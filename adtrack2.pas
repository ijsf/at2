program AdTrack2;
{$IFDEF __TMT__}
{$S-,Q-,R-,V-,B-,X+}
{$ELSE}
{$IFDEF WINDOWS}
{$APPTYPE GUI}
{$R adtrack2.res}
{$ENDIF}
{$PACKRECORDS 1}
{$ENDIF}

{$IFDEF __TMT__}

uses
  CRT,LFB256,
  AdT2opl3,AdT2unit,AdT2sys,AdT2extn,AdT2ext2,AdT2text,AdT2keyb,AdT2data,
  TimerInt,TxtScrIO,StringIO,DialogIO,ParserIO,MenuLib1,MenuLib2;

const
  scan_addresses: array[1..7] of Word = ($388,$210,$220,$230,$240,$250,$260);

var
  fade_buf,fade_buf2: tFADE_BUF;
  temp,index: Word;
  opl3detected: Boolean;
  dos_dir: String;

procedure LoadFont(var font_data); assembler;
asm
        // set access to font memory
        mov     dx,3c4h
        mov     ax,0402h
        out     dx,ax
        mov     ax,0704h
        out     dx,ax
        mov     dx,3ceh
        mov     ax,0005h
        out     dx,ax
        mov     ax,0406h
        out     dx,ax
        mov     ax,0204h
        out     dx,ax
        // load font
        mov     edi,0a0000h
        mov     esi,dword ptr [font_data]
        mov     eax,256*16*2
        mov     ebx,16*2
        mov     edx,16
        cld
@@1:    mov     ecx,edx
        rep     movsb
        mov     ecx,ebx
        sub     ecx,edx
        add     edi,ecx
        sub     eax,ebx
        or      eax,eax
        jnz     @@1
        // set access to text memory
        mov     dx,3c4h
        mov     ax,0302h
        out     dx,ax
        mov     ax,0304h
        out     dx,ax
        mov     dx,3ceh
        mov     ax,1005h
        out     dx,ax
        mov     ax,0e06h
        out     dx,ax
        mov     ax,0004h
        out     dx,ax
end;

var
  old_exit_proc: procedure;

procedure new_exit_proc; far;
begin
  asm
      mov   ax,03h
      xor   bh,bh
      int   10h
      mov   MaxCol,80
      mov   MaxLn,25
  end;

  WriteLn('ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ');
  WriteLn('Û ABNORMAL PROGRAM TERMiNATiON Û');
  WriteLn('ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß');
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

  FreeMem(pattdata,PATTERN_SIZE*max_patterns);
  ErrorAddr := NIL;
  HALT(ExitCode);
end;

{$ELSE}

uses
  SDL_Timer,
  AdT2sys,AdT2keyb,AdT2opl3,AdT2unit,AdT2extn,AdT2ext2,AdT2ext3,AdT2text,AdT2data,
  TimerInt,StringIO,DialogIO,ParserIO,TxtScrIO,MenuLib1,MenuLib2;

var
  temp: Longint;

{$ENDIF}

begin { MAIN }
{$IFDEF __TMT__}

  @old_exit_proc := ExitProc;
  ExitProc := @new_exit_proc;
  {$i-}
  GetDir(0,dos_dir);
  {$i+}

  If (IOresult <> 0) then dos_dir := '';
  ShowStartMessage;

  WriteLn('******************************************');
  WriteLn('**  TEST VERSION -- DO NOT DISTRIBUTE!  **');
  WriteLn('******************************************');
  WriteLn;

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
      HALT(1);
    end;

  If _debug_ then WriteLn('--- detecting available linear frame buffer');
  If _debug_ then WriteLn('--- ## ',MemAvail/1024/1000:0:2,'MB lfb found');

  If NOT (MemAvail DIV 1024 > 5*1024) then
    begin
      WriteLn('ERROR(1) - Insufficient memory!');
      HALT(1);
    end;

  temp := $80;
  Repeat
    If (MemAvail > PATTERN_SIZE*temp) then
      begin
        max_patterns := temp;
        BREAK;
      end
    else If (temp-$10 >= $10) then Dec(temp,$10)
         else begin
                WriteLn('ERROR(1) - Insufficient memory!');
                HALT(1);
              end;
  until FALSE;

  { allocate memory for patterns }
  If _debug_ then WriteLn('--- allocating frame buffer for patterns');

  GetMem(pattdata,PATTERN_SIZE*max_patterns);
  If NOT iVGA then
    begin
      WriteLn('ERROR(2) - Insufficient video equipment!');
      HALT(2);
    end;

  If (max_patterns <> $80) then
    WriteLn('WARNING: Maximum number of patterns is ',max_patterns,'!');

  { read and process adtrack2.ini file }
  If _debug_ then WriteLn('--- updating user configuration');

  process_config_file;

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

