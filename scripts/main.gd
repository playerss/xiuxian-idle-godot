extends Control
## 修仙挂机 · 主界面 (UI 全部代码构建, Tab: 修行/技能/装备)

const BG := Color(0.07, 0.08, 0.11)
const PANEL_BG := Color(0.12, 0.13, 0.18)
const CARD_BG := Color(0.16, 0.17, 0.22)
const GOLD := Color(0.98, 0.86, 0.5)
const CYAN := Color(0.62, 0.9, 0.95)
const DIM := Color(0.6, 0.62, 0.68)
const WHITEISH := Color(0.92, 0.92, 0.95)
const HILITE := Color(0.98, 0.86, 0.5)  # 已学/已穿戴 高亮金

var _realm_label: Label
var _essence_label: Label
var _stones_label: Label
var _qi_label: Label
var _stone_rate_label: Label
var _offline_label: Label      # 打磨-13: 离线每小时收益 (修行页)
var _offline_text := ""        # 离线文本缓存 (变化时才刷)
var _break_eta_label: Label    # 打磨-24: 突破/道行精进 ETA (修行页)
var _break_eta_text := ""      # 突破 ETA 文本缓存 (变化时才刷)
var _stats_label: Label        # 打磨-14: 修行统计 (修行页)
var _stats_text := ""          # 统计文本缓存 (变化时才刷)
var _progress_label: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _break_btn: Button
var _shop_box: VBoxContainer
var _shop_rows: Dictionary = {}
var _msg_label: Label
var _msg_tween: Tween
var _float_label: Label
var _float_tween: Tween
var _ach_float_label: Label   # 打磨-17: 成就解锁浮动提示 (顶层)
var _ach_float_tween: Tween
var _ach_prev: Array[String] = []  # 打磨-17: 上帧已解锁成就快照 (检测新解锁)
var _ach_float_count := 0          # 打磨-17: 成就浮动提示次数 (自测断言用)
var _break_flash_seq := 0
var _realm_tip := ""              # 境界标签 tooltip 缓存 (变化时才刷新)
var _btn_sb_normal: StyleBoxFlat  # 突破按钮默认样式 (闪烁后恢复用)
var _flash_sb: StyleBoxFlat       # 闪烁用样式 (成功绿/失败红)
var _flash_left := 0              # 剩余闪烁帧数
var _tab: TabContainer
var _skill_box: VBoxContainer
var _skill_row_nodes: Dictionary = {}
var _skill_btns: Dictionary = {}
var _filter_btns: Dictionary = {}
var _filter_active := ""
var _tier_btns: Dictionary = {}         # 打磨-20: 品质筛选按钮 (key = 品质索引字符串, "" = 全部)
var _tier_active := ""                 # 打磨-20: 当前品质筛选 ("" = 全部)
var _equip_box: VBoxContainer
var _equip_row_nodes: Dictionary = {}
var _equip_btns: Dictionary = {}
var _learn_all_btn: Button           # 打磨-23: 一键领悟 (技能页)
var _buy_all_btn: Button            # 打磨-23: 一键购买 (装备页)
var _equip_filter_btns: Dictionary = {}  # 部位 id -> 筛选按钮 (打磨-11)
var _equip_filter_active := ""           # "" = 全部
var _equip_tier_btns: Dictionary = {}    # 打磨-21: 装备品质筛选按钮 (key = 品质索引字符串, "" = 全部)
var _equip_tier_active := ""             # 打磨-21: 当前装备品质筛选 ("" = 全部)
var _eq_states: Array = []               # 打磨-22: 上帧装备状态快照 (变化才重排)
var _slot_labels: Dictionary = {}
var _card_sb_normal: StyleBoxFlat
var _card_sb_hi: StyleBoxFlat
var _ach_box: VBoxContainer
var _ach_rows: Dictionary = {}      # 成就 id -> {row, name_l, desc_l, prog_l}
var _ach_count_label: Label
var _ach_hl_seq := 0               # 成就解锁总数缓存 (变化时才刷样式)
var _bonus_labels: Array[Label] = []  # 技能/装备页顶栏 总加成汇总标签 (打磨-9)
var _bonus_text := ""              # 汇总文本缓存 (变化时才刷)
var _shop_row_nodes: Dictionary = {} # 法器 id -> row (tooltip 状态刷新用)
var _shop_eta: Dictionary = {}     # 法器 id -> 购买 ETA 提示标签 (打磨-12)
var _equip_eta: Dictionary = {}    # 装备 id -> 购买 ETA 提示标签 (打磨-12)
var _eta_acc := 0.0                # 打磨-12: ETA 节流累计 (1 秒刷一次)
var _realm_ladder: Array[Label] = []    # 打磨-18: 境界阶梯标签 (金框高亮随当前境界移动)
var _immortal_ladder: Array[Label] = [] # 打磨-18: 仙界道行阶梯标签
var _ladder_key := -1                # 打磨-18: 阶梯高亮缓存键 (境界/道行变化才刷)


func _ready() -> void:
	_card_sb_normal = _make_card_sb(false)
	_card_sb_hi = _make_card_sb(true)
	_btn_sb_normal = _make_btn_sb_normal()
	_build_ui()
	if GameData.offline_msg != "":
		_show_msg(GameData.offline_msg)
	# 打磨-17: 启动时先取基线快照, 读档恢复的旧解锁不当作"新解锁"弹浮动
	_ach_prev = GameData.ach_done.duplicate()


func _process(_delta: float) -> void:
	_refresh()
	_flash_step()


