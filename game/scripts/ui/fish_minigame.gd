extends PanelContainer
## 钓鱼小游戏

@onready var tip: Label = %FishTip

var _pos := 0.0
var _dir := 1.0
var _zone := 0.3
var _zone_w := 0.18
var _ok_time := 0.0
var _time_left := 3.5
var _running := false
var _fish_id := "carp_spring"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group("fish_ui")
	var btn := Button.new()
	btn.text = "起竿"
	btn.custom_minimum_size = Vector2(120, 56)
	btn.anchor_left = 0.5
	btn.anchor_top = 1.0
	btn.anchor_right = 0.5
	btn.anchor_bottom = 1.0
	btn.offset_left = -60
	btn.offset_top = -70
	btn.offset_right = 60
	btn.offset_bottom = -12
	btn.button_down.connect(func(): set_meta("hold", true))
	btn.button_up.connect(func(): set_meta("hold", false))
	add_child(btn)

func play_round(fish_id: String) -> void:
	_fish_id = fish_id
	_pos = randf()
	_dir = 1.0 if randf() < 0.5 else -1.0
	_zone_w = 0.24 - 0.02 * RanchWeather.skill_level("fishing")
	_zone = randf_range(0.15, 0.85 - _zone_w)
	_ok_time = 0.0
	_time_left = 4.0
	_running = true
	visible = true
	get_tree().paused = true
	Sfx.play("water", 1.0, -10.0)

func _process(delta: float) -> void:
	if not _running:
		return
	_pos += _dir * delta * 0.6
	if _pos > 1.0 or _pos < 0.0:
		_dir = -_dir
		_pos = clampf(_pos, 0.0, 1.0)
	_time_left -= delta
	var in_zone := _pos >= _zone and _pos <= _zone + _zone_w
	var holding := Input.is_action_pressed("interact") or Input.is_action_pressed("use_tool") or bool(get_meta("hold", false))
	if in_zone and holding:
		_ok_time += delta
	else:
		_ok_time = maxf(0.0, _ok_time - delta * 0.5)
	if tip:
		tip.text = "按住「起竿」停在亮条内 %.1fs / 1.0s（剩余 %.1fs）" % [_ok_time, maxf(_time_left, 0.0)]
	queue_redraw()
	if _ok_time >= 1.0:
		_finish(true)
	elif _time_left <= 0.0:
		_finish(false)

func _finish(ok: bool) -> void:
	_running = false
	visible = false
	get_tree().paused = false
	if not ok:
		EventBus.toast.emit("鱼跑了……下次再来。")
		return
	Sfx.play("harvest", 0.85)
	MuseumDb.mark_discover(_fish_id)
	RanchWeather.add_exp("fishing", 3)
	if _fish_id == "legend_fish":
		Achievements.set_stat("legend_fish", 1)
	if Inventory.add_item(_fish_id, 1):
		EventBus.toast.emit("钓到了：%s！" % ItemDb.item_name(_fish_id))
	else:
		EventBus.toast.emit("背包满了！")

func _draw() -> void:
	if not _running:
		return
	var y := 48.0
	draw_rect(Rect2(30, y, 360, 16), Color(0.1, 0.1, 0.1, 0.4))
	draw_rect(Rect2(30 + 360 * _zone, y, 360 * _zone_w, 16), Color(0.55, 0.85, 0.55, 0.9))
	draw_rect(Rect2(30 + 360 * _pos - 2, y - 5, 4, 26), Color("#E8C87A"))
