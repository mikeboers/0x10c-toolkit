
start:
	
	# Allocate 1 word and set it to `1`.
	set X, 1
	jsr malloc
	set [blocks + 0], A
	set [A + 0], 1
	
	# Allocate 2 words, and set them to `2`.
	set X, 2
	jsr malloc
	set [blocks + 1], A
	set [A + 0], 2
	set [A + 1], 2
	
	# Allocate 3 words, and set them to `3`.
	set X, 3
	jsr malloc
	set [blocks + 2], A
	set X, A
	set Y, 3
	set Z, 3
	jsr set_block
	
	# Free the first two blocks.
	set X, [blocks + 1]
	jsr free
	set X, [blocks + 0]
	jsr free
	
	# Allocate another 2 words, and set them to `4`. This will be in the space
	# of the previous allocation of two, but ideally would start in the first
	# allocation.
	set X, 2
	jsr malloc
	set [A + 0], 4
	set [A + 1], 4
	
	set X, [blocks + 2]
	jsr free
	
	set X, 10
	jsr malloc
	set I, 0
	set J, 10
set_loop:
	set [A], I
	add A, 1
	add I, 1
	ifg J, I
		set PC, set_loop

	set X, 1
	jsr malloc
	set [A], 0x9999
	
	
	set PC, exit
	



; malloc takes number of words in X, and returns pointer to start on A.
.GLOBAL malloc
malloc:
	
	; `A` will track the header for a memory block.
	set A, HEAP
	
	; Walk the heap chain until we come to a free block of sufficient size.
_malloc_loop:
	
	ifb [A], 0x8000 ; this block is in use
		set PC, _malloc_next
	ife [A], 0 ; this block is the end
		set PC, _malloc_found
	ifg X, [A] ; this block is too small
		set PC, _malloc_next
	
	; Fall through!
	
_malloc_found:
	
	; If this block is larger than we need, add an empty header.
	ifg [A], X
		jsr _malloc_resize
	
	set [A], X ; Set the length of the block.
	bor [A], 0x8000 ; Set the usage flag on the block.
	add A, 1 ; We want the first word of the block.
	set PC, POP ; Return!

_malloc_next:
	set B, [A]
	and B, 0x7fff
	add A, B
	add A, 1
	set PC, _malloc_loop
	
_malloc_resize:
	set B, A
	add B, X
	add B, 1
	set [B], [A]
	sub [B], X
	sub [B], 1
	set PC, POP




; Free the memory block which contains `[X]`.
.GLOBAL free
free:
	; Generally, we will walk through the chain of allocated blocks looking for
	; the one that contains `[X]`. Once we find it, we will mark it as unused.
	
	set A, HEAP # Tracks the current block header.
	set C, 0 # The previous block header.
	
_free_loop:
	
	; Set B to the position of the next header.
	set B, [A]
	and B, 0x7fff
	add B, A
	add B, 1
	
	ifg B, X ; X is in this block!
		set PC, _free_found
	
	set C, A # Remember the header.
	set A, B
	set PC, _free_loop
	
_free_found:

	and [A], 0x7fff # Mark this block as unused.
	
	ife C, 0 # This is the first block.
		set PC, _free_expand_next
	
	ifb [C], 0x8000 # The previous block is allocated
		set PC, _free_expand_next
	
	# Expand the previous block.
	add [C], 1
	add [C], [A]
	set A, C
	
_free_expand_next:
		
	ife [B], 0 # The next block is the start of unallocated space.
		set PC, _free_expand_last
	
	ifb [B], 0x8000 # The next block is allocated.
		set PC, POP
	
	# Expand into the next block
	add [A], [B]
	add [A], 1
	
	set PC, POP

_free_expand_last:
	# Mark this as the new end of unallocated space
	set [A], 0
	set PC, POP
	
	
	


; Starting at X, sets Y words to the value of Z
set_block:
	set I, X
	set J, X
	add J, Y
set_block_loop:
	set [I], Z
	add I, 1
	ifg J, I
		set PC, set_block_loop
	set PC, POP

; Starting at X, adds up Y words.
sum_block:
	set A, 0
	set I, X
	set J, X
	add J, Y
sum_block_loop:
	add A, [I]
	add I, 1
	ifg J, I
		set PC, sum_block_loop
	set PC, POP
	
	



blocks: dat 0, 0, 0

exit:
	dat 0

	dat 0xdead, 0xbeef
