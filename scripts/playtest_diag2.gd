extends Node
## A 项最终验证：修后中心点 x±20 / y=339 点 3 次 fired=3；段热区仍可点。


var ui: Node = null
var g: Node = null


func _ready() -> void:
	g = get_node("/root/GameData")
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	await get_tree().create_timer(1.2).timeout
	var t1: Button = _btn("尝试突破")
	var rect: Rect2 = t1.get_global_rect()
	var pt: Vector2 = rect.position + rect.size * 0.5
	print("BTN rect=", rect, " pt=", pt)
	var b0: float = _bk()
	for i in 3:
		g.essence = 1e9
		_click(pt + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0)))
		await get_tree().create_timer(0.45).timeout
	print("CENTER3 fired=", _bk() - b0, " expect 3 (20% fail roll ok)")
	# 段热区可点
	var sum_btn: Button = _btn("自动:")
	if sum_btn == null:
		for b in _all_btns(ui, []):
			var r: Rect2 = (b as Control).get_global_rect()
			if r.position.y > 368 and r.position.y < 395 and r.size.x > 10:
				sum_btn = b
	if sum_btn != null:
		var ab0: bool = g.auto_break
		_click((sum_btn as Control).get_global_rect().position + (sum_btn as Control).get_global_rect().size * 0.5)
		await get_tree().create_timer(0.45).timeout
		print("SEG fired: auto_break ", ab0, " -> ", g.auto_break)
	else:
		print("NO SEG BTN")
	get_tree().quit()


func _bk() -> float:
	return float(g.stats.get("break_ok", 0.0)) + float(g.stats.get("break_fail", 0.0))


func _btn(prefix: String) -> Button:
	for b in _all_btns(ui, []):
		if String(b.text).strip_edges().begins_with(prefix):
			return b
	return null


func _all_btns(n: Node, out: Array) -> Array:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_all_btns(c, out)
	return out


func _click(pos: Vector2) -> void:
	var vp: Viewport = get_viewport()
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	vp.push_input(m)
	var d := InputEventMouseButton.new()
	d.button_index = MOUSE_BUTTON_LEFT
	d.position = pos
	d.global_position = pos
	d.pressed = true
	vp.push_input(d)
	var u := d.duplicate() as InputEventMouseButton
	u.pressed = false
	vp.push_input(u)
