import os
import re

# 1. Update World 1
def update_world1():
    path = "scripts/world/World1.gd"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    # Update NPCS_DATA portraits
    code = code.replace(
        '"icon": "🌾",\n\t\t"xp": 40,',
        '"icon": "🌾",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_farmer.png",\n\t\t"xp": 40,'
    )
    code = code.replace(
        '"icon": "🏹",\n\t\t"xp": 40,',
        '"icon": "🏹",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_alex.png",\n\t\t"xp": 40,'
    )
    code = code.replace(
        '"icon": "🔨",\n\t\t"xp": 40,',
        '"icon": "🔨",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_engineer.png",\n\t\t"xp": 40,'
    )

    # Add helper function _update_dialog_speaker
    helper = """func _update_dialog_speaker(icon_str: String, name_str: String, portrait_path: String) -> void:
	if not quest_dialog:
		return
	var s_icon = quest_dialog.find_child("SpeakerIcon", true, false) as Label
	var s_name = quest_dialog.find_child("SpeakerName", true, false) as Label
	var s_port = quest_dialog.find_child("SpeakerPortrait", true, false) as TextureRect
	if s_icon: s_icon.text = icon_str
	if s_name: s_name.text = name_str
	if s_port and ResourceLoader.exists(portrait_path):
		s_port.texture = load(portrait_path)
		s_port.pivot_offset = s_port.size / 2.0
		s_port.scale = Vector2(0.85, 0.85)
		var p_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(s_port, "scale", Vector2.ONE, 0.28)

"""
    if "_update_dialog_speaker" not in code:
        code = code.replace("func _on_npc_interacted(npc_id: String) -> void:\n", helper + "func _on_npc_interacted(npc_id: String) -> void:\n")

    # Update NPC speaker assignment in _on_npc_interacted
    old_npc_speaker = """\tvar speaker_icon = quest_dialog.get_node_or_null("Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon") as Label
\tvar speaker_name = quest_dialog.get_node_or_null("Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName") as Label
\tif speaker_icon:
\t\tspeaker_icon.text = n_data["icon"]
\tif speaker_name:
\t\tspeaker_name.text = n_data["name"]"""

    new_npc_speaker = """\t_update_dialog_speaker(n_data["icon"], n_data["name"], n_data.get("portrait", "res://assets/sprites/portraits/portrait_npc_scholar.png"))"""
    code = code.replace(old_npc_speaker, new_npc_speaker)

    # Update Boss Gate speaker assignment in open_quest_dialog
    old_boss_speaker = """\tvar speaker_icon = quest_dialog.get_node_or_null("Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon") as Label
\tvar speaker_name = quest_dialog.get_node_or_null("Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName") as Label
\tif speaker_icon:
\t\tspeaker_icon.text = "🧙‍♂️"
\tif speaker_name:
\t\tspeaker_name.text = "Master PyWizard • Guardian of the Final Shrine"\t"""

    # We can match more loosely if needed
    code = re.sub(
        r'var speaker_icon = quest_dialog\.get_node_or_null\([^\)]+\) as Label\n\tvar speaker_name = quest_dialog\.get_node_or_null\([^\)]+\) as Label\n\tif speaker_icon:\n\t\tspeaker_icon\.text = "🧙‍♂️"\n\tif speaker_name:\n\t\tspeaker_name\.text = "Master PyWizard • Guardian of the Final Shrine"',
        r'''var cleared = _get_cleared_shrines()
\tvar raw_stars = SaveManager.user_profile.get("level_stars", {})
\tvar stars: int = 0
\tif typeof(raw_stars) == TYPE_DICTIONARY:
\t\tstars = int(raw_stars.get("1", 0))
\telif typeof(raw_stars) == TYPE_ARRAY and raw_stars.size() > 0:
\t\tstars = int(raw_stars[0])

\tif stars > 0 or cleared.size() >= 3:
\t\t_update_dialog_speaker("👾", "NullByte • The Glitched Obsidian Golem", "res://assets/sprites/portraits/portrait_nullbyte.png")
\telse:
\t\t_update_dialog_speaker("🧙‍♂️", "Master PyWizard • Guardian of the Final Shrine", "res://assets/sprites/portraits/portrait_pywizard.png")''',
        code
    )

    with open(path, "w", encoding="utf-8") as f:
        f.write(code)
    print("Updated World1.gd")

