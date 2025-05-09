# Detect host architecture
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# DEBUG Flag
BOPTS := ""
ifneq ($$_DEBUG,"1")
	BOPTS := "-Ofast -DNDEBUG"
endif

ifeq ($$_VERBOSE,"1")
	BOPTS += "-v"
endif


# Build for current platform
all:
ifeq ($(UNAME_S),Darwin)
ifeq ($(UNAME_M),arm64)
	@$(MAKE) macos-arm64
else
	@$(MAKE) macos-x86_64
endif
else
	@$(MAKE) linux
endif

macos-arm64:
	as adate-$(UNAME_S)-$(UNAME_M).asm -o adate_arm64.o
	clang -arch arm64 -o adate_arm64 adate_arm64.o

macos-x86_64:
	nasm -f macho64 adate.asm -o adate_x86.o
	clang -arch x86_64 -o adate_x86 adate_x86.o

universal:
	lipo -create -output adate_universal adate_x86 adate_arm64

linux:
	nasm -f elf64 adate.asm -o adate_linux.o
	gcc $(BOPTS) -static -static-libgcc -static-libstdc++ -no-pie -o adate_linux adate_linux.o

clean:
	rm -f *.o adate_linux adate_x86 adate_arm64 adate_universal
