import os,threading
from pathlib import Path
import tkinter as tk
from tkinter import ttk,filedialog,messagebox
from .schematic import load_schematic,save_schematic
from .txtformat import export_txt,import_txt
from .build_tool import main as build_main
class App(tk.Tk):
 def __init__(self):
  super().__init__();self.title('SchematicTxtGenerator');self.geometry('1050x700');self.minsize(850,560);self.ui()
 def ui(self):
  top=ttk.Frame(self,padding=18);top.pack(fill='x');ttk.Label(top,text='SchematicTxtGenerator',font=('Segoe UI',20,'bold')).pack(anchor='w');ttk.Label(top,text='Minecraft 1.7.10 • Schematica • klassisches .schematic').pack(anchor='w',pady=(3,12))
  b=ttk.Frame(top);b.pack(fill='x')
  ttk.Button(b,text='Schematic → TXT',command=self.s2t).pack(side='left',padx=(0,7));ttk.Button(b,text='TXT → Schematic',command=self.t2s).pack(side='left',padx=7);ttk.Button(b,text='EXE kompilieren',command=self.build).pack(side='left',padx=7);ttk.Button(b,text='Build-Ordner',command=self.open_dist).pack(side='left',padx=7)
  mid=ttk.Frame(self,padding=(18,0,18,8));mid.pack(fill='both',expand=True);self.tree=ttk.Treeview(mid,columns=('x','y','z','id','meta'),show='headings')
  for c,t,w in [('x','X',90),('y','Y',90),('z','Z',90),('id','Block-ID',130),('meta','Metadata',110)]:self.tree.heading(c,text=t);self.tree.column(c,width=w,anchor='center')
  sb=ttk.Scrollbar(mid,command=self.tree.yview);self.tree.configure(yscrollcommand=sb.set);self.tree.pack(side='left',fill='both',expand=True);sb.pack(side='right',fill='y')
  bot=ttk.Frame(self,padding=18);bot.pack(fill='x');self.status=ttk.Label(bot,text='Bereit.');self.status.pack(anchor='w');self.log=tk.Text(bot,height=8,font=('Consolas',9));self.log.pack(fill='x',pady=(5,0));self.log.insert('end','Bereit.\n')
 def add(self,s):self.log.insert('end',s+'\n');self.log.see('end')
 def preview(self,s):
  for x in self.tree.get_children():self.tree.delete(x)
  n=0
  for y in range(s.height):
   for z in range(s.length):
    for x in range(s.width):
     i=x+z*s.width+y*s.width*s.length;b=s.block_id(i)
     if b:
      if n<50000:self.tree.insert('', 'end',values=(x,y,z,b,s.meta(i)))
      n+=1
  return n
 def s2t(self):
  a=filedialog.askopenfilename(filetypes=[('Schematic','*.schematic')]);
  if not a:return
  b=filedialog.asksaveasfilename(defaultextension='.txt',initialfile=Path(a).stem+'.txt',filetypes=[('TXT','*.txt')]);
  if not b:return
  try:s=load_schematic(a);export_txt(s,b);n=self.preview(s);self.status.config(text=f'Exportiert • {s.width}×{s.height}×{s.length} • {n} Nicht-Luft-Blöcke');self.add('Schematic → TXT: '+b);messagebox.showinfo('Fertig','TXT erfolgreich erstellt.')
  except Exception as e:self.err(e)
 def t2s(self):
  a=filedialog.askopenfilename(filetypes=[('TXT','*.txt')]);
  if not a:return
  b=filedialog.asksaveasfilename(defaultextension='.schematic',initialfile=Path(a).stem+'.schematic',filetypes=[('Schematic','*.schematic')]);
  if not b:return
  try:s=import_txt(a);save_schematic(b,s);n=self.preview(s);self.status.config(text=f'Erstellt • {s.width}×{s.height}×{s.length} • {n} Nicht-Luft-Blöcke');self.add('TXT → Schematic: '+b);messagebox.showinfo('Fertig','Schematic erfolgreich erstellt.')
  except Exception as e:self.err(e)
 def err(self,e):self.add('FEHLER: '+str(e));messagebox.showerror('Fehler',str(e))
 def build(self):
  self.add('Build gestartet...')
  def job():
   try:
    build_main(self.add);self.after(0,lambda:messagebox.showinfo('Build fertig','dist\\SchematicTxtGenerator.exe wurde erstellt.'))
   except Exception as e:self.after(0,lambda:self.err(e))
  threading.Thread(target=job,daemon=True).start()
 def open_dist(self):
  p=Path(__file__).resolve().parent.parent/'dist';p.mkdir(exist_ok=True)
  try:os.startfile(p)
  except: self.add(str(p))
if __name__=='__main__':App().mainloop()
