extends Node
## 打磨-40: 成就页进度条 UI 断言 (headless 可跑, scene 模式带 autoload GameData/Steam)
## 打磨-41: 技能/装备/法器 行首品质色竖条断言 (存在/首子节点/颜色与数据 tier 或价格档一致)
## 打磨-42: 成就页顶栏收集进度一览 mini 进度条断言 (4 条节点/0 填充/满态金/半态比例/节流缓存)
## 打磨-43: 收集进度一览加 总计 mini 进度条断言 (5 条节点/总计=10/287 与 137/287 两态/wrap 换行布局)
## 运行: timeout 30 ~/bin/godot --headless --path . res://scenes/ui_test.tscn
## 退出码 0 = 通过, 非 0 = 失败 (失败详情写入 user://ui_test_result.txt)
## 说明: 实例化主场景 (UI 全代码构建), 直接驱动 _refresh 断言进度条节点/宽度/颜色/tooltip;
##       headless 无真实像素渲染, 故断言布局几何 (size) 而非像素颜色。

const UI_SIZE := Vector2(1280, 720)

var _fail: Array[String] = []
var _pass := 0
var ui: Node = null


func check(c: bool, label: String) -> void:
	if c:
		_pass += 1
	else:
		_fail.append(label)
		printerr("FAIL: " + label)


func _ready() -> void:
	# 先等一帧, 避开 _ready 期间 add_child 的 busy 限制 (UITest 自身还在入场)
	await get_tree().process_frame
	# 清理旧存档, 保证初始态干净 (须在实例化主场景前; 同 selftest.gd)
	var sp: String = GameData.SAVE_PATH
	var old := FileAccess.open(sp, FileAccess.READ)
	if old != null:
		old.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sp))
	# autoload GameData 启动时已 load_game, 须重置内存态 (旧档内容仍在内存)
	var g0 := GameData
	g0.ach_done.clear()
	g0.realm_idx = 0
	g0.layer = 1
	g0.essence = 0.0
	g0.stones = 0.0
	g0.dao = 0.0
	g0.dao_level = 0
	g0.ascended = false
	g0.learned.clear()
	g0.owned.clear()
	g0.owned_eq.clear()
	g0.equipped.clear()
	g0.stats = {}
	# 冻结 GameData 挂机/成就/自动存档 (同 store_shots.gd), 由 UI 手动驱动 _refresh
	g0.set_process(false)
	var script: GDScript = load("res://scripts/main.gd")
	ui = Control.new()
	ui.set_script(script)
	var root := get_tree().root
	root.size = Vector2i(UI_SIZE)
	ui.size = UI_SIZE
	root.add_child(ui)
	await get_tree().process_frame
	await get_tree().process_frame
	# 成就页 (index 3), 首帧已 _ready 构建 UI; 再驱动一次 _refresh 确保进度条/排序刷完
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	_assert_initial()
	await _assert_collect_bars_initial()
	_mutate_state()
	await _assert_tier_bars()
	await _assert_collect_bars_mutated()
	_finish()


# 初始态 (全新档, 未成就页): 17 条进度条, 未解锁青色 0 填充, tooltip 进度 0%, 顶栏计数 0/17
func _assert_initial() -> void:
	var g := GameData
	check(g.ach_done.size() == 0, "初始态 无已解锁成就 (实际 %d)" % g.ach_done.size())
	check(ui._ach_rows.size() == g.ach_ids.size(), "成就行数量=%d (实际 %d)" % [g.ach_ids.size(), ui._ach_rows.size()])
	for id in g.ach_ids:
		var r: Dictionary = ui._ach_rows.get(id, {})
		var bg: ColorRect = r.get("bar_bg", null)
		var fill: ColorRect = r.get("bar_fill", null)
		check(bg != null and fill != null, "成就 %s 进度条节点存在" % id)
		if bg == null or fill == null:
			continue
		check(int(bg.size.x) > 0, "成就 %s 进度条背景布局宽>0 (实际 %d)" % [id, int(bg.size.x)])
		check(int(fill.size.x) == 0, "成就 %s 未解锁进度条 0 填充 (实际 %d)" % [id, int(fill.size.x)])
		check(fill.size.y == bg.size.y, "成就 %s 进度条高与背景一致" % id)
		check(fill.color == ui.CYAN, "成就 %s 未解锁填充色=青" % id)
		var rown: Node = r["row"]
		check(rown.tooltip_text.find("进度: 0%") >= 0, "成就 %s tooltip 含 进度: 0%% (实际 %s)" % [id, rown.tooltip_text])
	check(str(ui._ach_count_label.text) == "成就 0/%d" % g.ach_ids.size(), "顶栏成就计数 0/%d (实际 %s)" % [g.ach_ids.size(), ui._ach_count_label.text])


