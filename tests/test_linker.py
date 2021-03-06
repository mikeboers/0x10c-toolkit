from . import *


class TestLinker(TestCase):
    
    def test_symbols_across_files(self):
        
        a = '''
        
        :start
            set A, [data]
            jsr func
        :exit
            set PC, exit
        
        '''
        b = '''
            
        .GLOBAL func
        :func
            add A, A
            set PC, POP
                
        .GLOBAL data
        :data
            DAT 0x1234
            
        '''
        
        hex = self.assemble_and_link(a, b)
        self.assertEqualHex(hex, '''
            0000: ???? 0008 ???? 0006 ???? 0004 0002 ????
            0008: 1234
        ''')
        
        cpu = CPU()
        cpu.load(hex)
        cpu.run()
        
        self.assertEqual(cpu['A'], 0x1234 * 2)
    
    def test_label_offsets(self):
        self.assertEqualHex(self.assemble_and_link('''
            set A, data
            set B, data + 1
            set C, 2 + data
            set X, [data]
            set Y, [data + 1]
            set Z, [2 + data]
            dat 0
            :data dat 0x1234, 0x5678, 0x9abc
        '''), '''
            0000: ???? 000d ???? 000e ???? 000f ???? 000d
            0008: ???? 000e ???? 000f 0000 1234 5678 9abc
        ''')
        
        
    def test_negative_labels(self):
        self.assertEqualHex(self.assemble_and_link('''
            :al dat 0, 1, 2, 3, 4
            :bl dat 5, 6, 7, 8, 9
            :cl dat 10 - al, 10 - bl, 10 - cl
        '''), self.assemble_and_link('''
            :al dat 0, 1, 2, 3, 4
            :bl dat 5, 6, 7, 8, 9
            :cl dat 10, 5, 0
            
        '''))
        
    
        
        