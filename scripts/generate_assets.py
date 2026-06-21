#!/usr/bin/env python3
"""
Asset generator for Pokemon Journey iOS game.
Generates GBA RSE-style pixel art sprites, tilesets, and UI elements.
All assets are original designs (not Nintendo IP).
"""
from PIL import Image, ImageDraw
import os, math

OUT = "/Users/r1chi3/PokemonJourney/generated_assets"
S = 3  # pixels per logical pixel (scale factor)

# ──────────────────────────────────────────────────────────────────────────────
# Core helpers
# ──────────────────────────────────────────────────────────────────────────────

def canvas(lw, lh, bg=(0,0,0,0)):
    return Image.new('RGBA', (lw*S, lh*S), bg)

def px(draw, x, y, c):
    if len(c) == 4 and c[3] == 0: return
    draw.rectangle([x*S, y*S, x*S+S-1, y*S+S-1], fill=c)

def hline(draw, x, y, n, c):
    for i in range(n): px(draw, x+i, y, c)

def vline(draw, x, y, n, c):
    for i in range(n): px(draw, x, y+i, c)

def rect(draw, x, y, w, h, c):
    for dy in range(h):
        for dx in range(w):
            px(draw, x+dx, y+dy, c)

def ellipse_fill(draw, cx, cy, rx, ry, c):
    for dy in range(-ry, ry+1):
        for dx in range(-rx, rx+1):
            if (dx/max(rx,0.1))**2 + (dy/max(ry,0.1))**2 <= 1.0:
                px(draw, cx+dx, cy+dy, c)

def circle_fill(draw, cx, cy, r, c):
    ellipse_fill(draw, cx, cy, r, r, c)

def outline(draw, cx, cy, rx, ry, c):
    """1-pixel-thick outline of ellipse"""
    for dy in range(-ry-1, ry+2):
        for dx in range(-rx-1, rx+2):
            d = (dx/max(rx,0.1))**2 + (dy/max(ry,0.1))**2
            d_inner = ((dx-0.5)/max(rx,0.1))**2 + ((dy-0.5)/max(ry,0.1))**2
            if d <= 1.3 and d >= 0.85:
                # check if adjacent pixels are inside
                inside = any(
                    (dx+nx)/max(rx,0.1)**2 + (dy+ny)**2/max(ry,0.1)**2 <= 1.0
                    for nx, ny in [(-1,0),(1,0),(0,-1),(0,1)]
                )
                if inside or d >= 1.05:
                    pass
                px(draw, cx+dx, cy+dy, c)

# ──────────────────────────────────────────────────────────────────────────────
# Color palette (GBA RSE inspired)
# ──────────────────────────────────────────────────────────────────────────────
BK  = (28,  28,  28,  255)   # outline black
GY  = (72,  72,  72,  255)   # dark gray
WH  = (248, 248, 248, 255)   # white

# Sparky (electric yellow creature)
YM  = (248, 208, 48,  255)   # main yellow   F8D030
YL  = (252, 232, 88,  255)   # light yellow  FCE858
YD  = (200, 152, 0,   255)   # dark yellow   C89800
YVD = (140, 100, 0,   255)   # very dark     8C6400
CR  = (255, 248, 200, 255)   # cream         FFF8C8  (belly / inner ear)
TL  = (64,  184, 216, 255)   # teal bright   40B8D8  (cheek stars — NOT red)
TLD = (32,  128, 168, 255)   # teal dark     2080A8
EY  = (56,  36,  8,   255)   # eye dark      381C08 (pupil)
EYL = (104, 72,  16,  255)   # eye light     685010
IN  = (248, 160, 96,  255)   # inner ear     F8A060
NS  = (64,  40,  16,  255)   # nose/mouth    402810
RD  = (224, 64,  32,  255)   # red (lightning bolt detail, NOT cheeks)

# Tile palette - environment
GR1 = (72,  168, 64,  255)   # grass bright
GR2 = (48,  136, 40,  255)   # grass dark
GR3 = (100, 200, 88,  255)   # grass highlight
PT1 = (192, 160, 104, 255)   # path tan
PT2 = (168, 136, 80,  255)   # path dark
TR1 = (144, 96,  40,  255)   # tree trunk
TR2 = (104, 64,  16,  255)   # trunk dark
LE1 = (32,  128, 24,  255)   # leaf dark
LE2 = (56,  168, 40,  255)   # leaf mid
LE3 = (88,  208, 64,  255)   # leaf bright
SK1 = (128, 208, 248, 255)   # sky bright
SK2 = (88,  176, 232, 255)   # sky mid
WA1 = (64,  152, 224, 255)   # water
WA2 = (48,  120, 200, 255)   # water dark
WA3 = (112, 184, 248, 255)   # water foam
SA1 = (232, 208, 152, 255)   # sand bright
SA2 = (208, 184, 120, 255)   # sand mid
ST1 = (128, 120, 112, 255)   # stone bright
ST2 = (96,  88,  80,  255)   # stone dark
CR1 = (160, 240, 248, 255)   # crystal bright
CR2 = (120, 200, 232, 255)   # crystal mid
CL1 = (48,  48,  64,  255)   # cave wall dark
CL2 = (64,  64,  80,  255)   # cave wall mid
FL1 = (168, 136, 96,  255)   # wood floor light
FL2 = (136, 104, 64,  255)   # wood floor dark
WL1 = (184, 200, 216, 255)   # room wall light  B8C8D8
WL2 = (160, 176, 200, 255)   # room wall mid

