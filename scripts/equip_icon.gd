extends Control
## M8-2 打磨-154: 装备 部位 5 剪影 + 法器 金边 单字 徽章 程序化 图标 (零素材 零许可风险,
## 与 打磨-136/138/153 徽章 体系 同 风格 同 纪律) — weapon=剑形 / robe=袍形 /
## amulet=玉佩环 / bead=圆珠 / boot=靴形; 24x24 基准 简化 几何 (直线段/多边形/圆/弧),
## 低饱和 白灰 系 2-3 色 (部位 主色 + 暗底 + 主色 高光), 深色 仙侠 基调 不 抢 前景 文字。
## 部位 剪影 主色 单源 GameData.EQUIP_SLOT_COLORS (由 调用 方 传入, 防 无 autoload 的
## -s 脚本 场景 依赖); 品质 色 由 138 徽章 区分, 部位 图标 恒 白灰 不 随 品质 变色。
## 法器 徽章 = 金边 单字 (名称 前 2 字, 10 件 两两 不重 可分, 与 136 资源 徽章 同 壳 风格,
## 金色 与 灵石 语义 同源); 未 设 部位/名称 时 _draw 早退 全 透明 (UI 隐藏 口径)。
## 绘制 纯函数 化: 同 部位 恒 同 图 (无 随机 无 时间 依赖, 防 flake); 纯 装饰 无 热区。
## Control 化 (非 裸 CanvasItem): 需 custom_minimum_size 撑 24x24 (裸 CanvasItem size 恒 0
## 不 渲染, 与 ink_bg/打磨-135 布局 坑 同源 口径)。

const SIZE := 24.0                      # 基准 绘制 尺寸 (实际 按 节点 宽 等比 缩放)
const BG_COL := Color(0.05, 0.06, 0.09)  # 暗底 (低于 卡片 底色, 融入 深色 仙侠 基调)
const GOLD := Color(0.85, 0.7, 0.38)     # 法器 徽章 金 (EQUIP_ITEM_COLOR 同 值 单源)
const ACC_A := 0.55                      # 高光 透明度 (主色 降 alpha 点缀, 低 饱和 不 抢 前景)

var _kind := ""     # "slot" 部位 剪影 / "item" 法器 金边 徽章 / "" 未 设 态
var _key := ""      # 部位 剪影 = slot 键; 法器 徽章 = 名称 前 2 字
var _col := Color() # 部位 剪影 主色 (调用 方 传 GameData.equip_slot_color; 法器 徽章 恒 GOLD)
var redraw_count := 0  # set_* 状态 变化 触发 重绘 计数 (自测 断言 挂机 恒定 无 每帧 重绘)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # 纯 装饰 无 热区
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE


# 部位 剪影: slot 键 + 主色 (同 键 幂等 不 重绘; 空 slot = 清除 回 未 设 态)
func set_slot(slot: String, col: Color) -> void:
	if slot == "":
		_clear_state()
		return
	if _kind == "slot" and slot == _key and col == _col:
		return
	_kind = "slot"
	_key = slot
	_col = col
	_bump()


# 法器 金边 单字 徽章: name 前 2 字 由 调用 方 传入 (GameData.item_icon_name 单源;
# 同 字 幂等 不 重绘; 空 name = 清除 回 未 设 态)
func set_item(name: String) -> void:
	var k := name.substr(0, min(2, name.length()))
	if k == "":
		_clear_state()
		return
	if _kind == "item" and k == _key:
		return
	_kind = "item"
	_key = k
	_col = GOLD
	_bump()


func _clear_state() -> void:
	if _kind == "" and _key == "":
		return
	_kind = ""
	_key = ""
	_col = Color()
	_bump()


func _bump() -> void:
	redraw_count += 1
	queue_redraw()


# 只读: 当前 类型/键 (自测 断言 用)
func get_kind() -> String:
	return _kind


func get_key() -> String:
	return _key


func _draw() -> void:
	if _kind == "":
		return
	var sz: Vector2 = size
	if sz.x < 8.0:
		return
	var s: float = sz.x / SIZE
	# 暗底 壳 降级 实心 底 (draw_stylebox 属 CanvasItem, Control 化 后 无 该 方法 —
	# 剪影 主体 已 覆盖 底 区, 实心 暗底 不 影响 采样 口径, 与 打磨-153 同 口径)
	draw_rect(Rect2(Vector2.ZERO, sz), BG_COL)
	if _kind == "slot":
		match _key:
			"weapon":
				_weapon(s)
			"robe":
				_robe(s)
			"amulet":
				_amulet(s)
			"bead":
				_bead(s)
			"boot":
				_boot(s)
			_:
				pass  # 未知 部位 只 显 暗底 壳 (颜色 兜底 由 接口 侧 处理, 此处 防御)
	else:
		_item(s)


