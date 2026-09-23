extends "res://scripts/entities/interactable.gd"
class_name Workbench
## 合成站：工作台 / 厨房 / 木工 / 铜炉 / 晶灯工坊

@export var station := "workbench"

const STATION_META := {
	"workbench": ["工作台", "#A67C52"],
	"kitchen": ["厨房", "#E8C87A"],
	"carpentry": ["木工坊", "#B8956C"],
	"forge": ["铜炉", "#C07840"],
	"crystal_atelier": ["晶灯工坊", "#A0E0E8"],
}

func _ready() -> void:
	var meta: Array = STATION_META.get(station, ["工作台", "#A67C52"])
	display_name = meta[0]
	color = Color(meta[1])
	size = Vector2(32, 24)
	super._ready()

func interact(_player: Node) -> void:
	get_tree().call_group("craft_ui", "open_station", station)

func prompt() -> String:
	return "E：%s（C：合成）" % display_name

func _art_tex() -> Texture2D:
	var map := {
		"workbench": "building_workbench",
		"kitchen": "building_workbench",
		"carpentry": "building_workbench",
		"forge": "building_windmill",
		"crystal_atelier": "building_belltower",
	}
	var key: String = map.get(station, "building_workbench")
	return ArtPipeline.tex(key)
