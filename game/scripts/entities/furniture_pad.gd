extends Node2D
class_name FurniturePad
## 家具摆放点：用背包家具点亮

var placed_id := ""

func _ready() -> void:
	add_to_group("save_serializable")
	queue_redraw()

func interact(_player: Node) -> void:
	if placed_id != "":
		EventBus.toast.emit("这里摆着：%s" % ItemDb.item_name(placed_id))
		return
	# 找背包里第一件 placeable
	var counts := Inventory.get_counts()
	for id in counts:
		var item := ItemDb.get_item(str(id))
		if bool(item.get("placeable", false)) or ItemDb.get_type(str(id)) == "furniture":
			Inventory.remove_item(str(id), 1)
			placed_id = str(id)
			Sfx.play("click")
			EventBus.toast.emit("摆好了：%s" % ItemDb.item_name(placed_id))
			MuseumDb.mark_bell_tone(placed_id)
			if placed_id == "tiny_bell":
				GameState.add_flag("tiny_bell_nearby", true)
				GameState.add_flag("tiny_bell_placed", true)
			queue_redraw()
			return
	EventBus.toast.emit("背包里没有可摆放的家具")

func prompt() -> String:
	if placed_id == "":
		return "E：摆放家具"
	return "E：%s" % ItemDb.item_name(placed_id)

func to_dict() -> Dictionary:
	return {"placed_id": placed_id}

func from_dict(d: Dictionary) -> void:
	placed_id = str(d.get("placed_id", ""))
	queue_redraw()

func on_save_collect() -> void:
	pass

func on_save_restore() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-14, -10, 28, 20), Color(0.2, 0.2, 0.2, 0.2))
	if placed_id != "":
		draw_rect(Rect2(-10, -12, 20, 16), ItemDb.get_color(placed_id))
		draw_circle(Vector2(0, -16), 5.0, ItemDb.get_color(placed_id).lightened(0.2))
