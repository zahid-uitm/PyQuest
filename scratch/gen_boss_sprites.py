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
        raw_data.append(0)  # Filter type 0 (None)
        raw_data.extend(rgba_bytes[y * stride:(y + 1) * stride])
    idat = zlib.compress(bytes(raw_data), 9)

    png = b'\x89PNG\r\n\x1a\n' + make_chunk(b'IHDR', ihdr) + make_chunk(b'IDAT', idat) + make_chunk(b'IEND', b'')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(png)


class Canvas:
    def __init__(self, w, h):
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
                # Alpha blend
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
        if rx <= 0 or ry <= 0:
            return
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                nx = (x - cx) / rx
                ny = (y - cy) / ry
                d = nx * nx + ny * ny
                if d <= 1.0:
                    if outline and d >= 0.72:
                        self.set_px(x, y, outline)
                    else:
                        self.set_px(x, y, color)

    def line(self, x0, y0, x1, y1, color, thickness=1):
        steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(steps + 1):
            t = i / float(steps)
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            if thickness <= 1:
                self.set_px(x, y, color)
            else:
                r = thickness / 2.0
                for dy in range(int(-r), int(r) + 1):
                    for dx in range(int(-r), int(r) + 1):
                        if dx*dx + dy*dy <= r*r + 0.5:
                            self.set_px(x + dx, y + dy, color)

    def blit_cell(self, cell, col, row):
        ox = col * 48
        oy = row * 48
        for y in range(48):
            for x in range(48):
                idx = (y * 48 + x) * 4
                if cell.buf[idx + 3] > 0:
                    d_idx = ((oy + y) * self.w + (ox + x)) * 4
                    self.buf[d_idx:d_idx + 4] = cell.buf[idx:idx + 4]


