# Ball.asm
# This file implements the Ball functions.

	.globl		Ball
	
	.data
		newLine:	.asciiz "\n"
		maxV:		.float 4.0
		initVX:		.float 3.0
		initVY:		.float 0.0
	
	.text


# Constructor for the Ball Class
#
#	Args:
#	 $a0	The address of the Display
#	 $a1	The a box for the Ball
#
#	Return:
#	 $v0	The address of the new instance
#
#	Usage:
#    code to put the address of the Display into $a0
#    code to put the address of the Box into $a1
#    jal     Ball
#	 move $t1, $v0
#
####################################
# Object Structure
#	0-4		The tick function
#	4-8		The reset function
#	8-12	Hit x side (-1 for left and 1 for right)
#	12-16	Display address
#	16-20	Box address
#	20-24	The x velocity (float)
#	24-28	The y velocity (float)
#	28-32	The real x pos (float)
#	32-36	The real y pos (float)
####################################
Ball:
	move	$t3, $a0	# start of new Ball()
	move	$t4, $a1

	lwc1	$f0, initVX
	lwc1	$f1, initVY
	
	li		$t2, 0
	
	# alloc Ball
	li      $v0, 9      # sbrk code
	li		$a0, 36		# number of bytes needed
    syscall
    
    # load methods
    la		$t0, tick
    la		$t1, reset
    
    # load pos
	lwc1	$f2, 0($t4)
	cvt.s.w	$f2, $f2
	lwc1	$f3, 4($t4)
	cvt.s.w	$f3, $f3
    
    # Setup object
    sw		$t0, 0($v0)
    sw		$t1, 4($v0)
    sw		$t2, 8($v0)
    sw		$t3, 12($v0)
    sw		$t4, 16($v0)
    swc1	$f0, 20($v0)
    swc1	$f1, 24($v0)
    swc1	$f2, 28($v0)
    swc1	$f3, 32($v0)

	jr		$ra

# Moves the ball and redraws it.
#
#	Args:
#	 $a0	The address of the ball
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of the ball into $a0
#    lw		$t9, 0($a0)
#    jalr	$t9
#
tick:
# $t0	this
# $t1	Box
# $s0	Display
# $f0	vx
# $f1	vy
# $f2	pos x
# $f3	pos y
	sub     $sp, $sp, 24     # allocate stack frame - Start of Ball.tick
	sw      $ra, 0($sp)     # with return address at 0($sp)
	sw		$s0, 4($sp)
	sw		$s1, 8($sp)
	sw		$s2, 12($sp)
	sw		$s3, 16($sp)
	sw		$s4, 20($sp)

	move	$t0, $a0
	
	# reset hit to 0
	li		$t1, 0
	sw		$t1, 8($t0)
	
	# load vars
	lw		$t1, 16($t0)
	lw		$s0, 12($t0)
	lwc1	$f0, 20($t0)
	lwc1	$f1, 24($t0)
	lwc1	$f2, 28($t0)
	lwc1	$f3, 32($t0)
    
	# convert real pos to ints
	
# $t6	xlo
# $t8	ylo
	add.s	$f2, $f2, $f0	# float xlo
	add.s	$f3, $f3, $f1	# float ylo
	
	cvt.w.s	$f2, $f2
	cvt.w.s	$f3, $f3
	
	mfc1	$t6, $f2
	mfc1	$t8, $f3
	

# $t4	mxhi
# $t5	myhi

	lw		$t4, 12($s0)
	lw		$t5, 16($s0)

# $t6	xlo
# $t7	xhi
# $t8	ylo
# $t9	yhi
	
#	lw		$t6, 0($t1)		# x
#	add		$t6, $t6, $t2
	lw		$t7, 8($t1)
	add		$t7, $t7, $t6
	
#	lw		$t8, 4($t1)		# y
#	add		$t8, $t8, $t3
	lw		$t9, 12($t1)
	add		$t9, $t9, $t8
	
	
#	move	$a0, $t9
#	li		$v0, 1
#	syscall
#	move	$a0, $t5
#	li		$v0, 1
#	syscall
#	la		$a0, newLine
#	li		$v0, 4
#	syscall
	
	li		$t1, -1
	sw		$t1, 8($t0)
	
	bltz	$t6, hitx
	
	li		$t1, 1
	sw		$t1, 8($t0)
	
	bgt 	$t7, $t4, hitx
	
	li		$t1, 0
	sw		$t1, 8($t0)

	
# $s1	pbox
# $s2	phi
# $s3	tmp
	# check if hit paddle boxes

	# player
	lw		$s1, 24($s0)	# p box
	lw		$s2, 0($s1)		# p x
	lw		$s3, 8($s1)		# p width
	add		$s2, $s2, $s3	# p hi
	
	bge		$t6, $s2, nohittoc
# $s2	tmp
# $s3	pylo
# $s4	pyhi
	lw		$s3, 4($s1)		# p y lo
	
	blt		$t9, $s3, nohitx
	
	lw		$s4, 12($s1)	# p height
	add		$s4, $s4, $s3	# p y hi
	
	bgt		$t8, $s4, nohitx
	
	# change vy
	
	# find middle of ball
# $f8	middle of ball
	add		$s2, $t8, $t9
	mtc1	$s2, $f8
	cvt.s.w	$f8, $f8
	li		$s2, 1073741824	# 2.0
	mtc1	$s2, $f7
	div.s	$f8, $f8, $f7
# $f8	length below paddle
	mtc1	$s3, $f7
	cvt.s.w	$f7, $f7
	sub.s	$f8, $f8, $f7
# $f8	percent below paddle
	lw		$s4, 12($s1)	# p height
	mtc1	$s4, $f7
	cvt.s.w	$f7, $f7
	div.s	$f8, $f8, $f7
	
