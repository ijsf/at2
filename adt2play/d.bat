@echo off
echo.
echo ************************************
echo **                                **
echo **  Deleting file garbage         **
echo **                                **
echo ************************************
echo.
if not exist *.exe goto :no_exe_file
del *.exe >nul
:no_exe_file
if not exist *.ppu goto :no_ppu_file
del *.ppu >nul
:no_ppu_file
if not exist *.o goto :no_o_file
del *.o >nul
:no_o_file
if not exist !log goto :no_log_file
del !log >nul
:no_log_file
