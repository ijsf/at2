{
        procedure PATTERN_tabs_refresh;
        procedure STATUS_LINE_refresh;
        function last_chan_pos: Byte;
        function last_hpos: Byte;
        procedure PATTERN_page_refresh(page: Byte);
        procedure PATTERN_position_preview(pattern,line,channel,mode: Byte);
        procedure update_trace;
        procedure update_without_trace;
        function PATTERN_trace: Word;
        procedure PATTERN_edit(var pattern,page,hpos: Byte);
}

procedure PATTERN_tabs_refresh;

var
  temp: Byte;

begin
  If (command_typing <> 0) then
    begin
      For temp := chan_pos to max(chan_pos+MAX_TRACKS-1,songdata.nm_tracks) do
        If (temp <> count_channel(pattern_hpos)) then
          show_str(08+(temp-PRED(chan_pos)-1)*15,10,
                   'ออออออออออออออ',
                   pattern_bckg+pattern_border);

      Case count_pos(pattern_hpos) of
        0,
        1: show_cstr(08+(count_channel(pattern_hpos)-PRED(chan_pos)-1)*15,10,
                     '~~อ~~อออออออออออ',
                     pattern_bckg+pattern_border,
                     pattern_bckg+pattern_pos_indic);
        2,
        3: show_cstr(08+(count_channel(pattern_hpos)-PRED(chan_pos)-1)*15,10,
                     'ออออ~~ออออออออ',
                     pattern_bckg+pattern_border,
                     pattern_bckg+pattern_pos_indic);
        4,5,
        6: show_cstr(08+(count_channel(pattern_hpos)-PRED(chan_pos)-1)*15,10,
                     'อออออออ~~ออออ',
                     pattern_bckg+pattern_border,
                     pattern_bckg+pattern_pos_indic);
        7,8,
        9: show_cstr(08+(count_channel(pattern_hpos)-PRED(chan_pos)-1)*15,10,
                     'อออออออออออ~~',
                     pattern_bckg+pattern_border,
                     pattern_bckg+pattern_pos_indic);
      end;
    end;
end;

procedure STATUS_LINE_refresh;
begin
  If _debug_ then
    _debug_str_ := 'IPATTERN.INC:STATUS_LINE_refresh';
  If (_4op_to_test <> 0) then
    show_cstr(40,MAX_PATTERN_ROWS+12,'~[~'+byte2hex(HI(_4op_to_test))+'~+~'+byte2hex(LO(_4op_to_test))+'~]~',
              main_background+main_hi_stat_line,
              main_background+main_stat_line)
  else show_cstr(40,MAX_PATTERN_ROWS+12,'~[~'+byte2hex(current_inst)+'~]~ฤฤฤ',
                 main_background+main_border,
                 main_background+main_stat_line);

  If marking and NOT (discard_block or
                     (tracing and (pattern_patt <> tracing_block_pattern))) then
    show_cstr(MAX_COLUMNS-43,MAX_PATTERN_ROWS+12,'~[BEGiN:~'+
              byte2hex(block_y0)+','+byte2dec(block_x0)+'~;END:~'+
              byte2hex(block_y1)+','+byte2dec(block_x1)+'~]~',
              main_background+main_hi_stat_line,
              main_background+main_stat_line)
  else begin
         show_cstr(MAX_COLUMNS-43,MAX_PATTERN_ROWS+12,'~[LN:~'+ExpStrL(Num2str(pattern_page,10),3,'0')+'/'+ExpStrL(Num2str(PRED(songdata.patt_len),10),3,'0')+'~]~',
                   main_background+main_hi_stat_line,
                   main_background+main_stat_line);
         show_cstr(MAX_COLUMNS-31,MAX_PATTERN_ROWS+12,'~[TRK:~'+byte2dec(count_channel(pattern_hpos))+'/'+byte2dec(songdata.nm_tracks)+'~]~',
                   main_background+main_hi_stat_line,
                   main_background+main_stat_line);
       end;

  If midiboard or (debugging and (play_status = isStopped)) then
    show_str(03,MAX_PATTERN_ROWS+12,'MBOARD',main_background+main_hi_stat_line)
  else show_str(03,MAX_PATTERN_ROWS+12,'MBOARD',main_background+main_stat_line);

  If NOT debugging and tracing and (play_status <> isStopped) then
    show_str(10,MAX_PATTERN_ROWS+12,'TRACE',main_background+main_hi_stat_line)
  else show_str(10,MAX_PATTERN_ROWS+12,'TRACE',main_background+main_stat_line);

  If debugging and (play_status <> isStopped) then
    show_str(16,MAX_PATTERN_ROWS+12,'DEBUG',main_background+main_hi_stat_line)
  else show_str(16,MAX_PATTERN_ROWS+12,'DEBUG',main_background+main_stat_line);

  If debugging and (play_status = isStopped) then
    show_str(22,MAX_PATTERN_ROWS+12,'TRACKiNG',main_background+main_hi_stat_line)
  else show_str(22,MAX_PATTERN_ROWS+12,'TRACKiNG',main_background+main_stat_line);
end;

function last_chan_pos: Byte;
begin
  If (songdata.nm_tracks > MAX_TRACKS) then
    last_chan_pos := max(16,songdata.nm_tracks-MAX_TRACKS+1)
  else last_chan_pos := 1;
end;

function last_hpos: Byte;
begin
  last_hpos := max(PATEDIT_lastpos,songdata.nm_tracks*(PATEDIT_lastpos DIV MAX_TRACKS));
end;

procedure PATTERN_page_refresh(page: Byte);

var
  attr: Word;
  temp,temp1,temp2,temp3,attr2,attr3: Byte;
  chan_attr: Byte;
  chanrec_indicator_attr: array[Boolean] of Byte;
  temps: String;
  spos,epos: Byte;
  dummy_str: String[1];
  dummy_atr: Byte;
  chunk: tCHUNK;
  _row_bckg,
  _row_bckg2,
  _row_fgnd: Byte;
  _no_block_tracing: Boolean;

function PRED1(value: Longint): Longint;
begin
  If (value > 1) then PRED1 := PRED(value)
  else PRED1 := 1;
end;

procedure _set_attr(chan: Byte; chunk: tCHUNK;
                    _bckg,_fix_note,_note,_note0,_note_hid,_inst,_inst0: Byte;
                    var attr: Word; var attr2: Byte);
begin
  If NOT (is_4op_chan(chan) and
         (chan in [1,3,5,10,12,14])) then
    If (chunk.note <> 0) then
      If (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1]) then
        attr := attr+(_bckg+_fix_note) SHL 8
      else attr := attr+(_bckg+_note) SHL 8
    else attr := attr+(_bckg+_note0) SHL 8
  else attr := attr+(_bckg+_note_hid) SHL 8;

  If (chunk.instr_def <> 0) then attr2 := _bckg+_inst
  else attr2 := _bckg+_inst0;
end;

