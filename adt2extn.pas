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

unit AdT2extn;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

const
  remap_mtype:         Byte = 1;
  remap_ins1:          Byte = 1;
  remap_ins2:          Byte = 1;
  remap_selection:     Byte = 1;
  rearrange_selection: Byte = 1;
  replace_selection:   Byte = 1;
  replace_prompt:      Boolean = FALSE;
  replace_data:        Record
                         event_to_find: Record
                                          note: String[3];
                                          inst: String[2];
                                          fx_1: String[3];
                                          fx_2: String[3];
                                        end;

                         new_event: Record
                                      note: String[3];
                                      inst: String[2];
                                      fx_1: String[3];
                                      fx_2: String[3];
                                    end;
                       end = (

    event_to_find: (note: '???'; inst: '??'; fx_1: '???'; fx_2: '???');
    new_event:     (note: '???'; inst: '??'; fx_1: '???'; fx_2: '???'));

var
  fkey: Word;

var
  progress_xstart,progress_ystart: Byte;
  progress_num_steps: Byte;
  progress_step: Byte;
  progress_value: Dword;
  progress_old_value,progress_new_value: Byte;

var
  tracing_block_pattern,
  tracing_block_xend,
  tracing_block_yend: Byte;

const
  copypos1: Byte = 1;
  copypos2: Byte = 1;
  copypos3: Byte = 1;
  copypos4: Byte = 1;
  clearpos: Byte = 1;
  pattern_list__page: Byte = 1;
  pattern2use: Byte = BYTE(NOT 0);

type
  tTRANSPOSE_TYPE = (ttTransposeUp,ttTransposeDown,
                     ttTransposeCurrentIns,ttTransposeAllIns);

function _patts_marked: Byte;

procedure nul_volume_bars;
procedure transpose_custom_area(type1,type2: tTRANSPOSE_TYPE;
                                patt0,patt1,track0,track1,line0,line1: Byte;
                                factor: Byte);
procedure TRANSPOSE;
procedure REMAP;
procedure REARRANGE;
procedure REPLACE;
procedure POSITIONS_reset;
procedure DEBUG_INFO;
procedure LINE_MARKING_SETUP;
procedure OCTAVE_CONTROL;
procedure SONG_VARIABLES;
procedure FILE_save(ext: String);
function  FILE_open(masks: String; loadBankPossible: Boolean): Byte;
procedure NUKE;
procedure MESSAGE_BOARD;
procedure QUIT_request;
procedure show_progress(value: Longint); overload;
procedure show_progress(value,refresh_dif: Longint); overload;

implementation

uses
{$IFNDEF UNIX}
  CRT,
{$ENDIF}
{$IFNDEF GO32V2}
  SDL_Timer,
{$ENDIF}
  StrUtils,
  AdT2opl3,AdT2sys,AdT2keyb,AdT2unit,AdT2ext2,AdT2ext3,AdT2ext4,AdT2ext5,AdT2text,AdT2pack,
  StringIO,DialogIO,ParserIO,TxtScrIO,MenuLib1,MenuLib2;

function _patts_marked: Byte;

var
  temp,
  result: Byte;

begin
  result := 0;
  For temp := 0 to $7f do
    If (songdata.pattern_names[temp][1] = #16) then
      Inc(result);
  _patts_marked := result;
end;

procedure nul_volume_bars;

var
  chan: Byte;

begin
  For chan := chan_pos to chan_pos+MAX_TRACKS-1 do
    If channel_flag[chan] then
      show_str(08+(chan-PRED(chan_pos)-1)*15,MAX_PATTERN_ROWS+11,
               ExpStrR('',14,#205),
               pattern_bckg+pattern_border);
end;

const
  transp_menu2: Boolean = FALSE;
  transp_pos1: Byte = 1;
  transp_pos2: Byte = 1;

procedure transpose_custom_area(type1,type2: tTRANSPOSE_TYPE;
                                patt0,patt1,track0,track1,line0,line1: Byte;
                                factor: Byte);
var
  skip_all,erase_all: Boolean;
  _1st_choice: Byte;
  _break,_continue: Boolean;
  chunk: tCHUNK;
  temp,temp1,temp2,temp3: Byte;
  status_backup: Record
                   replay_forbidden: Boolean;
                   play_status: tPLAY_STATUS;
                 end;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:transpose_custom_area';
{$ENDIF}
  status_backup.replay_forbidden := replay_forbidden;
  status_backup.play_status := play_status;
  replay_forbidden := TRUE;
  If (play_status <> isStopped) then play_status := isPaused;
  PATTERN_position_preview(BYTE_NULL,BYTE_NULL,BYTE_NULL,0);

  _1st_choice := BYTE_NULL;
  _break := FALSE;
  _continue := TRUE;

  Case type1 of
    ttTransposeUp:
      For temp3 := patt0 to patt1 do
        begin
          For temp2 := track0 to track1 do
            begin
              For temp1 := line0 to line1 do
                begin
                  get_chunk(temp3,temp1,temp2,chunk);
                  If NOT (type2 = ttTransposeCurrentIns) then
                    begin
                      If NOT (chunk.note+factor <= 12*8+1) and
                         NOT (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) then
                        begin
                          PATTERN_position_preview(temp3,temp1,temp2,1);
                          keyboard_reset_buffer;
                          temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                         'LiNE #'   +byte2hex(temp1)+', '+
                                         'TRACK #'  +Num2str(temp2,10)+'$'+
                                         'NOTE OVERFLOW$',
                                         '~E~RASE$ERASE ~A~LL$~S~KiP$S~K~iP ALL$~C~ANCEL$',
                                         ' TRANSPOSE ',1);

                          _1st_choice := temp;
                          If (dl_environment.keystroke <> kESC) and
                             (_1st_choice <> 5) then
                            begin
                              _break := TRUE;
                              BREAK;
                            end
                          else
                            begin
                              _break := TRUE;
                              _continue := FALSE;
                              BREAK;
                            end;
                        end;
                    end
                  else
                    If NOT (chunk.note < 12*8+1) and
                       NOT (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) and
                           (chunk.instr_def = current_inst) then
                      begin
                        PATTERN_position_preview(temp3,temp1,temp2,1);
                        keyboard_reset_buffer;
                        temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                       'LiNE #'   +byte2hex(temp1)+', '+
                                       'TRACK #'  +Num2str(temp2,10)+'$'+
                                       'NOTE OVERFLOW$',
                                       '~E~RASE$ERASE ~A~LL$~S~KiP$S~K~iP ALL$~C~ANCEL$',
                                       ' TRANSPOSE ',1);

                        _1st_choice := temp;
                        If (dl_environment.keystroke <> kESC) and
                           (_1st_choice <> 5) then
                          begin
                            _break := TRUE;
                            BREAK;
                          end
                        else
                          begin
                            _break := TRUE;
                            _continue := FALSE;
                            BREAK;
                          end;
                      end;
                end;
              If _break then BREAK;
            end;
          If _break then BREAK;
        end;

    ttTransposeDown:
      For temp3 := patt0 to patt1 do
        begin
          For temp2 := track0 to track1 do
            begin
              For temp1 := line0 to line1 do
                begin
                  get_chunk(temp3,temp1,temp2,chunk);
                  If NOT (type2 = ttTransposeCurrentIns) then
                    begin
                      If NOT (chunk.note >= factor+1) and
                         NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) then
                        begin
                          PATTERN_position_preview(temp3,temp1,temp2,1);
                          keyboard_reset_buffer;
                          temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                         'LiNE #'   +byte2hex(temp1)+', '+
                                         'TRACK #'  +Num2str(temp2,10)+'$'+
                                         'NOTE OVERFLOW$',
                                         '~E~RASE$ERASE ~A~LL$~S~KiP$S~K~iP ALL$~C~ANCEL$',
                                         ' TRANSPOSE ',1);

                          _1st_choice := temp;
                          If (dl_environment.keystroke <> kESC) and
                             (_1st_choice <> 5) then
                            begin
                              _break := TRUE;
                              BREAK;
                            end
                          else
                            begin
                              _break := TRUE;
                              _continue := FALSE;
                              BREAK;
                            end;
                        end;
                    end
                  else
                    If NOT (chunk.note >= factor+1) and
                       NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) and
                           (chunk.instr_def = current_inst) then
                      begin
                        PATTERN_position_preview(temp3,temp1,temp2,1);
                        keyboard_reset_buffer;
                        temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                       'LiNE #'   +byte2hex(temp1)+', '+
                                       'TRACK #'  +Num2str(temp2,10)+'$'+
                                       'NOTE OVERFLOW$',
                                       '~E~RASE$ERASE ~A~LL$~S~KiP$S~K~iP ALL$~C~ANCEL$',
                                       ' TRANSPOSE ',1);

                        _1st_choice := temp;
                        If (dl_environment.keystroke <> kESC) and
                           (_1st_choice <> 5) then
                          begin
                            _break := TRUE;
                            BREAK;
                          end
                        else
                          begin
                            _break := TRUE;
                            _continue := FALSE;
                            BREAK;
                          end;
                      end;
                end;
              If _break then BREAK;
            end;
          If _break then BREAK;
        end;
  end;

  _break := FALSE;
  skip_all := FALSE;
  erase_all := FALSE;

  If _continue then
    Case type1 of
      ttTransposeUp:
        For temp3 := patt0 to patt1 do
          begin
            For temp2 := track0 to track1 do
              begin
                For temp1 := line0 to line1 do
                  begin
                    get_chunk(temp3,temp1,temp2,chunk);
                    If NOT (type2 = ttTransposeCurrentIns) then
                      begin
                        If NOT (chunk.note+factor <= 12*8+1) and
                           NOT (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) then
                          begin
                            If (_1st_choice <> BYTE_NULL) then
                              begin
                                Case _1st_choice of
                                  1,
                                  2: begin
                                       chunk.note := 0;
                                       chunk.instr_def := 0;
                                       If (_1st_choice = 2) then erase_all := TRUE;
                                     end;
                                  3,
                                  4: If (_1st_choice = 4) then skip_all := TRUE;
                                end;

                                put_chunk(temp3,temp1,temp2,chunk);
                                _1st_choice := BYTE_NULL;
                                CONTINUE;
                              end;

                            If skip_all then CONTINUE;
                            If erase_all then
                              begin
                                chunk.note := 0;
                                chunk.instr_def := 0;
                                put_chunk(temp3,temp1,temp2,chunk);
                                CONTINUE;
                              end;

                            PATTERN_position_preview(temp3,temp1,temp2,1);
                            keyboard_reset_buffer;
                            temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                           'LiNE #'   +byte2hex(temp1)+', '+
                                           'TRACK #'  +Num2str(temp2,10)+'$'+
                                           'NOTE OVERFLOW$',
                                           '~E~RASE$ERASE ~A~LL$~S~KiP$S~K~iP ALL$CANCEL$',
                                           ' TRANSPOSE ',1);

                            If (dl_environment.keystroke <> kESC) then
                              begin
                                Case temp of
                                  1,
                                  2: begin
                                       chunk.note := 0;
                                       chunk.instr_def := 0;
                                       If (temp = 2) then erase_all := TRUE;
                                     end;
                                  3,
                                  4: If (temp = 4) then skip_all := TRUE;
                                  5: begin
                                       _break := TRUE;
                                       BREAK;
                                     end;
                                end;
                                put_chunk(temp3,temp1,temp2,chunk);
                              end;
                          end
                        else
                          If NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) then
                            begin
                              Inc(chunk.note,factor);
                              put_chunk(temp3,temp1,temp2,chunk);
                            end;
                      end
                    else
                      If NOT (chunk.note < 12*8+1) and
                         NOT (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) and
                             (chunk.instr_def = current_inst) then
                        begin
                          If (_1st_choice <> BYTE_NULL) then
                            begin
                              Case _1st_choice of
                                1,
                                2: begin
                                     chunk.note := 0;
                                     chunk.instr_def := 0;
                                     If (_1st_choice = 2) then erase_all := TRUE;
                                   end;
                                3,
                                4: If (_1st_choice = 4) then skip_all := TRUE;
                              end;

                              put_chunk(temp3,temp1,temp2,chunk);
                              _1st_choice := BYTE_NULL;
                              CONTINUE;
                            end;

                          If skip_all then CONTINUE;
                          If erase_all then
                            begin
                              chunk.note := 0;
                              chunk.instr_def := 0;
                              put_chunk(temp3,temp1,temp2,chunk);
                              CONTINUE;
                            end;

                          PATTERN_position_preview(temp3,temp1,temp2,1);
                          keyboard_reset_buffer;
                          temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                         'LiNE #'   +byte2hex(temp1)+', '+
                                         'TRACK #'  +Num2str(temp2,10)+'$'+
                                         'NOTE OVERFLOW$',
                                         '~E~RASE$ERASE ~A~LL$~S~KiP$S~K~iP ALL$CANCEL$',
                                         ' TRANSPOSE ',1);

                          If (dl_environment.keystroke <> kESC) then
                            begin
                              Case temp of
                                1,
                                2: begin
                                     chunk.note := 0;
                                     chunk.instr_def := 0;
                                     If (temp = 2) then erase_all := TRUE;
                                   end;
                                3,
                                4: If (temp = 4) then skip_all := TRUE;
                                5: begin
                                     _break := TRUE;
                                     BREAK;
                                   end;
                              end;
                              put_chunk(temp3,temp1,temp2,chunk);
                            end;
                        end
                      else
                        If NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) and
                               (chunk.instr_def = current_inst) then
                          begin
                            Inc(chunk.note,factor);
                            put_chunk(temp3,temp1,temp2,chunk);
                          end;
                  end;
                If _break then BREAK;
              end;
            If _break then BREAK;
          end;

      ttTransposeDown:
        For temp3 := patt0 to patt1 do
          begin
            For temp2 := track0 to track1 do
              begin
                For temp1 := line0 to line1 do
                  begin
                    get_chunk(temp3,temp1,temp2,chunk);
                    If NOT (type2 = ttTransposeCurrentIns) then
                      begin
                        If NOT (chunk.note >= factor+1) and
                           NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) then
                          begin
                            If (_1st_choice <> BYTE_NULL) then
                              begin
                                Case _1st_choice of
                                  1,
                                  2: begin
                                       chunk.note := 0;
                                       chunk.instr_def := 0;
                                       If (_1st_choice = 2) then erase_all := TRUE;
                                     end;
                                  3,
                                  4: If (_1st_choice = 4) then skip_all := TRUE;
                                end;

                                put_chunk(temp3,temp1,temp2,chunk);
                                _1st_choice := BYTE_NULL;
                                CONTINUE;
                              end;

                            If skip_all then CONTINUE;
                            If erase_all then
                              begin
                                chunk.note := 0;
                                chunk.instr_def := 0;
                                put_chunk(temp3,temp1,temp2,chunk);
                                CONTINUE;
                              end;

                            PATTERN_position_preview(temp3,temp1,temp2,1);
                            keyboard_reset_buffer;
                            temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                           'LiNE #'   +byte2hex(temp1)+', '+
                                           'TRACK #'  +Num2str(temp2,10)+'$'+
                                           'NOTE OVERFLOW$',
                                           '~E~RASE$ERASE ~A~LL$~S~KiP$S~K~iP ALL$CANCEL$',
                                           ' TRANSPOSE ',1);

                            If (dl_environment.keystroke <> kESC) then
                              begin
                                Case temp of
                                  1,
                                  2: begin
                                       chunk.note := 0;
                                       chunk.instr_def := 0;
                                       If (temp = 2) then erase_all := TRUE;
                                     end;
                                  3,
                                  4: If (temp = 4) then skip_all := TRUE;
                                  5: begin
                                       _break := TRUE;
                                       BREAK;
                                     end;
                                end;
                                put_chunk(temp3,temp1,temp2,chunk);
                              end;
                          end
                        else
                          If NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) then
                            begin
                              Dec(chunk.note,factor);
                              put_chunk(temp3,temp1,temp2,chunk);
                            end;
                      end
                    else
                      If NOT (chunk.note >= factor+1) and
                         NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) and
                             (chunk.instr_def = current_inst) then
                        begin
                          If (_1st_choice <> BYTE_NULL) then
                            begin
                              Case _1st_choice of
                                1,
                                2: begin
                                     chunk.note := 0;
                                     chunk.instr_def := 0;
                                     If (_1st_choice = 2) then erase_all := TRUE;
                                   end;
                                3,
                                4: If (_1st_choice = 4) then skip_all := TRUE;
                              end;

                              put_chunk(temp3,temp1,temp2,chunk);
                              _1st_choice := BYTE_NULL;
                              CONTINUE;
                            end;

                          If skip_all then CONTINUE;
                          If erase_all then
                            begin
                              chunk.note := 0;
                              chunk.instr_def := 0;
                              put_chunk(temp3,temp1,temp2,chunk);
                              CONTINUE;
                            end;

                          PATTERN_position_preview(temp3,temp1,temp2,1);
                          keyboard_reset_buffer;
                          temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                         'LiNE #'   +byte2hex(temp1)+', '+
                                         'TRACK #'  +Num2str(temp2,10)+'$'+
                                         'NOTE OVERFLOW$',
                                         '~E~RASE$ERASE ~A~LL$~S~KiP$S~K~iP ALL$CANCEL$',
                                         ' TRANSPOSE ',1);

                          If (dl_environment.keystroke <> kESC) then
                            begin
                              Case temp of
                                1,
                                2: begin
                                     chunk.note := 0;
                                     chunk.instr_def := 0;
                                     If (temp = 2) then erase_all := TRUE;
                                   end;
                                3,
                                4: If (temp = 4) then skip_all := TRUE;
                                5: begin
                                     _break := TRUE;
                                     BREAK;
                                   end;
                              end;
                              put_chunk(temp3,temp1,temp2,chunk);
                            end;
                        end
                      else
                        If NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,BYTE_NULL]) and
                               (chunk.instr_def = current_inst) then
                          begin
                            Dec(chunk.note,factor);
                            put_chunk(temp3,temp1,temp2,chunk);
                          end;
                  end;
                If _break then BREAK;
              end;
            If _break then BREAK;
          end;
    end;

  PATTERN_position_preview(BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL);
  replay_forbidden := status_backup.replay_forbidden;
  play_status := status_backup.play_status;
end;

procedure transpose__control_proc;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:transpose__control_proc';
{$ENDIF}
  If (mn_environment.curr_pos in [1..8]) then
    begin
      If (mn_environment.curr_pos in [1..4]) then
        begin
          transp_menu_str1[2] := Copy(transp_menu_str1[2],1,18)+transp_mnu_str5[1];
          transp_menu_str1[3] := Copy(transp_menu_str1[3],1,18)+transp_mnu_str5[2];
          transp_menu_str1[5] := Copy(transp_menu_str1[5],1,37)+transp_mnu_str5[18];
          transp_menu_str1[6] := Copy(transp_menu_str1[6],1,18)+transp_mnu_str5[3];
          transp_menu_str1[7] := Copy(transp_menu_str1[7],1,18)+transp_mnu_str5[4];
        end
      else begin
             transp_menu_str1[2] := Copy(transp_menu_str1[2],1,18)+transp_mnu_str5[5];
             transp_menu_str1[3] := Copy(transp_menu_str1[3],1,18)+transp_mnu_str5[6];
             transp_menu_str1[5] := Copy(transp_menu_str1[5],1,37)+transp_mnu_str5[18];
             transp_menu_str1[6] := Copy(transp_menu_str1[6],1,18)+transp_mnu_str5[7];
             transp_menu_str1[7] := Copy(transp_menu_str1[7],1,18)+transp_mnu_str5[8];
           end;

      If NOT transp_menu2 then
        transp_menu_str1[4] := Copy(transp_menu_str1[4],1,37)+transp_mnu_str5[10]
      else transp_menu_str1[4] := Copy(transp_menu_str1[4],1,37)+transp_mnu_str5[11];
    end
  else begin
         transp_menu_str1[2] := Copy(transp_menu_str1[2],1,18)+transp_mnu_str5[5];
         transp_menu_str1[3] := Copy(transp_menu_str1[3],1,18)+transp_mnu_str5[9];
         transp_menu_str1[5] := Copy(transp_menu_str1[5],1,37)+transp_mnu_str5[19];
         transp_menu_str1[6] := Copy(transp_menu_str1[6],1,18)+transp_mnu_str5[3];
         transp_menu_str1[7] := Copy(transp_menu_str1[7],1,18)+transp_mnu_str5[4];

         If NOT transp_menu2 then
           transp_menu_str1[4] := Copy(transp_menu_str1[4],1,37)+transp_mnu_str5[12]
         else transp_menu_str1[4] := Copy(transp_menu_str1[4],1,37)+transp_mnu_str5[13];
       end;

  If (mn_environment.curr_pos in [10..17]) then
    begin
      If (mn_environment.curr_pos in [10..13]) then
        begin
          transp_menu_str1[11] := Copy(transp_menu_str1[11],1,18)+transp_mnu_str5[1];
          transp_menu_str1[12] := Copy(transp_menu_str1[12],1,18)+transp_mnu_str5[2];
          transp_menu_str1[14] := Copy(transp_menu_str1[14],1,37)+transp_mnu_str5[18];
          transp_menu_str1[15] := Copy(transp_menu_str1[15],1,18)+transp_mnu_str5[3];
          transp_menu_str1[16] := Copy(transp_menu_str1[16],1,18)+transp_mnu_str5[4];
        end
      else begin
             transp_menu_str1[11] := Copy(transp_menu_str1[11],1,18)+transp_mnu_str5[5];
             transp_menu_str1[12] := Copy(transp_menu_str1[12],1,18)+transp_mnu_str5[6];
             transp_menu_str1[14] := Copy(transp_menu_str1[14],1,37)+transp_mnu_str5[18];
             transp_menu_str1[15] := Copy(transp_menu_str1[15],1,18)+transp_mnu_str5[7];
             transp_menu_str1[16] := Copy(transp_menu_str1[16],1,18)+transp_mnu_str5[8];
           end;

      If NOT transp_menu2 then
        transp_menu_str1[13] := Copy(transp_menu_str1[13],1,37)+transp_mnu_str5[14]
      else transp_menu_str1[13] := Copy(transp_menu_str1[13],1,37)+transp_mnu_str5[15];
    end
  else If NOT (transp_menu2 and NOT marking) then
         begin
           transp_menu_str1[11] := Copy(transp_menu_str1[11],1,18)+transp_mnu_str5[5];
           transp_menu_str1[12] := Copy(transp_menu_str1[12],1,18)+transp_mnu_str5[9];
           transp_menu_str1[14] := Copy(transp_menu_str1[14],1,37)+transp_mnu_str5[19];
           transp_menu_str1[15] := Copy(transp_menu_str1[15],1,18)+transp_mnu_str5[3];
           transp_menu_str1[16] := Copy(transp_menu_str1[16],1,18)+transp_mnu_str5[4];

           If NOT transp_menu2 then
             transp_menu_str1[13] := Copy(transp_menu_str1[13],1,37)+transp_mnu_str5[16]
           else transp_menu_str1[13] := Copy(transp_menu_str1[13],1,37)+transp_mnu_str5[17];
         end;

  mn_environment.do_refresh := TRUE;
  mn_environment.refresh;
end;

procedure TRANSPOSE;

var
  patt0,patt1,track0,track1,line0,line1: Byte;
  patterns: Byte;
  old_text_attr: Byte;

const
  factor: array[1..17] of Byte = (1,12,1,12,1,12,1,12,BYTE_NULL,
                                  1,12,1,12,1,12,1,12);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:TRANSPOSE';
{$ENDIF}
  old_text_attr := mn_setting.text_attr;
  mn_setting.text_attr := dialog_background+dialog_text;
  mn_setting.cycle_moves := TRUE;
  mn_setting.fixed_len := 14;
  mn_setting.terminate_keys[3] := kTAB;
  mn_environment.ext_proc := transpose__control_proc;
  count_patterns(patterns);

  Repeat
    If transp_menu2 then
      begin
        mn_environment.context := ' TAB '#196#16' PATTERN/SONG ';
        transp_menu_str1[4] := transp_menu_str4[3];
        If marking then
          begin
            Move(transp_menu_str2,transp_menu_str1[10],SizeOf(transp_menu_str2));
            transp_menu_str1[13] := transp_menu_str4[4];
          end
        else Move(transp_menu_str3,transp_menu_str1[10],SizeOf(transp_menu_str3));
      end
    else begin
           mn_environment.context := ' TAB '#196#16' TRACK/BLOCK ';
           Move(transp_menu_str2,transp_menu_str1[10],SizeOf(transp_menu_str2));
           transp_menu_str1[4] := transp_menu_str4[1];
           transp_menu_str1[13] := transp_menu_str4[2];
         end;

    transpos := Menu(transp_menu_str1,01,01,transpos,50,17,17,' TRANSPOSE ');
    If transp_menu2 then transp_pos1 := transpos
    else transp_pos2 := transpos;

    If (mn_environment.keystroke = kTAB) then
      begin
        transp_menu2 := NOT transp_menu2;
        If transp_menu2 then transpos := transp_pos1
        else transpos := transp_pos2;
        keyboard_reset_buffer;
      end;

    If (mn_environment.keystroke <> kESC) and
       (mn_environment.keystroke <> kTAB) then
      begin
        If transp_menu2 or (transpos < 9) then
          begin
            patt0 := pattern_patt;
            patt1 := patt0;
          end
        else
          begin
            patt0 := 0;
            patt1 := patterns;
          end;

        If NOT transp_menu2 then
          begin
            line0  := 0;
            line1  := PRED(songdata.patt_len);
            track0 := 1;
            track1 := songdata.nm_tracks;
          end
        else If (transpos < 9) then
               begin
                 line0  := 0;
                 line1  := PRED(songdata.patt_len);
                 track0 := count_channel(pattern_hpos);
                 track1 := track0;
               end
             else
               begin
                 If tracing then
                   begin
                     patt0 := tracing_block_pattern;
                     patt1 := patt0;
                   end;

                 line0  := block_y0;
                 line1  := block_y1;
                 track0 := block_x0;
                 track1 := block_x1;
               end;

        Case transpos of
          1,2,
          5,6,
          10..11,
          14..15: If (transpos in [1..4,10..13]) then
                    transpose_custom_area(ttTransposeUp,
                                          ttTransposeCurrentIns,
                                          patt0,patt1,track0,track1,line0,line1,
                                          factor[transpos])
                  else
                    transpose_custom_area(ttTransposeUp,
                                          ttTransposeAllIns,
                                          patt0,patt1,track0,track1,line0,line1,
                                          factor[transpos]);
          3,4,
          7,8,
          12..13,
          16..17: If (transpos in [1..4,10..13]) then
                    transpose_custom_area(ttTransposeDown,
                                          ttTransposeCurrentIns,
                                          patt0,patt1,track0,track1,line0,line1,
                                          factor[transpos])
                  else
                    transpose_custom_area(ttTransposeDown,
                                          ttTransposeAllIns,
                                          patt0,patt1,track0,track1,line0,line1,
                                          factor[transpos]);
        end;
      end;
  until (mn_environment.keystroke <> kTAB);

  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(pattern_page);
  mn_setting.fixed_len := 0;
  mn_setting.terminate_keys[3] := 0;
  mn_environment.context := '';
  mn_environment.ext_proc := NIL;
  mn_setting.text_attr := old_text_attr;
end;

function cstr2str(str: String): String;

var
  temp: Byte;

begin
  For temp := 1 to Length(str) do
    If (str[temp] = '~') then Delete(str,temp,1);
  cstr2str := str;
end;

var
  _remap_pos,
  _remap_inst_page_len,
  _remap_xstart,
  _remap_ystart: Byte;

procedure _remap_refresh_proc;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_remap_refresh_proc';
{$ENDIF}
  If (_remap_pos = 1) then
    ShowStr(centered_frame_vdest,_remap_xstart+8,_remap_ystart+1,'CURRENT iNSTRUMENT ('+
            byte2hex(MenuLib1_mn_environment.curr_pos)+')',
            dialog_background+dialog_hi_text)
  else
    ShowStr(centered_frame_vdest,_remap_xstart+8,_remap_ystart+1,'CURRENT iNSTRUMENT ('+
            byte2hex(MenuLib1_mn_environment.curr_pos)+')',
            dialog_background+dialog_text);

  If (_remap_pos = 2) then
    ShowStr(centered_frame_vdest,_remap_xstart+44,_remap_ystart+1,'NEW iNSTRUMENT ('+
            byte2hex(MenuLib2_mn_environment.curr_pos)+')',
            dialog_background+dialog_hi_text)
  else
    ShowStr(centered_frame_vdest,_remap_xstart+44,_remap_ystart+1,'NEW iNSTRUMENT ('+
            byte2hex(MenuLib2_mn_environment.curr_pos)+')',
            dialog_background+dialog_text);

  If (_remap_pos = 3) then
    ShowStr(centered_frame_vdest,_remap_xstart+18,_remap_ystart+_remap_inst_page_len+4,' PATTERN ',
            dialog_hi_text SHL 4)
  else If (remap_selection = 1) then
         ShowStr(centered_frame_vdest,_remap_xstart+18,_remap_ystart+_remap_inst_page_len+4,' PATTERN ',
            dialog_sel_itm_bck+dialog_sel_itm)
       else
         ShowStr(centered_frame_vdest,_remap_xstart+18,_remap_ystart+_remap_inst_page_len+4,' PATTERN ',
                 dialog_background+dialog_text);

  If (_remap_pos = 4) then
    ShowStr(centered_frame_vdest,_remap_xstart+29,_remap_ystart+_remap_inst_page_len+4,' SONG ',
            dialog_hi_text SHL 4)
  else If (remap_selection = 2) then
         ShowStr(centered_frame_vdest,_remap_xstart+29,_remap_ystart+_remap_inst_page_len+4,' SONG ',
                 dialog_sel_itm_bck+dialog_sel_itm)
       else
         ShowStr(centered_frame_vdest,_remap_xstart+29,_remap_ystart+_remap_inst_page_len+4,' SONG ',
                 dialog_background+dialog_text);

  If (_remap_pos = 5) then
    ShowStr(centered_frame_vdest,_remap_xstart+37,_remap_ystart+_remap_inst_page_len+4,' TRACK ',
            dialog_hi_text SHL 4)
  else If (remap_selection = 3) then
         ShowStr(centered_frame_vdest,_remap_xstart+37,_remap_ystart+_remap_inst_page_len+4,' TRACK ',
                 dialog_sel_itm_bck+dialog_sel_itm)
       else
         ShowStr(centered_frame_vdest,_remap_xstart+37,_remap_ystart+_remap_inst_page_len+4,' TRACK ',
                 dialog_background+dialog_text);

  If (_remap_pos = 6) then
    ShowStr(centered_frame_vdest,_remap_xstart+46,_remap_ystart+_remap_inst_page_len+4,' BLOCK ',
            dialog_hi_text SHL 4)
  else If (remap_selection = 4) then
         ShowStr(centered_frame_vdest,_remap_xstart+46,_remap_ystart+_remap_inst_page_len+4,' BLOCK ',
                 dialog_sel_itm_bck+dialog_sel_itm)
       else If marking then
              ShowStr(centered_frame_vdest,_remap_xstart+46,_remap_ystart+_remap_inst_page_len+4,' BLOCK ',
                      dialog_background+dialog_text)
            else
              ShowStr(centered_frame_vdest,_remap_xstart+46,_remap_ystart+_remap_inst_page_len+4,' BLOCK ',
                      dialog_background+dialog_item_dis);
end;

procedure REMAP_instr_control_proc;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:REMAP_instr_control_proc';
{$ENDIF}
  _remap_refresh_proc;
  If (remap_mtype = 1) then
    INSTRUMENT_test(MenuLib1_mn_environment.curr_pos,BYTE_NULL,count_channel(pattern_hpos),
                    MenuLib1_mn_environment.keystroke,TRUE)
  else
    INSTRUMENT_test(MenuLib2_mn_environment.curr_pos,BYTE_NULL,count_channel(pattern_hpos),
                    MenuLib2_mn_environment.keystroke,TRUE);
end;

procedure REMAP;

var
  status_backup: Record
                   replay_forbidden: Boolean;
                   play_status: tPLAY_STATUS;
                 end;
var
  chunk: tCHUNK;
  temp,temp1,temp2,temp3: Byte;
  patt0,patt1,track0,track1,line0,line1: Byte;
  fkey: Word;
  patterns: Byte;
  qflag: Boolean;

procedure reset_screen;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:REMAP:reset_screen';
{$ENDIF}

  MenuLib1_mn_environment.ext_proc := NIL;
  MenuLib2_mn_environment.ext_proc := NIL;

  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := _remap_xstart;
  move_to_screen_area[2] := _remap_ystart;
  move_to_screen_area[3] := _remap_xstart+71+2;
  move_to_screen_area[4] := _remap_ystart+_remap_inst_page_len+5+1;
  move2screen;
end;

procedure override_frame(dest: tSCREEN_MEM_PTR; x,y: Byte; frame: String; attr: Byte);

{$IFNDEF CPU64}

procedure override_vscrollbar(dest: tSCREEN_MEM_PTR; x,y: Byte; len: Byte; attr: Byte);
begin
  asm
        mov     al,MaxCol
        dec     al
        xor     ah,ah
        xor     ebx,ebx
        mov     bl,2
        mul     bl
        mov     bx,ax
        mov     edi,dword ptr [dest]
        mov     al,x
        mov     ah,y
        push    eax
        push    ebx
        mov     al,MaxCol
        xor     ah,ah
        xor     ebx,ebx
        mov     bl,y
        dec     bl
        mul     bl
        mov     bl,x
        dec     bl
        add     eax,ebx
        mov     edx,eax
        shl     edx,1
        pop     ebx
        pop     eax
        xor     ecx,ecx
        mov     cl,len
        jecxz   @@2
        add     edi,edx
        mov     al,attr
@@1:    inc     edi
        stosb
        add     edi,ebx
        loop    @@1
@@2:
  end;
end;

{$ELSE}

procedure override_vscrollbar(dest: tSCREEN_MEM_PTR; x,y: Byte; len: Byte; attr: Byte);

