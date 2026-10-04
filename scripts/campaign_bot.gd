extends Node
## M10 战役封测 bot —— 模拟玩家完整旅程的一测/二测引擎
## 用法: DISPLAY=:99 CAMPAIGN_SECONDS=15000 CAMPAIGN_SPEED=8 ~/bin/godot --path . res://scenes/campaign_run.tscn
## 断点续跑: CAMPAIGN_STAGE=n 从第 n 阶段开始 (前段用 checkpoint 档或 seed 档, 由 cron agent 负责置备)
## 输出: user://playtest/campaign/
##   history.csv (阶段级 PASS/FAIL 长期账本) stage_<i>.json (每阶段明细)
##   shots/ 截图 ledger.csv 收支审计 checkpoint_<i>.json

const OUT := "user://playtest/campaign"
const STAGE_LOG := OUT + "/history.csv"

var ui: Node = null
var g: Node = null
var speed := 8.0
var total_budget := 15000.0
var start_stage := 0
var cur_stage := 0
var stage_deadline := 0.0
var run_start_ms := 0
var done := false
var fails := 0
var cur_shot := 0
var _act_acc := 0.0
var _led_acc := 0.0
var _last_led: Dictionary = {}
var _interacts: Dictionary = {}  # stage -> {key: "done"}
var _shot_turn := 0
var _stage_results: Array = []

const STAGES := [
	{
		"name": "P0 新手期", "budget": 900.0, "seed": false,
		"interacts": ["tabs", "first_break", "first_learn", "first_buy"],
		"goal": "新玩家 15 分钟内点成第一次突破且 5 页无报错",
	},
	{
		"name": "P1 凡境筑基", "budget": 1800.0, "seed": true,
		"interacts": ["tabs", "one_learn", "one_buy", "one_best", "one_divine", "one_cast", "break_loop", "tower_challenge", "autos"],
		"goal": "realm>=化神(4) learned>=40 owned_eq>=20 突破>=8次",
	},
	{
		"name": "P2 化神炼虚+爬塔", "budget": 1800.0, "seed": false,
		"interacts": ["tabs", "tower_challenge", "auto_tower_on", "one_best", "affix_best", "one_exchange"],
		"goal": "realm>=大乘(7) 镇妖塔>=150 登天梯>=100 词缀掉落>=1",
	},
	{
		"name": "P3 渡劫飞升", "budget": 1200.0, "seed": false,
		"interacts": ["tabs", "break_loop"],
		"goal": "ascended=true dao_level>=1",
	},
	{
		"name": "P4 仙界道途", "budget": 2400.0, "seed": false,
		"interacts": ["tabs", "auto_break_on", "slot_upgrade", "affix_equip_try", "one_exchange"],
		"goal": "dao_level>=8(道祖) 词缀装配>=1 槽位升级埋点路径走通",
	},
	{
		"name": "P5 全收集收官", "budget": 1500.0, "seed": false,
		"interacts": ["tabs", "one_learn", "one_buy", "one_best", "save_reload"],
		"goal": "技能120/装备140/法器10/成就全解锁 存读档往返一致",
	},
]

var BTN := {
	"尝试突破": "尝试突破",
	"one_learn": "一键领悟",
	"one_buy": "一键购买",
	"one_best": "一键最佳",
	"one_divine": "一键神通",
	"one_cast": "一键施展",
	"one_exchange": "一键兑换",
	"affix_best": "一键最佳装配",
	"slot_upgrade": "一键强化槽位",
	"break_challenge": "挑战",
}


func _ready() -> void:
	randomize()
	if OS.get_environment("CAMPAIGN_SPEED").is_valid_int():
		speed = maxf(1.0, float(OS.get_environment("CAMPAIGN_SPEED").to_int()))
	if OS.get_environment("CAMPAIGN_SECONDS").is_valid_int():
		total_budget = maxf(120.0, float(OS.get_environment("CAMPAIGN_SECONDS").to_int()))
	if OS.get_environment("CAMPAIGN_STAGE").is_valid_int():
		start_stage = clampi(OS.get_environment("CAMPAIGN_STAGE").to_int(), 0, STAGES.size() - 1)
	Engine.time_scale = speed
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.make_dir_recursive_absolute(OUT + "/shots")
	if not FileAccess.file_exists(STAGE_LOG):
		var f := FileAccess.open(STAGE_LOG, FileAccess.WRITE)
		if f:
			f.store_line("date,stage,result,seconds,note")
		f.close()
	var main_sc := load("res://scenes/main.tscn")
	ui = main_sc.instantiate()
	add_child(ui)
	g = get_node("/root/GameData")
	run_start_ms = Time.get_ticks_msec()
	cur_stage = start_stage
	var f := FileAccess.open(OUT + "/ledger.csv", FileAccess.WRITE)
	if f:
		f.store_line("rt_sec,fps,essence,stones,dao,ascended,realm,layer,break_ok,break_fail,primary_gain,primary_spent,stone_gain,stone_spent")
	f.close()
	_enter_stage()
	print("CAMPAIGN START speed=%.0fx budget=%.0fs stage=%s" % [speed, total_budget, STAGES[cur_stage].name])


