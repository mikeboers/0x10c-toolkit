# 0x10c Toolkit

This repo contains my tools for experimenting with [the DCPU-16 spec](http://0x10c.com/doc/dcpu-16.txt) for [the upcoming 0x10c game](http://0x10c.com/).

## TODO

- pull in examples from https://github.com/jtauber/DCPU-16-Examples
- look for more TODOs http://dwilliamson.github.com/
- https://github.com/noname22/dtools/

√ disassembler script
√ running script
√ assembling script
√ linking script

- incorperate normal assembler syntax
	- appears to be intel/MASM/NASM syntax
	- see:
		- http://en.wikipedia.org/wiki/X86_assembly_language#Syntax
		- http://en.wikibooks.org/wiki/X86_Assembly/FASM_Syntax
	
	- FASM:
		- anonymous labels (@@, @f, @b)
		- global vs local labels (starting with period)
			global:
			.local:
		
			can reference like "global.local"
		- macro <name> <parameters> { code }
			
	- NASM:
		- %define newline 0xA
		- %define func(a, b) ((a) * (b) + 2)
	
	- GAS:
		- comments can start with any of #!;@|
	
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

- consider adding label offsets to registers: [A + data]
	This would be handy if we are iterating across some words located at `data`.
	Would be handy if we could swap out nearly any number for a label.

√ abstract offsets to a sequence of numbers, labels, and registers, where you
  can have upto 1 register and up to 1 label, and everything else is determined at link time
  	- no really special treatment needed from the linker: symbols are added on
	  top of hard-coded offsets
	- all cases:
		√ [A + label]
		√ [A + label + 1]
		√ [label]
		√ [label + 1]
		√ label
		√ label + 1

- be able to have negative labels and offsets, in addition to multiple labels
	set A, two - one
	- negative offsets are taken %2^16

- start utils module
	- hex stream normalizer
	- comment stripping normalizer
	- value parsing?

- convert scripts into setuptools entrypoints

- alloc.asm has a bug: unallocated blocks of length 0 encode to 0, which flags
  the start of fresh heap. Headers should track the length to the next header
  (what it does now, but +1).

- assembler directives:
	√ .GLOBAL start

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

- monitor colours; see http://0x10co.de/io
	- have a lookup table of colours instead
	- match their font as well; bitmap all the characters

- rewrite OpenGL runner in Cython
	- how to link against OpenGL from Cython so I'm not wasting cycles with my
	  wrapper?
	 
- runner should support multiple CPUs networked together

- GUI in TK, WX, or QT
	- manually edit memory
	- manually edit registers
	- single step
	- PC highlighting in memory

- start a BASIC-like compiler
- start a C-like compiler
	- use http://code.google.com/p/pycparser/
	- uchar/ushort are both unsigned words
	- uint, ulong are 32/64 bits long
	- local variables at the top of functions and control blocks

- negative offsets
- subtracting labels

- implement malloc as a ring-list:
	- the header is the number of words to the next header, unless it is 0 in
	  which case it means to go back to the start of the heap
	- hold onto the last free header to be worked on in a static location
		- for malloc, the location of the next block
		- for free, the location of the freed block
- simplify free:
	- assert that the user pass the first word after the header

- crypto
	- http://en.wikipedia.org/wiki/XXTEA
	- http://en.wikipedia.org/wiki/RC4#Description
	- http://en.wikipedia.org/wiki/International_Data_Encryption_Algorithm
	- http://en.wikipedia.org/wiki/BLAKE_(hash_function)
	- md5?

