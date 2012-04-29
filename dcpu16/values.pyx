include "macros.pyi"

from dcpu16.cpu cimport CPU


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
        
    def __init__(self, value=0):
        self.value = value % 0x10000
    
    cpdef unsigned short get(self, CPU cpu) except *:
        raise RuntimeError('cannot eval %r' % self)

    cpdef unsigned char set(self, CPU cpu, unsigned short value) except 1:
        raise TypeError('cannot save to %r' % self)
    
    def __repr__(self):
        return '<%s %r>' % (self.__class__.__name__, self.value)
    
    def asm(self):
        raise NotImplementedError(self.__class__.__name__)
    
    def hex(self):
        raise NotImplementedError(self.__class__.__name__)


cdef class Register(Base):
    
    cdef bint indirect
    cdef int offset
    cdef object label
    
    def __init__(self, unsigned short index, indirect=False, offset=0, label=None):
        self.value = index
        self.indirect = indirect
        self.offset = offset
        self.label = label
    
    cpdef unsigned short get(self, CPU cpu):
        if self.indirect or self.offset:
            loc = cpu.registers[self.value] + (self.offset or 0)
            return cpu.memory[loc]
        else:
            return cpu.registers[self.value]
    
    cpdef unsigned char set(self, CPU cpu, unsigned short value) except 1:
        if self.indirect or self.offset:
            loc = cpu.registers[self.value] + (self.offset or 0)
            cpu.memory[loc] = value
        else:
            cpu.registers[self.value] = value
    
    def asm(self):
        out = REGISTER_NAMES[self.value]
        if self.offset:
            out = '0x%x + %s' % (self.offset, out)
        if self.label:
            out = '%s + %s' % (self.label, out)
        if self.offset or self.label or self.indirect:
            out = '[%s]' % out
        return out
    
    def hex(self):
        if self.value >= 0x8:
            return self.value + 0x1b - 0x8, ()
        if self.label:
            return 0x10 + self.value, (Label(self.label, offset=self.offset),)
        if self.offset:
            return 0x10 + self.value, (self.offset, )
        if self.indirect:
            return 0x08 + self.value, ()
        return self.value, ()


cdef class Literal(Base):

    cpdef unsigned short get(self, CPU cpu):
        return self.value
    
    def asm(self):
        return '0x%x' % self.value
    
    cpdef unsigned char set(self, CPU cpu, unsigned short value):
        # Silent failure.
        pass
    
    
    def hex(self):
        if self.value <= 0x1e:
            return 0x21 + self.value, ()
        if self.value == 0xffff:
            return 0x20, ()
        return 0x1f, (self.value, )


cdef class Indirect(Base):

    cpdef unsigned short get(self, CPU cpu):
        return cpu.memory[self.value]
        
    def asm(self):
        return '[0x%x]' % self.value
        
    cpdef unsigned char set(self, CPU cpu, unsigned short value) except 1:
        cpu.memory[self.value] = value
    
    def hex(self):
        return 0x1e, (self.value, )


cdef class Label(Base):

    cdef public object label
    cdef public bint indirect
    cdef public unsigned short offset
    cdef public bint subtract
    
    def __init__(self, label, indirect=False, offset=0, subtract=False):
        self.label = label
        self.indirect = indirect
        self.offset = offset
        self.subtract = subtract
    
    def asm(self):
        out = self.label
        if self.offset:
            out = '0x%x + %s' % (self.offset, out)
        if self.indirect:
            out = '[%s]' % out
        return out
    
    def hex(self):
        if self.indirect:
            return 0x1e, (self, )
        else:
            return 0x1f, (self, )
    
    def __richcmp__(self, other, op):
        if op == 3:
            return not self.__richcmp__(other, 2)
        elif op == 2:
            if not isinstance(other, Label):
                return False
            return self.label == other.label and self.offset == other.offset
        else:
            return False


cdef class StackPush(Base):

    def asm(self):
        return 'PUSH'
    
    def hex(self):
        return 0x18, ()
    
    cpdef unsigned char set(self, CPU cpu, unsigned short value) except 1:
        cpu.registers[REG_SP] = (cpu.registers[REG_SP] - 1) % 0x10000
        cpu.memory[cpu.registers[REG_SP]] = value


cdef class StackPop(Base):
    
    def asm(self):
        return 'POP'
    
    def hex(self):
        return 0x18, ()
    
    cpdef unsigned short get(self, CPU cpu):
        val = cpu.memory[cpu.registers[REG_SP]]
        cpu.registers[REG_SP] = (cpu.registers[REG_SP] + 1) % 0x10000
        return val


cdef class StackPick(Base):

    def asm(self):
        if self.value:
            return 'PICK 0x%x' % self.value
        else:
            return 'PEEK'
    
    def hex(self):
        if self.value:
            return 0x1a, (self.value, )
        else:
            return 0x19, ()
    
    cpdef unsigned short get(self, CPU cpu):
        cdef unsigned short offset = (cpu.registers[REG_SP] + self.value) % 0x10000
        return cpu.memory[offset]
        
    cpdef unsigned char set(self, CPU cpu, unsigned short value) except 1:
        cdef unsigned short offset = (cpu.registers[REG_SP] + self.value) % 0x10000
        cpu.memory[offset] = value

