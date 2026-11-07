import zlib
import struct
import math
import os

def save_png(path, width, height, rgba_bytes):
    def make_chunk(chunk_type, data):
        chunk = struct.pack('>I', len(data)) + chunk_type + data
        crc = zlib.crc32(chunk_type + data) & 0xffffffff
        return chunk + struct.pack('>I', crc)

    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    raw_data = bytearray()
    stride = width * 4
    for y in range(height):
        raw_data.append(0)
        raw_data.extend(rgba_bytes[y * stride:(y + 1) * stride])
    idat = zlib.compress(bytes(raw_data), 9)

    png = b'\x89PNG\r\n\x1a\n' + make_chunk(b'IHDR', ihdr) + make_chunk(b'IDAT', idat) + make_chunk(b'IEND', b'')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(png)

class Canvas:
    def __init__(self, w=128, h=128):
        self.w = w
        self.h = h
        self.buf = bytearray(w * h * 4)

    def set_px(self, x, y, color):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            idx = (y * self.w + x) * 4
            r, g, b = color[0], color[1], color[2]
            a = color[3] if len(color) > 3 else 255
            if a == 255 or self.buf[idx + 3] == 0:
                self.buf[idx] = r
                self.buf[idx + 1] = g
                self.buf[idx + 2] = b
                self.buf[idx + 3] = a
            elif a > 0:
                sa = a / 255.0
                da = self.buf[idx + 3] / 255.0
                out_a = sa + da * (1.0 - sa)
                if out_a > 0:
                    self.buf[idx] = int((r * sa + self.buf[idx] * da * (1.0 - sa)) / out_a)
                    self.buf[idx + 1] = int((g * sa + self.buf[idx + 1] * da * (1.0 - sa)) / out_a)
                    self.buf[idx + 2] = int((b * sa + self.buf[idx + 2] * da * (1.0 - sa)) / out_a)
                    self.buf[idx + 3] = int(out_a * 255)

    def rect(self, x0, y0, w, h, color, outline=None):
        x0, y0, w, h = int(round(x0)), int(round(y0)), int(round(w)), int(round(h))
        for dy in range(h):
            for dx in range(w):
                if outline and (dx == 0 or dx == w - 1 or dy == 0 or dy == h - 1):
                    self.set_px(x0 + dx, y0 + dy, outline)
                else:
                    self.set_px(x0 + dx, y0 + dy, color)

    def ellipse(self, cx, cy, rx, ry, color, outline=None):
        cx, cy = float(cx), float(cy)
        rx, ry = float(rx), float(ry)
        if rx <= 0 or ry <= 0: return
        for y in range(int(cy - ry - 2), int(cy + ry + 3)):
            for x in range(int(cx - rx - 2), int(cx + rx + 3)):
                nx = (x - cx) / rx
                ny = (y - cy) / ry
                d = nx * nx + ny * ny
                if d <= 1.0:
                    if outline and d >= 0.75:
                        self.set_px(x, y, outline)
                    else:
                        self.set_px(x, y, color)

    def circle(self, cx, cy, r, color, outline=None):
        self.ellipse(cx, cy, r, r, color, outline)

    def line(self, x0, y0, x1, y1, color, thickness=1):
        steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(steps + 1):
            t = i / float(steps)
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            if thickness <= 1:
                self.set_px(x, y, color)
            else:
                rad = thickness / 2.0
                for dy in range(int(-rad), int(rad) + 1):
                    for dx in range(int(-rad), int(rad) + 1):
                        if dx*dx + dy*dy <= rad*rad + 0.5:
                            self.set_px(x + dx, y + dy, color)

    def glow(self, cx, cy, radius, color, max_alpha=160):
        r, g, b = color[0], color[1], color[2]
        for y in range(int(cy - radius), int(cy + radius + 1)):
            for x in range(int(cx - radius), int(cx + radius + 1)):
                d = math.hypot(x - cx, y - cy)
                if d <= radius:
                    factor = 1.0 - (d / radius)
                    a = int(max_alpha * (factor ** 1.8))
                    if a > 0:
                        self.set_px(x, y, (r, g, b, a))

    def polygon(self, points, color, outline=None):
        # Scanline polygon fill
        if len(points) < 3: return
        min_y = max(0, int(min(p[1] for p in points)))
        max_y = min(self.h - 1, int(max(p[1] for p in points)))
        n = len(points)
        for y in range(min_y, max_y + 1):
            nodes = []
            for i in range(n):
                p1 = points[i]
                p2 = points[(i + 1) % n]
                if (p1[1] <= y < p2[1]) or (p2[1] <= y < p1[1]):
                    if p2[1] != p1[1]:
                        x = p1[0] + (y - p1[1]) * (p2[0] - p1[0]) / (p2[1] - p1[1])
                        nodes.append(x)
            nodes.sort()
            for i in range(0, len(nodes) - 1, 2):
                x_start = max(0, int(math.ceil(nodes[i])))
                x_end = min(self.w - 1, int(math.floor(nodes[i + 1])))
                for x in range(x_start, x_end + 1):
                    self.set_px(x, y, color)
        if outline:
            for i in range(n):
                p1 = points[i]
                p2 = points[(i + 1) % n]
                self.line(p1[0], p1[1], p2[0], p2[1], outline, 1)

