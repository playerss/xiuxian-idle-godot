extends Node
## 诊断: 爬塔页自动爬塔按钮 可点性
var ui: Node = null
var g: Node = null

func _ready() -> void:
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	g = get_node("/root/GameData")
	await get_tree().process_frame
	ui._tab.current_tab = 4
	await get_tree().process_frame
	var out: Array = []
	_walk(ui, out)
	var lines: Array[String] = []
	for b in out:
		var t := str(b.text)
		if t.contains("自动爬塔") or t.contains("挑战"):
			var vis: bool = b.is_visible_in_tree()
			var r: Rect2 = b.get_global_rect()
			lines.append("%s | disabled=%d vis=%d rect=%s size=%s" % [t, int(b.disabled), int(vis), str(r.position), str(r.size)])
	var f := FileAccess.open("user://tower_diag.txt", FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	print("TOWER_DIAG_DONE lines=", lines.size())
	get_tree().quit()

func _walk(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_walk(c, out)
