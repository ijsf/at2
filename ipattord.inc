//  This file is part of Adlib Tracker II (AT2).
//
//  AT2 is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  AT2 is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with AT2.  If not, see <http://www.gnu.org/licenses/>.

{
        procedure pattern_list__proc;
        procedure PATTERN_LIST(page: Byte);
        function  PATTERN_LIST_alt(page: Byte): Byte;
        procedure PATTERN_ORDER_page_refresh(page: Byte);
        procedure PATTERN_ORDER_edit(var page,hpos,vpos: Byte);
}

var
  _nm_patterns: Byte;

procedure pattern_list__proc;

var
  chunk: tCHUNK;
  temp,temp1,temp2,
  _1st,_2nd: Byte;
  temps: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'IPATTORD.INC:pattern_list__proc';
{$ENDIF}
  Case mn_environment.keystroke of
    kSPACE:
      If ctrl_pressed then
        For temp := 0 to $7f do
          If NOT shift_pressed then songdata.pattern_names[temp][1] := ' '
          else If (songdata.pattern_names[temp][1] <> ' ') then
                 songdata.pattern_names[temp][1] := ' '
               else songdata.pattern_names[temp][1] := #16
      else If (songdata.pattern_names[mn_environment.curr_pos-1][1] <> #16) then
             songdata.pattern_names[mn_environment.curr_pos-1][1] := #16
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
    kAltV,
    kCtrlV: If (clipboard.object_type = objPattern) then
              begin
                For temp2 := 0 to PRED(songdata.patt_len) do
                  For temp1 := 1 to songdata.nm_tracks do
                    begin
                      If (mn_environment.keystroke <> kAltV) then
                        put_chunk(mn_environment.curr_pos-1,temp2,temp1,
                                  clipboard.pattern[temp1][temp2]);
                      If NOT (shift_pressed and (mn_environment.keystroke = kCtrlV)) then
                        songdata.pattern_names[mn_environment.curr_pos-1] :=
                          Copy(songdata.pattern_names[mn_environment.curr_pos-1],1,8)+
                          clipboard._string;
                    end;

                If NOT Empty(pattdata^[(mn_environment.curr_pos-1) DIV 8]
                                      [(mn_environment.curr_pos-1) MOD 8],
                             PATTERN_SIZE) then
                  begin
                    songdata.pattern_names[mn_environment.curr_pos-1][9] := #15;
                    Inc(_nm_patterns);
                  end
                else songdata.pattern_names[mn_environment.curr_pos-1][9] := #14;

                PATTERN_ORDER_page_refresh(pattord_page);
                PATTERN_page_refresh(pattern_page);
              end;

    kCtrlN: If NOT shift_pressed then
              For temp2 := 0 to PRED(songdata.patt_len) do
                For temp1 := 1 to songdata.nm_tracks do
                  begin
                    FillChar(chunk,SizeOf(chunk),0);
                    put_chunk(mn_environment.curr_pos-1,temp2,temp1,chunk);
                  end
            else
              For temp := 0 to $7f do
                If (songdata.pattern_names[temp][1] = #16) then
                  For temp2 := 0 to PRED(songdata.patt_len) do
                    For temp1 := 1 to songdata.nm_tracks do
                      begin
                        FillChar(chunk,SizeOf(chunk),0);
                        put_chunk(temp,temp2,temp1,chunk);
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
                     buf1,
                     PATTERN_SIZE);

                temps := Copy(songdata.pattern_names[_1st],9,33);
                Move(pattdata^[_2nd DIV 8][_2nd MOD 8],
                     pattdata^[_1st DIV 8][_1st MOD 8],
                     PATTERN_SIZE);

                If shift_pressed then
                  songdata.pattern_names[_1st] :=
                    Copy(songdata.pattern_names[_1st],1,8)+
                    Copy(songdata.pattern_names[_2nd],9,33);

                Move(buf1,
                     pattdata^[_2nd DIV 8][_2nd MOD 8],
                     PATTERN_SIZE);

                If shift_pressed then
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

                FillChar(pattdata^[PRED(max_patterns) DIV 8][PRED(max_patterns) MOD 8],
                         PATTERN_SIZE,0);
                songdata.pattern_names[PRED(max_patterns)] :=
                  ' '+
                  Copy(songdata.pattern_names[PRED(max_patterns)],2,10);
                songdata.pattern_names[PRED(max_patterns)][9] := #14;

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

                FillChar(pattdata^[(mn_environment.curr_pos-1) DIV 8]
                                  [(mn_environment.curr_pos-1) MOD 8],
                         PATTERN_SIZE,0);
                songdata.pattern_names[(mn_environment.curr_pos-1)] :=
                  ' '+
                  Copy(songdata.pattern_names[(mn_environment.curr_pos-1)],2,10);
                songdata.pattern_names[(mn_environment.curr_pos-1)][9] := #14;

                PATTERN_ORDER_page_refresh(pattord_page);
                PATTERN_page_refresh(pattern_page);
              end;
  end;

  ShowC3Str(screen_ptr,
           mn_environment.xpos+13,
           mn_environment.desc_pos,
           ' [`USED`:~'+
           ExpStrL(Num2str(_nm_patterns,10)+'~/'+
                   Num2str(max_patterns,10),8,' ')+']'+
           ' [`MARKED`:~'+
           ExpStrL(Num2str(_patts_marked,10),3,' ')+'~] ',
           dialog_background+dialog_context_dis,
           dialog_background+dialog_context,
           dialog_background+dialog_border);

  If NOT ((play_status <> isStopped) and tracing) then
    begin
      pattern_patt := mn_environment.curr_pos-1;
      PATTERN_page_refresh(pattern_page);
    end;

  mn_environment.do_refresh := TRUE;
  mn_environment.refresh;
end;

procedure PATTERN_LIST(page: Byte);

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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'IPATTORD.INC:PATTERN_LIST';
{$ENDIF}
  For temp := 0 to $7f do
    begin
      temp_marks[temp] := songdata.pattern_names[temp][1];
      songdata.pattern_names[temp][1] := ' ';
      songdata.pattern_names[temp][9] := #14;
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
        songdata.pattern_names[temp][9] := #15;
        Inc(_nm_patterns);
      end
    else songdata.pattern_names[temp][9] := #14;

  Move(mn_setting.terminate_keys,old_keys,SizeOf(old_keys));
  Move(new_keys,mn_setting.terminate_keys,SizeOf(new_keys));

  mn_setting.center_box    := TRUE;
  mn_setting.cycle_moves   := FALSE;
  mn_environment.edit_pos  := 11;
  mn_setting.edit_contents := TRUE;
  mn_environment.ext_proc  := pattern_list__proc;
  mn_setting.terminate_keys[3] := kF1;
  mn_environment.hlight_chrs := 1;
  pattern_list__page := Menu(songdata.pattern_names,0,0,page,42,MAX_PATTERN_ROWS+4,max_patterns,' PATTERN LiST ');

  Move(old_keys,mn_setting.terminate_keys,SizeOf(old_keys));
  mn_setting.edit_contents := FALSE;
  mn_environment.ext_proc  := NIL;
  mn_setting.terminate_keys[3] := 0;
  mn_environment.hlight_chrs := 0;

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
              pattern2use := BYTE_NULL;
              GOTO _jmp1;
            end;

    kF3,
    kShF3,
    kCtrlL: begin
              If (mn_environment.keystroke = kShF3) then quick_cmd := TRUE;
              pattern2use := pattern_list__page-1;
              FILE_open('*.a2p$',FALSE);
              pattern2use := BYTE_NULL;
              quick_cmd := FALSE;
              GOTO _jmp1;
            end;
  end;

  For temp := 0 to $7f do
    begin
      temp_marks[temp] := songdata.pattern_names[temp][1];
      songdata.pattern_names[temp][1] := ' ';
      songdata.pattern_names[temp][9] := #14;
    end;

  crc2 := Update32(songdata.pattern_names,SizeOf(songdata.pattern_names),0);
  If (Update32(pattdata^,SizeOf(pattdata^),crc2) <> songdata_crc) then
    module_archived := FALSE;

  For temp := 0 to $7f do
    songdata.pattern_names[temp][1] := temp_marks[temp];
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'IPATTORD.INC:PATTERN_LIST_alt';
{$ENDIF}
  If NOT (clipboard.object_type in [objNote,objInstrumentDef,objEffect,objEffect2,
                                    objLine,objTrack,objPattern,objMarkedBlock]) then
    begin
      PATTERN_LIST_alt := BYTE_NULL;
      EXIT;
    end;

  _nm_patterns := 0;
  For temp := 0 to PRED(max_patterns) do
    If NOT Empty(pattdata^[temp DIV 8][temp MOD 8],PATTERN_SIZE) then
      begin
        songdata.pattern_names[temp][9] := #15;
        Inc(_nm_patterns);
      end
    else songdata.pattern_names[temp][9] := #14;

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
  else PATTERN_LIST_alt := BYTE_NULL;
end;

procedure PATTERN_ORDER_page_refresh(page: Byte);

var
  attr: Word;
  temp1,temp2: Byte;
  xstart: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'IPATTORD.INC:PATTERN_ORDER_page_refresh';
{$ENDIF}
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
               (play_status <> isStopped) and NOT play_single_patt then
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
                show_str(xstart+pos1[temp1]-1+5,temp2,#240,order_background+order_border);
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
                show_str(xstart+pos1[temp1]-1+5,temp2,#240,order_background+order_border);
          end;
      end;

  temp1 := 0;
  If tracing then count_order(temp1);
  If scroll_bars then
    begin
      If (program_screen_mode <> 2) then
        If (temp1 <> 0) then
          scroll_pos0 := vscroll_bar(MAX_COLUMNS-2,02,6,temp1,
                                     (page+pattord_hpos-1)*4+pattord_vpos,scroll_pos0,
                                     scrollbar_bckg+scrollbar_text,
                                     scrollbar_bckg+scrollbar_mark)
      else
          scroll_pos0 := vscroll_bar(MAX_COLUMNS-2,02,6,1,1,BYTE_NULL,
                                     scrollbar_bckg+scrollbar_text,
                                     scrollbar_bckg+scrollbar_mark);

      scroll_pos1 := vscroll_bar(MAX_COLUMNS-1,02,6,$7f,
                                 (page+pattord_hpos-1)*4+pattord_vpos,scroll_pos1,
                                 scrollbar_bckg+scrollbar_text,
                                 scrollbar_bckg+scrollbar_2nd_mark);
    end
  else
    begin
      If (program_screen_mode <> 2) then
        scroll_pos0 := vscroll_bar(MAX_COLUMNS-2,02,6,1,1,BYTE_NULL,
                                   scrollbar_bckg+scrollbar_text,
                                   scrollbar_bckg+scrollbar_mark);
      scroll_pos1 := vscroll_bar(MAX_COLUMNS-1,02,6,1,1,BYTE_NULL,
                                 scrollbar_bckg+scrollbar_text,
                                 scrollbar_bckg+scrollbar_mark);
    end;
end;

procedure PATTERN_ORDER_edit(var page,hpos,vpos: Byte);

var
  nope: Boolean;
  tstr,temps: String;
  temp: Byte;
  temp1: Word;
  xstart: Byte;

procedure copy_object;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'IPATTORD.INC:PATTERN_ORDER_edit:copy_object';
{$ENDIF}
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'IPATTORD.INC:PATTERN_ORDER_edit:paste_object';
{$ENDIF}
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'IPATTORD.INC:PATTERN_ORDER_edit';
{$ENDIF}
  songdata_crc_ord := Update32(songdata.pattern_order,
                               SizeOf(songdata.pattern_order),0);
  Repeat
    PATTERN_ORDER_page_refresh(page);
    PATTERN_page_refresh(pattern_page);

    xstart := 23+PATTORD_xshift;
    GotoXY(xstart+pos1[hpos]-1,03+vpos-1);

    If tracing then fkey := PATTERN_trace
    else ThinCursor;

    If ctrl_pressed and alt_pressed then
      begin
        DEBUG_INFO;
        PATTERN_ORDER_page_refresh(pattord_page);
        PATTERN_page_refresh(pattern_page);
      end;

    nope := FALSE;
    If keypressed then fkey := getkey else GOTO _end; //CONTINUE;

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

      kAstrsk,
      kNPastr:
{$IFNDEF GO32V2}
               If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
{$ENDIF}
                 For temp := 1 to songdata.nm_tracks do
                   begin
                     channel_flag[temp] := NOT channel_flag[temp];
                     If NOT channel_flag[temp] then reset_chan_data(temp);
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

      kAltS:
{$IFNDEF GO32V2}
               If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
{$ENDIF}
                 begin
                   For temp := 1 to songdata.nm_tracks do
                     channel_flag[temp] := FALSE;
                   For temp := 1 to songdata.nm_tracks do
                     If (temp = count_channel(pattern_hpos)) then
                       begin
                         channel_flag[temp] := TRUE;
                         If is_4op_chan(temp) then
                           If (temp in _4op_tracks_hi) then channel_flag[SUCC(temp)] := TRUE
                           else channel_flag[PRED(temp)] := TRUE;
                       end;
                   For temp := 1 to songdata.nm_tracks do
                     If NOT channel_flag[temp] then reset_chan_data(temp);
                 end;

      kAltR:
{$IFNDEF GO32V2}
               If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
{$ENDIF}
                 FillChar(channel_flag,songdata.nm_tracks,BYTE(TRUE));
      kAlt1..
      kAlt0:
{$IFNDEF GO32V2}
               If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
{$ENDIF}
                 If (fkey <> kAlt0) then
                   begin
                     If shift_pressed then temp := HI(fkey)-$77+10
                     else temp := HI(fkey)-$77;
                     If (temp <= songdata.nm_tracks) then
                       begin
                         channel_flag[temp] := NOT channel_flag[temp];
                         If NOT channel_flag[temp] then reset_chan_data(temp);
                         If is_4op_chan(temp) then
                           If (temp in _4op_tracks_hi) then
                             begin
                               channel_flag[SUCC(temp)] := channel_flag[temp];
                               If NOT channel_flag[SUCC(temp)] then reset_chan_data(SUCC(temp));
                             end
                           else If (temp in _4op_tracks_lo) then
                                  begin
                                    channel_flag[PRED(temp)] := channel_flag[temp];
                                    If NOT channel_flag[PRED(temp)] then reset_chan_data(PRED(temp));
                                  end;
                       end;
                   end
                 else If shift_pressed or
                         (10 in [chan_pos..chan_pos+MAX_TRACKS-1]) or
                         (songdata.nm_tracks = 10) then
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
                 temp := Menu(copy_menu_str3,01,01,copypos3,30,15,15,' COPY OBJECT ');
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
      kCtrlB:  MESSAGE_BOARD;
      kCtrlD:  DEBUG_INFO;
      kCtrlO:  OCTAVE_CONTROL;

      kCtrlP:  If NOT ((play_status <> isStopped) and tracing) then
                 PATTERN_LIST(pattern_patt+1)
               else begin
                      PATTERN_LIST(old_pattern_patt+1);
                      old_pattern_patt := pattern_list__page-1;
                    end;

      kCtrlF:  SONG_VARIABLES;
      kCtrlH:  REPLACE;
      kCtrlI:  INSTRUMENT_CONTROL;
      kCtrlE:  INSTRUMENT_CONTROL_edit;
      kCtrlQ:  MACRO_EDITOR(current_inst,FALSE);
      kCtrlG:  MACRO_EDITOR(current_inst,TRUE);
      kCtrlM:  MACRO_BROWSER(TRUE,TRUE);
      kCtrlX:  REARRANGE;

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

{$IFDEF GO32V2}
      kF1:     HELP('pattern_order');
{$ELSE}
      kF1:     If (sdl_opl3_emulator = 1) and ((play_status = isPlaying) or opl3_channel_recording_mode) then HELP('wav_recorder')
               else HELP('pattern_order');
{$ENDIF}

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
                         '*.s3m$*.sat$*.sa2$*.xms$',FALSE);
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
                       (calc_pattern_pos(songdata.pattern_order[vpos+4*(hpos+page-1)-1]) <> BYTE_NULL) then
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

      kF7:     begin
                 fade_out_playback(FALSE);
                 stop_playing;
                 If (play_status <> isStopped) then FillChar(ai_table,SizeOf(ai_table),0);
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
                                  end
                                else If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $80) and
                                        (calc_pattern_pos(songdata.pattern_order[vpos+4*(hpos+page-1)-1]) <> BYTE_NULL) then
                                       begin
                                         stop_playing;
                                         calibrate_player(vpos+4*(hpos+page-1)-1,0,TRUE,FALSE);
                                       end;
                              end;

                   isStopped: If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $80) and
                                 (calc_pattern_pos(songdata.pattern_order[vpos+4*(hpos+page-1)-1]) <> BYTE_NULL) then
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
                                  end
                                else If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $80) and
                                        (calc_pattern_pos(songdata.pattern_order[vpos+4*(hpos+page-1)-1]) <> BYTE_NULL) then
                                       begin
                                         stop_playing;
                                         calibrate_player(vpos+4*(hpos+page-1)-1,0,TRUE,FALSE);
                                         repeat_pattern := TRUE;
                                       end;
                              end;

                   isStopped: If (songdata.pattern_order[vpos+4*(hpos+page-1)-1] < $80) and
                                 (calc_pattern_pos(songdata.pattern_order[vpos+4*(hpos+page-1)-1]) <> BYTE_NULL) then
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
        is_setting.character_set  := HEX_NUM_CHARSET;
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
                 (Str2num(tstr,16)-$80 = vpos+4*(hpos+page-1)-1) then
                is_environment.keystroke := WORD_NULL
              else nope := TRUE;
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

    If (Update32(songdata.pattern_order,SizeOf(songdata.pattern_order),0) <> songdata_crc_ord) then
      module_archived := FALSE;
_end:
{$IFDEF GO32V2}
    keyboard_reset_buffer_alt;
{$ELSE}
    draw_screen;
{$ENDIF}
    If scankey(SC_F11) and
       NOT ctrl_pressed and NOT alt_pressed and NOT shift_pressed then
      begin
        If (command_typing <> 0) then
          Case command_typing of
            1: If cycle_pattern then
                 begin
                   command_typing := 2;
                   cycle_pattern := FALSE;
                 end
               else cycle_pattern := TRUE;

            2: begin
                 command_typing := 1;
                 cycle_pattern := FALSE;
               end;
          end;
        status_refresh;
        wait_until_F11_F12_released;
        keyboard_reset_buffer;
      end;

    If scankey(SC_F12) and
       NOT ctrl_pressed and NOT alt_pressed then
      begin
        If NOT shift_pressed then
          linefeed := NOT linefeed
        else jump_mark_mode := NOT jump_mark_mode;
        status_refresh;
        wait_until_F11_F12_released;
        keyboard_reset_buffer;
      end;
  until (nope and ((fkey = kENTER) or (fkey = kESC) or (fkey = kF10))) or _force_program_quit;
  PATTERN_ORDER_page_refresh(page);
end;
