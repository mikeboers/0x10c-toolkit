- pull in examples from https://github.com/jtauber/DCPU-16-Examples
- look for more TODOs http://dwilliamson.github.com/
- https://github.com/noname22/dtools/
- http://pastie.org/pastes/3772655/text?key=xw0dmiwx5khzoagoemyww
- http://0x10cwiki.com/wiki/DCPU-16#cite_note-leakspec-1

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

- move font.png into some resource directory and make sure setup.py includes it

- how do deal with short labels?
	It may not be all that important to deal with, as it only really
	benifits jumps to the first 0x1f words of code.

- optimize
	- easly binding Cython everywhere

- be able to have negative labels and offsets, in addition to multiple labels
	set A, two - one
	- negative offsets are taken %2^16

- start utils module
	- hex stream normalizer
	- comment stripping normalizer
	- value parsing?

- alloc.asm has a bug: unallocated blocks of length 0 encode to 0, which flags
  the start of fresh heap. Headers should track the length to the next header
  (what it does now, but +1).
  	- free should assume it was given the first word
	- xfree does not

- assembler directives:
	.macro name -> .mend
	.fill count value
	.zero count

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

- fix compiling for linux
	 
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

- .define CONSTANT value
	- predefined VIDEO, KEYBOARD, RADIO (eventually)
	
- split run.py into EmulatorApp and CPUWindow so that we may have multiple CPUS
  running at the same time

- runner should automatically compile/link files
	- .dasm16, .dasm, or .asm are assembly
	- .dobj16, .dobj, or .obj are objects
	- .dhex16, .dhex, or .hex are final linked code

- force textmate icon

- make tool to conform syntax to other established convensions
	- expand all macros and constants
	- labels with prefixed ':'
	
- crypto
	- http://en.wikipedia.org/wiki/XXTEA
	- http://en.wikipedia.org/wiki/RC4#Description
	- http://en.wikipedia.org/wiki/International_Data_Encryption_Algorithm
	- http://en.wikipedia.org/wiki/BLAKE_(hash_function)
	- md5?

