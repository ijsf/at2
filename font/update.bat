@echo Updating font data...
@copy ..\font8x16.inc ..\font8x16.bak /Y >nul
@copy font.com font.bak /Y >nul
@bpc truncfnt.pas /m >nul
@truncfnt
@data font.com >nul
@copy /B _pre_+font.inc+_post_ ..\font8x16.inc /Y >nul
@copy font.bak font.com /Y >nul
@del font.bak >nul
@echo OK
