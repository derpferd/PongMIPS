# PaddleC.asm
# This file implements the Player's Paddle function

	.globl		PaddleC
	
	.text


# Constructor for the PaddleC Class
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
#    jal     PaddleC
#	 move	$t1, $v0
#
####################################
# Object Structure
#	0-4		The tick function
#	4-8		The reset function
#	8-12	reserved for later function
#	12-16	Display address
#	16-20	Box address
####################################
PaddleC:
	move	$t0, $a0	# start of new PaddleC()
	move	$t1, $a1
	
	# alloc PaddleC
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
    sw		$t1, 28($t0)

	jr		$ra


# Moves the paddle and redraws it
#
#	Args:
#	 $a0	The address of the paddle
#	 $a1	The x of the ball
#	 $a1	The y of the ball
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of the paddle into $a0
#	 li		$a1, 0		# the x of the ball
#	 li		$a1, 0		# the y of the ball
#    lw		$t9, 0($a0)
#    jalr	$t9
#
tick:
# $t0	this
# $t1	Box
# $t2	Display
# $t3	x
# $t4	y
	sub     $sp, $sp, 4     # allocate stack frame - Start of PaddleC.tick
	sw      $ra, 0($sp)     # with return address at 0($sp)

	move	$t0, $a0
	lw		$t1, 16($t0)
	lw		$t2, 12($t0)
	move	$t3, $a1
	move	$t4, $a2

# $t6	ylo before move
# $t7	yhi before move
	lw		$t6, 4($t1)
	lw		$t7, 12($t1)
	add		$t7, $t7, $t6

	# cal good move
# $t8	center of paddle
	sub		$t8, $t7, $t6
	div		$t8, $t8, 2
	add		$t8, $t8, $t6


	sub		$t9, $t8, $t4
# $t3	temp var
# $t4	x reach
	# end if out of x reach
	lw		$t4, 12($t2)
#	mul		$t4, $t4, 5
#	div		$t4, $t4, 4
	sub		$t3, $t3, $t4

	lwc1	$f0, hardness
	sqrt.s	$f0, $f0
	lwc1	$f1, 12($t2)
	cvt.s.w	$f1, $f1
	mul.s	$f0, $f0, $f1
	cvt.w.s	$f0, $f0
	mfc1	$t4, $f0
	
	mul		$t4, $t4, -1
	
	blt		$t3, $t4, returnTick

	# move if in y reach
# $t4	y reach
	lw		$t3, paddleHeight
	sub		$t3, $t3, 2
	div		$t3, $t3, 2
	mtc1	$t3, $f1
	lwc1	$f0, hardness
	cvt.s.w	$f1, $f1
	mul.s	$f0, $f1, $f0
	cvt.w.s	$f0, $f0
	mfc1	$t4, $f0
	
	bgt		$t9, $t4, goUp
	mul		$t4, $t4, -1
	bgt		$t9, $t4, returnTick

	li		$t8, 2
	b		goEnd
goUp:
	li		$t8, -2
goEnd:
	
# $t8	dy
	add		$t6, $t6, $t8
	add		$t7, $t7, $t8

# $t5	myhi
	lw		$t5, 16($t2)

	# if hit edge return without redraw or move
	bltz	$t6, returnTick
	bgt 	$t7, $t5, returnTick

	# Call display.moveboxfast
	# load args
	lw		$a0, 12($t0)
	lw		$a1, 16($t0)
	li		$a2, 0
	move	$a3, $t8
	
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
	sub     $sp, $sp, 4     # allocate stack frame - Start of PaddleC.reset()
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
    lw		$t0, width
    sub		$t0, $t0, 4
	lw		$t1, height
	lw		$t2, paddleHeight
	sub		$t1, $t1, $t2
	div		$t1, $t1, 2
    
    sw		$t0, 0($a1)
    sw		$t1, 4($a1)
	
	lw      $ra, 0($sp)     # restore return address
	add     $sp, $sp, 4     # and deallocate it
	jr		$ra
