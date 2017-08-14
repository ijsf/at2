program AdLib_Tracker_2;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
{$i asmport.inc}
{$IFDEF WINDOWS}
{$APPTYPE GUI}
{$R adtrack2.res}
{$ENDIF}

{$IFDEF GO32V2}

uses
  CRT,GO32,
  AdT2opl3,AdT2unit,AdT2sys,AdT2extn,AdT2ext2,AdT2text,AdT2keyb,AdT2data,AdT2vesa,
  TxtScrIO,StringIO,DialogIO,ParserIO,MenuLib1,MenuLib2;

const
  scan_addresses: array[1..7] of Word = ($388,$210,$220,$230,$240,$250,$260);

var
  fade_buf,fade_buf2: tFADE_BUF;
  temp,index: Word;
  mem_info: tMemInfo;
  free_mem: Longint;
  opl3detected: Boolean;
  dos_dir: String;
  mouse_sx,mouse_sy,mouse_sd: Word;

procedure LoadFont(var font_data);

var
  regs: tRealRegs;
  dos_sel,dos_seg: Word;
  dos_mem_adr: Dword;

begin
  dos_mem_adr := global_dos_alloc(4096);
  dos_sel := WORD(dos_mem_adr);
  dos_seg := WORD(dos_mem_adr SHR 16);
  dosmemput(dos_seg,0,font_data,4096);
  FillChar(regs,SizeOf(regs),0);
  regs.ax := $1100;
  regs.bh := 16;
  regs.bl := 0;
  regs.es := dos_seg;
  regs.ds := dos_seg;
  regs.bp := 0;
  regs.cx := 256;
  regs.dx := 0;
  RealIntr($10,regs);
  global_dos_free(dos_sel);
end;

function mouse_driver_installed: Boolean;

const
  iret = $0cf;

var
  driver_ofs,driver_seg: Word;

begin
  driver_ofs := MEMW[0:$0cc];
  driver_seg := MEMW[0:$0ce];
  If (driver_seg <> 0) and (driver_ofs <> 0) and
     (MEM[driver_seg:driver_ofs] <> iret) then mouse_driver_installed := TRUE
  else mouse_driver_installed := FALSE;
end;

var
  old_exit_proc: procedure;

procedure new_exit_proc;
begin
  ExitProc := old_exit_proc;

  If mouse_active then
    asm
        mov     ax,1ah
        mov     bx,mouse_sx
        mov     cx,mouse_sy
        mov     dx,mouse_sd
        int     33h
    end;

  If (ExitCode <> 0) then
    begin
      asm  mov ax,03h; xor bh,bh; int 10h end;
      WriteLn(prog_exception_title);
      WriteLn('PROGRAM VERSION: ',at2ver,' from ',at2date,', ',at2link);
      WriteLn('ERROR_ID #'+Num2str(ExitCode,10)+' at '+ExpStrL(Num2str(LONGINT(ErrorAddr),16),8,'0'));
      WriteLn('STEP #1 -> ',_last_debug_str_);
      WriteLn('STEP #2 -> ',_debug_str_);
      WriteLn;
      WriteLn('Please send this information with brief description what you were doing');
      WriteLn('when you encountered this error to following email address:');
      WriteLn;
      WriteLn('subz3ro.altair@gmail.com');
      WriteLn;
      WriteLn('Thanks and sorry for your inconvenience! :-)');
      WriteLn;
      WriteLn;

      reset_player;
      sys_done;
      If (pattdata <> NIL) then
        FreeMem(pattdata,PATTERN_SIZE*max_patterns);
      ErrorAddr := NIL;
      HALT(ExitCode);
    end;
end;

procedure halt_startup(exitcode: Byte);
begin
  sys_done;
  If (pattdata <> NIL) then
    FreeMem(pattdata,PATTERN_SIZE*max_patterns);
  ExitProc := old_exit_proc;
  If (dos_dir <> '') then ChDir(dos_dir);
  HALT(exitcode);
end;

