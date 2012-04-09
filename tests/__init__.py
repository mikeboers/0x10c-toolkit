import unittest
import re

from cpu import CPU
import values
import ops
from link import Linker
from asm import Assembler

class TestCase(unittest.TestCase):
    
    def assemble(self, source):
        assembler = Assembler()
        assembler.loads(source)
        return assembler.dumps()
    
    def assemble_and_link(self, *sources):
        linker = Linker()
        for source in sources:
            linker.loads(self.assemble(source))
        linker.link()
        return linker.dumps()
    
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
        cpu.loads(hex)
        cpu.run()
        return cpu
    