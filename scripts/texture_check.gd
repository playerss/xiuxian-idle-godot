# 打磨-134 纹理入库验证: 逐个加载 assets/ui/ 下 10 张 PNG, 校验尺寸/非空, 全过则输出 PASS
extends SceneTree

const EXPECT := {
	"panel_border.png": Vector2i(48, 48),
	"panel_border_slim.png": Vector2i(48, 48),
	"panel_frame_frost.png": Vector2i(48, 48),
	"divider.png": Vector2i(96, 22),
	"btn_primary.png": Vector2i(192, 64),
	"btn_primary_hover.png": Vector2i(192, 64),
	"btn_primary_pressed.png": Vector2i(192, 64),
	"btn_secondary.png": Vector2i(64, 64),
	"bar_track.png": Vector2i(96, 16),
	"bar_fill.png": Vector2i(192, 64),
}

func _initialize() -> void:
	var fail := 0
	for f in EXPECT:
		var p: String = "res://assets/ui/" + f
		if not ResourceLoader.exists(p):
			print("FAIL %s: resource missing" % p); fail += 1; continue
		var t := load(p)
		if t == null:
			print("FAIL %s: load returned null (import error?)" % f); fail += 1; continue
		var t2 := t as Texture2D
		if t2 == null:
			print("FAIL %s: not a Texture2D (%s)" % [f, t.get_class()]); fail += 1; continue
		var sz := t2.get_size()
		var want: Vector2i = EXPECT[f]
		if sz != Vector2(want.x, want.y):
			print("FAIL %s: size %s != %s" % [f, sz, want]); fail += 1; continue
		# 内容非空: 采样一个角点像素有 alpha (边框图角部实心)
		var img := t2.get_image()
		if img == null:
			print("FAIL %s: get_image null" % f); fail += 1; continue
		if img.get_width() == 0 or img.get_height() == 0:
			print("FAIL %s: empty image" % f); fail += 1; continue
		var px_count := img.get_data().size() / 4
		if px_count == 0:
			print("FAIL %s: zero pixels" % f); fail += 1; continue
		print("OK %s %s px=%d" % [f, sz, px_count])
	# 语义抽查: panel_border 中心应透明 (013 边框中心 a=0), panel_frame_frost 中心应半透明 (a~127)
	var pb := (load("res://assets/ui/panel_border.png") as Texture2D).get_image().get_pixel(24, 24)
	if pb.a > 0.1:
		print("FAIL panel_border center should be transparent (a=%.2f)" % pb.a)
		fail += 1
	else:
		print("OK panel_border center transparent")
	var ff := (load("res://assets/ui/panel_frame_frost.png") as Texture2D).get_image().get_pixel(24, 24)
	if ff.a < 0.4 or ff.a > 0.6:
		print("FAIL panel_frame_frost center should be semi-transparent (a=%.2f)" % ff.a)
		fail += 1
	else:
		print("OK panel_frame_frost center semi-transparent a=%.2f" % ff.a)
	if fail > 0:
		print("TEXTURE CHECK FAIL (%d)" % fail)
		quit(1)
	else:
		print("TEXTURE CHECK PASS (12 项)")
		quit(0)
