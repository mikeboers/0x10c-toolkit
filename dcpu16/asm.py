import sys
import re
import ast

from . import ops
from . import values




class Label(str):
    pass


custom_name_to_cls = {}
def custom(cls):
    custom_name_to_cls[cls.__name__[-3:]] = cls
    return cls

@custom
class OpDAT(object):
    
    def __init__(self, *args):
        self.data = []
        for arg in args:
            if isinstance(arg, values.Literal):
                self.data.append(arg.value)
            elif isinstance(arg, StringValue):
                self.data.extend(ord(c) for c in arg.string)
            elif isinstance(arg, values.Label):
                self.data.append(arg)
            else:
                raise TypeError('DAT can only take Literal values')
    
    def to_code(self):
        return self.data


class StringValue(values.Base):
    
    def __init__(self, value):
        self.string = value

register_to_code = dict((x, i) for i, x in enumerate('''
    A B C X Y Z I J SP PC O
'''.strip().split()))


class Assembler(object):
    
    def __init__(self):
        self.operations = []
        self.global_names = set()
        self.global_symbols = []
        self.local_symbols = []
        self.symbol_references = []
        self.constants = dict(
            VIDEO='0x8000',
            KEYBOARD='0x9000',
        )
    
    def _get_args(self, line):
        args = []
        while line:
            value, line = self._get_arg(line)
            args.append(value)
            line = line.strip()
        return args
    
    
    def _get_arg(self, line):
    
        NUMBER = r'(?:0x[a-f0-9 ]+|(?:0d)?[0-9 ]+|0o[0-7 ]+|0b[01 ]+)'
        def parse_number(raw):
            raw = re.sub(r'\s', '', raw).lower()
            if raw.startswith('0x'):
                return int(raw[2:], 16)
            if raw.startswith('0d'):
                return int(raw[2:], 10)
            if raw.startswith('0o'):
                return int(raw[2:], 8)
            if raw.startswith('0b'):
                return int(raw[2:], 2)
            return int(raw)
    
        REGISTER = r'(?:[ABCXYZIJ]|PC|SP|O)'
        def parse_register(raw):
            try:
                return register_to_code[raw.upper()]
            except KeyError:
                raise ValueError('not a register: %r' % raw)
    
        def match(exp, line, flags=0):
            return re.match(r'\s*' + exp + r'\s*(?:,\s*|$)', line, re.I | flags)
    
        # Stack values.
        m = match(r'(POP|PEEK|PUSH)', line)
        if m:
            return values.Stack(dict(POP=0, PEEK=1, PUSH=2)[m.group(1).upper()]), line[m.end(0):]
        
        # Character literals.
        m = match(r"('[^']*?')", line)
        if m:
            value = ast.literal_eval(m.group(1))
            if len(value) != 1:
                raise ValueError('character literal not of length 1: %r' % value)
            return values.Literal(ord(value)), line[m.end(0):]
    
        # Strings
        m = match(r'("[^"]*?")', line)
        if m:
            value = ast.literal_eval(m.group(1))
            return StringValue(value), line[m.end(0):]
        
        
        # Below here handles registers (with offsets), labels, and literals.
        
        
        # Extract indirect sequences.
        m = match(r'\[([^\]]+)\]', line)
        if m:
            indirect = True
            this_value = m.group(1)
            line = line[m.end(0):]
        
        # Extract non-indirect sequences.
        else:
            indirect = False
            line_chunks = line.split(',', 1)
            if len(line_chunks) == 2:
                this_value, line = line_chunks
            else:
                this_value = line_chunks[0]
                line = ''
        
        reg = None
        label = None
        offset = 0
        
        chunks = re.split(r'(\+|-)', this_value)
        for i in range(0, len(chunks), 2):
            if not i:
                operation = '+'
            else:
                operation = chunks[i-1]
            chunk = chunks[i].strip()
            
            # Lookup constants.
            chunk = self.constants.get(chunk, chunk)
            
            try:
                if operation == '+':
                    offset += parse_number(chunk)
                else:
                    offset -= parse_number(chunk)
            except ValueError:
                pass
            else:
                continue
                
            try:
                new_reg = parse_register(chunk)
            except ValueError:
                pass
            else:
                if reg:
                    raise ValueError('cannot have two registers in value %r' % this_value)
                if operation != '+':
                    raise ValueError('cannot use operator %r on registers in value %r' % (operation, this_value))
                reg = new_reg
                continue
                
            if not re.match(r'^\w+$', chunk):
                raise ValueError('cannot identity chunk %r in value %r' % (chunk, this_value))
            if label:
                raise ValueError('cannot have two labels in value %r' % this_value)
                
            label = chunk
        
        offset = offset % 0x10000
        
        if reg is not None:
            if offset and not indirect:
                raise ValueError('cannot offset direct register in value %r' % this_value)
            return values.Register(reg, indirect=indirect, offset=offset, label=label), line
        elif label:
            return values.Label(label, indirect=indirect, offset=offset, subtract=operation=='-'), line
        elif indirect:
            return values.Indirect(offset), line
        else:
            return values.Literal(offset), line
        
        


    def load(self, infile):
        if isinstance(infile, basestring):
            infile = infile.splitlines()
        for line in infile:
            self._load_line(line)
    
    def _load_line(self, line):
        
        # Strip comments.
        line = re.sub(r';.*', '', line).strip()
    
        m = re.match(r':(\w+)', line)
        if m:
            self.operations.append(Label(m.group(1)))
            line = line[m.end(0):].strip()
    
        if not line:
            return
        
        m = re.match(r'\.(\w+)(.*)', line)
        if m:
            directive, args = m.groups()
            if directive.lower() == 'global':
                self.global_names.add(args.strip())
                return
            if directive.lower() == 'define':
                name, value = args.split(None, 1)
                self.constants[name] = value
                return
            raise SyntaxError('unknown directive %r' % directive)
                
        m = re.match(r'[a-zA-Z]{3}', line)
        if not m:
            raise SyntaxError('expected opname; got %r' % line)
    
        opname = m.group(0).upper()
        line = line[m.end(0):].strip()
    
        if opname in ops.basic_name_to_cls:
            opcls = ops.basic_name_to_cls[opname]
        elif opname in ops.nonbasic_name_to_cls:
            opcls = ops.nonbasic_name_to_cls[opname]
        elif opname in custom_name_to_cls:
            opcls = custom_name_to_cls[opname]
        else:
            raise ValueError('no operation %r' % opname)
    
        args = self._get_args(line)
        op = opcls(*args)
        
        self.operations.append(op)
    
    def assemble(self):
        
        raw_code = []
                
        for op in self.operations:
            
            if isinstance(op, Label):
                name = str(op)
                if name in self.global_names:
                    self.global_symbols.append((name, len(raw_code)))
                else:
                    self.local_symbols.append((name, len(raw_code)))
                
            else:
                raw_code.extend(op.to_code())
        
        code = []
        for x in raw_code:
            if isinstance(x, values.Label):
                self.symbol_references.append((x.label, x.subtract, len(code)))
                code.append(x.offset)
            elif isinstance(x, int):
                code.append(x)
            else:
                raise TypeError('cannot assemble code object %r' % x)
        

            
        out = []
        
        def format_symbol_defs(values):
            if values:
                for i, (sym, loc) in enumerate(values):
                    out.append(', ' if i else ' ')
                    out.append('%s=0x%04x' % (sym, loc))
                out.append('\n')
        def format_symbol_refs(values):
            if values:
                for i, (sym, sub, loc) in enumerate(values):
                    out.append(', ' if i else ' ')
                    out.append('0x%04x%s%s' % (loc, '-' if sub else '+', sym))
                out.append('\n')
        
        for header_name, header_value, formatter in [
            ('Global-Symbols', self.global_symbols, format_symbol_defs),
            ('Local-Symbols', self.local_symbols, format_symbol_defs),
            ('Symbol-References', self.symbol_references, format_symbol_refs),
        ]:
            if header_value:
                out.append('; %s:' % header_name)
                formatter(header_value)
        
        for i, x in enumerate(code):
            if i % 8 == 0:
                if i:
                    out.append('\n')
                out.append('%04x: ' % i)
            else:
                out.append(' ')
            out.append('%04x' % x)
    
        return ''.join(out)


def main():
    
    if len(sys.argv) == 1:
        infile = sys.stdin
    elif len(sys.argv) == 2:
        infile = open(sys.argv[1])
    else:
        print 'usage: %s [infile]' % (sys.argv[0])
    
    asm = Assembler()
    asm.load(infile)
    print asm.assemble()


if __name__ == '__main__':
    main()

    