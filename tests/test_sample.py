from . import TestCase

import values
from cpu import CPU
from asm import Assembler
# from link import Linker

class TestSample(TestCase):
    
    def test_run(self):
        source = '''
        0000: 7c01 0030 7de1 1000 0020 7803 1000 c00d
        0008: 7dc1 001a a861 7c01 2000 2161 2000 8463
        0010: 806d 7dc1 000d 9031 7c10 0018 7dc1 001a
        0018: 9037 61c1 7dc1 001a 0000 0000 0000 0000
        '''
        
        cpu = CPU()
        cpu.loads(source)
        cpu.run()
        
        self.assertEquals(cpu[0xffff], 0x16)
        self.assertEquals(cpu['PC'], 0x1a)
        self.assertEquals(cpu['SP'], 0)
        self.assertEquals(cpu['X'], 0x40)
    
    def test_assemble(self):
        
        source = '''
        ; Try some basic stuff
                      SET A, 0x30              ; 7c01 0030
                      SET [0x1000], 0x20       ; 7de1 1000 0020
                      SUB A, [0x1000]          ; 7803 1000
                      IFN A, 0x10              ; c00d 
                         SET PC, crash         ; 7dc1 001a [*]
                      
        ; Do a loopy thing
                      SET I, 10                ; a861
                      SET A, 0x2000            ; 7c01 2000
        :loop         SET [0x2000+I], [A]      ; 2161 2000
                      SUB I, 1                 ; 8463
                      IFN I, 0                 ; 806d
                         SET PC, loop          ; 7dc1 000d [*]
        
        ; Call a subroutine
                      SET X, 0x4               ; 9031
                      JSR testsub              ; 7c10 0018 [*]
                      SET PC, crash            ; 7dc1 001a [*]
        
        :testsub      SHL X, 4                 ; 9037
                      SET PC, POP              ; 61c1
                        
        ; Hang forever. X should now be 0x40 if everything went right.
        :crash        SET PC, crash            ; 7dc1 001a [*]
        
        ; [*]: Note that these can be one word shorter and one cycle faster by using the short form (0x00-0x1f) of literals,
        ;      but my assembler doesn't support short form labels yet.     
        '''
        
        