#include <util.h>

#include <stdlib.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <errno.h>
#include <stdbool.h>
#include <stdarg.h>

// print error indicated by errno and exit
void die(char *where) {
    perror(where);
    exit(1);
}

// exit with error message
void die_with(char *where, char *fmt, ...) {
    fprintf(stderr, "%s: ", where);
    
    va_list args;
    va_start(args, fmt);

    vfprintf(stderr, fmt, args);

    va_end(args);

    exit(1);
}