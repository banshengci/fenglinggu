extends Node
## JSON 存档：3 手动槽 + 1 自动槽

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func slot_path(slot: int) -> String:
	return "%s/slot%d.json" % [SAVE_DIR, slot]

func auto_path() -> String:
	return "%s/auto.json" % SAVE_DIR

func save_game(slot: int = 0) -> bool:
	return _write(slot_path(slot))

func save_auto() -> bool:
	return _write(auto_path(), true)

func load_game(slot: int = 0) -> bool:
	return _read(slot_path(slot))

func load_auto() -> bool:
	return _read(auto_path())

func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func has_auto() -> bool:
	return FileAccess.file_exists(auto_path())

func slot_meta(slot: int) -> Dictionary:
	var p := slot_path(slot)
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return {}
	return {
		"saved_at": str(parsed.get("saved_at", "")),
		"day": int(parsed.get("time", {}).get("day", 0)),
		"player": str(parsed.get("game", {}).get("player_name", "")),
	}

func _write(path: String, is_auto := false) -> bool:
	get_tree().call_group("save_serializable", "on_save_collect")
	var data := {
		"version": 2,
		"time": TimeSystem.to_dict(),
		"inventory": Inventory.to_dict(),
		"game": GameState.to_dict(),
		"saved_at": Time.get_datetime_string_from_system(),
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		EventBus.toast.emit("存档失败：无法写入文件")
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	EventBus.toast.emit("已自动存档" if is_auto else "已存档")
	return true

func _read(path: String) -> bool:
	if not FileAccess.file_exists(path):
		EventBus.toast.emit("还没有存档")
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		EventBus.toast.emit("存档损坏")
		return false
	TimeSystem.from_dict(parsed.get("time", {}))
	Inventory.from_dict(parsed.get("inventory", {}))
	GameState.from_dict(parsed.get("game", {}))
	get_tree().call_group("save_serializable", "on_save_restore")
	EventBus.toast.emit("读档完成")
	EventBus.hud_refresh.emit()
	return true
