#!/usr/bin/env python3
"""Small local control panel for the BULDACITY main PC installation."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = Path(__file__).with_name("install.py")


def run_update() -> int:
    return subprocess.call([sys.executable, str(INSTALLER), "--update", "--target", str(ROOT)])


def main() -> int:
    while True:
        print("\n" + "=" * 58)
        print(" BULDACITY / 2 - MAIN PC")
        print("=" * 58)
        print(f"Installation: {ROOT}")
        print("1) Repository aktualisieren")
        print("2) README anzeigen")
        print("3) Ordner öffnen")
        print("0) Beenden")
        choice = input("> ").strip()
        if choice == "1":
            run_update()
        elif choice == "2":
            readme = ROOT / "README.md"
            if readme.exists():
                print("\n" + readme.read_text(encoding="utf-8", errors="replace"))
            else:
                print("README.md nicht gefunden.")
        elif choice == "3":
            if sys.platform.startswith("win"):
                subprocess.Popen(["explorer", str(ROOT)])
            elif sys.platform == "darwin":
                subprocess.Popen(["open", str(ROOT)])
            else:
                subprocess.Popen(["xdg-open", str(ROOT)])
        elif choice == "0":
            return 0


if __name__ == "__main__":
    raise SystemExit(main())
