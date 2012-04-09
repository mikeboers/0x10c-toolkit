# 0x10c Toolkit

This repo contains my tools for experimenting with [the DCPU-16 spec](http://0x10c.com/doc/dcpu-16.txt) for [the upcoming 0x10c game](http://0x10c.com/).

## TODO

- pull in examples from https://github.com/jtauber/DCPU-16-Examples
- look for more TODOs http://dwilliamson.github.com/

√ disassembler script
√ running script
√ assembling script
√ linking script
	
- assembler
	√ assemble into object files
	√ do not resolve symbols; output them into comments in the object files
		; Global-Symbols: start=0x0
		; Local-Symbols: loop=0x1234
		; Symbol-References: loop=0x1500
	- how do deal with short labels?
		It may not be all that important to deal with, as it only really
		benifits jumps to the first 0x1f words of code.
	
- linker
	√ link assembled object files and resolve all labels/symbols
		- add final symbol addr into the words that are placeholders for it,
		  which will allow us to have positive offsets from them
	x if an object has start at the beginning, put it first, otherwise throw
	  in a `set PC, start`. Not going to do this as one can easily add a stub
	  file as the first argument to the linker which contains: `set PC, start`
	- consider adding special global symbols:
		- __HEAP__ would point to the first word after the end of memory
		- __KEYBOARD__ to the keyboard buffer
		- __VIDEO__ to the video screen

- C compiler

- optimize
	- easly binding Cython everywhere

- move modules into a package

- label offsets
	SET [0x1 + data], 0x20
	SET A, data + 0x23

- more forgiving regsiter offsets:
	[A + 1] or [1 + A]

- start utils module
	- hex stream normalizer
	- comment stripping normalizer
	- value parsing?

- convert scripts into setuptools entrypoints


- assembler directives:
	√ .GLOBAL start

- character literals should be able to have escapes: '\n'
	- use ast.literal_eval on these and strings

- entrypoints
	- all equal SECTIONS get assembled next to each other
		.SECTION startup_function
	- or a way to have a location in memory be a null terminated list of start of section addresses
		startup_functions: DAT start_*, 0 (pattern matching labels)

- assembly for debugging
	PRX (print hex)   addr, num
	PRC (print chars) addr, num
	PRS (print string), addr
	PRD (print decimal)
	BRK
		kill the emulator; could just be a `DAT 0`
	
	put these all the end of the reserved special opcode space
	
- cycle costs

