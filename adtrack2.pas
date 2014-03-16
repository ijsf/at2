program AdTrack2;

{$APPTYPE GUI}
{$PACKRECORDS 1}
{$R adtrack2.res}

uses
  SDL_Timer,
  AdT2sys,AdT2vid,AdT2keyb,AdT2vscr,AdT2opl3,AdT2apak, 
  AdT2unit,AdT2extn,AdT2ext2,AdT2ext3,AdT2text,
  TimerInt,StringIO,DialogIO,ParserIO,TxtScrIO,MenuLib1,MenuLib2;

var
  temp: Longint;

begin { MAIN }
  ShowStartMessage;

  { read and process adtrack2.ini file }
  If __debug__ then WriteLn('--- updating user configuration');
  process_config_file;

  { init system things }
  sys_init;

  { allocate memory for patterns }
  If __debug__ then WriteLn('--- allocating frame buffer for patterns');
  GetMem(pattdata,PATTERN_SIZE*max_patterns);
  If (max_patterns <> $80) then
      WriteLn('WARNING: Maximum number of patterns is ',max_patterns,'!');

  { adlib player init }
  If __debug__ then WriteLn('--- initializing player routine');
    init_player;

  { txtscrio init }
  TxtScrIO_Init;
  
  { dialogio init }
  DialogIO_Init;

  { MenuLib1 init }
  MenuLib1_Init;

  { MenuLib2 init }
  MenuLib2_Init;

  If __debug__ then WriteLn('--- initializing songdata');  
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

  If __debug__ then WriteLn('--- executing program core');
  vid_SetVideoMode(TRUE);

  { initializing interface (phase:4) }
  PROGRAM_SCREEN_init;
  POSITIONS_reset;

  If (command_typing <> 0) then GotoXY(08+pos4[pattern_hpos],11+8)
  else GotoXY(08+pos3[pattern_hpos],11+8);
  ThinCursor;

  { initializing timer }
  init_timer_proc;

  { initializing keyboard }
  keyboard_init;
  stop_playing;

  do_slide := TRUE;
  do_synchronize := TRUE;

  { initializing interface (phase:5) }
 
  { Main loop }
  fkey := kENTER;
  Repeat
    If (fkey = kENTER) then PATTERN_edit(pattern_patt,pattern_page,pattern_hpos);
    If (fkey = kENTER) then PATTERN_ORDER_edit(pattord_page,pattord_hpos,pattord_vpos);
  until (fkey = kESC) or (fkey = kF10) or _force_program_quit;

  { terminating program (phase:1) }
  If NOT tracing then ThinCursor;
  do_synchronize := FALSE;

  { terminating program (phase:2) }
  
  fade_out_playback(TRUE); // fade playback together with screen
  stop_playing;
  FillChar(decay_bar,SizeOf(decay_bar),0);
  FillChar(volum_bar,SizeOf(volum_bar),0);
  decay_bars_refresh;
  keyboard_done;
  done_timer_proc;
  opl3_deinit;
  Dispose(pattdata);
  ThinCursor;
  
  sdl_screen_mode := 0;
  TxtScrIO_Init;
  vid_SetVideoMode(FALSE);
  CleanScreen(v_ofs^);
  vid_SetRGBPalette(Addr(vga_rgb_color)^);
  temp := screen_scroll_offset DIV 16 + 4;

  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+00,ascii_line_01,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+01,ascii_line_02,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+02,ascii_line_03,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+03,ascii_line_04,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+04,ascii_line_05,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+05,ascii_line_06,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+06,ascii_line_07,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+07,ascii_line_08,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+08,ascii_line_09,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+09,ascii_line_10,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+10,ascii_line_11,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+11,ascii_line_12,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+12,ascii_line_13,$08,$07,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+13,ascii_line_14,$08,$09,$03);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+14,ascii_line_15,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+15,ascii_line_16,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+16,ascii_line_17,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+17,ascii_line_18,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+18,ascii_line_19,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+19,ascii_line_20,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+20,ascii_line_21,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+21,ascii_line_22,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+23,ascii_line_24,$08,$09,$01);
  C3WriteLn(02+(MAX_COLUMNS-57) DIV 2,temp+22,ascii_line_23,$08,$09,$01);
  Move(vga_font8x16,font8x16,SizeOf(font8x16));
  emulate_screen;
  SDL_Delay(3000);
  sys_deinit;
  snd_Deinit;

  { terminating program (phase:4) }
  (* HALT(0); // the last opportunity to properly exit?! :) *)
end.
