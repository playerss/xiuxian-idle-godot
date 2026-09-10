#!/usr/bin/env python3
"""修仙挂机 · 数据生成器（确定性，固定种子，可重跑）
产出 data/skills.json (120) 与 data/equipment.json (140)。
"""
import json, os, random

random.seed(20260902)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")
os.makedirs(DATA, exist_ok=True)

# ============ 品质 ============
SKILL_TIERS = ["凡品", "灵品", "玄品", "地品", "天品", "仙品"]        # 6 档
EQUIP_TIERS = ["凡品", "灵品", "玄品", "地品", "天品", "仙品", "神品"]  # 7 档

# ============ 成就 (打磨-6: Steam 上架准备, 数据驱动) ============
# Steam 成就 id 必须为 [a-zA-Z0-9_]+, 定义与解锁判定 (game_data.check_achievements) 按 id 对齐
ACHIEVEMENTS = [
    # 境界里程碑 (realm_idx 0..9)
    {"id": "realm_zhuji",      "name": "筑基",     "desc": "突破至筑基期"},
    {"id": "realm_jindan",     "name": "结丹",     "desc": "突破至金丹期"},
    {"id": "realm_yuanying",   "name": "元婴初现", "desc": "突破至元婴期"},
    {"id": "realm_huashen",    "name": "化神",     "desc": "突破至化神期"},
    {"id": "realm_luexu",      "name": "炼虚",     "desc": "突破至炼虚期"},
    {"id": "realm_het",        "name": "合体",     "desc": "突破至合体期"},
    {"id": "realm_dacheng",    "name": "大乘",     "desc": "突破至大乘期"},
    {"id": "realm_dujie",      "name": "渡劫",     "desc": "突破至渡劫期"},
    {"id": "ascend_immortal",  "name": "飞升",     "desc": "飞升真仙界, 仙凡两隔"},
    # 玩法进度
    {"id": "first_break",      "name": "初次突破", "desc": "首次成功突破"},
    {"id": "first_item",       "name": "第一件法器", "desc": "购入第一件法器"},
    {"id": "skill_10",         "name": "小有小成", "desc": "领悟 10 个技能"},
    {"id": "skill_50",         "name": "博闻强记", "desc": "领悟 50 个技能"},
    {"id": "equip_first",      "name": "初具规模", "desc": "购入第一件装备"},
    {"id": "equip_10",         "name": "行头齐全", "desc": "购入 10 件装备"},
    {"id": "rich_100k",      "name": "灵石满堂", "desc": "持有灵石达 10 万"},
    {"id": "dao_zuzi",         "name": "道祖",     "desc": "道行精进至道祖境"},
    # M5-2: 爬塔成就 (8 项: 镇妖塔 3 + 登天梯 4 + 首通 1)
    {"id": "tower_100",        "name": "小有名气", "desc": "镇妖塔 登上 100 层"},
    {"id": "tower_500",        "name": "声名鹊起", "desc": "镇妖塔 登上 500 层"},
    {"id": "tower_clear",      "name": "镇妖塔·通关者", "desc": "镇妖塔 登遍 1000 层"},
    {"id": "endless_100",      "name": "登天启程", "desc": "登天梯 登上 100 层"},
    {"id": "endless_500",      "name": "天阶在望", "desc": "登天梯 登上 500 层"},
    {"id": "endless_1000",     "name": "百步穿云", "desc": "登天梯 登上 1000 层"},
    {"id": "endless_5000",     "name": "问鼎登天", "desc": "登天梯 登上 5000 层"},
    {"id": "first_tower",      "name": "初入塔门", "desc": "首次通过任意塔一层"},
]
# 境界里程碑 id 与 REALMS 索引的对应 (realm_xxx -> realm_idx)
ACH_REALM_IDX = {"realm_zhuji": 1, "realm_jindan": 2, "realm_yuanying": 3,
                 "realm_huashen": 4, "realm_luexu": 5, "realm_het": 6,
                 "realm_dacheng": 7, "realm_dujie": 8}

def gen_achievements():
    out = []
    for a in ACHIEVEMENTS:
        out.append(dict(a))
    return out

