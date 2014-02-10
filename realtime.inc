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
  _decay_bar_str := flipStr(result);
end;

procedure show_bar(chan,level,xpos,from_pos,to_pos,attr: Byte);

var
  {index1,index2: Byte;}
  temp: Byte;

begin
  For temp := from_pos to to_pos do
    show_vcstr(xpos+temp-1+PRED(chan)*15,MAX_PATTERN_ROWS+14,
           ExpStrL('~'+_decay_bar_str(Round(105/63*level))+'~',9,'à'),
           analyzer_bckg+analyzer,
           analyzer_bckg+attr SHR 4);
end;

procedure decay_bars_refresh;

var
  chan: Byte;

begin
  show_bar(1,overall_volume,05,1,2,
           analyzer_ovrllvol+analyzer_ovrllvol SHL 4);
  show_bar(1,global_volume,MAX_COLUMNS-7,1,2,
           analyzer_volumelvl+analyzer_volumelvl SHL 4);

  For chan := chan_pos to chan_pos+MAX_TRACKS-1 do
    begin
      If (decay_bar[chan].dir1 = 1) then
        decay_bar[chan].lvl1 := decay_bar[chan].lvl1+
                 decay_bar[chan].dir1*(decay_bar_rise*5/IRQ_freq*100)
      else
        decay_bar[chan].lvl1 := decay_bar[chan].lvl1+
                 decay_bar[chan].dir1*(decay_bar_fall*5/IRQ_freq*100);

      If (decay_bar[chan].dir2 = 1) then
        decay_bar[chan].lvl2 := decay_bar[chan].lvl2+
                 decay_bar[chan].dir2*(decay_bar_rise*5/IRQ_freq*100)
      else
        decay_bar[chan].lvl2 := decay_bar[chan].lvl2+
                 decay_bar[chan].dir2*(decay_bar_fall*5/IRQ_freq*100);

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
                 volum_bar[chan].dir*(decay_bar_rise*5/IRQ_freq*100)
      else
        volum_bar[chan].lvl := volum_bar[chan].lvl+
                 volum_bar[chan].dir*(decay_bar_fall*5/IRQ_freq*100);

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
        show_bar(chan-PRED(chan_pos),Round(decay_bar[chan].lvl2),08,1,6,
                 analyzer+analyzer_modulator SHL 4)
      else
        show_bar(chan-PRED(chan_pos),
                 63-(scale_volume(63-Round(decay_bar[chan].lvl2),
                                  63-Round(decay_bar[chan].lvl1))),
                 08,1,6,
                 analyzer+analyzer_modulator SHL 4);

      If NOT (percussion_mode and (chan in [17..20])) then
        show_bar(chan-PRED(chan_pos),Round(decay_bar[chan].lvl1),08,8,14,
                 analyzer+analyzer_carrier SHL 4)
      else
        show_bar(chan-PRED(chan_pos),0,08,8,14,
                 analyzer+analyzer_carrier SHL 4);
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
  temps: String[15];
  temp,chan: Byte;