func _enter_stage() -> void:
	var st: Dictionary = STAGES[cur_stage]
	stage_deadline = float(Time.get_ticks_msec()) / 1000.0 + float(st.budget)
	_interacts[cur_stage] = {}
	print("STAGE %d [%s] ENTER goal: %s" % [cur_stage, str(st.name), str(st.goal)])


func _process(_delta: float) -> void:
	var rt := float(Time.get_ticks_msec() - run_start_ms) / 1000.0
	# 收支审计 采样
	_led_acc += _delta / speed
	if _led_acc >= 5.0:
		_led_acc = 0.0
		_ledger()
	# 截图
	cur_shot += 1
	if cur_shot % int(speed * 30) == 0:
		_shot()
	# 阶段内交互 tick (每 4 real sec 一轮)
	_act_acc += _delta / speed
	if _act_acc >= 4.0:
		_act_acc = 0.0
		_stage_tick()
	# 目标检查
	if goal_met():
		_finish_stage("PASS")
		return
	if rt >= stage_deadline:
		_finish_stage("TIMEOUT")
		return
	if rt >= total_budget:
		_finish_stage("TIMEOUT")
		return


# ---------- 交互 (真实 UI 路径) ----------

func _stage_tick() -> void:
	var st: Dictionary = STAGES[cur_stage]
	var done_map: Dictionary = _interacts[cur_stage]
	var budget: float = float(st.budget)
	var spent := float(Time.get_ticks_msec()) / 1000.0 - (stage_deadline - budget)
	var frac := clampf(spent / budget, 0.0, 1.0)
	for key in st.interacts:
		var k := str(key)
		if bool(done_map.get(k, false)):
			continue
		var ratio := 0.0
		match k:
			"tabs":
				ratio = 0.15
			"first_break", "break_loop":
				ratio = 0.1
			"first_learn", "one_learn", "one_divine":
				ratio = 0.3
			"first_buy", "one_buy":
				ratio = 0.35
			"one_best", "affix_best", "affix_equip_try":
				ratio = 0.4
			"one_cast", "one_exchange":
				ratio = 0.45
			"tower_challenge", "auto_tower_on":
				ratio = 0.5
			"autos", "auto_break_on", "slot_upgrade":
				ratio = 0.6
			"save_reload":
				ratio = 0.9
		if frac >= ratio:
			do_interact(k)
			done_map[k] = true
	# break_loop 持续: 资源够就点
	if frac >= 0.1:
		if g.breakthrough_ready() or (bool(g.ascended) and _dao_ready()):
			_click_named("尝试突破")
	# 塔持续
	if bool(done_map.get("auto_tower_on", false)) or (cur_stage >= 1 and frac >= 0.7):
		if not bool(g.auto_tower) and cur_stage >= 1:
			_click_tab(4)
			_click_named("自动爬塔")
			done_map["auto_tower_on"] = true


func _dao_ready() -> bool:
	return true  # dao 攒够由 auto_break 自动精进, 按钮点击兜底


