# 0x10c Toolkit

This repo contains my tools for experimenting with [the DCPU-16 spec](http://0x10c.com/doc/dcpu-16.txt) for [the upcoming 0x10c game](http://0x10c.com/).

## TODO

- pull in examples from https://github.com/jtauber/DCPU-16-Examples

- disassembler (done, in `dis.py`)
	- rewrite in Cython or C++
	
- emulator (partially done, in `dis.py`)
	- rewrite in Cython or C++
	
- assembler
	- assemble into object files
	- these will still be able to contain references to undefined symbols
	
- linker
	- link assembled object files and resolve all symbols

- C compiler
