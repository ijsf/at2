@echo off
set homedir=%~d1\AT2_Compilation_Environment
cd %homedir%\at2-SDL
set VERSION=2.4.10 050
echo.
echo ************************************
echo **                                **
echo **  Validating                    **
echo **                                **
echo ************************************
echo.
copy utils\validate.exe ..\at2-SDL >nul
validate.exe %VERSION%
del validate.exe
echo.
echo ************************************
echo **                                **
echo **  Compilation in progress       **
echo **                                **
echo ************************************
echo.
@call make.bat >!log
if not exist adtrack2.exe goto :compile_error
del *.ppu
del *.o
del *.s
del *.res
del *.or
del !log
echo.
echo ************************************
echo **                                **
echo **  UPXW: Compressing executable  **
echo **                                **
echo ************************************
echo.
@..\utils\upx adtrack2.exe
echo.
echo ************************************
echo **                                **
echo **  Executing program             **
echo **                                **
echo ************************************
echo.
start adtrack2
goto :ok
:compile_error
..\utils\notepad++\notepad++ !log.
:ok
