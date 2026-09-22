extends PanelContainer
## 角色外观：发色 / 衣色 / 肤色

signal appearance_changed

var hairstyles := ["短发", "束发", "长发", "刺猬头"]
var hair_colors := [Color("#3D2B1F"), Color("#6B5340"), Color("#C4A574"), Color("#E8C87A"), Color("#8A5A5A"), Color("#5B8FA8")]
var body_colors := [Color("#5B8FA8"), Color("#6B8F5A"), Color("#C07850"), Color("#8A7AAA"), Color("#E05555"), Color("#E8C87A")]
var skin_colors := [Color("#F0D0B0"), Color("#E0B080"), Color("#C08060"), Color("#8A5A40")]

var hair_i := 0
var hair_c := 0
var body_c := 0
var skin_c := 0

@onready var info_label: Label = %LookInfo

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_buttons()

func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()

func close() -> void:
	visible = false
	get_tree().paused = false
	appearance_changed.emit()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func _build_buttons() -> void:
	var box := VBoxContainer.new()
	add_child(box)
	box.name = "Buttons"
	for row in [
		["发型", func(): hair_i = (hair_i + 1) % hairstyles.size()],
		["发色", func(): hair_c = (hair_c + 1) % hair_colors.size()],
		["衣色", func(): body_c = (body_c + 1) % body_colors.size()],
		["肤色", func(): skin_c = (skin_c + 1) % skin_colors.size()],
	]:
		var btn := Button.new()
		btn.text = "切换·%s" % row[0]
		btn.pressed.connect(row[1])
		btn.pressed.connect(_refresh)
		box.add_child(btn)
	var close_btn := Button.new()
	close_btn.text = "完成"
	close_btn.pressed.connect(close)
	box.add_child(close_btn)

func _refresh() -> void:
	if info_label:
		info_label.text = "外观：%s · 自定义已完成，角色绘制将应用配色。" % hairstyles[hair_i]
	# 应用到玩家
	var p := get_tree().get_first_node_in_group("player")
	if p and "body_color" in p:
		p.body_color = body_colors[body_c]
		p.hand_color = hair_colors[hair_c]
		if "skin_color" in p:
			p.skin_color = skin_colors[skin_c]

func to_dict() -> Dictionary:
	return {"hair_i": hair_i, "hair_c": hair_c, "body_c": body_c, "skin_c": skin_c}

func from_dict(d: Dictionary) -> void:
	hair_i = int(d.get("hair_i", 0))
	hair_c = int(d.get("hair_c", 0))
	body_c = int(d.get("body_c", 0))
	skin_c = int(d.get("skin_c", 0))
