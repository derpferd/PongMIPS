# Display.asm
# This file implements the Display functions.

	.globl		Display
	
	.data
		tempBox:	.space 20 # This is a temp box for drawing
	
	.text

# Box Struct
####################################
# Object Structure
#	0-4		The x position
#	4-8		The y position
#	8-12	The width of the box
#	12-16	The height of the box
#	16-20	The color of the box
####################################

# Constructor for the Display Class
#
#	Args:
#	 $a0	The width of the display buffer
#	 $a1	The height of the display buffer
#	 $a2	The address of the display buffer
#
#	Return:
#	 $v0	The address of the new instance
#
#	Usage:
#	 li   $a0, 8	# the width
#	 li   $a1, 4	# the height
#    code to put the address of the display buffer into $a2
#    jal     Display
#	 move $t1, $v0
#
####################################
# Object Structure
#	0-4		The drawBox function
#	4-8		The moveBoxFast function
#	8-12	The clearBox function
#	12-16	display width
#	16-20	display height
#	20-24	display buffer address
#	24-28	player box address
#	28-32	computer box address
####################################
Display:
	
	move	$t0, $a0	# start of new Display()
	move	$t1, $a1
	move	$t2, $a2
	
	# alloc Display
	li      $v0, 9      # sbrk code
	li		$a0, 32		# number of bytes needed
    syscall
    
    # load methods
    la		$t3, drawbox
#    la		$t4, movebox
	la		$t4, moveboxfast
    la		$t5, clearBox
    
    # Setup object
    sw		$t3, 0($v0)
    sw		$t4, 4($v0)
    sw		$t5, 8($v0)
    sw		$t0, 12($v0)
    sw		$t1, 16($v0)
    sw		$t2, 20($v0)

	jr		$ra



# Moves a box on the display fast
#
#	Args:
#	 $a0	The address of the display
#	 $a1	The address of the box
#	 $a2	The movement in the x
#	 $a3	The movement in the y
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of display into $a0
#    code to put the address of box into $a1
#	 li		$a2, 8		# the dx
#	 li		$a3, 4		# the dy
#    lw		$t9, 4($a0)
#    jalr	$t9
#
moveboxfast:
	sub     $sp, $sp, 4     # allocate stack frame - Start of Display.moveboxfast
	sw      $ra, 0($sp)     # with return address at 0($sp)


	# draw background where old box was and is no longer needed
	sub     $sp, $sp, 20     # allocate stack frame
	sw      $a0, 0($sp)
	sw      $a1, 4($sp)
	sw      $a2, 8($sp)
	sw      $a3, 12($sp)
	
    # save color
    lw		$t0, 16($a1)
    sw		$t0, 16($sp)
	
moveboxBGY:
	# make temp box for y bg
# $t0	tempbox
	la		$t0, tempBox
    lw		$t1, 0($a1)
    sw		$t1, 0($t0)
    lw		$t1, 4($a1)
    sw		$t1, 4($t0)
    lw		$t1, 8($a1)
    sw		$t1, 8($t0)
    lw		$t1, 12($a1)
    sw		$t1, 12($t0)
	
	bltz	$a3, moveboxBGAtBottom

# draw background at top (dy>0)
moveboxBGAtTop:
	sw		$a3, 12($t0)

	b		moveboxBGYDraw

# draw background at bottom (dy<0)
moveboxBGAtBottom:
	lw		$t1, 4($t0)
	lw		$t2, 12($t0)
	add		$t1, $t1, $t2
	add		$t1, $t1, $a3
	sw		$t1, 4($t0)
	move	$t1, $a3
	mul		$t1, $t1, -1
	sw		$t1, 12($t0)

moveboxBGYDraw:
    # change color
    lw		$t1, bgColor
    sw		$t1, 16($t0)
    
    move	$a1, $t0
    
    jal		drawbox
    
    lw      $a0, 0($sp)
    lw      $a1, 4($sp)
    lw      $a2, 8($sp)
    lw      $a3, 12($sp)
moveboxBGYEnd:

moveboxBGX:
	# make temp box for x bg
# $t0	tempbox
	la		$t0, tempBox
    lw		$t1, 0($a1)
    sw		$t1, 0($t0)
    lw		$t1, 4($a1)
    add		$t1, $t1, $a3
    sw		$t1, 4($t0)
    lw		$t1, 8($a1)
    sw		$t1, 8($t0)
    lw		$t1, 12($a1)
