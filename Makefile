.PHONY: clean release release_

all: adtrack2

release: release_
	rm -rf release/adtrack-*/
	echo -e "\n\n\nyour files are ready at release/\n"

release_: all
	rm -rf release
	mkdir release
	mkdir release/src
	cp -r *.pas *.inc Makefile TODO *.asm *.bat sdl.dll *.c *.h sdl utils package release/src/
	cp -r package release/bin
	cp adtrack2 release/bin/
	rm -f release/bin/techinfo.*
	
	cd release; \
	echo "which minor version is this? NOTE that i assume 2.4.xx and that you're on debian wheezy x86!"; \
	read ver; \
	mv src adtrack-2.4.$${ver}-linux-src; \
	mv bin adtrack-2.4.$${ver}-linux-bin-debian-wheezy-x86; \
	tar cvzf adtrack-2.4.$${ver}-linux-src.tar.gz adtrack-2.4.$${ver}-linux-src; \
	tar cvzf adtrack-2.4.$${ver}-linux-bin-debian-wheezy-x86.tar.gz adtrack-2.4.$${ver}-linux-bin-debian-wheezy-x86;
	


clean:
	rm -f *.o *.s *.res *.ppu *.map *.fpd *.sym *.cfg adtrack2
	rm -f sdl/*.o sdl/*.ppu

mrproper: clean
	rm -rf bin/
	mkdir bin/
	rm -rf release/

adtrack2: ymf262.o aplib.o adt2apak.pas adt2data.pas adt2ext2.pas adt2ext3.pas adt2ext4.pas adt2extn.pas adt2keyb.pas adt2opl3.pas adt2sys.pas adt2text.pas adt2unit.pas adtrack2.pas depackio.pas dialogio.pas iloaders.inc iloadins.inc instedit.inc ipattern.inc ipattord.inc menulib1.pas menulib2.pas parserio.pas realtime.inc stringio.pas timerint.pas txtscrio.pas typconst.inc
	fpc -O2 -OpPENTIUM2 -Ccpascal -Mtp -Rintel -Fusdl adtrack2.pas -oadtrack2

ymf262.o: ymf262.c ymf262.h
	gcc -c ymf262.c -o ymf262.o -shared -Wall -O3 -std=c99 -fms-extensions -DINLINE="static"

aplib.o: aplib.asm 
	jwasm -elf -Foaplib.o aplib.asm