begin
  If really_no_status_refresh then EXIT;
  show_str(21,06,status_layout[play_status][8]+status_layout[play_status][9],
       status_background+status_play_state);

  If no_status_refresh then
    begin
      For chan := chan_pos to chan_pos+MAX_TRACKS-1 do
        If channel_flag[chan] then
          show_str(08+(chan-PRED(chan_pos)-1)*15,MAX_PATTERN_ROWS+11,
               ExpStrR('',14,'Í'),
               pattern_bckg+pattern_border);
      EXIT;
    end;

  temps := status_layout[play_status];
  show_str(14,06,ExpStrR(temps,10,' '),
       status_background+status_play_state);
  If NOT (sdl_screen_mode <> 0) and (@mn_environment.ext_proc_rt <> NIL) then
    show_str(02,01,' '+ExpStrR(temps,10,' '),
         main_background+main_border)
  else
    show_str(02,01,ExpStrR('',12,'Ä'),
         main_background+main_border);

  If single_play then EXIT;
  If play_single_patt then
    show_str(20,03,byte2hex(current_pattern)+'  ',
         pattern_bckg+status_dynamic_txt)
  else
    begin
      temp := songdata.pattern_order[current_order];
      If NOT (temp <= $7f) then temp := 0;
      If NOT replay_forbidden and repeat_pattern and
         NOT calibrating then
        show_str(20,03,byte2hex(temp)+' ',
             pattern_bckg+status_dynamic_txt)
      else If NOT calibrating then
             show_str(20,03,byte2hex(temp)+'  ',
                  status_background+status_dynamic_txt)
           else show_str(20,03,byte2hex(temp),status_background+status_dynamic_txt);
    end;

  If NOT play_single_patt then
    show_str(17,03,byte2hex(current_order),status_background+status_dynamic_txt)
  else show_str(17,03,'--',status_background+status_dynamic_txt);

  show_str(17,04,byte2hex(current_line),status_background+status_dynamic_txt);
  show_str(17,05,byte2hex(speed),status_background+status_dynamic_txt);

  If (tempo < 100) then
    If (tempo = 18) and timer_fix then
      show_str(20,05,byte2dec(tempo)+#5+#3,
           status_background+status_dynamic_txt)
    else show_str(20,05,byte2dec(tempo)+#3+' ',
              status_background+status_dynamic_txt)
  else show_str(20,05,byte2dec(tempo)+#3,
            status_background+status_dynamic_txt);

  If (play_status <> isStopped) then
      temps := ' '+byte2dec(song_timer DIV 60)+':'+
                   byte2dec(song_timer MOD 60)+'.'+
                   CHR(48+song_timer_tenths DIV 10)+' '
  else temps := ' 00~:~00~.~0 ';

  temp := Pos('.',songdata_title);
  If (play_status <> isStopped) then
    show_str(13,07,temps,
         status_background+status_border)
  else show_cstr(13,07,temps,
             status_background+status_text_dis,
             status_background+status_border);

  If NOT (sdl_screen_mode <> 0) and (@mn_environment.ext_proc_rt <> NIL) then
    If (play_status <> isStopped) then
      show_cstr(16,01,temps,
           main_background+main_border,
           main_background+main_border)
    else show_cstr(16,01,temps,
              main_background+main_border,
              main_background+main_border)
  else
    show_str(12,01,ExpStrR('',14,'Ä'),
         main_background+main_border);

  show_str(03,06,'['+ExpStrR(iCASE(Copy(songdata_title,1,PRED(temp))),8,' ')+']',
       status_background+status_dynamic_txt);
  show_str(03,07,'['+ExpStrR(iCASE(Copy(songdata_title,SUCC(temp),3)),3,' ')+']',
       status_background+status_border);

  If NOT module_archived then
    show_str(09,07,#29,
         status_background+status_dynamic_txt)
  else show_str(09,07,'Í',
            status_background+status_border);

  If (sdl_opl3_emulator = 0) then temps := 'MME'
  else temps := 'DBE';

  If NOT (sdl_screen_mode <> 0) and (@mn_environment.ext_proc_rt <> NIL) then
    show_str(13,01,temps,main_background+main_behavior)
  else show_str(08,07,'['+temps+']',main_background+main_behavior);
  
  If (command_typing = 1) then
    If NOT cycle_pattern then
      show_str(MAX_COLUMNS-20,MAX_PATTERN_ROWS+12,'AT',main_background+main_behavior)
    else show_str(MAX_COLUMNS-20,MAX_PATTERN_ROWS+12,'FT',main_background+main_behavior)
  else If (command_typing = 2) and NOT cycle_pattern then
         show_str(MAX_COLUMNS-20,MAX_PATTERN_ROWS+12,'ST',main_background+main_behavior)
       else show_str(MAX_COLUMNS-20,MAX_PATTERN_ROWS+12,'ÄÄ',main_background+main_border);

  For temp := 1 to 8 do
    If (temp <> current_octave) then
      show_str(30+temp,MAX_PATTERN_ROWS+12,CHR(48+temp),
           main_background+main_stat_line)
    else show_str(30+temp,MAX_PATTERN_ROWS+12,CHR(48+temp),
              main_background+main_hi_stat_line);

  For chan := chan_pos to max(chan_pos+MAX_TRACKS-1,songdata.nm_tracks) do
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
                 2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then temps := '~®¯~ '
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 3,
                 4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then temps := '~®¯~ '
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 5,
                 6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then temps := '~®¯~ '
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 10,
                 11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then temps := '~®¯~ '
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 12,
                 13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then temps := '~®¯~ '
                     else Case volslide_type[chan] of
                            0: temps := '   ';
                            1: temps := 'C'+#10+' ';
                            2: temps := 'M'+#10+' ';
                            3: temps := '&'+#10+' ';
                          end;
                 14,
                 15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then temps := '~®¯~ '
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
              0: show_str(12+(chan-PRED(chan_pos)-1)*15,09,' ',temp);
              1: show_str(12+(chan-PRED(chan_pos)-1)*15,09,'  ',temp);
              2: show_str(12+(chan-PRED(chan_pos)-1)*15,09,'  ',temp);
            end
          else
            Case panning_table[chan] of
              0: show_str(12+(chan-PRED(chan_pos)-1)*15,09,' ',temp);
              1: show_str(12+(chan-PRED(chan_pos)-1)*15,09,'  ',temp);
              2: show_str(12+(chan-PRED(chan_pos)-1)*15,09,'  ',temp);
            end;

          If NOT (chan in [16..20]) then
            show_cstr(12+(chan-PRED(chan_pos)-1)*15+3,09,ExpStrR(temps,7,' '),
                  pattern_bckg+pattern_lock_indic,
                  pattern_bckg+pattern_4op_indic)
          else show_cstr(12+(chan-PRED(chan_pos)-1)*15+3,09,ExpStrR(temps,7,' '),
                     pattern_bckg+pattern_lock_indic,
                     pattern_bckg+pattern_perc_indic);
        end
      else If NOT percussion_mode and (chan in [16..20]) then
             show_str(12+(chan-PRED(chan_pos)-1)*15,09,'úú '+ExpStrL('',7,' '),
                  pattern_bckg+pattern_pan_indic)
           else Case chan of
                  1,
                  2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then
                        show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                              pattern_bckg+pattern_pan_indic,
                              pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic);
                  3,
                  4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then
                        show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                              pattern_bckg+pattern_pan_indic,
                              pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic);
                  5,
                  6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then
                        show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                              pattern_bckg+pattern_pan_indic,
                              pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic);
                  10,
                  11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then
                        show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                              pattern_bckg+pattern_pan_indic,
                              pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic);
                  12,
                  13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then
                        show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                              pattern_bckg+pattern_pan_indic,
                              pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic);
                  14,
                  15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then
                        show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                              pattern_bckg+pattern_pan_indic,
                              pattern_bckg+pattern_4op_indic)
                      else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                 pattern_bckg+pattern_pan_indic,
                                 pattern_bckg+pattern_4op_indic);

                  16: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('BD',7,' ')+'~',
                            pattern_bckg+pattern_pan_indic,
                            pattern_bckg+pattern_perc_indic);
                  17: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('SD',7,' ')+'~',
                            pattern_bckg+pattern_pan_indic,
                            pattern_bckg+pattern_perc_indic);
                  18: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('TT',7,' ')+'~',
                            pattern_bckg+pattern_pan_indic,
                            pattern_bckg+pattern_perc_indic);
                  19: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('TC',7,' ')+'~',
                            pattern_bckg+pattern_pan_indic,
                            pattern_bckg+pattern_perc_indic);
                  20: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('HH',7,' ')+'~',
                            pattern_bckg+pattern_pan_indic,
                            pattern_bckg+pattern_perc_indic);
                  else show_str(12+(chan-PRED(chan_pos)-1)*15,09,'úú '+ExpStrL('',7,' '),
                            pattern_bckg+pattern_pan_indic);
                end;

      If NOT channel_flag[chan] then
        begin
          show_str(08+(chan-PRED(chan_pos)-1)*15,MAX_PATTERN_ROWS+11,'ÍÍÍ',
               pattern_bckg+pattern_border);
          show_str(11+(chan-PRED(chan_pos)-1)*15,MAX_PATTERN_ROWS+11,' () OFF ',
               pattern_bckg+pattern_chan_indic);
          show_str(19+(chan-PRED(chan_pos)-1)*15,MAX_PATTERN_ROWS+11,'ÍÍÍ',
               pattern_bckg+pattern_border);

          If NOT percussion_mode and (chan in [16..20]) then
            show_str(12+(chan-PRED(chan_pos)-1)*15,09,'úú '+ExpStrL('',7,' '),
                 pattern_bckg+pattern_pan_indic)
          else Case chan of
                 1,
                 2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then
                       show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                             pattern_bckg+pattern_pan_indic,
                             pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_4op_indic);
                 3,
                 4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then
                       show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                             pattern_bckg+pattern_pan_indic,
                             pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_4op_indic);
                 5,
                 6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then
                       show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                             pattern_bckg+pattern_pan_indic,
                             pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_4op_indic);
                 10,
                 11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then
                       show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                             pattern_bckg+pattern_pan_indic,
                             pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_4op_indic);
                 12,
                 13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then
                       show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                             pattern_bckg+pattern_pan_indic,
                             pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_4op_indic);
                 14,
                 15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then
                       show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('®¯',7,' ')+'~',
                             pattern_bckg+pattern_pan_indic,
                             pattern_bckg+pattern_4op_indic)
                     else show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('',7,' ')+'~',
                                pattern_bckg+pattern_pan_indic,
                                pattern_bckg+pattern_4op_indic);

                 16: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('BD',7,' ')+'~',
                           pattern_bckg+pattern_pan_indic,
                           pattern_bckg+pattern_perc_indic);
                 17: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('SD',7,' ')+'~',
                           pattern_bckg+pattern_pan_indic,
                           pattern_bckg+pattern_perc_indic);
                 18: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('TT',7,' ')+'~',
                           pattern_bckg+pattern_pan_indic,
                           pattern_bckg+pattern_perc_indic);
                 19: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('TC',7,' ')+'~',
                           pattern_bckg+pattern_pan_indic,
                           pattern_bckg+pattern_perc_indic);
                 20: show_cstr(12+(chan-PRED(chan_pos)-1)*15,09,'úú ~'+ExpStrR('HH',7,' ')+'~',
                           pattern_bckg+pattern_pan_indic,
                           pattern_bckg+pattern_perc_indic);
                 else show_str(12+(chan-PRED(chan_pos)-1)*15,09,'úú '+ExpStrL('',7,' '),
                           pattern_bckg+pattern_pan_indic);
               end;
        end
      else begin
             temp := 0;
             If NOT ((mouse_y > 10) or (sdl_screen_mode <> 0)) then
               temp := Round(42/63*volum_bar[chan].lvl);

             show_str(08+(chan-PRED(chan_pos)-1)*15,MAX_PATTERN_ROWS+11,
                  ExpStrR(_vol_bar_str(temp),14,'Í'),
                  pattern_bckg+pattern_border);
           end;
    end;
end;

procedure slide_show;
begin
  Case slide_pos of
    00..17: show_str(01+(MAX_COLUMNS-18) DIV 2,01,adt2_title[slide_pos],main_background+main_title);
    18..80: show_str(01+(MAX_COLUMNS-18) DIV 2,01,adt2_title[18],main_background+main_title);
    81..98: show_str(01+(MAX_COLUMNS-18) DIV 2,01,adt2_title[slide_pos-62],main_background+main_title);
    else ;
  end;

  If (slide_pos < 150) then Inc(slide_pos)
  else begin
         slide_pos := 0;
         do_slide := FALSE;
       end;
end;
