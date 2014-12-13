start adtrack2.exe /cfg:sdl_screen_mode=1 /cfg:sdl_frame_rate=150
wmic process where name="adtrack2.exe" CALL setpriority "above normal"