# 打磨-42→43: 初始态 (全新档, 成就页): 5 条收集进度条 (4 类 + 总计), 节点齐全/0 填充/青色/计数文本/tooltip + 节流缓存 (同态再刷不重写)
func _assert_collect_bars_initial() -> void:
	var g := GameData
	check(ui._collect_items.size() == 5, "收集进度 5 条节点齐全 (4 类+总计) (实际 %d)" % ui._collect_items.size())
	check(ui._collect_wrap != null and ui._collect_box == ui._collect_wrap, "打磨-43 收集进度一览为 FlowContainer (宽不足逐条换行不截断)")
	var expect_txt := {"skill": "技能 0/%d" % g.skill_ids.size(), "equip": "装备 0/%d" % g.equip_ids.size(),
		"item": "法器 0/10", "ach": "成就 0/%d" % g.ach_ids.size(), "total": "总计 0/287"}
	for k in expect_txt:
		var it: Dictionary = ui._collect_items.get(k, {})
		check(it.has("label") and it.has("bar_bg") and it.has("bar_fill"), "收集 %s 节点 (label/bar_bg/bar_fill) 存在" % k)
		if it.is_empty() or not it.has("bar_bg"):
			continue
		var bg: ColorRect = it["bar_bg"]
		var fill: ColorRect = it["bar_fill"]
		check(int(bg.size.x) > 0, "收集 %s 进度条背景布局宽>0 (实际 %d)" % [k, int(bg.size.x)])
		check(bg.size.y >= 5.0, "收集 %s 进度条高>=5 (实际 %.0f)" % [k, bg.size.y])
		check(int(fill.size.x) == 0, "收集 %s 初始 0 填充 (实际 %d)" % [k, int(fill.size.x)])
		check(fill.color == ui.CYAN, "收集 %s 初始填充色=青" % k)
		check(str((it["label"] as Label).text) == expect_txt[k], "收集 %s 计数文本 (实际 %s)" % [k, str(it["label"].text)])
		var lc: Color = (it["label"] as Label).get_theme_color("font_color")
		check(lc == ui.CYAN, "收集 %s 未集齐 文字色=青" % k)
	check(ui._collect_box.tooltip_text.find("全局收集进度") >= 0, "收集进度 tooltip 说明 (实际 %s)" % ui._collect_box.tooltip_text)
	check(str(ui._collect_text).find("收集进度") >= 0 and str(ui._collect_text).find("(总 0/287)") >= 0, "收集汇总文本含 总 0/287 (实际 %s)" % str(ui._collect_text))
	# 节流: 同态再刷两帧, 缓存键不变 (不重写)
	var keys_before := {}
	for k in expect_txt:
		keys_before[k] = str(ui._collect_items[k].get("q", ""))
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	await get_tree().process_frame
	var stable := true
	for k in expect_txt:
		if str(ui._collect_items[k].get("q", "")) != keys_before[k]:
			stable = false
	check(stable, "收集进度 同态再刷 缓存键不变 (节流生效)")


