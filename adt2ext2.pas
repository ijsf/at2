unit AdT2ext2;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
{$i asmport.inc}
interface

const
  quick_mark_type: Byte = 0;
  discard_block: Boolean = FALSE;
  old_chan_pos: Byte = 1;
  old_hpos: Byte = 1;
  old_page: Byte = 0;
  old_block_chan_pos: Byte = 1;
  old_block_patt_hpos: Byte = 1;
  old_block_patt_page: Byte = 0;

procedure process_global_keys;

procedure PROGRAM_SCREEN_init;
function  INSTRUMENT_CONTROL_alt(instr: Byte; title: String): Byte;

procedure INSTRUMENT_test(instr,instr2,chan: Byte; fkey: Word;
                          process_macros: Boolean);

procedure INSTRUMENT_CONTROL_page_refresh(page: Byte);
procedure INSTRUMENT_CONTROL_edit;

procedure PATTERN_ORDER_page_refresh(page: Byte);
procedure PATTERN_ORDER_edit(var page,hpos,vpos: Byte);

procedure PATTERN_tabs_refresh;
procedure PATTERN_page_refresh(page: Byte);
procedure STATUS_LINE_refresh;

procedure PATTERN_position_preview(pattern,line,channel,mode: Byte);
function  PATTERN_trace: Word;
procedure PATTERN_edit(var pattern,page,hpos: Byte);

procedure process_config_file;

function  _1st_marked: Byte;
function  _2nd_marked: Byte;
function  marked_instruments: Byte;
procedure reset_marked_instruments;
function  get_4op_to_test: Word;
function  check_4op_to_test: Word;
function  check_4op_instrument(ins: Byte): Word;
function  check_4op_flag(ins: Byte): Boolean;
procedure reset_4op_flag(ins: Byte);
procedure set_4op_flag(ins: Byte);
procedure update_4op_flag_marks;

implementation

uses
{$IFNDEF UNIX}
  CRT,
{$ENDIF}
{$IFDEF GO32V2}
  GO32,
{$ELSE}
  SDL_Timer,
{$ENDIF}
  AdT2opl3,AdT2unit,AdT2sys,AdT2extn,AdT2ext4,AdT2ext5,AdT2text,AdT2pack,AdT2keyb,
  TxtScrIO,StringIO,DialogIO,ParserIO;

var
  old_pattern_patt,old_pattern_page,
  old_pattern_hpos,
  old_block_xstart,old_block_ystart: Byte;
  old_marking: Boolean;

{$i instedit.inc}
{$i ipattord.inc}
{$i ipattern.inc}

procedure FADE_OUT_RECORDING;

{$IFNDEF GO32V2}

const
   frame_start: Longint = 0;
   frame_end: Longint = 0;
   actual_frame_end: Longint = 0;

var
  xstart,ystart: Byte;
  temp,temp2: Byte;

label _jmp1,_end;

