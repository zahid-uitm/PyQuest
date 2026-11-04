path = "c:/Users/zahid/Documents/py-quest/scripts/ui/LevelSelectUI.gd"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

target = """func _get_stars_dict() -> Dictionary:
	var raw_stars = SaveManager.user_profile.get("level_stars", {})
	if typeof(raw_stars) == TYPE_DICTIONARY:
		return raw_stars
	elif typeof(raw_stars) == TYPE_ARRAY:
		var converted: Dictionary = {}
		for idx in range(raw_stars.size()):
			converted[str(idx + 1)] = int(raw_stars[idx])
		return converted
	return {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}"""

replacement = """func _get_stars_dict() -> Dictionary:
	var raw_stars = SaveManager.user_profile.get("level_stars", {})
	var converted: Dictionary = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
	if typeof(raw_stars) == TYPE_DICTIONARY:
		for k in raw_stars.keys():
			var v = raw_stars[k]
			if v != null and (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT):
				converted[str(k)] = int(v)
	elif typeof(raw_stars) == TYPE_ARRAY:
		var arr: Array = raw_stars
		var is_one_indexed: bool = arr.size() > 0 and arr[0] == null
		for idx in range(arr.size()):
			var item = arr[idx]
			if item != null and (typeof(item) == TYPE_INT or typeof(item) == TYPE_FLOAT):
				var lvl_key = str(idx) if is_one_indexed else str(idx + 1)
				converted[lvl_key] = int(item)
	return converted"""

if target in content:
    content = content.replace(target, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("SUCCESS: Updated LevelSelectUI.gd with null-safe _get_stars_dict()")
else:
    print("Target not found!")

