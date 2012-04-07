from cpu cimport DCPU16
from values cimport BaseValue

cdef class BasicOperation(object):

        cdef BaseValue a
        cdef BaseValue b
    
        cdef run(self, DCPU16 cpu)
