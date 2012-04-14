from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
    name = '0x10c DCPU-16 Toolkit',
    version = '0.1-dev',
    # description = "0x10c DCPU-16 Toolkit",
    url = "https://github.com/mikeboers/0x10c-toolkit",
    
    author = "Mike Boers",
    author_email = "0x10c-toolkit@mikeboers.com",
    license = "BSD-3",

    # packages = find_packages(),
    
    cmdclass = {'build_ext': build_ext},
    ext_modules = [
        Extension("dcpu16.cpu", ["dcpu16/cpu.pyx"]),
        Extension("dcpu16.values", ["dcpu16/values.pyx"]),
        Extension("dcpu16.ops", ["dcpu16/ops.pyx"]),
        Extension("dcpu16.run", ["dcpu16/run.pyx"], extra_compile_args='''
            -I/usr/include
        '''.strip().split(), extra_link_args='''
            -framework OpenGL
            -framework GLUT
        '''.strip().split()),
    ],
    
    install_requires = '''
        cython
        pyopengl
        PIL
    ''',
    
    entry_points = {
        'console_scripts': [
            'asm = dcpu16.asm:main',
            'link = dcpu16.link:main',
            'run = dcpu16.run:main',
            'dis = dcpu16.dis:main',
        ]
    }
)