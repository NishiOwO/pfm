.PHONY: all clean

all: ./fpmake
	./fpmake --globalunitdir=/usr/lib/fpc/3.2.2

clean: ./fpmake
	./fpmake  --globalunitdir=/usr/lib/fpc/3.2.2 clean

./fpmake: ./fpmake.pp
	fpc fpmake.pp
