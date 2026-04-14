.text                   # Defines the start of the code (text) segment
    .globl main             # Makes the main function globally visible to the linker

    .extern malloc          # Declares the malloc function from an external library
    .extern printf          # Declares the printf function from an external library

    .section .rodata        # Starts the read-only data section for string constants
fmt_space:                  # Label for space-separated format string
    .string "%d "           # Format string for printf to print an integer followed by a space
fmt_end:                    # Label for newline-terminated format string
    .string "%d\n"          # Format string for printf to print an integer followed by a newline

    .text                   # Switches back to the code (text) segment
parse_int:                  # Entry point for the string-to-integer parsing function
    mv      t0, a0          # Move the string pointer (a0) into temporary register t0
    li      t1, 1           # Initialize the sign multiplier (t1) to positive 1
    li      t2, 0           # Initialize the parsed accumulator value (t2) to 0

    lbu     t3, 0(t0)       # Load the first byte (character) of the string into t3
    li      t4, '-'         # Load the ASCII value for the minus sign into t4
    bne     t3, t4, .pi_digits # If the first character is not a minus sign, branch to parse digits
    li      t1, -1          # If it is a minus sign, set the sign multiplier (t1) to -1
    addi    t0, t0, 1       # Advance the string pointer (t0) past the minus sign

.pi_digits:                 # Label for the digit parsing loop
    lbu     t3, 0(t0)       # Load the current byte (character) into t3
    li      t4, '0'         # Load the ASCII value for '0' into t4
    blt     t3, t4, .pi_done # If the character is less than '0', it's not a digit; branch to done
    li      t5, '9'         # Load the ASCII value for '9' into t5
    blt     t5, t3, .pi_done # If the character is greater than '9', it's not a digit; branch to done

    slli    t6, t2, 3       # Multiply the current accumulator value (t2) by 8 (shift left 3) and store in t6
    slli    t5, t2, 1       # Multiply the current accumulator value (t2) by 2 (shift left 1) and store in t5
    add     t2, t6, t5      # Add t6 and t5 (t2 * 8 + t2 * 2 = t2 * 10) to multiply the accumulator by 10
    addi    t3, t3, -48     # Subtract 48 (ASCII '0') from the character to get its integer value (0-9)
    add     t2, t2, t3      # Add the new integer digit to the accumulator (t2)
    addi    t0, t0, 1       # Advance the string pointer (t0) to the next character
    j       .pi_digits      # Jump back to the beginning of the digit parsing loop

.pi_done:                   # Label for the end of the parsing loop
    li      t3, -1          # Load -1 into t3 for comparison
    bne     t1, t3, .pi_ret # If the sign multiplier (t1) is not -1, branch to the return label
    neg     t2, t2          # If the sign was negative, negate the final accumulator value (t2)
.pi_ret:                    # Label for returning from parse_int
    mv      a0, t2          # Move the final parsed integer into a0 as the return value
    ret                     # Return to the caller

main:                       # Entry point for the main program
    addi    sp, sp, -112    # Allocate 112 bytes on the stack for the stack frame
    sd      ra, 104(sp)     # Save the return address (ra) onto the stack
    sd      s0, 96(sp)      # Save saved register s0 onto the stack (will hold argc)
    sd      s1, 88(sp)      # Save saved register s1 onto the stack (will hold argv)
    sd      s2, 80(sp)      # Save saved register s2 onto the stack (will hold number of elements 'n')
    sd      s3, 72(sp)      # Save saved register s3 onto the stack (will hold vals[] pointer)
    sd      s4, 64(sp)      # Save saved register s4 onto the stack (will hold result[] pointer)
    sd      s5, 56(sp)      # Save saved register s5 onto the stack (will hold stack[] pointer)
    sd      s6, 48(sp)      # Save saved register s6 onto the stack (will hold loop counter 'i')
    sd      s7, 40(sp)      # Save saved register s7 onto the stack (will hold stack top pointer)

    mv      s0, a0          # Store argc (a0) into s0
    mv      s1, a1          # Store argv pointer (a1) into s1

    li      t0, 1           # Load 1 into t0 for comparison
    ble     s0, t0, .q2_exit # If argc <= 1 (no arguments provided), branch to the exit block

    addi    s2, s0, -1      # Calculate n = argc - 1 (the number of numeric arguments) and store in s2

    slli    a0, s2, 2       # Multiply n by 4 (bytes per 32-bit integer) to get allocation size for vals[]
    call    malloc          # Call malloc to allocate memory on the heap for vals[]
    beqz    a0, .q2_exit    # If malloc fails (returns NULL), branch to exit
    mv      s3, a0          # Store the returned pointer to vals[] in s3

    slli    a0, s2, 2       # Multiply n by 4 to get allocation size for result[]
    call    malloc          # Call malloc to allocate memory on the heap for result[]
    beqz    a0, .q2_exit    # If malloc fails, branch to exit
    mv      s4, a0          # Store the returned pointer to result[] in s4

    slli    a0, s2, 2       # Multiply n by 4 to get allocation size for stack[]
    call    malloc          # Call malloc to allocate memory on the heap for stack[]
    beqz    a0, .q2_exit    # If malloc fails, branch to exit
    mv      s5, a0          # Store the returned pointer to stack[] in s5

    li      s6, 0           # Initialize loop counter i (s6) to 0 for parsing arguments
