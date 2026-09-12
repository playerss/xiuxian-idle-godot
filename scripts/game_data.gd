extends Node
## 全局游戏数据：挂机核心 + 技能/装备 + 存档 (autoload: GameData)

const SAVE_PATH := "user://save.json"
const SKILLS_JSON := "res://data/skills.json"
const EQUIP_JSON := "res://data/equipment.json"
const ACH_JSON := "res://data/achievements.json"
# M5-2: 爬塔数据 (镇妖塔 1000 层表 / 登天梯公式 / 145 怪物 / 18 特性)
const TOWER_JSON := "res://data/tower_monsters.json"
const MONSTERS_JSON := "res://data/monsters.json"
const TRAITS_JSON := "res://data/monster_traits.json"
const AFFIX_JSON := "res://data/affixes.json"
const OFFLINE_CAP_SEC := 8 * 3600.0   # 离线收益上限 8 小时
const OFFLINE_BASE_RATE := 0.5       # 基础离线效率 50%
const SAVE_INTERVAL_SEC := 15.0
# M5-2: 玩家战力基础 (境界 x 功法装备 atk/def 池 之上的 战力公式)
# 战力 = 基础 x 成长^进度 (进度: 未飞升=境界索引, 飞升后=真仙境 + 道行阶段 0..8)
# 成长 40 校准: 新档(练气1层, 战力 2.0) 可胜 镇妖塔 1 层; 渡劫期 封顶 ~5e15 (不可通关);
# 道祖 (进度 17) 战力 ~3e28 可通关 1000 层 (含 剧毒 减成 后 仍 可通关) —— 通关点 ≈ 道祖期
const TOWER_BASE_ATK := 2.0
const TOWER_BASE_DEF := 2.0
const TOWER_POWER_GROWTH := 40.0
const TOWER_WIN_RATIO := 0.85        # 判定: 玩家 atk >= 怪 atk x 0.85 即胜
const TOWER_POISON_ATK_MULT := 0.85  # 剧毒: 战胜后 玩家 atk -15%, 持续 2 场
const TOWER_POISON_BATTLES := 2      # 剧毒持续场数
# M5-4: 镇妖塔 通关 一次性 大奖 (首通 1000 层 Boss: 称号 + 灵石 大奖 + 永久 atk/def 增益,
# 守塔 模式 保持 长期 收益; 神品词缀 大奖 待 M6 词缀系统 落地 后 替换 口径 — 原计划 神品词缀 x3)
const TOWER_CLEAR_BONUS_STONE := 1000000.0  # 通关 一次性 灵石 大奖
const TOWER_CLEAR_BUFF := 0.15              # 通关 永久 增益: 玩家 atk/def +15% (乘算 独立 项)
const ENDLESS_ELITE_MULT := 3.0      # 登天梯 精英层 (每 10 层) 数值 x3
const ENDLESS_BOSS_MULT := 10.0      # 登天梯 里程碑 Boss (每 100 层) 数值 x10

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
	{"id": "wooden_sword", "name": "木剑", "desc": "修行人的伙伴", "cost": 100, "boost": 1.5, "atk": 0.01, "def": 0.01},
	{"id": "jade_talisman", "name": "玉符", "desc": "静心护体", "cost": 1000, "boost": 2.0, "atk": 0.02, "def": 0.02},
	{"id": "spirit_bag", "name": "聚灵袋", "desc": "引四方灵气", "cost": 6000, "boost": 3.0, "atk": 0.03, "def": 0.03},
	{"id": "star_lamp", "name": "引星灯", "desc": "借星力修行", "cost": 45000, "boost": 5.0, "atk": 0.05, "def": 0.04},
	{"id": "immortal_flute", "name": "仙音笛", "desc": "一缕仙音, 道心通明", "cost": 250000, "boost": 8.0, "atk": 0.07, "def": 0.06},
	{"id": "star_dock", "name": "星槎", "desc": "乘槎问星, 直上天河", "cost": 1500000, "boost": 12.0, "atk": 0.09, "def": 0.08},
	{"id": "void_mirror", "name": "太虚镜", "desc": "照见太虚, 返璞归真", "cost": 5000000, "boost": 18.0, "atk": 0.12, "def": 0.10},
	{"id": "primordial_lamp", "name": "太初道灯", "desc": "一盏长明, 照破鸿蒙", "cost": 20000000, "boost": 25.0, "atk": 0.15, "def": 0.13},
	{"id": "chaos_bell", "name": "鸿蒙道钟", "desc": "一钟一世界, 道在钟鸣", "cost": 80000000, "boost": 40.0, "atk": 0.18, "def": 0.16},
	{"id": "ascension_seal", "name": "渡劫引仙印", "desc": "仙缘已至, 只待飞升", "cost": 300000000, "boost": 60.0, "atk": 0.22, "def": 0.20},
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
# M5-2: 爬塔 数据表 (镇妖塔层表 / 怪物表 / 特性表; 战斗计算直接消费)
var tower_fixed: Dictionary = {}        # 镇妖塔 {name,max_floor,formulas,elite,boss}
var tower_endless: Dictionary = {}      # 登天梯 {name,milestone_floor,formulas,elite,boss}
var tower_floors: Array = []            # 镇妖塔 1000 层 (index floor-1)
var tower_floor_by_idx: Dictionary = {} # floor -> 层 记录 (O(1) 查)
var monster_by_id := {}                # 怪物 id -> 记录 (145)
var monster_ids: Array = []
var trait_by_id := {}                  # 特性 id -> {name,group,desc,mult} (18)
var _endless_species: Array = []       # 120 普通怪物种 (登天梯 普通层 候选池)
var _endless_small_bosses: Array = []  # 20 小 Boss (登天梯 里程碑 候选池)
var _trait_ids: Array = []             # 18 特性 id (确定性 追加特性 用)
var affix_by_id := {}                  # M6-2: 词缀 id -> 记录 (120)
var affix_ids: Array = []
var affix_tier_names: Array = []       # M6-2: 词缀 品质 5 档 名称
var _affix_buckets: Array = []         # M6-2: 掉落 品质 权重 20 桶
var _affix_sources := {}               # M6-2: 掉落 来源 配置 (normal/elite/boss/milestone)
var _affix_cfg := {}                   # M6-2: 装配/背包 配置 (bag_capacity/slots_per_equip/slot_max)

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
# 打磨-66: 本次离线收益明细 (启动金色浮动提示用; load_game 计算, 只读展示)
var _offline_sec := 0.0     # 离线时长 (秒, <=60 或无档时 0)
var _offline_qi := 0.0      # 离线收获 灵气/道行
var _offline_stone := 0.0   # 离线收获 灵石
var last_break_result := 0  # 上次突破: 0=未触发 1=成功 2=失败 3=飞升
var break_seq := 0          # 突破事件序号 (每次成功/失败/飞升 +1, UI 据此触发闪烁)
var auto_break := false     # 打磨-67: 自动突破 (开=资源攒够自动尝试 突破/道行精进, 存档持久化)
var auto_buy := false       # 打磨-68: 自动购置 (开=灵石攒够自动购买 法器/装备 + 自动最佳穿戴, 存档持久化)
var _auto_buy_seq := 0      # 打磨-68: 自动购置 变更事件计数 (每轮 实际变更 +1, 不持久化, UI 据此刷底部消息)
var _auto_buy_last_items := 0   # 打磨-68: 上轮 新购 法器 件数 (内存态, 供 auto_buy_last_text)
var _auto_buy_last_equip := 0   # 打磨-68: 上轮 新购 装备 件数 (内存态, 供 auto_buy_last_text)
var _auto_buy_last_cost := 0.0  # 打磨-68: 上轮 花费 灵石 (内存态, 供 auto_buy_last_text)
var _auto_buy_last_swap := 0    # 打磨-68: 上轮 最佳换装 槽位数 (内存态, 供 auto_buy_last_text)
var auto_cast := false          # 打磨-69: 自动施展 (开=主动神通冷却完毕自动施展爆发, 存档持久化)
var _auto_cast_seq := 0         # 打磨-69: 自动施展 变更事件计数 (每轮 实际施展 +1, 不持久化, UI 据此弹浮动)
var auto_learn := false         # 打磨-80: 自动领悟 (开=境界提升后自动批量学习 可学 技能, 存档持久化)
var _auto_learn_seq := 0        # 打磨-80: 自动领悟 变更事件计数 (每轮 实际学习 +1, 不持久化, UI 据此刷底部消息)
var _auto_learn_last_n := 0     # 打磨-80: 上轮 学习 技能 数 (内存态, 供 auto_learn_last_text)
var _auto_cast_last_n := 0      # 打磨-69: 上轮 施展 神通 数 (内存态, 供 auto_cast_last_text)
var _auto_cast_last_burst := 0.0  # 打磨-69: 上轮 爆发 总量 (内存态, 供 auto_cast_last_text)
var stats: Dictionary = {}  # 打磨-14: 修行统计 (累计时长/突破/道行/神通/法器/装备/爬塔, 读档时 _load_stats 兜底)

# M5-2: 爬塔 状态 (存档持久化, 旧档缺字段默认 0)
var tower_fixed_floor := 0       # 镇妖塔 最高 已过 层 (0=未登塔, 通关态 = 1000)
var tower_fixed_clear := false   # 镇妖塔 通关 (1000 层 全过)
var tower_endless_floor := 1     # 登天梯 当前 可挑战 层 (从 1 起, 打 当前 层 胜 -> +1)
var tower_endless_best := 0      # 登天梯 历史 最高 纪录 层
var tower_daily_date := ""       # 登天梯 每日首胜 日期 标记 (YYYY-MM-DD, 跨日 重置)
var tower_daily_bonus_stones := 0.0  # 登天梯 当日 首胜 已发 灵石 总数
var tower_clear_reward_got := false  # M5-4: 通关 一次性 大奖 已 发放 (称号/灵石/永久增益 只 触发一次, 防 存档 重放 重复 发放)
var poison_battles := 0          # 剧毒 跨场 debuff 剩余 场数 (0=无毒; >0=玩家 atk -15%, 持续 2 场)
# M6-2: DIY 词缀 (库存/装配/槽位升级; 旧档缺字段 默认 空/0)
var affix_bag := {}             # 词缀 id -> 堆叠 数量 (数量制, 背包格数 = 非零 id 数)
var affix_load := {}            # 装备 id -> {0,1,2,...: 词缀 id} (槽位 -> 词缀)
var slot_upgrades := {}         # 装备 id -> 额外 槽位数 (0..1, 道祖期 上限 4 槽)
# M5-3: 自动爬塔 (开=镇妖塔+登天梯 自动 挑战; GameData._process 每帧驱动, 自门控,
# 胜推进/败停留 天然无热循环; 与 自动系列 4 开关 同口径: 存档持久化, 旧档缺字段默认 关, 离线期间 不触发)
var auto_tower := false

var _active_cd := {}        # 技能 id -> 剩余冷却秒
var _save_acc := 0.0
var _ach_acc := 0.0         # 成就检测节流累计
# 打磨-57: 主动神通 冷却完毕转就绪 事件队列 (冷却在 _process 结束时产生,
# UI 每帧 drain_ready_events 消费; 只读不改动 状态/存档/统计, 不持久化)
var ready_events: Array[String] = []

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
	# 打磨-67: 自动突破 (开启时 资源攒够 自动尝试; _try_auto_break 自门控于 auto_break,
	# 每帧至多一次, 突破后资源已低于 下一档 阈值, 无热循环)
	_try_auto_break()
	# 打磨-80: 自动领悟 (开启时 境界/层 变化 自动 批量学习 新可学 技能; 置于 _try_auto_break 之后:
	# 同帧 突破升层/晋境界 后 立即学习 新解锁 技能; _try_auto_learn 自门控于 auto_learn,
	# 学习后 可学数 归 0, 下帧 再试 0 变更 幂等, 无热循环)
	_try_auto_learn()
	# 打磨-68: 自动购置 (开启时 灵石攒够 自动购入 法器/装备 并 最佳换装; _try_auto_buy 自门控于
	# auto_buy, 灵石攒够才触发, 每帧至多一轮; 无浮动/闪烁 反馈 防 挂机刷屏)
	_try_auto_buy()
	# 打磨-69: 自动施展 (开启时 主动神通 冷却完毕 自动 施展 爆发; _try_auto_cast 自门控于
	# auto_cast, 每帧至多一轮; 置于 _tick_active_cd 之前: 冷却归零 同帧 即自动施展,
	# 施展后 各神通 进冷却, 全冷却中 0 施展 幂等 无热循环)
	_try_auto_cast()
	# M5-3: 自动爬塔 (开启时 双塔 自动 挑战; _try_auto_tower 自门控于 auto_tower,
	# 镇妖塔 通关态 守塔 模式 恒胜 1000 层 Boss, 登天梯 败 停留 本层, 无热循环)
	_try_auto_tower()
	_stat_inc("play_sec", delta)  # 打磨-14: 累计在线时长
	_tick_active_cd(delta)  # 神通冷却
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
	_load_tower_data()
	_load_affix_data()

# M6-2: 加载 词缀 数据 (120 词缀 + 掉落 概率 表 + 装配/背包 配置)
func _load_affix_data() -> void:
	var af: Dictionary = _load_json(AFFIX_JSON)
	if af == null:
		return
	affix_by_id = {}
	affix_ids.clear()
	if af.has("affixes"):
		for a in af["affixes"]:
			affix_by_id[a["id"]] = a
			affix_ids.append(a["id"])
	affix_tier_names.clear()
	if af.has("tier_names"):
		for t in af["tier_names"]:
			affix_tier_names.append(str(t))
	_affix_buckets.clear()
	if af.has("drop") and typeof(af["drop"]) == TYPE_DICTIONARY:
		var dp: Dictionary = af["drop"]
		if dp.has("buckets"):
			for b in dp["buckets"]:
				_affix_buckets.append(b)
		if dp.has("sources"):
			_affix_sources = dp["sources"]
	_affix_cfg = af.get("config", {})

# M5-2: 加载 爬塔 数据 (镇妖塔 1000 层表 / 登天梯 公式 / 145 怪物 / 18 特性)
func _load_tower_data() -> void:
	var tw: Dictionary = _load_json(TOWER_JSON)
	if tw.has("fixed"):
		tower_fixed = tw["fixed"]
	if tw.has("endless"):
		tower_endless = tw["endless"]
	tower_floors.clear()
	tower_floor_by_idx.clear()
	if tw.has("floors"):
		for f in tw["floors"]:
			tower_floors.append(f)
			tower_floor_by_idx[int(f["floor"])] = f
	var mo: Dictionary = _load_json(MONSTERS_JSON)
	if mo.has("monsters"):
		for m in mo["monsters"]:
			monster_by_id[m["id"]] = m
			monster_ids.append(m["id"])
			if str(m.get("kind", "")) == "species":
				_endless_species.append(m)
			elif str(m.get("kind", "")) == "boss" and str(m.get("boss_type", "")) == "small":
				_endless_small_bosses.append(m)
	var tr: Dictionary = _load_json(TRAITS_JSON)
	if tr.has("traits"):
		for t in tr["traits"]:
			trait_by_id[t["id"]] = t
			_trait_ids.append(t["id"])

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

# 已穿戴装备的加成汇总 (M6-2: 含 已装配 词缀 同池 加成; 词缀 按 已装 槽位 生效,
# 卸下/未拥有 装备 的词缀 不 计入)
func equip_bonus(eff: String) -> float:
	var total := 0.0
	for slot in SLOTS:
		var id: String = equipped.get(slot, "")
		if id == "":
			continue
		var e: Dictionary = equip_by_id.get(id, {})
		if not e.is_empty():
			total += float(e.get(eff, 0.0))
		total += affix_bonus_for_equipment(id, eff)
	return total

# M5-2: 已学 功法 atk/def 属性池 汇总 (独立 字段, 非 主 效果; 只读)
func skill_atk_bonus() -> float:
	var total := 0.0
	for id in learned:
		var s: Dictionary = skill_by_id.get(id, {})
		if not s.is_empty() and str(s.get("type", "")) == "passive":
			total += float(s.get("atk", 0.0))
	return total

func skill_def_bonus() -> float:
	var total := 0.0
	for id in learned:
		var s: Dictionary = skill_by_id.get(id, {})
		if not s.is_empty() and str(s.get("type", "")) == "passive":
			total += float(s.get("def", 0.0))
	return total

# ================= M5-2: 玩家战力 (atk/def 汇总) =================
# 境界战力进度: 未飞升 = 境界索引 (练气0..真仙9, 层内 不 单独 计 战力);
# 飞升后 = 真仙境(9) + 道行阶段 0..8 (道祖 = 17), 使 战力 随 境界/道行 单调 指数 上升
func tower_power_progress() -> int:
	if not ascended:
		return realm_idx
	return 9 + dao_level

# ================= M6-2: DIY 词缀 (库存/装配/拆卸/分解/槽位升级 + 装备属性 接入) =================
# 模型: 词缀 数量制 堆叠 (affix_bag), 每件 装备 3 槽 (slot_upgrades 道祖期 +1 至 4 槽);
# 装配 = 从背包选 词缀 装入槽位 (背包 -1), 拆卸 = 无损 回背包; 词缀 不消耗.
# 加成 口径: 已装 词缀 与 装备 同池 乘算 独立 项 — 装备 总属性 = 基础 x (1 + Σ词缀)
# (沿用 M1 防溢出 口径; 词缀 value 已 数据层 按 池 区分 加成 类型, 同池 直接 求和).
# 词缀 效果池 -> 现有 加成 体系 键: qi_rate=灵气速率 / stone_rate=灵石速率 /
# bt_chance=突破成功率 / offline_rate=离线效率 / atk=攻击 / def=防御.
const AFFIX_POOL_KEY := {
	"qi_rate": "qi_mult",
	"stone_rate": "stone_mult",
	"bt_chance": "bt_chance",
	"offline_rate": "offline_rate",
	"atk": "atk",
	"def": "def",
}

# 指定 装备 的 词缀 加成 (eff = 池键 qi_mult/stone_mult/bt_chance/offline_rate/atk/def)
# 只读: 不 改 状态/存档/统计; 未拥有 装备/空槽 返回 0
func affix_bonus_for_equipment(equip_id: String, eff: String) -> float:
	var total := 0.0
	var slots: Variant = affix_load.get(equip_id, {})
	if typeof(slots) != TYPE_DICTIONARY:
		return 0.0
	for pos in slots:
		var aid: String = str(slots[pos])
		var a: Dictionary = affix_by_id.get(aid, {})
		if a.is_empty() or str(AFFIX_POOL_KEY.get(str(a.get("pool", "")), "")) != eff:
			continue
		total += float(a.get("value", 0.0))
	return total

# 词缀 品质 名 (越界 钳制, 复用 skill_tier_name 风格)
func affix_tier_name(t: int) -> String:
	if affix_tier_names.is_empty():
		return "词缀"
	return str(affix_tier_names[clampi(t, 0, affix_tier_names.size() - 1)])

# 指定 装备 的 词缀槽 数 (基础 3 + 道祖期 升级 +1, 上限 4; 数据 配置 兜底)
func equipment_slots(equip_id: String) -> int:
	var base := int(_affix_cfg.get("slots_per_equip", 3))
	var cap := int(_affix_cfg.get("slot_max", 4))
	var up := int(slot_upgrades.get(equip_id, 0))
	return clampi(base + up, 1, cap)

