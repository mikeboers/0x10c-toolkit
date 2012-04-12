set I, 0

ascii_loop:
	set [0x8000 + I], I
	add I, 1
	ifg 256, I
		set PC, ascii_loop


set I, 0
key_loop:
	set [0x80ff + I], [0x9000 + I]
	add I, 1
	and I, 0xf
	set PC, key_loop
	

exit: set PC, exit