# Base background vignette for portraits
def draw_portrait_background(c, theme_dark, theme_light, sigil="circle"):
    # Circular medallion background
    c.circle(64, 64, 62, (15, 12, 28, 255), (80, 65, 120, 255))
    c.circle(64, 64, 58, theme_dark)
    c.glow(64, 52, 45, theme_light, 90)
    # Subtle runic ring
    for deg in range(0, 360, 15):
        rad = math.radians(deg)
        x = 64 + math.cos(rad) * 54
        y = 64 + math.sin(rad) * 54
        c.set_px(x, y, (theme_light[0], theme_light[1], theme_light[2], 120))

# ------------------------------------------------------------------------------
# 1. MASTER PYWIZARD (Wise elder sage, flowing beard, starry hat & spectacles)
# ------------------------------------------------------------------------------
def render_pywizard():
    c = Canvas(128, 128)
    draw_portrait_background(c, (18, 24, 58, 255), (96, 165, 250, 255))

    # Robes and Shoulders
    c.polygon([(18, 127), (40, 92), (88, 92), (110, 127)], (28, 48, 110, 255), (15, 25, 65, 255))
    c.polygon([(36, 92), (64, 127), (92, 92)], (38, 70, 150, 255))
    # Golden starry collar trim
    c.line(40, 92, 64, 122, (245, 158, 11, 255), 2)
    c.line(88, 92, 64, 122, (245, 158, 11, 255), 2)
    c.circle(64, 120, 4, (254, 240, 138, 255), (180, 83, 9, 255))

    # Face & Skin
    SKIN_SHADOW = (212, 140, 105, 255)
    SKIN = (245, 185, 145, 255)
    SKIN_LIGHT = (255, 215, 185, 255)
    c.ellipse(64, 66, 22, 24, SKIN, SKIN_SHADOW)
    c.ellipse(64, 62, 19, 18, SKIN_LIGHT)
    # Cheeks & Nose
    c.circle(50, 72, 6, (235, 140, 125, 100))
    c.circle(78, 72, 6, (235, 140, 125, 100))
    c.ellipse(64, 68, 5, 6, SKIN_SHADOW)
    c.circle(64, 67, 4, SKIN)

    # Silver-white flowing beard and mustache
    BEARD_DARK = (180, 195, 215, 255)
    BEARD = (235, 242, 250, 255)
    BEARD_LIGHT = (255, 255, 255, 255)
    # Mustache sweeps
    c.polygon([(42, 75), (64, 73), (56, 85)], BEARD, BEARD_DARK)
    c.polygon([(86, 75), (64, 73), (72, 85)], BEARD, BEARD_DARK)
    c.ellipse(64, 74, 9, 4, BEARD_LIGHT)
    # Flowing long beard
    c.polygon([(38, 80), (64, 125), (90, 80)], BEARD, BEARD_DARK)
    c.polygon([(46, 82), (64, 120), (82, 82)], BEARD_LIGHT)
    # Beard strand details
    c.line(58, 84, 62, 115, BEARD_DARK, 1)
    c.line(70, 84, 66, 115, BEARD_DARK, 1)

    # Kind twinkling blue eyes
    c.ellipse(52, 60, 4, 3, (255, 255, 255, 255))
    c.ellipse(76, 60, 4, 3, (255, 255, 255, 255))
    c.circle(53, 60, 2, (37, 99, 235, 255))
    c.circle(75, 60, 2, (37, 99, 235, 255))
    c.set_px(54, 59, (255, 255, 255, 255))
    c.set_px(76, 59, (255, 255, 255, 255))
    # Eyebrows
    c.line(44, 54, 58, 55, BEARD, 3)
    c.line(84, 54, 70, 55, BEARD, 3)

    # Golden spectacles
    c.ellipse(52, 60, 7, 6, (0, 0, 0, 0), (245, 158, 11, 255))
    c.ellipse(76, 60, 7, 6, (0, 0, 0, 0), (245, 158, 11, 255))
    c.line(59, 60, 69, 60, (245, 158, 11, 255), 2)
    # Lens glint
    c.line(49, 58, 51, 56, (255, 255, 255, 180), 1)
    c.line(73, 58, 75, 56, (255, 255, 255, 180), 1)

    # Pointed Wizard Hat
    HAT_DARK = (15, 25, 65, 255)
    HAT = (30, 55, 125, 255)
    HAT_LIGHT = (45, 80, 165, 255)
    GOLD = (245, 158, 11, 255)
    # Wide brim
    c.ellipse(64, 48, 44, 12, HAT, HAT_DARK)
    c.ellipse(64, 46, 40, 10, HAT_LIGHT)
    # Golden hat band
    c.ellipse(64, 44, 25, 7, GOLD, (160, 80, 10, 255))
    c.circle(64, 42, 5, (254, 240, 138, 255), GOLD)
    # Tall crooked cone
    c.polygon([(40, 43), (64, 8), (88, 43)], HAT, HAT_DARK)
    c.polygon([(46, 42), (64, 12), (76, 42)], HAT_LIGHT)
    # Crooked tip bending right
    c.polygon([(60, 14), (76, 6), (68, 18)], HAT, HAT_DARK)
    c.circle(76, 6, 3, (254, 240, 138, 255), GOLD)
    # Celestial stars on hat
    for sx, sy in [(56, 26), (68, 32), (62, 38)]:
        c.set_px(sx, sy, (254, 240, 138, 255))
        c.set_px(sx - 1, sy, (245, 158, 11, 200))
        c.set_px(sx + 1, sy, (245, 158, 11, 200))
        c.set_px(sx, sy - 1, (245, 158, 11, 200))
        c.set_px(sx, sy + 1, (245, 158, 11, 200))

    # Floating arcane cyan Python spark
    c.glow(26, 45, 12, (56, 189, 248, 255), 180)
    c.circle(26, 45, 3, (255, 255, 255, 255))

    return c

