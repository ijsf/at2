.DEFAULT_GOAL := all

CFLAGS = -Wall -Wno-unused-local-typedef -ggdb

# Should be equivalent to your list of C files, if you don't build selectively
SRC=$(wildcard *.c)
OBJ=$(patsubst %.c, %.o, $(SRC))

%.o: %.c
	$(CXX) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o

all: $(OBJ)
	echo $(SRC)
