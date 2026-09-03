extends Node
## 全局游戏数据：挂机核心 + 技能/装备 + 存档 (autoload: GameData)

const SAVE_PATH := "user://save.json"
const SKILLS_JSON := "res://data/skills.json"
const EQUIP_JSON := "res://data/equipment.json"
const ACH_JSON := "res://data/achievements.json"
const OFFLINE_CAP_SEC := 8 * 3600.0   # 离线收益上限 8 小时
const OFFLINE_BASE_RATE := 0.5       # 基础离线效率 50%
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

# 打磨-10: 飞升后道行 — 真仙境 9 阶段, 每阶灵气速率 x2, 道行精进 (突破) 消耗道行
const IMMORTAL_REALMS := ["初仙", "少仙", "上仙", "天仙", "金仙", "太乙", "大罗", "混元", "道祖"]
const IMMORTAL_STAGE_MULT := 2.0   # 道行每阶灵气倍率
const DAO_BREAK_BASE := 1.0e9      # 道行精进基础消耗 (初仙→少仙)
const DAO_BREAK_GROWTH := 8.0      # 每阶消耗倍率 (长线挂机目标)

# 法器 (用灵石购买, 永久提升灵气速率)
# 打磨-4: 性价比曲线调平 + 补全真仙境 (渡劫/真仙), 每件在当前境界约 1~8 分钟灵石可购
const ITEMS := [
	{"id": "wooden_sword", "name": "木剑", "desc": "修行人的伙伴", "cost": 100, "boost": 1.5},
	{"id": "jade_talisman", "name": "玉符", "desc": "静心护体", "cost": 1000, "boost": 2.0},
	{"id": "spirit_bag", "name": "聚灵袋", "desc": "引四方灵气", "cost": 6000, "boost": 3.0},
	{"id": "star_lamp", "name": "引星灯", "desc": "借星力修行", "cost": 45000, "boost": 5.0},
	{"id": "immortal_flute", "name": "仙音笛", "desc": "一缕仙音, 道心通明", "cost": 250000, "boost": 8.0},
	{"id": "star_dock", "name": "星槎", "desc": "乘槎问星, 直上天河", "cost": 1500000, "boost": 12.0},
	{"id": "void_mirror", "name": "太虚镜", "desc": "照见太虚, 返璞归真", "cost": 5000000, "boost": 18.0},
	{"id": "primordial_lamp", "name": "太初道灯", "desc": "一盏长明, 照破鸿蒙", "cost": 20000000, "boost": 25.0},
	{"id": "chaos_bell", "name": "鸿蒙道钟", "desc": "一钟一世界, 道在钟鸣", "cost": 80000000, "boost": 40.0},
	{"id": "ascension_seal", "name": "渡劫引仙印", "desc": "仙缘已至, 只待飞升", "cost": 300000000, "boost": 60.0},
]

# 装备部位
const SLOTS := ["weapon", "robe", "amulet", "bead", "boot"]
const SLOT_CN := {"weapon": "武器", "robe": "法袍", "amulet": "玉佩", "bead": "灵珠", "boot": "云靴"}
# 技能类别
const SKILL_CAT_CN := {"sword": "剑法", "spell": "法术", "mind": "心法", "body": "身法", "divine": "神通"}
# 品质颜色
const TIER_COLOR := {
	0: Color(0.6, 0.62, 0.68),    # 凡品 灰
	1: Color(0.55, 0.85, 0.55),   # 灵品 绿
	2: Color(0.5, 0.7, 0.98),     # 玄品 蓝
	3: Color(0.98, 0.85, 0.4),    # 地品 黄
	4: Color(0.98, 0.6, 0.35),    # 天品 橙
	5: Color(0.8, 0.55, 0.98),    # 仙品 紫
	6: Color(0.98, 0.86, 0.5),    # 神品 金
}

# ---- 数据表 (加载自 JSON) ----
var skill_by_id := {}
var equip_by_id := {}
var ach_by_id := {}
var skill_ids: Array = []
var equip_ids: Array = []
var ach_ids: Array = []

