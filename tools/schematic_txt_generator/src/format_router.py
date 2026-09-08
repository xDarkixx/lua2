from pathlib import Path
import math
import re
import struct
from .schematic import Schematic, load_schematic, save_schematic
from .txtformat import import_txt, export_txt
from .nbt import read, write

EXTENSIONS = {'.schematic', '.schem', '.litematic', '.obj', '.txt'}
LEGACY_TO_STATE = {0:'minecraft:air',1:'minecraft:stone',2:'minecraft:grass_block',3:'minecraft:dirt',4:'minecraft:cobblestone',5:'minecraft:planks',12:'minecraft:sand',13:'minecraft:gravel',20:'minecraft:glass',41:'minecraft:gold_block',42:'minecraft:iron_block',45:'minecraft:bricks',49:'minecraft:obsidian',57:'minecraft:diamond_block'}
STATE_TO_LEGACY = {v:k for k,v in LEGACY_TO_STATE.items()}; STATE_TO_LEGACY['minecraft:brick']=45

def _nbt(path): return read(path)[1]
def _v(d,k,default=None): return d[k][1] if k in d else default
def _list(v): return v.get('items',[]) if isinstance(v,dict) else []
def _state_name(x):
    if isinstance(x,tuple): x=x[1]
    if not isinstance(x,dict): return str(x)
    name=_v(x,'Name','minecraft:air'); props=_v(x,'Properties',{})
    if props:
        name+='['+','.join('%s=%s'%(k,p[1] if isinstance(p,tuple) else p) for k,p in sorted(props.items()))+']'
    return name
def _base_state(name): return str(name).split('[',1)[0]
def _legacy_id(name):
    base=_base_state(name)
    return STATE_TO_LEGACY.get(base,0 if base.endswith(':air') else 1)
def _varints(data):
    out=[];value=shift=0
    for b in bytes(data):
        value|=(b&127)<<shift
        if not b&128: out.append(value);value=shift=0
        else:
            shift+=7
            if shift>35: raise ValueError('Sponge .schem: ungültige VarInt-Daten.')
    if shift: raise ValueError('Sponge .schem: abgeschnittene VarInt-Daten.')
    return out
def _put_varints(values):
    out=bytearray()
    for value in values:
        value=int(value)
        if value<0: raise ValueError('Palette-Index darf nicht negativ sein.')
        while value>127: out.append((value&127)|128);value>>=7
        out.append(value)
    return bytes(out)

def load_schem(path):
    r=_nbt(path);w,h,l=int(_v(r,'Width',0)),int(_v(r,'Height',0)),int(_v(r,'Length',0))
    if min(w,h,l)<=0: raise ValueError('Sponge .schem: ungültige Größe.')
    pal=_v(r,'Palette',{}) or {};names={int(v[1]):k for k,v in pal.items()};vals=_varints(_v(r,'BlockData',b''));total=w*h*l
    if len(vals)!=total: raise ValueError('Sponge .schem: BlockData passt nicht zur Größe.')
    low=bytearray(total);meta=bytearray(total);states={}
    for i,idx in enumerate(vals):
        state=_state_name(names.get(idx,'minecraft:air'));states[i]=state;low[i]=_legacy_id(state)&255
    s=Schematic(str(_v(r,'Name',Path(path).stem)),w,h,l,'Universal',bytes(low),bytes(meta));s.states=states;return s

def _schem_root(s):
    total=s.width*s.height*s.length;palette={};ids=[]
    for i in range(total):
        state=getattr(s,'states',{}).get(i,LEGACY_TO_STATE.get(s.block_id(i),'minecraft:stone' if s.block_id(i) else 'minecraft:air'))
        if state not in palette: palette[state]=len(palette)
        ids.append(palette[state])
    root={'Version':(3,2),'DataVersion':(3,1976),'Width':(2,s.width),'Height':(2,s.height),'Length':(2,s.length),'Palette':(10,{k:(3,v) for k,v in palette.items()}),'BlockData':(7,_put_varints(ids)),'Metadata':(10,{'Name':(8,s.name),'WEOffsetX':(3,0),'WEOffsetY':(3,0),'WEOffsetZ':(3,0)}),'BlockEntities':(9,{'type':10,'items':[]})}
    return root
