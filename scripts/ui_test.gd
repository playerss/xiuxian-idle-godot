extends Node
## 打磨-40: 成就页进度条 UI 断言 (headless 可跑, scene 模式带 autoload GameData/Steam)
## 打磨-41: 技能/装备/法器 行首品质色竖条断言 (存在/首子节点/颜色与数据 tier 或价格档一致)
## 打磨-42: 成就页顶栏收集进度一览 mini 进度条断言 (4 条节点/0 填充/满态金/半态比例/节流缓存)
## 打磨-43: 收集进度一览加 总计 mini 进度条断言 (5 条节点/总计=10/287 与 137/287 两态/wrap 换行布局)
## 打磨-44: 收集进度一览 点击直达断言 (5 条 flat Button+手型光标/tooltip/点击切 Tab 重置筛选/
##          法器区金边高亮+自动恢复/无存档统计副作用/总计不切页)
## 打磨-45: 一键系列统一浮动反馈断言 (变更>0 屏幕中央绿色浮动含数量/0 变更不弹/幂等再点不弹/
##          文案/计数/颜色/无 essence 副作用, 5 按钮逐一+重复点击)
## 打磨-46: 一键系列按钮 tooltip 统一口径断言 (5 按钮 3 行结构: 动作顺序/筛选叠加/计数口径 +
##          各按钮关键口径词: 境界条件/爆发口径/自动穿戴/最佳判定链/幂等/全局口径)
## 打磨-55: 单个神通 施展 浮动反馈断言 (成功弹绿色浮动 文案含神通名/未领悟与冷却中 不弹/
##          点被动行 不弹/底部消息 与 浮动 并存/skill_use 统计口径不变)
## 打磨-57: 主动神通 冷却完毕转就绪 浮动断言 (冷却 归零 弹绿色浮动 文案含神通名/同一批多个
##          就绪 合并一行/按钮同步恢复 施展/tick/drain 无 资源/统计 副作用/无重复触发)
## 打磨-47: 一键购买 (装备/法器) 结果反馈断言 (变更>0 底部消息追加 共花灵石+距下一件缺口/
##          全拥有 0 变更 不追加/tooltip 说明 结果反馈 口径)
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
	await _assert_collect_jump()
	await _assert_onekey_float()
	_assert_onekey_tooltips()
	_assert_buy_feedback()
	_assert_stone_tip()
	await _assert_stone_next_inline()
	await _assert_burst_preview()
	await _assert_skill_cast_float()
	await _assert_active_learn()
	await _assert_ready_float()
	await _assert_cd_bars()
	await _assert_ready_flash()
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


# 打磨-44: 收集进度一览 点击直达 — 5 条 flat Button (手型光标/tooltip), 点击切 Tab+重置筛选,
# 法器区金边高亮+自动恢复, 无存档/统计副作用, 总计不切页
func _assert_collect_jump() -> void:
	var g := GameData
	# 回到成就页 (点击入口所在页)
	ui._tab.current_tab = 3
	# 5 条按钮节点 + flat + 手型光标
	check(ui._collect_btns.size() == 5, "收集进度 5 条点击按钮齐全 (实际 %d)" % ui._collect_btns.size())
	var expect_tip := {"skill": "点击直达 技能页", "equip": "点击直达 装备页",
		"item": "点击直达 修行页·法器区", "ach": "已在 成就页", "total": "总计 = 四类已收集之和"}
	for k in expect_tip:
		var b: Button = ui._collect_btns.get(k, null)
		check(b != null, "收集 %s 按钮存在" % k)
		if b == null:
			continue
		check(b.flat == true, "收集 %s 按钮 flat (可点样式)" % k)
		check(b.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "收集 %s 手型光标提示可点" % k)
		check(b.toggle_mode == false, "收集 %s 按钮非 toggle (点击即触发)" % k)
		check(b.tooltip_text.find(expect_tip[k]) >= 0, "收集 %s tooltip 含「%s」 (实际 %s)" % [k, expect_tip[k], b.tooltip_text])
		# 行 (HBox) 是按钮子节点 (结构: wrap > btn > row[label+bar])
		var it: Dictionary = ui._collect_items[k]
		var row: Node = it["row"]
		check(row.get_parent() == b, "收集 %s 行挂在按钮下 (点击热区=整行)" % k)
	# 法器区高亮 Panel 存在 (修行页)
	check(ui._items_panel != null and ui._items_panel is Panel, "修行页法器区高亮 Panel 存在")
	# --- 点击 技能: 切到技能页(tab1) + 筛选重置(全部类别/全部品质) ---
	# 先给技能页制造一个筛选态, 验证点击后重置
	ui._on_filter("sword")
	ui._on_tier_filter("2")
	check(ui._filter_active == "sword" and ui._tier_active == "2", "前置 技能筛选态 (sword/tier2)")
	# 副作用快照 (点击 不应改变)
	var snap_essence := g.essence
	var snap_stones := g.stones
	var snap_stats := g.stats
	ui._on_collect_jump("skill")
	await get_tree().process_frame
	check(ui._tab.current_tab == 1, "点击 技能 → 切到 技能页 (tab=1) (实际 %d)" % ui._tab.current_tab)
	check(ui._filter_active == "", "点击 技能 → 类别筛选重置为 全部 (实际 %s)" % ui._filter_active)
	check(ui._tier_active == "", "点击 技能 → 品质筛选重置为 全部 (实际 %s)" % ui._tier_active)
	check(g.essence == snap_essence and g.stones == snap_stones, "点击 技能 无资源副作用")
	check(g.stats == snap_stats, "点击 技能 无统计副作用 (无 _stat_inc)")
	# --- 点击 装备: 切到装备页(tab2) + 部位/品质 筛选重置 ---
	ui._on_equip_filter("weapon")
	ui._on_equip_tier_filter("3")
	check(ui._equip_filter_active == "weapon" and ui._equip_tier_active == "3", "前置 装备筛选态 (weapon/tier3)")
	ui._on_collect_jump("equip")
	await get_tree().process_frame
	check(ui._tab.current_tab == 2, "点击 装备 → 切到 装备页 (tab=2) (实际 %d)" % ui._tab.current_tab)
	check(ui._equip_filter_active == "", "点击 装备 → 部位筛选重置为 全部 (实际 %s)" % ui._equip_filter_active)
	check(ui._equip_tier_active == "", "点击 装备 → 品质筛选重置为 全部 (实际 %s)" % ui._equip_tier_active)
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats, "点击 装备 无资源/统计副作用")
	# --- 点击 法器: 切到修行页(tab0) + 法器区金边高亮, 之后自动恢复 ---
	ui._on_collect_jump("item")
	await get_tree().process_frame
	check(ui._tab.current_tab == 0, "点击 法器 → 切到 修行页 (tab=0) (实际 %d)" % ui._tab.current_tab)
	var sb_hi: StyleBoxFlat = ui._items_panel.get_theme_stylebox("panel")
	check(sb_hi != null and sb_hi.border_width_left > 0, "点击 法器 → 法器区金边高亮 (边框宽>0)")
	check(sb_hi != null and sb_hi.border_color == ui.GOLD, "点击 法器 → 高亮边框=金")
	# 等待 tween 结束(1.2s) 后恢复
	await get_tree().create_timer(1.4).timeout
	var sb_rest: StyleBoxFlat = ui._items_panel.get_theme_stylebox("panel")
	check(sb_rest != null and sb_rest.border_width_left == 0, "法器区高亮 1.2s 后自动恢复 (边框宽=0)")
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats, "点击 法器 无资源/统计副作用")
	# --- 点击 成就: 已在成就页, 不切页 (保持 tab=3) ---
	ui._tab.current_tab = 3
	ui._on_collect_jump("ach")
	await get_tree().process_frame
	check(ui._tab.current_tab == 3, "点击 成就 → 保持 成就页 (tab=3) (实际 %d)" % ui._tab.current_tab)
	# --- 点击 总计: 只弹口径提示, 不切页 (保持 tab=3) ---
	ui._tab.current_tab = 3
	var tab_before_total: int = ui._tab.current_tab
	ui._on_collect_jump("total")
	await get_tree().process_frame
	check(ui._tab.current_tab == tab_before_total, "点击 总计 → 不切页 (保持 tab=%d)" % tab_before_total)
	check(str(ui._msg_label.text).find("总计") >= 0, "点击 总计 → 底部弹口径提示 (实际 %s)" % ui._msg_label.text)
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats, "点击 总计 无资源/统计副作用")
	# 恢复受控态 (防污染: 筛选已重置为全部, 无需额外清理)