begin
  _debug_str_ := 'IPATTERN.INC:PATTERN_page_refresh';
  For temp := SUCC(songdata.nm_tracks) to MAX_TRACKS do
    begin
      show_str(08+(temp-1)*15,10,'ออออออออออออออ',
               pattern_bckg+pattern_border);
      show_str(11+(temp-1)*15,09,ExpStrL('',10,' '),
               pattern_bckg+pattern_border);
    end;

  PATTERN_tabs_refresh;
  If (page > PRED(songdata.patt_len)) then
    page := PRED(songdata.patt_len);

  If (pattern_page > PRED(songdata.patt_len)) then
    pattern_page := PRED(songdata.patt_len);

  While NOT ((chan_pos <= last_chan_pos) and (pattern_hpos <= last_hpos)) do
    If (pattern_hpos > PATEDIT_lastpos DIV MAX_TRACKS) then
      begin
        Dec(pattern_hpos,PATEDIT_lastpos DIV MAX_TRACKS);
        If (pattern_hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS) > 0) then
          temp := PRED(pattern_hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS))
        else temp := PRED(PATEDIT_lastpos DIV MAX_TRACKS);
        Dec(pattern_hpos,temp);
      end
    else If (chan_pos > 1) then
           begin
             Dec(chan_pos);
             If (pattern_hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS) > 0) then
               temp := PRED(pattern_hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS))
             else temp := PRED(PATEDIT_lastpos DIV MAX_TRACKS);
             Dec(pattern_hpos,temp);
           end
         else If cycle_pattern then
                begin
                  chan_pos := last_chan_pos;
                  pattern_hpos := last_hpos;
                end;

  If (page < PRED(MAX_PATTERN_ROWS DIV 2)) then spos := PRED(MAX_PATTERN_ROWS DIV 2)-page else spos := 0;
  If (page > INTEGER(PRED(songdata.patt_len))-PRED(MAX_PATTERN_ROWS DIV 2)-1) then
    epos := page-(INTEGER(PRED(songdata.patt_len))-PRED(MAX_PATTERN_ROWS DIV 2)-1)
  else epos := 0;

  If (spos <> 0) or (epos <> 0) then
    For temp2 := chan_pos to chan_pos+MAX_TRACKS-1 do
      begin
        If (temp2-PRED(chan_pos) <> MAX_TRACKS) then dummy_str := 'ณ'
        else dummy_str := '';

        If (spos <> 0) then
          For temp3 := 1 to spos do
            begin
              show_str(03,10+temp3,ExpStrL('',4,' ')+'บ',pattern_bckg+pattern_border);
              show_str(MAX_COLUMNS-8,10+temp3,'บ'+ExpStrL('',4,' '),pattern_bckg+pattern_border);
              show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp3,ExpStrL('',14,' ')+
                       dummy_str,pattern_bckg+pattern_border);
            end;

        If (epos <> 0) then
          For temp3 := MAX_PATTERN_ROWS downto MAX_PATTERN_ROWS-epos+1 do
            begin
              show_str(03,10+temp3,ExpStrL('',4,' ')+'บ',pattern_bckg+pattern_border);
              show_str(MAX_COLUMNS-8,10+temp3,'บ'+ExpStrL('',4,' '),pattern_bckg+pattern_border);
              show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp3,ExpStrL('',14,' ')+
                       dummy_str,pattern_bckg+pattern_border);
            end;
      end;

  _no_block_tracing := discard_block or
                       (tracing and (pattern_patt <> tracing_block_pattern));

  show_str(17+(MAX_COLUMNS-19) DIV 2,08,byte2hex(pattern_patt),pattern_bckg+pattern_border);
  For temp1 := 1+spos to MAX_PATTERN_ROWS-epos do
    begin
      If tracing and (play_status <> isStopped) then
        begin
          If (temp1 <> MAX_PATTERN_ROWS DIV 2) then _row_bckg := BYTE_NULL
          else begin
                 _row_bckg  := pattern_row_bckg_p;
                 _row_bckg2 := pattern_bckg;
                 _row_fgnd  := pattern_line_p;
               end
        end
      else If NOT ((pattern_patt = current_pattern) and
                   (page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1 = current_line) and
                   (play_status <> isStopped)) then
             _row_bckg := BYTE_NULL
           else begin
                  _row_bckg  := pattern_row_bckg_p;
                  _row_bckg2 := pattern_bckg;
                  _row_fgnd  := pattern_line_p;
                end;

      If NOT ((mark_line <> 0) and mark_lines) then
        begin
          If (temp1 <> MAX_PATTERN_ROWS DIV 2) or (marking and (NOT _no_block_tracing or discard_block)) then
            begin
              If (temp1 <> MAX_PATTERN_ROWS DIV 2) then
                begin
                  If (_row_bckg = BYTE_NULL) then
                    begin
                      _row_bckg  := pattern_bckg;
                      _row_bckg2 := pattern_bckg;
                      _row_fgnd  := pattern_line;
                    end;

                  show_cstr(03,10+temp1,' '+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+' ~บ~',
                            _row_bckg+_row_fgnd,
                            _row_bckg2+pattern_border);
                  show_cstr(MAX_COLUMNS-8,10+temp1,'~บ~ '+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+' ',
                            _row_bckg+_row_fgnd,
                            _row_bckg2+pattern_border);
                end
              else
                begin
                  If (_row_bckg = BYTE_NULL) then
                    begin
                      _row_bckg  := pattern_bckg;
                      _row_bckg2 := pattern_bckg;
                      _row_fgnd  := pattern_border;
                    end;

                  show_cstr(03,10+temp1,#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11+'~บ~',
                            _row_bckg+_row_fgnd,
                            _row_bckg2+pattern_border);
                  show_cstr(MAX_COLUMNS-8,10+temp1,'~บ~'+#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11,
                            _row_bckg+_row_fgnd,
                            _row_bckg2+pattern_border);
                end;
            end
          else begin
                 If (_row_bckg = BYTE_NULL) then
                   begin
                     _row_bckg  := pattern_row_bckg;
                     _row_bckg2 := pattern_bckg;
                     _row_fgnd  := pattern_hi_line;
                   end;

                 show_cstr(03,10+temp1,#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11+'~บ~',
                           _row_bckg+_row_fgnd,
                           _row_bckg2+pattern_border);
                 show_cstr(MAX_COLUMNS-8,10+temp1,'~บ~'+#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11,
                           _row_bckg+_row_fgnd,
                           _row_bckg2+pattern_border);
               end;
        end
      else
        begin
          If (temp1 <> MAX_PATTERN_ROWS DIV 2) or (marking and (NOT _no_block_tracing or discard_block)) then
            If ((page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1 = 0) or
               ((page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1) MOD mark_line = 0)) and
                (mark_line <> 0) then
              begin
                If NOT marking or (marking and NOT discard_block and
                                   _no_block_tracing) then
                  begin
                    If (_row_bckg = BYTE_NULL) then
                      begin
                        _row_bckg  := pattern_row_bckg;
                        _row_bckg2 := pattern_bckg;
                        _row_fgnd  := pattern_hi_line;
                      end;

                    show_cstr(03,10+temp1,' '+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+' ~บ~',
                              _row_bckg+_row_fgnd,
                              _row_bckg2+pattern_border);
                    show_cstr(MAX_COLUMNS-8,10+temp1,'~บ~ '+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+' ',
                              _row_bckg+_row_fgnd,
                              _row_bckg2+pattern_border);
                  end
                else
                  If (temp1 <> MAX_PATTERN_ROWS DIV 2) then
                    begin
                      If (_row_bckg = BYTE_NULL) then
                        begin
                          _row_bckg  := pattern_bckg;
                          _row_bckg2 := pattern_bckg;
                          _row_fgnd  := pattern_hi_line;
                        end;

                      show_cstr(03,10+temp1,' '+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+' ~บ~',
                                _row_bckg+_row_fgnd,
                                _row_bckg2+pattern_border);
                      show_cstr(MAX_COLUMNS-8,10+temp1,'~บ~ '+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+' ',
                                _row_bckg+_row_fgnd,
                                _row_bckg2+pattern_border);
                    end
                  else
                    begin
                      If (_row_bckg = BYTE_NULL) then
                        begin
                          _row_bckg  := pattern_bckg;
                          _row_bckg2 := pattern_bckg;
                          _row_fgnd  := pattern_border;
                        end;

                      show_cstr(03,10+temp1,#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11+'~บ~',
                                _row_bckg+_row_fgnd,
                                _row_bckg2+pattern_border);
                      show_cstr(MAX_COLUMNS-8,10+temp1,'~บ~'+#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11,
                                _row_bckg+_row_fgnd,
                                _row_bckg2+pattern_border);
                    end;
              end
            else
              If (temp1 <> MAX_PATTERN_ROWS DIV 2) then
                begin
                  If (_row_bckg = BYTE_NULL) then
                    begin
                      _row_bckg  := pattern_bckg;
                      _row_bckg2 := pattern_bckg;
                      _row_fgnd  := pattern_line;
                    end;

                  show_cstr(03,10+temp1,' '+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+' ~บ~',
                            _row_bckg+_row_fgnd,
                            _row_bckg2+pattern_border);
                  show_cstr(MAX_COLUMNS-8,10+temp1,'~บ~ '+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+' ',
                            _row_bckg+_row_fgnd,
                            _row_bckg2+pattern_border);
                end
              else
                begin
                  If (_row_bckg = BYTE_NULL) then
                    begin
                      _row_bckg  := pattern_bckg;
                      _row_bckg2 := pattern_bckg;
                      _row_fgnd  := pattern_border;
                    end;

                  show_cstr(03,10+temp1,#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11+'~บ~',
                            _row_bckg+_row_fgnd,
                            _row_bckg2+pattern_border);
                  show_cstr(MAX_COLUMNS-8,10+temp1,'~บ~'+#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11,
                            _row_bckg+_row_fgnd,
                            _row_bckg2+pattern_border);
                end
          else
            begin
              If (_row_bckg = BYTE_NULL) then
                begin
                  _row_bckg  := pattern_row_bckg_m;
                  _row_bckg2 := pattern_bckg;
                  _row_fgnd  := pattern_hi_line_m;
                end;

              show_cstr(03,10+temp1,#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11+'~บ~',
                        _row_bckg+_row_fgnd,
                        _row_bckg2+pattern_border);
              show_cstr(MAX_COLUMNS-8,10+temp1,'~บ~'+#$10+byte2hex(page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1)+#$11,
                        _row_bckg+_row_fgnd,
                        _row_bckg2+pattern_border);
            end;
        end;

      For temp2 := chan_pos to chan_pos+MAX_TRACKS-1 do
        begin
          get_chunk(pattern_patt,page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1,temp2,chunk);
          If marking and (
               (NOT tracing and
                is_in_block(temp2,page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1,
                            count_channel(pattern_hpos),page))
             or (NOT discard_block and tracing and
                 NOT _no_block_tracing and
                 is_in_block(temp2,page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1,
                             tracing_block_xend,tracing_block_yend))
             or (discard_block and (temp2 = block_xstart) and
                                   (page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1 = block_ystart))) then
            begin
              If NOT ((chunk.effect_def = 0) and (chunk.effect = 0)) then
                attr := pattern_block_bckg+pattern_cmnd_b
              else attr := pattern_block_bckg+pattern_cmnd0_b;
              If NOT ((chunk.effect_def2 = 0) and (chunk.effect2 = 0)) then
                attr3 := pattern_block_bckg+pattern_cmnd_b
              else attr3 := pattern_block_bckg+pattern_cmnd0_b;

              _set_attr(temp2,chunk,pattern_block_bckg,pattern_fix_note_b,
                                    pattern_note_b,pattern_note0_b,pattern_note_hid_b,
                                    pattern_inst_b,pattern_inst0_b,attr,attr2);
            end
          else If (NOT marking or (marking and NOT discard_block and
                                   _no_block_tracing)) and
                  (temp1 = 1+PRED(MAX_PATTERN_ROWS DIV 2)) then
                 begin
                   If NOT ((mark_line <> 0) and mark_lines) then
                     begin
                       If NOT ((chunk.effect_def = 0) and (chunk.effect = 0)) then
                         attr := pattern_row_bckg+pattern_hi_cmnd
                       else attr := pattern_row_bckg+pattern_hi_cmnd0;
                       If NOT ((chunk.effect_def2 = 0) and (chunk.effect2 = 0)) then
                         attr3 := pattern_row_bckg+pattern_hi_cmnd
                       else attr3 := pattern_row_bckg+pattern_hi_cmnd0;

                       _set_attr(temp2,chunk,pattern_row_bckg,pattern_hi_fx_note,
                                             pattern_hi_note,pattern_hi_note0,pattern_hi_note_h,
                                             pattern_hi_inst,pattern_hi_inst0,attr,attr2);
                     end
                   else
                     begin
                       If NOT ((chunk.effect_def = 0) and (chunk.effect = 0)) then
                         attr := pattern_row_bckg_m+pattern_cmnd_m
                       else attr := pattern_row_bckg_m+pattern_cmnd0_m;
                       If NOT ((chunk.effect_def2 = 0) and (chunk.effect2 = 0)) then
                         attr3 := pattern_row_bckg_m+pattern_cmnd_m
                       else attr3 := pattern_row_bckg_m+pattern_cmnd0_m;

                       _set_attr(temp2,chunk,pattern_row_bckg_m,pattern_fix_note_m,
                                             pattern_note_m,pattern_note0_m,pattern_note_hid_m,
                                             pattern_inst_m,pattern_inst0_m,attr,attr2);
                     end;
                 end
               else If ((page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1 = 0) or
                       ((page+temp1-PRED(MAX_PATTERN_ROWS DIV 2)-1) MOD mark_line = 0)) and
                        (mark_line <> 0) and
                        (NOT marking or (marking and NOT discard_block and
                                         _no_block_tracing)) and
                        mark_lines then
                      begin
                        If NOT ((chunk.effect_def = 0) and (chunk.effect = 0)) then
                          attr := pattern_row_bckg+pattern_hi_cmnd
                        else attr := pattern_row_bckg+pattern_hi_cmnd0;
                        If NOT ((chunk.effect_def2 = 0) and (chunk.effect2 = 0)) then
                          attr3 := pattern_row_bckg+pattern_hi_cmnd
                        else attr3 := pattern_row_bckg+pattern_hi_cmnd0;

                       _set_attr(temp2,chunk,pattern_row_bckg,pattern_hi_fx_note,
                                             pattern_hi_note,pattern_hi_note0,pattern_hi_note_h,
                                             pattern_hi_inst,pattern_hi_inst0,attr,attr2);
                      end
                    else
                      begin
                        If NOT ((chunk.effect_def = 0) and (chunk.effect = 0)) then
                          begin
                            If NOT highlight_controls or
                               NOT ((chunk.effect_def in [ef_PositionJump,
                                                          ef_PatternBreak,
                                                          ef_SetSpeed,
                                                          ef_SetTempo]) or
                                    ((chunk.effect_def = ef_Extended) and
                                     (chunk.effect DIV 16 in [ef_ex_PatternLoop,
                                                              ef_ex_PatternLoopRec]))) then
                              attr := pattern_bckg+pattern_cmnd
                            else attr := pattern_bckg+pattern_cmnd_ctrl
                          end
                        else attr := pattern_bckg+pattern_cmnd0;

                        If NOT ((chunk.effect_def2 = 0) and (chunk.effect2 = 0)) then
                          begin
                            If NOT highlight_controls or
                               NOT ((chunk.effect_def2 in [ef_PositionJump,
                                                           ef_PatternBreak,
                                                           ef_SetSpeed,
                                                           ef_SetTempo]) or
                                    ((chunk.effect_def2 = ef_Extended) and
                                     (chunk.effect2 DIV 16 in [ef_ex_PatternLoop,
                                                               ef_ex_PatternLoopRec]))) then
                              attr3 := pattern_bckg+pattern_cmnd
                            else attr3 := pattern_bckg+pattern_cmnd_ctrl
                          end
                        else attr3 := pattern_bckg+pattern_cmnd0;

                       _set_attr(temp2,chunk,pattern_bckg,pattern_fix_note,
                                             pattern_note,pattern_note0,pattern_note_hid,
                                             pattern_inst,pattern_inst0,attr,attr2);
                      end;

          dummy_atr := attr3 AND $0f0+pattern_border;
          If (temp2-PRED(chan_pos) <> MAX_TRACKS) and
             (NOT (marking and (temp2 >= block_x1)) or
             (marking and _no_block_tracing)) then
            begin
              dummy_str := 'ณ';
              If marking and discard_block then
                dummy_atr := pattern_bckg+pattern_border;
            end
          else If marking and (temp2-PRED(chan_pos) <> MAX_TRACKS) and
                  NOT _no_block_tracing then
                 begin
                   dummy_str := 'ณ';
                   dummy_atr := pattern_bckg+pattern_border;
                 end
               else dummy_str := '';

          If (temp2 > max(chan_pos+MAX_TRACKS-1,songdata.nm_tracks)) then
            show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,'    ',HI(attr))
          else
            Case pattern_layout of
              0: Case chunk.note of
                   0:         show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,'๚๚๚ ',HI(attr));
                   1..12*8+1: show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,note_layout[chunk.note]+' ',HI(attr));
                   fixed_note_flag+
                   1..
                   fixed_note_flag+
                   12*8+1: show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,note_layout[chunk.note-fixed_note_flag]+' ',HI(attr));
                   BYTE_NULL:      show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,'þþþ ',HI(attr));
                 end;

              1: Case chunk.note of
                   0:         show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,'๚๚๚ ',HI(attr));
                   1..12*8+1: show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,note_layout[chunk.note]+' ',HI(attr));
                   fixed_note_flag+
                   1..
                   fixed_note_flag+
                   12*8+1: show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,note_layout[chunk.note-fixed_note_flag]+' ',HI(attr));
                   BYTE_NULL:   show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,'อออ ',HI(attr));
                 end;

              2: Case chunk.note of
                   0:         show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,'๚๚๚ ',HI(attr));
                   1..12*8+1: show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,note_layout[chunk.note]+' ',HI(attr));
                   fixed_note_flag+
                   1..
                   fixed_note_flag+
                   12*8+1: show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,note_layout[chunk.note-fixed_note_flag]+' ',HI(attr));
                   BYTE_NULL:      show_str(08+pos3[(temp2-PRED(chan_pos))*4-3],10+temp1,'^^๚ ',HI(attr));
                 end;
            end;

          If (temp2 > max(chan_pos+MAX_TRACKS-1,songdata.nm_tracks)) then
            begin
              show_str(08+pos3[(temp2-PRED(chan_pos))*4-2],10+temp1,'   ',attr2);
              show_str(08+pos3[(temp2-PRED(chan_pos))*4-1],10+temp1,'    ',LO(attr));
              show_cstr(08+pos3[(temp2-PRED(chan_pos))*4], 10+temp1,'   '+
                        '~'+dummy_str+'~',attr3,dummy_atr);
            end
          else
            Case pattern_layout of
              0: begin
                   If (chunk.instr_def = 0) then
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-2],10+temp1,'๙๙ ',attr2)
                   else
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-2],10+temp1,
                              ExpStrL(Num2str(chunk.instr_def,16),2,'๙')+' ',attr2);

                   If (chunk.effect_def = 0) and (chunk.effect = 0) then
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-1],10+temp1,'๚๚๚ ',LO(attr))
                   else
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-1],10+temp1,
                              fx_digits[chunk.effect_def]+byte2hex(chunk.effect)+' ',LO(attr));

                   If (chunk.effect_def2 = 0) and (chunk.effect2 = 0) then
                     show_cstr(08+pos3[(temp2-PRED(chan_pos))*4],10+temp1,'๚๚๚'+
                               '~'+dummy_str+'~',attr3,dummy_atr)
                   else
                     show_cstr(08+pos3[(temp2-PRED(chan_pos))*4],10+temp1,
                               fx_digits[chunk.effect_def2]+byte2hex(chunk.effect2)+
                               '~'+dummy_str+'~',attr3,dummy_atr);
                 end;

              1: begin
                   If (chunk.instr_def = 0) then
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-2],10+temp1,'๚๚ ',attr2)
                   else
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-2],10+temp1,
                              ExpStrL(Num2str(chunk.instr_def,16),2,'๚')+' ',attr2);

                   If (chunk.effect_def = 0) and (chunk.effect = 0) then
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-1],10+temp1,'๙๙๙ ',LO(attr))
                   else
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-1],10+temp1,
                              fx_digits[chunk.effect_def]+byte2hex(chunk.effect)+' ',LO(attr));

                   If (chunk.effect_def2 = 0) and (chunk.effect2 = 0) then
                     show_cstr(08+pos3[(temp2-PRED(chan_pos))*4],10+temp1,'๙๙๙'+
                               '~'+dummy_str+'~',attr3,dummy_atr)
                   else
                     show_cstr(08+pos3[(temp2-PRED(chan_pos))*4],10+temp1,
                               fx_digits[chunk.effect_def2]+byte2hex(chunk.effect2)+
                               '~'+dummy_str+'~',attr3,dummy_atr);
                 end;

              2: begin
                   If (chunk.instr_def = 0) then
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-2],10+temp1,'๚๚ ',attr2)
                   else
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-2],10+temp1,
                              ExpStrL(Num2str(chunk.instr_def,16),2,'๚')+' ',attr2);

                   If (chunk.effect_def = 0) and (chunk.effect = 0) then
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-1],10+temp1,'๚๙๙ ',LO(attr))
                   else
                     show_str(08+pos3[(temp2-PRED(chan_pos))*4-1],10+temp1,
                              fx_digits[chunk.effect_def]+byte2hex(chunk.effect)+' ',LO(attr));

                   If (chunk.effect_def2 = 0) and (chunk.effect2 = 0) then
                     show_cstr(08+pos3[(temp2-PRED(chan_pos))*4],10+temp1,'๚๙๙'+
                               '~'+dummy_str+'~',attr3,dummy_atr)
                   else
                     show_cstr(08+pos3[(temp2-PRED(chan_pos))*4],10+temp1,
                               fx_digits[chunk.effect_def2]+byte2hex(chunk.effect2)+
                               '~'+dummy_str+'~',attr3,dummy_atr);
                 end;

            end;
        end;
    end;
  
  chanrec_indicator_attr[TRUE] := main_behavior SHL 4 AND $0f0;
  If (play_status = isPlaying) then
    chanrec_indicator_attr[FALSE] := pattern_bckg+pattern_border
  else chanrec_indicator_attr[FALSE] := main_behavior SHL 4 AND $0f0;
  
  STATUS_LINE_refresh;
  For temp1 := chan_pos to chan_pos+MAX_TRACKS-1 do
    begin
      If NOT is_4op_chan(temp1) then
        temps := '~ ~'+ExpStrR(Num2str(temp1,10),2,' ')+'~ ~'
      else Case temp1 of
             1,3,5,10,12,
             14: temps := '~๕~'+ExpStrR(Num2str(temp1,10),2,' ')+'~ ~';
             2,4,6,11,13,
             15: temps := '~๔~'+ExpStrR(Num2str(temp1,10),2,' ')+'~ ~';
           end;

      If opl3_channel_recording_mode and opl3_record_channel[temp1] then
        chan_attr := chanrec_indicator_attr[_generic_blink_event_flag]
      else chan_attr := pattern_bckg+pattern_border;

      show_cstr(08+(temp1-PRED(chan_pos)-1)*15,09,temps,
                chan_attr,
                pattern_bckg+pattern_4op_indic);
    end;

  If scroll_bars then
    begin
      scroll_pos2 := vscroll_bar(MAX_COLUMNS-2,08,MAX_PATTERN_ROWS+4,PRED1(songdata.patt_len),
                                 page,scroll_pos2,
                                 scrollbar_bckg+scrollbar_text,
                                 scrollbar_bckg+scrollbar_mark);
      scroll_pos3 := hscroll_bar(MAX_COLUMNS-17,MAX_PATTERN_ROWS+12,16,PRED1(songdata.nm_tracks),PRED(count_channel(pattern_hpos)),
                                 scroll_pos3,
                                 scrollbar_bckg+scrollbar_text,
                                 scrollbar_bckg+scrollbar_mark);
      If (pattern_patt <= PRED(max_patterns)) then
        scroll_pos4 := vscroll_bar(MAX_COLUMNS-1,08,MAX_PATTERN_ROWS+4,PRED(max_patterns),
                                   pattern_patt,scroll_pos4,
                                   scrollbar_bckg+scrollbar_text,
                                   scrollbar_bckg+scrollbar_2nd_mark)
      else
        scroll_pos4 := vscroll_bar(MAX_COLUMNS-1,08,MAX_PATTERN_ROWS+4,1,1,BYTE_NULL,
                                   scrollbar_bckg+scrollbar_text,
                                   scrollbar_bckg+scrollbar_mark);
    end
  else
    begin
      scroll_pos2 := vscroll_bar(MAX_COLUMNS-2,08,MAX_PATTERN_ROWS+4,1,1,BYTE_NULL,
                                 scrollbar_bckg+scrollbar_text,
                                 scrollbar_bckg+scrollbar_mark);
      scroll_pos3 := hscroll_bar(MAX_COLUMNS-17,MAX_PATTERN_ROWS+12,16,1,1,BYTE_NULL,
                                 scrollbar_bckg+scrollbar_text,
                                 scrollbar_bckg+scrollbar_mark);
      scroll_pos4 := vscroll_bar(MAX_COLUMNS-1,08,MAX_PATTERN_ROWS+4,1,1,BYTE_NULL,
                                 scrollbar_bckg+scrollbar_text,
                                 scrollbar_bckg+scrollbar_mark);
    end;
end;

var
  old_pattern_patt,old_pattern_page,
  old_pattern_hpos,
  old_block_xstart,old_block_ystart: Byte;
  old_marking: Boolean;

procedure PATTERN_position_preview(pattern,line,channel,mode: Byte);
begin
  _debug_str_ := 'IPATTERN.INC:PATTERN_position_preview';
  If (mode = 0) then
    begin
      old_pattern_patt := pattern_patt;
      old_pattern_page := pattern_page;
      old_pattern_hpos := pattern_hpos;
      old_chan_pos := chan_pos;
      old_block_xstart := block_xstart;
      old_block_ystart := block_ystart;
      old_marking := marking;
    end
  else If (mode = 1) then
         begin
           pattern_patt := pattern;
           pattern_page := line;
           If (channel > chan_pos+MAX_TRACKS-1) then
             While (channel > chan_pos+MAX_TRACKS-1) do Inc(chan_pos)
           else While (channel < chan_pos) do Dec(chan_pos);
           While (channel > chan_pos+MAX_TRACKS-1) and (chan_pos < last_chan_pos) do Inc(chan_pos);
           If (count_channel(pattern_hpos) < channel) then
             While (count_channel(pattern_hpos) <> channel) do Inc(pattern_hpos)
           else While (count_channel(pattern_hpos) <> channel) do Dec(pattern_hpos);
           While (count_pos(pattern_hpos) <> 0) do Dec(pattern_hpos);
           block_xstart := count_channel(pattern_hpos);
           block_ystart := line;
           marking := TRUE;
           discard_block := TRUE;
           PATTERN_ORDER_page_refresh(pattord_page);
           PATTERN_page_refresh(pattern_page);
         end
       else If (mode = BYTE_NULL) then
              begin
                pattern_patt := old_pattern_patt;
                pattern_page := old_pattern_page;
                pattern_hpos := old_pattern_hpos;
                chan_pos := old_chan_pos;
                block_xstart := old_block_xstart;
                block_ystart := old_block_ystart;
                marking := old_marking;
                discard_block := FALSE;
                PATTERN_ORDER_page_refresh(pattord_page);
                PATTERN_page_refresh(pattern_page);
              end;
end;

var
  last_order,last_pattern,
  last_line: Byte;

procedure update_trace;
begin
  _debug_str_ := 'IPATTERN.INC:update_trace';
  space_pressed := scankey($39); { SPACE }
  If (play_status = isPlaying) then
    If (last_order <> current_order) or
       (last_pattern <> current_pattern) or
       (last_line <> current_line) then
      begin
        last_order := current_order;
        last_pattern := songdata.pattern_order[current_order];
        last_line := current_line;

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

        PATTERN_ORDER_page_refresh(pattord_page);
        PATTERN_page_refresh(pattern_page);
      end;