# ---------- UI 构建 ----------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 14
	root.offset_right = -16
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# 顶栏
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	root.add_child(top)
	top.add_child(_label("修 仙 挂 机", 26, GOLD))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_realm_label = _label("", 19, CYAN)
	top.add_child(_realm_label)
	_essence_label = _label("灵气 0", 19, GOLD)
	top.add_child(_essence_label)
	_stones_label = _label("灵石 0", 19, WHITEISH)
	top.add_child(_stones_label)

	# Tab
	_tab = TabContainer.new()
	_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tab)
	var page1 := _make_page("修行")
	var page2 := _make_page("技能")
	var page3 := _make_page("装备")
	var page4 := _make_page("成就")
	_tab.add_child(page1)
	_tab.add_child(page2)
	_tab.add_child(page3)
	_tab.add_child(page4)

	_build_training_page(page1)
	_build_skill_page(page2)
	_build_equip_page(page3)
	_build_ach_page(page4)

	# 底部消息
	_msg_label = _label("", 18, GOLD)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_msg_label)

	# 突破浮动提示 (顶层, 居中上浮淡出)
	_float_label = _label("", 24, GOLD)
	_float_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_float_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_float_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_float_label.position = Vector2(0, -20)
	_float_label.modulate = Color(1, 1, 1, 0)
	_float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_float_label)

	# 打磨-17: 成就解锁浮动提示 (顶层, 居中略偏下, 金绿上浮淡出)
	_ach_float_label = _label("", 22, Color(0.65, 0.95, 0.6))
	_ach_float_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_ach_float_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_ach_float_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_ach_float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ach_float_label.position = Vector2(0, -70)
	_ach_float_label.modulate = Color(1, 1, 1, 0)
	_ach_float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ach_float_label)


func _make_page(title: String) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	p.add_theme_stylebox_override("panel", sb)
	p.name = title
	return p


