# PaddleP.asm
# This file implements the Player's Paddle function

	.globl		PaddleP
	
	.text


# Constructor for the PaddleP Class
#
#	Args:
#	 $a0	The address of the Display
#	 $a1	The a box for the Paddle
#
#	Return:
#	 $v0	The address of the new instance
#
#	Usage:
#    code to put the address of the Display into $a0
#    code to put the address of the Box into $a1
#    jal     PaddleP
#	 move $t1, $v0
#
####################################
# Object Structure
#	0-4		The tick function
#	4-8		The reset function
#	8-12	reserved for later function
#	12-16	Display address
#	16-20	Box address
####################################
PaddleP:
	move	$t0, $a0	# start of new PaddleP()
	move	$t1, $a1
	
	# alloc PaddleP
	li      $v0, 9      # sbrk code
	li		$a0, 28		# number of bytes needed
    syscall
    
    # load methods
    la		$t4, tick
    la		$t5, reset
    
    # Setup object
    sw		$t4, 0($v0)
    sw		$t5, 4($v0)
    sw		$t0, 12($v0)
    sw		$t1, 16($v0)
    
    # load box into Display
    sw		$t1, 24($t0)

	jr		$ra


# Moves the paddle and redraws it
#
#	Args:
#	 $a0	The address of the paddle
#	 $a1	The movement in the y
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of the paddle into $a0
#	 li		$a1, 0		# the change in the y
#    lw		$t9, 0($a0)
#    jalr	$t9
#
tick:
# $t0	this
# $t1	Box
# $t2	Display
# $t3	dy
	sub     $sp, $sp, 4     # allocate stack frame - Start of PaddleP.tick
	sw      $ra, 0($sp)     # with return address at 0($sp)

	move	$t0, $a0
	lw		$t1, 16($t0)
	lw		$t2, 12($t0)
	move	$t3, $a1

# $t4	myhi
	lw		$t4, 16($t2)

# $t5	ylo
# $t6	yhi
	lw		$t5, 4($t1)
	add		$t5, $t5, $t3
	lw		$t6, 12($t1)
	add		$t6, $t6, $t5


	# if hit edge return without redraw or move
	bltz	$t5, returnTick
	bgt 	$t6, $t4, returnTick

	# Call display.movebox
	# load args
	lw		$a0, 12($t0)
	lw		$a1, 16($t0)
	li		$a2, 0
	move	$a3, $t3
	
	lw		$t9, 4($a0)
	jalr	$t9

returnTick:
	lw      $ra, 0($sp)     # restore return address
	add     $sp, $sp, 4     # and deallocate it
	jr		$ra



# Reset the paddle's state back to how it was when it started.
#
#	Args:
#	 $a0	The address of the paddle
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of the paddle into $a0
#    lw		$t9, 4($a0)
#    jalr	$t9
#
reset:
	sub     $sp, $sp, 4     # allocate stack frame - Start of PaddleP.reset()
	sw      $ra, 0($sp)     # with return address at 0($sp)
	
	sub     $sp, $sp, 4
	sw      $a0, 0($sp)
	
	# clear the box from the screen
# $a0	display
# $a1	box
	lw		$a1, 16($a0)
	lw		$a0, 12($a0)
	lw		$t9, 8($a0)
	jalr	$t9
	
# $a0	paddle
# $a1	box
	lw		$a0, 0($sp)
	lw		$a1, 16($a0)
	add		$sp, $sp, 4
	
	# reset pos in box
	li		$t0, 0
	lw		$t1, height
	lw		$t2, paddleHeight
	sub		$t1, $t1, $t2
	div		$t1, $t1, 2
    
    sw		$t0, 0($a1)
    sw		$t1, 4($a1)
	
	lw      $ra, 0($sp)     # restore return address
	add     $sp, $sp, 4     # and deallocate it
	jr		$ra
