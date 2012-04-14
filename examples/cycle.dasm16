SET [0x8280], 0x4
SET J, 0x80
:main
SET [0x8000+I], J
ADD I, 1
IFE I, 0x180
	SET I, 0
ADD J, 1
SET C, J
AND C, 0x80
IFE C, 0x0
	SET PC, Continue
ADD J, 0x80
:Continue    
IFE J, 0xFFFF
	SET J, 0
JSR loop
SET PC, main

:loop
SET X, 0
:loop2
ADD X, 1
IFE X, 0x80
	SET PC, main
SET PC, loop2
