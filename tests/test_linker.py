from . import TestCase

import values
from cpu import CPU
from asm import Assembler
from link import Linker


class TestLinker(TestCase):
    
    def test_symbols_across_files(self):
        
        self.assertEqualHex(self.assemble_and_link(
            '''
            set A, data
            jsr func
            
            ''', '''
            
            .GLOBAL func
            func:
                mul A, 2
                set PC, POP
                
            .GLOBAL data
            data: DAT 0x1234
            
            '''
        ), '''
            0000: 7c01 0006 7c10 0004 8804 61c1 1234
           '''
        )
        