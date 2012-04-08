# 0x10c Toolkit

This repo contains my tools for experimenting with [the DCPU-16 spec](http://0x10c.com/doc/dcpu-16.txt) for [the upcoming 0x10c game](http://0x10c.com/).

## TODO

- pull in examples from https://github.com/jtauber/DCPU-16-Examples
- look for more TODOs http://dwilliamson.github.com/

- disassembler script
- emulator script
	
- assembler
	- assemble into object files
	- do not resolve symbols; output them into comments in the object files
		; Global-Symbols: start=0x0
		; Local-Symbols: loop=0x1234
		; Symbol-References: loop=0x1500
	- how do deal with short labels?
		It may not be all that important to deal with, as it only really
		benifits jumps to the first 0x1f words of code.
	
- linker
	- link assembled object files and resolve all labels/symbols
		- add final symbol addr into the words that are placeholders for it,
		  which will allow us to have positive offsets from them
	- if an object has start at the beginning, put it first, otherwise throw
	  in a `set PC, start`

- C compiler

- optimize
	- easly binding Cython everywhere

- move modules into a package

- values
	- rename load/save to get/set
	- save should take `unsigned short` value

- label offsets
	SET [0x1 + data], 0x20
	SET A, data + 0x23

- assembler directives:
	.GLOBAL start

- entrypoints
	- all equal SECTIONS get assembled next to each other
		.SECTION startup_function
	- or a way to have a location in memory be a null terminated list of start of section addresses
		startup_functions: DAT start_*, 0 (pattern matching labels)

- nearly everything should be case insensitive
	x labels
	√ registers
	√ operations
	√ watch out that string and character literals keep their case

- assembly for debugging
	PRX (print hex)   addr, num
	PRC (print chars) addr, num
	PRS (print string), addr
	PRD (print decimal)
	
- cycle costs