func _build_training_page(page: Panel) -> void:
	var wrap := HBoxContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.offset_left = 10
	wrap.offset_top = 8
	wrap.offset_right = -10
	wrap.offset_bottom = -8
	wrap.add_theme_constant_override("separation", 16)
	page.add_child(wrap)

	# 左: 修行状态 + 法器
	var left := _add_panel(wrap)
	left.add_child(_label("修 行 状 态", 15, DIM))
	left.add_child(_sep())
	_qi_label = _label("灵气速率  0 /秒", 15, CYAN)
	left.add_child(_qi_label)
	_stone_rate_label = _label("灵石速率  0 /秒", 15, CYAN)
	left.add_child(_stone_rate_label)
	# 打磨-13: 离线/挂机收益可视化 (每小时离线可得资源)
	_offline_label = _label("", 14, DIM)
	left.add_child(_offline_label)
	_offline_label.tooltip_text = "离线收益 = 当前速率 x 离线效率 (基础50% + 功法/装备加成), 上限 8 小时。关闭游戏后继续积累, 重新进入时发放。\n飞升后离线主资源计入道行。"
	# 打磨-14: 修行统计 (累计时长/突破/道行精进/神通/法器/装备, 持久化)
	_stats_label = _label("", 13, DIM)
	left.add_child(_stats_label)
	_stats_label.tooltip_text = "修行统计自开荒起累计, 存档保存。\n突破: 境界层数成功次数 (含飞升)。\n道行精进: 飞升后道行阶段成功次数。"
	left.add_child(_sep())
	_progress_label = _label("突破进度  0%", 14, DIM)
	left.add_child(_progress_label)
	# 打磨-24: 突破/道行精进 ETA (按当前速率预计何时攒够突破资源)
	_break_eta_label = _label("", 13, DIM)
	left.add_child(_break_eta_label)
	_break_eta_label.tooltip_text = "按当前灵气(道行)速率估算攒够突破资源所需时间。挂机/神通/境界提升都会改变该时间, 攒够后自动消失。"
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.18, 0.19, 0.25)
	_bar_bg.custom_minimum_size = Vector2(0, 14)
	_bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_bar_bg)
	_bar_fill = ColorRect.new()
	_bar_fill.color = CYAN
	_bar_fill.position = Vector2.ZERO
	_bar_bg.add_child(_bar_fill)
	_break_btn = _make_button("尝试突破")
	_break_btn.pressed.connect(_on_break)
	left.add_child(_break_btn)
	left.add_child(_sep())
	left.add_child(_label("法 器", 15, DIM))
	# 打磨-13: 法器列表可滚动 (10 件避免低分辨率下超出屏幕)
	var shop_scroll := ScrollContainer.new()
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(shop_scroll)
	_shop_box = VBoxContainer.new()
	_shop_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_box.add_theme_constant_override("separation", 10)
	shop_scroll.add_child(_shop_box)
	for it in GameData.ITEMS:
		_add_shop_row(it)

	# 右: 境界阶梯 (打磨-10: 含仙界道行阶梯, 可滚动)
	var right := _add_panel(wrap)
	right.add_child(_label("境 界 阶 梯", 15, DIM))
	right.add_child(_sep())
	var rscroll := ScrollContainer.new()
	rscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rscroll)
	var rbox := VBoxContainer.new()
	rbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rbox.add_theme_constant_override("separation", 4)
	rscroll.add_child(rbox)
	for i in GameData.REALMS.size():
		var r: Dictionary = GameData.REALMS[i]
		var rl := _label("%s × %d 层  (灵气x%s)" % [r["name"], r["layers"], GameData.fmt(GameData.QI_MULT[i])], 14, WHITEISH)
		rbox.add_child(rl)
		_realm_ladder.append(rl)
	# 仙界道行 (飞升后解锁, 每阶灵气 x2)
	rbox.add_child(_sep())
	rbox.add_child(_label("仙界道行 (飞升后解锁, 每阶灵气 x%d)" % int(GameData.IMMORTAL_STAGE_MULT), 13, DIM))
	for i in GameData.IMMORTAL_REALMS.size():
		var nm: String = GameData.IMMORTAL_REALMS[i]
		var il := _label("%s  (x%.0f)" % [nm, pow(2.0, float(i))], 14, WHITEISH)
		rbox.add_child(il)
		_immortal_ladder.append(il)
	# 打磨-18: 阶梯高亮随当前境界/道行阶段动态移动 (初始刷一次)
	_refresh_ladder()
	var hint := _label("挂机自动积累灵气与灵石, 灵气攒够后点击突破。境界越高, 挂机越快。\n飞升后改修道行: 道行每阶灵气 x2, 直至道祖。", 13, DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rbox.add_child(hint)


func _add_shop_row(it: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.tooltip_text = GameData.item_detail(it["id"] as String)
	_shop_box.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	info.add_child(_label(it["name"] as String, 15, WHITEISH))
	info.add_child(_label("%s · 灵气x%.1f" % [it["desc"], it["boost"]], 13, DIM))
	info.add_child(_label("灵石 %s" % GameData.fmt(it["cost"]), 13, GOLD))
	# 打磨-12: 购买 ETA 提示 (买不起时显示预计时间, 买得起时隐藏)
	var eta_l := _label("", 13, DIM)
	info.add_child(eta_l)
	_shop_eta[it["id"] as String] = eta_l
	var btn := _make_button("购买")
	btn.pressed.connect(_on_buy.bind(it["id"]))
	row.add_child(btn)
	_shop_rows[it["id"] as String] = btn
	_shop_row_nodes[it["id"] as String] = row


# ---------- 技能页 ----------

func _build_skill_page(page: Panel) -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_top = 8
	outer.offset_right = -10
	outer.offset_bottom = -8
	outer.add_theme_constant_override("separation", 8)
	page.add_child(outer)

	var filter_bar := HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 8)
	outer.add_child(filter_bar)
	var all_btn := _make_button("全部")
	all_btn.toggle_mode = true
	all_btn.pressed.connect(_on_filter.bind(""))
	filter_bar.add_child(all_btn)
	_filter_btns[""] = all_btn
	for cat in GameData.SKILL_CAT_CN:
		var b := _make_button(GameData.SKILL_CAT_CN[cat] as String)
		b.toggle_mode = true
		b.pressed.connect(_on_filter.bind(str(cat)))
		filter_bar.add_child(b)
		_filter_btns[cat] = b
	# 打磨-20: 品质筛选行 (凡品~仙品, 与类别筛选叠加生效)
	var tier_bar := HBoxContainer.new()
	tier_bar.add_theme_constant_override("separation", 8)
	outer.add_child(tier_bar)
	var t_all := _make_button("全部品质")
	t_all.toggle_mode = true
	t_all.pressed.connect(_on_tier_filter.bind(""))
	tier_bar.add_child(t_all)
	_tier_btns[""] = t_all
	for t in [0, 1, 2, 3, 4, 5]:
		var tb := _make_button(GameData.skill_tier_name(t))
		tb.toggle_mode = true
		tb.pressed.connect(_on_tier_filter.bind(str(t)))
		tier_bar.add_child(tb)
		_tier_btns[str(t)] = tb
	# 打磨-23: 一键领悟 (与当前 类别/品质 筛选叠加, 批量学习全部 可学 技能)
	var tier_sp := Control.new()
	tier_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tier_bar.add_child(tier_sp)
	_learn_all_btn = _make_button("一键领悟")
	_learn_all_btn.pressed.connect(_on_learn_all)
	tier_bar.add_child(_learn_all_btn)

	# 顶栏: 总加成汇总 (打磨-9)
	var bonus_l := _label(GameData.bonus_summary_text(), 14, GOLD)
	outer.add_child(bonus_l)
	_bonus_labels.append(bonus_l)
	_bonus_text = GameData.bonus_summary_text()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_skill_box = VBoxContainer.new()
	_skill_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_skill_box)
	for id in GameData.skill_ids:
		_add_skill_row(id)


func _add_skill_row(id: String) -> void:
	var s: Dictionary = GameData.skill_by_id[id]
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _card_sb_normal)
	row.tooltip_text = GameData.skill_detail(id)
	_skill_box.add_child(row)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hb.add_child(info)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)
	name_row.add_child(_label(s["name"] as String, 15, GameData.TIER_COLOR[int(s["tier"])]))
	name_row.add_child(_label(s["tier_name"] as String, 13, DIM))
	var is_active := str(s["type"]) == "active"
	name_row.add_child(_label("[" + ("神通" if is_active else "功法") + "] " + str(s["category_name"]), 13, CYAN if is_active else DIM))
	info.add_child(_label(s["desc"] as String, 13, WHITEISH))
	info.add_child(_label("领悟条件: %s 第%d层" % [GameData.REALMS[int(s["unlock_realm"])]["name"], int(s["unlock_layer"])], 12, DIM))

	var btn := _make_button("领悟")
	btn.custom_minimum_size = Vector2(76, 0)
	btn.pressed.connect(_on_skill_btn.bind(id, is_active))
	hb.add_child(btn)
	_skill_btns[id] = btn
	_skill_row_nodes[id] = row


func _on_filter(cat: String) -> void:
	_filter_active = cat
	for key in _filter_btns:
		var b: Button = _filter_btns[key]
		b.set_pressed_no_signal(cat == str(key))
	_apply_skill_filter()


# 打磨-20: 品质筛选 (与类别筛选叠加生效)
func _on_tier_filter(tier: String) -> void:
	_tier_active = tier
	for key in _tier_btns:
		var b: Button = _tier_btns[key]
		b.set_pressed_no_signal(tier == str(key))
	_apply_skill_filter()


