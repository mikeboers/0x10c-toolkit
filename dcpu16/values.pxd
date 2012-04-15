from dcpu16.cpu cimport CPU


cdef class Base(object):
    
    cdef public unsigned short value
    
    cpdef unsigned short get(self, CPU cpu)

    # Non-void so it can be cpdef (for testing).
    cpdef unsigned char set(self, CPU cpu, unsigned short value) except 1
