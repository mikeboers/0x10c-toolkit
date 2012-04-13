import sys
import re
import time

from c_opengl cimport *

from cpu cimport CPU

from mygl import glu, glut

include "font.pyi"

DEF CHAR_W = 8
DEF CHAR_H = 13
DEF SCREEN_COLS = 32
DEF SCREEN_ROWS = 12

cdef unsigned char colours[16][3]
for i, (r, g, b) in enumerate([
    (0x00, 0x00, 0x00),
    (0x00, 0x1b, 0xaa),
    (0x00, 0xaa, 0x00),
    (0x00, 0xaa, 0xaa),
    (0xaa, 0x02, 0x06),
    (0xaa, 0x1b, 0xaa),
    (0xaa, 0xaa, 0x00),
    (0xaa, 0xaa, 0xaa),
    (0x55, 0x55, 0x55),
    (0x55, 0x55, 0xff),
    (0x55, 0xfc, 0x55),
    (0x55, 0xff, 0xff),
    (0xff, 0x54, 0x55),
    (0xff, 0x55, 0xff),
    (0xff, 0xfc, 0x55),
    (0xff, 0xff, 0xff),
]):
    colours[i][0] = r
    colours[i][1] = g
    colours[i][2] = b


cdef class App(object):
    
    cdef CPU cpu
    cdef int last_PC
    cdef float last_time
    cdef unsigned short keyboard_ring_i
    
    cdef unsigned int width
    cdef unsigned int height
    
    def __init__(self):
        self.last_PC = -1
        self.last_time = 0
        self.keyboard_ring_i = 0
    
    def setup(self, infile):
        
        self.cpu = CPU()
        self.cpu.loads(infile.read())
        
        glut.init(sys.argv)
        glut.initDisplayMode(glut.DOUBLE | glut.RGBA | glut.DEPTH | glut.MULTISAMPLE)
    
        self.width = CHAR_W * SCREEN_COLS
        self.height = CHAR_H * SCREEN_ROWS
        glut.initWindowSize(self.width, self.height)
        glut.createWindow('DCPU-16 Emulator')

        glClearColor(0, 0, 0, 1)
        
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
        
        cdef unsigned short i, c, x, y, bgx, fgx
        for x in range(SCREEN_COLS):
            for y in range(SCREEN_ROWS):
                i = y * SCREEN_COLS + x
                c = self.cpu.memory[0x8000 + i]
                if not c:
                    continue
                
                bgx = ((c & 0x0f00) >> 8)
                if bgx:
                    glColor3ub(colours[bgx][0], colours[bgx][1], colours[bgx][2])
                    glBegin(GL_QUADS)
                    glVertex2i(x * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                    glVertex2i((x + 1) * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                    glVertex2i((x + 1) * CHAR_W, (SCREEN_ROWS - y) * CHAR_H)
                    glVertex2i(x * CHAR_W, (SCREEN_ROWS - y) * CHAR_H)
                    glEnd()
                
                fgx = ((c & 0xf000) >> 12)
                
                glColor3ub(colours[fgx][0], colours[fgx][1], colours[fgx][2])
                glRasterPos2i(x * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                
                glBitmap(4, 8, 0, 0, 4, 0, &font[c & 0x7f][0])
                # glut.bitmapCharacter(glut.BITMAP_8_BY_13, c & 0x7f)
        
        
        
        glut.swapBuffers()
    
    def keyboard(self, key, x, y):
        self.cpu[0x9000 + self.keyboard_ring_i] = ord(key)
        self.keyboard_ring_i = (self.keyboard_ring_i + 1) & 0xf
        
    def idle(self):
        cdef int i

        for i in range(3000):
            try:
                self.cpu.run_one()
                # print ' '.join(['%4x' % self.cpu[x] for x in 'PC SP O A B C X Y Z I J'.split()]) 
            except ValueError as e:
                print e

        glut.postRedisplay()
        
        
    
        
    
        
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
