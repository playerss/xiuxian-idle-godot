extends Control
## 修仙挂机 · 主界面 (UI 全部代码构建, Tab: 修行/技能/装备)
## 打磨-41: 技能/装备/法器 行首 4px 品质色竖条 (技能 tier 0..5 / 装备 tier 0..6 / 法器按价格档: 凡灰·玄蓝·仙紫·神金)
## 打磨-42: 成就页顶栏收集进度一览 mini 进度条 (4 类横排, 满=金/未满=青, 比例 1% 量化档才刷)
## 打磨-44: 收集进度一览 点击直达 (技能/装备/法器 点击切对应 Tab+重置筛选, 总计弹口径提示; 纯导航无存档/统计副作用)
## 打磨-46: 一键系列按钮 tooltip 统一口径 (动作与顺序 / 筛选叠加与作用范围 / 按钮计数口径, 5 按钮)

const BG := Color(0.07, 0.08, 0.11)
const PANEL_BG := Color(0.12, 0.13, 0.18)
const CARD_BG := Color(0.16, 0.17, 0.22)
const GOLD := Color(0.98, 0.86, 0.5)
const CYAN := Color(0.62, 0.9, 0.95)
const DIM := Color(0.6, 0.62, 0.68)
const WHITEISH := Color(0.92, 0.92, 0.95)
const HILITE := Color(0.98, 0.86, 0.5)  # 已学/已穿戴 高亮金

var _realm_label: Label
var _essence_label: Label
var _stones_label: Label
var _qi_label: Label
var _stone_rate_label: Label
var _stone_next_label: Label    # 打磨-50: 灵石速率行内联 下一件可购 ETA (修行页)
var _stone_next_text := ""      # 打磨-50: 内联文本缓存 (变化时才刷)
var _offline_label: Label      # 打磨-13: 离线每小时收益 (修行页)
var _offline_text := ""        # 离线文本缓存 (变化时才刷)
var _break_eta_label: Label    # 打磨-24: 突破/道行精进 ETA (修行页)
var _break_eta_text := ""      # 突破 ETA 文本缓存 (变化时才刷)
var _chance_label: Label       # 打磨-36: 主突破/道行精进成功率 (修行页)
var _chance_text := ""         # 成功率文本缓存 (变化时才刷)
var _chance_tip := ""          # 打磨-37: 成功率构成 tooltip 缓存 (变化才刷)
var _goal_label: Label         # 打磨-31: 下一目标提示 (修行页)
var _goal_text := ""           # 下一目标文本缓存 (变化时才刷)
var _stats_label: Label        # 打磨-14: 修行统计 (修行页)
var _stats_text := ""          # 统计文本缓存 (变化时才刷)
var _progress_label: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _break_btn: Button
var _auto_break_btn: Button     # 打磨-67: 自动突破开关 (toggle, 存档持久化)
var _auto_break_on := false     # 打磨-67: 上帧开关状态缓存 (变化才刷按钮态)
var _auto_buy_btn: Button       # 打磨-68: 自动购置开关 (toggle, 存档持久化)
var _auto_buy_on := false       # 打磨-68: 上帧开关状态缓存 (变化才刷按钮态)
var _auto_buy_msg_seq := 0      # 打磨-68: 已提示过的 自动购置 变更事件序号 (避免重复提示; 启动=0 与 GameData 同态)
var _auto_cast_btn: Button      # 打磨-69: 自动施展开关 (toggle, 存档持久化)
var _auto_cast_on := false      # 打磨-69: 上帧开关状态缓存 (变化才刷按钮态)
var _auto_cast_float_label: Label   # 打磨-69: 自动施展 浮动提示 (顶层, 居中, 绿色)
var _auto_cast_float_tween: Tween
var _auto_cast_msg_seq := 0     # 打磨-69: 已处理过的 自动施展 变更事件序号 (避免重复弹浮动; 启动=0 与 GameData 同态)
var _auto_cast_float_count := 0  # 打磨-69: 自动施展 浮动提示次数 (自测断言用)
var _auto_cast_last_text := ""   # 打磨-69: 最近一次自动施展 浮动文案 (自测断言用)
var _shop_box: VBoxContainer
var _shop_rows: Dictionary = {}
var _items_buy_btn: Button          # 打磨-29: 法器 一键购买 (修行页法器区)
var _msg_label: Label
var _msg_tween: Tween
var _float_label: Label
var _float_tween: Tween
var _ach_float_label: Label   # 打磨-17: 成就解锁浮动提示 (顶层)
var _ach_float_tween: Tween
var _ach_prev: Array[String] = []  # 打磨-17: 上帧已解锁成就快照 (检测新解锁)
var _ach_float_count := 0          # 打磨-17: 成就浮动提示次数 (自测断言用)
var _onekey_float_label: Label     # 打磨-45: 一键系列浮动反馈 (顶层, 居中)
var _onekey_float_tween: Tween
var _onekey_float_count := 0       # 打磨-45: 浮动提示次数 (自测断言用)
var _onekey_last_text := ""        # 打磨-45: 最近一次浮动文案 (自测断言用)
var _ready_float_label: Label      # 打磨-57: 主动神通 冷却完毕转就绪 浮动提示 (顶层, 居中)
var _ready_float_tween: Tween
var _ready_float_count := 0        # 打磨-57: 就绪浮动提示次数 (自测断言用)
var _ready_last_text := ""         # 打磨-57: 最近一次就绪浮动文案 (自测断言用)
var _offline_float_label: Label    # 打磨-66: 离线收益 启动浮动提示 (顶层, 居中, 金色)
var _offline_float_tween: Tween
var _offline_float_count := 0      # 打磨-66: 离线浮动提示次数 (自测断言用)
var _offline_last_text := ""       # 打磨-66: 最近一次离线浮动文案 (自测断言用)
var _break_flash_seq := 0
var _realm_tip := ""              # 境界标签 tooltip 缓存 (变化时才刷新)
var _stone_tip := ""              # 打磨-49: 顶栏灵石行 tooltip 缓存 (变化才刷, 速率/缺口随挂机变化)
var _btn_sb_normal: StyleBoxFlat  # 突破按钮默认样式 (闪烁后恢复用)
var _btn_sb_gold: StyleBoxFlat    # 打磨-32: 突破按钮"可突破"金边高亮样式
var _break_ready := false         # 打磨-32: 上帧可突破状态缓存 (变化才刷样式)
var _flash_sb: StyleBoxFlat       # 闪烁用样式 (成功绿/失败红)
var _flash_left := 0              # 剩余闪烁帧数
var _tab: TabContainer
var _skill_box: VBoxContainer
var _skill_row_nodes: Dictionary = {}
var _skill_btns: Dictionary = {}
var _burst_previews: Dictionary = {}    # 打磨-54: 主动神通 id -> 爆发预览标签 (金色小字, 只读预览)
var _burst_previews_key: Dictionary = {} # 打磨-54: id -> "已学|预览文本" 缓存键 (tooltip 只在该键变化时重建)
var _skill_cd_bars: Dictionary = {}     # 打磨-58: 主动神通 id -> {bg, fill} 冷却进度条 (青色填充, 归零隐藏)
# 打磨-59: 冷却完毕 收口动画 + 按钮微光 (就绪事件触发: 进度条 满条快速收窄 青色闪烁,
# 施展按钮 短暂 金边微光; 纯视觉, 无 状态/存档/统计 副作用)
var _skill_active_glow: Dictionary = {} # 打磨-59: 主动神通 id -> true (按钮金边微光进行中, 防 _refresh 覆盖)
var _skill_active_close: Dictionary = {} # 打磨-59: 主动神通 id -> {tween} (进度条收口动画进行中, 防 _refresh 重绘)
var _skill_glow_restored: Dictionary = {} # 打磨-59: 按钮 默认样式缓存 (id -> [normal,hover,pressed], 微光结束恢复)
var _skill_ready_seq := 0               # 打磨-59: 收口+微光 触发批次计数 (每批就绪 +1, 自测断言用)
var _skill_cd_q: Dictionary = {}        # 打磨-58: id -> "宽|档" 缓存键 (2% 量化+布局宽变化才刷, 防每帧重绘)
var _skill_cd_acc := 0.0                # 打磨-58: 冷却进度条 1 秒节流累计 (同 打磨-12/33 口径)
var _filter_btns: Dictionary = {}
var _filter_active := ""
var _tier_btns: Dictionary = {}         # 打磨-20: 品质筛选按钮 (key = 品质索引字符串, "" = 全部)
var _tier_active := ""                 # 打磨-20: 当前品质筛选 ("" = 全部)
var _equip_box: VBoxContainer
var _equip_row_nodes: Dictionary = {}
var _equip_btns: Dictionary = {}
var _learn_all_btn: Button           # 打磨-23: 一键领悟 (技能页)
var _active_learn_btn: Button        # 打磨-56: 一键神通 (技能页, 只学 筛选范围内 未学+境界足够 的 主动神通)
var _active_all_btn: Button         # 打磨-30: 一键施展 (技能页, 释放所有就绪主动神通)
var _buy_all_btn: Button            # 打磨-23: 一键购买 (装备页)
var _equip_best_btn: Button         # 打磨-26: 一键最佳穿戴 (装备页)
var _equip_filter_btns: Dictionary = {}  # 部位 id -> 筛选按钮 (打磨-11)
var _equip_filter_active := ""           # "" = 全部
var _equip_tier_btns: Dictionary = {}    # 打磨-21: 装备品质筛选按钮 (key = 品质索引字符串, "" = 全部)
var _equip_tier_active := ""             # 打磨-21: 当前装备品质筛选 ("" = 全部)
var _learnable_btn: Button               # 打磨-38: 技能页"只看可学"开关 (与 类别/品质 筛选 AND 叠加)
var _learnable_on := false               # 打磨-38: "只看可学"当前开关状态
var _eq_states: Array = []               # 打磨-22: 上帧装备状态快照 (变化才重排)
var _slot_labels: Dictionary = {}
var _card_sb_normal: StyleBoxFlat
var _card_sb_hi: StyleBoxFlat
var _ach_box: VBoxContainer
var _ach_rows: Dictionary = {}      # 成就 id -> {row, name_l, desc_l, prog_l}
var _ach_count_label: Label
var _ach_hl_seq := 0               # 成就解锁总数缓存 (变化时才刷样式)
var _ach_states: Array = []           # 打磨-39: 上帧成就排序键快照 (变化才重排)
var _ach_bar_q: Dictionary = {}       # 打磨-40: 成就进度条量化缓存 id -> "宽|档" (宽/档变化才刷, 防每帧重绘)
var _collect_box: Control         # 打磨-42: 成就页顶栏 收集进度一览 (5 条 mini 进度条, FlowContainer 换行)
var _collect_wrap: FlowContainer  # 打磨-43: 收集进度一览容器 (与 _collect_box 同一节点, 宽度不足时逐条换行不截断)
var _collect_items: Dictionary = {} # 打磨-42: 类别 -> {label, bar_bg, bar_fill, text, q} (text/q 变化才刷)
var _collect_text := ""            # 收集文本缓存 (变化时才刷, tooltip/断言用; 原单行 Label 已升级为 _collect_box)
var _collect_btns: Dictionary = {}  # 打磨-44: 类别 -> flat Button (收集进度行, 点击直达对应页)
var _collect_sb_normal: StyleBoxFlat # 打磨-44: 收集行按钮 normal (透明)
var _collect_sb_hover: StyleBoxFlat  # 打磨-44: 收集行按钮 hover (淡底+金边 可点提示)
var _items_panel: Panel              # 打磨-44: 修行页法器区面板 (透明, 收集进度点击直达时金边高亮)
var _items_hi_tween: Tween           # 打磨-44: 法器区高亮 tween (1.2s 自动恢复)
var _bonus_labels: Array[Label] = []  # 技能/装备页顶栏 总加成汇总标签 (打磨-9)
var _bonus_text := ""              # 汇总文本缓存 (变化时才刷)
var _shop_row_nodes: Dictionary = {} # 法器 id -> row (tooltip 状态刷新用)
var _shop_eta: Dictionary = {}     # 法器 id -> 购买 ETA 提示标签 (打磨-12)
var _equip_eta: Dictionary = {}    # 装备 id -> 购买 ETA 提示标签 (打磨-12)
var _equip_swap: Dictionary = {}   # 打磨-25: 装备 id -> 换装对比提示标签
var _eta_acc := 0.0                # 打磨-12: ETA 节流累计 (1 秒刷一次)
var _eta_ladder_acc := 0.0         # 打磨-33: 阶梯 ETA 节流累计 (1 秒刷一次)
var _realm_ladder: Array[Label] = []    # 打磨-18: 境界阶梯标签 (金框高亮随当前境界移动)
var _immortal_ladder: Array[Label] = [] # 打磨-18: 仙界道行阶梯标签
var _ladder_key := -1                # 打磨-18: 阶梯高亮缓存键 (境界/道行变化才刷)
var _ladder_eta: Dictionary = {}     # 打磨-33: "realm_N"/"dao_N" -> ETA 提示标签 (青色)
var _ladder_eta_key := ""            # 打磨-33: ETA 文本快照缓存 (变化才刷)
var _ladder_prog: Label              # 打磨-34: 当前境界行内层内进度标签 (金色, 飞升后隐藏)
var _ladder_prog_text := ""          # 打磨-34: 层内进度文本缓存 (变化才刷)
var _dao_prog: Label                 # 打磨-35: 当前道行阶段行内进度标签 (金色, 未飞升隐藏)
var _dao_prog_text := ""             # 打磨-35: 道行进度文本缓存 (变化才刷)
var _dao_prog_hide_idx := 0          # 打磨-35: 未飞升时道行进度标签的隐藏位置 (道行区末行)


func _ready() -> void:
	_card_sb_normal = _make_card_sb(false)
	_card_sb_hi = _make_card_sb(true)
	_btn_sb_normal = _make_btn_sb_normal()
	_btn_sb_gold = _make_btn_sb_gold()
	_build_ui()
	if GameData.offline_msg != "":
		_show_msg(GameData.offline_msg)
		# 打磨-66: 离线收益 启动金色浮动 (底部消息仍保留, 两者并存; 不足1分钟/无档 不弹)
		_offline_float()
	# 打磨-17: 启动时先取基线快照, 读档恢复的旧解锁不当作"新解锁"弹浮动
	_ach_prev = GameData.ach_done.duplicate()


func _process(_delta: float) -> void:
	_refresh()
	_flash_step()


