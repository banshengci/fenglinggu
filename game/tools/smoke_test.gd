extends SceneTree
## 独立冒烟测试（不依赖 autoload）
## 运行: Godot --headless --path game -s res://tools/smoke_test.gd

func _init() -> void:
	var errors: PackedStringArray = []

	var items = _load_json("res://data/items.json", errors)
	var crops = _load_json("res://data/crops.json", errors)
	var recipes = _load_json("res://data/recipes.json", errors)
	var npcs = _load_json("res://data/npcs.json", errors)

	for id in items:
		if str(items[id].get("name", "")) == "":
			errors.append("items.%s 缺 name" % id)

	for id in crops:
		var c = crops[id]
		var product = str(c.get("product_item", ""))
		var seed_id = str(c.get("seed_item", ""))
		if not items.has(product):
			errors.append("crops.%s product 缺失" % id)
		if not items.has(seed_id):
			errors.append("crops.%s seed 缺失" % id)
		# 模拟生长
		var days := int(c.get("days_to_grow", 0))
		var growth := 0
		var watered := true
		for d in days + 2:
			if watered:
				growth += 1
			if growth >= days:
				break
		if growth < days:
			errors.append("crops.%s 生长规则异常" % id)

	for id in recipes:
		var r = recipes[id]
		if not items.has(str(r.get("output", ""))):
			errors.append("recipes.%s output 缺失" % id)
		var inputs = r.get("inputs", {})
		for mat in inputs:
			if not items.has(str(mat)):
				errors.append("recipes.%s 材料 %s 缺失" % [id, mat])

	for id in npcs:
		if str(npcs[id].get("name", "")) == "":
			errors.append("npcs.%s 缺 name" % id)

	for tool in ["hoe", "watering_can", "wood_axe", "stone_pick", "seed_turnip", "seed_potato"]:
		if not items.has(tool):
			errors.append("开局物资缺失: " + tool)

	if errors.is_empty():
		print("SMOKE OK")
		quit(0)
	else:
		print("SMOKE FAIL:")
		for e in errors:
			print("  - ", e)
		quit(1)

func _load_json(path: String, errors: PackedStringArray):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		errors.append("无法读取 " + path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null:
		errors.append("JSON 解析失败 " + path)
		return {}
	return parsed
