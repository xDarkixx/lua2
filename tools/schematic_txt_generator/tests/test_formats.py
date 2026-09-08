import os
import tempfile
import unittest
from pathlib import Path

from src.schematic import Schematic
from src.format_router import load_any, save_any


class FormatRoundTripTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        # 3 x 2 x 2, including a high legacy ID to exercise AddBlocks.
        w, h, l = 3, 2, 2
        blocks = bytearray(w*h*l)
        data = bytearray(w*h*l)
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
        self.check_numeric(load_any(p))

    def test_litematic(self):
        p = Path(self.tmp.name) / 'a.litematic'
        save_any(p, self.s)
        self.check_numeric(load_any(p))

    def test_obj_and_mtl(self):
        p = Path(self.tmp.name) / 'a.obj'
        save_any(p, self.s)
        self.assertTrue(p.exists())
        self.assertTrue(p.with_suffix('.mtl').exists())
        self.check_numeric(load_any(p))


if __name__ == '__main__':
    unittest.main()
