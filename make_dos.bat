@echo off
rem -------------------------------------
set VERSION=2.3.53
rem -------------------------------------
if not exist *.exe goto :no_exe_file
del *.exe >nul
:no_exe_file
if not exist *.obj goto :no_obj_file
del *.obj
:no_obj_file
if not exist !log goto :no_log_file
del !log
:no_log_file
echo.
echo ************************************
echo **                                **
echo **  STEP 1/5                      **
echo **  Validating version info       **
echo **                                **
echo ************************************
copy /y utils\val_dos.exe validate.exe >nul
validate.exe %VERSION%
del validate.exe
echo.
echo ************************************
echo **                                **
echo **  STEP 2/5                      **
echo **  Compiling sources             **
echo **                                **
echo ************************************
tasm aplib.asm /m2 >!log
if not exist aplib.obj goto :compile_error
tmtpc -M -STACK:1024000 -$MAP+ -$W- -OBJMAX:1024000 adtrack2.pas >!log
if not exist adtrack2.exe goto :compile_error
if not exist *.fpd goto :no_fpd_file
del *.fpd >nul
:no_fpd_file
if not exist *.map goto :no_map_file
del *.map
:no_map_file
if not exist *.obj goto :no_obj_file
del *.obj
:no_obj_file
if not exist *.sym goto :no_sym_file
del *.sym
:no_sym_file
if not exist !log goto :no_log_file
del !log
:no_log_file
echo.
echo ************************************
echo **                                **
echo **  STEP 3/5                      **
echo **  PMODE/W: Removing copyright   **
echo **                                **
echo ************************************
pmwsetup /B0 adtrack2.exe >nul
echo.
echo ************************************
echo **                                **
echo **  STEP 4/5                      **
echo **  UPX: Compressing EXE file     **
echo **                                **
echo ************************************
upx -9 adtrack2.exe >nul
echo.
echo ************************************
echo **                                **
echo **  STEP 5/5                      **
echo **  Executing program             **
echo **                                **
echo ************************************
echo.
adtrack2
:compile_error
