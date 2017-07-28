@echo off
if exist adtrack2.res goto :res_ok
windres -i adtrack2.rc -o adtrack2.res
:res_ok
if not exist adtrack2.exe goto :exe_ok
del /F /Q adtrack2.exe >nul
if exist adtrack2.exe goto :error
:exe_ok
echo.
echo ************************************
echo **                                **
echo **  Compiling ADTRACK2            **
echo **                                **
echo ************************************
echo.
fpc.exe -O2 -OpPENTIUM2 -Ccpascal -Mtp -Rintel -Twin32 -WC -Fusdl adtrack2.pas -oadtrack2.exe
set ERR_RESULT="OK"
goto :end
:error
echo.
echo ************************************
echo **                                **
echo **  COMPILATION WAS ABORTED       **
echo **                                **
echo **  Some files are still in use   **
echo **  by other process!             **
echo **                                **
echo ************************************
:end
