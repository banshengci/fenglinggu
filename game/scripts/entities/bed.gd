extends "res://scripts/entities/interactable.gd"
class_name Bed
## 床：睡觉跨天并存档

func _ready() -> void:
	display_name = "床（睡觉进入第二天）"
	color = Color("#6B8F5A")
	size = Vector2(40, 28)
	super._ready()

func interact(_player: Node) -> void:
	SaveSystem.save_game(0)
	SaveSystem.save_auto()
	EventBus.toast.emit("你躺下休息……")
	Sfx.play("bell", 0.8, -10.0)
	QuestLog.mark("sleep")
	TimeSystem.force_sleep()

func prompt() -> String:
	return "E：睡觉（自动存档并到第二天）"

func _art_tex() -> Texture2D:
	return ArtPipeline.tex("building_bed")
