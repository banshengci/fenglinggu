extends Control
## 目标追踪条（左上）

@onready var quest_label: Label = %QuestLabel
@onready var progress_label: Label = %ProgressLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	QuestLog.objectives_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if quest_label:
		quest_label.text = "目标：" + QuestLog.current_text()
	if progress_label:
		progress_label.text = QuestLog.progress()