# UI palette
UI_BG  = (18,  18,  42,  255)  # 12122A dark bg
UI_P1  = (32,  80,  144, 255)  # primary button  205090
UI_P2  = (48,  104, 192, 255)  # primary hover   3068C0
UI_Y1  = (200, 160, 8,   255)  # yellow button   C8A008
UI_Y2  = (248, 208, 48,  255)  # yellow bright
UI_PN  = (240, 244, 255, 255)  # panel light     F0F4FF
UI_PD  = (200, 212, 232, 255)  # panel shadow
UI_BRD = (100, 120, 160, 255)  # panel border
PC_BG  = (245, 236, 216, 255)  # postcard beige  F5ECD8
PC_BD  = (180, 144, 80,  255)  # postcard border D4B070

# ──────────────────────────────────────────────────────────────────────────────
# SPARKY CHARACTER SPRITES
# ──────────────────────────────────────────────────────────────────────────────

def draw_sparky_body_front(draw, ox, oy, eyes='open'):
    """Draw Sparky facing forward. 28x36 logical pixels."""
    # ── Ears (long, rounded-top, rabbit-style) ──
    for ear_cx, ear_sx in [(9, -1), (19, 1)]:
        # outer black outline
        ellipse_fill(draw, ox+ear_cx, oy+4, 3, 6, BK)
        # yellow fill
        ellipse_fill(draw, ox+ear_cx, oy+4, 2, 5, YM)
        # inner ear (peach/orange tint)
        ellipse_fill(draw, ox+ear_cx, oy+5, 1, 3, IN)
        # highlight
        px(draw, ox+ear_cx-1, oy+2, YL)

    # ── Head ──
    ellipse_fill(draw, ox+14, oy+16, 10, 9, BK)    # outline
    ellipse_fill(draw, ox+14, oy+16, 9, 8, YM)      # main
    # cheek highlights (upper-left)
    ellipse_fill(draw, ox+10, oy+13, 3, 3, YL)

    # ── Eyes ──
    for eye_cx in [10, 18]:
        if eyes == 'open':
            circle_fill(draw, ox+eye_cx, oy+15, 3, BK)      # eye bg
            circle_fill(draw, ox+eye_cx, oy+15, 2, EY)      # pupil
            px(draw, ox+eye_cx-1, oy+14, EYL)               # iris glint
            px(draw, ox+eye_cx+1, oy+13, WH)                # highlight
        elif eyes == 'half':
            rect(draw, ox+eye_cx-2, oy+15, 5, 2, BK)
            rect(draw, ox+eye_cx-1, oy+15, 3, 2, EY)
            px(draw, ox+eye_cx+1, oy+14, WH)
        elif eyes == 'closed':
            hline(draw, ox+eye_cx-2, oy+16, 5, BK)
            hline(draw, ox+eye_cx-1, oy+16, 3, EY)
        elif eyes == 'happy':
            # ^ shape
            px(draw, ox+eye_cx-2, oy+15, BK)
            px(draw, ox+eye_cx-1, oy+14, BK)
            px(draw, ox+eye_cx,   oy+15, BK)
            px(draw, ox+eye_cx+1, oy+14, BK)
            px(draw, ox+eye_cx+2, oy+15, BK)

    # ── Teal star-shaped cheek marks (NOT red circles!) ──
    for ck_cx in [8, 20]:
        # star pattern: 5 pixels
        px(draw, ox+ck_cx,   oy+18, TL)
        px(draw, ox+ck_cx-1, oy+18, TL)
        px(draw, ox+ck_cx+1, oy+18, TL)
        px(draw, ox+ck_cx,   oy+17, TL)
        px(draw, ox+ck_cx,   oy+19, TL)
        px(draw, ox+ck_cx-1, oy+17, TLD)  # subtle 3D effect
        # glow center
        px(draw, ox+ck_cx, oy+18, TL)

    # ── Nose ──
    px(draw, ox+13, oy+18, NS)
    px(draw, ox+14, oy+18, NS)
    px(draw, ox+15, oy+18, NS)

    # ── Mouth (small smile) ──
    px(draw, ox+12, oy+20, NS)
    px(draw, ox+13, oy+21, NS)
    px(draw, ox+14, oy+21, NS)
    px(draw, ox+15, oy+21, NS)
    px(draw, ox+16, oy+20, NS)

    # ── Body ──
    ellipse_fill(draw, ox+14, oy+30, 8, 7, BK)     # outline
    ellipse_fill(draw, ox+14, oy+30, 7, 6, YM)      # main body
    ellipse_fill(draw, ox+14, oy+30, 5, 4, YL)      # light center
    ellipse_fill(draw, ox+14, oy+31, 4, 3, CR)      # cream belly

    # ── Arms ──
    ellipse_fill(draw, ox+5,  oy+27, 2, 3, BK)
    ellipse_fill(draw, ox+5,  oy+27, 1, 2, YM)
    ellipse_fill(draw, ox+23, oy+27, 2, 3, BK)
    ellipse_fill(draw, ox+23, oy+27, 1, 2, YM)
    # little fingers
    for fx in [3,4,6]:
        px(draw, ox+fx, oy+30, BK)
        px(draw, ox+fx, oy+29, YD)
    for fx in [21,23,24]:
        px(draw, ox+fx, oy+30, BK)
        px(draw, ox+fx, oy+29, YD)

    # ── Legs ──
    ellipse_fill(draw, ox+10, oy+35, 3, 2, BK)
    ellipse_fill(draw, ox+10, oy+35, 2, 2, YD)
    ellipse_fill(draw, ox+18, oy+35, 3, 2, BK)
    ellipse_fill(draw, ox+18, oy+35, 2, 2, YD)

    # ── Feet (round) ──
    ellipse_fill(draw, ox+10, oy+37, 4, 2, BK)
    ellipse_fill(draw, ox+10, oy+37, 3, 2, YM)
    ellipse_fill(draw, ox+18, oy+37, 4, 2, BK)
    ellipse_fill(draw, ox+18, oy+37, 3, 2, YM)

    # ── Lightning bolt tail (peeking from side) ──
    px(draw, ox+22, oy+26, YD)
    px(draw, ox+23, oy+25, YD)
    px(draw, ox+24, oy+24, BK)
    px(draw, ox+25, oy+23, BK)
    px(draw, ox+24, oy+23, YVD)


