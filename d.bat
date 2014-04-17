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
if not exist *.exe goto :no_exe_file
del /F /Q *.exe
:no_exe_file
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