# 打磨-20: 应用 类别×品质 叠加筛选 (显示/隐藏 + 排序 + 提示)
func _apply_skill_filter() -> void:
	# 排序: 已学在前, 其次按品质
	var order: Array = []
	for id in GameData.skill_ids:
		var s: Dictionary = GameData.skill_by_id[id]
		if _filter_active != "" and str(s["category"]) != _filter_active:
			continue
		if _tier_active != "" and int(s["tier"]) != int(_tier_active):
			continue
		order.append(id)
	order.sort_custom(_skill_sort)
	# 显示/隐藏
	for id in GameData.skill_ids:
		var row: Node = _skill_row_nodes[id]
		row.visible = order.has(id)
	# 重排: 按 order 顺序逐个移到末尾, 最终顺序即 order
	for idx in order.size():
		var row: Node = _skill_row_nodes[order[idx]]
		_skill_box.move_child(row, _skill_box.get_child_count() - 1)
	var msg := "筛选: "
	msg += (_filter_active if _filter_active != "" else "全部类别")
	if _tier_active != "":
		msg += " · " + GameData.skill_tier_name(int(_tier_active))
	else:
		msg += " · 全部品质"
	_show_msg(msg)


func _skill_sort(a: String, b: String) -> bool:
	var sa: Dictionary = GameData.skill_by_id[a]
	var sb2: Dictionary = GameData.skill_by_id[b]
	var a_learned := int(GameData.learned.has(a))
	var b_learned := int(GameData.learned.has(b))
	if a_learned != b_learned:
		return a_learned < b_learned
	if int(sa["tier"]) != int(sb2["tier"]):
		return int(sa["tier"]) < int(sb2["tier"])
	return a < b


func _on_skill_btn(id: String, is_active: bool) -> void:
	if is_active:
		_show_msg(GameData.use_active_skill(id))
	else:
		_show_msg(GameData.learn_skill(id))


# 打磨-23: 一键领悟 (与当前 类别/品质 筛选叠加; 只学 未学+境界足够 的)
func _on_learn_all() -> void:
	var tier_i := int(_tier_active) if _tier_active != "" else -1
	var r: Dictionary = GameData.learn_all_available(_filter_active, tier_i)
	if int(r["count"]) > 0:
		var msg := "一键领悟 %d 个技能" % int(r["count"])
		msg += (", " + GameData.skill_tier_name(int(_tier_active))) if _tier_active != "" else ""
		_show_msg(msg)
	else:
		_show_msg("当前境界下没有可领悟的新技能 (或筛选范围内已全部领悟)")


# 打磨-23: 一键购买 (价格升序连买, 灵石花到买不起为止)
func _on_buy_all() -> void:
	var r: Dictionary = GameData.buy_affordable()
	if int(r["count"]) > 0:
		_show_msg("一键购买 %d 件装备 (槽位空时已自动穿戴)" % int(r["count"]))
	else:
		_show_msg("当前灵石买不起任何一件未拥有的装备")


# ---------- 装备页 ----------

func _build_equip_page(page: Panel) -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_top = 8
	outer.offset_right = -10
	outer.offset_bottom = -8
	outer.add_theme_constant_override("separation", 10)
	page.add_child(outer)

	# 已穿戴槽位
	var slot_bar := HBoxContainer.new()
	slot_bar.add_theme_constant_override("separation", 10)
	outer.add_child(slot_bar)
	for slot in GameData.SLOTS:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 4)
		slot_bar.add_child(cell)
		cell.add_child(_label(GameData.SLOT_CN[slot] as String, 14, DIM))
		var name_l := _label("(空)", 15, WHITEISH)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(name_l)
		_slot_labels[slot] = name_l
		var btn := _make_button("卸下")
		btn.pressed.connect(_on_unequip.bind(slot))
		cell.add_child(btn)

	# 部位筛选 (打磨-11: 140 件按部位过滤, 降低查找成本)
	var eq_filter_bar := HBoxContainer.new()
	eq_filter_bar.add_theme_constant_override("separation", 8)
	outer.add_child(eq_filter_bar)
	var eq_all := _make_button("全部")
	eq_all.toggle_mode = true
	eq_all.pressed.connect(_on_equip_filter.bind(""))
	eq_filter_bar.add_child(eq_all)
	_equip_filter_btns[""] = eq_all
	for slot in GameData.SLOTS:
		var eb := _make_button(GameData.SLOT_CN[slot] as String)
		eb.toggle_mode = true
		eb.pressed.connect(_on_equip_filter.bind(slot))
		eq_filter_bar.add_child(eb)
		_equip_filter_btns[slot] = eb
	# 打磨-21: 装备品质筛选行 (凡品~神品 7 档, 与部位筛选叠加生效)
	var eq_tier_bar := HBoxContainer.new()
	eq_tier_bar.add_theme_constant_override("separation", 8)
	outer.add_child(eq_tier_bar)
	var et_all := _make_button("全部品质")
	et_all.toggle_mode = true
	et_all.pressed.connect(_on_equip_tier_filter.bind(""))
	eq_tier_bar.add_child(et_all)
	_equip_tier_btns[""] = et_all
	for t in 7:
		var etb := _make_button(GameData.equip_tier_name(t))
		etb.toggle_mode = true
		etb.pressed.connect(_on_equip_tier_filter.bind(str(t)))
		eq_tier_bar.add_child(etb)
		_equip_tier_btns[str(t)] = etb
	# 打磨-23: 一键购买 (连续买下当前所有买得起的装备, 槽位空时自动穿戴)
	var eq_sp := Control.new()
	eq_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_tier_bar.add_child(eq_sp)
	_buy_all_btn = _make_button("一键购买")
	_buy_all_btn.pressed.connect(_on_buy_all)
	eq_tier_bar.add_child(_buy_all_btn)

	# 装备列表 (已拥有=穿戴, 未拥有=购买)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_equip_box = VBoxContainer.new()
	_equip_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_equip_box)
	for id in GameData.equip_ids:
		_add_equip_row(id)