func _V(x: float, y: float, s: float) -> Vector2:
	return Vector2(x * s, y * s)


func _lw(s: float) -> float:
	return maxf(1.0, 1.5 * s)


func _accent() -> Color:
	var a := _col
	a.a = ACC_A
	return a


# weapon = 剑形 (剑尖 三角 + 剑身 直段 + 剑格 + 剑柄, 高光 剑脊)
func _weapon(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 剑身 (斜向 右上 剑尖, 剑柄 左下)
	draw_line(_V(6, 18, s), _V(13, 11, s), c, w * 2.4)
	# 剑尖 (剑身 末端 收 尖)
	draw_colored_polygon(PackedVector2Array([_V(13, 11, s), _V(18.5, 5.5, s), _V(15, 8.5, s)]), c)
	# 剑格 (横 短 段, 剑身/剑柄 交界)
	draw_line(_V(10.5, 12.5, s), _V(14.5, 8.5, s), c, w)
	# 剑柄 (短 段 + 柄 端 圆)
	draw_line(_V(6.5, 17.5, s), _V(4.5, 19.5, s), c, w)
	draw_circle(_V(4.5, 19.5, s), 1.1 * s, c)
	# 剑脊 高光 (剑身 中线 细 亮 段)
	draw_line(_V(8, 16.5, s), _V(13.5, 10.5, s), _accent(), w * 0.6)


# robe = 袍形 (领口 V + 双侧 垂 褶 长 边 + 下摆 横 段, 高光 领 口)
func _robe(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 肩部/领口 (左肩 -> 颈 -> 右肩)
	draw_line(_V(8, 6, s), _V(12, 9, s), c, w)
	draw_line(_V(12, 9, s), _V(16, 6, s), c, w)
	# 左 垂 褶 (肩 -> 摆)
	draw_line(_V(8, 6, s), _V(6.5, 18, s), c, w)
	# 右 垂 褶 (肩 -> 摆)
	draw_line(_V(16, 6, s), _V(17.5, 18, s), c, w)
	# 下摆 (左右 垂 褶 底 连接)
	draw_line(_V(6.5, 18, s), _V(12, 16.5, s), c, w)
	draw_line(_V(12, 16.5, s), _V(17.5, 18, s), c, w)
	# 中 褶 (领 口 下 垂 至 摆, 短 虚 段)
	draw_line(_V(12, 9, s), _V(12, 12.5, s), c, w * 0.8)
	# 领口 高光
	draw_circle(_V(12, 9, s), 0.9 * s, _accent())


# amulet = 玉佩环 (上 挂环 小 圆 + 下 玉 片 圆 缺, 高光 玉 心)
func _amulet(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 上 挂环
	draw_arc(_V(12, 7.5, s), 2.2 * s, 0.0, TAU, 16, c, w * 0.9)
	# 挂环 下 连 段 (环 -> 玉 片)
	draw_line(_V(12, 9.7, s), _V(12, 11.5, s), c, w)
	# 玉 片 (下 大 圆 缺 口 朝 下, 以 大 圆 + 底 暗 弧 近似)
	draw_circle(_V(12, 15, s), 4.2 * s, c)
	# 底 缺 口 (暗底 小 弧 切 出 玉 佩 缺)
	draw_arc(_V(12, 15, s), 4.2 * s, PI * 0.25, PI * 0.75, 8, BG_COL, w * 1.2)
	# 玉 心 高光
	draw_circle(_V(12, 14, s), 1.1 * s, _accent())


# bead = 圆珠 (大 圆 + 顶部 挂绳 弧, 高光 珠 面)
func _bead(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 珠 体
	draw_circle(_V(12, 13.5, s), 5.5 * s, c)
	# 顶部 挂绳 (珠 顶 两侧 收 拢 短 弧)
	draw_line(_V(8.5, 9, s), _V(12, 5.5, s), c, w)
	draw_line(_V(15.5, 9, s), _V(12, 5.5, s), c, w)
	# 珠 面 高光 (左上 小 弧)
	draw_arc(_V(10.5, 12, s), 1.6 * s, 0.0, TAU, 12, _accent(), w * 0.7)


# boot = 靴形 (靴筒 竖 段 + 靴头 前伸 + 靴底, 高光 靴 头)
func _boot(s: float) -> void:
	var c := _col
	var w := _lw(s)
	# 靴筒 (左 上 竖 段 -> 靴 背)
	draw_line(_V(9, 5.5, s), _V(9, 14, s), c, w * 1.8)
	# 靴 背 (筒 底 -> 后 跟)
	draw_line(_V(9, 14, s), _V(15.5, 14, s), c, w)
	# 靴头 (前伸 尖, 朝 右)
	draw_colored_polygon(PackedVector2Array([_V(15.5, 14, s), _V(19.5, 16.5, s), _V(15.5, 17.5, s)]), c)
	# 靴底 (后 跟 -> 前 尖 底 边)
	draw_line(_V(9, 16.5, s), _V(19.5, 16.5, s), c, w * 1.4)
	draw_line(_V(9, 14, s), _V(9, 16.5, s), c, w)
	# 靴筒 高光
	draw_line(_V(10.2, 6.5, s), _V(10.2, 12.5, s), _accent(), w * 0.6)
	# 靴 头 高光
	draw_circle(_V(16.5, 15.5, s), 0.8 * s, _accent())


# 法器 = 金边 逐件 几何 徽章 (金边 环 壳 + 10 枚 逐件 简化 几何 字形, 与 打磨-136 资源
# 徽章 同 壳 风格 金色; 不用 文字 绘制 — llvmpipe 软件 渲染 下 字体 字形 像素 不可靠
# [探针 实测 同 金 像素数 且 笔画 混同], 几何 图形 同 153/154 部位 剪影 同 确定性 口径;
# 10 枚 字形 两两 可分 (剑/符/囊/灯/笛/船/镜/灯座/钟/印), 金色 与 灵石 语义 同源)
const ITEMS_ORDER := ["sword", "talisman", "bag", "lamp", "flute",
		"boat", "mirror", "hex", "bell", "seal"]


func set_item_index(idx: int) -> void:
	var k := str(ITEMS_ORDER[clampi(idx, 0, ITEMS_ORDER.size() - 1)])
	if _kind == "item" and k == _key:
		return
	_kind = "item"
	_key = k
	_col = GOLD
	_bump()


func _item(s: float) -> void:
	# 金色 描边 环 (金边 徽章 壳, 10 枚 同 壳 区 分 靠 内 字形)
	draw_arc(_V(12, 12, s), 8.5 * s, 0.0, TAU, 24, GOLD, _lw(s))
	match _key:
		"sword":
			_it_sword(s)
		"talisman":
			_it_talisman(s)
		"bag":
			_it_bag(s)
		"lamp":
			_it_lamp(s)
		"flute":
			_it_flute(s)
		"boat":
			_it_boat(s)
		"mirror":
			_it_mirror(s)
		"hex":
			_it_hex(s)
		"bell":
			_it_bell(s)
		"seal":
			_it_seal(s)
		_:
			pass


# 木剑 = 竖直 剑 (剑尖 三角 + 剑身 + 剑格 + 柄 珠, 与 部位 剑 斜向 区分)
func _it_sword(s: float) -> void:
	var c := GOLD
	var w := _lw(s)
	draw_colored_polygon(PackedVector2Array([_V(12, 3.5, s), _V(14.5, 8, s), _V(9.5, 8, s)]), c)
	draw_line(_V(12, 8, s), _V(12, 15.5, s), c, w * 1.6)
	draw_line(_V(9.5, 15.5, s), _V(14.5, 15.5, s), c, w)
	draw_line(_V(12, 15.5, s), _V(12, 18.5, s), c, w)
	draw_circle(_V(12, 19.2, s), 0.9 * s, c)


# 玉符 = 斜置 玉牌 (45° 方 牌 + 中心 纹 点)
func _it_talisman(s: float) -> void:
	var c := GOLD
	draw_colored_polygon(PackedVector2Array([_V(12, 4.5, s), _V(18, 12, s), _V(12, 19.5, s), _V(6, 12, s)]), c)
	draw_circle(_V(12, 12, s), 1.2 * s, BG_COL)


# 聚灵袋 = 束口 灵囊 (囊 体 圆 + 束口 绳 结 + 囊 底 褶)
func _it_bag(s: float) -> void:
	var c := GOLD
	var w := _lw(s)
	draw_circle(_V(12, 14.5, s), 4.8 * s, c)
	draw_line(_V(9.5, 9.5, s), _V(12, 7, s), c, w)
	draw_line(_V(14.5, 9.5, s), _V(12, 7, s), c, w)
	draw_circle(_V(12, 7, s), 1.0 * s, c)
	draw_line(_V(9, 17, s), _V(15, 17, s), _accent(), w * 0.7)


# 引星灯 = 灯 座 + 星焰 (灯 座 梯 + 杆 + 四芒 星)
func _it_lamp(s: float) -> void:
	var c := GOLD
	var w := _lw(s)
	draw_colored_polygon(PackedVector2Array([_V(8.5, 18.5, s), _V(15.5, 18.5, s), _V(14, 15.5, s), _V(10, 15.5, s)]), c)
	draw_line(_V(12, 15.5, s), _V(12, 11.5, s), c, w)
	draw_line(_V(12, 4.5, s), _V(12, 10, s), c, w)
	draw_line(_V(8.5, 7.2, s), _V(15.5, 7.2, s), c, w)


# 仙音笛 = 斜笛 (笛 身 长 段 + 笛 头 + 3 音孔)
func _it_flute(s: float) -> void:
	var c := GOLD
	var w := _lw(s)
	draw_line(_V(6.5, 17.5, s), _V(17.5, 6.5, s), c, w * 1.5)
	draw_circle(_V(18.2, 5.8, s), 1.2 * s, c)
	draw_circle(_V(10, 14, s), 0.7 * s, BG_COL)
	draw_circle(_V(12.5, 11.5, s), 0.7 * s, BG_COL)
	draw_circle(_V(15, 9, s), 0.7 * s, BG_COL)


# 星槎 = 星船 (船 体 梯 + 船 头 尖 + 桅 + 帆 尖)
func _it_boat(s: float) -> void:
	var c := GOLD
	var w := _lw(s)
	draw_colored_polygon(PackedVector2Array([_V(5.5, 14, s), _V(18.5, 14, s), _V(15, 18.5, s), _V(9, 18.5, s)]), c)
	draw_line(_V(18.5, 14, s), _V(20.5, 12, s), c, w)
	draw_line(_V(12, 14, s), _V(12, 5.5, s), c, w)
	draw_colored_polygon(PackedVector2Array([_V(12, 6, s), _V(16.5, 9, s), _V(12, 11, s)]), c)


# 太虚镜 = 圆镜 (外 镜 环 + 内 环 + 中心 镜面 点)
func _it_mirror(s: float) -> void:
	var c := GOLD
	var w := _lw(s)
	draw_arc(_V(12, 12, s), 6.5 * s, 0.0, TAU, 20, c, w)
	draw_arc(_V(12, 12, s), 4.0 * s, 0.0, TAU, 16, c, w * 0.6)
	draw_circle(_V(12, 12, s), 1.0 * s, c)


# 太初道灯 = 六角 灯 (六 边形 灯 体 + 中心 焰 + 顶 钮)
func _it_hex(s: float) -> void:
	var c := GOLD
	var pts := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0 - PI / 2.0
		pts.append(_V(12 + 6.0 * cos(a), 13 + 6.0 * sin(a), s))
	draw_colored_polygon(pts, c)
	draw_circle(_V(12, 13, s), 1.6 * s, _accent())
	draw_circle(_V(12, 5.5, s), 0.9 * s, c)


# 鸿蒙道钟 = 钟 (钟 钮 + 钟 身 弧 + 钟 唇 + 钟 舌)
func _it_bell(s: float) -> void:
	var c := GOLD
	var w := _lw(s)
	draw_circle(_V(12, 6, s), 1.0 * s, c)
	draw_line(_V(12, 7, s), _V(12, 9, s), c, w)
	draw_arc(_V(12, 13, s), 5.5 * s, PI, TAU, 16, c, w)
	draw_line(_V(6.5, 13, s), _V(6.5, 15.5, s), c, w)
	draw_line(_V(17.5, 13, s), _V(17.5, 15.5, s), c, w)
	draw_line(_V(6.5, 15.5, s), _V(17.5, 15.5, s), c, w * 1.2)
	draw_circle(_V(12, 17.5, s), 0.8 * s, c)


# 渡劫引仙印 = 双 方 印 (外 方 印 + 内 方 印 + 印心)
func _it_seal(s: float) -> void:
	var c := GOLD
	var w := _lw(s)
	draw_rect(Rect2(_V(6.5, 6.5, s), Vector2(11.0 * s, 11.0 * s)), c)
	draw_rect(Rect2(_V(9.5, 9.5, s), Vector2(5.0 * s, 5.0 * s)), c)
	draw_circle(_V(12, 12, s), 0.9 * s, BG_COL)