def gen_sparky_front():
    """Generate 4 idle frames (front view) + happy + sleep"""
    frames = {
        'sparky_idle_0': 'open',
        'sparky_idle_1': 'open',   # same as 0, tail moves slightly
        'sparky_idle_2': 'half',
        'sparky_idle_3': 'closed',
        'sparky_happy':  'happy',
    }
    for name, eyes in frames.items():
        img = canvas(28, 40)
        draw = ImageDraw.Draw(img)
        draw_sparky_body_front(draw, 0, 0, eyes=eyes)
        # save with @2x (we'll use this as @2x in xcassets)
        img.save(f"{OUT}/sparky/{name}.png")
        print(f"  ✓ {name}.png")

    # Sleep frames (lying on side)
    for fi in range(2):
        img = canvas(36, 24)
        draw = ImageDraw.Draw(img)
        # oval body lying down
        ellipse_fill(draw, 18, 12, 13, 8, BK)
        ellipse_fill(draw, 18, 12, 12, 7, YM)
        ellipse_fill(draw, 18, 13, 9, 5, YL)
        ellipse_fill(draw, 18, 14, 7, 4, CR)
        # head on left
        circle_fill(draw, 6, 9, 7, BK)
        circle_fill(draw, 6, 9, 6, YM)
        circle_fill(draw, 4, 7, 3, YL)
        # closed eyes (z z z)
        hline(draw, 3, 8, 5, BK)
        hline(draw, 4, 8, 3, EY)
        # ear pointing up
        ellipse_fill(draw, 5, 2, 2, 5, BK)
        ellipse_fill(draw, 5, 2, 1, 4, YM)
        px(draw, 5, 3, IN)
        px(draw, 5, 4, IN)
        # tail on right
        for tx, ty in [(28,8),(29,7),(30,6),(31,7),(30,8)]:
            px(draw, tx, ty, YD)
        for tx, ty in [(28,8),(31,7)]:
            px(draw, tx, ty, BK)
        # sleep z's (animate position slightly)
        z_offset = fi * 2
        for zi, (zx, zy) in enumerate([(24+z_offset, 4), (26+z_offset, 2), (28+z_offset, 0)]):
            if 0 <= zx < 36 and 0 <= zy - zi < 24:
                px(draw, zx, zy - zi, WH)
        img.save(f"{OUT}/sparky/sparky_sleep_{fi}.png")
        print(f"  ✓ sparky_sleep_{fi}.png")


def draw_sparky_side(draw, ox, oy, leg_phase=0):
    """Draw Sparky side-facing (for walk animation). 24x28 logical pixels."""
    # Leg phase 0: neutral, 1: right forward, 2: neutral, 3: right back
    # Body
    ellipse_fill(draw, ox+12, oy+17, 7, 6, BK)
    ellipse_fill(draw, ox+12, oy+17, 6, 5, YM)
    ellipse_fill(draw, ox+12, oy+17, 4, 4, YL)
    # Head
    circle_fill(draw, ox+7,  oy+9, 7, BK)
    circle_fill(draw, ox+7,  oy+9, 6, YM)
    circle_fill(draw, ox+5,  oy+7, 3, YL)  # highlight
    # Ear
    ellipse_fill(draw, ox+5, oy+2, 2, 5, BK)
    ellipse_fill(draw, ox+5, oy+2, 1, 4, YM)
    px(draw, ox+5, oy+3, IN)
    px(draw, ox+5, oy+4, IN)
    # Eye (single, facing right)
    circle_fill(draw, ox+10, oy+8, 2, BK)
    circle_fill(draw, ox+10, oy+8, 1, EY)
    px(draw, ox+11, oy+7, WH)
    # Teal cheek (side view - just 3 dots)
    px(draw, ox+12, oy+11, TL)
    px(draw, ox+13, oy+10, TL)
    px(draw, ox+13, oy+12, TL)
    # Nose
    px(draw, ox+13, oy+9, NS)
    # Mouth
    px(draw, ox+13, oy+11, NS)
    px(draw, ox+14, oy+12, NS)
    # Tail (lightning bolt shape)
    tail_y = oy+14 + (1 if leg_phase in [1,3] else 0)
    for tx, ty in [(18,0),(19,-1),(20,-2),(20,-1),(19,0),(18,1)]:
        px(draw, ox+18+tx-18, tail_y+ty, YD)
    px(draw, ox+18, tail_y,   BK)
    px(draw, ox+20, tail_y-2, BK)
    px(draw, ox+19, tail_y+1, YVD)
    # Front leg
    front_off = [0, -2, 0, 2][leg_phase % 4]
    ellipse_fill(draw, ox+7,  oy+22+front_off, 2, 3, BK)
    ellipse_fill(draw, ox+7,  oy+22+front_off, 1, 2, YD)
    ellipse_fill(draw, ox+7,  oy+24+front_off, 3, 2, BK)
    ellipse_fill(draw, ox+7,  oy+24+front_off, 2, 1, YM)
    # Back leg
    back_off = [0, 2, 0, -2][leg_phase % 4]
    ellipse_fill(draw, ox+15, oy+22+back_off, 2, 3, BK)
    ellipse_fill(draw, ox+15, oy+22+back_off, 1, 2, YD)
    ellipse_fill(draw, ox+15, oy+24+back_off, 3, 2, BK)
    ellipse_fill(draw, ox+15, oy+24+back_off, 2, 1, YM)
    # ARM (front arm only visible from side)
    arm_off = [-1, -2, -1, 0][leg_phase % 4]
    ellipse_fill(draw, ox+5, oy+17+arm_off, 2, 2, BK)
    ellipse_fill(draw, ox+5, oy+17+arm_off, 1, 1, YD)


