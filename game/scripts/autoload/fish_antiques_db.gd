extends Node
## 鱼获与古物

const PATH := "res://data/fish_antiques.json"

var data: Dictionary = {}

func _ready() -> void:
	_load()
	_register_items()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func all_fish() -> Array:
	return data.get("fish", [])

func all_antiques() -> Array:
	return data.get("antiques", [])

func seasonal_fish(season: String) -> Array:
	var out: Array = []
	for f in all_fish():
		var ss: Array = f.get("seasons", [])
		if ss.is_empty() or season in ss:
			if not bool(f.get("rare", false)) or randf() < 0.2:
				out.append(f)
	return out

## 把表里条目并入 ItemDb 运行时字典，便于统一背包/出货
func _register_items() -> void:
	for f in all_fish():
		var id := str(f.get("id", ""))
		if id == "":
			continue
		if not ItemDb.items.has(id):
			ItemDb.items[id] = {
				"id": id,
				"name": str(f.get("name", id)),
				"type": "fish",
				"sell_price": int(f.get("sell_price", 10)),
				"color": str(f.get("color", "#AAA")),
				"desc": "钓鱼获得。",
			}
	for a in all_antiques():
		var aid := str(a.get("id", ""))
		if aid == "":
			continue
		if not ItemDb.items.has(aid):
			ItemDb.items[aid] = {
				"id": aid,
				"name": str(a.get("name", aid)),
				"type": "antique",
				"sell_price": int(a.get("sell_price", 10)),
				"color": str(a.get("color", "#AAA")),
				"desc": "从土里找到的旧物。",
			}