# 指定 装备 已装 词缀 槽位 数 (0..槽数)
func affix_slots_used(equip_id: String) -> int:
	var slots: Variant = affix_load.get(equip_id, {})
	if typeof(slots) != TYPE_DICTIONARY:
		return 0
	return (slots as Dictionary).size()

# 装备 词缀 配置 行 (tooltip/UI 展示: 槽位 N/M + 已装 词缀 名·品质·数值)
func affix_load_text(equip_id: String) -> String:
	var n := affix_slots_used(equip_id)
	var m := equipment_slots(equip_id)
	if n == 0:
		return "词缀槽 %d/%d (未装配)" % [n, m]
	var parts: Array = []
	var slots: Dictionary = affix_load.get(equip_id, {})
	var keys: Array = (slots.keys() as Array).duplicate()
	keys.sort_custom(func(a, b): return int(a) < int(b))
	for pos in keys:
		var a: Dictionary = affix_by_id.get(str(slots[pos]), {})
		if a.is_empty():
			parts.append(str(slots[pos]))
			continue
		parts.append("%s(%s +%s)" % [a["name"], affix_tier_name(int(a["tier"])), fmt(float(a["value"]))])
	return "词缀槽 %d/%d: %s" % [n, m, " · ".join(parts)]

# ---------- M6-2: 套装 共鸣 (同 品质 装配 词缀 满 3 件 触发; 只读) ----------
# 口径: 统计 已装配 (affix_load) 词缀 按 品质 分档; 某档 装配 数 N>=3 时
# atk/def 乘算 独立 项 x(1 + 0.02 x N) (每 件 同品质 +2%, 3 件 = +6%).
# 仅 atk/def (计划 口径: 同 品质 N 件 atk/def 额外 xN%); 不 进 equip_bonus (独立 乘项, 防 溢出).
const AFFIX_RESONANCE_MIN := 3
const AFFIX_RESONANCE_PER := 0.02

# 已装配 词缀 按 品质 计数 {tier: 件数} (只读)
func resonance_count() -> Dictionary:
	var out: Dictionary = {}
	for equip_id in affix_load:
		var slots: Variant = affix_load.get(equip_id, {})
		if typeof(slots) != TYPE_DICTIONARY:
			continue
		for pos in (slots as Dictionary):
			var a: Dictionary = affix_by_id.get(str((slots as Dictionary)[pos]), {})
			if a.is_empty():
				continue
			var t: int = int(a.get("tier", 0))
			out[t] = int(out.get(t, 0)) + 1
	return out

# 共鸣 乘数 (未 触发 = 1.0; 多档 可 叠加 连乘)
func resonance_mult() -> float:
	var m := 1.0
	var cnt := resonance_count()
	for t in cnt:
		var n: int = int(cnt[t])
		if n >= AFFIX_RESONANCE_MIN:
			m *= 1.0 + AFFIX_RESONANCE_PER * float(n)
	return m

# 共鸣 文案 (tooltip/UI: 无 触发 = 提示 条件; 已 触发 = 逐档 倍率)
func resonance_text() -> String:
	var cnt := resonance_count()
	if resonance_mult() <= 1.0 + 1e-9:
		var best := 0
		for t in cnt:
			best = maxi(best, int(cnt[t]))
		return "套装 共鸣: 同 品质 装配 满 %d 件 触发 (当前 最多 一档 %d 件, 未 触发)" % [AFFIX_RESONANCE_MIN, best]
	var parts: Array = []
	for t in cnt:
		var n: int = int(cnt[t])
		if n >= AFFIX_RESONANCE_MIN:
			parts.append("%s %d 件 x%.2f" % [affix_tier_name(t), n, 1.0 + AFFIX_RESONANCE_PER * float(n)])
	return "套装 共鸣: " + " · ".join(parts) + " (atk/def)"

# 背包 格数 (非零 词缀 id 数) / 容量
func affix_bag_used() -> int:
	return affix_bag.size()

func affix_bag_capacity() -> int:
	return int(_affix_cfg.get("bag_capacity", 30))

# 背包 容量 是否 已满
func affix_bag_full() -> bool:
	return affix_bag_used() >= affix_bag_capacity()

# 入包 (词缀掉落/分解 回退 用): 堆叠 +n; 背包 满 时 普通品质 自动 入料 (分解, 不占格),
# 高品质 拒绝 (返回 未入包 计数, 掉落 结算 跳过). 返回 实际 入包 数.
func affix_add(id: String, n: int) -> int:
	var a: Dictionary = affix_by_id.get(id, {})
	if a.is_empty() or n <= 0:
		return 0
	if not affix_bag.has(id) and affix_bag_full():
		# 背包满: 普通品质 (tier 0) 自动入料 (丢弃不占格, 计 分解 埋点), 高品质 拒绝
		if int(a.get("tier", 0)) == 0:
			_stat_inc("affix_decompose", n)
			return 0
		return 0
	affix_bag[id] = int(affix_bag.get(id, 0)) + n
	_affix_seen_mark(id)  # M6-3: 收集 成就 曾 入包 标记 (只增不减)
	return n

# 分解: 词缀 -> 材料 (防 背包 溢出; 数量 上限 钳制). 返回 实际 分解 数
func affix_decompose(id: String, n: int = -1) -> int:
	if not affix_bag.has(id):
		return 0
	var have := int(affix_bag[id])
	var cnt := have if n < 0 else mini(n, have)
	if cnt <= 0:
		return 0
	_stat_inc("affix_decompose", cnt)
	if have - cnt <= 0:
		affix_bag.erase(id)
	else:
		affix_bag[id] = have - cnt
	return cnt

# 装配: 背包 词缀 装入 装备 槽位 (背包 -1; 词缀 不消耗, 纯 排列 组合).
# 成功 返回 "", 失败 返回 原因 (背包 无此词缀/槽位 已满/该槽已装 同词缀 等)
func affix_equip(equip_id: String, slot_pos: int, affix_id: String) -> String:
	var e: Dictionary = equip_by_id.get(equip_id, {})
	if e.is_empty():
		return "未找到该装备"
	if not owned_eq.has(equip_id):
		return "尚未拥有该装备"
	var a: Dictionary = affix_by_id.get(affix_id, {})
	if a.is_empty():
		return "未找到该词缀"
	if int(affix_bag.get(affix_id, 0)) <= 0:
		return "背包 没有 该词缀"
	var slots := equipment_slots(equip_id)
	if slot_pos < 0 or slot_pos >= slots:
		return "槽位 越界 (1~%d)" % slots
	var load: Dictionary = affix_load.get(equip_id, {})
	if str(load.get(str(slot_pos), "")) != "":
		return "该槽位 已装配 (先卸下 再 换装)"
	load[str(slot_pos)] = affix_id  # 键 用 字符串 (JSON 往返 键 恒 为 字符串, 统一 口径)
	affix_load[equip_id] = load
	affix_bag[affix_id] = int(affix_bag[affix_id]) - 1
	if int(affix_bag[affix_id]) <= 0:
		affix_bag.erase(affix_id)
	_stat_inc("affix_equip")
	return ""

# 拆卸: 槽位 词缀 无损 回背包 (数量制 不消耗). 成功 返回 "", 失败 返回 原因
func affix_unequip(equip_id: String, slot_pos: int) -> String:
	var load: Dictionary = affix_load.get(equip_id, {})
	var key := str(slot_pos)
	var aid: String = str(load.get(key, ""))
	if aid == "":
		return "该槽位 未装配"
	load.erase(key)
	if load.is_empty():
		affix_load.erase(equip_id)
	else:
		affix_load[equip_id] = load
	affix_bag[aid] = int(affix_bag.get(aid, 0)) + 1
	return ""

# 换装: 槽位 卸下 旧 词缀 回背包 后 装入 新 词缀 (一步 完成; 背包 无 新 词缀 则 失败 不 改动)
func affix_swap(equip_id: String, slot_pos: int, affix_id: String) -> String:
	var load: Dictionary = affix_load.get(equip_id, {})
	var old: String = str(load.get(str(slot_pos), ""))
	var err: String = ""
	if old != "":
		affix_unequip(equip_id, slot_pos)
		err = affix_equip(equip_id, slot_pos, affix_id)
		if err != "":
			# 回滚: 把 刚 卸下 的 词缀 装回 (背包 此刻 必有 — 拆卸 刚 放入)
			affix_equip(equip_id, slot_pos, old)
		return err
	return affix_equip(equip_id, slot_pos, affix_id)

# 槽位 升级: 道祖期 解锁 3 槽 -> 4 槽 (每件 至多 1 次; 无 资源 消耗 口径, M6-4 数值 平衡 可 追加)
func affix_slot_upgrade(equip_id: String) -> String:
	if not owned_eq.has(equip_id):
		return "尚未拥有该装备"
	if int(slot_upgrades.get(equip_id, 0)) >= 1:
		return "槽位 已 满级"
	if not ascended or dao_level < IMMORTAL_REALMS.size() - 1:
		return "需 道祖期 解锁 第 4 槽"
	slot_upgrades[equip_id] = 1
	return ""

# 掉落 桶 位 (层数 -> 桶; 封顶 19; 越界 防御 0)
func affix_drop_bucket(floor: int) -> int:
	if _affix_buckets.is_empty():
		return 0
	var size := 50
	var max_b := int(_affix_buckets.size()) - 1
	return clampi((maxi(floor, 1) - 1) / size, 0, max_b)

# 掉落 品质 判定 (确定性: roll 0..1 按 桶 权重 表 加权 抽取; 供 自测 注入 确定性 roll)
func affix_roll_tier(bucket: int, roll: float) -> int:
	if _affix_buckets.is_empty():
		return 0
	var b: Variant = _affix_buckets[clampi(bucket, 0, _affix_buckets.size() - 1)]
	var w: Array = b if typeof(b) == TYPE_ARRAY else []
	if w.size() != 5:
		return 0
	var total := 0.0
	for x in w:
		total += float(x)
	if total <= 0.0:
		return 0
	var r := clampf(roll, 0.0, 1.0) * total
	var acc := 0.0
	for i in 5:
		acc += float(w[i])
		if r < acc:
			return i
	return 4

# 掉落 词缀 判定 (确定性; 返回 实际 入包 词缀 id 列表, 背包满 拒绝 的 不计入).
# source = normal/elite/boss/milestone (数据 掉落 来源 配置 口径: 掉率/件数/桶位上移).
# rolls 口径 (供 自测 注入 确定性): [0]=掉率判定 / [1]=件数 / [2..4]=各件 品质 /
# [5]=池 (0..5) / [6]=变体 (0..3); 缺失 项 按 0.5 兜底 (不影响 确定性)
func affix_roll_drop(source: String, floor: int, rolls: Array) -> Array:
	var out: Array = []
	var src: Dictionary = _affix_sources.get(source, {})
	if src.is_empty() or rolls.size() < 3:
		return out
	var chance: float = float(src.get("chance", 0.0))
	if float(rolls[0]) >= chance:
		return out
	var cnt := int(src.get("count_min", 1))
	var span := maxi(int(src.get("count_max", 1)) - cnt + 1, 1)
	if span > 1:
		cnt += int(clampf(float(rolls[1]), 0.0, 1.0) * float(span))
	var bucket := affix_drop_bucket(floor) + int(src.get("bonus_buckets", 0))
	var pool_idx := int(clampf(float(rolls[5]) if rolls.size() > 5 else 0.5, 0.0, 1.0) * 6.0)
	var var_idx := int(clampf(float(rolls[6]) if rolls.size() > 6 else 0.5, 0.0, 1.0) * 4.0)
	for i in cnt:
		var tr: float = float(rolls[mini(2 + i, rolls.size() - 1)] if rolls.size() > 2 else 0.5)
		var tier := affix_roll_tier(bucket, tr)
		var aid := _affix_id_by_pool_tier_variant(pool_idx, tier, var_idx)
		if aid != "" and affix_add(aid, 1) > 0:
			out.append(aid)
	return out

# 按 池序/品质/变体 定位 词缀 id (数据 命名 恒等: af_<pool>_<tier>_<variant>, pool 顺序 = AFFIX 6 池 固定序)
func _affix_id_by_pool_tier_variant(pool_idx: int, tier: int, var_idx: int) -> String:
	var pools: Array = []
	var seen: Dictionary = {}
	for id in affix_ids:
		var a: Dictionary = affix_by_id.get(str(id), {})
		if a.is_empty():
			continue
		var p: String = str(a.get("pool", ""))
		if not seen.has(p):
			seen[p] = true
			pools.append(p)
	var p: String = pools[clampi(pool_idx, 0, maxi(pools.size() - 1, 0))]
	return "af_%s_%d_%d" % [p, clampi(tier, 0, 4), clampi(var_idx, 0, 3)]

# ---------- M6-3: DIY 评分 / 词缀 收集 / 装配 预览 (UI 交互 数据层) ----------

# 装备 已装 词缀 6 池 总和 (评分/换装对比 用; 只读 不 改 状态/存档/统计)
func equip_affix_total(equip_id: String) -> float:
	var total := 0.0
	for eff in ["qi_mult", "stone_mult", "bt_chance", "offline_rate", "atk", "def"]:
		total += affix_bonus_for_equipment(equip_id, eff)
	return total

# 装备 评分 (数值化 总分: 装备 基础 6 池 + 已装 词缀 6 池; 装备列表/换装对比 排序 口径).
# 评分 对 词缀 装配 严格 单调 递增 (装词缀 恒 提升 评分, 词缀 value 恒正)
func equip_score(equip_id: String) -> float:
	var e: Dictionary = equip_by_id.get(equip_id, {})
	if e.is_empty():
		return 0.0
	var s := float(e.get("qi_mult", 0.0)) + float(e.get("stone_mult", 0.0))
	for eff in ["bt_chance", "offline_rate", "atk", "def"]:
		s += float(e.get(eff, 0.0))
	return s + equip_affix_total(equip_id)

# 词缀 品质 色 (灰/绿/蓝/紫/金; 与 装备 TIER_COLOR 同 风格, 越界 钳制)
func affix_tier_color(t: int) -> Color:
	var cols: Array = [
		Color(0.6, 0.62, 0.68), Color(0.55, 0.85, 0.55), Color(0.5, 0.7, 0.98),
		Color(0.8, 0.55, 0.98), Color(0.98, 0.86, 0.5)]
	return cols[clampi(t, 0, cols.size() - 1)]

# 词缀 颜色 (按 品质; 未知 id = 灰)
func affix_color(aid: String) -> Color:
	var a: Dictionary = affix_by_id.get(aid, {})
	return affix_tier_color(int(a.get("tier", 0)) if not a.is_empty() else 0)

# 槽位 装配 评分 预览: 若 把 词缀 装入 空槽, 评分 变化 量 (只读 模拟).
# 评分 线性 (6 池 求和), delta = 该词缀 value (与 实际 装配 后 评分 差 恒等);
# 槽位 已装/越界/未拥有 装备/未知 词缀 = 0 (UI 据此 显示 Δ 或 隐藏)
func affix_equip_preview(equip_id: String, slot_pos: int, affix_id: String) -> float:
	var e: Dictionary = equip_by_id.get(equip_id, {})
	if e.is_empty() or not owned_eq.has(equip_id):
		return 0.0
	var a: Dictionary = affix_by_id.get(affix_id, {})
	if a.is_empty():
		return 0.0
	if slot_pos < 0 or slot_pos >= equipment_slots(equip_id):
		return 0.0
	var load: Dictionary = affix_load.get(equip_id, {})
	if str(load.get(str(slot_pos), "")) != "":
		return 0.0
	return float(a.get("value", 0.0))

# 词缀 收集 (曾 入包 过的 词缀 id 集合; 卸下/分解 不 移除, 只增不减).
# 背包 集齐 120 成就 判 此 集合; 存档 seen_affixes 字段 (旧档 缺 默认 空).
var seen_affixes: Array = []

# 标记 词缀 曾 入包 (affix_add 成功后 调用; 幂等)
func _affix_seen_mark(aid: String) -> void:
	if not seen_affixes.has(aid):
		seen_affixes.append(aid)

# 收集 进度 文本 (装备页 词缀背包 标题; N/120)
func affix_seen_text() -> String:
	return "词缀 收集 %d/%d" % [seen_affixes.size(), affix_ids.size()]

const AFFIX_DIY_SLOTS := 3

# 一键 最佳 装配 (M6-3 UI): 各 装备 的 空槽 装入 背包 内 评分 贡献 最高 的 词缀
# (value 降序, 同 value 按 id 确定性; 词缀 不消耗 只 转移, 每槽 至多 1 件).
# 返回 实际 装配 数 (0 = 无 空槽 或 背包 空, 幂等 安全); 复用 affix_equip 口径 (含 槽位 校验)
func affix_auto_best() -> int:
	var cnt := 0
	var cands: Array = []
	for aid in affix_bag:
		cands.append(aid)
	cands.sort_custom(func(a, b) -> bool:  # 评分 贡献 (value) 降序, 同 value id 升序
		var va: float = float(affix_by_id.get(str(a), {}).get("value", 0.0))
		var vb: float = float(affix_by_id.get(str(b), {}).get("value", 0.0))
		if va != vb:
			return va > vb
		return str(a) < str(b))
	for eid in owned_eq:
		var slots := equipment_slots(str(eid))
		var load: Dictionary = affix_load.get(str(eid), {})
		for pos in slots:
			if str(load.get(str(pos), "")) != "":
				continue
			var placed := false
			for aid in cands:
				if int(affix_bag.get(str(aid), 0)) > 0:
					if affix_equip(str(eid), pos, str(aid)) == "":
						cnt += 1
						placed = true
						break
			if placed:
				continue
	return cnt

# 分解 背包 全部 词缀 (M6-3 UI 一键 分解; 返回 总 件数; 复用 affix_decompose 埋点 口径)
func affix_decompose_all() -> int:
	var ids: Array = []
	for k in affix_bag:
		ids.append(str(k))
	var total := 0
	for aid in ids:
		total += affix_decompose(str(aid), -1)
	return total

# 某 装备 是否 DIY 装满 (基础 3 槽 全 装配; 成就 diy_first 判 此 口径)
func affix_diy_full(equip_id: String) -> bool:
	return affix_slots_used(equip_id) >= AFFIX_DIY_SLOTS

# 套装 共鸣 是否 触发 (任一 品质档 装配 数 >=3; 成就 resonance_first 判 此 口径)
func affix_resonance_active() -> bool:
	return resonance_mult() > 1.0 + 1e-9

# 任一 装备 已 DIY 装满 (成就 diy_first; affix_load 载入 已 过滤 未拥有 装备)
func _affix_any_diy_full() -> bool:
	for equip_id in affix_load:
		if affix_diy_full(str(equip_id)):
			return true
	return false

# 曾 入包 过 指定 品质 词缀 (成就 affix_legend 判 tier=4 传说; 只增不减 口径)
func _affix_any_tier_seen(tier: int) -> bool:
	for aid in seen_affixes:
		var a: Dictionary = affix_by_id.get(str(aid), {})
		if not a.is_empty() and int(a.get("tier", 0)) == tier:
			return true
	return false

# 玩家 攻击 (爬塔战斗用): 基础 x 成长^进度 x (1 + 功法 atk 池 + 装备 atk 池 [含词缀]) x 通关增益
# 旧数据 无 atk 字段 时 equip_bonus 返回 0 (只读, 不改动状态)
func player_atk() -> float:
	var base := TOWER_BASE_ATK * pow(TOWER_POWER_GROWTH, float(tower_power_progress()))
	return base * (1.0 + skill_atk_bonus() + equip_bonus("atk") + item_attack()) * clear_buff_mult() * resonance_mult()