def save_schem(path,s): write(path,'Schematic',_schem_root(s))

def _longs(data):
    if isinstance(data,(list,tuple)):
        return [int(x)&((1<<64)-1) for x in data]
    if len(data)%8: raise ValueError('Litematic: BlockStates-Länge ist ungültig.')
    return [struct.unpack('>Q',bytes(data[i:i+8]))[0] for i in range(0,len(data),8)]
def _bits(values,bits,count):
    mask=(1<<bits)-1;out=[]
    for i in range(count):
        bit=i*bits;q,off=bit>>6,bit&63
        if q>=len(values): raise ValueError('Litematic: BlockStates ist zu kurz.')
        v=values[q]>>off
        if off+bits>64:
            if q+1>=len(values): raise ValueError('Litematic: BlockStates ist abgeschnitten.')
            v|=values[q+1]<<(64-off)
        out.append(v&mask)
    return out
def _pack_bits(indices,bits):
    n=(len(indices)*bits+63)//64;vals=[0]*n;mask=(1<<bits)-1
    for i,idx in enumerate(indices):
        bit=i*bits;q,off=bit>>6,bit&63;v=idx&mask;vals[q]|=v<<off
        if off+bits>64: vals[q+1]|=v>>(64-off)
    return [v if v<(1<<63) else v-(1<<64) for v in vals]

