import sys
import re


BASIC_OPCODES = '''
    XXX
    SET
    ADD
    SUB
    MUL
    DIV
    MOD
    SHL
    SHR
    AND
    BOR
    XOR
    IFE
    IFN
    IFG
    IFB
'''.strip().split()

NONBASIC_OPCODES = '''
    XXX
    JSR
'''.strip().split()

REGISTERS = 'ABCXYZIJ'


if len(sys.argv) == 1:
    infile = sys.stdin
elif len(sys.argv) == 2:
    infile = open(sys.argv[1])
else:
    print 'usage: %s [infile]' % (sys.argv[0])


def prep_line(line):
    line = re.sub(r';.*', '', line)
    line = re.sub(r'.*:', '', line)
    line = re.sub(r'[^0-9a-f]', '', line.lower())
    return line

encoded = ''.join(prep_line(x) for x in infile)
words = [(i / 4, int(encoded[i:i+4], 16)) for i in xrange(0, len(encoded), 4)]
words_copy = words[:]

# print '\n'.join('%04x' % x for x in words)

def get_value(value):
    
    # Registers.
    if value <= 0x07:
        return REGISTERS[value]
    
    # Indirect registers.
    if value <= 0x0f:
        return '[%s]' % (REGISTERS[value - 0x08])
    
    # Indirect register with offset.
    if value <= 0x17:
        return '[0x%x + %s]' % (words.pop(0)[1], REGISTERS[value - 0x10])
    
    if value == 0x18:
        return 'POP'
    if value == 0x19:
        return 'PEEK'
    if value == 0x1a:
        return 'PUSH'
    if value == 0x1b:
        return 'SP'
    if value == 0x1c:
        return 'PC'
    if value == 0x1d:
        return 'O'
    
    if value == 0x1e:
        return '[0x%04x]' % words.pop(0)[1]
    if value == 0x1f:
        return '0x%04x' % words.pop(0)[1]
    
    if value >= 0x20 and value <= 0x3f:
        return '0x%02x' % (value - 0x20)
    
    return 'UNKNOWN(0x%x)' % (value)
    
while words:
    
    start_word_count = len(words)
    
    addr, word = words.pop(0)
    # print '%04x' % word
    opcode = word & 0xf
    a = (word >> 4) & 0x3f
    b = (word >> 10) & 0x3f
    # print '\t%02x %02x %02x' % (opcode, a, b)
    
    
    if opcode:
        basic = True
        a = get_value(a)
        b = get_value(b)
    else:
        basic = False
        opcode, a, b = a, b, None
        a = get_value(a)

    words_used = start_word_count - len(words)
    if basic:
        out = '%04x: %s %s, %s' % (addr, BASIC_OPCODES[opcode], a, b)
    else:
        out = '%04x: %s %s' % (addr, NONBASIC_OPCODES[opcode], a)
    dump = ' '.join('%04x' % x[1] for x in words_copy[addr:addr + words_used])
    print '%-40s; %s' % (out, dump)
    