begin
  If (play_status = isStopped) or (sdl_opl3_emulator = 0) then
    begin
      sdl_opl3_emulator := 0;
      opl3_channel_recording_mode := FALSE;
      EXIT;
    end;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  centered_frame_vdest := screen_ptr;
  HideCursor;

  dl_environment.context := ' ESC '#196#16' STOP ';
  centered_frame(xstart,ystart,43,3,' WAV RECORDER ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);
  ShowStr(screen_ptr,xstart+43-Length(dl_environment.context),ystart+3,
          dl_environment.context,
          dialog_background+dialog_border);
  dl_environment.context := '';

  show_progress(40);
  ShowStr(screen_ptr,xstart+2,ystart+1,
          'FADiNG OUT WAV RECORDiNG...',
          dialog_background+dialog_text);

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;
  progress_num_steps := 1;
  progress_step := 1;
  progress_value:= 63;
  progress_old_value := BYTE_NULL;

  For temp := 63 downto 0 do
    begin
      If scankey(1) then GOTO _jmp1;
      fade_out_volume := temp;
      set_global_volume;
      show_progress(temp);
      For temp2 := 1 to 10 do
        begin
          If scankey(1) then GOTO _jmp1;
          keyboard_reset_buffer;
          actual_frame_end := SDL_GetTicks;
          frame_end := frame_start+fade_delay_tab[temp];
          If (actual_frame_end+fade_delay_tab[temp] > frame_end) then
            begin
              frame_end := actual_frame_end;
              _draw_screen_without_delay := TRUE;
              draw_screen;
            end;
          SDL_Delay(frame_end-actual_frame_end);
          frame_start := SDL_GetTicks;
        end;
      _draw_screen_without_delay := TRUE;
      draw_screen;
    end;

 _jmp1:

  show_progress(0);
  ShowStr(screen_ptr,xstart+2,ystart+1,
          'FADiNG iN SONG PLAYBACK... ',
          dialog_background+dialog_text);

  flush_WAV_data;
  sdl_opl3_emulator := 0;
  opl3_channel_recording_mode := FALSE;

  For temp := 0 to 63 do
    begin
      If scankey(1) then GOTO _end;
      fade_out_volume := temp;
      set_global_volume;
      show_progress(temp);
      If scankey(1) then GOTO _end;
      _draw_screen_without_delay := TRUE;
      draw_screen;
      keyboard_reset_buffer;
      actual_frame_end := SDL_GetTicks;
      frame_end := frame_start+5;
      If (actual_frame_end > frame_end) then frame_end := actual_frame_end;
      SDL_Delay(frame_end-actual_frame_end);
      frame_start := SDL_GetTicks;
    end;

_end:

  flush_WAV_data;
  sdl_opl3_emulator := 0;
  opl3_channel_recording_mode := FALSE;
  fade_out_volume := 63;
  set_global_volume;

  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;

{$ELSE}

begin

{$ENDIF}

end;

procedure FADE_IN_RECORDING;

{$IFNDEF GO32V2}

const
  frame_start: Longint = 0;
  frame_end: Longint = 0;
  actual_frame_end: Longint = 0;

var
  xstart,ystart: Byte;
  temp,temp2: Byte;
  smooth_fadeOut: Boolean;

label _end;

begin
  If (sdl_opl3_emulator = 1) or (calc_following_order(0) = -1) then EXIT;
  If (play_status = isStopped) then smooth_fadeOut := FALSE
  else smooth_fadeOut := TRUE;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  centered_frame_vdest := screen_ptr;
  HideCursor;

  dl_environment.context := ' ESC '#196#16' STOP ';
  centered_frame(xstart,ystart,43,3,' WAV RECORDER ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);
  ShowStr(screen_ptr,xstart+43-Length(dl_environment.context),ystart+3,
          dl_environment.context,
          dialog_background+dialog_border);
  dl_environment.context := '';

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;
  progress_num_steps := 1;
  progress_step := 1;
  progress_value:= 63;
  progress_old_value := BYTE_NULL;

  If smooth_fadeOut then
    begin
      show_progress(40);
      ShowStr(screen_ptr,xstart+2,ystart+1,
              'FADiNG OUT SONG PLAYBACK...',
              dialog_background+dialog_text);

      For temp := 63 downto 0 do
        begin
          If scankey(1) then GOTO _end;
          fade_out_volume := temp;
          set_global_volume;
          show_progress(temp);
          _draw_screen_without_delay := TRUE;
          draw_screen;
          keyboard_reset_buffer;
          actual_frame_end := SDL_GetTicks;
          frame_end := frame_start+5;
          If (actual_frame_end > frame_end) then frame_end := actual_frame_end;
          SDL_Delay(frame_end-actual_frame_end);
          frame_start := SDL_GetTicks;
          If scankey(1) then GOTO _end;
        end;
    end
  else
    SDL_Delay(100);

  show_progress(0);
  ShowStr(screen_ptr,xstart+2,ystart+1,
          'FADiNG iN WAV RECORDiNG... ',
          dialog_background+dialog_text);

  Case play_status of
    isStopped: begin
                 If trace_by_default then tracing := TRUE;
                 start_playing;
               end;
    isPaused:  begin
                 replay_forbidden := FALSE;
                 play_status := isPlaying;
               end;
  end;

  fade_out_playback(FALSE);
  sdl_opl3_emulator := 1;

  For temp := 0 to 63 do
    begin
      If scankey(1) then GOTO _end;
      fade_out_volume := temp;
      set_global_volume;
      show_progress(temp);
      _draw_screen_without_delay := TRUE;
      draw_screen;

      For temp2 := 1 to 10 do
        begin
          If scankey(1) then GOTO _end;
          keyboard_reset_buffer;
          actual_frame_end := SDL_GetTicks;
          frame_end := frame_start+fade_delay_tab[temp];
          If (actual_frame_end+fade_delay_tab[temp] > frame_end) then
            begin
              frame_end := actual_frame_end;
              _draw_screen_without_delay := TRUE;
              draw_screen;
            end;
          SDL_Delay(frame_end-actual_frame_end);
          frame_start := SDL_GetTicks;
        end;
      _draw_screen_without_delay := TRUE;
      draw_screen;
    end;

_end:

  sdl_opl3_emulator := 1;
  fade_out_volume := 63;
  set_global_volume;

  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;

{$ELSE}

begin

{$ENDIF}

end;

procedure process_global_keys;

var
  temp,temp2: Byte;
  start_row,end_row: Byte;
  chunk: tCHUNK;

begin
  If NOT ins_trailing_flag and ctrl_pressed then
    If scankey(SC_1) then current_octave := 1
    else If scankey(SC_2) then current_octave := 2
         else If scankey(SC_3) then current_octave := 3
              else If scankey(SC_4) then current_octave := 4
                   else If scankey(SC_5) then current_octave := 5
                        else If scankey(SC_6) then current_octave := 6
                             else If scankey(SC_7) then current_octave := 7
                                  else If scankey(SC_8) then current_octave := 8;

  If alt_pressed and NOT ctrl_pressed then
    If scankey(SC_PLUS) or (shift_pressed and scankey(SC_UP)) then
      begin
        If (overall_volume < 63) then
          begin
            Inc(overall_volume);
            set_global_volume;
          end;
      end
    else If scankey(SC_MINUS2) or (shift_pressed and scankey(SC_DOWN)) then
           begin
             If (overall_volume > 0) then
               begin
                 Dec(overall_volume);
                 set_global_volume;
               end;
           end;

{$IFNDEF GO32V2}

  If scankey(SC_F11) and
     ((alt_pressed and NOT ctrl_pressed) or
      (ctrl_pressed and NOT alt_pressed)) then
    begin
      If ctrl_pressed and NOT opl3_flushmode and
         ((sdl_opl3_emulator = 0) or (play_status = isStopped)) then
        begin
          opl3_channel_recording_mode := TRUE;
          track_notes := FALSE;
          If shift_pressed then sdl_opl3_emulator := 0;
        end;
      If NOT shift_pressed then sdl_opl3_emulator := 1
      else FADE_IN_RECORDING;
      keyboard_reset_buffer;
    end;

  If scankey(SC_F12) and
     ((alt_pressed and NOT ctrl_pressed) or
      (ctrl_pressed and NOT alt_pressed)) then
    begin
      If NOT shift_pressed then
        begin
          flush_WAV_data;
          sdl_opl3_emulator := 0;
          opl3_channel_recording_mode := FALSE;
        end
      else FADE_OUT_RECORDING;
      keyboard_reset_buffer;
    end;

{$ENDIF}

  If track_notes and scankey(SC_BACKSPACE) then
    begin
      If NOT ctrl_pressed then
        begin
          start_row := pattern_page;
          end_row := pattern_page;
        end
      else begin
             start_row := 0;
             end_row := songdata.patt_len;
           end;
      For temp2 := start_row to end_row do
        For temp := 1 to nm_track_chan do
          If channel_flag[track_chan_start+temp-1] then
            begin
              chunk := pattdata^[pattern_patt DIV 8][pattern_patt MOD 8]
                                [track_chan_start+temp-1][temp2];
              chunk.note := 0;
              chunk.instr_def := 0;
              pattdata^[pattern_patt DIV 8][pattern_patt MOD 8]
                       [track_chan_start+temp-1][temp2] := chunk;
            end;
    end;
end;

procedure PROGRAM_SCREEN_init;

var
  temp: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT2.PAS:PROGRAM_SCREEN_init';
{$ENDIF}
  fr_setting.shadow_enabled := FALSE;
  Frame(screen_ptr,01,MAX_PATTERN_ROWS+12,MAX_COLUMNS,MAX_PATTERN_ROWS+22,
        main_background+main_border,'',
        main_background+main_title,
        frame_double);
  Frame(screen_ptr,01,01,MAX_COLUMNS,MAX_PATTERN_ROWS+12,
        main_background+main_border,'- '+_ADT2_TITLE_STRING_+' -',
        main_background+main_border,
        frame_single);
  Frame(screen_ptr,02,02,24,07,
        status_background+status_border,' STATUS ',
        status_background+status_border,
        frame_double);
  Frame(screen_ptr,25,02,25+MAX_ORDER_COLS*7-1+PATTORD_xshift*2,07,
        order_background+order_border,' PATTERN ORDER (  ) ',
        order_background+order_border,
        frame_double);

  fr_setting.shadow_enabled := TRUE;
  area_x1 := 0;
  area_y1 := 0;
  area_x2 := 0;
  area_y2 := 0;

  ShowVStr(screen_ptr,02,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),
           analyzer_bckg+analyzer);
  ShowVStr(screen_ptr,03,MAX_PATTERN_ROWS+13,'MAX   MiN',
           analyzer_bckg+analyzer);

  For temp := 05 to MAX_COLUMNS-6 do
    ShowVStr(screen_ptr,temp,MAX_PATTERN_ROWS+13,
             #242#224#224#224#224#224#224#224#243,
             analyzer_bckg+analyzer);

  ShowVStr(screen_ptr,04,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),
           analyzer_bckg+analyzer);
  ShowVStr(screen_ptr,MAX_COLUMNS-5,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),
           analyzer_bckg+analyzer);
  ShowVStr(screen_ptr,MAX_COLUMNS-4,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),
           analyzer_bckg+analyzer);
  ShowVStr(screen_ptr,MAX_COLUMNS-3,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),
           analyzer_bckg+analyzer);
  ShowVStr(screen_ptr,MAX_COLUMNS-2,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),
           analyzer_bckg+analyzer);
  ShowVStr(screen_ptr,MAX_COLUMNS-1,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),
           analyzer_bckg+analyzer);

  ShowStr(screen_ptr,MAX_COLUMNS-4,MAX_PATTERN_ROWS+13,'dB',
          analyzer_bckg+analyzer);
  ShowStr(screen_ptr,MAX_COLUMNS-4,MAX_PATTERN_ROWS+14,#224'47',
          analyzer_bckg+analyzer);
  ShowStr(screen_ptr,MAX_COLUMNS-4,MAX_PATTERN_ROWS+15,#224,
          analyzer_bckg+analyzer);
  ShowStr(screen_ptr,MAX_COLUMNS-4,MAX_PATTERN_ROWS+16,#224'23',
          analyzer_bckg+analyzer);
  ShowStr(screen_ptr,MAX_COLUMNS-4,MAX_PATTERN_ROWS+17,#224,
          analyzer_bckg+analyzer);
  ShowStr(screen_ptr,MAX_COLUMNS-4,MAX_PATTERN_ROWS+18,#224'12',
          analyzer_bckg+analyzer);
  ShowStr(screen_ptr,MAX_COLUMNS-4,MAX_PATTERN_ROWS+19,#224'4',
          analyzer_bckg+analyzer);
  ShowStr(screen_ptr,MAX_COLUMNS-4,MAX_PATTERN_ROWS+20,#224'2',
          analyzer_bckg+analyzer);

  ShowCStr(screen_ptr,03,03,'~ORDER/PATTERN ~  /',
           status_background+status_dynamic_txt,
           status_background+status_static_txt);
  ShowCStr(screen_ptr,03,04,'~ROW           ~',
           status_background+status_dynamic_txt,
           status_background+status_static_txt);
  ShowCStr(screen_ptr,03,05,'~SPEED/TEMPO   ~  /',
           status_background+status_dynamic_txt,
           status_background+status_static_txt);

  ShowStr(screen_ptr,02,08,patt_win[1],
          pattern_bckg+pattern_border);
  ShowStr(screen_ptr,02,09,patt_win[2],
          pattern_bckg+pattern_border);
  ShowStr(screen_ptr,02,10,patt_win[3],
          pattern_bckg+pattern_border);

  For temp := 11 to 11+MAX_PATTERN_ROWS-1 do
    ShowStr(screen_ptr,02,temp,patt_win[4],
            pattern_bckg+pattern_border);

  ShowStr(screen_ptr,02,11+MAX_PATTERN_ROWS,patt_win[5],
          pattern_bckg+pattern_border);
