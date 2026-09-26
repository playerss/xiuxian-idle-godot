extends Control
## M8-4 打磨-156: 词缀 6 池 程序化 字形 图标 (零素材 零许可风险, 与 打磨-136/138/153/154/155
## 徽章 体系 同 风格 同 纪律) — qi_rate=灵气 涡旋 / stone_rate=灵石 宝石 / bt_chance=突破 箭矢 /
## offline_rate=离线 月相 / atk=攻击 交叉 锋 / def=防御 盾形; 24x24 基准 简化 几何
## (直线段/多边形/圆/弧), 低饱和 2-3 色 (池 主色 + 暗底 + 主色 高光), 深色 仙侠 基调 不 抢 前景 文字。
## 池 主色 单源 GameData.AFFIX_POOL_COLORS (由 调用 方 传入 affix_pool_color, 防 无
## autoload 的 -s 脚本 场景 依赖); 品质 色 由 背包格 品质色 区分, 字形 不 随 品质 变色。
## 绘制 纯函数 化: 同 池 恒 同 图 (无 随机 无 时间 依赖, 防 flake); 未 设 池 时 _draw
## 早退 全 透明 (UI 隐藏 口径); 纯 装饰 无 热区。
## Control 化 (非 裸 CanvasItem): 需 custom_minimum_size 撑 24x24 (裸 CanvasItem size 恒 0
## 不 渲染, 与 ink_bg/打磨-135/153 布局 坑 同源 口径)。

const SIZE := 24.0                      # 基准 绘制 尺寸 (实际 按 节点 宽 等比 缩放)
const BG_COL := Color(0.05, 0.06, 0.09)  # 暗底 (低于 卡片 底色, 融入 深色 仙侠 基调)
const ACC_A := 0.55                     # 高光 透明度 (主色 降 alpha 点缀, 低 饱和 不 抢 前景)

var _pool := ""
var _col := Color()
var redraw_count := 0  # set_pool 状态 变化 触发 重绘 计数 (自测 断言 挂机 恒定 无 每帧 重绘)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # 纯 装饰 无 热区
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE


# 池 键 + 主色 (同 键 幂等 不 重绘; 空 pool = 清除 回 未 设 态)
# pool 取 qi_rate/stone_rate/bt_chance/offline_rate/atk/def (GameData.AFFIX_POOL_COLORS 键 单源);
# col 由 调用 方 传 GameData.affix_pool_color
func set_pool(pool: String, col: Color) -> void:
	if pool == "":
		_clear_state()
		return
	if _pool == pool and _col == col:
		return
	_pool = pool
	_col = col
	_bump()


func _clear_state() -> void:
	if _pool == "":
		return
	_pool = ""
	_col = Color()
	_bump()


func _bump() -> void:
	redraw_count += 1
	queue_redraw()


# 只读: 当前 池 (自测 断言 用)
func get_pool() -> String:
	return _pool


func _draw() -> void:
	if _pool == "":
		return
	var sz: Vector2 = size
	if sz.x < 8.0:
		return
	var s: float = sz.x / SIZE
	# 暗底 壳 (字形 主体 已 覆盖 底 区, 实心 暗底 不 影响 采样 口径, 与 打磨-153/154/155 同 口径)
	draw_rect(Rect2(Vector2.ZERO, sz), BG_COL)
	match _pool:
		"qi_rate":
			_qi(s)
		"stone_rate":
			_stone(s)
		"bt_chance":
			_break(s)
		"offline_rate":
			_offline(s)
		"atk":
			_atk(s)
		"def":
			_def(s)
		_:
			pass  # 未知 池 只 显 暗底 壳 (颜色 兜底 由 接口 侧 处理, 此处 防御)


func _V(x: float, y: float, s: float) -> Vector2:
	return Vector2(x * s, y * s)


func _lw(s: float) -> float:
	return maxf(1.0, 1.5 * s)


func _accent() -> Color:
	var a := _col
	a.a = ACC_A
	return a


