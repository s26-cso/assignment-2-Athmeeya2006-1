#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Define a function pointer type for the dynamically loaded operations
typedef int (*op_func_t)(int, int);

int main() {
    char op[16];
    int a, b;
    
    void *handle = NULL;      // Pointer to the currently open shared library
    char current_op[16] = ""; // Cache of the active operation to avoid redundant reloading

    // Read standard input line by line until EOF or parsing fails
    while (scanf("%15s %d %d", op, &a, &b) == 3) {
        
        // Only trigger a library reload if the requested operation has changed
        if (strcmp(op, current_op) != 0) {
            
            // Close the previously loaded library BEFORE opening a new one.
            // This strictly prevents exceeding the 2 GB memory constraint.
            if (handle != NULL) {
                dlclose(handle);
                handle = NULL;
            }

            // Construct the shared library filename (e.g., "./libadd.so")
            char libname[64];
            snprintf(libname, sizeof(libname), "./lib%s.so", op);

            // Clear any stale errors, then load the library resolving symbols immediately
            dlerror(); 
            handle = dlopen(libname, RTLD_NOW | RTLD_LOCAL);
            if (!handle) {
                fprintf(stderr, "Failed to load %s: %s\n", libname, dlerror());
                return 1;
            }

            // Update the cache with the newly loaded operation name
            strncpy(current_op, op, sizeof(current_op) - 1);
            current_op[sizeof(current_op) - 1] = '\0';
        }

        // Look up the memory address of the specific operation function within the loaded library
        dlerror(); 
        op_func_t func = (op_func_t)dlsym(handle, op);
        const char *err = dlerror();
        
        if (err != NULL || func == NULL) {
            fprintf(stderr, "Failed to resolve symbol %s: %s\n", op, err ? err : "unknown error");
            if (handle != NULL) {
                dlclose(handle);
            }
            return 1;
        }

        // Execute the resolved function and output the result
        printf("%d\n", func(a, b));
    }

    // Clean up the remaining library handle upon normal program exit
    if (handle != NULL) {
        dlclose(handle);
    }

    return 0;
}