end;

procedure process_config_file;

var
  data: String;

function check_number(str: String; base: Byte; limit1,limit2: Longint; default: Longint): Longint;

var
  idx,temp: Byte;
  temp2: Longint;
  result: Longint;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT2.PAS:check_number';
{$ENDIF}
  result := default;

  temp2 := 1000000000;
  For idx := 10 downto 1 do
    begin
      If (limit2 >= temp2) then
        begin
          temp := idx;
          BREAK;
        end;
      temp2 := temp2 DIV 10;
    end;

  If SameName(str+'='+ExpStrL('',temp,'?'),data) and (Length(data) < Length(str)+temp+2) then
    begin
      result := Str2num(Copy(data,Length(str)+2,temp),base);
      If (result >= limit1) and (result <= limit2) then
      else result := default;
    end;

  check_number := result;
end;

function validate_number(var num: Longint; str: String; base: Byte; limit1,limit2: Longint): Boolean;

var
  idx,temp: Byte;
  temp2: Longint;
  result: Boolean;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT2.PAS:validate_number';
{$ENDIF}
  result := FALSE;

  temp2 := 1000000000;
  For idx := 10 downto 1 do
    begin
      If (limit2 >= temp2) then
        begin
          temp := idx;
          BREAK;
        end;
      temp2 := temp2 DIV 10;
    end;

  If SameName(str+'='+ExpStrL('',temp,'?'),data) and (Length(data) < Length(str)+temp+2) then
    begin
      num := Str2num(Copy(data,Length(str)+2,temp),base);
      If (num >= limit1) and (num <= limit2) then
        result := TRUE;
    end
  else
    result := TRUE;

  validate_number := result;
end;

type
  tRANGE = Set of 1..255;

function check_range(str: String; base: Byte; range: tRANGE; default: Byte): Byte;

var
  result: Word;

begin
  result := default;
  If SameName(str+'='+ExpStrL('',3,'?'),data) and
     (Length(data) < Length(str)+5) then
    If (Str2num(Copy(data,Length(str)+2,3),base) in range) then
      result := Str2num(Copy(data,Length(str)+2,3),base);
  check_range := result;
end;

function check_boolean(str: String; default: Boolean): Boolean;

var
  result: Boolean;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT2.PAS:process_config_file:check_boolean';
{$ENDIF}
  result := default;
  If SameName(str+'=???',data) and
     (Length(data) < Length(str)+5) then
    begin
      If (Copy(data,Length(str)+2,3) = 'on')  then result := TRUE;
      If (Copy(data,Length(str)+2,3) = 'off') then result := FALSE;
    end;
  check_boolean := result;
end;

procedure check_rgb(str: String; var default: tRGB);

var
  result: tRGB;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT2.PAS:process_config_file:check_rgb';
{$ENDIF}
  If SameName(str+'=??,??,??',data) and
     (Length(data) < Length(str)+10) then
    begin
      result.r := Str2num(Copy(data,Length(str)+2,2),10);
      result.g := Str2num(Copy(data,Length(str)+5,2),10);
      result.b := Str2num(Copy(data,Length(str)+8,2),10);
      If (result.r <= 63) and (result.g <= 63) and (result.b <= 63) then
        begin
          default := result;
{$IFNDEF GO32V2}
          default.r := default.r SHL 2;
          default.g := default.g SHL 2;
          default.b := default.b SHL 2;
{$ENDIF}
        end;
    end;
end;

procedure check_option_data;

var
  temp: Byte;
{$IFNDEF GO32V2}
  temp_str: String;
{$ENDIF}

begin

