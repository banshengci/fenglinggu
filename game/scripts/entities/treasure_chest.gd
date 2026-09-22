extends "res://scripts/entities/interactable.gd"
class_name TreasureChest
## 宝箱

var opened := false

func _ready() -> void:
	display_name = "矿洞宝箱"
	color = Color("#D4A017")
	size = Vector2(26, 18)
	super._ready()

func interact(_player: Node) -> void:
	if opened:
		EventBus.toast.emit("箱子已经空了")
		return
	opened = true
	var drops := MineDb.roll_chest_drops()
	var parts: PackedStringArray = []
	for id in drops:
		var n: int = int(drops[id])
		if n <= 0:
			continue
		if Inventory.add_item(str(id), n):
			parts.append("%s×%d" % [ItemDb.item_name(str(id)), n])
			if str(id) == "wind_shard":
				GameState.wind_shards += 1
	if parts.is_empty():
		EventBus.toast.emit("箱子里只剩灰尘……")
	else:
		EventBus.toast.emit("宝箱：%s" % "，".join(parts))
	queue_redraw()

func prompt() -> String:
	return "E：打开宝箱" if not opened else "空宝箱"

func _draw() -> void:
	if opened:
		draw_rect(Rect2(-size * 0.5, size * Vector2(1, 0.4)), Color("#8B6914"))
		return
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_rect(Rect2(-size * 0.5, size), Color("#5C4308"), false, 2.0)
	draw_rect(Rect2(-3, -2, 6, 6), Color("#FFF2A8"))