func _add_equip_row(id: String) -> void:
	var e: Dictionary = GameData.equip_by_id[id]
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _card_sb_normal)
	row.tooltip_text = GameData.equip_detail(id)
	_equip_box.add_child(row)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hb.add_child(info)
	info.add_child(_label("%s · %s" % [e["name"], e["slot_name"]], 15, GameData.TIER_COLOR[int(e["tier"])]))
	info.add_child(_label(e["desc"] as String, 13, WHITEISH))
	info.add_child(_label("灵石 %s" % GameData.fmt(float(e["cost"])), 13, GOLD))
	# 打磨-12: 购买 ETA 提示 (未拥有且买不起时显示预计时间)
	var eta_l := _label("", 13, DIM)
	info.add_child(eta_l)
	_equip_eta[id] = eta_l
	var btn := _make_button("购买")
	btn.custom_minimum_size = Vector2(76, 0)
	btn.pressed.connect(_on_equip_btn.bind(id))
	hb.add_child(btn)
	_equip_btns[id] = btn
	_equip_row_nodes[id] = row


# ---------- 成就页 ----------

func _build_ach_page(page: Panel) -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_top = 8
	outer.offset_right = -10
	outer.offset_bottom = -8
	outer.add_theme_constant_override("separation", 8)
	page.add_child(outer)

	# 顶栏: 进度统计
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	outer.add_child(head)
	_ach_count_label = _label("成就 0/0", 16, GOLD)
	head.add_child(_ach_count_label)
	var hint := _label("达成条件即自动解锁, 悬停条目可查看详情", 13, DIM)
	head.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_ach_box = VBoxContainer.new()
	_ach_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ach_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_ach_box)
	for id in GameData.ach_ids:
		_add_ach_row(id)


func _add_ach_row(id: String) -> void:
	var a: Dictionary = GameData.ach_by_id[id]
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _card_sb_normal)
	_ach_box.add_child(row)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hb.add_child(info)
	var name_l := _label("☆ " + (a["name"] as String), 15, DIM)
	info.add_child(name_l)
	var desc_l := _label(a["desc"] as String, 13, WHITEISH)
	info.add_child(desc_l)
	# 进度标签 + 解锁提示 (解锁时换色/换文案, 变化时才刷)
	var prog_l := _label(GameData.ach_progress(id), 13, DIM)
	info.add_child(prog_l)
	# tooltip: 名称/条件/进度
	row.tooltip_text = "成就「%s」\n条件: %s" % [a["name"], a["desc"]]
	_ach_rows[id] = {
		"row": row, "name_l": name_l, "desc_l": desc_l, "prog_l": prog_l,
	}


# ---------- 每帧刷新 ----------