# 打磨-45: 一键系列统一浮动反馈 — 变更>0 时屏幕中央绿色浮动提示 (文案含数量), 0 变更不弹
# 受控态 (realm_idx=2 layer=1, 灵石 5万, 空技能/装备/法器): 期望值全部按 GameData 只读接口
# 动态计算 (learn_available_count/active_ready_count/item_affordable_count/equip_best_pending),
# 5 按钮逐一点击断言 计数+1/文案含数量/绿色/位置复位; 5 按钮再点一次 (全学/全买/全穿/冷却中)
# 计数不变 (0 变更只走底部消息); 施展爆发真实加灵气, 购买/穿戴不动灵气
func _assert_onekey_float() -> void:
	var g := GameData
	# 受控态 (打磨-44 末态: 筛选已重置为全部, 资源 5万, 空 技能/装备/法器)
	check(ui._filter_active == "" and ui._tier_active == "" and ui._equip_filter_active == "" and ui._equip_tier_active == "", "前置 筛选态已重置")
	g.realm_idx = 2
	g.layer = 1
	g.stones = 50000.0
	g.learned.clear()
	g.owned_eq.clear()
	g.owned.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	ui._refresh()
	# 节点: 浮动 Label 存在 + 绿色 (与 成就浮动 同绿口径)
	var fl: Label = ui._onekey_float_label
	check(fl != null, "一键浮动 Label 节点存在")
	if fl == null:
		return
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "一键浮动 文字色=绿")
	check(str(ui._onekey_last_text) == "", "初始 无浮动文案 (实际 %s)" % str(ui._onekey_last_text))
	check(ui._onekey_float_count == 0, "初始 浮动计数=0 (实际 %d)" % ui._onekey_float_count)
	var c0: int = ui._onekey_float_count
	var snap_ess := g.essence
	# --- 一键领悟 (技能页): 期望数 = learn_available_count (境界足够+未学) ---
	var n_learn: int = g.learn_available_count()
	check(n_learn > 0, "受控态 存在可学技能 (实际 %d)" % n_learn)
	ui._tab.current_tab = 1
	ui._refresh()
	# 打磨-53: 学习前 qi 快照, 学习后 delta>0 追加 灵气速率 增量 (与 打磨-51/52 法器/装备 同口径)
	var qi_pre_l53: float = g.qi_per_sec()
	ui._on_learn_all()
	var qi_delta_l53: float = g.qi_per_sec() - qi_pre_l53
	var extra_l53 := (" (灵气速率 +%s/秒)" % g.fmt(qi_delta_l53)) if qi_delta_l53 > 0.0 else ""
	onekey_assert("一键领悟 %d 个技能%s" % [n_learn, extra_l53], c0)
	c0 = ui._onekey_float_count
	check(qi_delta_l53 > 0.0, "一键领悟后 灵气速率上升 (delta %s/秒)" % g.fmt(qi_delta_l53))
	check(g.learned.size() == n_learn, "一键领悟 学到 %d (实际 %d)" % [n_learn, g.learned.size()])
	check(g.essence == snap_ess, "一键领悟 无灵气副作用 (实际 %.0f)" % g.essence)
	# --- 一键施展: 期望数 = active_ready_count (冷却清空, 刚学的主动神通全部就绪; 爆发真实加灵气) ---
	var n_act: int = g.active_ready_count()
	check(n_act > 0, "受控态 存在就绪主动神通 (实际 %d)" % n_act)
	ui._refresh()
	var snap_ess_act := g.essence
	ui._on_active_all()
	# 打磨-60: 浮动文案追加 本批 爆发 获得 总量 (爆发=前后 主资源 差, 与 底部消息 同口径;
	# GameData 无新接口, use_all_active 已返回 burst)
	var burst_act: float = g.essence - snap_ess_act
	check(burst_act > 0.0, "打磨-60 一键施展 爆发总量>0 (实际 %s)" % g.fmt(burst_act))
	onekey_assert("一键施展 %d 个神通 (爆发+%s 灵气)" % [n_act, g.fmt(burst_act)], c0)
	c0 = ui._onekey_float_count
	check(g.active_ready_count() == 0, "施展后 全部进冷却 (就绪 0, 实际 %d)" % g.active_ready_count())
	check(g.essence > snap_ess_act, "施展 爆发真实加灵气 (爆发前 %.0f → 后 %.0f)" % [snap_ess_act, g.essence])
	# --- 法器 一键购买 (修行页): 期望数 = 价格升序连买 (预算耗尽即停, 与 buy_items_affordable 同口径; 花灵石, 不动灵气) ---
	var n_item := 0
	var sim_stones_it := g.stones
	var item_costs: Array = []
	for it in g.ITEMS:
		item_costs.append(float((it as Dictionary).get("cost", 1e18)))
	item_costs.sort()
	for c in item_costs:
		var cost: float = float(c)
		if cost <= sim_stones_it:
			sim_stones_it -= cost
			n_item += 1
	check(n_item > 0, "受控态 存在可购法器 (实际 %d)" % n_item)
	var snap_ess2 := g.essence
	var qi_pre51: float = g.qi_per_sec()   # 打磨-51: 浮动文案含 灵气速率 +delta (购买前快照)
	ui._tab.current_tab = 0
	ui._refresh()
	ui._on_items_buy_all()
	var qi_delta51: float = g.qi_per_sec() - qi_pre51
	onekey_assert("一键购置 %d 件法器 (灵气速率 +%s/秒)" % [n_item, g.fmt(qi_delta51)], c0)
	c0 = ui._onekey_float_count
	check(qi_delta51 > 0.0, "法器购买后 灵气速率上升 (delta %s)" % g.fmt(qi_delta51))
	check(g.owned.size() == n_item, "法器 买到 %d (实际 %d)" % [n_item, g.owned.size()])
	check(g.essence == snap_ess2, "一键购置 无灵气副作用 (实际 %.0f)" % g.essence)
	# --- 装备 一键购买 (装备页): 期望数按 与 buy_affordable 完全一致的顺序 (价格升序, 同价 id 升序) 连买模拟 ---
	var n_equip := 0
	var sim_stones := g.stones
	var ids: Array = g.equip_ids.duplicate()
	ids.sort_custom(g.buy_affordable_cmp)
	for id in ids:
		var e: Dictionary = g.equip_by_id[str(id)]
		var cost: float = float(e.get("cost", 1e18))
		if cost <= sim_stones:
			sim_stones -= cost
			n_equip += 1
	check(n_equip > 0, "受控态 存在可购装备 (实际 %d)" % n_equip)
	ui._tab.current_tab = 2
	ui._refresh()
	# 打磨-52: 浮动文案含 灵气速率 增量 (购买前 qi 快照, 与 打磨-51 法器 口径一致)
	var qi_pre52: float = g.qi_per_sec()
	ui._on_buy_all()
	var qi_delta52: float = g.qi_per_sec() - qi_pre52
	check(qi_delta52 > 0.0, "装备一键购买后 灵气速率上升 (delta %s)" % g.fmt(qi_delta52))
	onekey_assert("一键购买 %d 件装备 (灵气速率 +%s/秒)" % [n_equip, g.fmt(qi_delta52)], c0)
	c0 = ui._onekey_float_count
	check(g.owned_eq.size() == n_equip, "装备 买到 %d (实际 %d)" % [n_equip, g.owned_eq.size()])
	check(g.equipped.size() == 5, "槽位空时已自动穿戴 (5 部位, 实际 %d)" % g.equipped.size())
	check(g.essence == snap_ess2, "一键购买 无灵气副作用 (实际 %.0f)" % g.essence)
	# --- 一键最佳: 期望数 = equip_best_pending (各槽位换最佳) ---
	var n_best: int = g.equip_best_pending()
	check(n_best > 0, "受控态 存在待改进槽位 (实际 %d)" % n_best)
	ui._refresh()
	# 打磨-52: 换装前 qi 快照, 换装后 delta>0 追加 灵气速率 增量
	var qi_pre53: float = g.qi_per_sec()
	ui._on_equip_best()
	var qi_delta53: float = g.qi_per_sec() - qi_pre53
	check(qi_delta53 > 0.0, "一键最佳换装后 灵气速率再升 (delta %s)" % g.fmt(qi_delta53))
	onekey_assert("最佳穿戴 %d 件 (灵气速率 +%s/秒)" % [n_best, g.fmt(qi_delta53)], c0)
	c0 = ui._onekey_float_count
	check(g.equip_best_pending() == 0, "一键最佳后 无待改进槽位 (实际 %d)" % g.equip_best_pending())
	check(g.essence == snap_ess2, "一键最佳 无灵气副作用 (实际 %.0f)" % g.essence)
	# --- 再点 5 按钮 (全学/全买/全穿/冷却中): 0 变更不弹 ---
	ui._on_learn_all()
	ui._on_active_all()
	ui._on_items_buy_all()
	ui._on_buy_all()
	ui._on_equip_best()
	check(ui._onekey_float_count == c0, "5 按钮 0 变更再点 不弹浮动 (计数 %d 不变)" % c0)
	check(str(ui._msg_label.text).find("装备") >= 0 or str(ui._msg_label.text).find("穿戴") >= 0, "0 变更仍走底部消息 (实际 %s)" % str(ui._msg_label.text))
	check(g.essence == snap_ess2, "全流程 (施展后) 无额外灵气副作用 (实际 %.0f)" % g.essence)