# ==============================================================================
# BOSS 1: NULLBYTE - THE GLITCHED OBSIDIAN GOLEM (World 1)
# ==============================================================================
def draw_nullbyte_frame(col, row):
    c = Canvas(48, 48)
    OL = (14, 9, 24, 255)          # Deep obsidian outline
    STONE_DARK = (32, 24, 48, 255)
    STONE_MID = (52, 39, 76, 255)
    STONE_LIGHT = (78, 60, 110, 255)
    STEEL = (98, 84, 130, 255)
    GLITCH_RED = (255, 30, 86, 255)
    GLITCH_PINK = (255, 110, 165, 255)
    GLITCH_MAG = (192, 38, 211, 255)
    GLITCH_CYAN = (0, 245, 212, 255)
    SHADOW = (10, 6, 18, 120)

    phase = (col / 6.0) * math.pi * 2.0
    bob = int(round(math.sin(phase) * 1.3))
    is_side = row in (1, 4, 7)
    is_back = row in (2, 5, 8)
    is_walk = row in (3, 4, 5)
    is_atk = row in (6, 7, 8)
    is_dead = (row == 9)

    # Ground shadow
    c.ellipse(24, 41, 12, 3, SHADOW)

    if is_dead:
        if col == 0:
            # Frame 54: Heavy Hurt Recoil + Glitch Lightning Cracks
            by = 2
            c.rect(14, 20 + by, 20, 15, STONE_MID, OL)
            c.rect(10, 18 + by, 7, 9, STONE_DARK, OL)
            c.rect(31, 18 + by, 7, 9, STONE_DARK, OL)
            c.ellipse(24, 15 + by, 7, 6, STONE_DARK, OL)
            c.rect(19, 14 + by, 10, 3, GLITCH_PINK)
            # Glitch lightning cracks across body
            c.line(16, 21 + by, 28, 33 + by, GLITCH_CYAN, 1)
            c.line(29, 20 + by, 18, 31 + by, GLITCH_RED, 1)
            c.rect(16, 35, 6, 6, STONE_DARK, OL)
            c.rect(26, 35, 6, 6, STONE_DARK, OL)
        elif col == 1:
            # Frame 55: Kneeling & Shattering Golem
            c.rect(13, 26, 22, 12, STONE_DARK, OL)
            c.rect(9, 28, 6, 8, STONE_MID, OL)
            c.rect(33, 28, 6, 8, STONE_MID, OL)
            c.ellipse(24, 22, 6, 5, STONE_DARK, OL)
            c.rect(20, 22, 8, 2, GLITCH_RED)
            c.rect(21, 30, 6, 4, GLITCH_MAG)
            # Floating shattered shards
            c.rect(11, 19, 3, 3, GLITCH_CYAN)
            c.rect(34, 17, 3, 3, GLITCH_RED)
        else:
            # Frame 56+: Collapsed Obsidian Rubble Pile
            c.ellipse(24, 39, 14, 4, SHADOW)
            c.rect(11, 35, 9, 6, STONE_DARK, OL)
            c.rect(19, 33, 11, 8, STONE_MID, OL)
            c.rect(28, 36, 9, 5, STONE_DARK, OL)
            c.ellipse(23, 34, 5, 4, STONE_DARK, OL)
            # Fading glitch core ember
            c.rect(22, 34, 4, 2, GLITCH_RED)
            c.set_px(15, 33, GLITCH_CYAN)
            c.set_px(31, 34, GLITCH_MAG)
        return c

    # Walk leg offsets
    leg_l = int(round(math.sin(phase) * 2.5)) if is_walk else 0
    leg_r = -leg_l if is_walk else 0
    atk_shift = 1 if (is_atk and col in (1, 2)) else 0
    cx = 22 + (atk_shift if is_side else 2)
    cy = 24 + bob

    # 1. Floating Glitch Matrix Cubes behind shoulders
    for i, gx in enumerate([cx - 14, cx + 13]):
        gy = cy - 11 + int(round(math.sin(phase + i * 2.1) * 2.0))
        col_g = GLITCH_CYAN if (col + i) % 2 == 0 else GLITCH_RED
        c.rect(gx, gy, 3, 3, col_g, OL)

    # 2. Legs / Heavy Obsidian Greaves
    if is_side:
        c.rect(cx - 6 + leg_l, 33, 6, 8, STONE_DARK, OL)
        c.rect(cx - 5 + leg_l, 35, 4, 2, GLITCH_MAG)
        c.rect(cx + 1 + leg_r, 33, 6, 8, STONE_MID, OL)
        c.rect(cx + 2 + leg_r, 35, 4, 2, GLITCH_RED)
    else:
        c.rect(cx - 9, 33 + max(0, leg_l), 7, 8, STONE_MID, OL)
        c.rect(cx - 7, 36 + max(0, leg_l), 3, 2, GLITCH_RED)
        c.rect(cx + 2, 33 + max(0, leg_r), 7, 8, STONE_MID, OL)
        c.rect(cx + 4, 36 + max(0, leg_r), 3, 2, GLITCH_RED)

    # 3. Hulking Golem Torso (Armored Chestplate)
    c.rect(cx - 10, cy - 5, 20, 15, STONE_MID, OL)
    c.rect(cx - 8, cy - 3, 16, 11, STONE_DARK)
    # Rib/Plate segments
    c.line(cx - 8, cy + 1, cx + 7, cy + 1, STONE_LIGHT, 1)
    c.line(cx - 8, cy + 5, cx + 7, cy + 5, STONE_LIGHT, 1)
    # Belt & Runic Waistguard
    c.rect(cx - 9, cy + 7, 18, 4, STEEL, OL)
    c.rect(cx - 2, cy + 7, 4, 4, GLITCH_RED, OL)

    if not is_back:
        # Glowing Corrupt Variable Core in center of chest
        core_r = 4 if col % 2 == 0 else 3
        c.ellipse(cx + (2 if is_side else 0), cy + 1, core_r, core_r, GLITCH_RED, GLITCH_MAG)
        c.set_px(cx + (2 if is_side else 0), cy + 1, (255, 230, 245, 255))

    # 4. Massive Spiked Obsidian Pauldrons (Shoulders)
    # Left pauldron
    c.rect(cx - 15, cy - 8, 8, 9, STONE_LIGHT, OL)
    c.rect(cx - 14, cy - 6, 5, 2, GLITCH_MAG)
    c.line(cx - 14, cy - 8, cx - 17, cy - 13, OL, 2)
    c.line(cx - 13, cy - 8, cx - 16, cy - 12, GLITCH_RED, 1)
    # Right pauldron
    c.rect(cx + 7, cy - 8, 8, 9, STONE_LIGHT, OL)
    c.rect(cx + 9, cy - 6, 5, 2, GLITCH_MAG)
    c.line(cx + 14, cy - 8, cx + 17, cy - 13, OL, 2)
    c.line(cx + 13, cy - 8, cx + 16, cy - 12, GLITCH_RED, 1)

    # 5. Horned Obsidian Golem Helm (NO hair, NO human face!)
    hx = cx + (1 if is_side else 0)
    hy = cy - 11
    c.rect(hx - 7, hy - 5, 14, 11, STONE_DARK, OL)
    c.rect(hx - 5, hy - 6, 10, 3, STONE_LIGHT, OL)
    # Jagged Obsidian Horns curving upward
    c.line(hx - 7, hy - 3, hx - 11, hy - 10, OL, 3)
    c.line(hx - 7, hy - 3, hx - 10, hy - 9, STEEL, 1)
    c.line(hx + 7, hy - 3, hx + 11, hy - 10, OL, 3)
    c.line(hx + 7, hy - 3, hx + 10, hy - 9, STEEL, 1)
    # Central Crown Crest
    c.rect(hx - 2, hy - 8, 4, 4, GLITCH_RED, OL)

    if not is_back:
        # Glowing Crimson Cyclops/Knight Visor Slit
        vx = hx + (2 if is_side else 0)
        c.rect(vx - 5, hy - 1, 10, 3, (20, 5, 15, 255))
        c.rect(vx - 4, hy, 8, 2, GLITCH_RED)
        c.set_px(vx - 2, hy, GLITCH_PINK)
        c.set_px(vx + 2, hy, (255, 255, 255, 255))
        # Metal jaw grille
        for jx in range(vx - 3, vx + 4, 2):
            c.line(jx, hy + 3, jx, hy + 4, STEEL, 1)

    # 6. Giant Stone Gauntlets & Corrupt Syntax Greatsword
    if is_atk and col < 4:
        if col == 0:
            # Windup: Sword raised high overhead
            c.rect(cx + 7, cy - 7, 6, 6, STONE_DARK, OL)
            c.line(cx + 10, cy - 7, cx + 8, cy - 22, OL, 4)
            c.line(cx + 10, cy - 7, cx + 8, cy - 21, GLITCH_RED, 2)
        elif col == 1:
            # Massive Cleave Arc!
            c.rect(cx + 8, cy - 2, 6, 6, STONE_DARK, OL)
            c.line(cx + 10, cy, cx + 19, cy + 2, OL, 4)
            c.line(cx + 10, cy, cx + 18, cy + 2, GLITCH_RED, 2)
            # Huge magenta/cyan slash crescent
            for a in range(-65, 65, 4):
                rad = math.radians(a)
                sx = cx + 7 + math.cos(rad) * 12
                sy = cy + 1 + math.sin(rad) * 12
                c.set_px(sx, sy, GLITCH_PINK)
                c.set_px(sx - 1, sy, GLITCH_RED)
                if a % 16 == 0:
                    c.set_px(sx + 1, sy, GLITCH_CYAN)
        elif col == 2:
            # Follow-through low cleave
            c.rect(cx + 8, cy + 2, 6, 6, STONE_DARK, OL)
            c.line(cx + 11, cy + 4, cx + 22, cy + 11, OL, 4)
            c.line(cx + 11, cy + 4, cx + 21, cy + 10, GLITCH_MAG, 2)
            for a in range(10, 80, 6):
                rad = math.radians(a)
                sx = cx + 9 + math.cos(rad) * 13
                sy = cy + 2 + math.sin(rad) * 13
                c.set_px(sx, sy, GLITCH_RED)
        else:
            # Recovery
            c.rect(cx + 8, cy - 1, 6, 6, STONE_DARK, OL)
            c.line(cx + 11, cy + 1, cx + 19, cy - 8, OL, 4)
            c.line(cx + 11, cy + 1, cx + 18, cy - 7, GLITCH_RED, 2)
    else:
        # Left Gauntlet
        c.rect(cx - 15, cy + 1, 6, 7, STONE_DARK, OL)
        c.rect(cx - 14, cy + 3, 4, 2, STEEL)
        # Right Gauntlet holding Giant Corrupt Greatsword
        c.rect(cx + 9, cy + 1, 6, 7, STONE_DARK, OL)
        # Greatsword hilt & crossguard
        sx = cx + 13
        sy = cy + 3
        c.line(sx - 3, sy - 2, sx + 3, sy + 1, STEEL, 2)
        # Broad glowing blade angled menacingly
        c.line(sx, sy - 1, sx + 7, sy - 16, OL, 4)
        c.line(sx, sy - 1, sx + 6, sy - 15, GLITCH_RED, 2)
        c.line(sx, sy - 2, sx + 5, sy - 14, GLITCH_PINK, 1)

    return c


