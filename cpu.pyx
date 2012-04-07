import re

cimport values
import values

cimport ops
import ops


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
        self.PC = 0
        self.SP = 0
        self.O = 0
        self.skip = False
        
    def loads_hex(self, encoded, location=0):
        encoded = re.sub(r';.*$', '', encoded, 0, re.M) # strip comments
        encoded = re.sub(r'^.*:', '', encoded, 0, re.M) # strip addresses
        encoded = encoded.lower()
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
        cdef unsigned short word = self.memory[self.PC]
        self.PC += 1
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
            return values.Stack(1) # POP
        if value == 0x19:
            return values.Stack(0) # PEEK
        if value == 0x1a:
            return values.Stack(-1) # PUSH
        
        if value == 0x1b:
            return values.Register('SP')
        if value == 0x1c:
            return values.Register('PC')
        if value == 0x1d:
            return values.Register('O')
    
        if value == 0x1e:
            return values.Indirect(self.get_next_word())
        if value == 0x1f:
            return values.Literal(self.get_next_word())
    
        if value >= 0x20 and value <= 0x3f:
            return values.Literal(value - 0x20)
    
        raise ValueError('unknown value 0x%04x' % value)
    
    def disassemble(self, location=None):
        old_PC = self.PC
        if location:
            self.PC = location
        self._disassemble()
        self.PC = old_PC
    
    def _disassemble(self):
        while self.memory[self.PC]:
            self._disassemble_one()
    
    def _disassemble_one(self):
        start_PC = self.PC
        cdef ops.Base op = self.get_next_instruction()        
        end_PC = self.PC
        dump = ' '.join('%04x' % x for x in self.memory[start_PC:end_PC])
        print '%-30r; %04x: %s' % (op, start_PC, dump)
    
    cdef ops.Base get_next_instruction(self):
        
        cdef unsigned short word = self.get_next_word()
        cdef unsigned short opcode = word & 0xf
        cdef unsigned short raw_a = (word >> 4) & 0x3f
        cdef unsigned short raw_b = (word >> 10) & 0x3f    
        
        cdef values.Base a, b
        if opcode:
            
            a = self.get_op_value(raw_a)
            b = self.get_op_value(raw_b)
            
            if opcode == 1:
                return OpSET(a, b)
            elif opcode == 2:
                return OpADD(a, b)
            elif opcode == 3:
                return OpSUB(a, b)
            elif opcode == 4:
                return OpMUL(a, b)
            elif opcode == 5:
                return OpDIV(a, b)
            elif opcode == 6:
                return OpMOD(a, b)
            elif opcode == 7:
                return OpSHL(a, b)
            elif opcode == 8:
                return OpSHR(a, b)
            elif opcode == 9:
                return OpAND(a, b)
            elif opcode == 0xa:
                return OpBOR(a, b)
            elif opcode == 0xb:
                return OpXOR(a, b)
            elif opcode == 0xc:
                return OpIFE(a, b)
            elif opcode == 0xd:
                return OpIFN(a, b)
            elif opcode == 0xe:
                return OpIFG(a, b)
            elif opcode == 0xf:
                return OpIFB(a, b)
            
        else:
            a = self.get_op_value(raw_b)
            if raw_a == 1:
                return OpJSR(a)

        raise ValueError('unknown operation %r, %r, %r' % (opcode, raw_a, raw_b))
            
            
        
    cpdef run(self):
        cdef bint debug = False
        cdef unsigned long counter = 0
        cdef int last_PC = -1
        while self.memory[self.PC] and last_PC != self.PC:
            last_PC = self.PC
            if debug:
                if counter % 16 == 0:
                    if counter:
                        print
                    print ';', ' '.join(['%4s' % x for x in '# PC SP O A B C X Y Z I J'.split()])
                    print ';', '-----' * 12
            counter += 1
            if debug:
                print '; %4x' % (counter - 1,),
                print ' '.join(['%4x' % x for x in [self.PC, self.SP, self.O]]),
                print ' '.join(['%4x' % self.registers[x] for x in xrange(8)])
            self._run_one()
        return counter
    
    cpdef _run_one(self):
        cdef ops.Base op = self.get_next_instruction()
        if self.skip:
            self.skip = False
            return
        op.run(self)
        
    
    
    

    
    
    
    
        
