extends Node
## 打磨-40: 成就页进度条 UI 断言 (headless 可跑, scene 模式带 autoload GameData/Steam)
## 打磨-41: 技能/装备/法器 行首品质色竖条断言 (存在/首子节点/颜色与数据 tier 或价格档一致)
## 打磨-42: 成就页顶栏收集进度一览 mini 进度条断言 (4 条节点/0 填充/满态金/半态比例/节流缓存)
## 打磨-43: 收集进度一览加 总计 mini 进度条断言 (5 条节点/总计=10/287 与 137/287 两态/wrap 换行布局)
## 打磨-44: 收集进度一览 点击直达断言 (5 条 flat Button+手型光标/tooltip/点击切 Tab 重置筛选/
##          法器区金边高亮+自动恢复/无存档统计副作用/总计不切页)
## 打磨-71: 自动系列 汇总行 点击直达断言 (3 段热区 flat Button+手型光标/tooltip 口径/点击切
##          对应 自动开关 同 口径+底部消息+上方按钮同步按压态/节流/无 资源/统计 副作用)
## 打磨-72: 启动 自动系列 恢复 提示断言 (_ready 三关 不提示 计数 0/手动驱动 单开+组合 底部消息
##          文案=auto_restore_text+计数+1/离线消息 优先 让位/全关 不提示/无 资源/统计 副作用/收尾 恢复)
## 打磨-73: 顶栏 自动系列 状态徽标断言 (金色徽标节点 顶栏子节点/全关 隐藏 文本空/单开 显示
##          "自动 1/3"+tooltip 复用 auto_summary_text/两开 "2/3"/三开 "3/3"/全关 恢复 隐藏/
##          节流 同态 不重写 文本/无 资源/统计 副作用/收尾 三关 隐藏)
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
	# 防御性重置 自动系列 四开关 (autoload 启动时 已从 档 load 进内存, 旧档 可能 残留 true;
	# 不清会导致 打磨-69/70/71/80 初始态 错位 级联失败 — 每轮 强制 干净 基准)
	g0.auto_break = false
	g0.auto_buy = false
	g0.auto_cast = false
	g0.auto_learn = false
	# 打磨-72: 防御性 重置 离线收益 文案/明细 (autoload 启动 load_game 读 旧档 时间戳,
	# 距上轮 运行 >60 秒 时 已 结算 离线收益 置 offline_msg 非空; 残留 会 让 打磨-72
	# 启动 自动恢复 提示 走 离线优先 分支 被抑制 — 重置 保证 干净 基准)
	g0.offline_msg = ""
	g0._offline_sec = 0.0
	g0._offline_qi = 0.0
	g0._offline_stone = 0.0
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
	await _assert_ready_float_burst()
	await _assert_cd_bars()
	await _assert_ready_flash()
	await _assert_chance_expect_tip()
	await _assert_break_fail_float()
	await _assert_break_ok_float()
	_assert_offline_float()
	await _assert_auto_break()
	await _assert_auto_buy()
	await _assert_auto_cast()
	await _assert_auto_learn()
	await _assert_auto_summary()
	await _assert_auto_sum_jump()
	_assert_auto_restore()
	await _assert_auto_badge()
	await _assert_auto_badge_jump()
	await _assert_onekey_badge()
	await _assert_onekey_tip_detail()
	await _assert_play_time_badge()
	_assert_primary_rate_badge()
	_assert_stone_rate_badge()
	await _assert_goalbar()
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
	# 打磨-62: 受控态 速率=1.0 (境界0层1, 无 功法/装备/法器), 爆发 恒等 速率 x 爆发秒数
	var v1: int = int(g.skill_by_id[a1]["value"])
	var v2: int = int(g.skill_by_id[a2]["value"])
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
	check(str(fl.text) == "✦ 冷却完毕: " + n1 + " ✦ (爆发+%d 灵气)" % v1, "打磨-62 浮动 Label 文本=✦ 冷却完毕: X ✦ (爆发+N 灵气) (实际 %s)" % str(fl.text))
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
	check(str(fl.text) == "✦ 冷却完毕: " + n2 + " ✦ (爆发+%d 灵气)" % v2, "打磨-62 第二次 浮动 Label 文本=爆发+N 灵气 (实际 %s)" % str(fl.text))
	# --- 同一批多个就绪 合并一行: 两神通 同时 进冷却, 同帧 归零 -> 一个 浮动 含 两名 (换行) ---
	g._active_cd[a1] = 5.0
	g._active_cd[a2] = 5.0
	g.ready_events.clear()
	var c2: int = ui._ready_float_count
	g._tick_active_cd(5.0)
	ui._refresh()
	check(ui._ready_float_count == c2 + 1, "打磨-57 同帧两就绪 仅一个 浮动 (合并, 计数 %d→%d)" % [c2, ui._ready_float_count])
	check(str(fl.text) == "✦ 冷却完毕: " + n1 + "\n" + n2 + " ✦ (爆发+%d 灵气)" % (v1 + v2), "打磨-62 合并浮动 爆发总量=两神通值之和 (实际 %s)" % str(fl.text))
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


# 打磨-62: 冷却完毕 浮动 追加 爆发总量 — 飞升态 口径=道行 (飞升后 灵气速率 x2,
# 爆发 = 速率 x 爆发秒数 x 2), 文案 与 打磨-60/61 "爆发+N 灵气/道行" 同格式, 2 态 精确匹配。
# 注: 就绪事件 触发 打磨-59 收口+微光 (tween+标记), 且 UI 自动 _process 每帧 _refresh 会与 手动驱动 竞争;
# 全程 冻结 UI 手动 驱动 _refresh, 收尾 手动驱动 收口/微光 终态 回调 + 清 标记, 避免 泄漏 污染 后续 58 测试。
func _assert_ready_float_burst() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1, 空 技能/装备/法器)
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
	# 冻结 UI 自动 _refresh (同 打磨-59 口径: UI 自动 drain 就绪事件 会与 手动驱动 竞争 致 断言竞态)
	ui.set_process(false)
	# 清 遗留 收口/微光 标记 (前序测试 UI 自动 drain 可能 残留)
	ui._skill_active_close.clear()
	ui._skill_active_glow.clear()
	# 找 1 个 凡品 主动神通
	var a1 := ""
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if int(s["tier"]) == 0 and str(s["type"]) == "active":
			a1 = str(id)
			break
	check(a1 != "", "打磨-62 受控态 找到 凡品主动神通 (实际 %s)" % a1)
	if a1 == "":
		ui.set_process(true)
		return
	var name: String = str(g.skill_by_id[a1]["name"])
	var v: int = int(g.skill_by_id[a1]["value"])
	var fl: Label = ui._ready_float_label
	# --- 态1 未飞升: 速率 1.0, 冷却归零 就绪 -> 浮动 含 "爆发+v 灵气" 精确匹配 ---
	g.learned.append(a1)
	g._active_cd[a1] = 30.0
	g.ready_events.clear()
	g._tick_active_cd(30.0)
	ui._refresh()
	check(str(fl.text) == "✦ 冷却完毕: " + name + " ✦ (爆发+%d 灵气)" % v, "打磨-62 未飞升 浮动文案=爆发+%d 灵气 (实际 %s)" % [v, str(fl.text)])
	# --- 态2 飞升: 速率 x2 (道行阶段1, 同 打磨-61 飞升态口径), 冷却归零 就绪 -> 浮动 含 "爆发+2v 道行" ---
	g._active_cd[a1] = 30.0
	g.ready_events.clear()
	g.ascended = true
	g.dao_level = 1
	g._tick_active_cd(30.0)
	ui._refresh()
	check(str(fl.text) == "✦ 冷却完毕: " + name + " ✦ (爆发+%d 道行)" % (v * 2), "打磨-62 飞升态 浮动文案=爆发+%d 道行 (实际 %s)" % [v * 2, str(fl.text)])
	# 收尾: 恢复基准态 (未飞升, 清 已学/冷却/就绪事件/资源)
	g.learned.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	# 手动驱动 打磨-59 收口/微光 终态 回调 (headless 不依赖 tween 自然跑完, 清 标记 并 恢复 默认样式/隐藏条,
	# 避免 泄漏 污染 后续 打磨-58 进度条 断言)
	ui._skill_close_done(a1)
	ui._skill_glow_done(a1)
	ui._skill_cd_acc = 0.0
	ui._skill_active_close.clear()
	ui._skill_active_glow.clear()
	ui.set_process(true)
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
	# 等 布局落定 (宽度 0 -> 实际 宽, headless 高负载时 1 帧可能不够, 上限 20 帧; 顺带修既有 flake)
	for _i58 in 20:
		await get_tree().process_frame
		if bg1.size.x > 0.0 and bg2.size.x > 0.0:
			break
	check(bg1.size.x > 0.0, "打磨-58 a1 布局落定 宽度>0 (实际 %.1f)" % bg1.size.x)
	check(bg2.size.x > 0.0, "打磨-58 a2 布局落定 宽度>0 (实际 %.1f)" % bg2.size.x)
	# 宽度落定后 再 直调 一次 由 宽变化缓存键 触发 填充
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
	var r1: Dictionary = ui._skill_cd_bars[a1]
	var r2: Dictionary = ui._skill_cd_bars[a2]
	var bg1: ColorRect = r1["bg"]
	var bg2: ColorRect = r2["bg"]
	var fill1: ColorRect = r1["fill"]
	var fill2: ColorRect = r2["fill"]
	check(bg1.visible and bg2.visible, "打磨-59 冷却中 两行 进度条 可见 (a1=%s a2=%s)" % [str(bg1.visible), str(bg2.visible)])
	# 等 布局落定 (宽度 0 -> 实际 宽, headless 高负载时 1 帧可能不够, 上限 20 帧; 与 打磨-58 同款加固)
	for _i59 in 20:
		await get_tree().process_frame
		if bg1.size.x > 0.0 and bg2.size.x > 0.0:
			break
	ui._refresh_skill_cd_bars()
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