# ------------------------------------------------------------------------------
# 2. ADVENTURER ALEX (Young hero, spiky brown hair, confident smirk, tunic)
# ------------------------------------------------------------------------------
def render_alex():
    c = Canvas(128, 128)
    draw_portrait_background(c, (14, 38, 32, 255), (16, 185, 129, 255))

    # Shoulders and Leather/Teal Armor Tunic
    c.polygon([(18, 127), (38, 96), (90, 96), (110, 127)], (20, 80, 105, 255), (10, 40, 55, 255))
    # Bronze pauldrons
    c.ellipse(32, 106, 14, 10, (180, 115, 35, 255), (120, 70, 18, 255))
    c.ellipse(96, 106, 14, 10, (180, 115, 35, 255), (120, 70, 18, 255))
    # Chest collar & tunic fold
    c.polygon([(46, 96), (64, 120), (82, 96)], (235, 220, 190, 255), (180, 160, 130, 255))
    c.polygon([(52, 96), (64, 115), (76, 96)], (35, 115, 145, 255))

    # Neck
    c.rect(55, 78, 18, 20, (215, 145, 110, 255))

    # Face & Jawline
    SKIN_SHADOW = (215, 145, 110, 255)
    SKIN = (250, 195, 160, 255)
    SKIN_LIGHT = (255, 222, 195, 255)
    c.polygon([(44, 52), (84, 52), (76, 86), (64, 94), (52, 86)], SKIN, SKIN_SHADOW)
    c.ellipse(64, 65, 18, 16, SKIN_LIGHT)
    # Nose & confident mouth smirk
    c.line(64, 62, 66, 73, SKIN_SHADOW, 2)
    c.line(62, 73, 67, 73, SKIN_SHADOW, 2)
    # Confident lopsided smirk
    c.line(56, 81, 72, 80, (140, 60, 50, 255), 2)
    c.line(70, 80, 74, 77, (140, 60, 50, 255), 2)

    # Expressive Amber/Hazel Eyes
    c.ellipse(51, 62, 6, 4, (255, 255, 255, 255), (120, 60, 30, 255))
    c.ellipse(77, 62, 6, 4, (255, 255, 255, 255), (120, 60, 30, 255))
    c.circle(52, 62, 3, (180, 110, 30, 255))
    c.circle(76, 62, 3, (180, 110, 30, 255))
    c.set_px(53, 61, (255, 255, 255, 255))
    c.set_px(77, 61, (255, 255, 255, 255))
    # Determined eyebrows
    c.line(44, 55, 58, 57, (90, 45, 20, 255), 3)
    c.line(84, 55, 70, 57, (90, 45, 20, 255), 3)

    # Spiky Adventurer Brown Hair
    HAIR_DARK = (70, 35, 15, 255)
    HAIR = (115, 65, 30, 255)
    HAIR_LIGHT = (165, 95, 45, 255)
    # Sideburns
    c.polygon([(38, 52), (44, 74), (48, 54)], HAIR, HAIR_DARK)
    c.polygon([(90, 52), (84, 74), (80, 54)], HAIR, HAIR_DARK)
    # Big anime adventurer spikes
    c.polygon([(36, 52), (28, 34), (46, 40)], HAIR, HAIR_DARK)
    c.polygon([(42, 38), (44, 20), (58, 30)], HAIR, HAIR_DARK)
    c.polygon([(52, 28), (64, 14), (74, 28)], HAIR_LIGHT, HAIR_DARK)
    c.polygon([(70, 28), (84, 18), (86, 38)], HAIR, HAIR_DARK)
    c.polygon([(82, 36), (100, 32), (92, 52)], HAIR, HAIR_DARK)
    # Fringe / bangs over forehead
    c.polygon([(46, 44), (54, 52), (58, 44)], HAIR_LIGHT, HAIR_DARK)
    c.polygon([(58, 44), (66, 54), (70, 44)], HAIR, HAIR_DARK)
    c.polygon([(70, 44), (78, 52), (82, 44)], HAIR_LIGHT, HAIR_DARK)

    # Green adventurer feather / token pin
    c.line(34, 48, 24, 30, (16, 185, 129, 255), 3)
    c.circle(34, 48, 3, (245, 158, 11, 255))

    return c