# 2. Update World 2
def update_world2():
    path = "scripts/world/World2.gd"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    code = code.replace(
        '"icon": "🔧",\n\t\t"xp": 50,',
        '"icon": "🔧",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_engineer.png",\n\t\t"xp": 50,'
    )
    code = code.replace(
        '"icon": "⏳",\n\t\t"xp": 50,',
        '"icon": "⏳",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_scholar.png",\n\t\t"xp": 50,'
    )
    code = code.replace(
        '"icon": "🛡️",\n\t\t"xp": 50,',
        '"icon": "🛡️",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_engineer.png",\n\t\t"xp": 50,'
    )

    helper = """func _update_dialog_speaker(icon_str: String, name_str: String, portrait_path: String) -> void:
	if not quest_dialog:
		return
	var s_icon = quest_dialog.find_child("SpeakerIcon", true, false) as Label
	var s_name = quest_dialog.find_child("SpeakerName", true, false) as Label
	var s_port = quest_dialog.find_child("SpeakerPortrait", true, false) as TextureRect
	if s_icon: s_icon.text = icon_str
	if s_name: s_name.text = name_str
	if s_port and ResourceLoader.exists(portrait_path):
		s_port.texture = load(portrait_path)
		s_port.pivot_offset = s_port.size / 2.0
		s_port.scale = Vector2(0.85, 0.85)
		var p_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(s_port, "scale", Vector2.ONE, 0.28)

"""
    if "_update_dialog_speaker" not in code:
        code = code.replace("func _on_npc_interacted(npc_id: String) -> void:\n", helper + "func _on_npc_interacted(npc_id: String) -> void:\n")

    old_npc_speaker = """\tvar speaker_icon = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon") as Label
\tvar speaker_name = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName") as Label
\tif speaker_icon:
\t\tspeaker_icon.text = data["icon"]
\tif speaker_name:
\t\tspeaker_name.text = data["name"]"""

    new_npc_speaker = """\t_update_dialog_speaker(data["icon"], data["name"], data.get("portrait", "res://assets/sprites/portraits/portrait_npc_engineer.png"))"""
    code = code.replace(old_npc_speaker, new_npc_speaker)

    old_boss_pattern = r'var speaker_icon = get_node_or_null\("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon"\) as Label\n\tvar speaker_name = get_node_or_null\("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName"\) as Label\n\tif speaker_icon:\n\t\tspeaker_icon\.text = "🧙‍♂️"\n\tif speaker_name:\n\t\tspeaker_name\.text = "Master PyWizard • Guardian of the Final Seal"'
    
    new_boss = """var cleared = _get_cleared_shrines()
\tvar count = cleared.size()
\tif count >= 3:
\t\t_update_dialog_speaker("⏳", "Chronos-If • The Infinite Loop Warden", "res://assets/sprites/portraits/portrait_chronos.png")
\telse:
\t\t_update_dialog_speaker("🧙‍♂️", "Master PyWizard • Guardian of the Final Seal", "res://assets/sprites/portraits/portrait_pywizard.png")"""
    code = re.sub(old_boss_pattern, new_boss, code)

    with open(path, "w", encoding="utf-8") as f:
        f.write(code)
    print("Updated World2.gd")

