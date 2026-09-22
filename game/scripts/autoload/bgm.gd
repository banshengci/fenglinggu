extends Node
## 背景音乐：程序化循环垫底 + 可选昼夜变奏

var _players: Array = []
var _current_id := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -18.0
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	EventBus.day_started.connect(func(_d, _s): refresh_from_time())
	EventBus.time_changed.connect(func(_h, _m): pass)

func play_track(id: String) -> void:
	if _current_id == id:
		return
	_current_id = id
	var stream := _build_stream(id)
	var a: AudioStreamPlayer = _players[0]
	var b: AudioStreamPlayer = _players[1]
	var target := b if a.playing else a
	var other := a if target == b else b
	target.stream = stream
	target.volume_db = -16.0
	target.play()
	var tw := create_tween()
	tw.tween_property(target, "volume_db", -14.0, 0.8)
	if other.playing:
		tw2_fade_out(other)

func tw2_fade_out(p: AudioStreamPlayer) -> void:
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -40.0, 0.8)
	tw.tween_callback(p.stop)

func refresh_from_time() -> void:
	var area := "town"
	var am := get_tree().get_first_node_in_group("area_manager")
	if am and "current_area" in am:
		area = str(am.current_area)
	if area == "mine":
		play_track("mine")
		return
	var h := TimeSystem.hour
	if h >= 19 or h < 5:
		play_track("night")
	else:
		play_track("town")

func _build_stream(id: String) -> AudioStreamWAV:
	# 简易琶音垫：每轨不同音阶
	var patterns := {
		"town": [329.63, 392.0, 493.88, 392.0],
		"night": [220.0, 261.63, 329.63, 261.63],
		"mine": [146.83, 174.61, 220.0, 164.81],
	}
	var notes: Array = patterns.get(id, patterns["town"])
	var rate := 11025
	var duration := 4.0
	var samples := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(rate)
		var idx := int(floor(t / 0.5)) % notes.size()
		var f := float(notes[idx])
		var env := 0.35 + 0.2 * sin(TAU * 0.25 * t)
		var s := 0.0
		s += sin(TAU * f * t) * 0.35
		s += sin(TAU * f * 2.0 * t) * 0.12
		s += sin(TAU * (f * 0.5) * t) * 0.18
		# soft pulse
		s *= env
		data.encode_s16(i * 2, int(clampf(s, -1, 1) * 20000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples
	return wav
