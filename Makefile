FPCDIR = /usr/lib/fpc/3.2.2
FPMKARGS =

.PHONY: all clean

all: ./fpmake
	./fpmake --globalunitdir=$(FPCDIR) $(FPMKARGS)

clean: ./fpmake
	./fpmake  --globalunitdir=$(FPCDIR) $(FPMKARGS) clean

./fpmake: ./fpmake.pp
	fpc fpmake.pp
