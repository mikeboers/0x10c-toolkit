from . import TestCase

import values
from cpu import CPU
from asm import Assembler
from link import Linker


class TestLinker(TestCase):
    
    def test_symbols_across_files(self):
        
        a = '''
        
        start:
            set A, [data]
            jsr func
        exit:
            set PC, exit
        
        '''
        b = '''
            
        .GLOBAL func
        func:
            add A, A
            set PC, POP
                
        .GLOBAL data
        data:
            DAT 0x1234
            
        '''
        
        hex = self.assemble_and_link(a, b)
        self.assertEqualHex(hex, '''
            0000: 7801 0008 7c10 0006 7dc1 0004 0002 61c1
            0008: 1234
        ''')
        
        cpu = CPU()
        cpu.loads(hex)
        cpu.run()
        
        self.assertEqual(cpu['A'], 0x1234 * 2)
        
        