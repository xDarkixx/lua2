from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
TESTS = ROOT / "tests"
SPEC = ROOT / "SchematicTxtGenerator.spec"
DIST = ROOT / "dist"
EXE = DIST / "SchematicTxtGenerator.exe"


def run(cmd, label):
    print(f"\n=== {label} ===")
    print("$", " ".join(map(str, cmd)))
    subprocess.check_call(cmd, cwd=ROOT)


def main():
    # The build is deliberately test-gated: no EXE is produced when a test fails.
    run([sys.executable, "-m", "unittest", "discover", "-s", str(TESTS), "-v"], "Tests")

    run([sys.executable, "-m", "pip", "install", "--upgrade", "pip"], "Python build tools")
    run([sys.executable, "-m", "pip", "install", "-r", str(ROOT / "requirements.txt")], "Dependencies")

    DIST.mkdir(exist_ok=True)
    run([sys.executable, "-m", "PyInstaller", "--clean", "--noconfirm", str(SPEC)], "Windows EXE")

    if not EXE.exists():
        raise RuntimeError(f"EXE wurde nicht erzeugt: {EXE}")
    print(f"\nFERTIG: {EXE}")
    print("Die fertige Anwendung ist eine einzelne Windows-Datei.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