# ============ 技能 ============
# 每档属性池（越高档越稀有），每类 4 变体各取不同属性
SKILL_ATTR = {
    0: ["木", "青", "石", "铁"],
    1: ["灵", "玉", "翠", "风"],
    2: ["玄", "紫", "幽", "雷"],
    3: ["地", "岩", "焰", "赤"],
    4: ["天", "星", "月", "云"],
    5: ["仙", "神", "圣", "道"],
}
# 5 大类 × 4 核心词
SKILL_CATS = {
    "sword":  ("剑法", ["剑法", "剑诀", "剑意", "剑典"]),
    "spell":  ("法术", ["雷术", "火诀", "冰咒", "风经"]),
    "mind":   ("心法", ["凝神诀", "吐纳功", "静心经", "归元要"]),
    "body":   ("身法", ["踏云步", "凌波遁", "无影身", "追风轻功"]),
    "divine": ("神通", ["金刚身", "法天术", "须弥诀", "乾坤法"]),
}
# 被动效果池（权重随机），主动神通固定 qi_burst
# M5-2: 新增 atk/def 池 (爬塔战力; 与 灵气/灵石/突破/离线 同 乘算独立 口径 1+Σ)
PASSIVE_EFFECTS = ["qi_mult", "stone_mult", "bt_chance", "offline_rate", "all_mult"]
# M5-2: 攻击/防御 独立 属性池 (爬塔 战力; 与 灵气/灵石/突破/离线 主效果 解耦, 不占 主 效果 循环,
# 使 旧 功法 效果 分配 不 变 [sword_5_2 仍 bt_chance 等 受测 技能 效果 保持], 仅 追加 atk/def 字段)
SKILL_CAT_ATKDEF = {
    "sword":  (3.0, 1.0),   # 剑法 偏 攻击
    "spell":  (3.0, 1.0),   # 法术 偏 攻击
    "mind":   (1.0, 3.0),   # 心法 偏 防御
    "body":   (1.0, 3.0),   # 身法 偏 防御
    "divine": (2.0, 2.0),   # 神通 均衡
}
EFFECT_CN = {
    "qi_mult": "灵气速率 +{v}%",
    "stone_mult": "灵石速率 +{v}%",
    "bt_chance": "突破成功率 +{v}%",
    "offline_rate": "离线效率 +{v}%",
    "all_mult": "灵气/灵石速率 +{v}%",
}
# 品质 -> 被动加成基数(%) / 解锁境界
TIER_BASE_PCT = [3, 8, 15, 25, 40, 70]
TIER_UNLOCK_REALM = [0, 1, 2, 3, 4, 5]
# 品质 -> 主动神通爆发秒数 / 冷却
TIER_BURST = [60, 120, 240, 420, 700, 1200]
TIER_CD = [90, 150, 240, 420, 700, 1200]

def gen_skills():
    skills, used = [], set()
    for cat, (cat_cn, cores) in SKILL_CATS.items():
        for tier in range(len(SKILL_TIERS)):
            for v in range(4):
                name = SKILL_ATTR[tier][v] + cores[v]
                # 保证全局唯一
                base = name
                k = 1
                while name in used:
                    name = f"{base}·{'甲乙丙丁'[k%4]}"; k += 1
                used.add(name)
                sid = f"{cat}_{tier}_{v}"
                # 约 2/3 被动, 1/3 主动神通
                is_active = (tier % 2 == 0 and v == 3) or (cat == "divine" and v in (2, 3))
                if is_active:
                    burst, cd = TIER_BURST[tier], TIER_CD[tier]
                    skills.append({
                        "id": sid, "name": name, "category": cat, "category_name": cat_cn,
                        "tier": tier, "tier_name": SKILL_TIERS[tier], "type": "active",
                        "effect": "qi_burst", "value": burst, "cooldown": cd,
                        "unlock_realm": TIER_UNLOCK_REALM[tier], "unlock_layer": 1,
                        "desc": f"爆发: 瞬间获得 {burst} 秒灵气, 冷却 {cd} 秒",
                    })
                else:
                    eff = PASSIVE_EFFECTS[(tier + v + (0 if cat != "divine" else 1)) % len(PASSIVE_EFFECTS)]
                    pct = TIER_BASE_PCT[tier] + v * 2
                    # M5-2: atk/def 独立 属性池 (乘算 加成, 与 主 效果 解耦; 类别 攻/防 偏向, 随 品质/变体 上升)
                    sa, sd = SKILL_CAT_ATKDEF[cat]
                    sk_atk = round((0.02 + 0.05 * tier + 0.02 * v) * sa, 3)
                    sk_def = round((0.02 + 0.05 * tier + 0.02 * v) * sd, 3)
                    skills.append({
                        "id": sid, "name": name, "category": cat, "category_name": cat_cn,
                        "tier": tier, "tier_name": SKILL_TIERS[tier], "type": "passive",
                        "effect": eff, "value": round(pct / 100.0, 3),
                        "atk": sk_atk, "def": sk_def,
                        "unlock_realm": TIER_UNLOCK_REALM[tier], "unlock_layer": (v % 3) + 1,
                        "desc": EFFECT_CN[eff].format(v=pct),
                    })
    return skills

# ============ 装备 ============
EQUIP_SLOTS = {
    "weapon": ("武器", ["剑", "刀", "枪", "戟", "尺", "扇"]),
    "robe":   ("法袍", ["法袍", "道袍", "灵衣", "天裳", "战甲", "羽衣"]),
    "amulet": ("玉佩", ["玉佩", "灵符", "仙印", "法铃", "宝坠", "神环"]),
    "bead":   ("灵珠", ["灵珠", "宝珠", "天珠", "金丹", "仙珠", "道珠"]),
    "boot":   ("云靴", ["云靴", "天履", "仙履", "风靴", "踏云靴", "凌波履"]),
}
EQUIP_ATTR = {
    0: ["木", "铁", "石", "铜"],
    1: ["灵", "玉", "翠", "青"],
    2: ["玄", "紫", "幽", "雷"],
    3: ["岩", "焰", "赤", "地"],
    4: ["天", "星", "月", "云"],
    5: ["仙", "神", "圣", "道"],
    6: ["混沌", "太古", "太初", "鸿蒙"],
}
# 打磨-4: 后期价格曲线调平 —— 各档约 x5, 与灵石速率的境界增幅 (~x2.5~4) 匹配,
# 保证每升一档的购买耗时约为上一档的 1.5~2 倍 (旧曲线 x8 导致 仙品/神品 需数小时~十几小时)
EQUIP_BASE_COST = [100, 500, 2500, 12000, 60000, 300000, 1500000]
# M5-2: 装备 atk/def 属性池 (爬塔战力; 武器偏攻, 法袍/云靴偏防, 玉佩/灵珠均衡)
EQUIP_SLOT_ATKDEF = {
    "weapon": (1.0, 0.2),
    "robe":   (0.2, 1.0),
    "amulet": (0.6, 0.6),
    "bead":   (0.7, 0.4),
    "boot":   (0.3, 0.7),
}

