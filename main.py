import sys
import re
import time

from cpu import DCPU16


if len(sys.argv) == 1:
    infile = sys.stdin
elif len(sys.argv) == 2:
    infile = open(sys.argv[1])
else:
    print 'usage: %s [infile]' % (sys.argv[0])


cpu = DCPU16()
cpu.loads_hex(infile.read())

cpu.dump()
print

cpu.disassemble()
print

start = time.time()
steps = cpu.run()
print steps / (time.time() - start)
print 
    
cpu.dump()
