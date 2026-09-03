# 修仙挂机 · Xiuxian Idle

一款用 **Godot 4** 开发的修仙主题挂机 (idle / incremental) 游戏，目标上架 Steam。

## 玩法

挂机自动积累 **灵气** 与 **灵石**，灵气攒够后点击突破境界（有成功率）。

- **境界体系**：练气 → 筑基 → 金丹 → 元婴 → 化神 → 炼虚 → 合体 → 大乘 → 渡劫 → 真仙（飞升），境界越高挂机越快
- **技能系统**（120 个，数据驱动 `data/skills.json`）：
  - 被动功法：永久加成（灵气/灵石速率、突破成功率、离线效率）
  - 主动神通：点击释放，瞬间爆发大量灵气，带冷却
  - 按剑法/法术/心法/身法/神通分类，6 档品质（凡品→仙品）
- **装备系统**（140 个，数据驱动 `data/equipment.json`）：
  - 5 部位：武器 / 法袍 / 玉佩 / 灵珠 / 云靴
  - 7 档品质：凡品 → 神品
  - 灵石购买，每部位同时穿戴 1 件，提供各类加成
- **法器**：5 件永久法器，乘算提升灵气速率
- **离线收益**：最高 8 小时、50% 效率
- **自动存档**：每 15 秒 + 退出时写入 `user://save.json`（兼容旧档）

## 运行

```bash
godot --path .            # 打开并运行
```

> 需要 Godot 4.x。UI 为代码构建，已内置 Noto Sans SC 中文字体。

## 数据生成

技能/装备均为程序生成，修改 `scripts/gen_data.py` 后重跑即可重新生成（固定随机种子，可复现）：

```bash
python3 scripts/gen_data.py
```

## 项目结构

```
project.godot            # 项目配置
data/skills.json         # 120 技能 (数据驱动)
data/equipment.json      # 140 装备 (数据驱动)
scenes/main.tscn         # 主场景
scripts/game_data.gd     # 全局逻辑 + 存档 (autoload)
scripts/main.gd          # 主界面 UI (Tab: 修行/技能/装备)
scripts/gen_data.py      # 数据生成器
PROJECT_PLAN.md          # 项目计划
```

## 开发

```bash
~/bin/godot --headless --path .            # 无头冒烟 (应无报错, 会一直挂机运行)
~/bin/godot --headless --path . -s res://scripts/selftest.gd   # 全流程自测 (学习/购买/穿戴/冷却/存读档, 44 项, 退出码 0=通过)
```
