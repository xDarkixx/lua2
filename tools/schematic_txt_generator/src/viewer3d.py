import tkinter as tk
class Viewer3D(tk.Toplevel):
 def __init__(self,master,s):
  super().__init__(master);self.s=s;self.title('3D Vorschau');self.geometry('900x650');self.c=tk.Canvas(self,bg='#17191d');self.c.pack(fill='both',expand=True);self.a=.7;self.p=.5;self.z=10;self.c.bind('<MouseWheel>',self.wheel);self.c.bind('<B1-Motion>',self.move);self.c.bind('<Button-1>',self.down);self.draw()
 def down(self,e):self.d=(e.x,e.y,self.a,self.p)
 def move(self,e):
  if hasattr(self,'d'):x,y,a,p=self.d;self.a=a+(e.x-x)/80;self.p=p+(e.y-y)/100;self.draw()
 def wheel(self,e):self.z=max(2,min(60,self.z*(1.1 if e.delta>0 else .9)));self.draw()
 def q(self,x,y,z):
  import math
  x-=self.s.width/2;z-=self.s.length/2;y-=self.s.height/2;ca,sa=math.cos(self.a),math.sin(self.a);xx=x*ca-z*sa;zz=x*sa+z*ca;cp,sp=math.cos(self.p),math.sin(self.p);yy=y*cp-zz*sp;return self.c.winfo_width()/2+xx*self.z,self.c.winfo_height()/2-yy*self.z,y*sp+zz*cp
 def draw(self):
  self.c.delete('all');a=[];w,l=self.s.width,self.s.length
  for y in range(self.s.height):
   for z in range(l):
    for x in range(w):
     i=x+z*w+y*w*l;b=self.s.block_id(i)
     if b:
      p=[self.q(x+dx,y+dy,z+dz) for dx,dy,dz in ((0,0,0),(1,0,0),(1,1,0),(0,1,0),(0,0,1),(1,0,1),(1,1,1),(0,1,1))];a.append((sum(v[2] for v in p),p))
  a.sort(reverse=True)
  for _,p in a[-20000:]:
   for f in ((p[3],p[2],p[6],p[7]),(p[1],p[5],p[6],p[2]),(p[0],p[4],p[5],p[1])):self.c.create_polygon([(v[0],v[1]) for v in f],fill='#888888',outline='#202328')
