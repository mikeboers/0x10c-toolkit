from cpu cimport CPU

DEF REG_A  = 0x0
DEF REG_B  = 0x1
DEF REG_C  = 0x2
DEF REG_X  = 0x3
DEF REG_Y  = 0x4
DEF REG_Z  = 0x5
DEF REG_I  = 0x6
DEF REG_J  = 0x7
DEF REG_SP = 0x8
DEF REG_PC = 0x9
DEF REG_O  = 0xA

REGISTER_NAMES = '''
    A
    B
    C
    X
    Y
    Z
    I
    J
    SP
    PC
    O
'''.strip().split()


cdef class Base(object):
        
    def __init__(self, value):
        self.value = value
    
    cdef unsigned short eval(self, CPU cpu) except *:
        raise RuntimeError('cannot eval %r' % self)

    cdef void save(self, CPU cpu, unsigned short value) except *:
        raise TypeError('cannot save to %r' % self)
    
    def __repr__(self):
        return '%s(%r)' % (self.__class__.__name__, self.value)
    
    def to_code(self):
        raise NotImplementedError(self.__class__.__name__)


cdef class Register(Base):
    
    cdef bint indirect
    cdef int offset
    
    def __init__(self, unsigned short index, indirect=False, offset=0):
        self.value = index
        self.indirect = indirect
        self.offset = offset
    
    cdef unsigned short eval(self, CPU cpu):
        if self.indirect or self.offset:
            loc = cpu.registers[self.value] + (self.offset or 0)
            return cpu.memory[loc]
        else:
            return cpu.registers[self.value]
    
    cdef void save(self, CPU cpu, unsigned short value):
        if self.indirect or self.offset:
            loc = cpu.registers[self.value] + (self.offset or 0)
            cpu.memory[loc] = value
        else:
            cpu.registers[self.value] = value
    
    def __repr__(self):
        out = REGISTER_NAMES[self.value]
        if self.offset:
            out = '0x%x + %s' % (self.offset, out)
        if self.offset or self.indirect:
            out = '[%s]' % out
        return out
    
    def to_code(self):
        if self.value >= 0x8:
            return self.value + 0x1b - 0x8, ()
        if self.offset:
            return 0x10 + self.index, (self.offset, )
        if self.indirect:
            return 0x08 + self.index, ()
        return self.index, ()


cdef class Literal(Base):

    cdef unsigned short eval(self, CPU cpu):
        return self.value
    
    def __repr__(self):
        return '0x%x' % self.value
    
    def to_code(self):
        if self.value <= 0x1f:
            return 0x20 + self.value, ()
        return 0x1f, (self.value, )


cdef class Indirect(Base):

    cdef unsigned short eval(self, CPU cpu):
        return cpu.memory[self.value]
        
    def __repr__(self):
        return '[0x%x]' % self.value
        
    cdef void save(self, CPU cpu, unsigned short value):
        cpu.memory[self.value] = value
    
    def to_code(self):
        return 0x1e, (self.value, )


cdef class Label(Base):

    cdef public object label
    cdef public bint indirect
    cdef public unsigned short offset
    
    def __init__(self, label, indirect=False, offset=0):
        self.label = label
        self.indirect = indirect
        self.offset = 0
        self.value = 0
    
    def __repr__(self):
        out = self.label
        if self.offset:
            out = '0x%x + %s' % (self.offset, out)
        if self.indirect:
            out = '[%s]' % out
        return out
    
    def to_code(self):
        if self.indirect:
            return 0x1e, (self.label, )
        else:
            return 0x1f, (self.label, )


cdef class Stack(Base):

    def __repr__(self):
        if self.value < 0:
            return 'PUSH'
        if self.value > 0:
            return 'POP'
        return 'PEEK'
    
    cdef unsigned short eval(self, CPU cpu):
        if self.value < 0:
            cpu.registers[REG_SP] = (cpu.registers[REG_SP] - 1) % 0x10000
            return cpu.memory[cpu.registers[REG_SP]]
        if self.value > 0:
            val = cpu.memory[cpu.registers[REG_SP]]
            cpu.registers[REG_SP] = (cpu.registers[REG_SP] + 1) % 0x10000
            return val
        else:
            return cpu.memory[cpu.registers[REG_SP]]
    
    def to_code(self):
        if self.value < 0:
            return 0x1a, ()
        if self.value > 0:
            return 0x18, ()
        return 0x19, ()