def gen_equipment():
    eq, used = [], set()
    for slot, (slot_cn, cores) in EQUIP_SLOTS.items():
        for tier in range(len(EQUIP_TIERS)):
            for v in range(4):
                name = EQUIP_ATTR[tier][v] + cores[v]
                base = name
                k = 1
                while name in used:
                    name = f"{base}·{'甲乙丙丁'[k%4]}"; k += 1
                used.add(name)
                eid = f"{slot}_{tier}_{v}"
                # 属性: 随品质/变体线性增长
                qi = round(0.05 + 0.10 * tier + 0.03 * v, 3)
                stone = round(0.03 + 0.06 * tier + 0.02 * v, 3)
                bt = round(0.0 + 0.005 * tier + 0.003 * v, 4) if v % 2 == 0 else 0.0
                off = round(0.0 + 0.01 * tier + 0.005 * v, 4) if v % 2 == 1 else 0.0
                cost = int(EQUIP_BASE_COST[tier] * (1 + 0.25 * v))
                # M5-2: atk/def 乘算独立加成 (与 qi/stone 同梯度, 部位偏向 攻/防)
                sa, sd = EQUIP_SLOT_ATKDEF[slot]
                atk = round((0.05 + 0.10 * tier + 0.03 * v) * sa, 3)
                dfn = round((0.05 + 0.10 * tier + 0.03 * v) * sd, 3)
                eq.append({
                    "id": eid, "name": name, "slot": slot, "slot_name": slot_cn,
                    "tier": tier, "tier_name": EQUIP_TIERS[tier], "cost": cost,
                    "qi_mult": qi, "stone_mult": stone, "bt_chance": bt, "offline_rate": off,
                    "atk": atk, "def": dfn,
                    "desc": f"灵气+{qi*100:.0f}% 灵石+{stone*100:.0f}% 攻击+{atk*100:.0f}% 防御+{dfn*100:.0f}% 突破+{bt*100:.1f}% 离线+{off*100:.1f}%",
                })
    return eq

# ============ M5 爬塔: 特性 / 怪物 / 塔表 (M5-1 数据层) ============
# 设计见 PROJECT_PLAN.md「新特性: M5 爬塔系统」。
# 规模: 145 怪物 = 120 普通怪物种 (6 大类 x 20 种, tier 1~4) + 25 专属 Boss。
# Boss 分布 (1000 层, 每 50 层一个 Boss 层):
#   - 20 小 Boss: 每 50 层各占其一 (50/100/.../1000), 数值 x10, 掉落 x5
#   - 4 主题 Boss: 第 100/250/500/750 层, 数值 x20 (该层实际出战的是主题 Boss)
#   - 1 最终 Boss「镇妖塔主」: 第 1000 层, 数值 x50
#   注: 100/250/500/750/1000 层的小 Boss 实体不出战固定塔,
#       留作登天梯每 100 层天阶里程碑 Boss 池 (M5-3 接入)。
# 固定种子独立 RNG (20260910), 不与技能/装备生成器共享随机流。
TOWER_RNG_SEED = 20260910

