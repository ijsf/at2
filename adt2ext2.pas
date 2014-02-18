{
    Unit that manages reading ini file and setting options
}
unit AdT2ext2;
{$PACKRECORDS 1}
interface

const
  _check_ADSR_preview_flag: Boolean = FALSE;
  _ADSR_preview_flag: Boolean = TRUE;
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

procedure update_without_trace;
procedure PATTERN_ORDER_page_refresh(page: Byte);
procedure PATTERN_ORDER_edit(var page,hpos,vpos: Byte);

procedure PATTERN_tabs_refresh;
procedure PATTERN_page_refresh(page: Byte);
procedure STATUS_LINE_refresh;

procedure PATTERN_position_preview(pattern,line,channel,mode: Byte);
function  PATTERN_trace: Word;
procedure PATTERN_edit(var pattern,page,hpos: Byte);

procedure process_config_file;
procedure reset_4op_to_test(_4op_type,ins2: Byte);

function  marked_instruments: Byte;
function _1st_marked: Byte;
function _2nd_marked: Byte;
function _4op_to_test: Word;

implementation

uses
  CRT,
  AdT2vid,AdT2vscr,AdT2keyb,AdT2opl3,AdT2unit,AdT2extn,AdT2text,AdT2apak,
  StringIO,DialogIO,ParserIO,TxtScrIO;

{$i instedit.inc}
{$i ipattord.inc}
{$i ipattern.inc}

procedure FADE_OUT_RECORDING;

var
  xstart,ystart: Byte;
  temp,temp2: Byte;

procedure show_progress(value: Longint);
begin
  progress_new_value := Round(progress_step*value);
  If (progress_new_value <> progress_old_value) then
    begin
      progress_old_value := progress_new_value;
      ShowCStr(v_ofs^,
               progress_xstart,progress_ystart,
               '~'+ExpStrL('',progress_new_value,'Û')+'~'+
               ExpStrL('',40-progress_new_value,'Û'),
               dialog_background+dialog_prog_bar1,
               dialog_background+dialog_prog_bar2);

      If tracing then trace_update_proc
      else If (play_status = isPlaying) then
             begin
               PATTERN_ORDER_page_refresh(pattord_page);
               PATTERN_page_refresh(pattern_page);
             end;
      _emulate_screen_without_delay := TRUE;
      emulate_screen;
    end;
end;

label _jmp1,_end;