# 状态变化: 境界金丹+5万灵石+2技能+2装备+法器 -> 6 成就解锁 (金满条/100%) + 部分进度条按 ratio 填充 + 排序已解锁在前
func _mutate_state() -> void:
	var g := GameData
	g.realm_idx = 2
	g.stones = 50000.0
	g.learned.append("sword_0_0")
	g.learned.append("sword_0_1")
	g.owned_eq.append("weapon_0_0")
	g.owned_eq.append("robe_0_0")
	g.owned.append("wooden_sword")
	g.check_achievements()
	ui._refresh()
	# 解锁 6 个: realm_zhuji/realm_jindan/first_break/first_item/equip_first/skill 未 (12<50? 2 技能 -> skill_10 未)
	# 期望: first_break first_item realm_jindan realm_zhuji equip_first (5 个) + rich 未 (5万<10万)
	var done: Array[String] = g.ach_done.duplicate()
	check(done.has("realm_jindan") and done.has("realm_zhuji") and done.has("first_break")
		\
		and done.has("first_item") and done.has("equip_first"), "解锁 5 成就 (实际 %s)" % ",".join(done))
	check(str(ui._ach_count_label.text) == "成就 %d/%d" % [done.size(), g.ach_ids.size()], "顶栏计数 %d (实际 %s)" % [done.size(), ui._ach_count_label.text])
	# 已解锁: 金满条 + 100% tooltip
	for id in done:
		var r: Dictionary = ui._ach_rows[id]
		var bg: ColorRect = r["bar_bg"]
		var fill: ColorRect = r["bar_fill"]
		check(int(fill.size.x) == int(bg.size.x), "已解锁 %s 满条 (fill=%d bg=%d)" % [id, int(fill.size.x), int(bg.size.x)])
		check(fill.color == ui.GOLD, "已解锁 %s 金色" % id)
		var rown: Node = r["row"]
		check(rown.tooltip_text.find("进度: 100%") >= 0, "已解锁 %s tooltip 100%% (实际 %s)" % [id, rown.tooltip_text])
	# rich_100k 未解锁 50%: 青条 fill = bg*ceil(0.5*50)/50 = bg
	var rr: Dictionary = ui._ach_rows["rich_100k"]
	var rbg: ColorRect = rr["bar_bg"]
	var rfill: ColorRect = rr["bar_fill"]
	check(int(rfill.size.x) == int(rbg.size.x * 0.5), "rich_100k 50%% 填充=半条 (fill=%d bg=%d)" % [int(rfill.size.x), int(rbg.size.x)])
	check(rfill.color == ui.CYAN, "rich_100k 青色 (未解锁)")
	var rrow: Node = rr["row"]
	check(rrow.tooltip_text.find("进度: 50%") >= 0, "rich_100k tooltip 50%% (实际 %s)" % rrow.tooltip_text)
	# 排序: 已解锁 5 个在前
	var box: VBoxContainer = ui._ach_box
	var first5: Array = []
	for i in done.size():
		first5.append(box.get_child(i))
	var all_ok := true
	for node in first5:
		if not (node as PanelContainer).get_meta("_hl", false):
			all_ok = false
	check(all_ok, "排序 前 %d 行均为已解锁 (金框)" % done.size())


# 打磨-42→43: 变化态 (2技能+2装备+1法器+5成就): 5 条同步计数 (含 总计 10/287) + 1% 档填充 + 青色 (未满);
# 再学全技能/全法器 -> 满态金 (技能/法器 金 + 总计 137/287 仍青, 金/青混合二态)
func _assert_collect_bars_mutated() -> void:
	var g := GameData
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	var names := {"skill": "技能", "equip": "装备", "item": "法器", "ach": "成就", "total": "总计"}
	var expect := {"skill": [2, g.skill_ids.size()], "equip": [2, g.equip_ids.size()],
		"item": [1, 10], "ach": [5, g.ach_ids.size()], "total": [10, 287]}
	for k in expect:
		var it: Dictionary = ui._collect_items.get(k, {})
		if it.is_empty():
			continue
		var got: int = int(expect[k][0])
		var tot: int = int(expect[k][1])
		var q: int = int(ceil(clampf(float(got) / float(tot), 0.0, 1.0) * 100.0))
		var bg: ColorRect = it["bar_bg"]
		var fill: ColorRect = it["bar_fill"]
		check(str((it["label"] as Label).text) == "%s %d/%d" % [names[k], got, tot], "收集 %s 计数文本 (实际 %s)" % [k, str((it["label"] as Label).text)])
		check(int(fill.size.x) == int(bg.size.x * float(q) / 100.0), "收集 %s 填充=1%%档 %d%% (fill=%d bg=%d)" % [k, q, int(fill.size.x), int(bg.size.x)])
		check(fill.color == ui.CYAN, "收集 %s 未满填充色=青" % k)
		check((it["label"] as Label).get_theme_color("font_color") == ui.CYAN, "收集 %s 未满文字色=青" % k)
	check(str(ui._collect_text).find("(总 10/287)") >= 0, "收集汇总文本含 总 10/287 (实际 %s)" % str(ui._collect_text))
	# 满态: 学全技能 + 全法器 -> 技能/法器 满条金色, 装备/成就 仍青色 (金/青 混合二态)
	g.learned.clear()
	for sid in g.skill_ids:
		g.learned.append(sid)
	g.owned.clear()
	for itm in g.ITEMS:
		g.owned.append(str(itm["id"]))
	ui._refresh()
	for k in ["skill", "item"]:
		var it: Dictionary = ui._collect_items[k]
		var bg: ColorRect = it["bar_bg"]
		var fill: ColorRect = it["bar_fill"]
		check(int(fill.size.x) == int(bg.size.x), "收集 %s 满条 (fill=%d bg=%d)" % [k, int(fill.size.x), int(bg.size.x)])
		check(fill.color == ui.GOLD, "收集 %s 满态金色" % k)
		check((it["label"] as Label).get_theme_color("font_color") == ui.GOLD, "收集 %s 满态文字金" % k)
		check(str((it["label"] as Label).text) == "%s %d/%d" % [names[k], int(expect[k][1]), int(expect[k][1])], "收集 %s 满态计数 (实际 %s)" % [k, str((it["label"] as Label).text)])
	for k in ["equip", "ach"]:
		var it: Dictionary = ui._collect_items[k]
		check((it["bar_fill"] as ColorRect).color == ui.CYAN, "收集 %s 未满分态保持青" % k)
	check(str(ui._collect_text).find("(总 137/287)") >= 0, "满态汇总文本含 总 137/287 (实际 %s)" % str(ui._collect_text))
	# 打磨-43: 总计条 满态 137/287 — 青色 48%档 (未满保持青, 与 4 类同口径; 10/287 态已在上方 for 循环 q 公式断言)
	var t2: Dictionary = ui._collect_items["total"]
	var tb2: ColorRect = t2["bar_bg"]
	var tf2: ColorRect = t2["bar_fill"]
	var q2: int = int(ceil(clampf(137.0 / 287.0, 0.0, 1.0) * 100.0))
	check(int(tf2.size.x) == int(tb2.size.x * float(q2) / 100.0), "总计条 137/287 填充=1%%档 %d%% (fill=%d bg=%d)" % [q2, int(tf2.size.x), int(tb2.size.x)])
	check(tf2.color == ui.CYAN, "总计条 137/287 未满=青")
	await _assert_collect_total_wrap()