# ==============================================================================
# BOSS 2: CHRONOS-IF - THE ABYSSAL CLOCKWORK SERAPH (World 2)
# ==============================================================================
def draw_chronos_frame(col, row):
    c = Canvas(48, 48)
    OL = (8, 18, 34, 255)
    ARMOR_DARK = (16, 38, 68, 255)
    ARMOR_MID = (28, 66, 110, 255)
    ARMOR_LIGHT = (56, 116, 178, 255)
    GOLD_DARK = (161, 98, 7, 255)
    GOLD = (245, 158, 11, 255)
    GOLD_LIGHT = (254, 240, 138, 255)
    CYAN = (0, 240, 255, 255)
    CYAN_SOFT = (56, 189, 248, 220)
    WHITE = (235, 252, 255, 255)
    SHADOW = (6, 22, 42, 115)

    phase = (col / 6.0) * math.pi * 2.0
    hover = int(round(math.sin(phase) * 2.0))
    is_side = row in (1, 4, 7)
    is_back = row in (2, 5, 8)
    is_atk = row in (6, 7, 8)
    is_dead = (row == 9)

    # Glowing Temporal Loop Ring on the ground
    c.ellipse(24, 41, 11, 3, SHADOW)
    if not is_dead:
        c.ellipse(24, 41, 9 + (col % 2), 2, CYAN_SOFT, CYAN)

    if is_dead:
        if col == 0:
            # Frame 54: Temporal Overload Shock
            c.ellipse(24, 19, 12, 12, GOLD, OL)
            c.rect(17, 17, 14, 15, ARMOR_MID, OL)
            c.line(12, 12, 36, 28, CYAN, 2)
            c.line(35, 11, 13, 29, GOLD_LIGHT, 2)
        elif col == 1:
            # Frame 55: Wings dissolving & Halo cracking
            c.ellipse(24, 26, 9, 9, GOLD_DARK, OL)
            c.rect(18, 24, 12, 12, ARMOR_DARK, OL)
            c.ellipse(24, 28, 4, 4, CYAN)
        else:
            # Frame 56: Broken Clockwork Gears & Shattered Hourglass on floor
            c.ellipse(24, 38, 12, 4, (12, 28, 48, 180))
            c.ellipse(20, 36, 6, 3, GOLD_DARK, OL)
            c.ellipse(28, 37, 5, 3, ARMOR_MID, OL)
            c.rect(22, 34, 5, 4, CYAN, OL)
            c.set_px(24, 35, WHITE)
        return c

    atk_shift = 1 if (is_atk and col in (1, 2)) else 0
    cx = 22 + (atk_shift if is_side else 2)
    cy = 21 + hover

    # 1. Rotating Golden Clockwork Halo / Astrolabe behind back
    halo_r = 12
    c.ellipse(cx, cy - 3, halo_r, halo_r, (0, 0, 0, 0), GOLD)
    c.ellipse(cx, cy - 3, halo_r - 1, halo_r - 1, (0, 0, 0, 0), GOLD_DARK)
    # Rotating gear teeth on the clockwork wheel
    for i in range(8):
        ang = (i * math.pi / 4.0) + (col * math.pi / 12.0)
        tx = cx + math.cos(ang) * (halo_r + 1.5)
        ty = (cy - 3) + math.sin(ang) * (halo_r + 1.5)
        c.rect(tx - 1, ty - 1, 2, 2, GOLD_LIGHT, OL)

    # 2. Sweeping Cyan Energy Seraph Wings (Left = IF, Right = ELSE)
    wing_flap = int(round(math.sin(phase) * 2.0))
    for side in (-1, 1):
        wx = cx + side * 9
        # Upper wing feather blade
        c.line(wx, cy - 4, wx + side * 9, cy - 11 + wing_flap, CYAN, 3)
        c.line(wx, cy - 4, wx + side * 9, cy - 11 + wing_flap, WHITE, 1)
        # Mid wing feather blade
        c.line(wx, cy - 1, wx + side * 10, cy - 4 + wing_flap, CYAN_SOFT, 3)
        # Lower wing feather blade
        c.line(wx, cy + 2, wx + side * 7, cy + 3 + wing_flap, CYAN_SOFT, 2)

    # 3. Levitating Tapered Automaton Greaves / Lower Spire (No human walk!)
    c.line(cx - 3, cy + 7, cx - 2, cy + 15, ARMOR_DARK, 3)
    c.line(cx + 3, cy + 7, cx + 2, cy + 15, ARMOR_DARK, 3)
    c.set_px(cx - 2, cy + 15, GOLD)
    c.set_px(cx + 2, cy + 15, GOLD)

    # 4. Celestial Bronze & Abyssal Sapphire Armored Torso
    c.rect(cx - 7, cy - 4, 14, 12, ARMOR_MID, OL)
    # Golden Pauldrons
    c.rect(cx - 11, cy - 6, 6, 6, GOLD, OL)
    c.rect(cx + 5, cy - 6, 6, 6, GOLD, OL)
    c.set_px(cx - 9, cy - 5, GOLD_LIGHT)
    c.set_px(cx + 7, cy - 5, GOLD_LIGHT)

    if not is_back:
        # Glowing Cyan Hourglass Core in Chest
        c.line(cx - 2, cy - 2, cx + 2, cy - 2, GOLD, 1)
        c.line(cx - 2, cy + 4, cx + 2, cy + 4, GOLD, 1)
        c.line(cx - 2, cy - 1, cx + 2, cy + 3, CYAN, 2)
        c.line(cx + 2, cy - 1, cx - 2, cy + 3, CYAN, 2)
        c.set_px(cx, cy + 1, WHITE)

    # 5. Crowned Clockwork Mask / Archon Helm
    hx = cx + (1 if is_side else 0)
    hy = cy - 10
    c.rect(hx - 5, hy - 4, 10, 9, ARMOR_DARK, OL)
    # Tall Golden Sunburst Crown Spires
    c.line(hx - 4, hy - 4, hx - 6, hy - 9, GOLD, 2)
    c.line(hx, hy - 4, hx, hy - 10, GOLD_LIGHT, 2)
    c.line(hx + 4, hy - 4, hx + 6, hy - 9, GOLD, 2)
    if not is_back:
        # Glowing Cyan Temporal Eye + Golden Faceplate
        ex = hx + (1 if is_side else 0)
        c.rect(ex - 4, hy - 2, 8, 5, GOLD, OL)
        c.rect(ex - 3, hy - 1, 6, 3, (6, 20, 38, 255))
        c.rect(ex - 2, hy, 4, 2, CYAN)
        c.set_px(ex, hy, WHITE)

    # 6. Temporal Pendulum Halberd / Twin-Scythe
    if is_atk and col < 4:
        if col == 0:
            c.line(cx + 8, cy + 3, cx + 10, cy - 18, GOLD, 2)
            c.ellipse(cx + 12, cy - 15, 5, 4, CYAN, OL)
        elif col in (1, 2):
            # Sweeping Temporal Halberd Slash!
            c.line(cx + 5, cy, cx + 18, cy + (2 if col == 1 else 6), GOLD, 2)
            for a in range(-60, 68, 4):
                rad = math.radians(a)
                sx = cx + 7 + math.cos(rad) * 12
                sy = cy + math.sin(rad) * 12
                c.set_px(sx, sy, CYAN)
                c.set_px(sx - 1, sy, WHITE)
                c.set_px(sx - 2, sy, GOLD)
        else:
            c.line(cx + 8, cy + 2, cx + 16, cy - 10, GOLD, 2)
    else:
        sx = cx + 10
        sy = cy + 2
        # Long golden clockwork polearm shaft
        c.line(sx, sy + 11, sx + 3, sy - 14, GOLD, 2)
        # Crescent cyan energy scythe blade at top
        c.line(sx + 3, sy - 12, sx + 10, sy - 8, CYAN, 3)
        c.line(sx + 3, sy - 13, sx - 3, sy - 10, CYAN_SOFT, 2)
        c.set_px(sx + 3, sy - 12, WHITE)

    return c


