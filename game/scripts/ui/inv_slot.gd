extends Button
## 单个背包格

func setup(item_id: String, count: int, selected: bool) -> void:
	var item_name := ItemDb.item_name(item_id)
	var col := ItemDb.get_color(item_id)
	text = "%s\n×%d" % [item_name, count]
	modulate = Color(1.2, 1.2, 1.0) if selected else Color.WHITE
	var style := StyleBoxFlat.new()
	style.bg_color = col.darkened(0.15)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2 if selected else 1)
	style.border_color = Color("#FFF2A8") if selected else Color("#2F3D28")
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_color_override("font_color", Color("#1A2418"))
	add_theme_color_override("font_hover_color", Color("#1A2418"))
	add_theme_font_size_override("font_size", 11)

func setup_empty(selected: bool) -> void:
	text = ""
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.15, 0.45)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2 if selected else 1)
	style.border_color = Color("#FFF2A8") if selected else Color("#2F3D28")
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
