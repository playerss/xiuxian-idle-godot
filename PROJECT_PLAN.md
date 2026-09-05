# 修仙挂机 · 技能 & 装备系统 项目计划

> 目标：在现有 Godot 4 修仙挂机基础上，新增 **技能（功法/神通）** 与 **装备** 两大系统，
> 各 100+ 数据项，采用 **数据驱动（JSON）**，并用 **定时任务** 持续推进、自动 commit+push。

---

## 里程碑

### M1 数据层（data-driven）
- [x] `scripts/gen_data.py` — 确定性数据生成器（固定随机种子，可重跑）
- [x] `data/skills.json` — **120 技能**（5 大类 × 6 品质 × 4 变体）
  - 被动功法：永久加成（灵气速率 / 灵石速率 / 突破成功率 / 离线效率 / 全面增幅）
  - 主动神通：点击释放，爆发灵气（= 当前速率 × N 秒），带冷却
- [x] `data/equipment.json` — **140 装备**（5 部位 × 7 品质 × 4 变体）
  - 部位：武器 / 法袍 / 玉佩 / 灵珠 / 云靴
  - 品质：凡品 / 灵品 / 玄品 / 地品 / 天品 / 仙品 / 神品
- [x] 数据校验：数量 ≥100、id 唯一、数值梯度合理

### M2 核心逻辑（game_data.gd）
- [x] 加载 `skills.json` / `equipment.json`（FileAccess + JSON.parse_string）
- [x] 技能：学习/解锁（境界门槛）、被动加成汇总、主动神通释放 + 冷却计时
- [x] 装备：灵石购买、5 部位穿戴、属性汇总
- [x] 存档兼容：旧档无新字段时默认空，新字段 `skills` / `equipment`
- [x] headless 逻辑自测（学习/购买/穿戴/冷却/存读档往返）

### M3 UI
- [x] 技能面板：列表、品质/类型筛选、学习按钮、主动神通冷却倒计时
- [x] 装备面板：5 部位槽位、背包列表、穿戴 / 属性对比
- [x] 主界面：Tab 切换（修行 / 技能 / 装备）

### M4 验证 & 交付
- [x] headless 全流程自测通过
- [x] `git commit + push` → `github.com/playerss/xiuxian-idle-godot`
- [x] README 更新（运行方式 + 系统说明）

---

## 数值设计（见 gen_data.py）

**技能**
| 品质 | 凡 | 灵 | 玄 | 地 | 天 | 仙 |
|---|---|---|---|---|---|---|
| 解锁境界 | 练气 | 筑基 | 金丹 | 元婴 | 化神 | 渡劫 |
| 被动加成基数 | +3% | +8% | +15% | +25% | +40% | +70% |

- 被动：加成为 **乘算独立** 项（`1 + Σvalue`），避免指数爆炸
- 主动神通：`value` = 爆发秒数（60~600s），`cooldown` = 冷却秒

**装备**
- 5 部位 × 7 品质 × 4 变体 = 140
- 灵石价格按品质指数增长：100 → 500 → 2.5k → 12k → 60k → 300k → 1.5M（打磨-4 调平，各档约 x5）
- 属性随品质/变体线性增长（灵气% / 灵石% / 突破% / 离线%）

---

## 推进机制（定时任务）

- cron 每 **30 分钟** 触发一次自主检查：
  1. 读本计划 + `todo_list`，找未完成的最高优先级项
  2. 实现该里程碑的下一步
  3. `~/bin/godot --headless` 跑自测，确保无脚本错误
  4. `git commit + push` 到 GitHub
  5. 汇报：做了什么 / 验证结果 / 剩什么
- **M4 完成后暂停定时任务**（避免空转）

## 风险与对策

| 风险 | 对策 |
|---|---|
| 后期数值溢出 | 乘算独立项 + 指数受控，上线后按实测调 |
| 旧存档不兼容 | `parsed.get(key, 默认)` 兜底，缺字段即空 |
| JSON 数据量大 | 数据驱动，改数值不碰逻辑，git 可 diff |

