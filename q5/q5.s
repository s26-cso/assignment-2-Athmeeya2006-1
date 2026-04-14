.text                   # Defines the start of the code (text) segment
    .globl main             # Makes the main function globally visible to the linker

    .extern open            # Declares the external C library function 'open'
    .extern lseek           # Declares the external C library function 'lseek'
    .extern read            # Declares the external C library function 'read'
    .extern close           # Declares the external C library function 'close'
    .extern write           # Declares the external C library function 'write'

    .section .rodata        # Starts the read-only data section for string constants
filename:                   # Label for the filename string
    .string "input.txt"     # The name of the file to open
yes_msg:                    # Label for the success message
    .string "Yes\n"         # The string to print if it is a palindrome
no_msg:                     # Label for the failure message
    .string "No\n"          # The string to print if it is not a palindrome

    .text                   # Switches back to the code (text) segment
main:                       # Entry point for the main function
    addi    sp, sp, -64     # Allocate 64 bytes on the stack for the stack frame
    sd      ra, 56(sp)      # Save the return address (ra) to the stack at offset 56
    sd      s0, 48(sp)      # Save saved register s0 to the stack (will hold file descriptor)
    sd      s1, 40(sp)      # Save saved register s1 to the stack (will hold file length)
    sd      s2, 32(sp)      # Save saved register s2 to the stack (will hold left pointer)
    sd      s3, 24(sp)      # Save saved register s3 to the stack (will hold right pointer)

    la      a0, filename    # Load the address of the "input.txt" string into a0 (1st arg for open)
    li      a1, 0           # Load 0 (O_RDONLY flag) into a1 (2nd arg for open)
    call    open            # Call the 'open' function to open the file
    mv      s0, a0          # Store the returned file descriptor from a0 into s0
    blt     s0, zero, .q5_no # If file descriptor is less than 0 (error), branch to print "No"

    mv      a0, s0          # Move the file descriptor into a0 (1st arg for lseek)
    li      a1, 0           # Load offset 0 into a1 (2nd arg for lseek)
    li      a2, 2           # Load 2 (SEEK_END flag) into a2 (3rd arg for lseek)
    call    lseek           # Call 'lseek' to move the file pointer to the end and get the file size
    blt     a0, zero, .q5_close_no # If lseek returns < 0 (error), branch to close file and print "No"
    mv      s1, a0          # Store the returned file length from a0 into s1

    li      t0, 1           # Load 1 into t0 for comparison
    ble     s1, t0, .q5_yes # If file length <= 1, it's inherently a palindrome; branch to .q5_yes

    li      s2, 0           # Initialize the left pointer (s2) to 0 (start of file)
    addi    s3, s1, -1      # Initialize the right pointer (s3) to length - 1 (end of file)

.q5_loop:                   # Label for the main two-pointer palindrome checking loop
    bge     s2, s3, .q5_yes # If left pointer >= right pointer, we checked all pairs; branch to .q5_yes

    mv      a0, s0          # Move the file descriptor into a0 (1st arg for lseek)
    mv      a1, s2          # Move the left pointer (offset) into a1 (2nd arg for lseek)
    li      a2, 0           # Load 0 (SEEK_SET flag) into a2 (3rd arg for lseek) to seek from start
    call    lseek           # Call 'lseek' to move the file pointer to the left character's position

    mv      a0, s0          # Move the file descriptor into a0 (1st arg for read)
    mv      a1, sp          # Use the stack pointer (sp) as the buffer address (2nd arg for read)
    li      a2, 1           # Read exactly 1 byte (3rd arg for read)
    call    read            # Call 'read' to read the left character into the stack buffer at 0(sp)
    li      t0, 1           # Load 1 into t0 for comparison
    bne     a0, t0, .q5_close_no # If read did not return exactly 1 byte read, branch to close and fail

    mv      a0, s0          # Move the file descriptor into a0 (1st arg for lseek)
    mv      a1, s3          # Move the right pointer (offset) into a1 (2nd arg for lseek)
    li      a2, 0           # Load 0 (SEEK_SET flag) into a2 (3rd arg for lseek) to seek from start
    call    lseek           # Call 'lseek' to move the file pointer to the right character's position

    mv      a0, s0          # Move the file descriptor into a0 (1st arg for read)
    addi    a1, sp, 1       # Use sp+1 as the buffer address so we don't overwrite the left char
    li      a2, 1           # Read exactly 1 byte (3rd arg for read)
    call    read            # Call 'read' to read the right character into the stack buffer at 1(sp)
    li      t0, 1           # Load 1 into t0 for comparison
    bne     a0, t0, .q5_close_no # If read did not return exactly 1 byte read, branch to close and fail

    lbu     t1, 0(sp)       # Load the left character (unsigned byte) from the buffer at 0(sp) into t1
    lbu     t2, 1(sp)       # Load the right character (unsigned byte) from the buffer at 1(sp) into t2
    bne     t1, t2, .q5_close_no # If the two characters don't match, it's not a palindrome; branch to fail

    addi    s2, s2, 1       # Increment the left pointer to move inward
    addi    s3, s3, -1      # Decrement the right pointer to move inward
    j       .q5_loop        # Jump back to the start of the loop to check the next pair

.q5_yes:                    # Label for successful palindrome check
    mv      a0, s0          # Move the file descriptor into a0 (1st arg for close)
    call    close           # Call 'close' to close the file and release the file descriptor
    li      a0, 1           # Load 1 (stdout file descriptor) into a0 (1st arg for write)
    la      a1, yes_msg     # Load the address of the "Yes\n" string into a1 (2nd arg for write)
    li      a2, 4           # Load 4 (length of "Yes\n") into a2 (3rd arg for write)
    call    write           # Call 'write' to print the success message
    j       .q5_exit        # Jump to the function epilogue to exit safely

.q5_close_no:               # Label for closing the file before returning "No"
    mv      a0, s0          # Move the file descriptor into a0 (1st arg for close)
    call    close           # Call 'close' to ensure the file descriptor doesn't leak
.q5_no:                     # Label for failed palindrome check
    li      a0, 1           # Load 1 (stdout file descriptor) into a0 (1st arg for write)
    la      a1, no_msg      # Load the address of the "No\n" string into a1 (2nd arg for write)
    li      a2, 3           # Load 3 (length of "No\n") into a2 (3rd arg for write)
    call    write           # Call 'write' to print the failure message

.q5_exit:                   # Label for the main function epilogue
    ld      ra, 56(sp)      # Restore the return address (ra) from the stack
    ld      s0, 48(sp)      # Restore saved register s0 from the stack
    ld      s1, 40(sp)      # Restore saved register s1 from the stack
    ld      s2, 32(sp)      # Restore saved register s2 from the stack
    ld      s3, 24(sp)      # Restore saved register s3 from the stack
    addi    sp, sp, 64      # Deallocate the 64 bytes from the stack
    li      a0, 0           # Set the return value to 0 (successful program exit)
    ret                     # Return to the operating system