def gen_sparky_walk():
    """Generate 6 walk cycle frames (side view)"""
    for i in range(6):
        img = canvas(24, 30)
        draw = ImageDraw.Draw(img)
        draw_sparky_side(draw, 0, 0, leg_phase=i % 4)
        img.save(f"{OUT}/sparky/sparky_walk_{i}.png")
        print(f"  ✓ sparky_walk_{i}.png")


# ──────────────────────────────────────────────────────────────────────────────
# BACKGROUND TILES (16x16 logical pixels)
# ──────────────────────────────────────────────────────────────────────────────

def tile(name, fn):
    img = canvas(16, 16)
    draw = ImageDraw.Draw(img)
    fn(draw)
    img.save(f"{OUT}/tiles/{name}.png")
    print(f"  ✓ {name}.png")

def t_grass(draw):
    rect(draw, 0, 0, 16, 16, GR2)
    # highlights
    for x, y in [(2,3),(5,1),(9,4),(12,2),(3,7),(7,6),(13,8),(1,11),(6,10),(11,12),(4,14)]:
        px(draw, x, y, GR3)
    # darker patches
    for x, y in [(1,5),(8,9),(14,4),(3,13)]:
        px(draw, x, y, GR1)
    # tiny flowers
    px(draw, 4, 5, (255,240,160,255))
    px(draw, 12, 11, (255,200,160,255))

def t_grass_light(draw):
    rect(draw, 0, 0, 16, 16, GR1)
    for x in range(0, 16, 3):
        px(draw, x, (x*7)%16, GR3)
    for x, y in [(2,4),(7,2),(13,6),(5,11),(10,13)]:
        px(draw, x, y, GR2)

def t_path(draw):
    rect(draw, 0, 0, 16, 16, PT1)
    for y in [3, 8, 13]:
        for x in range(0, 16, 4):
            hline(draw, x, y, 2, PT2)
    for x, y in [(1,1),(5,5),(9,3),(13,7),(2,10),(7,12),(11,9),(4,14)]:
        px(draw, x, y, PT2)
    for x in range(0,16,6):
        px(draw, x, (x*3)%16, (224,192,128,255))

def t_path_h(draw):
    t_path(draw)  # same for now, can diff later

def t_tree_base(draw):
    rect(draw, 0, 0, 16, 16, GR2)
    # trunk at bottom center
    rect(draw, 6, 8, 4, 8, TR2)
    rect(draw, 7, 8, 2, 8, TR1)
    # canopy bottom layer
    ellipse_fill(draw, 8, 7, 7, 5, LE1)
    ellipse_fill(draw, 8, 7, 5, 4, LE2)
    ellipse_fill(draw, 8, 6, 3, 2, LE3)

def t_tree_top(draw):
    rect(draw, 0, 0, 16, 16, (0,0,0,0))
    ellipse_fill(draw, 8, 10, 8, 7, LE1)
    ellipse_fill(draw, 8, 10, 6, 5, LE2)
    ellipse_fill(draw, 7, 9, 3, 3, LE3)
    px(draw, 9, 7, LE3)

def t_water_0(draw):
    rect(draw, 0, 0, 16, 16, WA2)
    hline(draw, 0, 3, 16, WA1)
    hline(draw, 0, 9, 16, WA1)
    for x in [2,6,10,14]:
        hline(draw, x, 3, 3, WA3)
    for x in [0,4,8,12]:
        hline(draw, x, 9, 3, WA3)
    # foam
    for x, y in [(1,1),(5,2),(9,1),(13,2)]:
        px(draw, x, y, WA3)

def t_water_1(draw):  # wave frame 2
    rect(draw, 0, 0, 16, 16, WA2)
    hline(draw, 0, 5, 16, WA1)
    hline(draw, 0, 11, 16, WA1)
    for x in [0,4,8,12]:
        hline(draw, x, 5, 3, WA3)
    for x in [2,6,10,14]:
        hline(draw, x, 11, 3, WA3)

def t_sand(draw):
    rect(draw, 0, 0, 16, 16, SA1)
    for x, y in [(2,2),(6,5),(10,3),(14,1),(1,8),(5,10),(9,7),(13,11),(3,13),(7,15),(11,13)]:
        px(draw, x, y, SA2)
    for x, y in [(4,4),(12,6),(8,12)]:
        px(draw, x, y, (255,224,160,255))

def t_cave_wall(draw):
    rect(draw, 0, 0, 16, 16, CL1)
    # stone blocks
    for y in [0, 5, 10]:
        hline(draw, 0, y+4, 16, CL2)
    for x in [0, 7]:
        vline(draw, x, 0, 5, CL2)
    for x in [3, 11]:
        vline(draw, x, 5, 5, CL2)
    for x in [5, 13]:
        vline(draw, x, 10, 6, CL2)
    # highlights
    for x, y in [(1,1),(8,1),(4,6),(12,6),(6,11),(2,12)]:
        px(draw, x, y, (80,80,104,255))

def t_cave_floor(draw):
    rect(draw, 0, 0, 16, 16, (80, 72, 64, 255))
    for x, y in [(2,2),(8,4),(14,1),(5,7),(11,9),(3,13),(9,11),(13,14)]:
        px(draw, x, y, (104,96,88,255))
    for x, y in [(4,5),(10,7),(6,13)]:
        px(draw, x, y, (60,56,48,255))

