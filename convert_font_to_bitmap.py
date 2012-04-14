from PIL import Image

print 'cdef unsigned char font[128][8]'
print

img = Image.open('font.png')
for i in range(128):
    xc = i % 32
    yc = i / 32

    print '# %d -> %c' % (i, i)
    
    
    prev = 0
    for row in range(8):
        y = (yc * 8 + (7 - row))
        data = 0
        for col in range(4):
            x = xc * 4 + col
            bit = int(img.getpixel((x, y))[0] > 128)
            data = (data << 1) + bit
        data <<= 4
        print 'font[%d][%d] = 0x%02x' % (i, row, data)
    
    print
            