@echo off
set homedir=%~d1\AT2_Compilation_Environment
set path=%homedir%\utils\fpc\bin\i386-win32;%homedir%\utils\mingw\bin;%homedir%\utils\jwasm
cd %homedir%\at2-SDL
if exist adtrack2.res goto :res_ok
windres -i adtrack2.rc -o adtrack2.res
:res_ok
if not exist aplib.o goto :aplib_ok
del /F /Q aplib.o
if exist aplib.o goto :error
:aplib_ok
if not exist adtrack2.exe goto :exe_ok
del /F /Q adtrack2.exe
if exist adtrack2.exe goto :error
:exe_ok
if not exist ymf262.o goto :mame_ok
del /F /Q ymf262.o
if exist ymf262.o goto :error
:mame_ok
echo.
echo ************************************
echo **                                **
echo **  Compiling MAME OPL3EMU        **
echo **                                **
echo ************************************
echo.
%homedir%\utils\minigw\bin\gcc -c ymf262.c -o ymf262.o -shared -Wall -O1 -std=c99 -fms-extensions -DINLINE="static" 2>&1
echo.
echo ************************************
echo **                                **
echo **  Compiling APLIB               **
echo **                                **
echo ************************************
echo.
jwasm.exe -coff -Foaplib.o aplib.asm 2>&1
:aplib_ok
echo.
echo ************************************
echo **                                **
echo **  Compiling ADTRACK2            **
echo **                                **
echo ************************************
echo.
fpc.exe -O2 -OpPENTIUM2 -Ccpascal -Mtp -Rintel -Twin32 -WC -Fusdl adtrack2.pas -oadtrack2.exe
set ERR_RESULT="OK"
goto :end
:error
echo.
echo ************************************
echo **                                **
echo **  COMPILATION WAS ABORTED       **
echo **                                **
echo **  Some files are still in use   **
echo **  by other process!             **
echo **                                **
echo ************************************
:end
