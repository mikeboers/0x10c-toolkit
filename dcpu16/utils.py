import os
import re

from . import link
from . import asm


def get_file_type(path):
    name = os.path.basename(path)
    ext = os.path.splitext(name)[1]
    m = re.match(r'\.d?(asm|hex|obj)(?:16)?$', ext.lower())
    if m:
        return m.group(1)
    else:
        return None

def get_hex_from_file(name):
    
    type = get_file_type(name)
    if not type:
        raise ValueError('unknown file type %r' % name)
    
    data = open(name).read()
    
    if type == 'asm':
        asmembler = asm.Assembler()
        asmembler.load(data)
        data = asmembler.assemble()
        type = 'obj'
    
    if type == 'obj':
        linker = link.Linker()
        linker.load(data)
        data = linker.link()
    
    return data
        
        
    