# ==============================================================================
# BOSS 3: LAMBDA-PRIME - THE ARCANE RELIC SOVEREIGN (World 3)
# ==============================================================================
def draw_lambda_frame(col, row):
    c = Canvas(48, 48)
    OL = (18, 7, 36, 255)
    ROBE_DARK = (38, 16, 72, 255)
    ROBE_MID = (76, 29, 149, 255)
    ROBE_LIGHT = (124, 58, 237, 255)
    GOLD_DARK = (180, 83, 9, 255)
    GOLD = (245, 158, 11, 255)
    GOLD_BRIGHT = (253, 224, 71, 255)
    VIOLET_GLOW = (216, 180, 254, 255)
    MAGENTA_GLOW = (244, 114, 182, 255)
    SHADOW = (18, 6, 36, 120)

    phase = (col / 6.0) * math.pi * 2.0
    float_y = int(round(math.sin(phase) * 2.0))
    is_side = row in (1, 4, 7)
    is_back = row in (2, 5, 8)
    is_atk = row in (6, 7, 8)
    is_dead = (row == 9)

    c.ellipse(24, 41, 11, 3, SHADOW)
    if not is_dead:
        c.ellipse(24, 41, 8, 2, (147, 51, 234, 140))

    if is_dead:
        if col == 0:
            # Frame 54: Orbs destabilize in violet flash
            c.rect(15, 15, 18, 20, ROBE_MID, OL)
            c.line(10, 14, 38, 32, VIOLET_GLOW, 2)
            c.line(38, 14, 10, 32, GOLD_BRIGHT, 2)
        elif col == 1:
            # Frame 55: Collapsing into arcane singularity
            c.ellipse(24, 27, 9, 9, ROBE_DARK, GOLD)
            c.ellipse(24, 27, 5, 5, MAGENTA_GLOW, VIOLET_GLOW)
        else:
            # Frame 56: Fallen Sovereign Crown & Empty Cloak
            c.ellipse(24, 38, 12, 4, ROBE_DARK, OL)
            c.rect(16, 35, 16, 5, ROBE_MID, OL)
            # Golden Crown resting on cloak
            c.rect(20, 31, 8, 4, GOLD, OL)
            c.set_px(21, 29, GOLD_BRIGHT)
            c.set_px(24, 28, GOLD_BRIGHT)
            c.set_px(27, 29, GOLD_BRIGHT)
        return c

    atk_shift = 1 if (is_atk and col in (1, 2)) else 0
    cx = 22 + (atk_shift if is_side else 2)
    cy = 22 + float_y

    # 1. Sweeping High-Collared Arcane Mantle & Levitating Robe Train
    # High Regal Collar behind head
    c.ellipse(cx, cy - 9, 11, 6, ROBE_DARK, GOLD)
    # Flowing Robe Body (Bell-shaped arch-mage silhouette)
    for dy in range(-4, 15):
        half_w = int(6 + (dy + 4) * 0.35)
        y_pos = cy + dy
        c.line(cx - half_w, y_pos, cx + half_w, y_pos, ROBE_MID if abs(dy) < 8 else ROBE_DARK, 1)
        c.set_px(cx - half_w, y_pos, OL)
        c.set_px(cx + half_w, y_pos, OL)
        # Golden runic trim down the robe edges
        if dy % 2 == 0:
            c.set_px(cx - half_w + 1, y_pos, GOLD)
            c.set_px(cx + half_w - 1, y_pos, GOLD)

    # Tattered floating hem waves at bottom
    for tx in range(cx - 10, cx + 11, 4):
        ty = cy + 15 + int(round(math.sin(phase + tx) * 1.5))
        c.rect(tx, ty, 3, 3, ROBE_DARK, OL)

    if not is_back:
        # Golden Lambda (λ) Crest emblazoned on chest
        c.line(cx - 2, cy - 3, cx + 3, cy + 5, GOLD_BRIGHT, 2)
        c.line(cx, cy + 1, cx - 3, cy + 5, GOLD, 2)

    # 2. Towering Three-Spired Sovereign Crown & Void Face with 3 Glowing Eyes
    hx = cx + (1 if is_side else 0)
    hy = cy - 10
    c.ellipse(hx, hy, 6, 5, (12, 4, 24, 255), OL)
    # Golden Sovereign Crown
    c.rect(hx - 6, hy - 6, 12, 3, GOLD, OL)
    c.line(hx - 5, hy - 6, hx - 6, hy - 11, GOLD, 2)
    c.line(hx, hy - 6, hx, hy - 13, GOLD_BRIGHT, 2)
    c.line(hx + 5, hy - 6, hx + 6, hy - 11, GOLD, 2)
    c.set_px(hx, hy - 10, MAGENTA_GLOW)

    if not is_back:
        ex = hx + (1 if is_side else 0)
        # Three Eldritch Glowing Eyes (2 lower, 1 third-eye on forehead)
        c.rect(ex - 4, hy, 2, 2, MAGENTA_GLOW)
        c.rect(ex + 2, hy, 2, 2, MAGENTA_GLOW)
        c.rect(ex - 1, hy - 2, 2, 2, VIOLET_GLOW)

    # 3. Three Orbiting Parameter Orbs (Grimoire Spheres)
    for i in range(3):
        orb_ang = phase + i * (math.pi * 2.0 / 3.0)
        ox = cx + math.cos(orb_ang) * 14.0
        oy = (cy - 2) + math.sin(orb_ang) * 5.0
        c.ellipse(ox, oy, 3, 3, MAGENTA_GLOW if i == 0 else ROBE_LIGHT, GOLD_BRIGHT)
        c.set_px(ox, oy, (255, 255, 255, 255))

    # 4. Grand Scepter of Return & Arcane Beam Slash
    if is_atk and col < 4:
        if col == 0:
            c.line(cx + 9, cy + 4, cx + 11, cy - 16, GOLD, 2)
            c.ellipse(cx + 11, cy - 17, 4, 4, MAGENTA_GLOW, GOLD_BRIGHT)
        elif col in (1, 2):
            # Thrusts Scepter & unleashes Lambda Arcane Wave!
            c.line(cx + 5, cy - 1, cx + 16, cy - 1, GOLD_BRIGHT, 2)
            c.ellipse(cx + 15, cy - 1, 3, 3, MAGENTA_GLOW, GOLD)
            for a in range(-55, 56, 4):
                rad = math.radians(a)
                sx = cx + 7 + math.cos(rad) * 12
                sy = cy + math.sin(rad) * 12
                c.set_px(sx, sy, VIOLET_GLOW)
                c.set_px(sx - 1, sy, MAGENTA_GLOW)
                c.set_px(sx - 2, sy, GOLD_BRIGHT)
        else:
            c.line(cx + 9, cy + 4, cx + 15, cy - 12, GOLD, 2)
    else:
        sx = cx + 11
        sy = cy + 2
        c.line(sx, sy + 11, sx + 2, sy - 12, GOLD, 2)
        c.ellipse(sx + 2, sy - 14, 4, 4, ROBE_LIGHT, GOLD_BRIGHT)
        c.set_px(sx + 2, sy - 14, VIOLET_GLOW)

    return c