# 玩家 防御 (爬塔战斗用): 基础 x 成长^进度 x (1 + 功法 def 池 + 装备 def 池 + 法器 def 池) x 通关增益
func player_def() -> float:
	var base := TOWER_BASE_DEF * pow(TOWER_POWER_GROWTH, float(tower_power_progress()))
	return base * (1.0 + skill_def_bonus() + equip_bonus("def") + item_defense()) * clear_buff_mult() * resonance_mult()

# M5-4: 镇妖塔 通关 永久 增益 (通关后 玩家 atk/def +15%, 乘算 独立 项; 未通关=1.0; 只读)
func clear_buff_mult() -> float:
	return 1.0 + TOWER_CLEAR_BUFF if tower_fixed_clear else 1.0

# M5-2: 法器 atk/def 池 (已拥有 法器 加成; 只读)
func item_attack() -> float:
	var total := 0.0
	for it in ITEMS:
		if owned.has(str(it["id"])):
			total += float(it.get("atk", 0.0))
	return total

func item_defense() -> float:
	var total := 0.0
	for it in ITEMS:
		if owned.has(str(it["id"])):
			total += float(it.get("def", 0.0))
	return total

# 剧毒 debuff 时 有效攻击 (跨场 -15%, 持续 2 场; 只读 展示/战斗 用)
func player_atk_effective() -> float:
	if poison_battles > 0:
		return player_atk() * TOWER_POISON_ATK_MULT
	return player_atk()

# 战力 汇总 (UI 战力对比/顶栏展示用; 只读)
func combat_summary() -> Dictionary:
	return {
		"atk": player_atk(),
		"def": player_def(),
		"atk_eff": player_atk_effective(),
		"poison": poison_battles,
		"progress": tower_power_progress(),
	}

# ================= M5-2: 爬塔 战斗 (即时判定, 无死亡, 可无限重试) =================
# 镇妖塔 当前 可挑战 层 (已通关 = 守塔模式 反复打 1000 层 Boss)
func fixed_challenge_floor() -> int:
	if tower_fixed_clear:
		return 1000  # 守塔模式: 反复挑战 最终 Boss
	return tower_fixed_floor + 1

# 镇妖塔 指定层 怪物 基础 记录 (数据驱动, 读 落表; 越界 = 空 dict)
func get_fixed_floor(floor: int) -> Dictionary:
	if floor < 1 or floor > 1000:
		return {}
	var rec: Variant = tower_floor_by_idx.get(floor, {})
	return rec if typeof(rec) == TYPE_DICTIONARY else {}

# 登天梯 指定层 怪物 记录 (无上限, 按 公式 + 确定性 怪物种 生成, 不占 层表)
# 普通层: 120 种 轮转 (floor 取模, 确定性); 每 10 层 精英 x3; 每 100 层 里程碑 Boss x10
func get_endless_floor(floor: int) -> Dictionary:
	if floor < 1:
		return {}
	var fml: Dictionary = tower_endless.get("formulas", {})
	var hp_f: Array = fml.get("hp", [5.0, 1.06])
	var atk_f: Array = fml.get("atk", [2.0, 1.06])
	var def_f: Array = fml.get("def", [1.0, 1.04])
	var st_f: Array = fml.get("stone", [10.0, 1.06])
	var base_hp := float(hp_f[0]) * pow(float(hp_f[1]), float(floor))
	var base_atk := float(atk_f[0]) * pow(float(atk_f[1]), float(floor))
	var base_def := float(def_f[0]) * pow(float(def_f[1]), float(floor))
	var reward_stone := float(st_f[0]) * pow(float(st_f[1]), float(floor))
	var is_elite := (floor % 10 == 0) and (floor % 100 != 0)
	var is_boss := (floor % 100 == 0)
	var struct := 1.0
	var reward_mult := 1
	var name := ""
	var traits: Array = []
	var species_id := ""
	if _endless_species.size() > 0:
		var sp: Dictionary = _endless_species[int((floor - 1) % _endless_species.size())]
		species_id = str(sp.get("id", ""))
		for t in sp.get("traits", []):
			traits.append(str(t))
		var bias_hp := float(sp.get("b_hp", 1.0))
		var bias_atk := float(sp.get("b_atk", 1.0))
		var bias_def := float(sp.get("b_def", 1.0))
		if is_boss:
			struct = ENDLESS_BOSS_MULT
			reward_mult = 5
			# 里程碑 Boss: 20 小 Boss 池 轮转 (确定性), 名字/特性 取 Boss 记录, 无 偏向
			var boss: Dictionary = _endless_small_bosses[int((floor / 100 - 1) % _endless_small_bosses.size())] if _endless_small_bosses.size() > 0 else {}
			if not boss.is_empty():
				name = str(boss.get("name", ""))
				traits.clear()
				for t in boss.get("traits", []):
					traits.append(str(t))
				species_id = str(boss.get("id", ""))
				bias_hp = 1.0
				bias_atk = 1.0
				bias_def = 1.0
		elif is_elite:
			struct = ENDLESS_ELITE_MULT
			reward_mult = 2
			# 精英: 追加 1 个 确定性 特性 (层数 取模 特性表, 不重复)
			var extra: String = str(_trait_ids[int(floor % _trait_ids.size())]) if _trait_ids.size() > 0 else ""
			if extra != "" and extra not in traits:
				traits.append(extra)
		if name == "":
			name = str(sp.get("name", ""))
			if is_elite:
				name = "魔化·" + name
		# 偏向 与 结构 相乘 (与 镇妖塔 落表 同口径: 基础 x 结构 x 偏向)
		base_hp *= bias_hp
		base_atk *= bias_atk
		base_def *= bias_def
	return {
		"floor": floor, "name": name, "species": species_id, "traits": traits,
		"is_elite": is_elite, "boss_type": ("boss" if is_boss else ""),
		"b_hp": 1.0, "b_atk": 1.0, "b_def": 1.0,
		"base_hp": base_hp, "base_atk": base_atk, "base_def": base_def,
		"hp": base_hp * struct, "atk": base_atk * struct, "def": base_def * struct,
		"reward_stone": reward_stone * reward_mult, "reward_mult": reward_mult,
	}

# 怪物 有效 属性 (层数公式 x 结构 x 偏向 x 特性倍率; 特性 mult 逐条 应用)
# 返回 {hp, atk, def, stone, name, traits, is_elite, boss_type, reward_mult, poison}
func tower_monster_stats(rec: Dictionary) -> Dictionary:
	var hp := float(rec.get("hp", 0.0))
	var atk := float(rec.get("atk", 0.0))
	var dfn := float(rec.get("def", 0.0))
	var stone := float(rec.get("reward_stone", 0.0))
	var has_poison := false
	var tlist: Array = rec.get("traits", [])
	for tid in tlist:
		var td: Dictionary = trait_by_id.get(str(tid), {})
		if td.is_empty():
			continue
		var mult: Dictionary = td.get("mult", {})
		hp *= float(mult.get("hp", 1.0))
		atk *= float(mult.get("atk", 1.0))
		dfn *= float(mult.get("def", 1.0))
		dfn += float(mult.get("shield_add", 0.0))
		stone *= float(mult.get("stone", 1.0))
		if mult.has("atk_debuff"):
			has_poison = true
	# 天怨: 仅无尽塔生效 (层数 未知 时 =1; 由 调用方 通过 rec 传 floor 已含 结构, 此处 保守 不放大)
	return {
		"hp": hp, "atk": atk, "def": dfn, "stone": stone,
		"name": str(rec.get("name", "")), "traits": tlist,
		"is_elite": bool(rec.get("is_elite", false)),
		"boss_type": str(rec.get("boss_type", "")),
		"reward_mult": int(rec.get("reward_mult", 1)),
		"poison": has_poison,
		"floor": int(rec.get("floor", 0)),
	}

# 战斗判定: 即时, 无死亡, 可无限重试。win = 玩家 有效 atk >= 怪 atk x 0.85
# tower = "fixed" (镇妖塔) / "endless" (登天梯); roll 仅 影响 展示 伤害浮动 (不改变 胜负), 可注入 确定性
func try_tower_challenge(tower: String, roll: float = -1.0) -> Dictionary:
	var rec: Dictionary = {}
	var next_floor := 0
	if tower == "fixed":
		next_floor = fixed_challenge_floor()
		rec = get_fixed_floor(next_floor)
	elif tower == "endless":
		next_floor = tower_endless_floor
		rec = get_endless_floor(next_floor)
	else:
		return {"win": false, "reason": "未知塔 %s" % tower, "tower": tower, "floor": 0}
	if rec.is_empty():
		return {"win": false, "reason": "塔 数据 未加载", "tower": tower, "floor": next_floor}
	var mon: Dictionary = tower_monster_stats(rec)
	var m_atk: float = float(mon["atk"])
	var m_def: float = float(mon["def"])
	var m_hp: float = float(mon["hp"])
	var p_atk: float = player_atk_effective()  # 含 剧毒 debuff
	var p_def: float = player_def()
	# 胜负 判定 (确定性, 与 roll 无关): atk >= mon_atk x 0.85
	var win := p_atk >= m_atk * TOWER_WIN_RATIO
	# 展示: 对怪 伤害 / 回合数 (roll 浮动 0.9~1.1, 仅展示, 不改变 胜负)
	if roll < 0.0:
		roll = randf()
	var dmg := maxf(1.0, p_atk - m_def) * (0.9 + 0.2 * roll)
	var rounds := int(ceil(m_hp / dmg)) if dmg > 0.0 else 999999
	# 结算 (胜 = 推进 + 灵石; 败 = 停留 本层 无 消耗, 无 惩罚)
	var reward_stone := 0.0
	var new_floor := next_floor
	var clear := tower_fixed_clear
	var daily_bonus := 0.0
	var clear_reward_stone := 0.0
	var daily_date_today := _today_str()
	# M6-2: 词缀掉落 (胜利 结算; 来源 由 层 结构 决定: 里程碑 Boss=milestone, Boss=boss,
	# 精英=elite, 普通=normal; rolls 7 个 确定性 种子 随机 注入 (roll 已生成 时 复用))
	var affix_drops: Array = []
	if win:
		reward_stone = float(mon["stone"])
		stones += reward_stone
		# 剧毒: 战胜 后 玩家 atk -15%, 持续 2 场 (可 刷新)
		if bool(mon["poison"]):
			poison_battles = TOWER_POISON_BATTLES
		# M6-2: 词缀掉落 结算 (背包满 时 普通品质 自动入料, 高品质 拒绝 不 入包)
		var drop_src := "normal"
		if bool(mon["is_elite"]):
			drop_src = "elite"
		elif str(mon["boss_type"]) != "":
			drop_src = "milestone" if tower == "endless" else "boss"
		var dr: Array = []
		for i in 7:
			dr.append(randf())
		affix_drops = affix_roll_drop(drop_src, next_floor, dr)
		_stat_inc("affix_drop", float(affix_drops.size()))
		if tower == "fixed":
			if next_floor < 1000:
				tower_fixed_floor = max(tower_fixed_floor, next_floor)
				new_floor = next_floor + 1
			else:
				new_floor = 1000
				if not clear:
					clear = true  # 1000 层 Boss 首次 通过 -> 通关
					tower_fixed_clear = true
					# M5-4: 通关 一次性 大奖 (称号「镇妖塔·通关者」+ 灵石 大奖 + 永久 atk/def 增益;
					# 发放 以 本局 首次 通关 事件 为准 (reward_got 防 重放), 守塔 模式 不再 重复 发放)
					if not tower_clear_reward_got:
						tower_clear_reward_got = true
						clear_reward_stone = TOWER_CLEAR_BONUS_STONE
						stones += clear_reward_stone
		elif tower == "endless":
			# 口径: tower_endless_best = 历史 最高 已 通关 层; tower_endless_floor = 当前 待挑战 层 (最高+1)
			# 本胜 通关 next_floor 层 -> 最高纪录 更新 为 next_floor, 待挑战 推进 到 next_floor+1
			var was_best := next_floor > tower_endless_best
			tower_endless_best = maxi(tower_endless_best, next_floor)
			tower_endless_floor = next_floor + 1
			new_floor = next_floor + 1
			# 每日首胜: 当天 首次 通过 新纪录 层 给 额外 灵石 (鼓励 每日上线)
			# 口径: 本胜 创 新纪录 且 今日 尚未 发放过 首胜 奖励 -> 发 0.5 x 本层 灵石
			if was_best and tower_daily_date != daily_date_today:
				tower_daily_date = daily_date_today
				daily_bonus = reward_stone * 0.5
				stones += daily_bonus
				tower_daily_bonus_stones += daily_bonus
		_stat_inc("tower_win")
	# 剧毒 跨场 debuff: 每 场 战斗 末 递减 1 (胜 本层 剧毒 怪 时 本回合 已 刷新 为 2, 随后 再 递减 1 -> 下回合 仍 处 中毒;
	# 无 剧毒 怪 时 仅 递减 已 持续 的 debuff; poison_battles 0 时 无副作用)
	if poison_battles > 0:
		poison_battles -= 1
	return {
		"win": win, "tower": tower, "floor": next_floor, "new_floor": new_floor,
		"monster": str(mon["name"]), "traits": mon["traits"],
		"is_elite": bool(mon["is_elite"]), "boss_type": str(mon["boss_type"]),
		"mon_hp": m_hp, "mon_atk": m_atk, "mon_def": m_def,
		"player_atk": p_atk, "player_def": p_def,
		"dmg": dmg, "rounds": rounds, "reward_stone": reward_stone,
		"clear_reward_stone": clear_reward_stone,
		"daily_bonus": daily_bonus, "clear": clear, "poison": bool(mon["poison"]),
		"poison_battles": poison_battles, "affix_drops": affix_drops,
		"reason": ("胜" if win else "败: 战力 不足, 停留 本层 (无 惩罚, 可 重试)"),
	}

func _today_str() -> String:
	var t := Time.get_unix_time_from_system()
	var tm := Time.get_datetime_dict_from_unix_time(t)
	return "%04d-%02d-%02d" % [int(tm.year), int(tm.month), int(tm.day)]

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
	return breakthrough_cost_at(realm_idx, layer)

# 指定境界/层的突破消耗 (打磨-33: 阶梯 ETA 路线按此估算, 不改动当前状态)
func breakthrough_cost_at(r: int, l: int) -> float:
	return 10.0 * pow(3.0, float(r)) * float(l)

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

# 打磨-66: 本次离线收益 启动浮动 文案 (load_game 结算后调用; 不足 1 分钟 或 无档 返回空串)
# 口径: "☾ 离线 X, 收获 灵气/道行 A · 灵石 B ☾" (与 offline_msg 同源, 飞升后主资源=道行). 只读无副作用.
func offline_float_text() -> String:
	if _offline_sec < 60.0 or (_offline_qi <= 0.0 and _offline_stone <= 0.0):
		return ""
	var res_name: String = "道行" if ascended else "灵气"
	return "☾ 离线 %s, 收获 %s %s · 灵石 %s ☾" % [
		fmt_time(_offline_sec), res_name, fmt(_offline_qi), fmt(_offline_stone)]

# ================= 打磨-14: 修行统计 (累计时长/突破/道行/神通/法器/装备) =================

func _stat_inc(key: String, amount: float = 1.0) -> void:
	stats[key] = float(stats.get(key, 0.0)) + amount

func _load_stats(v: Variant) -> void:
	stats = {}
	if typeof(v) == TYPE_DICTIONARY:
		for k in v:
			stats[str(k)] = float(v[k])
	# 兜底键齐全 (旧档缺失不影响读取)
	for k in ["play_sec", "break_ok", "break_fail", "dao_ok", "skill_use", "item_buy", "equip_buy", "tower_win", "affix_drop", "affix_equip", "affix_decompose"]:
		if not stats.has(k):
			stats[k] = 0.0

# 统计文本 (修行页展示)
func stats_text() -> String:
	return "修行 %s · 突破 %d 次 · 道行精进 %d 次 · 神通 %d 次 · 法器 %d 件 · 装备 %d 件 · 爬塔胜 %d 次" % [
		fmt_stats_time(float(stats.get("play_sec", 0.0))),
		int(stats.get("break_ok", 0.0)), int(stats.get("dao_ok", 0.0)),
		int(stats.get("skill_use", 0.0)), int(stats.get("item_buy", 0.0)),
		int(stats.get("equip_buy", 0.0)), int(stats.get("tower_win", 0.0))]

# 打磨-77: 挂机时长 只读 接口 (顶栏 常显 用; 复用 stats.play_sec + fmt_stats_time 口径,
# 只读 不 改 状态/存档/统计; 返回 空串 时 UI 隐藏 标签 避免 首帧 空文本 占位)
func play_time_text() -> String:
	var sec: float = float(stats.get("play_sec", 0.0))
	if sec <= 0.0:
		return ""
	return "⏳ %s" % fmt_stats_time(sec)

# 打磨-78: 顶栏 主资源速率 只读 接口 (未飞升=灵气/秒, 飞升后=道行/秒; 与 修行页 灵气速率 同口径
# = 境界基础 x 道行阶段 x 法器连乘 x 功法装备 1+Σ; 速率<=0 返回 空串 供 UI 隐藏 标签,
# 只读 不 改 状态/存档/统计)
func primary_rate_text() -> String:
	var r: float = qi_per_sec()
	if r <= 0.0:
		return ""
	return "+%s/秒" % fmt(r)

# 打磨-79: 顶栏 灵石速率 只读 接口 (与 修行页 灵石速率 行 同 口径
# = 基础1 x 境界倍率 x (1 + 灵石/全面 被动 + 装备加成); 法器连乘 不影响 灵石;
# 速率<=0 返回 空串 供 UI 隐藏 标签, 只读 不 改 状态/存档/统计)
func stone_rate_text() -> String:
	var r: float = stone_per_sec()
	if r <= 0.0:
		return ""
	return "+%s/秒" % fmt(r)

