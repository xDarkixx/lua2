from .nbt import *
class Schematic:
 def __init__(self,name,w,h,l,materials,blocks,data,add=None):self.name=name;self.width=w;self.height=h;self.length=l;self.materials=materials or 'Universal';self.blocks=blocks;self.data=data;self.addblocks=add
 def block_id(self,i):
  low=self.blocks[i]&255
  if self.addblocks and i//2<len(self.addblocks):
   b=self.addblocks[i//2]&255;return low|((b>>4 if i%2==0 else b&15)<<8)
  return low
 def meta(self,i):return self.data[i]&15
def load_schematic(path):
 rootname,root=read(path);v=lambda k,d=None:root[k][1] if k in root else d
 w,h,l=int(v('Width',0)),int(v('Height',0)),int(v('Length',0));total=w*h*l
 if min(w,h,l)<=0:raise NBTError('Ungültige Abmessungen.')
 blocks=bytes(v('Blocks',b''));data=bytes(v('Data',b''));add=v('AddBlocks',None);add=bytes(add) if add is not None else None
 if len(blocks)!=total or len(data)!=total:raise NBTError('Blocks/Data passen nicht zur Größe.')
 if add is not None and len(add)!=(total+1)//2:raise NBTError('AddBlocks passt nicht zur Größe.')
 return Schematic(str(v('Name',rootname or 'Schematic')),w,h,l,str(v('Materials','Universal')),blocks,data,add)
def save_schematic(path,s):
 total=s.width*s.height*s.length
 ids=[s.block_id(i) for i in range(total)]
 if any(b>4095 for b in ids):raise NBTError('Legacy-Block-ID > 4095 wird von .schematic nicht unterstützt.')
 root={'Width':(2,s.width),'Height':(2,s.height),'Length':(2,s.length),'Materials':(8,s.materials),'Blocks':(7,s.blocks),'Data':(7,s.data),'Entities':(9,{'type':10,'items':[]}),'TileEntities':(9,{'type':10,'items':[]}),'Name':(8,s.name)}
 if any(b>255 for b in ids):
  a=bytearray((total+1)//2)
  for i,b in enumerate(ids):
   hi=(b>>8)&15;a[i//2]=a[i//2]|(hi<<4 if i%2==0 else hi)
  root['AddBlocks']=(7,bytes(a))
 write(path,'Schematic',root)