# 打磨-45: 单按钮 浮动 断言 (计数+1 / 文案=完整句子 / 绿色 / 位置复位 / 可见)
func onekey_assert(expect_text: String, c_before: int) -> void:
	var fl: Label = ui._onekey_float_label
	check(ui._onekey_float_count == c_before + 1, "一键 浮动计数+1 (期望 %d, 实际 %d)" % [c_before + 1, ui._onekey_float_count])
	check(str(ui._onekey_last_text) == expect_text, "一键 浮动文案=%s (实际 %s)" % [expect_text, str(ui._onekey_last_text)])
	check(str(fl.text) == "✦ " + expect_text + " ✦", "一键 浮动 Label 文本 ✦…✦ (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "一键 浮动文字=绿")
	check(absf(fl.position.y + 26.0) < 0.5, "一键 浮动位置复位 y≈-26 (实际 %.2f)" % fl.position.y)
	check(fl.modulate.a > 0.9, "一键 浮动可见 (alpha=%.2f)" % fl.modulate.a)


# 打磨-46: 一键系列按钮 tooltip 统一口径 — 6 按钮 (一键领悟/一键神通/一键施展/法器一键购买/装备一键购买/
# 一键最佳) tooltip 统一 3 行: 动作与顺序 / 筛选叠加与作用范围 / 按钮计数口径
# tooltip 为构建时静态文本 (不随状态刷新), 此处断言 3 行结构 + 各按钮关键口径词
func _assert_onekey_tooltips() -> void:
	var btns: Dictionary = {
		"learn": ui._learn_all_btn,
		"actlearn": ui._active_learn_btn,
		"active": ui._active_all_btn,
		"item": ui._items_buy_btn,
		"buy": ui._buy_all_btn,
		"best": ui._equip_best_btn,
	}
	for key in btns:
		var b: Button = btns[key]
		var tip: String = str(b.tooltip_text)
		var lines: PackedStringArray = tip.split("\n")
		check(tip.length() > 20, "一键系列 tooltip 非空 (%s)" % key)
		check(lines.size() == 3, "一键系列 tooltip 三行结构 (%s, 实际 %d)" % [key, lines.size()])
		check(lines.size() >= 3 and lines[2].begins_with("按钮计数 ="), "一键系列 tooltip 第3行=计数口径 (%s)" % key)
	# 一键领悟: 境界条件 + 筛选 AND 叠加 + 不耗资源
	var t_learn: String = str(ui._learn_all_btn.tooltip_text)
	check(t_learn.contains("境界/层数足够"), "一键领悟 tooltip 含 境界/层数足够 条件")
	check(t_learn.contains("AND 叠加"), "一键领悟 tooltip 含 类别/品质 筛选 AND 叠加口径")
	check(t_learn.contains("不消耗资源"), "一键领悟 tooltip 含 不消耗资源")
	# 一键施展: 就绪口径 + 爆发口径 + 飞升后道行
	var t_active: String = str(ui._active_all_btn.tooltip_text)
	check(t_active.contains("冷却完毕"), "一键施展 tooltip 含 冷却完毕 口径")
	check(t_active.contains("当前灵气速率 x 爆发秒数"), "一键施展 tooltip 含 爆发=速率x秒数 口径")
	check(t_active.contains("飞升后改为获得道行"), "一键施展 tooltip 含 飞升后道行 说明")
	# 打磨-60: 一键施展 tooltip 含 爆发总量 口径 (浮动追加 爆发+N 灵气/道行, 与底部消息同口径)
	check(t_active.contains("爆发+N 灵气/道行"), "一键施展 tooltip 含 爆发总量口径 (打磨-60)")
	# 装备一键购买: 购买顺序 + 自动穿戴规则
	var t_buy: String = str(ui._buy_all_btn.tooltip_text)
	check(t_buy.contains("同价按数据序"), "装备一键购买 tooltip 含 同价按数据序 顺序")
	check(t_buy.contains("槽位为空时自动穿戴"), "装备一键购买 tooltip 含 槽位空自动穿戴 规则")
	# 打磨-48: 一键购买 tooltip 含 缺口 ETA 联动 口径
	check(t_buy.contains("约 X 可购"), "装备一键购买 tooltip 含 缺口ETA 口径")
	check(str(ui._items_buy_btn.tooltip_text).contains("约 X 可购"), "法器一键购买 tooltip 含 缺口ETA 口径")
	# 一键最佳: 最佳判定链 + 幂等
	var t_best: String = str(ui._equip_best_btn.tooltip_text)
	check(t_best.contains("灵气% + 灵石%"), "一键最佳 tooltip 含 主属性 判定")
	check(t_best.contains("突破率 > 离线效率"), "一键最佳 tooltip 含 次属性 判定顺序")
	check(t_best.contains("幂等"), "一键最佳 tooltip 含 幂等 说明")
	# 法器一键购买: 全局口径 + 顺序
	var t_item: String = str(ui._items_buy_btn.tooltip_text)
	check(t_item.contains("不受筛选影响"), "法器一键购买 tooltip 含 全局口径 说明")
	check(t_item.contains("同价按数据序"), "法器一键购买 tooltip 含 同价按数据序 顺序")
	# 打磨-52: 装备一键购买/一键最佳 tooltip 含 灵气速率 增量 口径 (0 变化省略)
	check(t_buy.contains("灵气速率 +N/秒"), "装备一键购买 tooltip 含 灵气速率增量 口径 (打磨-52)")
	check(t_best.contains("灵气速率 +N/秒"), "一键最佳 tooltip 含 灵气速率增量 口径 (打磨-52)")
	check(t_best.contains("0 变化省略"), "一键最佳 tooltip 含 0变化省略 口径 (打磨-52)")
	# 打磨-53: 一键领悟 tooltip 含 灵气速率 增量 口径 (0 变化省略, 与法器/装备同口径)
	check(t_learn.contains("灵气速率 +N/秒"), "一键领悟 tooltip 含 灵气速率增量 口径 (打磨-53)")
	check(t_learn.contains("0 变化省略"), "一键领悟 tooltip 含 0变化省略 口径 (打磨-53)")


# 打磨-47: 一键购买 (装备/法器) 结果反馈 — 变更>0 底部消息追加 共花灵石 + 距下一件缺口;
# 全拥有 0 变更时 不追加 (走 买不起 消息); tooltip 第 1 行 说明 结果反馈 口径 (三行结构不变)
func _assert_buy_feedback() -> void:
	var g := GameData
	# tooltip 口径说明 (构建时静态文本)
	check(str(ui._buy_all_btn.tooltip_text).contains("共花灵石"), "装备一键购买 tooltip 含 共花灵石 反馈口径")
	check(str(ui._buy_all_btn.tooltip_text).contains("距下一件"), "装备一键购买 tooltip 含 距下一件 缺口口径")
	check(str(ui._items_buy_btn.tooltip_text).contains("共花灵石"), "法器一键购买 tooltip 含 共花灵石 反馈口径")
	check(str(ui._items_buy_btn.tooltip_text).contains("距下一件"), "法器一键购买 tooltip 含 距下一件 缺口口径")
	# --- 受控态: 灵石 5万, 空 技能/装备/法器 (与 打磨-45 断言末态同口径) ---
	g.realm_idx = 2
	g.layer = 1
	g.stones = 50000.0
	g.learned.clear()
	g.owned_eq.clear()
	g.owned.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	ui._refresh()
	# 法器: 期望花费 = 价格升序连买模拟 (与 buy_items_affordable 同口径), 下一件 = item_next_target
	var sim_it := g.stones
	var n_it := 0
	var item_costs: Array = []
	for it in g.ITEMS:
		item_costs.append(float((it as Dictionary).get("cost", 1e18)))
	item_costs.sort()
	for c in item_costs:
		var cost: float = float(c)
		if cost <= sim_it:
			sim_it -= cost
			n_it += 1
	check(n_it > 0, "受控态 法器 存在可购 (实际 %d)" % n_it)
	ui._tab.current_tab = 0
	ui._refresh()
	var stones_before_it := g.stones
	ui._on_items_buy_all()
	# 缺口目标在 购买后 取 (最便宜未拥有 = 连买后下一件)
	var it_target: Dictionary = g.item_next_target()
	check(not it_target.is_empty(), "受控态 法器 存在下一件 (连买买不起)")
	var msg_it: String = str(ui._msg_label.text)
	check(msg_it.find("共花") >= 0, "法器 一键购买 底部消息含 共花灵石 (实际 %s)" % msg_it)
	check(msg_it.find(GameData.fmt(stones_before_it - g.stones)) >= 0, "法器 共花额=购买前后灵石差 (期望 %s, 实际 %s)" % [GameData.fmt(stones_before_it - g.stones), msg_it])
	check(msg_it.find("距下一件「%s」" % str(it_target["name"])) >= 0, "法器 缺口行 指向最便宜未拥有 (期望 %s, 实际 %s)" % [str(it_target["name"]), msg_it])
	check(msg_it.find(GameData.fmt(float(it_target["shortfall"]))) >= 0, "法器 缺口额 正确 (期望 %s, 实际 %s)" % [GameData.fmt(float(it_target["shortfall"])), msg_it])
	# 打磨-48: 缺口行 追加 ETA (受控态灵石速率>0; 口径=打磨-12 eta_text(cost), 与 next_target_eta_text 同式)
	var it_eta: String = g.next_target_eta_text(it_target)
	check(it_eta != "", "受控态 法器 缺口行 ETA 非空 (灵石速率 %s/s)" % g.stone_per_sec())
	check(msg_it.find("灵石" + it_eta) >= 0, "法器 缺口行 追加 ETA (期望片段 %s, 实际 %s)" % ["灵石" + it_eta, msg_it])
	# 打磨-51: 浮动文案追加 灵气速率 +delta (购买前 qi 快照在 _on_items_buy_all 之前取, 此处按连买口径复算)
	var qi_pre_fb: float = g.qi_per_sec() / g.item_boost()  # 逆连乘还原 购买前 qi (本件连乘全部刚购, 无其它拥有)
	var qi_delta_fb: float = g.qi_per_sec() - qi_pre_fb
	check(qi_delta_fb > 0.0, "打磨-51 法器连购后 灵气速率上升 (delta %s)" % g.fmt(qi_delta_fb))
	check(str(ui._onekey_last_text) == "一键购置 %d 件法器 (灵气速率 +%s/秒)" % [n_it, g.fmt(qi_delta_fb)], "法器 浮动文案 含 灵气速率增量 (打磨-51, 实际 %s)" % str(ui._onekey_last_text))
	# 装备: 同口径 (起始灵石 = 法器买完后的剩余, 非 5万)
	var sim_eq := g.stones
	var n_eq := 0
	var eq_ids: Array = g.equip_ids.duplicate()
	eq_ids.sort_custom(g.buy_affordable_cmp)
	for id in eq_ids:
		var e: Dictionary = g.equip_by_id[str(id)]
		var cost: float = float(e.get("cost", 1e18))
		if cost <= sim_eq:
			sim_eq -= cost
			n_eq += 1
	check(n_eq > 0, "受控态 装备 存在可购 (实际 %d)" % n_eq)
	ui._tab.current_tab = 2
	ui._refresh()
	var stones_before_eq := g.stones
	ui._on_buy_all()
	var eq_target: Dictionary = g.equip_next_target()
	check(not eq_target.is_empty(), "受控态 装备 存在下一件 (连买买不起)")
	var msg_eq: String = str(ui._msg_label.text)
	check(msg_eq.find("共花") >= 0, "装备 一键购买 底部消息含 共花灵石 (实际 %s)" % msg_eq)
	check(msg_eq.find(GameData.fmt(stones_before_eq - g.stones)) >= 0, "装备 共花额=购买前后灵石差 (期望 %s, 实际 %s)" % [GameData.fmt(stones_before_eq - g.stones), msg_eq])
	check(msg_eq.find("距下一件「%s」" % str(eq_target["name"])) >= 0, "装备 缺口行 指向最便宜未拥有 (期望 %s, 实际 %s)" % [str(eq_target["name"]), msg_eq])
	check(msg_eq.find(GameData.fmt(float(eq_target["shortfall"]))) >= 0, "装备 缺口额 正确 (期望 %s, 实际 %s)" % [GameData.fmt(float(eq_target["shortfall"])), msg_eq])
	# 打磨-48: 装备 缺口行 追加 ETA (同 法器 口径)
	var eq_eta: String = g.next_target_eta_text(eq_target)
	check(eq_eta != "", "受控态 装备 缺口行 ETA 非空")
	check(msg_eq.find("灵石" + eq_eta) >= 0, "装备 缺口行 追加 ETA (期望片段 %s, 实际 %s)" % ["灵石" + eq_eta, msg_eq])
	# 打磨-48: 小额缺口 边界 (缺口=1, 灵石速率>0 -> 不足1分档; 验证 eta 对小额缺口不空)
	g.stones = float(eq_target["cost"]) - 1.0
	var eq_eta1: String = g.next_target_eta_text(eq_target)
	check(eq_eta1 == " 不足1分可购", "缺口=1 灵石速率>0 出 ETA 不足1分档 (实际 %s)" % eq_eta1)
	# 注: 无灵石收入 (eta=-1 -> 省略) 分支由 selftest next_target_eta 只读接口覆盖 (stone 速率为乘性项, 正常态恒 >0)
	# --- 全拥有: 0 变更走 买不起 消息, 不追加 共花/缺口 ---
	for id in g.equip_ids:
		g.owned_eq.append(str(id))
	for it in g.ITEMS:
		g.owned.append(str((it as Dictionary)["id"]))
	g.stones = 0.0
	ui._tab.current_tab = 0
	ui._refresh()
	ui._on_items_buy_all()
	var msg_it2: String = str(ui._msg_label.text)
	check(msg_it2.find("买不起") >= 0, "法器 全拥有 走 买不起 消息 (实际 %s)" % msg_it2)
	check(msg_it2.find("共花") < 0, "法器 全拥有 不追加 共花 (实际 %s)" % msg_it2)
	check(msg_it2.find("距下一件") < 0, "法器 全拥有 不追加 缺口 (实际 %s)" % msg_it2)
	ui._on_buy_all()
	var msg_eq2: String = str(ui._msg_label.text)
	check(msg_eq2.find("买不起") >= 0, "装备 全拥有 走 买不起 消息 (实际 %s)" % msg_eq2)
	check(msg_eq2.find("共花") < 0, "装备 全拥有 不追加 共花 (实际 %s)" % msg_eq2)
	check(msg_eq2.find("距下一件") < 0, "装备 全拥有 不追加 缺口 (实际 %s)" % msg_eq2)
	# 恢复基准态
	g.stones = 0.0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()


# 打磨-49: 顶栏灵石行 tooltip = 当前灵石速率 + 距下一件 (最便宜未拥有) 缺口与 ETA
# 在 _assert_buy_feedback 的基准态 (全空, 境界0, 灵石0, 灵石速率 1.0/s) 上断言 UI 侧:
# 顶栏 _stones_label.tooltip_text 随 _refresh 动态刷新, 口径与 GameData.stone_next_target_tip 一致。
func _assert_stone_tip() -> void:
	var g := GameData
	# 基准态 (打磨-47/48 恢复): 全空, 境界0, 灵石0 -> 灵石速率 1.0/s, 最便宜未拥有 = 全局最便宜 (装备)
	check(absf(g.stone_per_sec() - 1.0) < 1e-6, "打磨-49 基准态 灵石速率=1.0/s (实际 %s)" % g.stone_per_sec())
	var st: Dictionary = g.stone_next_target()
	check(not st.is_empty(), "基准态 stone_next 非空 (实际 %s)" % str(st))
	ui._refresh()
	var tip: String = str(ui._stones_label.tooltip_text)
	check(tip == g.stone_next_target_tip(), "顶栏灵石 tooltip 与 stone_next_target_tip 一致 (UI %s / 接口 %s)" % [tip, g.stone_next_target_tip()])
	check(tip.begins_with("当前 1 灵石/秒"), "顶栏灵石 tooltip 前缀=当前灵石速率 (实际 %s)" % tip)
	check(tip.find("距下一件 %s「%s」" % [str(st["kind"]), str(st["name"])]) >= 0, "顶栏灵石 tooltip 指向 最便宜未拥有 %s (实际 %s)" % [str(st["name"]), tip])
	check(tip.find("还差 %s 灵石" % g.fmt(float(st["shortfall"]))) >= 0, "顶栏灵石 tooltip 含 缺口额 (实际 %s)" % tip)
	check(tip.find("可购") >= 0, "顶栏灵石 tooltip 含 可购 ETA (实际 %s)" % tip)
	# 节流: 同态再刷两帧, tooltip 文本不变 (缓存键生效)
	var tip_cache: String = str(ui._stone_tip)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._stone_tip) == tip_cache, "顶栏灵石 tooltip 同态再刷 缓存不变 (节流生效)")
	# 状态变化: 灵石足够 -> tooltip 切 可立即购买 (缓存随之更新)
	g.stones = float(st["cost"]) + 1.0
	ui._refresh()
	var tip2: String = str(ui._stones_label.tooltip_text)
	check(tip2 != tip, "灵石足够后 tooltip 变化 (缓存刷新)")
	check(tip2.find("可立即购买") >= 0, "灵石足够 tooltip=可立即购买 (实际 %s)" % tip2)
	check(tip2.find("还差") < 0, "灵石足够 tooltip 不含 还差 (实际 %s)" % tip2)
	# 状态变化: 全拥有 -> tooltip 切 已集齐
	for id in g.equip_ids:
		g.owned_eq.append(str(id))
	for it in g.ITEMS:
		g.owned.append(str((it as Dictionary)["id"]))
	ui._refresh()
	var tip3: String = str(ui._stones_label.tooltip_text)
	check(tip3.find("已集齐") >= 0, "全拥有 tooltip=已集齐 (实际 %s)" % tip3)
	# 恢复基准态 (全空, 灵石0)
	g.stones = 0.0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()


