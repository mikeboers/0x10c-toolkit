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
    RSV
    JSR
'''.strip().split()

REGISTER_NAMES = 'ABCXYZIJ'





class DCPU16(object):
    
    def __init__(self):
        self.registers = [0] * 8
        self.PC = 0
        self.SP = 0xffff
        self.O = 0
        self.memory = [0] * 0x10000
    
    def loads_hex(self, encoded, location=0):
        encoded = re.sub(r';.*$', '', encoded, 0, re.M) # strip comments
        encoded = re.sub(r'^.*:', '', encoded, 0, re.M) # strip addresses
        encoded = encoded.lower()
        encoded = re.sub(r'[^0-9a-f]', '', encoded) # strip non-hex
        for i in xrange(len(encoded) / 4):
            self.memory[location + i] = int(encoded[4 * i:4 * i + 4], 16)
    
    def dump(self):
        max_i = max(i if self.memory[i] else 0 for i in xrange(0x10000))
        for i in xrange(0, max_i, 8):
            print '; %04x:' % (i,),
            for j in xrange(8):
                offset = i + j
                if offset >= 0x10000:
                    break
                print '%04x' % (self.memory[offset],),
            print
                
    def disassemble(self, location=None):
        old_PC = self.PC
        if location:
            self.PC = location
        
        self._disassemble()
        self.PC = old_PC
    
    def _disassemble(self):
        while self.memory[self.PC]:
            self._disassemble_one()
    
    def _disassemble_one(self):
        
        start_PC = self.PC
        
        word = self.get_next_word()
        opcode = word & 0xf
        a = (word >> 4) & 0x3f
        b = (word >> 10) & 0x3f
        
        # print '%04x: %02x %02x %02x' % (self.PC, opcode, a, b)
        
        if opcode:
            basic = True
            a = self.get_op_value(a)
            b = self.get_op_value(b)
        else:
            basic = False
            opcode, a, b = a, b, None
            a = self.get_op_value(a)
        
        end_PC = self.PC
        
        if basic:
            out = '%s %s, %s' % (BASIC_OPCODES[opcode], a, b)
        else:
            out = '%s %s' % (NONBASIC_OPCODES[opcode], a)
        dump = ' '.join('%04x' % x for x in self.memory[start_PC:end_PC])
        print '%-30s; %04x: %s' % (out, start_PC, dump)
            
    
    def get_next_word(self):
        word = self.memory[self.PC]
        self.PC += 1
        return word
    
    def get_op_value(self, value):
    
        # Registers.
        if value <= 0x07:
            return REGISTER_NAMES[value]
    
        # Indirect registers.
        if value <= 0x0f:
            return '[%s]' % (REGISTER_NAMES[value - 0x08])
    
        # Indirect register with offset.
        if value <= 0x17:
            return '[0x%x + %s]' % (self.get_next_word(), REGISTER_NAMES[value - 0x10])
    
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
            return '[0x%x]' % self.get_next_word()
        if value == 0x1f:
            return '0x%x' % self.get_next_word()
    
        if value >= 0x20 and value <= 0x3f:
            return '0x%x' % (value - 0x20)
    
        return 'UNKNOWN(0x%x)' % (value)



if __name__ == '__main__':
    
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
    