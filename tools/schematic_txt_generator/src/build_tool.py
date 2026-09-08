import sys,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent;VENV=ROOT/'.venv'
def main(log=print):
 py=VENV/'Scripts'/'python.exe'
 if not py.exists():log('Erstelle virtuelle Python-Umgebung...');subprocess.check_call([sys.executable,'-m','venv',str(VENV)])
 log('Installiere PyInstaller...');subprocess.check_call([str(py),'-m','pip','install','--upgrade','pip']);subprocess.check_call([str(py),'-m','pip','install','-r',str(ROOT/'requirements.txt')])
 log('Kompiliere Windows-EXE...');subprocess.check_call([str(py),'-m','PyInstaller','--clean','--noconfirm',str(ROOT/'SchematicTxtGenerator.spec')],cwd=ROOT)
 exe=ROOT/'dist'/'SchematicTxtGenerator.exe'
 if not exe.exists():raise RuntimeError('EXE wurde nicht erzeugt.')
 log('FERTIG: '+str(exe));return exe
if __name__=='__main__':main()
