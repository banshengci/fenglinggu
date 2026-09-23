extends PanelContainer
## 图鉴/技能/成就：滚动 + 关闭钮

@onready var body_label: Label = %MuseumBody

var _close_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("museum_ui")
	visible = false
	custom_minimum_size = Vector2(560, 460)
	_build_chrome()

func _build_chrome() -> void:
	var top := get_node_or_null("VBox")
	if top == null:
		# 节点挂在自身下
		if body_label and body_label.get_parent():
			top = body_label.get_parent()
	if top == null:
		return
	var bar := HBoxContainer.new()
	top.add_child(bar)
	top.move_child(bar, 0)
	var title := Label.new()
	title.text = "图鉴 · 技能 · 成就"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)
	_close_btn = Button.new()
	_close_btn.text = "关闭"
	_close_btn.custom_minimum_size = Vector2(88, 40)
	_close_btn.pressed.connect(close)
	bar.add_child(_close_btn)
	if body_label and body_label.get_parent():
		var parent := body_label.get_parent()
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(520, 360)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		parent.add_child(scroll)
		parent.remove_child(body_label)
		body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scroll.add_child(body_label)

func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()
	if _close_btn:
		_close_btn.grab_focus()

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
	var lines: PackedStringArray = []
	lines.append(MuseumDb.catalog_text())
	lines.append("")
	lines.append("技能：")
	for s in RanchWeather.skills():
		var sid := str(s.get("id", ""))
		lines.append("  %s Lv%d（%d）" % [RanchWeather.skill_name(sid), RanchWeather.skill_level(sid), int(RanchWeather.skill_exp.get(sid, 0))])
	lines.append("")
	lines.append("成就 %d/%d" % [Achievements.unlocked_count(), Achievements.list_all().size()])
	for a in Achievements.list_all():
		var ok := bool(Achievements.unlocked.get(str(a.get("id")), false))
		lines.append("  %s %s — %s" % ["V" if ok else ".", str(a.get("name", "")), str(a.get("desc", ""))])
	if body_label:
		body_label.text = "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") \
		or event.is_action_pressed("interact") \
		or event.is_action_pressed("use_tool") \
		or event.is_action_pressed("open_map"):
		close()
		get_viewport().set_input_as_handled()