# 打磨-63: 突破成功率 tooltip 预期成本 (UI 侧: _chance_label.tooltip_text 随 _refresh 刷新, 含 期望次数/期望总消耗)
# 在 打磨-59 收尾 基准态 (全空, 练气第1层, 未飞升) 上断言: tooltip=构成段+预期成本两行, 口径与接口一致,
# 状态变化 (境界/飞升) 刷新, 道祖封顶 不追加.
func _assert_chance_expect_tip() -> void:
	var g := GameData
	check(ui._chance_label != null, "打磨-63 _chance_label 节点存在")
	# 基准态: 练气第1层 85%, cost 10 -> 构成段 + 预期成本两行
	check(absf(g.primary_break_chance() - 0.85) < 1e-9, "打磨-63 基准态 成功率=0.85 (实际 %s)" % g.primary_break_chance())
	ui._tab.current_tab = 0
	ui._refresh()
	var tip0: String = str(ui._chance_label.tooltip_text)
	check(tip0 == g.primary_break_chance_tip(), "打磨-63 UI tooltip 与接口一致 (UI %s / 接口 %s)" % [tip0, g.primary_break_chance_tip()])
	check(tip0.find("突破成功率 85% 构成:") >= 0, "打磨-63 基准 tooltip 含 构成段 (实际 %s)" % tip0)
	check(tip0.find("· 期望次数 ~1.2 次 (成功率 85%)") >= 0, "打磨-63 基准 tooltip 含 期望次数 (实际 %s)" % tip0)
	check(tip0.find("· 期望总消耗 ~11 灵气") >= 0, "打磨-63 基准 tooltip 含 期望总消耗 灵气 口径 (实际 %s)" % tip0)
	# 节流: 同态再刷 缓存不变
	var cache0: String = str(ui._chance_tip)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._chance_tip) == cache0, "打磨-63 同态再刷 缓存不变 (节流生效)")
	# 状态变化: 筑基第2层 81%, cost 60 -> 期望 1.2 次/74 灵气 (tooltip 随之刷新)
	g.realm_idx = 1
	g.layer = 2
	ui._refresh()
	var tip1: String = str(ui._chance_label.tooltip_text)
	check(tip1 != tip0, "打磨-63 境界变化后 tooltip 刷新 (缓存更新)")
	check(tip1.find("突破成功率 81%") >= 0, "打磨-63 筑基 tooltip 成功率 81%% (实际 %s)" % tip1)
	check(tip1.find("· 期望总消耗 ~74 灵气") >= 0, "打磨-63 筑基 tooltip 期望总消耗 74 灵气 (实际 %s)" % tip1)
	# 状态变化: 飞升 初仙 90% -> 道行 口径 (cost 1e9 -> 11.1亿 道行)
	g.ascended = true
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()
	var tip2: String = str(ui._chance_label.tooltip_text)
	check(tip2.find("道行精进成功率 90%") >= 0, "打磨-63 飞升 tooltip 道行精进 90%% (实际 %s)" % tip2)
	check(tip2.find("· 期望次数 ~1.1 次 (成功率 90%)") >= 0, "打磨-63 飞升 tooltip 期望次数 (实际 %s)" % tip2)
	check(tip2.find("· 期望总消耗 ~11.1亿 道行") >= 0, "打磨-63 飞升 tooltip 期望总消耗 道行 口径 (实际 %s)" % tip2)
	# 状态变化: 道祖封顶 -> 圆满文案, 不追加 预期成本
	g.dao_level = 8
	ui._refresh()
	var tip3: String = str(ui._chance_label.tooltip_text)
	check(tip3.find("已至道祖") >= 0, "打磨-63 道祖 tooltip 圆满文案 (实际 %s)" % tip3)
	check(tip3.find("期望次数") < 0 and tip3.find("期望总消耗") < 0, "打磨-63 道祖 tooltip 不追加 预期成本 (实际 %s)" % tip3)
	# 恢复基准态
	g.ascended = false
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-64: 突破/道行精进 失败 浮动提示 含 本次消耗+预期成本 (UI 侧: _float_label 文案=接口, 红色;
# 资源不足不触发 / 道祖封顶 基础文案; _on_break 真实路径 扣资源+埋点 口径验证)
func _assert_break_fail_float() -> void:
	var g := GameData
	# 受控态: 全新基准 (基准态 由 打磨-63 收尾 保证)
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
	var fl: Label = ui._float_label
	var stats_b: Dictionary = g.stats.duplicate(true)
	# 0=未触发: _float_break 直接返回, 文案不变
	fl.text = "SENTINEL_64"
	g.last_break_result = 0
	ui._float_break()
	check(str(fl.text) == "SENTINEL_64", "打磨-64 last_break_result=0 不触发 浮动 (实际 %s)" % str(fl.text))
	# 未飞升 失败: 注入 roll=0.999 必失败 (85% 成功率, 确定性), 再驱动 UI _float_break 渲染
	g.essence = 20.0
	var ess_b: float = g.essence
	g.try_breakthrough(0.999)
	ui._float_break()
	var txt64: String = str(fl.text)
	var expect64: String = g.break_fail_float_text()
	check(txt64 == expect64, "打磨-64 未飞升 失败浮动=接口文案 (实际 %s / 接口 %s)" % [txt64, expect64])
	check(txt64.begins_with("✖ 突破失败… ✖  本次耗 "), "打磨-64 未飞升 前缀+本次耗 (实际 %s)" % txt64)
	check(txt64.find("期望次数 ~1.2 次") >= 0 and txt64.find("期望总消耗 ~11 灵气") >= 0, "打磨-64 未飞升 含 预期成本 (实际 %s)" % txt64)
	check(fl.get_theme_color("font_color") == Color(1.0, 0.45, 0.4), "打磨-64 未飞升 失败浮动 红色")
	check(absf(g.essence - (ess_b - 10.0)) < 1e-9, "打磨-64 失败 扣突破消耗 10 灵气 (实际 %s)" % g.essence)
	check(float(g.stats.get("break_fail", 0.0)) == float(stats_b.get("break_fail", 0.0)) + 1.0, "打磨-64 失败 break_fail+1 埋点")
	# 资源不足: try_breakthrough 走 灵气不足 分支 (roll 前返回), last_break_result 保持 0 -> 不弹浮动
	fl.text = "SENTINEL_64"
	g.essence = 5.0
	var msg64: String = g.try_breakthrough()
	ui._float_break()
	check(str(fl.text) == "SENTINEL_64", "打磨-64 资源不足 不触发 浮动 (实际 %s)" % str(fl.text))
	check(msg64.find("灵气不足") >= 0, "打磨-64 资源不足 返回 灵气不足 消息 (实际 %s)" % msg64)
	# 飞升后 失败: 道行 口径 (初仙 90%, cost 1e9 -> 10.0亿 道行)
	g.ascended = true
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 2.0e9
	var dao_b: float = g.dao
	g.try_dao_break(0.999)
	ui._float_break()
	var txt65: String = str(fl.text)
	expect64 = g.break_fail_float_text()
	check(txt65 == expect64, "打磨-64 飞升 失败浮动=接口文案 (实际 %s / 接口 %s)" % [txt65, expect64])
	check(txt65.begins_with("✖ 道行精进失败… ✖  本次耗 10.0亿 道行"), "打磨-64 飞升 前缀+本次耗 道行 (实际 %s)" % txt65)
	check(txt65.find("期望次数 ~1.1 次") >= 0 and txt65.find("期望总消耗 ~11.1亿 道行") >= 0, "打磨-64 飞升 含 预期成本 道行 口径 (实际 %s)" % txt65)
	check(fl.get_theme_color("font_color") == Color(1.0, 0.45, 0.4), "打磨-64 飞升 失败浮动 红色")
	check(absf(g.dao - (dao_b - 1.0e9)) < 1e-6, "打磨-64 飞升失败 扣道行 1e9 (实际 %s)" % g.dao)
	# 道祖封顶: try_dao_break 直接返回 (圆满 无失败), last_break_result=0 -> 不弹浮动
	g.dao_level = 8
	fl.text = "SENTINEL_64"
	var msg65: String = g.try_dao_break()
	ui._float_break()
	check(str(fl.text) == "SENTINEL_64", "打磨-64 道祖 不触发 浮动 (实际 %s)" % str(fl.text))
	check(msg65.find("已至道祖") >= 0, "打磨-64 道祖 返回 圆满 消息 (实际 %s)" % msg65)
	check(g.break_fail_float_text() == "✖ 道行精进失败… ✖", "打磨-64 道祖 接口=基础文案 不追加 (实际 %s)" % g.break_fail_float_text())
	# 恢复基准态
	g.ascended = false
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-65: 突破/道行精进 成功 浮动提示 含 新境界+当前成功率 (UI 侧: _float_label 文案=接口, 绿色/金色;
# 未触发不弹; 与 打磨-64 失败浮动 互补)
func _assert_break_ok_float() -> void:
	var g := GameData
	# 受控态: 全新基准 (基准态 由 打磨-64 收尾 保证)
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
	g.last_break_result = 0
	var fl: Label = ui._float_label
	# 普通成功: 练气1层 攒够 10 灵气, roll=0.01 必成功 -> 晋升 练气第2层 (成功率仍 85%)
	g.essence = 10.0
	g.try_breakthrough(0.01)
	ui._float_break()
	var ok65: String = str(fl.text)
	check(ok65 == g.break_ok_float_text(), "打磨-65 普通成功 浮动=接口 (实际 %s / 接口 %s)" % [ok65, g.break_ok_float_text()])
	check(ok65 == "✦ 突破成功! 晋升 练气 第 2 层 (当前成功率 85%) ✦", "打磨-65 普通成功 文案 新境界+成功率 (实际 %s)" % ok65)
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-65 普通成功 绿色")
	check(absf(g.essence - (10.0 - 10.0)) < 1e-9, "打磨-65 成功 扣突破消耗 10 灵气 (实际 %s)" % g.essence)
	# 跨境界成功: 练气顶层第 9 层 (消耗 90) -> 筑基第1层 -> 成功率 81%
	fl.text = "SENTINEL_65"
	g.layer = 9
	g.essence = 90.0
	g.try_breakthrough(0.01)
	check(g.realm_idx == 1 and g.layer == 1, "打磨-65 跨境界成功 境界=筑基第1层 (实际 %s)" % g.realm_display())
	ui._float_break()
	ok65 = str(fl.text)
	check(ok65 == g.break_ok_float_text(), "打磨-65 跨境界成功 浮动=接口 (实际 %s)" % ok65)
	check(ok65.find("晋升 筑基 第 1 层") >= 0 and ok65.find("当前成功率 81%") >= 0, "打磨-65 跨境界成功 文案 新境界+新成功率 (实际 %s)" % ok65)
	# 飞升: 真仙境(第 9 境) 顶层第 1 层 (消耗 196830) 成功 -> 飞升 (金色, 无成功率口径)
	g.realm_idx = 9
	g.layer = 1
	fl.text = "SENTINEL_65"
	g.essence = 196830.0
	g.try_breakthrough(0.01)
	ui._float_break()
	ok65 = str(fl.text)
	check(ok65 == g.break_ok_float_text(), "打磨-65 飞升 浮动=接口 (实际 %s)" % ok65)
	check(ok65 == "☀ 飞升真仙! 仙凡两隔, 灵气 x100000 ☀", "打磨-65 飞升 文案 (实际 %s)" % ok65)
	check(fl.get_theme_color("font_color") == Color(0.98, 0.86, 0.5), "打磨-65 飞升 金色")
	# 道行精进: 初仙 攒够 1e9 道行 成功 -> 晋阶 少仙 (成功率 87%)
	g.dao = 1.0e9
	fl.text = "SENTINEL_65"
	g.try_dao_break(0.01)
	ui._float_break()
	ok65 = str(fl.text)
	check(ok65 == g.break_ok_float_text(), "打磨-65 精进成功 浮动=接口 (实际 %s)" % ok65)
	check(ok65 == "✦ 道行精进! 晋阶 少仙 (当前成功率 87%) ✦", "打磨-65 精进成功 文案 阶段+成功率 (实际 %s)" % ok65)
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-65 精进成功 绿色")
	# 未触发: last_break_result=0 -> 不弹 浮动 (文案不变)
	g.last_break_result = 0
	fl.text = "SENTINEL_65"
	ui._float_break()
	check(str(fl.text) == "SENTINEL_65", "打磨-65 未触发 不弹 浮动 (实际 %s)" % str(fl.text))
	# 恢复基准态
	g.ascended = false
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	g.last_break_result = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-66: 离线收益 启动浮动 — 手动驱动 确定性断言 (不依赖启动时是否真离线, 防 flake):
# 金色浮动 Label / 文案=offline_float_text / 计数+1 / 可见 / 位置复位 y≈-84;
# 未飞升(灵气) 与 飞升(道行) 两态口径; 无收益(明细全0) 与 不足1分钟 不弹 计数不变
func _assert_offline_float() -> void:
	var g := GameData
	var ofl: Label = ui._offline_float_label
	check(ofl != null, "打磨-66 离线浮动 Label 节点存在")
	if ofl == null:
		return
	check(ofl.get_theme_color("font_color") == ui.GOLD, "打磨-66 离线浮动 文字色=金 (实际 %s)" % str(ofl.get_theme_color("font_color")))
	# --- 未飞升 口径: 确定性明细 (5400s, 各 2700) ---
	g.ascended = false
	g._offline_sec = 5400.0
	g._offline_qi = 2700.0
	g._offline_stone = 2700.0
	var exp66: String = g.offline_float_text()
	check(exp66 == "☾ 离线 1小时30分, 收获 灵气 2700 · 灵石 2700 ☾", "打磨-66 离线浮动 文案(未飞升) (实际 %s)" % exp66)
	var cnt_before: int = ui._offline_float_count
	ui._offline_float()
	check(ui._offline_float_count == cnt_before + 1, "打磨-66 手动驱动 浮动计数+1 (实际 %d)" % ui._offline_float_count)
	check(str(ui._offline_last_text) == exp66, "打磨-66 离线浮动 文案=offline_float_text (实际 %s)" % str(ui._offline_last_text))
	check(str(ofl.text) == exp66, "打磨-66 离线浮动 Label 文本=接口 (实际 %s)" % str(ofl.text))
	check(exp66.find("☾") >= 0 and exp66.find("灵气") >= 0 and exp66.find("灵石") >= 0, "打磨-66 文案含 ☾/灵气/灵石 (实际 %s)" % exp66)
	check(ofl.modulate.a > 0.5, "打磨-66 离线浮动 可见 (modulate.a>0.5, 实际 %.2f)" % ofl.modulate.a)
	check(absf(ofl.position.y + 84.0) < 0.5, "打磨-66 离线浮动 位置复位 y≈-84 (实际 %.2f)" % ofl.position.y)
	# --- 飞升 口径: 主资源=道行 (7200s, 3.6亿) ---
	g.ascended = true
	g._offline_sec = 7200.0
	g._offline_qi = 3.6e8
	g._offline_stone = 3.6e8
	var exp66b: String = g.offline_float_text()
	check(exp66b.find("道行") >= 0 and exp66b.find("2小时") >= 0, "打磨-66 飞升 文案含 道行/2小时 (实际 %s)" % exp66b)
	var cnt_b2: int = ui._offline_float_count
	ui._offline_float()
	check(ui._offline_float_count == cnt_b2 + 1, "打磨-66 飞升 手动驱动 计数+1 (实际 %d)" % ui._offline_float_count)
	check(str(ofl.text) == exp66b, "打磨-66 飞升 浮动文本=接口 (实际 %s)" % str(ofl.text))
	# --- 无收益 不弹: 明细全 0 ---
	g._offline_sec = 0.0
	g._offline_qi = 0.0
	g._offline_stone = 0.0
	check(g.offline_float_text() == "", "打磨-66 无收益 空串 (实际 %s)" % g.offline_float_text())
	var cnt_b3: int = ui._offline_float_count
	ui._offline_float()
	check(ui._offline_float_count == cnt_b3, "打磨-66 无收益 不弹 计数不变 (实际 %d)" % ui._offline_float_count)
	# --- 不足 1 分钟 不弹 ---
	g._offline_sec = 30.0
	g._offline_qi = 15.0
	g._offline_stone = 15.0
	check(g.offline_float_text() == "", "打磨-66 不足1分钟 空串 (实际 %s)" % g.offline_float_text())
	# 收尾: 恢复明细 (防污染 后续断言/收尾)
	g._offline_sec = 0.0
	g._offline_qi = 0.0
	g._offline_stone = 0.0
	g.ascended = false
	ui._refresh()
	await get_tree().process_frame


# 打磨-67: 自动突破 — 开关按钮存在/tooltip/点击切换/开关态同步/浮动文案 "(自动)" 标注 (成功绿+标注,
# 失败红+标注, 关闭不标注); 事件走 break_seq 统一驱动 (浮动/闪烁 与手动按钮 同口径); 收尾恢复基准态
func _assert_auto_break() -> void:
	var g := GameData
	var btn: Button = ui._auto_break_btn
	check(btn != null, "打磨-67 自动突破开关按钮存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-67 开关按钮 toggle_mode")
	check(btn.tooltip_text.find("资源攒够") >= 0 and btn.tooltip_text.find("存档") >= 0,
		"打磨-67 tooltip 含 资源攒够/存档 口径 (实际 %s)" % btn.tooltip_text)
	check(btn.tooltip_text.find("离线期间不触发") >= 0, "打磨-67 tooltip 含 离线期间不触发 口径")
	check(g.auto_break == false and not btn.button_pressed and str(btn.text) == "自动突破: 关",
		"打磨-67 初始 关 态 (文本/按压/存档值 一致)")
	# 点击切换: 开 (底部消息 + 按钮态 + 存档值)
	ui._on_auto_break()
	check(g.auto_break == true, "打磨-67 点击后 auto_break=true (实际 %s)" % str(g.auto_break))
	check(btn.button_pressed and str(btn.text) == "自动突破: 开", "打磨-67 点击后 按钮按压+文本 开")
	check(str(ui._msg_label.text).find("自动突破已开启") >= 0, "打磨-67 开启 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 点击切换: 关
	ui._on_auto_break()
	check(g.auto_break == false and not btn.button_pressed and str(btn.text) == "自动突破: 关", "打磨-67 再点 关 态")
	check(str(ui._msg_label.text).find("自动突破已关闭") >= 0, "打磨-67 关闭 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 外部改存档值: _refresh 同步按钮态 (读档恢复 场景)
	g.auto_break = true
	ui._refresh()
	check(btn.button_pressed and str(btn.text) == "自动突破: 开", "打磨-67 _refresh 同步 外部置 开 按钮态")
	# 浮动文案 "(自动)" 标注: 成功 (手动 _try_auto_break 注入 roll, 事件走 break_seq, 手动驱动 _float_break)
	# 受控态: 重置 基准 (练气第1层, 无加成, cost=10, 成功率 85%)
	var fl: Label = ui._float_label
	var stats_ab: Dictionary = g.stats.duplicate(true)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 10.0
	g.dao = 0.0
	g.last_break_result = 0
	g._try_auto_break(0.01)
	check(g.last_break_result == 1 and g.layer == 2, "打磨-67 UI 自动成功 事件=1 升层 (实际 %s)" % g.realm_display())
	fl.text = "SENTINEL_67"
	ui._float_break()
	check(str(fl.text) == g.break_ok_float_text() + " (自动)", "打磨-67 成功浮动=接口+ (自动) 标注 (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-67 成功浮动 绿色")
	check(float(g.stats.get("break_ok", 0.0)) == float(stats_ab.get("break_ok", 0.0)) + 1.0, "打磨-67 自动成功 break_ok+1 埋点")
	# 失败: 红浮动 + (自动) 标注 (练气第2层 cost=20, essence=20 刚好够, 注入失败)
	g.essence = 20.0
	g._try_auto_break(0.999)
	fl.text = "SENTINEL_67"
	ui._float_break()
	check(str(fl.text) == g.break_fail_float_text() + " (自动)", "打磨-67 失败浮动=接口+ (自动) 标注 (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(1.0, 0.45, 0.4), "打磨-67 失败浮动 红色")
	# 关闭 开关: 浮动 无 标注 (手动 口径 不变; 重置 练气第1层 cost=10)
	g.auto_break = false
	g.last_break_result = 0
	g.layer = 1
	g.essence = 10.0
	g.try_breakthrough(0.01)
	check(g.last_break_result == 1, "打磨-67 关闭时 手动成功 事件=1 (实际 %d)" % g.last_break_result)
	fl.text = "SENTINEL_67"
	ui._float_break()
	check(str(fl.text) == g.break_ok_float_text() and str(fl.text).find("(自动)") < 0,
		"打磨-67 关闭时 浮动 无 (自动) 标注 (实际 %s)" % str(fl.text))
	# 开关不消耗资源/不计突破统计 (开关动作 本身 无 事件)
	g.essence = 3.0
	var seq_ab: int = g.break_seq
	var stats_ab2: Dictionary = g.stats.duplicate(true)
	ui._on_auto_break()
	ui._on_auto_break()
	check(g.auto_break == false and g.break_seq == seq_ab and g.stats == stats_ab2,
		"打磨-67 开关切换 无 资源/事件/统计 副作用")
	# 收尾: 恢复基准态 (防污染)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	g.auto_break = false
	ui._refresh()
	await get_tree().process_frame


# 打磨-68: 自动购置 — 开关按钮存在/tooltip/点击切换/开关态同步/灵石不足不触发/灵石够触发变更
# _refresh 出底部消息 (无屏幕浮动)/幂等0变更不再刷/开关切换无资源统计副作用; 收尾恢复基准态
func _assert_auto_buy() -> void:
	var g := GameData
	var btn: Button = ui._auto_buy_btn
	check(btn != null, "打磨-68 自动购置开关按钮存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-68 开关按钮 toggle_mode")
	check(btn.tooltip_text.find("自动购买") >= 0 and btn.tooltip_text.find("存档") >= 0,
		"打磨-68 tooltip 含 自动购买/存档 口径 (实际 %s)" % btn.tooltip_text)
	check(btn.tooltip_text.find("无屏幕浮动") >= 0, "打磨-68 tooltip 含 无屏幕浮动 口径")
	check(g.auto_buy == false and not btn.button_pressed and str(btn.text) == "自动购置: 关",
		"打磨-68 初始 关 态 (文本/按压/存档值 一致)")
	# 点击切换: 开 (底部消息 + 按钮态 + 存档值)
	ui._on_auto_buy()
	check(g.auto_buy == true, "打磨-68 点击后 auto_buy=true (实际 %s)" % str(g.auto_buy))
	check(btn.button_pressed and str(btn.text) == "自动购置: 开", "打磨-68 点击后 按钮按压+文本 开")
	check(str(ui._msg_label.text).find("自动购置已开启") >= 0, "打磨-68 开启 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 点击切换: 关
	ui._on_auto_buy()
	check(g.auto_buy == false and not btn.button_pressed and str(btn.text) == "自动购置: 关", "打磨-68 再点 关 态")
	check(str(ui._msg_label.text).find("自动购置已关闭") >= 0, "打磨-68 关闭 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 外部改存档值: _refresh 同步按钮态 (读档恢复 场景)
	g.auto_buy = true
	ui._refresh()
	check(btn.button_pressed and str(btn.text) == "自动购置: 开", "打磨-68 _refresh 同步 外部置 开 按钮态")
	# 灵石不足: _try_auto_buy 不购买 (最便宜 100 灵石, 当前 50)
	var owned0: int = g.owned.size()
	var eq0: int = g.owned_eq.size()
	var seq0: int = g._auto_buy_seq
	var stats0: Dictionary = g.stats.duplicate(true)
	g.stones = 50.0
	g._try_auto_buy()
	check(g.owned.size() == owned0 and g.owned_eq.size() == eq0 and g._auto_buy_seq == seq0,
		"打磨-68 灵石不足 不购买 (owned=%d eq=%d seq=%d)" % [g.owned.size(), g.owned_eq.size(), g._auto_buy_seq])
	check(g.stats == stats0, "打磨-68 灵石不足 无 统计 副作用")
	# 灵石够: 手动驱动 _try_auto_buy 触发 变更 (最便宜法器 木剑 100 + 装备 tier0), _refresh 出 底部消息
	g.stones = 700.0
	var msg_before: String = str(ui._msg_label.text)
	g._try_auto_buy()
	check(g._auto_buy_seq == seq0 + 1, "打磨-68 灵石够 触发 变更 事件 seq+1 (实际 %d)" % g._auto_buy_seq)
	check(g.owned.size() > owned0 or g.owned_eq.size() > eq0, "打磨-68 灵石够 有 购入 (owned=%d eq=%d)" % [g.owned.size(), g.owned_eq.size()])
	check(str(g.auto_buy_last_text()).find("自动购置") >= 0, "打磨-68 auto_buy_last_text 含 自动购置 (实际 %s)" % g.auto_buy_last_text())
	ui._refresh()
	check(str(ui._msg_label.text).find("自动购置") >= 0 and str(ui._msg_label.text) != msg_before,
		"打磨-68 _refresh 变更 后 底部消息 含 自动购置 (实际 %s)" % str(ui._msg_label.text))
	# 幂等: 再驱动一次 (买不起 下一件 + 已最佳) 0 变更, 底部消息 不再刷 (保持 上条 自动购置 文案)
	var msg_after: String = str(ui._msg_label.text)
	var seq1: int = g._auto_buy_seq
	g._try_auto_buy()
	check(g._auto_buy_seq == seq1, "打磨-68 幂等 0变更 不增 事件 (seq=%d)" % g._auto_buy_seq)
	ui._refresh()
	check(str(ui._msg_label.text) == msg_after, "打磨-68 幂等 后 底部消息 不变 (实际 %s)" % str(ui._msg_label.text))
	# 开关不消耗资源/不计 购买 统计 (开关动作 本身 无 副作用; 前置 置 关 保证 双击 后 仍 关)
	g.auto_buy = false
	g.stones = 3.0
	var seq_ab: int = g._auto_buy_seq
	var stats_ab: Dictionary = g.stats.duplicate(true)
	var owned_ab: int = g.owned.size()
	ui._on_auto_buy()
	ui._on_auto_buy()
	check(g.auto_buy == false and g._auto_buy_seq == seq_ab and g.stats == stats_ab and g.owned.size() == owned_ab,
		"打磨-68 开关切换 无 资源/事件/统计 副作用")
	# 收尾: 恢复基准态 (防污染)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	g.auto_buy = false
	g.auto_break = false
	ui._refresh()
	await get_tree().process_frame


# 打磨-69: 自动施展 — 开关按钮存在/tooltip/点击切换/开关态同步/0就绪不触发变更事件/
# 就绪触发变更+_refresh 弹绿色浮动(文案=接口+爆发总量+可见)/冷却中0变更不再刷/开关切换无副作用;
# 收尾恢复基准态 (含 自动系列 三开关 全 关)
func _assert_auto_cast() -> void:
	var g := GameData
	var btn: Button = ui._auto_cast_btn
	check(btn != null, "打磨-69 自动施展开关按钮存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-69 开关按钮 toggle_mode")
	check(btn.tooltip_text.find("自动 施展") >= 0 and btn.tooltip_text.find("存档") >= 0,
		"打磨-69 tooltip 含 自动施展/存档 口径 (实际 %s)" % btn.tooltip_text)
	check(btn.tooltip_text.find("绿色浮动") >= 0, "打磨-69 tooltip 含 绿色浮动 口径")
	check(g.auto_cast == false and not btn.button_pressed and str(btn.text) == "自动施展: 关",
		"打磨-69 初始 关 态 (文本/按压/存档值 一致)")
	# 点击切换: 开 (底部消息 + 按钮态 + 存档值)
	ui._on_auto_cast()
	check(g.auto_cast == true, "打磨-69 点击后 auto_cast=true (实际 %s)" % str(g.auto_cast))
	check(btn.button_pressed and str(btn.text) == "自动施展: 开", "打磨-69 点击后 按钮按压+文本 开")
	check(str(ui._msg_label.text).find("自动施展已开启") >= 0, "打磨-69 开启 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 点击切换: 关
	ui._on_auto_cast()
	check(g.auto_cast == false and not btn.button_pressed and str(btn.text) == "自动施展: 关", "打磨-69 再点 关 态")
	check(str(ui._msg_label.text).find("自动施展已关闭") >= 0, "打磨-69 关闭 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 外部改存档值: _refresh 同步按钮态 (读档恢复 场景)
	g.auto_cast = true
	ui._refresh()
	check(btn.button_pressed and str(btn.text) == "自动施展: 开", "打磨-69 _refresh 同步 外部置 开 按钮态")
	# 受控态: 2 个 境界0 主动神通 已学 (速率 1.0, 各 爆发 60, 冷却 90)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g._active_cd = {}
	g._auto_cast_seq = 0
	ui._auto_cast_msg_seq = 0
	ui._auto_cast_float_count = 0
	var act: Array = []
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id.get(str(id), {})
		if s.is_empty() or str(s.get("type", "")) != "active":
			continue
		if int(s.get("unlock_realm", 99)) == 0 and int(s.get("unlock_layer", 99)) == 1:
			act.append(str(id))
		if act.size() == 2:
			break
	check(act.size() == 2, "打磨-69 受控态 2 神通 数据存在 (实际 %d)" % act.size())
	g.learned.clear()
	for id in act:
		g.learned.append(str(id))
	var fl: Label = ui._auto_cast_float_label
	check(fl != null, "打磨-69 浮动 Label 节点存在")
	# 0 就绪 (全冷却中): _try_auto_cast 0 变更, _refresh 不弹浮动
	for id in act:
		g._active_cd[id] = 90.0
	var seq0: int = g._auto_cast_seq
	var stats0: Dictionary = g.stats.duplicate(true)
	g._try_auto_cast()
	check(g._auto_cast_seq == seq0 and g.stats == stats0, "打磨-69 0就绪 0变更 不增 事件/统计 (seq=%d)" % g._auto_cast_seq)
	ui._refresh()
	check(ui._auto_cast_float_count == 0 and str(fl.text) == "", "打磨-69 0变更 不弹 浮动 (count=%d)" % ui._auto_cast_float_count)
	# 就绪: 手动驱动 _try_auto_cast (2 神通 爆发 120 灵气) + _refresh 弹 绿色浮动 (文案=接口)
	g._active_cd = {}
	g._try_auto_cast()
	check(g._auto_cast_seq == seq0 + 1, "打磨-69 就绪 触发 变更 事件 seq+1 (实际 %d)" % g._auto_cast_seq)
	check(str(g.auto_cast_last_text()) == "自动施展 2 个神通 (爆发+120 灵气)",
		"打磨-69 auto_cast_last_text 数量+爆发 (实际 %s)" % g.auto_cast_last_text())
	check(absf(g.essence - 120.0) < 1e-6, "打磨-69 2 神通 爆发 120 灵气 (实际 %s)" % g.fmt(g.essence))
	fl.text = "SENTINEL_69"
	ui._refresh()
	check(ui._auto_cast_float_count == 1, "打磨-69 _refresh 弹浮动 计数+1 (实际 %d)" % ui._auto_cast_float_count)
	check(str(fl.text) == "✦ 自动施展 2 个神通 (爆发+120 灵气) ✦",
		"打磨-69 浮动文案=接口 (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(0.5, 0.9, 0.5), "打磨-69 浮动 绿色")
	check(fl.visible, "打磨-69 浮动 可见")
	# 幂等: 冷却中 0 变更, _refresh 不再刷 (保持 上条 浮动 文案)
	var fl_text: String = str(fl.text)
	var seq1: int = g._auto_cast_seq
	g._try_auto_cast()
	check(g._auto_cast_seq == seq1, "打磨-69 冷却中 0变更 不增 事件 (seq=%d)" % g._auto_cast_seq)
	ui._refresh()
	check(ui._auto_cast_float_count == 1 and str(fl.text) == fl_text, "打磨-69 幂等 后 浮动 不变 (实际 %s)" % str(fl.text))
	# 开关不消耗资源/不计 施展 统计 (开关动作 本身 无 副作用; 前置 置 关 保证 双击 后 仍 关)
	g.auto_cast = false
	var seq_sw: int = g._auto_cast_seq
	var stats_sw: Dictionary = g.stats.duplicate(true)
	var ess_sw: float = g.essence
	ui._on_auto_cast()
	ui._on_auto_cast()
	check(g.auto_cast == false and g._auto_cast_seq == seq_sw and g.stats == stats_sw and absf(g.essence - ess_sw) < 1e-9,
		"打磨-69 开关切换 无 资源/事件/统计 副作用")
	# 收尾: 恢复基准态 (防污染) + 自动系列 三开关 全 关
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	g.auto_buy = false
	g.auto_break = false
	g.auto_cast = false
	g._active_cd = {}
	g.ready_events.clear()
	ui._refresh()
	await get_tree().process_frame


# 打磨-80: 自动领悟 — 自动领悟开关按钮 (境界/层 提升 解锁 新技能 自动 批量 领悟)/
# tooltip 口径/初始 关 态/点击 开 (底部消息+按钮态)/再点 关/外部改 _refresh 同步/
# 受控态 手动驱动 _try_auto_learn (学习 可学数+seq+文案)/_refresh 出 底部消息/
# 幂等 0 变更 不再刷/开关切换 无 资源/事件/统计 副作用/收尾 基准 恢复
func _assert_auto_learn() -> void:
	var g := GameData
	var btn: Button = ui._auto_learn_btn
	check(btn != null, "打磨-80 自动领悟开关按钮存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-80 开关按钮 toggle_mode")
	check(btn.tooltip_text.find("自动 批量 领悟") >= 0 and btn.tooltip_text.find("存档") >= 0,
		"打磨-80 tooltip 含 自动领悟/存档 口径 (实际 %s)" % btn.tooltip_text)
	check(btn.tooltip_text.find("免费") >= 0, "打磨-80 tooltip 含 免费 无 消耗 口径")
	check(g.auto_learn == false and not btn.button_pressed and str(btn.text) == "自动领悟: 关",
		"打磨-80 初始 关 态 (文本/按压/存档值 一致)")
	# 点击切换: 开 (底部消息 + 按钮态 + 存档值)
	ui._on_auto_learn()
	check(g.auto_learn == true, "打磨-80 点击后 auto_learn=true (实际 %s)" % str(g.auto_learn))
	check(btn.button_pressed and str(btn.text) == "自动领悟: 开", "打磨-80 点击后 按钮按压+文本 开")
	check(str(ui._msg_label.text).find("自动领悟已开启") >= 0, "打磨-80 开启 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 点击切换: 关
	ui._on_auto_learn()
	check(g.auto_learn == false and not btn.button_pressed and str(btn.text) == "自动领悟: 关", "打磨-80 再点 关 态")
	check(str(ui._msg_label.text).find("自动领悟已关闭") >= 0, "打磨-80 关闭 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 外部改存档值: _refresh 同步按钮态 (读档恢复 场景)
	g.auto_learn = true
	ui._refresh()
	check(btn.button_pressed and str(btn.text) == "自动领悟: 开", "打磨-80 _refresh 同步 外部置 开 按钮态")
	# 受控态: 境界0 层1 空已学 (可学 11 个, 数据 固定 种子); 冻结 自动领悟 事件 手动驱动
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g._active_cd = {}
	g._auto_learn_seq = 0
	ui._auto_learn_msg_seq = 0
	# 可学 数 按 数据 动态 计算 (境界0 层1)
	var n_learn80: int = 0
	for sid in g.skill_ids:
		var s: Dictionary = g.skill_by_id.get(str(sid), {})
		if s.is_empty():
			continue
		if (int(s.get("unlock_realm", 99)) < 0) or (int(s.get("unlock_realm", 99)) == 0 and int(s.get("unlock_layer", 99)) <= 1):
			n_learn80 += 1
	check(n_learn80 == 11, "打磨-80 受控态 可学数=11 (境界0 层1, 实际 %d)" % n_learn80)
	# 0 变更 初始 (未 驱动 _try): _refresh 不刷 底部消息
	var msg_before: String = str(ui._msg_label.text)
	ui._refresh()
	check(g._auto_learn_seq == 0, "打磨-80 初始 _try 未驱动 seq=0")
	# 手动驱动 _try_auto_learn (学习 11 个) + _refresh 出 底部消息 (文案=接口)
	g._try_auto_learn()
	check(g.learned.size() == n_learn80, "打磨-80 学习 可学数 11 (实际 %d)" % g.learned.size())
	check(g._auto_learn_seq == 1, "打磨-80 触发 变更 事件 seq+1 (实际 %d)" % g._auto_learn_seq)
	check(str(g.auto_learn_last_text()) == "自动领悟 %d 个技能" % n_learn80,
		"打磨-80 auto_learn_last_text 数量 (实际 %s)" % g.auto_learn_last_text())
	ui._refresh()
	check(str(ui._msg_label.text).find("自动领悟 %d 个技能" % n_learn80) >= 0,
		"打磨-80 _refresh 出 底部消息 (实际 %s)" % str(ui._msg_label.text))
	check(ui._auto_learn_msg_seq == 1, "打磨-80 _refresh 消费 事件 seq 同步 (实际 %d)" % ui._auto_learn_msg_seq)
	# 幂等: 学完 0 变更, _refresh 不再 刷 底部消息 (保持 上条 文案)
	var seq_idem: int = g._auto_learn_seq
	var msg_idem: String = str(ui._msg_label.text)
	g._try_auto_learn()
	check(g._auto_learn_seq == seq_idem, "打磨-80 学完 再试 0 变更 不增 事件 (seq=%d)" % g._auto_learn_seq)
	ui._refresh()
	check(str(ui._msg_label.text) == msg_idem, "打磨-80 幂等 后 底部消息 不变 (实际 %s)" % str(ui._msg_label.text))
	# 升层: 境界0 层2 解锁 5 个 新技能, 自动 领悟 (变更 事件+文案 更新)
	g.layer = 2
	g._try_auto_learn()
	check(g.learned.size() == n_learn80 + 5, "打磨-80 升层 后 新增 5 (实际 %d)" % g.learned.size())
	check(g._auto_learn_seq == 2, "打磨-80 升层 触发 变更 事件 seq=2 (实际 %d)" % g._auto_learn_seq)
	check(str(g.auto_learn_last_text()) == "自动领悟 5 个技能",
		"打磨-80 升层 后 文案 更新 (实际 %s)" % g.auto_learn_last_text())
	ui._refresh()
	check(str(ui._msg_label.text).find("自动领悟 5 个技能") >= 0, "打磨-80 升层 _refresh 出新 文案 (实际 %s)" % str(ui._msg_label.text))
	# 开关切换 无 资源/事件/统计 副作用 (开关动作 本身 无 学习 副作用)
	var stats_sw: Dictionary = g.stats.duplicate(true)
	var ess_sw: float = g.essence
	var stones_sw: float = g.stones
	ui._on_auto_learn()
	check(g.auto_learn == false and str(btn.text) == "自动领悟: 关", "打磨-80 开关切换 关 态")
	check(g.stats == stats_sw and absf(g.essence - ess_sw) < 1e-9 and g.stones == stones_sw,
		"打磨-80 开关切换 无 资源/统计 副作用")
	# 收尾: 恢复基准态 (防污染) + 自动系列 四开关 全 关
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	g.auto_buy = false
	g.auto_break = false
	g.auto_cast = false
	g.auto_learn = false
	g._active_cd = {}
	g.ready_events.clear()
	ui._refresh()
	await get_tree().process_frame


# 打磨-70: 自动系列 状态汇总 — 汇总行存在 (前缀+4 段标签, 打磨-80 起 4 开关)/tooltip 口径/
# 四关 初始 全灰 ✗/开关切换 (按钮点击+外部置) 后 _refresh 同步 文本/颜色 (开=金 关=灰)/
# 节流 (键不变不重刷)/无 存档/统计 副作用; 收尾 四开关 全 关 + 汇总 恢复 四关 态
func _assert_auto_summary() -> void:
	var g := GameData
	var box: HBoxContainer = ui._auto_sum_box
	check(box != null, "打磨-70 自动系列 汇总行 节点存在")
	if box == null:
		return
	check(ui._auto_sum_prefix != null and str(ui._auto_sum_prefix.text) == "自动:",
		"打磨-70 前缀标签 文本=自动: (实际 %s)" % str(ui._auto_sum_prefix.text))
	check(ui._auto_sum_segs.size() == 4, "打磨-70 4 个 状态段标签 (打磨-80) (实际 %d)" % ui._auto_sum_segs.size())
	# 打磨-74: tooltip 由 汇总行 HBox 上移到 外壳 Panel (金边高亮 载体)
	var panel70: Panel = ui._auto_sum_panel
	check(panel70 != null, "打磨-70 汇总行 外壳 Panel 存在 (打磨-74 高亮载体)")
	check(panel70.tooltip_text.find("自动突破") >= 0 and panel70.tooltip_text.find("自动购置") >= 0
			and panel70.tooltip_text.find("自动施展") >= 0 and panel70.tooltip_text.find("自动领悟") >= 0
			and panel70.tooltip_text.find("离线期间不触发") >= 0,
		"打磨-70 汇总行 tooltip 含 四开关 口径 (实际 %s)" % panel70.tooltip_text)
	# 初始态: 四关 (打磨-69 收尾 已 全 关 + _refresh)
	ui._refresh()
	check(ui._auto_sum_key == "0|0|0|0", "打磨-70 初始 状态键 0|0|0|0 (实际 %s)" % ui._auto_sum_key)
	var seg0: Label = ui._auto_sum_segs[0]
	var seg1: Label = ui._auto_sum_segs[1]
	var seg2: Label = ui._auto_sum_segs[2]
	var seg3: Label = ui._auto_sum_segs[3]
	check(str(seg0.text) == "突破 ✗" and str(seg1.text) == "购置 ✗" and str(seg2.text) == "施展 ✗"
			and str(seg3.text) == "领悟 ✗",
		"打磨-70 四关 段文本 全 ✗ (实际 %s/%s/%s/%s)" % [str(seg0.text), str(seg1.text), str(seg2.text), str(seg3.text)])
	check(seg0.get_theme_color("font_color") == ui.DIM and seg1.get_theme_color("font_color") == ui.DIM
			and seg2.get_theme_color("font_color") == ui.DIM and seg3.get_theme_color("font_color") == ui.DIM,
		"打磨-70 四关 段颜色 全灰")
	# 点击 自动突破 开关 → _refresh 同步 (突破 段 转金 ✓)
	ui._on_auto_break()
	ui._refresh()
	check(g.auto_break == true, "打磨-70 点击后 auto_break=true (实际 %s)" % str(g.auto_break))
	check(ui._auto_sum_key == "1|0|0|0", "打磨-70 键 1|0|0|0 (实际 %s)" % ui._auto_sum_key)
	check(str(seg0.text) == "突破 ✓" and seg0.get_theme_color("font_color") == ui.GOLD,
		"打磨-70 突破 段 金 ✓ (实际 %s)" % str(seg0.text))
	check(str(seg1.text) == "购置 ✗" and seg1.get_theme_color("font_color") == ui.DIM,
		"打磨-70 购置 段 保持 灰 ✗")
	# 外部置 购置 开 (读档恢复 场景): _refresh 同步 (键变化 才刷, 仅 购置 段 变色)
	g.auto_buy = true
	var key_before: String = ui._auto_sum_key
	ui._refresh()
	check(ui._auto_sum_key == "1|1|0|0" and key_before == "1|0|0|0", "打磨-70 外部置 购置 键 1|1|0|0 (实际 %s)" % ui._auto_sum_key)
	check(str(seg1.text) == "购置 ✓" and seg1.get_theme_color("font_color") == ui.GOLD,
		"打磨-70 购置 段 金 ✓ (实际 %s)" % str(seg1.text))
	check(str(seg0.text) == "突破 ✓" and seg0.get_theme_color("font_color") == ui.GOLD, "打磨-70 突破 段 保持 金")
	# 节流: 状态键 未变 时 _refresh 不重刷 (缓存键 保持, 段文本/颜色 稳定)
	ui._refresh()
	check(ui._auto_sum_key == "1|1|0|0" and str(seg1.text) == "购置 ✓", "打磨-70 键不变 节流 不重刷")
	# 点击 自动施展 开关 → 三开 (施展 段 转金)
	ui._on_auto_cast()
	ui._refresh()
	check(ui._auto_sum_key == "1|1|1|0" and str(seg2.text) == "施展 ✓"
			and seg2.get_theme_color("font_color") == ui.GOLD, "打磨-70 三开 施展 段 金 ✓ (实际 %s)" % ui._auto_sum_key)
	# 外部置 领悟 开 → 四开 (领悟 段 转金, 打磨-80)
	g.auto_learn = true
	ui._refresh()
	check(ui._auto_sum_key == "1|1|1|1" and str(seg3.text) == "领悟 ✓"
			and seg3.get_theme_color("font_color") == ui.GOLD, "打磨-70 四开 领悟 段 金 ✓ (实际 %s)" % ui._auto_sum_key)
	# 开关切换 无 存档/统计 副作用 (汇总行 纯展示)
	var stats_sum: Dictionary = g.stats.duplicate(true)
	var stones_sum: float = g.stones
	var seq_sum: int = g._auto_cast_seq
	ui._on_auto_buy()
	ui._refresh()
	check(g.auto_buy == false and ui._auto_sum_key == "1|0|1|1"
			and g.stats == stats_sum and g.stones == stones_sum and g._auto_cast_seq == seq_sum,
		"打磨-70 开关切换 无 统计/资源/事件 副作用 (键=%s)" % ui._auto_sum_key)
	# 收尾: 四开关 全 关, 汇总 恢复 四关 态 (防污染)
	ui._on_auto_break()
	ui._on_auto_cast()
	ui._on_auto_learn()
	ui._refresh()
	check(g.auto_break == false and g.auto_buy == false and g.auto_cast == false and g.auto_learn == false
			and ui._auto_sum_key == "0|0|0|0"
			and str(seg0.text) == "突破 ✗" and str(seg1.text) == "购置 ✗" and str(seg2.text) == "施展 ✗"
			and str(seg3.text) == "领悟 ✗",
		"打磨-70 收尾 四关 汇总 恢复 全 ✗")
	await get_tree().process_frame


# 打磨-71: 自动系列 汇总行 点击直达 — 4 段热区 flat Button (手型光标+悬停金边, 打磨-80 起 4 段)/
# tooltip 口径/点击=切 对应 自动开关 (与上方按钮 同 口径: 状态+上方按钮按压态+底部消息确认)/
# 再点=关闭/节流 (键不变不重刷)/无 资源/统计 副作用; 收尾 四开关 全 关 恢复 0|0|0|0
func _assert_auto_sum_jump() -> void:
	var g := GameData
	var btns: Array = ui._auto_sum_btns
	check(btns.size() == 4, "打磨-71 4 个 段热区 按钮 (打磨-80) (实际 %d)" % btns.size())
	if btns.size() < 4:
		return
	for i in 4:
		var b: Button = btns[i]
		check(b.flat == true and b.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
			"打磨-71 段%d 热区 flat+手型光标 (flat=%s cursor=%d)" % [i, str(b.flat), b.mouse_default_cursor_shape])
	check(str(btns[0].tooltip_text).find("点击切换 自动突破") >= 0
			and str(btns[1].tooltip_text).find("点击切换 自动购置") >= 0
			and str(btns[2].tooltip_text).find("点击切换 自动施展") >= 0
			and str(btns[3].tooltip_text).find("点击切换 自动领悟") >= 0,
		"打磨-71 段热区 tooltip 含 点击切换 口径 (突破/购置/施展/领悟)")
	check(str(ui._auto_sum_panel.tooltip_text).find("各段可点击") >= 0,
			"打磨-71 汇总行 tooltip 含 各段可点击 说明 (打磨-74 起 tooltip 挂在外壳 Panel)")
	# 初始 四关 (打磨-70 收尾 全 关)
	ui._refresh()
	check(ui._auto_sum_key == "0|0|0|0", "打磨-71 初始 状态键 0|0|0|0 (实际 %s)" % ui._auto_sum_key)
	# 点击 突破 段 → 自动突破 开 (与上方按钮 同 口径: 状态+按压态+底部消息)
	var stats0: Dictionary = g.stats.duplicate(true)
	var stones0: float = g.stones
	btns[0].pressed.emit()
	ui._refresh()
	check(g.auto_break == true and ui._auto_break_btn.is_pressed() == true,
		"打磨-71 点击 突破 段 auto_break=true+上方按钮 按压态")
	check(ui._auto_sum_key == "1|0|0|0", "打磨-71 点击后 键 1|0|0|0 (实际 %s)" % ui._auto_sum_key)
	check(str(ui._msg_label.text).find("自动突破已开启") >= 0,
		"打磨-71 点击 突破 段 底部消息 确认 (实际 %s)" % str(ui._msg_label.text))
	# 点击 购置 段 → 自动购置 开
	btns[1].pressed.emit()
	ui._refresh()
	check(g.auto_buy == true and ui._auto_buy_btn.is_pressed() == true
			and ui._auto_sum_key == "1|1|0|0", "打磨-71 点击 购置 段 auto_buy=true 键 1|1|0|0 (实际 %s)" % ui._auto_sum_key)
	check(str(ui._msg_label.text).find("自动购置已开启") >= 0, "打磨-71 点击 购置 段 底部消息 确认")
	# 点击 施展 段 → 三开
	btns[2].pressed.emit()
	ui._refresh()
	check(g.auto_cast == true and ui._auto_cast_btn.is_pressed() == true and ui._auto_sum_key == "1|1|1|0",
		"打磨-71 点击 施展 段 三开 键 1|1|1|0 (实际 %s)" % ui._auto_sum_key)
	# 点击 领悟 段 → 四开 (打磨-80)
	btns[3].pressed.emit()
	ui._refresh()
	check(g.auto_learn == true and ui._auto_learn_btn.is_pressed() == true and ui._auto_sum_key == "1|1|1|1",
		"打磨-71 点击 领悟 段 四开 键 1|1|1|1 (实际 %s)" % ui._auto_sum_key)
	check(str(ui._msg_label.text).find("自动领悟已开启") >= 0, "打磨-71 点击 领悟 段 底部消息 确认")
	# 再点 突破 段 → 关闭 (与上方按钮 再点 同 口径)
	btns[0].pressed.emit()
	ui._refresh()
	check(g.auto_break == false and ui._auto_break_btn.is_pressed() == false and ui._auto_sum_key == "0|1|1|1",
		"打磨-71 再点 突破 段 auto_break=false 键 0|1|1|1")
	check(str(ui._msg_label.text).find("自动突破已关闭") >= 0, "打磨-71 关闭 底部消息 确认")
	# 点击切换 无 资源/统计 副作用
	check(g.stats == stats0 and g.stones == stones0,
		"打磨-71 点击切换 无 统计/资源 副作用")
	# 节流: 键 未变 _refresh 不重刷 (段文本/颜色 稳定)
	var seg0: Label = ui._auto_sum_segs[0]
	var t_before: String = str(seg0.text)
	ui._refresh()
	check(ui._auto_sum_key == "0|1|1|1" and str(seg0.text) == t_before, "打磨-71 键不变 节流 不重刷")
	# 收尾: 四开关 全 关 恢复 (防污染)
	btns[1].pressed.emit()
	btns[2].pressed.emit()
	btns[3].pressed.emit()
	ui._refresh()
	check(g.auto_break == false and g.auto_buy == false and g.auto_cast == false and g.auto_learn == false
			and ui._auto_sum_key == "0|0|0|0", "打磨-71 收尾 四关 恢复 0|0|0|0 (实际 %s)" % ui._auto_sum_key)
	await get_tree().process_frame


# 打磨-72: 启动 自动系列 恢复 提示 — _ready 时 任一 自动 开关 为 开 则 底部 消息
# "已恢复 自动: …" (文案=GameData.auto_restore_text, 全关 空串 不提示, 离线 消息 优先 让位).
# "仅 启动 一次" 由 _ready 只调 一次 _show_auto_restore_msg 保证 (函数 本身 无 启动 门控,
# 手动驱动 重放 会 再显示, 与 _show_msg/_offline_float 同 口径 可 重放).
# 断言 (手动驱动 确定性, 不依赖 启动 时 真实 档态, 防 flake): _ready 三关 不提示 计数 0/
# 单开+组合 底部消息 文案=接口+计数+1/离线消息 优先 让位/全关 不提示 计数不变/
# 无 资源/统计 副作用/收尾 三关 恢复 计数 不变
func _assert_auto_restore() -> void:
	var g := GameData
	# _ready 时 三开关 全关 (ui_test _ready 防御性 重置 + 打磨-71 收尾), 启动 未 触发 提示
	check(ui._auto_restore_count == 0, "打磨-72 启动 三关 未 触发 提示 (实际 %d)" % ui._auto_restore_count)
	check(str(ui._auto_restore_last_text) == "", "打磨-72 启动 三关 无 文案 (实际 %s)" % str(ui._auto_restore_last_text))
	# 手动驱动: 单开 购置 -> 底部 消息 文案=接口 + 计数+1 (文案 由 GameData 接口 提供)
	g.auto_buy = true
	var exp72: String = g.auto_restore_text()
	check(exp72 == "已恢复 自动: 购置", "打磨-72 接口 文案(仅购置) (实际 %s)" % exp72)
	var stats72: Dictionary = g.stats.duplicate(true)
	var stones72: float = g.stones
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 1, "打磨-72 单开 提示 计数+1 (实际 %d)" % ui._auto_restore_count)
	check(str(ui._auto_restore_last_text) == exp72, "打磨-72 单开 文案=接口 (实际 %s)" % str(ui._auto_restore_last_text))
	check(str(ui._msg_label.text) == exp72, "打磨-72 单开 底部消息=文案 (实际 %s)" % str(ui._msg_label.text))
	# 单开 领悟 -> 文案 固定序 含 领悟 (打磨-80)
	g.auto_buy = false
	g.auto_learn = true
	exp72 = g.auto_restore_text()
	check(exp72 == "已恢复 自动: 领悟", "打磨-72 接口 文案(仅领悟, 打磨-80) (实际 %s)" % exp72)
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 2 and str(ui._auto_restore_last_text) == exp72
			and str(ui._msg_label.text) == exp72, "打磨-72 单开 领悟 文案=接口 计数+1 (实际 %s / %d)" % [str(ui._msg_label.text), ui._auto_restore_count])
	# 组合 开 (购置+施展) -> 文案 固定序 购置·施展
	g.auto_learn = false
	g.auto_buy = true
	g.auto_cast = true
	exp72 = g.auto_restore_text()
	check(exp72 == "已恢复 自动: 购置·施展", "打磨-72 接口 文案(购置+施展) (实际 %s)" % exp72)
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 3 and str(ui._auto_restore_last_text) == exp72
			and str(ui._msg_label.text) == exp72, "打磨-72 组合 文案=接口 计数+1 (实际 %s / %d)" % [str(ui._msg_label.text), ui._auto_restore_count])
	# 离线 消息 优先: offline_msg 非空 时 本 提示 让位 (早期 返回 不 _show_msg, 不覆盖 已有 文案, 计数 不变)
	g.offline_msg = "离线 8小时, 收获 灵气 999, 灵石 888"
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 3 and str(ui._msg_label.text) == "已恢复 自动: 购置·施展",
			"打磨-72 离线消息 优先 让位 (计数不变, 不 覆盖 已有 底部 消息)")
	g.offline_msg = ""
	# 提示 触发 无 资源/统计 副作用 (纯 展示)
	check(g.stats == stats72 and g.stones == stones72, "打磨-72 提示 无 资源/统计 副作用")
	# 全关 不提示 计数不变 (auto_restore_text 空串)
	g.auto_buy = false
	g.auto_cast = false
	g.auto_learn = false
	check(g.auto_restore_text() == "", "打磨-72 全关 接口 空串")
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 3, "打磨-72 全关 不提示 计数不变 (实际 %d)" % ui._auto_restore_count)
	# 收尾: 四开关 全 关 (防 污染), 恢复 干净 基准 (offline_msg 已 复位 空)
	g.auto_break = false
	g.auto_buy = false
	g.auto_cast = false
	g.auto_learn = false
	ui._refresh()
	check(ui._auto_restore_count == 3 and str(ui._auto_restore_last_text) == "已恢复 自动: 购置·施展",
			"打磨-72 收尾 四关 恢复 计数/文案 稳定 (实际 %d / %s)" % [ui._auto_restore_count, str(ui._auto_restore_last_text)])
	await get_tree().process_frame


# 打磨-73: 顶栏 自动系列 状态徽标 — 顶栏 最右 金色 "自动 N/4" 徽标 (任一开关开 显示, 全关 隐藏;
# tooltip 复用 auto_summary_text 四开关 口径 (打磨-80 起 4 开关) + 离线不触发 说明; 开启数 变化才刷, 无 存档/统计 副作用)
# 断言 (手动驱动 确定性): 徽标节点 顶栏子节点+金色样式/全关 隐藏 文本空/单开 "自动 1/4"+可见+
# tooltip 含 四开关 状态行/两开 "自动 2/4"/三开 "自动 3/4"/四开 "自动 4/4"/同态 再 _refresh 文本 不变 节流/
# 全关 恢复 隐藏 文本空 tooltip 清/无 资源/统计 副作用/收尾 四关 隐藏
func _assert_auto_badge() -> void:
	var g := GameData
	# 徽标 节点: 顶栏子节点 (境界/主资源/灵石 之后), 金色字 + 金边样式
	check(ui._auto_badge != null, "打磨-73 顶栏 自动 徽标 节点 存在")
	check(ui._auto_badge.get_parent() == ui._realm_label.get_parent(),
		"打磨-73 徽标 挂在 顶栏 容器 (与 境界标签 同父; 实际父节点 %s)" % str(ui._auto_badge.get_parent()))
	check(ui._auto_badge.get_theme_color("font_color") == Color(0.98, 0.86, 0.5),
		"打磨-73 徽标 字色 金色 (实际 %s)" % str(ui._auto_badge.get_theme_color("font_color")))
	# 初始 (打磨-72 收尾 三关 全 关): 隐藏, 文本 空
	check(ui._auto_badge.visible == false, "打磨-73 初始 三关 徽标 隐藏 (实际 visible=%s)" % str(ui._auto_badge.visible))
	check(str(ui._auto_badge.text) == "", "打磨-73 初始 三关 徽标 文本 空 (实际 %s)" % str(ui._auto_badge.text))
	# 单开 突破 -> "自动 1/4" 可见 + tooltip 复用 auto_summary_text 四开关 口径
	g.auto_break = true
	ui._refresh()
	check(ui._auto_badge.visible == true, "打磨-73 单开 突破 徽标 显示 (实际 visible=%s)" % str(ui._auto_badge.visible))
	check(str(ui._auto_badge.text) == "自动 1/4", "打磨-73 单开 文案=自动 1/4 (实际 %s)" % str(ui._auto_badge.text))
	var tip73: String = str(ui._auto_badge.tooltip_text)
	check(tip73.begins_with("自动: 突破 ✓ · 购置 ✗ · 施展 ✗ · 领悟 ✗") and tip73.contains("离线期间不触发"),
		"打磨-73 单开 tooltip 复用 auto_summary_text+离线口径 (实际 %s)" % tip73)
	# 两开 (突破+施展) -> "自动 2/4" (购置 关 口径 与 汇总行 同)
	g.auto_cast = true
	ui._refresh()
	check(str(ui._auto_badge.text) == "自动 2/4", "打磨-73 两开 文案=自动 2/4 (实际 %s)" % str(ui._auto_badge.text))
	check(str(ui._auto_badge.tooltip_text).begins_with("自动: 突破 ✓ · 购置 ✗ · 施展 ✓ · 领悟 ✗"),
		"打磨-73 两开 tooltip 四开关 口径 (实际 %s)" % str(ui._auto_badge.tooltip_text))
	# 三开 -> "自动 3/4"
	g.auto_buy = true
	ui._refresh()
	check(str(ui._auto_badge.text) == "自动 3/4", "打磨-73 三开 文案=自动 3/4 (实际 %s)" % str(ui._auto_badge.text))
	# 四开 -> "自动 4/4" (打磨-80)
	g.auto_learn = true
	ui._refresh()
	check(str(ui._auto_badge.text) == "自动 4/4", "打磨-73 四开 文案=自动 4/4 (实际 %s)" % str(ui._auto_badge.text))
	check(str(ui._auto_badge.tooltip_text).begins_with("自动: 突破 ✓ · 购置 ✓ · 施展 ✓ · 领悟 ✓"),
		"打磨-73 四开 tooltip 全开 口径 (实际 %s)" % str(ui._auto_badge.tooltip_text))
	# 节流: 同态 再 _refresh, 文本/可见 不变 (开启数 未变 不重写)
	var txt73: String = str(ui._auto_badge.text)
	var st73: Dictionary = g.stats.duplicate(true)
	var stones73: float = g.stones
	ui._refresh()
	check(str(ui._auto_badge.text) == txt73 and ui._auto_badge.visible == true,
		"打磨-73 同态 节流 文本/可见 稳定")
	# 全关 恢复 隐藏 + 文本空 + tooltip 清
	g.auto_break = false
	g.auto_buy = false
	g.auto_cast = false
	g.auto_learn = false
	ui._refresh()
	check(ui._auto_badge.visible == false and str(ui._auto_badge.text) == ""
			and str(ui._auto_badge.tooltip_text) == "", "打磨-73 全关 恢复 隐藏/文本空/tooltip 清")
	# 徽标 刷新 无 资源/统计 副作用 (纯展示)
	check(g.stats == st73 and g.stones == stones73, "打磨-73 徽标 刷新 无 资源/统计 副作用")
	# 收尾: 四关 全 关 隐藏 稳定 (防 污染)
	check(ui._auto_badge.visible == false, "打磨-73 收尾 四关 隐藏")
	await get_tree().process_frame


# 打磨-74: 顶栏 自动 徽标 点击直达 — 徽标 升级 flat Button 热区 (手型光标+悬停 淡底 金边),
# 点击=切 修行页 + 自动系列 汇总行 金边高亮 1.2s (复用 法器区 高亮 口径), 全关 隐藏 无热区 口径 不变;
# 断言 (手动驱动 确定性): 徽标=flat Button+手型/悬停样式非空/汇总行 Panel 外壳 存在+初始无边框/
# tooltip 点击口径/单开 点击 → 切 修行页(tab0)+汇总行 金边+底部消息/汇总行 tooltip 徽标直达口径/
# 1.2s 后 高亮 自动恢复 边框0/重入 kill 旧 tween 不叠加/全关 隐藏 无热区 (visible=false 时 点击 不触发)/
# 无 资源/统计 副作用 (纯导航)/收尾 修行页+无边框
func _assert_auto_badge_jump() -> void:
	var g := GameData
	# 前置: 打磨-73 收尾 三关 全 关 (徽标 隐藏); 切 成就页 作为 点击 前 受控 tab
	ui._tab.current_tab = 3
	# 徽标 = flat Button 可点击热区 (手型光标, 非 toggle)
	var badge: Button = ui._auto_badge
	check(badge is Button, "打磨-74 徽标 节点 是 Button (升级 可点击)")
	check(badge.flat == true, "打磨-74 徽标 flat (可点样式)")
	check(badge.toggle_mode == false, "打磨-74 徽标 非 toggle (点击即触发)")
	check(badge.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
			"打磨-74 徽标 手型光标 提示可点")
	check(badge.get_theme_stylebox("hover") != null
			and badge.get_theme_stylebox("hover").border_width_left == 1,
			"打磨-74 徽标 悬停 金边 样式 非空 (hover 边框宽=1)")
	# 汇总行 Panel 外壳 存在 + 初始 无边框 (恢复态)
	check(ui._auto_sum_panel != null and ui._auto_sum_panel is Panel, "打磨-74 汇总行 Panel 外壳 存在")
	check(ui._auto_sum_box.get_parent() == ui._auto_sum_panel, "打磨-74 汇总行 HBox 挂在 Panel 下")
	var sb0: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb0 != null and sb0.border_width_left == 0, "打磨-74 初始 汇总行 无边框 (边框宽=0)")
	check(str(ui._auto_sum_panel.tooltip_text).find("顶栏 自动 N/4 徽标 点击也可直达本行") >= 0,
			"打磨-74 汇总行 tooltip 含 徽标直达 口径 (实际 %s)" % str(ui._auto_sum_panel.tooltip_text).left(60))
	# 副作用快照 (点击 不应改变)
	var snap_essence := g.essence
	var snap_stones := g.stones
	var snap_stats := g.stats
	# --- 单开 突破 → 徽标 显示 "自动 1/4" → 点击 → 切 修行页(tab0) + 汇总行 金边 ---
	g.auto_break = true
	ui._refresh()
	check(ui._auto_badge.visible == true and str(ui._auto_badge.text) == "自动 1/4",
			"打磨-74 单开 突破 徽标 显示 (实际 visible=%s 文本=%s)" % [str(ui._auto_badge.visible), str(ui._auto_badge.text)])
	check(str(ui._auto_badge.tooltip_text).contains("点击: 直达 修行页·自动系列状态汇总行"),
			"打磨-74 徽标 tooltip 追加 点击直达 口径 (实际 %s)" % str(ui._auto_badge.tooltip_text))
	ui._on_auto_badge()
	await get_tree().process_frame
	check(ui._tab.current_tab == 0, "打磨-74 点击 徽标 → 切 修行页 (tab=0) (实际 %d)" % ui._tab.current_tab)
	var sb_hi: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb_hi != null and sb_hi.border_width_left == 2 and sb_hi.border_color == ui.GOLD,
			"打磨-74 点击 徽标 → 汇总行 金边高亮 (边框宽=2 金)")
	check(str(ui._msg_label.text).find("直达 修行页·自动系列状态汇总行") >= 0,
			"打磨-74 点击 徽标 → 底部消息确认 (实际 %s)" % str(ui._msg_label.text))
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats,
			"打磨-74 点击 徽标 无 资源/统计 副作用 (纯导航)")
	# 重入: 高亮中 再点 徽标 kill 旧 tween 重开 (不报错 且 仍 高亮, 边框 口径 不变)
	ui._on_auto_badge()
	await get_tree().process_frame
	var sb_hi2: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb_hi2 != null and sb_hi2.border_width_left == 2, "打磨-74 高亮中 重入 不叠加/不报错 (仍 金边)")
	# 等待 tween 结束 (1.2s, 重入后 重新计时) 后 自动恢复 边框 0
	await get_tree().create_timer(1.4).timeout
	var sb_rest: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb_rest != null and sb_rest.border_width_left == 0, "打磨-74 汇总行 高亮 1.2s 后 自动恢复 (边框宽=0)")
	# --- 全关 → 徽标 隐藏 (无热区); 隐藏态 处理器 直调 仍 导航+高亮 (口径 由 visible 门控, 直调 仅验证 无副作用) ---
	g.auto_break = false
	ui._refresh()
	check(ui._auto_badge.visible == false and str(ui._auto_badge.text) == "",
			"打磨-74 全关 徽标 隐藏 无热区 (visible=%s 文本=%s)" % [str(ui._auto_badge.visible), str(ui._auto_badge.text)])
	# 收尾: 修行页 稳定, 无边框 (防 污染); tab 保持 0 (后续 无 依赖 成就页 的 测试)
	check(ui._tab.current_tab == 0, "打磨-74 收尾 保持 修行页")
	var sb_end: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb_end != null and sb_end.border_width_left == 0, "打磨-74 收尾 汇总行 无边框")
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats,
			"打磨-74 收尾 无 资源/统计 副作用")
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


