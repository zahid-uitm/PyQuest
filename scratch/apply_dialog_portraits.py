import os
import re

def update_world_tscn(path, world_num, boss_name):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add SubResource for portrait frame if not present
    if 'id="StyleBoxFlat_portrait_frame"' not in content:
        sub_res = """[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_portrait_frame"]
content_margin_left = 6.0
content_margin_top = 6.0
content_margin_right = 6.0
content_margin_bottom = 6.0
bg_color = Color(0.05, 0.08, 0.16, 0.96)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.96, 0.62, 0.04, 0.9)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12
shadow_color = Color(0, 0, 0, 0.6)
shadow_size = 6
shadow_offset = Vector2(0, 3)

"""
        # Insert before first sub_resource
        pos = content.find('[sub_resource')
        if pos != -1:
            content = content[:pos] + sub_res + content[pos:]

    # 2. Add ExtResource for default portrait if not present
    if 'portrait_pywizard.png' not in content:
        ext_res = '[ext_resource type="Texture2D" path="res://assets/sprites/portraits/portrait_pywizard.png" id="portrait_pywizard_res"]\n'
        pos = content.rfind('[ext_resource')
        end_line = content.find('\n', pos) + 1
        content = content[:end_line] + ext_res + content[end_line:]

    # 3. Update DialogCard structure
    old_card_pattern = r'(\[node name="DialogCard" type="PanelContainer" parent="UILayer/QuestDialogModal/Center"[^\]]*\]\n)(custom_minimum_size = Vector2\([^\)]*\)\nlayout_mode = 2\ntheme_override_styles/panel = SubResource\("[^"]*"\)\n\n)(\[node name="DialogVBox" type="VBoxContainer" parent="UILayer/QuestDialogModal/Center/DialogCard"[^\]]*\])'
    
    match = re.search(old_card_pattern, content)
    if match:
        card_header = match.group(1)
        dialog_vbox_line = match.group(3)
        # Extract unique_id if present
        vbox_uid = ""
        uid_m = re.search(r'unique_id=(\d+)', dialog_vbox_line)
        if uid_m:
            vbox_uid = f' unique_id={uid_m.group(1)}'

        new_structure = f"""{card_header}custom_minimum_size = Vector2(660, 0)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_dialog_card")

[node name="DialogHBox" type="HBoxContainer" parent="UILayer/QuestDialogModal/Center/DialogCard"]
layout_mode = 2
theme_override_constants/separation = 18

[node name="PortraitFrame" type="PanelContainer" parent="UILayer/QuestDialogModal/Center/DialogCard/DialogHBox"]
custom_minimum_size = Vector2(116, 116)
layout_mode = 2
size_flags_vertical = 0
theme_override_styles/panel = SubResource("StyleBoxFlat_portrait_frame")

[node name="SpeakerPortrait" type="TextureRect" parent="UILayer/QuestDialogModal/Center/DialogCard/DialogHBox/PortraitFrame"]
unique_name_in_owner = true
custom_minimum_size = Vector2(104, 104)
layout_mode = 2
texture = ExtResource("portrait_pywizard_res")
expand_mode = 1
stretch_mode = 5

[node name="DialogVBox" type="VBoxContainer" parent="UILayer/QuestDialogModal/Center/DialogCard/DialogHBox"{vbox_uid}]"""

        content = content[:match.start()] + new_structure + content[match.end():]
        # Also fix any parent references for child nodes that had parent="UILayer/QuestDialogModal/Center/DialogCard/DialogVBox"
        content = content.replace(
            'parent="UILayer/QuestDialogModal/Center/DialogCard/DialogVBox"',
            'parent="UILayer/QuestDialogModal/Center/DialogCard/DialogHBox/DialogVBox"'
        )
        print(f"Updated {path} structure successfully.")
    else:
        print(f"DialogCard pattern already updated or not matched in {path}")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


def update_level_gameplay_tscn():
    path = "scenes/ui/LevelGameplay.tscn"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'id="StyleBoxFlat_portrait_frame"' not in content:
        sub_res = """[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_portrait_frame"]
content_margin_left = 6.0
content_margin_top = 6.0
content_margin_right = 6.0
content_margin_bottom = 6.0
bg_color = Color(0.05, 0.08, 0.16, 0.96)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.38, 0.65, 0.98, 0.9)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12
shadow_color = Color(0, 0, 0, 0.6)
shadow_size = 6
shadow_offset = Vector2(0, 3)

"""
        pos = content.find('[sub_resource')
        if pos != -1:
            content = content[:pos] + sub_res + content[pos:]

    if 'portrait_pywizard.png' not in content:
        ext_res = '[ext_resource type="Texture2D" path="res://assets/sprites/portraits/portrait_pywizard.png" id="portrait_pywizard_res"]\n'
        pos = content.rfind('[ext_resource')
        end_line = content.find('\n', pos) + 1
        content = content[:end_line] + ext_res + content[end_line:]

    old_pattern = r'(\[node name="HintCard" type="PanelContainer" parent="HintModalOverlay/Center"\]\n)(custom_minimum_size = Vector2\([^\)]*\)\nlayout_mode = 2\ntheme_override_styles/panel = SubResource\("[^"]*"\)\n\n)(\[node name="HintVBox" type="VBoxContainer" parent="HintModalOverlay/Center/HintCard"\])'
    match = re.search(old_pattern, content)
    if match:
        new_structure = """[node name="HintCard" type="PanelContainer" parent="HintModalOverlay/Center"]
custom_minimum_size = Vector2(660, 0)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_modal_card")

[node name="HintHBox" type="HBoxContainer" parent="HintModalOverlay/Center/HintCard"]
layout_mode = 2
theme_override_constants/separation = 18

[node name="PortraitFrame" type="PanelContainer" parent="HintModalOverlay/Center/HintCard/HintHBox"]
custom_minimum_size = Vector2(116, 116)
layout_mode = 2
size_flags_vertical = 0
theme_override_styles/panel = SubResource("StyleBoxFlat_portrait_frame")

[node name="SpeakerPortrait" type="TextureRect" parent="HintModalOverlay/Center/HintCard/HintHBox/PortraitFrame"]
unique_name_in_owner = true
custom_minimum_size = Vector2(104, 104)
layout_mode = 2
texture = ExtResource("portrait_pywizard_res")
expand_mode = 1
stretch_mode = 5

[node name="HintVBox" type="VBoxContainer" parent="HintModalOverlay/Center/HintCard/HintHBox"]"""

        content = content[:match.start()] + new_structure + content[match.end():]
        content = content.replace(
            'parent="HintModalOverlay/Center/HintCard/HintVBox"',
            'parent="HintModalOverlay/Center/HintCard/HintHBox/HintVBox"'
        )
        print("Updated LevelGameplay.tscn structure successfully.")
    else:
        print("HintCard pattern already updated or not matched in LevelGameplay.tscn")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


if __name__ == "__main__":
    bosses = {
        1: "nullbyte",
        2: "chronos",
        3: "lambda",
        4: "vektor"
    }
    for w, b in bosses.items():
        update_world_tscn(f"scenes/world/World{w}.tscn", w, b)
    update_level_gameplay_tscn()