# ==============================================================================
# BOSS 4: VEKTOR-ZERO - THE CATACOMB SEQUENCE LICH (World 4)
# ==============================================================================
def draw_vektor_frame(col, row):
    c = Canvas(48, 48)
    OL = (10, 16, 14, 255)
    BONE_DARK = (148, 163, 184, 255)
    BONE = (226, 232, 240, 255)
    BONE_BRIGHT = (248, 250, 252, 255)
    GOLD_DARK = (161, 98, 7, 255)
    GOLD = (245, 158, 11, 255)
    GOLD_BRIGHT = (253, 224, 71, 255)
    LAPIS = (30, 58, 138, 255)
    SOUL_DARK = (5, 150, 105, 255)
    SOUL_GREEN = (16, 185, 129, 255)
    SOUL_BRIGHT = (110, 231, 183, 255)
    SHROUD = (24, 32, 44, 255)
    SHADOW = (6, 24, 16, 125)

    phase = (col / 6.0) * math.pi * 2.0
    hover = int(round(math.sin(phase) * 2.0))
    is_side = row in (1, 4, 7)
    is_back = row in (2, 5, 8)
    is_atk = row in (6, 7, 8)
    is_dead = (row == 9)

    c.ellipse(24, 41, 12, 3, SHADOW)
    if not is_dead:
        c.ellipse(24, 41, 9, 2, (16, 185, 129, 135))

    if is_dead:
        if col == 0:
            # Frame 54: Necrotic Soul-Fire Eruption
            c.rect(16, 18, 16, 16, SHROUD, OL)
            c.ellipse(24, 22, 8, 8, SOUL_GREEN, SOUL_BRIGHT)
            c.ellipse(24, 13, 6, 5, BONE, OL)
        elif col == 1:
            # Frame 55: Skeleton crumbling apart
            c.rect(15, 27, 18, 10, SHROUD, OL)
            c.line(17, 26, 31, 29, BONE, 2)
            c.ellipse(24, 23, 5, 4, BONE, OL)
            c.ellipse(24, 30, 4, 3, SOUL_GREEN)
        else:
            # Frame 56: Pile of Bones, Pharaonic Skull & Flickering Soul Wisp
            c.ellipse(24, 39, 13, 3, SHADOW)
            c.line(14, 38, 34, 37, BONE_DARK, 3)
            c.line(16, 36, 31, 39, BONE, 2)
            c.ellipse(24, 34, 5, 4, BONE, OL)
            c.rect(20, 30, 8, 3, GOLD, OL)
            c.set_px(22, 34, SOUL_BRIGHT)
            c.set_px(26, 34, SOUL_BRIGHT)
        return c

    atk_shift = 1 if (is_atk and col in (1, 2)) else 0
    cx = 22 + (atk_shift if is_side else 2)
    cy = 22 + hover

    # 1. Tattered Necrotic Pharaoh Shroud & Floating Spine
    for dy in range(2, 16):
        w_shroud = int(9 - (dy - 2) * 0.35)
        c.line(cx - w_shroud, cy + dy, cx + w_shroud, cy + dy, SHROUD, 1)
    # Glowing emerald soul-flame vortex at base of spine
    c.ellipse(cx, cy + 12, 5, 4, SOUL_DARK, SOUL_GREEN)
    c.ellipse(cx, cy + 12, 3, 2, SOUL_BRIGHT)

    # 2. Exposed Skeletal Ribcage with Emerald Soul-Fire Heart
    c.rect(cx - 8, cy - 5, 16, 11, SHROUD, OL)
    if not is_back:
        # Glowing green soul-fire inside chest cavity
        c.ellipse(cx, cy, 5, 4, SOUL_GREEN, SOUL_DARK)
        c.set_px(cx, cy, SOUL_BRIGHT)
        # White Bone Spine & Ribs cages over the soul-fire
        c.line(cx, cy - 4, cx, cy + 5, BONE, 2)
        for ry in (cy - 3, cy, cy + 3):
            c.line(cx - 6, ry, cx + 6, ry, BONE_BRIGHT, 1)
            c.set_px(cx - 7, ry, OL)
            c.set_px(cx + 7, ry, OL)

    # 3. Royal Pharaonic Gold & Lapis Broad Collar / Pauldrons
    c.rect(cx - 12, cy - 7, 24, 4, GOLD, OL)
    for sx in range(cx - 10, cx + 10, 4):
        c.rect(sx, cy - 6, 2, 2, LAPIS)

    # 4. Egyptian Nemes Headdress & Horned Lich Skull
    hx = cx + (1 if is_side else 0)
    hy = cy - 11
    # Striped Gold & Lapis Nemes Headcloth Wings
    c.ellipse(hx, hy, 9, 7, GOLD, OL)
    for sy in range(hy - 5, hy + 6, 2):
        c.line(hx - 7, sy, hx + 7, sy, LAPIS, 1)
    # Golden Cobra Uraeus on forehead
    c.rect(hx - 1, hy - 8, 3, 4, GOLD_BRIGHT, OL)
    c.set_px(hx, hy - 7, SOUL_BRIGHT)

    if not is_back:
        # Bleached Lich Skull Face
        sx = hx + (1 if is_side else 0)
        c.ellipse(sx, hy, 5, 5, BONE_BRIGHT, OL)
        c.rect(sx - 3, hy + 3, 6, 3, BONE, OL)
        # Grinning skull teeth
        for tx in range(sx - 2, sx + 3, 2):
            c.set_px(tx, hy + 4, OL)
        # Blazing Emerald Soul-Fire Eye Sockets
        c.rect(sx - 4, hy - 1, 3, 3, OL)
        c.rect(sx + 1, hy - 1, 3, 3, OL)
        c.rect(sx - 3, hy, 2, 2, SOUL_BRIGHT)
        c.rect(sx + 2, hy, 2, 2, SOUL_BRIGHT)

    # 5. Floating Emerald Index Tablets [0] [1] [2] orbiting
    for i, ox_off in enumerate([-15, 14]):
        ty = cy - 6 + int(round(math.sin(phase + i * 2.5) * 2.5))
        c.rect(cx + ox_off, ty, 4, 6, SHROUD, SOUL_GREEN)
        c.set_px(cx + ox_off + 2, ty + 2, SOUL_BRIGHT)

    # 6. Necrotic Serpent Scythe / Soul Khopesh
    if is_atk and col < 4:
        if col == 0:
            c.line(cx + 8, cy + 4, cx + 10, cy - 17, BONE, 2)
            c.line(cx + 10, cy - 17, cx + 18, cy - 12, SOUL_GREEN, 3)
        elif col in (1, 2):
            # Reaping Emerald Scythe Cleave!
            c.line(cx + 5, cy, cx + 17, cy + 3, BONE, 2)
            for a in range(-65, 65, 4):
                rad = math.radians(a)
                rx = cx + 7 + math.cos(rad) * 12
                ry = cy + math.sin(rad) * 12
                c.set_px(rx, ry, SOUL_BRIGHT)
                c.set_px(rx - 1, ry, SOUL_GREEN)
                c.set_px(rx - 2, ry, GOLD)
        else:
            c.line(cx + 8, cy + 3, cx + 15, cy - 11, BONE, 2)
    else:
        sx = cx + 11
        sy = cy + 2
        # Bone Scythe Shaft
        c.line(sx, sy + 12, sx + 2, sy - 13, BONE, 2)
        # Golden Serpent Head at top of scythe
        c.rect(sx + 1, sy - 15, 4, 4, GOLD, OL)
        # Sweeping Emerald Necrotic Scythe Blade
        c.line(sx + 3, sy - 14, sx + 12, sy - 9, SOUL_GREEN, 3)
        c.line(sx + 3, sy - 14, sx + 11, sy - 10, SOUL_BRIGHT, 1)

    return c


