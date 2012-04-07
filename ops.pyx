cimport values
import values

from cpu cimport DCPU16


cdef class BasicOperation(object):
    
    def __init__(self, values.BaseValue a, values.BaseValue b):
        self.a = a
        self.b = b
    
    cdef run(self, DCPU16 cpu):
        raise NotImplementedError(self.__class__.__name__)
    
    def __repr__(self):
        return '%s %r, %r' % (self.__class__.__name__[-3:], self.a, self.b)


cdef class NonBasicOperation(BasicOperation):

    def __init__(self, values.BaseValue a):
        self.a = a
        
    def __repr__(self):
        return '%s %r' % (self.__class__.__name__[-3:], self.a)


cdef class OpSET(BasicOperation):
    cdef run(self, DCPU16 cpu):
        self.a.save(cpu, self.b)

cdef class OpADD(BasicOperation):
    pass

cdef class OpSUB(BasicOperation):
    cdef run(self, DCPU16 cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.O = 0xffff if bval > aval else 0
        self.a.save(cpu, values.LiteralValue((aval - bval) & 0xffff))
    
cdef class OpMUL(BasicOperation):
    pass
cdef class OpDIV(BasicOperation):
    pass
cdef class OpMOD(BasicOperation):
    pass
cdef class OpSHL(BasicOperation):
    cdef run(self, DCPU16 cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.O = ((aval << bval) >> 16 ) & 0xffff
        self.a.save(cpu, values.LiteralValue((aval << bval) & 0xffff))    
cdef class OpSHR(BasicOperation):
    cdef run(self, DCPU16 cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.O = ((aval << 16) >> bval) & 0xffff
        self.a.save(cpu, values.LiteralValue(aval >> bval))
cdef class OpAND(BasicOperation):
    cdef run(self, DCPU16 cpu):
        self.a.save(cpu, values.LiteralValue(self.a.eval(cpu) & self.b.eval(cpu)))
cdef class OpBOR(BasicOperation):
    cdef run(self, DCPU16 cpu):
        self.a.save(cpu, values.LiteralValue(self.a.eval(cpu) | self.b.eval(cpu)))
cdef class OpXOR(BasicOperation):
    cdef run(self, DCPU16 cpu):
        self.a.save(cpu, values.LiteralValue(self.a.eval(cpu) ^ self.b.eval(cpu)))
cdef class OpIFE(BasicOperation):
    cdef run(self, DCPU16 cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip = aval != bval
cdef class OpIFN(BasicOperation):
    cdef run(self, DCPU16 cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip = aval == bval
cdef class OpIFG(BasicOperation):
    cdef run(self, DCPU16 cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip = aval <= bval
cdef class OpIFB(BasicOperation):
    cdef run(self, DCPU16 cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip = not (aval & bval)
cdef class OpJSR(NonBasicOperation):
    cdef run(self, DCPU16 cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cpu.SP = cpu.SP - 1
        cpu.memory[cpu.SP] = cpu.PC
        cpu.PC = aval
    
