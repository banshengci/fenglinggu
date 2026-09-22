extends "res://scripts/entities/interactable.gd"
class_name MuseumBuilding
## 谷之馆：捐赠与图鉴

func _ready() -> void:
	display_name = "谷之馆"
	color = Color("#D8C4A0")
	size = Vector2(40, 32)
	super._ready()

func interact(_player: Node) -> void:
	var counts := Inventory.get_counts()
	for id in counts:
		if MuseumDb.can_donate(str(id)):
			if MuseumDb.donate(str(id), 1):
				return
	EventBus.dialogue_started.emit([
		MuseumDb.catalog_text(),
		"把鱼获、古物或特别作物带来捐赠吧。",
		"捐赠 10 件可达成「博物之友」。",
	], "system")

func prompt() -> String:
	return "E：谷之馆 · 捐赠 %d 件" % MuseumDb.donate_count()