# 3. Update World 3
def update_world3():
    path = "scripts/world/World3.gd"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    code = code.replace(
        '"icon": "📜",\n\t\t"xp": 50,',
        '"icon": "📜",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_scholar.png",\n\t\t"xp": 50,'
    )
    code = code.replace(
        '"icon": "⚙️",\n\t\t"xp": 50,',
        '"icon": "⚙️",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_engineer.png",\n\t\t"xp": 50,'
    )
    code = code.replace(
        '"icon": "🔮",\n\t\t"xp": 50,',
        '"icon": "🔮",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_scholar.png",\n\t\t"xp": 50,'
    )

    helper = """func _update_dialog_speaker(icon_str: String, name_str: String, portrait_path: String) -> void:
	if not quest_dialog:
		return
	var s_icon = quest_dialog.find_child("SpeakerIcon", true, false) as Label
	var s_name = quest_dialog.find_child("SpeakerName", true, false) as Label
	var s_port = quest_dialog.find_child("SpeakerPortrait", true, false) as TextureRect
	if s_icon: s_icon.text = icon_str
	if s_name: s_name.text = name_str
	if s_port and ResourceLoader.exists(portrait_path):
		s_port.texture = load(portrait_path)
		s_port.pivot_offset = s_port.size / 2.0
		s_port.scale = Vector2(0.85, 0.85)
		var p_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(s_port, "scale", Vector2.ONE, 0.28)

"""
    if "_update_dialog_speaker" not in code:
        code = code.replace("func _on_npc_interacted(npc_id: String) -> void:\n", helper + "func _on_npc_interacted(npc_id: String) -> void:\n")

    old_npc_speaker = """\tvar speaker_icon = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon") as Label
\tvar speaker_name = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName") as Label
\tif speaker_icon:
\t\tspeaker_icon.text = data["icon"]
\tif speaker_name:
\t\tspeaker_name.text = data["name"]"""

    new_npc_speaker = """\t_update_dialog_speaker(data["icon"], data["name"], data.get("portrait", "res://assets/sprites/portraits/portrait_npc_scholar.png"))"""
    code = code.replace(old_npc_speaker, new_npc_speaker)

    old_boss_pattern = r'var speaker_icon = get_node_or_null\("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon"\) as Label\n\tvar speaker_name = get_node_or_null\("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName"\) as Label\n\tif speaker_icon:\n\t\tspeaker_icon\.text = "🧙‍♂️"\n\tif speaker_name:\n\t\tspeaker_name\.text = "Master PyWizard • Guardian of the Final Seal"'

    new_boss = """var cleared = _get_cleared_shrines()
\tvar count = cleared.size()
\tif count >= 3:
\t\t_update_dialog_speaker("🔮", "Lambda-Prime • The Modular Relic Sovereign", "res://assets/sprites/portraits/portrait_lambda.png")
\telse:
\t\t_update_dialog_speaker("🧙‍♂️", "Master PyWizard • Guardian of the Arcane Sanctum", "res://assets/sprites/portraits/portrait_pywizard.png")"""
    code = re.sub(old_boss_pattern, new_boss, code)

    with open(path, "w", encoding="utf-8") as f:
        f.write(code)
    print("Updated World3.gd")

