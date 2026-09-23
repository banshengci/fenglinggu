extends "res://scripts/entities/interactable.gd"
class_name ResourceNode
## 采集点：木 / 石 / 纤维（跨天刷新）

@export var resource_id := "wood"
@export var yield_min := 1
@export var yield_max := 3
@export var regrow_days := 2

var available := true
var _cooldown := 0

func _ready() -> void:
	add_to_group("daily_tick")
	display_name = ItemDb.item_name(resource_id)
	color = ItemDb.get_color(resource_id)
	size = Vector2(18, 18)
	super._ready()

func on_new_day() -> void:
	if not available:
		_cooldown -= 1
		if _cooldown <= 0:
			available = true
			queue_redraw()

func interact(_player: Node) -> void:
	if not available:
		EventBus.toast.emit("还要再长一长……")
		return
	var n := randi_range(yield_min, yield_max)
	if randf() < 0.05 * RanchWeather.skill_level("foraging"):
		n += 1
	# 工具品阶加成：高阶工具小概率额外产出
	var power := 1
	var ui := get_tree().get_first_node_in_group("inventory_ui")
	if ui and ui.has_method("selected_item_id"):
		var held: String = ui.selected_item_id()
		if held != "" and ItemDb.is_tool(held):
			power = ItemDb.get_tool_power(held)
	if power > 1 and randf() < 0.12 * (power - 1):
		n += 1
	Inventory.add_item(resource_id, n)
	if resource_id == "wood" and randf() < 0.2:
		Inventory.add_item("fiber", 1)
	if resource_id == "stone" and randf() < 0.08 + 0.02 * (power - 1):
		Inventory.add_item("wind_shard", 1)
		GameState.wind_shards += 1
		EventBus.toast.emit("石缝里闪着风铃碎片！")
	available = false
	_cooldown = regrow_days
	RanchWeather.add_exp("foraging", 1)
	queue_redraw()
	EventBus.toast.emit("采集 %s ×%d" % [ItemDb.item_name(resource_id), n])

func prompt() -> String:
	if available:
		return "E：采集 %s" % display_name
	return "%s（待重生）" % display_name

func _art_tex() -> Texture2D:
	var map := {
		"wood": "tree_summer_broadleaf",
		"stone": "prop_rock_pile",
		"fiber": "prop_grass_tuft",
		"wind_shard": "icon_windchime_shard",
	}
	var key: String = map.get(resource_id, "")
	if key == "":
		return null
	return ArtPipeline.tex(key)

func _draw() -> void:
	if not available:
		draw_rect(Rect2(-size * 0.5, size), Color(0.3, 0.3, 0.3, 0.35))
		return
	draw_circle(Vector2.ZERO, size.x * 0.5, color)
	draw_rect(Rect2(-size * 0.5, size), color.darkened(0.25), false, 2.0)
