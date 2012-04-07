from cpu cimport CPU


cdef class Base(object):
    
    cdef unsigned short value
    
    cdef unsigned short eval(self, CPU cpu)
    cdef void save(self, CPU cpu, unsigned short value)