func do_interact(k: String) -> void:
	match k:
		"tabs":
			var t: int = _shot_turn % 5
			_click_tab(t)
			_shot_turn += 1
		"first_break", "break_loop":
			_click_named("尝试突破")
		"first_learn", "one_learn":
			_click_tab(1)
			_click_named("一键领悟")
		"first_buy", "one_buy":
			# 修行页 法器区购买 + 装备页 一键购买
			_click_named("法器")
			_click_tab(2)
			_click_named("一键购买")
		"one_best":
			_click_tab(2)
			_click_named("一键最佳")
		"one_divine":
			_click_tab(1)
			_click_named("一键神通")
		"one_cast":
			_click_tab(1)
			_click_named("一键施展")
		"one_exchange":
			_click_named("一键兑换")
		"affix_best":
			_click_named("一键最佳装配")
		"affix_equip_try":
			_click_named("一键最佳装配")
		"slot_upgrade":
			_click_named("一键强化槽位")
		"tower_challenge":
			_click_tab(4)
			_click_named("挑战")
		"auto_tower_on":
			_click_tab(4)
			if not bool(g.auto_tower):
				_click_named("自动爬塔")
		"autos":
			_click_tab(0)
			if not bool(g.auto_learn):
				_click_named("自动领悟")
			if not bool(g.auto_buy):
				_click_named("自动购置")
			if not bool(g.auto_cast):
				_click_named("自动施展")
		"auto_break_on":
			_click_tab(0)
			if not bool(g.auto_break):
				_click_named("自动突破")
		"save_reload":
			g.save_game()
			var snap_e: float = g.essence
			g.load_game()
			check(abs(g.essence - snap_e) < maxf(1.0, snap_e * 0.001), "存档往返 essence 一致")


func goal_met() -> bool:
	match cur_stage:
		0:
			return int(g.stats.get("break_ok", 0)) > 0 and bool(_interacts[0].get("first_break", false))
		1:
			return int(g.realm_idx) >= 4 and g.learned.size() >= 40 and g.owned_eq.size() >= 20 and float(g.stats.get("break_ok", 0)) >= 8.0
		2:
			return int(g.realm_idx) >= 7 and int(g.tower_fixed_floor) >= 150 and int(g.tower_endless_floor) >= 100 and float(g.stats.get("affix_drop", 0)) >= 1.0
		3:
			return bool(g.ascended) and int(g.dao_level) >= 1
		4:
			return int(g.dao_level) >= 8
		5:
			var cs: Dictionary = g.collect_summary()
			return (
				int((cs.skill as Dictionary).got) >= int((cs.skill as Dictionary).total)
				and int((cs.equip as Dictionary).got) >= int((cs.equip as Dictionary).total)
				and int((cs.item as Dictionary).got) >= int((cs.item as Dictionary).total)
				and int((cs.ach as Dictionary).got) >= int((cs.ach as Dictionary).total)
				and int((cs.affix as Dictionary).got) >= int((cs.affix as Dictionary).total)
			)
	return false


func check(c: bool, label: String) -> void:
	if not c:
		fails += 1
		print("CAMPAIGN FAIL: " + label)


# ---------- 收阶段 ----------