{$IFDEF GO32V2}

  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT2.PAS:check_option_data';

  opl3port :=
    check_number('adlib_port',16,1,$0ffff,opl3port);

  typematic_rate :=
    check_number('typematic_rate',10,0,31,typematic_rate);

  typematic_delay:=
    check_number('typematic_delay',10,0,3,typematic_delay);

  mouse_hspeed :=
    check_number('mouse_hspeed',10,0,65535,mouse_hspeed);

  mouse_vspeed :=
    check_number('mouse_vspeed',10,0,65535,mouse_vspeed);

  mouse_threshold :=
    check_number('mouse_threshold',10,0,65535,mouse_threshold);

  screen_mode :=
    check_number('screen_mode',10,0,5,screen_mode);

  comp_text_mode :=
    check_number('comp_text_mode',10,0,4,comp_text_mode);

  opl_latency :=
    check_number('opl_latency',10,0,1,opl_latency);

  fps_down_factor :=
    check_number('fps_down_factor',10,0,10,fps_down_factor);

  mouse_disabled :=
    check_boolean('mouse_disabled',mouse_disabled);

  // validate custom SVGA text-mode configuration

  custom_svga_mode :=
    check_boolean('custom_svga_mode',custom_svga_mode);

  _custom_svga_cfg[1].flag :=
    validate_number(_custom_svga_cfg[1].value,'svga_txt_columns',10,80,180);

  _custom_svga_cfg[2].flag :=
    validate_number(_custom_svga_cfg[2].value,'svga_txt_rows',10,25,60);

  _custom_svga_cfg[3].flag :=
    validate_number(_custom_svga_cfg[3].value,'crtc_misc_out',16,0,255);

  _custom_svga_cfg[4].flag :=
    validate_number(_custom_svga_cfg[4].value,'crtc_h_total',16,0,255);

  _custom_svga_cfg[5].flag :=
    validate_number(_custom_svga_cfg[5].value,'crtc_h_disp_en_end',16,0,255);

  _custom_svga_cfg[6].flag :=
    validate_number(_custom_svga_cfg[6].value,'crtc_h_blank_start',16,0,255);

  _custom_svga_cfg[7].flag :=
    validate_number(_custom_svga_cfg[7].value,'crtc_h_blank_end',16,0,255);

  _custom_svga_cfg[8].flag :=
    validate_number(_custom_svga_cfg[8].value,'crtc_h_ret_start',16,0,255);

  _custom_svga_cfg[9].flag :=
    validate_number(_custom_svga_cfg[9].value,'crtc_h_ret_end',16,0,255);

  _custom_svga_cfg[10].flag :=
    validate_number(_custom_svga_cfg[10].value,'crtc_v_total',16,0,255);

  _custom_svga_cfg[11].flag :=
    validate_number(_custom_svga_cfg[11].value,'crtc_overflow_reg',16,0,255);

  _custom_svga_cfg[12].flag :=
    validate_number(_custom_svga_cfg[12].value,'crtc_preset_r_scan',16,0,255);

  _custom_svga_cfg[13].flag :=
    validate_number(_custom_svga_cfg[13].value,'crtc_max_scan_h',16,0,255);

  _custom_svga_cfg[14].flag :=
    validate_number(_custom_svga_cfg[14].value,'crtc_v_ret_start',16,0,255);

  _custom_svga_cfg[15].flag :=
    validate_number(_custom_svga_cfg[15].value,'crtc_v_ret_end',16,0,255);

  _custom_svga_cfg[16].flag :=
    validate_number(_custom_svga_cfg[16].value,'crtc_v_disp_en_end',16,0,255);

  _custom_svga_cfg[17].flag :=
    validate_number(_custom_svga_cfg[17].value,'crtc_offs_width',16,0,255);

  _custom_svga_cfg[18].flag :=
    validate_number(_custom_svga_cfg[18].value,'crtc_underline_loc',16,0,255);

  _custom_svga_cfg[19].flag :=
    validate_number(_custom_svga_cfg[19].value,'crtc_v_blank_start',16,0,255);

  _custom_svga_cfg[20].flag :=
    validate_number(_custom_svga_cfg[20].value,'crtc_v_blank_end',16,0,255);

  _custom_svga_cfg[21].flag :=
    validate_number(_custom_svga_cfg[21].value,'crtc_mode_ctrl',16,0,255);

  _custom_svga_cfg[22].flag :=
    validate_number(_custom_svga_cfg[22].value,'crtc_clock_m_reg',16,0,255);

  _custom_svga_cfg[23].flag :=
    validate_number(_custom_svga_cfg[23].value,'crtc_char_gen_sel',16,0,255);

  _custom_svga_cfg[24].flag :=
    validate_number(_custom_svga_cfg[24].value,'crtc_memory_m_reg',16,0,255);

  _custom_svga_cfg[25].flag :=
    validate_number(_custom_svga_cfg[25].value,'crtc_mode_reg',16,0,255);

  _custom_svga_cfg[26].flag :=
    validate_number(_custom_svga_cfg[26].value,'crtc_misc_reg',16,0,255);

  _custom_svga_cfg[27].flag :=
    validate_number(_custom_svga_cfg[27].value,'crtc_mode_control',16,0,255);

  _custom_svga_cfg[28].flag :=
    validate_number(_custom_svga_cfg[28].value,'crtc_screen_b_clr',16,0,255);

  _custom_svga_cfg[29].flag :=
    validate_number(_custom_svga_cfg[29].value,'crtc_colr_plane_en',16,0,255);

  _custom_svga_cfg[30].flag :=
    validate_number(_custom_svga_cfg[30].value,'crtc_h_panning',16,0,255);

  _custom_svga_cfg[31].flag :=
    validate_number(_custom_svga_cfg[31].value,'crtc_color_select',16,0,255);

{$ELSE}

  sdl_screen_mode :=
    check_number('sdl_screen_mode',10,0,2,sdl_screen_mode);

  sdl_frame_rate :=
    check_number('sdl_frame_rate',10,50,200,sdl_frame_rate);

  sdl_timer_slowdown :=
    check_number('sdl_timer_slowdown',10,0,50,sdl_timer_slowdown);

  sdl_typematic_rate :=
    check_number('sdl_typematic_rate',10,1,100,sdl_typematic_rate);

  sdl_typematic_delay :=
    check_number('sdl_typematic_delay',10,0,2000,sdl_typematic_delay);

  If (Copy(data,1,18) = 'sdl_wav_directory=') and
     (Length(data) > 18) then
    begin
      temp_str := Copy(data,19,Length(data)-18);
      If (temp_str[1] = PATHSEP) then Delete(temp_str,1,1);
      If (temp_str <> '') then
        begin
          If (Length(temp_str) > 4) then
            If NOT (Lower(Copy(temp_str,Length(temp_str)-3,4)) = '.wav') then
                               temp_str := temp_str+PATHSEP
            else opl3_flushmode := TRUE
           else If (temp_str[Length(temp_str)] <> PATHSEP) then
                  temp_str := temp_str+PATHSEP;
         end;
      sdl_wav_directory := temp_str;
      If NOT (Pos(':',sdl_wav_directory) <> 0) then
        sdl_wav_directory := PathOnly(ParamStr(0))+PATHSEP+sdl_wav_directory;
    end;

