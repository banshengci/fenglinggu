extends PanelContainer
## 风铃演奏：8 音按钮 + 序列显示

@onready var body: VBoxContainer = %HarpBody

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group("harp_ui")
	_build()

func _build() -> void:
	if body == null:
		return
	var title := Label.new()
	title.text = "风铃演奏（U 看图鉴）"
	body.add_child(title)
	var seq_label := Label.new()
	seq_label.name = "Seq"
	body.add_child(seq_label)
	for note in 8:
		var w := WindDb.word_by_note(note)
		var b := Button.new()
		b.text = "♪ %s" % str(w.get("name", str(note)))
		b.custom_minimum_size = Vector2(88, 44)
		b.pressed.connect(func(): WindDb.press_note(note); _refresh())
		body.add_child(b)
	var row := HBoxContainer.new()
	var clear_btn := Button.new()
	clear_btn.text = "清空"
	clear_btn.pressed.connect(func(): WindDb.clear_sequence(); _refresh())
	row.add_child(clear_btn)
	var close_btn := Button.new()
	close_btn.text = "收起"
	close_btn.pressed.connect(close)
	row.add_child(close_btn)
	body.add_child(row)

func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()

func close() -> void:
	visible = false
	if get_tree().paused:
		get_tree().paused = false

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func _refresh() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact") or event.is_action_pressed("use_tool"):
		close()
		get_viewport().set_input_as_handled()