# 4. Update World 4
def update_world4():
    path = "scripts/world/World4.gd"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    code = code.replace(
        '"icon": "🗝️",\n\t\t"xp": 50,',
        '"icon": "🗝️",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_scholar.png",\n\t\t"xp": 50,'
    )
    code = code.replace(
        '"icon": "🏺",\n\t\t"xp": 50,',
        '"icon": "🏺",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_engineer.png",\n\t\t"xp": 50,'
    )
    code = code.replace(
        '"icon": "🔮",\n\t\t"xp": 50,',
        '"icon": "🔮",\n\t\t"portrait": "res://assets/sprites/portraits/portrait_npc_scholar.png",\n\t\t"xp": 50,'
    )

    helper = """func _update_dialog_speaker(icon_str: String, name_str: String, portrait_path: String) -> void:
	if not quest_dialog:
		return
	var s_icon = quest_dialog.find_child("SpeakerIcon", true, false) as Label
	var s_name = quest_dialog.find_child("SpeakerName", true, false) as Label
	var s_port = quest_dialog.find_child("SpeakerPortrait", true, false) as TextureRect
	if s_icon: s_icon.text = icon_str
	if s_name: s_name.text = name_str
	if s_port and ResourceLoader.exists(portrait_path):
		s_port.texture = load(portrait_path)
		s_port.pivot_offset = s_port.size / 2.0
		s_port.scale = Vector2(0.85, 0.85)
		var p_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(s_port, "scale", Vector2.ONE, 0.28)

"""
    if "_update_dialog_speaker" not in code:
        code = code.replace("func _on_npc_interacted(npc_id: String) -> void:\n", helper + "func _on_npc_interacted(npc_id: String) -> void:\n")

    old_npc_speaker = """\tvar speaker_icon = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon") as Label
\tvar speaker_name = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName") as Label
\tif speaker_icon:
\t\tspeaker_icon.text = data["icon"]
\tif speaker_name:
\t\tspeaker_name.text = data["name"]"""

    new_npc_speaker = """\t_update_dialog_speaker(data["icon"], data["name"], data.get("portrait", "res://assets/sprites/portraits/portrait_npc_scholar.png"))"""
    code = code.replace(old_npc_speaker, new_npc_speaker)

    old_boss_pattern = r'var speaker_icon = get_node_or_null\("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon"\) as Label\n\tvar speaker_name = get_node_or_null\("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName"\) as Label\n\tif speaker_icon:\n\t\tspeaker_icon\.text = "🧙‍♂️"\n\tif speaker_name:\n\t\tspeaker_name\.text = "Master PyWizard • Guardian of the Final Seal"'

    new_boss = """var cleared = _get_cleared_shrines()
\tvar count = cleared.size()
\tif count >= 3:
\t\t_update_dialog_speaker("🏺", "Vektor-Zero • The Catacomb Sequence Lich", "res://assets/sprites/portraits/portrait_vektor.png")
\telse:
\t\t_update_dialog_speaker("🧙‍♂️", "Master PyWizard • Guardian of the Crypt Sanctum", "res://assets/sprites/portraits/portrait_pywizard.png")"""
    code = re.sub(old_boss_pattern, new_boss, code)

    with open(path, "w", encoding="utf-8") as f:
        f.write(code)
    print("Updated World4.gd")

# 5. Update GameplayUI
def update_gameplay_ui():
    path = "scripts/ui/GameplayUI.gd"
    with open(path, "r", encoding="utf-8") as f:
        code = f.read()

    old_hint = """\thint_modal_overlay.visible = true

func _on_close_hint_pressed() -> void:"""

    new_hint = """\thint_modal_overlay.visible = true
\tvar hint_card = hint_modal_overlay.find_child("HintCard", true, false) as Control
\tif hint_card:
\t\thint_card.scale = Vector2(0.92, 0.92)
\t\thint_card.pivot_offset = hint_card.size / 2.0
\t\tvar tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
\t\ttw.tween_property(hint_card, "scale", Vector2.ONE, 0.25)
\tvar wiz_port = hint_modal_overlay.find_child("SpeakerPortrait", true, false) as TextureRect
\tif wiz_port:
\t\twiz_port.scale = Vector2(0.85, 0.85)
\t\twiz_port.pivot_offset = wiz_port.size / 2.0
\t\tvar p_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
\t\tp_tw.tween_property(wiz_port, "scale", Vector2.ONE, 0.28)

func _on_close_hint_pressed() -> void:"""

    code = code.replace(old_hint, new_hint)
    with open(path, "w", encoding="utf-8") as f:
        f.write(code)
    print("Updated GameplayUI.gd")

if __name__ == "__main__":
    update_world1()
    update_world2()
    update_world3()
    update_world4()
    update_gameplay_ui()
