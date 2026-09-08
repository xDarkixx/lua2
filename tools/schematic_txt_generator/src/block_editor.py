import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from pathlib import Path
from .schematic import Schematic
from .txtformat import export_txt

# Small built-in 1.7.10 palette. The editor also accepts any numeric legacy ID.
PALETTE = [
    ('Air',0,0),('Stone',1,0),('Grass',2,0),('Dirt',3,0),('Cobblestone',4,0),
    ('Planks',5,0),('Sand',12,0),('Gravel',13,0),('Glass',20,0),
    ('Gold Block',41,0),('Iron Block',42,0),('Bricks',45,0),('Obsidian',49,0),
    ('Diamond Block',57,0),('Stone Slab',44,0),('Glowstone',89,0),('Snow',78,0),
]

class BlockEditor(tk.Toplevel):
    def __init__(self, master, schematic=None):
        super().__init__(master)
        self.title('Block-Editor – SCHEMATIC_TXT')
        self.geometry('1050x760'); self.minsize(850,600)
        self.s = schematic or self.new_schematic()
        self.selected = (1,0); self.layer = 0; self.cell = 28
        self.palette = PALETTE[:]
        self._ui(); self._load_palette(); self._draw()

    def new_schematic(self):
        w,h,l=16,8,16; total=w*h*l
        b=bytearray(total); d=bytearray(total)
        return Schematic('Neues Bauwerk',w,h,l,'Alpha',bytes(b),bytes(d))

    def _ui(self):
        bar=ttk.Frame(self,padding=8); bar.pack(fill='x')
        ttk.Button(bar,text='TXT öffnen',command=self.open_txt).pack(side='left',padx=3)
        ttk.Button(bar,text='TXT speichern',command=self.save_txt).pack(side='left',padx=3)
        ttk.Button(bar,text='Neu',command=self.new_doc).pack(side='left',padx=3)
        ttk.Label(bar,text='Ebene Y:').pack(side='left',padx=(18,3))
        self.ly=tk.IntVar(value=0)
        self.layer_spin=ttk.Spinbox(bar,from_=0,to=max(0,self.s.height-1),textvariable=self.ly,width=6,command=self.layer_changed)
        self.layer_spin.pack(side='left')
        ttk.Button(bar,text='▲',command=lambda:self.set_layer(self.layer+1)).pack(side='left',padx=2)
        ttk.Button(bar,text='▼',command=lambda:self.set_layer(self.layer-1)).pack(side='left',padx=2)
        ttk.Button(bar,text='Start',command=lambda:self.set_layer(0)).pack(side='left',padx=2)
        ttk.Button(bar,text='Ende',command=lambda:self.set_layer(self.s.height-1)).pack(side='left',padx=2)
        ttk.Button(bar,text='3D',command=self.preview3d).pack(side='left',padx=(15,2))
        self.info=ttk.Label(bar,text=''); self.info.pack(side='right')

        main=ttk.Panedwindow(self,orient='horizontal');main.pack(fill='both',expand=True,padx=8,pady=8)
        left=ttk.Frame(main,width=230); main.add(left,weight=0)
        ttk.Label(left,text='Blöcke').pack(anchor='w',padx=6,pady=4)
        self.lb=tk.Listbox(left,exportselection=False,height=25);self.lb.pack(fill='both',expand=True,padx=6)
        self.lb.bind('<<ListboxSelect>>',self.palette_selected)
        form=ttk.Frame(left,padding=6);form.pack(fill='x')
        ttk.Label(form,text='ID').grid(row=0,column=0); self.idv=tk.IntVar(value=1);ttk.Spinbox(form,from_=0,to=4095,textvariable=self.idv,width=8).grid(row=0,column=1)
        ttk.Label(form,text='Meta').grid(row=1,column=0);self.mv=tk.IntVar(value=0);ttk.Spinbox(form,from_=0,to=15,textvariable=self.mv,width=8).grid(row=1,column=1)
        ttk.Button(form,text='Übernehmen',command=self.custom_selected).grid(row=2,column=0,columnspan=2,pady=5)
        ttk.Label(left,text='Linksklick = setzen\nRechtsklick = löschen',foreground='gray').pack(anchor='w',padx=8,pady=5)
        right=ttk.Frame(main);main.add(right,weight=1)
        self.canvas=tk.Canvas(right,background='#20242a',highlightthickness=0);self.canvas.pack(fill='both',expand=True)
        self.canvas.bind('<Button-1>',self.paint);self.canvas.bind('<Button-3>',self.erase)
        self.canvas.bind('<B1-Motion>',self.paint);self.canvas.bind('<B3-Motion>',self.erase)
        # Mausrad = Ebene wechseln. Strg+Mausrad = in 10er-Schritten springen.
        self.canvas.bind('<MouseWheel>',self.layer_wheel)
        self.canvas.bind('<Button-4>',lambda e:self.layer_wheel_delta(1))
        self.canvas.bind('<Button-5>',lambda e:self.layer_wheel_delta(-1))
        self.bind('<MouseWheel>',self.layer_wheel)
        self.bind('<Control-MouseWheel>',self.layer_wheel)

    def _load_palette(self):
        self.lb.delete(0,'end')
        for name,b,m in self.palette:self.lb.insert('end',f'{name}  [{b}:{m}]')
        self.lb.selection_set(1);self.lb.activate(1)

    def palette_selected(self,event=None):
        i=self.lb.curselection()
        if i:
            _,b,m=self.palette[i[0]];self.selected=(b,m);self.idv.set(b);self.mv.set(m)

    def custom_selected(self):
        b=max(0,min(4095,int(self.idv.get())));m=max(0,min(15,int(self.mv.get())));self.selected=(b,m)
        self._draw()

    def set_layer(self,y):
        y=max(0,min(self.s.height-1,int(y)));self.layer=y;self.ly.set(y);self._draw()

    def layer_changed(self):
        try:self.set_layer(self.ly.get())
        except (ValueError,tk.TclError):pass

    def layer_wheel_delta(self,delta):
        step=10 if (self._ctrl_down()) else 1
        self.set_layer(self.layer + (step if delta > 0 else -step))

    def _ctrl_down(self):
        try:return bool(self.tk.call('expr','{[%s state] & 0x4}' % self.winfo_name()))
        except Exception:return False

    def layer_wheel(self,event):
        delta=1 if getattr(event,'delta',0)>0 else -1
        step=10 if (event.state & 0x4) else 1
        self.set_layer(self.layer + delta*step)
        return 'break'

    def _index(self,x,y,z):return x+z*self.s.width+y*self.s.width*self.s.length
    def _draw(self):
        self.canvas.delete('all');w,l=self.s.width,self.s.length;cs=self.cell
        for z in range(l):
            for x in range(w):
                i=self._index(x,self.layer,z);b=self.s.block_id(i);m=self.s.meta(i)
                x0,z0=x*cs,z*cs;x1,z1=x0+cs,z0+cs
                self.canvas.create_rectangle(x0,z0,x1,z1,outline='#505761',fill=self._shade(b))
                if b:self.canvas.create_text(x0+cs/2,z0+cs/2,text=str(b),fill='white',font=('Consolas',8))
        self.info.config(text=f'{self.s.name} • {w}×{self.s.height}×{l} • Ebene Y={self.layer}/{max(0,self.s.height-1)} • ID {self.selected[0]}:{self.selected[1]}')
        self.canvas.config(scrollregion=(0,0,w*cs,l*cs))

    def _shade(self,b):
        if not b:return '#252a30'
        # Deterministic neutral shade; no external block assets required.
        v=(b*37)%100; q=80+v
        return '#%02x%02x%02x'%(q,min(190,q+15),min(210,q+30))

    def _xy(self,event):
        x=int(self.canvas.canvasx(event.x)//self.cell);z=int(self.canvas.canvasy(event.y)//self.cell)
        return x,z
    def paint(self,event):
        x,z=self._xy(event)
        if 0<=x<self.s.width and 0<=z<self.s.length:self._set(x,self.layer,z,*self.selected)
    def erase(self,event):
        x,z=self._xy(event)
        if 0<=x<self.s.width and 0<=z<self.s.length:self._set(x,self.layer,z,0,0)
    def _set(self,x,y,z,b,m):
        i=self._index(x,y,z);lo=bytearray(self.s.blocks);da=bytearray(self.s.data);lo[i]=b&255;da[i]=m&15
        add=self.s.addblocks
        aa=bytearray(add or bytes((self.s.width*self.s.height*self.s.length+1)//2))
        if b>255:
            hi=(b>>8)&15
            aa[i//2]=(aa[i//2]& (0x0F if i%2==0 else 0xF0)) | (hi<<4 if i%2==0 else hi)
            add=bytes(aa)
        elif add:
            # Clear an old AddBlocks nibble when replacing a >255 block with a legacy ID.
            aa[i//2] &= 0x0F if i%2==0 else 0xF0
            add=bytes(aa)
        self.s=Schematic(self.s.name,self.s.width,self.s.height,self.s.length,self.s.materials,bytes(lo),bytes(da),add);self._draw()

    def new_doc(self):
        if messagebox.askyesno('Neu','Aktuelles Bauwerk verwerfen?'):
            self.s=self.new_schematic();self.layer=0;self.ly.set(0);self._update_layer_range();self._draw()

    def _update_layer_range(self):
        try:self.layer_spin.configure(from_=0,to=max(0,self.s.height-1))
        except Exception:pass

    def open_txt(self):
        p=filedialog.askopenfilename(filetypes=[('TXT','*.txt')])
        if not p:return
        try:self.s=__import__('src.txtformat',fromlist=['import_txt']).import_txt(p);self.layer=0;self.ly.set(0);self._update_layer_range();self._draw()
        except Exception as e:messagebox.showerror('Fehler',str(e))

    def save_txt(self):
        p=filedialog.asksaveasfilename(defaultextension='.txt',initialfile=Path(self.s.name).stem+'.txt',filetypes=[('TXT','*.txt')])
        if p:
            try:export_txt(self.s,p);messagebox.showinfo('Gespeichert','TXT wurde gespeichert.')
            except Exception as e:messagebox.showerror('Fehler',str(e))

    def preview3d(self):
        from .viewer3d import Viewer3D;Viewer3D(self,self.s)
