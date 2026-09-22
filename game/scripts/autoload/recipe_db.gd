extends Node
## 合成配方数据库

const PATH := "res://data/recipes.json"

var recipes: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_error("无法读取 recipes.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		recipes = parsed

func get_recipe(id: String) -> Dictionary:
	return recipes.get(id, {})

func list_for_station(station: String) -> Array:
	var out: Array = []
	for id in recipes:
		var r: Dictionary = recipes[id]
		if str(r.get("station", "")) == station:
			out.append(id)
	return out

func can_craft(id: String, inv: Dictionary) -> bool:
	var r := get_recipe(id)
	if r.is_empty():
		return false
	var inputs: Dictionary = r.get("inputs", {})
	for item_id in inputs:
		if int(inv.get(item_id, 0)) < int(inputs[item_id]):
			return false
	return true

func consume_inputs(id: String) -> void:
	var r := get_recipe(id)
	var inputs: Dictionary = r.get("inputs", {})
	for item_id in inputs:
		Inventory.remove_item(str(item_id), int(inputs[item_id]))

func get_output(id: String) -> String:
	return str(get_recipe(id).get("output", ""))

func get_output_count(id: String) -> int:
	return int(get_recipe(id).get("output_count", 1))
