@echo off
set homedir=%~d1\AT2_Compilation_Environment
cd %homedir%\at2-SDL
set ERR_RESULT=???
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
if not %ERR_RESULT% == "OK" GOTO :compile_error
echo.
echo ************************************
echo **                                **
echo **  STEP 2/2                      **
echo **  Executing program             **
echo **                                **
echo ************************************
echo.
start adtrack2
goto :end
:compile_error
start %windir%\notepad.exe !log.
:end