# 打磨-43: 顶栏宽度不足时逐条换行不截断 — 压缩 FlowContainer 宽度 -> 5 条目折到多行; 恢复宽 -> 回单行
func _assert_collect_total_wrap() -> void:
	var g := GameData
	var wrap: FlowContainer = ui._collect_wrap
	# 全收集态 (287/287) 下断言: 总计条 满条金色
	g.owned_eq.clear()
	for eid in g.equip_ids:
		g.owned_eq.append(eid)
	g.ach_done.clear()
	for aid in g.ach_ids:
		g.ach_done.append(str(aid))
	ui._refresh()
	await get_tree().process_frame
	var full_txt := "总计 287/287"
	var it_all: Dictionary = ui._collect_items["total"]
	check(str((it_all["label"] as Label).text) == full_txt, "总计条 全收集 %s (实际 %s)" % [full_txt, str((it_all["label"] as Label).text)])
	check((it_all["bar_fill"] as ColorRect).color == ui.GOLD, "总计条 全收集=金")
	# 宽态: 5 条目全部布局在位 (1280 窄屏下天然可能 2~3 行, 记录自然行数供 roundtrip 对比; 1920 宽屏实测单行)
	var rows_nat := _count_rows(wrap)
	check(wrap.get_child_count() == 5, "宽态 5 条目全在 (实际 %d, 自然 %d 行)" % [wrap.get_child_count(), rows_nat])
	# 窄态: 强制 FlowContainer 最小宽 200px -> 条目必须换行 (y 出现 2 档) 且不消失 (5 条目全在)
	var old_min: Vector2 = wrap.custom_minimum_size
	wrap.custom_minimum_size = Vector2(200, 0)
	ui._refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	check(wrap.get_child_count() == 5, "窄态 5 条目仍在 (未截断) (实际 %d)" % wrap.get_child_count())
	var rows_narrow := _count_rows(wrap)
	check(rows_narrow >= 2, "窄态 逐条换行到多行 (实际 %d 行)" % rows_narrow)
	# 恢复宽度 -> roundtrip 行数与压缩前一致
	wrap.custom_minimum_size = old_min
	ui._refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	var rows_rest := _count_rows(wrap)
	check(rows_rest == rows_nat, "恢复宽后 roundtrip 行数一致 (压缩前 %d, 恢复后 %d)" % [rows_nat, rows_rest])
	# 恢复受控态 (防污染后续断言)
	g.owned_eq.clear()
	g.ach_done.clear()