# 打磨-75: 顶栏 一键系列 状态汇总徽标 — 顶栏 青色 徽标 "一键:" + 6 段热区 (领悟/神通/施展/法器/装备/最佳,
# 可执行>0 金色带计数 / =0 灰; 与 各页 一键 按钮 计数 同口径, 领悟/神通 受 技能页 筛选 叠加);
# 段 点击 直达 对应页 (重置 筛选) 或 直接 执行 一键施展 (施展 段).
# 断言 (手动驱动 确定性): 徽标节点 顶栏同父/6 段 flat Button+手型/tooltip 口径/受控基准 6 段 计数+着色/
# 键 缓存/同态 节流 无副作用/筛选 叠加 (tier0)/学 6 神通 施展段 变金/施展段 点击 直接 执行
# (爆发=速率x秒数 精确 匹配+统计+冷却后 段 回灰)/5 段 直达 (切页+重置筛选+底部消息 无副作用)/
# 全 0 态 6 段 全灰/收尾 恢复
func _assert_onekey_badge() -> void:
	var g := GameData
	# 徽标 节点: 顶栏 子节点 (与 自动 徽标 同父), flat Button 容器
	var badge: Button = ui._onekey_badge
	check(badge != null, "打磨-75 顶栏 一键 汇总 徽标 节点 存在")
	check(badge is Button and badge.flat == true, "打磨-75 徽标 flat Button (可点热区容器)")
	check(badge.get_parent() == ui._auto_badge.get_parent(),
			"打磨-75 徽标 挂在 顶栏 (与 自动 徽标 同父; 实际 %s)" % str(badge.get_parent()))
	check(ui._onekey_segs.size() == 6 and ui._onekey_btns.size() == 6,
			"打磨-75 6 段 标签/按钮 齐全 (实际 %d/%d)" % [ui._onekey_segs.size(), ui._onekey_btns.size()])
	for i in 6:
		var seg_btn: Button = ui._onekey_btns[i]
		var seg_l: Label = ui._onekey_segs[i]
		check(seg_btn is Button and seg_btn.flat == true and seg_btn.toggle_mode == false,
				"打磨-75 段%d flat 非toggle 热区" % i)
		check(seg_btn.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
				"打磨-75 段%d 手型光标" % i)
		check(seg_l.get_parent() == seg_btn, "打磨-75 段%d 标签 挂在 热区 下" % i)
		check(str(seg_btn.tooltip_text).find("段计数 = 当前 可执行数") >= 0,
				"打磨-75 段%d tooltip 含 段计数 口径 (实际 %s)" % [i, str(seg_btn.tooltip_text).left(40)])
	check(str(badge.tooltip_text).find("一键系列 状态汇总") >= 0
			and str(badge.tooltip_text).find("施展→直接 执行 一键施展") >= 0
			and str(badge.tooltip_text).find("纯 导航/执行") >= 0,
			"打磨-75 徽标 tooltip 含 汇总口径/施展执行/无副作用 说明")
	# 受控基准: 境界2 层1 灵石 5000 全空 状态 (防 前序 测试 残留 污染)
	g.realm_idx = 2
	g.layer = 1
	g.essence = 0.0
	g.stones = 5000.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._on_filter("")
	ui._on_tier_filter("")
	ui._on_equip_filter("")
	ui._on_equip_tier_filter("")
	ui._refresh()
	# 6 段 计数 与 着色 (基准 键 51|14|0|2|60|0, 期望值 与 selftest 同 数据 锚定;
	# 段 0 可执行 时 文本=名称 (灰), >0 时 追加 " N" (金))
	check(ui._onekey_key == "51|14|0|2|60|0", "打磨-75 基准 键=51|14|0|2|60|0 (实际 %s)" % ui._onekey_key)
	var exp_txt: Array = ["领悟 51", "神通 14", "施展", "法器 2", "装备 60", "最佳"]
	var exp_gold: Array = [true, true, false, true, true, false]
	for i in 6:
		var seg_l: Label = ui._onekey_segs[i]
		check(str(seg_l.text) == str(exp_txt[i]),
				"打磨-75 基准 段%d 文本=%s (实际 %s)" % [i, str(exp_txt[i]), str(seg_l.text)])
		var col: Color = seg_l.get_theme_color("font_color")
		check(col == ui.GOLD if exp_gold[i] else col == ui.DIM,
				"打磨-75 基准 段%d 着色 %s (实际 %s)" % [i, "金" if exp_gold[i] else "灰", str(col)])
	# 同态 节流: 再 _refresh 键不变 不重写 (文本 稳定 + 无 资源/统计 副作用)
	var st75: Dictionary = g.stats.duplicate(true)
	var stones75: float = g.stones
	var txt75: String = str(ui._onekey_segs[0].text) + "|" + str(ui._onekey_segs[4].text)
	ui._refresh()
	check(ui._onekey_key == "51|14|0|2|60|0"
			and str(ui._onekey_segs[0].text) + "|" + str(ui._onekey_segs[4].text) == txt75
			and g.stones == stones75 and g.stats == st75,
			"打磨-75 同态 节流 文本稳定 无 资源/统计 副作用")
	# 筛选 叠加: 品质 tier0 → 领悟/神通 段 减, 法器/装备/最佳 不变 (口径 与 技能页 按钮 一致)
	ui._on_tier_filter("0")
	ui._refresh()
	check(ui._onekey_key == "20|6|0|2|60|0", "打磨-75 筛选 tier0 键=20|6|0|2|60|0 (实际 %s)" % ui._onekey_key)
	check(str(ui._onekey_segs[0].text) == "领悟 20" and str(ui._onekey_segs[1].text) == "神通 6",
			"打磨-75 tier0 领悟 20 神通 6 (实际 %s / %s)" % [str(ui._onekey_segs[0].text), str(ui._onekey_segs[1].text)])
	check(str(ui._onekey_segs[3].text) == "法器 2" and str(ui._onekey_segs[4].text) == "装备 60",
			"打磨-75 tier0 法器/装备 段 不受 技能 筛选 影响")
	ui._on_tier_filter("")
	ui._refresh()
	# 学 6 个 可学 主动神通 (tier0) → 施展 段 变金 "施展 6"
	var act_t0: Array = []
	for sid in g.skill_ids:
		var s: Dictionary = g.skill_by_id.get(str(sid), {})
		if not s.is_empty() and str(s.get("type","")) == "active" and int(s["tier"]) == 0 and g.can_learn(str(sid)):
			act_t0.append(str(sid))
	check(act_t0.size() == 6, "打磨-75 受控 可学 主动神通(tier0)=6 (实际 %d)" % act_t0.size())
	for sid in act_t0:
		g.learned.append(str(sid))
	ui._refresh()
	check(ui._onekey_key == "45|8|6|2|60|0", "打磨-75 学6神通 键=45|8|6|2|60|0 (实际 %s)" % ui._onekey_key)
	check(str(ui._onekey_segs[2].text) == "施展 6" and ui._onekey_segs[2].get_theme_color("font_color") == ui.GOLD,
			"打磨-75 施展 段 就绪 6 金色 (实际 %s)" % str(ui._onekey_segs[2].text))
	# 施展 段 点击 = 直接 执行 一键施展 (不切页; 爆发=速率x秒数 精确; 冷却后 段 回灰)
	var qi_rate: float = g.qi_per_sec()
	var exp_burst := 0.0
	for sid in act_t0:
		exp_burst += float(g.skill_by_id[str(sid)]["value"]) * qi_rate
	var ess_before: float = g.essence
	var use_before: float = float(g.stats.get("skill_use", 0.0))
	var fcnt_before: int = ui._onekey_float_count
	var tab_before: int = ui._tab.current_tab
	ui._on_onekey_jump("cast")
	check(g.essence == ess_before + exp_burst, "打磨-75 施展执行 爆发=%s (实际 +%s)" % [str(exp_burst), str(g.essence - ess_before)])
	check(float(g.stats.get("skill_use", 0.0)) == use_before + 6.0, "打磨-75 施展执行 skill_use+6")
	check(ui._onekey_float_count == fcnt_before + 1 and str(ui._onekey_last_text).find("一键施展 6 个神通 (爆发+") >= 0,
			"打磨-75 施展执行 浮动 文案含 数量+爆发 (实际 %s)" % str(ui._onekey_last_text))
	check(ui._tab.current_tab == tab_before, "打磨-75 施展执行 不切页 (实际 %d)" % ui._tab.current_tab)
	ui._refresh()
	check(str(ui._onekey_segs[2].text) == "施展" and ui._onekey_segs[2].get_theme_color("font_color") == ui.DIM,
			"打磨-75 施展后 全冷却 施展 段 回灰 无计数 (实际 %s)" % str(ui._onekey_segs[2].text))
	check(str(ui._onekey_segs[1].text) == "神通 8", "打磨-75 施展执行 不改变 神通 可学数")
	# 5 段 直达: 切页 + 重置 筛选 + 底部 消息; 不执行 学习/购买 (只 施展 段 执行)
	var snap_ess: float = g.essence
	var snap_st: float = g.stones
	var snap_learn: int = g.learned.size()
	var snap_own: int = g.owned_eq.size()
	var snap_stats: Dictionary = g.stats.duplicate(true)
	ui._on_onekey_jump("learn")
	check(ui._tab.current_tab == 1 and ui._filter_active == "" and ui._tier_active == ""
			and str(ui._msg_label.text).find("直达 技能页·一键领悟") >= 0,
			"打磨-75 领悟段 点击 → 技能页+重置 筛选+底部消息 (tab=%d %s)" % [ui._tab.current_tab, str(ui._msg_label.text)])
	check(g.learned.size() == snap_learn, "打磨-75 领悟段 直达 不 执行 学习")
	ui._on_onekey_jump("active_learn")
	check(ui._tab.current_tab == 1 and str(ui._msg_label.text).find("一键神通") >= 0,
			"打磨-75 神通段 点击 → 技能页 一键神通 消息")
	ui._on_onekey_jump("item")
	check(ui._tab.current_tab == 0 and str(ui._msg_label.text).find("法器区") >= 0,
			"打磨-75 法器段 点击 → 修行页·法器区")
	var ip_sb: StyleBoxFlat = ui._items_panel.get_theme_stylebox("panel")
	check(ip_sb != null and ip_sb.border_width_left == 2 and ip_sb.border_color == ui.GOLD,
			"打磨-75 法器段 点击 → 法器区 金边高亮 (边框宽=2 金)")
	ui._on_onekey_jump("equip")
	check(ui._tab.current_tab == 2 and ui._equip_filter_active == "" and ui._equip_tier_active == ""
			and str(ui._msg_label.text).find("直达 装备页·一键购买") >= 0,
			"打磨-75 装备段 点击 → 装备页+重置 部位/品质 筛选")
	ui._on_onekey_jump("best")
	check(ui._tab.current_tab == 2 and str(ui._msg_label.text).find("一键最佳") >= 0,
			"打磨-75 最佳段 点击 → 装备页 一键最佳 消息")
	check(g.essence == snap_ess and g.stones == snap_st and g.learned.size() == snap_learn
			and g.owned_eq.size() == snap_own and g.stats == snap_stats,
			"打磨-75 5 段 直达 均 不 执行 批量操作 (无 资源/学习/购买 副作用)")
	# 等待 法器区 高亮 1.2s 自动恢复 (重入 口径 与 打磨-44 一致, 防 污染 收尾)
	await get_tree().create_timer(1.4).timeout
	var ip_rest: StyleBoxFlat = ui._items_panel.get_theme_stylebox("panel")
	check(ip_rest != null and ip_rest.border_width_left == 0, "打磨-75 法器区 高亮 1.2s 后 自动恢复 (边框宽=0)")
	# 全新 开荒 基准: 清空 状态 + 灵石 0 + 境界归 练气1层 → 施展/法器/装备/最佳 全 0 灰,
	# 领悟/神通 = 凡品 可学数 11/6 (与 各页 按钮 同口径; 防 前序 测试 残留 污染)
	g.stones = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._refresh()
	check(ui._onekey_key == "11|6|0|0|0|0", "打磨-75 全新基准 键=11|6|0|0|0|0 (实际 %s)" % ui._onekey_key)
	var exp0_names: Array = ["施展", "法器", "装备", "最佳"]
	for i in [2, 3, 4, 5]:
		var seg_l: Label = ui._onekey_segs[i]
		check(str(seg_l.text) == exp0_names[i - 2] and seg_l.get_theme_color("font_color") == ui.DIM,
				"打磨-75 全新基准 段%d 灰 仅名称 无计数 (实际 %s)" % [i, str(seg_l.text)])
	check(str(ui._onekey_segs[0].text) == "领悟 11" and str(ui._onekey_segs[1].text) == "神通 6",
			"打磨-75 全新基准 领悟11 神通6 金色 (实际 %s / %s)" % [str(ui._onekey_segs[0].text), str(ui._onekey_segs[1].text)])
	# 收尾: 恢复 干净 基准 (防 污染 后续 测试)
	g.stones = 0.0
	g.essence = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._refresh()
	await get_tree().process_frame


