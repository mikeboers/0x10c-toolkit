
	; Calculate fib sequence.
	set [0x1000], 1
	set [0x1001], 1


	; A will point to N - 2
	set A, 0x1000
	set I, 0

loop:
	# Increment, and exit after 10.
	add I, 1
	ifg I, 10
		SET PC, exit
	
	# Calculate the new number
	set [A + 2], [A]
	add [A + 2], [A + 1]
	add A, 1
	
	set PC, loop
	
exit:
	# This should crash the emulator.
	set PC, exit
