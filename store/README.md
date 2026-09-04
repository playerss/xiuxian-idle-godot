# 修仙挂机 — Steam 商店页素材 (打磨-16)

本目录是 Steam 商店页素材的工作区：

- `shots/` — 1920×1080 游戏内 UI 截图（由 `scripts/store_shots.gd` 确定性生成，可重跑）
- `store_page.md` — 商店页文案模板（中/英文，可直接粘贴进 Steamworks）

## 生成截图

截图模式为确定性演示档态（金丹 第 2 层、已学 12 技能、4 件装备穿戴、3 件法器），
每次生成的 4 张图数值一致，可重复执行：

```bash
# 本机 (有 X 环境):
XIUXIAN_STORE_SHOTS=1 ~/bin/godot --path . res://scenes/main.tscn

# 无显示环境 (Xvfb):
Xvfb :99 -screen 0 1920x1080x24 &
DISPLAY=:99 XIUXIAN_STORE_SHOTS=1 ~/bin/godot --path . res://scenes/main.tscn
```

产出 4 张（退出码 0 成功）：

| 文件 | 内容 |
|---|---|
| `shots/01_training.png` | 修行页：境界/速率/突破进度/法器商店/境界阶梯 |
| `shots/02_skills.png` | 技能页：筛选 + 已学技能金框高亮 + 总加成汇总 |
| `shots/03_equipment.png` | 装备页：5 部位槽位 + 部位筛选 + 购买/穿戴 |
| `shots/04_achievements.png` | 成就页：已解锁成就金框 + 进度提示 |

截图为「当前游戏版本」的真实渲染（gl_compatibility），上架前重新执行一次即可
拿到最新素材；`shots/` 已提交仓库，diff 可查。

## 商店页文案（见 store_page.md）

- 短描述：300 字符内
- 长描述：支持 Steam 富文本标签（`b`/`i`/`img`/`br` 等）
- 截图 1 为封面（修行页），其余 2~4 按顺序排布
- 后续建议：首张封面可加游戏标题 Logo 合成（当前为纯 UI 截图，留白充足）
