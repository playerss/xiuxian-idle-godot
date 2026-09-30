extends Node
## 机器试玩 bot：真实窗口渲染 + 真实鼠标事件点 UI + 类人节奏，长时间挂机观测。
## 用法: DISPLAY=:99 ~/bin/godot --path . res://scenes/playtest_run.tscn
## 离线模式: PLAYTEST_MODE=offline 时只跑 30 秒观测读档离线收益。
## 输出: user://playtest/ (log.csv, shots/, results.json / offline.json)

const TOTAL_SEC_DEFAULT := 1500.0  # 试玩总时长 (25 分钟)
var _total_sec := TOTAL_SEC_DEFAULT   # PLAYTEST_SEC env 可覆盖
const SNAP_EVERY := 5.0          # 快照采样间隔
const SHOT_EVERY := 60.0         # 截图间隔
const OUT_DIR := "user://playtest"

var ui: Node = null
var t := 0.0
var _next_act := 5.0
var _act_turn := 0
var _next_shot := 3.0
var _next_snap := 3.0
var _clicks := 0
var _fails: Array[String] = []
var _shot_n := 0
var _offline_mode := false
var _plan_order: Array[String] = [
	"TAB1", "一键领悟", "一键施展",
	"TAB2", "一键购买", "一键最佳",
	"TAB0", "突破", "TAB1", "一键神通",
	"TAB4", "挑战", "TAB0",
	"TAB3", "TAB0", "TAB4",
]
var _loiter_order: Array[String] = ["TAB1", "TAB2", "TAB4", "TAB0", "突破"]
var _autos_set := false


func _ready() -> void:
	randomize()
	seed(1337)
	var sec_env: String = OS.get_environment("PLAYTEST_SEC")
	if sec_env.is_valid_int():
		_total_sec = maxf(30.0, float(sec_env.to_int()))
	_offline_mode = OS.get_environment("PLAYTEST_MODE") == "offline"
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(OUT_DIR + "/shots")
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	if _offline_mode:
		await get_tree().create_timer(30.0).timeout
		_write_offline_json()
		_take_shot("offline")
		get_tree().quit()
		return
	var f := FileAccess.open(OUT_DIR + "/log.csv", FileAccess.WRITE)
	if f:
		f.store_line("t,fps,essence,stones,dao,ascended,realm,layer,play_sec,primary_gain,stone_gain,primary_spent,stone_spent,break_ok,break_fail,tower_win,tower_loss,tower_stone,skill_learn,item_buy,equip_buy,affix_drop,mat_gain,mat_spent")
		f.close()
	get_tree().create_timer(_total_sec).timeout.connect(_finish)


func _process(_delta: float) -> void:
	t += _delta
	if _offline_mode:
		return
	if t >= _next_snap:
		_next_snap += SNAP_EVERY
		_snapshot()
	if t >= _next_shot:
		_next_shot += SHOT_EVERY
		_take_shot("run")
	if t >= _next_act:
		_schedule_action()


func _schedule_action() -> void:
	var p1 := _total_sec * 0.12   # 阶段1 纯挂机观察
	var p2 := _total_sec * 0.52   # 阶段2 点按钮巡游
	if t < p1:
		_next_act = t + randf_range(4.0, 8.0)
		return
	if t < p2:
		_next_act = t + randf_range(3.0, 9.0)
		_act(_plan_order[_act_turn % _plan_order.size()])
		_act_turn += 1
	else:
		_next_act = t + randf_range(10.0, 20.0)
		if not _autos_set:
			for a in ["自动领悟", "自动施展", "自动爬塔", "自动购置", "自动突破"]:
				_click_named(a)
			_autos_set = true
		else:
			_act(_loiter_order[_act_turn % 5])
			_act_turn += 1


func _act(step: String) -> void:
	if step == "TAB0":
		_click_tab(0)
	elif step == "TAB1":
		_click_tab(1)
	elif step == "TAB2":
		_click_tab(2)
	elif step == "TAB3":
		_click_tab(3)
	elif step == "TAB4":
		_click_tab(4)
	elif step == "突破":
		_click_named("尝试突破")
	else:
		_click_named(step)