def t_crystal(draw):
    t_cave_floor(draw)
    # crystal cluster
    vline(draw, 7, 2, 8, CR2)
    vline(draw, 8, 1, 9, CR1)
    vline(draw, 9, 3, 7, CR2)
    px(draw, 8, 0, WH)
    px(draw, 7, 1, CR1)
    px(draw, 9, 2, CR1)
    # small crystals
    vline(draw, 4, 5, 4, CR2)
    px(draw, 4, 4, CR1)
    vline(draw, 11, 6, 3, CR2)
    px(draw, 11, 5, CR1)

def t_room_wall(draw):
    rect(draw, 0, 0, 16, 16, WL1)
    # subtle diamond wallpaper pattern
    for i in range(-1, 3):
        for j in range(-1, 3):
            cx = i*8 + (j%2)*4
            cy = j*8
            for dx, dy in [(0,-2),(2,0),(0,2),(-2,0)]:
                if 0 <= cx+dx < 16 and 0 <= cy+dy < 16:
                    px(draw, cx+dx, cy+dy, WL2)

def t_room_floor(draw):
    rect(draw, 0, 0, 16, 16, FL1)
    # wood plank lines
    hline(draw, 0, 4, 16, FL2)
    hline(draw, 0, 9, 16, FL2)
    hline(draw, 0, 14, 16, FL2)
    # grain highlights
    for x in range(0, 16, 5):
        vline(draw, x, 0, 3, (184,152,104,255))
        vline(draw, (x+2)%16, 5, 3, (184,152,104,255))

def t_room_baseboard(draw):
    rect(draw, 0, 0, 16, 4, (100, 72, 40, 255))
    rect(draw, 0, 0, 16, 16, FL1)
    hline(draw, 0, 0, 16, (120, 88, 48, 255))
    hline(draw, 0, 3, 16, FL2)
    hline(draw, 0, 8, 16, FL2)
    hline(draw, 0, 13, 16, FL2)

def t_sky(draw):
    for y in range(16):
        t = y / 15
        r = int(SK1[0] + t*(SK2[0]-SK1[0]))
        g = int(SK1[1] + t*(SK2[1]-SK1[1]))
        b = int(SK1[2] + t*(SK2[2]-SK1[2]))
        hline(draw, 0, y, 16, (r,g,b,255))

def t_sky_cloud(draw):
    t_sky(draw)
    ellipse_fill(draw, 8, 8, 6, 4, (255,255,255,200))
    ellipse_fill(draw, 5, 9, 4, 3, (255,255,255,200))
    ellipse_fill(draw, 11, 9, 3, 3, (255,255,255,200))

def t_mountain_bg(draw):
    for y in range(16):
        t = y / 15
        r = int(SK2[0] + t*0.3*(90-SK2[0]))
        g = int(SK2[1] + t*0.3*(90-SK2[1]))
        b = int(SK2[2] + t*0.3*(120-SK2[2]))
        hline(draw, 0, y, 16, (r,g,b,255))
    # mountain silhouette
    for x in range(16):
        peak = max(0, 10 - abs(x-8))
        for y in range(16-peak, 16):
            px(draw, x, y, (120,120,160,255))

def t_snow_ground(draw):
    rect(draw, 0, 0, 16, 16, (240,248,255,255))
    for x, y in [(2,2),(6,5),(10,3),(14,7),(3,10),(8,12),(12,9)]:
        px(draw, x, y, (200,216,240,255))
    hline(draw, 0, 15, 16, (200,216,240,255))

def gen_tiles():
    tiles = {
        # Grass / outdoor
        'grass':        t_grass,
        'grass_light':  t_grass_light,
        'path':         t_path,
        'tree_base':    t_tree_base,
        'tree_top':     t_tree_top,
        'sky':          t_sky,
        'sky_cloud':    t_sky_cloud,
        'mountain_bg':  t_mountain_bg,
        # Water / beach
        'water_0':      t_water_0,
        'water_1':      t_water_1,
        'sand':         t_sand,
        # Cave
        'cave_wall':    t_cave_wall,
        'cave_floor':   t_cave_floor,
        'crystal':      t_crystal,
        # Room
        'room_wall':    t_room_wall,
        'room_floor':   t_room_floor,
        'room_base':    t_room_baseboard,
        # Snow
        'snow':         t_snow_ground,
    }
    for name, fn in tiles.items():
        tile(name, fn)


# ──────────────────────────────────────────────────────────────────────────────
# UI ELEMENTS
# ──────────────────────────────────────────────────────────────────────────────