#    add		$t1, $t1, $a3
    sw		$t1, 12($t0)
	
	bltz	$a2, moveboxBGAtRight

# draw background at top (dx>0)
moveboxBGAtLeft:
	sw		$a2, 8($t0)

	b		moveboxBGXDraw

# draw background at bottom (dx<0)
moveboxBGAtRight:
	lw		$t1, 0($t0)
	lw		$t2, 8($t0)
	add		$t1, $t1, $t2
	add		$t1, $t1, $a2
	sw		$t1, 0($t0)
	move	$t1, $a2
	mul		$t1, $t1, -1
	sw		$t1, 8($t0)

moveboxBGXDraw:
    # change color
    lw		$t1, bgColor
    sw		$t1, 16($t0)
    
    move	$a1, $t0
    
    jal		drawbox
    
    lw      $a0, 0($sp)
    lw      $a1, 4($sp)
    lw      $a2, 8($sp)
    lw      $a3, 12($sp)
moveboxBGXEnd:
    
    # reset color
    lw		$t0, 16($sp)
    sw		$t0, 16($a1)
    
    # move box
    lw		$t0, 0($a1)		# move x
    add		$t0, $t0, $a2
    sw		$t0, 0($a1)
    
    lw		$t0, 4($a1)		# move y
    add		$t0, $t0, $a3
    sw		$t0, 4($a1)


moveboxFGY:
	# make temp box
# $t0	tempbox
	la		$t0, tempBox
    lw		$t1, 0($a1)
    sw		$t1, 0($t0)
    lw		$t1, 4($a1)
    sw		$t1, 4($t0)
    lw		$t1, 8($a1)
    sw		$t1, 8($t0)
    lw		$t1, 12($a1)
    sw		$t1, 12($t0)
    lw		$t1, 16($a1)
    sw		$t1, 16($t0)
	
	bgtz	$a3, moveboxFGAtBottom

# draw background at top (dy<0)
moveboxFGAtTop:
	move	$t1, $a3
	mul		$t1, $t1, -1
	sw		$t1, 12($t0)

	b		moveboxFGYDraw

# draw background at bottom (dy>0)
moveboxFGAtBottom:
	lw		$t1, 4($t0)
	lw		$t2, 12($t0)
	add		$t1, $t1, $t2
	sub		$t1, $t1, $a3
	sw		$t1, 4($t0)
	sw		$a3, 12($t0)

moveboxFGYDraw:

    move	$a1, $t0
    jal		drawbox
    
    lw      $a0, 0($sp)
    lw      $a1, 4($sp)
    lw      $a2, 8($sp)
    lw      $a3, 12($sp)
moveboxFGYEnd:


moveboxFGX:
	# make temp box
# $t0	tempbox
	la		$t0, tempBox
    lw		$t1, 0($a1)
    sw		$t1, 0($t0)
    lw		$t1, 4($a1)
    sw		$t1, 4($t0)
    lw		$t1, 8($a1)
    sw		$t1, 8($t0)
    lw		$t1, 12($a1)
    sw		$t1, 12($t0)
    lw		$t1, 16($a1)
    sw		$t1, 16($t0)
	
	bgtz	$a2, moveboxFGAtRight

# draw background at left (dy<0)
moveboxFGAtLeft:
	move	$t1, $a2
	mul		$t1, $t1, -1
	sw		$t1, 8($t0)

	b		moveboxFGXDraw

# draw background at right (dy>0)
moveboxFGAtRight:
	lw		$t1, 0($t0)
	lw		$t2, 8($t0)
	add		$t1, $t1, $t2
	sub		$t1, $t1, $a2
	sw		$t1, 0($t0)
	sw		$a2, 8($t0)

moveboxFGXDraw:
	move	$a1, $t0
	jal		drawbox

moveboxFGXEnd:
    add     $sp, $sp, 20     # and deallocate it

    lw      $ra, 0($sp)     # restore return address
    add     $sp, $sp, 4     # and deallocate it
	jr		$ra


