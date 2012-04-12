import sys
import re
import time


from mygl import gl, glu, glut

CHAR_W = 8
CHAR_H = 13
SCREEN_COLS = 32
SCREEN_ROWS = 12

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

        gl.clearColor(0, 0, 0, 1)
    
        gl.enable(gl.CULL_FACE)
        gl.enable(gl.DEPTH_TEST)
        gl.enable(gl.COLOR_MATERIAL)
    
        gl.enable('blend')
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        
        glut.reshapeFunc(self.reshape)
        glut.displayFunc(self.display)
        glut.idleFunc(self.idle)
        glut.keyboardFunc(self.keyboard)
    
    def run(self):
        return glut.mainLoop()
        
    def reshape(self, width, height):
        self.width = width
        self.height = height
        gl.viewport(0, 0, width, height)
        gl.matrixMode(gl.PROJECTION)
        gl.loadIdentity()
        gl.ortho(0, width, 0, height, -100, 100)
        gl.matrixMode(gl.MODELVIEW)
    
    def display(self):
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        gl.loadIdentity()
        
        for x in xrange(SCREEN_COLS):
            for y in xrange(SCREEN_ROWS):
                i = y * SCREEN_COLS + x
                c = self.cpu[0x8000 + i]
                if not c:
                    continue
                
                gl.rasterPos(x * CHAR_W, (SCREEN_ROWS - y - 1) * CHAR_H)
                glut.bitmapCharacter(glut.BITMAP_8_BY_13, c & 0xff)
        
        
        
        glut.swapBuffers()
    
    def keyboard(self, key, x, y):
        self.cpu[0x9000 + self.keyboard_ring_i] = ord(key)
        self.keyboard_ring_i = (self.keyboard_ring_i + 1) & 0xf
        
    def idle(self):
        
        if self.last_PC != self.cpu['PC']:
            self.last_PC = self.cpu['PC']
            try:
                self.cpu.run_one()
            except ValueError:
                self.last_PC = self.cpu['PC'] # Should stop it.

        current_time = time.time()
        if current_time - self.last_time > 1.0 / 60:
            glut.postRedisplay()
            self.last_time = current_time
        
    
        
    
        
        
if __name__ == '__main__':



    if len(sys.argv) == 1:
        infile = sys.stdin
    elif len(sys.argv) == 2:
        infile = open(sys.argv[1])
    else:
        print 'usage: %s [infile]' % (sys.argv[0])


    app = App()
    app.setup(infile)
    app.run()
    
    cpu.dump()
