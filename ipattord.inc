{
	procedure pattern_list__proc;
	function PATTERN_LIST(page: Byte): Byte;
	function PATTERN_LIST_alt(page: Byte): Byte;
	procedure PATTERN_ORDER_page_refresh(page: Byte);
	procedure PATTERN_ORDER_edit(var page,hpos,vpos: Byte);
}

var
  _nm_patterns: Byte;

procedure pattern_list__proc;

var
  chunk: tCHUNK;
  temp,temp1,temp2,
  _1st,_2nd,nm_marked: Byte;
  temps: String;

begin
  Case mn_environment.keystroke of
    kSPACE:
      If ctrl_pressed then
        For temp := 0 to $7f do
          If NOT shift_pressed then songdata.pattern_names[temp][1] := ' '
          else If (songdata.pattern_names[temp][1] <> ' ') then
                 songdata.pattern_names[temp][1] := ' '
               else songdata.pattern_names[temp][1] := ''
      else If (songdata.pattern_names[mn_environment.curr_pos-1][1] <> '') then
             songdata.pattern_names[mn_environment.curr_pos-1][1] := ''
           else songdata.pattern_names[mn_environment.curr_pos-1][1] := ' ';

    kAltC,
    kCtrlC: begin
              clipboard.object_type := objPattern;
              For temp2 := 0 to PRED(songdata.patt_len) do
                For temp1 := 1 to songdata.nm_tracks do
                  begin
                    get_chunk(mn_environment.curr_pos-1,temp2,temp1,chunk);
                    clipboard.pattern[temp1][temp2] := chunk;
                  end;
              clipboard._string := Copy(songdata.pattern_names[mn_environment.curr_pos-1],9,33);
            end;

    kAltP,
    kCtrlV: If (clipboard.object_type = objPattern) then
              begin
                If NOT shift_pressed or
                   (left_shift_pressed and NOT right_shift_pressed) then
                  For temp2 := 0 to PRED(songdata.patt_len) do
                    For temp1 := 1 to songdata.nm_tracks do
                      put_chunk(mn_environment.curr_pos-1,temp2,temp1,
                                clipboard.pattern[temp1][temp2]);

                If NOT shift_pressed or
                   (NOT left_shift_pressed and right_shift_pressed) then
                  songdata.pattern_names[mn_environment.curr_pos-1] :=
                    Copy(songdata.pattern_names[mn_environment.curr_pos-1],1,8)+
                    clipboard._string;

                PATTERN_ORDER_page_refresh(pattord_page);
                PATTERN_page_refresh(pattern_page);
              end;

    kCtrlW: If (_patts_marked = 2) then
              begin
                _1st := 0;
                While (_1st < PRED(max_patterns)) and
                      (songdata.pattern_names[_1st][1] = ' ') do
                  Inc(_1st);

                _2nd := SUCC(_1st);
                While (_2nd < PRED(max_patterns)) and
                      (songdata.pattern_names[_2nd][1] = ' ') do
                  Inc(_2nd);

                Move(pattdata^[_1st DIV 8][_1st MOD 8],
                     buffer,
                     PATTERN_SIZE);

                temps := Copy(songdata.pattern_names[_1st],9,33);

                If NOT shift_pressed or
                   (left_shift_pressed and NOT right_shift_pressed) then
                  Move(pattdata^[_2nd DIV 8][_2nd MOD 8],
                       pattdata^[_1st DIV 8][_1st MOD 8],
                       PATTERN_SIZE);

                If NOT shift_pressed or
                   (NOT left_shift_pressed and right_shift_pressed) then
                  songdata.pattern_names[_1st] :=
                    Copy(songdata.pattern_names[_1st],1,8)+
                    Copy(songdata.pattern_names[_2nd],9,33);

                If NOT shift_pressed or
                   (left_shift_pressed and NOT right_shift_pressed) then
                  Move(buffer,
                       pattdata^[_2nd DIV 8][_2nd MOD 8],
                       PATTERN_SIZE);

                If NOT shift_pressed or
                   (NOT left_shift_pressed and right_shift_pressed) then
                  songdata.pattern_names[_2nd] :=
                    Copy(songdata.pattern_names[_2nd],1,8)+
                    temps;

                PATTERN_ORDER_page_refresh(pattord_page);
                PATTERN_page_refresh(pattern_page);
              end;

    kDELETE,
    kNPdel: If shift_pressed then
              begin
                For temp := mn_environment.curr_pos-1 to PRED(max_patterns)-1 do
                  begin
                    Move(pattdata^[SUCC(temp) DIV 8][SUCC(temp) MOD 8],
                         pattdata^[temp DIV 8][temp MOD 8],
                         PATTERN_SIZE);
                    songdata.pattern_names[temp] :=
                      Copy(songdata.pattern_names[SUCC(temp)],1,1)+
                      Copy(songdata.pattern_names[temp],2,10)+
                      Copy(songdata.pattern_names[SUCC(temp)],12,30);
                    songdata.pattern_names[temp][9] :=
                      songdata.pattern_names[SUCC(temp)][9];
                  end;

                FillData(pattdata^[PRED(max_patterns) DIV 8][PRED(max_patterns) MOD 8],
                         PATTERN_SIZE,0);
                songdata.pattern_names[PRED(max_patterns)] :=
                  ' '+
                  Copy(songdata.pattern_names[PRED(max_patterns)],2,10);
                songdata.pattern_names[PRED(max_patterns)][9] := '';

                PATTERN_ORDER_page_refresh(pattord_page);
                PATTERN_page_refresh(pattern_page);
              end;

    kINSERT,
    kNPins: If shift_pressed then
              begin
                For temp := PRED(max_patterns)-1 downto mn_environment.curr_pos-1 do
                  begin
                    Move(pattdata^[temp DIV 8][temp MOD 8],
                         pattdata^[SUCC(temp) DIV 8][SUCC(temp) MOD 8],
                         PATTERN_SIZE);
                    songdata.pattern_names[SUCC(temp)] :=
                      Copy(songdata.pattern_names[temp],1,1)+
                      Copy(songdata.pattern_names[SUCC(temp)],2,10)+
                      Copy(songdata.pattern_names[temp],12,30);
                    songdata.pattern_names[SUCC(temp)][9] :=
                      songdata.pattern_names[temp][9];
                  end;

                FillData(pattdata^[(mn_environment.curr_pos-1) DIV 8]
                                  [(mn_environment.curr_pos-1) MOD 8],
                         PATTERN_SIZE,0);
                songdata.pattern_names[(mn_environment.curr_pos-1)] :=
                  ' '+
                  Copy(songdata.pattern_names[(mn_environment.curr_pos-1)],2,10);
                songdata.pattern_names[(mn_environment.curr_pos-1)][9] := '';

                PATTERN_ORDER_page_refresh(pattord_page);
                PATTERN_page_refresh(pattern_page);
              end;
  end;

  nm_marked := _patts_marked;
  ShowCStr(v_ofs^,
           mn_environment.xpos+16,
           mn_environment.desc_pos,
           ' ~USED:'+
           ExpStrR(Num2str(_nm_patterns,10)+'/'+
                   Num2str(max_patterns,10)+'~ ',9,'Í'),
           menu_background+menu_border,
           menu_background+menu_context_dis);

  ShowCStr(v_ofs^,
           mn_environment.xpos+31,
           mn_environment.desc_pos,
           ' ~MARKED:'+
           ExpStrR(Num2str(nm_marked,10)+'~ ',5,'Í'),
           menu_background+menu_border,
           menu_background+menu_context_dis);

  mn_environment.do_refresh := TRUE;
  mn_environment.refresh;