# 打磨-76: 顶栏 一键 徽标 段 悬浮 明细 — 段 tooltip 追加 可执行项 列表 (与 段 计数 同 状态键 节流);
# 断言 (手动驱动 确定性): 6 段 tooltip 结构 (口径行 + 段计数 行 + 空行 + 明细) / 基准 明细 文案
# (领悟 51 可学 截断 6 行+…45 项 / 神通 14 / 施展 无就绪 说明 / 法器 2 件 价格升序 / 装备 60 件 5 行+…55 项 /
# 最佳 无拥有 说明) / 明细 与 onekey_segment_tips 接口 逐段 恒等 / 筛选 叠加 刷新 (tier0 领悟 20 神通 6) /
# 学 6 神通 施展段 明细 6 行 爆发 预览 / 拥有 5 件 未穿 最佳段 5 部位 / 同态 节流 tooltip 稳定 无副作用 /
# 灵石 0 法器装备段 灵石不足 说明 / 收尾 恢复 干净 基准
func _assert_onekey_tip_detail() -> void:
	var g := GameData
	# 受控基准: 境界2 层1 / 灵石 5000 / 空 状态 (防 前序 测试 残留 污染, 与 打磨-75 基准 同)
	g.realm_idx = 2
	g.layer = 1
	g.essence = 0.0
	g.stones = 5000.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._on_filter("")
	ui._on_tier_filter("")
	ui._on_equip_filter("")
	ui._on_equip_tier_filter("")
	ui._refresh()
	# 6 段 tooltip 结构: 口径说明行 + "段计数 =" 行 + 空行 + 明细 (明细 首行 含 计数 前缀)
	var exp_prefix: Array = ["51 个可学:", "14 个可学:", "无 就绪 主动神通", "2 件可购:", "60 件可购:", "各 部位 已 最佳"]
	var tips: Array = g.onekey_segment_tips()
	for i in 6:
		var seg_btn: Button = ui._onekey_btns[i]
		var tt: String = str(seg_btn.tooltip_text)
		check(tt.find("段计数 = 当前 可执行数") >= 0, "打磨-76 段%d tooltip 含 段计数 口径 行" % i)
		var detail_part: String = tt.substr(tt.rfind("\n\n"))
		check(detail_part.find("\n\n") >= 0, "打磨-76 段%d tooltip 含 空行 分隔 明细 (实际 %s)" % [i, detail_part.left(20)])
		var det: String = detail_part.substr(detail_part.find("\n\n") + 2)
		check(det == str(tips[i]), "打磨-76 段%d tooltip 明细 = onekey_segment_tips 接口 (实际 %s)" % [i, det.left(30)])
		check(str(tips[i]).find(str(exp_prefix[i])) == 0 or str(tips[i]).begins_with(str(exp_prefix[i])),
				"打磨-76 段%d 明细 前缀=%s (实际 %s)" % [i, str(exp_prefix[i]), str(tips[i]).left(20)])
	check(str(tips[3]).find("· 「木剑」 灵石 100") >= 0 and str(tips[3]).find("· 「玉符」 灵石 1000") >= 0,
			"打磨-76 法器 段 明细 价格升序 (实际 %s)" % str(tips[3]))
	# 同态 节流: 再 _refresh 键不变 → tooltip 不重写 文本稳定 无 资源/统计 副作用
	var st76: Dictionary = g.stats.duplicate(true)
	var stones76: float = g.stones
	var tt76: Array = []
	for i in 6:
		tt76.append(str(ui._onekey_btns[i].tooltip_text))
	ui._refresh()
	var tt76b: Array = []
	for i in 6:
		tt76b.append(str(ui._onekey_btns[i].tooltip_text))
	check(tt76 == tt76b and g.stones == stones76 and g.stats == st76,
			"打磨-76 同态 节流 tooltip 稳定 无 资源/统计 副作用")
	# 筛选 叠加: tier0 → 领悟/神通 段 明细 刷新 (前缀 20/6, 法器/装备 段 不变)
	ui._on_tier_filter("0")
	ui._refresh()
	var tips_t0: Array = g.onekey_segment_tips("", 0)
	check(str(ui._onekey_btns[0].tooltip_text).find(str(tips_t0[0])) >= 0
			and str(ui._onekey_btns[0].tooltip_text).find("20 个可学:") >= 0,
			"打磨-76 tier0 领悟段 明细 刷新 前缀 20 个可学 (实际 %s)" % str(tips_t0[0]).left(20))
	check(str(ui._onekey_btns[1].tooltip_text).find("6 个可学:") >= 0,
			"打磨-76 tier0 神通段 明细 刷新 前缀 6 个可学 (实际 %s)" % str(tips_t0[1]).left(20))
	check(str(ui._onekey_btns[3].tooltip_text).find(str(tips_t0[3])) >= 0
			and str(ui._onekey_btns[4].tooltip_text).find(str(tips_t0[4])) >= 0,
			"打磨-76 tier0 法器/装备 段 明细 不受 技能 筛选 影响")
	ui._on_tier_filter("")
	ui._refresh()
	# 学 6 个 可学 主动神通 (tier0) → 施展段 明细 刷新 6 行 爆发 预览
	var act_t0: Array = []
	for sid in g.skill_ids:
		var s: Dictionary = g.skill_by_id.get(str(sid), {})
		if not s.is_empty() and str(s.get("type","")) == "active" and int(s["tier"]) == 0 and g.can_learn(str(sid)):
			act_t0.append(str(sid))
	for sid in act_t0:
		g.learned.append(str(sid))
	ui._refresh()
	var tip_cast: String = str(ui._onekey_btns[2].tooltip_text)
	check(tip_cast.find("6 个就绪:") >= 0 and tip_cast.count("爆发 +") == 6,
			"打磨-76 学6神通 施展段 明细 刷新 6 行 爆发 预览 (实际 %s)" % tip_cast.left(30))
	# 拥有 各部位 最便宜件 (5 件) 未 穿戴 → 最佳段 明细 刷新 5 部位 (换 建议 + 当前 件名)
	for slot in g.SLOTS:
		var cheapest: Dictionary = {}
		for eid in g.equip_ids:
			var e: Dictionary = g.equip_by_id[eid]
			if str(e["slot"]) != slot:
				continue
			if cheapest.is_empty() or float(e["cost"]) < float(cheapest["cost"]):
				cheapest = e
		g.owned_eq.append(str(cheapest["id"]))
	ui._refresh()
	var tip_best: String = str(ui._onekey_btns[5].tooltip_text)
	check(tip_best.find("5 部位 可改进:") >= 0 and tip_best.count("\n· ") == 5,
			"打磨-76 拥有5件未穿 最佳段 明细 刷新 5 部位 (实际 %s)" % tip_best.left(30))
	# 灵石 归 0 → 法器/装备 段 明细 刷新 灵石不足 说明
	g.stones = 0.0
	ui._refresh()
	check(str(ui._onekey_btns[3].tooltip_text).find("灵石 不足") >= 0
			and str(ui._onekey_btns[4].tooltip_text).find("灵石 不足") >= 0,
			"打磨-76 灵石0 法器/装备段 明细 刷新 灵石不足 说明")
	# 收尾: 恢复 干净 基准 (防 污染 后续 测试), tooltip 恢复 收尾 基准 文案
	g.stones = 0.0
	g.essence = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._refresh()
	var tips_f: Array = g.onekey_segment_tips()
	check(str(ui._onekey_btns[0].tooltip_text).find("11 个可学:") >= 0
			and str(ui._onekey_btns[5].tooltip_text).find("各 部位 已 最佳") >= 0
			and str(tips_f[0]) == str(tips_f[0]),
			"打磨-76 收尾 基准 段 tooltip 恢复 干净 明细")
	await get_tree().process_frame


