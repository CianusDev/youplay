"""Génère les images du logo YouPlay (icône d'app, premier plan adaptatif, splash).

Logo : fond jaune doux, disque noir, triangle « lecture » blanc aux coins arrondis.
Usage : python3 tools/make_icons.py   (écrit dans assets/branding/)
"""
from pathlib import Path

from PIL import Image, ImageDraw

YELLOW = (0xFF, 0xE8, 0x78, 255)  # SikaColors.yellowSoft
INK = (0x14, 0x12, 0x08, 255)      # SikaColors.onYellow
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
SS = 4  # suréchantillonnage (anticrénelage)
OUT = Path(__file__).resolve().parent.parent / 'assets' / 'branding'


def rounded_triangle(d, pts, r, fill, steps=24):
    """Triangle aux coins arrondis : chaque coin est remplacé par un arc tangent de rayon r."""
    import math
    out = []
    n = len(pts)
    for i in range(n):
        px, py = pts[i]
        ax, ay = pts[i - 1]
        bx, by = pts[(i + 1) % n]
        ux, uy = ax - px, ay - py
        vx, vy = bx - px, by - py
        lu, lv = math.hypot(ux, uy), math.hypot(vx, vy)
        ux, uy, vx, vy = ux / lu, uy / lu, vx / lv, vy / lv
        theta = math.acos(max(-1.0, min(1.0, ux * vx + uy * vy)))
        t = r / math.tan(theta / 2)                       # distance coin → points de tangence
        bxs, bys = ux + vx, uy + vy
        lb = math.hypot(bxs, bys)
        cx, cy = px + bxs / lb * r / math.sin(theta / 2), py + bys / lb * r / math.sin(theta / 2)
        p1 = (px + ux * t, py + uy * t)
        p2 = (px + vx * t, py + vy * t)
        a1 = math.atan2(p1[1] - cy, p1[0] - cx)
        a2 = math.atan2(p2[1] - cy, p2[0] - cx)
        da = (a2 - a1 + math.pi) % (2 * math.pi) - math.pi  # petit arc
        for k in range(steps + 1):
            a = a1 + da * k / steps
            out.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    d.polygon(out, fill=fill)


def draw_mark(d, size, scale=1.0):
    """Disque noir + triangle blanc, centrés dans un carré de `size`."""
    c = size / 2
    rd = size * 0.33 * scale  # disque ≈ 66 % de la largeur (maquette)
    d.ellipse([c - rd, c - rd, c + rd, c + rd], fill=INK)
    h = rd * 1.0             # hauteur du triangle
    w = h * 0.88             # largeur (pointe vers la droite)
    ox = rd * 0.07           # décalage optique vers la droite
    pts = [(c - w / 2 + ox, c - h / 2), (c - w / 2 + ox, c + h / 2), (c + w / 2 + ox, c)]
    rounded_triangle(d, pts, rd * 0.13, WHITE)


def render(size, bg, scale=1.0, rounded=False):
    big = size * SS
    img = Image.new('RGBA', (big, big), CLEAR)
    d = ImageDraw.Draw(img)
    if rounded:  # carré arrondi (splash < Android 12)
        d.rounded_rectangle([0, 0, big - 1, big - 1], radius=big * 0.22, fill=bg)
    elif bg != CLEAR:
        d.rectangle([0, 0, big, big], fill=bg)
    draw_mark(d, big, scale)
    return img.resize((size, size), Image.LANCZOS)


def padded(img, canvas):
    out = Image.new('RGBA', (canvas, canvas), CLEAR)
    out.paste(img, ((canvas - img.width) // 2, (canvas - img.height) // 2), img)
    return out


OUT.mkdir(parents=True, exist_ok=True)
render(1024, YELLOW).save(OUT / 'icon.png')                         # iOS, web, Android ancien
render(1024, CLEAR, scale=0.70).save(OUT / 'icon_foreground.png')    # icône adaptative (zone sûre)
render(768, YELLOW, rounded=True).save(OUT / 'splash.png')           # splash Android ≤ 11 / iOS
padded(render(768, CLEAR, scale=1.0), 1152).save(OUT / 'splash_android12.png')  # splash Android 12+ (cercle)
print('ok ->', OUT)