# 打磨-50: 修行页灵石速率行 内联 下一件可购 ETA (UI 侧: _stone_next_label 金色小字)
# 在 _assert_stone_tip 的基准态 (全空, 境界0, 灵石0, 灵石速率 1.0/s) 上断言:
# 缺口行文本与接口一致 / 同态节流 / 灵石足够切换 / 灵石归0恢复 / 全拥有已集齐.
func _assert_stone_next_inline() -> void:
	var g := GameData
	check(ui._stone_next_label != null, "打磨-50 _stone_next_label 节点存在")
	check(ui._stone_next_label.get_theme_color("font_color") == ui.GOLD, "打磨-50 内联标签颜色=金 (实际 %s)" % ui._stone_next_label.get_theme_color("font_color"))
	# 基准态: 缺口>0, 速率 1.0/s -> 距下一件 最便宜 缺口+ETA
	var st: Dictionary = g.stone_next_target()
	check(not st.is_empty(), "打磨-50 基准态 stone_next 非空 (实际 %s)" % str(st))
	ui._refresh()
	var t0: String = str(ui._stone_next_label.text)
	check(t0 == g.stone_next_target_inline(), "打磨-50 内联文本 与接口一致 (UI %s / 接口 %s)" % [t0, g.stone_next_target_inline()])
	check(t0.begins_with("距下一件 %s「%s」" % [str(st["kind"]), str(st["name"])]), "打磨-50 内联指向最便宜未拥有 (实际 %s)" % t0)
	check(t0.find("还差 %s 灵石" % g.fmt(float(st["shortfall"]))) >= 0, "打磨-50 内联含缺口额 (实际 %s)" % t0)
	check(t0.find("可购") >= 0, "打磨-50 内联含 可购 ETA (实际 %s)" % t0)
	# 节流: 同态再刷, 缓存不变
	var cache0: String = str(ui._stone_next_text)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._stone_next_text) == cache0, "打磨-50 内联 同态再刷 缓存不变 (节流生效)")
	# 状态变化: 灵石足够 -> 内联切 "灵石已足够, 可立即购买"
	g.stones = float(st["cost"]) + 1.0
	ui._refresh()
	var t1: String = str(ui._stone_next_label.text)
	check(t1 != t0, "打磨-50 灵石足够后 内联文本变化 (缓存刷新)")
	check(t1.find("灵石已足够, 可立即购买") >= 0, "打磨-50 灵石足够 内联=可立即购买 (实际 %s)" % t1)
	# 状态变化: 灵石归 0 -> 回到缺口行 (与接口一致)
	g.stones = 0.0
	ui._refresh()
	check(str(ui._stone_next_label.text) == t0, "打磨-50 灵石归0 内联恢复缺口行 (实际 %s)" % str(ui._stone_next_label.text))
	# 状态变化: 全拥有 -> 已集齐
	for id in g.equip_ids:
		g.owned_eq.append(str(id))
	for it in g.ITEMS:
		g.owned.append(str((it as Dictionary)["id"]))
	ui._refresh()
	var t2: String = str(ui._stone_next_label.text)
	check(t2 == "已集齐全部 装备与法器", "打磨-50 全拥有 内联=已集齐 (实际 %s)" % t2)
	# 恢复基准态 (全空, 灵石0)
	g.stones = 0.0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()


# 打磨-54: 主动神通 爆发预览断言 (行内金色标签: 未领悟隐藏/已领悟显示 当前灵气速率 x 爆发秒数;
# 预览随 境界/飞升 变化刷新; tooltip 含同口径预览行; 缓存键防重复重建)
func _assert_burst_preview() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1, 速率 1.0, 无功法/法器/装备)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.stones = 0.0
	g.essence = 0.0
	# 主动神通总数 (数据驱动: 5 类 x 6 品质, 每类 1 个主动变体 = 24)
	var n_active := 0
	for id in g.skill_ids:
		if str(g.skill_by_id[id]["type"]) == "active":
			n_active += 1
	check(n_active == 24, "打磨-54 数据含 24 主动神通 (实际 %d)" % n_active)
	check(ui._burst_previews.size() == n_active, "打磨-54 行内预览标签数=主动神通数 (实际 %d)" % ui._burst_previews.size())
	check(not ui._burst_previews.has("sword_0_0"), "打磨-54 被动功法行 无预览标签")
	ui._tab.current_tab = 1  # 技能页
	ui._refresh()
	# 未领悟: 全部隐藏 + 文本空
	var all_hidden := true
	for id in ui._burst_previews:
		var l: Label = ui._burst_previews[id]
		if l.visible or l.text != "":
			all_hidden = false
	check(all_hidden, "打磨-54 未领悟 爆发预览 全部隐藏")
	# tooltip 含 爆发预览行 (构建时初值已刷; 受控态 速率 1.0 x 60 秒)
	var row3: Node = ui._skill_row_nodes["sword_0_3"]
	check(str(row3.tooltip_text).find("爆发 +60 灵气 (当前 1/秒 x 60 秒)") >= 0, "打磨-54 未领悟 tooltip 含爆发预览行 (实际 %s)" % str(row3.tooltip_text))
	# 领悟 主动神通: 标签显示 + 金色 12px + tooltip 状态行同步
	g.learned.append("sword_0_3")
	ui._refresh()
	var lb: Label = ui._burst_previews["sword_0_3"]
	check(lb.visible, "打磨-54 已领悟 爆发预览 显示")
	check(lb.text == "爆发 +60 灵气 (当前 1/秒 x 60 秒)", "打磨-54 已领悟 预览文本 (实际 %s)" % lb.text)
	check(lb.get_theme_color("font_color") == ui.GOLD, "打磨-54 预览 金色")
	check(int(lb.get_theme_font_size("font_size")) == 12, "打磨-54 预览 12px")
	check(lb.get_parent() is VBoxContainer and lb.get_parent().get_child_count() > 0, "打磨-54 预览 挂 行内信息 VBox")
	check(str(row3.tooltip_text).find("状态: 已领悟") >= 0, "打磨-54 领悟后 tooltip 状态行=已领悟")
	# 境界提升 (筑基 x4): 速率 4.0 -> 预览数值 同步提升 (已领悟+未领悟 两口径)
	g.realm_idx = 1
	ui._refresh()
	check(lb.text == "爆发 +240 灵气 (当前 4/秒 x 60 秒)", "打磨-54 境界提升 预览数值 提升 (实际 %s)" % lb.text)
	var row_body: Node = ui._skill_row_nodes["body_0_3"]  # 未领悟 主动
	check(str(row_body.tooltip_text).find("当前 4/秒 x 60 秒") >= 0, "打磨-54 境界提升 未领悟 tooltip 预览 同步 (实际 %s)" % str(row_body.tooltip_text))
	# 飞升 (道行 x2): 速率 8.0 -> 口径 改 道行
	g.ascended = true
	g.dao_level = 1
	ui._refresh()
	check(lb.text == "爆发 +480 道行 (当前 8/秒 x 60 秒)", "打磨-54 飞升后 预览 口径改道行 (实际 %s)" % lb.text)
	# 缓存键: 与 当前 已学|预览 口径一致 (防重复重建 口径对齐)
	check(str(ui._burst_previews_key["sword_0_3"]) == "1|%s" % g.skill_burst_preview("sword_0_3"), "打磨-54 缓存键=已学|预览文本 (实际 %s)" % str(ui._burst_previews_key["sword_0_3"]))
	# 幂等: 再刷一次 无状态变化 -> 文本不变 (标签/tooltip 同值)
	var tip_before: String = str(row3.tooltip_text)
	ui._refresh()
	check(lb.text == "爆发 +480 道行 (当前 8/秒 x 60 秒)" and str(row3.tooltip_text) == tip_before, "打磨-54 重复刷新 幂等不变")
	# 恢复基准态: 取消领悟 -> 标签 再隐藏
	g.learned.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	ui._refresh()
	check(not lb.visible and lb.text == "", "打磨-54 取消领悟 预览 再隐藏")
	check(str(row3.tooltip_text).find("爆发 +60 灵气 (当前 1/秒 x 60 秒)") >= 0, "打磨-54 恢复基准 未领悟 tooltip 预览 回退")
	# 顺带修回归: 技能列表 已学在前 (原 _skill_sort 比较式语义相反, 已学被排到列表底部)
	g.learned.append("sword_0_0")
	ui._on_filter("")
	ui._refresh()
	var box54: VBoxContainer = ui._skill_box
	var first10_54 := 0
	for i in 10:
		var rn: Node = box54.get_child(i)
		for k in ui._skill_row_nodes:
			if ui._skill_row_nodes[k] == rn and g.learned.has(str(k)):
				first10_54 += 1
				break
	check(first10_54 >= 1, "打磨-54顺带修 技能列表 已学在前 (前 10 行含已学 %d)" % first10_54)
	var rn0: Node = box54.get_child(0)
	var id0 := ""
	for k in ui._skill_row_nodes:
		if ui._skill_row_nodes[k] == rn0:
			id0 = str(k)
			break
	check(id0 == "sword_0_0", "打磨-54顺带修 首行=已学技能 (实际 %s)" % id0)
	# 收尾: 等一帧让状态/布局稳定 (同 _assert_stone_next_inline 口径)
	await get_tree().process_frame


