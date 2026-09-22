extends Node
## 集市周溢价

const PATH := "res://data/market.json"

var data: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func premium_items() -> Array:
	var day := TimeSystem.day
	var key := str((day - 1) % 7)
	var map: Dictionary = data.get("premium_weekdays", {})
	return map.get(key, [])

func multiplier() -> float:
	return float(data.get("premium_multiplier", 1.35))

func is_premium(id: String) -> bool:
	return id in premium_items()

func sell_price(id: String) -> int:
	var base := ItemDb.get_sell_price(id)
	if is_premium(id):
		base = int(round(base * multiplier()))
	if ItemDb.get_type(id) == "cooked":
		base = int(round(base * (1.0 + 0.05 * RanchWeather.skill_level("cooking"))))
	return base

func board_text() -> String:
	var items := premium_items()
	if items.is_empty():
		return "集市：今日无溢价品类"
	var names: PackedStringArray = []
	for id in items:
		names.append(ItemDb.item_name(str(id)))
	return "集市溢价 +%d%%：%s" % [int((multiplier() - 1.0) * 100.0), "、".join(names)]
