#only 24-bits 320x240 pixels BMP files are supported
	.eqv	BMP_FILE_SIZE 230454
	.eqv	BYTES_PER_ROW 960
	.eqv	IMAGE_WIDTH 320
	.eqv	IMAGE_HEIGHT 240

	.data
# space for the  320x240 bmp image
	.align	4

result:	.space	2

image:	.space	BMP_FILE_SIZE
fname:	.asciz	"ex.bmp"

	.text
main:
	jal	read_bmp
	jal 	process_image

exit:
	li 	a7, 10
	ecall
# ============================================================================
process_image:
#description: 
#   Processes pixels from left to right, bottom to top, in a loop, and call
#   the get_pixel function to retrieve and display each pixel color.
	addi	sp, sp, -4
	sw	ra, 0(sp)
	addi	sp, sp, -4
	sw	s0, 0(sp)
	addi	sp, sp, -4
	sw	s1, 0(sp)
	addi	sp, sp, -4
	sw	s2, 0(sp)
	addi	sp, sp, -4
	sw	s3, 0(sp)
	addi	sp, sp, -4
	sw	s4, 0(sp)	#pixel color
	

    	# Set up loop counters
    	li	s0, 0   # x Start from the bottom row
	li	s1, 0	# y
	li	s2, IMAGE_WIDTH
	li	s3, IMAGE_HEIGHT
outer_loop:
	bge	s0, s2, outer_loop_end # x iteration
inner_loop:
	bge	s1, s3, inner_loop_end # y iteration
	
	# Call get_pixel function to get the color of the current pixel
	mv	a0, s0		# x coordinate
	mv	a1, s1		# y coordinate
	jal	get_pixel
	bnez	a0, ifnot0
	mv	s4, a0
	jal	process_pixel
	add	s1, s1, a0

	#let printing of pixel be somewhere else
	#mv	a0, s4
	#mv	a1, s0
	#mv	a2, s1
	#jal	print_pixel
ifnot0:
	# restoring state

	
	# inner loop incrementation
	addi	s1, s1, 1
        # Skok do sprawdzenia warunku wewnętrznej pętli
	j	inner_loop

inner_loop_end:
    	# Inkrementacja iteratora zewnętrznej pętli
	addi	s0, s0, 1

    	# Reset iteratora wewnętrznej pętli na wartość początkową
	li	s1, 0

    	# Skok do sprawdzenia warunku zewnętrznej pętli
	j	outer_loop

outer_loop_end:
	lw	s4, 0(sp)
	addi	sp, sp, 4
	lw	s3, 0(sp)
	addi	sp, sp, 4
	lw	s2, 0(sp)
	addi	sp, sp, 4
	lw	s1, 0(sp)
	addi	sp, sp, 4
	lw	s0, 0(sp)
	addi	sp, sp, 4
	lw	ra, 0(sp)
	addi	sp, sp, 4
	jr	ra

# ============================================================================
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	addi	sp, sp, -4		#push $s1
	sw	s1, 0(sp)
#open file
	li	a7, 1024
        la	a0, fname		#file name 
        li	a1, 0		#flags: 0-read file
        ecall
	mv	s1, a0      # save the file descriptor
	
#check for errors - if the file was opened
#...

#read file
	li	a7, 63
	mv	a0, s1
	la	a1, image
	li	a2, BMP_FILE_SIZE
	ecall

#close file
	li	a7, 57
	mv	a0, s1
        ecall
	
	lw	s1, 0(sp)		#restore (pop) s1
	addi	sp, sp, 4
	jr	ra

# ============================================================================
get_pixel:
#description: 
#	returns color of specified pixel
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - 0RGB - pixel color

	la	t1, image		# adress of file offset to pixel array
	addi	t1, t1, 10
	lw	t2, (t1)		# file offset to pixel array in $t2
	la	t1, image		# adress of bitmap
	add	t2, t1, t2		# adress of pixel array in $t2
	
	# pixel address calculation
	li	t4, BYTES_PER_ROW
	mul	t1, a1, t4		# t1 = y*BYTES_PER_ROW
	mv	t3, a0		
	slli	a0, a0, 1
	add	t3, t3, a0		# $t3= 3*x
	add	t1, t1, t3		# $t1 = 3x + y*BYTES_PER_ROW
	add	t2, t2, t1		# pixel address 
	
	# get color
	lbu	a0, (t2)			# load B
	lbu	t1, 1(t2)		# load G
	slli	t1, t1,8
	or	a0, a0, t1
	lbu	t1, 2(t2)		# load R
        slli	t1, t1, 16
	or	a0, a0, t1
					
	jr	ra

# ============================================================================
print_pixel:
#description: 
#	print color, x coordinate and y coordinate  of specific pixel
#arguments:
#	a0 - color
#	a1 - x coordinate
#	a2 - y coordinate - (0,0) - bottom left corner
#return value:
#	none

	addi	sp, sp, -4		#push $ra
	sw	ra, 0(sp)

	li	a7, 1
	ecall
	
	mv	t0, a1
	mv	t1, a2

	# Print a space for separation
	li	a0, 32
	li	a7, 11
	ecall

	# Print x coords
	mv	a0, a1
	li	a7, 1
	ecall

	# Print a space for separation
	li	a0, 32
	li	a7, 11
	ecall

	# Print y coords
	mv	a0, a2
	li	a7, 1
	ecall

	# Print a newline character to move to the next row
	li	a0, 10
	li	a7, 11
	ecall

	lw	ra, 0(sp)		#restore (pop) ra
	addi	sp, sp, 4
	jr	ra

