extends SceneTree
## 打磨-15: 数值曲线压力测试 (CI 可跑, 不依赖 gen_data.py, 纯读 data/*.json + game_data.gd 逻辑)
## 覆盖: 全境界/全品质梯度、技能解锁门槛与境界一致性、后期数值溢出检查
## 运行: ~/bin/godot --headless --path . -s res://scripts/stress_test.gd
## 退出码 0 = 通过, 非 0 = 失败 (失败详情写入 user://stress_result.txt)
## 说明: -s 模式无 autoload, 手动实例化 game_data.gd 作为被测对象 (同 selftest.gd)。

var _fail: Array[String] = []
var _pass_count := 0
var g: Node = null  # 被测 GameData 实例

func check(cond: bool, label: String) -> void:
	if cond:
		_pass_count += 1
	else:
		_fail.append(label)
		printerr("FAIL: " + label)

func _init() -> void:
	var script: GDScript = load("res://scripts/game_data.gd")
	g = script.new()
	root.add_child(g)  # 触发 _ready: load_data + load_game
	# 清理旧存档, 保证干净环境
	var sp: String = g.SAVE_PATH
	var old := FileAccess.open(sp, FileAccess.READ)
	if old != null:
		old.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sp))
	# 等待一帧确保 _ready 完成数据加载 (同 selftest.gd)
	await process_frame

	# ---------- 境界/灵气倍率梯度 ----------
	for i in g.REALMS.size() - 1:
		check(g.QI_MULT[i + 1] > g.QI_MULT[i], "QI_MULT 严格递增 境界%d->%d (x%s -> x%s)" % [i, i + 1, g.QI_MULT[i], g.QI_MULT[i + 1]])
	check(g.QI_MULT[8] == 4000.0, "渡劫灵气倍率 x4000 锚点 (实际 x%s)" % g.QI_MULT[8])
	check((g.REALMS[9]["name"] as String) == "真仙", "境界表第 9 阶为 真仙")
	# 道行: 每阶消耗 x8 递推, 基础 1e9 (8 阶跨度 1e9 -> 2.1e15, 长线挂机不溢出)
	g.dao_level = 0
	check(g.dao_break_cost() == 1.0e9, "道行精进基础消耗 = 1e9 (实际 %s)" % g.dao_break_cost())
	for lv in g.IMMORTAL_REALMS.size() - 1:
		g.dao_level = lv
		var c0: float = g.dao_break_cost()
		g.dao_level = lv + 1
		var c1: float = g.dao_break_cost()
		check(c1 == c0 * g.DAO_BREAK_GROWTH, "道行消耗 x%d 递推 (阶%d, %s -> %s)" % [g.DAO_BREAK_GROWTH, lv, c0, c1])
	g.dao_level = 7
	check(g.dao_break_cost() == 1.0e9 * 2097152.0, "末阶道行消耗 = 2.1e15 (实际 %s)" % g.fmt(g.dao_break_cost()))

	# ---------- 技能: 解锁门槛与境界一致性 ----------
	# gen_data.py TIER_UNLOCK_REALM = [0,1,2,3,4,5]: 品质 tier -> 解锁境界 idx
	var TIER_UNLOCK := [0, 1, 2, 3, 4, 5]
	for tier in TIER_UNLOCK.size():
		var cnt := 0
		for id in g.skill_ids:
			var s: Dictionary = g.skill_by_id[id]
			if int(s["tier"]) != tier:
				continue
			cnt += 1
			check(int(s["unlock_realm"]) == TIER_UNLOCK[tier], "技能 %s 解锁境界与品质%d 一致 (实际 境界%d)" % [id, tier, int(s["unlock_realm"])])
			check(int(s["unlock_layer"]) >= 1 and int(s["unlock_layer"]) <= int(g.REALMS[TIER_UNLOCK[tier]]["layers"]), "技能 %s 解锁层在 境界%d 层数内" % [id, TIER_UNLOCK[tier]])
		check(cnt == 20, "品质%d 技能 20 个 (5类x4变体, 实际 %d)" % [tier, cnt])
	# 解锁层 1..3 均可达: 每个 (tier, layer) 组合至少 1 个技能 (unlock_layer 取值 1..3)
	for tier in TIER_UNLOCK.size():
		for layer in 3:
			var found := false
			for id in g.skill_ids:
				var s: Dictionary = g.skill_by_id[id]
				if int(s["tier"]) == tier and int(s["unlock_layer"]) == layer + 1:
					found = true
					break
			check(found, "境界%d 第%d层 存在可解锁技能 (tier%d)" % [TIER_UNLOCK[tier], layer + 1, tier])
	# 主动神通: 爆发秒数/冷却随品质递增
	for tier in TIER_UNLOCK.size() - 1:
		var a0: float = 0.0
		var a1: float = 0.0
		var c0: float = 0.0
		var c1: float = 0.0
		for id in g.skill_ids:
			var s: Dictionary = g.skill_by_id[id]
			if str(s["type"]) != "active":
				continue
			if int(s["tier"]) == tier:
				a0 = float(s["value"]); c0 = float(s["cooldown"])
			if int(s["tier"]) == tier + 1:
				a1 = float(s["value"]); c1 = float(s["cooldown"])
		check(a1 > a0 and c1 > c0, "主动神通 品质%d->%d 爆发/冷却递增 (%ds->%ds, cd %ds->%ds)" % [tier, tier + 1, int(a0), int(a1), int(c0), int(c1)])

	# ---------- 装备: 全品质价格/属性梯度 (7 档 x 5 部位 x 4 变体 = 140) ----------
	var seen_tiers := {}
	for id in g.equip_ids:
		var e: Dictionary = g.equip_by_id[id]
		seen_tiers[int(e["tier"])] = int(seen_tiers.get(int(e["tier"]), 0)) + 1
		check(int(e["cost"]) > 0, "装备 %s 价格>0 (实际 %s)" % [id, e["cost"]])
	for t in 7:
		check(int(seen_tiers.get(t, 0)) == 20, "装备品质%d 共 20 件 (5部位x4变体, 实际 %d)" % [t, int(seen_tiers.get(t, 0))])
	# 各部位: 品质递进价格严格上升; 最高品质内变体价格/灵气属性单调
	for slot in g.SLOTS:
		var tc: Array[float] = []
		for t in 7:
			var c := -1.0
			for id in g.equip_ids:
				var e: Dictionary = g.equip_by_id[id]
				if str(e["slot"]) == slot and int(e["tier"]) == t:
					c = float(e["cost"])
					break
			tc.append(c)
		for i in 6:
			check(tc[i + 1] > tc[i], "装备 %s 品质%d->%d 价格上升 (%s -> %s)" % [g.SLOT_CN[slot], i, i + 1, tc[i], tc[i + 1]])
		for v0 in 3:
			var e0: Dictionary = {}
			var e1: Dictionary = {}
			for id in g.equip_ids:
				var e: Dictionary = g.equip_by_id[id]
				if str(e["slot"]) == slot and int(e["tier"]) == 6 and int(e["id"].split("_")[2]) == v0:
					e0 = e
				if str(e["slot"]) == slot and int(e["tier"]) == 6 and int(e["id"].split("_")[2]) == v0 + 1:
					e1 = e
			check(float(e1["cost"]) > float(e0["cost"]), "装备 %s 神品变体%d->%d 价格上升 (%s -> %s)" % [g.SLOT_CN[slot], v0, v0 + 1, e0["cost"], e1["cost"]])
			check(float(e1["qi_mult"]) > float(e0["qi_mult"]), "装备 %s 神品变体%d->%d 灵气属性上升" % [g.SLOT_CN[slot], v0, v0 + 1])
	# 法器: 10 件价格严格递增 + 增幅单调
	var item_costs: Array[float] = []
	var item_boosts: Array[float] = []
	for it in g.ITEMS:
		item_costs.append(float(it["cost"]))
		item_boosts.append(float(it["boost"]))
	for i in g.ITEMS.size() - 1:
		check(item_costs[i + 1] > item_costs[i], "法器 %d->%d 价格上升 (%s -> %s)" % [i, i + 1, item_costs[i], item_costs[i + 1]])
		check(item_boosts[i + 1] > item_boosts[i], "法器 %d->%d 增幅上升 (x%s -> x%s)" % [i, i + 1, item_boosts[i], item_boosts[i + 1]])

	# ---------- 突破/道行成功率: 全程受控 ----------
	var bt_min: float = 0.85 - 0.04 * (g.REALMS.size() - 1)  # 真仙境裸成功率 0.49
	check(bt_min >= 0.45, "渡劫裸突破成功率 >= 0.45 (实际 %s)" % bt_min)
	for idx in g.REALMS.size():
		g.realm_idx = idx
		var bh: float = g.breakthrough_chance()
		check(bh >= 0.05 and bh <= 0.99, "境界%d 突破成功率受控 [0.05,0.99] (实际 %s)" % [idx, bh])
	var dch: float = g.dao_break_chance()
	check(dch >= 0.05 and dch <= 0.99, "道行成功率受控 (实际 %s)" % dch)

	# ---------- 加满被动/装备后的乘数上限 ----------
	g.realm_idx = 9  # 真仙境: 全部技能解锁门槛可达
	g.layer = 1
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if str(s["type"]) == "passive":
			g.learn_skill(id)
	var pb_qi: float = g.passive_bonus("qi_mult") + g.passive_bonus("all_mult")
	var pb_stone: float = g.passive_bonus("stone_mult") + g.passive_bonus("all_mult")
	check(pb_qi > 10.0 and pb_qi < 100.0, "满修被动灵气加和适中 x%s (10<x<100, 防指数爆炸)" % pb_qi)
	check(pb_stone > 10.0 and pb_stone < 100.0, "满修被动灵石加和适中 x%s (10<x<100)" % pb_stone)
	check(g.offline_rate() > 0.5, "加满被动后离线效率 > 基础50%% (实际 %0.0f%%)" % (g.offline_rate() * 100.0))
	check(g.offline_rate() <= 1.0, "离线效率被 clamp 在 100%% (实际 %0.0f%%)" % (g.offline_rate() * 100.0))
	# 穿满 5 部位神品最高变体
	var eq_bonus_qi := 0.0
	for slot in g.SLOTS:
		for id in g.equip_ids:
			var e: Dictionary = g.equip_by_id[id]
			if str(e["slot"]) == slot and int(e["tier"]) == 6 and int(e["id"].split("_")[2]) == 3:
				g.equipped[slot] = id
				eq_bonus_qi += float(e["qi_mult"])
				break
	check(g.equip_bonus("qi_mult") == eq_bonus_qi, "装备灵气汇总 = 5 部位之和 (x%s)" % g.equip_bonus("qi_mult"))
	check(g.equip_bonus("qi_mult") > 2.0, "神品 5 件装备灵气加成可观 x%s" % g.equip_bonus("qi_mult"))
	# 离线收益 8 小时封顶
	var og: Dictionary = g.offline_gain(30.0 * 86400.0)
	check(bool(og["capped"]), "离线 30 天收益被 8 小时封顶")
	check(float(og["sec"]) == g.OFFLINE_CAP_SEC, "封顶秒数 = 8h (实际 %s)" % og["sec"])
	check(float(og["qi"]) == g.qi_per_sec() * g.OFFLINE_CAP_SEC * float(og["rate"]), "封顶收益 = 速率x8h x 效率")

	# ---------- 突破消耗梯度 (每境界内随层严格上升, 峰值按公式 10*3^idx*layer 精确锚定) ----------
	var EXPECT_MAX := [90.0, 90.0, 270.0, 810.0, 2430.0, 7290.0, 21870.0, 65610.0, 65610.0, 196830.0]
	var prev_max: float = -1.0
	var total_breaks := 0
	for idx in g.REALMS.size():
		var m := 0.0
		var prev_layer_cost := -1.0
		for l in int(g.REALMS[idx]["layers"]):
			g.realm_idx = idx
			g.layer = l + 1
			var c: float = g.breakthrough_cost()
			check(c > prev_layer_cost, "突破消耗 境界%d第%d层 随层上升 (%s -> %s)" % [idx, l + 1, prev_layer_cost, c])
			prev_layer_cost = c
			m = c
		check(m == EXPECT_MAX[idx], "突破消耗 境界%d 峰值 = %s (实际 %s)" % [idx, EXPECT_MAX[idx], m])
		check(m >= prev_max, "突破消耗 境界%d 峰值不回落下降 (%s >= %s)" % [idx, m, prev_max])
		prev_max = m
		total_breaks += int(g.REALMS[idx]["layers"])
	check(total_breaks == 32, "全程需 32 次突破 (9+3x7+1+1, 实际 %d)" % total_breaks)

	# ---------- 后期数值溢出检查: 满修 + 飞升 + 道祖 ----------
	g.realm_idx = 9
	g.layer = 1
	g.ascended = true
	g.dao_level = 8
	g.owned.clear()
	for it in g.ITEMS:
		g.owned.append(str(it["id"]))
	var ip: float = g.item_boost()
	var ip_expect := 1.0
	for it in g.ITEMS:
		ip_expect *= float(it["boost"])
	check(ip == ip_expect, "法器总增幅 = 10 件连乘 x%s" % g.fmt(ip))
	check(is_finite(ip) and ip < 1e18, "法器总增幅不溢出 (x%s)" % g.fmt(ip))
	check(g.immortal_mult() == pow(2.0, 8.0), "道祖倍率 = x256 (实际 x%s)" % g.immortal_mult())
	check(g.qi_mult_realm() == 100000.0 * 256.0, "道祖境界倍率 = x100000 x x256 (实际 x%s)" % g.qi_mult_realm())
	var qi_max: float = g.qi_per_sec()
	var stone_max: float = g.stone_per_sec()
	check(is_finite(qi_max) and qi_max < 1e19, "满修+道祖灵气速率有限 < 1e19/s (实际 %s)" % g.fmt(qi_max))
	check(g.fmt(qi_max).ends_with("京") or g.fmt(qi_max).ends_with("垓"), "满修灵气速率展示在 京/垓 档 (实际 %s)" % g.fmt(qi_max))
	check(is_finite(stone_max) and stone_max < 1e8, "满修+道祖灵石速率有限 < 1e8/s (实际 %s)" % g.fmt(stone_max))
	# 神通爆发 (飞升后转道行)
	var active_id := ""
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if str(s["type"]) == "active" and int(s["tier"]) == 5:
			active_id = id
			break
	check(active_id != "", "存在仙品主动神通")
	g.learned.append(active_id)
	g.dao = 0.0
	var dao0: float = g.dao
	var burst: float = float(g.qi_per_sec()) * float(g.skill_by_id[active_id]["value"])
	check(is_finite(burst) and burst < 1e24, "仙品神通爆发有限 < 1e24 (实际 %s)" % g.fmt(burst))
	g.use_active_skill(active_id)
	check(g.dao == dao0 + burst, "飞升后神通爆发计入道行 (delta %s)" % g.fmt(g.dao - dao0))
	# 末阶道行精进可达: 满修 1 小时挂机即可攒出末阶消耗
	g.dao_level = 7
	var last_dao_cost: float = g.dao_break_cost()
	var hour_gain: float = g.qi_per_sec() * 3600.0
	check(hour_gain > last_dao_cost, "满修 1 小时挂机 > 末阶道行精进消耗 (%s > %s)" % [g.fmt(hour_gain), g.fmt(last_dao_cost)])
	g.dao = last_dao_cost
	var msg: String = g.try_dao_break(0.01)
	check(msg.find("道行精进") >= 0 and g.dao_level == 8, "注入 roll 末阶精进成功: " + msg)
	check(g.try_dao_break(0.01).find("道祖") >= 0, "道祖封顶提示: " + g.try_dao_break(0.01))
	# 离线收益在满修下不溢出
	var og2: Dictionary = g.offline_gain(3600.0)
	check(is_finite(float(og2["qi"])) and is_finite(float(og2["stone"])), "满修离线小时收益有限 (qi=%s stone=%s)" % [g.fmt(float(og2["qi"])), g.fmt(float(og2["stone"]))])
	# 满修突破/道行成功率仍受控 (加满 bt 加成后)
	check(g.breakthrough_chance() >= 0.05 and g.breakthrough_chance() <= 0.99, "满修突破成功率仍受控 (实际 %s)" % g.breakthrough_chance())
	check(g.dao_break_chance() >= 0.05 and g.dao_break_chance() <= 0.99, "满修道行成功率仍受控 (实际 %s)" % g.dao_break_chance())

	# ---------- fmt 展示上限 (万/亿/兆/京/垓) ----------
	check(g.fmt(0.0) == "0", "fmt 零 (实际 %s)" % g.fmt(0.0))
	check(g.fmt(999.0) == "999", "fmt 个位 (实际 %s)" % g.fmt(999.0))
	check(g.fmt(1.5e4) == "1.5万", "fmt 万 (实际 %s)" % g.fmt(1.5e4))
	check(g.fmt(2.0e8) == "2.0亿", "fmt 亿 (实际 %s)" % g.fmt(2.0e8))
	check(g.fmt(3.0e12) == "3.0兆", "fmt 兆 (实际 %s)" % g.fmt(3.0e12))
	check(g.fmt(4.0e16) == "4.0京", "fmt 京 (实际 %s)" % g.fmt(4.0e16))
	check(g.fmt(5.0e20) == "5.0垓", "fmt 垓 (实际 %s)" % g.fmt(5.0e20))
	g.dao_level = 7
	check(g.fmt(g.dao_break_cost()) == "2097.2兆", "fmt 末阶道行消耗 兆档 (实际 %s)" % g.fmt(g.dao_break_cost()))

	# ---------- M6-4: DIY 词缀 数值平衡 (词缀曲线 vs 商店装备曲线 + 满配 20 槽 溢出检查) ----------
	# 档态: 满修 120 技能 + 道祖 + 10 法器 (复用上方 后期溢出 段 状态); 道行 阶段 拉到 道祖 (4 槽 解锁 门槛)
	g.dao_level = 8
	# 1) 词缀 曲线 vs 商店 装备 曲线 (逐池 对比: 普通 词缀 不 反超 商店, 传说 词缀 上限线 不 低于 商店)
	var pool_ids := ["qi_rate", "stone_rate", "bt_chance", "offline_rate", "atk", "def"]
	for pid in pool_ids:
		var eff: String = g.AFFIX_POOL_KEY[pid]
		var t0: float = float(g.affix_by_id["af_%s_0_0" % pid]["value"])
		var t4: float = float(g.affix_by_id["af_%s_4_3" % pid]["value"])
		var shop_max := 0.0
		for slot in g.SLOTS:
			for id in g.equip_ids:
				var e: Dictionary = g.equip_by_id[id]
				if str(e["slot"]) == slot and int(e["tier"]) == 6:
					shop_max = maxf(shop_max, float(e.get(eff, 0.0)))
		check(t0 <= shop_max * 2.0, "M6-4 %s 普通词缀 ≤ 商店神品单件x2 (词缀%s vs 商店%s)" % [pid, t0, shop_max])
		check(t4 >= shop_max * 0.5, "M6-4 %s 传说词缀 ≥ 商店神品单件x0.5 上限线 (词缀%s vs 商店%s)" % [pid, t4, shop_max])
	# 2) 商店 满装 基线 (5 部位 神品 最高变体) 属性 可观
	var shop_full_qi := 0.0
	for slot in g.SLOTS:
		for id in g.equip_ids:
			var e: Dictionary = g.equip_by_id[id]
			if str(e["slot"]) == slot and int(e["tier"]) == 6 and int(e["id"].split("_")[2]) == 3:
				g.equipped[slot] = id
				if not g.owned_eq.has(id):
					g.owned_eq.append(id)
				shop_full_qi += float(e["qi_mult"])
				break
	check(shop_full_qi > 3.0, "M6-4 商店满装灵气加成基线 > 3 (实际 %s)" % shop_full_qi)
	var qi_shop: float = g.qi_per_sec()
	# 3) 道祖期 4 槽 升级 5 件 全 成功 + 满配 20 槽 (全 传说 qi_rate v3)
	var up_fail := 0
	for slot in g.SLOTS:
		var r: String = g.affix_slot_upgrade(str(g.equipped[slot]))
		if r != "":
			up_fail += 1
	check(up_fail == 0, "M6-4 道祖期 4 槽升级 5 件全成功 (失败 %d)" % up_fail)
	var eq_fail := 0
	for slot in g.SLOTS:
		var eid: String = g.equipped[slot]
		for pos in 4:
			g.affix_add("af_qi_rate_4_3", 1)
			var r2: String = g.affix_equip(eid, pos, "af_qi_rate_4_3")
			if r2 != "":
				eq_fail += 1
	check(eq_fail == 0, "M6-4 满配 20 槽 装配全成功 (失败 %d)" % eq_fail)
	# 4) 满配 溢出 检查 (词缀 乘算 独立项 不 溢出, 与 商店路线 比值 受控)
	var qi_full: float = g.qi_per_sec()
	var atk_full: float = g.player_atk()
	var def_full: float = g.player_def()
	var bt_full: float = g.breakthrough_chance()
	var off_full: float = g.offline_rate()
	check(is_finite(qi_full) and qi_full < 1e19, "M6-4 满配灵气速率有限 < 1e19/s (实际 %s)" % g.fmt(qi_full))
	check(is_finite(atk_full) and is_finite(def_full), "M6-4 满配 atk/def 有限 (atk=%s def=%s)" % [g.fmt(atk_full), g.fmt(def_full)])
	check(g.resonance_mult() == 1.0 + 0.02 * 20.0, "M6-4 同品质 20 件共鸣 = x1.4 (实际 x%s)" % g.resonance_mult())
	check(bt_full <= 0.99, "M6-4 满配突破成功率 clamp ≤ 0.99 (实际 %s)" % bt_full)
	check(off_full <= 1.0, "M6-4 满配离线效率 clamp ≤ 100%% (实际 %d%%)" % int(off_full * 100.0))
	var diy_ratio: float = qi_full / qi_shop
	check(diy_ratio > 1.5 and diy_ratio < 3.0, "M6-4 DIY满配 vs 商店满装 放大受控 (1.5<x<3.0, 实际 x%s)" % diy_ratio)
	check(g.fmt(qi_full).ends_with("京") or g.fmt(qi_full).ends_with("垓"), "M6-4 满配灵气展示在 京/垓 档 (实际 %s)" % g.fmt(qi_full))
	# 5) 6 池 混合 15 槽 满配 (各池 传说 混装) 全 有限
	g.affix_load.clear()
	g.affix_bag.clear()
	var mix_pools := ["af_qi_rate_4_3", "af_stone_rate_4_3", "af_bt_chance_4_3",
		"af_offline_rate_4_3", "af_atk_4_3", "af_def_4_3"]
	for slot in g.SLOTS:
		var eid3: String = g.equipped[slot]
		for pos in 3:
			var pid2: String = mix_pools[(pos + g.SLOTS.find(slot)) % 6]
			g.affix_add(pid2, 1)
			g.affix_equip(eid3, pos, pid2)
	var qi_mix: float = g.qi_per_sec()
	check(is_finite(qi_mix) and qi_mix > qi_shop, "M6-4 6池混合15槽 灵气有限且 > 商店基线 (%s)" % g.fmt(qi_mix))
	check(g.breakthrough_chance() <= 0.99 and g.offline_rate() <= 1.0, "M6-4 混合满配 成功率/离线 仍 clamp 受控")
	# 6) 掉落 桶位/品质 曲线 (低层 无 传说, 顶层 高 roll 必 传说 — 高层塔 掉 高品质 口径)
	check(g.affix_drop_bucket(1) == 0 and g.affix_drop_bucket(50) == 0 and g.affix_drop_bucket(51) == 1, "M6-4 掉落桶位 1/50/51 层 -> 0/0/1")
	check(g.affix_drop_bucket(1000) == 19, "M6-4 1000 层 = 顶桶 19")
	check(g.affix_roll_tier(0, 0.9999) < 4, "M6-4 首桶 无 传说 掉落 (roll 0.9999 = 品质%d)" % g.affix_roll_tier(0, 0.9999))
	check(g.affix_roll_tier(19, 0.9999) == 4, "M6-4 顶桶 高 roll 命中 传说 (roll 0.9999 = 品质%d)" % g.affix_roll_tier(19, 0.9999))
	# 7) 收尾 复原 (清 词缀/装备/槽位 状态, 防 污染 后续)
	g.affix_load.clear()
	g.affix_bag.clear()
	g.slot_upgrades.clear()
	g.equipped.clear()
	g.owned_eq.clear()

	# ---------- 汇报 ----------
	print("")
	if _fail.is_empty():
		print("STRESS PASS  %d 项全部通过" % _pass_count)
		quit(0)
	else:
		printerr("STRESS FAIL  %d 通过 / %d 失败:" % [_pass_count, _fail.size()])
		for x in _fail:
			printerr("  - " + x)
		var rf := FileAccess.open("user://stress_result.txt", FileAccess.WRITE)
		if rf != null:
			rf.store_string("\n".join(_fail))
			rf.close()
		quit(1)