begin
  If (play_status = isStopped) or (sdl_opl3_emulator = 0) then
    begin
      sdl_opl3_emulator := 0;
      EXIT;
    end;

  Move(v_ofs^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;
  HideCursor;

  dl_environment.context := ' ESC Ä STOP '; 
  centered_frame(xstart,ystart,43,3,' WAV RECORDER ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);
  ShowStr(v_ofs^,xstart+43-Length(dl_environment.context),ystart+3,
                 dl_environment.context,
                 dialog_background+dialog_border);
  dl_environment.context := '';

  show_progress(40); 
  ShowStr(v_ofs^,xstart+2,ystart+1,
    'FADiNG OUT WAV RECORDiNG...',
    dialog_background+dialog_text);

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;
  progress_old_value := NULL;
  progress_step := 40/63;

  For temp := 63 downto 0 do
    begin
      If scankey(1) then GOTO _jmp1;
      fade_out_volume := temp;
      set_global_volume;
      ShowStr(v_ofs^,xstart+30,ystart+1,
        Num2Str(Round(100/63*temp),10)+'%  ',
        dialog_background+dialog_hi_text);        
      If (@trace_update_proc <> NIL) then trace_update_proc
      else If (play_status = isPlaying) then
             begin
               PATTERN_ORDER_page_refresh(pattord_page);
               PATTERN_page_refresh(pattern_page);
             end;
      show_progress(temp);
      For temp2 := 1 to 20 do
        begin
          If scankey(1) then GOTO _jmp1;
          _emulate_screen_without_delay := TRUE;
          emulate_screen;
          keyboard_reset_buffer;
          Delay(fade_delay_tab[temp]);
        end;
    end;

 _jmp1:

  show_progress(0);
  ShowStr(v_ofs^,xstart+2,ystart+1,
    'FADiNG iN SONG PLAYBACK... ',
    dialog_background+dialog_text);

  sdl_opl3_emulator := 0;
  For temp := 0 to 63 do
    begin
      If scankey(1) then GOTO _end;
      fade_out_volume := temp;
      set_global_volume;
      ShowStr(v_ofs^,xstart+30,ystart+1,
        Num2Str(Round(100/63*temp),10)+'%  ',
        dialog_background+dialog_hi_text);        
      If (@trace_update_proc <> NIL) then trace_update_proc
      else If (play_status = isPlaying) then
             begin
               PATTERN_ORDER_page_refresh(pattord_page);
               PATTERN_page_refresh(pattern_page);
             end;
      show_progress(temp);
      If scankey(1) then GOTO _end;
      _emulate_screen_without_delay := TRUE;
      emulate_screen;
      keyboard_reset_buffer;
      Delay(5);
    end;

_end:

  fade_out_volume := 63;
  set_global_volume;

  move_to_screen_data := Addr(backup.screen);
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;

  move2screen;
//  SetCursor(backup.cursor);
//  GotoXY(backup.oldx,backup.oldy);
end;

procedure FADE_IN_RECORDING;

var
  xstart,ystart: Byte;
  temp,temp2: Byte;
  smooth_fadeOut: Boolean;

procedure show_progress(value: Longint);
begin
  progress_new_value := Round(progress_step*value);
  If (progress_new_value <> progress_old_value) then
    begin
      progress_old_value := progress_new_value;
      ShowCStr(v_ofs^,
               progress_xstart,progress_ystart,
               '~'+ExpStrL('',progress_new_value,'Û')+'~'+
               ExpStrL('',40-progress_new_value,'Û'),
               dialog_background+dialog_prog_bar1,
               dialog_background+dialog_prog_bar2);

      If tracing then trace_update_proc
      else If (play_status = isPlaying) then
             begin
               PATTERN_ORDER_page_refresh(pattord_page);
               PATTERN_page_refresh(pattern_page);
             end;
      _emulate_screen_without_delay := TRUE;
      emulate_screen;
    end;
end;

label _end;

begin
  If (sdl_opl3_emulator = 1) then EXIT;
  If (play_status = isStopped) then smooth_fadeOut := FALSE
  else smooth_fadeOut := TRUE;

  Move(v_ofs^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;
  HideCursor;

  dl_environment.context := ' ESC Ä STOP ';
  centered_frame(xstart,ystart,43,3,' WAV RECORDER ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);
  ShowStr(v_ofs^,xstart+43-Length(dl_environment.context),ystart+3,
                 dl_environment.context,
                 dialog_background+dialog_border);
  dl_environment.context := '';

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;
  progress_old_value := NULL;
  progress_step := 40/63;

  If smooth_fadeOut then
    begin
      show_progress(40);
      ShowStr(v_ofs^,xstart+2,ystart+1,
        'FADiNG OUT SONG PLAYBACK...',
        dialog_background+dialog_text);   
      
      For temp := 63 downto 0 do
        begin
          If scankey(1) then GOTO _end;
          fade_out_volume := temp;
          set_global_volume;
          ShowStr(v_ofs^,xstart+30,ystart+1,
            Num2Str(Round(100/63*temp),10)+'%  ',
            dialog_background+dialog_hi_text);        
          If (@trace_update_proc <> NIL) then trace_update_proc
          else If (play_status = isPlaying) then
                 begin
                   PATTERN_ORDER_page_refresh(pattord_page);
                   PATTERN_page_refresh(pattern_page);
                 end;
          show_progress(temp);
          _emulate_screen_without_delay := TRUE;
          emulate_screen;
          keyboard_reset_buffer;
          Delay(5);
          If scankey(1) then GOTO _end;
        end;
    end;

  show_progress(0); 
  ShowStr(v_ofs^,xstart+2,ystart+1,
    'FADiNG iN WAV RECORDiNG... ',
    dialog_background+dialog_text);   
    
  Case play_status of
    isStopped: begin
                 If trace_by_default then
                   begin
                     tracing := TRUE;
                     trace_update_proc := update_trace;
                   end;
                 start_playing;
               end;
    isPaused:  begin
                 replay_forbidden := FALSE;
                 play_status := isPlaying;
               end;
  end;

  If NOT smooth_fadeOut then fade_out_playback(FALSE);
  sdl_opl3_emulator := 1;

  For temp := 0 to 63 do
    begin
      If scankey(1) then GOTO _end;
      fade_out_volume := temp;
      set_global_volume;
      ShowStr(v_ofs^,xstart+30,ystart+1,
        Num2Str(Round(100/63*temp),10)+'%  ',
        dialog_background+dialog_hi_text);        
      If (@trace_update_proc <> NIL) then trace_update_proc
      else If (play_status = isPlaying) then
             begin
               PATTERN_ORDER_page_refresh(pattord_page);
               PATTERN_page_refresh(pattern_page);
             end;
      show_progress(temp);
      For temp2 := 1 to 20 do
        begin
          If scankey(1) then GOTO _end;
          _emulate_screen_without_delay := TRUE;
          emulate_screen;
          keyboard_reset_buffer;
          Delay(fade_delay_tab[temp]);
        end;
    end;

_end:

  fade_out_volume := 63;
  set_global_volume;
  
  move_to_screen_data := Addr(backup.screen);
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;

  move2screen;
//  SetCursor(backup.cursor);
//  GotoXY(backup.oldx,backup.oldy);
end;

procedure process_global_keys;

var
  temp,
  old_octave: Byte;

begin
  old_octave := current_octave;
  If (scankey(SC_LCTRL) or scankey(SC_RCTRL)) then
    If scankey(SC_1) then current_octave := 1
    else If scankey(SC_2) then current_octave := 2
         else If scankey(SC_3) then current_octave := 3
              else If scankey(SC_4) then current_octave := 4
                   else If scankey(SC_5) then current_octave := 5
                        else If scankey(SC_6) then current_octave := 6
                             else If scankey(SC_7) then current_octave := 7
                                  else If scankey(SC_8) then current_octave := 8;

  If (current_octave <> old_octave) then
    begin
      For temp := 1 to 8 do
        If (temp <> current_octave) then
          show_str(30+temp,MAX_PATTERN_ROWS+12,CHR(48+temp),
               main_background+main_stat_line)
        else show_str(30+temp,MAX_PATTERN_ROWS+12,CHR(48+temp),
                  main_background+main_hi_stat_line);
    end;

  If scankey(SC_LALT) or scankey(SC_RALT) then
    If scankey(SC_PLUS) then
      begin
        If (overall_volume < 63) then
          begin
            Inc(overall_volume);
            set_global_volume;
          end;
      end
    else If scankey(SC_MINUS2) then
           begin
             If (overall_volume > 0) then
               begin
                 Dec(overall_volume);
                 set_global_volume;
               end;
           end;

    If (command_typing <> 0) then
      begin
        If scankey(SC_F11) and
           NOT ctrl_pressed and NOT alt_pressed then
          begin
            command_typing := 1;
            If NOT shift_pressed then cycle_pattern := TRUE
            else cycle_pattern := FALSE;
          end;

        If scankey(SC_F12) and
           NOT ctrl_pressed and NOT alt_pressed and NOT shift_pressed then
          begin
            command_typing := 2;
            cycle_pattern := FALSE;
          end;
      end;

  If scankey(SC_F11) and alt_pressed and
     NOT ctrl_pressed then
    If NOT shift_pressed then sdl_opl3_emulator := 1
    else FADE_IN_RECORDING;

  If scankey(SC_F12) and alt_pressed and
     NOT ctrl_pressed then
    If NOT shift_pressed then sdl_opl3_emulator := 0
    else FADE_OUT_RECORDING;

   If _check_ADSR_preview_flag then
     If ctrl_pressed and left_shift_pressed and not right_shift_pressed then
       _ADSR_preview_flag := FALSE
     else If ctrl_pressed and right_shift_pressed and not left_shift_pressed then
            _ADSR_preview_flag := TRUE;
end;

procedure PROGRAM_SCREEN_init;

var
  temp: longint;

begin
  fr_setting.shadow_enabled := FALSE;
  Frame(v_ofs^,01,MAX_PATTERN_ROWS+12,MAX_COLUMNS,MAX_PATTERN_ROWS+22,main_background+main_border,'',
                                                                      main_background+main_title,double);
  Frame(v_ofs^,01,01,MAX_COLUMNS,MAX_PATTERN_ROWS+12,main_background+main_border,'-'+ExpStrL('',20,' ')+'-',
                                                     main_background+main_border,single);
  Frame(v_ofs^,02,02,24,07,status_background+status_border,' STATUS ',
                                      status_background+status_border,double);
  Frame(v_ofs^,25,02,25+MAX_ORDER_COLS*7-1+PATTORD_xshift*2,07,order_background+order_border,' PATTERN ORDER (  ) ',
                                      order_background+order_border,double);
  fr_setting.shadow_enabled := TRUE;
  reset_critical_area;

  ShowVStr(v_ofs^,02,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),analyzer_bckg+analyzer);
  ShowVStr(v_ofs^,03,MAX_PATTERN_ROWS+13,'MAX   MiN',analyzer_bckg+analyzer);

  For temp := 05 to MAX_COLUMNS-6 do
    ShowVStr(v_ofs^,temp,MAX_PATTERN_ROWS+13,'òàààààààó',analyzer_bckg+analyzer);

  ShowVStr(v_ofs^,04,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),analyzer_bckg+analyzer);
  ShowVStr(v_ofs^,MAX_COLUMNS-5,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),analyzer_bckg+analyzer);
  ShowVStr(v_ofs^,MAX_COLUMNS-4,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),analyzer_bckg+analyzer);
  ShowVStr(v_ofs^,MAX_COLUMNS-3,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),analyzer_bckg+analyzer);
  ShowVStr(v_ofs^,MAX_COLUMNS-2,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),analyzer_bckg+analyzer);
  ShowVStr(v_ofs^,MAX_COLUMNS-1,MAX_PATTERN_ROWS+13,ExpStrL('',9,' '),analyzer_bckg+analyzer);

  ShowStr(v_ofs^,MAX_COLUMNS-4,MAX_PATTERN_ROWS+13,'dB', analyzer_bckg+analyzer);
  ShowStr(v_ofs^,MAX_COLUMNS-4,MAX_PATTERN_ROWS+14,'à47',analyzer_bckg+analyzer);
  ShowStr(v_ofs^,MAX_COLUMNS-4,MAX_PATTERN_ROWS+15,'à',  analyzer_bckg+analyzer);
  ShowStr(v_ofs^,MAX_COLUMNS-4,MAX_PATTERN_ROWS+16,'à23',analyzer_bckg+analyzer);
  ShowStr(v_ofs^,MAX_COLUMNS-4,MAX_PATTERN_ROWS+17,'à',  analyzer_bckg+analyzer);
  ShowStr(v_ofs^,MAX_COLUMNS-4,MAX_PATTERN_ROWS+18,'à12',analyzer_bckg+analyzer);
  ShowStr(v_ofs^,MAX_COLUMNS-4,MAX_PATTERN_ROWS+19,'à4', analyzer_bckg+analyzer);
  ShowStr(v_ofs^,MAX_COLUMNS-4,MAX_PATTERN_ROWS+20,'à2', analyzer_bckg+analyzer);

  ShowCStr(v_ofs^,03,03,'~ORDER/PATTERN ~  /',
           status_background+status_dynamic_txt,
           status_background+status_static_txt);
  ShowCStr(v_ofs^,03,04,'~ROW           ~',
           status_background+status_dynamic_txt,
           status_background+status_static_txt);
  ShowCStr(v_ofs^,03,05,'~SPEED/TEMPO   ~  /',
           status_background+status_dynamic_txt,
           status_background+status_static_txt);

  ShowStr(v_ofs^,02,08,patt_win[1],pattern_bckg+pattern_border);
  ShowStr(v_ofs^,02,09,patt_win[2],pattern_bckg+pattern_border);
  ShowStr(v_ofs^,02,10,patt_win[3],pattern_bckg+pattern_border);

  For temp := 11 to 11+MAX_PATTERN_ROWS-1 do
    ShowStr(v_ofs^,02,temp,patt_win[4],pattern_bckg+pattern_border);

  ShowStr(v_ofs^,02,11+MAX_PATTERN_ROWS,patt_win[5],pattern_bckg+pattern_border);
