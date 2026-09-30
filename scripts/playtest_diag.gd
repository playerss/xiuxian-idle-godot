extends Node
var ui: Node = null


func _ready() -> void:
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var bp: Panel = ui._break_panel
	print("break_panel g=", bp.get_global_rect(), " size=", bp.size, " children=", bp.get_child_count())
	var bb: Control = bp.get_child(0)
	print("break_box  g=", bb.get_global_rect(), " size=", bb.size)
	for c in bb.get_children():
		if c is Button:
			print("  btn ", String(c.text).left(10), " g=", c.get_global_rect())
	var lp: Control = bp.get_parent()
	print("parent chain: ", lp.get_name(), " g=", (lp as Control).get_global_rect())
	get_tree().quit()