def load_litematic(path):
    r=_nbt(path);regions=_v(r,'Regions',{}) or {};allblocks={};name=str(_v(r,'Name','Litematic'))
    for _,rv in regions.items():
        d=rv[1];size=_v(d,'Size',{});pos=_v(d,'Position',{});sx,sy,sz=[int(_v(size,k,0)) for k in 'xyz'];px,py,pz=[int(_v(pos,k,0)) for k in 'xyz'];ax,ay,az=abs(sx),abs(sy),abs(sz)
        if min(ax,ay,az)<=0: continue
        palette=[_state_name(x) for x in _list(_v(d,'BlockStatePalette',{}))]
        if not palette: continue
        bits=max(2,(len(palette)-1).bit_length());indices=_bits(_longs(_v(d,'BlockStates',[])),bits,ax*ay*az)
        for i,idx in enumerate(indices):
            if idx>=len(palette): continue
            x,y,z=i%ax,(i//ax)%ay,i//(ax*ay)
            if sx<0:x=ax-1-x
            if sy<0:y=ay-1-y
            if sz<0:z=az-1-z
            allblocks[(px+x,py+y,pz+z)]=palette[idx]
    if not allblocks:return Schematic(name,1,1,1,'Universal',b'\0',b'\0')
    minx=min(x for x,y,z in allblocks);miny=min(y for x,y,z in allblocks);minz=min(z for x,y,z in allblocks);maxx=max(x for x,y,z in allblocks);maxy=max(y for x,y,z in allblocks);maxz=max(z for x,y,z in allblocks);w,h,l=maxx-minx+1,maxy-miny+1,maxz-minz+1;low=bytearray(w*h*l);meta=bytearray(w*h*l);states={}
    for (x,y,z),state in allblocks.items():i=(x-minx)+(z-minz)*w+(y-miny)*w*l;states[i]=state;low[i]=_legacy_id(state)&255
    s=Schematic(name,w,h,l,'Universal',bytes(low),bytes(meta));s.states=states;return s

def save_litematic(path,s):
    total=s.width*s.height*s.length;states=getattr(s,'states',{});palette=[];pindex={};indices=[]
    for i in range(total):
        state=states.get(i,LEGACY_TO_STATE.get(s.block_id(i),'minecraft:stone' if s.block_id(i) else 'minecraft:air'))
        if state not in pindex:pindex[state]=len(palette);palette.append(state)
        indices.append(pindex[state])
    bits=max(2,(len(palette)-1).bit_length());plist=[]
    for state in palette:
        c={'Name':(8,_base_state(state))}
        if '[' in state:
            props={}
            for item in state.split('[',1)[1].rstrip(']').split(','):
                if '=' in item:k,v=item.split('=',1);props[k]=(8,v)
            if props:c['Properties']=(10,props)
        plist.append(c)
    region={'Position':(10,{'x':(3,0),'y':(3,0),'z':(3,0)}),'Size':(10,{'x':(3,s.width),'y':(3,s.height),'z':(3,s.length)}),'BlockStatePalette':(9,{'type':10,'items':plist}),'BlockStates':(12,_pack_bits(indices,bits)),'TileEntities':(9,{'type':10,'items':[]})}
    root={'MinecraftDataVersion':(3,1976),'Version':(3,6),'SubVersion':(3,1),'Name':(8,s.name),'Regions':(10,{'Schematic':(10,region)})};write(path,'Litematic',root)

def save_obj(path,s):
    path=Path(path);mtl=path.with_suffix('.mtl');lines=['# Minecraft block voxel export','mtllib '+mtl.name];v=1;materials=set()
    for y in range(s.height):
        for z in range(s.length):
            for x in range(s.width):
                i=x+z*s.width+y*s.width*s.length;bid=s.block_id(i);md=s.meta(i)
                if not bid:continue
                mat='block_%d_%d'%(bid,md);materials.add(mat);lines+=['o block_%d_%d_x%d_y%d_z%d'%(bid,md,x,y,z),'usemtl '+mat]
                vs=[(x,y,z),(x+1,y,z),(x+1,y+1,z),(x,y+1,z),(x,y,z+1),(x+1,y,z+1),(x+1,y+1,z+1),(x,y+1,z+1)]
                lines += ['v %.6f %.6f %.6f'%p for p in vs]+['f %d %d %d %d'%(v,v+1,v+2,v+3),'f %d %d %d %d'%(v+4,v+7,v+6,v+5),'f %d %d %d %d'%(v,v+4,v+5,v+1),'f %d %d %d %d'%(v+1,v+5,v+6,v+2),'f %d %d %d %d'%(v+2,v+6,v+7,v+3),'f %d %d %d %d'%(v+4,v,v+3,v+7)];v+=8
    path.write_text('\n'.join(lines)+'\n',encoding='utf-8');mtl.write_text('\n'.join(['newmtl '+m+'\nKd 0.8 0.8 0.8' for m in sorted(materials)])+'\n',encoding='utf-8')

def load_obj(path):
    path=Path(path);names=[];has_vertex=False
    for line in path.read_text(encoding='utf-8',errors='replace').splitlines():
        q=line.strip().split()
        if not q:continue
        if q[0]=='v' and len(q)>=4:has_vertex=True
        elif q[0] in ('o','g') and len(q)>1:names.append(q[1])
    if not has_vertex:raise ValueError('OBJ enthält keine Vertices.')
    parsed=[]
    for n in names:
        m=re.fullmatch(r'block_(\d+)_(\d+)_x(-?\d+)_y(-?\d+)_z(-?\d+)',n)
        if m:parsed.append(tuple(map(int,m.groups())))
    if not parsed:raise ValueError('OBJ enthält keine SchematicTxtGenerator-Blockobjekte (block_ID_META_xX_yY_zZ).')
    w=max(x for _,_,x,_,_ in parsed)+1;h=max(y for _,_,_,y,_ in parsed)+1;l=max(z for _,_,_,_,z in parsed)+1;low=bytearray(w*h*l);data=bytearray(w*h*l)
    for bid,md,x,y,z in parsed:
        if x<0 or y<0 or z<0:continue
        i=x+z*w+y*w*l;low[i]=bid&255;data[i]=md&15
    return Schematic(path.stem,w,h,l,'Universal',bytes(low),bytes(data))

def load_any(path):
    p=Path(path);e=p.suffix.lower()
    if e=='.schematic':return load_schematic(str(p))
    if e=='.txt':return import_txt(str(p))
    if e=='.schem':return load_schem(str(p))
    if e=='.litematic':return load_litematic(str(p))
    if e=='.obj':return load_obj(str(p))
    raise ValueError('Nicht unterstütztes Format: '+e)
def save_any(path,s):
    p=Path(path);e=p.suffix.lower()
    if e=='.txt':return export_txt(s,str(p))
    if e=='.schematic':return save_schematic(str(p),s)
    if e=='.schem':return save_schem(str(p),s)
    if e=='.litematic':return save_litematic(str(p),s)
    if e=='.obj':return save_obj(str(p),s)
    raise ValueError('Nicht unterstütztes Ausgabeformat: '+e)
def convert(src,dst):return save_any(dst,load_any(src))
