import tkinter as tk
import math

# Only the rasterized preview is capped. The loaded structure itself is never
# truncated, so large files remain fully available to the converter/editor.
MAX_RENDER_BLOCKS = 20000

class Viewer3D(tk.Toplevel):
 def __init__(self,master,s):
  super().__init__(master);self.s=s;self.title('3D Vorschau – version-unabhängig');self.geometry('980x700');self.minsize(760,520)
  self.c=tk.Canvas(self,bg='#17191d',highlightthickness=0);self.c.pack(fill='both',expand=True)
  self.info=tk.Label(self,text='',anchor='w');self.info.pack(fill='x',padx=8,pady=4)
  self.a=.7;self.p=.5;self.z=10;self.d=None;self._after=None;self._blocks_cache=None;self._blocks_cache_key=None
  self.c.bind('<MouseWheel>',self.wheel);self.c.bind('<Button-4>',lambda e:self.zoom(1));self.c.bind('<Button-5>',lambda e:self.zoom(-1));self.c.bind('<B1-Motion>',self.move);self.c.bind('<Button-1>',self.down);self.bind('<Configure>',self._resize)
  self.draw()
 def down(self,e):self.d=(e.x,e.y,self.a,self.p)
 def move(self,e):
  if self.d:
   x,y,a,p=self.d;self.a=a+(e.x-x)/80;self.p=max(-1.45,min(1.45,p+(e.y-y)/100));self.schedule_draw()
 def wheel(self,e):self.zoom(1 if e.delta>0 else -1)
 def zoom(self,direction):self.z=max(2,min(100,self.z*(1.1 if direction>0 else .9)));self.schedule_draw()
 def _resize(self,event=None):self.schedule_draw()
 def schedule_draw(self):
  if self._after is None:self._after=self.after(30,self._scheduled_draw)
 def _scheduled_draw(self):self._after=None;self.draw()
 def q(self,x,y,z):
  x-=self.s.width/2;z-=self.s.length/2;y-=self.s.height/2;ca,sa=math.cos(self.a),math.sin(self.a);xx=x*ca-z*sa;zz=x*sa+z*ca;cp,sp=math.cos(self.p),math.sin(self.p);yy=y*cp-zz*sp;return self.c.winfo_width()/2+xx*self.z,self.c.winfo_height()/2-yy*self.z,y*sp+zz*cp
 def _preview_blocks(self):
  key=(id(self.s),id(self.s.blocks),id(getattr(self.s,'addblocks',None)),self.s.width,self.s.height,self.s.length)
  if self._blocks_cache_key==key and self._blocks_cache is not None:return self._blocks_cache
  w,h,l=self.s.width,self.s.height,self.s.length;blocks=[]
  for y in range(h):
   for z in range(l):
    base=z*w+y*w*l
    for x in range(w):
     i=x+base
     if self.s.block_id(i):blocks.append((x,y,z))
  total=len(blocks)
  if total<=MAX_RENDER_BLOCKS:result=(blocks,total,False)
  else:
   step=max(1,math.ceil(total/MAX_RENDER_BLOCKS));result=(blocks[::step][:MAX_RENDER_BLOCKS],total,True)
  self._blocks_cache_key=key;self._blocks_cache=result;return result
 def draw(self):
  self.c.delete('all')
  if min(self.s.width,self.s.height,self.s.length)<=0:return
  blocks,total,sampled=self._preview_blocks();a=[]
  for x,y,z in blocks:
   p=[self.q(x+dx,y+dy,z+dz) for dx,dy,dz in ((0,0,0),(1,0,0),(1,1,0),(0,1,0),(0,0,1),(1,0,1),(1,1,1),(0,1,1))];a.append((sum(v[2] for v in p),p))
  a.sort(reverse=True)
  for _,p in a:
   for f in ((p[3],p[2],p[6],p[7]),(p[1],p[5],p[6],p[2]),(p[0],p[4],p[5],p[1])):self.c.create_polygon([(v[0],v[1]) for v in f],fill='#888888',outline='#202328')
  if sampled:msg=f'3D-Vorschau: {total:,} Blöcke • Anzeige: {len(blocks):,} • reduziert, Daten vollständig erhalten'
  else:msg=f'3D-Vorschau: {total:,} Blöcke • {self.s.width}×{self.s.height}×{self.s.length}'
  self.info.config(text=msg.replace(',','.'))