# ------------------------------------------------------------------------------
# 3. NULLBYTE (World 1 Boss - Horned Obsidian War-Golem, Crimson Visor)
# ------------------------------------------------------------------------------
def render_nullbyte():
    c = Canvas(128, 128)
    draw_portrait_background(c, (26, 14, 34, 255), (244, 63, 94, 255))

    STONE_DARK = (24, 18, 38, 255)
    STONE_MID = (48, 36, 72, 255)
    STONE_LIGHT = (82, 64, 116, 255)
    GLITCH_RED = (255, 30, 86, 255)
    GLITCH_PINK = (255, 110, 165, 255)
    GLITCH_MAG = (192, 38, 211, 255)
    GLITCH_CYAN = (0, 245, 212, 255)

    # Massive Spiked Shoulders & Chest
    c.polygon([(8, 127), (26, 86), (102, 86), (120, 127)], STONE_MID, STONE_DARK)
    # Spiked obsidian pauldrons
    c.polygon([(6, 110), (14, 76), (38, 86), (30, 118)], STONE_LIGHT, STONE_DARK)
    c.line(14, 76, 4, 60, STONE_DARK, 4)
    c.line(14, 76, 5, 62, GLITCH_RED, 2)

    c.polygon([(122, 110), (114, 76), (90, 86), (98, 118)], STONE_LIGHT, STONE_DARK)
    c.line(114, 76, 124, 60, STONE_DARK, 4)
    c.line(114, 76, 123, 62, GLITCH_RED, 2)

    # Core in chest
    c.circle(64, 114, 14, GLITCH_RED, GLITCH_MAG)
    c.circle(64, 114, 8, GLITCH_PINK)
    c.circle(64, 114, 3, (255, 255, 255, 255))

    # Golem Neck & Collar
    c.rect(48, 72, 32, 20, STONE_DARK)
    c.line(48, 80, 80, 80, GLITCH_MAG, 2)

    # Giant Horned Obsidian War Helmet
    c.polygon([(40, 40), (88, 40), (84, 82), (64, 90), (44, 82)], STONE_MID, STONE_DARK)
    c.polygon([(44, 42), (84, 42), (78, 54), (50, 54)], STONE_LIGHT)

    # Giant Curved War Horns
    c.polygon([(40, 48), (18, 22), (28, 18), (44, 38)], STONE_DARK)
    c.polygon([(42, 46), (22, 24), (28, 20), (44, 38)], STONE_MID)
    c.line(28, 18, 16, 10, GLITCH_RED, 3)

    c.polygon([(88, 48), (110, 22), (100, 18), (84, 38)], STONE_DARK)
    c.polygon([(86, 46), (106, 24), (100, 20), (84, 38)], STONE_MID)
    c.line(100, 18, 112, 10, GLITCH_RED, 3)

    # Central Spiked Crown Crest
    c.polygon([(56, 38), (64, 16), (72, 38)], STONE_LIGHT, STONE_DARK)
    c.set_px(64, 22, GLITCH_RED)

    # Crimson Cyclops Visor Slit
    c.rect(44, 56, 40, 10, (15, 4, 18, 255), STONE_DARK)
    c.glow(64, 61, 14, GLITCH_RED, 180)
    c.rect(46, 58, 36, 6, GLITCH_RED)
    c.rect(58, 59, 12, 4, GLITCH_PINK)
    c.rect(62, 60, 4, 2, (255, 255, 255, 255))

    # Heavy Iron Grill Jaw
    c.rect(50, 70, 28, 14, STONE_DARK)
    for gx in range(54, 76, 4):
        c.line(gx, 70, gx, 84, STONE_LIGHT, 2)

    # Floating glitch cubes
    c.rect(18, 40, 6, 6, GLITCH_CYAN, STONE_DARK)
    c.rect(104, 46, 6, 6, GLITCH_RED, STONE_DARK)

    return c

