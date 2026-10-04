extends Node
## 诊断2: 真实点击 爬塔页自动爬塔按钮 (bot 同款 push_input)
var ui: Node = null
var g: Node = null

func _ready() -> void:
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	g = get_node("/root/GameData")
	print("DIAG2 start auto_tower=", g.auto_tower)
	await get_tree().process_frame
	# 真实点 tab 4
	var tab: TabContainer = ui._tab
	var tb: TabBar = tab.get_tab_bar()
	var r: Rect2 = Rect2(tb.get_tab_rect(4))
	var pos: Vector2 = tb.get_global_position() + r.position + r.size * 0.5
	_click(pos)
	print("DIAG2 tab clicked, current=", tab.current_tab)
	for i in 6:
		await get_tree().process_frame
	# 找 自动爬塔 按钮 真实点击
	for k in 3:
		var out: Array = []
		_walk(ui, out)
		for b in out:
			if str(b.text).strip_edges().begins_with("自动爬塔") and not b.disabled and _vis_chain(b):
				var br: Rect2 = b.get_global_rect()
				_click(br.position + br.size * 0.5)
				print("DIAG2 clicked at frame loop ", k, " rect=", str(br))
				break
		for i in 6:
			await get_tree().process_frame
		print("DIAG2 auto_tower now = ", g.auto_tower)
		if bool(g.auto_tower):
			break
	var f := FileAccess.open("user://tower_diag2.txt", FileAccess.WRITE)
	f.store_string("auto_tower=%s" % str(g.auto_tower))
	f.close()
	get_tree().quit()

func _vis_chain(n: Node) -> bool:
	var p: Node = n
	while p != null and p != ui:
		if not (p as CanvasItem).is_visible_in_tree():
			return false
		p = p.get_parent()
	return true

func _click(pos: Vector2) -> void:
	var vp := get_viewport()
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
	var u := InputEventMouseButton.new()
	u.button_index = MOUSE_BUTTON_LEFT
	u.position = pos
	u.global_position = pos
	u.pressed = false
	vp.push_input(u)

func _walk(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_walk(c, out)
