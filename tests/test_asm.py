from . import *


class TestASM(TestCase):
    
    def test_literal_bases(self):
        self.assertEqualHex(self.assemble('''
            dat 2000, 0d2001, 0x2002, 0o3000, 0b1111111
        '''),
        '''
            0000: 07d0 07d1 2002 0600 007f
        ''')
        
    def test_op_case(self):
        self.assertEqualHex(self.assemble('''
            SET A, 0
            set B, 1
            set c, 2
            set X, 0X3
            set Y, 0O4
            set Z, 0D5
            set I, 0B110
        '''), '''
            ; Manually verified with the disassembler.
            0000: 8401 8821 8c41 9061 9481 98a1 9cc1
        ''')
    
    def test_label_case(self):
        self.assertEqualHex(self.assemble_and_link('''
            set A, test
            set B, Test
            set C, TEST
            dat 0 ; end

        :test dat 0
        :Test dat 1
        :TEST dat 2
            
        '''), '''
            ; Manually verified with the disassembler.
            0000: ???? 0007 ???? 0008 ???? 0009 0000 0000
            0008: 0001 0002
        ''')
    
    def test_string_case(self):
        self.assertEqualHex(self.assemble('''
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
    
    def test_register_offset_flexibility(self):
        self.assertEqualHex(self.assemble('''
            set [A + 0], [B + 1]
        '''), self.assemble('''
            set [0 + A], [1 + B]
        '''))
    
    def test_multiple_offsets(self):
        self.assertEqualHex(self.assemble('''
            set [A + 1 + 10], [0x10 + B + 1]
        '''), self.assemble('''
            set [11 + A], [17 + B]
        '''))
    
    def test_register_labels(self):
        self.assertEqualHex(self.assemble('''
            :start set [A + 1 + 10 + start], [0x10 + B + 1]
        '''), self.assemble('''
            set [11 + A], [17 + B]
        '''))
    
    def test_negative_values(self):
        self.assertEqualHex(self.assemble('''
            set [0x1000 - 1], 0x1234
        '''), self.assemble('''
            set [0x0fff], 0x1234
        '''))
        
    def test_negative_offsets(self):
        self.assertEqualHex(self.assemble('''
            set [A - 1], 0x1234
        '''), self.assemble('''
            set [A + 0xffff], 0x1234
        '''))
        
        
        
    
        
        
        
        
