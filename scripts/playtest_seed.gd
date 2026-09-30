extends SceneTree
## 试玩播种：构造"金丹第2层 + 塔 140 层 + 词缀 3 件"的中期玩家档，写入 user://save.json。
## 用法: ~/bin/godot --headless --path . -s res://scripts/playtest_seed.gd

func _init() -> void:
	# 机器试玩修复: 种档前 必须 先删 user://save.json — 否则 g._ready() 的 load_game() 会读真实
	# 玩家存档 (ascended/dao/owned_eq/equipped 等 种档脚本 未覆写 字段 全部 泄漏, 曾致 一整轮
	# 900s 长试玩 全程 ascended=true + dao=8e21 数据 作废)。
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save.json"))
	var g = load("res://scripts/game_data.gd").new()
	root.add_child(g)
	g._ready()
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.affix_bag.clear()
	g.affix_load.clear()
	g.slot_upgrades.clear()
	g.seen_affixes.clear()
	g.realm_idx = 2       # 金丹
	g.layer = 2
	g.essence = 1.3 * g.breakthrough_cost()
	g.stones = 30000.0
	g.learned.clear()
	for id in ["sword_0_0", "sword_1_1", "sword_2_0", "sword_2_3",
			"spell_0_0", "spell_1_2", "mind_0_0", "mind_1_0",
			"mind_2_1", "body_0_1", "body_1_3", "divine_2_2"]:
		if g.skill_by_id.has(id):
			g.learned.append(id)
	g.tower_fixed_floor = 140
	g.tower_endless_floor = 56
	g.tower_endless_best = 55
	g.auto_cast = false
	g.auto_learn = false
	g.auto_break = false
	g.auto_buy = false
	g.auto_tower = false
	g.affix_add("af_qi_rate_1_1", 2)
	g.affix_add("af_atk_1_0", 1)
	g.buy_equipment("weapon_2_1")
	g.buy_equipment("robe_1_2")
	g.buy_equipment("amulet_3_0")
	g.buy_equipment("bead_2_1")
	g.try_buy_item("wooden_sword")
	g.try_buy_item("jade_talisman")
	g.stats = {"play_sec": 193560.0, "break_ok": 12.0, "break_fail": 5.0, "tower_win": 260.0, "tower_loss": 40.0}
	g.check_achievements()
	g.save_game()
	print("SEEDED realm=%d layer=%d essence=%.0f stones=%.0f owned_eq=%d learned=%d" % [g.realm_idx, g.layer, g.essence, g.stones, g.owned_eq.size(), g.learned.size()])
	g.queue_free()
	quit(0)
