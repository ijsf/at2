@echo off
set homedir=%~d1\AT2_Compilation_Environment
cd %homedir%\at2-SDL
set ERR_RESULT=???
rem -------------------------------------
set VERSION=2.4.16
rem -------------------------------------
echo.
echo ************************************
echo **                                **
echo **  STEP 1/4                      **
echo **  Validating version info       **
echo **                                **
echo ************************************
echo.
copy /Y utils\validate.exe ..\at2-SDL >nul
validate.exe %VERSION%
del validate.exe
echo.
echo ************************************
echo **                                **
echo **  STEP 2/4                      **
echo **  Compiling sources             **
echo **                                **
echo ************************************
echo.
call make.bat >!log
if not exist adtrack2.exe goto :compile_error
if not %ERR_RESULT% == "OK" GOTO :compile_error
if not exist *.ppu goto :no_ppu_file
del /F /Q *.ppu
:no_ppu_file
if not exist *.o goto :no_o_file
del /F /Q *.o
:no_o_file
if not exist *.or goto :no_or_file
del /F /Q *.or
:no_or_file
if not exist *.res goto :no_res_file
del /F /Q *.res
:no_res_file
if not exist !log goto :no_log_file
del /F /Q !log
:no_log_file
echo.
echo ************************************
echo **                                **
echo **  STEP 3/4                      **
echo **  UPX: Compressing EXE file     **
echo **                                **
echo ************************************
echo.
..\utils\upx -9 adtrack2.exe >nul
echo.
echo ************************************
echo **                                **
echo **  STEP 4/4                      **
echo **  Executing program             **
echo **                                **
echo ************************************
echo.
start adtrack2
goto :end
:compile_error
start %windir%\notepad.exe !log.
:end
