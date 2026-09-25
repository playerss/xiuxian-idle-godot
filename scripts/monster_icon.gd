extends Control
## M8-1 打磨-153: 怪物 6 类别 程序化 剪影 图标 (零素材 零许可风险, 与 打磨-136/138 徽章 体系
## 同 风格 同 纪律) — 妖兽=狼耳兽头 / 鬼修=圆头飘带 / 虫群=六足多节 / 精怪=狐耳面具 /
## 凶灵=火焰爪 / 天兽=双角犄; 24x24 基准 简化 几何 (直线段/多边形/圆), 低饱和 2-3 色
## (类别 主色 + 暗底 + 主色 高光), 深色 仙侠 基调 不 抢 前景 文字。
## 绘制 纯函数 化: 同 类别 恒 同 图 (无 随机 无 时间 依赖, 防 flake); 类别 主色 单源
## GameData.monster_category_color (由 调用 方 传入, 防 无 autoload 的 -s 脚本 场景 依赖)。
## Boss 层 无 category_name 时 由 UI 隐藏 本 节点 (旧 ⚑ 口径 不 显 类别 图标); 纯 装饰 无 热区。
## Control 化 (非 裸 CanvasItem): 需 custom_minimum_size 撑 24x24 (裸 CanvasItem size 恒 0 不 渲染,
## 与 ink_bg/打磨-135 布局 坑 同源 口径)。

const SIZE := 24.0                      # 基准 绘制 尺寸 (实际 按 节点 宽 等比 缩放)
const BG_COL := Color(0.05, 0.06, 0.09)  # 暗底 (低于 卡片 底色, 融入 深色 仙侠 基调)
const ACC_A := 0.5                      # 高光 透明度 (主色 降 alpha 点缀, 低 饱和 不 抢 前景)

var _cat := ""
var _col := Color()
var redraw_count := 0  # set_category 状态 变化 触发 重绘 计数 (自测 断言 挂机 恒定 无 每帧 重绘)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # 纯 装饰 无 热区
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE


# 类别 名 + 主色 (调用 方 传 GameData.monster_category_color; 同 键 幂等 不 重绘)
func set_category(cat_name: String, col: Color) -> void:
	if cat_name == _cat and col == _col:
		return
	_cat = cat_name
	_col = col
	redraw_count += 1
	queue_redraw()


# 只读: 当前 类别 (自测 断言 用)
func get_category() -> String:
	return _cat


func _draw() -> void:
	if _cat == "":
		return
	var sz: Vector2 = size
	if sz.x < 8.0:
		return
	var s: float = sz.x / SIZE
	# 暗底 圆角 壳 降级 实心 底 (draw_stylebox 属 CanvasItem, Control 化 后 无 该 方法 —
	# 剪影 主体 已 覆盖 底 区, 实心 暗底 不 影响 采样 口径)
	draw_rect(Rect2(Vector2.ZERO, sz), BG_COL)
	match _cat:
		"妖兽":
			_demon(s)
		"鬼修":
			_ghost(s)
		"虫群":
			_insect(s)
		"精怪":
			_fox(s)
		"凶灵":
			_flame(s)
		"天兽":
			_horn(s)
		_:
			pass  # 未知 类别 只 显 暗底 壳 (颜色 兜底 由 接口 侧 处理, 此处 防御)


func _V(x: float, y: float, s: float) -> Vector2:
	return Vector2(x * s, y * s)


func _lw(s: float) -> float:
	return maxf(1.0, 1.5 * s)


func _accent() -> Color:
	var a := _col
	a.a = ACC_A
	return a


# 妖兽 = 狼耳兽头 (双 尖耳 三角 + 圆脸 + 高光 眼)
func _demon(s: float) -> void:
	var c := _col
	draw_colored_polygon(PackedVector2Array([_V(5, 11, s), _V(7.5, 4.5, s), _V(10.5, 9, s)]), c)
	draw_colored_polygon(PackedVector2Array([_V(13.5, 9, s), _V(16.5, 4.5, s), _V(19, 11, s)]), c)
	draw_circle(_V(12, 14.5, s), 5.5 * s, c)
	draw_circle(_V(9.8, 13.5, s), 0.9 * s, _accent())
	draw_circle(_V(14.2, 13.5, s), 0.9 * s, _accent())


