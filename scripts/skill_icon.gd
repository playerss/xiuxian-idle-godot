extends Control
## M8-3 打磨-155: 功法/神通 5 类别 程序化 字形 图标 (零素材 零许可风险, 与 打磨-136/138/153/154
## 徽章 体系 同 风格 同 纪律) — sword=剑法 竖刃 / spell=法术 符纸雷纹 / mind=心法 瞳 /
## body=身法 脉动 / divine=神通 四芒星; 24x24 基准 简化 几何 (直线段/多边形/圆/弧),
## 低饱和 2-3 色 (类别 主色 + 暗底 + 主色 高光), 深色 仙侠 基调 不 抢 前景 文字。
## 类别 主色 单源 GameData.SKILL_CAT_COLORS (由 调用 方 传入 skill_category_color, 防 无
## autoload 的 -s 脚本 场景 依赖); 品质 色 由 138 徽章 区分, 字形 不 随 品质 变色。
## 主动/被动 两档: 24 主动 神通 按 类别 取 字形 + 金色 爆发 描边 环 区分 主动 (SKILL_ACTIVE_GOLD,
## 金色 与 爆发/灵石 语义 同源); 96 被动 功法 无 描边 旧 品质徽章 口径 保持。
## 绘制 纯函数 化: 同 类别+同 档 恒 同 图 (无 随机 无 时间 依赖, 防 flake); 未 设 类别 时 _draw
## 早退 全 透明 (UI 隐藏 口径); 纯 装饰 无 热区。
## Control 化 (非 裸 CanvasItem): 需 custom_minimum_size 撑 24x24 (裸 CanvasItem size 恒 0
## 不 渲染, 与 ink_bg/打磨-135/153 布局 坑 同源 口径)。

const SIZE := 24.0                      # 基准 绘制 尺寸 (实际 按 节点 宽 等比 缩放)
const BG_COL := Color(0.05, 0.06, 0.09)  # 暗底 (低于 卡片 底色, 融入 深色 仙侠 基调)
const GOLD := Color(0.85, 0.7, 0.38)     # 主动 爆发 描边 金 (GameData.SKILL_ACTIVE_GOLD 同值 单源)
const ACC_A := 0.55                     # 高光 透明度 (主色 降 alpha 点缀, 低 饱和 不 抢 前景)

var _cat := ""
var _col := Color()
var _active := false
var redraw_count := 0  # set_category 状态 变化 触发 重绘 计数 (自测 断言 挂机 恒定 无 每帧 重绘)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # 纯 装饰 无 热区
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE


# 类别 键 + 主色 + 主动 标记 (同 键 幂等 不 重绘; 空 cat = 清除 回 未 设 态)
# cat 取 sword/spell/mind/body/divine (GameData.SKILL_CAT_COLORS 键 单源);
# col 由 调用 方 传 GameData.skill_category_color; active = 主动 神通 爆发 描边 档
func set_category(cat: String, col: Color, active: bool = false) -> void:
	if cat == "":
		_clear_state()
		return
	if _cat == cat and _col == col and _active == active:
		return
	_cat = cat
	_col = col
	_active = active
	_bump()


func _clear_state() -> void:
	if _cat == "" and not _active:
		return
	_cat = ""
	_col = Color()
	_active = false
	_bump()


func _bump() -> void:
	redraw_count += 1
	queue_redraw()


# 只读: 当前 类别/主动 标记 (自测 断言 用)
func get_category() -> String:
	return _cat


func is_active_marked() -> bool:
	return _active


func _draw() -> void:
	if _cat == "":
		return
	var sz: Vector2 = size
	if sz.x < 8.0:
		return
	var s: float = sz.x / SIZE
	# 暗底 壳 降级 实心 底 (draw_stylebox 属 CanvasItem, Control 化 后 无 该 方法 —
	# 字形 主体 已 覆盖 底 区, 实心 暗底 不 影响 采样 口径, 与 打磨-153/154 同 口径)
	draw_rect(Rect2(Vector2.ZERO, sz), BG_COL)
	match _cat:
		"sword":
			_sword(s)
		"spell":
			_spell(s)
		"mind":
			_mind(s)
		"body":
			_body(s)
		"divine":
			_divine(s)
		_:
			pass  # 未知 类别 只 显 暗底 壳 (颜色 兜底 由 接口 侧 处理, 此处 防御)
	if _active:
		_burst(s)


func _V(x: float, y: float, s: float) -> Vector2:
	return Vector2(x * s, y * s)


func _lw(s: float) -> float:
	return maxf(1.0, 1.5 * s)


func _accent() -> Color:
	var a := _col
	a.a = ACC_A
	return a