# 18 特性 (id, 名称, 组, 说明)。组: 强化/削弱/奖励/特殊。
TRAIT_DEFS = [
    ("regen",         "再生",     "强化", "有效 HP x1.3"),
    ("drain",         "汲取",     "强化", "有效 HP x1.25"),
    ("split",         "分身",     "强化", "有效 HP x1.8"),
    ("swift",         "迅捷",     "强化", "有效 ATK x1.3"),
    ("enrage",        "狂暴",     "强化", "ATK x1.5 但 HP x0.9"),
    ("thorn_skin",    "石肤",     "削弱", "有效 DEF x1.5"),
    ("heavy",         "重甲",     "削弱", "DEF x2 但 ATK x0.8"),
    ("shield",        "护盾",     "削弱", "DEF +10 (固定值)"),
    ("counter",       "反噬",     "削弱", "玩家伤害 x0.85"),
    ("stealth",       "隐匿",     "削弱", "玩家伤害 x0.9"),
    ("poison",        "剧毒",     "削弱", "战胜后玩家 ATK -15%, 持续 2 场战斗 (可刷新)"),
    ("rich_ore",      "富矿",     "奖励", "灵石奖励 x2"),
    ("mat_bag",       "材料囊",   "奖励", "材料奖励 x2"),
    ("affix_bag",     "词缀袋",   "奖励", "词缀掉率 +10%"),
    ("lucky",         "幸运",     "奖励", "50% 概率全奖励 x2"),
    ("indomit",       "不屈",     "奖励", "全奖励 x1.2"),
    ("weak",          "虚弱",     "奖励", "HP x0.7 (轻松层)"),
    ("heaven_grudge", "天怨",     "特殊", "仅无尽塔生效, HP x(1+层数/400)"),
]
# 数值倍率字段 (M5-2 战斗计算直接消费; 缺省 1.0 = 无影响)
TRAIT_MULT = {
    "regen":         {"hp": 1.3},
    "drain":         {"hp": 1.25},
    "split":         {"hp": 1.8},
    "swift":         {"atk": 1.3},
    "enrage":        {"atk": 1.5, "hp": 0.9},
    "thorn_skin":    {"def": 1.5},
    "heavy":         {"def": 2.0, "atk": 0.8},
    "shield":        {"shield_add": 10.0},
    "counter":       {"p_dmg": 0.85},
    "stealth":       {"p_dmg": 0.9},
    "poison":        {"atk_debuff": 0.15, "debuff_battles": 2},
    "rich_ore":      {"stone": 2.0},
    "mat_bag":       {"mat": 2.0},
    "affix_bag":     {"affix_drop": 0.10},
    "lucky":         {"all_reward": 2.0, "lucky_chance": 0.5},
    "indomit":       {"all_reward": 1.2},
    "weak":          {"hp": 0.7},
    "heaven_grudge": {"heaven_grudge": 1.0},
}
TRAIT_GROUP = {tid: grp for tid, _, grp, _ in TRAIT_DEFS}
ENHANCE_TRAITS = [t for t, _, g, _ in TRAIT_DEFS if g == "强化"]
REWARD_TRAITS = [t for t, _, g, _ in TRAIT_DEFS if g in ("奖励", "特殊")]

# 6 大类 x (5 前缀 x 4 种类) = 120 种; 种类词跨类互斥保证全表唯一
MONSTER_CATS = {
    "demon_beast":  ("妖兽", ["黑风", "血影", "雷翼", "冰寒", "骨霜"], ["狼", "虎", "蛇", "狐"]),
    "ghost_cult":   ("鬼修", ["九幽", "鬼焰", "失魂", "夜雾", "白骨"], ["魂", "鬼", "煞", "魅"]),
    "insect_swarm": ("虫群", ["灰烬", "埋沙", "雷殛", "血沸", "星坠"], ["蝗", "蜂", "甲", "螳"]),
    "spirit_fiend": ("精怪", ["铜", "铁", "玉", "石", "炎"], ["灯", "铃", "镜", "笔"]),
    "fierce_soul":  ("凶灵", ["炽", "夜嚎", "天晦", "地朽", "噬灵"], ["魍", "魉", "魔女", "无头"]),
    "heaven_beast": ("天兽", ["星陨", "天裂", "云崩", "穹断", "御天"], ["龙", "麒麟", "凤", "玄武"]),
}
# 属性偏向: 血牛 HPx1.5 / 狂攻 ATKx1.5 / 铁壁 DEFx2 / 均衡 x1
BIAS_TYPES = ["hp", "atk", "def", "balanced"]
BIAS_MULT = {"hp": (1.5, 1.0, 1.0), "atk": (1.0, 1.5, 1.0),
             "def": (1.0, 1.0, 2.0), "balanced": (1.0, 1.0, 1.0)}
BIAS_CN = {"hp": "血牛型", "atk": "狂攻型", "def": "铁壁型", "balanced": "均衡型"}

# 25 专属 Boss 命名 (小 Boss 按 50 层起每 50 层序; 无「·」避免与塔层名冲突)
SMALL_BOSS_NAMES = ["石心巨熊", "雷鳞犀王", "九幽毒蟾", "寒霜白狐", "沸血铁牛",
                    "幽冥火鸦", "枯骨战马", "裂空巨鹏", "朽木树灵", "熔岩巨魔",
                    "霜骨枭王", "沙暴鼠君", "血毒蝎后", "魂灯魅主", "陨星猿魔",
                    "雾影幽狐", "刺骨蜈蚣", "炎爪獬豸", "幽魂蟒尊", "雷翼凤枭"]
THEME_BOSS = {100: ("万幻妖殿主", "demon_hall"), 250: ("幽冥魂帝", "nether"),
              500: ("破天魔君", "sky_break"), 750: ("万魔阵主", "myriad_devil")}
FINAL_BOSS_NAME = "镇妖塔主"

def gen_monster_traits():
    out = []
    for tid, name, grp, desc in TRAIT_DEFS:
        out.append({"id": tid, "name": name, "group": grp, "desc": desc,
                    "mult": TRAIT_MULT[tid]})
    return out

def _pick_traits(rng, n):
    """种子随机取 n 个不重复特性"""
    pool = [t for t, _, _, _ in TRAIT_DEFS]
    rng.shuffle(pool)
    return pool[:n]

