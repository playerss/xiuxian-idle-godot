extends Node
## 突破区 break_box 各按钮全局 rect 测量：判 右缘越界/裁切（真实渲染窗口下量一次即退）。

var ui: Node = null


func _ready() -> void:
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	await get_tree().create_timer(1.0).timeout
	var vp_size: Vector2 = get_window().get_visible_rect().size
	print("VP=", vp_size)
	var panel: Panel = ui._break_panel
	if panel != null:
		print("break_panel rect=", panel.get_global_rect())
		var box: Node = panel.get_child(0)
		print("break_box rect=", (box as Control).get_global_rect(), " clip=", (box as Control).clip_contents)
		for i in box.get_child_count():
			var c: Control = box.get_child(i)
			var r: Rect2 = c.get_global_rect()
			var txt := ""
			if c.get("text") != null:
				txt = String(c.get("text"))
			var over := ""
			if r.end.x > vp_size.x - 1 and txt != "":
				over = " <== OVERFLOW"
			print("seg[%d] rect=%s right=%.1f min_w=%.1f txt='%s'%s" % [i, r, r.end.x, c.get_combined_minimum_size().x, txt.left(14), over])
	get_tree().quit()