## 打磨期（M4 之后）
M1-M4 已全部完成（2026-09-03）。后续按以下小项推进，每次一个小改动 + 自测 + push：
- [x] 打磨-1：技能/装备行显示当前已穿戴/已学状态的视觉区分（高亮边框）（金色边框, 状态变化时才刷样式）
- [x] 打磨-2：突破成功/失败时短暂浮动提示（突破按钮闪烁）
- [x] 打磨-3：顶栏显示当前境界的灵气倍率（境界标签 `灵气xN`，tooltip 展示 境界/功法装备/法器 倍率构成）
- [x] 打磨-4：数值微调（后期装备价格曲线 x8→x5 受控；法器 5→10 件，性价比曲线调平并补全渡劫/真仙境，每件约 1~8 分钟灵石可购，自测新增曲线校验 21 项）
- [x] 打磨-5：打包/导出配置（Steam 上架前的 Linux/Windows export preset）（export_presets.cfg 双平台 x86_64，Linux release 本机实测导出成功 GDPC pck；Windows preset 配置经 4.4 源码核对，需在 Windows 主机或 Godot 编辑器执行）
- [x] 打磨-6：Steam 上架准备（app_id 配置、SteamAPI 初始化骨架、成就定义表、app manifest）（16 成就数据驱动 data/achievements.json，steam.gd 骨架 autoload Windows+SDK 真接入/否则降级，成就判定入 GameData + 存档 ach_done 字段，steam_app.json manifest，自测 100 项）
- [x] 打磨-7：成就面板 UI（16 成就列表：已解锁高亮 / 条件提示 / tooltip）（成就 Tab 页, 计数 N/16, 已解锁金框+★+绿字, 未解锁☆+进度提示 (进度/目标), 行 tooltip 条件说明; 状态变化才刷样式, 自测 +7 项 ach_progress 断言)
- [ ] 打磨-8：Windows 主机接入 Steamworks 官方 SDK 实测（需 Windows 环境 + 真实 app_id，本机仅配置就绪）
- [x] 打磨-9：技能/装备/法器行 tooltip 详情（名称/品质/类型/效果/领悟条件/状态行）+ 技能/装备页顶栏当前总加成汇总（灵气/灵石/突破/离线/法器乘数）（GameData.skill_detail/equip_detail/item_detail/bonus_summary/bonus_summary_text，UI 仅状态/文本变化时刷新，自测 123 项）
- [x] 打磨-10（候选）：飞升后目标玩法 — 真仙境道行进度/仙界资源，给满级玩家一个挂机目标（飞升后挂机积累道行, 9 阶段 初仙→道祖 每阶灵气 x2, 道行精进耗 1e9~1.1e13 (每阶x8) 成功率 90%→66%, 突破按钮复用为修炼道行, 境界阶梯页加仙界道行列表, 离线收益飞升后计道行, 成就 dao_zuzi (17 个), fmt 扩展 万/亿/兆/京/垓, 存档 dao/dao_level 字段, 自测 164 项）
- [x] 打磨-11：飞升后可玩性修复 + 装备页部位筛选（飞升后主动神通爆发改为获得道行(文案/tooltip 同步说明), 道行精进失败浮动提示改专属文案, 装备页加 5 部位+全部 筛选按钮; 自测 172 项）
- [x] 打磨-12：购买 ETA 提示（法器/装备行在灵石不足时显示"约 X分/X小时 可购"预计时间, 买得起或已拥有时隐藏; GameData.eta_seconds/eta_text, fmt_time 短时长改"不足1分", UI 1 秒节流且仅文本变化时刷新; 自测 182 项）
- [x] 打磨-13（候选）：离线/挂机收益可视化（顶栏或修行页显示每小时离线可得资源）或 数值曲线压力测试脚本（修行页离线每小时收益行: 道行/灵气 + 灵石 + 效率% + 上限8小时, 飞升后主资源文案改道行, tooltip 说明构成; GameData.offline_gain/offline_hourly/offline_hourly_text, UI 仅文本变化时刷; 顺带法器列表包进滚动容器防低分辨率溢出; 自测 200 项）
- [x] 打磨-14：修行统计（累计在线时长/突破/道行精进/神通施展/法器/装备次数, 存档 stats 字段持久化, 旧档缺字段默认0, 修行页统计行+tooltip; GameData.stats/stats_text/fmt_stats_time/_stat_inc 事件埋点, UI 文本变化才刷; 自测 221 项）
- [x] 打磨-15：数值曲线压力测试脚本（gen_data.py 或独立 headless 脚本: 全境界/全品质梯度、技能解锁门槛与境界一致性、后期数值溢出检查, CI 可跑）（scripts/stress_test.gd 独立 headless 脚本 613 项: 境界/道行消耗梯度锚定、技能 120 解锁门槛与境界/层一致性+品质分布 20/档、装备 140 全部位品质/变体价格属性单调、法器 10 件梯度、突破 32 次消耗峰值公式锚定、成功率全程受控、满修+道祖溢出检查 (灵气<1e19/s 展示京/垓档, 法器连乘 x4.7e9, 爆发/离线/道行精进全有限), fmt 万/亿/兆/京/垓 档锚定, 退出码 0/1 可接 CI）
- [x] 打磨-16（候选）：Steam 商店页面素材（截图 1920x1080 游戏内 UI 截图脚本 + 页面描述文案模板）（scripts/store_shots.gd+scenes/store_shots.tscn 独立场景, SubViewport 1920x1080 真实渲染, 确定性演示档态 金丹第2层/12技能/4装备/3法器/6成就, 输出 01_修行..04_成就 4 张 PNG 已提交 store/shots/, 程序化校验 2300+色+顶栏像素; store/store_page.md 中英文案模板+标签建议, store/README.md 复跑说明; selftest 221+stress 613 回归全过）
- [x] 打磨-17：成就解锁浮动提示（挂机时不在成就页也能看到达成反馈; GameData.new_ach_since 差集接口 (prev 用非类型 Array 兼容未类型化调用方), UI 每帧对比上帧快照, 数量变化才更新 (ach_done 只增不减, 读档恢复的旧解锁不弹), 同一批多个解锁合并一行 "✦ 成就达成: xxx ✦" 居中上浮淡出; selftest +3 项 = 224 项）
- [x] 打磨-18：境界阶梯动态高亮（修行页境界阶梯原为构建时一次性定色, 金色高亮停在练气不随进度移动; 现境界/道行阶段变化时才刷, 未飞升当前境界金 / 飞升后当前道行阶段金, 其余白字; main.gd _refresh_ladder + 缓存键节流; headless 主场景 0 报错, selftest 224 + stress 613 回归全过）
- [x] 打磨-19：飞升后顶栏主资源切换（飞升后灵气弃用但顶栏仍显示"灵气 0", 道行总量无展示位; GameData.primary_res_name/primary_res_value/primary_res_text 统一主资源接口, main.gd 顶栏 _essence_label 改用 primary_res_text (未飞升=灵气 / 飞升后=道行, 灵石始终单列); selftest +8 项 = 232 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-20：技能页品质筛选（120 技能列表只能按类别筛, 按品质找功法成本高; 类别筛选行下加品质筛选行 (全部品质/凡品~仙品 6 档), 与类别筛选叠加生效 (AND), 排序规则不变 (已学在前+品质升序); GameData.skill_tier_name 品质名接口 (越界钳制), main.gd _on_tier_filter/_apply_skill_filter 统一应用; selftest +11 项 = 243 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-21：装备页品质筛选（140 装备只能按部位筛, 按品质找装备成本高; 部位筛选行下加品质筛选行 (全部品质/凡品~神品 7 档), 与部位筛选叠加生效 (AND), 列表顺序不变; GameData.equip_tier_name 品质名接口 (越界钳制), main.gd _on_equip_tier_filter/_apply_equip_filter 统一应用; selftest +14 项 = 257 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-22：装备列表按状态排序（140 件装备原按数据序平铺, 买到的装备沉在列表底部难寻; 现按 已穿戴>已拥有>未拥有 分三段, 段内保持 部位/品质/变体 数据序; GameData.equip_state (0/1/2) + equip_sort_order/equip_sort_cmp, main.gd _resort_equip 状态快照变化才重排 (购买/穿戴/卸下/读档触发, 避免每帧 140 行重排) 并在 _apply_equip_filter 内重排保持筛选与排序一致; selftest +13 项 = 270 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-23：一键领悟 / 一键购买（120 技能 + 140 装备逐个点成本高; 技能页品质筛选行尾加 "一键领悟" 按钮 (与 类别/品质 筛选 AND 叠加, 只学 未学+境界足够, 按钮随可学数变文案 "x N"/已无新技能), 装备页品质筛选行尾加 "一键购买" 按钮 (价格升序连买 买得起 的, 灵石花到买不起为止, 槽位空自动穿戴, 按钮随可购数变文案); GameData.learn_all_available(cat,tier)/buy_affordable/buy_affordable_cmp (按价格升序, 同价按数据序), 复用 buy_equipment 的 _stat_inc 统计埋点; main.gd _on_learn_all/_on_buy_all + 按钮文本仅数值变化才刷; selftest +23 项 = 293 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-24：突破 ETA（核心循环"攒灵气突破"缺耗时预期, 玩家不知还要多久能突破/精进; 修行页突破进度条下加 ETA 行: 按当前灵气(道行)速率估算攒够突破资源所需时间, 攒够后自动消失; 飞升后自动切换为道行精进 ETA (文案"道行精进还需 X"), 道祖封顶显示空; GameData.breakthrough_eta_seconds (缺口/qi_per_sec, 0=可突破, -1=无收入防御) / breakthrough_eta_text (前缀 突破还需/道行精进还需 + 不足1分/分/小时档), 复用 fmt_time; main.gd _break_eta_label 每帧算+文本变化才刷; selftest +17 项 = 310 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-25：换装对比提示（140 件装备购买/穿戴时不知穿上后该部位属性变化; 每行加 换装对比 标签: 该部位已穿其它件时显示"替换「X」: 灵气±N% 灵石±N%" (主属性差, 0 省略), 槽位空或穿上自身时隐藏; GameData.equipped_at/equip_swap_hint 接口, equip_detail tooltip 追加换装对比行; main.gd _equip_swap 行标签文本变化才刷并同步 tooltip, 穿戴/卸下自动触发; selftest +19 项 = 331 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-26：一键最佳穿戴（140 件买齐后逐个点穿戴成本高, 且 一键购买 仅槽位空时自动穿最便宜件; 装备页品质筛选行尾加 "一键最佳" 按钮: 各部位穿上拥有的最佳件 (按 灵气+灵石 主属性, 再 突破/离线, id 兜底确定性), 按钮随可改进槽位数变文案 "x N"/已最佳 + tooltip; GameData._equip_rank_key/_rank_gt/equip_best_id(slot)/equip_best_pending()/equip_best() 接口 (幂等, 已最佳再点 0 变更); selftest +15 项 = 346 项, stress 613 + 主场景冒烟 0 报错回归全过; 顺带 Steam 商店截图 4 张用 Xvfb 重跑更新为当前版 UI (store/shots/, 尺寸/颜色档/顶栏内容程序化校验))
- [x] 打磨-27：一键领悟按钮计数口径统一（按钮文案原按 全局可学数 计数, 但点击只学 当前 类别/品质 筛选 内的技能, 筛选后文案与实际执行不符误导玩家; 现按钮按 筛选范围内可学数 计数 (与 一键购买/一键最佳 按可执行数计 口径统一), 点完归零变"已无新技能"; GameData.learn_available_count(cat,tier) 只读计数 (口径与 learn_all_available 完全一致), main.gd _refresh 改用它; selftest +12 项 = 358 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-28：收集进度一览（120 技能/140 装备/10 法器/17 成就 的全局收集进度此前无展示位, 收集控玩家缺少长线目标感; 成就页顶栏计数右侧加 "收集进度 技能 N/120 · 装备 N/140 · 法器 N/10 · 成就 N/17 (总 N/287)" 青色行 + tooltip 说明 (各条目只收集一次, 计数只增不减, 卸下/换装不影响); GameData.collect_summary() 四类 已收集/总量 + collect_summary_text() 汇总文本, main.gd _collect_label 文本变化才刷; selftest +15 项 = 373 项, stress 613 + 主场景冒烟 0 报错回归全过; 顺带 4 张 Steam 商店截图 Xvfb 重跑更新为当前版 UI (04 顶栏收集进度程序化校验 青色像素 12->105))
- [x] 打磨-29：法器 一键购买（修行页 10 件法器逐个点成本高, 与技能/装备页 一键 系列按钮口径不齐; 法器标题行尾加 "一键购买" 按钮: 按 价格升序 连买 买得起 的法器, 灵石花到买不起为止, 按钮随可买数变文案 "x N"/灵石不足 + tooltip; GameData.item_affordable_count() 只读计数 + buy_items_affordable() 批量购买 (复用 try_buy_item 的 _stat_inc 统计埋点, 价格升序 _item_price_cmp), main.gd _on_items_buy_all + 按钮文本仅数值变化才刷; selftest +17 项 = 390 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-30：主动神通 一键施展（已学的主动神通此前只能逐个点 施展 爆发, 与 一键 系列口径不齐; 技能页 一键领悟 旁加 "一键施展" 按钮: 一次释放所有 已学+冷却完毕 的主动神通, 施展后各自进冷却, 按钮随就绪数变文案 "x N"/冷却中 + tooltip; GameData.active_ready_count() 只读计数 + use_all_active() 批量释放 (复用 use_active_skill 的 冷却/爆发/skill_use 统计埋点, 返回 {count, burst}), 冷却中再调=0 幂等; main.gd _on_active_all + 按钮文本仅就绪数变化才刷; selftest +10 项 = 400 项, stress 613 + 主场景冒烟 0 报错回归全过; 顺带 4 张 Steam 商店截图 Xvfb 重跑更新当前版 UI (02 技能页新增 一键施展 按钮))
- [x] 打磨-31：下一目标提示（挂机核心循环"攒资源→突破"缺方向感, 玩家不知下一步该干什么/还差多少; 修行页突破 ETA 下加金色 下一目标 行: 未飞升="突破至 练气 第 2 层 还差 X 灵气 (突破还需 Y)" / 层顶跨境界自动指下一境界 / 真仙顶层指飞升, 飞升后="道行精进至 少仙 还差 X 道行", 资源攒够直接提示"点击突破/修炼", 道祖封顶"道法自然"; GameData.next_goal_text() + next_realm_display() (复用 breakthrough_eta_text 的 ETA), main.gd _goal_label 文本变化才刷 + tooltip; selftest +13 项 = 413 项, stress 613 + 主场景冒烟 0 报错回归全过; 顺带 4 张 Steam 商店截图 Xvfb 重跑更新当前版 UI (01 修行页左栏金色 下一目标 行 1031px 程序化校验))
- [x] 打磨-32：突破按钮"可突破"金边高亮（资源攒够时按钮无视觉引导, 玩家要自己扫 ETA 才知道可点; GameData.breakthrough_ready() (资源>=突破消耗且未封顶, 封顶恒 false), main.gd _btn_sb_gold 金边样式 + _apply_break_btn_style 状态变化才刷 (闪烁动画期间不干预, 闪烁结束按当前 ready 恢复), 按钮 tooltip 不变 (文案本身已含消耗); selftest +9 项 = 422 项, stress 613 + 主场景冒烟 0 报错回归全过; 顺带 store_shots 演示档改为 可突破 态 (essence 102%), 4 张截图 Xvfb 重跑 (01 突破按钮金棕填充区 42..934x382..414 程序化校验))
- [x] 打磨-33：境界阶梯 ETA 路线（修行页右侧境界阶梯原只有静态倍率, 长线玩家不知各境界还要挂多久; 每个未达成境界/道行阶段按当前速率估算 累计预计耗时 ("约X分/X小时/X天"), 已达成标注"已达成 ✓", 当前行不显示(金高亮已表达), 飞升后阶梯改道行口径 (凡境全标已达成), 速率/境界/资源变化文本才刷 (0.5 速率档+1 资源档量化节流, 1 秒刷), 上限 7 天 显示"8天+"封顶; GameData.breakthrough_cost_at/dao_break_cost_at (指定境界/阶段消耗, 不改动状态), realm_ladder_eta/dao_ladder_eta (累计消耗, 目标=当前=0, 越界 -1), ladder_eta_text (0/负=空, 8天+ 封顶), ladder_row_eta (库存抵扣+无收入防御), main.gd _ladder_eta 19 行青色标签+hint tooltip 说明估算口径 (未计入突破失败重耗, 境界提升后只会更快); selftest +26 项 = 448 项, stress 613 + 主场景冒烟 0 报错回归全过; 顺带 4 张 Steam 商店截图 Xvfb 重跑更新当前版 UI (01 境界阶梯 ETA 标签程序化验证 金丹档态: 已达成x2/当前空/约不足1分~约13分 梯度正确))
- [x] 打磨-34：境界阶梯当前层进度（当前境界行只显示"× N 层"无层数位置, 玩家不知当前境界内爬到第几层; 当前境界行下加金色 "第 X/Y 层 · 突破需 X 灵气 (当前 X)" 行, 标签随当前境界移动 (move_child), 飞升后隐藏 (仙界按阶段行, 无层概念); GameData.ladder_current_progress_text() (未飞升才出文本, 复用 breakthrough_cost/fmt), main.gd _ladder_prog 构建时挂第 0 行下, _refresh_ladder 状态变化才 move_child, _refresh_ladder_eta 文本变化才刷 (1 秒节流随 ETA 同路径); selftest +7 项 = 455 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-35：当前道行阶段消耗提示（飞升后当前道行行只有金色高亮+下方 ETA, 与打磨-34 未飞升层内进度口径不齐; 飞升后当前道行阶段行下加金色 "道行精进需 X 道行 (当前 X)" 行 (道祖封顶行 "已至道祖, 道法自然 ♪"), 标签随道行阶段 move_child, 未飞升隐藏; GameData.dao_progress_text() 复用 dao_break_cost/fmt, 自测 +6 项 = 461 项）
- [x] 打磨-36：道行精进成功率显示（飞升后精进成功率 90%→66% 逐阶递减, 玩家在修行页看不到失败风险预期; 修行页突破进度/ETA 区旁加成功率行 (未飞升显示突破成功率同口径), 与突破失败浮动提示口径对齐; GameData.primary_break_chance()/primary_break_chance_text() 统一接口 (道祖封顶=1.0+圆满文案, 舍入到整数), main.gd _chance_label 文本变化才刷+tooltip 构成说明, 自测 +18 项 = 479 项）
- [x] 打磨-37：成功率构成 tooltip（成功率行 tooltip 现只有静态说明, 玩家不知 +N% 来自哪; GameData.primary_break_chance_parts() 拆 基础(境界/阶段)/功法/装备/钳制 四段数值, main.gd 成功率行 tooltip 动态展示构成, 数值变化才刷; 自测 +24 项 = 503 项, stress 613 + 主场景冒烟 0 报错回归全过）
- [x] 打磨-38：技能页"只看可学"筛选（120 技能含大量境界不足项, 玩家找"现在能学的"成本高; 技能页品质筛选行尾加 "只看可学" 开关按钮 (与 类别/品质 筛选 AND 叠加, 过滤掉 境界/层 不足的未学技能, 已学技能恒显示且排最前; 按钮按 筛选范围内可显示数 变文案 "只看可学 x N"/"无可学", 开启态显示 "显示全部"); GameData.skill_can_learn_display(id) (已学恒 true, 未学复用 can_learn 口径, 未知 id false) + learnable_display_count(cat,tier) (与 类别/品质 叠加, 口径与 UI 过滤条件一致), main.gd _on_learnable_filter 切换 + _apply_skill_filter 内叠加应用 (显示/隐藏/重排/筛选提示同步) + 按钮文本仅变化才刷; selftest +18 项 = 522 项, stress 613 + 主场景冒烟 0 报错回归全过; 顺带 4 张 Steam 商店截图 Xvfb 重跑更新当前版 UI)
- [x] 打磨-39：成就页按解锁状态排序（17 成就现按数据序平铺, 已解锁的与未解锁的混排, 收集控玩家回看成就时已达成项沉在中间难找; 现按 已解锁在前 / 未解锁在后 两段, 段内 已解锁按 id 稳定 / 未解锁按 进度比例 降序 (比例相同按 id 稳定), 排序键变化才重排 (_resort_ach 快照对比, 避免每帧 17 行重排); GameData.ach_progress_ratio(id) (0..1, 口径与 ach_progress 一致: 境界=realm_idx/need 封顶, 灵石/技能/装备/道行=已获/目标, 飞升类=0/1, 未知 id=0) + ach_sort_cmp/ach_sort_order, main.gd _ach_states 快照 + _resort_ach 每帧对比 move_child; selftest +27 项 = 549 项, stress 613 + 主场景冒烟 0 报错回归全过; 顺带 4 张 Steam 商店截图 Xvfb 重跑更新为当前版 UI)
- [ ] 打磨-40（候选）：成就页进度条可视化（17 成就现只有文字进度 "50000/100000", 收集控玩家扫视时难以快速判断哪个快达成; 每个未解锁成就行加 进度条 (复用打磨-39 ach_progress_ratio 0..1 口径, 已解锁=满条金色, 未解锁=青色按 ratio 填充, 与"按进度降序"排序视觉呼应); GameData 无需新接口 (直接复用 ach_progress_ratio), main.gd _ach_rows 加 progress bar 子节点 + 仅 ratio 变化才刷 (复用 _ach_hl_seq 节流路径防每帧重绘); 自测补断言)
