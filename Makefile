TEST?=no
TESTFILE=build/.testfile

CC?=gcc

INSTRUMENTS=-fsanitize=address -fsanitize=leak -fsanitize=undefined -fsanitize=float-divide-by-zero -static-libasan -static-liblsan 

CSRC=$(wildcard source/*.c)
COBJ=$(patsubst source/%.c, build/%.c.o, $(CSRC))
CDEF=$(patsubst source/%.c, build/%.c.d, $(CSRC))

TCFLAGS:=$(CFLAGS) -Wall -Werror -Wextra -Og -g -c -mtune=native -Isource/ $(INSTRUMENTS)

ifeq ($(TEST),yes)
TESTOBJ=build/mktestgen.o
TCFLAGS+=-DTESTRUN
endif

CFLAGS:=$(TCFLAGS) -MMD
LFLAGS:=$(LFLAGS) $(INSTRUMENTS) -lrt -fPIE -pie

DBG?=gdb
DBGVARS?=LSAN_OPTIONS=verbosity=0:log_threads=1 ASAN_OPTIONS=detect_leaks=0
DBGCMD=$(DBGVARS) $(DBG)

BINNAME=arbiter
BIN=build/$(BINNAME)

# quick hack; allows us to depend on the value of the TEST variable (will rebuild if changed) 
$(TESTFILE).$(TEST):
	mkdir -p $(dir $@)
	rm -f $(TESTFILE).*
	touch $@

# mktests.sh generates a test runner from C source code
ifeq ($(TEST),yes)
$(TESTOBJ): $(CSRC) source/testing.h utils/mktests.sh
	mkdir -p $(dir $@)
	$(CC) $(TCFLAGS) $(shell ./utils/mktests.sh $(CSRC)) -I. -o $@
endif

build/%.c.o: source/%.c $(TESTFILE).$(TEST)
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< -o $@

$(BIN): $(COBJ) $(TESTOBJ)
	$(CC) $(TESTOBJ) $(COBJ) -o $@ $(LFLAGS)

.PHONY: all run dbg clean 

all: $(BIN)

run: all
	./$(BIN)

dbg: all
	$(DBGCMD) $(BIN)

clean:
	rm -rf build/
	rm -f /tmp/mktestgen.*

-include build/*.d