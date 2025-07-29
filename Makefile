FPC = fpc

.PHONY: all clean

all: bin/pfm

bin/pfm: src/*.pas
	mkdir -p bin obj
	$(FPC) -Mobjfpc -Sh -Fusrc -FUobj -FEbin src/pfm.pas

clean:
	rm -f obj/* bin/*
