extends "res://scripts/entities/interactable.gd"
class_name FishSpot

func _ready() -> void:
	display_name = "钓鱼点"
	color = Color("#8FC0D8")
	size = Vector2(18, 12)
	super._ready()

func interact(_player: Node) -> void:
	var season := TimeSystem.season()
	var table := FishAntiques.seasonal_fish(season)
	if table.is_empty():
		table = FishAntiques.all_fish()
	if table.is_empty():
		EventBus.toast.emit("今天没有鱼咬钩")
		return
	var pick: Dictionary = table[randi() % table.size()]
	var fid := str(pick.get("id", "carp_spring"))
	get_tree().call_group("fish_ui", "play_round", fid)

func prompt() -> String:
	return "E：钓鱼"
