extends "res://scripts/entities/interactable.gd"
class_name FurnitureSpot
## 可放置共鸣摆件的位置（灰盒：菜园旁共鸣台）

@export var place_item_id := "tiny_bell"

var placed := false
var placed_id := ""

func _ready() -> void:
	display_name = "共鸣台"
	color = Color("#B0A090")
	size = Vector2(24, 16)
	super._ready()

func interact(_player: Node) -> void:
	if placed:
		EventBus.dialogue_started.emit([
			"%s 在轻轻作响。" % ItemDb.item_name(placed_id),
			"附近的作物更容易结出闪光果。",
		], "system")
		return
	if Inventory.has_item(place_item_id, 1):
		Inventory.remove_item(place_item_id, 1)
		placed = true
		placed_id = place_item_id
		GameState.add_flag("tiny_bell_nearby", true)
		GameState.add_flag("tiny_bell_placed", true)
		Sfx.play("bell", 1.2, -8.0)
		EventBus.toast.emit("放置了 %s，菜园共鸣增强！" % ItemDb.item_name(place_item_id))
		queue_redraw()
	else:
		EventBus.dialogue_started.emit([
			"这里是共鸣台座。",
			"放入「%s」后，田园会更容易结出闪光果。" % ItemDb.item_name(place_item_id),
		], "system")

func prompt() -> String:
	if placed:
		return "E：倾听 %s" % ItemDb.item_name(placed_id)
	return "E：放置 %s" % ItemDb.item_name(place_item_id)

func on_save_restore() -> void:
	if GameState.get_flag("tiny_bell_placed", false):
		placed = true
		placed_id = place_item_id
		queue_redraw()

func to_dict() -> Dictionary:
	return {"placed": placed, "placed_id": placed_id}

func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), color)
	if placed:
		draw_circle(Vector2(0, -8), 6.0, Color("#E8C87A"))
		draw_line(Vector2(0, -2), Vector2(0, -8), Color("#8B6914"), 2.0)
