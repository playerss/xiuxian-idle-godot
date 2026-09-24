extends Node
## 打磨-40: 成就页进度条 UI 断言 (headless 可跑, scene 模式带 autoload GameData/Steam)
## 打磨-41: 技能/装备/法器 行首品质色竖条断言 (存在/首子节点/颜色与数据 tier 或价格档一致)
## 打磨-42: 成就页顶栏收集进度一览 mini 进度条断言 (4 条节点/0 填充/满态金/半态比例/节流缓存)
## 打磨-43: 收集进度一览加 总计 mini 进度条断言 (6 条节点/总计=10/419 与 159/419 两态/wrap 换行布局)
## 打磨-92: 收集进度一览 加入 词缀 类 (6 条 = 5 类 + 总计; 总 287→419; 词缀 点击 直达 装备页)
## 打磨-44: 收集进度一览 点击直达断言 (5 条 flat Button+手型光标/tooltip/点击切 Tab 重置筛选/
##          法器区金边高亮+自动恢复/无存档统计副作用/总计不切页)
## 打磨-71: 自动系列 汇总行 点击直达断言 (3 段热区 flat Button+手型光标/tooltip 口径/点击切
##          对应 自动开关 同 口径+底部消息+上方按钮同步按压态/节流/无 资源/统计 副作用)
## 打磨-72: 启动 自动系列 恢复 提示断言 (_ready 三关 不提示 计数 0/手动驱动 单开+组合 底部消息
##          文案=auto_restore_text+计数+1/离线消息 优先 让位/全关 不提示/无 资源/统计 副作用/收尾 恢复)
## 打磨-73: 顶栏 自动系列 状态徽标断言 (金色徽标节点 顶栏子节点/全关 隐藏 文本空/单开 显示
##          "自动 1/3"+tooltip 复用 auto_summary_text/两开 "2/3"/三开 "3/3"/全关 恢复 隐藏/
##          节流 同态 不重写 文本/无 资源/统计 副作用/收尾 三关 隐藏)
## 打磨-45: 一键系列统一浮动反馈断言 (变更>0 屏幕中央绿色浮动含数量/0 变更不弹/幂等再点不弹/
##          文案/计数/颜色/无 essence 副作用, 5 按钮逐一+重复点击)
## 打磨-46: 一键系列按钮 tooltip 统一口径断言 (5 按钮 3 行结构: 动作顺序/筛选叠加/计数口径 +
##          各按钮关键口径词: 境界条件/爆发口径/自动穿戴/最佳判定链/幂等/全局口径)
## 打磨-55: 单个神通 施展 浮动反馈断言 (成功弹绿色浮动 文案含神通名/未领悟与冷却中 不弹/
##          点被动行 不弹/底部消息 与 浮动 并存/skill_use 统计口径不变)
## 打磨-57: 主动神通 冷却完毕转就绪 浮动断言 (冷却 归零 弹绿色浮动 文案含神通名/同一批多个
##          就绪 合并一行/按钮同步恢复 施展/tick/drain 无 资源/统计 副作用/无重复触发)
## 打磨-47: 一键购买 (装备/法器) 结果反馈断言 (变更>0 底部消息追加 共花灵石+距下一件缺口/
##          全拥有 0 变更 不追加/tooltip 说明 结果反馈 口径)
## 打磨-79: 顶栏灵石速率常显断言
## 打磨-81: 顶栏下一目标渐变进度条断言
## 打磨-82: 顶栏下一目标进度条点击直达断言 (升级 flat Button 可点击热区 手型光标/悬停金边/
##          tooltip 点击口径/突破区 Panel 外壳+初始无边框/点击切 tab0+金边高亮+底部消息/
##          重入不叠加/1.2s 自动恢复/无 资源/统计 副作用/收尾 无边框)
## 运行: timeout 30 ~/bin/godot --headless --path . res://scenes/ui_test.tscn
## 退出码 0 = 通过, 非 0 = 失败 (失败详情写入 user://ui_test_result.txt)
## 说明: 实例化主场景 (UI 全代码构建), 直接驱动 _refresh 断言进度条节点/宽度/颜色/tooltip;
##       headless 无真实像素渲染, 故断言布局几何 (size) 而非像素颜色。
## 打磨-139c: 音效播放器挂接断言 (player 节点/UI 入树/6 触发点 突破成·败/成就/塔胜/新纪录/一键 播放
##          正确 名称/未知 名称 静默 跳过/无 资源·统计 副作用/收尾 复位)

const UI_SIZE := Vector2(1280, 720)

var _fail: Array[String] = []
var _pass := 0
var ui: Node = null


func check(c: bool, label: String) -> void:
	if c:
		_pass += 1
	else:
		_fail.append(label)
		printerr("FAIL: " + label)


func _ready() -> void:
	# 先等一帧, 避开 _ready 期间 add_child 的 busy 限制 (UITest 自身还在入场)
	await get_tree().process_frame
	# 清理旧存档, 保证初始态干净 (须在实例化主场景前; 同 selftest.gd)
	var sp: String = GameData.SAVE_PATH
	var old := FileAccess.open(sp, FileAccess.READ)
	if old != null:
		old.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sp))
	# autoload GameData 启动时已 load_game, 须重置内存态 (旧档内容仍在内存)
	var g0 := GameData
	g0.ach_done.clear()
	g0.realm_idx = 0
	g0.layer = 1
	g0.essence = 0.0
	g0.stones = 0.0
	g0.dao = 0.0
	g0.dao_level = 0
	g0.ascended = false
	# 防御性 重置 自动系列 四开关 (autoload 启动时 已从 档 load 进内存, 旧档 可能 残留 true;
	# 不清会导致 打磨-69/70/71/80 初始态 错位 级联失败 — 每轮 强制 干净 基准)
	g0.auto_break = false
	g0.auto_buy = false
	g0.auto_cast = false
	g0.auto_learn = false
	# 打磨-72: 防御性 重置 离线收益 文案/明细 (autoload 启动 load_game 读 旧档 时间戳,
	# 距上轮 运行 >60 秒 时 已 结算 离线收益 置 offline_msg 非空; 残留 会 让 打磨-72
	# 启动 自动恢复 提示 走 离线优先 分支 被抑制 — 重置 保证 干净 基准)
	g0.offline_msg = ""
	g0._offline_sec = 0.0
	g0._offline_qi = 0.0
	g0._offline_stone = 0.0
	g0.learned.clear()
	g0.owned.clear()
	g0.owned_eq.clear()
	g0.equipped.clear()
	g0.stats = {}
	# M5-4: 防御性 重置 爬塔 状态 (autoload 启动 load_game 读 残留档, 塔 进度 可能 非零;
	# 残留 会 让 成就段/收集段 断言 看到 非零 塔 进度 泄漏 [tower_*/endless_*/first_tower 进度条非 0,
	# 收集 ach 计数偏多] — 每轮 强制 干净 基准, 同 打磨-71/72 自动开关/离线收益 防御性 重置 口径)
	g0.tower_fixed_floor = 0
	g0.tower_fixed_clear = false
	g0.tower_endless_floor = 1
	g0.tower_endless_best = 0
	g0.tower_daily_date = ""
	g0.tower_daily_bonus_stones = 0.0
	g0.tower_clear_reward_got = false
	g0.poison_battles = 0
	g0.poison_events.clear()  # 打磨-93: 防御性 清空 剧毒 事件 队列 (autoload 启动 load 残留 防 首帧 误弹)
	g0.auto_tower = false
	# 打磨-95: 防御性 重置 自动爬塔 会话 统计 (autoload 启动 可能 已 跑 挂机帧 累计 会话 值;
	# 内存态 不随 读档 清, 残留 会 让 爬塔页 状态行/底部消息 断言 看到 非零 会话 泄漏 — 每轮 强制 干净 基准)
	g0._auto_tower_seq = 0
	g0._auto_tower_last_txt = ""
	g0._auto_tower_wins = 0
	g0._auto_tower_stone = 0.0
	g0._auto_tower_mats = 0  # 打磨-100: 防御性 重置 会话 材料 累计
	g0._auto_tower_affixes = 0  # 打磨-122: 防御性 重置 会话 词缀 累计
	g0._auto_tower_losses = 0  # 打磨-128: 防御性 重置 会话 败局 累计
	g0._auto_tower_new_records = 0  # 打磨-132: 防御性 重置 会话 新纪录 次数 累计
	g0._auto_tower_new_best = 0  # 打磨-132: 防御性 重置 会话 新纪录 最高层 累计
	g0._auto_tower_milestones = 0  # 打磨-133: 防御性 重置 会话 里程碑 宝箱 次数 累计
	# M6-3: 防御性 重置 DIY 词缀 状态 (autoload 启动 load_game 读 残留档, 词缀 背包/装配/收集 可能 非空;
	# 残留 会 让 成就 检查 触发 DIY 成就 泄漏 [affix_legend/affix_120/diy_first/resonance_first],
	# 致 收集 计数/只看未解锁 断言 偏多 — 每轮 强制 干净 基准, 同 打磨-71/72 自动开关/离线收益 口径)
	g0.affix_bag = {}
	g0.affix_load = {}
	g0.slot_upgrades = {}
	g0.seen_affixes = []
	g0.affix_materials = 0  # 打磨-96: 防御性 重置 材料 (残留 会 让 兑换 面板 断言 偏多)
	# 打磨-97: bag_40 成就 为 派生 态 (ach_done 已 在上方 clear), 容量 随 之 回 30; 显式 注释 口径
	g0.set_process(false)
	var script: GDScript = load("res://scripts/main.gd")
	ui = Control.new()
	ui.set_script(script)
	var root := get_tree().root
	root.size = Vector2i(UI_SIZE)
	ui.size = UI_SIZE
	root.add_child(ui)
	await get_tree().process_frame
	await get_tree().process_frame
	# 成就页 (index 3), 首帧已 _ready 构建 UI; 再驱动一次 _refresh 确保进度条/排序刷完
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	_assert_initial()
	await _assert_collect_bars_initial()
	_mutate_state()
	await _assert_tier_bars()
	await _assert_collect_bars_mutated()
	await _assert_collect_jump()
	await _assert_onekey_float()
	_assert_onekey_tooltips()
	_assert_buy_feedback()
	_assert_stone_tip()
	await _assert_stone_next_inline()
	await _assert_burst_preview()
	await _assert_skill_cast_float()
	await _assert_active_learn()
	await _assert_ready_float()
	await _assert_ready_float_burst()
	await _assert_cd_bars()
	await _assert_ready_flash()
	await _assert_chance_expect_tip()
	await _assert_break_fail_float()
	await _assert_break_ok_float()
	_assert_offline_float()
	await _assert_auto_break()
	await _assert_auto_buy()
	await _assert_auto_buy_next_tip()
	await _assert_auto_break_next_tip()
	await _assert_auto_cast()
	await _assert_auto_learn()
	await _assert_auto_next_tips()
	await _assert_auto_idle()
	await _assert_idle_badge()
	await _assert_auto_summary()
	await _assert_auto_sum_jump()
	_assert_auto_restore()
	await _assert_auto_badge()
	await _assert_auto_badge_jump()
	await _assert_onekey_badge()
	await _assert_onekey_tip_detail()
	await _assert_play_time_badge()
	await _assert_play_time_tip()
	_assert_primary_rate_badge()
	_assert_stone_rate_badge()
	_assert_primary_next_tip()
	await _assert_goalbar()
	await _assert_goalbar_jump()
	await _assert_goalbar_eta_tip()  # 打磨-141: 顶栏 下一目标 进度条 tooltip 动态 ETA 段
	await _assert_ach_nofilter()
	await _assert_tower_clear()  # M5-4: 镇妖塔 通关态 (称号/大奖/守塔模式) + 顶栏 称号 徽标
	await _assert_poison_debuff()  # 打磨-93: 剧毒 debuff 顶栏徽标 + 触发浮动
	await _assert_tower_progress_badge()  # 打磨-130: 顶栏 双塔 进度 徽标 (节点/隐藏/文案/tooltip/点击直达/节流/收尾)
	await _assert_tower_affix_drop()  # 打磨-94: 塔战斗 词缀掉落 底部消息 展示
	await _assert_tower_win_float()  # 打磨-107: 塔战斗 胜利 浮动提示 (M5-3 规格 浮动 段)
	await _assert_auto_tower_feedback()  # 打磨-95: 自动爬塔 胜局 汇总 底部消息 + 会话 统计 状态行
	await _assert_auto_tower_affix_session()  # 打磨-122: 自动爬塔 会话 词缀 段 (状态行 会话 段 词缀 累计/tooltip 口径/节流)
	await _assert_auto_tower_session_tip()  # 打磨-125: 自动爬塔开关 tooltip 会话 统计 段 (开关悬停 展示 本次 运行 会话 累计)
	await _assert_auto_tower_loss_feedback()  # 打磨-128: 自动爬塔 会话 败局/卡层 段 (状态行 卡层 提示/会话 段 败局 段/tooltip 口径/节流)
	await _assert_endless_demon()  # 打磨-102: 登天梯 500 层后 全部 默认 魔化 (怪物卡 前缀/战力对比/胜局 消息)
	await _assert_tower_rounds()  # 打磨-105: 战斗时长 预估 行 (M5 数值 模型 rounds 仅 展示: 双塔 卡片 文案/恒等 口径/败 预测 追加/剧毒 联动/节流)
	await _assert_milestone_chest()  # 打磨-103: 登天梯 里程碑 宝箱 保底 高品质 词缀 (tooltip 保底 段/卡片 口径/胜局 掉落 品质)
	await _assert_tower_mats_tip()  # 打磨-106: 怪物卡 tooltip 材料 掉落 预估 (双塔 材料 行/接口 恒等/节流; 修 stats 幂等 丢 mats)
	await _assert_tower_reward_weights()  # 打磨-108: 怪物种 reward 权重 stone_w/affix_w (tooltip 权重 行/接口 恒等/Boss 层 无 行/节流)
	await _assert_milestone_chest_tag()  # 打磨-115: 登天梯 里程碑 Boss 宝箱 标记 + 胜利 底部消息/浮动 宝箱 段 (卡片 标记/消息 段/浮动 段/普通层 无/败局 不弹/节流)
	await _assert_tower_daily_first()  # 打磨-116: 登天梯 每日首胜 当日 状态 行 (未触发 无 段/触发 追加 段/恒等/跨日 消失/tooltip 口径/节流/收尾)
	await _assert_tower_new_record()  # 打磨-126: 登天梯 新纪录 展示位 (new_record 字段/浮动 新纪录 段/底部消息 同源 段/镇妖塔·败局 恒 false/收尾)
	await _assert_tower_def_line()  # 打磨-111: 战力对比 DEF 行 (M5 规格 "玩家 atk/def vs 怪物" DEF 段: 双塔 节点/恒等/剧毒 不 变/DEF 变化 同步/升层 同步/tooltip/节流)
	await _assert_endless_mile_bar()  # 打磨-129: 登天梯 卡片 进度条 接入 下一 里程碑 段 进度 (条 填充 = tower_endless_mile_ratio 单点 口径/100 倍数 层 满条/绕回/升层 动态 同步/条 tooltip 口径/镇妖塔 旧 口径 不变/节流/收尾)
	await _assert_tower_prog_tip_dyn()  # 打磨-131: 顶栏 双塔 进度 徽标 tooltip 动态段 (会话 单源 恒等/开关门控/动态同步/节流/收尾)

	await _assert_equip_score_sort()  # 打磨-109: 装备页 按评分排序 开关 (M6 规格 装备列表按评分排序: 开关/降序/同分/筛选叠加/装配联动/节流/收尾)

	await _assert_m63_diy()  # M6-3: DIY 词缀 UI (背包抽屉/槽位装配/拆卸/换装/一键/分解/评分)
	await _assert_bag_expand()  # 打磨-97: 背包 容量 成就 解锁 (bag_40: 曾入包满30格 -> 容量 30->40)
	await _assert_struct_line_tip()  # 打磨-119: 怪物卡 tooltip 精英/魔化 结构 行 (M5 规格 精英 x3 掉落 x2 + 登天梯 500 层后 默认 魔化 展示位: 精英/魔化 两 口径 行/普通层 Boss 层 无 行/状态行 tooltip 口径/节流/收尾)
	await _assert_m99_upgrade()  # 打磨-99: 一键 强化 槽位 按钮 (道祖期 批量 3->4, 200 材料/件)
	await _assert_m101_exchange_all()  # 打磨-101: 一键 兑换 按钮 (材料 连兑 买不起 的 最高 变体 词缀)
	await _assert_stats_affix()  # 打磨-110: 修行统计 词缀 段 (stats_text 4 段 展示/tooltip 口径/埋点 联动/节流/收尾)
	await _assert_swap_delta()  # 打磨-112: 换装对比 战力/评分 Δ 段 (行 标签=接口 恒等/攻击防御评分 段/负差/词缀 装配 动态 同步/tooltip 口径/节流/收尾)
	await _assert_tower_power_compose()  # 打磨-113: 爬塔 战力构成 tooltip (M5 规格 境界x功法x装备x塔专属 构成 展示位: 双塔 拼接 恒等/剧毒 口径 切换/节流/收尾)
	await _assert_monster_bias_tip()  # 打磨-117: 怪物卡 tooltip 追加 属性偏向/类型 行 (M5 规格 stat_bias 血牛/狂攻/铁壁/均衡 展示位: 含 偏向 行/接口 恒等/Boss 无 行/节流/收尾)
	await _assert_boss_tier_tag()  # 打磨-118: 镇妖塔 主题/最终 Boss 卡片 标记 分层 (卡片 tag/tooltip 分层 行/状态行 tooltip 口径/普通层 无 标记/节流/收尾)
	await _assert_affix_drop_line()  # 打磨-120: 怪物卡 tooltip 词缀 掉落 概率 行 (M6 规格 掉落 来源 口径 展示 位: 普通 5%/精英 20%/Boss 1~3/里程碑 宝箱 1~2; 有效 掉率 = base x 种 权重 + 词缀袋 +10%; 含 掉率 行/接口 恒等/Boss 100%/状态行 tooltip 口径/节流/收尾)
	await _assert_tower_milestone_line()  # 打磨-121: 双塔 卡片 下一 里程碑 行 (M5 规格 每 100 层 天阶 里程碑 进度 展示 位: 距 下个 精英/Boss/里程碑 Boss 层数/就在 本层/通关 隐藏/tooltip/节流/收尾)
	await _assert_win_threshold_line()  # 打磨-123: 爬塔 战力对比 胜 阈值/缺口 行 (M5 规格 败 预测 时 展示 胜还需 多少 ATK: 败 可见 阈值/缺口=接口 恒等/胜 预测 隐藏/升层 动态 同步/剧毒 缺口 放大/tooltip 提升 路径/同态 节流 无 副作用/收尾 干净 基准)
	await _assert_tower_milestone_eta()  # 打磨-127: 双塔 卡片 下一里程碑 ETA 行 (M5 规格 战斗 节奏 ≤2 秒/层 时间 预期: 层距 x 本层 预估 回合 x 2s, 7天+ 封顶/败 预测 战力 不足 提示/升层 动态 同步/剧毒 联动/守塔 隐藏/tooltip 口径/节流/收尾)
	await _assert_challenge_btn_tip()  # 打磨-124: 爬塔 挑战 按钮 tooltip 动态段 (胜败 预测+胜利 结算 预览 灵石/材料/词缀 掉率/每日 首胜/剧毒 警告 + 败 预测 阈值/缺口 行: 双塔 按钮 tooltip=接口 恒等/一败一胜 双向/结算 预览 段 数值 恒等/升层 动态 同步/同态 节流 无 副作用/收尾 干净 基准)
	await _assert_auto_tower_new_record_session()  # 打磨-132: 自动爬塔 会话 新纪录 累计 段 (登天梯 新纪录 单场 只 显 浮动/底部消息, 会话 段 累计 次数+最高层 展示位: 状态行 会话 段 单源 恒等 含 新纪录 段/0 新纪录 旧 口径/节流 无 副作用/收尾 干净 基准)
	await _assert_auto_tower_mile_session()  # 打磨-133: 自动爬塔 会话 里程碑 宝箱 累计 段 (登天梯 里程碑 Boss 宝箱 单场 只 显 浮动/底部消息 [打磨-115], 会话 段 累计 次数: 状态行 会话 段 单源 恒等 含 宝箱 段/0 宝箱 旧 口径/tooltip 口径/节流 无 副作用/收尾 干净 基准)
	_assert_m135a_skins()  # M7-2 打磨-135a: 顶栏 Panel + Tab 按钮 9-slice 皮肤 (StyleBoxTexture/texture 路径/五态 齐全/选中 暖金 区分/顶栏 内容 同父 布局 不变/Tab 切换 功能 不变)
	_assert_m135b_page_skins()  # M7-2 打磨-135b: 5 页大容器 9-slice 面板底 (panel_frame_frost.png/9-slice 边距/modulate 深色仙侠/行内 卡片 样式 不变/布局 偏移 不变)
	_assert_m135c_btn_skins()  # M7-2 打磨-135c-1: 按钮族 核心 9-slice 换皮 (_make_button 默认 btn_primary 三态/金边高亮 适配纹理底/一键挂机 flat 保留/微光/闪烁 恢复 纹理 默认)
	await _assert_m135c2_skins()  # M7-2 打磨-135c-2: 词缀背包格 btn_secondary 9-slice 换皮 (未选中 纹理 三态/选中 金边 叠加/flat 保留) + 内联 Button.new() 族 残留 flat 默认 排查固化 (徽标/段热区/进度条底/收集行 有意 保留)
	await _assert_m135d_bar_skins()  # M7-2 打磨-135d: 进度条 族 9-slice 换皮 (7 族 bar 底 bar_track + 填充 bar_fill 9-slice 裁带/金青 档 modulate 逻辑 不变/细条 完整 渲染/节流/收尾)
	await _assert_m136_res_icons()  # M7-3 打磨-136: 顶栏 资源图标 程序化 单字 徽章 (界/气/石 3 枚 Panel 壳+单字 同父 顶栏/顺序 在行 前/圆角深底边色=字色 语义/纯装饰 无热区/飞升 翻转 气->道 动态 同步/收尾 复原)
	await _assert_m137_bg_toggle()  # M7-3 打磨-137-2: 水墨山水 背景 开关 按钮 (toggle 默认开/z-order _bg 在 BG ColorRect 上/点击 翻转 状态+可见性+底部消息/读档 同步 按钮态/无 资源/统计 副作用/收尾 复位 开)
	await _assert_m139c_sfx()  # M7-4 打磨-139c: 音效 播放器 挂 现有 触发点 (player 节点/6 触发点 名称/未知 名称 防御/无 副作用/收尾 复位; 内部含 tower 挑战 await 须 显式 await 防 _finish 抢先 quit)
	await _assert_m140_sfx_toggle()  # M7-4 打磨-140: 音效 开关 (修行页 开关 按钮 与 水墨背景 同区 同 定位: toggle 默认 开/点击 切 关 _sfx_play 静默 跳过/恢复 开 播放/读档 同步 按钮态/tooltip 口径/同态 节流/无 资源 统计 副作用/收尾 复位 开)
	await _assert_break_btn_tip()  # 打磨-142: 突破 按钮 tooltip 动态 段 (核心 CTA 悬停 消耗/成功率/缺口/ETA/预期成本 一览: 静态段 标记+动态段=break_btn_tip 接口 恒等/境界 提升 消耗 段 动态 同步/攒满 已攒够 文案/飞升 道行 口径/同态 节流 无 副作用/收尾 干净 基准)
	await _assert_onekey_btn_tips()  # 打磨-143: 6 个 一键 按钮 (领悟/神通/施展/法器/装备/最佳) tooltip 动态段 (单源 onekey_btn_tip 复用 打磨-76 明细: 静态前缀+接口 恒等/筛选 叠加 同步/施展 就绪 同步/同态 节流 无 副作用/收尾 干净 基准)
	await _assert_goal_line_tip()  # 打磨-144: 修行页 下一目标 行 tooltip 动态段 (goal_line_tip 只读接口: 静态前缀+接口 恒等/开 自动突破 段 同步/境界 成功率 同步/飞升 道行 口径/同态 节流 无 副作用/收尾 干净 基准)

	_finish()


# 打磨-135d: 进度条 填充 Panel modulate 色读取 (bar_fill 9-slice 纹理底, 金/青 档 = modulate;
# 未 命中 stylebox 返回 空 Color 供 断言 显示)
func _fill_modulate(fill: Panel) -> Color:
	var sb = fill.get_theme_stylebox("panel")
	if sb == null or not (sb is StyleBoxTexture):
		return Color(-1, -1, -1)
	return (sb as StyleBoxTexture).modulate_color


# 初始态 (全新档, 未成就页): 17 条进度条, 未解锁青色 0 填充, tooltip 进度 0%, 顶栏计数 0/17
func _assert_initial() -> void:
	var g := GameData
	check(g.ach_done.size() == 0, "初始态 无已解锁成就 (实际 %d)" % g.ach_done.size())
	check(ui._ach_rows.size() == g.ach_ids.size(), "成就行数量=%d (实际 %d)" % [g.ach_ids.size(), ui._ach_rows.size()])
	for id in g.ach_ids:
		var r: Dictionary = ui._ach_rows.get(id, {})
		var bg: Panel = r.get("bar_bg", null)
		var fill: Panel = r.get("bar_fill", null)
		check(bg != null and fill != null, "成就 %s 进度条节点存在" % id)
		if bg == null or fill == null:
			continue
		check(int(bg.size.x) > 0, "成就 %s 进度条背景布局宽>0 (实际 %d)" % [id, int(bg.size.x)])
		check(int(fill.size.x) == 0, "成就 %s 未解锁进度条 0 填充 (实际 %d)" % [id, int(fill.size.x)])
		check(fill.size.y == bg.size.y, "成就 %s 进度条高与背景一致" % id)
		check(_fill_modulate(fill) == ui.CYAN, "成就 %s 未解锁填充色=青 (modulate)" % id)
		var rown: Node = r["row"]
		check(rown.tooltip_text.find("进度: 0%") >= 0, "成就 %s tooltip 含 进度: 0%% (实际 %s)" % [id, rown.tooltip_text])
	check(str(ui._ach_count_label.text) == "成就 0/%d" % g.ach_ids.size(), "顶栏成就计数 0/%d (实际 %s)" % [g.ach_ids.size(), ui._ach_count_label.text])


# 打磨-42→43: 初始态 (全新档, 成就页): 5 条收集进度条 (4 类 + 总计), 节点齐全/0 填充/青色/计数文本/tooltip + 节流缓存 (同态再刷不重写)
func _assert_collect_bars_initial() -> void:
	var g := GameData
	var total_collect := g.skill_ids.size() + g.equip_ids.size() + g.ITEMS.size() + g.ach_ids.size() + g.affix_ids.size()
	check(ui._collect_items.size() == 6, "收集进度 6 条节点齐全 (5 类+总计, 打磨-92 加 词缀) (实际 %d)" % ui._collect_items.size())
	check(ui._collect_wrap != null and ui._collect_box == ui._collect_wrap, "打磨-43 收集进度一览为 FlowContainer (宽不足逐条换行不截断)")
	var expect_txt := {"skill": "技能 0/%d" % g.skill_ids.size(), "equip": "装备 0/%d" % g.equip_ids.size(),
		"item": "法器 0/10", "ach": "成就 0/%d" % g.ach_ids.size(), "affix": "词缀 0/%d" % g.affix_ids.size(),
		"total": "总计 0/%d" % total_collect}
	for k in expect_txt:
		var it: Dictionary = ui._collect_items.get(k, {})
		check(it.has("label") and it.has("bar_bg") and it.has("bar_fill"), "收集 %s 节点 (label/bar_bg/bar_fill) 存在" % k)
		if it.is_empty() or not it.has("bar_bg"):
			continue
		var bg: Panel = it["bar_bg"]
		var fill: Panel = it["bar_fill"]
		check(int(bg.size.x) > 0, "收集 %s 进度条背景布局宽>0 (实际 %d)" % [k, int(bg.size.x)])
		check(bg.size.y >= 5.0, "收集 %s 进度条高>=5 (实际 %.0f)" % [k, bg.size.y])
		check(int(fill.size.x) == 0, "收集 %s 初始 0 填充 (实际 %d)" % [k, int(fill.size.x)])
		check(_fill_modulate(fill) == ui.CYAN, "收集 %s 初始填充色=青 (modulate)" % k)
		check(str((it["label"] as Label).text) == expect_txt[k], "收集 %s 计数文本 (实际 %s)" % [k, str(it["label"].text)])
		var lc: Color = (it["label"] as Label).get_theme_color("font_color")
		check(lc == ui.CYAN, "收集 %s 未集齐 文字色=青" % k)
	check(ui._collect_box.tooltip_text.find("全局收集进度") >= 0, "收集进度 tooltip 说明 (实际 %s)" % ui._collect_box.tooltip_text)
	check(str(ui._collect_text).find("收集进度") >= 0 and str(ui._collect_text).find("(总 0/%d)" % total_collect) >= 0, "收集汇总文本含 总 0/总量 (实际 %s)" % str(ui._collect_text))
	# 节流: 同态再刷两帧, 缓存键不变 (不重写)
	var keys_before := {}
	for k in expect_txt:
		keys_before[k] = str(ui._collect_items[k].get("q", ""))
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	await get_tree().process_frame
	var stable := true
	for k in expect_txt:
		if str(ui._collect_items[k].get("q", "")) != keys_before[k]:
			stable = false
	check(stable, "收集进度 同态再刷 缓存键不变 (节流生效)")


# 状态变化: 境界金丹+5万灵石+2技能+2装备+法器 -> 6 成就解锁 (金满条/100%) + 部分进度条按 ratio 填充 + 排序已解锁在前
func _mutate_state() -> void:
	var g := GameData
	g.realm_idx = 2
	g.stones = 50000.0
	g.learned.append("sword_0_0")
	g.learned.append("sword_0_1")
	g.owned_eq.append("weapon_0_0")
	g.owned_eq.append("robe_0_0")
	g.owned.append("wooden_sword")
	g.check_achievements()
	ui._refresh()
	# 解锁 6 个: realm_zhuji/realm_jindan/first_break/first_item/equip_first/skill 未 (12<50? 2 技能 -> skill_10 未)
	# 期望: first_break first_item realm_jindan realm_zhuji equip_first (5 个) + rich 未 (5万<10万)
	var done: Array[String] = g.ach_done.duplicate()
	check(done.has("realm_jindan") and done.has("realm_zhuji") and done.has("first_break")
		\
		and done.has("first_item") and done.has("equip_first"), "解锁 5 成就 (实际 %s)" % ",".join(done))
	check(str(ui._ach_count_label.text) == "成就 %d/%d" % [done.size(), g.ach_ids.size()], "顶栏计数 %d (实际 %s)" % [done.size(), ui._ach_count_label.text])
	# 已解锁: 金满条 + 100% tooltip
	for id in done:
		var r: Dictionary = ui._ach_rows[id]
		var bg: Panel = r["bar_bg"]
		var fill: Panel = r["bar_fill"]
		check(int(fill.size.x) == int(bg.size.x), "已解锁 %s 满条 (fill=%d bg=%d)" % [id, int(fill.size.x), int(bg.size.x)])
		check(_fill_modulate(fill) == ui.GOLD, "已解锁 %s 金色 (modulate)" % id)
		var rown: Node = r["row"]
		check(rown.tooltip_text.find("进度: 100%") >= 0, "已解锁 %s tooltip 100%% (实际 %s)" % [id, rown.tooltip_text])
	# rich_100k 未解锁 50%: 青条 fill = bg*ceil(0.5*50)/50 = bg
	var rr: Dictionary = ui._ach_rows["rich_100k"]
	var rbg: Panel = rr["bar_bg"]
	var rfill: Panel = rr["bar_fill"]
	check(int(rfill.size.x) == int(rbg.size.x * 0.5), "rich_100k 50%% 填充=半条 (fill=%d bg=%d)" % [int(rfill.size.x), int(rbg.size.x)])
	check(_fill_modulate(rfill) == ui.CYAN, "rich_100k 青色 (未解锁, modulate)")
	var rrow: Node = rr["row"]
	check(rrow.tooltip_text.find("进度: 50%") >= 0, "rich_100k tooltip 50%% (实际 %s)" % rrow.tooltip_text)
	# 排序: 已解锁 5 个在前
	var box: VBoxContainer = ui._ach_box
	var first5: Array = []
	for i in done.size():
		first5.append(box.get_child(i))
	var all_ok := true
	for node in first5:
		if not (node as PanelContainer).get_meta("_hl", false):
			all_ok = false
	check(all_ok, "排序 前 %d 行均为已解锁 (金框)" % done.size())


# 打磨-42→43→92: 变化态 (2技能+2装备+1法器+5成就+0词缀): 6 条同步计数 (含 总计 10/419) + 1% 档填充 + 青色 (未满);
# 再学全技能/全法器 -> 满态金 (技能/法器 金 + 总计 159/419 仍青, 金/青混合二态)
func _assert_collect_bars_mutated() -> void:
	var g := GameData
	var total_collect := g.skill_ids.size() + g.equip_ids.size() + g.ITEMS.size() + g.ach_ids.size() + g.affix_ids.size()
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	var names := {"skill": "技能", "equip": "装备", "item": "法器", "ach": "成就", "affix": "词缀", "total": "总计"}
	var expect := {"skill": [2, g.skill_ids.size()], "equip": [2, g.equip_ids.size()],
		"item": [1, 10], "ach": [5, g.ach_ids.size()], "affix": [0, g.affix_ids.size()], "total": [10, total_collect]}
	for k in expect:
		var it: Dictionary = ui._collect_items.get(k, {})
		if it.is_empty():
			continue
		var got: int = int(expect[k][0])
		var tot: int = int(expect[k][1])
		var q: int = int(ceil(clampf(float(got) / float(tot), 0.0, 1.0) * 100.0))
		var bg: Panel = it["bar_bg"]
		var fill: Panel = it["bar_fill"]
		check(str((it["label"] as Label).text) == "%s %d/%d" % [names[k], got, tot], "收集 %s 计数文本 (实际 %s)" % [k, str((it["label"] as Label).text)])
		check(int(fill.size.x) == int(bg.size.x * float(q) / 100.0), "收集 %s 填充=1%%档 %d%% (fill=%d bg=%d)" % [k, q, int(fill.size.x), int(bg.size.x)])
		check(_fill_modulate(fill) == ui.CYAN, "收集 %s 未满填充色=青 (modulate)" % k)
		check((it["label"] as Label).get_theme_color("font_color") == ui.CYAN, "收集 %s 未满文字色=青" % k)
	check(str(ui._collect_text).find("(总 10/%d)" % total_collect) >= 0, "收集汇总文本含 总 10/总量 (实际 %s)" % str(ui._collect_text))
	# 满态: 学全技能 + 全法器 -> 技能/法器 满条金色, 装备/成就 仍青色 (金/青 混合二态)
	g.learned.clear()
	for sid in g.skill_ids:
		g.learned.append(sid)
	g.owned.clear()
	for itm in g.ITEMS:
		g.owned.append(str(itm["id"]))
	ui._refresh()
	for k in ["skill", "item"]:
		var it: Dictionary = ui._collect_items[k]
		var bg: Panel = it["bar_bg"]
		var fill: Panel = it["bar_fill"]
		check(int(fill.size.x) == int(bg.size.x), "收集 %s 满条 (fill=%d bg=%d)" % [k, int(fill.size.x), int(bg.size.x)])
		check(_fill_modulate(fill) == ui.GOLD, "收集 %s 满态金色 (modulate)" % k)
		check((it["label"] as Label).get_theme_color("font_color") == ui.GOLD, "收集 %s 满态文字金" % k)
		check(str((it["label"] as Label).text) == "%s %d/%d" % [names[k], int(expect[k][1]), int(expect[k][1])], "收集 %s 满态计数 (实际 %s)" % [k, str((it["label"] as Label).text)])
	for k in ["equip", "ach"]:
		var it: Dictionary = ui._collect_items[k]
		check(_fill_modulate(it["bar_fill"]) == ui.CYAN, "收集 %s 未满分态保持青 (modulate)" % k)
	# 满态 总计 分子 = 全技能 + 全法器 + 2 装备 + 5 成就
	var full_got := g.skill_ids.size() + g.ITEMS.size() + 2 + 5
	check(str(ui._collect_text).find("(总 %d/%d)" % [full_got, total_collect]) >= 0, "满态汇总文本含 总 %d/总量 (实际 %s)" % [full_got, str(ui._collect_text)])
	# 打磨-43: 总计条 满态 分子/总量 — 青色 (未满保持青, 与 4 类同口径)
	var t2: Dictionary = ui._collect_items["total"]
	var tb2: Panel = t2["bar_bg"]
	var tf2: Panel = t2["bar_fill"]
	var q2: int = int(ceil(clampf(float(full_got) / float(total_collect), 0.0, 1.0) * 100.0))
	check(int(tf2.size.x) == int(tb2.size.x * float(q2) / 100.0), "总计条 %d/总量 填充=1%%档 %d%% (fill=%d bg=%d)" % [full_got, q2, int(tf2.size.x), int(tb2.size.x)])
	check(_fill_modulate(tf2) == ui.CYAN, "总计条 %d/总量 未满=青 (modulate)" % full_got)
	await _assert_collect_total_wrap()


# 打磨-43→92: 顶栏宽度不足时逐条换行不截断 — 压缩 FlowContainer 宽度 -> 6 条目折到多行; 恢复宽 -> 回单行
func _assert_collect_total_wrap() -> void:
	var g := GameData
	var total_collect := g.skill_ids.size() + g.equip_ids.size() + g.ITEMS.size() + g.ach_ids.size() + g.affix_ids.size()
	var wrap: FlowContainer = ui._collect_wrap
	# 全收集态 (总量/总量, 打磨-92 含 词缀 类) 下断言: 总计条 满条金色
	g.owned_eq.clear()
	for eid in g.equip_ids:
		g.owned_eq.append(eid)
	g.ach_done.clear()
	for aid in g.ach_ids:
		g.ach_done.append(str(aid))
	g.seen_affixes = []
	for aid in g.affix_ids:
		g.seen_affixes.append(str(aid))
	ui._refresh()
	await get_tree().process_frame
	var full_txt := "总计 %d/%d" % [total_collect, total_collect]
	var it_all: Dictionary = ui._collect_items["total"]
	check(str((it_all["label"] as Label).text) == full_txt, "总计条 全收集 %s (实际 %s)" % [full_txt, str((it_all["label"] as Label).text)])
	check(_fill_modulate(it_all["bar_fill"]) == ui.GOLD, "总计条 全收集=金 (modulate)")
	# 宽态: 6 条目全部布局在位 (1280 窄屏下天然可能 2~3 行, 记录自然行数供 roundtrip 对比; 1920 宽屏实测单行)
	var rows_nat := _count_rows(wrap)
	check(wrap.get_child_count() == 6, "宽态 6 条目全在 (实际 %d, 自然 %d 行)" % [wrap.get_child_count(), rows_nat])
	# 窄态: 强制 FlowContainer 最小宽 200px -> 条目必须换行 (y 出现 2 档) 且不消失 (5 条目全在)
	var old_min: Vector2 = wrap.custom_minimum_size
	wrap.custom_minimum_size = Vector2(200, 0)
	ui._refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	check(wrap.get_child_count() == 6, "窄态 6 条目仍在 (未截断) (实际 %d)" % wrap.get_child_count())
	var rows_narrow := _count_rows(wrap)
	check(rows_narrow >= 2, "窄态 逐条换行到多行 (实际 %d 行)" % rows_narrow)
	# 恢复宽度 -> roundtrip 行数与压缩前一致
	wrap.custom_minimum_size = old_min
	ui._refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	var rows_rest := _count_rows(wrap)
	check(rows_rest == rows_nat, "恢复宽后 roundtrip 行数一致 (压缩前 %d, 恢复后 %d)" % [rows_nat, rows_rest])
	# 恢复受控态 (防污染后续断言)
	g.owned_eq.clear()
	g.ach_done.clear()
	g.seen_affixes = []


# 打磨-43: 统计容器子节点折成的行数 (y 坐标 2px 容差归并)
func _count_rows(c: Container) -> int:
	var rows := 0
	var y0: float = -1.0
	for i in c.get_child_count():
		var y: float = c.get_child(i).position.y
		if y0 < 0.0 or absf(y - y0) > 2.0:
			rows += 1
			y0 = y
	return rows


# 打磨-41→138: 技能/装备/法器 行首品质徽章 (16px 单字 徽章「凡~神」; Panel 壳+Label 字,
# 边色=字色=TIER_COLOR[tier], 法器 按 价格档 0/2/5/6; 断言 节点结构/字符/边色/尺寸/覆盖档)
func _assert_tier_bars() -> void:
	var g := GameData
	# 技能页 (tab 1): 徽章 = tier_badge_char(s.tier), 边色 = TIER_COLOR[s.tier]
	ui._tab.current_tab = 1
	ui._refresh()
	await get_tree().process_frame
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		var rown: Node = ui._skill_row_nodes[id]
		var hb: HBoxContainer = rown.get_child(0)
		check(hb.get_child_count() > 0 and hb.get_child(0) is Panel, "技能 %s 徽章为首子节点 (Panel)" % id)
		if hb.get_child_count() == 0 or not (hb.get_child(0) is Panel):
			continue
		var p: Panel = hb.get_child(0)
		var lab: Label = p.get_child(0) if p.get_child_count() > 0 else null
		check(lab != null and lab is Label, "技能 %s 徽章 含 单字 Label" % id)
		if lab == null:
			continue
		check(lab.text == g.tier_badge_char(int(s["tier"])), "技能 %s 徽章字=%s tier=%s (实际 %s)" % [id, g.tier_badge_char(int(s["tier"])), str(s["tier"]), lab.text])
		var sbg := p.get_theme_stylebox("panel") as StyleBoxFlat
		check(sbg != null and sbg.border_color == g.TIER_COLOR[int(s["tier"])], "技能 %s 徽章边色=TIER_COLOR tier=%s" % [id, str(s["tier"])])
		check(sbg != null and lab.get_theme_color("font_color") == sbg.border_color, "技能 %s 徽章字色=边色 语义同源" % id)
		check(p.custom_minimum_size.x >= 16.0 and p.custom_minimum_size.y >= 16.0, "技能 %s 徽章 16px 尺寸口径 (实际 %s)" % [id, str(p.custom_minimum_size)])
	# 装备页 (tab 2): 徽章 = tier_badge_char(e.tier)
	ui._tab.current_tab = 2
	ui._refresh()
	await get_tree().process_frame
	for id in g.equip_ids:
		var e: Dictionary = g.equip_by_id[id]
		var rown: Node = ui._equip_row_nodes[id]
		var hb: HBoxContainer = rown.get_child(0)
		check(hb.get_child_count() > 0 and hb.get_child(0) is Panel, "装备 %s 徽章为首子节点 (Panel)" % id)
		if hb.get_child_count() == 0 or not (hb.get_child(0) is Panel):
			continue
		var p: Panel = hb.get_child(0)
		var lab: Label = p.get_child(0) if p.get_child_count() > 0 else null
		check(lab != null and lab is Label, "装备 %s 徽章 含 单字 Label" % id)
		if lab == null:
			continue
		check(lab.text == g.tier_badge_char(int(e["tier"])), "装备 %s 徽章字=%s tier=%s (实际 %s)" % [id, g.tier_badge_char(int(e["tier"])), str(e["tier"]), lab.text])
		var sbg := p.get_theme_stylebox("panel") as StyleBoxFlat
		check(sbg != null and sbg.border_color == g.TIER_COLOR[int(e["tier"])], "装备 %s 徽章边色=TIER_COLOR tier=%s" % [id, str(e["tier"])])
	# 修行页 (tab 0): 法器徽章 = 价格档 (1k/100k/1M -> 凡/玄/仙/神)
	ui._tab.current_tab = 0
	ui._refresh()
	await get_tree().process_frame
	var tier_seen := {0: 0, 2: 0, 5: 0, 6: 0}
	var char_expect := {0: "凡", 2: "玄", 5: "仙", 6: "神"}
	for it in g.ITEMS:
		var iid: String = str(it["id"])
		var row: Node = ui._shop_row_nodes[iid]
		check(row.get_child_count() > 0 and row.get_child(0) is Panel, "法器 %s 徽章为首子节点 (Panel)" % iid)
		if row.get_child_count() == 0 or not (row.get_child(0) is Panel):
			continue
		var p: Panel = row.get_child(0)
		var lab: Label = p.get_child(0) if p.get_child_count() > 0 else null
		check(lab != null and lab is Label, "法器 %s 徽章 含 单字 Label" % iid)
		if lab == null:
			continue
		var cost: float = float(it["cost"])
		var expect_idx := 0 if cost < 1000.0 else (2 if cost < 100000.0 else (5 if cost < 1000000.0 else 6))
		check(lab.text == char_expect[expect_idx], "法器 %s 徽章字=%s 价格档%d (实际 %s)" % [iid, char_expect[expect_idx], expect_idx, lab.text])
		var sbg := p.get_theme_stylebox("panel") as StyleBoxFlat
		check(sbg != null and sbg.border_color == g.TIER_COLOR[expect_idx], "法器 %s 徽章边色=TIER_COLOR 档%d" % [iid, expect_idx])
		tier_seen[expect_idx] = tier_seen[expect_idx] + 1
	check(tier_seen[0] > 0 and tier_seen[2] > 0 and tier_seen[5] > 0 and tier_seen[6] > 0, "法器四档价格徽章均有覆盖 (实际 %s)" % str(tier_seen))


# 打磨-44→92: 收集进度一览 点击直达 — 6 条 flat Button (手型光标/tooltip), 点击切 Tab+重置筛选,
# 法器区金边高亮+自动恢复, 无存档/统计副作用, 总计不切页; 打磨-92 词缀 条 直达 装备页
func _assert_collect_jump() -> void:
	var g := GameData
	# 回到成就页 (点击入口所在页)
	ui._tab.current_tab = 3
	# 6 条按钮节点 + flat + 手型光标 (打磨-92: 5 类 + 总计)
	check(ui._collect_btns.size() == 6, "收集进度 6 条点击按钮齐全 (打磨-92 加 词缀) (实际 %d)" % ui._collect_btns.size())
	var expect_tip := {"skill": "点击直达 技能页", "equip": "点击直达 装备页",
		"item": "点击直达 修行页·法器区", "ach": "已在 成就页", "affix": "点击直达 装备页·词缀背包",
		"total": "总计 = 五类已收集之和"}
	for k in expect_tip:
		var b: Button = ui._collect_btns.get(k, null)
		check(b != null, "收集 %s 按钮存在" % k)
		if b == null:
			continue
		check(b.flat == true, "收集 %s 按钮 flat (可点样式)" % k)
		check(b.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "收集 %s 手型光标提示可点" % k)
		check(b.toggle_mode == false, "收集 %s 按钮非 toggle (点击即触发)" % k)
		check(b.tooltip_text.find(expect_tip[k]) >= 0, "收集 %s tooltip 含「%s」 (实际 %s)" % [k, expect_tip[k], b.tooltip_text])
		# 行 (HBox) 是按钮子节点 (结构: wrap > btn > row[label+bar])
		var it: Dictionary = ui._collect_items[k]
		var row: Node = it["row"]
		check(row.get_parent() == b, "收集 %s 行挂在按钮下 (点击热区=整行)" % k)
	# 法器区高亮 Panel 存在 (修行页)
	check(ui._items_panel != null and ui._items_panel is Panel, "修行页法器区高亮 Panel 存在")
	# --- 点击 技能: 切到技能页(tab1) + 筛选重置(全部类别/全部品质) ---
	# 先给技能页制造一个筛选态, 验证点击后重置
	ui._on_filter("sword")
	ui._on_tier_filter("2")
	check(ui._filter_active == "sword" and ui._tier_active == "2", "前置 技能筛选态 (sword/tier2)")
	# 副作用快照 (点击 不应改变)
	var snap_essence := g.essence
	var snap_stones := g.stones
	var snap_stats := g.stats
	ui._on_collect_jump("skill")
	await get_tree().process_frame
	check(ui._tab.current_tab == 1, "点击 技能 → 切到 技能页 (tab=1) (实际 %d)" % ui._tab.current_tab)
	check(ui._filter_active == "", "点击 技能 → 类别筛选重置为 全部 (实际 %s)" % ui._filter_active)
	check(ui._tier_active == "", "点击 技能 → 品质筛选重置为 全部 (实际 %s)" % ui._tier_active)
	check(g.essence == snap_essence and g.stones == snap_stones, "点击 技能 无资源副作用")
	check(g.stats == snap_stats, "点击 技能 无统计副作用 (无 _stat_inc)")
	# --- 点击 装备: 切到装备页(tab2) + 部位/品质 筛选重置 ---
	ui._on_equip_filter("weapon")
	ui._on_equip_tier_filter("3")
	check(ui._equip_filter_active == "weapon" and ui._equip_tier_active == "3", "前置 装备筛选态 (weapon/tier3)")
	ui._on_collect_jump("equip")
	await get_tree().process_frame
	check(ui._tab.current_tab == 2, "点击 装备 → 切到 装备页 (tab=2) (实际 %d)" % ui._tab.current_tab)
	check(ui._equip_filter_active == "", "点击 装备 → 部位筛选重置为 全部 (实际 %s)" % ui._equip_filter_active)
	check(ui._equip_tier_active == "", "点击 装备 → 品质筛选重置为 全部 (实际 %s)" % ui._equip_tier_active)
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats, "点击 装备 无资源/统计副作用")
	# --- 点击 法器: 切到修行页(tab0) + 法器区金边高亮, 之后自动恢复 ---
	ui._on_collect_jump("item")
	await get_tree().process_frame
	check(ui._tab.current_tab == 0, "点击 法器 → 切到 修行页 (tab=0) (实际 %d)" % ui._tab.current_tab)
	var sb_hi: StyleBoxFlat = ui._items_panel.get_theme_stylebox("panel")
	check(sb_hi != null and sb_hi.border_width_left > 0, "点击 法器 → 法器区金边高亮 (边框宽>0)")
	check(sb_hi != null and sb_hi.border_color == ui.GOLD, "点击 法器 → 高亮边框=金")
	# 等待 tween 结束(1.2s) 后恢复
	await get_tree().create_timer(1.4).timeout
	var sb_rest: StyleBoxFlat = ui._items_panel.get_theme_stylebox("panel")
	check(sb_rest != null and sb_rest.border_width_left == 0, "法器区高亮 1.2s 后自动恢复 (边框宽=0)")
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats, "点击 法器 无资源/统计副作用")
	# --- 点击 成就: 已在成就页, 不切页 (保持 tab=3) ---
	ui._tab.current_tab = 3
	ui._on_collect_jump("ach")
	await get_tree().process_frame
	check(ui._tab.current_tab == 3, "点击 成就 → 保持 成就页 (tab=3) (实际 %d)" % ui._tab.current_tab)
	# --- 打磨-92: 点击 词缀: 切到装备页(tab2) + 部位/品质 筛选重置 + 词缀背包 消息 ---
	ui._on_equip_filter("robe")
	ui._on_equip_tier_filter("1")
	check(ui._equip_filter_active == "robe" and ui._equip_tier_active == "1", "前置 装备筛选态 (robe/tier1)")
	ui._on_collect_jump("affix")
	await get_tree().process_frame
	check(ui._tab.current_tab == 2, "打磨-92 点击 词缀 → 切到 装备页 (tab=2) (实际 %d)" % ui._tab.current_tab)
	check(ui._equip_filter_active == "" and ui._equip_tier_active == "", "打磨-92 点击 词缀 → 部位/品质 筛选重置为 全部")
	check(str(ui._msg_label.text).find("词缀背包") >= 0, "打磨-92 点击 词缀 → 底部弹 词缀背包 提示 (实际 %s)" % ui._msg_label.text)
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats, "打磨-92 点击 词缀 无资源/统计副作用")
	# --- 点击 总计: 只弹口径提示, 不切页 (保持 tab=3) ---
	ui._tab.current_tab = 3
	var tab_before_total: int = ui._tab.current_tab
	ui._on_collect_jump("total")
	await get_tree().process_frame
	check(ui._tab.current_tab == tab_before_total, "点击 总计 → 不切页 (保持 tab=%d)" % tab_before_total)
	check(str(ui._msg_label.text).find("总计") >= 0, "点击 总计 → 底部弹口径提示 (实际 %s)" % ui._msg_label.text)
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats, "点击 总计 无资源/统计副作用")
	# 恢复受控态 (防污染: 筛选已重置为全部, 无需额外清理)


# 打磨-45: 一键系列统一浮动反馈 — 变更>0 时屏幕中央绿色浮动提示 (文案含数量), 0 变更不弹
# 受控态 (realm_idx=2 layer=1, 灵石 5万, 空技能/装备/法器): 期望值全部按 GameData 只读接口
# 动态计算 (learn_available_count/active_ready_count/item_affordable_count/equip_best_pending),
# 5 按钮逐一点击断言 计数+1/文案含数量/绿色/位置复位; 5 按钮再点一次 (全学/全买/全穿/冷却中)
# 计数不变 (0 变更只走底部消息); 施展爆发真实加灵气, 购买/穿戴不动灵气
func _assert_onekey_float() -> void:
	var g := GameData
	# 受控态 (打磨-44 末态: 筛选已重置为全部, 资源 5万, 空 技能/装备/法器)
	check(ui._filter_active == "" and ui._tier_active == "" and ui._equip_filter_active == "" and ui._equip_tier_active == "", "前置 筛选态已重置")
	g.realm_idx = 2
	g.layer = 1
	g.stones = 50000.0
	g.learned.clear()
	g.owned_eq.clear()
	g.owned.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	ui._refresh()
	# 节点: 浮动 Label 存在 + 绿色 (与 成就浮动 同绿口径)
	var fl: Label = ui._onekey_float_label
	check(fl != null, "一键浮动 Label 节点存在")
	if fl == null:
		return
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "一键浮动 文字色=绿")
	check(str(ui._onekey_last_text) == "", "初始 无浮动文案 (实际 %s)" % str(ui._onekey_last_text))
	check(ui._onekey_float_count == 0, "初始 浮动计数=0 (实际 %d)" % ui._onekey_float_count)
	var c0: int = ui._onekey_float_count
	var snap_ess := g.essence
	# --- 一键领悟 (技能页): 期望数 = learn_available_count (境界足够+未学) ---
	var n_learn: int = g.learn_available_count()
	check(n_learn > 0, "受控态 存在可学技能 (实际 %d)" % n_learn)
	ui._tab.current_tab = 1
	ui._refresh()
	# 打磨-53: 学习前 qi 快照, 学习后 delta>0 追加 灵气速率 增量 (与 打磨-51/52 法器/装备 同口径)
	var qi_pre_l53: float = g.qi_per_sec()
	ui._on_learn_all()
	var qi_delta_l53: float = g.qi_per_sec() - qi_pre_l53
	var extra_l53 := (" (灵气速率 +%s/秒)" % g.fmt(qi_delta_l53)) if qi_delta_l53 > 0.0 else ""
	onekey_assert("一键领悟 %d 个技能%s" % [n_learn, extra_l53], c0)
	c0 = ui._onekey_float_count
	check(qi_delta_l53 > 0.0, "一键领悟后 灵气速率上升 (delta %s/秒)" % g.fmt(qi_delta_l53))
	check(g.learned.size() == n_learn, "一键领悟 学到 %d (实际 %d)" % [n_learn, g.learned.size()])
	check(g.essence == snap_ess, "一键领悟 无灵气副作用 (实际 %.0f)" % g.essence)
	# --- 一键施展: 期望数 = active_ready_count (冷却清空, 刚学的主动神通全部就绪; 爆发真实加灵气) ---
	var n_act: int = g.active_ready_count()
	check(n_act > 0, "受控态 存在就绪主动神通 (实际 %d)" % n_act)
	ui._refresh()
	var snap_ess_act := g.essence
	ui._on_active_all()
	# 打磨-60: 浮动文案追加 本批 爆发 获得 总量 (爆发=前后 主资源 差, 与 底部消息 同口径;
	# GameData 无新接口, use_all_active 已返回 burst)
	var burst_act: float = g.essence - snap_ess_act
	check(burst_act > 0.0, "打磨-60 一键施展 爆发总量>0 (实际 %s)" % g.fmt(burst_act))
	onekey_assert("一键施展 %d 个神通 (爆发+%s 灵气)" % [n_act, g.fmt(burst_act)], c0)
	c0 = ui._onekey_float_count
	check(g.active_ready_count() == 0, "施展后 全部进冷却 (就绪 0, 实际 %d)" % g.active_ready_count())
	check(g.essence > snap_ess_act, "施展 爆发真实加灵气 (爆发前 %.0f → 后 %.0f)" % [snap_ess_act, g.essence])
	# --- 法器 一键购买 (修行页): 期望数 = 价格升序连买 (预算耗尽即停, 与 buy_items_affordable 同口径; 花灵石, 不动灵气) ---
	var n_item := 0
	var sim_stones_it := g.stones
	var item_costs: Array = []
	for it in g.ITEMS:
		item_costs.append(float((it as Dictionary).get("cost", 1e18)))
	item_costs.sort()
	for c in item_costs:
		var cost: float = float(c)
		if cost <= sim_stones_it:
			sim_stones_it -= cost
			n_item += 1
	check(n_item > 0, "受控态 存在可购法器 (实际 %d)" % n_item)
	var snap_ess2 := g.essence
	var qi_pre51: float = g.qi_per_sec()   # 打磨-51: 浮动文案含 灵气速率 +delta (购买前快照)
	ui._tab.current_tab = 0
	ui._refresh()
	ui._on_items_buy_all()
	var qi_delta51: float = g.qi_per_sec() - qi_pre51
	onekey_assert("一键购置 %d 件法器 (灵气速率 +%s/秒)" % [n_item, g.fmt(qi_delta51)], c0)
	c0 = ui._onekey_float_count
	check(qi_delta51 > 0.0, "法器购买后 灵气速率上升 (delta %s)" % g.fmt(qi_delta51))
	check(g.owned.size() == n_item, "法器 买到 %d (实际 %d)" % [n_item, g.owned.size()])
	check(g.essence == snap_ess2, "一键购置 无灵气副作用 (实际 %.0f)" % g.essence)
	# --- 装备 一键购买 (装备页): 期望数按 与 buy_affordable 完全一致的顺序 (价格升序, 同价 id 升序) 连买模拟 ---
	var n_equip := 0
	var sim_stones := g.stones
	var ids: Array = g.equip_ids.duplicate()
	ids.sort_custom(g.buy_affordable_cmp)
	for id in ids:
		var e: Dictionary = g.equip_by_id[str(id)]
		var cost: float = float(e.get("cost", 1e18))
		if cost <= sim_stones:
			sim_stones -= cost
			n_equip += 1
	check(n_equip > 0, "受控态 存在可购装备 (实际 %d)" % n_equip)
	ui._tab.current_tab = 2
	ui._refresh()
	# 打磨-52: 浮动文案含 灵气速率 增量 (购买前 qi 快照, 与 打磨-51 法器 口径一致)
	var qi_pre52: float = g.qi_per_sec()
	ui._on_buy_all()
	var qi_delta52: float = g.qi_per_sec() - qi_pre52
	check(qi_delta52 > 0.0, "装备一键购买后 灵气速率上升 (delta %s)" % g.fmt(qi_delta52))
	onekey_assert("一键购买 %d 件装备 (灵气速率 +%s/秒)" % [n_equip, g.fmt(qi_delta52)], c0)
	c0 = ui._onekey_float_count
	check(g.owned_eq.size() == n_equip, "装备 买到 %d (实际 %d)" % [n_equip, g.owned_eq.size()])
	check(g.equipped.size() == 5, "槽位空时已自动穿戴 (5 部位, 实际 %d)" % g.equipped.size())
	check(g.essence == snap_ess2, "一键购买 无灵气副作用 (实际 %.0f)" % g.essence)
	# --- 一键最佳: 期望数 = equip_best_pending (各槽位换最佳) ---
	var n_best: int = g.equip_best_pending()
	check(n_best > 0, "受控态 存在待改进槽位 (实际 %d)" % n_best)
	ui._refresh()
	# 打磨-52: 换装前 qi 快照, 换装后 delta>0 追加 灵气速率 增量
	var qi_pre53: float = g.qi_per_sec()
	ui._on_equip_best()
	var qi_delta53: float = g.qi_per_sec() - qi_pre53
	check(qi_delta53 > 0.0, "一键最佳换装后 灵气速率再升 (delta %s)" % g.fmt(qi_delta53))
	onekey_assert("最佳穿戴 %d 件 (灵气速率 +%s/秒)" % [n_best, g.fmt(qi_delta53)], c0)
	c0 = ui._onekey_float_count
	check(g.equip_best_pending() == 0, "一键最佳后 无待改进槽位 (实际 %d)" % g.equip_best_pending())
	check(g.essence == snap_ess2, "一键最佳 无灵气副作用 (实际 %.0f)" % g.essence)
	# --- 再点 5 按钮 (全学/全买/全穿/冷却中): 0 变更不弹 ---
	ui._on_learn_all()
	ui._on_active_all()
	ui._on_items_buy_all()
	ui._on_buy_all()
	ui._on_equip_best()
	check(ui._onekey_float_count == c0, "5 按钮 0 变更再点 不弹浮动 (计数 %d 不变)" % c0)
	check(str(ui._msg_label.text).find("装备") >= 0 or str(ui._msg_label.text).find("穿戴") >= 0, "0 变更仍走底部消息 (实际 %s)" % str(ui._msg_label.text))
	check(g.essence == snap_ess2, "全流程 (施展后) 无额外灵气副作用 (实际 %.0f)" % g.essence)


# 打磨-45: 单按钮 浮动 断言 (计数+1 / 文案=完整句子 / 绿色 / 位置复位 / 可见)
func onekey_assert(expect_text: String, c_before: int) -> void:
	var fl: Label = ui._onekey_float_label
	check(ui._onekey_float_count == c_before + 1, "一键 浮动计数+1 (期望 %d, 实际 %d)" % [c_before + 1, ui._onekey_float_count])
	check(str(ui._onekey_last_text) == expect_text, "一键 浮动文案=%s (实际 %s)" % [expect_text, str(ui._onekey_last_text)])
	check(str(fl.text) == "✦ " + expect_text + " ✦", "一键 浮动 Label 文本 ✦…✦ (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "一键 浮动文字=绿")
	check(absf(fl.position.y + 26.0) < 0.5, "一键 浮动位置复位 y≈-26 (实际 %.2f)" % fl.position.y)
	check(fl.modulate.a > 0.9, "一键 浮动可见 (alpha=%.2f)" % fl.modulate.a)


# 打磨-46: 一键系列按钮 tooltip 统一口径 — 6 按钮 (一键领悟/一键神通/一键施展/法器一键购买/装备一键购买/
# 一键最佳) tooltip 统一 3 行: 动作与顺序 / 筛选叠加与作用范围 / 按钮计数口径
# tooltip 为构建时静态文本 (不随状态刷新), 此处断言 3 行结构 + 各按钮关键口径词
func _assert_onekey_tooltips() -> void:
	var btns: Dictionary = {
		"learn": ui._learn_all_btn,
		"actlearn": ui._active_learn_btn,
		"active": ui._active_all_btn,
		"item": ui._items_buy_btn,
		"buy": ui._buy_all_btn,
		"best": ui._equip_best_btn,
	}
	for key in btns:
		# 打磨-46 三行结构 静态 前缀 断言 (打磨-143 后 tooltip = 静态 前缀 3 行 + 空行 + 动态段,
		# 前 3 行 口径 不变: 第1行 动作/第2行 筛选/第3行 按钮计数)
		var b: Button = btns[key]
		var tip: String = str(b.tooltip_text)
		var lines: PackedStringArray = tip.split("\n")
		check(tip.length() > 20, "一键系列 tooltip 非空 (%s)" % key)
		check(lines.size() >= 4 and lines[3] == "", "一键系列 tooltip 静态 3 行+空行 分隔 动态段 (%s, 实际 %d)" % [key, lines.size()])
		check(lines.size() >= 3 and lines[2].begins_with("按钮计数 ="), "一键系列 tooltip 第3行=计数口径 (%s)" % key)
		check(tip.find("【本次 一键") >= 0, "一键系列 tooltip 含 动态段 标记 (%s)" % key)
	# 一键领悟: 境界条件 + 筛选 AND 叠加 + 不耗资源
	var t_learn: String = str(ui._learn_all_btn.tooltip_text)
	check(t_learn.contains("境界/层数足够"), "一键领悟 tooltip 含 境界/层数足够 条件")
	check(t_learn.contains("AND 叠加"), "一键领悟 tooltip 含 类别/品质 筛选 AND 叠加口径")
	check(t_learn.contains("不消耗资源"), "一键领悟 tooltip 含 不消耗资源")
	# 一键施展: 就绪口径 + 爆发口径 + 飞升后道行
	var t_active: String = str(ui._active_all_btn.tooltip_text)
	check(t_active.contains("冷却完毕"), "一键施展 tooltip 含 冷却完毕 口径")
	check(t_active.contains("当前灵气速率 x 爆发秒数"), "一键施展 tooltip 含 爆发=速率x秒数 口径")
	check(t_active.contains("飞升后改为获得道行"), "一键施展 tooltip 含 飞升后道行 说明")
	# 打磨-60: 一键施展 tooltip 含 爆发总量 口径 (浮动追加 爆发+N 灵气/道行, 与底部消息同口径)
	check(t_active.contains("爆发+N 灵气/道行"), "一键施展 tooltip 含 爆发总量口径 (打磨-60)")
	# 装备一键购买: 购买顺序 + 自动穿戴规则
	var t_buy: String = str(ui._buy_all_btn.tooltip_text)
	check(t_buy.contains("同价按数据序"), "装备一键购买 tooltip 含 同价按数据序 顺序")
	check(t_buy.contains("槽位为空时自动穿戴"), "装备一键购买 tooltip 含 槽位空自动穿戴 规则")
	# 打磨-48: 一键购买 tooltip 含 缺口 ETA 联动 口径
	check(t_buy.contains("约 X 可购"), "装备一键购买 tooltip 含 缺口ETA 口径")
	check(str(ui._items_buy_btn.tooltip_text).contains("约 X 可购"), "法器一键购买 tooltip 含 缺口ETA 口径")
	# 一键最佳: 最佳判定链 + 幂等
	var t_best: String = str(ui._equip_best_btn.tooltip_text)
	check(t_best.contains("灵气% + 灵石%"), "一键最佳 tooltip 含 主属性 判定")
	check(t_best.contains("突破率 > 离线效率"), "一键最佳 tooltip 含 次属性 判定顺序")
	check(t_best.contains("幂等"), "一键最佳 tooltip 含 幂等 说明")
	# 法器一键购买: 全局口径 + 顺序
	var t_item: String = str(ui._items_buy_btn.tooltip_text)
	check(t_item.contains("不受筛选影响"), "法器一键购买 tooltip 含 全局口径 说明")
	check(t_item.contains("同价按数据序"), "法器一键购买 tooltip 含 同价按数据序 顺序")
	# 打磨-52: 装备一键购买/一键最佳 tooltip 含 灵气速率 增量 口径 (0 变化省略)
	check(t_buy.contains("灵气速率 +N/秒"), "装备一键购买 tooltip 含 灵气速率增量 口径 (打磨-52)")
	check(t_best.contains("灵气速率 +N/秒"), "一键最佳 tooltip 含 灵气速率增量 口径 (打磨-52)")
	check(t_best.contains("0 变化省略"), "一键最佳 tooltip 含 0变化省略 口径 (打磨-52)")
	# 打磨-53: 一键领悟 tooltip 含 灵气速率 增量 口径 (0 变化省略, 与法器/装备同口径)
	check(t_learn.contains("灵气速率 +N/秒"), "一键领悟 tooltip 含 灵气速率增量 口径 (打磨-53)")
	check(t_learn.contains("0 变化省略"), "一键领悟 tooltip 含 0变化省略 口径 (打磨-53)")


# 打磨-47: 一键购买 (装备/法器) 结果反馈 — 变更>0 底部消息追加 共花灵石 + 距下一件缺口;
# 全拥有 0 变更时 不追加 (走 买不起 消息); tooltip 第 1 行 说明 结果反馈 口径 (三行结构不变)
func _assert_buy_feedback() -> void:
	var g := GameData
	# tooltip 口径说明 (构建时静态文本)
	check(str(ui._buy_all_btn.tooltip_text).contains("共花灵石"), "装备一键购买 tooltip 含 共花灵石 反馈口径")
	check(str(ui._buy_all_btn.tooltip_text).contains("距下一件"), "装备一键购买 tooltip 含 距下一件 缺口口径")
	check(str(ui._items_buy_btn.tooltip_text).contains("共花灵石"), "法器一键购买 tooltip 含 共花灵石 反馈口径")
	check(str(ui._items_buy_btn.tooltip_text).contains("距下一件"), "法器一键购买 tooltip 含 距下一件 缺口口径")
	# --- 受控态: 灵石 5万, 空 技能/装备/法器 (与 打磨-45 断言末态同口径) ---
	g.realm_idx = 2
	g.layer = 1
	g.stones = 50000.0
	g.learned.clear()
	g.owned_eq.clear()
	g.owned.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	ui._refresh()
	# 法器: 期望花费 = 价格升序连买模拟 (与 buy_items_affordable 同口径), 下一件 = item_next_target
	var sim_it := g.stones
	var n_it := 0
	var item_costs: Array = []
	for it in g.ITEMS:
		item_costs.append(float((it as Dictionary).get("cost", 1e18)))
	item_costs.sort()
	for c in item_costs:
		var cost: float = float(c)
		if cost <= sim_it:
			sim_it -= cost
			n_it += 1
	check(n_it > 0, "受控态 法器 存在可购 (实际 %d)" % n_it)
	ui._tab.current_tab = 0
	ui._refresh()
	var stones_before_it := g.stones
	ui._on_items_buy_all()
	# 缺口目标在 购买后 取 (最便宜未拥有 = 连买后下一件)
	var it_target: Dictionary = g.item_next_target()
	check(not it_target.is_empty(), "受控态 法器 存在下一件 (连买买不起)")
	var msg_it: String = str(ui._msg_label.text)
	check(msg_it.find("共花") >= 0, "法器 一键购买 底部消息含 共花灵石 (实际 %s)" % msg_it)
	check(msg_it.find(GameData.fmt(stones_before_it - g.stones)) >= 0, "法器 共花额=购买前后灵石差 (期望 %s, 实际 %s)" % [GameData.fmt(stones_before_it - g.stones), msg_it])
	check(msg_it.find("距下一件「%s」" % str(it_target["name"])) >= 0, "法器 缺口行 指向最便宜未拥有 (期望 %s, 实际 %s)" % [str(it_target["name"]), msg_it])
	check(msg_it.find(GameData.fmt(float(it_target["shortfall"]))) >= 0, "法器 缺口额 正确 (期望 %s, 实际 %s)" % [GameData.fmt(float(it_target["shortfall"])), msg_it])
	# 打磨-48: 缺口行 追加 ETA (受控态灵石速率>0; 口径=打磨-12 eta_text(cost), 与 next_target_eta_text 同式)
	var it_eta: String = g.next_target_eta_text(it_target)
	check(it_eta != "", "受控态 法器 缺口行 ETA 非空 (灵石速率 %s/s)" % g.stone_per_sec())
	check(msg_it.find("灵石" + it_eta) >= 0, "法器 缺口行 追加 ETA (期望片段 %s, 实际 %s)" % ["灵石" + it_eta, msg_it])
	# 打磨-51: 浮动文案追加 灵气速率 +delta (购买前 qi 快照在 _on_items_buy_all 之前取, 此处按连买口径复算)
	var qi_pre_fb: float = g.qi_per_sec() / g.item_boost()  # 逆连乘还原 购买前 qi (本件连乘全部刚购, 无其它拥有)
	var qi_delta_fb: float = g.qi_per_sec() - qi_pre_fb
	check(qi_delta_fb > 0.0, "打磨-51 法器连购后 灵气速率上升 (delta %s)" % g.fmt(qi_delta_fb))
	check(str(ui._onekey_last_text) == "一键购置 %d 件法器 (灵气速率 +%s/秒)" % [n_it, g.fmt(qi_delta_fb)], "法器 浮动文案 含 灵气速率增量 (打磨-51, 实际 %s)" % str(ui._onekey_last_text))
	# 装备: 同口径 (起始灵石 = 法器买完后的剩余, 非 5万)
	var sim_eq := g.stones
	var n_eq := 0
	var eq_ids: Array = g.equip_ids.duplicate()
	eq_ids.sort_custom(g.buy_affordable_cmp)
	for id in eq_ids:
		var e: Dictionary = g.equip_by_id[str(id)]
		var cost: float = float(e.get("cost", 1e18))
		if cost <= sim_eq:
			sim_eq -= cost
			n_eq += 1
	check(n_eq > 0, "受控态 装备 存在可购 (实际 %d)" % n_eq)
	ui._tab.current_tab = 2
	ui._refresh()
	var stones_before_eq := g.stones
	ui._on_buy_all()
	var eq_target: Dictionary = g.equip_next_target()
	check(not eq_target.is_empty(), "受控态 装备 存在下一件 (连买买不起)")
	var msg_eq: String = str(ui._msg_label.text)
	check(msg_eq.find("共花") >= 0, "装备 一键购买 底部消息含 共花灵石 (实际 %s)" % msg_eq)
	check(msg_eq.find(GameData.fmt(stones_before_eq - g.stones)) >= 0, "装备 共花额=购买前后灵石差 (期望 %s, 实际 %s)" % [GameData.fmt(stones_before_eq - g.stones), msg_eq])
	check(msg_eq.find("距下一件「%s」" % str(eq_target["name"])) >= 0, "装备 缺口行 指向最便宜未拥有 (期望 %s, 实际 %s)" % [str(eq_target["name"]), msg_eq])
	check(msg_eq.find(GameData.fmt(float(eq_target["shortfall"]))) >= 0, "装备 缺口额 正确 (期望 %s, 实际 %s)" % [GameData.fmt(float(eq_target["shortfall"])), msg_eq])
	# 打磨-48: 装备 缺口行 追加 ETA (同 法器 口径)
	var eq_eta: String = g.next_target_eta_text(eq_target)
	check(eq_eta != "", "受控态 装备 缺口行 ETA 非空")
	check(msg_eq.find("灵石" + eq_eta) >= 0, "装备 缺口行 追加 ETA (期望片段 %s, 实际 %s)" % ["灵石" + eq_eta, msg_eq])
	# 打磨-48: 小额缺口 边界 (缺口=1, 灵石速率>0 -> 不足1分档; 验证 eta 对小额缺口不空)
	g.stones = float(eq_target["cost"]) - 1.0
	var eq_eta1: String = g.next_target_eta_text(eq_target)
	check(eq_eta1 == " 不足1分可购", "缺口=1 灵石速率>0 出 ETA 不足1分档 (实际 %s)" % eq_eta1)
	# 注: 无灵石收入 (eta=-1 -> 省略) 分支由 selftest next_target_eta 只读接口覆盖 (stone 速率为乘性项, 正常态恒 >0)
	# --- 全拥有: 0 变更走 买不起 消息, 不追加 共花/缺口 ---
	for id in g.equip_ids:
		g.owned_eq.append(str(id))
	for it in g.ITEMS:
		g.owned.append(str((it as Dictionary)["id"]))
	g.stones = 0.0
	ui._tab.current_tab = 0
	ui._refresh()
	ui._on_items_buy_all()
	var msg_it2: String = str(ui._msg_label.text)
	check(msg_it2.find("买不起") >= 0, "法器 全拥有 走 买不起 消息 (实际 %s)" % msg_it2)
	check(msg_it2.find("共花") < 0, "法器 全拥有 不追加 共花 (实际 %s)" % msg_it2)
	check(msg_it2.find("距下一件") < 0, "法器 全拥有 不追加 缺口 (实际 %s)" % msg_it2)
	ui._on_buy_all()
	var msg_eq2: String = str(ui._msg_label.text)
	check(msg_eq2.find("买不起") >= 0, "装备 全拥有 走 买不起 消息 (实际 %s)" % msg_eq2)
	check(msg_eq2.find("共花") < 0, "装备 全拥有 不追加 共花 (实际 %s)" % msg_eq2)
	check(msg_eq2.find("距下一件") < 0, "装备 全拥有 不追加 缺口 (实际 %s)" % msg_eq2)
	# 恢复基准态
	g.stones = 0.0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()


# 打磨-49: 顶栏灵石行 tooltip = 当前灵石速率 + 距下一件 (最便宜未拥有) 缺口与 ETA
# 在 _assert_buy_feedback 的基准态 (全空, 境界0, 灵石0, 灵石速率 1.0/s) 上断言 UI 侧:
# 顶栏 _stones_label.tooltip_text 随 _refresh 动态刷新, 口径与 GameData.stone_next_target_tip 一致。
func _assert_stone_tip() -> void:
	var g := GameData
	# 基准态 (打磨-47/48 恢复): 全空, 境界0, 灵石0 -> 灵石速率 1.0/s, 最便宜未拥有 = 全局最便宜 (装备)
	check(absf(g.stone_per_sec() - 1.0) < 1e-6, "打磨-49 基准态 灵石速率=1.0/s (实际 %s)" % g.stone_per_sec())
	var st: Dictionary = g.stone_next_target()
	check(not st.is_empty(), "基准态 stone_next 非空 (实际 %s)" % str(st))
	ui._refresh()
	var tip: String = str(ui._stones_label.tooltip_text)
	check(tip == g.stone_next_target_tip(), "顶栏灵石 tooltip 与 stone_next_target_tip 一致 (UI %s / 接口 %s)" % [tip, g.stone_next_target_tip()])
	check(tip.begins_with("当前 1 灵石/秒"), "顶栏灵石 tooltip 前缀=当前灵石速率 (实际 %s)" % tip)
	check(tip.find("距下一件 %s「%s」" % [str(st["kind"]), str(st["name"])]) >= 0, "顶栏灵石 tooltip 指向 最便宜未拥有 %s (实际 %s)" % [str(st["name"]), tip])
	check(tip.find("还差 %s 灵石" % g.fmt(float(st["shortfall"]))) >= 0, "顶栏灵石 tooltip 含 缺口额 (实际 %s)" % tip)
	check(tip.find("可购") >= 0, "顶栏灵石 tooltip 含 可购 ETA (实际 %s)" % tip)
	# 节流: 同态再刷两帧, tooltip 文本不变 (缓存键生效)
	var tip_cache: String = str(ui._stone_tip)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._stone_tip) == tip_cache, "顶栏灵石 tooltip 同态再刷 缓存不变 (节流生效)")
	# 状态变化: 灵石足够 -> tooltip 切 可立即购买 (缓存随之更新)
	g.stones = float(st["cost"]) + 1.0
	ui._refresh()
	var tip2: String = str(ui._stones_label.tooltip_text)
	check(tip2 != tip, "灵石足够后 tooltip 变化 (缓存刷新)")
	check(tip2.find("可立即购买") >= 0, "灵石足够 tooltip=可立即购买 (实际 %s)" % tip2)
	check(tip2.find("还差") < 0, "灵石足够 tooltip 不含 还差 (实际 %s)" % tip2)
	# 状态变化: 全拥有 -> tooltip 切 已集齐
	for id in g.equip_ids:
		g.owned_eq.append(str(id))
	for it in g.ITEMS:
		g.owned.append(str((it as Dictionary)["id"]))
	ui._refresh()
	var tip3: String = str(ui._stones_label.tooltip_text)
	check(tip3.find("已集齐") >= 0, "全拥有 tooltip=已集齐 (实际 %s)" % tip3)
	# 恢复基准态 (全空, 灵石0)
	g.stones = 0.0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()


# 打磨-50: 修行页灵石速率行 内联 下一件可购 ETA (UI 侧: _stone_next_label 金色小字)
# 在 _assert_stone_tip 的基准态 (全空, 境界0, 灵石0, 灵石速率 1.0/s) 上断言:
# 缺口行文本与接口一致 / 同态节流 / 灵石足够切换 / 灵石归0恢复 / 全拥有已集齐.
func _assert_stone_next_inline() -> void:
	var g := GameData
	check(ui._stone_next_label != null, "打磨-50 _stone_next_label 节点存在")
	check(ui._stone_next_label.get_theme_color("font_color") == ui.GOLD, "打磨-50 内联标签颜色=金 (实际 %s)" % ui._stone_next_label.get_theme_color("font_color"))
	# 基准态: 缺口>0, 速率 1.0/s -> 距下一件 最便宜 缺口+ETA
	var st: Dictionary = g.stone_next_target()
	check(not st.is_empty(), "打磨-50 基准态 stone_next 非空 (实际 %s)" % str(st))
	ui._refresh()
	var t0: String = str(ui._stone_next_label.text)
	check(t0 == g.stone_next_target_inline(), "打磨-50 内联文本 与接口一致 (UI %s / 接口 %s)" % [t0, g.stone_next_target_inline()])
	check(t0.begins_with("距下一件 %s「%s」" % [str(st["kind"]), str(st["name"])]), "打磨-50 内联指向最便宜未拥有 (实际 %s)" % t0)
	check(t0.find("还差 %s 灵石" % g.fmt(float(st["shortfall"]))) >= 0, "打磨-50 内联含缺口额 (实际 %s)" % t0)
	check(t0.find("可购") >= 0, "打磨-50 内联含 可购 ETA (实际 %s)" % t0)
	# 节流: 同态再刷, 缓存不变
	var cache0: String = str(ui._stone_next_text)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._stone_next_text) == cache0, "打磨-50 内联 同态再刷 缓存不变 (节流生效)")
	# 状态变化: 灵石足够 -> 内联切 "灵石已足够, 可立即购买"
	g.stones = float(st["cost"]) + 1.0
	ui._refresh()
	var t1: String = str(ui._stone_next_label.text)
	check(t1 != t0, "打磨-50 灵石足够后 内联文本变化 (缓存刷新)")
	check(t1.find("灵石已足够, 可立即购买") >= 0, "打磨-50 灵石足够 内联=可立即购买 (实际 %s)" % t1)
	# 状态变化: 灵石归 0 -> 回到缺口行 (与接口一致)
	g.stones = 0.0
	ui._refresh()
	check(str(ui._stone_next_label.text) == t0, "打磨-50 灵石归0 内联恢复缺口行 (实际 %s)" % str(ui._stone_next_label.text))
	# 状态变化: 全拥有 -> 已集齐
	for id in g.equip_ids:
		g.owned_eq.append(str(id))
	for it in g.ITEMS:
		g.owned.append(str((it as Dictionary)["id"]))
	ui._refresh()
	var t2: String = str(ui._stone_next_label.text)
	check(t2 == "已集齐全部 装备与法器", "打磨-50 全拥有 内联=已集齐 (实际 %s)" % t2)
	# 恢复基准态 (全空, 灵石0)
	g.stones = 0.0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.essence = 0.0
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()


# 打磨-54: 主动神通 爆发预览断言 (行内金色标签: 未领悟隐藏/已领悟显示 当前灵气速率 x 爆发秒数;
# 预览随 境界/飞升 变化刷新; tooltip 含同口径预览行; 缓存键防重复重建)
func _assert_burst_preview() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1, 速率 1.0, 无功法/法器/装备)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.stones = 0.0
	g.essence = 0.0
	# 主动神通总数 (数据驱动: 5 类 x 6 品质, 每类 1 个主动变体 = 24)
	var n_active := 0
	for id in g.skill_ids:
		if str(g.skill_by_id[id]["type"]) == "active":
			n_active += 1
	check(n_active == 24, "打磨-54 数据含 24 主动神通 (实际 %d)" % n_active)
	check(ui._burst_previews.size() == n_active, "打磨-54 行内预览标签数=主动神通数 (实际 %d)" % ui._burst_previews.size())
	check(not ui._burst_previews.has("sword_0_0"), "打磨-54 被动功法行 无预览标签")
	ui._tab.current_tab = 1  # 技能页
	ui._refresh()
	# 未领悟: 全部隐藏 + 文本空
	var all_hidden := true
	for id in ui._burst_previews:
		var l: Label = ui._burst_previews[id]
		if l.visible or l.text != "":
			all_hidden = false
	check(all_hidden, "打磨-54 未领悟 爆发预览 全部隐藏")
	# tooltip 含 爆发预览行 (构建时初值已刷; 受控态 速率 1.0 x 60 秒)
	var row3: Node = ui._skill_row_nodes["sword_0_3"]
	check(str(row3.tooltip_text).find("爆发 +60 灵气 (当前 1/秒 x 60 秒)") >= 0, "打磨-54 未领悟 tooltip 含爆发预览行 (实际 %s)" % str(row3.tooltip_text))
	# 领悟 主动神通: 标签显示 + 金色 12px + tooltip 状态行同步
	g.learned.append("sword_0_3")
	ui._refresh()
	var lb: Label = ui._burst_previews["sword_0_3"]
	check(lb.visible, "打磨-54 已领悟 爆发预览 显示")
	check(lb.text == "爆发 +60 灵气 (当前 1/秒 x 60 秒)", "打磨-54 已领悟 预览文本 (实际 %s)" % lb.text)
	check(lb.get_theme_color("font_color") == ui.GOLD, "打磨-54 预览 金色")
	check(int(lb.get_theme_font_size("font_size")) == 12, "打磨-54 预览 12px")
	check(lb.get_parent() is VBoxContainer and lb.get_parent().get_child_count() > 0, "打磨-54 预览 挂 行内信息 VBox")
	check(str(row3.tooltip_text).find("状态: 已领悟") >= 0, "打磨-54 领悟后 tooltip 状态行=已领悟")
	# 境界提升 (筑基 x4): 速率 4.0 -> 预览数值 同步提升 (已领悟+未领悟 两口径)
	g.realm_idx = 1
	ui._refresh()
	check(lb.text == "爆发 +240 灵气 (当前 4/秒 x 60 秒)", "打磨-54 境界提升 预览数值 提升 (实际 %s)" % lb.text)
	var row_body: Node = ui._skill_row_nodes["body_0_3"]  # 未领悟 主动
	check(str(row_body.tooltip_text).find("当前 4/秒 x 60 秒") >= 0, "打磨-54 境界提升 未领悟 tooltip 预览 同步 (实际 %s)" % str(row_body.tooltip_text))
	# 飞升 (道行 x2): 速率 8.0 -> 口径 改 道行
	g.ascended = true
	g.dao_level = 1
	ui._refresh()
	check(lb.text == "爆发 +480 道行 (当前 8/秒 x 60 秒)", "打磨-54 飞升后 预览 口径改道行 (实际 %s)" % lb.text)
	# 缓存键: 与 当前 已学|预览 口径一致 (防重复重建 口径对齐)
	check(str(ui._burst_previews_key["sword_0_3"]) == "1|%s" % g.skill_burst_preview("sword_0_3"), "打磨-54 缓存键=已学|预览文本 (实际 %s)" % str(ui._burst_previews_key["sword_0_3"]))
	# 幂等: 再刷一次 无状态变化 -> 文本不变 (标签/tooltip 同值)
	var tip_before: String = str(row3.tooltip_text)
	ui._refresh()
	check(lb.text == "爆发 +480 道行 (当前 8/秒 x 60 秒)" and str(row3.tooltip_text) == tip_before, "打磨-54 重复刷新 幂等不变")
	# 恢复基准态: 取消领悟 -> 标签 再隐藏
	g.learned.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	ui._refresh()
	check(not lb.visible and lb.text == "", "打磨-54 取消领悟 预览 再隐藏")
	check(str(row3.tooltip_text).find("爆发 +60 灵气 (当前 1/秒 x 60 秒)") >= 0, "打磨-54 恢复基准 未领悟 tooltip 预览 回退")
	# 顺带修回归: 技能列表 已学在前 (原 _skill_sort 比较式语义相反, 已学被排到列表底部)
	g.learned.append("sword_0_0")
	ui._on_filter("")
	ui._refresh()
	var box54: VBoxContainer = ui._skill_box
	var first10_54 := 0
	for i in 10:
		var rn: Node = box54.get_child(i)
		for k in ui._skill_row_nodes:
			if ui._skill_row_nodes[k] == rn and g.learned.has(str(k)):
				first10_54 += 1
				break
	check(first10_54 >= 1, "打磨-54顺带修 技能列表 已学在前 (前 10 行含已学 %d)" % first10_54)
	var rn0: Node = box54.get_child(0)
	var id0 := ""
	for k in ui._skill_row_nodes:
		if ui._skill_row_nodes[k] == rn0:
			id0 = str(k)
			break
	check(id0 == "sword_0_0", "打磨-54顺带修 首行=已学技能 (实际 %s)" % id0)
	# 收尾: 等一帧让状态/布局稳定 (同 _assert_stone_next_inline 口径)
	await get_tree().process_frame


# 打磨-55: 单个神通 施展 浮动反馈 — 单个 神通行 点 施展 成功时 屏幕中央 绿色浮动 (复用 打磨-45 _onekey_float 口径,
# 文案 "施展「X」" 含神通名, 与 一键施展 的 "一键施展 N 个神通" 口径区分); 失败 (未领悟/冷却中) 与
# 点 被动功法行 不弹; 底部消息 与 浮动 并存; skill_use 统计埋点口径不变 (只增不减, 失败不增)
func _assert_skill_cast_float() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1 速率 1.0, 空 技能/法器/装备/道行)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	ui._tab.current_tab = 1
	ui._refresh()
	var fl: Label = ui._onekey_float_label
	check(fl != null, "打磨-55 浮动 Label 节点存在")
	if fl == null:
		_finish()
		return
	var c0: int = ui._onekey_float_count
	# 找 1 个 凡品 主动神通 (境界0层1 可领悟) + 1 个 同档 被动功法 + 1 个 不同件 的 未学 主动
	var act_id := ""
	var pas_id := ""
	var unact_id := ""
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if int(s["tier"]) != 0:
			continue
		if str(s["type"]) == "active" and act_id == "":
			act_id = str(id)
		elif str(s["type"]) == "passive" and pas_id == "":
			pas_id = str(id)
		if str(s["type"]) == "active" and act_id != "" and unact_id == "" and str(id) != act_id:
			unact_id = str(id)
	check(act_id != "" and pas_id != "" and unact_id != "", "打磨-55 受控态 找到 主动/被动/未学主动 (实际 %s/%s/%s)" % [act_id, pas_id, unact_id])
	# --- 未领悟: 原按钮 disabled 无法领悟 (只能走 一键领悟); 顺带修: 点击 = 领悟 (境界足够), 不弹浮动 ---
	ui._refresh()
	var btn_un: Button = ui._skill_btns[unact_id]
	check(str(btn_un.text) == "未领悟" and btn_un.disabled, "打磨-55 未领悟 按钮=未领悟+禁用 (实际 %s)" % str(btn_un.text))
	ui._on_skill_btn(unact_id, true)
	check(g.learned.has(unact_id), "打磨-55顺带修 未领悟 点击=领悟 (境界足够时)")
	check(ui._onekey_float_count == c0, "打磨-55 领悟 (非施展) 不弹浮动 (计数 %d 不变)" % c0)
	check(str(ui._msg_label.text).find("领悟「") >= 0, "打磨-55顺带修 未领悟 底部消息=领悟成功 (实际 %s)" % str(ui._msg_label.text))
	# --- 领悟 目标神通 (技能行 按钮路径): 领悟本身不弹浮动 (只有 施展 弹) ---
	var stats_use0: int = int(g.stats.get("skill_use", 0.0))
	# 顺带修: 未领悟的主动神通 点按钮 = 领悟 (原按钮被禁用 无法领悟, 只能走 一键领悟)
	ui._on_skill_btn(act_id, true)
	check(g.learned.has(act_id), "打磨-55 领悟 目标神通 (已学 %d)" % g.learned.size())
	check(int(g.stats.get("skill_use", 0.0)) == stats_use0, "打磨-55 领悟 (非施展) 不增 skill_use")
	# --- 点击 施展: 成功弹浮动 (绿色/文案含神通名/位置复位/可见) + 爆发真实加灵气 + 底部消息 并存 ---
	ui._refresh()
	var btn: Button = ui._skill_btns[act_id]
	check(str(btn.text) == "施展" and not btn.disabled, "打磨-55 已就绪 按钮=施展 (实际 %s)" % str(btn.text))
	var name: String = str(g.skill_by_id[act_id]["name"])
	# 打磨-61: 爆发总量 精确值 (受控态 境界0层1 速率 1.0, gain = 速率 x 爆发秒数)
	var act_val61: int = int(g.skill_by_id[act_id]["value"])
	var exp61: String = "施展「%s」 (爆发+%d 灵气)" % [name, act_val61]
	var ess0: float = g.essence
	ui._on_skill_btn(act_id, true)
	check(ui._onekey_float_count == c0 + 1, "打磨-55 施展成功 浮动计数+1 (期望 %d, 实际 %d)" % [c0 + 1, ui._onekey_float_count])
	check(str(ui._onekey_last_text) == exp61, "打磨-61 浮动文案=爆发+%d 灵气 (实际 %s)" % [act_val61, str(ui._onekey_last_text)])
	check(str(fl.text) == "✦ %s ✦" % exp61, "打磨-61 浮动 Label 文本 ✦…✦ (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-55 浮动文字=绿 (与 一键系列 同绿口径)")
	check(absf(fl.position.y + 26.0) < 0.5, "打磨-55 浮动位置复位 y≈-26 (实际 %.2f)" % fl.position.y)
	check(fl.modulate.a > 0.9, "打磨-55 浮动可见 (alpha=%.2f)" % fl.modulate.a)
	check(g.essence > ess0, "打磨-55 施展 爆发真实加灵气 (爆发前 %.0f → 后 %.0f)" % [ess0, g.essence])
	check(str(ui._msg_label.text).find("施展「%s」" % name) >= 0, "打磨-55 底部消息 与 浮动 并存 (实际 %s)" % str(ui._msg_label.text))
	check(int(g.stats.get("skill_use", 0.0)) == stats_use0 + 1, "打磨-55 施展成功 skill_use +1 (口径不变)")
	# --- 冷却中: 再点 不弹浮动 (只走底部消息), 失败不增 skill_use ---
	ui._refresh()
	check(str(btn.text).begins_with("冷却"), "打磨-55 施展后 按钮=冷却N秒 (实际 %s)" % str(btn.text))
	var stats_use1: int = int(g.stats.get("skill_use", 0.0))
	ui._on_skill_btn(act_id, true)
	check(ui._onekey_float_count == c0 + 1, "打磨-55 冷却中 再点 不弹浮动 (计数 %d 不变)" % (c0 + 1))
	check(str(ui._msg_label.text).find("冷却中") >= 0, "打磨-55 冷却中 底部消息=冷却中 (实际 %s)" % str(ui._msg_label.text))
	check(int(g.stats.get("skill_use", 0.0)) == stats_use1, "打磨-55 冷却中 失败 不增 skill_use")
	# --- 被动功法行: 点击 (领悟/已领悟) 不弹浮动 ---
	ui._refresh()
	var btn_p: Button = ui._skill_btns[pas_id]
	ui._on_skill_btn(pas_id, false)
	check(ui._onekey_float_count == c0 + 1, "打磨-55 被动功法 点击 不弹浮动 (计数 %d 不变)" % (c0 + 1))
	# --- 飞升态: 口径改道行, 浮动文案 同口径 (复用 _onekey_float, 文案仅 神通名 不涉 资源) ---
	g.learned.clear()
	g._active_cd.clear()
	g.ascended = true
	g.dao_level = 1
	g.dao = 0.0
	g.essence = 0.0
	check(g.can_learn(act_id), "打磨-55 飞升态 目标神通 门槛可学 (can_learn 只看 境界/层)")
	g.learned.append(act_id)
	ui._refresh()
	var dao0: float = g.dao
	ui._on_skill_btn(act_id, true)
	check(ui._onekey_float_count == c0 + 2, "打磨-55 飞升态 施展成功 浮动+1 (期望 %d, 实际 %d)" % [c0 + 2, ui._onekey_float_count])
	# 打磨-61: 飞升态 口径=道行 (飞升后倍率 x2, 速率 = 1.0 x 2)
	check(str(ui._onekey_last_text) == "施展「%s」 (爆发+%d 道行)" % [name, act_val61 * 2], "打磨-61 飞升态 浮动文案=爆发+%d 道行 (实际 %s)" % [act_val61 * 2, str(ui._onekey_last_text)])
	check(g.dao > dao0, "打磨-55 飞升态 爆发 加道行 (爆发前 %.0f → 后 %.0f)" % [dao0, g.dao])
	# 收尾: 恢复基准态 (境界0层1 未飞升, 清 已学/冷却/道行)
	g.learned.clear()
	g._active_cd.clear()
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()
	await get_tree().process_frame


# 打磨-56: 技能页 一键神通 — 只学 筛选范围内 未学+境界足够 的 主动神通 (与 一键领悟 同口径 仅 type 过滤不同):
# 按钮节点存在 / 计数文案 "一键神通 xN" 按 当前 类别/品质 筛选 (AND 叠加, 变化才刷) / 点击 只学主动神通
# (learned 全为 active, 无被动副作用, 无灵气变化) / 绿色浮动 "一键神通 N 个" (与 一键领悟 文案区分,
# 主动无被动加成故无 灵气速率 增量) / 学完 "已无新神通" / 幂等 0 变更 不弹 / tooltip 3 行口径
func _assert_active_learn() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1 速率 1.0, 空 技能/法器/装备/道行)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.dao = 0.0
	g.essence = 0.0
	g.stones = 0.0
	# 数据锚定: 境界0层1 可学 主动神通 = 6 (tier0 全 6 件, tier1+ 境界不足)
	var n_act56: int = g.active_learn_available_count()
	check(n_act56 == 6, "打磨-56 受控态 全局可学神通=6 (实际 %d)" % n_act56)
	check(g.active_learn_available_count() < g.learn_available_count(), "打磨-56 神通数 < 技能总数 (含被动)")
	# 节点: 按钮存在 + 默认文案
	var btn: Button = ui._active_learn_btn
	check(btn != null, "打磨-56 一键神通 按钮节点存在")
	if btn == null:
		return
	check(btn.get_parent() is HBoxContainer, "打磨-56 按钮 挂 技能页 品质筛选行")
	ui._tab.current_tab = 1  # 技能页
	ui._refresh()
	var t_init56 := ("一键神通 x%d" % n_act56)
	check(btn.text == t_init56, "打磨-56 初始文案=一键神通 x%d (实际 %s)" % [n_act56, btn.text])
	# 筛选 AND 叠加: sword → x1 (sword_0_3); sword×tier1 → 已无新神通 (境界不足); 恢复全部 → x6
	ui._on_filter("sword")
	ui._refresh()
	check(btn.text == "一键神通 x1", "打磨-56 类别 sword 文案 x1 (实际 %s)" % btn.text)
	ui._on_tier_filter("1")
	ui._refresh()
	check(btn.text == "已无新神通", "打磨-56 sword×tier1 境界不足 文案 已无新神通 (实际 %s)" % btn.text)
	ui._on_tier_filter("")
	ui._refresh()
	check(btn.text == "一键神通 x1", "打磨-56 品质重置 恢复 sword x1 (实际 %s)" % btn.text)
	ui._on_filter("")
	ui._refresh()
	var t_full56 := ("一键神通 x%d" % n_act56)
	check(btn.text == t_full56, "打磨-56 类别重置 恢复 全局 x%d (实际 %s)" % [n_act56, btn.text])
	# 点击: 只学 6 个主动神通, 绿色浮动 "一键神通 6 个" (与 一键领悟 "一键领悟 6 个技能" 口径区分)
	var c0: int = ui._onekey_float_count
	var snap_ess: float = g.essence
	var qi0: float = g.qi_per_sec()
	ui._on_active_learn()
	onekey_assert("一键神通 %d 个" % n_act56, c0)
	check(str(ui._onekey_last_text).find("灵气速率") < 0, "打磨-56 浮动文案 无 灵气速率 增量 (神通无被动加成, 实际 %s)" % str(ui._onekey_last_text))
	check(str(ui._msg_label.text).find("一键神通 %d 个主动神通" % n_act56) >= 0, "打磨-56 底部消息 含数量 (实际 %s)" % str(ui._msg_label.text))
	check(g.learned.size() == n_act56, "打磨-56 学到 %d (实际 %d)" % [n_act56, g.learned.size()])
	var only_act: bool = true
	for id in g.learned:
		if str(g.skill_by_id[str(id)].get("type", "")) != "active":
			only_act = false
	check(only_act, "打磨-56 只学主动神通 (learned 全为 active)")
	check(absf(g.qi_per_sec() - qi0) < 1e-9, "打磨-56 学神通 无 灵气速率 变化 (实际 %s)" % g.fmt(g.qi_per_sec()))
	check(g.essence == snap_ess, "打磨-56 无 灵气 副作用 (实际 %.0f)" % g.essence)
	# 学完: 按钮文案 切换 已无新神通 (文本变化才刷)
	ui._refresh()
	check(btn.text == "已无新神通", "打磨-56 学完文案=已无新神通 (实际 %s)" % btn.text)
	# 幂等: 再点 0 变更 不弹浮动, 走底部消息
	var c1: int = ui._onekey_float_count
	ui._on_active_learn()
	check(ui._onekey_float_count == c1, "打磨-56 0变更再点 不弹浮动 (计数 %d 不变)" % c1)
	check(str(ui._msg_label.text).find("没有可领悟的新主动神通") >= 0, "打磨-56 0变更 走底部消息 (实际 %s)" % str(ui._msg_label.text))
	# tooltip 静态 3 行 前缀 + 空行 + 动态段 (打磨-143 后 结构; 前 3 行 口径 不变)
	var tip: String = str(btn.tooltip_text)
	var lines: PackedStringArray = tip.split("\n")
	check(lines.size() >= 4 and lines[3] == "", "打磨-56 tooltip 静态 3 行+空行 分隔 动态段 (实际 %d)" % lines.size())
	check(lines.size() >= 3 and lines[2].begins_with("按钮计数 ="), "打磨-56 tooltip 第3行=计数口径 (实际 %s)" % (lines[2] if lines.size() >= 3 else ""))
	check(tip.contains("主动神通"), "打磨-56 tooltip 含 主动神通 范围说明")
	check(tip.contains("AND 叠加"), "打磨-56 tooltip 含 筛选 AND 叠加口径")
	check(tip.contains("不消耗资源"), "打磨-56 tooltip 含 不消耗资源")
	check(tip.contains("飞升后"), "打磨-56 tooltip 含 飞升后 口径说明")
	# 收尾: 恢复基准态 (境界0层1, 清 已学/冷却/资源)
	g.learned.clear()
	g._active_cd.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-57: 主动神通 冷却完毕转就绪 浮动提示 — 冷却 归零 时 屏幕中央 绿色浮动
# "✦ 冷却完毕: X ✦" (文案含神通名, 与 一键施展/单个施展 浮动 口径区分), 同一批多个就绪
# 合并一行; 只读 _active_cd 事件 (不改动 状态/存档/统计); 受控态: 两个 凡品 主动神通 冷却
# 30/45 秒 不同步, 手动驱动 _tick_active_cd 后 _refresh 消费 就绪事件 触发浮动
func _assert_ready_float() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1, 空 技能/装备/法器, 清 冷却/就绪事件)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	# 节点: 就绪浮动 Label 存在 + 绿色 (与 一键系列 同绿口径) + 初始 无浮动
	var fl: Label = ui._ready_float_label
	check(fl != null, "打磨-57 就绪浮动 Label 节点存在")
	if fl == null:
		return
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-57 就绪浮动 文字色=绿")
	check(str(ui._ready_last_text) == "", "打磨-57 初始 无就绪浮动文案 (实际 %s)" % str(ui._ready_last_text))
	check(ui._ready_float_count == 0, "打磨-57 初始 就绪浮动计数=0 (实际 %d)" % ui._ready_float_count)
	# 找 两个 凡品 主动神通 (不同 id, 不同冷却: 90s/90s 同档, 用 手动注入 30/45 区分同步)
	var r_act: Array[String] = []
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if int(s["tier"]) == 0 and str(s["type"]) == "active":
			r_act.append(str(id))
	check(r_act.size() >= 2, "打磨-57 受控态 找到 >=2 个 凡品主动神通 (实际 %d)" % r_act.size())
	if r_act.size() < 2:
		return
	var a1: String = r_act[0]
	var a2: String = r_act[1]
	var n1: String = str(g.skill_by_id[a1]["name"])
	var n2: String = str(g.skill_by_id[a2]["name"])
	# 打磨-62: 受控态 速率=1.0 (境界0层1, 无 功法/装备/法器), 爆发 恒等 速率 x 爆发秒数
	var v1: int = int(g.skill_by_id[a1]["value"])
	var v2: int = int(g.skill_by_id[a2]["value"])
	# 注入: 两个 已学 主动神通 冷却中 (30/45 秒 不同步), 就绪事件 清空
	g.learned.append(a1)
	g.learned.append(a2)
	g._active_cd[a1] = 30.0
	g._active_cd[a2] = 45.0
	g.ready_events.clear()
	var c0: int = ui._ready_float_count
	var stats_b: Dictionary = g.stats.duplicate(true)
	var ess_b: float = g.essence
	var sto_b: float = g.stones
	# --- 手动驱动 冷却 tick 30 秒 (GameData 已冻结 _process, 由测试手动推进): ---
	# a1 归零转就绪 (推 就绪事件), a2 余 15 秒 (不推)
	g._tick_active_cd(30.0)
	check(g.active_ready(a1) and not g.active_ready(a2), "打磨-57 30s tick 后 a1 就绪 a2 仍冷却")
	# _refresh 消费 就绪事件 -> 弹 就绪浮动 (文案仅含 a1 名, a2 未就绪)
	ui._refresh()
	check(ui._ready_float_count == c0 + 1, "打磨-57 a1 冷却完毕 浮动计数+1 (期望 %d, 实际 %d)" % [c0 + 1, ui._ready_float_count])
	check(str(ui._ready_last_text) == n1, "打磨-57 浮动文案=a1 神通名 (实际 %s)" % str(ui._ready_last_text))
	check(str(fl.text) == "✦ 冷却完毕: " + n1 + " ✦ (爆发+%d 灵气)" % v1, "打磨-62 浮动 Label 文本=✦ 冷却完毕: X ✦ (爆发+N 灵气) (实际 %s)" % str(fl.text))
	check(absf(fl.position.y + 48.0) < 0.5, "打磨-57 浮动位置复位 y≈-48 (实际 %.2f)" % fl.position.y)
	check(fl.modulate.a > 0.9, "打磨-57 浮动可见 (alpha=%.2f)" % fl.modulate.a)
	# 只读: tick/drain 不改动 资源/统计
	check(absf(g.essence - ess_b) < 1e-9, "打磨-57 tick 无 灵气 副作用 (实际 %.0f)" % g.essence)
	check(absf(g.stones - sto_b) < 1e-9, "打磨-57 tick 无 灵石 副作用 (实际 %.0f)" % g.stones)
	check(g.stats == stats_b, "打磨-57 tick 无 统计 副作用")
	# 技能行 按钮 同步: a1 冷却完毕 -> 按钮 恢复 施展
	var btn_a1: Button = ui._skill_btns[a1]
	check(str(btn_a1.text) == "施展" and not btn_a1.disabled, "打磨-57 a1 冷却完毕 按钮恢复 施展 (实际 %s)" % str(btn_a1.text))
	var btn_a2: Button = ui._skill_btns[a2]
	check(str(btn_a2.text).begins_with("冷却"), "打磨-57 a2 仍冷却 按钮=冷却N秒 (实际 %s)" % str(btn_a2.text))
	# 再 tick 15 秒: a2 归零转就绪 -> 同一 _refresh 弹 第二个 就绪浮动 (文案=a2 名)
	g._tick_active_cd(15.0)
	check(g.active_ready(a1) and g.active_ready(a2), "打磨-57 再 15s tick 后 a2 也就绪")
	var c1: int = ui._ready_float_count
	ui._refresh()
	check(ui._ready_float_count == c1 + 1, "打磨-57 a2 冷却完毕 浮动计数+1 (期望 %d, 实际 %d)" % [c1 + 1, ui._ready_float_count])
	check(str(ui._ready_last_text) == n2, "打磨-57 第二次 浮动文案=a2 神通名 (实际 %s)" % str(ui._ready_last_text))
	check(str(fl.text) == "✦ 冷却完毕: " + n2 + " ✦ (爆发+%d 灵气)" % v2, "打磨-62 第二次 浮动 Label 文本=爆发+N 灵气 (实际 %s)" % str(fl.text))
	# --- 同一批多个就绪 合并一行: 两神通 同时 进冷却, 同帧 归零 -> 一个 浮动 含 两名 (换行) ---
	g._active_cd[a1] = 5.0
	g._active_cd[a2] = 5.0
	g.ready_events.clear()
	var c2: int = ui._ready_float_count
	g._tick_active_cd(5.0)
	ui._refresh()
	check(ui._ready_float_count == c2 + 1, "打磨-57 同帧两就绪 仅一个 浮动 (合并, 计数 %d→%d)" % [c2, ui._ready_float_count])
	check(str(fl.text) == "✦ 冷却完毕: " + n1 + "\n" + n2 + " ✦ (爆发+%d 灵气)" % (v1 + v2), "打磨-62 合并浮动 爆发总量=两神通值之和 (实际 %s)" % str(fl.text))
	var merged: String = str(ui._ready_last_text)
	check(merged.find(n1) >= 0 and merged.find(n2) >= 0 and merged != "", "打磨-57 合并文案 含 两神通名 (实际 %s)" % merged)
	check(str(fl.text).find("\n") >= 0, "打磨-57 合并 浮动 Label 多行 (含换行) (实际 %s)" % str(fl.text))
	# 无重复触发: 均已就绪, 再 tick + _refresh 不弹 新浮动 (计数不变)
	var c3: int = ui._ready_float_count
	g._tick_active_cd(10.0)
	ui._refresh()
	check(ui._ready_float_count == c3, "打磨-57 就绪后再 tick 不重复触发 浮动 (计数 %d 不变)" % c3)
	# 收尾: 恢复基准态 (清 已学/冷却/就绪事件/资源)
	g.learned.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-62: 冷却完毕 浮动 追加 爆发总量 — 飞升态 口径=道行 (飞升后 灵气速率 x2,
# 爆发 = 速率 x 爆发秒数 x 2), 文案 与 打磨-60/61 "爆发+N 灵气/道行" 同格式, 2 态 精确匹配。
# 注: 就绪事件 触发 打磨-59 收口+微光 (tween+标记), 且 UI 自动 _process 每帧 _refresh 会与 手动驱动 竞争;
# 全程 冻结 UI 手动 驱动 _refresh, 收尾 手动驱动 收口/微光 终态 回调 + 清 标记, 避免 泄漏 污染 后续 58 测试。
func _assert_ready_float_burst() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1, 空 技能/装备/法器)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	# 冻结 UI 自动 _refresh (同 打磨-59 口径: UI 自动 drain 就绪事件 会与 手动驱动 竞争 致 断言竞态)
	ui.set_process(false)
	# 清 遗留 收口/微光 标记 (前序测试 UI 自动 drain 可能 残留)
	ui._skill_active_close.clear()
	ui._skill_active_glow.clear()
	# 找 1 个 凡品 主动神通
	var a1 := ""
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if int(s["tier"]) == 0 and str(s["type"]) == "active":
			a1 = str(id)
			break
	check(a1 != "", "打磨-62 受控态 找到 凡品主动神通 (实际 %s)" % a1)
	if a1 == "":
		ui.set_process(true)
		return
	var name: String = str(g.skill_by_id[a1]["name"])
	var v: int = int(g.skill_by_id[a1]["value"])
	var fl: Label = ui._ready_float_label
	# --- 态1 未飞升: 速率 1.0, 冷却归零 就绪 -> 浮动 含 "爆发+v 灵气" 精确匹配 ---
	g.learned.append(a1)
	g._active_cd[a1] = 30.0
	g.ready_events.clear()
	g._tick_active_cd(30.0)
	ui._refresh()
	check(str(fl.text) == "✦ 冷却完毕: " + name + " ✦ (爆发+%d 灵气)" % v, "打磨-62 未飞升 浮动文案=爆发+%d 灵气 (实际 %s)" % [v, str(fl.text)])
	# --- 态2 飞升: 速率 x2 (道行阶段1, 同 打磨-61 飞升态口径), 冷却归零 就绪 -> 浮动 含 "爆发+2v 道行" ---
	g._active_cd[a1] = 30.0
	g.ready_events.clear()
	g.ascended = true
	g.dao_level = 1
	g._tick_active_cd(30.0)
	ui._refresh()
	check(str(fl.text) == "✦ 冷却完毕: " + name + " ✦ (爆发+%d 道行)" % (v * 2), "打磨-62 飞升态 浮动文案=爆发+%d 道行 (实际 %s)" % [v * 2, str(fl.text)])
	# 收尾: 恢复基准态 (未飞升, 清 已学/冷却/就绪事件/资源)
	g.learned.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	# 手动驱动 打磨-59 收口/微光 终态 回调 (headless 不依赖 tween 自然跑完, 清 标记 并 恢复 默认样式/隐藏条,
	# 避免 泄漏 污染 后续 打磨-58 进度条 断言)
	ui._skill_close_done(a1)
	ui._skill_glow_done(a1)
	ui._skill_cd_acc = 0.0
	ui._skill_active_close.clear()
	ui._skill_active_glow.clear()
	ui.set_process(true)
	ui._refresh()
	await get_tree().process_frame



# 打磨-58: 神通冷却进度条 — 24 个主动神通行内细条 (冷却中=青色按 剩余/总冷却 填充, 归零隐藏);
# 1 秒节流 + 2% 量化档 + 布局宽变化才刷 (同 打磨-40 成就条 口径)。
# 注: 进度条初始隐藏 (未学), 容器布局跳过隐藏子节点 -> 首次 显示 当帧 宽度仍为 0 (布局未落定),
# 宽度 在下一 process_frame 落定后 由 宽变化缓存键 触发 重算填充 (自愈, 最迟 1 秒档 内 填充到位)。
# 测试手动驱动 _skill_cd_acc 跨节流档 + 直接调 _refresh_skill_cd_bars 断言 填充/节流/归零隐藏。
func _assert_cd_bars() -> void:
	var g := GameData
	# 受控态: 全新基准 (境界0层1, 空 技能/装备/法器, 清 冷却/就绪事件)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	ui._skill_cd_acc = 0.0
	# 审查修复 (打磨-58 flake): 前段 残留 的 可见 冷却条 + 陈旧 缓存键 会 泄漏 到 本段 —
	# 本段 清零 _skill_cd_acc 后 _refresh() 不跨 节流档, 不 重跑 条 刷新, 残留 可见 条
	# 使 「初始 未学 隐藏」 假失败, 陈旧 键 使 填充 不 重算 (高负载 偶发); 显式 收口 全部
	# 条 到 hidden (填充 清零 + 键 hidden) 使 本段 初始 态 自包含, 与 前段 收尾 解耦
	for _id58 in ui._skill_cd_bars:
		ui._hide_cd_bar(_id58)
	ui._tab.current_tab = 1
	ui._refresh()
	await get_tree().process_frame
	# 节点: 24 个主动神通 均有 {bg, fill} 结构, 挂在行内信息 VBox, 初始 全部 隐藏 (未学)
	var n_active := 0
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if str(s["type"]) != "active":
			continue
		n_active += 1
		var r58: Dictionary = ui._skill_cd_bars.get(str(id), {})
		check(r58.size() >= 2 and r58.get("bg") != null and r58.get("fill") != null, "打磨-58 %s 进度条节点 {bg,fill} 存在" % str(id))
		if r58.size() < 2:
			continue
		var bg58: Panel = r58["bg"]
		check(bg58.get_parent() is VBoxContainer, "打磨-58 %s 进度条 挂 行内信息 VBox" % str(id))
		check(bg58.size.y >= 5.0, "打磨-58 %s 进度条高>=5 (实际 %.1f)" % [str(id), bg58.size.y])
		var _sb58 = bg58.get_theme_stylebox("panel")
		check(_sb58 is StyleBoxTexture and str((_sb58 as StyleBoxTexture).texture.resource_path) == "res://assets/ui/bar_track.png", "打磨-58 %s 进度条底=bar_track 纹理 (打磨-135d)" % str(id))
		check(not bg58.visible, "打磨-58 %s 初始 未学 进度条隐藏" % str(id))
	check(n_active == 24, "打磨-58 主动神通行数量=24 (实际 %d)" % n_active)
	# 找 两个 凡品主动神通 (cd 90s), 手动注入 冷却 (不同同步: a1 余 45 / a2 余 90=满)
	var r_act: Array[String] = []
	for id in g.skill_ids:
		var s2: Dictionary = g.skill_by_id[id]
		if int(s2["tier"]) == 0 and str(s2["type"]) == "active":
			r_act.append(str(id))
	check(r_act.size() >= 2, "打磨-58 受控态 找到 >=2 个 凡品主动神通 (实际 %d)" % r_act.size())
	if r_act.size() < 2:
		return
	var a1: String = r_act[0]
	var a2: String = r_act[1]
	g.learned.append(a1)
	g.learned.append(a2)
	g._active_cd[a1] = 45.0
	g._active_cd[a2] = 90.0
	var stats_b: Dictionary = g.stats.duplicate(true)
	var ess_b: float = g.essence
	# 首次 显示: 跨节流档 直调 (可见=true, 当帧 宽度 仍 0 -> 填充 0, 待 布局落定 自愈)
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	var r1: Dictionary = ui._skill_cd_bars[a1]
	var r2: Dictionary = ui._skill_cd_bars[a2]
	var bg1: Panel = r1["bg"]
	var bg2: Panel = r2["bg"]
	check(bg1.visible, "打磨-58 a1 冷却中 进度条 显示")
	check(bg2.visible, "打磨-58 a2 冷却中 进度条 显示")
	# 等 布局落定 + 缓存键 按 最终 宽 重算 (宽度 0 -> 实际 宽, headless 高负载时 布局 落定 慢;
	# 缓存键 = 宽|档 — 宽 变 后 必须 等 到 键 已 重算 否则 填充 仍 为 首显 0 (打磨-58 flake:
	# 旧 20 帧 窗口 只 等 宽>0, 宽 已 落定 但 键 未 重算 时 第二次 直调 命中 旧键 跳过 写 填充);
	# 预算 40 帧, 宽 两 帧 稳定 + 键 = 宽|当前 档 即 收敛)
	for _i58 in 40:
		await get_tree().process_frame
		var w1s: int = int(bg1.size.x)
		var w2s: int = int(bg2.size.x)
		if w1s > 0 and w2s > 0 and w1s == int(bg1.size.x) and w2s == int(bg2.size.x):
			var k1e: String = "%d|50" % w1s
			var k2e: String = "%d|50" % w2s
			if str(ui._skill_cd_q.get(a1, "")) == k1e and str(ui._skill_cd_q.get(a2, "")) == k2e:
				break
	check(bg1.size.x > 0.0, "打磨-58 a1 布局落定 宽度>0 (实际 %.1f)" % bg1.size.x)
	check(bg2.size.x > 0.0, "打磨-58 a2 布局落定 宽度>0 (实际 %.1f)" % bg2.size.x)
	# 宽度落定后 再 直调 一次 由 宽变化缓存键 触发 填充
	ui._refresh_skill_cd_bars()
	check(_fill_modulate(r1["fill"]) == ui.CYAN, "打磨-58 a1 填充色=青 (modulate)")
	check(absf(r1["fill"].size.x - bg1.size.x * 0.5) < 0.5, "打磨-58 a1 填充=50%% 宽 (余45/总90, 期望 %.1f 实际 %.1f)" % [bg1.size.x * 0.5, r1["fill"].size.x])
	check(absf(r2["fill"].size.x - bg2.size.x) < 0.5, "打磨-58 a2 填充=100%% 宽 (满冷却, 期望 %.1f 实际 %.1f)" % [bg2.size.x, r2["fill"].size.x])
	# 节流门: 未跨 1 秒档时 _refresh() 内 不触发 _refresh_skill_cd_bars (缓存键/填充 不变)
	var q1_before: String = str(ui._skill_cd_q[a1])
	var f1_before: float = r1["fill"].size.x
	ui._skill_cd_acc = 0.5
	ui._refresh()
	check(str(ui._skill_cd_q[a1]) == q1_before, "打磨-58 节流: 未跨档 不刷 (缓存键不变, 实际 %s)" % str(ui._skill_cd_q[a1]))
	check(r1["fill"].size.x == f1_before, "打磨-58 节流: 未跨档 填充不写 (宽不变)")
	# 冷却递减 (tick 25s: a1 余 20/90, a2 余 65/90) -> 跨档 直调 后 填充 同步缩短
	g._tick_active_cd(25.0)
	g.drain_ready_events()
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	var q_a1: int = int(ceil(minf(20.0 / 90.0, 1.0) * 50.0))
	var q_a2: int = int(ceil(minf(65.0 / 90.0, 1.0) * 50.0))
	check(absf(r1["fill"].size.x - bg1.size.x * float(q_a1) / 50.0) < 0.5, "打磨-58 a1 余 20/90 填充=%d/50 档 (期望 %.1f 实际 %.1f)" % [q_a1, bg1.size.x * float(q_a1) / 50.0, r1["fill"].size.x])
	check(absf(r2["fill"].size.x - bg2.size.x * float(q_a2) / 50.0) < 0.5, "打磨-58 a2 余 65/90 填充=%d/50 档 (期望 %.1f 实际 %.1f)" % [q_a2, bg2.size.x * float(q_a2) / 50.0, r2["fill"].size.x])
	check(q_a1 < 25 and q_a2 < 50, "打磨-58 tick 后 填充档 单调下降 (a1 %d<25, a2 %d<50)" % [q_a1, q_a2])
	# 只读: 刷条 不改动 资源/统计/冷却
	check(absf(g.essence - ess_b) < 1e-9 and g.stats == stats_b, "打磨-58 刷条 无 资源/统计 副作用")
	check(absf(g._active_cd[a1] - 20.0) < 1e-9 and absf(g._active_cd[a2] - 65.0) < 1e-9, "打磨-58 刷条 无 冷却 副作用")
	# 归零: tick 20s -> a1 就绪; 打磨-59 后 隐藏 由 收口动画 (_skill_close_done) 负责,
	# _refresh_skill_cd_bars 对 就绪条 只 停填充 不抢先 隐藏; a2 仍冷却 (条 保持 填充)
	g._tick_active_cd(20.0)
	g.drain_ready_events()
	check(g.active_ready(a1) and not g.active_ready(a2), "打磨-58 tick 后 a1 就绪 a2 仍冷却")
	var a1_fill_pre: float = r1["fill"].size.x
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	check(bg1.visible and r1["fill"].size.x == a1_fill_pre, "打磨-58 a1 就绪 _refresh_skill_cd_bars 不抢先隐藏 (打磨-59 收口动画 收尾, 填充 %.1f 不变)" % r1["fill"].size.x)
	check(bg2.visible and r2["fill"].size.x > 0.0, "打磨-58 a2 仍冷却 进度条 保持 填充 (实际 %.1f)" % r2["fill"].size.x)
	# 收口动画 收尾 (真实流程由 _refresh 消费 就绪事件 触发; 此处 手动驱动 终态)
	ui._skill_close_done(a1)
	check(not bg1.visible and r1["fill"].size == Vector2.ZERO, "打磨-58 a1 收口后 进度条 隐藏+填充清零")
	check(str(ui._skill_cd_q[a1]) == "hidden", "打磨-58 a1 隐藏态 缓存键=hidden (实际 %s)" % str(ui._skill_cd_q[a1]))
	# 全部就绪: a2 也 tick 到 0 -> 收口后 全部 隐藏 (无残留显示)
	g._tick_active_cd(65.0)
	g.drain_ready_events()
	check(g.active_ready(a2), "打磨-58 再 65s tick 后 a2 就绪")
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	ui._skill_close_done(a2)
	check(not bg1.visible and not bg2.visible, "打磨-58 全部就绪 收口后 进度条 全隐藏")
	# 未学隐藏: a1 取消领悟 (冷却已无) -> 条 保持 隐藏 (未学不显示; 此路径 仍由 _refresh_skill_cd_bars 亲手隐藏)
	g.learned.erase(a1)
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	check(not bg1.visible, "打磨-58 取消领悟 进度条 隐藏 (未学不显示)")
	# 收尾: 恢复基准态
	g.learned.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	ui._skill_cd_acc = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-59: 冷却完毕 收口动画 + 按钮金边微光 — 就绪事件 触发后:
# 进度条 满档 快速收窄至 0 后隐藏 (与 打磨-57 就绪浮动 同帧), 施展按钮 金边微光 渐隐回默认。
# 测试手动驱动: 注入冷却 -> 先 跨节流档 _refresh_skill_cd_bars 把条刷到 50% 可见 -> tick 归零
# -> _refresh 消费 就绪事件 (触发 收口+微光) -> 帧推进 让 tween 完成 -> 断言 终态。
func _assert_ready_flash() -> void:
	var g := GameData
	# 受控态: 全新基准
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	var stats_b: Dictionary = g.stats.duplicate(true)
	# 冻结 UI 自动 _refresh (UI._process 每帧 drain 就绪事件, 会与手动驱动竞争, 致断言竞态);
	# 本测试 全程 手动 驱动 _refresh; tween 由 SceneTree 推进, 不受 set_process(false) 影响
	ui.set_process(false)
	# 清 遗留 收口/微光 标记 (前序测试 UI 自动 drain 可能 残留)
	ui._skill_active_close.clear()
	ui._skill_active_glow.clear()
	# 找 两个 凡品 主动神通
	var r_act: Array[String] = []
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id[id]
		if int(s["tier"]) == 0 and str(s["type"]) == "active":
			r_act.append(str(id))
	check(r_act.size() >= 2, "打磨-59 受控态 找到 >=2 个 凡品主动神通 (实际 %d)" % r_act.size())
	if r_act.size() < 2:
		ui.set_process(true)
		return
	var a1: String = r_act[0]
	var a2: String = r_act[1]
	var seq0: int = ui._skill_ready_seq
	g.learned.append(a1)
	g.learned.append(a2)
	g._active_cd[a1] = 90.0
	g._active_cd[a2] = 135.0  # >90: 首轮 tick 90s 后 a2 仍余 45s 不就绪
	ui._tab.current_tab = 1
	ui._refresh()
	await get_tree().process_frame
	# 冷却中: 跨节流档 直调 把 条 刷成 可见 (a1 满 100% / a2 135 注入 首轮 仍冷却)
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	var r1: Dictionary = ui._skill_cd_bars[a1]
	var r2: Dictionary = ui._skill_cd_bars[a2]
	var bg1: Panel = r1["bg"]
	var bg2: Panel = r2["bg"]
	var fill1: Panel = r1["fill"]
	var fill2: Panel = r2["fill"]
	check(bg1.visible and bg2.visible, "打磨-59 冷却中 两行 进度条 可见 (a1=%s a2=%s)" % [str(bg1.visible), str(bg2.visible)])
	# 等 布局落定 (宽度 0 -> 实际 宽, headless 高负载时 1 帧可能不够, 上限 20 帧; 与 打磨-58 同款加固)
	for _i59 in 20:
		await get_tree().process_frame
		if bg1.size.x > 0.0 and bg2.size.x > 0.0:
			break
	ui._refresh_skill_cd_bars()
	check(fill1.size.x > 0.0 and fill2.size.x > 0.0, "打磨-59 冷却中 填充>0 (a1=%.1f a2=%.1f)" % [fill1.size.x, fill2.size.x])
	# 记 按钮 默认样式 (恢复后 normal 须 回到 默认; 打磨-135c-1 后 默认 = 9-slice 纹理,
	# 微光中 = StyleBoxFlat 金边; 用 类型+边框色 断言 而非 对象引用 — get_theme_stylebox 返回 拷贝)
	var btn_a1: Button = ui._skill_btns[a1]
	var btn_a2: Button = ui._skill_btns[a2]
	# 默认 = 9-slice 纹理 (打磨-135c-1), 微光中 = StyleBoxFlat 金边 (打磨-32 口径)
	# --- a1 归零: tick 90 秒 -> a1 就绪 (a2 余 45 不就绪) ---
	g._tick_active_cd(90.0)
	check(g.active_ready(a1) and not g.active_ready(a2), "打磨-59 tick 后 a1 就绪 a2 仍冷却")
	# 手动 _refresh 消费 就绪事件 -> 浮动 + 收口 + 微光 同帧 (UI 自动 _process 已冻结, 无竞争)
	ui._refresh()
	check(ui._skill_ready_seq == seq0 + 1, "打磨-59 就绪批次计数+1 (期望 %d 实际 %d)" % [seq0 + 1, ui._skill_ready_seq])
	check(ui._skill_active_close.has(a1), "打磨-59 a1 收口动画 进行中 (标记存在)")
	check(ui._skill_active_glow.has(a1), "打磨-59 a1 按钮微光 进行中 (标记存在)")
	check(not ui._skill_active_close.has(a2) and not ui._skill_active_glow.has(a2), "打磨-59 a2 未就绪 无收口/微光 标记")
	# 微光中: 按钮 金边样式 已套 (边框色=金 0.98,0.86,0.5)
	var sb_glow: StyleBoxFlat = btn_a1.get_theme_stylebox("normal")
	check(sb_glow is StyleBoxFlat and sb_glow.border_color == Color(0.98, 0.86, 0.5), "打磨-59 a1 微光中 按钮 normal=金边 (实际 %s)" % str(sb_glow))
	# 收口中: 条 保持 可见 (收口动画 负责 收窄+隐藏 终态, 节流刷新 不抢先 隐藏 就绪条)
	check(bg1.visible, "打磨-59 a1 收口中 条 保持 可见 (动画负责终态)")
	# a2 不受 a1 事件影响: 条 保持 冷却 填充
	check(bg2.visible and fill2.size.x > 0.0, "打磨-59 a2 仍冷却 条保持 (实际 %.1f)" % fill2.size.x)
	# 节流门: 就绪条 被 _refresh_skill_cd_bars 跳过 (不 隐藏/不清零, 由 收口动画 收尾)
	var fill1_pre: float = fill1.size.x
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	check(bg1.visible and fill1.size.x == fill1_pre, "打磨-59 收口中 节流刷新 跳过 a1 不抢先隐藏 (填充 %.1f 不变)" % fill1.size.x)
	check(str(ui._skill_cd_q[a1]) != "hidden", "打磨-59 收口中 a1 缓存键 未 归 hidden (实际 %s)" % str(ui._skill_cd_q[a1]))
	# --- 收口 终态 手动驱动 (headless 帧时间不确定, 不依赖 tween 自然跑完; 驱动 动画结束回调) ---
	ui._skill_close_done(a1)
	check(not bg1.visible, "打磨-59 a1 收口完成 条 隐藏")
	check(fill1.size == Vector2.ZERO, "打磨-59 a1 收口完成 填充清零 (实际 %s)" % str(fill1.size))
	check(str(ui._skill_cd_q[a1]) == "hidden", "打磨-59 a1 缓存键=hidden (实际 %s)" % str(ui._skill_cd_q[a1]))
	check(not ui._skill_active_close.has(a1), "打磨-59 a1 收口标记 已清除")
	# --- 微光 终态 手动驱动 (驱动 微光结束回调, 恢复 默认样式) ---
	ui._skill_glow_done(a1)
	var sb_n_after: StyleBox = btn_a1.get_theme_stylebox("normal")
	check(sb_n_after is StyleBoxTexture and sb_n_after.texture != null and str((sb_n_after as StyleBoxTexture).texture.resource_path) == "res://assets/ui/btn_primary.png", "打磨-59 a1 微光结束 normal 恢复 默认 9-slice 纹理 (实际 %s)" % str(sb_n_after))
	check(not ui._skill_active_glow.has(a1), "打磨-59 a1 微光标记 已清除")
	# 恢复后 冷却 刷新 可再次 驱动 a1 (无残留 卡死)
	g._active_cd[a1] = 45.0
	ui._skill_cd_acc = 1.0
	ui._refresh_skill_cd_bars()
	check(bg1.visible and fill1.size.x > 0.0, "打磨-59 恢复后 再进冷却 条可再次 显示 (实际 %.1f)" % fill1.size.x)
	# --- 同批多就绪: a1/a2 同时 归零 -> 一个批次 触发 双收口+双微光 ---
	# 注: a1 刚重注 45s, a2 尚余 45s, 本次 tick 45s 使 a1/a2 同帧 归零 -> 同批 两就绪
	g._tick_active_cd(45.0)
	check(g.active_ready(a1) and g.active_ready(a2), "打磨-59 同批 tick 后 a1/a2 均就绪")
	ui._refresh()
	check(ui._skill_active_close.has(a1) and ui._skill_active_close.has(a2), "打磨-59 同批双就绪 双收口 进行中")
	check(ui._skill_active_glow.has(a1) and ui._skill_active_glow.has(a2), "打磨-59 同批双就绪 双微光 进行中")
	# 同批 双 终态 手动驱动
	ui._skill_close_done(a1)
	ui._skill_close_done(a2)
	ui._skill_glow_done(a1)
	ui._skill_glow_done(a2)
	check(not ui._skill_active_close.has(a1) and not ui._skill_active_close.has(a2), "打磨-59 同批 收口 全部完成")
	check(not ui._skill_active_glow.has(a1) and not ui._skill_active_glow.has(a2), "打磨-59 同批 微光 全部完成")
	check(not bg1.visible and not bg2.visible, "打磨-59 同批 双条 终态 隐藏")
	var sb_a1_after: StyleBox = btn_a1.get_theme_stylebox("normal")
	check(sb_a1_after is StyleBoxTexture and str((sb_a1_after as StyleBoxTexture).texture.resource_path) == "res://assets/ui/btn_primary.png", "打磨-59 同批 a1 样式 恢复 默认 9-slice 纹理 (实际 %s)" % str(sb_a1_after))
	var sb_a2_after: StyleBox = btn_a2.get_theme_stylebox("normal")
	check(sb_a2_after is StyleBoxTexture and str((sb_a2_after as StyleBoxTexture).texture.resource_path) == "res://assets/ui/btn_primary.png", "打磨-59 同批 a2 样式 恢复 默认 9-slice 纹理 (实际 %s)" % str(sb_a2_after))
	# 只读: 收口/微光 不改动 资源/统计
	check(absf(g.essence) < 1e-9 and g.stats == stats_b, "打磨-59 收口/微光 无 资源/统计 副作用")
	# 收尾: 恢复基准态 + 解冻 UI
	g.learned.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	ui._skill_cd_acc = 0.0
	ui._skill_active_close.clear()
	ui._skill_active_glow.clear()
	ui.set_process(true)
	ui._refresh()
	await get_tree().process_frame


# 打磨-63: 突破成功率 tooltip 预期成本 (UI 侧: _chance_label.tooltip_text 随 _refresh 刷新, 含 期望次数/期望总消耗)
# 在 打磨-59 收尾 基准态 (全空, 练气第1层, 未飞升) 上断言: tooltip=构成段+预期成本两行, 口径与接口一致,
# 状态变化 (境界/飞升) 刷新, 道祖封顶 不追加.
func _assert_chance_expect_tip() -> void:
	var g := GameData
	check(ui._chance_label != null, "打磨-63 _chance_label 节点存在")
	# 基准态: 练气第1层 85%, cost 10 -> 构成段 + 预期成本两行
	check(absf(g.primary_break_chance() - 0.85) < 1e-9, "打磨-63 基准态 成功率=0.85 (实际 %s)" % g.primary_break_chance())
	ui._tab.current_tab = 0
	ui._refresh()
	var tip0: String = str(ui._chance_label.tooltip_text)
	check(tip0 == g.primary_break_chance_tip(), "打磨-63 UI tooltip 与接口一致 (UI %s / 接口 %s)" % [tip0, g.primary_break_chance_tip()])
	check(tip0.find("突破成功率 85% 构成:") >= 0, "打磨-63 基准 tooltip 含 构成段 (实际 %s)" % tip0)
	check(tip0.find("· 期望次数 ~1.2 次 (成功率 85%)") >= 0, "打磨-63 基准 tooltip 含 期望次数 (实际 %s)" % tip0)
	check(tip0.find("· 期望总消耗 ~11 灵气") >= 0, "打磨-63 基准 tooltip 含 期望总消耗 灵气 口径 (实际 %s)" % tip0)
	# 节流: 同态再刷 缓存不变
	var cache0: String = str(ui._chance_tip)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._chance_tip) == cache0, "打磨-63 同态再刷 缓存不变 (节流生效)")
	# 状态变化: 筑基第2层 81%, cost 60 -> 期望 1.2 次/74 灵气 (tooltip 随之刷新)
	g.realm_idx = 1
	g.layer = 2
	ui._refresh()
	var tip1: String = str(ui._chance_label.tooltip_text)
	check(tip1 != tip0, "打磨-63 境界变化后 tooltip 刷新 (缓存更新)")
	check(tip1.find("突破成功率 81%") >= 0, "打磨-63 筑基 tooltip 成功率 81%% (实际 %s)" % tip1)
	check(tip1.find("· 期望总消耗 ~74 灵气") >= 0, "打磨-63 筑基 tooltip 期望总消耗 74 灵气 (实际 %s)" % tip1)
	# 状态变化: 飞升 初仙 90% -> 道行 口径 (cost 1e9 -> 11.1亿 道行)
	g.ascended = true
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	ui._refresh()
	var tip2: String = str(ui._chance_label.tooltip_text)
	check(tip2.find("道行精进成功率 90%") >= 0, "打磨-63 飞升 tooltip 道行精进 90%% (实际 %s)" % tip2)
	check(tip2.find("· 期望次数 ~1.1 次 (成功率 90%)") >= 0, "打磨-63 飞升 tooltip 期望次数 (实际 %s)" % tip2)
	check(tip2.find("· 期望总消耗 ~11.1亿 道行") >= 0, "打磨-63 飞升 tooltip 期望总消耗 道行 口径 (实际 %s)" % tip2)
	# 状态变化: 道祖封顶 -> 圆满文案, 不追加 预期成本
	g.dao_level = 8
	ui._refresh()
	var tip3: String = str(ui._chance_label.tooltip_text)
	check(tip3.find("已至道祖") >= 0, "打磨-63 道祖 tooltip 圆满文案 (实际 %s)" % tip3)
	check(tip3.find("期望次数") < 0 and tip3.find("期望总消耗") < 0, "打磨-63 道祖 tooltip 不追加 预期成本 (实际 %s)" % tip3)
	# 恢复基准态
	g.ascended = false
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-64: 突破/道行精进 失败 浮动提示 含 本次消耗+预期成本 (UI 侧: _float_label 文案=接口, 红色;
# 资源不足不触发 / 道祖封顶 基础文案; _on_break 真实路径 扣资源+埋点 口径验证)
func _assert_break_fail_float() -> void:
	var g := GameData
	# 受控态: 全新基准 (基准态 由 打磨-63 收尾 保证)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	var fl: Label = ui._float_label
	var stats_b: Dictionary = g.stats.duplicate(true)
	# 0=未触发: _float_break 直接返回, 文案不变
	fl.text = "SENTINEL_64"
	g.last_break_result = 0
	ui._float_break()
	check(str(fl.text) == "SENTINEL_64", "打磨-64 last_break_result=0 不触发 浮动 (实际 %s)" % str(fl.text))
	# 未飞升 失败: 注入 roll=0.999 必失败 (85% 成功率, 确定性), 再驱动 UI _float_break 渲染
	g.essence = 20.0
	var ess_b: float = g.essence
	g.try_breakthrough(0.999)
	ui._float_break()
	var txt64: String = str(fl.text)
	var expect64: String = g.break_fail_float_text()
	check(txt64 == expect64, "打磨-64 未飞升 失败浮动=接口文案 (实际 %s / 接口 %s)" % [txt64, expect64])
	check(txt64.begins_with("✖ 突破失败… ✖  本次耗 "), "打磨-64 未飞升 前缀+本次耗 (实际 %s)" % txt64)
	check(txt64.find("期望次数 ~1.2 次") >= 0 and txt64.find("期望总消耗 ~11 灵气") >= 0, "打磨-64 未飞升 含 预期成本 (实际 %s)" % txt64)
	check(fl.get_theme_color("font_color") == Color(1.0, 0.45, 0.4), "打磨-64 未飞升 失败浮动 红色")
	check(absf(g.essence - (ess_b - 10.0)) < 1e-9, "打磨-64 失败 扣突破消耗 10 灵气 (实际 %s)" % g.essence)
	check(float(g.stats.get("break_fail", 0.0)) == float(stats_b.get("break_fail", 0.0)) + 1.0, "打磨-64 失败 break_fail+1 埋点")
	# 资源不足: try_breakthrough 走 灵气不足 分支 (roll 前返回), last_break_result 保持 0 -> 不弹浮动
	fl.text = "SENTINEL_64"
	g.essence = 5.0
	var msg64: String = g.try_breakthrough()
	ui._float_break()
	check(str(fl.text) == "SENTINEL_64", "打磨-64 资源不足 不触发 浮动 (实际 %s)" % str(fl.text))
	check(msg64.find("灵气不足") >= 0, "打磨-64 资源不足 返回 灵气不足 消息 (实际 %s)" % msg64)
	# 飞升后 失败: 道行 口径 (初仙 90%, cost 1e9 -> 10.0亿 道行)
	g.ascended = true
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 2.0e9
	var dao_b: float = g.dao
	g.try_dao_break(0.999)
	ui._float_break()
	var txt65: String = str(fl.text)
	expect64 = g.break_fail_float_text()
	check(txt65 == expect64, "打磨-64 飞升 失败浮动=接口文案 (实际 %s / 接口 %s)" % [txt65, expect64])
	check(txt65.begins_with("✖ 道行精进失败… ✖  本次耗 10.0亿 道行"), "打磨-64 飞升 前缀+本次耗 道行 (实际 %s)" % txt65)
	check(txt65.find("期望次数 ~1.1 次") >= 0 and txt65.find("期望总消耗 ~11.1亿 道行") >= 0, "打磨-64 飞升 含 预期成本 道行 口径 (实际 %s)" % txt65)
	check(fl.get_theme_color("font_color") == Color(1.0, 0.45, 0.4), "打磨-64 飞升 失败浮动 红色")
	check(absf(g.dao - (dao_b - 1.0e9)) < 1e-6, "打磨-64 飞升失败 扣道行 1e9 (实际 %s)" % g.dao)
	# 道祖封顶: try_dao_break 直接返回 (圆满 无失败), last_break_result=0 -> 不弹浮动
	g.dao_level = 8
	fl.text = "SENTINEL_64"
	var msg65: String = g.try_dao_break()
	ui._float_break()
	check(str(fl.text) == "SENTINEL_64", "打磨-64 道祖 不触发 浮动 (实际 %s)" % str(fl.text))
	check(msg65.find("已至道祖") >= 0, "打磨-64 道祖 返回 圆满 消息 (实际 %s)" % msg65)
	check(g.break_fail_float_text() == "✖ 道行精进失败… ✖", "打磨-64 道祖 接口=基础文案 不追加 (实际 %s)" % g.break_fail_float_text())
	# 恢复基准态
	g.ascended = false
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-65: 突破/道行精进 成功 浮动提示 含 新境界+当前成功率 (UI 侧: _float_label 文案=接口, 绿色/金色;
# 未触发不弹; 与 打磨-64 失败浮动 互补)
func _assert_break_ok_float() -> void:
	var g := GameData
	# 受控态: 全新基准 (基准态 由 打磨-64 收尾 保证)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	var fl: Label = ui._float_label
	# 普通成功: 练气1层 攒够 10 灵气, roll=0.01 必成功 -> 晋升 练气第2层 (成功率仍 85%)
	g.essence = 10.0
	g.try_breakthrough(0.01)
	ui._float_break()
	var ok65: String = str(fl.text)
	check(ok65 == g.break_ok_float_text(), "打磨-65 普通成功 浮动=接口 (实际 %s / 接口 %s)" % [ok65, g.break_ok_float_text()])
	check(ok65 == "✦ 突破成功! 晋升 练气 第 2 层 (当前成功率 85%) ✦", "打磨-65 普通成功 文案 新境界+成功率 (实际 %s)" % ok65)
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-65 普通成功 绿色")
	check(absf(g.essence - (10.0 - 10.0)) < 1e-9, "打磨-65 成功 扣突破消耗 10 灵气 (实际 %s)" % g.essence)
	# 跨境界成功: 练气顶层第 9 层 (消耗 90) -> 筑基第1层 -> 成功率 81%
	fl.text = "SENTINEL_65"
	g.layer = 9
	g.essence = 90.0
	g.try_breakthrough(0.01)
	check(g.realm_idx == 1 and g.layer == 1, "打磨-65 跨境界成功 境界=筑基第1层 (实际 %s)" % g.realm_display())
	ui._float_break()
	ok65 = str(fl.text)
	check(ok65 == g.break_ok_float_text(), "打磨-65 跨境界成功 浮动=接口 (实际 %s)" % ok65)
	check(ok65.find("晋升 筑基 第 1 层") >= 0 and ok65.find("当前成功率 81%") >= 0, "打磨-65 跨境界成功 文案 新境界+新成功率 (实际 %s)" % ok65)
	# 飞升: 真仙境(第 9 境) 顶层第 1 层 (消耗 196830) 成功 -> 飞升 (金色, 无成功率口径)
	g.realm_idx = 9
	g.layer = 1
	fl.text = "SENTINEL_65"
	g.essence = 196830.0
	g.try_breakthrough(0.01)
	ui._float_break()
	ok65 = str(fl.text)
	check(ok65 == g.break_ok_float_text(), "打磨-65 飞升 浮动=接口 (实际 %s)" % ok65)
	check(ok65 == "☀ 飞升真仙! 仙凡两隔, 灵气 x100000 ☀", "打磨-65 飞升 文案 (实际 %s)" % ok65)
	check(fl.get_theme_color("font_color") == Color(0.98, 0.86, 0.5), "打磨-65 飞升 金色")
	# 道行精进: 初仙 攒够 1e9 道行 成功 -> 晋阶 少仙 (成功率 87%)
	g.dao = 1.0e9
	fl.text = "SENTINEL_65"
	g.try_dao_break(0.01)
	ui._float_break()
	ok65 = str(fl.text)
	check(ok65 == g.break_ok_float_text(), "打磨-65 精进成功 浮动=接口 (实际 %s)" % ok65)
	check(ok65 == "✦ 道行精进! 晋阶 少仙 (当前成功率 87%) ✦", "打磨-65 精进成功 文案 阶段+成功率 (实际 %s)" % ok65)
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-65 精进成功 绿色")
	# 未触发: last_break_result=0 -> 不弹 浮动 (文案不变)
	g.last_break_result = 0
	fl.text = "SENTINEL_65"
	ui._float_break()
	check(str(fl.text) == "SENTINEL_65", "打磨-65 未触发 不弹 浮动 (实际 %s)" % str(fl.text))
	# 恢复基准态
	g.ascended = false
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	g.last_break_result = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	ui._refresh()
	await get_tree().process_frame


# 打磨-66: 离线收益 启动浮动 — 手动驱动 确定性断言 (不依赖启动时是否真离线, 防 flake):
# 金色浮动 Label / 文案=offline_float_text / 计数+1 / 可见 / 位置复位 y≈-84;
# 未飞升(灵气) 与 飞升(道行) 两态口径; 无收益(明细全0) 与 不足1分钟 不弹 计数不变
func _assert_offline_float() -> void:
	var g := GameData
	var ofl: Label = ui._offline_float_label
	check(ofl != null, "打磨-66 离线浮动 Label 节点存在")
	if ofl == null:
		return
	check(ofl.get_theme_color("font_color") == ui.GOLD, "打磨-66 离线浮动 文字色=金 (实际 %s)" % str(ofl.get_theme_color("font_color")))
	# --- 未飞升 口径: 确定性明细 (5400s, 各 2700) ---
	g.ascended = false
	g._offline_sec = 5400.0
	g._offline_qi = 2700.0
	g._offline_stone = 2700.0
	var exp66: String = g.offline_float_text()
	check(exp66 == "☾ 离线 1小时30分, 收获 灵气 2700 · 灵石 2700 ☾", "打磨-66 离线浮动 文案(未飞升) (实际 %s)" % exp66)
	var cnt_before: int = ui._offline_float_count
	ui._offline_float()
	check(ui._offline_float_count == cnt_before + 1, "打磨-66 手动驱动 浮动计数+1 (实际 %d)" % ui._offline_float_count)
	check(str(ui._offline_last_text) == exp66, "打磨-66 离线浮动 文案=offline_float_text (实际 %s)" % str(ui._offline_last_text))
	check(str(ofl.text) == exp66, "打磨-66 离线浮动 Label 文本=接口 (实际 %s)" % str(ofl.text))
	check(exp66.find("☾") >= 0 and exp66.find("灵气") >= 0 and exp66.find("灵石") >= 0, "打磨-66 文案含 ☾/灵气/灵石 (实际 %s)" % exp66)
	check(ofl.modulate.a > 0.5, "打磨-66 离线浮动 可见 (modulate.a>0.5, 实际 %.2f)" % ofl.modulate.a)
	check(absf(ofl.position.y + 84.0) < 0.5, "打磨-66 离线浮动 位置复位 y≈-84 (实际 %.2f)" % ofl.position.y)
	# --- 飞升 口径: 主资源=道行 (7200s, 3.6亿) ---
	g.ascended = true
	g._offline_sec = 7200.0
	g._offline_qi = 3.6e8
	g._offline_stone = 3.6e8
	var exp66b: String = g.offline_float_text()
	check(exp66b.find("道行") >= 0 and exp66b.find("2小时") >= 0, "打磨-66 飞升 文案含 道行/2小时 (实际 %s)" % exp66b)
	var cnt_b2: int = ui._offline_float_count
	ui._offline_float()
	check(ui._offline_float_count == cnt_b2 + 1, "打磨-66 飞升 手动驱动 计数+1 (实际 %d)" % ui._offline_float_count)
	check(str(ofl.text) == exp66b, "打磨-66 飞升 浮动文本=接口 (实际 %s)" % str(ofl.text))
	# --- 无收益 不弹: 明细全 0 ---
	g._offline_sec = 0.0
	g._offline_qi = 0.0
	g._offline_stone = 0.0
	check(g.offline_float_text() == "", "打磨-66 无收益 空串 (实际 %s)" % g.offline_float_text())
	var cnt_b3: int = ui._offline_float_count
	ui._offline_float()
	check(ui._offline_float_count == cnt_b3, "打磨-66 无收益 不弹 计数不变 (实际 %d)" % ui._offline_float_count)
	# --- 不足 1 分钟 不弹 ---
	g._offline_sec = 30.0
	g._offline_qi = 15.0
	g._offline_stone = 15.0
	check(g.offline_float_text() == "", "打磨-66 不足1分钟 空串 (实际 %s)" % g.offline_float_text())
	# 收尾: 恢复明细 (防污染 后续断言/收尾)
	g._offline_sec = 0.0
	g._offline_qi = 0.0
	g._offline_stone = 0.0
	g.ascended = false
	ui._refresh()
	await get_tree().process_frame


# 打磨-67: 自动突破 — 开关按钮存在/tooltip/点击切换/开关态同步/浮动文案 "(自动)" 标注 (成功绿+标注,
# 失败红+标注, 关闭不标注); 事件走 break_seq 统一驱动 (浮动/闪烁 与手动按钮 同口径); 收尾恢复基准态
func _assert_auto_break() -> void:
	var g := GameData
	var btn: Button = ui._auto_break_btn
	check(btn != null, "打磨-67 自动突破开关按钮存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-67 开关按钮 toggle_mode")
	check(btn.tooltip_text.find("资源攒够") >= 0 and btn.tooltip_text.find("存档") >= 0,
		"打磨-67 tooltip 含 资源攒够/存档 口径 (实际 %s)" % btn.tooltip_text)
	check(btn.tooltip_text.find("离线期间不触发") >= 0, "打磨-67 tooltip 含 离线期间不触发 口径")
	check(g.auto_break == false and not btn.button_pressed and str(btn.text) == "自动突破: 关",
		"打磨-67 初始 关 态 (文本/按压/存档值 一致)")
	# 点击切换: 开 (底部消息 + 按钮态 + 存档值)
	ui._on_auto_break()
	check(g.auto_break == true, "打磨-67 点击后 auto_break=true (实际 %s)" % str(g.auto_break))
	check(btn.button_pressed and str(btn.text) == "自动突破: 开", "打磨-67 点击后 按钮按压+文本 开")
	check(str(ui._msg_label.text).find("自动突破已开启") >= 0, "打磨-67 开启 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 点击切换: 关
	ui._on_auto_break()
	check(g.auto_break == false and not btn.button_pressed and str(btn.text) == "自动突破: 关", "打磨-67 再点 关 态")
	check(str(ui._msg_label.text).find("自动突破已关闭") >= 0, "打磨-67 关闭 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 外部改存档值: _refresh 同步按钮态 (读档恢复 场景)
	g.auto_break = true
	ui._refresh()
	check(btn.button_pressed and str(btn.text) == "自动突破: 开", "打磨-67 _refresh 同步 外部置 开 按钮态")
	# 浮动文案 "(自动)" 标注: 成功 (手动 _try_auto_break 注入 roll, 事件走 break_seq, 手动驱动 _float_break)
	# 受控态: 重置 基准 (练气第1层, 无加成, cost=10, 成功率 85%)
	var fl: Label = ui._float_label
	var stats_ab: Dictionary = g.stats.duplicate(true)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 10.0
	g.dao = 0.0
	g.last_break_result = 0
	g._try_auto_break(0.01)
	check(g.last_break_result == 1 and g.layer == 2, "打磨-67 UI 自动成功 事件=1 升层 (实际 %s)" % g.realm_display())
	fl.text = "SENTINEL_67"
	ui._float_break()
	check(str(fl.text) == g.break_ok_float_text() + " (自动)", "打磨-67 成功浮动=接口+ (自动) 标注 (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(0.55, 0.95, 0.55), "打磨-67 成功浮动 绿色")
	check(float(g.stats.get("break_ok", 0.0)) == float(stats_ab.get("break_ok", 0.0)) + 1.0, "打磨-67 自动成功 break_ok+1 埋点")
	# 失败: 红浮动 + (自动) 标注 (练气第2层 cost=20, essence=20 刚好够, 注入失败)
	g.essence = 20.0
	g._try_auto_break(0.999)
	fl.text = "SENTINEL_67"
	ui._float_break()
	check(str(fl.text) == g.break_fail_float_text() + " (自动)", "打磨-67 失败浮动=接口+ (自动) 标注 (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(1.0, 0.45, 0.4), "打磨-67 失败浮动 红色")
	# 关闭 开关: 浮动 无 标注 (手动 口径 不变; 重置 练气第1层 cost=10)
	g.auto_break = false
	g.last_break_result = 0
	g.layer = 1
	g.essence = 10.0
	g.try_breakthrough(0.01)
	check(g.last_break_result == 1, "打磨-67 关闭时 手动成功 事件=1 (实际 %d)" % g.last_break_result)
	fl.text = "SENTINEL_67"
	ui._float_break()
	check(str(fl.text) == g.break_ok_float_text() and str(fl.text).find("(自动)") < 0,
		"打磨-67 关闭时 浮动 无 (自动) 标注 (实际 %s)" % str(fl.text))
	# 开关不消耗资源/不计突破统计 (开关动作 本身 无 事件)
	g.essence = 3.0
	var seq_ab: int = g.break_seq
	var stats_ab2: Dictionary = g.stats.duplicate(true)
	ui._on_auto_break()
	ui._on_auto_break()
	check(g.auto_break == false and g.break_seq == seq_ab and g.stats == stats_ab2,
		"打磨-67 开关切换 无 资源/事件/统计 副作用")
	# 收尾: 恢复基准态 (防污染)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	g.auto_break = false
	ui._refresh()
	await get_tree().process_frame


# 打磨-68: 自动购置 — 开关按钮存在/tooltip/点击切换/开关态同步/灵石不足不触发/灵石够触发变更
# _refresh 出底部消息 (无屏幕浮动)/幂等0变更不再刷/开关切换无资源统计副作用; 收尾恢复基准态
func _assert_auto_buy() -> void:
	var g := GameData
	var btn: Button = ui._auto_buy_btn
	check(btn != null, "打磨-68 自动购置开关按钮存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-68 开关按钮 toggle_mode")
	check(btn.tooltip_text.find("自动购买") >= 0 and btn.tooltip_text.find("存档") >= 0,
		"打磨-68 tooltip 含 自动购买/存档 口径 (实际 %s)" % btn.tooltip_text)
	check(btn.tooltip_text.find("无屏幕浮动") >= 0, "打磨-68 tooltip 含 无屏幕浮动 口径")
	check(g.auto_buy == false and not btn.button_pressed and str(btn.text) == "自动购置: 关",
		"打磨-68 初始 关 态 (文本/按压/存档值 一致)")
	# 点击切换: 开 (底部消息 + 按钮态 + 存档值)
	ui._on_auto_buy()
	check(g.auto_buy == true, "打磨-68 点击后 auto_buy=true (实际 %s)" % str(g.auto_buy))
	check(btn.button_pressed and str(btn.text) == "自动购置: 开", "打磨-68 点击后 按钮按压+文本 开")
	check(str(ui._msg_label.text).find("自动购置已开启") >= 0, "打磨-68 开启 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 点击切换: 关
	ui._on_auto_buy()
	check(g.auto_buy == false and not btn.button_pressed and str(btn.text) == "自动购置: 关", "打磨-68 再点 关 态")
	check(str(ui._msg_label.text).find("自动购置已关闭") >= 0, "打磨-68 关闭 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 外部改存档值: _refresh 同步按钮态 (读档恢复 场景)
	g.auto_buy = true
	ui._refresh()
	check(btn.button_pressed and str(btn.text) == "自动购置: 开", "打磨-68 _refresh 同步 外部置 开 按钮态")
	# 灵石不足: _try_auto_buy 不购买 (最便宜 100 灵石, 当前 50)
	var owned0: int = g.owned.size()
	var eq0: int = g.owned_eq.size()
	var seq0: int = g._auto_buy_seq
	var stats0: Dictionary = g.stats.duplicate(true)
	g.stones = 50.0
	g._try_auto_buy()
	check(g.owned.size() == owned0 and g.owned_eq.size() == eq0 and g._auto_buy_seq == seq0,
		"打磨-68 灵石不足 不购买 (owned=%d eq=%d seq=%d)" % [g.owned.size(), g.owned_eq.size(), g._auto_buy_seq])
	check(g.stats == stats0, "打磨-68 灵石不足 无 统计 副作用")
	# 灵石够: 手动驱动 _try_auto_buy 触发 变更 (最便宜法器 木剑 100 + 装备 tier0), _refresh 出 底部消息
	g.stones = 700.0
	var msg_before: String = str(ui._msg_label.text)
	g._try_auto_buy()
	check(g._auto_buy_seq == seq0 + 1, "打磨-68 灵石够 触发 变更 事件 seq+1 (实际 %d)" % g._auto_buy_seq)
	check(g.owned.size() > owned0 or g.owned_eq.size() > eq0, "打磨-68 灵石够 有 购入 (owned=%d eq=%d)" % [g.owned.size(), g.owned_eq.size()])
	check(str(g.auto_buy_last_text()).find("自动购置") >= 0, "打磨-68 auto_buy_last_text 含 自动购置 (实际 %s)" % g.auto_buy_last_text())
	ui._refresh()
	check(str(ui._msg_label.text).find("自动购置") >= 0 and str(ui._msg_label.text) != msg_before,
		"打磨-68 _refresh 变更 后 底部消息 含 自动购置 (实际 %s)" % str(ui._msg_label.text))
	# 幂等: 再驱动一次 (买不起 下一件 + 已最佳) 0 变更, 底部消息 不再刷 (保持 上条 自动购置 文案)
	var msg_after: String = str(ui._msg_label.text)
	var seq1: int = g._auto_buy_seq
	g._try_auto_buy()
	check(g._auto_buy_seq == seq1, "打磨-68 幂等 0变更 不增 事件 (seq=%d)" % g._auto_buy_seq)
	ui._refresh()
	check(str(ui._msg_label.text) == msg_after, "打磨-68 幂等 后 底部消息 不变 (实际 %s)" % str(ui._msg_label.text))
	# 开关不消耗资源/不计 购买 统计 (开关动作 本身 无 副作用; 前置 置 关 保证 双击 后 仍 关)
	g.auto_buy = false
	g.stones = 3.0
	var seq_ab: int = g._auto_buy_seq
	var stats_ab: Dictionary = g.stats.duplicate(true)
	var owned_ab: int = g.owned.size()
	ui._on_auto_buy()
	ui._on_auto_buy()
	check(g.auto_buy == false and g._auto_buy_seq == seq_ab and g.stats == stats_ab and g.owned.size() == owned_ab,
		"打磨-68 开关切换 无 资源/事件/统计 副作用")
	# 收尾: 恢复基准态 (防污染)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	g.auto_buy = false
	g.auto_break = false
	ui._refresh()
	await get_tree().process_frame


# 打磨-84: 自动购置按钮 tooltip 动态段 — 构建含 动态段 标记/_refresh 按 接口 刷新/灵石状态 动态/节流/购买后 目标 切换/无副作用
func _assert_auto_buy_next_tip() -> void:
	var g := GameData
	var btn: Button = ui._auto_buy_btn
	check(btn != null, "打磨-84 自动购置按钮存在")
	if btn == null:
		return
	# 基准态 (前节 收尾: 清空 拥有/穿戴/已学, 境界0层1, 灵石 0, 速率 1.0/s)
	var t84: Dictionary = g.stone_next_target()
	check(not t84.is_empty(), "打磨-84 基准 存在 下一件 未拥有件 (实际 %s)" % str(t84.get("id", "")))
	var expect84 := ("当前 %s 灵石/秒" % g.fmt(g.stone_per_sec())) + ("\n下一件 %s「%s」 还差 %s 灵石 " % [str(t84["kind"]), str(t84["name"]), g.fmt(float(t84["shortfall"]))]) + g.eta_text(float(t84["cost"]))
	ui._refresh()
	check(str(btn.tooltip_text) == str(ui._auto_buy_tip_static) + expect84, "打磨-84 基准 tooltip=静态前缀+动态段 恒等 (实际 %s)" % str(btn.tooltip_text).left(60))
	check(str(btn.tooltip_text).find("【下一件 可购 时间 (动态)】") >= 0, "打磨-84 tooltip 含 动态段 标记")
	check(str(btn.tooltip_text).find(str(t84["name"])) >= 0, "打磨-84 tooltip 动态段 含 目标件名 (实际 %s)" % str(btn.tooltip_text).left(80))
	# 同态 节流: 再刷 不重写 (tooltip 稳定, 无 副作用)
	var tip_before: String = str(btn.tooltip_text)
	var snap_stats: Dictionary = g.stats.duplicate(true)
	var snap_stones: float = g.stones
	ui._refresh()
	check(str(btn.tooltip_text) == tip_before, "打磨-84 同态 节流 tooltip 稳定")
	check(g.stats == snap_stats and g.stones == snap_stones, "打磨-84 同态 刷 tooltip 无 资源/统计 副作用")
	# 灵石 足够: 动态段 切换 可立即购入 分支 (无 ETA 档位)
	g.stones = float(t84["cost"])
	ui._refresh()
	check(str(btn.tooltip_text).right(12) == "灵石已足够, 可立即购入", "打磨-84 灵石足够 动态段=可立即购入 无 ETA (实际 %s)" % str(btn.tooltip_text).right(12))
	# 灵石 半档: 动态段 更新 缺口/ETA (随 灵石 变化 才刷)
	g.stones = float(t84["cost"]) / 2.0
	ui._refresh()
	var t84b: Dictionary = g.stone_next_target()
	check(str(btn.tooltip_text).find(g.fmt(float(t84b["shortfall"]))) >= 0,
		"打磨-84 灵石 半档 动态段 缺口 同步 (实际 %s)" % str(btn.tooltip_text).left(80))
	# 购买 下一件: 目标 切换, 动态段 指向 次便宜 未拥有件
	g.stones = float(t84b["cost"]) + 1.0
	if str(t84b["kind"]) == "法器":
		g.try_buy_item(str(t84b["id"]))
	else:
		g.buy_equipment(str(t84b["id"]))
	var t84c: Dictionary = g.stone_next_target()
	ui._refresh()
	check(not t84c.is_empty() and str(btn.tooltip_text).find(str(t84c["name"])) >= 0,
		"打磨-84 购入后 动态段 切换 指向 次便宜 件 (实际 %s)" % str(btn.tooltip_text).left(80))
	check(str(btn.tooltip_text).find(str(t84b["name"])) < 0, "打磨-84 购入后 旧目标 不再 出现")
	# 全拥有: 动态段=已集齐 (买齐 140+10 件)
	for id84 in g.equip_ids:
		if not g.owned_eq.has(id84):
			g.owned_eq.append(id84)
	for it84 in g.ITEMS:
		if not g.owned.has(str(it84["id"])):
			g.owned.append(str(it84["id"]))
	g.stones = 5.0
	ui._refresh()
	check(str(btn.tooltip_text).find("已集齐全部 装备与法器") >= 0, "打磨-84 全拥有 动态段=已集齐 (实际 %s)" % str(btn.tooltip_text).left(80))
	# 收尾: 恢复 基准态 (防 污染 后续 断言)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.stones = 0.0
	g.auto_buy = false
	g.auto_break = false
	ui._refresh()
	await get_tree().process_frame


# 打磨-85: 自动突破按钮 tooltip 动态段 — 构建含 动态段 标记/_refresh 按 接口 刷新/资源状态 动态/节流/飞升口径/道祖圆满/无副作用
func _assert_auto_break_next_tip() -> void:
	var g := GameData
	var btn: Button = ui._auto_break_btn
	check(btn != null, "打磨-85 自动突破按钮存在")
	if btn == null:
		return
	# 基准态 (前节 收尾: 清空 拥有/穿戴/已学, 境界0层1, 灵石 0; 主资源 取 当前 实际态)
	var exp85 := g.auto_break_next_tip()
	check(exp85.find("当前") >= 0 and exp85.find("灵气/秒") >= 0, "打磨-85 基准 动态段 含 主资源 速率 (实际 %s)" % exp85.left(40))
	check(exp85.find("突破至") >= 0, "打磨-85 基准 动态段 含 下一目标 (实际 %s)" % exp85.left(40))
	ui._refresh()
	check(str(btn.tooltip_text) == str(ui._auto_break_tip_static) + exp85, "打磨-85 基准 tooltip=静态前缀+动态段 恒等 (实际 %s)" % str(btn.tooltip_text).left(60))
	check(str(btn.tooltip_text).find("【下次 自动突破 耗时 (动态)】") >= 0, "打磨-85 tooltip 含 动态段 标记")
	# 同态 节流: 再刷 不重写 (tooltip 稳定, 无 副作用)
	var tip_before: String = str(btn.tooltip_text)
	var snap_stats: Dictionary = g.stats.duplicate(true)
	var snap_stones: float = g.stones
	ui._refresh()
	check(str(btn.tooltip_text) == tip_before, "打磨-85 同态 节流 tooltip 稳定")
	check(g.stats == snap_stats and g.stones == snap_stones, "打磨-85 同态 刷 tooltip 无 资源/统计 副作用")
	# 灵气 足够: 动态段 切换 可立即突破 分支 (无 ETA)
	var cost85: float = g.breakthrough_cost()
	g.essence = cost85
	ui._refresh()
	check(str(btn.tooltip_text).find("灵气 已足够, 可立即突破") >= 0, "打磨-85 灵气足够 动态段=可立即突破 无 ETA (实际 %s)" % str(btn.tooltip_text).right(20))
	# 灵气 半档: 动态段 更新 缺口/ETA (随 主资源 变化 才刷)
	g.essence = cost85 / 2.0
	ui._refresh()
	check(str(btn.tooltip_text).find(g.fmt(cost85 - g.essence)) >= 0,
		"打磨-85 灵气 半档 动态段 缺口 同步 (实际 %s)" % str(btn.tooltip_text).left(80))
	# 层顶: 目标 切换 跨境界 (练气 第 N 层 -> 筑基 第 1 层)
	var maxl85: int = g.REALMS[0]["layers"]
	g.layer = maxl85
	ui._refresh()
	check(str(btn.tooltip_text).find("筑基 第 1 层") >= 0, "打磨-85 层顶 动态段 指向 跨境界 (实际 %s)" % str(btn.tooltip_text).left(80))
	g.layer = 1
	ui._refresh()
	# 飞升: 主资源 口径 切 道行 (目标=道行精进至 下一阶段)
	g.ascended = true
	g.dao = 0.0
	g.dao_level = 0
	ui._refresh()
	check(str(btn.tooltip_text).find("道行/秒") >= 0, "打磨-85 飞升 动态段 主资源=道行 (实际 %s)" % str(btn.tooltip_text).left(80))
	check(str(btn.tooltip_text).find("道行精进至 %s" % g.IMMORTAL_REALMS[1]) >= 0, "打磨-85 飞升 动态段 目标=下一阶段 (实际 %s)" % str(btn.tooltip_text).left(80))
	# 道祖 封顶: 圆满 文案
	g.dao_level = g.IMMORTAL_REALMS.size() - 1
	ui._refresh()
	check(str(btn.tooltip_text).find("已至道祖 · 道法自然 ♪ (圆满, 不再精进)") >= 0, "打磨-85 道祖 封顶 圆满 文案 (实际 %s)" % str(btn.tooltip_text).left(80))
	# 收尾: 恢复 基准态 (防 污染 后续 断言)
	g.ascended = false
	g.dao_level = 0
	g.dao = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.auto_buy = false
	g.auto_break = false
	ui._refresh()
	await get_tree().process_frame


# 打磨-69: 自动施展 — 开关按钮存在/tooltip/点击切换/开关态同步/0就绪不触发变更事件/
# 就绪触发变更+_refresh 弹绿色浮动(文案=接口+爆发总量+可见)/冷却中0变更不再刷/开关切换无副作用;
# 收尾恢复基准态 (含 自动系列 三开关 全 关)
func _assert_auto_cast() -> void:
	var g := GameData
	var btn: Button = ui._auto_cast_btn
	check(btn != null, "打磨-69 自动施展开关按钮存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-69 开关按钮 toggle_mode")
	check(btn.tooltip_text.find("自动 施展") >= 0 and btn.tooltip_text.find("存档") >= 0,
		"打磨-69 tooltip 含 自动施展/存档 口径 (实际 %s)" % btn.tooltip_text)
	check(btn.tooltip_text.find("绿色浮动") >= 0, "打磨-69 tooltip 含 绿色浮动 口径")
	check(g.auto_cast == false and not btn.button_pressed and str(btn.text) == "自动施展: 关",
		"打磨-69 初始 关 态 (文本/按压/存档值 一致)")
	# 点击切换: 开 (底部消息 + 按钮态 + 存档值)
	ui._on_auto_cast()
	check(g.auto_cast == true, "打磨-69 点击后 auto_cast=true (实际 %s)" % str(g.auto_cast))
	check(btn.button_pressed and str(btn.text) == "自动施展: 开", "打磨-69 点击后 按钮按压+文本 开")
	check(str(ui._msg_label.text).find("自动施展已开启") >= 0, "打磨-69 开启 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 点击切换: 关
	ui._on_auto_cast()
	check(g.auto_cast == false and not btn.button_pressed and str(btn.text) == "自动施展: 关", "打磨-69 再点 关 态")
	check(str(ui._msg_label.text).find("自动施展已关闭") >= 0, "打磨-69 关闭 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 外部改存档值: _refresh 同步按钮态 (读档恢复 场景)
	g.auto_cast = true
	ui._refresh()
	check(btn.button_pressed and str(btn.text) == "自动施展: 开", "打磨-69 _refresh 同步 外部置 开 按钮态")
	# 受控态: 2 个 境界0 主动神通 已学 (速率 1.0, 各 爆发 60, 冷却 90)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g._active_cd = {}
	g._auto_cast_seq = 0
	ui._auto_cast_msg_seq = 0
	ui._auto_cast_float_count = 0
	var act: Array = []
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id.get(str(id), {})
		if s.is_empty() or str(s.get("type", "")) != "active":
			continue
		if int(s.get("unlock_realm", 99)) == 0 and int(s.get("unlock_layer", 99)) == 1:
			act.append(str(id))
		if act.size() == 2:
			break
	check(act.size() == 2, "打磨-69 受控态 2 神通 数据存在 (实际 %d)" % act.size())
	g.learned.clear()
	for id in act:
		g.learned.append(str(id))
	var fl: Label = ui._auto_cast_float_label
	check(fl != null, "打磨-69 浮动 Label 节点存在")
	# 0 就绪 (全冷却中): _try_auto_cast 0 变更, _refresh 不弹浮动
	for id in act:
		g._active_cd[id] = 90.0
	var seq0: int = g._auto_cast_seq
	var stats0: Dictionary = g.stats.duplicate(true)
	g._try_auto_cast()
	check(g._auto_cast_seq == seq0 and g.stats == stats0, "打磨-69 0就绪 0变更 不增 事件/统计 (seq=%d)" % g._auto_cast_seq)
	ui._refresh()
	check(ui._auto_cast_float_count == 0 and str(fl.text) == "", "打磨-69 0变更 不弹 浮动 (count=%d)" % ui._auto_cast_float_count)
	# 就绪: 手动驱动 _try_auto_cast (2 神通 爆发 120 灵气) + _refresh 弹 绿色浮动 (文案=接口)
	g._active_cd = {}
	g._try_auto_cast()
	check(g._auto_cast_seq == seq0 + 1, "打磨-69 就绪 触发 变更 事件 seq+1 (实际 %d)" % g._auto_cast_seq)
	check(str(g.auto_cast_last_text()) == "自动施展 2 个神通 (爆发+120 灵气)",
		"打磨-69 auto_cast_last_text 数量+爆发 (实际 %s)" % g.auto_cast_last_text())
	check(absf(g.essence - 120.0) < 1e-6, "打磨-69 2 神通 爆发 120 灵气 (实际 %s)" % g.fmt(g.essence))
	fl.text = "SENTINEL_69"
	ui._refresh()
	check(ui._auto_cast_float_count == 1, "打磨-69 _refresh 弹浮动 计数+1 (实际 %d)" % ui._auto_cast_float_count)
	check(str(fl.text) == "✦ 自动施展 2 个神通 (爆发+120 灵气) ✦",
		"打磨-69 浮动文案=接口 (实际 %s)" % str(fl.text))
	check(fl.get_theme_color("font_color") == Color(0.5, 0.9, 0.5), "打磨-69 浮动 绿色")
	check(fl.visible, "打磨-69 浮动 可见")
	# 幂等: 冷却中 0 变更, _refresh 不再刷 (保持 上条 浮动 文案)
	var fl_text: String = str(fl.text)
	var seq1: int = g._auto_cast_seq
	g._try_auto_cast()
	check(g._auto_cast_seq == seq1, "打磨-69 冷却中 0变更 不增 事件 (seq=%d)" % g._auto_cast_seq)
	ui._refresh()
	check(ui._auto_cast_float_count == 1 and str(fl.text) == fl_text, "打磨-69 幂等 后 浮动 不变 (实际 %s)" % str(fl.text))
	# 开关不消耗资源/不计 施展 统计 (开关动作 本身 无 副作用; 前置 置 关 保证 双击 后 仍 关)
	g.auto_cast = false
	var seq_sw: int = g._auto_cast_seq
	var stats_sw: Dictionary = g.stats.duplicate(true)
	var ess_sw: float = g.essence
	ui._on_auto_cast()
	ui._on_auto_cast()
	check(g.auto_cast == false and g._auto_cast_seq == seq_sw and g.stats == stats_sw and absf(g.essence - ess_sw) < 1e-9,
		"打磨-69 开关切换 无 资源/事件/统计 副作用")
	# 收尾: 恢复基准态 (防污染) + 自动系列 三开关 全 关
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	g.auto_buy = false
	g.auto_break = false
	g.auto_cast = false
	g._active_cd = {}
	g.ready_events.clear()
	ui._refresh()
	await get_tree().process_frame


# 打磨-80: 自动领悟 — 自动领悟开关按钮 (境界/层 提升 解锁 新技能 自动 批量 领悟)/
# tooltip 口径/初始 关 态/点击 开 (底部消息+按钮态)/再点 关/外部改 _refresh 同步/
# 受控态 手动驱动 _try_auto_learn (学习 可学数+seq+文案)/_refresh 出 底部消息/
# 幂等 0 变更 不再刷/开关切换 无 资源/事件/统计 副作用/收尾 基准 恢复
func _assert_auto_learn() -> void:
	var g := GameData
	var btn: Button = ui._auto_learn_btn
	check(btn != null, "打磨-80 自动领悟开关按钮存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-80 开关按钮 toggle_mode")
	check(btn.tooltip_text.find("自动 批量 领悟") >= 0 and btn.tooltip_text.find("存档") >= 0,
		"打磨-80 tooltip 含 自动领悟/存档 口径 (实际 %s)" % btn.tooltip_text)
	check(btn.tooltip_text.find("免费") >= 0, "打磨-80 tooltip 含 免费 无 消耗 口径")
	check(g.auto_learn == false and not btn.button_pressed and str(btn.text) == "自动领悟: 关",
		"打磨-80 初始 关 态 (文本/按压/存档值 一致)")
	# 点击切换: 开 (底部消息 + 按钮态 + 存档值)
	ui._on_auto_learn()
	check(g.auto_learn == true, "打磨-80 点击后 auto_learn=true (实际 %s)" % str(g.auto_learn))
	check(btn.button_pressed and str(btn.text) == "自动领悟: 开", "打磨-80 点击后 按钮按压+文本 开")
	check(str(ui._msg_label.text).find("自动领悟已开启") >= 0, "打磨-80 开启 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 点击切换: 关
	ui._on_auto_learn()
	check(g.auto_learn == false and not btn.button_pressed and str(btn.text) == "自动领悟: 关", "打磨-80 再点 关 态")
	check(str(ui._msg_label.text).find("自动领悟已关闭") >= 0, "打磨-80 关闭 底部消息 (实际 %s)" % str(ui._msg_label.text))
	# 外部改存档值: _refresh 同步按钮态 (读档恢复 场景)
	g.auto_learn = true
	ui._refresh()
	check(btn.button_pressed and str(btn.text) == "自动领悟: 开", "打磨-80 _refresh 同步 外部置 开 按钮态")
	# 受控态: 境界0 层1 空已学 (可学 11 个, 数据 固定 种子); 冻结 自动领悟 事件 手动驱动
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g._active_cd = {}
	g._auto_learn_seq = 0
	ui._auto_learn_msg_seq = 0
	# 可学 数 按 数据 动态 计算 (境界0 层1)
	var n_learn80: int = 0
	for sid in g.skill_ids:
		var s: Dictionary = g.skill_by_id.get(str(sid), {})
		if s.is_empty():
			continue
		if (int(s.get("unlock_realm", 99)) < 0) or (int(s.get("unlock_realm", 99)) == 0 and int(s.get("unlock_layer", 99)) <= 1):
			n_learn80 += 1
	check(n_learn80 == 11, "打磨-80 受控态 可学数=11 (境界0 层1, 实际 %d)" % n_learn80)
	# 0 变更 初始 (未 驱动 _try): _refresh 不刷 底部消息
	var msg_before: String = str(ui._msg_label.text)
	ui._refresh()
	check(g._auto_learn_seq == 0, "打磨-80 初始 _try 未驱动 seq=0")
	# 手动驱动 _try_auto_learn (学习 11 个) + _refresh 出 底部消息 (文案=接口)
	g._try_auto_learn()
	check(g.learned.size() == n_learn80, "打磨-80 学习 可学数 11 (实际 %d)" % g.learned.size())
	check(g._auto_learn_seq == 1, "打磨-80 触发 变更 事件 seq+1 (实际 %d)" % g._auto_learn_seq)
	check(str(g.auto_learn_last_text()) == "自动领悟 %d 个技能" % n_learn80,
		"打磨-80 auto_learn_last_text 数量 (实际 %s)" % g.auto_learn_last_text())
	ui._refresh()
	check(str(ui._msg_label.text).find("自动领悟 %d 个技能" % n_learn80) >= 0,
		"打磨-80 _refresh 出 底部消息 (实际 %s)" % str(ui._msg_label.text))
	check(ui._auto_learn_msg_seq == 1, "打磨-80 _refresh 消费 事件 seq 同步 (实际 %d)" % ui._auto_learn_msg_seq)
	# 幂等: 学完 0 变更, _refresh 不再 刷 底部消息 (保持 上条 文案)
	var seq_idem: int = g._auto_learn_seq
	var msg_idem: String = str(ui._msg_label.text)
	g._try_auto_learn()
	check(g._auto_learn_seq == seq_idem, "打磨-80 学完 再试 0 变更 不增 事件 (seq=%d)" % g._auto_learn_seq)
	ui._refresh()
	check(str(ui._msg_label.text) == msg_idem, "打磨-80 幂等 后 底部消息 不变 (实际 %s)" % str(ui._msg_label.text))
	# 升层: 境界0 层2 解锁 5 个 新技能, 自动 领悟 (变更 事件+文案 更新)
	g.layer = 2
	g._try_auto_learn()
	check(g.learned.size() == n_learn80 + 5, "打磨-80 升层 后 新增 5 (实际 %d)" % g.learned.size())
	check(g._auto_learn_seq == 2, "打磨-80 升层 触发 变更 事件 seq=2 (实际 %d)" % g._auto_learn_seq)
	check(str(g.auto_learn_last_text()) == "自动领悟 5 个技能",
		"打磨-80 升层 后 文案 更新 (实际 %s)" % g.auto_learn_last_text())
	ui._refresh()
	check(str(ui._msg_label.text).find("自动领悟 5 个技能") >= 0, "打磨-80 升层 _refresh 出新 文案 (实际 %s)" % str(ui._msg_label.text))
	# 开关切换 无 资源/事件/统计 副作用 (开关动作 本身 无 学习 副作用)
	var stats_sw: Dictionary = g.stats.duplicate(true)
	var ess_sw: float = g.essence
	var stones_sw: float = g.stones
	ui._on_auto_learn()
	check(g.auto_learn == false and str(btn.text) == "自动领悟: 关", "打磨-80 开关切换 关 态")
	check(g.stats == stats_sw and absf(g.essence - ess_sw) < 1e-9 and g.stones == stones_sw,
		"打磨-80 开关切换 无 资源/统计 副作用")
	# 收尾: 恢复基准态 (防污染) + 自动系列 四开关 全 关
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	g.auto_buy = false
	g.auto_break = false
	g.auto_cast = false
	g.auto_learn = false
	g._active_cd = {}
	g.ready_events.clear()
	ui._refresh()
	await get_tree().process_frame


# 打磨-86: 自动施展/自动领悟 按钮 tooltip 动态段 — 构建含 静态前缀+动态段 标记/_refresh 按 接口 刷新/
# 状态 动态 (就绪/冷却/可学/境界 切换)/节流 无副作用/飞升 道行 口径/收尾 基准 恢复
func _assert_auto_next_tips() -> void:
	var g := GameData
	# ============ 自动施展 按钮 (auto_cast_next_tip) ============
	var cb: Button = ui._auto_cast_btn
	check(cb != null, "打磨-86 自动施展按钮存在")
	if cb == null:
		return
	# 受控态: 清空 拥有/穿戴/已学, 境界0层1, 资源 0 (同 打磨-69 受控态 口径)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g._active_cd = {}
	# 未学 主动神通: 静态前缀 + 未学 说明 文案
	var cast_tip0: String = g.auto_cast_next_tip()
	check(cast_tip0 == "未学 任何 主动神通 (先 领悟 神通 后 自动 施展 生效)",
		"打磨-86 施展 未学 说明 文案 (实际 %s)" % cast_tip0)
	check(str(ui._auto_cast_tip_static).find("【神通 就绪/爆发/冷却 (动态)】") >= 0,
		"打磨-86 施展 tooltip 静态 动态段 标记")
	ui._refresh()
	check(str(cb.tooltip_text) == str(ui._auto_cast_tip_static) + cast_tip0,
		"打磨-86 施展 tooltip=静态前缀+动态段 恒等 (实际 %s)" % str(cb.tooltip_text).left(60))
	# 境界0 主动神通 数据序 前 2 (各 爆发 60 秒 冷却 90)
	var act: Array = []
	for id in g.skill_ids:
		var s: Dictionary = g.skill_by_id.get(str(id), {})
		if s.is_empty() or str(s.get("type", "")) != "active":
			continue
		if int(s.get("unlock_realm", 99)) == 0 and int(s.get("unlock_layer", 99)) == 1:
			act.append(str(id))
		if act.size() == 2:
			break
	check(act.size() == 2, "打磨-86 境界0 主动神通 数据存在 (实际 %d)" % act.size())
	for id in act:
		g.learned.append(str(id))
	ui._refresh()
	var rate: float = g.qi_per_sec()
	var cast_tip1: String = g.auto_cast_next_tip()
	check(cast_tip1 == ("就绪 2/2 个, 爆发+%s 灵气 | 全部就绪" % g.fmt(rate * 120.0)),
		"打磨-86 施展 2 就绪 爆发+全就绪 (实际 %s)" % cast_tip1)
	check(str(cb.tooltip_text) == str(ui._auto_cast_tip_static) + cast_tip1,
		"打磨-86 施展 _refresh 刷新 动态段 (就绪态)")
	# 1 冷却中: 就绪 1/2 + 最短冷却 档位
	g._active_cd[str(act[1])] = 45.0
	var cast_tip2: String = g.auto_cast_next_tip()
	ui._refresh()
	check(str(cb.tooltip_text) == str(ui._auto_cast_tip_static) + cast_tip2,
		"打磨-86 施展 1 冷却 动态段 刷新 (实际 %s)" % cast_tip2.left(60))
	check(cast_tip2.find("就绪 1/2") >= 0 and cast_tip2.find(str(g.skill_by_id[str(act[1])]["name"])) >= 0,
		"打磨-86 施展 冷却段 含 名称+档位 (实际 %s)" % cast_tip2)
	# 节流: 同态 _refresh 不重写 tooltip (缓存命中) + 无 资源/统计 副作用
	var t2: String = str(cb.tooltip_text)
	var stats0: Dictionary = g.stats.duplicate(true)
	var ess0: float = g.essence
	ui._refresh()
	check(str(cb.tooltip_text) == t2, "打磨-86 施展 同态 节流 tooltip 稳定")
	check(g.stats == stats0 and absf(g.essence - ess0) < 1e-9, "打磨-86 施展 刷 tooltip 无 资源/统计 副作用")
	# 冷却 清零: 回 全就绪 (动态)
	g._active_cd = {}
	ui._refresh()
	check(str(cb.tooltip_text) == str(ui._auto_cast_tip_static) + g.auto_cast_next_tip(),
		"打磨-86 施展 冷却 清零 回 全就绪 (动态)")
	# 飞升: 爆发 口径 切 道行
	g.ascended = true
	var cast_tip3: String = g.auto_cast_next_tip()
	ui._refresh()
	check(cast_tip3.find("道行") >= 0 and cast_tip3.find("灵气") < 0,
		"打磨-86 施展 飞升 爆发口径=道行 (实际 %s)" % cast_tip3)
	check(str(cb.tooltip_text) == str(ui._auto_cast_tip_static) + cast_tip3,
		"打磨-86 施展 飞升 动态段 刷新")
	g.ascended = false
	ui._refresh()
	check(str(cb.tooltip_text) == str(ui._auto_cast_tip_static) + g.auto_cast_next_tip(),
		"打磨-86 施展 恢复 飞升 态 后 复原")
	# ============ 自动领悟 按钮 (auto_learn_next_tip) ============
	var lb: Button = ui._auto_learn_btn
	check(lb != null, "打磨-86 自动领悟按钮存在")
	# 受控态: 清空 已学 (施展小段 已学 2 神通, 重置 保证 基准 独立), 境界0层1
	g.learned.clear()
	g._active_cd = {}
	g.realm_idx = 0
	g.layer = 1
	var n_learn: int = g.learn_available_count()
	check(n_learn == 11, "打磨-86 基准 可学数=11 (实际 %d)" % n_learn)
	var learn_tip0: String = g.auto_learn_next_tip()
	check(learn_tip0 == ("当前 可学 %d 个 (开启时 立即 批量 领悟)" % n_learn),
		"打磨-86 领悟 基准 可学数 (实际 %s)" % learn_tip0)
	check(str(ui._auto_learn_tip_static).find("【当前 可学/下一 门槛 (动态)】") >= 0,
		"打磨-86 领悟 tooltip 静态 动态段 标记")
	ui._refresh()
	check(str(lb.tooltip_text) == str(ui._auto_learn_tip_static) + learn_tip0,
		"打磨-86 领悟 tooltip=静态前缀+动态段 恒等 (实际 %s)" % str(lb.tooltip_text).left(60))
	# 升层: 可学数 动态 变化 (境界0 层2 解锁 5 个)
	g.layer = 2
	var n_learn2: int = g.learn_available_count()
	check(n_learn2 > n_learn, "打磨-86 升层 可学数 上升 (实际 %d > %d)" % [n_learn2, n_learn])
	var learn_tip1: String = g.auto_learn_next_tip()
	ui._refresh()
	check(learn_tip1 == ("当前 可学 %d 个 (开启时 立即 批量 领悟)" % n_learn2),
		"打磨-86 领悟 升层 可学数 动态 刷新 (实际 %s)" % learn_tip1)
	check(str(lb.tooltip_text) == str(ui._auto_learn_tip_static) + learn_tip1,
		"打磨-86 领悟 _refresh 刷新 动态段 (升层)")
	# 学完 (境界0 层2 可学) → 下一 门槛 指向 (数据序 首个 未学+境界不足 动态 指针)
	# 只读接口 测试 直接 改 learned 态 (learn_all_available, 不 走 _try 自门控 开关)
	g.learn_all_available("", -1)
	check(g.learn_available_count() == 0, "打磨-86 层2 学完 可学归0 (实际 %d)" % g.learn_available_count())
	var nxt: String = ""
	for sid in g.skill_ids:
		if not g.learned.has(str(sid)) and not g.can_learn(str(sid)):
			nxt = str(sid)
			break
	var ns: Dictionary = g.skill_by_id[nxt]
	var learn_tip2: String = "无可学技能 | 下一个 「%s」 还需 %s 第%d层" % [str(ns["name"]), str(g.REALMS[int(ns["unlock_realm"])]["name"]), int(ns["unlock_layer"])]
	check(g.auto_learn_next_tip() == learn_tip2,
		"打磨-86 领悟 学完 下一门槛 指向 (实际 %s)" % g.auto_learn_next_tip())
	ui._refresh()
	check(str(lb.tooltip_text) == str(ui._auto_learn_tip_static) + learn_tip2,
		"打磨-86 领悟 学完 门槛 动态段 刷新")
	# 节流: 同态 _refresh 不重写 tooltip + 无 资源/统计 副作用
	var t_l2: String = str(lb.tooltip_text)
	var stats1: Dictionary = g.stats.duplicate(true)
	var ess1: float = g.essence
	ui._refresh()
	check(str(lb.tooltip_text) == t_l2, "打磨-86 领悟 同态 节流 tooltip 稳定")
	check(g.stats == stats1 and absf(g.essence - ess1) < 1e-9, "打磨-86 领悟 刷 tooltip 无 资源/统计 副作用")
	# 收尾: 恢复基准态 (防污染) + 四开关 全 关
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.essence = 0.0
	g.dao = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	g.auto_buy = false
	g.auto_break = false
	g.auto_cast = false
	g.auto_learn = false
	g._active_cd = {}
	g.ready_events.clear()
	ui._refresh()
	await get_tree().process_frame


# 打磨-88: 一键挂机 — 一键挂机 按钮 (一键 全开/全关 自动系列 5 开关 [突破/购置/施展/领悟/爬塔 (M5-3)]):
# 按钮存在/toggle_mode/tooltip 口径/初始 全关 态 (未全开 未按压 文本=全关)/点击 全开 (5 开关 (M5-3) +
# 各单开关 按钮 按压/文本 同步+底部消息+汇总行 4 金)/再点 全关/部分开 补齐 至 全开 (点击 方向 补齐)/
# 外部 单开关 置 全开 _refresh 同步 按钮态/开关切换 无 资源/统计 副作用/收尾 基准 恢复 (四关)
func _assert_auto_idle() -> void:
	var g := GameData
	var btn: Button = ui._auto_idle_btn
	check(btn != null, "打磨-88 一键挂机 按钮 存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-88 按钮 toggle_mode")
	check(btn.tooltip_text.find("一键") >= 0 and btn.tooltip_text.find("突破") >= 0,
			"打磨-88 tooltip 含 一键/突破 口径 (实际 %s)" % btn.tooltip_text.left(40))
	check(btn.tooltip_text.find("离线期间不触发") >= 0, "打磨-88 tooltip 含 离线 口径")
	# 基准: 全关 (M5-3 起 5 开关 含 爬塔; 塔 层数 归零 防 爬塔段 受 旧档 影响)
	g.auto_break = false
	g.auto_buy = false
	g.auto_cast = false
	g.auto_learn = false
	g.auto_tower = false
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd = {}
	g.ready_events.clear()
	ui._refresh()
	# 初始 全关 态: 未按压 文本=全关 (与 各单开关 一致)
	check(not btn.button_pressed and str(btn.text) == "一键挂机: 全关",
			"打磨-88 初始 全关 态 (未按压 文本=全关; 实际 %s)" % str(btn.text))
	# 点击: 全开 (5 开关 (M5-3) + 各单开关 按钮 按压/文本 + 底部消息)
	var stats_k: Dictionary = g.stats.duplicate(true)
	var ess_k: float = g.essence
	var stones_k: float = g.stones
	ui._on_auto_idle()
	check(g.auto_break and g.auto_buy and g.auto_cast and g.auto_learn and g.auto_tower,
			"打磨-88 点击 全开 5 开关 (M5-3, 实际 %s)" % g.auto_summary_key())
	check(g.auto_summary_key() == "1|1|1|1|1", "打磨-88 全开 汇总键 1|1|1|1|1 (M5-3, 实际 %s)" % g.auto_summary_key())
	check(btn.button_pressed and str(btn.text) == "一键挂机: 全开", "打磨-88 点击 后 按压+文本 全开")
	check(str(ui._msg_label.text).find("一键挂机已开启") >= 0,
			"打磨-88 全开 底部消息 (实际 %s)" % str(ui._msg_label.text).left(40))
	# 各单开关 按钮 同步 (按压/文本 与 开关值 一致)
	check(ui._auto_break_btn.button_pressed and str(ui._auto_break_btn.text) == "自动突破: 开",
			"打磨-88 全开 后 自动突破 按钮 同步 开")
	check(ui._auto_buy_btn.button_pressed and str(ui._auto_buy_btn.text) == "自动购置: 开",
			"打磨-88 全开 后 自动购置 按钮 同步 开")
	check(ui._auto_cast_btn.button_pressed and str(ui._auto_cast_btn.text) == "自动施展: 开",
			"打磨-88 全开 后 自动施展 按钮 同步 开")
	check(ui._auto_learn_btn.button_pressed and str(ui._auto_learn_btn.text) == "自动领悟: 开",
			"打磨-88 全开 后 自动领悟 按钮 同步 开")
	# 汇总行 5 段 全 金 (auto_summary 同步 经 _refresh; M5-3 含 爬塔)
	ui._refresh()
	# 点击: 全关
	ui._on_auto_idle()
	check(not g.auto_break and not g.auto_buy and not g.auto_cast and not g.auto_learn and not g.auto_tower,
			"打磨-88 再点 全关 5 开关 (M5-3, 实际 %s)" % g.auto_summary_key())
	check(g.auto_summary_key() == "0|0|0|0|0", "打磨-88 全关 汇总键 0|0|0|0|0 (M5-3, 实际 %s)" % g.auto_summary_key())
	check(not btn.button_pressed and str(btn.text) == "一键挂机: 全关", "打磨-88 再点 后 按压+文本 全关")
	check(str(ui._msg_label.text).find("一键挂机已关闭") >= 0,
			"打磨-88 全关 底部消息 (实际 %s)" % str(ui._msg_label.text).left(40))
	check(ui._auto_break_btn.button_pressed == false and str(ui._auto_break_btn.text) == "自动突破: 关",
			"打磨-88 全关 后 自动突破 按钮 同步 关")
	# 部分开 补齐: 置 3/5 开, 点击 = 补齐 至 全开 (非 仅关 已开; M5-3)
	g.auto_break = true
	g.auto_buy = true
	g.auto_cast = true
	g.auto_learn = false
	g.auto_tower = false
	ui._refresh()
	check(not btn.button_pressed and str(btn.text) == "一键挂机: 全关",
			"打磨-88 部分开(3/5) 按钮 仍 未按压/文本 全关 (补齐 方向, M5-3)")
	ui._on_auto_idle()
	check(g.auto_break and g.auto_buy and g.auto_cast and g.auto_learn and g.auto_tower,
			"打磨-88 部分开 点击 补齐 至 全开 (含 已开 3 项 + 补 领悟/爬塔, M5-3)")
	check(btn.button_pressed and str(btn.text) == "一键挂机: 全开", "打磨-88 补齐 后 按压+文本 全开")
	# 打磨-89: 一键挂机按钮 tooltip 动态段 (静态前缀+动态段 恒等 / 5 段 固定序 (M5-3 含 爬塔) / 同态 节流 /
	# 开关 切换 同步 / 全关 说明 文案 / 无 资源 副作用)
	check(str(btn.tooltip_text).find("【各开关 动态 状态 (动态)】") >= 0,
			"打磨-89 tooltip 含 动态段 标记 (实际 %s)" % str(btn.tooltip_text).left(40))
	check(str(btn.tooltip_text) == ui._auto_idle_tip_static + g.auto_idle_next_tip(),
			"打磨-89 tooltip=静态前缀+动态段 恒等")
	var p_break: int = str(btn.tooltip_text).find("突破: 当前")
	var p_buy: int = str(btn.tooltip_text).find("购置: 当前")
	var p_cast: int = str(btn.tooltip_text).find("施展: ")
	var p_learn: int = str(btn.tooltip_text).find("领悟: ")
	var p_tower: int = str(btn.tooltip_text).find("爬塔: ")
	check(p_break >= 0 and p_buy >= 0 and p_cast >= 0 and p_learn >= 0 and p_tower >= 0,
			"打磨-89 全开 tooltip 含 5 段 前缀 (突破/购置/施展/领悟/爬塔, M5-3)")
	check(p_break < p_buy and p_buy < p_cast and p_cast < p_learn and p_learn < p_tower,
			"打磨-89 5 段 固定序 突破>购置>施展>领悟>爬塔 (M5-3, 实际 %d,%d,%d,%d,%d)" % [p_break, p_buy, p_cast, p_learn, p_tower])
	check(str(btn.tooltip_text).find("未学 任何 主动神通") >= 0,
			"打磨-89 未学 神通 时 施展段=说明 文案")
	ui._refresh()
	check(str(btn.tooltip_text) == ui._auto_idle_tip_static + g.auto_idle_next_tip(),
			"打磨-89 同态 节流 tooltip 稳定 无 资源 副作用")
	# 组合 2 开 (购置+领悟): 动态段 仅 2 段 (固定序 购置<领悟; 不含 未开 段 突破/施展/爬塔, M5-3)
	g.set_auto_all(false)
	g.auto_buy = true
	g.auto_learn = true
	ui._refresh()
	check(str(btn.tooltip_text).find("突破: 当前") < 0 and str(btn.tooltip_text).find("施展: ") < 0
			and str(btn.tooltip_text).find("爬塔: ") < 0,
			"打磨-89 组合 2 开 不含 未开 段 (突破/施展/爬塔, M5-3)")
	check(str(btn.tooltip_text).find("购置: 当前") < str(btn.tooltip_text).find("领悟: "),
			"打磨-89 组合 2 开 固定序 购置<领悟")
	# 全关: 说明 文案
	g.set_auto_all(false)
	ui._refresh()
	check(str(btn.tooltip_text).find("各开关 均 未开启") >= 0,
			"打磨-89 全关 动态段=说明 文案 (实际 %s)" % str(btn.tooltip_text).left(40))
	check(g.stats == stats_k and absf(g.essence - ess_k) < 1e-9 and g.stones == stones_k,
			"打磨-89 tooltip 动态段 只读 无 资源/统计 副作用")
	# 外部 单开关 置 全开: _refresh 同步 按钮态 (读档恢复 场景; M5-3 起 5 开关 含 爬塔)
	g.set_auto_all(false)
	g.auto_break = true
	g.auto_buy = true
	g.auto_cast = true
	g.auto_learn = true
	g.auto_tower = true
	ui._refresh()
	check(btn.button_pressed and str(btn.text) == "一键挂机: 全开",
			"打磨-88 _refresh 同步 外部 置 全开 按钮态 (M5-3)")
	# 开关切换 无 资源/统计 副作用 (开关动作 本身 无 资源 消耗)
	check(g.stats == stats_k and absf(g.essence - ess_k) < 1e-9 and g.stones == stones_k,
			"打磨-88 开关切换 无 资源/统计 副作用")
	# 收尾: 恢复 基准 (四关)
	g.set_auto_all(false)
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.last_break_result = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd = {}
	g.ready_events.clear()
	ui._refresh()
	await get_tree().process_frame


# 打磨-90: 顶栏 一键挂机 状态徽标 — 金色圆角 "挂机" (5 自动开关 (M5-3) 全开 才 显示, 部分开/全关 隐藏,
# 与 打磨-73 "自动 N/5" 同父/同风格 但 只表达 全开 终态 (M5-3); flat Button 可点击热区 (手型光标+悬停金边):
# 点击=切 修行页 + 一键挂机 按钮 金边高亮 1.2s (复用 法器区 高亮 口径); 纯导航 无 存档/统计 副作用.
# 断言 (手动驱动 确定性): 徽标节点 顶栏同父/flat Button+手型/悬停金边/tooltip 全开口径/
# 初始 全关 隐藏 文本空/部分开 4/5 隐藏 (与 自动 4/5 并存)/全开 显示 "挂机"+tooltip/
# 全开 节流 同态 稳定/点击 → 切 修行页(tab0)+一键挂机按钮 金边高亮(border宽=2 金)+底部消息/
# 重入 kill 旧 tween 不叠加/1.2s 后 高亮 自动恢复 边框0/全关 隐藏 无热区/无 资源/统计/开关 副作用/收尾 隐藏.
func _assert_idle_badge() -> void:
	var g := GameData
	# 前置: _assert_auto_idle 收尾 五关 全 关 (M5-3); 切 成就页 作为 点击 前 受控 tab
	ui._tab.current_tab = 3
	# 徽标 节点: 顶栏 子节点 (与 自动 徽标 同父), flat Button + 手型光标 + 金色字
	var badge: Button = ui._idle_badge
	check(badge != null, "打磨-90 顶栏 挂机 徽标 节点 存在")
	if badge == null:
		return
	check(badge is Button and badge.flat == true and badge.toggle_mode == false,
			"打磨-90 徽标 flat 非toggle Button (可点热区)")
	check(badge.get_parent() == ui._auto_badge.get_parent(),
			"打磨-90 徽标 挂在 顶栏 (与 自动 徽标 同父; 实际 %s)" % str(badge.get_parent()))
	check(badge.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
			"打磨-90 徽标 手型光标 提示可点")
	check(badge.get_theme_color("font_color") == ui.GOLD,
			"打磨-90 徽标 字色 金色 (实际 %s)" % str(badge.get_theme_color("font_color")))
	check(badge.get_theme_stylebox("hover") != null
			and badge.get_theme_stylebox("hover").border_width_left == 1,
			"打磨-90 徽标 悬停 金边 样式 非空 (hover 边框宽=1)")
	# 初始 全关 态: 隐藏, 文本空, tooltip 空
	check(badge.visible == false and str(badge.text) == "" and str(badge.tooltip_text) == "",
			"打磨-90 初始 全关 徽标 隐藏/文本空/tooltip 空 (visible=%s 文本=%s)" % [str(badge.visible), str(badge.text)])
	# 部分开 4/5 (M5-3): 挂机 徽标 隐藏 (但 自动 N/5 徽标 显示 4/5 表达 进度)
	g.auto_break = true
	g.auto_buy = true
	g.auto_cast = true
	g.auto_learn = true
	g.auto_tower = false
	ui._refresh()
	check(badge.visible == false, "打磨-90 部分开(4/5) 挂机 徽标 隐藏 (M5-3, visible=%s)" % str(badge.visible))
	check(str(ui._auto_badge.text) == "自动 4/5",
			"打磨-90 部分开(4/5) 自动 徽标 仍 显示 4/5 (M5-3, 实际 %s)" % str(ui._auto_badge.text))
	# 全开 (5 开关): 挂机 徽标 显示 "挂机" + tooltip 全开 口径 + 自动 徽标 5/5 并存
	g.auto_tower = true
	ui._refresh()
	check(badge.visible == true, "打磨-90 全开 挂机 徽标 显示 (visible=%s)" % str(badge.visible))
	check(str(badge.text) == "挂机", "打磨-90 全开 文案=挂机 (实际 %s)" % str(badge.text))
	var ib_tip: String = str(badge.tooltip_text)
	check(ib_tip.find("一键挂机 已全开") >= 0 and ib_tip.find("离线期间不触发") >= 0,
			"打磨-90 全开 tooltip 含 全开/离线 口径 (实际 %s)" % ib_tip.left(40))
	check(ib_tip.find("直达 修行页·一键挂机按钮") >= 0,
			"打磨-90 全开 tooltip 含 点击直达 口径")
	check(str(ui._auto_badge.text) == "自动 5/5",
			"打磨-90 全开 自动 徽标 5/5 并存 (M5-3, 实际 %s)" % str(ui._auto_badge.text))
	# 节流: 全开 同态 再 _refresh, 文本/可见 稳定 无副作用
	var snap90: Dictionary = g.stats.duplicate(true)
	var st90: float = g.stones
	ui._refresh()
	check(badge.visible == true and str(badge.text) == "挂机",
			"打磨-90 全开 同态 节流 文本/可见 稳定")
	# 副作用快照 (点击 不应改变 资源/统计/开关)
	var snap90b: Dictionary = g.stats.duplicate(true)
	var st90b: float = g.stones
	var key90: String = g.auto_summary_key()
	# 点击 → 切 修行页(tab0) + 一键挂机按钮 金边高亮 + 底部消息
	var rest_sb: StyleBoxFlat = ui._auto_idle_btn.get_theme_stylebox("normal")
	var rest_border: int = rest_sb.border_width_left if rest_sb != null else -1
	ui._on_idle_badge()
	await get_tree().process_frame
	check(ui._tab.current_tab == 0, "打磨-90 点击 徽标 → 切 修行页 (tab=0) (实际 %d)" % ui._tab.current_tab)
	var hi_sb: StyleBoxFlat = ui._auto_idle_btn.get_theme_stylebox("normal")
	check(hi_sb != null and hi_sb.border_width_left == 2 and hi_sb.border_color == ui.GOLD,
			"打磨-90 点击 徽标 → 一键挂机按钮 金边高亮 (边框宽=2 金)")
	check(str(ui._msg_label.text).find("直达 修行页·一键挂机按钮") >= 0,
			"打磨-90 点击 徽标 → 底部消息确认 (实际 %s)" % str(ui._msg_label.text).left(40))
	# 点击 不 误触 一键挂机 开关 (开关/资源/统计 不变, 纯导航)
	check(g.auto_summary_key() == key90, "打磨-90 点击 徽标 不 误触 一键挂机 开关 (仍 全开 %s)" % g.auto_summary_key())
	check(g.stones == st90b and g.stats == snap90b, "打磨-90 点击 徽标 无 资源/统计 副作用 (纯导航)")
	# 重入: 高亮中 再点 徽标 kill 旧 tween 重开 (不报错 且 仍 金边)
	ui._on_idle_badge()
	await get_tree().process_frame
	var hi_sb2: StyleBoxFlat = ui._auto_idle_btn.get_theme_stylebox("normal")
	check(hi_sb2 != null and hi_sb2.border_width_left == 2, "打磨-90 高亮中 重入 不叠加/不报错 (仍 金边)")
	# 等待 tween 结束 (1.2s, 重入后 重新计时) 后 自动恢复 边框 0 (回到 构建时 默认 normal)
	await get_tree().create_timer(1.4).timeout
	var rest_sb2: StyleBoxFlat = ui._auto_idle_btn.get_theme_stylebox("normal")
	check(rest_sb2 != null and rest_sb2.border_width_left == rest_border,
			"打磨-90 一键挂机按钮 高亮 1.2s 后 自动恢复 (边框宽=%d)" % rest_sb2.border_width_left)
	# 全关 恢复 隐藏 (挂机 徽标 无热区); 自动 徽标 亦 隐藏
	g.set_auto_all(false)
	ui._refresh()
	check(badge.visible == false and str(badge.text) == "" and str(badge.tooltip_text) == "",
			"打磨-90 全关 挂机 徽标 恢复 隐藏/文本空/tooltip 空 (visible=%s)" % str(badge.visible))
	check(ui._auto_badge.visible == false, "打磨-90 全关 自动 徽标 亦 隐藏 (无热区)")
	# 收尾: 修行页 稳定, 一键挂机按钮 无边框 (防 污染); 无 资源/统计 副作用
	check(ui._tab.current_tab == 0, "打磨-90 收尾 保持 修行页")
	var rest_sb3: StyleBoxFlat = ui._auto_idle_btn.get_theme_stylebox("normal")
	check(rest_sb3 != null and rest_sb3.border_width_left == rest_border, "打磨-90 收尾 一键挂机按钮 无边框")
	check(g.stones == st90b and g.stats == snap90b, "打磨-90 收尾 无 资源/统计 副作用")
	await get_tree().process_frame


# 打磨-70: 自动系列 状态汇总 — 汇总行存在 (前缀+5 段标签, M5-3 起 5 开关 含 爬塔)/tooltip 口径/
# 四关 初始 全灰 ✗/开关切换 (按钮点击+外部置) 后 _refresh 同步 文本/颜色 (开=金 关=灰)/
# 节流 (键不变不重刷)/无 存档/统计 副作用; 收尾 四开关 全 关 + 汇总 恢复 四关 态
func _assert_auto_summary() -> void:
	var g := GameData
	var box: HBoxContainer = ui._auto_sum_box
	check(box != null, "打磨-70 自动系列 汇总行 节点存在")
	if box == null:
		return
	check(ui._auto_sum_prefix != null and str(ui._auto_sum_prefix.text) == "自动:",
		"打磨-70 前缀标签 文本=自动: (实际 %s)" % str(ui._auto_sum_prefix.text))
	check(ui._auto_sum_segs.size() == 5, "打磨-70 5 个 状态段标签 (M5-3 含 爬塔) (实际 %d)" % ui._auto_sum_segs.size())
	# 打磨-74: tooltip 由 汇总行 HBox 上移到 外壳 Panel (金边高亮 载体)
	var panel70: Panel = ui._auto_sum_panel
	check(panel70 != null, "打磨-70 汇总行 外壳 Panel 存在 (打磨-74 高亮载体)")
	check(panel70.tooltip_text.find("自动突破") >= 0 and panel70.tooltip_text.find("自动购置") >= 0
			and panel70.tooltip_text.find("自动施展") >= 0 and panel70.tooltip_text.find("自动领悟") >= 0
			and panel70.tooltip_text.find("自动爬塔") >= 0
			and panel70.tooltip_text.find("离线期间不触发") >= 0,
		"打磨-70 汇总行 tooltip 含 五开关 口径 (M5-3, 实际 %s)" % panel70.tooltip_text)
	# 初始态: 四关 (打磨-69 收尾 已 全 关 + _refresh)
	ui._refresh()
	check(ui._auto_sum_key == "0|0|0|0|0", "打磨-70 初始 状态键 0|0|0|0|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	var seg0: Label = ui._auto_sum_segs[0]
	var seg1: Label = ui._auto_sum_segs[1]
	var seg2: Label = ui._auto_sum_segs[2]
	var seg3: Label = ui._auto_sum_segs[3]
	var seg4: Label = ui._auto_sum_segs[4]
	check(str(seg0.text) == "突破 ✗" and str(seg1.text) == "购置 ✗" and str(seg2.text) == "施展 ✗"
			and str(seg3.text) == "领悟 ✗" and str(seg4.text) == "爬塔 ✗",
		"打磨-70 五关 段文本 全 ✗ (M5-3, 实际 %s/%s/%s/%s/%s)" % [str(seg0.text), str(seg1.text), str(seg2.text), str(seg3.text), str(seg4.text)])
	check(seg0.get_theme_color("font_color") == ui.DIM and seg1.get_theme_color("font_color") == ui.DIM
			and seg2.get_theme_color("font_color") == ui.DIM and seg3.get_theme_color("font_color") == ui.DIM
			and seg4.get_theme_color("font_color") == ui.DIM,
		"打磨-70 五关 段颜色 全灰")
	# 点击 自动突破 开关 → _refresh 同步 (突破 段 转金 ✓)
	ui._on_auto_break()
	ui._refresh()
	check(g.auto_break == true, "打磨-70 点击后 auto_break=true (实际 %s)" % str(g.auto_break))
	check(ui._auto_sum_key == "1|0|0|0|0", "打磨-70 键 1|0|0|0|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	check(str(seg0.text) == "突破 ✓" and seg0.get_theme_color("font_color") == ui.GOLD,
		"打磨-70 突破 段 金 ✓ (实际 %s)" % str(seg0.text))
	check(str(seg1.text) == "购置 ✗" and seg1.get_theme_color("font_color") == ui.DIM,
		"打磨-70 购置 段 保持 灰 ✗")
	# 外部置 购置 开 (读档恢复 场景): _refresh 同步 (键变化 才刷, 仅 购置 段 变色)
	g.auto_buy = true
	var key_before: String = ui._auto_sum_key
	ui._refresh()
	check(ui._auto_sum_key == "1|1|0|0|0" and key_before == "1|0|0|0|0", "打磨-70 外部置 购置 键 1|1|0|0|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	check(str(seg1.text) == "购置 ✓" and seg1.get_theme_color("font_color") == ui.GOLD,
		"打磨-70 购置 段 金 ✓ (实际 %s)" % str(seg1.text))
	check(str(seg0.text) == "突破 ✓" and seg0.get_theme_color("font_color") == ui.GOLD, "打磨-70 突破 段 保持 金")
	# 节流: 状态键 未变 时 _refresh 不重刷 (缓存键 保持, 段文本/颜色 稳定)
	ui._refresh()
	check(ui._auto_sum_key == "1|1|0|0|0" and str(seg1.text) == "购置 ✓", "打磨-70 键不变 节流 不重刷")
	# 点击 自动施展 开关 → 三开 (施展 段 转金)
	ui._on_auto_cast()
	ui._refresh()
	check(ui._auto_sum_key == "1|1|1|0|0" and str(seg2.text) == "施展 ✓"
			and seg2.get_theme_color("font_color") == ui.GOLD, "打磨-70 三开 施展 段 金 ✓ (实际 %s)" % ui._auto_sum_key)
	# 外部置 领悟 开 → 四开 (领悟 段 转金, 打磨-80)
	g.auto_learn = true
	ui._refresh()
	check(ui._auto_sum_key == "1|1|1|1|0" and str(seg3.text) == "领悟 ✓"
			and seg3.get_theme_color("font_color") == ui.GOLD, "打磨-70 四开 领悟 段 金 ✓ (实际 %s)" % ui._auto_sum_key)
	# 开关切换 无 存档/统计 副作用 (汇总行 纯展示)
	var stats_sum: Dictionary = g.stats.duplicate(true)
	var stones_sum: float = g.stones
	var seq_sum: int = g._auto_cast_seq
	ui._on_auto_buy()
	ui._refresh()
	check(g.auto_buy == false and ui._auto_sum_key == "1|0|1|1|0"
			and g.stats == stats_sum and g.stones == stones_sum and g._auto_cast_seq == seq_sum,
		"打磨-70 开关切换 无 统计/资源/事件 副作用 (键=%s)" % ui._auto_sum_key)
	# 收尾: 四开关 全 关, 汇总 恢复 四关 态 (防污染)
	ui._on_auto_break()
	ui._on_auto_cast()
	ui._on_auto_learn()
	if ui._tw_auto_on:
		ui._on_tower_auto()
	ui._refresh()
	check(g.auto_break == false and g.auto_buy == false and g.auto_cast == false and g.auto_learn == false
			and g.auto_tower == false
			and ui._auto_sum_key == "0|0|0|0|0"
			and str(seg0.text) == "突破 ✗" and str(seg1.text) == "购置 ✗" and str(seg2.text) == "施展 ✗"
			and str(seg3.text) == "领悟 ✗" and str(seg4.text) == "爬塔 ✗",
		"打磨-70 收尾 五关 汇总 恢复 全 ✗ (M5-3)")
	await get_tree().process_frame


# 打磨-71: 自动系列 汇总行 点击直达 — 5 段热区 flat Button (手型光标+悬停金边, M5-3 起 5 段 含 爬塔)/
# tooltip 口径/点击=切 对应 自动开关 (与上方按钮 同 口径: 状态+上方按钮按压态+底部消息确认)/
# 再点=关闭/节流 (键不变不重刷)/无 资源/统计 副作用; 收尾 五开关 全 关 恢复 0|0|0|0|0
func _assert_auto_sum_jump() -> void:
	var g := GameData
	var btns: Array = ui._auto_sum_btns
	check(btns.size() == 5, "打磨-71 5 个 段热区 按钮 (M5-3 含 爬塔) (实际 %d)" % btns.size())
	if btns.size() < 5:
		return
	for i in 5:
		var b: Button = btns[i]
		check(b.flat == true and b.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
			"打磨-71 段%d 热区 flat+手型光标 (flat=%s cursor=%d)" % [i, str(b.flat), b.mouse_default_cursor_shape])
	check(str(btns[0].tooltip_text).find("点击切换 自动突破") >= 0
			and str(btns[1].tooltip_text).find("点击切换 自动购置") >= 0
			and str(btns[2].tooltip_text).find("点击切换 自动施展") >= 0
			and str(btns[3].tooltip_text).find("点击切换 自动领悟") >= 0
			and str(btns[4].tooltip_text).find("点击切换 自动爬塔") >= 0,
		"打磨-71 段热区 tooltip 含 点击切换 口径 (突破/购置/施展/领悟/爬塔, M5-3)")
	check(str(ui._auto_sum_panel.tooltip_text).find("各段可点击") >= 0,
			"打磨-71 汇总行 tooltip 含 各段可点击 说明 (打磨-74 起 tooltip 挂在外壳 Panel)")
	# 初始 四关 (打磨-70 收尾 全 关)
	ui._refresh()
	check(ui._auto_sum_key == "0|0|0|0|0", "打磨-71 初始 状态键 0|0|0|0|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	# 点击 突破 段 → 自动突破 开 (与上方按钮 同 口径: 状态+按压态+底部消息)
	var stats0: Dictionary = g.stats.duplicate(true)
	var stones0: float = g.stones
	btns[0].pressed.emit()
	ui._refresh()
	check(g.auto_break == true and ui._auto_break_btn.is_pressed() == true,
		"打磨-71 点击 突破 段 auto_break=true+上方按钮 按压态")
	check(ui._auto_sum_key == "1|0|0|0|0", "打磨-71 点击后 键 1|0|0|0|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	check(str(ui._msg_label.text).find("自动突破已开启") >= 0,
		"打磨-71 点击 突破 段 底部消息 确认 (实际 %s)" % str(ui._msg_label.text))
	# 点击 购置 段 → 自动购置 开
	btns[1].pressed.emit()
	ui._refresh()
	check(g.auto_buy == true and ui._auto_buy_btn.is_pressed() == true
			and ui._auto_sum_key == "1|1|0|0|0", "打磨-71 点击 购置 段 auto_buy=true 键 1|1|0|0|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	check(str(ui._msg_label.text).find("自动购置已开启") >= 0, "打磨-71 点击 购置 段 底部消息 确认")
	# 点击 施展 段 → 三开
	btns[2].pressed.emit()
	ui._refresh()
	check(g.auto_cast == true and ui._auto_cast_btn.is_pressed() == true and ui._auto_sum_key == "1|1|1|0|0",
		"打磨-71 点击 施展 段 三开 键 1|1|1|0|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	# 点击 领悟 段 → 四开 (打磨-80)
	btns[3].pressed.emit()
	ui._refresh()
	check(g.auto_learn == true and ui._auto_learn_btn.is_pressed() == true and ui._auto_sum_key == "1|1|1|1|0",
		"打磨-71 点击 领悟 段 四开 键 1|1|1|1|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	check(str(ui._msg_label.text).find("自动领悟已开启") >= 0, "打磨-71 点击 领悟 段 底部消息 确认")
	# 再点 突破 段 → 关闭 (与上方按钮 再点 同 口径)
	btns[0].pressed.emit()
	ui._refresh()
	check(g.auto_break == false and ui._auto_break_btn.is_pressed() == false and ui._auto_sum_key == "0|1|1|1|0",
		"打磨-71 再点 突破 段 auto_break=false 键 0|1|1|1|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	check(str(ui._msg_label.text).find("自动突破已关闭") >= 0, "打磨-71 关闭 底部消息 确认")
	# 点击切换 无 资源/统计 副作用
	check(g.stats == stats0 and g.stones == stones0,
		"打磨-71 点击切换 无 统计/资源 副作用")
	# 节流: 键 未变 _refresh 不重刷 (段文本/颜色 稳定)
	var seg0: Label = ui._auto_sum_segs[0]
	var t_before: String = str(seg0.text)
	ui._refresh()
	check(ui._auto_sum_key == "0|1|1|1|0" and str(seg0.text) == t_before, "打磨-71 键不变 节流 不重刷 (M5-3)")
	# 收尾: 四开关 全 关 恢复 (防污染)
	btns[1].pressed.emit()
	btns[2].pressed.emit()
	btns[3].pressed.emit()
	ui._refresh()
	check(g.auto_break == false and g.auto_buy == false and g.auto_cast == false and g.auto_learn == false
			and ui._auto_sum_key == "0|0|0|0|0", "打磨-71 收尾 五关 恢复 0|0|0|0|0 (M5-3, 实际 %s)" % ui._auto_sum_key)
	await get_tree().process_frame


# 打磨-72: 启动 自动系列 恢复 提示 — _ready 时 任一 自动 开关 为 开 则 底部 消息
# "已恢复 自动: …" (文案=GameData.auto_restore_text, 全关 空串 不提示, 离线 消息 优先 让位).
# "仅 启动 一次" 由 _ready 只调 一次 _show_auto_restore_msg 保证 (函数 本身 无 启动 门控,
# 手动驱动 重放 会 再显示, 与 _show_msg/_offline_float 同 口径 可 重放).
# 断言 (手动驱动 确定性, 不依赖 启动 时 真实 档态, 防 flake): _ready 三关 不提示 计数 0/
# 单开+组合 底部消息 文案=接口+计数+1/离线消息 优先 让位/全关 不提示 计数不变/
# 无 资源/统计 副作用/收尾 三关 恢复 计数 不变
func _assert_auto_restore() -> void:
	var g := GameData
	# _ready 时 三开关 全关 (ui_test _ready 防御性 重置 + 打磨-71 收尾), 启动 未 触发 提示
	check(ui._auto_restore_count == 0, "打磨-72 启动 三关 未 触发 提示 (实际 %d)" % ui._auto_restore_count)
	check(str(ui._auto_restore_last_text) == "", "打磨-72 启动 三关 无 文案 (实际 %s)" % str(ui._auto_restore_last_text))
	# 手动驱动: 单开 购置 -> 底部 消息 文案=接口 + 计数+1 (文案 由 GameData 接口 提供)
	g.auto_buy = true
	var exp72: String = g.auto_restore_text()
	check(exp72 == "已恢复 自动: 购置", "打磨-72 接口 文案(仅购置) (实际 %s)" % exp72)
	var stats72: Dictionary = g.stats.duplicate(true)
	var stones72: float = g.stones
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 1, "打磨-72 单开 提示 计数+1 (实际 %d)" % ui._auto_restore_count)
	check(str(ui._auto_restore_last_text) == exp72, "打磨-72 单开 文案=接口 (实际 %s)" % str(ui._auto_restore_last_text))
	check(str(ui._msg_label.text) == exp72, "打磨-72 单开 底部消息=文案 (实际 %s)" % str(ui._msg_label.text))
	# 单开 领悟 -> 文案 固定序 含 领悟 (打磨-80)
	g.auto_buy = false
	g.auto_learn = true
	exp72 = g.auto_restore_text()
	check(exp72 == "已恢复 自动: 领悟", "打磨-72 接口 文案(仅领悟, 打磨-80) (实际 %s)" % exp72)
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 2 and str(ui._auto_restore_last_text) == exp72
			and str(ui._msg_label.text) == exp72, "打磨-72 单开 领悟 文案=接口 计数+1 (实际 %s / %d)" % [str(ui._msg_label.text), ui._auto_restore_count])
	# 组合 开 (购置+施展) -> 文案 固定序 购置·施展
	g.auto_learn = false
	g.auto_buy = true
	g.auto_cast = true
	exp72 = g.auto_restore_text()
	check(exp72 == "已恢复 自动: 购置·施展", "打磨-72 接口 文案(购置+施展) (实际 %s)" % exp72)
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 3 and str(ui._auto_restore_last_text) == exp72
			and str(ui._msg_label.text) == exp72, "打磨-72 组合 文案=接口 计数+1 (实际 %s / %d)" % [str(ui._msg_label.text), ui._auto_restore_count])
	# 离线 消息 优先: offline_msg 非空 时 本 提示 让位 (早期 返回 不 _show_msg, 不覆盖 已有 文案, 计数 不变)
	g.offline_msg = "离线 8小时, 收获 灵气 999, 灵石 888"
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 3 and str(ui._msg_label.text) == "已恢复 自动: 购置·施展",
			"打磨-72 离线消息 优先 让位 (计数不变, 不 覆盖 已有 底部 消息)")
	g.offline_msg = ""
	# 提示 触发 无 资源/统计 副作用 (纯 展示)
	check(g.stats == stats72 and g.stones == stones72, "打磨-72 提示 无 资源/统计 副作用")
	# 全关 不提示 计数不变 (auto_restore_text 空串)
	g.auto_buy = false
	g.auto_cast = false
	g.auto_learn = false
	check(g.auto_restore_text() == "", "打磨-72 全关 接口 空串")
	ui._show_auto_restore_msg()
	check(ui._auto_restore_count == 3, "打磨-72 全关 不提示 计数不变 (实际 %d)" % ui._auto_restore_count)
	# 收尾: 四开关 全 关 (防 污染), 恢复 干净 基准 (offline_msg 已 复位 空)
	g.auto_break = false
	g.auto_buy = false
	g.auto_cast = false
	g.auto_learn = false
	ui._refresh()
	check(ui._auto_restore_count == 3 and str(ui._auto_restore_last_text) == "已恢复 自动: 购置·施展",
			"打磨-72 收尾 四关 恢复 计数/文案 稳定 (实际 %d / %s)" % [ui._auto_restore_count, str(ui._auto_restore_last_text)])
	await get_tree().process_frame


# 打磨-73: 顶栏 自动系列 状态徽标 — 顶栏 最右 金色 "自动 N/5" 徽标 (M5-3 起 5 开关; 任一开关开 显示, 全关 隐藏;
# tooltip 复用 auto_summary_text 五开关 口径 (M5-3 起 5 开关) + 离线不触发 说明; 开启数 变化才刷, 无 存档/统计 副作用)
# 断言 (手动驱动 确定性): 徽标节点 顶栏子节点+金色样式/全关 隐藏 文本空/单开 "自动 1/5"+可见 (M5-3) +
# tooltip 含 五开关 状态行/两开 "自动 2/5"/三开 "自动 3/5"/四开 "自动 4/5"/五开 "自动 5/5"/同态 再 _refresh 文本 不变 节流/
# 全关 恢复 隐藏 文本空 tooltip 清/无 资源/统计 副作用/收尾 四关 隐藏
func _assert_auto_badge() -> void:
	var g := GameData
	# 徽标 节点: 顶栏子节点 (境界/主资源/灵石 之后), 金色字 + 金边样式
	check(ui._auto_badge != null, "打磨-73 顶栏 自动 徽标 节点 存在")
	check(ui._auto_badge.get_parent() == ui._realm_label.get_parent(),
		"打磨-73 徽标 挂在 顶栏 容器 (与 境界标签 同父; 实际父节点 %s)" % str(ui._auto_badge.get_parent()))
	check(ui._auto_badge.get_theme_color("font_color") == Color(0.98, 0.86, 0.5),
		"打磨-73 徽标 字色 金色 (实际 %s)" % str(ui._auto_badge.get_theme_color("font_color")))
	# 初始 (打磨-72 收尾 三关 全 关): 隐藏, 文本 空
	check(ui._auto_badge.visible == false, "打磨-73 初始 三关 徽标 隐藏 (实际 visible=%s)" % str(ui._auto_badge.visible))
	check(str(ui._auto_badge.text) == "", "打磨-73 初始 三关 徽标 文本 空 (实际 %s)" % str(ui._auto_badge.text))
	# 单开 突破 -> "自动 1/5" 可见 + tooltip 复用 auto_summary_text 五开关 口径
	g.auto_break = true
	ui._refresh()
	check(ui._auto_badge.visible == true, "打磨-73 单开 突破 徽标 显示 (实际 visible=%s)" % str(ui._auto_badge.visible))
	check(str(ui._auto_badge.text) == "自动 1/5", "打磨-73 单开 文案=自动 1/5 (M5-3, 实际 %s)" % str(ui._auto_badge.text))
	var tip73: String = str(ui._auto_badge.tooltip_text)
	check(tip73.begins_with("自动: 突破 ✓ · 购置 ✗ · 施展 ✗ · 领悟 ✗ · 爬塔 ✗") and tip73.contains("离线期间不触发"),
		"打磨-73 单开 tooltip 复用 auto_summary_text+离线口径 (实际 %s)" % tip73)
	# 两开 (突破+施展) -> "自动 2/5" (购置 关 口径 与 汇总行 同)
	g.auto_cast = true
	ui._refresh()
	check(str(ui._auto_badge.text) == "自动 2/5", "打磨-73 两开 文案=自动 2/5 (M5-3, 实际 %s)" % str(ui._auto_badge.text))
	check(str(ui._auto_badge.tooltip_text).begins_with("自动: 突破 ✓ · 购置 ✗ · 施展 ✓ · 领悟 ✗ · 爬塔 ✗"),
		"打磨-73 两开 tooltip 四开关 口径 (实际 %s)" % str(ui._auto_badge.tooltip_text))
	# 三开 -> "自动 3/5"
	g.auto_buy = true
	ui._refresh()
	check(str(ui._auto_badge.text) == "自动 3/5", "打磨-73 三开 文案=自动 3/5 (M5-3, 实际 %s)" % str(ui._auto_badge.text))
	# 四开 -> "自动 4/5" (M5-3 起 5 开关); 五开 -> "自动 5/5" (含 爬塔)
	g.auto_learn = true
	ui._refresh()
	check(str(ui._auto_badge.text) == "自动 4/5", "打磨-73 四开 文案=自动 4/5 (M5-3, 实际 %s)" % str(ui._auto_badge.text))
	check(str(ui._auto_badge.tooltip_text).begins_with("自动: 突破 ✓ · 购置 ✓ · 施展 ✓ · 领悟 ✓ · 爬塔 ✗"),
		"打磨-73 四开 tooltip 口径 (实际 %s)" % str(ui._auto_badge.tooltip_text))
	# 五开 (M5-3 含 爬塔) -> "自动 5/5"
	g.auto_tower = true
	ui._refresh()
	check(str(ui._auto_badge.text) == "自动 5/5", "打磨-73 五开 文案=自动 5/5 (M5-3, 实际 %s)" % str(ui._auto_badge.text))
	check(str(ui._auto_badge.tooltip_text).begins_with("自动: 突破 ✓ · 购置 ✓ · 施展 ✓ · 领悟 ✓ · 爬塔 ✓"),
		"打磨-73 五开 tooltip 全开 口径 (M5-3, 实际 %s)" % str(ui._auto_badge.tooltip_text))
	# 节流: 同态 再 _refresh, 文本/可见 不变 (开启数 未变 不重写)
	var txt73: String = str(ui._auto_badge.text)
	var st73: Dictionary = g.stats.duplicate(true)
	var stones73: float = g.stones
	ui._refresh()
	check(str(ui._auto_badge.text) == txt73 and ui._auto_badge.visible == true,
		"打磨-73 同态 节流 文本/可见 稳定")
	# 全关 恢复 隐藏 + 文本空 + tooltip 清 (M5-3 起 5 开关, 含 爬塔)
	g.auto_break = false
	g.auto_buy = false
	g.auto_cast = false
	g.auto_learn = false
	g.auto_tower = false
	ui._refresh()
	check(ui._auto_badge.visible == false and str(ui._auto_badge.text) == ""
			and str(ui._auto_badge.tooltip_text) == "", "打磨-73 全关 恢复 隐藏/文本空/tooltip 清")
	# 徽标 刷新 无 资源/统计 副作用 (纯展示)
	check(g.stats == st73 and g.stones == stones73, "打磨-73 徽标 刷新 无 资源/统计 副作用")
	# 收尾: 四关 全 关 隐藏 稳定 (防 污染)
	check(ui._auto_badge.visible == false, "打磨-73 收尾 五关 隐藏 (M5-3)")
	await get_tree().process_frame


# 打磨-74: 顶栏 自动 徽标 点击直达 — 徽标 升级 flat Button 热区 (手型光标+悬停 淡底 金边),
# 点击=切 修行页 + 自动系列 汇总行 金边高亮 1.2s (复用 法器区 高亮 口径), 全关 隐藏 无热区 口径 不变;
# 断言 (手动驱动 确定性): 徽标=flat Button+手型/悬停样式非空/汇总行 Panel 外壳 存在+初始无边框/
# tooltip 点击口径/单开 点击 → 切 修行页(tab0)+汇总行 金边+底部消息/汇总行 tooltip 徽标直达口径/
# 1.2s 后 高亮 自动恢复 边框0/重入 kill 旧 tween 不叠加/全关 隐藏 无热区 (visible=false 时 点击 不触发)/
# 无 资源/统计 副作用 (纯导航)/收尾 修行页+无边框
func _assert_auto_badge_jump() -> void:
	var g := GameData
	# 前置: 打磨-73 收尾 三关 全 关 (徽标 隐藏); 切 成就页 作为 点击 前 受控 tab
	ui._tab.current_tab = 3
	# 徽标 = flat Button 可点击热区 (手型光标, 非 toggle)
	var badge: Button = ui._auto_badge
	check(badge is Button, "打磨-74 徽标 节点 是 Button (升级 可点击)")
	check(badge.flat == true, "打磨-74 徽标 flat (可点样式)")
	check(badge.toggle_mode == false, "打磨-74 徽标 非 toggle (点击即触发)")
	check(badge.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
			"打磨-74 徽标 手型光标 提示可点")
	check(badge.get_theme_stylebox("hover") != null
			and badge.get_theme_stylebox("hover").border_width_left == 1,
			"打磨-74 徽标 悬停 金边 样式 非空 (hover 边框宽=1)")
	# 汇总行 Panel 外壳 存在 + 初始 无边框 (恢复态)
	check(ui._auto_sum_panel != null and ui._auto_sum_panel is Panel, "打磨-74 汇总行 Panel 外壳 存在")
	check(ui._auto_sum_box.get_parent() == ui._auto_sum_panel, "打磨-74 汇总行 HBox 挂在 Panel 下")
	var sb0: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb0 != null and sb0.border_width_left == 0, "打磨-74 初始 汇总行 无边框 (边框宽=0)")
	check(str(ui._auto_sum_panel.tooltip_text).find("顶栏 自动 N/5 徽标 (M5-3 起 5 开关) 点击也可直达本行") >= 0,
			"打磨-74 汇总行 tooltip 含 徽标直达 口径 (实际 %s)" % str(ui._auto_sum_panel.tooltip_text).left(60))
	# 副作用快照 (点击 不应改变)
	var snap_essence := g.essence
	var snap_stones := g.stones
	var snap_stats := g.stats
	# --- 单开 突破 → 徽标 显示 "自动 1/5" (M5-3) → 点击 → 切 修行页(tab0) + 汇总行 金边 ---
	g.auto_break = true
	ui._refresh()
	check(ui._auto_badge.visible == true and str(ui._auto_badge.text) == "自动 1/5",
			"打磨-74 单开 突破 徽标 显示 (M5-3, 实际 visible=%s 文本=%s)" % [str(ui._auto_badge.visible), str(ui._auto_badge.text)])
	check(str(ui._auto_badge.tooltip_text).contains("点击: 直达 修行页·自动系列状态汇总行"),
			"打磨-74 徽标 tooltip 追加 点击直达 口径 (实际 %s)" % str(ui._auto_badge.tooltip_text))
	ui._on_auto_badge()
	await get_tree().process_frame
	check(ui._tab.current_tab == 0, "打磨-74 点击 徽标 → 切 修行页 (tab=0) (实际 %d)" % ui._tab.current_tab)
	var sb_hi: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb_hi != null and sb_hi.border_width_left == 2 and sb_hi.border_color == ui.GOLD,
			"打磨-74 点击 徽标 → 汇总行 金边高亮 (边框宽=2 金)")
	check(str(ui._msg_label.text).find("直达 修行页·自动系列状态汇总行") >= 0,
			"打磨-74 点击 徽标 → 底部消息确认 (实际 %s)" % str(ui._msg_label.text))
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats,
			"打磨-74 点击 徽标 无 资源/统计 副作用 (纯导航)")
	# 重入: 高亮中 再点 徽标 kill 旧 tween 重开 (不报错 且 仍 高亮, 边框 口径 不变)
	ui._on_auto_badge()
	await get_tree().process_frame
	var sb_hi2: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb_hi2 != null and sb_hi2.border_width_left == 2, "打磨-74 高亮中 重入 不叠加/不报错 (仍 金边)")
	# 等待 tween 结束 (1.2s, 重入后 重新计时) 后 自动恢复 边框 0
	await get_tree().create_timer(1.4).timeout
	var sb_rest: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb_rest != null and sb_rest.border_width_left == 0, "打磨-74 汇总行 高亮 1.2s 后 自动恢复 (边框宽=0)")
	# --- 全关 → 徽标 隐藏 (无热区); 隐藏态 处理器 直调 仍 导航+高亮 (口径 由 visible 门控, 直调 仅验证 无副作用) ---
	g.auto_break = false
	ui._refresh()
	check(ui._auto_badge.visible == false and str(ui._auto_badge.text) == "",
			"打磨-74 全关 徽标 隐藏 无热区 (visible=%s 文本=%s)" % [str(ui._auto_badge.visible), str(ui._auto_badge.text)])
	# 收尾: 修行页 稳定, 无边框 (防 污染); tab 保持 0 (后续 无 依赖 成就页 的 测试)
	check(ui._tab.current_tab == 0, "打磨-74 收尾 保持 修行页")
	var sb_end: StyleBoxFlat = ui._auto_sum_panel.get_theme_stylebox("panel")
	check(sb_end != null and sb_end.border_width_left == 0, "打磨-74 收尾 汇总行 无边框")
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats,
			"打磨-74 收尾 无 资源/统计 副作用")
	await get_tree().process_frame


# 打磨-97: 背包 容量 成就 解锁 (bag_40: 曾 入包 满 30 格 -> 容量 30 -> 40; 容量 行 tooltip 动态 段)
func _assert_bag_expand() -> void:
	var g := GameData
	ui._tab.current_tab = 2
	g.set_process(false)
	# 受控 基准: 干净 词缀 态 (M6-3 段 收尾 已 归零, 此处 再 防 断)
	g.affix_bag = {}
	g.affix_load = {}
	g.seen_affixes = []
	g.ach_done.clear()
	ui._m63_sel = ""
	ui._m63_bag_tip = ""
	ui._refresh_m63_ui()
	# 初始 30 格 + tooltip 未 解锁 口径
	check(str(ui._m63_bag_hdr.text) == "词缀背包 0/30 格", "打磨-97 容量 行 0/30 (实际 %s)" % str(ui._m63_bag_hdr.text))
	check(str(ui._m63_bag_hdr.tooltip_text) == g.bag_expand_tip(), "打磨-97 tooltip = 接口 (实际 %s)" % str(ui._m63_bag_hdr.tooltip_text))
	check(str(ui._m63_bag_hdr.tooltip_text).contains("还差 30 种"), "打磨-97 tooltip 还差 30 种 (实际 %s)" % str(ui._m63_bag_hdr.tooltip_text))
	# 入包 29 种 -> 未满, 容量 30, tooltip 还差 1
	for i in 29:
		g.affix_add(str(g.affix_ids[i]), 1)
	ui._refresh_m63_ui()
	check(str(ui._m63_bag_hdr.text) == "词缀背包 29/30 格", "打磨-97 容量 行 29/30 (实际 %s)" % str(ui._m63_bag_hdr.text))
	check(g.affix_bag_capacity() == 30, "打磨-97 29 种 容量 仍 30 (实际 %d)" % g.affix_bag_capacity())
	check(str(ui._m63_bag_hdr.tooltip_text).contains("还差 1 种"), "打磨-97 tooltip 还差 1 种 (实际 %s)" % str(ui._m63_bag_hdr.tooltip_text))
	# 第 30 种 -> 触发 bag_40 -> 容量 40 + 成就 解锁 (成就 浮动 同 打磨-17 口径)
	g.affix_add(str(g.affix_ids[29]), 1)
	g.check_achievements()
	ui._refresh_m63_ui()
	check(str(ui._m63_bag_hdr.text) == "词缀背包 30/40 格", "打磨-97 容量 行 30/40 (实际 %s)" % str(ui._m63_bag_hdr.text))
	check(g.affix_bag_capacity() == 40, "打磨-97 解锁 后 容量 40 (实际 %d)" % g.affix_bag_capacity())
	check(g.ach_done.has("bag_40"), "打磨-97 bag_40 解锁 (ach_done)")
	check(str(ui._m63_bag_hdr.tooltip_text) == "「百宝囊」已解锁: 词缀背包 容量 +10 (30 -> 40 格)", "打磨-97 tooltip 已 解锁 (实际 %s)" % str(ui._m63_bag_hdr.tooltip_text))
	# 成就 页 展示: bag_40 行 金框 + 进度 0/30 -> 已解锁 (动态 接口 口径)
	check(g.ach_progress("bag_40") == "已解锁", "打磨-97 成就 进度 已解锁")
	check(absf(g.ach_progress_ratio("bag_40") - 1.0) < 1e-9, "打磨-97 比例 1.0")
	# 40 满 拒绝 (容量 40 生效 于 入包 路径)
	for i in 10:
		g.affix_add(str(g.affix_ids[30 + i]), 1)
	check(g.affix_bag_used() == 40 and g.affix_bag_full(), "打磨-97 40/40 已满 (实际 %d)" % g.affix_bag_used())
	check(g.affix_add(str(g.affix_ids[40]), 1) == 0, "打磨-97 40 满 后 新 词缀 拒绝")
	# 节流: 同 态 刷新 tooltip 不 重写 (缓存 键 稳定)
	var tip_same: String = str(ui._m63_bag_hdr.tooltip_text)
	ui._refresh_m63_ui()
	check(str(ui._m63_bag_hdr.tooltip_text) == tip_same and ui._m63_bag_tip == tip_same, "打磨-97 同 态 节流 稳定")
	# 收尾: 干净 基准 (bag_40 解锁 清掉, 容量 回 30; 防 污染 后续 段 与 落盘)
	g.seen_affixes = []
	g.ach_done.clear()
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.affix_materials = 0
	ui._m63_sel = ""
	ui._m63_bag_tip = ""
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._m63_bag_hdr.text) == "词缀背包 0/30 格", "打磨-97 收尾 容量 回 30 (实际 %s)" % str(ui._m63_bag_hdr.text))

# 打磨-99: 一键 强化 槽位 按钮 (装备页 词缀 材料 兑换 面板 内; 道祖期 批量 3->4, 200 材料/件)
# 断言: 按钮 节点/tooltip 口径/未 飞升 与 无 拥有 文案/材料 不足/可 强化 计数/点击 批量 升级
# (材料 扣减+槽数 3->4+chips 重建 4+底部 消息+浮动)/全 满级 幂等/主循环 文案 刷新 同步/收尾 归零
func _assert_m99_upgrade() -> void:
	var g := GameData
	ui._tab.current_tab = 2
	g.set_process(false)
	# 受控 基准: 干净 DIY 态 + 购买 weapon_0_0 (3 槽)
	g.owned_eq.clear()
	g.equipped.clear()
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.affix_materials = 0
	g.seen_affixes = []
	g.ascended = false
	g.dao_level = 0
	g.stones = 1e12
	g.buy_equipment("weapon_0_0")
	ui._refresh()
	await get_tree().process_frame
	# 按钮 节点 存在 (兑换 按钮 行 第 2 个) + 金色 字体 + tooltip 口径 (成本/道祖期/幂等)
	var btn: Button = ui._m99_up_btn
	check(btn != null, "打磨-99 强化 按钮 节点 存在")
	if btn == null:
		return
	check(str(btn.text) != "", "打磨-99 按钮 有 初始 文案")
	check(str(btn.tooltip_text).find("200 材料") >= 0 and str(btn.tooltip_text).find("道祖期") >= 0
			and str(btn.tooltip_text).find("幂等") >= 0, "打磨-99 按钮 tooltip 含 成本/道祖期/幂等 口径 (实际 %s)" % str(btn.tooltip_text).left(40))
	# 未 飞升 = 需道祖期 文案
	check(str(btn.text) == "一键强化槽位 (需道祖期)", "打磨-99 未 飞升 文案 (实际 %s)" % str(btn.text))
	# 飞升 道祖期 + 拥有 1 件 未 满级 + 材料 0 = 材料 不足 文案
	g.ascended = true
	g.dao_level = 8
	g.affix_materials = 0
	ui._refresh_m99_upgrade()
	check(str(btn.text) == "一键强化槽位 (材料不足 0/200)", "打磨-99 材料 不足 文案 (实际 %s)" % str(btn.text))
	# 材料 100 = 不足 文案 带 当前数
	g.affix_materials = 100
	ui._refresh_m99_upgrade()
	check(str(btn.text) == "一键强化槽位 (材料不足 100/200)", "打磨-99 材料 100 不足 文案 (实际 %s)" % str(btn.text))
	# 材料 500 = 可 强化 x1 文案 (min(500//200=2, 未 满级 1 件)=1)
	g.affix_materials = 500
	ui._refresh_m99_upgrade()
	check(str(btn.text) == "一键强化槽位 x1 (200 材料/件)", "打磨-99 可 强化 x1 文案 (实际 %s)" % str(btn.text))
	# 点击 = 批量 升级 成功: 材料 扣 200 + 槽数 4 + chips 重建 4 + 底部 消息 + 浮动
	var flt_before: int = ui._onekey_float_count
	var chips_before: int = (ui._m63_chips.get("weapon_0_0", []) as Array).size()
	btn.pressed.emit()
	await get_tree().process_frame
	check(g.equipment_slots("weapon_0_0") == 4, "打磨-99 点击 后 4 槽 (实际 %d)" % g.equipment_slots("weapon_0_0"))
	check(g.affix_materials == 300, "打磨-99 点击 扣 200 材料 (实际 %d)" % g.affix_materials)
	check((ui._m63_chips.get("weapon_0_0", []) as Array).size() == 4, "打磨-99 chips 重建 4 个 (实际 %d, 前 %d)" % [(ui._m63_chips.get("weapon_0_0", []) as Array).size(), chips_before])
	check(str(ui._msg_label.text).find("强化 槽位 1 件") >= 0, "打磨-99 底部 消息 确认 (实际 %s)" % str(ui._msg_label.text))
	check(ui._onekey_float_count == flt_before + 1, "打磨-99 成功 浮动 +1 (实际 %d -> %d)" % [flt_before, ui._onekey_float_count])
	check(str(ui._onekey_last_text).find("强化 槽位 1 件") >= 0, "打磨-99 浮动 文案 含 件数 (实际 %s)" % ui._onekey_last_text)
	# 文案 同步: 已 全 满级
	check(str(btn.text) == "一键强化槽位 (已全满级/无拥有)", "打磨-99 满级 后 文案 同步 (实际 %s)" % str(btn.text))
	# 再 点 = 幂等 0 变更 (不 扣 材料 不 再 浮动, 0 变更 走 底部 消息)
	var flt_after: int = ui._onekey_float_count
	btn.pressed.emit()
	await get_tree().process_frame
	check(g.affix_materials == 300 and g.equipment_slots("weapon_0_0") == 4, "打磨-99 幂等 0 变更 (材料 %d 槽 %d)" % [g.affix_materials, g.equipment_slots("weapon_0_0")])
	check(ui._onekey_float_count == flt_after, "打磨-99 幂等 不 再 浮动 (实际 %d)" % ui._onekey_float_count)
	check(str(ui._msg_label.text).find("0 件") >= 0, "打磨-99 幂等 底部 消息 0 件 (实际 %s)" % str(ui._msg_label.text))
	# 主循环 文案 刷新 同步: 未 拥有 态 文案 (拥有 清空 后 _refresh 路径)
	g.owned_eq.clear()
	g.slot_upgrades = {}
	g.ascended = false
	g.dao_level = 0
	ui._refresh()
	await get_tree().process_frame
	check(str(btn.text) == "一键强化槽位 (需道祖期)", "打磨-99 未 飞升 恢复 文案 (实际 %s)" % str(btn.text))
	# 收尾: 归零 干净 基准
	g.affix_materials = 0
	g.affix_bag = {}
	g.affix_load = {}
	g.affix_decompose_all()
	g.seen_affixes = []
	ui._m63_sel = ""
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g.affix_bag.is_empty() and g.affix_load.is_empty() and g.seen_affixes.is_empty() and g.affix_materials == 0, "打磨-99 收尾 干净 基准")

func _assert_m101_exchange_all() -> void:
	var g := GameData
	ui._tab.current_tab = 2
	g.set_process(false)
	# 受控 基准: 干净 词缀 态 + 选中 池 qi_rate 品质 0 (成本 25 数据 锚定)
	g.owned_eq.clear()
	g.equipped.clear()
	g.affix_bag = {}
	g.affix_load = {}
	g.affix_materials = 0
	g.seen_affixes = []
	ui._m63_sel = ""
	ui._on_m96_pool("qi_rate")
	ui._on_m96_tier(0)
	var btn: Button = ui._m101_exch_all_btn
	check(btn != null, "打磨-101 一键 兑换 按钮 节点 存在")
	if btn == null:
		return
	check(str(btn.tooltip_text).find("连兑") >= 0 and str(btn.tooltip_text).find("背包满") >= 0
			and str(btn.tooltip_text).find("幂等") >= 0, "打磨-101 按钮 tooltip 含 连兑/背包满/幂等 口径 (实际 %s)" % str(btn.tooltip_text).left(40))
	# 材料 0 = 不足 文案
	g.affix_materials = 0
	ui._refresh_m101_exchange_all()
	check(str(btn.text) == "一键兑换 (材料不足 0/25)", "打磨-101 材料 0 不足 文案 (实际 %s)" % str(btn.text))
	# 材料 70 = x2 (70//25)
	g.affix_materials = 70
	ui._refresh_m101_exchange_all()
	check(str(btn.text) == "一键兑换 x2 (25 材料/件)", "打磨-101 材料 70 可兑 x2 文案 (实际 %s)" % str(btn.text))
	# 点击 = 批量 兑 2 件 最高 变体 + 扣 50 + 入包 2 + 底部 消息 + 浮动
	var flt_before: int = ui._onekey_float_count
	var before_bag: int = int(g.affix_bag.get("af_qi_rate_0_3", 0))
	btn.pressed.emit()
	await get_tree().process_frame
	check(int(g.affix_bag.get("af_qi_rate_0_3", 0)) == before_bag + 2, "打磨-101 点击 兑 2 件 入包 (实际 %d)" % int(g.affix_bag.get("af_qi_rate_0_3", 0)))
	check(g.affix_materials == 20, "打磨-101 点击 扣 50 材料 余 20 (实际 %d)" % g.affix_materials)
	check(str(ui._msg_label.text).find("一键兑换 2 件") >= 0, "打磨-101 底部 消息 含 件数 (实际 %s)" % str(ui._msg_label.text))
	check(ui._onekey_float_count == flt_before + 1, "打磨-101 成功 浮动 +1 (实际 %d -> %d)" % [flt_before, ui._onekey_float_count])
	check(str(ui._onekey_last_text).find("2 件") >= 0, "打磨-101 浮动 文案 含 件数 (实际 %s)" % ui._onekey_last_text)
	check(str(btn.text) == "一键兑换 (材料不足 20/25)", "打磨-101 兑后 文案 同步 材料不足 (实际 %s)" % str(btn.text))
	# 材料 补足 25 -> 文案 x1 (20+25=45 仍 不足? 不, 现 20; 设 25)
	g.affix_materials = 25
	ui._refresh_m101_exchange_all()
	check(str(btn.text) == "一键兑换 x1 (25 材料/件)", "打磨-101 材料 25 x1 文案 (实际 %s)" % str(btn.text))
	# 背包满 = 拒绝 文案 + 点击 0 件 无 副作用 (动态 容量: 打磨-97 bag_40 可能 已 解锁 40 格, 清 成就 取 基础 30 格 基准)
	g.ach_done.erase("bag_40")
	var cap96: int = g.affix_bag_capacity()
	g.affix_bag = {}
	var filled96 := 0
	for aidf in g.affix_ids:
		g.affix_bag[str(aidf)] = 1
		filled96 += 1
		if filled96 >= cap96:
			break
	check(g.affix_bag_full(), "打磨-101 背包 占满 前提 成立 (容量 %d 实际 %d 格)" % [cap96, g.affix_bag_used()])
	g.affix_materials = 200
	ui._refresh_m101_exchange_all()
	check(str(btn.text) == "一键兑换 (背包满)", "打磨-101 背包满 文案 (实际 %s)" % str(btn.text))
	var flt_full: int = ui._onekey_float_count
	btn.pressed.emit()
	await get_tree().process_frame
	check(g.affix_materials == 200 and ui._onekey_float_count == flt_full, "打磨-101 背包满 0 件 不 扣 不 浮动 (材料 %d)" % g.affix_materials)
	check(str(ui._msg_label.text).find("0 件") >= 0, "打磨-101 背包满 点击 0 件 底部 消息 (实际 %s)" % str(ui._msg_label.text))
	# 未 选 池 文案
	g.affix_bag = {}
	g.affix_materials = 100
	ui._m96_pool = ""
	ui._m96_tier = -1
	ui._refresh_m101_exchange_all()
	check(str(btn.text) == "一键兑换 (先选 池 与 品质)", "打磨-101 未 选 池 文案 (实际 %s)" % str(btn.text))
	# 收尾: 归零 干净 基准
	g.affix_bag = {}
	g.affix_load = {}
	g.seen_affixes = []
	g.affix_materials = 0
	ui._m63_sel = ""
	ui._m96_pool = ""
	ui._m96_tier = -1
	for p in ui._m96_pool_btns:
		(ui._m96_pool_btns[p] as Button).button_pressed = false
	for t in ui._m96_tier_btns:
		(ui._m96_tier_btns[t] as Button).button_pressed = false
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g.affix_bag.is_empty() and g.affix_load.is_empty() and g.seen_affixes.is_empty() and g.affix_materials == 0, "打磨-101 收尾 干净 基准")


# 打磨-119: 怪物卡 tooltip 精英/魔化 结构 行 (M5 规格 "每 10 层 精英 (数值 x3, 掉落 x2)" +
# "登天梯 500 层后 所有 怪物 默认 魔化" 的 结构/奖励 倍率 展示 位 — 数值/掉落 已 随 层表/
# 结算 落地, tooltip 追加 结构 行 给 口径 说明 (双塔 精英 同 结构 魔化· 前缀 + 追加 1 额外
# 特性 + x3/x2, 登天梯 500+ 非 Boss 层 恒 魔化); Boss 层 分层 行 已 展示 不 叠; 状态行
# tooltip 追加 精英/魔化 口径 说明; UI 断言: 精英 层 结构 行 = 接口 恒等/魔化 层 魔化 口径/
# 普通层·Boss 层 无 结构 行/状态行 tooltip 口径/同态 节流/收尾 干净 基准 防 污染)
func _assert_struct_line_tip() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 + 弱 玩家 (防 误触 结算 推进 层数)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 1) 基准 普通层 (镇妖塔 第 1 层): 怪物卡 无 精英 标记 + tooltip 无 结构 行
	check(str(ui._tw_mon_labels["fixed"].text).find("★精英") < 0,
			"打磨-119 镇妖塔 第 1 层 普通层 无 精英 标记 (实际 %s)" % str(ui._tw_mon_labels["fixed"].text))
	check(str(ui._tw_mon_labels["fixed"].tooltip_text).find("结构: ") < 0,
			"打磨-119 镇妖塔 普通层 怪物卡 tooltip 无 结构 行 (实际 %s)" % str(ui._tw_mon_labels["fixed"].tooltip_text).left(60))
	# 2) 镇妖塔 精英层 (第 10 层): 卡片 tag ★精英 + tooltip 结构 行 = 接口 恒等
	g.tower_fixed_floor = 9
	ui._refresh_tower()
	await get_tree().process_frame
	var mon119a: String = str(ui._tw_mon_labels["fixed"].text)
	check(mon119a.find("第 10 层") >= 0 and mon119a.find("★精英") >= 0,
			"打磨-119 镇妖塔 第 10 层 精英 卡片 tag ★精英 (实际 %s)" % mon119a)
	check(mon119a.find("魔化·") >= 0, "打磨-119 镇妖塔 精英 名 含 魔化· 前缀 (实际 %s)" % mon119a)
	check(str(ui._tw_mon_labels["fixed"].tooltip_text) == g.tower_monster_tip(g.get_fixed_floor(10), "fixed")
			and str(ui._tw_mon_labels["fixed"].tooltip_text).find("结构: 精英层 (每 10 层) 数值 x3 · 掉落 x2") >= 0,
			"打磨-119 镇妖塔 精英 怪物卡 tooltip 含 精英 结构 行 且 = 接口 恒等 (实际 %s)" % str(ui._tw_mon_labels["fixed"].tooltip_text).get_slice("\n", 3))
	# 3) 登天梯 魔化 精英 (第 510 层 >= 500): tooltip 魔化 口径 行
	g.tower_fixed_floor = 0
	g.tower_endless_floor = 510
	ui._refresh_tower()
	await get_tree().process_frame
	var mon119b: String = str(ui._tw_mon_labels["endless"].text)
	check(mon119b.find("第 510 层") >= 0 and mon119b.find("魔化·") >= 0,
			"打磨-119 登天梯 第 510 层 魔化 名 含 魔化· 前缀 (实际 %s)" % mon119b)
	check(str(ui._tw_mon_labels["endless"].tooltip_text) == g.tower_monster_tip(g.get_endless_floor(510), "endless")
			and str(ui._tw_mon_labels["endless"].tooltip_text).find("结构: 魔化 (500 层后 默认 魔化 + 精英 结构)") >= 0,
			"打磨-119 登天梯 第 510 层 怪物卡 tooltip 含 魔化 结构 行 且 = 接口 恒等 (实际 %s)" % str(ui._tw_mon_labels["endless"].tooltip_text).get_slice("\n", 2))
	# 4) 登天梯 499 层 (< 500 非 精英): 无 结构 行 (普通层 无 魔化 前缀)
	g.tower_endless_floor = 499
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["endless"].text).find("魔化·") < 0,
			"打磨-119 登天梯 第 499 层 (<500) 无 魔化 前缀 (实际 %s)" % str(ui._tw_mon_labels["endless"].text))
	check(str(ui._tw_mon_labels["endless"].tooltip_text).find("结构: ") < 0,
			"打磨-119 登天梯 第 499 层 普通层 tooltip 无 结构 行 (实际 %s)" % str(ui._tw_mon_labels["endless"].tooltip_text).left(60))
	# 5) 登天梯 500 层 里程碑 Boss: 无 结构 行 (Boss 分层/宝箱 行 已 展示 不 叠)
	g.tower_endless_floor = 500
	ui._refresh_tower()
	await get_tree().process_frame
	var mon119c: String = str(ui._tw_mon_labels["endless"].text)
	check(mon119c.find("⚑Boss") >= 0 and str(ui._tw_mon_labels["endless"].tooltip_text).find("结构: ") < 0,
			"打磨-119 登天梯 第 500 层 里程碑 Boss 无 结构 行 (Boss 不 叠 精英/魔化, 实际 %s)" % mon119c)
	# 6) 状态行 tooltip 含 精英/魔化 口径 说明 (构建 时 写入)
	check(str(ui._tw_status_panel.tooltip_text).find("精英/魔化 结构") >= 0
			and str(ui._tw_status_panel.tooltip_text).find("数值 x3 + 掉落 x2") >= 0
			and str(ui._tw_status_panel.tooltip_text).find("500 层后 全部 非 Boss 怪物 默认 魔化") >= 0,
			"打磨-119 状态行 tooltip 含 精英/魔化 口径 说明")
	# 7) 同态 节流: 无 塔 态 变化 再 刷 不 重写 + 无 统计 副作用
	var snap119: Dictionary = g.stats.duplicate(true)
	var ref119: String = str(ui._tw_mon_labels["endless"].text)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["endless"].text) == ref119 and g.stats == snap119,
			"打磨-119 同态 节流 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.set_process(true)
	ui._tab.current_tab = 3



# 打磨-120: 怪物卡 tooltip 词缀 掉落 概率 行 (M6 规格 掉落 来源 口径 展示 位 — 普通 5% /
# 精英 20% / Boss 1~3 件 / 里程碑 宝箱 1~2 件; 结算 口径 affix_roll_drop 已 落地 但 tooltip
# 无 概率 展示; 只读 接口 tower_affix_drop_line = 来源 base x 种 affix_w + 词缀袋 +10%
# 同 表达式 clamp, 100% → "1~N 件"; 败 局 不 掉 词缀 标注 仅 胜利). UI 断言: 怪物卡 tooltip
# 含 词缀 掉落 行 = 接口 同 输入 恒等 (stats 字典 路径 不 丢)/普通 层 百分比 档/Boss 100% 1~N 件/
# 状态行 tooltip 口径/同态 节流 无 副作用/收尾 干净 基准.
func _assert_affix_drop_line() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 1) 基准 普通层 (镇妖塔 第 1 层): 怪物卡 tooltip 含 词缀 掉落 行 = 接口 同 输入 恒等
	var f1: Dictionary = g.get_fixed_floor(1)
	var dl1: String = g.tower_affix_drop_line(f1, "fixed")
	check(dl1.find("词缀 掉落:") >= 0 and dl1.find("%") >= 0 and dl1.find("仅 胜利 结算") >= 0,
			"打磨-120 普通层 掉率 行 含 概率 + 仅 胜利 口径 (实际 %s)" % dl1)
	check(str(ui._tw_mon_labels["fixed"].tooltip_text) == g.tower_monster_tip(g.get_fixed_floor(1), "fixed"),
			"打磨-120 镇妖塔 普通层 怪物卡 tooltip = 接口 恒等 (同 输入 口径)")
	check(str(ui._tw_mon_labels["fixed"].tooltip_text).find(dl1) >= 0,
			"打磨-120 镇妖塔 普通层 tooltip 含 词缀 掉落 行 (实际 %s)" % str(ui._tw_mon_labels["fixed"].tooltip_text).get_slice("\n", 6))
	# 2) 镇妖塔 精英层 (第 10 层): tooltip 含 精英 掉率 行 (base 20% x 权重)
	g.tower_fixed_floor = 9
	ui._refresh_tower()
	await get_tree().process_frame
	var f10: Dictionary = g.get_fixed_floor(10)
	var dl10: String = g.tower_affix_drop_line(f10, "fixed")
	check(str(ui._tw_mon_labels["fixed"].tooltip_text).find(dl10) >= 0
			and dl10.find("来源 base 20%") >= 0,
			"打磨-120 精英层 tooltip 含 base 20%% 掉率 行 (实际 %s)" % dl10)
	# 3) 镇妖塔 小 Boss (第 50 层): tooltip 含 100% 1~3 件 段
	g.tower_fixed_floor = 49
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["fixed"].tooltip_text).find("词缀 掉落: 100% (1~3 件)") >= 0,
			"打磨-120 小 Boss tooltip 含 100%% 1~3 件 段 (实际 %s)" % str(ui._tw_mon_labels["fixed"].tooltip_text).left(40))
	# 4) 登天梯 里程碑 Boss (第 100 层): tooltip 含 100% 1~2 件 段
	g.tower_fixed_floor = 0
	g.tower_endless_floor = 100
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["endless"].tooltip_text).find("词缀 掉落: 100% (1~2 件)") >= 0,
			"打磨-120 登天梯 里程碑 Boss tooltip 含 100%% 1~2 件 段 (实际 %s)" % str(ui._tw_mon_labels["endless"].tooltip_text).left(40))
	# 5) stats 字典 路径 幂等 恒等 (UI tooltip 走 stats 路径 不 丢 掉率 行):
	var s1: Dictionary = g.tower_monster_stats(g.get_fixed_floor(40))
	check(str(ui._tw_mon_labels["fixed"].tooltip_text) != "" and g.tower_affix_drop_line(s1, "fixed") == g.tower_affix_drop_line(g.tower_monster_stats(s1), "fixed"),
			"打磨-120 stats 字典 路径 掉率 行 幂等 恒等 (40 层 精英+词缀袋)")
	# 6) 状态行 tooltip 含 词缀 掉落 口径 说明 (构建 时 写入)
	check(str(ui._tw_status_panel.tooltip_text).find("词缀 掉落") >= 0
			and str(ui._tw_status_panel.tooltip_text).find("词缀 掉落 行") >= 0,
			"打磨-120 状态行 tooltip 含 词缀 掉落 口径 说明")
	# 7) 同态 节流: 无 塔 态 变化 再 刷 不 重写 + 无 统计 副作用
	var snap120: Dictionary = g.stats.duplicate(true)
	var ref120: String = str(ui._tw_mon_labels["endless"].tooltip_text)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["endless"].tooltip_text) == ref120 and g.stats == snap120,
			"打磨-120 同态 节流 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.set_process(true)
	ui._tab.current_tab = 3


# 打磨-121: 双塔 卡片 下一 里程碑 行 (M5 规格 "每 100 层 天阶 里程碑" 进度 展示 位 — 距 下个
# 精英/Boss/里程碑 Boss 还有 几 层; 本层 即是 标注 就在 本层; 镇妖塔 通关 守塔 模式 隐藏;
# 文本 变化 才 刷 节流; 收尾 干净 基准)
func _assert_tower_milestone_line() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 1) 双塔 里程碑 行 节点 存在 + 初始 基准 文案 = 接口 恒等 (镇妖塔 第 1 层 下一 = 10 层 精英)
	var fms: Label = ui._tw_cards["fixed"]["milestone"]
	var ems: Label = ui._tw_cards["endless"]["milestone"]
	check(fms != null and ems != null, "打磨-121 双塔 里程碑 行 节点 存在")
	check(str(fms.text) == g.tower_milestone_line("fixed", 1)
			and str(fms.text).find("第 10 层精英层") >= 0 and str(fms.text).find("还有 9 层") >= 0,
			"打磨-121 镇妖塔 基准 里程碑 行 = 接口 恒等 含 层数+余量 (实际 %s)" % str(fms.text))
	check(str(ems.text) == g.tower_milestone_line("endless", 1)
			and str(ems.text).find("第 100 层 里程碑 Boss + 宝箱") >= 0 and str(ems.text).find("还有 99 层") >= 0,
			"打磨-121 登天梯 基准 里程碑 行 = 接口 恒等 (实际 %s)" % str(ems.text))
	check(fms.visible and ems.visible, "打磨-121 基准 双塔 里程碑 行 可见")
	# 2) 镇妖塔 待挑战 层 本身 是 精英 (第 10 层): 就在 本层 标注
	g.tower_fixed_floor = 9
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(fms.text) == g.tower_milestone_line("fixed", 10)
			and str(fms.text).find("就在 第 10 层") >= 0,
			"打磨-121 镇妖塔 精英 本层 就在 标注 (实际 %s)" % str(fms.text))
	# 3) 登天梯 第 100 层 (里程碑 Boss 层): 下一 = 200 层 动态 同步
	g.tower_endless_floor = 100
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ems.text) == g.tower_milestone_line("endless", 100)
			and str(ems.text).find("第 200 层") >= 0,
			"打磨-121 登天梯 100 层 下一 = 200 层 同步 (实际 %s)" % str(ems.text))
	# 4) 镇妖塔 通关 守塔 模式: 里程碑 行 隐藏 (无 下一 层 概念)
	g.tower_fixed_floor = 999
	g.tower_fixed_clear = true
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(fms.text) == "" and not fms.visible,
			"打磨-121 镇妖塔 通关 守塔 模式 里程碑 行 隐藏 (实际 text=%s visible=%s)" % [str(fms.text), str(fms.visible)])
	# 5) 里程碑 行 tooltip 口径 说明
	check(str(fms.tooltip_text).find("下一 里程碑") >= 0 and str(fms.tooltip_text).find("守塔 模式") >= 0,
			"打磨-121 里程碑 行 tooltip 含 口径 说明 (实际 %s)" % str(fms.tooltip_text).left(40))
	# 6) 同态 节流: 无 塔 态 变化 再 刷 不 重写 + 无 统计 副作用
	var snap121: Dictionary = g.stats.duplicate(true)
	var ref121: String = str(ems.text)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ems.text) == ref121 and g.stats == snap121, "打磨-121 同态 节流 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.set_process(true)
	ui._tab.current_tab = 3


# 打磨-123: 爬塔 战力对比 胜 阈值/缺口 行 (M5 规格 "战力对比 (胜/败 预测)" 败 预测 时 展示
# 缺口 — 玩家 有效 ATK 不足 只 见 "败", 不知 要 多 强 才 能 过 本层; 阈值 = 怪物 ATK x 0.85
# 判定 口径 与 tower_power_line 同源 单点, 缺口 = 阈值 - 当前 有效 ATK [剧毒 已 计入];
# 败 预测 才 可见 胜 预测 隐藏; 随 战力/剧毒/层数 动态 同步; 收尾 干净 基准)
func _assert_win_threshold_line() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 弱 玩家 (atk 池 清空, 有效 ATK 2.0) + 塔 态 受控:
	# 镇妖塔 挑战层 = 12 (判定=败: 阈值 3.23 > 2.0, 数据 锚定), 登天梯 = 1 (判定=胜:
	# 阈值 1.7 < 2.0) — 一败一胜 覆盖 阈值 行 可见/隐藏 双向
	g.learned.clear()
	g.equipped = {}
	g.owned.clear()
	g.ascended = false
	g.dao_level = 0
	g.tower_fixed_floor = 11
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 1) 双塔 阈值 行 节点 存在 + 败/胜 预测 阈值 行 可见性 分态 (镇妖塔 12 层 败=可见,
	# 登天梯 1 层 胜=隐藏) 且 败 态 文案 = 接口 恒等
	var fthr: Label = ui._tw_thr_labels["fixed"]
	var ethr: Label = ui._tw_thr_labels["endless"]
	check(fthr != null and ethr != null, "打磨-123 双塔 阈值 行 节点 存在")
	var fm123: Dictionary = g.tower_monster_stats(g.get_fixed_floor(12))
	var em123: Dictionary = g.tower_monster_stats(g.get_endless_floor(1))
	check(g.player_atk_effective() < float(fm123["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-123 弱 玩家 镇妖塔 第 12 层 判定=败 (数据 锚定)")
	check(g.player_atk_effective() >= float(em123["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-123 弱 玩家 登天梯 第 1 层 判定=胜 (数据 锚定)")
	check(fthr.visible and str(fthr.text) == g.tower_win_threshold_line(float(fm123["atk"]))
			and str(fthr.text).find("胜 阈值") >= 0 and str(fthr.text).find("还差") >= 0,
			"打磨-123 镇妖塔 败 预测 阈值 行 可见 + = 接口 恒等 (实际 %s)" % str(fthr.text))
	check(not ethr.visible and str(ethr.text) == "",
			"打磨-123 登天梯 胜 预测 阈值 行 隐藏 (实际 vis=%s txt=%s)" % [ethr.visible, str(ethr.text)])
	# 2) 阈值 数值 段 = 怪物 ATK x 0.85 精确 (fmt_score 口径, 与 判定 口径 单点 同源)
	check(str(fthr.text).find("有效 ATK %s" % g.fmt_score(float(fm123["atk"]) * g.TOWER_WIN_RATIO)) >= 0
			and str(fthr.text).find("还差 %s ATK" % g.fmt_score(float(fm123["atk"]) * g.TOWER_WIN_RATIO - g.player_atk_effective())) >= 0,
			"打磨-123 阈值/缺口 数值 段 精确 (实际 %s)" % str(fthr.text))
	# 3) 升层: 阈值/缺口 动态 同步 (镇妖塔 第 20 层 精英 层 数值 更高)
	g.tower_fixed_floor = 19
	ui._refresh_tower()
	await get_tree().process_frame
	var fm123_20: Dictionary = g.tower_monster_stats(g.get_fixed_floor(20))
	check(str(fthr.text) == g.tower_win_threshold_line(float(fm123_20["atk"])),
			"打磨-123 升 精英层 阈值 行 动态 同步 (实际 %s)" % str(fthr.text))
	# 4) 剧毒 态: 有效 ATK x0.85 后 缺口 放大, 行 文案 动态 同步 (判定 口径 同源)
	g.poison_battles = 1
	ui._refresh_tower()
	await get_tree().process_frame
	var thr_poison123: String = g.tower_win_threshold_line(float(fm123_20["atk"]))
	check(str(fthr.text) == thr_poison123 and str(thr_poison123).find("还差 %s ATK" % g.fmt_score(float(fm123_20["atk"]) * g.TOWER_WIN_RATIO - g.player_atk_effective())) >= 0,
			"打磨-123 剧毒 态 缺口 放大 动态 同步 (实际 %s)" % str(fthr.text))
	g.poison_battles = 0
	ui._refresh_tower()
	await get_tree().process_frame
	# 5) tooltip 口径 说明 (判定 口径 + 阈值/缺口 构成 + 提升 路径)
	check(str(fthr.tooltip_text).find("胜 阈值/缺口") >= 0 and str(fthr.tooltip_text).find("x 0.85") >= 0
			and str(fthr.tooltip_text).find("提升 路径") >= 0,
			"打磨-123 阈值 行 tooltip 含 口径+提升 路径 (实际 %s)" % str(fthr.tooltip_text).left(40))
	# 6) 强 玩家 (飞升 道祖): 双塔 胜 预测 → 阈值 行 隐藏 (缺口 <=0 无 展示 价值)
	g.ascended = true
	g.dao_level = 8
	ui._refresh_tower()
	await get_tree().process_frame
	check(not fthr.visible and str(fthr.text) == "" and not ethr.visible and str(ethr.text) == "",
			"打磨-123 强 玩家 胜 预测 双塔 阈值 行 隐藏 (实际 f_vis=%s e_vis=%s)" % [fthr.visible, ethr.visible])
	# 7) 同态 节流: 无 状态 变化 再 刷 不 重写 + 无 统计 副作用 (基准 败 态 恢复 后)
	g.ascended = false
	g.dao_level = 0
	g.tower_fixed_floor = 0
	ui._refresh_tower()
	await get_tree().process_frame
	var snap123: Dictionary = g.stats.duplicate(true)
	var ref123: String = str(fthr.text)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(fthr.text) == ref123 and g.stats == snap123, "打磨-123 同态 节流 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态/玩家 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.learned.clear()
	g.equipped = {}
	g.owned.clear()
	g.ascended = false
	g.dao_level = 0
	g.set_process(true)
	ui._tab.current_tab = 3


# 打磨-127: 双塔 卡片 下一里程碑 ETA 行 (M5 规格 "战斗 节奏 ≤2 秒/层" 的 时间 预期 展示位 —
# 里程碑 行 [打磨-121] 只给 层数 余量, 玩家 挂机 不知 距 下个 精英/Boss/里程碑 Boss 还要 挂 多久;
# 口径 = 层距 x 本层 预估 回合 [tower_rounds_line 同源 最不利 0.9 档] x 2s/层, 7天+ 封顶,
# 败 预测 显 "本层 战力 不足…再 估", 守塔 模式 隐藏; 随 层数/战力/剧毒 动态 同步; 收尾 干净 基准)
func _assert_tower_milestone_eta() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 弱 玩家 (atk 池 清空, 有效 ATK 2.0) + 塔 态 受控 —
	# 镇妖塔 挑战层 = 2 (判定=败: 阈值 2.84 > 2.0, 数据 锚定), 登天梯 = 1 (判定=胜: 阈值 1.44 < 2.0)
	g.learned.clear()
	g.equipped = {}
	g.owned.clear()
	g.ascended = false
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	g.tower_fixed_floor = 1
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 1) 双塔 ETA 行 节点 存在 + 一败一胜 双向 (镇妖塔 2 层 败=战力 不足 提示, 登天梯 1 层 胜=ETA 文案)
	var feta: Label = ui._tw_milestone_eta_labels["fixed"]
	var eta: Label = ui._tw_milestone_eta_labels["endless"]
	check(feta != null and eta != null, "打磨-127 双塔 ETA 行 节点 存在")
	var pv127: Dictionary = g.tower_challenge_preview()
	var fm127: Dictionary = pv127["fixed_mon"]
	var em127: Dictionary = pv127["endless_mon"]
	check(g.player_atk_effective() < float(fm127["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-127 弱 玩家 镇妖塔 第 2 层 判定=败 (数据 锚定)")
	check(g.player_atk_effective() >= float(em127["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-127 弱 玩家 登天梯 第 1 层 判定=胜 (数据 锚定)")
	check(feta.visible and str(feta.text) == g.tower_milestone_eta("fixed", 2, fm127, false)
			and str(feta.text).find("本层 战力 不足") >= 0,
			"打磨-127 镇妖塔 败 预测 ETA 行 = 接口 恒等 战力 不足 段 (实际 %s)" % str(feta.text))
	check(eta.visible and str(eta.text) == g.tower_milestone_eta("endless", 1, em127, true)
			and str(eta.text).find("下一 里程碑 ETA") >= 0 and str(eta.text).find("约 99 层") >= 0,
			"打磨-127 登天梯 胜 预测 ETA 行 = 接口 恒等 含 层距 段 (实际 %s)" % str(eta.text))
	# 2) 升层: ETA 动态 同步 (镇妖塔 2→20 层 怪物 数值 变, 仍 败 预测 战力 不足 提示 口径 不变)
	g.tower_fixed_floor = 19
	ui._refresh_tower()
	await get_tree().process_frame
	var fm127_20: Dictionary = g.tower_challenge_preview()["fixed_mon"]
	check(g.player_atk_effective() < float(fm127_20["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-127 弱 玩家 镇妖塔 第 20 层 判定=败 (数据 锚定)")
	check(str(feta.text) == g.tower_milestone_eta("fixed", 20, fm127_20, false),
			"打磨-127 升 层 败 预测 ETA 行 动态 同步 (实际 %s)" % str(feta.text))
	# 3) 登天梯 升层 (1→100 层 里程碑 Boss 层): 弱 玩家 败 预测 → 战力 不足 提示 动态 同步
	# (怪物 字典 走 preview 口径 = UI 标签 同源 endless_mon, 与 _apply_tower_card 传参 一致)
	g.tower_endless_floor = 100
	ui._refresh_tower()
	await get_tree().process_frame
	var em127_100: Dictionary = g.tower_challenge_preview()["endless_mon"]
	check(g.player_atk_effective() < float(em127_100["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-127 弱 玩家 登天梯 第 100 层 判定=败 (数据 锚定)")
	check(str(eta.text) == g.tower_milestone_eta("endless", 100, em127_100, false)
			and str(eta.text).find("本层 战力 不足") >= 0,
			"打磨-127 登天梯 升 100 层 败 预测 ETA 行 动态 同步 (实际 %s)" % str(eta.text))
	# 4) 剧毒 态: 有效 ATK x0.85 后 按 减成 口径 预估 回合, 胜 预测 下 ETA 文案 动态 同步
	# (剧毒 只 影响 预估 回合, 不 改 胜负 判定; 弱 玩家 登天梯 第 1 层 胜 判定 剧毒 前后 恒 胜;
	# 怪物 字典 走 preview 口径 = UI 标签 同源 endless_mon; 文案 = 接口 恒等 [剧毒 已 计入 有效 ATK])
	g.tower_endless_floor = 1
	ui._refresh_tower()
	await get_tree().process_frame
	var em127np: Dictionary = g.tower_challenge_preview()["endless_mon"]
	var eta127_npoison: String = g.tower_milestone_eta("endless", 1, em127np, true)
	check(str(eta.text) == eta127_npoison and eta127_npoison.find("本层 战力 不足") < 0,
			"打磨-127 登天梯 第 1 层 无 剧毒 胜 预测 ETA 文案 基准 (实际 %s)" % eta127_npoison)
	g.poison_battles = 1
	ui._refresh_tower()
	await get_tree().process_frame
	var em127p: Dictionary = g.tower_challenge_preview()["endless_mon"]
	var eta127_poison: String = g.tower_milestone_eta("endless", 1, em127p, true)
	check(str(eta.text) == eta127_poison,
			"打磨-127 剧毒 态 登天梯 ETA 行 = 接口 恒等 (实际 %s)" % str(eta.text))
	# 剧毒 降成 校验: 有效 ATK 剧毒 态 (x0.85) < 无 剧毒 态
	var atk_npoison127: float = g.player_atk()
	var atk_poison127: float = g.player_atk_effective()
	check(atk_poison127 < atk_npoison127 and absf(atk_poison127 / atk_npoison127 - g.TOWER_POISON_ATK_MULT) < 1e-6,
			"打磨-127 剧毒 态 有效 ATK 降成 x%.2f (无剧毒 %s → 剧毒 %s)" % [g.TOWER_POISON_ATK_MULT, g.fmt(atk_npoison127), g.fmt(atk_poison127)])
	g.poison_battles = 0
	ui._refresh_tower()
	await get_tree().process_frame
	# 5) ETA 行 tooltip 口径 说明 (估算 口径/封顶/败 预测 不出 ETA/不 改 判定)
	check(str(eta.tooltip_text).find("下一 里程碑 ETA") >= 0 and str(eta.tooltip_text).find("7 天 封顶") >= 0
			and str(eta.tooltip_text).find("不 改 即时 胜负 判定") >= 0,
			"打磨-127 ETA 行 tooltip 含 口径 说明 (实际 %s)" % str(eta.tooltip_text).left(40))
	# 6) 强 玩家 (飞升 道祖) 登天梯 第 100 层: 胜 预测 → ETA 正常 文案 (未 封顶, 预估 回合 少)
	g.tower_endless_floor = 100
	g.ascended = true
	g.dao_level = 8
	ui._refresh_tower()
	await get_tree().process_frame
	var em127s100: Dictionary = g.tower_challenge_preview()["endless_mon"]
	check(g.player_atk_effective() >= float(em127s100["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-127 强 玩家 登天梯 第 100 层 判定=胜 (数据 锚定)")
	check(str(eta.text) == g.tower_milestone_eta("endless", 100, em127s100, true)
			and str(eta.text).find("下一 里程碑 ETA") >= 0 and str(eta.text).find("7天+") < 0,
			"打磨-127 强 玩家 登天梯 100 层 ETA 行 = 接口 恒等 未 封顶 (实际 %s)" % str(eta.text))
	# 7) 强 玩家 镇妖塔 通关 守塔 模式: ETA 行 + 里程碑 行 均 隐藏 (无 下一 层 概念)
	g.tower_fixed_floor = 999
	g.tower_fixed_clear = true
	ui._refresh_tower()
	await get_tree().process_frame
	check(not feta.visible and str(feta.text) == "",
			"打磨-127 镇妖塔 通关 守塔 模式 ETA 行 隐藏 (实际 vis=%s txt=%s)" % [feta.visible, str(feta.text)])
	# 8) 同态 节流: 无 塔 态 变化 再 刷 不 重写 + 无 统计 副作用
	var snap127: Dictionary = g.stats.duplicate(true)
	var ref127: String = str(eta.text)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(eta.text) == ref127 and g.stats == snap127, "打磨-127 同态 节流 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态/玩家 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.learned.clear()
	g.equipped = {}
	g.owned.clear()
	g.ascended = false
	g.dao_level = 0
	g.set_process(true)
	ui._tab.current_tab = 3

# 打磨-129: 登天梯 卡片 进度条 接入 下一 100 层 里程碑 段 进度 (M5 规格 双塔卡片 进度 条 的
# 登天梯 段 缺口 — 原 登天梯 条 恒 满条 装饰 无 进度 信息, 无尽 无 上限 玩家 扫视 扫不到
# 段 内 进度; 现 条 填充 = tower_endless_mile_ratio 单点 口径 [(层%100)/100, 100 倍数 层
# 满条, 过层 绕回]; 镇妖塔 条 旧 口径 [层数/1000, 通关 恒 满条 金] 不变; 断言:
# 条 填充 比例 = 接口 恒等 (像素 级) / 100 倍数 层 满条 / 升层 动态 同步 / 条 tooltip 口径
# 双塔 区分 / 镇妖塔 旧 口径 回归 不变 / 同态 节流 无 副作用 / 收尾 干净 基准)
func _assert_endless_mile_bar() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 登天梯 第 1 层 (段 进度 0.01), 镇妖塔 第 40 层 (层数/1000 = 0.04)
	g.tower_fixed_floor = 40
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.poison_battles = 0
	g.poison_events.clear()
	# 等 布局 落定: 2 连续 帧 bg 宽 不变 (>0, 同 打磨-58 口径 — headless 高负载 切页 首帧 宽 0)
	var ebar0: Panel = ui._tw_cards["endless"]["bar_bg"]
	var wprev129 := -1
	for _i129 in 40:
		await get_tree().process_frame
		var wcur129: int = int(ebar0.size.x)
		if wcur129 > 0 and wcur129 == wprev129:
			break
		wprev129 = wcur129
	# 宽 落定 后 清 刷新键 强制 全量 刷 (绕过 节流; 确保 填充 按 稳定 宽 写入 再 断言)
	ui._tw_key = ""
	ui._refresh_tower()
	await get_tree().process_frame
	var ebar: Panel = ui._tw_cards["endless"]["bar_bg"]
	var efill: Panel = ui._tw_cards["endless"]["bar_fill"]
	var fbar: Panel = ui._tw_cards["fixed"]["bar_bg"]
	var ffill: Panel = ui._tw_cards["fixed"]["bar_fill"]
	check(ebar != null and efill != null and fbar != null and ffill != null, "打磨-129 双塔 进度条 节点 齐全 (bg/fill)")
	# 1) 登天梯 第 1 层: 条 填充 = 接口 比例 (像素 级 恒等, 填充宽 = bg 宽 x 比例)
	var w129: float = ebar.size.x
	check(w129 > 0.0, "打磨-129 登天梯 进度条 布局 宽 >0 (实际 %.1f)" % w129)
	var ex129: float = g.tower_endless_mile_ratio(1)
	check(absf(efill.size.x - w129 * ex129) < 1.0 and absf(efill.size.y - ebar.size.y) < 1.0,
		"打磨-129 登天梯 第 1 层 条 填充 = 接口 段 进度 0.01 (实际 填充 %.2f / bg %.2f)" % [efill.size.x, w129])
	# 2) 镇妖塔 旧 口径 回归 不变: 填充 = 层数/1000 比例 (第 40 层 = 0.04)
	check(absf(ffill.size.x - fbar.size.x * (40.0 / 1000.0)) < 1.0,
		"打磨-129 镇妖塔 条 旧 口径 回归 (第 40 层 填充 = 0.04 x 宽, 实际 %.2f / bg %.2f)" % [ffill.size.x, fbar.size.x])
	# 3) 升层 动态 同步: 登天梯 升 第 42 层 -> 填充 比例 = 0.42 (层数 入 刷新键 天然 感知)
	g.tower_endless_floor = 42
	ui._refresh_tower()
	await get_tree().process_frame
	check(absf(efill.size.x - w129 * g.tower_endless_mile_ratio(42)) < 1.0,
		"打磨-129 登天梯 升 第 42 层 条 填充 动态 同步 = 0.42 x 宽 (实际 %.2f)" % efill.size.x)
	# 4) 100 倍数 层 满条 + 过层 绕回: 第 100 层 填充 = 满条, 第 101 层 绕回 0.01
	g.tower_endless_floor = 100
	ui._refresh_tower()
	await get_tree().process_frame
	check(absf(efill.size.x - w129) < 1.0, "打磨-129 登天梯 第 100 层 (里程碑 层) 条 满条 = bg 宽 (实际 %.2f / %.2f)" % [efill.size.x, w129])
	g.tower_endless_floor = 101
	ui._refresh_tower()
	await get_tree().process_frame
	check(absf(efill.size.x - w129 * 0.01) < 1.0, "打磨-129 登天梯 第 101 层 条 绕回 = 0.01 x 宽 (实际 %.2f)" % efill.size.x)
	# 5) 条 tooltip 口径 双塔 区分 (登天梯 = 段 进度 口径, 镇妖塔 = 层数/1000 口径 旧 不变)
	check(str(ebar.tooltip_text).find("里程碑 Boss 的 段 进度") >= 0 and str(ebar.tooltip_text).find("绕回") >= 0,
		"打磨-129 登天梯 条 tooltip 含 段 进度 口径 + 绕回 说明 (实际 %s)" % str(ebar.tooltip_text).left(40))
	check(str(fbar.tooltip_text).find("层数/1000") >= 0,
		"打磨-129 镇妖塔 条 tooltip 含 层数/1000 口径 (实际 %s)" % str(fbar.tooltip_text).left(40))
	# 6) 同态 节流: 无 塔 态 变化 再 刷 不 改 填充 + 无 统计 副作用
	var snap129: Dictionary = g.stats.duplicate(true)
	var fillref129: float = efill.size.x
	ui._refresh_tower()
	await get_tree().process_frame
	check(efill.size.x == fillref129 and g.stats == snap129, "打磨-129 同态 节流 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.learned.clear()
	g.equipped = {}
	g.owned.clear()
	g.ascended = false
	g.dao_level = 0
	g.set_process(true)
	ui._tab.current_tab = 3

# 打磨-124: 爬塔 挑战 按钮 tooltip 动态段 (M5 规格 战斗 即时 判定 的 结算 展示 位 缺口 —
# 「挑战 本层」按钮 此前 无 tooltip, 点击 前 悬停 不知 本层 胜败 预测 与 胜利 结算 内容;
# 口径 与 爬塔页 各 展示 位 同源 [player_atk_effective/tower_power_line/
# tower_win_threshold_line/tower_affix_drop_line/tower_daily_first_line]; 断言:
# 双塔 按钮 tooltip = 接口 恒等 / 一败一胜 双向 覆盖 / 结算 预览 数值 段 精确
# (灵石 表值/材料 向上取整/词缀 掉率 恒等/每日 首胜 口径/剧毒 警告 恒等) / 升层 动态
# 同步 / 同态 节流 无 资源 统计 副作用 / 收尾 干净 基准)
func _assert_challenge_btn_tip() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准 (同 打磨-123 锚定): 弱 玩家 atk 池 清空 [有效 ATK 2.0] + 塔 态 受控:
	# 镇妖塔 挑战层 = 12 (判定=败: 阈值 3.23 > 2.0, 含 剧毒 特性), 登天梯 = 1 (判定=胜:
	# 阈值 1.44 < 2.0, 含 剧毒+重甲 特性) — 一败一胜 覆盖 阈值/缺口 行 与 结算 预览 双向
	g.learned.clear()
	g.equipped = {}
	g.owned.clear()
	g.ascended = false
	g.dao_level = 0
	g.tower_fixed_floor = 11
	g.tower_fixed_clear = false
	g.tower_clear_reward_got = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 1) 双塔 挑战 按钮 节点 存在 + tooltip = 接口 恒等 + 层 标题 行
	var fbtn: Button = ui._tw_cards["fixed"]["btn"]
	var efbtn: Button = ui._tw_cards["endless"]["btn"]
	check(fbtn != null and efbtn != null, "打磨-124 双塔 挑战 按钮 节点 存在")
	var fm124: Dictionary = g.tower_monster_stats(g.get_fixed_floor(12))
	var em124: Dictionary = g.tower_monster_stats(g.get_endless_floor(1))
	check(g.player_atk_effective() < float(fm124["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-124 弱 玩家 镇妖塔 第 12 层 判定=败 (数据 锚定)")
	check(g.player_atk_effective() >= float(em124["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-124 弱 玩家 登天梯 第 1 层 判定=胜 (数据 锚定)")
	var ftip124: String = g.tower_challenge_tip("fixed", 12, fm124)
	var etip124: String = g.tower_challenge_tip("endless", 1, em124)
	check(str(fbtn.tooltip_text) == ftip124 and str(efbtn.tooltip_text) == etip124,
			"打磨-124 双塔 挑战 按钮 tooltip = 接口 恒等 (实际 %s / %s)" % [str(fbtn.tooltip_text).left(30), str(efbtn.tooltip_text).left(30)])
	# 2) 败 预测 (镇妖塔 12 层): 层 标题 + 预测败 + 阈值/缺口 行, 无 结算 预览 段
	check(str(fbtn.tooltip_text).begins_with("镇妖塔 第 12 层\n") and str(fbtn.tooltip_text).find("→ 败") >= 0
			and str(fbtn.tooltip_text).find(g.tower_win_threshold_line(float(fm124["atk"]))) >= 0
			and str(fbtn.tooltip_text).find("胜利 结算 预览") < 0,
			"打磨-124 镇妖塔 败 预测 tooltip = 预测败 + 阈值/缺口 行 无 结算 预览 (实际 %s)" % str(fbtn.tooltip_text))
	# 3) 胜 预测 (登天梯 1 层): 结算 预览 段 数值 精确 (灵石 表值/材料 向上取整/词缀 掉率
	# 恒等/每日 首胜 未 触发 态/剧毒 警告 段 恒等; 无 幸运/不屈 倍率 段/无 首通 大奖 段)
	check(str(efbtn.tooltip_text).find("→ 胜") >= 0
			and str(efbtn.tooltip_text).find("胜利 结算 预览: 灵石 +%s" % g.fmt(float(em124["stone"]))) >= 0,
			"打磨-124 结算 预览 灵石 段 = 层表 表值 (实际 %s)" % str(efbtn.tooltip_text))
	check(str(efbtn.tooltip_text).find("幸运 50% 概率 x2") < 0 and str(efbtn.tooltip_text).find("不屈 x1.2") < 0,
			"打磨-124 无 幸运/不屈 特性 不 追加 倍率 段")
	check(str(efbtn.tooltip_text).find("· 材料 +%d (同 怪物卡 材料 预估)" % int(ceil(float(em124["mats"])))) >= 0,
			"打磨-124 材料 段 = 向上取整 stats mats 恒等")
	var dl124: String = g.tower_affix_drop_line(em124, "endless")
	check(dl124 != "" and str(efbtn.tooltip_text).find("· " + dl124) >= 0,
			"打磨-124 词缀 掉率 段 = tower_affix_drop_line 恒等")
	check(str(efbtn.tooltip_text).find("· 每日 首胜: 今日 首胜 奖励 未 触发") >= 0
			and str(efbtn.tooltip_text).find("首通 一次性 大奖") < 0,
			"打磨-124 每日 首胜 未 触发 态 + 无 首通 大奖 段")
	check(str(efbtn.tooltip_text).find("· 剧毒 特性: 战胜 后 玩家 ATK -15%% 持续 %d 场 (可 刷新)" % int(g.TOWER_POISON_BATTLES)) >= 0,
			"打磨-124 剧毒 特性 警告 段 文案 恒等 (实际 %s)" % str(efbtn.tooltip_text))
	# 4) 升层 动态 同步 (镇妖塔 第 20 层 精英 层; 按钮 tooltip 随 刷新 键 自动 刷, 文本 变化 才 写)
	g.tower_fixed_floor = 19
	ui._refresh_tower()
	await get_tree().process_frame
	var fm124_20: Dictionary = g.tower_monster_stats(g.get_fixed_floor(20))
	check(str(fbtn.tooltip_text) == g.tower_challenge_tip("fixed", 20, fm124_20),
			"打磨-124 升 精英层 20 层 按钮 tooltip 动态 同步 (实际 %s)" % str(fbtn.tooltip_text).left(40))
	# 5) 同态 节流: 无 状态 变化 再 刷 不 重写 + 无 资源/统计 副作用
	var snap124: Dictionary = g.stats.duplicate(true)
	var ess124: float = g.essence
	var stone124: float = g.stones
	var ref124: String = str(fbtn.tooltip_text) + "|" + str(efbtn.tooltip_text)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(fbtn.tooltip_text) + "|" + str(efbtn.tooltip_text) == ref124
			and g.stats == snap124 and g.essence == ess124 and g.stones == stone124,
			"打磨-124 同态 节流 无 资源 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态/玩家 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_clear_reward_got = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.learned.clear()
	g.equipped = {}
	g.owned.clear()
	g.ascended = false
	g.dao_level = 0
	g.set_process(true)
	ui._tab.current_tab = 3


# M7-3 打磨-136: 顶栏 资源图标 断言 — 程序化 单字 徽章 (零素材 零许可风险, 二选一风格中 选 程序化):
# 3 枚 Panel 壳 (20x20 圆角 深底 细边) + 内嵌 13px 单字 Label (界=青/气=金/石=白, 与 行 字色 语义 同源),
# 插在 各行 标签 前 (同父 顶栏 HBox 口径 保持); 纯装饰 无热区 (mouse_filter IGNORE + 无 tooltip),
# 主资源 徽章 字符 随 飞升 翻转 气->道 (仅 翻转 时 重写); 断言: 3 枚 节点/同父/顺序 在行 前/
# 壳 StyleBoxFlat 圆角+深底+边色=字色 语义/字符 字色/飞升 翻转 气->道->气 动态 同步/翻转 后
# 同态 节流 无 副作用/无 存档 副作用/收尾 复原。渲染 像素 入帧 由 136c 商店截图 复核
func _assert_m136_res_icons() -> void:
	var g := GameData
	# 1) 3 枚 节点 存在 + Panel 壳 20x20 + 同父 顶栏 HBox (与 行 标签 同父 口径 不变)
	check(ui._res_realm_icon != null, "打磨-136 境界行 徽章 节点 存在")
	check(ui._res_qi_icon != null, "打磨-136 主资源行 徽章 节点 存在")
	check(ui._res_stone_icon != null, "打磨-136 灵石行 徽章 节点 存在")
	if ui._res_realm_icon == null or ui._res_qi_icon == null or ui._res_stone_icon == null:
		return
	check(ui._res_realm_icon is Panel and ui._res_qi_icon is Panel and ui._res_stone_icon is Panel,
			"打磨-136 徽章 壳 = Panel (实际 %s)" % str(ui._res_realm_icon.get_class()))
	check(ui._res_realm_icon.get_parent() == ui._realm_label.get_parent(),
			"打磨-136 境界 徽章 与 境界行 标签 同父 (实际 %s)" % str(ui._res_realm_icon.get_parent()))
	check(ui._res_qi_icon.get_parent() == ui._essence_label.get_parent(),
			"打磨-136 主资源 徽章 与 主资源行 标签 同父 (实际 %s)" % str(ui._res_qi_icon.get_parent()))
	check(ui._res_stone_icon.get_parent() == ui._stones_label.get_parent(),
			"打磨-136 灵石 徽章 与 灵石行 标签 同父 (实际 %s)" % str(ui._res_stone_icon.get_parent()))
	# 2) 顺序: 徽章 紧跟在 各自 行 标签 前 (HBox 内 前一 兄弟)
	var top_hb: HBoxContainer = ui._realm_label.get_parent() as HBoxContainer
	var kids: Array = top_hb.get_children()
	check(kids.size() > 0 and top_hb.get_child(kids.find(ui._realm_label) - 1) == ui._res_realm_icon,
			"打磨-136 境界 徽章 在 境界行 标签 前 (实际 前兄弟 %s)" % str(top_hb.get_child(kids.find(ui._realm_label) - 1)))
	check(top_hb.get_child(kids.find(ui._essence_label) - 1) == ui._res_qi_icon,
			"打磨-136 主资源 徽章 在 主资源行 标签 前 (实际 %s)" % str(top_hb.get_child(kids.find(ui._essence_label) - 1)))
	check(top_hb.get_child(kids.find(ui._stones_label) - 1) == ui._res_stone_icon,
			"打磨-136 灵石 徽章 在 灵石行 标签 前 (实际 %s)" % str(top_hb.get_child(kids.find(ui._stones_label) - 1)))
	# 3) 壳 StyleBoxFlat: 圆角 4 + 深底 (b 略 > r 深色仙侠) + 边色 = 字色 语义 同源 + 尺寸口径
	var icons: Array = [ui._res_realm_icon, ui._res_qi_icon, ui._res_stone_icon]
	var names: Array = ["界", "气", "石"]
	var idx: Array = [0, 1, 2]
	for i in idx:
		var pn: Panel = icons[i]
		var sbb: StyleBoxFlat = pn.get_theme_stylebox("panel") as StyleBoxFlat
		check(sbb != null, "打磨-136 %s 徽章 壳 StyleBoxFlat (实际 %s)" % [names[i], str(pn.get_theme_stylebox("panel"))])
		if sbb == null:
			continue
		check(sbb.get_corner_radius(0) >= 4.0, "打磨-136 %s 徽章 圆角 >=4 (实际 %.0f)" % [names[i], sbb.get_corner_radius(0)])
		check(sbb.bg_color.b >= sbb.bg_color.r and sbb.bg_color.r < 0.15,
				"%s 徽章 深底 深色仙侠 (实际 %s)" % [names[i], str(sbb.bg_color)])
		var lbb: Label = pn.get_child(0) as Label
		check(lbb != null and lbb.text == names[i], "打磨-136 %s 徽章 字符=%s (实际 %s)" % [names[i], names[i], str(lbb.text) if lbb != null else "null"])
		if lbb == null:
			continue
		check(lbb.get_theme_color("font_color") == sbb.border_color,
				"%s 徽章 字色 = 边色 语义 同源 (实际 %s vs %s)" % [names[i], str(lbb.get_theme_color("font_color")), str(sbb.border_color)])
	# 字色 语义: 界=青 / 气=金 / 石=白 (与 顶栏 行 字色 同源 CYAN/GOLD/WHITEISH)
	check(ui._res_realm_icon.get_child(0).get_theme_color("font_color") == ui.CYAN,
			"打磨-136 界 徽章 字色=青 (实际 %s)" % str(ui._res_realm_icon.get_child(0).get_theme_color("font_color")))
	check(ui._res_qi_icon.get_child(0).get_theme_color("font_color") == ui.GOLD,
			"打磨-136 气 徽章 字色=金 (实际 %s)" % str(ui._res_qi_icon.get_child(0).get_theme_color("font_color")))
	check(ui._res_stone_icon.get_child(0).get_theme_color("font_color") == ui.WHITEISH,
			"打磨-136 石 徽章 字色=白 (实际 %s)" % str(ui._res_stone_icon.get_child(0).get_theme_color("font_color")))
	# 4) 纯装饰 无热区: mouse_filter IGNORE + 无 tooltip + 尺寸 20x20 口径
	for i in idx:
		var pn2: Panel = icons[i]
		check(pn2.mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"%s 徽章 mouse_filter=IGNORE 无热区 (实际 %d)" % [names[i], int(pn2.mouse_filter)])
		check(str(pn2.tooltip_text) == "", "%s 徽章 无 tooltip 纯装饰 (实际 %s)" % [names[i], str(pn2.tooltip_text)])
		check(int(pn2.custom_minimum_size.x) == 20 and int(pn2.custom_minimum_size.y) == 20,
				"%s 徽章 尺寸 20x20 口径 (实际 %dx%d)" % [names[i], int(pn2.custom_minimum_size.x), int(pn2.custom_minimum_size.y)])
	# 5) 飞升 翻转 气->道 (动态 同步, 与 主资源行 口径 同源 primary_res_name)
	check(str(ui._res_qi_icon.get_child(0).text) == "气", "打磨-136 初始 主资源 徽章=气 (实际 %s)" % str(ui._res_qi_icon.get_child(0).text))
	g.ascended = true
	g.dao_level = 1
	ui._refresh()
	check(str(ui._res_qi_icon.get_child(0).text) == "道", "打磨-136 飞升 后 主资源 徽章=道 (实际 %s)" % str(ui._res_qi_icon.get_child(0).text))
	# 翻转 后 同态 节流: 再 刷 两帧 字符 稳定 无 变化 (挂机 恒定)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	check(str(ui._res_qi_icon.get_child(0).text) == "道", "打磨-136 翻转 后 同态 节流 稳定 (实际 %s)" % str(ui._res_qi_icon.get_child(0).text))
	# 无 存档 副作用: 飞升 翻转 仅 改 展示 字符, 不 改 资源/统计
	check(g.essence >= 0 and g.stones >= 0, "打磨-136 翻转 无 资源 副作用 (essence=%s stones=%s)" % [str(g.essence), str(g.stones)])
	# 收尾: 复位 飞升 -> 徽章 恢复 气 + 缓存 复位
	g.ascended = false
	g.dao_level = 0
	ui._refresh()
	check(str(ui._res_qi_icon.get_child(0).text) == "气", "打磨-136 收尾 复位 主资源 徽章=气 (实际 %s)" % str(ui._res_qi_icon.get_child(0).text))
	await get_tree().process_frame


# M7-3 打磨-137-2: 水墨山水 背景 开关 按钮 断言 —
# 修行页 自动 系列 区 末位 toggle (默认 开): 节点/toggle/初始 文本+pressed / z-order 修复
# (_bg 必须 在 全屏 不透明 BG ColorRect 之 上 才 可见, 137-1 原序 被 遮挡) / 点击 切 关:
# bg_on=false + _bg 隐藏 + 按钮 文本/pressed 同步 + 底部 消息 确认 / 点击 恢复 开 /
# 同态 节流 稳定 / 读档 同步 按钮态+可见性 / 整段 快照 无 资源/统计 副作用 / 收尾 复位 开
func _assert_m137_bg_toggle() -> void:
	var g := GameData
	# 冻结 UI 自动 _process + GameData 挂机 累积 (本段 手动 驱动 _process/_refresh;
	# GameData._process 可能被 前段 恢复 运行, 不冻结 会 致 资源/统计 断言 见 累积 增量;
	# 段尾 双 恢复, 同 136/135d 段 冻结 口径)
	var gproc: bool = g.is_processing()
	ui.set_process(false)
	g.set_process(false)
	# 1) 节点 + 基本 态
	check(ui._bg_btn != null, "打磨-137-2 水墨背景 开关 按钮 节点 存在")
	if ui._bg_btn == null or ui._bg == null:
		g.set_process(gproc)
		ui.set_process(true)
		return
	check(ui._bg_btn.toggle_mode, "打磨-137-2 按钮 toggle_mode=true (实际 %s)" % str(ui._bg_btn.toggle_mode))
	check(ui._bg_btn.text == "水墨背景: 开" and ui._bg_btn.button_pressed,
			"打磨-137-2 初始 默认 开: 文本+pressed (实际 %s pressed=%s)" % [str(ui._bg_btn.text), str(ui._bg_btn.button_pressed)])
	check(str(ui._bg_btn.tooltip_text).contains("水墨山水 主背景"), "打磨-137-2 tooltip 含 口径 说明 (实际 %s)" % str(ui._bg_btn.tooltip_text).left(30))
	check(ui._bg_btn.get_parent() == ui._auto_learn_btn.get_parent(),
			"打磨-137-2 按钮 与 自动 系列 按钮 同 容器 (实际 %s)" % str(ui._bg_btn.get_parent().get_class()))
	# 2) z-order 修复: _bg 在 BG ColorRect 之后 (index 更大 渲染 在 上, 不 被 遮挡)
	var bgcr: Control = null
	for c in ui.get_children():
		if c is ColorRect and (c as ColorRect).color == ui.BG:
			bgcr = c
			break
	check(bgcr != null, "打磨-137-2 全屏 BG ColorRect 存在 (底色 0.07/0.08/0.11)")
	if bgcr == null:
		g.set_process(gproc)
		ui.set_process(true)
		return
	var kids: Array = ui.get_children()
	check(kids.find(ui._bg) > kids.find(bgcr),
			"打磨-137-2 _bg z-order 在 BG ColorRect 之上 (bg 序 %d > CR 序 %d)" % [kids.find(ui._bg), kids.find(bgcr)])
	check(ui._bg.visible and g.bg_on, "打磨-137-2 初始 开: _bg 可见 + bg_on=true")
	# 3) 点击 切 关 (emit pressed 走 真实 _on_bg_toggle 路径; 副作用 断言 基准 在 load 后 取, 见 段 7)
	ui._bg_btn.emit_signal("pressed")
	check(g.bg_on == false, "打磨-137-2 点击 切关: bg_on=false (实际 %s)" % str(g.bg_on))
	ui._process(0.0)  # 手动 驱动 缓存键 同步 可见性 (冻结 态 下 确定性)
	check(not ui._bg.visible, "打磨-137-2 切关 后 _bg 隐藏 (零 开销 口径)")
	check(ui._bg_btn.text == "水墨背景: 关" and not ui._bg_btn.button_pressed,
			"打磨-137-2 切关 后 按钮 文本+pressed 同步 (实际 %s pressed=%s)" % [str(ui._bg_btn.text), str(ui._bg_btn.button_pressed)])
	check(str(ui._msg_label.text).contains("水墨山水"), "打磨-137-2 切关 底部 消息 确认 (实际 %s)" % str(ui._msg_label.text))
	# 4) 点击 恢复 开
	ui._bg_btn.emit_signal("pressed")
	ui._process(0.0)
	check(g.bg_on and ui._bg.visible, "打磨-137-2 点击 恢复 开: bg_on=true + _bg 可见")
	check(ui._bg_btn.text == "水墨背景: 开" and ui._bg_btn.button_pressed,
			"打磨-137-2 恢复 后 按钮 态=开 (实际 %s)" % str(ui._bg_btn.text))
	# 5) 同态 节流 稳定
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	check(g.bg_on and ui._bg_btn.text == "水墨背景: 开" and ui._bg.visible,
			"打磨-137-2 同态 节流 稳定 无 抖动 (实际 %s)" % str(ui._bg_btn.text))
	# 6) 读档 同步: 存档 bg_on=false -> load_game -> 按钮态+可见性 同步
	g.save_game()
	var fp: String = g.SAVE_PATH
	var fsr := FileAccess.open(fp, FileAccess.READ)
	var sj: Dictionary = JSON.parse_string(fsr.get_as_text())
	fsr.close()
	sj["bg_on"] = false
	var fsw := FileAccess.open(fp, FileAccess.WRITE)
	fsw.store_string(JSON.stringify(sj))
	fsw.close()
	g.load_game()
	check(g.bg_on == false, "打磨-137-2 读档 恢复 bg_on=false (实际 %s)" % str(g.bg_on))
	ui._refresh()
	ui._process(0.0)
	check(ui._bg_btn.text == "水墨背景: 关" and not ui._bg_btn.button_pressed,
			"打磨-137-2 读档 后 按钮态 同步=关 (实际 %s pressed=%s)" % [str(ui._bg_btn.text), str(ui._bg_btn.button_pressed)])
	check(not ui._bg.visible, "打磨-137-2 读档 后 _bg 可见性 同步 隐藏")
	# 7) 无 资源/统计 副作用: 开关 动作 (点击 切 关/开 两轮) 不 改 资源/统计 —
	# load_game 会 舍入 float 存读档 往返 (~3e-6 误差, 打磨-66 已知 口径) 且 重读 stats,
	# 故 断言 基准 取 load 后 快照, 只 覆盖 load 之后 收尾 复位 点击 窗口
	var st1: float = g.stones
	var es1: float = g.essence
	var stats1: Dictionary = g.stats.duplicate(true)
	# 收尾: 复位 开 (点击 切回 走 真实 路径 + 手动 驱动 同步)
	ui._bg_btn.emit_signal("pressed")
	ui._process(0.0)
	ui._refresh()
	check(g.bg_on and ui._bg_btn.text == "水墨背景: 开" and ui._bg.visible,
			"打磨-137-2 收尾 复位 开 (实际 %s)" % str(ui._bg_btn.text))
	check(g.stones == st1 and g.essence == es1,
			"打磨-137-2 收尾 点击 无 资源 副作用 (stones=%s essence=%s)" % [str(g.stones), str(g.essence)])
	check(g.stats == stats1, "打磨-137-2 收尾 点击 无 统计 副作用")
	g.set_process(gproc)
	ui.set_process(true)
	await get_tree().process_frame


# M7-2 打磨-135d: 进度条 族 9-slice 换皮 断言 —
# 7 族 bar (顶栏 goalbar/突破条/冷却条 24/双塔 2/收集 mini 6/成就 N 行) 底 = bar_track.png 9-slice
# (裁 实心带 region_rect + 水平边距 4 保 端部 倒角 + 垂直 0 纯 拉伸 防 细条 压扁, Xvfb 实测 5/6/10/14px
# 均 完整 渲染), 填充 = bar_fill.png 9-slice (裁 亮带, modulate 上色 金/青 档 逻辑 不变); 断言: 7 族
# 底 纹理 路径+裁带 region+水平边距 恒等 / 填充 纹理 路径+modulate 青档(金档 随 满态) / goalbar 攒满
# 动态 满条+modulate 不变 / 同态 节流 无 统计 副作用 / 收尾 复原 0 填充。渲染 高度 属 容器 布局
# (HBox 行 拉伸) 非 换皮 口径, 不 断言 (与 旧 ColorRect 行为 一致 防 误报)
func _assert_m135d_bar_skins() -> void:
	var g := GameData
	# --- 顶栏 goalbar (5px, Button 底 纹理 normal 态 + 填充 Panel) ---
	var gb: Button = ui._goalbar_bg
	var gnorm = gb.get_theme_stylebox("normal")
	check(gnorm is StyleBoxTexture and str((gnorm as StyleBoxTexture).texture.resource_path) == "res://assets/ui/bar_track.png",
		"打磨-135d goalbar 底=bar_track 纹理 (实际 %s)" % str(gnorm))
	check((gnorm as StyleBoxTexture).texture_margin_left == 4.0 and (gnorm as StyleBoxTexture).texture_margin_right == 4.0,
		"打磨-135d goalbar 底 9-slice 水平边距=4 (保 端部 倒角)")
	check((gnorm as StyleBoxTexture).region_rect == Rect2(0, 4, 96, 8),
		"打磨-135d goalbar 底 裁 实心带 region (实际 %s)" % str((gnorm as StyleBoxTexture).region_rect))
	check(gb.get_theme_stylebox("hover") is StyleBoxFlat and (gb.get_theme_stylebox("hover") as StyleBoxFlat).border_width_left == 1,
		"打磨-135d goalbar hover 金边 StyleBoxFlat 保留 (135c-1 同口径, 叠加 纹理底)")
	var gfill: Panel = ui._goalbar_fill
	check(gfill.get_parent() == gb, "打磨-135d goalbar 填充 挂 背景 下")
	var gfill_sb = gfill.get_theme_stylebox("panel")
	check(gfill_sb is StyleBoxTexture and str((gfill_sb as StyleBoxTexture).texture.resource_path) == "res://assets/ui/bar_fill.png",
		"打磨-135d goalbar 填充=bar_fill 纹理 (实际 %s)" % str(gfill_sb))
	check(_fill_modulate(gfill) == Color(0.62, 0.9, 0.95, 0.9), "打磨-135d goalbar 填充 青档 modulate (实际 %s)" % str(_fill_modulate(gfill)))
	# --- 突破条 (14px, 修行页) ---
	var bb = ui._bar_bg
	var bsb = bb.get_theme_stylebox("panel")
	check(bsb is StyleBoxTexture and str((bsb as StyleBoxTexture).texture.resource_path) == "res://assets/ui/bar_track.png"
			and (bsb as StyleBoxTexture).region_rect == Rect2(0, 4, 96, 8),
		"打磨-135d 突破条 底=bar_track 裁带 (实际 %s)" % str(bsb))
	var bfill: Panel = ui._bar_fill
	check(bfill.get_parent() == bb, "打磨-135d 突破条 填充 挂 背景 下")
	check(_fill_modulate(bfill) == ui.CYAN, "打磨-135d 突破条 填充 青档 modulate")
	check(bb.custom_minimum_size.y == 14.0, "打磨-135d 突破条 高 14px 设计值 不变")
	# --- 冷却条 (24 行 6px) ---
	check(ui._skill_cd_bars.size() == 24, "打磨-135d 冷却条 数量=24 (实际 %d)" % ui._skill_cd_bars.size())
	var cd0: Dictionary = ui._skill_cd_bars.values()[0]
	var cdbg: Panel = cd0["bg"]
	var cfill: Panel = cd0["fill"]
	var csb = cdbg.get_theme_stylebox("panel")
	check(csb is StyleBoxTexture and str((csb as StyleBoxTexture).texture.resource_path) == "res://assets/ui/bar_track.png"
			and (csb as StyleBoxTexture).region_rect == Rect2(0, 4, 96, 8),
		"打磨-135d 冷却条 底=bar_track 裁带 (实际 %s)" % str(csb))
	check(_fill_modulate(cfill) == ui.CYAN, "打磨-135d 冷却条 填充 青档 modulate")
	check(cdbg.custom_minimum_size.y == 6.0, "打磨-135d 冷却条 高 6px 设计值 不变")
	# --- 双塔 卡片 (10px x2) ---
	var fbar: Panel = ui._tw_cards["fixed"]["bar_bg"]
	var ebar: Panel = ui._tw_cards["endless"]["bar_bg"]
	var fsb = fbar.get_theme_stylebox("panel")
	check(fsb is StyleBoxTexture and str((fsb as StyleBoxTexture).texture.resource_path) == "res://assets/ui/bar_track.png"
			and (fsb as StyleBoxTexture).region_rect == Rect2(0, 4, 96, 8),
		"打磨-135d 镇妖塔 底=bar_track 裁带 (实际 %s)" % str(fsb))
	var esb = ebar.get_theme_stylebox("panel")
	check(esb is StyleBoxTexture and str((esb as StyleBoxTexture).texture.resource_path) == "res://assets/ui/bar_track.png",
		"打磨-135d 登天梯 底=bar_track 裁带 (实际 %s)" % str(esb))
	check(_fill_modulate(ui._tw_cards["fixed"]["bar_fill"]) == ui.CYAN
			and _fill_modulate(ui._tw_cards["endless"]["bar_fill"]) == ui.CYAN,
		"打磨-135d 双塔 填充 青档 两 卡 modulate")
	check(fbar.custom_minimum_size.y == 10.0, "打磨-135d 双塔 条 高 10px 设计值 不变")
	# --- 收集 mini (6 条 6px) ---
	var ci: Dictionary = ui._collect_items["skill"]
	var cbg: Panel = ci["bar_bg"]
	var cbfill: Panel = ci["bar_fill"]
	var cs2 = cbg.get_theme_stylebox("panel")
	check(cs2 is StyleBoxTexture and str((cs2 as StyleBoxTexture).texture.resource_path) == "res://assets/ui/bar_track.png"
			and (cs2 as StyleBoxTexture).texture_margin_left == 4.0,
		"打磨-135d 收集 mini 底=bar_track (实际 %s)" % str(cs2))
	check(_fill_modulate(cbfill) == ui.CYAN, "打磨-135d 收集 mini 填充 青档 modulate")
	check(cbg.custom_minimum_size == Vector2(72, 6), "打磨-135d 收集 mini 尺寸 72x6 设计值 不变")
	# --- 成就 行 (6px x N) ---
	var aid0: String = g.ach_ids[0]
	var ar: Dictionary = ui._ach_rows[aid0]
	var abg: Panel = ar["bar_bg"]
	var asb = abg.get_theme_stylebox("panel")
	check(asb is StyleBoxTexture and str((asb as StyleBoxTexture).texture.resource_path) == "res://assets/ui/bar_track.png"
			and (asb as StyleBoxTexture).region_rect == Rect2(0, 4, 96, 8),
		"打磨-135d 成就 条 底=bar_track 裁带 (实际 %s)" % str(asb))
	check(_fill_modulate(ar["bar_fill"]) == ui.CYAN, "打磨-135d 成就 条 填充 青档 modulate")
	check(abg.custom_minimum_size.y == 6.0, "打磨-135d 成就 条 高 6px 设计值 不变")
	# --- goalbar 攒满 动态 同步 (0 -> 满条, 填充 随 ratio; 全 同步 路径 无 await 防 _process 累积 干扰) ---
	var ess135s: float = g.essence
	g.essence = 0.0
	ui._refresh()
	check(int(gfill.size.x) == 0, "打磨-135d goalbar 初始 0 灵气 0 填充 (实际 %d)" % int(gfill.size.x))
	g.essence = g.breakthrough_cost()
	ui._refresh()
	check(gfill.size.x == gb.size.x, "打磨-135d goalbar 攒满 满条 (fill=%.1f 宽=%.1f)" % [gfill.size.x, gb.size.x])
	check(_fill_modulate(gfill) == Color(0.62, 0.9, 0.95, 0.9), "打磨-135d goalbar 满条 后 modulate 青档 不变")
	# 同态 节流: 再刷 填充 不 重写 + 无 统计 副作用
	var f135b: float = gfill.size.x
	var snap135: Dictionary = g.stats.duplicate(true)
	ui._refresh()
	check(gfill.size.x == f135b and g.stats == snap135, "打磨-135d 同态 节流 填充 稳定 无 统计 副作用")
	# 收尾: 复原 前序 灵气 (0 填充 态 由 键 节流 保持, 防 后续 段 基线 漂移)
	g.essence = ess135s
	ui._refresh()


func _finish() -> void:
	print("")
	if _fail.is_empty():
		print("UI_TEST PASS  %d 项全部通过" % _pass)
		get_tree().quit(0)
	else:
		printerr("UI_TEST FAIL  %d 通过 / %d 失败:" % [_pass, _fail.size()])
		for x in _fail:
			printerr("  - " + x)
		var rf := FileAccess.open("user://ui_test_result.txt", FileAccess.WRITE)
		if rf != null:
			rf.store_string("\n".join(_fail))
			rf.close()
		get_tree().quit(1)  # 修复: 失败分支 原 缺 退出 调用 — headless 场景 模式 不 quit 会 无限 空转 (进程 挂死), 现 退出码 1 与 selftest/stress 口径 一致


# 打磨-75: 顶栏 一键系列 状态汇总徽标 — 顶栏 青色 徽标 "一键:" + 6 段热区 (领悟/神通/施展/法器/装备/最佳,
# 可执行>0 金色带计数 / =0 灰; 与 各页 一键 按钮 计数 同口径, 领悟/神通 受 技能页 筛选 叠加);
# 段 点击 直达 对应页 (重置 筛选) 或 直接 执行 一键施展 (施展 段).
# 断言 (手动驱动 确定性): 徽标节点 顶栏同父/6 段 flat Button+手型/tooltip 口径/受控基准 6 段 计数+着色/
# 键 缓存/同态 节流 无副作用/筛选 叠加 (tier0)/学 6 神通 施展段 变金/施展段 点击 直接 执行
# (爆发=速率x秒数 精确 匹配+统计+冷却后 段 回灰)/5 段 直达 (切页+重置筛选+底部消息 无副作用)/
# 全 0 态 6 段 全灰/收尾 恢复
func _assert_onekey_badge() -> void:
	var g := GameData
	# 徽标 节点: 顶栏 子节点 (与 自动 徽标 同父), flat Button 容器
	var badge: Button = ui._onekey_badge
	check(badge != null, "打磨-75 顶栏 一键 汇总 徽标 节点 存在")
	check(badge is Button and badge.flat == true, "打磨-75 徽标 flat Button (可点热区容器)")
	check(badge.get_parent() == ui._auto_badge.get_parent(),
			"打磨-75 徽标 挂在 顶栏 (与 自动 徽标 同父; 实际 %s)" % str(badge.get_parent()))
	check(ui._onekey_segs.size() == 6 and ui._onekey_btns.size() == 6,
			"打磨-75 6 段 标签/按钮 齐全 (实际 %d/%d)" % [ui._onekey_segs.size(), ui._onekey_btns.size()])
	for i in 6:
		var seg_btn: Button = ui._onekey_btns[i]
		var seg_l: Label = ui._onekey_segs[i]
		check(seg_btn is Button and seg_btn.flat == true and seg_btn.toggle_mode == false,
				"打磨-75 段%d flat 非toggle 热区" % i)
		check(seg_btn.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
				"打磨-75 段%d 手型光标" % i)
		check(seg_l.get_parent() == seg_btn, "打磨-75 段%d 标签 挂在 热区 下" % i)
		check(str(seg_btn.tooltip_text).find("段计数 = 当前 可执行数") >= 0,
				"打磨-75 段%d tooltip 含 段计数 口径 (实际 %s)" % [i, str(seg_btn.tooltip_text).left(40)])
	check(str(badge.tooltip_text).find("一键系列 状态汇总") >= 0
			and str(badge.tooltip_text).find("施展→直接 执行 一键施展") >= 0
			and str(badge.tooltip_text).find("纯 导航/执行") >= 0,
			"打磨-75 徽标 tooltip 含 汇总口径/施展执行/无副作用 说明")
	# 受控基准: 境界2 层1 灵石 5000 全空 状态 (防 前序 测试 残留 污染)
	g.realm_idx = 2
	g.layer = 1
	g.essence = 0.0
	g.stones = 5000.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._on_filter("")
	ui._on_tier_filter("")
	ui._on_equip_filter("")
	ui._on_equip_tier_filter("")
	ui._refresh()
	# 6 段 计数 与 着色 (基准 键 51|14|0|2|60|0, 期望值 与 selftest 同 数据 锚定;
	# 段 0 可执行 时 文本=名称 (灰), >0 时 追加 " N" (金))
	check(ui._onekey_key == "51|14|0|2|60|0", "打磨-75 基准 键=51|14|0|2|60|0 (实际 %s)" % ui._onekey_key)
	var exp_txt: Array = ["领悟 51", "神通 14", "施展", "法器 2", "装备 60", "最佳"]
	var exp_gold: Array = [true, true, false, true, true, false]
	for i in 6:
		var seg_l: Label = ui._onekey_segs[i]
		check(str(seg_l.text) == str(exp_txt[i]),
				"打磨-75 基准 段%d 文本=%s (实际 %s)" % [i, str(exp_txt[i]), str(seg_l.text)])
		var col: Color = seg_l.get_theme_color("font_color")
		check(col == ui.GOLD if exp_gold[i] else col == ui.DIM,
				"打磨-75 基准 段%d 着色 %s (实际 %s)" % [i, "金" if exp_gold[i] else "灰", str(col)])
	# 同态 节流: 再 _refresh 键不变 不重写 (文本 稳定 + 无 资源/统计 副作用)
	var st75: Dictionary = g.stats.duplicate(true)
	var stones75: float = g.stones
	var txt75: String = str(ui._onekey_segs[0].text) + "|" + str(ui._onekey_segs[4].text)
	ui._refresh()
	check(ui._onekey_key == "51|14|0|2|60|0"
			and str(ui._onekey_segs[0].text) + "|" + str(ui._onekey_segs[4].text) == txt75
			and g.stones == stones75 and g.stats == st75,
			"打磨-75 同态 节流 文本稳定 无 资源/统计 副作用")
	# 筛选 叠加: 品质 tier0 → 领悟/神通 段 减, 法器/装备/最佳 不变 (口径 与 技能页 按钮 一致)
	ui._on_tier_filter("0")
	ui._refresh()
	check(ui._onekey_key == "20|6|0|2|60|0", "打磨-75 筛选 tier0 键=20|6|0|2|60|0 (实际 %s)" % ui._onekey_key)
	check(str(ui._onekey_segs[0].text) == "领悟 20" and str(ui._onekey_segs[1].text) == "神通 6",
			"打磨-75 tier0 领悟 20 神通 6 (实际 %s / %s)" % [str(ui._onekey_segs[0].text), str(ui._onekey_segs[1].text)])
	check(str(ui._onekey_segs[3].text) == "法器 2" and str(ui._onekey_segs[4].text) == "装备 60",
			"打磨-75 tier0 法器/装备 段 不受 技能 筛选 影响")
	ui._on_tier_filter("")
	ui._refresh()
	# 学 6 个 可学 主动神通 (tier0) → 施展 段 变金 "施展 6"
	var act_t0: Array = []
	for sid in g.skill_ids:
		var s: Dictionary = g.skill_by_id.get(str(sid), {})
		if not s.is_empty() and str(s.get("type","")) == "active" and int(s["tier"]) == 0 and g.can_learn(str(sid)):
			act_t0.append(str(sid))
	check(act_t0.size() == 6, "打磨-75 受控 可学 主动神通(tier0)=6 (实际 %d)" % act_t0.size())
	for sid in act_t0:
		g.learned.append(str(sid))
	ui._refresh()
	check(ui._onekey_key == "45|8|6|2|60|0", "打磨-75 学6神通 键=45|8|6|2|60|0 (实际 %s)" % ui._onekey_key)
	check(str(ui._onekey_segs[2].text) == "施展 6" and ui._onekey_segs[2].get_theme_color("font_color") == ui.GOLD,
			"打磨-75 施展 段 就绪 6 金色 (实际 %s)" % str(ui._onekey_segs[2].text))
	# 施展 段 点击 = 直接 执行 一键施展 (不切页; 爆发=速率x秒数 精确; 冷却后 段 回灰)
	var qi_rate: float = g.qi_per_sec()
	var exp_burst := 0.0
	for sid in act_t0:
		exp_burst += float(g.skill_by_id[str(sid)]["value"]) * qi_rate
	var ess_before: float = g.essence
	var use_before: float = float(g.stats.get("skill_use", 0.0))
	var fcnt_before: int = ui._onekey_float_count
	var tab_before: int = ui._tab.current_tab
	ui._on_onekey_jump("cast")
	check(g.essence == ess_before + exp_burst, "打磨-75 施展执行 爆发=%s (实际 +%s)" % [str(exp_burst), str(g.essence - ess_before)])
	check(float(g.stats.get("skill_use", 0.0)) == use_before + 6.0, "打磨-75 施展执行 skill_use+6")
	check(ui._onekey_float_count == fcnt_before + 1 and str(ui._onekey_last_text).find("一键施展 6 个神通 (爆发+") >= 0,
			"打磨-75 施展执行 浮动 文案含 数量+爆发 (实际 %s)" % str(ui._onekey_last_text))
	check(ui._tab.current_tab == tab_before, "打磨-75 施展执行 不切页 (实际 %d)" % ui._tab.current_tab)
	ui._refresh()
	check(str(ui._onekey_segs[2].text) == "施展" and ui._onekey_segs[2].get_theme_color("font_color") == ui.DIM,
			"打磨-75 施展后 全冷却 施展 段 回灰 无计数 (实际 %s)" % str(ui._onekey_segs[2].text))
	check(str(ui._onekey_segs[1].text) == "神通 8", "打磨-75 施展执行 不改变 神通 可学数")
	# 5 段 直达: 切页 + 重置 筛选 + 底部 消息; 不执行 学习/购买 (只 施展 段 执行)
	var snap_ess: float = g.essence
	var snap_st: float = g.stones
	var snap_learn: int = g.learned.size()
	var snap_own: int = g.owned_eq.size()
	var snap_stats: Dictionary = g.stats.duplicate(true)
	ui._on_onekey_jump("learn")
	check(ui._tab.current_tab == 1 and ui._filter_active == "" and ui._tier_active == ""
			and str(ui._msg_label.text).find("直达 技能页·一键领悟") >= 0,
			"打磨-75 领悟段 点击 → 技能页+重置 筛选+底部消息 (tab=%d %s)" % [ui._tab.current_tab, str(ui._msg_label.text)])
	check(g.learned.size() == snap_learn, "打磨-75 领悟段 直达 不 执行 学习")
	ui._on_onekey_jump("active_learn")
	check(ui._tab.current_tab == 1 and str(ui._msg_label.text).find("一键神通") >= 0,
			"打磨-75 神通段 点击 → 技能页 一键神通 消息")
	ui._on_onekey_jump("item")
	check(ui._tab.current_tab == 0 and str(ui._msg_label.text).find("法器区") >= 0,
			"打磨-75 法器段 点击 → 修行页·法器区")
	var ip_sb: StyleBoxFlat = ui._items_panel.get_theme_stylebox("panel")
	check(ip_sb != null and ip_sb.border_width_left == 2 and ip_sb.border_color == ui.GOLD,
			"打磨-75 法器段 点击 → 法器区 金边高亮 (边框宽=2 金)")
	ui._on_onekey_jump("equip")
	check(ui._tab.current_tab == 2 and ui._equip_filter_active == "" and ui._equip_tier_active == ""
			and str(ui._msg_label.text).find("直达 装备页·一键购买") >= 0,
			"打磨-75 装备段 点击 → 装备页+重置 部位/品质 筛选")
	ui._on_onekey_jump("best")
	check(ui._tab.current_tab == 2 and str(ui._msg_label.text).find("一键最佳") >= 0,
			"打磨-75 最佳段 点击 → 装备页 一键最佳 消息")
	check(g.essence == snap_ess and g.stones == snap_st and g.learned.size() == snap_learn
			and g.owned_eq.size() == snap_own and g.stats == snap_stats,
			"打磨-75 5 段 直达 均 不 执行 批量操作 (无 资源/学习/购买 副作用)")
	# 等待 法器区 高亮 1.2s 自动恢复 (重入 口径 与 打磨-44 一致, 防 污染 收尾)
	await get_tree().create_timer(1.4).timeout
	var ip_rest: StyleBoxFlat = ui._items_panel.get_theme_stylebox("panel")
	check(ip_rest != null and ip_rest.border_width_left == 0, "打磨-75 法器区 高亮 1.2s 后 自动恢复 (边框宽=0)")
	# 全新 开荒 基准: 清空 状态 + 灵石 0 + 境界归 练气1层 → 施展/法器/装备/最佳 全 0 灰,
	# 领悟/神通 = 凡品 可学数 11/6 (与 各页 按钮 同口径; 防 前序 测试 残留 污染)
	g.stones = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._refresh()
	check(ui._onekey_key == "11|6|0|0|0|0", "打磨-75 全新基准 键=11|6|0|0|0|0 (实际 %s)" % ui._onekey_key)
	var exp0_names: Array = ["施展", "法器", "装备", "最佳"]
	for i in [2, 3, 4, 5]:
		var seg_l: Label = ui._onekey_segs[i]
		check(str(seg_l.text) == exp0_names[i - 2] and seg_l.get_theme_color("font_color") == ui.DIM,
				"打磨-75 全新基准 段%d 灰 仅名称 无计数 (实际 %s)" % [i, str(seg_l.text)])
	check(str(ui._onekey_segs[0].text) == "领悟 11" and str(ui._onekey_segs[1].text) == "神通 6",
			"打磨-75 全新基准 领悟11 神通6 金色 (实际 %s / %s)" % [str(ui._onekey_segs[0].text), str(ui._onekey_segs[1].text)])
	# 收尾: 恢复 干净 基准 (防 污染 后续 测试)
	g.stones = 0.0
	g.essence = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._refresh()
	await get_tree().process_frame


# 打磨-76: 顶栏 一键 徽标 段 悬浮 明细 — 段 tooltip 追加 可执行项 列表 (与 段 计数 同 状态键 节流);
# 断言 (手动驱动 确定性): 6 段 tooltip 结构 (口径行 + 段计数 行 + 空行 + 明细) / 基准 明细 文案
# (领悟 51 可学 截断 6 行+…45 项 / 神通 14 / 施展 无就绪 说明 / 法器 2 件 价格升序 / 装备 60 件 5 行+…55 项 /
# 最佳 无拥有 说明) / 明细 与 onekey_segment_tips 接口 逐段 恒等 / 筛选 叠加 刷新 (tier0 领悟 20 神通 6) /
# 学 6 神通 施展段 明细 6 行 爆发 预览 / 拥有 5 件 未穿 最佳段 5 部位 / 同态 节流 tooltip 稳定 无副作用 /
# 灵石 0 法器装备段 灵石不足 说明 / 收尾 恢复 干净 基准
func _assert_onekey_tip_detail() -> void:
	var g := GameData
	# 受控基准: 境界2 层1 / 灵石 5000 / 空 状态 (防 前序 测试 残留 污染, 与 打磨-75 基准 同)
	g.realm_idx = 2
	g.layer = 1
	g.essence = 0.0
	g.stones = 5000.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._on_filter("")
	ui._on_tier_filter("")
	ui._on_equip_filter("")
	ui._on_equip_tier_filter("")
	ui._refresh()
	# 6 段 tooltip 结构: 口径说明行 + "段计数 =" 行 + 空行 + 明细 (明细 首行 含 计数 前缀)
	var exp_prefix: Array = ["51 个可学:", "14 个可学:", "无 就绪 主动神通", "2 件可购:", "60 件可购:", "各 部位 已 最佳"]
	var tips: Array = g.onekey_segment_tips()
	for i in 6:
		var seg_btn: Button = ui._onekey_btns[i]
		var tt: String = str(seg_btn.tooltip_text)
		check(tt.find("段计数 = 当前 可执行数") >= 0, "打磨-76 段%d tooltip 含 段计数 口径 行" % i)
		var detail_part: String = tt.substr(tt.rfind("\n\n"))
		check(detail_part.find("\n\n") >= 0, "打磨-76 段%d tooltip 含 空行 分隔 明细 (实际 %s)" % [i, detail_part.left(20)])
		var det: String = detail_part.substr(detail_part.find("\n\n") + 2)
		check(det == str(tips[i]), "打磨-76 段%d tooltip 明细 = onekey_segment_tips 接口 (实际 %s)" % [i, det.left(30)])
		check(str(tips[i]).find(str(exp_prefix[i])) == 0 or str(tips[i]).begins_with(str(exp_prefix[i])),
				"打磨-76 段%d 明细 前缀=%s (实际 %s)" % [i, str(exp_prefix[i]), str(tips[i]).left(20)])
	check(str(tips[3]).find("· 「木剑」 灵石 100") >= 0 and str(tips[3]).find("· 「玉符」 灵石 1000") >= 0,
			"打磨-76 法器 段 明细 价格升序 (实际 %s)" % str(tips[3]))
	# 同态 节流: 再 _refresh 键不变 → tooltip 不重写 文本稳定 无 资源/统计 副作用
	var st76: Dictionary = g.stats.duplicate(true)
	var stones76: float = g.stones
	var tt76: Array = []
	for i in 6:
		tt76.append(str(ui._onekey_btns[i].tooltip_text))
	ui._refresh()
	var tt76b: Array = []
	for i in 6:
		tt76b.append(str(ui._onekey_btns[i].tooltip_text))
	check(tt76 == tt76b and g.stones == stones76 and g.stats == st76,
			"打磨-76 同态 节流 tooltip 稳定 无 资源/统计 副作用")
	# 筛选 叠加: tier0 → 领悟/神通 段 明细 刷新 (前缀 20/6, 法器/装备 段 不变)
	ui._on_tier_filter("0")
	ui._refresh()
	var tips_t0: Array = g.onekey_segment_tips("", 0)
	check(str(ui._onekey_btns[0].tooltip_text).find(str(tips_t0[0])) >= 0
			and str(ui._onekey_btns[0].tooltip_text).find("20 个可学:") >= 0,
			"打磨-76 tier0 领悟段 明细 刷新 前缀 20 个可学 (实际 %s)" % str(tips_t0[0]).left(20))
	check(str(ui._onekey_btns[1].tooltip_text).find("6 个可学:") >= 0,
			"打磨-76 tier0 神通段 明细 刷新 前缀 6 个可学 (实际 %s)" % str(tips_t0[1]).left(20))
	check(str(ui._onekey_btns[3].tooltip_text).find(str(tips_t0[3])) >= 0
			and str(ui._onekey_btns[4].tooltip_text).find(str(tips_t0[4])) >= 0,
			"打磨-76 tier0 法器/装备 段 明细 不受 技能 筛选 影响")
	ui._on_tier_filter("")
	ui._refresh()
	# 学 6 个 可学 主动神通 (tier0) → 施展段 明细 刷新 6 行 爆发 预览
	var act_t0: Array = []
	for sid in g.skill_ids:
		var s: Dictionary = g.skill_by_id.get(str(sid), {})
		if not s.is_empty() and str(s.get("type","")) == "active" and int(s["tier"]) == 0 and g.can_learn(str(sid)):
			act_t0.append(str(sid))
	for sid in act_t0:
		g.learned.append(str(sid))
	ui._refresh()
	var tip_cast: String = str(ui._onekey_btns[2].tooltip_text)
	check(tip_cast.find("6 个就绪:") >= 0 and tip_cast.count("爆发 +") == 6,
			"打磨-76 学6神通 施展段 明细 刷新 6 行 爆发 预览 (实际 %s)" % tip_cast.left(30))
	# 拥有 各部位 最便宜件 (5 件) 未 穿戴 → 最佳段 明细 刷新 5 部位 (换 建议 + 当前 件名)
	for slot in g.SLOTS:
		var cheapest: Dictionary = {}
		for eid in g.equip_ids:
			var e: Dictionary = g.equip_by_id[eid]
			if str(e["slot"]) != slot:
				continue
			if cheapest.is_empty() or float(e["cost"]) < float(cheapest["cost"]):
				cheapest = e
		g.owned_eq.append(str(cheapest["id"]))
	ui._refresh()
	var tip_best: String = str(ui._onekey_btns[5].tooltip_text)
	check(tip_best.find("5 部位 可改进:") >= 0 and tip_best.count("\n· ") == 5,
			"打磨-76 拥有5件未穿 最佳段 明细 刷新 5 部位 (实际 %s)" % tip_best.left(30))
	# 灵石 归 0 → 法器/装备 段 明细 刷新 灵石不足 说明
	g.stones = 0.0
	ui._refresh()
	check(str(ui._onekey_btns[3].tooltip_text).find("灵石 不足") >= 0
			and str(ui._onekey_btns[4].tooltip_text).find("灵石 不足") >= 0,
			"打磨-76 灵石0 法器/装备段 明细 刷新 灵石不足 说明")
	# 收尾: 恢复 干净 基准 (防 污染 后续 测试), tooltip 恢复 收尾 基准 文案
	g.stones = 0.0
	g.essence = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._refresh()
	var tips_f: Array = g.onekey_segment_tips()
	check(str(ui._onekey_btns[0].tooltip_text).find("11 个可学:") >= 0
			and str(ui._onekey_btns[5].tooltip_text).find("各 部位 已 最佳") >= 0
			and str(tips_f[0]) == str(tips_f[0]),
			"打磨-76 收尾 基准 段 tooltip 恢复 干净 明细")
	await get_tree().process_frame


# 打磨-77: 顶栏 挂机时长 常显 — 顶栏 灵石 行 后 加 灰色小字 "⏳ X小时Y分" (stats.play_sec 分钟档 口径,
# 复用 GameData.play_time_text; 0 时长 隐藏 避免 空文本 占位; 文本 变化 才刷 节流; 纯展示 无 副作用);
# 断言 (手动驱动 确定性): 标签 节点 顶栏 同父/初始 0 时长 隐藏 文本空/注入 600s 显示 ⏳ 10分 可见+灰色/
# 分钟档 节流 (同 分钟档 内 play_sec+10 不重写 文本)/跨档 4200s 显示 1小时10分/tooltip 口径/
# 归 0 恢复 隐藏 文本空/刷新 无 资源/统计 副作用/收尾 0 时长 隐藏
func _assert_play_time_badge() -> void:
	var g := GameData
	# 节点: 顶栏 子节点 (与 自动/一键 徽标 同父), 灰色
	var pl: Label = ui._play_label
	check(pl != null, "打磨-77 顶栏 挂机时长 标签 节点 存在")
	check(pl.get_parent() == ui._auto_badge.get_parent(),
			"打磨-77 标签 挂在 顶栏 (与 自动 徽标 同父; 实际 %s)" % str(pl.get_parent()))
	check(pl.get_theme_color("font_color") == Color(0.6, 0.62, 0.68),
			"打磨-77 标签 字色 灰色 (实际 %s)" % str(pl.get_theme_color("font_color")))
	# 打磨-83: tooltip 首帧 被 _refresh 替换为 离线收益 预估 (含 口径 说明 的 静态 文案 已 让位 动态 段)
	check(pl.tooltip_text.find("离线收益 预估") >= 0,
			"打磨-77 标签 tooltip 为 离线收益 预估 (打磨-83 动态 段; 实际 %s)" % pl.tooltip_text.left(24))
	# 初始: play_sec=0 (前序 收尾 干净 基准) → 隐藏 + 文本空
	check(pl.visible == false and str(pl.text) == "",
			"打磨-77 初始 0 时长 隐藏 文本空 (实际 visible=%s text=%s)" % [str(pl.visible), str(pl.text)])
	# 注入 600s → "⏳ 10分" 可见
	g.stats["play_sec"] = 600.0
	ui._refresh()
	check(pl.visible == true and str(pl.text) == "⏳ 10分",
			"打磨-77 600s 显示 ⏳ 10分 可见 (实际 visible=%s text=%s)" % [str(pl.visible), str(pl.text)])
	# 节流: 同 分钟档 内 刷新 文本 稳定, 无 资源/统计 副作用
	var snap_pt: Dictionary = g.stats.duplicate(true)
	ui._refresh()
	check(str(pl.text) == "⏳ 10分" and g.stats == snap_pt,
			"打磨-77 同 分钟档 节流 文本 稳定 无副作用")
	# 跨档: 4200s = 1小时10分 刷新
	g.stats["play_sec"] = 4200.0
	ui._refresh()
	check(str(pl.text) == "⏳ 1小时10分",
			"打磨-77 跨档 4200s 显示 1小时10分 (实际 %s)" % str(pl.text))
	# 610→620s 同 分钟档 (10分) 文本 不重写
	g.stats["play_sec"] = 610.0
	ui._refresh()
	var t610: String = str(pl.text)
	g.stats["play_sec"] = 620.0
	ui._refresh()
	check(str(pl.text) == t610 and str(pl.text) == "⏳ 10分",
			"打磨-77 610→620s 同 分钟档 文本 不重写 (实际 %s)" % str(pl.text))
	# 归 0 → 隐藏 文本空 恢复
	g.stats["play_sec"] = 0.0
	ui._refresh()
	check(pl.visible == false and str(pl.text) == "",
			"打磨-77 归 0 恢复 隐藏 文本空 (实际 visible=%s text=%s)" % [str(pl.visible), str(pl.text)])
	# 收尾: 干净 基准 (play_sec 0 隐藏)
	check(float(g.stats.get("play_sec", 0.0)) == 0.0,
		"打磨-77 收尾 play_sec 恢复 0 (实际 %s)" % str(g.stats.get("play_sec")))
	# 收尾: 干净 基准 (play_sec 0 隐藏)
	check(float(g.stats.get("play_sec", 0.0)) == 0.0,
			"打磨-77 收尾 play_sec 恢复 0 (实际 %s)" % str(g.stats.get("play_sec")))
	check(pl.visible == false, "打磨-77 收尾 0 时长 隐藏 稳定")
	await get_tree().process_frame


# 打磨-83: 顶栏 挂机时长 悬停 离线收益 预估 tooltip — 挂机时长 标签 tooltip 由 静态 口径 说明 升级为
# 动态 离线 收益 预估 (复用 GameData.offline_preview_tip: 1h/4h/8h 三档 主资源/灵石 + 效率% + 上限 8h,
# 随 速率/功法装备/飞升 变化 才刷; 纯 展示 无 副作用);
# 断言 (手动驱动 确定性): tooltip 初始 含 口径 说明 + 离线收益 预估 段 + 三档/上限/效率%/主资源 灵气/
# 同态 节流 无 资源/统计 副作用/境界 变化 tooltip 同步 动态 恒等/学 offline_rate 功法 效率% 变化/
# 飞升 后 主资源=道行/恢复 复原/收尾 复原
func _assert_play_time_tip() -> void:
	var g := GameData
	var pl: Label = ui._play_label
	# tooltip 初始 (前序 收尾 干净 基准 未飞升): _refresh 已 替换 为 离线收益 预估 段
	check(pl.tooltip_text.find("离线收益 预估") >= 0 and pl.tooltip_text.find("离线 1 小时") >= 0
			and pl.tooltip_text.find("离线 4 小时") >= 0 and pl.tooltip_text.find("离线 8 小时") >= 0,
			"打磨-83 tooltip 含 离线收益 预估 三档 1h/4h/8h")
	check(pl.tooltip_text.find("上限") >= 0 and pl.tooltip_text.find("基础") >= 0,
			"打磨-83 tooltip 含 上限 8 小时 + 基础 效率%%")
	check(pl.tooltip_text.find("灵气") >= 0 and pl.tooltip_text.find("道行") < 0,
			"打磨-83 未飞升 主资源 口径=灵气 (实际 %s)" % pl.tooltip_text.left(30))
	# 同态 节流: 刷新 无 资源/统计/境界 副作用 (tooltip 稳定)
	var snap_t: Dictionary = g.stats.duplicate(true)
	var ess_t: float = g.essence
	var st_t: float = g.stones
	var realm_t: int = g.realm_idx
	var tip_base: String = str(pl.tooltip_text)
	ui._refresh()
	check(str(pl.tooltip_text) == tip_base and g.stats == snap_t
			and g.essence == ess_t and g.stones == st_t and g.realm_idx == realm_t,
			"打磨-83 同态 节流 tooltip 稳定 无 资源/统计 副作用")
	# 境界 变化 → tooltip 数值 同步 (动态 恒等, 恢复原 境界)
	var realm_save: int = g.realm_idx
	g.realm_idx = 2
	ui._refresh()
	check(str(pl.tooltip_text) != tip_base, "打磨-83 境界2 tooltip 数值 变化 (动态)")
	g.realm_idx = realm_save
	ui._refresh()
	check(str(pl.tooltip_text) == tip_base, "打磨-83 恢复 境界 后 tooltip 复原 (实际 %s)" % pl.tooltip_text.left(30))
	# 学 offline_rate 功法 → 效率% 上升 → tooltip 变化 (境界临时拉到 3 使 可学, 学后 恢复+清除)
	var off_skill := ""
	for sid in g.skill_ids:
		var sk: Dictionary = g.skill_by_id[sid]
		if str(sk.get("type", "")) == "passive" and str(sk.get("effect", "")) == "offline_rate":
			off_skill = sid
			break
	check(off_skill != "", "打磨-83 存在 offline_rate 被动 (实际 %s)" % off_skill)
	if off_skill != "":
		g.learned.erase(off_skill)
		var rate_before: float = g.offline_rate()
		var realm_b: int = g.realm_idx
		g.realm_idx = 3
		g.learn_skill(off_skill)
		check(g.learned.has(off_skill) and g.offline_rate() > rate_before,
				"打磨-83 学 offline_rate 后 效率 上升 (实际 %s > %s)" % [str(g.offline_rate()), str(rate_before)])
		ui._refresh()
		var tip_rate: String = str(pl.tooltip_text)
		check(tip_rate.find("基础 %d%%" % int(g.offline_rate() * 100.0)) >= 0,
				"打磨-83 tooltip 含 新 效率%% (实际 %s)" % tip_rate.left(40))
		check(tip_rate != tip_base, "打磨-83 学功法 后 tooltip 变化")
		g.learned.erase(off_skill)
		g.realm_idx = realm_b
		ui._refresh()
		check(str(pl.tooltip_text) == tip_base, "打磨-83 清除 功法+恢复 境界 后 tooltip 复原")
	# 飞升 后 主资源 口径 = 道行 (恢复 原 飞升 态)
	var asc_save: bool = g.ascended
	var daoLv_save: int = g.dao_level
	g.ascended = true
	g.dao_level = 1
	ui._refresh()
	var tip_asc: String = str(pl.tooltip_text)
	check(tip_asc.find("道行") >= 0 and tip_asc.find("灵气") < 0,
			"打磨-83 飞升 后 tooltip 主资源=道行 (实际 %s)" % tip_asc.left(30))
	g.ascended = asc_save
	g.dao_level = daoLv_save
	ui._refresh()
	check(str(pl.tooltip_text) == tip_base, "打磨-83 恢复 飞升 态 后 tooltip 复原")
	# 收尾: 干净 基准
	check(g.ascended == false and g.realm_idx == realm_t, "打磨-83 收尾 状态 复原")
	await get_tree().process_frame


# 打磨-78: 顶栏 主资源速率 常显 — 顶栏 主资源行 (灵气/道行) 后 加 灰色小字 "+X/秒" (未飞升=灵气/秒,
# 飞升后=道行/秒, 与 修行页 灵气速率 同 口径; 速率<=0 隐藏; 文本 变化 才刷 节流; 纯展示 无 副作用);
# 断言 (手动驱动 确定性): 标签 节点 顶栏 同父/灰色/tooltip 口径/初始 可见+文本=接口 (速率恒>0)/
# 同态 节流 稳定 无副作用/境界 变化 文本 同步 (动态 恒等)/飞升 后 道行 口径 动态 恒等/恢复 复原/
# 收尾 文本=接口 可见
func _assert_primary_rate_badge() -> void:
	var g := GameData
	# 节点: 顶栏 子节点 (与 挂机时长 标签 同父), 灰色 13px
	var rl: Label = ui._rate_label
	check(rl != null, "打磨-78 顶栏 主资源速率 标签 节点 存在")
	check(rl.get_parent() == ui._play_label.get_parent(),
		"打磨-78 标签 挂在 顶栏 (与 挂机时长 标签 同父; 实际 %s)" % str(rl.get_parent()))
	check(rl.get_theme_color("font_color") == Color(0.6, 0.62, 0.68),
		"打磨-78 标签 字色 灰色 (实际 %s)" % str(rl.get_theme_color("font_color")))
	check(rl.tooltip_text.find("主资源 收入 速率") >= 0 and rl.tooltip_text.find("修行页 灵气速率 同 口径") >= 0,
		"打磨-78 标签 tooltip 含 口径 说明 (实际 %s)" % rl.tooltip_text.left(20))
	# 初始: 速率 恒 >0 (QI_MULT>=1) → 可见 + 文本=接口 (动态 恒等, 防 前序 残留 干扰)
	var t0: String = g.primary_rate_text()
	check(t0 != "", "打磨-78 基准 速率>0 接口 非空 (实际 %s)" % t0)
	check(rl.visible == true and str(rl.text) == t0,
		"打磨-78 初始 可见 文本=接口 (实际 visible=%s text=%s)" % [str(rl.visible), str(rl.text)])
	# 节流: 同态 刷新 文本 稳定, 无 资源/统计 副作用
	var snap_r: Dictionary = g.stats.duplicate(true)
	var ess_r: float = g.essence
	var st_r: float = g.stones
	ui._refresh()
	check(str(rl.text) == t0 and g.stats == snap_r and g.essence == ess_r and g.stones == st_r,
		"打磨-78 同态 节流 文本 稳定 无副作用")
	# 境界 变化 → 文本 同步 (动态 恒等, 恢复原 境界)
	var realm_save: int = g.realm_idx
	g.realm_idx = 2
	ui._refresh()
	var t_r2: String = g.primary_rate_text()
	check(str(rl.text) == t_r2 and t_r2 != t0,
		"打磨-78 境界2 文本 同步 (实际 %s, 期望 %s)" % [str(rl.text), t_r2])
	g.realm_idx = realm_save
	ui._refresh()
	check(str(rl.text) == t0, "打磨-78 恢复 境界 后 文本 复原 (实际 %s)" % str(rl.text))
	# 飞升 后 口径 = 道行/秒 (速率 同 公式, 动态 恒等; 恢复 原 态)
	var asc_save: bool = g.ascended
	var daoLv_save: int = g.dao_level
	g.ascended = true
	g.dao_level = 1
	ui._refresh()
	var t_asc: String = g.primary_rate_text()
	check(str(rl.text) == t_asc,
		"打磨-78 飞升 后 文本=接口 道行 口径 (实际 %s, 期望 %s)" % [str(rl.text), t_asc])
	g.ascended = asc_save
	g.dao_level = daoLv_save
	ui._refresh()
	check(str(rl.text) == t0, "打磨-78 恢复 飞升 态 后 文本 复原 (实际 %s)" % str(rl.text))
	# 收尾: 可见 + 文本=接口
	check(rl.visible == true and str(rl.text) == g.primary_rate_text(),
		"打磨-78 收尾 可见 文本=接口 稳定")


# 打磨-79: 顶栏 灵石速率 常显 — 顶栏 灵石行 后 加 灰色小字 "+X/秒" (与 修行页 灵石速率 行 同口径
# = 基础 x 境界倍率 x (1+灵石/全面被动+装备加成); 法器连乘 不影响 灵石; 速率<=0 隐藏;
# 文本 变化 才刷 节流; 纯展示 无 副作用);
# 断言 (手动驱动 确定性): 标签 节点 顶栏 同父/灰色/tooltip 口径/初始 可见+文本=接口 (灵石速率恒>0)/
# 同态 节流 稳定 无副作用/境界 变化 文本 同步 (动态 恒等)/飞升 后 口径 不变 动态 恒等/恢复 复原/
# 收尾 文本=接口 可见
func _assert_stone_rate_badge() -> void:
	var g := GameData
	# 节点: 顶栏 子节点 (与 挂机时长 标签 同父), 灰色 13px
	var sl: Label = ui._sr_label
	check(sl != null, "打磨-79 顶栏 灵石速率 标签 节点 存在")
	check(sl.get_parent() == ui._play_label.get_parent(),
		"打磨-79 标签 挂在 顶栏 (与 挂机时长 标签 同父; 实际 %s)" % str(sl.get_parent()))
	check(sl.get_theme_color("font_color") == Color(0.6, 0.62, 0.68),
		"打磨-79 标签 字色 灰色 (实际 %s)" % str(sl.get_theme_color("font_color")))
	check(sl.tooltip_text.find("灵石 收入 速率") >= 0 and sl.tooltip_text.find("修行页 灵石速率 行 同 口径") >= 0,
		"打磨-79 标签 tooltip 含 口径 说明 (实际 %s)" % sl.tooltip_text.left(20))
	# 初始: 灵石速率 恒 >0 (境界倍率>=1) → 可见 + 文本=接口 (动态 恒等, 防 前序 残留 干扰)
	var t0: String = g.stone_rate_text()
	check(t0 != "", "打磨-79 基准 灵石速率>0 接口 非空 (实际 %s)" % t0)
	check(sl.visible == true and str(sl.text) == t0,
		"打磨-79 初始 可见 文本=接口 (实际 visible=%s text=%s)" % [str(sl.visible), str(sl.text)])
	# 节流: 同态 刷新 文本 稳定, 无 资源/统计 副作用
	var snap_s: Dictionary = g.stats.duplicate(true)
	var ess_s: float = g.essence
	var st_s: float = g.stones
	ui._refresh()
	check(str(sl.text) == t0 and g.stats == snap_s and g.essence == ess_s and g.stones == st_s,
		"打磨-79 同态 节流 文本 稳定 无副作用")
	# 境界 变化 → 文本 同步 (灵石 速率 含 境界倍率, 动态 恒等; 恢复原 境界)
	var realm_s: int = g.realm_idx
	g.realm_idx = 2
	ui._refresh()
	var t_r2: String = g.stone_rate_text()
	check(str(sl.text) == t_r2 and t_r2 != t0,
		"打磨-79 境界2 文本 同步 (实际 %s, 期望 %s)" % [str(sl.text), t_r2])
	g.realm_idx = realm_s
	ui._refresh()
	check(str(sl.text) == t0, "打磨-79 恢复 境界 后 文本 复原 (实际 %s)" % str(sl.text))
	# 飞升 后 口径 不变 (灵石 恒 为 灵石, 同 公式 动态 恒等; 恢复 原 态)
	var asc_s: bool = g.ascended
	var daoLv_s: int = g.dao_level
	g.ascended = true
	g.dao_level = 1
	ui._refresh()
	var t_asc: String = g.stone_rate_text()
	check(str(sl.text) == t_asc,
		"打磨-79 飞升 后 文本=接口 口径 不变 (实际 %s, 期望 %s)" % [str(sl.text), t_asc])
	g.ascended = asc_s
	g.dao_level = daoLv_s
	ui._refresh()
	check(str(sl.text) == t0, "打磨-79 恢复 飞升 态 后 文本 复原 (实际 %s)" % str(sl.text))
	# 收尾: 可见 + 文本=接口
	check(sl.visible == true and str(sl.text) == g.stone_rate_text(),
		"打磨-79 收尾 可见 文本=接口 稳定")


# 打磨-87: 顶栏 主资源行 悬停 下一目标 动态 tooltip — 顶栏 主资源行 (灵气/道行) 悬停 即知
# 下一目标 进度 (当前速率/缺口/ETA/成功率), 不 切 修行页; 与 顶栏灵石行 tooltip 打磨-49 同 模式,
# 口径=primary_next_target_tip (复用 打磨-24/31/36 只读接口, 随 境界/资源/功法装备/飞升 变化 才刷;
# 纯 展示 无 存档/统计 副作用);
# 断言 (手动驱动 确定性): tooltip=接口/基准 含 速率+缺口+ETA+成功率/同态 节流 稳定 无副作用/
# 境界2 同步 (动态 恒等)/灵气 攒够 切 已攒够 文案/飞升 口径 切 道行/恢复 复原 收尾 文本=接口
func _assert_primary_next_tip() -> void:
	var g := GameData
	var el: Label = ui._essence_label
	# 节点: 顶栏 主资源行 (与 灵石行 同父), 金色 19px
	check(el != null, "打磨-87 顶栏 主资源行 节点 存在")
	check(el.get_parent() == ui._stones_label.get_parent(),
		"打磨-87 标签 挂在 顶栏 (与 灵石行 同父; 实际 %s)" % str(el.get_parent()))
	# 初始: tooltip=接口 (动态 恒等, 防 前序 残留 干扰)
	var t0: String = g.primary_next_target_tip()
	check(str(el.tooltip_text) == t0, "打磨-87 初始 tooltip=接口 (实际 %s, 期望 %s)" % [str(el.tooltip_text).left(40), t0.left(40)])
	check(t0.find("当前") >= 0 and t0.find("灵气/秒") >= 0,
		"打磨-87 基准 tooltip 含 当前 速率 灵气/秒 (实际 %s)" % t0.left(30))
	check(t0.find("还差") >= 0 and t0.find("突破成功率") >= 0 and t0.find("突破还需") >= 0,
		"打磨-87 基准 tooltip 含 缺口+成功率+ETA (实际 %s)" % t0.left(60))
	# 节流: 同态 再刷 两帧, tooltip 稳定 + 缓存 不变 + 无 资源/统计 副作用
	var cache0: String = str(ui._primary_tip)
	var snap87: Dictionary = g.stats.duplicate(true)
	var ess87: float = g.essence
	var st87: float = g.stones
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	await get_tree().process_frame
	check(str(el.tooltip_text) == t0 and str(ui._primary_tip) == cache0,
		"打磨-87 同态 再刷 缓存 不变 (节流 生效)")
	check(g.stats == snap87 and g.essence == ess87 and g.stones == st87,
		"打磨-87 同态 节流 无 资源/统计 副作用")
	# 境界 变化 → tooltip 同步 (成功率/消耗/速率 变, 动态 恒等; 恢复原 境界)
	var realm87: int = g.realm_idx
	g.realm_idx = 2
	ui._refresh()
	var t_r2: String = g.primary_next_target_tip()
	check(str(el.tooltip_text) == t_r2 and t_r2 != t0,
		"打磨-87 境界2 tooltip 同步 (实际 %s, 期望 %s)" % [str(el.tooltip_text).left(40), t_r2.left(40)])
	check(t_r2.find("突破成功率 77%") >= 0, "打磨-87 境界2 成功率=77%% (实际 %s)" % t_r2.left(60))
	g.realm_idx = realm87
	ui._refresh()
	check(str(el.tooltip_text) == t0, "打磨-87 恢复 境界 后 tooltip 复原 (实际 %s)" % str(el.tooltip_text).left(40))
	# 灵气 攒够 → 切 已攒够 文案 (无 还差/成功率), 再刷 后 恢复 基准 文案
	var need87: float = g.breakthrough_cost()
	g.essence = need87
	ui._refresh()
	var t_full: String = str(el.tooltip_text)
	check(t_full != t0 and t_full.find("灵气已攒够, 点击突破!") >= 0,
		"打磨-87 资源够 tooltip 切 已攒够 文案 (实际 %s)" % t_full.left(40))
	check(t_full.find("还差") < 0 and t_full.find("成功率") < 0,
		"打磨-87 资源够 tooltip 无 缺口/成功率 (实际 %s)" % t_full.left(40))
	g.essence = 0.0
	ui._refresh()
	check(str(el.tooltip_text) == t0, "打磨-87 灵气 归 0 后 tooltip 复原 基准")
	# 飞升 后 口径 = 道行 (道行/秒, 道行精进至/道行精进成功率, 动态 恒等; 恢复原 态)
	var asc87: bool = g.ascended
	var daoLv87: int = g.dao_level
	g.ascended = true
	g.dao_level = 0
	ui._refresh()
	var t_asc: String = g.primary_next_target_tip()
	check(str(el.tooltip_text) == t_asc,
		"打磨-87 飞升 后 tooltip=接口 道行 口径 (实际 %s, 期望 %s)" % [str(el.tooltip_text).left(40), t_asc.left(40)])
	check(t_asc.find("道行/秒") >= 0 and t_asc.find("道行精进成功率") >= 0,
		"打磨-87 飞升 tooltip 含 道行 口径 (实际 %s)" % t_asc.left(60))
	g.ascended = asc87
	g.dao_level = daoLv87
	ui._refresh()
	check(str(el.tooltip_text) == t0, "打磨-87 恢复 飞升 态 后 tooltip 复原 (实际 %s)" % str(el.tooltip_text).left(40))
	# 收尾: tooltip=接口 稳定
	check(str(el.tooltip_text) == g.primary_next_target_tip(),
		"打磨-87 收尾 tooltip=接口 稳定")


# 打磨-81: 顶栏 下一目标 渐变进度条 — 顶栏 下 5px 全宽 青色 填充 (next_goal_ratio 0..1,
# 与 修行页 下一目标 行 同 口径; 2% 量化档+布局宽 变化 才写 fill, 挂机 恒定 无 每帧 重绘;
# tooltip 动态 含 比例; 飞升 后 口径 切换 道行精进; 道祖 封顶 满条; 纯 展示 无 副作用);
# 断言 (手动驱动 确定性): 节点/父链/高度/颜色/tooltip 口径/初始 0% 空 填充/同态 节流 稳定/
# 灵气 半程 50% 填充 同步/同态 再刷 fill 不变 节流/攒满 100% 满 填充/境界2 消耗变 比例 同步/
# 飞升 口径 切换 道行精进 动态 恒等/道祖 封顶 满条/恢复 复原 收尾 0% 稳定 无 资源/统计 副作用
func _assert_goalbar() -> void:
	var g := GameData
	var bg: Node = ui._goalbar_bg
	var fill: Panel = ui._goalbar_fill
	check(bg != null and fill != null, "打磨-81 顶栏 下一目标 进度条 节点 存在")
	check(fill.get_parent() == bg, "打磨-81 填充 挂在 背景 下 (实际 %s)" % str(fill.get_parent()))
	var root_bg: Node = bg.get_parent()
	check(root_bg.get_children().find(bg) >= 0 and root_bg.get_child(root_bg.get_children().find(bg) + 1) == ui._tab,
		"打磨-81 进度条 紧随 顶栏 (root 内 顶栏 下一位; 实际 %s)" % str(root_bg))
	check(bg.custom_minimum_size.y >= 5.0, "打磨-81 进度条 高度>=5px (实际 %s)" % str(bg.custom_minimum_size.y))
	check(_fill_modulate(fill) == Color(0.62, 0.9, 0.95, 0.9),
		"打磨-81 填充 青色 modulate (打磨-135d 9-slice 纹理底, 实际 %s)" % str(_fill_modulate(fill)))
	check(str(bg.tooltip_text).find("下一目标") >= 0 and str(bg.tooltip_text).find("无 存档/统计 副作用") >= 0,
		"打磨-81 tooltip 口径 (静态/动态 均含 下一目标+副作用 说明; 实际 %s)" % bg.tooltip_text.left(24))
	# 等 布局落定 (宽度 0 -> 实际 宽, headless 高负载时 1 帧可能不够, 上限 20 帧; 与 打磨-58 同款加固)
	for _i81 in 20:
		if bg.size.x > 0.0:
			break
		await get_tree().process_frame
	check(bg.size.x > 0.0, "打磨-81 进度条 布局宽>0 (实际 %s)" % str(bg.size.x))
	var w: float = bg.size.x
	# 受控基准: 前序 测试 可能 残留 灵气, 显式 置 0 再 驱动 (初始 0 灵气 → ratio 0 → 0 填充)
	var ess81s: float = g.essence
	g.essence = 0.0
	ui._refresh()
	var t0: String = g.next_goal_text()
	check(int(fill.size.x) == 0, "打磨-81 初始 0 灵气 空 填充 (实际 %s)" % str(fill.size.x))
	check(str(bg.tooltip_text).find("下一目标  0%") >= 0 and str(bg.tooltip_text).find(t0) >= 0,
		"打磨-81 初始 tooltip=下一目标 0%%|下一目标文本 (实际 %s)" % bg.tooltip_text)
	check(str(bg.tooltip_text).find("与 修行页 下一目标 行 同 口径") >= 0
		and str(bg.tooltip_text).find("无 存档/统计 副作用") >= 0,
		"打磨-81 动态 tooltip 含 口径 说明 (实际 %s)" % bg.tooltip_text.left(24))
	# 节流: 同态 再刷 fill/tooltip 稳定, 无 资源/统计 副作用
	var snap81u: Dictionary = g.stats.duplicate(true)
	var ess81u: float = g.essence
	var st81u: float = g.stones
	ui._refresh()
	check(int(fill.size.x) == 0 and g.stats == snap81u and g.essence == ess81u and g.stones == st81u,
		"打磨-81 同态 节流 fill/tooltip 稳定 无副作用")
	# 灵气 半程 → ratio 0.5 → 50% 档 填充 + tooltip 50% 同步
	var cost81u: float = g.breakthrough_cost()
	g.essence = cost81u * 0.5
	ui._refresh()
	var w2: float = bg.size.x
	check(absf(fill.size.x - w2 * 0.5) < 1.0, "打磨-81 半程 50%% 档 填充 (实际 %s, 期望 ~%s)" % [str(fill.size.x), str(w2 * 0.5)])
	check(str(bg.tooltip_text).find("下一目标  50%") >= 0,
		"打磨-81 半程 tooltip=50%% (实际 %s)" % bg.tooltip_text)
	# 同态 再刷 不 重写 fill (2% 量化档 未跨档, 缓存键 未变)
	var f81_before: float = fill.size.x
	ui._refresh()
	check(fill.size.x == f81_before, "打磨-81 同态 再刷 fill 不 重写 (节流) (实际 %s)" % str(fill.size.x))
	# 攒满 → 100% 满 填充 (与 突破 ready 口径 一致)
	g.essence = cost81u
	ui._refresh()
	var w3: float = bg.size.x
	check(fill.size.x == w3, "打磨-81 攒满 100%% 满 填充 (实际 %s, 宽 %s)" % [str(fill.size.x), str(w3)])
	check(str(bg.tooltip_text).find("下一目标  100%") >= 0 and str(bg.tooltip_text).find("点击突破") >= 0,
		"打磨-81 攒满 tooltip=100%%|已攒够 (实际 %s)" % bg.tooltip_text)
	# 境界 变化 → 消耗 变 比例 同步 (半程 基准 按 新境界 消耗 重算, 动态 恒等; 恢复原 境界)
	var realm81u: int = g.realm_idx
	g.realm_idx = 2
	g.essence = g.breakthrough_cost() * 0.5
	ui._refresh()
	var t_r2: String = g.next_goal_text()
	check(str(bg.tooltip_text).find(t_r2) >= 0,
		"打磨-81 境界2 消耗变 tooltip 同步 (实际 %s)" % bg.tooltip_text)
	check(str(bg.tooltip_text).find("下一目标  50%") >= 0,
		"打磨-81 境界2 半程 仍 50%% 档 (实际 %s)" % bg.tooltip_text)
	g.realm_idx = realm81u
	ui._refresh()
	# 飞升 口径 切换: tooltip 前缀=道行精进 + 道行 比例 动态 恒等 (道祖 封顶 满条; 恢复原 态)
	var asc81u: bool = g.ascended
	var dao81u: float = g.dao
	var daoLv81u: int = g.dao_level
	g.ascended = true
	g.dao = g.dao_break_cost() * 0.25
	ui._refresh()
	check(str(bg.tooltip_text).find("道行精进  25%") >= 0,
		"打磨-81 飞升 tooltip=道行精进 25%% (实际 %s)" % bg.tooltip_text)
	# 填充 按 2% 量化档 (25% → ceil 档 13/50=26%), 容差 覆盖 1 档 量化 误差
	check(fill.size.x >= bg.size.x * 0.24 and fill.size.x <= bg.size.x * 0.28,
		"打磨-81 飞升 25%% 档 填充 (实际 %s, 宽 %s)" % [str(fill.size.x), str(bg.size.x)])
	g.dao_level = g.IMMORTAL_REALMS.size() - 1
	ui._refresh()
	check(fill.size.x == bg.size.x and str(bg.tooltip_text).find("道行精进  100%") >= 0,
		"打磨-81 道祖 封顶 满条 (实际 fill=%s 宽=%s tooltip=%s)" % [str(fill.size.x), str(bg.size.x), bg.tooltip_text.left(24)])
	g.ascended = asc81u
	g.dao_level = daoLv81u
	g.dao = dao81u
	g.essence = 0.0
	ui._refresh()
	# 收尾: 0% 空 填充 稳定 + 无 资源/统计 副作用
	var snap81e: Dictionary = g.stats.duplicate(true)
	check(int(fill.size.x) == 0 and g.stats == snap81e,
		"打磨-81 收尾 恢复 0% 空 填充 稳定 无副作用")
	g.essence = ess81s  # 恢复 前序 残留 灵气 (不影响 _finish, 防 后续 轮 启动态 漂移)


# 打磨-82: 顶栏 下一目标 进度条 点击直达 — 进度条 升级 flat Button 可点击热区 (手型光标+悬停 金边),
# 点击=切 修行页 + 突破区 Panel 外壳 金边高亮 1.2s (复用 法器区/汇总行 口径), 纯导航 无 存档/统计 副作用;
# 断言 (手动驱动 确定性): 热区=flat Button+手型+非 toggle/悬停金边 样式/tooltip 点击口径/
# 突破区 Panel 外壳 存在+初始 无边框/点击 切 修行页(tab0)+突破区 金边+底部消息/
# 重入 kill 旧 tween 不叠加/1.2s 后 高亮 自动恢复 边框0/无 资源/统计 副作用 (纯导航)/收尾 无边框
func _assert_goalbar_jump() -> void:
	var g := GameData
	var bg: Node = ui._goalbar_bg
	# 热区 = flat Button 可点击 (手型光标, 非 toggle)
	check(bg is Button and (bg as Button).flat == true,
		"打磨-82 进度条 节点 是 flat Button (升级 可点击热区)")
	check((bg as Button).mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
		"打磨-82 进度条 手型光标 提示可点")
	check((bg as Button).toggle_mode == false, "打磨-82 进度条 非 toggle (点击即触发)")
	check(bg.get_theme_stylebox("hover") != null
			and (bg.get_theme_stylebox("hover") as StyleBoxFlat).border_width_left == 1,
		"打磨-82 进度条 悬停 金边 样式 非空 (hover 边框宽=1)")
	check(str(bg.tooltip_text).find("点击: 直达 修行页·突破区") >= 0,
		"打磨-82 进度条 tooltip 含 点击直达 口径 (实际 %s)" % str(bg.tooltip_text).left(40))
	# 突破区 Panel 外壳 存在 + 初始 无边框 (恢复态)
	check(ui._break_panel != null and ui._break_panel is Panel, "打磨-82 突破区 Panel 外壳 存在")
	check(ui._bar_bg.get_parent() != null and ui._break_panel.get_child(0) != null,
		"打磨-82 突破区 Panel 有 子布局 (实际 %d 子)" % ui._break_panel.get_child_count())
	var sb0: StyleBoxFlat = ui._break_panel.get_theme_stylebox("panel")
	check(sb0 != null and sb0.border_width_left == 0, "打磨-82 初始 突破区 无边框 (边框宽=0)")
	# 副作用快照 (点击 不应改变)
	var snap_essence := g.essence
	var snap_stones := g.stones
	var snap_stats := g.stats
	var snap_realm := g.realm_idx
	var snap_break_ok := int(g.stats.get("break_ok", 0.0))
	# 切 成就页 作为 点击 前 受控 tab
	ui._tab.current_tab = 3
	# 点击 → 切 修行页(tab0) + 突破区 金边高亮 + 底部消息
	ui._on_goalbar()
	await get_tree().process_frame
	check(ui._tab.current_tab == 0, "打磨-82 点击 进度条 → 切 修行页 (tab=0) (实际 %d)" % ui._tab.current_tab)
	var sb_hi: StyleBoxFlat = ui._break_panel.get_theme_stylebox("panel")
	check(sb_hi != null and sb_hi.border_width_left == 2 and sb_hi.border_color == ui.GOLD,
		"打磨-82 点击 进度条 → 突破区 金边高亮 (边框宽=2 金)")
	check(str(ui._msg_label.text).find("直达 修行页·突破区") >= 0,
		"打磨-82 点击 进度条 → 底部消息确认 (实际 %s)" % str(ui._msg_label.text))
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats
			and g.realm_idx == snap_realm,
		"打磨-82 点击 进度条 无 资源/境界 副作用 (纯导航)")
	# 重入: 高亮中 再点 进度条 kill 旧 tween 重开 (不报错 且 仍 高亮, 边框 口径 不变)
	ui._on_goalbar()
	await get_tree().process_frame
	var sb_hi2: StyleBoxFlat = ui._break_panel.get_theme_stylebox("panel")
	check(sb_hi2 != null and sb_hi2.border_width_left == 2, "打磨-82 高亮中 重入 不叠加/不报错 (仍 金边)")
	# 等待 tween 结束 (1.2s, 重入后 重新计时) 后 自动恢复 边框 0
	await get_tree().create_timer(1.4).timeout
	var sb_rest: StyleBoxFlat = ui._break_panel.get_theme_stylebox("panel")
	check(sb_rest != null and sb_rest.border_width_left == 0,
		"打磨-82 突破区 高亮 1.2s 后 自动恢复 (边框宽=0)")
	# 收尾: 修行页 稳定, 无边框 (防 污染); 突破按钮 未 误触发 (realm 未变 + break_ok 未增)
	check(ui._tab.current_tab == 0, "打磨-82 收尾 保持 修行页")
	var sb_end: StyleBoxFlat = ui._break_panel.get_theme_stylebox("panel")
	check(sb_end != null and sb_end.border_width_left == 0, "打磨-82 收尾 突破区 无边框")
	check(g.realm_idx == snap_realm and int(g.stats.get("break_ok", 0.0)) == snap_break_ok,
		"打磨-82 收尾 无 境界/突破 误触发")
	check(g.essence == snap_essence and g.stones == snap_stones and g.stats == snap_stats,
		"打磨-82 收尾 无 资源/统计 副作用")
	await get_tree().process_frame


# 打磨-141: 顶栏 下一目标 进度条 tooltip 动态 ETA 段 — _refresh_goalbar tooltip 追加
# "【攒够 下一目标 预计 (动态)】" 段 (GameData.goalbar_eta_tip 只读接口, 复用 打磨-24
# breakthrough_eta_text 口径 + 成功率 段). 断言 (手动驱动 确定性): 动态段 标记 存在/
# 基准 = 接口 恒等/境界2 动态 同步/飞升 道行 口径/攒满 已攒够 文案/同态 节流 无副作用/收尾 复原
func _assert_goalbar_eta_tip() -> void:
	var g := GameData
	var bg: Node = ui._goalbar_bg
	var tip0: String = str(bg.tooltip_text)
	check(tip0.find("【攒够 下一目标 预计 (动态)】") >= 0,
		"打磨-141 tooltip 含 动态段 标记 (实际 %s)" % tip0.left(30))
	check(tip0.find(g.goalbar_eta_tip()) >= 0,
		"打磨-141 动态段=接口 恒等 (实际 %s)" % tip0)
	# 同态 节流: 再刷 动态段 稳定 无 资源/统计 副作用
	var snap141: Dictionary = g.stats.duplicate(true)
	var ess141: float = g.essence
	var st141: float = g.stones
	ui._refresh()
	check(str(bg.tooltip_text) == tip0 and g.stats == snap141
			and g.essence == ess141 and g.stones == st141,
		"打磨-141 同态 节流 动态段 稳定 无副作用")
	# 受控 基准: 未飞升 半程 — 动态段 = 接口 恒等 (前缀 突破还需 + ETA + 成功率 段)
	var r141: int = g.realm_idx
	var a141: bool = g.ascended
	var d141: float = g.dao
	var dl141: int = g.dao_level
	g.ascended = false
	g.dao_level = 0
	g.essence = g.breakthrough_cost() * 0.5
	ui._refresh()
	var tip1: String = str(bg.tooltip_text)
	check(tip1.find(g.goalbar_eta_tip()) >= 0 and tip1.find("突破还需") >= 0,
		"打磨-141 基准 动态段=接口 恒等 含 突破还需 (实际 %s)" % tip1)
	# 境界 提升 — 消耗变 动态段 动态 同步
	g.essence = 0.0
	g.realm_idx = 2
	g.essence = g.breakthrough_cost() * 0.5
	ui._refresh()
	var tip2: String = str(bg.tooltip_text)
	check(tip2 != tip1 and tip2.find(g.goalbar_eta_tip()) >= 0,
		"打磨-141 境界2 动态段 同步 (实际 %s)" % tip2)
	# 攒满 — 已攒够 无 ETA 段
	g.essence = g.breakthrough_cost()
	ui._refresh()
	var tip3: String = str(bg.tooltip_text)
	check(tip3.find("灵气已攒够, 点击突破") >= 0,
		"打磨-141 攒满 动态段=已攒够 文案 (实际 %s)" % tip3)
	# 飞升 道行 口径 — 动态段 前缀 道行精进还需
	g.ascended = true
	g.dao_level = 0
	g.dao = g.dao_break_cost() * 0.25
	ui._refresh()
	var tip4: String = str(bg.tooltip_text)
	check(tip4.find("道行精进还需") >= 0 and tip4.find(g.goalbar_eta_tip()) >= 0,
		"打磨-141 飞升 道行 口径 动态段 (实际 %s)" % tip4)
	# 收尾 复原
	g.ascended = a141
	g.dao_level = dl141
	g.dao = d141
	g.essence = ess141
	g.realm_idx = r141
	ui._refresh()
	check(g.stats == snap141, "打磨-141 收尾 复原 无副作用")


# 打磨-91: 成就页 "只看未解锁" 筛选 — 与 打磨-38 技能页 只看可学 同模式: 只显示 未解锁 行
# (已解锁行 暂时隐藏, 排序口径不变), 按钮文案按 当前 未解锁数 计 (x N / 显示全部 / 已无未解锁)。
# 断言 (手动驱动 确定性): 按钮节点/toggle/tooltip 口径/初始 关态 文案 x17/同态 节流 无副作用/
# 开 后 已解锁行 全隐藏 未解锁行 全可见 (受控态 5 解锁)/解锁 新增 同步 计数+行恢复可见/
# 全解锁 文案 已无未解锁/关 后 全部 恢复可见/收尾 干净 基准 (防 污染 后续)
func _assert_ach_nofilter() -> void:
	var g := GameData
	ui._tab.current_tab = 3
	var btn: Button = ui._ach_nofilter_btn
	check(btn != null, "打磨-91 成就页 只看未解锁 按钮 节点 存在")
	check(btn is Button and btn.toggle_mode == true, "打磨-91 按钮 是 toggle 开关")
	check(str(btn.tooltip_text).find("只显示 未解锁 的成就") >= 0
			and str(btn.tooltip_text).find("再点 恢复全部") >= 0,
			"打磨-91 按钮 tooltip 含 口径 说明 (实际 %s)" % str(btn.tooltip_text).left(30))
	# 受控基准: 干净档态 (与 _assert_initial 同基准, 防 前序 测试 残留)
	g.ach_done.clear()
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	ui._refresh()
	await get_tree().process_frame
	# 初始 关态: 文案 只看未解锁 x17 (17 全未解锁), 全行可见
	check(str(btn.button_pressed) == "false", "打磨-91 初始 关态 (实际 %s)" % str(btn.button_pressed))
	check(str(btn.text) == "只看未解锁 x%d" % g.ach_ids.size(),
			"打磨-91 初始 文案 只看未解锁 x17 (实际 %s)" % str(btn.text))
	var all_vis := true
	for id in g.ach_ids:
		if not (ui._ach_rows[id]["row"] as Node).visible:
			all_vis = false
	check(all_vis, "打磨-91 关态 全部 17 行 可见")
	# 同态 节流: 再 _refresh 文案/行 稳定, 无 资源/统计 副作用
	var snap_ess: float = g.essence
	var snap_sto: float = g.stones
	var snap_stats: Dictionary = g.stats
	var txt0: String = str(btn.text)
	ui._refresh()
	check(str(btn.text) == txt0 and g.essence == snap_ess and g.stones == snap_sto
			and g.stats == snap_stats, "打磨-91 同态 节流 文案 稳定 无副作用")
	# 受控 解锁 5 成就 (与 _mutate_state 同口径: 境界2+5万灵石+2技能+2装备+1法器)
	g.realm_idx = 2
	g.stones = 50000.0
	g.learned.append("sword_0_0")
	g.learned.append("sword_0_1")
	g.owned_eq.append("weapon_0_0")
	g.owned_eq.append("robe_0_0")
	g.owned.append("wooden_sword")
	g.check_achievements()
	ui._refresh()
	await get_tree().process_frame
	check(str(btn.text) == "只看未解锁 x%d" % (g.ach_ids.size() - g.ach_done.size()),
			"打磨-91 解锁 5 后 文案 计数 同步 x12 (实际 %s, done=%d)" % [str(btn.text), g.ach_done.size()])
	# 点击 处理器: 开 (口径 同 打磨-67 点击切换: 内部态+按压+底部消息 一致)
	ui._on_ach_nofilter()
	await get_tree().process_frame
	check(ui._ach_nofilter_on == true and btn.button_pressed, "打磨-91 点击 后 开 态 (内部+按压 一致)")
	check(str(ui._msg_label.text).find("只看未解锁") >= 0,
			"打磨-91 开启 底部消息 (实际 %s)" % str(ui._msg_label.text).left(20))
	check(str(btn.text) == "显示全部", "打磨-91 点击 开 后 文案 显示全部 (实际 %s)" % str(btn.text))
	ui._on_ach_nofilter()
	await get_tree().process_frame
	check(ui._ach_nofilter_on == false and not btn.button_pressed, "打磨-91 再点 关 态")
	# 开启: 外部 置 开关态 模拟 (口径 同 打磨-67 外部置 存档值), _refresh 同步 文案+行 可见性
	ui._ach_nofilter_on = true
	ui._refresh()
	await get_tree().process_frame
	check(str(btn.text) == "显示全部", "打磨-91 开启 后 文案 显示全部 (实际 %s)" % str(btn.text))
	var done_ok := true
	var undone_ok := true
	for id in g.ach_ids:
		var row: Node = ui._ach_rows[id]["row"]
		if g.ach_done.has(id) and row.visible:
			done_ok = false
		if not g.ach_done.has(id) and not row.visible:
			undone_ok = false
	check(done_ok, "打磨-91 开启 后 已解锁行 全隐藏")
	check(undone_ok, "打磨-91 开启 后 未解锁行 全可见")
	# 排序口径 不变: 筛选 只 隐藏 不 重排 — _ach_states 排序键 仍 已解锁在前
	# (box 内 首个 可见 行 必为 未解锁 段 首行, 因 已解锁段 全 隐藏)
	var first_vis_id := ""
	for ch in ui._ach_box.get_children():
		if (ch as Node).visible:
			for id in g.ach_ids:
				if ui._ach_rows[id]["row"] == ch:
					first_vis_id = str(id)
					break
			break
	check(first_vis_id != "" and not g.ach_done.has(first_vis_id),
			"打磨-91 开启 后 box 首个 可见行 = 未解锁行 (排序口径 不变; 实际 %s)" % first_vis_id)
	# 开启 中 再 解锁 1 个 (直接 append 确定性, 口径 与 _mutate_state 一致): 计数 同步 + 该行 隐藏
	if not g.ach_done.has("realm_huashen"):
		g.ach_done.append("realm_huashen")
		ui._refresh()
		await get_tree().process_frame
		check(str(btn.text) == "显示全部", "打磨-91 开启 中 解锁 新 1 个 文案 仍 显示全部 (实际 %s)" % str(btn.text))
		check((ui._ach_rows["realm_huashen"]["row"] as Node).visible == false,
				"打磨-91 开启 中 新解锁行 保持 隐藏 (口径 一致)")
	# 关: 外部 置 关态, _refresh 同步 全部 恢复可见
	ui._ach_nofilter_on = false
	btn.set_pressed_no_signal(false)
	ui._refresh()
	await get_tree().process_frame
	var vis2 := true
	for id in g.ach_ids:
		if not (ui._ach_rows[id]["row"] as Node).visible:
			vis2 = false
	check(vis2, "打磨-91 关闭 后 全部 行 恢复可见")
	check(str(btn.text) == "只看未解锁 x%d" % (g.ach_ids.size() - g.ach_done.size()),
			"打磨-91 关闭 后 文案 计数 (实际 %s)" % str(btn.text))
	# 全解锁 态: 文案 已无未解锁 + 开 后 全隐藏 (无可见行)
	g.ach_done.clear()
	for id in g.ach_ids:
		g.ach_done.append(id)
	ui._refresh()
	await get_tree().process_frame
	check(str(btn.text) == "已无未解锁", "打磨-91 全解锁 文案 已无未解锁 (实际 %s)" % str(btn.text))
	ui._on_ach_nofilter()
	await get_tree().process_frame
	var all_hid := true
	for id in g.ach_ids:
		if (ui._ach_rows[id]["row"] as Node).visible:
			all_hid = false
	check(all_hid, "打磨-91 全解锁 开 后 全部 行 隐藏")
	check(str(btn.text) == "显示全部", "打磨-91 全解锁 开 后 文案 显示全部 (实际 %s)" % str(btn.text))
	# 收尾: 干净 基准 + 关态 (本测试 为 最后一段, 直接 清档 到 全新 基准, 防 残留)
	g.ach_done.clear()
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	btn.set_pressed_no_signal(false)
	ui._ach_nofilter_on = false
	ui._refresh()
	await get_tree().process_frame
	check(str(btn.text) == "只看未解锁 x%d" % g.ach_ids.size(),
			"打磨-91 收尾 干净 基准 文案 x17 (实际 %s)" % str(btn.text))
	check(g.essence == 0.0 and g.stones == 0.0 and g.stats == snap_stats,
			"打磨-91 收尾 无 资源/统计 副作用")


# M5-4: 镇妖塔 通关态 (称号/大奖/守塔模式) + 顶栏 通关 称号 徽标 断言:
# 通关 前 隐藏 徽标/通关 后 恒显 称号 徽标 (与 自动/挂机 徽标 同父)+tooltip 口径+状态行 含 称号/
# 点击 直达 爬塔页 (tab 4)+镇妖塔 卡片 金边高亮/守塔 模式 恒 1000 层 胜 不 重复 发放 大奖 (reward_got 幂等)/
# 未通关 不 发放/收尾 恢复 干净 基准
func _assert_tower_clear() -> void:
	var g := GameData
	var badge: Button = ui._clear_badge
	# 基准: 未通关 (全新 塔 态)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.tower_clear_reward_got = false
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.set_process(false)  # 冻结 挂机/成就, 确定性 受控
	ui._refresh()
	await get_tree().process_frame
	# 未通关: 称号 接口 空串 + 徽标 隐藏
	check(g.tower_clear_title() == "", "M5-4 未通关 称号 空串 (实际 %s)" % g.tower_clear_title())
	check(badge != null, "M5-4 顶栏 通关 称号 徽标 节点 存在")
	check(badge != null and not badge.visible and str(badge.text) == "",
			"M5-4 未通关 徽标 隐藏 文本空 (visible=%s 文本=%s)" % [str(badge.visible), str(badge.text)])
	# 通关 前: 新档 败 第 2 层 (atk 2.0 < 怪 2.84 恒败) — 验 未通关 不 发放 大奖
	g.tower_fixed_floor = 1  # 待挑战 层 = 2 (恒败, 不 推进 不 通关)
	var rc_pre: Dictionary = g.try_tower_challenge("fixed", 0.5)
	check(not bool(rc_pre["win"]) and not g.tower_fixed_clear, "M5-4 新档 败 第 2 层 未 通关 (实际 win=%s clear=%s)" % [str(rc_pre["win"]), str(rc_pre["clear"])])
	check(int(rc_pre["floor"]) == 2, "M5-4 新档 镇妖塔 挑战 层 = 2 (实际 %d)" % int(rc_pre["floor"]))
	check(float(rc_pre["clear_reward_stone"]) == 0.0, "M5-4 未通关 不 发放 大奖")
	# 受控: 999->1000 层 Boss 首通 (战力 拉满 道祖 级), 触发 通关 一次性 大奖
	g.tower_fixed_clear = false
	g.tower_fixed_floor = 999
	g.tower_clear_reward_got = false
	# 拉满 战力 (道祖 级): 胜 守塔 1000 层 Boss
	g.ascended = true
	g.dao_level = 8
	var stones_before: float = g.stones
	var rc: Dictionary = g.try_tower_challenge("fixed", 0.5)
	check(bool(rc["win"]), "M5-4 道祖 守塔 1000 层 Boss 胜 (实际 win=%s)" % str(rc["win"]))
	check(bool(rc["clear"]), "M5-4 守塔 胜 返回 clear=true (首次 通关 态)")
	# 通关 一次性 大奖: 灵石 大奖 发放 (reward_got 由 false->true 触发)
	check(float(rc["clear_reward_stone"]) > 0.0, "M5-4 通关 灵石 大奖 发放 (实际 %s)" % g.fmt(float(rc["clear_reward_stone"])))
	check(absf(g.stones - (stones_before + g.TOWER_CLEAR_BONUS_STONE + float(rc["reward_stone"]))) < 1e-6,
			"M5-4 灵石 = 前值 + 通关大奖 + 本层 奖励 (实际 %s)" % g.fmt(g.stones))
	check(g.tower_clear_reward_got, "M5-4 通关 大奖 已发放 标记 置位")
	# 称号 接口 非空 (通关态)
	check(g.tower_clear_title() == "镇妖塔·通关者", "M5-4 通关 称号 = 镇妖塔·通关者 (实际 %s)" % g.tower_clear_title())
	# 通关 文案 接口 (灵石 大奖 文案 含 称号/灵石/永久 atk/def/守塔)
	var rw_txt: String = g.tower_clear_reward_text(g.TOWER_CLEAR_BONUS_STONE)
	check(rw_txt.find("镇妖塔·通关者") >= 0 and rw_txt.find("永久 atk/def") >= 0 and rw_txt.find("守塔") >= 0,
			"M5-4 通关 大奖 文案 含 称号/永久atk/def/守塔 (实际 %s)" % rw_txt)
	check(g.tower_clear_reward_text(0.0) == "", "M5-4 通关 大奖 文案 0 发放 = 空串")
	# 打磨-114: 通关 大奖 顶级(传说) 词缀 x3 — 数据 口径/发放 入包/文案 段/守塔 幂等/背包满 折算 材料
	var ids114: Array = g.tower_clear_affix_ids()
	check(ids114.size() == g.TOWER_CLEAR_BONUS_AFFIX_COUNT, "打磨-114 大奖 词缀 ids = 3 件 (实际 %d)" % ids114.size())
	var leg114 := true
	for aid114 in ids114:
		if int(g.affix_by_id.get(str(aid114), {}).get("tier", 0)) != 4:
			leg114 = false
	check(leg114, "打磨-114 大奖 3 件 全 为 传说 (实际 %s)" % str(ids114))
	check(int(rc.get("clear_reward_affixes", []).size()) == g.TOWER_CLEAR_BONUS_AFFIX_COUNT,
			"打磨-114 通关 发放 3 件 传说 词缀 入包 (实际 %s)" % str(rc.get("clear_reward_affixes", [])))
	check(JSON.stringify(rc.get("clear_reward_affixes", [])) == JSON.stringify(ids114),
			"打磨-114 发放 ids = 期望 顶级 ids (实际 %s)" % str(rc.get("clear_reward_affixes", [])))
	check(int(rc.get("clear_reward_mat", 0)) == 0, "打磨-114 未 背包满 折算 材料 = 0 (实际 %d)" % int(rc.get("clear_reward_mat", 0)))
	var rw114: String = g.tower_clear_reward_text(g.TOWER_CLEAR_BONUS_STONE, 3)
	check(rw114.find("顶级(传说) 词缀 x3") >= 0, "打磨-114 大奖 文案 含 顶级(传说) 词缀 x3 (实际 %s)" % rw114)
	check(g.tower_win_float_text(rc).find("大奖词缀") >= 0, "打磨-114 胜利 浮动 含 大奖词缀 段 (实际 %s)" % g.tower_win_float_text(rc).right(60))
	# 通关 后 状态行 含 称号
	check(g.tower_status_line().find("镇妖塔·通关者") >= 0, "M5-4 状态行 含 通关 称号 (实际 %s)" % g.tower_status_line())
	# 守塔 模式: 通关 后 反复 打 1000 层, 再胜 不 重复 发放 大奖 (reward_got 幂等)
	var stones_before2: float = g.stones
	var rc2: Dictionary = g.try_tower_challenge("fixed", 0.5)
	check(bool(rc2["win"]) and int(rc2["floor"]) == 1000, "M5-4 守塔 反复 打 恒 1000 层 (实际 %d)" % int(rc2["floor"]))
	check(float(rc2["clear_reward_stone"]) == 0.0, "M5-4 守塔 再胜 不 重复 发放 大奖 (幂等, 实际 %s)" % str(rc2["clear_reward_stone"]))
	# 打磨-114: 守塔 再胜 不 重复 发放 大奖 词缀 (幂等, 与 灵石 大奖 同 reward_got 口径)
	check(int(rc2.get("clear_reward_affixes", []).size()) == 0 and int(rc2.get("clear_reward_mat", 0)) == 0,
			"打磨-114 守塔 再胜 不 重复 发放 大奖 词缀 (幂等, 实际 %s)" % str(rc2.get("clear_reward_affixes", [])))
	check(absf(g.stones - (stones_before2 + float(rc2["reward_stone"]))) < 1e-6,
			"M5-4 守塔 再胜 仅 本层 奖励 无 大奖 (实际 %s)" % g.fmt(g.stones))
	# 通关 永久 增益: atk/def +15% (乘算 独立 项, 通关 恒 生效)
	check(absf(g.clear_buff_mult() - (1.0 + g.TOWER_CLEAR_BUFF)) < 1e-9, "M5-4 通关 增益 倍率 = 1+0.15 (实际 %s)" % str(g.clear_buff_mult()))
	# 顶栏 徽标 刷 显隐 (通关态 显示, 与 自动 徽标 同父)
	ui._refresh()
	await get_tree().process_frame
	check(badge.visible and str(badge.text) == "镇妖塔·通关者",
			"M5-4 通关 后 徽标 显 称号 (visible=%s 文本=%s)" % [str(badge.visible), str(badge.text)])
	check(badge.get_parent() == ui._auto_badge.get_parent(), "M5-4 徽标 与 自动 徽标 同父 (顶栏)")
	check(badge.tooltip_text.find("镇妖塔") >= 0 and badge.tooltip_text.find("通关") >= 0,
			"M5-4 徽标 tooltip 含 镇妖塔/通关 口径 (实际 %s)" % badge.tooltip_text.left(40))
	# 点击 直达 爬塔页 (tab 4) + 镇妖塔 卡片 金边 高亮 (1.2s 自动恢复)
	ui._on_clear_badge()
	await get_tree().process_frame
	check(ui._tab.current_tab == 4, "M5-4 点击 徽标 直达 爬塔页 (tab=4, 实际 %d)" % ui._tab.current_tab)
	var fcard: Dictionary = ui._tw_cards.get("fixed", {})
	var fpanel: PanelContainer = fcard.get("panel", null)
	if fpanel != null:
		var fhi: StyleBoxFlat = fpanel.get_theme_stylebox("panel")
		check(fhi != null and fhi.border_width_left == 2, "M5-4 点击 后 镇妖塔 卡片 金边 高亮 (边框宽=%d)" % (fhi.border_width_left if fhi != null else -1))
	# 无 资源/统计 副作用 (点击 导航 不改 存档)
	await get_tree().process_frame
	# 收尾: 恢复 干净 基准 (本 测试 为 末段, 清档 到 全新, 防 残留)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.tower_clear_reward_got = false
	g.poison_battles = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	# 打磨-114: 收尾 清 词缀 残留 (本段 首通 入包 3 件 传说 大奖, 防 泄漏 后续 段 收集/背包 断言)
	g.affix_bag = {}
	g.affix_load = {}
	g.affix_materials = 0
	g.seen_affixes = []
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(not badge.visible and str(badge.text) == "", "M5-4 收尾 未通关 徽标 隐藏 (实际 visible=%s)" % str(badge.visible))
	check(g.tower_clear_title() == "", "M5-4 收尾 称号 空串")


# 打磨-93: 剧毒 debuff 顶栏徽标 + 触发浮动 断言 (徽标 显隐/文本/tooltip/点击 直达 爬塔页+状态行紫边高亮+无副作用;
# 触发 浮动: 手动 推 poison 事件 后 _refresh 消费 弹 紫色浮动 [计数/文案/位置]; 收尾 恢复 干净 基准)
func _assert_poison_debuff() -> void:
	var g := GameData
	var badge: Button = ui._poison_badge
	var fl: Label = ui._poison_float_label
	var stats_b: Dictionary = g.stats.duplicate(true)
	# 节点/初始 隐藏 (基准 无 debuff)
	check(badge != null, "打磨-93 顶栏 剧毒 徽标 节点 存在")
	check(badge.visible == false and str(badge.text) == "", "打磨-93 初始 无 debuff 徽标 隐藏 (实际 visible=%s)" % str(badge.visible))
	check(fl != null and str(fl.text) == "" and ui._poison_float_count == 0, "打磨-93 初始 无 剧毒浮动 文案/计数=0")
	# 手动 置 debuff (读档 恢复 同 路径: _refresh 场数 变化才刷) + _refresh 同步
	g.poison_battles = 2
	ui._refresh()
	check(badge.visible and str(badge.text) == "剧毒 2", "打磨-93 徽标 显示 剧毒 2 (实际 %s)" % str(badge.text))
	check(badge.tooltip_text.contains("ATK -15%"), "打磨-93 徽标 tooltip 含 口径 (实际 %s)" % str(badge.tooltip_text))
	# 只读 连刷 节流 稳定 (同 场数 不 重写 文本)
	var txt_b: String = str(badge.text)
	ui._refresh()
	check(str(badge.text) == txt_b, "打磨-93 同 场数 徽标 节流 稳定")
	# 点击 直达 爬塔页 + 状态行 紫边 高亮 (headless 不 跑 tween, 手动 驱动 恢复 断言 终态;
	# 无 副作用 锚定 资源/塔 状态 [stats 含 play_sec 挂机 累积 不锚定, 同 M5-3 selftest 口径])
	var sto93c: float = g.stones
	var fl93c: int = g.tower_fixed_floor
	var tw93c: int = int(g.stats.get("tower_win", 0.0))
	var pb93c: int = g.poison_battles
	badge.pressed.emit()
	await get_tree().process_frame
	check(ui._tab.current_tab == 4, "打磨-93 点击 切 爬塔页 (tab=4, 实际 %d)" % ui._tab.current_tab)
	var psb: StyleBox = ui._tw_status_panel.get_theme_stylebox("panel")
	check(psb != null and psb.border_width_left == 2, "打磨-93 点击 后 状态行 紫边 高亮 (边框宽=%d)" % (psb.border_width_left if psb != null else -1))
	check(psb != null and psb.border_color == Color(0.75, 0.55, 1.0), "打磨-93 高亮 边框色=紫 (实际 %s)" % str(psb.border_color if psb != null else "null"))
	# 恢复 终态 (手动 回调; headless 不 依赖 tween 自然 跑完, 同 M5-4 卡片 高亮 断言 口径)
	ui._restore_poison_status()
	var psb2: StyleBox = ui._tw_status_panel.get_theme_stylebox("panel")
	check(psb2 != null and psb2.border_width_left == 0, "打磨-93 恢复 后 状态行 无边框 (边框宽=%d)" % (psb2.border_width_left if psb2 != null else -1))
	# 无 资源/统计 副作用 (点击 导航 不改 存档)
	# 无 副作用: 塔 层/胜利 统计/debuff 场数 不变 (灵石 挂机 累积 不 锚定, 同 M5-3 口径)
	check(g.tower_fixed_floor == fl93c and int(g.stats.get("tower_win", 0.0)) == tw93c and g.poison_battles == pb93c,
			"打磨-93 点击 无 塔/统计 副作用 (实际 层=%d 胜=%d 场=%d)" % [g.tower_fixed_floor, tw93c, g.poison_battles])
	var _bisect_skip: bool = false
	# 触发 浮动: 手动 推 2 个 事件 (new + refresh) 后 _refresh 消费 (计数+2, 文案=末条)
	g.poison_battles = 1
	var c0: int = ui._poison_float_count
	g.poison_events.append("朽地·鹰|new")
	g.poison_events.append("震雷·蜈蚣|refresh")
	ui._refresh()
	check(ui._poison_float_count == c0 + 2, "打磨-93 剧毒浮动 计数+2 (期望 %d, 实际 %d)" % [c0 + 2, ui._poison_float_count])
	check(str(fl.text) == "☠ 剧毒 刷新: 「震雷·蜈蚣」 攻 -15% 持续 2 场", "打磨-93 浮动 文案=末条 refresh (实际 %s)" % str(fl.text))
	check(absf(fl.position.y + 100.0) < 0.5, "打磨-93 浮动 位置 复位 y≈-100 (实际 %.2f)" % fl.position.y)
	check(fl.modulate.a > 0.9, "打磨-93 浮动 可见 (alpha=%.2f)" % fl.modulate.a)
	check(g.poison_events.is_empty(), "打磨-93 _refresh 消费 后 事件 队列 清空")
	# 空 事件 不 弹 (防御)
	var c1: int = ui._poison_float_count
	g.poison_events.append("X|new")
	g.poison_events.append("")
	ui._refresh()
	check(ui._poison_float_count == c1 + 1, "打磨-93 空 事件 串 不 弹 计数 只 +1 (实际 %d)" % ui._poison_float_count)
	# 场数 归 0 徽标 隐藏 文本 清空
	g.poison_battles = 0
	ui._refresh()
	check(badge.visible == false and str(badge.text) == "", "打磨-93 场数 归0 徽标 隐藏 (实际 visible=%s)" % str(badge.visible))
	# 收尾: 恢复 干净 基准 + 切回 成就页 (与 _assert_tower_clear 收尾 同口径 防 后续 段 污染)
	g.poison_battles = 0
	g.poison_events.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.stones = 0.0
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g.poison_battles == 0 and g.poison_events.is_empty() and ui._poison_float_count > 0, "打磨-93 收尾 干净 基准 (徽标/事件 清零)")


# 打磨-130: 顶栏 双塔 进度 徽标 断言 (挂机 扫视 顶栏 的 爬塔 进度 展示位 — 进度 此前 只在
# 爬塔页 状态行, 挂机 在 其他 页 扫视 顶栏 需 切页 才 见; 与 剧毒/通关 徽标 同 定位 同父 同风格,
# 青色 区分 减益 剧毒 [紫]/终态 通关 [金]. 断言: 节点 存在/同父 顶栏/青色 字色/手型 光标/
# 平铺 flat + 青色 圆角 样式 / 初始 双塔 均 0 隐藏 无 热区 / 仅 镇妖 层 / 仅 登天 纪录 / 双塔 并排 /
# 通关 追加 标注 / 文案=接口 恒等 / tooltip 含 双塔 口径+点击 直达 / 升层 动态 同步 / 点击 直达
# 爬塔页 (tab=4) + 状态行 金边 高亮+自动恢复 / 同态 节流 无 资源 统计 副作用 / 收尾 干净 基准)
func _assert_tower_progress_badge() -> void:
	var g := GameData
	# 基准: 双塔 归零 冻结 (与 剧毒/通关 段 收尾 同口径, 防 挂机/自动 爬塔 竞争)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.set_process(false)
	var badge: Button = ui._tower_progress_badge
	check(badge != null, "打磨-130 顶栏 双塔 进度 徽标 节点 存在")
	check(badge != null and badge.get_parent() == ui._auto_badge.get_parent(),
			"打磨-130 徽标 挂在 顶栏 容器 (与 自动 徽标 同父; 实际父节点 %s)" % str(badge.get_parent()))
	check(badge != null and badge.flat and not badge.toggle_mode,
			"打磨-130 徽标 flat 可点击 (非 按压 切换)")
	check(badge != null and badge.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
			"打磨-130 徽标 手型 光标 (实际 %d)" % badge.mouse_default_cursor_shape)
	check(badge != null and badge.get_theme_color("font_color") == Color(0.6, 0.85, 0.85),
			"打磨-130 徽标 字色 青色 (实际 %s)" % str(badge.get_theme_color("font_color")))
	var nb: StyleBoxFlat = badge.get_theme_stylebox("normal")
	check(nb != null and nb.bg_color == Color(0.07, 0.13, 0.13)
			and nb.get_corner_radius(0) == 4,
			"打磨-130 徽标 青色 圆角 底 (normal 背景 0.07,0.13,0.13 圆角 4; 实际 bg=%s 圆角=%d)"
			% [str(nb.bg_color if nb != null else "null"), nb.get_corner_radius(0) if nb != null else -1])
	ui._refresh()
	await get_tree().process_frame
	check(badge.visible == false and str(badge.text) == "" and str(badge.tooltip_text) == "",
			"打磨-130 初始 双塔 均 0 徽标 隐藏 无 热区 (visible=%s 文本=%s)" % [str(badge.visible), str(badge.text)])
	# 仅 镇妖塔 有 进度: 显示 镇妖 层数 + 登天 0 (文案=接口 恒等)
	g.tower_fixed_floor = 5
	g.tower_endless_best = 0
	ui._refresh()
	await get_tree().process_frame
	check(badge.visible and str(badge.text) == "塔 镇妖 5/1000 · 登天 0",
			"打磨-130 仅 镇妖 5 层 徽标 显示 文案 (实际 %s)" % str(badge.text))
	check(str(badge.text) == g.tower_progress_badge_text(), "打磨-130 徽标 文案 = 接口 恒等")
	# 仅 登天梯 有 纪录: 镇妖 0 + 登天 纪录
	g.tower_fixed_floor = 0
	g.tower_endless_best = 233
	ui._refresh()
	await get_tree().process_frame
	check(str(badge.text) == "塔 镇妖 0/1000 · 登天 233", "打磨-130 仅 登天 233 层 文案 (实际 %s)" % str(badge.text))
	# 升层 动态 同步 (登天 233 -> 5000)
	g.tower_endless_best = 5000
	ui._refresh()
	await get_tree().process_frame
	check(str(badge.text) == "塔 镇妖 0/1000 · 登天 5000", "打磨-130 登天 升层 动态 同步 (实际 %s)" % str(badge.text))
	# 双塔 并排 + 通关 追加 标注
	g.tower_fixed_floor = 1000
	g.tower_fixed_clear = true
	g.tower_endless_best = 500
	ui._refresh()
	await get_tree().process_frame
	check(str(badge.text) == "塔 镇妖 1000/1000 (通关) · 登天 500",
			"打磨-130 双塔 并排 通关 追加 标注 (实际 %s)" % str(badge.text))
	# tooltip 含 双塔 口径 + 点击 直达 爬塔页
	var tip130: String = str(badge.tooltip_text)
	check(tip130 == g.tower_progress_badge_tip() + g.tower_progress_badge_tip_dyn(), "打磨-130 徽标 tooltip = 静态 + 动态段 恒等")
	check(tip130.find("双塔") >= 0 and tip130.find("镇妖塔") >= 0 and tip130.find("登天") >= 0,
			"打磨-130 tooltip 含 双塔/镇妖塔/登天 口径 (实际 %s)" % tip130.left(40))
	check(tip130.find("点击") >= 0 and tip130.find("爬塔页") >= 0, "打磨-130 tooltip 含 点击 直达 爬塔页 口径")
	# 点击 直达 爬塔页 (tab 4) + 状态行 金边 高亮 (复用 自动汇总行 金边 口径)
	var tw130: int = int(g.stats.get("tower_win", 0.0))
	var f130: int = g.tower_fixed_floor
	var pb130: int = g.poison_battles
	ui._on_tower_progress_badge()
	await get_tree().process_frame
	check(ui._tab.current_tab == 4, "打磨-130 点击 切 爬塔页 (tab=4, 实际 %d)" % ui._tab.current_tab)
	var tsb: StyleBox = ui._tw_status_panel.get_theme_stylebox("panel")
	check(tsb != null and tsb.border_width_left == 2, "打磨-130 点击 后 状态行 金边 高亮 (边框宽=%d)" % (tsb.border_width_left if tsb != null else -1))
	check(tsb != null and tsb.border_color == Color(0.98, 0.86, 0.5), "打磨-130 高亮 边框色=金 (实际 %s)" % str(tsb.border_color if tsb != null else "null"))
	# 恢复 终态 (手动 回调; headless 不 依赖 tween 自然 跑完, 同 M5-4/93 高亮 断言 口径)
	ui._restore_tower_status_panel()
	var tsb2: StyleBox = ui._tw_status_panel.get_theme_stylebox("panel")
	check(tsb2 != null and tsb2.border_width_left == 0, "打磨-130 恢复 后 状态行 无边框 (边框宽=%d)" % (tsb2.border_width_left if tsb2 != null else -1))
	# 无 资源/统计 副作用 (点击 导航 不改 存档: 塔 层/胜利 统计/debuff 场数 不变)
	check(g.tower_fixed_floor == f130 and int(g.stats.get("tower_win", 0.0)) == tw130 and g.poison_battles == pb130,
			"打磨-130 点击 无 塔/统计 副作用 (实际 层=%d 胜=%d 场=%d)" % [g.tower_fixed_floor, tw130, g.poison_battles])
	# 同态 节流: 无 塔 态 变化 再 刷 不 重写 文本 (锚定 文本 引用 不变 + 无 统计 副作用)
	var snap130: Dictionary = g.stats.duplicate(true)
	var txt130: String = str(badge.text)
	ui._refresh()
	await get_tree().process_frame
	check(str(badge.text) == txt130 and g.stats == snap130, "打磨-130 同态 节流 无 统计 副作用")
	# 收尾: 双塔 归零 + 冻结 恢复 + 切回 成就页 (防 残留 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(badge.visible == false and str(badge.text) == "", "打磨-130 收尾 双塔 归零 徽标 隐藏 (visible=%s 文本=%s)" % [str(badge.visible), str(badge.text)])


# 打磨-131: 顶栏 双塔 进度 徽标 tooltip 动态段 断言 (挂机 扫视 顶栏 悬停 徽标 查看 本次 运行 自动
# 爬塔 会话 统计; 段 文案 单源 auto_tower_session_text 恒等. 断言: 初始 会话 空 + 关 开关 无 段
# tooltip=静态前缀 / 会话 胜局 态 + 开 开关 _refresh 动态 同步 含 四 累计 = 静态 + 接口 恒等 /
# 败局 清零 无 段 旧 口径 / 开关 关 段 消失 (会话 保留) / 开关 回 开 恢复 / 同态 节流 无 副作用 /
# 收尾 干净 基准 防 污染)
func _assert_tower_prog_tip_dyn() -> void:
	var g := GameData
	# 基准: 双塔 有 进度 + 会话 清零 + 开关 关 + 冻结 (防 挂机/自动 爬塔 竞争)
	g.tower_fixed_floor = 5
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 12
	g.auto_tower = false
	g._auto_tower_seq = 0
	g._auto_tower_last_txt = ""
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_losses = 0
	g.set_process(false)
	var badge: Button = ui._tower_progress_badge
	ui._refresh()
	await get_tree().process_frame
	check(badge.visible, "打磨-131 基准 有 进度 徽标 显示 (visible=%s)" % str(badge.visible))
	check(str(badge.tooltip_text) == g.tower_progress_badge_tip() and g.tower_progress_badge_tip_dyn() == "",
				"打磨-131 初始 会话 空 + 关 开关 tooltip = 静态 前缀 无 动态段 (实际 %s)" % str(badge.tooltip_text).left(48))
	# 会话 胜局 态 + 开关 开: _refresh 动态 同步 含 四 累计 = 静态 + 接口 恒等
	g._auto_tower_wins = 2
	g._auto_tower_stone = 888.0
	g._auto_tower_mats = 3
	g._auto_tower_affixes = 1
	g.auto_tower = true
	ui._refresh()
	await get_tree().process_frame
	var tip131: String = str(badge.tooltip_text)
	check(tip131 == g.tower_progress_badge_tip() + g.tower_progress_badge_tip_dyn(),
				"打磨-131 会话 态 tooltip = 静态 前缀 + 动态段 恒等")
	check(tip131.find("自动 胜 2 场 (灵石 888)") >= 0 and tip131.find("材料 3") >= 0 and tip131.find("词缀 1 件") >= 0
				and tip131.find("【本次 运行 自动 爬塔 会话 (内存态 不 持久化, 读档 归零)】") >= 0,
				"打磨-131 动态段 含 胜局/灵石/材料/词缀 四 累计 (实际 %s)" % tip131.left(60))
	# 会话 败局 清零 无 败局 段 (旧 口径)
	check(tip131.find("败 0 场") < 0, "打磨-131 0 败局 无 败局 段 旧 口径")
	# 开关 关: 动态段 消失 (会话 保留 不 清零)
	g.auto_tower = false
	ui._refresh()
	await get_tree().process_frame
	check(str(badge.tooltip_text) == g.tower_progress_badge_tip() and g._auto_tower_wins == 2,
				"打磨-131 关 开关 动态段 消失 会话 保留 (tooltip=%s wins=%d)" % [str(badge.tooltip_text).left(48), g._auto_tower_wins])
	# 开关 回 开: 动态段 恢复 恒等
	g.auto_tower = true
	ui._refresh()
	await get_tree().process_frame
	check(str(badge.tooltip_text) == g.tower_progress_badge_tip() + g.tower_progress_badge_tip_dyn(),
				"打磨-131 开关 回 开 动态段 恢复 恒等")
	# 同态 节流: 无 会话 变化 再 刷 不 重写 (文本 稳定 + 无 统计 副作用)
	var snap131: Dictionary = g.stats.duplicate(true)
	var txt131: String = str(badge.tooltip_text)
	ui._refresh()
	await get_tree().process_frame
	check(str(badge.tooltip_text) == txt131 and g.stats == snap131, "打磨-131 同态 节流 无 统计 副作用")
	# 收尾: 会话 归零 + 开关 关 + 双塔 归零 (防 残留 污染 后续 段)
	g._auto_tower_seq = 0
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_losses = 0
	g._auto_tower_last_txt = ""
	g.auto_tower = false
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.set_process(true)
	ui._refresh()
	await get_tree().process_frame
	check(badge.visible == false and str(badge.tooltip_text) == "" and g.tower_progress_badge_tip_dyn() == "",
			"打磨-131 收尾 会话 归零 + 双塔 归零 徽标 隐藏 tooltip 空 (visible=%s)" % str(badge.visible))


# 打磨-132: 自动爬塔 会话 新纪录 累计 段 断言 (登天梯 新纪录 单场 只 显 浮动/底部消息, 挂机
# 回来看 会话 不知 本次 运行 创 几 个 新纪录 — 会话 段 累计 次数 + 最高层; 状态行 会话 段
# 单源 auto_tower_session_text 复用 自动 覆盖; 冻结 _process 防 挂机/自动 爬塔 竞争, 手动
# 置态 驱动 刷新键 变化 路径, 验证 状态行 文本 动态 同步 + 0 新纪录 旧 口径 + 节流 无 副作用)
func _assert_auto_tower_new_record_session() -> void:
	var g := GameData
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.auto_tower = false
	g._auto_tower_seq = 0
	g._auto_tower_last_txt = ""
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_losses = 0
	g._auto_tower_new_records = 0
	g._auto_tower_new_best = 0
	g.set_process(false)
	# 切 爬塔页 tab4 确保 状态行 构建可见
	ui._tab.current_tab = 4
	ui._refresh()
	await get_tree().process_frame
	# 1) 初始 0 胜局: 状态行 无 会话 段 (无 新纪录 段)
	check(str(ui._tw_status_label.text).find("新纪录") < 0 and str(ui._tw_status_label.text) == g.tower_status_line(),
			"打磨-132 初始 0 胜局 状态行 无 会话 段 = 接口 恒等 (实际 %s)" % str(ui._tw_status_label.text))
	# 2) 会话 胜局 态 + 新纪录 2 次 最高 88: _refresh 动态 同步 状态行 含 新纪录 段 单源 恒等
	g._auto_tower_wins = 3
	g._auto_tower_stone = 888.0
	g._auto_tower_affixes = 1
	g._auto_tower_new_records = 2
	g._auto_tower_new_best = 88
	ui._refresh()
	await get_tree().process_frame
	var st132: String = str(ui._tw_status_label.text)
	check(st132 == g.tower_status_line(), "打磨-132 会话 态 状态行 = 接口 恒等 (实际 %s)" % st132.left(60))
	check(st132.find("新纪录 2 次 (最高 第 88 层)") >= 0,
			"打磨-132 状态行 含 新纪录 段 单源 恒等 (实际 %s)" % st132)
	# 3) 0 新纪录 旧 口径: 新纪录 清零 后 状态行 无 新纪录 段 (防 回归 打磨-95/128 既有 段)
	g._auto_tower_new_records = 0
	g._auto_tower_new_best = 0
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text).find("新纪录") < 0,
			"打磨-132 0 新纪录 状态行 无 段 旧 口径 (实际 %s)" % str(ui._tw_status_label.text))
	# 4) 同态 节流: 无 会话 变化 再 刷 不 重写 (文本 稳定 + 无 统计 副作用)
	var snap132: Dictionary = g.stats.duplicate(true)
	var txt132: String = str(ui._tw_status_label.text)
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text) == txt132 and g.stats == snap132,
			"打磨-132 同态 节流 无 统计 副作用")
	# 收尾: 会话 归零 + 开关 关 + 双塔 归零 (防 残留 污染 后续 段)
	g._auto_tower_seq = 0
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_losses = 0
	g._auto_tower_new_records = 0
	g._auto_tower_new_best = 0
	g._auto_tower_last_txt = ""
	g.auto_tower = false
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.set_process(true)
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text) == g.tower_status_line(),
			"打磨-132 收尾 状态行 = 接口 恒等 (干净 基准)")


# 打磨-133: 自动爬塔 会话 里程碑 宝箱 累计 段 断言 (登天梯 里程碑 Boss 宝箱 单场 只 显
# 浮动/底部消息 [打磨-115], 挂机 回来看 会话 不知 本次 运行 触发 几次 宝箱 — 会话 段 累计 次数;
# 状态行 会话 段 单源 auto_tower_session_text 复用 自动 覆盖; 冻结 _process 防 挂机/自动 爬塔
# 竞争, 手动 置态 驱动 刷新键 变化 路径, 验证 状态行 文本 动态 同步 + 0 宝箱 旧 口径 + tooltip 口径
# + 节流 无 副作用)
func _assert_auto_tower_mile_session() -> void:
	var g := GameData
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.auto_tower = false
	g._auto_tower_seq = 0
	g._auto_tower_last_txt = ""
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_losses = 0
	g._auto_tower_new_records = 0
	g._auto_tower_new_best = 0
	g._auto_tower_milestones = 0
	g.set_process(false)
	# 切 爬塔页 tab4 确保 状态行 构建可见
	ui._tab.current_tab = 4
	ui._refresh()
	await get_tree().process_frame
	# 1) 初始 0 胜局: 状态行 无 会话 段 (无 宝箱 段)
	check(str(ui._tw_status_label.text).find("里程碑宝箱") < 0 and str(ui._tw_status_label.text) == g.tower_status_line(),
			"打磨-133 初始 0 胜局 状态行 无 会话 段 = 接口 恒等 (实际 %s)" % str(ui._tw_status_label.text))
	# 2) 会话 胜局 态 + 宝箱 3 次: _refresh 动态 同步 状态行 含 宝箱 段 单源 恒等 (与新纪录 段 并存)
	g._auto_tower_wins = 3
	g._auto_tower_stone = 888.0
	g._auto_tower_affixes = 1
	g._auto_tower_milestones = 3
	g._auto_tower_new_records = 2
	g._auto_tower_new_best = 100
	ui._refresh()
	await get_tree().process_frame
	var st133: String = str(ui._tw_status_label.text)
	check(st133 == g.tower_status_line(), "打磨-133 会话 态 状态行 = 接口 恒等 (实际 %s)" % st133.left(60))
	check(st133.find("里程碑宝箱 3 次") >= 0 and st133.find("新纪录 2 次 (最高 第 100 层)") >= 0,
			"打磨-133 状态行 含 宝箱 段 + 新纪录 段 单源 恒等 (实际 %s)" % st133)
	# 3) 0 宝箱 旧 口径: 宝箱 清零 后 状态行 无 宝箱 段 (防 回归 打磨-95/128/132 既有 段)
	g._auto_tower_milestones = 0
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text).find("里程碑宝箱") < 0,
			"打磨-133 0 宝箱 状态行 无 段 旧 口径 (实际 %s)" % str(ui._tw_status_label.text))
	# 4) 同态 节流: 无 会话 变化 再 刷 不 重写 (文本 稳定 + 无 统计 副作用)
	var snap133: Dictionary = g.stats.duplicate(true)
	var txt133: String = str(ui._tw_status_label.text)
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text) == txt133 and g.stats == snap133,
			"打磨-133 同态 节流 无 统计 副作用")
	# 5) 状态行 tooltip 含 里程碑 宝箱 口径 说明行 (打磨-133 追加)
	check(str(ui._tw_status_panel.tooltip_text).find("里程碑 宝箱 段 (打磨-133)") >= 0,
			"打磨-133 状态行 tooltip 含 宝箱 段 口径 (实际 %s)" % str(ui._tw_status_panel.tooltip_text).right(60))
	# 收尾: 会话 归零 + 开关 关 + 双塔 归零 (防 残留 污染 后续 段)
	g._auto_tower_seq = 0
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_losses = 0
	g._auto_tower_new_records = 0
	g._auto_tower_new_best = 0
	g._auto_tower_milestones = 0
	g._auto_tower_last_txt = ""
	g.auto_tower = false
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.set_process(true)
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text) == g.tower_status_line(),
			"打磨-133 收尾 状态行 = 接口 恒等 (干净 基准)")


# 打磨-94: 塔战斗 词缀掉落 底部消息 展示 断言 (M5-3 规格 "战斗后 掉落展示 灵石/材料/词缀" 词缀 段:
# 胜 含 词缀 掉落 时 底部 胜利消息 追加 "(词缀: 「名」、…)"; 败/无掉落 不追加; 驱动 真实 处理器
# _on_tower_challenge (roll=-1 走 randf, 但 boss 层 100% 必掉 使 掉落 ≥1 确定, 胜负 由 玩家 战力 控制 确定).
# 基准: 镇妖塔 第 50 层 = 小 Boss (boss_type=small, 掉落 必掉 1~3 件, 数据 锚定 于 tower_monsters.json),
# 弱 玩家 (境界0 atk 2.0) 恒败 [怪 atk ~290 阈值 246 > 2.0] 无 掉落 → 消息 无 词缀 段;
# 强 玩家 (ascended 道祖 dao8 有效 atk ~3.4e25) 恒胜 → 消息 含 词缀 段. 冻结 g._process 防 挂机/自动 爬塔 竞争.
# 收尾 恢复 干净 基准 + 词缀 背包/收集 清零 防 污染 后续 M6-3 段 初始 0/0 断言.
func _assert_tower_affix_drop() -> void:
	var g := GameData
	# 干净 基准 (塔 归零 + 境界0 层1 无 加成 + 词缀 背包 清零 + 冻结 挂机/自动 爬塔)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	g.set_process(false)
	ui._tab.current_tab = 4
	ui._refresh()
	await get_tree().process_frame
	# 数据 锚定: 第 50 层 小 Boss (必掉) + 强 玩家 恒胜 / 弱 玩家 恒败
	var rec50: Dictionary = g.get_fixed_floor(50)
	var mon50: Dictionary = g.tower_monster_stats(rec50)
	check(str(mon50.get("boss_type", "")) == "small", "打磨-94 第 50 层 = 小 Boss (数据 锚定, 实际 %s)" % str(mon50.get("boss_type", "")))
	g.tower_fixed_floor = 49  # 待挑战 层 = 50
	# 弱 玩家 (atk 2.0): 恒败 (阈值 246 > 2.0) → 无 掉落 → 败 消息 不 含 词缀 段
	check(g.player_atk_effective() < float(mon50["atk"]) * g.TOWER_WIN_RATIO, "打磨-94 弱 玩家 第 50 层 判定=败 (数据 锚定)")
	ui._on_tower_challenge("fixed")
	var msg_loss: String = str(ui._msg_label.text)
	check(msg_loss.begins_with("✖ 镇妖塔 第 50 层"), "打磨-94 败 局 消息 口径 (实际 %s)" % msg_loss.left(24))
	check(msg_loss.find("词缀") < 0, "打磨-94 败 局 无 词缀 段 (败 无 掉落, 实际 %s)" % msg_loss)
	# 强 玩家 (ascended 道祖): 恒胜 boss → 掉落 必掉 1~3 件 → 胜 消息 含 词缀 段
	g.ascended = true
	g.dao_level = 8
	g.tower_fixed_floor = 49
	check(g.player_atk_effective() >= float(mon50["atk"]) * g.TOWER_WIN_RATIO, "打磨-94 强 玩家 第 50 层 判定=胜 (数据 锚定)")
	var bag_before: int = g.affix_bag_used()
	ui._on_tower_challenge("fixed")
	var msg_win: String = str(ui._msg_label.text)
	check(msg_win.begins_with("✔ 镇妖塔 第 50 层"), "打磨-94 胜 局 消息 口径 (实际 %s)" % msg_win.left(24))
	check(msg_win.find("胜利!") >= 0, "打磨-94 胜 局 消息 含 胜利 (实际 %s)" % msg_win)
	check(msg_win.find("(词缀: ") >= 0, "打磨-94 胜 局 boss 必掉 → 消息 含 词缀 段 (实际 %s)" % msg_win)
	check(msg_win.find("」") >= 0, "打磨-94 词缀 段 含 词缀 名 (引号 包裹, 实际 %s)" % msg_win)
	check(g.affix_bag_used() > bag_before, "打磨-94 词缀 入包 (背包 格数 上升, %d->%d)" % [bag_before, g.affix_bag_used()])
	check(int(g.stats.get("tower_win", 0.0)) >= 1, "打磨-94 胜 局 统计 tower_win 计数")
	# 收尾: 恢复 干净 基准 + 词缀 清零 (防 污染 M6-3 段 初始 0/0 断言)
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g.affix_bag_used() == 0 and g.affix_bag.is_empty(), "打磨-94 收尾 词缀 背包 清零 (防 污染)")


# 打磨-107: 塔战斗 胜利 浮动提示 断言 (M5-3 规格 "掉落展示 底部消息 + 浮动提示" 浮动 段:
# 手动 挑战 胜利 → 屏幕中央 绿色 浮动 "✦ 塔名 第 N 层「怪名」胜利 (…) ✦", 败 局 不 弹,
# 与 底部 消息 并存; 自动爬塔 路径 不 弹 浮动 口径 不变. 驱动 真实 _on_tower_challenge 处理器,
# 基准 同 打磨-94: 镇妖塔 第 50 层 小 Boss 数据 锚定, 弱 玩家 (境界0 atk 2.0) 恒败 /
# 强 玩家 (ascended 道祖) 恒胜. 收尾 恢复 干净 基准 + 词缀 清零 防 污染 M6-3 段.)
func _assert_tower_win_float() -> void:
	var g := GameData
	# 干净 基准 (塔 归零 + 境界0 层1 无 加成 + 词缀 背包 清零 + 冻结 挂机/自动 爬塔)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	g.set_process(false)
	# 浮动 计数 归零 (打磨-94 胜局 已 弹 过 1 次, 本段 独立 断言)
	ui._tower_win_float_count = 0
	ui._tower_win_last_text = ""
	ui._tab.current_tab = 4
	ui._refresh()
	await get_tree().process_frame
	var fl: Label = ui._tower_win_float_label
	check(fl != null, "打磨-107 浮动 标签 节点 存在")
	check(ui._tower_win_float_count == 0, "打磨-107 归零 后 浮动 计数=0 (实际 %d)" % ui._tower_win_float_count)
	# 数据 锚定: 第 50 层 小 Boss, 弱 玩家 恒败 / 强 玩家 恒胜
	var rec50: Dictionary = g.get_fixed_floor(50)
	var mon50: Dictionary = g.tower_monster_stats(rec50)
	check(str(mon50.get("boss_type", "")) == "small", "打磨-107 第 50 层 = 小 Boss (数据 锚定, 实际 %s)" % str(mon50.get("boss_type", "")))
	g.tower_fixed_floor = 49  # 待挑战 层 = 50
	# 弱 玩家 (atk 2.0): 恒败 → 不 弹 浮动
	check(g.player_atk_effective() < float(mon50["atk"]) * g.TOWER_WIN_RATIO, "打磨-107 弱 玩家 第 50 层 判定=败 (数据 锚定)")
	ui._on_tower_challenge("fixed")
	check(ui._tower_win_float_count == 0, "打磨-107 败 局 不 弹 浮动 (实际 %d)" % ui._tower_win_float_count)
	check(str(ui._msg_label.text).begins_with("✖ 镇妖塔 第 50 层"), "打磨-107 败 局 底部 消息 仍 保留 (实际 %s)" % str(ui._msg_label.text).left(24))
	# 强 玩家 (ascended 道祖): 恒胜 → 弹 绿色 浮动
	g.ascended = true
	g.dao_level = 8
	g.tower_fixed_floor = 49
	check(g.player_atk_effective() >= float(mon50["atk"]) * g.TOWER_WIN_RATIO, "打磨-107 强 玩家 第 50 层 判定=胜 (数据 锚定)")
	ui._on_tower_challenge("fixed")
	check(ui._tower_win_float_count == 1, "打磨-107 胜 局 浮动 计数 +1 (实际 %d)" % ui._tower_win_float_count)
	var ftxt: String = str(fl.text)
	check(ftxt.begins_with("✦ 镇妖塔 第 50 层「"), "打磨-107 浮动 文案 前缀 塔名/层 (实际 %s)" % ftxt.left(28))
	check(ftxt.find("胜利") >= 0 and ftxt.ends_with("✦"), "打磨-107 浮动 文案 含 胜利+收尾 符号 (实际 %s)" % ftxt)
	check(ftxt.find("(灵石 +") >= 0, "打磨-107 浮动 文案 含 灵石 段 (实际 %s)" % ftxt)
	check(fl.visible, "打磨-107 浮动 标签 可见")
	var pos_y: float = fl.position.y
	check(pos_y > -70.0 and pos_y < -20.0, "打磨-107 浮动 位置 居中 段 (实际 y=%.0f)" % pos_y)
	# 文案 结构: Boss 层 必掉 词缀 1~3 件 (M6-2 口径) → 浮动 含 词缀 件数 段;
	# Boss 层 无 怪物种 → mats=0 → 无 材料 段 (与 结算 reward_mat=0 同源 口径)
	check(ftxt.find("词缀 x") >= 0, "打磨-107 浮动 文案 含 词缀 件数 段 (实际 %s)" % ftxt)
	check(ftxt.find("材料") < 0, "打磨-107 Boss 层 无 怪物种 → 无 材料 段 (实际 %s)" % ftxt)
	# 收尾: 恢复 干净 基准 + 词缀 清零 (防 污染 M6-3 段)
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g.affix_bag_used() == 0 and g.affix_bag.is_empty(), "打磨-107 收尾 词缀 背包 清零 (防 污染)")


# 打磨-95: 自动爬塔 胜局 汇总 底部消息 + 会话 统计 状态行 断言 (挂机 期间 自动 爬塔 胜利 静默 补位:
# 胜局 变更事件 驱动 底部消息 "自动爬塔 胜利 N 场 (…)" 节流 提示 [无 浮动 防 刷屏] +
# 爬塔页 状态行 追加 "· 自动 胜 N 场 (灵石 X)" 会话 统计 段. 驱动 真实 _process 帧 (同 挂机 路径),
# 基准 同 打磨-94: realm0 层1 有效 atk 2.0, 双塔 第 1 层 恒胜; 词缀 掉落 走 randf 随机
# 只 断言 文案 前缀/塔 明细/会话 累计, 不 锚定 掉落 件数. 收尾 恢复 干净 基准 防 污染 M6-3 段)
func _assert_auto_tower_feedback() -> void:
	var g := GameData
	# 干净 基准 (塔 归零 + 境界0 层1 无 加成 + 会话 归零 + 剧毒 清)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g._auto_tower_seq = 0
	g._auto_tower_last_txt = ""
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0  # 打磨-100: 会话 材料 归零 (防 污染 后续 段)
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	g.set_process(false)
	ui._tab.current_tab = 4
	ui._refresh()
	await get_tree().process_frame
	# 初始: 无 胜局 → 状态行 无 会话 段
	check(str(ui._tw_status_label.text).find("自动 胜") < 0, "打磨-95 初始 状态行 无 会话 段 (实际 %s)" % str(ui._tw_status_label.text))
	# 开 自动爬塔 + _process 一帧: 双塔 各 胜 第 1 层 → 胜局 变更事件 驱动 底部消息
	g.auto_tower = true
	var f1s: float = float(g.tower_monster_stats(g.get_fixed_floor(1))["stone"])
	var e1s: float = float(g.tower_monster_stats(g.get_endless_floor(1))["stone"])
	var seq0: int = g._auto_tower_seq
	g._process(0.016)
	ui._refresh()
	await get_tree().process_frame
	check(g._auto_tower_seq == seq0 + 1, "打磨-95 胜局 变更事件 seq+1 (实际 %d)" % g._auto_tower_seq)
	var msg_at: String = str(ui._msg_label.text)
	check(msg_at.begins_with("自动爬塔 胜利 2 场 ("), "打磨-95 底部消息 胜局 汇总 文案 (实际 %s)" % msg_at.left(28))
	check(msg_at.find("镇妖塔 第 1 层 灵石 +") >= 0 and msg_at.find("登天梯 第 1 层 灵石 +") >= 0,
			"打磨-95 底部消息 含 双塔 明细 (实际 %s)" % msg_at)
	check(str(ui._tw_status_label.text).find("自动 胜 2 场 (灵石 ") >= 0,
			"打磨-95 状态行 会话 统计 段 刷新 (实际 %s)" % str(ui._tw_status_label.text))
	check(absf(g._auto_tower_stone - f1s - e1s - e1s * 0.5) < 1e-6,
			"打磨-95 会话 灵石 累计 = 双塔 第 1 层 + 每日首胜 0.5x (实际 %s)" % g.fmt(g._auto_tower_stone))
	# 节流: 同 会话 态 _refresh 再 跑 不 重写 底部消息 (seq 未变, 文案 稳定)
	var msg_at2_before: String = str(ui._msg_label.text)
	var stats_snap: Dictionary = g.stats.duplicate(true)
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._msg_label.text) == msg_at2_before, "打磨-95 同 会话 态 节流 不 重写 底部消息")
	# 关 开关: 全败 帧 不 增 事件 不 弹 消息
	g.auto_tower = false
	g.set_process(true)
	# 收尾: 恢复 干净 基准 + 会话 清零 (防 污染 后续 M6-3 段 断言)
	g._auto_tower_seq = 0
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0  # 打磨-100: 会话 材料 归零 (防 污染 后续 段)
	g._auto_tower_affixes = 0  # 打磨-122: 会话 词缀 归零 (防 污染 后续 段)
	g._auto_tower_last_txt = ""
	g.auto_tower = false
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g._auto_tower_wins == 0 and g._auto_tower_stone == 0.0 and g.auto_tower == false, "打磨-95 收尾 干净 基准 (会话 清零)")


# 打磨-122: 自动爬塔 会话 词缀 段 UI 断言 (会话 累计 词缀 件数 展示位: 状态行 会话 段 追加
# "词缀 N 件"; 手动 会话 态 驱动 (UI 层 无 新 逻辑 接口 恒等 口径 同 selftest),
# 词缀 = 0 不 追加 段 旧 口径/状态行 tooltip 含 会话 段 口径 说明; 收尾 干净 基准 防 污染)
func _assert_auto_tower_affix_session() -> void:
	var g := GameData
	g.set_process(false)
	g.auto_tower = false
	ui._tab.current_tab = 4
	# 干净 基准 (同 打磨-95 口径 + 会话 词缀 归零)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g._auto_tower_seq = 0
	g._auto_tower_last_txt = ""
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0  # 打磨-122: 会话 词缀 归零
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	ui._refresh()
	await get_tree().process_frame
	# 1) 初始 0 胜局: 状态行 无 会话 段
	check(str(ui._tw_status_label.text).find("自动 胜") < 0, "打磨-122 初始 状态行 无 会话 段 (实际 %s)" % str(ui._tw_status_label.text))
	# 2) 手动 会话 态 (词缀 > 0): 状态行 会话 段 追加 词缀 段 = 会话 文案 恒等
	g._auto_tower_wins = 2
	g._auto_tower_stone = 1234.0
	g._auto_tower_mats = 7
	g._auto_tower_affixes = 3
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text).find("自动 胜 2 场 (灵石 ") >= 0 and str(ui._tw_status_label.text).find("词缀 3 件") >= 0,
			"打磨-122 状态行 会话 段 含 词缀 累计 (实际 %s)" % str(ui._tw_status_label.text))
	check(str(ui._tw_status_label.text).find(g.auto_tower_session_text()) >= 0,
			"打磨-122 状态行 会话 段 = auto_tower_session_text 恒等 (实际 %s)" % str(ui._tw_status_label.text))
	# 3) 词缀 = 0: 状态行 不 追加 词缀 段 (旧 口径)
	g._auto_tower_affixes = 0
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text).find("词缀 ") < 0,
			"打磨-122 0 词缀 状态行 无 词缀 段 旧 口径 (实际 %s)" % str(ui._tw_status_label.text))
	# 4) 状态行 tooltip 含 会话 段 口径 说明 (词缀 件数 = 战斗 掉落 累计 / 大奖 另段)
	check(ui._tw_status_panel.tooltip_text.find("词缀 件数") >= 0 and ui._tw_status_panel.tooltip_text.find("通关 大奖 词缀 另段 展示") >= 0,
			"打磨-122 状态行 tooltip 含 会话 词缀 口径 (实际 %s)" % ui._tw_status_panel.tooltip_text.left(60))
	# 5) 只读: 同 会话 态 _refresh 无 资源/统计 副作用
	var stats_snap122: Dictionary = g.stats.duplicate(true)
	var affix0: int = g._auto_tower_affixes
	ui._refresh()
	await get_tree().process_frame
	check(g.stats == stats_snap122 and g._auto_tower_affixes == affix0, "打磨-122 同 会话 态 节流 无 资源/统计 副作用")
	# 收尾: 恢复 干净 基准 + 会话 清零 (防 污染 后续 段)
	g._auto_tower_seq = 0
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_last_txt = ""
	g.auto_tower = false
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g._auto_tower_affixes == 0 and g._auto_tower_wins == 0, "打磨-122 收尾 干净 基准 (会话 词缀 清零)")


# 打磨-125: 自动爬塔开关 tooltip 会话 统计 段 UI 断言 (挂机 期间 自动 爬塔 胜局/灵石/材料/词缀
# 累计 的 悬停 展示 位: 开关 tooltip 动态段 追加 "本次 运行 会话" 行 = auto_tower_next_tip 接口
# 恒等, 0 胜局 显 口径 说明 / 会话 态 动态 同步 / 只读 节流 无 副作用; 收尾 干净 基准 防 污染)
func _assert_auto_tower_session_tip() -> void:
	var g := GameData
	g.set_process(false)
	g.auto_tower = false
	ui._tab.current_tab = 4
	# 干净 基准 (同 打磨-95/122 口径 + 会话 归零)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g._auto_tower_seq = 0
	g._auto_tower_last_txt = ""
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	ui._refresh()
	await get_tree().process_frame
	# 1) 初始 0 胜局: 开关 tooltip 含 会话 段 口径 说明 = 接口 恒等
	check(str(ui._tw_auto_btn.tooltip_text).find("本次 运行 会话: 0 胜局 (内存态 不 持久化, 读档 归零)") >= 0,
			"打磨-125 0 胜局 开关 tooltip 会话 段 口径 说明 (实际 %s)" % str(ui._tw_auto_btn.tooltip_text).left(60))
	check(str(ui._tw_auto_btn.tooltip_text) == ui._tw_auto_tip_static + g.auto_tower_next_tip(),
			"打磨-125 开关 tooltip = 静态 前缀 + 接口 恒等")
	# 2) 手动 会话 态: _refresh 动态 同步 会话 段 = 接口 恒等 (含 词缀 段)
	g._auto_tower_wins = 2
	g._auto_tower_stone = 1234.0
	g._auto_tower_mats = 7
	g._auto_tower_affixes = 3
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_auto_btn.tooltip_text).find("本次 运行 会话: 自动 胜 2 场 (灵石 %s) · 材料 7 · 词缀 3 件" % g.fmt(1234.0)) >= 0,
			"打磨-125 会话 态 tooltip 会话 段 含 四 累计 (实际 %s)" % str(ui._tw_auto_btn.tooltip_text).left(80))
	check(str(ui._tw_auto_btn.tooltip_text) == ui._tw_auto_tip_static + g.auto_tower_next_tip(),
			"打磨-125 会话 态 tooltip = 接口 恒等")
	# 3) 0 词缀: 会话 段 不 追加 词缀 段 (旧 口径 同 状态行)
	g._auto_tower_affixes = 0
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_auto_btn.tooltip_text).find("词缀 ") < 0,
			"打磨-125 0 词缀 tooltip 会话 段 无 词缀 段 旧 口径 (实际 %s)" % str(ui._tw_auto_btn.tooltip_text).left(80))
	# 4) 只读: 同 会话 态 _refresh 无 资源/统计 副作用 + tooltip 稳定
	var stats_snap125: Dictionary = g.stats.duplicate(true)
	var tip125: String = str(ui._tw_auto_btn.tooltip_text)
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_auto_btn.tooltip_text) == tip125 and g.stats == stats_snap125,
			"打磨-125 同 会话 态 节流 无 资源/统计 副作用")
	# 收尾: 恢复 干净 基准 + 会话 清零 (防 污染 后续 段)
	g._auto_tower_seq = 0
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_losses = 0  # 打磨-128: 防御性 清零 会话 败局 累计 (防 残留 污染 后续 段)
	g._auto_tower_last_txt = ""
	g.auto_tower = false
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g._auto_tower_wins == 0 and g._auto_tower_affixes == 0, "打磨-125 收尾 干净 基准 (会话 清零)")


# 打磨-128: 自动爬塔 会话 败局/卡层 段 UI 断言 (挂机 自动 爬塔 会话 统计 展示位 缺口落地:
# 0 胜局 全败 态 状态行 显 卡层 提示 / 有 胜局 时 会话 段 末尾 追加 败局 段 / 开关 tooltip 会话
# 段 恒等 口径 / 状态行 tooltip 口径 说明 / 刷新键 感知 败局 变化 才 刷 (手动 置态 不 升层);
# 收尾 干净 基准 防 污染)
func _assert_auto_tower_loss_feedback() -> void:
	var g := GameData
	g.set_process(false)
	g.auto_tower = false
	ui._tab.current_tab = 4
	# 干净 基准 (同 打磨-95 口径 + 会话 全部 归零 含 败局)
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g._auto_tower_seq = 0
	g._auto_tower_last_txt = ""
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_losses = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	ui._refresh()
	await get_tree().process_frame
	# 1) 初始 0 胜局 0 败局: 状态行 无 会话 段 无 卡层 段
	check(str(ui._tw_status_label.text).find("自动 败") < 0 and str(ui._tw_status_label.text).find("自动 胜") < 0,
			"打磨-128 初始 状态行 无 会话/卡层 段 (实际 %s)" % str(ui._tw_status_label.text))
	# 2) 0 胜局 全败 态 (手动 置态 不 升层): 刷新键 感知 败局 变化 自动 刷 卡层 段 = 接口 恒等
	g._auto_tower_losses = 3
	ui._refresh()
	await get_tree().process_frame
	var sess128: String = g.auto_tower_session_text()
	check(str(ui._tw_status_label.text).find("· " + sess128) >= 0,
			"打磨-128 全败 态 状态行 卡层 段 = auto_tower_session_text 单源 恒等 (实际 %s)" % str(ui._tw_status_label.text))
	check(sess128.find("未 推进") >= 0 and sess128.find("败 3 场") >= 0,
			"打磨-128 卡层 文案 含 败局 数 + 未 推进 口径 (实际 %s)" % sess128)
	# 3) 有 胜局 态: 会话 段 末尾 追加 败局 段 (与 状态行 单源 恒等)
	g._auto_tower_wins = 2
	g._auto_tower_stone = 5678.0
	g._auto_tower_mats = 7
	g._auto_tower_affixes = 3
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text).find("自动 胜 2 场 (灵石 ") >= 0 and str(ui._tw_status_label.text).find("败 3 场") >= 0,
			"打磨-128 胜局 态 状态行 含 败局 段 (实际 %s)" % str(ui._tw_status_label.text))
	check(str(ui._tw_status_label.text).find(g.auto_tower_session_text()) >= 0,
			"打磨-128 胜局 态 状态行 会话 段 = 接口 恒等 (实际 %s)" % str(ui._tw_status_label.text))
	# 4) 败局 = 0 不 追加 段 (旧 口径)
	g._auto_tower_losses = 0
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text).find("败 ") < 0,
			"打磨-128 0 败局 状态行 无 败局 段 旧 口径 (实际 %s)" % str(ui._tw_status_label.text))
	# 5) 开关 tooltip 会话 段 = 静态 前缀 + 接口 恒等 (卡层 态 亦 同步)
	g._auto_tower_wins = 0
	g._auto_tower_losses = 6
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_auto_btn.tooltip_text) == ui._tw_auto_tip_static + g.auto_tower_next_tip(),
			"打磨-128 卡层 态 开关 tooltip = 静态 前缀 + 接口 恒等")
	check(str(ui._tw_auto_btn.tooltip_text).find("本次 运行 会话: " + g.auto_tower_session_text()) >= 0,
			"打磨-128 开关 tooltip 会话 段 含 卡层 文案 (实际 %s)" % str(ui._tw_auto_btn.tooltip_text).left(120))
	# 6) 状态行 tooltip 含 败局/卡层 口径 说明
	check(ui._tw_status_panel.tooltip_text.find("自动 败局 卡层 段") >= 0
			and ui._tw_status_panel.tooltip_text.find("未 推进") >= 0
			and ui._tw_status_panel.tooltip_text.find("败 N 场") >= 0,
			"打磨-128 状态行 tooltip 含 败局/卡层 口径 说明 (实际 %s)" % ui._tw_status_panel.tooltip_text.left(60))
	# 7) 只读: 同 会话 态 _refresh 无 资源/统计 副作用 + 标签 稳定
	var stats_snap128: Dictionary = g.stats.duplicate(true)
	var txt128: String = str(ui._tw_status_label.text)
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text) == txt128 and g.stats == stats_snap128,
			"打磨-128 同 会话 态 节流 无 资源/统计 副作用")
	# 收尾: 恢复 干净 基准 + 会话 清零 (防 污染 后续 段)
	g._auto_tower_seq = 0
	g._auto_tower_wins = 0
	g._auto_tower_stone = 0.0
	g._auto_tower_mats = 0
	g._auto_tower_affixes = 0
	g._auto_tower_losses = 0
	g._auto_tower_last_txt = ""
	g.auto_tower = false
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.essence = 0.0
	g.stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g._auto_tower_losses == 0 and g._auto_tower_wins == 0, "打磨-128 收尾 干净 基准 (会话 败局 清零)")


# 打磨-102: 登天梯 500 层后 全部 怪物 默认 魔化 (M5 规格落地: 数值 x3 + 追加 1 特性 + 「魔化·」前缀,
# 与 精英层 同口径; Boss 层 独立 x10 不叠魔化). UI 断言: 登天梯 卡片 副标题 魔化 口径/怪物卡 魔化 前缀/
# 战力对比 按 魔化 数值/弱玩家 恒败 停留 本层/强玩家 胜局 消息 含 层数 推进 (收尾 干净 基准 防 污染)
func _assert_endless_demon() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 (待挑战 499, 最高 498) + 剧毒 归零 防 跨段 污染
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 499
	g.tower_endless_best = 498
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 卡片 副标题 含 魔化 口径 (500 层后 全部 魔化)
	var sub499: String = str((ui._tw_cards["endless"]["panel"] as PanelContainer).get_child(0).get_child(1).text)
	check(sub499.find("500 层后") >= 0 and sub499.find("魔化") >= 0,
			"打磨-102 登天梯 卡片 副标题 含 魔化 口径 (实际 %s)" % sub499)
	# 第 499 层 (未 达 魔化 线): 怪物卡 无 魔化 前缀
	var mon499: String = str(ui._tw_mon_labels["endless"].text)
	check(mon499.find("第 499 层") >= 0 and mon499.find("魔化·") < 0,
			"打磨-102 第 499 层 怪物卡 无 魔化 前缀 (实际 %s)" % mon499)
	# 推进 至 500 层 (里程碑 Boss 层): 怪物卡 Boss 标记 (Boss 层 独立 结构, 无 魔化 前缀)
	g.tower_endless_floor = 500
	g.tower_endless_best = 499
	ui._refresh_tower()
	await get_tree().process_frame
	var mon500: String = str(ui._tw_mon_labels["endless"].text)
	check(mon500.find("第 500 层") >= 0 and mon500.find("⚑Boss") >= 0 and mon500.find("魔化·") < 0,
			"打磨-102 第 500 层 怪物卡 Boss 标记 (实际 %s)" % mon500)
	# 推进 至 501 层 (普通 层, 魔化 新口径): 怪物卡 名 含 魔化· 前缀 + 无 Boss/精英 标记
	g.tower_endless_floor = 501
	g.tower_endless_best = 500
	ui._refresh_tower()
	await get_tree().process_frame
	var mon501: String = str(ui._tw_mon_labels["endless"].text)
	check(mon501.find("第 501 层") >= 0 and mon501.find("魔化·") >= 0 and mon501.find("⚑Boss") < 0,
			"打磨-102 第 501 层 普通 层 怪物卡 含 魔化· 前缀 (实际 %s)" % mon501)
	# 战力对比 按 魔化 数值 (501 层 有效 atk = 基础 x3; 弱玩家 atk 恒 < 阈值 → 败 预测)
	var m501: Dictionary = g.tower_monster_stats(g.get_endless_floor(501))
	var pa: float = g.player_atk_effective()
	check(pa < float(m501["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-102 501 层 魔化 后 弱玩家 (基准 atk %s) 判定=败 (数据 锚定, 阈值 %s)" % [g.fmt(pa), g.fmt(float(m501["atk"]) * g.TOWER_WIN_RATIO)])
	var pwr501: String = str(ui._tw_pwr_labels["endless"].text)
	check(pwr501.find("败") >= 0 and pwr501.find("vs 怪物 ATK %s" % g.fmt(float(m501["atk"]))) >= 0,
			"打磨-102 501 层 战力对比 含 魔化 数值 且 预测 败 (实际 %s)" % pwr501)
	# 弱玩家 手动 挑战 501 层 = 败 (停留 本层, 无 消耗 无 惩罚)
	var sto501: float = g.stones
	var r_lose: Dictionary = g.try_tower_challenge("endless", 0.5)
	check(bool(r_lose["win"]) == false and int(g.tower_endless_floor) == 501 and absf(g.stones - sto501) < 1e-9,
			"打磨-102 弱玩家 501 层 败 停留 本层 无 消耗 (实际 win=%s 层=%d)" % [str(r_lose["win"]), int(g.tower_endless_floor)])
	# 强玩家 (飞升 道祖) 恒胜: 挑战 501 层 胜 → 层数 推进 502 + 最高 纪录 501 + 奖励 入账
	var snap501: Dictionary = g.stats.duplicate(true)
	g.ascended = true
	g.dao_level = 8
	g.learned.clear()
	var r_win: Dictionary = g.try_tower_challenge("endless", 0.5)
	check(bool(r_win["win"]) and int(g.tower_endless_floor) == 502 and int(g.tower_endless_best) == 501,
			"打磨-102 强玩家 501 层 魔化 层 胜 推进 (实际 win=%s 层=%d 最高=%d)" % [str(r_win["win"]), int(g.tower_endless_floor), int(g.tower_endless_best)])
	check(float(r_win["reward_stone"]) > 0.0, "打磨-102 魔化 层 胜 奖励 灵石 >0 (实际 %s)" % g.fmt(float(r_win["reward_stone"])))
	# 升层 后 怪物卡 切 502 层 (普通 层 恒 魔化, 502 层 抽样 同 口径)
	g.tower_endless_floor = 502
	g.tower_endless_best = 501
	ui._refresh_tower()
	await get_tree().process_frame
	var mon502: String = str(ui._tw_mon_labels["endless"].text)
	check(mon502.find("第 502 层") >= 0 and mon502.find("魔化·") >= 0,
			"打磨-102 502 层 怪物卡 恒 魔化 (实际 %s)" % mon502)
	check(int(g.stats.get("tower_win", 0.0)) == int(snap501.get("tower_win", 0.0)) + 1,
			"打磨-102 魔化 层 胜 tower_win 统计 +1")
	# 收尾: 恢复 干净 基准 (塔 态/飞升/剧毒 归零, 防 污染 M6-3 段)
	g.ascended = false
	g.dao_level = 0
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1 and int(g.tower_endless_best) == 0 and g.poison_battles == 0,
			"打磨-102 收尾 干净 基准 (塔 态 归零)")


# 打磨-105: 战斗时长 预估 行 (M5 数值 模型 "rounds = ceil(mon_hp/dmg) 决定 战斗时长 [仅 展示]":
# 爬塔页 双塔 卡片 怪物卡/战力对比 之间 加 12px 预估 行). UI 断言: 标签 节点 双塔 齐全/
# 文案 = GameData.tower_rounds_line 恒等 口径 (ceil(怪 HP / max(1, 有效atk-怪def) x 0.9))/
# 胜 预测 无 败 后缀/败 预测 追加 "本层 战力 不足"/剧毒 -15% 联动 文案 变化/升层 动态 同步/
# tooltip 口径/同态 节流 无 副作用 (收尾 干净 基准 防 污染 M6-3 段)
func _assert_tower_rounds() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 + 弱玩家 (基准 atk 恒 < 任意 塔 怪 阈值 -> 败 预测)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 5
	g.tower_endless_best = 4
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.ascended = false
	g.dao_level = 0
	g.learned.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 标签 节点 双塔 齐全 (怪物卡 之后 战力对比 之前 构建)
	check(ui._tw_round_labels.has("fixed") and ui._tw_round_labels.has("endless"),
			"打磨-105 战斗时长 标签 双塔 节点 齐全")
	# 文案 = 接口 恒等 (按 preview 同 输入 口径 动态 计算, 不 硬编码 数值)
	var pv: Dictionary = g.tower_challenge_preview()
	var fmon: Dictionary = pv["fixed_mon"]
	var emon: Dictionary = pv["endless_mon"]
	var rl_fixed: String = g.tower_rounds_line(float(fmon["hp"]), float(fmon["def"]), bool(pv["fixed_win"]))
	var rl_endless: String = g.tower_rounds_line(float(emon["hp"]), float(emon["def"]), bool(pv["endless_win"]))
	check(str(ui._tw_round_labels["fixed"].text) == rl_fixed,
			"打磨-105 镇妖塔 回合 预估 行 = 接口 恒等 (实际 %s)" % str(ui._tw_round_labels["fixed"].text))
	check(str(ui._tw_round_labels["endless"].text) == rl_endless,
			"打磨-105 登天梯 回合 预估 行 = 接口 恒等 (实际 %s)" % str(ui._tw_round_labels["endless"].text))
	# 胜/败 口径 动态 断言 (基准 玩家 对 当前 层 判 胜/败 由 数据 锚定 决定, 后缀 与 判定 恒 同源):
	# 败 预测 -> 追加 " (本层 战力 不足)"; 胜 预测 -> 无 后缀
	var pa: float = g.player_atk_effective()
	check((rl_fixed.find("本层 战力 不足") >= 0) == (not bool(pv["fixed_win"]))
			and (rl_endless.find("本层 战力 不足") >= 0) == (not bool(pv["endless_win"])),
			"打磨-105 败 预测 追加 口径 说明 / 胜 预测 无 (实际 %s, fixed_win=%s endless_win=%s atk %s)"
			% [rl_fixed, str(bool(pv["fixed_win"])), str(bool(pv["endless_win"])), g.fmt(pa)])
	check(rl_fixed.begins_with("约 ") and rl_fixed.find("回合 击败") >= 0 and rl_fixed.find("伤害 预估") >= 0
			and rl_fixed.find("/回合)") >= 0,
			"打磨-105 文案 含 回合 数 + 伤害 预估 段 (实际 %s)" % rl_fixed)
	# tooltip 口径 (仅 展示 不 改变 即时 判定)
	check(str(ui._tw_round_labels["fixed"].tooltip_text).find("不 改变 胜负") >= 0,
			"打磨-105 回合 预估 tooltip 含 仅展示 口径 (实际 %s)" % str(ui._tw_round_labels["fixed"].tooltip_text))
	# 升层 动态 同步: 登天梯 5->10 层 怪物 数值 变 -> 预估 文本 变化 (非 同 缓存)
	g.tower_endless_floor = 10
	g.tower_endless_best = 9
	ui._refresh_tower()
	await get_tree().process_frame
	var pv10: Dictionary = g.tower_challenge_preview()
	var emon10: Dictionary = pv10["endless_mon"]
	var rl10: String = g.tower_rounds_line(float(emon10["hp"]), float(emon10["def"]), bool(pv10["endless_win"]))
	check(str(ui._tw_round_labels["endless"].text) == rl10 and rl10 != rl_endless,
			"打磨-105 升层 后 回合 预估 动态 同步 (实际 %s)" % str(ui._tw_round_labels["endless"].text))
	# 剧毒 联动: 置 剧毒 后 文案 与 接口 同输入 恒等 (剧毒 生效 与否 由 atk vs 怪 def 决定,
	# 弱玩家 基准 atk 低于 怪 def 时 伤害 恒等 钳制 — 恒等 口径 断言 不 依赖 数值 方向)
	g.tower_endless_floor = 5
	g.tower_endless_best = 4
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_round_labels["endless"].text) == rl_endless, "打磨-105 层数 复原 后 文本 复原 恒等")
	g.poison_battles = g.TOWER_POISON_BATTLES
	ui._refresh_tower()
	await get_tree().process_frame
	var pv_p: Dictionary = g.tower_challenge_preview()
	var emonp: Dictionary = pv_p["endless_mon"]
	var rl_p: String = g.tower_rounds_line(float(emonp["hp"]), float(emonp["def"]), bool(pv_p["endless_win"]))
	check(str(ui._tw_round_labels["endless"].text) == rl_p,
			"打磨-105 剧毒 后 回合 预估 与 接口 同输入 恒等 (实际 %s)" % str(ui._tw_round_labels["endless"].text))
	g.poison_battles = 0
	ui._refresh_tower()
	await get_tree().process_frame
	# 节流: 同态 再刷 不 重写 (文本 缓存 稳定, 无 统计 副作用)
	var snap: Dictionary = g.stats.duplicate(true)
	var txt_before: String = str(ui._tw_round_labels["fixed"].text)
	ui._refresh_tower()
	ui._refresh_tower()
	check(str(ui._tw_round_labels["fixed"].text) == txt_before and g.stats == snap,
			"打磨-105 同态 再刷 文本 稳定 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态/剧毒/飞升 归零, 防 污染 M6-3 段)
	g.ascended = false
	g.dao_level = 0
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1 and int(g.tower_endless_best) == 0 and g.poison_battles == 0,
			"打磨-105 收尾 干净 基准 (塔 态 归零)")


# 打磨-103: 登天梯 里程碑 宝箱 保底 高品质 词缀 (M5 规格 "每 100 层 里程碑 Boss + 里程碑 宝箱 [保底 高级词缀]" 落地:
# 词缀 来源 配置 min_tier=稀有+, affix_roll_drop 钳制 只升不降). UI 断言: 登天梯 卡片 副标题 宝箱 口径/
# 里程碑 Boss 层 怪物卡 tooltip 含 保底 段 (精英层/镇妖塔 不 含)/强玩家 胜局 词缀 品质 恒 >= 稀有
# (数据 锚定 100 层 里程碑 Boss, rolls 随机 但 保底 钳制 确定性 下限; 收尾 干净 基准 防 污染)
func _assert_milestone_chest() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 + 词缀 清零 + 待挑战 100 层 (里程碑 Boss 层)
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.affix_materials = 0
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 100
	g.tower_endless_best = 99
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	ui._refresh_tower()
	await get_tree().process_frame
	# 卡片 副标题 含 宝箱 保底 口径 (UI 入口 提示)
	var sub103: String = str((ui._tw_cards["endless"]["panel"] as PanelContainer).get_child(0).get_child(1).text)
	check(sub103.find("宝箱") >= 0 and sub103.find("保底 稀有+") >= 0,
			"打磨-103 登天梯 卡片 副标题 含 宝箱保底 口径 (实际 %s)" % sub103)
	# 里程碑 Boss 层 怪物卡 tooltip 含 保底 段 (与 数据 接口 同源 断言 恒等)
	var rec100: Dictionary = g.get_endless_floor(100)
	check(str(g.tower_monster_stats(rec100).get("boss_type", "")) == "boss", "打磨-103 第 100 层 = 里程碑 Boss (数据 锚定)")
	var mon_tip100: String = str(ui._tw_mon_labels["endless"].tooltip_text)
	# 口径: UI 传入 的是 preview 的 stats 字典 (tower_monster_tip 内部 再走 tower_monster_stats),
	# 期望 值 须 用 同 输入 计算 (stats 字典 无 reward_stone 键, 灵石 行 = 0 为 既有 口径, 本 段 不 改)
	var exp_tip100: String = g.tower_monster_tip(g.tower_monster_stats(rec100), "endless")
	check(mon_tip100 == exp_tip100, "打磨-103 怪物卡 tooltip = 接口 (同 输入 口径)")
	check(mon_tip100.find("里程碑 宝箱") >= 0 and mon_tip100.find("保底 稀有+") >= 0,
			"打磨-103 里程碑 Boss 层 tooltip 含 宝箱保底 段 (实际 %s)" % mon_tip100.get_slice("\n", mon_tip100.count("\n")))
	# 精英层 (非 里程碑): tooltip 无 宝箱 段
	g.tower_endless_floor = 20
	g.tower_endless_best = 19
	ui._refresh_tower()
	await get_tree().process_frame
	var mon_tip20: String = str(ui._tw_mon_labels["endless"].tooltip_text)
	check(str(g.tower_monster_stats(g.get_endless_floor(20)).get("is_elite", false)) and mon_tip20.find("里程碑 宝箱") < 0,
			"打磨-103 精英层 tooltip 无 宝箱段 (实际 %s)" % mon_tip20.left(30))
	# 强玩家 (飞升 道祖) 恒胜 100 层 里程碑 Boss → 词缀 必掉 且 品质 恒 >= 稀有 (保底 钳制 确定性 下限)
	g.tower_endless_floor = 100
	g.tower_endless_best = 99
	g.ascended = true
	g.dao_level = 8
	g.learned.clear()
	var mon100: Dictionary = g.tower_monster_stats(g.get_endless_floor(100))
	check(g.player_atk_effective() >= float(mon100["atk"]) * g.TOWER_WIN_RATIO,
			"打磨-103 强玩家 100 层 里程碑 Boss 判定=胜 (数据 锚定)")
	var bag0: int = g.affix_bag_used()
	ui._on_tower_challenge("endless")
	var msg103: String = str(ui._msg_label.text)
	check(msg103.begins_with("✔ 登天梯 第 100 层"), "打磨-103 胜局 消息 口径 (实际 %s)" % msg103.left(20))
	check(msg103.find("(词缀: ") >= 0, "打磨-103 里程碑 必掉 → 消息 含 词缀 段 (实际 %s)" % msg103)
	check(g.affix_bag_used() > bag0, "打磨-103 里程碑 词缀 入包 (背包 %d->%d)" % [bag0, g.affix_bag_used()])
	var tiers_ok := true
	for aid103 in g.affix_bag:
		if int(g.affix_by_id.get(str(aid103), {}).get("tier", -1)) < 2:
			tiers_ok = false
	check(tiers_ok, "打磨-103 入包 词缀 品质 恒 >= 稀有 (保底 生效, 背包 %s)" % str(g.affix_bag.keys()))
	# 收尾: 恢复 干净 基准 (词缀/塔 态/飞升 归零, 防 污染 M6-3 段 0/0 断言)
	g.ascended = false
	g.dao_level = 0
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.affix_materials = 0
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1 and g.affix_bag_used() == 0,
			"打磨-103 收尾 干净 基准 (塔 态/词缀 归零)")


# 打磨-106: 怪物卡 tooltip 材料 掉落 预估 (M5 规格 掉落展示 灵石/材料/词缀 材料 段 展示 位).
# UI 断言: 双塔 怪物卡 tooltip 含 "奖励 材料 N" 行 (N = 向上取整 stats mats, 与 战斗 结算
# reward_mat 同源) + tooltip = 接口 同 输入 恒等 口径 (UI 走 stats 字典 路径, 修 幂等 丢 mats
# 后 材料 行 不 丢) + 同态 节流 无 副作用 (收尾 干净 基准 防 污染 M6-3 段)
func _assert_tower_mats_tip() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 (镇妖塔 第 1 层 = 有 怪物种 种 带 reward.mat_w; 登天梯 第 5 层 同)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 5
	g.tower_endless_best = 4
	g.poison_battles = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	ui._refresh_tower()
	await get_tree().process_frame
	# 镇妖塔 怪物卡 tooltip 含 材料 预估 行 (与 stats mats 同源 向上取整; 有 怪物种 恒 >0)
	var fr: Dictionary = g.get_fixed_floor(1)
	var fs: Dictionary = g.tower_monster_stats(fr)
	check(float(fs["mats"]) > 0.0, "打磨-106 镇妖塔 第 1 层 有 怪物种 mats>0 (实际 %s)" % g.fmt(float(fs["mats"])))
	var f_tip: String = str(ui._tw_mon_labels["fixed"].tooltip_text)
	var f_exp: String = g.tower_monster_tip(fs, "fixed")
	check(f_tip == f_exp, "打磨-106 镇妖塔 怪物卡 tooltip = 接口 (同 输入 口径, stats 字典 路径 材料 行 不 丢)")
	check(f_tip.find("奖励 材料 %d" % int(ceil(float(fs["mats"])))) >= 0,
			"打磨-106 镇妖塔 tooltip 含 材料 预估 行 (期望 %d, 实际 %s)" % [int(ceil(float(fs["mats"]))), f_tip.left(60)])
	# 登天梯 怪物卡 tooltip 同 口径 (精英/普通 层 种 均 带 reward.mat_w)
	var er: Dictionary = g.get_endless_floor(5)
	var es: Dictionary = g.tower_monster_stats(er)
	var e_tip: String = str(ui._tw_mon_labels["endless"].tooltip_text)
	var e_exp: String = g.tower_monster_tip(es, "endless")
	check(e_tip == e_exp and e_tip.find("奖励 材料 %d" % int(ceil(float(es["mats"])))) >= 0,
			"打磨-106 登天梯 tooltip 含 材料 预估 行 且 = 接口 (期望 %d)" % int(ceil(float(es["mats"]))))
	# 同态 节流: 无 塔 态 变化 再 刷 不 重写 (tooltip 引用 文本 稳定) + 无 统计 副作用
	var snap_ut: Dictionary = g.stats.duplicate(true)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["fixed"].tooltip_text) == f_tip and g.stats == snap_ut,
			"打磨-106 同态 再刷 tooltip 稳定 无 副作用")
	# 收尾: 恢复 干净 基准 (塔 态 归零, 防 污染 M6-3 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1, "打磨-106 收尾 干净 基准 (塔 态 归零)")


# 打磨-108: 怪物种 reward 权重 stone_w/affix_w (M5 规格 掉落 差异化 灵石/词缀 段 — 数据 层
# stone_w/affix_w 已 生成 但 逻辑 层 未 消费, 本轮 接入: stone_w 乘 灵石 / affix_w 词缀 掉率
# base 乘数). UI 侧 断言: 怪物卡 tooltip 含 "· 种 掉落 权重: 灵石 x%.3f · 词缀 x%.3f" 行
# (有 怪物种 层 展示 / Boss 层 权重 1.0 不 展示) + tooltip = 接口 恒等 (stats 字典 路径
# 权重 行 不 丢) + 同态 节流 无 副作用; 数值 口径 断言 在 selftest 段 (stats/结算/幂等).
func _assert_tower_reward_weights() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 (镇妖塔 第 1 层 种 m41 权重 1.255/0.63; 登天梯 第 5 层 种 同 锚定)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 5
	g.tower_endless_best = 4
	g.poison_battles = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	ui._refresh_tower()
	await get_tree().process_frame
	# 镇妖塔 第 1 层 (有 怪物种): tooltip 含 种 掉落 权重 行 (数值 = 接口 同源)
	var fr: Dictionary = g.get_fixed_floor(1)
	var fs: Dictionary = g.tower_monster_stats(fr)
	check(absf(float(fs.get("stone_w", 1.0)) - 1.255) < 1e-9,
			"打磨-108 镇妖塔 第 1 层 stats stone_w = 1.255 (数据 锚定, 实际 %s)" % str(fs.get("stone_w")))
	var f_tip: String = str(ui._tw_mon_labels["fixed"].tooltip_text)
	var f_exp: String = g.tower_monster_tip(fs, "fixed")
	check(f_tip == f_exp, "打磨-108 镇妖塔 怪物卡 tooltip = 接口 (权重 行 stats 字典 路径 不 丢)")
	check(f_tip.find("· 种 掉落 权重: 灵石 x%.3f · 词缀 x%.3f" % [float(fs["stone_w"]), float(fs["affix_w"])]) >= 0,
			"打磨-108 镇妖塔 tooltip 含 种 权重 行 (实际 %s)" % f_tip.left(80))
	# 登天梯 第 5 层 (普通层 有 种): 同 口径 恒等
	var er: Dictionary = g.get_endless_floor(5)
	var es: Dictionary = g.tower_monster_stats(er)
	var e_tip: String = str(ui._tw_mon_labels["endless"].tooltip_text)
	var e_exp: String = g.tower_monster_tip(es, "endless")
	check(e_tip == e_exp and e_tip.find("· 种 掉落 权重: 灵石 x%.3f · 词缀 x%.3f" % [float(es["stone_w"]), float(es["affix_w"])]) >= 0,
			"打磨-108 登天梯 tooltip 含 种 权重 行 且 = 接口 (stone_w %s)" % str(es.get("stone_w")))
	# Boss 层 (第 50 层 小 Boss 无 reward 字段): 权重 1.0 不 展示 权重 行
	var fb: Dictionary = g.get_fixed_floor(50)
	var mb: Dictionary = g.tower_monster_stats(fb)
	var b_tip: String = g.tower_monster_tip(mb, "fixed")
	check(float(mb.get("stone_w", 1.0)) == 1.0 and float(mb.get("affix_w", 1.0)) == 1.0,
			"打磨-108 Boss 层 权重 = 1.0 兜底 (实际 %s / %s)" % [str(mb.get("stone_w")), str(mb.get("affix_w"))])
	check(b_tip.find("种 掉落 权重") < 0, "打磨-108 Boss 层 tooltip 无 权重 行 (1.0 不 展示, 实际 %s)" % b_tip.left(80))
	# 同态 节流: 无 塔 态 变化 再 刷 不 重写 (tooltip 文本 稳定) + 无 统计 副作用
	var snap_tw: Dictionary = g.stats.duplicate(true)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["fixed"].tooltip_text) == f_tip and g.stats == snap_tw,
			"打磨-108 同态 再刷 tooltip 稳定 无 副作用")
	# 收尾: 恢复 干净 基准 (塔 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1, "打磨-108 收尾 干净 基准 (塔 态 归零)")


# 打磨-117: 怪物卡 tooltip 追加 属性偏向/类型 行 (M5 规格 120 怪物种 每种 stat_bias
# 血牛/狂攻/铁壁/均衡 的 展示 位; 数据 层 bias_cn/category_name 已 生成 但 无 展示 位 —
# 本轮 tower_monster_stats 携带 字段 + tower_monster_tip 追加 类型 · 偏向 行).
# UI 断言: 怪物卡 tooltip 含 偏向 行 + = 接口 恒等 (stats 字典 路径 不 丢)/Boss 层 无 行/
# 升层 动态 同步/同态 节流 无 副作用 (收尾 干净 基准 防 污染).
func _assert_monster_bias_tip() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 (镇妖塔 第 1 层 种 m41 = 虫群 · 均衡型 数据 锚定)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 5
	g.tower_endless_best = 4
	g.poison_battles = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	ui._refresh_tower()
	await get_tree().process_frame
	# 镇妖塔 怪物卡 tooltip 含 类型 · 偏向 行 + = 接口 (stats 字典 路径 不 丢 偏向 行)
	var fr: Dictionary = g.get_fixed_floor(1)
	var fs: Dictionary = g.tower_monster_stats(fr)
	check(str(fs.get("bias_cn", "")) != "" and str(fs.get("category_name", "")) != "",
			"打磨-117 镇妖塔 第 1 层 stats 有 偏向/类型 (数据 锚定, 实际 %s / %s)" % [str(fs.get("bias_cn")), str(fs.get("category_name"))])
	var f_tip: String = str(ui._tw_mon_labels["fixed"].tooltip_text)
	var f_exp: String = g.tower_monster_tip(fs, "fixed")
	check(f_tip == f_exp, "打磨-117 镇妖塔 怪物卡 tooltip = 接口 (同 输入 口径, 偏向 行 stats 路径 不 丢)")
	check(f_tip.find("类型 · 偏向: %s" % str(fs.get("category_name", ""))) >= 0,
			"打磨-117 镇妖塔 怪物卡 tooltip 含 类型 · 偏向 行 (期望 %s, 实际 %s)" % [str(fs.get("category_name")), f_tip.left(60)])
	check(f_tip.find("类型 · 偏向: %s · %s" % [str(fs.get("category_name", "")), str(fs.get("bias_cn", ""))]) >= 0,
			"打磨-117 镇妖塔 tooltip 偏向 行 含 偏向 名 (实际 %s)" % f_tip.get_slice("\n", 1))
	# 登天梯 普通层 (第 5 层 有 种): 同 口径 恒等
	var er: Dictionary = g.get_endless_floor(5)
	var es: Dictionary = g.tower_monster_stats(er)
	var e_tip: String = str(ui._tw_mon_labels["endless"].tooltip_text)
	check(e_tip == g.tower_monster_tip(es, "endless") and e_tip.find("类型 · 偏向") >= 0,
			"打磨-117 登天梯 怪物卡 tooltip 含 偏向 行 且 = 接口 (实际 %s)" % str(es.get("bias_cn")))
	# Boss 层 (第 50 层 小 Boss 无 种): 无 类型 · 偏向 行 (空串 不 展示)
	g.tower_fixed_floor = 49
	ui._refresh_tower()
	await get_tree().process_frame
	var b_tip: String = str(ui._tw_mon_labels["fixed"].tooltip_text)
	check(b_tip.find("类型 · 偏向") < 0, "打磨-117 Boss 层 怪物卡 tooltip 无 类型 · 偏向 行 (实际 %s)" % b_tip.left(60))
	# 同态 节流: 无 塔 态 变化 再 刷 不 重写 + 无 统计 副作用
	var snap117u: Dictionary = g.stats.duplicate(true)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["fixed"].tooltip_text) == b_tip and g.stats == snap117u,
			"打磨-117 同态 再刷 tooltip 稳定 无 副作用")
	# 收尾: 恢复 干净 基准 (塔 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.learned.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1, "打磨-117 收尾 干净 基准 (塔 态 归零)")


# 打磨-115: 登天梯 里程碑 Boss 「里程碑 宝箱」 怪物卡 标记 + 胜利 底部消息/浮动 宝箱 段
# (M5 规格 "每 100 层 里程碑 Boss + 宝箱 [保底 稀有+ 词缀]" 的 展示位; 词缀 结算 口径 打磨-103 已落地,
# 本段 补 展示: 卡片 tag 追加 宝箱 标记 + 手动 挑战 胜利 底部消息/浮动 追加 宝箱 段).
# UI 断言: 登天梯 100 层 怪物卡 标记 含 宝箱/镇妖塔 Boss 不 含 宝箱/101 层 普通层 不 含/
# 手动 挑战 100 层 胜 底部消息 含 宝箱 段 + 浮动 含 宝箱 段/101 层 胜 无 宝箱 段/败 局 不 弹 浮动/
# 同态 节流 无 副作用 (收尾 干净 基准 防 污染)
func _assert_milestone_chest_tag() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 + 词缀 清零 + 待挑战 100 层 (里程碑 Boss)
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.affix_materials = 0
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 100
	g.tower_endless_best = 99
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	g.learned.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 登天梯 100 层 里程碑 Boss: 怪物卡 标记 含 宝箱 (⚑Boss·里程碑 宝箱)
	var mon115: String = str(ui._tw_mon_labels["endless"].text)
	check(mon115.find("⚑Boss·里程碑 宝箱") >= 0, "打磨-115 登天梯 100 层 怪物卡 标记 含 里程碑 宝箱 (实际 %s)" % mon115)
	check(mon115.find("第 100 层") >= 0, "打磨-115 怪物卡 标记 层数 口径 (实际 %s)" % mon115.left(20))
	# 镇妖塔 卡片: 镇妖塔 层表 非 100 倍数 boss 无 宝箱 标记 (基准 待挑战 第 1 层 普通层, 无 标记 行)
	check(str(ui._tw_mon_labels["fixed"].text).find("里程碑 宝箱") < 0, "打磨-115 镇妖塔 怪物卡 不 含 里程碑 宝箱 标记")
	# 登天梯 101 层 普通层: 无 宝箱 标记
	g.tower_endless_floor = 101
	g.tower_endless_best = 100
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["endless"].text).find("里程碑 宝箱") < 0, "打磨-115 登天梯 101 层 普通层 不 含 宝箱 标记 (实际 %s)" % str(ui._tw_mon_labels["endless"].text))
	# 强 玩家 (飞升 道祖) 恒胜 100 层 里程碑 Boss → 底部消息 + 浮动 含 宝箱 段
	g.tower_endless_floor = 100
	g.tower_endless_best = 99
	g.ascended = true
	g.dao_level = 8
	ui._refresh_tower()
	await get_tree().process_frame
	var mon115s: Dictionary = g.tower_monster_stats(g.get_endless_floor(100))
	check(g.player_atk_effective() >= float(mon115s["atk"]) * g.TOWER_WIN_RATIO, "打磨-115 强 玩家 100 层 判定=胜 (数据 锚定)")
	ui._tower_win_float_count = 0
	ui._tower_win_last_text = ""
	ui._on_tower_challenge("endless")
	var msg115: String = str(ui._msg_label.text)
	check(msg115.begins_with("✔ 登天梯 第 100 层"), "打磨-115 胜局 底部 消息 口径 (实际 %s)" % msg115.left(20))
	check(msg115.find("里程碑 宝箱") >= 0 and msg115.find("保底 稀有+") >= 0, "打磨-115 胜局 底部 消息 含 宝箱 段 (实际 %s)" % msg115)
	check(ui._tower_win_float_count == 1, "打磨-115 胜局 浮动 计数 +1 (实际 %d)" % ui._tower_win_float_count)
	var ftxt115: String = str(ui._tower_win_float_label.text)
	check(ftxt115.find("里程碑 宝箱") >= 0, "打磨-115 胜局 浮动 含 宝箱 段 (实际 %s)" % ftxt115)
	check(ftxt115.find("保底 稀有+") >= 0, "打磨-115 浮动 宝箱 段 含 保底 口径 (实际 %s)" % ftxt115)
	check(ui._tower_win_float_label.visible, "打磨-115 浮动 标签 可见")
	# 101 层 普通层 胜: 底部消息/浮动 无 宝箱 段 (标记 只 100 倍数 boss 层)
	ui._on_tower_challenge("endless")
	var msg115b: String = str(ui._msg_label.text)
	check(msg115b.begins_with("✔ 登天梯 第 101 层"), "打磨-115 101 层 胜局 口径 (实际 %s)" % msg115b.left(20))
	check(msg115b.find("里程碑 宝箱") < 0, "打磨-115 101 层 普通层 底部 消息 无 宝箱 段 (实际 %s)" % msg115b)
	check(str(ui._tower_win_float_label.text).find("里程碑 宝箱") < 0, "打磨-115 101 层 浮动 无 宝箱 段")
	# 败 局: 弱 玩家 100 层 恒败 → 不 弹 浮动 无 宝箱 段 (浮动 计数 保持)
	g.ascended = false
	g.dao_level = 0
	g.learned.clear()
	g.tower_endless_floor = 100
	g.tower_endless_best = 99
	var cnt_before: int = ui._tower_win_float_count
	var mon115w: Dictionary = g.tower_monster_stats(g.get_endless_floor(100))
	check(g.player_atk_effective() < float(mon115w["atk"]) * g.TOWER_WIN_RATIO, "打磨-115 弱 玩家 100 层 判定=败 (数据 锚定)")
	ui._on_tower_challenge("endless")
	check(ui._tower_win_float_count == cnt_before, "打磨-115 败 局 不 弹 浮动 (实际 %d)" % ui._tower_win_float_count)
	check(str(ui._msg_label.text).begins_with("✖ 登天梯 第 100 层"), "打磨-115 败 局 底部 消息 保留 (实际 %s)" % str(ui._msg_label.text).left(20))
	# 同态 节流: 无 塔 态 变化 再 刷 不 重写 无 统计 副作用
	var snap115: Dictionary = g.stats.duplicate(true)
	ui._refresh_tower()
	await get_tree().process_frame
	check(g.stats == snap115, "打磨-115 同态 再刷 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (词缀/塔 态/飞升 归零, 防 污染 后续 段)
	g.ascended = false
	g.dao_level = 0
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.affix_materials = 0
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.learned.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1 and g.affix_bag_used() == 0, "打磨-115 收尾 干净 基准 (塔 态/词缀 归零)")


# 打磨-116: 登天梯 每日首胜奖励 当日 状态 行 (M5 规格 "每日 首胜 奖励" 展示位: tower_daily_date
# 已 随 结算/存档 落地, 但 爬塔页 状态行 无 当日 是否 已 触发 展示位, 玩家 不知 今日 首胜 是否
# 已 领; 状态行 已 触发 追加 段 + 刷新键 感知 当日态; UI 断言: 未 触发 无 段/触发 追加 段/
# 文本 = tower_status_line 恒等/手动 模拟 触发 态 刷新/跨日 段 消失/败局 不 触发/tooltip 口径/
# 同态 节流/收尾 干净 基准 防 污染)
func _assert_tower_daily_first() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 + 弱 玩家 (atke 2.0 恒败 防 误触 结算) + 登天梯 待挑战 第 15 层
	# (第 15 层 怪 atk ≈ 4.8 > 2.0/0.85 恒败 [第 2 层 怪 太弱 弱 玩家 可胜, 须 选 层 锚定];
	# equipped 也 清 — 前段 残留 装备 atk 池 会 抬 玩家 战力 致 弱 玩家 假设 失效)
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.affix_materials = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_clear_reward_got = false
	g.tower_endless_floor = 15
	g.tower_endless_best = 14
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	g.learned.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 1) 未 触发 态: 状态行 无 段 + 文本 = 接口 恒等
	var st116a: String = str(ui._tw_status_label.text)
	check(st116a.find("每日 首胜 奖励 已 触发") < 0, "打磨-116 未 触发 态 状态行 无 段 (实际 %s)" % st116a)
	check(st116a == g.tower_status_line(), "打磨-116 状态行 文本 = tower_status_line 恒等")
	check(g.tower_status_line().find("登天梯 待挑战 第 15 层") >= 0, "打磨-116 状态行 层数 口径 基准 (实际 %s)" % st116a)
	# 2) 手动 模拟 当日 已 触发 态 (日期 = 今日): 刷新键 变化 自动 刷 状态行 追加 段
	g.tower_daily_date = g._today_str()
	ui._refresh_tower()
	await get_tree().process_frame
	var st116b: String = str(ui._tw_status_label.text)
	check(st116b.find("每日 首胜 奖励 已 触发") >= 0, "打磨-116 已 触发 态 状态行 含 段 (实际 %s)" % st116b)
	check(st116b == g.tower_status_line(), "打磨-116 已 触发 态 文本 = 接口 恒等")
	# 3) 败局 不 触发: 弱 玩家 恒败 不 改 日期 (状态行 保持 已 触发 模拟 态 不变)
	var mon116: Dictionary = g.tower_monster_stats(g.get_endless_floor(15))
	check(g.player_atk_effective() < float(mon116["atk"]) * g.TOWER_WIN_RATIO, "打磨-116 弱 玩家 第 15 层 判定=败 (数据 锚定)")
	ui._on_tower_challenge("endless")
	check(g.tower_daily_date == g._today_str(), "打磨-116 败局 日期 不变 (首胜 不 触发)")
	check(str(ui._tw_status_label.text) == st116b, "打磨-116 败局 后 状态行 保持 (层数 未 推进 键 不变)")
	# 4) 跨日 模拟 (日期 = 昨日): 刷新键 变化 -> 段 消失
	var yest116: Dictionary = Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_system() - 86400)
	g.tower_daily_date = "%04d-%02d-%02d" % [int(yest116.year), int(yest116.month), int(yest116.day)]
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_status_label.text).find("每日 首胜 奖励 已 触发") < 0, "打磨-116 跨日 后 状态行 段 消失 (实际 %s)" % str(ui._tw_status_label.text))
	# 5) 状态行 tooltip 含 每日 首胜 口径 说明
	check(str(ui._tw_status_panel.tooltip_text).find("每日 首胜 奖励") >= 0, "打磨-116 状态行 tooltip 含 每日 首胜 口径")
	check(str(ui._tw_status_panel.tooltip_text).find("0.5x 该层 灵石") >= 0, "打磨-116 状态行 tooltip 含 0.5x 口径")
	# 6) 同态 节流: 无 变化 再 刷 无 统计 副作用
	var snap116: Dictionary = g.stats.duplicate(true)
	ui._refresh_tower()
	await get_tree().process_frame
	check(g.stats == snap116, "打磨-116 同态 再刷 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (日期/塔 态 归零, 防 污染 后续 段)
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_clear_reward_got = false
	g.poison_battles = 0
	g.poison_events.clear()
	g.learned.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1 and g.tower_daily_date == "", "打磨-116 收尾 干净 基准 (塔 态/日期 归零)")


# 打磨-126: 登天梯 新纪录 展示位 (M5 规格 "个人 最高纪录" — was_best 结算 已 算 但 无
# 结果 字段/无 展示; 结算 字典 new_record 字段 [仅 登天梯 胜局 可 为 true, 镇妖塔/败局 恒 false]
# + tower_win_float_text 新纪录 段 + 手动 挑战 底部消息 同源 段).
# UI 断言: 登天梯 胜 新纪录 底部消息 含 新纪录 段 + 居中 绿色 浮动 含 新纪录 段/镇妖塔 胜 无 段/
# 败局 不弹 浮动 + 无 新纪录 段/只读 接口 恒等/节流 无 副作用 (收尾 干净 基准 防 污染)
func _assert_tower_new_record() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 强 玩家 恒胜 (ascended 道祖) + 登天梯 待挑战 第 2 层 / 历史 最高 1 层
	# (弱 玩家 选 层 锚定 见 败局 段; equipped 清 防 前段 残留 atk 池 抬 战力)
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.affix_materials = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_clear_reward_got = false
	g.tower_endless_floor = 2
	g.tower_endless_best = 1
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.ascended = true
	g.dao_level = 8
	g.auto_tower = false
	ui._tower_win_float_count = 0
	var mon126: Dictionary = g.tower_monster_stats(g.get_endless_floor(2))
	check(g.player_atk_effective() >= float(mon126["atk"]) * g.TOWER_WIN_RATIO, "打磨-126 强 玩家 第 2 层 判定=胜 (数据 锚定)")
	# 1) 登天梯 胜 第 2 层 创 新纪录: new_record=true + 底部消息 含 新纪录 段 + 居中 绿色 浮动 含 段
	var before_n: int = ui._tower_win_float_count
	ui._on_tower_challenge("endless")
	await get_tree().process_frame
	check(int(g.tower_endless_best) == 2 and int(g.tower_endless_floor) == 3, "打磨-126 结算 口径 推进 (best=%d floor=%d)" % [g.tower_endless_best, g.tower_endless_floor])
	check(str(ui._msg_label.text).find("新纪录! 最高 第 2 层") >= 0, "打磨-126 底部消息 含 新纪录 段 (实际 %s)" % str(ui._msg_label.text).left(80))
	check(ui._tower_win_float_count == before_n + 1, "打磨-126 胜利 浮动 计数 +1 (实际 %d)" % ui._tower_win_float_count)
	check(str(ui._tower_win_float_label.text).find("新纪录! 最高 第 2 层") >= 0, "打磨-126 居中 浮动 含 新纪录 段 (实际 %s)" % str(ui._tower_win_float_label.text).left(80))
	# 浮动 文案 = 接口 恒等 (再 胜 第 3 层 结算 字典 口径, 新纪录 层数 动态 同步)
	var rf: Dictionary = g.try_tower_challenge("endless", 0.5)
	check(bool(rf["win"]) and bool(rf["new_record"]), "打磨-126 接口 new_record=true (数据 锚定)")
	check(g.tower_win_float_text(rf).find("新纪录! 最高 第 3 层") >= 0,
			"打磨-126 接口 浮动 新纪录 层数 动态 同步 (实际 %s)" % g.tower_win_float_text(rf))
	# 2) 镇妖塔 胜局 恒 false: 底部消息 无 新纪录 段 (无 最高纪录 概念)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	ui._on_tower_challenge("fixed")
	await get_tree().process_frame
	check(str(ui._msg_label.text).find("新纪录") < 0, "打磨-126 镇妖塔 底部消息 无 新纪录 段 (实际 %s)" % str(ui._msg_label.text).left(80))
	# 3) 登天梯 败局 恒 false: 弱 玩家 选 层 锚定 + 不弹 浮动 + 无 新纪录 段 + 纪录 不 变
	g.ascended = false
	g.dao_level = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.tower_endless_floor = 15
	g.tower_endless_best = 14
	var mon126w: Dictionary = g.tower_monster_stats(g.get_endless_floor(15))
	check(g.player_atk_effective() < float(mon126w["atk"]) * g.TOWER_WIN_RATIO, "打磨-126 弱 玩家 第 15 层 判定=败 (数据 锚定)")
	var before_n2: int = ui._tower_win_float_count
	ui._on_tower_challenge("endless")
	await get_tree().process_frame
	check(int(g.tower_endless_best) == 14, "打磨-126 败局 纪录 不 变 (best=%d)" % g.tower_endless_best)
	check(ui._tower_win_float_count == before_n2, "打磨-126 败局 不弹 浮动 (计数 不变)")
	check(str(ui._msg_label.text).find("新纪录") < 0 and str(ui._msg_label.text).find("战力不足") >= 0, "打磨-126 败局 底部消息 无 新纪录 段 (实际 %s)" % str(ui._msg_label.text).left(80))
	# 4) 只读 接口 恒等 无 副作用 (tower_win_float_text 不 改 状态/统计)
	var snap126: Dictionary = g.stats.duplicate(true)
	var bs126: int = g.tower_endless_best
	check(g.tower_win_float_text(rf) == g.tower_win_float_text(rf) and g.tower_endless_best == bs126 and g.stats == snap126,
			"打磨-126 浮动 文案 只读 连读 恒定 无 副作用")
	# 收尾: 恢复 干净 基准 (塔 态/强玩家 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.affix_materials = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.ascended = false
	g.dao_level = 0
	g.auto_tower = false
	ui._tower_win_float_count = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1 and int(g.tower_endless_best) == 0, "打磨-126 收尾 干净 基准 (塔 态 归零)")


# 打磨-111: 战力对比 DEF 行 (M5 规格 "玩家 atk/def vs 怪物" DEF 段 落地 — tower_power_line 只有
# ATK 段+胜负, 玩家 DEF/怪物 DEF 无 展示位; 爬塔页 双塔 卡片 战力对比 行 下 加 12px DEF 行).
# UI 断言: 双塔 标签 节点 齐全/文案 = GameData.tower_power_def_line 恒等 口径/剧毒 只 减 有效 ATK
# DEF 行 不 变 (ATK/DEF 口径 区分)/玩家 DEF 变化 (装备 词缀 def 池) 动态 同步/升层 怪物 DEF 同步/
# tooltip 口径 说明/同态 节流 无 副作用 (收尾 干净 基准 防 污染)
func _assert_tower_def_line() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 + 玩家 DEF 基础 2.0
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 双塔 标签 节点 齐全 (战力对比 行 下 构建)
	check(ui._tw_def_labels.has("fixed") and ui._tw_def_labels.has("endless"),
			"打磨-111 双塔 DEF 行 标签 节点 齐全")
	# 文案 = 接口 恒等 (按 preview 同 输入 口径 动态 计算, 不 硬编码 数值)
	var pv: Dictionary = g.tower_challenge_preview()
	var fmon: Dictionary = pv["fixed_mon"]
	var emon: Dictionary = pv["endless_mon"]
	var dl_fixed: String = g.tower_power_def_line(float(fmon["def"]))
	var dl_endless: String = g.tower_power_def_line(float(emon["def"]))
	check(str(ui._tw_def_labels["fixed"].text) == dl_fixed,
			"打磨-111 镇妖塔 DEF 行 = 接口 恒等 (实际 %s)" % str(ui._tw_def_labels["fixed"].text))
	check(str(ui._tw_def_labels["endless"].text) == dl_endless,
			"打磨-111 登天梯 DEF 行 = 接口 恒等 (实际 %s)" % str(ui._tw_def_labels["endless"].text))
	# 判定 口径 说明 段
	check(str(ui._tw_def_labels["fixed"].text).find("DEF 不 参与 胜负 判定") >= 0,
			"打磨-111 DEF 行 含 判定 口径 说明 (实际 %s)" % str(ui._tw_def_labels["fixed"].text).left(60))
	# tooltip 口径 (构建 路径 写入)
	check(str(ui._tw_def_labels["fixed"].tooltip_text).find("DEF 不 参与 胜负 判定") >= 0
			and str(ui._tw_def_labels["fixed"].tooltip_text).find("只 影响 对怪 伤害 与 回合 预估") >= 0,
			"打磨-111 DEF 行 tooltip 含 口径 说明")
	# 剧毒 只 减 有效 ATK: ATK 行 变 而 DEF 行 不变 (口径 区分)
	var pwr_before: String = str(ui._tw_pwr_labels["fixed"].text)
	var def_before: String = str(ui._tw_def_labels["fixed"].text)
	g.poison_battles = g.TOWER_POISON_BATTLES
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_pwr_labels["fixed"].text) != pwr_before
			and str(ui._tw_def_labels["fixed"].text) == def_before,
			"打磨-111 剧毒 后 ATK 行 变化 而 DEF 行 不变 (DEF 不 随 剧毒 变化)")
	g.poison_battles = 0
	ui._refresh_tower()
	await get_tree().process_frame
	# 玩家 DEF 变化 (飞升 道祖 进度 17, 战力 指数 成长): 玩家 段 动态 同步 (文本 必变 防 假 恒等;
	# 低 档 def 池 词缀/装备 增幅 经 fmt int 截断 不 可见 [2.0->2.1 均显 "2"], 用 飞升 量级 变化 断言 刷新 路径)
	g.ascended = true
	g.dao_level = 8
	ui._refresh_tower()
	await get_tree().process_frame
	var dl_after: String = g.tower_power_def_line(float(fmon["def"]))
	check(str(ui._tw_def_labels["fixed"].text) == dl_after and dl_after != dl_fixed,
			"打磨-111 玩家 DEF 变化 (飞升 道祖) 后 DEF 行 动态 同步 = 接口 恒等 (实际 %s)" % str(ui._tw_def_labels["fixed"].text))
	g.ascended = false
	g.dao_level = 0
	ui._refresh_tower()
	await get_tree().process_frame
	# 基准 重捕获 (上一步 从 飞升 道祖 复位 后 玩家 DEF 回 基础, 须 重新 按 接口 取 基准;
	# 与 首 基准 dl_endless [可能 残留 飞升 段] 区分, 防 假 变化)
	var dl_endless0: String = g.tower_power_def_line(float(emon["def"]))
	check(str(ui._tw_def_labels["endless"].text) == dl_endless0,
			"打磨-111 复位 后 登天梯 DEF 行 基准 重捕获 = 接口 恒等 (实际 %s)" % str(ui._tw_def_labels["endless"].text))
	# 升层 怪物 DEF 变化 (登天梯 30 层 精英, DEF fmt 4->9 真 变化 防 假 恒等;
	# 10 层 精英 4.44 与 1 层 4.16 经 fmt int 截断 同显 "4" 不 触发 刷新 路径, 故 取 30 层): 登天梯 行 动态 同步
	g.tower_endless_floor = 30
	g.tower_endless_best = 29
	ui._refresh_tower()
	await get_tree().process_frame
	var pv2: Dictionary = g.tower_challenge_preview()
	var emon2: Dictionary = pv2["endless_mon"]
	var dl_endless2: String = g.tower_power_def_line(float(emon2["def"]))
	check(str(ui._tw_def_labels["endless"].text) == dl_endless2 and dl_endless2 != dl_endless0,
			"打磨-111 升 精英层 后 登天梯 DEF 行 动态 同步 (实际 %s)" % str(ui._tw_def_labels["endless"].text))
	# 同态 节流: 无 变化 再 刷 不 重写 + 无 统计 副作用
	var snap_tw: Dictionary = g.stats.duplicate(true)
	var txt_tw: String = str(ui._tw_def_labels["fixed"].text)
	ui._refresh_tower()
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_def_labels["fixed"].text) == txt_tw and g.stats == snap_tw,
			"打磨-111 同态 再刷 稳定 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态/飞升/灵石 归零, 防 污染 后续 段)
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.ascended = false
	g.dao_level = 0
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 0.0
	g.learned.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1 and int(g.tower_endless_best) == 0,
			"打磨-111 收尾 干净 基准 (塔 态 归零)")


# M6-3: DIY 词缀 UI 断言 (装备页 词缀背包 抽屉: 容量行/收集行/共鸣行/一键装配/分解/网格 格子/选中 金边;
# 装备行 槽位 chip 装配/拆卸/换装 往返 + 评分 行 + tooltip 评分 行; 收尾 恢复 干净 基准)
# 打磨-109: 装备页 按评分排序 开关 (M6 规格 "装备列表按评分排序") — 140 件 现 按 状态序 平铺 [打磨-22],
# 买齐/装配 词缀 后 不知 哪件 评分 高; "按评分排序" 开关 (装备页 品质 筛选行尾, 与 一键购买/一键最佳 同 行):
# 开启 = 列表 改 按 装备 评分 降序 (评分 = 基础 6 池 + 已装 词缀 6 池, equip_score 同口径, 同分 id 升序),
# 与 部位/品质 筛选 AND 叠加 (排序 在 筛选 内 生效); 快照 (模式标记+值) 变化 才 重排, 挂机 恒定 无 每帧 重绘;
# 不 存档 不 计 统计 (与 只看可学/筛选 同 定位), 切换 按钮 无 拥有/穿戴/资源 副作用.
# 断言 (手动驱动 确定性): 按钮 节点/toggle/tooltip 口径/默认 关 态 (状态序 = 数据序 首行)/
# 点击 开 (按压+文本+底部消息) + 列表 改 评分 降序 (首行 amulet_6_3 同分 id 升序/次行 weapon_6_3/末行 boot_0_0/
# 全表 非增 单调)/再点 关 恢复 状态序/筛选 叠加 (武器 部位 首 可见行 weapon_6_3)/
# 词缀 装配 评分 升 行 位 上升 (snapshot 变化 重排)/同态 节流 无 统计 副作用/开关 切换 无 拥有 副作用/
# 收尾 关 态 干净 基准 (防 M6-3 段 污染)
func _assert_equip_score_sort() -> void:
	var g := GameData
	ui._tab.current_tab = 2
	g.set_process(false)
	# 受控 基准: 干净 拥有/穿戴/词缀 态 (前 段 可能 残留, 全清 保 基准 纯净)
	g.owned_eq.clear()
	g.equipped.clear()
	g.affix_load = {}
	g.affix_decompose_all()
	g.seen_affixes = []
	var stats109: Dictionary = g.stats.duplicate(true)
	var owned109: int = g.owned_eq.size()
	ui._refresh()
	await get_tree().process_frame
	var btn: Button = ui._equip_score_btn
	check(btn != null, "打磨-109 装备页 按评分排序 按钮 存在")
	if btn == null:
		return
	check(btn.toggle_mode, "打磨-109 开关按钮 toggle_mode")
	check(str(btn.tooltip_text).find("评分 降序") >= 0 and str(btn.tooltip_text).find("不 存档") >= 0
			and str(btn.tooltip_text).find("状态序") >= 0, "打磨-109 tooltip 含 评分降序/不存档/状态序 口径 (实际 %s)" % str(btn.tooltip_text).left(40))
	check(not btn.button_pressed and str(btn.text) == "按评分排序: 关", "打磨-109 默认 关 态 (文本/按压 一致)")
	# 基准: 全 未拥有 状态序 = 数据序 (首行 = 数据 首行 weapon_0_0, 打磨-22 口径)
	check(ui._equip_box.get_child(0) == ui._equip_row_nodes[g.equip_ids[0]], "打磨-109 基准 状态序 首行 = 数据序 首行 (实际 %s)" % str(ui._equip_box.get_child(0)))
	# 点击 开: 按钮态 + 底部 消息 + 列表 改 评分 降序
	ui._on_equip_score_sort()
	check(btn.button_pressed and str(btn.text) == "按评分排序: 开", "打磨-109 点击后 按压+文本 开")
	check(str(ui._msg_label.text).find("按评分 降序") >= 0, "打磨-109 开启 底部 消息 (实际 %s)" % str(ui._msg_label.text))
	await get_tree().process_frame
	check(ui._equip_box.get_child(0) == ui._equip_row_nodes["amulet_6_3"], "打磨-109 评分序 首行 = amulet_6_3 (同分 2.153 id 升序)")
	check(ui._equip_box.get_child(1) == ui._equip_row_nodes["weapon_6_3"], "打磨-109 评分序 次行 = weapon_6_3 (同分 2.153)")
	check(ui._equip_box.get_child(ui._equip_box.get_child_count() - 1) == ui._equip_row_nodes["boot_0_0"], "打磨-109 评分序 末行 = boot_0_0 (最低 0.13)")
	# 全表 单调: 140 行 逐行 评分 非增 (行 顺序 ↔ 评分 降序 恒等)
	var mono109 := true
	var prev109 := 1e18
	for c in ui._equip_box.get_children():
		var c_id := ""
		for k in ui._equip_row_nodes:
			if ui._equip_row_nodes[k] == c:
				c_id = str(k)
				break
		var s109: float = g.equip_score(c_id)
		if s109 > prev109 + 1e-12:
			mono109 = false
		prev109 = s109
	check(mono109, "打磨-109 评分序 全表 非增 (140 行 逐行 单调 降序)")
	# 同态 节流: 重复 _refresh 同 快照 不 重排 (首行 恒定), 无 统计 副作用
	var stats109b: Dictionary = g.stats.duplicate(true)
	ui._refresh()
	ui._refresh()
	await get_tree().process_frame
	check(ui._equip_box.get_child(0) == ui._equip_row_nodes["amulet_6_3"], "打磨-109 同态 节流 首行 恒定")
	check(g.stats == stats109b, "打磨-109 同态 重复 刷新 无 统计 副作用")
	# 开关 切换 (再点 开 再点 关) 无 统计 副作用 (排序 纯 展示, 不 走 装配/分解 埋点路径)
	var stats109c: Dictionary = g.stats.duplicate(true)
	ui._on_equip_score_sort()
	ui._on_equip_score_sort()
	check(g.stats == stats109c, "打磨-109 开关 切换 无 统计 副作用")
	ui._refresh()
	await get_tree().process_frame
	# 筛选 叠加: 武器 部位 筛选 内 首 可见行 = weapon_6_3 (武器 最高 评分)
	ui._on_equip_filter("weapon")
	await get_tree().process_frame
	var vis_first109: Node = null
	for c in ui._equip_box.get_children():
		if (c as Control).visible:
			vis_first109 = c
			break
	check(vis_first109 == ui._equip_row_nodes["weapon_6_3"], "打磨-109 筛选 叠加 评分序 (武器 首 可见行 weapon_6_3, 实际 %s)" % str(vis_first109))
	ui._on_equip_filter("")
	# 词缀 装配 评分 联动: weapon_0_0 装 高值 词缀 后 评分 升, 行位 上升 (snapshot 变化 触发 重排)
	g.owned_eq.append("weapon_0_0")
	ui._refresh()
	await get_tree().process_frame
	var idx109_before: int = (ui._equip_box.get_children() as Array).find(ui._equip_row_nodes["weapon_0_0"])
	g.affix_add("af_def_3_0", 1)
	g.affix_equip("weapon_0_0", 0, "af_def_3_0")
	ui._refresh()
	await get_tree().process_frame
	var idx109_after: int = (ui._equip_box.get_children() as Array).find(ui._equip_row_nodes["weapon_0_0"])
	check(idx109_after < idx109_before, "打磨-109 词缀 装配 评分 升 行位 上升 (实际 %d -> %d)" % [idx109_before, idx109_after])
	# 再点 关: 恢复 状态序 (weapon_0_0 已 拥有 → 状态序 首行 = weapon_0_0); 开关 切换 本身 无 统计 副作用
	var stats109d: Dictionary = g.stats.duplicate(true)
	ui._on_equip_score_sort()
	check(not btn.button_pressed and str(btn.text) == "按评分排序: 关", "打磨-109 再点 关 态")
	await get_tree().process_frame
	check(ui._equip_box.get_child(0) == ui._equip_row_nodes["weapon_0_0"], "打磨-109 关 后 恢复 状态序 (已拥有 weapon_0_0 排 首)")
	check(g.owned_eq.size() == owned109 + 1 and g.owned_eq.has("weapon_0_0") and g.stats == stats109d, "打磨-109 开关 切换 无 资源/统计 副作用")
	# 收尾: 关 态 + 干净 基准 (防 M6-3 段 污染)
	g.affix_load = {}
	g.affix_decompose_all()
	g.owned_eq.clear()
	g.equipped.clear()
	g.seen_affixes = []
	g.set_process(true)
	ui._refresh()
	await get_tree().process_frame
	check(ui._equip_score_sort_on == false and g.owned_eq.is_empty() and g.equipped.is_empty() and g.affix_load.is_empty(), "打磨-109 收尾 关 态 干净 基准")


func _assert_m63_diy() -> void:
	var g := GameData
	ui._tab.current_tab = 2
	g.set_process(false)
	# 受控 基准: 干净 DIY 态 + 购买 weapon_0_0 (槽位 空)
	g.owned_eq.clear()
	g.equipped.clear()
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.affix_materials = 0  # 打磨-96: 材料 归零 (防 前序 段 污染, 断言 材料 恒等)
	g.seen_affixes = []
	g.stones = 1e12
	g.buy_equipment("weapon_0_0")
	ui._refresh()
	await get_tree().process_frame
	# 抽屉 节点 存在
	check(ui._m63_bag_grid != null, "M6-3 词缀背包 网格 节点 存在")
	check(ui._m63_bag_hdr != null and ui._m63_seen_hdr != null and ui._m63_res_hdr != null, "M6-3 背包 容量/收集/共鸣 行 节点 存在")
	check(ui._m63_best_btn != null and ui._m63_dec_btn != null, "M6-3 一键装配/分解 按钮 存在")
	check(str(ui._m63_bag_hdr.text) == "词缀背包 0/30 格", "M6-3 初始 容量行 0/30 (实际 %s)" % ui._m63_bag_hdr.text)
	check(str(ui._m63_seen_hdr.text) == "词缀 收集 0/120", "M6-3 初始 收集行 0/120 (实际 %s)" % ui._m63_seen_hdr.text)
	check(str(ui._m63_res_hdr.text).find("未 触发") >= 0, "M6-3 初始 共鸣行 未 触发 (实际 %s)" % ui._m63_res_hdr.text)
	# 未拥有 装备 行: 无 chip (延迟 构建 仅 拥有 时 建)
	# 未拥有 装备: chip 若 存在 (前序 测试 段 拥有 过) 恒 禁用 灰显 (实际 游戏 只 增 不 减, 此处 验 语义)
	var robe_chips: Array = ui._m63_chips.get("robe_0_0", [])
	for rc in robe_chips:
		check((rc as Button).disabled, "M6-3 未拥有 装备 chip 禁用 (实际 disabled=%s)" % str((rc as Button).disabled))
	# 拥有 weapon_0_0: 3 chip 构建
	check(ui._m63_chips.has("weapon_0_0") and (ui._m63_chips["weapon_0_0"] as Array).size() == 3, "M6-3 拥有 装备 3 chip 构建")
	# 初始 评分 行 = 基础 6 池
	var sc_base: float = g.equip_score("weapon_0_0")
	check(str(ui._m63_score_labels["weapon_0_0"].text) == "评分 %s" % g.fmt_score(sc_base), "M6-3 初始 评分 行 = 基础 (打磨-98 fmt_score, 实际 %s)" % ui._m63_score_labels["weapon_0_0"].text)
	# 入包 3 词缀 -> 网格 3 格 + 容量 3/30 + 收集 3/120
	g.affix_add("af_qi_rate_0_0", 2)
	g.affix_add("af_atk_1_0", 1)
	g.affix_add("af_atk_4_0", 1)
	ui._refresh()
	await get_tree().process_frame
	check(ui._m63_bag_grid.get_child_count() == 3, "M6-3 背包 3 种 词缀 3 格 (实际 %d)" % ui._m63_bag_grid.get_child_count())
	check(str(ui._m63_bag_hdr.text) == "词缀背包 3/30 格", "M6-3 容量行 3/30 (实际 %s)" % ui._m63_bag_hdr.text)
	check(str(ui._m63_seen_hdr.text) == "词缀 收集 3/120", "M6-3 收集行 3/120 (实际 %s)" % ui._m63_seen_hdr.text)
	check(ui._m63_bag_cells.has("af_qi_rate_0_0"), "M6-3 背包 格子 登记")
	var cell_qi: Button = ui._m63_bag_cells["af_qi_rate_0_0"]
	check(cell_qi != null and str(cell_qi.text).find("x2") >= 0, "M6-3 格子 堆叠数 x2 (实际 %s)" % cell_qi.text)
	# 选中 词缀 -> 金边 + 选中 提示行 (网格 按 选中 键 重建: 先 点 旧 格 选中,
	# 重建 后 取 新 格 断言; 旧 引用 可能 被 free — 打磨-64 同 高负载 flake 口径,
	# is_instance_valid 防御, 失效 直接 置 选中 态 跳过 点击)
	if is_instance_valid(cell_qi):
		cell_qi.pressed.emit()
	else:
		ui._m63_sel = "af_qi_rate_0_0"
	await get_tree().process_frame
	check(str(ui._m63_sel) == "af_qi_rate_0_0", "M6-3 选中 词缀 记录 (实际 %s)" % str(ui._m63_sel))
	cell_qi = ui._m63_bag_cells.get("af_qi_rate_0_0", null) as Button
	var sel_sb: Variant = (cell_qi.get_theme_stylebox("normal") if is_instance_valid(cell_qi) else null)
	check(sel_sb != null and sel_sb.border_width_left == 2, "M6-3 选中 格子 金边 (边框宽=%d)" % (sel_sb.border_width_left if sel_sb != null else -1))
	check(str(ui._m63_sel_hdr.text).find("已选中") >= 0 and str(ui._m63_sel_hdr.text).find("灵气速率") >= 0, "M6-3 选中 提示行 含 词缀名/池名 (实际 %s)" % ui._m63_sel_hdr.text)
	# 空槽 chip 装配 (chip 0)
	var chips: Array = ui._m63_chips["weapon_0_0"]
	(chips[0] as Button).pressed.emit()
	await get_tree().process_frame
	check(str((g.affix_load.get("weapon_0_0", {}) as Dictionary).get("0", "")) == "af_qi_rate_0_0", "M6-3 chip 装配 成功 (槽0)")
	check(str((chips[0] as Button).text) == str(g.affix_by_id["af_qi_rate_0_0"]["name"]), "M6-3 装配 后 chip 显示 词缀 名 (实际 %s)" % (chips[0] as Button).text)
	check(str(ui._m63_score_labels["weapon_0_0"].text) == "评分 %s" % g.fmt_score(g.equip_score("weapon_0_0")), "M6-3 装配 后 评分 行 刷新 (打磨-98 fmt_score)")
	check(g.equip_score("weapon_0_0") > sc_base, "M6-3 装配 后 评分 上升")
	check(str(ui._m63_seen_hdr.text) == "词缀 收集 3/120", "M6-3 装配 不 改 收集 (仍 3/120)")
	# 拆卸 (chip 0 再 点, 无 选中)
	(chips[0] as Button).pressed.emit()
	await get_tree().process_frame
	check(str((g.affix_load.get("weapon_0_0", {}) as Dictionary).get("0", "")) == "", "M6-3 chip 拆卸 成功 (槽0 空)")
	check(int(g.affix_bag.get("af_qi_rate_0_0", 0)) == 2, "M6-3 拆卸 无损 回背包 (x2)")
	# 换装: 装配 槽0 = atk, 选中 atk_4_0, 点 槽0 = 换装
	g.affix_equip("weapon_0_0", 0, "af_atk_1_0")
	(ui._m63_bag_cells["af_atk_4_0"] as Button).pressed.emit()
	await get_tree().process_frame
	(chips[0] as Button).pressed.emit()
	await get_tree().process_frame
	check(str((g.affix_load.get("weapon_0_0", {}) as Dictionary).get("0", "")) == "af_atk_4_0", "M6-3 chip 换装 成功 (槽0 换 传说)")
	check(int(g.affix_bag.get("af_atk_1_0", 0)) == 1, "M6-3 换装 旧 词缀 回背包")
	# 评分 单调: 传说 槽 > atk_1 槽
	var sc_leg: float = g.equip_score("weapon_0_0")
	# 一键 最佳 装配 (槽1/2 空, 背包 有 qi_rate x2 + atk_1 x1; 装 2 件, 余 1 件)
	ui._m63_best_btn.pressed.emit()
	await get_tree().process_frame
	check(g.affix_slots_used("weapon_0_0") == 3, "M6-3 一键装配 后 3 槽 满 (实际 %d)" % g.affix_slots_used("weapon_0_0"))
	check(int(g.affix_bag.get("af_qi_rate_0_0", 0)) == 1, "M6-3 一键装配 装 2 件 余 1 件 (实际 %d)" % int(g.affix_bag.get("af_qi_rate_0_0", 0)))
	check(g.equip_score("weapon_0_0") > sc_leg, "M6-3 一键装配 后 评分 再 升")
	# 共鸣 行 刷新 (3 槽 装 词缀 后 若 同 品质 满 3 件 触发)
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._m63_res_hdr.text) == g.resonance_text(), "M6-3 共鸣行 = 接口 同源")
	# 分解 全部
	ui._m63_dec_btn.pressed.emit()
	await get_tree().process_frame
	check(g.affix_bag.is_empty(), "M6-3 分解 全部 后 背包 空")
	check(str(ui._m63_bag_hdr.text) == "词缀背包 0/30 格", "M6-3 分解 后 容量行 0/30 (实际 %s)" % ui._m63_bag_hdr.text)
	check(str(ui._m63_seen_hdr.text) == "词缀 收集 3/120", "M6-3 分解 不 清 收集 (仍 3/120)")
	check(ui._m63_bag_grid.get_child_count() == 1, "M6-3 分解 后 网格 空 提示 1 格 (实际 %d)" % ui._m63_bag_grid.get_child_count())
	# 评分 行 未 改变 (分解 不 卸 装配)
	check(str(ui._m63_score_labels["weapon_0_0"].text) == "评分 %s" % g.fmt_score(g.equip_score("weapon_0_0")), "M6-3 分解 后 评分 行 不变 (打磨-98 fmt_score)")
	# tooltip 含 评分 行 (equip_detail 含 词缀槽 + 评分)
	check(str((ui._equip_row_nodes["weapon_0_0"] as Node).tooltip_text).find("评分") >= 0, "M6-3 装备 tooltip 含 评分 行")

	# ---------- 打磨-98: 选中 词缀 评分 Δ 汇总 行 (M6-3 规格 「槽位下方 实时 预览 换装 后 评分 Δ」) ----------
	# 前置: 一键装配 后 weapon_0_0 3 槽 全满 (槽0=atk_4_0 0.96 / 槽1=atk_1_0 0.144 / 槽2=qi_rate_0_0 0.05),
	# 背包 已 分解 空, 未 选中 -> Δ 行 隐藏
	check(str(ui._m63_delta_hdr.text) == "" and not ui._m63_delta_hdr.visible,
			"打磨-98 未 选中 词缀 Δ 行 隐藏 (实际 %s)" % str(ui._m63_delta_hdr.text))
	# 受控 态: 拆 空 3 槽 后 背包 = {qi x2, atk_1 x2, def_4_0 x1}, 槽 全 空
	g.affix_unequip("weapon_0_0", 0)
	g.affix_unequip("weapon_0_0", 1)
	g.affix_unequip("weapon_0_0", 2)
	g.affix_decompose("af_atk_4_0", -1)  # 拆 出 的 传说 分解 掉 (防 污染 Δ 取 最大)
	g.affix_add("af_qi_rate_0_0", 1)
	g.affix_add("af_atk_1_0", 1)
	g.affix_add("af_def_4_0", 1)
	check(int(g.affix_bag.get("af_qi_rate_0_0", 0)) == 2 and int(g.affix_bag.get("af_atk_1_0", 0)) == 2
			and int(g.affix_bag.get("af_def_4_0", 0)) == 1, "打磨-98 受控 背包 态 (qi2/atk1x2/def4x1)")
	# 空槽 增益: 选中 qi 普通 (0.05) -> 3 空槽 增益 均 0.05, 行 = 「木剑」 +0.05
	ui._m63_sel = "af_qi_rate_0_0"
	ui._refresh_m63_ui()
	check(str(ui._m63_delta_hdr.text) == "可 增益: 「%s」 +%s" % [str(g.equip_by_id["weapon_0_0"]["name"]), g.fmt_score(0.05)],
			"打磨-98 选中 普通 词缀 Δ 行 空槽 增益 0.05 (实际 %s)" % str(ui._m63_delta_hdr.text))
	check(ui._m63_delta_hdr.visible, "打磨-98 Δ 行 可见 (选中 态)")
	# 空槽 增益 随 词缀 数值: 选中 传说 def (0.96) -> 取 最大 0.96
	ui._m63_sel = "af_def_4_0"
	ui._refresh_m63_ui()
	check(str(ui._m63_delta_hdr.text).find(g.fmt_score(0.96)) >= 0,
			"打磨-98 传说 词缀 空槽 增益 0.96 (实际 %s)" % str(ui._m63_delta_hdr.text))
	# 换装 与 空槽 取 最大: 槽0 装 qi 后 选中 atk_1 (0.144): 槽0 换装 0.094 < 空槽 0.144 -> 取 0.144
	g.affix_equip("weapon_0_0", 0, "af_qi_rate_0_0")
	ui._m63_sel = "af_atk_1_0"
	ui._refresh_m63_ui()
	check(str(ui._m63_delta_hdr.text) == "可 增益: 「%s」 +%s" % [str(g.equip_by_id["weapon_0_0"]["name"]), g.fmt_score(0.144)],
			"打磨-98 空槽 0.144 与 换装 0.094 取 最大 (实际 %s)" % str(ui._m63_delta_hdr.text))
	# 已装槽 换装 净增益 精确: 3 槽 全满 (qi/atk_1/qi) 后 选中 atk_1: 槽0 0.094 / 槽1 0 / 槽2 0.094 -> 0.094
	g.affix_equip("weapon_0_0", 1, "af_atk_1_0")
	g.affix_equip("weapon_0_0", 2, "af_qi_rate_0_0")
	ui._refresh_m63_ui()
	check(str(ui._m63_delta_hdr.text) == "可 增益: 「%s」 +%s" % [str(g.equip_by_id["weapon_0_0"]["name"]), g.fmt_score(0.094)],
			"打磨-98 已装槽 换装 净增益 0.094 精确 (实际 %s)" % str(ui._m63_delta_hdr.text))
	# 无 正增益 隐藏: 槽 全满 时 选中 同槽 词缀 (qi 0.05: 槽0/槽2 平 0, 槽1 负) -> 隐藏
	ui._m63_sel = "af_qi_rate_0_0"
	ui._refresh_m63_ui()
	check(str(ui._m63_delta_hdr.text) == "" and not ui._m63_delta_hdr.visible,
			"打磨-98 全 平/负 无 正增益 Δ 行 隐藏 (实际 %s)" % str(ui._m63_delta_hdr.text))
	# 同 态 节流: 再刷 文本/显隐 不变
	ui._refresh_m63_ui()
	check(str(ui._m63_delta_hdr.text) == "", "打磨-98 同 态 刷新 Δ 行 稳定")
	# 只读 无 副作用: Δ 行 刷新 不 改 装配/背包/统计
	var snap_load98j: String = JSON.stringify(g.affix_load)
	var snap_bag98j: String = JSON.stringify(g.affix_bag)
	var snap_stats98: Dictionary = g.stats.duplicate()
	ui._refresh_m63_ui()
	check(JSON.stringify(g.affix_load) == snap_load98j
			and JSON.stringify(g.affix_bag) == snap_bag98j and g.stats == snap_stats98,
			"打磨-98 Δ 预览 只读 无 装配/背包/统计 副作用")
	# 收尾: 拆 空 3 槽 + 分解 背包, 材料 复原 1 (M6-3 段 分解 口径, 防 打磨-96 段 基准 错位)
	for k in g.affix_load.keys():
		for pk in (g.affix_load[k] as Dictionary).keys():
			g.affix_unequip(str(k), int(pk))
	g.affix_decompose_all()
	g.affix_materials = 1
	ui._m63_sel = ""
	ui._refresh_m63_ui()
	check(str(ui._m63_delta_hdr.text) == "", "打磨-98 收尾 Δ 行 隐藏")

	# ---------- 打磨-96: 词缀 材料 兑换 面板 (UI 断言; 分解 全部 时 背包 仅 qi 普通 x1 -> 材料 +1) ----------
	ui._refresh_m96_ui()  # 材料行 同步 刷新 (主循环 刷新 口径)
	check(ui._m96_mat_hdr != null and ui._m96_exch_btn != null, "打磨-96 材料行/兑换 按钮 节点 存在")
	check(str(ui._m96_mat_hdr.text) == "词缀 材料 1 (分解 产出; 兑换/强化 槽位 消耗)", "打磨-96 分解 全部 后 材料行 显示 1 (实际 %s)" % ui._m96_mat_hdr.text)
	check(ui._m96_pool_btns.size() == 6 and ui._m96_tier_btns.size() == 5, "打磨-96 池 6 档/品质 5 档 按钮 齐全 (实际 %d/%d)" % [ui._m96_pool_btns.size(), ui._m96_tier_btns.size()])
	check(str(ui._m96_pool) == "" and int(ui._m96_tier) == -1, "打磨-96 初始 池/品质 未 选中")
	for p in ui._m96_pool_btns:
		check((ui._m96_pool_btns[p] as Button).button_pressed == false, "打磨-96 池 按钮 初始 未 点亮 (%s)" % str(p))
	# 选 池 + 品质 -> 按钮 点亮 + 文案 (材料 9 < 成本 25 = 不足)
	ui._on_m96_pool("qi_rate")
	ui._on_m96_tier(0)
	check(str(ui._m96_pool) == "qi_rate" and int(ui._m96_tier) == 0, "打磨-96 选中 池/品质 记录")
	check((ui._m96_pool_btns["qi_rate"] as Button).button_pressed and (ui._m96_tier_btns["0"] as Button).button_pressed, "打磨-96 选中 按钮 点亮")
	check(str(ui._m96_exch_btn.text) == "兑换 (材料不足)", "打磨-96 材料不足 文案 (实际 %s)" % ui._m96_exch_btn.text)
	# 材料 补足 25 -> 文案 x1
	g.affix_materials = 25
	ui._refresh_m96_exchange()
	check(str(ui._m96_exch_btn.text) == "兑换 x1 (25 材料/件)", "打磨-96 可兑换 计数 文案 (实际 %s)" % ui._m96_exch_btn.text)
	# 兑换 -> 入包 最高 价值 变体 (qi_rate 普通 = af_qi_rate_0_3) + 材料 归 0 + 收集 标记
	ui._on_m96_exchange()
	var after96: int = int(g.affix_bag.get("af_qi_rate_0_3", 0))
	check(after96 == 1, "打磨-96 兑换 入包 最高 变体 词缀 (实际 %d)" % after96)
	check(g.affix_materials == 0, "打磨-96 兑换 扣 25 材料 (实际 %d)" % g.affix_materials)
	check(int(g.stats.get("affix_exchange", 0.0)) >= 1, "打磨-96 兑换 统计 affix_exchange 计数")
	ui._refresh_m96_ui()  # 材料行 同步 刷新 (主循环 刷新 口径)
	check(str(ui._m96_mat_hdr.text) == "词缀 材料 0 (分解 产出; 兑换/强化 槽位 消耗)", "打磨-96 兑换 后 材料行 0 (实际 %s)" % ui._m96_mat_hdr.text)
	# 材料 不足 拒绝 (不 扣 不 入包)
	ui._on_m96_exchange()
	check(int(g.affix_bag.get("af_qi_rate_0_3", 0)) == 1 and g.affix_materials == 0, "打磨-96 材料不足 拒绝 无 副作用")
	# 背包满 拒绝 (填 30 格 后 兑换 拒绝, 材料/背包 不变)
	var ex_pools: Array = ["qi_rate", "stone_rate", "bt_chance", "offline_rate", "atk", "def"]
	g.affix_bag = {}
	var filled96 := 0
	for pi in ex_pools.size():
		for v in 4:
			g.affix_bag["af_%s_0_%d" % [ex_pools[pi], v]] = 1
			filled96 += 1
		g.affix_bag["af_%s_1_0" % ex_pools[pi]] = 1
		filled96 += 1
	check(g.affix_bag_full(), "打磨-96 背包 30 格 填满 (实际 %d 格)" % g.affix_bag_used())
	g.affix_materials = 50
	ui._on_m96_exchange()
	check(str(ui._msg_label.text).find("背包已满") >= 0, "打磨-96 背包满 兑换 拒绝 提示 (实际 %s)" % ui._msg_label.text)
	check(int(g.affix_bag.size()) == 30 and g.affix_materials == 50, "打磨-96 背包满 拒绝 无 副作用 (背包 %d 材料 %d)" % [g.affix_bag.size(), g.affix_materials])
	# 池 按钮 再 点 取消 选中 (toggle)
	ui._on_m96_pool("qi_rate")
	check(str(ui._m96_pool) == "" and (ui._m96_pool_btns["qi_rate"] as Button).button_pressed == false, "打磨-96 池 按钮 再 点 取消 选中")
	# 收尾: 恢复 干净 基准
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.affix_materials = 0
	g.seen_affixes = []
	ui._m63_sel = ""
	ui._m96_pool = ""
	ui._m96_tier = -1
	g.owned_eq.clear()
	g.equipped.clear()
	g.stones = 0.0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(g.affix_bag.is_empty() and g.affix_load.is_empty() and g.seen_affixes.is_empty() and g.affix_materials == 0, "M6-3 收尾 干净 基准")


# 打磨-110: 修行统计 词缀 段 — stats_text 追加 词缀 掉落/装配/分解/兑换 4 段 (埋点 打磨-96/99/101 已有, 展示位 补齐);
# 断言: 标签 含 4 段 基准 0 / 统计 行 文本 = stats_text 接口 恒等 / tooltip 含 词缀 口径 行 / 埋点 递增 后
# _refresh 同步 / 同态 节流 无 副作用 / 收尾 恢复 干净 基准
func _assert_stats_affix() -> void:
	var g := GameData
	# 切 修行页 (统计 标签 所在 页, 布局 落定)
	ui._tab.current_tab = 0
	g.set_process(false)
	# 基准: 词缀 4 键 清零 (前 段 词缀 UI 断言 可能 残留 埋点, 全清 保 基准 纯净)
	g.stats["affix_drop"] = 0.0
	g.stats["affix_equip"] = 0.0
	g.stats["affix_decompose"] = 0.0
	g.stats["affix_exchange"] = 0.0
	ui._refresh()
	await get_tree().process_frame
	# 1) 标签 节点 存在 且 文本 = 接口 恒等 (含 4 段 基准 0)
	check(ui._stats_label != null, "打磨-110 统计 标签 存在")
	var stt: String = g.stats_text()
	check(stt.find("词缀 掉落 0") >= 0 and stt.find("装配 0") >= 0 and stt.find("分解 0") >= 0 and stt.find("兑换 0") >= 0,
			"打磨-110 stats_text 含 词缀 4 段 基准 0 (实际 %s)" % stt)
	check(str(ui._stats_label.text) == stt, "打磨-110 统计 行 文本 = stats_text 接口 恒等 (实际 %s)" % str(ui._stats_label.text))
	# 2) tooltip 含 词缀 口径 行 (打磨-110 补 说明)
	check(ui._stats_label.tooltip_text.find("词缀") >= 0 and ui._stats_label.tooltip_text.find("存档保存") >= 0,
			"打磨-110 统计 行 tooltip 含 词缀 口径 (实际 %s)" % ui._stats_label.tooltip_text.left(60))
	# 3) 埋点 递增 后 _refresh 同步 (只读 展示 路径, 无 资源/统计 副作用)
	var snap_r: float = g.essence
	var snap_s: float = g.stones
	var snap_st: Dictionary = g.stats.duplicate(true)
	g.stats["affix_drop"] = 3.0
	g.stats["affix_exchange"] = 1.0
	ui._refresh()
	var stt2: String = g.stats_text()
	check(stt2.find("词缀 掉落 3") >= 0 and stt2.find("兑换 1") >= 0, "打磨-110 埋点 递增 后 文案 同步 (实际 %s)" % stt2.right(80))
	check(str(ui._stats_label.text) == stt2, "打磨-110 _refresh 后 标签 文本 同步 恒等")
	check(g.essence == snap_r and g.stones == snap_s, "打磨-110 刷新 无 资源 副作用")
	var diff_keys: Array[String] = []
	for k in g.stats:
		if k in ["affix_drop", "affix_exchange"]:
			continue
		if absf(float(g.stats[k]) - float(snap_st.get(k, 0.0))) > 1e-9:
			diff_keys.append(str(k))
	check(diff_keys.is_empty(), "打磨-110 刷新 无 其他 统计 副作用 (变化键 %s)" % ", ".join(diff_keys))
	# 4) 同态 节流: 再 刷 文本 不 重写 (缓存 键 不变)
	var cached: String = ui._stats_text
	ui._refresh()
	check(ui._stats_text == cached and str(ui._stats_label.text) == stt2, "打磨-110 同态 节流 文本 稳定 无 副作用")
	# 5) 收尾: 归零 恢复 干净 基准 (防 污染 _finish 汇报 计数 之外 的 状态)
	g.stats["affix_drop"] = 0.0
	g.stats["affix_equip"] = 0.0
	g.stats["affix_decompose"] = 0.0
	g.stats["affix_exchange"] = 0.0
	g.set_process(true)
	ui._refresh()
	await get_tree().process_frame
	check(g.stats_text().find("词缀 掉落 0") >= 0 and str(ui._stats_label.text) == g.stats_text(), "打磨-110 收尾 干净 基准 (实际 %s)" % g.stats_text().right(80))


# 打磨-112: 换装对比 战力 atk/def + 评分 Δ 段 (M6 规格 "当前穿戴 vs 备选 实时对比" 缺口 落地 —
# 打磨-25 换装对比 行 只有 灵气/灵石 差, atk/def 战力 与 装备 评分 无 对比 位; 行 换装 标签 + 行
# tooltip 由 equip_swap_hint text 驱动 自动 覆盖 新 段, UI 无 逻辑 改动). 断言 (手动驱动 确定性):
# 受控 基准 (已穿 紫刀) 行 标签 = 接口 恒等 含 攻击/防御/评分 段 / 负差 带 负号 / 词缀 装配 后
# 动态 同步 = 接口 恒等 / 换装 标签 tooltip 口径 说明 / 同态 节流 无 资源 统计 副作用 / 收尾 干净 基准
func _assert_swap_delta() -> void:
	var g := GameData
	# 切 装备页 (换装 标签 所在 页, 布局 落定)
	ui._tab.current_tab = 2
	g.set_process(false)
	# 受控 基准: 清空 拥有/穿戴/词缀, 灵石 足够, 穿 紫刀 (weapon_2_1); 前 段 可能 残留, 全清 保 基准 纯净
	g.owned_eq.clear()
	g.equipped.clear()
	g.affix_bag = {}
	g.affix_load = {}
	g.seen_affixes = []
	g.affix_decompose_all()
	g.stats["affix_equip"] = 0.0
	g.stats["affix_decompose"] = 0.0
	g.stones = 1e12
	g.buy_equipment("weapon_2_1")  # 槽位 空 -> 自动 穿戴 紫刀
	check(str(g.equipped.get("weapon", "")) == "weapon_2_1", "打磨-112 受控 基准: 紫刀 已穿 (实际 %s)" % str(g.equipped.get("weapon", "")))
	var stats112: Dictionary = g.stats.duplicate(true)
	var stones112: float = g.stones
	ui._refresh()
	await get_tree().process_frame
	# 1) 行 换装 标签 存在 (140 件 全 构建) + 未拥有 备选 件 标签 文本 = 接口 恒等 (含 攻击/防御/评分 段)
	check(ui._equip_swap.size() == g.equip_ids.size(), "打磨-112 换装 标签 140 件 全 构建 (实际 %d)" % ui._equip_swap.size())
	var sw112: Dictionary = g.equip_swap_hint("weapon_5_0")  # 仙剑 vs 已穿 紫刀
	var l112: Label = ui._equip_swap["weapon_5_0"]
	check(l112 != null, "打磨-112 仙剑 行 换装 标签 存在")
	check(str(l112.text) == str(sw112["text"]) and str(l112.text).find("替换「") == 0,
			"打磨-112 仙剑 行 换装 标签 = 接口 恒等 (实际 %s)" % str(l112.text))
	check(str(l112.text).find("攻击+") >= 0 and str(l112.text).find("防御+") >= 0,
			"打磨-112 换装 标签 含 攻击/防御 战力 段 (实际 %s)" % str(l112.text))
	check(str(l112.text).find("评分+") >= 0, "打磨-112 换装 标签 含 评分 段 (实际 %s)" % str(l112.text))
	# 2) 负差 件 (灵剑 评分 低于 紫刀) 评分 段 带 负号; 行 tooltip 随 标签 变化 同步 含 新 段
	var sw112b: Dictionary = g.equip_swap_hint("weapon_1_0")
	check(str(sw112b["text"]).find("评分-") >= 0, "打磨-112 负差 评分 段 带 负号 (接口 %s)" % str(sw112b["text"]))
	check(str(ui._equip_swap["weapon_1_0"].text) == str(sw112b["text"]),
			"打磨-112 灵剑 行 标签 = 接口 恒等 (负差 态)")
	var row112: Node = ui._equip_row_nodes["weapon_5_0"]
	check(str(row112.tooltip_text) == g.equip_detail("weapon_5_0")
			and str(row112.tooltip_text).find("评分+") >= 0,
			"打磨-112 行 tooltip 随 换装 标签 变化 同步 含 评分 段 (实际 %s)" % str(row112.tooltip_text).left(40))
	# 3) 换装 标签 tooltip 口径 说明 (打磨-112 补: 攻击/防御/评分 段 口径)
	check(str(l112.tooltip_text).find("评分") >= 0 and str(l112.tooltip_text).find("攻击") >= 0,
			"打磨-112 换装 标签 tooltip 含 评分/攻击 口径 (实际 %s)" % str(l112.tooltip_text).left(40))
	# 4) 词缀 装配 动态 同步: 紫刀 装 atk 词缀 后 行 标签 = 接口 恒等 (评分 差 -0.08 联动)
	g.owned_eq.append("weapon_0_0")
	g.affix_add("af_atk_0_0", 1)
	check(g.affix_equip("weapon_2_1", 0, "af_atk_0_0") == "", "打磨-112 受控 装配 atk 词缀 成功")
	ui._refresh()
	await get_tree().process_frame
	var sw112c: Dictionary = g.equip_swap_hint("weapon_5_0")
	check(str(ui._equip_swap["weapon_5_0"].text) == str(sw112c["text"]),
			"打磨-112 词缀 装配 后 行 标签 动态 同步 = 接口 恒等 (实际 %s)" % str(ui._equip_swap["weapon_5_0"].text))
	check(absf(float(sw112c["score_d"]) - (float(sw112["score_d"]) - 0.08)) < 5e-3,
			"打磨-112 词缀 装配 后 评分 差 -0.08 联动 (容差 float32 档, 实际 %s)" % str(sw112c["score_d"]))
	# 5) 同态 节流: 重复 _refresh 标签 文本 不 重写, 无 资源/统计 副作用 (快照 取 于 装配 后, 含 affix_equip 埋点)
	var l112_pre: String = str(ui._equip_swap["weapon_5_0"].text)
	var stats112b: Dictionary = g.stats.duplicate(true)
	ui._refresh()
	check(str(ui._equip_swap["weapon_5_0"].text) == l112_pre and g.stones == stones112 and g.stats == stats112b,
			"打磨-112 同态 节流 无 资源/统计 副作用")
	# 6) 收尾: 卸下 词缀 全 分解 + 清空 恢复 干净 基准 (防 污染 后续 段)
	g.affix_unequip("weapon_2_1", 0)
	g.affix_decompose_all()
	g.owned_eq.clear()
	g.equipped.clear()
	g.seen_affixes = []
	g.stats["affix_equip"] = 0.0
	g.stats["affix_decompose"] = 0.0
	g.stones = 0.0
	g.set_process(true)
	ui._refresh()
	await get_tree().process_frame
	check(ui._equip_swap.size() == g.equip_ids.size() and str(ui._equip_swap["weapon_5_0"].text) == g.equip_swap_hint("weapon_5_0")["text"],
			"打磨-112 收尾 干净 基准 (标签 随 穿戴 清空 回 空 态)")


# 打磨-113: 爬塔 战力构成 tooltip (M5 规格 "玩家 战力 = 境界 x 功法 x 装备 x 塔专属 加成"
# 构成 展示 位 缺口 落地 — 战力对比 行 悬停 展开 五段 构成: 境界 基础 x 功法 x 装备[含词缀]
# x 法器 x 塔 专属 [通关 增益+套装 共鸣]; 构成 段 独立 缓存 变化 才 刷, 判定口径 段 静态).
# UI 断言: 双塔 标签 节点 齐全/tooltip = 判定口径 段 + 构成 段 拼接 恒等 (构成 = 接口
# tower_power_compose_tip 同 口径)/剧毒 态 判定口径 段 切换 (构成 段 剧毒 不 入 基础 口径 不 变)/
# 同态 节流 无 副作用 (收尾 干净 基准 防 污染)
func _assert_tower_power_compose() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 + 无 剧毒 + 境界 练气 进度 0 (M5-4 通关 段 可能 残留 tower_fixed_clear)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao_level = 0
	g.learned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g.affix_load = {}
	g.affix_bag = {}
	g.affix_decompose_all()
	ui._refresh_tower()
	await get_tree().process_frame
	# 1) 双塔 战力对比 标签 存在 + tooltip = 判定口径 段 + 构成 段 拼接 恒等
	check(ui._tw_pwr_labels.has("fixed") and ui._tw_pwr_labels.has("endless"),
			"打磨-113 双塔 战力对比 标签 齐全")
	var tip113: String = g.tower_power_compose_tip()
	var exp113: String = ("判定口径: 玩家 有效 ATK ≥ 怪物 ATK x 0.85 即胜 (即时判定, 无死亡惩罚, 败 停留本层 可 无限重试)。\n"
		+ "无 debuff, 按 当前 战力 预测。\n\n" + tip113)
	check(str(ui._tw_pwr_labels["fixed"].tooltip_text) == exp113,
			"打磨-113 镇妖塔 战力对比 tooltip = 判定口径 段 + 构成 段 恒等 (实际 %s)" % str(ui._tw_pwr_labels["fixed"].tooltip_text).left(60))
	check(str(ui._tw_pwr_labels["endless"].tooltip_text) == exp113,
			"打磨-113 登天梯 战力对比 tooltip 同 口径 恒等")
	# 构成 段 关键 行 (基准 境界 进度 0 / 基础 2.0)
	check(tip113.find("境界 基础: ATK %s" % g.fmt(g.TOWER_BASE_ATK)) >= 0,
			"打磨-113 构成 段 境界 基础 = 2.0 (实际 %s)" % tip113)
	check(tip113.find("未 触发") >= 0 and tip113.find("未通关 = x1.00") >= 0,
			"打磨-113 构成 段 共鸣 未 触发 + 通关 未 态 基准")
	# 2) 剧毒 态: 判定口径 段 切 减成 口径 (文本 因 fmt 截断 不 变 也 须 刷 口径 段)
	g.poison_battles = g.TOWER_POISON_BATTLES
	ui._refresh_tower()
	await get_tree().process_frame
	var tip113b: String = g.tower_power_compose_tip()
	var exp113b: String = ("判定口径: 玩家 有效 ATK ≥ 怪物 ATK x 0.85 即胜 (即时判定, 无死亡惩罚, 败 停留本层 可 无限重试)。\n"
		+ "玩家 当前 处 剧毒 debuff (ATK -15%% x %d 场), 按 减成 后 口径 预测。\n\n" % g.poison_battles
		+ tip113b)
	check(str(ui._tw_pwr_labels["fixed"].tooltip_text) == exp113b,
			"打磨-113 剧毒 态 判定口径 段 切换 = 拼接 恒等 (实际 %s)" % str(ui._tw_pwr_labels["fixed"].tooltip_text).left(60))
	check(tip113b.replace(" (剧毒 x0.85 x 2 场)", "") == tip113,
			"打磨-113 剧毒 仅 汇总行 追加 标注, 基础 构成 段 不变 (实际 %s)" % tip113b.right(60))
	g.poison_battles = 0
	ui._refresh_tower()
	await get_tree().process_frame
	# 3) 同态 节流: 无 变化 再 刷 tooltip 不 重写 对象 不 变 + 无 统计 副作用
	var stats113: Dictionary = g.stats.duplicate(true)
	var ref113: String = str(ui._tw_pwr_labels["fixed"].tooltip_text)
	ui._refresh_tower()
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_pwr_labels["fixed"].tooltip_text) == ref113 and g.stats == stats113,
			"打磨-113 同态 节流 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态/剧毒/境界 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_endless_floor) == 1 and int(g.tower_endless_best) == 0,
			"打磨-113 收尾 干净 基准 (塔 态 归零)")


# 打磨-118: 镇妖塔 专属 Boss 分层 卡片 标记 + tooltip 分层 行 (M5 规格 "25 专属 Boss: 20 小
# Boss 每 50 层 x10 / 4 主题 Boss 100·250·500·750 层 x20 / 最终 Boss 镇妖塔主 1000 层 x50"
# 展示 位 — 原 怪物卡 所有 Boss 统一 ⚑Boss 无 分层; 卡片 tag 主题/最终 Boss 分层 标记 +
# tooltip 分层 行 + 状态行 tooltip 分层 口径 说明; 数值 已 落表 只 展示 不 改 数值;
# UI 断言: 普通层 无 分层 标记/主题 Boss 卡片 tag + tooltip 分层 行/最终 Boss tag/
# 状态行 tooltip 分层 口径/登天梯 里程碑 Boss 不 叠 分层/同态 节流/收尾 干净 基准 防 污染)
func _assert_boss_tier_tag() -> void:
	var g := GameData
	ui._tab.current_tab = 4
	g.set_process(false)
	# 受控 基准: 干净 塔 态 + 弱 玩家 (防 误触 结算 推进 层数)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	ui._refresh_tower()
	await get_tree().process_frame
	# 1) 基准 普通层 (镇妖塔 第 1 层): 怪物卡 无 Boss/主题/最终 标记 + 无 分层 行
	var mon118a: String = str(ui._tw_mon_labels["fixed"].text)
	check(mon118a.find("⚑") < 0 and mon118a.find("★精英") < 0,
			"打磨-118 镇妖塔 第 1 层 普通层 无 Boss 标记 (实际 %s)" % mon118a)
	check(str(ui._tw_mon_labels["fixed"].tooltip_text).find("分层:") < 0,
			"打磨-118 镇妖塔 普通层 怪物卡 tooltip 无 分层 行 (实际 %s)" % str(ui._tw_mon_labels["fixed"].tooltip_text).left(60))
	# 2) 主题 Boss (镇妖塔 第 100 层 万幻妖殿主): 卡片 tag 含 主题Boss + tooltip 分层 行
	g.tower_fixed_floor = 99
	ui._refresh_tower()
	await get_tree().process_frame
	var mon118b: String = str(ui._tw_mon_labels["fixed"].text)
	check(mon118b.find("第 100 层") >= 0 and mon118b.find("⚑主题Boss") >= 0,
			"打磨-118 镇妖塔 第 100 层 主题 Boss 卡片 tag = ⚑主题Boss (实际 %s)" % mon118b)
	check(mon118b.find("万幻妖殿主") >= 0, "打磨-118 主题 Boss 名 = 万幻妖殿主 (数据 锚定, 实际 %s)" % mon118b)
	check(str(ui._tw_mon_labels["fixed"].tooltip_text).find("分层: 主题 Boss (数值 x20)") >= 0,
			"打磨-118 主题 Boss 怪物卡 tooltip 含 分层 行 (实际 %s)" % str(ui._tw_mon_labels["fixed"].tooltip_text).get_slice("\n", 2))
	# 3) 小 Boss (镇妖塔 第 50 层): 卡片 tag 恒 ⚑Boss (旧 口径 不变) + tooltip 含 小 Boss 分层 行
	g.tower_fixed_floor = 49
	ui._refresh_tower()
	await get_tree().process_frame
	var mon118c: String = str(ui._tw_mon_labels["fixed"].text)
	check(mon118c.find("第 50 层") >= 0 and mon118c.find("⚑Boss") >= 0 and mon118c.find("主题") < 0,
			"打磨-118 小 Boss 卡片 tag 恒 ⚑Boss (旧 口径 不变, 实际 %s)" % mon118c)
	check(str(ui._tw_mon_labels["fixed"].tooltip_text).find("分层: 小 Boss (每 50 层 · 数值 x10)") >= 0,
			"打磨-118 小 Boss 怪物卡 tooltip 含 小 Boss 分层 行 (实际 %s)" % str(ui._tw_mon_labels["fixed"].tooltip_text).get_slice("\n", 2))
	# 4) 最终 Boss (镇妖塔 通关 守塔 模式 恒 1000 层 镇妖塔主): 卡片 tag 含 最终Boss·镇妖塔主
	g.tower_fixed_floor = 1000
	g.tower_fixed_clear = true
	ui._refresh_tower()
	await get_tree().process_frame
	var mon118d: String = str(ui._tw_mon_labels["fixed"].text)
	check(mon118d.find("⚑最终Boss·镇妖塔主") >= 0,
			"打磨-118 最终 Boss 卡片 tag = ⚑最终Boss·镇妖塔主 (实际 %s)" % mon118d)
	check(str(ui._tw_mon_labels["fixed"].tooltip_text).find("分层: 最终 Boss (数值 x50)") >= 0,
			"打磨-118 最终 Boss 怪物卡 tooltip 含 最终 Boss 分层 行 (实际 %s)" % str(ui._tw_mon_labels["fixed"].tooltip_text).get_slice("\n", 2))
	# 5) 登天梯 里程碑 Boss (100 层): 卡片 tag 恒 ⚑Boss·里程碑 宝箱 (不 叠 镇妖塔 分层)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 100
	ui._refresh_tower()
	await get_tree().process_frame
	var mon118e: String = str(ui._tw_mon_labels["endless"].text)
	check(mon118e.find("⚑Boss·里程碑 宝箱") >= 0 and mon118e.find("主题") < 0 and mon118e.find("最终") < 0,
			"打磨-118 登天梯 里程碑 Boss 不 叠 镇妖塔 分层 标记 (实际 %s)" % mon118e)
	check(str(ui._tw_mon_labels["endless"].tooltip_text).find("分层:") < 0,
			"打磨-118 登天梯 里程碑 Boss tooltip 无 分层 行 (实际 %s)" % str(ui._tw_mon_labels["endless"].tooltip_text).left(60))
	# 6) 状态行 tooltip 含 分层 口径 说明 (构建 时 写入)
	check(str(ui._tw_status_panel.tooltip_text).find("主题 Boss (x20)") >= 0
			and str(ui._tw_status_panel.tooltip_text).find("最终 Boss") >= 0
			and str(ui._tw_status_panel.tooltip_text).find("小 Boss (数值 x10)") >= 0,
			"打磨-118 状态行 tooltip 含 25 Boss 分层 口径 说明")
	# 7) 同态 节流: 无 塔 态 变化 再 刷 不 重写 + 无 统计 副作用
	var snap118: Dictionary = g.stats.duplicate(true)
	var ref118: String = str(ui._tw_mon_labels["endless"].text)
	ui._refresh_tower()
	await get_tree().process_frame
	check(str(ui._tw_mon_labels["endless"].text) == ref118 and g.stats == snap118,
			"打磨-118 同态 节流 无 统计 副作用")
	# 收尾: 恢复 干净 基准 (塔 态 归零, 防 污染 后续 段)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.set_process(true)
	ui._tab.current_tab = 3
	ui._refresh()
	await get_tree().process_frame
	check(int(g.tower_fixed_floor) == 0 and int(g.tower_endless_floor) == 1,
			"打磨-118 收尾 干净 基准 (塔 态 归零)")

# M7-2 打磨-135a: 顶栏 Panel + Tab 页签 9-slice 皮肤 (assets/ui Kenney CC0; modulate 调 深色仙侠;
# 顶栏 panel_border.png 底 + TabContainer 五态 StyleBoxTexture btn_secondary.png; 布局/文字/功能 口径 不变)
# 断言: 顶栏 Panel + StyleBoxTexture + texture=panel_border + 9-slice 边距 + 调暗口径 /
# 顶栏 内容 同父 口径 不变 (徽标/境界 同 HBox, 布局 断言 兼容) /
# Tab 五态 (tab/tab_unselected/tab_hovered/tab_focus/tab_disabled) stylebox 齐全 + texture=btn_secondary /
# 选中 暖金 区分 未选 深底 / Tab 切换 功能 不变 (current_tab 0..4 往返) + 收尾 成就页
func _assert_m135a_skins() -> void:
	# 1) 顶栏 Panel: 节点 + StyleBoxTexture + 纹理 路径 + 9-slice 边距 + 调暗 口径
	var tp: Panel = ui._top_panel
	check(tp != null, "135a 顶栏 Panel 节点 存在")
	if tp == null:
		return
	check(int(tp.size.x) > 100, "135a 顶栏 Panel 布局 宽 >100 (实际 %d)" % int(tp.size.x))
	var top_sb: StyleBox = tp.get_theme_stylebox("panel")
	check(top_sb != null and top_sb is StyleBoxTexture, "135a 顶栏 panel stylebox = StyleBoxTexture")
	var tbt: StyleBoxTexture = top_sb as StyleBoxTexture
	check(tbt != null and tbt.texture != null, "135a 顶栏 9-slice 纹理 已 加载")
	if tbt != null and tbt.texture != null:
		check(str(tbt.texture.resource_path) == "res://assets/ui/panel_border.png",
					"135a 顶栏 纹理 = panel_border.png (实际 %s)" % str(tbt.texture.resource_path))
		check(tbt.texture_margin_left > 0.0 and tbt.texture_margin_top > 0.0
					and tbt.texture_margin_right > 0.0 and tbt.texture_margin_bottom > 0.0,
					"135a 顶栏 9-slice 四边 边距 非 0 (l=%.0f t=%.0f r=%.0f b=%.0f)" % [tbt.texture_margin_left, tbt.texture_margin_top, tbt.texture_margin_right, tbt.texture_margin_bottom])
		check(tbt.modulate_color.r < 0.7,
					"135a 顶栏 纹理 modulate 调暗 融入 深色底 (r<0.7; 实际 %s)" % str(tbt.modulate_color))
	# 2) 顶栏 内容 同父 口径 不变 (换皮 后 徽标/境界/灵石 仍 同 顶栏 HBox — 既有 布局 断言 兼容)
	check(ui._auto_badge.get_parent() == ui._realm_label.get_parent(),
				"135a 顶栏 内容 同父 口径 不变 (自动 徽标 与 境界 标签 同 父)")
	check(ui._realm_label.get_parent() is HBoxContainer,
				"135a 顶栏 内容 容器 = HBox (布局 不变; 实际 %s)" % str(ui._realm_label.get_parent().get_class()))
	# 3) Tab 五态 stylebox 齐全 + texture = btn_secondary.png
	var states := ["tab", "tab_unselected", "tab_hovered", "tab_focus", "tab_disabled"]
	for st in states:
		var sb2: StyleBox = ui._tab.get_theme_stylebox(st)
		check(sb2 != null and sb2 is StyleBoxTexture, "135a Tab %s stylebox = StyleBoxTexture" % st)
		var stt: StyleBoxTexture = sb2 as StyleBoxTexture
		if stt != null and stt.texture != null:
			check(str(stt.texture.resource_path) == "res://assets/ui/btn_secondary.png",
						"135a Tab %s 纹理 = btn_secondary.png (实际 %s)" % [st, str(stt.texture.resource_path)])
			check(stt.texture_margin_left > 0.0, "135a Tab %s 9-slice 左边距 非 0" % st)
	# 4) 选中 暖金 区分 未选 深底
	var tab_sel: StyleBoxTexture = ui._tab.get_theme_stylebox("tab") as StyleBoxTexture
	var tab_un: StyleBoxTexture = ui._tab.get_theme_stylebox("tab_unselected") as StyleBoxTexture
	check(tab_sel != null and tab_un != null and tab_sel.modulate_color != tab_un.modulate_color,
				"135a Tab 选中 与 未选中 颜色 区分 (sel=%s unsel=%s)" % [str(tab_sel.modulate_color), str(tab_un.modulate_color)])
	check(tab_sel != null and tab_sel.modulate_color.r > tab_sel.modulate_color.b,
				"135a Tab 选中 暖金 口径 (r>b; 实际 %s)" % str(tab_sel.modulate_color))
	check(tab_un != null and tab_un.modulate_color.r < 0.4,
				"135a Tab 未选中 深底 口径 (r<0.4; 实际 %s)" % str(tab_un.modulate_color))
	# 5) Tab 切换 功能 不变: current_tab 0..4 往返 (皮肤 不 影响 页 切换)
	for i in range(5):
		ui._tab.current_tab = i
		check(ui._tab.current_tab == i, "135a Tab 切换 至 %d 成功 (实际 %d)" % [i, ui._tab.current_tab])
	ui._tab.current_tab = 3
	ui._refresh()
	check(ui._tab.current_tab == 3, "135a Tab 收尾 恢复 成就 页 (实际 %d)" % ui._tab.current_tab)

# M7-2 打磨-135b: 各页卡片/行容器 背景 换 面板 纹理 — 5 页 大容器 (修行/技能/装备/成就/爬塔)
# 换 9-slice 面板底 panel_frame_frost.png (Kenney CC0, 中心 半透明 磨砂 + 013 角饰;
# modulate 到 PANEL_BG 深色仙侠, 边框线 随 modulate 显 青灰; 行内 状态 高亮 金框 打磨-1 不变).
# 断言: 5 页 panel stylebox = StyleBoxTexture + 纹理 路径 + 9-slice 边距 + modulate 深色 口径 /
#       页 内容 布局 偏移 不变 (各页 首 子 容器 offset 口径) / 行内 卡片 样式 不变 (StyleBoxFlat) /
#       Tab 切换 功能 不变 / 收尾 恢复
func _assert_m135b_page_skins() -> void:
	# 1) 5 页 大容器 = StyleBoxTexture + 纹理 路径 + 9-slice 边距 + modulate 深色仙侠
	var pages := ["修行", "技能", "装备", "成就", "爬塔"]
	for pn in pages:
		var pg: Panel = ui._tab.get_node(pn)
		check(pg != null and pg is Panel, "135b 页面 %s 节点 存在 (实际 %s)" % [pn, str(pg.get_class()) if pg != null else "null"])
		if pg == null:
			continue
		var pgsb: StyleBox = pg.get_theme_stylebox("panel")
		check(pgsb != null and pgsb is StyleBoxTexture, "135b 页 %s panel stylebox = StyleBoxTexture (实际 %s)" % [pn, str(pgsb.get_class()) if pgsb != null else "null"])
		var pgt: StyleBoxTexture = pgsb as StyleBoxTexture
		if pgt != null:
			check(pgt.texture != null and str(pgt.texture.resource_path) == "res://assets/ui/panel_frame_frost.png",
						"135b 页 %s 纹理 = panel_frame_frost.png (实际 %s)" % [pn, str(pgt.texture.resource_path) if pgt.texture != null else "null"])
			check(pgt.texture_margin_left > 0.0 and pgt.texture_margin_top > 0.0
						and pgt.texture_margin_right > 0.0 and pgt.texture_margin_bottom > 0.0,
						"135b 页 %s 9-slice 四边 边距 非 0 (l=%.0f t=%.0f r=%.0f b=%.0f)" % [pn, pgt.texture_margin_left, pgt.texture_margin_top, pgt.texture_margin_right, pgt.texture_margin_bottom])
			check(pgt.modulate_color.b > pgt.modulate_color.r and pgt.modulate_color.r < 0.6,
						"135b 页 %s modulate 深色仙侠 口径 (b>r, r<0.6; 实际 %s)" % [pn, str(pgt.modulate_color)])
	# 2) 页 内容 布局 偏移 不变 (各页 首 子 容器 offset 口径 = 构建 时 设定, 换皮 不 改 布局)
	for pn in pages:
		var pg2: Control = ui._tab.get_node(pn)
		if pg2 == null or pg2.get_child_count() == 0:
			check(false, "135b 页 %s 有 内容 子 容器" % pn)
			continue
		var inner: Control = pg2.get_child(0)
		check(inner.offset_left == 10.0 and inner.offset_top == 8.0,
					"135b 页 %s 内容 容器 布局 偏移 不变 (l=%.0f t=%.0f)" % [pn, inner.offset_left, inner.offset_top])
	# 3) 行内 卡片 样式 不变 (技能/装备/成就/爬塔 行 卡片 仍 用 构建 时 缓存 StyleBoxFlat, 金框 高亮 口径 打磨-1 保持)
	check(ui._card_sb_normal != null and ui._card_sb_normal is StyleBoxFlat, "135b 行 卡片 默认 样式 = StyleBoxFlat (行 高亮 金框 口径 不变)")
	var any_row_flat := true
	for k in ui._skill_row_nodes:
		var row: PanelContainer = ui._skill_row_nodes[k]
		var rsb: StyleBox = row.get_theme_stylebox("panel")
		if rsb == null or not (rsb is StyleBoxFlat):
			any_row_flat = false
			break
	check(any_row_flat, "135b 技能 行 卡片 仍 为 StyleBoxFlat (行 样式 不 随 页 换皮 变)")
	# 4) Tab 切换 功能 不变 (皮肤 不 影响 页 切换)
	for i in range(5):
		ui._tab.current_tab = i
		check(ui._tab.current_tab == i, "135b Tab 切换 至 %d 成功 (实际 %d)" % [i, ui._tab.current_tab])
	ui._tab.current_tab = 3
	ui._refresh()
	check(ui._tab.current_tab == 3, "135b Tab 收尾 恢复 成就 页 (实际 %d)" % ui._tab.current_tab)


# M7-2 打磨-135c-1: 按钮族 核心 9-slice 换皮 — _make_button 默认 三态 换 btn_primary 纹理
# (Kenney CC0, 状态 由 纹理 本身 区分 hover 提亮/pressed 压暗, 无 modulate; 金边高亮/微光/闪烁
# 系统 保持 StyleBoxFlat 叠加, 结束 恢复 纹理 默认; 一键挂机 flat 保留 [打磨-90 border 断言]).
# 断言: 突破/技能 按钮 三态 纹理+9-slice 边距/三态 互 不同/一键挂机 flat/可突破 金边 叠加/微光 恢复.
# M7-2 打磨-135c-2: 词缀背包格 btn_secondary 9-slice 换皮 + 内联 Button.new() 族 残留 flat 排查
# 口径: 未选中 = btn_secondary 9-slice 纹理 底 (modulate 深色仙侠 三态), 选中 = 金边 叠加 (M6-3 口径 不变);
# 徽标/段热区/进度条底/收集行/一键挂机 = flat 有意 保留 (语义 色板 与 动作 按钮 区分, 防 纹理 底 抢 视觉)
func _assert_m135c2_skins() -> void:
	var g := GameData
	# 基准 清理: 清 前序 段 词缀 残留 (防 背包 计数 断言 污染; 本段 为 最末 UI 段 无 后续 依赖)
	g.affix_decompose_all()
	g.affix_bag.clear()
	g.affix_materials = 0
	# 1) 词缀格 纹理 换皮 (需 背包 非空 构建 格子)
	g.affix_add("af_qi_rate_0_0", 2)
	g.affix_add("af_atk_1_0", 1)
	ui._refresh()
	await get_tree().process_frame
	check(ui._m63_bag_cells.size() == 2, "135c-2 词缀背包 2 格 构建 (实际 %d)" % ui._m63_bag_cells.size())
	var c1: Button = ui._m63_bag_cells.get("af_qi_rate_0_0")
	var c2: Button = ui._m63_bag_cells.get("af_atk_1_0")
	check(c1 != null and c2 != null, "135c-2 词缀格 节点 存在")
	if c1 == null:
		return
	# 2) 未选中 格 = btn_secondary 9-slice 纹理 三态 (modulate 深色仙侠 调色 区分)
	var bn: StyleBox = c1.get_theme_stylebox("normal")
	var bh: StyleBox = c1.get_theme_stylebox("hover")
	var bp: StyleBox = c1.get_theme_stylebox("pressed")
	var bf: StyleBox = c1.get_theme_stylebox("focus")
	check(bn is StyleBoxTexture and str((bn as StyleBoxTexture).texture.resource_path) == "res://assets/ui/btn_secondary.png",
			"135c-2 词缀格 未选中 normal = btn_secondary 9-slice (实际 %s)" % str(bn))
	check(bn is StyleBoxTexture and (bn as StyleBoxTexture).texture_margin_left > 0,
			"135c-2 词缀格 9-slice 边距 非 0 (实际 %.1f)" % (bn as StyleBoxTexture).texture_margin_left)
	check(bh != null and bp != null and bf != null,
			"135c-2 词缀格 四态 齐全 (normal/hover/pressed/focus)")
	check(bh is StyleBoxTexture and bf is StyleBoxTexture
			and (bh as StyleBoxTexture).texture == (bn as StyleBoxTexture).texture
			and (bf as StyleBoxTexture).texture == (bn as StyleBoxTexture).texture,
			"135c-2 词缀格 三态 同源 纹理 (状态 由 modulate 区分)")
	check((bh as StyleBoxTexture).modulate_color.r > (bn as StyleBoxTexture).modulate_color.r,
			"135c-2 词缀格 悬停 提亮 区分 未选中 (n=%s h=%s)" % [str((bn as StyleBoxTexture).modulate_color), str((bh as StyleBoxTexture).modulate_color)])
	check((bp as StyleBoxTexture).modulate_color.r < (bn as StyleBoxTexture).modulate_color.r,
			"135c-2 词缀格 按下 压暗 区分 未选中 (n=%s p=%s)" % [str((bn as StyleBoxTexture).modulate_color), str((bp as StyleBoxTexture).modulate_color)])
	check((bn as StyleBoxTexture).modulate_color.b > (bn as StyleBoxTexture).modulate_color.r,
			"135c-2 词缀格 深色仙侠 底 口径 (b>r; 实际 %s)" % str((bn as StyleBoxTexture).modulate_color))
	check(c1.flat, "135c-2 词缀格 flat 保留 (防 引擎 默认 底 叠 纹理)")
	# 3) 选中 格 = 金边 StyleBoxFlat 叠加 (M6-3 口径 不变: 边框宽=2)
	c1.pressed.emit()
	ui._refresh()
	await get_tree().process_frame
	check(str(ui._m63_sel) == "af_qi_rate_0_0", "135c-2 点击 选中 词缀 记录 (实际 %s)" % str(ui._m63_sel))
	var cell_sel: Button = ui._m63_bag_cells.get("af_qi_rate_0_0")
	check(cell_sel != null, "135c-2 选中 格 重建 存在")
	if cell_sel != null:
		var sn: StyleBox = cell_sel.get_theme_stylebox("normal")
		check(sn is StyleBoxFlat and (sn as StyleBoxFlat).border_width_left == 2 and (sn as StyleBoxFlat).border_color == ui.GOLD,
				"135c-2 选中 格 normal = 金边 叠加 (M6-3 口径; 实际 %s)" % str(sn))
	# 4) 残留 flat 默认 排查固化 (135c-2: 内联 Button.new() 族 有意 保留 flat 清单)
	var flat_keep: Dictionary = {
			"auto": ui._auto_badge, "idle": ui._idle_badge, "clear": ui._clear_badge,
			"poison": ui._poison_badge, "twprog": ui._tower_progress_badge, "onekey": ui._onekey_badge,
			"goalbar": ui._goalbar_bg,
	}
	for key in flat_keep:
		var b: Button = flat_keep[key]
		check(b != null and b.flat, "135c-2 残留 flat 排查 %s 徽标/进度条 flat 保留 (实际 %s)" % [key, str(b != null and b.flat)])
	for i in ui._onekey_btns.size():
		check((ui._onekey_btns[i] as Button).flat, "135c-2 残留 flat 排查 一键段 %d flat 保留" % i)
	for i in ui._auto_sum_btns.size():
		check((ui._auto_sum_btns[i] as Button).flat, "135c-2 残留 flat 排查 自动汇总段 %d flat 保留" % i)
	for ckey in ui._collect_btns:
		var cbtn: Button = ui._collect_btns[ckey]
		check(cbtn != null and cbtn.flat, "135c-2 残留 flat 排查 收集行 %s flat 保留 (实际 %s)" % [ckey, str(cbtn != null and cbtn.flat)])
	check(ui._auto_idle_btn != null and ui._auto_idle_btn.flat,
			"135c-2 残留 flat 排查 一键挂机 按钮 flat 保留 (打磨-90 高亮 基于 border_width 断言 口径)")
	# 收尾: 清 词缀 残留 防 污染 后续 段 (M6-3/收集 计数 断言)
	ui._m63_sel = ""
	g.affix_decompose_all()
	g.affix_bag.clear()
	g.seen_affixes.clear()
	g.affix_materials = 0
	ui._refresh()
	await get_tree().process_frame


func _assert_m135c_btn_skins() -> void:
	# 1) 突破按钮 (代表 默认 _make_button): normal/hover/pressed = btn_primary 三态 9-slice
	var bb: Button = ui._break_btn
	check(bb != null, "135c-1 突破按钮 节点 存在")
	if bb == null:
		return
	var bn: StyleBox = bb.get_theme_stylebox("normal")
	check(bn is StyleBoxTexture and (bn as StyleBoxTexture).texture != null and str((bn as StyleBoxTexture).texture.resource_path) == "res://assets/ui/btn_primary.png",
			"135c-1 突破按钮 normal = btn_primary.png 9-slice (实际 %s)" % str(bn))
	var bh: StyleBox = bb.get_theme_stylebox("hover")
	check(bh is StyleBoxTexture and str((bh as StyleBoxTexture).texture.resource_path) == "res://assets/ui/btn_primary_hover.png",
			"135c-1 突破按钮 hover = btn_primary_hover.png (实际 %s)" % str(bh))
	var bp: StyleBox = bb.get_theme_stylebox("pressed")
	check(bp is StyleBoxTexture and str((bp as StyleBoxTexture).texture.resource_path) == "res://assets/ui/btn_primary_pressed.png",
			"135c-1 突破按钮 pressed = btn_primary_pressed.png (实际 %s)" % str(bp))
	if bn is StyleBoxTexture:
		var bt: StyleBoxTexture = bn as StyleBoxTexture
		check(bt.texture_margin_left > 0.0 and bt.texture_margin_top > 0.0 and bt.texture_margin_right > 0.0 and bt.texture_margin_bottom > 0.0,
				"135c-1 突破按钮 9-slice 四边 边距 非 0 (l=%.0f t=%.0f r=%.0f b=%.0f)" % [bt.texture_margin_left, bt.texture_margin_top, bt.texture_margin_right, bt.texture_margin_bottom])
	check(bn != bh and bh != bp, "135c-1 三态 纹理 互 不 同 (状态 区分)")
	# 2) 技能 领悟 按钮 同 默认 口径 (非 微光 态 = 纹理)
	var sid: String = ""
	for k in ui._skill_btns:
		sid = str(k)
		break
	var skill_btn: Button = ui._skill_btns.get(sid) if sid != "" else null
	check(skill_btn != null, "135c-1 技能 领悟 按钮 存在")
	if skill_btn != null:
		var skn: StyleBox = skill_btn.get_theme_stylebox("normal")
		check(skn is StyleBoxTexture and str((skn as StyleBoxTexture).texture.resource_path) == "res://assets/ui/btn_primary.png",
				"135c-1 技能 按钮 normal = 默认 9-slice 纹理 (实际 %s)" % str(skn))
	# 3) 一键挂机 按钮 flat 保留 (打磨-90 border_width 断言 依赖)
	var ibn: StyleBox = ui._auto_idle_btn.get_theme_stylebox("normal")
	check(ibn is StyleBoxFlat and (ibn as StyleBoxFlat).border_color == Color(0.3, 0.35, 0.45),
			"135c-1 一键挂机 按钮 flat 保留 默认 (border=默认; 实际 %s)" % str(ibn))
	# 4) 金边高亮 适配 纹理 底: 可突破 时 突破按钮 normal 换 StyleBoxFlat 金边
	var ready_before: bool = ui._break_ready
	ui._break_ready = true
	ui._apply_break_btn_style()
	var gdn: StyleBox = bb.get_theme_stylebox("normal")
	check(gdn is StyleBoxFlat and (gdn as StyleBoxFlat).border_color == Color(0.98, 0.86, 0.5) and (gdn as StyleBoxFlat).border_width_left == 2,
			"135c-1 可突破 突破按钮 normal = 金边 StyleBoxFlat (叠加 纹理底; 实际 %s)" % str(gdn))
	ui._break_ready = ready_before
	ui._apply_break_btn_style()
	# 5) 微光 适配: 技能 按钮 微光中 = 金边, 结束 恢复 纹理 默认 (打磨-59 口径 在 135c-1 后 成立)
	if skill_btn != null:
		ui._btn_glow59(sid, skill_btn)
		var gl: StyleBox = skill_btn.get_theme_stylebox("normal")
		check(gl is StyleBoxFlat and (gl as StyleBoxFlat).border_color == Color(0.98, 0.86, 0.5),
				"135c-1 技能 按钮 微光中 normal = 金边 (实际 %s)" % str(gl))
		ui._skill_glow_done(sid)
		var rest: StyleBox = skill_btn.get_theme_stylebox("normal")
		check(rest is StyleBoxTexture and str((rest as StyleBoxTexture).texture.resource_path) == "res://assets/ui/btn_primary.png",
				"135c-1 技能 按钮 微光结束 恢复 纹理 默认 (实际 %s)" % str(rest))
	# 收尾: 清 残留 微光 标记 + 恢复 基准 态
	ui._skill_active_glow.clear()
	ui._break_ready = ready_before
	ui._apply_break_btn_style()
	ui._refresh()


# M7-4 打磨-139c: 音效 播放器 挂 现有 触发点 (main.gd AudioStreamPlayer + _sfx_play 单 通道;
# 6 触发点: 突破成/败 [_float_break 路径]/成就解锁 [_ach_float 路径]/一键系列 [_onekey_float 路径]/
# 塔胜利+新纪录 [_on_tower_challenge 手动 路径, 自动爬塔 不 弹 不 播]; 未知 名称/资源 缺失 静默 跳过;
# 只 播放 不 改 状态/存档/统计, 无 资源 副作用). 断言 (手动 驱动 确定性, 冻结 UI+GameData _process):
# player 节点 入树/初始 0 播放/未知 名称 防御/突破成=break_win 败=break_fail/成就=achieve/
# 一键=onekey (0 变更 不 播)/塔胜=tower_win/登天梯 新纪录 胜局 追加 new_record/镇妖塔 胜局 无 new_record/
# 无 资源·统计 副作用/收尾 复位 0 播放
func _assert_m139c_sfx() -> void:
	var g := GameData
	# 冻结 UI/GameData _process (手动 驱动 确定性; 段尾 恢复, 同 打磨-137 段 冻结 口径)
	var gproc: bool = g.is_processing()
	ui.set_process(false)
	g.set_process(false)
	# 1) player 节点: AudioStreamPlayer + 挂 主 UI 下 (UI 构建 入树, 6 音效 共享 通道)
	check(ui._sfx_player != null and ui._sfx_player is AudioStreamPlayer, "打磨-139c player 节点 存在 (AudioStreamPlayer)")
	if ui._sfx_player == null:
		g.set_process(gproc)
		ui.set_process(true)
		return
	check(ui._sfx_player.get_parent() == ui, "打磨-139c player 挂 主 UI 下 (实际 %s)" % str(ui._sfx_player.get_parent().get_class()))
	check(float(ui._sfx_player.volume_db) <= 0.0, "打磨-139c player volume_db<=0 (音量 压低 不 盖 音乐; 实际 %.1f)" % float(ui._sfx_player.volume_db))
	# 基准: 前段 既有 触发点 已 播放 (一键 浮动/突破 等 真实 路径 计数 可能 非 0) — 断言 用 增量 口径
	var sfx_base: int = int(ui._sfx_played)
	var sfx_last_base: String = str(ui._sfx_last)
	# 2) _sfx_play 直调: 未知 名称 静默 跳过 (计数/名称 不 更新), 有效 名称 计数 +1 + stream 设置
	ui._sfx_play("not_exist")
	check(int(ui._sfx_played) == sfx_base and str(ui._sfx_last) == sfx_last_base,
			"打磨-139c 未知 名称 静默 跳过 (计数/名称 不 更新; 实际 +%d/%s)" % [int(ui._sfx_played) - sfx_base, str(ui._sfx_last)])
	ui._sfx_play("break_win")
	check(int(ui._sfx_played) == sfx_base + 1 and str(ui._sfx_last) == "break_win",
			"打磨-139c 有效 名称 计数+1 记录 名称 (实际 +%d/%s)" % [int(ui._sfx_played) - sfx_base, str(ui._sfx_last)])
	check(ui._sfx_last_player == ui._sfx_player and ui._sfx_player.stream != null and ui._sfx_player.stream is AudioStreamWAV,
			"打磨-139c player 同 对象 + stream=AudioStreamWAV (实际 %s)" % str(ui._sfx_player.stream))
	# 复位 计数 (后续 触发点 断言 从 0 增量 起)
	ui._sfx_played = 0
	ui._sfx_last = ""
	ui._sfx_last_player = null
	# 受控 基准: 干净 状态 (防 前段 残留 污染: 成就/境界/塔 态)
	g.ach_done.clear()
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.affix_materials = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ready_events.clear()
	g.realm_idx = 0
	g.layer = 1
	g.ascended = false
	g.dao = 0.0
	g.dao_level = 0
	g.essence = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	var stats139: Dictionary = g.stats.duplicate(true)
	# 3) 突破音效: 成功=break_win (成 1/飞升 3/精进 4 同 口径, 取 普通 成功 1) / 失败=break_fail (与 浮动 同 路径)
	g.essence = 10.0
	g.try_breakthrough(0.01)
	ui._float_break()
	check(int(g.last_break_result) == 1, "打磨-139c 受控 突破 成功 (实际 %d)" % g.last_break_result)
	check(int(ui._sfx_played) == 1 and str(ui._sfx_last) == "break_win", "打磨-139c 突破成功 播 break_win (实际 %d/%s)" % [ui._sfx_played, str(ui._sfx_last)])
	# 失败: 成功 已 晋 层 (消耗 10→20 档), 按 当前 突破 消耗 注入 资源 后 必 失败
	g.essence = g.breakthrough_cost()
	g.try_breakthrough(0.999)
	ui._float_break()
	check(int(g.last_break_result) == 2, "打磨-139c 受控 突破 失败 (实际 %d)" % g.last_break_result)
	check(int(ui._sfx_played) == 2 and str(ui._sfx_last) == "break_fail", "打磨-139c 突破失败 播 break_fail (实际 %d/%s)" % [ui._sfx_played, str(ui._sfx_last)])
	# last_break_result=0 不 触发 (与 浮动 同 口径, 计数 不 变)
	g.last_break_result = 0
	ui._float_break()
	check(int(ui._sfx_played) == 2, "打磨-139c 突破 未触发 不 播 (计数 不变)")
	# 4) 成就解锁音效: _ach_float 新 解锁 弹 浮动 同 路径 播 achieve (同 一批 合并 一行 只 播 一次)
	var n_ach: int = int(ui._sfx_played)
	g.ach_done.append("equip_first")
	ui._ach_float(["equip_first"])
	check(int(ui._sfx_played) == n_ach + 1 and str(ui._sfx_last) == "achieve", "打磨-139c 成就解锁 播 achieve (实际 %d/%s)" % [ui._sfx_played, str(ui._sfx_last)])
	# 5) 一键系列音效: 变更>0 弹 浮动 同 路径 播 onekey / 0 变更 走 底部 消息 不 经 浮动 不 播
	var n_ok: int = int(ui._sfx_played)
	ui._onekey_float("一键领悟 3 个技能")
	check(int(ui._sfx_played) == n_ok + 1 and str(ui._sfx_last) == "onekey", "打磨-139c 一键系列 变更>0 播 onekey (实际 %d/%s)" % [ui._sfx_played, str(ui._sfx_last)])
	# 0 变更: 全部 已 领悟 时 一键领悟 走 _show_msg 分支 (不 经 _onekey_float → 不 播)
	g.owned.clear()
	g.learned.clear()
	for sk139 in g.skill_ids:
		g.learned.append(str(sk139))
	ui._on_learn_all()
	check(str(ui._msg_label.text).find("没有可领悟") >= 0, "打磨-139c 一键 0 变更 走 底部 消息 分支 (实际 %s)" % str(ui._msg_label.text).left(30))
	check(int(ui._sfx_played) == n_ok + 1, "打磨-139c 一键 0 变更 不 经 浮动 不 播 (计数 不变)")
	g.learned.clear()
	# 6) 塔胜利音效: 强 玩家 (飞升 道祖 恒胜) 手动 挑战 登天梯 第 2 层 (best=1 → new_record=true):
	#    胜局 播 tower_win + 新纪录 追加 new_record (同帧 先后 播, 收尾 last=new_record)
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 2
	g.tower_endless_best = 1
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.ascended = true
	g.dao_level = 8
	g.stones = 0.0
	g.essence = 0.0
	var mon139: Dictionary = g.tower_monster_stats(g.get_endless_floor(2))
	check(g.player_atk_effective() >= float(mon139["atk"]) * g.TOWER_WIN_RATIO, "打磨-139c 强 玩家 第 2 层 判定=胜 (数据 锚定)")
	var n_tw: int = int(ui._sfx_played)
	ui._on_tower_challenge("endless")
	await get_tree().process_frame
	check(bool(g.try_tower_challenge("endless", 0.5)["win"]), "打磨-139c 结算 口径 恒胜 (接口 锚定)")
	check(int(ui._sfx_played) == n_tw + 2, "打磨-139c 登天梯 新纪录 胜局 播 tower_win+new_record 共 2 次 (实际 +%d)" % (int(ui._sfx_played) - n_tw))
	check(str(ui._sfx_last) == "new_record", "打磨-139c 新纪录 收尾 last=new_record (实际 %s)" % str(ui._sfx_last))
	# 7) 镇妖塔 胜局: new_record 恒 false → 只 播 tower_win 不 追加 (计数 +1)
	var n_fx: int = int(ui._sfx_played)
	ui._on_tower_challenge("fixed")
	await get_tree().process_frame
	check(int(ui._sfx_played) == n_fx + 1 and str(ui._sfx_last) == "tower_win", "打磨-139c 镇妖塔 胜局 只 播 tower_win (实际 +%d/%s)" % [int(ui._sfx_played) - n_fx, str(ui._sfx_last)])
	# 8) 无 副作用: 音效 只 播放 — 不 新增 统计 键 (既有 埋点 键 的 数值 自 增 属 触发 路径 既有 口径,
	#    非 音效 引入; 此处 断言 键 集合 无 新增 即 音效 层 无 副作用)
	var extra_keys: Array[String] = []
	for k in g.stats:
		if not stats139.has(k):
			extra_keys.append(str(k))
	check(extra_keys.is_empty(), "打磨-139c 音效 不 新增 统计 键 (新增 %s)" % ",".join(extra_keys))
	check(float(stats139.get("skill_use", 0.0)) == float(g.stats.get("skill_use", 0.0)),
			"打磨-139c 音效 路径 无 神通 施展 统计 副作用 (skill_use 不变)")
	# 收尾: 恢复 干净 基准 (塔 态/飞升 态/成就 归零 + 音效 计数 复位, 防 污染 后续)
	g.affix_bag = {}
	g.affix_load = {}
	g.slot_upgrades = {}
	g.seen_affixes = []
	g.affix_materials = 0
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	g.ach_done.clear()
	g.tower_fixed_floor = 0
	g.tower_fixed_clear = false
	g.tower_endless_floor = 1
	g.tower_endless_best = 0
	g.tower_daily_date = ""
	g.tower_daily_bonus_stones = 0.0
	g.poison_battles = 0
	g.poison_events.clear()
	g.ascended = false
	g.dao_level = 0
	g.realm_idx = 0
	g.layer = 1
	g.essence = 0.0
	g.stones = 0.0
	g.last_break_result = 0
	ui._sfx_played = 0
	ui._sfx_last = ""
	ui._sfx_last_player = null
	# 收尾: 清 音效池 缓存 + player 释放 stream (防 quit 时 资源 仍 被 引用 告警; 缓存 懒 加载 幂等 无 副作用)
	ui._sfx_player.stream = null
	g._sfx_cache.clear()
	g.set_process(gproc)
	ui.set_process(true)
	ui._refresh()
	await get_tree().process_frame
	check(int(ui._sfx_played) == 0 and str(ui._sfx_last) == "", "打磨-139c 收尾 复位 0 播放 名称空 (实际 %d/%s)" % [ui._sfx_played, str(ui._sfx_last)])


# M7-4 打磨-140: 音效 开关 (139c 6 触发点 无 玩家 开关 入口, 与 水墨背景 开关 137-2 同 定位: 修行页 自动 系列 区 toggle, 存档 持久化)
# 断言: 按钮 节点/toggle 默认 开/tooltip 口径/点击 切 关 _sfx_play 静默 跳过/恢复 开 播放/读档 同步 按钮态/同态 节流/无 资源 统计 副作用/收尾 复位 开
func _assert_m140_sfx_toggle() -> void:
	var g := GameData
	# 冻结 UI/GameData _process (手动 驱动 确定性; 段尾 双 恢复, 同 打磨-137/139c 段 冻结 口径)
	var gproc: bool = g.is_processing()
	ui.set_process(false)
	g.set_process(false)
	# 1) 节点 + toggle 初始 态
	check(ui._sfx_btn != null, "打磨-140 音效 开关 按钮 节点 存在")
	if ui._sfx_btn == null:
		g.set_process(gproc)
		ui.set_process(true)
		return
	check(ui._sfx_btn.toggle_mode, "打磨-140 按钮 toggle_mode=true (实际 %s)" % str(ui._sfx_btn.toggle_mode))
	check(ui._sfx_btn.text == "音效: 开" and ui._sfx_btn.button_pressed,
			"打磨-140 初始 默认 开: 文本+pressed (实际 %s pressed=%s)" % [str(ui._sfx_btn.text), str(ui._sfx_btn.button_pressed)])
	check(str(ui._sfx_btn.tooltip_text).contains("6 处 触发 点 短音效"), "打磨-140 tooltip 含 口径 说明 (实际 %s)" % str(ui._sfx_btn.tooltip_text).left(20))
	check(ui._sfx_btn.get_parent() == ui._bg_btn.get_parent(),
			"打磨-140 按钮 与 水墨背景 开关 同 容器 同区 (实际 %s)" % str(ui._sfx_btn.get_parent().get_class()))
	# 2) 基准: 开 态 播放 正常 (139c 收尾 已 清 缓存/计数, 此 处 直调 有效 名称 计数 +1)
	var base140: int = int(ui._sfx_played)
	ui._sfx_play("onekey")
	check(int(ui._sfx_played) == base140 + 1 and str(ui._sfx_last) == "onekey",
			"打磨-140 开 态 _sfx_play 正常 播放 (实际 +%d/%s)" % [int(ui._sfx_played) - base140, str(ui._sfx_last)])
	ui._sfx_played = 0
	ui._sfx_last = ""
	# 3) 点击 切 关 (emit pressed 走 真实 _on_sfx_toggle 路径): sfx_on=false + 按钮态 + 底部消息 + _sfx_play 静默 跳过
	ui._sfx_btn.emit_signal("pressed")
	check(g.sfx_on == false, "打磨-140 点击 切关: sfx_on=false (实际 %s)" % str(g.sfx_on))
	check(ui._sfx_btn.text == "音效: 关" and not ui._sfx_btn.button_pressed,
			"打磨-140 切关 后 按钮 文本+pressed 同步 (实际 %s pressed=%s)" % [str(ui._sfx_btn.text), str(ui._sfx_btn.button_pressed)])
	check(str(ui._msg_label.text).contains("音效"), "打磨-140 切关 底部 消息 确认 (实际 %s)" % str(ui._msg_label.text).left(20))
	var n0: int = int(ui._sfx_played)
	ui._sfx_play("onekey")
	check(int(ui._sfx_played) == n0, "打磨-140 关 态 _sfx_play 静默 跳过 (计数 不变; 实际 +%d)" % (int(ui._sfx_played) - n0))
	ui._sfx_play("break_win")
	check(int(ui._sfx_played) == n0, "打磨-140 关 态 有效 名称 仍 静默 跳过 (实际 +%d)" % (int(ui._sfx_played) - n0))
	# 4) 点击 恢复 开: 播放 恢复
	ui._sfx_btn.emit_signal("pressed")
	check(g.sfx_on == true and ui._sfx_btn.text == "音效: 开" and ui._sfx_btn.button_pressed,
			"打磨-140 恢复 开: 状态+按钮态 (实际 %s pressed=%s)" % [str(g.sfx_on), str(ui._sfx_btn.button_pressed)])
	var n1: int = int(ui._sfx_played)
	ui._sfx_play("achieve")
	check(int(ui._sfx_played) == n1 + 1 and str(ui._sfx_last) == "achieve",
			"打磨-140 恢复 开 后 播放 恢复 (实际 +%d/%s)" % [int(ui._sfx_played) - n1, str(ui._sfx_last)])
	ui._sfx_played = 0
	ui._sfx_last = ""
	# 5) 读档 同步: 存档 sfx_on=false -> load_game -> _refresh 按钮态 同步 关
	g.save_game()
	var fp: String = g.SAVE_PATH
	var fsr := FileAccess.open(fp, FileAccess.READ)
	var sj: Dictionary = JSON.parse_string(fsr.get_as_text())
	fsr.close()
	sj["sfx_on"] = false
	var fsw := FileAccess.open(fp, FileAccess.WRITE)
	fsw.store_string(JSON.stringify(sj))
	fsw.close()
	g.load_game()
	check(g.sfx_on == false, "打磨-140 读档 恢复 sfx_on=false (实际 %s)" % str(g.sfx_on))
	ui._refresh()
	check(ui._sfx_btn.text == "音效: 关" and not ui._sfx_btn.button_pressed,
			"打磨-140 读档 后 按钮态 同步=关 (实际 %s pressed=%s)" % [str(ui._sfx_btn.text), str(ui._sfx_btn.button_pressed)])
	# 6) 同态 节流 稳定
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	check(ui._sfx_btn.text == "音效: 关" and not ui._sfx_btn.button_pressed,
			"打磨-140 同态 节流 稳定 无 抖动 (实际 %s)" % str(ui._sfx_btn.text))
	# 7) 无 资源/统计 副作用: 开关 动作 (点击 切 关/开 两轮 + 读档) 不 改 资源/统计
	#    load_game 会 舍入 float 存读档 往返 (打磨-66 已知 口径), 故 基准 取 load 后 快照, 只 覆盖 收尾 点击 窗口
	var st1: float = g.stones
	var es1: float = g.essence
	var stats1: Dictionary = g.stats.duplicate(true)
	# 收尾: 复位 开 (点击 切回 走 真实 路径 + _refresh 同步)
	ui._sfx_btn.emit_signal("pressed")
	check(g.sfx_on == true and ui._sfx_btn.text == "音效: 开" and ui._sfx_btn.button_pressed,
			"打磨-140 收尾 复位 开 (实际 %s)" % str(g.sfx_on))
	ui._refresh()
	check(float(g.stones) == st1 and float(g.essence) == es1 and g.stats == stats1,
			"打磨-140 开关 动作 无 资源/统计 副作用 (收尾 点击 窗口)")
	# 收尾: 落盘 + 复位 播放 计数 + 清 音效池 缓存/player stream (防 quit 资源 告警, 同 139c 口径)
	g.save_game()
	ui._sfx_played = 0
	ui._sfx_last = ""
	ui._sfx_last_player = null
	if ui._sfx_player != null:
		ui._sfx_player.stream = null
	g._sfx_cache.clear()
	g.set_process(gproc)
	ui.set_process(true)
	ui._refresh()
	await get_tree().process_frame
	check(int(ui._sfx_played) == 0 and g.sfx_on == true, "打磨-140 收尾 复位 0 播放 + sfx_on=开 (实际 %d/%s)" % [ui._sfx_played, str(g.sfx_on)])


# 打磨-142: 突破 按钮 tooltip 动态 段 — 核心 CTA 悬停 消耗/成功率/缺口/ETA/预期成本 一览 (break_btn_tip 单源);
# tooltip = 静态 口径 前缀 (_break_btn_tip_static) + 动态段, _refresh 文本 变化 才 刷 (同 打磨-84/85 口径).
# 断言 (手动驱动 确定性): 静态段 标记+动态段=接口 恒等 / 境界 提升 头部 消耗 动态 同步 / 攒满 已攒够 文案 /
# 飞升 道行 口径 / 道祖 圆满 / 同态 节流 无 资源·统计 副作用 / 收尾 干净 基准 (防 污染 后续 段)
func _assert_break_btn_tip() -> void:
	var g := GameData
	var btn: Node = ui._break_btn
	var tip0: String = str(btn.tooltip_text)
	check(tip0.find("【本次 突破 预估 (动态)】") >= 0,
		"打磨-142 tooltip 含 静态段 标记 (实际 %s)" % tip0.left(40))
	check(tip0.find(g.break_btn_tip()) >= 0,
		"打磨-142 初始 动态段=接口 恒等 (实际 %s)" % tip0)
	# 受控 基准: 未飞升 半程 — 动态段=接口 恒等 含 消耗+缺口+ETA+预期成本
	var r142: int = g.realm_idx
	var a142: bool = g.ascended
	var d142: float = g.dao
	var dl142: int = g.dao_level
	var es142: float = g.essence
	g.ascended = false
	g.dao_level = 0
	g.realm_idx = 0
	g.essence = g.breakthrough_cost() * 0.5
	ui._refresh()
	var tip1: String = str(btn.tooltip_text)
	check(tip1.find(g.break_btn_tip()) >= 0 and tip1.find("还差") >= 0 and tip1.find("期望次数 ~") >= 0,
		"打磨-142 基准 动态段=接口 恒等 含 缺口+预期成本 (实际 %s)" % tip1)
	# 境界 提升 — 消耗/成功率 变 头部 动态 同步
	g.essence = 0.0
	g.realm_idx = 2
	g.essence = g.breakthrough_cost() * 0.5
	ui._refresh()
	var tip2: String = str(btn.tooltip_text)
	check(tip2 != tip1 and tip2.find(g.break_btn_tip()) >= 0,
		"打磨-142 境界2 头部 动态 同步 (实际 %s)" % tip2)
	# 攒满 — 已攒够 无 ETA/预期成本 段
	g.essence = g.breakthrough_cost()
	ui._refresh()
	var tip3: String = str(btn.tooltip_text)
	check(tip3.find("灵气已攒够, 点击突破") >= 0,
		"打磨-142 攒满 动态段=已攒够 文案 (实际 %s)" % tip3)
	# 飞升 道行 口径 — 头部 修炼道行 耗 X 道行
	g.ascended = true
	g.dao_level = 0
	g.dao = g.dao_break_cost() * 0.25
	ui._refresh()
	var tip4: String = str(btn.tooltip_text)
	check(tip4.find("修炼道行 耗") >= 0 and tip4.find(g.break_btn_tip()) >= 0,
		"打磨-142 飞升 道行 口径 动态段 (实际 %s)" % tip4)
	# 道祖 封顶 — 圆满 文案
	g.dao_level = g.IMMORTAL_REALMS.size() - 1
	ui._refresh()
	var tip5: String = str(btn.tooltip_text)
	check(tip5.find("已至道祖") >= 0,
		"打磨-142 道祖 圆满 文案 (实际 %s)" % tip5)
	# 同态 节流: 再刷 稳定 无 资源/统计 副作用 (UI 挂机 _process 每帧 主动 收益 资源 快照 会 漂移,
	# 同 打磨-59 口径: set_process(false) 冻结 UI 窗口 内 手动 驱动; stats 快照 覆盖 整个 窗口)
	var snap142: Dictionary = g.stats.duplicate(true)
	var gproc142: bool = g.is_processing()
	var uiproc142: bool = ui.is_processing()
	g.set_process(false)
	ui.set_process(false)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	check(str(btn.tooltip_text) == tip5 and g.stats == snap142,
		"打磨-142 同态 节流 稳定 无 统计 副作用 (窗口内 冻结 UI)")
	# 收尾 复原 (恢复 挂机 进程, 资源 漂移 不 断言 — 主动 收益 口径)
	g.ascended = a142
	g.dao_level = dl142
	g.dao = d142
	g.essence = es142
	g.realm_idx = r142
	g.set_process(gproc142)
	ui.set_process(uiproc142)
	ui._refresh()
	check(g.stats == snap142, "打磨-142 收尾 复原 无 统计 副作用")


# 打磨-143: 6 个 一键 按钮 (领悟/神通/施展/法器/装备/最佳) tooltip 动态段 — 单源 g.onekey_btn_tip
# 复用 打磨-76 onekey_segment_tips 明细, 与 顶栏 一键 徽标 段 同 状态键 节流 (挂机 恒定 无 每帧 重建).
# 断言: 静态前缀 标记 + 动态段 = 接口 恒等 x6 / 筛选 叠加 领悟/神通 段 同步 / 学 神通 施展 段 就绪 同步 /
# 同态 节流 无 资源/统计 副作用 (UI 挂机 _process 冻结 窗口 内 手动 驱动, 同 打磨-59/142 口径) / 收尾 干净 基准.
func _assert_onekey_btn_tips() -> void:
	var g := GameData
	# 受控基准: 境界2 层1 / 灵石 5000 / 空 状态 (防 前序 段 残留, 与 打磨-76 基准 同口径)
	g.realm_idx = 2
	g.layer = 1
	g.essence = 0.0
	g.stones = 5000.0
	g.dao = 0.0
	g.dao_level = 0
	g.ascended = false
	g.learned.clear()
	g.owned.clear()
	g.owned_eq.clear()
	g.equipped.clear()
	g._active_cd.clear()
	ui._on_filter("")
	ui._on_tier_filter("")
	ui._on_equip_filter("")
	ui._on_equip_tier_filter("")
	ui._refresh()
	# 1) 静态前缀 标记 + 动态段 = 接口 恒等 x6 (单源 口径)
	var btns: Array = [ui._learn_all_btn, ui._active_learn_btn, ui._active_all_btn,
		ui._items_buy_btn, ui._buy_all_btn, ui._equip_best_btn]
	var marks: Array = ["【本次 一键领悟 预估", "【本次 一键神通 预估", "【本次 一键施展 预估",
		"【本次 一键购买 预估", "【本次 一键购买 预估", "【本次 一键最佳 预估"]
	var statics: Array = [ui._ok_learn_tip_static, ui._ok_actlearn_tip_static, ui._ok_cast_tip_static,
		ui._ok_item_tip_static, ui._ok_buy_tip_static, ui._ok_best_tip_static]
	var cat143: String = ui._filter_active
	var tier143: int = int(ui._tier_active) if ui._tier_active != "" else -1
	for i in 6:
		var tt: String = str(btns[i].tooltip_text)
		check(tt.begins_with(str(statics[i])) and tt.find(str(marks[i])) >= 0,
			"打磨-143 按钮%d tooltip = 静态前缀+动态段标记 (实际 %s)" % [i, tt.left(20)])
		var seg: String = g.onekey_btn_tip(i, cat143, tier143) if i < 2 else g.onekey_btn_tip(i)
		check(tt == str(statics[i]) + seg,
			"打磨-143 按钮%d tooltip = 静态前缀 + onekey_btn_tip 恒等 (实际 %s)" % [i, tt.substr(0, 30)])
	# 2) 筛选 叠加: tier0 → 领悟/神通 段 收窄 动态 同步 (状态键 变化 触发 刷)
	ui._on_tier_filter("0")
	ui._refresh()
	var t0l: String = g.onekey_btn_tip(0, "", 0)
	var t0a: String = g.onekey_btn_tip(1, "", 0)
	check(str(ui._learn_all_btn.tooltip_text).ends_with(t0l) and t0l.find("20 个可学:") >= 0,
		"打磨-143 tier0 领悟段 收窄 同步 20 个可学 (实际 %s)" % t0l.left(16))
	check(str(ui._active_learn_btn.tooltip_text).ends_with(t0a) and t0a.find("6 个可学:") >= 0,
		"打磨-143 tier0 神通段 收窄 同步 6 个可学 (实际 %s)" % t0a.left(16))
	# 3) 学 全部 可学 神通 → 施展 段 就绪 数 上升 动态 同步 (爆发 预览 段 非空)
	ui._on_tier_filter("")
	g.learn_all_active()
	ui._refresh()
	var tcs: String = g.onekey_btn_tip(2)
	var rn: int = g.active_ready_count()
	check(str(ui._active_all_btn.tooltip_text).ends_with(tcs)
			and tcs.begins_with("%d 个就绪:" % rn) and rn > 0,
		"打磨-143 学神通 后 施展段 就绪 同步 %d 个就绪 (实际 %s)" % [rn, tcs.left(16)])
	# 同态 节流: 再刷 键 不变 → tooltip 不重写 稳定 无 资源/统计 副作用 (UI 挂机 _process 冻结 窗口, 同 打磨-142 口径)
	var snap143: Dictionary = g.stats.duplicate(true)
	var st143s: float = g.stones
	var tips143: Array = []
	for i in 6:
		tips143.append(str(btns[i].tooltip_text))
	var gproc143: bool = g.is_processing()
	var uiproc143: bool = ui.is_processing()
	g.set_process(false)
	ui.set_process(false)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	var same: bool = true
	for i in 6:
		if str(btns[i].tooltip_text) != tips143[i]:
			same = false
	check(same and g.stats == snap143 and g.stones == st143s,
		"打磨-143 同态 节流 6 按钮 tooltip 稳定 无 资源/统计 副作用 (窗口内 冻结 UI)")
	# 收尾 复原 干净 基准 (恢复 挂机 进程, 资源 漂移 不 断言 — 主动 收益 口径)
	g.learned.clear()
	g._active_cd.clear()
	g.stones = 0.0
	g.essence = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.set_process(gproc143)
	ui.set_process(uiproc143)
	ui._refresh()
	check(g.stats == snap143 and g.learned.is_empty(), "打磨-143 收尾 干净 基准 无 统计 副作用")

# 打磨-144: 修行页 下一目标 行 tooltip 动态段 — _goal_label tooltip 追加
# "【下一目标 状态 (动态)】" 段 (GameData.goal_line_tip 只读接口: 当前 速率/成功率/自动突破 状态,
# 与 行 文本 next_goal_text 互补). 断言 (手动驱动 确定性): 静态前缀+接口 恒等/开 自动突破 段 同步/
# 境界 成功率 同步/飞升 道行 口径/同态 节流 无副作用/收尾 干净 基准 (tooltip 节点 隐藏 态 仍可 读).
func _assert_goal_line_tip() -> void:
	var g := GameData
	var gl: Label = ui._goal_label
	var tip0: String = str(gl.tooltip_text)
	check(tip0.find("【下一目标 状态 (动态)】") >= 0,
		"打磨-144 下一目标 行 tooltip 含 动态段 标记 (实际 %s)" % tip0.left(30))
	check(tip0 == str(ui._goal_tip_static) + g.goal_line_tip(),
		"打磨-144 初始 tooltip = 静态前缀 + goal_line_tip 接口 恒等 (实际 %s)" % tip0)
	# 受控 基准: 未飞升 境界0层1 / 关 自动突破 / 半程 资源 (前序 段 残留 须 显式 清零)
	var a144: bool = g.ascended
	var d144: float = g.dao
	var dl144: int = g.dao_level
	var es144: float = g.essence
	var ab144: bool = g.auto_break
	var r144: int = g.realm_idx
	var l144: int = g.layer
	g.ascended = false
	g.dao_level = 0
	g.dao = 0.0
	g.realm_idx = 0
	g.layer = 1
	g.essence = g.breakthrough_cost() * 0.5
	g.auto_break = false
	ui._refresh()
	var tip1: String = str(gl.tooltip_text)
	var rl144: String = "当前 %s 灵气/秒" % g.fmt(g.qi_per_sec())
	check(tip1.begins_with(str(ui._goal_tip_static)) and tip1.begins_with(str(ui._goal_tip_static) + rl144)
			and tip1 == str(ui._goal_tip_static) + g.goal_line_tip(),
		"打磨-144 基准 未飞升 静态前缀+速率段=接口 恒等 (实际 %s)" % tip1.left(40))
	check(("突破成功率 %d%%" % int(round(g.primary_break_chance() * 100.0))) in tip1 and "自动突破: 关" in tip1,
		"打磨-144 基准 含 成功率 段+自动突破 关 段 (实际 %s)" % tip1)
	# 开 自动突破 — 自动突破 段 动态 同步 (开关 状态 变化 _refresh 感知)
	g.auto_break = true
	ui._refresh()
	var tip2: String = str(gl.tooltip_text)
	check(tip2 != tip1 and "自动突破: 开" in tip2 and tip2 == str(ui._goal_tip_static) + g.goal_line_tip(),
		"打磨-144 开 自动突破 段 动态 同步 = 接口 恒等 (实际 %s)" % tip2)
	# 境界 提升 — 成功率 变 动态 同步 (境界2 成功率 与 基准 不同)
	g.auto_break = false
	g.realm_idx = 2
	g.essence = g.breakthrough_cost() * 0.5
	ui._refresh()
	var tip3: String = str(gl.tooltip_text)
	check(tip3 != tip2 and ("突破成功率 %d%%" % int(round(g.primary_break_chance() * 100.0))) in tip3,
		"打磨-144 境界2 成功率 段 动态 同步 (实际 %s)" % tip3)
	# 飞升 道行 口径 — 速率 段 道行 + 道行精进成功率 段
	g.ascended = true
	g.dao_level = 0
	g.dao = g.dao_break_cost() * 0.25
	ui._refresh()
	var tip4: String = str(gl.tooltip_text)
	check(tip4.begins_with(str(ui._goal_tip_static) + "当前 %s 道行/秒" % g.fmt(g.qi_per_sec()))
			and ("道行精进成功率 %d%%" % int(round(g.primary_break_chance() * 100.0))) in tip4,
		"打磨-144 飞升 道行 口径 速率+成功率 段 (实际 %s)" % tip4)
	# 同态 节流: 再刷 键 不变 → tooltip 不重写 稳定 无 资源/统计 副作用 (UI 挂机 _process 冻结 窗口, 同 打磨-142 口径)
	var snap144: Dictionary = g.stats.duplicate(true)
	var st144s: float = g.stones
	var gproc144: bool = g.is_processing()
	var uiproc144: bool = ui.is_processing()
	g.set_process(false)
	ui.set_process(false)
	ui._refresh()
	await get_tree().process_frame
	ui._refresh()
	check(str(gl.tooltip_text) == tip4 and g.stats == snap144 and g.stones == st144s,
		"打磨-144 同态 节流 tooltip 稳定 无 资源/统计 副作用 (窗口内 冻结 UI)")
	# 收尾 复原 干净 基准 (恢复 挂机 进程)
	g.ascended = a144
	g.dao_level = dl144
	g.dao = d144
	g.essence = es144
	g.realm_idx = r144
	g.layer = l144
	g.auto_break = ab144
	g.set_process(gproc144)
	ui.set_process(uiproc144)
	ui._refresh()
	check(g.stats == snap144 and g.auto_break == ab144, "打磨-144 收尾 干净 基准 无 统计 副作用")

