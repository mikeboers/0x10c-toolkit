import re
import sys

if len(sys.argv) == 1:
    infile = sys.stdin
elif len(sys.argv) == 2:
    infile = open(sys.argv[1])
else:
    print 'usage: %s [infile]' % (sys.argv[0])

headers = {}
encoded = []

for line in infile:
    
    line = line.strip()
    if not line:
        continue
    
    # Extract headers.
    m = re.match(r'; ([\w-]+): (.+)', line)
    if m:
        headers[m.group(1).lower()] = m.group(2)
        continue
    
    m = re.match(r'^\s*(:\w+)?(.*:)?([0-9a-fA-F \t]*)([;#].*)?$', line)
    if not m:
        print 'could not parse line %r' % line
        exit(1)
    line = re.sub(r'\s+', '', m.group(3).lower())
    
    encoded.append(line)

code = []
encoded = ''.join(encoded)
for i in xrange(0, len(encoded), 4):
    code.append(int(encoded[i:i + 4], 16))

def parse_symbol_header(encoded):
    out = []
    for chunk in encoded.split(', '):
        chunk = chunk.strip()
        if not chunk:
            continue
        m = re.match(r'(\w+)=0x([a-fA-F0-9]+)', chunk)
        if m:
            name, value = m.groups()
            out.append((name, int(value, 16)))
        else:
            raise ValueError('could not parse symbol header chunk: %r' % chunk)
    return out

global_symbols = dict(parse_symbol_header(headers.get('global-symbols', '')))
local_symbols = dict(parse_symbol_header(headers.get('local-symbols', '')))
symbol_references = parse_symbol_header(headers.get('symbol-references', ''))

found_all_symbols = True
for name, from_ in symbol_references:
    to = local_symbols.get(name)
    to = global_symbols.get(name) if name is None else to
    if to is None:
        print 'undefined symbol:', to
        found_all_symbols = False
        continue
    
    code[from_] += to

if not found_all_symbols:
    exit(1)

out = []
for i, x in enumerate(code):
    if i % 8 == 0:
        if i:
            out.append('\n')
        out.append('%04x: ' % i)
    else:
        out.append(' ')
    out.append('%04x' % x)

print ''.join(out)







    