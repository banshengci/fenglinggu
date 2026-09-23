extends "res://scripts/entities/interactable.gd"
class_name WindShrine

@export var area_id := "town"

func _ready() -> void:
	display_name = "听风点"
	color = Color("#C8E0D0")
	size = Vector2(22, 22)
	super._ready()

func interact(_player: Node) -> void:
	WindDb.try_collect_area(area_id)
	EventBus.dialogue_started.emit([
		"你侧耳听风……",
		WindDb.catalog_text().split("\n")[0],
		"（凑齐旋律后可在风铃塔按 H 打开演奏）",
	], "system")

func prompt() -> String:
	return "E：聆听风的声音"

func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_circle(Vector2(0, -10), 7.0, Color("#E8C87A"))
	draw_line(Vector2(-8, -14), Vector2(8, -14), Color("#F3EAD3"), 2.0)