def gen_monsters(rng):
    monsters = []
    # --- 120 普通怪物种: 每类 5 前缀 x 4 种类; i//5 = 种类 -> tier 1~4 ---
    for cat, (cat_cn, prefs, specs) in MONSTER_CATS.items():
        for i in range(20):
            name = f"{prefs[i % 5]}·{specs[i // 5]}"
            tier = 1 + i // 5
            n_tr = 1 if rng.random() < 0.4 else 2
            bias = rng.choice(BIAS_TYPES)
            bh, ba, bd = BIAS_MULT[bias]
            monsters.append({
                "id": f"m{len(monsters) + 1:02d}", "name": name, "kind": "species",
                "category": cat, "category_name": cat_cn, "tier": tier,
                "bias": bias, "bias_cn": BIAS_CN[bias],
                "b_hp": bh, "b_atk": ba, "b_def": bd,
                "traits": _pick_traits(rng, n_tr),
                "reward": {"stone_w": round(rng.uniform(0.8, 1.4), 3),
                           "mat_w": round(rng.uniform(0.5, 1.2), 3),
                           "affix_w": round(rng.uniform(0.2, 0.8), 3)},
            })
    # --- 25 专属 Boss: 20 小 (每 50 层) + 4 主题 + 1 最终; 各 2 特性 (1 强化 + 1 奖励/特殊) ---
    for i in range(20):
        monsters.append({
            "id": f"b{i + 1:02d}", "name": SMALL_BOSS_NAMES[i], "kind": "boss",
            "boss_type": "small", "floor": 50 * (i + 1), "mult": 10.0,
            "traits": [ENHANCE_TRAITS[i % 5], REWARD_TRAITS[(i * 3 + 1) % len(REWARD_TRAITS)]],
        })
    for j, (fl, (bname, theme)) in enumerate(THEME_BOSS.items()):
        monsters.append({
            "id": f"b{21 + j:02d}", "name": bname, "kind": "boss",
            "boss_type": "theme", "floor": fl, "mult": 20.0, "theme": theme,
            "traits": [ENHANCE_TRAITS[(j + 2) % 5], REWARD_TRAITS[(j * 2 + 3) % len(REWARD_TRAITS)]],
        })
    monsters.append({
        "id": "b25", "name": FINAL_BOSS_NAME, "kind": "boss",
        "boss_type": "final", "floor": 1000, "mult": 50.0, "theme": "final",
        "traits": ["enrage", "lucky"],
    })
    # 特性覆盖保证: 每特性至少 3 种怪物使用 (不足则确定性补到 特性数<2 的怪物种)
    use = {}
    for m in monsters:
        for tr in m["traits"]:
            use[tr] = use.get(tr, 0) + 1
    species = [m for m in monsters if m["kind"] == "species"]
    for tr in [t for t, _, _, _ in TRAIT_DEFS]:
        while use.get(tr, 0) < 3:
            host = next((m for m in species if tr not in m["traits"] and len(m["traits"]) < 2), None)
            assert host is not None, f"特性 {tr} 覆盖不足且无可用怪物种"
            host["traits"].append(tr)
            use[tr] = use.get(tr, 0) + 1
    return monsters

# 塔层名 1000 个唯一: 36 前缀 x 30 种类 = 1080 组合, 种子洗牌取 980 (非 Boss 层) + 20 Boss 名
TOWER_PREFS = ["暮岚", "血潮", "雷嶂", "冰髓", "瘴骨", "幽冥眼", "熔砂", "岩隙", "阴翳", "穹崖",
               "魔渊", "夺魂", "流星", "裂云", "刺棘", "沸血", "枯木", "霜咬", "埋沙", "蚀水",
               "游星", "震雷", "鬼氛", "魔啸", "裂穹", "崩地", "夜霭", "染血", "皓骨", "失魄",
               "坠星", "晦天", "朽地", "夜魆", "流焰", "穹渊"]
TOWER_SPKS = ["狼", "虎", "蟒", "狐", "熊", "蝎", "蛛", "蝠", "鼠", "蟾",
              "蜥", "鳄", "鹿", "犀牛", "枭", "鹰", "鹤", "猿", "兔", "鼬",
              "鼹", "蜈蚣", "螳螂", "甲虫", "鳝", "蛙", "鸦", "猩", "蛟", "豨"]

# 镇妖塔数值公式 (数据驱动, 落表)
TOWER_HP_BASE, TOWER_HP_GROWTH = 5.0, 1.055
TOWER_ATK_BASE, TOWER_ATK_GROWTH = 2.0, 1.055
TOWER_DEF_BASE, TOWER_DEF_GROWTH = 1.0, 1.04
TOWER_STONE_BASE, TOWER_STONE_GROWTH = 10.0, 1.06
TOWER_ELITE_MULT, TOWER_ELITE_REWARD = 3.0, 2
TOWER_BOST_MULTS = {"small": 10.0, "theme": 20.0, "final": 50.0}
TOWER_BOST_REWARD = 5
# M5-2: 登天梯 (无尽塔) 公式 — 底数 1.06 略高于 镇妖塔 1.055, 越打越难 无上限;
# 每 100 层 天阶里程碑 (小 Boss 池轮转 + 宝箱), 奖励指数同 镇妖塔 口径
ENDLESS_HP_BASE, ENDLESS_HP_GROWTH = 5.0, 1.06
ENDLESS_ATK_BASE, ENDLESS_ATK_GROWTH = 2.0, 1.06
ENDLESS_DEF_BASE, ENDLESS_DEF_GROWTH = 1.0, 1.04
ENDLESS_STONE_BASE, ENDLESS_STONE_GROWTH = 10.0, 1.06
ENDLESS_MILESTONE_FLOOR = 100