# ---------- UI 构建 ----------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 14
	root.offset_right = -16
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# 顶栏
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	root.add_child(top)
	top.add_child(_label("修 仙 挂 机", 26, GOLD))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_realm_label = _label("", 19, CYAN)
	top.add_child(_realm_label)
	_essence_label = _label("灵气 0", 19, GOLD)
	top.add_child(_essence_label)
	_stones_label = _label("灵石 0", 19, WHITEISH)
	top.add_child(_stones_label)

	# Tab
	_tab = TabContainer.new()
	_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tab)
	var page1 := _make_page("修行")
	var page2 := _make_page("技能")
	var page3 := _make_page("装备")
	var page4 := _make_page("成就")
	_tab.add_child(page1)
	_tab.add_child(page2)
	_tab.add_child(page3)
	_tab.add_child(page4)

	_build_training_page(page1)
	_build_skill_page(page2)
	_build_equip_page(page3)
	_build_ach_page(page4)

	# 底部消息
	_msg_label = _label("", 18, GOLD)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_msg_label)

	# 突破浮动提示 (顶层, 居中上浮淡出)
	_float_label = _label("", 24, GOLD)
	_float_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_float_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_float_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_float_label.position = Vector2(0, -20)
	_float_label.modulate = Color(1, 1, 1, 0)
	_float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_float_label)

	# 打磨-17: 成就解锁浮动提示 (顶层, 居中略偏下, 金绿上浮淡出)
	_ach_float_label = _label("", 22, Color(0.65, 0.95, 0.6))
	_ach_float_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_ach_float_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_ach_float_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_ach_float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ach_float_label.position = Vector2(0, -70)
	_ach_float_label.modulate = Color(1, 1, 1, 0)
	_ach_float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ach_float_label)

	# 打磨-45: 一键系列浮动反馈 (居中绿色, 与 突破/成就 浮动同口径, 位置错开)
	_onekey_float_label = _label("", 22, Color(0.55, 0.95, 0.55))
	_onekey_float_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_onekey_float_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_onekey_float_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_onekey_float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_onekey_float_label.position = Vector2(0, -30)
	_onekey_float_label.modulate = Color(1, 1, 1, 0)
	_onekey_float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_onekey_float_label)

	# 打磨-57: 主动神通 冷却完毕转就绪 浮动提示 (居中绿色, 与 一键系列 同口径, 位置错开)
	_ready_float_label = _label("", 22, Color(0.55, 0.95, 0.55))
	_ready_float_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_ready_float_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_ready_float_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_ready_float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ready_float_label.position = Vector2(0, -48)
	_ready_float_label.modulate = Color(1, 1, 1, 0)
	_ready_float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ready_float_label)

	# 打磨-66: 离线收益 启动浮动提示 (居中金色, 位置最高不与其他浮动重叠; 仅启动时弹一次)
	_offline_float_label = _label("", 22, GOLD)
	_offline_float_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_offline_float_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_offline_float_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_offline_float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offline_float_label.position = Vector2(0, -84)
	_offline_float_label.modulate = Color(1, 1, 1, 0)
	_offline_float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_offline_float_label)

	# 打磨-69: 自动施展 浮动提示 (居中绿色, 与 一键系列 浮动 同口径/同位, 位置错开由 _ready_float 系列 承担)
	_auto_cast_float_label = _label("", 22, Color(0.5, 0.9, 0.5))
	_auto_cast_float_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_auto_cast_float_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_auto_cast_float_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_auto_cast_float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_auto_cast_float_label.position = Vector2(0, -26)
	_auto_cast_float_label.modulate = Color(1, 1, 1, 0)
	_auto_cast_float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_auto_cast_float_label)


func _make_page(title: String) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	p.add_theme_stylebox_override("panel", sb)
	p.name = title
	return p


func _build_training_page(page: Panel) -> void:
	var wrap := HBoxContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.offset_left = 10
	wrap.offset_top = 8
	wrap.offset_right = -10
	wrap.offset_bottom = -8
	wrap.add_theme_constant_override("separation", 16)
	page.add_child(wrap)

	# 左: 修行状态 + 法器
	var left := _add_panel(wrap)
	left.add_child(_label("修 行 状 态", 15, DIM))
	left.add_child(_sep())
	_qi_label = _label("灵气速率  0 /秒", 15, CYAN)
	left.add_child(_qi_label)
	_stone_rate_label = _label("灵石速率  0 /秒", 15, CYAN)
	left.add_child(_stone_rate_label)
	# 打磨-50: 灵石速率行内联 下一件可购 ETA (金色小字, 文本变化才刷; 买得起/全集齐 切换提示)
	_stone_next_label = _label("", 12, GOLD)
	left.add_child(_stone_next_label)
	_stone_next_label.tooltip_text = "距下一件可购(最便宜未拥有 装备/法器)所需灵石与预计时间, 复用顶栏灵石口径。灵石足够或已集齐时显示对应提示。"
	# 打磨-13: 离线/挂机收益可视化 (每小时离线可得资源)
	_offline_label = _label("", 14, DIM)
	left.add_child(_offline_label)
	_offline_label.tooltip_text = "离线收益 = 当前速率 x 离线效率 (基础50% + 功法/装备加成), 上限 8 小时。关闭游戏后继续积累, 重新进入时发放。\n飞升后离线主资源计入道行。"
	# 打磨-14: 修行统计 (累计时长/突破/道行精进/神通/法器/装备, 持久化)
	_stats_label = _label("", 13, DIM)
	left.add_child(_stats_label)
	_stats_label.tooltip_text = "修行统计自开荒起累计, 存档保存。\n突破: 境界层数成功次数 (含飞升)。\n道行精进: 飞升后道行阶段成功次数。"
	left.add_child(_sep())
	_progress_label = _label("突破进度  0%", 14, DIM)
	left.add_child(_progress_label)
	# 打磨-24: 突破/道行精进 ETA (按当前速率预计何时攒够突破资源)
	_break_eta_label = _label("", 13, DIM)
	left.add_child(_break_eta_label)
	_break_eta_label.tooltip_text = "按当前灵气(道行)速率估算攒够突破资源所需时间。挂机/神通/境界提升都会改变该时间, 攒够后自动消失。"
	# 打磨-36: 主突破/道行精进成功率 (与浮动提示/按钮口径对齐; 道祖封顶圆满)
	_chance_label = _label("", 13, DIM)
	left.add_child(_chance_label)
	# 打磨-37: 成功率行 tooltip 动态展示构成 (境界基础/功法/装备/钳制, 数值变化才刷)
	_chance_label.tooltip_text = GameData.primary_break_chance_tip()
	# 打磨-31: 下一目标提示 (玩家下一步该做什么: 目标名+缺口+预计时间)
	_goal_label = _label("", 14, GOLD)
	left.add_child(_goal_label)
	_goal_label.tooltip_text = "当前最优先的下一步: 攒够突破资源即点击突破; 飞升后改为道行精进。"
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.18, 0.19, 0.25)
	_bar_bg.custom_minimum_size = Vector2(0, 14)
	_bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_bar_bg)
	_bar_fill = ColorRect.new()
	_bar_fill.color = CYAN
	_bar_fill.position = Vector2.ZERO
	_bar_bg.add_child(_bar_fill)
	_break_btn = _make_button("尝试突破")
	_break_btn.pressed.connect(_on_break)
	left.add_child(_break_btn)
	# 打磨-67: 自动突破开关 (资源攒够自动尝试 突破/道行精进; 状态变化才刷按钮态)
	_auto_break_btn = _make_button("自动突破: 关")
	_auto_break_btn.toggle_mode = true
	_auto_break_btn.pressed.connect(_on_auto_break)
	_auto_break_btn.tooltip_text = "资源攒够 突破/道行精进 消耗时 自动尝试, 无需手动点按钮 (挂机时生效; 离线期间不触发, 离线只结算收益, 重新进入游戏后生效)。\n成功弹绿色浮动 / 飞升弹金色浮动 / 失败弹红色浮动 (与手动按钮同口径, 浮动文案追加 自动 标注), 每帧至多尝试一次, 失败不重烧 (资源攒够才再试)。\n开关 存档 持久化, 默认 关 (手动玩家不受影响); 道祖封顶 恒不触发。"
	left.add_child(_auto_break_btn)
	# 打磨-68: 自动购置开关 (灵石攒够 自动购买 法器/装备 + 自动最佳换装; 状态变化才刷按钮态)
	_auto_buy_btn = _make_button("自动购置: 关")
	_auto_buy_btn.toggle_mode = true
	_auto_buy_btn.pressed.connect(_on_auto_buy)
	_auto_buy_btn.tooltip_text = "灵石攒够 自动购买 未拥有 法器/装备 (与 一键购置/一键购买 同口径: 价格升序连买 买得起 的, 槽位空时自动穿戴), 并自动 换上 各部位 最佳 拥有件 (一键最佳 口径)。\n每帧至多一轮, 灵石花到买不起为止 (购买后最便宜件恒买不起, 无热循环); 购入时底部消息提示 件数与花费 (无屏幕浮动, 避免挂机刷屏)。\n开关 存档 持久化, 默认 关 (手动玩家不受影响); 离线期间不触发 (离线只结算收益, 重新进入游戏后生效)。"
	left.add_child(_auto_buy_btn)
	# 打磨-69: 自动施展开关 (主动神通 冷却完毕 自动 施展 爆发; 状态变化才刷按钮态)
	_auto_cast_btn = _make_button("自动施展: 关")
	_auto_cast_btn.toggle_mode = true
	_auto_cast_btn.pressed.connect(_on_auto_cast)
	_auto_cast_btn.tooltip_text = "已学 主动神通 冷却完毕 自动 施展 爆发 (与 一键施展 同口径: 一次释放所有 就绪 的 主动神通, 各神通 爆发=当前灵气速率 x 爆发秒数, 飞升后=道行; 施展后 各自 进冷却)。\n每帧至多一轮 (施展后 各神通 进冷却, 全冷却中 0 施展, 无热循环); 施展时屏幕中央绿色浮动 提示 数量与 爆发总量 (与 一键施展 浮动 同口径)。\n开关 存档 持久化, 默认 关 (手动玩家不受影响); 离线期间不触发 (离线只结算收益, 重新进入游戏后生效)。"
	left.add_child(_auto_cast_btn)
	left.add_child(_sep())
	# 法器标题 + 打磨-29: 一键购买 (价格升序连买买得起的法器)
	# 打磨-44: 法器区 包进透明 Panel, 收集进度"法器"点击直达时金边高亮 1.2s
	_items_panel = Panel.new()
	var ip_sb := StyleBoxFlat.new()
	ip_sb.bg_color = Color(0, 0, 0, 0)
	ip_sb.set_corner_radius_all(8)
	_items_panel.add_theme_stylebox_override("panel", ip_sb)
	_items_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_items_panel)
	var items_box := VBoxContainer.new()
	items_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	items_box.offset_left = 10
	items_box.offset_top = 8
	items_box.offset_right = -10
	items_box.offset_bottom = -8
	items_box.add_theme_constant_override("separation", 8)
	_items_panel.add_child(items_box)
	var item_head := HBoxContainer.new()
	item_head.add_theme_constant_override("separation", 8)
	items_box.add_child(item_head)
	var item_sp := Control.new()
	item_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_head.add_child(_label("法 器", 15, DIM))
	item_head.add_child(item_sp)
	_items_buy_btn = _make_button("一键购买")
	_items_buy_btn.pressed.connect(_on_items_buy_all)
	# 打磨-46: 统一口径 tooltip (动作顺序 / 筛选叠加 / 计数口径)
	_items_buy_btn.tooltip_text = "按 价格升序 (同价按数据序) 连续购买 当前灵石买得起 的 未拥有 法器, 灵石花到买不起为止; 购入后底部消息追加 共花灵石 与 距下一件 (最便宜未拥有) 缺口 (全拥有省略), 缺口>0 且灵石收入速率>0 时再追加 \"约 X 可购\" (无灵石收入省略)。\n不受筛选影响 (全局口径); 购入后法器加成直接生效; 浮动提示追加 灵气速率 +N/秒 变化量 (购买后速率-购买前速率)。\n按钮计数 = 当前灵石单件买得起的未拥有法器数 (连买以预算耗尽为准, 实购数可能略少)。"
	item_head.add_child(_items_buy_btn)
	# 打磨-13: 法器列表可滚动 (10 件避免低分辨率下超出屏幕)
	var shop_scroll := ScrollContainer.new()
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	items_box.add_child(shop_scroll)
	_shop_box = VBoxContainer.new()
	_shop_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_box.add_theme_constant_override("separation", 10)
	shop_scroll.add_child(_shop_box)
	for it in GameData.ITEMS:
		_add_shop_row(it)

	# 右: 境界阶梯 (打磨-10: 含仙界道行阶梯, 可滚动)
	var right := _add_panel(wrap)
	right.add_child(_label("境 界 阶 梯", 15, DIM))
	right.add_child(_sep())
	var rscroll := ScrollContainer.new()
	rscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rscroll)
	var rbox := VBoxContainer.new()
	rbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rbox.add_theme_constant_override("separation", 4)
	rscroll.add_child(rbox)
	for i in GameData.REALMS.size():
		var r: Dictionary = GameData.REALMS[i]
		var rl := _label("%s × %d 层  (灵气x%s)" % [r["name"], r["layers"], GameData.fmt(GameData.QI_MULT[i])], 14, WHITEISH)
		rbox.add_child(rl)
		_realm_ladder.append(rl)
		if i == 0:
			# 打磨-34: 当前境界行内 层内进度 (初始挂在第 0 行下, 随当前境界移动)
			_ladder_prog = _label("", 12, GOLD)
			_ladder_prog.tooltip_text = "当前境界的层内进度: 第 X/Y 层 与 下次突破所需灵气 (当前已攒)。\n飞升后隐藏。"
			rbox.add_child(_ladder_prog)
		# 打磨-33: 阶梯 ETA 路线 (按当前速率估算 累计耗时, 已达成/当前 行不显示)
		var r_eta := _label("", 12, CYAN)
		rbox.add_child(r_eta)
		_ladder_eta["realm_%d" % i] = r_eta
	# 仙界道行 (飞升后解锁, 每阶灵气 x2)
	rbox.add_child(_sep())
	rbox.add_child(_label("仙界道行 (飞升后解锁, 每阶灵气 x%d)" % int(GameData.IMMORTAL_STAGE_MULT), 13, DIM))
	for i in GameData.IMMORTAL_REALMS.size():
		var nm: String = GameData.IMMORTAL_REALMS[i]
		var il := _label("%s  (x%.0f)" % [nm, pow(2.0, float(i))], 14, WHITEISH)
		rbox.add_child(il)
		_immortal_ladder.append(il)
		var d_eta := _label("", 12, CYAN)
		rbox.add_child(d_eta)
		_ladder_eta["dao_%d" % i] = d_eta
	# 打磨-35: 当前道行阶段行内 道行精进进度 (初始挂在第 1 个道行 d_eta 下 index=23, 随道行阶段移动; 未飞升隐藏)
	_dao_prog = _label("", 12, GOLD)
	_dao_prog.tooltip_text = "当前道行阶段的精进进度: 下次精进所需道行 (当前已攒)。道祖封顶显示圆满。\n未飞升隐藏。"
	rbox.add_child(_dao_prog)
	_dao_prog_hide_idx = rbox.get_child_count() - 1   # 道行区末行 (未飞升时藏于此, 视觉最靠下)
	rbox.move_child(_dao_prog, 23)
	# 打磨-18: 阶梯高亮随当前境界/道行阶段动态移动 (初始刷一次; 内部连带刷新打磨-33 ETA)
	_refresh_ladder()
	var hint := _label("挂机自动积累灵气与灵石, 灵气攒够后点击突破。境界越高, 挂机越快。\n飞升后改修道行: 道行每阶灵气 x2, 直至道祖。\n阶梯下青色为按当前速率的累计预计耗时 (8天+ = 超过 7 天上限), 随境界/资源变化更新。", 13, DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.tooltip_text = "境界阶梯 ETA 说明: 按 当前灵气速率 估算从当前状态攒够 各境界/阶段 全部突破资源所需的 累计时间 (含当前已攒部分抵扣, 未计入突破失败重耗; 境界提升后速率加快, 实际只会更快)。超过 7 天显示 8天+。"
	rbox.add_child(hint)


func _add_shop_row(it: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.tooltip_text = GameData.item_detail(it["id"] as String)
	_shop_box.add_child(row)
	# 打磨-41: 行首品质色竖条 (法器无 tier 字段, 按价格档着色: <1k 凡灰 / <100k 玄蓝 / <1M 仙紫 / 以上 神金)
	_add_tier_bar(row, _item_tier_color(float(it["cost"])))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	info.add_child(_label(it["name"] as String, 15, WHITEISH))
	info.add_child(_label("%s · 灵气x%.1f" % [it["desc"], it["boost"]], 13, DIM))
	info.add_child(_label("灵石 %s" % GameData.fmt(it["cost"]), 13, GOLD))
	# 打磨-12: 购买 ETA 提示 (买不起时显示预计时间, 买得起时隐藏)
	var eta_l := _label("", 13, DIM)
	info.add_child(eta_l)
	_shop_eta[it["id"] as String] = eta_l
	var btn := _make_button("购买")
	btn.pressed.connect(_on_buy.bind(it["id"]))
	row.add_child(btn)
	_shop_rows[it["id"] as String] = btn
	_shop_row_nodes[it["id"] as String] = row


# ---------- 技能页 ----------

func _build_skill_page(page: Panel) -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_top = 8
	outer.offset_right = -10
	outer.offset_bottom = -8
	outer.add_theme_constant_override("separation", 8)
	page.add_child(outer)

	var filter_bar := HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 8)
	outer.add_child(filter_bar)
	var all_btn := _make_button("全部")
	all_btn.toggle_mode = true
	all_btn.pressed.connect(_on_filter.bind(""))
	filter_bar.add_child(all_btn)
	_filter_btns[""] = all_btn
	for cat in GameData.SKILL_CAT_CN:
		var b := _make_button(GameData.SKILL_CAT_CN[cat] as String)
		b.toggle_mode = true
		b.pressed.connect(_on_filter.bind(str(cat)))
		filter_bar.add_child(b)
		_filter_btns[cat] = b
	# 打磨-20: 品质筛选行 (凡品~仙品, 与类别筛选叠加生效)
	var tier_bar := HBoxContainer.new()
	tier_bar.add_theme_constant_override("separation", 8)
	outer.add_child(tier_bar)
	var t_all := _make_button("全部品质")
	t_all.toggle_mode = true
	t_all.pressed.connect(_on_tier_filter.bind(""))
	tier_bar.add_child(t_all)
	_tier_btns[""] = t_all
	for t in [0, 1, 2, 3, 4, 5]:
		var tb := _make_button(GameData.skill_tier_name(t))
		tb.toggle_mode = true
		tb.pressed.connect(_on_tier_filter.bind(str(t)))
		tier_bar.add_child(tb)
		_tier_btns[str(t)] = tb
	# 打磨-23: 一键领悟 (与当前 类别/品质 筛选叠加, 批量学习全部 可学 技能)
	var tier_sp := Control.new()
	tier_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tier_bar.add_child(tier_sp)
	_learn_all_btn = _make_button("一键领悟")
	_learn_all_btn.pressed.connect(_on_learn_all)
	# 打磨-46: 统一口径 tooltip (动作与条件 / 筛选叠加 / 计数口径)
	_learn_all_btn.tooltip_text = "批量领悟 当前境界/层数足够 的 未学 技能 (境界足够且未领悟); 浮动提示追加 灵气速率 +N/秒 变化量 (学习后速率-学习前速率, 0 变化省略)。\n与 类别/品质 筛选 AND 叠加生效 (只学筛选范围内的); 不消耗资源; 已领悟的不重复领悟。\n按钮计数 = 筛选范围内可执行技能数 (与实际执行数一致)。"
	tier_bar.add_child(_learn_all_btn)
	# 打磨-56: 一键神通 (只学 筛选范围内 未学+境界足够 的 主动神通, 与 一键领悟 同口径 仅 type 过滤不同)
	_active_learn_btn = _make_button("一键神通")
	_active_learn_btn.pressed.connect(_on_active_learn)
	# 打磨-46 口径 统一 tooltip (动作与条件 / 筛选叠加 / 计数口径)
	_active_learn_btn.tooltip_text = "批量领悟 当前境界/层数足够 的 未学 主动神通 (境界足够且未领悟); 浮动提示追加 灵气速率 +N/秒 变化量 (本按钮仅学主动神通, 不学被动, 0 变化省略)。\n与 类别/品质 筛选 AND 叠加生效 (只学筛选范围内的 主动神通); 不消耗资源; 已领悟的不重复领悟; 飞升后 主动神通 爆发口径 道行 不变, 亦可作 飞升后 补齐入口。\n按钮计数 = 筛选范围内可执行 主动神通数 (与实际执行数一致)。"
	tier_bar.add_child(_active_learn_btn)
	# 打磨-30: 一键施展 (释放所有 已学+冷却完毕 的主动神通)
	_active_all_btn = _make_button("一键施展")
	_active_all_btn.pressed.connect(_on_active_all)
	# 打磨-46: 统一口径 tooltip (动作与顺序 / 爆发口径 / 计数口径)
	_active_all_btn.tooltip_text = "一次释放所有 已领悟 且 冷却完毕 的主动神通, 各自爆发 (爆发获得 = 当前灵气速率 x 爆发秒数; 飞升后改为获得道行); 浮动提示追加 本批 爆发 获得 总量 \"爆发+N 灵气/道行\" (与 底部消息 爆发 总量 同口径)。\n施展后各自进入冷却; 未领悟或冷却中的不计入, 不受筛选影响 (全局口径)。\n按钮计数 = 当前可施展 (就绪) 的主动神通数。"
	tier_bar.add_child(_active_all_btn)
	# 打磨-38: 只看可学 开关 (与 类别/品质 筛选 AND 叠加: 过滤境界/层不足的未学技能, 已学恒显示在最前)
	_learnable_btn = _make_button("只看可学")
	_learnable_btn.toggle_mode = true
	_learnable_btn.pressed.connect(_on_learnable_filter)
	_learnable_btn.tooltip_text = "只显示 已领悟 与 当前境界可领悟 的技能 (与 类别/品质 筛选叠加生效); 已学技能始终显示在最前。"
	tier_bar.add_child(_learnable_btn)

	# 顶栏: 总加成汇总 (打磨-9)
	var bonus_l := _label(GameData.bonus_summary_text(), 14, GOLD)
	outer.add_child(bonus_l)
	_bonus_labels.append(bonus_l)
	_bonus_text = GameData.bonus_summary_text()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_skill_box = VBoxContainer.new()
	_skill_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_skill_box)
	for id in GameData.skill_ids:
		_add_skill_row(id)