end;

procedure update_without_trace;
begin
  If _debug_ then
    _debug_str_ := 'IPATTERN.INC:update_without_trace';
  If (play_status = isPlaying) then
    If (last_order <> current_order) or
       (last_pattern <> current_pattern) or
       (last_line <> current_line) then
      begin
        last_order := current_order;
        last_pattern := songdata.pattern_order[current_order];
        last_line := current_line;

        PATTERN_ORDER_page_refresh(pattord_page);
        PATTERN_page_refresh(pattern_page);
      end;
end;

function PATTERN_trace: Word;

var
  old_pattord_page,old_pattord_hpos,old_pattord_vpos: Byte;
  old_pattern_patt,old_pattern_page,old_pattern_hpos: Byte;
  nope: Boolean;
  temp,temp2,fkey2: Word;
  temps: String;

procedure pause_debugging;
begin
  If debugging then
    begin
      debugging := FALSE;
      replay_forbidden := TRUE;
      play_status := isPaused;
      PATTERN_ORDER_page_refresh(pattord_page);
      PATTERN_page_refresh(pattern_page);
    end;
end;

label _end;

begin
  _debug_str_ := 'IPATTERN.INC:PATTERN_trace';
  If (play_status = isStopped) then EXIT;
  last_order := BYTE_NULL;
  last_pattern := BYTE_NULL;
  last_line := BYTE_NULL;

  HideCursor;
  old_pattord_page := pattord_page;
  old_pattord_hpos := pattord_hpos;
  old_pattord_vpos := pattord_vpos;
  old_pattern_patt := pattern_patt;
  old_pattern_page := pattern_page;
  old_pattern_hpos := pattern_hpos;

  If marking then
    begin
      tracing_block_pattern := pattern_patt;
      tracing_block_xend := count_channel(pattern_hpos);
      tracing_block_yend := pattern_page;
    end;

  tracing := TRUE;
  trace_update_proc := update_trace;

  Repeat
    nope := FALSE;
    update_trace;
    If (scankey(SC_LCTRL) or scankey(SC_RCTRL)) { CTRL } and
       (scankey(SC_LALT) or scankey(SC_RALT)) { ALT } then
      begin
        DEBUG_INFO;
        PATTERN_ORDER_page_refresh(pattord_page);
        PATTERN_page_refresh(pattern_page);
      end;

    If keypressed then fkey2 := getkey
    else If NOT (seconds_counter >= ssaver_time) then GOTO _end //CONTINUE
         else begin
                screen_saver;
                GOTO _end; //CONTINUE;
              end;

    Case fkey2 of
      kCtLbr: If NOT shift_pressed then
                If (_4op_to_test = 0) then
                  If (current_inst > 1) then
                    begin
                      Dec(current_inst);
                      instrum_page := current_inst;
                      keyboard_reset_buffer;
                    end;

      kCtRbr: If NOT shift_pressed then
                If (_4op_to_test = 0) then
                  If (current_inst < 255) then
                    begin
                      Inc(current_inst);
                      instrum_page := current_inst;
                      keyboard_reset_buffer;
                    end;

      kNPastr: If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
                 begin
                   For temp := 1 to songdata.nm_tracks do
                     begin
                       channel_flag[temp] := NOT channel_flag[temp];
                       If NOT channel_flag[temp] then reset_chan_data(temp);
                     end;
                 end;

      kAltL:   begin
                 pause_debugging;
                 LINE_MARKING_SETUP;
                 PATTERN_ORDER_page_refresh(pattord_page);
                 PATTERN_page_refresh(pattern_page);
               end;

      kAltM:   If (mark_line <> 0) then
                 begin
                   mark_lines := NOT mark_lines;
                   PATTERN_ORDER_page_refresh(pattord_page);
                   PATTERN_page_refresh(pattern_page);
                 end;

      kAltS:   If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
                 begin
                   For temp := 1 to songdata.nm_tracks do
                     channel_flag[temp] := FALSE;
                   For temp := 1 to songdata.nm_tracks do
                     If (temp = count_channel(pattern_hpos)) then
                       begin
                         channel_flag[temp] := TRUE;
                         If is_4op_chan(temp) then
                           If (temp in [1,3,5,10,12,14]) then channel_flag[SUCC(temp)] := TRUE
                           else channel_flag[PRED(temp)] := TRUE;
                       end;
                   For temp := 1 to songdata.nm_tracks do
                     If NOT channel_flag[temp] then reset_chan_data(temp);
                 end;

      kAltR:   If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
                 FillChar(channel_flag,songdata.nm_tracks,BYTE(TRUE));
      kAlt1..
      kAlt0:   If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
                 If (fkey2 <> kAlt0) then
                   begin
                     If (HI(fkey2)-$77 <= songdata.nm_tracks) then
                       begin
                         channel_flag[HI(fkey2)-$77] := NOT channel_flag[HI(fkey2)-$77];
                         If NOT channel_flag[HI(fkey2)-$77] then reset_chan_data(HI(fkey2)-$77);
                         If is_4op_chan(HI(fkey2)-$77) then
                           If (HI(fkey2)-$77 in [1,3,5]) then
                             begin
                               channel_flag[SUCC(HI(fkey2)-$77)] := channel_flag[HI(fkey2)-$77];
                               If NOT channel_flag[SUCC(HI(fkey2)-$77)] then reset_chan_data(SUCC(HI(fkey2)-$77));
                             end
                           else If (HI(fkey2)-$77 in [2,4,6]) then
                                  begin
                                    channel_flag[PRED(HI(fkey2)-$77)] := channel_flag[HI(fkey2)-$77];
                                    If NOT channel_flag[PRED(HI(fkey2)-$77)] then reset_chan_data(PRED(HI(fkey2)-$77));
                                  end;  
                       end;
                   end
                 else If (songdata.nm_tracks = 10) then
                        begin
                          channel_flag[10] := NOT channel_flag[10];
                          If NOT channel_flag[10] then reset_chan_data(10);
                          If is_4op_chan(10) then
                           begin
                             channel_flag[11] := channel_flag[10];
                             If NOT channel_flag[11] then reset_chan_data(11);
                           end;  
                        end  
                      else begin
                             If NOT percussion_mode then temps := '1~0~$1~1~$1~2~$1~3~$1~4~$1~5~$1~6~$1~7~$1~8~$1~9~$2~0~$'
                             else temps := '1~0~$1~1~$1~2~$1~3~$1~4~$1~5~$16 ~B~D$17 ~S~D$18 ~T~T$19 T~C~$20 ~H~H$';
                             temps := FlipStr(temps);
                             For temp := 10 to 20 do
                               If (temp > songdata.nm_tracks) then
                                 begin
                                   Delete(temps,Pos('~',temps),1);
                                   Delete(temps,Pos('~',temps),1);
                                 end;
                             temps := FlipStr(temps);
                             If (Pos('~',temps) <> 0) then
                               begin
                                 chpos := Dialog('USE CURSOR KEYS OR DiRECTLY PRESS HOTKEY '+
                                                 'TO TOGGLE TRACK ON/OFF$',
                                                 temps,
                                                 ' TRACK ON/OFF ',chpos);
                                 If (dl_environment.keystroke <> kESC) then
                                   begin
                                     channel_flag[9+chpos] := NOT channel_flag[9+chpos];
                                     If NOT channel_flag[9+chpos] then reset_chan_data(9+chpos);
                                     If is_4op_chan(9+chpos) then
                                       If (9+chpos in [10,12,14]) then
                                         begin
                                           channel_flag[SUCC(9+chpos)] := channel_flag[9+chpos];
                                           If NOT channel_flag[SUCC(9+chpos)] then reset_chan_data(SUCC(9+chpos));
                                         end  
                                       else If (9+chpos in [11,13,15]) then
                                              begin
                                                channel_flag[PRED(9+chpos)] := channel_flag[9+chpos];
                                                If NOT channel_flag[PRED(9+chpos)] then reset_chan_data(PRED(9+chpos));
                                              end;
                                   end;
                               end;
                           end;
      kUp,
      kCtLEFT: If NOT debugging and (play_status = isPlaying) then
                 rewind := TRUE;
      kDown,
      kCtRGHT: If NOT debugging and (play_status = isPlaying) then
                 fast_forward := TRUE;

      kLEFT,
      kShTAB:  If (chan_pos > 1) then
                 begin
                   Dec(chan_pos);
                   PATTERN_ORDER_page_refresh(pattord_page);
                   PATTERN_page_refresh(pattern_page);
                 end
               else If (pattern_hpos > PATEDIT_lastpos DIV MAX_TRACKS) then
                      begin
                        Dec(pattern_hpos,PATEDIT_lastpos DIV MAX_TRACKS);
                        PATTERN_ORDER_page_refresh(pattord_page);
                        PATTERN_page_refresh(pattern_page);
                      end;
      kRIGHT,
      kTAB:    If (chan_pos < last_chan_pos) then
                 begin
                   Inc(chan_pos);
                   PATTERN_ORDER_page_refresh(pattord_page);
                   PATTERN_page_refresh(pattern_page);
                 end
               else If (pattern_hpos <= last_hpos-PATEDIT_lastpos DIV MAX_TRACKS) then
                      begin
                        Inc(pattern_hpos,PATEDIT_lastpos DIV MAX_TRACKS);
                        PATTERN_ORDER_page_refresh(pattord_page);
                        PATTERN_page_refresh(pattern_page);
                      end;

      kNPmins: If NOT play_single_patt then
                 begin
                   temp := current_order;
                   temp2 := current_line;
                   While (temp > 0) and
                         NOT (songdata.pattern_order[temp-1] < $80) do
                     begin
                       Dec(temp);
                       // keyboard_reset_buffer;
                     end;

                   If (temp > 0) then
                     begin
                       Dec(temp);
                       If (songdata.pattern_order[temp] < $80) then
                         begin
                           fade_out_playback(FALSE);
                           If shift_pressed then calibrate_player(temp,temp2,TRUE,FALSE)
                           else calibrate_player(temp,0,TRUE,FALSE);
                         end;
                     end;
                 end;

      kNPplus: If NOT play_single_patt then
                 begin
                   temp := current_order;
                   temp2 := current_line;
                   While (temp < $7f) and
                         (songdata.pattern_order[SUCC(temp)] > $80) do
                     begin
                       Inc(temp);
                       // keyboard_reset_buffer;
                     end;

                   If (temp < $7f) then
                     begin
                       Inc(temp);
                       If (songdata.pattern_order[temp] < $80) then
                         begin
                           fade_out_playback(FALSE);
                           If shift_pressed then calibrate_player(temp,temp2,TRUE,FALSE)
                           else calibrate_player(temp,0,TRUE,FALSE);
                         end;
                     end;
                 end;

      kCtENTR: If play_single_patt then
                 begin
                   current_line := 0;
                   PATTERN_ORDER_page_refresh(0);
                   PATTERN_page_refresh(0);
                 end
               else
                 begin
                   no_status_refresh := TRUE;
                   fade_out_playback(FALSE);
                   If (current_order < $7f) and
                      (play_status <> isStopped) then
                     If (songdata.pattern_order[SUCC(current_order)] < $80) then
                       calibrate_player(SUCC(current_order),0,FALSE,FALSE)
                     else If (calc_following_order(SUCC(current_order)) <> -1) then
                            calibrate_player(calc_following_order(SUCC(current_order)),0,FALSE,FALSE)
                          else
                   else If (calc_following_order(0) <> -1) then
                          calibrate_player(calc_following_order(0),0,FALSE,FALSE);
                   no_status_refresh := FALSE;
                 end;

      kCtrlT:  begin
                 pause_debugging;
                 TRANSPOSE;
               end;

      kCtrlR:  begin
                 pause_debugging;
                 REMAP;
               end;

      kCtrlD:  begin
                 pause_debugging;
                 DEBUG_INFO;
               end;

      kCtrlO:  begin
                 pause_debugging;
                 OCTAVE_CONTROL;
               end;

      kCtrlP:  begin
                 pause_debugging;
                 PATTERN_LIST(pattern_list__page);
               end;

      kCtrlF:  begin
                 pause_debugging;
                 SONG_VARIABLES;
               end;

      kCtrlH:  begin
                 pause_debugging;
                 REPLACE;
               end;

      kCtrlI:  begin
                 pause_debugging;
                 INSTRUMENT_CONTROL;
               end;

      kCtrlQ:  begin
                 pause_debugging;
                 MACRO_EDITOR(current_inst,FALSE);
               end;

      kCtrlE:  begin
                 pause_debugging;
                 MACRO_EDITOR(current_inst,TRUE);
               end;

      kCtrlM:  begin
                 pause_debugging;
                 MACRO_BROWSER(TRUE,TRUE);
               end;

      kF1:     begin
                 pause_debugging;
                 If (sdl_opl3_emulator = 1) and ((play_status = isPlaying) or opl3_channel_recording_mode) then HELP('wav_recorder')
                 else HELP('general');
               end;
      kF2,
      kShF2,
      kCtrlS:  begin
                 pause_debugging;
                 If (fkey2 = kShF2) then quick_cmd := TRUE;
                 FILE_save('a2m');
                 quick_cmd := FALSE;
               end;

      kCtrlF2: begin
                 pause_debugging;
                 FILE_save('a2t');
               end;
      kF3,
      kShF3,
      kCtrlL:  begin
                 pause_debugging;
                 If (fkey2 = kShF3) then quick_cmd := TRUE;
                 FILE_open('*.a2m$*.a2t$*.a2p$*.amd$*.cff$*.dfm$*.fmk$*.hsc$*.mtk$*.rad$'+
                           '*.s3m$*.sat$*.sa2$*.xms$',FALSE);
                 quick_cmd := FALSE;
               end;

      kF4,
      kCtrlA:  NUKE;

      kSPACE:  If (play_status = isPaused) then
                 begin
                   debugging := TRUE;
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                   PATTERN_ORDER_page_refresh(pattord_page);
                   PATTERN_page_refresh(pattern_page);
                 end;

      kF10:    begin
                 QUIT_request;
                 If (fkey = kESC) then
                   begin
                     fkey2 := kF10;
                     nope := TRUE;
                   end;
               end;
      kENTER,
      kESC:    begin
                 nope := TRUE;
                 debugging := FALSE;
                 If (fkey2 = kENTER) then
                   begin
                      replay_forbidden := TRUE;
                      play_status := isPaused;
                      update_trace;
                    end;
               end;
      kF5,
      kAltF5,
      kShF5:   If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                 end
               else
                 Case play_status of
                   isPlaying: begin
                                debugging := FALSE;
                                If (NOT nosync_by_default and (fkey2 = kAltF5)) or
                                   (nosync_by_default and (fkey2 = kF5)) then
                                  no_sync_playing := TRUE;
                              end;

                   isPaused:  begin
                                debugging := FALSE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;
                                If (NOT nosync_by_default and (fkey2 = kAltF5)) or
                                   (nosync_by_default and (fkey2 = kF5)) then
                                  no_sync_playing := TRUE;
                              end;
                 end;

      kF6:     Case play_status of
                 isPlaying: begin
                              If NOT debugging then
                                begin
                                  replay_forbidden := TRUE;
                                  play_status := isPaused;
                                end;
                              debugging := FALSE;
                            end;

                 isPaused:  begin
                              debugging := FALSE;
                              replay_forbidden := FALSE;
                              play_status := isPlaying;
                            end;
               end;

      kShF6:   begin
                 debugging := TRUE;
                 replay_forbidden := FALSE;
                 play_status := isPlaying;
                 PATTERN_ORDER_page_refresh(pattord_page);
                 PATTERN_page_refresh(pattern_page);
               end;

      kF7:     If (play_status <> isStopped) then
                 begin
                   fade_out_playback(FALSE);
                   debugging := FALSE;
                   stop_playing;
                   nope := TRUE;
                   FillChar(ai_table,SizeOf(ai_table),0);
                 end;
      kF8,
      kAltF8,
      kShF8:   If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                 end
               else
                 Case play_status of
                   isPlaying: begin
                                debugging := FALSE;
                                repeat_pattern := FALSE;
                                If (NOT nosync_by_default and (fkey2 = kAltF8)) or
                                   (nosync_by_default and (fkey2 = kF8)) then
                                  no_sync_playing := TRUE;
                              end;

                   isPaused:  begin
                                debugging := FALSE;
                                repeat_pattern := FALSE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;
                                If (NOT nosync_by_default and (fkey2 = kAltF8)) or
                                   (nosync_by_default and (fkey2 = kF8)) then
                                  no_sync_playing := TRUE;
                              end;
                 end;
      kF9,
      kAltF9,
      kShF9:   If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                 end
               else
                 Case play_status of
                   isPlaying: begin
                                debugging := FALSE;
                                repeat_pattern := TRUE;
                                If (NOT nosync_by_default and (fkey2 = kAltF9)) or
                                   (nosync_by_default and (fkey2 = kF8)) then
                                  no_sync_playing := TRUE;
                              end;

                   isPaused:  begin
                                debugging := FALSE;
                                repeat_pattern := TRUE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;
                                If (NOT nosync_by_default and (fkey2 = kAltF9)) or
                                   (nosync_by_default and (fkey2 = kF9)) then
                                  no_sync_playing := TRUE;
                              end;
                 end;
    end;
_end:
    emulate_screen;
    // keyboard_reset_buffer;
  until (nope or (play_status = isStopped)) or _force_program_quit;

  PATTERN_trace := fkey2;
  If (fkey2 = kF10) or _force_program_quit then EXIT;
  trace_update_proc := NIL;
  ThinCursor;
  tracing := FALSE;
  If nope and (fkey2 <> kENTER) then
    begin
      pattord_page := old_pattord_page;
      pattord_hpos := old_pattord_hpos;
      pattord_vpos := old_pattord_vpos;
      pattern_patt := old_pattern_patt;
      pattern_page := old_pattern_page;
      pattern_hpos := old_pattern_hpos;
    end;

  debugging := FALSE;
  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(pattern_page);