func _refresh() -> void:
	var g := GameData
	var realm_mult := g.qi_mult_realm()
	_realm_label.text = "境界: %s · 灵气x%s" % [g.realm_display(), g.fmt(realm_mult)]
	# tooltip: 倍率构成 (境界基础含道行 / 功法装备 / 法器 / 道行), 仅在数值变化时刷新
	var tip := "境界灵气倍率 x%s  |  功法/装备 x%.2f  |  法器 x%.1f  |  道行 x%.0f  |  当前速率 %s/秒" % [
		g.fmt(realm_mult), g.qi_mult_skill_equip(), g.item_boost(), g.immortal_mult(), g.fmt(g.qi_per_sec())]
	if tip != _realm_tip:
		_realm_tip = tip
		_realm_label.tooltip_text = tip
	_essence_label.text = g.primary_res_text()  # 打磨-19: 顶栏主资源 (未飞升=灵气 / 飞升后=道行)
	_stones_label.text = "灵石 %s" % g.fmt(g.stones)
	var rate_txt := g.fmt(g.qi_per_sec())
	_qi_label.text = ("道行速率  %s /秒" if g.ascended else "灵气速率  %s /秒") % rate_txt
	_stone_rate_label.text = "灵石速率  %s /秒" % g.fmt(g.stone_per_sec())
	# 打磨-13: 离线每小时收益 (文本变化时才刷)
	var off_t: String = g.offline_hourly_text()
	if off_t != _offline_text:
		_offline_text = off_t
		_offline_label.text = off_t
	# 打磨-14: 修行统计 (文本变化时才刷)
	var st_t: String = g.stats_text()
	if st_t != _stats_text:
		_stats_text = st_t
		_stats_label.text = st_t
	_progress_label.text = ("道行进度  %d%%" if g.ascended else "突破进度  %d%%") % int(g.breakthrough_progress())
	# 打磨-24: 突破/道行精进 ETA (每帧算一次, 文本变化才写)
	var bet_t: String = g.breakthrough_eta_text()
	if bet_t != _break_eta_text:
		_break_eta_text = bet_t
		_break_eta_label.text = bet_t
	_bar_fill.size = Vector2(_bar_bg.size.x * g.breakthrough_progress() / 100.0, _bar_bg.size.y)
	if g.ascended:
		if g.dao_level >= g.IMMORTAL_REALMS.size() - 1:
			_break_btn.text = "已至道祖 · 道法自然 ♪"
			_break_btn.disabled = true
		else:
			_break_btn.text = "修炼道行 · 耗 %s 道行 (成功率%0.0f%%)" % [g.fmt(g.dao_break_cost()), g.dao_break_chance() * 100.0]
			_break_btn.disabled = false
	else:
		_break_btn.text = "尝试突破 · 耗 %s 灵气 (成功率%0.0f%%)" % [g.fmt(g.breakthrough_cost()), g.breakthrough_chance() * 100.0]
		_break_btn.disabled = false
	# 法器
	for id in _shop_rows:
		var btn: Button = _shop_rows[id]
		var it: Dictionary = _find_item(id)
		if g.owned.has(id):
			btn.text = "已拥有"
			btn.disabled = true
		else:
			btn.text = "购买"
			btn.disabled = g.stones < it["cost"]
	# 技能
	for id in _skill_btns:
		var s: Dictionary = GameData.skill_by_id[id]
		var btn: Button = _skill_btns[id]
		if str(s["type"]) == "active":
			if not g.learned.has(id):
				btn.text = "未领悟"
				btn.disabled = true
			elif not g.active_ready(id):
				btn.text = "冷却%d秒" % g.active_cd_left(id)
				btn.disabled = true
			else:
				btn.text = "施展"
				btn.disabled = false
		else:
			if g.learned.has(id):
				btn.text = "已领悟"
				btn.disabled = true
			elif g.can_learn(id):
				btn.text = "领悟"
				btn.disabled = false
			else:
				btn.text = "未解锁"
				btn.disabled = true
	# 装备
	for id in _equip_btns:
		var e: Dictionary = GameData.equip_by_id[id]
		var btn: Button = _equip_btns[id]
		if not g.owned_eq.has(id):
			btn.text = "购买"
			btn.disabled = g.stones < float(e["cost"])
		else:
			var worn: bool = str(g.equipped.get(e["slot"], "")) == id
			btn.text = "已穿戴" if worn else "穿戴"
			btn.disabled = worn
	# 打磨-23: 批量按钮 (境界/灵石/已学数变化时才刷, 避免每帧写文本)
	var ll_avail := 0
	for sid in g.skill_ids:
		if not g.learned.has(sid) and g.can_learn(sid):
			ll_avail += 1
	var ll_txt := ("一键领悟 x%d" if ll_avail > 0 else "已无新技能")
	var buy_n := 0
	for eid in g.equip_ids:
		var ee: Dictionary = g.equip_by_id[eid]
		if not g.owned_eq.has(eid) and g.stones >= float(ee["cost"]):
			buy_n += 1
	var ba_txt := ("一键购买 x%d" if buy_n > 0 else "灵石不足")
	if _learn_all_btn.text != ll_txt:
		_learn_all_btn.text = ll_txt
	if _buy_all_btn.text != ba_txt:
		_buy_all_btn.text = ba_txt
	# 槽位
	for slot in g.SLOTS:
		(_slot_labels[slot] as Label).text = g.equipped_name(slot)
	# 状态高亮: 已学技能 / 已穿戴装备 金色边框 (仅状态变化时应用, 避免每帧重刷)
	for id in _skill_row_nodes:
		_apply_card_hl(_skill_row_nodes[id], g.learned.has(id))
	for id in _equip_row_nodes:
		var e: Dictionary = g.equip_by_id[id]
		_apply_card_hl(_equip_row_nodes[id], str(g.equipped.get(str(e["slot"]), "")) == id)
	# 打磨-22: 装备列表按状态重排 (购买/穿戴/卸下 时状态快照变化才真正重排)
	_resort_equip()
	# 打磨-9: tooltip 状态行 (已领悟/已穿戴/已拥有 变化时才重建文本)
	for id in _skill_row_nodes:
		var row: Node = _skill_row_nodes[id]
		if int(row.get_meta("_dk", -1)) != int(g.learned.has(id)):
			row.set_meta("_dk", int(g.learned.has(id)))
			row.tooltip_text = g.skill_detail(id)
	for id in _equip_row_nodes:
		var e2: Dictionary = g.equip_by_id[id]
		var row2: Node = _equip_row_nodes[id]
		var st := 0
		if str(g.equipped.get(str(e2["slot"]), "")) == id:
			st = 2
		elif g.owned_eq.has(id):
			st = 1
		if int(row2.get_meta("_dk", -1)) != st:
			row2.set_meta("_dk", st)
			row2.tooltip_text = g.equip_detail(id)
	for id in _shop_row_nodes:
		var row3: Node = _shop_row_nodes[id]
		if int(row3.get_meta("_dk", -1)) != int(g.owned.has(id)):
			row3.set_meta("_dk", int(g.owned.has(id)))
			row3.tooltip_text = g.item_detail(id)
	# 打磨-9: 总加成汇总 (文本变化时才刷)
	var bt: String = g.bonus_summary_text()
	if bt != _bonus_text:
		_bonus_text = bt
		for l in _bonus_labels:
			l.text = bt
	# 成就: 计数 + 已解锁高亮/进度 (解锁数变化时刷样式, 进度文本仅文本变化时刷)
	var done_n: int = g.ach_done.size()
	if done_n != _ach_hl_seq:
		_ach_hl_seq = done_n
		_ach_count_label.text = "成就 %d/%d" % [done_n, g.ach_ids.size()]
		for id in _ach_rows:
			var r: Dictionary = _ach_rows[id]
			var hi: bool = g.ach_done.has(id)
			_apply_card_hl(r["row"], hi)
			var nl: Label = r["name_l"]
			nl.text = ("★ " if hi else "☆ ") + str(r["name_l"].text).trim_prefix("★ ").trim_prefix("☆ ")
			nl.add_theme_color_override("font_color", GOLD if hi else DIM)
			var pl: Label = r["prog_l"]
			pl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55) if hi else DIM)
			pl.text = g.ach_progress(id)
	for id in _ach_rows:
		var pl2: Label = _ach_rows[id]["prog_l"]
		var pt: String = g.ach_progress(id)
		if pl2.text != pt:
			pl2.text = pt
	# 打磨-12: 购买 ETA (1 秒节流刷一次, 仅文本变化时写)
	_eta_acc += get_process_delta_time()
	if _eta_acc >= 1.0:
		_eta_acc = 0.0
		_refresh_eta()
	# 打磨-18: 境界阶梯高亮随当前境界/道行阶段移动 (状态变化才刷)
	_refresh_ladder()
	# 突破/道行精进闪烁: 事件序号变化时触发 (成功绿闪 / 失败红闪, 打磨-10)
	if g.break_seq != _break_flash_seq:
		_break_flash_seq = g.break_seq
		_break_flash(int(g.last_break_result))
	# 打磨-17: 成就解锁浮动提示 (与上一帧快照对比, 检测新解锁; 只增不减, 数量变化即快照)
	var fresh: Array = g.new_ach_since(_ach_prev)
	if not fresh.is_empty():
		_ach_float(fresh)
	if g.ach_done.size() != _ach_prev.size():
		_ach_prev = g.ach_done.duplicate()