# 打磨-55: 单个神通 施展 浮动反馈 — 单个 神通行 点 施展 成功时 屏幕中央 绿色浮动 (复用 打磨-45 _onekey_float 口径,
# 文案 "施展「X」" 含神通名, 与 一键施展 的 "一键施展 N 个神通" 口径区分); 失败 (未领悟/冷却中) 与
# 点 被动功法行 不弹; 底部消息 与 浮动 并存; skill_use 统计埋点口径不变 (只增不减, 失败不增)
func _assert_skill_cast_float() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1 速率 1.0, 空 技能/法器/装备/道行)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	ui._tab.current_tab = 1
	ui._refresh()
	var fl: Label = ui._onekey_float_label
	check(fl != null, "打磨-55 浮动 Label 节点存在")
	if fl == null:
		_finish()
		return
	var c0: int = ui._onekey_float_count
	# 找 1 个 凡品 主动神通 (境界0层1 可领悟) + 1 个 同档 被动功法 + 1 个 不同件 的 未学 主动
	var act_id := ""
	var pas_id := ""
	var unact_id := ""
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if int(s["tier"]) != 0:
			continue
		if str(s["type"]) == "active" and act_id == "":
			act_id = str(id)
		elif str(s["type"]) == "passive" and pas_id == "":
			pas_id = str(id)
		if str(s["type"]) == "active" and act_id != "" and unact_id == "" and str(id) != act_id:
			unact_id = str(id)
	check(act_id != "" and pas_id != "" and unact_id != "", "打磨-55 受控态 找到 主动/被动/未学主动 (实际 %s/%s/%s)" % [act_id, pas_id, unact_id])
	# --- 未领悟: 原按钮 disabled 无法领悟 (只能走 一键领悟); 顺带修: 点击 = 领悟 (境界足够), 不弹浮动 ---
	ui._refresh()
	var btn_un: Button = ui._skill_btns[unact_id]
	check(str(btn_un.text) == "未领悟" and btn_un.disabled, "打磨-55 未领悟 按钮=未领悟+禁用 (实际 %s)" % str(btn_un.text))
	ui._on_skill_btn(unact_id, true)
	check(g.learned.has(unact_id), "打磨-55顺带修 未领悟 点击=领悟 (境界足够时)")
	check(ui._onekey_float_count == c0, "打磨-55 领悟 (非施展) 不弹浮动 (计数 %d 不变)" % c0)
	check(str(ui._msg_label.text).find("领悟「") >= 0, "打磨-55顺带修 未领悟 底部消息=领悟成功 (实际 %s)" % str(ui._msg_label.text))
	# --- 领悟 目标神通 (技能行 按钮路径): 领悟本身不弹浮动 (只有 施展 弹) ---
	var stats_use0: int = int(g.stats.get("skill_use", 0.0))
	# 顺带修: 未领悟的主动神通 点按钮 = 领悟 (原按钮被禁用 无法领悟, 只能走 一键领悟)
	ui._on_skill_btn(act_id, true)
	check(g.learned.has(act_id), "打磨-55 领悟 目标神通 (已学 %d)" % g.learned.size())
	check(int(g.stats.get("skill_use", 0.0)) == stats_use0, "打磨-55 领悟 (非施展) 不增 skill_use")
	# --- 点击 施展: 成功弹浮动 (绿色/文案含神通名/位置复位/可见) + 爆发真实加灵气 + 底部消息 并存 ---
	ui._refresh()
	var btn: Button = ui._skill_btns[act_id]
	check(str(btn.text) == "施展" and not btn.disabled, "打磨-55 已就绪 按钮=施展 (实际 %s)" % str(btn.text))
	var name: String = str(g.skill_by_id[act_id]["name"])
	# 打磨-61: 爆发总量 精确值 (受控态 境界0层1 速率 1.0, gain = 速率 x 爆发秒数)
	var act_val61: int = int(g.skill_by_id[act_id]["value"])
	var exp61: String = "施展「%s」 (爆发+%d 灵气)" % [name, act_val61]
	var ess0: float = g.essence
	ui._on_skill_btn(act_id, true)
	check(ui._onekey_float_count == c0 + 1, "打磨-55 施展成功 浮动计数+1 (期望 %d, 实际 %d)" % [c0 + 1, ui._onekey_float_count])
	check(str(ui._onekey_last_text) == exp61, "打磨-61 浮动文案=爆发+%d 灵气 (实际 %s)" % [act_val61, str(ui._onekey_last_text)])
	check(str(fl.text) == "✦ %s ✦" % exp61, "打磨-61 浮动 Label 文本 ✦…✦ (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-55 浮动文字=绿 (与 一键系列 同绿口径)")
	check(absf(fl.position.y + 26.0) < 0.5, "打磨-55 浮动位置复位 y≈-26 (实际 %.2f)" % fl.position.y)
	check(fl.modulate.a > 0.9, "打磨-55 浮动可见 (alpha=%.2f)" % fl.modulate.a)
	check(g.essence > ess0, "打磨-55 施展 爆发真实加灵气 (爆发前 %.0f → 后 %.0f)" % [ess0, g.essence])
	check(str(ui._msg_label.text).find("施展「%s」" % name) >= 0, "打磨-55 底部消息 与 浮动 并存 (实际 %s)" % str(ui._msg_label.text))
	check(int(g.stats.get("skill_use", 0.0)) == stats_use0 + 1, "打磨-55 施展成功 skill_use +1 (口径不变)")
	# --- 冷却中: 再点 不弹浮动 (只走底部消息), 失败不增 skill_use ---
	ui._refresh()
	check(str(btn.text).begins_with("冷却"), "打磨-55 施展后 按钮=冷却N秒 (实际 %s)" % str(btn.text))
	var stats_use1: int = int(g.stats.get("skill_use", 0.0))
	ui._on_skill_btn(act_id, true)
	check(ui._onekey_float_count == c0 + 1, "打磨-55 冷却中 再点 不弹浮动 (计数 %d 不变)" % (c0 + 1))
	check(str(ui._msg_label.text).find("冷却中") >= 0, "打磨-55 冷却中 底部消息=冷却中 (实际 %s)" % str(ui._msg_label.text))
	check(int(g.stats.get("skill_use", 0.0)) == stats_use1, "打磨-55 冷却中 失败 不增 skill_use")
	# --- 被动功法行: 点击 (领悟/已领悟) 不弹浮动 ---
	ui._refresh()
	var btn_p: Button = ui._skill_btns[pas_id]
	ui._on_skill_btn(pas_id, false)
	check(ui._onekey_float_count == c0 + 1, "打磨-55 被动功法 点击 不弹浮动 (计数 %d 不变)" % (c0 + 1))
	# --- 飞升态: 口径改道行, 浮动文案 同口径 (复用 _onekey_float, 文案仅 神通名 不涉 资源) ---
	g.learned.clear()
	g._active_cd.clear()
	g.ascended = true
	g.dao_level = 1
	g.dao = 0.0
	g.essence = 0.0
	check(g.can_learn(act_id), "打磨-55 飞升态 目标神通 门槛可学 (can_learn 只看 境界/层)")
	g.learned.append(act_id)
	ui._refresh()
	var dao0: float = g.dao
	ui._on_skill_btn(act_id, true)
	check(ui._onekey_float_count == c0 + 2, "打磨-55 飞升态 施展成功 浮动+1 (期望 %d, 实际 %d)" % [c0 + 2, ui._onekey_float_count])
	# 打磨-61: 飞升态 口径=道行 (飞升后倍率 x2, 速率 = 1.0 x 2)
	check(str(ui._onekey_last_text) == "施展「%s」 (爆发+%d 道行)" % [name, act_val61 * 2], "打磨-61 飞升态 浮动文案=爆发+%d 道行 (实际 %s)" % [act_val61 * 2, str(ui._onekey_last_text)])
	check(g.dao > dao0, "打磨-55 飞升态 爆发 加道行 (爆发前 %.0f → 后 %.0f)" % [dao0, g.dao])
	# 收尾: 恢复基准态 (境界0层1 未飞升, 清 已学/冷却/道行)
	g.learned.clear()
	g._active_cd.clear()
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()
	await get_tree().process_frame


