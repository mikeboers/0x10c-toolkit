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



class Operation(object):
    pass


class BaseValue(object):
    
    def __init__(self, value):
        self.value = value
    
    def eval(self, cpu):
        raise RuntimeError('cannot eval %r' % self)

    def save(self, cpu, value):
        raise TypeError('cannot save to %r' % self)
    
    def __repr__(self):
        return '%s(%r)' % (self.__class__.__name__, self.value)


class RegisterValue(BaseValue):
    
    def __init__(self, index, indirect=False, offset=None):
        self.index = index
        self.indirect = indirect
        self.offset = offset
    
    def eval(self, cpu):
        if isinstance(self.index, basestring):
            return getattr(cpu, self.index)
        if self.indirect or self.offset:
            loc = cpu.registers[self.index] + (self.offset or 0)
            return cpu.memory[loc]
        else:
            return cpu.registers[self.index]
    
    def save(self, cpu, value):
        if isinstance(self.index, basestring):
            setattr(cpu, self.index, value.eval(cpu))
        else:
            if self.indirect or self.offset:
                loc = cpu.registers[self.index] + (self.offset or 0)
                cpu.memory[loc] = value.eval(cpu)
            else:
                cpu.registers[self.index] = value.eval(cpu)
    
    def __repr__(self):
        if isinstance(self.index, basestring):
            return self.index
        out = REGISTER_NAMES[self.index]
        if self.offset is not None:
            out = '0x%x + %s' % (self.offset, out)
        if self.offset is not None or self.indirect:
            out = '[%s]' % out
        return out


class LiteralValue(BaseValue):
    def eval(self, cpu):
        return self.value
    def __repr__(self):
        return '0x%x' % self.value


class IndirectValue(BaseValue):
    def eval(self, cpu):
        return cpu.memory[self.value]
    def __repr__(self):
        return '[0x%x]' % self.value
    def save(self, cpu, value):
        cpu.memory[self.value] = value.eval(cpu)


class StackValue(BaseValue):
    def __repr__(self):
        if self.value < 0:
            return 'PUSH'
        if self.value > 0:
            return 'POP'
        return 'PEEK'
    def eval(self, cpu):
        if self.value < 0:
            cpu.SP = (cpu.SP - 1) % 0x10000
            return cpu.memory[cpu.SP]
        if self.value > 0:
            val = cpu.memory[cpu.SP]
            cpu.SP = (cpu.SP + 1) % 0x10000
            return val
        else:
            return cpu.memory[cpu.SP]
        
