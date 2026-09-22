extends Node
## 统一 UI 主题：田园纸色 + 木牌边

var theme: Theme

func _ready() -> void:
	theme = _build_theme()
	get_tree().root.theme = theme

func _build_theme() -> Theme:
	var t := Theme.new()
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#F3EAD3")
	panel.border_color = Color("#5C4030")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(10)
	panel.content_margin_left = 14
	panel.content_margin_right = 14
	panel.content_margin_top = 10
	panel.content_margin_bottom = 10
	panel.shadow_color = Color(0.1, 0.08, 0.05, 0.25)
	panel.shadow_size = 4
	t.set_stylebox("panel", "PanelContainer", panel)

	var btn := StyleBoxFlat.new()
	btn.bg_color = Color("#E0D0B0")
	btn.border_color = Color("#6B5340")
	btn.set_border_width_all(2)
	btn.set_corner_radius_all(8)
	btn.content_margin_left = 12
	btn.content_margin_right = 12
	btn.content_margin_top = 8
	btn.content_margin_bottom = 8
	t.set_stylebox("normal", "Button", btn)

	var btn_h := btn.duplicate()
	btn_h.bg_color = Color("#F0E2C0")
	t.set_stylebox("hover", "Button", btn_h)

	var btn_p := btn.duplicate()
	btn_p.bg_color = Color("#C4A574")
	t.set_stylebox("pressed", "Button", btn_p)

	var btn_d := btn.duplicate()
	btn_d.bg_color = Color("#B0A090")
	t.set_stylebox("disabled", "Button", btn_d)

	t.set_color("font_color", "Label", Color("#2F3D28"))
	t.set_color("font_color", "Button", Color("#2A2018"))
	t.set_font_size("font_size", "Label", 14)
	t.set_font_size("font_size", "Button", 14)
	t.set_color("font_color", "PanelContainer", Color("#2F3D28"))
	return t

func title_style(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("#3D2B1F"))
