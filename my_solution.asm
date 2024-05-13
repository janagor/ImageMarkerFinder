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
#fname:	.asciz	"example_markers.bmp"
fname:	.space	100

	.text
main:
	la	a0, fname
	jal	read_fname
	la	a0, fname
	jal	edit_fname
	jal	read_bmp
	jal 	process_image

exit:
	li 	a7, 10
	ecall
# ============================================================================
read_fname:
#description: 
#	reads file name from standard input
#arguments:
#	a0 - container for name
#return value:
#	none

	addi	sp, sp, -4
	sw	ra, 0(sp)
	

	li	a7, 8      # Kod syscall dla "read"
    	li	a1, 100     # Maksymalna długość nazwy pliku
    	ecall

	addi	sp, sp, 4
	jr	ra
# ============================================================================
edit_fname:
#description: 
#	replaces newline character ('\n') with end of string character '\0'
#arguments:
#	a0 - container for name
#return value:
#	none
	addi	sp, sp, -4
	sw	ra, 0(sp)
	
	li	t2, 10
	la t0,	fname      # Adres początkowy ciągu znaków
edit_fname_loop:
	lbu	t1, 0(t0)  # Wczytaj kolejny znak
	beqz	t1, edit_fname_done   # Jeśli znak to 0, zakończ pętlę
	beq	t1, t2, edit_fname_replace # Jeśli znak to '\n', zastąp go '\0'
	addi	t0, t0, 1 # Przejdź do następnego znaku
	j	edit_fname_loop
edit_fname_replace:
	sb	zero, 0(t0)  # Zamień znak na '\0'
	addi	t0, t0, 1 # Przejdź do następnego znaku
	j	edit_fname_loop
	edit_fname_done:

	addi	sp, sp, 4
	jr	ra
	
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
	beqz	a0, after_print_result
	mv	t0, a0
	mv	a0, s0 
	mv	a1, s1
	jal	print_found_marker
after_print_result:

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
print_found_marker:
#description: 
#	prints coordinates of a given marker, (0, 0) - upper left corner
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value: none
	addi	sp, sp, -4
	sw	ra, 0(sp)

	mv	t0, a0
	mv	t1, a1
	
	# print x cord
	li	a7, 1
	ecall
	# print comma
	li	a7, 11
	li	a0, ','
	ecall
	li	a7, 11
	li	a0, ' '
	ecall
	# print y cord
	li	a7, 1
	li	a0, IMAGE_HEIGHT
	addi	a0, a0, -1
	sub	a0, a0, t1
	ecall
	li	a7, 11
	li	a0, 10
	ecall

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
# for debbuging
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
	li	a0, ' '
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

	# check if first rectangle is black
	mv	a0, s0
	addi	a0, a0, 1
	mv	a1, s1
	mv	a2, s3
	mv	a3, s2
	addi	a3, a3, 1
	li	a4, 0
	jal	check_rectangle
	mv	t0, s2
	addi	t0, t0, 1
	mul	t0, t0, s3	# height * (width - 1) of first rectangle
	bne	a0, t0, process_pixel_return_zero	
	
	# check if second part of the marker is black
	#  x + wing_length_minus_one + 1,
	mv	a0, s0
	addi	a0, a0, 1
	add	a0, a0, s3
	# y + height_minus_one - wing_length_minus_one,
	mv	a1, s1
	add	a1, a1, s2
	sub	a1, a1, s3
        # height_minus_one - wing_length_minus_one,
	mv	a2, s2
	sub	a2, a2, s3
        # wing_length_minus_one + 1,
	mv	a3, s3
	addi	a3, a3, 1
	jal	check_rectangle
	mv	t0, s2
	sub	t0, t0, s3
	mv	t1, s3
	addi	t1, t1, 1
	mul	t0, t0, t1
	bne	a0, t0, process_pixel_return_zero
	#bnez	a0, process_pixel_return_zero
	
	# check if all surrounding is not black
	mv	a0, s0
	mv	a1, s1
	mv	a2, s3
	mv	a3, s2
	addi	a2, a2, 1
	addi	a3, a3, 1
	jal	check_surroundings
	bnez	a0, process_pixel_return_zero
####
print_if_is_proper:
	mv	a0, s0
	mv	a1, s1
	jal	get_pixel
	mv	a1, s0
	mv	a2, s1
	#jal	print_pixel	# for debbuging
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
#	processes pixels on the right of given pixel, analyse how many of them are black in a row
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
check_rectangle:
#description: 
#	processes rectangle of given parameters. Checks if it is of a given color (0x00XXXXXX)
#arguments:
#	a0 - x coordinate of checked rectangle (left)
#	a1 - y coordinate of checked rectangle (bottm)
#	a2 - width
#	a3 - height
# 	a4 - color (0x00XXXXXX)
#return value:
#	a0 - color counter - number of pixels of a given color in the rectangle
	addi	sp, sp, -4
	sw	ra, 0(sp)
	addi	sp, sp, -4
	sw	s0, 0(sp)	# x coordinate - outer counter
	addi	sp, sp, -4
	sw	s1, 0(sp)	# y coordinate
	addi	sp, sp, -4
	sw	s2, 0(sp)	# width
	addi	sp, sp, -4
	sw	s3, 0(sp)	# height
	addi	sp, sp, -4
	sw	s4, 0(sp)	# return value storage - color counter
	addi	sp, sp, -4
	sw	s5, 0(sp)	# inner counter
	addi	sp, sp, -4
	sw	s6, 0(sp)	# color	

	mv	s0, a0
	mv	s1, a1	
	mv	s2, a2		
	add	s2, s2, s0	# x coord + width
	mv	s3, a3		
	add	s3, s3, s1	# y coord + height
	li	s4, 0		# default color status - no error
	mv	s6, a4

	beqz	a2, end_check_rectangle_outer_loop
	beqz	a3, end_check_rectangle_outer_loop

