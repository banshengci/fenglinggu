extends Control
## 设置面板：音量、休闲辅助、重扫美术

@onready var body: VBoxContainer = %SettingsBody

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func _build() -> void:
	if body == null:
		body = VBoxContainer.new()
		add_child(body)
	var title := Label.new()
	title.text = "设置（Esc 关闭）"
	body.add_child(title)

	_add_slider("主音量", 0.8, func(v): AudioServer.set_bus_volume_db(0, linear_to_db(clampf(v, 0.01, 1.0))))
	_add_toggle("休闲辅助", bool(GameState.get_flag("easy_mode", true)), func(on): GameState.add_flag("easy_mode", on))
	_add_toggle("性能档（关天气叠色）", bool(GameState.get_flag("low_fx", false)), func(on):
		GameState.add_flag("low_fx", on)
	)
	_add_button("重新扫描美术资源", func(): ArtPipeline.reload())
	# v2.0 系统改进
	_add_toggle("闲日长（时间减慢）", bool(SysPrefs.leisure_mode) if SysPrefs else false, func(on):
		if SysPrefs:
			if on != SysPrefs.leisure_mode:
				SysPrefs.toggle_leisure()
	)
	_add_toggle("高对比", bool(SysPrefs.high_contrast) if SysPrefs else false, func(on):
		if SysPrefs and on != SysPrefs.high_contrast:
			SysPrefs.toggle_high_contrast()
	)
	_add_toggle("减少动效", bool(SysPrefs.reduce_motion) if SysPrefs else false, func(on):
		if SysPrefs and on != SysPrefs.reduce_motion:
			SysPrefs.toggle_reduce_motion()
	)
	_add_slider("界面缩放", float(SysPrefs.ui_scale) if SysPrefs else 1.0, func(v):
		if SysPrefs:
			SysPrefs.set_ui_scale(0.8 + v * 0.7)
	)
	_add_button("导出云存档", func(): SysPrefs.export_cloud())
	_add_button("导入云存档", func(): SysPrefs.import_cloud())
	_add_button("关闭", close)

func _add_slider(label: String, init: float, cb: Callable) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = init
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(cb)
	row.add_child(l)
	row.add_child(s)
	body.add_child(row)

func _add_toggle(label: String, init: bool, cb: Callable) -> void:
	var b := CheckButton.new()
	b.text = label
	b.button_pressed = init
	b.toggled.connect(cb)
	body.add_child(b)

func _add_button(label: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.pressed.connect(cb)
	body.add_child(b)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") \
		or event.is_action_pressed("interact") \
		or event.is_action_pressed("use_tool"):
		close()
		get_viewport().set_input_as_handled()
