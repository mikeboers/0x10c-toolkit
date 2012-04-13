set a, 0x8000
set y, 0x0000

:loop

set z, y
shr z, 12
jsr printz

set z, y
shr z, 8
and z, 0x0f
jsr printz

add y, 0x0100
ife o, 0x0000
set pc, loop

set pc, exit

:printz
add z, 0x30
ifg z, 0x39
add z, 7
bor z, y
set [a], z
add a, 1
set pc, pop


exit:
	set pc, exit