# 打磨-17: 成就解锁浮动提示 (居中上浮淡出; 同一批多个解锁合并一行展示)
func _ach_float(fresh: Array) -> void:
	var names := ""
	for id in fresh:
		var a: Dictionary = GameData.ach_by_id.get(str(id), {})
		if a.is_empty():
			continue
		names += ("\n" if names != "" else "") + (a["name"] as String)
	if names == "":
		return
	_ach_float_count += 1
	_ach_float_label.text = "✦ 成就达成: " + names + " ✦"
	_ach_float_label.position = Vector2(0, -58)
	_ach_float_label.modulate = Color(1, 1, 1, 1)
	if _ach_float_tween != null and _ach_float_tween.is_valid():
		_ach_float_tween.kill()
	_ach_float_tween = create_tween()
	_ach_float_tween.tween_property(_ach_float_label, "position:y", -96.0, 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_ach_float_tween.parallel().tween_property(_ach_float_label, "modulate:a", 0.0, 1.6).set_delay(0.5)


func _apply_card_hl(row: PanelContainer, hi: bool) -> void:
	var last: bool = bool(row.get_meta("_hl", false))
	if last == hi:
		return
	row.set_meta("_hl", hi)
	row.add_theme_stylebox_override("panel", _card_sb_hi if hi else _card_sb_normal)


# 打磨-12: 刷新法器/装备行的购买 ETA (买不起才显示预计时间, 买得起隐藏)
func _refresh_eta() -> void:
	var g := GameData
	for id in _shop_eta:
		var it: Dictionary = _find_item(str(id))
		if it.is_empty():
			continue
		var l: Label = _shop_eta[id]
		var t := "" if g.owned.has(str(id)) else g.eta_text(float(it["cost"]))
		if l.text != t:
			l.text = t
	for id in _equip_eta:
		var e: Dictionary = g.equip_by_id.get(id, {})
		if e.is_empty():
			continue
		var l2: Label = _equip_eta[id]
		var t2 := "" if g.owned_eq.has(id) else g.eta_text(float(e["cost"]))
		if l2.text != t2:
			l2.text = t2


# 打磨-18: 境界阶梯高亮 (当前境界 / 飞升后当前道行阶段 金色, 其余白字; 状态变化才刷)
func _refresh_ladder() -> void:
	var g := GameData
	var key := g.realm_idx * 100 + (1000 if g.ascended else 0) + (g.dao_level if g.ascended else 0)
	if key == _ladder_key:
		return
	_ladder_key = key
	for i in _realm_ladder.size():
		var hi := (not g.ascended) and i == g.realm_idx
		(_realm_ladder[i] as Label).add_theme_color_override("font_color", GOLD if hi else WHITEISH)
	for i in _immortal_ladder.size():
		var hi2 := g.ascended and i == g.dao_level
		(_immortal_ladder[i] as Label).add_theme_color_override("font_color", GOLD if hi2 else WHITEISH)


func _make_card_sb(hi: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.19, 0.17, 0.12) if hi else CARD_BG
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.border_color = HILITE if hi else Color(0, 0, 0, 0)
	sb.set_border_width_all(2 if hi else 0)
	return sb


func _find_item(item_id: String) -> Dictionary:
	for it in GameData.ITEMS:
		if it["id"] == item_id:
			return it
	return {}


# ---------- 事件 ----------

func _on_break() -> void:
	# 飞升后同一按钮用于道行精进 (打磨-10)
	var msg := GameData.try_dao_break() if GameData.ascended else GameData.try_breakthrough()
	_show_msg(msg)
	_float_break()


func _on_buy(item_id: String) -> void:
	_show_msg(GameData.try_buy_item(item_id))


func _on_equip_btn(id: String) -> void:
	var g := GameData
	if g.owned_eq.has(id):
		_show_msg(g.equip_equipment(id))
	else:
		_show_msg(g.buy_equipment(id))


func _on_unequip(slot: String) -> void:
	_show_msg(GameData.unequip(slot))


# 打磨-11: 装备部位筛选 (显示/隐藏对应行)
func _on_equip_filter(slot: String) -> void:
	_equip_filter_active = slot
	for key in _equip_filter_btns:
		var b: Button = _equip_filter_btns[key]
		b.set_pressed_no_signal(slot == str(key))
	_apply_equip_filter()


# 打磨-21: 装备品质筛选 (与部位筛选叠加生效)
func _on_equip_tier_filter(tier: String) -> void:
	_equip_tier_active = tier
	for key in _equip_tier_btns:
		var b: Button = _equip_tier_btns[key]
		b.set_pressed_no_signal(tier == str(key))
	_apply_equip_filter()


# 打磨-21: 应用 部位×品质 叠加筛选 (显示/隐藏 + 提示)
# 打磨-22: 顺带按状态重排 (已穿戴 > 已拥有 > 未拥有), 避免买到的装备沉在长列表底部
func _apply_equip_filter() -> void:
	_resort_equip()
	for id in _equip_row_nodes:
		var e: Dictionary = GameData.equip_by_id[id]
		var row: Node = _equip_row_nodes[id]
		row.visible = (_equip_filter_active == "" or str(e["slot"]) == _equip_filter_active) \
			and (_equip_tier_active == "" or int(e["tier"]) == int(_equip_tier_active))
	var msg := "装备筛选: " + (str(GameData.SLOT_CN[_equip_filter_active]) if _equip_filter_active != "" else "全部部位")
	msg += (" · " + GameData.equip_tier_name(int(_equip_tier_active)) if _equip_tier_active != "" else " · 全部品质")
	_show_msg(msg)


# 打磨-22: 状态快照变化时才重排 (购买/穿戴/卸下/读档触发, 避免每帧重排 140 行)
func _resort_equip() -> void:
	var cur: Array = []
	for id in GameData.equip_ids:
		cur.append(GameData.equip_state(id))
	if cur.size() != _eq_states.size() or _states_diff(cur):
		_eq_states = cur
		var order: Array = GameData.equip_sort_order()
		for idx in order.size():
			var row: Node = _equip_row_nodes[order[idx]]
			_equip_box.move_child(row, _equip_box.get_child_count() - 1)


func _states_diff(cur: Array) -> bool:
	for i in cur.size():
		if int(cur[i]) != int(_eq_states[i]):
			return true
	return false


func _show_msg(text: String) -> void:
	_msg_label.text = text
	_msg_label.modulate = Color.WHITE
	if _msg_tween != null and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_interval(4.0)
	_msg_tween.tween_property(_msg_label, "modulate", Color(1, 1, 1, 0), 1.5)


# 突破浮动提示: 屏幕中央上浮淡出, 成功绿/飞升金/失败红
func _float_break() -> void:
	if GameData.last_break_result == 0:
		return
	match GameData.last_break_result:
		1:
			_float_label.text = "✦ 突破成功! ✦"
			_float_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55))
		2:
			_float_label.text = "✖ 道行精进失败… ✖" if GameData.ascended else "✖ 突破失败… ✖"
			_float_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		3:
			_float_label.text = "☀ 飞升真仙! 仙凡两隔 ☀"
			_float_label.add_theme_color_override("font_color", GOLD)
		4:
			_float_label.text = "✦ 道行精进! ✦"
			_float_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55))
		_:
			_float_label.text = "✖ 突破失败… ✖"
			_float_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	_float_label.position = Vector2(0, 12)
	_float_label.modulate = Color(1, 1, 1, 1)
	if _float_tween != null and _float_tween.is_valid():
		_float_tween.kill()
	_float_tween = create_tween()
	_float_tween.tween_property(_float_label, "position:y", -36.0, 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.parallel().tween_property(_float_label, "modulate:a", 0.0, 1.6).set_delay(0.5)


# 突破按钮闪烁: 成功绿闪 / 失败红闪, 闪烁后恢复默认样式
func _break_flash(result: int) -> void:
	if _break_btn == null or _break_btn.disabled:
		return
	var col := Color(0.3, 0.9, 0.3) if (result == 1 or result == 4) else Color(1.0, 0.4, 0.35)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r * 0.22, col.g * 0.22, col.b * 0.22, 1.0)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_flash_sb = sb
	_flash_left = 16   # 每 4 帧切换一次, 共 16 帧 ≈ 0.55s
	_flash_step()


