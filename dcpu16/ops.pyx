include "macros.pyi"

from dcpu16.cpu cimport CPU

cimport dcpu16.values as values
import dcpu16.values as values


cdef class Base(object):
    
    cdef run(self, CPU cpu):
        raise NotImplementedError(self.__class__.__name__)


cdef class Basic(Base):

    def __init__(self, values.Base dst, values.Base src):
        self.dst = dst
        self.src = src
    
    def __repr__(self):
        return '%s %r, %r' % (self.__class__.__name__, self.dst, self.src)
    
    def hex(self):
        opcode = basic_cls_to_hex[self.__class__]
        dst, dst_extra = self.dst.hex()
        src, src_extra = self.src.hex()
        # print self.__class__.__name__ + '.hex() ->', opcode, src, dst
        return (opcode + ((dst & 0x3f) << 5) + ((src & 0x3f) << 10) ,) + src_extra + dst_extra


cdef class NonBasic(Base):

    def __init__(self, values.Base val, other=None):
        self.val = val
        
    def __repr__(self):
        return '%s %r' % (self.__class__.__name__, self.val)
    
    def hex(self):
        opcode = nonbasic_cls_to_hex[self.__class__]
        val, val_extra = self.val.hex()
        return (((opcode & 0x3f) << 5) + ((val & 0x3f) << 10) ,) + val_extra


cdef class SET(Basic):
    cdef run(self, CPU cpu):
        self.dst.set(cpu, self.src.get(cpu))


cdef class ADD(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        cdef unsigned int out = dst + src
        self.dst.set(cpu, out & 0xffff)
        cpu.registers[REG_EX] = 1 if out > 0xffff else 0


cdef class SUB(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        self.dst.set(cpu, (dst - src) & 0xffff)
        cpu.registers[REG_EX] = 0xffff if src > dst else 0
    
    
cdef class MUL(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        cdef unsigned int out = dst * src
        self.dst.set(cpu, out & 0xffff)
        cpu.registers[REG_EX] = (out >> 16) & 0xffff
    
    
cdef class DIV(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        if not src:
            self.dst.set(cpu, 0)
            cpu.registers[REG_EX] = 0
        else:
            self.dst.set(cpu, dst / src)
            cpu.registers[REG_EX] = ((dst << 16) / src) & 0xffff
            
    
    
cdef class MOD(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        if not src:
            self.dst.set(cpu, 0)
        else:
            self.dst.set(cpu, dst % src)
    
    
cdef class SHL(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        cpu.registers[REG_EX] = ((dst << src) >> 16 ) & 0xffff
        self.dst.set(cpu, (dst << src) & 0xffff)
        
        
cdef class SHR(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        cpu.registers[REG_EX] = ((dst << 16) >> src) & 0xffff
        self.dst.set(cpu, dst >> src)
        
        
cdef class AND(Basic):
    cdef run(self, CPU cpu):
        self.dst.set(cpu, self.dst.get(cpu) & self.src.get(cpu))
        
        
cdef class BOR(Basic):
    cdef run(self, CPU cpu):
        self.dst.set(cpu, self.dst.get(cpu) | self.src.get(cpu))
        
        
cdef class XOR(Basic):
    cdef run(self, CPU cpu):
        self.dst.set(cpu, self.dst.get(cpu) ^ self.src.get(cpu))
        
        
cdef class IFE(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        cpu.skip_next = dst != src
        
        
cdef class IFN(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        cpu.skip_next = dst == src
        
        
cdef class IFG(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        cpu.skip_next = dst <= src
        
        
cdef class IFB(Basic):
    cdef run(self, CPU cpu):
        cdef unsigned short dst = self.dst.get(cpu)
        cdef unsigned short src = self.src.get(cpu)
        cpu.skip_next = not (dst & src)


cdef class JSR(NonBasic):
    cdef run(self, CPU cpu):
        cdef unsigned short val = self.val.get(cpu)
        cpu.registers[REG_SP] = cpu.registers[REG_SP] - 1
        cpu.memory[cpu.registers[REG_SP]] = cpu.registers[REG_PC]
        cpu.registers[REG_PC] = val



basic_code_to_cls = {
    0: None,
    OP_SET: SET,
    OP_ADD: ADD,
    OP_SUB: SUB,
    OP_MUL: MUL,
    OP_DIV: DIV,
    OP_MOD: MOD,
    OP_SHL: SHL,
    OP_SHR: SHR,
    OP_AND: AND,
    OP_BOR: BOR,
    OP_XOR: XOR,
    OP_IFE: IFE,
    OP_IFN: IFN,
    OP_IFG: IFG,
    OP_IFB: IFB
}

basic_name_to_cls = dict((cls.__name__, cls) for cls in basic_code_to_cls.itervalues() if cls)

basic_cls_to_hex = dict(reversed(x) for x in basic_code_to_cls.iteritems() if x[1])

nonbasic_code_to_cls = {
    0: None,
    OP_JSR: JSR
}

nonbasic_name_to_cls = dict((cls.__name__, cls) for cls in nonbasic_code_to_cls.itervalues() if cls)

nonbasic_cls_to_hex = dict(reversed(x) for x in nonbasic_code_to_cls.iteritems() if x[1])