end;

procedure PATTERN_edit(var pattern,page,hpos: Byte);

var
  temp1,temp2,temp3,fkey_X: Word;
  temp: Byte;
  tstr,temps: String;
  nope: Boolean;
  chunk,chunk2: tCHUNK;
  old_order,old_pattern,old_line: Byte;
  old_speed,old_tempo: Byte;
  flag: Boolean;

function correct_range(fxdef: Byte; var fxdata: Byte): Boolean;

var
  result: Boolean;

begin
  If _debug_ then
    _debug_str_ := 'IPATTERN.INC:PATTERN_edit:correct_range';
  result := FALSE;
  Case fxdef of
    ef_Arpeggio,
    ef_FSlideUp,
    ef_FSlideDown,
    ef_FSlideUpFine,
    ef_FSlideDownFine,
    ef_FSlideUpVSlide,
    ef_FSlUpVSlF,
    ef_FSlideDownVSlide,
    ef_FSlDownVSlF,
    ef_FSlUpFineVSlide,
    ef_FSlUpFineVSlF,
    ef_FSlDownFineVSlide,
    ef_FSlDownFineVSlF,
    ef_TonePortamento,
    ef_TPortamVolSlide,
    ef_TPortamVSlideFine,
    ef_Vibrato,
    ef_VibratoVolSlide,
    ef_VibratoVSlideFine,
    ef_VolSlide,
    ef_VolSlideFine,
    ef_ArpggVSlide,
    ef_ArpggVSlideFine,
    ef_Tremolo,
    ef_Tremor,
    ef_ExtraFineVibrato,
    ef_ExtraFineTremolo,
    ef_SwapArpeggio,
    ef_SwapVibrato,
    ef_SetCustomSpeedTab: result := TRUE;
    ef_SetSpeed,
    ef_SetTempo,
    ef_ExtraFineArpeggio,
    ef_RetrigNote,
    ef_MultiRetrigNote:   If (fxdata in [1..255]) then result := TRUE
                          else If (command_typing <> 0) then
                                 begin
                                   If (fxdef <> ef_MultiRetrigNote) then fxdata := 1
                                   else fxdata := $10;
                                   result := TRUE;
                                 end;
    ef_SetCarrierVol,
    ef_SetModulatorVol,
    ef_SetInsVolume,
    ef_ForceInsVolume,
    ef_SetGlobalVolume:   If (fxdata in [0..63]) then result := TRUE
                          else If (command_typing <> 0) then
                                 begin
                                   fxdata := 0;
                                   result := TRUE;
                                 end;

    ef_PatternBreak:      result := TRUE;
    ef_PositionJump:      If (fxdata in [0..127]) then result := TRUE
                          else If (command_typing <> 0) then
                                 begin
                                   fxdata := 0;
                                   result := TRUE;
                                 end;

    ef_SetWaveform:       If (fxdata DIV 16 in [0..7,$0f]) and
                             (fxdata MOD 16 in [0..7,$0f]) then result := TRUE
                          else If (command_typing <> 0) then
                                 begin
                                   If (fxdata DIV 16 in [0..7,$0f]) then fxdata := fxdata AND $f0
                                   else If (fxdata MOD 16 in [0..7,$0f]) then fxdata := fxdata AND $0f
                                        else fxdata := 0;
                                   result := TRUE;
                                 end;

    ef_Extended:          If (fxdata in [$00..$01,$10..$11,
                                         $20..$2f,$30..$3f,
                                         $40..$4f,$50..$5f,
                                         $60..$6f,$70..$7f,
                                         $80..$8f,$90..$9f,
                                         $a0..$a7,$b0..$b2,
                                         $c0..$cf,$d0..$df,
                                         $e0..$e1,$f0..$ff]) then result := TRUE
                          else If (command_typing <> 0) then
                                 begin
                                   fxdata := fxdata AND $f0;
                                   result := TRUE;
                                 end;

    ef_Extended2:         If (fxdata in [$01..$0f,$11..$1f,
                                         $21..$2f,$31..$3f,
                                         $41..$4f,$51..$5f,
                                         $61..$6f,$71..$7f,
                                         $81..$8f,$91..$9f,
                                         $a1..$af,$b1..$bf,
                                         $c1..$cf,$d1..$df,
                                         $e1..$ef,$f1..$ff]) then result := TRUE
                          else If (command_typing <> 0) then
                                 begin
                                   fxdata := fxdata AND $f0+1;
                                   result := TRUE;
                                 end;

    ef_Extended3:         If (fxdata in [$00..$01,$10..$1f,
                                         $20..$23,$30..$31,
                                         $40..$41,$50..$51,
                                         $60..$61,$70..$7f,
                                         $80..$83,$90..$91,
                                         $a0..$a1,$b0..$b1,
                                         $c0..$c1]) then result := TRUE
                          else If (command_typing <> 0) then
                                 begin
                                   If (fxdata DIV 16 in [0..$0c]) then fxdata := fxdata AND $f0+1
                                   else fxdata := 1;
                                   result := TRUE;
                                 end;
  end;
  correct_range := result;
end;

procedure copy_object;

var
  temp1,temp2: Word;
  temp3: tCOPY_OBJECT;
  chunk: tCHUNK;

begin
  _debug_str_ := 'IPATTERN.INC:PATTERN_edit:copy_object';
  If clipboard.object_type in [
       objPatternDef,objPatternTable,
       objInstrument,objInstrumentBank,
       objNote,objInstrumentDef,objEffect,objEffect2,
       objLine,objTrack,objPattern,objMarkedBlock] then
    begin
      temp3 := clipboard.object_type;
      FillChar(clipboard,SizeOf(clipboard),0);
      clipboard.object_type := temp3;
    end;

  Case clipboard.object_type of
    objNote,
    objInstrumentDef,
    objEffect,
    objEffect2:
      begin
        get_chunk(pattern,page,count_channel(hpos),chunk);
        clipboard.pattern[1][0] := chunk;
      end;

    objLine:
      For temp1 := 1 to songdata.nm_tracks do
        begin
          get_chunk(pattern,page,temp1,chunk);
          clipboard.pattern[temp1][0] := chunk;
        end;

    objTrack:
      For temp1 := 0 to PRED(songdata.patt_len) do
        begin
          get_chunk(pattern,temp1,count_channel(hpos),chunk);
          clipboard.pattern[1][temp1] := chunk;
        end;

    objPattern:
      begin
        For temp2 := 0 to PRED(songdata.patt_len) do
          For temp1 := 1 to songdata.nm_tracks do
            begin
              get_chunk(pattern,temp2,temp1,chunk);
              clipboard.pattern[temp1][temp2] := chunk;
            end;
        clipboard._string := Copy(songdata.pattern_names[pattern],9,33);
      end;

    objMarkedBlock:
      begin
        clipboard.block_hsize := block_x1-block_x0;
        clipboard.block_vsize := block_y1-block_y0;

        For temp2 := block_y0 to block_y1 do
          For temp1 := block_x0 to block_x1 do
            begin
              get_chunk(pattern,temp2,temp1,chunk);
              clipboard.pattern[SUCC(temp1-block_x0)][temp2-block_y0] := chunk;
            end;
      end;
  end;
end;

procedure paste_object;

var
  temp1,temp2: Word;
  chunk: tCHUNK;

begin
  _debug_str_ := 'IPATTERN.INC:PATTERN_edit:paste_object';
  Case clipboard.object_type of
    objNote:
      begin
        get_chunk(pattern,page,count_channel(hpos),chunk);
        chunk.note := clipboard.pattern[1][0].note;
        put_chunk(pattern,page,count_channel(hpos),chunk);
        If linefeed then
          If page < PRED(songdata.patt_len) then Inc(page)
          else If cycle_pattern then page := 0;
      end;

    objInstrumentDef:
      begin
        get_chunk(pattern,page,count_channel(hpos),chunk);
        chunk.instr_def := clipboard.pattern[1][0].instr_def;
        put_chunk(pattern,page,count_channel(hpos),chunk);
        If linefeed then
          If page < PRED(songdata.patt_len) then Inc(page)
          else If cycle_pattern then page := 0;
      end;

    objEffect:
      begin
        get_chunk(pattern,page,count_channel(hpos),chunk);
        chunk.effect_def := clipboard.pattern[1][0].effect_def;
        chunk.effect := clipboard.pattern[1][0].effect;
        put_chunk(pattern,page,count_channel(hpos),chunk);
        If linefeed then
          If page < PRED(songdata.patt_len) then Inc(page)
          else If cycle_pattern then page := 0;
      end;

    objEffect2:
      begin
        get_chunk(pattern,page,count_channel(hpos),chunk);
        chunk.effect_def2 := clipboard.pattern[1][0].effect_def2;
        chunk.effect2 := clipboard.pattern[1][0].effect2;
        put_chunk(pattern,page,count_channel(hpos),chunk);
        If linefeed then
          If page < PRED(songdata.patt_len) then Inc(page)
          else If cycle_pattern then page := 0;
      end;

    objLine:
      begin
        For temp1 := 1 to songdata.nm_tracks do
          put_chunk(pattern,page,temp1,
                    clipboard.pattern[temp1][0]);
        If linefeed then
          If page < PRED(songdata.patt_len) then Inc(page)
          else If cycle_pattern then page := 0;
      end;

    objTrack:
      For temp1 := 0 to PRED(songdata.patt_len) do
        put_chunk(pattern,temp1,count_channel(hpos),
                  clipboard.pattern[1][temp1]);

    objPattern:
      begin
        For temp2 := 0 to PRED(songdata.patt_len) do
          For temp1 := 1 to songdata.nm_tracks do
            put_chunk(pattern,temp2,temp1,
                      clipboard.pattern[temp1][temp2]);
        songdata.pattern_names[pattern] :=
          Copy(songdata.pattern_names[pattern],1,8)+
          clipboard._string;
      end;

    objMarkedBlock:
      If shift_pressed then
        begin
          For temp2 := page to page+clipboard.block_vsize do
            For temp1 := count_channel(hpos) to count_channel(hpos)+clipboard.block_hsize do
              If (temp1 <= songdata.nm_tracks) and (temp2 <= PRED(songdata.patt_len)) then
                begin
                  get_chunk(pattern,temp2,temp1,chunk);
                  If (command_typing <> 0) then
                    Case count_pos(hpos) of
                      0,
                      1: chunk.note := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].note;
                      2,
                      3: chunk.instr_def := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].instr_def;

                      4,5,
                      6: begin
                           chunk.effect_def := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].effect_def;
                           chunk.effect := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].effect;
                         end;

                      7,8,
                      9: begin
                           chunk.effect_def2 := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].effect_def2;
                           chunk.effect2 := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].effect2;
                         end;
                    end
                  else Case count_pos(hpos) of
                         0: chunk.note := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].note;
                         1: chunk.instr_def := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].instr_def;

                         2: begin
                              chunk.effect_def := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].effect_def;
                              chunk.effect := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].effect;
                            end;

                         3: begin
                              chunk.effect_def2 := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].effect_def2;
                              chunk.effect2 := clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page].effect2;
                            end;
                       end;

                  put_chunk(pattern,temp2,temp1,chunk);
                end;
        end
      else
        For temp2 := page to page+clipboard.block_vsize do
          For temp1 := count_channel(hpos) to count_channel(hpos)+clipboard.block_hsize do
            If (temp1 <= songdata.nm_tracks) and (temp2 <= PRED(songdata.patt_len)) then
              put_chunk(pattern,temp2,temp1,
                        clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page]);
  end;
end;

procedure paste_object_alt(pattern: Byte);

var
  temp1,temp2: Word;
  chunk: tCHUNK;

begin
  _debug_str_ := 'IPATTERN.INC:PATTERN_edit:paste_object_alt';
  Case clipboard.object_type of
    objNote:
      begin
        get_chunk(pattern,page,count_channel(hpos),chunk);
        chunk.note := clipboard.pattern[1][0].note;
        put_chunk(pattern,page,count_channel(hpos),chunk);
      end;

    objInstrumentDef:
      begin
        get_chunk(pattern,page,count_channel(hpos),chunk);
        chunk.instr_def := clipboard.pattern[1][0].instr_def;
        put_chunk(pattern,page,count_channel(hpos),chunk);
      end;

    objEffect:
      begin
        get_chunk(pattern,page,count_channel(hpos),chunk);
        chunk.effect_def := clipboard.pattern[1][0].effect_def;
        chunk.effect := clipboard.pattern[1][0].effect;
        put_chunk(pattern,page,count_channel(hpos),chunk);
      end;

    objEffect2:
      begin
        get_chunk(pattern,page,count_channel(hpos),chunk);
        chunk.effect_def2 := clipboard.pattern[1][0].effect_def2;
        chunk.effect2 := clipboard.pattern[1][0].effect2;
        put_chunk(pattern,page,count_channel(hpos),chunk);
      end;

    objLine:
      begin
        For temp1 := 1 to songdata.nm_tracks do
          put_chunk(pattern,page,temp1,
                    clipboard.pattern[temp1][0]);
      end;

    objTrack:
      For temp1 := 0 to PRED(songdata.patt_len) do
        put_chunk(pattern,temp1,count_channel(hpos),
                  clipboard.pattern[1][temp1]);

    objPattern:
      For temp2 := 0 to PRED(songdata.patt_len) do
        For temp1 := 1 to songdata.nm_tracks do
          put_chunk(pattern,temp2,temp1,
                    clipboard.pattern[temp1][temp2]);

    objMarkedBlock:
      For temp2 := page to page+clipboard.block_vsize do
        For temp1 := count_channel(hpos) to count_channel(hpos)+clipboard.block_hsize do
          If (temp1 <= songdata.nm_tracks) and (temp2 <= PRED(songdata.patt_len)) then
            put_chunk(pattern,temp2,temp1,
                      clipboard.pattern[SUCC(temp1-count_channel(hpos))][temp2-page]);
  end;
end;

function FX(chr: Char): Byte;
begin FX := PRED(Pos(UpCase(chr),fx_digits)); end;

label _end;

