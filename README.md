# 修仙挂机 · Xiuxian Idle

一款用 **Godot 4** 开发的修仙主题挂机 (idle / incremental) 游戏，目标上架 Steam。

## 玩法

挂机自动积累 **灵气** 与 **灵石**，灵气攒够后点击突破境界（有成功率）；开启 **自动突破** 后攒够即自动突破/精进（打磨-67），开启 **自动购置** 后灵石攒够即自动购买法器/装备并最佳换装（打磨-68），开启 **自动施展** 后主动神通冷却完毕即自动爆发（打磨-69），修行页底部一行 **自动系列状态汇总**（✓=开/✗=关，打磨-70），各段可点击切换对应开关（打磨-71），挂机全程无需手动点击。

- **境界体系**：练气 → 筑基 → 金丹 → 元婴 → 化神 → 炼虚 → 合体 → 大乘 → 渡劫 → 真仙（飞升），境界越高挂机越快（顶栏显示当前境界灵气倍率，悬停查看构成）
- **飞升后道行**（打磨-10）：飞升真仙界后挂机积累 **道行**，可精进 9 个阶段（初仙→道祖），每阶灵气速率 x2，给满级玩家长线挂机目标
- **技能系统**（120 个，数据驱动 `data/skills.json`）：
  - 被动功法：永久加成（灵气/灵石速率、突破成功率、离线效率）
  - 主动神通：点击释放，瞬间爆发大量灵气，带冷却
  - 按剑法/法术/心法/身法/神通分类，6 档品质（凡品→仙品）
- **装备系统**（140 个，数据驱动 `data/equipment.json`）：
  - 5 部位：武器 / 法袍 / 玉佩 / 灵珠 / 云靴
  - 7 档品质：凡品 → 神品
  - 灵石购买，每部位同时穿戴 1 件，提供各类加成
- **法器**：10 件永久法器（含渡劫/真仙境），乘算提升灵气速率，性价比曲线调平
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
data/achievements.json   # 17 成就 (数据驱动, Steam 上报)
scenes/main.tscn         # 主场景
scripts/game_data.gd     # 全局逻辑 + 存档 + 成就判定 (autoload)
scripts/steam.gd         # Steam 接入骨架 (autoload)
scripts/main.gd          # 主界面 UI (Tab: 修行/技能/装备)
scripts/gen_data.py      # 数据生成器
scripts/stress_test.gd   # 数值曲线压力测试 (打磨-15, headless CI)
steam_app.json           # Steam app manifest
PROJECT_PLAN.md          # 项目计划
```

## 开发

```bash
~/bin/godot --headless --path .            # 无头冒烟 (应无报错, 会一直挂机运行)
~/bin/godot --headless --path . -s res://scripts/selftest.gd   # 全流程自测 (学习/购买/穿戴/冷却/存读档/倍率/数值曲线/成就/飞升后道行/装备/技能浮动灵气速率增量/神通爆发预览/一键神通/神通冷却完毕就绪事件/神通冷却进度比例/突破成功率tooltip预期成本/突破失败浮动预期成本/突破成功浮动新境界成功率/离线收益启动金色浮动/自动突破/自动购置/自动施展/自动系列状态汇总, 845 项, 退出码 0=通过)
~/bin/godot --headless --path . -s res://scripts/stress_test.gd  # 数值曲线压力测试 (全境界/全品质梯度/解锁门槛一致性/后期溢出检查, 613 项, CI 可跑, 退出码 0=通过)
~/bin/godot --headless --path . res://scenes/ui_test.tscn  # UI 断言 (成就进度条/收集条/品质色/一键系列/顶栏灵石可购进度/灵石行内联下一件可购/法器属性构成/装备/技能浮动灵气速率增量/神通爆发预览/单个神通施展浮动/一键神通/神通冷却完毕就绪浮动/神通冷却进度条/神通冷却完毕收口动画+按钮微光/一键施展浮动爆发总量/单个神通施展浮动爆发总量/冷却完毕就绪浮动爆发总量/突破成功率tooltip预期成本/突破失败浮动预期成本/突破成功浮动新境界成功率/离线收益启动金色浮动/自动突破/自动购置/自动施展/自动系列状态汇总/自动系列汇总行点击直达, scene 模式带 autoload, 1510 项, 退出码 0=通过)
```

## 导出 (打包)

已配置 Linux / Windows 双平台 export preset（`export_presets.cfg`，均 x86_64、release 用二进制脚本、不内嵌 pck）。

```bash
# 前置: 安装 Godot 4.4 导出模板 (~/.local/share/godot/export_templates/4.4.stable)
mkdir -p export/linux export/windows
~/bin/godot --headless --path . --export-release Linux export/linux/xiuxian_idle
~/bin/godot --headless --path . --export-release Windows export/windows/XiuxianIdle.exe
```

> 注意：命令行 `--export` 仅支持当前 Godot 构建编译进的平台（本机 Linux 构建只能导出 Linux；
> Windows preset 需在 Windows 主机或 Godot 编辑器中导出）。导出产物在 `export/`（已 gitignore）。

## Steam 上架准备

- **成就系统**（16 条，数据驱动 `data/achievements.json`，由 `gen_data.py` 生成）：
  境界里程碑 ×8（筑基→渡劫）+ 飞升 + 玩法进度 ×7（首破/首法器/技能10/50/装备1/10/灵石10万）
  解锁状态存于存档 `ach_done` 字段（离线可玩、可重放幂等检查）
- **SteamAPI 初始化骨架**（`scripts/steam.gd`，autoload `Steam`）：
  Windows + Steamworks SDK 存在时真正接入（`RestartAppIfNecessary` → 成就
  `SetAchievement` + `StoreStats`）；开发机 / headless 自动降级为本地记录，不阻塞
- **app_id**：`steam.gd` 中 `APP_ID` 为占位值，Steamworks 注册后替换
- **app manifest**：`steam_app.json`（导出产物同目录放置；`launch` 需与实际可执行文件名一致）

上架步骤（Windows 主机）：Steamworks 注册应用 → 替换 `APP_ID` → 导出目录放置
`steam_app.json` + Steamworks SDK 的 `Steam.dll` → 导出 Windows 版 → SteamDB
同步成就定义（id 与 `data/achievements.json` 对齐）→ 提审。