# 打磨-43: 统计容器子节点折成的行数 (y 坐标 2px 容差归并)
func _count_rows(c: Container) -> int:
	var rows := 0
	var y0: float = -1.0
	for i in c.get_child_count():
		var y: float = c.get_child(i).position.y
		if y0 < 0.0 or absf(y - y0) > 2.0:
			rows += 1
			y0 = y
	return rows


# 打磨-41: 技能/装备/法器 行首品质色竖条 (120+140+10 行, 颜色与 数据tier/价格档 一致)
func _assert_tier_bars() -> void:
	var g := GameData
	# 技能页 (tab 1): 色条 = TIER_COLOR[s.tier]
	ui._tab.current_tab = 1
	ui._refresh()
	await get_tree().process_frame
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		var rown: Node = ui._skill_row_nodes[id]
		var hb: HBoxContainer = rown.get_child(0)
		check(hb.get_child_count() > 0 and hb.get_child(0) is ColorRect, "技能 %s 色条为首子节点" % id)
		if hb.get_child_count() == 0 or not (hb.get_child(0) is ColorRect):
			continue
		var bar: ColorRect = hb.get_child(0)
		check(bar.color == g.TIER_COLOR[int(s["tier"])], "技能 %s 色条色=%s tier=%s" % [id, str(bar.color), str(s["tier"])])
		check(bar.size.y >= 16.0, "技能 %s 色条高>16 (实际 %.0f)" % [id, bar.size.y])
	# 装备页 (tab 2): 色条 = TIER_COLOR[e.tier]
	ui._tab.current_tab = 2
	ui._refresh()
	await get_tree().process_frame
	for id in g.equip_ids:
		var e: Dictionary = g.equip_by_id[id]
		var rown: Node = ui._equip_row_nodes[id]
		var hb: HBoxContainer = rown.get_child(0)
		check(hb.get_child_count() > 0 and hb.get_child(0) is ColorRect, "装备 %s 色条为首子节点" % id)
		if hb.get_child_count() == 0 or not (hb.get_child(0) is ColorRect):
			continue
		var bar: ColorRect = hb.get_child(0)
		check(bar.color == g.TIER_COLOR[int(e["tier"])], "装备 %s 色条色=%s tier=%s" % [id, str(bar.color), str(e["tier"])])
	# 修行页 (tab 0): 法器色条 = 价格档 (1k/100k/1M -> 凡灰/玄蓝/仙紫/神金)
	ui._tab.current_tab = 0
	ui._refresh()
	await get_tree().process_frame
	var tier_seen := {0: 0, 2: 0, 5: 0, 6: 0}
	for it in g.ITEMS:
		var iid: String = str(it["id"])
		var row: Node = ui._shop_row_nodes[iid]
		check(row.get_child_count() > 0 and row.get_child(0) is ColorRect, "法器 %s 色条为首子节点" % iid)
		if row.get_child_count() == 0 or not (row.get_child(0) is ColorRect):
			continue
		var bar: ColorRect = row.get_child(0)
		var cost: float = float(it["cost"])
		var expect_idx := 0 if cost < 1000.0 else (2 if cost < 100000.0 else (5 if cost < 1000000.0 else 6))
		check(bar.color == g.TIER_COLOR[expect_idx], "法器 %s 价格档色=%s 期望档%d" % [iid, str(bar.color), expect_idx])
		tier_seen[expect_idx] = tier_seen[expect_idx] + 1
	check(tier_seen[0] > 0 and tier_seen[2] > 0 and tier_seen[5] > 0 and tier_seen[6] > 0, "法器四档价格色标均有覆盖 (实际 %s)" % str(tier_seen))


func _finish() -> void:
	print("")
	if _fail.is_empty():
		print("UI_TEST PASS  %d 项全部通过" % _pass)
		get_tree().quit(0)
	else:
		printerr("UI_TEST FAIL  %d 通过 / %d 失败:" % [_pass, _fail.size()])
		for x in _fail:
			printerr("  - " + x)
		var rf := FileAccess.open("user://ui_test_result.txt", FileAccess.WRITE)
		if rf != null:
			rf.store_string("\n".join(_fail))
			rf.close()
		get_tree().quit(1)