# $f8	percent below middle of paddle
	li		$s2, 1056964608	# 0.5
	mtc1	$s2, $f7
	sub.s	$f8, $f8, $f7
	
	lwc1	$f9, maxV
	mul.s	$f1, $f8, $f9
	swc1	$f1, 24($t0)
	
	
#	mov.s	$f12, $f1
#	li		$v0, 2
#	syscall
#	la		$a0, newLine
#	li		$v0, 4
#	syscall
	
	b		hitx

nohittoc:
# $s1	cbox
# $s2	clo
	# computer
	lw		$s1, 28($s0)	# c box
	lw		$s2, 0($s1)		# c lo

	ble		$t7, $s2, nohitx
# $s2	tmp
# $s3	cylo
# $s4	cyhi
	lw		$s3, 4($s1)		# c y lo
	
	blt		$t9, $s3, nohitx
	
	lw		$s4, 12($s1)	# c height
	add		$s4, $s4, $s3	# c y hi
	
	bgt		$t8, $s4, nohitx
	
	
	# change vy
	
	# find middle of ball
# $f8	middle of ball
	add		$s2, $t8, $t9
	mtc1	$s2, $f8
	cvt.s.w	$f8, $f8
	li		$s2, 1073741824	# 2.0
	mtc1	$s2, $f7
	div.s	$f8, $f8, $f7
# $f8	length below paddle
	mtc1	$s3, $f7
	cvt.s.w	$f7, $f7
	sub.s	$f8, $f8, $f7
# $f8	percent below paddle
	lw		$s4, 12($s1)	# p height
	mtc1	$s4, $f7
	cvt.s.w	$f7, $f7
	div.s	$f8, $f8, $f7
	
# $f8	percent below middle of paddle
	li		$s2, 1056964608	# 0.5
	mtc1	$s2, $f7
	sub.s	$f8, $f8, $f7
	
	lwc1	$f9, maxV
	mul.s	$f1, $f8, $f9
	swc1	$f1, 24($t0)
	
	
#	mov.s	$f12, $f1
#	li		$v0, 2
#	syscall
#	la		$a0, newLine
#	li		$v0, 4
#	syscall
	
	b		hitx

	# hit x
hitx:
#	mul		$t2, $t2, -1
#	sw		$t2, 20($t0)
	li		$s1, -1
	mtc1	$s1, $f9
	cvt.s.w	$f9, $f9
	mul.s	$f0, $f0, $f9
	swc1	$f0, 20($t0)
	
nohitx:
endhitx:




	bltz	$t8, hity
	bgt 	$t9, $t5, hity
	b		nohity
	# hit y
hity:
#	mul		$t3, $t3, -1
#	sw		$t3, 24($t0)
	li		$s1, -1
	mtc1	$s1, $f9
	cvt.s.w	$f9, $f9
	mul.s	$f1, $f1, $f9
	swc1	$f1, 24($t0)

nohity:

    # move real vars
# $t2	old x
# $t3	old y
# $t4	new x & diff x
# $t5	new y & diff y

	lwc1	$f2, 28($t0)
	lwc1	$f3, 32($t0)
	cvt.w.s	$f2, $f2
	cvt.w.s	$f3, $f3
	mfc1	$t2, $f2
	mfc1	$t3, $f3

	lwc1	$f0, 20($t0)
	lwc1	$f1, 24($t0)
	lwc1	$f2, 28($t0)
	lwc1	$f3, 32($t0)
	add.s	$f2, $f2, $f0	# float xlo
	add.s	$f3, $f3, $f1	# float ylo
	swc1	$f2, 28($t0)
	swc1	$f3, 32($t0)
	
	# diff real vars
	cvt.w.s	$f2, $f2
	cvt.w.s	$f3, $f3
	mfc1	$t4, $f2
	mfc1	$t5, $f3
	
	sub		$t4, $t4, $t2
	sub		$t5, $t5, $t3
	
    # cal diff between old and new positions

	# Call display.movebox
	# load args
	lw		$a0, 12($t0)
	lw		$a1, 16($t0)
	move	$a2, $t4
	move	$a3, $t5
	
	lw		$t9, 4($a0)
	jalr	$t9

	lw		$s0, 4($sp)
	lw		$s1, 8($sp)
	lw		$s2, 12($sp)
	lw		$s3, 16($sp)
	lw		$s4, 20($sp)
	lw      $ra, 0($sp)     # restore return address
	add     $sp, $sp, 24     # and deallocate it
	jr		$ra


# Reset the ball's state back to how it was when it started.
#
#	Args:
#	 $a0	The address of the ball
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of the ball into $a0
#    lw		$t9, 4($a0)
#    jalr	$t9
#
reset:
	sub     $sp, $sp, 4     # allocate stack frame - Start of Ball.reset()
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
	
# $a0	ball
# $a1	box
	lw		$a0, 0($sp)
	lw		$a1, 16($a0)
	add		$sp, $sp, 4
	
	# reset pos and v to defaults
	
	lwc1	$f0, initVX
	lwc1	$f1, initVY
	
	li		$t2, 0
	
	# reset pos in box
	li		$t0, 4
	li		$t1, 30
    
    sw		$t0, 0($a1)
    sw		$t1, 4($a1)
    
    # load pos
	lwc1	$f2, 0($a1)
	cvt.s.w	$f2, $f2
	lwc1	$f3, 4($a1)
	cvt.s.w	$f3, $f3
    
    sw		$t2, 8($a0)
    swc1	$f0, 20($a0)
    swc1	$f1, 24($a0)
    swc1	$f2, 28($a0)
    swc1	$f3, 32($a0)
	
	lw      $ra, 0($sp)     # restore return address
	add     $sp, $sp, 4     # and deallocate it
	jr		$ra
