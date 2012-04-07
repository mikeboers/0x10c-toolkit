from cpu cimport CPU
from values cimport BaseValue


cdef class Base(object):
    
        cdef run(self, CPU cpu)


cdef class Basic(Base):

        cdef BaseValue a
        cdef BaseValue b


cdef class NonBasic(Base):

        cdef BaseValue a