# 打磨-77: 顶栏 挂机时长 常显 — 顶栏 灵石 行 后 加 灰色小字 "⏳ X小时Y分" (stats.play_sec 分钟档 口径,
# 复用 GameData.play_time_text; 0 时长 隐藏 避免 空文本 占位; 文本 变化 才刷 节流; 纯展示 无 副作用);
# 断言 (手动驱动 确定性): 标签 节点 顶栏 同父/初始 0 时长 隐藏 文本空/注入 600s 显示 ⏳ 10分 可见+灰色/
# 分钟档 节流 (同 分钟档 内 play_sec+10 不重写 文本)/跨档 4200s 显示 1小时10分/tooltip 口径/
# 归 0 恢复 隐藏 文本空/刷新 无 资源/统计 副作用/收尾 0 时长 隐藏
func _assert_play_time_badge() -> void:
	var g := GameData
	# 节点: 顶栏 子节点 (与 自动/一键 徽标 同父), 灰色
	var pl: Label = ui._play_label
	check(pl != null, "打磨-77 顶栏 挂机时长 标签 节点 存在")
	check(pl.get_parent() == ui._auto_badge.get_parent(),
			"打磨-77 标签 挂在 顶栏 (与 自动 徽标 同父; 实际 %s)" % str(pl.get_parent()))
	check(pl.get_theme_color("font_color") == Color(0.6, 0.62, 0.68),
			"打磨-77 标签 字色 灰色 (实际 %s)" % str(pl.get_theme_color("font_color")))
	check(pl.tooltip_text.find("累计 挂机 时长") >= 0 and pl.tooltip_text.find("不含 离线") >= 0,
			"打磨-77 标签 tooltip 含 口径 说明 (实际 %s)" % pl.tooltip_text.left(24))
	# 初始: play_sec=0 (前序 收尾 干净 基准) → 隐藏 + 文本空
	check(pl.visible == false and str(pl.text) == "",
			"打磨-77 初始 0 时长 隐藏 文本空 (实际 visible=%s text=%s)" % [str(pl.visible), str(pl.text)])
	# 注入 600s → "⏳ 10分" 可见
	g.stats["play_sec"] = 600.0
	ui._refresh()
	check(pl.visible == true and str(pl.text) == "⏳ 10分",
			"打磨-77 600s 显示 ⏳ 10分 可见 (实际 visible=%s text=%s)" % [str(pl.visible), str(pl.text)])
	# 节流: 同 分钟档 内 刷新 文本 稳定, 无 资源/统计 副作用
	var snap_pt: Dictionary = g.stats.duplicate(true)
	ui._refresh()
	check(str(pl.text) == "⏳ 10分" and g.stats == snap_pt,
			"打磨-77 同 分钟档 节流 文本 稳定 无副作用")
	# 跨档: 4200s = 1小时10分 刷新
	g.stats["play_sec"] = 4200.0
	ui._refresh()
	check(str(pl.text) == "⏳ 1小时10分",
			"打磨-77 跨档 4200s 显示 1小时10分 (实际 %s)" % str(pl.text))
	# 610→620s 同 分钟档 (10分) 文本 不重写
	g.stats["play_sec"] = 610.0
	ui._refresh()
	var t610: String = str(pl.text)
	g.stats["play_sec"] = 620.0
	ui._refresh()
	check(str(pl.text) == t610 and str(pl.text) == "⏳ 10分",
			"打磨-77 610→620s 同 分钟档 文本 不重写 (实际 %s)" % str(pl.text))
	# 归 0 → 隐藏 文本空 恢复
	g.stats["play_sec"] = 0.0
	ui._refresh()
	check(pl.visible == false and str(pl.text) == "",
			"打磨-77 归 0 恢复 隐藏 文本空 (实际 visible=%s text=%s)" % [str(pl.visible), str(pl.text)])
	# 收尾: 干净 基准 (play_sec 0 隐藏)
	check(float(g.stats.get("play_sec", 0.0)) == 0.0,
		"打磨-77 收尾 play_sec 恢复 0 (实际 %s)" % str(g.stats.get("play_sec")))
	check(pl.visible == false, "打磨-77 收尾 0 时长 隐藏 稳定")
	await get_tree().process_frame


