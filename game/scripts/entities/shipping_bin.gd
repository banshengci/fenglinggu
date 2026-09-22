extends "res://scripts/entities/interactable.gd"
class_name ShippingBin
## 出货箱：把背包里可出售物品全部或单个出货

func _ready() -> void:
	display_name = "出货箱"
	color = Color("#D4A017")
	size = Vector2(36, 24)
	super._ready()

func interact(_player: Node) -> void:
	EventBus.toast.emit(MarketDb.board_text())
	var sold_any := false
	var counts := Inventory.get_counts()
	for id in counts:
		if ItemDb.is_tool(id) or ItemDb.is_seed(id):
			continue
		var price := MarketDb.sell_price(id)
		if price <= 0:
			continue
		var n: int = counts[id]
		if Inventory.sell_item(id, n) > 0:
			sold_any = true
	if not sold_any:
		EventBus.toast.emit("出货箱：没有可出售的货物")

func prompt() -> String:
	return "E：出货箱（%s）" % MarketDb.board_text()