# 打磨-83: 顶栏 挂机时长 悬停 离线收益 预估 tooltip (只读, 复用 offline_gain/offline_rate 口径;
# 玩家 悬停 顶栏 ⏳ 挂机时长 即知 离线 X 小时 可攒 多少 主资源/灵石, 不 切 修行页;
# 口径: 基础 效率 50% + 功法/装备 加成, 上限 8 小时, 飞升后 主资源=道行; 纯 文本 无 副作用)
func offline_preview_tip() -> String:
	var r: float = offline_rate()
	var res_name: String = "道行" if ascended else "灵气"
	var h1 := offline_gain(3600.0)
	var h4 := offline_gain(4.0 * 3600.0)
	var h8 := offline_gain(8.0 * 3600.0)
	return ("离线收益 预估 (%s, 基础 %0.0f%% + 功法/装备 加成, 上限 8 小时):\n"
		+ "· 离线 1 小时 ≈ %s · 灵石 %s\n"
		+ "· 离线 4 小时 ≈ %s · 灵石 %s\n"
		+ "· 离线 8 小时 (上限) ≈ %s · 灵石 %s") % [
		res_name, r * 100.0,
		fmt(float(h1["qi"])), fmt(float(h1["stone"])),
		fmt(float(h4["qi"])), fmt(float(h4["stone"])),
		fmt(float(h8["qi"])), fmt(float(h8["stone"]))]

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
# M5-2: 爬塔 层数 成就 -> 目标 层数 (镇妖塔 fixed / 登天梯 endless 最高纪录)
const ACH_TOWER_FIXED := {"tower_100": 100, "tower_500": 500}
const ACH_TOWER_ENDLESS := {"endless_100": 100, "endless_500": 500, "endless_1000": 1000, "endless_5000": 5000}

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
		# M5-2: 爬塔 成就 (镇妖塔 层数/通关 + 登天梯 层数 + 首通)
		"first_tower":
			return tower_fixed_floor >= 1 or tower_endless_best >= 1
		"tower_clear":
			return tower_fixed_clear
		# M6-3: DIY 装备 成就 (首件 3 槽装满/传说 首获/共鸣 首触发/集齐 120)
		"diy_first":
			return _affix_any_diy_full()
		"affix_legend":
			return _affix_any_tier_seen(4)
		"resonance_first":
			return affix_resonance_active()
		"affix_120":
			return seen_affixes.size() >= affix_ids.size()
		_:
			if ACH_TOWER_FIXED.has(id):
				return tower_fixed_floor >= int(ACH_TOWER_FIXED[id])
			if ACH_TOWER_ENDLESS.has(id):
				return tower_endless_best >= int(ACH_TOWER_ENDLESS[id])
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
		# M5-2: 爬塔 成就 进度 (镇妖塔 层数 / 通关 / 登天梯 层数 / 首通)
		"first_tower":
			return "1/1" if (tower_fixed_floor >= 1 or tower_endless_best >= 1) else "0/1"
		"tower_clear":
			return "%d/1000" % mini(tower_fixed_floor, 1000) if not tower_fixed_clear else "1000/1000"
		# M6-3: DIY 装备 成就 进度
		"diy_first":
			return "%d/1" % int(_affix_any_diy_full())
		"affix_legend":
			return "%d/1" % int(_affix_any_tier_seen(4))
		"resonance_first":
			var m63_best := 0
			for t in resonance_count():
				m63_best = maxi(m63_best, int(resonance_count()[t]))
			return "%d/3" % mini(m63_best, 3)
		"affix_120":
			return "%d/%d" % [seen_affixes.size(), affix_ids.size()]
		_:
			if ACH_TOWER_FIXED.has(id):
				var need: int = int(ACH_TOWER_FIXED[id])
				return "%d/%d" % [mini(tower_fixed_floor, need), need]
			if ACH_TOWER_ENDLESS.has(id):
				var need: int = int(ACH_TOWER_ENDLESS[id])
				return "%d/%d" % [mini(tower_endless_best, need), need]
			var need: int = ACH_REALM_IDX.get(id, -1)
			if need >= 0:
				return "当前 %s / 目标 %s" % [realm_name(), REALMS[need]["name"]]
	return ""

# 打磨-39: 未解锁成就进度比例 0..1 (只读估算, 供成就页排序; 口径与 ach_progress 一致, 未知 id = 0)
func ach_progress_ratio(id: String) -> float:
	match id:
		"ascend_immortal":
			return 1.0 if ascended else 0.0
		"first_break":
			return 1.0 if (realm_idx > 0 or layer > 1) else 0.0
		"first_item":
			return 1.0 if owned.size() >= 1 else 0.0
		"skill_10":
			return minf(float(learned.size()), 10.0) / 10.0
		"skill_50":
			return minf(float(learned.size()), 50.0) / 50.0
		"equip_first":
			return 1.0 if owned_eq.size() >= 1 else 0.0
		"equip_10":
			return minf(float(owned_eq.size()), 10.0) / 10.0
		"rich_100k":
			return minf(stones, 100000.0) / 100000.0
		"dao_zuzi":
			if not ascended:
				return 0.0
			return float(dao_level) / float(IMMORTAL_REALMS.size() - 1)
		# M5-2: 爬塔 成就 进度比例 (镇妖塔 层数/通关 / 登天梯 层数 / 首通)
		"first_tower":
			return 1.0 if (tower_fixed_floor >= 1 or tower_endless_best >= 1) else 0.0
		"tower_clear":
			return 1.0 if tower_fixed_clear else minf(float(tower_fixed_floor), 1000.0) / 1000.0
		# M6-3: DIY 装备 成就 进度比例
		"diy_first":
			return 1.0 if _affix_any_diy_full() else 0.0
		"affix_legend":
			return 1.0 if _affix_any_tier_seen(4) else 0.0
		"resonance_first":
			if affix_resonance_active():
				return 1.0
			var m63_best2 := 0
			for t in resonance_count():
				m63_best2 = maxi(m63_best2, int(resonance_count()[t]))
			return minf(float(m63_best2), 3.0) / 3.0
		"affix_120":
			return minf(float(seen_affixes.size()), float(affix_ids.size())) / float(affix_ids.size())
		_:
			if ACH_TOWER_FIXED.has(id):
				var need: int = int(ACH_TOWER_FIXED[id])
				return minf(float(tower_fixed_floor), float(need)) / float(need)
			if ACH_TOWER_ENDLESS.has(id):
				var need: int = int(ACH_TOWER_ENDLESS[id])
				return minf(float(tower_endless_best), float(need)) / float(need)
			var need: int = ACH_REALM_IDX.get(id, -1)
			if need < 0:
				return 0.0
			return minf(float(realm_idx), float(need)) / float(need)
	return 0.0

# 打磨-39: 成就页排序 (已解锁在前 / 未解锁按进度比例降序, 比例相同按 id 升序稳定)
# 排序键 [未解锁 0/1, -进度比例, id], sort_custom 升序比较
func ach_sort_cmp(a: String, b: String) -> bool:
	var da: int = int(not ach_done.has(a))
	var db: int = int(not ach_done.has(b))
	if da != db:
		return da < db
	if da == 0:  # 已解锁段: 按 id 稳定
		return a < b
	var ra: float = ach_progress_ratio(a)
	var rb: float = ach_progress_ratio(b)
	if ra != rb:
		return ra > rb
	return a < b

func ach_sort_order() -> Array:
	var out: Array = []
	for id in ach_ids:
		out.append(id)
	out.sort_custom(ach_sort_cmp)
	return out

# 打磨-17: 自 prev 以来新解锁的成就 (UI 浮动提示用; 存档带来的旧解锁不当作"新")
# prev 用非类型 Array: 调用方 (含 -s 脚本/存档恢复) 可能传入未类型化数组, 类型化参数会运行时报错
func new_ach_since(prev: Array) -> Array[String]:
	var out: Array[String] = []
	for id in ach_done:
		if not prev.has(id):
			out.append(id)
	return out

# ================= 详情提示 (打磨-9: 行 tooltip) =================

# 打磨-54: 主动神通 爆发预览 (当前灵气速率 x 爆发秒数; 飞升后口径=道行)
# 只读预览, 不改状态; 未知 id / 非主动 返回 ""; 供 技能行 内联标签 + tooltip 复用
func skill_burst_preview(id: String) -> String:
	var s: Dictionary = skill_by_id.get(id, {})
	if s.is_empty() or str(s.get("type", "")) != "active":
		return ""
	return "爆发 +%s %s (当前 %s/秒 x %d 秒)" % [
		fmt(float(qi_per_sec()) * float(s["value"])), primary_res_name(),
		fmt(float(qi_per_sec())), int(s["value"])]

# 技能详情 (tooltip: 名称/品质/类型/效果/领悟条件/状态)
func skill_detail(id: String) -> String:
	var s: Dictionary = skill_by_id.get(id, {})
	if s.is_empty():
		return ""
	var type_cn := "主动·神通" if str(s["type"]) == "active" else "被动·功法"
	var tip := "「%s」 %s · %s\n%s" % [s["name"], s["tier_name"], type_cn, s["desc"]]
	if str(s["type"]) == "active":
		# 打磨-54: 爆发预览行 (与行内联标签同文本; 数值随 速率/境界/飞升 变化, 刷新口径见 main.gd _refresh)
		tip += "\n" + skill_burst_preview(id)
		tip += "\n(飞升后: 爆发转为获得道行)"
	var r: Dictionary = REALMS[int(s["unlock_realm"])]
	tip += "\n领悟条件: %s 第%d层" % [r["name"], int(s["unlock_layer"])]
	tip += "\n状态: %s" % ("已领悟" if learned.has(id) else "未领悟")
	return tip

# 打磨-9: 装备详情 (tooltip: 名称/品质/部位/属性/价格/状态/换装对比)
func equip_detail(id: String) -> String:
	var e: Dictionary = equip_by_id.get(id, {})
	if e.is_empty():
		return ""
	var tip := "「%s」 %s · %s\n%s\n灵石 %s" % [e["name"], e["tier_name"], e["slot_name"], e["desc"], fmt(float(e["cost"]))]
	# M6-2: 词缀槽 行 (已装 词缀 明细; 与 affix_load_text 同源)
	tip += "\n" + affix_load_text(id)
	# M6-3: 评分 (装备 基础 6 池 + 已装 词缀 6 池; 列表/对比 排序 口径)
	tip += "\n评分 %s" % fmt(equip_score(id))
	if affix_slots_used(id) > 0:
		tip += "\n" + resonance_text()
	if str(equipped.get(str(e["slot"]), "")) == id:
		tip += "\n状态: 已穿戴"
	elif owned_eq.has(id):
		tip += "\n状态: 已拥有(未穿戴)"
	else:
		tip += "\n状态: 未拥有"
	# 打磨-25: 换装对比 (该部位已穿其它装备时, 穿上本件的主属性变化)
	var sw: Dictionary = equip_swap_hint(id)
	if str(sw["text"]) != "":
		tip += "\n换装对比: %s" % str(sw["text"])
	return tip

# 法器详情 (tooltip: 名称/描述/价格/增幅/状态/属性构成对比 打磨-51)
func item_detail(item_id: String) -> String:
	for it in ITEMS:
		if str(it["id"]) == item_id:
			var tip := "「%s」\n%s\n灵石 %s\n灵气速率 x%.1f" % [it["name"], it["desc"], fmt(float(it["cost"])), float(it["boost"])]
			tip += "\n状态: %s" % ("已拥有" if owned.has(item_id) else "未拥有")
			tip += "\n" + item_attr_line(item_id)  # 打磨-51: 属性构成 (购买后数值预览, 刷新口径与 _refresh 一致)
			return tip
	return ""

# ---------- 打磨-51: 法器区属性构成 tooltip ----------

# 灵气速率构成文本: 当前灵气/秒 = 境界基础 x 功法装备 x 法器连乘 x 飞升道行倍率
# (未飞升时 飞升段 x1.0 省略; 供 法器行 tooltip / 一键购买 浮动文案 复用)
func item_qi_compose() -> String:
	var base: float = QI_MULT[realm_idx]
	if ascended:
		base *= immortal_mult()
	var parts := "境界基础 x%.1f" % base
	if ascended:
		parts += " x 飞升x%.0f" % immortal_mult()
	parts += " x 功法装备 x%.2f x 法器连乘 x%.1f" % [qi_mult_skill_equip(), item_boost()]
	parts += " = 当前灵气 %s/秒" % fmt(qi_per_sec())
	return parts

# 法器行 tooltip 属性构成行: 未拥有 = 当前贡献(法器连乘未含本件) + 购买后预览; 已拥有 = 当前构成
# 只读: 不改状态; 未拥有时 购买后 = 当前 x 本件boost (与 qi_per_sec 连乘口径一致)
func item_attr_line(item_id: String) -> String:
	var found: Dictionary = {}
	for it in ITEMS:
		if str(it["id"]) == item_id:
			found = it
			break
	if found.is_empty():
		return ""
	var b: float = float(found["boost"])
	if owned.has(item_id):
		return "属性构成: " + item_qi_compose()
	var base: float = QI_MULT[realm_idx]
	if ascended:
		base *= immortal_mult()
	var mult: float = base * qi_mult_skill_equip()
	var cur: float = mult * item_boost()   # 未拥有: 当前 法器连乘 未含本件
	var aft: float = cur * b
	return "当前贡献: 法器连乘 x%.1f = 灵气 %s/秒" % [item_boost(), fmt(cur)] + \
		"\n购买后: 法器连乘 x%.1f = 灵气 %s/秒 (x%.1f)" % [item_boost() * b, fmt(aft), b]

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

# ---------- 打磨-28: 收集进度一览 (成就页顶栏, 全局收集目标) ----------

# 全局收集进度: 技能/装备/法器/成就 各自 已收集/总量 (各条目只收集一次, 计数只增不减)
func collect_summary() -> Dictionary:
	return {
		"skill": {"got": learned.size(), "total": skill_ids.size()},
		"equip": {"got": owned_eq.size(), "total": equip_ids.size()},
		"item": {"got": owned.size(), "total": ITEMS.size()},
		"ach": {"got": ach_done.size(), "total": ach_ids.size()},
	}

# 收集一览文本 (成就页展示; 某类收集变化才变)
func collect_summary_text() -> String:
	var c := collect_summary()
	var g_all := 0
	var t_all := 0
	for k in c:
		g_all += int(c[k]["got"])
		t_all += int(c[k]["total"])
	return "收集进度  技能 %d/%d · 装备 %d/%d · 法器 %d/%d · 成就 %d/%d (总 %d/%d)" % [
		int(c["skill"]["got"]), int(c["skill"]["total"]),
		int(c["equip"]["got"]), int(c["equip"]["total"]),
		int(c["item"]["got"]), int(c["item"]["total"]),
		int(c["ach"]["got"]), int(c["ach"]["total"]),
		g_all, t_all]

# ================= 技能 =================

# 打磨-20: 技能品质名 (凡品~仙品 共 6 档, 供筛选按钮/展示用)
func skill_tier_name(t: int) -> String:
	return ["凡品", "灵品", "玄品", "地品", "天品", "仙品"][clampi(t, 0, 5)]

# 打磨-21: 装备品质名 (凡品~神品 共 7 档, 供筛选按钮/展示用)
func equip_tier_name(t: int) -> String:
	return ["凡品", "灵品", "玄品", "地品", "天品", "仙品", "神品"][clampi(t, 0, 6)]

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

# 打磨-23: 一键领悟 — 批量学习全部 未学 且 境界足够 的技能 (可叠加技能页筛选)
# cat = 类别 id ("" = 全部类别), tier = 品质索引 (-1 = 全部品质)
func learn_all_available(cat: String = "", tier: int = -1) -> Dictionary:
	var n := 0
	for id in skill_ids:
		if learned.has(id):
			continue
		var s: Dictionary = skill_by_id.get(id, {})
		if s.is_empty():
			continue
		if cat != "" and str(s["category"]) != cat:
			continue
		if tier >= 0 and int(s["tier"]) != tier:
			continue
		if not can_learn(id):
			continue
		learned.append(id)
		n += 1
	return {"count": n}

# 打磨-27: 筛选范围内可学技能数 (未学+境界足够+匹配 类别/品质 筛选)
# 口径与 learn_all_available(cat, tier) 完全一致, 供技能页"一键领悟"按钮文案
# (按钮点击只学筛选内的技能, 计数显示全局数会误导; 与 一键购买/一键最佳 口径统一)
func learn_available_count(cat: String = "", tier: int = -1) -> int:
	var n := 0
	for id in skill_ids:
		if learned.has(id):
			continue
		var s: Dictionary = skill_by_id.get(id, {})
		if s.is_empty():
			continue
		if cat != "" and str(s["category"]) != cat:
			continue
		if tier >= 0 and int(s["tier"]) != tier:
			continue
		if can_learn(id):
			n += 1
	return n

# 打磨-38: "只看可学"筛选显示口径 — 已学技能恒显示(排最前), 未学的须 境界/层 足够
# 供技能页"只看可学"开关注释用, 与 UI _apply_skill_filter 过滤条件完全一致
func skill_can_learn_display(id: String) -> bool:
	if learned.has(id):
		return true
	var s: Dictionary = skill_by_id.get(id, {})
	if s.is_empty():
		return false
	return can_learn(id)

# 打磨-38: 筛选范围内 可学(未学+境界足够) 技能显示数 (与 skill_can_learn_display 口径一致)
# cat = 类别 id ("" = 全部类别), tier = 品质索引 (-1 = 全部品质)
func learnable_display_count(cat: String = "", tier: int = -1) -> int:
	var n := 0
	for id in skill_ids:
		if cat != "" and str(skill_by_id[id]["category"]) != cat:
			continue
		if tier >= 0 and int(skill_by_id[id]["tier"]) != tier:
			continue
		if skill_can_learn_display(id):
			n += 1
	return n

# 打磨-56: 筛选范围内 可学主动神通 数 (未学+境界足够+匹配 类别/品质 筛选, 仅 type=="active")
# 口径与 learn_all_available(cat, tier) 完全一致, 仅多一道 type 过滤 (与 打磨-27 计数口径对齐,
# 供技能页"一键神通"按钮文案; 24 个主动神通混在 96 被动里逐个找成本高, 此按钮一次补齐)
func active_learn_available_count(cat: String = "", tier: int = -1) -> int:
	var n := 0
	for id in skill_ids:
		if learned.has(id):
			continue
		var s: Dictionary = skill_by_id.get(id, {})
		if s.is_empty() or str(s.get("type", "")) != "active":
			continue
		if cat != "" and str(s["category"]) != cat:
			continue
		if tier >= 0 and int(s["tier"]) != tier:
			continue
		if can_learn(id):
			n += 1
	return n

# 打磨-56: 一键神通 — 批量学习 筛选范围内 未学+境界足够 的 主动神通 (仅 type=="active")
# 复用 learn_skill 同口径 (learned.append + can_learn 门槛), 无 统计/存档 新副作用;
# 变更 0 (无新神通) 再调 = 0 幂等; 飞升后 主动神通 爆发口径 道行 不变, 亦作 飞升后 补齐入口
func learn_all_active(cat: String = "", tier: int = -1) -> Dictionary:
	var n := 0
	for id in skill_ids:
		if learned.has(id):
			continue
		var s: Dictionary = skill_by_id.get(id, {})
		if s.is_empty() or str(s.get("type", "")) != "active":
			continue
		if cat != "" and str(s["category"]) != cat:
			continue
		if tier >= 0 and int(s["tier"]) != tier:
			continue
		if not can_learn(id):
			continue
		learned.append(id)
		n += 1
	return {"count": n}

func active_ready(id: String) -> bool:
	return _active_cd.get(id, 0.0) <= 0.0

func active_cd_left(id: String) -> int:
	return int(ceil(_active_cd.get(id, 0.0)))

# 打磨-58: 冷却进度 (0..1, 剩余/总冷却) — 未学/非主动/已就绪=0.0, 冷却中=剩余比例
# (只读, 不改动 状态/存档/统计; 神通行 冷却进度条 用, 与 打磨-57 就绪事件 同 _active_cd 口径)
func active_cd_ratio(id: String) -> float:
	var rem: float = _active_cd.get(id, 0.0)
	if rem <= 0.0:
		return 0.0
	var s: Dictionary = skill_by_id.get(id, {})
	var cd: float = float(s.get("cooldown", 0.0))
	if cd <= 0.0:
		return 0.0
	return clampf(rem / cd, 0.0, 1.0)

# 打磨-57: 神通冷却推进 (从 _process 拆出, 供自测手动驱动): 逐 id 扣减剩余冷却,
# 归零即移除并推入 ready_events (冷却完毕转就绪事件; 只增不改 状态/存档/统计)
func _tick_active_cd(delta: float) -> void:
	for id in _active_cd.keys():
		_active_cd[id] = maxf(0.0, _active_cd[id] - delta)
		if _active_cd[id] <= 0.0:
			_active_cd.erase(id)
			ready_events.append(str(id))

