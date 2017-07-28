@echo off
echo.
echo ************************************
echo **                                **
echo **  STEP 1/2                      **
echo **  Compiling sources             **
echo **                                **
echo ************************************
..\utils\val2 ..\iloaders.inc iloaders.inc
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
ppc386 -O2 -OpPENTIUM2 -Ccpascal -Mtp -Rintel -Tgo32v2 adt2play >!log
if not exist adt2play.exe goto :compile_error
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
echo **  STEP 2/2                      **
echo **  UPX: Compressing executable   **
echo **                                **
echo ************************************
c:\utils\upx -9 adt2play.exe >nul
echo.
:compile_error
