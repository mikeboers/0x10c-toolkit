from cpu cimport CPU
cimport values

cdef class Base(object):
    
        cdef run(self, CPU cpu)


cdef class Basic(Base):

        cdef values.Base a
        cdef values.Base b


cdef class NonBasic(Base):

        cdef values.Base a

