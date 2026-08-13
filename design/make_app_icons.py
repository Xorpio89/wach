#!/usr/bin/env python
"""Erzeugt den kompletten App-Icon-Satz aus dem W.A.C.H.-Logo (v1).

Ersetzt die Flutter-Standardicons auf allen Plattformen:
  Web (Favicon, PWA inkl. maskable), Android, iOS, macOS, Windows.

Bewusst ohne flutter_launcher_icons: das Projekt haengt auf Dart 3.5
fest (siehe CLAUDE.md) und pflegt eine Liste verbotener Packages —
eine weitere Abhaengigkeit mit eigenem SDK-Constraint waere ein Risiko
fuer nichts. Hier ist die Groessenliste ohnehin explizit.

  python make_app_icons.py [--dry-run]
"""
import sys
from pathlib import Path

from wach_logo import render, render_rgb

# design/ -> wach/ -> wach_flutter/
ROOT = Path(__file__).resolve().parent.parent / "wach_flutter"

DRY = "--dry-run" in sys.argv


def write(img, rel_path):
    path = ROOT / rel_path
    if not path.parent.exists():
        print(f"  UEBERSPRUNGEN (Ordner fehlt): {rel_path}")
        return False
    if DRY:
        print(f"  [dry-run] {rel_path}  {img.size[0]}px")
        return True
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"  {rel_path}  {img.size[0]}px")
    return True


def web():
    print("Web:")
    # Favicon klein -> Motiv groesser, sonst verschwindet es
    write(render(32, "rounded", motif_frac=0.78), "web/favicon.png")
    write(render(192, "rounded"), "web/icons/Icon-192.png")
    write(render(512, "rounded"), "web/icons/Icon-512.png")
    # Maskable: Android beschneidet bis auf einen Kreis mit 80%
    # Durchmesser. Das Motiv muss in dessen einbeschriebenes Quadrat
    # passen (0.8/sqrt(2) = 0.57) — 0.50 laesst Sicherheitsabstand.
    write(
        render(192, "maskable", motif_frac=0.50),
        "web/icons/Icon-maskable-192.png",
    )
    write(
        render(512, "maskable", motif_frac=0.50),
        "web/icons/Icon-maskable-512.png",
    )


def android():
    print("Android:")
    sizes = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    for dpi, px in sizes.items():
        frac = 0.72 if px <= 72 else 0.62
        write(
            render(px, "rounded", motif_frac=frac),
            f"android/app/src/main/res/mipmap-{dpi}/ic_launcher.png",
        )


def ios():
    print("iOS:")
    # Namen und Kantenlaengen laut Contents.json des Runner-Targets.
    # iOS erlaubt keine Transparenz und rundet selbst -> "square".
    icons = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    base = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for name, px in icons:
        frac = 0.76 if px <= 40 else 0.62
        write(render_rgb(px, "square", motif_frac=frac), f"{base}/{name}")


def macos():
    print("macOS:")
    base = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for px in (16, 32, 64, 128, 256, 512, 1024):
        frac = 0.80 if px <= 32 else 0.62
        write(
            render(px, "rounded", motif_frac=frac),
            f"{base}/app_icon_{px}.png",
        )


def windows():
    print("Windows:")
    path = ROOT / "windows/runner/resources/app_icon.ico"
    if not path.parent.exists():
        print("  UEBERSPRUNGEN (Ordner fehlt)")
        return
    if DRY:
        print("  [dry-run] windows/runner/resources/app_icon.ico")
        return
    # Multi-Resolution-ICO: Windows waehlt je Kontext die passende.
    master = render(256, "rounded")
    master.save(
        path,
        format="ICO",
        sizes=[(16, 16), (32, 32), (48, 48), (64, 64),
               (128, 128), (256, 256)],
    )
    print("  windows/runner/resources/app_icon.ico  16-256px")


def preview():
    """Kontaktbogen zur Sichtpruefung, bevor irgendwas ausgeliefert wird."""
    from PIL import Image

    out = Path(__file__).parent / "logo-drafts" / "_icon-satz.png"
    shots = [
        ("rounded 512", render(512, "rounded")),
        ("maskable", render(512, "maskable", motif_frac=0.50)),
        ("iOS 512", render_rgb(512, "square").convert("RGBA")),
        ("favicon 32", render(32, "rounded", 0.78).resize(
            (512, 512), Image.NEAREST)),
    ]
    pad = 24
    w = len(shots) * 512 + (len(shots) + 1) * pad
    sheet = Image.new("RGB", (w, 512 + 2 * pad), (10, 10, 10))
    x = pad
    for _, im in shots:
        sheet.paste(im.convert("RGB"), (x, pad))
        x += 512 + pad
    sheet.save(out)
    print(f"\nVorschau: {out.name}  ({', '.join(s[0] for s in shots)})")


def main():
    print(f"Ziel: {ROOT}\n")
    web()
    android()
    ios()
    macos()
    windows()
    preview()
    print("\nFertig.")


if __name__ == "__main__":
    main()
