from cpu cimport DCPU16


REGISTER_NAMES = 'ABCXYZIJ'




cdef class BaseValue(object):
        
    def __init__(self, value):
        self.value = value
    
    cpdef eval(self, DCPU16 cpu):
        raise RuntimeError('cannot eval %r' % self)

    cpdef save(self, DCPU16 cpu, BaseValue value):
        raise TypeError('cannot save to %r' % self)
    
    def __repr__(self):
        return '%s(%r)' % (self.__class__.__name__, self.value)


cdef class RegisterValue(BaseValue):
    
    cdef object index
    cdef object indirect
    cdef object offset
    
    def __init__(self, index, indirect=False, offset=None):
        self.index = index
        self.indirect = indirect
        self.offset = offset
    
    cpdef eval(self, DCPU16 cpu):
        if isinstance(self.index, basestring):
            return getattr(cpu, self.index)
        if self.indirect or self.offset:
            loc = cpu.registers[self.index] + (self.offset or 0)
            return cpu.memory[loc]
        else:
            return cpu.registers[self.index]
    
    cpdef save(self, DCPU16 cpu, BaseValue value):
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


cdef class LiteralValue(BaseValue):
    cpdef eval(self, DCPU16 cpu):
        return self.value
    def __repr__(self):
        return '0x%x' % self.value


cdef class IndirectValue(BaseValue):
    cpdef eval(self, DCPU16 cpu):
        return cpu.memory[self.value]
    def __repr__(self):
        return '[0x%x]' % self.value
    cpdef save(self, DCPU16 cpu, BaseValue value):
        cpu.memory[self.value] = value.eval(cpu)


cdef class StackValue(BaseValue):
    def __repr__(self):
        if self.value < 0:
            return 'PUSH'
        if self.value > 0:
            return 'POP'
        return 'PEEK'
    cpdef eval(self, DCPU16 cpu):
        if self.value < 0:
            cpu.SP = (cpu.SP - 1) % 0x10000
            return cpu.memory[cpu.SP]
        if self.value > 0:
            val = cpu.memory[cpu.SP]
            cpu.SP = (cpu.SP + 1) % 0x10000
            return val
        else:
            return cpu.memory[cpu.SP]