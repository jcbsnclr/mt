#!/usr/bin/env sh

OUTP="/tmp/mktestgen.$(date +%s%N).c"

# Matches `// @test(<FUNCTION TO RUN>) <NAME>`
STARTEXP='\s*MKTEST(\s*'
FUNCEXP='[a-zA-Z0-9_$]\+'
ENDEXP='\s*)\s*{'

# Helper regexes for value extraction
BEFORE_FUNC="$STARTEXP"
AFTER_FUNC="$ENDEXP$NAMEEXP"

REGEX="$STARTEXP$FUNCEXP$ENDEXP"

# Deletes pattern from stdin
remove() {
    sed "s/$1//g"
}

# Define symbol for test func
# $1: func
decltestfn() {
    echo "MKTEST($1);" >> $OUTP
}

# Add entry to tests list
# $1: func
deftest() {
    echo "\t{ .name = \"$1\", .func = __mktests_$1 }," >> $OUTP
}

# Define the null test (indicates end of tests)
defnull() {
    echo "\t{ NULL }," >> $OUTP
}

# Add a newline to the output for readability
nl() {
    echo >> $OUTP
}

# Extract function from a test declaration
# $1: declaration
getfunc() {
    echo "$1" | remove "$BEFORE_FUNC" | remove "$AFTER_FUNC"
}

# Checks if a string contains any non-whitespace characters
# $1: string
hasdata() {
    echo "$1" | grep -q '[^[:space:]]'
}

if [ "$#" -eq 0 ]; then
    echo "usage: $0 [FILE]..."
    echo "generate a C file to run tests in your project"
    exit 1
fi

# Common start of file; 
cat >> $OUTP << EOF
#include <stddef.h>
#include <stdio.h>
#include <unistd.h>
#include <testing.h>

static char *outcomes[] = {
    [TEST_PASS] = "PASS",
    [TEST_FAIL] = "FAIL"
};

struct test_def {
    char *name;
    enum test_res (*func)();
};

enum test_res test_expects = TEST_PASS;
EOF

nl

EXTRACT="$(cat $@ | grep -o "$REGEX")"

hasdata "$EXTRACT" && echo "$EXTRACT" | while read -r def; do
    FUNC=$(getfunc "$def")
    decltestfn "$FUNC"
done && nl

echo "static struct test_def tests[] = {" >> $OUTP

hasdata "$EXTRACT" && echo "$EXTRACT" | while read -r def; do
    FUNC=$(getfunc "$def")
    deftest "$FUNC"
done

defnull
echo "};" >> $OUTP;
nl

# Common end of file; test runner
cat >> $OUTP << EOF
void run_tests() {
    struct test_def *cur = tests;
    int succ, unsucc = 0;
    int count = 0;

    puts("Running tests...");

    while (cur->func) {
        test_expects = TEST_PASS;

        fprintf(stderr, "\tRunning test \`%s\`... ", cur->name);

        enum test_res res = cur->func();
        fprintf(
            stderr, 
            "%sED (expected %s): %s\n", 
            outcomes[res], outcomes[test_expects],
            res == test_expects ? "SUCCESSFUL" : "UNSUCCESSFUL"
        );
        if (res != test_expects) unsucc++; else succ++;

        cur++;
        count++;
    }

    fprintf(stderr, "%d tests ran\n%d tests successful, %d tests unsuccessful\n", count, succ, unsucc);
}
EOF

printf "$OUTP"