# sword = 剑法 (竖刃 菱形 + 剑格 + 剑柄 + 柄 珠, 高光 剑脊; 与 部位 剑 [斜向]/法器 木剑
# [金边] 以 类别 冷青 色 区分; 剑刃 填充 体量 >= 部位 剪影 口径 防 阈值 边界 flake)
func _sword(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 竖刃 (宽 菱形 填充: 上 刃 尖 + 下 剑身 收 尖)
	draw_colored_polygon(PackedVector2Array([_V(12, 3, s), _V(15.2, 8.5, s), _V(12, 15.5, s), _V(8.8, 8.5, s)]), c)
	# 剑格
	draw_line(_V(7.5, 13.5, s), _V(16.5, 13.5, s), c, w)
	# 剑柄 + 柄 珠
	draw_line(_V(12, 15.5, s), _V(12, 18.5, s), c, w * 1.4)
	draw_circle(_V(12, 19.0, s), 1.1 * s, c)
	# 剑脊 高光
	draw_line(_V(12, 5.5, s), _V(12, 11.5, s), _accent(), w * 0.6)


# spell = 法术 (符纸 竖 牌 + 雷纹 折线 + 符尾 双 褶, 高光 雷 纹)
func _spell(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 符纸 (竖 圆 牌 以 竖 矩形 + 顶 弧 近似)
	draw_rect(Rect2(_V(8.8, 4, s), Vector2(6.4 * s, 13.5 * s)), c)
	draw_arc(_V(12, 4.5, s), 3.2 * s, PI, TAU, 10, c, w * 0.7)
	# 雷纹 (折线 刻 于 纸面, 暗底 色 切 出)
	draw_line(_V(10.5, 7.5, s), _V(13.5, 9.5, s), BG_COL, w * 0.8)
	draw_line(_V(13.5, 9.5, s), _V(10.5, 11.5, s), BG_COL, w * 0.8)
	draw_line(_V(10.5, 11.5, s), _V(13.5, 13.5, s), BG_COL, w * 0.8)
	# 符尾 双 褶
	draw_line(_V(10, 17.5, s), _V(12, 19.5, s), c, w * 0.9)
	draw_line(_V(14, 17.5, s), _V(12, 19.5, s), c, w * 0.9)
	# 纸面 高光 (左上 小 点)
	draw_circle(_V(10, 6, s), 0.7 * s, _accent())


# mind = 心法 (瞳: 外 眼眶 双 弧 + 瞳 心 圆 + 高光 瞳 点)
func _mind(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 眼眶 (上 弧 + 下 弧 合成 椭圆 感)
	draw_arc(_V(12, 12, s), 6.5 * s, PI, TAU, 14, c, w)
	draw_arc(_V(12, 12, s), 6.5 * s, 0.0, PI, 14, c, w)
	# 瞳 心
	draw_circle(_V(12, 12, s), 2.6 * s, c)
	# 瞳 内 高光
	draw_circle(_V(12, 12, s), 1.0 * s, _accent())


# body = 身法 (脉动: 横向 心脉 折线 + 波峰 节点, 高光 脉 点)
func _body(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 心脉 (左 平 -> 波峰 -> 波谷 -> 右 平)
	draw_line(_V(3.5, 12, s), _V(8, 12, s), c, w * 1.2)
	draw_line(_V(8, 12, s), _V(10.5, 6.5, s), c, w * 1.2)
	draw_line(_V(10.5, 6.5, s), _V(13.5, 17.5, s), c, w * 1.2)
	draw_line(_V(13.5, 17.5, s), _V(15.5, 12, s), c, w * 1.2)
	draw_line(_V(15.5, 12, s), _V(20.5, 12, s), c, w * 1.2)
	# 波峰 节点 (脉 点)
	draw_circle(_V(10.5, 6.5, s), 1.3 * s, c)
	# 脉 点 高光
	draw_circle(_V(10.5, 6.5, s), 0.7 * s, _accent())


# divine = 神通 (四芒 星: 8 顶点 凹 星 多边形 + 中心 星核 高光)
func _divine(s: float) -> void:
	var c := _col
	# 四芒 星 (上/下/左/右 芒 尖 + 四 凹 谷)
	draw_colored_polygon(PackedVector2Array([
		_V(12, 3.5, s), _V(14, 10, s), _V(20.5, 12, s), _V(14, 14, s),
		_V(12, 20.5, s), _V(10, 14, s), _V(3.5, 12, s), _V(10, 10, s)]), c)
	# 星核 高光
	draw_circle(_V(12, 12, s), 1.4 * s, _accent())


# 主动 爆发 描边 (金色 环 + 四 芒 火花 点; 仅 24 主动 神通 启用, 被动 无 描边 旧 口径)
func _burst(s: float) -> void:
	var w := _lw(s)
	# 爆发 环
	draw_arc(_V(12, 12, s), 9.3 * s, 0.0, TAU, 24, GOLD, w)
	# 四 芒 火花 (环外 四 尖 短 点)
	draw_circle(_V(12, 2.6, s), 0.8 * s, GOLD)
	draw_circle(_V(12, 21.4, s), 0.8 * s, GOLD)
	draw_circle(_V(2.6, 12, s), 0.8 * s, GOLD)
	draw_circle(_V(21.4, 12, s), 0.8 * s, GOLD)
