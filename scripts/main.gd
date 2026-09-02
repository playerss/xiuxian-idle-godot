extends Control
## 修仙挂机 · 主界面 (UI 全部代码构建)

const BG := Color(0.07, 0.08, 0.11)
const PANEL_BG := Color(0.12, 0.13, 0.18)
const GOLD := Color(0.98, 0.86, 0.5)
const CYAN := Color(0.62, 0.9, 0.95)
const DIM := Color(0.6, 0.62, 0.68)
const WHITEISH := Color(0.92, 0.92, 0.95)

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
var _msg_label: Label
var _shop_rows: Dictionary = {}
var _msg_tween: Tween


func _ready() -> void:
	_build_ui()
	if GameData.offline_msg != "":
		_show_msg(GameData.offline_msg)


func _process(_delta: float) -> void:
	_refresh()


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
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	# 顶栏
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	root.add_child(top)
	top.add_child(_label("修 仙 挂 机", 26, GOLD))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_realm_label = _label("", 20, CYAN)
	top.add_child(_realm_label)

	# 中部
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	root.add_child(mid)

	# 左面板: 修行状态
	var left := _add_panel(mid)
	left.add_child(_label("修 行 状 态", 15, DIM))
	left.add_child(_sep())
	_essence_label = _label("灵气  0", 26, GOLD)
	left.add_child(_essence_label)
	_stones_label = _label("灵石  0", 18, WHITEISH)
	left.add_child(_stones_label)
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
	var hint := _label("挂机自动积累灵气与灵石, 灵气攒够后点击突破。", 13, DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(hint)

	# 右面板: 法器阁
	var right := _add_panel(mid)
	right.add_child(_label("法 器 阁", 18, GOLD))
	right.add_child(_sep())
	_shop_box = VBoxContainer.new()
	_shop_box.add_theme_constant_override("separation", 10)
	right.add_child(_shop_box)
	for it in GameData.ITEMS:
		_add_shop_row(it)
	var tail := Control.new()
	tail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(tail)

	# 底部消息
	_msg_label = _label("", 18, GOLD)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_msg_label)


func _add_shop_row(it: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_shop_box.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	info.add_child(_label(it["name"] as String, 16, WHITEISH))
	info.add_child(_label("%s · 灵气速率 x%.1f" % [it["desc"], it["boost"]], 13, DIM))
	info.add_child(_label("灵石 %s" % GameData.fmt(it["cost"]), 14, GOLD))
	var btn := _make_button("购买")
	btn.pressed.connect(_on_buy.bind(it["id"]))
	row.add_child(btn)
	_shop_rows[it["id"] as String] = btn


# ---------- 每帧刷新 ----------

func _refresh() -> void:
	var g := GameData
	_realm_label.text = "境界: %s %s" % [g.realm_name(), g.layer_name()]
	_essence_label.text = "灵气  %s" % g.fmt(g.essence)
	_stones_label.text = "灵石  %s" % g.fmt(g.stones)
	_qi_label.text = "灵气速率  %s /秒" % g.fmt(g.qi_per_sec())
	_stone_rate_label.text = "灵石速率  %s /秒" % g.fmt(g.stone_per_sec())
	_progress_label.text = "突破进度  %d%%" % int(g.breakthrough_progress())
	_bar_fill.size = Vector2(_bar_bg.size.x * g.breakthrough_progress() / 100.0, _bar_bg.size.y)
	if g.ascended:
		_break_btn.text = "已飞升真仙 · 仙凡两隔 ♪"
		_break_btn.disabled = true
	else:
		_break_btn.text = "尝试突破 · 耗 %s 灵气" % g.fmt(g.breakthrough_cost())
	for id in _shop_rows:
		var btn: Button = _shop_rows[id]
		var it: Dictionary = _find_item(id)
		if g.owned.has(id):
			btn.text = "已拥有"
			btn.disabled = true
		else:
			btn.text = "购买"
			btn.disabled = g.stones < it["cost"]


func _find_item(item_id: String) -> Dictionary:
	for it in GameData.ITEMS:
		if it["id"] == item_id:
			return it
	return {}


# ---------- 事件 ----------

func _on_break() -> void:
	_show_msg(GameData.try_breakthrough())


func _on_buy(item_id: String) -> void:
	_show_msg(GameData.try_buy_item(item_id))


func _show_msg(text: String) -> void:
	_msg_label.text = text
	_msg_label.modulate = Color.WHITE
	if _msg_tween != null and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_interval(4.0)
	_msg_tween.tween_property(_msg_label, "modulate", Color(1, 1, 1, 0), 1.5)


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
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.16, 0.17, 0.23)
	s.border_color = Color(0.3, 0.35, 0.45)
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.2, 0.22, 0.3)
	b.add_theme_stylebox_override("hover", sh)
	var spb := s.duplicate() as StyleBoxFlat
	spb.bg_color = Color(0.05, 0.06, 0.08)
	b.add_theme_stylebox_override("pressed", spb)
	return b
