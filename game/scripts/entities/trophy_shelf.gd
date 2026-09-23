extends "res://scripts/entities/interactable.gd"
class_name TrophyShelf
## 节令联赛奖杯架 + 本地榜

func _ready() -> void:
	display_name = "联赛奖杯架"
	color = Color("#E8D48A")
	size = Vector2(48, 36)
	super._ready()

func interact(_player: Node) -> void:
	var lines: Array = [
		SeasonLeague.trophy_shelf_text(),
		SeasonLeague.board_text(),
	]
	for e in SeasonLeague.EVENTS:
		var id := str(e.get("id", ""))
		var best := int(SeasonLeague.season_scores.get(id, 0))
		var cup := "★" if SeasonLeague.trophies.get(id, false) else "☆"
		lines.append("%s %s 最佳 %d" % [cup, str(e.get("name", id)), best])
	EventBus.dialogue_started.emit(lines, "system")

func prompt() -> String:
	return "E：%s" % display_name

func _draw() -> void:
	var r := Rect2(-size * 0.5, size)
	draw_rect(r, Color("#8B7355"))
	draw_rect(r, Color("#5C4A32"), false, 2.0)
	# 五个杯位
	for i in 5:
		var got: bool = SeasonLeague.trophies.get(str(SeasonLeague.TROPHY_IDS[i]), false) if i < SeasonLeague.TROPHY_IDS.size() else false
		var cx := -size.x * 0.5 + 6.0 + i * 9.0
		var c := Color("#E8D48A") if got else Color("#3A3A3A")
		draw_circle(Vector2(cx + 3, size.y * 0.45), 3.5, c)
