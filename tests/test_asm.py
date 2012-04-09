from . import TestCase

import values
from cpu import CPU
from asm import Assembler
from link import Linker


class TestASM(TestCase):
    
    def test_literal_bases(self):
        self.assertEqualHex(self.assemble_and_link('''
            set A, 2000
            set B, 0d2001
            set C, 0x2002
            set X, 0o3000
            set Y, 0b1111111
        '''),
        '''
            ; Manually verified with the disassembler.
            0000: 7c01 07d0 7c11 07d1 7c21 2002 7c31 0600
            0008: 7c41 007f
        ''')
        
    def test_op_case(self):
        self.assertEqualHex(self.assemble_and_link('''
            SET A, 0
            set B, 1
            set c, 2
            set X, 0X3
            set Y, 0O4
            set Z, 0D5
            set I, 0B110
        '''), '''
            ; Manually verified with the disassembler.
            0000: 8001 8411 8821 8c31 9041 9451 9861
        ''')
    
    def test_label_case(self):
        self.assertEqualHex(self.assemble_and_link('''
            set A, test
            set B, Test
            set C, TEST
            dat 0 ; end

        test: dat 0
        Test: dat 1
        TEST: dat 2
            
        '''), '''
            ; Manually verified with the disassembler.
            0000: 7c01 0007 7c11 0008 7c21 0009 0000 0000
            0008: 0001 0002
        ''')
    
    def test_string_case(self):
        self.assertEqualHex(self.assemble_and_link('''
            dat "hello", 0
            dat "HELLO", 0
            dat 'a', 'A', 0
        '''), '''
            0000: 0068 0065 006c 006c 006f 0000 0048 0045
            0008: 004c 004c 004f 0000 0061 0041 0000
        ''')
    
    def test_character_escapes(self):
        self.assertEqualHex(self.assemble(r'''
            dat '\0', '\n', '\t', '\r', ' '
        '''), '''
            0000: 0000 000a 0009 000d 0020
        ''')
    
    def test_string_escapes(self):
        self.assertEqualHex(self.assemble(r'''
            dat "\tbefore\0after\r\n"
        '''), '''
            0000: 0009 0062 0065 0066 006f 0072 0065 0000
            0008: 0061 0066 0074 0065 0072 000d 000a
        ''')
        
        
