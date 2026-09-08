import os,threading
from pathlib import Path
import tkinter as tk
from tkinter import ttk,filedialog,messagebox
from src.format_router import load_any,save_any
from src.build_tool import main as build_main
from src.viewer3d import Viewer3D
from src.block_editor import BlockEditor
class App(tk.Tk):
 def __init__(self):
  super().__init__();self.title('SchematicTxtGenerator – Offline Converter');self.geometry('1150x760');self.minsize(950,620);self.current=None;self.ui()
 def ui(self):
  top=ttk.Frame(self,padding=18);top.pack(fill='x');ttk.Label(top,text='SchematicTxtGenerator',font=('Segoe UI',20,'bold')).pack(anchor='w');ttk.Label(top,text='Offline • Version-unabhängig • Schematic • Sponge Schem • Litematic • OBJ • reine TXT').pack(anchor='w',pady=(3,4));ttk.Label(top,text='Kein Minecraft, keine Mods und keine Befehle für Konvertierung oder Bearbeitung erforderlich.',foreground='gray').pack(anchor='w',pady=(0,12))
  b=ttk.Frame(top);b.pack(fill='x')
  for text,cmd in [('Datei öffnen',self.open_file),('TXT exportieren',self.to_txt),('Block-Editor',self.editor),('3D Vorschau',self.show3d),('Konvertieren',self.convert),('EXE kompilieren',self.build),('Build-Ordner',self.open_dist)]:ttk.Button(b,text=text,command=cmd).pack(side='left',padx=4)
  mid=ttk.Frame(self,padding=(18,0,18,8));mid.pack(fill='both',expand=True);self.tree=ttk.Treeview(mid,columns=('x','y','z','id','meta','state'),show='headings')
  for c,t,w in [('x','X',70),('y','Y',70),('z','Z',70),('id','Block-ID',110),('meta','Metadata',100),('state','Block-State',380)]:self.tree.heading(c,text=t);self.tree.column(c,width=w,anchor='center')
  sb=ttk.Scrollbar(mid,command=self.tree.yview);self.tree.configure(yscrollcommand=sb.set);self.tree.pack(side='left',fill='both',expand=True);sb.pack(side='right',fill='y')
  bot=ttk.Frame(self,padding=18);bot.pack(fill='x');self.status=ttk.Label(bot,text='Bereit – version-unabhängiger Offline-Converter.');self.status.pack(anchor='w');self.log=tk.Text(bot,height=8,font=('Consolas',9));self.log.pack(fill='x',pady=(5,0));self.log.insert('end','Offline-Konverter bereit. Unterstützt: .schematic .schem .litematic .obj .txt\n')
 def add(self,s):
  if threading.current_thread() is not threading.main_thread():
   self.after(0,self.add,s);return
  self.log.insert('end',s+'\n');self.log.see('end')
 def preview(self,s):
  self.current=s
  for x in self.tree.get_children():self.tree.delete(x)
  n=0;states=getattr(s,'states',{})
  for y in range(s.height):
   for z in range(s.length):
    for x in range(s.width):
     i=x+z*s.width+y*s.width*s.length;b=s.block_id(i)
     if b:
      if n<50000:self.tree.insert('', 'end',values=(x,y,z,b,s.meta(i),states.get(i,'')))
      n+=1
  return n
 def open_file(self):
  a=filedialog.askopenfilename(filetypes=[('Unterstützte Formate','*.schematic *.schem *.litematic *.obj *.txt')])
  if not a:return
  try:s=load_any(a);n=self.preview(s);self.status.config(text=f'Geladen • {s.width}×{s.height}×{s.length} • {n} Blöcke');self.add('Geöffnet: '+a)
  except Exception as e:self.err(e)
 def to_txt(self):
  a=filedialog.askopenfilename(filetypes=[('Schematic/3D/TXT','*.schematic *.schem *.litematic *.obj *.txt')])
  if not a:return
  b=filedialog.asksaveasfilename(defaultextension='.txt',initialfile=Path(a).stem+'.txt',filetypes=[('TXT','*.txt')])
  if not b:return
  try:s=load_any(a);save_any(b,s);n=self.preview(s);self.status.config(text=f'TXT fertig • {s.width}×{s.height}×{s.length} • {n} Blöcke');self.add(Path(a).suffix+' → TXT: '+b);messagebox.showinfo('Fertig','TXT erfolgreich erstellt.')
  except Exception as e:self.err(e)
 def editor(self):
  BlockEditor(self,self.current)
 def convert(self):
  a=filedialog.askopenfilename(filetypes=[('Unterstützte Formate','*.schematic *.schem *.litematic *.obj *.txt')])
  if not a:return
  b=filedialog.asksaveasfilename(initialfile=Path(a).stem,filetypes=[('Schematic','*.schematic'),('TXT','*.txt'),('Sponge Schematic','*.schem'),('Litematic','*.litematic'),('OBJ','*.obj')])
  if not b:return
  try:s=load_any(a);save_any(b,s);self.preview(s);self.add(Path(a).suffix+' → '+Path(b).suffix+': '+b);messagebox.showinfo('Fertig','Konvertierung erfolgreich.')
  except Exception as e:self.err(e)
 def show3d(self):
  if self.current is None:self.open_file()
  if self.current is not None:Viewer3D(self,self.current)
 def err(self,e):
  if threading.current_thread() is not threading.main_thread():
   self.after(0,self.err,e);return
  self.add('FEHLER: '+str(e));messagebox.showerror('Fehler',str(e))
 def build(self):
  self.add('Build gestartet...')
  def job():
   try:
    build_main(self.add)
    self.after(0,lambda:messagebox.showinfo('Build fertig','dist\\SchematicTxtGenerator.exe wurde erstellt.'))
   except Exception as e:self.after(0,self.err,e)
  threading.Thread(target=job,daemon=True).start()
 def open_dist(self):
  p=Path(__file__).resolve().parent.parent/'dist';p.mkdir(exist_ok=True)
  try:os.startfile(p)
  except Exception:self.add(str(p))
if __name__=='__main__':App().mainloop()