# 打磨-57: UI 每帧消费就绪事件 (取出即清空, 幂等; 返回的 id 恒为 已学主动神通)
# 注意: Array[String] 是引用类型, `var out = ready_events` 只是别名 (clear 会连带清空 out),
# 须逐项拷贝到新数组再清源
func drain_ready_events() -> Array[String]:
	var out: Array[String] = []
	for id in ready_events:
		out.append(id)
	ready_events.clear()
	return out

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

# 打磨-23: 一键购买 — 按 价格升序 (同价按数据序) 连续购买 买得起 的装备
# (先买便宜的, 灵石花到买不起为止; 槽位空时 buy_equipment 自动穿戴)
func buy_affordable() -> Dictionary:
	var n := 0
	var ids: Array = []
	for id in equip_ids:
		ids.append(id)
	ids.sort_custom(buy_affordable_cmp)
	for id in ids:
		if str(buy_equipment(str(id))).find("购得") >= 0:
			n += 1
	return {"count": n, "bought": n > 0}

func buy_affordable_cmp(a: String, b: String) -> bool:
	var ea: Dictionary = equip_by_id.get(a, {})
	var eb: Dictionary = equip_by_id.get(b, {})
	var ca: float = float(ea.get("cost", INF))
	var cb: float = float(eb.get("cost", INF))
	if ca != cb:
		return ca < cb
	return a < b

func equipped_name(slot: String) -> String:
	var id: String = equipped.get(slot, "")
	if id == "":
		return "(空)"
	var e: Dictionary = equip_by_id.get(id, {})
	return str(e["name"]) if not e.is_empty() else "(空)"

# ---------- 打磨-25: 换装对比提示 (购买/穿戴行显示 替换对象 + 主属性差) ----------

# 指定部位当前穿戴的装备 (无 -> {})
func equipped_at(slot: String) -> Dictionary:
	var id: String = equipped.get(slot, "")
	if id == "":
		return {}
	return equip_by_id.get(id, {})

# 换装对比: 穿上 id 后该部位属性变化
# {"cur": {}, "replace_name": "", "d_qi": 0.0, "d_stone": 0.0, "text": ""}
# text: "" = 槽位空 (纯增益) / "替换 「X」: 灵气+12% 灵石+7%" (负数带负号, 0 省略)
func equip_swap_hint(id: String) -> Dictionary:
	var e: Dictionary = equip_by_id.get(id, {})
	if e.is_empty():
		return {"cur": {}, "replace_name": "", "d_qi": 0.0, "d_stone": 0.0, "text": ""}
	var slot := str(e["slot"])
	var cur: Dictionary = equipped_at(slot)
	if cur.is_empty() or str(cur.get("id", "")) == id:
		return {"cur": cur, "replace_name": "", "d_qi": 0.0, "d_stone": 0.0, "text": ""}
	var dqi: float = (float(e["qi_mult"]) + affix_bonus_for_equipment(id, "qi_mult")) \
		- (float(cur.get("qi_mult", 0.0)) + affix_bonus_for_equipment(str(cur.get("id", "")), "qi_mult"))
	var dst: float = (float(e["stone_mult"]) + affix_bonus_for_equipment(id, "stone_mult")) \
		- (float(cur.get("stone_mult", 0.0)) + affix_bonus_for_equipment(str(cur.get("id", "")), "stone_mult"))
	var parts: Array = []
	if absf(dqi) >= 0.0005:
		parts.append("灵气%s%0.0f%%" % ["+" if dqi > 0.0 else "-", absf(dqi) * 100.0])
	if absf(dst) >= 0.0005:
		parts.append("灵石%s%0.0f%%" % ["+" if dst > 0.0 else "-", absf(dst) * 100.0])
	return {"cur": cur, "replace_name": str(cur.get("name", "")), "d_qi": dqi, "d_stone": dst,
		"text": "替换「%s」: %s" % [str(cur.get("name", "")), ", ".join(parts)]}

# 打磨-22: 装备状态 (0=未拥有 1=已拥有未穿戴 2=已穿戴) — 供装备列表排序
func equip_state(id: String) -> int:
	if not owned_eq.has(id):
		return 0
	var e: Dictionary = equip_by_id.get(id, {})
	if not e.is_empty() and str(equipped.get(str(e["slot"]), "")) == id:
		return 2
	return 1

# 打磨-22: 装备列表排序 (已穿戴 > 已拥有 > 未拥有; 同状态按 部位/品质/变体 数据序)
func equip_sort_order() -> Array:
	var out: Array = []
	for id in equip_ids:
		out.append(id)
	out.sort_custom(equip_sort_cmp)
	return out

func equip_sort_cmp(a: String, b: String) -> bool:
	var sa: int = equip_state(a)
	var sb: int = equip_state(b)
	if sa != sb:
		return sa > sb
	var ea: Dictionary = equip_by_id[a]
	var eb: Dictionary = equip_by_id[b]
	var ia: int = SLOTS.find(str(ea["slot"]))
	var ib: int = SLOTS.find(str(eb["slot"]))
	if ia != ib:
		return ia < ib
	if int(ea["tier"]) != int(eb["tier"]):
		return int(ea["tier"]) < int(eb["tier"])
	return str(a) < str(b)

# ---------- 打磨-26: 一键最佳穿戴 (各槽位自动穿上拥有的最佳件) ----------

# 最佳穿戴排序键: [主属性(灵气+灵石), 突破, 离线, id] (最终按 id 兜底, 确定性)
func _equip_rank_key(id: String) -> Array:
	var e: Dictionary = equip_by_id.get(id, {})
	if e.is_empty():
		return [0.0, 0.0, 0.0, ""]
	return [float(e["qi_mult"]) + float(e["stone_mult"]), float(e.get("bt_chance", 0.0)), float(e.get("offline_rate", 0.0)), str(id)]

# a 是否优于 b (主属性降序, 再突破/离线, 最后 id 小者优先)
func _rank_gt(a: Array, b: Array) -> bool:
	if float(a[0]) != float(b[0]):
		return float(a[0]) > float(b[0])
	if float(a[1]) != float(b[1]):
		return float(a[1]) > float(b[1])
	if float(a[2]) != float(b[2]):
		return float(a[2]) > float(b[2])
	return str(a[3]) < str(b[3])

# 已拥有装备中, 指定部位的最佳 id ("" = 该部位无拥有件)
func equip_best_id(slot: String) -> String:
	var best := ""
	var best_key: Array = []
	for id in owned_eq:
		var e: Dictionary = equip_by_id.get(str(id), {})
		if e.is_empty() or str(e.get("slot", "")) != slot:
			continue
		var k: Array = _equip_rank_key(str(id))
		if best == "" or _rank_gt(k, best_key):
			best = str(id)
			best_key = k
	return best

# 当前穿戴非最佳拥有件的槽位数 (0 = 各槽位均已最佳 / 无拥有件)
func equip_best_pending() -> int:
	var n := 0
	for slot in SLOTS:
		var bid := equip_best_id(slot)
		if bid != "" and str(equipped.get(slot, "")) != bid:
			n += 1
	return n

# 一键最佳穿戴: 各槽位穿上拥有的最佳件; 返回 {count, changed}
func equip_best() -> Dictionary:
	var changed: Array[String] = []
	for slot in SLOTS:
		var bid := equip_best_id(slot)
		if bid != "" and str(equipped.get(slot, "")) != bid:
			equipped[slot] = bid
			changed.append(bid)
	return {"count": changed.size(), "changed": changed}

# ================= 突破 =================

# 打磨-67: 自动突破 (GameData._process 每帧驱动; 自门控于 auto_break 开关, 关闭时直接返回,
# 故可直接调用测试; 资源攒够 自动尝试 突破/道行精进, 每帧至多一次; 突破后资源已低于 下一档
# 阈值, 无热循环; 成功/失败 事件 与 手动按钮 同口径 (浮动/闪烁 由 break_seq 统一驱动);
# 道祖封顶 不触发; 真仙境 顶层 资源够 也 自动 飞升 (口径=try_breakthrough, 飞升后转道行精进))
# roll: 传入 [0,1) 可确定性注入 (自测用), 默认 randf() (同 try_breakthrough 口径)
func _try_auto_break(roll: float = -1.0) -> void:
	if not auto_break:
		return
	if ascended:
		if dao_level >= IMMORTAL_REALMS.size() - 1:
			return
		if dao >= dao_break_cost():
			try_dao_break(roll)
	else:
		if essence >= breakthrough_cost():
			try_breakthrough(roll)

# 打磨-68: 自动购置 (挂机时 灵石 攒够 自动 购入 未拥有 法器/装备 + 自动 最佳换装,
# 与 一键购置/一键购买/一键最佳 同口径; GameData._process 每帧驱动, 自门控于 auto_buy,
# 关闭时直接返回 故可直接调用测试; 每帧 至多一轮: 先 法器 一键口径 (价格升序连买买得起的),
# 再 装备 一键口径 (价格升序连买买得起的, 槽位空自动穿戴), 最后 一键最佳 (各部位换上
# 拥有件中的 主属性最优, 补 首穿非最优 缺口); 本轮 有任何 变更 则 _auto_buy_seq+1
# (UI 可 据 变化刷 底部提示, 无屏幕浮动 防 挂机刷屏); 灵石 花到 买不起 为止,
# 购买后 最便宜未拥有件 恒 买不起, 无热循环; 全拥有+已最佳 时 0 变更 幂等)
func _try_auto_buy() -> void:
	if not auto_buy:
		return
	var items_before: int = owned.size()
	var equip_before: int = owned_eq.size()
	var stones_before: float = stones
	var eq_slots_before: Dictionary = equipped.duplicate(true)
	# 性能门: 最便宜 未拥有 件 (跨 法器+装备) 买不起时 跳过 购买 连买 (避免 每帧 140 件排序),
	# 但仍 执行 一键最佳 (换装 无 灵石 门槛)
	var target68: Dictionary = stone_next_target()
	var can_buy68: bool = not target68.is_empty() and float(target68.get("shortfall", INF)) <= 0.0
	if can_buy68:
		buy_items_affordable()
		buy_affordable()
	var r_best: Dictionary = equip_best()
	var n_items: int = owned.size() - items_before
	var n_equip: int = owned_eq.size() - equip_before
	var n_swap: int = int(r_best.get("count", 0))
	var changed: bool = (n_items > 0 or n_equip > 0 or equipped != eq_slots_before)
	if not changed:
		return
	_auto_buy_seq += 1
	_auto_buy_last_items = n_items
	_auto_buy_last_equip = n_equip
	_auto_buy_last_cost = stones_before - stones
	_auto_buy_last_swap = n_swap

# 打磨-68: 自动购置 上一轮 变更 文案 (只读; seq<=0 [从未触发/读档重置] 返回 "")
# 口径: 有新购 "自动购置 法器 N 件 + 装备 M 件, 花费 X 灵石"; 仅换装 "自动最佳换装 N 件"
func auto_buy_last_text() -> String:
	if _auto_buy_seq <= 0:
		return ""
	var parts: Array = []
	if _auto_buy_last_items > 0:
		parts.append("法器 %d 件" % _auto_buy_last_items)
	if _auto_buy_last_equip > 0:
		parts.append("装备 %d 件" % _auto_buy_last_equip)
	if not parts.is_empty():
		return "自动购置 %s, 花费 %s 灵石" % [" + ".join(parts), fmt(_auto_buy_last_cost)]
	if _auto_buy_last_swap > 0:
		return "自动最佳换装 %d 件" % _auto_buy_last_swap
	return ""

# 打磨-69: 自动施展 (挂机时 主动神通 冷却完毕 仍要 手动 逐个点 施展, 与 一键施展 口径 不齐;
# GameData._process 每帧驱动 (置于 _tick_active_cd 之前, 冷却归零 同帧 即施展), 自门控于
# auto_cast, 关闭时直接返回 故可直接调用测试; 本轮 自动 施展 所有 就绪 (无冷却) 的 已学
# 主动神通 (复用 use_all_active 口径: 复用 use_active_skill 的 冷却/爆发/skill_use 埋点),
# 施展后 各神通 进冷却, 下轮 全冷却中 0 施展 幂等, 无热循环; 每轮 有 施展 则 _auto_cast_seq+1
# (UI 据此弹 绿色浮动, 与 打磨-45/60 一键施展 浮动 同口径 追加 爆发 总量); 0 施展 不增 事件
# (UI 不弹 浮动, 口径 与 一键施展 0 变更 只走 底部消息 一致); 离线期间 不触发 (离线只结算收益))
func _try_auto_cast() -> void:
	if not auto_cast:
		return
	var r: Dictionary = use_all_active()
	var n := int(r.get("count", 0))
	var burst := float(r.get("burst", 0.0))
	if n <= 0:
		return
	_auto_cast_seq += 1
	_auto_cast_last_n = n
	_auto_cast_last_burst = burst

# 打磨-69: 自动施展 上一轮 变更 文案 (只读; seq<=0 [从未触发/读档重置] 返回 "")
# 口径: "自动施展 N 个神通 (爆发+X 灵气/道行)" (飞升后 口径=道行, 与 打磨-60 一键施展 同格式)
func auto_cast_last_text() -> String:
	if _auto_cast_seq <= 0 or _auto_cast_last_n <= 0:
		return ""
	return "自动施展 %d 个神通 (爆发+%s %s)" % [_auto_cast_last_n, fmt(_auto_cast_last_burst), primary_res_name()]

# 打磨-80: 自动领悟 (挂机时 境界/层 提升 解锁 新技能 仍要 手动 逐个点 领悟, 与 一键领悟 口径
# 不齐; GameData._process 每帧驱动 (置于 _try_auto_break 之后: 同帧 突破 升层/晋境界 后 立即
# 学习 新解锁 技能), 自门控于 auto_learn, 关闭时直接返回 故可直接调用测试; 本轮 批量学习
# 全部 未学+境界足够 技能 (复用 learn_all_available("", -1) 全局口径: 无 类别/品质 筛选 叠加,
# 与 一键领悟 按钮 全部类别·全部品质 口径 一致); 学习后 可学数 归 0, 下帧 再试 0 变更 幂等
# (learn_all_available 只学 未学+可学 项), 无热循环; 学习 无 资源/灵石 消耗 (技能 领悟 免费,
# 与 手动 领悟 口径 一致), 无 统计 新 埋点 (skill_learn 由 成就/收集 侧 消费 learned 数组);
# 变更 文案 auto_learn_last_text() 供 UI 底部 消息 提示 (无屏幕浮动 防 挂机刷屏, 与 自动购置 同口径))
func _try_auto_learn() -> void:
	if not auto_learn:
		return
	var r: Dictionary = learn_all_available("", -1)
	var n := int(r.get("count", 0))
	if n <= 0:
		return
	_auto_learn_seq += 1
	_auto_learn_last_n = n

# 打磨-80: 自动领悟 上一轮 变更 文案 (只读; seq<=0 [从未触发/读档重置] 返回 "")
# 口径: "自动领悟 N 个技能" (与 一键领悟 浮动 文案 同 数量 口径, 无 资源 消耗 说明)
func auto_learn_last_text() -> String:
	if _auto_learn_seq <= 0 or _auto_learn_last_n <= 0:
		return ""
	return "自动领悟 %d 个技能" % _auto_learn_last_n

# ================= M5-3: 爬塔 自动挑战 + UI 只读接口 =================
# 自动爬塔 (GameData._process 每帧驱动; 自门控于 auto_tower, 关闭时直接返回 可直接调用测试;
# 每帧 双塔 各 至多 挑战一次 (镇妖塔 先, 登天梯 后, 口径=try_tower_challenge 手动按钮同路径,
# 复用 奖励结算/剧毒/每日首胜/统计埋点); 胜=层数推进 (灵石+奖励), 败=停留 本层 无 消耗 无 惩罚,
# 层数 单调 推进/停留 天然 无热循环 (与 自动突破 同 门控 口径); 镇妖塔 通关态 恒 守塔 模式
# 反复 挑战 1000 层 Boss (口径=fixed_challenge_floor); 离线期间 不触发 (离线只结算收益))
func _try_auto_tower() -> void:
	if not auto_tower:
		return
	try_tower_challenge("fixed")
	try_tower_challenge("endless")

# 爬塔 UI 只读接口 (UI 每帧 调用; 不 改 状态/存档/统计)
# 双塔 当前 挑战 层 记录 (镇妖塔=守塔 1000 层 或 最高已过层+1; 登天梯=当前 待挑战 层;
# 怪物 有效 属性 含 结构/偏向/特性 倍率; 供 怪物卡/战力对比 展示)
func tower_challenge_preview() -> Dictionary:
	var frec: Dictionary = get_fixed_floor(fixed_challenge_floor())
	var erec: Dictionary = get_endless_floor(tower_endless_floor)
	var fmon: Dictionary = tower_monster_stats(frec)
	var emon: Dictionary = tower_monster_stats(erec)
	return {
		"fixed_floor": fixed_challenge_floor(),
		"fixed_mon": fmon,
		"fixed_win": player_atk_effective() >= float(fmon["atk"]) * TOWER_WIN_RATIO,
		"endless_floor": tower_endless_floor,
		"endless_mon": emon,
		"endless_win": player_atk_effective() >= float(emon["atk"]) * TOWER_WIN_RATIO,
	}

# 怪物 特性 名称 列表 文案 (未知 id 原样保留; 空 返回 "")
func _trait_names(traits: Array) -> String:
	var names: Array[String] = []
	for tid in traits:
		var td: Dictionary = trait_by_id.get(str(tid), {})
		names.append(str(td.get("name", str(tid))) if not td.is_empty() else str(tid))
	return "、".join(names)

# 怪物卡 tooltip (名/特性说明/数值 构成; 与 M5-1 数据表 同口径)
func tower_monster_tip(rec: Dictionary) -> String:
	var mon: Dictionary = tower_monster_stats(rec)
	var lines: Array[String] = []
	lines.append(str(mon["name"]) + (" (精英)" if bool(mon["is_elite"]) else "") + (" (Boss)" if str(mon["boss_type"]) != "" else ""))
	var tn: String = _trait_names(mon["traits"])
	if tn != "":
		lines.append("特性: " + tn)
	for tid in mon["traits"]:
		var td: Dictionary = trait_by_id.get(str(tid), {})
		if not td.is_empty():
			lines.append("· %s — %s" % [str(td.get("name", "")), str(td.get("desc", ""))])
	lines.append("HP %s · ATK %s · DEF %s" % [fmt(float(mon["hp"])), fmt(float(mon["atk"])), fmt(float(mon["def"]))])
	lines.append("奖励 灵石 %s" % fmt(float(mon["stone"])))
	return "\n".join(lines)

# 战力对比 行 文案 (玩家 atk/def 有效 vs 怪物 atk; 胜=绿/败=红 由 UI 着色, 此处 只给 文本)
func tower_power_line(mon_atk: float) -> String:
	var ok: bool = player_atk_effective() >= mon_atk * TOWER_WIN_RATIO
	return "玩家 ATK %s%s vs 怪物 ATK %s → %s (判定: 玩家 ≥ 怪 x %.2f)" % [
		fmt(player_atk_effective()),
		" (剧毒 -15%% x %d 场)" % poison_battles if poison_battles > 0 else "",
		fmt(mon_atk), ("胜" if ok else "败"), TOWER_WIN_RATIO]

