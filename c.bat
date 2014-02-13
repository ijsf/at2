@echo off
set homedir=%~d1\AT2_Compilation_Environment
cd %homedir%\at2-SDL
echo.
echo ************************************
echo **                                **
echo **  Compilation in progress       **
echo **                                **
echo ************************************
echo.
call make.bat >!log
if not exist adtrack2.exe goto :compile_error
start adtrack2
goto :ok
:compile_error
..\utils\notepad++\notepad++ !log.
:ok