var
  row: Byte;

begin
  If (len <> 0) then
    For row := PRED(y) to PRED(y)+len do
      dest^[SUCC((row*MaxCol+PRED(x))*2)] := attr;
end;

{$ENDIF}

begin
  ShowStr(dest,x,y,frame[1]+ExpStrL('',32,frame[2])+frame[3],attr);
  ShowVStr(dest,x,y+1,ExpStrL('',MAX_PATTERN_ROWS,frame[4]),attr);
  ShowStr(dest,x,y+MAX_PATTERN_ROWS+1,frame[6]+ExpStrL('',32,frame[7])+frame[8],attr);
  override_vscrollbar(dest,x+33,y+1,MAX_PATTERN_ROWS,attr);
end;

var
  temp_instr_names: array[1..255] of String[32];

label _jmp1;

begin { REMAP }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:REMAP';
{$ENDIF}
  If (remap_selection = 4) and NOT marking then remap_selection := 1;
  _remap_pos := 1;
  _remap_inst_page_len := MAX_PATTERN_ROWS;
  qflag := FALSE;

  MenuLib1_mn_setting.menu_attr := dialog_background+dialog_text;
  MenuLib2_mn_setting.menu_attr := dialog_background+dialog_text;

_jmp1:
  If _force_program_quit then EXIT;

  For temp := 1 to 255 do
    temp_instr_names[temp] := ' '+Copy(cstr2str(songdata.instr_names[temp]),2,31);

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  HideCursor;
  count_patterns(patterns);

  ScreenMemCopy(screen_ptr,ptr_temp_screen);
  centered_frame_vdest := ptr_temp_screen;
  centered_frame(_remap_xstart,_remap_ystart,71,_remap_inst_page_len+5,' REMAP iNSTRUMENT ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);

  MenuLib1_mn_environment.curr_pos := remap_ins1;
  MenuLib2_mn_environment.curr_pos := remap_ins2;

  MenuLib1_mn_environment.v_dest := ptr_temp_screen;
  MenuLib2_mn_environment.v_dest := ptr_temp_screen;
  MenuLib1_mn_environment.ext_proc := REMAP_instr_control_proc;
  MenuLib2_mn_environment.ext_proc := REMAP_instr_control_proc;

  MenuLib1_mn_environment.unpolite := FALSE;
  MenuLib1_mn_environment.preview := TRUE;
  remap_ins1 := MenuLib1_Menu(temp_instr_names,_remap_xstart+2,_remap_ystart+2,
                        remap_ins1,32,_remap_inst_page_len,255,'');

  MenuLib2_mn_environment.unpolite := FALSE;
  MenuLib2_mn_environment.preview := TRUE;
  remap_ins2 := MenuLib2_Menu(temp_instr_names,_remap_xstart+36,_remap_ystart+2,
                        remap_ins2,32,_remap_inst_page_len,255,'');

  If (_remap_pos = 1) then
    override_frame(centered_frame_vdest,_remap_xstart+2,_remap_ystart+2,
                   frame_double,
                   dialog_background+dialog_hi_text)
  else override_frame(centered_frame_vdest,_remap_xstart+2,_remap_ystart+2,
                      frame_single,
                      dialog_background+dialog_text);

  If (_remap_pos = 2) then
    override_frame(centered_frame_vdest,_remap_xstart+36,_remap_ystart+2,
                   frame_double,dialog_background+dialog_hi_text)
  else override_frame(centered_frame_vdest,_remap_xstart+36,_remap_ystart+2,
                      frame_single,
                      dialog_background+dialog_text);

  _remap_refresh_proc;
  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := _remap_xstart;
  move_to_screen_area[2] := _remap_ystart;
  move_to_screen_area[3] := _remap_xstart+71+2;
  move_to_screen_area[4] := _remap_ystart+_remap_inst_page_len+5+1;
  move2screen_alt;

  centered_frame_vdest := screen_ptr;
  MenuLib1_mn_environment.v_dest := screen_ptr;
  MenuLib2_mn_environment.v_dest := screen_ptr;

  If NOT _force_program_quit then
    Repeat
      If (_remap_pos = 1) then
        begin
          override_frame(screen_ptr,_remap_xstart+2,_remap_ystart+2,
                         frame_double,
                         dialog_background+dialog_hi_text);
          MenuLib1_mn_setting.menu_attr := dialog_background+dialog_hi_text;
        end
      else
        begin
          override_frame(screen_ptr,_remap_xstart+2,_remap_ystart+2,
                         frame_single,
                         dialog_background+dialog_text);
          MenuLib1_mn_setting.menu_attr := dialog_background+dialog_text;
        end;

      If (_remap_pos = 2) then
        begin
          override_frame(screen_ptr,_remap_xstart+36,_remap_ystart+2,
                         frame_double,
                         dialog_background+dialog_hi_text);
          MenuLib2_mn_setting.menu_attr := dialog_background+dialog_hi_text;
        end
      else
        begin
          override_frame(screen_ptr,_remap_xstart+36,_remap_ystart+2,
                         frame_single,
                         dialog_background+dialog_text);
          MenuLib2_mn_setting.menu_attr := dialog_background+dialog_text;
        end;

      Case _remap_pos of
        1: begin
             remap_ins1 := MenuLib1_Menu(temp_instr_names,_remap_xstart+2,_remap_ystart+2,
                                   remap_ins1,32,_remap_inst_page_len,255,'');
             Case MenuLib1_mn_environment.keystroke of
               kShTAB,kLEFT: _remap_pos := 2+remap_selection;
               kRIGHT,kTAB: _remap_pos := 2;
               kESC: qflag := TRUE;
               kENTER: begin _remap_pos := 2+remap_selection; qflag := TRUE; end;
             kCtrlO: begin reset_screen; OCTAVE_CONTROL; GOTO _jmp1; end;
             kF1: begin reset_screen; HELP('remap_dialog'); GOTO _jmp1; end;
             end;
           end;

        2: begin
             remap_ins2 := MenuLib2_Menu(temp_instr_names,_remap_xstart+36,_remap_ystart+2,
                                   remap_ins2,32,_remap_inst_page_len,255,'');
             Case MenuLib2_mn_environment.keystroke of
               kLEFT,kShTAB: _remap_pos := 1;
               kTAB,kRIGHT: _remap_pos := 2+remap_selection;
               kESC: qflag := TRUE;
               kENTER: begin _remap_pos := 2+remap_selection; qflag := TRUE; end;
             kCtrlO: begin reset_screen; OCTAVE_CONTROL; GOTO _jmp1; end;
             kF1: begin reset_screen; HELP('remap_dialog'); GOTO _jmp1; end;
             end;
           end;

        3: begin
             fkey := getkey;
             Case fkey of
               kHOME: _remap_pos := 3;
               kEND,kLEFT: If marking then _remap_pos := 6 else _remap_pos := 5;
               kRIGHT: _remap_pos := 4;
               kTAB,kDOWN: _remap_pos := 1;
               kShTAB,kUP: _remap_pos := 2;
               kENTER: qflag := TRUE;
               kESC: begin _remap_pos := 1; qflag := TRUE; end;
             kCtrlO: begin reset_screen; OCTAVE_CONTROL; GOTO _jmp1; end;
             kF1: begin reset_screen; HELP('remap_dialog'); GOTO _jmp1; end;
             end;
           end;

        4: begin
             fkey := getkey;
             Case fkey of
               kHOME: _remap_pos := 3;
               kEND: If marking then _remap_pos := 6 else _remap_pos := 5;
               kLEFT: _remap_pos := 3;
               kRIGHT: _remap_pos := 5;
               kTAB,kDOWN: _remap_pos := 1;
               kShTAB,kUP: _remap_pos := 2;
               kENTER: qflag := TRUE;
               kESC: begin _remap_pos := 1; qflag := TRUE; end;
             kCtrlO: begin reset_screen; OCTAVE_CONTROL; GOTO _jmp1; end;
             kF1: begin reset_screen; HELP('remap_dialog'); GOTO _jmp1; end;
             end;
           end;

        5: begin
             fkey := getkey;
             Case fkey of
               kHOME: _remap_pos := 3;
               kEND: If marking then _remap_pos := 6 else _remap_pos := 5;
               kLEFT: _remap_pos := 4;
               kRIGHT: If marking then _remap_pos := 6 else _remap_pos := 3;
               kTAB,kDOWN: _remap_pos := 1;
               kShTAB,KUP: _remap_pos := 2;
               kENTER: qflag := TRUE;
               kESC: begin _remap_pos := 1; qflag := TRUE; end;
             kCtrlO: begin reset_screen; OCTAVE_CONTROL; GOTO _jmp1; end;
             kF1: begin reset_screen; HELP('remap_dialog'); GOTO _jmp1; end;
             end;
           end;

        6: begin
             fkey := getkey;
             Case fkey of
               kHOME: _remap_pos := 3;
               kEND: _remap_pos := 6;
               kLEFT: _remap_pos := 5;
               kRIGHT: _remap_pos := 3;
               kTAB,kDOWN: _remap_pos := 1;
               kShTAB,kUP: _remap_pos := 2;
               kENTER: qflag := TRUE;
               kESC: begin _remap_pos := 1; qflag := TRUE; end;
             kCtrlO: begin reset_screen; OCTAVE_CONTROL; GOTO _jmp1; end;
             kF1: begin reset_screen; HELP('remap_dialog'); GOTO _jmp1; end;
             end;
           end;
      end;

      If (_remap_pos < 3) then remap_mtype := _remap_pos else remap_selection := _remap_pos-2;
      _remap_refresh_proc;
      // draw_screen;
    until qflag;

  MenuLib1_mn_environment.ext_proc := NIL;
  MenuLib2_mn_environment.ext_proc := NIL;

  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := _remap_xstart;
  move_to_screen_area[2] := _remap_ystart;
  move_to_screen_area[3] := _remap_xstart+71+2;
  move_to_screen_area[4] := _remap_ystart+_remap_inst_page_len+5+1;
  move2screen;

  If qflag and (_remap_pos > 2) then
    begin
      status_backup.replay_forbidden := replay_forbidden;
      status_backup.play_status := play_status;
      replay_forbidden := TRUE;
      If (play_status <> isStopped) then play_status := isPaused;

      Case _remap_pos-2 of
        1: begin
             patt0  := pattern_patt;
             patt1  := patt0;
             track0 := 1;
             track1 := songdata.nm_tracks;
             line0  := 0;
             line1  := PRED(songdata.patt_len);
           end;

        2: begin
             patt0  := 0;
             patt1  := patterns;
             track0 := 1;
             track1 := songdata.nm_tracks;
             line0  := 0;
             line1  := PRED(songdata.patt_len);
           end;

        3: begin
             patt0  := pattern_patt;
             patt1  := patt0;
             track0 := count_channel(pattern_hpos);
             track1 := track0;
             line0  := 0;
             line1  := PRED(songdata.patt_len);
           end;

        4: begin
             patt0  := pattern_patt;
             patt1  := patt0;
             track0 := block_x0;
             track1 := block_x1;
             line0  := block_y0;
             line1  := block_y1;
           end;
      end;

      For temp3 := patt0 to patt1 do
        For temp2 := track0 to track1 do
          For temp1 := line0 to line1 do
            begin
              get_chunk(temp3,temp1,temp2,chunk);
              If (chunk.instr_def = remap_ins1) then
                begin
                  chunk.instr_def := remap_ins2;
                  put_chunk(temp3,temp1,temp2,chunk);
                end;
            end;

      replay_forbidden := status_backup.replay_forbidden;
      play_status := status_backup.play_status;
    end;

  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(pattern_page);
end;

const
  _rearrange_track_pos: Byte = 1;
  _rearrange_pos: Byte = 1;
  _rearrange_tracklist_idx: array[1..20] of Byte = (
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20);

var
  _rearrange_xstart,
  _rearrange_ystart,
  _rearrange_nm_tracks: Byte;
  _rearrange_tracklist: array[1..18] of String[4];

procedure _rearrange_refresh_proc;

var
  idx: Byte;
  attr: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_rearrange_refresh_proc';
{$ENDIF}

  If (_rearrange_pos <> 1) then attr := dialog_sel_itm_bck+dialog_sel_itm
  else attr := dialog_hi_text SHL 4;

  For idx := 1 to _rearrange_nm_tracks do
    If (idx = _rearrange_track_pos) then
      ShowCStr(centered_frame_vdest,_rearrange_xstart+1,_rearrange_ystart+idx,
               '~      '+ExpStrL(Num2str(idx,10),2,' ')+' ~'#16+_rearrange_tracklist[idx]+#17,
               attr,
               dialog_background+dialog_contxt_dis2)
    else
      ShowCStr(centered_frame_vdest,_rearrange_xstart+1,_rearrange_ystart+idx,
               '~      '+ExpStrL(Num2str(idx,10),2,' ')+'  ~'+_rearrange_tracklist[idx]+' ',
               mn_setting.text_attr,
               dialog_background+dialog_contxt_dis2);

  If (_rearrange_pos = 2) then
    ShowStr(centered_frame_vdest,_rearrange_xstart+2,_rearrange_ystart+_rearrange_nm_tracks+2,' PATTERN ',
            dialog_hi_text SHL 4)
  else If (rearrange_selection = 1) then
         ShowStr(centered_frame_vdest,_rearrange_xstart+2,_rearrange_ystart+_rearrange_nm_tracks+2,' PATTERN ',
            dialog_sel_itm_bck+dialog_sel_itm)
       else
         ShowStr(centered_frame_vdest,_rearrange_xstart+2,_rearrange_ystart+_rearrange_nm_tracks+2,' PATTERN ',
                 dialog_background+dialog_text);

  If (_rearrange_pos = 3) then
    ShowStr(centered_frame_vdest,_rearrange_xstart+13,_rearrange_ystart+_rearrange_nm_tracks+2,' SONG ',
            dialog_hi_text SHL 4)
  else If (rearrange_selection = 2) then
         ShowStr(centered_frame_vdest,_rearrange_xstart+13,_rearrange_ystart+_rearrange_nm_tracks+2,' SONG ',
                 dialog_sel_itm_bck+dialog_sel_itm)
       else
         ShowStr(centered_frame_vdest,_rearrange_xstart+13,_rearrange_ystart+_rearrange_nm_tracks+2,' SONG ',
                 dialog_background+dialog_text);
end;

procedure REARRANGE;

var
  status_backup: Record
                   replay_forbidden: Boolean;
                   play_status: tPLAY_STATUS;
                 end;
var
  temp,temp1,temp2,temp3: Byte;
  temps: String;
  patt0,patt1: Byte;
  fkey: Word;
  patterns: Byte;
  qflag,reset_flag: Boolean;
  temp_pattern: array[1..20] of array[0..$0ff] of tCHUNK;

procedure reset_screen;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:REARRANGE:reset_screen';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := _rearrange_xstart;
  move_to_screen_area[2] := _rearrange_ystart;
  move_to_screen_area[3] := _rearrange_xstart+20+2;
  move_to_screen_area[4] := _rearrange_ystart+_rearrange_nm_tracks+3+1;
  move2screen;
end;

label _jmp1;

begin { REARRANGE }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:REARRANGE';
{$ENDIF}
  If (_rearrange_track_pos > songdata.nm_tracks) then _rearrange_track_pos := 1;
  If (rearrange_selection = 4) and NOT marking then rearrange_selection := 1;
  _rearrange_pos := 1;
  qflag := FALSE;

  If percussion_mode then _rearrange_nm_tracks := max(songdata.nm_tracks,15)
  else _rearrange_nm_tracks := songdata.nm_tracks;
  reset_flag := FALSE;
  For temp := 1 to _rearrange_nm_tracks do
    If (_rearrange_tracklist_idx[temp] > _rearrange_nm_tracks) then
      begin
        reset_flag := TRUE;
        BREAK;
      end;

  If reset_flag then
    begin
      For temp := 1 to _rearrange_nm_tracks do _rearrange_tracklist_idx[temp] := temp;
      _rearrange_track_pos := 1;
    end;

  For temp := 1 to _rearrange_nm_tracks do
    _rearrange_tracklist[temp] := ' '+ExpStrL(Num2str(_rearrange_tracklist_idx[temp],10),2,' ')+' ';

_jmp1:
  If _force_program_quit then EXIT;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  HideCursor;
  count_patterns(patterns);

  ScreenMemCopy(screen_ptr,ptr_temp_screen);
  centered_frame_vdest := ptr_temp_screen;
  centered_frame(_rearrange_xstart,_rearrange_ystart,20,_rearrange_nm_tracks+3,' REARRANGE TRACKS ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);

  ShowStr(centered_frame_vdest,_rearrange_xstart+1,_rearrange_ystart+_rearrange_nm_tracks+1,
          ExpStrL('',19,#196),
          dialog_background+dialog_contxt_dis2);

  _rearrange_refresh_proc;
  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := _rearrange_xstart;
  move_to_screen_area[2] := _rearrange_ystart;
  move_to_screen_area[3] := _rearrange_xstart+20+2;
  move_to_screen_area[4] := _rearrange_ystart+_rearrange_nm_tracks+3+1;
  move2screen_alt;
  centered_frame_vdest := screen_ptr;

  If NOT _force_program_quit then
    Repeat
      Case _rearrange_pos of
        1: begin
             fkey := getkey;
             Case fkey of
               kUP: If (_rearrange_track_pos > 1) then Dec(_rearrange_track_pos)
                    else _rearrange_track_pos := _rearrange_nm_tracks;
               kDOWN: If (_rearrange_track_pos < _rearrange_nm_tracks) then Inc(_rearrange_track_pos)
                      else _rearrange_track_pos := 1;
               kPgUP,kHOME: _rearrange_track_pos := 1;
               kPgDOWN,kEND: _rearrange_track_pos := _rearrange_nm_tracks;
               kCtPgUP: If (_rearrange_nm_tracks > 1) then
                          If shift_pressed then
                            begin
                              temps := _rearrange_tracklist[1];
                              For temp := 1 to _rearrange_track_pos do
                                _rearrange_tracklist[temp] := _rearrange_tracklist[temp+1];
                              _rearrange_tracklist[_rearrange_track_pos] := temps;
                            end
                          else If (_rearrange_track_pos > 1) then
                                 begin
                                   temps := _rearrange_tracklist[_rearrange_track_pos-1];
                                   _rearrange_tracklist[_rearrange_track_pos-1] := _rearrange_tracklist[_rearrange_track_pos];
                                   _rearrange_tracklist[_rearrange_track_pos] := temps;
                                   Dec(_rearrange_track_pos);
                                 end;
               kCtPgDN: If (_rearrange_track_pos < _rearrange_nm_tracks) then
                          If shift_pressed then
                            begin
                              temps := _rearrange_tracklist[_rearrange_nm_tracks];
                              For temp := _rearrange_nm_tracks downto _rearrange_track_pos+1 do
                                _rearrange_tracklist[temp] := _rearrange_tracklist[temp-1];
                              _rearrange_tracklist[_rearrange_track_pos] := temps;
                            end
                          else begin
                                 temps := _rearrange_tracklist[_rearrange_track_pos+1];
                                 _rearrange_tracklist[_rearrange_track_pos+1] := _rearrange_tracklist[_rearrange_track_pos];
                                 _rearrange_tracklist[_rearrange_track_pos] := temps;
                                 Inc(_rearrange_track_pos);
                               end;
               kLEFT,kRIGHT,kTAB,kShTAB: _rearrange_pos := 1+rearrange_selection;
               kESC: qflag := TRUE;
               kENTER: begin _rearrange_pos := 1+rearrange_selection; qflag := TRUE; end;
               kF1: begin reset_screen; HELP('rearrange_dialog'); GOTO _jmp1; end;
             end;
           end;

        2: begin
             fkey := getkey;
             Case fkey of
               kHOME: _rearrange_pos := 2;
               kEND,kLEFT: _rearrange_pos := 3;
               kRIGHT: _rearrange_pos := 3;
               kUP,kDOWN,kTAB,kShTAB: _rearrange_pos := 1;
               kENTER: qflag := TRUE;
               kESC: begin _rearrange_pos := 1; qflag := TRUE; end;
               kF1: begin reset_screen; HELP('rearrange_dialog'); GOTO _jmp1; end;
             end;
           end;

        3: begin
             fkey := getkey;
             Case fkey of
               kHOME: _rearrange_pos := 2;
               kEND: _rearrange_pos := 3;
               kLEFT: _rearrange_pos := 2;
               kRIGHT: _rearrange_pos := 2;
               kUP,kDOWN,kTAB,kShTAB: _rearrange_pos := 1;
               kENTER: qflag := TRUE;
               kESC: begin _rearrange_pos := 1; qflag := TRUE; end;
               kF1: begin reset_screen; HELP('rearrange_dialog'); GOTO _jmp1; end;
             end;
           end;
      end;

      If (_rearrange_pos > 1) then rearrange_selection := _rearrange_pos-1;
      If (fkey <> kESC) then _rearrange_refresh_proc;
      // draw_screen;
    until qflag;

  reset_screen;
  For temp := 1 to _rearrange_nm_tracks do
    _rearrange_tracklist_idx[temp] := Str2num(CutStr(_rearrange_tracklist[temp]),10);

  If qflag and (_rearrange_pos > 1) then
    begin
      status_backup.replay_forbidden := replay_forbidden;
      status_backup.play_status := play_status;
      replay_forbidden := TRUE;
      If (play_status <> isStopped) then play_status := isPaused;
      _rearrange_track_pos := 1;

      Case rearrange_selection of
        1: begin
             patt0  := pattern_patt;
             patt1  := patt0;
           end;

        2: begin
             patt0  := 0;
             patt1  := patterns;
           end;
      end;

      For temp3 := patt0 to patt1 do
        begin
          For temp2 := 0 to PRED(songdata.patt_len) do
            For temp1 := 1 to _rearrange_nm_tracks do
              get_chunk(temp3,temp2,_rearrange_tracklist_idx[temp1],temp_pattern[temp1][temp2]);
          For temp2 := 0 to PRED(songdata.patt_len) do
            For temp1 := 1 to _rearrange_nm_tracks do
              put_chunk(temp3,temp2,temp1,temp_pattern[temp1][temp2]);
        end;

      For temp := 1 to _rearrange_nm_tracks do _rearrange_tracklist_idx[temp] := temp;
      replay_forbidden := status_backup.replay_forbidden;
      play_status := status_backup.play_status;
    end;

  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(pattern_page);
end;

procedure REPLACE;

type
  tCharSet = Set of Char;

const
  _charset: array[1..11] of tCharSet = (
    [],
    ['#','-'],
    ['1'..'9'],
    ['0'..'9','A'..'F'],
    ['0'..'9','A'..'F'],
    ['0'..'9','A'..'Z','&','%','!','@','=','#','$','~','^','`','>','<'],
    ['0'..'9','A'..'F'],
    ['0'..'9','A'..'F'],
    ['0'..'9','A'..'Z','&','%','!','@','=','#','$','~','^','`','>','<'],
    ['0'..'9','A'..'F'],
    ['0'..'9','A'..'F']);

const
  _on_off: array[0..1] of Char = ' '#251;

var
  status_backup: Record
                   replay_forbidden: Boolean;
                   play_status: tPLAY_STATUS;
                 end;
var
  chunk,old_chunk: tCHUNK;
  temp,temp1,temp2,temp3: Byte;
  patt0,patt1,track0,track1,line0,line1: Byte;
  pos: Byte;
  fkey: Word;
  xstart,ystart: Byte;
  patterns: Byte;
  qflag: Boolean;

procedure refresh;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:REPLACE:refresh';
{$ENDIF}
  If (pos in [1..11]) then
    ShowStr(centered_frame_vdest,xstart+2,ystart+1,
            'NOTE,iNSTRUMENT,FX N'#249'1/N'#249'2 TO FiND',
            dialog_background+dialog_hi_text)
  else ShowStr(centered_frame_vdest,xstart+2,ystart+1,
               'NOTE,iNSTRUMENT,FX N'#249'1/N'#249'2 TO FiND',
               dialog_background+dialog_text);

  If (pos in [12..22]) then
    ShowStr(centered_frame_vdest,xstart+2,ystart+4,
            'NEW NOTE,iNSTRUMENT,FX N'#249'1/N'#249'2',
            dialog_background+dialog_hi_text)
  else ShowStr(centered_frame_vdest,xstart+2,ystart+4,
               'NEW NOTE,iNSTRUMENT,FX N'#249'1/N'#249'2',
               dialog_background+dialog_text);

  ShowCStr2(centered_frame_vdest,xstart+2,ystart+2,
            '"'+FilterStr(replace_data.event_to_find.note,'?',#250)+'" '+
            '"'+FilterStr(replace_data.event_to_find.inst,'?',#250)+'" '+
            '"'+FilterStr(replace_data.event_to_find.fx_1,'?',#250)+'" '+
            '"'+FilterStr(replace_data.event_to_find.fx_2,'?',#250)+'"',
            dialog_background+dialog_text,
            dialog_input_bckg+dialog_input);

  ShowCStr2(centered_frame_vdest,xstart+2,ystart+5,
            '"'+FilterStr(replace_data.new_event.note,'?',#250)+'" '+
            '"'+FilterStr(replace_data.new_event.inst,'?',#250)+'" '+
            '"'+FilterStr(replace_data.new_event.fx_1,'?',#250)+'" '+
            '"'+FilterStr(replace_data.new_event.fx_2,'?',#250)+'"',
            dialog_background+dialog_text,
            dialog_input_bckg+dialog_input);

  If (pos = 27) then
    ShowC3Str(centered_frame_vdest,xstart+2,ystart+7,
              '~[~`'+_on_off[BYTE(replace_prompt)]+'`~]~ PROMPT ON REPLACE',
              dialog_background+dialog_hi_text,
              dialog_background+dialog_text,
              dialog_background+dialog_item)
  else ShowCStr(centered_frame_vdest,xstart+2,ystart+7,
                '[~'+_on_off[BYTE(replace_prompt)]+'~] PROMPT ON REPLACE',
                dialog_background+dialog_text,
                dialog_background+dialog_item);

  If (pos = 23) then
    ShowStr(centered_frame_vdest,xstart+2,ystart+9,' PATTERN ',
            dialog_hi_text SHL 4)
  else If (replace_selection = 1) then
         ShowStr(centered_frame_vdest,xstart+2,ystart+9,' PATTERN ',
            dialog_sel_itm_bck+dialog_sel_itm)
       else
         ShowStr(centered_frame_vdest,xstart+2,ystart+9,' PATTERN ',
                 dialog_background+dialog_text);

  If (pos = 24) then
    ShowStr(centered_frame_vdest,xstart+13,ystart+9,' SONG ',
            dialog_hi_text SHL 4)
  else If (replace_selection = 2) then
         ShowStr(centered_frame_vdest,xstart+13,ystart+9,' SONG ',
                 dialog_sel_itm_bck+dialog_sel_itm)
       else
         ShowStr(centered_frame_vdest,xstart+13,ystart+9,' SONG ',
                 dialog_background+dialog_text);

  If (pos = 25) then
    ShowStr(centered_frame_vdest,xstart+21,ystart+9,' TRACK ',
            dialog_hi_text SHL 4)
  else If (replace_selection = 3) then
         ShowStr(centered_frame_vdest,xstart+21,ystart+9,' TRACK ',
                 dialog_sel_itm_bck+dialog_sel_itm)
       else
         ShowStr(centered_frame_vdest,xstart+21,ystart+9,' TRACK ',
                 dialog_background+dialog_text);

  If (pos = 26) then
    ShowStr(centered_frame_vdest,xstart+30,ystart+9,' BLOCK ',
            dialog_hi_text SHL 4)
  else If (replace_selection = 4) then
         ShowStr(centered_frame_vdest,xstart+30,ystart+9,' BLOCK ',
                 dialog_sel_itm_bck+dialog_sel_itm)
       else If marking then
              ShowStr(centered_frame_vdest,xstart+30,ystart+9,' BLOCK ',
                      dialog_background+dialog_text)
            else
              ShowStr(centered_frame_vdest,xstart+30,ystart+9,' BLOCK ',
                      dialog_background+dialog_item_dis);
end;

procedure reset_screen;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:REPLACE:reset_screen';
{$ENDIF}
  HideCursor;
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+38+2;
  move_to_screen_area[4] := ystart+10+1;
  move2screen;
end;

function _find_note(layout: String; old_note: Byte): BYTE;

var
  temp: Byte;
  found_flag: Boolean;

begin
  If (layout = note_keyoff_str[pattern_layout]) then _find_note := BYTE_NULL
  else
    begin
      found_flag := FALSE;
      For temp := 0 to 12*8+1 do
        If SameName(note_layout[temp],layout) then
          begin
            found_flag := TRUE;
            BREAK;
          end;
      If found_flag then _find_note := temp
      else _find_note := old_note;
    end;
end;

{$IFNDEF CPU64}

function _find_fx(fx_str: Char): Byte;

var
  result: Byte;

begin
  asm
        lea     edi,[fx_digits]
        mov     ebx,edi
        mov     al,fx_str
        mov     ecx,NM_FX_DIGITS
        repnz   scasb
        sub     edi,ebx
        mov     eax,edi
        dec     eax
        mov     result,al
  end;
  _find_fx := result;
end;

{$ELSE}

function _find_fx(fx_str: Char): Byte;

var
  result: Byte;

begin
  result := SYSTEM.Pos(fx_str,fx_digits);
  If (result <> 0) then
    _find_fx := PRED(result)
  else _find_fx := PRED(NM_FX_DIGITS);
end;

{$ENDIF}

function _wildcard_str(wildcard,str: String): String;

var
  temp: Byte;

begin
  For temp := 1 to Length(wildcard) do
    If (wildcard[temp] = '?') then wildcard[temp] := str[temp];
  _wildcard_str := wildcard;
end;

var
  _1st_choice,_replace_all,
  _cancel,_valid_note: Boolean;
  chr: Char;
  temp_note: Byte;
  temps: String;
  event_to_find: Record
                   note: String[3];
                   inst: String[2];
                   fx_1: String[3];
                   fx_2: String[3];
                 end;

  new_event: Record
               note: String[3];
               inst: String[2];
               fx_1: String[3];
               fx_2: String[3];
             end;

label _jmp1;

begin { REPLACE }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:REPLACE';
{$ENDIF}
  If (replace_selection = 4) and NOT marking then replace_selection := 1;
  pos := min(get_bank_position('?replace_window?pos',-1),1);
  qflag := FALSE;
  _charset[1] := ['A',UpCase(b_note),'C'..'G'];

_jmp1:
  If _force_program_quit then EXIT;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  HideCursor;
  count_patterns(patterns);

  ScreenMemCopy(screen_ptr,ptr_temp_screen);
  centered_frame_vdest := ptr_temp_screen;
  centered_frame(xstart,ystart,38,10,' REPLACE ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);

  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+38+2;
  move_to_screen_area[4] := ystart+10+1;

  refresh;
  ShowStr(centered_frame_vdest,xstart+1,ystart+8,
          ExpStrL('',38-1,#20),
          dialog_background+dialog_context_dis);

  move2screen_alt;
  centered_frame_vdest := screen_ptr;

  If NOT _force_program_quit then
    Repeat
      If (pos in [1..22,27]) then ThinCursor
      else HideCursor;

      Case pos of
        1..11: begin
                 GotoXY(xstart+1+pos6[pos],ystart+2);
                 fkey := getkey;

                 Case fkey of
                   kTAB,
                   kDOWN: begin
                            add_bank_position('?replace_window?posfx',-1,pos);
                            Inc(pos,11);
                          end;

                   kShTAB,
                   kUP: begin
                          add_bank_position('?replace_window?posfx',-1,pos);
                          pos := 22+replace_selection;
                        end;

                   kLEFT: If (pos > 1) then Dec(pos)
                          else begin
                                 add_bank_position('?replace_window?posfx',-1,pos);
                                 pos := 22+replace_selection;
                               end;

                   kRIGHT: Inc(pos);
                   kHOME: pos := 1;
                   kEND: pos := 11;
                   kESC: qflag := TRUE;
                   kENTER: begin pos := 22+replace_selection; qflag := TRUE; end;
                   kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;

                   kCtrlK: If (pos in [1,2,3]) then
                             begin
                               replace_data.event_to_find.note := note_keyoff_str[pattern_layout];
                               pos := 4;
                             end;

                   else If (UpCase(CHAR(LO(fkey))) in _charset[pos]) or
                           (fkey = kBkSPC) or (fkey = kDELETE) then
                          begin
                            Case fkey of
                              kDELETE: chr := #250;
                              kBkSPC: begin
                                        chr := #250;
                                        If (pos > 1) then Dec(pos);
                                      end;
                              else chr := UpCase(CHAR(LO(fkey)));
                            end;

                            If (replace_data.event_to_find.note = note_keyoff_str[pattern_layout]) and
                               (pos in [1,2,3]) then
                              replace_data.event_to_find.note := #250#250#250;

                            With replace_data.event_to_find do
                              Case pos of
                                 1: begin
                                      note[1] := chr;
                                      If (note[1] in ['E',UpCase(b_note)]) and
                                         (note[2] = '#') then
                                        note[2] := '-';

                                      If (note[1] <> 'C') and (note[3] = '9') then
                                        note[3] := '8';
                                    end;

                                 2: If NOT ((note[1] in ['E',UpCase(b_note)]) and
                                            (chr = '#')) then
                                      note[2] := chr
                                    else note[2] := '-';

                                 3: If NOT ((note[1] <> 'C') and
                                            (chr = '9')) then
                                      note[3] := chr;

                                 4: inst[1] := chr;
                                 5: inst[2] := chr;
                                 6: fx_1[1] := chr;
                                 7: fx_1[2] := chr;
                                 8: fx_1[3] := chr;
                                 9: fx_2[1] := chr;
                                10: fx_2[2] := chr;
                                11: fx_2[3] := chr;
                              end;

                            Case fkey of
                              kDELETE: ;
                              kBkSPC: ;
                              else If (pos < 22) then Inc(pos);
                            end;
                          end;
                 end;
               end;

        12..22: begin
                  GotoXY(xstart+1+pos6[pos-11],ystart+5);
                  fkey := getkey;

                  Case fkey of
                    kTAB,
                    kDOWN: begin
                             add_bank_position('?replace_window?posfx',-1,pos-11);
                             pos := 27;
                           end;

                    kShTAB,
                    kUP: begin
                           add_bank_position('?replace_window?posfx',-1,pos-11);
                           Dec(pos,11);
                         end;

                    kLEFT: Dec(pos);
                    kRIGHT: If (pos < 22) then Inc(pos) else pos := 27;
                    kHOME: pos := 12;
                    kEND: pos := 22;
                    kESC: qflag := TRUE;
                    kENTER: begin pos := 22+replace_selection; qflag := TRUE; end;
                    kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;

                    kCtrlN: Case pos-11 of
                              1,2,3: begin
                                       replace_data.new_event.note := #7#7#7;
                                       pos := 11+4;
                                     end;

                              4,5: begin
                                     replace_data.new_event.inst := '00';
                                     pos := 11+6;
                                   end;

                              6,7,8: begin
                                       replace_data.new_event.fx_1 := '000';
                                       pos := 11+9;
                                     end;

                              9,10,11: begin
                                         replace_data.new_event.fx_2 := '000';
                                         pos := 27;
                                       end;
                            end;

                    kCtrlK: If (pos-11 in [1,2,3]) then
                              begin
                                replace_data.new_event.note := note_keyoff_str[pattern_layout];
                                pos := 11+4;
                              end;

                    else If (UpCase(CHAR(LO(fkey))) in _charset[pos-11]) or
                            (fkey = kBkSPC) or (fkey = kDELETE) then
                           begin
                             Case fkey of
                               kDELETE: chr := #250;
                               kBkSPC: begin
                                         chr := #250;
                                         Dec(pos);
                                       end;
                               else chr := UpCase(CHAR(LO(fkey)));
                             end;

                             If ((replace_data.new_event.note = note_keyoff_str[pattern_layout]) or
                                 (replace_data.new_event.note = #7#7#7)) and
                                (pos-11 in [1,2,3]) then
                               replace_data.new_event.note := #250#250#250;

                             With replace_data.new_event do
                               Case pos-11 of
                                  1: begin
                                       note[1] := chr;
                                       If (note[1] in ['E',UpCase(b_note)]) and
                                          (note[2] = '#') then
                                         note[2] := '-';

                                       If (note[1] <> 'C') and (note[3] = '9') then
                                         note[3] := '8';
                                     end;

                                  2: If NOT ((note[1] in ['E',UpCase(b_note)]) and
                                             (chr = '#')) then
                                       note[2] := chr
                                     else note[2] := '-';

                                  3: If NOT ((note[1] <> 'C') and
                                             (chr = '9')) then
                                       note[3] := chr;

                                  4: inst[1] := chr;
                                  5: inst[2] := chr;
                                  6: fx_1[1] := chr;
                                  7: fx_1[2] := chr;
                                  8: fx_1[3] := chr;
                                  9: fx_2[1] := chr;
                                 10: fx_2[2] := chr;
                                 11: fx_2[3] := chr;
                               end;

                             Case fkey of
                               kDELETE: ;
                               kBkSPC: ;
                               else If (pos < 22) then Inc(pos);
                             end;
                           end;
                  end;
                end;

        27: begin
              GotoXY(xstart+3,ystart+7);
              fkey := getkey;
              Case fkey of
                kUP,kShTAB: pos := get_bank_position('?replace_window?posfx',-1)+11;
                kLEFT: pos := 22;
                kTAB,kRIGHT,kDOWN: pos := 22+replace_selection;
                kENTER: qflag := TRUE;
                kSPACE: replace_prompt := NOT replace_prompt;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;

        23: begin
              fkey := getkey;
              Case fkey of
                kTAB,kDOWN: pos := get_bank_position('?replace_window?posfx',-1);
                kShTAB,kUP: pos := 27;
                kHOME: pos := 23;
                kEND,kLEFT: If marking then pos := 26 else pos := 25;
                kRIGHT: pos := 24;
                kENTER: qflag := TRUE;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;

        24: begin
              fkey := getkey;
              Case fkey of
                kTAB,kDOWN: pos := get_bank_position('?replace_window?posfx',-1);
                kShTAB,kUP: pos := 27;
                kHOME: pos := 23;
                kEND: If marking then pos := 26 else pos := 25;
                kLEFT: pos := 23;
                kRIGHT: pos := 25;
                kENTER: qflag := TRUE;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;

        25: begin
              fkey := getkey;
              Case fkey of
                kTAB,kDOWN: pos := get_bank_position('?replace_window?posfx',-1);
                kShTAB,kUP: pos := 27;
                kHOME: pos := 23;
                kEND: If marking then pos := 26 else pos := 25;
                kLEFT: pos := 24;
                kRIGHT: If marking then pos := 26 else pos := 23;
                kENTER: qflag := TRUE;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;

        26: begin
              fkey := getkey;
              Case fkey of
                kTAB,kDOWN: pos := get_bank_position('?replace_window?posfx',-1);
                kShTAB,kUP: pos := 27;
                kHOME: pos := 23;
                kEND: pos := 26;
                kLEFT: pos := 25;
                kRIGHT: pos := 23;
                kENTER: qflag := TRUE;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;
      end;

      Case fkey of
        kCtrlW: begin
                  temps := replace_data.event_to_find.note;
                  replace_data.event_to_find.note := replace_data.new_event.note;
                  replace_data.new_event.note := temps;
                  temps := replace_data.event_to_find.inst;
                  replace_data.event_to_find.inst := replace_data.new_event.inst;
                  replace_data.new_event.inst := temps;
                  temps := replace_data.event_to_find.fx_1;
                  replace_data.event_to_find.fx_1 := replace_data.new_event.fx_1;
                  replace_data.new_event.fx_1 := temps;
                  temps := replace_data.event_to_find.fx_2;
                  replace_data.event_to_find.fx_2 := replace_data.new_event.fx_2;
                  replace_data.new_event.fx_2 := temps;
                end;

        kCtBkSp: begin
                   If (pos < 12) or shift_pressed then
                     begin
                       replace_data.event_to_find.note := #250#250#250;
                       replace_data.event_to_find.inst := #250#250;
                       replace_data.event_to_find.fx_1 := #250#250#250;
                       replace_data.event_to_find.fx_2 := #250#250#250;
                     end;
                   If (pos >= 12) or shift_pressed then
                     begin
                       replace_data.new_event.note := #250#250#250;
                       replace_data.new_event.inst := #250#250;
                       replace_data.new_event.fx_1 := #250#250#250;
                       replace_data.new_event.fx_2 := #250#250#250;
                     end;
                 end;
      end;

      If (pos in [23..26]) then replace_selection := pos-22;
      refresh;
      // draw_screen;
      If NOT qflag then add_bank_position('?replace_window?pos',-1,pos);
    until qflag;

  HideCursor;
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+38+2;
  move_to_screen_area[4] := ystart+10+1;
  move2screen;

  If qflag and (pos > 22) then
    begin
      status_backup.replay_forbidden := replay_forbidden;
      status_backup.play_status := play_status;
      replay_forbidden := TRUE;
      If (play_status <> isStopped) then play_status := isPaused;
      PATTERN_position_preview(BYTE_NULL,BYTE_NULL,BYTE_NULL,0);

      event_to_find.note := FilterStr(replace_data.event_to_find.note,#250,'?');
      event_to_find.inst := FilterStr(replace_data.event_to_find.inst,#250,'?');
      event_to_find.fx_1 := FilterStr(replace_data.event_to_find.fx_1,#250,'?');
      event_to_find.fx_2 := FilterStr(replace_data.event_to_find.fx_2,#250,'?');

      new_event.note := FilterStr(replace_data.new_event.note,#250,'?');
      new_event.inst := FilterStr(replace_data.new_event.inst,#250,'?');
      new_event.fx_1 := FilterStr(replace_data.new_event.fx_1,#250,'?');
      new_event.fx_2 := FilterStr(replace_data.new_event.fx_2,#250,'?');

      Case replace_selection of
        1: begin
             patt0  := pattern_patt;
             patt1  := patt0;
             track0 := 1;
             track1 := songdata.nm_tracks;
             line0  := 0;
             line1  := PRED(songdata.patt_len);
           end;

        2: begin
             patt0  := 0;
             patt1  := patterns;
             track0 := 1;
             track1 := songdata.nm_tracks;
             line0  := 0;
             line1  := PRED(songdata.patt_len);
           end;

        3: begin
             patt0  := pattern_patt;
             patt1  := patt0;
             track0 := count_channel(pattern_hpos);
             track1 := track0;
             line0  := 0;
             line1  := PRED(songdata.patt_len);
           end;

        4: begin
             patt0  := pattern_patt;
             patt1  := patt0;
             track0 := block_x0;
             track1 := block_x1;
             line0  := block_y0;
             line1  := block_y1;
           end;
      end;

      _replace_all := FALSE;
      _cancel := FALSE;
      _1st_choice := TRUE;

      For temp3 := patt0 to patt1 do
        For temp2 := track0 to track1 do
          For temp1 := line0 to line1 do
            If NOT _cancel then
              begin
                get_chunk(temp3,temp1,temp2,chunk);
                old_chunk := chunk;

                If SameName(event_to_find.inst,byte2hex(old_chunk.instr_def)) and
                   SameName(event_to_find.fx_1,fx_digits[old_chunk.effect_def]+byte2hex(old_chunk.effect)) and
                   SameName(event_to_find.fx_2,fx_digits[old_chunk.effect_def2]+byte2hex(old_chunk.effect2)) then
                  begin
                    _valid_note := FALSE;
                    Case old_chunk.note of
                      0,
                      1..12*8+1: If SameName(event_to_find.note,note_layout[old_chunk.note]) then
                                   begin
                                     temp_note := _find_note(_wildcard_str(new_event.note,note_layout[old_chunk.note]),old_chunk.note);
                                     _valid_note := TRUE;
                                   end;

                      fixed_note_flag+
                      1..
                      fixed_note_flag+
                      12*8+1: If SameName(event_to_find.note,note_layout[old_chunk.note-fixed_note_flag]) then
                                begin
                                  If NOT (FilterStr(replace_data.new_event.note,'?',#250) = note_keyoff_str[pattern_layout]) then
                                    temp_note := fixed_note_flag+_find_note(_wildcard_str(new_event.note,note_layout[old_chunk.note-fixed_note_flag]),old_chunk.note)
                                  else temp_note := _find_note(new_event.note,old_chunk.note);
                                  _valid_note := TRUE;
                                end;

                      BYTE_NULL: If (replace_data.event_to_find.note = note_keyoff_str[pattern_layout]) then
                                   begin
                                     temp_note := _find_note(new_event.note,old_chunk.note);
                                     _valid_note := TRUE;
                                   end;
                    end;

                    If _valid_note and (new_event.note <> '???') then
                      If (new_event.note <> #7#7#7) then chunk.note := temp_note
                      else chunk.note := 0;

                    If _valid_note and (new_event.inst <> '??') then
                      chunk.instr_def := Str2num(_wildcard_str(new_event.inst,byte2hex(old_chunk.instr_def)),16);

                    If _valid_note and (new_event.fx_1 <> '???') then
                      begin
                        chunk.effect_def := _find_fx(_wildcard_str(new_event.fx_1[1],fx_digits[old_chunk.effect_def])[1]);
                        chunk.effect := Str2num(_wildcard_str(new_event.fx_1[2]+new_event.fx_1[3],byte2hex(old_chunk.effect)),16);
                      end;

                    If _valid_note and (new_event.fx_2 <> '???') then
                      begin
                        chunk.effect_def2 := _find_fx(_wildcard_str(new_event.fx_2[1],fx_digits[old_chunk.effect_def2])[1]);
                        chunk.effect2 := Str2num(_wildcard_str(new_event.fx_2[2]+new_event.fx_2[3],byte2hex(old_chunk.effect2)),16);
                      end;
                  end;

                If NOT Compare(chunk,old_chunk,SizeOf(chunk)) then
                  begin
                    If replace_prompt and NOT _replace_all then
                      begin
                        PATTERN_position_preview(temp3,temp1,temp2,1);
                        keyboard_reset_buffer;
                        If _1st_choice then
                          temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                         'LiNE #'   +byte2hex(temp1)+', '+
                                         'TRACK #'  +Num2str(temp2,10)+'$'+
                                         'FOUND OCCURENCE$',
                                         '~R~EPLACE$REPLACE ~A~LL$~S~KiP$S~K~iP ALL$~C~ANCEL$',
                                         ' REPLACE ',1)
                        else
                          temp := Dialog('PATTERN #'+byte2hex(temp3)+', '+
                                         'LiNE #'   +byte2hex(temp1)+', '+
                                         'TRACK #'  +Num2str(temp2,10)+'$'+
                                         'FOUND OCCURENCE$',
                                         '~R~EPLACE$REPLACE ~A~LL$~S~KiP$S~K~iP ALL$CANCEL$',
                                         ' REPLACE ',1);

                        If (dl_environment.keystroke <> kESC) then
                          begin
                            _1st_choice := FALSE;
                            If (temp = 2) then _replace_all := TRUE
                            else If (temp = 3) then CONTINUE
                                 else If (temp in [4,5]) then
                                        begin
                                          _cancel := TRUE;
                                          BREAK;
                                        end;
                          end
                        else If NOT _1st_choice then CONTINUE
                             else begin
                                    _cancel := TRUE;
                                    BREAK;
                                  end;
                      end;

                    put_chunk(temp3,temp1,temp2,chunk);
                  end;
              end;

      PATTERN_position_preview(BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL);
      replay_forbidden := status_backup.replay_forbidden;
      play_status := status_backup.play_status;
    end;

  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(pattern_page);
end;

procedure POSITIONS_reset;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:POSITIONS_reset';
{$ENDIF}

  pattord_page := 0; pattord_hpos := 1; pattord_vpos := 1;
  instrum_page := 1;
  pattern_page := 0; pattern_hpos := 1;

  If (songdata.pattern_order[0] > $7f) then pattern_patt := 0
  else pattern_patt := songdata.pattern_order[0];

  chan_pos := 1;
  PATTERN_ORDER_page_refresh(0);
  PATTERN_page_refresh(0);
end;

const
  _perc_char: array[1..5] of Char = #160#161#162#163#164;
  _panning: array[0..3] of String = (#21#22,#21'`'#22'`','`'#21'`'#22,'`'#21#22'`');
  _connection: array[0..1] of String = ('FM','AM');
  _off_on: array[1..4,0..1] of Char = (#250'T',#250'V',#250'K',#250'S');
  _win_title: array[Boolean] of String = (' DEBUG iNFO ','');
  _contxt_str: String = ' LSHiFT/RSHiFT '#196#16' TOGGLE DETAiLS ';

procedure DEBUG_INFO;

const
  NOFX = '        ';

function effect_str(effect_def,effect,effect_def2: Byte): String;
begin
  Case effect_def of
    ef_Arpeggio:          If (effect <> 0) then effect_str := 'Arpeggio'
                          else effect_str := NOFX;
    ef_VolSlide:          If (effect DIV 16 <> 0) then effect_str := 'VolSld'#24' '
                          else effect_str := 'VolSld'#25' ';
    ef_VolSlideFine:      If (effect DIV 16 <> 0) then effect_str := 'VolSld'#18' '
                          else effect_str := 'VolSld'#23' ';
    ef_TPortamVolSlide:   If (effect DIV 16 <> 0) then effect_str := 'Por'#13'VSl'#24''
                          else effect_str := 'Por'#13'VSl'#25;
    ef_VibratoVolSlide:   If (effect DIV 16 <> 0) then effect_str := 'VibrVSl'#24''
                          else effect_str := 'VibrVSl'#25;
    ef_TPortamVSlideFine: If (effect DIV 16 <> 0) then effect_str := 'Por'#13'VSl'#18''
                          else effect_str := 'Por'#13'VSl'#23;
    ef_VibratoVSlideFine: If (effect DIV 16 <> 0) then effect_str := 'VibrVSl'#18''
                          else effect_str := 'VibrVSl'#23;
    ef_ArpggVSlide:       If (effect DIV 16 <> 0) then effect_str := 'ArpgVSl'#24''
                          else effect_str := 'ArpgVSl'#25;
    ef_ArpggVSlideFine:   If (effect DIV 16 <> 0) then effect_str := 'ArpgVSl'#18''
                          else effect_str := 'ArpgVSl'#23;

    ef_SetWaveform:       If NOT (effect MOD 16 in [0..7]) then
                            effect_str := 'SetW'#26'Car'
                          else If NOT (effect DIV 16 in [0..7]) then
                                 effect_str := 'SetW'#26'Mod'
                               else effect_str := 'SetWform';

    ef_FSlideUpVSlide:    If (effect DIV 16 <> 0) then effect_str := 'Por'#24'VSl'#24''
                          else effect_str := 'Por'#24'VSl'#25;
    ef_FSlUpVSlF:         If (effect DIV 16 <> 0) then effect_str := 'Por'#24'VSl'#18''
                          else effect_str := 'Por'#24'VSl'#23;
    ef_FSlideDownVSlide:  If (effect DIV 16 <> 0) then effect_str := 'Por'#25'VSl'#24''
                          else effect_str := 'Por'#25'VSl'#25;
    ef_FSlDownVSlF:       If (effect DIV 16 <> 0) then effect_str := 'Por'#25'VSl'#18''
                          else effect_str := 'Por'#25'VSl'#23;
    ef_FSlUpFineVSlide:   If (effect DIV 16 <> 0) then effect_str := 'Por'#18'VSl'#24''
                          else effect_str := 'Por'#18'VSl'#25;
    ef_FSlUpFineVSlF:     If (effect DIV 16 <> 0) then effect_str := 'Por'#18'VSl'#18''
                          else effect_str := 'Por'#18'VSl'#23;
    ef_FSlDownFineVSlide: If (effect DIV 16 <> 0) then effect_str := 'Por'#23'VSl'#24''
                          else effect_str := 'Por'#23'VSl'#25;
    ef_FSlDownFineVSlF:   If (effect DIV 16 <> 0) then effect_str := 'Por'#23'VSl'#18''
                          else effect_str := 'Por'#23'VSl'#23;

    ef_FSlideUp:          effect_str := 'Porta'#24'  ';
    ef_FSlideDown:        effect_str := 'Porta'#25'  ';
    ef_TonePortamento:    effect_str := 'Porta'#13'  ';
    ef_Vibrato:           effect_str := 'Vibrato ';
    ef_FSlideUpFine:      effect_str := 'Porta'#18'  ';
    ef_FSlideDownFine:    effect_str := 'Porta'#23'  ';
    ef_SetCarrierVol:     effect_str := 'SetCVol ';
    ef_SetModulatorVol:   effect_str := 'SetMVol ';
    ef_PositionJump:      effect_str := 'PosJump ';
    ef_SetInsVolume:      effect_str := 'SetVol  ';
    ef_PatternBreak:      effect_str := 'PatBreak';
    ef_SetTempo:          effect_str := 'SetTempo';
    ef_SetSpeed:          effect_str := 'SetSpeed';
    ef_RetrigNote:        effect_str := 'Retrig'#13' ';
    ef_MultiRetrigNote:   effect_str := 'MulRetr'#13;
    ef_Tremolo:           effect_str := 'Tremolo ';
    ef_Tremor:            effect_str := 'Tremor  ';
    ef_SetGlobalVolume:   effect_str := 'SetGlVol';
    ef_ForceInsVolume:    effect_str := 'ForceVol';

    ef_Extended:
      Case effect DIV 16 of
        ef_ex_SetTremDepth:   effect_str := 'SetTremD';
        ef_ex_SetVibDepth:    effect_str := 'SetVibrD';
        ef_ex_SetAttckRateM:  effect_str := '[A]DSR'#26'M';
        ef_ex_SetDecayRateM:  effect_str := 'A[D]SR'#26'M';
        ef_ex_SetSustnLevelM: effect_str := 'AD[S]R'#26'M';
        ef_ex_SetRelRateM:    effect_str := 'ADS[R]'#26'M';
        ef_ex_SetAttckRateC:  effect_str := '[A]DSR'#26'C';
        ef_ex_SetDecayRateC:  effect_str := 'A[D]SR'#26'C';
        ef_ex_SetSustnLevelC: effect_str := 'AD[S]R'#26'C';
        ef_ex_SetRelRateC:    effect_str := 'ADS[R]'#26'C';
        ef_ex_SetFeedback:    effect_str := 'SetFeedb';
        ef_ex_PatternLoop:    effect_str := 'PatLoop ';
        ef_ex_PatternLoopRec: effect_str := 'PatLoopR';

        ef_ex_SetPanningPos:
          Case effect MOD 16 of
            0: effect_str := 'SetPan'#26'C';
            1: effect_str := 'SetPan'#26'L';
            2: effect_str := 'SetPan'#26'R';
          end;

        ef_ex_ExtendedCmd:
          Case effect MOD 16 of
            ef_ex_cmd_MKOffLoopDi: effect_str := #12'LoopOff';
            ef_ex_cmd_MKOffLoopEn: effect_str := #12'LoopOn ';
            ef_ex_cmd_TPortaFKdis: effect_str := 'Porta'#13'K-';
            ef_ex_cmd_TPortaFKenb: effect_str := 'Porta'#13'K+';
            ef_ex_cmd_RestartEnv:  effect_str := 'RstrtEnv';
            ef_ex_cmd_4opVlockOff: effect_str := 'VLock'#4#3'-';
            ef_ex_cmd_4opVlockOn:  effect_str := 'VLock'#4#3'+';
            ef_ex_cmd_ForceBpmSld: effect_str := 'BpmSlide';
          end;

        ef_ex_ExtendedCmd2:
          Case effect MOD 16 of
            ef_ex_cmd2_RSS:        effect_str := 'RelSS   ';
            ef_ex_cmd2_ResetVol:   effect_str := 'ResetVol';
            ef_ex_cmd2_LockVol:    effect_str := 'VolLock+';
            ef_ex_cmd2_UnlockVol:  effect_str := 'VolLock-';
            ef_ex_cmd2_LockVP:     effect_str := 'LockVP+ ';
            ef_ex_cmd2_UnlockVP:   effect_str := 'LockVP- ';
            ef_ex_cmd2_VSlide_car: effect_str := 'VSld'#26'Car';
            ef_ex_cmd2_VSlide_mod: effect_str := 'VSld'#26'Mod';
            ef_ex_cmd2_VSlide_def: effect_str := 'VSld'#26'Def';
            ef_ex_cmd2_LockPan:    effect_str := 'PanLock+';
            ef_ex_cmd2_UnlockPan:  effect_str := 'PanLock-';
            ef_ex_cmd2_VibrOff:    effect_str := 'VibrOff ';
            ef_ex_cmd2_TremOff:    effect_str := 'TremOff ';
            ef_ex_cmd2_FVib_FGFS:  If NOT (effect_def2 in [ef_GlobalFSlideUp,ef_GlobalFSlideDown]) then
                                    effect_str := 'VibrFine'
                                  else effect_str := 'GlPortaF';
            ef_ex_cmd2_FTrm_XFGFS: If NOT (effect_def2 in [ef_GlobalFSlideUp,ef_GlobalFSlideDown]) then
                                    effect_str := 'TremFine'
                                  else effect_str := 'GlPortXF';
            ef_ex_cmd2_NoRestart:  effect_str := 'ArpVibNR';
            else                  effect_str := NOFX;
          end;
        else effect_str := NOFX;
      end;

    ef_Extended2:
      Case effect DIV 16 of
        ef_ex2_PatDelayFrame: effect_str := 'PatDelF ';
        ef_ex2_PatDelayRow:   effect_str := 'PatDelR ';
        ef_ex2_NoteDelay:     effect_str := 'Delay'#13'  ';
        ef_ex2_NoteCut:       effect_str := 'Cut'#13'    ';
        ef_ex2_GlVolSlideUp:  effect_str := 'GlVolSl'#24;
        ef_ex2_GlVolSlideDn:  effect_str := 'GlVolSl'#25;
        ef_ex2_GlVolSlideUpF: effect_str := 'GlVolSl'#18;
        ef_ex2_GlVolSlideDnF: effect_str := 'GlVolSl'#23;
        ef_ex2_FineTuneUp:    effect_str := 'FTune'#24'  ';
        ef_ex2_FineTuneDown:  effect_str := 'FTune'#25'  ';
        ef_ex2_GlVolSldUpXF:  effect_str := 'GVolSl'#12#18;
        ef_ex2_GlVolSldDnXF:  effect_str := 'GVolSl'#12#23;
        ef_ex2_VolSlideUpXF:  effect_str := 'VolSld'#12#18;
        ef_ex2_VolSlideDnXF:  effect_str := 'VolSld'#12#23;
        ef_ex2_FreqSlideUpXF: effect_str := 'Porta'#12#18' ';
        ef_ex2_FreqSlideDnXF: effect_str := 'Porta'#12#23' ';
      end;

    ef_SwapArpeggio: effect_str := 'ArpT'#26+byte2hex(effect)+' ';
    ef_SwapVibrato:  effect_str := 'VibT'#26+byte2hex(effect)+' ';

    ef_Extended3:
      Case effect DIV 16 of
        ef_ex3_SetConnection: If (effect MOD 16 = 0) then effect_str := 'Conct'#26'FM'
                              else effect_str := 'Conct'#26'AM';
        ef_ex3_SetMultipM:    effect_str := 'Multip'#26'M';
        ef_ex3_SetKslM:       effect_str := 'KSL'#26'M   ';
        ef_ex3_SetTremoloM:   effect_str := 'Trem'#26'M  ';
        ef_ex3_SetVibratoM:   effect_str := 'Vibr'#26'M  ';
        ef_ex3_SetKsrM:       effect_str := 'KSR'#26'M   ';
        ef_ex3_SetSustainM:   effect_str := 'Sustn'#26'M ';
        ef_ex3_SetMultipC:    effect_str := 'Multip'#26'C';
        ef_ex3_SetKslC:       effect_str := 'KSL'#26'C   ';
        ef_ex3_SetTremoloC:   effect_str := 'Trem'#26'C  ';
        ef_ex3_SetVibratoC:   effect_str := 'Vibr'#26'C  ';
        ef_ex3_SetKsrC:       effect_str := 'KSR'#26'C   ';
        ef_ex3_SetSustainC:   effect_str := 'Sustn'#26'C ';
      end;

    ef_ExtraFineArpeggio: effect_str := 'Arpggio'#12;
    ef_ExtraFineVibrato:  effect_str := 'Vibrato'#12;
    ef_ExtraFineTremolo:  effect_str := 'Tremolo'#12;
    ef_SetCustomSpeedTab: effect_str := 'SetCusST';
    ef_GlobalFSlideUp:    effect_str := 'GlPorta'#24;
    ef_GlobalFSlideDown:  effect_str := 'GlPorta'#25;

    else effect_str := NOFX;
  end;
end;

function note_str(note,chan: Byte): String;
begin
  If (note < 100) then note_str := note_layout[note]+' '
  else If (note AND $7f <> 0) then note_str := note_layout[note AND $7f]+#12
       else note_str := note_layout[0]+' ';
end;

function cstr2str(str: String): String;

var
  temp: Byte;

begin
  For temp := 1 to Length(str) do
    If (str[temp] = '~') then Delete(str,temp,1);
  cstr2str := str;
end;

function last_chan_pos: Byte;
begin
  If (songdata.nm_tracks > MAX_TRACKS) then
    last_chan_pos := max(16,songdata.nm_tracks-MAX_TRACKS+1)
  else last_chan_pos := 1;
end;

function last_hpos: Byte;
begin
  last_hpos := max(_pattedit_lastpos,songdata.nm_tracks*(_pattedit_lastpos DIV MAX_TRACKS));
end;

function _macro_str(str: String; null_byte: Byte): String;
begin
  If (null_byte <> 0) then _macro_str := str
  else _macro_str := ExpStrL('',C3StrLen(str),' ');
end;

function _freq_slide_str(value: Shortint): String;
begin
  If (value = 0) then _freq_slide_str := '`'#10'`'
  else If (value > 0) then _freq_slide_str := #24
       else _freq_slide_str := #25;
end;

const
  IDLE = $0fff;
  FINISHED = $0ffff;
  note_keyoff_str: array[Boolean] of String = ('`'#12'`',#12);

function _macro_pos_str_fm(pos,len: Word; keyoff_pos,duration: Byte;
                           retrig_note: Byte; freq_slide: Smallint): String;
begin
  If (pos <= 255) then
    _macro_pos_str_fm := byte2hex(pos)+'/'+byte2hex(len)+':'+byte2hex(duration)+' '+macro_retrig_str[retrig_note]+
                         _freq_slide_str(freq_slide)+note_keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)]+'`'#251'`'
  else If (pos = IDLE) then
         _macro_pos_str_fm := #250#250#12#250#250':'#250#250'     '
       else _macro_pos_str_fm := byte2hex(len)+'/'+byte2hex(len)+':'+byte2hex(duration)+' '+macro_retrig_str[retrig_note]+
                         _freq_slide_str(freq_slide)+note_keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)]+#251;
end;

function _macro_pos_str_av(pos,len: Word; keyoff_pos: Byte; slide_str: String): String;
begin
  If (pos <= 255) then
    _macro_pos_str_av := byte2hex(pos)+'/'+byte2hex(len)+' '+slide_str+
                         note_keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)]
  else If (pos = IDLE) then
         _macro_pos_str_av := #250#250#12#250#250' '+slide_str+
                              note_keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)]
       else _macro_pos_str_av := byte2hex(len)+'/'+byte2hex(len)+' '+slide_str+
                                 note_keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)];
end;

var
  temp,temp2,atr1,atr2,atr3,atr4,xstart,ystart: Byte;
  temps,temps2,temps3: String;
  old_debugging,old_replay_forbidden: Boolean;
  old_play_status: tPLAY_STATUS;
  _ctrl_alt_flag,
  _reset_state: Boolean;
  _win_attr: array[Boolean] of Byte;
  _details_flag,_macro_details_flag: Boolean;
  fkey: Word;
  bckg_attr,current_track: Byte;

label _jmp1;

begin { DEBUG_INFO }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:DEBUG_INFO';
{$ENDIF}
  _ctrl_alt_flag := ctrl_pressed AND alt_pressed;
  _win_attr[FALSE] := debug_info_bckg+debug_info_border2;
  _win_attr[TRUE] := debug_info_bckg+debug_info_border;
  _reset_state := FALSE;

  If NOT _ctrl_alt_flag then
    begin
      temp := get_bank_position('?debug_info?details_flag',-1);
      Case temp of
        0: begin
             _details_flag := FALSE;
             _macro_details_flag := FALSE;
           end;
        1: begin
             _details_flag := TRUE;
             _macro_details_flag := FALSE;
           end;
        2: begin
             _details_flag := TRUE;
             _macro_details_flag := TRUE;
           end;
      end;
    end;

_jmp1:

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  centered_frame_vdest := screen_ptr;
  HideCursor;
  centered_frame(xstart,ystart,83,songdata.nm_tracks+6,
                 _win_title[_ctrl_alt_flag],_win_attr[_ctrl_alt_flag],
                 debug_info_bckg+debug_info_title,
                 frame_double);

  Repeat
    If _ctrl_alt_flag then
      begin
        _details_flag := shift_pressed;
        _macro_details_flag := NOT left_shift_pressed and right_shift_pressed;
      end;

    If _ctrl_alt_flag then
      If NOT _details_flag then
        ShowStr(screen_ptr,xstart+83-Length(_contxt_str),ystart+songdata.nm_tracks+6,
                _contxt_str,
                debug_info_bckg+debug_info_topic)
      else
        ShowStr(screen_ptr,xstart+83-Length(_contxt_str),ystart+songdata.nm_tracks+6,
                ExpStrL('',Length(_contxt_str),#205),
                debug_info_bckg+debug_info_border);

    If space_pressed and (play_status <> isStopped) then
      If NOT _ctrl_alt_flag and ctrl_pressed and
         NOT alt_pressed and NOT shift_pressed then
        begin
          debugging := FALSE;
          _reset_state := FALSE;
        end
      else If NOT _reset_state then
             begin
               _reset_state := TRUE;
               old_debugging := debugging;
               old_play_status := play_status;
               old_replay_forbidden := replay_forbidden;
               debugging := TRUE;
               play_status := isPlaying;
               replay_forbidden := FALSE;
               STATUS_LINE_refresh;
             end;

    If NOT _details_flag then
      begin
        ShowCStr(screen_ptr,xstart+2,ystart+1,
                 debug_win_str1[1],
                 debug_info_bckg+debug_info_topic,debug_info_bckg+debug_info_border);
        ShowStr(screen_ptr,xstart+2,ystart+2,
                debug_win_str1[2],
                debug_info_bckg+debug_info_border);
        ShowStr(screen_ptr,xstart+2,ystart+songdata.nm_tracks+3,
                debug_win_str1[3],
                debug_info_bckg+debug_info_border);
        If NOT _ctrl_alt_flag then
          ShowCStr(screen_ptr,xstart+76,ystart+songdata.nm_tracks+6,' [~1/3~] ',
                   _win_attr[_ctrl_alt_flag],
                   debug_info_bckg+debug_info_topic);
      end
    else If NOT _macro_details_flag then
           begin
             ShowCStr(screen_ptr,xstart+2,ystart+1,
                      debug_win_str2[1],
                      debug_info_bckg+debug_info_topic,debug_info_bckg+debug_info_border);
             ShowStr(screen_ptr,xstart+2,ystart+2,
                     debug_win_str2[2],
                     debug_info_bckg+debug_info_border);
             ShowStr(screen_ptr,xstart+2,ystart+songdata.nm_tracks+3,
                     debug_win_str2[3],
                     debug_info_bckg+debug_info_border);
             If NOT _ctrl_alt_flag then
               ShowCStr(screen_ptr,xstart+76,ystart+songdata.nm_tracks+6,' [~2/3~] ',
                        _win_attr[_ctrl_alt_flag],
                        debug_info_bckg+debug_info_topic);
           end
         else begin
                ShowCStr(screen_ptr,xstart+2,ystart+1,
                         debug_win_str3[1],
                         debug_info_bckg+debug_info_topic,debug_info_bckg+debug_info_border);
                ShowStr(screen_ptr,xstart+2,ystart+2,
                        debug_win_str3[2],
                        debug_info_bckg+debug_info_border);
                ShowStr(screen_ptr,xstart+2,ystart+songdata.nm_tracks+3,
                        debug_win_str3[3],
                        debug_info_bckg+debug_info_border);
                If NOT _ctrl_alt_flag then
                  ShowCStr(screen_ptr,xstart+76,ystart+songdata.nm_tracks+6,' [~3/3~] ',
                           _win_attr[_ctrl_alt_flag],
                           debug_info_bckg+debug_info_topic);
              end;

    If NOT play_single_patt and NOT replay_forbidden and
       repeat_pattern then temps := '~'#19'~'
    else temps := #19;

    If NOT play_single_patt then
      ShowCStr(screen_ptr,
               xstart+2,ystart+songdata.nm_tracks+4,
               '~ORDER/PATTERN/ROW~  '+byte2hex(current_order)+'/'+
               byte2hex(current_pattern)+'/'+
               byte2hex(current_line),
               debug_info_bckg+debug_info_txt,
               debug_info_bckg+debug_info_hi_txt)
    else
      ShowCStr(screen_ptr,
               xstart+2,ystart+songdata.nm_tracks+4,
               '~ORDER/PATTERN/ROW~  --/'+
               byte2hex(current_pattern)+'/'+
               byte2hex(current_line),
               debug_info_bckg+debug_info_txt,
               debug_info_bckg+debug_info_hi_txt);

    ShowCStr(screen_ptr,
             xstart+30,ystart+songdata.nm_tracks+4,
             temps,
             debug_info_bckg+debug_info_txt_hid,
             debug_info_bckg+debug_info_txt);

    If (tempo < 100) then
      If (tempo = 18) and timer_fix then temps := num2str(tempo,10)+#5+#174
      else temps := num2str(tempo,10)+#174
    else temps := num2str(tempo,10)+#174;

    If (_macro_speedup = 1) then temps2 := temps
    else begin
           temp := calc_max_speedup(tempo);
           If (_macro_speedup <= temp) then
             temps2 := Num2str(tempo*_macro_speedup,10)+#174
           else temps2 := Num2str(tempo*temp,10)+#174;
         end;

    ShowCStr(screen_ptr,
             xstart+2,ystart+songdata.nm_tracks+5,
             '~SPEED/TEMPO/MACROS~ '+byte2hex(speed)+'/'+
             ExpStrR(temps+'/'+temps2,9,' '),
             debug_info_bckg+debug_info_txt,
             debug_info_bckg+debug_info_hi_txt);

    Case current_tremolo_depth of
      0: temps := '1dB';
      1: temps := '4.8dB';
    end;

    Case current_vibrato_depth of
      0: temps2 := '7%    ';
      1: temps2 := '14%   ';
    end;

    ShowCStr(screen_ptr,
             xstart+36,ystart+songdata.nm_tracks+4,
             '~TREMOLO/ViBRATO DEPTH~ '+
             temps+'/'+temps2,
             debug_info_bckg+debug_info_txt,
             debug_info_bckg+debug_info_hi_txt);

    ShowCStr(screen_ptr,
             xstart+36,ystart+songdata.nm_tracks+5,
             '~GLOBAL VOLUME~         '+
             ExpStrR(Num2str(global_volume,16),2,'0'),
             debug_info_bckg+debug_info_txt,
             debug_info_bckg+debug_info_hi_txt);

    temps := ' '+
             ExpStrL(Num2str(song_timer DIV 60,10),2,'0')+':'+
             ExpStrL(Num2str(song_timer MOD 60,10),2,'0')+'.'+
             CHR(48+song_timer_tenths DIV 10)+' ';

    If (play_status <> isStopped) then
      temps := '~'+temps+'~';

    ShowCStr(screen_ptr,
             xstart+74,ystart+songdata.nm_tracks+4,
             temps,
             debug_info_bckg+debug_info_txt,
             debug_info_bckg+debug_info_hi_txt);

    temps := Bpm2str(calc_realtime_bpm_speed(tempo,speed,mark_line))+' BPM';
    If (IRQ_freq_shift+playback_speed_shift > 0) then
      temps := temps+' [+'+Num2str(IRQ_freq_shift+playback_speed_shift,10)+#174']'
    else If (IRQ_freq_shift+playback_speed_shift < 0) then
           temps := temps+' [-'+Num2str(Abs(IRQ_freq_shift+playback_speed_shift),10)+#174']';

    ShowStr(screen_ptr,
            xstart+62,ystart+songdata.nm_tracks+5,
            ExpStrL(temps,20,' '),
            debug_info_bckg+debug_info_bpm);

    current_track := count_channel(pattern_hpos);
    For temp := 1 to songdata.nm_tracks do
      begin
        If NOT _ctrl_alt_flag and (temp = current_track) then
          bckg_attr := debug_info_bckg2
        else bckg_attr := debug_info_bckg;

        If channel_flag[temp] then
          If event_new[temp] then atr1 := bckg_attr+debug_info_hi_txt
          else atr1 := bckg_attr+debug_info_txt
        else atr1 := bckg_attr+debug_info_txt_hid;

        If channel_flag[temp] then
          If event_new[temp] then atr2 := bckg_attr+debug_info_hi_txt
          else atr2 := bckg_attr+debug_info_txt
        else atr2 := bckg_attr+debug_info_txt_hid;

        If channel_flag[temp] then
          If event_new[temp] then atr3 := bckg_attr+debug_info_hi_car
          else atr3 := bckg_attr+debug_info_car
        else atr3 := bckg_attr+debug_info_txt_hid;

        If channel_flag[temp] then
          If event_new[temp] then atr4 := bckg_attr+debug_info_hi_mod
          else atr4 := bckg_attr+debug_info_mod
        else atr4 := bckg_attr+debug_info_txt_hid;

        If percussion_mode and (temp in [16..20]) then temps := _perc_char[temp-15]
        else Case temp of
               1:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then temps := #172
                   else temps := ' ';
               2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then temps := #173
                   else temps := ' ';
               3:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then temps := #172
                   else temps := ' ';
               4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then temps := #173
                   else temps := ' ';
               5:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then temps := #172
                   else temps := ' ';
               6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then temps := #173
                   else temps := ' ';
               10: If (songdata.flag_4op OR 8 = songdata.flag_4op) then temps := #172
                   else temps := ' ';
               11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then temps := #173
                   else temps := ' ';
               12: If (songdata.flag_4op OR $10 = songdata.flag_4op) then temps := #172
                   else temps := ' ';
               13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then temps := #173
                   else temps := ' ';
               14: If (songdata.flag_4op OR $20 = songdata.flag_4op) then temps := #172
                   else temps := ' ';
               15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then temps := #173
                   else temps := ' ';
               else temps := ' ';
             end;

        ShowStr(screen_ptr,xstart+1,ystart+temp+2,
                temps,
                bckg_attr+debug_info_perc);

        ShowCStr(screen_ptr,xstart+2,ystart+temp+2,
                 ExpStrL(Num2str(temp,10),2,' '),
                 atr1,
                 bckg_attr+debug_info_txt_hid);

        If NOT _details_flag then
          If (event_table[temp].instr_def in [1..255]) then
            begin
              temps := ExpStrR(cstr2str(Copy(songdata.instr_names[event_table[temp].instr_def],2,30)),30,' ');
              Delete(temps,7,1);
              Insert('~'#247'~',temps,7);
            end
          else temps := ExpStrR('      ~'#247'~',30+2,' ')
        else If (event_table[temp].instr_def in [1..255]) then temps := 'i'+byte2hex(event_table[temp].instr_def)
             else temps := ExpStrR('',3,' ');

        If (play_status = isStopped) and NOT debugging then temp2 := 3
        else temp2 := panning_table[temp];

        Case (songdata.lock_flags[temp] SHR 2 AND 3) of
          0: temps2 := #250#24#25;
          1: temps2 := 'C'#24#25;
          2: temps2 := 'M'#24#25;
          3: temps2 := '&'#24#25;
        end;

        If (songdata.lock_flags[temp] SHR 2 AND 3 = 0) or
           ((play_status = isStopped) and NOT debugging) then
          temps2 := '`'+temps2+'`';

        If lockvol and (songdata.lock_flags[temp] OR $10 = songdata.lock_flags[temp]) then
          temps2 := temps2+'~'#179'~V+'
        else temps2 := temps2+'~'#179'~`V+`';

        If lockVP and (songdata.lock_flags[temp] OR $20 = songdata.lock_flags[temp]) then
          temps2 := temps2+'~'#179'~P+'
        else temps2 := temps2+'~'#179'~`P+`';

        If NOT (is_4op_chan(temp) and (temp in _4op_tracks_hi)) then
          temps3 := ExpStrL(Num2str(freqtable2[temp],16),4,'0')
        else temps3 := '    ';

        If NOT _details_flag then
          begin
            If pan_lock[temp] then
              ShowC3Str(screen_ptr,xstart+4,ystart+temp+2,
                        '~'#179'~'+_panning[temp2]+'~'#179'~',
                        atr2,
                        bckg_attr+debug_info_border,
                        bckg_attr+debug_info_txt_hid)
            else ShowC3Str(screen_ptr,xstart+4,ystart+temp+2,
                           '~'#179'~'+_panning[temp2]+'~'#179'~',
                           atr3,
                           bckg_attr+debug_info_border,
                           bckg_attr+debug_info_txt_hid);

            ShowC3Str(screen_ptr,xstart+8,ystart+temp+2,
                      temps2+'~'#179'~',
                      atr2,
                      bckg_attr+debug_info_border,
                      bckg_attr+debug_info_txt_hid);

            ShowCStr(screen_ptr,xstart+18,ystart+temp+2,
                     temps+'~'#179'~'+
                     note_str(event_table[temp].note,temp)+'~'#179'~'+
                     effect_str(event_table[temp].effect_def,
                                event_table[temp].effect,
                                event_table[temp].effect_def2)+'~'#179'~'+
                     effect_str(event_table[temp].effect_def2,
                                event_table[temp].effect2,
                                event_table[temp].effect_def)+'~'#179'~'+
                     temps3+'~'#179'~',
                     atr1,
                     bckg_attr+debug_info_border);

            If NOT (percussion_mode and (temp in [17..20])) then
              ShowCStr(screen_ptr,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~'#179'~',
                       atr3,
                       bckg_attr+debug_info_border)
            else
              ShowCStr(screen_ptr,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~'#179'~',
                       bckg_attr+bckg_attr SHR 4,
                       bckg_attr+debug_info_border);
          end
        else
          begin
            If pan_lock[temp] then
              ShowC3Str(screen_ptr,xstart+4,ystart+temp+2,
                        '~'#179'~'+_panning[temp2]+'~'#179'~',
                        atr2,
                        bckg_attr+debug_info_border,
                        bckg_attr+debug_info_txt_hid)
            else ShowC3Str(screen_ptr,xstart+4,ystart+temp+2,
                           '~'#179'~'+_panning[temp2]+'~'#179'~',
                           atr3,
                           bckg_attr+debug_info_border,
                           bckg_attr+debug_info_txt_hid);

            If NOT _macro_details_flag then
              begin
                ShowCStr(screen_ptr,xstart+8,ystart+temp+2,
                         temps+'~'#179'~'+
                         note_str(event_table[temp].note,temp)+'~'#179'~'+
                         effect_str(event_table[temp].effect_def,
                                    event_table[temp].effect,
                                    event_table[temp].effect_def2)+'~'#179'~'+
                         effect_str(event_table[temp].effect_def2,
                                    event_table[temp].effect2,
                                    event_table[temp].effect_def)+'~'#179'~'+
                         temps3+'~'#179'~',
                         atr1,bckg_attr+debug_info_border);

                If NOT (percussion_mode and (temp in [17..20])) then
                  ShowStr(screen_ptr,xstart+40,ystart+temp+2,
                          _connection[fmpar_table[temp].connect]+' '+
                          Num2str(fmpar_table[temp].feedb,16)+' ',
                          atr1)
                else
                  ShowStr(screen_ptr,xstart+40,ystart+temp+2,
                          ExpStrL('',5,' '),
                          atr1);

                If NOT (percussion_mode and (temp in [17..20])) then
                  ShowCStr(screen_ptr,xstart+45,ystart+temp+2,
                           Num2str(fmpar_table[temp].adsrw_car.attck,16)+
                           Num2str(fmpar_table[temp].adsrw_car.dec,16)+
                           Num2str(fmpar_table[temp].adsrw_car.sustn,16)+
                           Num2str(fmpar_table[temp].adsrw_car.rel,16)+' '+
                           Num2str(fmpar_table[temp].adsrw_car.wform,16)+' '+
                           Num2str(fmpar_table[temp].kslC,16)+' '+
                           Num2str(fmpar_table[temp].multipC,16)+' '+
                           _off_on[1,fmpar_table[temp].tremC]+
                           _off_on[2,fmpar_table[temp].vibrC]+
                           _off_on[3,fmpar_table[temp].ksrC]+
                           _off_on[4,fmpar_table[temp].sustC]+'~'#179'~',
                           atr3,
                           bckg_attr+debug_info_border)
                else
                  ShowCStr(screen_ptr,xstart+45,ystart+temp+2,
                           Num2str(fmpar_table[temp].adsrw_car.attck,16)+
                           Num2str(fmpar_table[temp].adsrw_car.dec,16)+
                           Num2str(fmpar_table[temp].adsrw_car.sustn,16)+
                           Num2str(fmpar_table[temp].adsrw_car.rel,16)+' '+
                           Num2str(fmpar_table[temp].adsrw_car.wform,16)+' '+
                           Num2str(fmpar_table[temp].kslC,16)+' '+
                           Num2str(fmpar_table[temp].multipC,16)+' '+
                           _off_on[1,fmpar_table[temp].tremC]+
                           _off_on[2,fmpar_table[temp].vibrC]+
                           _off_on[3,fmpar_table[temp].ksrC]+
                           _off_on[4,fmpar_table[temp].sustC]+'~'#179'~',
                           bckg_attr+bckg_attr SHR 4,
                           bckg_attr+debug_info_border);

                ShowCStr(screen_ptr,xstart+61,ystart+temp+2,
                         Num2str(fmpar_table[temp].adsrw_mod.attck,16)+
                         Num2str(fmpar_table[temp].adsrw_mod.dec,16)+
                         Num2str(fmpar_table[temp].adsrw_mod.sustn,16)+
                         Num2str(fmpar_table[temp].adsrw_mod.rel,16)+' '+
                         Num2str(fmpar_table[temp].adsrw_mod.wform,16)+' '+
                         Num2str(fmpar_table[temp].kslM,16)+' '+
                         Num2str(fmpar_table[temp].multipM,16)+' '+
                         _off_on[1,fmpar_table[temp].tremM]+
                         _off_on[2,fmpar_table[temp].vibrM]+
                         _off_on[3,fmpar_table[temp].ksrM]+
                         _off_on[4,fmpar_table[temp].sustM]+'~'#179'~',
                         atr4,
                         bckg_attr+debug_info_border);
              end
            else
              begin
                ShowCStr(screen_ptr,xstart+8,ystart+temp+2,
                         temps+'~'#179'~'+
                         note_str(event_table[temp].note,temp)+'~'#179'~'+
                         effect_str(event_table[temp].effect_def,
                                    event_table[temp].effect,
                                    event_table[temp].effect_def2)+'~'#179'~'+
                         effect_str(event_table[temp].effect_def2,
                                    event_table[temp].effect2,
                                    event_table[temp].effect_def)+'~'#179'~',
                         atr1,bckg_attr+debug_info_border);

                ShowC3Str(screen_ptr,xstart+35,ystart+temp+2,
                          _macro_str(_macro_pos_str_fm(macro_table[temp].fmreg_pos,
                                                       songdata.instr_macros[macro_table[temp].fmreg_table].length,
                                                       songdata.instr_macros[macro_table[temp].fmreg_table].keyoff_pos,
                                                       songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].duration,
                                                       songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].fm_data.FEEDBACK_FM SHR 5,
                                                       songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].freq_slide),
                                     songdata.instr_macros[macro_table[temp].fmreg_table].length)+'~'#179'~'+
                          _macro_str(byte2hex(macro_table[temp].arpg_table)+#246+
                                     _macro_pos_str_av(macro_table[temp].arpg_pos,
                                                       songdata.macro_table[macro_table[temp].arpg_table].arpeggio.length,
                                                       songdata.macro_table[macro_table[temp].arpg_table].arpeggio.keyoff_pos,
                                                       ''),
                                     macro_table[temp].arpg_table)+'~'#179'~'+
                          _macro_str(byte2hex(macro_table[temp].vib_table)+#246+
                                     _macro_pos_str_av(macro_table[temp].vib_pos,
                                                       songdata.macro_table[macro_table[temp].vib_table].vibrato.length,
                                                       songdata.macro_table[macro_table[temp].vib_table].vibrato.keyoff_pos,
                                                       _freq_slide_str(songdata.macro_table[macro_table[temp].vib_table].vibrato.data[macro_table[temp].vib_pos])),
                                     macro_table[temp].vib_table)+'~'#179'~'+
                          temps3+'~'#179'~',
                          atr1,
                          bckg_attr+debug_info_border,
                          bckg_attr+debug_info_txt_hid);
              end;

            If NOT (percussion_mode and (temp in [17..20])) then
              ShowCStr(screen_ptr,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~'#179'~',
                       atr3,
                       bckg_attr+debug_info_border)
            else
              ShowCStr(screen_ptr,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~'#179'~',
                       bckg_attr+bckg_attr SHR 4,
                       bckg_attr+debug_info_border);
          end;

        ShowCStr(screen_ptr,xstart+80,ystart+temp+2,
                 ExpStrL(Num2str(modulator_vol[temp],16),2,'0')+' ',
                 atr4,bckg_attr+debug_info_border);
      end;

    fkey := WORD_NULL;
    If _ctrl_alt_flag then
      If keypressed then keyboard_reset_buffer
      else
    else If keypressed then fkey := getkey;

    If scankey($39) { SPACE } then
      If (play_status = isStopped) then
        If (calc_pattern_pos(pattern_patt) <> BYTE_NULL) then
          begin
            fade_out_playback(FALSE);
            calibrate_player(calc_pattern_pos(pattern_patt),
                             pattern_page,TRUE,TRUE);
            If (play_status <> isStopped) then
              begin
                debugging := TRUE;
                play_status := isPlaying;
                replay_forbidden := FALSE;
                PATTERN_ORDER_page_refresh(pattord_page);
                PATTERN_page_refresh(pattern_page);
                tracing := TRUE;
              end;
          end
        else If (calc_pattern_pos(pattern_patt) = BYTE_NULL) then
               begin
                 fade_out_playback(FALSE);
                 play_single_patt := TRUE;
                 no_sync_playing := TRUE;
                 start_pattern := pattern_patt;
                 start_line := pattern_page;
                 start_playing;
                 debugging := TRUE;
                 tracing := TRUE;
               end
             else
      else If NOT tracing then
             begin
               debugging := TRUE;
               tracing := TRUE;
             end;

    Case fkey of
      kCtLEFT: If NOT debugging and (play_status = isPlaying) then
                 rewind := TRUE;

      kCtRGHT: If NOT debugging and (play_status = isPlaying) then
                 fast_forward := TRUE;

      kTAB:    If NOT _details_flag then _details_flag := TRUE
               else If NOT _macro_details_flag then _macro_details_flag := TRUE
                    else begin
                           _details_flag := FALSE;
                           _macro_details_flag := FALSE;
                         end;

      kBkSPC:  If NOT replay_forbidden then
                 repeat_pattern := NOT repeat_pattern;

      kPgUP,
      kHOME:   begin
                 chan_pos := 1;
                 pattern_hpos := 1;
                 PATTERN_ORDER_page_refresh(pattord_page);
                 PATTERN_page_refresh(pattern_page);
               end;
      kPgDOWN,
      kEND:    begin
                 chan_pos := last_chan_pos;
                 pattern_hpos := last_hpos;
                 PATTERN_ORDER_page_refresh(pattord_page);
                 PATTERN_page_refresh(pattern_page);
               end;

      kUP:     If (chan_pos > 1) then
                 begin
                   Dec(chan_pos);
                   PATTERN_ORDER_page_refresh(pattord_page);
                   PATTERN_page_refresh(pattern_page);
                 end
               else If (pattern_hpos > _pattedit_lastpos DIV MAX_TRACKS) then
                      begin
                        Dec(pattern_hpos,_pattedit_lastpos DIV MAX_TRACKS);
                        PATTERN_ORDER_page_refresh(pattord_page);
                        PATTERN_page_refresh(pattern_page);
                      end;

      kDOWN:   If (chan_pos < last_chan_pos) then
                 begin
                   Inc(chan_pos);
                   PATTERN_ORDER_page_refresh(pattord_page);
                   PATTERN_page_refresh(pattern_page);
                 end
               else If (pattern_hpos <= last_hpos-_pattedit_lastpos DIV MAX_TRACKS) then
                      begin
                        Inc(pattern_hpos,_pattedit_lastpos DIV MAX_TRACKS);
                        PATTERN_ORDER_page_refresh(pattord_page);
                        PATTERN_page_refresh(pattern_page);
                      end;

      kCHmins,
      kNPmins,
      kCtHOME: If NOT play_single_patt then
                 begin
                   temp := current_order;
                   temp2 := current_line;
                   While (temp > 0) and
                         NOT (songdata.pattern_order[temp-1] < $80) do
                     begin
                       Dec(temp);
{$IFDEF GO32V2}
                       keyboard_reset_buffer_alt;
{$ENDIF}
                     end;

                   If (temp > 0) then
                     begin
                       Dec(temp);
                       If (songdata.pattern_order[temp] < $80) then
                         begin
                           fade_out_playback(FALSE);
                           If (fkey = kCtHOME) then calibrate_player(temp,temp2,TRUE,FALSE)
                           else calibrate_player(temp,0,TRUE,FALSE);
                         end;
                     end;
                 end;

      kCHplus,
      kNPplus,
      kCtEND:  If NOT play_single_patt then
                 begin
                   temp := current_order;
                   temp2 := current_line;
                   While (temp < $7f) and
                         (songdata.pattern_order[SUCC(temp)] > $80) do
                     begin
                       Inc(temp);
{$IFDEF GO32V2}
                       keyboard_reset_buffer_alt;
{$ENDIF}
                     end;

                   If (temp < $7f) then
                     begin
                       Inc(temp);
                       If (songdata.pattern_order[temp] < $80) then
                         begin
                           fade_out_playback(FALSE);
                           If (fkey = kCtEND) then calibrate_player(temp,temp2,TRUE,FALSE)
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
      kAlt9:
{$IFNDEF GO32V2}
               If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
{$ENDIF}
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
                 end;
      kAlt0:
{$IFNDEF GO32V2}
               If (opl3_channel_recording_mode and (play_status <> isStopped)) then fkey := WORD_NULL
               else
{$ENDIF}
                 If (shift_pressed and (songdata.nm_tracks > 9)) or
                    (songdata.nm_tracks = 10) then
                   begin
                     channel_flag[10] := NOT channel_flag[10];
                     If NOT channel_flag[10] then reset_chan_data(10);
                     fkey := WORD_NULL;
                   end;
    end;
{$IFDEF GO32V2}
    realtime_gfx_poll_proc;
    keyboard_reset_buffer_alt;
{$ELSE}
    draw_screen;
{$ENDIF}
  until (NOT _ctrl_alt_flag and ((fkey = kESC) or (fkey = kF1) or (fkey = kAlt0))) or
        (_ctrl_alt_flag and NOT (ctrl_pressed and alt_pressed)) or
        _force_program_quit;

  If NOT _ctrl_alt_flag then keyboard_reset_buffer;
  If NOT ((fkey = kF1) or (fkey = kAlt0)) and _reset_state then
    begin
      debugging := old_debugging;
      play_status := old_play_status;
      replay_forbidden := old_replay_forbidden;
    end;

  If NOT _ctrl_alt_flag then
    add_bank_position('?debug_info?details_flag',-1,ORD(_details_flag)+ORD(_macro_details_flag));

  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+83+2;
  move_to_screen_area[4] := ystart+songdata.nm_tracks+6+1;
  move2screen;

  If (fkey = kF1) then
    begin
      realtime_gfx_poll_proc;
      no_step_debugging := TRUE;
      HELP('debug_info');
      draw_screen;
      keyboard_reset_buffer;
      no_step_debugging := FALSE;
      IF NOT _force_program_quit then GOTO _jmp1;
    end;

  If (fkey = kAlt0) then
{$IFNDEF GO32V2}
    If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
{$ENDIF}
      begin
        realtime_gfx_poll_proc;
        no_step_debugging := TRUE;
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

        draw_screen;
        keyboard_reset_buffer;
        no_step_debugging := FALSE;
        If NOT _force_program_quit then GOTO _jmp1;
      end;
end;

procedure _show_bpm_callback_LMS;
begin
  ShowC3Str(screen_ptr,dl_environment.xpos+2,dl_environment.ypos+dl_environment.ysize,
            ExpC2StrL(' ~ '+Bpm2str(calc_bpm_speed(songdata.tempo,songdata.speed,dl_environment.cur_item))+' ~`BPM `',
                      dl_environment.xsize-2,#205)+' ',
            dialog_background+dialog_border,
            dialog_def_bckg+dialog_input,
            dialog_def_bckg+dialog_input);
end;

procedure LINE_MARKING_SETUP;

var
  old_bpm_proc: procedure;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:LINE_MARKING_SETUP';
{$ENDIF}
  old_bpm_proc := _show_bpm_realtime_proc;
  _show_bpm_realtime_proc := _show_bpm_callback_LMS;
  dl_setting.all_enabled := TRUE;
  mark_line := Dialog('USE CURSOR KEYS OR DiRECTLY PRESS ~HOTKEY~ TO SETUP COUNTER$',
                      '~1~$~2~$~3~$~4~$~5~$~6~$~7~$~8~$~9~$10$11$12$13$14$15$16$',
                      ' LiNE MARKiNG SETUP (ROWS PER BEAT) ',mark_line);
  dl_setting.all_enabled := FALSE;
  _IRQFREQ_update_event := FALSE;
  _show_bpm_realtime_proc := old_bpm_proc;
end;

procedure OCTAVE_CONTROL;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:OCTAVE_CONTROL';
{$ENDIF}
  current_octave := Dialog('USE CURSOR KEYS OR DiRECTLY PRESS HOTKEY '+
                           'TO CHANGE OCTAVE$',
                           '~1~$~2~$~3~$~4~$~5~$~6~$~7~$~8~$',
                           ' OCTAVE CONTROL ',current_octave);
end;

var
  _bpm_xstart: Byte;
  _bpm_ystart: Byte;

const
  _song_variables_pos: Byte = 1;

var
  bpm_str,
  bpm_inc_str,bpm_dec_str: String;
  is_num: Byte;

procedure _show_bpm_callback_SV;
begin
  Case _song_variables_pos of
    3: begin
         is_num := Str2num(is_environment.cur_str,10);
         If is_num in [1..255] then
           bpm_str := ExpStrL(Bpm2str(calc_bpm_speed(is_num,songdata.speed,mark_line))+' BPM',9,' ')
         else bpm_str := ExpStrL(Bpm2str(calc_bpm_speed(songdata.tempo,songdata.speed,mark_line))+' BPM',9,' ');
       end;
    4: begin
         is_num := Str2num(is_environment.cur_str,16);
         If is_num in [1..255] then
           bpm_str := ExpStrL(Bpm2str(calc_bpm_speed(songdata.tempo,is_num,mark_line))+' BPM',9,' ')
         else bpm_str := ExpStrL(Bpm2str(calc_bpm_speed(songdata.tempo,songdata.speed,mark_line))+' BPM',9,' ');
       end
    else
      bpm_str := ExpStrL(Bpm2str(calc_bpm_speed(songdata.tempo,songdata.speed,mark_line))+' BPM',9,' ');
  end;
  ShowStr(screen_ptr,_bpm_xstart,_bpm_ystart,
          bpm_str,
          dialog_background+dialog_misc_indic);
end;

procedure _show_current_bpm_with_hints;
begin
  Case _song_variables_pos of
    3: begin
         is_num := Str2num(is_environment.cur_str,10);
         If (is_num in [1..254]) then
           bpm_inc_str := '`(`~+~`)` '+ExpStrL(Bpm2str(calc_bpm_speed(is_num+1,songdata.speed,mark_line))+' `BPM`',11,' ')
         else bpm_inc_str := ExpStrL('',13,' ');
         If (is_num in [2..255]) then
           bpm_dec_str := '`(`~-~`)` '+ExpStrL(Bpm2str(calc_bpm_speed(is_num-1,songdata.speed,mark_line))+' `BPM`',11,' ')
         else bpm_dec_str := ExpStrL('',13,' ');
       end;
    4: begin
         is_num := Str2num(is_environment.cur_str,16);
         If (is_num in [1..254]) then
           bpm_inc_str := '`(`~+~`)` '+ExpStrL(Bpm2str(calc_bpm_speed(songdata.tempo,is_num+1,mark_line))+' `BPM`',11,' ')
         else bpm_inc_str := ExpStrL('',13,' ');
         If (is_num in [2..255]) then
           bpm_dec_str := '`(`~-~`)` '+ExpStrL(Bpm2str(calc_bpm_speed(songdata.tempo,is_num-1,mark_line))+' `BPM`',11,' ')
         else bpm_dec_str := ExpStrL('',13,' ');
       end;
  end;

  ShowC3Str(screen_ptr,_bpm_xstart-4,_bpm_ystart+1,
            bpm_inc_str,
            dialog_background+dialog_context_dis,
            dialog_background+dialog_title,
            dialog_background+dialog_contxt_dis2);

  If (CutStr(bpm_inc_str) <> '') then
    ShowC3Str(screen_ptr,_bpm_xstart-4,_bpm_ystart+2,
              bpm_dec_str,
              dialog_background+dialog_context_dis,
              dialog_background+dialog_title,
              dialog_background+dialog_contxt_dis2)
  else
    begin
      ShowC3Str(screen_ptr,_bpm_xstart-4,_bpm_ystart+1,
               bpm_dec_str,
               dialog_background+dialog_context_dis,
               dialog_background+dialog_title,
               dialog_background+dialog_contxt_dis2);
      ShowC3Str(screen_ptr,_bpm_xstart-4,_bpm_ystart+2,
               bpm_inc_str,
               dialog_background+dialog_context_dis,
               dialog_background+dialog_title,
               dialog_background+dialog_contxt_dis2);
    end;
end;

procedure SONG_VARIABLES;

const
  new_keys: array[1..29] of Word = (kF1,kESC,kENTER,kTAB,kShTAB,kUP,kDOWN,kCtENTR,
                                    kAltN,kAltE,kAltT,kAltS,kAltR,kAltD,kAltO,kAltI,
                                    kAltA,kAltL,kAltB,kAltH,kAltF,kAltX,kAltU,kAltK,
                                    kAltG,kAltM,kAltC,kAltV,kAltP);
var
  old_keys: array[1..7] of Word;
  pos,pos_4op,temp,temp1,temp2,temp3: Byte;
  temps: String;
  xstart,ystart: Byte;
  attr: array[1..163] of Word;
  status_backup: Record
                   replay_forbidden: Boolean;
                   play_status: tPLAY_STATUS;
                 end;
const
  RANGE_PAN_LO = 18;
  RANGE_PAN_HI = 77;
  RANGE_PAN: Set of Byte = [RANGE_PAN_LO..RANGE_PAN_HI];

  RANGE_4OP_LO = 78;
  RANGE_4OP_HI = 83;
  RANGE_4OP: Set of Byte = [RANGE_4OP_LO..RANGE_4OP_HI];

  RANGE_LCK_LO = 84;
  RANGE_LCK_HI = 163;
  RANGE_LCK: Set of Byte = [RANGE_LCK_LO..RANGE_LCK_HI];

  _on_off: array[0..1] of Char = #250#251;
  _4op_str: array[1..6] of String = ('1 '#241'2   ','3 '#241'4   ','5 '#241'6   ',
                                     '10'#241'11  ','12'#241'13  ','14'#241'15  ');
  _pan_pos: array[0..2] of Byte = (1,0,2);
  _left_pos_pan: array[1..60] of Byte = (2,  18,19,  {1}
                                         87, 21,22,  {2}
                                         91, 24,25,  {3}
                                         3,  27,28,  {4}
                                         5,  30,31,  {5}
                                         17, 33,34,  {6}
                                         107,36,37,  {7}
                                         78, 39,40,  {8}
                                         79, 42,43,  {9}
                                         80, 45,46,  {10}
                                         81, 48,49,  {11}
                                         82, 51,52,  {12}
                                         83, 54,55,  {13}
                                         12, 57,58,  {14}
                                         139,60,61,  {15}
                                         13, 63,64,  {16}
                                         14, 66,67,  {17}
                                         151,69,70,  {18}
                                         15, 72,73,  {19}
                                         16, 75,76); {20}

  _left_pos_lck: array[1..80] of Byte = (20,84, 85, 86,   {1}
                                         23,88, 89, 90,   {2}
                                         26,92, 93, 94,   {3}
                                         29,96, 97, 98,   {4}
                                         32,100,101,102,  {5}
                                         35,104,105,106,  {6}
                                         38,108,109,110,  {7}
                                         41,112,113,114,  {8}
                                         44,116,117,118,  {9}
                                         47,120,121,122,  {10}
                                         50,124,125,126,  {11}
                                         53,128,129,130,  {12}
                                         56,132,133,134,  {13}
                                         59,136,137,138,  {14}
                                         62,140,141,142,  {15}
                                         65,144,145,146,  {16}
                                         68,148,149,150,  {17}
                                         71,152,153,154,  {18}
                                         74,156,157,158,  {19}
                                         77,160,161,162); {20}

  _right_pos_pan: array[1..60] of Byte = (19,20,84,   {1}
                                          22,23,88,   {2}
                                          25,26,92,   {3}
                                          28,29,96,   {4}
                                          31,32,100,  {5}
                                          34,35,104,  {6}
                                          37,38,108,  {7}
                                          40,41,112,  {8}
                                          43,44,116,  {9}
                                          46,47,120,  {10}
                                          49,50,124,  {11}
                                          52,53,128,  {12}
                                          55,56,132,  {13}
                                          58,59,136,  {14}
                                          61,62,140,  {15}
                                          64,65,144,  {16}
                                          67,68,148,  {17}
                                          70,71,152,  {18}
                                          73,74,156,  {19}
                                          76,77,160); {20}

  _right_pos_lck: array[1..80] of Byte = (85, 86, 87, 0,  {1}
                                          89, 90, 91, 0,  {2}
                                          93, 94, 95, 0,  {3}
                                          97, 98, 99, 0,  {4}
                                          101,102,103,0,  {5}
                                          105,106,107,0,  {6}
                                          109,110,111,0,  {7}
                                          113,114,115,0,  {8}
                                          117,118,119,0,  {9}
                                          121,122,123,0,  {10}
                                          125,126,127,0,  {11}
                                          129,130,131,0,  {12}
                                          133,134,135,0,  {13}
                                          137,138,139,0,  {14}
                                          141,142,143,0,  {15}
                                          145,146,147,0,  {16}
                                          149,150,151,0,  {17}
                                          153,154,155,0,  {18}
                                          157,158,159,0,  {19}
                                          161,162,163,1); {20}

  _right_pos_lck_def: array[1..20-1] of Record
                                          variant1,
                                          variant2: Byte;
                                        end = (
    (variant1: 21; variant2: 3),   {1}
    (variant1: 24; variant2: 3),   {2}
    (variant1: 3;  variant2: 3),   {3}
    (variant1: 4;  variant2: 4),   {4}
    (variant1: 17; variant2: 17),  {5}
    (variant1: 36; variant2: 6),   {6}
    (variant1: 6;  variant2: 6),   {7}
    (variant1: 7;  variant2: 7),   {8}
    (variant1: 8;  variant2: 8),   {9}
    (variant1: 81; variant2: 81),  {10}
    (variant1: 82; variant2: 82),  {11}
    (variant1: 9;  variant2: 9),   {12}
    (variant1: 10; variant2: 10),  {13}
    (variant1: 60; variant2: 13),  {14}
    (variant1: 13; variant2: 13),  {15}
    (variant1: 14; variant2: 14),  {16}
    (variant1: 69; variant2: 15),  {17}
    (variant1: 15; variant2: 15),  {18}
    (variant1: 16; variant2: 16)); {19}

  _left_pos_4op: array[1..6] of Byte = (6,7,8,0,0,11);
  _right_pos_4op: array[1..6] of Byte = (0,0,0,0,0,0);
  _up_pos_4op: array[1..6] of Byte = (0,78,79,80,81,82);
  _down_pos_4op: array[1..6] of Byte = (79,80,81,82,83,10);
  _right_pos_4op_def: array[1..6] of Record
                                       variant1,
                                       variant2: Byte;
                                     end = (
    (variant1: 39; variant2: 7),
    (variant1: 42; variant2: 8),
    (variant1: 45; variant2: 81),
    (variant1: 48; variant2: 82),
    (variant1: 51; variant2: 9),
    (variant1: 54; variant2: 10));


  _old_pos_pan: Byte = RANGE_PAN_LO+1;
  _old_pos_4op: Byte = RANGE_4OP_LO;
  _old_pos_lck: Byte = RANGE_LCK_LO;

var
  old_bpm_proc: procedure;

function truncate_string(str: String): String;
begin
  While (Length(str) > 0) and (str[Length(str)] in [#0,#32,#255]) do
    Delete(str,Length(str),1);
  truncate_string := str;
end;

procedure _check_key_shortcuts;
begin
  If (pos in RANGE_PAN) then
    begin
      _old_pos_pan := RANGE_PAN_LO+1+(pos-RANGE_PAN_LO) DIV 3*3;
      _old_pos_lck := RANGE_LCK_LO+(pos-RANGE_PAN_LO) DIV 3*4;
    end
  else If (pos in RANGE_4OP) then
         _old_pos_4op := pos
       else If (pos in RANGE_LCK) then
              begin
                _old_pos_pan := RANGE_PAN_LO+1+(pos-RANGE_LCK_LO) DIV 4*3;
                _old_pos_lck := RANGE_LCK_LO+(pos MOD 4)+(pos-RANGE_LCK_LO) DIV 4*4;
              end;
  Case is_environment.keystroke of
    kAltN: pos := 1;
    kAltE: pos := 2;
    kAltT: pos := 3;
    kAltS: pos := 4;
    kAltR: pos := 5;
    kAltD: pos := 17;
    kAltO: pos := 6;
    kAltI: pos := 7;
    kAltA: pos := 8;
    kAltL: If (tremolo_depth = 0) then pos := 9 else pos := 10;
    kAltB: If (vibrato_depth = 0) then pos := 11 else pos := 12;
    kAltH: pos := 13;
    kAltF: pos := 14;
    kAltX: pos := 15;
    kAltU: pos := 16;
    kAltK: begin
             If (_old_pos_4op in RANGE_4OP) then pos := _old_pos_4op
             else pos := RANGE_4OP_LO;
             pos_4op := 0;
           end;
    kAltG: If (_old_pos_pan in RANGE_PAN) then pos := _old_pos_pan
           else pos := RANGE_PAN_LO+1;
    kAltM: If (_old_pos_lck in RANGE_LCK) then pos := RANGE_LCK_LO+((_old_pos_lck-RANGE_LCK_LO) DIV 4)*4
           else pos := RANGE_LCK_LO;
    kAltC: If (_old_pos_lck in RANGE_LCK) then pos := RANGE_LCK_LO+1+((_old_pos_lck-RANGE_LCK_LO) DIV 4)*4
           else pos := RANGE_LCK_LO+1;
    kAltV: If (_old_pos_lck in RANGE_LCK) then pos := RANGE_LCK_LO+2+((_old_pos_lck-RANGE_LCK_LO) DIV 4)*4
           else pos := RANGE_LCK_LO+2;
    kAltP: If (_old_pos_lck in RANGE_LCK) then pos := RANGE_LCK_LO+3+((_old_pos_lck-RANGE_LCK_LO) DIV 4)*4
           else pos := RANGE_LCK_LO+3;
  end;
end;

label _jmp1,_end;

begin { SONG_VARIABLES }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:SONG_VARIABLES';
{$ENDIF}
  songdata_crc := Update32(songdata,SizeOf(songdata),0);
  count_order(temp1);
  count_patterns(temp2);
  count_instruments(temp3);
  pos := min(get_bank_position('?song_variables_window?pos',-1),1);
  pos_4op := min(get_bank_position('?song_variables_window?pos_4op',-1),0);
  If (calc_max_speedup(songdata.tempo) < songdata.macro_speedup) then
    begin
      songdata.macro_speedup := calc_max_speedup(songdata.tempo);
      If (play_status = isStopped) then
        macro_speedup := songdata.macro_speedup;
    end;

_jmp1:
  If _force_program_quit then EXIT;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  HideCursor;

  ScreenMemCopy(screen_ptr,ptr_temp_screen);
  centered_frame_vdest := ptr_temp_screen;
  centered_frame(xstart,ystart,79,26,' SONG VARiABLES ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);
  centered_frame_vdest := screen_ptr;

  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+79+2;
  move_to_screen_area[4] := ystart+26+1;
  move2screen_alt;

  move_to_screen_area[1] := xstart+1;
  move_to_screen_area[2] := ystart+1;
  move_to_screen_area[3] := xstart+78;
  move_to_screen_area[4] := ystart+25;

  _bpm_xstart := xstart+39;
  _bpm_ystart := ystart+7;

  old_bpm_proc := _show_bpm_realtime_proc;
  _show_bpm_realtime_proc := _show_bpm_callback_SV;

  ShowCStr(ptr_temp_screen,xstart+2,ystart+6,
           'iNSTRUMENTS: ~'+Num2str(temp3,10)+'/255~  ',
           dialog_background+dialog_text,
           dialog_background+dialog_context_dis);

  ShowCStr(ptr_temp_screen,xstart+25,ystart+6,
           'PATTERNS: ~'+Num2str(temp2,10)+'/'+Num2str(max_patterns,10)+'~  ',
           dialog_background+dialog_text,
           dialog_background+dialog_context_dis);

  ShowCStr(ptr_temp_screen,xstart+2,ystart+7,
           'ORDER LiST ENTRiES: ~'+Num2str(temp1,10)+'/128~  ',
           dialog_background+dialog_text,
           dialog_background+dialog_context_dis);

  ShowStr(ptr_temp_screen,xstart+51,ystart+2,
          'iNiTiAL LOCK SETTiNGS',
          dialog_background+dialog_context_dis);
  ShowStr(ptr_temp_screen,xstart+51,ystart+3,
          ExpStrL('',27,#154),
          dialog_background+dialog_context_dis);

  Move(is_setting.terminate_keys,old_keys,SizeOf(old_keys));
  Move(new_keys,is_setting.terminate_keys,SizeOf(new_keys));

  songdata.songname := truncate_string(songdata.songname);
  songdata.composer := truncate_string(songdata.composer);

  If NOT _force_program_quit then
    Repeat
      If (songdata.nm_tracks < 11) then _left_pos_4op[4] := 80
      else _left_pos_4op[4] := 123;

      If (songdata.nm_tracks < 12) then _left_pos_4op[5] := 81
      else _left_pos_4op[5] := 127;

      For temp := 1 to 6 do
        If (songdata.nm_tracks < 8+temp-1) then
          _right_pos_4op[temp] := _right_pos_4op_def[temp].variant2
        else _right_pos_4op[temp] := _right_pos_4op_def[temp].variant1;

      If (songdata.nm_tracks < 7) then _up_pos_4op[1] := 17
      else _up_pos_4op[1] := 36;

      For temp := 1 to 19 do
        If (songdata.nm_tracks < temp+1) then
          _right_pos_lck[(temp-1)*4+4] := _right_pos_lck_def[temp].variant2
        else _right_pos_lck[(temp-1)*4+4] := _right_pos_lck_def[temp].variant1;

      For temp2 := 1 to 18 do
        If (pos = temp2) then
          attr[temp2] := dialog_hi_text+(dialog_hi_text SHL 8)
        else attr[temp2] := dialog_text+(dialog_title SHL 8);

      If (pos = 4) then attr[5] := 0
      else If (pos = 5) then attr[4] := 0
           else attr[5] := 0;

      If (pos = 9) then attr[10] := 0
      else If (pos = 10) then attr[9] := 0
           else attr[10] := 0;

      If (pos = 11) then attr[12] := 0
      else If (pos = 12) then attr[11] := 0
           else attr[11] := 0;

      If (pos in RANGE_PAN) then attr[RANGE_PAN_LO] := dialog_hi_text+(dialog_hi_text SHL 8)
      else attr[RANGE_PAN_LO] := dialog_text+(dialog_title SHL 8);

      If (pos in RANGE_4OP) then attr[RANGE_4OP_LO] := dialog_hi_text+(dialog_hi_text SHL 8)
      else attr[RANGE_4OP_LO] := dialog_text+(dialog_title SHL 8);

      If (pos in RANGE_LCK) and (pos MOD 4 = 0) then
        attr[RANGE_LCK_LO] := dialog_hi_text+(dialog_hi_text SHL 8)
      else attr[RANGE_LCK_LO] := dialog_text+(dialog_title SHL 8);

      If (pos in RANGE_LCK) and (pos MOD 4 = 1) then
        attr[RANGE_LCK_LO+1] := dialog_hi_text+(dialog_hi_text SHL 8)
      else attr[RANGE_LCK_LO+1] := dialog_text+(dialog_title SHL 8);

      If (pos in RANGE_LCK) and (pos MOD 4 = 2) then
        attr[RANGE_LCK_LO+2] := dialog_hi_text+(dialog_hi_text SHL 8)
      else attr[RANGE_LCK_LO+2] := dialog_text+(dialog_title SHL 8);

      If (pos in RANGE_LCK) and (pos MOD 4 = 3) then
        attr[RANGE_LCK_LO+3] := dialog_hi_text+(dialog_hi_text SHL 8)
      else attr[RANGE_LCK_LO+3] := dialog_text+(dialog_title SHL 8);

      ShowCStr(ptr_temp_screen,xstart+34,ystart+12,
               #4#3' TRAC~K~S  '#4#3'+',
               dialog_background+LO(attr[RANGE_4OP_LO]),
               dialog_background+HI(attr[RANGE_4OP_LO]));

      For temp := 1 to 6 do
        If (songdata.flag_4op OR (1 SHL PRED(temp)) = songdata.flag_4op) then
          ShowC3Str(ptr_temp_screen,xstart+34,ystart+13+temp-1,
                   '[~'#251'~] '+_4op_str[temp]+'`[ ]`',
                   dialog_background+dialog_text,
                   dialog_background+dialog_item,
                   dialog_background+dialog_text)
        else
          ShowC3Str(ptr_temp_screen,xstart+34,ystart+13+temp-1,
                   '[~ ~] '+_4op_str[temp]+'`[ ]`',
                   dialog_background+dialog_text,
                   dialog_background+dialog_item,
                   dialog_background+dialog_item_dis);

      ShowCStr(ptr_temp_screen,xstart+51,ystart+4,
               'PANNiN~G~',
                dialog_background+LO(attr[RANGE_PAN_LO]),
                dialog_background+HI(attr[RANGE_PAN_LO]));
      ShowStr(ptr_temp_screen,xstart+51,ystart+5,
              #170'  c  '#171,
              dialog_background+LO(attr[18]));

      ShowVCStr(ptr_temp_screen,xstart+64,ystart+4,
                '~M~'#31,
                dialog_background+LO(attr[RANGE_LCK_LO]),
                dialog_background+HI(attr[RANGE_LCK_LO]));
      ShowVStr(ptr_temp_screen,xstart+65,ystart+4,
               #10,
               dialog_background+LO(attr[RANGE_LCK_LO]));

      ShowVCStr(ptr_temp_screen,xstart+68,ystart+4,
                '~C~'#31,
                dialog_background+LO(attr[RANGE_LCK_LO+1]),
                dialog_background+HI(attr[RANGE_LCK_LO+1]));
      ShowVStr(ptr_temp_screen,xstart+69,ystart+4,
               #10,
               dialog_background+LO(attr[RANGE_LCK_LO+1]));

      ShowVCStr(ptr_temp_screen,xstart+72,ystart+4,
                '~V~'#31,
                dialog_background+LO(attr[RANGE_LCK_LO+2]),
                dialog_background+HI(attr[RANGE_LCK_LO+2]));
      ShowVStr(ptr_temp_screen,xstart+73,ystart+4,
               '+',
               dialog_background+LO(attr[RANGE_LCK_LO+2]));

      ShowVCStr(ptr_temp_screen,xstart+76,ystart+4,
                '~P~'#31,
                dialog_background+LO(attr[RANGE_LCK_LO+3]),
                dialog_background+HI(attr[RANGE_LCK_LO+3]));
      ShowVStr(ptr_temp_screen,xstart+77,ystart+4,
               '+',
               dialog_background+LO(attr[RANGE_LCK_LO+3]));

      temps := '';
      For temp := 1 to 6 do
        If (songdata.lock_flags[_4op_main_chan[temp]] OR $40 = songdata.lock_flags[_4op_main_chan[temp]]) or
           (songdata.lock_flags[PRED(_4op_main_chan[temp])] OR $40 = songdata.lock_flags[PRED(_4op_main_chan[temp])]) then
          temps := temps+#251
        else temps := temps+' ';

      ShowVStr(ptr_temp_screen,xstart+46,ystart+13,
               temps,
               dialog_background++dialog_item);

      For temp := 1 to 20 do
        If (temp <= songdata.nm_tracks) then
          begin
            ShowCStr(ptr_temp_screen,xstart+51,ystart+6+temp-1,
                     voice_pan_str[songdata.lock_flags[temp] AND 3],
                     dialog_background+dialog_text,
                     dialog_background+dialog_item);
            ShowCStr(ptr_temp_screen,xstart+60,ystart+6+temp-1,
                     '~'+ExpStrL(Num2str(temp,10),2,' ')+'~  '+
                     _on_off[songdata.lock_flags[temp] SHR 3 AND 1]+' ~'#246'~ '+
                     _on_off[songdata.lock_flags[temp] SHR 2 AND 1]+' ~'#246'~ '+
                     _on_off[songdata.lock_flags[temp] SHR 4 AND 1]+' ~'#246'~ '+
                     _on_off[songdata.lock_flags[temp] SHR 5 AND 1],
                     dialog_background+dialog_item,
                     dialog_background+dialog_context_dis);
          end
        else ShowStr(ptr_temp_screen,xstart+51,ystart+6+temp-1,
                     voice_pan_str[3]+'  '+ExpStrL(Num2str(temp,10),2,' ')+
                     '  '#250' '#246' '#250' '#246' '#250' '#246' '#250,
                     dialog_background+dialog_hid);

      temps := '';
      For temp := 1 to songdata.nm_tracks do
        If percussion_mode and (temp in [16..20]) then temps := temps+_perc_char[temp-15]
        else Case temp of
               1:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then temps := temps+#172
                   else temps := temps+' ';
               2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then temps := temps+#173
                   else temps := temps+' ';
               3:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then temps := temps+#172
                   else temps := temps+' ';
               4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then temps := temps+#173
                   else temps := temps+' ';
               5:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then temps := temps+#172
                   else temps := temps+' ';
               6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then temps := temps+#173
                   else temps := temps+' ';
               10: If (songdata.flag_4op OR 8 = songdata.flag_4op) then temps := temps+#172
                   else temps := temps+' ';
               11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then temps := temps+#173
                   else temps := temps+' ';
               12: If (songdata.flag_4op OR $10 = songdata.flag_4op) then temps := temps+#172
                   else temps := temps+' ';
               13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then temps := temps+#173
                   else temps := temps+' ';
               14: If (songdata.flag_4op OR $20 = songdata.flag_4op) then temps := temps+#172
                   else temps := temps+' ';
               15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then temps := temps+#173
                   else temps := temps+' ';
               else temps := temps+' ';
             end;

      ShowVStr(ptr_temp_screen,xstart+50,ystart+6,
               ExpStrR(temps,20,' '),
               dialog_background+dialog_misc_indic);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+1,
               'SONG~N~AME',
               dialog_background+LO(attr[1]),
               dialog_background+HI(attr[1]));

      ShowCStr(ptr_temp_screen,xstart+2,ystart+3,
               'COMPOS~E~R',
               dialog_background+LO(attr[2]),
               dialog_background+HI(attr[2]));

      ShowCStr(ptr_temp_screen,xstart+2,ystart+9,
               'SONG ~T~EMPO',
               dialog_background+LO(attr[3]),
               dialog_background+HI(attr[3]));

      ShowCStr(ptr_temp_screen,xstart+2,ystart+10,
               'SONG ~S~PEED',
               dialog_background+LO(attr[4])+LO(attr[5]),
               dialog_background+HI(attr[4])+HI(attr[5]));

      ShowC3Str(ptr_temp_screen,xstart+26,ystart+10,
                '[ ] ~`R`ESET~',
                dialog_background+dialog_text,
                dialog_background+LO(attr[4])+LO(attr[5]),
                dialog_background+HI(attr[4])+HI(attr[5]));

      ShowC3Str(ptr_temp_screen,xstart+2,ystart+11,
                '~MACRO`D`EF.~ '#7,
                dialog_background+dialog_text,
                dialog_background+LO(attr[17]),
                dialog_background+HI(attr[17]));

      ShowCStr(ptr_temp_screen,
               xstart+31,ystart+7,
               'RHYTHM: ~'+ExpStrL(Bpm2str(calc_bpm_speed(songdata.tempo,songdata.speed,mark_line))+' BPM',9,' '),
               dialog_background+dialog_text,
               dialog_background+dialog_misc_indic);

      If speed_update then
        ShowStr(ptr_temp_screen,xstart+27,ystart+10,
                #251,
                dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+27,ystart+10,
                   ' ',
                   dialog_background+dialog_item);

      ShowC3Str(ptr_temp_screen,xstart+2,ystart+13,
                '[ ] ~TRACK VOLUME L`O`CK~',
                dialog_background+dialog_text,
                dialog_background+LO(attr[6]),
                dialog_background+HI(attr[6]));
      ShowC3Str(ptr_temp_screen,xstart+2,ystart+14,
                '[ ] ~TRACK PANN`i`NG LOCK~',
                dialog_background+dialog_text,
                dialog_background+LO(attr[7]),
                dialog_background+HI(attr[7]));
      ShowC3Str(ptr_temp_screen,xstart+2,ystart+15,
                '[ ] ~VOLUME PE`A`K LOCK~',
                dialog_background+dialog_text,
                dialog_background+LO(attr[8]),
                dialog_background+HI(attr[8]));

      If lockvol then ShowStr(ptr_temp_screen,xstart+3,ystart+13,#251,dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+13,' ',dialog_background+dialog_item);

      If panlock then ShowStr(ptr_temp_screen,xstart+3,ystart+14,#251,dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+14,' ',dialog_background+dialog_item);

      If lockVP then ShowStr(ptr_temp_screen,xstart+3,ystart+15,#251,dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+15,' ',dialog_background+dialog_item);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+17,
               'TREMO~L~O DEPTH',
               dialog_background+LO(attr[9])+LO(attr[10]),
               dialog_background+HI(attr[9])+HI(attr[10]));

      ShowStr(ptr_temp_screen,xstart+2,ystart+18,
        '( ) 1 dB',dialog_background+dialog_text);
      ShowStr(ptr_temp_screen,xstart+2,ystart+19,
        '( ) 4.8 dB',dialog_background+dialog_text);

      If (tremolo_depth = 0) then ShowVStr(ptr_temp_screen,xstart+3,ystart+18,#11' ',dialog_background+dialog_item)
      else ShowVStr(ptr_temp_screen,xstart+3,ystart+18,' '#11,dialog_background+dialog_item);

      ShowCStr(ptr_temp_screen,xstart+18,ystart+17,
               'Vi~B~RATO DEPTH',
               dialog_background+LO(attr[11])+LO(attr[12]),
               dialog_background+HI(attr[11])+HI(attr[12]));

      ShowStr(ptr_temp_screen,xstart+18,ystart+18,
        '( ) 7%',dialog_background+dialog_text);
      ShowStr(ptr_temp_screen,xstart+18,ystart+19,
        '( ) 14%',dialog_background+dialog_text);

      If (vibrato_depth = 0) then ShowVStr(ptr_temp_screen,xstart+19,ystart+18,#11' ',dialog_background+dialog_item)
      else ShowVStr(ptr_temp_screen,xstart+19,ystart+18,' '#11,dialog_background+dialog_item);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+21,
               'PATTERN LENGT~H~',
               dialog_background+LO(attr[13]),
               dialog_background+HI(attr[13]));
      ShowCStr(ptr_temp_screen,xstart+2,ystart+22,
               'NUMBER O~F~ TRACKS',
               dialog_background+LO(attr[14]),
               dialog_background+HI(attr[14]));

      ShowC3Str(ptr_temp_screen,xstart+2,ystart+24,
                '[ ] ~PERCUSSiON TRACK E`X`TENSiON ('#160','#161','#162','#163','#164')~',
                dialog_background+dialog_text,
                dialog_background+LO(attr[15]),
                dialog_background+HI(attr[15]));

      If percussion_mode then ShowStr(ptr_temp_screen,xstart+3,ystart+24,#251,dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+24,' ',dialog_background+dialog_item);

      ShowC3Str(ptr_temp_screen,xstart+2,ystart+25,
                '[ ] ~VOL`U`ME SCALiNG~',
                dialog_background+dialog_text,
                dialog_background+LO(attr[16]),
                dialog_background+HI(attr[16]));

      If volume_scaling then
        ShowStr(ptr_temp_screen,xstart+3,ystart+25,
                #251,
                dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+25,
                   ' ',
                   dialog_background+dialog_item);

      is_setting.append_enabled := TRUE;
      is_environment.locate_pos := 1;

      ShowStr(ptr_temp_screen,xstart+2,ystart+2,
              ExpStrR(songdata.songname,46,' '),
              dialog_input_bckg+dialog_input);

      ShowStr(ptr_temp_screen,xstart+2,ystart+4,
              ExpStrR(songdata.composer,46,' '),
              dialog_input_bckg+dialog_input);

      ShowCStr(ptr_temp_screen,xstart+13,ystart+9,
               ExpStrR(Num2str(songdata.tempo,10),4,' ')+
               '~ {1..255}~',
               dialog_input_bckg+dialog_input,
               dialog_background+dialog_text);

      ShowCStr(ptr_temp_screen,xstart+13,ystart+10,
               ExpStrR(Num2str(songdata.speed,16),4,' ')+
               '~ {1..FF}~',
               dialog_input_bckg+dialog_input,
               dialog_background+dialog_text);

      ShowCStr(ptr_temp_screen,xstart+13,ystart+11,
               '~'+ExpStrR(Num2str(songdata.macro_speedup,10),4,' ')+'~'+
               ' {1..'+Num2str(calc_max_speedup(songdata.tempo),10)+'}   ',
               dialog_background+dialog_text,
               dialog_input_bckg+dialog_input);

      ShowCStr(ptr_temp_screen,xstart+19,ystart+21,
               ExpStrR(Num2str(songdata.patt_len,10),3,' ')+
               '~ {1..256}~',
               dialog_input_bckg+dialog_input,
               dialog_background+dialog_text);

      ShowCStr(ptr_temp_screen,xstart+19,ystart+22,
               ExpStrR(Num2str(songdata.nm_tracks,10),3,' ')+
               '~ {1..20}~',
               dialog_input_bckg+dialog_input,
               dialog_background+dialog_text);

      move2screen_alt;
      _song_variables_pos := pos;
      Case pos of
        1: begin
             is_setting.character_set := [#32..#255];
             temps := InputStr(songdata.songname,xstart+2,ystart+2,
                               42,42,
                               dialog_input_bckg+dialog_input,
                               dialog_def_bckg+dialog_def);
             songdata.songname := truncate_string(temps);
             _check_key_shortcuts;
             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 2
             else If (is_environment.keystroke = kUP) then pos := 16
                  else If (is_environment.keystroke = kShTAB) then
                         If (_old_pos_lck in RANGE_LCK) then pos := RANGE_LCK_LO+3+((_old_pos_lck-RANGE_LCK_LO) DIV 4)*4
                         else pos := RANGE_LCK_LO+3;
           end;

        2: begin
             is_setting.character_set := [#32..#255];
             temps := InputStr(songdata.composer,xstart+2,ystart+4,
                               42,42,
                               dialog_input_bckg+dialog_input,
                               dialog_def_bckg+dialog_def);
             songdata.composer := truncate_string(temps);
             _check_key_shortcuts;
             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 3
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 1;
           end;

        3: begin
             is_setting.character_set := DEC_NUM_CHARSET;
             is_environment.ext_proc := _show_current_bpm_with_hints;
             is_environment.min_num := 1;
             is_environment.max_num := 255;

             Repeat
               temps := InputStr(Num2str(songdata.tempo,10),
                                 xstart+13,ystart+9,3,3,
                                 dialog_input_bckg+dialog_input,
                                 dialog_def_bckg+dialog_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,10) > 0) and (Str2num(temps,10) < 256));

             is_environment.ext_proc := NIL;
             If ((Str2num(temps,10) > 0) and (Str2num(temps,10) < 256)) then
               begin
                 songdata.tempo := Str2num(temps,10);
                 If (play_status = isStopped) then
                   tempo := songdata.tempo;
               end;

             If (calc_max_speedup(songdata.tempo) < songdata.macro_speedup) then
               songdata.macro_speedup := calc_max_speedup(songdata.tempo);

             _check_key_shortcuts;
             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 4
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 2;
           end;

        4: begin
             is_setting.character_set := HEX_NUM_CHARSET;
             is_environment.ext_proc := _show_current_bpm_with_hints;
             is_environment.min_num := 1;
             is_environment.max_num := 255;

             Repeat
               temps := InputStr(Num2str(songdata.speed,16),
                                 xstart+13,ystart+10,2,2,
                                 dialog_input_bckg+dialog_input,
                                 dialog_def_bckg+dialog_def);
             until (is_environment.keystroke = kESC) or
                   (Str2num(temps,16) in [1..255]);

             is_environment.ext_proc := NIL;
             If (Str2num(temps,16) in [1..255]) then
               begin
                 songdata.speed := Str2num(temps,16);
                 If (play_status = isStopped) then
                   speed := songdata.speed;
               end;

             _check_key_shortcuts;
             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) then pos := 5
             else If (is_environment.keystroke = kDOWN) then pos := 17
                  else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 3;
           end;

        5: begin
             GotoXY(xstart+27,ystart+10);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kUP: pos := 3;
               kLEFT,kShTAB: pos := 4;
               kDOWN,kTAB,kENTER: pos := 17;
               kRIGHT: If (songdata.nm_tracks < 5) then pos := 17 else pos := 30;
               kSPACE: speed_update := NOT speed_update;
             end;
           end;

       17: begin
             is_setting.character_set := DEC_NUM_CHARSET;
             is_environment.min_num := 1;
             is_environment.max_num := calc_max_speedup(songdata.tempo);
             Repeat
               temps := InputStr(Num2str(songdata.macro_speedup,10),
                                 xstart+13,ystart+11,4,4,
                                 dialog_input_bckg+dialog_input,
                                 dialog_def_bckg+dialog_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,10) >= 1) and
                    (Str2num(temps,10) <= calc_max_speedup(songdata.tempo)));

             If ((Str2num(temps,10) >= 1) and
                 (Str2num(temps,10) <= calc_max_speedup(songdata.tempo))) then
               songdata.macro_speedup := Str2num(temps,10);

             _check_key_shortcuts;
             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 6
             else If (is_environment.keystroke = kUP) then pos := 4
                  else If (is_environment.keystroke = kShTAB) then pos := 5;
           end;

        6: begin
             GotoXY(xstart+3,ystart+13);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kLEFT: If (songdata.nm_tracks < 7) then pos := 17 else pos := 111;
               kUP,kShTAB: pos := 17;
               kDOWN,kTAB,kENTER: pos := 7;
               kRIGHT: pos := _old_pos_4op;
               kSPACE: lockvol := NOT lockvol;
             end;
           end;

        7: begin
             GotoXY(xstart+3,ystart+14);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kUP,kShTAB: pos := 6;
               kLEFT: If (songdata.nm_tracks < 8) then pos := 78 else pos := 115;
               kTAB,kENTER: pos := 8;
               kDOWN: pos := 8;
               kRIGHT: pos := 79;
               kSPACE: panlock := NOT panlock;
             end;
           end;

        8: begin
             GotoXY(xstart+3,ystart+15);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kUP: pos := 7;
               kLEFT: If (songdata.nm_tracks < 9) then pos := 79 else pos := 119;
               kShTAB: pos := 7;
               kDOWN: pos := 9;
               kTAB,kENTER: If (tremolo_depth = 0) then pos := 9 else pos := 10;
               kRIGHT: pos := 80;
               kSPACE: lockVP := NOT lockVP;
             end;
           end;

        9: begin
             GotoXY(xstart+3,ystart+18);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kUP: pos := 8;
               kLEFT: If (songdata.nm_tracks < 12) then pos := 82 else pos := 131;
               kShTAB: pos := 8;
               kRIGHT,kTAB,kENTER: If (vibrato_depth = 0) then pos := 11 else pos := 12;
               kDOWN: pos := 10;
               kSPACE: tremolo_depth := 0;
             end;
           end;

       10: begin
             GotoXY(xstart+3,ystart+19);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kUP: pos := 9;
               kShTAB: pos := 8;
               kDOWN: pos := 13;
               kTAB,kENTER: If (vibrato_depth = 0) then pos := 11 else pos := 12;
               kLEFT: If (songdata.nm_tracks < 13) then pos := 83 else pos := 135;
               kRIGHT: pos := 12;
               kSPACE: tremolo_depth := 1;
             end;
           end;

       11: begin
             GotoXY(xstart+19,ystart+18);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kUP: pos := 8;
               kShTAB: If (tremolo_depth = 0) then pos := 9 else pos := 10;
               kDOWN: pos := 12;
               kTAB,kENTER: pos := 13;
               kLEFT: pos := 9;
               kRIGHT: pos := 83;
               kSPACE: vibrato_depth := 0;
             end;
           end;

       12: begin
             GotoXY(xstart+19,ystart+19);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kUP: pos := 11;
               kShTAB: pos := 9;
               kDOWN,kTAB,kENTER: pos := 13;
               kLEFT: pos := 10;
               kRIGHT: If (songdata.nm_tracks < 14) then pos := 13 else pos := 57;
               kSPACE: vibrato_depth := 1;
             end;
           end;

       13: begin
             is_setting.character_set := DEC_NUM_CHARSET;
             is_environment.min_num := 1;
             is_environment.max_num := 256;
             Repeat
               temps := InputStr(Num2str(songdata.patt_len,10),
                                 xstart+19,ystart+21,3,3,
                                 dialog_input_bckg+dialog_input,
                                 dialog_def_bckg+dialog_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,10) >= 1) and (Str2num(temps,10) <= 256));

             If ((Str2num(temps,10) >= 1) and (Str2num(temps,10) <= 256)) then
               begin
                 If (current_line <= Str2num(temps,10)) then
                   songdata.patt_len := Str2num(temps,10)
                 else begin
                        status_backup.replay_forbidden := replay_forbidden;
                        status_backup.play_status := play_status;
                        replay_forbidden := TRUE;
                        If (play_status <> isStopped) then play_status := isPaused;

                        pattern_break := TRUE;
                        next_line := 0;
                        ticks := tick0;
                        update_song_position;
                        songdata.patt_len := Str2num(temps,10);

                        replay_forbidden := status_backup.replay_forbidden;
                        play_status := status_backup.play_status;
                      end;

                 force_scrollbars := TRUE;
                 PATTERN_ORDER_page_refresh(pattord_page);
                 PATTERN_page_refresh(pattern_page);
                 force_scrollbars := FALSE;
               end;

             _check_key_shortcuts;
             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 14
             else If (is_environment.keystroke = kUP) then pos := 12
                  else If (is_environment.keystroke = kShTAB) then
                         If (vibrato_depth = 0) then pos := 11 else pos := 12;
           end;

       14: begin
             is_setting.character_set := DEC_NUM_CHARSET;
             is_environment.min_num := 1;
             is_environment.max_num := 20;
             Repeat
               temps := InputStr(Num2str(songdata.nm_tracks,10),
                                 xstart+19,ystart+22,2,2,
                                 dialog_input_bckg+dialog_input,
                                 dialog_def_bckg+dialog_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,10) >= 1) and (Str2num(temps,10) <= 20));

             If (Str2num(temps,10) >= 1) and (Str2num(temps,10) <= 20) then
               begin
                 songdata.nm_tracks := Str2num(temps,10);
                 If (songdata.nm_tracks > 18) and
                    NOT percussion_mode then
                   begin
                     reset_player;
                     percussion_mode := TRUE;
                     _chan_n := _chpm_n;
                     _chan_m := _chpm_m;
                     _chan_c := _chpm_c;
                     reset_player;
                   end;

                 If (songdata.nm_tracks < 15) and
                    (songdata.flag_4op OR $20 = songdata.flag_4op) then
                   begin
                     reset_player;
                     songdata.flag_4op := songdata.flag_4op AND NOT $20;
                     reset_player;
                   end;

                 If (songdata.nm_tracks < 13) and
                    (songdata.flag_4op OR $10 = songdata.flag_4op) then
                   begin
                     reset_player;
                     songdata.flag_4op := songdata.flag_4op AND NOT $10;
                     reset_player;
                   end;

                 If (songdata.nm_tracks < 11) and
                    (songdata.flag_4op OR 8 = songdata.flag_4op) then
                   begin
                     reset_player;
                     songdata.flag_4op := songdata.flag_4op AND NOT 8;
                     reset_player;
                   end;

                 If (songdata.nm_tracks < 6) and
                    (songdata.flag_4op OR 4 = songdata.flag_4op) then
                   begin
                     reset_player;
                     songdata.flag_4op := songdata.flag_4op AND NOT 4;
                     reset_player;
                   end;

                 If (songdata.nm_tracks < 4) and
                    (songdata.flag_4op OR 2 = songdata.flag_4op) then
                   begin
                     reset_player;
                     songdata.flag_4op := songdata.flag_4op AND NOT 2;
                     reset_player;
                   end;

                 If (songdata.nm_tracks < 2) and
                    (songdata.flag_4op OR 1 = songdata.flag_4op) then
                   begin
                     reset_player;
                     songdata.flag_4op := songdata.flag_4op AND NOT 1;
                     reset_player;
                   end;

                 force_scrollbars := TRUE;
                 PATTERN_ORDER_page_refresh(pattord_page);
                 PATTERN_page_refresh(pattern_page);
                 force_scrollbars := FALSE;
               end;

             _check_key_shortcuts;
             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 15
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 13;
           end;

       15: begin
             GotoXY(xstart+3,ystart+24);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kLEFT: If (songdata.nm_tracks < 18) then pos := 14 else pos := 155;
               kRIGHT: If (songdata.nm_tracks < 19) then pos := 16 else pos := 72;
               kUP,kShTAB: pos := 14;
               kDOWN,kTAB,kENTER: pos := 16;
             end;

             If (is_environment.keystroke = kSPACE) then
               If NOT percussion_mode then
                 begin
                   reset_player;
                   songdata.nm_tracks := 20;
                   percussion_mode := TRUE;
                   _chan_n := _chpm_n;
                   _chan_m := _chpm_m;
                   _chan_c := _chpm_c;
                   reset_player;
                   If (play_status = isStopped) then init_buffers;
                 end
               else
                 begin
                   reset_player;
                   If (songdata.nm_tracks > 18) then songdata.nm_tracks := 18;
                   percussion_mode := FALSE;
                   _chan_n := _chmm_n;
                   _chan_m := _chmm_m;
                   _chan_c := _chmm_c;
                   reset_player;
                   If (play_status = isStopped) then init_buffers;
                 end;

             force_scrollbars := TRUE;
             PATTERN_ORDER_page_refresh(pattord_page);
             PATTERN_page_refresh(pattern_page);
             force_scrollbars := FALSE;
           end;

       16: begin
             GotoXY(xstart+3,ystart+25);
             ThinCursor;
             is_environment.keystroke := getkey;
             _check_key_shortcuts;
             Case is_environment.keystroke of
               kUP: pos := 15;
               kLEFT: If (songdata.nm_tracks < 19) then pos := 15 else pos := 159;
               kRIGHT: If (songdata.nm_tracks < 20) then pos := 1 else pos := 75;
               kShTAB: pos := 15;
               kDOWN: pos := 1;
               kTAB,kENTER: begin
                              pos := _old_pos_4op;
                              pos_4op := 0;
                            end;
               kSPACE: volume_scaling := NOT volume_scaling;
             end;
           end;

        RANGE_PAN_LO..RANGE_PAN_HI:
          begin
            GotoXY(xstart+51+(pos-RANGE_PAN_LO) MOD 3*3,ystart+6+(pos-RANGE_PAN_LO) DIV 3);
            ThinCursor;
            is_environment.keystroke := getkey;
            _old_pos_pan := pos;
            _check_key_shortcuts;
            Case is_environment.keystroke of
              kLEFT: pos := _left_pos_pan[pos-RANGE_PAN_LO+1];
              kRIGHT: pos := _right_pos_pan[pos-RANGE_PAN_LO+1];
              kUP: If ((pos-RANGE_PAN_LO) DIV 3 > 0) then Dec(pos,3)
                   else pos := pos+PRED(songdata.nm_tracks)*3;
              kDOWN:  If ((pos-RANGE_PAN_LO) DIV 3 < PRED(songdata.nm_tracks)) then Inc(pos,3)
                      else pos := 18+(pos-RANGE_PAN_LO) MOD 3;
              kShTAB: begin
                        pos := _old_pos_4op;
                        pos_4op := 0;
                      end;
              kTAB,kENTER: pos := RANGE_LCK_LO+(pos-RANGE_PAN_LO) DIV 3*4;
              kSPACE: begin
                        songdata.lock_flags[SUCC((pos-RANGE_PAN_LO) DIV 3)] :=
                        songdata.lock_flags[SUCC((pos-RANGE_PAN_LO) DIV 3)] AND NOT 3+
                        _pan_pos[(pos-RANGE_PAN_LO) MOD 3];
                        panlock := TRUE;
                      end;
            end;
          end;

        RANGE_4OP_LO..RANGE_4OP_HI:
          begin
            If (pos_4op <> 0) and NOT (songdata.flag_4op OR (1 SHL PRED(pos-RANGE_4OP_LO+1)) = songdata.flag_4op) then
              pos_4op := 0;
            GotoXY(xstart+35+pos_4op*11,ystart+13+pos-RANGE_4OP_LO);
            ThinCursor;
            is_environment.keystroke := getkey;
            _old_pos_4op := pos;
            _check_key_shortcuts;
            Case is_environment.keystroke of
              kLEFT: If (pos_4op <> 0) then pos_4op := 0
                     else pos := _left_pos_4op[pos-RANGE_4OP_LO+1];
              kRIGHT: If (pos_4op <> 1) and (songdata.flag_4op OR (1 SHL PRED(pos-RANGE_4OP_LO+1)) = songdata.flag_4op) then pos_4op := 1
                      else pos := _right_pos_4op[pos-RANGE_4OP_LO+1];
              kUP: If (pos > 78) then pos := _up_pos_4op[pos-RANGE_4OP_LO+1]
                   else pos := 17;
              kDOWN: pos := _down_pos_4op[pos-RANGE_4OP_LO+1];
              kShTAB: pos := 16;
              kTAB,kENTER: If (_old_pos_pan in RANGE_PAN) then pos := _old_pos_pan
                           else pos := 19;
            end;

            If (is_environment.keystroke = kSPACE) then
              Case pos_4op of
                0: If (songdata.flag_4op OR (1 SHL PRED(pos-RANGE_4OP_LO+1)) <> songdata.flag_4op) then
                     begin
                       reset_player;
                       Case (pos-RANGE_4OP_LO+1) of
                         1: songdata.nm_tracks := min(songdata.nm_tracks,2);
                         2: songdata.nm_tracks := min(songdata.nm_tracks,4);
                         3: songdata.nm_tracks := min(songdata.nm_tracks,6);
                         4: songdata.nm_tracks := min(songdata.nm_tracks,11);
                         5: songdata.nm_tracks := min(songdata.nm_tracks,13);
                         6: songdata.nm_tracks := min(songdata.nm_tracks,15);
                       end;
                       songdata.flag_4op := songdata.flag_4op OR (1 SHL PRED(pos-RANGE_4OP_LO+1));
                       reset_player;
                       If (play_status = isStopped) then init_buffers;
                     end
                   else
                     begin
                       reset_player;
                       songdata.flag_4op := songdata.flag_4op AND NOT (1 SHL PRED(pos-RANGE_4OP_LO+1));
                       reset_player;
                       If (play_status = isStopped) then init_buffers;
                     end;

                1: begin
                     songdata.lock_flags[_4op_main_chan[pos-RANGE_4OP_LO+1]] := songdata.lock_flags[_4op_main_chan[pos-RANGE_4OP_LO+1]] XOR $40;
                     songdata.lock_flags[PRED(_4op_main_chan[pos-RANGE_4OP_LO+1])] := songdata.lock_flags[PRED(_4op_main_chan[pos-RANGE_4OP_LO+1])] XOR $40;
                   end;
              end;

            force_scrollbars := TRUE;
            PATTERN_ORDER_page_refresh(pattord_page);
            PATTERN_page_refresh(pattern_page);
            force_scrollbars := FALSE;
          end;

        RANGE_LCK_LO..RANGE_LCK_HI:
          begin
            GotoXY(xstart+64+(pos-RANGE_LCK_LO) MOD 4*4,ystart+6+(pos-RANGE_LCK_LO) DIV 4);
            ThinCursor;
            is_environment.keystroke := getkey;
            _old_pos_lck := pos;
            _check_key_shortcuts;
            Case is_environment.keystroke of
              kLEFT: pos := _left_pos_lck[pos-RANGE_LCK_LO+1];
              kRIGHT: pos := _right_pos_lck[pos-RANGE_LCK_LO+1];
              kUP: If ((pos-RANGE_LCK_LO) DIV 4 > 0) then Dec(pos,4)
                   else pos := RANGE_LCK_LO+PRED(songdata.nm_tracks)*4+(pos-RANGE_LCK_LO) MOD 4;
              kDOWN:  If ((pos-RANGE_LCK_LO) DIV 4 < PRED(songdata.nm_tracks)) then Inc(pos,4)
                      else pos := RANGE_LCK_LO+(pos-RANGE_LCK_LO) MOD 4;
              kShTAB: Case (pos-RANGE_LCK_LO) MOD 4 of
                        0: pos := RANGE_PAN_LO+1+(pos-RANGE_LCK_LO) DIV 4*3;
                        else Dec(pos);
                      end;

              kTAB,
              kENTER: Case (pos-RANGE_LCK_LO) MOD 4 of
                        3: pos := 1;
                        else Inc(pos);
                      end;

              kSPACE: Case (pos-RANGE_LCK_LO) MOD 4 of
                        0: songdata.lock_flags[SUCC((pos-RANGE_LCK_LO) DIV 4)] :=
                           songdata.lock_flags[SUCC((pos-RANGE_LCK_LO) DIV 4)] XOR 8;
                        1: songdata.lock_flags[SUCC((pos-RANGE_LCK_LO) DIV 4)] :=
                           songdata.lock_flags[SUCC((pos-RANGE_LCK_LO) DIV 4)] XOR 4;

                        2: begin
                             songdata.lock_flags[SUCC((pos-RANGE_LCK_LO) DIV 4)] :=
                             songdata.lock_flags[SUCC((pos-RANGE_LCK_LO) DIV 4)] XOR $10;
                             lockvol := TRUE;
                           end;

                        3: begin
                             songdata.lock_flags[SUCC((pos-RANGE_LCK_LO) DIV 4)] :=
                             songdata.lock_flags[SUCC((pos-RANGE_LCK_LO) DIV 4)] XOR $20;
                             lockVP := TRUE;
                           end;
                      end;
            end;
          end;
      end;
_end:
{$IFDEF GO32V2}
      realtime_gfx_poll_proc;
      keyboard_reset_buffer_alt;
{$ELSE}
      draw_screen;
{$ENDIF}
    until (is_environment.keystroke = kESC) or
          (is_environment.keystroke = kF1) or
          (is_environment.keystroke = kCtENTR);

  If (nm_track_chan > songdata.nm_tracks) then
    nm_track_chan := songdata.nm_tracks;

  songdata.common_flag := BYTE(speed_update)+BYTE(lockvol) SHL 1+
                                           BYTE(lockVP)  SHL 2+
                                           tremolo_depth SHL 3+
                                           vibrato_depth SHL 4+
                                           BYTE(panlock) SHL 5+
                                           BYTE(percussion_mode) SHL 6+
                                           BYTE(volume_scaling) SHL 7;

  If (Update32(songdata,SizeOf(songdata),0) <> songdata_crc) then
    module_archived := FALSE;

  If (play_status = isStopped) then
    begin
      current_tremolo_depth := tremolo_depth;
      current_vibrato_depth := vibrato_depth;
    end;

  add_bank_position('?song_variables_window?pos',-1,pos);
  add_bank_position('?song_variables_window?pos_4op',-1,pos_4op);
  HideCursor;
  Move(old_keys,is_setting.terminate_keys,SizeOf(old_keys));
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+79+2;
  move_to_screen_area[4] := ystart+26+1;
  move2screen;

  _IRQFREQ_update_event := FALSE;
  _show_bpm_realtime_proc := old_bpm_proc;
  is_environment.min_num := 1;
  is_environment.max_num := SizeOf(DWORD);

  If (is_environment.keystroke = kF1) then
    begin
      HELP('song_variables');
      GOTO _jmp1;
    end;

  If (is_environment.keystroke = kCtENTR) then
    begin
      LINE_MARKING_SETUP;
      GOTO _jmp1;
    end;
end;

procedure NUKE;

var
  temp,temp1,temp2: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:NUKE';
{$ENDIF}
  temp1 := Dialog('SO YOU THiNK iT REALLY SUCKS, DON''T YOU?$'+
                  'WHAT DO YOU WANT TO BE NUKED?$',
                  '~O~RDER$~P~ATTERNS$iNSTR [$~N~AMES$~R~EGS$~M~ACROS$]$ARP/~V~iB$~A~LL$',
                  ' NUKE''M ',clearpos);

  clearpos := temp1;
  If (dl_environment.keystroke <> kESC) then
    begin
      If (temp1 = 1) then
        begin
          FillChar(songdata.pattern_order,SizeOf(songdata.pattern_order),$080);
          PATTERN_ORDER_page_refresh(pattord_page);
        end;

      If (temp1 = 2) then
        begin
          For temp := 1 to max_patterns DIV 8 do
            FillChar(pattdata^[PRED(temp)],8*PATTERN_SIZE,0);
          PATTERN_ORDER_page_refresh(pattord_page);
          PATTERN_page_refresh(pattern_page);
          For temp2 := 0 to $7f do
            songdata.pattern_names[temp2] :=
              ' PAT_'+byte2hex(temp2)+'  '#247' ';
          pattern_list__page := 1;
        end;

      If (temp1 = 4) then
        begin
          For temp2 := 1 to 255 do
            begin
              FillChar(songdata.instr_names[temp2][2],SizeOf(songdata.instr_names[temp2])-2,0);
              songdata.instr_names[temp2] :=
                songdata.instr_names[temp2][1]+
                'iNS_'+byte2hex(temp2)+#247' ';
            end;
        end;

      If (temp1 = 5) then
        begin
          FillChar(songdata.instr_data,SizeOf(songdata.instr_data),0);
          FillChar(songdata.ins_4op_flags,SizeOf(songdata.ins_4op_flags),0);
          update_4op_flag_marks;
        end;

      If (temp1 = 6) then
        begin
          FillChar(songdata.instr_macros,SizeOf(songdata.instr_macros),0);
          _macro_editor__pos[FALSE] := 1;
          _macro_editor__fmreg_hpos[FALSE] := 1;
          _macro_editor__fmreg_hpos[TRUE] := 1;
          _macro_editor__fmreg_page[FALSE] := 1;
          _macro_editor__fmreg_page[TRUE] := 1;
          _macro_editor__fmreg_left_margin[FALSE] := 1;
          _macro_editor__fmreg_left_margin[TRUE] := 1;
          _macro_editor__fmreg_cursor_pos[FALSE] := 1;
          _macro_editor__fmreg_cursor_pos[TRUE] := 1;
          add_bank_position('?internal_instrument_data?macro?pos',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_page',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_hpos',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_vpos',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_left_margin',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_cursor_pos',-1,1);
        end;

      If (temp1 = 8) then
        begin
          FillChar(songdata.macro_table,SizeOf(songdata.macro_table),0);
          _macro_editor__pos[TRUE] := 8;
          _macro_editor__arpeggio_page[FALSE] := 1;
          _macro_editor__arpeggio_page[TRUE] := 1;
          _macro_editor__vibrato_hpos[FALSE] := 1;
          _macro_editor__vibrato_hpos[TRUE] := 1;
          _macro_editor__vibrato_page[FALSE] := 1;
          _macro_editor__vibrato_page[TRUE] := 1;
          add_bank_position('?internal_instrument_data?macro_av?pos',-1,1);
          add_bank_position('?internal_instrument_data?macro_av?arp_pos',-1,1);
          add_bank_position('?internal_instrument_data?macro_av?vib_pos',-1,1);
        end;

      If (temp1 = 9) then
        begin
          fade_out_playback(FALSE);
          stop_playing;
          tempo := init_tempo;
          speed := init_speed;
          mark_line := 4;
          IRQ_freq_shift := 0;
          playback_speed_shift := 0;
          init_songdata;
          POSITIONS_reset;
          songdata_title := 'noname.';
          FillChar(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
          track_notes := FALSE;
          track_chan_start := 1;
          nm_track_chan := 1;
          remap_mtype := 1;
          remap_ins1 := 1;
          remap_ins2 := 1;
          remap_selection := 1;
          replace_selection := 1;
          replace_prompt := FALSE;
          replace_data.event_to_find.note := '???';
          replace_data.event_to_find.inst := '??';
          replace_data.event_to_find.fx_1 := '???';
          replace_data.event_to_find.fx_2 := '???';
          replace_data.new_event.note := '???';
          replace_data.new_event.inst := '??';
          replace_data.new_event.fx_1 := '???';
          replace_data.new_event.fx_2 := '???';
          current_inst := 1;
          pattern_list__page := 1;
          _macro_editor__pos[FALSE] := 1;
          _macro_editor__pos[TRUE] := 8;
          _macro_editor__fmreg_hpos[FALSE] := 1;
          _macro_editor__fmreg_hpos[TRUE] := 1;
          _macro_editor__fmreg_page[FALSE] := 1;
          _macro_editor__fmreg_page[TRUE] := 1;
          _macro_editor__fmreg_left_margin[FALSE] := 1;
          _macro_editor__fmreg_left_margin[TRUE] := 1;
          _macro_editor__fmreg_cursor_pos[FALSE] := 1;
          _macro_editor__fmreg_cursor_pos[TRUE] := 1;
          add_bank_position('?internal_instrument_data?macro?pos',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_page',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_hpos',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_vpos',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_left_margin',-1,1);
          add_bank_position('?internal_instrument_data?macro?fmreg_cursor_pos',-1,1);
          _macro_editor__arpeggio_page[FALSE] := 1;
          _macro_editor__arpeggio_page[TRUE] := 1;
          _macro_editor__vibrato_hpos[FALSE] := 1;
          _macro_editor__vibrato_hpos[TRUE] := 1;
          _macro_editor__vibrato_page[FALSE] := 1;
          _macro_editor__vibrato_page[TRUE] := 1;
          add_bank_position('?internal_instrument_data?macro_av?pos',-1,1);
          add_bank_position('?internal_instrument_data?macro_av?arp_pos',-1,1);
          add_bank_position('?internal_instrument_data?macro_av?vib_pos',-1,1);
          add_bank_position('?song_variables_window?pos',-1,1);
          add_bank_position('?song_variables_window?pos_4op',-1,0);
          add_bank_position('?replace_window?pos',-1,1);
          add_bank_position('?replace_window?posfx',-1,1);
          add_bank_position('?message_board?hpos',-1,1);
          add_bank_position('?message_board?vpos',-1,1);
          For temp := 1 to 255 do
            begin
              add_bank_position('?instrument_editor?'+byte2hex(temp)+'?carrier',-1,1);
              add_bank_position('?instrument_editor?'+byte2hex(temp)+'?carrier?hpos',-1,1);
              add_bank_position('?instrument_editor?'+byte2hex(temp)+'?carrier?vpos',-1,1);
              add_bank_position('?instrument_editor?'+byte2hex(temp)+'?modulator?hpos',-1,1);
              add_bank_position('?instrument_editor?'+byte2hex(temp)+'?modulator?vpos',-1,1);
            end;
          For temp := 1 to _rearrange_nm_tracks do _rearrange_tracklist_idx[temp] := temp;
          _rearrange_track_pos := 1;
        end
      else module_archived := FALSE;
    end;
end;

procedure MESSAGE_BOARD;

const
  new_keys: array[1..21] of Word = (kF1,kESC,kENTER,kUP,kDOWN,kLEFT,kRIGHT,
                                    kHOME,kEND,kPgUP,kPGDOWN,kCtHOME,kCtEND,
                                    kCtPgUP,kCtPgDN,kTAB,kCtBkSp,
                                    kCtrlY,kDELETE,kBkSPC,kSPACE);
var
  old_keys: array[1..21] of Word;
  old_append_enabled: Boolean;
  idx,idx2,vpos,vpos2,ref_vpos,old_vpos,hpos: Byte;
  xstart,ystart: Byte;
  flag: Boolean;
  fkey: Word;
  temps: String;
  p_mb: pMESSAGE_BOARD_DATA;

label _jmp1;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:MESSAGE_BOARD';
{$ENDIF}
  p_mb := Addr(songdata.reserved_data);
  If Empty(songdata.reserved_data,SizeOf(songdata.reserved_data)) then
    p_mb^.signature := MB_SIGNATURE
  else If (p_mb^.signature <> MB_SIGNATURE) then EXIT;
 is_environment.insert_mode := TRUE;

_jmp1:
  If _force_program_quit then EXIT;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  HideCursor;

  ScreenMemCopy(screen_ptr,ptr_temp_screen);
  centered_frame_vdest := ptr_temp_screen;
  centered_frame(xstart,ystart,MB_HSIZE+3,MB_VSIZE+1,' MESSAGE BOARD ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);

  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+MB_HSIZE+3+2;
  move_to_screen_area[4] := ystart+MB_VSIZE+1+1;

  For idx := 1 to MB_VSIZE do
    ShowStr(centered_frame_vdest,xstart+2,ystart+1+idx-1,
            ExpStrR(p_mb^.data[idx],MB_HSIZE,' '),
            dl_setting.text_attr);

  move2screen_alt;
  centered_frame_vdest := screen_ptr;

  old_append_enabled := is_setting.append_enabled;
  is_setting.append_enabled := FALSE;
  Move(is_setting.terminate_keys,old_keys,SizeOf(old_keys));
  Move(new_keys,is_setting.terminate_keys,SizeOf(new_keys));

  hpos := min(get_bank_position('?message_board?hpos',-1),1);
  vpos := min(get_bank_position('?message_board?vpos',-1),1);

  If NOT _force_program_quit then
    Repeat
      If (hpos > Length(p_mb^.data[vpos])+1) then
        hpos := Length(p_mb^.data[vpos])+1;

      is_setting.insert_mode := is_environment.insert_mode;
      is_environment.locate_pos := hpos;
          is_setting.character_set := [#32..#255];

      p_mb^.data[vpos] := InputStr(p_mb^.data[vpos],xstart+2,
                                   ystart+1+vpos-1,MB_HSIZE,MB_HSIZE,
                                   dl_setting.text_attr,dl_setting.text_attr);

      hpos := is_environment.locate_pos;
      fkey := is_environment.keystroke;
      ref_vpos := vpos;

      Case fkey of
        kUP: If (vpos > 1) then Dec(vpos);
        kDOWN: If (vpos < MB_VSIZE) then Inc(vpos);

        kLEFT: If (hpos > 1) then Dec(hpos)
               else If (vpos > 1) then
                      begin
                        Dec(vpos);
                        If (Length(p_mb^.data[vpos]) <> 0) then
                          hpos := max(Length(p_mb^.data[vpos])+1,MB_HSIZE)
                        else begin
                               hpos := MB_HSIZE;
                               p_mb^.data[vpos] := ExpStrR('',MB_HSIZE,' ');
                             end;
                      end;

        kRIGHT: If (hpos < MB_HSIZE) then Inc(hpos)
                else If (vpos < MB_VSIZE) then
                      begin
                        Inc(vpos);
                        hpos := 1;
                      end;

        kCtPgUP: vpos := 1;
        kCtPgDN: vpos := MB_VSIZE;

        kPgUP: begin
                 old_vpos := vpos;
                 If (vpos > 1) then
                   Repeat
                     Dec(vpos);
                   until (vpos = 1) or
                         (CutStr(p_mb^.data[vpos]) <> '');
                 If (vpos = old_vpos) then vpos := 1;
               end;

        kPgDOWN: begin
                   old_vpos := vpos;
                   If (vpos < MB_VSIZE) then
                     Repeat
                       Inc(vpos);
                     until (vpos = MB_VSIZE) or
                           (CutStr(p_mb^.data[vpos]) <> '');
                   If (vpos = old_vpos) then vpos := MB_VSIZE;
                 end;

        kHOME: If (hpos > 1) then hpos := 1
               else vpos := 1;

        kCtHOME: begin
                   vpos := 1;
                   hpos := 1;
                 end;

        kEND: If (hpos < Length(CutStrR(p_mb^.data[vpos],0))+1) then
                hpos := Length(CutStrR(p_mb^.data[vpos],0))+1
              else If (hpos < MB_HSIZE) then hpos := MB_HSIZE
                   else vpos := MB_VSIZE;

        kCtEND: begin
                  vpos := MB_VSIZE;
                  hpos := Length(p_mb^.data[MB_VSIZE])+1;
                end;

        kENTER: If (vpos < MB_VSIZE) then
                  begin
                    If (CutStr(p_mb^.data[MB_VSIZE]) = '') then
                      begin
                        If (hpos < MB_HSIZE) then
                          begin
                            temps := Copy(p_mb^.data[vpos],hpos,Length(p_mb^.data[vpos]));
                            If (temps <> '') then
                              Delete(p_mb^.data[vpos],hpos,Length(p_mb^.data[vpos]));
                          end
                        else temps := '';
                        For idx := MB_VSIZE downto vpos+1 do
                          p_mb^.data[idx] := p_mb^.data[idx-1];
                        p_mb^.data[vpos+1] := temps;
                      end;
                    Inc(vpos);
                    hpos := 1;
                  end;

        kDELETE: If ((hpos = Length(p_mb^.data[vpos])) and (p_mb^.data[vpos][Length(p_mb^.data[vpos])] <> ' ')) or
                    NOT ((CutStr(p_mb^.data[vpos]) = '') or
                         (hpos >= Length(p_mb^.data[vpos])) or
                         (CutStrR(p_mb^.data[vpos],hpos) <> CutStrR(p_mb^.data[vpos],0))) then
                   Delete(p_mb^.data[vpos],hpos,1)
                 else If (vpos < MB_VSIZE) then
                        begin
                          If (Length(CutStrR(p_mb^.data[vpos],hpos))+
                              Length(CutStrR(p_mb^.data[vpos+1],0)) <= MB_HSIZE) then
                          begin
                            p_mb^.data[vpos] := CutStrR(p_mb^.data[vpos],hpos)+
                                                CutStrR(p_mb^.data[vpos+1],0);
                            If (Length(p_mb^.data[vpos]) > MB_HSIZE) then
                              Delete(p_mb^.data[vpos],MB_HSIZE+1,Length(p_mb^.data[vpos]));
                            For idx := vpos+1 to MB_VSIZE-1 do
                              p_mb^.data[idx] := p_mb^.data[idx+1];
                            p_mb^.data[MB_VSIZE] := '';
                          end;
                        end;

        kTAB: begin
                If (vpos > 1) then
                  begin
                    vpos2 := vpos;
                    Repeat
                      Dec(vpos2);
                      temps := CutStr(Copy(p_mb^.data[vpos2],hpos+1,Length(p_mb^.data[vpos2])-hpos));
                    until (vpos2 = 1) or (temps <> '');
                    If (hpos <= Length(p_mb^.data[vpos2])) then
                      begin
                        idx2 := hpos+1;
                        While (idx2 < Length(p_mb^.data[vpos2])) and
                              (p_mb^.data[vpos2][idx2] <> ' ') do
                          Inc(idx2);
                        While (idx2 < Length(p_mb^.data[vpos2])) and
                              (p_mb^.data[vpos2][idx2] = ' ') do
                          Inc(idx2);
                        If (idx2-hpos > 1) then
                          begin
                            Insert(ExpStrL('',idx2-hpos,' '),p_mb^.data[vpos],hpos);
                            Inc(hpos,idx2-hpos);
                          end
                      end
                  end;
                If (Length(p_mb^.data[vpos]) > MB_HSIZE) then
                  Delete(p_mb^.data[vpos],MB_HSIZE+1,Length(p_mb^.data[vpos]));
              end;

        kSPACE: begin
                  If NOT ctrl_pressed then idx2 := vpos
                  else idx2 := MB_VSIZE;
                  flag := FALSE;
                  For idx := vpos to idx2 do
                    If (Length(CutStrR(p_mb^.data[idx],0)) = MB_HSIZE) then
                      begin
                        flag := TRUE;
                        BREAK;
                      end;
                  If NOT flag and is_environment.insert_mode then
                    For idx := vpos to idx2 do
                      begin
                        Insert(' ',p_mb^.data[idx],hpos);
                        If (Length(p_mb^.data[idx]) > MB_HSIZE) then
                          Delete(p_mb^.data[idx],MB_HSIZE+1,Length(p_mb^.data[idx]));
                      end
                  else If NOT is_environment.insert_mode then
                         p_mb^.data[idx][hpos] := ' ';

                  If (NOT flag or NOT is_environment.insert_mode) and (hpos < MB_HSIZE) then
                    Inc(hpos);
                end;

        kCtBkSp: If NOT shift_pressed then
                   begin
                     If (hpos = MB_HSIZE) and
                        (BYTE(p_mb^.data[vpos][0]) > 0) then
                       Dec(BYTE(p_mb^.data[vpos][0]));
                     While (p_mb^.data[vpos][hpos-1] in is_setting.word_characters) and
                           (hpos > 1) do
                       begin
                         Dec(hpos);
                         Delete(p_mb^.data[vpos],hpos,1);
                       end;
                     While NOT (p_mb^.data[vpos][hpos-1] in is_setting.word_characters) and
                               (hpos > 1) do
                       begin
                         Dec(hpos);
                         Delete(p_mb^.data[vpos],hpos,1);
                       end;
                   end
                 else If (hpos < MB_HSIZE) then
                        begin
                          Dec(hpos);
                          If (hpos <> 0) then
                            For idx := vpos to MB_VSIZE do
                              Delete(p_mb^.data[idx],hpos,1)
                          else hpos := 1;
                        end
                      else For idx := vpos to MB_VSIZE do
                             If (BYTE(p_mb^.data[idx][0]) > 0) then
                               Dec(BYTE(p_mb^.data[idx][0]));

        kBkSPC: If (hpos > 1) then
                  If (hpos < MB_HSIZE) or
                     (p_mb^.data[vpos][hpos] = ' ') then
                    begin
                      Dec(hpos);
                      Delete(p_mb^.data[vpos],hpos,1);
                    end
                  else If (BYTE(p_mb^.data[vpos][0]) > 0) then
                         Dec(BYTE(p_mb^.data[vpos][0]))
                       else
                else If (vpos > 1) then
                       If (Length(CutStrR(p_mb^.data[vpos-1],0))+
                           Length(CutStrR(p_mb^.data[vpos],0)) <= MB_HSIZE) then
                         begin
                           Dec(vpos);
                           hpos := Length(p_mb^.data[vpos])+1;
                           p_mb^.data[vpos] := CutStrR(p_mb^.data[vpos],0)+
                                               CutStrR(p_mb^.data[vpos+1],0);
                           If (Length(p_mb^.data[vpos]) > MB_HSIZE) then
                             Delete(p_mb^.data[vpos],MB_HSIZE+1,Length(p_mb^.data[vpos]));
                           For idx := vpos+1 to MB_VSIZE-1 do
                             p_mb^.data[idx] := p_mb^.data[idx+1];
                           p_mb^.data[MB_VSIZE] := '';
                         end;

        kCtrlY: If NOT shift_pressed then
                  begin
                    For idx := vpos to MB_VSIZE-1 do
                      p_mb^.data[idx] := p_mb^.data[idx+1];
                    p_mb^.data[MB_VSIZE] := '';
                  end;
      end;

      If (Length(p_mb^.data[vpos]) < hpos) then
        p_mb^.data[vpos] := ExpStrR(p_mb^.data[vpos],hpos,' ');

      If (ref_vpos <> vpos) then
        p_mb^.data[ref_vpos] := CutStrR(p_mb^.data[ref_vpos],0);

      For idx := 1 to MB_VSIZE do
        ShowStr(centered_frame_vdest,xstart+2,ystart+1+idx-1,
                ExpStrR(p_mb^.data[idx],MB_HSIZE,' '),
                dl_setting.text_attr);
    until (fkey = kESC) or (fkey = kF1) or
          _force_program_quit;

  is_setting.append_enabled := old_append_enabled;
  Move(old_keys,is_setting.terminate_keys,SizeOf(old_keys));
  add_bank_position('?message_board?hpos',-1,hpos);
  add_bank_position('?message_board?vpos',-1,vpos);

  HideCursor;
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+MB_HSIZE+3+2;
  move_to_screen_area[4] := ystart+MB_VSIZE+1+1;
  move2screen;

  If (fkey = kF1) then
    begin
      HELP('message_board');
      GOTO _jmp1;
    end;
end;

procedure QUIT_request;

var
  temp: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:QUIT_request';
{$ENDIF}
  If _force_program_quit then
    begin
      fkey := kESC;
      EXIT;
    end;

  temp := Dialog('...AND YOU WiLL KNOW MY NAME iS THE LORD, WHEN i LAY$'+
                 'MY VENGEANCE UPON THEE...$',
                 '~Q~UiT$~O~OOPS$',
                 ' EZECHiEL 25:17 ',1);

  If (dl_environment.keystroke <> kESC) and (temp = 1) then
    begin
      fkey := kESC;
      _force_program_quit := TRUE;
    end
  else fkey := kENTER;
end;

procedure show_progress(value: Longint);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:show_progress';
{$ENDIF}
  If (progress_num_steps = 0) or
     (progress_value = 0) then
    EXIT;
  If (value <> DWORD_NULL) then
    begin
      If (progress_num_steps = 1) then
        progress_new_value := Round(40/progress_value*value)
      else progress_new_value :=
             Round(40/progress_num_steps*PRED(progress_step)+
                   40/progress_num_steps/progress_value*value);
      progress_new_value := max(progress_new_value,40);
      If (progress_new_value <> progress_old_value) then
        begin
          progress_old_value := progress_new_value;
          ShowStr(screen_ptr,progress_xstart+35,progress_ystart-1,
                  ExpStrL(Num2Str(Round(100/40*progress_new_value),10)+'%',5,' '),
                  dialog_background+dialog_hi_text);
          ShowCStr(screen_ptr,
                   progress_xstart,progress_ystart,
                   '~'+ExpStrL('',progress_new_value,#219)+'~'+
                   ExpStrL('',40-progress_new_value,#219),
                   dialog_background+dialog_prog_bar1,
                   dialog_background+dialog_prog_bar2);
          realtime_gfx_poll_proc;
          draw_screen;
        end;
    end
  else begin
         ShowStr(screen_ptr,progress_xstart+35,progress_ystart-1,
                 ExpStrL('0%',5,' '),
                 dialog_background+dialog_hi_text);
         ShowStr(screen_ptr,
                 progress_xstart,progress_ystart,
                 ExpStrL('',40,#219),
                 dialog_background+dialog_prog_bar1);
         realtime_gfx_poll_proc;
         draw_screen;
       end;
end;

procedure show_progress(value,refresh_dif: Longint);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:show_progress';
{$ENDIF}
  If (progress_num_steps = 0) or
     (progress_value = 0) then
    EXIT;
  If (value <> DWORD_NULL) then
    begin
      If (progress_num_steps = 1) then
        progress_new_value := Round(40/progress_value*value)
      else progress_new_value :=
             Round(40/progress_num_steps*PRED(progress_step)+
                   40/progress_num_steps/progress_value*value);
      progress_new_value := max(progress_new_value,40);
      If (Abs(progress_new_value-progress_old_value) >= refresh_dif) or
         (progress_new_value = 40) then
        begin
          progress_old_value := progress_new_value;
          ShowStr(screen_ptr,progress_xstart+35,progress_ystart-1,
                  ExpStrL(Num2Str(Round(100/40*progress_new_value),10)+'%',5,' '),
                  dialog_background+dialog_hi_text);
          ShowCStr(screen_ptr,
                   progress_xstart,progress_ystart,
                   '~'+ExpStrL('',progress_new_value,#219)+'~'+
                   ExpStrL('',40-progress_new_value,#219),
                   dialog_background+dialog_prog_bar1,
                   dialog_background+dialog_prog_bar2);
          realtime_gfx_poll_proc;
          draw_screen;
        end;
    end
  else begin
         ShowStr(screen_ptr,progress_xstart+35,progress_ystart-1,
                 ExpStrL('0%',5,' '),
                 dialog_background+dialog_hi_text);
         ShowStr(screen_ptr,
                 progress_xstart,progress_ystart,
                 ExpStrL('',40,#219),
                 dialog_background+dialog_prog_bar1);
         realtime_gfx_poll_proc;
         draw_screen;
       end;
end;

const
  last_dir:  array[1..4] of String[DIR_SIZE] = ('','','','');
  last_file: array[1..4] of String[FILENAME_SIZE] = ('FNAME:EXT','FNAME:EXT',
                                                     'FNAME:EXT','FNAME:EXT');

function FILE_open(masks: String; loadBankPossible: Boolean): Byte;

var
  fname,temps: String;
  mpos,index: Byte;
  old_ext_proc: procedure;
  old_songdata_source: String;
  old_play_status: tPLAY_STATUS;
  old_tracing: Boolean;
  temp_marks: array[1..255] of Char;
  temp_marks2: array[0..$7f] of Char;
  xstart,ystart: Byte;
  flag: Byte;

procedure _restore;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:FILE_open:_restore';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
end;

label _jmp1;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:FILE_open';
{$ENDIF}
  flag := BYTE_NULL;
  old_play_status := play_status;
  old_tracing := tracing;
  If (Pos('a2i',Lower(masks)) = 0) and (Pos('a2f',Lower(masks)) = 0) and (Pos('a2w',Lower(masks)) = 0) then mpos := 1
  else mpos := 2;

  For index := 1 to 255 do
    temp_marks[index] := songdata.instr_names[index][1];

  For index := 0 to $7f do
    temp_marks2[index] := songdata.pattern_names[index][1];

_jmp1:
  If _force_program_quit then EXIT;

  old_songdata_source := songdata_source;
  If NOT quick_cmd then
    begin
      fs_environment.last_file := last_file[mpos];
      fs_environment.last_dir  := last_dir[mpos];

      old_ext_proc := mn_environment.ext_proc;
      If (mpos = 2) then mn_environment.ext_proc := fselect_external_proc;
      fname := Fselect(masks);
      mn_environment.ext_proc := old_ext_proc;

      last_file[mpos] := fs_environment.last_file;
      last_dir[mpos]  := fs_environment.last_dir;

      If (mn_environment.keystroke <> kENTER) then EXIT
      else If (mpos = 1) then songdata_source := fname
           else instdata_source := fname;
    end
  else If (mpos = 1) then fname := songdata_source
       else fname := instdata_source;

  load_flag := BYTE_NULL;
  limit_exceeded := FALSE;
  HideCursor;

  nul_volume_bars;
  no_status_refresh := TRUE;

  If (Lower(ExtOnly(fname)) = 'a2m') or (Lower(ExtOnly(fname)) = 'a2t') then
    begin
      ScreenMemCopy(screen_ptr,ptr_screen_backup);
      centered_frame_vdest := screen_ptr;

      temps := Upper(ExtOnly(fname))+' FiLE';
      centered_frame(xstart,ystart,43,3,' '+temps+' ',
                     dialog_background+dialog_border,
                     dialog_background+dialog_title,
                     frame_double);

      progress_xstart := xstart+2;
      progress_ystart := ystart+2;
      progress_num_steps := 1;
      progress_step := 1;

      If (Lower(ExtOnly(fname)) = 'a2m') then
        temps := 'MODULE'
      else temps := 'TiNY MODULE';

      ShowCStr(screen_ptr,xstart+2,ystart+1,
               'DECOMPRESSiNG '+temps+' DATA...',
               dialog_background+dialog_text,
               dialog_background+dialog_hi_text);
      show_progress(DWORD_NULL);
    end;

  If (Lower(ExtOnly(fname)) = 'a2m') then a2m_file_loader;
  If (Lower(ExtOnly(fname)) = 'a2t') then a2t_file_loader;
  If (Lower(ExtOnly(fname)) = 'a2p') then a2p_file_loader;
  If (Lower(ExtOnly(fname)) = 'amd') then amd_file_loader;
  If (Lower(ExtOnly(fname)) = 'cff') then cff_file_loader;
  If (Lower(ExtOnly(fname)) = 'dfm') then dfm_file_loader;
  If (Lower(ExtOnly(fname)) = 'fmk') then fmk_file_loader;
  If (Lower(ExtOnly(fname)) = 'hsc') then hsc_file_loader;
  If (Lower(ExtOnly(fname)) = 'mtk') then mtk_file_loader;
  If (Lower(ExtOnly(fname)) = 'rad') then rad_file_loader;
  If (Lower(ExtOnly(fname)) = 's3m') then s3m_file_loader;
  If (Lower(ExtOnly(fname)) = 'sat') then sat_file_loader;
  If (Lower(ExtOnly(fname)) = 'sa2') then sa2_file_loader;
  If (Lower(ExtOnly(fname)) = 'xms') then amd_file_loader;
  If (Lower(ExtOnly(fname)) = 'a2i') then a2i_file_loader;
  If (Lower(ExtOnly(fname)) = 'a2f') then a2f_file_loader;

  If ((Lower(ExtOnly(fname)) = 'a2m') or (Lower(ExtOnly(fname)) = 'a2t')) and
     (load_flag = 1)  then
    begin
      progress_num_steps := 1;
      progress_step := 1;
      progress_value := 1;
      progress_old_value := BYTE_NULL;
      _draw_screen_without_delay := TRUE;
      show_progress(1);
      // delay for awhile to show progress bar at 100%
{$IFDEF GO32V2}
      CRT.Delay(500);
{$ELSE}
      SDL_Delay(200);
{$ENDIF}
      _restore;
    end;

  If (Lower(ExtOnly(fname)) = 'a2b') then
    If shift_pressed and NOT ctrl_pressed and
       NOT alt_pressed then
      begin
        If loadBankPossible then
          begin
            index := Dialog('ALL UNSAVED INSTRUMENT DATA WiLL BE LOST$'+
                            'DO YOU WiSH TO CONTiNUE?$',
                            '~Y~UP$~N~OPE$',' A2B LOADER ',1);
            If (dl_environment.keystroke <> kESC) and (index = 1) then
              a2b_file_loader(FALSE,loadBankPossible); // w/o bank selector
          end
        else a2b_file_loader(TRUE,loadBankPossible); // w/ bank selector
      end
    else a2b_file_loader(TRUE,loadBankPossible); // w/ bank selector

  If (Lower(ExtOnly(fname)) = 'a2w') then
    If shift_pressed and NOT ctrl_pressed and
       NOT alt_pressed then
      begin
        If loadBankPossible then
          begin
            If _arp_vib_loader then
              index := Dialog('ALL UNSAVED ARPEGGiO/ViBRATO MACRO DATA WiLL BE LOST$'+
                              'DO YOU WiSH TO CONTiNUE?$',
                              '~Y~UP$~N~OPE$',' A2W LOADER ',1)
            else
              index := Dialog('ALL UNSAVED iNSTRUMENT AND MACRO DATA WiLL BE LOST$'+
                              'DO YOU WiSH TO CONTiNUE?$',
                              '~Y~UP$~N~OPE$',' A2W LOADER ',1);
            If (dl_environment.keystroke <> kESC) and (index = 1) then
              a2w_file_loader(TRUE,_arp_vib_loader,FALSE,loadBankPossible,FALSE); // w/o bank selector
          end
        else a2w_file_loader(TRUE,_arp_vib_loader,TRUE,loadBankPossible,FALSE); // w/ bank selector
        _arp_vib_loader := FALSE;
      end
    else
      begin
        a2w_file_loader(TRUE,_arp_vib_loader,TRUE,loadBankPossible,FALSE); // w/ bank selector
        _arp_vib_loader := FALSE;
      end;

  If (Lower(ExtOnly(fname)) = 'bnk') then bnk_file_loader;
  If (Lower(ExtOnly(fname)) = 'cif') then cif_file_loader;
  If (Lower(ExtOnly(fname)) = 'fib') then fib_file_loader;
  If (Lower(ExtOnly(fname)) = 'fin') then fin_file_loader;
  If (Lower(ExtOnly(fname)) = 'ibk') then ibk_file_loader;
  If (Lower(ExtOnly(fname)) = 'ins') then ins_file_loader;
  If (Lower(ExtOnly(fname)) = 'sbi') then sbi_file_loader;
  If (Lower(ExtOnly(fname)) = 'sgi') then sgi_file_loader;

//  ThinCursor;
  If (mpos = 1) then
    Case load_flag of
      0: If (old_songdata_source <> '') and
            (old_songdata_source <> songdata_source) then
           begin
             force_scrollbars := TRUE;
             PATTERN_ORDER_page_refresh(pattord_page);
             PATTERN_page_refresh(pattern_page);
             force_scrollbars := FALSE;

             index := Dialog('THERE WAS AN ERROR WHiLE LOADiNG NEW MODULE$'+
                             'DO YOU WiSH TO RELOAD PREViOUS?$',
                             '~Y~UP$~N~OPE$',' PATTERN EDiTOR ',1);

             If (dl_environment.keystroke <> kESC) and (index = 1) then
               begin
                 quick_cmd := TRUE;
                 songdata_source := old_songdata_source;
                 FILE_open('*.a2m$*.a2t$*.a2p$*.amd$*.cff$*.dfm$*.hsc$*.mtk$*.rad$'+
                           '*.s3m$*.sat$*.sa2$*.xms$',FALSE);
                 quick_cmd := FALSE;
               end;
           end
         else
           begin
             force_scrollbars := TRUE;
             PATTERN_ORDER_page_refresh(pattord_page);
             PATTERN_page_refresh(pattern_page);
             force_scrollbars := FALSE;

             index := Dialog('THERE WAS AN ERROR WHiLE LOADiNG NEW MODULE$'+
                             'DO YOU WiSH TO CONTiNUE?$',
                             '~Y~UP$~N~OPE$',' PATTERN EDiTOR ',1);

             If (dl_environment.keystroke <> kESC) and (index = 1) then
             else If (dl_environment.keystroke <> kESC) then init_songdata;
           end;

      1: begin
           If limit_exceeded then
             If (old_songdata_source <> '') and
                (old_songdata_source <> songdata_source) then
               begin
                 force_scrollbars := TRUE;
                 PATTERN_ORDER_page_refresh(pattord_page);
                 PATTERN_page_refresh(pattern_page);
                 force_scrollbars := FALSE;

                 index := Dialog('MODULE WAS NOT COMPLETELY LOADED DUE TO LACK OF MEMORY$'+
                                 'DO YOU WiSH TO RELOAD PREViOUS?$',
                                 '~Y~UP$~N~OPE$',' PATTERN EDiTOR ',1);

                 If (dl_environment.keystroke <> kESC) and (index = 1) then
                   begin
                     quick_cmd := TRUE;
                     songdata_source := old_songdata_source;
                     FILE_open('*.a2m$*.a2t$*.a2p$*.amd$*.cff$*.dfm$*.hsc$*.mtk$*.rad$'+
                               '*.s3m$*.sat$*.sa2$*.xms$',FALSE);
                     quick_cmd := FALSE;
                   end;
               end
             else
               begin
                 force_scrollbars := TRUE;
                 PATTERN_ORDER_page_refresh(pattord_page);
                 PATTERN_page_refresh(pattern_page);
                 force_scrollbars := FALSE;

                 index := Dialog('MODULE WAS NOT COMPLETELY LOADED DUE TO LACK OF MEMORY$'+
                                 'DO YOU WiSH TO CONTiNUE?$',
                                 '~Y~UP$~N~OPE$',' PATTERN EDiTOR ',1);

                 If (dl_environment.keystroke <> kESC) and (index = 1) then
                 else If (dl_environment.keystroke <> kESC) then init_songdata;
               end;

           speed_update    := BOOLEAN(songdata.common_flag AND 1);
           lockvol         := BOOLEAN(songdata.common_flag SHR 1 AND 1);
           lockVP          := BOOLEAN(songdata.common_flag SHR 2 AND 1);
           tremolo_depth   :=         songdata.common_flag SHR 3 AND 1;
           vibrato_depth   :=         songdata.common_flag SHR 4 AND 1;
           panlock         := BOOLEAN(songdata.common_flag SHR 5 AND 1);
           percussion_mode := BOOLEAN(songdata.common_flag SHR 6 AND 1);
           volume_scaling  := BOOLEAN(songdata.common_flag SHR 7 AND 1);

           mark_line := songdata.bpm_data.rows_per_beat;
           IRQ_freq_shift := songdata.bpm_data.tempo_finetune;

           current_tremolo_depth := tremolo_depth;
           current_vibrato_depth := vibrato_depth;

           If NOT percussion_mode then
             begin
               _chan_n := _chmm_n;
               _chan_m := _chmm_m;
               _chan_c := _chmm_c;
             end
           else
             begin
               _chan_n := _chpm_n;
               _chan_m := _chpm_m;
               _chan_c := _chpm_c;
             end;

           init_buffers;
           If (Lower(ExtOnly(fname)) <> 'a2p') then
             For index := 1 to 255 do
               songdata.instr_names[index] :=
                 ' iNS_'+byte2hex(index)+#247' '+
                 Copy(songdata.instr_names[index],10,32);

           If (Lower(ExtOnly(fname)) <> 'a2p') then
             For index := 0 to $7f do
               songdata.pattern_names[index] :=
                 ' PAT_'+byte2hex(index)+'  '#247' '+
                 Copy(songdata.pattern_names[index],12,30);

           If NOT quick_cmd then
             begin
               FillChar(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
               track_notes := FALSE;
               track_chan_start := 1;
               nm_track_chan := 1;
               remap_mtype := 1;
               remap_ins1 := 1;
               remap_ins2 := 1;
               remap_selection := 1;
               replace_selection := 1;
               replace_prompt := FALSE;
               replace_data.event_to_find.note := '???';
               replace_data.event_to_find.inst := '??';
               replace_data.event_to_find.fx_1 := '???';
               replace_data.event_to_find.fx_2 := '???';
               replace_data.new_event.note := '???';
               replace_data.new_event.inst := '??';
               replace_data.new_event.fx_1 := '???';
               replace_data.new_event.fx_2 := '???';
               current_inst := 1;
               pattern_list__page := 1;
               _macro_editor__pos[FALSE] := 1;
               _macro_editor__pos[TRUE] := 8;
               _macro_editor__fmreg_hpos[FALSE] := 1;
               _macro_editor__fmreg_hpos[TRUE] := 1;
               _macro_editor__fmreg_page[FALSE] := 1;
               _macro_editor__fmreg_page[TRUE] := 1;
               _macro_editor__fmreg_left_margin[FALSE] := 1;
               _macro_editor__fmreg_left_margin[TRUE] := 1;
               _macro_editor__fmreg_cursor_pos[FALSE] := 1;
               _macro_editor__fmreg_cursor_pos[TRUE] := 1;
               add_bank_position('?internal_instrument_data?macro?pos',-1,1);
               add_bank_position('?internal_instrument_data?macro?fmreg_page',-1,1);
               add_bank_position('?internal_instrument_data?macro?fmreg_hpos',-1,1);
               add_bank_position('?internal_instrument_data?macro?fmreg_vpos',-1,1);
               add_bank_position('?internal_instrument_data?macro?fmreg_left_margin',-1,1);
               add_bank_position('?internal_instrument_data?macro?fmreg_cursor_pos',-1,1);
               _macro_editor__arpeggio_page[FALSE] := 1;
               _macro_editor__arpeggio_page[TRUE] := 1;
               _macro_editor__vibrato_hpos[FALSE] := 1;
               _macro_editor__vibrato_hpos[TRUE] := 1;
               _macro_editor__vibrato_page[FALSE] := 1;
               _macro_editor__vibrato_page[TRUE] := 1;
               add_bank_position('?internal_instrument_data?macro_av?pos',-1,1);
               add_bank_position('?internal_instrument_data?macro_av?arp_pos',-1,1);
               add_bank_position('?internal_instrument_data?macro_av?vib_pos',-1,1);
               add_bank_position('?song_variables_window?pos',-1,1);
               add_bank_position('?song_variables_window?pos_4op',-1,0);
               add_bank_position('?replace_window?pos',-1,1);
               add_bank_position('?replace_window?posfx',-1,1);
               add_bank_position('?message_board?hpos',-1,1);
               add_bank_position('?message_board?vpos',-1,1);
               For index := 1 to 255 do
                 begin
                   add_bank_position('?instrument_editor?'+byte2hex(index)+'?carrier',-1,1);
                   add_bank_position('?instrument_editor?'+byte2hex(index)+'?carrier?hpos',-1,1);
                   add_bank_position('?instrument_editor?'+byte2hex(index)+'?carrier?vpos',-1,1);
                   add_bank_position('?instrument_editor?'+byte2hex(index)+'?modulator?hpos',-1,1);
                   add_bank_position('?instrument_editor?'+byte2hex(index)+'?modulator?vpos',-1,1);
                 end;
               For index := 1 to _rearrange_nm_tracks do _rearrange_tracklist_idx[index] := index;
               _rearrange_track_pos := 1;
             end
           else begin
                  For index := 1 to 255 do
                     songdata.instr_names[index][1] := temp_marks[index];
                  For index := 0 to $7f do
                     songdata.pattern_names[index][1] := temp_marks2[index];
                end;

           reset_player;
           If NOT quick_cmd or NOT keep_position then
              If (Lower(ExtOnly(fname)) <> 'a2p') and
                 NOT (shift_pressed and (mpos = 1) and (load_flag <> BYTE_NULL) and NOT quick_cmd and
                                        (old_play_status = isPlaying)) then
                POSITIONS_reset;
           songdata_crc := Update32(songdata,SizeOf(songdata),0);
           If (Lower(ExtOnly(fname)) <> 'a2p') then
             begin
               module_archived := TRUE;
               songdata_crc_ord := Update32(songdata.pattern_order,
                                            SizeOf(songdata.pattern_order),0);
             end;
         end
    end
  else
    If (load_flag <> BYTE_NULL) then module_archived := FALSE
    else If NOT quick_cmd then
           If (Lower(ExtOnly(fname)) = 'bnk') or
              (Lower(ExtOnly(fname)) = 'fib') or
              (Lower(ExtOnly(fname)) = 'ibk') then GOTO _jmp1;

  If (load_flag <> BYTE_NULL) then
    begin
      songdata.songname := FilterStr2(songdata.songname,_valid_characters,'_');
      songdata.composer := FilterStr2(songdata.composer,_valid_characters,'_');

      For index := 1 to 255 do
        songdata.instr_names[index] :=
          Copy(songdata.instr_names[index],1,9)+
          FilterStr2(Copy(cstr2str(songdata.instr_names[index]),10,32),_valid_characters,'_');
    end;

  If shift_pressed and
     (mpos = 1) and (load_flag <> BYTE_NULL) and NOT quick_cmd and
     (old_play_status = isPlaying) then
    begin
      start_playing;
      tracing := old_tracing;
      If NOT quick_cmd or NOT keep_position then
        If (Lower(ExtOnly(fname)) <> 'a2p') and NOT tracing then POSITIONS_reset;
    end
  else begin
         force_scrollbars := TRUE;
         PATTERN_ORDER_page_refresh(pattord_page);
         PATTERN_page_refresh(pattern_page);
         force_scrollbars := FALSE;
       end;

  flag := 1;
  FillChar(ai_table,SizeOf(ai_table),0);
  no_status_refresh := FALSE;
  FILE_open := flag;
end;

function _a2m_saver: Byte;

type
  tHEADER = Record
              ident: array[1..10] of Char;
              crc32: Longint;
              ffver: Byte;
              patts: Byte;
              b0len: Longint;
              b1len: array[0..15] of Longint;
            end;
const
  id = '_A2module_';

var
  f: File;
  header: tHEADER;
  temp,index: Longint;
  xstart,ystart: Byte;
  temp_marks: array[1..255] of Char;
  temp_marks2: array[0..$7f] of Char;

procedure _restore;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2m_saver:_restore';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
  progress_num_steps := 0;
  progress_value := 0;
end;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2m_saver';
{$ENDIF}
  _a2m_saver := 0;
  {$i-}
  Assign(f,songdata_source);
  ResetF(f);
  {$i+}
  If (IOresult = 0) and NOT quick_cmd then
    begin
      If (dl_environment.keystroke = kESC) then EXIT;
        temp := Dialog('FiLE "'+iCASE(NameOnly(songdata_source))+
                       '" ALREADY EXiSTS iN DESTiNATiON DiRECTORY$',
                       '~O~VERWRiTE$~R~ENAME$~C~ANCEL$',' A2M SAVER ',1);

      If ((dl_environment.keystroke <> kESC) and (temp = 3)) or
          (dl_environment.keystroke = kESC) then
        begin CloseF(f); EXIT; end
      else If (dl_environment.keystroke <> kESC) and (temp = 2) then
             begin CloseF(f); _a2m_saver := BYTE_NULL; EXIT; end;
    end
  else If (IOresult <> 0) then
         begin
           CloseF(f);
           Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
                  'SAViNG STOPPED$',
                  '~O~KAY$',' A2M SAVER ',1);
           EXIT;
         end;
  {$i-}
  RewriteF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2M SAVER ',1);
      EXIT;
    end;

  FillChar(songdata.songname[SUCC(Length(songdata.songname))],
            PRED(SizeOf(songdata.songname))-
            Length(songdata.songname),0);

  FillChar(songdata.composer[SUCC(Length(songdata.composer))],
            PRED(SizeOf(songdata.composer))-
            Length(songdata.composer),0);

  For temp := 1 to 255 do
    FillChar(songdata.instr_names[temp][SUCC(Length(songdata.instr_names[temp]))],
              PRED(SizeOf(songdata.instr_names[temp]))-
              Length(songdata.instr_names[temp]),0);

  For temp := 0 to $7f do
    FillChar(songdata.pattern_names[temp][SUCC(Length(songdata.pattern_names[temp]))],
              PRED(SizeOf(songdata.pattern_names[temp]))-
              Length(songdata.pattern_names[temp]),0);

  FillChar(header,SizeOf(header),0);
  count_patterns(header.patts);
  header.crc32 := DWORD_NULL;
  header.ident := id;

  songdata.common_flag := BYTE(speed_update)+BYTE(lockvol) SHL 1+
                                             BYTE(lockVP)  SHL 2+
                                             tremolo_depth SHL 3+
                                             vibrato_depth SHL 4+
                                             BYTE(panlock) SHL 5+
                                             BYTE(percussion_mode) SHL 6+
                                             BYTE(volume_scaling) SHL 7;

  songdata.bpm_data.rows_per_beat := mark_line;
  songdata.bpm_data.tempo_finetune := IRQ_freq_shift;

  header.ffver := FFVER_A2M;
  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2M SAVER ',1);
      EXIT;
    end;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  centered_frame_vdest := screen_ptr;
  HideCursor;
  If (header.patts = 0) then header.patts := 1;

  centered_frame(xstart,ystart,43,3,' A2M FiLE ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;
  progress_step := 1;
  progress_num_steps := (header.patts-1) DIV 8 +2;

  ShowCStr(screen_ptr,xstart+2,ystart+1,
           'COMPRESSiNG MODULE DATA...',
           dialog_background+dialog_text,
           dialog_background+dialog_hi_text);
  show_progress(DWORD_NULL);

  For temp := 1 to 255 do
    begin
      temp_marks[temp] := songdata.instr_names[temp][1];
      Delete(songdata.instr_names[temp],1,9);
      FillChar(songdata.instr_names[temp][SUCC(Length(songdata.instr_names[temp]))],
               32-Length(songdata.instr_names[temp]),0);
    end;

  For temp := 0 to $7f do
    begin
      temp_marks2[temp] := songdata.pattern_names[temp][1];
      Delete(songdata.pattern_names[temp],1,11);
      FillChar(songdata.pattern_names[temp][SUCC(Length(songdata.pattern_names[temp]))],
               32-Length(songdata.pattern_names[temp]),0);
    end;

  header.b0len := LZH_compress(songdata,buf1,SizeOf(songdata));
  For temp := 1 to 255 do
    Insert(temp_marks[temp]+
           'iNS_'+byte2hex(temp)+#247' ',
           songdata.instr_names[temp],1);

  For temp := 0 to $7f do
    Insert(temp_marks2[temp]+
           'PAT_'+byte2hex(temp)+'  '#247' ',
           songdata.pattern_names[temp],1);

  BlockWriteF(f,buf1,header.b0len,temp);
  Inc(progress_step);
  If NOT (temp = header.b0len) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2M SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b0len,header.crc32);
  header.b1len[0] := LZH_compress(pattdata^[0],buf1,SizeOf(pattdata^[0]));
  BlockWriteF(f,buf1,header.b1len[0],temp);
  Inc(progress_step);
  If NOT (temp = header.b1len[0]) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2M SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b1len[0],header.crc32);
  For index := 1 to 15 do
    If ((header.patts-1) DIV 8 > PRED(index)) then
      begin
        header.b1len[index] := LZH_compress(pattdata^[index],buf1,SizeOf(pattdata^[index]));
        BlockWriteF(f,buf1,header.b1len[index],temp);
        Inc(progress_step);
        If NOT (temp = header.b1len[index]) then
          begin
            CloseF(f);
            EraseF(f);
            _restore;
            Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
                   'SAViNG STOPPED$',
                   '~O~KAY$',' A2M SAVER ',1);
            EXIT;
          end;
        header.crc32 := Update32(buf1,header.b1len[index],header.crc32);
      end;

  header.crc32 := Update32(header.b0len,2,header.crc32);
  For index := 0 to 15 do
    header.crc32 := Update32(header.b1len[index],2,header.crc32);

  ResetF_RW(f);
  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2M SAVER ',1);
      EXIT;
    end;

  CloseF(f);
  _restore;
  songdata_title := NameOnly(songdata_source);
  songdata_crc := Update32(songdata,SizeOf(songdata),0);
  songdata_crc_ord := Update32(songdata.pattern_order,
                               SizeOf(songdata.pattern_order),0);
  module_archived := TRUE;
end;

function _a2t_saver: Byte;

type
  tHEADER = Record
              ident: array[1..15] of Char;
              crc32: Longint;
              ffver: Byte;
              patts: Byte;
              tempo: Byte;
              speed: Byte;
              cflag: Byte;
              patln: Word;
              nmtrk: Byte;
              mcspd: Word;
              is4op: Byte;
              locks: array[1..20] of Byte;
              b0len: Longint;
              b1len: Longint;
              b2len: Longint;
              b3len: Longint;
              b4len: Longint;
              b5len: array[0..15] of Longint;
            end;
const
  id = '_A2tiny_module_';

var
  f: File;
  header: tHEADER;
  instruments: Byte;
  temp,temp2,index: Longint;
  temps: String;
  xstart,ystart: Byte;

procedure _restore;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2t_saver:_restore';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
  progress_num_steps := 0;
  progress_value := 0;
end;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2t_saver';
{$ENDIF}
  _a2t_saver := 0;
  {$i-}
  Assign(f,songdata_source);
  ResetF(f);
  {$i+}
  If (IOresult = 0) and NOT quick_cmd then
    begin
      If (dl_environment.keystroke = kESC) then EXIT;
        temp := Dialog('FiLE "'+iCASE(NameOnly(songdata_source))+
                       '" ALREADY EXiSTS iN DESTiNATiON DiRECTORY$',
                       '~O~VERWRiTE$~R~ENAME$~C~ANCEL$',' A2T SAVER ',1);

      If ((dl_environment.keystroke <> kESC) and (temp = 3)) or
          (dl_environment.keystroke = kESC) then
        begin CloseF(f); EXIT; end
      else If (dl_environment.keystroke <> kESC) and (temp = 2) then
             begin CloseF(f); _a2t_saver := BYTE_NULL; EXIT; end;
    end
  else If (IOresult <> 0) then
         begin
           CloseF(f);
           Dialog('ERROR WRiTiNG DATA - DiSK ERROR?'+
                  'SAViNG STOPPED$',
                  '~O~KAY$',' A2T SAVER ',1);
           EXIT;
         end;
  {$i-}
  RewriteF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2T SAVER ',1);
      EXIT;
    end;

  FillChar(header,SizeOf(header),0);
  count_patterns(header.patts);
  header.crc32 := DWORD_NULL;
  header.ident := id;
  header.tempo := songdata.tempo;
  header.speed := songdata.speed;
  header.cflag := BYTE(speed_update)+BYTE(lockvol) SHL 1+
                                     BYTE(lockVP)  SHL 2+
                                     tremolo_depth SHL 3+
                                     vibrato_depth SHL 4+
                                     BYTE(panlock) SHL 5+
                                     BYTE(percussion_mode) SHL 6+
                                     BYTE(volume_scaling) SHL 7;

  songdata.bpm_data.rows_per_beat := mark_line;
  songdata.bpm_data.tempo_finetune := IRQ_freq_shift;

  header.patln := songdata.patt_len;
  header.nmtrk := songdata.nm_tracks;
  header.mcspd := songdata.macro_speedup;
  header.is4op := songdata.flag_4op;
  Move(songdata.lock_flags,header.locks,SizeOf(header.locks));
  header.ffver := FFVER_A2T;

  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2T SAVER ',1);
      EXIT;
    end;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  centered_frame_vdest := screen_ptr;
  HideCursor;
  If (header.patts = 0) then header.patts := 1;

  temps := 'A2T FiLE';
  centered_frame(xstart,ystart,43,3,' '+temps+' ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;
  progress_step := 1;
  progress_num_steps := (header.patts-1) DIV 8 +6;

  ShowCStr(screen_ptr,xstart+2,ystart+1,
           'COMPRESSiNG TiNY MODULE DATA...',
           dialog_background+dialog_text,
           dialog_background+dialog_hi_text);
  show_progress(DWORD_NULL);

  count_instruments(instruments);
  instruments := min(instruments,1);
  temp2 := 0;
  Move(songdata.bpm_data,buf2[temp2],SizeOf(songdata.bpm_data));
  Inc(temp2,SizeOf(songdata.bpm_data));
  Move(songdata.ins_4op_flags,buf2[temp2],SizeOf(songdata.ins_4op_flags));
  Inc(temp2,SizeOf(songdata.ins_4op_flags));
  Move(songdata.reserved_data,buf2[temp2],SizeOf(songdata.reserved_data));
  Inc(temp2,SizeOf(songdata.reserved_data));
  Move(songdata.instr_data,buf2[temp2],instruments*SizeOf(songdata.instr_data[1]));
  Inc(temp2,instruments*SizeOf(songdata.instr_data[1]));
  header.b0len := LZH_compress_ultra(buf2,buf1,temp2);
  BlockWriteF(f,buf1,header.b0len,temp);
  Inc(progress_step);
  If NOT (temp = header.b0len) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2T SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b0len,header.crc32);
  temp := 0;
  temp2 := instruments*SizeOf(songdata.instr_macros[1]);
  If NOT Empty(songdata.instr_macros,temp2) then
    begin
      header.b1len := LZH_compress_ultra(songdata.instr_macros,buf1,temp2);
      BlockWriteF(f,buf1,header.b1len,temp);
    end
  else header.b1len := 0;
  Inc(progress_step);
  If NOT (temp = header.b1len) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2T SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b1len,header.crc32);
  temp := 0;
  temp2 := SizeOf(songdata.macro_table);
  If NOT Empty(songdata.macro_table,temp2) then
    begin
      header.b2len := LZH_compress_ultra(songdata.macro_table,buf1,temp2);
      BlockWriteF(f,buf1,header.b2len,temp);
    end
  else header.b2len := 0;
  Inc(progress_step);
  If NOT (temp = header.b2len) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2T SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b2len,header.crc32);
  temp := 0;
  temp2 := SizeOf(songdata.dis_fmreg_col);
  If NOT Empty(songdata.dis_fmreg_col,temp2) then
    begin
      header.b3len := LZH_compress_ultra(songdata.dis_fmreg_col,buf1,temp2);
      BlockWriteF(f,buf1,header.b3len,temp);
    end
  else header.b3len := 0;
  Inc(progress_step);
  If NOT (temp = header.b3len) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2T SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b3len,header.crc32);
  temp2 := SizeOf(songdata.pattern_order);
  header.b4len := LZH_compress_ultra(songdata.pattern_order,buf1,temp2);
  BlockWriteF(f,buf1,header.b4len,temp);
  Inc(progress_step);
  If NOT (temp = header.b4len) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2T SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b4len,header.crc32);
  If (header.patts < 1*8) then temp2 := header.patts*SizeOf(pattdata^[0][0])
  else temp2 := SizeOf(pattdata^[0]);

  header.b5len[0] := LZH_compress_ultra(pattdata^[0],buf1,temp2);
  BlockWriteF(f,buf1,header.b5len[0],temp);
  Inc(progress_step);
  If NOT (temp = header.b5len[0]) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2T SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b5len[0],header.crc32);
  For index := 1 to 15 do
    If ((header.patts-1) DIV 8 > PRED(index)) then
      begin
        If (header.patts < SUCC(index)*8) then
          temp2 := (header.patts-index*8)*SizeOf(pattdata^[index][0])
        else temp2 := SizeOf(pattdata^[index]);
        header.b5len[index] := LZH_compress_ultra(pattdata^[index],buf1,temp2);
        BlockWriteF(f,buf1,header.b5len[index],temp);
        Inc(progress_step);
        If NOT (temp = header.b5len[index]) then
          begin
            CloseF(f);
            EraseF(f);
            _restore;
            Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
                   'SAViNG STOPPED$',
                   '~O~KAY$',' A2T SAVER ',1);
            EXIT;
          end;
        header.crc32 := Update32(buf1,header.b5len[index],header.crc32);
      end;

  header.crc32 := Update32(header.b0len,2,header.crc32);
  header.crc32 := Update32(header.b1len,2,header.crc32);
  header.crc32 := Update32(header.b2len,2,header.crc32);
  header.crc32 := Update32(header.b3len,2,header.crc32);
  header.crc32 := Update32(header.b4len,2,header.crc32);

  For index := 0 to 15 do
    header.crc32 := Update32(header.b5len[index],2,header.crc32);

  ResetF_RW(f);
  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      _restore;
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2T SAVER ',1);
      EXIT;
    end;

  CloseF(f);
  _restore;
  songdata_title := NameOnly(songdata_source);
  songdata_crc := Update32(songdata,SizeOf(songdata),0);
  songdata_crc_ord := Update32(songdata.pattern_order,
                               SizeOf(songdata.pattern_order),0);
  module_archived := TRUE;
end;

function _a2i_saver: Byte;

type
  tHEADER = Record
              ident: array[1..7] of Char;
              crc16: Word;
              ffver: Byte;
              b0len: Word;
            end;
const
  id = '_A2ins_';

var
  f: File;
  header: tHEADER;
  temp,temp2,temp3: Longint;
  ins_4op: Word;
  crc: Word;
  temp_str: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2i_saver';
{$ENDIF}
  _a2i_saver := 0;
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult = 0) and NOT quick_cmd then
    begin
      If (dl_environment.keystroke = kESC) then EXIT;
        temp := Dialog('FiLE "'+iCASE(NameOnly(instdata_source))+
                       '" ALREADY EXiSTS iN DESTiNATiON DiRECTORY$',
                       '~O~VERWRiTE$~R~ENAME$~C~ANCEL$',' A2i SAVER ',1);

      If ((dl_environment.keystroke <> kESC) and (temp = 3)) or
          (dl_environment.keystroke = kESC) then
        begin CloseF(f); EXIT; end
      else If (dl_environment.keystroke <> kESC) and (temp = 2) then
             begin CloseF(f); _a2i_saver := BYTE_NULL; EXIT; end;
    end
  else If (IOresult <> 0) then
         begin
           CloseF(f);
           Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
                  'SAViNG STOPPED$',
                  '~O~KAY$',' A2i SAVER ',1);
           EXIT;
         end;
  {$i-}
  RewriteF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2i SAVER ',1);
      EXIT;
    end;

  progress_num_steps := 0;
  header.ident := id;
  header.ffver := FFVER_A2I;

  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2i SAVER ',1);
      EXIT;
    end;

  temp3 := 0;
  ins_4op := check_4op_to_test;
  If (ins_4op <> 0) then
    begin
      // 4OP 1/2
      Move(songdata.instr_data[HI(ins_4op)],buf2[temp3],
           SizeOf(songdata.instr_data[HI(ins_4op)]));
      Inc(temp3,SizeOf(songdata.instr_data[HI(ins_4op)]));
      temp_str := Copy(songdata.instr_names[HI(ins_4op)],10,32);
      Move(temp_str,buf2[temp3],SUCC(Length(temp_str)));
      Inc(temp3,SUCC(Length(temp_str)));
      // 4OP 2/2
      Move(songdata.instr_data[LO(ins_4op)],buf2[temp3],
           SizeOf(songdata.instr_data[LO(ins_4op)]));
      Inc(temp3,SizeOf(songdata.instr_data[LO(ins_4op)]));
      temp_str := Copy(songdata.instr_names[LO(ins_4op)],10,32);
      Move(temp_str,buf2[temp3],SUCC(Length(temp_str)));
      Inc(temp3,SUCC(Length(temp_str)));
    end
  else begin
         Move(songdata.instr_data[current_inst],buf2[temp3],
              SizeOf(songdata.instr_data[current_inst]));
         Inc(temp3,SizeOf(songdata.instr_data[current_inst]));
         temp_str := Copy(songdata.instr_names[current_inst],10,32);
         Move(temp_str,buf2[temp3],SUCC(Length(temp_str)));
         Inc(temp3,SUCC(Length(temp_str)));
       end;

  temp2 := LZH_compress(buf2,buf3,temp3);
  BlockWriteF(f,buf3,temp2,temp);
  If NOT (temp = temp2) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2i SAVER ',1);
      EXIT;
    end;

  header.b0len := temp;
  crc := WORD_NULL;
  crc := Update16(header.b0len,1,crc);
  crc := Update16(buf3,header.b0len,crc);
  header.crc16 := crc;
  ResetF_RW(f);

  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2i SAVER ',1);
      EXIT;
    end;

  CloseF(f);
end;

function _a2f_saver: Byte;

type
  tHEADER = Record
              ident: array[1..18] of Char;
              crc32: Longint;
              ffver: Byte;
              b0len: Word;
            end;
const
  id = '_a2ins_w/fm-macro_';

var
  f: File;
  header: tHEADER;
  temp,temp2,temp3: Longint;
  ins_4op: Word;
  temp_str: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2f_saver';
{$ENDIF}
  _a2f_saver := 0;
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult = 0) and NOT quick_cmd then
    begin
      If (dl_environment.keystroke = kESC) then EXIT;
        temp := Dialog('FiLE "'+iCASE(NameOnly(instdata_source))+
                       '" ALREADY EXiSTS iN DESTiNATiON DiRECTORY$',
                       '~O~VERWRiTE$~R~ENAME$~C~ANCEL$',' A2F SAVER ',1);

      If ((dl_environment.keystroke <> kESC) and (temp = 3)) or
          (dl_environment.keystroke = kESC) then
        begin CloseF(f); EXIT; end
      else If (dl_environment.keystroke <> kESC) and (temp = 2) then
             begin CloseF(f); _a2f_saver := BYTE_NULL; EXIT; end;
    end
  else If (IOresult <> 0) then
         begin
           CloseF(f);
           Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
                  'SAViNG STOPPED$',
                  '~O~KAY$',' A2F SAVER ',1);
           EXIT;
         end;
  {$i-}
  RewriteF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2F SAVER ',1);
      EXIT;
    end;

  progress_num_steps := 0;
  header.ident := id;
  header.ffver := FFVER_A2F;

  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2F SAVER ',1);
      EXIT;
    end;

  temp3 := 0;
  ins_4op := check_4op_to_test;
  If (ins_4op <> 0) then
    begin
      // 4OP 1/2
      Move(songdata.instr_data[HI(ins_4op)],buf2[temp3],
           SizeOf(songdata.instr_data[HI(ins_4op)]));
      Inc(temp3,SizeOf(songdata.instr_data[HI(ins_4op)]));
      temp_str := Copy(songdata.instr_names[HI(ins_4op)],10,32);
      Move(temp_str,buf2[temp3],SUCC(Length(temp_str)));
      Inc(temp3,SUCC(Length(temp_str)));
      temp2 := 0;
      Move(songdata.instr_macros[HI(ins_4op)],buf3[temp2],
           SizeOf(songdata.instr_macros[HI(ins_4op)]));
      Inc(temp2,SizeOf(songdata.instr_macros[HI(ins_4op)]));
      tREGISTER_TABLE(Addr(buf3[temp2])^).arpeggio_table := 0;
      tREGISTER_TABLE(Addr(buf3[temp2])^).vibrato_table := 0;
      Move(songdata.dis_fmreg_col[HI(ins_4op)],
           buf3[temp2],
           SizeOf(songdata.dis_fmreg_col[HI(ins_4op)]));
      Inc(temp2,SizeOf(songdata.dis_fmreg_col[HI(ins_4op)]));
      Move(buf3,buf2[temp3],temp2);
      Inc(temp3,temp2);
      // 4OP 2/2
      Move(songdata.instr_data[LO(ins_4op)],buf2[temp3],
           SizeOf(songdata.instr_data[LO(ins_4op)]));
      Inc(temp3,SizeOf(songdata.instr_data[LO(ins_4op)]));
      temp_str := Copy(songdata.instr_names[LO(ins_4op)],10,32);
      Move(temp_str,buf2[temp3],SUCC(Length(temp_str)));
      Inc(temp3,SUCC(Length(temp_str)));
      temp2 := 0;
      Move(songdata.instr_macros[LO(ins_4op)],buf3[temp2],
           SizeOf(songdata.instr_macros[LO(ins_4op)]));
      Inc(temp2,SizeOf(songdata.instr_macros[LO(ins_4op)]));
      tREGISTER_TABLE(Addr(buf3[temp2])^).arpeggio_table := 0;
      tREGISTER_TABLE(Addr(buf3[temp2])^).vibrato_table := 0;
      Move(songdata.dis_fmreg_col[LO(ins_4op)],
           buf3[temp2],
           SizeOf(songdata.dis_fmreg_col[LO(ins_4op)]));
      Inc(temp2,SizeOf(songdata.dis_fmreg_col[LO(ins_4op)]));
      Move(buf3,buf2[temp3],temp2);
      Inc(temp3,temp2);
    end
  else begin
         Move(songdata.instr_data[current_inst],buf2[temp3],
              SizeOf(songdata.instr_data[current_inst]));
         Inc(temp3,SizeOf(songdata.instr_data[current_inst]));
         temp_str := Copy(songdata.instr_names[current_inst],10,32);
         Move(temp_str,buf2[temp3],SUCC(Length(temp_str)));
         Inc(temp3,SUCC(Length(temp_str)));
         temp2 := 0;
         Move(songdata.instr_macros[current_inst],buf3[temp2],
              SizeOf(songdata.instr_macros[current_inst]));
         Inc(temp2,SizeOf(songdata.instr_macros[current_inst]));
         tREGISTER_TABLE(Addr(buf3[temp2])^).arpeggio_table := 0;
         tREGISTER_TABLE(Addr(buf3[temp2])^).vibrato_table := 0;
         Move(songdata.dis_fmreg_col[current_inst],
              buf3[temp2],
              SizeOf(songdata.dis_fmreg_col[current_inst]));
         Inc(temp2,SizeOf(songdata.dis_fmreg_col[current_inst]));
         Move(buf3,buf2[temp3],temp2);
         Inc(temp3,temp2);
       end;

  temp2 := LZH_compress(buf2,buf3,temp3);
  BlockWriteF(f,buf3,temp2,temp);
  If NOT (temp = temp2) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2F SAVER ',1);
      EXIT;
    end;

  header.b0len := temp;
  header.crc32 := DWORD_NULL;
  header.crc32 := Update32(header.b0len,1,header.crc32);
  header.crc32 := Update32(buf3,header.b0len,header.crc32);
  ResetF_RW(f);

  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2F SAVER ',1);
      EXIT;
    end;

  CloseF(f);
end;

function _a2p_saver: Byte;

type
  tHEADER = Record
              ident: array[1..11] of Char;
              crc32: Longint;
              ffver: Byte;
              b0len: Longint;
            end;
const
  id = '_A2pattern_';

var
  f: File;
  header: tHEADER;
  temp,temp2: Longint;
  temp_str: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2p_saver';
{$ENDIF}
  _a2p_saver := 0;
  {$i-}
  Assign(f,songdata_source);
  ResetF(f);
  {$i+}
  If (IOresult = 0) and NOT quick_cmd then
    begin
      If (dl_environment.keystroke = kESC) then EXIT;
        temp := Dialog('FiLE "'+iCASE(NameOnly(songdata_source))+
                       '" ALREADY EXiSTS iN DESTiNATiON DiRECTORY$',
                       '~O~VERWRiTE$~R~ENAME$~C~ANCEL$',' A2P SAVER ',1);

      If ((dl_environment.keystroke <> kESC) and (temp = 3)) or
          (dl_environment.keystroke = kESC) then
        begin CloseF(f); EXIT; end
      else If (dl_environment.keystroke <> kESC) and (temp = 2) then
             begin CloseF(f); _a2p_saver := BYTE_NULL; EXIT; end;
    end
  else If (IOresult <> 0) then
         begin
           CloseF(f);
           Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
                  'SAViNG STOPPED$',
                  '~O~KAY$',' A2P SAVER ',1);
           EXIT;
         end;
  {$i-}
  RewriteF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2P SAVER ',1);
      EXIT;
    end;

  progress_num_steps := 0;
  header.crc32 := DWORD_NULL;
  header.ident := id;
  header.ffver := FFVER_A2P;

  If (pattern2use <> BYTE_NULL) then
    Move(pattdata^[pattern2use DIV 8][pattern2use MOD 8],
         buf2,
         PATTERN_SIZE)
  else
    Move(pattdata^[pattern_patt DIV 8][pattern_patt MOD 8],
         buf2,
         PATTERN_SIZE);

  If (pattern2use <> BYTE_NULL) then
    temp_str := Copy(songdata.pattern_names[pattern2use],12,30)
  else temp_str := Copy(songdata.pattern_names[pattern_patt],12,30);

  FillChar(temp_str[SUCC(Length(temp_str))],30-Length(temp_str),0);
  Move(temp_str,buf2[PATTERN_SIZE],Length(temp_str)+1);

  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2P SAVER ',1);
      EXIT;
    end;

  temp2 := PATTERN_SIZE+30+1;
  header.b0len := LZH_compress(buf2,buf1,temp2);

  BlockWriteF(f,buf1,header.b0len,temp);
  If NOT (temp = header.b0len) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2P SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b0len,header.crc32);
  header.crc32 := Update32(header.b0len,2,header.crc32);

  ResetF_RW(f);
  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2P SAVER ',1);
      EXIT;
    end;

  CloseF(f);
end;

function _a2b_saver: Byte;

const
  id = '_A2insbank_';

type
  tHEADER = Record
              ident: array[1..11] of Char;
              crc32: Longint;
              ffver: Byte;
              b0len: Longint;
            end;
var
  f: File;
  header: tHEADER;
  temp,temp2,temp3: Longint;
  crc: Longint;
  temp_marks: array[1..255] of Char;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2b_saver';
{$ENDIF}
  _a2b_saver := 0;
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult = 0) and NOT quick_cmd then
    begin
      If (dl_environment.keystroke = kESC) then EXIT;
        temp := Dialog('FiLE "'+iCASE(NameOnly(instdata_source))+
                       '" ALREADY EXiSTS iN DESTiNATiON DiRECTORY$',
                       '~O~VERWRiTE$~R~ENAME$~C~ANCEL$',' A2B SAVER ',1);

      If ((dl_environment.keystroke <> kESC) and (temp = 3)) or
          (dl_environment.keystroke = kESC) then
        begin CloseF(f); EXIT; end
      else If (dl_environment.keystroke <> kESC) and (temp = 2) then
             begin CloseF(f); _a2b_saver := BYTE_NULL; EXIT; end;
    end
  else If (IOresult <> 0) then
         begin
           CloseF(f);
           Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
                  'SAViNG STOPPED$',
                  '~O~KAY$',' A2B SAVER ',1);
           EXIT;
         end;
  {$i-}
  RewriteF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2B SAVER ',1);
      EXIT;
    end;

  progress_num_steps := 0;
  header.ident := id;
  header.ffver := FFVER_A2B;

  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2B SAVER ',1);
      EXIT;
    end;

  For temp := 1 to 255 do
    begin
      temp_marks[temp] := songdata.instr_names[temp][1];
      Delete(songdata.instr_names[temp],1,9);
      FillChar(songdata.instr_names[temp][SUCC(Length(songdata.instr_names[temp]))],
               32-Length(songdata.instr_names[temp]),0);
    end;

  temp3 := SizeOf(songdata.instr_names)+SizeOf(songdata.instr_data);
  Move(songdata.instr_names,buf2,temp3);
  Move(songdata.ins_4op_flags,buf2[temp3],SizeOf(songdata.ins_4op_flags));
  Inc(temp3,SizeOf(songdata.ins_4op_flags));
  temp2 := LZH_compress(buf2,buf1,temp3);

  For temp := 1 to 255 do
    Insert(temp_marks[temp]+
           'iNS_'+byte2hex(temp)+#247' ',
           songdata.instr_names[temp],1);

  BlockWriteF(f,buf1,temp2,temp);
  If NOT (temp = temp2) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2B SAVER ',1);
      EXIT;
    end;

  header.b0len := temp;
  crc := DWORD_NULL;
  crc := Update32(header.b0len,2,crc);
  crc := Update32(buf1,header.b0len,crc);
  header.crc32 := crc;
  ResetF_RW(f);

  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2B SAVER ',1);
      EXIT;
    end;

  CloseF(f);
end;

function _a2w_saver: Byte;

const
  id = '_A2insbank_w/macros_';

type
  tHEADER = Record
              ident: array[1..20] of Char;
              crc32: Longint;
              ffver: Byte;
              b0len: Longint;
              b1len: Longint;
              b2len: Longint;
            end;
var
  f: File;
  header: tHEADER;
  temp,temp3: Longint;
  temp_marks: array[1..255] of Char;
  xstart,ystart: Byte;

procedure _restore;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2w_saver:_restore';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
  progress_num_steps := 0;
  progress_value := 0;
end;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2w_saver';
{$ENDIF}
  _a2w_saver := 0;
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult = 0) and NOT quick_cmd then
    begin
      If (dl_environment.keystroke = kESC) then EXIT;
        temp := Dialog('FiLE "'+iCASE(NameOnly(instdata_source))+
                       '" ALREADY EXiSTS iN DESTiNATiON DiRECTORY$',
                       '~O~VERWRiTE$~R~ENAME$~C~ANCEL$',' A2W SAVER ',1);

      If ((dl_environment.keystroke <> kESC) and (temp = 3)) or
          (dl_environment.keystroke = kESC) then
        begin CloseF(f); EXIT; end
      else If (dl_environment.keystroke <> kESC) and (temp = 2) then
             begin CloseF(f); _a2w_saver := BYTE_NULL; EXIT; end;
    end
  else If (IOresult <> 0) then
         begin
           CloseF(f);
           Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
                  'SAViNG STOPPED$',
                  '~O~KAY$',' A2W SAVER ',1);
           EXIT;
         end;
  {$i-}
  RewriteF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK ERROR?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2W SAVER ',1);
      EXIT;
    end;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  centered_frame_vdest := screen_ptr;
  HideCursor;

  centered_frame(xstart,ystart,43,3,' A2W FiLE ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 frame_double);

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;
  progress_step := 1;
  progress_num_steps := 3;

  ShowCStr(screen_ptr,xstart+2,ystart+1,
           'COMPRESSiNG iNSTRUMENT BANK DATA...',
           dialog_background+dialog_text,
           dialog_background+dialog_hi_text);
  show_progress(DWORD_NULL);

  header.crc32 := DWORD_NULL;
  header.ident := id;
  header.ffver := FFVER_A2W;

  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2W SAVER ',1);
      EXIT;
    end;

  For temp := 1 to 255 do
    begin
      temp_marks[temp] := songdata.instr_names[temp][1];
      Delete(songdata.instr_names[temp],1,9);
      FillChar(songdata.instr_names[temp][SUCC(Length(songdata.instr_names[temp]))],
               32-Length(songdata.instr_names[temp]),0);
    end;

  temp3 := SizeOf(songdata.instr_names)+
           SizeOf(songdata.instr_data)+
           SizeOf(songdata.instr_macros);
  Move(songdata.instr_names,buf2,temp3);
  Move(songdata.ins_4op_flags,buf2[temp3],SizeOf(songdata.ins_4op_flags));
  Inc(temp3,SizeOf(songdata.ins_4op_flags));
  header.b0len := LZH_compress(buf2,buf1,temp3);
  Inc(progress_step);
  For temp := 1 to 255 do
    Insert(temp_marks[temp]+
           'iNS_'+byte2hex(temp)+#247' ',
           songdata.instr_names[temp],1);

  BlockWriteF(f,buf1,header.b0len,temp);
  If NOT (temp = header.b0len) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2W SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b0len,header.crc32);
  header.b1len := LZH_compress(songdata.macro_table,buf1,SizeOf(songdata.macro_table));
  Inc(progress_step);
  BlockWriteF(f,buf1,header.b1len,temp);
  If NOT (temp = header.b1len) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2W SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b1len,header.crc32);
  header.b2len := LZH_compress(songdata.dis_fmreg_col,buf1,SizeOf(songdata.dis_fmreg_col));
  Inc(progress_step);
  BlockWriteF(f,buf1,header.b2len,temp);
  If NOT (temp = header.b2len) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2W SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buf1,header.b2len,header.crc32);
  header.crc32 := Update32(header.b0len,2,header.crc32);
  header.crc32 := Update32(header.b1len,2,header.crc32);
  header.crc32 := Update32(header.b2len,2,header.crc32);

  ResetF_RW(f);
  BlockWriteF(f,header,SizeOf(header),temp);
  If NOT (temp = SizeOf(header)) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2W SAVER ',1);
      EXIT;
    end;

  CloseF(f);
  progress_num_steps := 1;
  progress_step := 1;
  progress_value := 1;
  progress_old_value := BYTE_NULL;
  _draw_screen_without_delay := TRUE;
  show_progress(1);
  // delay for awhile to show progress bar at 100%
{$IFDEF GO32V2}
  CRT.Delay(500);
{$ELSE}
  SDL_Delay(200);
{$ENDIF}
  _restore;
end;

procedure FILE_save(ext: String);

var
  quit_flag: Boolean;
  temp_str:  String;
  temp,mpos: Byte;
  old_songdata_source,
  old_instdata_source: String;

label _jmp1,_jmp2;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:FILE_save';
{$ENDIF}
  old_songdata_source := songdata_source;
  old_instdata_source := instdata_source;

  If (songdata_source <> '') then
    songdata_source := iCase_filename(PathOnly(songdata_source))+
                             Lower_filename(BaseNameOnly(songdata_source))+'.'+ext;

  If (instdata_source <> '') then
    instdata_source := iCase_filename(PathOnly(instdata_source))+
                             Lower_filename(BaseNameOnly(instdata_source))+'.'+ext;
_jmp1:
  If quick_cmd then
    If ((Lower_filename(ext) = 'a2m') or (Lower_filename(ext) = 'a2t')) and
        (songdata_source <> '') then GOTO _jmp2;

  Repeat
    is_setting.append_enabled    := TRUE;
    is_setting.character_set     := [#32..#255];
    dl_setting.center_text       := FALSE;
    dl_setting.terminate_keys[3] := kTAB;
    is_setting.terminate_keys[3] := kTAB;
    is_environment.locate_pos    := 1;
    dl_environment.context       := ' TAB '#196#16' FiLE SELECTOR ';

    If (Lower_filename(ext) = 'a2i') then
      begin
        If NOT alt_ins_name then
          begin
            If (a2i_default_path = '') then dl_environment.input_str := instdata_source
            else dl_environment.input_str := iCase_filename(a2i_default_path)+NameOnly(instdata_source);
          end
        else dl_environment.input_str := iCase_filename(a2i_default_path)+
               'instr'+ExpStrL(Num2str(current_inst,10),3,'0')+'.a2i';
      end;

    If (Lower_filename(ext) = 'a2f') then
      begin
        If NOT alt_ins_name then
          begin
            If (a2f_default_path = '') then dl_environment.input_str := instdata_source
            else dl_environment.input_str := iCase_filename(a2f_default_path)+NameOnly(instdata_source);
          end
        else dl_environment.input_str := iCase_filename(a2f_default_path)+
               'instr'+ExpStrL(Num2str(current_inst,10),3,'0')+'.a2f';
      end;

    If (Lower_filename(ext) = 'a2b') then
      If (a2b_default_path = '') then dl_environment.input_str := instdata_source
      else dl_environment.input_str := iCase_filename(a2b_default_path)+NameOnly(instdata_source);

    If (Lower_filename(ext) = 'a2w') then
      If (a2w_default_path = '') then dl_environment.input_str := instdata_source
      else dl_environment.input_str := iCase_filename(a2w_default_path)+NameOnly(instdata_source);

    If (Lower_filename(ext) = 'a2m') then
      If (a2m_default_path = '') then dl_environment.input_str := songdata_source
      else dl_environment.input_str := iCase_filename(a2m_default_path)+NameOnly(songdata_source);

    If (Lower_filename(ext) = 'a2t') then
      If (a2t_default_path = '') then dl_environment.input_str := songdata_source
      else dl_environment.input_str := iCase_filename(a2t_default_path)+NameOnly(songdata_source);

    If (Lower_filename(ext) = 'a2p') then
      If (a2p_default_path = '') then dl_environment.input_str := songdata_source
      else dl_environment.input_str := iCase_filename(a2p_default_path)+NameOnly(songdata_source);

    Dialog('{PATH}[FiLENAME] EXTENSiON iS SET TO "'+iCase_filename(ext)+'"$',
           '%string_input%255$50'+
           '$'+Num2str(dialog_input_bckg+dialog_input,16)+
           '$'+Num2str(dialog_def_bckg+dialog_def,16)+
           '$',' SAVE FiLE ',0);

    dl_setting.terminate_keys[3] := 0;
    is_setting.terminate_keys[3] := 0;
    dl_setting.center_text       := TRUE;
    dl_environment.context       := '';

    If (dl_environment.keystroke = kESC) or
       ((dl_environment.keystroke <> kTAB) and
       (BaseNameOnly(dl_environment.input_str) = '')) then
      begin
        songdata_source := old_songdata_source;
        instdata_source := old_instdata_source;
        EXIT;
      end;

    If (dl_environment.keystroke = kENTER) then
      begin
        If (Lower_filename(ext) = 'a2m') then
          songdata_source := iCase_filename(PathOnly(dl_environment.input_str))+
                             Lower_filename(BaseNameOnly(dl_environment.input_str))+
                             '.a2m';

        If (Lower_filename(ext) = 'a2t') then
          songdata_source := iCase_filename(PathOnly(dl_environment.input_str))+
                             Lower_filename(BaseNameOnly(dl_environment.input_str))+
                             '.a2t';

        If (Lower_filename(ext) = 'a2p') then
          songdata_source := iCase_filename(PathOnly(dl_environment.input_str))+
                             Lower_filename(BaseNameOnly(dl_environment.input_str))+
                             '.a2p';

        If (Lower_filename(ext) = 'a2i') then
          instdata_source := iCase_filename(PathOnly(dl_environment.input_str))+
                             Lower_filename(BaseNameOnly(dl_environment.input_str))+
                             '.a2i';

        If (Lower_filename(ext) = 'a2f') then
          instdata_source := iCase_filename(PathOnly(dl_environment.input_str))+
                             Lower_filename(BaseNameOnly(dl_environment.input_str))+
                             '.a2f';

        If (Lower_filename(ext) = 'a2b') then
          instdata_source := iCase_filename(PathOnly(dl_environment.input_str))+
                             Lower_filename(BaseNameOnly(dl_environment.input_str))+
                             '.a2b';

        If (Lower_filename(ext) = 'a2w') then
          instdata_source := iCase_filename(PathOnly(dl_environment.input_str))+
                             Lower_filename(BaseNameOnly(dl_environment.input_str))+
                             '.a2w';
      end;

    quit_flag := TRUE;
    If (dl_environment.keystroke = kTAB) then
      begin
        If (Lower_filename(ext) <> 'a2i') and (Lower_filename(ext) <> 'a2f') and
           (Lower_filename(ext) <> 'a2b') and (Lower_filename(ext) <> 'a2w') then mpos := 3
        else mpos := 4;

        fs_environment.last_file := last_file[mpos];
        fs_environment.last_dir  := last_dir[mpos];

        temp_str := Fselect('*.'+ext+'$');

        last_file[mpos] := fs_environment.last_file;
        last_dir[mpos]  := fs_environment.last_dir;

        If (mn_environment.keystroke = kESC) then quit_flag := FALSE
        else begin
               If (Lower_filename(ext) = 'a2m') then
                 songdata_source := iCase_filename(PathOnly(temp_str))+
                                    Lower_filename(BaseNameOnly(temp_str))+'.a2m';

               If (Lower_filename(ext) = 'a2t') then
                 songdata_source := iCase_filename(PathOnly(temp_str))+
                                    Lower_filename(BaseNameOnly(temp_str))+'.a2t';

               If (Lower_filename(ext) = 'a2p') then
                 songdata_source := iCase_filename(PathOnly(temp_str))+
                                    Lower_filename(BaseNameOnly(temp_str))+'.a2p';

               If (Lower_filename(ext) = 'a2i') then
                 instdata_source := iCase_filename(PathOnly(temp_str))+
                                    Lower_filename(BaseNameOnly(temp_str))+'.a2i';

               If (Lower_filename(ext) = 'a2f') then
                 instdata_source := iCase_filename(PathOnly(temp_str))+
                                    Lower_filename(BaseNameOnly(temp_str))+'.a2f';

               If (Lower_filename(ext) = 'a2b') then
                 instdata_source := iCase_filename(PathOnly(temp_str))+
                                    Lower_filename(BaseNameOnly(temp_str))+'.a2b';

               If (Lower_filename(ext) = 'a2w') then
                 instdata_source := iCase_filename(PathOnly(temp_str))+
                                    Lower_filename(BaseNameOnly(temp_str))+'.a2w';
             end;
      end;
  until quit_flag;

  If (dl_environment.keystroke = kESC) then
    begin
      songdata_source := old_songdata_source;
      instdata_source := old_instdata_source;
      EXIT;
    end;

_jmp2:
 If (Lower_filename(ext) = 'a2i') or (Lower_filename(ext) = 'a2f') or
    (Lower_filename(ext) = 'a2b') or (Lower_filename(ext) = 'a2w') then
    temp_str := instdata_source;
  If (Lower_filename(ext) = 'a2m') or (Lower_filename(ext) = 'a2t') or (Lower_filename(ext) = 'a2p') then
    temp_str := songdata_source;

  If (Lower_filename(ext) = 'a2m') then temp := _a2m_saver;
  If (Lower_filename(ext) = 'a2t') then temp := _a2t_saver;
  If (Lower_filename(ext) = 'a2i') then temp := _a2i_saver;
  If (Lower_filename(ext) = 'a2f') then temp := _a2f_saver;
  If (Lower_filename(ext) = 'a2p') then temp := _a2p_saver;
  If (Lower_filename(ext) = 'a2b') then temp := _a2b_saver;
  If (Lower_filename(ext) = 'a2w') then temp := _a2w_saver;

  If (temp = BYTE_NULL) then GOTO _jmp1;
end;

end.
