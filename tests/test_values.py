from . import *


class TestLiterals(TestCase):
    
    def test_short_code(self):
        v = values.Literal(0xffff)
        self.assertEqual(v.hex(), (0x20, ()))
        v = values.Literal(0)
        self.assertEqual(v.hex(), (0x21, ()))
        v = values.Literal(30)
        self.assertEqual(v.hex(), (0x21 + 30, ()))
    
    def test_long_code(self):
        v = values.Literal(31)
        self.assertEqual(v.hex(), (0x1f, (31, )))
        v = values.Literal(0x1234)
        self.assertEqual(v.hex(), (0x1f, (0x1234, )))
    
    def test_get(self):
        cpu = CPU()
        for i in [0x0, 0x1, 0x10, 0x100, 0x1000, 0xffff]:
            v = values.Literal(i)
            self.assertEqual(v.get(cpu), i)
    
    def test_set(self):
        cpu = CPU()
        v = values.Literal(0x0)
        v.set(cpu, 0x1)
        
        # It doesn't set, because you CANT set literals; it fails silently.
        self.assertEqual(v.get(cpu), 0)
    
    def test_short_minus_one(self):
        self.assertEqualHex(self.assemble('''
            SET A, 0xffff
        '''), '''
            0000: ????
        ''')
    
        cpu = self.assemble_and_run('''
            SET A, 0xffff
        ''')
        self.assertEqual(cpu['A'], 0xffff)
    
        cpu = self.assemble_and_run('''
            SET A, -1
        ''')
        self.assertEqual(cpu['A'], 0xffff)
    


class TestRegisters(TestCase):
    
    def test_labels(self):
        reg = values.Register(0, offset=10, label='data')
        self.assertEqual(reg.asm(), '[data + 0xa + A]')
        self.assertEqual(reg.hex(), (16, (values.Label('data', offset=10),)))
        self.assertNotEqual(reg.hex(), (16, (values.Label('data', offset=11),)))
        self.assertNotEqual(reg.hex(), (16, (values.Label('other', offset=10),)))
        
        