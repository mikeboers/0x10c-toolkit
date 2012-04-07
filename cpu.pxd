cdef class BaseValue(object):
    
    cdef object value
    
    cpdef eval(self, DCPU16 cpu)
    cpdef save(self, DCPU16 cpu, BaseValue value)

cdef class DCPU16(object):
    
    cdef unsigned short registers[8]
    cdef unsigned short PC
    cdef unsigned short SP
    cdef unsigned short O
    cdef unsigned short memory[0x10000]
    cdef bint skip

    cpdef run(self)
    cdef unsigned short get_next_word(self)
    cdef BaseValue get_op_value(self, unsigned short value)
    