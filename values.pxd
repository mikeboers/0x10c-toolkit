from cpu cimport CPU


cdef class Base(object):
    
    cdef public unsigned short value
    
    cdef unsigned short get(self, CPU cpu)
    cdef void set(self, CPU cpu, unsigned short value)