def build_sheet(draw_fn, out_path):
    sheet = Canvas(288, 480)
    for row in range(10):
        for col in range(6):
            # Rows 6,7,8 only have 4 frames in original layout, but filling all 6 keeps it safe
            cell = draw_fn(col, row)
            sheet.blit_cell(cell, col, row)
    save_png(out_path, 288, 480, sheet.buf)
    print(f"Generated {out_path} (288x480)")
    return sheet


def build_preview_card(sheets, out_path):
    # Scale up Frame 6 (side idle) and Frame 43 (attack slash) of each boss 4x for a crisp showcase image
    scale = 4
    card_w = 4 * (48 * scale * 2 + 24) + 24
    card_h = 48 * scale + 48
    card = Canvas(card_w, card_h)
    # Dark RPG slate background
    card.rect(0, 0, card_w, card_h, (15, 12, 28, 255))

    for i, sheet in enumerate(sheets):
        base_x = 20 + i * (48 * scale * 2 + 24)
        base_y = 24
        # Panel border
        card.rect(base_x - 4, base_y - 4, 48 * scale * 2 + 8, 48 * scale + 8, (26, 20, 46, 255), (90, 70, 140, 255))
        # Draw Frame 0 (Front Idle) and Frame 43 (Attack) scaled 4x
        for f_idx, (f_col, f_row) in enumerate([(0, 0), (1, 7)]):
            ox = f_col * 48
            oy = f_row * 48
            dest_x = base_x + f_idx * (48 * scale)
            for y in range(48):
                for x in range(48):
                    s_idx = ((oy + y) * 288 + (ox + x)) * 4
                    a = sheet.buf[s_idx + 3]
                    if a > 0:
                        col_rgba = (sheet.buf[s_idx], sheet.buf[s_idx+1], sheet.buf[s_idx+2], a)
                        card.rect(dest_x + x * scale, base_y + y * scale, scale, scale, col_rgba)

    save_png(out_path, card_w, card_h, card.buf)
    print(f"Generated showcase preview: {out_path}")


if __name__ == "__main__":
    s1 = build_sheet(draw_nullbyte_frame, "c:/Users/zahid/Documents/py-quest/assets/sprites/custom/boss_golem_sheet.png")
    s2 = build_sheet(draw_chronos_frame, "c:/Users/zahid/Documents/py-quest/assets/sprites/custom/boss_warden_sheet.png")
    s3 = build_sheet(draw_lambda_frame, "c:/Users/zahid/Documents/py-quest/assets/sprites/custom/boss_arbiter_sheet.png")
    s4 = build_sheet(draw_vektor_frame, "c:/Users/zahid/Documents/py-quest/assets/sprites/custom/boss_index_warden_sheet.png")

    # Also update boss_golem.png single icon if used
    c1 = draw_nullbyte_frame(0, 0)
    save_png("c:/Users/zahid/Documents/py-quest/assets/sprites/custom/boss_golem.png", 48, 48, c1.buf)

    preview_path = "C:/Users/zahid/.gemini/antigravity/brain/5e05ec48-69da-4627-8897-fdac854bd4ca/boss_redesign_showcase.png"
    build_preview_card([s1, s2, s3, s4], preview_path)
