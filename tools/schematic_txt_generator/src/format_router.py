from pathlib import Path
import gzip, re, struct
from .schematic import Schematic, load_schematic, save_schematic
from .txtformat import import_txt, export_txt
from .nbt import read

EXTENSIONS={'.schematic','.schem','.litematic','.obj','.txt'}

def _nbt(path): return read(path)[1]
def _v(d,k,default=None): return d[k][1] if k in d else default

def _varints(data):
 out=[];v=0;shift=0
 for b in data:
  v|=(b&127)<<shift
  if not b&128: out.append(v);v=shift=0
  else: shift+=7
 return out

def _palette_name(x):
 if isinstance(x,tuple): x=x[1]
 if isinstance(x,dict):
  n=_v(x,'Name','minecraft:air'); p=_v(x,'Properties',{})
  if p:
   n+='['+','.join('%s=%s'%(k,_v(p[k], 'value', '')) for k in sorted(p))+']'
  return n
 return str(x)

def load_schem(path):
 r=_nbt(path);w,h,l=int(_v(r,'Width',0)),int(_v(r,'Height',0)),int(_v(r,'Length',0))
 if min(w,h,l)<=0: raise ValueError('Sponge .schem: ungültige Größe.')
 pal=_v(r,'Palette',{}); names={int(v[1]):k for k,v in pal.items()}
 vals=_varints(bytes(_v(r,'BlockData',b'')))
 total=w*h*l
 if len(vals)<total: raise ValueError('Sponge .schem: BlockData ist zu kurz.')
 low=bytearray(total);meta=bytearray(total);states={}
 for i in range(total):
  name=_palette_name(names.get(vals[i],'minecraft:air'));states[i]=name
  m=re.match(r'minecraft:(?:stone|cobblestone|dirt|glass|sand|gravel|planks|brick|obsidian|iron_block|gold_block|diamond_block)$',name)
  bid={'minecraft:stone':1,'minecraft:grass_block':2,'minecraft:dirt':3,'minecraft:cobblestone':4,'minecraft:planks':5,'minecraft:sand':12,'minecraft:gravel':13,'minecraft:glass':20,'minecraft:brick':45,'minecraft:obsidian':49,'minecraft:iron_block':42,'minecraft:gold_block':41,'minecraft:diamond_block':57}.get(name.split('[')[0],1 if not name.endswith('air') else 0)
  low[i]=bid;meta[i]=0
 s=Schematic(str(_v(r,'Metadata',{})),w,h,l,'Alpha',bytes(low),bytes(meta));s.states=states;return s

def _longs(b): return [struct.unpack('>q',b[i:i+8])[0]&((1<<64)-1) for i in range(0,len(b)-7,8)]
def _bits(vals,bits,n):
 mask=(1<<bits)-1;out=[]
 for i in range(n):
  bit=i*bits; q=bit>>6;o=bit&63;v=(vals[q]>>o)&mask
  if o+bits>64:v|=(vals[q+1]&((1<<(o+bits-64))-1))<<(64-o)
  out.append(v)
 return out

def load_litematic(path):
 r=_nbt(path);regions=_v(r,'Regions',{});allblocks={};name='Litematic'
 for rn,rv in regions.items():
  d=rv[1];sz=_v(d,'Size',{});pos=_v(d,'Position',{});sx,sy,szv=int(_v(sz,'x',0)),int(_v(sz,'y',0)),int(_v(sz,'z',0));px,py,pz=int(_v(pos,'x',0)),int(_v(pos,'y',0)),int(_v(pos,'z',0))
  ax,ay,az=abs(sx),abs(sy),abs(szv);pal=_v(d,'BlockStatePalette',{'type':10,'items':[]})['items'];pl=[_palette_name(x) for x in pal];bits=max(2,(len(pl)-1).bit_length());idx=_bits(_longs(bytes(_v(d,'BlockStates',b''))),bits,ax*ay*az)
  for i,k in enumerate(idx):
   if k>=len(pl): continue
   x=i%ax;y=(i//ax)%ay;z=i//(ax*ay);allblocks[(px+(x if sx>=0 else -x),py+(y if sy>=0 else -y),pz+(z if szv>=0 else -z))]=pl[k]
 if not allblocks: return Schematic(name,1,1,1,'Alpha',b'\0',b'\0')
 minx=min(x for x,y,z in allblocks);miny=min(y for x,y,z in allblocks);minz=min(z for x,y,z in allblocks);maxx=max(x for x,y,z in allblocks);maxy=max(y for x,y,z in allblocks);maxz=max(z for x,y,z in allblocks);w=maxx-minx+1;h=maxy-miny+1;l=maxz-minz+1;low=bytearray(w*h*l);meta=bytearray(w*h*l);states={}
 for (x,y,z),state in allblocks.items():
  i=(x-minx)+(z-minz)*w+(y-miny)*w*l;states[i]=state;low[i]=0 if state.endswith('air') else 1
 s=Schematic(name,w,h,l,'Alpha',bytes(low),bytes(meta));s.states=states;return s

def load_obj(path):
 verts=[];blocks=[];mtl=None
 with open(path,encoding='utf-8',errors='replace') as f:
  for line in f:
   q=line.strip().split()
   if not q: continue
   if q[0]=='v' and len(q)>=4: verts.append(tuple(float(x) for x in q[1:4]))
   elif q[0] in ('o','g') and len(q)>1: blocks.append(q[1])
   elif q[0]=='mtllib' and len(q)>1: mtl=q[1]
 if not verts: raise ValueError('OBJ enthält keine Vertices.')
 minx=min(v[0] for v in verts);miny=min(v[1] for v in verts);minz=min(v[2] for v in verts);maxx=max(v[0] for v in verts);maxy=max(v[1] for v in verts);maxz=max(v[2] for v in verts);w=max(1,int(round(maxx-minx)));h=max(1,int(round(maxy-miny)));l=max(1,int(round(maxz-minz)));low=bytearray(w*h*l);data=bytearray(w*h*l)
 for n in blocks:
  m=re.search(r'(?:block_)?(\d+)(?:[_:](\d+))?',n)
  if not m: continue
  bid=int(m.group(1));md=int(m.group(2) or 0);m=re.search(r'x(-?\d+).*?y(-?\d+).*?z(-?\d+)',n)
  if m:
   x,y,z=map(int,m.groups());
   if 0<=x<w and 0<=y<h and 0<=z<l:i=x+z*w+y*w*l;low[i]=bid&255;data[i]=md&15
 s=Schematic(Path(path).stem,w,h,l,'Alpha',bytes(low),bytes(data));return s

def load_any(path):
 p=Path(path);e=p.suffix.lower()
 if e=='.schematic': return load_schematic(str(p))
 if e=='.txt': return import_txt(str(p))
 if e=='.schem': return load_schem(str(p))
 if e=='.litematic': return load_litematic(str(p))
 if e=='.obj': return load_obj(str(p))
 raise ValueError('Nicht unterstütztes Format: '+e)

def save_any(path,s):
 p=Path(path);e=p.suffix.lower()
 if e=='.txt': return export_txt(s,str(p))
 if e=='.schematic': return save_schematic(str(p),s)
 raise ValueError('Ausgabeformat derzeit nicht implementiert: '+e)

def convert(src,dst): return save_any(dst,load_any(src))
