import gzip
import io
import struct

TAG_END = 0
TAG_BYTE = 1
TAG_SHORT = 2
TAG_INT = 3
TAG_LONG = 4
TAG_FLOAT = 5
TAG_DOUBLE = 6
TAG_BYTE_ARRAY = 7
TAG_STRING = 8
TAG_LIST = 9
TAG_COMPOUND = 10
TAG_INT_ARRAY = 11
TAG_LONG_ARRAY = 12

class NBTError(Exception):
    pass


def exact(f, n):
    b = f.read(n)
    if len(b) != n:
        raise NBTError('Unerwartetes Dateiende bei Position %d (benötigt %d, erhalten %d).' % (f.tell(), n, len(b)))
    return b


def rstr(f):
    n = struct.unpack('>H', exact(f, 2))[0]
    return exact(f, n).decode('utf-8')


def readp(f, t):
    if t == TAG_BYTE:
        return struct.unpack('>b', exact(f, 1))[0]
    if t == TAG_SHORT:
        return struct.unpack('>h', exact(f, 2))[0]
    if t == TAG_INT:
        return struct.unpack('>i', exact(f, 4))[0]
    if t == TAG_LONG:
        return struct.unpack('>q', exact(f, 8))[0]
    if t == TAG_FLOAT:
        return struct.unpack('>f', exact(f, 4))[0]
    if t == TAG_DOUBLE:
        return struct.unpack('>d', exact(f, 8))[0]
    if t == TAG_BYTE_ARRAY:
        n = struct.unpack('>i', exact(f, 4))[0]
        if n < 0:
            raise NBTError('Negative ByteArray-Länge.')
        return exact(f, n)
    if t == TAG_STRING:
        return rstr(f)
    if t == TAG_LIST:
        st = struct.unpack('>B', exact(f, 1))[0]
        n = struct.unpack('>i', exact(f, 4))[0]
        if n < 0:
            raise NBTError('Negative List-Länge.')
        if st == TAG_END and n:
            raise NBTError('NBT-Liste mit TAG_End und nicht-leerer Länge.')
        return {'type': st, 'items': [readp(f, st) for _ in range(n)]}
    if t == TAG_COMPOUND:
        d = {}
        while True:
            st = struct.unpack('>B', exact(f, 1))[0]
            if st == TAG_END:
                return d
            if st < TAG_BYTE or st > TAG_LONG_ARRAY:
                raise NBTError('Ungültiger NBT-Tag-Typ %d bei Position %d.' % (st, f.tell() - 1))
            name = rstr(f)
            d[name] = (st, readp(f, st))
    if t in (TAG_INT_ARRAY, TAG_LONG_ARRAY):
        n = struct.unpack('>i', exact(f, 4))[0]
        if n < 0:
            raise NBTError('Negative Array-Länge.')
        if t == TAG_INT_ARRAY:
            return [struct.unpack('>i', exact(f, 4))[0] for _ in range(n)]
        return [struct.unpack('>q', exact(f, 8))[0] for _ in range(n)]
    raise NBTError('Nicht unterstützter NBT-Tag: %s' % t)


def _open_read(path):
    with open(path, 'rb') as source:
        raw = source.read()
    if raw[:2] == b'\x1f\x8b':
        return gzip.GzipFile(fileobj=io.BytesIO(raw), mode='rb')
    return io.BytesIO(raw)


def read(path):
    with _open_read(path) as f:
        root_type = struct.unpack('>B', exact(f, 1))[0]
        if root_type != TAG_COMPOUND:
            raise NBTError('Root ist kein Compound (Tag %d).' % root_type)
        return rstr(f), readp(f, TAG_COMPOUND)


def wstr(f, s):
    b = str(s).encode('utf-8')
    if len(b) > 65535:
        raise NBTError('NBT-String ist zu lang.')
    f.write(struct.pack('>H', len(b)))
    f.write(b)


def writep(f, t, v):
    if t == TAG_BYTE:
        f.write(struct.pack('>b', int(v)))
    elif t == TAG_SHORT:
        f.write(struct.pack('>h', int(v)))
    elif t == TAG_INT:
        f.write(struct.pack('>i', int(v)))
    elif t == TAG_LONG:
        f.write(struct.pack('>q', int(v)))
    elif t == TAG_FLOAT:
        f.write(struct.pack('>f', float(v)))
    elif t == TAG_DOUBLE:
        f.write(struct.pack('>d', float(v)))
    elif t == TAG_BYTE_ARRAY:
        f.write(struct.pack('>i', len(v)))
        f.write(bytes(v))
    elif t == TAG_STRING:
        wstr(f, v)
    elif t == TAG_LIST:
        st = int(v['type'])
        f.write(struct.pack('>B', st))
        f.write(struct.pack('>i', len(v['items'])))
        for x in v['items']:
            writep(f, st, x)
    elif t == TAG_COMPOUND:
        for k, (st, x) in v.items():
            f.write(struct.pack('>B', int(st)))
            wstr(f, k)
            writep(f, int(st), x)
        f.write(b'\0')
    elif t == TAG_INT_ARRAY:
        vals = v or []
        f.write(struct.pack('>i', len(vals)))
        for x in vals:
            f.write(struct.pack('>i', int(x)))
    elif t == TAG_LONG_ARRAY:
        vals = v or []
        f.write(struct.pack('>i', len(vals)))
        for x in vals:
            f.write(struct.pack('>q', int(x)))
    else:
        raise NBTError('Nicht unterstützter NBT-Tag: %s' % t)


def write(path, name, root):
    with gzip.open(path, 'wb') as f:
        f.write(bytes((TAG_COMPOUND,)))
        wstr(f, name)
        writep(f, TAG_COMPOUND, root)
