#!/usr/bin/env python
"""Das Logo als Bild fuer die App-Oberflaeche.

make_app_icons.py erzeugt die Icons fuer Startbildschirm, Browser-Tab und
Launcher. Innerhalb der App fehlte das Logo bisher — dort stand ein
allgemeines Material-Icon. Dieses Skript liefert das Bild dafuer.

Bewusst dasselbe Motiv wie das App-Icon, mit Hintergrund und Rundung: Wer
die App vom Startbildschirm oeffnet, soll oben dasselbe Zeichen wiederfinden.

Flutter waehlt anhand der Pixeldichte aus, deshalb drei Groessen:
`wach-icon.png` fuer 1x, `2.0x/` und `3.0x/` daneben. Die Basisgroesse
entspricht der Darstellung in `home_screen.dart`.
"""
from pathlib import Path

from wach_logo import render

# Kantenlaenge in logischen Pixeln, wie im Home-Header dargestellt.
BASIS = 80

ZIEL = Path(__file__).resolve().parent.parent / "wach_flutter" / "assets" / "logo"


def main() -> None:
    for faktor, unterordner in ((1, ""), (2, "2.0x"), (3, "3.0x")):
        ordner = ZIEL / unterordner if unterordner else ZIEL
        ordner.mkdir(parents=True, exist_ok=True)
        pfad = ordner / "wach-icon.png"
        render(BASIS * faktor, "rounded", motif_frac=0.62).save(pfad)
        print(f"{pfad.relative_to(ZIEL.parents[2])}  ({BASIS * faktor}px)")


if __name__ == "__main__":
    main()
