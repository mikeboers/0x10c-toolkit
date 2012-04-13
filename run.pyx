import sys
import re
import time

from c_opengl cimport *
from mygl import glu, glut

CHAR_W = 8
CHAR_H = 13
SCREEN_COLS = 32
SCREEN_ROWS = 16

class App(object):
    
    def __init__(self):
        self.last_PC = None
        self.last_time = 0
        self.keyboard_ring_i = 0
    
    def setup(self, infile):
        
        from cpu import CPU
        self.cpu = CPU()
        self.cpu.loads(infile.read())
        
        glut.init(sys.argv)
        glut.initDisplayMode(glut.DOUBLE | glut.RGBA | glut.DEPTH | glut.MULTISAMPLE)
    
        self.width = CHAR_W * SCREEN_COLS
        self.height = CHAR_H * SCREEN_ROWS
        glut.initWindowSize(self.width, self.height)
        glut.createWindow('DCPU-16 Emulator')

        glClearColor(0, 0, 0, 1)
    
        glEnable(GL_CULL_FACE)
        glEnable(GL_DEPTH_TEST)
        glEnable(GL_COLOR_MATERIAL)
    
        glEnable(GL_BLEND)
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        
        glut.reshapeFunc(self.reshape)
        glut.displayFunc(self.display)
        glut.idleFunc(self.idle)
        glut.keyboardFunc(self.keyboard)
    
    def run(self):
        return glut.mainLoop()
        
    def reshape(self, width, height):
        self.width = width
        self.height = height
        glViewport(0, 0, width, height)
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        glOrtho(0, width, 0, height, -100, 100)
        glMatrixMode(GL_MODELVIEW)
    
    def display(self):
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glLoadIdentity()
        
        def col(x):
            h = int(bool(x & 0x8))
            r = int(bool(x & 0x4))
            g = int(bool(x & 0x2))
            b = int(bool(x & 0x1))
            
            rgb = (h + r, h + g, h + b)
            return tuple((0.0, 0.5, 1.0)[x] for x in rgb)
            
        for x in xrange(SCREEN_COLS):
            for y in xrange(SCREEN_ROWS):
                i = y * SCREEN_COLS + x
                c = self.cpu[0x8000 + i]
                if not c:
                    continue
                
                # bgx = ((c & 0x0f00) >> 8)
                # if bgx:
                #     glColor(col(bgx))
                #     glBegin(GL_QUADS)
                #     glVertex(x * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                #     glVertex((x + 1) * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                #     glVertex((x + 1) * CHAR_W, (SCREEN_ROWS - y) * CHAR_H)
                #     glVertex(x * CHAR_W, (SCREEN_ROWS - y) * CHAR_H)
                #     glEnd()
                # fgx = ((c & 0xf000) >> 12)
                # glColor(col(fgx))
                glRasterPos2i(x * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                glut.bitmapCharacter(glut.BITMAP_8_BY_13, c & 0x7f)
        
        
        
        glut.swapBuffers()
    
    def keyboard(self, key, x, y):
        self.cpu[0x9000 + self.keyboard_ring_i] = ord(key)
        self.keyboard_ring_i = (self.keyboard_ring_i + 1) & 0xf
        
    def idle(self):
        
        if True or self.last_PC != self.cpu['PC']:
            self.last_PC = self.cpu['PC']
            for i in xrange(100):
                try:
                    self.cpu.run_one()
                    print ' '.join(['%4x' % self.cpu[x] for x in 'PC SP O A B C X Y Z I J'.split()])
                    
                except ValueError as e:
                    print e
                    print 'STOPPING'
                    self.last_PC = self.cpu['PC'] # Should stop it.
                    break
        else:
            print 'stopped'
            glut.idleFunc(None)

        current_time = time.time()
        if current_time - self.last_time > 1.0 / 60:
            glut.postRedisplay()
            self.last_time = current_time
        
    
        
    
        
def main():

    if len(sys.argv) == 1:
        infile = sys.stdin
    elif len(sys.argv) == 2:
        infile = open(sys.argv[1])
    else:
        print 'usage: %s [infile]' % (sys.argv[0])


    app = App()
    app.setup(infile)
    app.run()
    app.cpu.dump()
