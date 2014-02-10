@echo off
set homedir=%~d1\AT2_Compilation_Environment
set path=%homedir%\utils\fpc\bin\i386-win32
fpc.exe -O1 -OpPENTIUM2 -Ccpascal -Mtp -Rintel -Twin32 -WC -Fusdl validate.pas -ovalidate.exe
del *.ppu
del *.o
