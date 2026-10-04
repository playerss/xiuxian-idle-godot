extends SceneTree
## P3-2 正确性 fuzz: 随机/遍历状态组合下 断言 缓存路径 == 全量参照 恒等
## (onekey_summary_vals / onekey_segment_tips / rate_compose_tip / stone_next_target_tip / inline)
## 用法: ~/bin/godot --headless --path . -s res://scripts/perf_fuzz_p32.gd

var g: Node
var rng := RandomNumberGenerator.new()

func _init() -> void:
	var script: GDScript = load("res://scripts/game_data.gd")
	g = script.new()
	root.add_child(g)
	await process_frame
	rng.seed = 143
	var fails := 0
	var cases := 800
	for cat_i in 3:
		var cat: String = ["", "sword", "spell"][cat_i]
		var tier: int = [-1, 0, 2][cat_i]
		for i in range(cases):
			_mutate(i + cat_i * 1000)
			var p := "c%d_%d" % [cat_i, i]
			var v_c: Array = g.onekey_summary_vals(cat, tier)
			var v_f: Array = _ref_vals(cat, tier)
			if str(v_c) != str(v_f):
				printerr("FAIL vals @", p, str(v_c), str(v_f)); fails += 1
			var t_c: Array = g.onekey_segment_tips(cat, tier)
			var t_f: Array = _ref_tips(cat, tier)
			if str(t_c) != str(t_f):
				printerr("FAIL tips @", p, " cache=", str(t_c).left(40), " ref=", str(t_f).left(40)); fails += 1
			if str(g.rate_compose_tip()) != str(g._rate_compose_tip_full()):
				printerr("FAIL rc @", p); fails += 1
			if str(g.stone_next_target_tip()) != str(g._stone_next_target_tip_full()):
				printerr("FAIL snst @", p); fails += 1
			if str(g.stone_next_target_inline()) != str(g._stone_next_target_inline_full()):
				printerr("FAIL sni @", p); fails += 1
			# 缓存命中路径 恒等
			if str(g.onekey_summary_vals(cat, tier)) != str(v_c):
				printerr("FAIL vals-repeat @", p); fails += 1
			# 只动 离散无关 连续量(essence/dao) → sig 必同 键命中, 六段 明细/数值 必须完全一致
			# (qi/stone 速率 = 离散态 函数 无 连续输入; essence/dao 不 进入 六项/六段 文本)
			var before_v: Array = g.onekey_summary_vals(cat, tier)
			var before_tip2: String = str(g.onekey_btn_tip(2))
			g.essence *= 1.0 + rng.randf_range(-1e-6, 1e-6)
			g.dao *= 1.0 + rng.randf_range(-1e-6, 1e-6)
			if str(g.onekey_summary_vals(cat, tier)) != str(before_v):
				printerr("FAIL cont-vals @", p); fails += 1
			if str(g.onekey_btn_tip(2)) != before_tip2:
				printerr("FAIL cont-cast @", p); fails += 1
	print("FUZZ_DONE fails=", fails)
	quit(0 if fails == 0 else 1)

func _ref_vals(cat: String, tier: int) -> Array:
	return [g.learn_available_count(cat, tier), g.active_learn_available_count(cat, tier),
		g.active_ready_count(), g.item_affordable_count(), g.equip_affordable_count(),
		g.equip_best_pending()]

func _ref_tips(cat: String, tier: int) -> Array:
	return [g._ok_tip_learn(cat, tier, false), g._ok_tip_learn(cat, tier, true),
		g._ok_tip_cast(), g._ok_tip_item(), g._ok_tip_equip(), g._ok_tip_best()]

func _mutate(seed_i: int) -> void:
	var g2 := g
	g2.ascended = (seed_i % 3 == 0)
	g2.dao_level = rng.randi_range(0, 8)
	g2.realm_idx = rng.randi_range(0, 9)
	g2.layer = rng.randi_range(1, 9)
	g2.essence = rng.randf() * rng.randf() * 1e12
	g2.dao = rng.randf() * rng.randf() * 1e9
	g2.stones = rng.randf() * rng.randf() * 5e6
	var learned_new: Array[String] = []
	for sid in g2.skill_ids:
		if rng.randf() < 0.35:
			learned_new.append(str(sid))
	g2.learned.assign(learned_new)
	var ow: Array[String] = []
	for it in g2.ITEMS:
		if rng.randf() < 0.3:
			ow.append(str(it["id"]))
	g2.owned.assign(ow)
	var oe: Array[String] = []
	for eid in g2.equip_ids:
		if rng.randf() < 0.25:
			oe.append(str(eid))
	g2.owned_eq.assign(oe)
	var eqd := {}
	for slot in g2.SLOTS:
		eqd[slot] = ""
	if not oe.is_empty() and rng.randf() < 0.7:
		var w: Array = oe
		eqd[str(g2.SLOTS[0])] = w[rng.randi() % w.size()]
	g2.equipped = eqd
	var al := {}
	for _k in range(rng.randi_range(0, 3)):
		var eid2: String = str(g2.equip_ids[rng.randi() % g2.equip_ids.size()])
		var aid: String = str(g2.affix_ids[rng.randi() % g2.affix_ids.size()])
		var inner := {}
		inner[0] = aid
		al[eid2] = inner
	g2.affix_load = al
	var cd := {}
	for sid in g2.skill_ids:
		var s: Dictionary = g2.skill_by_id.get(str(sid), {})
		if not s.is_empty() and str(s.get("type", "")) == "active" and g2.learned.has(str(sid)):
			if rng.randf() < 0.6:
				cd[str(sid)] = rng.randf() * 600.0
	g2._active_cd = cd