check_rectangle_outer_loop:
	mv	s5, s1
check_rectangle_inner_loop:
        # Ciało pętli
        ####
	mv	a0, s0
	mv	a1, s5
	jal	get_pixel
	bne	a0, s6, not_a_given_color
	addi	s4, s4, 1
not_a_given_color:
	####
        # Inkrementacja wewnętrznego licznika pętli
        addi s5, s5, 1

        # Sprawdzenie warunku końcowego wewnętrznej pętli
        bge s5, s3, end_check_rectangle_inner_loop

        # Skok do kolejnej iteracji wewnętrznej pętli
        j check_rectangle_inner_loop

end_check_rectangle_inner_loop:

    # Inkrementacja zewnętrznego licznika pętli
    addi s0, s0, 1

    # Sprawdzenie warunku końcowego zewnętrznej pętli
    bge s0, s2, end_check_rectangle_outer_loop

    # Skok do kolejnej iteracji zewnętrznej pętli
    j check_rectangle_outer_loop

end_check_rectangle_outer_loop:
	mv	a0, s4

	lw	s6, 0(sp)
	addi	sp, sp, 4
	lw	s5, 0(sp)
	addi	sp, sp, 4
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
check_surroundings:
#description: 
#	processes rectangle surrounding. Checks if it is black
#arguments:
#	a0 - x coordinate of checked rectangle (left)
#	a1 - y coordinate of checked rectangle (bottm)
#	a2 - wing width
#	a3 - height
#return value:
#	a0 - color status - 0 if the marker is properly surrounded, else 1
	addi	sp, sp, -4
	sw	ra, 0(sp)
	addi	sp, sp, -4
	sw	s0, 0(sp)	# x coordinate
	addi	sp, sp, -4
	sw	s1, 0(sp)	# y coordinate
	addi	sp, sp, -4
	sw	s2, 0(sp)	# wing width
	addi	sp, sp, -4
	sw	s3, 0(sp)	# height
	addi	sp, sp, -4
	sw	s4, 0(sp)	# return value storage
	addi	sp, sp, -4
	sw	s5, 0(sp)	# IMAGE_WIDHT - 1 (last row index)
	addi	sp, sp, -4
	sw	s6, 0(sp)	# IMAGE_HEIGHT - 1 (last row index)
	# initiating all values
	mv	s0, a0
	mv	s1, a1
	mv	s2, a2
	mv	s3, a3
	li	s4, 0
	li	s5, IMAGE_WIDTH
	#addi	s5, s5, -1
	li	s6, IMAGE_HEIGHT
	#addi	s6, s6, -1

	# sorroundings are checked from bottom clockwise
	# when checking resutl
check_surroundings_bottom_surrounding:
	mv	a0, s0
	mv	a1, s1
	beqz	a1, check_surroundings_left_surrounding
	addi	a1, a1, -1

	mv	a2, s2
	li	a3, 1
	li	a4, 0
	jal	check_rectangle
	bnez	a0, end_check_surroundings_set_error

check_surroundings_left_surrounding:
	mv	a0, s0
	beqz	a0, check_surroundings_upper_surrounding
	addi	a0, a0, -1
	mv	a1, s1

	li	a2, 1
	mv	a3, s3
	li	a4, 0
	jal	check_rectangle
	bnez	a0, end_check_surroundings_set_error

check_surroundings_upper_surrounding:
	mv	a0, s0
	mv	a1, s1
	add	a1, a1, s3 # shall see if we need to decrement by 1
	bge	a1, s6, check_surroundings_right_surrounding

	mv	a2, s3
	li	a3, 1
	li	a4, 0
	jal	check_rectangle
	bnez	a0, end_check_surroundings_set_error

check_surroundings_right_surrounding:
	mv	a0, s0
	add	a0, a0, s3
	bge	a0, s5, check_surroundings_horizontal_middle_surrounding
	mv	a1, s1
	add	a1, a1, s3
	sub	a1, a1, s2

	li	a2, 1
	mv	a3, s2
	li	a4, 0
	jal	check_rectangle
	bnez	a0, end_check_surroundings_set_error

check_surroundings_horizontal_middle_surrounding:
	mv	a0, s0
	add	a0, a0, s2
	mv	a1, s1
	add	a1, a1, s3
	sub	a1, a1,	s2
	addi	a1, a1, -1

	mv	a2, s2
	sub	a2, a2,	s3
	li	a3, 1
	li	a4, 0
	jal	check_rectangle
	bnez	a0, end_check_surroundings_set_error

check_surroundings_vertical_middle_surrounding:
	mv	a0, s0
	add	a0, a0, s2
	mv	a1, s1

	li	a2, 1
	mv	a3, s2
	sub	a3, a3, s3
	li	a4, 0
	jal	check_rectangle
	bnez	a0, end_check_surroundings_set_error

	b	end_check_surroundings
	
end_check_surroundings_set_error:
	li	s4, 1
end_check_surroundings:
	mv	a0, s4

	lw	s6, 0(sp)
	addi	sp, sp, 4
	lw	s5, 0(sp)
	addi	sp, sp, 4
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
