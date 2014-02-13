.PHONY: clean

all: adtrack2

clean:
	rm -f *.o *.s *.res *.ppu *.map *.fpd *.sym *.cfg adtrack2
	rm -f sdl/*.o sdl/*.ppu

mrproper: clean
	rm -rf bin/
	mkdir bin/

adtrack2: ymf262.o aplib.o adt2icon.inc font8x16.inc iloaders.inc iloadins.inc instedit.inc ipattern.inc ipattord.inc realtime.inc symtab.inc typconst.inc adt2apak.pas adt2ext2.pas adt2ext3.pas adt2extn.pas adt2keyb.pas adt2opl3.pas adt2sys.pas adt2text.pas adt2unit.pas adt2vid.pas adt2vscr.pas depackio.pas dialogio.pas menulib1.pas menulib2.pas parserio.pas stringio.pas timerint.pas txtscrio.pas adtrack2.pas
	fpc -O2 -OpPENTIUM2 -Ccpascal -Mtp -Rintel -Fusdl adtrack2.pas -oadtrack2

ymf262.o: ymf262.c ymf262.h
	gcc -c ymf262.c -o ymf262.o -shared -Wall -O3 -std=c99 -fms-extensions -DINLINE="static"

aplib.o: aplib.asm bin/jwasm
	bin/jwasm -elf -Foaplib.o aplib.asm

bin/jwasm: bin/JWasm211bl.zip
	unzip bin/JWasm211bl.zip jwasm -d bin/
	touch bin/jwasm
	chmod a+x bin/jwasm

bin/JWasm211bl.zip:
	test -d bin || mkdir bin
	wget http://www.japheth.de/Download/JWasm/JWasm211bl.zip -O bin/JWasm211bl.zip
	touch bin/JWasm211bl.zip

