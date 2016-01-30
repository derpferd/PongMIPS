
	.globl main
	.globl white
	.globl black
	.globl bgColor
	.globl paddleHeight
	.globl hardness
	.globl width
	.globl height
	
	.data
#		width:	.word 96	# This is the width of the display buffer
#		height:	.word 64	# This is the height of the display buffer
		width:	.word 192	# This is the width of the display buffer
		height:	.word 128	# This is the height of the display buffer
		
		paddleHeight: .word	28
		hardness: .float 1.0	# This value must be between 0.0(easyest) and 1.0(hardest)
								# easyest = 0.08 (you should not go below this)
								# hardest = 1.0
		
		# Colors
		white:	.word -1
		black:	.word 0
		pink:	.word 16724889
		red:	.word 16711680
		green:	.word 2517550
		
		# Color properties
#		bgColor:	.word 2517550	# black
		bgColor:	.word 0	# black
		
		# MSGs
		cLosesMsg:	.asciiz "You win!!!"
		pLosesMsg:	.asciiz "The Computer bested you. :P"
		newLine:	.asciiz "\n"
	
	.text

# all $t's are temp vars
# $s0	display buffer
# $s1	Display
# $s2	Clock
# $s3	Ball
# $s4	PaddleP
# $s5	PaddleC
# $s6	Input
# $s7	Temp var needed over calls (ex. a for loop count)
main:
    
    # Figure number of bytes needed for display
    lw		$t0, width
    lw		$t1, height
    mul		$a0, $t0, $t1	# Get the area
    mul		$a0, $a0, 4		# # of pixel * 4 = bytes

	# alloc Display Buffer - THIS MUST BE THE FIRST ALLOC
	li      $v0, 9      # sbrk code
    syscall
    move	$s0, $v0	# set $s0 to the display buffer
    
    # alloc Display
    # $s1 = new Display(width, height, display_buf)
	move	$a0, $t0
	move	$a1, $t1
	move	$a2, $s0
    jal     Display
	move	$s1, $v0
    
	# alloc Clock
	# $s2 = new Clock(17)
#	li		$a0, 17		# 60 FPS
#	li		$a0, 1000	# 1 FPS
	li		$a0, 30
	jal		Clock
	move	$s2, $v0
	
	# alloc Input
	# $s6 = new Input()
	jal		Input
	move	$s6, $v0

	# alloc BallBox
	# $t9 = new Box(0, 0, 2, 2, White)
	li      $v0, 9      # sbrk code
	li		$a0, 20		# number of bytes needed
    syscall
    move	$a1, $v0
    
	li		$t2, 4
	li		$t3, 4
	lw		$t4, white
    
    sw		$t2, 8($a1)
    sw		$t3, 12($a1)
    sw		$t4, 16($a1)
    # end alloc BallBox
    
    # alloc Ball
    # $s3 = new Ball(Display, BallBox)
    move	$a0, $s1
    jal		Ball
    move	$s3, $v0
    

	# alloc PaddlePBox
	# $t9 = new Box(0, 0, 4, paddleHeight, White)
	li      $v0, 9      # sbrk code
	li		$a0, 20		# number of bytes needed
    syscall
    move	$a1, $v0
    
	li		$t2, 4
	lw		$t3, paddleHeight
	lw		$t4, red
    
    sw		$t2, 8($a1)
    sw		$t3, 12($a1)
    sw		$t4, 16($a1)
    # end alloc PaddlePBox
    
    # alloc PaddleP
    # $s4 = new PaddleP(Display, BallBox)
    move	$a0, $s1
    jal		PaddleP
    move	$s4, $v0
    
    
	# alloc PaddleCBox
	# $a1 = new Box(0, 0, 2, 2, White)
	li      $v0, 9      # sbrk code
	li		$a0, 20		# number of bytes needed
    syscall
    move	$a1, $v0

	li		$t2, 4
	lw		$t3, paddleHeight
	lw		$t4, red
    
    sw		$t2, 8($a1)
    sw		$t3, 12($a1)
    sw		$t4, 16($a1)
    # end alloc PaddleCBox
    
    # alloc PaddleC
    # $s5 = new PaddleC(Display, BallBox)
    move	$a0, $s1
    jal		PaddleC
	move	$s5, $v0

startGame:
    # clear the ball
    # (Ball)$s3.reset()
	move	$a0, $s3
	lw		$t9, 4($a0)
	jalr	$t9
    
    # clear the paddles
    # (Paddle)$s4.reset()
	move	$a0, $s4
	lw		$t9, 4($a0)
	jalr	$t9
    # (Paddle)$s5.reset()
	move	$a0, $s5
	lw		$t9, 4($a0)
	jalr	$t9


    # draw the ball for the first time
	# (Display)$s1.draw($s3.box)
	lw		$a1, 16($s3)	# $s3.box
	move	$a0, $s1
	lw		$t9, 0($a0)
	jalr	$t9
    
    # draw the paddles for the first time
	# (Display)$s1.draw($s4.box)
	lw		$a1, 16($s4)	# $s4.box
	move	$a0, $s1
	lw		$t9, 0($a0)
	jalr	$t9
	
	# (Display)$s1.draw($s5.box)
	lw		$a1, 16($s5)	# $s5.box
	move	$a0, $s1
	lw		$t9, 0($a0)
	jalr	$t9
    
	# Game Loop
gameLoopTop:

	# (Ball)$s3.tick()
	move	$a0, $s3
	lw		$t9, 0($a0)
	jalr	$t9
	
	# (Ball)$s3.hitX?
	lw		$t9, 8($s3)
	
	bltz	$t9, pLoses
	bgtz	$t9, cLoses
	
	# (Paddle)$s5.tick(ballx, bally)
	lw		$t0, 16($s3)
	lw		$a1, 0($t0)
	lw		$a2, 4($t0)
	move	$a0, $s5
	lw		$t9, 0($a0)
	jalr	$t9
	
	# (Clock)$s2.sleep()
	move	$a0, $s2
	lw      $t9, 0($a0)
	jalr    $t9

	# (Input)$s6.tick()
	move	$a0, $s6
	lw		$t9, 0($a0)
	jalr	$t9

	# if no input jump to top
	lb		$t8, 20($s6)
	beqz	$t8, gameLoopTop
	
	# (Input)$s6.pop()
	move	$a0, $s6
    lw		$t9, 4($a0)
    jalr	$t9
	li		$t7, 113	# q for quit
	beq 	$v0, $t7, quit
	
	li		$t7, 119	# w for up
	beq		$v0, $t7, wkey
	
	li		$t7, 115	# s for down
	beq		$v0, $t7, skey
	
	b		endkeys

wkey:
	li		$a1, -2
	b		movepaddle
skey:
	li		$a1, 2
movepaddle:
	# (Paddle)$s4.tick(dy)
	move	$a0, $s4
	lw		$t9, 0($a0)
	jalr	$t9
	
endkeys:

	b		gameLoopTop

cLoses:
	la		$a0, cLosesMsg
	li		$v0, 4
	syscall	
	la		$a0, newLine
	li		$v0, 4
	syscall

	b		gameLoopEnd
pLoses:
	la		$a0, pLosesMsg
	li		$v0, 4
	syscall
	la		$a0, newLine
	li		$v0, 4
	syscall

gameLoopEnd:
	
	b		startGame

quit:
    
    li      $v0, 10         # terminate the program
    syscall
