extends Node
## 系统改进：背包筛选 · 闲日长 · 无障碍 · 云存档导出导入

const PREFS_PATH := "user://prefs.json"
const CLOUD_PATH := "user://cloud_save_export.json"

var bag_filter := "all"  # all|seed|crop|tool|resource|quest
var leisure_mode := false  # 闲日长：时间流速减半
var high_contrast := false
var ui_scale := 1.0
var reduce_motion := false

func _ready() -> void:
	load_prefs()
	apply_accessibility()

func to_dict() -> Dictionary:
	return {
		"bag_filter": bag_filter,
		"leisure_mode": leisure_mode,
		"high_contrast": high_contrast,
		"ui_scale": ui_scale,
		"reduce_motion": reduce_motion,
	}

func from_dict(d: Dictionary) -> void:
	bag_filter = str(d.get("bag_filter", "all"))
	leisure_mode = bool(d.get("leisure_mode", false))
	high_contrast = bool(d.get("high_contrast", false))
	ui_scale = clampf(float(d.get("ui_scale", 1.0)), 0.8, 1.5)
	reduce_motion = bool(d.get("reduce_motion", false))
	apply_accessibility()

func save_prefs() -> void:
	var f := FileAccess.open(PREFS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict(), "  "))

func load_prefs() -> void:
	var f := FileAccess.open(PREFS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		from_dict(parsed)

func apply_accessibility() -> void:
	var win := get_window()
	if win:
		win.content_scale_factor = ui_scale
	if high_contrast:
		DisplayServer.window_set_title("风铃谷 · 高对比")
	# reduce_motion 由各特效脚本读取 SysPrefs.reduce_motion

func set_filter(f: String) -> void:
	bag_filter = f
	save_prefs()
	get_tree().call_group("inventory_ui", "rebuild")

func toggle_leisure() -> void:
	leisure_mode = not leisure_mode
	save_prefs()
	EventBus.toast.emit("闲日长：%s" % ("开启（时间减慢）" if leisure_mode else "关闭"))

func time_scale() -> float:
	return 0.5 if leisure_mode else 1.0

func toggle_high_contrast() -> void:
	high_contrast = not high_contrast
	save_prefs()
	apply_accessibility()
	EventBus.toast.emit("高对比：%s" % ("开" if high_contrast else "关"))

func set_ui_scale(v: float) -> void:
	ui_scale = clampf(v, 0.8, 1.5)
	save_prefs()
	apply_accessibility()

func toggle_reduce_motion() -> void:
	reduce_motion = not reduce_motion
	save_prefs()
	EventBus.toast.emit("减少动效：%s" % ("开" if reduce_motion else "关"))

## 云存档：导出完整存档 JSON，便于网盘/跨设备
func export_cloud() -> bool:
	var payload := GameState.to_dict()
	payload["_meta"] = {"kind": "fenglinggu_cloud", "version": 2, "day": TimeSystem.day}
	var f := FileAccess.open(CLOUD_PATH, FileAccess.WRITE)
	if f == null:
		EventBus.toast.emit("导出失败：无法写入")
		return false
	f.store_string(JSON.stringify(payload, "  "))
	EventBus.toast.emit("已导出云存档到 user://cloud_save_export.json")
	EventBus.dialogue_started.emit([
		"云存档已打包。",
		"可把该文件拷到网盘或另一台设备后导入。",
	], "system")
	return true

func import_cloud() -> bool:
	var f := FileAccess.open(CLOUD_PATH, FileAccess.READ)
	if f == null:
		EventBus.toast.emit("未找到云存档文件")
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		EventBus.toast.emit("云存档格式无效")
		return false
	GameState.from_dict(parsed)
	EventBus.toast.emit("云存档已导入")
	EventBus.hud_refresh.emit()
	get_tree().call_group("area_manager", "travel_to", "town", 0, true)
	return true

func cloud_path_text() -> String:
	return CLOUD_PATH
