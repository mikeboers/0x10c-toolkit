from cpu cimport CPU


REGISTER_NAMES = 'ABCXYZIJ'


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
    
    cdef object index
    cdef bint indirect
    cdef int offset
    
    def __init__(self, index, indirect=False, offset=0):
        self.index = index
        self.indirect = indirect
        self.offset = offset
    
    cdef unsigned short eval(self, CPU cpu):
        if isinstance(self.index, basestring):
            return getattr(cpu, self.index)
        if self.indirect or self.offset:
            loc = cpu.registers[self.index] + (self.offset or 0)
            return cpu.memory[loc]
        else:
            return cpu.registers[self.index]
    
    cdef void save(self, CPU cpu, unsigned short value):
        if isinstance(self.index, basestring):
            if self.index == 'PC':
                cpu.PC = value
            elif self.index == 'SP':
                cpu.SP == value
            else:
                cpu.O == value
        else:
            if self.indirect or self.offset:
                loc = cpu.registers[self.index] + (self.offset or 0)
                cpu.memory[loc] = value
            else:
                cpu.registers[self.index] = value
    
    def __repr__(self):
        if isinstance(self.index, basestring):
            return self.index
        out = REGISTER_NAMES[self.index]
        if self.offset:
            out = '0x%x + %s' % (self.offset, out)
        if self.offset or self.indirect:
            out = '[%s]' % out
        return out
    
    def to_code(self):
        if isinstance(self.index, basestring):
            return dict(PC=0x1c, SP=0x1b, O=0x1d)[self.index], ()
        
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
            cpu.SP = (cpu.SP - 1) % 0x10000
            return cpu.memory[cpu.SP]
        if self.value > 0:
            val = cpu.memory[cpu.SP]
            cpu.SP = (cpu.SP + 1) % 0x10000
            return val
        else:
            return cpu.memory[cpu.SP]
    
    def to_code(self):
        if self.value < 0:
            return 0x1a, ()
        if self.value > 0:
            return 0x18, ()
        return 0x19, ()
