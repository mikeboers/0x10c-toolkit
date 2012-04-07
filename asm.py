import sys
import re

import ops
import values


if len(sys.argv) == 1:
    infile = sys.stdin
elif len(sys.argv) == 2:
    infile = open(sys.argv[1])
else:
    print 'usage: %s [infile]' % (sys.argv[0])


class Label(str):
    def to_code(self):
        return ()


operations = []


register_to_code = dict((x, i) for i, x in enumerate('ABCXYZIJ'))

def get_value(line):
    
    NUMBER = r'(?:0x[a-fA-F0-9 ]+|(?:0d)?[0-9 ]+|0o[0-7 ]+|0b[01 ]+)'
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
        return register_to_code.get(raw, raw)
    
    def match(exp, line):
        return re.match(r'\s*' + exp + r'\s*(?:,\s*|$)', line)
    
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
    
    # Stack values.
    m = match(r'(POP|PEEK|PUSH)', line)
    if m:
        return values.Stack(dict(POP=1, PEEK=0, PUSH=-1)[m.group(1)]), line[m.end(0):]
    
    # Labels
    m = match(r'(\w{3,})', line)
    if m:
        return values.Label(m.group(1)), line[m.end(0):]
    
    return 'unknown', line


for line in infile:
    
    # Strip comments.
    line = re.sub(r';.*', '', line).strip()
    
    m = re.match(r':\w+|\w+:', line)
    if m:
        label = m.group().strip(':')
        print '%s:' % label
        operations.append(Label(label))
        line = line[m.end(0):].strip()
    
    if not line:
        continue
    
    m = re.match(r'[a-zA-Z]{3}', line)
    if not m:
        raise SyntaxError('expected opname; got %r' % line)
    
    opname = m.group(0)
    line = line[m.end(0):].strip()
    
    if opname in ops.basic_name_to_cls:
        opcls = ops.basic_name_to_cls[opname]
        a, line = get_value(line)
        b, line = get_value(line)
        
    elif opname in ops.nonbasic_name_to_cls:
        opcls = ops.nonbasic_name_to_cls[opname]
        a, line = get_value(line)
        b = None
    
    else:
        raise ValueError('no operation %r' % opname)
    
    if line:
        print 'LINE NOT FULLY CONSUMED:', repr(line)
    else:
        op = opcls(a, b)
        operations.append(op)
        print op


code = []
labels = {}
for op in operations:
    if isinstance(op, Label):
        labels[str(op)] = len(code)
    code.extend(op.to_code())
    
    print op
    print '\t', op.to_code()
    print
    

print code

code = [labels.get(x, x) for x in code]

print code

for i, x in enumerate(code):
    if i and (i % 8 == 0):
        print
    print '%04x' % x,