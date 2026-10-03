extends Node
## 诊断：真实 push_input 点「自动购置」按钮，fired 判据 = stone_spent 跳升或消息提示。

var ui: Node = null


func _find_btn(n: Node, prefix: String) -> Button:
	for c in n.get_children():
		if c is Button and String(c.text).strip_edges().begins_with(prefix):
			return c
		var r := _find_btn(c, prefix)
		if r != null:
			return r
	return null


func _click(pos: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	get_viewport().push_input(m)
	var d := InputEventMouseButton.new()
	d.button_index = MOUSE_BUTTON_LEFT
	d.position = pos
	d.global_position = pos
	d.pressed = true
	get_viewport().push_input(d)
	var u := d.duplicate() as InputEventMouseButton
	u.pressed = false
	get_viewport().push_input(u)


func _ready() -> void:
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	await get_tree().create_timer(1.0).timeout
	var g: Node = get_node("/root/GameData")
	for name in ["尝试突破", "自动突破", "自动购置", "自动施展", "自动领悟", "一键挂机"]:
		var btn: Button = _find_btn(ui, name)
		if btn == null:
			print("%s: NOT-FOUND" % name)
			continue
		var r: Rect2 = btn.get_global_rect()
		var pressed0: bool = btn.button_pressed
		var togg: bool = btn.toggle_mode
		var ok0: int = int(g.stats.get("break_ok")) + int(g.stats.get("break_fail"))
		var spent0: float = g.stones
		_click(r.get_center())
		await get_tree().process_frame
		var fired: bool = false
		if togg:
			fired = btn.button_pressed != pressed0
		else:
			fired = int(g.stats.get("break_ok")) + int(g.stats.get("break_fail")) != ok0
			if not fired and g.stones != spent0:
				fired = true
		print("%s: fired=%s togg=%s rect=%s" % [name, str(fired), str(togg), r])
	get_tree().quit()