begin
  _debug_str_ := 'IPATTERN.INC:PATTERN_edit';
  fkey_X := WORD_NULL;
  Repeat
    If (page > PRED(songdata.patt_len)) then
      page := PRED(songdata.patt_len);

    While NOT ((chan_pos <= last_chan_pos) and (hpos <= last_hpos)) do
      If (hpos > PATEDIT_lastpos DIV MAX_TRACKS) then
        begin
          Dec(hpos,PATEDIT_lastpos DIV MAX_TRACKS);
          If (hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS) > 0) then
            temp := PRED(hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS))
          else temp := PRED(PATEDIT_lastpos DIV MAX_TRACKS);
          Dec(hpos,temp);
        end
      else If (chan_pos > 1) then
             begin
               Dec(chan_pos);
               If (hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS) > 0) then
                 temp := PRED(hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS))
               else temp := PRED(PATEDIT_lastpos DIV MAX_TRACKS);
               Dec(hpos,temp);
             end
           else If cycle_pattern then
                  begin
                    chan_pos := last_chan_pos;
                    hpos := last_hpos;
                  end;

    If (is_4op_chan(count_channel(hpos)) and
       (count_channel(hpos) in [1,3,5,10,12,14])) then
      If (command_typing <> 0) then
        While (count_pos(hpos) < 2) do
          begin
            If (fkey = kLEFT) then
              begin
                If marking then
                  begin
                    If (chan_pos > 1) then Dec(chan_pos);
                                        If (count_pos(hpos) < 2) then
                                           hpos := hpos + 2 - count_pos(hpos);
                  end
                else If hpos > 1 then Dec(hpos)
                     else If (chan_pos > 1) then
                            begin
                              Dec(chan_pos);
                              hpos := PATEDIT_lastpos DIV MAX_TRACKS;
                            end
                          else If cycle_pattern then
                                 begin
                                   chan_pos := last_chan_pos;
                                   hpos := last_hpos;
                                 end
                               else begin
                                      hpos := 3;
                                      BREAK;
                                    end;
              end
            else Inc(hpos);
          end
      else If (count_pos(hpos) = 0) then
             If (fkey = kLEFT) then
               begin
                 If marking then
                   begin
                     If (hpos > PATEDIT_lastpos DIV MAX_TRACKS) then Dec(hpos,PATEDIT_lastpos DIV MAX_TRACKS)
                     else If (chan_pos > 1) then Dec(chan_pos);
                   end
                 else If hpos > 1 then Dec(hpos)
                      else If (chan_pos > 1) then
                             begin
                               Dec(chan_pos);
                               hpos := PATEDIT_lastpos DIV MAX_TRACKS;
                             end
                           else If cycle_pattern then
                                  begin
                                    chan_pos := last_chan_pos;
                                    hpos := last_hpos;
                                  end
               end
             else Inc(hpos);

    PATTERN_ORDER_page_refresh(pattord_page);
    PATTERN_page_refresh(page);

    If (command_typing <> 0) then GotoXY(08+pos4[hpos],11+PRED(MAX_PATTERN_ROWS DIV 2))
    else GotoXY(08+pos3[hpos],11+PRED(MAX_PATTERN_ROWS DIV 2));
    
    If tracing then fkey := PATTERN_trace
    else ThinCursor;

    nope := FALSE;
    If (scankey(SC_LCTRL) or scankey(SC_RCTRL)) { CTRL } and
       (scankey(SC_LALT) or scankey(SC_RALT)) { ALT } then
      begin
        DEBUG_INFO;
        PATTERN_ORDER_page_refresh(pattord_page);
        PATTERN_page_refresh(pattern_page);
      end;

    If keypressed then fkey := getkey
    else If NOT (seconds_counter >= ssaver_time) then GOTO _end //CONTINUE
         else begin
                screen_saver;
                GOTO _end; //CONTINUE;
              end;

    If (fkey <> kAltQ) then quick_mark_type := 0;
    If NOT shift_pressed and
       NOT (marking and ((fkey = kAltC)   or (fkey = kCtrlN)  or
                         (fkey = kCtrlB)  or (fkey = kCtrlD)  or
                         (fkey = kCtrlC)  or (fkey = kCtrlV)  or
                         (fkey = kCtrlX)  or (fkey = kCtPgUP) or
                         (fkey = kCtrlM)  or (fkey = kCtPgDN) or
                         (fkey = kCtrlT)  or (fkey = kCtrlR)  or
                         (fkey = kCtrlH)  or (fkey = kAltQ)   or
                         (fkey = kCtrlD)  or
                         (fkey = kAltM)   or (fkey = kAltL)   or
                         (fkey = kF5)     or (fkey = kAltF5)  or
                         (fkey = kF6)     or (fkey = kAltF6)  or
                         (fkey = kF7)     or (fkey = kF8)     or
                         (fkey = kAltF8)  or (fkey = kCtrlF8) or
                         (fkey = kF9)     or (fkey = kAltF9)  or
                         (fkey = kCtrlF9) or (fkey = kCtLeft) or
                         (fkey = kCtRght) or (fkey = kCtENTR) or
                         (fkey = kAltB)   or (fkey = kAltV)))
    or (shift_pressed and
                    NOT ((fkey = kLEFT)   or (fkey = kRIGHT)  or
                         (fkey = kUP)     or (fkey = kDOWN)   or
                         (fkey = kPgUP)   or (fkey = kPgDOWN) or
                         (fkey = kNPPgUP) or (fkey = kNPPgDN) or
                         (fkey = kHOME)   or (fkey = kEND)    or
                         (fkey = kNPHOME) or (fkey = kNPEND)  or

                     (marking and ((fkey = kAltF5)  or (fkey = kShF5)     or
                                   (fkey = kAltF6)  or (fkey = kShF6)     or
                                   (fkey = kAltF8)  or (fkey = kShF8)     or
                                   (fkey = kCtrlF8) or (fkey = kAltF9)    or
                                   (fkey = kShF9)   or (fkey = kCtrlF9)   or
                                   (fkey = kCtLeft) or (fkey = kCtRght))) or

                         (fkey = kCtENTR)))
    then begin
           If marking and
              NOT (((fkey = kENTER) and shift_pressed) or
                  (fkey = kF1)) then
             begin
               old_block_chan_pos := chan_pos;
               old_block_patt_hpos := hpos;
               old_block_patt_page := page;
               marking := FALSE;
               fkey := WORD_NULL;
               PATTERN_ORDER_page_refresh(pattord_page);
               PATTERN_page_refresh(page);
               If (command_typing <> 0) then GotoXY(08+pos4[hpos],11+PRED(MAX_PATTERN_ROWS DIV 2))
               else GotoXY(08+pos3[hpos],11+PRED(MAX_PATTERN_ROWS DIV 2));
             end;
         end
    else If NOT marking and (fkey <> kPgUP)   and (fkey <> kPgDOWN) and
                            (fkey <> kNPPgUP) and (fkey <> kNPPgDN) and
                            (fkey <> kHOME)   and (fkey <> kEND)    and
                            (fkey <> kNPHOME) and (fkey <> kNPEND)  then
           begin
             old_chan_pos := chan_pos;
             old_hpos := hpos;
             old_page := page;
             marking := TRUE;
             fkey := WORD_NULL;
             block_xstart := count_channel(hpos);
             block_ystart := page;
           end;


    Case fkey of
      kCHlbrk,
      kCtLbr: If NOT shift_pressed then
                If (_4op_to_test = 0) then
                  If (current_inst > 1) then
                    begin
                      Dec(current_inst);
                      instrum_page := current_inst;
                      keyboard_reset_buffer;
                    end;

      kCHrbrk,
      kCtRbr: If NOT shift_pressed then
                If (_4op_to_test = 0) then
                  If (current_inst < 255) then
                    begin
                      Inc(current_inst);
                      instrum_page := current_inst;
                      keyboard_reset_buffer;
                    end;

      kLEFT:   If marking then
                 begin
                   If (hpos > PATEDIT_lastpos DIV MAX_TRACKS) then Dec(hpos,PATEDIT_lastpos DIV MAX_TRACKS)
                   else If (chan_pos > 1) then Dec(chan_pos);
                 end
               else If hpos > 1 then Dec(hpos)
                    else If (chan_pos > 1) then
                           begin
                             Dec(chan_pos);
                             hpos := PATEDIT_lastpos DIV MAX_TRACKS;
                           end
                         else If cycle_pattern then
                                begin
                                  chan_pos := last_chan_pos;
                                  hpos := last_hpos;
                                end;

      kRIGHT:  If marking then
                 begin
                   If (hpos <= last_hpos-PATEDIT_lastpos DIV MAX_TRACKS) then
                     Inc(hpos,PATEDIT_lastpos DIV MAX_TRACKS)
                   else If (chan_pos < last_chan_pos) then Inc(chan_pos);
                 end
               else If hpos < last_hpos then Inc(hpos)
                    else If (chan_pos < last_chan_pos) then
                           begin
                             Inc(chan_pos);
                             hpos := last_hpos-PRED(PATEDIT_lastpos DIV MAX_TRACKS);
                           end
                         else If cycle_pattern then
                                begin
                                  chan_pos := 1;
                                  hpos := 1;
                                end;

      kUP:     If page > 0 then Dec(page)
               else If NOT marking and cycle_pattern then page := PRED(songdata.patt_len);

      kDOWN:   If page < PRED(songdata.patt_len) then Inc(page)
               else If NOT marking and cycle_pattern then page := 0;

      kCHplus,
      kNPplus: If pattern < PRED(max_patterns) then Inc(pattern);
      kCHmins,
      kNPmins: If pattern > 0 then Dec(pattern);

      kPgUP:   If NOT shift_pressed or marking then
                 begin
                   If page > max(16,songdata.patt_len) then Dec(page,max(16,songdata.patt_len))
                   else page := 0;
                 end
               else If pattern > 0 then Dec(pattern);

      kPgDOWN: If NOT shift_pressed or marking then
                 begin
                   If page < PRED(songdata.patt_len)-max(16,songdata.patt_len) then Inc(page,max(16,songdata.patt_len))
                   else page := PRED(songdata.patt_len);
                 end
               else If pattern < PRED(max_patterns) then Inc(pattern);

      kNPPgUP: If NumLock then nope := TRUE
               else
                 If shift_pressed then
                   If NOT marking and (pattern > 0) then Dec(pattern)
                   else If marking then
                          begin
                            If page > max(16,songdata.patt_len) then Dec(page,max(16,songdata.patt_len))
                            else page := 0;
                          end;

      kNPPgDN: If NumLock then nope := TRUE
               else
                 If shift_pressed then
                   If NOT marking and (pattern < PRED(max_patterns)) then Inc(pattern)
                   else If marking then
                          begin
                            If page < PRED(songdata.patt_len)-max(16,songdata.patt_len) then Inc(page,max(16,songdata.patt_len))
                            else page := PRED(songdata.patt_len);
                          end;

      kCtHOME: If pattern > 0 then begin Dec(pattern); page := PRED(songdata.patt_len); end;
      kCtEND:  If pattern < PRED(max_patterns) then begin Inc(pattern); page :=  0; end;

      kHOME:   If NOT shift_pressed or marking then
                 If (page <> 0) then page := 0
                 else begin
                        chan_pos := 1;
                        hpos := 1;
                      end
               else If (chan_pos+hpos-1 <> 1) then
                      begin
                        chan_pos := 1;
                        hpos := 1;
                      end
                    else If (page <> 0) then
                           page := 0
                         else pattern := 0;

      kEND:    If NOT shift_pressed or marking then
                 If (page <> PRED(songdata.patt_len)) then
                   page := PRED(songdata.patt_len)
                 else begin
                        chan_pos := last_chan_pos;
                        hpos := last_hpos;
                      end
               else If (chan_pos+hpos <> last_chan_pos+last_hpos) then
                      begin
                        chan_pos := last_chan_pos;
                        hpos := last_hpos;
                      end
                    else If (page <> PRED(songdata.patt_len)) then
                           page := PRED(songdata.patt_len)
                         else pattern := PRED(max_patterns);

      kNPHOME: If NumLock then nope := TRUE
               else
                 If shift_pressed then
                   If NOT marking then
                     begin
                       If (chan_pos+hpos-1 <> 1) then
                         begin
                           chan_pos := 1;
                           hpos := 1;
                         end
                       else If (page <> 0) then
                              page := 0
                            else pattern := 0;
                     end
                   else If (page <> 0) then page := 0
                        else begin
                               chan_pos := 1;
                               hpos := 1;
                             end;

      kNPEND:  If NumLock then nope := TRUE
               else
                 If shift_pressed then
                   If NOT marking then
                     begin
                       If (chan_pos+hpos <> last_chan_pos+last_hpos) then
                         begin
                           chan_pos := last_chan_pos;
                           hpos := last_hpos;
                         end
                       else If (page <> PRED(songdata.patt_len)) then
                              page := PRED(songdata.patt_len)
                            else pattern := PRED(max_patterns);
                     end
                   else If (page <> PRED(songdata.patt_len)) then
                          page := PRED(songdata.patt_len)
                        else begin
                               chan_pos := last_chan_pos;
                               hpos := last_hpos;
                             end;
      kNPastr: If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
                 begin
                   For temp1 := 1 to songdata.nm_tracks do
                     begin
                       channel_flag[temp1] := NOT channel_flag[temp1];
                       If NOT channel_flag[temp1] then reset_chan_data(temp1);
                     end;
                 end;

      kAltL:   begin
                 LINE_MARKING_SETUP;
                 PATTERN_ORDER_page_refresh(pattord_page);
                 PATTERN_page_refresh(pattern_page);
               end;

      kAltM:   If (mark_line <> 0) then
                 begin
                   mark_lines := NOT mark_lines;
                   PATTERN_ORDER_page_refresh(pattord_page);
                   PATTERN_page_refresh(pattern_page);
                 end;

      kAltS:   If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
                 begin
                   For temp := 1 to songdata.nm_tracks do
                     channel_flag[temp] := FALSE;
                   For temp := 1 to songdata.nm_tracks do
                     If (temp = count_channel(pattern_hpos)) then
                       begin
                         channel_flag[temp] := TRUE;
                         If is_4op_chan(temp) then
                           If (temp in [1,3,5,10,12,14]) then channel_flag[SUCC(temp)] := TRUE
                           else channel_flag[PRED(temp)] := TRUE;
                       end;
                   For temp := 1 to songdata.nm_tracks do
                     If NOT channel_flag[temp] then reset_chan_data(temp);
                 end;

      kAltR:   If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
                 FillChar(channel_flag,songdata.nm_tracks,BYTE(TRUE));
      kAlt1..
      kAlt0:   If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
                 If (fkey <> kAlt0) then
                   begin
                     If (HI(fkey)-$77 <= songdata.nm_tracks) then
                       begin
                         channel_flag[HI(fkey)-$77] := NOT channel_flag[HI(fkey)-$77];
                         If NOT channel_flag[HI(fkey)-$77] then reset_chan_data(HI(fkey)-$77);
                         If is_4op_chan(HI(fkey)-$77) then
                           If (HI(fkey)-$77 in [1,3,5]) then
                             begin
                               channel_flag[SUCC(HI(fkey)-$77)] := channel_flag[HI(fkey)-$77];
                               If NOT channel_flag[SUCC(HI(fkey)-$77)] then reset_chan_data(SUCC(HI(fkey)-$77));
                             end
                           else If (HI(fkey)-$77 in [2,4,6]) then
                                  begin
                                    channel_flag[PRED(HI(fkey)-$77)] := channel_flag[HI(fkey)-$77];
                                    If NOT channel_flag[PRED(HI(fkey)-$77)] then reset_chan_data(PRED(HI(fkey)-$77));
                                  end;  
                       end;
                   end
                 else If (songdata.nm_tracks = 10) then
                        begin
                          channel_flag[10] := NOT channel_flag[10];
                          If NOT channel_flag[10] then reset_chan_data(10);
                          If is_4op_chan(10) then
                           begin
                             channel_flag[11] := channel_flag[10];
                             If NOT channel_flag[11] then reset_chan_data(11);
                           end;  
                        end  
                      else begin
                             If NOT percussion_mode then temps := '1~0~$1~1~$1~2~$1~3~$1~4~$1~5~$1~6~$1~7~$1~8~$1~9~$2~0~$'
                             else temps := '1~0~$1~1~$1~2~$1~3~$1~4~$1~5~$16 ~B~D$17 ~S~D$18 ~T~T$19 T~C~$20 ~H~H$';
                             temps := FlipStr(temps);
                             For temp := 10 to 20 do
                               If (temp > songdata.nm_tracks) then
                                 begin
                                   Delete(temps,Pos('~',temps),1);
                                   Delete(temps,Pos('~',temps),1);
                                 end;
                             temps := FlipStr(temps);
                             If (Pos('~',temps) <> 0) then
                               begin
                                 chpos := Dialog('USE CURSOR KEYS OR DiRECTLY PRESS HOTKEY '+
                                                 'TO TOGGLE TRACK ON/OFF$',
                                                 temps,
                                                 ' TRACK ON/OFF ',chpos);
                                 If (dl_environment.keystroke <> kESC) then
                                   begin
                                     channel_flag[9+chpos] := NOT channel_flag[9+chpos];
                                     If NOT channel_flag[9+chpos] then reset_chan_data(9+chpos);
                                     If is_4op_chan(9+chpos) then
                                       If (9+chpos in [10,12,14]) then
                                         begin
                                           channel_flag[SUCC(9+chpos)] := channel_flag[9+chpos];
                                           If NOT channel_flag[SUCC(9+chpos)] then reset_chan_data(SUCC(9+chpos));
                                         end  
                                       else If (9+chpos in [11,13,15]) then
                                              begin
                                                channel_flag[PRED(9+chpos)] := channel_flag[9+chpos];
                                                If NOT channel_flag[PRED(9+chpos)] then reset_chan_data(PRED(9+chpos));
                                              end;
                                   end;
                               end;
                           end;
                           
      kShTAB:  If (hpos > PATEDIT_lastpos DIV MAX_TRACKS) then
                 begin
                   Dec(hpos,PATEDIT_lastpos DIV MAX_TRACKS);
                   If (hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS) > 0) then
                     temp := PRED(hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS))
                   else temp := PRED(PATEDIT_lastpos DIV MAX_TRACKS);
                   Dec(hpos,temp);
                 end
               else If (chan_pos > 1) then
                      begin
                        Dec(chan_pos);
                        If (hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS) > 0) then
                          temp := PRED(hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS))
                        else temp := PRED(PATEDIT_lastpos DIV MAX_TRACKS);
                        Dec(hpos,temp);
                      end
                    else If cycle_pattern then
                           begin
                             chan_pos := last_chan_pos;
                             hpos := last_hpos;
                           end;

      kTAB:    If (hpos <= last_hpos-PATEDIT_lastpos DIV MAX_TRACKS) then
                 begin
                   Inc(hpos,PATEDIT_lastpos DIV MAX_TRACKS);
                   If (hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS) > 0) then
                     temp := PRED(hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS))
                   else temp := PRED(PATEDIT_lastpos DIV MAX_TRACKS);
                   Dec(hpos,temp);
                 end
               else If (chan_pos < last_chan_pos) then
                      begin
                        Inc(chan_pos);
                        If (hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS) > 0) then
                          temp := PRED(hpos MOD (PATEDIT_lastpos DIV MAX_TRACKS))
                        else temp := PRED(PATEDIT_lastpos DIV MAX_TRACKS);
                        Dec(hpos,temp);
                      end
                    else If cycle_pattern then
                           begin
                             chan_pos := 1;
                             hpos := 1;
                           end;

      kSPACE:  If shift_pressed then
                 begin
                   midiboard := NOT midiboard;
                   fkey := WORD_NULL;
                 end
               else
                 If NOT midiboard then
                   If page < PRED(songdata.patt_len) then Inc(page)
                   else If cycle_pattern then page := 0;

      kINSERT: If NOT shift_pressed then
                 begin
                   For temp1 := PRED(songdata.patt_len)-1 downto page do
                     begin
                       get_chunk(pattern,temp1,count_channel(hpos),chunk);
                       put_chunk(pattern,temp1+1,count_channel(hpos),chunk);
                     end;
                   FillChar(chunk,SizeOf(chunk),0);
                   put_chunk(pattern,page,count_channel(hpos),chunk);
                 end
               else
                 begin
                   For temp1 := PRED(songdata.patt_len)-1 downto page do
                     For temp2 := 1 to songdata.nm_tracks do
                       begin
                         get_chunk(pattern,temp1,temp2,chunk);
                         put_chunk(pattern,temp1+1,temp2,chunk);
                       end;
                   For temp1 := 1 to songdata.nm_tracks do
                     begin
                       FillChar(chunk,SizeOf(chunk),0);
                       put_chunk(pattern,page,temp1,chunk);
                     end;
                 end;

      kDELETE: If NOT shift_pressed then
                 begin
                   For temp1 := page to PRED(songdata.patt_len)-1 do
                     begin
                       get_chunk(pattern,temp1+1,count_channel(hpos),chunk);
                       put_chunk(pattern,temp1,count_channel(hpos),chunk);
                     end;
                   FillChar(chunk,SizeOf(chunk),0);
                   put_chunk(pattern,PRED(songdata.patt_len),count_channel(hpos),chunk);
                 end
               else
                 begin
                   For temp1 := page to PRED(songdata.patt_len)-1 do
                     For temp2 := 1 to songdata.nm_tracks do
                       begin
                         get_chunk(pattern,temp1+1,temp2,chunk);
                         put_chunk(pattern,temp1,temp2,chunk);
                       end;
                   For temp1 := 1 to songdata.nm_tracks do
                     begin
                       FillChar(chunk,SizeOf(chunk),0);
                       put_chunk(pattern,PRED(songdata.patt_len),temp1,chunk);
                     end;
                 end;

      kNPins:  If NumLock then nope := TRUE
               else
                 If shift_pressed then
                   begin
                     For temp1 := PRED(songdata.patt_len)-1 downto page do
                       For temp2 := 1 to songdata.nm_tracks do
                         begin
                           get_chunk(pattern,temp1,temp2,chunk);
                           put_chunk(pattern,temp1+1,temp2,chunk);
                         end;
                     For temp1 := 1 to songdata.nm_tracks do
                       begin
                         FillChar(chunk,SizeOf(chunk),0);
                         put_chunk(pattern,page,temp1,chunk);
                       end;
                   end;

      kNPdel:  If NumLock then nope := TRUE
               else
                 If shift_pressed then
                   begin
                     For temp1 := page to PRED(songdata.patt_len)-1 do
                       For temp2 := 1 to songdata.nm_tracks do
                         begin
                           get_chunk(pattern,temp1+1,temp2,chunk);
                           put_chunk(pattern,temp1,temp2,chunk);
                         end;
                     For temp1 := 1 to songdata.nm_tracks do
                       begin
                         FillChar(chunk,SizeOf(chunk),0);
                         put_chunk(pattern,PRED(songdata.patt_len),temp1,chunk);
                       end;
                   end;

      kAltB:   If marking then
                 begin
                   old_block_chan_pos := chan_pos;
                   old_block_patt_hpos := hpos;
                   old_block_patt_page := page;
                   chan_pos := old_chan_pos;
                   hpos := old_hpos;
                   page := old_page;
                   marking := FALSE;
                 end
               else begin
                      old_chan_pos := chan_pos;
                      old_hpos := hpos;
                      old_page := page;
                      hpos := old_block_patt_hpos;
                      page := old_block_patt_page;
                      chan_pos := old_block_chan_pos;
                      marking := TRUE;
                    end;

      kAltQ:   Case quick_mark_type of
                 0: begin
                      old_chan_pos := chan_pos;
                      old_hpos := hpos;
                      old_page := page;
                      page := 0;
                      marking := TRUE;
                      block_xstart := count_channel(hpos);
                      block_ystart := PRED(songdata.patt_len);
                      quick_mark_type := 1;
                    end;

                 1: begin
                      marking := TRUE;
                      chan_pos := 1;
                      hpos := 1;
                      page := 0;
                      block_xstart := songdata.nm_tracks;
                      block_ystart := PRED(songdata.patt_len);
                      quick_mark_type := 2;
                    end;

                 2: begin
                      old_block_chan_pos := chan_pos;
                      old_block_patt_hpos := hpos;
                      old_block_patt_page := page;
                      chan_pos := old_chan_pos;
                      hpos := old_hpos;
                      page := old_page;
                      marking := FALSE;
                      quick_mark_type := 0;
                    end;
               end;

      kCtrlK:  begin
                 get_chunk(pattern,pattern_page,count_channel(hpos),chunk);
                 chunk.note := BYTE_NULL;
                 put_chunk(pattern,pattern_page,count_channel(hpos),chunk);
                 If page < PRED(songdata.patt_len) then Inc(page)
                 else If cycle_pattern then page := 0;                 
               end;

      kBkSPC:  begin
                 get_chunk(pattern,pattern_page,count_channel(hpos),chunk);
                 If (command_typing <> 0) then
                   Case count_pos(hpos) of
                     0,
                     1: begin
                          chunk.note := 0;
                          If is_4op_chan(count_channel(hpos)) and
                             (count_channel(hpos) in [2,4,6,11,13,15]) and
                             (_4op_to_test <> 0) then
                            begin
                              get_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                              chunk2.note := 0;
                              put_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                            end;

                          If midiboard then
                            begin
                              chunk.instr_def := 0;
                              If is_4op_chan(count_channel(hpos)) and
                                 (count_channel(hpos) in [2,4,6,11,13,15]) and
                                 (_4op_to_test <> 0) then
                                begin
                                  get_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                                  chunk2.note := 0;
                                  chunk2.instr_def := 0;
                                  put_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                                end;
                            end;

                        end;
                     2,
                     3: begin
                          chunk.instr_def := 0;
                          If is_4op_chan(count_channel(hpos)) and
                             (count_channel(hpos) in [2,4,6,11,13,15]) and
                             (_4op_to_test <> 0) then
                            begin
                              get_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                              chunk2.note := 0;
                              chunk2.instr_def := 0;
                              put_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                            end;
                        end;

                     4,5,
                     6: begin
                          chunk.effect_def := 0;
                          chunk.effect := 0;
                        end;

                     7,8,
                     9: begin
                          chunk.effect_def2 := 0;
                          chunk.effect2 := 0;
                        end;
                   end
                 else Case count_pos(hpos) of
                        0: begin
                             chunk.note := 0;
                             If is_4op_chan(count_channel(hpos)) and
                                (count_channel(hpos) in [2,4,6,11,13,15]) and
                                (_4op_to_test <> 0) then
                               begin
                                 get_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                                 chunk2.note := 0;
                                 put_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                               end;

                             If midiboard then
                               begin
                                 chunk.instr_def := 0;
                                 If is_4op_chan(count_channel(hpos)) and
                                    (count_channel(hpos) in [2,4,6,11,13,15]) and
                                    (_4op_to_test <> 0) then
                                   begin
                                     get_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                                     chunk2.note := 0;
                                     chunk2.instr_def := 0;
                                     put_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                                   end;
                               end;
                           end;

                        1: begin
                             chunk.instr_def := 0;
                             If is_4op_chan(count_channel(hpos)) and
                                (count_channel(hpos) in [2,4,6,11,13,15]) and
                                (_4op_to_test <> 0) then
                               begin
                                 get_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                                 chunk2.note := 0;
                                 chunk2.instr_def := 0;
                                 put_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                               end;
                           end;

                        2: begin chunk.effect_def := 0; chunk.effect := 0; end;
                        3: begin chunk.effect_def2 := 0; chunk.effect2 := 0; end;
                      end;

                 put_chunk(pattern,pattern_page,count_channel(hpos),chunk);
                 Case backspace_dir of
                   1: If page < PRED(songdata.patt_len) then Inc(page)
                      else If cycle_pattern then page := 0;
                   2: If page > 0 then Dec(page)
                      else If cycle_pattern then page := PRED(songdata.patt_len);
                 end;
               end;

      kCtPgUP: If marking then
                 transpose_custom_area(ttTransposeUp,
                                       ttTransposeAllIns,
                                       pattern,pattern,block_x0,block_x1,block_y0,block_y1,
                                       1)
               else
                 transpose_custom_area(ttTransposeUp,
                                       ttTransposeAllIns,
                                       pattern,pattern,count_channel(hpos),count_channel(hpos),page,page,
                                       1);

      kCtPgDN: If marking then
                 transpose_custom_area(ttTransposeDown,
                                       ttTransposeAllIns,
                                       pattern,pattern,block_x0,block_x1,block_y0,block_y1,
                                       1)
               else
                 transpose_custom_area(ttTransposeDown,
                                       ttTransposeAllIns,
                                       pattern,pattern,count_channel(hpos),count_channel(hpos),page,page,
                                       1);
      kCtrlC: begin
                If marking then clipboard.object_type := objMarkedBlock
                else If (command_typing <> 0) then
                       Case count_pos(hpos) of
                         0,
                         1: clipboard.object_type := objNote;
                         2,
                         3: clipboard.object_type := objInstrumentDef;
                         4,5,
                         6: clipboard.object_type := objEffect;
                         7,8,
                         9: clipboard.object_type := objEffect2;
                       end
                     else Case count_pos(hpos) of
                            0: clipboard.object_type := objNote;
                            1: clipboard.object_type := objInstrumentDef;
                            2: clipboard.object_type := objEffect;
                            3: clipboard.object_type := objEffect2;
                          end;

                   old_block_chan_pos := chan_pos;
                   old_block_patt_hpos := hpos;
                   old_block_patt_page := page;
                   marking := FALSE;
                   copy_object;
                 end;

      kAltP:   paste_object;
      kCtrlV:  If scankey($0f) { TAB } then
                 begin
                   temp := PATTERN_LIST_alt(pattern_list__page);
                   If (temp <> BYTE_NULL) then
                     If (_patts_marked <> 0) then
                       begin
                         For temp := 0 to PRED(max_patterns) do
                           If (songdata.pattern_names[temp][1] <> ' ') then
                             paste_object_alt(temp);
                       end
                     else paste_object_alt(temp-1);
                 end
               else paste_object;

      kAltV: If (clipboard.object_type = objMarkedBlock) then
               For temp2 := page to page+clipboard.block_vsize do
                 For temp1 := count_channel(hpos) to count_channel(hpos)+clipboard.block_hsize do
                   begin
                     get_chunk(pattern,temp2,temp1,chunk);
                     If (chunk.note = 0) then
                       begin
                         chunk.note :=
                           clipboard.pattern[SUCC(temp1-count_channel(hpos))]
                                         [temp2-page].note;
                         chunk.instr_def :=
                           clipboard.pattern[SUCC(temp1-count_channel(hpos))]
                                         [temp2-page].instr_def;
                       end;
               
                       If (chunk.effect_def = 0) then
                         chunk.effect_def :=
                           clipboard.pattern[SUCC(temp1-count_channel(hpos))]
                                         [temp2-page].effect_def;
               
                       If (chunk.effect = 0) then
                         chunk.effect :=
                           clipboard.pattern[SUCC(temp1-count_channel(hpos))]
                                         [temp2-page].effect;
               
                       If (chunk.effect_def2 = 0) then
                         chunk.effect_def2 :=
                           clipboard.pattern[SUCC(temp1-count_channel(hpos))]
                                         [temp2-page].effect_def2;
               
                       If (chunk.effect2 = 0) then
                         chunk.effect2 :=
                           clipboard.pattern[SUCC(temp1-count_channel(hpos))]
                                         [temp2-page].effect2;
               
                       put_chunk(pattern,temp2,temp1,chunk);
                     end;

      kCtrlX:  If marking then
                 begin
                   clipboard.object_type := objMarkedBlock;
                   clipboard.block_hsize := block_x1-block_x0;
                   clipboard.block_vsize := block_y1-block_y0;

                   For temp2 := block_y0 to block_y1 do
                     For temp1 := block_x0 to block_x1 do
                       begin
                         get_chunk(pattern,temp2,temp1,chunk);
                         clipboard.pattern[SUCC(temp1-block_x0)]
                                       [temp2-block_y0] := chunk;
                       end;

                   old_block_chan_pos := chan_pos;
                   old_block_patt_hpos := hpos;
                   old_block_patt_page := page;
                   marking := FALSE;
                   For temp2 := block_x0 to block_x1 do
                     For temp1 := block_y0 to block_y1 do
                       begin
                         For temp3 := block_y0 to PRED(songdata.patt_len) do
                           begin
                             get_chunk(pattern,temp3+1,temp2,chunk);
                             put_chunk(pattern,temp3,temp2,chunk);
                           end;
                         FillChar(chunk,SizeOf(chunk),0);
                         put_chunk(pattern,PRED(songdata.patt_len),temp2,chunk);
                       end;
                 end;

      kCtrlN:  If marking then
                 begin
                   old_block_chan_pos := chan_pos;
                   old_block_patt_hpos := hpos;
                   old_block_patt_page := page;
                   marking := FALSE;
                   For temp2 := block_y0 to block_y1 do
                     For temp1 := block_x0 to block_x1 do
                       begin
                         FillChar(chunk,SizeOf(chunk),0);
                         put_chunk(pattern,temp2,temp1,chunk);
                       end;
                 end;

      kAltC:   begin
                 mn_setting.cycle_moves := TRUE;
                 If NOT marking then copymnu2[12] := copymark[1]
                 else copymnu2[12] := copymark[2];
                 temp1 := Menu(copymnu2,01,01,copypos2,30,15,15,' COPY OBJECT ');

                 If (mn_environment.keystroke <> kESC) then
                   begin
                     copypos2 := temp1;
                     If marking and
                        (tCOPY_OBJECT(temp1) = objMarkedBlock) then
                       clipboard.object_type := objMarkedBlock
                     else If (tCOPY_OBJECT(temp1) <> objMarkedBlock) then
                            clipboard.object_type := tCOPY_OBJECT(temp1)
                          else GOTO _end; //CONTINUE;

                     old_block_chan_pos := chan_pos;
                     old_block_patt_hpos := hpos;
                     old_block_patt_page := page;
                     marking := FALSE;
                     copy_object;
                   end;
               end;

      kCtrlB:  If marking then
                 begin
                   old_block_chan_pos := chan_pos;
                   old_block_patt_hpos := hpos;
                   old_block_patt_page := page;
                   marking := FALSE;
                   For temp2 := block_x0 to block_x1 do
                     For temp1 := block_y0 to block_y1 do
                       begin
                         For temp3 := PRED(songdata.patt_len)-1 downto block_y0 do
                           begin
                             get_chunk(pattern,temp3,temp2,chunk);
                             put_chunk(pattern,temp3+1,temp2,chunk);
                           end;
                         FillChar(chunk,SizeOf(chunk),0);
                         put_chunk(pattern,block_y0,temp2,chunk);
                       end;
                 end;

      kCtrlD:  If NOT marking then DEBUG_INFO
               else
                 begin
                   old_block_chan_pos := chan_pos;
                   old_block_patt_hpos := hpos;
                   old_block_patt_page := page;
                   marking := FALSE;
                   For temp2 := block_x0 to block_x1 do
                     For temp1 := block_y0 to block_y1 do
                       begin
                         For temp3 := block_y0 to PRED(songdata.patt_len)-1 do
                           begin
                             get_chunk(pattern,temp3+1,temp2,chunk);
                             put_chunk(pattern,temp3,temp2,chunk);
                           end;
                         FillChar(chunk,SizeOf(chunk),0);
                         put_chunk(pattern,PRED(songdata.patt_len),temp2,chunk);
                       end;
                 end;

      kCtrlT:  TRANSPOSE;
      kCtrlR:  REMAP;
      kCtrlO:  OCTAVE_CONTROL;
      kCtrlP:  PATTERN_LIST(pattern_list__page);
      kCtrlF:  SONG_VARIABLES;
      kCtrlH:  REPLACE;
      kCtrlI:  INSTRUMENT_CONTROL;
      kCtrlQ:  MACRO_EDITOR(current_inst,FALSE);
      kCtrlE:  MACRO_EDITOR(current_inst,TRUE);
      kCtrlM:  MACRO_BROWSER(TRUE,TRUE);

      kCtLEFT: If (play_status = isPlaying) then rewind := TRUE;
      kCtRGHT: If (play_status = isPlaying) then fast_forward := TRUE;

      kCtENTR: If play_single_patt then current_line := 0
               else
                 begin
                   no_status_refresh := TRUE;
                   fade_out_playback(FALSE);
                   If (current_order < $7f) and
                      (play_status <> isStopped) then
                     If (songdata.pattern_order[SUCC(current_order)] < $80) then
                       calibrate_player(SUCC(current_order),0,FALSE,FALSE)
                     else If (calc_following_order(SUCC(current_order)) <> -1) then
                            calibrate_player(calc_following_order(SUCC(current_order)),0,FALSE,FALSE)
                          else
                   else If (calc_following_order(0) <> -1) then
                          calibrate_player(calc_following_order(0),0,FALSE,FALSE);
                   no_status_refresh := FALSE;
                 end;

      kF1:     begin
                 If marking then temps := 'block_operations'
                 else If NOT (command_typing <> 0) and (count_pos(hpos) in [2,3]) then temps := 'effects'
                      else If (command_typing <> 0) and (count_pos(hpos) in [4..9]) then temps := 'effects'
                           else If debugging and (play_status = isStopped) then temps := 'midiboard'
                               else temps := 'pattern_editor';
                 If NOT marking and (sdl_opl3_emulator = 1) and
                    opl3_channel_recording_mode then HELP('wav_recorder')          
                 else HELP(temps);
               end;
      kF2,
      kShF2,
      kCtrlS:  begin
                 If (fkey = kShF2) then quick_cmd := TRUE;
                 FILE_save('a2m');
                 quick_cmd := FALSE;
               end;

      kAltF2:  FILE_save('a2p');
      kCtrlF2: FILE_save('a2t');

      kF3,
      kShF3,
      kCtrlL:  begin
                 If (fkey = kShF3) then quick_cmd := TRUE;
                 FILE_open('*.a2m$*.a2t$*.a2p$*.amd$*.cff$*.dfm$*.fmk$*.hsc$*.mtk$*.rad$'+
                           '*.s3m$*.sat$*.sa2$*.xms$',FALSE);
                 quick_cmd := FALSE;
               end;

      kF4,
      kCtrlA:  NUKE;
      kF5,
      kAltF5,
      kShF5:   If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                   If (shift_pressed and NOT trace_by_default) or
                      (NOT shift_pressed and trace_by_default) then
                     begin
                       temp1 := PATTERN_trace;
                       If (temp1 = kF10) then
                         begin
                           fkey := temp1;
                           nope := TRUE;
                         end;
                     end;
                 end
               else
                 Case play_status of
                   isPlaying: If (shift_pressed and NOT trace_by_default) or
                                 (NOT shift_pressed and trace_by_default) then
                                begin
                                  If (NOT nosync_by_default and (fkey = kAltF5)) or
                                     (nosync_by_default and (fkey = kF5)) then
                                    no_sync_playing := TRUE;

                                  temp1 := PATTERN_trace;
                                  If (temp1 = kF10) then
                                    begin
                                      fkey := temp1;
                                      nope := TRUE;
                                    end;
                                end;

                   isStopped: begin
                                If (NOT nosync_by_default and (fkey = kAltF5)) or
                                   (nosync_by_default and (fkey = kF5)) then
                                  no_sync_playing := TRUE;

                                start_playing;
                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;

                   isPaused:  begin
                                replay_forbidden := FALSE;
                                play_status := isPlaying;

                                If (NOT nosync_by_default and (fkey = kAltF5)) or
                                   (nosync_by_default and (fkey = kF5)) then
                                  no_sync_playing := TRUE;

                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;
                 end;

      kF6:     Case play_status of
                 isPlaying: begin
                              replay_forbidden := TRUE;
                              play_status := isPaused;
                            end;

                 isPaused:  begin
                              replay_forbidden := FALSE;
                              play_status := isPlaying;
                            end;
               end;

      kShF6:   If NOT replay_forbidden then
                 begin
                   debugging := TRUE;
                   play_status := isPlaying;
                   temp1 := PATTERN_trace;
                   If (temp1 = kF10) then
                     begin
                       fkey := temp1;
                       nope := TRUE;
                     end;
                 end
               else If NOT play_single_patt and
                       (calc_pattern_pos(pattern) <> BYTE_NULL) then
                      begin
                        fade_out_playback(FALSE);
                        calibrate_player(calc_pattern_pos(pattern),pattern_page,TRUE,TRUE);
                        If (play_status <> isStopped) then
                          begin
                            debugging := TRUE;
                            play_status := isPlaying;
                            replay_forbidden := FALSE;
                            PATTERN_ORDER_page_refresh(pattord_page);
                            PATTERN_page_refresh(pattern_page);
                            temp1 := PATTERN_trace;
                            If (temp1 = kF10) then
                              begin
                                fkey := temp1;
                                nope := TRUE;
                              end;
                          end;
                      end
                    else If (calc_pattern_pos(pattern) = BYTE_NULL) then
                           begin
                             fade_out_playback(FALSE);
                             play_single_patt := TRUE;
                             no_sync_playing := TRUE;
                             start_pattern := pattern_patt;
                             start_line := pattern_page;
                             start_playing;
                             debugging := TRUE;
                             temp1 := PATTERN_trace;
                             If (temp1 = kF10) then
                               begin
                                 fkey := temp1;
                                 nope := TRUE;
                               end;
                           end;

      kAltF6:  If NOT play_single_patt then
                 begin
                   start_pattern := pattern;
                   play_single_patt := TRUE;
                   no_sync_playing := TRUE;
                   start_playing;
                   repeat_pattern := TRUE;
                   If (shift_pressed and NOT trace_by_default) or
                      (NOT shift_pressed and trace_by_default) then
                     begin
                       temp1 := PATTERN_trace;
                       If (temp1 = kF10) then
                         begin
                           fkey := temp1;
                           nope := TRUE;
                         end;
                     end;
                 end
               else begin
                      temp1 := PATTERN_trace;
                      If (temp1 = kF10) then
                        begin
                          fkey := temp1;
                          nope := TRUE;
                        end;
                    end;

      kF7:     If (play_status <> isStopped) then
                 begin
                   fade_out_playback(FALSE);
                   stop_playing;
                   FillChar(ai_table,SizeOf(ai_table),0);
                 end;
      kF8,
      kAltF8,
      kShF8:   If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                   If (shift_pressed and NOT trace_by_default) or
                      (NOT shift_pressed and trace_by_default) then
                     begin
                       temp1 := PATTERN_trace;
                       If (temp1 = kF10) then
                         begin
                           fkey := temp1;
                           nope := TRUE;
                         end;
                     end;
                 end
               else
                 Case play_status of
                   isPlaying: begin
                                debugging := FALSE;
                                repeat_pattern := FALSE;
                                If (NOT nosync_by_default and (fkey = kAltF8)) or
                                   (nosync_by_default and (fkey = kF8)) then
                                  no_sync_playing := TRUE;

                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;

                   isStopped: If (calc_pattern_pos(pattern) <> BYTE_NULL) then
                                begin
                                  debugging := FALSE;
                                  If (NOT nosync_by_default and (fkey = kAltF8)) or
                                     (nosync_by_default and (fkey = kF8)) then
                                    no_sync_playing := TRUE;

                                  calibrate_player(calc_pattern_pos(pattern),0,TRUE,FALSE);
                                  repeat_pattern := FALSE;
                                  If (shift_pressed and NOT trace_by_default) or
                                     (NOT shift_pressed and trace_by_default) then
                                    begin
                                      temp1 := PATTERN_trace;
                                      If (temp1 = kF10) then
                                        begin
                                          fkey := temp1;
                                          nope := TRUE;
                                        end;
                                    end;
                                end;

                   isPaused:  begin
                                debugging := FALSE;
                                repeat_pattern := FALSE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;

                                If (NOT nosync_by_default and (fkey = kAltF8)) or
                                   (nosync_by_default and (fkey = kF8)) then
                                  no_sync_playing := TRUE;

                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;
                 end;

      kCtrlF8: If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                   If (shift_pressed and NOT trace_by_default) or
                      (NOT shift_pressed and trace_by_default) then
                     begin
                       temp1 := PATTERN_trace;
                       If (temp1 = kF10) then
                         begin
                           fkey := temp1;
                           nope := TRUE;
                         end;
                     end;
                 end
               else
                 Case play_status of
                   isPlaying: begin
                                debugging := FALSE;
                                repeat_pattern := FALSE;
                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;

                   isStopped: If (calc_pattern_pos(pattern) <> BYTE_NULL) then
                                begin
                                  debugging := FALSE;
                                  calibrate_player(calc_pattern_pos(pattern),pattern_page,TRUE,FALSE);
                                  repeat_pattern := FALSE;
                                  If (shift_pressed and NOT trace_by_default) or
                                     (NOT shift_pressed and trace_by_default) then
                                    begin
                                      temp1 := PATTERN_trace;
                                      If (temp1 = kF10) then
                                        begin
                                          fkey := temp1;
                                          nope := TRUE;
                                        end;
                                    end;
                                end;

                   isPaused:  begin
                                debugging := FALSE;
                                repeat_pattern := FALSE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;
                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;
                 end;

      kF9,
      kAltF9,
      kShF9:   If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                   If (shift_pressed and NOT trace_by_default) or
                      (NOT shift_pressed and trace_by_default) then
                     begin
                       temp1 := PATTERN_trace;
                       If (temp1 = kF10) then
                         begin
                           fkey := temp1;
                           nope := TRUE;
                         end;
                     end;
                 end
               else
                 Case play_status of
                   isPlaying: begin
                                debugging := FALSE;
                                repeat_pattern := TRUE;
                                If (NOT nosync_by_default and (fkey = kAltF9)) or
                                   (nosync_by_default and (fkey = kF9)) then
                                  no_sync_playing := TRUE;

                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;

                   isStopped: If (calc_pattern_pos(pattern) <> BYTE_NULL) then
                                begin
                                  debugging := FALSE;
                                  If (NOT nosync_by_default and (fkey = kAltF9)) or
                                     (nosync_by_default and (fkey = kF9)) then
                                    no_sync_playing := TRUE;

                                  calibrate_player(calc_pattern_pos(pattern),0,TRUE,FALSE);
                                  repeat_pattern := TRUE;
                                  If (shift_pressed and NOT trace_by_default) or
                                     (NOT shift_pressed and trace_by_default) then
                                    begin
                                      temp1 := PATTERN_trace;
                                      If (temp1 = kF10) then
                                        begin
                                          fkey := temp1;
                                          nope := TRUE;
                                        end;
                                    end;
                                end;

                   isPaused:  begin
                                debugging := FALSE;
                                repeat_pattern := TRUE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;

                                If (NOT nosync_by_default and (fkey = kAltF9)) or
                                   (nosync_by_default and (fkey = kF9)) then
                                  no_sync_playing := TRUE;

                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;
                 end;

      kCtrlF9: If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                   If (shift_pressed and NOT trace_by_default) or
                      (NOT shift_pressed and trace_by_default) then
                     begin
                       temp1 := PATTERN_trace;
                       If (temp1 = kF10) then
                         begin
                           fkey := temp1;
                           nope := TRUE;
                         end;
                     end;
                 end
               else
                 Case play_status of
                   isPlaying: begin
                                debugging := FALSE;
                                repeat_pattern := TRUE;
                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;

                   isStopped: If (calc_pattern_pos(pattern) <> BYTE_NULL) then
                                begin
                                  debugging := FALSE;
                                  calibrate_player(calc_pattern_pos(pattern),pattern_page,TRUE,FALSE);
                                  repeat_pattern := TRUE;
                                  If (shift_pressed and NOT trace_by_default) or
                                     (NOT shift_pressed and trace_by_default) then
                                    begin
                                      temp1 := PATTERN_trace;
                                      If (temp1 = kF10) then
                                        begin
                                          fkey := temp1;
                                          nope := TRUE;
                                        end;
                                    end;
                                end;

                   isPaused:  begin
                                debugging := FALSE;
                                repeat_pattern := TRUE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;
                                If (shift_pressed and NOT trace_by_default) or
                                   (NOT shift_pressed and trace_by_default) then
                                  begin
                                    temp1 := PATTERN_trace;
                                    If (temp1 = kF10) then
                                      begin
                                        fkey := temp1;
                                        nope := TRUE;
                                      end;
                                  end;
                              end;
                 end;
      kF10,
      kESC:    begin
                 QUIT_request;
                 If (fkey = kESC) then nope := TRUE;
               end;

      kENTER:  If NOT shift_pressed then nope := TRUE
               else If marking then
                      For temp2 := block_x0 to block_x1 do
                        For temp1 := block_y0 to block_y1 do
                          begin
                            get_chunk(pattern,temp1,temp2,chunk);
                            If (chunk.note in [1..12*8+1]) then
                              chunk.note := chunk.note+fixed_note_flag
                            else If (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1]) then
                                   chunk.note := chunk.note-fixed_note_flag;
                            put_chunk(pattern,temp1,temp2,chunk);
                          end
                    else
                      begin
                        get_chunk(pattern,page,count_channel(hpos),chunk);
                        If (chunk.note in [1..12*8+1]) then
                          chunk.note := chunk.note+fixed_note_flag
                        else If (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1]) then
                               chunk.note := chunk.note-fixed_note_flag;
                        put_chunk(pattern,page,count_channel(hpos),chunk);
                      end;

      else nope := TRUE;
    end;

    If (nope or (fkey = kSPACE) or
                (fkey = kWeird)) and
       midiboard then
      begin
        nope := FALSE;
        flag := FALSE;

        If NOT ctrl_pressed and NOT alt_pressed then
          For temp1 := 1 to 29 do
            If (board_scancodes[temp1] = HI(fkey)) then
              begin
                flag := TRUE;
                BREAK;
              end
            else
              If shift_pressed and (board_scancodes[temp1] = HI(fkey)) then
                begin
                  flag := TRUE;
                  BREAK;
                end;

        fkey_X := fkey;
        If ((fkey = kSPACE) or
            (((fkey = kWeird) or
              (flag AND (count_pos(hpos) = 0))) and
               NOT ((fkey = kWeird) and (count_pos(hpos) >= 2)) and
                    NOT (is_4op_chan(count_channel(hpos)) and
                        (count_channel(hpos) in [1,3,5,10,12,14])))) then
          begin
            If (fkey = kSPACE) or (fkey = kWeird) or
               (temp1+12*(current_octave-1) in [1..12*8+1]) then
              begin
                If (fkey <> kSPACE) and
                   NOT (is_4op_chan(count_channel(hpos)) and
                       (count_channel(hpos) in [1,3,5,10,12,14])) then
                  begin
                    get_chunk(pattern,page,count_channel(hpos),chunk);
                    If (fkey <> kWeird) then
                      begin
                        If NOT right_shift_pressed then
                          chunk.note := temp1+12*(current_octave-1)
                        else chunk.note := temp1+12*(current_octave-1)+fixed_note_flag;
                        If NOT (chunk.effect_def in [ef_TonePortamento,
                                                     ef_TPortamVolSlide]) then
                          begin
                            chunk.instr_def := current_inst;
                            If is_4op_chan(count_channel(hpos)) and
                               (count_channel(hpos) in [2,4,6,11,13,15]) and
                               (_4op_to_test <> 0) then
                              begin
                                get_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                                chunk2.note := 0;
                                chunk2.instr_def := HI(_4op_to_test);
                                put_chunk(pattern,pattern_page,PRED(count_channel(hpos)),chunk2);
                              end;
                          end
                        else chunk.instr_def := 0;
                      end
                    else begin
                           chunk.note := BYTE_NULL;
                           chunk.instr_def := 0;
                         end;
                    put_chunk(pattern,page,count_channel(hpos),chunk);
                    fkey := kSPACE;
                  end;

                If (songdata.pattern_order[pattern] <> BYTE_NULL) and
                   NOT ((play_status <> isStopped) and (fkey_X = kSPACE)) then
                  begin
                    status_backup.replay_forbidden := replay_forbidden;
                    status_backup.play_status := play_status;

                    If (status_backup.play_status <> isStopped) then
                      begin
                        replay_forbidden := TRUE;
                        If (play_status <> isStopped) then play_status := isPaused;
                        nul_volume_bars;

                        Move(event_table,event_table_backup,SizeOf(event_table));
                        Move(voice_table,voice_table_backup,SizeOf(voice_table));
                        Move(volume_table,volume_table_backup,SizeOf(volume_table));
                        Move(pan_lock,pan_lock_backup,SizeOf(pan_lock));
                        Move(volume_lock,volume_lock_backup,SizeOf(volume_lock));
                        Move(peak_lock,peak_lock_backup,SizeOf(volume_lock));
                        Move(panning_table,panning_table_backup,SizeOf(panning_table));
                        FillChar(pan_lock,SizeOf(pan_lock),0);
                        FillChar(volume_lock,SizeOf(volume_lock),0);
                        FillChar(peak_lock,SizeOf(volume_lock),0);

                        reset_player;
                        Move(fmpar_table,fmpar_table_backup,SizeOf(fmpar_table_backup));
                        Move(freq_table,freq_table_backup,SizeOf(freq_table));
                        Move(freqtable2,freqtable2_backup,SizeOf(freqtable2));
                        Move(keyoff_loop,keyoff_loop_backup,SizeOf(keyoff_loop));
                        FillChar(keyoff_loop,SizeOf(keyoff_loop),FALSE);
                      end;

                    If NOT (debugging and (play_status = isStopped)) then
                      begin
                        init_player;
                        debugging := TRUE;
                      end;

                    old_order := current_order;
                    old_pattern := current_pattern;
                    old_line := current_line;
                    old_speed := speed;
                    old_tempo := tempo;
                    current_order := 0;
                    current_pattern := pattern;
                    current_line := page;
                    single_play := TRUE;
                    poll_proc;
                    single_play := FALSE;
                    current_order := old_order;
                    current_pattern := old_pattern;
                    current_line := old_line;
                    speed := old_speed;
                    tempo := old_tempo;

                    play_status := isStopped;
                    PATTERN_ORDER_page_refresh(pattord_page);
                    PATTERN_page_refresh(page);
                    If (fkey_X <> kSPACE) then wait_until_key_released;

                    If (status_backup.play_status <> isStopped) then
                      begin
                        Move(event_table_backup,event_table,SizeOf(event_table));
                        Move(voice_table_backup,voice_table,SizeOf(voice_table));
                        Move(volume_table_backup,volume_table,SizeOf(volume_table));
                        Move(fmpar_table_backup,fmpar_table,SizeOf(fmpar_table));
                        Move(panning_table_backup,panning_table,SizeOf(panning_table));
                        reset_player;

                        Move(pan_lock_backup,pan_lock,SizeOf(pan_lock));
                        Move(volume_lock_backup,volume_lock,SizeOf(volume_lock));
                        Move(peak_lock_backup,peak_lock,SizeOf(volume_lock));

                        Move(freq_table_backup,freq_table,SizeOf(freq_table));
                        Move(freqtable2_backup,freqtable2,SizeOf(freqtable2));
                        Move(keyoff_loop_backup,keyoff_loop,SizeOf(keyoff_loop));
                        FillChar(macro_table,SizeOf(macro_table),0);
                        replay_forbidden := status_backup.replay_forbidden;
                        play_status := status_backup.play_status;
                        debugging := FALSE;
                      end;

                    If (page < PRED(songdata.patt_len)) then Inc(page)
                    else If cycle_pattern then page := 0;

                    If left_shift_pressed and (mark_line <> 0) and mark_lines then
                      While (page MOD mark_line <> 0) do
                        If (page < PRED(songdata.patt_len)) then Inc(page)
                        else If cycle_pattern then page := 0;
                  end
                else
                  If (page < PRED(songdata.patt_len)) then Inc(page)
                  else If cycle_pattern then page := 0;
              end;
          end
        else If (fkey <> kUp)     and (fkey <> kDown)   and
                (fkey <> kHome)   and (fkey <> kEnd)    and
                (fkey <> kLeft)   and (fkey <> kRight)  and
                (fkey <> kPgUp)   and (fkey <> kPgDown) and
                (fkey <> kCtPgUp) and (fkey <> kCtPgDn) and
                (fkey <> kTab)    and (fkey <> kShTab)  and
                (fkey <> kCtLbr)  and (fkey <> kCtRbr)  and
                (fkey <> kCHlbrk) and (fkey <> kCHrbrk) and
                (fkey <> kCtHome) and (fkey <> kCtEnd)  and
                (fkey <> kAltM)   and (fkey <> kAltL)   and
                (fkey <> kCtEntr) and (fkey <> kF1)     and

                NOT (shift_pressed and ((fkey = kHome)   or (fkey = kNPHome) or
                                        (fkey = kPgUp)   or (fkey = kNPPgUp) or
                                        (fkey = kEnd)    or (fkey = kNPEnd)  or
                                        (fkey = kPgDown) or (fkey = kNPPgDn))) then
               begin
                 If debugging and replay_forbidden then
                   begin
                     fade_out_playback(FALSE);
                     stop_playing;
                   end;

                 nope := TRUE;
                 debugging := FALSE;
               end;
      end
    else If (fkey <> kUp)     and (fkey <> kDown)   and
            (fkey <> kHome)   and (fkey <> kEnd)    and
            (fkey <> kLeft)   and (fkey <> kRight)  and
            (fkey <> kPgUp)   and (fkey <> kPgDown) and
            (fkey <> kCtPgUp) and (fkey <> kCtPgDn) and
            (fkey <> kTab)    and (fkey <> kShTab)  and
            (fkey <> kCtLbr)  and (fkey <> kCtRbr)  and
            (fkey <> kCHlbrk) and (fkey <> kCHrbrk) and
            (fkey <> kCtHome) and (fkey <> kCtEnd)  and
            (fkey <> kAltM)   and (fkey <> kAltL)   and
            (fkey <> kCtEntr) and (fkey <> kF1)     and

            NOT (shift_pressed and ((fkey = kHome)   or (fkey = kNPHome) or
                                    (fkey = kPgUp)   or (fkey = kNPPgUp) or
                                    (fkey = kEnd)    or (fkey = kNPEnd)  or
                                    (fkey = kPgDown) or (fkey = kNPPgDn))) then
           begin
             If debugging and replay_forbidden then
               begin
                 fade_out_playback(FALSE);
                 stop_playing;
               end;

             debugging := FALSE;
           end;

     If nope and NOT midiboard and (count_pos(hpos) = 0) and
        NOT (is_4op_chan(count_channel(hpos)) and
            (count_channel(hpos) in [1,3,5,10,12,14])) and
        (UpCase(CHAR(LO(fkey))) in ['A',UpCase(b_note),'C'..'G']) then
      begin
        nope := FALSE;
        is_setting.append_enabled := FALSE;
        is_setting.character_set  := ['1'..'9','a',b_note,'c'..'g',
                                      'A',UpCase(b_note),'C'..'F','#','-'];
        is_environment.locate_pos := 2;
        tstr := CHAR(LO(fkey));
        is_setting.terminate_keys[3] := kTAB;

        Repeat
               tstr := InputStr(tstr,08+pos3[1+(count_channel(hpos)-PRED(chan_pos)-1)*4],
                                11+PRED(MAX_PATTERN_ROWS DIV 2),3,3,
                           pattern_input_bckg+pattern_input,
                           pattern_input_warn+pattern_input);
          is_setting.append_enabled := TRUE;

          If (UpCase(tstr[1]) in ['A',UpCase(b_note),'C'..'G']) and
            ((is_environment.keystroke = kENTER) or
             (is_environment.keystroke = kTAB)) then
            begin
              nope := FALSE;
              If (Length(tstr) = 2) then
                If tstr[2] in ['1'..'9'] then Insert('-',tstr,2)
                else If tstr[2] in ['-','#'] then
                       tstr := tstr+Num2str(current_octave,10);

              If (Length(tstr) = 1) then
                tstr := tstr+'-'+Num2str(current_octave,10);

              For temp1 := 1 to 12*8+1 do
                If (Upper(tstr) = note_layout[temp1]) then
                  begin
                    nope := TRUE;
                    get_chunk(pattern,page,count_channel(hpos),chunk);
                    chunk.note := temp1;
                    put_chunk(pattern,page,count_channel(hpos),chunk);
                    BREAK;
                  end;

              If NOT nope and (Length(tstr) = 2) then
                For temp1 := 1 to 12*8+1 do
                  If (Copy(Upper(tstr),1,2) = Copy(note_layout[temp1],1,2)) then
                    begin
                      nope := TRUE;
                      get_chunk(pattern,page,count_channel(hpos),chunk);
                      chunk.note := temp1;
                      put_chunk(pattern,page,count_channel(hpos),chunk);
                      BREAK;
                    end;

              If nope and linefeed and
                 (is_environment.keystroke = kENTER) then
                If page < PRED(songdata.patt_len) then Inc(page)
                else If cycle_pattern then page := 0;
              If (tstr = '') then nope := TRUE;
              If nope and (is_environment.keystroke = kTAB) and
                          (hpos+1 <= last_hpos) then Inc(hpos);
            end;
        until (is_environment.keystroke = kESC) or nope;
        is_setting.terminate_keys[3] := 0;
        nope := FALSE;
      end;

    If NOT (command_typing <> 0) and nope and (count_pos(hpos) = 1) and
       (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'F']) then
      begin
        nope := FALSE;
        is_setting.append_enabled := FALSE;
        is_setting.character_set  := ['0'..'9','a'..'f','A'..'F'];
        is_environment.locate_pos := 2;
        tstr := CHAR(LO(fkey));
        is_setting.terminate_keys[3] := kTAB;
        If (pattern_layout = 1) then temp := 1 else temp := 0;

        Repeat
          tstr := InputStr(tstr,08+pos3[hpos]-temp,11+PRED(MAX_PATTERN_ROWS DIV 2),2,2,
                           pattern_input_bckg+pattern_input,
                           pattern_input_warn+pattern_input);
          is_setting.append_enabled := TRUE;

          If (is_environment.keystroke = kENTER) or
             (is_environment.keystroke = kTAB) then
            If (tstr = '') then nope := TRUE
            else If Str2num(tstr,16) in [0..$0fa] then
                   begin
                     nope := TRUE;
                     get_chunk(pattern,page,count_channel(hpos),chunk);
                     chunk.instr_def := Str2num(tstr,16);
                     put_chunk(pattern,page,count_channel(hpos),chunk);

                     If (chunk.instr_def <> 0) and update_ins then
                       If is_4op_chan(count_channel(hpos)) and
                          (count_channel(hpos) in [1,3,5,10,12,14]) then
                         reset_4op_to_test(2,chunk.instr_def)
                       else begin
                              current_inst := chunk.instr_def;
                              instrum_page := current_inst;
                              reset_4op_to_test(1,BYTE_NULL);
                            end;
                   end;
          If nope and linefeed and
             (is_environment.keystroke = kENTER) then
            If page < PRED(songdata.patt_len) then Inc(page)
            else If cycle_pattern then page := 0;
          If nope and (is_environment.keystroke = kTAB) and
                      (hpos+1 <= last_hpos) then Inc(hpos);
        until (is_environment.keystroke = kESC) or nope;
        is_setting.terminate_keys[3] := 0;
        nope := FALSE;
      end;

    If NOT (command_typing <> 0) and nope and (count_pos(hpos) = 2) and
       (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'Z','&','%','!','@','=','#','$','~','^','`']) then
      begin
        nope := FALSE;
        is_setting.append_enabled := FALSE;
        is_setting.character_set  := ['0'..'9','a'..'z','A'..'Z','&','%','!','@','=','#','$','~','^','`'];
        is_environment.locate_pos := 2;
        tstr := CHAR(LO(fkey));
        is_setting.terminate_keys[3] := kTAB;

        Repeat
          tstr := InputStr(tstr,08+pos3[hpos],11+PRED(MAX_PATTERN_ROWS DIV 2),3,3,
                           pattern_input_bckg+pattern_input,
                           pattern_input_warn+pattern_input);
          is_setting.append_enabled := TRUE;

          If (is_environment.keystroke = kENTER) or
             (is_environment.keystroke = kTAB) then
            If (tstr = '') then nope := TRUE
            else begin
                   get_chunk(pattern,page,count_channel(hpos),chunk);
                   chunk.effect_def := FX(tstr[1]);
                   temp := Str2num(Copy(tstr,2,Length(tstr)),16);
                   If correct_range(chunk.effect_def,temp) or (tstr = '') then
                     begin
                       nope := TRUE;
                       tstr := Copy(tstr,2,Length(tstr));
                       If (tstr <> '') then chunk.effect := Str2num(tstr,16)
                       else chunk.effect := 0;
                       put_chunk(pattern,page,count_channel(hpos),chunk);
                     end;
                 end;
          If nope and linefeed and
             (is_environment.keystroke = kENTER) then
            If page < PRED(songdata.patt_len) then Inc(page)
            else If cycle_pattern then page := 0;
          If nope and (is_environment.keystroke = kTAB) and
                      (hpos+1 <= last_hpos) then Inc(hpos);
        until (is_environment.keystroke = kESC) or nope;
        is_setting.terminate_keys[3] := 0;
        nope := FALSE;
      end;

    If NOT (command_typing <> 0) and nope and (count_pos(hpos) = 3) and
       (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'Z','&','%','!','@','=','#','$','~','^','`']) then
      begin
        nope := FALSE;
        is_setting.append_enabled := FALSE;
        is_setting.character_set  := ['0'..'9','a'..'z','A'..'Z','&','%','!','@','=','#','$','~','^','`'];
        is_environment.locate_pos := 2;
        tstr := CHAR(LO(fkey));
        is_setting.terminate_keys[3] := kTAB;

        Repeat
          tstr := InputStr(tstr,08+pos3[hpos],11+PRED(MAX_PATTERN_ROWS DIV 2),3,3,
                           pattern_input_bckg+pattern_input,
                           pattern_input_warn+pattern_input);
          is_setting.append_enabled := TRUE;

          If (is_environment.keystroke = kENTER) or
             (is_environment.keystroke = kTAB) then
            If (tstr = '') then nope := TRUE
            else begin
                   get_chunk(pattern,page,count_channel(hpos),chunk);
                   chunk.effect_def2 := FX(tstr[1]);
                   temp := Str2num(Copy(tstr,2,Length(tstr)),16);
                   If correct_range(chunk.effect_def2,temp) or (tstr = '') then
                     begin
                       nope := TRUE;
                       tstr := Copy(tstr,2,Length(tstr));
                       If (tstr <> '') then chunk.effect2 := Str2num(tstr,16)
                       else chunk.effect2 := 0;
                       put_chunk(pattern,page,count_channel(hpos),chunk);
                     end;
                 end;
          If nope and linefeed and
             (is_environment.keystroke = kENTER) then
            If page < PRED(songdata.patt_len) then Inc(page)
            else If cycle_pattern then page := 0;
          If nope and (is_environment.keystroke = kTAB) and
                      (hpos+1 <= last_hpos) then Inc(hpos);
        until (is_environment.keystroke = kESC) or nope;
        is_setting.terminate_keys[3] := 0;
        nope := FALSE;
      end;

      If NOT marking and nope then
        If (command_typing <> 0) and
           ((count_pos(hpos) > 0) and
            (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'Z','&','%','!','@','=','#','$','~','^','`'])) then
          begin
            Case count_pos(hpos) of
              1: If NOT (UpCase(CHAR(LO(fkey))) in ['1'..'9']) or
                    (is_4op_chan(count_channel(hpos)) and
                    (count_channel(hpos) in [1,3,5,10,12,14])) then nope := FALSE
                 else begin
                        nope := TRUE;
                        get_chunk(pattern,page,count_channel(hpos),chunk);
                        If (chunk.note in [1..12*8+1]) then
                          chunk.note := ((chunk.note-1) MOD 12)+1+
                                        12*(Str2num(CHAR(LO(fkey)),10)-1)
                        else If (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1]) then
                               chunk.note := ((chunk.note-1) MOD 12)+1+
                                             12*(Str2num(CHAR(LO(fkey)),10)-1)+fixed_note_flag;
                        If (chunk.note in [1..12*8+1,fixed_note_flag+1..fixed_note_flag+12*8+1]) then
                          put_chunk(pattern,page,count_channel(hpos),chunk)
                        else nope := FALSE;
                     end;
              2,
              3: If NOT (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'F']) then nope := FALSE
                 else begin
                        nope := TRUE;
                        get_chunk(pattern,page,count_channel(hpos),chunk);
                        Case count_pos(hpos) of
                          2: chunk.instr_def := Str2num(CHAR(LO(fkey)),16)*$10+
                                                chunk.instr_def AND $0f;
                          3: chunk.instr_def := Str2num(CHAR(LO(fkey)),16)+
                                                chunk.instr_def AND $f0;
                        end;
                        If (chunk.instr_def <= 255) and
                           NOT shift_pressed then
                          begin
                            put_chunk(pattern,page,count_channel(hpos),chunk);
                            If (chunk.instr_def <> 0) and update_ins then
                              If is_4op_chan(count_channel(hpos)) and
                                 (count_channel(hpos) in [1,3,5,10,12,14]) then
                                reset_4op_to_test(2,chunk.instr_def)
                              else begin
                                     current_inst := chunk.instr_def;
                                     instrum_page := current_inst;
                                     reset_4op_to_test(1,BYTE_NULL);
                                   end;
                          end
                        else nope := FALSE;
                      end;
              4,5,
              6: begin
                   nope := TRUE;
                   get_chunk(pattern,page,count_channel(hpos),chunk);
                   Case count_pos(hpos) of
                     4: begin
                          chunk.effect_def := FX(CHAR(LO(fkey)));
                          If (chunk.effect_def in [ef_SetSpeed,ef_SetTempo]) and
                             (chunk.effect = 0) then
                            Case chunk.effect_def of
                              ef_SetSpeed: chunk.effect := songdata.speed;
                              ef_SetTempo: chunk.effect := songdata.tempo;
                            end;
                        end;

                     5: If NOT (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'F']) then nope := FALSE
                        else chunk.effect := Str2num(CHAR(LO(fkey)),16)*$10+
                                             chunk.effect AND $0f;
                     6: If NOT (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'F']) then nope := FALSE
                        else chunk.effect := Str2num(CHAR(LO(fkey)),16)+
                                             chunk.effect AND $f0;
                   end;
                   If correct_range(chunk.effect_def,chunk.effect) and
                      NOT (shift_pressed and NOT (FX(CHAR(LO(fkey))) in [ef_Extended2,ef_Extended3,ef_SetGlobalVolume,
                                                                         ef_ExtraFineArpeggio,ef_ExtraFineVibrato,ef_ExtraFineTremolo,
                                                                         ef_ForceInsVolume,ef_SwapArpeggio,ef_SwapVibrato,
                                                                         ef_SetCustomSpeedTab])) then
                     put_chunk(pattern,page,count_channel(hpos),chunk)
                   else nope := FALSE;
                 end;

              7,8,
              9: begin
                   nope := TRUE;
                   get_chunk(pattern,page,count_channel(hpos),chunk);
                   Case count_pos(hpos) of
                     7: begin
                          chunk.effect_def2 := FX(CHAR(LO(fkey)));
                          If (chunk.effect_def2 in [ef_SetSpeed,ef_SetTempo]) and
                             (chunk.effect2 = 0) then
                            Case chunk.effect_def2 of
                              ef_SetSpeed: chunk.effect2 := songdata.speed;
                              ef_SetTempo: chunk.effect2 := songdata.tempo;
                            end;
                        end;

                     8: If NOT (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'F']) then nope := FALSE
                        else chunk.effect2 := Str2num(CHAR(LO(fkey)),16)*$10+
                                              chunk.effect2 AND $0f;
                     9: If NOT (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'F']) then nope := FALSE
                        else chunk.effect2 := Str2num(CHAR(LO(fkey)),16)+
                                              chunk.effect2 AND $f0;
                   end;
                   If correct_range(chunk.effect_def2,chunk.effect2) and
                      NOT (shift_pressed and NOT (FX(CHAR(LO(fkey))) in [ef_Extended2,ef_Extended3,ef_SetGlobalVolume,
                                                                         ef_ExtraFineArpeggio,ef_ExtraFineVibrato,ef_ExtraFineTremolo,
                                                                         ef_ForceInsVolume,ef_SwapArpeggio,ef_SwapVibrato,
                                                                         ef_SetCustomSpeedTab])) then
                     put_chunk(pattern,page,count_channel(hpos),chunk)
                   else nope := FALSE;
                 end;
            end;

            If (command_typing = 2) and (count_pos(hpos) in [2,5,8]) then Inc(hpos)
            else If nope and linefeed then
                   begin
                     If (command_typing = 2) and (count_pos(hpos) in [3,6,9]) then Dec(hpos);
                     If page < PRED(songdata.patt_len) then Inc(page)
                     else If cycle_pattern then page := 0;
                   end;
          end;

    fkey_X := WORD_NULL;
_end:
    emulate_screen;
    // keyboard_reset_buffer;
  until (nope and ((fkey = kENTER) or (fkey = kESC) or (fkey = kF10))) or _force_program_quit;

  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(page);
end;
