extends Node
## 杂货数据

const PATH := "res://data/shop.json"

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

func stock() -> Array:
	return data.get("stock", [])

func visible_stock(season: String) -> Array:
	var out: Array = []
	for row in stock():
		var seasons: Array = row.get("seasons", [])
		if seasons.is_empty() or season in seasons:
			out.append(row)
	return out

func buy(row: Dictionary) -> bool:
	var price := int(row.get("price", 0))
	var item := str(row.get("item", ""))
	if item == "" or price <= 0:
		return false
	if not Inventory.spend_money(price):
		return false
	if not Inventory.add_item(item, 1):
		Inventory.add_money(price)  # 退还
		return false
	EventBus.toast.emit("购入 %s（-%d 谷币）" % [ItemDb.item_name(item), price])
	return true
