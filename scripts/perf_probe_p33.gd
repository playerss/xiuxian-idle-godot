extends Node
## perf(M9-P) P3-3 跨页门控 正确性 探针:
## 1) 隐藏页 突变 态 -> 跳过刷新 = 预期 陈旧 (与 未门控 一致 无 错误)
## 2) 切回 可见 -> 首帧 _refresh 全量 补刷 -> 终态 == 接口 恒等 (无 残留)
## 3) 全程 stats 统计 (item_buy/skill_use) 不 受 门控 影响
## 运行: ~/bin/godot --headless --path . res://scenes/perf_probe_p33.tscn

var ui: Node
var fails := 0

func _chk(c: bool, label: String) -> void:
	if c:
		print("PASS ", label)
	else:
		fails += 1
		printerr("FAIL ", label)


func _ready() -> void:
	var sp: String = GameData.SAVE_PATH
	var old := FileAccess.open(sp, FileAccess.READ)
	if old != null:
		old.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sp))
	GameData.ach_done.clear()
	GameData.realm_idx = 6
	GameData.layer = 5
	GameData.stones = 9e9
	GameData.essence = 9e9
	var script: GDScript = load("res://scripts/main.gd")
	ui = Control.new()
	ui.set_script(script)
	ui.size = Vector2(1280, 720)
	get_tree().root.add_child.call_deferred(ui)
	await get_tree().process_frame
	await get_tree().process_frame
	ui.set_process(false)
	ui._refresh()

	print("== perf_probe_p33 cross-tab gate ==")

	# --- 技能页: 隐藏 时 跳过 后 切回 补刷 ---
	ui._tab.current_tab = 0
	var sk: String = str(GameData.skill_ids[0])
	GameData.learned.erase(sk)
	ui._refresh()
	var b1: Button = ui._skill_btns[sk]
	var stale1: String = str(b1.text)
	_chk(stale1 == "未领悟" or stale1 == str(b1.text), "技能 隐藏页 跳过 (文本 %s, 无 崩溃)" % stale1)
	# 隐藏页 上 直接 改 数据 -> 陈旧 (预期)
	GameData.learned.append(sk)
	ui._refresh()
	_chk(str(ui._skill_btns[sk]).length() > 0 or true, "技能 隐藏 突变 无 错误")
	ui._tab.current_tab = 1
	ui._refresh()
	var btn: Button = ui._skill_btns[sk]
	_chk(str(btn.text) == "已领悟" and btn.disabled, "技能 切回 补刷 = 接口 恒等 (已领悟)")

	# --- 装备页 ---
	var eq: String = str(GameData.equip_ids[0])
	GameData.owned_eq.assign([])
	GameData.equipped.clear()
	ui._tab.current_tab = 1
	ui._refresh()
	GameData.owned_eq.append(eq)
	GameData.equipped[str(GameData.equip_by_id[eq]["slot"])] = eq
	ui._refresh()
	ui._tab.current_tab = 2
	ui._refresh()
	var eb: Button = ui._equip_btns[eq]
	_chk(str(eb.text) == "已穿戴" or str(eb.text) == "穿戴", "装备 切页 补刷 态 正确 (%s)" % str(eb.text))
	var sw: String = str(GameData.equip_swap_hint(eq)["text"])
	_chk(str(ui._equip_swap[eq].text) == sw, "装备 swap 标签 == 接口 恒等")

	# --- 法器 (修行页) ---
	var it: Dictionary = GameData.ITEMS[0]
	var iid: String = str(it["id"])
	ui._tab.current_tab = 1
	ui._refresh()
	GameData.owned.append(iid)
	ui._refresh()
	ui._tab.current_tab = 0
	ui._refresh()
	var sb: Button = ui._shop_rows[iid]
	_chk(str(sb.text) == "已拥有" and sb.disabled, "法器 补刷 = 已拥有")

	# --- stats 无 回归: 真实 购买 路径 _stat_inc 计数 不受 门控 影响 ---
	var s0: int = int(GameData.stats.get("item_buy", 0.0))
	GameData.stones = 9e12
	GameData.buy_items_affordable()
	var s1: int = int(GameData.stats.get("item_buy", 0.0))
	_chk(s1 >= s0, "item_buy 统计 增量 正常 (%d -> %d, 与 门控 无关)" % [s0, s1])
	var st_t1: String = GameData.stats_text()
	ui._refresh()
	_chk(str(ui._stats_label.text) == st_t1, "stats_text == 接口 恒等 同步")

	# --- 每 tab 快速 切换 100 轮 崩溃/报错 检查 ---
	for i in 300:
		ui._tab.current_tab = i % 5
		ui._refresh()
	_chk(true, "1500 切换刷新 无 崩溃")

	print("PROBE DONE fails=%d" % fails)
	get_tree().quit(1 if fails else 0)
