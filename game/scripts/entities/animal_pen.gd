extends "res://scripts/entities/interactable.gd"
class_name AnimalPen

func _ready() -> void:
	display_name = "南坡牧场"
	color = Color("#A8C870")
	size = Vector2(36, 24)
	super._ready()

func interact(_player: Node) -> void:
	var n := RanchWeather.collect_animal_products()
	if n > 0:
		return
	if int(RanchWeather.animals_owned.get("chicken", 0)) == 0:
		if RanchWeather.buy_animal("chicken"):
			EventBus.dialogue_started.emit(["第一只芦花鸡入住牧场！", "明天来收蛋吧。"], "system")
			return
	EventBus.dialogue_started.emit(["牧场静静的。", _roster_text()], "system")

func _roster_text() -> String:
	var parts: PackedStringArray = []
	for id in RanchWeather.animals_owned:
		var def: Dictionary = RanchWeather.animal_def(id)
		parts.append("%s×%d" % [str(def.get("name", id)), int(RanchWeather.animals_owned[id])])
	return "、".join(parts) if parts.size() > 0 else "（空）"

func prompt() -> String:
	return "E：牧场（收取产出/照料）"

func _draw() -> void:
	var tex := ArtPipeline.tex("building_pasture")
	if tex:
		draw_texture_rect(tex, Rect2(-40, -30, 80, 50), false)
	else:
		draw_rect(Rect2(-size * 0.5, size), color)
	var i := 0
	for id in RanchWeather.animals_owned:
		var at := ArtPipeline.tex("animal_%s" % str(id))
		var p := Vector2(-30 + i * 20, -24)
		if at:
			draw_texture_rect(at, Rect2(p, Vector2(18, 18)), false)
		else:
			draw_circle(p + Vector2(9, 9), 7.0, Color("#E8D0B0"))
		i += 1