end;

function PATTERN_LIST(page: Byte): Byte;

const
  new_keys: array[1..8] of Word = (kESC,kENTER,kF1,kF2,kCtrlS,
                                   kF3,kCtrlL,kShF3);

  var
  temp: Byte;
  old_keys: array[1..8] of Word;
  temp_marks: array[0..$7f] of Char;
  crc2: Longint;

label _jmp1;

begin
  For temp := 0 to $7f do
    begin
      temp_marks[temp] := songdata.pattern_names[temp][1];
      songdata.pattern_names[temp][1] := ' ';
      songdata.pattern_names[temp][9] := '';
    end;

  songdata_crc := Update32(songdata.pattern_names,SizeOf(songdata.pattern_names),0);
  songdata_crc := Update32(pattdata^,SizeOf(pattdata^),songdata_crc);
  For temp := 0 to $7f do
    songdata.pattern_names[temp][1] := temp_marks[temp];

_jmp1:
  If _force_program_quit then EXIT;
  
  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(pattern_page);
  _nm_patterns := 0;
  For temp := 0 to PRED(max_patterns) do
    If NOT Empty(pattdata^[temp DIV 8][temp MOD 8],PATTERN_SIZE) then
      begin
        songdata.pattern_names[temp][9] := '';
        Inc(_nm_patterns);
      end
    else songdata.pattern_names[temp][9] := '';

  Move(mn_setting.terminate_keys,old_keys,SizeOf(old_keys));
  Move(new_keys,mn_setting.terminate_keys,SizeOf(new_keys));

  mn_setting.center_box    := TRUE;
  mn_setting.cycle_moves   := FALSE;
  mn_environment.edit_pos  := 11;
  mn_setting.edit_contents := TRUE;
  mn_environment.ext_proc  := pattern_list__proc;
  mn_setting.terminate_keys[3] := kF1;
  pattern_list__page := Menu(songdata.pattern_names,0,0,page,42,MAX_PATTERN_ROWS+4,max_patterns,' PATTERN LiST ');
  page := pattern_list__page;

  Move(old_keys,mn_setting.terminate_keys,SizeOf(old_keys));
  mn_setting.edit_contents := FALSE;
  mn_environment.ext_proc  := NIL;
  mn_setting.terminate_keys[3] := 0;

  Case mn_environment.keystroke of
    kF1: begin
           HELP('pattern_list');
           GOTO _jmp1;
         end;

    kF2,
    kCtrlS: begin
              quick_cmd := FALSE;
              pattern2use := pattern_list__page-1;
              FILE_save('a2p');
              pattern2use := NULL;
              GOTO _jmp1;
            end;

    kF3,
    kShF3,
    kCtrlL: begin
              If (mn_environment.keystroke = kShF3) then quick_cmd := TRUE;
              pattern2use := pattern_list__page-1;
              FILE_open('*.a2p$');
              pattern2use := NULL;
              quick_cmd := FALSE;
              GOTO _jmp1;
            end;
  end;

  For temp := 0 to $7f do
    begin
      temp_marks[temp] := songdata.pattern_names[temp][1];
      songdata.pattern_names[temp][1] := ' ';
      songdata.pattern_names[temp][9] := '';
    end;

  crc2 := Update32(songdata.pattern_names,SizeOf(songdata.pattern_names),0);
  If (Update32(pattdata^,SizeOf(pattdata^),crc2) <> songdata_crc) then
    module_archived := FALSE;

  For temp := 0 to $7f do
    songdata.pattern_names[temp][1] := temp_marks[temp];

  If (mn_environment.keystroke <> kESC) then PATTERN_LIST := pattern_list__page
  else PATTERN_LIST := NULL;
