from dcpu16.cpu cimport CPU
cimport dcpu16.values as values


cdef class Base(object):
    
    cdef run(self, CPU cpu)


cdef class Basic(Base):

    cdef public values.Base dst
    cdef public values.Base src


cdef class NonBasic(Base):

    cdef public values.Base val

