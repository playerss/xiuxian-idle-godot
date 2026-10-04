extends SceneTree
## P3-1 正确性 fuzz: 随机/遍历状态组合下 断言 缓存路径 == _full 全量路径 逐字符恒等

var g: Node
var rng := RandomNumberGenerator.new()

func _init() -> void:
	var script: GDScript = load("res://scripts/game_data.gd")
	g = script.new()
	root.add_child(g)
	await process_frame
	rng.seed = 42
	var fails := 0
	var cases := 1500
	for i in range(cases):
		_mutate(i)
		var p := str(i)
		if str(g.auto_buy_next_tip()) != str(g._auto_buy_next_tip_full()):
			printerr("FAIL ab @", p); fails += 1
		if str(g.auto_break_next_tip()) != str(g._auto_break_next_tip_full()):
			printerr("FAIL bk @", p); fails += 1
		if str(g.auto_cast_next_tip()) != str(g._auto_cast_next_tip_full()):
			printerr("FAIL ac @", p); fails += 1
		if str(g.auto_learn_next_tip()) != str(g._auto_learn_next_tip_full()):
			printerr("FAIL al @", p); fails += 1
		if str(g.offline_preview_tip()) != str(g._offline_preview_tip_full()):
			printerr("FAIL op @", p); fails += 1
	# stone_next_target 逐字段恒等 (与 独立重算 参照实现)
	for i in range(300):
		_mutate(1000 + i)
		var a: Dictionary = g.stone_next_target()
		var b: Dictionary = _ref_stone_next()
		var ok: bool = (a.is_empty() == b.is_empty()) and (a.is_empty() or (
			str(a["id"]) == str(b["id"]) and float(a["cost"]) == float(b["cost"])
			and float(a["shortfall"]) == float(b["shortfall"])))
		if not ok:
			printerr("FAIL snt @", i, str(a), str(b)); fails += 1
	print("FUZZ_DONE fails=", fails)
	quit(0 if fails == 0 else 1)

func _mutate(seed_i: int) -> void:
	var g2 := g
	# 离散状态
	g2.ascended = (seed_i % 3 == 0)
	g2.dao_level = rng.randi_range(0, 8)
	g2.realm_idx = rng.randi_range(0, 9)
	g2.layer = rng.randi_range(1, 9)
	g2.essence = rng.randf() * rng.randf() * 1e12
	g2.dao = rng.randf() * rng.randf() * 1e9
	g2.stones = rng.randf() * rng.randf() * 1e10
	# learned 子集
	var learned_new: Array[String] = []
	for sid in g2.skill_ids:
		if rng.randf() < 0.35:
			learned_new.append(str(sid))
	g2.learned.assign(learned_new)
	# owned / owned_eq 子集
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
	# equipped
	var eqd := {}
	for slot in g2.SLOTS:
		eqd[slot] = ""
	if not oe.is_empty() and rng.randf() < 0.7:
		var w: Array = oe
		eqd[str(g2.SLOTS[0])] = w[rng.randi() % w.size()]
	g2.equipped = eqd
	# affix_load 随机
	var al := {}
	for _k in range(rng.randi_range(0, 3)):
		var eid2: String = str(g2.equip_ids[rng.randi() % g2.equip_ids.size()])
		var aid: String = str(g2.affix_ids[rng.randi() % g2.affix_ids.size()])
		var inner := {}
		inner[0] = aid
		al[eid2] = inner
	g2.affix_load = al
	# active cd
	var cd := {}
	for sid in g2.skill_ids:
		var s: Dictionary = g2.skill_by_id.get(str(sid), {})
		if not s.is_empty() and str(s.get("type", "")) == "active" and g2.learned.has(str(sid)):
			if rng.randf() < 0.6:
				cd[str(sid)] = rng.randf() * 600.0
	g2._active_cd = cd
	g2.auto_break = (seed_i % 5 == 0)
	g2.auto_buy = (seed_i % 4 == 0)

# 参照实现 (独立 全量 遍历, 与 旧 stone_next_target 选优 逻辑 逐句 一致)
func _ref_stone_next() -> Dictionary:
	var pe: Dictionary = {}
	for id in g.equip_ids:
		if g.owned_eq.has(id):
			continue
		var e: Dictionary = g.equip_by_id.get(id, {})
		if e.is_empty():
			continue
		var c: float = float(e.get("cost", INF))
		if pe.is_empty() or c < float(pe["cost"]) or (c == float(pe["cost"]) and str(id) < str(pe["id"])):
			pe = e
	var pi: Dictionary = {}
	for it in g.ITEMS:
		if g.owned.has(str(it["id"])):
			continue
		var c2: float = float(it["cost"])
		if pi.is_empty() or c2 < float(pi["cost"]) or (c2 == float(pi["cost"]) and str(it["id"]) < str(pi["id"])):
			pi = it
	if pe.is_empty() and pi.is_empty():
		return {}
	var pick: Dictionary = pe
	if pe.is_empty():
		pick = pi
	elif not pi.is_empty():
		var ce: float = float(pe["cost"])
		var ci: float = float(pi["cost"])
		if ci < ce or (ci == ce and str(pi["id"]) < str(pe["id"])):
			pick = pi
	return {"id": str(pick["id"]), "name": str(pick.get("name", "")), "cost": float(pick["cost"]), "shortfall": maxf(float(pick["cost"]) - g.stones, 0.0)}
