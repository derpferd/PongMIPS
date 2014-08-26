# Input.asm
# This file implements the Input functions.

	.globl Input
	
	.data
		inputFlag:	.word 4294901760
		inputAddr:	.word 4294901764
		bufferSize:	.word 16384
	
	.text

# Constructor for the Input class
#
#	Args:
#	 None
#
#	Return:
#	 $v0	The address of the new instance
#
#	Usage:
#    jal     Input
#	 move	 $t1, $v0
#
####################################
# Object Structure
#	0-4		The tick function
#	4-8		The pop function
#	8-12	The reset function
#	12-16	The address of the buffer
#	16-20	The current pointer into the buffer
#	20-21	The hasChars flag
####################################
Input:
	move	$t0, $a0	# start of new Input()
	move	$t1, $a1
	move	$t2, $a2
	
    # alloc Buffer
    li		$v0, 9
    lw		$a0, bufferSize
    syscall
    move	$t3, $v0
    
	# alloc Input
	li      $v0, 9      # sbrk code
	li		$a0, 24		# number of bytes needed
    syscall
    
    # load methods
    la		$t0, tick
    la		$t1, pop
    la		$t2, reset
    
    li		$t4, 0
    
    # Setup object
    sw		$t0, 0($v0)
    sw		$t1, 4($v0)
    sw		$t2, 8($v0)
    sw		$t3, 12($v0)
    sw		$t3, 16($v0)
    sb		$t4, 20($v0)

	jr		$ra


# Adds input to buffer if there is any.
#
#	Args:
#	 $a0	The address of the Input class
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of Input into $a0
#    lw		$t9, 0($a0)
#    jalr	$t9
#
tick:
# $t0	input flag
	lw		$t0, inputFlag		# start of Input.tick()
	lw		$t0, ($t0)

	beqz	$t0, tickReturn

# $t0	input value
# $t1	cur pointer
	lw		$t0, inputAddr
	lw		$t0, ($t0)
	lw		$t1, 16($a0)
	sw		$t0, ($t1)

	add		$t1, $t1, 4
	sw		$t1, 16($a0)
	
	li		$t2, 1
	sb		$t2, 20($a0)
tickReturn:
	jr		$ra


# Pops the last buffered char and returns it
#
#	Args:
#	 $a0	The address of the Input class
#
#	Return:
#	 $v0	The value poped
#
#	Usage:
#    code to put the address of Input into $a0
#    lw		$t9, 4($a0)
#    jalr	$t9
#
pop:
# $t0	cur pointer
# $t1	base pointer
	lw		$t0, 16($a0)	# start of Input.pop()
	lw		$v0, -4($t0)

	sub		$t0, $t0, 4
	sw		$t0, 16($a0)

	lw		$t1, 12($a0)
	sub		$t2, $t0, $t1

	bnez 	$t2, popReturn
	
	li		$t3, 0
	sb		$t3, 20($a0)
popReturn:
	jr		$ra


# Resets the buffer
#
#	Args:
#	 $a0	The address of the Input class
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of Input into $a0
#    lw		$t9, 8($a0)
#    jalr	$t9
#
reset:
	lw		$t0, 12($a0)
	sw		$t0, 16($a0)
	jr		$ra

