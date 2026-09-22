extends PanelContainer
## 合成面板

@onready var title_label: Label = $VBox/TitleLabel
@onready var list_box: VBoxContainer = %ListBox
@onready var hint_label: Label = %CraftHintLabel

var _station := "workbench"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("craft_ui")
	visible = false

func open_station(station: String) -> void:
	_station = station
	visible = true
	get_tree().paused = true
	rebuild()

func toggle() -> void:
	if visible:
		visible = false
		get_tree().paused = false
	else:
		open_station("workbench")

func rebuild() -> void:
	title_label.text = "合成 · 厨房" if _station == "kitchen" else "合成 · 工作台"
	hint_label.text = "点击配方合成 · C/Esc 关闭"
	for c in list_box.get_children():
		c.queue_free()
	var ids := RecipeDb.list_for_station(_station)
	if ids.is_empty():
		var l := Label.new()
		l.text = "（此工位暂无配方）"
		list_box.add_child(l)
		return
	for id in ids:
		var r := RecipeDb.get_recipe(id)
		var btn := Button.new()
		btn.text = "%s  →  %s ×%d" % [
			_format_inputs(r.get("inputs", {})),
			ItemDb.item_name(str(r.get("output", ""))),
			int(r.get("output_count", 1)),
		]
		btn.tooltip_text = str(r.get("desc", ""))
		btn.disabled = not RecipeDb.can_craft(id, Inventory.get_counts())
		btn.pressed.connect(_craft.bind(id))
		list_box.add_child(btn)

func _format_inputs(inputs: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k in inputs:
		parts.append("%s×%d" % [ItemDb.item_name(str(k)), int(inputs[k])])
	return " + ".join(parts)

func _craft(id: String) -> void:
	if not RecipeDb.can_craft(id, Inventory.get_counts()):
		return
	RecipeDb.consume_inputs(id)
	var out := RecipeDb.get_output(id)
	var n := RecipeDb.get_output_count(id)
	Inventory.add_item(out, n)
	MuseumDb.mark_discover(out)
	if ItemDb.get_type(out) == "cooked":
		Achievements.add_stat("cook_count", 1)
		RanchWeather.add_exp("cooking", 2)
	else:
		RanchWeather.add_exp("cooking", 0)
	if out == "tiny_bell":
		GameState.add_flag("has_tiny_bell", true)
	EventBus.toast.emit("合成：%s ×%d" % [ItemDb.item_name(out), n])
	rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("open_craft"):
		toggle()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		visible = false
		get_tree().paused = false
		get_viewport().set_input_as_handled()
