extends Control
## 打磨-137: 主背景 程序化水墨山水 (M7-3, 零素材 零许可风险)
## 渐变 夜空 + 远山 3 层 视差 缓慢 横移 + 灵气 粒子 缓慢 上浮;
## 低 饱和度 深色系 不 抢 前景 文字 (与 BG 0.07/0.08/0.11 深色仙侠 基调 同源)。
## 纯 CanvasItem 自绘: 0.1s 量化 重绘 (挂机 恒定 无 每帧 重绘), 开关 由
## GameData.bg_on 存档 持久化 (本节点 无 存档/统计 副作用, 纯 装饰 无 热区)。

# 夜空 垂直 渐变 (顶 深 -> 底 略亮 青灰; 顶 与 底 均 低于 面板 底色 不 抢 前景)
const SKY_TOP := Color(0.045, 0.055, 0.09)
const SKY_BOT := Color(0.10, 0.115, 0.15)
# 远山 3 层 (远 层 略亮 呈 远虚, 近 层 趋 BG 呈 近实; 低 饱和 青灰)
const MOUNTS: Array[Color] = [
	Color(0.115, 0.135, 0.175),  # 远
	Color(0.09, 0.11, 0.15),     # 中
	Color(0.062, 0.078, 0.11),   # 近
]
const MOUNT_H := [0.30, 0.24, 0.17]   # 各层 山脊 基线 占高 比例 (自 底 起)
const MOUNT_AMP := [0.10, 0.09, 0.08] # 山脊 起伏 幅度 占高 比例
const MOUNT_SPEED := [0.6, 1.0, 1.6]  # 视差 横移 速度 px/s (近 层 快 远 层 慢)
const RIDGE_FREQS := [2.0, 3.5, 5.5, 8.0]  # 山脊 正弦 频率 (确定性 固定 值)
const RIDGE_PHASES := [0.7, 2.3, 4.1, 5.9] # 山脊 正弦 相位 (确定性 固定 值)
const PARTICLE_N := 14
const PARTICLE_COLOR := Color(0.62, 0.9, 0.95)  # 与 CYAN 同 语义 色
const DRAW_INTERVAL := 0.1  # 0.1s 量化 重绘 (10fps)

var _t := 0.0        # 动画 累计 时间 (秒, 仅 重绘 节流 窗口 内 推进, 防 后台 追赶 快进)
var _acc := 0.0      # 重绘 节流 累计
var _parts: Array[Dictionary] = []  # 粒子 {x,y,sp,r,a,ph} (x/y 为 0..1 比例 坐标)
var _bg_enabled := true
var draw_count := 0  # _draw 执行 次数 (自测 断言 用)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # 纯 装饰 无 热区
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_init_particles()


func _process(delta: float) -> void:
	if not _bg_enabled:
		return
	_acc += delta
	if _acc < DRAW_INTERVAL:
		return
	_advance(_acc)
	_acc = 0.0
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


# 开关 (main._refresh 每帧 幂等 调用, 仅 翻转 时 生效; 关 时 停 节流 计时 零 开销)
func set_bg_enabled(v: bool) -> void:
	if v == _bg_enabled:
		return
	_bg_enabled = v
	visible = v
	_acc = 0.0
	if v:
		queue_redraw()


# 粒子 确定性 初始化 (黄金比 散列 均匀 分布, 无 运行期 随机 防 每 启动 不同)
func _init_particles() -> void:
	for i in PARTICLE_N:
		_parts.append({
			"x": fmod(i * 0.61803, 1.0),
			"y": fmod(i * 0.38197, 1.0) * 0.85 + 0.06,
			"sp": 0.008 + (i % 5) * 0.003,   # 上升 速度 (比例/秒)
			"r": 1.0 + (i % 3) * 0.8,        # 半径 px
			"a": 0.05 + (i % 4) * 0.02,      # 基础 alpha (低 饱和 低 透明 档)
			"ph": i * 1.7,                   # 相位
		})


# 节流 窗口 内 推进 动画 时间 + 粒子 上浮 环绕 (纯 状态 无 渲染, 供 自测 独立 驱动)
func _advance(dt: float) -> void:
	_t += dt
	for pt in _parts:
		var y := float(pt.y) + float(pt.sp) * dt  # y 比例 递增 => 屏幕 坐标 上浮 (py = (1-y)*H)
		if y > 1.0:
			y -= 1.0
		pt.y = y


# 山脊 线 高度 (0..1 占高 比例, 0=画面 底 越大 越 高) = 层 基线 + 4 正弦 叠加 确定性 伪 山形;
# 纯 函数 (同 输入 恒等), 自测 可 独立 复算 校验
func _ridge(layer: int, x: float, t: float) -> float:
	var off: float = t * MOUNT_SPEED[layer]
	var u: float = (x + off) / 180.0
	var s := 0.0
	for i in 4:
		s += sin(u * RIDGE_FREQS[i] + RIDGE_PHASES[i])
	var base: float = MOUNT_H[layer]
	var amp: float = MOUNT_AMP[layer]
	return base + s / 4.0 * amp


func _draw() -> void:
	draw_count += 1  # 执行 计数 (自测 断言 用; 置于 守卫 前, headless size=0 早退 也 计数)
	var sz: Vector2 = size
	if sz.x < 8.0 or sz.y < 8.0:
		return
	# 夜空 垂直 渐变 (24 条带 线性 插值, 低 开销)
	var steps := 24
	for i in steps:
		var c: Color = SKY_TOP.lerp(SKY_BOT, i / float(steps - 1))
		var y0 := sz.y * i / float(steps)
		var y1 := sz.y * (i + 1) / float(steps)
		draw_rect(Rect2(0.0, y0, sz.x, y1 - y0 + 1.0), c)
	# 月亮 (低 alpha 光晕 + 圆盘, 不 抢 前景)
	var mx := sz.x * 0.78
	var my := sz.y * 0.22
	draw_circle(Vector2(mx, my), 34.0, Color(0.85, 0.9, 0.95, 0.05))
	draw_circle(Vector2(mx, my), 16.0, Color(0.85, 0.9, 0.95, 0.10))
	# 远山 3 层 (远 -> 近 叠画, 视差 横移; 6px 步长 采样)
	for layer in 3:
		var col: Color = MOUNTS[layer]
		var p := PackedVector2Array()
		p.append(Vector2(0.0, sz.y))
		var x := 0.0
		while x <= sz.x + 6.0:
			p.append(Vector2(x, sz.y * (1.0 - _ridge(layer, x, _t))))
			x += 6.0
		p.append(Vector2(sz.x, sz.y))
		draw_colored_polygon(p, col)
	# 灵气 粒子 (缓慢 上浮 + 轻微 左右 摆动, 低 alpha 青色)
	for pt in _parts:
		var px := sz.x * float(pt.x) + sin(_t * 0.3 + float(pt.ph)) * 14.0
		var py := sz.y * (1.0 - float(pt.y))
		var a := float(pt.a) * (0.6 + 0.4 * sin(_t * 0.8 + float(pt.ph)))
		draw_circle(Vector2(px, py), float(pt.r), Color(PARTICLE_COLOR, a))