end;

function PATTERN_LIST_alt(page: Byte): Byte;

const
  obj_name: array[tCOPY_OBJECT] of String[10] = (
    '',
    '','',
    '','',
    'NOTE','iNSTRUMENT','1ST EFFECT','2ND EFFECT',
    'LiNE','TRACK','PATTERN','BLOCK',
    '','','',
    '');

var
  temp: Byte;

label _jmp1;

begin
  If NOT (clipboard.object_type in [objNote,objInstrumentDef,objEffect,objEffect2,
                                    objLine,objTrack,objPattern,objMarkedBlock]) then
    begin
      PATTERN_LIST_alt := NULL;
      EXIT;
    end;

  _nm_patterns := 0;
  For temp := 0 to PRED(max_patterns) do
    If NOT Empty(pattdata^[temp DIV 8][temp MOD 8],PATTERN_SIZE) then
      begin
        songdata.pattern_names[temp][9] := '';
        Inc(_nm_patterns);
      end
    else songdata.pattern_names[temp][9] := '';

_jmp1:
  If _force_program_quit then EXIT;

  mn_setting.center_box    := TRUE;
  mn_setting.cycle_moves   := FALSE;
  mn_environment.ext_proc  := pattern_list__proc;
  mn_setting.terminate_keys[3] := kF1;
  pattern_list__page := Menu(songdata.pattern_names,0,0,page,42,22,max_patterns,
                             ' PATTERN LiST | PASTE "'+obj_name[clipboard.object_type]+'" ');

  mn_environment.ext_proc := NIL;
  mn_setting.terminate_keys[3] := 0;
  If (mn_environment.keystroke = kF1) then
    begin
      HELP('pattern_list');
      GOTO _jmp1;
    end;

  If (mn_environment.keystroke <> kESC) then PATTERN_LIST_alt := pattern_list__page
  else PATTERN_LIST_alt := NULL;