# M5-3: 自动爬塔按钮 tooltip 动态段 (只读; 双塔 当前 挑战 层 + 胜负 预测 + 层数进度;
# 口径 与 爬塔页 怪物卡/战力对比 同源; 不 改 状态/存档/统计; 供 按钮 悬停 动态 刷新, 同 打磨-84/85/86)
func auto_tower_next_tip() -> String:
	var p: Dictionary = tower_challenge_preview()
	var lines: Array[String] = []
	lines.append("镇妖塔 第 %d/%d 层「%s」→ %s" % [
		int(p["fixed_floor"]), int(tower_fixed.get("max_floor", 1000)),
		str(p["fixed_mon"]["name"]), ("可胜" if bool(p["fixed_win"]) else "战力不足")])
	if tower_fixed_clear:
		lines.append("已通关 (守塔模式: 反复 挑战 1000 层 Boss 拿刷新掉落)")
	lines.append("登天梯 第 %d 层「%s」→ %s (历史最高 %d 层)" % [
		int(p["endless_floor"]), str(p["endless_mon"]["name"]),
		("可胜" if bool(p["endless_win"]) else "战力不足"), tower_endless_best])
	return "\n".join(lines)

# M5-4: 镇妖塔 通关 一次性 大奖 文案 (首通 1000 层 Boss 触发; 灵石 大奖 100 万 + 永久 atk/def +15%;
# 称号 与 成就 tower_clear 由 check_achievements 判定, 此处 只 给 灵石 大奖 文案; 0 发放=空串)
func tower_clear_reward_text(stone: float) -> String:
	if stone <= 0.0:
		return ""
	return " 通关大奖: 称号「镇妖塔·通关者」+ 灵石 %s + 永久 atk/def +%.0f%% (守塔模式)" % [
		fmt(stone), TOWER_CLEAR_BUFF * 100.0]

# M5-4: 镇妖塔 通关 称号 (顶栏/爬塔页 展示; 未通关 空串; 只读 无 状态/存档/统计 副作用)
func tower_clear_title() -> String:
	return "镇妖塔·通关者" if tower_fixed_clear else ""

# M5-3: 爬塔 状态汇总 文案 (只读; 修行页 爬塔区 展示; 含 剧毒 debuff 提醒; 不 改 状态)
func tower_status_line() -> String:
	var s: String = "镇妖塔 最高 %d/1000 层%s · 登天梯 待挑战 第 %d 层 (最高 %d)" % [
		tower_fixed_floor, " (通关「镇妖塔·通关者」)" if tower_fixed_clear else "",
		tower_endless_floor, tower_endless_best]
	if poison_battles > 0:
		s += " · 剧毒 -15%% 攻 x %d 场" % poison_battles
	return s

# 打磨-70: 自动系列 状态汇总 — 状态键 (只读; "1|0|1|1|0" = 突破|购置|施展|领悟|爬塔, 1=开 0=关;
# M5-3 起 5 开关: 第 5 段=自动爬塔; UI 仅 键变化 时 刷 汇总行 文本/颜色; 无 存档/统计 副作用)
func auto_summary_key() -> String:
	return "%d|%d|%d|%d|%d" % [
		1 if auto_break else 0, 1 if auto_buy else 0,
		1 if auto_cast else 0, 1 if auto_learn else 0, 1 if auto_tower else 0]

# 打磨-70: 自动系列 状态汇总 文案 (只读; ✓=开 ✗=关, 口径 与 各 开关 按钮 一致;
# M5-3 起 5 段: 突破·购置·施展·领悟·爬塔)
func auto_summary_text() -> String:
	return "自动: 突破 %s · 购置 %s · 施展 %s · 领悟 %s · 爬塔 %s" % [
		"✓" if auto_break else "✗", "✓" if auto_buy else "✗",
		"✓" if auto_cast else "✗", "✓" if auto_learn else "✗",
		"✓" if auto_tower else "✗"]

# 打磨-72: 启动 恢复 自动系列 开关 提示 文案 (只读; 全关 返回 空串, 否则
# "已恢复 自动: 突破·购置·施展·领悟" (仅 开启项, 固定序 突破>购置>施展>领悟, 全开 即 突破·购置·施展·领悟);
# 供 main.gd _ready 启动提示 (底部消息 同位置, 仅 启动 一次, 离线消息 优先, 离线 与 自动 提示 不同时 显示))
func auto_restore_text() -> String:
	var parts: Array[String] = []
	if auto_break:
		parts.append("突破")
	if auto_buy:
		parts.append("购置")
	if auto_cast:
		parts.append("施展")
	if auto_learn:
		parts.append("领悟")
	if auto_tower:
		parts.append("爬塔")
	if parts.is_empty():
		return ""
	return "已恢复 自动: %s" % "·".join(parts)

# 打磨-73: 顶栏 自动系列 状态徽标 — 开启开关 数量 (只读; 0=全关 UI 隐藏徽标,
# N>0 时 UI 显示 "自动 N/4" 金色徽标 (打磨-80 起 4 开关); 无 存档/统计 副作用)
func auto_on_count() -> int:
	var n := 0
	if auto_break:
		n += 1
	if auto_buy:
		n += 1
	if auto_cast:
		n += 1
	if auto_learn:
		n += 1
	if auto_tower:
		n += 1
	return n

# 打磨-88: 自动系列 一键挂机 — 是否 全部 开启 (只读; 5 开关 全 true 才 返回 true, 部分开 返回 false;
# M5-3 起 5 开关 [突破/购置/施展/领悟/爬塔]; 供 一键挂机 按钮 判断 文案/点击方向: 未全开=点击 全开,
# 全开=点击 全关; 无 存档/统计 副作用)
func auto_all_on() -> bool:
	return auto_break and auto_buy and auto_cast and auto_learn and auto_tower

# 打磨-88: 自动系列 一键 全开/全关 (供 一键挂机 按钮 直接 置 5 开关 [突破/购置/施展/领悟/爬塔];
# 各开关 口径/持久化 不变 (各自 auto_* 存档字段, 离线期间不触发, 道祖封顶 自动突破 恒不触发);
# 开关 动作 本身 无 资源/统计 副作用, 实际 行为 由 各 _try_auto_* 走 真实 埋点 路径;
# 部分开 时 点击 一键挂机 = 补齐 至 全开 (而非 仅关 已开的), 与 "挂机 全程 自动" 目标一致)
func set_auto_all(on: bool) -> void:
	auto_break = on
	auto_buy = on
	auto_cast = on
	auto_learn = on
	auto_tower = on

# ---------- 打磨-89: 一键挂机 按钮 tooltip 动态段 (各 开启中 开关 动态 状态 汇总) ----------
# 只读: 一键挂机 是 4 自动 开关 的 批量 开关 (打磨-88), 悬停 只有 静态 口径, 开启 后 悬停 不知
# 各 开启中 开关 当前 状态 (下次 突破 ETA / 下一件 购置 ETA / 神通 就绪数 / 可学 数); 4 个 单开关
# 按钮 的 动态段 (打磨-84/85/86) 要 逐个 按钮 悬停 才 见; tooltip 追加 动态段: 按 各 单开关 接口
# 口径 汇总 (auto_break_next_tip/auto_buy_next_tip/auto_cast_next_tip/auto_learn_next_tip),
# 各段 带 开关名 前缀, 固定序 突破>购置>施展>领悟; 仅 展示 开启中 开关 的 段 (动态段 与 开关
# 状态 无关 恒可算, 但 只 展示 生效中 的 避免 全关 时 4 段 空谈 拉长 tooltip); 全关 = 简短
# "全关" 说明 文案。只读: 不 改 状态/存档/统计 (供 UI 悬停 tooltip 动态 刷新, 文本 变化 才 写)
func auto_idle_next_tip() -> String:
	var parts: Array[String] = []
	if auto_break:
		parts.append("突破: " + auto_break_next_tip())
	if auto_buy:
		parts.append("购置: " + auto_buy_next_tip())
	if auto_cast:
		parts.append("施展: " + auto_cast_next_tip())
	if auto_learn:
		parts.append("领悟: " + auto_learn_next_tip())
	if auto_tower:
		parts.append("爬塔: " + auto_tower_next_tip())
	if parts.is_empty():
		return "各开关 均 未开启 (点击 一键 全开; 开启后 此处 展示 各开关 动态 状态)"
	return "\n".join(parts)

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

# ---------- 打磨-29: 法器 一键购买 (修行页法器区, 与 一键购买/一键领悟/一键最佳 口径一致) ----------

# 当前灵石可买起的未拥有法器数 (供修行页"一键购买"按钮文案)
func item_affordable_count() -> int:
	var n := 0
	for it in ITEMS:
		if not owned.has(it["id"] as String) and stones >= float(it["cost"]):
			n += 1
	return n

# 按 价格升序 (同价按数据序) 连续购买 买得起 的法器, 灵石花到买不起为止
func buy_items_affordable() -> Dictionary:
	var order: Array = []
	for it in ITEMS:
		order.append(it)
	order.sort_custom(_item_price_cmp)
	var n := 0
	for it in order:
		if str(try_buy_item(str(it["id"]))).find("购得") >= 0:
			n += 1
	return {"count": n, "bought": n > 0}

func _item_price_cmp(a: Dictionary, b: Dictionary) -> bool:
	var ca: float = float(a["cost"])
	var cb: float = float(b["cost"])
	if ca != cb:
		return ca < cb
	return str(a["id"]) < str(b["id"])

# ---------- 打磨-47: 下一购买目标 (最便宜未拥有件, 供 一键购买 结果反馈) ----------
# 只读: 返回 价格升序首个未拥有件 {id, name, cost, shortfall}, 全部拥有 = {}
# shortfall = cost - 当前灵石 (>=0; 连买买不起时恒 >0, 供 UI 追加 "距下一件还差")

func equip_next_target() -> Dictionary:
	var best: Dictionary = {}
	for id in equip_ids:
		if owned_eq.has(id):
			continue
		var e: Dictionary = equip_by_id.get(id, {})
		if e.is_empty():
			continue
		var c: float = float(e.get("cost", INF))
		if best.is_empty() or c < float(best["cost"]) or (c == float(best["cost"]) and str(id) < str(best["id"])):
			best = e
	if best.is_empty():
		return {}
	return {"id": str(best["id"]), "name": str(best.get("name", "")),
		"cost": float(best["cost"]), "shortfall": maxf(float(best["cost"]) - stones, 0.0)}

func item_next_target() -> Dictionary:
	var best: Dictionary = {}
	for it in ITEMS:
		if owned.has(str(it["id"])):
			continue
		var c: float = float(it["cost"])
		if best.is_empty() or c < float(best["cost"]) or (c == float(best["cost"]) and str(it["id"]) < str(best["id"])):
			best = it
	if best.is_empty():
		return {}
	return {"id": str(best["id"]), "name": str(best.get("name", "")),
		"cost": float(best["cost"]), "shortfall": maxf(float(best["cost"]) - stones, 0.0)}

# ---------- 打磨-48: 下一件缺口 ETA 联动 (复用 打磨-12 eta_seconds/eta_text 口径) ----------
# 只读: target 空 或 缺口<=0 (买得起) 返回 ""; 灵石速率>0 时返回 " 约 X 可购" (前缀空格供拼接),
# 无灵石收入 (eta=-1 防御) 时省略 (返回 "")。shortfall=cost-灵石, 与 eta_seconds(cost)=(cost-灵石)/速率 恒等。
func next_target_eta_text(target: Dictionary) -> String:
	if target.is_empty():
		return ""
	var gap: float = float(target.get("shortfall", 0.0))
	if gap <= 0.0:
		return ""
	var cost: float = float(target.get("cost", 0.0))
	var t: float = eta_seconds(cost)
	if t < 0.0:
		return ""
	return " " + eta_text(cost)

# ---------- 打磨-49: 顶栏灵石 可购进度 (最便宜 未拥有 装备/法器, 复用 打磨-47/12/48 口径) ----------
# 只读: 跨 140 装备 + 10 法器 取 最便宜 未拥有件 (价格升序, 同价按 id 确定性)。
# 复用 equip_next_target / item_next_target 的 shortfall 口径, 追加 kind = "装备"/"法器" 供 UI 命名。
# 全部拥有 = {}。
func stone_next_target() -> Dictionary:
	var e: Dictionary = equip_next_target()
	var i: Dictionary = item_next_target()
	if e.is_empty() and i.is_empty():
		return {}
	var pick: Dictionary = e
	var kind := "装备"
	if e.is_empty():
		pick = i
		kind = "法器"
	elif not i.is_empty():
		var ce: float = float(e["cost"])
		var ci: float = float(i["cost"])
		if ci < ce or (ci == ce and str(i["id"]) < str(e["id"])):
			pick = i
			kind = "法器"
	pick["kind"] = kind
	return pick

# 顶栏灵石行 tooltip: 当前灵石速率 + 距下一件 (最便宜未拥有) 缺口与 ETA。
# 全拥有 = "已集齐"; 灵石已足够 = "可立即购买"; 缺口>0 且 灵石速率>0 = 缺口额 + "约 X 可购"
# (复用 打磨-12 eta_seconds/eta_text 口径); 无灵石收入 省略 ETA 并标注。
func stone_next_target_tip() -> String:
	var rate: float = stone_per_sec()
	var head := "当前 %s 灵石/秒" % fmt(rate)
	var target: Dictionary = stone_next_target()
	if target.is_empty():
		return head + "\n已集齐全部 装备与法器 (无需再攒灵石)"
	var gap: float = float(target["shortfall"])
	var label := "%s「%s」" % [str(target["kind"]), str(target["name"])]
	if gap <= 0.0:
		return head + "\n距下一件 %s 灵石已足够, 可立即购买" % label
	var t: float = eta_seconds(float(target["cost"]))
	if t < 0.0:
		return head + ("\n距下一件 %s 还差 %s 灵石 (当前无灵石收入)" % [label, fmt(gap)])
	return head + ("\n距下一件 %s 还差 %s 灵石 %s" % [label, fmt(gap), eta_text(float(target["cost"]))])

# ---------- 打磨-50: 修行页灵石速率行 内联 下一件可购提示 (复用 打磨-49 stone_next_target 口径) ----------
# 只读: 全拥有 -> "已集齐全部 装备与法器"; 灵石足够 -> "「类别·名」灵石已足够, 可立即购买";
# 缺口>0 且 灵石速率>0 -> "距下一件「类别·名」还差 X 灵石 <ETA 档位>" (复用 打磨-12 eta_text 口径);
# 缺口>0 且 无灵石收入 -> 省略 ETA 标注 "当前无灵石收入"。无新存档字段。
func stone_next_target_inline() -> String:
	var target: Dictionary = stone_next_target()
	if target.is_empty():
		return "已集齐全部 装备与法器"
	var label := "%s「%s」" % [str(target["kind"]), str(target["name"])]
	var gap: float = float(target["shortfall"])
	if gap <= 0.0:
		return label + " 灵石已足够, 可立即购买"
	var t: float = eta_seconds(float(target["cost"]))
	if t < 0.0:
		return "距下一件 %s 还差 %s 灵石 (当前无灵石收入)" % [label, fmt(gap)]
	return ("距下一件 %s 还差 %s 灵石 " % [label, fmt(gap)]) + eta_text(float(target["cost"]))

# ---------- 打磨-84: 自动购置 按钮 tooltip 动态段 (下一件 可购时间, 复用 打磨-49/12 口径) ----------
# 只读: 顶栏灵石行 tooltip (打磨-49 stone_next_target_tip) 与 底部消息 (打磨-47/48 _next_gap_text)
# 已给 手动路径 下一件 ETA, 但 自动购置 开关按钮 tooltip 只有 静态 口径, 开启 自动 后 玩家 悬停
# 开关 不知 下一件 还要 多久 才能 被 自动 购入; tooltip 追加 动态 段: 当前 灵石 速率 + 距 下一件
# (跨 140 装备 + 10 法器 最便宜 未拥有件, 打磨-49 stone_next_target 口径) 缺口 与 可购 ETA
# (复用 打磨-12 eta_seconds/eta_text; 全拥有 = 已集齐, 缺口<=0 = 可立即购入, 无 灵石 收入 省略 ETA)。
# 只读: 不 改 状态/存档/统计 (供 UI 悬停 tooltip 动态 刷新, 文本 变化 才 写)
func auto_buy_next_tip() -> String:
	var rate: float = stone_per_sec()
	var head := "当前 %s 灵石/秒" % fmt(rate)
	var target: Dictionary = stone_next_target()
	if target.is_empty():
		return head + "\n已集齐全部 装备与法器 (无需再攒灵石)"
	var gap: float = float(target["shortfall"])
	var label := "%s「%s」" % [str(target["kind"]), str(target["name"])]
	if gap <= 0.0:
		return head + "\n下一件 %s 灵石已足够, 可立即购入" % label
	var t: float = eta_seconds(float(target["cost"]))
	if t < 0.0:
		return head + ("\n下一件 %s 还差 %s 灵石 (当前无灵石收入)" % [label, fmt(gap)])
	return head + ("\n下一件 %s 还差 %s 灵石 %s" % [label, fmt(gap), eta_text(float(target["cost"]))])

# ---------- 打磨-85: 自动突破 按钮 tooltip 动态段 (下次 自动突破 耗时预估, 复用 打磨-24 ETA 口径) ----------
# 只读: 打磨-84 已给 自动购置 开关 tooltip 补 下一件 可购 动态段, 但 自动突破 开关 悬停 只有 静态 口径,
# 开启 后 玩家 悬停 不知 资源 还要 攒多久 才 够 下一次 自动 突破/道行精进; tooltip 追加 动态 段:
# 当前 主资源 速率 + 距 下一目标 (未飞升=突破至 下一层/境界/飞升, 飞升后=道行精进至 下一阶段,
# 与 打磨-31 下一目标 行 同口径) 缺口 与 ETA (复用 打磨-24 breakthrough_eta_seconds/breakthrough_eta_text;
# 资源已足够 = 可立即突破, 无 主资源 收入 = 标注 当前无收入, 道祖封顶 = 圆满 不再 精进)。
# 只读: 不 改 状态/存档/统计 (供 UI 悬停 tooltip 动态 刷新, 文本 变化 才 写)
func auto_break_next_tip() -> String:
	var res_name: String = primary_res_name()
	var head := "当前 %s %s/秒" % [fmt(qi_per_sec()), res_name]
	if ascended and dao_level >= IMMORTAL_REALMS.size() - 1:
		return head + "\n已至道祖 · 道法自然 ♪ (圆满, 不再精进)"
	var need: float = dao_break_cost() if ascended else breakthrough_cost()
	var cur: float = dao if ascended else essence
	if cur >= need:
		return head + ("\n%s 已足够, 可立即突破" % res_name)
	var gap: float = need - cur
	var goal: String = "道行精进至 %s" % IMMORTAL_REALMS[dao_level + 1] if ascended else "突破至 %s" % next_realm_display()
	var t: float = breakthrough_eta_seconds()
	if t < 0.0:
		return head + ("\n%s 还差 %s %s (当前无收入)" % [goal, fmt(gap), res_name])
	return head + ("\n%s 还差 %s %s %s" % [goal, fmt(gap), res_name, breakthrough_eta_text()])

