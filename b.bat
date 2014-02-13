@echo off
set homedir=%~d1\AT2_Compilation_Environment
cd %homedir%\at2-SDL
if exist !bak\ goto :dir_exist
mkdir !bak
:dir_exist
call d.bat
copy !bak\backup.zip !bak\backup.bak
del !bak\backup.zip
..\utils\7za a !bak\backup.zip -xr!!bak
