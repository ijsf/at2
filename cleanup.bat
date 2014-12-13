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
if not exist adt2play\*.exe goto :no_exe_file2
del adt2play\*.exe >nul
:no_exe_file2
if not exist adt2play\*.fpd goto :no_fpd_file2
del adt2play\*.fpd >nul
:no_fpd_file2
if not exist adt2play\*.map goto :no_map_file2
del adt2play\*.map
:no_map_file2
if not exist adt2play\*.obj goto :no_obj_file2
del adt2play\*.obj
:no_obj_file2
if not exist adt2play\*.sym goto :no_sym_file2
del adt2play\*.sym
:no_sym_file2
if not exist adt2play\!log goto :no_log_file2
del adt2play\!log
:no_log_file2
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
if not exist sdl\*.ppu goto :no_ppu_file2
del /F /Q sdl\*.ppu
:no_ppu_file2
if not exist sdl\*.o goto :no_o_file2
del /F /Q sdl\*.o
:no_o_file2
if not exist sdl\*.a goto :no_a_file
del /F /Q sdl\*.a
:no_a_file
