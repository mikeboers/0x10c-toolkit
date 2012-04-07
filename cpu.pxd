from values cimport BaseValue


cdef class BasicOperation(object):

        cdef BaseValue a
        cdef BaseValue b
    
        cdef run(self, DCPU16 cpu)


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
    