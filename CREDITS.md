# CREDITS — 第三方素材署名

> 纪律：素材只收 `assets/<用途>/` 下实际被代码引用的文件；每件记录 来源 URL + 许可 + 作者。
> CC0 亦记录（Steam credits 直接可填）。2026-09-21 起 M7 美术里程碑启用。

## Kenney — UI Pack (CC0 1.0)

- 作者：Kenney (Kenney.nl)
- 许可：CC0 1.0（公共领域，可商用，无需署名）
- 来源：https://kenney.nl/assets/ui-pack
- 下载包：https://kenney.nl/media/pages/assets/ui-pack/f651646eab-1718203990/kenney_ui-pack.zip

| 本地文件 | 包内原文件 | 用途 |
|---|---|---|
| `assets/ui/btn_primary.png` | PNG/Grey/Default/button_rectangle_border.png (192x64) | 主按钮 normal 底 (9-slice) |
| `assets/ui/btn_primary_hover.png` | PNG/Grey/Default/button_rectangle_gloss.png (192x64) | 主按钮 hover 底 |
| `assets/ui/btn_primary_pressed.png` | PNG/Grey/Default/button_rectangle_depth_border.png (192x64) | 主按钮 pressed 底 |
| `assets/ui/btn_secondary.png` | PNG/Grey/Default/button_square_border.png (64x64) | 次级按钮底 (9-slice) |
| `assets/ui/bar_track.png` | PNG/Grey/Default/slide_horizontal_grey.png (96x16) | 进度条/滑条轨道底 |
| `assets/ui/bar_fill.png` | PNG/Grey/Default/button_rectangle_flat.png (192x64) | 进度条填充底 (StyleBoxTexture modulate 上色, 金/青档不变) |

## Kenney — Fantasy UI Borders (CC0 1.0)

- 作者：Kenney (Kenney.nl)
- 许可：CC0 1.0（公共领域，可商用，无需署名）
- 来源：https://kenney.nl/assets/fantasy-ui-borders
- 下载包：https://kenney.nl/media/pages/assets/fantasy-ui-borders/ab29cd0165-1701602367/kenney_fantasy-ui-borders.zip

| 本地文件 | 包内原文件 | 用途 |
|---|---|---|
| `assets/ui/panel_border.png` | PNG/Default/Border/panel-border-013.png (48x48) | 面板/按钮 9-slice 边框 (L 括号+方块节点角, 中心透明, 运行时 modulate 金/青) |
| `assets/ui/panel_border_slim.png` | PNG/Default/Border/panel-border-001.png (48x48) | 细边框 9-slice (小面板/卡片行, 空心方块节点角) |
| `assets/ui/panel_frame_frost.png` | PNG/Default/Transparent center/panel-transparent-center-013.png (48x48) | 面板 9-slice (中心半透明磨砂 + 013 同款角饰; 运行时 modulate 到 PANEL_BG 深色) |
| `assets/ui/divider.png` | PNG/Default/Divider/divider-000.png (96x22) | 页内横向分隔饰线 (居中拉伸) |

## 说明

- 全部素材为单色浅灰白线稿，深色底上运行时用 `StyleBoxTexture.modulate` / `TextureRect` 着色（金 0.98,0.86,0.5 / 青 0.62,0.9,0.95），不改 PNG 原色。
- 未入库：两包其余全部文件（整包 1300+ 文件）——纪律只收被引用文件；需要时按上表格式追加。
- `assets/icons/` `assets/sfx/` 预留（打磨-136 图标 / 打磨-139 音效）。