func _add_skill_row(id: String) -> void:
	var s: Dictionary = GameData.skill_by_id[id]
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _card_sb_normal)
	row.tooltip_text = GameData.skill_detail(id)
	_skill_box.add_child(row)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	# 打磨-41: 行首品质色竖条 (4px, 颜色随数据 tier 固定, 构建一次)
	_add_tier_bar(hb, GameData.TIER_COLOR[int(s["tier"])])
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hb.add_child(info)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)
	name_row.add_child(_label(s["name"] as String, 15, GameData.TIER_COLOR[int(s["tier"])]))
	name_row.add_child(_label(s["tier_name"] as String, 13, DIM))
	var is_active := str(s["type"]) == "active"
	name_row.add_child(_label("[" + ("神通" if is_active else "功法") + "] " + str(s["category_name"]), 13, CYAN if is_active else DIM))
	info.add_child(_label(s["desc"] as String, 13, WHITEISH))
	info.add_child(_label("领悟条件: %s 第%d层" % [GameData.REALMS[int(s["unlock_realm"])]["name"], int(s["unlock_layer"])], 12, DIM))
	# 打磨-54: 主动神通 爆发预览 (金色小字; 未领悟隐藏, 已领悟显示 当前灵气速率 x 爆发秒数, 随速率/境界/飞升变化才刷)
	if is_active:
		var burst := _label("", 12, GOLD)
		burst.visible = false
		info.add_child(burst)
		_burst_previews[id] = burst
		_burst_previews_key[id] = ""
		# 打磨-58: 冷却进度条 (细 6px, 青色按 剩余/总冷却 填充; 冷却中显示, 归零隐藏;
		# 1 秒节流 + 2% 量化档 + 布局宽变化才刷, 防挂机每帧重绘)
		var cd_bg := ColorRect.new()
		cd_bg.color = Color(0.22, 0.24, 0.31)
		cd_bg.custom_minimum_size = Vector2(0, 6)
		cd_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cd_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd_bg.visible = false
		var cd_fill := ColorRect.new()
		cd_fill.color = CYAN
		cd_fill.position = Vector2.ZERO
		cd_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd_bg.add_child(cd_fill)
		info.add_child(cd_bg)
		_skill_cd_bars[id] = {"bg": cd_bg, "fill": cd_fill}
		_skill_cd_q[id] = ""

	var btn := _make_button("领悟")
	btn.custom_minimum_size = Vector2(76, 0)
	btn.pressed.connect(_on_skill_btn.bind(id, is_active))
	hb.add_child(btn)
	_skill_btns[id] = btn
	_skill_row_nodes[id] = row
	# 打磨-59: 按钮 默认样式 缓存 (微光结束恢复; 构建时取当前 normal/hover/pressed 样式, 此后不变)
	_skill_glow_restored[id] = [btn.get_theme_stylebox("normal"),
		btn.get_theme_stylebox("hover"), btn.get_theme_stylebox("pressed")]


func _on_filter(cat: String) -> void:
	_filter_active = cat
	for key in _filter_btns:
		var b: Button = _filter_btns[key]
		b.set_pressed_no_signal(cat == str(key))
	_apply_skill_filter()


# 打磨-20: 品质筛选 (与类别筛选叠加生效)
func _on_tier_filter(tier: String) -> void:
	_tier_active = tier
	for key in _tier_btns:
		var b: Button = _tier_btns[key]
		b.set_pressed_no_signal(tier == str(key))
	_apply_skill_filter()


# 打磨-38: "只看可学"开关 (与 类别/品质 筛选 AND 叠加)
func _on_learnable_filter() -> void:
	_learnable_on = _learnable_btn.button_pressed
	_apply_skill_filter()


# 打磨-20: 应用 类别×品质 叠加筛选 (显示/隐藏 + 排序 + 提示)
func _apply_skill_filter() -> void:
	# 排序: 已学在前, 其次按品质
	var order: Array = []
	for id in GameData.skill_ids:
		var s: Dictionary = GameData.skill_by_id[id]
		if _filter_active != "" and str(s["category"]) != _filter_active:
			continue
		if _tier_active != "" and int(s["tier"]) != int(_tier_active):
			continue
		# 打磨-38: "只看可学"叠加 — 已学恒显示, 未学须 境界/层 足够
		if _learnable_on and not GameData.skill_can_learn_display(id):
			continue
		order.append(id)
	order.sort_custom(_skill_sort)
	# 显示/隐藏
	for id in GameData.skill_ids:
		var row: Node = _skill_row_nodes[id]
		row.visible = order.has(id)
	# 重排: 按 order 顺序逐个移到末尾, 最终顺序即 order
	for idx in order.size():
		var row: Node = _skill_row_nodes[order[idx]]
		_skill_box.move_child(row, _skill_box.get_child_count() - 1)
	var msg := "筛选: "
	msg += (_filter_active if _filter_active != "" else "全部类别")
	if _tier_active != "":
		msg += " · " + GameData.skill_tier_name(int(_tier_active))
	else:
		msg += " · 全部品质"
	if _learnable_on:
		msg += " · 只看可学"
	_show_msg(msg)


func _skill_sort(a: String, b: String) -> bool:
	var sa: Dictionary = GameData.skill_by_id[a]
	var sb2: Dictionary = GameData.skill_by_id[b]
	var a_learned := int(GameData.learned.has(a))
	var b_learned := int(GameData.learned.has(b))
	# 打磨-54 顺带修: 原式 a_learned < b_learned 语义相反 (sort_custom 返回 true=a 在前),
	# 已学技能被排到列表底部, 与计划文档/注释 "已学在前" 不符; 现 已学在前
	if a_learned != b_learned:
		return a_learned > b_learned
	if int(sa["tier"]) != int(sb2["tier"]):
		return int(sa["tier"]) < int(sb2["tier"])
	return a < b


func _on_skill_btn(id: String, is_active: bool) -> void:
	if is_active:
		if not GameData.learned.has(id):
			# 打磨-55 顺带修: 原逻辑 is_active 只走 use_active_skill, 未领悟的神通点按钮
			# 恒返回 "尚未领悟" 且按钮被禁用, 境界达标的主动神通实际无法领悟; 现 未领悟先领悟
			_show_msg(GameData.learn_skill(id))
			return
		# 打磨-55: 单个神通 施展 成功时同步 屏幕中央绿色浮动 (与 打磨-45 一键系列 同 _onekey_float 口径);
		# 失败 (冷却中) 只走底部消息不弹浮动; skill_use 统计埋点口径不变 (仍在 use_active_skill 内)
		var snap_ess: float = GameData.essence
		var snap_dao: float = GameData.dao
		var msg: String = GameData.use_active_skill(id)
		_show_msg(msg)
		if msg.begins_with("施展") and (GameData.essence > snap_ess or GameData.dao > snap_dao):
			var name: String = str(GameData.skill_by_id.get(id, {}).get("name", ""))
			# 打磨-61: 浮动文案追加 本次 爆发 获得 总量 (前后快照差, 与 打磨-60 一键施展 同文案格式;
			# 飞升后口径=道行; 成功分支恒 gain>0, 无 0 变化分支)
			var gain := (GameData.essence - snap_ess) + (GameData.dao - snap_dao)
			var res := "灵气" if not GameData.ascended else "道行"
			_onekey_float("施展「%s」 (爆发+%s %s)" % [name, GameData.fmt(gain), res])
	else:
		_show_msg(GameData.learn_skill(id))


# 打磨-23: 一键领悟 (与当前 类别/品质 筛选叠加; 只学 未学+境界足够 的)
func _on_learn_all() -> void:
	var tier_i := int(_tier_active) if _tier_active != "" else -1
	# 打磨-53: 学习前 灵气速率 快照 (被动功法 qi_mult/all_mult 改变 功法装备段 1+Σ, 前后差作浮动反馈)
	var qi_before: float = GameData.qi_per_sec()
	var r: Dictionary = GameData.learn_all_available(_filter_active, tier_i)
	if int(r["count"]) > 0:
		var msg := "一键领悟 %d 个技能" % int(r["count"])
		msg += (", " + GameData.skill_tier_name(int(_tier_active))) if _tier_active != "" else ""
		_show_msg(msg)
		# 打磨-45: 变更>0 统一浮动反馈 (文案含数量)
		# 打磨-53: 浮动文案追加 灵气速率 变化量 (学习后速率-学习前速率, 0 变化省略; 与 打磨-51/52 法器/装备 同口径)
		var qi_delta: float = GameData.qi_per_sec() - qi_before
		var extra := (" (灵气速率 +%s/秒)" % GameData.fmt(qi_delta)) if qi_delta > 0.0 else ""
		_onekey_float("一键领悟 %d 个技能%s" % [int(r["count"]), extra])
	else:
		_show_msg("当前境界下没有可领悟的新技能 (或筛选范围内已全部领悟)")


