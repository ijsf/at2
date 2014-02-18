@echo off
set homedir=%~d1\AT2_Compilation_Environment
cd %homedir%\at2-SDL
echo.
echo ************************************
echo **                                **
echo **  STEP 1/2                      **
echo **  Compiling sources             **
echo **                                **
echo ************************************
echo.
call make.bat >!log
if not exist adtrack2.exe goto :compile_error
echo.
echo ************************************
echo **                                **
echo **  STEP 2/2                      **
echo **  Executing program             **
echo **                                **
echo ************************************
echo.
start adtrack2
goto :ok
:compile_error
start %windir%\notepad.exe !log.
:ok
