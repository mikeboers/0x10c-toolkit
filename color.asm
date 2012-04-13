set I, 0
set J, 0
:loop
	set A, J
    mul A, 32
    add A, I
    add A, 0x8000
    
    set [A], I
    shl [A], 4
    bor [A], J
    shl [A], 8
    bor [A], 0x58
    
    add I, 1
    ifg I, 0xf
    	add J, 1
    and I, 0xf
    and J, 0xf
    
    set PC, loop
