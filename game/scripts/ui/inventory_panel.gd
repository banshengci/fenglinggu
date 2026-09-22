extends PanelContainer
class_name InventoryPanel
## 背包面板：格子展示、快捷栏选中、点击出货/送礼提示

signal selection_changed(item_id: String)

@onready var grid: GridContainer = %Grid
@onready var money_label: Label = %InvMoneyLabel
@onready var detail_label: Label = %DetailLabel

const SLOT_SCENE := preload("res://scenes/ui/inv_slot.tscn")

var selected_index := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("inventory_ui")
	EventBus.inventory_changed.connect(rebuild)
	EventBus.money_changed.connect(_on_money)
	rebuild()
	_on_money(Inventory.money)
	visible = false

func toggle() -> void:
	visible = not visible
	if visible:
		rebuild()
		get_tree().paused = true
	else:
		get_tree().paused = false

func _on_money(v: int) -> void:
	money_label.text = "谷币 %d" % v

func rebuild() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in Inventory.MAX_SLOTS:
		var slot = SLOT_SCENE.instantiate()
		grid.add_child(slot)
		if i < Inventory.slots.size():
			var s: Dictionary = Inventory.slots[i]
			slot.setup(str(s["id"]), int(s["count"]), i == selected_index)
		else:
			slot.setup_empty(i == selected_index)
		slot.pressed.connect(_on_slot.bind(i))
	_update_detail()

func _on_slot(index: int) -> void:
	selected_index = index
	rebuild()

func _update_detail() -> void:
	if selected_index >= Inventory.slots.size():
		detail_label.text = "选中：（空）"
		selection_changed.emit("")
		return
	var s: Dictionary = Inventory.slots[selected_index]
	var id := str(s["id"])
	detail_label.text = "选中：%s ×%d\n%s" % [ItemDb.item_name(id), int(s["count"]), ItemDb.get_desc(id)]
	selection_changed.emit(id)

func selected_item_id() -> String:
	if selected_index < Inventory.slots.size():
		return str(Inventory.slots[selected_index]["id"])
	return ""
