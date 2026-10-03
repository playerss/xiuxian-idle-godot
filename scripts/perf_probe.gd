extends Node
## M9-P P1 热点定位探针：真实渲染窗口三态对照采样。
## 用法: 先种档 ~/bin/godot --headless --path . -s res://scripts/playtest_seed.gd
##      再 DISPLAY=:99 ~/bin/godot --path . res://scenes/perf_probe.tscn
## 环境: PERF_SEC=每态秒数(默认130, 冒烟可用 10), PERF_STATES=idle,tower,break
## 输出: user://playtest/prof/<state>.csv
## 口径: Godot 4.4 无 time_draw/draw_calls 的 Performance 常量(3.x 遗名)——
##      fps/脚本耗时 用 Performance.TIME_FPS/TIME_PROCESS/TIME_PHYSICS_PROCESS,
##      渲染层 draw_calls 与图元数 用 RenderingServer.get_rendering_info 同源指标。

const OUT_DIR := "user://playtest/prof"
const SAMPLE_EVERY := 0.5

var _main: Node = null
var _t := 0.0
var _state_t := 0.0
var _acc := 0.0
var _state_i := 0
var _sec_per_state := 130.0
var _states: Array[String] = ["idle", "tower", "break"]
var _files := {}


func _ready() -> void:
	var sec_env: String = OS.get_environment("PERF_SEC")
	if sec_env.is_valid_int():
		_sec_per_state = clampf(float(sec_env.to_int()), 5.0, 3600.0)
	var st_env: String = OS.get_environment("PERF_STATES")
	if st_env.length() > 0:
		_states.assign(st_env.split(","))
	# PERF_BG=0 关闭水墨背景 (P1 归因实验: 粒子/绘制层 vs 脚本热路径判别, 不改代码)
	var bg_env: String = OS.get_environment("PERF_BG")
	if bg_env == "0":
		get_node("/root/GameData").bg_on = false
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for s in _states:
		var f := FileAccess.open(OUT_DIR + "/" + s + ".csv", FileAccess.WRITE)
		if f:
			f.store_line("t,fps,time_process,time_physics,draw_calls,primitives,node_count,realm,layer,essence,stones,ascended")
			_files[s] = f
	var main_sc := load("res://scenes/main.tscn")
	_main = main_sc.instantiate()
	add_child(_main)
	_apply_state()
	get_tree().create_timer(_sec_per_state * _states.size() + 2.0).timeout.connect(_finish)


func _g() -> Node:
	return get_node("/root/GameData")


func _apply_state() -> void:
	var g = _g()
	# 三态共同点：全部自动开关先关，再按态单独开（保证归因干净；break 态另加注入）
	g.auto_break = false
	g.auto_learn = false
	g.auto_buy = false
	g.auto_cast = false
	g.auto_tower = false
	match _states[_state_i]:
		"idle":
			pass
		"tower":
			g.auto_tower = true
		"break":
			g.auto_break = true


func _process(delta: float) -> void:
	_t += delta
	_state_t += delta
	_acc += delta
	# break 态：每 0.5 秒注入 3 倍突破成本，保证高频突破循环（飞升后注入道行口径）
	if _states[_state_i] == "break" and _acc >= 0.5:
		var g = _g()
		if g.ascended:
			g.dao += g.dao_break_cost() * 3.0
		else:
			g.essence += g.breakthrough_cost() * 3.0
	if _acc >= SAMPLE_EVERY:
		_acc -= SAMPLE_EVERY
		_sample()
	if _state_t >= _sec_per_state:
		_state_t = 0.0
		_state_i += 1
		if _state_i >= _states.size():
			_finish()
		else:
			_apply_state()


func _finish() -> void:
	for f in _files.values():
		if f != null:
			f.close()
	print("PERF_DONE states=", _states, " sec_per=", _sec_per_state)
	get_tree().quit()


func _sample() -> void:
	var s: String = _states[_state_i]
	var f = _files.get(s)
	if f == null:
		return
	var g = _g()
	var row: Array[String] = [
		str(int(_t)),
		str(Performance.get_monitor(Performance.TIME_FPS)),
		str(Performance.get_monitor(Performance.TIME_PROCESS)),
		str(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)),
		str(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)),
		str(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)),
		str(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))),
		str(g.realm_idx), str(g.layer), str(g.essence), str(g.stones), str(g.ascended),
	]
	f.store_line(",".join(row))
