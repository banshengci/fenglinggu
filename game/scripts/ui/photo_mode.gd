extends PanelContainer
## 拍照模式：隐藏 UI，P 截图

var active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func toggle() -> void:
	active = not active
	visible = active
	get_tree().call_group("photo_hide", "set_visible", not active)
	EventBus.toast.emit("拍照模式开启（P 截图，Esc 退出）" if active else "拍照模式关闭")

func capture() -> void:
	var dir := "user://photos"
	DirAccess.make_dir_recursive_absolute(dir)
	var img := get_viewport().get_texture().get_image()
	var path := "%s/wind_chime_%s.png" % [dir, Time.get_datetime_string_from_system().replace(":", "-")]
	img.save_png(path)
	Sfx.play("click", 1.2, -8.0)
	EventBus.toast.emit("已保存照片")

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		if event.is_physical_key_pressed(KEY_P):
			toggle()
			get_viewport().set_input_as_handled()
		return
	if event.is_physical_key_pressed(KEY_P):
		capture()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()
