extends "res://scripts/entities/interactable.gd"
class_name SeedShop
## 杂货购买

func _ready() -> void:
	display_name = "杂货摊"
	color = Color("#E8A050")
	size = Vector2(34, 24)
	super._ready()

func interact(_player: Node) -> void:
	get_tree().call_group("shop_ui", "open_shop")

func prompt() -> String:
	return "E：逛杂货摊（买种子与日用品）"