func _finish() -> void:
	var g: Node = get_node("/root/GameData")
	g.save_game()
	var res := {
		"seconds": t, "clicks": _clicks, "fails": _fails,
		"essence": g.essence, "stones": g.stones, "dao": g.dao, "ascended": g.ascended,
		"realm": g.realm_idx, "layer": g.layer, "stats": g.stats,
		"owned": g.owned.size(), "shots": _shot_n,
	}
	var f := FileAccess.open(OUT_DIR + "/results.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(res, "  "))
		f.close()
	print("PLAYTEST_DONE clicks=%d fails=%d" % [_clicks, _fails.size()])
	get_tree().quit()


# ---------- 真实输入：经 viewport.push_input 走 UI 命中测试 ----------

func _hover(pos: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	get_viewport().push_input(m)


func _click_at(pos: Vector2) -> void:
	_hover(pos + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0)))
	var d := InputEventMouseButton.new()
	d.button_index = MOUSE_BUTTON_LEFT
	d.position = pos
	d.global_position = pos
	d.pressed = true
	get_viewport().push_input(d)
	var u := d.duplicate() as InputEventMouseButton
	u.pressed = false
	get_viewport().push_input(u)
	_clicks += 1


func _is_on_screen(n: Node) -> bool:
	var p: Node = n
	while p != null and p != ui:
		if not (p as CanvasItem).is_visible_in_tree():
			return false
		p = p.get_parent()
	return (n as Control).get_global_rect().size.x > 3


func _all_buttons(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_all_buttons(c, out)


func _click_named(prefix: String) -> void:
	var btns: Array = []
	_all_buttons(ui, btns)
	for b in btns:
		if not is_instance_valid(b) or not b.enabled or not _is_on_screen(b):
			continue
		if String(b.text).strip_edges().begins_with(prefix):
			var g: Rect2 = (b as Control).get_global_rect()
			if g.size.x < 3 or g.size.y < 3:
				continue
			_click_at(g.position + g.size * 0.5)
			return
	# 按钮存在但不可见/禁用不算 bug，静默跳过


func _click_tab(i: int) -> void:
	var tab: TabContainer = ui._tab
	var tb: TabBar = tab.get_tab_bar()
	var r: Rect2 = Rect2(tb.get_tab_rect(i))
	var pos: Vector2 = tb.get_global_position() + r.position + r.size * 0.5
	_click_at(pos)


# ---------- 观测 ----------

func _snapshot() -> void:
	var g: Node = get_node("/root/GameData")
	var st: Dictionary = g.stats
	var row := [
		str(int(t)), str(Engine.get_frames_per_second()),
		str(g.essence), str(g.stones), str(g.dao), str(g.ascended), str(g.realm_idx), str(g.layer),
		str(st.get("play_sec", 0)), str(st.get("primary_gain", 0)), str(st.get("stone_gain", 0)),
		str(st.get("primary_spent", 0)), str(st.get("stone_spent", 0)),
		str(st.get("break_ok", 0)), str(st.get("break_fail", 0)),
		str(st.get("tower_win", 0)), str(st.get("tower_loss", 0)), str(st.get("tower_total_stone", 0)),
		str(st.get("skill_learn", 0)), str(st.get("item_buy", 0)), str(st.get("equip_buy", 0)),
		str(st.get("affix_drop", 0)), str(st.get("mat_gain", 0)), str(st.get("mat_spent", 0)),
	]
	var f := FileAccess.open(OUT_DIR + "/log.csv", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line(",".join(row))
		f.close()


func _take_shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_window().get_texture().get_image()
	_shot_n += 1
	var name := "%s_%04d.png" % [tag, int(t)]
	var err := img.save_png(OUT_DIR + "/shots/" + name)
	if err != OK:
		_fails.append("shot err %d" % err)


func _write_offline_json() -> void:
	var g: Node = get_node("/root/GameData")
	var d := {
		"offline_sec": g._offline_sec, "qi": g._offline_qi, "stone": g._offline_stone,
		"essence": g.essence, "stones": g.stones,
		"stats_offline_qi": g.stats.get("offline_total_qi", 0),
		"stats_offline_stone": g.stats.get("offline_total_stone", 0),
		"stats_offline_sec": g.stats.get("offline_total_sec", 0),
		"play_sec": g.stats.get("play_sec", 0),
	}
	var f := FileAccess.open(OUT_DIR + "/offline.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
		f.close()
	print("PLAYTEST_OFFLINE " + JSON.stringify(d))
