extends PanelContainer
## 合成面板：限宽滚动 + 明确关闭按钮（触屏可点）

@onready var title_label: Label = $VBox/TitleLabel
@onready var list_box: VBoxContainer = %ListBox
@onready var hint_label: Label = %CraftHintLabel

var _station := "workbench"
var _close_btn: Button
var _scroll: ScrollContainer
var _pending_craft := ""
var _qte = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("craft_ui")
	visible = false
	custom_minimum_size = Vector2(520, 420)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_build_chrome()
	_setup_qte()

func _build_chrome() -> void:
	# 顶部增加触屏关闭键
	var top := get_node_or_null("VBox")
	if top == null:
		return
	var bar := HBoxContainer.new()
	bar.name = "TopBar"
	top.add_child(bar)
	top.move_child(bar, 0)
	if title_label and title_label.get_parent() == top:
		top.remove_child(title_label)
		bar.add_child(title_label)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_btn = Button.new()
	_close_btn.name = "CloseBtn"
	_close_btn.text = "关闭"
	_close_btn.custom_minimum_size = Vector2(88, 40)
	_close_btn.pressed.connect(close)
	bar.add_child(_close_btn)
	# 列表放入滚动
	if list_box and list_box.get_parent():
		var parent := list_box.get_parent()
		_scroll = ScrollContainer.new()
		_scroll.name = "Scroll"
		_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_scroll.custom_minimum_size = Vector2(500, 320)
		parent.add_child(_scroll)
		parent.remove_child(list_box)
		list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll.add_child(list_box)

func open_station(station: String) -> void:
	_station = station
	visible = true
	get_tree().paused = true
	rebuild()
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
		open_station(_station if _station != "" else "workbench")

func rebuild() -> void:
	if title_label:
		title_label.text = "合成 · 厨房" if _station == "kitchen" else "合成 · 工作台"
	if hint_label:
		hint_label.text = "点击合成 · 关闭 / Esc / 再按 C 退出"
	for c in list_box.get_children():
		c.queue_free()
	var ids := RecipeDb.list_for_station(_station)
	if ids.is_empty():
		var l := Label.new()
		l.text = "（此工位暂无配方）"
		list_box.add_child(l)
		return
	var counts := Inventory.get_counts()
	# 可做的排前面
	var ready: Array = []
	var locked: Array = []
	for id in ids:
		if RecipeDb.can_craft(id, counts):
			ready.append(id)
		else:
			locked.append(id)
	for id in ready + locked:
		var r := RecipeDb.get_recipe(id)
		var btn := Button.new()
		btn.text = "%s  →  %s ×%d" % [
			_format_inputs(r.get("inputs", {})),
			ItemDb.item_name(str(r.get("output", ""))),
			int(r.get("output_count", 1)),
		]
		btn.tooltip_text = str(r.get("desc", ""))
		btn.custom_minimum_size = Vector2(480, 40)
		btn.disabled = not RecipeDb.can_craft(id, counts)
		btn.pressed.connect(_craft.bind(id))
		list_box.add_child(btn)

func _setup_qte() -> void:
	var QteScript := preload("res://scripts/ui/craft_qte.gd")
	_qte = QteScript.new()
	_qte.name = "CraftQte"
	get_tree().root.add_child.call_deferred(_qte)
	_qte.finished.connect(_on_qte_finished)

func _on_qte_finished(ok: bool, quality: float) -> void:
	var id := _pending_craft
	_pending_craft = ""
	if not ok:
		EventBus.toast.emit("手感差了点……材料未消耗，再试一次。")
		return
	if quality > 0.75:
		EventBus.toast.emit("匠心如一！成品更出色。")
		RanchWeather.add_exp("cooking", 3)
	else:
		RanchWeather.add_exp("cooking", 1)
	_do_craft(id, quality)

func _do_craft(id: String, quality: float = 0.5) -> void:
	if not RecipeDb.can_craft(id, Inventory.get_counts()):
		return
	RecipeDb.consume_inputs(id)
	var out := RecipeDb.get_output(id)
	var n := RecipeDb.get_output_count(id)
	if quality > 0.75:
		n += 1
	Inventory.add_item(out, n)
	EventBus.toast.emit("完成：%s ×%d" % [ItemDb.item_name(out), n])
	rebuild()

func _format_inputs(inputs: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k in inputs:
		parts.append("%s×%d" % [ItemDb.item_name(str(k)), int(inputs[k])])
	return " + ".join(parts)

func _craft(id: String) -> void:
	if not RecipeDb.can_craft(id, Inventory.get_counts()):
		return
	_pending_craft = id
	if _qte:
		_qte.start("合成")
	else:
		_do_craft(id, 0.5)
	MuseumDb.mark_discover(out)
	if ItemDb.get_type(out) == "cooked":
		Achievements.add_stat("cook_count", 1)
		RanchWeather.add_exp("cooking", 2)
	if out == "tiny_bell":
		GameState.add_flag("has_tiny_bell", true)
	EventBus.toast.emit("合成：%s ×%d" % [ItemDb.item_name(out), n])
	rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# 点按 / 右键 / 取消 / 再按 C：一律关闭，避免卡死
	if event.is_action_pressed("ui_cancel") \
		or event.is_action_pressed("interact") \
		or event.is_action_pressed("use_tool") \
		or event.is_action_pressed("open_craft"):
		close()
		get_viewport().set_input_as_handled()
