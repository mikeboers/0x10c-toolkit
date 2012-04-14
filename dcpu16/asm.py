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
    
        # Literal values.
        m = match(r'(' + NUMBER + ')', line)
        if m:
            return values.Literal(parse_number(m.group(1))), line[m.end(0):]
    
        # Basic registers.
        m = match(r'(' + REGISTER + ')', line)
        if m:
            return values.Register(parse_register(m.group(1))), line[m.end(0):]
    
        # Indirect registers and labels with offsets.
        m = match(r'\[([^\]]+)\]', line)
        if m:
            
            reg = None
            label = None
            offset = 0
            
            for chunk in m.group(1).split('+'):
                chunk = chunk.strip()
                
                try:
                    offset += parse_number(chunk)
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
                        raise ValueError('cannot have two registers in indirect value')
                    reg = new_reg
                    continue
                
                if not re.match(r'^\w+$', chunk):
                    raise ValueError('cannot identity chunk in indirect value: %r' % chunk)
                if label:
                    raise ValueError('cannot have two labels in indirect value')
                label = chunk
            
            # print 'reg', reg, 'label', repr(label), 'offset', offset
            
            if reg is not None:
                return values.Register(reg, indirect=True, offset=offset, label=label), line[m.end(0):]
            elif label:
                return values.Label(label, indirect=True, offset=offset), line[m.end(0):]
            else:
                return values.Indirect(offset), line[m.end(0):]
    
        # Stack values.
        m = match(r'(POP|PEEK|PUSH)', line)
        if m:
            return values.Stack(dict(POP=0, PEEK=1, PUSH=2)[m.group(1).upper()]), line[m.end(0):]
            
        # Basic (and offset) labels.
        m = match(r'(?:(' + NUMBER + ')\s*\+\s*)?' +
                  r'(\w+)' +
                  r'(?:\s*\+\s*(' + NUMBER + '))?', line)
        if m:
            pre, label, post = m.groups()
            offset = parse_number(pre or '0') + parse_number(post or '0')
            return values.Label(label, indirect=False, offset=offset), line[m.end(0):]
    
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
    
        raise ValueError('could not extract values from %r' % line)


    def load(self, infile):
        if isinstance(infile, basestring):
            infile = infile.splitlines()
        for line in infile:
            self._load_line(line)
    
    def _load_line(self, line):
        
        # Strip comments.
        line = re.sub(r'[#;].*', '', line).strip()
    
        m = re.match(r':\w+|\w+:', line)
        if m:
            label = m.group().strip(':')
            # print '%s:' % label
            self.operations.append(Label(label))
            line = line[m.end(0):].strip()
    
        if not line:
            return
        
        m = re.match(r'\.(\w+)(.*)', line)
        if m:
            directive, args = m.groups()
            if directive.lower() == 'global':
                self.global_names.add(args.strip())
            return
                
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
                self.symbol_references.append((x.label, len(code)))
                code.append(x.offset)
            elif isinstance(x, int):
                code.append(x)
            else:
                raise TypeError('cannot assemble code object %r' % x)
        
        out = []
        for header_name, header_value in [
            ('Global-Symbols', self.global_symbols),
            ('Local-Symbols', self.local_symbols),
            ('Symbol-References', self.symbol_references),
        ]:
            if header_value:
                out.append('; %s:' % header_name)
                for i, (sym, loc) in enumerate(header_value):
                    out.append(', ' if i else ' ')
                    out.append('%s=0x%04x' % (sym, loc))
                out.append('\n')
        
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

    