{$ELSE}

uses
  SDL_Timer,
  AdT2sys,AdT2keyb,AdT2opl3,AdT2unit,AdT2extn,AdT2ext2,AdT2ext3,AdT2text,AdT2data,
  StringIO,DialogIO,ParserIO,TxtScrIO,MenuLib1,MenuLib2;

var
  temp: Longint;

{$ENDIF}

begin { MAIN }
{$IFDEF GO32V2}

  old_exit_proc := ExitProc;
  ExitProc := @new_exit_proc;
  {$i-}
  GetDir(0,dos_dir);
  {$i+}

  If (IOresult <> 0) then dos_dir := '';
  ShowStartMessage;

//  WriteLn('******************************************');
//  WriteLn('**  TEST VERSION -- DO NOT DISTRIBUTE!  **');
//  WriteLn('******************************************');
//  WriteLn;

  { init system things }
  sys_init;

  For index := 1 to ParamCount do
    If (Lower(ParamStr(index)) = '/debug') then _debug_ := TRUE;

  If _debug_ then WriteLn('-------- DEBUG --------');
  If _debug_ then WriteLn('--- detecting available dos memory');

  asm
        mov     bx,0ffffh
        mov     ah,48h
        int     21h
        mov     dos_memavail,bx
  end;

  If (dos_memavail*16 DIV 1024 < 120) then
    begin
      WriteLn('ERROR(1) - Insufficient DOS memory!');
      halt_startup(1);
    end;

  If _debug_ then WriteLn('--- detecting available linear frame buffer');
  Get_MemInfo(mem_info);
  free_mem := mem_info.available_memory;

  If _debug_ then WriteLn('--- ## ',free_mem/1024/1000:0:2,'MB lfb found');
  If NOT (free_mem DIV 1024 > 5*1024) then
    begin
      WriteLn('ERROR(1) - Insufficient memory!');
      halt_startup(1);
    end;

  temp := 128;
  Repeat
    If (free_mem > PATTERN_SIZE*temp) then
      begin
        max_patterns := temp;
        BREAK;
      end
    else If (temp-16 >= 16) then Dec(temp,16)
         else begin
                WriteLn('ERROR(1) - Insufficient memory!');
                halt_startup(1);
              end;
  until FALSE;

  { allocate memory for patterns }
  If _debug_ then WriteLn('--- allocating frame buffer for patterns');

  GetMem(pattdata,PATTERN_SIZE*max_patterns);
  If NOT iVGA then
    begin
      WriteLn('ERROR(2) - Insufficient video equipment!');
      halt_startup(2);
    end;

  If (max_patterns <> $80) then
    WriteLn('WARNING: Maximum number of patterns is ',max_patterns,'!');

  { read and process adtrack2.ini file }
  If _debug_ then WriteLn('--- updating user configuration');
  process_config_file;

  { detect mouse }
  If _debug_ then WriteLn('--- detecting mouse');
  If NOT mouse_disabled then
    mouse_active := mouse_driver_installed;

  If NOT mouse_disabled and NOT mouse_active then
    If is_scrollable_screen_mode then
      WriteLn('WARNING: Mouse driver not installed!');

{$ELSE}

  screen_ptr := ptr_screen_emulator;
  ShowStartMessage;

  { init system things }
  sys_init;

  { read and process adtrack2.ini file }
  If _debug_ then WriteLn('--- updating user configuration');
  process_config_file;
  program_screen_mode := sdl_screen_mode;

  { allocate memory for patterns }
  If _debug_ then WriteLn('--- allocating frame buffer for patterns');
  max_patterns := 128;
  GetMem(pattdata,PATTERN_SIZE*max_patterns);

{$ENDIF}

