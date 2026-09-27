extends "res://scripts/entities/interactable.gd"
class_name MineRock
## 矿岩：镐子开采

@export var ore_id := "stone"
@export var hp := 2

var _hp := 2

func _ready() -> void:
	_hp = hp
	display_name = "矿岩（%s）" % ItemDb.item_name(ore_id)
	color = ItemDb.get_color(ore_id).darkened(0.15)
	size = Vector2(22, 22)
	super._ready()

func interact(_player: Node) -> void:
	# 只有镐子能采；空手提示
	hit(1)

func prompt() -> String:
	return "E/左键：开采（%s）" % ItemDb.item_name(ore_id)

func _art_tex() -> Texture2D:
	var t := ArtPipeline.ore_rock(ore_id)
	if t:
		return t
	return ArtPipeline.tex("prop_rock_pile")

func hit(damage: int = 1) -> void:
	var power := 1
	var ui := get_tree().get_first_node_in_group("inventory_ui")
	if ui and ui.has_method("selected_item_id"):
		var held: String = ui.selected_item_id()
		if held != "" and ItemDb.is_tool(held):
			power = ItemDb.get_tool_power(held)
	var bonus := 1 if RanchWeather.skill_level("mining") >= 3 and randf() < 0.25 else 0
	_hp -= damage + bonus + (power - 1)
	Sfx.play("chop", 0.85)
	QuestLog.mark("mine")
	Achievements.add_stat("mine_count", 1)
	RanchWeather.add_exp("mining", 1)
	queue_redraw()
	if _hp <= 0:
		var n := 1
		if ore_id != "stone" and randf() < 0.25 + 0.05 * (power - 1):
			n = 2
		if power >= 4 and randf() < 0.15:
			n += 1
		Inventory.add_item(ore_id, n)
		if ore_id == "wind_shard":
			GameState.wind_shards += 1
		if randf() < 0.12:
			Inventory.add_item("stone", 1)
		EventBus.toast.emit("开采：%s ×%d" % [ItemDb.item_name(ore_id), n])
		queue_free()

func _draw() -> void:
	var s := size.x * 0.5 + (2 - _hp) * 1.5
	var tex := ArtPipeline.tex("prop_mine_rock")
	if tex:
		draw_texture_rect(tex, Rect2(-s, -s, s * 2, s * 2), false)
	else:
		draw_circle(Vector2.ZERO, s, color)
		draw_rect(Rect2(-s, -s, s * 2, s * 2), color.darkened(0.3), false, 2.0)
	if _hp < hp:
		draw_line(Vector2(-4, -3), Vector2(4, 5), Color(0, 0, 0, 0.35), 1.5)
