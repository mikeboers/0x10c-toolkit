import re
import sys


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


class Linker(object):
    
    def __init__(self):
        self.objects = []
        self.global_symbols = {}
        self.code = []
    
    def loads(self, source, name='<string>'):
        obj = Object(name)
        obj.loads(source)
        self.objects.append(obj)
    
    def load(self, infile, name='<file>'):
        obj = Object(name)
        obj.load(infile)
        self.objects.append(obj)
    
    def link(self):
        
        self.code = []
        
        # Build up global symbols.
        offset = 0
        for obj in self.objects:
            for name, value in obj.global_symbols:
                self.global_symbols[name] = offset + value
            offset += len(obj.code)
        
        self.global_symbols['HEAP'] = offset
        
        # Resolve all symbols
        symbols = {}
        missing = []
        offset = 0
        for obj in self.objects:
            
            symbols.update(self.global_symbols)
            for name, value in obj.local_symbols:
                symbols[name] = offset + value
            
            code = obj.code[:]
            
            for name, from_ in obj.symbol_references:
                to = symbols.get(name)
                
                if to is None:
                    missing.append(name)
                    continue
                
                code[from_] += to
            
            self.code.extend(code)
            offset += len(code)
                    
        if missing:
            for x in missing:
                print 'undefined symbol: %s' % x
            return False
        
        return True
    
    def dumps(self):
    
        out = []
        for i, x in enumerate(self.code):
            if i % 8 == 0:
                if i:
                    out.append('\n')
                out.append('%04x: ' % i)
            else:
                out.append(' ')
            out.append('%04x' % x)

        return ''.join(out)
        
        
        

class Object(object):
    
    def __init__(self, name):
        self.name = name
        self.headers = {}
        self.code = []
    
    def loads(self, source):
        self.load(source.splitlines())
    
    def load(self, infile):
        encoded = []
        for line in infile:
    
            line = line.strip()
            if not line:
                continue
    
            # Extract headers.
            m = re.match(r'; ([\w-]+): (.+)', line)
            if m:
                self.headers[m.group(1).lower()] = m.group(2)
                continue
    
            m = re.match(r'^\s*(:\w+)?(.*:)?([0-9a-fA-F \t]*)([;#].*)?$', line)
            if not m:
                print 'could not parse line %r' % line
                exit(1)
            line = re.sub(r'\s+', '', m.group(3).lower())
    
            encoded.append(line)

        encoded = ''.join(encoded)
        for i in xrange(0, len(encoded), 4):
            self.code.append(int(encoded[i:i + 4], 16))
        
        self.global_symbols = parse_symbol_header(self.headers.get('global-symbols', ''))
        self.local_symbols = parse_symbol_header(self.headers.get('local-symbols', ''))
        self.symbol_references = parse_symbol_header(self.headers.get('symbol-references', ''))
        
        
            
        
if __name__ == '__main__':
    
    if len(sys.argv) == 1:
        infiles = [sys.stdin]
    else:
        infiles = [open(x) for x in sys.argv[1:]]

    linker = Linker()
    for infile in infiles:
        linker.load(infile)
    
    if not linker.link():
        exit(1)
    
    print linker.dumps()
    







    