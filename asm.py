import sys
import re

import ops
import values





class Label(str):
    def to_code(self):
        return ()


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
            return register_to_code[raw.upper()]
    
        def match(exp, line):
            return re.match(r'\s*' + exp + r'\s*(?:,\s*|$)', line, re.I)
    
        # Literal values.
        m = match(r'(' + NUMBER + ')', line)
        if m:
            return values.Literal(parse_number(m.group(1))), line[m.end(0):]
    
        # Indirect values.
        m = match(r'\[\s*(' + NUMBER + ')\s*\]', line)
        if m:
            return values.Indirect(parse_number(m.group(1))), line[m.end(0):]
    
        # Basic registers.
        m = match(r'(' + REGISTER + ')', line)
        if m:
            return values.Register(parse_register(m.group(1))), line[m.end(0):]
    
        # Indirect register.
        m = match(r'\[\s*(' + REGISTER + ')\s*\]', line)
        if m:
            return values.Register(parse_register(m.group(1)), indirect=True), line[m.end(0):]
    
        # Offset register.
        m = match(r'\[\s*(' + NUMBER + ')\s*\+\s*(' + REGISTER + ')\s*\]', line)
        if m:
            return values.Register(
                parse_register(m.group(2)),
                indirect=True,
                offset=parse_number(m.group(1)),
            ), line[m.end(0):]
        m = match(r'\[\s*(' + REGISTER + ')\s*\+\s*(' + NUMBER + ')\s*\]', line)
        if m:
            return values.Register(
                parse_register(m.group(1)),
                indirect=True,
                offset=parse_number(m.group(2)),
            ), line[m.end(0):]

    
        # Stack values.
        m = match(r'(POP|PEEK|PUSH)', line)
        if m:
            return values.Stack(dict(POP=1, PEEK=0, PUSH=-1)[m.group(1)]), line[m.end(0):]
    
        # Labels
        m = match(r'(\w{3,})', line)
        if m:
            return values.Label(m.group(1)), line[m.end(0):]
        m = match(r'\[\s*(\w{3,})\s*\]', line)
        if m:
            return values.Label(m.group(1), indirect=True), line[m.end(0):]
    
        # Character literals.
        m = match(r"'([^'])'", line)
        if m:
            return values.Literal(ord(m.group(1))), line[m.end(0):]
    
        # Strings
        m = match(r'"([^"]*)"', line)
        if m:
            return StringValue(m.group(1)), line[m.end(0):]
    
        raise ValueError('could not extract values from %r' % line)


    def load(self, infile):
        for line in infile:
            self._load_line(line)

    def loads(self, source):
        for line in source.splitlines():
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

    def dumps(self):
        
        code = []
        labels = {}
        for op in self.operations:
            if isinstance(op, Label):
                labels[str(op)] = len(code)
            code.extend(op.to_code())
    
            # print op
            # print '\t', ' '.join('%04x' % x if isinstance(x, int) else x for x in op.to_code())
            # print

        code = [labels.get(x, x) for x in code]

        for i, x in enumerate(code):
            if i % 8 == 0:
                if i:
                    print
                print '%04x:' % i,
            print '%04x' % x,



if __name__ == '__main__':
    
    if len(sys.argv) == 1:
        infile = sys.stdin
    elif len(sys.argv) == 2:
        infile = open(sys.argv[1])
    else:
        print 'usage: %s [infile]' % (sys.argv[0])
    
    asm = Assembler()
    asm.load(infile)
    asm.dumps()
    