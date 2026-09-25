extends Node
## M8-1 打磨-153 像素探针: SubViewport 真实渲染 monster_icon 6 类剪影 + Boss 层隐藏口径
## 用法 (需 X 环境/Xvfb, 勿加 --headless, 与 store_shots 同口径):
##   xvfb-run -a ~/bin/godot --path . res://scenes/icon_probe.tscn
## 口径: 6 类别 真实 渲染 像素 采样 — 采样区 非空 (不透明 像素 > 阈值) + 主色 命中 比例
## (颜色 = 类别 主色 单源 GameData.MONSTER_CAT_COLORS); Boss 层 (未设 类别) 区域 全 透明
## (UI 隐藏 口径 0 不透明 像素); 退出码 0/1 可 接 CI。

const W := 512
const H := 440
const CATS: Array = ["妖兽", "鬼修", "虫群", "精怪", "凶灵", "天兽"]
const TOL := 0.25        # 主色 像素 匹配 距离 容差 (抗锯齿 边缘 混色)
const MIN_BODY := 0.08   # 区域 内 主色 像素 占比 下限 (剪影 躯体 非空)
const MIN_OPA := 40      # 区域 不透明 像素 下限 (非空)
const ICON := 72        # 探针 实际 渲染 尺寸 (24 基准 x3, 放大 采样 精度)


func _ready() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(W, H)
	_sub.transparent_bg = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub)
	var gd: GDScript = load("res://scripts/game_data.gd")
	for i in CATS.size():
		var cn: String = str(CATS[i])
		var ic: Control = (load("res://scripts/monster_icon.gd").new())
		ic.set_category(cn, gd.MONSTER_CAT_COLORS[cn])
		ic.position = Vector2(40.0 + float(i % 3) * 150.0, 40.0 + float(i / 3) * 160.0)
		ic.size = Vector2(ICON, ICON)
		_sub.add_child(ic)
	# Boss 层 口径: 未设 类别 -> _draw 早退 全 透明 (UI 隐藏 口径 同源)
	_boss = (load("res://scripts/monster_icon.gd").new())
	_boss.position = Vector2(40.0, 340.0)
	_boss.size = Vector2(ICON, ICON)
	_sub.add_child(_boss)


var _sub: SubViewport
var _boss: Control
var _frames := 0
var _done := false
var _fail: Array[String] = []


func _process(_d: float) -> void:
	_frames += 1
	if _frames == 10 and not _done:
		_done = true
		_render_check()


func _render_check() -> void:
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img: Image = _sub.get_texture().get_image()
	if img == null or img.is_empty():
		_fail.append("探针: 图像为空 (渲染失败?)")
		_finish()
		return
	var gd: GDScript = load("res://scripts/game_data.gd")
	for i in CATS.size():
		var cn: String = str(CATS[i])
		var col: Color = gd.MONSTER_CAT_COLORS[cn]
		var rect := Rect2i(40 + (i % 3) * 150, 40 + (i / 3) * 160, ICON, ICON)
		var opaque := 0
		var body := 0
		for y in rect.size.y:
			for x in rect.size.x:
				var px: Color = img.get_pixel(rect.position.x + x, rect.position.y + y)
				if px.a > 0.5:
					opaque += 1
					var d: float = absf(px.r - col.r) + absf(px.g - col.g) + absf(px.b - col.b)
					if d / 3.0 < TOL:
						body += 1
		var tot: int = rect.size.x * rect.size.y
		if opaque < MIN_OPA:
			_fail.append("%s: 不透明像素 不足 (%d < %d, 非空 口径)" % [cn, opaque, MIN_OPA])
		if float(body) / float(tot) < MIN_BODY:
			_fail.append("%s: 主色占比 不足 (%.3f < %.3f, 颜色 != 类别 主色)" % [cn, float(body) / float(tot), MIN_BODY])
	# Boss 层: 全 透明 (无 类别 = 不 绘制)
	var br := Rect2i(40, 340, ICON, ICON)
	var bop := 0
	for y in br.size.y:
		for x in br.size.x:
			if img.get_pixel(br.position.x + x, br.position.y + y).a > 0.1:
				bop += 1
	if bop > 0:
		_fail.append("Boss 层 (未设 类别) 应 全 透明 (实际 %d 不透明 像素)" % bop)
	_finish()


func _finish() -> void:
	if _fail.is_empty():
		print("ICON_PROBE PASS (6 类 非空 + 主色 命中 + Boss 层 隐藏)")
		get_tree().quit(0)
	else:
		printerr("ICON_PROBE FAIL (%d 项):" % _fail.size())
		for x in _fail:
			printerr("  - " + x)
		get_tree().quit(1)
