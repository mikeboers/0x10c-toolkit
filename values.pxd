from cpu cimport DCPU16


cdef class BaseValue(object):
    
    cdef object value
    
    cpdef eval(self, DCPU16 cpu)
    cpdef save(self, DCPU16 cpu, BaseValue value)
