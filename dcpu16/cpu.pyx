include "macros.pyi"

import re

cimport dcpu16.values as values
import dcpu16.values as values

cimport dcpu16.ops as ops
import dcpu16.ops as ops


# Early binding for speed.
cdef object OpSET = ops.SET
cdef object OpADD = ops.ADD
cdef object OpSUB = ops.SUB
cdef object OpMUL = ops.MUL
cdef object OpDIV = ops.DIV
cdef object OpMOD = ops.MOD
cdef object OpSHL = ops.SHL
cdef object OpSHR = ops.SHR
cdef object OpAND = ops.AND
cdef object OpBOR = ops.BOR
cdef object OpXOR = ops.XOR
cdef object OpIFE = ops.IFE
cdef object OpIFN = ops.IFN
cdef object OpIFG = ops.IFG
cdef object OpIFB = ops.IFB
cdef object OpJSR = ops.JSR









cdef class CPU(object):
    
    def __init__(self):
        self.skip_next = False
    
    def load(self, encoded, location=0):
        if not isinstance(encoded, basestring):
            encoded = ''.join(encoded)
        encoded = re.sub(r'[#;].*$', '', encoded, 0, re.M) # strip comments
        encoded = re.sub(r'^.*:', '', encoded, 0, re.M) # strip addresses
        encoded = re.sub(r'[^0-9a-f]', '', encoded) # strip non-hex
        for i in xrange(len(encoded) / 4):
            self.memory[location + i] = int(encoded[4 * i:4 * i + 4], 16)
    
    def dump(self):
        for i in xrange(0, 0x10000, 8):
            data = False
            for j in xrange(i, i + 8):
                if self.memory[j]:
                    data = True
                    break
            if data:
                print '; %04x:' % (i,),
                for j in xrange(i, i + 8):
                    print '%04x' % (self.memory[j],),
                print
    
    cdef unsigned short get_next_word(self):
        cdef unsigned short PC = self.registers[REG_PC]
        cdef unsigned short word = self.memory[PC]
        self.registers[REG_PC] = PC + 1
        return word
    
    cdef values.Base get_op_value(self, unsigned short value):
    
        # Registers.
        if value <= 0x07:
            return values.Register(value)
    
        # Indirect registers.
        if value <= 0x0f:
            return values.Register(value - 0x08, indirect=True)
    
        # Indirect register with offset.
        if value <= 0x17:
            return values.Register(value - 0x10, indirect=True, offset=self.get_next_word())
    
        if value == 0x18:
            return values.Stack(STACK_POP)
        if value == 0x19:
            return values.Stack(STACK_PEEK)
        if value == 0x1a:
            return values.Stack(STACK_PUSH)
        
        if value == 0x1b:
            return values.Register(REG_SP)
        if value == 0x1c:
            return values.Register(REG_PC)
        if value == 0x1d:
            return values.Register(REG_EX)
    
        if value == 0x1e:
            return values.Indirect(self.get_next_word())
        if value == 0x1f:
            return values.Literal(self.get_next_word())
    
        if value >= 0x20 and value <= 0x3f:
            return values.Literal(value - 0x20)
    
        raise ValueError('unknown value 0x%04x' % value)
    
    def disassemble(self, location=None):
        old_PC = self.registers[REG_PC]
        if location:
            self.registers[REG_PC] = location
        self._disassemble()
        self.registers[REG_PC] = old_PC
    
    def _disassemble(self):
        while self.memory[self.registers[REG_PC]]:
            self._disassemble_one()
    
    def _disassemble_one(self):
        start_PC = self.registers[REG_PC]
        cdef ops.Base op = self.get_next_instruction()        
        end_PC = self.registers[REG_PC]
        dump = ' '.join('%04x' % x for x in self.memory[start_PC:end_PC])
        print '%-30r; %04x: %s' % (op, start_PC, dump)
    
    cdef ops.Base get_next_instruction(self):
        
        cdef unsigned short word = self.get_next_word()
        cdef unsigned short opcode = word & 0x1f
        cdef unsigned short raw_b = (word >> 5) & 0x1f
        cdef unsigned short raw_a = (word >> 10) & 0x3f    
        
        cdef values.Base a, b
        if opcode:
            
            a = self.get_op_value(raw_a)
            b = self.get_op_value(raw_b)
            
            if opcode == 1:
                return OpSET(b, a)
            elif opcode == 2:
                return OpADD(b, a)
            elif opcode == 3:
                return OpSUB(b, a)
            elif opcode == 4:
                return OpMUL(b, a)
            elif opcode == 5:
                return OpDIV(b, a)
            elif opcode == 6:
                return OpMOD(b, a)
            elif opcode == 7:
                return OpSHL(b, a)
            elif opcode == 8:
                return OpSHR(b, a)
            elif opcode == 9:
                return OpAND(b, a)
            elif opcode == 0xa:
                return OpBOR(b, a)
            elif opcode == 0xb:
                return OpXOR(b, a)
            elif opcode == 0xc:
                return OpIFE(b, a)
            elif opcode == 0xd:
                return OpIFN(b, a)
            elif opcode == 0xe:
                return OpIFG(b, a)
            elif opcode == 0xf:
                return OpIFB(b, a)
            
        else:
            a = self.get_op_value(raw_a)
            if raw_b == 1:
                return OpJSR(a)

        raise ValueError('unknown operation %r, %r, %r' % (opcode, raw_b, raw_a))
            
            
        
    def run(self, bint debug=False):
        cdef unsigned long counter = 0
        cdef int last_PC = -1
        while self.memory[self.registers[REG_PC]] and last_PC != self.registers[REG_PC]:
            last_PC = self.registers[REG_PC]
            if debug:
                if counter % 16 == 0:
                    if counter:
                        print
                    print ';', ' '.join(['%4s' % x for x in '# PC SP EX A B C X Y Z I J'.split()])
                    print ';', '-----' * 12
            counter += 1
            if debug:
                print '; %4x' % (counter - 1,),
                print ' '.join(['%4x' % x for x in [self.registers[REG_PC], self.registers[REG_SP], self.registers[REG_EX]]]),
                print ' '.join(['%4x' % self.registers[x] for x in xrange(8)])
            self.run_one()
        return counter
    
    cpdef run_one(self):
        cdef ops.Base op = self.get_next_instruction()
        if self.skip_next:
            self.skip_next = False
            return False
        op.run(self)
        return True
    
    def __getitem__(self, name):
        registers = 'A B C X Y Z I J SP PC EX'.split()
        if name in registers:
            return self.registers[registers.index(name)]
        return self.memory[name]
    
    def __setitem__(self, name, value):
        registers = 'A B C X Y Z I J SP PC EX'.split()
        if name in registers:
            self.registers[registers.index(name)] = value
        self.memory[name] = value
        
        
    
    
    

    
    
    
    
        
