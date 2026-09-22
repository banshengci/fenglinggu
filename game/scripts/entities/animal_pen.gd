extends "res://scripts/entities/interactable.gd"
class_name AnimalPen
## 牧场围栏：购买动物 / 收取产出

func _ready() -> void:
	display_name = "南坡牧场"
	color = Color("#A8C870")
	size = Vector2(36, 24)
	super._ready()

func interact(_player: Node) -> void:
	var n := RanchWeather.collect_animal_products()
	if n > 0:
		return
	var counts := int(RanchWeather.animals_owned.get("chicken", 0))
	if counts == 0:
		if RanchWeather.buy_animal("chicken"):
			EventBus.dialogue_started.emit(["第一只芦花鸡入住牧场！", "明天来收蛋吧。"], "system")
			return
	EventBus.dialogue_started.emit([
		"牧场静静的。",
		"已有动物：%s" % _roster_text(),
		"（可在杂货继续购入更多）",
	], "system")

func _roster_text() -> String:
	var parts: PackedStringArray = []
	for id in RanchWeather.animals_owned:
		var def: Dictionary = RanchWeather.animal_def(id)
		parts.append("%s×%d" % [str(def.get("name", id)), int(RanchWeather.animals_owned[id])])
	return "、".join(parts) if parts.size() > 0 else "（空）"

func prompt() -> String:
	return "E：牧场（收取产出/照料）"