end;

procedure process_config_file;

var
  txtf: Text;
  data: String;
  temp: Byte;
  temp_str: String;

function check_number(str: String; base: Byte; limit1,limit2: Word; default: Word): Word;

var
  temp: Byte;
  result: Word;

begin
  result := default;
  If (limit2 >= 10000) then temp := 5
  else If (limit2 >= 1000) then temp := 4
       else If (limit2 >= 100) then temp := 3
            else If (limit2 >= 10) then temp := 2
                 else temp := 1;

  If SameName(str+'='+ExpStrL('',temp,'?'),data) and (Length(data) < Length(str)+temp+2) then
    begin
      result := Str2num(Copy(data,Length(str)+2,temp),base);
      If (result >= limit1) and (result <= limit2) then
      else result := default;
    end;

  check_number := result;
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
  If SameName(str+'=??,??,??',data) and
     (Length(data) < Length(str)+10) then
    begin
      result.r := Str2num(Copy(data,Length(str)+2,2),10) SHL 2;
      result.g := Str2num(Copy(data,Length(str)+5,2),10) SHL 2;
      result.b := Str2num(Copy(data,Length(str)+8,2),10) SHL 2;

      If (result.r <= 63) and (result.g <= 63) and (result.b <= 63) then
        default := result;
    end;
