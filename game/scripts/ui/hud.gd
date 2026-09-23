extends Control
## HUD：时钟、季节、金钱、快捷栏、Toast

@onready var date_label: Label = %DateLabel
@onready var clock_label: Label = %ClockLabel
@onready var money_label: Label = %MoneyLabel
@onready var season_label: Label = %SeasonLabel
@onready var hp_label: Label = %HpLabel
@onready var toast_label: Label = %ToastLabel
@onready var hint_label: Label = %HintLabel
@onready var help_label: Label = %HelpLabel

var _toast_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.time_changed.connect(_on_time)
	EventBus.money_changed.connect(_on_money)
	EventBus.toast.connect(_on_toast)
	EventBus.day_started.connect(func(_d, _s): _refresh_date())
	EventBus.hud_refresh.connect(_refresh_all)
	EventBus.inventory_changed.connect(_show_hotbar)
	toast_label.modulate.a = 0.0
	var touch_on := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if help_label:
		help_label.visible = not touch_on
		if not touch_on:
			help_label.text = "WASD移动 · E交互 · I背包 · C合成 · M地图 · U图鉴 · O外观 · F1设置 · P拍照 · Esc暂停"
	_refresh_all()

func _refresh_all() -> void:
	_refresh_date()
	clock_label.text = TimeSystem.format_clock()
	money_label.text = "谷币 %d" % Inventory.money
	var am := get_tree().get_first_node_in_group("area_manager")
	if am:
		hp_label.text = "HP %d/%d" % [am.player_hp, am.max_hp]
	else:
		hp_label.text = "HP 5/5"
	season_label.text = "%s · %s · 天气:%s · %s" % [
		TimeSystem.season(), StoryDb.current_title(), RanchWeather.weather, MarketDb.board_text()
	]
	_show_hotbar()

func _show_hotbar() -> void:
	if hint_label == null:
		return
	var touch_on := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if touch_on:
		hint_label.visible = false
		return
	hint_label.visible = true
	var parts: PackedStringArray = []
	for i in 4:
		var n := i + 1
		if i < Inventory.slots.size():
			var s: Dictionary = Inventory.slots[i]
			parts.append("%d:%s×%d" % [n, ItemDb.item_name(str(s["id"])), int(s["count"])])
		else:
			parts.append("%d:—" % n)
	hint_label.text = "快捷栏 " + " ".join(parts)

func _refresh_date() -> void:
	date_label.text = TimeSystem.format_date()
	season_label.text = "%s · %s · 天气:%s · %s" % [
		TimeSystem.season(), StoryDb.current_title(), RanchWeather.weather, MarketDb.board_text()
	]

func _on_time(_h: int, _m: int) -> void:
	clock_label.text = TimeSystem.format_clock()

func _on_money(v: int) -> void:
	money_label.text = "谷币 %d" % v

func _on_toast(msg: String) -> void:
	toast_label.text = msg
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	toast_label.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)

func set_hint(text: String) -> void:
	# 交互提示用 help 上方空间；与快捷栏错开
	if hint_label and text != "":
		hint_label.text = text
	elif hint_label:
		_show_hotbar()

func set_help_visible(v: bool) -> void:
	if help_label:
		help_label.visible = v
