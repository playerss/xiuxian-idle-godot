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
PASSIVE_EFFECTS = ["qi_mult", "stone_mult", "bt_chance", "offline_rate", "all_mult"]
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
                    skills.append({
                        "id": sid, "name": name, "category": cat, "category_name": cat_cn,
                        "tier": tier, "tier_name": SKILL_TIERS[tier], "type": "passive",
                        "effect": eff, "value": round(pct / 100.0, 3),
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
EQUIP_BASE_COST = [100, 800, 6000, 48000, 400000, 3200000, 25000000]

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
                eq.append({
                    "id": eid, "name": name, "slot": slot, "slot_name": slot_cn,
                    "tier": tier, "tier_name": EQUIP_TIERS[tier], "cost": cost,
                    "qi_mult": qi, "stone_mult": stone, "bt_chance": bt, "offline_rate": off,
                    "desc": f"灵气+{qi*100:.0f}% 灵石+{stone*100:.0f}% 突破+{bt*100:.1f}% 离线+{off*100:.1f}%",
                })
    return eq

def main():
    skills = gen_skills()
    equipment = gen_equipment()
    with open(os.path.join(DATA, "skills.json"), "w", encoding="utf-8") as f:
        json.dump({"skills": skills}, f, ensure_ascii=False, indent=2)
    with open(os.path.join(DATA, "equipment.json"), "w", encoding="utf-8") as f:
        json.dump({"equipment": equipment}, f, ensure_ascii=False, indent=2)
    # 校验
    assert len(skills) >= 100, f"技能数 {len(skills)} < 100"
    assert len(equipment) >= 100, f"装备数 {len(equipment)} < 100"
    assert len({s["id"] for s in skills}) == len(skills), "技能 id 重复"
    assert len({e["id"] for e in equipment}) == len(equipment), "装备 id 重复"
    active = sum(1 for s in skills if s["type"] == "active")
    passive = sum(1 for s in skills if s["type"] == "passive")
    print(f"skills: {len(skills)} (passive {passive}, active {active})")
    print(f"equipment: {len(equipment)}")
    print("\n--- 技能样例 ---")
    for s in skills[:3] + [x for x in skills if x["type"] == "active"][:2]:
        print(f"  {s['id']:14s} {s['name']:10s} {s['tier_name']} {s['type']:8s} {s['desc']}")
    print("\n--- 装备样例 ---")
    for e in equipment[:3] + equipment[-2:]:
        print(f"  {e['id']:14s} {e['name']:10s} {e['slot_name']}/{e['tier_name']} 灵石{e['cost']} {e['desc']}")

if __name__ == "__main__":
    main()
