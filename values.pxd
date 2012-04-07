from cpu cimport CPU


cdef class Base(object):
    
    cdef object value
    
    cpdef eval(self, CPU cpu)
    cpdef save(self, CPU cpu, Base value)
