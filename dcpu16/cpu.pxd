cimport dcpu16.values as values
cimport dcpu16.ops as ops



cdef class CPU(object):
    
    # The 8 general registers, then SP, PC, and EX.
    cdef unsigned short registers[11]
    cdef unsigned short memory[0x10000]
    
    cdef bint skip_next

    cpdef run_one(self)
    cdef unsigned short get_next_word(self)
    cdef ops.Base get_next_instruction(self)
    cdef values.Base get_op_value(self, unsigned short value, bint is_dst)
    