{$IFDEF GO32V2}

  { detect opl3 }
  If _debug_ then WriteLn('--- processing opl3 detection');

  index := 1;
  If (opl3port <> 0) then
    If (opl3port < $100) then
      WriteLn('OPL3 interface base address forced to ',ExpStrL(Num2str(opl3port,16),2,'0'),'h')
    else If (opl3port < $1000) then
           WriteLn('OPL3 interface base address forced to ',ExpStrL(Num2str(opl3port,16),3,'0'),'h')
         else WriteLn('OPL3 interface base address forced to ',ExpStrL(Num2str(opl3port,16),4,'0'),'h')
  else begin
         opl3detected := FALSE;
         Repeat
           opl3port := scan_addresses[index];
           Inc(index);
           Write('Autodetecting OPL3 interface at ',
                 Num2str(opl3port,16),'h ... ');

           If NOT detect_OPL3 then
             begin
               If (index < 8) then Write(#13)
               else
                 begin
                   WriteLn('not responding!');
                   WriteLn;
                   WriteLn('Force base address in configuration file (section TROUBLESHOOTiNG)');
                   WriteLn('or directly from command-line using "/cfg:adlib_port=XXXX" option;');
                   WriteLn('XXXX range is 1-FFFFh');
                   halt_startup(3);
                end;
             end
           else
             begin
               opl3detected := TRUE;
               WriteLn('ok');
               BREAK;
             end;
         until opl3detected or (index > 7);
       end;

{$ENDIF}

  { intialize player routine }
  If _debug_ then WriteLn('--- initializing player routine');
{$IFDEF GO32V2}
  If (opl_latency <> 0) then opl3out := opl2out;
{$ENDIF}
  init_player;

  { initialize unit data }
  DialogIO_Init;
  StringIO_Init;
  TxtScrIO_Init;
  MenuLib1_Init;
  MenuLib2_Init;

  If _debug_ then WriteLn('--- initializing songdata');
  tempo := init_tempo;
  speed := init_speed;
  init_songdata;

  songdata_source := '';
  instdata_source := '';
  songdata_title  := 'noname.';
  bank_position_list_size := 0;

  FillChar(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
  play_status := isStopped;
  current_octave := default_octave;

  If use_h_for_b then b_note := 'h';
  For temp := 1 to 12*8+1 do
    If (note_layout[temp][1] = '%') then
      If NOT use_h_for_b then note_layout[temp][1] := 'B'
      else note_layout[temp][1] := 'H';

  If _debug_ then WriteLn('--- executing program core');

{$IFDEF GO32V2}

  WriteLn('Available memory: ',free_mem DIV 1024,'k (DOS: ',dos_memavail*16 DIV 1024,'k)');
  For temp := 1 to 50 do WaitRetrace;

  fade_speed := 16;
  fade_buf.action := first;
  VgaFade(fade_buf,fadeOut,delayed);

  For temp := 1 to 31 do
    If NOT _custom_svga_cfg[temp].flag or
       (_custom_svga_cfg[temp].value = -1) then
      begin
        custom_svga_mode := FALSE;
        BREAK;
      end;

  { initializing interface (phase:1) }

  If NOT is_VESA_emulated_mode then
    Case program_screen_mode of
      0: SetCustomVideoMode(36);       // 90x30

      1: If NOT custom_svga_mode then
           set_svga_txtmode_100x38     // 100x38
         else
           begin
             svga_txtmode_cols := _custom_svga_cfg[1].value;
             svga_txtmode_rows := _custom_svga_cfg[2].value;
             For temp := 1 to 29 do
               svga_txtmode_regs[temp].val := _custom_svga_cfg[2+temp].value;
             set_custom_svga_txtmode;
           end;

      2: If NOT custom_svga_mode then
           set_svga_txtmode_128x48     // 100x48
         else
           begin
             svga_txtmode_cols := _custom_svga_cfg[1].value;
             svga_txtmode_rows := _custom_svga_cfg[2].value;
             For temp := 1 to 29 do
               svga_txtmode_regs[temp].val := _custom_svga_cfg[2+temp].value;
             set_custom_svga_txtmode;
           end;

      3: Case comp_text_mode of
           0: SetCustomVideoMode(34);  // 80x30
           1: SetCustomVideoMode(25);  // 80x25
         end;

      4: set_svga_txtmode_100x38;      // 100x38
      5: set_svga_txtmode_128x48;      // 100x48
    end
  else
    Case get_VESA_emulated_mode_idx of
      0: begin
           VESA_Init;
           VESA_SetMode(VESA_800x600);
           VESA_SegLFB := Allocate_LDT_Descriptors(1);
           Set_Segment_Base_Address(VESA_SegLFB,
                                    Get_Linear_Addr(DWORD(VESA_FrameBuffer),
                                    VESA_VideoMemory*64*1024));
           Set_Segment_Limit(VESA_SegLFB,VESA_VideoMemory*64*1024-1);
           For temp := 0 to 15 do
             SetRGBitem(temp,rgb_color[temp].r,
                             rgb_color[temp].g,
                             rgb_color[temp].b);
         end;

      1: begin
           VESA_Init;
           VESA_SetMode(VESA_800x600);
           VESA_SegLFB := Allocate_LDT_Descriptors(1);
           Set_Segment_Base_Address(VESA_SegLFB,
                                    Get_Linear_Addr(DWORD(VESA_FrameBuffer),
                                    VESA_VideoMemory*64*1024));
           Set_Segment_Limit(VESA_SegLFB,VESA_VideoMemory*64*1024-1);
           For temp := 0 to 15 do
             SetRGBitem(temp,rgb_color[temp].r,
                             rgb_color[temp].g,
                             rgb_color[temp].b);
         end;

      2: begin
           VESA_Init;
           VESA_SetMode(VESA_1024x768);
           VESA_SegLFB := Allocate_LDT_Descriptors(1);
           Set_Segment_Base_Address(VESA_SegLFB,
                                    Get_Linear_Addr(DWORD(VESA_FrameBuffer),
                                    VESA_VideoMemory*64*1024));
           Set_Segment_Limit(VESA_SegLFB,VESA_VideoMemory*64*1024-1);
           For temp := 0 to 15 do
             SetRGBitem(temp,rgb_color[temp].r,
                             rgb_color[temp].g,
                             rgb_color[temp].b);
         end;
    end;

  For temp := 0 to 15 do
    Case temp of
      0..5,
         7: SetRGBitem(temp,   rgb_color[temp].r,rgb_color[temp].g,rgb_color[temp].b);
         6: SetRGBitem(temp+14,rgb_color[temp].r,rgb_color[temp].g,rgb_color[temp].b);
     8..15: SetRGBitem(temp+48,rgb_color[temp].r,rgb_color[temp].g,rgb_color[temp].b);
    end;

  If is_VESA_emulated_mode then
    begin
      VESA_GetPalette(fade_buf);
      FillChar(fade_buf2,SizeOf(fade_buf2),0);
      VESA_InitStepFade(fade_buf,fade_buf2,1);
      VESA_StepFade;
    end;

  { initializing interface (phase:2) }
  If NOT is_VESA_emulated_mode then
    begin
      HideCursor;
      LoadFont(font8x16);
      TXTSCRIO.initialize;
      hard_maxcol := MaxCol;
      hard_maxln := MaxLn;
      If NOT (program_screen_mode in [4,5]) then
        SetSize(MAX_COLUMNS,MAX_ROWS)
      else SetSize(SCREEN_RES_X DIV scr_font_width,MAX_ROWS);
      TXTSCRIO.initialize;
      do_synchronize := FALSE;
    end
  else
    begin
      v_seg := 0;
      v_ofs := Ofs(screen_emulator);
      screen_ptr := ptr_screen_emulator;
      mn_environment.v_dest := screen_ptr;
      TxtScrIO_Init;
    end;

  { initializing interface (phase:3) }
  work_MaxCol := MAX_COLUMNS;
  If (program_screen_mode in [4,5]) or
     ((program_screen_mode = 3) and (comp_text_mode = 4)) then
    work_MaxLn := MAX_ROWS
  else work_MaxLn := MAX_ROWS-10;

  If NOT is_VESA_emulated_mode then
    begin
      fade_buf.action := first;
      fade_speed := 1;
      VgaFade(fade_buf,fadeOut,fast);
      fade_speed := 32;
    end;

  asm
        mov     ah,03h
        mov     al,05h
        mov     bl,typematic_rate
        mov     bh,typematic_delay
        int     16h
        mov     ax,1003h
        xor     bl,bl
        int     10h
  end;

  If mouse_active then
    asm
        xor     ax,ax
        int     33h
        mov     ax,1bh
        int     33h
        mov     mouse_sx,bx
        mov     mouse_sy,cx
        mov     mouse_sd,dx
        mov     ax,04h
        xor     cx,cx
        xor     dx,dx
        int     33h
        mov     ax,1ah
        mov     bx,mouse_hspeed
        mov     cx,mouse_vspeed
        mov     dx,mouse_threshold
        int     33h
        mov     ax,07h
        mov     cx,0
        mov     dx,SCREEN_RES_x
        int     33h
        mov     ax,08h
        mov     cx,0
        mov     dx,SCREEN_RES_y
        int     33h
    end;

{$ELSE}

  vid_SetVideoMode(TRUE);

{$ENDIF}

  { initializing interface (phase:4) }
  PROGRAM_SCREEN_init;
  POSITIONS_reset;
  decay_bars_refresh;
  status_refresh;

  If (command_typing <> 0) then GotoXY(08+pos4[pattern_hpos],11+PRED(MAX_PATTERN_ROWS DIV 2))
  else GotoXY(08+pos3[pattern_hpos],11+PRED(MAX_PATTERN_ROWS DIV 2));
  ThinCursor;

  { initializing timer }
  init_timer_proc;

  { initializing keyboard }
  keyboard_init;
  stop_playing;

{$IFDEF GO32V2}

  { initializing interface (phase:5) }
  realtime_gfx_poll_proc;
  _draw_screen_without_vsync := TRUE;
  draw_screen;
  WaitRetrace;
  If NOT is_VESA_emulated_mode then
    begin
      For temp := 1 to 10 do WaitRetrace;
      VgaFade(fade_buf,fadeIn,delayed);
    end
  else
    begin
      VESA_InitStepFade(fade_buf2,fade_buf,20);
      For temp := 1 to 20 do
        begin
          VESA_StepFade;
          If keypressed then keyboard_reset_buffer;
        end;
    end;

{$ENDIF}

  { main loop }
  _debug_str_ := 'redirecting to main loop';
  do_synchronize := TRUE;
  fkey := kENTER;
  Repeat
    If (fkey = kENTER) then PATTERN_edit(pattern_patt,pattern_page,pattern_hpos);
    If (fkey = kENTER) then PATTERN_ORDER_edit(pattord_page,pattord_hpos,pattord_vpos);
  until (fkey = kESC) or (fkey = kF10) or _force_program_quit;

  { terminating program (phase:1) }
  If NOT tracing then ThinCursor;
  do_synchronize := FALSE;

{$IFDEF GO32V2}

  draw_screen;
  If NOT is_VESA_emulated_mode then
    fade_out_playback(TRUE)
  else
    begin
      VESA_InitStepFade(fade_buf,fade_buf2,20);
      For temp := 1 to 20 do
        begin
          VESA_StepFade;
          If (overall_volume > 3) then Dec(overall_volume,3)
          else overall_volume := 0;
          set_global_volume;
          If keypressed then keyboard_reset_buffer;
        end
    end;

{$ELSE}
  fade_out_playback(TRUE);
{$ENDIF}

  stop_playing;
  FillChar(decay_bar,SizeOf(decay_bar),0);
  FillChar(volum_bar,SizeOf(volum_bar),0);
  done_timer_proc;
  keyboard_done;
{$IFDEF GO32V2}
  opl3exp($0004);
  opl3exp($0005);
{$ELSE}
  opl3_done;
{$ENDIF}

  { terminating program (phase:2) }
  _realtime_gfx_no_update := TRUE;

{$IFDEF GO32V2}

  set_vga_txtmode_80x25;
  HideCursor;
  fade_buf.action := first;
  fade_speed := 1;
  VgaFade(fade_buf,fadeOut,fast);
  fade_speed := 32;

  GOTOXY_xshift := 0;
  GotoXY(1,1);
  C3WriteLn(ascii_line_01,$08,$09,$01);
  C3WriteLn(ascii_line_02,$08,$09,$01);
  C3WriteLn(ascii_line_03,$08,$09,$01);
  C3WriteLn(ascii_line_04,$08,$09,$01);
  C3WriteLn(ascii_line_05,$08,$09,$01);
  C3WriteLn(ascii_line_06,$08,$09,$01);
  C3WriteLn(ascii_line_07,$08,$09,$01);
  C3WriteLn(ascii_line_08,$08,$09,$01);
  C3WriteLn(ascii_line_09,$08,$09,$01);
  C3WriteLn(ascii_line_10,$08,$09,$01);
  C3WriteLn(ascii_line_11,$08,$09,$01);
  C3WriteLn(ascii_line_12,$08,$09,$01);
  C3WriteLn(ascii_line_13,$08,$07,$01);
  C3WriteLn(ascii_line_14,$08,$09,$03);
  C3WriteLn(ascii_line_15,$08,$09,$01);
  C3WriteLn(ascii_line_16,$08,$09,$01);
  C3WriteLn(ascii_line_17,$08,$09,$01);
  C3WriteLn(ascii_line_18,$08,$09,$01);
  C3WriteLn(ascii_line_19,$08,$09,$01);
  C3WriteLn(ascii_line_20,$08,$09,$01);
  C3WriteLn(ascii_line_21,$08,$09,$01);
  C3WriteLn(ascii_line_22,$08,$09,$01);
  C3WriteLn(ascii_line_23,$08,$09,$01);
  Move(vga_font8x16,font8x16,SizeOf(font8x16));
  dosmemput(v_seg,v_ofs,screen_ptr^,(SCREEN_RES_X DIV scr_font_width)*MAX_ROWS*2);

  For temp := 1 to 50 do WaitRetrace;
  VgaFade(fade_buf,fadeIn,delayed);
  ThinCursor;

  For temp := 1 to 50 do WaitRetrace;
  { terminating program (phase:3) }
  sys_done;
  FreeMem(pattdata,PATTERN_SIZE*max_patterns);
  ExitProc := old_exit_proc;
  If (dos_dir <> '') then ChDir(dos_dir);

{$ELSE}

  program_screen_mode := 0;
  TxtScrIO_Init;
  vid_SetVideoMode(FALSE);
  vid_SetRGBPalette(Addr(vga_rgb_color)^);
  temp := screen_scroll_offset DIV 16 + 3;
  HideCursor;

  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+01,ascii_line_01,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+02,ascii_line_02,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+03,ascii_line_03,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+04,ascii_line_04,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+05,ascii_line_05,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+06,ascii_line_06,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+07,ascii_line_07,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+08,ascii_line_08,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+09,ascii_line_09,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+10,ascii_line_10,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+11,ascii_line_11,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+12,ascii_line_12,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+13,ascii_line_13,$08,$07,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+14,ascii_line_14,$08,$09,$03);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+15,ascii_line_15,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+16,ascii_line_16,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+17,ascii_line_17,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+18,ascii_line_18,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+19,ascii_line_19,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+20,ascii_line_20,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+21,ascii_line_21,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+22,ascii_line_22,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+23,ascii_line_23,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+24,ascii_line_24,$08,$09,$01);
  Move(vga_font8x16,font8x16,SizeOf(font8x16));
  draw_screen;
  SDL_Delay(3000);

  { terminating program (phase:3) }
  sys_done;
  snd_done;
  FreeMem(pattdata,PATTERN_SIZE*max_patterns);

{$ENDIF}

end.
