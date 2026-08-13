#!/usr/bin/env python
"""W.A.C.H. Logo-Entwuerfe — vier Varianten als PNG.

Bewusst geometrisch gezeichnet statt per Bildgenerierung: ein App-Icon
braucht exakte Symmetrie und scharfe Kanten in jeder Groesse. Diffusions-
modelle liefern bei Icons ausgefranste Raender und unsauberen Text.

Gezeichnet wird 4x ueberabgetastet und dann heruntergerechnet — das gibt
saubere Kantenglaettung ohne externe Renderer.

  python make_logo_drafts.py
"""
import math

from PIL import Image, ImageDraw
from pathlib import Path

OUT = Path(__file__).parent / "logo-drafts"
SIZE = 512
SS = 4  # Supersampling-Faktor
C = SIZE * SS

BG = (18, 18, 18)          # #121212 App-Hintergrund
GREEN = (76, 175, 80)      # #4CAF50 Primary
GREEN_LIGHT = (129, 199, 132)  # #81C784
ORANGE = (255, 152, 0)     # #FF9800 Secondary


def arrow_head(d, start, end, size, color):
    """Pfeilspitze in Laufrichtung start->end, zentriert auf end.

    Der Winkel muss aus der Strichrichtung kommen — ein fest gedrehtes
    Dreieck sitzt sonst schief auf der Linie.
    """
    ang = math.atan2(end[1] - start[1], end[0] - start[0])
    # Die Spitze ragt um size/2 ueber den Linienendpunkt hinaus, damit
    # Linie und Dreieck nahtlos ineinander laufen.
    tip = (
        end[0] + math.cos(ang) * size * 0.5,
        end[1] + math.sin(ang) * size * 0.5,
    )
    left = ang + math.radians(140)
    right = ang - math.radians(140)
    d.polygon(
        [
            tip,
            (tip[0] + math.cos(left) * size,
             tip[1] + math.sin(left) * size),
            (tip[0] + math.cos(right) * size,
             tip[1] + math.sin(right) * size),
        ],
        fill=color,
    )


def canvas():
    """Neues Bild mit abgerundetem dunklem Icon-Hintergrund."""
    img = Image.new("RGB", (C, C), BG)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(
        [0, 0, C - 1, C - 1], radius=int(C * 0.22), fill=BG
    )
    return img, d


def finish(img, name):
    """Herunterrechnen und speichern."""
    out = img.resize((SIZE, SIZE), Image.LANCZOS)
    path = OUT / f"{name}.png"
    out.save(path)
    print(f"  {path.name}")
    return out


def v1_monogram_arrow():
    """W als Zickzack, dessen letzter Aufstrich zum Pfeil wird.

    Liest als 'W' und gleichzeitig als Aufwaertstrend — Progressive
    Overload ist der Kern der App.
    """
    img, d = canvas()
    w = int(C * 0.085)  # Strichstaerke

    # W-Grundform im Raster 0..1, dann auf Canvas skaliert
    pad_x, pad_y = 0.20, 0.30
    span_x, span_y = 0.60, 0.34
    pts = [(0.0, 0.0), (0.22, 1.0), (0.5, 0.30), (0.78, 1.0), (1.0, 0.0)]
    xy = [
        (pad_x * C + px * span_x * C, pad_y * C + py * span_y * C)
        for px, py in pts
    ]
    d.line(xy, fill=GREEN, width=w, joint="curve")

    # Aufstrich verlaengern: in exakt derselben Richtung wie der letzte
    # W-Schenkel, damit Buchstabe und Pfeil eine Linie bleiben.
    x0, y0 = xy[-2]
    x1, y1 = xy[-1]
    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy)
    ext = 0.17 * C
    tip = (x1 + dx / length * ext, y1 + dy / length * ext)
    d.line([(x1, y1), tip], fill=GREEN_LIGHT, width=w, joint="curve")
    arrow_head(d, (x1, y1), tip, 0.085 * C, GREEN_LIGHT)
    return finish(img, "v1-monogramm-pfeil")


