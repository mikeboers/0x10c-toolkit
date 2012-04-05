# 0x10c Toolkit

This repo contains my tools for experimenting with [the DCPU-16 spec](http://0x10c.com/doc/dcpu-16.txt) for [the upcoming 0x10c game](http://0x10c.com/).

## TODO
- disassembler (done, in `dis.py`)
	- rewrite in Cython or C++
- emulator (partially done, in `dis.py`)
	- rewrite in Cython or C++
- assembler
	Assemble into object files. These will still be able to contain references to undefined symbols.
- linker
	Link assembled object files and resolve all symbols.
- C compiler
