set a, 0xF000
set b, 0x8000
set c, 0

:nextchar
  ife a, 128
    set pc, break
  set [b], a
  add a, 1
  add b, 2
  
  add c, 1
  mod c, 16
  ife c, 0
    add b, 32
  
  set pc, nextchar

:break
:exit
	set pc, exit