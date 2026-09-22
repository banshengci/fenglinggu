extends PanelContainer
## 地图面板：区域与兴趣点示意

@onready var map_label: Label = %MapLabel
@onready var legend_label: Label = %MapLegendLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("map_ui")
	visible = false

func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		_refresh()

func _refresh() -> void:
	map_label.text = "\n".join([
		"风铃谷 · 简易地图",
		"",
		"  [风车林]     [风铃祭]     [矿洞/深部]",
		"      ↑           ↑            ↑",
		"  【屋舍/床】 【风铃塔】 【杂货摊/委托】",
		"     【工作台】【厨房】",
		"     【菜园 6×4】〔共鸣台〕【出货箱】",
		"              [湖畔栈道]",
		"",
		"你在：" + _area_name(),
		"主线：" + StoryDb.current_title(),
		StoryDb.progress_text(),
	])
	legend_label.text = "Esc/M 关闭 · 矿洞入口在地图东侧风铃塔旁"

func _area_name() -> String:
	var am := get_tree().get_first_node_in_group("area_manager")
	if am == null:
		return "翠谷镇"
	var area := str(am.current_area)
	match area:
		"mine":
			return "雾晶矿洞 B%d" % (int(am.current_floor) + 1)
		"deep_mine":
			return "矿脉深部 B%d" % (4 + int(am.current_floor))
		"lakeside":
			return "湖畔栈道"
		"forest":
			return "旧风车林"
		"festival":
			return "风铃祭广场"
	return "翠谷镇"

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("open_map") or event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()