# 打磨-56: 一键神通 (只学 筛选范围内 未学+境界足够 的 主动神通, 与 一键领悟 同口径 仅 type 过滤不同)
# 变更>0 时绿色浮动 "一键神通 N 个" (与 一键领悟 的 "一键领悟 N 个技能" 口径区分);
# 主动神通 无被动加成, 灵气速率 恒 0 变化, 浮动不追加 速率增量 (与 打磨-53 同口径 防御)
func _on_active_learn() -> void:
	var tier_i := int(_tier_active) if _tier_active != "" else -1
	var qi_before: float = GameData.qi_per_sec()
	var r: Dictionary = GameData.learn_all_active(_filter_active, tier_i)
	if int(r["count"]) > 0:
		var msg := "一键神通 %d 个主动神通" % int(r["count"])
		msg += (", " + GameData.skill_tier_name(int(_tier_active))) if _tier_active != "" else ""
		_show_msg(msg)
		# 打磨-45: 变更>0 统一浮动反馈 (文案含数量, 与 一键领悟/一键施展 区分)
		var qi_delta: float = GameData.qi_per_sec() - qi_before
		var extra := (" (灵气速率 +%s/秒)" % GameData.fmt(qi_delta)) if qi_delta > 0.0 else ""
		_onekey_float("一键神通 %d 个%s" % [int(r["count"]), extra])
	else:
		_show_msg("当前境界下没有可领悟的新主动神通 (或筛选范围内已全部领悟)")


# 打磨-29: 法器 一键购买 (价格升序连买买得起的, 与装备 一键购买 口径一致)
func _on_items_buy_all() -> void:
	var before := GameData.stones
	var qi_before: float = GameData.qi_per_sec()
	var r: Dictionary = GameData.buy_items_affordable()
	if int(r["count"]) > 0:
		# 打磨-47: 追加 共花灵石 + 距下一件 (最便宜未拥有) 缺口 (全拥有省略)
		var msg := "一键购置 %d 件法器, 共花 %s 灵石" % [int(r["count"]), GameData.fmt(before - GameData.stones)]
		msg += _next_gap_text(GameData.item_next_target())
		_show_msg(msg)
		# 打磨-51: 浮动文案追加 灵气速率 增加量 (购买后速率 - 购买前速率, 有购买恒 >0)
		var delta: float = GameData.qi_per_sec() - qi_before
		var extra := (" (灵气速率 +%s/秒)" % GameData.fmt(delta)) if delta > 0.0 else ""
		_onekey_float("一键购置 %d 件法器%s" % [int(r["count"]), extra])
	else:
		_show_msg("当前灵石买不起任何一件未拥有的法器")


# 打磨-30: 一键施展 (释放所有 就绪 的主动神通, 与 一键领悟/一键购买/一键最佳 系列口径一致)
# 打磨-60: 浮动文案追加 本批 爆发 获得 总量 (与 打磨-51/52/53 法器/装备/技能 一键 浮动 追加
# 灵气速率增量 口径对齐; 本按钮 爆发 直接 获得 资源, 增量 即 爆发总量; 飞升后 口径=道行;
# use_all_active 已返回 {count, burst}, GameData 无新接口)
func _on_active_all() -> void:
	var res := "灵气" if not GameData.ascended else "道行"
	var r: Dictionary = GameData.use_all_active()
	if int(r["count"]) > 0:
		_show_msg("一键施展 %d 个神通, 爆发%s %s" % [int(r["count"]), res, GameData.fmt(float(r["burst"]))])
		_onekey_float("一键施展 %d 个神通 (爆发+%s %s)" % [int(r["count"]), GameData.fmt(float(r["burst"])), res])
	else:
		_show_msg("没有可施展的主动神通 (未领悟或冷却中)")


# 打磨-23: 一键购买 (价格升序连买, 灵石花到买不起为止)
func _on_buy_all() -> void:
	var before := GameData.stones
	# 打磨-52: 购买前 灵气速率 快照 (功法装备段 1+Σ 随购买/自动穿戴变化, 前后差作浮动反馈)
	var qi_before: float = GameData.qi_per_sec()
	var r: Dictionary = GameData.buy_affordable()
	if int(r["count"]) > 0:
		# 打磨-47: 追加 共花灵石 + 距下一件 (最便宜未拥有) 缺口 (全拥有省略)
		var msg := "一键购买 %d 件装备, 共花 %s 灵石 (槽位空时已自动穿戴)" % [int(r["count"]), GameData.fmt(before - GameData.stones)]
		msg += _next_gap_text(GameData.equip_next_target())
		_show_msg(msg)
		# 打磨-52: 浮动文案追加 灵气速率 变化量 (购买后速率-购买前速率, 0 变化省略; 与 打磨-51 法器口径一致)
		var qi_delta: float = GameData.qi_per_sec() - qi_before
		var extra := (" (灵气速率 +%s/秒)" % GameData.fmt(qi_delta)) if qi_delta > 0.0 else ""
		_onekey_float("一键购买 %d 件装备%s" % [int(r["count"]), extra])
	else:
		_show_msg("当前灵石买不起任何一件未拥有的装备")


# 打磨-47: 下一购买目标缺口文案 — target 空 (全拥有) 或 缺口<=0 (买得起, 口径防御) 返回 ""
# 打磨-48: 缺口>0 且灵石速率>0 时追加 " 约 X 可购" (复用 GameData.next_target_eta_text 的 打磨-12 eta 口径);
# 无灵石收入时省略 ETA (避免 "约 无灵石收入可购" 误导), 仅保留缺口数量
func _next_gap_text(target: Dictionary) -> String:
	if target.is_empty():
		return ""
	var gap: float = float(target.get("shortfall", 0.0))
	if gap <= 0.0:
		return ""
	return " 距下一件「%s」还差 %s 灵石%s" % [str(target.get("name", "")), GameData.fmt(gap), GameData.next_target_eta_text(target)]


# 打磨-26: 一键最佳穿戴 (各槽位穿上拥有的最佳件)
func _on_equip_best() -> void:
	# 打磨-52: 换装前 灵气速率 快照 (换装改变 功法装备段 1+Σ, 前后差作浮动反馈)
	var qi_before: float = GameData.qi_per_sec()
	var r: Dictionary = GameData.equip_best()
	if int(r["count"]) > 0:
		_show_msg("最佳穿戴 %d 件 (各部位已换上最佳装备)" % int(r["count"]))
		# 打磨-52: 浮动文案追加 灵气速率 变化量 (换装后速率-换装前速率, 0 变化省略; 与 打磨-51 法器口径一致)
		var qi_delta: float = GameData.qi_per_sec() - qi_before
		var extra := (" (灵气速率 +%s/秒)" % GameData.fmt(qi_delta)) if qi_delta > 0.0 else ""
		_onekey_float("最佳穿戴 %d 件%s" % [int(r["count"]), extra])
	else:
		_show_msg("各部位已是最佳穿戴 (或尚无已拥有装备)")


# ---------- 装备页 ----------

func _build_equip_page(page: Panel) -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_top = 8
	outer.offset_right = -10
	outer.offset_bottom = -8
	outer.add_theme_constant_override("separation", 10)
	page.add_child(outer)

	# 已穿戴槽位
	var slot_bar := HBoxContainer.new()
	slot_bar.add_theme_constant_override("separation", 10)
	outer.add_child(slot_bar)
	for slot in GameData.SLOTS:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 4)
		slot_bar.add_child(cell)
		cell.add_child(_label(GameData.SLOT_CN[slot] as String, 14, DIM))
		var name_l := _label("(空)", 15, WHITEISH)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(name_l)
		_slot_labels[slot] = name_l
		var btn := _make_button("卸下")
		btn.pressed.connect(_on_unequip.bind(slot))
		cell.add_child(btn)

	# 部位筛选 (打磨-11: 140 件按部位过滤, 降低查找成本)
	var eq_filter_bar := HBoxContainer.new()
	eq_filter_bar.add_theme_constant_override("separation", 8)
	outer.add_child(eq_filter_bar)
	var eq_all := _make_button("全部")
	eq_all.toggle_mode = true
	eq_all.pressed.connect(_on_equip_filter.bind(""))
	eq_filter_bar.add_child(eq_all)
	_equip_filter_btns[""] = eq_all
	for slot in GameData.SLOTS:
		var eb := _make_button(GameData.SLOT_CN[slot] as String)
		eb.toggle_mode = true
		eb.pressed.connect(_on_equip_filter.bind(slot))
		eq_filter_bar.add_child(eb)
		_equip_filter_btns[slot] = eb
	# 打磨-21: 装备品质筛选行 (凡品~神品 7 档, 与部位筛选叠加生效)
	var eq_tier_bar := HBoxContainer.new()
	eq_tier_bar.add_theme_constant_override("separation", 8)
	outer.add_child(eq_tier_bar)
	var et_all := _make_button("全部品质")
	et_all.toggle_mode = true
	et_all.pressed.connect(_on_equip_tier_filter.bind(""))
	eq_tier_bar.add_child(et_all)
	_equip_tier_btns[""] = et_all
	for t in 7:
		var etb := _make_button(GameData.equip_tier_name(t))
		etb.toggle_mode = true
		etb.pressed.connect(_on_equip_tier_filter.bind(str(t)))
		eq_tier_bar.add_child(etb)
		_equip_tier_btns[str(t)] = etb
	# 打磨-23: 一键购买 (连续买下当前所有买得起的装备, 槽位空时自动穿戴)
	var eq_sp := Control.new()
	eq_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_tier_bar.add_child(eq_sp)
	_buy_all_btn = _make_button("一键购买")
	_buy_all_btn.pressed.connect(_on_buy_all)
	# 打磨-46: 统一口径 tooltip (动作顺序 / 自动穿戴规则 / 计数口径)
	_buy_all_btn.tooltip_text = "按 价格升序 (同价按数据序) 连续购买 当前灵石买得起 的 未拥有 装备, 灵石花到买不起为止; 购入后底部消息追加 共花灵石 与 距下一件 (最便宜未拥有) 缺口 (全拥有省略), 缺口>0 且灵石收入速率>0 时再追加 \"约 X 可购\" (无灵石收入省略), 浮动提示追加 灵气速率 +N/秒 变化量 (购买后速率-购买前速率, 0 变化省略)。\n不受 部位/品质 筛选影响 (全局口径); 该部位槽位为空时自动穿戴, 已有装备的槽位不替换 (换更好的用 一键最佳)。\n按钮计数 = 当前灵石单件买得起的未拥有装备数 (连买以预算耗尽为准, 实购数可能略少)。"
	eq_tier_bar.add_child(_buy_all_btn)
	# 打磨-26: 一键最佳穿戴 (各槽位穿上拥有的最佳件, 补 一键购买 只穿首件 的缺口)
	_equip_best_btn = _make_button("一键最佳")
	_equip_best_btn.pressed.connect(_on_equip_best)
	# 打磨-46: 统一口径 tooltip (最佳判定 / 作用范围 / 计数口径)
	_equip_best_btn.tooltip_text = "各部位自动换上 已拥有 的最佳装备: 主属性 (灵气% + 灵石%) > 突破率 > 离线效率 (id 兜底, 确定性); 浮动提示追加 灵气速率 +N/秒 变化量 (换装后速率-换装前速率, 0 变化省略)。\n仅变更 尚未最佳 的槽位; 无拥有件不受影响; 已最佳 = 0 变更 (幂等), 不受 部位/品质 筛选影响 (全局口径)。\n按钮计数 = 可换上更好拥有件的部位槽位数。"
	eq_tier_bar.add_child(_equip_best_btn)

	# 装备列表 (已拥有=穿戴, 未拥有=购买)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_equip_box = VBoxContainer.new()
	_equip_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_equip_box)
	for id in GameData.equip_ids:
		_add_equip_row(id)


func _add_equip_row(id: String) -> void:
	var e: Dictionary = GameData.equip_by_id[id]
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _card_sb_normal)
	row.tooltip_text = GameData.equip_detail(id)
	_equip_box.add_child(row)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	# 打磨-41: 行首品质色竖条 (4px, 颜色随数据 tier 固定, 构建一次)
	_add_tier_bar(hb, GameData.TIER_COLOR[int(e["tier"])])
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hb.add_child(info)
	info.add_child(_label("%s · %s" % [e["name"], e["slot_name"]], 15, GameData.TIER_COLOR[int(e["tier"])]))
	info.add_child(_label(e["desc"] as String, 13, WHITEISH))
	info.add_child(_label("灵石 %s" % GameData.fmt(float(e["cost"])), 13, GOLD))
	# 打磨-12: 购买 ETA 提示 (未拥有且买不起时显示预计时间)
	var eta_l := _label("", 13, DIM)
	info.add_child(eta_l)
	_equip_eta[id] = eta_l
	# 打磨-25: 换装对比提示 (穿上本件后该部位主属性变化; 穿戴/卸下状态变化才刷)
	var swap_l := _label("", 12, CYAN)
	info.add_child(swap_l)
	_equip_swap[id] = swap_l
	var btn := _make_button("购买")
	btn.custom_minimum_size = Vector2(76, 0)
	btn.pressed.connect(_on_equip_btn.bind(id))
	hb.add_child(btn)
	_equip_btns[id] = btn
	_equip_row_nodes[id] = row


# ---------- 成就页 ----------

