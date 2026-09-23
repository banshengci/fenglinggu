extends PanelContainer
## 背包：限宽滚动 + 关闭钮（触屏可点）

signal selection_changed(item_id: String)

@onready var grid: GridContainer = %Grid
@onready var money_label: Label = %InvMoneyLabel
@onready var detail_label: Label = %DetailLabel

const SLOT_SCENE := preload("res://scenes/ui/inv_slot.tscn")

var selected_index := 0
var _close_btn: Button
var _scroll: ScrollContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("inventory_ui")
	EventBus.inventory_changed.connect(rebuild)
	EventBus.money_changed.connect(_on_money)
	custom_minimum_size = Vector2(560, 440)
	_build_chrome()
	rebuild()
	_on_money(Inventory.money)
	visible = false

func _build_chrome() -> void:
	var top := get_node_or_null("VBox")
	if top == null:
		return
	var bar := HBoxContainer.new()
	bar.name = "TopBar"
	top.add_child(bar)
	top.move_child(bar, 0)
	var title := top.get_node_or_null("Title")
	if title:
		top.remove_child(title)
		bar.add_child(title)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_btn = Button.new()
	_close_btn.text = "关闭"
	_close_btn.custom_minimum_size = Vector2(88, 40)
	_close_btn.pressed.connect(close)
	bar.add_child(_close_btn)
	# 格子滚动
	if grid and grid.get_parent():
		var parent := grid.get_parent()
		_scroll = ScrollContainer.new()
		_scroll.custom_minimum_size = Vector2(520, 280)
		_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		parent.add_child(_scroll)
		parent.remove_child(grid)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll.add_child(grid)
	# 类型筛选条
	var filter_bar := HBoxContainer.new()
	filter_bar.name = "FilterBar"
	top.add_child(filter_bar)
	if _scroll:
		top.move_child(filter_bar, top.get_children().find(_scroll))
	else:
		top.move_child(filter_bar, 1)
	for label in ["全部", "种子", "作物", "工具", "材料", "任务"]:
		var b := Button.new()
		b.text = label
		b.custom_minimum_size = Vector2(72, 36)
		b.pressed.connect(_set_filter_label.bind(label))
		filter_bar.add_child(b)

func _set_filter_label(label: String) -> void:
	var map := {
		"全部": "all", "种子": "seed", "作物": "crop",
		"工具": "tool", "材料": "resource", "任务": "quest",
	}
	SysPrefs.set_filter(str(map.get(label, "all")))

func open() -> void:
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
		open()

func _on_money(v: int) -> void:
	if money_label:
		money_label.text = "谷币 %d" % v

func rebuild() -> void:
	for c in grid.get_children():
		c.queue_free()
	var filt := "all"
	if SysPrefs:
		filt = SysPrefs.bag_filter
	var shown: Array = []
	for s in Inventory.slots:
		if filt == "all":
			shown.append(s)
			continue
		var tid := ItemDb.get_type(str(s["id"]))
		if tid == filt:
			shown.append(s)
	for i in Inventory.MAX_SLOTS:
		var slot = SLOT_SCENE.instantiate()
		grid.add_child(slot)
		if i < shown.size():
			var s: Dictionary = shown[i]
			var real_idx := Inventory.slots.find(s)
			var is_sel := real_idx == selected_index
			slot.setup(str(s["id"]), int(s["count"]), is_sel)
			slot.pressed.connect(_on_slot.bind(real_idx if real_idx >= 0 else i))
		else:
			slot.setup_empty(false)
	_update_detail()

func _on_slot(index: int) -> void:
	selected_index = index
	rebuild()

func _update_detail() -> void:
	if selected_index >= Inventory.slots.size():
		if detail_label:
			detail_label.text = "选中：（空）"
		selection_changed.emit("")
		return
	var s: Dictionary = Inventory.slots[selected_index]
	var id := str(s["id"])
	if detail_label:
		detail_label.text = "选中：%s ×%d\n%s" % [ItemDb.item_name(id), int(s["count"]), ItemDb.get_desc(id)]
	selection_changed.emit(id)

func selected_item_id() -> String:
	if selected_index < Inventory.slots.size():
		return str(Inventory.slots[selected_index]["id"])
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") \
		or event.is_action_pressed("interact") \
		or event.is_action_pressed("use_tool") \
		or event.is_action_pressed("open_inventory"):
		close()
		get_viewport().set_input_as_handled()
