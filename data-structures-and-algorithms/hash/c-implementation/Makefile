CPP = gcc
HEAD_FILE_PATH = ./
COMPILE_CMD = $(CPP) -I $(HEAD_FILE_PATH)

.SUFFIXES : .o .cpp .c
.cpp.o :
	$(COMPILE_CMD) $<
.c.o :
	$(COMPILE_CMD) $<

md5test: md5c.c mddriver.c
	$(COMPILE_CMD) md5c.c mddriver.c -o $@

test: md5test \

	./md5test -x

clean:
	rm md5test

.PHONY:
	clean