extends Node
## C 项验证：低分辨率窗口 (--resolution 缩小) 下 canvas_items stretch 缩放，内容是否完整落界内。

func _ready() -> void:
	var main_sc := load("res://scenes/main.tscn")
	add_child(main_sc.instantiate())
	await get_tree().create_timer(2.5).timeout
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("user://playtest/lowres.png")
	print("LOWRES shot saved size=", img.get_size(), " win=", get_window().get_visible_rect().size)
	get_tree().quit()
