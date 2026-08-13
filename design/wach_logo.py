#!/usr/bin/env python
"""W.A.C.H. Logo — die gewaehlte Variante v1 als wiederverwendbare Quelle.

Das Motiv ist ein W, dessen letzter Aufstrich in derselben Richtung
weiterlaeuft und in einer Pfeilspitze endet: Buchstabe und Aufwaertstrend
in einer Linie (Progressive Overload).

Gezeichnet statt generiert — ein App-Icon braucht exakte Symmetrie und
scharfe Kanten in jeder Groesse. Jede Ausgabe wird stark ueberabgetastet
und dann heruntergerechnet, das ergibt saubere Kantenglaettung.

Verwendet von make_app_icons.py.
"""
import math

from PIL import Image, ImageDraw

# Farben aus lib/core/theme/app_colors.dart
BG = (18, 18, 18)              # #121212 background
GREEN = (76, 175, 80)          # #4CAF50 primary
GREEN_LIGHT = (129, 199, 132)  # #81C784 primaryLight

# Aufloesung, in der das Motiv intern gezeichnet wird.
_WORK = 2048


def _draw_motif(size=_WORK):
    """Das blanke Motiv auf transparentem Grund, ohne Hintergrund."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w = int(size * 0.085)  # Strichstaerke

    # W-Grundform im Einheitsraster, dann auf die Flaeche skaliert
    pad_x, pad_y = 0.20, 0.30
    span_x, span_y = 0.60, 0.34
    pts = [(0.0, 0.0), (0.22, 1.0), (0.5, 0.30), (0.78, 1.0), (1.0, 0.0)]
    xy = [
        (pad_x * size + px * span_x * size,
         pad_y * size + py * span_y * size)
        for px, py in pts
    ]
    d.line(xy, fill=GREEN, width=w, joint="curve")

    # Aufstrich in exakt derselben Richtung verlaengern, damit Buchstabe
    # und Pfeil eine durchgehende Linie bleiben.
    (x0, y0), (x1, y1) = xy[-2], xy[-1]
    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy)
    ext = 0.17 * size
    tip = (x1 + dx / length * ext, y1 + dy / length * ext)
    d.line([(x1, y1), tip], fill=GREEN_LIGHT, width=w, joint="curve")
    _arrow_head(d, (x1, y1), tip, 0.085 * size, GREEN_LIGHT)

    return img


def _arrow_head(d, start, end, size, color):
    """Pfeilspitze in Laufrichtung start->end, zentriert auf end."""
    ang = math.atan2(end[1] - start[1], end[0] - start[0])
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


# Einmal zeichnen, auf den sichtbaren Inhalt zuschneiden und
# wiederverwenden — so ist das Motiv in jeder Ausgabe exakt zentriert.
_MOTIF = None


def _motif_cropped():
    global _MOTIF
    if _MOTIF is None:
        raw = _draw_motif()
        _MOTIF = raw.crop(raw.getbbox())
    return _MOTIF


def render(size, style="rounded", motif_frac=0.62):
    """Ein Icon in der gewuenschten Groesse erzeugen.

    style:
      "rounded" — abgerundetes Quadrat (Web, Android, macOS)
      "square"  — volle Flaeche ohne Rundung (iOS maskiert selbst;
                  transparente Ecken sind dort nicht erlaubt)
      "maskable"— wie square, Motiv aber klein genug fuer die
                  Safe Zone (Android schneidet bis zu einem Kreis
                  mit 80% Durchmesser zu)
    motif_frac: Anteil der Kantenlaenge, den das Motiv einnimmt.
    """
    work = max(size * 4, 512)

    if style == "rounded":
        base = Image.new("RGBA", (work, work), (0, 0, 0, 0))
        d = ImageDraw.Draw(base)
        d.rounded_rectangle(
            [0, 0, work - 1, work - 1],
            radius=int(work * 0.22),
            fill=BG + (255,),
        )
    else:
        base = Image.new("RGBA", (work, work), BG + (255,))

    motif = _motif_cropped()
    target = int(work * motif_frac)
    ratio = target / max(motif.size)
    new_size = (
        max(1, int(motif.size[0] * ratio)),
        max(1, int(motif.size[1] * ratio)),
    )
    scaled = motif.resize(new_size, Image.LANCZOS)

    base.alpha_composite(
        scaled,
        ((work - new_size[0]) // 2, (work - new_size[1]) // 2),
    )
    return base.resize((size, size), Image.LANCZOS)


def render_rgb(size, style="square", motif_frac=0.62):
    """Wie render(), aber ohne Alphakanal — fuer iOS Pflicht."""
    img = render(size, style=style, motif_frac=motif_frac)
    flat = Image.new("RGB", img.size, BG)
    flat.paste(img, mask=img.split()[3])
    return flat