# 打磨-56: 技能页 一键神通 — 只学 筛选范围内 未学+境界足够 的 主动神通 (与 一键领悟 同口径 仅 type 过滤不同):
# 按钮节点存在 / 计数文案 "一键神通 xN" 按 当前 类别/品质 筛选 (AND 叠加, 变化才刷) / 点击 只学主动神通
# (learned 全为 active, 无被动副作用, 无灵气变化) / 绿色浮动 "一键神通 N 个" (与 一键领悟 文案区分,
# 主动无被动加成故无 灵气速率 增量) / 学完 "已无新神通" / 幂等 0 变更 不弹 / tooltip 3 行口径
func _assert_active_learn() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1 速率 1.0, 空 技能/法器/装备/道行)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.dao = 0.0
	g.essence = 0.0
	g.stones = 0.0
	# 数据锚定: 境界0层1 可学 主动神通 = 6 (tier0 全 6 件, tier1+ 境界不足)
	var n_act56: int = g.active_learn_available_count()
	check(n_act56 == 6, "打磨-56 受控态 全局可学神通=6 (实际 %d)" % n_act56)
	check(g.active_learn_available_count() < g.learn_available_count(), "打磨-56 神通数 < 技能总数 (含被动)")
	# 节点: 按钮存在 + 默认文案
	var btn: Button = ui._active_learn_btn
	check(btn != null, "打磨-56 一键神通 按钮节点存在")
	if btn == null:
		return
	check(btn.get_parent() is HBoxContainer, "打磨-56 按钮 挂 技能页 品质筛选行")
	ui._tab.current_tab = 1  # 技能页
	ui._refresh()
	var t_init56 := ("一键神通 x%d" % n_act56)
	check(btn.text == t_init56, "打磨-56 初始文案=一键神通 x%d (实际 %s)" % [n_act56, btn.text])
	# 筛选 AND 叠加: sword → x1 (sword_0_3); sword×tier1 → 已无新神通 (境界不足); 恢复全部 → x6
	ui._on_filter("sword")
	ui._refresh()
	check(btn.text == "一键神通 x1", "打磨-56 类别 sword 文案 x1 (实际 %s)" % btn.text)
	ui._on_tier_filter("1")
	ui._refresh()
	check(btn.text == "已无新神通", "打磨-56 sword×tier1 境界不足 文案 已无新神通 (实际 %s)" % btn.text)
	ui._on_tier_filter("")
	ui._refresh()
	check(btn.text == "一键神通 x1", "打磨-56 品质重置 恢复 sword x1 (实际 %s)" % btn.text)
	ui._on_filter("")
	ui._refresh()
	var t_full56 := ("一键神通 x%d" % n_act56)
	check(btn.text == t_full56, "打磨-56 类别重置 恢复 全局 x%d (实际 %s)" % [n_act56, btn.text])
	# 点击: 只学 6 个主动神通, 绿色浮动 "一键神通 6 个" (与 一键领悟 "一键领悟 6 个技能" 口径区分)
	var c0: int = ui._onekey_float_count
	var snap_ess: float = g.essence
	var qi0: float = g.qi_per_sec()
	ui._on_active_learn()
	onekey_assert("一键神通 %d 个" % n_act56, c0)
	check(str(ui._onekey_last_text).find("灵气速率") < 0, "打磨-56 浮动文案 无 灵气速率 增量 (神通无被动加成, 实际 %s)" % str(ui._onekey_last_text))
	check(str(ui._msg_label.text).find("一键神通 %d 个主动神通" % n_act56) >= 0, "打磨-56 底部消息 含数量 (实际 %s)" % str(ui._msg_label.text))
	check(g.learned.size() == n_act56, "打磨-56 学到 %d (实际 %d)" % [n_act56, g.learned.size()])
	var only_act: bool = true
	for id in g.learned:
		if str(g.skill_by_id[str(id)].get("type", "")) != "active":
			only_act = false
	check(only_act, "打磨-56 只学主动神通 (learned 全为 active)")
	check(absf(g.qi_per_sec() - qi0) < 1e-9, "打磨-56 学神通 无 灵气速率 变化 (实际 %s)" % g.fmt(g.qi_per_sec()))
	check(g.essence == snap_ess, "打磨-56 无 灵气 副作用 (实际 %.0f)" % g.essence)
	# 学完: 按钮文案 切换 已无新神通 (文本变化才刷)
	ui._refresh()
	check(btn.text == "已无新神通", "打磨-56 学完文案=已无新神通 (实际 %s)" % btn.text)
	# 幂等: 再点 0 变更 不弹浮动, 走底部消息
	var c1: int = ui._onekey_float_count
	ui._on_active_learn()
	check(ui._onekey_float_count == c1, "打磨-56 0变更再点 不弹浮动 (计数 %d 不变)" % c1)
	check(str(ui._msg_label.text).find("没有可领悟的新主动神通") >= 0, "打磨-56 0变更 走底部消息 (实际 %s)" % str(ui._msg_label.text))
	# tooltip 3 行结构 + 口径词 (构建时静态文本)
	var tip: String = str(btn.tooltip_text)
	var lines: PackedStringArray = tip.split("\n")
	check(lines.size() == 3, "打磨-56 tooltip 三行结构 (实际 %d)" % lines.size())
	check(lines.size() >= 3 and lines[2].begins_with("按钮计数 ="), "打磨-56 tooltip 第3行=计数口径 (实际 %s)" % (lines[2] if lines.size() >= 3 else ""))
	check(tip.contains("主动神通"), "打磨-56 tooltip 含 主动神通 范围说明")
	check(tip.contains("AND 叠加"), "打磨-56 tooltip 含 筛选 AND 叠加口径")
	check(tip.contains("不消耗资源"), "打磨-56 tooltip 含 不消耗资源")
	check(tip.contains("飞升后"), "打磨-56 tooltip 含 飞升后 口径说明")
	# 收尾: 恢复基准态 (境界0层1, 清 已学/冷却/资源)
	g.learned.clear()
	g._active_cd.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-57: 主动神通 冷却完毕转就绪 浮动提示 — 冷却 归零 时 屏幕中央 绿色浮动
# "✦ 冷却完毕: X ✦" (文案含神通名, 与 一键施展/单个施展 浮动 口径区分), 同一批多个就绪
# 合并一行; 只读 _active_cd 事件 (不改动 状态/存档/统计); 受控态: 两个 凡品 主动神通 冷却
# 30/45 秒 不同步, 手动驱动 _tick_active_cd 后 _refresh 消费 就绪事件 触发浮动
func _assert_ready_float() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1, 空 技能/装备/法器, 清 冷却/就绪事件)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	# 节点: 就绪浮动 Label 存在 + 绿色 (与 一键系列 同绿口径) + 初始 无浮动
	var fl: Label = ui._ready_float_label
	check(fl != null, "打磨-57 就绪浮动 Label 节点存在")
	if fl == null:
		return
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-57 就绪浮动 文字色=绿")
	check(str(ui._ready_last_text) == "", "打磨-57 初始 无就绪浮动文案 (实际 %s)" % str(ui._ready_last_text))
	check(ui._ready_float_count == 0, "打磨-57 初始 就绪浮动计数=0 (实际 %d)" % ui._ready_float_count)
	# 找 两个 凡品 主动神通 (不同 id, 不同冷却: 90s/90s 同档, 用 手动注入 30/45 区分同步)
	var r_act: Array[String] = []
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if int(s["tier"]) == 0 and str(s["type"]) == "active":
			r_act.append(str(id))
	check(r_act.size() >= 2, "打磨-57 受控态 找到 >=2 个 凡品主动神通 (实际 %d)" % r_act.size())
	if r_act.size() < 2:
		return
	var a1: String = r_act[0]
	var a2: String = r_act[1]
	var n1: String = str(g.skill_by_id[a1]["name"])
	var n2: String = str(g.skill_by_id[a2]["name"])
	# 注入: 两个 已学 主动神通 冷却中 (30/45 秒 不同步), 就绪事件 清空
	g.learned.append(a1)
	g.learned.append(a2)
	g._active_cd[a1] = 30.0
	g._active_cd[a2] = 45.0
	g.ready_events.clear()
	var c0: int = ui._ready_float_count
	var stats_b: Dictionary = g.stats.duplicate(true)
	var ess_b: float = g.essence
	var sto_b: float = g.stones
	# --- 手动驱动 冷却 tick 30 秒 (GameData 已冻结 _process, 由测试手动推进): ---
	# a1 归零转就绪 (推 就绪事件), a2 余 15 秒 (不推)
	g._tick_active_cd(30.0)
	check(g.active_ready(a1) and not g.active_ready(a2), "打磨-57 30s tick 后 a1 就绪 a2 仍冷却")
	# _refresh 消费 就绪事件 -> 弹 就绪浮动 (文案仅含 a1 名, a2 未就绪)
	ui._refresh()
	check(ui._ready_float_count == c0 + 1, "打磨-57 a1 冷却完毕 浮动计数+1 (期望 %d, 实际 %d)" % [c0 + 1, ui._ready_float_count])
	check(str(ui._ready_last_text) == n1, "打磨-57 浮动文案=a1 神通名 (实际 %s)" % str(ui._ready_last_text))
	check(str(fl.text) == "✦ 冷却完毕: " + n1 + " ✦", "打磨-57 浮动 Label 文本=✦ 冷却完毕: X ✦ (实际 %s)" % str(fl.text))
	check(absf(fl.position.y + 48.0) < 0.5, "打磨-57 浮动位置复位 y≈-48 (实际 %.2f)" % fl.position.y)
	check(fl.modulate.a > 0.9, "打磨-57 浮动可见 (alpha=%.2f)" % fl.modulate.a)
	# 只读: tick/drain 不改动 资源/统计
	check(absf(g.essence - ess_b) < 1e-9, "打磨-57 tick 无 灵气 副作用 (实际 %.0f)" % g.essence)
	check(absf(g.stones - sto_b) < 1e-9, "打磨-57 tick 无 灵石 副作用 (实际 %.0f)" % g.stones)
	check(g.stats == stats_b, "打磨-57 tick 无 统计 副作用")
	# 技能行 按钮 同步: a1 冷却完毕 -> 按钮 恢复 施展
	var btn_a1: Button = ui._skill_btns[a1]
	check(str(btn_a1.text) == "施展" and not btn_a1.disabled, "打磨-57 a1 冷却完毕 按钮恢复 施展 (实际 %s)" % str(btn_a1.text))
	var btn_a2: Button = ui._skill_btns[a2]
	check(str(btn_a2.text).begins_with("冷却"), "打磨-57 a2 仍冷却 按钮=冷却N秒 (实际 %s)" % str(btn_a2.text))
	# 再 tick 15 秒: a2 归零转就绪 -> 同一 _refresh 弹 第二个 就绪浮动 (文案=a2 名)
	g._tick_active_cd(15.0)
	check(g.active_ready(a1) and g.active_ready(a2), "打磨-57 再 15s tick 后 a2 也就绪")
	var c1: int = ui._ready_float_count
	ui._refresh()
	check(ui._ready_float_count == c1 + 1, "打磨-57 a2 冷却完毕 浮动计数+1 (期望 %d, 实际 %d)" % [c1 + 1, ui._ready_float_count])
	check(str(ui._ready_last_text) == n2, "打磨-57 第二次 浮动文案=a2 神通名 (实际 %s)" % str(ui._ready_last_text))
	check(str(fl.text) == "✦ 冷却完毕: " + n2 + " ✦", "打磨-57 第二次 浮动 Label 文本 (实际 %s)" % str(fl.text))
	# --- 同一批多个就绪 合并一行: 两神通 同时 进冷却, 同帧 归零 -> 一个 浮动 含 两名 (换行) ---
	g._active_cd[a1] = 5.0
	g._active_cd[a2] = 5.0
	g.ready_events.clear()
	var c2: int = ui._ready_float_count
	g._tick_active_cd(5.0)
	ui._refresh()
	check(ui._ready_float_count == c2 + 1, "打磨-57 同帧两就绪 仅一个 浮动 (合并, 计数 %d→%d)" % [c2, ui._ready_float_count])
	var merged: String = str(ui._ready_last_text)
	check(merged.find(n1) >= 0 and merged.find(n2) >= 0 and merged != "", "打磨-57 合并文案 含 两神通名 (实际 %s)" % merged)
	check(str(fl.text).find("\n") >= 0, "打磨-57 合并 浮动 Label 多行 (含换行) (实际 %s)" % str(fl.text))
	# 无重复触发: 均已就绪, 再 tick + _refresh 不弹 新浮动 (计数不变)
	var c3: int = ui._ready_float_count
	g._tick_active_cd(10.0)
	ui._refresh()
	check(ui._ready_float_count == c3, "打磨-57 就绪后再 tick 不重复触发 浮动 (计数 %d 不变)" % c3)
	# 收尾: 恢复基准态 (清 已学/冷却/就绪事件/资源)
	g.learned.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-58: 神通冷却进度条 — 24 个主动神通行内细条 (冷却中=青色按 剩余/总冷却 填充, 归零隐藏);
