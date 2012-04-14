import unittest
import re

from dcpu16 import asm
from dcpu16 import cpu
from dcpu16 import link
from dcpu16 import ops
from dcpu16 import values

from dcpu16.asm import Assembler
from dcpu16.cpu import CPU
from dcpu16.link import Linker


class TestCase(unittest.TestCase):
    
    def assemble(self, source):
        assembler = Assembler()
        assembler.load(source)
        return assembler.assemble()
    
    def assemble_and_link(self, *sources):
        linker = Linker()
        for source in sources:
            linker.load(self.assemble(source))
        return linker.link()
    
    def normalize_hex(self, source):
        cleaned = []
        
        for line in source.splitlines():
            m = re.match(r'^\s*(:\w+)?(.*:)?([0-9a-fA-F \t]*)([;#].*)?$', line)
            if not m:
                print 'could not parse line %r' % line
                exit(1)
            line = re.sub(r'\s+', '', m.group(3).lower())
            cleaned.append(line)
        
        encoded = ''.join(cleaned)
        chunks = [encoded[i:i + 4] for i in xrange(0, len(encoded), 4)]
        out = []
        
        for i, x in enumerate(chunks):
            if i % 8 == 0:
                if i:
                    out.append('\n')
                out.append('%04x: ' % i)
            else:
                out.append(' ')
            out.append(x)
        
        return ''.join(out)
        
    def assertEqualHex(self, one, two, *args):
        self.assertEqual(self.normalize_hex(one), self.normalize_hex(two), *args)
    
    def assemble_and_run(self, *args):
        hex = self.assemble_and_link(*args)
        cpu = CPU()
        cpu.load(hex)
        cpu.run()
        return cpu






    