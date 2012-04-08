cimport values
import values

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
        self.a.save(cpu, self.b.eval(cpu))


cdef class ADD(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cdef unsigned int sum = aval + bval
        cpu.registers[REG_O] = 1 if sum > 0xffff else 0
        self.a.save(cpu, sum & 0xffff)


cdef class SUB(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.registers[REG_O] = 0xffff if bval > aval else 0
        self.a.save(cpu, (aval - bval) & 0xffff)
    
    
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
        cpu.registers[REG_O] = ((aval << bval) >> 16 ) & 0xffff
        self.a.save(cpu, (aval << bval) & 0xffff)
        
        
cdef class SHR(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.registers[REG_O] = ((aval << 16) >> bval) & 0xffff
        self.a.save(cpu, aval >> bval)
        
        
cdef class AND(Basic):
    cdef run(self, CPU cpu):
        self.a.save(cpu, self.a.eval(cpu) & self.b.eval(cpu))
        
        
cdef class BOR(Basic):
    cdef run(self, CPU cpu):
        self.a.save(cpu, self.a.eval(cpu) | self.b.eval(cpu))
        
        
cdef class XOR(Basic):
    cdef run(self, CPU cpu):
        self.a.save(cpu, self.a.eval(cpu) ^ self.b.eval(cpu))
        
        
cdef class IFE(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip_next = aval != bval
        
        
cdef class IFN(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip_next = aval == bval
        
        
cdef class IFG(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip_next = aval <= bval
        
        
cdef class IFB(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cdef unsigned short bval = self.b.eval(cpu)
        cpu.skip_next = not (aval & bval)


cdef class JSR(NonBasic):
    cdef run(self, CPU cpu):
        cdef unsigned short aval = self.a.eval(cpu)
        cpu.registers[REG_SP] = cpu.registers[REG_SP] - 1
        cpu.memory[cpu.registers[REG_SP]] = cpu.registers[REG_PC]
        cpu.registers[REG_PC] = aval



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