def gen_ui():
    # ── Buttons (48x16 logical, 9-slice friendly) ──
    for name, base, highlight, shadow in [
        ('btn_yellow',  UI_Y1, UI_Y2, (160,120,0,255)),
        ('btn_blue',    UI_P1, UI_P2, (12,48,96,255)),
        ('btn_gray',    (88,88,96,255), (112,112,120,255), (48,48,56,255)),
        ('btn_red',     (176,40,40,255), (216,64,64,255), (112,16,16,255)),
    ]:
        img = canvas(48, 14)
        d = ImageDraw.Draw(img)
        # shadow
        rect(d, 1, 2, 46, 12, shadow)
        # main
        rect(d, 0, 0, 46, 11, base)
        # highlight
        rect(d, 1, 1, 44, 3, highlight)
        # outline
        for x in range(46):
            px(d, x, 0, BK)
            px(d, x, 11, BK)
        for y in range(12):
            px(d, 0, y, BK)
            px(d, 45, y, BK)
        # rounded corners
        px(d, 0, 0, (0,0,0,0))
        px(d, 45, 0, (0,0,0,0))
        px(d, 0, 11, (0,0,0,0))
        px(d, 45, 11, (0,0,0,0))
        img.save(f"{OUT}/ui/{name}.png")
        print(f"  ✓ {name}.png")

    # ── Panel / dialog ──
    img = canvas(80, 48)
    d = ImageDraw.Draw(img)
    rect(d, 0, 1, 80, 47, BK)
    rect(d, 1, 0, 78, 46, BK)
    rect(d, 1, 1, 78, 46, UI_PN)
    rect(d, 2, 2, 76, 44, UI_PN)
    hline(d, 2, 2, 76, WH)
    hline(d, 2, 3, 76, (240,244,255,255))
    rect(d, 2, 43, 76, 3, UI_PD)
    img.save(f"{OUT}/ui/panel.png")
    print("  ✓ panel.png")

    # ── Tab bar background ──
    img = canvas(96, 24)
    d = ImageDraw.Draw(img)
    rect(d, 0, 0, 96, 24, (18,18,42,255))
    hline(d, 0, 0, 96, (45,45,78,255))
    img.save(f"{OUT}/ui/tabbar.png")
    print("  ✓ tabbar.png")

    # ── Postcard frame ──
    img = canvas(88, 56)
    d = ImageDraw.Draw(img)
    rect(d, 0, 1, 88, 55, PC_BD)
    rect(d, 0, 0, 87, 55, PC_BG)
    rect(d, 1, 1, 85, 53, PC_BG)
    # inner border dashes
    for x in range(0, 85, 4):
        px(d, x+2, 3, PC_BD)
        px(d, x+2, 51, PC_BD)
    for y in range(0, 51, 4):
        px(d, 2, y+3, PC_BD)
        px(d, 85, y+3, PC_BD)
    # stamp area
    rect(d, 72, 4, 12, 16, (255,255,240,255))
    for x in range(72, 84, 2):
        px(d, x, 4, PC_BD)
        px(d, x, 20, PC_BD)
    for y in range(4, 21, 2):
        px(d, 72, y, PC_BD)
        px(d, 84, y, PC_BD)
    img.save(f"{OUT}/ui/postcard.png")
    print("  ✓ postcard.png")

    # ── Progress bar bg & fill ──
    for name, col in [('progress_bg', (168,184,200,255)), ('progress_fill', UI_Y2)]:
        img = canvas(80, 8)
        d = ImageDraw.Draw(img)
        rect(d, 0, 1, 80, 6, BK)
        rect(d, 1, 0, 78, 6, col)
        for x in range(1, 79, 8):
            px(d, x, 1, (255,255,255,80))
        img.save(f"{OUT}/ui/{name}.png")
        print(f"  ✓ {name}.png")


# ──────────────────────────────────────────────────────────────────────────────
# ITEM ICONS (24x24 logical)
# ──────────────────────────────────────────────────────────────────────────────

def gen_items():
    items = {
        'item_oran':     _item_berry_blue,
        'item_pecha':    _item_berry_pink,
        'item_sitrus':   _item_berry_orange,
        'item_coin':     _item_coin,
        'item_umbrella': _item_umbrella,
        'item_hat':      _item_hat,
        'item_map':      _item_map,
        'item_compass':  _item_compass,
        'item_clover':   _item_clover,
    }
    for name, fn in items.items():
        img = canvas(24, 24)
        d = ImageDraw.Draw(img)
        fn(d)
        img.save(f"{OUT}/items/{name}.png")
        print(f"  ✓ {name}.png")


def _item_berry_blue(d):
    circle_fill(d, 12, 14, 7, BK)
    circle_fill(d, 12, 14, 6, (40, 120, 200, 255))
    circle_fill(d, 12, 14, 4, (80, 160, 240, 255))
    px(d, 10, 12, WH)
    # stem + leaf
    vline(d, 12, 5, 4, (72, 128, 32, 255))
    px(d, 13, 6, (88, 160, 40, 255))
    px(d, 14, 5, (88, 160, 40, 255))

def _item_berry_pink(d):
    circle_fill(d, 12, 14, 7, BK)
    circle_fill(d, 12, 14, 6, (224, 96, 144, 255))
    circle_fill(d, 12, 14, 4, (248, 152, 192, 255))
    px(d, 10, 12, WH)
    vline(d, 12, 5, 4, (72, 128, 32, 255))
    px(d, 13, 6, (88, 160, 40, 255))
    px(d, 14, 5, (88, 160, 40, 255))

def _item_berry_orange(d):
    circle_fill(d, 12, 14, 7, BK)
    circle_fill(d, 12, 14, 6, (232, 136, 32, 255))
    circle_fill(d, 12, 14, 4, (248, 184, 80, 255))
    px(d, 10, 12, WH)
    vline(d, 12, 5, 4, (72, 128, 32, 255))
    px(d, 13, 6, (88, 160, 40, 255))
    px(d, 14, 5, (88, 160, 40, 255))

def _item_coin(d):
    circle_fill(d, 12, 12, 8, BK)
    circle_fill(d, 12, 12, 7, (192, 152, 8, 255))
    circle_fill(d, 12, 12, 5, (240, 200, 32, 255))
    circle_fill(d, 12, 12, 3, (255, 224, 80, 255))
    px(d, 11, 10, WH)
    # coin center mark
    for x, y in [(12,9),(11,12),(13,12),(12,15)]:
        px(d, x, y, (192,152,8,255))
    hline(d, 10, 12, 5, (192,152,8,255))

def _item_umbrella(d):
    # Canopy
    ellipse_fill(d, 12, 10, 9, 6, BK)
    ellipse_fill(d, 12, 10, 8, 5, (40, 100, 200, 255))
    # Segments
    for sx in [8, 12, 16]:
        vline(d, sx, 5, 6, (60, 130, 230, 255))
    # Handle
    vline(d, 12, 15, 6, BK)
    vline(d, 12, 15, 5, (96, 64, 32, 255))
    # Hook
    px(d, 11, 21, BK)
    px(d, 10, 21, BK)
    px(d, 10, 20, BK)
    px(d, 11, 21, (96, 64, 32, 255))

