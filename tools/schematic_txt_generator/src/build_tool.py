import sys
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VENV = ROOT / '.venv'
TESTS = ROOT / 'tests'


def run(py, args, log):
    log('$ ' + ' '.join([str(py)] + [str(x) for x in args]))
    subprocess.check_call([str(py)] + [str(x) for x in args], cwd=ROOT)


def main(log=print):
    py = VENV / 'Scripts' / 'python.exe'
    if not py.exists():
        log('Erstelle virtuelle Python-Umgebung...')
        subprocess.check_call([sys.executable, '-m', 'venv', str(VENV)], cwd=ROOT)

    log('Installiere Build-Abhängigkeiten...')
    run(py, ['-m', 'pip', 'install', '--upgrade', 'pip'], log)
    run(py, ['-m', 'pip', 'install', '-r', ROOT / 'requirements.txt'], log)

    log('Führe Tests aus (EXE wird bei Fehler nicht gebaut)...')
    run(py, ['-m', 'unittest', 'discover', '-s', TESTS, '-v'], log)

    log('Kompiliere Windows-EXE...')
    run(py, ['-m', 'PyInstaller', '--clean', '--noconfirm', ROOT / 'SchematicTxtGenerator.spec'], log)

    exe = ROOT / 'dist' / 'SchematicTxtGenerator.exe'
    if not exe.exists():
        raise RuntimeError('EXE wurde nicht erzeugt: ' + str(exe))
    log('FERTIG: ' + str(exe))
    return exe


if __name__ == '__main__':
    main()
