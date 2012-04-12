from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
    name = 'Hello world app',
    cmdclass = {'build_ext': build_ext},
    ext_modules = [
        Extension("cpu", ["cpu.pyx"]),
        Extension("values", ["values.pyx"]),
        Extension("ops", ["ops.pyx"]),
    ],
    
    install_requires = '''
        cython
        pyopengl
    ''',
)