def _item_hat(d):
    # Brim
    rect(d, 4, 16, 16, 3, BK)
    rect(d, 5, 16, 14, 2, (60, 40, 20, 255))
    # Crown
    rect(d, 7, 6, 10, 11, BK)
    rect(d, 8, 7, 8, 10, (60, 40, 20, 255))
    rect(d, 8, 7, 8, 2, (80, 56, 24, 255))
    # Band
    hline(d, 8, 15, 8, (200, 160, 40, 255))

def _item_map(d):
    rect(d, 3, 3, 18, 18, BK)
    rect(d, 4, 4, 16, 16, (240, 224, 192, 255))
    rect(d, 4, 4, 16, 1, (220, 200, 168, 255))
    # fold lines
    vline(d, 11, 4, 16, (200, 180, 144, 255))
    hline(d, 4, 11, 16, (200, 180, 144, 255))
    # map features
    circle_fill(d, 8, 8, 2, (40, 120, 200, 255))
    for x, y in [(7,8),(9,8),(8,7),(8,9)]:
        px(d, x, y, (64,152,232,255))
    for x, y in [(13,14),(14,13),(14,15),(15,14)]:
        px(d, x, y, (200,80,40,255))
    # path
    for x in range(10, 13): px(d, x, 10, (180,140,80,255))
    for y in range(10, 14): px(d, 12, y, (180,140,80,255))

def _item_compass(d):
    circle_fill(d, 12, 12, 9, BK)
    circle_fill(d, 12, 12, 8, (224, 216, 200, 255))
    circle_fill(d, 12, 12, 6, (240, 232, 216, 255))
    # compass rose
    vline(d, 12, 6, 4, (200, 40, 40, 255))   # N red
    vline(d, 12, 14, 3, (80, 80, 80, 255))   # S gray
    hline(d, 6, 12, 4, (80, 80, 80, 255))    # W
    hline(d, 14, 12, 3, (80, 80, 80, 255))   # E
    px(d, 12, 12, BK)

def _item_clover(d):
    for cx, cy in [(8,12),(16,12),(12,8)]:
        circle_fill(d, cx, cy, 4, BK)
        circle_fill(d, cx, cy, 3, (48, 160, 48, 255))
        px(d, cx-1, cy-1, (88, 200, 88, 255))
    # stem
    vline(d, 12, 16, 6, (48,128,32,255))
    px(d, 11, 19, (64,160,40,255))
    px(d, 13, 20, (64,160,40,255))


# ──────────────────────────────────────────────────────────────────────────────
# WINDOW / FURNITURE SPRITES
# ──────────────────────────────────────────────────────────────────────────────

def gen_room_furniture():
    # Window (48x40 logical)
    img = canvas(48, 40)
    d = ImageDraw.Draw(img)
    # Frame
    rect(d, 0, 0, 48, 40, (120, 88, 48, 255))
    rect(d, 3, 3, 42, 34, SK1)
    # Sky gradient
    for y in range(3, 37):
        t = (y-3)/33
        r = int(SK1[0] - t*20)
        g = int(SK1[1] - t*10)
        b = int(SK1[2] - t*5)
        hline(d, 3, y, 42, (r,g,b,255))
    # Sun
    circle_fill(d, 36, 10, 5, (255,240,80,255))
    circle_fill(d, 36, 10, 4, (255,224,40,255))
    # Cloud
    ellipse_fill(d, 12, 10, 8, 4, WH)
    ellipse_fill(d, 8, 11, 5, 4, WH)
    ellipse_fill(d, 17, 11, 4, 3, WH)
    # Tree tops
    ellipse_fill(d, 10, 32, 8, 6, LE1)
    ellipse_fill(d, 10, 32, 6, 4, LE2)
    ellipse_fill(d, 36, 33, 7, 5, LE1)
    ellipse_fill(d, 36, 33, 5, 4, LE2)
    # Cross bar
    vline(d, 23, 3, 34, (100, 72, 32, 255))
    hline(d, 3, 20, 42, (100, 72, 32, 255))
    # Frame outline
    rect(d, 0, 0, 2, 40, BK)
    rect(d, 46, 0, 2, 40, BK)
    rect(d, 0, 0, 48, 2, BK)
    rect(d, 0, 38, 48, 2, BK)
    img.save(f"{OUT}/ui/window.png")
    print("  ✓ window.png")

    # Bookshelf (40x48 logical)
    img = canvas(40, 56)
    d = ImageDraw.Draw(img)
    # Frame
    rect(d, 0, 0, 40, 56, BK)
    rect(d, 1, 1, 38, 54, (96, 64, 24, 255))
    # Shelves
    for sy in [16, 32, 48]:
        hline(d, 1, sy, 38, (128, 88, 32, 255))
    # Books on each shelf
    book_cols = [
        [(4,(200,48,48,255)),(9,(48,100,200,255)),(14,(48,160,48,255)),
         (19,(220,160,32,255)),(24,(160,48,160,255)),(29,(200,80,40,255)),(34,(80,160,80,255))],
        [(3,(160,40,40,255)),(8,(40,80,180,255)),(13,(32,140,32,255)),
         (18,(192,140,16,255)),(23,(120,40,120,255)),(28,(64,64,180,255)),(33,(180,80,32,255))],
        [(4,(48,140,200,255)),(9,(200,100,48,255)),(14,(80,48,160,255)),
         (19,(48,160,120,255)),(24,(200,48,80,255)),(29,(120,160,40,255)),(34,(80,120,200,255))],
    ]
    for si, (shelf_y, books) in enumerate([(3, book_cols[0]),(19, book_cols[1]),(35, book_cols[2])]):
        for bx, bc in books:
            bh = 10 + (bx % 3)
            rect(d, bx, shelf_y + (13 - bh), 4, bh, bc)
            rect(d, bx, shelf_y + (13 - bh), 4, 1, (min(bc[0]+40,255), min(bc[1]+40,255), min(bc[2]+40,255), 255))
    # Plant on top
    circle_fill(d, 20, 6, 5, LE2)
    circle_fill(d, 20, 6, 3, LE3)
    circle_fill(d, 16, 8, 3, LE2)
    circle_fill(d, 24, 8, 3, LE2)
    ellipse_fill(d, 20, 12, 4, 3, (96, 64, 32, 255))
    ellipse_fill(d, 20, 12, 3, 2, (128, 88, 40, 255))
    img.save(f"{OUT}/ui/bookshelf.png")
    print("  ✓ bookshelf.png")

    # Table (64x24 logical)
    img = canvas(64, 24)
    d = ImageDraw.Draw(img)
    # Tabletop
    rect(d, 0, 0, 64, 8, BK)
    rect(d, 1, 0, 62, 7, (128, 88, 40, 255))
    rect(d, 1, 0, 62, 2, (160, 112, 56, 255))
    # Legs
    for lx in [6, 54]:
        rect(d, lx, 7, 5, 17, BK)
        rect(d, lx+1, 7, 3, 16, (96, 64, 24, 255))
    img.save(f"{OUT}/ui/table.png")
    print("  ✓ table.png")


