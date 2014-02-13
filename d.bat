@echo off
set homedir=%~d1\AT2_Compilation_Environment
cd %homedir%\at2-SDL
echo.
echo ************************************
echo **                                **
echo **  Deleting old files            **
echo **                                **
echo ************************************
echo.
del *.exe
del *.ppu
del *.o
del *.s
del *.res
del *.or
del !log
