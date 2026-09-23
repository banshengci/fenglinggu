extends PanelContainer
## 杂货摊：限宽滚动 + 关闭钮

@onready var title_label: Label = %ShopTitleLabel
@onready var money_label: Label = %ShopMoneyLabel
@onready var list_box: VBoxContainer = %ShopListBox
@onready var hint_label: Label = %ShopHintLabel

var _close_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("shop_ui")
	visible = false
	EventBus.money_changed.connect(func(_m): _refresh_money())
	custom_minimum_size = Vector2(520, 440)
	_build_chrome()

func _build_chrome() -> void:
	var top := get_node_or_null("VBox")
	if top == null:
		return
	var bar := HBoxContainer.new()
	top.add_child(bar)
	top.move_child(bar, 0)
	if title_label and title_label.get_parent() == top:
		top.remove_child(title_label)
		bar.add_child(title_label)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_btn = Button.new()
	_close_btn.text = "关闭"
	_close_btn.custom_minimum_size = Vector2(88, 40)
	_close_btn.pressed.connect(close_shop)
	bar.add_child(_close_btn)
	if list_box and list_box.get_parent():
		var parent := list_box.get_parent()
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(480, 300)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		parent.add_child(scroll)
		parent.remove_child(list_box)
		list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list_box)

func open_shop() -> void:
	visible = true
	get_tree().paused = true
	rebuild()
	if _close_btn:
		_close_btn.grab_focus()

func close_shop() -> void:
	visible = false
	if get_tree().paused:
		get_tree().paused = false

func toggle() -> void:
	if visible:
		close_shop()
	else:
		open_shop()

func _refresh_money() -> void:
	if money_label:
		money_label.text = "谷币 %d" % Inventory.money

func rebuild() -> void:
	title_label.text = "杂货摊 · %s" % TimeSystem.season()
	hint_label.text = "点击购买 · 关闭 / Esc 退出"
	_refresh_money()
	for c in list_box.get_children():
		c.queue_free()
	var rows := ShopDb.visible_stock(TimeSystem.season())
	if rows.is_empty():
		var l := Label.new()
		l.text = "今日无货。"
		list_box.add_child(l)
		return
	for row in rows:
		var item := str(row.get("item", ""))
		var price := int(row.get("price", 0))
		var btn := Button.new()
		btn.text = "%s  —  %d 谷币" % [ItemDb.item_name(item), price]
		btn.tooltip_text = ItemDb.get_desc(item)
		btn.custom_minimum_size = Vector2(460, 40)
		btn.disabled = Inventory.money < price
		btn.pressed.connect(_buy.bind(row))
		list_box.add_child(btn)
	for a in RanchWeather.animal_defs():
		var aid := str(a.get("id", ""))
		var btn2 := Button.new()
		btn2.text = "牧场：%s  —  %d 谷币" % [str(a.get("name", aid)), int(a.get("buy_price", 0))]
		btn2.custom_minimum_size = Vector2(460, 40)
		btn2.disabled = Inventory.money < int(a.get("buy_price", 0))
		btn2.pressed.connect(_buy_animal.bind(aid))
		list_box.add_child(btn2)

func _buy(row: Dictionary) -> void:
	ShopDb.buy(row)
	rebuild()

func _buy_animal(aid: String) -> void:
	RanchWeather.buy_animal(aid)
	rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") \
		or event.is_action_pressed("interact") \
		or event.is_action_pressed("use_tool"):
		close_shop()
		get_viewport().set_input_as_handled()
