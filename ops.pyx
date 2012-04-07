cimport values
import values

from cpu cimport CPU


cdef class Base(object):
    
    cdef run(self, CPU cpu):
        raise NotImplementedError(self.__class__.__name__)


cdef class Basic(Base):

    def __init__(self, values.BaseValue a, values.BaseValue b):
        self.a = a
        self.b = b
    
    def __repr__(self):
        return '%s %r, %r' % (self.__class__.__name__, self.a, self.b)


cdef class NonBasic(Base):

    def __init__(self, values.BaseValue a):
        self.a = a
        
    def __repr__(self):
        return '%s %r' % (self.__class__.__name__, self.a)


cdef class SET(Basic):
    cdef run(self, CPU cpu):
        self.a.save(cpu, self.b)

cdef class ADD(Basic):
    pass

cdef class SUB(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.O = 0xffff if bval > aval else 0
        self.a.save(cpu, values.LiteralValue((aval - bval) & 0xffff))
    
cdef class MUL(Basic):
    pass
cdef class DIV(Basic):
    pass
cdef class MOD(Basic):
    pass
cdef class SHL(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.O = ((aval << bval) >> 16 ) & 0xffff
        self.a.save(cpu, values.LiteralValue((aval << bval) & 0xffff))    
cdef class SHR(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.O = ((aval << 16) >> bval) & 0xffff
        self.a.save(cpu, values.LiteralValue(aval >> bval))
cdef class AND(Basic):
    cdef run(self, CPU cpu):
        self.a.save(cpu, values.LiteralValue(self.a.eval(cpu) & self.b.eval(cpu)))
cdef class BOR(Basic):
    cdef run(self, CPU cpu):
        self.a.save(cpu, values.LiteralValue(self.a.eval(cpu) | self.b.eval(cpu)))
cdef class XOR(Basic):
    cdef run(self, CPU cpu):
        self.a.save(cpu, values.LiteralValue(self.a.eval(cpu) ^ self.b.eval(cpu)))
cdef class IFE(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip = aval != bval
cdef class IFN(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip = aval == bval
cdef class IFG(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip = aval <= bval
cdef class IFB(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip = not (aval & bval)
cdef class JSR(NonBasic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cpu.SP = cpu.SP - 1
        cpu.memory[cpu.SP] = cpu.PC
        cpu.PC = aval
    
