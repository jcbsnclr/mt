#pragma once

enum test_res {
    TEST_PASS,
    TEST_FAIL
};

extern enum test_res test_expects;

void run_tests();

#define PASS {return TEST_PASS;}
#define FAIL {return TEST_FAIL;}

#define SHOULD_FAIL {test_expects = TEST_FAIL;}

#define MKTEST(name) enum test_res __mktests_ ## name ()