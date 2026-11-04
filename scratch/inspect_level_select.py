import re

with open("c:/Users/zahid/Documents/py-quest/scenes/ui/LevelSelect.tscn", "r", encoding="utf-8") as f:
    text = f.read()

sub_res = re.findall(r'\[sub_resource type="([^"]+)" id="([^"]+)"\]', text)
print("Sub-resources:")
for s in sub_res:
    print(" -", s)

nodes = re.findall(r'\[node name="([^"]+)" type="([^"]+)"(?: parent="([^"]+)")?[^\]]*\]', text)
print("\nNodes:")
for n in nodes:
    print(" -", n)

