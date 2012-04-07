from values cimport BaseValue
from ops cimport BasicOperation




cdef class DCPU16(object):
    
    cdef unsigned short registers[8]
    cdef unsigned short PC
    cdef unsigned short SP
    cdef unsigned short O
    cdef unsigned short memory[0x10000]
    cdef bint skip

    cpdef run(self)
    cpdef _run_one(self)
    cdef unsigned short get_next_word(self)
    cdef BasicOperation get_next_instruction(self)
    cdef BaseValue get_op_value(self, unsigned short value)
    