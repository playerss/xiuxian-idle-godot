extends Node
## M8-1 打磨-153 + M8-2 打磨-154 + M8-3 打磨-155a 像素探针: SubViewport 真实渲染
## ① monster_icon 6 类剪影 + Boss 层隐藏口径 (153a)
## ② equip_icon 5 部位剪影 (5 枚 互异 非空 + 主色 命中) + 法器 金边 前 2 字 徽章
##    (10 枚 金 色 命中 + 区域 像素 不重 不空 + 未设态 全透明) (154a)
## ③ skill_icon 5 类字形 (sword/spell/mind/body/divine 互异 非空 + 类别 主色 命中)
##    + 24 主动 金色 爆发 描边 档 (被动/主动 两 行 同 键 对照: 主色 恒等 + 主动 金 命中
##    + 两 档 hash 区分 防 描边 未 生效 + 未设态 全透明) (155a)
## 用法 (需 X 环境/Xvfb, 勿加 --headless, 与 store_shots 同口径):
##   xvfb-run -a ~/bin/godot --path . res://scenes/icon_probe.tscn
## 口径: 真实 渲染 像素 采样 — 采样区 非空 (不透明 像素 > 阈值) + 主色 命中 比例
## (颜色 = 单源 色 表); 区域 像素 hash 互异 断言 同 类 不同 枚 不 混; 未设态 区域 全 透明
## (UI 隐藏 口径 0 不透明 像素); 退出码 0/1 可 接 CI。

const W := 512
const H := 880
const CATS: Array = ["妖兽", "鬼修", "虫群", "精怪", "凶灵", "天兽"]
const TOL := 0.25        # 主色 像素 匹配 距离 容差 (抗锯齿 边缘 混色)
const MIN_BODY := 0.07   # 区域 内 主色 像素 占比 下限 (剪影 躯体 非空; 0.07 = 抗锯齿 抖动 余量 —
                          # weapon 剪影 体量 恰 0.08 档, 边缘 混色 像素 跨 渲染 会话 抖动 致
                          # 0.0799/0.0800 边界 flake, 155a 复跑 实测 定稿)
const MIN_OPA := 40      # 区域 不透明 像素 下限 (非空)
const ICON := 72        # 探针 实际 渲染 尺寸 (24 基准 x3, 放大 采样 精度)
# 法器 徽章 金色 占比 下限 (金边 环 + 金字 笔画, 低于 部位 剪影 体量)
const MIN_GOLD := 0.10
# 主动 神通 爆发 描边 金 占比 下限 (金环 + 4 芒 火花, 体量 低于 法器 金边 环)
const MIN_SKILL_GOLD := 0.04
# 区域 坐标 (怪物 6 格 2 行 3 列 y=40/200, Boss 格 y=340; 装备 部位 5 格 y=450,
# 法器 10 格 2 行 5 列 y=540/620; 技能 5 类 字形 2 行 5 列 被动 y=710 / 主动 y=790)
const SLOT_X := 40
const SLOT_Y := 450
const ITEM_X := 40
const ITEM_Y := 530
const CELL := 80
const SKILL_X := 40
const SKILL_Y := 710
const SKILL_A_Y := 790
const SKILL_CATS: Array = ["sword", "spell", "mind", "body", "divine"]


var _sub: SubViewport
var _frames := 0
var _done := false
var _fail: Array[String] = []