# ---------- 打磨-86: 自动施展 按钮 tooltip 动态段 (就绪数/爆发总量/最短冷却, 复用 打磨-54 爆发口径) ----------
# 只读: 打磨-84/85 已给 自动购置/自动突破 开关 tooltip 补 动态段, 但 自动施展 开关 悬停 只有 静态 口径,
# 开启 后 玩家 悬停 不知 已学神通 就绪多少/冷却 还要 多久/爆发 多少; tooltip 追加 动态 段:
# 就绪 已学主动神通 数 + 本批 爆发 总量 (就绪数 x 各自 当前速率x爆发秒数, 与 打磨-54/60/69 同口径,
# 飞升后=道行) + 冷却中 最短 剩余 与 名称 (fmt_time 档位)。未学 主动神通 时 说明 文案; 无 就绪 时
# 只 给 冷却 ETA; 就绪 0 且 无 冷却 说明 全就绪 可 自动 施展。
# 只读: 不 改 状态/存档/统计 (供 UI 悬停 tooltip 动态 刷新, 文本 变化 才 写)
func auto_cast_next_tip() -> String:
	var learned_n := 0
	var ready_n := 0
	var burst := 0.0
	var next_name := ""
	var next_rem := 1e18
	for id in skill_ids:
		var s: Dictionary = skill_by_id.get(str(id), {})
		if s.is_empty() or str(s.get("type", "")) != "active":
			continue
		if not learned.has(str(id)):
			continue
		learned_n += 1
		var rem: float = _active_cd.get(str(id), 0.0)
		if rem <= 0.0:
			ready_n += 1
			burst += qi_per_sec() * float(s["value"])
		elif rem < next_rem:
			next_rem = rem
			next_name = str(s["name"])
	if learned_n == 0:
		return "未学 任何 主动神通 (先 领悟 神通 后 自动 施展 生效)"
	var out := "就绪 %d/%d 个" % [ready_n, learned_n]
	if ready_n > 0:
		out += ", 爆发+%s %s" % [fmt(burst), primary_res_name()]
	if ready_n < learned_n:
		out += " | 最短冷却 「%s」 约 %s" % [next_name, fmt_time(next_rem)]
	else:
		out += " | 全部就绪"
	return out

# ---------- 打磨-86: 自动领悟 按钮 tooltip 动态段 (当前 可学数/下一个 解锁 门槛, 复用 can_learn 口径) ----------
# 只读: 自动领悟 无 资源 消耗 (学习免费), 无 攒资源 ETA; 动态段 给 当前 全局 可学 数 (与 一键领悟
# 全部类别/全部品质 口径一致) + 下一个 未学 技能的 解锁 门槛 (数据序 首个 未学+境界不足,
# "还需 X 第 Y 层")。无 未学 技能 = 已集齐 说明 文案。
# 只读: 不 改 状态/存档/统计 (供 UI 悬停 tooltip 动态 刷新, 文本 变化 才 写)
func auto_learn_next_tip() -> String:
	var n := learn_available_count()
	if n > 0:
		return "当前 可学 %d 个 (开启时 立即 批量 领悟)" % n
	var nxt := ""
	for id in skill_ids:
		if learned.has(str(id)):
			continue
		var s: Dictionary = skill_by_id.get(str(id), {})
		if s.is_empty():
			continue
		if not can_learn(str(id)):
			nxt = str(id)
			break
	if nxt == "":
		return "已集齐 全部技能 (无需再领悟)"
	var s2: Dictionary = skill_by_id[nxt]
	var r: Dictionary = REALMS[int(s2["unlock_realm"])]
	return "无可学技能 | 下一个 「%s」 还需 %s 第%d层" % [str(s2["name"]), str(r["name"]), int(s2["unlock_layer"])]

# ---------- 打磨-30: 主动神通 一键施展 (批量释放所有 就绪 主动神通) ----------

# 当前就绪 (无冷却) 的 已学主动神通 数 (供技能页"一键施展"按钮文案)
func active_ready_count() -> int:
	var n := 0
	for id in skill_ids:
		var s: Dictionary = skill_by_id.get(str(id), {})
		if s.is_empty() or str(s.get("type", "")) != "active":
			continue
		if not learned.has(str(id)):
			continue
		if active_ready(str(id)):
			n += 1
	return n

# 释放所有 就绪 的主动神通 (复用 use_active_skill 的 冷却/爆发/统计埋点)
# 返回 {count, burst}; 施展后各自进入冷却, 冷却中再调 = 0 (幂等)
func use_all_active() -> Dictionary:
	var n := 0
	var burst := 0.0
	for id in skill_ids:
		var s: Dictionary = skill_by_id.get(str(id), {})
		if s.is_empty() or str(s.get("type", "")) != "active":
			continue
		if not learned.has(str(id)):
			continue
		if not active_ready(str(id)):
			continue
		var before := primary_res_value()
		var m := use_active_skill(str(id))
		if m.find("施展") >= 0:
			n += 1
			burst += primary_res_value() - before
	return {"count": n, "burst": burst}

# ---------- 打磨-75: 一键系列 顶栏 状态汇总 (六项 可执行数 一览, 与 各页 一键 按钮 计数 同口径) ----------
# 只读: 六项 = [一键领悟, 一键神通, 一键施展, 法器一键购买, 装备一键购买, 一键最佳] 的 可执行数。
# 口径 完全 复用 各页 按钮 计数 (领悟/神通 受 当前 技能页 类别/品质 筛选 叠加 — cat/tier 参数
# 由 UI 传入; 施展=就绪主动神通数; 法器/装备=灵石 单件 买得起 的 未拥有件 数 (连买以预算耗尽为准);
# 最佳=可改进 槽位数)。供 顶栏 汇总徽标 展示 与 段 着色 (0=灰), 无 状态/存档/统计 副作用。

# 当前灵石 单件 买得起 的 未拥有装备 数 (口径 = main.gd 装备页 一键购买 按钮计数: 逐件 灵石>=价)
func equip_affordable_count() -> int:
	var n := 0
	for eid in equip_ids:
		var e: Dictionary = equip_by_id.get(str(eid), {})
		if e.is_empty():
			continue
		if not owned_eq.has(str(eid)) and stones >= float(e["cost"]):
			n += 1
	return n

# 六项 可执行数 [领悟, 神通, 施展, 法器, 装备, 最佳] (只读; cat/tier = 当前 技能页 筛选,
# "" = 全部类别 / -1 = 全部品质, 与 技能页 按钮 同口径)
func onekey_summary_vals(cat: String = "", tier: int = -1) -> Array:
	return [learn_available_count(cat, tier), active_learn_available_count(cat, tier),
		active_ready_count(), item_affordable_count(), equip_affordable_count(), equip_best_pending()]

# 汇总 状态键 (只读; 变化才刷 UI 文本/颜色) — cat/tier 同 onekey_summary_vals
func onekey_summary_key(cat: String = "", tier: int = -1) -> String:
	var v: Array = onekey_summary_vals(cat, tier)
	return "%d|%d|%d|%d|%d|%d" % [int(v[0]), int(v[1]), int(v[2]), int(v[3]), int(v[4]), int(v[5])]

# ---------- 打磨-76: 一键汇总徽标 段 悬浮 明细 (悬停 段 热区 展开 可执行项 列表) ----------
# 只读: 返回 6 行 明细文本 [领悟, 神通, 施展, 法器, 装备, 最佳], 口径 与 onekey_summary_vals
# 完全一致 (领悟/神通 受 cat/tier 筛选 叠加, 施展=就绪主动神通, 法器/装备=灵石 单件 买得起
# 的 未拥有件, 最佳=可改进 槽位); 列表 截断 (领悟/神通/施展 前 6 行, 法器/装备/最佳 前 5 行),
# 超出 附 "…N 项"; 可执行 0 = 说明 文案 (无 可学/无 就绪/灵石不足/已最佳)。供 顶栏 一键 徽标
# 段 tooltip 追加 (UI 按 状态键 节流, 与 段 计数 同 刷新 时机), 无 状态/存档/统计 副作用。

# 领悟/神通 段 明细 (active_only=false=领悟 / true=神通; 与 按钮 计数 同 口径: 未学+境界足够+筛选)
func _ok_tip_learn(cat: String, tier: int, active_only: bool) -> String:
	var n: int = active_learn_available_count(cat, tier) if active_only else learn_available_count(cat, tier)
	var label: String = "神通" if active_only else "技能"
	if n == 0:
		return "当前境界 无 新 可学%s (未学 + 境界/层 足够, 与 一键%s 计数 同口径)" % [label, label]
	var lines: Array = []
	for id in skill_ids:
		if learned.has(id):
			continue
		var s: Dictionary = skill_by_id.get(id, {})
		if s.is_empty():
			continue
		if cat != "" and str(s["category"]) != cat:
			continue
		if tier >= 0 and int(s["tier"]) != tier:
			continue
		if active_only and str(s.get("type", "")) != "active":
			continue
		if not can_learn(id):
			continue
		lines.append("「%s」 %s·%s (%s 第%d层 以上)" % [str(s["name"]), str(s["tier_name"]),
			str(s["category_name"]), REALMS[int(s["unlock_realm"])]["name"], int(s["unlock_layer"])])
		if lines.size() >= 6:
			break
	var txt := "%d 个可学:" % n
	for l in lines:
		txt += "\n· " + str(l)
	if n > lines.size():
		txt += "\n…%d 项" % (n - lines.size())
	return txt

# 施展 段 明细 (已学+冷却完毕 的 主动神通; 每行 附 爆发 预览, 与 打磨-54 口径 一致)
func _ok_tip_cast() -> String:
	var n: int = active_ready_count()
	if n == 0:
		return "无 就绪 主动神通 (未领悟 或 冷却中)"
	var rate: float = qi_per_sec()
	var lines: Array = []
	for id in skill_ids:
		var s: Dictionary = skill_by_id.get(str(id), {})
		if s.is_empty() or str(s.get("type", "")) != "active":
			continue
		if not learned.has(str(id)) or not active_ready(str(id)):
			continue
		lines.append("「%s」 爆发 +%s %s" % [str(s["name"]), fmt(rate * float(s["value"])), primary_res_name()])
		if lines.size() >= 6:
			break
	var txt := "%d 个就绪:" % n
	for l in lines:
		txt += "\n· " + str(l)
	if n > lines.size():
		txt += "\n…%d 项" % (n - lines.size())
	return txt

# 法器 段 明细 (灵石 单件 买得起 的 未拥有 法器, 价格升序 截断 5 行)
func _ok_tip_item() -> String:
	var order: Array = []
	for it in ITEMS:
		if not owned.has(str(it["id"])) and stones >= float(it["cost"]):
			order.append(it)
	order.sort_custom(_item_price_cmp)
	var n: int = order.size()
	if n == 0:
		return "灵石 不足 购买 下一件, 或 法器 已 全 拥有"
	var txt := "%d 件可购:" % n
	for i in mini(n, 5):
		txt += "\n· 「%s」 灵石 %s" % [str(order[i]["name"]), fmt(float(order[i]["cost"]))]
	if n > 5:
		txt += "\n…%d 项" % (n - 5)
	return txt

# 装备 段 明细 (灵石 单件 买得起 的 未拥有 装备, 价格升序 截断 5 行; 与 装备页 一键购买 按钮 同口径)
func _ok_tip_equip() -> String:
	var order: Array = []
	for eid in equip_ids:
		var e: Dictionary = equip_by_id.get(str(eid), {})
		if e.is_empty():
			continue
		if not owned_eq.has(str(eid)) and stones >= float(e["cost"]):
			order.append(e)
	order.sort_custom(_equip_cost_cmp)
	var n: int = order.size()
	if n == 0:
		return "灵石 不足 购买 下一件, 或 装备 已 全 拥有"
	var txt := "%d 件可购:" % n
	for i in mini(n, 5):
		txt += "\n· 「%s」 %s·%s 灵石 %s" % [str(order[i]["name"]), str(order[i]["tier_name"]),
			str(order[i]["slot_name"]), fmt(float(order[i]["cost"]))]
	if n > 5:
		txt += "\n…%d 项" % (n - 5)
	return txt

func _equip_cost_cmp(a: Dictionary, b: Dictionary) -> bool:
	var ca: float = float(a["cost"])
	var cb: float = float(b["cost"])
	if ca != cb:
		return ca < cb
	return str(a["id"]) < str(b["id"])

# 最佳 段 明细 (穿戴 非最佳 的 槽位; 每行 部位 + 建议 换 件名 + 当前 穿戴)
func _ok_tip_best() -> String:
	var n: int = equip_best_pending()
	if n == 0:
		return "各 部位 已 最佳 (或 无 拥有 装备)"
	var txt := "%d 部位 可改进:" % n
	var shown := 0
	for slot in SLOTS:
		if shown >= 5:
			break
		var bid: String = equip_best_id(slot)
		if bid == "" or str(equipped.get(slot, "")) == bid:
			continue
		var e: Dictionary = equip_by_id.get(bid, {})
		var cur: String = str(equipped.get(slot, ""))
		var cur_name: String = "无"
		if cur != "":
			var ce: Dictionary = equip_by_id.get(cur, {})
			if not ce.is_empty():
				cur_name = str(ce.get("name", ""))
		txt += "\n· %s: 换「%s」 (当前 %s)" % [str(SLOT_CN[slot]), str(e.get("name", "")), cur_name]
		shown += 1
	return txt

# 六段 明细 [领悟, 神通, 施展, 法器, 装备, 最佳] (只读; cat/tier 同 onekey_summary_vals)
func onekey_segment_tips(cat: String = "", tier: int = -1) -> Array:
	var tips: Array = []
	tips.append(_ok_tip_learn(cat, tier, false))
	tips.append(_ok_tip_learn(cat, tier, true))
	tips.append(_ok_tip_cast())
	tips.append(_ok_tip_item())
	tips.append(_ok_tip_equip())
	tips.append(_ok_tip_best())
	return tips

# ================= 打磨-10: 道行 (飞升后目标) =================

func dao_break_cost() -> float:
	return dao_break_cost_at(dao_level)

# 指定阶段的道行精进消耗 (打磨-33: 阶梯 ETA 路线按此估算, 不改动当前状态)
func dao_break_cost_at(d: int) -> float:
	return DAO_BREAK_BASE * pow(DAO_BREAK_GROWTH, float(d))

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

# 打磨-19: 顶栏主资源 (未飞升=灵气, 飞升后=道行; 灵石始终单列)
func primary_res_name() -> String:
	return "道行" if ascended else "灵气"

func primary_res_value() -> float:
	return dao if ascended else essence

func primary_res_text() -> String:
	return "%s %s" % [primary_res_name(), fmt(primary_res_value())]

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
		"auto_break": auto_break,  # 打磨-67: 自动突破开关 (旧档缺字段默认关)
		"auto_buy": auto_buy,      # 打磨-68: 自动购置开关 (旧档缺字段默认关)
		"auto_cast": auto_cast,    # 打磨-69: 自动施展开关 (旧档缺字段默认关)
		"auto_learn": auto_learn,  # 打磨-80: 自动领悟开关 (旧档缺字段默认关)
		"auto_tower": auto_tower,  # M5-3: 自动爬塔开关 (旧档缺字段默认关)
		# M5-2: 爬塔 状态 (旧档缺字段默认 0 / 未通关)
		"tower_fixed_floor": tower_fixed_floor,
		"tower_fixed_clear": tower_fixed_clear,
		"tower_endless_floor": tower_endless_floor,
		"tower_endless_best": tower_endless_best,
		"tower_daily_date": tower_daily_date,
		"tower_daily_bonus_stones": tower_daily_bonus_stones,
		"tower_clear_reward_got": tower_clear_reward_got,  # M5-4: 通关大奖已发放标记 (旧档缺字段默认 未发放)
		"poison_battles": poison_battles,
		# M6-2: DIY 词缀 (库存/装配/槽位升级; 旧档缺字段 默认 空)
		"affix_bag": affix_bag,
		"affix_load": affix_load,
		"slot_upgrades": slot_upgrades,
		"seen_affixes": seen_affixes,  # M6-3: 词缀 收集 (曾 入包; 旧档缺字段 默认 空)
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
	auto_break = bool(parsed.get("auto_break", false))  # 打磨-67: 自动突破开关 (旧档缺字段默认关)
	auto_buy = bool(parsed.get("auto_buy", false))      # 打磨-68: 自动购置开关 (旧档缺字段默认关)
	auto_cast = bool(parsed.get("auto_cast", false))    # 打磨-69: 自动施展开关 (旧档缺字段默认关)
	auto_learn = bool(parsed.get("auto_learn", false))  # 打磨-80: 自动领悟开关 (旧档缺字段默认关)
	auto_tower = bool(parsed.get("auto_tower", false))  # M5-3: 自动爬塔开关 (旧档缺字段默认关)
	# M5-2: 爬塔 状态 (旧档缺字段 默认 0 / 未通关 / 登天梯 从 1 层 起)
	tower_fixed_floor = clampi(int(parsed.get("tower_fixed_floor", 0)), 0, 1000)
	tower_fixed_clear = bool(parsed.get("tower_fixed_clear", false))
	tower_endless_floor = maxi(1, int(parsed.get("tower_endless_floor", 1)))
	tower_endless_best = maxi(0, int(parsed.get("tower_endless_best", 0)))
	tower_daily_date = str(parsed.get("tower_daily_date", ""))
	tower_daily_bonus_stones = float(parsed.get("tower_daily_bonus_stones", 0.0))
	tower_clear_reward_got = bool(parsed.get("tower_clear_reward_got", false))  # M5-4: 旧档缺字段默认 未发放 (首通 1000 层 Boss 时 正常 发放)
	poison_battles = clampi(int(parsed.get("poison_battles", 0)), 0, TOWER_POISON_BATTLES)
	# M6-2: DIY 词缀 (旧档缺字段 默认 空; 非法 项 丢弃 防 污染)
	# 顺序: 先 槽位升级 (affix_load 校验 依赖 槽位 上限), 再 库存, 最后 装配
	slot_upgrades = {}
	var su: Dictionary = parsed.get("slot_upgrades", {})
	if typeof(su) == TYPE_DICTIONARY:
		for k in su:
			if owned_eq.has(str(k)) and int(su[k]) >= 1:
				slot_upgrades[str(k)] = 1
	affix_bag = {}
	var ab: Dictionary = parsed.get("affix_bag", {})
	if typeof(ab) == TYPE_DICTIONARY:
		for k in ab:
			var v: int = int(ab[k])
			if v > 0 and affix_by_id.has(str(k)):
				affix_bag[str(k)] = v
	affix_load = {}
	var al: Dictionary = parsed.get("affix_load", {})
	if typeof(al) == TYPE_DICTIONARY:
		for k in al:
			var slots_v: Dictionary = al[k]
			if typeof(slots_v) != TYPE_DICTIONARY or not owned_eq.has(str(k)):
				continue
			var clean: Dictionary = {}
			for pos in slots_v:
				var aid: String = str(slots_v[pos])
				# 键 统一 字符串 (内存 装配 键 与 JSON 往返 口径 一致)
				if aid != "" and affix_by_id.has(aid) and int(clean.size()) < equipment_slots(str(k)) and not clean.has(str(pos)):
					clean[str(pos)] = aid
			if not clean.is_empty():
				affix_load[str(k)] = clean
	# M6-3: 词缀 收集 (旧档缺字段 默认 空; 非法 id 丢弃 防 污染)
	seen_affixes = []
	var sa: Dictionary = {}
	var sv: Variant = parsed.get("seen_affixes", [])
	if typeof(sv) == TYPE_ARRAY:
		for item in sv:
			if typeof(item) == TYPE_STRING and affix_by_id.has(str(item)):
				sa[str(item)] = true
	for k in sa:
		seen_affixes.append(str(k))
	# 登天梯 一致性: 当前 层 不 低于 历史 最高+1 的 防御 (断点 续爬)
	if tower_endless_floor < tower_endless_best + 1:
		tower_endless_floor = tower_endless_best + 1
	equipped = {}
	var eq: Dictionary = parsed.get("equipped", {})
	if typeof(eq) == TYPE_DICTIONARY:
		for slot in SLOTS:
			var id: String = eq.get(slot, "")
			if typeof(id) == TYPE_STRING and owned_eq.has(id):
				equipped[slot] = id
	# 离线收益
	_offline_sec = 0.0
	_offline_qi = 0.0
	_offline_stone = 0.0
	var ts := int(parsed.get("ts", 0))
	if ts > 0:
		var elapsed := clampf(Time.get_unix_time_from_system() - float(ts), 0.0, OFFLINE_CAP_SEC)
		if elapsed > 60.0:
			var rate := offline_rate()
			var gq := qi_per_sec() * elapsed * rate
			var gs := stone_per_sec() * elapsed * rate
			stones += gs
			# 打磨-66: 记录本次离线明细, 供启动金色浮动提示 (offline_float_text)
			_offline_sec = elapsed
			_offline_qi = gq
			_offline_stone = gs
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

