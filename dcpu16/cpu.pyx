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

cdef object RegisterValue = values.Register
cdef object LiteralValue = values.Literal
cdef object IndirectValue = values.Indirect
cdef object PushValue = values.StackPush
cdef object PopValue = values.StackPop
cdef object PickValue = values.StackPick








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
    
    cdef values.Base get_op_value(self, unsigned short value, bint is_dst):
    
        # Registers.
        if value <= 0x07:
            return RegisterValue(value)
    
        # Indirect registers.
        if value <= 0x0f:
            return RegisterValue(value - 0x08, indirect=True)
    
        # Indirect register with offset.
        if value <= 0x17:
            return RegisterValue(value - 0x10, indirect=True, offset=self.get_next_word())
    
        if value == 0x18:
            if is_dst:
                return PushValue()
            else:
                return PopValue()
        if value == 0x19:
            return PickValue(0)
        if value == 0x1a:
            return PickValue(self.get_next_word())
        
        if value == 0x1b:
            return RegisterValue(REG_SP)
        if value == 0x1c:
            return RegisterValue(REG_PC)
        if value == 0x1d:
            return RegisterValue(REG_EX)
    
        if value == 0x1e:
            return IndirectValue(self.get_next_word())
        if value == 0x1f:
            return LiteralValue(self.get_next_word())
    
        if value >= 0x20 and value <= 0x3f:
            return LiteralValue(value - 0x21) # Range from -1 to 30.
    
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
        print '%-30r; %04x: %s' % (op.asm(), start_PC, dump)
    
    cdef ops.Base get_next_instruction(self):
        
        cdef unsigned short word = self.get_next_word()
        cdef unsigned short opcode = word & 0x1f
        cdef unsigned short raw_b = (word >> 5) & 0x1f
        cdef unsigned short raw_a = (word >> 10) & 0x3f    
        
        cdef values.Base dst, src, val
        if opcode:
            
            src = self.get_op_value(raw_a, False)
            dst = self.get_op_value(raw_b, True)
            
            if opcode == OP_SET:
                return OpSET(dst, src)
            elif opcode == OP_ADD:
                return OpADD(dst, src)
            elif opcode == OP_SUB:
                return OpSUB(dst, src)
            elif opcode == OP_MUL:
                return OpMUL(dst, src)
            # MLI
            elif opcode == OP_DIV:
                return OpDIV(dst, src)
            # DVI
            elif opcode == OP_MOD:
                return OpMOD(dst, src)
            # MDI
            elif opcode == OP_AND:
                return OpAND(dst, src)
            elif opcode == OP_BOR:
                return OpBOR(dst, src)
            elif opcode == OP_XOR:
                return OpXOR(dst, src)

            elif opcode == OP_SHR:
                return OpSHR(dst, src)
            # ASR
            elif opcode == OP_SHL:
                return OpSHL(dst, src)
            
            elif opcode == OP_IFB:
                return OpIFB(dst, src)
            # IFC
            elif opcode == OP_IFE:
                return OpIFE(dst, src)
            elif opcode == OP_IFN:
                return OpIFN(dst, src)
            elif opcode == OP_IFG:
                return OpIFG(dst, src)
            # IFA
            # IFL
            # IFU
            
            # ADX
            # SBX
            
            # STI
            # STD
            
            
        else:
            val = self.get_op_value(raw_a, False)
            if raw_b == OP_JSR:
                return OpJSR(val)

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
        
        
    
    
    

    
    
    
    
        
