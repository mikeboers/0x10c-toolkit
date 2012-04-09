include "macros.pyi"

cimport values
import values

from cpu cimport CPU


cdef class Base(object):
    
    cdef run(self, CPU cpu):
        raise NotImplementedError(self.__class__.__name__)


cdef class Basic(Base):

    def __init__(self, values.Base a, values.Base b):
        self.a = a
        self.b = b
    
    def __repr__(self):
        return '%s %r, %r' % (self.__class__.__name__, self.a, self.b)
    
    def to_code(self):
        opcode = basic_cls_to_code[self.__class__]
        a, a_extra = self.a.to_code()
        b, b_extra = self.b.to_code()
        # print self.__class__.__name__ + '.to_code() ->', opcode, a, b
        return (opcode + ((a & 0x3f) << 4) + ((b & 0x3f) << 10) ,) + a_extra + b_extra


cdef class NonBasic(Base):

    def __init__(self, values.Base a, b=None):
        self.a = a
        
    def __repr__(self):
        return '%s %r' % (self.__class__.__name__, self.a)
    
    def to_code(self):
        opcode = nonbasic_cls_to_code[self.__class__]
        a, a_extra = self.a.to_code()
        return (((opcode & 0x3f) << 4) + ((a & 0x3f) << 10) ,) + a_extra
        


cdef class SET(Basic):
    
    cdef run(self, CPU cpu):
        self.a.set(cpu, self.b.get(cpu))


cdef class ADD(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        cdef unsigned int out = a + b
        self.a.set(cpu, out & 0xffff)
        cpu.registers[REG_O] = 1 if out > 0xffff else 0


cdef class SUB(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        self.a.set(cpu, (a - b) & 0xffff)
        cpu.registers[REG_O] = 0xffff if b > a else 0
    
    
cdef class MUL(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        cdef unsigned int out = a * b
        self.a.set(cpu, out & 0xffff)
        cpu.registers[REG_O] = (out >> 16) & 0xffff
    
    
cdef class DIV(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        if not b:
            self.a.set(cpu, 0)
            cpu.registers[REG_O] = 0
        else:
            self.a.set(cpu, a / b)
            cpu.registers[REG_O] = ((a << 16) / b) & 0xffff
            
    
    
cdef class MOD(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        if not b:
            self.a.set(cpu, 0)
        else:
            self.a.set(cpu, a % b)
    
    
cdef class SHL(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        cpu.registers[REG_O] = ((a << b) >> 16 ) & 0xffff
        self.a.set(cpu, (a << b) & 0xffff)
        
        
cdef class SHR(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        cpu.registers[REG_O] = ((a << 16) >> b) & 0xffff
        self.a.set(cpu, a >> b)
        
        
cdef class AND(Basic):
    cdef run(self, CPU cpu):
        self.a.set(cpu, self.a.get(cpu) & self.b.get(cpu))
        
        
cdef class BOR(Basic):
    cdef run(self, CPU cpu):
        self.a.set(cpu, self.a.get(cpu) | self.b.get(cpu))
        
        
cdef class XOR(Basic):
    cdef run(self, CPU cpu):
        self.a.set(cpu, self.a.get(cpu) ^ self.b.get(cpu))
        
        
cdef class IFE(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        cpu.skip_next = a != b
        
        
cdef class IFN(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        cpu.skip_next = a == b
        
        
cdef class IFG(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        cpu.skip_next = a <= b
        
        
cdef class IFB(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cdef unsigned short b = self.b.get(cpu)
        cpu.skip_next = not (a & b)


cdef class JSR(NonBasic):
    cdef run(self, CPU cpu):
        cdef unsigned short a = self.a.get(cpu)
        cpu.registers[REG_SP] = cpu.registers[REG_SP] - 1
        cpu.memory[cpu.registers[REG_SP]] = cpu.registers[REG_PC]
        cpu.registers[REG_PC] = a



basic_code_to_cls = dict(enumerate([
    None, SET, ADD, SUB, MUL, DIV, MOD, SHL, SHR, AND, BOR, XOR, IFE, IFN, IFG, IFB
]))

basic_name_to_cls = dict((cls.__name__, cls) for cls in basic_code_to_cls.itervalues() if cls)

basic_cls_to_code = dict(reversed(x) for x in basic_code_to_cls.iteritems() if x[1])

nonbasic_code_to_cls = dict(enumerate([
    None, JSR
]))

nonbasic_name_to_cls = dict((cls.__name__, cls) for cls in nonbasic_code_to_cls.itervalues() if cls)

nonbasic_cls_to_code = dict(reversed(x) for x in nonbasic_code_to_cls.iteritems() if x[1])
