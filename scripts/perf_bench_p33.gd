extends Node
## perf(M9-P) P3-3 微基准 runner (scene 模式, 推荐 --headless):
## 实例化 main 场景, 逐 Tab 手动驱动 ui._refresh(), 测 脚本侧 us/帧。
## 口径: headless 渲染底噪隔离, 量化 = _refresh 脚本成本 (门控收益 = 省掉的 us/帧)。
## 对照: 同工具 P3-1/P3-2 前 6 tab? 不 — 这里 tab 0/1/2 (修行/技能/装备), 每 tab 60 帧均值。

const N := 60

var ui: Node
var _tab_i := 0
var _frames := 0
var _t0 := 0
var _lines: Array[String] = []
var _acc := 0.0


func _ready() -> void:
	var sp: String = GameData.SAVE_PATH
	var old := FileAccess.open(sp, FileAccess.READ)
	if old != null:
		old.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sp))
	GameData.realm_idx = 6
	GameData.layer = 5
	GameData.essence = 5e9
	GameData.stones = 9e8
	for i in 40:
		GameData.learned.append(str(GameData.skill_ids[i]))
	for i in 30:
		GameData.owned_eq.append(str(GameData.equip_ids[i]))
	var script: GDScript = load("res://scripts/main.gd")
	ui = Control.new()
	ui.set_script(script)
	ui.size = Vector2(1920, 1080)
	get_tree().root.size = Vector2i(1920, 1080)
	get_tree().root.add_child.call_deferred(ui)
	await get_tree().process_frame
	await get_tree().process_frame
	ui.set_process(false)
	ui._refresh()
	_next()


func _next() -> void:
	if _tab_i > 2:
		print("== perf_bench_p33 ==")
		for l in _lines:
			print(l)
		print("BENCH DONE")
		get_tree().quit(0)
		return
	ui._tab.current_tab = _tab_i
	await get_tree().process_frame
	ui._refresh()
	ui._refresh()
	_frames = 0
	_acc = 0.0
	_measure()


func _measure() -> void:
	if _frames >= N:
		_lines.append("tab=%d _refresh avg %.1f us/frame (%d frames)" % [_tab_i, _acc / float(N), N])
		_tab_i += 1
		await _next()
		return
	var t0 := Time.get_ticks_usec()
	ui._refresh()
	_acc += float(Time.get_ticks_usec() - t0)
	_frames += 1
	await get_tree().process_frame
	_measure()
