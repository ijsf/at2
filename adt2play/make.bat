@echo off
del adt2play.exe >nul
echo Compiling ADT2PLAY...
..\utils\val2 ..\iloaders.inc iloaders.inc
tmtpc -$MAP+ -$W- adt2play >!log
