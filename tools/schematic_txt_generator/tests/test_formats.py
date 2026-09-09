import tempfile
import unittest
from pathlib import Path

from src.schematic import Schematic
from src.format_router import (
    load_any, save_any, _nbt, _v, _list, _state_name,
    _longs, _bits, _pack_bits, _varints, _put_varints,
)
from src.txtformat import import_txt


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
        # Real AddBlocks entry for index 4: high nibble 1 -> ID 511.
        add = bytearray((w * h * l + 1) // 2)
        add[2] = 0x10
        s = Schematic('roundtrip', w, h, l, 'Alpha', bytes(blocks), bytes(data), bytes(add))
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

    def test_txt_roundtrip_including_high_legacy_id(self):
        p = Path(self.tmp.name) / 'a.txt'
        save_any(p, self.s)
        got = load_any(p)
        self.check_numeric(got)
        self.assertEqual(got.block_id(4), 511)

    def test_txt_preserves_modern_state_and_properties(self):
        s = Schematic('states', 2, 1, 1, 'Universal', bytes([20, 1]), bytes(2))
        s.states = {0: 'minecraft:oak_log[axis=y]', 1: 'minecraft:stone'}
        p = Path(self.tmp.name) / 'states.txt'
        save_any(p, s)
        got = load_any(p)
        self.assertEqual(getattr(got, 'states', {})[0], 'minecraft:oak_log[axis=y]')
        self.assertEqual(getattr(got, 'states', {})[1], 'minecraft:stone')

    def test_schematic_roundtrip_addblocks(self):
        p = Path(self.tmp.name) / 'a.schematic'
        save_any(p, self.s)
        self.check_numeric(load_any(p))
        self.assertEqual(load_any(p).block_id(4), 511)

    def test_schematic_rejects_legacy_id_above_4095(self):
        s = Schematic('invalid', 1, 1, 1, 'Universal', bytes([0]), bytes([0]))
        s.blocks = bytes([0])
        s.data = bytes([0])
        s.addblocks = bytes([0x10])
        # Simulate an out-of-range internal value without changing the public API.
        s.block_id = lambda i: 4096
        p = Path(self.tmp.name) / 'invalid.schematic'
        with self.assertRaises(ValueError):
            save_any(p, s)

    def test_schematic_rejects_wrong_addblocks_length(self):
        p = Path(self.tmp.name) / 'bad.schematic'
        from src.nbt import write
        write(p, 'Schematic', {
            'Width': (2, 3), 'Height': (2, 2), 'Length': (2, 2),
            'Materials': (8, 'Alpha'), 'Blocks': (7, bytes(12)),
            'Data': (7, bytes(12)), 'AddBlocks': (7, bytes(1)),
        })
        with self.assertRaises(Exception):
            load_any(p)

    def test_schem_roundtrip(self):
        p = Path(self.tmp.name) / 'a.schem'
        save_any(p, self.s)
        got = load_any(p)
        self.check_modern_states(got)
        self.assertEqual(getattr(got, 'states', {})[4], 'minecraft:stone')

    def test_litematic_roundtrip_crosses_long_boundary(self):
        # 5-bit entries deliberately cross 64-bit boundaries.
        values = [0, 1, 2, 3, 7, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]
        packed = _pack_bits(values, 5)
        self.assertEqual(_bits([x & ((1 << 64) - 1) for x in packed], 5, len(values)), values)

        s = Schematic('litematic', len(values), 1, 1, 'Universal', bytes([1] * len(values)), bytes(len(values)))
        s.states = {i: f'minecraft:test_block_{v}' for i, v in enumerate(values)}
        p = Path(self.tmp.name) / 'a.litematic'
        save_any(p, s)
        root = _nbt(p)
        region = next(iter(_v(root, 'Regions', {}).values()))[1]
        palette = [_state_name(x) for x in _list(_v(region, 'BlockStatePalette', {}))]
        bits = max(2, (len(palette) - 1).bit_length())
        raw = _longs(_v(region, 'BlockStates', []))
        indices = _bits(raw, bits, len(values))
        self.assertEqual(len(indices), len(values))
        self.assertEqual(load_any(p).width, len(values))

    def test_obj_and_mtl(self):
        p = Path(self.tmp.name) / 'a.obj'
        save_any(p, self.s)
        self.assertTrue(p.exists())
        self.assertTrue(p.with_suffix('.mtl').exists())
        self.check_numeric(load_any(p))

    def test_varint_helpers(self):
        values = [0, 1, 127, 128, 255, 16384, 1048575]
        self.assertEqual(_varints(_put_varints(values)), values)

    def test_invalid_txt_is_rejected(self):
        p = Path(self.tmp.name) / 'bad.txt'
        p.write_text(
            'SCHEMATIC_TXT 1\nsize=2,2,2\n2,0,0=1:0\n',
            encoding='utf-8',
        )
        with self.assertRaises(ValueError):
            import_txt(p)

    def test_unsupported_extension_is_rejected(self):
        p = Path(self.tmp.name) / 'a.xyz'
        p.write_text('x', encoding='utf-8')
        with self.assertRaises(ValueError):
            load_any(p)


if __name__ == '__main__':
    unittest.main()
