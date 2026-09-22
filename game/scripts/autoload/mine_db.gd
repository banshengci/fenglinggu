extends Node
## 矿洞数据库

const PATH := "res://data/mine.json"

var data: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_error("无法读取 mine.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func floors() -> Array:
	return data.get("floors", [])

func get_floor(index: int) -> Dictionary:
	var fs := floors()
	if index < 0 or index >= fs.size():
		return {}
	return fs[index]

func floor_count() -> int:
	return floors().size()

func get_enemy(type_id: String) -> Dictionary:
	return data.get("enemy_types", {}).get(type_id, {})

func chest_table() -> Array:
	return data.get("chest_table", [])

func roll_chest_drops() -> Dictionary:
	var table := chest_table()
	if table.is_empty():
		return {"stone": 2}
	var total := 0
	for row in table:
		total += int(row.get("weight", 1))
	var roll := randi() % maxi(total, 1)
	for row in table:
		roll -= int(row.get("weight", 1))
		if roll < 0:
			return row.get("drops", {}).duplicate()
	return table[0].get("drops", {}).duplicate()

func roll_ore(floor_index: int) -> String:
	var fl := get_floor(floor_index)
	var weights: Dictionary = fl.get("ore_weights", {"stone": 1})
	var total := 0
	for k in weights:
		total += int(weights[k])
	var roll := randi() % maxi(total, 1)
	for k in weights:
		roll -= int(weights[k])
		if roll < 0:
			return str(k)
	return "stone"