# ---------- 打磨-24: 突破 ETA (主资源攒够突破耗时; 飞升后自动切换为道行精进 ETA) ----------

# 距主资源 (灵气/道行) 攒够突破消耗所需秒数: 0 = 现在即可突破; -1 = 无灵气收入 (防御, 正常恒不触发)
func breakthrough_eta_seconds() -> float:
	var need := 0.0
	var cur := 0.0
	if ascended:
		if dao_level >= IMMORTAL_REALMS.size() - 1:
			return 0.0
		need = dao_break_cost()
		cur = dao
	else:
		need = breakthrough_cost()
		cur = essence
	var gap := need - cur
	if gap <= 0.0:
		return 0.0
	var r: float = qi_per_sec()
	if r <= 0.0:
		return -1.0
	return gap / r

# 突破 ETA 文本 (修行页展示; "" = 现在可突破 / 已至道祖)
func breakthrough_eta_text() -> String:
	var t: float = breakthrough_eta_seconds()
	if t == 0.0:
		return ""
	if t < 0.0:
		return "无灵气收入"
	var prefix := "道行精进还需 " if ascended else "突破还需 "
	if t < 60.0:
		return prefix + "不足1分"
	return prefix + fmt_time(t)

# ---------- 打磨-36: 主突破成功率显示 (主资源突破/道行精进, 未飞升/飞升统一口径) ----------

# 主突破成功率统一接口: 未飞升 = 突破成功率 / 飞升后 = 道行精进成功率 (道祖封顶 = 1.0, 不再精进)
# 与浮动提示/按钮文案口径一致 (0.85-4%/境界 / 0.90-3%/阶段, 功法装备加成, 钳制 [0.05, 0.99])
func primary_break_chance() -> float:
	if not ascended:
		return breakthrough_chance()
	if dao_level >= IMMORTAL_REALMS.size() - 1:
		return 1.0
	return dao_break_chance()

# 主突破成功率文本 (修行页展示; 道祖封顶圆满)
func primary_break_chance_text() -> String:
	if ascended and dao_level >= IMMORTAL_REALMS.size() - 1:
		return "已至道祖 · 道法自然 ♪"
	var pct := int(round(primary_break_chance() * 100.0))
	return ("道行精进成功率 %d%%" if ascended else "突破成功率 %d%%") % pct

# ---------- 打磨-87: 顶栏主资源行 悬停 下一目标 动态 tooltip ----------
# 口径 (与 顶栏灵石行 tooltip 打磨-49 镜像, 但 主资源 侧; 复用 打磨-24/31/36/37 只读接口):
# 未飞升 = "下一目标  突破至 X 第 Y 层:  当前 X 灵气/秒 · 还差 N 灵气 (突破还需 T) · 突破成功率 P%";
# 飞升后 = 道行精进 口径 (当前 道行/秒 · 还差 N 道行 (道行精进还需 T) · 道行精进成功率 P%);
# 资源已足够 = "已攒够, 点击突破/修炼" (无 ETA/成功率); 道祖 封顶 = 圆满 文案 (无 下一目标);
# 无 主资源 收入 = 省略 ETA 标注 "当前无主资源收入".
# 纯 文本 只读: 不 改 状态/存档/统计 (供 UI 悬停 tooltip 动态 刷新, 文本 变化 才 写)
func primary_next_target_tip() -> String:
	var res_name := "道行" if ascended else "灵气"
	var rate := qi_per_sec()
	var rate_head := "当前 %s %s/秒" % [fmt(rate), res_name]
	if ascended and dao_level >= IMMORTAL_REALMS.size() - 1:
		return rate_head + "\n已至道祖 · 道法自然 ♪ (无 下一目标)"
	var need: float = dao_break_cost() if ascended else breakthrough_cost()
	var cur: float = dao if ascended else essence
	var goal: String
	if ascended:
		goal = "道行精进至 %s" % IMMORTAL_REALMS[dao_level + 1]
	else:
		goal = "突破至 %s" % next_realm_display()
	var gap := need - cur
	if gap <= 0.0:
		if ascended:
			return rate_head + ("\n%s %s已攒够, 点击修炼!" % [goal, res_name])
		return rate_head + ("\n%s 灵气已攒够, 点击突破!" % goal)
	var eta: String = breakthrough_eta_text()
	if breakthrough_eta_seconds() < 0.0:
		eta = "(当前无主资源收入)"
	var pct := int(round(primary_break_chance() * 100.0))
	var chance: String
	if ascended:
		chance = "道行精进成功率 %d%%" % pct
	else:
		chance = "突破成功率 %d%%" % pct
	return "%s\n%s 还差 %s %s (%s) · %s" % [rate_head, goal, fmt(gap), res_name, eta, chance]

# ---------- 打磨-37: 成功率构成 tooltip (成功率行的 +N% 来自哪) ----------

# 主突破成功率构成: base=境界(阶段)基础, skill/equip=功法/装备加成,
# clamp=钳制修正 (非0=被 5%~99% 受控区间钳制), chance=最终值 (与 primary_break_chance 一致),
# cap=道祖封顶 (圆满, 无失败风险)
func primary_break_chance_parts() -> Dictionary:
	if ascended and dao_level >= IMMORTAL_REALMS.size() - 1:
		return {"base": 1.0, "skill": 0.0, "equip": 0.0, "clamp": 0.0, "chance": 1.0, "cap": true}
	var base := (0.90 - 0.03 * float(dao_level)) if ascended else (0.85 - 0.04 * float(realm_idx))
	var sk := passive_bonus("bt_chance")
	var eq := equip_bonus("bt_chance")
	var raw := base + sk + eq
	var ch := clampf(raw, 0.05, 0.99)
	return {"base": base, "skill": sk, "equip": eq, "clamp": ch - raw, "chance": ch, "cap": false}

# 有符号百分比文本 (0 -> "+0.0%", 非0 -> "+5.0%"/"-1.5%")
func _signed_pct(v: float) -> String:
	if absf(v) < 0.005:
		return "+0.0%"
	return "%+.1f%%" % (v * 100.0)

# 打磨-63: 主突破 预期成本 (成功率 tooltip 末尾追加 期望次数/期望总消耗)
# 口径: 期望次数 = 1/P (1 位小数), 期望总消耗 = 单次消耗/P (fmt 口径, 失败全耗重攒).
# 未飞升=灵气 / 飞升后=道行 / 道祖封顶="" (圆满, 不再精进, tooltip 不追加). 只读无副作用.
func breakthrough_expect_text() -> String:
	var p: Dictionary = primary_break_chance_parts()
	if bool(p["cap"]):
		return ""
	var ch: float = clampf(float(p["chance"]), 0.05, 1.0)
	var pct := int(round(ch * 100.0))
	var res_name := "道行" if ascended else "灵气"
	var cost: float = dao_break_cost() if ascended else breakthrough_cost()
	return "· 期望次数 ~%.1f 次 (成功率 %d%%)\n· 期望总消耗 ~%s %s" % [1.0 / ch, pct, fmt(cost / ch), res_name]

# 打磨-64: 突破/道行精进 失败 浮动提示 文案 (含 本次消耗 + 预期成本, 复用 打磨-63 口径)
# 口径: "✖ 突破失败… ✖  本次耗 X 灵气 · 期望次数 ~N 次 · 期望总消耗 ~Y 灵气 (成功率 P%)";
# 飞升后 前缀=道行精进失败 / 口径=道行; 道祖封顶 (圆满 无失败) 返回 基础 失败文案 不追加.
# 只读无副作用 (不改动 状态/存档/统计).
func break_fail_float_text() -> String:
	var prefix: String = "✖ 道行精进失败… ✖" if ascended else "✖ 突破失败… ✖"
	var p: Dictionary = primary_break_chance_parts()
	if bool(p["cap"]):
		return prefix
	var ch: float = clampf(float(p["chance"]), 0.05, 1.0)
	var pct := int(round(ch * 100.0))
	var res_name: String = "道行" if ascended else "灵气"
	var cost: float = dao_break_cost() if ascended else breakthrough_cost()
	return "%s  本次耗 %s %s · 期望次数 ~%.1f 次 · 期望总消耗 ~%s %s (成功率 %d%%)" % [
		prefix, fmt(cost), res_name, 1.0 / ch, fmt(cost / ch), res_name, pct]

# 打磨-65: 突破/道行精进 成功 浮动提示 文案 (含 新境界 + 当前成功率, 与 打磨-64 失败浮动 互补)
# 口径: "✦ 突破成功! 晋升 %s (当前成功率 P%) ✦" (1=普通成功, 境界=突破后新境界);
# "☀ 飞升真仙! 仙凡两隔, 灵气 x100000 ☀" (3=飞升, 仙凡两隔 无成功率口径);
# "✦ 道行精进! 晋阶 %s (当前成功率 P%) ✦" (4=飞升后精进, 阶段=精进后新阶段).
# 只在 last_break_result 已置位后调用 (0=未触发 返回空串); 只读无副作用.
func break_ok_float_text() -> String:
	match last_break_result:
		1:
			var pct := int(round(primary_break_chance() * 100.0))
			return "✦ 突破成功! 晋升 %s (当前成功率 %d%%) ✦" % [realm_display(), pct]
		3:
			return "☀ 飞升真仙! 仙凡两隔, 灵气 x100000 ☀"
		4:
			var dpct := int(round(primary_break_chance() * 100.0))
			return "✦ 道行精进! 晋阶 %s (当前成功率 %d%%) ✦" % [IMMORTAL_REALMS[dao_level], dpct]
	return ""

# 成功率构成 tooltip 文本 (成功率行动态展示; 境界/阶段/功法装备变化才变)
# 打磨-63: 构成段 之后 追加 预期成本 两行 (期望次数/期望总消耗, 道祖封顶 不追加)
func primary_break_chance_tip() -> String:
	var p: Dictionary = primary_break_chance_parts()
	if bool(p["cap"]):
		return "已至道祖 · 道法自然 ♪\n道行圆满, 无失败风险。"
	var stage_name: String = (IMMORTAL_REALMS[dao_level] if ascended else (REALMS[realm_idx]["name"] as String))
	var prefix: String = "道行精进成功率" if ascended else "突破成功率"
	var pct := int(round(float(p["chance"]) * 100.0))
	var base_pct := int(round(float(p["base"]) * 100.0))
	var stage_word: String = "阶段" if ascended else "境界"
	var tail := "→ %d%% (受控区间 5%%~99%%" % pct
	if float(p["clamp"]) != 0.0:
		tail += " · 已钳制"
	var tip: String = "%s %d%% 构成:\n· %s (%s) 基础 %d%%\n· 功法 %s\n· 装备 %s\n%s)" % [
		prefix, pct, stage_word, stage_name, base_pct, _signed_pct(float(p["skill"])), _signed_pct(float(p["equip"])), tail]
	var expect := breakthrough_expect_text()
	if not expect.is_empty():
		tip += "\n" + expect
	return tip

# ---------- 打磨-31: 下一目标提示 (修行页: 玩家下一步该做什么) ----------

# 下一目标文本 (未飞升=攒灵气突破到下一层/境界, 飞升后=道行精进; 已至道祖=圆满)
# 目标名称 + 缺口 + 按当前速率的预计时间; 攒够时直接提示"可突破/可精进"
func next_goal_text() -> String:
	if not ascended:
		var need: float = breakthrough_cost()
		var gap: float = need - essence
		var goal_name := "突破至 %s" % next_realm_display()
		if gap <= 0.0:
			return "下一目标  %s  灵气已攒够, 点击突破!" % goal_name
		return "下一目标  %s  还差 %s 灵气 (%s)" % [goal_name, fmt(gap), breakthrough_eta_text()]
	if dao_level >= IMMORTAL_REALMS.size() - 1:
		return "下一目标  已至道祖, 道法自然 ♪"
	var d_need: float = dao_break_cost()
	var d_gap: float = d_need - dao
	var d_goal := "道行精进至 %s" % IMMORTAL_REALMS[dao_level + 1]
	if d_gap <= 0.0:
		return "下一目标  %s  道行已攒够, 点击修炼!" % d_goal
	return "下一目标  %s  还差 %s 道行 (%s)" % [d_goal, fmt(d_gap), breakthrough_eta_text()]

# 下一层/境界的展示名 (未飞升用: "练气 第 2 层" / "筑基 第 1 层")
func next_realm_display() -> String:
	var max_layer := REALMS[realm_idx]["layers"] as int
	if layer < max_layer:
		return "%s 第 %d 层" % [REALMS[realm_idx]["name"] as String, layer + 1]
	if realm_idx < REALMS.size() - 1:
		return "%s 第 1 层" % [REALMS[realm_idx + 1]["name"] as String]
	return "飞升真仙"

# ---------- 打磨-81: 下一目标进度比例 (顶栏渐变进度条) ----------

# 当前 下一目标 的主资源进度 0..1 (与 next_goal_text 同目标口径: 未飞升=下一层/下一境界
# 突破消耗, 飞升后=道行精进 消耗, 资源>=消耗 恒 1.0; 道祖封顶 恒 1.0). 只读无副作用.
func next_goal_ratio() -> float:
	if ascended:
		if dao_level >= IMMORTAL_REALMS.size() - 1:
			return 1.0
		return clampf(dao / dao_break_cost(), 0.0, 1.0)
	return clampf(essence / breakthrough_cost(), 0.0, 1.0)

# ---------- 打磨-32: 突破按钮"可突破"状态 (资源攒够时 UI 金边高亮引导点击) ----------

# 当前是否已可点击突破/精进 (资源 >= 突破消耗且未封顶; 封顶恒 false, 按钮保持禁用)
func breakthrough_ready() -> bool:
	if ascended:
		if dao_level >= IMMORTAL_REALMS.size() - 1:
			return false
		return dao >= dao_break_cost()
	return essence >= breakthrough_cost()

# ---------- 打磨-33: 境界阶梯 ETA 路线 (按当前速率估算各境界/道行阶段累计耗时) ----------

const LADDER_ETA_CAP_SEC := 7.0 * 86400.0   # 显示上限 7 天 (>= 显示"8天+", 防无限期误导)

# 到达某境界(第 1 层)所需的 累计灵气消耗 (当前境界/层之后, 全部突破成功口径; 已含当前层)
# 返回 -1 = 目标不可达 (越界); 当前/已达成境界 = 0
func realm_ladder_eta(target_realm: int) -> float:
	if not ascended:
		if target_realm < realm_idx or target_realm >= REALMS.size():
			return -1.0
		if target_realm == realm_idx:
			return 0.0
		var total := 0.0
		# 当前境界: 从 当前层 逐层突破到 顶层
		var layers := REALMS[realm_idx]["layers"] as int
		for l in range(layer, layers + 1):
			total += breakthrough_cost_at(realm_idx, l)
		# 中间境界: 第 1 层 逐层突破到 顶层
		for r in range(realm_idx + 1, target_realm):
			var ll := REALMS[r]["layers"] as int
			for l in range(1, ll + 1):
				total += breakthrough_cost_at(r, l)
		return total
	# 已飞升: 凡境阶梯已走完 (全部视为已达成)
	return 0.0

# 到达某道行阶段所需的 累计道行消耗 (当前阶段之后, 全部精进成功口径)
# 阶段 d 的精进消耗 = dao_break_cost_at(d) (从 d 升到 d+1); 目标=当前阶段 = 0
# 返回 -1 = 目标不可达 (越界)
func dao_ladder_eta(target_stage: int) -> float:
	if target_stage < dao_level or target_stage >= IMMORTAL_REALMS.size():
		return -1.0
	if target_stage == dao_level:
		return 0.0
	var total := 0.0
	for d in range(dao_level, target_stage):
		total += dao_break_cost_at(d)
	return total

# 阶梯行 ETA 文本: "" = 已达成/当前 (不显示); "约 X" 按当前速率; "8天+" = 超 7 天显示上限
# 已达成行 (目标在当前之下) 返回 "" (UI 自行加"已达成"标注)
func ladder_eta_text(sec: float) -> String:
	if sec < 0.0 or sec == 0.0:
		return ""
	var t := minf(sec, LADDER_ETA_CAP_SEC)
	if t >= LADDER_ETA_CAP_SEC:
		return "8天+"
	if t < 60.0:
		return "约不足1分"
	if t < 3600.0:
		return "约 %d分" % int(t / 60)
	var d := int(t) / 86400
	var h := int(t) % 86400 / 3600
	if d == 0:
		return "约 %d小时" % h
	if h > 0:
		return "约%d天%d小时" % [d, h]
	return "约%d天" % d

# 境界阶梯行 ETA (修行页右栏; 未飞升=灵气口径, 飞升后=道行口径)
# 未达成行按当前速率估算 累计耗时 (含当前库存抵扣, 突破失败重耗不建模, tooltip 说明)
func ladder_row_eta(kind: String, target: int) -> String:
	var sec := 0.0
	var r: float = qi_per_sec()
	if kind == "realm":
		sec = realm_ladder_eta(target)
	elif kind == "dao":
		sec = dao_ladder_eta(target)
	else:
		return ""
	if sec < 0.0:
		return ""
	# 当前库存抵扣: 已有灵气/道行 先抵给路线 (估算保守口径: 失败不重耗)
	var have := dao if kind == "dao" else essence
	sec = maxf(sec - have, 0.0)
	if sec == 0.0:
		return ""
	if r <= 0.0:
		return "8天+"   # 无收入防御 (正常恒不触发): 按上限显示, 不误导
	return ladder_eta_text(sec / r)

# ---------- 打磨-34: 境界阶梯当前层进度 (当前境界行内 层数位置 + 突破资源) ----------

# 当前境界的层内进度 (未飞升): "第 X/Y 层 · 突破需 X 灵气 (当前 X)"
# 未飞升才有层内进度; 飞升后返回 "" (仙界按阶段行展示, 无层概念)
func ladder_current_progress_text() -> String:
	if ascended:
		return ""
	var max_layer := REALMS[realm_idx]["layers"] as int
	var cost := breakthrough_cost()
	return "第 %d/%d 层 · 突破需 %s 灵气 (当前 %s)" % [
		layer, max_layer, fmt(cost), fmt(essence)]

# ---------- 打磨-35: 当前道行阶段消耗提示 (飞升后阶梯行, 与打磨-34 层内进度口径对齐) ----------

# 道行阶段进度 (飞升后): "道行精进需 X 道行 (当前 X)"
# 道祖封顶: "已至道祖, 道法自然 ♪"; 未飞升返回 "" (阶梯无道行行, UI 隐藏标签)
func dao_progress_text() -> String:
	if not ascended:
		return ""
	if dao_level >= IMMORTAL_REALMS.size() - 1:
		return "已至道祖, 道法自然 ♪"
	var cost := dao_break_cost()
	return "道行精进需 %s 道行 (当前 %s)" % [fmt(cost), fmt(dao)]