# 突破按钮闪烁步进 (每帧调用; 闪色 4 帧 / 恢复 4 帧 / 闪色 4 帧 / 恢复 8 帧)
func _flash_step() -> void:
	if _flash_left <= 0:
		return
	_flash_left -= 1
	var hi := (_flash_left % 8) < 4
	var sb := _flash_sb if hi else _btn_sb_normal
	_break_btn.add_theme_stylebox_override("normal", sb)
	_break_btn.add_theme_stylebox_override("hover", sb)
	_break_btn.add_theme_stylebox_override("pressed", sb)
	if _flash_left == 0:
		_break_btn.add_theme_stylebox_override("normal", _btn_sb_normal)
		_break_btn.add_theme_stylebox_override("hover", _btn_sb_normal.duplicate())
		_break_btn.add_theme_stylebox_override("pressed", _btn_sb_normal.duplicate())


# ---------- 小工具 ----------

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _sep() -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.25, 0.27, 0.34)
	c.custom_minimum_size = Vector2(0, 2)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _add_panel(parent: Control) -> VBoxContainer:
	var p := Panel.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(10)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.add_theme_constant_override("separation", 8)
	p.add_child(box)
	return box


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.7))
	b.add_theme_color_override("font_pressed_color", Color(1, 0.9, 0.5))
	b.add_theme_stylebox_override("normal", _btn_sb_normal)
	var sh := _btn_sb_normal.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.2, 0.22, 0.3)
	b.add_theme_stylebox_override("hover", sh)
	var spb := _btn_sb_normal.duplicate() as StyleBoxFlat
	spb.bg_color = Color(0.05, 0.06, 0.08)
	b.add_theme_stylebox_override("pressed", spb)
	return b


func _make_btn_sb_normal() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.16, 0.17, 0.23)
	s.border_color = Color(0.3, 0.35, 0.45)
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
