extends PanelContainer
## 对话框

signal closed

@onready var name_label: Label = %NameLabel
@onready var line_label: Label = %LineLabel
@onready var next_label: Label = %NextLabel

var _lines: Array = []
var _index := 0
var _npc_id := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogue_ui")
	EventBus.dialogue_started.connect(_on_start)
	visible = false
	next_label.text = "E / 空格 继续"

func show_cutscene(key: String) -> void:
	var tex := ArtPipeline.tex(key)
	if tex:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = Vector2(400, 220)
		add_child(img)
		await get_tree().create_timer(2.5).timeout
		img.queue_free()

func _on_start(lines: Array, npc_id: String) -> void:
	_lines = lines
	_index = 0
	_npc_id = npc_id
	get_tree().paused = true
	visible = true
	_show()

func _show() -> void:
	if _index >= _lines.size():
		_end()
		return
	name_label.text = _npc_id if _npc_id == "system" else NpcDb.get_npc(_npc_id).get("name", _npc_id)
	line_label.text = str(_lines[_index])
	var speaker: String = name_label.text
	GameState.append_dialogue_log(speaker, str(_lines[_index]))

func _end() -> void:
	visible = false
	get_tree().paused = false
	EventBus.dialogue_ended.emit()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("use_tool"):
		_index += 1
		if _index >= _lines.size():
			_end()
		else:
			_show()
		get_viewport().set_input_as_handled()
