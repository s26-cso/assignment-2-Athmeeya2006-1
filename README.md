[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/d5nOy1eX)

# Assignment 2

This repository contains the solutions for Assignment 2 of CS2.201: Computer Systems Organization.  
The work is divided question-wise into separate folders: `q1`, `q2`, `q3`, `q4`, and `q5`.

## Folder Structure

```text
.
├── q1/
│   └── q1.s
├── q2/
│   └── q2.s
├── q3/
│   ├── a/
│   │   ├── payload.txt
│   │   └── target_Athmeeya2006
│   └── b/
│       ├── payload
│       └── target_Athmeeya2006
├── q4/
│   └── q4.c
├── q5/
│   └── q5.s
└── README.md
```

## What Each Question Does

### Question 1: Binary Search Tree in Assembly

File: [q1/q1.s](/home/athmeeya/assignment-2-Athmeeya2006-1/q1/q1.s)

This file implements a Binary Search Tree in RISC-V assembly. The following functions are defined:

- `make_node(int val)`
- `insert(struct Node* root, int val)`
- `get(struct Node* root, int val)`
- `getAtMost(int val, struct Node* root)`

What the code does:

- `make_node` allocates memory for a new BST node using `malloc`, stores the value, and initializes both child pointers to `NULL`.
- `insert` places a value into the BST while preserving BST order.
- `get` searches the tree and returns the pointer to the matching node if it exists.
- `getAtMost` finds the greatest value in the tree that is less than or equal to a given target. If no such value exists, it returns `-1`.

Approach used:

- Standard BST logic is implemented directly in assembly.
- Recursive logic is used for insertion and search.
- `getAtMost` is implemented iteratively by tracking the best candidate seen so far.

### Question 2: Next Greater Element in Assembly

File: [q2/q2.s](/home/athmeeya/assignment-2-Athmeeya2006-1/q2/q2.s)

This program takes integers from the command line and prints, for each position, the index of the first greater element to its right. If no greater element exists, it prints `-1`.

What the code does:

- Reads command-line arguments.
- Converts each argument from string to integer using a custom `parse_int` routine.
- Uses a monotonic stack to solve the problem in linear time.
- Prints the resulting indices as space-separated integers.

Approach used:

- The array is processed from right to left.
- A stack stores indices of useful candidates for the next greater element.
- Elements that are smaller than or equal to the current one are popped.
- The top of the stack, if present, becomes the answer for that index.

This matches the required `O(n)` time and `O(n)` space complexity.

### Question 3: Reverse Engineering Payloads

Files:

- [q3/a/payload.txt](/home/athmeeya/assignment-2-Athmeeya2006-1/q3/a/payload.txt)
- [q3/a/target_Athmeeya2006](/home/athmeeya/assignment-2-Athmeeya2006-1/q3/a/target_Athmeeya2006)
- [q3/b/payload](/home/athmeeya/assignment-2-Athmeeya2006-1/q3/b/payload)
- [q3/b/target_Athmeeya2006](/home/athmeeya/assignment-2-Athmeeya2006-1/q3/b/target_Athmeeya2006)

This question is different from the others because it is not about writing a full source program. Instead, the task is to analyze the provided binaries and discover the correct input that makes them print the success message.

What these files represent:

- `target_Athmeeya2006` is the given executable to be analyzed.
- `payload.txt` in part A stores the discovered correct input for the first binary.
- `payload` in part B stores the discovered input for the second binary.

q3` contains the final answer files needed to pass the provided binaries.

### Question 4: Dynamic Calculator in C

File: [q4/q4.c](/home/athmeeya/assignment-2-Athmeeya2006-1/q4/q4.c)

This program implements a calculator that reads operations from standard input in the form:

```text
<op> <num1> <num2>
```

Instead of hardcoding operations like addition or multiplication, it loads the required operation at runtime from a shared library named `lib<op>.so`.

What the code does:

- Repeatedly reads lines from standard input.
- Builds the shared library name dynamically, for example `./libadd.so`.
- Loads the library using `dlopen`.
- Looks up the function symbol using `dlsym`.
- Calls the loaded function with the two integer operands.
- Prints the returned result.

Approach used:

- Only one shared library is kept open at a time.
- If the requested operation changes, the previous library is closed using `dlclose` before loading the new one.
- This is done to respect the assignment's memory constraints.

### Question 5: Palindrome Check for a Very Large File

File: [q5/q5.s](/home/athmeeya/assignment-2-Athmeeya2006-1/q5/q5.s)

This program checks whether the contents of `input.txt` form a palindrome, without loading the entire file into memory.

What the code does:

- Opens `input.txt`.
- Finds the file length using `lseek`.
- Uses two pointers:
  one starting from the beginning and one from the end.
- Reads one byte from each side and compares them.
- Prints `Yes` if all matching pairs are equal, otherwise prints `No`.

Approach used:

- The program uses file operations such as `open`, `lseek`, `read`, `close`, and `write`.
- It only stores a constant amount of data at any point.
- This satisfies the required `O(n)` time and `O(1)` extra space complexity.

## Summary

This assignment uses both C and RISC-V assembly and covers:

- dynamic memory allocation
- binary search trees
- monotonic stack based array processing
- runtime shared library loading
- constant-space file processing
- reverse engineering based input discovery