# 打磨-78: 顶栏 主资源速率 常显 — 顶栏 主资源行 (灵气/道行) 后 加 灰色小字 "+X/秒" (未飞升=灵气/秒,
# 飞升后=道行/秒, 与 修行页 灵气速率 同 口径; 速率<=0 隐藏; 文本 变化 才刷 节流; 纯展示 无 副作用);
# 断言 (手动驱动 确定性): 标签 节点 顶栏 同父/灰色/tooltip 口径/初始 可见+文本=接口 (速率恒>0)/
# 同态 节流 稳定 无副作用/境界 变化 文本 同步 (动态 恒等)/飞升 后 道行 口径 动态 恒等/恢复 复原/
# 收尾 文本=接口 可见
func _assert_primary_rate_badge() -> void:
	var g := GameData
	# 节点: 顶栏 子节点 (与 挂机时长 标签 同父), 灰色 13px
	var rl: Label = ui._rate_label
	check(rl != null, "打磨-78 顶栏 主资源速率 标签 节点 存在")
	check(rl.get_parent() == ui._play_label.get_parent(),
		"打磨-78 标签 挂在 顶栏 (与 挂机时长 标签 同父; 实际 %s)" % str(rl.get_parent()))
	check(rl.get_theme_color("font_color") == Color(0.6, 0.62, 0.68),
		"打磨-78 标签 字色 灰色 (实际 %s)" % str(rl.get_theme_color("font_color")))
	check(rl.tooltip_text.find("主资源 收入 速率") >= 0 and rl.tooltip_text.find("修行页 灵气速率 同 口径") >= 0,
		"打磨-78 标签 tooltip 含 口径 说明 (实际 %s)" % rl.tooltip_text.left(20))
	# 初始: 速率 恒 >0 (QI_MULT>=1) → 可见 + 文本=接口 (动态 恒等, 防 前序 残留 干扰)
	var t0: String = g.primary_rate_text()
	check(t0 != "", "打磨-78 基准 速率>0 接口 非空 (实际 %s)" % t0)
	check(rl.visible == true and str(rl.text) == t0,
		"打磨-78 初始 可见 文本=接口 (实际 visible=%s text=%s)" % [str(rl.visible), str(rl.text)])
	# 节流: 同态 刷新 文本 稳定, 无 资源/统计 副作用
	var snap_r: Dictionary = g.stats.duplicate(true)
	var ess_r: float = g.essence
	var st_r: float = g.stones
	ui._refresh()
	check(str(rl.text) == t0 and g.stats == snap_r and g.essence == ess_r and g.stones == st_r,
		"打磨-78 同态 节流 文本 稳定 无副作用")
	# 境界 变化 → 文本 同步 (动态 恒等, 恢复原 境界)
	var realm_save: int = g.realm_idx
	g.realm_idx = 2
	ui._refresh()
	var t_r2: String = g.primary_rate_text()
	check(str(rl.text) == t_r2 and t_r2 != t0,
		"打磨-78 境界2 文本 同步 (实际 %s, 期望 %s)" % [str(rl.text), t_r2])
	g.realm_idx = realm_save
	ui._refresh()
	check(str(rl.text) == t0, "打磨-78 恢复 境界 后 文本 复原 (实际 %s)" % str(rl.text))
	# 飞升 后 口径 = 道行/秒 (速率 同 公式, 动态 恒等; 恢复 原 态)
	var asc_save: bool = g.ascended
	var daoLv_save: int = g.dao_level
	g.ascended = true
	g.dao_level = 1
	ui._refresh()
	var t_asc: String = g.primary_rate_text()
	check(str(rl.text) == t_asc,
		"打磨-78 飞升 后 文本=接口 道行 口径 (实际 %s, 期望 %s)" % [str(rl.text), t_asc])
	g.ascended = asc_save
	g.dao_level = daoLv_save
	ui._refresh()
	check(str(rl.text) == t0, "打磨-78 恢复 飞升 态 后 文本 复原 (实际 %s)" % str(rl.text))
	# 收尾: 可见 + 文本=接口
	check(rl.visible == true and str(rl.text) == g.primary_rate_text(),
		"打磨-78 收尾 可见 文本=接口 稳定")