func _ready() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(W, H)
	_sub.transparent_bg = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub)
	# ① 怪物 6 类别 (153a 口径 不变)
	for i in CATS.size():
		var cn: String = str(CATS[i])
		var ic: Control = (load("res://scripts/monster_icon.gd").new())
		ic.set_category(cn, GameData.MONSTER_CAT_COLORS[cn])
		ic.position = Vector2(40.0 + float(i % 3) * 150.0, 40.0 + float(i / 3) * 160.0)
		ic.size = Vector2(ICON, ICON)
		_sub.add_child(ic)
	# Boss 层 口径: 未设 类别 -> _draw 早退 全 透明 (UI 隐藏 口径 同源)
	_boss = (load("res://scripts/monster_icon.gd").new())
	_boss.position = Vector2(40.0, 340.0)
	_boss.size = Vector2(ICON, ICON)
	_sub.add_child(_boss)
	# ② 装备 5 部位 剪影 (154a: 部位 主色 单源 GameData.EQUIP_SLOT_COLORS)
	var slots: Array = ["weapon", "robe", "amulet", "bead", "boot"]
	for i in slots.size():
		var sl: String = str(slots[i])
		var ic2: Control = (load("res://scripts/equip_icon.gd").new())
		ic2.set_slot(sl, GameData.equip_slot_color(sl))
		ic2.position = Vector2(float(SLOT_X + i * CELL), float(SLOT_Y))
		ic2.size = Vector2(ICON, ICON)
		_sub.add_child(ic2)
	# ③ 法器 10 件 金边 逐件 几何 徽章 (154a: 字形 索引 单源 GameData.item_glyph_index,
	# 几何 图形 同 153/154 部位 剪影 同 确定性 口径, 字体 字形 像素 不可靠 已 弃用)
	var items: Array = [
		"wooden_sword", "jade_talisman", "spirit_bag", "star_lamp", "immortal_flute",
		"star_dock", "void_mirror", "primordial_lamp", "chaos_bell", "ascension_seal"]
	for i in items.size():
		var iid: String = str(items[i])
		var gi: int = GameData.item_glyph_index(iid)
		var ic3: Control = (load("res://scripts/equip_icon.gd").new())
		ic3.set_item_index(gi)
		ic3.position = Vector2(float(ITEM_X + (i % 5) * CELL), float(ITEM_Y + (i / 5) * CELL))
		ic3.size = Vector2(ICON, ICON)
		_sub.add_child(ic3)
	# ④ 部位 未设态 全透明 口径 (UI 隐藏 同源; 位置 避开 怪物 6 格 采样区)
	_empty = (load("res://scripts/equip_icon.gd").new())
	_empty.position = Vector2(430.0, 40.0)
	_empty.size = Vector2(ICON, ICON)
	_sub.add_child(_empty)
	# ⑤ 功法/神通 5 类 字形 (155a: 类别 主色 单源 GameData.SKILL_CAT_COLORS;
	# 被动 无 描边 行 y=710 + 主动 金爆发 描边 行 y=790, 5 类 同 键 两 档 对照)
	for i in SKILL_CATS.size():
		var ck: String = str(SKILL_CATS[i])
		var icp: Control = (load("res://scripts/skill_icon.gd").new())
		icp.set_category(ck, GameData.skill_category_color(ck), false)
		icp.position = Vector2(float(SKILL_X + i * CELL), float(SKILL_Y))
		icp.size = Vector2(ICON, ICON)
		_sub.add_child(icp)
		var icv: Control = (load("res://scripts/skill_icon.gd").new())
		icv.set_category(ck, GameData.skill_category_color(ck), true)
		icv.position = Vector2(float(SKILL_X + i * CELL), float(SKILL_A_Y))
		icv.size = Vector2(ICON, ICON)
		_sub.add_child(icv)
	# ⑥ 技能 未设态 全透明 口径 (位置 避开 采样区)
	_skill_empty = (load("res://scripts/skill_icon.gd").new())
	_skill_empty.position = Vector2(430.0, 340.0)
	_skill_empty.size = Vector2(ICON, ICON)
	_sub.add_child(_skill_empty)


var _boss: Control
var _empty: Control
var _skill_empty: Control


func _process(_d: float) -> void:
	_frames += 1
	if _frames == 10 and not _done:
		_done = true
		_render_check()


func _region_img(img: Image, rect: Rect2i) -> Image:
	return img.get_region(rect)


func _hash(img: Image) -> int:
	# 区域 像素 逐字节 确定性 hash (同 图 恒 同 hash; 用于 同 族 不同 枚 不 混 断言;
	# PackedByteArray 无 hash() 方法 [4.4], 自 实现 fnv 式 累加)
	var bytes: PackedByteArray = img.get_data()
	var h := 2166136261
	for b in bytes:
		h = (h ^ int(b)) * 16777619
		h = h & 0xFFFFFFFF
	return h


