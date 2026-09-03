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
var _equip_box: VBoxContainer
var _equip_row_nodes: Dictionary = {}
var _equip_btns: Dictionary = {}
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


func _ready() -> void:
	_card_sb_normal = _make_card_sb(false)
	_card_sb_hi = _make_card_sb(true)
	_btn_sb_normal = _make_btn_sb_normal()
	_build_ui()
	if GameData.offline_msg != "":
		_show_msg(GameData.offline_msg)


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
	left.add_child(_sep())
	_progress_label = _label("突破进度  0%", 14, DIM)
	left.add_child(_progress_label)
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
	_shop_box = VBoxContainer.new()
	_shop_box.add_theme_constant_override("separation", 10)
	left.add_child(_shop_box)
	for it in GameData.ITEMS:
		_add_shop_row(it)

	# 右: 境界阶梯
	var right := _add_panel(wrap)
	right.add_child(_label("境 界 阶 梯", 15, DIM))
	right.add_child(_sep())
	for i in GameData.REALMS.size():
		var r: Dictionary = GameData.REALMS[i]
		var name_c := GOLD if i == GameData.realm_idx else WHITEISH
		right.add_child(_label("%s × %d 层  (灵气x%.0f)" % [r["name"], r["layers"], GameData.QI_MULT[i]], 14, name_c))
	var hint := _label("挂机自动积累灵气与灵石, 灵气攒够后点击突破。境界越高, 挂机越快。", 13, DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(hint)


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
	# 排序: 已学在前, 其次按品质
	var order: Array = []
	for id in GameData.skill_ids:
		var s: Dictionary = GameData.skill_by_id[id]
		if _filter_active != "" and str(s["category"]) != _filter_active:
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
	_show_msg("筛选: " + (_filter_active if _filter_active != "" else "全部"))


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
	_realm_label.text = "境界: %s %s · 灵气x%s" % [g.realm_name(), g.layer_name(), g.fmt(realm_mult)]
	# tooltip: 倍率构成 (境界基础 / 功法装备 / 法器), 仅在数值变化时刷新
	var tip := "境界灵气倍率 x%s  |  功法/装备 x%.2f  |  法器 x%.1f  |  当前灵气速率 %s/秒" % [
		g.fmt(realm_mult), g.qi_mult_skill_equip(), g.item_boost(), g.fmt(g.qi_per_sec())]
	if tip != _realm_tip:
		_realm_tip = tip
		_realm_label.tooltip_text = tip
	_essence_label.text = "灵气 %s" % g.fmt(g.essence)
	_stones_label.text = "灵石 %s" % g.fmt(g.stones)
	_qi_label.text = "灵气速率  %s /秒" % g.fmt(g.qi_per_sec())
	_stone_rate_label.text = "灵石速率  %s /秒" % g.fmt(g.stone_per_sec())
	_progress_label.text = "突破进度  %d%%" % int(g.breakthrough_progress())
	_bar_fill.size = Vector2(_bar_bg.size.x * g.breakthrough_progress() / 100.0, _bar_bg.size.y)
	if g.ascended:
		_break_btn.text = "已飞升真仙 · 仙凡两隔 ♪"
		_break_btn.disabled = true
	else:
		_break_btn.text = "尝试突破 · 耗 %s 灵气 (成功率%0.0f%%)" % [g.fmt(g.breakthrough_cost()), g.breakthrough_chance() * 100.0]
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
	# 槽位
	for slot in g.SLOTS:
		(_slot_labels[slot] as Label).text = g.equipped_name(slot)
	# 状态高亮: 已学技能 / 已穿戴装备 金色边框 (仅状态变化时应用, 避免每帧重刷)
	for id in _skill_row_nodes:
		_apply_card_hl(_skill_row_nodes[id], g.learned.has(id))
	for id in _equip_row_nodes:
		var e: Dictionary = g.equip_by_id[id]
		_apply_card_hl(_equip_row_nodes[id], str(g.equipped.get(str(e["slot"]), "")) == id)
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
	# 突破闪烁: 事件序号变化时触发 (成功绿闪 / 失败红闪)
	if not g.ascended and g.break_seq != _break_flash_seq:
		_break_flash_seq = g.break_seq
		_break_flash(int(g.last_break_result))


func _apply_card_hl(row: PanelContainer, hi: bool) -> void:
	var last: bool = bool(row.get_meta("_hl", false))
	if last == hi:
		return
	row.set_meta("_hl", hi)
	row.add_theme_stylebox_override("panel", _card_sb_hi if hi else _card_sb_normal)


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
	var msg := GameData.try_breakthrough()
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
		3:
			_float_label.text = "☀ 飞升真仙! 仙凡两隔 ☀"
			_float_label.add_theme_color_override("font_color", GOLD)
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
	var col := Color(0.3, 0.9, 0.3) if result == 1 else Color(1.0, 0.4, 0.35)
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