{$ENDIF}

  init_tempo :=
    check_number('init_tempo',10,1,255,Round(init_tempo));

  init_speed :=
    check_number('init_speed',16,1,255,init_speed);

  init_macro_speedup :=
    check_number('init_macro_speedup',10,1,calc_max_speedup(init_tempo),init_macro_speedup);

  midiboard :=
    check_boolean('midiboard',midiboard);

  default_octave :=
    check_number('octave',10,1,8,default_octave);

  patt_len :=
    check_number('patt_len',10,1,255,patt_len);

  nm_tracks :=
    check_number('nm_tracks',10,1,20,nm_tracks);

  mod_description :=
    check_boolean('mod_description',mod_description);

  highlight_controls :=
    check_boolean('highlight_controls',highlight_controls);

  use_H_for_B :=
    check_boolean('use_h_for_b',use_H_for_B);

  linefeed :=
    check_boolean('linefeed',linefeed);

  update_ins :=
    check_boolean('update_ins',update_ins);

  adjust_tracks :=
    check_boolean('adjust_tracks',adjust_tracks);

  cycle_pattern :=
    check_boolean('cycle_pattern',cycle_pattern);

  keep_track_pos :=
    check_boolean('keep_track_pos',keep_track_pos);

  remember_ins_pos :=
    check_boolean('remember_ins_pos',remember_ins_pos);

  backspace_dir :=
    check_number('backspace_dir',10,1,2,backspace_dir);

  scroll_bars :=
    check_boolean('scroll_bars',scroll_bars);

  fforward_factor :=
    check_number('fforward_factor',10,1,5,fforward_factor);

  rewind_factor :=
    check_number('rewind_factor',10,1,5,rewind_factor);

  ssaver_time :=
    check_number('ssaver_time',10,0,1440,ssaver_time DIV 60)*60;

  timer_fix :=
    check_boolean('18hz_fix',timer_fix);

  decay_bar_rise :=
    check_number('decay_bar_rise',10,1,10,Round(decay_bar_rise));

  If (check_number('decay_bar_fall',10,1,10,0) <> 0) then
    decay_bar_fall := check_number('decay_bar_fall',10,1,10,0)/10;

  force_ins :=
    check_number('force_ins',10,0,2,force_ins);

  keep_position :=
    check_boolean('keep_position',keep_position);

  alt_ins_name :=
    check_boolean('alt_ins_name',alt_ins_name);

  trace_by_default :=
    check_boolean('trace_by_default',trace_by_default);

  nosync_by_default :=
    check_boolean('nosync_by_default',nosync_by_default);

  pattern_layout :=
    check_number('pattern_layout',10,0,2,pattern_layout);

  command_typing :=
    check_number('command_typing',10,0,2,command_typing);

  mark_lines :=
    check_boolean('mark_lines',mark_lines);

  fix_c_note_bug :=
    check_boolean('fix_c_note_bug',fix_c_note_bug);

  accurate_conv :=
    check_boolean('accurate_conv',accurate_conv);

  pattern_bckg :=
    check_number('pattern_bckg',10,0,15,pattern_bckg SHR 4) SHL 4;

  pattern_border :=
    check_number('pattern_border',10,0,15,pattern_border);

  pattern_pos_indic :=
    check_number('pattern_pos_indic',10,0,15,pattern_pos_indic);

  pattern_pan_indic :=
    check_number('pattern_pan_indic',10,0,15,pattern_pan_indic);

  pattern_gpan_indic :=
    check_number('pattern_gpan_indic',10,0,15,pattern_gpan_indic);

  pattern_lock_indic :=
    check_number('pattern_lock_indic',10,0,15,pattern_lock_indic);

  pattern_perc_indic :=
    check_number('pattern_perc_indic',10,0,15,pattern_perc_indic);

  pattern_4op_indic :=
    check_number('pattern_4op_indic',10,0,15,pattern_4op_indic);

  pattern_chan_indic :=
    check_number('pattern_chan_indic',10,0,15,pattern_chan_indic);

  pattern_row_bckg :=
    check_number('pattern_row_bckg',10,0,15,pattern_row_bckg SHR 4) SHL 4;

  pattern_row_bckg_p :=
    check_number('pattern_row_bckg_p',10,0,15,pattern_row_bckg_p SHR 4) SHL 4;

  pattern_row_bckg_m :=
    check_number('pattern_row_bckg_m',10,0,15,pattern_row_bckg_m SHR 4) SHL 4;

  pattern_block_bckg :=
    check_number('pattern_block_bckg',10,0,15,pattern_block_bckg SHR 4) SHL 4;

  pattern_line :=
    check_number('pattern_line#',10,0,15,pattern_line);

  pattern_line_p :=
    check_number('pattern_line#_p',10,0,15,pattern_line_p);

  pattern_line_m :=
    check_number('pattern_line#_m',10,0,15,pattern_line_m);

  pattern_hi_line :=
    check_number('pattern_hi_line#',10,0,15,pattern_hi_line);

  pattern_hi_line_m :=
    check_number('pattern_hi_line#_m',10,0,15,pattern_hi_line_m);

  pattern_note :=
    check_number('pattern_note',10,0,15,pattern_note);

  pattern_hi_note :=
    check_number('pattern_hi_note',10,0,15,pattern_hi_note);

  pattern_note0 :=
    check_number('pattern_note0',10,0,15,pattern_note0);

  pattern_hi_note0 :=
    check_number('pattern_hi_note0',10,0,15,pattern_hi_note0);

  pattern_note_hid :=
    check_number('pattern_note_hid',10,0,15,pattern_note_hid);

  pattern_hi_note_h :=
    check_number('pattern_hi_note_h',10,0,15,pattern_hi_note_h);

  pattern_inst :=
    check_number('pattern_ins#',10,0,15,pattern_inst);

  pattern_hi_inst :=
    check_number('pattern_hi_ins#',10,0,15,pattern_hi_inst);

  pattern_inst0 :=
    check_number('pattern_ins#0',10,0,15,pattern_inst0);

  pattern_hi_inst0 :=
    check_number('pattern_hi_ins#0',10,0,15,pattern_hi_inst0);

  pattern_cmnd :=
    check_number('pattern_cmnd',10,0,15,pattern_cmnd);

  pattern_hi_cmnd :=
    check_number('pattern_hi_cmnd',10,0,15,pattern_hi_cmnd);

  pattern_cmnd0 :=
    check_number('pattern_cmnd0',10,0,15,pattern_cmnd0);

  pattern_hi_cmnd0 :=
    check_number('pattern_hi_cmnd0',10,0,15,pattern_hi_cmnd0);

  pattern_note_m :=
    check_number('pattern_note_m',10,0,15,pattern_note_m);

  pattern_note0_m :=
    check_number('pattern_note0_m',10,0,15,pattern_note0_m);

  pattern_note_hid_m :=
    check_number('pattern_note_hid_m',10,0,15,pattern_note_hid_m);

  pattern_inst_m :=
    check_number('pattern_ins#_m',10,0,15,pattern_inst_m);

  pattern_inst0_m :=
    check_number('pattern_ins#0_m',10,0,15,pattern_inst0_m);

  pattern_cmnd_m :=
    check_number('pattern_cmnd_m',10,0,15,pattern_cmnd_m);

  pattern_cmnd0_m :=
    check_number('pattern_cmnd0_m',10,0,15,pattern_cmnd0_m);

  pattern_note_b :=
    check_number('pattern_note_b',10,0,15,pattern_note_b);

  pattern_note0_b :=
    check_number('pattern_note0_b',10,0,15,pattern_note0_b);

  pattern_note_hid_b :=
    check_number('pattern_note_hid_b',10,0,15,pattern_note_hid_b);

  pattern_inst_b :=
    check_number('pattern_ins#_b',10,0,15,pattern_inst_b);

  pattern_inst0_b :=
    check_number('pattern_ins#0_b',10,0,15,pattern_inst0_b);

  pattern_cmnd_b :=
    check_number('pattern_cmnd_b',10,0,15,pattern_cmnd_b);

  pattern_cmnd0_b :=
    check_number('pattern_cmnd0_b',10,0,15,pattern_cmnd0_b);

  pattern_cmnd_ctrl :=
    check_number('pattern_cmnd_ctrl',10,0,15,pattern_cmnd_ctrl);

  pattern_fix_note :=
    check_number('pattern_fix_note',10,0,15,pattern_fix_note);

  pattern_hi_fx_note :=
    check_number('pattern_hi_fx_note',10,0,15,pattern_hi_fx_note);

  pattern_fix_note_m :=
    check_number('pattern_fix_note_m',10,0,15,pattern_fix_note_m);

  pattern_fix_note_b :=
    check_number('pattern_fix_note_b',10,0,15,pattern_fix_note_b);

  pattern_input_bckg :=
    check_number('pattern_input_bckg',10,0,15,pattern_input_bckg SHR 4) SHL 4;

  pattern_input :=
    check_number('pattern_input',10,0,15,pattern_input);

  pattern_input_warn :=
    check_number('pattern_input_warn',10,0,15,pattern_input_warn SHR 4) SHL 4;

  analyzer_bckg :=
    check_number('analyzer_bckg',10,0,15,analyzer_bckg SHR 4) SHL 4;

  analyzer :=
    check_number('analyzer',10,0,15,analyzer);

  analyzer_ovrllvol :=
    check_number('analyzer_overallvol',10,0,15,analyzer_ovrllvol);

  analyzer_volumelvl :=
    check_number('analyzer_volumelvl',10,0,15,analyzer_volumelvl);

  analyzer_carrier :=
    check_number('analyzer_carrier',10,0,15,analyzer_carrier);

  analyzer_modulator :=
    check_number('analyzer_modulator',10,0,15,analyzer_modulator);

  debug_info_bckg :=
    check_number('debug_info_bckg',10,0,15,debug_info_bckg SHR 4) SHL 4;

  debug_info_bckg2 :=
    check_number('debug_info_bckg2',10,0,15,debug_info_bckg2 SHR 4) SHL 4;

  debug_info_border :=
    check_number('debug_info_border',10,0,15,debug_info_border);

  debug_info_title :=
    check_number('debug_info_title',10,0,15,debug_info_title);

  debug_info_border2 :=
    check_number('debug_info_border2',10,0,15,debug_info_border2);

  debug_info_topic :=
    check_number('debug_info_topic',10,0,15,debug_info_topic);

  debug_info_txt :=
    check_number('debug_info_txt',10,0,15,debug_info_txt);

  debug_info_hi_txt :=
    check_number('debug_info_hi_txt',10,0,15,debug_info_hi_txt);

  debug_info_txt_hid :=
    check_number('debug_info_txt_hid',10,0,15,debug_info_txt_hid);

  debug_info_mod :=
    check_number('debug_info_mod',10,0,15,debug_info_mod);

  debug_info_hi_mod :=
    check_number('debug_info_hi_mod',10,0,15,debug_info_hi_mod);

  debug_info_car :=
    check_number('debug_info_car',10,0,15,debug_info_car);

  debug_info_hi_car :=
    check_number('debug_info_hi_car',10,0,15,debug_info_hi_car);

  debug_info_4op :=
    check_number('debug_info_4op',10,0,15,debug_info_4op);

  debug_info_perc :=
    check_number('debug_info_perc',10,0,15,debug_info_perc);

  help_background :=
    check_number('help_background',10,0,15,help_background SHR 4) SHL 4;

  help_title :=
    check_number('help_title',10,0,15,help_title);

  help_border :=
    check_number('help_border',10,0,15,help_border);

  help_topic :=
    check_number('help_topic',10,0,15,help_topic);

  help_text :=
    check_number('help_text',10,0,15,help_text);

  help_hi_text :=
    check_number('help_hi_text',10,0,15,help_hi_text);

  help_indicators :=
    check_number('help_indicators',10,0,15,help_indicators);

  help_keys :=
    check_number('help_keys',10,0,15,help_keys);

  dialog_background :=
    check_number('dialog_background',10,0,15,dialog_background SHR 4) SHL 4;

  dialog_title :=
    check_number('dialog_title',10,0,15,dialog_title);

  dialog_border :=
    check_number('dialog_border',10,0,15,dialog_border);

  dialog_text :=
    check_number('dialog_text',10,0,15,dialog_text);

  dialog_hi_text :=
    check_number('dialog_hi_text',10,0,15,dialog_hi_text);

  dialog_hid :=
    check_number('dialog_hid',10,0,15,dialog_hid);

  dialog_item :=
    check_number('dialog_item',10,0,15,dialog_item);

  dialog_sel_itm_bck :=
    check_number('dialog_sel_itm_bckg',10,0,15,dialog_sel_itm_bck SHR 4) SHL 4;

  dialog_sel_itm :=
    check_number('dialog_sel_itm',10,0,15,dialog_sel_itm);

  dialog_short :=
    check_number('dialog_short',10,0,15,dialog_short);

  dialog_sel_short :=
    check_number('dialog_sel_short',10,0,15,dialog_sel_short);

  dialog_item_dis :=
    check_number('dialog_item_dis',10,0,15,dialog_item_dis);

  dialog_context :=
    check_number('dialog_context',10,0,15,dialog_context);

  dialog_context_dis :=
    check_number('dialog_context_dis',10,0,15,dialog_context_dis);

  dialog_contxt_dis2 :=
    check_number('dialog_context_dis2',10,0,15,dialog_contxt_dis2);

  dialog_input_bckg :=
    check_number('dialog_input_bckg',10,0,15,dialog_input_bckg SHR 4) SHL 4;

  dialog_input :=
    check_number('dialog_input',10,0,15,dialog_input);

  dialog_def_bckg :=
    check_number('dialog_def_bckg',10,0,15,dialog_def_bckg SHR 4) SHL 4;

  dialog_def :=
    check_number('dialog_def',10,0,15,dialog_def);

  dialog_prog_bar1 :=
    check_number('dialog_prog_bar1',10,0,15,dialog_prog_bar1);

  dialog_prog_bar2 :=
    check_number('dialog_prog_bar2',10,0,15,dialog_prog_bar2);

  dialog_topic :=
    check_number('dialog_topic',10,0,15,dialog_topic);

  dialog_hi_topic :=
    check_number('dialog_hi_topic',10,0,15,dialog_hi_topic);

  dialog_mod_text :=
    check_number('dialog_mod_text',10,0,15,dialog_mod_text);

  dialog_car_text :=
    check_number('dialog_car_text',10,0,15,dialog_car_text);

  macro_background :=
    check_number('macro_background',10,0,15,macro_background SHR 4) SHL 4;

  macro_title :=
    check_number('macro_title',10,0,15,macro_title);

  macro_border :=
    check_number('macro_border',10,0,15,macro_border);

  macro_topic :=
    check_number('macro_topic',10,0,15,macro_topic);

  macro_topic2 :=
    check_number('macro_topic2',10,0,15,macro_topic2);

  macro_hi_topic :=
    check_number('macro_hi_topic',10,0,15,macro_hi_topic);

  macro_text :=
    check_number('macro_text',10,0,15,macro_text);

  macro_hi_text :=
    check_number('macro_hi_text',10,0,15,macro_hi_text);

  macro_text_dis :=
    check_number('macro_text_dis',10,0,15,macro_text_dis);

  macro_text_loop :=
    check_number('macro_text_loop',10,0,15,macro_text_loop);

  macro_text_keyoff :=
    check_number('macro_text_keyoff',10,0,15,macro_text_keyoff);

  macro_current_bckg :=
    check_number('macro_current_bckg',10,0,15,macro_current_bckg SHR 4) SHL 4;

  macro_current :=
    check_number('macro_current',10,0,15,macro_current);

  macro_current_dis :=
    check_number('macro_current_dis',10,0,15,macro_current_dis);

  macro_current_loop :=
    check_number('macro_current_loop',10,0,15,macro_current_loop);

  macro_current_koff :=
    check_number('macro_current_koff',10,0,15,macro_current_koff);

  macro_input_bckg :=
    check_number('macro_input_bckg',10,0,15,macro_input_bckg SHR 4) SHL 4;

  macro_input :=
    check_number('macro_input',10,0,15,macro_input);

  macro_def_bckg :=
    check_number('macro_def_bckg',10,0,15,macro_def_bckg SHR 4) SHL 4;

  macro_def :=
    check_number('macro_def',10,0,15,macro_def);

  macro_scrbar_bckg :=
    check_number('macro_scrbar_bckg',10,0,15,macro_scrbar_bckg SHR 4) SHL 4;

  macro_scrbar_text :=
    check_number('macro_scrbar_text',10,0,15,macro_scrbar_text);

  macro_scrbar_mark :=
    check_number('macro_scrbar_mark',10,0,15,macro_scrbar_mark);

  macro_hint :=
    check_number('macro_hint',10,0,15,macro_hint);

  macro_item :=
    check_number('macro_item',10,0,15,macro_item);

  macro_sel_itm_bck :=
    check_number('macro_sel_itm_bckg',10,0,15,macro_sel_itm_bck SHR 4) SHL 4;

  macro_sel_itm :=
    check_number('macro_sel_itm',10,0,15,macro_sel_itm);

  macro_short :=
    check_number('macro_short',10,0,15,macro_short);

  macro_sel_short :=
    check_number('macro_sel_short',10,0,15,macro_sel_short);

  macro_item_dis :=
    check_number('macro_item_dis',10,0,15,macro_item_dis);

  macro_context :=
    check_number('macro_context',10,0,15,macro_context);

  macro_context_dis :=
    check_number('macro_context_dis',10,0,15,macro_context_dis);

  scrollbar_bckg :=
    check_number('scrollbar_bckg',10,0,15,scrollbar_bckg SHR 4) SHL 4;

  scrollbar_text :=
    check_number('scrollbar',10,0,15,scrollbar_text);

  scrollbar_mark :=
    check_number('scrollbar_mark',10,0,15,scrollbar_mark);

  scrollbar_2nd_mark :=
    check_number('scrollbar_2nd_mark',10,0,15,scrollbar_2nd_mark);

  main_background :=
    check_number('main_background',10,0,15,main_background SHR 4) SHL 4;

  main_title :=
    check_number('main_title',10,0,15,main_title);

  main_border :=
    check_number('main_border',10,0,15,main_border);

  main_stat_line :=
    check_number('main_stat_line',10,0,15,main_stat_line);

  main_hi_stat_line :=
    check_number('main_hi_stat_line',10,0,15,main_hi_stat_line);

  main_dis_stat_line :=
    check_number('main_dis_stat_line',10,0,15,main_dis_stat_line);

  main_behavior :=
    check_number('main_behavior',10,0,15,main_behavior);

  main_behavior_dis :=
    check_number('main_behavior_dis',10,0,15,main_behavior_dis);

  status_background :=
    check_number('status_background',10,0,15,status_background SHR 4) SHL 4;

  status_border :=
    check_number('status_border',10,0,15,status_border);

  status_static_txt :=
    check_number('status_static_txt',10,0,15,status_static_txt);

  status_dynamic_txt :=
    check_number('status_dynamic_txt',10,0,15,status_dynamic_txt);

  status_play_state :=
    check_number('status_play_state',10,0,15,status_play_state);

  status_text_dis :=
    check_number('status_text_dis',10,0,15,status_text_dis);

  order_background :=
    check_number('order_background',10,0,15,order_background SHR 4) SHL 4;

  order_hi_bckg :=
    check_number('order_hi_bckg',10,0,15,order_hi_bckg SHR 4) SHL 4;

  order_border :=
    check_number('order_border',10,0,15,order_border);

  order_entry :=
    check_number('order_entry',10,0,15,order_entry);

  order_hi_entry :=
    check_number('order_hi_entry',10,0,15,order_hi_entry);

  order_pattn_jump :=
    check_number('order_patt#_jump',10,0,15,order_pattn_jump);

  order_pattn :=
    check_number('order_patt#',10,0,15,order_pattn);

  order_hi_pattn :=
    check_number('order_hi_patt#',10,0,15,order_hi_pattn);

  order_played_b :=
    check_number('order_played_b',10,0,15,order_played_b SHR 4) SHL 4;

  order_played :=
    check_number('order_played',10,0,15,order_played);

  order_input_bckg :=
    check_number('order_input_bckg',10,0,15,order_input_bckg SHR 4) SHL 4;

  order_input :=
    check_number('order_input',10,0,15,order_input);

  order_input_warn :=
    check_number('order_input_warn',10,0,15,order_input_warn SHR 4) SHL 4;

  instrument_bckg :=
    check_number('instrument_bckg',10,0,15,instrument_bckg SHR 4) SHL 4;

  instrument_title :=
    check_number('instrument_title',10,0,15,instrument_title);

  instrument_border :=
    check_number('instrument_border',10,0,15,instrument_border);

  instrument_text :=
    check_number('instrument_text',10,0,15,instrument_text);

  instrument_hi_text :=
    check_number('instrument_hi_text',10,0,15,instrument_hi_text);

  instrument_glob :=
    check_number('instrument_glob',10,0,15,instrument_glob);

  instrument_hi_glob :=
    check_number('instrument_hi_glob',10,0,15,instrument_hi_glob);

  instrument_hid :=
    check_number('instrument_hid',10,0,15,instrument_hid);

  instrument_mod :=
    check_number('instrument_mod',10,0,15,instrument_mod);

  instrument_car :=
    check_number('instrument_car',10,0,15,instrument_car);

  instrument_hi_mod :=
    check_number('instrument_hi_mod',10,0,15,instrument_hi_mod);

  instrument_hi_car :=
    check_number('instrument_hi_car',10,0,15,instrument_hi_car);

  instrument_context :=
    check_number('instrument_context',10,0,15,instrument_context);

  instrument_con_dis :=
    check_number('instrument_con_dis',10,0,15,instrument_con_dis);

  instrument_adsr :=
    check_number('instrument_adsr',10,0,15,instrument_adsr SHR 4) SHL 4;

  instrument_ai_off :=
    check_number('instrument_ai_off',10,0,15,instrument_ai_off);

  instrument_ai_on :=
    check_number('instrument_ai_on',10,0,15,instrument_ai_on);

  instrument_ai_trig :=
    check_number('instrument_ai_trig',10,0,15,instrument_ai_trig);

  If (Copy(data,1,14) = 'home_dir_path=') and
     (Length(data) > 14) then
    begin
      home_dir_path := Copy(data,15,Length(data)-14);
      If (home_dir_path <> '') and
         (home_dir_path[Length(home_dir_path)] <> PATHSEP) then
        home_dir_path := home_dir_path+PATHSEP;
    end;

  If (Copy(data,1,17) = 'a2m_default_path=') and
     (Length(data) > 17) then
    begin
      a2m_default_path := Copy(data,18,Length(data)-17);
      If (a2m_default_path <> '') and
         (a2m_default_path[Length(a2m_default_path)] <> PATHSEP) then
        a2m_default_path := a2m_default_path+PATHSEP;
    end;

  If (Copy(data,1,17) = 'a2t_default_path=') and
     (Length(data) > 17) then
    begin
      a2t_default_path := Copy(data,18,Length(data)-17);
      If (a2t_default_path <> '') and
         (a2t_default_path[Length(a2t_default_path)] <> PATHSEP) then
        a2t_default_path := a2t_default_path+PATHSEP;
    end;

  If (Copy(data,1,17) = 'a2i_default_path=') and
     (Length(data) > 17) then
    begin
      a2i_default_path := Copy(data,18,Length(data)-17);
      If (a2i_default_path <> '') and
         (a2i_default_path[Length(a2i_default_path)] <> PATHSEP) then
        a2i_default_path := a2i_default_path+PATHSEP;
    end;

  If (Copy(data,1,17) = 'a2f_default_path=') and
     (Length(data) > 17) then
    begin
      a2f_default_path := Copy(data,18,Length(data)-17);
      If (a2f_default_path <> '') and
         (a2f_default_path[Length(a2f_default_path)] <> PATHSEP) then
        a2f_default_path := a2f_default_path+PATHSEP;
    end;

  If (Copy(data,1,17) = 'a2p_default_path=') and
     (Length(data) > 17) then
    begin
      a2p_default_path := Copy(data,18,Length(data)-17);
      If (a2p_default_path <> '') and
         (a2p_default_path[Length(a2p_default_path)] <> PATHSEP) then
        a2p_default_path := a2p_default_path+PATHSEP;
    end;

  If (Copy(data,1,17) = 'a2b_default_path=') and
     (Length(data) > 17) then
    begin
      a2b_default_path := Copy(data,18,Length(data)-17);
      If (a2b_default_path <> '') and
         (a2b_default_path[Length(a2b_default_path)] <> PATHSEP) then
        a2b_default_path := a2b_default_path+PATHSEP;
    end;

  If (Copy(data,1,17) = 'a2w_default_path=') and
     (Length(data) > 17) then
    begin
      a2w_default_path := Copy(data,18,Length(data)-17);
      If (a2w_default_path <> '') and
         (a2w_default_path[Length(a2w_default_path)] <> PATHSEP) then
        a2w_default_path := a2w_default_path+PATHSEP;
    end;

  For temp := 0 to 15 do
    check_rgb('color'+ExpStrL(Num2str(temp,10),2,'0'),rgb_color[temp]);
