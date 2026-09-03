extends Node
## Steam 接入骨架 (打磨-6, autoload: Steam)
## - app_id 配置: APP_ID (Steamworks 注册后替换; 占位值, 非真实应用)
## - SteamAPI 初始化骨架: 仅当 Windows 且存在 SteamAPI/CDNServer 单例时真正接入,
##   否则自动降级 (开发机 / headless 自测不阻塞、不崩溃)
## - 成就解锁判定与状态在 GameData (ach_done, 可存读档), 本节点只负责上报:
##   set_achieved(id) -> 已接入时调 SteamAPI.SetAchievement + StoreStats
## 上架前 (Windows 主机): 导出目录放置 steam_app.json + Steamworks SDK 的
## Steam.dll, 并替换 APP_ID。详见 README「Steam 上架准备」。

const APP_ID := 4828389999   # TODO: 替换为 Steamworks 后台申请的实际 app_id
const ACH_JSON := "res://data/achievements.json"

var steam_ok := false   # 是否真正接入 Steam 客户端 / SDK

func _ready() -> void:
	_load_ach_count()
	_init_steam()

# ---------- SteamAPI 初始化骨架 ----------

func _init_steam() -> void:
	if OS.get_name() != "Windows":
		steam_ok = false
		return
	if not Engine.has_singleton("SteamAPI") or not Engine.has_singleton("CDNServer"):
		steam_ok = false
		print("[Steam] 未检测到 SteamAPI/CDNServer 单例, 降级为本地成就记录")
		return
	var api: Object = Engine.get_singleton("SteamAPI")
	var err: int = int(api.call("RestartAppIfNecessary", APP_ID))
	if err != 0:
		steam_ok = false
		push_warning("[Steam] RestartAppIfNecessary 失败 err=%d, 降级为本地成就记录" % err)
		return
	steam_ok = true
	print("[Steam] 接入成功 (app_id=%d)" % APP_ID)

# ---------- 成就上报 ----------

func set_achieved(id: String) -> void:
	print("✦ 成就达成: " + id)
	if steam_ok:
		var api: Object = Engine.get_singleton("SteamAPI")
		api.call("SetAchievement", id)
		api.call("StoreStats")

# 成就定义由 GameData 统一读取 (单一数据源), 此处仅打印条目数确认数据可用
func _load_ach_count() -> void:
	var f := FileAccess.open(ACH_JSON, FileAccess.READ)
	if f == null:
		push_error("[Steam] 无法打开成就定义: " + ACH_JSON)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		print("[Steam] 成就定义 %d 条" % ((parsed as Dictionary).get("achievements", []) as Array).size())
