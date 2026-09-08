import re
from .schematic import Schematic
HEADER='SCHEMATIC_TXT 1'
RX=re.compile(r'^\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*=\s*(\d+)\s*(?::\s*(\d+))?\s*$')
SRX=re.compile(r'^\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*=\s*(.+?)\s*$')
def export_txt(s,path,include_air=False):
 with open(path,'w',encoding='utf-8',newline='\n') as f:
  f.write(HEADER+'\nname='+s.name+'\nsize=%d,%d,%d\nmaterials=%s\n\n'%(s.width,s.height,s.length,s.materials))
  states=getattr(s,'states',{})
  for y in range(s.height):
   for z in range(s.length):
    for x in range(s.width):
     i=x+z*s.width+y*s.width*s.length;b=s.block_id(i);m=s.meta(i)
     if b or include_air:
      f.write(f'{x},{y},{z}={b}:{m}')
      if i in states:f.write(' # state='+states[i])
      f.write('\n')
def import_txt(path):
 name='Schematic';materials='Alpha';size=None;blocks={};states={}
 with open(path,encoding='utf-8-sig') as f:lines=f.readlines()
 if not lines or lines[0].strip()!=HEADER:raise ValueError('Ungültiger TXT-Header.')
 for no,line in enumerate(lines[1:],2):
  s=line.strip()
  if not s or s.startswith('#'):continue
  if s.startswith('name='):name=s[5:].strip() or 'Schematic';continue
  if s.startswith('materials='):materials=s[10:].strip() or 'Alpha';continue
  if s.startswith('size='):
   try:size=tuple(int(v.strip()) for v in s[5:].split(','))
   except:raise ValueError(f'Zeile {no}: size ungültig.')
   if len(size)!=3 or any(v<=0 for v in size):raise ValueError(f'Zeile {no}: size muss positive W,H,L sein.')
   continue
  raw=s;state=None
  if ' # state=' in raw:
   raw,state=raw.split(' # state=',1);state=state.strip()
  m=RX.match(raw)
  if not m:raise ValueError(f'Zeile {no}: unbekannte Syntax.')
  if size is None:raise ValueError('size= fehlt vor Blockdaten.')
  x,y,z,bid,meta=m.groups();x,y,z,bid=int(x),int(y),int(z),int(bid);meta=int(meta or 0);w,h,l=size
  if not(0<=x<w and 0<=y<h and 0<=z<l):raise ValueError(f'Zeile {no}: Koordinate außerhalb.')
  if bid>4095 or bid<0 or meta>15 or meta<0:raise ValueError(f'Zeile {no}: ungültige Block-ID/Metadata.')
  i=x+z*w+y*w*l;blocks[(x,y,z)]=(bid,meta)
  if state:states[i]=state
 if size is None:raise ValueError('size= fehlt.')
 w,h,l=size;total=w*h*l;low=bytearray(total);data=bytearray(total)
 for (x,y,z),(b,m) in blocks.items():i=x+z*w+y*w*l;low[i]=b&255;data[i]=m&15
 s=Schematic(name,w,h,l,materials,bytes(low),bytes(data))
 if any(b>255 for b,m in blocks.values()):
  a=bytearray((total+1)//2)
  for (x,y,z),(b,m) in blocks.items():
   i=x+z*w+y*w*l;hi=(b>>8)&15;a[i//2]|=(hi<<4 if i%2==0 else hi)
  s.addblocks=bytes(a)
 if states:s.states=states
 return s