end;

begin { process_config_file }
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
      If (IOresult <> 0) then
        begin
          WriteLn('not found!');
          EXIT;
        end;
    end;

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
          EXIT;
        end;

      If (Pos(';',data) <> 0) then
        Delete(data,Pos(';',data),Length(data)-Pos(';',data)+1);
      data := CutStr(Lower(data));

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

      backspace_dir :=
        check_number('backspace_dir',10,1,2,backspace_dir);

      scroll_bars :=
        check_boolean('scroll_bars',scroll_bars);

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

      debug_info_border :=
        check_number('debug_info_border',10,0,15,debug_info_border);

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

      dialog_button :=
        check_number('dialog_button',10,0,15,dialog_button);

      dialog_sel_btn_bck :=
        check_number('dialog_sel_btn_bckg',10,0,15,dialog_sel_btn_bck SHR 4) SHL 4;

      dialog_sel_btn :=
        check_number('dialog_sel_btn',10,0,15,dialog_sel_btn);

      dialog_short :=
        check_number('dialog_short',10,0,15,dialog_short);

      dialog_sel_short :=
        check_number('dialog_sel_short',10,0,15,dialog_sel_short);

      dialog_button_dis :=
        check_number('dialog_button_dis',10,0,15,dialog_button_dis);

      dialog_context :=
        check_number('dialog_context',10,0,15,dialog_context);

      dialog_context_dis :=
        check_number('dialog_context_dis',10,0,15,dialog_context_dis);

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

      macro_background :=
        check_number('macro_background',10,0,15,macro_background SHR 4) SHL 4;

      macro_title :=
        check_number('macro_title',10,0,15,macro_title);

      macro_border :=
        check_number('macro_border',10,0,15,macro_border);

      macro_topic :=
        check_number('macro_topic',10,0,15,macro_topic);

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

      menu_background :=
        check_number('menu_background',10,0,15,menu_background SHR 4) SHL 4;

      menu_title :=
        check_number('menu_title',10,0,15,menu_title);

      menu_border :=
        check_number('menu_border',10,0,15,menu_border);

      menu_topic :=
        check_number('menu_topic',10,0,15,menu_topic);

      menu_hi_topic :=
        check_number('menu_hi_topic',10,0,15,menu_hi_topic);

      menu_item :=
        check_number('menu_item',10,0,15,menu_item);

      menu_sel_item_bckg :=
        check_number('menu_sel_item_bckg',10,0,15,menu_sel_item_bckg SHR 4) SHL 4;

      menu_sel_item :=
        check_number('menu_sel_item',10,0,15,menu_sel_item);

      menu_default_bckg :=
        check_number('menu_default_bckg',10,0,15,menu_default_bckg SHR 4) SHL 4;

      menu_default :=
        check_number('menu_default',10,0,15,menu_default);

      menu_short :=
        check_number('menu_short',10,0,15,menu_short);

      menu_sel_short :=
        check_number('menu_sel_short',10,0,15,menu_sel_short);

      menu_item_dis :=
        check_number('menu_item_dis',10,0,15,menu_item_dis);

      menu_context :=
        check_number('menu_context',10,0,15,menu_context);

      menu_context_dis :=
        check_number('menu_context_dis',10,0,15,menu_context_dis);

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

      main_behavior :=
        check_number('main_behavior',10,0,15,main_behavior);

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

      instrument_context :=
        check_number('instrument_context',10,0,15,instrument_context);

      instrument_adsr :=
        check_number('instrument_adsr',10,0,15,instrument_adsr SHR 4) SHL 4;

      instrument_ai_off :=
        check_number('instrument_ai_off',10,0,15,instrument_ai_off);

      instrument_ai_on :=
        check_number('instrument_ai_on',10,0,15,instrument_ai_on);

      instrument_ai_trig :=
        check_number('instrument_ai_trig',10,0,15,instrument_ai_trig);

      sdl_screen_mode :=
        check_number('sdl_screen_mode',10,0,2,sdl_screen_mode);

      sdl_sample_rate :=
        check_number('sdl_sample_rate',10,8000,48000,sdl_sample_rate);

      sdl_sample_buffer :=
        check_number('sdl_sample_buffer',10,512,32768,sdl_sample_buffer);

      sdl_delay_ms :=
        check_number('sdl_delay_ms',10,10,120,sdl_delay_ms);

      sdl_typematic_rate :=
        check_number('sdl_typematic_rate',10,1,100,sdl_typematic_rate);

      sdl_typematic_delay :=
        check_number('sdl_typematic_delay',10,0,2000,sdl_typematic_delay);

          If (Copy(data,1,18) = 'sdl_wav_directory=') and
         (Length(data) > 18) then
        begin
                  temp_str := Copy(data,19,Length(data)-18);
                  If (temp_str[1] = '\') then Delete(temp_str,1,1);
          If (temp_str <> '') then
                    begin
              If (Length(temp_str) > 4) then
                            If NOT (Lower(Copy(temp_str,Length(temp_str)-3,4)) = '.wav') then
                                  temp_str := temp_str+'\'
                                else opl3_flushmode := TRUE
                          else If (temp_str[Length(temp_str)] <> '\') then
                     temp_str := temp_str+'\';
                        end;
              sdl_wav_directory := temp_str;
              If NOT (Pos(':',sdl_wav_directory) <> 0) then
            sdl_wav_directory := PathOnly(ParamStr(0))+'\'+sdl_wav_directory;
        end;

      If (Copy(data,1,17) = 'a2m_default_path=') and
         (Length(data) > 17) then
        begin
          a2m_default_path := Copy(data,18,Length(data)-17);
          If (a2m_default_path <> '') and
             (a2m_default_path[Length(a2m_default_path)] <> '\') then
            a2m_default_path := a2m_default_path+'\';
        end;

      If (Copy(data,1,17) = 'a2t_default_path=') and
         (Length(data) > 17) then
        begin
          a2t_default_path := Copy(data,18,Length(data)-17);
          If (a2t_default_path <> '') and
             (a2t_default_path[Length(a2t_default_path)] <> '\') then
            a2t_default_path := a2t_default_path+'\';
        end;

      If (Copy(data,1,16) = 'a2i_default_path') and
         (Length(data) > 17) then
        begin
          a2i_default_path := Copy(data,18,Length(data)-17);
          If (a2i_default_path <> '') and
             (a2i_default_path[Length(a2i_default_path)] <> '\') then
            a2i_default_path := a2i_default_path+'\';
        end;

      If (Copy(data,1,16) = 'a2f_default_path') and
         (Length(data) > 17) then
        begin
          a2f_default_path := Copy(data,18,Length(data)-17);
          If (a2f_default_path <> '') and
             (a2f_default_path[Length(a2f_default_path)] <> '\') then
            a2f_default_path := a2f_default_path+'\';
        end;

      If (Copy(data,1,17) = 'a2p_default_path=') and
         (Length(data) > 17) then
        begin
          a2p_default_path := Copy(data,18,Length(data)-17);
          If (a2p_default_path <> '') and
             (a2p_default_path[Length(a2p_default_path)] <> '\') then
            a2p_default_path := a2p_default_path+'\';
        end;

      If (Copy(data,1,16) = 'a2b_default_path') and
         (Length(data) > 17) then
        begin
          a2b_default_path := Copy(data,18,Length(data)-17);
          If (a2b_default_path <> '') and
             (a2b_default_path[Length(a2b_default_path)] <> '\') then
            a2b_default_path := a2b_default_path+'\';
        end;

      If (Copy(data,1,16) = 'a2w_default_path') and
         (Length(data) > 17) then
        begin
          a2w_default_path := Copy(data,18,Length(data)-17);
          If (a2w_default_path <> '') and
             (a2w_default_path[Length(a2w_default_path)] <> '\') then
            a2w_default_path := a2w_default_path+'\';
        end;

      For temp := 0 to 15 do
        check_rgb('color'+ExpStrL(Num2str(temp,10),2,'0'),rgb_color[temp]);
    end;

  {$i-}
  Close(txtf);
  {$i+}
  If (IOresult <> 0) then ;
  WriteLn('ok');
end;

end.
