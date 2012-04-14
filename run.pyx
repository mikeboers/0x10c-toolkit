import sys
import re
import time
from PIL import Image
from c_opengl cimport *

from cpu cimport CPU

from mygl import glu, glut

include "font.pyi"
# include "font_data.pyi"

DEF CHAR_W = 4
DEF CHAR_H = 8
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
    
    cdef unsigned int font_texture
    
    cdef unsigned int pixel_scale
    
    def __init__(self):
        self.last_PC = -1
        self.last_time = 0
        self.keyboard_ring_i = 0
        self.pixel_scale = 3
    
    def setup(self, infile):
        
        self.cpu = CPU()
        self.cpu.loads(infile.read())
        
        glut.init(sys.argv)
        glut.initDisplayMode(glut.DOUBLE | glut.RGBA | glut.DEPTH)
    
        self.width = CHAR_W * SCREEN_COLS * self.pixel_scale
        self.height = CHAR_H * SCREEN_ROWS * self.pixel_scale
        glut.initWindowSize(self.width, self.height)
        glut.createWindow('DCPU-16 Emulator')

        glClearColor(0, 0, 0, 1)
        
        glut.reshapeFunc(self.reshape)
        glut.displayFunc(self.display)
        glut.idleFunc(self.idle)
        glut.keyboardFunc(self.keyboard)
        
        glGenTextures(1, &self.font_texture)
        glBindTexture(GL_TEXTURE_2D, self.font_texture)
        # print 'font_texture', self.font_texture
        img = Image.open('font.png')
        img = img.convert('RGBA')
        img.putalpha(img.split()[0])
        data = img.tostring()
        cdef unsigned char *c_data = data
        assert len(data) == 16384
        glTexImage2D(GL_TEXTURE_2D, 0, 4, 32 * 4, 4 * 8, 0, GL_RGBA, GL_UNSIGNED_BYTE, c_data)
        print glGetError()
        glEnable(GL_TEXTURE_2D)
        # glEnable(GL_COLOR_MATERIAL)
        #glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        #glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        glEnable(GL_BLEND)
        
        
    
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

        glScalef(self.pixel_scale, self.pixel_scale, self.pixel_scale)
        
        cdef unsigned short i, c, x, y, bgx, fgx, cx, cy
        
        for x in range(SCREEN_COLS):
            for y in range(SCREEN_ROWS):
                i = y * SCREEN_COLS + x
                c = self.cpu.memory[0x8000 + i]
                if not c:
                    continue
                
                bgx = ((c & 0x0f00) >> 8)
                if bgx:
                    glDisable(GL_TEXTURE_2D)
                    glColor3ub(colours[bgx][0], colours[bgx][1], colours[bgx][2])
                    glBegin(GL_QUADS)
                    glVertex2i(x * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                    glVertex2i((x + 1) * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                    glVertex2i((x + 1) * CHAR_W, (SCREEN_ROWS - y) * CHAR_H)
                    glVertex2i(x * CHAR_W, (SCREEN_ROWS - y) * CHAR_H)
                    glEnd()
                    glEnable(GL_TEXTURE_2D)
                    
                
                fgx = ((c & 0xf000) >> 12)
                
                cx = (c & 0x7f) % 32
                cy = (c & 0x7f) / 32
                
                glColor3ub(colours[fgx][0], colours[fgx][1], colours[fgx][2])
                
                

                glBegin(GL_QUADS)
                
                glTexCoord2f((cx + 0) / 32.0, (cy + 1) / 4.0)
                glVertex2i(x * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                
                glTexCoord2f((cx + 1) / 32.0, (cy + 1) / 4.0)
                glVertex2i((x + 1) * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                
                glTexCoord2f((cx + 1) / 32.0, (cy + 0) / 4.0)
                glVertex2i((x + 1) * CHAR_W, (SCREEN_ROWS - y) * CHAR_H)
                
                glTexCoord2f((cx + 0) / 32.0, (cy + 0) / 4.0)
                glVertex2i(x * CHAR_W, (SCREEN_ROWS - y) * CHAR_H)
                
                glEnd()
                
        
        
        
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
