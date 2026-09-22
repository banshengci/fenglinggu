extends Control
## 标题画面：新游戏 / 读档 / 退出

signal start_pressed(load_save: bool)

@onready var title_label: Label = %TitleLabel
@onready var sub_label: Label = %SubLabel
@onready var new_btn: Button = %NewBtn
@onready var load_btn: Button = %LoadBtn
@onready var quit_btn: Button = %QuitBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color("#F3EAD3"))
	sub_label.add_theme_color_override("font_color", Color("#E8F0E0"))
	title_label.text = "风铃谷"
	sub_label.text = "在一个被风遗忘的小镇，把日子过回来。"
	new_btn.text = "新游戏"
	load_btn.text = "读取存档"
	quit_btn.text = "退出"
	load_btn.disabled = not SaveSystem.has_save()
	new_btn.pressed.connect(func(): start_pressed.emit(false))
	load_btn.pressed.connect(func(): start_pressed.emit(true))
	quit_btn.pressed.connect(func(): get_tree().quit())
	new_btn.grab_focus()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#3D5C4A"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, size.y * 0.7),
		Vector2(size.x * 0.4, size.y * 0.55),
		Vector2(size.x * 0.7, size.y * 0.65),
		Vector2(size.x, size.y * 0.5),
		Vector2(size.x, size.y),
		Vector2(0, size.y),
	]), Color("#6B8F5A"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, size.y * 0.55),
		Vector2(size.x * 0.3, size.y * 0.35),
		Vector2(size.x * 0.55, size.y * 0.5),
		Vector2(size.x, size.y * 0.3),
		Vector2(size.x, size.y),
		Vector2(0, size.y),
	]), Color("#2F4A3A"))
	draw_circle(Vector2(size.x * 0.78, size.y * 0.22), 36.0, Color("#E8C87A"))
	draw_line(Vector2(size.x * 0.2, size.y * 0.25), Vector2(size.x * 0.2, size.y * 0.38), Color("#E8F0E0"), 2.0)
	draw_circle(Vector2(size.x * 0.2, size.y * 0.42), 6.0, Color("#E8C87A"))