# 鬼修 = 圆头飘带 (圆头 + 双侧 飘带 折线 + 高光 眼)
func _ghost(s: float) -> void:
	var c := _col
	var w := _lw(s)
	draw_circle(_V(12, 9.5, s), 5.0 * s, c)
	draw_line(_V(6.5, 14, s), _V(5, 18, s), c, w)
	draw_line(_V(5, 18, s), _V(7, 21, s), c, w)
	draw_line(_V(17.5, 14, s), _V(19, 18, s), c, w)
	draw_line(_V(19, 18, s), _V(17, 21, s), c, w)
	draw_circle(_V(10, 9, s), 0.9 * s, _accent())
	draw_circle(_V(14, 9, s), 0.9 * s, _accent())


# 虫群 = 六足多节 (3 节 圆 躯体 + 6 足 直线 + 高光 眼)
func _insect(s: float) -> void:
	var c := _col
	var w := _lw(s)
	draw_circle(_V(12, 7.5, s), 2.2 * s, c)
	draw_circle(_V(12, 12, s), 2.8 * s, c)
	draw_circle(_V(12, 16.5, s), 2.4 * s, c)
	var legs: Array = [
		[_V(10.2, 8.5, s), _V(5.5, 5.5, s)],
		[_V(9.5, 12, s), _V(4.8, 12, s)],
		[_V(10.2, 15.5, s), _V(5.5, 19, s)],
		[_V(13.8, 8.5, s), _V(18.5, 5.5, s)],
		[_V(14.5, 12, s), _V(19.2, 12, s)],
		[_V(13.8, 15.5, s), _V(18.5, 19, s)],
	]
	for p in legs:
		draw_line(p[0], p[1], c, w)
	draw_circle(_V(10.8, 6.8, s), 0.8 * s, _accent())
	draw_circle(_V(13.2, 6.8, s), 0.8 * s, _accent())


# 精怪 = 狐耳面具 (双 狐耳 + 圆脸 + 下尖 面罩 + 高光 眼)
func _fox(s: float) -> void:
	var c := _col
	draw_colored_polygon(PackedVector2Array([_V(6, 10, s), _V(8, 4, s), _V(11, 8.5, s)]), c)
	draw_colored_polygon(PackedVector2Array([_V(13, 8.5, s), _V(16, 4, s), _V(18, 10, s)]), c)
	draw_circle(_V(12, 12.5, s), 5.0 * s, c)
	draw_colored_polygon(PackedVector2Array([_V(8.5, 14, s), _V(12, 19.5, s), _V(15.5, 14, s)]), c)
	draw_circle(_V(10, 11.5, s), 0.9 * s, _accent())
	draw_circle(_V(14, 11.5, s), 0.9 * s, _accent())


# 凶灵 = 火焰爪 (火焰 多边形 + 内焰 高光 点缀)
func _flame(s: float) -> void:
	var c := _col
	draw_colored_polygon(PackedVector2Array([
		_V(12, 4, s), _V(15.2, 8.5, s), _V(16.8, 13, s), _V(14.8, 17.5, s),
		_V(12, 20, s), _V(9.2, 17.5, s), _V(7.2, 13, s), _V(8.8, 8.5, s)]), c)
	draw_colored_polygon(PackedVector2Array([
		_V(12, 9.5, s), _V(13.8, 12.5, s), _V(13.2, 15.5, s), _V(12, 16.5, s),
		_V(10.8, 15.5, s), _V(10.2, 12.5, s)]), _accent())


# 天兽 = 双角犄 (圆头 + 双侧 上扬 犄角 折线 + 角尖/眼 高光)
func _horn(s: float) -> void:
	var c := _col
	var w := _lw(s)
	draw_circle(_V(12, 13.5, s), 5.5 * s, c)
	draw_line(_V(8.5, 11, s), _V(7, 7, s), c, w)
	draw_line(_V(7, 7, s), _V(9.5, 4.5, s), c, w)
	draw_line(_V(15.5, 11, s), _V(17, 7, s), c, w)
	draw_line(_V(17, 7, s), _V(14.5, 4.5, s), c, w)
	draw_circle(_V(9.5, 4.5, s), 1.1 * s, _accent())
	draw_circle(_V(14.5, 4.5, s), 1.1 * s, _accent())
	draw_circle(_V(10, 13, s), 0.9 * s, _accent())
	draw_circle(_V(14, 13, s), 0.9 * s, _accent())