# ------------------------------------------------------------------------------
# 4. CHRONOS-IF (World 2 Boss - Clockwork Seraph, Astrolabe Halo, Cyan Visor)
# ------------------------------------------------------------------------------
def render_chronos():
    c = Canvas(128, 128)
    draw_portrait_background(c, (10, 28, 52, 255), (56, 189, 248, 255))

    GOLD_DARK = (161, 98, 7, 255)
    GOLD = (245, 158, 11, 255)
    GOLD_LIGHT = (254, 240, 138, 255)
    ARMOR_DARK = (16, 38, 68, 255)
    ARMOR_MID = (28, 66, 110, 255)
    ARMOR_LIGHT = (56, 116, 178, 255)
    CYAN = (0, 240, 255, 255)
    WHITE = (235, 252, 255, 255)

    # Golden Astrolabe / Clockwork Gear Halo behind head
    c.ellipse(64, 52, 42, 42, (0, 0, 0, 0), GOLD)
    c.ellipse(64, 52, 38, 38, (0, 0, 0, 0), GOLD_DARK)
    for deg in range(0, 360, 30):
        rad = math.radians(deg)
        gx = 64 + math.cos(rad) * 42
        gy = 52 + math.sin(rad) * 42
        c.rect(gx - 2, gy - 2, 5, 5, GOLD_LIGHT, GOLD_DARK)

    # Cyan Energy Feathered Wings flanking shoulders
    for side in (-1, 1):
        wx = 64 + side * 36
        c.line(wx, 80, wx + side * 22, 42, CYAN, 6)
        c.line(wx, 80, wx + side * 22, 42, WHITE, 2)
        c.line(wx, 88, wx + side * 24, 62, (56, 189, 248, 200), 5)

    # Shoulders and Celestial Bronze Armor
    c.polygon([(16, 127), (36, 88), (92, 88), (112, 127)], ARMOR_MID, ARMOR_DARK)
    c.polygon([(30, 88), (48, 84), (54, 110), (32, 116)], GOLD, GOLD_DARK)
    c.polygon([(98, 88), (80, 84), (74, 110), (96, 116)], GOLD, GOLD_DARK)

    # Glowing Cyan Hourglass Core in chest
    c.polygon([(56, 102), (72, 102), (64, 112)], CYAN, GOLD)
    c.polygon([(56, 122), (72, 122), (64, 112)], CYAN, GOLD)
    c.set_px(64, 112, WHITE)

    # Clockwork Mask / Archon Faceplate
    c.polygon([(46, 42), (82, 42), (76, 82), (64, 90), (52, 82)], ARMOR_DARK, (8, 20, 38, 255))
    c.polygon([(50, 44), (78, 44), (74, 76), (64, 82), (54, 76)], GOLD, GOLD_DARK)

    # Tall Golden Sunburst Crown
    c.polygon([(48, 42), (44, 20), (54, 38)], GOLD_LIGHT, GOLD_DARK)
    c.polygon([(58, 38), (64, 12), (70, 38)], GOLD_LIGHT, GOLD_DARK)
    c.polygon([(74, 38), (84, 20), (80, 42)], GOLD_LIGHT, GOLD_DARK)

    # Cyan Glowing Temporal Visor Slit
    c.rect(50, 56, 28, 8, (6, 20, 38, 255), GOLD_DARK)
    c.glow(64, 60, 12, CYAN, 180)
    c.rect(52, 58, 24, 4, CYAN)
    c.rect(60, 59, 8, 2, WHITE)

    # Roman numeral / Clock face etchings
    c.line(64, 68, 64, 80, GOLD_DARK, 2)
    c.line(58, 74, 70, 74, GOLD_DARK, 1)

    return c

