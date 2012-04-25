from . import *


class TestADD(TestCase):
    
    def test_basic(self):
        cpu = self.assemble_and_run('''
            set A, 1
            add A, 2
        ''')
        self.assertEqual(cpu['A'], 3)
        self.assertEqual(cpu['EX'], 0)
    
    def test_overflow(self):
        cpu = self.assemble_and_run('''
            set A, 0xf123
            add A, 0x2345
        ''')
        self.assertEqual(cpu['A'], 0x1468)
        self.assertEqual(cpu['EX'], 1)
    
    def test_32bit(self):
        cpu = self.assemble_and_run('''
        
            set X, one
            set Y, two
            
            add [1 + X], [1 + Y]
            add [X], EX
            add [X], [Y]
            
        ; stop
            dat 0
        
        :one
            dat 0x1234, 0x5678
        :two
            dat 0x3456, 0x789a
        
        ''')
        
        X = cpu['X']
        self.assertEqual(cpu[X], 0x468A)
        self.assertEqual(cpu[X + 1], 0xCF12)


class TestMUL(TestCase):
    
    def test_basic(self):
        cpu = self.assemble_and_run('''
            set A, 3
            mul A, 4
        ''')
        self.assertEqual(cpu['A'], 12)
        self.assertEqual(cpu['EX'], 0)
    
    def test_overflow(self):
        cpu = self.assemble_and_run('''
            set A, 0x1234
            mul A, 0x2345
        ''')
        self.assertEqual(cpu['A'], 0x0404)
        self.assertEqual(cpu['EX'], 0x0282)
        
    def test_32bit(self):
        cpu = self.assemble_and_run('''
        
            set X, one
            set Y, two
            
            mul [X], [1 + Y]
            set A, [1 + X]
            mul A, [Y]
            add [X], A
            mul [1 + X], [1 + Y]
            add [X], EX
            
        ; stop
            dat 0
        
        :one
            dat 0x0000, 0x0234
        :two
            dat 0x0001, 0x2345
        
        ''')
        
        X = cpu['X']
        self.assertEqual(cpu[X], 0x0281)
        self.assertEqual(cpu[X + 1], 0xB404)
        
    
