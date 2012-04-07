# 0x10c Toolkit

This repo contains my tools for experimenting with [the DCPU-16 spec](http://0x10c.com/doc/dcpu-16.txt) for [the upcoming 0x10c game](http://0x10c.com/).

## TODO

- pull in examples from https://github.com/jtauber/DCPU-16-Examples

- disassembler script
- emulator script
	
- assembler
	- assemble into object files
	- these will still be able to contain references to undefined symbols
	
- linker
	- link assembled object files and resolve all symbols

- C compiler

- optimize
	- easly binding Cython everywhere

- move modules into a package

- values
	- rename load/save to get/set
	- save should take `unsigned short` value
	