# ------------------------------------------------------------------------------
# 5. LAMBDA-PRIME (World 3 Boss - Relic Sovereign, 3 Eyes, Crown & λ Sigil)
# ------------------------------------------------------------------------------
def render_lambda():
    c = Canvas(128, 128)
    draw_portrait_background(c, (28, 12, 52, 255), (192, 132, 252, 255))

    ROBE_DARK = (38, 16, 72, 255)
    ROBE_MID = (76, 29, 149, 255)
    ROBE_LIGHT = (124, 58, 237, 255)
    GOLD_DARK = (180, 83, 9, 255)
    GOLD = (245, 158, 11, 255)
    GOLD_BRIGHT = (253, 224, 71, 255)
    MAGENTA_GLOW = (244, 114, 182, 255)
    VIOLET_GLOW = (216, 180, 254, 255)

    # 3 Orbiting Glowing Parameter Spheres
    for i, (ox, oy) in enumerate([(24, 40), (104, 40), (64, 18)]):
        c.glow(ox, oy, 14, MAGENTA_GLOW if i == 0 else VIOLET_GLOW, 180)
        c.circle(ox, oy, 6, MAGENTA_GLOW if i == 0 else ROBE_LIGHT, GOLD_BRIGHT)
        c.circle(ox, oy, 2, (255, 255, 255, 255))

    # High Arcane Collar behind head
    c.polygon([(26, 84), (40, 48), (64, 60), (88, 48), (102, 84)], ROBE_DARK, GOLD)

    # Robes and Royal Mantle
    c.polygon([(16, 127), (36, 86), (92, 86), (112, 127)], ROBE_MID, ROBE_DARK)
    c.line(36, 86, 64, 127, GOLD, 2)
    c.line(92, 86, 64, 127, GOLD, 2)

    # Golden Lambda (λ) Brooch / Sigil on chest
    c.line(58, 98, 70, 118, GOLD_BRIGHT, 4)
    c.line(64, 108, 58, 118, GOLD, 4)
    c.glow(64, 110, 10, GOLD_BRIGHT, 140)

    # Dark Void Hooded Cowl
    c.polygon([(40, 46), (88, 46), (84, 84), (64, 90), (44, 84)], (14, 6, 26, 255), (8, 3, 16, 255))
    c.polygon([(44, 46), (84, 46), (78, 52), (50, 52)], ROBE_LIGHT)

    # Towering 3-Spired Sovereign Crown
    c.polygon([(46, 46), (42, 22), (54, 42)], GOLD, GOLD_DARK)
    c.polygon([(56, 42), (64, 14), (72, 42)], GOLD_BRIGHT, GOLD_DARK)
    c.polygon([(74, 42), (86, 22), (82, 46)], GOLD, GOLD_DARK)
    c.circle(64, 16, 3, MAGENTA_GLOW)

    # Void Face with 3 Glowing Eldritch Eyes
    # Two lower eyes
    c.ellipse(54, 68, 5, 4, MAGENTA_GLOW, (18, 4, 30, 255))
    c.ellipse(74, 68, 5, 4, MAGENTA_GLOW, (18, 4, 30, 255))
    c.circle(54, 68, 2, (255, 255, 255, 255))
    c.circle(74, 68, 2, (255, 255, 255, 255))
    # Third eye on forehead
    c.ellipse(64, 58, 4, 3, VIOLET_GLOW, (18, 4, 30, 255))
    c.set_px(64, 58, (255, 255, 255, 255))

    return c

# ------------------------------------------------------------------------------
# 6. VEKTOR-ZERO (World 4 Boss - Sequence Lich, Nemes Headdress, Skull, Soul-Fire)
# ------------------------------------------------------------------------------
def render_vektor():
    c = Canvas(128, 128)
    draw_portrait_background(c, (10, 32, 24, 255), (16, 185, 129, 255))

    BONE_DARK = (148, 163, 184, 255)
    BONE = (226, 232, 240, 255)
    BONE_BRIGHT = (248, 250, 252, 255)
    GOLD = (245, 158, 11, 255)
    GOLD_BRIGHT = (253, 224, 71, 255)
    LAPIS = (30, 58, 138, 255)
    SOUL_GREEN = (16, 185, 129, 255)
    SOUL_BRIGHT = (110, 231, 183, 255)

    # Exposed Skeletal Spine & Ribcage bathed in Emerald Soul Fire
    c.polygon([(18, 127), (38, 92), (90, 92), (110, 127)], (20, 28, 38, 255), (10, 15, 22, 255))
    c.glow(64, 110, 16, SOUL_GREEN, 180)
    # White bone ribs
    for ry in [98, 106, 114, 122]:
        c.line(50, ry, 78, ry, BONE_BRIGHT, 2)
    c.line(64, 92, 64, 127, BONE, 4)

    # Pharaonic Broad Collar (Usekh) in Gold & Lapis Lazuli
    c.polygon([(36, 88), (64, 102), (92, 88)], GOLD, LAPIS)
    for cx_col in range(40, 88, 6):
        c.line(cx_col, 88, 64, 102, LAPIS, 2)

    # Egyptian Nemes Royal Headdress (Striped Gold & Lapis)
    c.polygon([(26, 78), (44, 40), (84, 40), (102, 78), (92, 92), (78, 86), (64, 90), (50, 86), (36, 92)], GOLD, (10, 15, 22, 255))
    # Blue lapis stripes
    for sy in range(44, 86, 6):
        c.line(30, sy, 98, sy, LAPIS, 3)

    # Golden Cobra (Uraeus) on forehead
    c.rect(62, 26, 4, 14, GOLD_BRIGHT, GOLD)
    c.circle(64, 26, 3, SOUL_BRIGHT)

    # Bleached Humanoid Lich Skull Face
    c.polygon([(46, 48), (82, 48), (78, 72), (72, 82), (56, 82), (50, 72)], BONE, BONE_DARK)
    c.ellipse(64, 56, 16, 10, BONE_BRIGHT)
    # Nasal cavity
    c.polygon([(62, 68), (66, 68), (64, 63)], (15, 20, 28, 255))
    # Grinning teeth row
    c.rect(56, 74, 16, 6, (15, 20, 28, 255))
    for tx in range(58, 72, 3):
        c.line(tx, 74, tx, 80, BONE_BRIGHT, 1)

    # Blazing Emerald Soul-Fire Eye Sockets
    c.ellipse(54, 58, 6, 5, (10, 16, 22, 255))
    c.ellipse(74, 58, 6, 5, (10, 16, 22, 255))
    c.glow(54, 58, 8, SOUL_GREEN, 220)
    c.glow(74, 58, 8, SOUL_GREEN, 220)
    c.circle(54, 58, 2, SOUL_BRIGHT)
    c.circle(74, 58, 2, SOUL_BRIGHT)

    # Floating Index Glyphs [0] [1]
    c.rect(14, 38, 12, 10, (12, 24, 20, 255), SOUL_GREEN)
    c.rect(102, 38, 12, 10, (12, 24, 20, 255), SOUL_GREEN)

    return c