{$IFDEF __TMT__}

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

           If NOT iAdLibGold then
             begin
               If (index < 8) then Write(#13) else
                 begin
                   WriteLn('not responding!');
                   WriteLn;
                   WriteLn('Force base address in configuration file (section TROUBLESHOOTiNG)');
                   WriteLn('or directly from command-line using "/aXXXX" option;');
                   WriteLn('XXXX range is 1-FFFFh');
                   HALT(4);
                end;
             end
           else
             begin
               opl3detected := TRUE;
               WriteLn('ok');
               BREAK;
             end;
         until opl3detected or (index > 8);
       end;

{$ENDIF}

  { intialize player routine }
  If _debug_ then WriteLn('--- initializing player routine');
{$IFDEF __TMT__}
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

  FillChar(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
  play_status := isStopped;
  current_octave := default_octave;

  If use_h_for_b then b_note := 'h';
  For temp := 1 to 12*8+1 do
    If (note_layout[temp][1] = '%') then
      If NOT use_h_for_b then note_layout[temp][1] := 'B'
      else note_layout[temp][1] := 'H';

  If _debug_ then WriteLn('--- executing program core');

{$IFDEF __TMT__}

  WriteLn('Available memory: ',MemAvail DIV 1024,'k (DOS: ',dos_memavail*16 DIV 1024,'k)');
  Delay(3000);
  fade_speed := 16;
  fade_buf.action := first;
  VgaFade(fade_buf,fadeOut,delayed);

  { initializing interface (phase:1) }
  Case program_screen_mode of
    0,1,
    2: SetCustomVideoMode(36);       // 90x30
    3: Case comp_text_mode of
         0: SetCustomVideoMode(34);  // 80x30
         1: SetCustomVideoMode(25);  // 80x25

         2: begin
              _VBE2_Init;
              _SetMode(_800x600);
              For temp := 0 to 15 do
               _SetRGB(temp,rgb_color[temp].r,
                            rgb_color[temp].g,
                            rgb_color[temp].b);
            end;
       end;

    4: begin
         _VBE2_Init;
         _SetMode(_800x600);
         For temp := 0 to 15 do
          _SetRGB(temp,rgb_color[temp].r,
                       rgb_color[temp].g,
                       rgb_color[temp].b);
       end;

    5: begin
         _VBE2_Init;
         _SetMode(_1024x768);
         For temp := 0 to 15 do
          _SetRGB(temp,rgb_color[temp].r,
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

  If (program_screen_mode > 3) or
     ((program_screen_mode = 3) and NOT (comp_text_mode < 2)) then
    begin
      _GetPalette(fade_buf);
      FillChar(fade_buf2,SizeOf(fade_buf2),0);
      _InitStepFade(fade_buf,fade_buf2,1);
      _StepFade;
    end;

  { initializing interface (phase:2) }
  If (program_screen_mode < 3) or
     ((program_screen_mode = 3) and (comp_text_mode < 2)) then
    begin
      HideCursor;
      LoadFont(font8x16);
      TXTSCRIO.initialize;
      hard_maxcol := MaxCol;
      hard_maxln := MaxLn;
      SetSize(MAX_COLUMNS,MAX_ROWS);
      TXTSCRIO.initialize;
    end
  else
    begin
      v_seg := 0;
      v_ofs := Ofs(screen_emulator);
      screen_ptr := ptr_screen_emulator
    end;

  CleanScreen(screen_ptr);
  mn_environment.v_dest := screen_ptr;
  centered_frame_vdest := screen_ptr;

  { initializing interface (phase:3) }
  work_MaxCol := MAX_COLUMNS;
  If (program_screen_mode in [0,3]) then work_MaxLn := 30
  else work_MaxLn := MAX_ROWS-10;
  If (program_screen_mode < 3) or
     ((program_screen_mode = 3) and (comp_text_mode < 2)) then
    begin
      SetTextDisp(0,MaxLn*scr_font_height);
      For temp := 1 to 50 do WaitRetrace;
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

{$ELSE}
  vid_SetVideoMode(TRUE);
{$ENDIF}

  { initializing interface (phase:4) }
  PROGRAM_SCREEN_init;
  POSITIONS_reset;

  If (command_typing <> 0) then GotoXY(08+pos4[pattern_hpos],11+PRED(MAX_PATTERN_ROWS DIV 2))
  else GotoXY(08+pos3[pattern_hpos],11+PRED(MAX_PATTERN_ROWS DIV 2));
  ThinCursor;

  { initializing timer }
  init_timer_proc;

  { initializing keyboard }
  keyboard_init;
  stop_playing;

  do_slide := TRUE;
  do_synchronize := FALSE;

{$IFDEF __TMT__}

  { initializing interface (phase:5) }
  If (program_screen_mode < 3) or
     ((program_screen_mode = 3) and (comp_text_mode < 2)) then
    For temp := MaxLn*scr_font_height downto 0 do
      begin
        keyboard_reset_buffer;
        realtime_gfx_poll_proc;
        If (temp MOD scr_font_height = 0) then WaitRetrace;
        SetTextDisp(0,temp);
      end
  else
    begin
      _InitStepFade(fade_buf2,fade_buf,20);
      For temp := 1 to 20 do
        begin
          _StepFade;
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

{$IFDEF __TMT__ }

  If (program_screen_mode < 3) or
     ((program_screen_mode = 3) and (comp_text_mode < 2)) then
    begin
      index := min(overall_volume DIV (MaxLn-scr_scroll_y DIV 16),1);
      While (scr_scroll_y < MaxLn*scr_font_height) do
        begin
          keyboard_reset_buffer;
          realtime_gfx_poll_proc;
          Inc(scr_scroll_y);
          If (play_status <> isStopped) then
            begin
              If (scr_scroll_y MOD scr_font_height = 0) then
                begin
                  If (overall_volume > 0) then Dec(overall_volume,index);
                  set_global_volume;
                end;
            end;
          If (scr_scroll_y MOD scr_font_height = 0) then WaitRetrace;
          SetTextDisp(scr_scroll_x,scr_scroll_y);
        end;
    end
  else
    begin
      _InitStepFade(fade_buf,fade_buf2,20);
      For temp := 1 to 20 do
        begin
          _StepFade;
          If (overall_volume > 3) then Dec(overall_volume,3)
          else overall_volume := 0;
          set_global_volume;
          If keypressed then keyboard_reset_buffer;
        end
    end;

{$ELSE}
  fade_out_playback(TRUE); // fade playback together with screen
{$ENDIF}

  stop_playing;
  FillChar(decay_bar,SizeOf(decay_bar),0);
  FillChar(volum_bar,SizeOf(volum_bar),0);
  done_timer_proc;
  keyboard_done;
{$IFDEF __TMT__}
  opl3exp($0004);
  opl3exp($0005);
{$ELSE}
  opl3_deinit;
{$ENDIF}

  { terminating program (phase:2) }
  _realtime_gfx_no_update := TRUE;

{$IFDEF __TMT__}

  If (program_screen_mode < 3) or
     ((program_screen_mode = 3) and (comp_text_mode < 2)) then
    asm
        mov     ax,03h
        xor     bh,bh
        int     10h
        mov     MaxCol,80
        mov     MaxLn,25
    end
  else
    _SetTextMode;

  comp_text_mode := 0;
  program_screen_mode := 3;
  TXTSCRIO.initialize;

  HideCursor;
  fade_buf.action := first;
  fade_speed := 1;
  VgaFade(fade_buf,fadeOut,fast);
  fade_speed := 32;

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

  For temp := 1 to 50 do WaitRetrace;
  VgaFade(fade_buf,fadeIn,delayed);
  ThinCursor;

  { terminating program (phase:3) }
  sys_deinit;
  FreeMem(pattdata,PATTERN_SIZE*max_patterns);
  ExitProc := @old_exit_proc;
  If (dos_dir <> '') then ChDir(dos_dir);
  HALT(0);

{$ELSE}

  program_screen_mode := 0;
  TxtScrIO_Init;
  vid_SetVideoMode(FALSE);
  CleanScreen(screen_ptr);
  vid_SetRGBPalette(Addr(vga_rgb_color)^);
  temp := screen_scroll_offset DIV 16 + 3;

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
  emulate_screen;
  SDL_Delay(3000);

  { terminating program (phase:3) }
  sys_deinit;
  snd_deinit;
  FreeMem(pattdata,PATTERN_SIZE*max_patterns);

{$ENDIF}

end.
