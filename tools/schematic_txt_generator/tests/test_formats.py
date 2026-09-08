import tempfile
import unittest
from pathlib import Path

from src.schematic import Schematic
from src.format_router import load_any, save_any, _nbt, _v, _list, _state_name, _longs, _bits


class FormatRoundTripTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        w, h, l = 3, 2, 2
        blocks = bytearray(w * h * l)
        data = bytearray(w * h * l)
        blocks[0] = 1
        blocks[1] = 20
        blocks[2] = 49
        blocks[3] = 57
        blocks[4] = 255
        data[4] = 3
        s = Schematic('roundtrip', w, h, l, 'Alpha', bytes(blocks), bytes(data))
        s.addblocks = bytes([0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0])
        self.s = s

    def tearDown(self):
        self.tmp.cleanup()

    def check_numeric(self, got):
        self.assertEqual((got.width, got.height, got.length), (3, 2, 2))
        for i in range(12):
            self.assertEqual(got.block_id(i), self.s.block_id(i))
            self.assertEqual(got.meta(i), self.s.meta(i))

    def check_modern_states(self, got):
        self.assertEqual((got.width, got.height, got.length), (3, 2, 2))
        states = getattr(got, 'states', {})
        self.assertEqual(states[0], 'minecraft:stone')
        self.assertEqual(states[1], 'minecraft:glass')
        self.assertEqual(states[2], 'minecraft:obsidian')
        self.assertEqual(states[3], 'minecraft:diamond_block')

    def test_txt(self):
        p = Path(self.tmp.name) / 'a.txt'
        save_any(p, self.s)
        self.check_numeric(load_any(p))

    def test_schematic(self):
        p = Path(self.tmp.name) / 'a.schematic'
        save_any(p, self.s)
        self.check_numeric(load_any(p))

    def test_schem(self):
        p = Path(self.tmp.name) / 'a.schem'
        save_any(p, self.s)
        self.check_modern_states(load_any(p))

    def test_litematic(self):
        p = Path(self.tmp.name) / 'a.litematic'
        save_any(p, self.s)
        root = _nbt(p)
        region = next(iter(_v(root, 'Regions', {}).values()))[1]
        palette = [_state_name(x) for x in _list(_v(region, 'BlockStatePalette', {}))]
        bits = max(2, (len(palette) - 1).bit_length())
        raw = _longs(_v(region, 'BlockStates', []))
        self.assertEqual(len(_bits(raw, bits, 12)), 12)
        self.check_modern_states(load_any(p))

    def test_obj_and_mtl(self):
        p = Path(self.tmp.name) / 'a.obj'
        save_any(p, self.s)
        self.assertTrue(p.exists())
        self.assertTrue(p.with_suffix('.mtl').exists())
        self.check_numeric(load_any(p))


if __name__ == '__main__':
    unittest.main()