# ------------------------------------------------------------------------------
# 7. NPC SCHOLAR / ARCHIVIST / ALCHEMIST (Versatile NPC Portrait)
# ------------------------------------------------------------------------------
def render_npc_scholar():
    c = Canvas(128, 128)
    draw_portrait_background(c, (38, 28, 18, 255), (245, 158, 11, 255))

    # Scholar's Vest & Collared Shirt
    c.polygon([(18, 127), (38, 96), (90, 96), (110, 127)], (85, 55, 30, 255), (50, 30, 15, 255))
    c.polygon([(46, 96), (64, 120), (82, 96)], (240, 230, 205, 255))
    c.circle(64, 114, 3, (180, 120, 40, 255))

    # Face & Skin
    SKIN = (245, 190, 155, 255)
    c.ellipse(64, 68, 20, 22, SKIN, (200, 140, 105, 255))
    c.line(64, 64, 66, 74, (190, 130, 95, 255), 2)
    # Gentle smile
    c.line(58, 80, 70, 80, (140, 70, 50, 255), 2)

    # Friendly eyes
    c.ellipse(52, 64, 5, 4, (255, 255, 255, 255), (100, 60, 30, 255))
    c.ellipse(76, 64, 5, 4, (255, 255, 255, 255), (100, 60, 30, 255))
    c.circle(53, 64, 2, (70, 120, 80, 255))
    c.circle(75, 64, 2, (70, 120, 80, 255))

    # Scholar Monocle on right eye
    c.circle(76, 64, 7, (0, 0, 0, 0), (245, 158, 11, 255))
    c.line(83, 64, 90, 84, (245, 158, 11, 255), 1)

    # Scholarly Cap & Brown Hair
    c.ellipse(64, 46, 28, 12, (60, 40, 25, 255), (35, 22, 12, 255))
    c.polygon([(44, 46), (64, 28), (84, 46)], (120, 75, 40, 255), (60, 40, 25, 255))
    c.circle(84, 46, 4, (245, 158, 11, 255))

    return c

# ------------------------------------------------------------------------------
# 8. NPC ENGINEER / WEAVER / GUARDIAN (Versatile Craftsperson Portrait)
# ------------------------------------------------------------------------------
def render_npc_engineer():
    c = Canvas(128, 128)
    draw_portrait_background(c, (16, 32, 42, 255), (56, 189, 248, 255))

    # Leather apron & workshirt
    c.polygon([(18, 127), (38, 96), (90, 96), (110, 127)], (60, 75, 90, 255), (30, 45, 60, 255))
    c.polygon([(44, 102), (84, 102), (80, 127), (48, 127)], (160, 95, 40, 255), (100, 55, 20, 255))

    # Face & Skin with soot smudge
    SKIN = (235, 175, 140, 255)
    c.ellipse(64, 68, 20, 22, SKIN, (190, 130, 95, 255))
    c.circle(52, 74, 4, (90, 75, 70, 80)) # Soot mark on cheek
    c.line(64, 64, 66, 74, (180, 120, 85, 255), 2)
    c.line(58, 81, 70, 81, (130, 65, 45, 255), 2)

    # Keen eyes
    c.ellipse(52, 64, 5, 4, (255, 255, 255, 255), (80, 50, 25, 255))
    c.ellipse(76, 64, 5, 4, (255, 255, 255, 255), (80, 50, 25, 255))
    c.circle(53, 64, 2, (30, 130, 180, 255))
    c.circle(75, 64, 2, (30, 130, 180, 255))

    # Brass Goggles on forehead
    c.rect(40, 44, 48, 5, (100, 60, 30, 255))
    c.ellipse(52, 46, 9, 8, (180, 120, 40, 255), (100, 60, 20, 255))
    c.ellipse(76, 46, 9, 8, (180, 120, 40, 255), (100, 60, 20, 255))
    c.ellipse(52, 46, 6, 5, (56, 189, 248, 200))
    c.ellipse(76, 46, 6, 5, (56, 189, 248, 200))

    # Messy dark hair
    c.polygon([(36, 48), (28, 36), (46, 40)], (45, 30, 25, 255))
    c.polygon([(46, 38), (56, 26), (68, 38)], (45, 30, 25, 255))
    c.polygon([(68, 38), (80, 28), (92, 44)], (45, 30, 25, 255))

    return c