def gen_tower_floors(rng, monsters):
    by_id = {m["id"]: m for m in monsters}
    boss_at = {m["floor"]: m for m in monsters if m["kind"] == "boss" and m["boss_type"] != ""}
    # 每层怪物种按 tier 段位: 1-250 -> tier1, 251-500 -> tier2, 501-750 -> tier3, 751-1000 -> tier4
    tier_pool = {}
    for tier in range(1, 5):
        tier_pool[tier] = [m["id"] for m in monsters
                           if m["kind"] == "species" and m["tier"] == tier]
    name_pool = [f"{p}·{s}" for p in TOWER_PREFS for s in TOWER_SPKS]
    rng.shuffle(name_pool)
    it = iter(name_pool)
    floors = []
    for fl in range(1, 1001):
        base_hp = TOWER_HP_BASE * (TOWER_HP_GROWTH ** fl)
        base_atk = TOWER_ATK_BASE * (TOWER_ATK_GROWTH ** fl)
        base_def = TOWER_DEF_BASE * (TOWER_DEF_GROWTH ** fl)
        reward_mult = 1
        btype = ""
        if fl in boss_at:
            bm = boss_at[fl]
            btype = bm["boss_type"]
            name, traits = bm["name"], list(bm["traits"])
            b_hp = b_atk = b_def = 1.0
            struct = TOWER_BOST_MULTS[btype]
            reward_mult = TOWER_BOST_REWARD
            species_id, is_elite = "", False
        else:
            tier = 1 if fl <= 250 else 2 if fl <= 500 else 3 if fl <= 750 else 4
            species_id = rng.choice(tier_pool[tier])
            sm = by_id[species_id]
            is_elite = (fl % 10 == 0)
            traits = list(sm["traits"])
            if is_elite:
                extra = _pick_traits(rng, 1)
                extra = extra[0] if extra[0] not in traits else _pick_traits(rng, 1)[0]
                while extra in traits:
                    extra = rng.choice([t for t, _, _, _ in TRAIT_DEFS])
                traits.append(extra)
            name = "魔化·" + next(it) if is_elite else next(it)
            b_hp, b_atk, b_def = sm["b_hp"], sm["b_atk"], sm["b_def"]
            struct = TOWER_ELITE_MULT if is_elite else 1.0
            if is_elite:
                reward_mult = TOWER_ELITE_REWARD
        floors.append({
            "floor": fl, "name": name, "species": species_id, "traits": traits,
            "is_elite": is_elite, "boss_type": btype,
            "b_hp": b_hp, "b_atk": b_atk, "b_def": b_def,
            "base_hp": base_hp, "base_atk": base_atk, "base_def": base_def,
            "hp": base_hp * struct * b_hp, "atk": base_atk * struct * b_atk,
            "def": base_def * struct * b_def,
            "reward_stone": TOWER_STONE_BASE * (TOWER_STONE_GROWTH ** fl) * reward_mult,
            "reward_mult": reward_mult,
        })
    return floors

