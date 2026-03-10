CC = gcc
CFLAGS = -shared -fPIC -O2
SCHEME = scheme

.PHONY: all clean test

all: chez_inotify_shim.so

chez_inotify_shim.so: chez_inotify_shim.c
	$(CC) $(CFLAGS) -o $@ $<

test: chez_inotify_shim.so
	LD_LIBRARY_PATH=. $(SCHEME) --libdirs src --script tests/inotify-test.ss

clean:
	rm -f chez_inotify_shim.so