# ------------------------------------------------------------------------------
# 9. NPC FARMER (Farmer Bob - Straw Hat, Sun-Tanned, Wheat Stalk, Country Vest)
# ------------------------------------------------------------------------------
def render_npc_farmer():
    c = Canvas(128, 128)
    draw_portrait_background(c, (20, 36, 18, 255), (132, 204, 22, 255))

    # Green farmer vest over linen shirt
    c.polygon([(18, 127), (38, 96), (90, 96), (110, 127)], (34, 85, 45, 255), (18, 50, 26, 255))
    c.polygon([(46, 96), (64, 120), (82, 96)], (245, 240, 220, 255))
    # Red neckerchief
    c.polygon([(52, 96), (64, 108), (76, 96)], (220, 38, 38, 255), (150, 20, 20, 255))

    # Face & Skin (Sun-tanned)
    SKIN = (230, 165, 125, 255)
    c.ellipse(64, 68, 20, 22, SKIN, (185, 120, 85, 255))
    c.circle(52, 74, 5, (220, 130, 110, 90)) # Rosy cheeks
    c.circle(76, 74, 5, (220, 130, 110, 90))
    c.line(64, 63, 65, 73, (180, 115, 80, 255), 2)
    # Broad happy grin
    c.line(54, 80, 74, 80, (130, 55, 40, 255), 3)
    c.line(56, 80, 72, 84, (255, 255, 255, 255), 2)

    # Friendly hazel eyes
    c.ellipse(52, 63, 5, 4, (255, 255, 255, 255), (80, 50, 25, 255))
    c.ellipse(76, 63, 5, 4, (255, 255, 255, 255), (80, 50, 25, 255))
    c.circle(53, 63, 2, (100, 60, 20, 255))
    c.circle(75, 63, 2, (100, 60, 20, 255))

    # Golden Wheat Stalk in mouth
    c.line(56, 82, 38, 92, (234, 179, 8, 255), 2)
    for wy in [88, 92, 96]:
        c.ellipse(38, wy, 3, 2, (250, 204, 21, 255), (161, 98, 7, 255))

    # Wide-Brimmed Straw Hat
    STRAW = (234, 179, 8, 255)
    STRAW_DARK = (161, 98, 7, 255)
    STRAW_LIGHT = (253, 224, 71, 255)
    # Brim
    c.ellipse(64, 46, 46, 14, STRAW, STRAW_DARK)
    c.ellipse(64, 44, 42, 11, STRAW_LIGHT)
    # Hat band (dark green)
    c.ellipse(64, 42, 24, 6, (22, 101, 52, 255))
    # Crown of hat
    c.polygon([(42, 42), (50, 20), (78, 20), (86, 42)], STRAW, STRAW_DARK)
    c.polygon([(46, 40), (52, 24), (74, 24), (82, 40)], STRAW_LIGHT)

    return c


# ------------------------------------------------------------------------------
# Build and Output all Portraits
# ------------------------------------------------------------------------------
portraits = [
    ("portrait_pywizard.png", render_pywizard()),
    ("portrait_alex.png", render_alex()),
    ("portrait_nullbyte.png", render_nullbyte()),
    ("portrait_chronos.png", render_chronos()),
    ("portrait_lambda.png", render_lambda()),
    ("portrait_vektor.png", render_vektor()),
    ("portrait_npc_farmer.png", render_npc_farmer()),
    ("portrait_npc_scholar.png", render_npc_scholar()),
    ("portrait_npc_engineer.png", render_npc_engineer())
]

out_dir = "c:/Users/zahid/Documents/py-quest/assets/sprites/portraits"
for name, canvas in portraits:
    dest = os.path.join(out_dir, name)
    save_png(dest, 128, 128, canvas.buf)
    print(f"Saved: {dest}")

# Build a composite showcase card of all 9 portraits (3 columns x 3 rows)
cols = 3
rows = 3
showcase_w = cols * 140 + 20
showcase_h = rows * 140 + 20
showcase = Canvas(showcase_w, showcase_h)
showcase.rect(0, 0, showcase_w, showcase_h, (14, 10, 24, 255))

for i, (name, p_canvas) in enumerate(portraits):
    col = i % cols
    row = i // cols
    bx = 20 + col * 140
    by = 20 + row * 140
    # Outer decorative frame
    showcase.rect(bx - 3, by - 3, 134, 134, (26, 20, 44, 255), (245, 158, 11, 255))
    for y in range(128):
        for x in range(128):
            idx = (y * 128 + x) * 4
            a = p_canvas.buf[idx + 3]
            if a > 0:
                showcase.set_px(bx + x, by + y, (p_canvas.buf[idx], p_canvas.buf[idx+1], p_canvas.buf[idx+2], a))

preview_file = "C:/Users/zahid/.gemini/antigravity/brain/5e05ec48-69da-4627-8897-fdac854bd4ca/dialog_portraits_showcase.png"
save_png(preview_file, showcase_w, showcase_h, showcase.buf)
print(f"Showcase generated at: {preview_file}")