class DCPU16(object):
    
    def __init__(self):
        self.registers = [0] * 8
        self.PC = 0
        self.SP = 0
        self.O = 0
        self.memory = [0] * 0x10000
        self.skip = False
    
    def loads_hex(self, encoded, location=0):
        encoded = re.sub(r';.*$', '', encoded, 0, re.M) # strip comments
        encoded = re.sub(r'^.*:', '', encoded, 0, re.M) # strip addresses
        encoded = encoded.lower()
        encoded = re.sub(r'[^0-9a-f]', '', encoded) # strip non-hex
        for i in xrange(len(encoded) / 4):
            self.memory[location + i] = int(encoded[4 * i:4 * i + 4], 16)
    
    def dump(self):
        for i in xrange(0, 0x10000, 8):
            data = False
            for j in xrange(i, i + 8):
                if self.memory[j]:
                    data = True
                    break
            if data:
                print '; %04x:' % (i,),
                for j in xrange(i, i + 8):
                    print '%04x' % (self.memory[j],),
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
        basic, opcode, a, b = self.get_next_instruction()        
        end_PC = self.PC
        
        if basic:
            out = '%s %s, %s' % (BASIC_OPCODES[opcode], a, b)
        else:
            out = '%s %s' % (NONBASIC_OPCODES[opcode], a)
        dump = ' '.join('%04x' % x for x in self.memory[start_PC:end_PC])
        print '%-30s; %04x: %s' % (out, start_PC, dump)
    
    def get_next_instruction(self):
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
        
        return basic, opcode, a, b
    
    def run(self):
        counter = 0
        last_PC = -1
        while self.memory[self.PC] and last_PC != self.PC:
            last_PC = self.PC
            
            if counter % 16 == 0:
                if counter:
                    print
                print ';', ' '.join('%4s' % x for x in '# PC SP O A B C X Y Z I J'.split())
                print ';', '-----' * 12
            counter += 1
            print '; %4x' % (counter - 1,),
            print ' '.join('%4x' % getattr(self, x) for x in 'PC SP O'.split()),
            print ' '.join('%4x' % self.registers[x] for x in xrange(8))
            self._run_one()
    
    def _run_one(self):
        basic, opcode, a, b = self.get_next_instruction()
        if self.skip:
            self.skip = False
            return
        opcode_name = BASIC_OPCODES[opcode] if basic else NONBASIC_OPCODES[opcode]
        try:
            handler = getattr(self, 'do_%s' % opcode_name)
        except AttributeError:
            raise RuntimeError('no handler for %s' % opcode_name)
        handler(a, b)
    
    def do_SET(self, a, b):
        a.save(self, b)
    
    def do_SUB(self, a, b):
        aval = a.eval(self)
        bval = b.eval(self)
        self.O = 0xffff if bval > aval else 0
        a.save(self, LiteralValue((aval - bval) & 0xffff))
    
    def do_IFN(self, a, b):
        aval = a.eval(self)
        bval = b.eval(self)
        self.skip = aval == bval
    
    def do_AND(self, a, b):
        a.save(self, LiteralValue(a.eval(self) & b.eval(self)))
    def do_BOR(self, a, b):
        a.save(self, LiteralValue(a.eval(self) | b.eval(self)))
    def do_XOR(self, a, b):
        a.save(self, LiteralValue(a.eval(self) ^ b.eval(self)))

    def do_JSR(self, a, b):
        aval = a.eval(self)
        self.SP = (self.SP - 1) % 0x10000
        self.memory[self.SP] = self.PC
        self.PC = aval
    
    def do_SHL(self, a, b):
        aval = a.eval(self)
        bval = b.eval(self)
        self.O = ((aval << bval) >> 16 ) & 0xffff
        a.save(self, LiteralValue((aval << bval) & 0xffff))
    
    def do_SHR(self, a, b):
        aval = a.eval(self)
        bval = b.eval(self)
        self.O = ((aval << 16) >> bval) & 0xffff
        a.save(self, LiteralValue(aval >> bval))

        
    def get_next_word(self):
        word = self.memory[self.PC]
        self.PC += 1
        return word
    
    def get_op_value(self, value):
    
        # Registers.
        if value <= 0x07:
            return RegisterValue(value)
    
        # Indirect registers.
        if value <= 0x0f:
            return RegisterValue(value - 0x08, indirect=True)
    
        # Indirect register with offset.
        if value <= 0x17:
            return RegisterValue(value - 0x10, indirect=True, offset=self.get_next_word())
    
        if value == 0x18:
            return StackValue(1) # POP
        if value == 0x19:
            return StackValue(0) # PEEK
        if value == 0x1a:
            return StackValue(-1) # PUSH
        
        if value == 0x1b:
            return RegisterValue('SP')
        if value == 0x1c:
            return RegisterValue('PC')
        if value == 0x1d:
            return RegisterValue('O')
    
        if value == 0x1e:
            return IndirectValue(self.get_next_word())
        if value == 0x1f:
            return LiteralValue(self.get_next_word())
    
        if value >= 0x20 and value <= 0x3f:
            return LiteralValue(value - 0x20)
    
        raise ValueError('unknown value 0x%04x' % value)



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
    print
    
    cpu.run()
    print 
    
    cpu.dump()