.q2_parse_loop:             # Label for the argument parsing loop
    bge     s6, s2, .q2_compute # If i >= n, all arguments are parsed; branch to computation phase
    addi    t0, s6, 1       # Calculate i + 1 (since argv[0] is the program name)
    slli    t0, t0, 3       # Multiply (i+1) by 8 (bytes per 64-bit pointer) to get array offset
    add     t0, s1, t0      # Add offset to argv base address (s1) to get the address of argv[i+1]
    ld      a0, 0(t0)       # Load the string pointer argv[i+1] into a0
    call    parse_int       # Call parse_int to convert the string to an integer
    slli    t1, s6, 2       # Multiply i by 4 (bytes per integer) to get offset for vals array
    add     t1, s3, t1      # Add offset to vals base address (s3)
    sw      a0, 0(t1)       # Store the parsed integer into vals[i]
    addi    s6, s6, 1       # Increment loop counter i
    j       .q2_parse_loop  # Jump back to start of parsing loop

.q2_compute:                # Label for the main Next Greater Element computation
    li      s7, -1          # Initialize monotonic stack top index (s7) to -1 (empty stack)
    addi    s6, s2, -1      # Initialize loop counter i (s6) to n - 1 (iterate right-to-left)

.q2_outer:                  # Label for the outer right-to-left array traversal loop
    blt     s6, zero, .q2_print # If i < 0, array traversal is complete; branch to printing phase
    slli    t0, s6, 2       # Multiply i by 4 to get offset for vals array
    add     t0, s3, t0      # Add offset to vals base address (s3)
    lw      t1, 0(t0)       # Load current array value vals[i] into t1

.q2_inner:                  # Label for the inner loop to pop smaller elements from the stack
    blt     s7, zero, .q2_no_stack # If stack is empty (top < 0), branch to .q2_no_stack
    slli    t2, s7, 2       # Multiply stack top index by 4 to get offset in stack array
    add     t2, s5, t2      # Add offset to stack base address (s5)
    lw      t3, 0(t2)       # Load the index stored at the top of the stack into t3
    slli    t4, t3, 2       # Multiply popped index by 4 to get offset in vals array
    add     t4, s3, t4      # Add offset to vals base address (s3)
    lw      t5, 0(t4)       # Load the actual value vals[stack[top]] into t5
    
    ble     t5, t1, .q2_pop # If stack value <= current value (vals[i]), branch to pop it
    mv      t6, t3          # We found a strictly greater element; save its index (t3) into t6
    j       .q2_store       # Jump to store the result

.q2_pop:                    # Label for popping an item off the monotonic stack
    addi    s7, s7, -1      # Decrement stack top index pointer (pop operation)
    j       .q2_inner       # Jump back to evaluate the new stack top

.q2_no_stack:               # Label handling the case where the stack becomes empty
    li      t6, -1          # No greater element exists to the right; set result indicator to -1

.q2_store:                  # Label for storing the computed NGE index into the result array
    slli    t0, s6, 2       # Multiply i by 4 to get offset for result array
    add     t0, s4, t0      # Add offset to result base address (s4)
    sw      t6, 0(t0)       # Store the computed answer (t6) into result[i]

    addi    s7, s7, 1       # Increment stack top index pointer (prepare to push)
    slli    t0, s7, 2       # Multiply new stack top index by 4 to get offset
    add     t0, s5, t0      # Add offset to stack base address (s5)
    sw      s6, 0(t0)       # Push the current array index (i) onto the stack

    addi    s6, s6, -1      # Decrement loop counter i (move leftward in the array)
    j       .q2_outer       # Jump back to start of outer traversal loop

.q2_print:                  # Label for the printing phase
    li      s6, 0           # Reset loop counter i (s6) to 0 for iterating over results
.q2_print_loop:             # Label for the result printing loop
    bge     s6, s2, .q2_exit # If i >= n, all results printed; branch to exit and cleanup
    slli    t0, s6, 2       # Multiply i by 4 to get offset for result array
    add     t0, s4, t0      # Add offset to result base address (s4)
    lw      a1, 0(t0)       # Load result[i] into a1 to be used as the argument for printf

    addi    t1, s6, 1       # Calculate i + 1
    bne     t1, s2, .q2_space # If i + 1 != n (not the last element), branch to use space format
    la      a0, fmt_end     # If it is the last element, load the newline format string pointer into a0
    j       .q2_do_print    # Jump to perform the print
.q2_space:                  # Label for using the space format string
    la      a0, fmt_space   # Load the space format string pointer into a0
.q2_do_print:               # Label for executing the print call
    call    printf          # Call printf to output the integer
    addi    s6, s6, 1       # Increment loop counter i
    j       .q2_print_loop  # Jump back to start of printing loop

.q2_exit:                   # Label for program cleanup and exit
    ld      ra, 104(sp)     # Restore the return address (ra) from the stack
    ld      s0, 96(sp)      # Restore saved register s0 from the stack
    ld      s1, 88(sp)      # Restore saved register s1 from the stack
    ld      s2, 80(sp)      # Restore saved register s2 from the stack
    ld      s3, 72(sp)      # Restore saved register s3 from the stack
    ld      s4, 64(sp)      # Restore saved register s4 from the stack
    ld      s5, 56(sp)      # Restore saved register s5 from the stack
    ld      s6, 48(sp)      # Restore saved register s6 from the stack
    ld      s7, 40(sp)      # Restore saved register s7 from the stack
    addi    sp, sp, 112     # Deallocate the 112 bytes from the stack (restore stack pointer)
    li      a0, 0           # Load 0 into a0 (standard exit code for success)
    ret                     # Return to the operating system / environment