end;

procedure PATTERN_ORDER_page_refresh(page: Byte);

var
  attr: Word;
  temp1,temp2: Byte;
  xstart: Byte;

begin
  show_str(25+6+PATTORD_xshift+(MAX_ORDER_COLS*7-1) DIV 2+(MAX_ORDER_COLS*7-1) MOD 2,02,
           byte2hex(pattord_vpos+4*(pattord_hpos+pattord_page-1)-1),
           order_background+order_border);

  xstart := 20+PATTORD_xshift;  
  For temp1 := 1 to MAX_ORDER_COLS do
    For temp2 := 03 to 06 do
      begin
        If NOT tracing or
           play_single_patt then
          begin
            If (songdata.pattern_order[temp2-2+4*(temp1+page-1)-1] < $80) then
              attr := concw(order_background+order_hi_pattn,order_background+order_hi_entry)
            else attr := concw(order_background+order_entry,order_background+order_hi_entry);
          end
        else begin
               If (current_order = temp2-2+4*(temp1+page-1)-1) then
                 attr := concw(order_hi_bckg+order_hi_pattn,order_hi_bckg+order_hi_entry)
               else If (songdata.pattern_order[temp2-2+4*(temp1+page-1)-1] < $80) then
                      attr := concw(order_background+order_pattn,order_background+order_entry)
                    else attr := concw(order_background+order_pattn_jump,order_background+order_entry);
             end;

        If (songdata.pattern_order[temp2-2+4*(temp1+page-1)-1] < $80) then
          begin
            If (current_order = temp2-2+4*(temp1+page-1)-1) and
               (play_status <> isStopped) then
              show_cstr(xstart+pos1[temp1]-1,temp2,
                        byte2hex(temp2-2+4*(temp1+page-1)-1)+'~ ~',
                        order_played_b+order_played,HI(attr))
            else
              show_str(xstart+pos1[temp1]-1,temp2,
                       byte2hex(temp2-2+4*(temp1+page-1)-1)+' ',HI(attr));

            If NOT no_trace_pattord then
              show_str(xstart+pos1[temp1]-1+3,temp2,
                       byte2hex(songdata.pattern_order[temp2-2+4*(temp1+page-1)-1]),LO(attr));

            If NOT tracing then
              If (temp1 <= MAX_ORDER_COLS-1) then
                show_str(xstart+pos1[temp1]-1+5,temp2,'ð',order_background+order_border);
          end
        else
          begin
            show_str(xstart+pos1[temp1]-1,temp2,
                     byte2hex(temp2-2+4*(temp1+page-1)-1)+' ',HI(attr));

            If NOT no_trace_pattord then
              show_str(xstart+pos1[temp1]-1+3,temp2,
                       byte2hex(songdata.pattern_order[temp2-2+4*(temp1+page-1)-1]-$80),LO(attr));

            If NOT tracing then
              If (temp1 <= MAX_ORDER_COLS-1) then
                show_str(xstart+pos1[temp1]-1+5,temp2,'ð',order_background+order_border);
          end;
      end;

  temp1 := 0;
  If tracing then count_order(temp1);
  If scroll_bars then
    begin
      If (sdl_screen_mode <> 2) then
        If (temp1 <> 0) then
          scroll_pos0 := vscroll_bar(MAX_COLUMNS-2,02,6,temp1,
                            (page+pattord_hpos-1)*4+pattord_vpos,scroll_pos0,
                             scrollbar_bckg+scrollbar_text,
                             scrollbar_bckg+scrollbar_mark)
        else
          scroll_pos0 := vscroll_bar(MAX_COLUMNS-2,02,6,1,1,$0ff,
                                     scrollbar_bckg+scrollbar_text,
                                     scrollbar_bckg+scrollbar_mark);

      scroll_pos1 := vscroll_bar(MAX_COLUMNS-1,02,6,$7f,
                        (page+pattord_hpos-1)*4+pattord_vpos,scroll_pos1,
                         scrollbar_bckg+scrollbar_text,
                         scrollbar_bckg+scrollbar_2nd_mark);
    end
  else
    begin
      If (sdl_screen_mode <> 2) then
        scroll_pos0 := vscroll_bar(MAX_COLUMNS-2,02,6,1,1,$0ff,
                                   scrollbar_bckg+scrollbar_text,
                                   scrollbar_bckg+scrollbar_mark);
      scroll_pos1 := vscroll_bar(MAX_COLUMNS-1,02,6,1,1,$0ff,
                                 scrollbar_bckg+scrollbar_text,
                                 scrollbar_bckg+scrollbar_mark);
    end;
