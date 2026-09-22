extends PanelContainer
## 暂停菜单

signal resume_requested
signal save_requested
signal load_requested
signal quit_requested

@onready var resume_btn: Button = %ResumeBtn
@onready var save_btn: Button = %PauseSaveBtn
@onready var load_btn: Button = %PauseLoadBtn
@onready var quit_btn: Button = %PauseQuitBtn
@onready var help_label: Label = %PauseHelpLabel

var _log_btn: Button
var _log_panel: PanelContainer
var _log_text: RichTextLabel
var _slot_panel: PanelContainer
var _slot_title: Label
var _slot_btns: Array = []
var _slot_auto_btn: Button
var _slot_save_mode := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_btn.text = "继续游戏"
	save_btn.text = "存档槽…"
	load_btn.text = "读档槽…"
	quit_btn.text = "回到标题"
	help_label.text = "WASD移动 · E交互 · I背包 · C合成 · M地图 · P拍照 · T睡觉 · H休整 · F2新周目+ · L对话日志"
	resume_btn.pressed.connect(func(): resume_requested.emit())
	save_btn.pressed.connect(func(): _open_slots(true))
	load_btn.pressed.connect(func(): _open_slots(false))
	quit_btn.pressed.connect(func(): quit_requested.emit())
	_build_log_ui()
	_build_slot_ui()

func _build_slot_ui() -> void:
	_slot_panel = PanelContainer.new()
	_slot_panel.name = "SlotPanel"
	_slot_panel.visible = false
	_slot_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	_slot_panel.add_child(box)
	_slot_title = Label.new()
	_slot_title.text = "选择存档槽"
	box.add_child(_slot_title)
	for i in SaveSystem.SLOT_COUNT:
		var b := Button.new()
		b.text = "槽位 %d" % (i + 1)
		b.pressed.connect(_on_slot_pressed.bind(i))
		box.add_child(b)
		_slot_btns.append(b)
	var auto_b := Button.new()
	auto_b.text = "自动存档"
	auto_b.pressed.connect(_on_auto_pressed)
	box.add_child(auto_b)
	_slot_auto_btn = auto_b
	var cancel := Button.new()
	cancel.text = "返回"
	cancel.pressed.connect(func(): _slot_panel.visible = false)
	box.add_child(cancel)
	add_child(_slot_panel)

func _open_slots(for_save: bool) -> void:
	_slot_save_mode = for_save
	_slot_title.text = "保存到…" if for_save else "读取自…"
	for i in _slot_btns.size():
		var meta: Dictionary = SaveSystem.slot_meta(i)
		var suffix := ""
		if not meta.is_empty():
			suffix = " · 第%s天 · %s" % [meta.get("day", "?"), meta.get("saved_at", "")]
		_slot_btns[i].text = "槽位 %d%s" % [i + 1, suffix]
		if for_save:
			_slot_btns[i].disabled = false
		else:
			_slot_btns[i].disabled = not SaveSystem.has_save(i)
	_slot_auto_btn.visible = not for_save
	_slot_auto_btn.disabled = not SaveSystem.has_auto()
	_slot_panel.visible = true

func _on_slot_pressed(slot: int) -> void:
	if _slot_save_mode:
		SaveSystem.save_game(slot)
	else:
		SaveSystem.load_game(slot)
	_slot_panel.visible = false

func _on_auto_pressed() -> void:
	SaveSystem.load_auto()
	_slot_panel.visible = false

func _build_log_ui() -> void:
	_log_btn = Button.new()
	_log_btn.name = "LogBtn"
	_log_btn.text = "对话日志 (L)"
	_log_btn.pressed.connect(_toggle_log)
	add_child(_log_btn)
	_log_btn.move_to_front()

	_log_panel = PanelContainer.new()
	_log_panel.name = "LogPanel"
	_log_panel.visible = false
	_log_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log_text = RichTextLabel.new()
	_log_text.bbcode_enabled = true
	_log_text.scroll_following = true
	_log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_panel.add_child(_log_text)
	add_child(_log_panel)

func _toggle_log() -> void:
	if _log_panel.visible:
		_log_panel.visible = false
		return
	var lines: Array = GameState.dialogue_log
	if lines.is_empty():
		_log_text.text = "（还没有对话记录）"
	else:
		var parts: PackedStringArray = []
		for e in lines.slice(max(0, lines.size() - 80)):
			parts.append("[b]%s[/b]：%s" % [e.get("speaker", "?"), e.get("line", "")])
		_log_text.text = "\n".join(parts)
	_log_panel.visible = true

func open() -> void:
	visible = true
	get_tree().paused = true
	load_btn.disabled = not (SaveSystem.has_save(0) or SaveSystem.has_auto())
	_log_panel.visible = false
	_slot_panel.visible = false
	resume_btn.grab_focus()

func close() -> void:
	visible = false
	_log_panel.visible = false
	_slot_panel.visible = false
	get_tree().paused = false
