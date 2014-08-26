# Clock.asm
# This file implements the Clock functions.

	.globl		Clock
	
	.text

# Constructor for the Clock class
#
#	Args:
#	 $a0	The frame rate in milliseconds per frame.
#
#	Return:
#	 $v0	The address of the new instance
#
#	Usage:
#	 li   $a0, 17	# 17 is about 60 FPS
#    jal     Clock
#	 move $t1, $v0
#
####################################
# Object Structure
#	0-4		The sleep function
#	4-8		The restart function
#	8-12	The milliseconds per frame
#	12-20	The prevous cycles system time (12) for lo, (16) for hi
####################################
Clock:
    sub     $sp, $sp, 4     # allocate stack frame - Start of new Clock
    sw      $ra, 0($sp)     # with return address at 0($sp)

	move	$t1, $a0	# start of new Clock()
	
	# alloc Clock
	li      $v0, 9      # sbrk code
	li		$a0, 20		# number of bytes needed
    syscall
    
    # load methods
    la		$t2, sleep
    la		$t3, restart
    
    # Setup object
    sw		$t2, 0($v0)
    sw		$t3, 4($v0)
    sw		$t1, 8($v0)

	# This is to set the system time
	move	$a0, $v0
    sub     $sp, $sp, 4     # allocate stack frame
    sw      $a0, 0($sp)     # with CLock at 0($sp)
    
    jal		restart

    lw     	$v0, 0($sp)     # restore CLock
    add     $sp, $sp, 4     # and deallocate it

    lw      $ra, 0($sp)     # restore return address
    add     $sp, $sp, 4     # and deallocate it
	jr		$ra

# Sleep the amount of time remaining from the last cycle to the
# next cycle based on the milliseconds per frame.
#
#	Args:
#	 $a0	Pointer to the Clock object (this)
#
#	Return:
#	 None
#
#	Usage:
#    code to put the address of clock into $a0
#    lw      $t9, 0($a0)
#    jalr    $t9
#
sleep:
	move	$t0, $a0		# Start of Clock.sleep()
	
    li      $v0, 30         # get system time
    syscall
    
    # reset timer
	sw		$a0, 12($t0)	# set lo
	sw		$a1, 16($t0)	# set hi
    
    lw		$t1, 12($t0)
    lw		$t2, 8($t0)
    
    sub		$t3, $a0, $t1	# this is the time we spent
    sub		$t4, $t2, $t3	# this is the time we need to sleep
    
    bltz	$t4, endSleep
    
    move	$a0, $t4
    li		$v0, 32			# sleep
    syscall
    
    
endSleep:
	jr		$ra
	

# Restarts the clock to the current system time
#
#	Args:
#	 $a0	Pointer to the Clock object (this)
#
#	Return:
#	 None
#
#	Usage:
#    code to put the address of clock into $a0
#    lw      $t9, 4($a0)
#    jalr    $t9
#
restart:
	move	$t0, $a0		# Start of Clock.restart()
	
    li      $v0, 30         # get system time
    syscall

	sw		$a0, 12($t0)	# set lo
	sw		$a1, 16($t0)	# set hi

	jr		$ra
