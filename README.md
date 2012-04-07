# 0x10c Toolkit

This repo contains my tools for experimenting with [the DCPU-16 spec](http://0x10c.com/doc/dcpu-16.txt) for [the upcoming 0x10c game](http://0x10c.com/).

## TODO

- pull in examples from https://github.com/jtauber/DCPU-16-Examples

- disassembler script
- emulator script
	
- assembler
	- assemble into object files
	- these will still be able to contain references to undefined symbols
	- short labels
	
- linker
	- link assembled object files and resolve all symbols

- C compiler

- optimize
	- easly binding Cython everywhere

- move modules into a package

- values
	- rename load/save to get/set
	- save should take `unsigned short` value

- direct/indirect labels
- label offsets

- assembly for inserting raw data
	DAT "Hello!", 0
	- assembler should scan for as many arguments as it can find instead of
	  2 for basic and 1 for nonbasic, then we have can DAT or STR which takes
	  as many as it wants

- assembly for debugging
	PRX (print hex)   addr, num
	PRC (print chars) addr, num
	PRS (print string), addr
	PRD (print decimal)
	
- cycle costs

