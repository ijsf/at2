@echo off
rem -------------------------------------
set VERSION=2.3.57
rem -------------------------------------
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
echo.
echo ************************************
echo **                                **
echo **  STEP 1/4                      **
echo **  Validating version info       **
echo **                                **
echo ************************************
copy /y utils\val_dos.exe validate.exe >nul
validate.exe %VERSION%
del validate.exe >nul
echo.
echo ************************************
echo **                                **
echo **  STEP 2/4                      **
echo **  Compiling sources             **
echo **                                **
echo ************************************
ppc386 -O2 -OpPENTIUM2 -Ccpascal -Mtp -Rintel -Tgo32v2 adtrack2.pas >!log
if not exist adtrack2.exe goto :compile_error
if not exist *.ppu goto :no_ppu_file
del *.ppu >nul
:no_ppu_file
if not exist *.o goto :no_o_file
del *.o >nul
:no_o_file
if not exist !log goto :no_log_file
del !log >nul
:no_log_file
echo.
echo ************************************
echo **                                **
echo **  STEP 3/4                      **
echo **  UPX: Compressing EXE file     **
echo **                                **
echo ************************************
c:\utils\upx -9 adtrack2.exe >nul
echo.
echo ************************************
echo **                                **
echo **  STEP 4/4                      **
echo **  Executing program             **
echo **                                **
echo ************************************
echo.
adtrack2
:compile_error
