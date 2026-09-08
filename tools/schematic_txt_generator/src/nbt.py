import gzip, struct
TAG_END=0; TAG_BYTE=1; TAG_SHORT=2; TAG_INT=3; TAG_LONG=4; TAG_FLOAT=5; TAG_DOUBLE=6; TAG_BYTE_ARRAY=7; TAG_STRING=8; TAG_LIST=9; TAG_COMPOUND=10
class NBTError(Exception): pass
def exact(f,n):
 b=f.read(n)
 if len(b)!=n: raise NBTError('Unerwartetes Dateiende.')
 return b
def rstr(f):
 n=struct.unpack('>H',exact(f,2))[0]; return exact(f,n).decode('utf-8')
def readp(f,t):
 if t==1:return struct.unpack('>b',exact(f,1))[0]
 if t==2:return struct.unpack('>h',exact(f,2))[0]
 if t==3:return struct.unpack('>i',exact(f,4))[0]
 if t==4:return struct.unpack('>q',exact(f,8))[0]
 if t==5:return struct.unpack('>f',exact(f,4))[0]
 if t==6:return struct.unpack('>d',exact(f,8))[0]
 if t==7:
  n=struct.unpack('>i',exact(f,4))[0]; return exact(f,n)
 if t==8:return rstr(f)
 if t==9:
  st=struct.unpack('>b',exact(f,1))[0]; n=struct.unpack('>i',exact(f,4))[0]; return {'type':st,'items':[readp(f,st) for _ in range(n)]}
 if t==10:
  d={}
  while True:
   st=struct.unpack('>b',exact(f,1))[0]
   if st==0:return d
   d[rstr(f)]=(st,readp(f,st))
 raise NBTError('Nicht unterstützter NBT-Tag: %s'%t)
def read(path):
 with gzip.open(path,'rb') as f:
  if struct.unpack('>b',exact(f,1))[0]!=10:raise NBTError('Root ist kein Compound.')
  return rstr(f),readp(f,10)
def wstr(f,s):
 b=s.encode('utf-8');f.write(struct.pack('>H',len(b)));f.write(b)
def writep(f,t,v):
 if t==1:f.write(struct.pack('>b',int(v)))
 elif t==2:f.write(struct.pack('>h',int(v)))
 elif t==3:f.write(struct.pack('>i',int(v)))
 elif t==4:f.write(struct.pack('>q',int(v)))
 elif t==5:f.write(struct.pack('>f',float(v)))
 elif t==6:f.write(struct.pack('>d',float(v)))
 elif t==7:f.write(struct.pack('>i',len(v)));f.write(bytes(v))
 elif t==8:wstr(f,v)
 elif t==9:
  f.write(struct.pack('>b',v['type']));f.write(struct.pack('>i',len(v['items'])))
  for x in v['items']:writep(f,v['type'],x)
 elif t==10:
  for k,(st,x) in v.items():f.write(struct.pack('>b',st));wstr(f,k);writep(f,st,x)
  f.write(b'\0')
 else:raise NBTError('Nicht unterstützter NBT-Tag: %s'%t)
def write(path,name,root):
 with gzip.open(path,'wb') as f:f.write(b'\x0a');wstr(f,name);writep(f,10,root)
