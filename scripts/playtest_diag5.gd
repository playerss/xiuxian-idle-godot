extends Node
## 诊断：突破行 y=339 上 x>930 的点分别落在哪些 Control (含 mouse_filter)，按绘制序后者优先 (后绘制在上)。

var ui: Node = null
var _z: Array = []   # (order_index, control)


func _walk(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			_z.append(c)
		_walk(c)


func _ready() -> void:
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	await get_tree().create_timer(1.0).timeout
	_walk(ui)
	var ys: Array = [339.0]
	for x in [955.0, 1079.0, 1199.0, 1300.0, 1410.0, 1540.0]:
		var hits: Array = []
		for i in _z.size():
			var c: Control = _z[i]
			var r: Rect2 = c.get_global_rect()
			var mf: int = c.get_mouse_filter()
			if r.position.x <= x and r.end.x > x and ys[0] >= r.position.y and ys[0] < r.end.y:
				hits.append("%s(%s mf=%d ord=%d)" % [c.name, c.get_class(), mf, i])
		print("x=%.0f y=339 hits: %s" % [x, ", ".join(hits)])
	get_tree().quit()