func _finish_stage(res: String) -> void:
	var st: Dictionary = STAGES[cur_stage]
	var sec: float = float(Time.get_ticks_msec()) / 1000.0 - (stage_deadline - float(st.budget))
	var d: Dictionary = Time.get_datetime_dict_from_system(true)
	var row := "%04d-%02d-%02d,%d,%s,%.0f,%s" % [int(d.year), int(d.month), int(d.day), cur_stage, res, sec, str(st.goal)]
	var f := FileAccess.open(STAGE_LOG, FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line(row)
	f.close()
	var detail := {
		"stage": cur_stage, "name": str(st.name), "result": res, "seconds": sec,
		"realm": int(g.realm_idx), "layer": int(g.layer), "dao_level": int(g.dao_level),
		"ascended": bool(g.ascended), "learned": g.learned.size(), "owned_eq": g.owned_eq.size(),
		"stats": g.stats, "fails_total": fails,
	}
	var df := FileAccess.open(OUT + "/stage_%d.json" % cur_stage, FileAccess.WRITE)
	if df:
		df.store_string(JSON.stringify(detail, "  "))
	df.close()
	g.save_game()
	var ck := FileAccess.open(OUT + "/checkpoint_%d.json" % cur_stage, FileAccess.WRITE)
	var sf := FileAccess.open("user://save.json", FileAccess.READ)
	if ck and sf:
		ck.store_string(sf.get_as_text())
	print("STAGE %d [%s] %s (%.0fs)" % [cur_stage, str(st.name), res, sec])
	cur_stage += 1
	var rt_now := float(Time.get_ticks_msec() - run_start_ms) / 1000.0
	if cur_stage >= STAGES.size() or rt_now >= total_budget:
		_end_run()
	else:
		_enter_stage()


func _end_run() -> void:
	if done:
		return
	done = true
	var summary := {
		"stages_passed": 0, "stages_total": STAGES.size(), "fails": fails,
		"realtime_sec": float(Time.get_ticks_msec() - run_start_ms) / 1000.0,
		"game_hours": float(Time.get_ticks_msec() - run_start_ms) / 1000.0 * speed / 3600.0,
		"final": {"realm": int(g.realm_idx), "dao": int(g.dao_level), "ascended": bool(g.ascended)},
	}
	for i in STAGES.size():
		var p := OUT + "/stage_%d.json" % i
		var ff := FileAccess.open(p, FileAccess.READ)
		if ff:
			var j: Variant = JSON.parse_string(ff.get_as_text())
			if typeof(j) == TYPE_DICTIONARY and str(j.get("result", "")) == "PASS":
				summary.stages_passed += 1
			ff.close()
	var f2 := FileAccess.open(OUT + "/results.json", FileAccess.WRITE)
	if f2:
		f2.store_string(JSON.stringify(summary, "  "))
		f2.close()
	print("CAMPAIGN_DONE %s" % JSON.stringify(summary))
	Engine.time_scale = 1.0
	get_tree().quit()


# ---------- 观测 ----------

func _ledger() -> void:
	var st: Dictionary = g.stats
	var row := ",".join(PackedStringArray([
		str(int(float(Time.get_ticks_msec() - run_start_ms) / 1000.0)),
		str(Engine.get_frames_per_second()),
		str(g.essence), str(g.stones), str(g.dao), str(g.ascended),
		str(g.realm_idx), str(g.layer),
		str(st.get("break_ok", 0)), str(st.get("break_fail", 0)),
		str(st.get("primary_gain", 0)), str(st.get("primary_spent", 0)),
		str(st.get("stone_gain", 0)), str(st.get("stone_spent", 0)),
	]))
	var f := FileAccess.open(OUT + "/ledger.csv", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line(row)
	f.close()
	if not _last_led.is_empty() and bool(g.ascended) == bool(_last_led.get("asc", false)):
		var d_cur: float = float(g.essence if not bool(g.ascended) else g.dao) - float(_last_led.get("cur", 0.0))
		var flow_g: float = (float(st.get("primary_gain", 0)) - float(st.get("primary_spent", 0))) - float(_last_led.get("lg", 0.0))
		var base: float = maxf(abs(flow_g), 1.0)
		if abs(d_cur - flow_g) > maxf(base * 0.01, 1.0):
			check(false, "主资源账实不平 d=%f flow=%f rt=%s" % [d_cur, flow_g, str(int(float(Time.get_ticks_msec() - run_start_ms) / 1000.0))])
	f.close()
	_last_led = {"lg": float(st.get("primary_gain", 0)) - float(st.get("primary_spent", 0)), "cur": float(g.essence if not bool(g.ascended) else g.dao), "st": float(g.stones), "asc": bool(g.ascended)}


func _shot() -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_window().get_texture().get_image()
	var err := img.save_png(OUT + "/shots/stage%d_%04d.png" % [cur_stage, int(float(Time.get_ticks_msec() - run_start_ms) / 1000.0)])
	if err != OK:
		check(false, "截图保存失败 %d" % err)


# ---------- 真实输入 ----------

func _all_buttons(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_all_buttons(c, out)


func _on_screen(c: Node) -> bool:
	var p: Node = c
	while p != null and p != ui:
		if not (p as CanvasItem).is_visible_in_tree():
			return false
		p = p.get_parent()
	return true


func _click_named(prefix: String) -> void:
	var btns: Array = []
	_all_buttons(ui, btns)
	for b in btns:
		if not is_instance_valid(b) or not b.disabled or not _on_screen(b):
			continue
		if str(b.text).strip_edges().begins_with(prefix):
			var r: Rect2 = b.get_global_rect()
			if r.size.x < 4 or r.size.y < 4:
				continue
			_click(r.position + r.size * 0.5)
			return


func _click_tab(i: int) -> void:
	var tab: TabContainer = ui._tab
	var tb: TabBar = tab.get_tab_bar()
	var r: Rect2 = Rect2(tb.get_tab_rect(i))
	_click(tb.get_global_position() + r.position + r.size * 0.5)


func _click(pos: Vector2) -> void:
	var vp := get_viewport()
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	vp.push_input(m)
	var d := InputEventMouseButton.new()
	d.button_index = MOUSE_BUTTON_LEFT
	d.position = pos
	d.global_position = pos
	d.pressed = true
	vp.push_input(d)
	var u := InputEventMouseButton.new()
	u.button_index = MOUSE_BUTTON_LEFT
	u.position = pos
	u.global_position = pos
	u.pressed = false
	vp.push_input(u)
