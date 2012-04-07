from cpu cimport CPU


cdef class BaseValue(object):
    
    cdef object value
    
    cpdef eval(self, CPU cpu)
    cpdef save(self, CPU cpu, BaseValue value)
