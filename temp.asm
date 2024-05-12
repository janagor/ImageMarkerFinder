	.data
newline:.string "Kaczuszka debbugowa\n"

	.text
main:
	li	a7, 4
	la	a0, newline
	ecall
	li	a7, 4
	la	a0, newline
	ecall
	li	a7, 4
	la	a0, newline
	ecall
    li t0, 0    # Początek zewnętrznej pętli (x)
outer_loop:
    li t4, 13
    bge t0, t4, outer_loop_end

    li t1, 0    # Początek wewnętrznej pętli (y)
inner_loop:
    li t5, 15
    bge t1, t5, inner_loop_end

    # Obliczenie sumy x i y
    add a0, t0, t1

    # Wywołanie funkcji do wyświetlenia sumy
    jal display_sum

    # Inkrementacja licznika y
    addi t1, t1, 1

    # Wywołanie funkcji do wyświetlenia znaku nowej linii
    la a0, newline
    li a7, 4
    ecall

    # Powrót do początku wewnętrznej pętli
    j inner_loop

inner_loop_end:
    # Inkrementacja licznika x
    addi t0, t0, 1

    # Wywołanie funkcji do wyświetlenia znaku nowej linii
    la a0, newline
    li a7, 4
    ecall

    # Powrót do początku zewnętrznej pętli
    j outer_loop

outer_loop_end:
    # Zakończenie programu
    li a7, 10
    ecall

# Funkcja do wyświetlania sumy
display_sum:
    # Wywołanie systemowego wywołania do wyświetlenia liczby całkowitej
    li a7, 1
    ecall

    # Wywołanie systemowego wywołania do wyświetlenia znaku nowej linii
    la a0, newline
    li a7, 4
    ecall

    ret