# 1 秒节流 + 2% 量化档 + 布局宽变化才刷 (同 打磨-40 成就条 口径)。
# 注: 进度条初始隐藏 (未学), 容器布局跳过隐藏子节点 -> 首次 显示 当帧 宽度仍为 0 (布局未落定),
# 宽度 在下一 process_frame 落定后 由 宽变化缓存键 触发 重算填充 (自愈, 最迟 1 秒档 内 填充到位)。
# 测试手动驱动 _skill_cd_acc 跨节流档 + 直接调 _refresh_skill_cd_bars 断言 填充/节流/归零隐藏。
func _assert_cd_bars() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1, 空 技能/装备/法器, 清 冷却/就绪事件)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	ui._skill_cd_acc = 0.0
	ui._tab.current_tab = 1
	ui._refresh()
	await get_tree().process_frame
	# 节点: 24 个主动神通 均有 {bg, fill} 结构, 挂在行内信息 VBox, 初始 全部隐藏 (未学)
	var n_active := 0
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if str(s["type"]) != "active":
			continue
		n_active += 1
		var r58: Dictionary = ui._skill_cd_bars.get(str(id), {})
		check(r58.size() >= 2 and r58.get("bg") != null and r58.get("fill") != null, "打磨-58 %s 进度条节点 {bg,fill} 存在" % str(id))
		if r58.size() < 2:
			continue
		var bg58: ColorRect = r58["bg"]
		check(bg58.get_parent() is VBoxContainer, "打磨-58 %s 进度条 挂 行内信息 VBox" % str(id))
		check(bg58.size.y >= 5.0, "打磨-58 %s 进度条高>=5 (实际 %.1f)" % [str(id), bg58.size.y])
		check(bg58.color == Color(0.22, 0.24, 0.31), "打磨-58 %s 进度条底色 (实际 %s)" % [str(id), str(bg58.color)])
		check(not bg58.visible, "打磨-58 %s 初始 未学 进度条隐藏" % str(id))
	check(n_active == 24, "打磨-58 主动神通行数量=24 (实际 %d)" % n_active)
	# 找 两个 凡品主动神通 (cd 90s), 手动注入 冷却 (不同同步: a1 余 45 / a2 余 90=满)
	var r_act: Array[String] = []
	for id in g.skill_ids:
		var s2: Dictionary = g.skill_by_id[id]
		if int(s2["tier"]) == 0 and str(s2["type"]) == "active":
			r_act.append(str(id))
	check(r_act.size() >= 2, "打磨-58 受控态 找到 >=2 个 凡品主动神通 (实际 %d)" % r_act.size())
	if r_act.size() < 2:
		return
	var a1: String = r_act[0]
	var a2: String = r_act[1]
	g.learned.append(a1)
	g.learned.append(a2)
	g._active_cd[a1] = 45.0
	g._active_cd[a2] = 90.0
	var stats_b: Dictionary = g.stats.duplicate(true)
	var ess_b: float = g.essence
	# 首次 显示: 跨节流档 直调 (可见=true, 当帧 宽度 仍 0 -> 填充 0, 待 布局落定 自愈)
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	var r1: Dictionary = ui._skill_cd_bars[a1]
	var r2: Dictionary = ui._skill_cd_bars[a2]
	var bg1: ColorRect = r1["bg"]
	var bg2: ColorRect = r2["bg"]
	check(bg1.visible, "打磨-58 a1 冷却中 进度条 显示")
	check(bg2.visible, "打磨-58 a2 冷却中 进度条 显示")
	# 等一帧 布局落定 (宽度 0 -> 实际 宽), 再 直调 一次 由 宽变化缓存键 触发 填充
	await get_tree().process_frame
	check(bg1.size.x > 0.0, "打磨-58 a1 布局落定 宽度>0 (实际 %.1f)" % bg1.size.x)
	ui._refresh_skill_cd_bars()
	check(r1["fill"].color == ui.CYAN, "打磨-58 a1 填充色=青")
	check(absf(r1["fill"].size.x - bg1.size.x * 0.5) < 0.5, "打磨-58 a1 填充=50%% 宽 (余45/总90, 期望 %.1f 实际 %.1f)" % [bg1.size.x * 0.5, r1["fill"].size.x])
	check(absf(r2["fill"].size.x - bg2.size.x) < 0.5, "打磨-58 a2 填充=100%% 宽 (满冷却, 期望 %.1f 实际 %.1f)" % [bg2.size.x, r2["fill"].size.x])
	# 节流门: 未跨 1 秒档时 _refresh() 内 不触发 _refresh_skill_cd_bars (缓存键/填充 不变)
	var q1_before: String = str(ui._skill_cd_q[a1])
	var f1_before: float = r1["fill"].size.x
	ui._skill_cd_acc = 0.5
	ui._refresh()
	check(str(ui._skill_cd_q[a1]) == q1_before, "打磨-58 节流: 未跨档 不刷 (缓存键不变, 实际 %s)" % str(ui._skill_cd_q[a1]))
	check(r1["fill"].size.x == f1_before, "打磨-58 节流: 未跨档 填充不写 (宽不变)")
	# 冷却递减 (tick 25s: a1 余 20/90, a2 余 65/90) -> 跨档 直调 后 填充 同步缩短
	g._tick_active_cd(25.0)
	g.drain_ready_events()
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	var q_a1: int = int(ceil(minf(20.0 / 90.0, 1.0) * 50.0))
	var q_a2: int = int(ceil(minf(65.0 / 90.0, 1.0) * 50.0))
	check(absf(r1["fill"].size.x - bg1.size.x * float(q_a1) / 50.0) < 0.5, "打磨-58 a1 余 20/90 填充=%d/50 档 (期望 %.1f 实际 %.1f)" % [q_a1, bg1.size.x * float(q_a1) / 50.0, r1["fill"].size.x])
	check(absf(r2["fill"].size.x - bg2.size.x * float(q_a2) / 50.0) < 0.5, "打磨-58 a2 余 65/90 填充=%d/50 档 (期望 %.1f 实际 %.1f)" % [q_a2, bg2.size.x * float(q_a2) / 50.0, r2["fill"].size.x])
	check(q_a1 < 25 and q_a2 < 50, "打磨-58 tick 后 填充档 单调下降 (a1 %d<25, a2 %d<50)" % [q_a1, q_a2])
	# 只读: 刷条 不改动 资源/统计/冷却
	check(absf(g.essence - ess_b) < 1e-9 and g.stats == stats_b, "打磨-58 刷条 无 资源/统计 副作用")
	check(absf(g._active_cd[a1] - 20.0) < 1e-9 and absf(g._active_cd[a2] - 65.0) < 1e-9, "打磨-58 刷条 无 冷却 副作用")
	# 归零: tick 20s -> a1 就绪; 打磨-59 后 隐藏 由 收口动画 (_skill_close_done) 负责,
	# _refresh_skill_cd_bars 对 就绪条 只 停填充 不抢先 隐藏; a2 仍冷却 (条 保持 填充)
	g._tick_active_cd(20.0)
	g.drain_ready_events()
	check(g.active_ready(a1) and not g.active_ready(a2), "打磨-58 tick 后 a1 就绪 a2 仍冷却")
	var a1_fill_pre: float = r1["fill"].size.x
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	check(bg1.visible and r1["fill"].size.x == a1_fill_pre, "打磨-58 a1 就绪 _refresh_skill_cd_bars 不抢先隐藏 (打磨-59 收口动画 收尾, 填充 %.1f 不变)" % r1["fill"].size.x)
	check(bg2.visible and r2["fill"].size.x > 0.0, "打磨-58 a2 仍冷却 进度条 保持 填充 (实际 %.1f)" % r2["fill"].size.x)
	# 收口动画 收尾 (真实流程由 _refresh 消费 就绪事件 触发; 此处 手动驱动 终态)
	ui._skill_close_done(a1)
	check(not bg1.visible and r1["fill"].size == Vector2.ZERO, "打磨-58 a1 收口后 进度条 隐藏+填充清零")
	check(str(ui._skill_cd_q[a1]) == "hidden", "打磨-58 a1 隐藏态 缓存键=hidden (实际 %s)" % str(ui._skill_cd_q[a1]))
	# 全部就绪: a2 也 tick 到 0 -> 收口后 全部 隐藏 (无残留显示)
	g._tick_active_cd(65.0)
	g.drain_ready_events()
	check(g.active_ready(a2), "打磨-58 再 65s tick 后 a2 就绪")
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	ui._skill_close_done(a2)
	check(not bg1.visible and not bg2.visible, "打磨-58 全部就绪 收口后 进度条 全隐藏")
	# 未学隐藏: a1 取消领悟 (冷却已无) -> 条 保持 隐藏 (未学不显示; 此路径 仍由 _refresh_skill_cd_bars 亲手隐藏)
	g.learned.erase(a1)
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	check(not bg1.visible, "打磨-58 取消领悟 进度条 隐藏 (未学不显示)")
	# 收尾: 恢复基准态
	g.learned.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	ui._skill_cd_acc = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-59: 冷却完毕 收口动画 + 按钮金边微光 — 就绪事件 触发后:
