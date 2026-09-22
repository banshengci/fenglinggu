extends Node
## 物品数据库

const PATH := "res://data/items.json"

var items: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_error("无法读取 items.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		items = parsed

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func item_name(id: String) -> String:
	return str(get_item(id).get("name", id))

func get_color(id: String) -> Color:
	return Color.html(str(get_item(id).get("color", "#CCCCCC")))

func get_sell_price(id: String) -> int:
	return int(get_item(id).get("sell_price", 0))

func get_type(id: String) -> String:
	return str(get_item(id).get("type", ""))

func get_tool_action(id: String) -> String:
	return str(get_item(id).get("tool_action", ""))

func get_crop_id(id: String) -> String:
	return str(get_item(id).get("crop_id", ""))

func get_desc(id: String) -> String:
	return str(get_item(id).get("desc", ""))

func is_tool(id: String) -> bool:
	return get_type(id) == "tool"

func is_seed(id: String) -> bool:
	return get_type(id) == "seed"

func get_tool_tier(id: String) -> int:
	return int(get_item(id).get("tool_tier", 0))

func get_tool_power(id: String) -> int:
	return get_tool_tier(id) + 1

func get_tool_base(id: String) -> String:
	return str(get_item(id).get("tool_base", id))