def main():
    skills = gen_skills()
    equipment = gen_equipment()
    achievements = gen_achievements()
    tower_rng = random.Random(TOWER_RNG_SEED)
    traits = gen_monster_traits()
    monsters = gen_monsters(tower_rng)
    floors = gen_tower_floors(tower_rng, monsters)
    # ---- M5 校验 ----
    assert len(traits) == 18 and len({t["id"] for t in traits}) == 18, "特性表须为 18 项且 id 唯一"
    assert len(monsters) == 145, f"怪物总数 {len(monsters)} != 145"
    species = [m for m in monsters if m["kind"] == "species"]
    bosses = [m for m in monsters if m["kind"] == "boss"]
    assert len(species) == 120 and len(bosses) == 25, "怪物构成须为 120 种 + 25 Boss"
    assert len({m["name"] for m in monsters}) == 145, "145 怪物名须全表唯一"
    assert sum(1 for m in bosses if m["boss_type"] == "small") == 20, "小 Boss 须 20 个"
    assert sum(1 for m in bosses if m["boss_type"] == "theme") == 4, "主题 Boss 须 4 个"
    assert sum(1 for m in bosses if m["boss_type"] == "final") == 1, "最终 Boss 须 1 个"
    assert {m["floor"] for m in bosses if m["boss_type"] == "small"} == set(range(50, 1001, 50)), "小 Boss 层须为 50/100/.../1000"
    assert {m["floor"] for m in bosses if m["boss_type"] == "theme"} == {100, 250, 500, 750}, "主题 Boss 层须为 100/250/500/750"
    assert [m["floor"] for m in bosses if m["boss_type"] == "final"] == [1000], "最终 Boss 层须为 1000"
    for m in monsters:
        trs = m["traits"]
        assert 1 <= len(trs) <= 2 and len(set(trs)) == len(trs), f"怪物 {m['id']} 特性须 1~2 个且不重复"
        for tr in trs:
            assert tr in {t["id"] for t in traits}, f"怪物 {m['id']} 引用未知特性 {tr}"
        if m["kind"] == "boss":
            assert len(trs) == 2, f"Boss {m['id']} 须固定 2 特性"
            assert sum(1 for tr in trs if TRAIT_GROUP[tr] == "强化") == 1, f"Boss {m['id']} 须含 1 强化特性"
            assert sum(1 for tr in trs if TRAIT_GROUP[tr] in ("奖励", "特殊")) == 1, f"Boss {m['id']} 须含 1 奖励/特殊特性"
    use = {}
    for m in monsters:
        for tr in m["traits"]:
            use[tr] = use.get(tr, 0) + 1
    low = [t["id"] for t in traits if use.get(t["id"], 0) < 3]
    assert not low, f"以下特性使用数 <3: {low}"
    # 塔表校验
    assert len(floors) == 1000 and [f["floor"] for f in floors] == list(range(1, 1001)), "塔表须为 1000 层连续"
    assert len({f["name"] for f in floors}) == 1000, "塔表 1000 层名须唯一"
    for i, f in enumerate(floors):
        prev = floors[i - 1] if i else None
        if prev is not None:
            assert f["base_hp"] > prev["base_hp"] and f["base_atk"] > prev["base_atk"] \
                and f["base_def"] > prev["base_def"], f"第 {f['floor']} 层基础数值须严格单调"
        struct = TOWER_BOST_MULTS[f["boss_type"]] if f["boss_type"] else (TOWER_ELITE_MULT if f["is_elite"] else 1.0)
        assert abs(f["hp"] - f["base_hp"] * struct * f["b_hp"]) < 1e-6 * f["hp"], f"第 {f['floor']} 层 hp 公式落表不符"
        assert abs(f["atk"] - f["base_atk"] * struct * f["b_atk"]) < 1e-6 * f["atk"], f"第 {f['floor']} 层 atk 公式落表不符"
        assert abs(f["def"] - f["base_def"] * struct * f["b_def"]) < 1e-6 * f["def"], f"第 {f['floor']} 层 def 公式落表不符"
        exp_rm = TOWER_BOST_REWARD if f["boss_type"] else (TOWER_ELITE_REWARD if f["is_elite"] else 1)
        assert f["reward_mult"] == exp_rm and f["reward_stone"] > 0, f"第 {f['floor']} 层奖励口径错误"
        assert f["is_elite"] == (f["floor"] % 10 == 0 and f["boss_type"] == ""), f"第 {f['floor']} 层精英标记错误"
    elite_cnt = sum(1 for f in floors if f["is_elite"])
    assert elite_cnt == 80, f"精英层须 80 个 (每 10 层 100 减 Boss 层 20, 实际 {elite_cnt})"
    # ---- M5-2 校验: 技能 atk/def 池 + 装备 atk/def 属性 ----
    for e in equipment:
        assert "atk" in e and "def" in e, f"装备 {e['id']} 缺 atk/def 字段"
        assert e["atk"] >= 0.0 and e["def"] >= 0.0, f"装备 {e['id']} atk/def 须非负"
    for slot in EQUIP_SLOTS:
        sa, sd = EQUIP_SLOT_ATKDEF[slot]
        # 同部位 atk/def 比例恒定 = 部位偏向 (武器偏攻, 法袍偏防 ...)
        for e in equipment:
            if e["slot"] != slot:
                continue
            if e["def"] <= 0:
                assert e["atk"] == 0, f"装备 {e['id']} def=0 时 atk 须 0"
                continue
            # 独立四舍五入到 3 位, 比例允许 2e-2 误差
            assert abs((e["atk"] / e["def"]) - (sa / sd)) < 2e-2, \
                f"装备 {e['id']} atk/def 比例须≈{sa:.1f}:{sd:.1f} (实际 {e['atk']/e['def']:.3f})"
        # 品质/变体 越高 atk+def 越大 (单调)
        by_tier = {}
        for e in equipment:
            if e["slot"] == slot:
                by_tier.setdefault(e["tier"], {})[e["id"]] = e["atk"] + e["def"]
        prev_tier_max = -1.0
        for t in sorted(by_tier):
            vals = by_tier[t]
            # 同品质 变体递增
            sorted_vals = sorted(vals.values())
            for i in range(len(sorted_vals) - 1):
                assert sorted_vals[i + 1] > sorted_vals[i], \
                    f"装备 {slot} 品质{t} atk+def 须随变体上升 ({sorted_vals})"
            assert max(vals.values()) > prev_tier_max, \
                f"装备 {slot} atk+def 须随品质上升 (t{t} max={max(vals.values())})"
            prev_tier_max = max(vals.values())
    eff_cnt = {}
    for s in skills:
        if s["type"] == "passive":
            eff_cnt[s["effect"]] = eff_cnt.get(s["effect"], 0) + 1
    # M5-2: 被动 技能 须 带 atk/def 属性池 (独立 字段, 非 主 效果)
    for s in skills:
        if s["type"] == "passive":
            assert "atk" in s and "def" in s, f"技能 {s['id']} 缺 atk/def 属性池"
            assert s["atk"] >= 0.0 and s["def"] >= 0.0, f"技能 {s['id']} atk/def 须非负"
    atk_cnt = sum(1 for s in skills if s["type"] == "passive" and s["atk"] > 0.0)
    def_cnt = sum(1 for s in skills if s["type"] == "passive" and s["def"] > 0.0)
    assert atk_cnt >= 5 and def_cnt >= 5, f"技能 atk/def 属性池覆盖不足 (atk {atk_cnt} / def {def_cnt})"
    # 登天梯 底数 须 严格高于 镇妖塔 (越打越难 口径)
    assert ENDLESS_HP_GROWTH > TOWER_HP_GROWTH, "登天梯 hp 底数须高于镇妖塔"
    assert ENDLESS_ATK_GROWTH > TOWER_ATK_GROWTH, "登天梯 atk 底数须高于镇妖塔"
    with open(os.path.join(DATA, "skills.json"), "w", encoding="utf-8") as f:
        json.dump({"skills": skills}, f, ensure_ascii=False, indent=2)
    with open(os.path.join(DATA, "equipment.json"), "w", encoding="utf-8") as f:
        json.dump({"equipment": equipment}, f, ensure_ascii=False, indent=2)
    with open(os.path.join(DATA, "achievements.json"), "w", encoding="utf-8") as f:
        json.dump({"achievements": achievements}, f, ensure_ascii=False, indent=2)
    with open(os.path.join(DATA, "monster_traits.json"), "w", encoding="utf-8") as f:
        json.dump({"traits": traits}, f, ensure_ascii=False, indent=2)
    with open(os.path.join(DATA, "monsters.json"), "w", encoding="utf-8") as f:
        json.dump({"monsters": monsters}, f, ensure_ascii=False, indent=2)
    with open(os.path.join(DATA, "tower_monsters.json"), "w", encoding="utf-8") as f:
        json.dump({
            "fixed": {"name": "镇妖塔", "max_floor": 1000,
                      "formulas": {"hp": [TOWER_HP_BASE, TOWER_HP_GROWTH],
                                   "atk": [TOWER_ATK_BASE, TOWER_ATK_GROWTH],
                                   "def": [TOWER_DEF_BASE, TOWER_DEF_GROWTH],
                                   "stone": [TOWER_STONE_BASE, TOWER_STONE_GROWTH]},
                      "elite": {"mult": TOWER_ELITE_MULT, "reward": TOWER_ELITE_REWARD},
                      "boss": {"mult": TOWER_BOST_MULTS, "reward": TOWER_BOST_REWARD}},
            "endless": {"name": "登天梯", "max_floor": None,
                        "milestone_floor": ENDLESS_MILESTONE_FLOOR,
                        "formulas": {"hp": [ENDLESS_HP_BASE, ENDLESS_HP_GROWTH],
                                     "atk": [ENDLESS_ATK_BASE, ENDLESS_ATK_GROWTH],
                                     "def": [ENDLESS_DEF_BASE, ENDLESS_DEF_GROWTH],
                                     "stone": [ENDLESS_STONE_BASE, ENDLESS_STONE_GROWTH]},
                        "elite": {"mult": TOWER_ELITE_MULT, "reward": TOWER_ELITE_REWARD},
                        "boss": {"mult": TOWER_BOST_MULTS, "reward": TOWER_BOST_REWARD}},
            "floors": floors,
        }, f, ensure_ascii=False, indent=2)
    # 校验
    assert len(skills) >= 100, f"技能数 {len(skills)} < 100"
    assert len(equipment) >= 100, f"装备数 {len(equipment)} < 100"
    assert len(achievements) >= 10, f"成就数 {len(achievements)} < 10"
    assert len({s["id"] for s in skills}) == len(skills), "技能 id 重复"
    assert len({e["id"] for e in equipment}) == len(equipment), "装备 id 重复"
    assert len({a["id"] for a in achievements}) == len(achievements), "成就 id 重复"
    import re
    for a in achievements:
        assert re.fullmatch(r"[A-Za-z0-9_]+", a["id"]), f"成就 id 不合法 (Steam 要求): {a['id']}"
    active = sum(1 for s in skills if s["type"] == "active")
    passive = sum(1 for s in skills if s["type"] == "passive")
    print(f"skills: {len(skills)} (passive {passive}, active {active})")
    print(f"equipment: {len(equipment)}")
    print(f"achievements: {len(achievements)}")
    print("\n--- 技能样例 ---")
    for s in skills[:3] + [x for x in skills if x["type"] == "active"][:2]:
        print(f"  {s['id']:14s} {s['name']:10s} {s['tier_name']} {s['type']:8s} {s['desc']}")
    print("\n--- 装备样例 ---")
    for e in equipment[:3] + equipment[-2:]:
        print(f"  {e['id']:14s} {e['name']:10s} {e['slot_name']}/{e['tier_name']} 灵石{e['cost']} {e['desc']}")

if __name__ == "__main__":
    main()