# ============================================================================
process_pixel:
#description: 
#	processes black pixel, analyse if it is a bottom left part of marker
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - number of pixels to jump over
	addi	sp, sp, -4
	sw	ra, 0(sp)
	addi	sp, sp, -4
	sw	s0, 0(sp)	
	addi	sp, sp, -4
	sw	s1, 0(sp)
	addi	sp, sp, -4
	sw	s2, 0(sp)	# return value storage - height_minus_one
	addi	sp, sp, -4
	sw	s3, 0(sp)	# wing_length_minus_one

	li	s2, 0		#default return value
	#save coordinates
	mv	s0, s0		# x coordinate
	mv	s1, a1		# y coordinate
process_pixel_conditions:
	li	t0, IMAGE_WIDTH
	li	t1, IMAGE_HEIGHT
	addi	t0, t0, -1
	addi	t1, t1, -1
	# check if is last height or last width
	beq	s0, t0, process_pixel_return_zero
	beq	s1, t1, process_pixel_return_zero
	# check if previous pixel (x, y-1) is black, if y = 0 than we do not check it and go over it
	beqz	s1, start_analysing
	mv	t1, s1
	addi	t1, t1, -1
	mv	a1, t1
	mv	a0, s0
	jal	get_pixel
	beqz	a0, process_pixel_return_zero
	##
	#b	print_if_is_proper
	##
start_analysing:
	# check height
	mv	a0, s0
	mv	a1, s1
	jal	check_height
	mv	s2, a0		# store height_minus_one
	beqz	a0, process_pixel_return_zero
	# check wing width
	mv	a0, s0
	mv	a1, s1
	jal	check_wing
	mv	s3, a0
	bge	s3, s2, process_pixel_return_zero

	#b	process_pixel_exit

####
print_if_is_proper:
	mv	a0, s0
	mv	a1, s1
	jal	get_pixel
	mv	a1, s0
	mv	a2, s1
	jal	print_pixel
	jal	process_pixel_exit
####	
	
process_pixel_return_zero:
	li	s2, 0
process_pixel_exit:
	mv	a0, s2
	lw	s3, 0(sp)
	addi	sp, sp, 4
	lw	s2, 0(sp)
	addi	sp, sp, 4
	lw	s1, 0(sp)
	addi	sp, sp, 4
	lw	s0, 0(sp)
	addi	sp, sp, 4
	lw	ra, 0(sp)
	addi	sp, sp, 4
	jr	ra

# ============================================================================
check_height:
#description: 
#	processes pixels over given coords, analyse how many of them are black
#arguments:
#	a0 - x
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - number of pixels to jump over
	addi	sp, sp, -4
	sw	ra, 0(sp)
	addi	sp, sp, -4
	sw	s0, 0(sp)	# x coordinate	
	addi	sp, sp, -4
	sw	s1, 0(sp)	# y coordinate
	addi	sp, sp, -4
	sw	s2, 0(sp)	# return value storage - height_minus_one
	addi	sp, sp, -4
	sw	s3, 0(sp)	# loop stop value

	mv	s0, a0
	mv	s1, a1		
	addi	s1, s1, 1
	li	s2, 0
	li	s3, IMAGE_HEIGHT
check_height_loop:
	beq	s1, s3, check_height_end_loop
	mv	a0, s0
	mv	a1, s1
	jal	get_pixel
	bnez	a0, check_height_end_loop
	addi	s2, s2, 1
	addi	s1, s1, 1
	b	check_height_loop
	
check_height_end_loop:
	mv	a0, s2
	lw	s3, 0(sp)
	addi	sp, sp, 4
	lw	s2, 0(sp)
	addi	sp, sp, 4
	lw	s1, 0(sp)
	addi	sp, sp, 4
	lw	s0, 0(sp)
	addi	sp, sp, 4
	lw	ra, 0(sp)
	addi	sp, sp, 4
	jr	ra
# ============================================================================
check_wing:
#description: 
#	processes pixels on the right of given pixel, analyse how many of them are black
#arguments:
#	a0 - x
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - number of black pixels on the right hand side
	addi	sp, sp, -4
	sw	ra, 0(sp)
	addi	sp, sp, -4
	sw	s0, 0(sp)	# x coordinate	
	addi	sp, sp, -4
	sw	s1, 0(sp)	# y coordinate
	addi	sp, sp, -4
	sw	s2, 0(sp)	# return value storage - wing_legth_minus_one
	addi	sp, sp, -4
	sw	s3, 0(sp)	# loop stop value

	mv	s0, a0
	mv	s1, a1		
	addi	s0, s0, 1
	li	s2, 0
	li	s3, IMAGE_WIDTH
check_wing_loop:
	beq	s0, s3, check_wing_end_loop
	mv	a0, s0
	mv	a1, s1
	jal	get_pixel
	bnez	a0, check_wing_end_loop
	addi	s2, s2, 1
	addi	s0, s0, 1
	b	check_wing_loop
	
check_wing_end_loop:
	mv	a0, s2
	lw	s3, 0(sp)
	addi	sp, sp, 4
	lw	s2, 0(sp)
	addi	sp, sp, 4
	lw	s1, 0(sp)
	addi	sp, sp, 4
	lw	s0, 0(sp)
	addi	sp, sp, 4
	lw	ra, 0(sp)
	addi	sp, sp, 4
	jr	ra
# ============================================================================
check_rectange:
#description: 
#	processes black pixel, analyse if it is a bottom left part of marker
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - number of pixels to jump over
# ============================================================================
check_remaining_rectangle_part:
#description: 
#	processes black pixel, analyse if it is a bottom left part of marker
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - number of pixels to jump over
# ============================================================================
check_line:
#description: 
#	processes black pixel, analyse if it is a bottom left part of marker
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - number of pixels to jump over
# ============================================================================