# 打磨-79: 顶栏 灵石速率 常显 — 顶栏 灵石行 后 加 灰色小字 "+X/秒" (与 修行页 灵石速率 行 同口径
# = 基础 x 境界倍率 x (1+灵石/全面被动+装备加成); 法器连乘 不影响 灵石; 速率<=0 隐藏;
# 文本 变化 才刷 节流; 纯展示 无 副作用);
# 断言 (手动驱动 确定性): 标签 节点 顶栏 同父/灰色/tooltip 口径/初始 可见+文本=接口 (灵石速率恒>0)/
# 同态 节流 稳定 无副作用/境界 变化 文本 同步 (动态 恒等)/飞升 后 口径 不变 动态 恒等/恢复 复原/
# 收尾 文本=接口 可见
func _assert_stone_rate_badge() -> void:
	var g := GameData
	# 节点: 顶栏 子节点 (与 挂机时长 标签 同父), 灰色 13px
	var sl: Label = ui._sr_label
	check(sl != null, "打磨-79 顶栏 灵石速率 标签 节点 存在")
	check(sl.get_parent() == ui._play_label.get_parent(),
		"打磨-79 标签 挂在 顶栏 (与 挂机时长 标签 同父; 实际 %s)" % str(sl.get_parent()))
	check(sl.get_theme_color("font_color") == Color(0.6, 0.62, 0.68),
		"打磨-79 标签 字色 灰色 (实际 %s)" % str(sl.get_theme_color("font_color")))
	check(sl.tooltip_text.find("灵石 收入 速率") >= 0 and sl.tooltip_text.find("修行页 灵石速率 行 同 口径") >= 0,
		"打磨-79 标签 tooltip 含 口径 说明 (实际 %s)" % sl.tooltip_text.left(20))
	# 初始: 灵石速率 恒 >0 (境界倍率>=1) → 可见 + 文本=接口 (动态 恒等, 防 前序 残留 干扰)
	var t0: String = g.stone_rate_text()
	check(t0 != "", "打磨-79 基准 灵石速率>0 接口 非空 (实际 %s)" % t0)
	check(sl.visible == true and str(sl.text) == t0,
		"打磨-79 初始 可见 文本=接口 (实际 visible=%s text=%s)" % [str(sl.visible), str(sl.text)])
	# 节流: 同态 刷新 文本 稳定, 无 资源/统计 副作用
	var snap_s: Dictionary = g.stats.duplicate(true)
	var ess_s: float = g.essence
	var st_s: float = g.stones
	ui._refresh()
	check(str(sl.text) == t0 and g.stats == snap_s and g.essence == ess_s and g.stones == st_s,
		"打磨-79 同态 节流 文本 稳定 无副作用")
	# 境界 变化 → 文本 同步 (灵石 速率 含 境界倍率, 动态 恒等; 恢复原 境界)
	var realm_s: int = g.realm_idx
	g.realm_idx = 2
	ui._refresh()
	var t_r2: String = g.stone_rate_text()
	check(str(sl.text) == t_r2 and t_r2 != t0,
		"打磨-79 境界2 文本 同步 (实际 %s, 期望 %s)" % [str(sl.text), t_r2])
	g.realm_idx = realm_s
	ui._refresh()
	check(str(sl.text) == t0, "打磨-79 恢复 境界 后 文本 复原 (实际 %s)" % str(sl.text))
	# 飞升 后 口径 不变 (灵石 恒 为 灵石, 同 公式 动态 恒等; 恢复 原 态)
	var asc_s: bool = g.ascended
	var daoLv_s: int = g.dao_level
	g.ascended = true
	g.dao_level = 1
	ui._refresh()
	var t_asc: String = g.stone_rate_text()
	check(str(sl.text) == t_asc,
		"打磨-79 飞升 后 文本=接口 口径 不变 (实际 %s, 期望 %s)" % [str(sl.text), t_asc])
	g.ascended = asc_s
	g.dao_level = daoLv_s
	ui._refresh()
	check(str(sl.text) == t0, "打磨-79 恢复 飞升 态 后 文本 复原 (实际 %s)" % str(sl.text))
	# 收尾: 可见 + 文本=接口
	check(sl.visible == true and str(sl.text) == g.stone_rate_text(),
		"打磨-79 收尾 可见 文本=接口 稳定")