end;

procedure PATTERN_ORDER_edit(var page,hpos,vpos: Byte);

var
  nope: Boolean;
  tstr,temps: String;
  temp{,temp2}: Byte;
  temp1: Word;
  xstart: Byte;

procedure copy_object;
begin
  Case clipboard.object_type of
    objPatternDef:
      clipboard.pattern_order[0] :=
        songdata.pattern_order[(page+hpos-1)*4+vpos-1];

    objPatternTable:
      Move(songdata.pattern_order,
           clipboard.pattern_order,SizeOf(songdata.pattern_order));
  end;
end;

procedure paste_object;
begin
  Case clipboard.object_type of
    objPatternDef:
      begin
        songdata.pattern_order[(page+hpos-1)*4+vpos-1] :=
          clipboard.pattern_order[0];
        If vpos < 4 then Inc(vpos)
        else If hpos < MAX_ORDER_COLS then begin Inc(hpos); vpos := 1; end
             else If page < (23-(MAX_ORDER_COLS-9)) then begin Inc(page); vpos := 1; end;
      end;

    objPatternTable:
      Move(clipboard.pattern_order,
           songdata.pattern_order,SizeOf(songdata.pattern_order));
  end;
end;

label _end;

begin { PATTERN_ORDER_edit }
  songdata_crc_ord := Update32(songdata.pattern_order,
                               SizeOf(songdata.pattern_order),0);
  Repeat
    keyboard_poll_input;
    PATTERN_ORDER_page_refresh(page);
    PATTERN_page_refresh(pattern_page);
    
    xstart := 23+PATTORD_xshift;   
    GotoXY(xstart+pos1[hpos]-1,03+vpos-1);

    If tracing then fkey := PATTERN_trace
	else ThinCursor;

    If (scankey(SC_LCTRL) or scankey(SC_RCTRL)) { CTRL } and
       (scankey(SC_LALT) or scankey(SC_RALT)) { ALT } then
      begin
        DEBUG_INFO;
        PATTERN_ORDER_page_refresh(pattord_page);
        PATTERN_page_refresh(pattern_page);
      end;

    nope := FALSE;
    If keypressed then fkey := getkey else goto _end; //CONTINUE;

    Case fkey of
      kLEFT:   If hpos > 1 then Dec(hpos) else If page > 0  then Dec(page);
      kRIGHT:  If hpos < MAX_ORDER_COLS then Inc(hpos) else If page < (23-(MAX_ORDER_COLS-9)) then Inc(page);

      kUP,
      kShTAB:  If vpos > 1 then Dec(vpos)
               else If hpos > 1 then begin Dec(hpos); vpos := 4; end
                    else If page > 0 then begin Dec(page); vpos := 4; end;

      kDOWN,
      kTAB:    If vpos < 4 then Inc(vpos)
               else If hpos < MAX_ORDER_COLS then begin Inc(hpos); vpos := 1; end
                    else If page < (23-(MAX_ORDER_COLS-9)) then begin Inc(page); vpos := 1; end;

      kPgUP:   If page-8 > 0 then Dec(page,8) else
                 begin
                   If page > 0 then page := 0
                   else begin page := 0; hpos := 1; vpos := 1; end;
                 end;

      kPgDOWN: If page+8 < (23-(MAX_ORDER_COLS-9)) then Inc(page,8) else
                 begin
                   If page < (23-(MAX_ORDER_COLS-9)) then page := (23-(MAX_ORDER_COLS-9))
                   else begin page := (23-(MAX_ORDER_COLS-9)); hpos := MAX_ORDER_COLS; vpos := 4; end;
                 end;

      kHOME:   begin page := 0;  hpos := 1; vpos := 1; end;
      kEND:    begin page := (23-(MAX_ORDER_COLS-9)); hpos := MAX_ORDER_COLS; vpos := 4; end;

      kCHmins,
      kNPmins: If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $80) then
                 If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] > 0) then
                   Dec(songdata.pattern_order[vpos+4*(hpos+page-1)-1])
                 else
               else
                 If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] > $80) then
                   Dec(songdata.pattern_order[vpos+4*(hpos+page-1)-1]);
      kCHplus,
      kNPplus: If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $80) then
                 If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $7f) then
                   Inc(songdata.pattern_order[vpos+4*(hpos+page-1)-1])
                 else
               else
                 If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $ff) then
                   begin
                     If (vpos+4*(hpos+page-1)-1 = 0) and
                        (songdata.pattern_order[vpos+4*(hpos+page-1)-1] = $80) then
                       songdata.pattern_order[vpos+4*(hpos+page-1)-1] := 0
                     else
                       Inc(songdata.pattern_order[vpos+4*(hpos+page-1)-1]);
                   end;
      kNPastr: begin
                 For temp := 1 to songdata.nm_tracks do
                   begin
                     channel_flag[temp] := NOT channel_flag[temp];
                     If NOT channel_flag[temp] then reset_chan_data(temp);
                   end;
               end;

      kBkSPC:  begin
                 songdata.pattern_order[vpos+4*(hpos+page-1)-1] := $80;
                 Case backspace_dir of
                   1: If (vpos < 4) then Inc(vpos)
                      else If (hpos < MAX_ORDER_COLS) then begin vpos := 1; Inc(hpos); end
                           else If (page < (23-(MAX_ORDER_COLS-9))) then begin hpos := MAX_ORDER_COLS; Inc(page); vpos := 1; end;
                   2: If (vpos > 1) then Dec(vpos)
                      else If (hpos > 1) then begin Dec(hpos); vpos := 4; end
                           else If (page > 0) then begin Dec(page); vpos := 4; end;
                 end;
               end;

      kSPACE: If ctrl_pressed then
                If (vpos+4*(hpos+page-1)-1 < $7f) then
                  begin
                    songdata.pattern_order[vpos+4*(hpos+page-1)-1] := $80+vpos+4*(hpos+page-1);
                    If (vpos < 4) then Inc(vpos)
                    else If (hpos < MAX_ORDER_COLS) then begin vpos := 1; Inc(hpos); end
                         else If (page < (23-(MAX_ORDER_COLS-9))) then begin hpos := MAX_ORDER_COLS; Inc(page); vpos := 1; end;
                  end
                else
                  begin
                    songdata.pattern_order[vpos+4*(hpos+page-1)-1] := $80;
                    If (vpos < 4) then Inc(vpos)
                    else If (hpos < MAX_ORDER_COLS) then begin vpos := 1; Inc(hpos); end
                         else If (page < (23-(MAX_ORDER_COLS-9))) then begin hpos := MAX_ORDER_COLS; Inc(page); vpos := 1; end;
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

      kAltS:   begin
                 For temp := 1 to songdata.nm_tracks do
                   If (temp <> count_channel(pattern_hpos)) then
                     begin
                       channel_flag[temp] := FALSE;
                       reset_chan_data(temp);
                     end
                   else channel_flag[temp] := TRUE;
               end;

      kAltR:   FillChar(channel_flag,songdata.nm_tracks,BYTE(TRUE));
      kAlt1..
      kAlt0:   If (fkey <> kAlt0) then
                 begin
                   If (HI(fkey)-$77 <= songdata.nm_tracks) then
                     begin
                       channel_flag[HI(fkey)-$77] := NOT channel_flag[HI(fkey)-$77];
                       If NOT channel_flag[HI(fkey)-$77] then reset_chan_data(HI(fkey)-$77);
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
                            end;
                        end;
                    end;

      kINSERT: begin
                 For temp := $7f downto (page+hpos-1)*4+vpos do
                   songdata.pattern_order[temp] := songdata.pattern_order[temp-1];
                 songdata.pattern_order[(page+hpos-1)*4+vpos-1] := 0;
               end;

      kDELETE: begin
                 For temp := (page+hpos-1)*4+vpos-1 to $7f-1 do
                   songdata.pattern_order[temp] := songdata.pattern_order[temp+1];
                 songdata.pattern_order[$7f] := $080;
               end;

      kCtrlC:  begin
                 clipboard.object_type := objPatternDef;
                 copy_object;
               end;

      kAltC:   begin
                 mn_setting.cycle_moves := TRUE;
                 temp := Menu(copymnu3,01,01,copypos3,30,15,15,' COPY OBJECT ');
                 If (mn_environment.keystroke <> kESC) then
                   begin
                     copypos3 := temp;
                     clipboard.object_type := tCOPY_OBJECT(temp);
                     copy_object;
                   end;
               end;
      kAltP,
      kCtrlV:  paste_object;

      kCtrlT:  TRANSPOSE;
      kCtrlR:  REMAP;
      kCtrlO:  OCTAVE_CONTROL;
      kCtrlP:  PATTERN_LIST(pattern_list__page);
      kCtrlF:  SONG_VARIABLES;
      kCtrlH:  REPLACE;
      kCtrlI:  INSTRUMENT_CONTROL;
      kCtrlQ:  MACRO_EDITOR(current_inst,FALSE);
      kCtrlE:  MACRO_EDITOR(current_inst,TRUE);

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

      kF1:     HELP('pattern_order');
      kF2,
      kShF2,
      kCtrlS:  begin
                 If (fkey = kShF2) then quick_cmd := TRUE;
                 FILE_save('a2m');
                 quick_cmd := FALSE;
               end;

      kCtrlF2: FILE_save('a2t');

      kF3,
      kCtrlL:  FILE_open('*.a2m$*.a2t$*.amd$*.cff$*.dfm$*.fmk$*.hsc$*.mtk$*.rad$'+
                         '*.s3m$*.sat$*.sa2$*.xms$');
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
                       (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $80) and
                       (calc_pattern_pos(songdata.pattern_order[vpos+4*(hpos+page-1)-1]) <> NULL) then
                      begin
                        fade_out_playback(FALSE);
                        calibrate_player(vpos+4*(hpos+page-1)-1,0,TRUE,FALSE);
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
                      end;

      kF7:     If (play_status <> isStopped) then
                 begin
                   fade_out_playback(FALSE);
                   stop_playing;
                   FillData(ai_table,SizeOf(ai_table),0);
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

                   isStopped: If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $80) and
                                 (calc_pattern_pos(songdata.pattern_order[vpos+4*(hpos+page-1)-1]) <> NULL) then
                                begin
                                  debugging := FALSE;
                                  If (NOT nosync_by_default and (fkey = kAltF8)) or
                                     (nosync_by_default and (fkey = kF8)) then
                                    no_sync_playing := TRUE;

                                  calibrate_player(vpos+4*(hpos+page-1)-1,0,TRUE,FALSE);
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

                   isStopped: If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $80) and
                                 (calc_pattern_pos(songdata.pattern_order[vpos+4*(hpos+page-1)-1]) <> NULL) then
                                begin
                                  debugging := FALSE;
                                  If (NOT nosync_by_default and (fkey = kAltF9)) or
                                     (nosync_by_default and (fkey = kF9)) then
                                    no_sync_playing := TRUE;

                                  calibrate_player(vpos+4*(hpos+page-1)-1,0,TRUE,FALSE);
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

      kF10,
      kESC:    begin QUIT_request; If (fkey = kESC) then nope := TRUE; end;
      kENTER:  nope := TRUE;
      else     nope := TRUE;
    end;

    If nope and (UpCase(CHAR(LO(fkey))) in ['0'..'9','A'..'F']) then
      begin
        no_trace_pattord := TRUE;
        nope := FALSE;
        is_setting.append_enabled := FALSE;
        is_setting.character_set  := ['0'..'9','a'..'f','A'..'F'];
        is_environment.locate_pos := 2;
        is_setting.terminate_keys[3] := kUp;
        is_setting.terminate_keys[4] := kDown;
        is_setting.terminate_keys[5] := kTAB;
        is_setting.terminate_keys[6] := kShTAB;
        tstr := CHAR(LO(fkey));

        Repeat
          tstr := ExpStrL(InputStr(tstr,xstart+pos1[hpos]-1,03+vpos-1,
                          2,2,order_input_bckg+order_input,
                              order_input_warn+order_input),2,'0');
          is_setting.append_enabled := TRUE;

          If (Str2num(tstr,16) in [0..$0ff]) and
             (is_environment.keystroke <> kESC) then
            begin
              If (Str2num(tstr,16) > $7f) and
                 (Str2num(tstr,16)-$80 = vpos+4*(hpos+page-1)-1) then goto _end; //CONTINUE;
              nope := TRUE;
              songdata.pattern_order[vpos+4*(hpos+page-1)-1] :=
                                     Str2num(tstr,16);
              If (is_environment.keystroke = kENTER) then
                If (vpos < 4) then Inc(vpos)
                else If hpos < MAX_ORDER_COLS then begin vpos := 1; Inc(hpos); end
                     else If page < (23-(MAX_ORDER_COLS-9)) then begin hpos := MAX_ORDER_COLS; Inc(page); vpos := 1; end;
            end;
        until (is_environment.keystroke = kESC) or
              (is_environment.keystroke = kUp) or
              (is_environment.keystroke = kDown) or
              (is_environment.keystroke = kTAB) or
              (is_environment.keystroke = kShTAB) or nope;

        no_trace_pattord := FALSE;
        nope := FALSE;
        Case is_environment.keystroke of
          kUP,
          kShTAB:  If vpos > 1 then Dec(vpos)
                   else If hpos > 1 then begin Dec(hpos); vpos := 4; end
                        else If page > 0 then begin Dec(page); vpos := 4; end;
          kDOWN,
          kTAB:    If vpos < 4 then Inc(vpos)
                   else If hpos < MAX_ORDER_COLS then begin Inc(hpos); vpos := 1; end
                        else If page < (23-(MAX_ORDER_COLS-9)) then begin Inc(page); vpos := 1; end;
        end;

        is_setting.terminate_keys[3] := 0;
        is_setting.terminate_keys[4] := 0;
        is_setting.terminate_keys[5] := 0;
        is_setting.terminate_keys[6] := 0;
      end;


    keyboard_reset_buffer;

    If (Update32(songdata.pattern_order,SizeOf(songdata.pattern_order),0) <> songdata_crc_ord) then
      module_archived := FALSE;
_end:
    emulate_screen;
  until (nope and ((fkey = kENTER) or (fkey = kESC) or (fkey = kF10))) or _force_program_quit;
  PATTERN_ORDER_page_refresh(page);
end;
