
from . import TestCase

import values
from cpu import CPU

class TestLiterals(TestCase):
    
    def test_short_code(self):
        v = values.Literal(0)
        self.assertEqual(v.to_code(), (0x20, ()))
        v = values.Literal(0x1f)
        self.assertEqual(v.to_code(), (0x20 + 0x1f, ()))
    
    def test_long_code(self):
        v = values.Literal(0x20)
        self.assertEqual(v.to_code(), (0x1f, (0x20, )))
        v = values.Literal(0x1234)
        self.assertEqual(v.to_code(), (0x1f, (0x1234, )))
    
    def test_get(self):
        cpu = CPU()
        for i in [0x0, 0x1, 0x10, 0x100, 0x1000, 0xffff]:
            v = values.Literal(i)
            self.assertEqual(v.get(cpu), i)
    
    def test_set(self):
        cpu = CPU()
        v = values.Literal(0x0)
        with self.assertRaises(TypeError):
            v.set(cpu, 0x1)
    
        
        