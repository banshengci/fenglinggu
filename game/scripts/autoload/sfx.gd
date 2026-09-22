extends Node
## 轻量音效：程序化波形，无需外部资源
## 风铃 / 收获 / 翻地 / 受伤 / 确认

var _cache: Dictionary = {}
var _player: AudioStreamPlayer
var _player2: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player2 = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player2.bus = "Master"
	add_child(_player)
	add_child(_player2)
	_build_all()

func play(id: String, pitch: float = 1.0, volume_db: float = -6.0) -> void:
	var stream: AudioStreamWAV = _cache.get(id)
	if stream == null:
		return
	var p := _player if not _player.playing else _player2
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()

func _build_all() -> void:
	_cache["bell"] = _tone_chord([880.0, 1320.0, 1760.0], 0.7, 0.35)
	_cache["harvest"] = _tone_chord([523.25, 659.25, 783.99], 0.22, 0.5)
	_cache["till"] = _noise_burst(0.08, 0.4)
	_cache["water"] = _tone_chord([300.0, 240.0], 0.15, 0.3)
	_cache["hit"] = _tone_chord([180.0, 120.0], 0.1, 0.55)
	_cache["hurt"] = _tone_chord([140.0, 90.0], 0.18, 0.5)
	_cache["coin"] = _tone_chord([988.0, 1319.0], 0.12, 0.4)
	_cache["click"] = _tone_chord([660.0], 0.05, 0.35)
	_cache["step"] = _noise_burst(0.03, 0.15)
	_cache["chop"] = _tone_chord([220.0, 165.0], 0.08, 0.4)

func _tone_chord(freqs: Array, duration: float, decay: float) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(rate)
		var env := exp(-t * (1.0 / maxf(0.05, duration * decay * 4.0)))
		var s := 0.0
		for f in freqs:
			s += sin(TAU * float(f) * t)
		s = s / float(freqs.size()) * env * 0.45
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	return _wrap(data, rate)

func _noise_burst(duration: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(samples)
		var env := 1.0 - t
		var s := (randf() * 2.0 - 1.0) * env * amp
		data.encode_s16(i * 2, int(s * 32767.0))
	return _wrap(data, rate)

func _wrap(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

## 绑定全局反馈
func bind_events() -> void:
	EventBus.toast.connect(func(_m): pass)
