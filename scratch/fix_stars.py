path = "c:/Users/zahid/Documents/py-quest/scripts/ui/LevelSelectUI.gd"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

helper = """func _get_stars_dict() -> Dictionary:
	var raw_stars = SaveManager.user_profile.get("level_stars", {})
	if typeof(raw_stars) == TYPE_DICTIONARY:
		return raw_stars
	elif typeof(raw_stars) == TYPE_ARRAY:
		var converted: Dictionary = {}
		for idx in range(raw_stars.size()):
			converted[str(idx + 1)] = int(raw_stars[idx])
		return converted
	return {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}

func build_map()"""

content = content.replace("func build_map()", helper, 1)
content = content.replace(
    'var stars_dict: Dictionary = SaveManager.user_profile.get("level_stars", {})',
    'var stars_dict: Dictionary = _get_stars_dict()'
)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("SUCCESS: Updated LevelSelectUI.gd with _get_stars_dict()")

