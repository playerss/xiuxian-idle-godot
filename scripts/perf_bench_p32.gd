extends SceneTree
## perf(M9-P) P3-2 微基准: onekey 键路径 + rc/snt 接口 us/call (headless, -s 模式)

var g: Node
var _fns: Array = []
var _names: Array = []

func _init() -> void:
	var script: GDScript = load("res://scripts/game_data.gd")
	g = script.new()
	root.add_child(g)
	await process_frame
	var N := 2000
	_names = ["onekey_summary_key", "onekey_btn_tip2", "onekey_segment_tips",
		"stone_next_target_tip", "stone_next_target_inline", "rate_compose_tip",
		"learn_available_count", "item_affordable_count", "equip_afford_n"]
	_fns = [
		func(): return g.onekey_summary_key("", -1),
		func(): return g.onekey_btn_tip(2),
		func(): return str(g.onekey_segment_tips("", -1)),
		func(): return g.stone_next_target_tip(),
		func(): return g.stone_next_target_inline(),
		func(): return g.rate_compose_tip(),
		func(): return g.learn_available_count("", -1),
		func(): return g.item_affordable_count(),
		func(): return g._ok_afford_n(false)]
	print("state: learned=", g.learned.size(), " realm=", g.realm_idx)
	for i in range(len(_names)):
		var f: Callable = _fns[i]
		f.call()
		var t0 := Time.get_ticks_usec()
		for _j in N:
			f.call()
		var us := float(Time.get_ticks_usec() - t0) / float(N)
		print("%-26s %.2f us/call" % [str(_names[i]), us])
	print("BENCH_DONE")
	quit()
