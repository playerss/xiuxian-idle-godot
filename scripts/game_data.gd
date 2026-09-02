extends Node
## 全局游戏数据：挂机核心逻辑 + 存档 (autoload: GameData)

const SAVE_PATH := "user://save.json"
const OFFLINE_CAP_SEC := 8 * 3600.0   # 离线收益上限 8 小时
const OFFLINE_RATE := 0.5             # 离线效率 50%
const SAVE_INTERVAL_SEC := 15.0

# 境界表: 每个境界有若干层, 逐层突破
const REALMS := [
	{"name": "练气", "layers": 9},
	{"name": "筑基", "layers": 3},
	{"name": "金丹", "layers": 3},
	{"name": "元婴", "layers": 3},
	{"name": "化神", "layers": 3},
	{"name": "炼虚", "layers": 3},
	{"name": "合体", "layers": 3},
	{"name": "大乘", "layers": 3},
	{"name": "渡劫", "layers": 1},
	{"name": "真仙", "layers": 1},
]
# 各境界的灵气速率倍率 (飞升后 x10 万, 仙凡两隔!)
const QI_MULT := [1.0, 4.0, 15.0, 40.0, 100.0, 250.0, 600.0, 1500.0, 4000.0, 100000.0]

# 法器 (用灵石购买, 永久提升灵气速率)
const ITEMS := [
	{"id": "wooden_sword", "name": "木剑", "desc": "修行人的伙伴", "cost": 100, "boost": 1.5},
	{"id": "jade_talisman", "name": "玉符", "desc": "静心护体", "cost": 1000, "boost": 2.0},
	{"id": "spirit_bag", "name": "聚灵袋", "desc": "引四方灵气", "cost": 8000, "boost": 3.0},
	{"id": "star_lamp", "name": "引星灯", "desc": "借星力修行", "cost": 60000, "boost": 5.0},
	{"id": "immortal_flute", "name": "仙音笛", "desc": "一缕仙音, 道心通明", "cost": 500000, "boost": 10.0},
]

# ---- 玩家状态 ----
var realm_idx := 0          # 当前境界索引
var layer := 1              # 当前层数 (1-based)
var essence := 0.0          # 灵气 (突破资源)
var stones := 0.0           # 灵石 (购买资源)
var owned: Array[String] = []  # 已拥有法器 id
var ascended := false       # 是否已飞升
var offline_msg := ""       # 离线收益提示

var _save_acc := 0.0

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	# 挂机自动积累
	if not ascended:
		essence += qi_per_sec() * delta
		stones += stone_per_sec() * delta
	# 定期存档
	_save_acc += delta
	if _save_acc >= SAVE_INTERVAL_SEC:
		_save_acc = 0.0
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		save_game()

# ---- 数值计算 ----

func item_boost() -> float:
	var m := 1.0
	for it in ITEMS:
		if owned.has(it["id"] as String):
			m *= it["boost"] as float
	return m

func qi_per_sec() -> float:
	return QI_MULT[realm_idx] * item_boost()

func stone_per_sec() -> float:
	return 1.0 * QI_MULT[realm_idx]

func breakthrough_cost() -> float:
	# 突破到下一层所需灵气
	return 10.0 * pow(3.0, realm_idx) * layer

func breakthrough_chance() -> float:
	return maxf(0.55, 1.0 - 0.04 * realm_idx)

# ---- 玩家操作 ----

func try_breakthrough() -> String:
	if ascended:
		return "你已在仙界, 道无止境 ♪"
	var cost := breakthrough_cost()
	if essence < cost:
		return "灵气不足: 需要 %s" % fmt(cost)
	essence -= cost
	if randf() < breakthrough_chance():
		_advance()
		if ascended:
			return "轰——天雷散尽, 你飞升真仙界了! 灵气速率 x100000!"
		return "突破成功! 当前境界: %s %s" % [realm_name(), layer_name()]
	else:
		return "突破失败… 灵气消耗殆尽, 但境界稳固, 卷土重来!"

func _advance() -> void:
	var max_layer := REALMS[realm_idx]["layers"] as int
	if layer < max_layer:
		layer += 1
	elif realm_idx < REALMS.size() - 1:
		realm_idx += 1
		layer = 1
	else:
		ascended = true

func try_buy_item(item_id: String) -> String:
	if owned.has(item_id):
		return "已经拥有了哦"
	for it in ITEMS:
		if it["id"] == item_id:
			if stones >= it["cost"]:
				stones -= it["cost"]
				owned.append(item_id)
				return "购得「%s」, 灵气速率 x%.1f!" % [it["name"], it["boost"]]
			else:
				return "灵石不足: 需要 %s" % fmt(it["cost"])
	return "未找到该法器"

# ---- 存档 ----

func save_game() -> void:
	var data := {
		"realm_idx": realm_idx,
		"layer": layer,
		"essence": essence,
		"stones": stones,
		"owned": owned,
		"ascended": ascended,
		"ts": int(Time.get_unix_time_from_system()),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
		f.close()

func load_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	realm_idx = clampi(int(parsed.get("realm_idx", 0)), 0, REALMS.size() - 1)
	layer = clampi(int(parsed.get("layer", 1)), 1, REALMS[realm_idx]["layers"] as int)
	essence = float(parsed.get("essence", 0.0))
	stones = float(parsed.get("stones", 0.0))
	ascended = bool(parsed.get("ascended", false))
	var ow = parsed.get("owned", [])
	owned.clear()
	if typeof(ow) == TYPE_ARRAY:
		for v in ow:
			if typeof(v) == TYPE_STRING:
				owned.append(v)
	# 离线收益
	var ts := int(parsed.get("ts", 0))
	if ts > 0:
		var elapsed := clampf(Time.get_unix_time_from_system() - float(ts), 0.0, OFFLINE_CAP_SEC)
		if elapsed > 60.0 and not ascended:
			var ge := qi_per_sec() * elapsed * OFFLINE_RATE
			var gs := stone_per_sec() * elapsed * OFFLINE_RATE
			essence += ge
			stones += gs
			offline_msg = "离线 %s, 效率50%%, 收获灵气 %s, 灵石 %s" % [
				fmt_time(elapsed), fmt(ge), fmt(gs)]

# ---- 展示用 ----

func realm_name() -> String:
	return REALMS[realm_idx]["name"] as String

func layer_name() -> String:
	if ascended:
		return "已飞升"
	return "第 %d 层" % layer

func breakthrough_progress() -> float:
	if ascended:
		return 100.0
	return clampf(essence / breakthrough_cost() * 100.0, 0.0, 100.0)

func fmt(v: float) -> String:
	if v >= 100000000.0:
		return "%.1f亿" % (v / 100000000.0)
	if v >= 10000.0:
		return "%.1f万" % (v / 10000.0)
	return str(int(v))

func fmt_time(sec: float) -> String:
	var h := int(sec) / 3600
	var m := int(sec) % 3600 / 60
	if h > 0:
		return "%d小时%d分" % [h, m]
	return "%d分" % maxi(m, 1)