# 进度条 满档 快速收窄至 0 后隐藏 (与 打磨-57 就绪浮动 同帧), 施展按钮 金边微光 渐隐回默认。
# 测试手动驱动: 注入冷却 -> 先 跨节流档 _refresh_skill_cd_bars 把条刷到 50% 可见 -> tick 归零
# -> _refresh 消费 就绪事件 (触发 收口+微光) -> 帧推进 让 tween 完成 -> 断言 终态。
func _assert_ready_flash() -> void:
	var g := GameData
	# 受控态: 全新基准
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	var stats_b: Dictionary = g.stats.duplicate(true)
	# 冻结 UI 自动 _refresh (UI._process 每帧 drain 就绪事件, 会与手动驱动竞争, 致断言竞态);
	# 本测试 全程 手动 驱动 _refresh; tween 由 SceneTree 推进, 不受 set_process(false) 影响
	ui.set_process(false)
	# 清 遗留 收口/微光 标记 (前序测试 UI 自动 drain 可能 残留)
	ui._skill_active_close.clear()
	ui._skill_active_glow.clear()
	# 找 两个 凡品 主动神通
	var r_act: Array[String] = []
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if int(s["tier"]) == 0 and str(s["type"]) == "active":
			r_act.append(str(id))
	check(r_act.size() >= 2, "打磨-59 受控态 找到 >=2 个 凡品主动神通 (实际 %d)" % r_act.size())
	if r_act.size() < 2:
		ui.set_process(true)
		return
	var a1: String = r_act[0]
	var a2: String = r_act[1]
	var seq0: int = ui._skill_ready_seq
	g.learned.append(a1)
	g.learned.append(a2)
	g._active_cd[a1] = 90.0
	g._active_cd[a2] = 135.0  # >90: 首轮 tick 90s 后 a2 仍余 45s 不就绪
	ui._tab.current_tab = 1
	ui._refresh()
	await get_tree().process_frame
	# 冷却中: 跨节流档 直调 把 条 刷成 可见 (a1 满 100% / a2 135 注入 首轮 仍冷却)
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	await get_tree().process_frame  # 布局落定
	ui._refresh_skill_cd_bars()
	var r1: Dictionary = ui._skill_cd_bars[a1]
	var r2: Dictionary = ui._skill_cd_bars[a2]
	var bg1: ColorRect = r1["bg"]
	var bg2: ColorRect = r2["bg"]
	var fill1: ColorRect = r1["fill"]
	var fill2: ColorRect = r2["fill"]
	check(bg1.visible and bg2.visible, "打磨-59 冷却中 两行 进度条 可见 (a1=%s a2=%s)" % [str(bg1.visible), str(bg2.visible)])
	check(fill1.size.x > 0.0 and fill2.size.x > 0.0, "打磨-59 冷却中 填充>0 (a1=%.1f a2=%.1f)" % [fill1.size.x, fill2.size.x])
	# 记 按钮 默认样式 边框色 (恢复后 normal 边框 须 回到 默认; 用 颜色 断言 而非 对象引用 —
	# get_theme_stylebox 返回 拷贝, 对象引用 不稳定, 颜色 才是 语义 判据)
	var btn_a1: Button = ui._skill_btns[a1]
	var btn_a2: Button = ui._skill_btns[a2]
	var DEF_BORDER := Color(0.3, 0.35, 0.45)  # _make_btn_sb_normal 边框色
	# --- a1 归零: tick 90 秒 -> a1 就绪 (a2 余 45 不就绪) ---
	g._tick_active_cd(90.0)
	check(g.active_ready(a1) and not g.active_ready(a2), "打磨-59 tick 后 a1 就绪 a2 仍冷却")
	# 手动 _refresh 消费 就绪事件 -> 浮动 + 收口 + 微光 同帧 (UI 自动 _process 已冻结, 无竞争)
	ui._refresh()
	check(ui._skill_ready_seq == seq0 + 1, "打磨-59 就绪批次计数+1 (期望 %d 实际 %d)" % [seq0 + 1, ui._skill_ready_seq])
	check(ui._skill_active_close.has(a1), "打磨-59 a1 收口动画 进行中 (标记存在)")
	check(ui._skill_active_glow.has(a1), "打磨-59 a1 按钮微光 进行中 (标记存在)")
	check(not ui._skill_active_close.has(a2) and not ui._skill_active_glow.has(a2), "打磨-59 a2 未就绪 无收口/微光 标记")
	# 微光中: 按钮 金边样式 已套 (边框色=金 0.98,0.86,0.5)
	var sb_glow: StyleBoxFlat = btn_a1.get_theme_stylebox("normal")
	check(sb_glow is StyleBoxFlat and sb_glow.border_color == Color(0.98, 0.86, 0.5), "打磨-59 a1 微光中 按钮 normal=金边 (实际 %s)" % str(sb_glow))
	# 收口中: 条 保持 可见 (收口动画 负责 收窄+隐藏 终态, 节流刷新 不抢先 隐藏 就绪条)
	check(bg1.visible, "打磨-59 a1 收口中 条 保持 可见 (动画负责终态)")
	# a2 不受 a1 事件影响: 条 保持 冷却 填充
	check(bg2.visible and fill2.size.x > 0.0, "打磨-59 a2 仍冷却 条保持 (实际 %.1f)" % fill2.size.x)
	# 节流门: 就绪条 被 _refresh_skill_cd_bars 跳过 (不 隐藏/不清零, 由 收口动画 收尾)
	var fill1_pre: float = fill1.size.x
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	check(bg1.visible and fill1.size.x == fill1_pre, "打磨-59 收口中 节流刷新 跳过 a1 不抢先隐藏 (填充 %.1f 不变)" % fill1.size.x)
	check(str(ui._skill_cd_q[a1]) != "hidden", "打磨-59 收口中 a1 缓存键 未 归 hidden (实际 %s)" % str(ui._skill_cd_q[a1]))
	# --- 收口 终态 手动驱动 (headless 帧时间不确定, 不依赖 tween 自然跑完; 驱动 动画结束回调) ---
	ui._skill_close_done(a1)
	check(not bg1.visible, "打磨-59 a1 收口完成 条 隐藏")
	check(fill1.size == Vector2.ZERO, "打磨-59 a1 收口完成 填充清零 (实际 %s)" % str(fill1.size))
	check(str(ui._skill_cd_q[a1]) == "hidden", "打磨-59 a1 缓存键=hidden (实际 %s)" % str(ui._skill_cd_q[a1]))
	check(not ui._skill_active_close.has(a1), "打磨-59 a1 收口标记 已清除")
	# --- 微光 终态 手动驱动 (驱动 微光结束回调, 恢复 默认样式) ---
	ui._skill_glow_done(a1)
	var sb_n_after: StyleBoxFlat = btn_a1.get_theme_stylebox("normal")
	check(sb_n_after is StyleBoxFlat and sb_n_after.border_color == DEF_BORDER, "打磨-59 a1 微光结束 normal 边框 恢复 默认 (实际 %s)" % str(sb_n_after))
	check(not ui._skill_active_glow.has(a1), "打磨-59 a1 微光标记 已清除")
	# 恢复后 冷却 刷新 可再次 驱动 a1 (无残留 卡死)
	g._active_cd[a1] = 45.0
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	check(bg1.visible and fill1.size.x > 0.0, "打磨-59 恢复后 再进冷却 条可再次 显示 (实际 %.1f)" % fill1.size.x)
	# --- 同批多就绪: a1/a2 同时 归零 -> 一个批次 触发 双收口+双微光 ---
	# 注: a1 刚重注 45s, a2 尚余 45s, 本次 tick 45s 使 a1/a2 同帧 归零 -> 同批 两就绪
	g._tick_active_cd(45.0)
	check(g.active_ready(a1) and g.active_ready(a2), "打磨-59 同批 tick 后 a1/a2 均就绪")
	ui._refresh()
	check(ui._skill_active_close.has(a1) and ui._skill_active_close.has(a2), "打磨-59 同批双就绪 双收口 进行中")
	check(ui._skill_active_glow.has(a1) and ui._skill_active_glow.has(a2), "打磨-59 同批双就绪 双微光 进行中")
	# 同批 双 终态 手动驱动
	ui._skill_close_done(a1)
	ui._skill_close_done(a2)
	ui._skill_glow_done(a1)
	ui._skill_glow_done(a2)
	check(not ui._skill_active_close.has(a1) and not ui._skill_active_close.has(a2), "打磨-59 同批 收口 全部完成")
	check(not ui._skill_active_glow.has(a1) and not ui._skill_active_glow.has(a2), "打磨-59 同批 微光 全部完成")
	check(not bg1.visible and not bg2.visible, "打磨-59 同批 双条 终态 隐藏")
	var sb_a1_after: StyleBoxFlat = btn_a1.get_theme_stylebox("normal")
	check(sb_a1_after is StyleBoxFlat and sb_a1_after.border_color == DEF_BORDER, "打磨-59 同批 a1 样式 恢复 默认 (边框 %s)" % str(sb_a1_after))
	var sb_a2_after: StyleBoxFlat = btn_a2.get_theme_stylebox("normal")
	check(sb_a2_after is StyleBoxFlat and sb_a2_after.border_color == DEF_BORDER, "打磨-59 同批 a2 样式 恢复 默认 (边框 %s)" % str(sb_a2_after))
	# 只读: 收口/微光 不改动 资源/统计
	check(absf(g.essence) < 1e-9 and g.stats == stats_b, "打磨-59 收口/微光 无 资源/统计 副作用")
	# 收尾: 恢复基准态 + 解冻 UI
	g.learned.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	ui._skill_cd_acc = 0.0
	ui._skill_active_close.clear()
	ui._skill_active_glow.clear()
	ui.set_process(true)
	ui._refresh()
	await get_tree().process_frame


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
