import re

cimport values
import values

cimport ops
import ops











cdef class DCPU16(object):
    
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
    
    cdef values.BaseValue get_op_value(self, unsigned short value):
    
        # Registers.
        if value <= 0x07:
            return values.RegisterValue(value)
    
        # Indirect registers.
        if value <= 0x0f:
            return values.RegisterValue(value - 0x08, indirect=True)
    
        # Indirect register with offset.
        if value <= 0x17:
            return values.RegisterValue(value - 0x10, indirect=True, offset=self.get_next_word())
    
        if value == 0x18:
            return values.StackValue(1) # POP
        if value == 0x19:
            return values.StackValue(0) # PEEK
        if value == 0x1a:
            return values.StackValue(-1) # PUSH
        
        if value == 0x1b:
            return values.RegisterValue('SP')
        if value == 0x1c:
            return values.RegisterValue('PC')
        if value == 0x1d:
            return values.RegisterValue('O')
    
        if value == 0x1e:
            return values.IndirectValue(self.get_next_word())
        if value == 0x1f:
            return values.LiteralValue(self.get_next_word())
    
        if value >= 0x20 and value <= 0x3f:
            return values.LiteralValue(value - 0x20)
    
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
        cdef ops.BasicOperation op = self.get_next_instruction()        
        end_PC = self.PC
        dump = ' '.join('%04x' % x for x in self.memory[start_PC:end_PC])
        print '%-30r; %04x: %s' % (op, start_PC, dump)
    
    cdef ops.BasicOperation get_next_instruction(self):
        
        cdef unsigned short word = self.get_next_word()
        cdef unsigned short opcode = word & 0xf
        cdef unsigned short raw_a = (word >> 4) & 0x3f
        cdef unsigned short raw_b = (word >> 10) & 0x3f    
        
        cdef values.BaseValue a, b
        if opcode:
            
            a = self.get_op_value(raw_a)
            b = self.get_op_value(raw_b)
            
            if opcode == 1:
                return ops.OpSET(a, b)
            elif opcode == 2:
                return ops.OpADD(a, b)
            elif opcode == 3:
                return ops.OpSUB(a, b)
            elif opcode == 4:
                return ops.OpMUL(a, b)
            elif opcode == 5:
                return ops.OpDIV(a, b)
            elif opcode == 6:
                return ops.OpMOD(a, b)
            elif opcode == 7:
                return ops.OpSHL(a, b)
            elif opcode == 8:
                return ops.OpSHR(a, b)
            elif opcode == 9:
                return ops.OpAND(a, b)
            elif opcode == 0xa:
                return ops.OpBOR(a, b)
            elif opcode == 0xb:
                return ops.OpXOR(a, b)
            elif opcode == 0xc:
                return ops.OpIFE(a, b)
            elif opcode == 0xd:
                return ops.OpIFN(a, b)
            elif opcode == 0xe:
                return ops.OpIFG(a, b)
            elif opcode == 0xf:
                return ops.OpIFB(a, b)
            
        else:
            a = self.get_op_value(raw_b)
            if raw_a == 1:
                return ops.OpJSR(a)

        raise ValueError('unknown operation %r, %r, %r' % (opcode, raw_a, raw_b))
            
            
        
    cpdef run(self):
        cdef bint debug = True
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
        cdef ops.BasicOperation op = self.get_next_instruction()
        if self.skip:
            self.skip = False
            return
        op.run(self)
        
    
    
    

    
    
    
    
        
