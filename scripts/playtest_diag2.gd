extends Node
## 汇总行 seg 按钮布局测量：各 seg_btn / 前缀 Label rect + 最小尺寸 + HBox 分配。


var ui: Node = null


func _ready() -> void:
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	await get_tree().create_timer(1.0).timeout
	var sp: Panel = ui._auto_sum_panel
	var box: Control = ui._auto_sum_box if sp != null and ui._auto_sum_box != null else null
	if box == null:
		var kids: Array = sp.get_children()
		box = kids[0] if kids.size() > 0 else null
	if box is Control:
		for i in box.get_child_count():
			var c: Control = box.get_child(i)
			var txt := String(c.get("text")) if c.get("text") != null else ""
			var kids: Array = []
			for k in c.get_children():
				if k is Control:
					kids.append([k.name, k.get_class(), String(k.get("text")) if k.get("text") != null else "", (k as Control).get_global_rect()])
			print("child[", i, "] ", c.name, " cls=", c.get_class(), " rect=", (c as Control).get_global_rect(), " min=", (c as Control).get_combined_minimum_size(), " txt='", txt, "'", " kids=", kids)
	else:
		print("box not found")
	get_tree().quit()


func _find_named(n: Node, prop: String) -> Node:
	if n.get(prop) != null and n.get(prop) is Control:
		return n.get(prop)
	for c in n.get_children():
		var r: Node = _find_named(c, prop)
		if r != null:
			return r
	return null
