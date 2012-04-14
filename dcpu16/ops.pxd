from cpu cimport CPU
cimport values


cdef class Base(object):
    
    cdef run(self, CPU cpu)


cdef class Basic(Base):

    cdef public values.Base a
    cdef public values.Base b


cdef class NonBasic(Base):

    cdef public values.Base a

