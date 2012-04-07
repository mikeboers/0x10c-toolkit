cimport values
cimport ops



cdef class CPU(object):
    
    cdef unsigned short registers[8]
    cdef unsigned short PC
    cdef unsigned short SP
    cdef unsigned short O
    cdef unsigned short memory[0x10000]
    cdef bint skip

    cpdef run(self)
    cpdef _run_one(self)
    cdef unsigned short get_next_word(self)
    cdef ops.Base get_next_instruction(self)
    cdef values.Base get_op_value(self, unsigned short value)
    