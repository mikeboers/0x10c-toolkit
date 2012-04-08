import sys
import re
import time

from cpu import CPU


if len(sys.argv) == 1:
    infile = sys.stdin
elif len(sys.argv) == 2:
    infile = open(sys.argv[1])
else:
    print 'usage: %s [infile]' % (sys.argv[0])


cpu = CPU()
cpu.loads_hex(infile.read())

cpu.dump()
print

cpu.disassemble()
print
