extends CharacterBody2D
class_name MineEnemy
## 轻量敌人：游荡 + 接触伤害 + 可被敲打

signal died(enemy: MineEnemy)

var type_id := "slime"
var hp := 3
var max_hp := 3
var touch_damage := 1
var speed := 40.0
var body_color := Color("#7BC96F")
var body_size := 14.0
var loot: Dictionary = {}

var _dir := Vector2.RIGHT
var _wander_t := 0.0
var _hit_flash := 0.0

func setup(p_type: String, data: Dictionary) -> void:
	type_id = p_type
	hp = int(data.get("hp", 3))
	max_hp = hp
	touch_damage = int(data.get("touch_damage", 1))
	speed = float(data.get("speed", 40))
	body_color = Color.html(str(data.get("color", "#7BC96F")))
	body_size = float(data.get("size", 14))
	loot = data.get("loot", {})

func _physics_process(delta: float) -> void:
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_t = randf_range(0.6, 1.8)
		var angle := randf() * TAU
		_dir = Vector2(cos(angle), sin(angle))
	velocity = _dir * speed
	move_and_slide()
	# 撞墙则换向
	if get_slide_collision_count() > 0:
		_dir = -_dir
	_hit_flash = maxf(0.0, _hit_flash - delta)
	queue_redraw()

func hit(damage: int = 1) -> void:
	hp -= damage
	_hit_flash = 0.15
	Sfx.play("hit")
	queue_redraw()
	if hp <= 0:
		_drop_loot()
		died.emit(self)
		queue_free()

func _drop_loot() -> void:
	for id in loot:
		var chance: float = 0.7 if int(loot[id]) > 0 else 0.15
		if randf() < chance:
			Inventory.add_item(str(id), maxi(1, int(loot[id])))
			EventBus.toast.emit("掉落：%s" % ItemDb.item_name(str(id)))
	if randf() < 0.08:
		Inventory.add_item("wind_shard", 1)
		GameState.wind_shards += 1
		EventBus.toast.emit("晶核里嵌着风铃碎片！")

func _draw() -> void:
	var c := body_color
	if _hit_flash > 0.0:
		c = Color.WHITE
	draw_circle(Vector2.ZERO, body_size * 0.5, c)
	draw_circle(Vector2.ZERO, body_size * 0.5, c.darkened(0.35), false, 2.0)
	# 眼睛
	draw_circle(Vector2(-4, -3), 2.0, Color("#1A2418"))
	draw_circle(Vector2(4, -3), 2.0, Color("#1A2418"))
	# 血条
	if hp < max_hp:
		draw_rect(Rect2(-12, -body_size * 0.5 - 8, 24, 3), Color(0, 0, 0, 0.4))
		draw_rect(Rect2(-12, -body_size * 0.5 - 8, 24.0 * float(hp) / float(max_hp), 3), Color("#E05555"))
