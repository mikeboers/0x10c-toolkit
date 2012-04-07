from cpu cimport CPU


REGISTER_NAMES = 'ABCXYZIJ'




cdef class Base(object):
        
    def __init__(self, value):
        self.value = value
    
    cpdef eval(self, CPU cpu):
        raise RuntimeError('cannot eval %r' % self)

    cpdef save(self, CPU cpu, Base value):
        raise TypeError('cannot save to %r' % self)
    
    def __repr__(self):
        return '%s(%r)' % (self.__class__.__name__, self.value)


cdef class RegisterValue(Base):
    
    cdef object index
    cdef object indirect
    cdef object offset
    
    def __init__(self, index, indirect=False, offset=None):
        self.index = index
        self.indirect = indirect
        self.offset = offset
    
    cpdef eval(self, CPU cpu):
        if isinstance(self.index, basestring):
            return getattr(cpu, self.index)
        if self.indirect or self.offset:
            loc = cpu.registers[self.index] + (self.offset or 0)
            return cpu.memory[loc]
        else:
            return cpu.registers[self.index]
    
    cpdef save(self, CPU cpu, Base value):
        if isinstance(self.index, basestring):
            if self.index == 'PC':
                cpu.PC = value.eval(cpu)
            elif self.index == 'SP':
                cpu.SP == value.eval(cpu)
            else:
                cpu.O == value.evap(cpu)
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


cdef class LiteralValue(Base):
    cpdef eval(self, CPU cpu):
        return self.value
    def __repr__(self):
        return '0x%x' % self.value


cdef class IndirectValue(Base):
    cpdef eval(self, CPU cpu):
        return cpu.memory[self.value]
    def __repr__(self):
        return '[0x%x]' % self.value
    cpdef save(self, CPU cpu, Base value):
        cpu.memory[self.value] = value.eval(cpu)


cdef class StackValue(Base):
    def __repr__(self):
        if self.value < 0:
            return 'PUSH'
        if self.value > 0:
            return 'POP'
        return 'PEEK'
    cpdef eval(self, CPU cpu):
        if self.value < 0:
            cpu.SP = (cpu.SP - 1) % 0x10000
            return cpu.memory[cpu.SP]
        if self.value > 0:
            val = cpu.memory[cpu.SP]
            cpu.SP = (cpu.SP + 1) % 0x10000
            return val
        else:
            return cpu.memory[cpu.SP]