# ---- 玩家状态 ----
var realm_idx := 0          # 当前境界索引
var layer := 1              # 当前层数 (1-based)
var essence := 0.0          # 灵气 (突破资源)
var stones := 0.0           # 灵石 (购买资源)
var owned: Array[String] = []      # 已拥有法器 id
var learned: Array[String] = []    # 已学习技能 id
var owned_eq: Array[String] = []   # 已拥有装备 id
var equipped: Dictionary = {}      # 部位 slot -> 装备 id
var ascended := false       # 是否已飞升
var dao := 0.0              # 道行 (飞升后挂机资源, 打磨-10)
var dao_level := 0          # 道行阶段 0..8 (0=初仙, 8=道祖, 打磨-10)
var ach_done: Array[String] = []   # 已解锁成就 id (打磨-6)
var offline_msg := ""       # 离线收益提示
var last_break_result := 0  # 上次突破: 0=未触发 1=成功 2=失败 3=飞升
var break_seq := 0          # 突破事件序号 (每次成功/失败/飞升 +1, UI 据此触发闪烁)
var stats: Dictionary = {}  # 打磨-14: 修行统计 (累计时长/突破/道行/神通/法器/装备, 读档时 _load_stats 兜底)

var _active_cd := {}        # 技能 id -> 剩余冷却秒
var _save_acc := 0.0
var _ach_acc := 0.0         # 成就检测节流累计

func _ready() -> void:
	load_data()
	load_game()

func _process(delta: float) -> void:
	# 挂机自动积累 (飞升后: 道行替代灵气, 打磨-10)
	if ascended:
		dao += qi_per_sec() * delta
	else:
		essence += qi_per_sec() * delta
	stones += stone_per_sec() * delta
	_stat_inc("play_sec", delta)  # 打磨-14: 累计在线时长
	# 神通冷却
	for id in _active_cd.keys():
		_active_cd[id] = maxf(0.0, _active_cd[id] - delta)
		if _active_cd[id] <= 0.0:
			_active_cd.erase(id)
	# 成就检测 (节流 1 秒, 幂等; 灵石达标记类成就在挂机中也能触发)
	_ach_acc += delta
	if _ach_acc >= 1.0:
		_ach_acc = 0.0
		check_achievements()
	# 定期存档
	_save_acc += delta
	if _save_acc >= SAVE_INTERVAL_SEC:
		_save_acc = 0.0
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		save_game()

# ================= 数据加载 =================

func load_data() -> void:
	var s: Dictionary = _load_json(SKILLS_JSON)
	if s.has("skills"):
		for item in s["skills"]:
			skill_by_id[item["id"]] = item
			skill_ids.append(item["id"])
	var e: Dictionary = _load_json(EQUIP_JSON)
	if e.has("equipment"):
		for item in e["equipment"]:
			equip_by_id[item["id"]] = item
			equip_ids.append(item["id"])
	var a: Dictionary = _load_json(ACH_JSON)
	if a.has("achievements"):
		for item in a["achievements"]:
			ach_by_id[item["id"]] = item
			ach_ids.append(item["id"])

