FPC = fpc
MK = generic

include mk/$(MK).mk

.PHONY: all clean

all: bin/pfm$(EXEC)

bin/pfm$(EXEC): src/*.pas $(RES)
	mkdir -p bin obj
	$(FPC) -dRELEASE -Mobjfpc -Sh -Fusrc -FUobj -FEbin src/pfm.pas

clean:
	rm -f obj/* bin/*