end;

var
  txtf: Text;
  idx: Byte;
  config_found_flag: Boolean;

begin { process_config_file }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT2.PAS:process_config_file';
{$ENDIF}
  config_found_flag := FALSE;
  Write('Reading configuration file ... ');
  {$i-}
  Assign(txtf,'adtrack2.ini');
  Reset (txtf);
  {$i+}
  If (IOresult <> 0) then
    begin
      {$i-}
      Assign(txtf,PathOnly(ParamStr(0))+'adtrack2.ini');
      Reset (txtf);
      {$i+}
      If (IOresult <> 0) then WriteLn('not found!')
      else begin
             config_found_flag := TRUE;
             WriteLn('ok');
        end;
    end
  else begin
         config_found_flag := TRUE;
         WriteLn('ok');
       end;

  If config_found_flag then
    begin
      While NOT EOF(txtf) do
        begin
          {$i-}
          ReadLn(txtf,data);
          {$i+}
          If (IOresult <> 0) then
            begin
              {$i-}
              Close(txtf);
              {$i+}
              If (IOresult <> 0) then ;
              BREAK;
            end;

          If (Pos(';',data) <> 0) then
            Delete(data,Pos(';',data),Length(data)-Pos(';',data)+1);

          data := CutStr(Lower(data));
          check_option_data;
        end;

      {$i-}
      Close(txtf);
      {$i+}
      If (IOresult <> 0) then ;
    end;

  If (ParamCount <> 0) then
    For idx := 1 to ParamCount do
      begin
        data := CutStr(Lower(ParamStr(idx)));
        If (Copy(data,1,5) = '/cfg:') then
          begin
            Delete(data,1,5);
            check_option_data;
          end;
      end;
end;

end.