func _load_json(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("无法打开数据文件: " + path)
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else null

# ================= 数值计算 =================

func item_boost() -> float:
	var m := 1.0
	for it in ITEMS:
		if owned.has(it["id"] as String):
			m *= it["boost"] as float
	return m

# 已学被动技能的加成汇总 (effect -> 总比例)
func passive_bonus(eff: String) -> float:
	var total := 0.0
	for id in learned:
		var s: Dictionary = skill_by_id.get(id, {})
		if s.is_empty() or str(s.get("type", "")) != "passive" or str(s.get("effect", "")) != eff:
			continue
		total += float(s.get("value", 0.0))
	return total

# 已穿戴装备的加成汇总
func equip_bonus(eff: String) -> float:
	var total := 0.0
	for slot in SLOTS:
		var id: String = equipped.get(slot, "")
		if id == "":
			continue
		var e: Dictionary = equip_by_id.get(id, {})
		if not e.is_empty():
			total += float(e.get(eff, 0.0))
	return total

# 打磨-10: 道行阶段倍率 (飞升后每阶 x2)
func immortal_mult() -> float:
	return pow(IMMORTAL_STAGE_MULT, dao_level) if ascended else 1.0

func qi_per_sec() -> float:
	return QI_MULT[realm_idx] * immortal_mult() * item_boost() * (1.0 + passive_bonus("qi_mult") + passive_bonus("all_mult") + equip_bonus("qi_mult"))

func stone_per_sec() -> float:
	return 1.0 * QI_MULT[realm_idx] * (1.0 + passive_bonus("stone_mult") + passive_bonus("all_mult") + equip_bonus("stone_mult"))

# 灵气倍率构成 (顶栏展示用: 境界基础 / 功法与装备加成)
func qi_mult_realm() -> float:
	return QI_MULT[realm_idx] * immortal_mult()

func qi_mult_skill_equip() -> float:
	return 1.0 + passive_bonus("qi_mult") + passive_bonus("all_mult") + equip_bonus("qi_mult")

func breakthrough_cost() -> float:
	return 10.0 * pow(3.0, realm_idx) * layer

func breakthrough_chance() -> float:
	return clampf(0.85 - 0.04 * realm_idx + passive_bonus("bt_chance") + equip_bonus("bt_chance"), 0.05, 0.99)

func offline_rate() -> float:
	return clampf(OFFLINE_BASE_RATE * (1.0 + passive_bonus("offline_rate") + equip_bonus("offline_rate")), 0.0, 1.0)

# ---------- 打磨-13: 离线/挂机收益可视化 ----------

# 指定秒数的离线收益 (基础效率 50% + 功法/装备, 上限 8 小时; 飞升后 qi 计为道行)
func offline_gain(sec: float) -> Dictionary:
	var s := minf(maxf(sec, 0.0), OFFLINE_CAP_SEC)
	var r: float = offline_rate()
	return {
		"sec": s,
		"rate": r,
		"qi": qi_per_sec() * s * r,
		"stone": stone_per_sec() * s * r,
		"capped": sec > OFFLINE_CAP_SEC,
	}

# 每小时离线收益 (修行页展示)
func offline_hourly() -> Dictionary:
	return offline_gain(3600.0)

# 离线每小时文本 (修行页; 飞升后主资源为道行)
func offline_hourly_text() -> String:
	var h := offline_hourly()
	return "离线每小时  %s %s · 灵石 %s (效率%0.0f%%, 上限8小时)" % [
		"道行" if ascended else "灵气", fmt(float(h["qi"])), fmt(float(h["stone"])), float(h["rate"]) * 100.0]

# ================= 打磨-14: 修行统计 (累计时长/突破/道行/神通/法器/装备) =================

func _stat_inc(key: String, amount: float = 1.0) -> void:
	stats[key] = float(stats.get(key, 0.0)) + amount

func _load_stats(v: Variant) -> void:
	stats = {}
	if typeof(v) == TYPE_DICTIONARY:
		for k in v:
			stats[str(k)] = float(v[k])
	# 兜底键齐全 (旧档缺失不影响读取)
	for k in ["play_sec", "break_ok", "break_fail", "dao_ok", "skill_use", "item_buy", "equip_buy"]:
		if not stats.has(k):
			stats[k] = 0.0

# 统计文本 (修行页展示)
func stats_text() -> String:
	return "修行 %s · 突破 %d 次 · 道行精进 %d 次 · 神通 %d 次 · 法器 %d 件 · 装备 %d 件" % [
		fmt_stats_time(float(stats.get("play_sec", 0.0))),
		int(stats.get("break_ok", 0.0)), int(stats.get("dao_ok", 0.0)),
		int(stats.get("skill_use", 0.0)), int(stats.get("item_buy", 0.0)), int(stats.get("equip_buy", 0.0))]

# 统计时长格式 (日/小时/分)
func fmt_stats_time(sec: float) -> String:
	var d := int(sec) / 86400
	var h := int(sec) % 86400 / 3600
	var m := int(sec) % 3600 / 60
	if d > 0:
		return "%d天%d小时" % [d, h]
	if h > 0:
		return "%d小时%d分" % [h, m]
	if m > 0:
		return "%d分" % m
	return "不足1分"

# ================= 成就 (打磨-6: 数据驱动, Steam 上报) =================

# 境界里程碑成就 -> 目标 realm_idx (与 gen_data.py ACH_REALM_IDX 一致)
const ACH_REALM_IDX := {
	"realm_zhuji": 1, "realm_jindan": 2, "realm_yuanying": 3, "realm_huashen": 4,
	"realm_luexu": 5, "realm_het": 6, "realm_dacheng": 7, "realm_dujie": 8,
}

func _ach_met(id: String) -> bool:
	if ach_done.has(id):
		return false
	match id:
		"ascend_immortal":
			return ascended
		"first_break":
			return realm_idx > 0 or layer > 1
		"first_item":
			return owned.size() >= 1
		"skill_10":
			return learned.size() >= 10
		"skill_50":
			return learned.size() >= 50
		"equip_first":
			return owned_eq.size() >= 1
		"equip_10":
			return owned_eq.size() >= 10
		"rich_100k":
			return stones >= 100000.0
		"dao_zuzi":
			return ascended and dao_level >= IMMORTAL_REALMS.size() - 1
		_:
			var need: int = ACH_REALM_IDX.get(id, -1)
			return need >= 0 and realm_idx >= need

# 检查并解锁新成就 (幂等: 已解锁的不会重复上报)。返回本次新解锁的 id 列表
func check_achievements() -> Array[String]:
	var got: Array[String] = []
	for id in ach_ids:
		if _ach_met(id):
			ach_done.append(id)
			got.append(id)
			var steam = get_node_or_null("/root/Steam")
			if steam != null:
				steam.set_achieved(id)
	return got

# 成就面板展示 (打磨-7): 已解锁 -> "已解锁"; 未解锁 -> 当前进度/条件提示
func ach_progress(id: String) -> String:
	if ach_done.has(id):
		return "已解锁"
	match id:
		"ascend_immortal":
			return "渡劫后飞升 (当前 %s %s)" % [realm_name(), layer_name()]
		"first_break":
			return "1/1" if (realm_idx > 0 or layer > 1) else "0/1"
		"first_item":
			return "%d/1" % mini(owned.size(), 1)
		"skill_10":
			return "%d/10" % mini(learned.size(), 10)
		"skill_50":
			return "%d/50" % mini(learned.size(), 50)
		"equip_first":
			return "%d/1" % mini(owned_eq.size(), 1)
		"equip_10":
			return "%d/10" % mini(owned_eq.size(), 10)
		"rich_100k":
			return "%d/100000" % int(minf(stones, 100000.0))
		"dao_zuzi":
			if not ascended:
				return "飞升后, 道行精进至道祖境"
			return "道行精进中: 当前 %s / 目标 道祖" % IMMORTAL_REALMS[dao_level]
		_:
			var need: int = ACH_REALM_IDX.get(id, -1)
			if need >= 0:
				return "当前 %s / 目标 %s" % [realm_name(), REALMS[need]["name"]]
	return ""

# ================= 详情提示 (打磨-9: 行 tooltip) =================

# 技能详情 (tooltip: 名称/品质/类型/效果/领悟条件/状态)
func skill_detail(id: String) -> String:
	var s: Dictionary = skill_by_id.get(id, {})
	if s.is_empty():
		return ""
	var type_cn := "主动·神通" if str(s["type"]) == "active" else "被动·功法"
	var tip := "「%s」 %s · %s\n%s" % [s["name"], s["tier_name"], type_cn, s["desc"]]
	if str(s["type"]) == "active":
		tip += "\n(飞升后: 爆发转为获得道行)"
	var r: Dictionary = REALMS[int(s["unlock_realm"])]
	tip += "\n领悟条件: %s 第%d层" % [r["name"], int(s["unlock_layer"])]
	tip += "\n状态: %s" % ("已领悟" if learned.has(id) else "未领悟")
	return tip

# 装备详情 (tooltip: 名称/品质/部位/属性/价格/状态)
func equip_detail(id: String) -> String:
	var e: Dictionary = equip_by_id.get(id, {})
	if e.is_empty():
		return ""
	var tip := "「%s」 %s · %s\n%s\n灵石 %s" % [e["name"], e["tier_name"], e["slot_name"], e["desc"], fmt(float(e["cost"]))]
	if str(equipped.get(str(e["slot"]), "")) == id:
		tip += "\n状态: 已穿戴"
	elif owned_eq.has(id):
		tip += "\n状态: 已拥有(未穿戴)"
	else:
		tip += "\n状态: 未拥有"
	return tip

# 法器详情 (tooltip: 名称/描述/价格/增幅/状态)
func item_detail(item_id: String) -> String:
	for it in ITEMS:
		if str(it["id"]) == item_id:
			var tip := "「%s」\n%s\n灵石 %s\n灵气速率 x%.1f" % [it["name"], it["desc"], fmt(float(it["cost"])), float(it["boost"])]
			tip += "\n状态: %s" % ("已拥有" if owned.has(item_id) else "未拥有")
			return tip
	return ""

# ================= 加成汇总 (打磨-9: 面板顶部展示) =================

# 当前总加成 (乘数/概率/离线效率/法器)
func bonus_summary() -> Dictionary:
	return {
		"qi_mult": 1.0 + passive_bonus("qi_mult") + passive_bonus("all_mult") + equip_bonus("qi_mult"),
		"stone_mult": 1.0 + passive_bonus("stone_mult") + passive_bonus("all_mult") + equip_bonus("stone_mult"),
		"bt_chance": passive_bonus("bt_chance") + equip_bonus("bt_chance"),
		"offline_rate": offline_rate(),
		"item_boost": item_boost(),
	}

# 加成汇总文本 (技能/装备页顶栏)
func bonus_summary_text() -> String:
	var b := bonus_summary()
	return "当前总加成  灵气 x%.2f · 灵石 x%.2f · 突破 +%0.1f%% · 离线 %0.0f%% · 法器 x%.1f" % [
		float(b["qi_mult"]), float(b["stone_mult"]), float(b["bt_chance"]) * 100.0,
		float(b["offline_rate"]) * 100.0, float(b["item_boost"])]

# ================= 技能 =================

func can_learn(id: String) -> bool:
	var s: Dictionary = skill_by_id.get(id, {})
	if s.is_empty():
		return false
	return realm_idx > s["unlock_realm"] or (realm_idx == s["unlock_realm"] and layer >= s["unlock_layer"])

func learn_skill(id: String) -> String:
	if learned.has(id):
		return "已经学会了哦"
	var s: Dictionary = skill_by_id.get(id, {})
	if s.is_empty():
		return "未找到该技能"
	if not can_learn(id):
		return "境界不足: 需要 %s 才能领悟" % REALMS[s["unlock_realm"]]["name"]
	learned.append(id)
	return "领悟「%s」! %s" % [s["name"], s["desc"]]

func active_ready(id: String) -> bool:
	return _active_cd.get(id, 0.0) <= 0.0

func active_cd_left(id: String) -> int:
	return int(ceil(_active_cd.get(id, 0.0)))

func use_active_skill(id: String) -> String:
	var s: Dictionary = skill_by_id.get(id, {})
	if s.is_empty() or s.get("type", "") != "active":
		return "这不是主动神通"
	if not learned.has(id):
		return "尚未领悟, 无法施展"
	if not active_ready(id):
		return "冷却中: 还需 %d 秒" % active_cd_left(id)
	var gain := float(qi_per_sec()) * float(s["value"])
	_active_cd[id] = float(s["cooldown"])
	_stat_inc("skill_use")  # 打磨-14: 神通施展计数
	# 打磨-11: 飞升后灵气不再使用, 神通爆发改为获得道行
	if ascended:
		dao += gain
		return "施展「%s」! 瞬间获得道行 %s!" % [s["name"], fmt(gain)]
	essence += gain
	return "施展「%s」! 瞬间获得灵气 %s!" % [s["name"], fmt(gain)]

# ================= 装备 =================

func buy_equipment(id: String) -> String:
	if owned_eq.has(id):
		return "已经拥有了哦"
	var e: Dictionary = equip_by_id.get(id, {})
	if e.is_empty():
		return "未找到该装备"
	if stones < float(e["cost"]):
		return "灵石不足: 需要 %s" % fmt(float(e["cost"]))
	stones -= float(e["cost"])
	owned_eq.append(id)
	_stat_inc("equip_buy")  # 打磨-14: 装备购置计数
	var msg := "购得「%s」(%s)" % [e["name"], e["tier_name"]]
	var slot := str(e["slot"])
	if equipped.get(slot) == null:
		equipped[slot] = id
		msg += ", 已自动穿戴!"
	return msg

func equip_equipment(id: String) -> String:
	if not owned_eq.has(id):
		return "尚未拥有该装备"
	var e: Dictionary = equip_by_id.get(id, {})
	if e.is_empty():
		return "未找到该装备"
	equipped[str(e["slot"])] = id
	return "已穿戴「%s」" % e["name"]

func unequip(slot: String) -> String:
	if equipped.has(slot):
		equipped.erase(slot)
		return "已卸下" + SLOT_CN[slot]
	return SLOT_CN[slot] + " 上没有装备"

func equipped_name(slot: String) -> String:
	var id: String = equipped.get(slot, "")
	if id == "":
		return "(空)"
	var e: Dictionary = equip_by_id.get(id, {})
	return str(e["name"]) if not e.is_empty() else "(空)"

# ================= 突破 =================

# roll: 传入 [0,1) 可确定性注入 (自测用), 默认 randf()
func try_breakthrough(roll: float = -1.0) -> String:
	last_break_result = 0
	if ascended:
		return "你已在仙界, 道无止境 ♪"
	var cost := breakthrough_cost()
	if essence < cost:
		return "灵气不足: 需要 %s" % fmt(cost)
	essence -= cost
	if roll < 0.0:
		roll = randf()
	if roll < breakthrough_chance():
		_advance()
		last_break_result = 3 if ascended else 1
		break_seq += 1
		_stat_inc("break_ok")  # 打磨-14: 突破成功计数 (含飞升)
		if ascended:
			return "轰——天雷散尽, 你飞升真仙界了! 灵气速率 x100000!"
		return "突破成功! 当前境界: %s %s" % [realm_name(), layer_name()]
	else:
		last_break_result = 2
		break_seq += 1
		_stat_inc("break_fail")  # 打磨-14: 突破失败计数
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
				_stat_inc("item_buy")  # 打磨-14: 法器购置计数
				return "购得「%s」, 灵气速率 x%.1f!" % [it["name"], it["boost"]]
			else:
				return "灵石不足: 需要 %s" % fmt(it["cost"])
	return "未找到该法器"

# ================= 打磨-10: 道行 (飞升后目标) =================

func dao_break_cost() -> float:
	return DAO_BREAK_BASE * pow(DAO_BREAK_GROWTH, dao_level)

func dao_break_chance() -> float:
	return clampf(0.90 - 0.03 * dao_level + passive_bonus("bt_chance") + equip_bonus("bt_chance"), 0.05, 0.99)

# 飞升后点击突破按钮 -> 道行精进; roll 可注入 [0,1) 确定性测试
func try_dao_break(roll: float = -1.0) -> String:
	last_break_result = 0
	if not ascended:
		return "飞升后方可修炼道行"
	if dao_level >= IMMORTAL_REALMS.size() - 1:
		return "已至道祖, 道法自然 ♪"
	var cost := dao_break_cost()
	if dao < cost:
		return "道行不足: 需要 %s" % fmt(cost)
	dao -= cost
	if roll < 0.0:
		roll = randf()
	if roll < dao_break_chance():
		dao_level += 1
		last_break_result = 4
		break_seq += 1
		_stat_inc("dao_ok")  # 打磨-14: 道行精进成功计数
		return "道行精进! 当前境界: %s·%s" % [realm_name(), IMMORTAL_REALMS[dao_level]]
	last_break_result = 2
	break_seq += 1
	return "道行精进失败… 道心不稳, 静修再来!"

# 境界展示 (顶栏): 未飞升 "练气 第 1 层" / 飞升后 "真仙·初仙 (已飞升)"
func realm_display() -> String:
	if not ascended:
		return "%s %s" % [realm_name(), layer_name()]
	return "真仙·%s (已飞升)" % IMMORTAL_REALMS[dao_level]

# ================= 存档 =================

func save_game() -> void:
	var data := {
		"realm_idx": realm_idx,
		"layer": layer,
		"essence": essence,
		"stones": stones,
		"owned": owned,
		"skills": learned,
		"eq_owned": owned_eq,
		"equipped": equipped,
		"ach_done": ach_done,
		"ascended": ascended,
		"dao": dao,
		"dao_level": dao_level,
		"stats": stats,
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
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	realm_idx = clampi(int(parsed.get("realm_idx", 0)), 0, REALMS.size() - 1)
	layer = clampi(int(parsed.get("layer", 1)), 1, REALMS[realm_idx]["layers"] as int)
	essence = float(parsed.get("essence", 0.0))
	stones = float(parsed.get("stones", 0.0))
	ascended = bool(parsed.get("ascended", false))
	dao = float(parsed.get("dao", 0.0))
	dao_level = clampi(int(parsed.get("dao_level", 0)), 0, IMMORTAL_REALMS.size() - 1)
	owned = _str_array(parsed.get("owned", []))
	learned = _str_array(parsed.get("skills", []))
	owned_eq = _str_array(parsed.get("eq_owned", []))
	ach_done = _str_array(parsed.get("ach_done", []))
	_load_stats(parsed.get("stats", {}))  # 打磨-14: 修行统计 (旧档缺字段默认 0)
	equipped = {}
	var eq: Dictionary = parsed.get("equipped", {})
	if typeof(eq) == TYPE_DICTIONARY:
		for slot in SLOTS:
			var id: String = eq.get(slot, "")
			if typeof(id) == TYPE_STRING and owned_eq.has(id):
				equipped[slot] = id
	# 离线收益
	var ts := int(parsed.get("ts", 0))
	if ts > 0:
		var elapsed := clampf(Time.get_unix_time_from_system() - float(ts), 0.0, OFFLINE_CAP_SEC)
		if elapsed > 60.0:
			var rate := offline_rate()
			var gq := qi_per_sec() * elapsed * rate
			var gs := stone_per_sec() * elapsed * rate
			stones += gs
			if ascended:
				dao += gq
				offline_msg = "离线 %s, 效率%0.0f%%, 收获道行 %s, 灵石 %s" % [
					fmt_time(elapsed), rate * 100.0, fmt(gq), fmt(gs)]
			else:
				essence += gq
				offline_msg = "离线 %s, 效率%0.0f%%, 收获灵气 %s, 灵石 %s" % [
					fmt_time(elapsed), rate * 100.0, fmt(gq), fmt(gs)]

func _str_array(v) -> Array[String]:
	var out: Array[String] = []
	if typeof(v) == TYPE_ARRAY:
		for item in v:
			if typeof(item) == TYPE_STRING:
				out.append(item)
	return out

# ================= 展示 =================

func realm_name() -> String:
	return REALMS[realm_idx]["name"] as String

func layer_name() -> String:
	if ascended:
		return "已飞升"
	return "第 %d 层" % layer

func breakthrough_progress() -> float:
	if ascended:
		if dao_level >= IMMORTAL_REALMS.size() - 1:
			return 100.0
		return clampf(dao / dao_break_cost() * 100.0, 0.0, 100.0)
	return clampf(essence / breakthrough_cost() * 100.0, 0.0, 100.0)

func fmt(v: float) -> String:
	if v >= 1e20:
		return "%.1f垓" % (v / 1e20)
	if v >= 1e16:
		return "%.1f京" % (v / 1e16)
	if v >= 1e12:
		return "%.1f兆" % (v / 1e12)
	if v >= 1e8:
		return "%.1f亿" % (v / 1e8)
	if v >= 1e4:
		return "%.1f万" % (v / 1e4)
	return str(int(v))

func fmt_time(sec: float) -> String:
	var h := int(sec) / 3600
	var m := int(sec) % 3600 / 60
	if h > 0:
		return "%d小时%d分" % [h, m]
	if m >= 1:
		return "%d分" % m
	return "不足1分"

# ---------- 打磨-12: 购买 ETA (灵石何时足够) ----------

# 灵石攒够所需秒数: 0 = 现在即可购买; -1 = 无灵石收入
func eta_seconds(cost: float) -> float:
	if cost <= stones:
		return 0.0
	var r: float = stone_per_sec()
	if r <= 0.0:
		return -1.0
	return (cost - stones) / r

# 购买 ETA 文本 (行内提示; "" = 现在买得起)
func eta_text(cost: float) -> String:
	var t: float = eta_seconds(cost)
	if t == 0.0:
		return ""
	if t < 0.0:
		return "无灵石收入"
	if t < 60.0:
		return "不足1分可购"
	return "约 %s 可购" % fmt_time(t)