# 打磨-81: 顶栏 下一目标 渐变进度条 — 顶栏 下 5px 全宽 青色 填充 (next_goal_ratio 0..1,
# 与 修行页 下一目标 行 同 口径; 2% 量化档+布局宽 变化 才写 fill, 挂机 恒定 无 每帧 重绘;
# tooltip 动态 含 比例; 飞升 后 口径 切换 道行精进; 道祖 封顶 满条; 纯 展示 无 副作用);
# 断言 (手动驱动 确定性): 节点/父链/高度/颜色/tooltip 口径/初始 0% 空 填充/同态 节流 稳定/
# 灵气 半程 50% 填充 同步/同态 再刷 fill 不变 节流/攒满 100% 满 填充/境界2 消耗变 比例 同步/
# 飞升 口径 切换 道行精进 动态 恒等/道祖 封顶 满条/恢复 复原 收尾 0% 稳定 无 资源/统计 副作用
func _assert_goalbar() -> void:
	var g := GameData
	var bg: ColorRect = ui._goalbar_bg
	var fill: ColorRect = ui._goalbar_fill
	check(bg != null and fill != null, "打磨-81 顶栏 下一目标 进度条 节点 存在")
	check(fill.get_parent() == bg, "打磨-81 填充 挂在 背景 下 (实际 %s)" % str(fill.get_parent()))
	var root_bg: Node = bg.get_parent()
	check(root_bg.get_children().find(bg) >= 0 and root_bg.get_child(root_bg.get_children().find(bg) + 1) == ui._tab,
		"打磨-81 进度条 紧随 顶栏 (root 内 顶栏 下一位; 实际 %s)" % str(root_bg))
	check(bg.custom_minimum_size.y >= 5.0, "打磨-81 进度条 高度>=5px (实际 %s)" % str(bg.custom_minimum_size.y))
	check(fill.color == Color(0.62, 0.9, 0.95, 0.9),
		"打磨-81 填充 青色 (实际 %s)" % str(fill.color))
	check(str(bg.tooltip_text).find("下一目标") >= 0 and str(bg.tooltip_text).find("无 存档/统计 副作用") >= 0,
		"打磨-81 tooltip 口径 (静态/动态 均含 下一目标+副作用 说明; 实际 %s)" % bg.tooltip_text.left(24))
	# 等 布局落定 (宽度 0 -> 实际 宽, headless 高负载时 1 帧可能不够, 上限 20 帧; 与 打磨-58 同款加固)
	for _i81 in 20:
		if bg.size.x > 0.0:
			break
		await get_tree().process_frame
	check(bg.size.x > 0.0, "打磨-81 进度条 布局宽>0 (实际 %s)" % str(bg.size.x))
	var w: float = bg.size.x
	# 受控基准: 前序 测试 可能 残留 灵气, 显式 置 0 再 驱动 (初始 0 灵气 → ratio 0 → 0 填充)
	var ess81s: float = g.essence
	g.essence = 0.0
	ui._refresh()
	var t0: String = g.next_goal_text()
	check(int(fill.size.x) == 0, "打磨-81 初始 0 灵气 空 填充 (实际 %s)" % str(fill.size.x))
	check(str(bg.tooltip_text).find("下一目标  0%") >= 0 and str(bg.tooltip_text).find(t0) >= 0,
		"打磨-81 初始 tooltip=下一目标 0%%|下一目标文本 (实际 %s)" % bg.tooltip_text)
	check(str(bg.tooltip_text).find("与 修行页 下一目标 行 同 口径") >= 0
		and str(bg.tooltip_text).find("无 存档/统计 副作用") >= 0,
		"打磨-81 动态 tooltip 含 口径 说明 (实际 %s)" % bg.tooltip_text.left(24))
	# 节流: 同态 再刷 fill/tooltip 稳定, 无 资源/统计 副作用
	var snap81u: Dictionary = g.stats.duplicate(true)
	var ess81u: float = g.essence
	var st81u: float = g.stones
	ui._refresh()
	check(int(fill.size.x) == 0 and g.stats == snap81u and g.essence == ess81u and g.stones == st81u,
		"打磨-81 同态 节流 fill/tooltip 稳定 无副作用")
	# 灵气 半程 → ratio 0.5 → 50% 档 填充 + tooltip 50% 同步
	var cost81u: float = g.breakthrough_cost()
	g.essence = cost81u * 0.5
	ui._refresh()
	var w2: float = bg.size.x
	check(absf(fill.size.x - w2 * 0.5) < 1.0, "打磨-81 半程 50%% 档 填充 (实际 %s, 期望 ~%s)" % [str(fill.size.x), str(w2 * 0.5)])
	check(str(bg.tooltip_text).find("下一目标  50%") >= 0,
		"打磨-81 半程 tooltip=50%% (实际 %s)" % bg.tooltip_text)
	# 同态 再刷 不 重写 fill (2% 量化档 未跨档, 缓存键 未变)
	var f81_before: float = fill.size.x
	ui._refresh()
	check(fill.size.x == f81_before, "打磨-81 同态 再刷 fill 不 重写 (节流) (实际 %s)" % str(fill.size.x))
	# 攒满 → 100% 满 填充 (与 突破 ready 口径 一致)
	g.essence = cost81u
	ui._refresh()
	var w3: float = bg.size.x
	check(fill.size.x == w3, "打磨-81 攒满 100%% 满 填充 (实际 %s, 宽 %s)" % [str(fill.size.x), str(w3)])
	check(str(bg.tooltip_text).find("下一目标  100%") >= 0 and str(bg.tooltip_text).find("点击突破") >= 0,
		"打磨-81 攒满 tooltip=100%%|已攒够 (实际 %s)" % bg.tooltip_text)
	# 境界 变化 → 消耗 变 比例 同步 (半程 基准 按 新境界 消耗 重算, 动态 恒等; 恢复原 境界)
	var realm81u: int = g.realm_idx
	g.realm_idx = 2
	g.essence = g.breakthrough_cost() * 0.5
	ui._refresh()
	var t_r2: String = g.next_goal_text()
	check(str(bg.tooltip_text).find(t_r2) >= 0,
		"打磨-81 境界2 消耗变 tooltip 同步 (实际 %s)" % bg.tooltip_text)
	check(str(bg.tooltip_text).find("下一目标  50%") >= 0,
		"打磨-81 境界2 半程 仍 50%% 档 (实际 %s)" % bg.tooltip_text)
	g.realm_idx = realm81u
	ui._refresh()
	# 飞升 口径 切换: tooltip 前缀=道行精进 + 道行 比例 动态 恒等 (道祖 封顶 满条; 恢复原 态)
	var asc81u: bool = g.ascended
	var dao81u: float = g.dao
	var daoLv81u: int = g.dao_level
	g.ascended = true
	g.dao = g.dao_break_cost() * 0.25
	ui._refresh()
	check(str(bg.tooltip_text).find("道行精进  25%") >= 0,
		"打磨-81 飞升 tooltip=道行精进 25%% (实际 %s)" % bg.tooltip_text)
	# 填充 按 2% 量化档 (25% → ceil 档 13/50=26%), 容差 覆盖 1 档 量化 误差
	check(fill.size.x >= bg.size.x * 0.24 and fill.size.x <= bg.size.x * 0.28,
		"打磨-81 飞升 25%% 档 填充 (实际 %s, 宽 %s)" % [str(fill.size.x), str(bg.size.x)])
	g.dao_level = g.IMMORTAL_REALMS.size() - 1
	ui._refresh()
	check(fill.size.x == bg.size.x and str(bg.tooltip_text).find("道行精进  100%") >= 0,
		"打磨-81 道祖 封顶 满条 (实际 fill=%s 宽=%s tooltip=%s)" % [str(fill.size.x), str(bg.size.x), bg.tooltip_text.left(24)])
	g.ascended = asc81u
	g.dao_level = daoLv81u
	g.dao = dao81u
	g.essence = 0.0
	ui._refresh()
	# 收尾: 0% 空 填充 稳定 + 无 资源/统计 副作用
	var snap81e: Dictionary = g.stats.duplicate(true)
	check(int(fill.size.x) == 0 and g.stats == snap81e,
		"打磨-81 收尾 恢复 0% 空 填充 稳定 无副作用")
	g.essence = ess81s  # 恢复 前序 残留 灵气 (不影响 _finish, 防 后续 轮 启动态 漂移)

