import sys
import re
import time
from PIL import Image
from c_opengl cimport *

from .cpu cimport CPU
from .mygl import glu, glut


DEF CHAR_W = 4
DEF CHAR_H = 8
DEF SCREEN_COLS = 32
DEF SCREEN_ROWS = 12

cdef unsigned char colours[16][3]
for i, (r, g, b) in enumerate([
    (0x00, 0x00, 0x00),
    (0x00, 0x00, 0xaa),
    (0x00, 0xaa, 0x00),
    (0x00, 0xaa, 0xaa),
    (0xaa, 0x00, 0x00),
    (0xaa, 0x00, 0xaa),
    (0xaa, 0xaa, 0x00),
    (0xaa, 0xaa, 0xaa),
    (0x55, 0x55, 0x55),
    (0x55, 0x55, 0xff),
    (0x55, 0xff, 0x55),
    (0x55, 0xff, 0xff),
    (0xff, 0x55, 0x55),
    (0xff, 0x55, 0xff),
    (0xff, 0xff, 0x55),
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
    
    cdef unsigned int font_texture
    
    
    def __init__(self):
        self.last_PC = -1
        self.last_time = 0
        self.keyboard_ring_i = 0
    
    def setup(self, infile):
        
        # Setup the CPU.
        self.cpu = CPU()
        self.cpu.loads(infile.read())
        
        # Setup GLUT.
        glut.init(sys.argv)
        glut.initDisplayMode(glut.DOUBLE | glut.RGBA | glut.DEPTH)
    
        # Setup the main window.
        self.width = CHAR_W * SCREEN_COLS * 3
        self.height = CHAR_H * SCREEN_ROWS * 3
        glut.initWindowSize(self.width, self.height)
        glut.createWindow('DCPU-16 Emulator')
        
        # Setup callbacks.
        glut.reshapeFunc(self.reshape)
        glut.displayFunc(self.display)
        glut.idleFunc(self.idle)
        glut.keyboardFunc(self.keyboard)
        
        # Setup font texture.
        # TODO: Cython should have access to this.
        img = Image.open('font.png')
        img = img.convert('RGBA')
        img.putalpha(img.split()[0])
        data = img.tostring()
        cdef unsigned char *c_data = data
        assert len(data) == 16384
        glGenTextures(1, &self.font_texture)
        glBindTexture(GL_TEXTURE_2D, self.font_texture)
        glTexImage2D(GL_TEXTURE_2D, 0, 4, 32 * 4, 4 * 8, 0, GL_RGBA, GL_UNSIGNED_BYTE, c_data)
        
        
        # INIT OPENGL
        
        glClearColor(0, 0, 0, 1)
        
        glEnable(GL_TEXTURE_2D)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
        
        glEnable(GL_BLEND)
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        
        
    def run(self):
        return glut.mainLoop()
    
    def reshape(self, width, height):
        self.width = width
        self.height = height
        glViewport(0, 0, self.width, self.height)
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        glOrtho(0, SCREEN_COLS, 0, SCREEN_ROWS, -1, 10)
        glMatrixMode(GL_MODELVIEW)
    
    def display(self):
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        
        glLoadIdentity()
        glTranslatef(0, SCREEN_ROWS, 0)
        
        cdef unsigned short i, c, x, y, bgx, fgx, cx, cy
        
        for x in range(SCREEN_COLS):
            glPushMatrix()
            
            for y in range(SCREEN_ROWS):
                glTranslatef(0, -1, 0)
                
                i = y * SCREEN_COLS + x
                c = self.cpu.memory[0x8000 + i]
                if not c:
                    continue
                
                bgx = ((c & 0x0f00) >> 8)
                if bgx:
                    glDisable(GL_TEXTURE_2D)
                    glColor3ub(colours[bgx][0], colours[bgx][1], colours[bgx][2])
                    glBegin(GL_QUADS)
                    glVertex2i(0, 0)
                    glVertex2i(1, 0)
                    glVertex2i(1, 1)
                    glVertex2i(0, 1)
                    glEnd()
                    glEnable(GL_TEXTURE_2D)
                    
                fgx = ((c & 0xf000) >> 12)
                glColor3ub(colours[fgx][0], colours[fgx][1], colours[fgx][2])
                
                cx = (c & 0x7f) % 32
                cy = (c & 0x7f) / 32
                
                # Draw the character itself.
                glBegin(GL_QUADS)
                glTexCoord2f((cx + 0) / 32.0, (cy + 1) / 4.0)
                glVertex2i(0, 0)
                glTexCoord2f((cx + 1) / 32.0, (cy + 1) / 4.0)
                glVertex2i(1, 0)
                glTexCoord2f((cx + 1) / 32.0, (cy + 0) / 4.0)
                glVertex2i(1, 1)
                glTexCoord2f((cx + 0) / 32.0, (cy + 0) / 4.0)
                glVertex2i(0, 1)
                glEnd()
                
            
            glPopMatrix()
            glTranslatef(1, 0, 0)
        
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
