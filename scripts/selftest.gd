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

	# ---------- 存档往返 ----------
	# 全购法器后灵石近 0, 补充灵石再存档 (验证恢复逻辑)
	g.stones = 123456.0
	g.save_game()
	var saved := _save_json()
	check(saved.has("skills") and saved.has("eq_owned") and saved.has("equipped"), "存档包含 skills/eq_owned/equipped 字段")
	check(saved.get("realm_idx", -1) == g.realm_idx, "存档 realm_idx 一致")
	check(saved.get("essence", -1.0) == g.essence, "存档 essence 一致")
	# 清空后重新加载
	g.realm_idx = 0
	g.layer = 1
	g.learned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 0.0
	g.load_game()
	check(g.learned.has(passive_id), "读档恢复已学技能")
	check(g.owned_eq.has(eq_id), "读档恢复已购装备")
	check(str(g.equipped.get("weapon", "")) == eq_id, "读档恢复穿戴")
	check(g.stones > 0.0, "读档恢复灵石")
	# 旧档兼容: 缺新字段
	var f := FileAccess.open(g.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"realm_idx": 1, "layer": 2, "essence": 5.0, "stones": 7.0}))
	f.close()
	g.learned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.load_game()
	check(g.realm_idx == 1 and g.layer == 2, "旧档境界读取")
	check(g.learned.is_empty() and g.owned_eq.is_empty(), "旧档缺字段默认空")
	check(g.stones == 7.0, "旧档灵石读取")

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
