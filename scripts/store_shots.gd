extends Node
## 打磨-16: Steam 商店页面素材 — 1920x1080 游戏内截图 (确定性演示档态: 金丹 第 2 层)
## 用法 (需 X 环境/Xvfb, SubViewport 内真实渲染, 与窗口尺寸无关):
##   DISPLAY=:99 ~/bin/godot --path . res://scenes/store_shots.tscn
## 输出: user://store_shots/01_training..04_achievements.png (1920x1080),
##       成功后把 4 张拷贝到 res://store/shots/ 提交。
## 说明: 演示状态为代码构造 (非真实存档), 冻结 GameData 挂机保证 4 张数值一致;
##       运行前后请清理 user 存档, 避免演示档污染真实玩家档。

const W := 1920
const H := 1080
const SHOTS := [
	{"tab": 0, "name": "01_training"},
	{"tab": 1, "name": "02_skills"},
	{"tab": 2, "name": "03_equipment"},
	{"tab": 3, "name": "04_achievements"},
]
const SETTLE_SEC := 1.2     # 每次切页后等待 UI 稳定的秒数

var _sub: SubViewport
var _idx := 0
var _wait := 0.0
var _busy := false
var _fail: Array[String] = []


func _ready() -> void:
	_setup_demo_state()
	_sub = SubViewport.new()
	_sub.size = Vector2i(W, H)
	_sub.transparent_bg = false
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub)
	var ps: PackedScene = load("res://scenes/main.tscn")
	_sub.add_child(ps.instantiate())
	_mkdir()
	_wait = SETTLE_SEC * 1.5  # 首帧多留时间让布局/字体稳定


func _process(delta: float) -> void:
	if _busy:
		return
	_wait += delta
	if _wait < SETTLE_SEC:
		return
	_wait = 0.0
	_busy = true
	_take_next()


func _main() -> Node:
	return _sub.get_child(0)


func _take_next() -> void:
	var ui: Node = _main()
	var sh: Dictionary = SHOTS[_idx]
	ui._tab.current_tab = int(sh["tab"])
	if _idx == 0:
		# 修行页: 底部消息栏放一条成功文案 (商店页观感)
		var s: Dictionary = GameData.skill_by_id.get("spell_1_2", {})
		if not s.is_empty():
			ui._show_msg("领悟「%s」! %s" % [s["name"], s["desc"]])
	elif _idx == 1:
		# 技能页: 触发一次筛选, 已学技能排到列表顶部
		ui._on_filter("")
	# 等该帧渲染完成后再读帧缓冲
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img: Image = _sub.get_texture().get_image()
	if img == null or img.is_empty():
		_fail.append("capture %s: 图像为空 (渲染失败?)" % sh["name"])
		_advance()
		return
	var path := "user://store_shots/%s.png" % sh["name"]
	var err: int = img.save_png(path)
	print("[SHOTS] %s %dx%d err=%d" % [sh["name"], img.get_width(), img.get_height(), err])
	if err != OK:
		_fail.append("save %s err=%d" % [path, err])
	_advance()


func _advance() -> void:
	_idx += 1
	if _idx >= SHOTS.size():
		_finish()
	else:
		_busy = false


func _finish() -> void:
	var abs_dir: String = ProjectSettings.globalize_path("user://store_shots")
	if _fail.is_empty():
		print("[SHOTS] OK %d 张 1920x1080 -> %s" % [SHOTS.size(), abs_dir])
		get_tree().quit(0)
	else:
		for x in _fail:
			printerr("[SHOTS] FAIL: " + x)
		get_tree().quit(1)


func _mkdir() -> void:
	var abs_p: String = ProjectSettings.globalize_path("user://store_shots")
	if not DirAccess.dir_exists_absolute(abs_p):
		DirAccess.make_dir_recursive_absolute(abs_p)


# ---------- 确定性演示状态 (金丹 第 2 层, 已学 12 技能, 4 件装备已穿戴, 3 件法器) ----------

func _setup_demo_state() -> void:
	var g := GameData
	g.set_process(false)  # 冻结挂机/成就/自动存档
	g.realm_idx = 2       # 金丹
	g.layer = 2
	g.essence = 0.4 * g.breakthrough_cost()  # 突破进度 40%
	g.stones = 30000.0
	# 法器: 前 3 件 (x1.5 x2.0 x3.0), 第 4 件 45k 买不起 -> 展示购买 ETA
	g.try_buy_item("wooden_sword")
	g.try_buy_item("jade_talisman")
	g.try_buy_item("spirit_bag")
	# 装备: 4 件不同部位, 购买即自动穿戴 (金框高亮)
	g.buy_equipment("weapon_2_1")   # 玄品 武器
	g.buy_equipment("robe_1_2")     # 灵品 法袍
	g.buy_equipment("amulet_3_0")   # 地品 玉佩
	g.buy_equipment("bead_2_1")     # 玄品 灵珠
	# 技能: 12 个已学 (含主动神通), 触发 skill_10 成就
	for id in ["sword_0_0", "sword_1_1", "sword_2_0", "sword_2_3",
			"spell_0_0", "spell_1_2", "mind_0_0", "mind_1_0",
			"mind_2_1", "body_0_1", "body_1_3", "divine_2_2"]:
		if g.skill_by_id.has(id):
			g.learned.append(id)
	# 修行统计 (打磨-14 展示: 2天4小时 / 突破7 / 神通15 / 法器3 / 装备4)
	g.stats = {
		"play_sec": 193560.0, "break_ok": 7.0, "break_fail": 2.0, "dao_ok": 0.0,
		"skill_use": 15.0, "item_buy": 3.0, "equip_buy": 4.0,
	}
	g.check_achievements()  # 自动解锁 6 个 (境界/首次/法器/技能/装备)
