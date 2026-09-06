#!/usr/bin/env python3
"""BULDACITY / 2 - Main PC installer and updater.

Downloads the complete public xDarkixx/lua2 repository as a release-style ZIP,
installs it into a local BULDACITY directory, creates launch helpers, and keeps
backups of files that are replaced. No Git installation is required.
"""

from __future__ import annotations

import argparse
import datetime as dt
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile
import urllib.request
import zipfile

OWNER = "xDarkixx"
REPO = "lua2"
BRANCH = "main"
VERSION = "1.0"
ARCHIVE_URL = f"https://codeload.github.com/{OWNER}/{REPO}/zip/refs/heads/{BRANCH}"


def log(message: str) -> None:
    print(f"[BULDACITY] {message}")


def choose_target(cli_target: str | None) -> Path:
    if cli_target:
        return Path(cli_target).expanduser().resolve()
    default = Path.home() / "BULDACITY"
    answer = input(f"Installationsordner [{default}]: ").strip()
    return Path(answer).expanduser().resolve() if answer else default


def download_archive() -> Path:
    fd, name = tempfile.mkstemp(prefix="buldacity-", suffix=".zip")
    os.close(fd)
    path = Path(name)
    request = urllib.request.Request(
        ARCHIVE_URL,
        headers={"User-Agent": "BULDACITY-MainPC-Installer/1.0"},
    )
    log("Lade aktuelles Repository von GitHub ...")
    with urllib.request.urlopen(request, timeout=60) as response, path.open("wb") as out:
        total = 0
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            out.write(chunk)
            total += len(chunk)
            print(f"\r  {total / 1024 / 1024:.1f} MB", end="", flush=True)
    print()
    if path.stat().st_size == 0:
        raise RuntimeError("GitHub hat ein leeres Archiv geliefert.")
    return path


def safe_extract(zip_path: Path, destination: Path) -> Path:
    with zipfile.ZipFile(zip_path) as archive:
        members = archive.infolist()
        if not members:
            raise RuntimeError("Das GitHub-Archiv ist leer.")
        root = Path(members[0].filename).parts[0]
        for member in members:
            member_path = Path(member.filename)
            if member_path.is_absolute() or ".." in member_path.parts:
                raise RuntimeError(f"Unsicherer Archivpfad: {member.filename}")
        archive.extractall(destination)
    extracted = destination / root
    if not extracted.is_dir():
        raise RuntimeError("Entpacktes Repository wurde nicht gefunden.")
    return extracted


def backup_existing(source: Path, backup_root: Path, relative: Path) -> None:
    if not source.exists():
        return
    target = backup_root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if source.is_dir():
        shutil.copytree(source, target, dirs_exist_ok=True)
    else:
        shutil.copy2(source, target)


def install_tree(source: Path, target: Path, backup_root: Path) -> tuple[int, int]:
    installed = 0
    backed_up = 0
    for path in source.rglob("*"):
        relative = path.relative_to(source)
        destination = target / relative
        if path.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
            continue
        if destination.exists():
            backup_existing(destination, backup_root, relative)
            backed_up += 1
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        installed += 1
    return installed, backed_up


def write_launchers(target: Path) -> None:
    launcher = target / "mainpc"
    launcher.write_text(
        "#!/bin/sh\n"
        "cd \"$(dirname \"$0\")\"\n"
        "exec python3 mainpc/control.py \"$@\"\n",
        encoding="utf-8",
    )
    launcher.chmod(launcher.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    if os.name == "nt":
        (target / "BULDACITY.bat").write_text(
            "@echo off\n"
            "cd /d \"%~dp0\"\n"
            "py mainpc\\control.py %*\n",
            encoding="utf-8",
        )
    else:
        (target / "BULDACITY.bat").write_text(
            "@echo off\n"
            "echo Bitte unter Windows mit BULDACITY.bat starten.\n"
            "echo Unter Linux/macOS: ./mainpc\n",
            encoding="utf-8",
        )


def write_state(target: Path, installed: int, backed_up: int) -> None:
    state = target / "mainpc" / "install-state.txt"
    state.parent.mkdir(parents=True, exist_ok=True)
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    state.write_text(
        f"BULDACITY_MAIN_PC_INSTALLER={VERSION}\n"
        f"REPOSITORY={OWNER}/{REPO}\n"
        f"BRANCH={BRANCH}\n"
        f"INSTALLED_UTC={now}\n"
        f"FILES_INSTALLED={installed}\n"
        f"FILES_BACKED_UP={backed_up}\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="BULDACITY / 2 Main PC installer")
    parser.add_argument("--target", help="Installationsordner")
    parser.add_argument("--update", action="store_true", help="ohne Nachfrage aktualisieren")
    args = parser.parse_args()

    print("=" * 58)
    print(" BULDACITY / 2 - MAIN PC INSTALLER")
    print("=" * 58)
    print(f"Quelle: https://github.com/{OWNER}/{REPO}")
    print("Der komplette Repository-Inhalt wird übernommen.")

    target = choose_target(args.target) if not args.update else Path(args.target or (Path.home() / "BULDACITY")).expanduser().resolve()
    target.mkdir(parents=True, exist_ok=True)
    backup_root = target / "backup" / dt.datetime.now().strftime("%Y%m%d-%H%M%S")

    if target.exists() and any(target.iterdir()) and not args.update:
        answer = input("Ordner existiert bereits. Aktualisieren/überschreiben? [J/n]: ").strip().lower()
        if answer in {"n", "nein", "no"}:
            print("Abgebrochen.")
            return 0

    archive = None
    try:
        archive = download_archive()
        with tempfile.TemporaryDirectory(prefix="buldacity-extract-") as tmp:
            extracted = safe_extract(archive, Path(tmp))
            installed, backed_up = install_tree(extracted, target, backup_root)

        write_launchers(target)
        write_state(target, installed, backed_up)

        if not (target / "README.md").exists():
            raise RuntimeError("README.md fehlt nach der Installation; Repository wurde nicht vollständig übernommen.")

        log(f"Fertig: {installed} Dateien installiert.")
        log(f"Backups: {backed_up} Dateien unter {backup_root}")
        log(f"Installationsordner: {target}")
        log("Windows: BULDACITY.bat | Linux/macOS: ./mainpc")
        log("Der Main-PC-Installer benötigt kein Git.")
        return 0
    except Exception as exc:
        print(f"[BULDACITY] FEHLER: {exc}", file=sys.stderr)
        return 1
    finally:
        if archive:
            try:
                archive.unlink()
            except OSError:
                pass


if __name__ == "__main__":
    raise SystemExit(main())
