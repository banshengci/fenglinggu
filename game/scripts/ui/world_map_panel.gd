extends PanelContainer
## 开放世界地图 / 快速旅行 / 漫游

signal travel_requested(region_id: String)

@onready var title_label: Label = %WorldMapTitle
@onready var body_label: Label = %WorldMapBody
@onready var list_box: VBoxContainer = %WorldMapList

var current_area := "town"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("world_map_ui")
	visible = false

func open(area_id: String) -> void:
	current_area = area_id
	visible = true
	get_tree().paused = true
	rebuild()

func close() -> void:
	visible = false
	get_tree().paused = false

func toggle(area_id: String) -> void:
	if visible:
		close()
	else:
		open(area_id)

func rebuild() -> void:
	title_label.text = "风之谷 · 开放世界"
	body_label.text = WorldMapDb.path_text(current_area)
	for c in list_box.get_children():
		c.queue_free()
	for rid in WorldMapDb.unlocked_ids():
		var r: Dictionary = WorldMapDb.region(rid)
		var btn := Button.new()
		btn.text = "前往：%s" % str(r.get("name", rid))
		btn.disabled = rid == current_area
		btn.pressed.connect(_go.bind(rid))
		list_box.add_child(btn)
	# 漫游到邻接
	var wander := Button.new()
	wander.text = "随意漫游（邻接区域）"
	wander.pressed.connect(_wander)
	list_box.add_child(wander)

func _go(rid: String) -> void:
	close()
	travel_requested.emit(rid)

func _wander() -> void:
	var target := WorldMapDb.pick_wander_target(current_area)
	if target == current_area:
		EventBus.toast.emit("四野静悄悄……再解锁一些区域吧。")
		return
	close()
	travel_requested.emit(target)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_map"):
		close()
		get_viewport().set_input_as_handled()
