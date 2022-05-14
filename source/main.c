#include <stdio.h>

#include <parser.h>

#ifdef TESTRUN
#include "testing.h"
#endif

int main(void) {
#ifdef TESTRUN
    run_tests();
#else
    puts("Build with `make TEST=yes run` in order to run the test suite");
#endif
    return 0;
}

#ifdef TESTRUN 

#endif