func _build_ach_page(page: Panel) -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_top = 8
	outer.offset_right = -10
	outer.offset_bottom = -8
	outer.add_theme_constant_override("separation", 8)
	page.add_child(outer)

	# 顶栏: 进度统计 (打磨-40: 初始计数用真实总数, 旧文案 0/0 会误导)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	outer.add_child(head)
	_ach_count_label = _label("成就 0/%d" % GameData.ach_ids.size(), 16, GOLD)
	head.add_child(_ach_count_label)
	var hint := _label("达成条件即自动解锁, 悬停条目可查看详情", 13, DIM)
	head.add_child(hint)
	# 打磨-28→42→43: 收集进度一览 (技能/装备/法器/成就 全局收集目标; 5 条 mini 进度条横排, 满=金/未满=青)
	var head_sp := Control.new()
	head_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(head_sp)
	# 打磨-43: 5 条 (含 总计) 逐条装进 FlowContainer (真换行) — 顶栏宽度不足时逐条换行, 不截断
	_collect_wrap = FlowContainer.new()
	_collect_wrap.add_theme_constant_override("h_separation", 10)
	_collect_wrap.add_theme_constant_override("v_separation", 4)
	_collect_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collect_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_collect_wrap.tooltip_text = "全局收集进度: 领悟过的技能 / 购买过的装备 / 购置的法器 / 达成的成就。\n收集只增不减, 全数收集即为圆满。"
	head.add_child(_collect_wrap)
	_collect_box = _collect_wrap  # 打磨-42 旧名指向同一容器 (tooltip/断言兼容)
	# 打磨-44: 收集进度行升级为 flat Button (点击直达对应页; 悬停淡底+金边提示可点)
	_collect_sb_normal = StyleBoxFlat.new()
	_collect_sb_normal.bg_color = Color(0, 0, 0, 0)
	_collect_sb_hover = StyleBoxFlat.new()
	_collect_sb_hover.bg_color = Color(1, 1, 1, 0.06)
	_collect_sb_hover.border_color = GOLD
	_collect_sb_hover.set_border_width_all(1)
	_collect_sb_hover.set_corner_radius_all(6)
	_collect_sb_hover.content_margin_left = 2
	_collect_sb_hover.content_margin_right = 2
	_collect_sb_hover.content_margin_top = 1
	_collect_sb_hover.content_margin_bottom = 1
	for kv in [["skill", "技能"], ["equip", "装备"], ["item", "法器"], ["ach", "成就"]]:
		var ckey: String = kv[0]
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 5)
		crow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var cl := _label("", 14, CYAN)
		crow.add_child(cl)
		var cbar_bg := ColorRect.new()
		cbar_bg.color = Color(0.22, 0.24, 0.31)
		cbar_bg.custom_minimum_size = Vector2(72, 6)
		cbar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cbar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cbar_fill := ColorRect.new()
		cbar_fill.color = CYAN
		cbar_fill.position = Vector2.ZERO
		cbar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cbar_bg.add_child(cbar_fill)
		crow.add_child(cbar_bg)
		var cbtn := Button.new()
		cbtn.flat = true
		cbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cbtn.add_theme_stylebox_override("normal", _collect_sb_normal)
		cbtn.add_theme_stylebox_override("hover", _collect_sb_hover)
		cbtn.add_theme_stylebox_override("pressed", _collect_sb_hover)
		cbtn.add_theme_stylebox_override("focus", _collect_sb_hover)
		cbtn.toggle_mode = false
		cbtn.pressed.connect(_on_collect_jump.bind(ckey))
		var ctip: String = {
			"skill": "点击直达 技能页", "equip": "点击直达 装备页",
			"item": "点击直达 修行页·法器区", "ach": "已在 成就页, 点击无动作",
		}[ckey]
		cbtn.tooltip_text = ctip
		cbtn.add_child(crow)
		_collect_wrap.add_child(cbtn)
		_collect_items[ckey] = {"label": cl, "bar_bg": cbar_bg, "bar_fill": cbar_fill, "text": "", "q": -1, "btn": cbtn, "row": crow}
		_collect_btns[ckey] = cbtn
	# 打磨-43: 第 5 条 总计 mini 进度条 (打磨-28 旧文字 "(总 N/287)" 的展示位回归; 口径=四类已收集之和/总量之和)
	# 打磨-44: 总计行同样 flat Button (点击弹口径提示, 不切页)
	var tt := _label("", 14, CYAN)
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 5)
	trow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(tt)
	var tbg := ColorRect.new()
	tbg.color = Color(0.22, 0.24, 0.31)
	tbg.custom_minimum_size = Vector2(72, 6)
	tbg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tfill := ColorRect.new()
	tfill.color = CYAN
	tfill.position = Vector2.ZERO
	tfill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tbg.add_child(tfill)
	trow.add_child(tbg)
	var tbtn := Button.new()
	tbtn.flat = true
	tbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tbtn.add_theme_stylebox_override("normal", _collect_sb_normal)
	tbtn.add_theme_stylebox_override("hover", _collect_sb_hover)
	tbtn.add_theme_stylebox_override("pressed", _collect_sb_hover)
	tbtn.add_theme_stylebox_override("focus", _collect_sb_hover)
	tbtn.pressed.connect(_on_collect_jump.bind("total"))
	tbtn.tooltip_text = "总计 = 四类已收集之和 / 四类总量之和 (技能+装备+法器+成就, 各条目只收集一次)"
	tbtn.add_child(trow)
	_collect_wrap.add_child(tbtn)
	_collect_items["total"] = {"label": tt, "bar_bg": tbg, "bar_fill": tfill, "text": "", "q": -1, "btn": tbtn, "row": trow}
	_collect_btns["total"] = tbtn

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_ach_box = VBoxContainer.new()
	_ach_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ach_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_ach_box)
	for id in GameData.ach_ids:
		_add_ach_row(id)


func _add_ach_row(id: String) -> void:
	var a: Dictionary = GameData.ach_by_id[id]
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _card_sb_normal)
	_ach_box.add_child(row)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hb.add_child(info)
	var name_l := _label("☆ " + (a["name"] as String), 15, DIM)
	info.add_child(name_l)
	var desc_l := _label(a["desc"] as String, 13, WHITEISH)
	info.add_child(desc_l)
	# 进度标签 + 解锁提示 (解锁时换色/换文案, 变化时才刷)
	var prog_l := _label(GameData.ach_progress(id), 13, DIM)
	info.add_child(prog_l)
	# 打磨-40: 进度条 (已解锁=满条金色 / 未解锁=青色按进度比例填充, 与按进度降序排序视觉呼应)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.22, 0.24, 0.31)
	bar_bg.custom_minimum_size = Vector2(0, 6)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_fill := ColorRect.new()
	bar_fill.color = CYAN
	bar_fill.position = Vector2.ZERO
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.add_child(bar_fill)
	info.add_child(bar_bg)
	# tooltip: 名称/条件/进度 (进度行随刷新路径 _ach_bar_refresh 更新)
	row.tooltip_text = "成就「%s」\n条件: %s\n进度: 0%%" % [a["name"], a["desc"]]
	_ach_rows[id] = {
		"row": row, "name_l": name_l, "desc_l": desc_l, "prog_l": prog_l,
		"bar_bg": bar_bg, "bar_fill": bar_fill,
	}


# ---------- 每帧刷新 ----------

func _refresh() -> void:
	var g := GameData
	var realm_mult := g.qi_mult_realm()
	_realm_label.text = "境界: %s · 灵气x%s" % [g.realm_display(), g.fmt(realm_mult)]
	# tooltip: 倍率构成 (境界基础含道行 / 功法装备 / 法器 / 道行), 仅在数值变化时刷新
	var tip := "境界灵气倍率 x%s  |  功法/装备 x%.2f  |  法器 x%.1f  |  道行 x%.0f  |  当前速率 %s/秒" % [
		g.fmt(realm_mult), g.qi_mult_skill_equip(), g.item_boost(), g.immortal_mult(), g.fmt(g.qi_per_sec())]
	if tip != _realm_tip:
		_realm_tip = tip
		_realm_label.tooltip_text = tip
	_essence_label.text = g.primary_res_text()  # 打磨-19: 顶栏主资源 (未飞升=灵气 / 飞升后=道行)
	_stones_label.text = "灵石 %s" % g.fmt(g.stones)
	# 打磨-49: 顶栏灵石行 tooltip = 当前灵石速率 + 距下一件 (最便宜未拥有) 缺口与 ETA (变化才刷)
	var stone_tip: String = g.stone_next_target_tip()
	if stone_tip != _stone_tip:
		_stone_tip = stone_tip
		_stones_label.tooltip_text = stone_tip
	var rate_txt := g.fmt(g.qi_per_sec())
	_qi_label.text = ("道行速率  %s /秒" if g.ascended else "灵气速率  %s /秒") % rate_txt
	_stone_rate_label.text = "灵石速率  %s /秒" % g.fmt(g.stone_per_sec())
	# 打磨-50: 内联 下一件可购 ETA (缺口>0 显示缺口+ETA; 买得起/全集齐 切换提示, 文本变化才刷)
	var sn_t: String = g.stone_next_target_inline()
	if sn_t != _stone_next_text:
		_stone_next_text = sn_t
		_stone_next_label.text = sn_t
	# 打磨-13: 离线每小时收益 (文本变化时才刷)
	var off_t: String = g.offline_hourly_text()
	if off_t != _offline_text:
		_offline_text = off_t
		_offline_label.text = off_t
	# 打磨-14: 修行统计 (文本变化时才刷)
	var st_t: String = g.stats_text()
	if st_t != _stats_text:
		_stats_text = st_t
		_stats_label.text = st_t
	_progress_label.text = ("道行进度  %d%%" if g.ascended else "突破进度  %d%%") % int(g.breakthrough_progress())
	# 打磨-24: 突破/道行精进 ETA (每帧算一次, 文本变化才写)
	var bet_t: String = g.breakthrough_eta_text()
	if bet_t != _break_eta_text:
		_break_eta_text = bet_t
		_break_eta_label.text = bet_t
	# 打磨-36: 主突破/道行精进成功率 (境界/道行阶段/功法装备变化才变, 文本变化才写)
	var ch_t: String = g.primary_break_chance_text()
	if ch_t != _chance_text:
		_chance_text = ch_t
		_chance_label.text = ch_t
	# 打磨-37: 成功率构成 tooltip (境界/阶段/功法装备变化才变, 文本变化才写)
	var ch_tip: String = g.primary_break_chance_tip()
	if ch_tip != _chance_tip:
		_chance_tip = ch_tip
		_chance_label.tooltip_text = ch_tip
	# 打磨-31: 下一目标提示 (缺口/预计时间随挂机与突破变化, 文本变化才写)
	var goal_t: String = g.next_goal_text()
	if goal_t != _goal_text:
		_goal_text = goal_t
		_goal_label.text = goal_t
	_bar_fill.size = Vector2(_bar_bg.size.x * g.breakthrough_progress() / 100.0, _bar_bg.size.y)
	if g.ascended:
		if g.dao_level >= g.IMMORTAL_REALMS.size() - 1:
			_break_btn.text = "已至道祖 · 道法自然 ♪"
			_break_btn.disabled = true
		else:
			_break_btn.text = "修炼道行 · 耗 %s 道行 (成功率%0.0f%%)" % [g.fmt(g.dao_break_cost()), g.dao_break_chance() * 100.0]
			_break_btn.disabled = false
	else:
		_break_btn.text = "尝试突破 · 耗 %s 灵气 (成功率%0.0f%%)" % [g.fmt(g.breakthrough_cost()), g.breakthrough_chance() * 100.0]
		_break_btn.disabled = false
	# 打磨-67: 自动突破开关 按钮态 (开关状态 变化才刷; 读档恢复/外部改 同步)
	if g.auto_break != _auto_break_on:
		_auto_break_on = g.auto_break
		_auto_break_btn.set_pressed_no_signal(g.auto_break)
		_auto_break_btn.text = ("自动突破: 开" if g.auto_break else "自动突破: 关")
	# 打磨-68: 自动购置开关 按钮态 (开关状态 变化才刷; 读档恢复/外部改 同步)
	if g.auto_buy != _auto_buy_on:
		_auto_buy_on = g.auto_buy
		_auto_buy_btn.set_pressed_no_signal(g.auto_buy)
		_auto_buy_btn.text = ("自动购置: 开" if g.auto_buy else "自动购置: 关")
	# 打磨-68: 自动购置 变更事件 → 底部消息 (变更事件序号 变化 且 有文案 才提示一次, 无屏幕浮动)
	if g._auto_buy_seq != _auto_buy_msg_seq:
		_auto_buy_msg_seq = g._auto_buy_seq
		var ab_t: String = g.auto_buy_last_text()
		if ab_t != "":
			_show_msg(ab_t)
	# 打磨-69: 自动施展开关 按钮态 (开关状态 变化才刷; 读档恢复/外部改 同步)
	if g.auto_cast != _auto_cast_on:
		_auto_cast_on = g.auto_cast
		_auto_cast_btn.set_pressed_no_signal(g.auto_cast)
		_auto_cast_btn.text = ("自动施展: 开" if g.auto_cast else "自动施展: 关")
	# 打磨-69: 自动施展 变更事件 → 绿色浮动 (与 一键施展 浮动 同口径 数量+爆发总量, 0 施展 不增 事件 不弹)
	if g._auto_cast_seq != _auto_cast_msg_seq:
		_auto_cast_msg_seq = g._auto_cast_seq
		_auto_cast_float(g.auto_cast_last_text())
	# 打磨-32: 突破按钮"可突破"金边高亮 (资源攒够时引导点击, 状态变化才刷样式; 闪烁动画期间不干预)
	var ready_now: bool = g.breakthrough_ready()
	if ready_now != _break_ready:
		_break_ready = ready_now
		_apply_break_btn_style()
	# 法器
	for id in _shop_rows:
		var btn: Button = _shop_rows[id]
		var it: Dictionary = _find_item(id)
		if g.owned.has(id):
			btn.text = "已拥有"
			btn.disabled = true
		else:
			btn.text = "购买"
			btn.disabled = g.stones < it["cost"]
	# 技能
	for id in _skill_btns:
		var s: Dictionary = GameData.skill_by_id[id]
		var btn: Button = _skill_btns[id]
		if str(s["type"]) == "active":
			if not g.learned.has(id):
				btn.text = "未领悟"
				btn.disabled = true
			elif not g.active_ready(id):
				btn.text = "冷却%d秒" % g.active_cd_left(id)
				btn.disabled = true
			else:
				btn.text = "施展"
				btn.disabled = false
		else:
			if g.learned.has(id):
				btn.text = "已领悟"
				btn.disabled = true
			elif g.can_learn(id):
				btn.text = "领悟"
				btn.disabled = false
			else:
				btn.text = "未解锁"
				btn.disabled = true
	# 打磨-54: 主动神通 爆发预览 (未领悟隐藏; 已领悟显示 当前灵气速率 x 爆发秒数,
	# 标签文本变化才刷; tooltip 预览行按 已学|预览文本 键变化才重建 — 预览值只随
	# 离散状态 (领悟/购买/穿戴/突破/飞升) 变化, 挂机期间恒定, 无需节流;
	# 未领悟时 tooltip 预览行同样随速率变化刷新, 与 打磨-9 状态行互补)
	for id in _burst_previews:
		var l54: Label = _burst_previews[id]
		var t54: String = g.skill_burst_preview(id)
		if g.learned.has(id):
			if l54.text != t54 or not l54.visible:
				l54.text = t54
				l54.visible = true
		elif l54.visible:
			l54.visible = false
			l54.text = ""
		var key54 := "%d|%s" % [int(g.learned.has(id)), t54]
		if str(_burst_previews_key[id]) != key54:
			_burst_previews_key[id] = key54
			(_skill_row_nodes[id] as Node).tooltip_text = g.skill_detail(id)
	# 装备
	for id in _equip_btns:
		var e: Dictionary = GameData.equip_by_id[id]
		var btn: Button = _equip_btns[id]
		if not g.owned_eq.has(id):
			btn.text = "购买"
			btn.disabled = g.stones < float(e["cost"])
		else:
			var worn: bool = str(g.equipped.get(e["slot"], "")) == id
			btn.text = "已穿戴" if worn else "穿戴"
			btn.disabled = worn
	# 打磨-23: 批量按钮 (境界/灵石/已学数变化时才刷, 避免每帧写文本)
	# 打磨-27: 一键领悟按当前 类别/品质 筛选计可学数 (点击只学筛选内技能, 计数与执行口径一致)
	# 顺带修: 原 ternary ("一键领悟 x%d" if ... else ...) 返回未格式化字面量 x%d, 计数从未真正显示;
	# 现各按钮 计数文案 按 %d 格式化 可执行数 (与 打磨-56 断言口径一致)
	var tier_i27 := int(_tier_active) if _tier_active != "" else -1
	var ll_avail: int = g.learn_available_count(_filter_active, tier_i27)
	var ll_txt := ("一键领悟 x%d" % ll_avail) if ll_avail > 0 else "已无新技能"
	# 打磨-30: 一键施展 (可施展数变化才刷; 就绪数随冷却倒计时变化)
	var ar_avail: int = g.active_ready_count()
	var ar_txt := ("一键施展 x%d" % ar_avail) if ar_avail > 0 else "冷却中"
	if _active_all_btn.text != ar_txt:
		_active_all_btn.text = ar_txt
	var buy_n := 0
	for eid in g.equip_ids:
		var ee: Dictionary = g.equip_by_id[eid]
		if not g.owned_eq.has(eid) and g.stones >= float(ee["cost"]):
			buy_n += 1
	var ba_txt := ("一键购买 x%d" % buy_n) if buy_n > 0 else "灵石不足"
	if _learn_all_btn.text != ll_txt:
		_learn_all_btn.text = ll_txt
	# 打磨-56: 一键神通 (按当前 类别/品质 筛选 计 可学 主动神通数, 文本变化才刷, 与 一键领悟 同口径)
	var al_avail: int = g.active_learn_available_count(_filter_active, tier_i27)
	var al_txt := ("一键神通 x%d" % al_avail) if al_avail > 0 else "已无新神通"
	if _active_learn_btn.text != al_txt:
		_active_learn_btn.text = al_txt
	if _buy_all_btn.text != ba_txt:
		_buy_all_btn.text = ba_txt
	# 打磨-38: 只看可学 开关 (按钮按 当前 类别/品质 筛选 内 可显示数 计口径, 开关态变化才刷)
	var lb_avail: int = g.learnable_display_count(_filter_active, tier_i27)
	var lb_txt := "显示全部" if _learnable_on else (("只看可学 x%d" % lb_avail) if lb_avail > 0 else "无可学")
	if _learnable_btn.text != lb_txt:
		_learnable_btn.text = lb_txt
	# 打磨-26: 一键最佳穿戴 (可改进槽位数变化时才刷, 购买/穿戴/卸下/读档 触发重排时自然生效)
	var best_n: int = g.equip_best_pending()
	var eb_txt := ("一键最佳 x%d" % best_n) if best_n > 0 else "已最佳"
	if _equip_best_btn.text != eb_txt:
		_equip_best_btn.text = eb_txt
	# 打磨-29: 法器 一键购买 (可买数变化时才刷, 与 一键购买/一键最佳 按可执行数计 口径一致)
	var ib_avail: int = g.item_affordable_count()
	var ib_txt := ("一键购买 x%d" % ib_avail) if ib_avail > 0 else "灵石不足"
	if _items_buy_btn.text != ib_txt:
		_items_buy_btn.text = ib_txt
	# 槽位
	for slot in g.SLOTS:
		(_slot_labels[slot] as Label).text = g.equipped_name(slot)
	# 状态高亮: 已学技能 / 已穿戴装备 金色边框 (仅状态变化时应用, 避免每帧重刷)
	for id in _skill_row_nodes:
		_apply_card_hl(_skill_row_nodes[id], g.learned.has(id))
	for id in _equip_row_nodes:
		var e: Dictionary = g.equip_by_id[id]
		_apply_card_hl(_equip_row_nodes[id], str(g.equipped.get(str(e["slot"]), "")) == id)
	# 打磨-22: 装备列表按状态重排 (购买/穿戴/卸下 时状态快照变化才真正重排)
	_resort_equip()
	# 打磨-9: tooltip 状态行 (已领悟/已穿戴/已拥有 变化时才重建文本)
	for id in _skill_row_nodes:
		var row: Node = _skill_row_nodes[id]
		if int(row.get_meta("_dk", -1)) != int(g.learned.has(id)):
			row.set_meta("_dk", int(g.learned.has(id)))
			row.tooltip_text = g.skill_detail(id)
	for id in _equip_row_nodes:
		var e2: Dictionary = g.equip_by_id[id]
		var row2: Node = _equip_row_nodes[id]
		var st := 0
		if str(g.equipped.get(str(e2["slot"]), "")) == id:
			st = 2
		elif g.owned_eq.has(id):
			st = 1
		if int(row2.get_meta("_dk", -1)) != st:
			row2.set_meta("_dk", st)
			row2.tooltip_text = g.equip_detail(id)
	for id in _shop_row_nodes:
		var row3: Node = _shop_row_nodes[id]
		# 打磨-51: tooltip 含 当前贡献/购买后预览 (随 拥有状态+法器连乘+境界+功法装备+飞升 变化)
		# 0.1 档量化 + 1 秒节流 (与 打磨-33 速率档口径一致), 避免挂机每帧 10 行文本重建
		var boost_q51 := int(round(g.item_boost() * 10.0)) / 10.0
		var mult_q51 := int(round(g.qi_mult_skill_equip() * 100.0)) / 100.0
		var key51 := "%d|%d|%d|%d|%d|%.1f|%.2f" % [
			int(g.owned.has(id)), g.realm_idx, int(g.ascended), g.dao_level,
			g.learned.size(), boost_q51, mult_q51]
		if str(row3.get_meta("_dkey", "")) != key51:
			row3.set_meta("_dkey", key51)
			row3.tooltip_text = g.item_detail(id)
	# 打磨-25: 换装对比提示 (穿上本件后该部位 灵气/灵石 差值; 文本变化才写标签, 并同步行 tooltip)
	for id in _equip_swap:
		var t25: String = str(g.equip_swap_hint(str(id))["text"])
		var l25: Label = _equip_swap[id]
		if l25.text != t25:
			l25.text = t25
			(_equip_row_nodes[id] as Node).tooltip_text = g.equip_detail(str(id))
	# 打磨-9: 总加成汇总 (文本变化时才刷)
	var bt: String = g.bonus_summary_text()
	if bt != _bonus_text:
		_bonus_text = bt
		for l in _bonus_labels:
			l.text = bt
	# 成就: 计数 + 已解锁高亮/进度 (解锁数变化时刷样式, 进度文本仅文本变化时刷)
	var done_n: int = g.ach_done.size()
	if done_n != _ach_hl_seq:
		_ach_hl_seq = done_n
		_ach_count_label.text = "成就 %d/%d" % [done_n, g.ach_ids.size()]
		for id in _ach_rows:
			var r: Dictionary = _ach_rows[id]
			var hi: bool = g.ach_done.has(id)
			_apply_card_hl(r["row"], hi)
			var nl: Label = r["name_l"]
			nl.text = ("★ " if hi else "☆ ") + str(r["name_l"].text).trim_prefix("★ ").trim_prefix("☆ ")
			nl.add_theme_color_override("font_color", GOLD if hi else DIM)
			var pl: Label = r["prog_l"]
			pl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55) if hi else DIM)
			pl.text = g.ach_progress(id)
	for id in _ach_rows:
		var pl2: Label = _ach_rows[id]["prog_l"]
		var pt: String = g.ach_progress(id)
		if pl2.text != pt:
			pl2.text = pt
	# 打磨-40: 成就页进度条 (2% 量化 + 布局宽变化才刷, 防每帧重绘)
	for id in _ach_rows:
		_ach_bar_refresh(id)
	# 打磨-39: 成就页按解锁状态排序 (排序键变化才重排; 解锁/进度变化触发)
	_resort_ach()
	# 打磨-28→42: 收集进度一览 (4 条 mini 进度条; 每帧调用但 文本/布局宽 变化才写, 防每帧重绘)
	_collect_text = g.collect_summary_text()
	_refresh_collect()
	# 打磨-12: 购买 ETA (1 秒节流刷一次, 仅文本变化时写)
	_eta_acc += get_process_delta_time()
	if _eta_acc >= 1.0:
		_eta_acc = 0.0
		_refresh_eta()
	# 打磨-58: 神通冷却进度条 (1 秒节流 + 2% 量化档 + 布局宽变化才刷, 防挂机每帧重绘)
	_skill_cd_acc += get_process_delta_time()
	if _skill_cd_acc >= 1.0:
		_skill_cd_acc = 0.0
		_refresh_skill_cd_bars()
	# 打磨-18: 境界阶梯高亮随当前境界/道行阶段移动 (状态变化才刷)
	_refresh_ladder()
	# 打磨-33: 境界阶梯 ETA 路线 (1 秒节流, 文本变化才刷)
	_eta_ladder_acc += get_process_delta_time()
	if _eta_ladder_acc >= 1.0:
		_eta_ladder_acc = 0.0
		_refresh_ladder_eta(false)
	# 突破/道行精进闪烁: 事件序号变化时触发 (成功绿闪 / 失败红闪, 打磨-10)
	# 打磨-67: 浮动 同事件驱动 (手动/自动 突破 统一经 break_seq 弹 屏幕中央浮动, 手动按钮不再直调)
	if g.break_seq != _break_flash_seq:
		_break_flash_seq = g.break_seq
		_break_flash(int(g.last_break_result))
		_float_break()
	# 打磨-17: 成就解锁浮动提示 (与上一帧快照对比, 检测新解锁; 只增不减, 数量变化即快照)
	var fresh: Array = g.new_ach_since(_ach_prev)
	if not fresh.is_empty():
		_ach_float(fresh)
	if g.ach_done.size() != _ach_prev.size():
		_ach_prev = g.ach_done.duplicate()
	# 打磨-57: 主动神通 冷却完毕转就绪 浮动提示 (每帧消费 就绪事件; 同一批多个就绪合并一行,
	# 文案含神通名, 与 一键施展/单个施展 浮动 口径区分; 只读事件 不改动 状态/存档/统计)
	# 打磨-59: 就绪 同帧触发 进度条 收口动画 + 施展按钮 金边微光 (纯视觉, 复用同一事件)
	var ready_ids: Array[String] = g.drain_ready_events()
	if not ready_ids.is_empty():
		_skill_ready_seq += 1
		_ready_float(ready_ids)
		_skill_ready_flash(ready_ids)


