extends PanelContainer
## 博物馆 / 成就 / 技能 总览面板

@onready var body_label: Label = %MuseumBody

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("museum_ui")
	visible = false

func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()

func close() -> void:
	visible = false
	get_tree().paused = false

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func _refresh() -> void:
	var lines: PackedStringArray = []
	lines.append(MuseumDb.catalog_text())
	lines.append("")
	lines.append("技能：")
	for s in RanchWeather.skills():
		var sid := str(s.get("id", ""))
		lines.append("  %s Lv%d（%d）" % [RanchWeather.skill_name(sid), RanchWeather.skill_level(sid), int(RanchWeather.skill_exp.get(sid, 0))])
	lines.append("")
	lines.append("成就 %d/%d" % [Achievements.unlocked_count(), Achievements.list_all().size()])
	for a in Achievements.list_all():
		var ok := bool(Achievements.unlocked.get(str(a.get("id")), false))
		lines.append("  %s %s — %s" % ["✓" if ok else "·", str(a.get("name", "")), str(a.get("desc", ""))])
	lines.append("")
	lines.append("动物：%s" % _animal_text())
	body_label.text = "\n".join(lines)

func _animal_text() -> String:
	var parts: PackedStringArray = []
	for id in RanchWeather.animals_owned:
		var def: Dictionary = RanchWeather.animal_def(id)
		parts.append("%s×%d" % [str(def.get("name", id)), int(RanchWeather.animals_owned[id])])
	return "、".join(parts) if parts.size() > 0 else "（无）"

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
