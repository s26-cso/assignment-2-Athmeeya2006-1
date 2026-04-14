.text                   # Defines the start of the code (text) segment
    .globl make_node        # Makes the make_node function globally visible to the linker
    .globl insert           # Makes the insert function globally visible to the linker
    .globl get              # Makes the get function globally visible to the linker
    .globl getAtMost        # Makes the getAtMost function globally visible to the linker
    .extern malloc          # Declares the malloc function, which is defined in an external library

make_node:                  # Entry point for the make_node function
    addi    sp, sp, -16     # Allocate 16 bytes of space on the stack for the stack frame
    sd      ra, 8(sp)       # Save the return address (ra) to the stack at offset 8
    sd      s0, 0(sp)       # Save the caller's s0 register to the stack at offset 0 to preserve it

    mv      s0, a0          # Move the argument 'val' from a0 to s0 so it isn't overwritten by malloc
    
    li      a0, 24          # Load the immediate value 24 (the size of struct Node in bytes) into a0
    call    malloc          # Call malloc to allocate 24 bytes on the heap; a0 will hold the resulting pointer
    beqz    a0, .make_node_done # If malloc returns 0 (NULL), branch to the cleanup/exit block

    sw      s0, 0(a0)       # Store the integer 'val' (saved in s0) into the first 4 bytes of the allocated node
    sd      zero, 8(a0)     # Store 0 (NULL) into the node's left child pointer (8 bytes at offset 8)
    sd      zero, 16(a0)    # Store 0 (NULL) into the node's right child pointer (8 bytes at offset 16)

.make_node_done:            # Label for the function epilogue (cleanup)
    ld      ra, 8(sp)       # Restore the return address (ra) from the stack
    ld      s0, 0(sp)       # Restore the caller's s0 register from the stack
    addi    sp, sp, 16      # Deallocate the 16 bytes from the stack
    ret                     # Return to the calling function

insert:                     # Entry point for the insert function
    bnez    a0, .insert_non_null # If the root pointer (a0) is not equal to zero (NULL), branch to .insert_non_null
    
    mv      a0, a1          # Move the 'val' argument (a1) into a0 to prepare for the make_node call
    tail    make_node       # Perform a tail call to make_node, reusing the current stack frame and returning its result directly

.insert_non_null:           # Label for handling a non-NULL root node
    addi    sp, sp, -32     # Allocate 32 bytes on the stack for the stack frame
    sd      ra, 24(sp)      # Save the return address (ra) to the stack at offset 24
    sd      s0, 16(sp)      # Save the caller's s0 register to the stack at offset 16 (will hold root pointer)
    sd      s1, 8(sp)       # Save the caller's s1 register to the stack at offset 8 (will hold val)

    mv      s0, a0          # Move the root pointer from a0 to s0 to preserve it across recursive calls
    mv      s1, a1          # Move the 'val' argument from a1 to s1 to preserve it across recursive calls

    lw      t0, 0(s0)       # Load the integer value of the current root node (root->val) into temporary register t0

    blt     s1, t0, .insert_left   # If val (s1) is less than root->val (t0), branch to insert into the left subtree
    bgt     s1, t0, .insert_right  # If val (s1) is greater than root->val (t0), branch to insert into the right subtree

    mv      a0, s0          # If val equals root->val (duplicate), move the unmodified root pointer back into a0 for return
    j       .insert_done    # Jump to the function epilogue

.insert_left:               # Label for inserting into the left subtree
    ld      a0, 8(s0)       # Load the left child pointer (root->left) into a0 as the first argument for recursion
    mv      a1, s1          # Move the 'val' (s1) into a1 as the second argument for recursion
    call    insert          # Recursively call the insert function
    sd      a0, 8(s0)       # Store the returned node pointer back into the root's left child pointer (root->left)
    mv      a0, s0          # Move the current root pointer (s0) back into a0 for the return value
    j       .insert_done    # Jump to the function epilogue

.insert_right:              # Label for inserting into the right subtree
    ld      a0, 16(s0)      # Load the right child pointer (root->right) into a0 as the first argument for recursion
    mv      a1, s1          # Move the 'val' (s1) into a1 as the second argument for recursion
    call    insert          # Recursively call the insert function
    sd      a0, 16(s0)      # Store the returned node pointer back into the root's right child pointer (root->right)
    mv      a0, s0          # Move the current root pointer (s0) back into a0 for the return value

.insert_done:               # Label for the function epilogue (cleanup)
    ld      ra, 24(sp)      # Restore the return address (ra) from the stack
    ld      s0, 16(sp)      # Restore the caller's s0 register from the stack
    ld      s1, 8(sp)       # Restore the caller's s1 register from the stack
    addi    sp, sp, 32      # Deallocate the 32 bytes from the stack
    ret                     # Return to the calling function

get:                        # Entry point for the get function
    beqz    a0, .get_not_found # If the root pointer (a0) is NULL, branch to .get_not_found (returns NULL)

    lw      t0, 0(a0)       # Load the integer value of the current root node (root->val) into temporary register t0
    beq     a1, t0, .get_found # If search val (a1) equals root->val (t0), branch to .get_found (returns current node)

    blt     a1, t0, .get_left  # If search val (a1) is less than root->val (t0), branch to search the left subtree
    ld      a0, 16(a0)      # If val is greater, load the right child pointer (root->right) into a0 for the next step
    tail    get             # Perform a tail call to 'get' to search the right subtree without growing the stack

.get_left:                  # Label for searching the left subtree
    ld      a0, 8(a0)       # Load the left child pointer (root->left) into a0 for the next step
    tail    get             # Perform a tail call to 'get' to search the left subtree without growing the stack

.get_found:                 # Label indicating the node was found (the matching pointer is already in a0)
.get_not_found:             # Label indicating the node wasn't found (a0 contains NULL/0)
    ret                     # Return to the calling function with the result in a0

getAtMost:                  # Entry point for the getAtMost function
    mv      t2, a0          # Move the target 'val' (a0) into temporary register t2
    mv      t0, a1          # Move the root node pointer (a1) into temporary register t0
    li      a0, -1          # Initialize the return value (a0) to -1 (the default if no valid value is found)

.gam_loop:                  # Label for the start of the iterative search loop
    beqz    t0, .gam_done   # If the current node pointer (t0) is NULL, the search is exhausted; branch to .gam_done

    lw      t1, 0(t0)       # Load the current node's integer value into temporary register t1

    bgt     t1, t2, .gam_left  # If current node's value (t1) is greater than target (t2), branch left (value is too big)

    mv      a0, t1          # Since current value <= target, it's a valid candidate; update the best answer (a0)
    beq     t1, t2, .gam_done  # If current value exactly equals the target, it's the perfect match; branch to .gam_done

    ld      t0, 16(t0)      # Target is larger than current, so load the right child pointer to find a larger valid value
    j       .gam_loop       # Jump back to the start of the loop to process the new node

.gam_left:                  # Label for moving to the left subtree
    ld      t0, 8(t0)       # Load the left child pointer into t0 to find a smaller value
    j       .gam_loop       # Jump back to the start of the loop to process the new node

.gam_done:                  # Label for the end of the search
    ret                     # Return to the calling function with the best found value (or -1) in a0