# ──────────────────────────────────────────────────────────────────────────────
# APP ICON
# ──────────────────────────────────────────────────────────────────────────────

def gen_app_icon():
    sizes = [1024, 180, 120, 87, 80, 60, 58, 40, 29]
    for size in sizes:
        img = Image.new('RGB', (size, size), (24, 20, 48))
        d = ImageDraw.Draw(img)
        # Background gradient
        for y in range(size):
            t = y / size
            r = int(24 + t*8)
            g = int(20 + t*8)
            b = int(48 + t*16)
            d.line([(0,y),(size,y)], fill=(r,g,b))
        # Outer glow ring
        from PIL import ImageFilter
        cx, cy = size//2, size//2
        r_outer = int(size * 0.42)
        r_inner = int(size * 0.37)
        for y in range(size):
            for x in range(size):
                dist = math.sqrt((x-cx)**2 + (y-cy)**2)
                if r_inner <= dist <= r_outer:
                    alpha = 1 - abs(dist - (r_inner+r_outer)/2) / ((r_outer-r_inner)/2)
                    r,g,b = 64+int(alpha*80), 184+int(alpha*40), 216
                    cur = img.getpixel((x,y))
                    img.putpixel((x,y), (
                        min(255, cur[0]+int(alpha*r)),
                        min(255, cur[1]+int(alpha*g)),
                        min(255, cur[2]+int(alpha*b))
                    ))
        # Draw Sparky character centered (scaled to icon)
        sc = max(1, size // 80)
        char_size = 28 * sc
        char_x = (size - char_size) // 2
        char_y = (size - 40*sc) // 2 - sc*2
        # Simple Sparky at this scale
        _draw_icon_sparky(d, char_x, char_y, sc, size)
        fname = f"{OUT}/ui/icon_{size}.png"
        img.save(fname)
    print(f"  ✓ App icons ({len(sizes)} sizes)")


def _draw_icon_sparky(d, ox, oy, sc, size):
    """Draw simplified Sparky for app icon at scale sc"""
    def px_icon(x, y, c):
        d.rectangle([ox+x*sc, oy+y*sc, ox+x*sc+sc-1, oy+y*sc+sc-1], fill=c)
    def el_icon(cx, cy, rx, ry, c):
        for dy in range(-ry, ry+1):
            for dx in range(-rx, rx+1):
                if (dx/max(rx,0.1))**2 + (dy/max(ry,0.1))**2 <= 1.0:
                    px_icon(cx+dx, cy+dy, c)
    # Body
    el_icon(14, 30, 8, 7, (28,28,28,255))
    el_icon(14, 30, 7, 6, (248,208,48,255))
    el_icon(14, 31, 5, 4, (255,248,200,255))
    # Head
    el_icon(14, 18, 10, 9, (28,28,28,255))
    el_icon(14, 18, 9, 8, (248,208,48,255))
    el_icon(11, 15, 4, 3, (252,232,88,255))
    # Ears
    for ex in [7, 21]:
        el_icon(ex, 6, 3, 7, (28,28,28,255))
        el_icon(ex, 6, 2, 6, (248,208,48,255))
        el_icon(ex, 7, 1, 4, (248,160,96,255))
    # Eyes
    for ex2 in [10, 18]:
        el_icon(ex2, 17, 3, 3, (28,28,28,255))
        el_icon(ex2, 17, 2, 2, (56,36,8,255))
        px_icon(ex2+1, 15, (248,248,248,255))
    # Teal cheek stars
    for ck in [8, 20]:
        for dx, dy in [(0,0),(-1,0),(1,0),(0,-1),(0,1)]:
            px_icon(ck+dx, 21+dy, (64,184,216,255))
    # Lightning bolt detail (small)
    for tx, ty in [(22,25),(23,24),(24,23),(24,24),(23,25)]:
        px_icon(tx, ty, (200,152,0,255))


# ──────────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    print("🎨 Generating Sparky sprites...")
    gen_sparky_front()
    gen_sparky_walk()

    print("\n🌲 Generating background tiles...")
    gen_tiles()

    print("\n🎮 Generating UI elements...")
    gen_ui()
    gen_room_furniture()

    print("\n🎒 Generating item icons...")
    gen_items()

    print("\n📱 Generating app icons...")
    gen_app_icon()

    print("\n✅ All assets generated!")
    import subprocess
    r = subprocess.run(['find', OUT, '-name', '*.png'], capture_output=True, text=True)
    print(f"Total files: {len(r.stdout.strip().split(chr(10)))}")
