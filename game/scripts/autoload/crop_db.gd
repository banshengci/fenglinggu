extends Node
## 作物数据库

const PATH := "res://data/crops.json"

var crops: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_error("无法读取 crops.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		crops = parsed

func get_crop(id: String) -> Dictionary:
	return crops.get(id, {})

func crop_name(id: String) -> String:
	return str(get_crop(id).get("name", id))

func get_days_to_grow(id: String) -> int:
	return int(get_crop(id).get("days_to_grow", 3))

func get_stages(id: String) -> int:
	return int(get_crop(id).get("stages", 4))

func get_seasons(id: String) -> Array:
	return get_crop(id).get("seasons", [])

func get_product_item(id: String) -> String:
	return str(get_crop(id).get("product_item", id))

func get_seed_item(id: String) -> String:
	return str(get_crop(id).get("seed_item", ""))

func get_regrow_days(id: String) -> int:
	return int(get_crop(id).get("regrow_days", 0))

func get_sprout_color(id: String) -> Color:
	return Color.html(str(get_crop(id).get("sprout_color", "#8FBC6B")))

func get_mature_color(id: String) -> Color:
	return Color.html(str(get_crop(id).get("mature_color", "#E8C87A")))

func can_plant_in_season(id: String, season: String) -> bool:
	var seasons := get_seasons(id)
	return seasons.is_empty() or season in seasons

func list_ids() -> Array:
	return crops.keys()