# qi_rate = 灵气 速率 (涡旋: 双 旋转 弧 + 中心 气核 圆 + 高光 核 点; 弧线 体量 主色 占比
# >= MIN_BODY 口径 防 阈值 边界 flake, 同 打磨-155 sword 体量 口径)
func _qi(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 外 弧 (3/4 圈 旋转 感)
	draw_arc(_V(12, 12, s), 6.8 * s, 0.5, TAU * 0.92, 18, c, w * 1.3)
	# 内 弧 (反向 旋转 半 圈)
	draw_arc(_V(12, 12, s), 3.4 * s, PI * 1.2, PI * 2.6, 14, c, w * 1.1)
	# 气核
	draw_circle(_V(12, 12, s), 1.6 * s, c)
	# 核 高光
	draw_circle(_V(12, 12, s), 0.8 * s, _accent())


# stone_rate = 灵石 速率 (宝石: 六角 轮廓 填充 + 顶/腰 切面 高光)
func _stone(s: float) -> void:
	var c := _col
	# 宝石 主体 (六 顶点: 顶 尖/上 肩 x2/下 肩 x2/底 尖)
	draw_colored_polygon(PackedVector2Array([
		_V(12, 4, s), _V(17.5, 8.5, s), _V(17.5, 15.5, s),
		_V(12, 20, s), _V(6.5, 15.5, s), _V(6.5, 8.5, s)]), c)
	# 腰 切面 高光 (横 亮带)
	draw_line(_V(6.9, 11.9, s), _V(17.1, 11.9, s), _accent(), _lw(s) * 1.2)
	# 顶 切面 高光
	draw_line(_V(12, 4.6, s), _V(9.2, 8.2, s), _accent(), _lw(s) * 0.8)


# bt_chance = 突破 成功率 (向上 箭矢: 箭镞 三角 填充 + 箭杆 + 尾羽 双 折线)
func _break(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 箭镞 (顶 三角 填充)
	draw_colored_polygon(PackedVector2Array([_V(12, 3.5, s), _V(16.5, 9.5, s), _V(7.5, 9.5, s)]), c)
	# 箭杆
	draw_line(_V(12, 9.5, s), _V(12, 18.5, s), c, w * 1.4)
	# 尾羽 (左 上/右 上 双 折)
	draw_line(_V(12, 18.5, s), _V(8.5, 15.5, s), c, w * 0.9)
	draw_line(_V(12, 18.5, s), _V(15.5, 15.5, s), c, w * 0.9)
	# 镞 高光
	draw_line(_V(12, 5.5, s), _V(12, 8.8, s), _accent(), w * 0.6)


# offline_rate = 离线 效率 (月相: 月 体 圆 填充 + 暗 侧 切 出 月牙 + 高光 月 点)
func _offline(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 月 体 (实心 圆)
	draw_circle(_V(12, 12, s), 6.8 * s, c)
	# 暗 侧 (暗底 色 切 出 月牙: 左偏 圆 遮 右半)
	draw_circle(_V(15.6, 12, s), 5.4 * s, BG_COL)
	# 月牙 弧 高光
	draw_arc(_V(12, 12, s), 7.6 * s, PI * 0.75, PI * 1.45, 12, _accent(), w * 0.7)


# atk = 攻击 (交叉 锋: 双 斜 剑 交叉 成 X + 刃 尖 三角 填充 + 高光 刃 线)
func _atk(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 左下->右上 剑 (刃 尖 右上 填充)
	draw_colored_polygon(PackedVector2Array([_V(17.5, 4.5, s), _V(13.4, 9.4, s), _V(15.6, 11.6, s)]), c)
	draw_line(_V(4, 20, s), _V(15.2, 8.8, s), c, w * 1.4)
	# 右下->左上 剑 (刃 尖 左上 填充)
	draw_colored_polygon(PackedVector2Array([_V(6.5, 4.5, s), _V(10.6, 9.4, s), _V(8.4, 11.6, s)]), c)
	draw_line(_V(20, 20, s), _V(8.8, 8.8, s), c, w * 1.4)
	# 交叉 点 高光
	draw_circle(_V(12, 12, s), 1.2 * s, _accent())


# def = 防御 (盾形: 五 边 盾 轮廓 填充 + 盾 脊 竖 线 + 高光 脊 点)
func _def(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 盾 主体 (顶 边 双 肩 + 侧 边 + 底 尖)
	draw_colored_polygon(PackedVector2Array([
		_V(7.5, 5.5, s), _V(16.5, 5.5, s), _V(19.5, 8.5, s),
		_V(19.5, 13.5, s), _V(12, 20, s), _V(4.5, 13.5, s), _V(4.5, 8.5, s)]), c)
	# 盾 脊 (中 竖 线, 暗底 色 切 出 防 盾 面 过 实)
	draw_line(_V(12, 7.5, s), _V(12, 18.5, s), BG_COL, w * 0.8)
	# 盾 顶 高光
	draw_line(_V(8.5, 6.4, s), _V(15.5, 6.4, s), _accent(), w * 0.7)
