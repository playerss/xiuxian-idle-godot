extends SceneTree
## perf(M9-P) P3-1 微基准: 5 个 tooltip 接口与组件的 us/call (headless, -s 模式)

var g: Node
var _fns: Array = []
var _names: Array = []

func _init() -> void:
	var script: GDScript = load("res://scripts/game_data.gd")
	g = script.new()
	root.add_child(g)
	await process_frame
	var N := 2000
	_names = ["qi_per_sec", "stone_per_sec", "passive_qi", "passive_all", "equip_qi",
		"auto_cast_next_tip", "auto_buy_next_tip", "auto_learn_next_tip",
		"auto_break_next_tip", "offline_preview_tip",
		"stone_next_target", "learn_available_count", "active_ready_count"]
	_fns = [
		func(): return g.qi_per_sec(),
		func(): return g.stone_per_sec(),
		func(): return g.passive_bonus("qi_mult"),
		func(): return g.passive_bonus("all_mult"),
		func(): return g.equip_bonus("qi_mult"),
		func(): return g.auto_cast_next_tip(),
		func(): return g.auto_buy_next_tip(),
		func(): return g.auto_learn_next_tip(),
		func(): return g.auto_break_next_tip(),
		func(): return g.offline_preview_tip(),
		func(): return str(g.stone_next_target()),
		func(): return g.learn_available_count(),
		func(): return g.active_ready_count()]
	print("state: learned=", g.learned.size(), " realm=", g.realm_idx, " layer=", g.layer)
	for i in range(len(_names)):
		var f: Callable = _fns[i]
		f.call()
		var t0 := Time.get_ticks_usec()
		for _j in N:
			f.call()
		var us := float(Time.get_ticks_usec() - t0) / float(N)
		print("%-22s %.2f us/call" % [str(_names[i]), us])
	print("BENCH_DONE")
	quit()