def v2_dumbbell_curve():
    """Hantel mit aufsteigender Kurve darueber."""
    img, d = canvas()

    cy = C * 0.62
    bar_h = int(C * 0.055)
    # Stange
    d.rounded_rectangle(
        [C * 0.26, cy - bar_h / 2, C * 0.74, cy + bar_h / 2],
        radius=bar_h / 2,
        fill=GREEN,
    )
    # Gewichtsscheiben: je Seite innen gross, aussen klein
    for sx, direction in ((0.26, -1), (0.74, 1)):
        for off, hh, ww in ((0.015, 0.15, 0.035), (0.065, 0.10, 0.030)):
            x = C * sx + direction * C * off
            d.rounded_rectangle(
                [
                    x - C * ww / 2,
                    cy - C * hh,
                    x + C * ww / 2,
                    cy + C * hh,
                ],
                radius=C * 0.012,
                fill=GREEN,
            )

    # Aufsteigende Kurve darueber, symmetrisch ueber der Hantel
    curve = [
        (C * 0.30, C * 0.40),
        (C * 0.44, C * 0.35),
        (C * 0.57, C * 0.28),
        (C * 0.66, C * 0.20),
    ]
    d.line(curve, fill=ORANGE, width=int(C * 0.05), joint="curve")
    arrow_head(d, curve[-2], curve[-1], C * 0.062, ORANGE)
    return finish(img, "v2-hantel-kurve")


def v3_pulse_ring():
    """EKG-Linie in einem offenen Ring."""
    img, d = canvas()

    r = C * 0.30
    cx = cy = C / 2
    ring_w = int(C * 0.055)
    # Ring mit Luecke, wo die Pulslinie austritt
    d.arc(
        [cx - r, cy - r, cx + r, cy + r],
        start=200, end=160,
        fill=GREEN, width=ring_w,
    )

    # Pulslinie
    pts = [
        (cx - r * 1.12, cy),
        (cx - r * 0.55, cy),
        (cx - r * 0.34, cy - r * 0.46),
        (cx - r * 0.10, cy + r * 0.52),
        (cx + r * 0.16, cy - r * 0.62),
        (cx + r * 0.40, cy),
        (cx + r * 1.12, cy),
    ]
    d.line(pts, fill=GREEN_LIGHT, width=int(C * 0.05), joint="curve")
    return finish(img, "v3-puls-ring")


def v4_bars_w():
    """Fuenf Balken, deren Oberkanten ein W ergeben.

    Jeder Balken steht fuer einen Satz — das Motiv ist damit zugleich
    ein Fortschrittsdiagramm.
    """
    img, d = canvas()

    heights = [0.60, 0.28, 0.46, 0.28, 0.60]
    colors = [GREEN, GREEN_LIGHT, GREEN, GREEN_LIGHT, GREEN]
    n = len(heights)
    total_w = 0.56
    gap = 0.026
    bar_w = (total_w - gap * (n - 1)) / n
    base_y = C * 0.72
    x = (1.0 - total_w) / 2

    for h, col in zip(heights, colors):
        top = base_y - C * h
        d.rounded_rectangle(
            [x * C, top, (x + bar_w) * C, base_y],
            radius=C * bar_w * 0.42,
            fill=col,
        )
        x += bar_w + gap

    # Grundlinie — schmaler als die Balkengruppe und duenn, damit sie
    # als Basis liest und nicht mit den Balken konkurriert.
    d.rounded_rectangle(
        [C * 0.23, base_y + C * 0.038, C * 0.77, base_y + C * 0.058],
        radius=C * 0.010,
        fill=ORANGE,
    )
    return finish(img, "v4-balken-w")


def contact_sheet(images):
    """Alle Varianten nebeneinander, zum Vergleich in einer Datei."""
    pad = 24
    label_h = 0
    w = len(images) * SIZE + (len(images) + 1) * pad
    sheet = Image.new("RGB", (w, SIZE + 2 * pad + label_h), (10, 10, 10))
    x = pad
    for im in images:
        sheet.paste(im, (x, pad))
        x += SIZE + pad
    path = OUT / "_uebersicht.png"
    sheet.save(path)
    print(f"  {path.name}")

    # Zusaetzlich: alle Varianten klein, wie sie als App-Icon aussehen
    small = 96
    w2 = len(images) * small + (len(images) + 1) * pad
    sheet2 = Image.new("RGB", (w2, small + 2 * pad), (10, 10, 10))
    x = pad
    for im in images:
        sheet2.paste(im.resize((small, small), Image.LANCZOS), (x, pad))
        x += small + pad
    path2 = OUT / "_uebersicht-klein.png"
    sheet2.save(path2)
    print(f"  {path2.name}  (96px — Homescreen-Groesse)")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    print("W.A.C.H. Logo-Entwuerfe:")
    images = [
        v1_monogram_arrow(),
        v2_dumbbell_curve(),
        v3_pulse_ring(),
        v4_bars_w(),
    ]
    contact_sheet(images)
    print(f"\nFertig — {OUT}")


if __name__ == "__main__":
    main()
