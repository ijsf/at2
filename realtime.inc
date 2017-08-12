{
        function  _decay_bar_str(value: Byte): String;
        procedure show_bar(chan,level,xpos,from_pos,to_pos,attr: Byte);
        procedure decay_bars_refresh;
        function  _vol_bar_str(value: Byte): String;
        procedure status_refresh;
        procedure trace_update_proc;
}

function _decay_bar_str(value: Byte): String;

var
  result: String;

begin
  result := '';
  Repeat
    If (value > 15) then
      begin
        result := result+#219;
        Dec(value,15);
      end;
    If (value <= 15) and (value <> 0) then
      result := result+CHR(224+value)
  until (value <= 15);
  _decay_bar_str := FlipStr(result);
end;

procedure show_bar(chan,level,xpos,from_pos,to_pos,attr: Byte);

var
  temp: Byte;

begin
  For temp := from_pos to to_pos do
    show_vcstr(xpos+temp-1+PRED(chan)*15,MAX_PATTERN_ROWS+14,
               ExpStrL('~'+_decay_bar_str(Round(105/63*level))+'~',9,#224),
               analyzer_bckg+analyzer,
               analyzer_bckg+attr SHR 4);
end;

procedure decay_bars_refresh;

var
  chan,temp: Byte;
  speedup_factor,speedown_factor: Real;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'REALTIME.INC:decay_bars_refresh';
{$ENDIF}
  show_bar(1,overall_volume,05,1,2,
           analyzer_ovrllvol+analyzer_ovrllvol SHL 4);
  show_bar(1,global_volume,MAX_COLUMNS-7,1,2,
           analyzer_volumelvl+analyzer_volumelvl SHL 4);

{$IFDEF GO32V2}
  speedup_factor := 4.0*SUCC(fps_down_factor);
  speedown_factor :=4.0*SUCC(fps_down_factor);
{$ELSE}
  speedup_factor := 2.5*(100/sdl_frame_rate);
  speedown_factor := 2.5*(100/sdl_frame_rate);
{$ENDIF}

  chan := chan_pos;
  For temp := 1 to MAX_TRACKS do
    begin
      If (decay_bar[chan].dir1 = 1) then
        decay_bar[chan].lvl1 := decay_bar[chan].lvl1+
                 decay_bar[chan].dir1*(decay_bar_rise*speedup_factor)
      else
        decay_bar[chan].lvl1 := decay_bar[chan].lvl1+
                 decay_bar[chan].dir1*(decay_bar_fall*speedown_factor);

      If (decay_bar[chan].dir2 = 1) then
        decay_bar[chan].lvl2 := decay_bar[chan].lvl2+
                 decay_bar[chan].dir2*(decay_bar_rise*speedup_factor)
      else
        decay_bar[chan].lvl2 := decay_bar[chan].lvl2+
                 decay_bar[chan].dir2*(decay_bar_fall*speedown_factor);

      If (decay_bar[chan].lvl1 < 0) then decay_bar[chan].lvl1 := 0;
      If (decay_bar[chan].lvl1 > 63) then decay_bar[chan].lvl1 := 63;
      If (decay_bar[chan].lvl1 >= carrier_vol[chan]) then
        decay_bar[chan].dir1 := -1;

      If (decay_bar[chan].lvl2 < 0) then decay_bar[chan].lvl2 := 0;
      If (decay_bar[chan].lvl2 > 63) then decay_bar[chan].lvl2 := 63;
      If (decay_bar[chan].lvl2 >= modulator_vol[chan]) then
        decay_bar[chan].dir2 := -1;

      If (volum_bar[chan].dir = 1) then
        volum_bar[chan].lvl := volum_bar[chan].lvl+
                 volum_bar[chan].dir*(decay_bar_rise*speedup_factor)
      else
        volum_bar[chan].lvl := volum_bar[chan].lvl+
                 volum_bar[chan].dir*(decay_bar_fall*speedown_factor);

      If (volum_bar[chan].lvl < 0) then volum_bar[chan].lvl := 0;
      If (volum_bar[chan].lvl > 63) then volum_bar[chan].lvl := 63;
      If NOT (percussion_mode and (chan in [17..20])) then
        If (ins_parameter(voice_table[chan],10) AND 1 = 1) then
          If (volum_bar[chan].lvl >= (carrier_vol[chan]+modulator_vol[chan]) DIV 2) then
            volum_bar[chan].dir := -1
          else
        else If (volum_bar[chan].lvl >= carrier_vol[chan]) then
               volum_bar[chan].dir := -1
             else
      else If (volum_bar[chan].lvl >= modulator_vol[chan]) then
             volum_bar[chan].dir := -1;

      If (ins_parameter(voice_table[chan],10) AND 1 = 1) or
         (percussion_mode and (chan in [17..20])) then
        show_bar(temp,Round(decay_bar[chan].lvl2),08,1,6,
                 analyzer+analyzer_modulator SHL 4)
      else
        show_bar(temp,
                 63-(scale_volume(63-Round(decay_bar[chan].lvl2),
                                  63-Round(decay_bar[chan].lvl1))),
                 08,1,6,
                 analyzer+analyzer_modulator SHL 4);

      If NOT (percussion_mode and (chan in [17..20])) then
        show_bar(temp,Round(decay_bar[chan].lvl1),08,8,14,
                 analyzer+analyzer_carrier SHL 4)
      else
        show_bar(temp,0,08,8,14,
                 analyzer+analyzer_carrier SHL 4);
      Inc(chan);
    end;
end;

function _vol_bar_str(value: Byte): String;

var
  result: String;

begin
  result := '';
  Repeat
    If (value > 3) then
      begin
        result := result+#168;
        Dec(value,3);
      end;
    If (value <= 3) and (value <> 0) then
      result := result+CHR(164+value)
  until (value <= 3);
  _vol_bar_str := result;
end;

procedure status_refresh;

var
  temps: String;
  temp,temp2,chan: Byte;
{$IFNDEF GO32V2}
  wav_indicator_attr: array[Boolean] of Byte;
{$ENDIF}

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'REALTIME.INC:status_refresh:1/4';
{$ENDIF}
  If really_no_status_refresh then EXIT;
  show_str(21,06,status_layout[play_status][8]+status_layout[play_status][9],
           status_background+status_play_state);

{$IFDEF GO32V2}
  _debug_str_ := 'REALTIME.INC:status_refresh:2/4';
{$ENDIF}
  If no_status_refresh then
    begin
      chan := chan_pos;
      For temp2 := 1 to MAX_TRACKS do
        begin
          If channel_flag[chan] then
            show_str(08+(temp2-1)*15,MAX_PATTERN_ROWS+11,
                     ExpStrR('',14,#205),
                     pattern_bckg+pattern_border);
          Inc(chan);
        end;
      EXIT;
    end;

{$IFDEF GO32V2}
  _debug_str_ := 'REALTIME.INC:status_refresh:3/4';
{$ENDIF}
  temps := status_layout[play_status];
  show_str(14,06,ExpStrR(temps,10,' '),
           status_background+status_play_state);
  If (mn_environment.ext_proc_rt <> NIL) and is_default_screen_mode then
    show_str(02,01,' '+ExpStrR(temps,10,' '),
             main_background+main_border)
  else
    show_str(02,01,ExpStrR('',12,#196),
             main_background+main_border);

  If single_play then EXIT;
{$IFDEF GO32V2}
  _debug_str_ := 'REALTIME.INC:status_refresh:4/4';
{$ENDIF}

  If play_single_patt then
    show_str(20,03,byte2hex(current_pattern)+'  ',
             pattern_bckg+status_dynamic_txt)
  else
    begin
      temp := songdata.pattern_order[current_order];
      If NOT (temp <= $7f) then temp := 0;
      If NOT replay_forbidden and repeat_pattern and
         NOT calibrating then
        show_str(20,03,byte2hex(temp)+' '#19,
                 pattern_bckg+status_dynamic_txt)
      else If NOT calibrating then
             show_str(20,03,byte2hex(temp)+'  ',
                      status_background+status_dynamic_txt)
           else show_str(20,03,byte2hex(temp),
                         status_background+status_dynamic_txt);
    end;

  If NOT play_single_patt then
    show_str(17,03,byte2hex(current_order),
             status_background+status_dynamic_txt)
  else show_str(17,03,'--',
                status_background+status_dynamic_txt);

  show_str(17,04,byte2hex(current_line),
           status_background+status_dynamic_txt);
  show_str(17,05,byte2hex(speed),
           status_background+status_dynamic_txt);

  If (tempo < 100) then
    If (tempo = 18) and timer_fix then
      show_str(20,05,byte2dec(tempo)+#5+#174,
               status_background+status_dynamic_txt)
    else show_str(20,05,byte2dec(tempo)+#174+' ',
                  status_background+status_dynamic_txt)
  else show_str(20,05,byte2dec(tempo)+#174,
                status_background+status_dynamic_txt);

  If (play_status <> isStopped) then
    temps := ' ~'+byte2dec(max(song_timer DIV 60,99))+':'+
                 byte2dec(max(song_timer MOD 60,99))+'.'+
                 CHR(48+max(song_timer_tenths DIV 10,9))+'~ '
  else temps := ' 00~:~00~.~0 ';

  show_cstr(13,07,temps,
            status_background+status_text_dis,
            status_background+status_border);

  If (mn_environment.ext_proc_rt <> NIL) and is_default_screen_mode then
    show_cstr(16,01,temps,
              main_background+main_border,
              main_background+main_border)
  else
    show_str(16,01,ExpStrR('',11,#196),
             main_background+main_border);

{$IFDEF GO32V2}
  temp := Pos('.',songdata_title);
  show_str(03,06,'['+ExpStrR(iCASE(Copy(songdata_title,1,PRED(temp))),8,' ')+']',
           status_background+status_dynamic_txt);
  show_str(03,07,'['+ExpStrR(iCASE(Copy(songdata_title,SUCC(temp),3)),3,' ')+']',
           status_background+status_border);

  If NOT module_archived then
    show_str(08,07,'['+#29+']',
             main_background+main_behavior)
  else show_str(08,07,#205#205#205,
                status_background+status_border);
{$ELSE}
  temps := BaseNameOnly(FilterStr2(songdata_title,_valid_characters_fname,'_'));

  While (8+_name_scrl_shift > Length(temps)) and (_name_scrl_shift > 0) do
    Dec(_name_scrl_shift);

  show_str(03,06,'['+ExpStrR(iCASE(Copy(temps,1+_name_scrl_shift,8)),8,' ')+']',
       status_background+status_dynamic_txt);
  show_str(03,07,'['+ExpStrR(iCASE(Copy(ExtOnly(songdata_title),1,3)),3,' ')+']',
       status_background+status_border);

  If (_name_scrl_pending_frames <> 0) then Dec(_name_scrl_pending_frames)
  else
    begin
      _name_scrl_pending_frames := 20;
      If (_name_scrl_shift_ctr > 0) then
        If (8+_name_scrl_shift < Length(temps)) then Inc(_name_scrl_shift,_name_scrl_shift_ctr)
        else begin
               _name_scrl_shift_ctr := -1;
               _name_scrl_pending_frames := _name_scrl_pending_frames*10;
             end
      else If (_name_scrl_shift > 0) then Inc(_name_scrl_shift,_name_scrl_shift_ctr)
           else begin
                  _name_scrl_shift_ctr := 1;
                  _name_scrl_pending_frames := _name_scrl_pending_frames*50;
                end;
    end;

  wav_indicator_attr[FALSE] := main_background+main_behavior;
  If (play_status = isPlaying) and NOT opl3_channel_recording_mode then
    wav_indicator_attr[TRUE] := (main_behavior SHL 4) AND $0f0
  else wav_indicator_attr[TRUE] := main_background+main_behavior;

  If is_default_screen_mode and (mn_environment.ext_proc_rt <> NIL) then
    If (sdl_opl3_emulator <> 0) then
      show_str(13,01,'WAV',wav_indicator_attr[_generic_blink_event_flag])
    else show_str(13,01,#196#196#196,main_background+main_border)
  else If (sdl_opl3_emulator = 1) then
         show_str(08,07,'[WAV]',wav_indicator_attr[_generic_blink_event_flag])
       else If NOT module_archived then
              show_cstr(08,07,'~['+#29+']~'#205#205,
                        status_background+status_border,
                        main_background+main_behavior)
            else show_str(08,07,#205#205#205#205#205,
                          status_background+status_border);
{$ENDIF}

  If (command_typing = 1) then
    If NOT cycle_pattern then
      show_str(MAX_COLUMNS-17,MAX_PATTERN_ROWS+12,'A',main_background+main_behavior)
    else show_str(MAX_COLUMNS-17,MAX_PATTERN_ROWS+12,'F',main_background+main_behavior)
  else If (command_typing = 2) and NOT cycle_pattern then
         show_str(MAX_COLUMNS-17,MAX_PATTERN_ROWS+12,'S',main_background+main_behavior)
       else show_str(MAX_COLUMNS-17,MAX_PATTERN_ROWS+12,#196,main_background+main_border);

  If (songdata.flag_4op <> 0) then
    show_cstr(MAX_COLUMNS-43,MAX_PATTERN_ROWS+12,'~[~'+#4#3+'~]~',
              main_background+main_hi_stat_line,
              main_background+main_stat_line)
  else show_cstr(MAX_COLUMNS-43,MAX_PATTERN_ROWS+12,'~[~'+#2+#3+'~]~',
                main_background+main_hi_stat_line,
                main_background+main_stat_line);

  For temp := 1 to 8 do
    If (temp <> current_octave) then
      show_str(30+temp,MAX_PATTERN_ROWS+12,CHR(48+temp),
               main_background+main_stat_line)
    else show_str(30+temp,MAX_PATTERN_ROWS+12,CHR(48+temp),
                  main_background+main_hi_stat_line);

  chan := chan_pos;
  For temp2 := 1 to max(MAX_TRACKS,songdata.nm_tracks) do
    begin
      If NOT pan_lock[chan] or
         ((play_status = isStopped) and NOT debugging) then
        temp := pattern_bckg+pattern_pan_indic
      else temp := pattern_bckg+pattern_gpan_indic;

      If NOT ((play_status = isStopped) and NOT debugging and NOT panlock) and
         channel_flag[chan] then
        begin
          If percussion_mode and (chan in [16..20]) then
            Case chan of
              16: temps := '~BD~ ';
              17: temps := '~SD~ ';
              18: temps := '~TT~ ';
              19: temps := '~TC~ ';
              20: temps := '~HH~ ';
            end
          else Case chan of
                 1,
                 2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then
                       If NOT vol4op_lock[chan] then temps := '~'#4#3'~ '
                       else temps := '~'#4#3'+~'
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 3,
                 4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then
                       If NOT vol4op_lock[chan] then temps := '~'#4#3'~ '
                       else temps := '~'#4#3'+~'
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 5,
                 6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then
                       If NOT vol4op_lock[chan] then temps := '~'#4#3'~ '
                       else temps := '~'#4#3'+~'
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 10,
                 11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then
                       If NOT vol4op_lock[chan] then temps := '~'#4#3'~ '
                       else temps := '~'#4#3'+~'
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 12,
                 13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then
                       If NOT vol4op_lock[chan] then temps := '~'#4#3'~ '
                       else temps := '~'#4#3'+~'
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 14,
                 15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then
                       If NOT vol4op_lock[chan] then temps := '~'#4#3'~ '
                       else temps := '~'#4#3'+~'
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;

                 else Case volslide_type[chan] of
                        0: temps := '   ';
                        1: temps := 'C'+#10+' ';
                        2: temps := 'M'+#10+' ';
                        3: temps := '&'+#10+' ';
                      end;
               end;

          If volume_lock[chan] then temps := temps+'V+';
          If peak_lock[chan] then temps := temps+'P+';

          If panlock and (play_status = isStopped) and NOT debugging then
            Case songdata.lock_flags[chan] AND 3 of
              0: show_str(12+(temp2-1)*15,09,#21#22' ',temp);
              1: show_str(12+(temp2-1)*15,09,#21'  ',temp);
              2: show_str(12+(temp2-1)*15,09,' '#22' ',temp);
            end
          else
            Case panning_table[chan] of
              0: show_str(12+(temp2-1)*15,09,#21#22' ',temp);
              1: show_str(12+(temp2-1)*15,09,#21'  ',temp);
              2: show_str(12+(temp2-1)*15,09,' '#22' ',temp);
            end;

          If NOT (chan in [16..20]) then
            show_cstr(12+(temp2-1)*15+3,09,ExpStrR(temps,7,' '),
                      pattern_bckg+pattern_lock_indic,
                      pattern_bckg+pattern_4op_indic)
          else show_cstr(12+(temp2-1)*15+3,09,ExpStrR(temps,7,' '),
                         pattern_bckg+pattern_lock_indic,
                         pattern_bckg+pattern_perc_indic);
        end
      else If NOT percussion_mode and (chan in [16..20]) then
             show_str(12+(temp2-1)*15,09,#250#250' '+ExpStrL('',7,' '),
                      pattern_bckg+pattern_pan_indic)
           else Case chan of
                  1,
                  2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then
                        show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                  pattern_bckg+pattern_pan_indic,
                                  pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                     pattern_bckg+pattern_pan_indic,
                                     pattern_bckg+pattern_4op_indic);
                  3,
                  4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then
                        show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                  pattern_bckg+pattern_pan_indic,
                                  pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                     pattern_bckg+pattern_pan_indic,
                                     pattern_bckg+pattern_4op_indic);
                  5,
                  6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then
                        show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                  pattern_bckg+pattern_pan_indic,
                                  pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                     pattern_bckg+pattern_pan_indic,
                                     pattern_bckg+pattern_4op_indic);
                  10,
                  11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then
                        show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                  pattern_bckg+pattern_pan_indic,
                                  pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                     pattern_bckg+pattern_pan_indic,
                                     pattern_bckg+pattern_4op_indic);
                  12,
                  13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then
                        show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                  pattern_bckg+pattern_pan_indic,
                                  pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                     pattern_bckg+pattern_pan_indic,
                                     pattern_bckg+pattern_4op_indic);
                  14,
                  15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then
                        show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                  pattern_bckg+pattern_pan_indic,
                                  pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                     pattern_bckg+pattern_pan_indic,
                                     pattern_bckg+pattern_4op_indic);

                  16: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('BD',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_perc_indic);
                  17: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('SD',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_perc_indic);
                  18: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('TT',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_perc_indic);
                  19: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('TC',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_perc_indic);
                  20: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('HH',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_perc_indic);
                  else show_str(12+(temp2-1)*15,09,#250#250' '+ExpStrL('',7,' '),
                                pattern_bckg+pattern_pan_indic);
                end;

      If NOT channel_flag[chan] then
        begin
          show_str(08+(temp2-1)*15,MAX_PATTERN_ROWS+11,#205#205#205,
                   pattern_bckg+pattern_border);
          show_str(11+(temp2-1)*15,MAX_PATTERN_ROWS+11,' () OFF ',
                   pattern_bckg+pattern_chan_indic);
          If (temp2 < max(MAX_TRACKS,songdata.nm_tracks)) then
            show_str(19+(temp2-1)*15,MAX_PATTERN_ROWS+11,#205#205#205#207,
                     pattern_bckg+pattern_border)
          else
            show_str(19+(temp2-1)*15,MAX_PATTERN_ROWS+11,#205#205#205#202,
                     pattern_bckg+pattern_border);

          If NOT percussion_mode and (chan in [16..20]) then
            show_str(12+(temp2-1)*15,09,#250#250' '+ExpStrL('',7,' '),
                     pattern_bckg+pattern_pan_indic)
          else Case chan of
                 1,
                 2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then
                       show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                    pattern_bckg+pattern_pan_indic,
                                    pattern_bckg+pattern_4op_indic);
                 3,
                 4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then
                       show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                    pattern_bckg+pattern_pan_indic,
                                    pattern_bckg+pattern_4op_indic);
                 5,
                 6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then
                       show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                    pattern_bckg+pattern_pan_indic,
                                    pattern_bckg+pattern_4op_indic);
                 10,
                 11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then
                       show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                    pattern_bckg+pattern_pan_indic,
                                    pattern_bckg+pattern_4op_indic);
                 12,
                 13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then
                       show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                    pattern_bckg+pattern_pan_indic,
                                    pattern_bckg+pattern_4op_indic);
                 14,
                 15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then
                       show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR(''#4#3'',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('',7,' ')+'~',
                                    pattern_bckg+pattern_pan_indic,
                                    pattern_bckg+pattern_4op_indic);

                 16: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('BD',7,' ')+'~',
                               pattern_bckg+pattern_pan_indic,
                               pattern_bckg+pattern_perc_indic);
                 17: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('SD',7,' ')+'~',
                               pattern_bckg+pattern_pan_indic,
                               pattern_bckg+pattern_perc_indic);
                 18: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('TT',7,' ')+'~',
                               pattern_bckg+pattern_pan_indic,
                               pattern_bckg+pattern_perc_indic);
                 19: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('TC',7,' ')+'~',
                               pattern_bckg+pattern_pan_indic,
                               pattern_bckg+pattern_perc_indic);
                 20: show_cstr(12+(temp2-1)*15,09,#250#250' ~'+ExpStrR('HH',7,' ')+'~',
                               pattern_bckg+pattern_pan_indic,
                               pattern_bckg+pattern_perc_indic);
                 else show_str(12+(temp2-1)*15,09,#250#250' '+ExpStrL('',7,' '),
                               pattern_bckg+pattern_pan_indic);
               end;
        end
      else begin
             temp := 0;
{$IFDEF GO32V2}
             If NOT ((scr_scroll_y > 10) or NOT is_scrollable_screen_mode) then
{$ELSE}
             If NOT ((screen_scroll_offset > 10) or NOT is_default_screen_mode) then
{$ENDIF}
               If NOT is_4op_chan(chan) or
                  (is_4op_chan(chan) and (((chan in _4op_tracks_lo) and (temp2 = 1)) or
                                          ((chan in _4op_tracks_hi) and (temp2 = max(MAX_TRACKS,songdata.nm_tracks))))) then
                 begin
                   temp := Round(42/63*volum_bar[chan].lvl);
                   If (temp2 < max(MAX_TRACKS,songdata.nm_tracks)) then
                     show_str(08+(temp2-1)*15,11+MAX_PATTERN_ROWS,
                              ExpStrR(_vol_bar_str(temp),14,#205)+#207,
                              pattern_bckg+pattern_border)
                   else
                     show_str(08+(temp2-1)*15,11+MAX_PATTERN_ROWS,
                              ExpStrR(_vol_bar_str(temp),14,#205)+#202,
                              pattern_bckg+pattern_border);
                 end
               else If (chan in _4op_tracks_hi) then
                      begin
                        temp := Round(84/63*volum_bar[chan].lvl);
                        temps := _vol_bar_str(temp);
                        If (Length(temps) > 14) then
                          begin
                            temps[15] := #169;
                            temps := ExpStrR(temps,29,#205);
                          end
                        else
                          begin
                            temps := ExpStrR(temps,29,#205);
                            temps[15] := #207;
                          end;
                        If (temp2 < PRED(max(MAX_TRACKS,songdata.nm_tracks))) then
                          temps := temps+#207
                        else temps := temps+#202;
                        show_str(08+(temp2-1)*15,11+MAX_PATTERN_ROWS,
                                 temps,
                                 pattern_bckg+pattern_border);
                      end
                    else
             else
               show_str(08+(temp2-1)*15,11+MAX_PATTERN_ROWS,Copy(patt_win[5],07+(temp2-1)*15,15),
                        pattern_bckg+pattern_border);
           end;
      Inc(chan);
    end;
end;

procedure trace_update_proc;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'IPATTERN.INC:trace_update_proc';
{$ENDIF}
  space_pressed := scankey(SC_SPACE);
  If (play_status = isPlaying) then
    If (_traceprc_last_order <> current_order) or
       (_traceprc_last_pattern <> current_pattern) or
       (_traceprc_last_line <> current_line) then
      begin
        _traceprc_last_order := current_order;
        _traceprc_last_pattern := songdata.pattern_order[current_order];
        _traceprc_last_line := current_line;

        If tracing then
          begin
            If NOT play_single_patt then
              pattern_patt := songdata.pattern_order[current_order];

            pattern_page := current_line;
            pattord_page := 0;
            pattord_hpos := 1;
            pattord_vpos := 1;

            While (current_order <> pattord_vpos+4*(pattord_hpos+pattord_page-1)-1) do
              If (pattord_vpos < 4) then Inc(pattord_vpos)
              else If (pattord_hpos < MAX_ORDER_COLS) then begin Inc(pattord_hpos); pattord_vpos := 1; end
                   else If (pattord_page < 23-(MAX_ORDER_COLS-9)) then begin Inc(pattord_page); pattord_vpos := 1; end;
          end;

        PATTERN_ORDER_page_refresh(pattord_page);
        PATTERN_page_refresh(pattern_page);
      end;
end;