# Moves a box on the display
#
#	Args:
#	 $a0	The address of the display
#	 $a1	The address of the box
#	 $a2	The movement in the x
#	 $a3	The movement in the y
#
#	Return:
#	 none
#
#	Usage:
#	 !!!Do not use this method use moveboxfast instead!!!
#    code to put the address of display into $a0
#    code to put the address of box into $a1
#	 li		$a2, 8		# the x
#	 li		$a3, 4		# the y
#    lw		$t9, 4($a0)
#    jalr	$t9
#
movebox:
    sub     $sp, $sp, 4     # allocate stack frame - Start of Display.movebox
    sw      $ra, 0($sp)     # with return address at 0($sp)
    
    
	# draw background where old box was
    sub     $sp, $sp, 20     # allocate stack frame
    sw      $a0, 0($sp)
    sw      $a1, 4($sp)
    sw      $a2, 8($sp)
    sw      $a3, 12($sp)
    
    # change color
    lw		$t0, 16($a1)
    sw		$t0, 16($sp)
    li		$t1, 0			# !!!HACK!!! this should be the background
    sw		$t1, 16($a1)
    
    jal		drawbox

    lw      $a0, 0($sp)
    lw      $a1, 4($sp)
    lw      $a2, 8($sp)
    lw      $a3, 12($sp)
    
    # reset color
    lw		$t0, 16($sp)
    sw		$t0, 16($a1)
    add     $sp, $sp, 20     # and deallocate it
    
    # move box
    lw		$t0, 0($a1)		# move x
    add		$t0, $t0, $a2
    sw		$t0, 0($a1)
    
    lw		$t0, 4($a1)		# move y
    add		$t0, $t0, $a3
    sw		$t0, 4($a1)

    jal		drawbox

    lw      $ra, 0($sp)     # restore return address
    add     $sp, $sp, 4     # and deallocate it
	jr		$ra


# Draws a box on the display
#
#	Args:
#	 $a0	The address of the Display
#	 $a1	The address of the Box
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of Display into $a0
#    code to put the address of Box into $a1
#    lw      $t9, 0($a0)
#    jalr    $t9
#
drawbox:
	lw		$t0, 0($a1)		# x - start of Display.drawbow(box, display)
	lw		$t1, 4($a1)		# y
	lw		$t2, 8($a1)		# box width
	lw		$t3, 12($a1)	# box height
	
	lw		$t4, 12($a0)	# display width
	lw		$t5, 20($a0)	# display buffer
	
	lw		$t6, 16($a1)	# the box color
	
	li		$t7, 0			# current x
	li		$t8, 0			# current y
	
	blt		$t2, 1, drawBoxLoopEnd
	blt		$t3, 1, drawBoxLoopEnd
	
drawBoxLoop:

	# display[y+cury][x+curx] = color
	move	$t9, $t1	# put posy into index
	add		$t9, $t9, $t8	# add cury
	mul		$t9, $t9, $t4	# mul by the width
	add		$t9, $t9, $t0	# add posx
	add		$t9, $t9, $t7	# add curx
	mul		$t9, $t9, 4		# convert from index to bytes
	add		$t9, $t9, $t5	# add display
	sw		$t6, ($t9)
	
	add		$t7, $t7, 1
	blt 	$t7, $t2, drawBoxLoop
	li		$t7, 0
	add		$t8, $t8, 1
	blt		$t8, $t3, drawBoxLoop
	

drawBoxLoopEnd:
	jr		$ra


# Removes a box on the display
#
#	Args:
#	 $a0	The address of the Display
#	 $a1	The address of the Box
#
#	Return:
#	 none
#
#	Usage:
#    code to put the address of Display into $a0
#    code to put the address of Box into $a1
#    lw      $t9, 8($a0)
#    jalr    $t9
#
clearBox:

    sub     $sp, $sp, 4     # allocate stack frame - Start of Display.movebox
    sw      $ra, 0($sp)     # with return address at 0($sp)
    
    
	# draw background where box was
    sub     $sp, $sp, 8     # allocate stack frame
    sw      $a1, 0($sp)
    # save color
    lw		$t0, 16($a1)
    sw		$t0, 4($sp)
    
    # change color to bgColor
    lw		$t1, bgColor
    sw		$t1, 16($a1)

    jal		drawbox
    
    # replace old color
    lw      $t1, 0($sp)
    lw		$t0, 4($sp)
    sw		$t0, 16($t1)
    add		$sp, $sp, 8

    lw      $ra, 0($sp)     # restore return address
    add     $sp, $sp, 4     # and deallocate it
	jr		$ra