func _render_check() -> void:
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img: Image = _sub.get_texture().get_image()
	if img == null or img.is_empty():
		_fail.append("探针: 图像为空 (渲染失败?)")
		_finish()
		return
	# ① 怪物 6 类别 (153a 口径 不变)
	for i in CATS.size():
		var cn: String = str(CATS[i])
		var col: Color = GameData.MONSTER_CAT_COLORS[cn]
		var rect := Rect2i(40 + (i % 3) * 150, 40 + (i / 3) * 160, ICON, ICON)
		_probe_body(img, rect, col, cn)
	# Boss 层: 全 透明 (无 类别 = 不 绘制)
	var br := Rect2i(40, 340, ICON, ICON)
	var bop := 0
	for y in br.size.y:
		for x in br.size.x:
			if img.get_pixel(br.position.x + x, br.position.y + y).a > 0.1:
				bop += 1
	if bop > 0:
		_fail.append("Boss 层 (未设 类别) 应 全 透明 (实际 %d 不透明 像素)" % bop)
	# ② 装备 5 部位: 非空 + 主色 命中 + 区域 互异
	var slots: Array = ["weapon", "robe", "amulet", "bead", "boot"]
	var sh: Array = []
	for i in slots.size():
		var sl: String = str(slots[i])
		var col: Color = GameData.EQUIP_SLOT_COLORS[sl]
		var rect := Rect2i(SLOT_X + i * CELL, SLOT_Y, ICON, ICON)
		_probe_body(img, rect, col, "部位-" + sl)
		sh.append(_hash(_region_img(img, rect)))
	for i in sh.size():
		for j in range(i + 1, sh.size()):
			if sh[i] == sh[j]:
				_fail.append("部位 剪影 区域 像素 混同 (hash 相等, 同 类 不同 枚 不 混 口径)")
				break
	# ③ 法器 10 枚: 非空 + 金色 命中 + 区域 互异 (前 2 字 不同 => 像素 不同)
	var items: Array = [
		"wooden_sword", "jade_talisman", "spirit_bag", "star_lamp", "immortal_flute",
		"star_dock", "void_mirror", "primordial_lamp", "chaos_bell", "ascension_seal"]
	var gold: Color = GameData.EQUIP_ITEM_COLOR
	var ih: Array = []
	for i in items.size():
		var iid: String = str(items[i])
		var rect := Rect2i(ITEM_X + (i % 5) * CELL, ITEM_Y + (i / 5) * CELL, ICON, ICON)
		var opaque := 0
		var gpx := 0
		for y in rect.size.y:
			for x in rect.size.x:
				var px: Color = img.get_pixel(rect.position.x + x, rect.position.y + y)
				if px.a > 0.5:
					opaque += 1
					var d: float = absf(px.r - gold.r) + absf(px.g - gold.g) + absf(px.b - gold.b)
					if d / 3.0 < TOL:
						gpx += 1
		var tot: int = rect.size.x * rect.size.y
		if opaque < MIN_OPA:
			_fail.append("%s: 不透明像素 不足 (%d < %d, 非空 口径)" % [iid, opaque, MIN_OPA])
		if float(gpx) / float(tot) < MIN_GOLD:
			_fail.append("%s: 金色 占比 不足 (%.3f < %.3f, 金边/金字 渲染 缺失)" % [iid, float(gpx) / float(tot), MIN_GOLD])
		ih.append(_hash(_region_img(img, rect)))
	for i in ih.size():
		for j in range(i + 1, ih.size()):
			if ih[i] == ih[j]:
				_fail.append("法器 徽章 区域 像素 混同 (%d=%s vs %d=%s, 10 枚 逐件 字形 不重 口径)" % [i, str(items[i]), j, str(items[j])])
				break
	# ④ 部位 未设态 全 透明 (UI 隐藏 口径 同源)
	var er := Rect2i(430, 40, ICON, ICON)
	var eop := 0
	for y in er.size.y:
		for x in er.size.x:
			if img.get_pixel(er.position.x + x, er.position.y + y).a > 0.1:
				eop += 1
	if eop > 0:
		_fail.append("部位 未设态 应 全 透明 (实际 %d 不透明 像素)" % eop)
	# ⑤ 技能 5 类 字形: 被动 行 非空 + 类别 主色 命中 + 区域 互异; 主动 行 同 键 主色
	# 恒等 + 金色 爆发 描边 命中 + 两 行 hash 区分 (描边 档 不 混 同 键)
	var shc: Color = GameData.SKILL_ACTIVE_GOLD
	var ph: Array = []
	var ah: Array = []
	for i in SKILL_CATS.size():
		var ck: String = str(SKILL_CATS[i])
		var col: Color = GameData.SKILL_CAT_COLORS[ck]
		var pr := Rect2i(SKILL_X + i * CELL, SKILL_Y, ICON, ICON)
		_probe_body(img, pr, col, "技能 被动-" + ck)
		ph.append(_hash(_region_img(img, pr)))
		var ar := Rect2i(SKILL_X + i * CELL, SKILL_A_Y, ICON, ICON)
		_probe_body(img, ar, col, "技能 主动-" + ck)
		# 主动 行 金色 爆发 描边 占比
		var gpx := 0
		for y in ar.size.y:
			for x in ar.size.x:
				var px: Color = img.get_pixel(ar.position.x + x, ar.position.y + y)
				var d: float = absf(px.r - shc.r) + absf(px.g - shc.g) + absf(px.b - shc.b)
				if d / 3.0 < TOL:
					gpx += 1
		var tot: int = ar.size.x * ar.size.y
		if float(gpx) / float(tot) < MIN_SKILL_GOLD:
			_fail.append("技能 主动-%s: 金色 爆发 描边 占比 不足 (%.3f < %.3f, 描边 渲染 缺失)" % [ck, float(gpx) / float(tot), MIN_SKILL_GOLD])
		ah.append(_hash(_region_img(img, ar)))
	for i in ph.size():
		for j in range(i + 1, ph.size()):
			if ph[i] == ph[j]:
				_fail.append("技能 字形 区域 像素 混同 (hash 相等, 5 类 不同 枚 不 混 口径)")
				break
	for i in ah.size():
		for j in range(i + 1, ah.size()):
			if ah[i] == ah[j]:
				_fail.append("技能 主动 字形 区域 像素 混同 (hash 相等, 5 类 不同 枚 不 混 口径)")
				break
	for i in ph.size():
		if ph[i] == ah[i]:
			_fail.append("技能 %s: 被动/主动 两 档 像素 混同 (金色 爆发 描边 未 生效)" % str(SKILL_CATS[i]))
	# ⑥ 技能 未设态 全 透明 (UI 隐藏 口径 同源)
	var sr := Rect2i(430, 340, ICON, ICON)
	var sop := 0
	for y in sr.size.y:
		for x in sr.size.x:
			if img.get_pixel(sr.position.x + x, sr.position.y + y).a > 0.1:
				sop += 1
	if sop > 0:
		_fail.append("技能 未设态 应 全 透明 (实际 %d 不透明 像素)" % sop)
	_finish()


func _probe_body(img: Image, rect: Rect2i, col: Color, tag: String) -> void:
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
		_fail.append("%s: 不透明像素 不足 (%d < %d, 非空 口径)" % [tag, opaque, MIN_OPA])
	if float(body) / float(tot) < MIN_BODY:
		_fail.append("%s: 主色占比 不足 (%.3f < %.3f, 颜色 != 部位 主色)" % [tag, float(body) / float(tot), MIN_BODY])


func _finish() -> void:
	if _fail.is_empty():
		print("ICON_PROBE PASS (6 类 非空 + 主色 命中 + Boss 层 隐藏 + 5 部位 互异 + 10 法器 金 命中 不重 + 未设态 全透明 + 5 技能 字形 互异 + 主动 金 爆发 描边 两 档 区分 + 技能 未设态 全透明)")
		get_tree().quit(0)
	else:
		printerr("ICON_PROBE FAIL (%d 项):" % _fail.size())
		for x in _fail:
			printerr("  - " + x)
		get_tree().quit(1)
