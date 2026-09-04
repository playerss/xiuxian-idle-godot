extends SceneTree
## headless 全流程自测: 数据层/学习/购买/穿戴/冷却/突破/存读档往返/数值梯度
## 运行: ~/bin/godot --headless --path . -s res://scripts/selftest.gd
## 退出码 0 = 通过, 非 0 = 失败 (失败详情写入 user://selftest_result.txt)
## 说明: -s 模式无 autoload, 故手动实例化 game_data.gd 作为被测对象。

var _fail: Array[String] = []
var _pass_count := 0
var g: Node = null  # 被测 GameData 实例

func check(cond: bool, label: String) -> void:
	if cond:
		_pass_count += 1
	else:
		_fail.append(label)
		printerr("FAIL: " + label)

func _save_json() -> Dictionary:
	var f := FileAccess.open(g.SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return v if typeof(v) == TYPE_DICTIONARY else {}

func _init() -> void:
	var script: GDScript = load("res://scripts/game_data.gd")
	g = script.new()
	root.add_child(g)  # 触发 _ready: load_data + load_game
	# 清理旧存档, 保证干净环境 (须在 load_game 之后, 覆盖其可能的写入)
	var sp: String = g.SAVE_PATH
	var old := FileAccess.open(sp, FileAccess.READ)
	if old != null:
		old.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sp))

	await process_frame

	# ---------- 数据层 ----------
	check(g.skill_ids.size() >= 100, "技能数量>=100 (实际 %d)" % g.skill_ids.size())
	check(g.equip_ids.size() >= 100, "装备数量>=100 (实际 %d)" % g.equip_ids.size())
	var tier_costs: Array[float] = []
	for t in 7:
		var c := -1.0
		for id in g.equip_ids:
			var e: Dictionary = g.equip_by_id[id]
			if int(e["tier"]) == t and str(e["slot"]) == "weapon":
				c = float(e["cost"])
				break
		tier_costs.append(c)
	for i in 6:
		check(tier_costs[i] > 0.0 and tier_costs[i + 1] > tier_costs[i], "装备品质%d价格梯度上升" % i)

	# ---------- 技能: 学习 / 未解锁 / 重复学习 ----------
	var passive_id := ""
	var active_id := ""
	var locked_passive := ""
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if str(s["type"]) == "passive" and passive_id == "":
			passive_id = id
		if str(s["type"]) == "active" and active_id == "":
			active_id = id
		if str(s["type"]) == "passive" and int(s["unlock_realm"]) >= 5 and locked_passive == "":
			locked_passive = id
	check(passive_id != "" and active_id != "" and locked_passive != "", "存在被动/主动/高境界技能")
	check(not g.can_learn(locked_passive), "高境界技能在练气期不可学习")
	check(g.learn_skill(locked_passive).find("境界不足") >= 0, "学习高境界技能被拒")
	var before_qi: float = g.qi_per_sec()
	var msg: String = g.learn_skill(passive_id)
	check(g.learned.has(passive_id), "被动技能学习成功")
	check(msg.find("领悟") >= 0, "学习返回领悟提示")
	check(g.qi_per_sec() >= before_qi, "学习被动后灵气速率提升")
	check(g.learn_skill(passive_id).find("已经") >= 0, "重复学习被拒")

	# ---------- 打磨-3: 灵气倍率构成 (顶栏展示用接口) ----------
	var qmr: float = g.qi_mult_realm()
	check(qmr == g.QI_MULT[0], "qi_mult_realm == QI_MULT[realm_idx] (练气 x1)")
	check(g.qi_mult_skill_equip() > 1.0, "已学被动后 qi_mult_skill_equip > 1")
	# 合成一致性: 境界 x (功法装备) 应近似 qi_per_sec / 法器
	var qi_ratio: float = g.qi_per_sec() / g.item_boost()
	check(absf(qi_ratio - qmr * g.qi_mult_skill_equip()) < 0.01, "qi_per_sec ≈ 境界x x 功法装备x")
	g.realm_idx = 3
	check(g.qi_mult_realm() == g.QI_MULT[3], "qi_mult_realm 随境界变化 (元婴 x40)")
	g.realm_idx = 0

	# ---------- 主动神通: 释放 / 冷却 ----------
	check(g.use_active_skill(active_id).find("尚未领悟") >= 0, "未领悟神通不可施展")
	g.learned.append(active_id)  # 直接注入, 测冷却逻辑
	var essence0: float = g.essence
	check(g.use_active_skill(active_id).find("施展") >= 0, "施展神通成功")
	var s_act: Dictionary = g.skill_by_id[active_id]
	check(g.essence >= essence0 + g.qi_per_sec() * float(s_act["value"]) * 0.99, "神通爆发≈速率x秒数")
	check(not g.active_ready(active_id), "施展后进入冷却")
	check(g.active_cd_left(active_id) > 0, "冷却倒计时>0")
	check(g.use_active_skill(active_id).find("冷却中") >= 0, "冷却中再次施展被拒")

	# ---------- 装备: 购买 / 穿戴 / 换装 / 卸下 ----------
	g.stones = 1e12
	var eq_id := ""
	var eq_same_slot := ""
	for id in g.equip_ids:
		var e: Dictionary = g.equip_by_id[id]
		if str(e["slot"]) == "weapon" and eq_id == "":
			eq_id = id
		if str(e["slot"]) == "weapon" and int(e["tier"]) == 6 and eq_same_slot == "":
			eq_same_slot = id
	check(eq_id != "" and eq_same_slot != "", "找到武器槽位装备")
	var stones0: float = g.stones
	check(g.buy_equipment(eq_id).find("购得") >= 0, "购买装备成功")
	check(g.owned_eq.has(eq_id), "购买后已拥有")
	check(g.stones < stones0, "购买扣除灵石")
	check(str(g.equipped.get("weapon", "")) == eq_id, "槽位空时自动穿戴")
	check(g.buy_equipment(eq_id).find("已经") >= 0, "重复购买被拒")
	check(g.buy_equipment(eq_same_slot).find("购得") >= 0, "购买第二件武器")
	check(g.equip_equipment(eq_id).find("已穿戴") >= 0, "手动换装回第一件")
	check(str(g.equipped.get("weapon", "")) == eq_id, "换装生效")
	g.unequip("weapon")
	check(not g.equipped.has("weapon"), "卸下生效")
	g.equip_equipment(eq_id)
	check(g.equip_bonus("qi_mult") > 0.0, "穿戴后属性汇总>0")

	# ---------- 突破 ----------
	g.realm_idx = 0
	g.layer = 1
	var seq0: int = g.break_seq
	# 灵气不足: 不触发事件, 不扣灵气
	g.essence = g.breakthrough_cost() * 0.5
	var e2: float = g.essence
	check(g.try_breakthrough(0.01).find("灵气不足") >= 0, "灵气不足被拒")
	check(g.last_break_result == 0, "灵气不足不产生事件标记")
	check(g.break_seq == seq0, "灵气不足 break_seq 不变")
	check(g.essence == e2, "灵气不足不扣灵气")
	# 确定性注入 roll: 成功必前进 + 事件计数/结果标记
	g.essence += g.breakthrough_cost() + 1.0
	var r0: int = g.realm_idx
	var l0: int = g.layer
	var bt_ok: String = g.try_breakthrough(0.01)
	check(bt_ok.find("突破成功") >= 0, "注入 roll=0.01 必成功: " + bt_ok)
	check(g.last_break_result == 1, "成功时 last_break_result==1")
	check(g.break_seq == seq0 + 1, "成功时 break_seq +1")
	check((g.realm_idx > r0) or (g.realm_idx == r0 and g.layer > l0), "成功后层/境界前进")
	# 确定性注入 roll: 失败不前进, 仍扣灵气
	g.essence = g.breakthrough_cost() + 1.0
	var r1: int = g.realm_idx
	var l1: int = g.layer
	var e1: float = g.essence
	var bt_fail: String = g.try_breakthrough(0.999)
	check(bt_fail.find("突破失败") >= 0, "注入 roll=0.999 必失败: " + bt_fail)
	check(g.realm_idx == r1 and g.layer == l1, "失败后层/境界不变")
	check(g.last_break_result == 2, "失败时 last_break_result==2")
	check(g.break_seq == seq0 + 2, "失败时 break_seq +1 (累计 seq0+2)")
	check(g.essence < e1, "失败仍消耗灵气")

	# ---------- 打磨-4: 数值曲线 (法器性价比 / 装备价格曲线受控) ----------
	var item_costs: Array[float] = []
	var item_boosts: Array[float] = []
	for it in g.ITEMS:
		item_costs.append(float(it["cost"]))
		item_boosts.append(float(it["boost"]))
	check(g.ITEMS.size() >= 5, "法器数量>=5 (实际 %d)" % g.ITEMS.size())
	for i in item_costs.size() - 1:
		check(item_costs[i + 1] > item_costs[i] and item_boosts[i + 1] > item_boosts[i], "法器第%d件价格/增幅单调上升" % i)
	# 性价比: 每单位增幅的单价应不降 (后期法器更贵但增幅更大)
	var cp_ok := true
	var prev_ratio := 0.0
	for i in g.ITEMS.size():
		var ratio: float = item_costs[i] / item_boosts[i]
		cp_ok = cp_ok and ratio >= prev_ratio * 0.99
		prev_ratio = ratio
	check(cp_ok, "法器性价比递减 (单价不降)")
	# 装备: weapon 变体0 = 该档基础价, 相邻档倍率受控 3~10x (防止曲线回归过陡/过平)
	var tc: Array[float] = []
	for t in 7:
		for id in g.equip_ids:
			var e: Dictionary = g.equip_by_id[id]
			if str(e["slot"]) == "weapon" and int(e["tier"]) == t:
				tc.append(float(e["cost"]))
				break
	check(tc.size() == 7, "装备 7 档基础价齐全")
	for i in 6:
		var eq_ratio: float = tc[i + 1] / tc[i]
		check(eq_ratio >= 3.0 and eq_ratio <= 12.0, "装备品质%d->%d 价格倍率受控 (实际 %.1fx)" % [i, i + 1, eq_ratio])
	# 法器全购: 按序全部可买, 灵石清零, 总增幅>100x
	var stones_all: float = 0.0
	for it in g.ITEMS:
		stones_all += float(it["cost"])
	g.stones = stones_all
	var bought := 0
	for it in g.ITEMS:
		if g.try_buy_item(it["id"]).find("购得") >= 0:
			bought += 1
	check(bought == g.ITEMS.size(), "法器全购成功 (%d/%d)" % [bought, g.ITEMS.size()])
	check(g.stones < 0.5, "法器全购后灵石清零")
	check(g.item_boost() > 100.0, "全购法器后灵气总增幅>100x (实际 x%.0f)" % g.item_boost())

	# ---------- 打磨-6: 成就 (Steam 上架准备, 数据驱动) ----------
	# 重置为受控状态, 保证解锁判定确定性 (前面各节已产生 owned/learned 等状态)
	g.owned.clear()
	g.learned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.ach_done.clear()
	g.stones = 0.0
	g.essence = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g._ach_acc = -86400.0   # 冻结节流, 避免 _process 并发解锁干扰自测确定性 (测试仅数秒)
	check(g.ach_ids.size() >= 10, "成就数量>=10 (实际 %d)" % g.ach_ids.size())
	check(g.ach_by_id.has("ascend_immortal") and g.ach_by_id.has("first_break") and g.ach_by_id.has("skill_10") and g.ach_by_id.has("dao_zuzi"), "成就定义齐全 (ascend/first_break/skill_10/dao_zuzi)")
	var got0: Array[String] = g.check_achievements()
	check(got0.is_empty(), "初始状态无成就解锁")
	# first_break: 首次成功突破
	g.essence = g.breakthrough_cost()
	g.try_breakthrough(0.01)
	var got1: Array[String] = g.check_achievements()
	check(got1.has("first_break"), "首次突破解锁 first_break: " + str(got1))
	check(g.ach_done.has("first_break"), "ach_done 记录 first_break")
	var got2: Array[String] = g.check_achievements()
	check(got2.is_empty(), "成就检查幂等 (不重复解锁)")
	# 打磨-17: new_ach_since (成就解锁浮动提示的差集逻辑; UI 每帧对比快照触发浮动)
	var prev17: Array[String] = g.ach_done.duplicate() as Array[String]
	check(g.new_ach_since(prev17).is_empty(), "new_ach_since 状态不变返回空 (实际 %s)" % str(g.new_ach_since(prev17)))
	var diff17: Array[String] = g.new_ach_since([])
	check(diff17.size() == 1 and diff17.has("first_break"), "new_ach_since 含新解锁成就 (实际 %s)" % str(diff17))
	var stale_prev: Array[String] = ["stale_x", "first_break"]
	check(g.new_ach_since(stale_prev).is_empty(), "new_ach_since 已含旧解锁不重复计")
	# realm_zhuji: 升到筑基 (realm_idx=1)
	var guard := 0
	while g.realm_idx < 1 and not g.ascended and guard < 30:
		g.essence = g.breakthrough_cost()
		g.try_breakthrough(0.01)
		guard += 1
	var got3: Array[String] = g.check_achievements()
	check(got3.has("realm_zhuji"), "筑基解锁 realm_zhuji: " + str(got3))
	# skill_10: 真实学习 10 个技能 (筑基 3 层可学 凡/灵 两档 40 个; 失败文案含"领悟"字, 按 learned 计数)
	g.layer = 3
	var learned_now := 0
	for id in g.skill_ids:
		if learned_now >= 10:
			break
		if not g.learned.has(id):
			g.learn_skill(id)
			if g.learned.has(id):
				learned_now += 1
	check(learned_now == 10, "已学满 10 技能 (实际 %d)" % learned_now)
	var got4: Array[String] = g.check_achievements()
	check(got4.has("skill_10"), "学 10 技能解锁 skill_10: " + str(got4))
	# skill_50: 补到 50 (注入剩余 id, 解锁判定只看数量)
	var si := 0
	while g.learned.size() < 50 and si < g.skill_ids.size():
		if not g.learned.has(g.skill_ids[si]):
			g.learned.append(g.skill_ids[si])
		si += 1
	check(g.learned.size() >= 50, "已学技能数>=50 (实际 %d)" % g.learned.size())
	var got5: Array[String] = g.check_achievements()
	check(got5.has("skill_50"), "学 50 技能解锁 skill_50: " + str(got5))
	# equip_first / equip_10: 购买 10 件装备 (先压低灵石避免 rich_100k 误触发)
	g.stones = 1e15
	var eq_bought := 0
	for id in g.equip_ids:
		if eq_bought >= 10:
			break
		if g.buy_equipment(id).find("购得") >= 0:
			eq_bought += 1
	g.stones = 99999.0
	var got6: Array[String] = g.check_achievements()
	check(got6.has("equip_first") and got6.has("equip_10"), "购 10 装备解锁 equip_first/equip_10: " + str(got6))
	# rich_100k: 灵石达 10 万
	g.stones = 100000.0
	var got7: Array[String] = g.check_achievements()
	check(got7.has("rich_100k"), "灵石达 10 万解锁 rich_100k: " + str(got7))
	# first_item: 购入第一件法器
	g.stones = 1000.0
	g.try_buy_item("wooden_sword")
	var got8: Array[String] = g.check_achievements()
	check(got8.has("first_item"), "第一件法器解锁 first_item: " + str(got8))
	# ascend_immortal: 飞升
	g.ascended = true
	var got9: Array[String] = g.check_achievements()
	check(got9.has("ascend_immortal"), "飞升解锁 ascend_immortal: " + str(got9))
	g.ascended = false
	# realm_dujie: 境界里程碑 (渡劫 idx=8, 顺带大乘 idx=7 同时满足)
	g.realm_idx = 8
	var got10: Array[String] = g.check_achievements()
	check(got10.has("realm_dujie") and got10.has("realm_dacheng"), "渡劫解锁 realm_dujie/realm_dacheng: " + str(got10))
	# 已解锁数 = 飞升前全部可解锁成就 (境界里程碑 8 + 飞升 + 玩法 7 = 16/17, dao_zuzi 需飞升后道祖)
	g.check_achievements()
	check(g.ach_done.size() == g.ach_ids.size() - 1, "飞升前 16/17 成就解锁 (实际 %d/%d)" % [g.ach_done.size(), g.ach_ids.size()])
	g.realm_idx = 0
	g.layer = 1
	# 成就存档往返: 部分解锁后存/读档
	g.ach_done.clear()
	g.ach_done.append("first_break")
	g.stones = 123456.0

	# ---------- 打磨-7: 成就面板 (进度提示逻辑; UI 构建靠主场景 headless 运行验证) ----------
	# ach_progress 逻辑 (此时 ach_done=["first_break"], stones=123456, learned 50 个)
	check(g.ach_progress("first_break") == "已解锁", "ach_progress 已解锁成就 (first_break)")
	g.stones = 50000.0
	check(g.ach_progress("rich_100k") == "50000/100000", "ach_progress rich_100k 进度 (实际 %s)" % g.ach_progress("rich_100k"))
	g.stones = 200000.0
	check(g.ach_progress("rich_100k") == "100000/100000", "ach_progress rich_100k 进度封顶")
	check(g.ach_progress("skill_50") == "50/50", "ach_progress skill_50 进度 (实际 %s)" % g.ach_progress("skill_50"))
	check(g.ach_progress("realm_jindan") == "当前 练气 / 目标 金丹", "ach_progress 境界成就提示")
	check(g.ach_progress("ascend_immortal") == "渡劫后飞升 (当前 练气 第 1 层)", "ach_progress 飞升成就提示")
	check(g.ach_progress("skill_10") == "10/10", "ach_progress skill_10 进度封顶 10/10 (实际 %s)" % g.ach_progress("skill_10"))
	# 恢复受控状态 (存档往返节)
	g.stones = 123456.0

	# ---------- 打磨-9: 详情 tooltip + 总加成汇总 (逻辑; UI 构建靠主场景 headless 运行验证) ----------
	var learned_one: String = g.learned[0]
	var unlearned_one := ""
	for id in g.skill_ids:
		if not g.learned.has(id):
			unlearned_one = id
			break
	check(unlearned_one != "", "找到未学技能")
	check(g.skill_detail(learned_one).find("状态: 已领悟") >= 0, "skill_detail 已学状态 (实际: %s)" % g.skill_detail(learned_one))
	check(g.skill_detail(unlearned_one).find("状态: 未领悟") >= 0, "skill_detail 未学状态")
	check(g.skill_detail(learned_one).find("领悟条件:") >= 0 and g.skill_detail(learned_one).find("功法") >= 0 or g.skill_detail(learned_one).find("神通") >= 0, "skill_detail 含领悟条件/类型")
	check(g.skill_detail("not_exist") == "", "skill_detail 未知 id 返回空")
	var owned_eq_one: String = g.owned_eq[0]
	var e_oe: Dictionary = g.equip_by_id[owned_eq_one]
	var worn_state := "状态: 已穿戴" if str(g.equipped.get(str(e_oe["slot"]), "")) == owned_eq_one else "状态: 已拥有(未穿戴)"
	check(g.equip_detail(owned_eq_one).find(worn_state) >= 0, "equip_detail 状态行 (实际: %s)" % g.equip_detail(owned_eq_one))
	check(g.equip_detail(owned_eq_one).find("灵石") >= 0, "equip_detail 含价格")
	check(g.equip_detail("not_exist") == "", "equip_detail 未知 id 返回空")
	check(g.item_detail("wooden_sword").find("状态: 已拥有") >= 0, "item_detail 已拥有状态 (wooden_sword, 实际: %s)" % g.item_detail("wooden_sword"))
	check(g.item_detail("jade_talisman").find("状态: 未拥有") >= 0, "item_detail 未拥有状态 (jade_talisman)")
	check(g.item_detail("not_exist") == "", "item_detail 未知 id 返回空")
	var bs: Dictionary = g.bonus_summary()
	check(absf(float(bs["qi_mult"]) - g.qi_mult_skill_equip()) < 0.001, "bonus_summary qi_mult 与 qi_mult_skill_equip 一致")
	check(absf(float(bs["stone_mult"]) - (1.0 + g.passive_bonus("stone_mult") + g.passive_bonus("all_mult") + g.equip_bonus("stone_mult"))) < 0.001, "bonus_summary stone_mult 一致")
	check(absf(float(bs["bt_chance"]) - (g.passive_bonus("bt_chance") + g.equip_bonus("bt_chance"))) < 0.001, "bonus_summary bt_chance 一致")
	check(absf(float(bs["item_boost"]) - g.item_boost()) < 0.001, "bonus_summary item_boost 一致")
	var bst: String = g.bonus_summary_text()
	check(bst.find("灵气 x") >= 0 and bst.find("法器 x") >= 0 and bst.find("离线") >= 0, "bonus_summary_text 含灵气/离线/法器段 (实际: %s)" % bst)

	# ---------- 打磨-10: 飞升后道行 (真仙境 9 阶, 每阶灵气 x2) ----------
	check(g.fmt(1.5e8) == "1.5亿", "fmt 亿 (实际 %s)" % g.fmt(1.5e8))
	check(g.fmt(1.0e12) == "1.0兆", "fmt 兆 (实际 %s)" % g.fmt(1.0e12))
	check(g.fmt(2.56e20) == "2.6垓", "fmt 垓 (实际 %s)" % g.fmt(2.56e20))
	check(g.try_dao_break(0.01).find("飞升后方可") >= 0, "未飞升不可修炼道行")
	check(g.immortal_mult() == 1.0, "未飞升道行倍率 x1")
	# 飞升 + 道行倍率
	g.ascended = true
	check(g.immortal_mult() == 1.0, "飞升初仙 道行倍率 x1")
	var qi_pre: float = g.qi_per_sec()
	g.dao_level = 1
	check(absf(g.qi_per_sec() / qi_pre - 2.0) < 1e-9, "道行每阶灵气 x2 (实际 x%.3f)" % (g.qi_per_sec() / qi_pre))
	g.realm_idx = 9
	check(absf(g.qi_mult_realm() - g.QI_MULT[9] * 2.0) < 1e-6, "qi_mult_realm 含道行倍率 (真仙 x2, 实际 %s)" % g.fmt(g.qi_mult_realm()))
	g.dao_level = 0
	check(g.realm_display() == "真仙·初仙 (已飞升)", "realm_display 飞升后 (实际 %s)" % g.realm_display())
	g.ascended = false
	g.realm_idx = 0
	check(g.realm_display() == "练气 第 1 层", "realm_display 未飞升 (实际 %s)" % g.realm_display())
	# 道行精进: 不足 / 成功 / 失败
	g.ascended = true
	var dseq0: int = g.break_seq
	g.dao = g.dao_break_cost() * 0.5
	check(g.try_dao_break(0.01).find("道行不足") >= 0, "道行不足被拒")
	check(g.dao == g.dao_break_cost() * 0.5, "道行不足不扣道行")
	g.dao = g.dao_break_cost() + 1.0
	var db_ok: String = g.try_dao_break(0.01)
	check(db_ok.find("道行精进!") >= 0, "注入 roll=0.01 道行精进成功: " + db_ok)
	check(g.dao_level == 1, "道行阶段 +1")
	check(g.last_break_result == 4, "道行精进 last_break_result==4")
	check(g.break_seq == dseq0 + 1, "道行精进 break_seq +1")
	g.dao = g.dao_break_cost() + 1.0
	var db_fail: String = g.try_dao_break(0.999)
	check(db_fail.find("道行精进失败") >= 0, "注入 roll=0.999 道行精进失败: " + db_fail)
	check(g.dao_level == 1, "失败后阶段不变")
	check(g.last_break_result == 2, "失败 last_break_result==2")
	check(g.dao_break_chance() >= 0.05 and g.dao_break_chance() <= 0.99, "道行成功率受控 5%%~99%% (实际 %0.0f%%)" % (g.dao_break_chance() * 100.0))
	# 飞升后进度条 = 道行比例
	g.dao = g.dao_break_cost() * 0.5
	check(absf(g.breakthrough_progress() - 50.0) < 1e-6, "飞升后进度=道行比例 (实际 %s)" % g.breakthrough_progress())
	# 封顶: 道祖
	g.dao_level = g.IMMORTAL_REALMS.size() - 1
	check(g.try_dao_break(0.01).find("道祖") >= 0, "道祖封顶提示 (实际: %s)" % g.try_dao_break(0.01))
	check(g.breakthrough_progress() == 100.0, "道祖进度 100%")
	check(g.ach_progress("dao_zuzi").find("道行精进中") >= 0, "ach_progress dao_zuzi 道行中 (实际 %s)" % g.ach_progress("dao_zuzi"))
	var got11: Array[String] = g.check_achievements()
	check(got11.has("dao_zuzi"), "道祖解锁 dao_zuzi: " + str(got11))
	g.ach_done.erase("dao_zuzi")
	g.dao_level = 0
	g.ascended = false
	check(g.ach_progress("dao_zuzi") == "飞升后, 道行精进至道祖境", "ach_progress dao_zuzi 未飞升 (实际 %s)" % g.ach_progress("dao_zuzi"))
	# 道行消耗梯度 (每阶 x8)
	var dc0: float = g.dao_break_cost()
	check(dc0 > 0.0, "道行基础消耗>0")
	for i in 8:
		var nxt: float = dc0 * g.DAO_BREAK_GROWTH
		check(nxt > dc0, "道行消耗第%d阶上升" % i)
		dc0 = nxt

	# ---------- 存档往返 ----------
	# 全购法器后灵石近 0, 补充灵石/道行再存档 (验证恢复逻辑)
	g.stones = 123456.0
	g.dao = 12345.678
	g.dao_level = 2
	g.save_game()
	var saved := _save_json()
	check(saved.has("skills") and saved.has("eq_owned") and saved.has("equipped"), "存档包含 skills/eq_owned/equipped 字段")
	check(saved.has("dao") and saved.has("dao_level"), "存档包含 dao/dao_level 字段 (打磨-10)")
	check(saved.has("ach_done"), "存档包含 ach_done 字段")
	check(saved.has("stats"), "存档包含 stats 字段 (打磨-14)")
	check(saved.get("realm_idx", -1) == g.realm_idx, "存档 realm_idx 一致")
	check(saved.get("essence", -1.0) == g.essence, "存档 essence 一致")
	# 清空后重新加载
	g.realm_idx = 0
	g.layer = 1
	g.learned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.ach_done.clear()
	g.stones = 0.0
	g.load_game()
	check(g.learned.has(passive_id), "读档恢复已学技能")
	check(g.owned_eq.has(eq_id), "读档恢复已购装备")
	check(str(g.equipped.get("weapon", "")) == eq_id, "读档恢复穿戴")
	check(g.ach_done.has("first_break"), "读档恢复已解锁成就")
	check(g.stones > 0.0, "读档恢复灵石")
	# 打磨-14: 统计存档往返 (前面各节已累积计数: 11 法器 / 12 装备 / 10 突破成功 / 3 神通施展)
	check(float(g.stats.get("item_buy", 0.0)) >= 10.0, "读档恢复统计 item_buy>=10 (打磨-14, 实际 %s)" % str(g.stats.get("item_buy")))
	check(float(g.stats.get("equip_buy", 0.0)) >= 12.0, "读档恢复统计 equip_buy>=12 (打磨-14, 实际 %s)" % str(g.stats.get("equip_buy")))
	check(float(g.stats.get("break_ok", 0.0)) >= 1.0, "读档恢复统计 break_ok>=1 (打磨-14, 实际 %s)" % str(g.stats.get("break_ok")))
	check(float(g.stats.get("skill_use", 0.0)) >= 1.0, "读档恢复统计 skill_use>=1 (打磨-14, 实际 %s)" % str(g.stats.get("skill_use")))
	# play_sec 存档往返: 读档后手动加时验证保存/读取通道
	g.stats["play_sec"] = 1234.5
	g.save_game()
	g.stats["play_sec"] = 0.0
	g.load_game()
	check(absf(g.stats["play_sec"] - 1234.5) < 1e-6, "play_sec 存读档往返 (打磨-14, 实际 %s)" % str(g.stats["play_sec"]))
	check(absf(g.dao - 12345.678) < 1e-9, "读档恢复道行 (打磨-10, 实际 %s)" % g.fmt(g.dao))
	check(g.dao_level == 2, "读档恢复道行阶段 (打磨-10)")
	# 旧档兼容: 缺新字段
	var f := FileAccess.open(g.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"realm_idx": 1, "layer": 2, "essence": 5.0, "stones": 7.0}))
	f.close()
	g.learned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.ach_done.clear()
	g.ach_done.append("stale")
	g.load_game()
	check(g.realm_idx == 1 and g.layer == 2, "旧档境界读取")
	check(g.learned.is_empty() and g.owned_eq.is_empty(), "旧档缺字段默认空")
	check(g.ach_done.is_empty(), "旧档缺 ach_done 默认空")
	check(g.stones == 7.0, "旧档灵石读取")
	check(float(g.stats.get("play_sec", -1.0)) == 0.0 and float(g.stats.get("item_buy", -1.0)) == 0.0, "旧档缺 stats 字段默认 0 (打磨-14)")

	# ---------- 打磨-10: 离线道行 (飞升后离线收益计入道行) ----------
	g.ascended = true
	g.dao_level = 0
	g.dao = 0.0
	g.essence = 0.0
	g.stones = 0.0
	g.realm_idx = 9
	g.layer = 1
	g.owned.clear()
	g.learned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.save_game()
	# 存档 ts 回拨 2 小时, 模拟离线
	var of := FileAccess.open(g.SAVE_PATH, FileAccess.READ)
	var ov: Variant = JSON.parse_string(of.get_as_text())
	of.close()
	var od: Dictionary = ov
	od["ts"] = int(Time.get_unix_time_from_system()) - 7200
	var ofw := FileAccess.open(g.SAVE_PATH, FileAccess.WRITE)
	ofw.store_string(JSON.stringify(od))
	ofw.close()
	g.essence = 0.0
	g.dao = 0.0
	g.load_game()
	# 纯挂机速率 = QI_MULT[9] = 1e5 (无加成), 离线效率 50%, 2h → 3.6e8
	check(g.dao >= 3.5e8 and g.dao <= 3.7e8, "离线道行 ≈ 3.6e8 (实际 %s)" % g.fmt(g.dao))
	check(g.essence == 0.0, "飞升后离线不涨灵气")
	check(g.offline_msg.find("道行") >= 0, "离线提示含道行 (实际 %s)" % g.offline_msg)

	# ---------- 打磨-11: 神通飞升后爆发转道行 ----------
	g.learned.append(active_id)
	g._active_cd.erase(active_id)
	var s_act2: Dictionary = g.skill_by_id[active_id]
	var dao_b4: float = g.dao
	var da_msg: String = g.use_active_skill(active_id)
	check(da_msg.find("获得道行") >= 0, "飞升后神通爆发文案为道行 (实际: %s)" % da_msg)
	check(g.dao >= dao_b4 + g.qi_per_sec() * float(s_act2["value"]) * 0.99, "飞升后神通爆发增加道行 (≈速率x秒数)")
	check(absf(g.essence) < 1e-9, "飞升后神通不增灵气")
	check(not g.active_ready(active_id), "飞升后神通同样进冷却")
	check(g.skill_detail(active_id).find("飞升后: 爆发转为获得道行") >= 0, "skill_detail 神通含飞升道行说明")
	# 未飞升路径回归: 爆发仍加灵气, 不增道行
	g.ascended = false
	var dao_b5: float = g.dao
	var ess_b5: float = g.essence
	g._active_cd.erase(active_id)
	var da_msg2: String = g.use_active_skill(active_id)
	check(da_msg2.find("获得灵气") >= 0, "未飞升神通爆发文案为灵气 (实际: %s)" % da_msg2)
	check(g.essence >= ess_b5 + g.qi_per_sec() * float(s_act2["value"]) * 0.99, "未飞升神通爆发增加灵气")
	check(absf(g.dao - dao_b5) < 1e-9, "未飞升神通不增道行")

	# ---------- 打磨-12: 购买 ETA (灵石不足 -> 预计多久买得起) ----------
	g.stones = 0.0
	g.learned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	# 无加成状态: 灵石速率 = QI_MULT[0] * 1.0 = 1.0/秒
	check(absf(g.stone_per_sec() - g.QI_MULT[0]) < 1e-9, "无加成灵石速率 = QI_MULT[0] (实际 %s)" % g.fmt(g.stone_per_sec()))
	g.stones = 100000.0
	check(g.eta_seconds(100000.0) == 0.0, "灵石足够 eta_seconds=0")
	check(g.eta_text(100000.0) == "", "灵石足够 eta_text 为空")
	g.stones = 0.0
	check(absf(g.eta_seconds(120.0) - 120.0) < 1e-6, "eta_seconds = (价格-灵石)/速率 (120秒, 实际 %s)" % g.eta_seconds(120.0))
	check(g.eta_text(120.0) == "约 2分 可购", "eta_text 分钟档 (实际 %s)" % g.eta_text(120.0))
	check(g.eta_text(30.0) == "不足1分可购", "eta_text 不足1分 (实际 %s)" % g.eta_text(30.0))
	check(g.eta_text(5400.0) == "约 1小时30分 可购", "eta_text 小时档 (实际 %s)" % g.eta_text(5400.0))
	# 差额部分: 已有灵石时只按缺口计算
	g.stones = 50.0
	check(absf(g.eta_seconds(120.0) - 70.0) < 1e-6, "eta 只按缺口计算 (50灵石->70秒, 实际 %s)" % g.eta_seconds(120.0))
	# fmt_time 回归: 短时长不再显示 0 分
	check(g.fmt_time(45.0) == "不足1分", "fmt_time 短时长 (实际 %s)" % g.fmt_time(45.0))
	check(g.fmt_time(7200.0) == "2小时0分", "fmt_time 小时档回归 (实际 %s)" % g.fmt_time(7200.0))

	# ---------- 打磨-13: 离线/挂机收益可视化 (offline_gain / offline_hourly) ----------
	# 当前受控状态: 无加成, 练气, 未飞升, qi/stone 速率均为 1.0/秒, 离线效率 50%
	var og: Dictionary = g.offline_gain(3600.0)
	check(absf(float(og["qi"]) - 1800.0) < 1e-6, "offline_gain 1h 灵气 = 速率x3600x0.5 = 1800 (实际 %s)" % g.fmt(float(og["qi"])))
	check(absf(float(og["stone"]) - 1800.0) < 1e-6, "offline_gain 1h 灵石 = 1800 (实际 %s)" % g.fmt(float(og["stone"])))
	check(float(og["sec"]) == 3600.0 and bool(og["capped"]) == false, "offline_gain 未封顶")
	check(absf(float(g.offline_hourly()["qi"]) - float(og["qi"])) < 1e-9, "offline_hourly == offline_gain(3600)")
	# 上限 8 小时: 超长离线按 8h 计
	var ogc: Dictionary = g.offline_gain(999999.0)
	check(absf(float(ogc["sec"]) - g.OFFLINE_CAP_SEC) < 1e-9, "offline_gain 超长按上限 8h (实际 %s)" % g.fmt(float(ogc["sec"])))
	check(bool(ogc["capped"]) == true, "offline_gain 超长按 capped=true")
	check(absf(float(ogc["qi"]) - 14400.0) < 1e-6, "offline_gain 封顶 8h 灵气 = 14400 (实际 %s)" % g.fmt(float(ogc["qi"])))
	check(absf(float(g.offline_gain(0.0)["qi"])) < 1e-9, "offline_gain 0 秒收益为 0")
	check(absf(float(g.offline_gain(-5.0)["qi"])) < 1e-9, "offline_gain 负秒按 0 处理")
	var oht: String = g.offline_hourly_text()
	check(oht.find("灵气 1800") >= 0 and oht.find("灵石 1800") >= 0 and oht.find("50%") >= 0 and oht.find("上限8小时") >= 0, "offline_hourly_text 未飞升含灵气/灵石/效率/上限 (实际 %s)" % oht)
	# 离线效率加成: 解锁并学习一个 offline_rate 被动 (最低为筑基第 2 层 divine_1_1), 小时收益随之提升
	g.realm_idx = 1
	g.layer = 2
	var off_skill := "divine_1_1"
	check(g.skill_by_id.has(off_skill) and str(g.skill_by_id[off_skill]["effect"]) == "offline_rate", "divine_1_1 为 offline_rate 被动 (实际 %s)" % str(g.skill_by_id.get(off_skill, {}).get("effect", "")))
	check(g.can_learn(off_skill), "筑基第 2 层可学离线功法")
	var rate_pre: float = g.offline_rate()
	var qi_pre13: float = g.qi_per_sec()
	g.learn_skill(off_skill)
	check(g.offline_rate() > rate_pre, "学习离线功法后 offline_rate 提升 (实际 %0.2f%%)" % (g.offline_rate() * 100.0))
	check(g.offline_hourly()["qi"] > qi_pre13 * 3600.0 * rate_pre, "离线小时收益随效率提升")
	g.realm_idx = 0
	g.layer = 1
	# 飞升后文案主资源改为道行 (不改变数值, 仅资源名; 同状态取基准)
	var oht_pre: String = g.offline_hourly_text()
	var oq_pre: float = float(g.offline_hourly()["qi"])
	g.ascended = true
	var oht_up: String = g.offline_hourly_text()
	check(oht_up.find("道行") >= 0 and oht_up.find("灵气") < 0, "offline_hourly_text 飞升后为道行 (实际 %s)" % oht_up)
	check(absf(float(g.offline_hourly()["qi"]) - oq_pre) < 1e-9, "飞升不改变离线数值 (仅资源名)")
	g.ascended = false
	check(g.offline_hourly_text() == oht_pre, "恢复未飞升后文案复原")
	check(g.learned.has(off_skill), "offline_rate 功法保留 (供存档往返节断言无副作用)")

	# ---------- 打磨-14: 修行统计 (计数/格式/存读档) ----------
	# 当前受控状态: 练气 1 层, 未飞升, stones=50, learned=[divine_1_1]
	check(g.fmt_stats_time(0.5) == "不足1分", "fmt_stats_time 短时长 (实际 %s)" % g.fmt_stats_time(0.5))
	check(g.fmt_stats_time(600.0) == "10分", "fmt_stats_time 分钟档 (实际 %s)" % g.fmt_stats_time(600.0))
	check(g.fmt_stats_time(5400.0) == "1小时30分", "fmt_stats_time 小时档 (实际 %s)" % g.fmt_stats_time(5400.0))
	check(g.fmt_stats_time(90000.0) == "1天1小时", "fmt_stats_time 天档 (实际 %s)" % g.fmt_stats_time(90000.0))
	var s14: Variant = g.stats.duplicate()
	# 突破成功/失败计数 (确定性注入 roll)
	g.essence = g.breakthrough_cost()
	g.try_breakthrough(0.01)
	check(float(g.stats["break_ok"]) == float(s14["break_ok"]) + 1.0, "突破成功 break_ok+1 (打磨-14, 实际 %s)" % str(g.stats["break_ok"]))
	g.essence = g.breakthrough_cost()
	g.try_breakthrough(0.999)
	check(float(g.stats["break_fail"]) == float(s14["break_fail"]) + 1.0, "突破失败 break_fail+1 (打磨-14, 实际 %s)" % str(g.stats["break_fail"]))
	# 神通施展计数
	g.learned.append(active_id)
	g._active_cd.erase(active_id)
	g.use_active_skill(active_id)
	check(float(g.stats["skill_use"]) == float(s14["skill_use"]) + 1.0, "神通施展 skill_use+1 (打磨-14, 实际 %s)" % str(g.stats["skill_use"]))
	# 法器/装备购置计数
	g.stones = 1000.0
	g.try_buy_item("wooden_sword")
	check(float(g.stats["item_buy"]) == float(s14["item_buy"]) + 1.0, "法器购置 item_buy+1 (打磨-14, 实际 %s)" % str(g.stats["item_buy"]))
	g.stones = 1e12
	g.buy_equipment(eq_id)
	check(float(g.stats["equip_buy"]) == float(s14["equip_buy"]) + 1.0, "装备购置 equip_buy+1 (打磨-14, 实际 %s)" % str(g.stats["equip_buy"]))
	# 重复购置不重复计数
	var ib_pre: float = g.stats["item_buy"]
	g.try_buy_item("wooden_sword")
	check(float(g.stats["item_buy"]) == ib_pre, "重复购置法器不重复计数 (打磨-14)")
	# 道行精进计数 (飞升后)
	g.ascended = true
	g.dao = g.dao_break_cost() + 1.0
	g.try_dao_break(0.01)
	check(float(g.stats["dao_ok"]) == float(s14["dao_ok"]) + 1.0, "道行精进 dao_ok+1 (打磨-14, 实际 %s)" % str(g.stats["dao_ok"]))
	g.ascended = false
	# stats_text 各段
	var stt: String = g.stats_text()
	check(stt.find("突破 %d 次" % int(g.stats["break_ok"])) >= 0, "stats_text 含突破计数 (实际 %s)" % stt)
	check(stt.find("装备 %d 件" % int(g.stats["equip_buy"])) >= 0, "stats_text 含装备计数 (实际 %s)" % stt)
	check(stt.find("神通") >= 0 and stt.find("法器") >= 0 and stt.find("道行精进") >= 0 and stt.find("修行") >= 0, "stats_text 含修行/神通/法器/道行段 (实际 %s)" % stt)

	# ---------- 打磨-19: 顶栏主资源切换 (飞升后 灵气 -> 道行) ----------
	g.ascended = false
	g.essence = 54321.0
	g.dao = 987654.0
	check(g.primary_res_name() == "灵气", "未飞升主资源名=灵气 (实际 %s)" % g.primary_res_name())
	check(absf(g.primary_res_value() - 54321.0) < 1e-9, "未飞升主资源值=essence (实际 %s)" % g.fmt(g.primary_res_value()))
	check(g.primary_res_text() == ("灵气 " + g.fmt(54321.0)), "未飞升顶栏主资源文本 (实际 %s)" % g.primary_res_text())
	g.ascended = true
	check(g.primary_res_name() == "道行", "飞升后主资源名=道行 (实际 %s)" % g.primary_res_name())
	check(absf(g.primary_res_value() - 987654.0) < 1e-9, "飞升后主资源值=dao (实际 %s)" % g.fmt(g.primary_res_value()))
	check(g.primary_res_text() == ("道行 " + g.fmt(987654.0)), "飞升后顶栏主资源文本 (实际 %s)" % g.primary_res_text())
	check((g.primary_res_name() == "道行") == g.ascended, "主资源名与飞升状态一致 (切换即生效)")
	g.ascended = false
	check(g.primary_res_name() == "灵气", "恢复未飞升后主资源复原为灵气")

	# ---------- 打磨-20: 技能品质筛选 (品质名接口 + 数据一致性) ----------
	check(g.skill_tier_name(0) == "凡品", "skill_tier_name 0=凡品 (实际 %s)" % g.skill_tier_name(0))
	check(g.skill_tier_name(5) == "仙品", "skill_tier_name 5=仙品 (实际 %s)" % g.skill_tier_name(5))
	check(g.skill_tier_name(-1) == "凡品" and g.skill_tier_name(99) == "仙品", "skill_tier_name 越界钳制 (实际 %s / %s)" % [g.skill_tier_name(-1), g.skill_tier_name(99)])
	var tier_ok := true
	var tier_dist: Dictionary = {}
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if g.skill_tier_name(int(s["tier"])) != str(s["tier_name"]):
			tier_ok = false
		tier_dist[str(s["tier_name"])] = int(tier_dist.get(str(s["tier_name"]), 0)) + 1
	check(tier_ok, "全部技能 tier_name 与 skill_tier_name(tier) 一致")
	check(tier_dist.size() == 6, "6 档品质均有技能 (实际 %d 档)" % tier_dist.size())
	for t in [0, 1, 2, 3, 4, 5]:
		check(int(tier_dist.get(g.skill_tier_name(t), 0)) == 20, "%s 档 20 个技能 (实际 %d)" % [g.skill_tier_name(t), int(tier_dist.get(g.skill_tier_name(t), 0))])

	# ---------- 打磨-21: 装备品质筛选 (品质名接口 + 数据一致性 + AND 叠加) ----------
	check(g.equip_tier_name(0) == "凡品", "equip_tier_name 0=凡品 (实际 %s)" % g.equip_tier_name(0))
	check(g.equip_tier_name(6) == "神品", "equip_tier_name 6=神品 (实际 %s)" % g.equip_tier_name(6))
	check(g.equip_tier_name(-1) == "凡品" and g.equip_tier_name(99) == "神品", "equip_tier_name 越界钳制 (实际 %s / %s)" % [g.equip_tier_name(-1), g.equip_tier_name(99)])
	var eq_tier_ok := true
	var eq_tier_dist: Dictionary = {}
	for id in g.equip_ids:
		var e: Dictionary = g.equip_by_id[id]
		if g.equip_tier_name(int(e["tier"])) != str(e["tier_name"]):
			eq_tier_ok = false
		eq_tier_dist[str(e["tier_name"])] = int(eq_tier_dist.get(str(e["tier_name"]), 0)) + 1
	check(eq_tier_ok, "全部装备 tier_name 与 equip_tier_name(tier) 一致")
	check(eq_tier_dist.size() == 7, "7 档品质均有装备 (实际 %d 档)" % eq_tier_dist.size())
	for t in [0, 1, 2, 3, 4, 5, 6]:
		check(int(eq_tier_dist.get(g.equip_tier_name(t), 0)) == 20, "%s 档 20 件装备 (实际 %d)" % [g.equip_tier_name(t), int(eq_tier_dist.get(g.equip_tier_name(t), 0))])
	# AND 叠加: 部位×品质 逐组合命中数 (每组合应恰 4 件 = 4 变体; weapon 全品质共 28 件)
	var combo_ok := true
	for slot in g.SLOTS:
		for t in 7:
			var n4 := 0
			for id in g.equip_ids:
				var eq_c: Dictionary = g.equip_by_id[id]
				if str(eq_c["slot"]) == slot and int(eq_c["tier"]) == t:
					n4 += 1
			if n4 != 4:
				combo_ok = false
	check(combo_ok, "AND 叠加: 每个部位x品质组合命中 4 件 (4 变体)")
	var weapon_total := 0
	for id in g.equip_ids:
		var eq_c2: Dictionary = g.equip_by_id[id]
		if str(eq_c2["slot"]) == "weapon":
			weapon_total += 1
	check(weapon_total == 28, "AND 叠加: weapon×全部品质 命中 28 件 (实际 %d)" % weapon_total)

	# ---------- 打磨-22: 装备列表排序 (已穿戴 > 已拥有 > 未拥有) ----------
	g.owned_eq.clear()   # 清掉前几节遗留的 weapon_0_0, 保证本组槽位假设成立
	g.equipped.clear()
	g.stones = 1e12
	g.buy_equipment("weapon_2_1")   # 武器槽空 -> 自动穿戴 (state 2)
	g.buy_equipment("robe_0_2")     # 法袍槽空 -> 自动穿戴 (state 2)
	g.buy_equipment("weapon_1_0")   # 武器槽已被占 -> 已拥有未穿戴 (state 1)
	g.buy_equipment("amulet_3_0")   # 玉佩槽空 -> 自动穿戴 (state 2)
	check(g.equip_state("weapon_2_1") == 2, "equip_state 已穿戴=2 (weapon_2_1)")
	check(g.equip_state("weapon_1_0") == 1, "equip_state 已拥有未穿戴=1 (weapon_1_0)")
	check(g.equip_state("robe_0_0") == 0, "equip_state 未拥有=0 (robe_0_0)")
	var eord: Array = g.equip_sort_order()
	check(eord.size() == g.equip_ids.size(), "equip_sort_order 含全部装备 (实际 %d/%d)" % [eord.size(), g.equip_ids.size()])
	var seen: Dictionary = {}
	var perm_ok := true
	for x in eord:
		if seen.has(x):
			perm_ok = false
		seen[x] = true
	check(perm_ok, "equip_sort_order 无重复 id")
	check(str(eord[0]) == "weapon_2_1", "已穿戴按数据序置顶 (首位 weapon_2_1, 实际 %s)" % str(eord[0]))
	check(str(eord[1]) == "robe_0_2" and str(eord[2]) == "amulet_3_0", "已穿戴组按 部位 数据序 (robe_0_2, amulet_3_0)")
	check(str(eord[3]) == "weapon_1_0", "已拥有未穿戴组紧随其后 (weapon_1_0)")
	var unowned_seq: Array = []
	for id in g.equip_ids:
		if g.equip_state(id) == 0:
			unowned_seq.append(id)
	var prev_i := -1
	var mono_ok := true
	for x in eord:
		if g.equip_state(str(x)) == 0:
			var pos: int = unowned_seq.find(x)
			if pos <= prev_i:
				mono_ok = false
			prev_i = pos
	check(mono_ok, "未拥有组内部保持数据序 (稳定)")
	var det2: Array = g.equip_sort_order()
	check(det2 == eord, "同状态重复调用顺序一致 (确定性)")
	# 卸下武器 -> weapon_2_1 降为 state 1, 法袍件升为首位
	g.unequip("weapon")
	var eord2: Array = g.equip_sort_order()
	check(str(eord2[0]) == "robe_0_2", "卸下后首位换为当前已穿戴件 (实际 %s)" % str(eord2[0]))
	check(eord2.find("weapon_1_0") < eord2.find("weapon_2_1"), "同为已拥有未穿戴时保持数据序 (weapon_1_0 < weapon_2_1)")
	check(g.equip_sort_order() == eord2, "状态变化后新顺序稳定 (确定性)")

	# ---------- 打磨-23: 一键领悟 / 一键购买 (批量操作 QoL) ----------
	# 受控状态: 清掉前几节遗留, 练气第 1 层 (tier0 解锁境界=0; 各档 20 个, layer1 可学 11)
	g.learned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	var ra0: Dictionary = g.learn_all_available()
	check(int(ra0["count"]) == 11, "一键领悟 练气第1层 学 11 (实际 %s)" % str(ra0))
	check(g.learned.size() == 11, "learned 恰好 11 (实际 %d)" % g.learned.size())
	check(int(g.learn_all_available()["count"]) == 0, "一键领悟 幂等 (重复 0)")
	# 品质/类别筛选叠加 (先取计数再断言, 避免二次调用把结果学走)
	g.learned.clear()
	var c_t0: Dictionary = g.learn_all_available("", 0)
	check(int(c_t0["count"]) == 11, "一键领悟 品质筛选 tier0 学 11 (实际 %d)" % int(c_t0["count"]))
	g.learned.clear()
	var c_sword: Dictionary = g.learn_all_available("sword", -1)
	check(int(c_sword["count"]) == 2, "一键领悟 类别筛选 sword 学 2 (实际 %d)" % int(c_sword["count"]))
	g.learned.clear()
	var c_sw_t0: Dictionary = g.learn_all_available("sword", 0)
	check(int(c_sw_t0["count"]) == 2, "一键领悟 类别x品质 AND 叠加 sword+t0 学 2 (实际 %d)" % int(c_sw_t0["count"]))
	g.learned.clear()
	var c_div: Dictionary = g.learn_all_available("divine", 1)
	check(int(c_div["count"]) == 0, "一键领悟 境界不足组合 0 (divine t1 需筑基, 实际 %d)" % int(c_div["count"]))
	# 境界门槛: 筑基第 3 层 -> tier0 全 20 + tier1 全 20 = 40
	g.learned.clear()
	g.realm_idx = 1
	g.layer = 3
	var ra13: Dictionary = g.learn_all_available()
	check(int(ra13["count"]) == 40, "一键领悟 筑基第3层 tier0+1 学 40 (实际 %s)" % str(ra13))
	check(g.learned.size() == 40, "learned 恰好 40 (实际 %d)" % g.learned.size())
	# 已学不重复: 升金丹第 1 层, 只剩 tier2 中 layer1 的 11 个可学
	g.realm_idx = 2
	g.layer = 1
	var ra2: Dictionary = g.learn_all_available()
	check(int(ra2["count"]) == 11, "一键领悟 金丹第1层 只学剩余 11 (实际 %s)" % str(ra2))
	check(int(g.learn_all_available()["count"]) == 0, "再次一键领悟 0 (幂等)")
	# 一键购买: 价格升序连买 (4 件 100 价 = amulet/bead/boot/robe v0, weapon 为第 5 件)
	g.learned.clear()
	g.realm_idx = 0
	g.layer = 1
	g.stones = 0.0
	g.owned_eq.clear()
	g.equipped.clear()
	var rb0: Dictionary = g.buy_affordable()
	check(int(rb0["count"]) == 0, "一键购买 灵石 0 买 0 (实际 %s)" % str(rb0))
	g.stones = 400.0
	var rb1: Dictionary = g.buy_affordable()
	check(int(rb1["count"]) == 4, "一键购买 400 灵石买 4 件 (实际 %s)" % int(rb1["count"]))
	check(g.owned_eq.size() == 4, "owned_eq 恰好 4 (实际 %d)" % g.owned_eq.size())
	check(absf(g.stones) < 1e-6, "一键购买扣光 4 件 x100 (剩 %s)" % g.fmt(g.stones))
	check(g.equipped.size() == 4, "槽位空时自动穿戴 4 件 (实际 %d 槽)" % g.equipped.size())
	check(str(g.equipped.get("robe", "")) != "" and str(g.equipped.get("amulet", "")) != "" and str(g.equipped.get("bead", "")) != "" and str(g.equipped.get("boot", "")) != "", "自动穿戴 robe/amulet/bead/boot")
	check(int(g.buy_affordable()["count"]) == 0, "灵石花到买不起为止 (再买 0)")
	# 零头再买: 55 灵石仍买不起下一件 -> 0
	g.stones = 55.0
	var rb1b: Dictionary = g.buy_affordable()
	check(int(rb1b["count"]) == 0 and g.stones == 55.0, "55 灵石再买 0 (剩 55)")
	# 已拥有不再买: 满灵石只补剩下的 136 件
	g.stones = 1e12
	var rb3: Dictionary = g.buy_affordable()
	check(int(rb3["count"]) == 136, "一键购买 满灵石补 136 件 (实际 %s)" % int(rb3["count"]))
	check(g.owned_eq.size() == g.equip_ids.size(), "一键购买后拥有全部装备")
	check(g.equipped.size() == 5, "5 槽位全部自动穿戴")
	var rb4: Dictionary = g.buy_affordable()
	check(int(rb4["count"]) == 0, "全部拥有后一键购买 0 (幂等)")

	# ---------- 打磨-24: 突破 ETA (主资源攒够突破耗时; 飞升后自动切换道行精进 ETA) ----------
	# 受控状态: 练气第 1 层, 无加成, qi = 1.0/秒 (QI_MULT[0] x 1 x 1), essence = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	var bcost: float = g.breakthrough_cost()  # 10.0
	check(absf(bcost - 10.0) < 1e-9, "突破消耗基准 10 灵气 (实际 %s)" % bcost)
	check(absf(g.breakthrough_eta_seconds() - bcost) < 1e-6, "eta_seconds = 缺口/灵气速率 (10秒, 实际 %s)" % g.breakthrough_eta_seconds())
	check(g.breakthrough_eta_text() == "突破还需 不足1分", "eta_text 不足1分档 (实际 %s)" % g.breakthrough_eta_text())
	# 缺口部分: 已有灵气时只按缺口计算
	g.essence = 5.0
	check(absf(g.breakthrough_eta_seconds() - 5.0) < 1e-6, "eta 只按缺口计算 (5灵气->5秒, 实际 %s)" % g.breakthrough_eta_seconds())
	# 文本分档
	g.essence = 0.0
	check(g.breakthrough_eta_text() == "突破还需 不足1分", "eta_text 突破还需前缀")
	g.essence = -5000.0  # 等效缺口 5010 秒 = 1小时23分
	check(g.breakthrough_eta_text() == "突破还需 1小时23分", "eta_text 小时档 (实际 %s)" % g.breakthrough_eta_text())
	g.essence = 0.0
	# 攒够 = 现在即可突破 (空文本, UI 隐藏)
	g.essence = bcost
	check(g.breakthrough_eta_seconds() == 0.0, "灵气足量 eta_seconds=0")
	check(g.breakthrough_eta_text() == "", "灵气足量 eta_text 为空")
	# 学一个 qi_mult 被动 (mind_0_0, 练气第1层 +3%) 后速率提升 -> ETA 变短
	g.essence = 0.0
	var eta_pre24: float = g.breakthrough_eta_seconds()
	g.learn_skill("mind_0_0")
	var eta_post24: float = g.breakthrough_eta_seconds()
	check(g.qi_per_sec() > 1.0, "学功法后灵气速率提升 (实际 x%.3f)" % g.qi_per_sec())
	check(eta_post24 < eta_pre24, "学功法后突破 ETA 变短 (%.3f -> %.3f 秒)" % [eta_pre24, eta_post24])
	# 境界提升: 消耗跳升 (筑基第1层 = 30) 但速率也升 (x4) -> ETA 仍可控
	g.learned.clear()  # 清掉 mind_0_0, 速率恰为 QI_MULT[1] = 4.0
	g.essence = 0.0
	g.realm_idx = 1
	g.layer = 1
	check(absf(g.breakthrough_cost() - 30.0) < 1e-9, "筑基消耗 30 (实际 %s)" % g.breakthrough_cost())
	check(absf(g.breakthrough_eta_seconds() - 7.5) < 1e-6, "筑基 ETA = 30/4 = 7.5秒 (实际 %s)" % g.breakthrough_eta_seconds())
	g.realm_idx = 0
	# 飞升后: ETA 切换为道行精进 (dao_break_cost 初仙 = 1e9, 飞升后 qi = QI_MULT[9] x 道行倍率)
	g.ascended = true
	g.dao_level = 0
	g.dao = 0.0
	g.realm_idx = 9
	var dcost24: float = g.dao_break_cost()
	check(absf(dcost24 - 1.0e9) < 1.0, "道行精进基础消耗 1e9 (实际 %s)" % g.fmt(dcost24))
	var qir: float = g.qi_per_sec()
	check(absf(g.breakthrough_eta_seconds() - dcost24 / qir) < 1e-6, "飞升后 eta = 道行缺口/道行速率 (实际 %s, 期望 %s)" % [g.breakthrough_eta_seconds(), dcost24 / qir])
	check(g.breakthrough_eta_text().find("道行精进还需") >= 0, "飞升后前缀切换为 道行精进还需 (实际 %s)" % g.breakthrough_eta_text())
	# 道祖封顶: 无需再精进 -> 0 + 空文本
	g.dao_level = g.IMMORTAL_REALMS.size() - 1
	check(g.breakthrough_eta_seconds() == 0.0, "道祖封顶 eta_seconds=0")
	check(g.breakthrough_eta_text() == "", "道祖封顶 eta_text 为空")
	g.ascended = false
	g.realm_idx = 0
	g.layer = 1

	# ---------- 打磨-25: 换装对比提示 (穿上本件后该部位 灵气/灵石 差值) ----------
	# 受控状态: 全清空, 练气第 1 层
	g.stones = 1e12
	g.buy_equipment("weapon_2_1")   # 武器槽空 -> 自动穿戴
	check(str(g.equipped_at("weapon").get("id", "")) == "weapon_2_1", "equipped_at 返回当前穿戴 (weapon_2_1)")
	check(g.equipped_at("robe").is_empty(), "equipped_at 空槽位返回 {}")
	var e25a: Dictionary = g.equip_by_id["weapon_1_0"]
	var e25b: Dictionary = g.equip_by_id["weapon_2_1"]
	var swA: Dictionary = g.equip_swap_hint("weapon_1_0")   # 灵剑 vs 已穿紫刀
	check(str(swA["replace_name"]) == str(e25b["name"]), "swap_hint 替换对象为当前穿戴 (实际 %s)" % str(swA["replace_name"]))
	check(absf(float(swA["d_qi"]) - (float(e25a["qi_mult"]) - float(e25b["qi_mult"]))) < 1e-9, "swap_hint d_qi = 新-旧 (实际 %s)" % str(swA["d_qi"]))
	check(float(swA["d_qi"]) < 0.0, "低级件 vs 已穿高级件 d_qi 为负")
	check(str(swA["text"]).find("替换「%s」: " % str(e25b["name"])) == 0, "swap_hint text 前缀 替换「当前穿戴」 (实际 %s)" % str(swA["text"]))
	check(str(swA["text"]).find("灵气-") >= 0, "swap_hint text 含灵气负差 (实际 %s)" % str(swA["text"]))
	check(str(swA["text"]).find("灵石-") >= 0, "swap_hint text 含灵石负差 (实际 %s)" % str(swA["text"]))
	check(str(g.equip_swap_hint("weapon_2_1")["text"]) == "", "穿上自身 text 为空 (自身不算替换)")
	check(float(g.equip_swap_hint("weapon_2_1")["d_qi"]) == 0.0, "穿上自身 d_qi=0")
	check(str(g.equip_swap_hint("robe_0_0")["text"]) == "", "空槽位 text 为空 (纯增益)")
	check(g.equip_swap_hint("robe_0_0")["d_qi"] == 0.0, "空槽位 d_qi=0")
	check(str(g.equip_swap_hint("not_exist")["text"]) == "", "未知 id text 为空")
	# 换装: 穿上更高品质武器后, 旧件对比符号翻正
	g.buy_equipment("weapon_5_0")
	g.equip_equipment("weapon_5_0")
	var swB: Dictionary = g.equip_swap_hint("weapon_2_1")   # 紫刀 vs 已穿仙品
	check(float(swB["d_qi"]) < 0.0, "仙品穿戴后 紫刀 d_qi 仍为负 (紫刀更弱, 实际 %s)" % str(swB["d_qi"]))
	var swC: Dictionary = g.equip_swap_hint("weapon_5_0")
	check(str(swC["text"]) == "", "已穿戴仙品自身 text 为空")
	# 正差场景: 卸下仙品, 穿回紫刀, 再看仙品 -> 正差带 +
	g.unequip("weapon")
	g.equip_equipment("weapon_2_1")
	var swD: Dictionary = g.equip_swap_hint("weapon_5_0")
	check(float(swD["d_qi"]) > 0.0, "穿上更强件 d_qi 为正 (实际 %s)" % str(swD["d_qi"]))
	check(str(swD["text"]).find("灵气+") >= 0, "swap_hint text 正差带+号 (实际 %s)" % str(swD["text"]))
	check(str(swD["text"]).find(str(e25b["name"])) >= 0, "swap_hint text 含被替换件名")
	# equip_detail 换装对比行 (随穿戴状态出现/消失)
	check(g.equip_detail("weapon_5_0").find("换装对比:") >= 0, "equip_detail 含换装对比行 (实际: %s)" % g.equip_detail("weapon_5_0"))
	var det25_before: String = g.equip_detail("weapon_5_0")
	g.unequip("weapon")
	check(g.equip_detail("weapon_5_0").find("换装对比:") < 0, "卸下后 equip_detail 无换装对比行")
	check(g.equip_detail("weapon_5_0") != det25_before, "detail 随穿戴状态变化而变化")

	# ---------- 打磨-26: 一键最佳穿戴 (各槽位自动穿上拥有的最佳件) ----------
	# 受控状态: 全清空, 练气第 1 层, 满灵石
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 1e12
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	# 购买 3 件武器 (价格升序): 第一件自动穿戴 (最便宜)
	g.buy_equipment("weapon_0_0")   # 凡品, 槽位空 -> 自动穿戴
	g.buy_equipment("weapon_2_1")   # 玄品, 槽位已占 -> 未穿戴
	g.buy_equipment("weapon_5_0")   # 仙品, 槽位已占 -> 未穿戴
	check(str(g.equipped.get("weapon", "")) == "weapon_0_0", "最佳穿戴前提: 初始自动穿戴为最便宜 weapon_0_0 (实际 %s)" % str(g.equipped.get("weapon", "")))
	check(g.equip_best_id("weapon") == "weapon_5_0", "equip_best_id 取该部位主属性最佳 (weapon_5_0, 实际 %s)" % g.equip_best_id("weapon"))
	check(g.equip_best_id("weapon") == g.equip_best_id("weapon"), "equip_best_id 确定性 (重复调用一致)")
	check(g.equip_best_id("robe") == "", "equip_best_id 空槽位返回空")
	check(g.equip_best_pending() == 1, "equip_best_pending = 1 (仅武器槽非最佳, 实际 %d)" % g.equip_best_pending())
	var eb0: Dictionary = g.equip_best()
	check(int(eb0["count"]) == 1, "一键最佳穿戴 变更 1 槽 (实际 %s)" % str(eb0))
	check(str(g.equipped.get("weapon", "")) == "weapon_5_0", "最佳穿戴后武器槽为最佳件 weapon_5_0")
	check(g.equip_best_pending() == 0, "最佳穿戴后 pending = 0")
	var eb1: Dictionary = g.equip_best()
	check(int(eb1["count"]) == 0, "一键最佳穿戴 幂等 (再执行 0)")
	# 多部位: 各槽位买 最佳件 + 干扰件, 验证仅法袍槽变更
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 1e12
	g.buy_equipment("robe_0_0")     # 自动穿戴 (最便宜)
	g.buy_equipment("robe_4_2")     # 天品 v2, 更优
	g.buy_equipment("amulet_1_1")   # 自动穿戴 (唯一一件)
	g.buy_equipment("bead_3_0")     # 自动穿戴 (唯一一件)
	g.buy_equipment("boot_2_0")     # 自动穿戴 (唯一一件)
	var eb2: Dictionary = g.equip_best()
	check(str(g.equipped.get("robe", "")) == "robe_4_2", "多部位: 法袍槽为最佳 robe_4_2 (实际 %s)" % str(g.equipped.get("robe", "")))
	check(str(g.equipped.get("amulet", "")) == "amulet_1_1", "玉佩槽不变 (唯一一件即最佳)")
	check(str(g.equipped.get("bead", "")) == "bead_3_0", "灵珠槽不变")
	check(str(g.equipped.get("boot", "")) == "boot_2_0", "云靴槽不变")
	check(int(eb2["count"]) == 1, "多部位: 仅法袍槽变更 (实际 %s)" % str(eb2))
	check(g.equip_best_pending() == 0, "多部位最佳穿戴后 pending = 0")

	# ---------- 打磨-27: 一键领悟按钮计数口径 (筛选范围内可学数, 与 learn_all_available 执行一致) ----------
	# 受控状态: 全清空, 练气第 1 层 (全局可学 11 = tier0 中 layer1 的 11 个)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	check(g.learn_available_count() == 11, "learn_available_count 全局 练气第1层 = 11 (实际 %d)" % g.learn_available_count())
	# 口径一致性: count 恒等于 learn_all_available 实际学到的数量 (点击执行即计数)
	var la27: Dictionary = g.learn_all_available()
	check(int(la27["count"]) == 11, "learn_all_available 全局学 11 (实际 %s)" % str(la27))
	g.learned.clear()
	# 类别筛选: sword 可学 2 (凡品 layer1 的两个变体)
	check(g.learn_available_count("sword", -1) == 2, "learn_available_count 类别 sword = 2 (实际 %d)" % g.learn_available_count("sword", -1))
	var la27b: Dictionary = g.learn_all_available("sword", -1)
	check(int(la27b["count"]) == 2, "类别口径: 执行数 = 执行前计数 (2, 实际 %s)" % str(la27b))
	check(g.learned.size() == 2, "类别筛选执行恰好 2 (实际 %d)" % g.learned.size())
	check(g.learn_available_count("sword", -1) == 0, "类别筛选执行后计数归 0 (幂等)")
	g.learned.clear()
	# 品质筛选: tier0 可学 11; tier1 需筑基 -> 0
	check(g.learn_available_count("", 0) == 11, "learn_available_count 品质 tier0 = 11 (实际 %d)" % g.learn_available_count("", 0))
	check(g.learn_available_count("", 1) == 0, "learn_available_count 品质 tier1 境界不足 = 0")
	# 类别×品质 AND 叠加: sword+t0 = 2, sword+t1 = 0
	check(g.learn_available_count("sword", 0) == 2, "learn_available_count sword×tier0 = 2 (实际 %d)" % g.learn_available_count("sword", 0))
	check(g.learn_available_count("sword", 1) == 0, "learn_available_count sword×tier1 = 0 (筑基门槛)")
	# 已学部分后计数递减 (学掉 sword 的 2 个, 全局 11 -> 9)
	var la27c: Dictionary = g.learn_all_available("sword", 0)
	check(g.learn_available_count() == 9, "学掉 2 个后全局计数递减 11->9 (实际 %d)" % g.learn_available_count())
	# 境界提升: 筑基第 3 层 tier0+1 共 40, 减去已学 sword2 凡品 -> 38
	g.realm_idx = 1
	g.layer = 3
	check(g.learn_available_count() == 38, "筑基第3层 计数 38 = 40-已学2 (实际 %d)" % g.learn_available_count())
	g.realm_idx = 0
	g.layer = 1

	# ---------- 打磨-28: 收集进度一览 (collect_summary / collect_summary_text) ----------
	# 受控状态: 清空装备/法器 (打磨-26/27 段遗留), 保留 已学 2 剑法 (learned=2), 练气第1层
	g.learned.clear()
	g.learn_all_available("sword", 0)  # 受控: 恰好学 2 个
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	var cs28: Dictionary = g.collect_summary()
	check(cs28.has("skill") and cs28.has("equip") and cs28.has("item") and cs28.has("ach"), "collect_summary 含 技能/装备/法器/成就 四类")
	check(int(cs28["skill"]["got"]) == 2 and int(cs28["skill"]["total"]) == g.skill_ids.size(), "collect_summary 技能 = 已学数/总量 (实际 %s)" % str(cs28["skill"]))
	check(int(cs28["equip"]["got"]) == 0 and int(cs28["equip"]["total"]) == g.equip_ids.size(), "collect_summary 装备 = 0/140 (实际 %s)" % str(cs28["equip"]))
	check(int(cs28["item"]["got"]) == 0 and int(cs28["item"]["total"]) == 10, "collect_summary 法器 = 0/10 (实际 %s)" % str(cs28["item"]))
	check(int(cs28["ach"]["total"]) == g.ach_ids.size(), "collect_summary 成就总量 = 成就数 (实际 %s)" % str(cs28["ach"]))
	check(int(cs28["ach"]["got"]) == g.ach_done.size(), "collect_summary 成就已解锁数 = ach_done 数 (实际 %s)" % str(cs28["ach"]))
	# 总量合计恒等: 总 = 120+140+10+17 = 287 (数据驱动, 用实际总量校验)
	var t28 := 0
	for k in cs28:
		t28 += int(cs28[k]["total"])
	check(t28 == 287, "收集总量合计 = 287 (实际 %d)" % t28)
	var txt28: String = g.collect_summary_text()
	check(txt28.begins_with("收集进度"), "collect_summary_text 以 收集进度 开头 (实际 %s)" % txt28)
	check(txt28.find("技能 2/%d" % g.skill_ids.size()) >= 0, "收集文本含 技能 2/120 (实际 %s)" % txt28)
	check(txt28.find("装备 0/%d" % g.equip_ids.size()) >= 0, "收集文本含 装备 0/140 (实际 %s)" % txt28)
	check(txt28.find("法器 0/10") >= 0, "收集文本含 法器 0/10")
	check(txt28.find("(总 %d/%d)" % [2 + g.ach_done.size(), 287]) >= 0, "收集文本含 总 N/287 (实际 %s)" % txt28)
	# 收集变化 -> 文本变化 (购买 1 件装备后)
	g.stones = 1e12
	g.buy_equipment("weapon_0_0")
	var txt28b: String = g.collect_summary_text()
	check(txt28b != txt28, "购买装备后收集文本变化")
	check(txt28b.find("装备 1/%d" % g.equip_ids.size()) >= 0, "收集文本装备更新为 1/140 (实际 %s)" % txt28b)
	# 已收集类计数只增不减 (卸下/换装不影响收集数)
	g.unequip("weapon")
	check(int(g.collect_summary()["equip"]["got"]) == 1, "卸下装备不影响收集计数 (只增不减)")

	# ---------- 打磨-29: 法器 一键购买 (价格升序连买买得起的, 与装备 一键购买 口径一致) ----------
	# 受控状态: 清掉前节遗留法器, 灵石从 0 开始
	g.owned.clear()
	g.stones = 0.0
	var ib_stats0: int = int(g.stats.get("item_buy", 0.0))
	var ib0: Dictionary = g.buy_items_affordable()
	check(int(ib0["count"]) == 0 and g.owned.size() == 0, "法器一键购买 灵石 0 买 0 (实际 %s)" % str(ib0))
	check(g.item_affordable_count() == 0, "item_affordable_count 灵石 0 = 0")
	g.stones = 100.0
	check(g.item_affordable_count() == 1, "item_affordable_count 100 灵石 = 1 (实际 %d)" % g.item_affordable_count())
	var ib1: Dictionary = g.buy_items_affordable()
	check(int(ib1["count"]) == 1, "法器一键购买 100 灵石买 1 件 (实际 %s)" % str(ib1))
	check(g.owned.has("wooden_sword"), "买到的最便宜法器 = 木剑 (价格升序)")
	check(absf(g.stones) < 1e-6, "法器一键购买扣光 100 灵石 (剩 %s)" % g.fmt(g.stones))
	# 200 灵石: 玉符 1000 买不起 -> 只买 0 件新的 (木剑已拥有)
	g.stones = 200.0
	var ib2: Dictionary = g.buy_items_affordable()
	check(int(ib2["count"]) == 0 and g.owned.size() == 1, "200 灵石再买 0 (下一件 1000 买不起, 实际 %s)" % str(ib2))
	# 1100 灵石: 连买 玉符(1000) 后剩 100, 无更便宜的未拥有件 -> 1 件
	g.stones = 1100.0
	var ib3: Dictionary = g.buy_items_affordable()
	check(int(ib3["count"]) == 1 and g.owned.has("jade_talisman"), "1100 灵石买 玉符 1 件 (实际 %s)" % str(ib3))
	check(absf(g.stones - 100.0) < 1e-6, "买 玉符 后剩 100 灵石 (实际 %s)" % g.fmt(g.stones))
	# 7000 灵石: 买起 聚灵袋(6000) 后剩 1000, 仍买不起 引星灯(45000) -> 1 件
	g.stones = 7000.0
	var ib4: Dictionary = g.buy_items_affordable()
	check(int(ib4["count"]) == 1 and g.owned.has("spirit_bag"), "7000 灵石买 聚灵袋 (实际 %s)" % str(ib4))
	check(g.item_affordable_count() == 0, "买完后 item_affordable_count 归 0")
	check(int(g.stats.get("item_buy", 0.0)) == ib_stats0 + 3, "item_buy 统计 +3 (实际 %s)" % str(int(g.stats.get("item_buy", 0.0))))
	# 满灵石: 补齐剩余 7 件, 全部拥有
	g.stones = 1e13
	var ib5: Dictionary = g.buy_items_affordable()
	check(int(ib5["count"]) == 7, "满灵石补齐 7 件法器 (实际 %s)" % str(ib5))
	check(g.owned.size() == g.ITEMS.size(), "法器一键购买后拥有全部 10 件")
	var ib6: Dictionary = g.buy_items_affordable()
	check(int(ib6["count"]) == 0 and g.owned.size() == 10, "全部拥有后法器一键购买 0 (幂等)")
	check(g.item_affordable_count() == 0, "全部拥有后 item_affordable_count = 0")
	# 幂等性: 重复购买不重复扣灵石/不重复入账
	var stones_before: float = g.stones
	var boost_before: float = g.item_boost()
	g.buy_items_affordable()
	check(g.stones == stones_before and g.item_boost() == boost_before, "幂等: 重复购买不扣灵石/不加成")

	# ---------- 汇报 ----------
	print("")
	if _fail.is_empty():
		print("SELFTEST PASS  %d 项全部通过" % _pass_count)
		quit(0)
	else:
		printerr("SELFTEST FAIL  %d 通过 / %d 失败:" % [_pass_count, _fail.size()])
		for x in _fail:
			printerr("  - " + x)
		var rf := FileAccess.open("user://selftest_result.txt", FileAccess.WRITE)
		if rf != null:
			rf.store_string("\n".join(_fail))
			rf.close()
		quit(1)
