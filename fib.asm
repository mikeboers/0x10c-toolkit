
start:

	; Calculate fib sequence.
	SET [0x1000], 1
	SET [0x1001], 1


	; A will point to N - 2
	SET A, 0x1000
	SET I, 0

loop:
	; Increment, and exit after 10.
	ADD I, 1
	IFG I, 10
		SET PC, exit
	
	; Calculate the new number
	SET [A + 2], [A]
	ADD [A + 2], [A + 1]
	ADD A, 1
	
	SET PC, loop
	

exit:
	; This should crash the emulator.
	SET PC, exit


data: