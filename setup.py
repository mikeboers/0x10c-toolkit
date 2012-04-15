import os

from distutils.core import setup

from Cython.Distutils import build_ext, Extension
from Cython.Build import cythonize


# Find all Cython modules.
ext_modules = []
for dirpath, dirnames, filenames in os.walk('dcpu16'):
    for filename in filenames:
        if filename.endswith('.pyx'):
            path = os.path.join(dirpath, filename)
            module_name = path.replace('/', '.')[:-4].strip('.')
            kwargs = {}
            if module_name == 'dcpu16.run':
                kwargs.update(
                    extra_compile_args='''
                        -I/usr/include
                    '''.strip().split(),
                    extra_link_args='''
                        -framework OpenGL
                        -framework GLUT
                    '''.strip().split(),
                )
            ext_modules.append(Extension(module_name, [path],
                include_dirs=['.'],
                **kwargs
            ))


setup(
    name='0x10c DCPU-16 Toolkit',
    version='0.1-dev',
    # description="0x10c DCPU-16 Toolkit"
    url="https://github.com/mikeboers/0x10c-toolkit",
    
    author="Mike Boers",
    author_email="0x10c-toolkit@mikeboers.com",
    license="BSD-3",

    packages=['dcpu16'],
    
    
    cmdclass={'build_ext': build_ext},
    ext_modules=cythonize(ext_modules),
    
    
    install_requires='''
        cython
        pyopengl
        PIL
    ''',
    
    entry_points={
        'console_scripts': [
            'asm = dcpu16.asm:main',
            'link = dcpu16.link:main',
            'run = dcpu16.run:main',
            'dis = dcpu16.dis:main',
        ]
    }
)