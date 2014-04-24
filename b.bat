@echo off
set homedir=%~d1\AT2_Compilation_Environment
cd %homedir%\at2-SDL
if exist !bak\ goto :bak_dir_exist
mkdir !bak
:bak_dir_exist
call d.bat
echo.
echo ************************************
echo **                                **
echo **  Making backup of files        **
echo **                                **
echo ************************************
echo.
if not exist !bak\backup.zip goto :no_old_backup
copy /Y !bak\backup.zip !bak\backup.bak >nul
del !bak\backup.zip
:no_old_backup
..\utils\7za a !bak\backup.zip -xr!!bak -xr!wav_files >nul