# 打磨-57: 主动神通 冷却完毕转就绪 浮动提示 (居中绿色上浮淡出, 与 打磨-45 一键系列 同口径,
# 位置 y=-48 与 一键(-26)/成就(-58) 错开; 同一批多个就绪合并一行展示)
# 打磨-62: 浮动文案 追加 本批 就绪神通 的 爆发 总量 "(爆发+N 灵气/道行)" — 每个 id 按
# qi_per_sec x value 口径 求和 (与 打磨-54 爆发预览/打磨-60 一键施展 同口径, 飞升后=道行),
# 求和<=0 省略 (速率 0 等极端态防御); 只读 不改 状态/存档/统计
func _ready_float(fresh: Array[String]) -> void:
	var names := ""
	for id in fresh:
		var s: Dictionary = GameData.skill_by_id.get(str(id), {})
		if s.is_empty():
			continue
		names += ("\n" if names != "" else "") + (s["name"] as String)
	if names == "":
		return
	# 打磨-62: 本批 就绪神通 爆发 总量 (每 id = 当前灵气速率 x 爆发秒数, 与 打磨-54/60 同口径;
	# 飞升后 口径=道行 由 primary_res_name 统一; 速率 0 等极端态 求和<=0 省略)
	var burst := 0.0
	var rate := GameData.qi_per_sec()
	for id in fresh:
		var sk: Dictionary = GameData.skill_by_id.get(str(id), {})
		if sk.is_empty():
			continue
		burst += rate * float(sk["value"])
	var burst_tag := ""
	if burst > 0.0:
		burst_tag = " (爆发+%s %s)" % [GameData.fmt(burst), GameData.primary_res_name()]
	_ready_float_count += 1
	_ready_last_text = names
	_ready_float_label.text = "✦ 冷却完毕: " + names + " ✦" + burst_tag
	_ready_float_label.position = Vector2(0, -48)
	_ready_float_label.modulate = Color(1, 1, 1, 1)
	if _ready_float_tween != null and _ready_float_tween.is_valid():
		_ready_float_tween.kill()
	_ready_float_tween = create_tween()
	_ready_float_tween.tween_property(_ready_float_label, "position:y", -86.0, 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_ready_float_tween.parallel().tween_property(_ready_float_label, "modulate:a", 0.0, 1.6).set_delay(0.5)


# 打磨-17: 成就解锁浮动提示 (居中上浮淡出; 同一批多个解锁合并一行展示)
func _ach_float(fresh: Array) -> void:
	var names := ""
	for id in fresh:
		var a: Dictionary = GameData.ach_by_id.get(str(id), {})
		if a.is_empty():
			continue
		names += ("\n" if names != "" else "") + (a["name"] as String)
	if names == "":
		return
	_ach_float_count += 1
	_ach_float_label.text = "✦ 成就达成: " + names + " ✦"
	_ach_float_label.position = Vector2(0, -58)
	_ach_float_label.modulate = Color(1, 1, 1, 1)
	if _ach_float_tween != null and _ach_float_tween.is_valid():
		_ach_float_tween.kill()
	_ach_float_tween = create_tween()
	_ach_float_tween.tween_property(_ach_float_label, "position:y", -96.0, 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_ach_float_tween.parallel().tween_property(_ach_float_label, "modulate:a", 0.0, 1.6).set_delay(0.5)


# 打磨-45: 一键系列统一浮动反馈 — 批量变更 >0 时屏幕中央绿色浮动提示 (文案含数量),
# 底部 _show_msg 仍保留 (两者并存); 0 变更不弹 (走底部提示, 口径不变)
func _onekey_float(text: String) -> void:
	_onekey_float_count += 1
	_onekey_last_text = text
	_onekey_float_label.text = "✦ " + text + " ✦"
	_onekey_float_label.position = Vector2(0, -26)
	_onekey_float_label.modulate = Color(1, 1, 1, 1)
	if _onekey_float_tween != null and _onekey_float_tween.is_valid():
		_onekey_float_tween.kill()
	_onekey_float_tween = create_tween()
	_onekey_float_tween.tween_property(_onekey_float_label, "position:y", -64.0, 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_onekey_float_tween.parallel().tween_property(_onekey_float_label, "modulate:a", 0.0, 1.6).set_delay(0.5)


# 打磨-66: 离线收益 启动浮动 — 启动读档结算离线收益后, 屏幕中央金色浮动 (仅一次, 底部消息并存);
# 文案由 GameData.offline_float_text() 提供 (不足 1 分钟/无档 = 空串, 此时不弹)
func _offline_float() -> void:
	var text: String = GameData.offline_float_text()
	if text == "":
		return
	_offline_float_count += 1
	_offline_last_text = text
	_offline_float_label.text = text
	_offline_float_label.position = Vector2(0, -84)
	_offline_float_label.modulate = Color(1, 1, 1, 1)
	if _offline_float_tween != null and _offline_float_tween.is_valid():
		_offline_float_tween.kill()
	_offline_float_tween = create_tween()
	_offline_float_tween.tween_property(_offline_float_label, "position:y", -122.0, 1.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_offline_float_tween.parallel().tween_property(_offline_float_label, "modulate:a", 0.0, 1.8).set_delay(0.6)


# 打磨-69: 自动施展 浮动 — 自动 施展 就绪 神通 时 屏幕中央 绿色浮动 "✦ 自动施展 N 个神通 (爆发+X 灵气/道行) ✦"
# (与 打磨-45/60 一键施展 浮动 同口径: 绿色/居中/上浮淡出/数量+爆发总量; 位置 y=-26 与 一键系列 同位,
# 同一时间 手动 一键 与 自动 施展 不并发 [自动开关 由 挂机 驱动, 手动 由 点击 驱动]); 文案 由
# GameData.auto_cast_last_text() 提供 (seq<=0 空串 时 不弹); 计数 _auto_cast_float_count 与
# GameData._auto_cast_seq 同步 (启动=0 同态), 0 施展 不增 事件 不弹 浮动
func _auto_cast_float(text: String) -> void:
	if text == "":
		return
	_auto_cast_float_count += 1
	_auto_cast_last_text = text
	_auto_cast_float_label.text = "✦ " + text + " ✦"
	_auto_cast_float_label.position = Vector2(0, -26)
	_auto_cast_float_label.modulate = Color(1, 1, 1, 1)
	if _auto_cast_float_tween != null and _auto_cast_float_tween.is_valid():
		_auto_cast_float_tween.kill()
	_auto_cast_float_tween = create_tween()
	_auto_cast_float_tween.tween_property(_auto_cast_float_label, "position:y", -64.0, 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_auto_cast_float_tween.parallel().tween_property(_auto_cast_float_label, "modulate:a", 0.0, 1.6).set_delay(0.5)


func _apply_card_hl(row: PanelContainer, hi: bool) -> void:
	var last: bool = bool(row.get_meta("_hl", false))
	if last == hi:
		return
	row.set_meta("_hl", hi)
	row.add_theme_stylebox_override("panel", _card_sb_hi if hi else _card_sb_normal)


# 打磨-42→43: 刷收集进度一览 mini 进度条 (4 类 + 总计 横排: 类别名+计数 + 6px 进度条, 满=金/未满=青)
# 计数文本或 布局宽 变化才写 (缓存键 "宽|文本", 同打磨-40 口径), 防每帧重绘;
# 比例按 1% 量化档 (q=ceil(ratio*100)), 页面不可见时布局宽为 0 跳过填充, 切页后首帧补刷
# 打磨-43: total 条 = 四类已收集之和/四类总量之和 (与 collect_summary_text 的 "(总 N/287)" 口径一致)
func _refresh_collect() -> void:
	var g := GameData
	var cs: Dictionary = g.collect_summary()
	var names := {"skill": "技能", "equip": "装备", "item": "法器", "ach": "成就", "total": "总计"}
	var got_all := 0
	var tot_all := 0
	for k in cs:
		got_all += int(cs[k]["got"])
		tot_all += int(cs[k]["total"])
	var keys: Array = []
	for k in cs:
		keys.append(k)
	keys.append("total")
	for k in keys:
		if not _collect_items.has(k):
			continue
		var c: Dictionary
		if k == "total":
			c = {"got": got_all, "total": tot_all}
		else:
			c = cs[k]
		var it: Dictionary = _collect_items[k]
		var bg: ColorRect = it["bar_bg"]
		var fill: ColorRect = it["bar_fill"]
		var got: int = int(c["got"])
		var tot: int = int(c["total"])
		var rt: float = 0.0 if tot <= 0 else clampf(float(got) / float(tot), 0.0, 1.0)
		var q: int = int(ceil(rt * 100.0))
		var txt: String = "%s %d/%d" % [str(names.get(k, k)), got, tot]
		var key: String = "%d|%s" % [int(bg.size.x), txt]
		if str(it.get("q", "")) == key:
			continue
		it["q"] = key
		var full: bool = q >= 100
		(it["label"] as Label).text = txt
		(it["label"] as Label).add_theme_color_override("font_color", GOLD if full else CYAN)
		fill.color = GOLD if full else CYAN
		if int(bg.size.x) > 0:
			fill.size = Vector2(bg.size.x * float(q) / 100.0, bg.size.y)
		# 打磨-44: Button 非 Container, 子行 label/bar 的 min-size 不会上抛 -> FlowContainer 视为 0 宽不换行;
		# 文本变化时按 label+bar 重算按钮 min-size (真实渲染含字体度量, headless 字体 min=0 但布局仍成立)
		_collect_btn_min(k, it["label"] as Label, bg)


# 打磨-44: 按 行内 label+bar 的 min-size 同步收集按钮 min-size (让 FlowContainer 正确换行)
func _collect_btn_min(k: String, cl: Label, bg: ColorRect) -> void:
	var it: Dictionary = _collect_items[k]
	var b: Button = it.get("btn", null)
	if b == null:
		return
	var mw: float = cl.get_minimum_size().x + bg.custom_minimum_size.x + 8.0  # 8 ≈ 行间 separation
	var mh: float = maxf(cl.get_minimum_size().y, bg.custom_minimum_size.y) + 4.0
	b.custom_minimum_size = Vector2(mw, mh)


# 打磨-40: 刷单个成就行进度条 (已解锁=满条金色 / 未解锁=青色按 ach_progress_ratio 填充)
# 量化 2% 档 + 布局宽变化才写 (缓存键 "宽|档"), 避免每帧 17 条重绘; tooltip 进度行同步
func _ach_bar_refresh(id: Variant) -> void:
	var g := GameData
	var r40: Dictionary = _ach_rows[id]
	var bg40: ColorRect = r40["bar_bg"]
	var fill40: ColorRect = r40["bar_fill"]
	var hi40: bool = g.ach_done.has(str(id))
	var rv40: float = 1.0 if hi40 else g.ach_progress_ratio(str(id))
	var cl40: float = minf(maxf(rv40, 0.0), 1.0)
	var q40: int = int(ceil(cl40 * 50.0))
	var key40 := "%d|%d" % [int(bg40.size.x), q40]
	if str(_ach_bar_q.get(id, "")) == key40:
		return
	_ach_bar_q[id] = key40
	fill40.color = GOLD if hi40 else CYAN
	fill40.size = Vector2(bg40.size.x * float(q40) / 50.0, bg40.size.y)
	var a40: Dictionary = g.ach_by_id.get(str(id), {})
	var pct40: int = int(round(cl40 * 100.0))
	(r40["row"] as Node).tooltip_text = "成就「%s」\n条件: %s\n进度: %d%%" % [
		str(a40.get("name", "")), str(a40.get("desc", "")), pct40]


# 打磨-39: 成就页按解锁状态排序 (已解锁在前, 未解锁按进度降序; 排序键变化才重排, 避免每帧 17 行重排)
func _resort_ach() -> void:
	var order: Array = GameData.ach_sort_order()
	if _ach_states == order:
		return
	_ach_states = order
	for idx in order.size():
		var row: Node = _ach_rows[order[idx]]["row"]
		_ach_box.move_child(row, _ach_box.get_child_count() - 1)


# 打磨-12: 刷新法器/装备行的购买 ETA (买不起才显示预计时间, 买得起隐藏)
func _refresh_eta() -> void:
	var g := GameData
	for id in _shop_eta:
		var it: Dictionary = _find_item(str(id))
		if it.is_empty():
			continue
		var l: Label = _shop_eta[id]
		var t := "" if g.owned.has(str(id)) else g.eta_text(float(it["cost"]))
		if l.text != t:
			l.text = t
	for id in _equip_eta:
		var e: Dictionary = g.equip_by_id.get(id, {})
		if e.is_empty():
			continue
		var l2: Label = _equip_eta[id]
		var t2 := "" if g.owned_eq.has(id) else g.eta_text(float(e["cost"]))
		if l2.text != t2:
			l2.text = t2


# 打磨-58: 神通冷却进度条 (冷却中=青色按 剩余/总冷却 填充;
# 2% 量化档 + 布局宽变化才写, 防挂机每帧 24 行重绘; 只读 active_cd_ratio, 无副作用)
# 打磨-59: 冷却 归零 (就绪) 的条 由 收口动画 负责 终态 隐藏 (_skill_close_done),
# 本函数 对 就绪条 只 停止 填充 (continue), 不抢先 隐藏 (否则 收口动画 无 起点 可见 条)
func _refresh_skill_cd_bars() -> void:
	var g := GameData
	for id in _skill_cd_bars:
		if not g.learned.has(id):
			_hide_cd_bar(id)
			continue
		if g.active_cd_ratio(id) <= 0.0:
			# 就绪: 收口动画 负责 收窄+隐藏 (打磨-59); 条 已 隐藏 则 无需 处理
			continue
		var r58: Dictionary = _skill_cd_bars[id]
		var bg58: ColorRect = r58["bg"]
		var fill58: ColorRect = r58["fill"]
		if not bg58.visible:
			bg58.visible = true
		var q58: int = int(ceil(clampf(g.active_cd_ratio(id), 0.0, 1.0) * 50.0))
		var key58 := "%d|%d" % [int(bg58.size.x), q58]
		if str(_skill_cd_q.get(id, "")) == key58:
			continue
		_skill_cd_q[id] = key58
		fill58.color = CYAN
		fill58.size = Vector2(bg58.size.x * float(q58) / 50.0, bg58.size.y)


# 打磨-58/59: 隐藏 神通行 冷却条 (填充清零 + 缓存键 hidden, 终态一致)
func _hide_cd_bar(id: String) -> void:
	var r59: Dictionary = _skill_cd_bars.get(id, {})
	if r59.is_empty():
		return
	var bg59: ColorRect = r59["bg"]
	var fill59: ColorRect = r59["fill"]
	if bg59.visible:
		bg59.visible = false
		fill59.size = Vector2.ZERO
	_skill_cd_q[id] = "hidden"


# 打磨-59: 冷却完毕 收口动画 + 按钮金边微光 (复用 打磨-57 就绪事件, 与 就绪浮动 同帧触发;
# 进度条 由 当前填充 快速收窄至 0 (青色短促闪烁) 后隐藏, 与 打磨-58 归零隐藏 时序衔接;
# 施展按钮 短暂 金边微光 (复用 打磨-32 _btn_sb_gold 样式, 结束恢复 构建时缓存 默认样式);
# 纯视觉 无 状态/存档/统计 副作用; 收口 仅对 当前 条 仍 可见 (冷却中) 的 神通 触发,
# 已隐藏 的条 (如 未学/已就绪) 无 起点 填充 可 收, 跳过 (按钮微光 不受影响)
func _skill_ready_flash(fresh: Array[String]) -> void:
	for id in fresh:
		var sid: String = str(id)
		var btn: Button = _skill_btns.get(sid)
		if btn != null:
			_btn_glow59(sid, btn)
		# 收口: 仅当 该条 当前 仍 可见 (冷却中) 时 才有 起点 填充 可 收窄; 已 隐藏 的 跳过
		var r59: Dictionary = _skill_cd_bars.get(sid, {})
		if r59.is_empty():
			continue
		var bg59: ColorRect = r59["bg"]
		var fill59: ColorRect = r59["fill"]
		if not bg59.visible:
			continue
		var old: Tween = _skill_active_close.get(sid)
		if old != null and old.is_valid():
			old.kill()
		var tw: Tween = create_tween()
		_skill_active_close[sid] = tw
		tw.tween_property(fill59, "size:x", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(_skill_close_done.bind(sid))


# 打磨-59: 收口动画 结束 (隐藏条+填充清零+缓存键归 hidden, 与 打磨-58 归零隐藏 终态一致)
func _skill_close_done(id: String) -> void:
	_skill_active_close.erase(id)
	var r59: Dictionary = _skill_cd_bars.get(id, {})
	if r59.is_empty():
		return
	var bg59: ColorRect = r59["bg"]
	var fill59: ColorRect = r59["fill"]
	fill59.size = Vector2.ZERO
	bg59.visible = false
	_skill_cd_q[id] = "hidden"


# 打磨-59: 施展按钮 金边微光 (金边/金棕底 短暂驻留 后 透明度+底色 渐隐回默认,
# 与 打磨-32 突破按钮 金边同风格; 结束恢复 构建时缓存 默认样式, 不干扰 后续 _refresh)
func _btn_glow59(id: String, btn: Button) -> void:
	var old: Tween = _skill_active_glow.get(id)
	if old != null and old.is_valid():
		old.kill()
	var sb: StyleBoxFlat = _btn_sb_gold.duplicate()
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb.duplicate())
	btn.add_theme_stylebox_override("pressed", sb.duplicate())
	var tw: Tween = create_tween()
	_skill_active_glow[id] = tw
	tw.tween_property(sb, "border_color", Color(0.98, 0.86, 0.5, 0.0), 0.5)
	tw.parallel().tween_property(sb, "bg_color", Color(0.16, 0.17, 0.23), 0.5)
	tw.tween_callback(_skill_glow_done.bind(id))


# 打磨-59: 微光 结束 恢复 按钮 默认样式 (构建时缓存的 normal/hover/pressed)
func _skill_glow_done(id: String) -> void:
	_skill_active_glow.erase(id)
	var btn: Button = _skill_btns.get(id)
	if btn == null:
		return
	var def: Array = _skill_glow_restored.get(id, [])
	if def.size() == 3:
		btn.add_theme_stylebox_override("normal", def[0])
		btn.add_theme_stylebox_override("hover", def[1])
		btn.add_theme_stylebox_override("pressed", def[2])


# 打磨-18: 境界阶梯高亮 (当前境界 / 飞升后当前道行阶段 金色, 其余白字; 状态变化才刷)
func _refresh_ladder() -> void:
	var g := GameData
	var key := g.realm_idx * 100 + (1000 if g.ascended else 0) + (g.dao_level if g.ascended else 0)
	if key == _ladder_key:
		return
	_ladder_key = key
	for i in _realm_ladder.size():
		var hi := (not g.ascended) and i == g.realm_idx
		(_realm_ladder[i] as Label).add_theme_color_override("font_color", GOLD if hi else WHITEISH)
	for i in _immortal_ladder.size():
		var hi2 := g.ascended and i == g.dao_level
		(_immortal_ladder[i] as Label).add_theme_color_override("font_color", GOLD if hi2 else WHITEISH)
	# 打磨-34: 层内进度标签移动到当前境界行下 (飞升后隐藏, 挪到凡境末行)
	if g.ascended:
		var last := 2 * (_realm_ladder.size() - 1) + 1
		if _ladder_prog.text != "":
			_ladder_prog.text = ""
		if _ladder_prog.get_index() != last:
			_ladder_prog.get_parent().move_child(_ladder_prog, last)
	else:
		var want := 2 * g.realm_idx + 1
		if _ladder_prog.get_index() != want:
			_ladder_prog.get_parent().move_child(_ladder_prog, want)
	# 打磨-35: 道行进度标签移动到当前道行阶段行下 (未飞升隐藏, 挪到道行区末行)
	if g.ascended:
		var want_d: int = (_immortal_ladder[g.dao_level] as Label).get_index() + 1
		if _dao_prog.get_index() != want_d:
			_dao_prog.get_parent().move_child(_dao_prog, want_d)
	else:
		if _dao_prog.text != "":
			_dao_prog.text = ""
		if _dao_prog.get_index() != _dao_prog_hide_idx:
			_dao_prog.get_parent().move_child(_dao_prog, _dao_prog_hide_idx)
	# 打磨-33: 境界/阶段变化时 ETA 路线口径变了, 立即重算
	_refresh_ladder_eta(true)


# 打磨-33: 境界阶梯 ETA 路线 (按当前速率估算 各境界/道行阶段 累计耗时; 文本变化才刷)
# 已达成行显示"已达成" (青色), 当前行不显示 (金色高亮已表达), 未达成行显示"约 X" (超 7 天显示 8天+)
func _refresh_ladder_eta(force: bool = false) -> void:
	var g := GameData
	# 快照键: 境界/层/道行/飞升/速率档/资源档 (变化才重算, 避免每帧 19 行字符串生成)
	var qi_step := int(ceil(g.qi_per_sec() / 0.5))       # 速率 0.5 档量化 (防浮点抖动)
	var res_step := int(ceil(primary_progress_value() / 1.0))
	var key := "%d|%d|%d|%d|%d|%d" % [
		g.realm_idx, g.layer, g.dao_level, 1 if g.ascended else 0, qi_step, res_step]
	if not force and key == _ladder_eta_key:
		return
	_ladder_eta_key = key
	for i in _realm_ladder.size():
		var l: Label = _ladder_eta["realm_%d" % i]
		var t := ""
		if not g.ascended:
			if i < g.realm_idx:
				t = "已达成 ✓"
			elif i == g.realm_idx:
				t = ""
			else:
				t = g.ladder_row_eta("realm", i)
		else:
			t = "已达成 ✓"
		if l.text != t:
			l.text = t
	for i in _immortal_ladder.size():
		var l2: Label = _ladder_eta["dao_%d" % i]
		var t2 := ""
		if g.ascended:
			if i < g.dao_level:
				t2 = "已达成 ✓"
			elif i == g.dao_level:
				t2 = ""
			else:
				t2 = g.ladder_row_eta("dao", i)
		if l2.text != t2:
			l2.text = t2
	# 打磨-34: 当前境界行内 层内进度 (未飞升才显示; 文本变化才刷)
	var tp: String = g.ladder_current_progress_text()
	if _ladder_prog.text != tp:
		_ladder_prog.text = tp
		_ladder_prog_text = tp
	# 打磨-35: 当前道行阶段行内 道行精进进度 (飞升后才显示; 文本变化才刷)
	var td: String = g.dao_progress_text()
	if _dao_prog.text != td:
		_dao_prog.text = td
		_dao_prog_text = td


# 打磨-33: 当前主资源进度值 (ETA 快照键用; 未飞升=灵气, 飞升后=道行)
func primary_progress_value() -> float:
	return GameData.dao if GameData.ascended else GameData.essence


# 打磨-41: 行首品质色竖条 (4px, 构建后颜色不变, 无每帧刷新)
func _add_tier_bar(parent: Control, color: Color) -> void:
	var bar := ColorRect.new()
	bar.color = color
	bar.custom_minimum_size = Vector2(4, 18)
	bar.size_flags_vertical = Control.SIZE_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	parent.move_child(bar, 0)


# 打磨-41: 法器无品质字段, 按价格档近似着色 (与 TIER_COLOR 复用, 断言/文案口径一致)
func _item_tier_color(cost: float) -> Color:
	if cost < 1000.0:
		return GameData.TIER_COLOR[0]    # 凡灰
	if cost < 100000.0:
		return GameData.TIER_COLOR[2]   # 玄蓝
	if cost < 1000000.0:
		return GameData.TIER_COLOR[5]   # 仙紫
	return GameData.TIER_COLOR[6]       # 神金


func _make_card_sb(hi: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.19, 0.17, 0.12) if hi else CARD_BG
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.border_color = HILITE if hi else Color(0, 0, 0, 0)
	sb.set_border_width_all(2 if hi else 0)
	return sb


func _find_item(item_id: String) -> Dictionary:
	for it in GameData.ITEMS:
		if it["id"] == item_id:
			return it
	return {}


# ---------- 事件 ----------

func _on_break() -> void:
	# 飞升后同一按钮用于道行精进 (打磨-10)
	# 打磨-67: 浮动 改由 _refresh 的 break_seq 事件统一驱动 (手动/自动 同路径, 避免 双弹)
	var msg := GameData.try_dao_break() if GameData.ascended else GameData.try_breakthrough()
	_show_msg(msg)


# 打磨-67: 自动突破开关 — 点击切 开/关 (存档持久化, 由 GameData._process 驱动尝试);
# 底部消息确认口径 (开关不消耗资源/不计 突破 统计, 实际 尝试 由 _try_auto_break 走 真实 埋点 路径)
func _on_auto_break() -> void:
	GameData.auto_break = not GameData.auto_break
	_auto_break_on = GameData.auto_break
	_auto_break_btn.set_pressed_no_signal(GameData.auto_break)
	_auto_break_btn.text = ("自动突破: 开" if GameData.auto_break else "自动突破: 关")
	_show_msg("自动突破已开启, 资源攒够将自动突破 (可存档, 离线期间不触发)" if GameData.auto_break else "自动突破已关闭, 恢复手动点击突破")


# 打磨-68: 自动购置开关 — 点击切 开/关 (存档持久化, 由 GameData._process 驱动 自动 购入 法器/装备);
# 底部消息确认口径 (开关动作 本身 无 购买/统计 副作用, 实际 购入 由 _try_auto_buy 走 真实 埋点 路径)
func _on_auto_buy() -> void:
	GameData.auto_buy = not GameData.auto_buy
	_auto_buy_on = GameData.auto_buy
	_auto_buy_btn.set_pressed_no_signal(GameData.auto_buy)
	_auto_buy_btn.text = ("自动购置: 开" if GameData.auto_buy else "自动购置: 关")
	_show_msg("自动购置已开启, 灵石攒够将自动购买法器/装备 (可存档, 离线期间不触发)" if GameData.auto_buy else "自动购置已关闭, 恢复手动点击购买")


# 打磨-69: 自动施展开关 — 点击切 开/关 (存档持久化, 由 GameData._process 驱动 主动神通 自动 施展);
# 底部消息确认口径 (开关动作 本身 无 施展/统计 副作用, 实际 施展 由 _try_auto_cast 走 use_all_active 真实 埋点 路径)
func _on_auto_cast() -> void:
	GameData.auto_cast = not GameData.auto_cast
	_auto_cast_on = GameData.auto_cast
	_auto_cast_btn.set_pressed_no_signal(GameData.auto_cast)
	_auto_cast_btn.text = ("自动施展: 开" if GameData.auto_cast else "自动施展: 关")
	_show_msg("自动施展已开启, 主动神通冷却完毕将自动施展爆发 (可存档, 离线期间不触发)" if GameData.auto_cast else "自动施展已关闭, 恢复手动点击施展")


func _on_buy(item_id: String) -> void:
	_show_msg(GameData.try_buy_item(item_id))


func _on_equip_btn(id: String) -> void:
	var g := GameData
	if g.owned_eq.has(id):
		_show_msg(g.equip_equipment(id))
	else:
		_show_msg(g.buy_equipment(id))


func _on_unequip(slot: String) -> void:
	_show_msg(GameData.unequip(slot))


# 打磨-44: 收集进度一览 点击直达 — 技能→技能页 / 装备→装备页 / 法器→修行页法器区(金边高亮) /
# 总计→口径提示 (不切页); 纯导航操作, 无存档/统计副作用 (复用筛选接口, 口径与各自页一致)
func _on_collect_jump(ckey: String) -> void:
	match ckey:
		"skill":
			_tab.current_tab = 1
			_on_filter("")
			_on_tier_filter("")
			_show_msg("直达 技能页 (全部类别 · 全部品质)")
		"equip":
			_tab.current_tab = 2
			_on_equip_filter("")
			_on_equip_tier_filter("")
			_show_msg("直达 装备页 (全部部位 · 全部品质)")
		"item":
			_tab.current_tab = 0
			_flash_items_panel()
			_show_msg("直达 修行页·法器区")
		"ach":
			_tab.current_tab = 3
			_show_msg("已在 成就页")
		"total":
			_show_msg("总计 = 四类已收集之和 / 四类总量之和 (各条目只收集一次, 卸下/换装不影响)")


# 打磨-44: 法器区金边高亮 1.2s 后自动恢复 (tween 驱动, 重入时先 kill 旧 tween)
func _flash_items_panel() -> void:
	if _items_panel == null:
		return
	if _items_hi_tween != null and _items_hi_tween.is_valid():
		_items_hi_tween.kill()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	_items_panel.add_theme_stylebox_override("panel", sb)
	_items_hi_tween = create_tween()
	_items_hi_tween.tween_interval(1.2)
	_items_hi_tween.tween_callback(_restore_items_panel)


func _restore_items_panel() -> void:
	if _items_panel == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_corner_radius_all(8)
	_items_panel.add_theme_stylebox_override("panel", sb)


# 打磨-11: 装备部位筛选 (显示/隐藏对应行)
func _on_equip_filter(slot: String) -> void:
	_equip_filter_active = slot
	for key in _equip_filter_btns:
		var b: Button = _equip_filter_btns[key]
		b.set_pressed_no_signal(slot == str(key))
	_apply_equip_filter()


# 打磨-21: 装备品质筛选 (与部位筛选叠加生效)
func _on_equip_tier_filter(tier: String) -> void:
	_equip_tier_active = tier
	for key in _equip_tier_btns:
		var b: Button = _equip_tier_btns[key]
		b.set_pressed_no_signal(tier == str(key))
	_apply_equip_filter()


# 打磨-21: 应用 部位×品质 叠加筛选 (显示/隐藏 + 提示)
# 打磨-22: 顺带按状态重排 (已穿戴 > 已拥有 > 未拥有), 避免买到的装备沉在长列表底部
func _apply_equip_filter() -> void:
	_resort_equip()
	for id in _equip_row_nodes:
		var e: Dictionary = GameData.equip_by_id[id]
		var row: Node = _equip_row_nodes[id]
		row.visible = (_equip_filter_active == "" or str(e["slot"]) == _equip_filter_active) \
			and (_equip_tier_active == "" or int(e["tier"]) == int(_equip_tier_active))
	var msg := "装备筛选: " + (str(GameData.SLOT_CN[_equip_filter_active]) if _equip_filter_active != "" else "全部部位")
	msg += (" · " + GameData.equip_tier_name(int(_equip_tier_active)) if _equip_tier_active != "" else " · 全部品质")
	_show_msg(msg)


# 打磨-22: 状态快照变化时才重排 (购买/穿戴/卸下/读档触发, 避免每帧重排 140 行)
func _resort_equip() -> void:
	var cur: Array = []
	for id in GameData.equip_ids:
		cur.append(GameData.equip_state(id))
	if cur.size() != _eq_states.size() or _states_diff(cur):
		_eq_states = cur
		var order: Array = GameData.equip_sort_order()
		for idx in order.size():
			var row: Node = _equip_row_nodes[order[idx]]
			_equip_box.move_child(row, _equip_box.get_child_count() - 1)


func _states_diff(cur: Array) -> bool:
	for i in cur.size():
		if int(cur[i]) != int(_eq_states[i]):
			return true
	return false


func _show_msg(text: String) -> void:
	_msg_label.text = text
	_msg_label.modulate = Color.WHITE
	if _msg_tween != null and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_interval(4.0)
	_msg_tween.tween_property(_msg_label, "modulate", Color(1, 1, 1, 0), 1.5)


# 突破浮动提示: 屏幕中央上浮淡出, 成功绿/飞升金/失败红
func _float_break() -> void:
	if GameData.last_break_result == 0:
		return
	match GameData.last_break_result:
		1:
			# 打磨-65: 成功浮动 文案 由 GameData 接口生成 (含 新境界 + 当前成功率, 与 打磨-64 失败浮动 互补)
			_float_label.text = GameData.break_ok_float_text()
			_float_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55))
		2:
			# 打磨-64: 失败浮动 文案 由 GameData 接口生成 (复用 打磨-63 预期成本口径, 含 本次耗 + 期望次数/总消耗)
			_float_label.text = GameData.break_fail_float_text()
			_float_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		3:
			# 打磨-65: 飞升 浮动 (仙凡两隔, 无成功率口径, 与接口同口径)
			_float_label.text = GameData.break_ok_float_text()
			_float_label.add_theme_color_override("font_color", GOLD)
		4:
			# 打磨-65: 道行精进 成功 浮动 含 新阶段 + 当前成功率
			_float_label.text = GameData.break_ok_float_text()
			_float_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55))
		_:
			_float_label.text = "✖ 突破失败… ✖"
			_float_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	# 打磨-67: 自动突破触发时 文案追加 "(自动)" 标注 (与 手动 按钮 口径区分; 颜色/位置 不变)
	if GameData.auto_break:
		_float_label.text += " (自动)"
	_float_label.position = Vector2(0, 12)
	_float_label.modulate = Color(1, 1, 1, 1)
	if _float_tween != null and _float_tween.is_valid():
		_float_tween.kill()
	_float_tween = create_tween()
	_float_tween.tween_property(_float_label, "position:y", -36.0, 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.parallel().tween_property(_float_label, "modulate:a", 0.0, 1.6).set_delay(0.5)


# 打磨-32: 突破按钮样式切换 — 可突破时金边高亮, 否则默认样式 (闪烁动画期间由 _flash_step 接管)
func _apply_break_btn_style() -> void:
	if _break_btn == null:
		return
	if _flash_left > 0:
		return
	var sb := _btn_sb_gold if _break_ready else _btn_sb_normal
	_break_btn.add_theme_stylebox_override("normal", sb)
	_break_btn.add_theme_stylebox_override("hover", sb.duplicate() if _break_ready else _btn_sb_normal.duplicate())
	_break_btn.add_theme_stylebox_override("pressed", sb.duplicate() if _break_ready else _btn_sb_normal.duplicate())


# 突破按钮闪烁: 成功绿闪 / 失败红闪, 闪烁后恢复默认样式
func _break_flash(result: int) -> void:
	if _break_btn == null or _break_btn.disabled:
		return
	var col := Color(0.3, 0.9, 0.3) if (result == 1 or result == 4) else Color(1.0, 0.4, 0.35)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r * 0.22, col.g * 0.22, col.b * 0.22, 1.0)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_flash_sb = sb
	_flash_left = 16   # 每 4 帧切换一次, 共 16 帧 ≈ 0.55s
	_flash_step()


# 突破按钮闪烁步进 (每帧调用; 闪色 4 帧 / 恢复 4 帧 / 闪色 4 帧 / 恢复 8 帧)
func _flash_step() -> void:
	if _flash_left <= 0:
		return
	_flash_left -= 1
	var hi := (_flash_left % 8) < 4
	var sb := _flash_sb if hi else _btn_sb_normal
	_break_btn.add_theme_stylebox_override("normal", sb)
	_break_btn.add_theme_stylebox_override("hover", sb)
	_break_btn.add_theme_stylebox_override("pressed", sb)
	if _flash_left == 0:
		# 打磨-32: 闪烁结束后按当前"可突破"状态恢复 (金边/默认)
		_apply_break_btn_style()


# ---------- 小工具 ----------

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _sep() -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.25, 0.27, 0.34)
	c.custom_minimum_size = Vector2(0, 2)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _add_panel(parent: Control) -> VBoxContainer:
	var p := Panel.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(10)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.add_theme_constant_override("separation", 8)
	p.add_child(box)
	return box


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.7))
	b.add_theme_color_override("font_pressed_color", Color(1, 0.9, 0.5))
	b.add_theme_stylebox_override("normal", _btn_sb_normal)
	var sh := _btn_sb_normal.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.2, 0.22, 0.3)
	b.add_theme_stylebox_override("hover", sh)
	var spb := _btn_sb_normal.duplicate() as StyleBoxFlat
	spb.bg_color = Color(0.05, 0.06, 0.08)
	b.add_theme_stylebox_override("pressed", spb)
	return b


func _make_btn_sb_normal() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.16, 0.17, 0.23)
	s.border_color = Color(0.3, 0.35, 0.45)
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


# 打磨-32: 突破按钮"可突破"金边样式 (资源攒够时的醒目高亮)
func _make_btn_sb_gold() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.3, 0.24, 0.1)
	s.border_color = Color(0.98, 0.86, 0.5)
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
