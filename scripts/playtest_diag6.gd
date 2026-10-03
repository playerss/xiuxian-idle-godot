extends Node
## 诊断：新双行 break_box 内部两行子控件 rect 与 右缘越界检查。

var ui: Node = null


func _ready() -> void:
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	await get_tree().create_timer(1.0).timeout
	var panel: Panel = ui._break_panel
	for row_i in 2:
		var row: Node = panel.get_child(0).get_child(row_i)
		var box: Node = row.get_child(0) if false else row
		print("ROW%d rect=%s" % [row_i, (row as Control).get_global_rect()])
		for i in row.get_child_count():
			var c: Control = row.get_child(i)
			var r: Rect2 = c.get_global_rect()
			var txt := ""
			if c.get("text") != null:
				txt = String(c.get("text"))
			var over := " <== OVERFLOW" if r.end.x > 940 and txt != "" and r.size.x > 5 else ""
			print("  [%d] %s rect=%s min=%.0f txt='%s'%s" % [i, c.name, r, c.get_combined_minimum_size().x, txt.left(18), over])
	get_tree().quit()
