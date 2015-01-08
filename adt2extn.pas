unit AdT2extn;
{$IFDEF __TMT__}
{$S-,Q-,R-,V-,B-,X+}
{$ELSE}
{$PACKRECORDS 1}
{$ENDIF}
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
  progress_step: Real;
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
procedure QUIT_request;
procedure show_progress(value: Longint);

implementation

uses
{$IFNDEF __TMT__}
{$IFDEF UNIX}
  SDL_Timer,
{$ELSE}
  CRT,
{$ENDIF}
  AdT2opl3,
{$ENDIF}
  AdT2sys,AdT2keyb,AdT2unit,AdT2ext2,AdT2ext3,AdT2ext4,AdT2ext5,AdT2text,AdT2apak,
  StringIO,DialogIO,ParserIO,TxtScrIO,MenuLib1,MenuLib2;

function _patts_marked: Byte;

var
  temp,
  result: Byte;

begin
  result := 0;
  For temp := 0 to $7f do
    If (songdata.pattern_names[temp][1] = '') then
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
               ExpStrR('',14,'Í'),
               pattern_bckg+pattern_border);
end;

const
  transp_menu2: Boolean = FALSE;
  transp_pos1: Byte = 1;
  transp_pos2: Byte = 1;
  _perc_char: array[1..5] of Char = ' ¡¢£¤';

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
{$IFDEF __TMT__}
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

const
  transps: array[1..17] of String[50] = (
    ' [~1~]   1 UP   ¿',
    ' [~2~]  12 UP   ö CURRENT',
    ' [~3~]   1 DOWN ø iNSTRUMENT         ÚÄÄÄÄÄÄÄÄÄ¿',
    '',
    ' [~5~]   1 UP   ¿                    ÀÄÄÄÄÄÄÄÄÄÙ',
    ' [~6~]  12 UP   ö ALL',
    ' [~7~]   1 DOWN ø iNSTRUMENTS',
    ' [~8~]  12 DOWN Ù',
    '',
    ' [~A~]   1 UP   ¿',
    ' [~B~]  12 UP   ö CURRENT',
    ' [~C~]   1 DOWN ø iNSTRUMENT         ÚÄÄÄÄÄÄÄÄÄ¿',
    '',
    ' [~E~]   1 UP   ¿                    ÀÄÄÄÄÄÄÄÄÄÙ',
    ' [~F~]  12 UP   ö ALL',
    ' [~G~]   1 DOWN ø iNSTRUMENTS',
    ' [~H~]  12 DOWN Ù');

const
  transp2: array[1..8] of String[50] = (
    ' [~A~]   1 UP   ¿',
    ' [~B~]  12 UP   ö CURRENT',
    ' [~C~]   1 DOWN ø iNSTRUMENT         ÚÄÄÄÄÄÄÄÄÄ¿',
    '',
    ' [~E~]   1 UP   ¿                    ÀÄÄÄÄÄÄÄÄÄÙ',
    ' [~F~]  12 UP   ö ALL',
    ' [~G~]   1 DOWN ø iNSTRUMENTS',
    ' [~H~]  12 DOWN Ù');

  transp3: array[1..8] of String[50] = (
    ' [A]   1 UP   ¿',
    ' [B]  12 UP   ö CURRENT',
    ' [C]   1 DOWN ø iNSTRUMENT         ÚÄÄÄÄÄÄÄÄÄ¿',
    ' [D]  12 DOWN Ù                    ³  BLOCK  ³',
    ' [E]   1 UP   ¿                    ÀÄÄÄÄÄÄÄÄÄÙ',
    ' [F]  12 UP   ö ALL',
    ' [G]   1 DOWN ø iNSTRUMENTS',
    ' [H]  12 DOWN Ù');

const
  extensn: array[1..4] of String[50] = (
    ' [~4~]  12 DOWN Ù                    ³ PATTERN ³',
    ' [~D~]  12 DOWN Ù                    ³  SONG   ³',
    ' [~4~]  12 DOWN Ù                    ³  TRACK  ³',
    ' [~D~]  12 DOWN Ù                    ³  BLOCK  ³');

procedure transpose__control_proc;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:transpose__control_proc';
{$ENDIF}
  If (mn_environment.curr_pos in [1..8]) then
    begin
      If (mn_environment.curr_pos in [1..4]) then
        begin
          transps[2] := Copy(transps[2],1,18)+'~CURRENT~';
          transps[3] := Copy(transps[3],1,18)+'~iNSTRUMENT         ÉÍÍÍÍÍÍÍÍÍ»~';
          transps[6] := Copy(transps[6],1,18)+'ALL';
          transps[7] := Copy(transps[7],1,18)+'iNSTRUMENTS';
        end
      else begin
             transps[2] := Copy(transps[2],1,18)+'CURRENT';
             transps[3] := Copy(transps[3],1,18)+'iNSTRUMENT         ~ÉÍÍÍÍÍÍÍÍÍ»~';
             transps[6] := Copy(transps[6],1,18)+'~ALL~';
             transps[7] := Copy(transps[7],1,18)+'~iNSTRUMENTS~';
           end;

      transps[5] := Copy(transps[5],1,37)+'~ÈÍÍÍÍÍÍÍÍÍ¼~';
      If NOT transp_menu2 then
        transps[4] := Copy(transps[4],1,37)+'~º PATTERN º~'
      else transps[4] := Copy(transps[4],1,37)+'~º  TRACK  º~';
    end
  else begin
         transps[2] := Copy(transps[2],1,18)+'CURRENT';
         transps[3] := Copy(transps[3],1,18)+'iNSTRUMENT         ÚÄÄÄÄÄÄÄÄÄ¿';
         transps[6] := Copy(transps[6],1,18)+'ALL';
         transps[7] := Copy(transps[7],1,18)+'iNSTRUMENTS';

         transps[5] := Copy(transps[5],1,37)+'ÀÄÄÄÄÄÄÄÄÄÙ';
         If NOT transp_menu2 then
           transps[4] := Copy(transps[4],1,37)+'³ PATTERN ³'
         else transps[4] := Copy(transps[4],1,37)+'³  TRACK  ³';
       end;

  If (mn_environment.curr_pos in [10..17]) then
    begin
      If (mn_environment.curr_pos in [10..13]) then
        begin
          transps[11] := Copy(transps[11],1,18)+'~CURRENT~';
          transps[12] := Copy(transps[12],1,18)+'~iNSTRUMENT         ÉÍÍÍÍÍÍÍÍÍ»~';
          transps[15] := Copy(transps[15],1,18)+'ALL';
          transps[16] := Copy(transps[16],1,18)+'iNSTRUMENTS';
        end
      else begin
             transps[11] := Copy(transps[11],1,18)+'CURRENT';
             transps[12] := Copy(transps[12],1,18)+'iNSTRUMENT         ~ÉÍÍÍÍÍÍÍÍÍ»~';
             transps[15] := Copy(transps[15],1,18)+'~ALL~';
             transps[16] := Copy(transps[16],1,18)+'~iNSTRUMENTS~';
           end;

      transps[14] := Copy(transps[14],1,37)+'~ÈÍÍÍÍÍÍÍÍÍ¼~';
      If NOT transp_menu2 then
        transps[13] := Copy(transps[13],1,37)+'~º  SONG   º~'
      else transps[13] := Copy(transps[13],1,37)+'~º  BLOCK  º~';
    end
  else If NOT (transp_menu2 and NOT marking) then
         begin
           transps[11] := Copy(transps[11],1,18)+'CURRENT';
           transps[12] := Copy(transps[12],1,18)+'iNSTRUMENT         ÚÄÄÄÄÄÄÄÄÄ¿';
           transps[15] := Copy(transps[15],1,18)+'ALL';
           transps[16] := Copy(transps[16],1,18)+'iNSTRUMENTS';

           transps[14] := Copy(transps[14],1,37)+'ÀÄÄÄÄÄÄÄÄÄÙ';
           If NOT transp_menu2 then
             transps[13] := Copy(transps[13],1,37)+'³  SONG   ³'
           else transps[13] := Copy(transps[13],1,37)+'³  BLOCK  ³';
         end;

  mn_environment.do_refresh := TRUE;
  mn_environment.refresh;
end;

procedure TRANSPOSE;

var
  patt0,patt1,track0,track1,line0,line1: Byte;
  patterns: Byte;
{$IFDEF __TMT__}
  wr_loop: Byte;
{$ENDIF}
  old_text_attr: Byte;

const
  factor: array[1..17] of Byte = (1,12,1,12,1,12,1,12,BYTE_NULL,
                                  1,12,1,12,1,12,1,12);
begin
{$IFDEF __TMT__}
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
        mn_environment.context := ' TAB Ä PATTERN/SONG ';
        transps[4] := extensn[3];
        If marking then
          begin
            Move(transp2,transps[10],SizeOf(transp2));
            transps[13] := extensn[4];
          end
        else Move(transp3,transps[10],SizeOf(transp3));
      end
    else begin
           mn_environment.context := ' TAB Ä TRACK/BLOCK ';
           Move(transp2,transps[10],SizeOf(transp2));
           transps[4] := extensn[1];
           transps[13] := extensn[2];
         end;

    transpos := Menu(transps,01,01,transpos,50,17,17,' TRANSPOSE ');
    If transp_menu2 then transp_pos1 := transpos
    else transp_pos2 := transpos;

    If (mn_environment.keystroke = kTAB) then
      begin
        transp_menu2 := NOT transp_menu2;
        If transp_menu2 then transpos := transp_pos1
        else transpos := transp_pos2;
{$IFDEF __TMT__}
        For wr_loop := 1 to 5 do
          begin
            WaitRetrace;
            realtime_gfx_poll_proc;
          end;
{$ENDIF}
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
{$IFDEF __TMT__}
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
{$IFDEF __TMT__}
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
{$IFDEF __TMT__}
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

procedure override_attr(dest: tSCREEN_MEM_PTR; x,y: Byte; len: Byte; attr: Byte);
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

begin
  ShowStr(dest,x,y,frame[1]+ExpStrL('',32,frame[2])+frame[3],attr);
  ShowVStr(dest,x,y+1,ExpStrL('',MAX_PATTERN_ROWS,frame[4]),attr);
  ShowStr(dest,x,y+MAX_PATTERN_ROWS+1,frame[6]+ExpStrL('',32,frame[7])+frame[8],attr);
  override_attr(dest,x+33,y+1,MAX_PATTERN_ROWS,attr);
end;

var
  temp_instr_names: array[1..255] of String[32];

label _jmp1;

begin { REMAP }
{$IFDEF __TMT__}
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
                 dialog_background+dialog_title,double);

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
                   double,dialog_background+dialog_hi_text)
  else override_frame(centered_frame_vdest,_remap_xstart+2,_remap_ystart+2,
                      single,dialog_background+dialog_text);

  If (_remap_pos = 2) then
    override_frame(centered_frame_vdest,_remap_xstart+36,_remap_ystart+2,
                   double,dialog_background+dialog_hi_text)
  else override_frame(centered_frame_vdest,_remap_xstart+36,_remap_ystart+2,
                      single,dialog_background+dialog_text);

  _remap_refresh_proc;
  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := _remap_xstart;
  move_to_screen_area[2] := _remap_ystart;
  move_to_screen_area[3] := _remap_xstart+71+2;
  move_to_screen_area[4] := _remap_ystart+_remap_inst_page_len+5+1;
{$IFDEF __TMT__}
  toggle_waitretrace := TRUE;
{$ENDIF}
  move2screen_alt;

  centered_frame_vdest := screen_ptr;
  MenuLib1_mn_environment.v_dest := screen_ptr;
  MenuLib2_mn_environment.v_dest := screen_ptr;

  If NOT _force_program_quit then
    Repeat
      If (_remap_pos = 1) then
        begin
          override_frame(screen_ptr,_remap_xstart+2,_remap_ystart+2,
                         double,dialog_background+dialog_hi_text);
          MenuLib1_mn_setting.menu_attr := dialog_background+dialog_hi_text;
        end
      else
        begin
          override_frame(screen_ptr,_remap_xstart+2,_remap_ystart+2,
                         single,dialog_background+dialog_text);
          MenuLib1_mn_setting.menu_attr := dialog_background+dialog_text;
        end;

      If (_remap_pos = 2) then
        begin
          override_frame(screen_ptr,_remap_xstart+36,_remap_ystart+2,
                         double,dialog_background+dialog_hi_text);
          MenuLib2_mn_setting.menu_attr := dialog_background+dialog_hi_text;
        end
      else
        begin
          override_frame(screen_ptr,_remap_xstart+36,_remap_ystart+2,
                         single,dialog_background+dialog_text);
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
      // emulate_screen;
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
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_rearrange_refresh_proc';
{$ENDIF}

  If (_rearrange_pos <> 1) then attr := dialog_sel_itm_bck+dialog_sel_itm
  else attr := dialog_hi_text SHL 4;

  For idx := 1 to _rearrange_nm_tracks do
    If (idx = _rearrange_track_pos) then
      ShowCStr(centered_frame_vdest,_rearrange_xstart+1,_rearrange_ystart+idx,
               '~      '+ExpStrL(Num2str(idx,10),2,' ')+' ~'+_rearrange_tracklist[idx]+'',
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
{$IFDEF __TMT__}
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
{$IFDEF __TMT__}
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
                 dialog_background+dialog_title,double);

  ShowStr(centered_frame_vdest,_rearrange_xstart+1,_rearrange_ystart+_rearrange_nm_tracks+1,
          ExpStrL('',19,'Ä'),
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
      // emulate_screen;
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
  _on_off: array[0..1] of Char = ' û';
  _keyoff_str: array[0..2] of String[3] = ('þþþ','ÍÍÍ','^^ú');

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
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:REPLACE:refresh';
{$ENDIF}
  If (pos in [1..11]) then
    ShowStr(centered_frame_vdest,xstart+2,ystart+1,
            'NOTE,iNSTRUMENT,FX Nù1/Nù2 TO FiND',
            dialog_background+dialog_hi_text)
  else ShowStr(centered_frame_vdest,xstart+2,ystart+1,
               'NOTE,iNSTRUMENT,FX Nù1/Nù2 TO FiND',
               dialog_background+dialog_text);

  If (pos in [12..22]) then
    ShowStr(centered_frame_vdest,xstart+2,ystart+4,
            'NEW NOTE,iNSTRUMENT,FX Nù1/Nù2',
            dialog_background+dialog_hi_text)
  else ShowStr(centered_frame_vdest,xstart+2,ystart+4,
               'NEW NOTE,iNSTRUMENT,FX Nù1/Nù2',
               dialog_background+dialog_text);

  ShowCStr2(centered_frame_vdest,xstart+2,ystart+2,
            '"'+FilterStr(replace_data.event_to_find.note,'?','ú')+'" '+
            '"'+FilterStr(replace_data.event_to_find.inst,'?','ú')+'" '+
            '"'+FilterStr(replace_data.event_to_find.fx_1,'?','ú')+'" '+
            '"'+FilterStr(replace_data.event_to_find.fx_2,'?','ú')+'"',
            dialog_background+dialog_text,
            dialog_input_bckg+dialog_input);

  ShowCStr2(centered_frame_vdest,xstart+2,ystart+5,
            '"'+FilterStr(replace_data.new_event.note,'?','ú')+'" '+
            '"'+FilterStr(replace_data.new_event.inst,'?','ú')+'" '+
            '"'+FilterStr(replace_data.new_event.fx_1,'?','ú')+'" '+
            '"'+FilterStr(replace_data.new_event.fx_2,'?','ú')+'"',
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
{$IFDEF __TMT__}
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

function _find_note(layout: String): Byte;

var
  temp: Byte;

begin
  If (layout = _keyoff_str[pattern_layout]) then temp := BYTE_NULL
  else For temp := 0 to 12*8+1 do
         If SameName(note_layout[temp],layout) then BREAK;
  _find_note := temp;
end;

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
{$IFDEF __TMT__}
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
                 dialog_background+dialog_title,double);

  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+38+2;
  move_to_screen_area[4] := ystart+10+1;

  refresh;
  ShowStr(centered_frame_vdest,xstart+1,ystart+8,
          ExpStrL('',38-1,''),
          dialog_background+dialog_context_dis);

{$IFDEF __TMT__}
  toggle_waitretrace := TRUE;
{$ENDIF}
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
                               replace_data.event_to_find.note := _keyoff_str[pattern_layout];
                               pos := 4;
                             end;

                   else If (UpCase(CHAR(LO(fkey))) in _charset[pos]) or
                           (fkey = kBkSPC) or (fkey = kDELETE) then
                          begin
                            Case fkey of
                              kDELETE: chr := 'ú';
                              kBkSPC: begin
                                        chr := 'ú';
                                        If (pos > 1) then Dec(pos);
                                      end;
                              else chr := UpCase(CHAR(LO(fkey)));
                            end;

                            If (replace_data.event_to_find.note = _keyoff_str[pattern_layout]) and
                               (pos in [1,2,3]) then
                              replace_data.event_to_find.note := 'úúú';

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
                                replace_data.new_event.note := _keyoff_str[pattern_layout];
                                pos := 11+4;
                              end;

                    else If (UpCase(CHAR(LO(fkey))) in _charset[pos-11]) or
                            (fkey = kBkSPC) or (fkey = kDELETE) then
                           begin
                             Case fkey of
                               kDELETE: chr := 'ú';
                               kBkSPC: begin
                                         chr := 'ú';
                                         Dec(pos);
                                       end;
                               else chr := UpCase(CHAR(LO(fkey)));
                             end;

                             If ((replace_data.new_event.note = _keyoff_str[pattern_layout]) or
                                 (replace_data.new_event.note = #7#7#7)) and
                                (pos-11 in [1,2,3]) then
                               replace_data.new_event.note := 'úúú';

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
                       replace_data.event_to_find.note := 'úúú';
                       replace_data.event_to_find.inst := 'úú';
                       replace_data.event_to_find.fx_1 := 'úúú';
                       replace_data.event_to_find.fx_2 := 'úúú';
                     end;
                   If (pos >= 12) or shift_pressed then
                     begin
                       replace_data.new_event.note := 'úúú';
                       replace_data.new_event.inst := 'úú';
                       replace_data.new_event.fx_1 := 'úúú';
                       replace_data.new_event.fx_2 := 'úúú';
                     end;
                 end;
      end;

      If (pos in [23..26]) then replace_selection := pos-22;
      refresh;
      // emulate_screen;
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

      event_to_find.note := FilterStr(replace_data.event_to_find.note,'ú','?');
      event_to_find.inst := FilterStr(replace_data.event_to_find.inst,'ú','?');
      event_to_find.fx_1 := FilterStr(replace_data.event_to_find.fx_1,'ú','?');
      event_to_find.fx_2 := FilterStr(replace_data.event_to_find.fx_2,'ú','?');

      new_event.note := FilterStr(replace_data.new_event.note,'ú','?');
      new_event.inst := FilterStr(replace_data.new_event.inst,'ú','?');
      new_event.fx_1 := FilterStr(replace_data.new_event.fx_1,'ú','?');
      new_event.fx_2 := FilterStr(replace_data.new_event.fx_2,'ú','?');

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
                                     temp_note := _find_note(_wildcard_str(new_event.note,note_layout[old_chunk.note]));
                                     _valid_note := TRUE;
                                   end;

                      fixed_note_flag+
                      1..
                      fixed_note_flag+
                      12*8+1: If SameName(event_to_find.note,note_layout[old_chunk.note-fixed_note_flag]) then
                                begin
                                  If NOT (FilterStr(replace_data.new_event.note,'?','ú') = _keyoff_str[pattern_layout]) then
                                    temp_note := fixed_note_flag+_find_note(_wildcard_str(new_event.note,note_layout[old_chunk.note-fixed_note_flag]))
                                  else temp_note := _find_note(new_event.note);
                                  _valid_note := TRUE;
                                end;

                      BYTE_NULL: begin
                                   If NOT (SYSTEM.Pos('?',new_event.note) <> 0) then temp_note := _find_note(new_event.note)
                                   else temp_note := old_chunk.note;
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
{$IFDEF __TMT__}
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

procedure DEBUG_INFO;

const
  NOFX = '        ';

function effect_str(effect_def,effect,effect_def2: Byte): String;
begin
  Case effect_def of
    ef_Arpeggio:          If (effect <> 0) then effect_str := 'Arpeggio'
                          else effect_str := NOFX;
    ef_VolSlide:          If (effect DIV 16 <> 0) then effect_str := 'VolSld '
                          else effect_str := 'VolSld ';
    ef_VolSlideFine:      If (effect DIV 16 <> 0) then effect_str := 'VolSld '
                          else effect_str := 'VolSld ';
    ef_TPortamVolSlide:   If (effect DIV 16 <> 0) then effect_str := 'Por'+#13+'VSl'
                          else effect_str := 'Por'+#13+'VSl';
    ef_VibratoVolSlide:   If (effect DIV 16 <> 0) then effect_str := 'VibrVSl'
                          else effect_str := 'VibrVSl';
    ef_TPortamVSlideFine: If (effect DIV 16 <> 0) then effect_str := 'Por'+#13+'VSl'
                          else effect_str := 'Por'+#13+'VSl';
    ef_VibratoVSlideFine: If (effect DIV 16 <> 0) then effect_str := 'VibrVSl'
                          else effect_str := 'VibrVSl';
    ef_ArpggVSlide:       If (effect DIV 16 <> 0) then effect_str := 'ArpgVSl'
                          else effect_str := 'ArpgVSl';
    ef_ArpggVSlideFine:   If (effect DIV 16 <> 0) then effect_str := 'ArpgVSl'
                          else effect_str := 'ArpgVSl';

    ef_SetWaveform:       If NOT (effect MOD 16 in [0..7]) then
                            effect_str := 'SetW'+#26+'Car'
                          else If NOT (effect DIV 16 in [0..7]) then
                                 effect_str := 'SetW'+#26+'Mod'
                               else effect_str := 'SetWform';

    ef_FSlideUpVSlide:    If (effect DIV 16 <> 0) then effect_str := 'PorVSl'
                          else effect_str := 'PorVSl';
    ef_FSlUpVSlF:         If (effect DIV 16 <> 0) then effect_str := 'PorVSl'
                          else effect_str := 'PorVSl';
    ef_FSlideDownVSlide:  If (effect DIV 16 <> 0) then effect_str := 'PorVSl'
                          else effect_str := 'PorVSl';
    ef_FSlDownVSlF:       If (effect DIV 16 <> 0) then effect_str := 'PorVSl'
                          else effect_str := 'PorVSl';
    ef_FSlUpFineVSlide:   If (effect DIV 16 <> 0) then effect_str := 'PorVSl'
                          else effect_str := 'PorVSl';
    ef_FSlUpFineVSlF:     If (effect DIV 16 <> 0) then effect_str := 'PorVSl'
                          else effect_str := 'PorVSl';
    ef_FSlDownFineVSlide: If (effect DIV 16 <> 0) then effect_str := 'PorVSl'
                          else effect_str := 'PorVSl';
    ef_FSlDownFineVSlF:   If (effect DIV 16 <> 0) then effect_str := 'PorVSl'
                          else effect_str := 'PorVSl';

    ef_FSlideUp:          effect_str := 'Porta  ';
    ef_FSlideDown:        effect_str := 'Porta  ';
    ef_TonePortamento:    effect_str := 'Porta'+#13+'  ';
    ef_Vibrato:           effect_str := 'Vibrato ';
    ef_FSlideUpFine:      effect_str := 'Porta  ';
    ef_FSlideDownFine:    effect_str := 'Porta  ';
    ef_SetCarrierVol:     effect_str := 'SetCVol ';
    ef_SetModulatorVol:   effect_str := 'SetMVol ';
    ef_PositionJump:      effect_str := 'PosJump ';
    ef_SetInsVolume:      effect_str := 'SetVol  ';
    ef_PatternBreak:      effect_str := 'PatBreak';
    ef_SetTempo:          effect_str := 'SetTempo';
    ef_SetSpeed:          effect_str := 'SetSpeed';
    ef_RetrigNote:        effect_str := 'Retrig'+#13+' ';
    ef_MultiRetrigNote:   effect_str := 'MulRetr'+#13;
    ef_Tremolo:           effect_str := 'Tremolo ';
    ef_Tremor:            effect_str := 'Tremor  ';
    ef_SetGlobalVolume:   effect_str := 'SetGlVol';
    ef_ForceInsVolume:    effect_str := 'ForceVol';

    ef_Extended:
      Case effect DIV 16 of
        ef_ex_SetTremDepth:   effect_str := 'SetTremD';
        ef_ex_SetVibDepth:    effect_str := 'SetVibrD';
        ef_ex_SetAttckRateM:  effect_str := '[A]DSR'+#26+'M';
        ef_ex_SetDecayRateM:  effect_str := 'A[D]SR'+#26+'M';
        ef_ex_SetSustnLevelM: effect_str := 'AD[S]R'+#26+'M';
        ef_ex_SetRelRateM:    effect_str := 'ADS[R]'+#26+'M';
        ef_ex_SetAttckRateC:  effect_str := '[A]DSR'+#26+'C';
        ef_ex_SetDecayRateC:  effect_str := 'A[D]SR'+#26+'C';
        ef_ex_SetSustnLevelC: effect_str := 'AD[S]R'+#26+'C';
        ef_ex_SetRelRateC:    effect_str := 'ADS[R]'+#26+'C';
        ef_ex_SetFeedback:    effect_str := 'SetFeedb';
        ef_ex_PatternLoop:    effect_str := 'PatLoop ';
        ef_ex_PatternLoopRec: effect_str := 'PatLoopR';

        ef_ex_MacroKOffLoop:  If (effect MOD 16 <> 0) then effect_str := 'LoopOn '
                              else effect_str := 'LoopOff';

        ef_ex_SetPanningPos:
          Case effect MOD 16 of
            0: effect_str := 'SetPan'+#26+'C';
            1: effect_str := 'SetPan'+#26+'L';
            2: effect_str := 'SetPan'+#26+'R';
          end;

        ef_ex_ExtendedCmd:
          Case effect MOD 16 of
            ef_ex_cmd_RSS:        effect_str := 'RelSS   ';
            ef_ex_cmd_ResetVol:   effect_str := 'ResetVol';
            ef_ex_cmd_LockVol:    effect_str := 'VolLock+';
            ef_ex_cmd_UnlockVol:  effect_str := 'VolLock-';
            ef_ex_cmd_LockVP:     effect_str := 'LockVP+ ';
            ef_ex_cmd_UnlockVP:   effect_str := 'LockVP- ';
            ef_ex_cmd_VSlide_car: effect_str := 'VSld'+#26+'Car';
            ef_ex_cmd_VSlide_mod: effect_str := 'VSld'+#26+'Mod';
            ef_ex_cmd_VSlide_def: effect_str := 'VSld'+#26+'Def';
            ef_ex_cmd_LockPan:    effect_str := 'PanLock+';
            ef_ex_cmd_UnlockPan:  effect_str := 'PanLock-';
            ef_ex_cmd_VibrOff:    effect_str := 'VibrOff ';
            ef_ex_cmd_TremOff:    effect_str := 'TremOff ';
            ef_ex_cmd_FVib_FGFS:  If NOT (effect_def2 in [ef_GlobalFSlideUp,ef_GlobalFSlideDown]) then
                                    effect_str := 'VibrFine'
                                  else effect_str := 'GlPortaF';
            ef_ex_cmd_FTrm_XFGFS: If NOT (effect_def2 in [ef_GlobalFSlideUp,ef_GlobalFSlideDown]) then
                                    effect_str := 'TremFine'
                                  else effect_str := 'GlPortXF';
            ef_ex_cmd_NoRestart:  effect_str := 'ArpVibNR';
            else                  effect_str := NOFX;
          end;
        else effect_str := NOFX;
      end;

    ef_Extended2:
      Case effect DIV 16 of
        ef_ex2_PatDelayFrame: effect_str := 'PatDelF ';
        ef_ex2_PatDelayRow:   effect_str := 'PatDelR ';
        ef_ex2_NoteDelay:     effect_str := 'Delay'+#13+'  ';
        ef_ex2_NoteCut:       effect_str := 'Cut'+#13+'    ';
        ef_ex2_GlVolSlideUp:  effect_str := 'GlVolSl';
        ef_ex2_GlVolSlideDn:  effect_str := 'GlVolSl';
        ef_ex2_GlVolSlideUpF: effect_str := 'GlVolSl';
        ef_ex2_GlVolSlideDnF: effect_str := 'GlVolSl';
        ef_ex2_FineTuneUp:    effect_str := 'FTune  ';
        ef_ex2_FineTuneDown:  effect_str := 'FTune  ';
        ef_ex2_GlVolSldUpXF:  effect_str := 'GVolSl';
        ef_ex2_GlVolSldDnXF:  effect_str := 'GVolSl';
        ef_ex2_VolSlideUpXF:  effect_str := 'VolSld';
        ef_ex2_VolSlideDnXF:  effect_str := 'VolSld';
        ef_ex2_FreqSlideUpXF: effect_str := 'Porta ';
        ef_ex2_FreqSlideDnXF: effect_str := 'Porta ';
      end;

    ef_SwapArpeggio: effect_str := 'ArpT'+#26+byte2hex(effect)+' ';
    ef_SwapVibrato:  effect_str := 'VibT'+#26+byte2hex(effect)+' ';

    ef_Extended3:
      Case effect DIV 16 of
        ef_ex3_SetConnection: If (effect MOD 16 = 0) then effect_str := 'Conct'+#26+'FM'
                              else effect_str := 'Conct'+#26+'AM';
        ef_ex3_SetMultipM:    effect_str := 'Multip'+#26+'M';
        ef_ex3_SetKslM:       effect_str := 'KSL'+#26+'M   ';
        ef_ex3_SetTremoloM:   effect_str := 'Trem'+#26+'M  ';
        ef_ex3_SetVibratoM:   effect_str := 'Vibr'+#26+'M  ';
        ef_ex3_SetKsrM:       effect_str := 'KSR'+#26+'M   ';
        ef_ex3_SetSustainM:   effect_str := 'Sustn'+#26+'M ';
        ef_ex3_SetMultipC:    effect_str := 'Multip'+#26+'C';
        ef_ex3_SetKslC:       effect_str := 'KSL'+#26+'C   ';
        ef_ex3_SetTremoloC:   effect_str := 'Trem'+#26+'C  ';
        ef_ex3_SetVibratoC:   effect_str := 'Vibr'+#26+'C  ';
        ef_ex3_SetKsrC:       effect_str := 'KSR'+#26+'C   ';
        ef_ex3_SetSustainC:   effect_str := 'Sustn'+#26+'C ';
      end;

    ef_ExtraFineArpeggio: effect_str := 'Arpggio';
    ef_ExtraFineVibrato:  effect_str := 'Vibrato';
    ef_ExtraFineTremolo:  effect_str := 'Tremolo';
    ef_SetCustomSpeedTab: effect_str := 'SetCusST';
    ef_GlobalFSlideUp:    effect_str := 'GlPorta';
    ef_GlobalFSlideDown:  effect_str := 'GlPorta';

    else effect_str := NOFX;
  end;
end;

function note_str(note,chan: Byte): String;
begin
  If (note < 100) then note_str := note_layout[note]+' '
  else If (note AND $7f <> 0) then note_str := note_layout[note AND $7f]+''
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
  else If (value > 0) then _freq_slide_str := ''
       else _freq_slide_str := '';
end;

const
  IDLE = $0fff;
  FINISHED = $0ffff;
  _retrig_note_str: array[Boolean] of String = ('`'#13'`',#13);
  _keyoff_str: array[Boolean] of String = ('`'#14'`',#14);

function _macro_pos_str_fm(pos,len: Word; keyoff_pos,duration: Byte;
                           retrig_note: Boolean; freq_slide: Smallint): String;
begin
  If (pos <= 255) then
    _macro_pos_str_fm := byte2hex(pos)+'/'+byte2hex(len)+':'+byte2hex(duration)+' '+_retrig_note_str[retrig_note]+
                         _freq_slide_str(freq_slide)+_keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)]+'`'#251'`'
  else If (pos = IDLE) then
         _macro_pos_str_fm := 'úúúú:úú     '
       else _macro_pos_str_fm := byte2hex(len)+'/'+byte2hex(len)+':'+byte2hex(duration)+' '+_retrig_note_str[retrig_note]+
                         _freq_slide_str(freq_slide)+_keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)]+#251;
end;

function _macro_pos_str_av(pos,len: Word; keyoff_pos: Byte; slide_str: String): String;
begin
  If (pos <= 255) then
    _macro_pos_str_av := byte2hex(pos)+'/'+byte2hex(len)+' '+slide_str+
                         _keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)]
  else If (pos = IDLE) then
         _macro_pos_str_av := 'úúúú '+slide_str+
                              _keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)]
       else _macro_pos_str_av := byte2hex(len)+'/'+byte2hex(len)+' '+slide_str+
                                 _keyoff_str[(pos >= keyoff_pos) and (keyoff_pos > 0)];
end;

const
  _perc_char: array[1..5] of Char = ' ¡¢£¤';
  _panning: array[0..3] of String = ('','``','``','``');
  _connection: array[0..1] of String = ('FM','AM');
  _off_on: array[1..4,0..1] of Char = ('úT','úV','úK','úS');
  _win_title: array[Boolean] of String = (' DEBUG iNFO ','');
  _contxt_str: String = ' LSHiFT/RSHiFT Ä TOGGLE DETAiLS ';

var
  temp,temp2,atr1,atr2,atr3,atr4,xstart,ystart: Byte;
  temps,temps2: String;
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
{$IFDEF __TMT__}
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
  HideCursor;
  centered_frame(xstart,ystart,83,songdata.nm_tracks+6,
                 _win_title[_ctrl_alt_flag],_win_attr[_ctrl_alt_flag],
                 debug_info_bckg+debug_info_title,double);

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
                 '     TRACK     ~³~          iNSTRUMENT          ~³~NOTE~³ ~FX Nù1~ ³ ~FX Nù2~ ³~FREQ~³ ~VOL',
                 debug_info_bckg+debug_info_topic,debug_info_bckg+debug_info_border);
        ShowStr(screen_ptr,xstart+2,ystart+2,
                'ÄÄÂÄÄÂÄÄÄÂÄÄÂÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÂÄÄ',
                debug_info_bckg+debug_info_border);
        ShowStr(screen_ptr,xstart+2,ystart+songdata.nm_tracks+3,
                'ÄÄÁÄÄÁÄÄÄÁÄÄÁÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÁÄÄ',
                debug_info_bckg+debug_info_border);
        If NOT _ctrl_alt_flag then
          ShowCStr(screen_ptr,xstart+76,ystart+songdata.nm_tracks+6,' [~1/3~] ',
                   _win_attr[_ctrl_alt_flag],
                   debug_info_bckg+debug_info_topic);
      end
    else If NOT _macro_details_flag then
           begin
             ShowCStr(screen_ptr,xstart+2,ystart+1,
                      'TRACK~³~iNS~³~NOTE~³ ~FX Nù1~ ³ ~FX Nù2~ ³~FREQ~³~CN/FB/ADSR/WF/KSL/MUL/TRM/ViB/KSR/EG~³ ~VOL',
                      debug_info_bckg+debug_info_topic,debug_info_bckg+debug_info_border);
             ShowStr(screen_ptr,xstart+2,ystart+2,
                     'ÄÄÂÄÄÅÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÂÄÄ',
                     debug_info_bckg+debug_info_border);
             ShowStr(screen_ptr,xstart+2,ystart+songdata.nm_tracks+3,
                     'ÄÄÁÄÄÁÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÁÄÄ',
                     debug_info_bckg+debug_info_border);
             If NOT _ctrl_alt_flag then
               ShowCStr(screen_ptr,xstart+76,ystart+songdata.nm_tracks+6,' [~2/3~] ',
                        _win_attr[_ctrl_alt_flag],
                        debug_info_bckg+debug_info_topic);
           end
         else begin
                ShowCStr(screen_ptr,xstart+2,ystart+1,
                         'TRACK~³~iNS~³~NOTE~³ ~FX Nù1~ ³ ~FX Nù2~ ³~MACRO FM-REG~ ³~MACRO ARPG~³~MACRO ViBR ~³~FREQ~³ ~VOL',
                         debug_info_bckg+debug_info_topic,debug_info_bckg+debug_info_border);
                ShowStr(screen_ptr,xstart+2,ystart+2,
                        'ÄÄÂÄÄÅÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÂÄÄ',
                        debug_info_bckg+debug_info_border);
                ShowStr(screen_ptr,xstart+2,ystart+songdata.nm_tracks+3,
                        'ÄÄÁÄÄÁÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÁÄÄ',
                        debug_info_bckg+debug_info_border);
                If NOT _ctrl_alt_flag then
                  ShowCStr(screen_ptr,xstart+76,ystart+songdata.nm_tracks+6,' [~3/3~] ',
                           _win_attr[_ctrl_alt_flag],
                           debug_info_bckg+debug_info_topic);
              end;

    If NOT play_single_patt and NOT replay_forbidden and
       repeat_pattern then temps := '~~'
    else temps := '';

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
      If (tempo = 18) and timer_fix then temps := num2str(tempo,10)+#5+#3
      else temps := num2str(tempo,10)+#3
    else temps := num2str(tempo,10)+#3;

    If (_macro_speedup = 1) then temps2 := temps
    else begin
           temp := calc_max_speedup(tempo);
           If (_macro_speedup <= temp) then
             temps2 := Num2str(tempo*_macro_speedup,10)+#3
           else temps2 := Num2str(tempo*temp,10)+#3;
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
               1:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then temps := '¬'
                   else temps := ' ';
               2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then temps := '­'
                   else temps := ' ';
               3:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then temps := '¬'
                   else temps := ' ';
               4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then temps := '­'
                   else temps := ' ';
               5:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then temps := '¬'
                   else temps := ' ';
               6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then temps := '­'
                   else temps := ' ';
               10: If (songdata.flag_4op OR 8 = songdata.flag_4op) then temps := '¬'
                   else temps := ' ';
               11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then temps := '­'
                   else temps := ' ';
               12: If (songdata.flag_4op OR $10 = songdata.flag_4op) then temps := '¬'
                   else temps := ' ';
               13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then temps := '­'
                   else temps := ' ';
               14: If (songdata.flag_4op OR $20 = songdata.flag_4op) then temps := '¬'
                   else temps := ' ';
               15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then temps := '­'
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
              Insert('~÷~',temps,7);
            end
          else temps := ExpStrR('      ~÷~',30+2,' ')
        else If (event_table[temp].instr_def in [1..255]) then temps := 'i'+byte2hex(event_table[temp].instr_def)
             else temps := ExpStrR('',3,' ');

        If (play_status = isStopped) and NOT debugging then temp2 := 3
        else temp2 := panning_table[temp];

        Case (songdata.lock_flags[temp] SHR 2 AND 3) of
          0: temps2 := 'ú';
          1: temps2 := 'C';
          2: temps2 := 'M';
          3: temps2 := '&';
        end;

        If (songdata.lock_flags[temp] SHR 2 AND 3 = 0) or
           ((play_status = isStopped) and NOT debugging) then
          temps2 := '`'+temps2+'`';

        If lockvol and (songdata.lock_flags[temp] OR $10 = songdata.lock_flags[temp]) then
          temps2 := temps2+'~³~V+'
        else temps2 := temps2+'~³~`V+`';

        If lockVP and (songdata.lock_flags[temp] OR $20 = songdata.lock_flags[temp]) then
          temps2 := temps2+'~³~P+'
        else temps2 := temps2+'~³~`P+`';

        If NOT _details_flag then
          begin
            If pan_lock[temp] then
              ShowC3Str(screen_ptr,xstart+4,ystart+temp+2,
                        '~³~'+_panning[temp2]+'~³~',
                        atr2,
                        bckg_attr+debug_info_border,
                        bckg_attr+debug_info_txt_hid)
            else ShowC3Str(screen_ptr,xstart+4,ystart+temp+2,
                           '~³~'+_panning[temp2]+'~³~',
                           atr3,
                           bckg_attr+debug_info_border,
                           bckg_attr+debug_info_txt_hid);

            ShowC3Str(screen_ptr,xstart+8,ystart+temp+2,
                      temps2+'~³~',
                      atr2,
                      bckg_attr+debug_info_border,
                      bckg_attr+debug_info_txt_hid);

            If NOT (is_4op_chan(temp) and
                   (temp in [1,3,5,10,12,14])) then
              ShowCStr(screen_ptr,xstart+18,ystart+temp+2,
                       temps+'~³~'+
                       note_str(event_table[temp].note,temp)+'~³~'+
                       effect_str(event_table[temp].effect_def,
                                  event_table[temp].effect,
                                  event_table[temp].effect_def2)+'~³~'+
                       effect_str(event_table[temp].effect_def2,
                                  event_table[temp].effect2,
                                  event_table[temp].effect_def)+'~³~'+
                       ExpStrL(Num2str(freqtable2[temp] AND $1fff,16),4,'0')+'~³~',
                       atr1,
                       bckg_attr+debug_info_border)
            else
              ShowCStr(screen_ptr,xstart+18,ystart+temp+2,
                       temps+'~³~    ~³~'+
                       effect_str(event_table[temp].effect_def,
                                  event_table[temp].effect,
                                  event_table[temp].effect_def2)+'~³~'+
                       effect_str(event_table[temp].effect_def2,
                                  event_table[temp].effect2,
                                  event_table[temp].effect_def)+'~³~    ~³~',
                       atr1,
                       bckg_attr+debug_info_border);

            If NOT (percussion_mode and (temp in [17..20])) then
              ShowCStr(screen_ptr,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~³~',
                       atr3,
                       bckg_attr+debug_info_border)
            else
              ShowCStr(screen_ptr,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~³~',
                       bckg_attr+bckg_attr SHR 4,
                       bckg_attr+debug_info_border);
          end
        else
          begin
            If pan_lock[temp] then
              ShowC3Str(screen_ptr,xstart+4,ystart+temp+2,
                        '~³~'+_panning[temp2]+'~³~',
                        atr2,
                        bckg_attr+debug_info_border,
                        bckg_attr+debug_info_txt_hid)
            else ShowC3Str(screen_ptr,xstart+4,ystart+temp+2,
                           '~³~'+_panning[temp2]+'~³~',
                           atr3,
                           bckg_attr+debug_info_border,
                           bckg_attr+debug_info_txt_hid);

            If NOT _macro_details_flag then
              begin
                If NOT (is_4op_chan(temp) and
                       (temp in [1,3,5,10,12,14])) then
                  ShowCStr(screen_ptr,xstart+8,ystart+temp+2,
                           temps+'~³~'+
                           note_str(event_table[temp].note,temp)+'~³~'+
                           effect_str(event_table[temp].effect_def,
                                      event_table[temp].effect,
                                      event_table[temp].effect_def2)+'~³~'+
                           effect_str(event_table[temp].effect_def2,
                                      event_table[temp].effect2,
                                      event_table[temp].effect_def)+'~³~'+
                           ExpStrL(Num2str(freqtable2[temp] AND $1fff,16),4,'0')+'~³~',
                           atr1,bckg_attr+debug_info_border)
                else
                  ShowCStr(screen_ptr,xstart+8,ystart+temp+2,
                           temps+'~³~    ~³~'+
                           effect_str(event_table[temp].effect_def,
                                      event_table[temp].effect,
                                      event_table[temp].effect_def2)+'~³~'+
                           effect_str(event_table[temp].effect_def2,
                                      event_table[temp].effect2,
                                      event_table[temp].effect_def)+'~³~'+
                           '    ~³~',
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
                           _off_on[4,fmpar_table[temp].sustC]+'~³~',
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
                           _off_on[4,fmpar_table[temp].sustC]+'~³~',
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
                         _off_on[4,fmpar_table[temp].sustM]+'~³~',
                         atr4,
                         bckg_attr+debug_info_border);
              end
            else
              begin
                If NOT (is_4op_chan(temp) and
                       (temp in [1,3,5,10,12,14])) then
                  ShowCStr(screen_ptr,xstart+8,ystart+temp+2,
                           temps+'~³~'+
                           note_str(event_table[temp].note,temp)+'~³~'+
                           effect_str(event_table[temp].effect_def,
                                      event_table[temp].effect,
                                      event_table[temp].effect_def2)+'~³~'+
                           effect_str(event_table[temp].effect_def2,
                                      event_table[temp].effect2,
                                      event_table[temp].effect_def)+'~³~',
                           atr1,bckg_attr+debug_info_border)
                else
                  ShowCStr(screen_ptr,xstart+8,ystart+temp+2,
                           temps+'~³~    ~³~'+
                           effect_str(event_table[temp].effect_def,
                                      event_table[temp].effect,
                                      event_table[temp].effect_def2)+'~³~'+
                           effect_str(event_table[temp].effect_def2,
                                      event_table[temp].effect2,
                                      event_table[temp].effect_def)+'~³~',
                           atr1,bckg_attr+debug_info_border);

                If NOT (is_4op_chan(temp) and
                       (temp in [1,3,5,10,12,14])) then
                  ShowC3Str(screen_ptr,xstart+35,ystart+temp+2,
                            _macro_str(_macro_pos_str_fm(macro_table[temp].fmreg_pos,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].length,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].keyoff_pos,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].duration,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].fm_data.FEEDBACK_FM OR $80 =
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].fm_data.FEEDBACK_FM,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].freq_slide),
                                       songdata.instr_macros[macro_table[temp].fmreg_table].length)+'~³~'+
                            _macro_str(byte2hex(macro_table[temp].arpg_table)+#246+
                                       _macro_pos_str_av(macro_table[temp].arpg_pos,
                                                         songdata.macro_table[macro_table[temp].arpg_table].arpeggio.length,
                                                         songdata.macro_table[macro_table[temp].arpg_table].arpeggio.keyoff_pos,
                                                         ''),
                                       macro_table[temp].arpg_table)+'~³~'+
                            _macro_str(byte2hex(macro_table[temp].vib_table)+#246+
                                       _macro_pos_str_av(macro_table[temp].vib_pos,
                                                         songdata.macro_table[macro_table[temp].vib_table].vibrato.length,
                                                         songdata.macro_table[macro_table[temp].vib_table].vibrato.keyoff_pos,
                                                         _freq_slide_str(songdata.macro_table[macro_table[temp].vib_table].vibrato.data[macro_table[temp].vib_pos])),
                                       macro_table[temp].vib_table)+'~³~'+
                            ExpStrL(Num2str(freqtable2[temp] AND $1fff,16),4,'0')+'~³~',
                            atr1,
                            bckg_attr+debug_info_border,
                            bckg_attr+debug_info_txt_hid)
                else
                  ShowC3Str(screen_ptr,xstart+35,ystart+temp+2,
                            _macro_str(_macro_pos_str_fm(macro_table[temp].fmreg_pos,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].length,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].keyoff_pos,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].duration,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].fm_data.FEEDBACK_FM OR $80 =
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].fm_data.FEEDBACK_FM,
                                                         songdata.instr_macros[macro_table[temp].fmreg_table].data[macro_table[temp].fmreg_pos].freq_slide),
                                       songdata.instr_macros[macro_table[temp].fmreg_table].length)+'~³~'+
                            _macro_str(byte2hex(macro_table[temp].arpg_table)+#246+
                                       _macro_pos_str_av(macro_table[temp].arpg_pos,
                                                         songdata.macro_table[macro_table[temp].arpg_table].arpeggio.length,
                                                         songdata.macro_table[macro_table[temp].arpg_table].arpeggio.keyoff_pos,
                                                         ''),
                                       macro_table[temp].arpg_table)+'~³~'+
                            _macro_str(byte2hex(macro_table[temp].vib_table)+#246+
                                       _macro_pos_str_av(macro_table[temp].vib_pos,
                                                         songdata.macro_table[macro_table[temp].vib_table].vibrato.length,
                                                         songdata.macro_table[macro_table[temp].vib_table].vibrato.keyoff_pos,
                                                         _freq_slide_str(songdata.macro_table[macro_table[temp].vib_table].vibrato.data[macro_table[temp].vib_pos])),
                                       macro_table[temp].vib_table)+'~³~'+
                            '    ~³~',
                            atr1,
                            bckg_attr+debug_info_border,
                            bckg_attr+debug_info_txt_hid);
              end;

            If NOT (percussion_mode and (temp in [17..20])) then
              ShowCStr(screen_ptr,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~³~',
                       atr3,
                       bckg_attr+debug_info_border)
            else
              ShowCStr(screen_ptr,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~³~',
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
{$IFDEF __TMT__}
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
{$IFDEF __TMT__}
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
{$IFNDEF __TMT__}
               If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
{$ENDIF}
                 For temp := 1 to songdata.nm_tracks do
                   begin
                     channel_flag[temp] := NOT channel_flag[temp];
                     If NOT channel_flag[temp] then reset_chan_data(temp);
                   end;
      kAltS:
{$IFNDEF __TMT__}
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
                           If (temp in [1,3,5,10,12,14]) then channel_flag[SUCC(temp)] := TRUE
                           else channel_flag[PRED(temp)] := TRUE;
                       end;
                   For temp := 1 to songdata.nm_tracks do
                     If NOT channel_flag[temp] then reset_chan_data(temp);
                 end;

      kAltR:
{$IFNDEF __TMT__}
               If NOT (opl3_channel_recording_mode and (play_status <> isStopped)) then
{$ENDIF}
                 FillChar(channel_flag,songdata.nm_tracks,BYTE(TRUE));
      kAlt1..
      kAlt9:
{$IFNDEF __TMT__}
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
                         If (temp in [1,3,5,10,12,14]) then
                           begin
                             channel_flag[SUCC(temp)] := channel_flag[temp];
                             If NOT channel_flag[SUCC(temp)] then reset_chan_data(SUCC(temp));
                           end
                         else If (temp in [2,4,6,11,13,15]) then
                                begin
                                  channel_flag[PRED(temp)] := channel_flag[temp];
                                  If NOT channel_flag[PRED(temp)] then reset_chan_data(PRED(temp));
                                end;
                     end;
                 end;
      kAlt0:
{$IFNDEF __TMT__}
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
{$IFDEF __TMT__}
    realtime_gfx_poll_proc;
    keyboard_reset_buffer_alt;
{$ELSE}
    emulate_screen;
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
      emulate_screen;
      keyboard_reset_buffer;
      no_step_debugging := FALSE;
      IF NOT _force_program_quit then GOTO _jmp1;
    end;

  If (fkey = kAlt0) then
{$IFNDEF __TMT__}
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

        emulate_screen;
        keyboard_reset_buffer;
        no_step_debugging := FALSE;
        If NOT _force_program_quit then GOTO _jmp1;
      end;
end;

procedure LINE_MARKING_SETUP;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:LINE_MARKING_SETUP';
{$ENDIF}
  dl_setting.all_enabled := TRUE;
  mark_line := Dialog('USE CURSOR KEYS OR DiRECTLY PRESS ~HOTKEY~ TO SETUP COUNTER$',
                      '~1~$~2~$~3~$~4~$~5~$~6~$~7~$~8~$~9~$10$11$12$13$14$15$16$',
                      ' LiNE MARKiNG SETUP ',mark_line);
  dl_setting.all_enabled := FALSE;
end;

procedure OCTAVE_CONTROL;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:OCTAVE_CONTROL';
{$ENDIF}
  current_octave := Dialog('USE CURSOR KEYS OR DiRECTLY PRESS HOTKEY '+
                           'TO CHANGE OCTAVE$',
                           '~1~$~2~$~3~$~4~$~5~$~6~$~7~$~8~$',
                           ' OCTAVE CONTROL ',current_octave);
end;

procedure SONG_VARIABLES;

const
  new_keys: array[1..7] of Word = (kF1,kESC,kENTER,kTAB,kShTAB,kUP,kDOWN);

var
  old_keys: array[1..7] of Word;
  pos,temp,temp1,temp2,temp3: Byte;
  temps: String;
  xstart,ystart: Byte;
  attr: array[1..163] of Byte;
  status_backup: Record
                   replay_forbidden: Boolean;
                   play_status: tPLAY_STATUS;
                 end;
const
  _on_off: array[0..1] of Char = 'úû';
  _4op_str: array[1..6] of String = ('1 ñ2','3 ñ4','5 ñ6','10ñ11','12ñ13','14ñ15');
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

  _up_pos_pan: array[1..60] of Byte = (2, 2, 2,   {1}
                                       18,19,20,  {2}
                                       21,22,23,  {3}
                                       24,25,26,  {4}
                                       27,28,29,  {5}
                                       30,31,32,  {6}
                                       33,34,35,  {7}
                                       36,37,38,  {8}
                                       39,40,41,  {9}
                                       42,43,44,  {10}
                                       45,46,47,  {11}
                                       48,49,50,  {12}
                                       51,52,53,  {13}
                                       54,55,56,  {14}
                                       57,58,59,  {15}
                                       60,61,62,  {16}
                                       63,64,65,  {17}
                                       66,67,68,  {18}
                                       69,70,71,  {19}
                                       72,73,74); {20}

  _down_pos_pan: array[1..60] of Byte = (0,0,0,  {1}
                                         0,0,0,  {2}
                                         0,0,0,  {3}
                                         0,0,0,  {4}
                                         0,0,0,  {5}
                                         0,0,0,  {6}
                                         0,0,0,  {7}
                                         0,0,0,  {8}
                                         0,0,0,  {9}
                                         0,0,0,  {10}
                                         0,0,0,  {11}
                                         0,0,0,  {12}
                                         0,0,0,  {13}
                                         0,0,0,  {14}
                                         0,0,0,  {15}
                                         0,0,0,  {16}
                                         0,0,0,  {17}
                                         0,0,0,  {18}
                                         0,0,0,  {19}
                                         1,1,1); {20}

  _down_pos_lck: array[1..80] of Byte = (0,0,0,0,  {1}
                                         0,0,0,0,  {2}
                                         0,0,0,0,  {3}
                                         0,0,0,0,  {4}
                                         0,0,0,0,  {5}
                                         0,0,0,0,  {6}
                                         0,0,0,0,  {7}
                                         0,0,0,0,  {8}
                                         0,0,0,0,  {9}
                                         0,0,0,0,  {10}
                                         0,0,0,0,  {11}
                                         0,0,0,0,  {12}
                                         0,0,0,0,  {13}
                                         0,0,0,0,  {14}
                                         0,0,0,0,  {15}
                                         0,0,0,0,  {16}
                                         0,0,0,0,  {17}
                                         0,0,0,0,  {18}
                                         0,0,0,0,  {19}
                                         1,1,1,1); {20}

  _up_pos_lck: array[1..80] of Byte = (2,  2,  2,  2,    {1}
                                       84, 85, 86, 87,   {2}
                                       88, 89, 90, 91,   {3}
                                       92, 93, 94, 95,   {4}
                                       96, 97, 98, 99,   {5}
                                       100,101,102,103,  {6}
                                       104,105,106,107,  {7}
                                       108,109,110,111,  {8}
                                       112,113,114,115,  {9}
                                       116,117,118,119,  {10}
                                       120,121,122,123,  {11}
                                       124,125,126,127,  {12}
                                       128,129,130,131,  {13}
                                       132,133,134,135,  {14}
                                       136,137,138,139,  {15}
                                       140,141,142,143,  {16}
                                       144,145,146,147,  {17}
                                       148,149,150,151,  {18}
                                       152,153,154,155,  {19}
                                       156,157,158,159); {20}

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

  _down_pos_pan_def: array[1..20-1] of Record
                                         variant1,
                                         variant2: array[1..3] of Byte;
                                       end = (

    (variant1: (21,22,23); variant2: (3, 3, 3 )),  {1}
    (variant1: (24,25,26); variant2: (3, 3, 3 )),  {2}
    (variant1: (27,28,29); variant2: (3, 3, 3 )),  {3}
    (variant1: (30,31,32); variant2: (4, 4, 4 )),  {4}
    (variant1: (33,34,35); variant2: (17,17,17)),  {5}
    (variant1: (36,37,38); variant2: (6, 6, 6 )),  {6}
    (variant1: (39,40,41); variant2: (6, 6, 6 )),  {7}
    (variant1: (42,43,44); variant2: (7, 7, 7 )),  {8}
    (variant1: (45,46,47); variant2: (8, 8, 8 )),  {9}
    (variant1: (48,49,50); variant2: (81,81,81)),  {10}
    (variant1: (51,52,53); variant2: (82,82,82)),  {11}
    (variant1: (54,55,56); variant2: (9, 9, 9 )),  {12}
    (variant1: (57,58,59); variant2: (10,10,10)),  {13}
    (variant1: (60,61,62); variant2: (13,13,13)),  {14}
    (variant1: (63,64,65); variant2: (13,13,13)),  {15}
    (variant1: (66,67,68); variant2: (14,14,14)),  {16}
    (variant1: (69,70,71); variant2: (15,15,15)),  {17}
    (variant1: (72,73,74); variant2: (15,15,15)),  {18}
    (variant1: (75,76,77); variant2: (16,16,16))); {19}

  _down_pos_lck_def: array[1..20-1] of Record
                                         variant1,
                                         variant2: array[1..4] of Byte;
                                       end = (

    (variant1: (88, 89, 90, 91);  variant2: (3, 3, 3, 3 )),  {1}
    (variant1: (92, 93, 94, 95);  variant2: (3, 3, 3, 3 )),  {2}
    (variant1: (96, 97, 98, 99);  variant2: (3, 3, 3, 3 )),  {3}
    (variant1: (100,101,102,103); variant2: (4, 4, 4, 4 )),  {4}
    (variant1: (104,105,106,107); variant2: (17,17,17,17)),  {5}
    (variant1: (108,109,110,111); variant2: (6, 6, 6, 6 )),  {6}
    (variant1: (112,113,114,115); variant2: (6, 6, 6, 6 )),  {7}
    (variant1: (116,117,118,119); variant2: (7, 7, 7, 7 )),  {8}
    (variant1: (120,121,122,123); variant2: (8, 8, 8, 8 )),  {9}
    (variant1: (124,125,126,127); variant2: (81,81,81,81)),  {10}
    (variant1: (128,129,130,131); variant2: (82,82,82,82)),  {11}
    (variant1: (132,133,134,135); variant2: (9, 9, 9, 9 )),  {12}
    (variant1: (136,137,138,139); variant2: (10,10,10,10)),  {13}
    (variant1: (140,141,142,143); variant2: (13,13,13,13)),  {14}
    (variant1: (144,145,146,147); variant2: (13,13,13,13)),  {15}
    (variant1: (148,149,150,151); variant2: (14,14,14,14)),  {16}
    (variant1: (152,153,154,155); variant2: (15,15,15,15)),  {17}
    (variant1: (156,157,158,159); variant2: (15,15,15,15)),  {18}
    (variant1: (160,161,152,163); variant2: (16,16,16,16))); {19}

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

function truncate_string(str: String): String;
begin
  While (Length(str) > 0) and (str[Length(str)] in [#0,#32,#255]) do
    Delete(str,Length(str),1);
  truncate_string := str;
end;

label _jmp1,_end;

begin { SONG_VARIABLES }
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:SONG_VARIABLES';
{$ENDIF}
  songdata_crc := Update32(songdata,SizeOf(songdata),0);
  count_order(temp1);
  count_patterns(temp2);
  count_instruments(temp3);
  pos := min(get_bank_position('?song_variables_window?pos',-1),1);
  If (calc_max_speedup(songdata.tempo) < songdata.macro_speedup) then
    songdata.macro_speedup := calc_max_speedup(songdata.tempo);

_jmp1:
  If _force_program_quit then EXIT;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  HideCursor;

  ScreenMemCopy(screen_ptr,ptr_temp_screen);
  centered_frame_vdest := ptr_temp_screen;
  centered_frame(xstart,ystart,79,26,' SONG VARiABLES ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 double);
  centered_frame_vdest := screen_ptr;

  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+79+2;
  move_to_screen_area[4] := ystart+26+1;
{$IFDEF __TMT__}
  toggle_waitretrace := TRUE;
{$ENDIF}
  move2screen_alt;

  move_to_screen_area[1] := xstart+1;
  move_to_screen_area[2] := ystart+1;
  move_to_screen_area[3] := xstart+78;
  move_to_screen_area[4] := ystart+25;

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
           'iNiTiAL LOCK SETTiNGS',dialog_background+dialog_context_dis);
  ShowStr(ptr_temp_screen,xstart+51,ystart+3,
           'ššššššššššššššššššššššššššš',dialog_background+dialog_context_dis);

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

      For temp := 1 to 19 do
        If (songdata.nm_tracks < temp+1) then
          begin
            _down_pos_pan[(temp-1)*3+1] := _down_pos_pan_def[temp].variant2[1];
            _down_pos_pan[(temp-1)*3+2] := _down_pos_pan_def[temp].variant2[2];
            _down_pos_pan[(temp-1)*3+3] := _down_pos_pan_def[temp].variant2[3];
            _down_pos_lck[(temp-1)*4+1] := _down_pos_lck_def[temp].variant2[1];
            _down_pos_lck[(temp-1)*4+2] := _down_pos_lck_def[temp].variant2[2];
            _down_pos_lck[(temp-1)*4+3] := _down_pos_lck_def[temp].variant2[3];
            _down_pos_lck[(temp-1)*4+4] := _down_pos_lck_def[temp].variant2[4];
          end
        else begin
               _down_pos_pan[(temp-1)*3+1] := _down_pos_pan_def[temp].variant1[1];
               _down_pos_pan[(temp-1)*3+2] := _down_pos_pan_def[temp].variant1[2];
               _down_pos_pan[(temp-1)*3+3] := _down_pos_pan_def[temp].variant1[3];
               _down_pos_lck[(temp-1)*4+1] := _down_pos_lck_def[temp].variant1[1];
               _down_pos_lck[(temp-1)*4+2] := _down_pos_lck_def[temp].variant1[2];
               _down_pos_lck[(temp-1)*4+3] := _down_pos_lck_def[temp].variant1[3];
               _down_pos_lck[(temp-1)*4+4] := _down_pos_lck_def[temp].variant1[4];
             end;

      For temp2 := 1 to 17 do
        If (pos = temp2) then attr[temp2] := dialog_background+dialog_hi_text
        else attr[temp2] := dialog_background+dialog_text;

      If (pos = 4) then attr[5] := 0
      else If (pos = 5) then attr[4] := 0
           else attr[5] := 0;

      If (pos = 9) then attr[10] := 0
      else If (pos = 10) then attr[9] := 0
           else attr[10] := 0;

      If (pos = 11) then attr[12] := 0
      else If (pos = 12) then attr[11] := 0
           else attr[11] := 0;

      If (pos in [18..77]) then attr[18] := dialog_background+dialog_hi_text
      else attr[18] := dialog_background+dialog_text;

      If (pos in [78..83]) then attr[78] := dialog_background+dialog_hi_text
      else attr[78] := dialog_background+dialog_text;

      If (pos in [84,88,92,96,100,104,108,112,116,120,
                  124,128,132,136,140,144,148,152,156,160]) then
        attr[84] := dialog_background+dialog_hi_text
      else attr[84] := dialog_background+dialog_text;

      If (pos in [85,89,93,97,101,105,109,113,117,121,
                  125,129,133,137,141,145,149,153,157,161]) then
        attr[85] := dialog_background+dialog_hi_text
      else attr[85] := dialog_background+dialog_text;

      If (pos in [86,90,94,98,102,106,110,114,118,122,
                  126,130,134,138,142,146,150,154,158,162]) then
        attr[86] := dialog_background+dialog_hi_text
      else attr[86] := dialog_background+dialog_text;

      If (pos in [87,91,95,99,103,107,111,115,119,123,
                  127,131,135,139,143,147,151,155,159,163]) then
        attr[87] := dialog_background+dialog_hi_text
      else attr[87] := dialog_background+dialog_text;

      ShowStr(ptr_temp_screen,xstart+34,ystart+12,'4-OP TRACK EXT.',attr[78]);
      For temp := 1 to 6 do
        If (songdata.flag_4op OR (1 SHL PRED(temp)) = songdata.flag_4op) then
          ShowCStr(ptr_temp_screen,xstart+34,ystart+13+temp-1,
                   '[~û~] ñ'+_4op_str[temp],
                   dialog_background+dialog_text,
                   dialog_background+dialog_item)
        else
          ShowCStr(ptr_temp_screen,xstart+34,ystart+13+temp-1,
                   '[~ ~] ñ'+_4op_str[temp],
                   dialog_background+dialog_text,
                   dialog_background+dialog_item);

      ShowStr(ptr_temp_screen,xstart+51,ystart+4,'PANNiNG',
              attr[18]);
      ShowStr(ptr_temp_screen,xstart+51,ystart+5,'©  c  ª',
              attr[18]);

      ShowVStr(ptr_temp_screen,xstart+64,ystart+4,'M',attr[84]);
      ShowVStr(ptr_temp_screen,xstart+68,ystart+4,'C',attr[85]);
      ShowVStr(ptr_temp_screen,xstart+72,ystart+4,'V',attr[86]);
      ShowVStr(ptr_temp_screen,xstart+76,ystart+4,'P',attr[87]);
      ShowVStr(ptr_temp_screen,xstart+65,ystart+4,#10, attr[84]);
      ShowVStr(ptr_temp_screen,xstart+69,ystart+4,#10, attr[85]);
      ShowVStr(ptr_temp_screen,xstart+73,ystart+4,'+', attr[86]);
      ShowVStr(ptr_temp_screen,xstart+77,ystart+4,'+', attr[87]);

      For temp := 1 to 20 do
        If (temp <= songdata.nm_tracks) then
          begin
            Case songdata.lock_flags[temp] AND 3 of
              0: ShowCStr(ptr_temp_screen,xstart+51,ystart+6+temp-1,
                          '~ú~ú~~ú~ú~',
                          dialog_background+dialog_text,
                          dialog_background+dialog_item);
              1: ShowCStr(ptr_temp_screen,xstart+51,ystart+6+temp-1,
                          '~~~ú~úú~ú~',
                          dialog_background+dialog_text,
                          dialog_background+dialog_item);
              2: ShowCStr(ptr_temp_screen,xstart+51,ystart+6+temp-1,
                          '~ú~úú~ú~~~',
                          dialog_background+dialog_text,
                          dialog_background+dialog_item);
            end;
            ShowCStr(ptr_temp_screen,xstart+60,ystart+6+temp-1,
                     '~'+ExpStrL(Num2str(temp,10),2,' ')+'~  '+
                     _on_off[songdata.lock_flags[temp] SHR 3 AND 1]+' ~ö~ '+
                     _on_off[songdata.lock_flags[temp] SHR 2 AND 1]+' ~ö~ '+
                     _on_off[songdata.lock_flags[temp] SHR 4 AND 1]+' ~ö~ '+
                     _on_off[songdata.lock_flags[temp] SHR 5 AND 1],
                     dialog_background+dialog_item,
                     dialog_background+dialog_context_dis);
          end
        else ShowStr(ptr_temp_screen,xstart+51,ystart+6+temp-1,
                     'úúúúúúú  '+ExpStrL(Num2str(temp,10),2,' ')+
                     '  ú ö ú ö ú ö ú',
                     dialog_background+dialog_hid);
      temps := '';
      For temp := 1 to songdata.nm_tracks do
        If percussion_mode and (temp in [16..20]) then temps := temps+_perc_char[temp-15]
        else Case temp of
               1:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then temps := temps+'¬'
                   else temps := temps+' ';
               2:  If (songdata.flag_4op OR 1 = songdata.flag_4op) then temps := temps+'­'
                   else temps := temps+' ';
               3:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then temps := temps+'¬'
                   else temps := temps+' ';
               4:  If (songdata.flag_4op OR 2 = songdata.flag_4op) then temps := temps+'­'
                   else temps := temps+' ';
               5:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then temps := temps+'¬'
                   else temps := temps+' ';
               6:  If (songdata.flag_4op OR 4 = songdata.flag_4op) then temps := temps+'­'
                   else temps := temps+' ';
               10: If (songdata.flag_4op OR 8 = songdata.flag_4op) then temps := temps+'¬'
                   else temps := temps+' ';
               11: If (songdata.flag_4op OR 8 = songdata.flag_4op) then temps := temps+'­'
                   else temps := temps+' ';
               12: If (songdata.flag_4op OR $10 = songdata.flag_4op) then temps := temps+'¬'
                   else temps := temps+' ';
               13: If (songdata.flag_4op OR $10 = songdata.flag_4op) then temps := temps+'­'
                   else temps := temps+' ';
               14: If (songdata.flag_4op OR $20 = songdata.flag_4op) then temps := temps+'¬'
                   else temps := temps+' ';
               15: If (songdata.flag_4op OR $20 = songdata.flag_4op) then temps := temps+'­'
                   else temps := temps+' ';
               else temps := temps+' ';
             end;

      ShowVStr(ptr_temp_screen,xstart+50,ystart+6,
               ExpStrR(temps,20,' '),
               dialog_background+dialog_context_dis);

      ShowStr(ptr_temp_screen,xstart+2,ystart+1,
        'SONGNAME',attr[1]);
      ShowStr(ptr_temp_screen,xstart+2,ystart+3,
        'COMPOSER',attr[2]);
      ShowStr(ptr_temp_screen,xstart+2,ystart+9,
        'SONG TEMPO',attr[3]);
      ShowStr(ptr_temp_screen,xstart+2,ystart+10,
        'SONG SPEED',attr[4]+attr[5]);

      ShowCStr(ptr_temp_screen,xstart+26,ystart+10,
        '[ ] ~update~',dialog_background+dialog_text,attr[4]+attr[5]);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+11,
        '~MACRODEF.~ ',dialog_background+dialog_text,attr[17]);

      If speed_update then ShowStr(ptr_temp_screen,xstart+27,ystart+10,'û',dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+27,ystart+10,' ',dialog_background+dialog_item);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+13,
        '[ ] ~TRACK VOLUME LOCK~',dialog_background+dialog_text,attr[6]);
      ShowCStr(ptr_temp_screen,xstart+2,ystart+14,
        '[ ] ~TRACK PANNiNG LOCK~',dialog_background+dialog_text,attr[7]);
      ShowCStr(ptr_temp_screen,xstart+2,ystart+15,
        '[ ] ~VOLUME PEAK LOCK~',dialog_background+dialog_text,attr[8]);

      If lockvol then ShowStr(ptr_temp_screen,xstart+3,ystart+13,'û',dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+13,' ',dialog_background+dialog_item);

      If panlock then ShowStr(ptr_temp_screen,xstart+3,ystart+14,'û',dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+14,' ',dialog_background+dialog_item);

      If lockVP then ShowStr(ptr_temp_screen,xstart+3,ystart+15,'û',dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+15,' ',dialog_background+dialog_item);

      ShowStr(ptr_temp_screen,xstart+2,ystart+17,
        'TREMOLO DEPTH',attr[9]+attr[10]);

      ShowStr(ptr_temp_screen,xstart+2,ystart+18,
        '( ) 1 dB',dialog_background+dialog_text);
      ShowStr(ptr_temp_screen,xstart+2,ystart+19,
        '( ) 4.8 dB',dialog_background+dialog_text);

      If (tremolo_depth = 0) then ShowVStr(ptr_temp_screen,xstart+3,ystart+18,'û ',dialog_background+dialog_item)
      else ShowVStr(ptr_temp_screen,xstart+3,ystart+18,' û',dialog_background+dialog_item);

      ShowStr(ptr_temp_screen,xstart+18,ystart+17,
        'ViBRATO DEPTH',attr[11]+attr[12]);

      ShowStr(ptr_temp_screen,xstart+18,ystart+18,
        '( ) 7%',dialog_background+dialog_text);
      ShowStr(ptr_temp_screen,xstart+18,ystart+19,
        '( ) 14%',dialog_background+dialog_text);

      If (vibrato_depth = 0) then ShowVStr(ptr_temp_screen,xstart+19,ystart+18,'û ',dialog_background+dialog_item)
      else ShowVStr(ptr_temp_screen,xstart+19,ystart+18,' û',dialog_background+dialog_item);

      ShowStr(ptr_temp_screen,xstart+2,ystart+21,
        'PATTERN LENGTH',attr[13]);
      ShowStr(ptr_temp_screen,xstart+2,ystart+22,
        'NUMBER OF TRACKS',attr[14]);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+24,
        '[ ] ~PERCUSSiON TRACK EXTENSiON ( ,¡,¢,£,¤)~',dialog_background+dialog_text,attr[15]);

      If percussion_mode then ShowStr(ptr_temp_screen,xstart+3,ystart+24,'û',dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+24,' ',dialog_background+dialog_item);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+25,
        '[ ] ~VOLUME SCALiNG~',dialog_background+dialog_text,attr[16]);

      If volume_scaling then ShowStr(ptr_temp_screen,xstart+3,ystart+25,'û',dialog_background+dialog_item)
      else ShowStr(ptr_temp_screen,xstart+3,ystart+25,' ',dialog_background+dialog_item);

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
      Case pos of
        1: begin
             is_setting.character_set := [#$20..#$ff];
             temps := InputStr(songdata.songname,xstart+2,ystart+2,
                               42,42,
                               dialog_input_bckg+dialog_input,
                               dialog_def_bckg+dialog_def);
             songdata.songname := truncate_string(temps);
             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 2
             else If (is_environment.keystroke = kUP) then pos := 16
                  else If (is_environment.keystroke = kShTAB) then pos := 87;
           end;

        2: begin
             is_setting.character_set := [#$20..#$ff];
             temps := InputStr(songdata.composer,xstart+2,ystart+4,
                               42,42,
                               dialog_input_bckg+dialog_input,
                               dialog_def_bckg+dialog_def);
             songdata.composer := truncate_string(temps);
             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) then pos := 3
             else If (is_environment.keystroke = kDOWN) then pos := 18
                  else If (is_environment.keystroke = kUP) or
                          (is_environment.keystroke = kShTAB) then pos := 1;
           end;

        3: begin
             is_setting.character_set := ['0'..'9'];
             Repeat
               temps := InputStr(Num2str(songdata.tempo,10),
                                 xstart+13,ystart+9,3,3,
                                 dialog_input_bckg+dialog_input,
                                 dialog_def_bckg+dialog_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,10) > 0) and (Str2num(temps,10) < 256));

             If ((Str2num(temps,10) > 0) and (Str2num(temps,10) < 256)) then
               songdata.tempo := Str2num(temps,10);

             If (calc_max_speedup(songdata.tempo) < songdata.macro_speedup) then
               songdata.macro_speedup := calc_max_speedup(songdata.tempo);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 4
             else If (is_environment.keystroke = kUP) then pos := 18+3*(max(3,songdata.nm_tracks)-1)
                  else If (is_environment.keystroke = kShTAB) then pos := 2;
           end;

        4: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(Num2str(songdata.speed,16),
                                 xstart+13,ystart+10,2,2,
                                 dialog_input_bckg+dialog_input,
                                 dialog_def_bckg+dialog_def);
             until (is_environment.keystroke = kESC) or
                   (Str2num(temps,16) in [1..255]);

             If (Str2num(temps,16) in [1..255]) then
               songdata.speed := Str2num(temps,16);

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
             Case is_environment.keystroke of
               kUP: pos := 3;
               kLEFT,kShTAB: pos := 4;
               kDOWN,kTAB,kENTER: pos := 17;
               kRIGHT: If (songdata.nm_tracks < 5) then pos := 17 else pos := 30;
               kSPACE: speed_update := NOT speed_update;
             end;
           end;

       17: begin
             is_setting.character_set := ['0'..'9'];
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

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) then pos := 6
             else If (is_environment.keystroke = kUP) then pos := 4
                  else If (is_environment.keystroke = kDOWN) then
                         If (songdata.nm_tracks < 7) then pos := 6
                         else pos := 36
                       else If (is_environment.keystroke = kShTAB) then pos := 5;
           end;

        6: begin
             GotoXY(xstart+3,ystart+13);
             ThinCursor;
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kUP,kLEFT: If (songdata.nm_tracks < 7) then pos := 17 else pos := 111;
               kShTAB: pos := 17;
               kDOWN,kTAB,kENTER: pos := 7;
               kRIGHT: pos := 78;
               kSPACE: lockvol := NOT lockvol;
             end;
           end;

        7: begin
             GotoXY(xstart+3,ystart+14);
             ThinCursor;
             is_environment.keystroke := getkey;
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
             Case is_environment.keystroke of
               kUP: pos := 7;
               kLEFT: If (songdata.nm_tracks < 9) then pos := 79 else pos := 119;
               kShTAB: pos := 7;
               kDOWN: pos := 9;
               kTAB,kENTER: pos := 9;
               kRIGHT: pos := 80;
               kSPACE: lockVP := NOT lockVP;
             end;
           end;

        9: begin
             GotoXY(xstart+3,ystart+18);
             ThinCursor;
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kUP: pos := 8;
               kLEFT: If (songdata.nm_tracks < 12) then pos := 82 else pos := 131;
               kShTAB: pos := 8;
               kRIGHT,kTAB,kENTER: pos := 11;
               kDOWN: pos := 10;
               kSPACE: tremolo_depth := 0;
             end;
           end;

       10: begin
             GotoXY(xstart+3,ystart+19);
             ThinCursor;
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kUP: pos := 9;
               kShTAB: pos := 8;
               kDOWN: If (songdata.nm_tracks < 15) then pos := 13 else pos := 60;
               kTAB,kENTER: pos := 11;
               kLEFT: If (songdata.nm_tracks < 13) then pos := 83 else pos := 135;
               kRIGHT: pos := 12;
               kSPACE: tremolo_depth := 1;
             end;
           end;

       11: begin
             GotoXY(xstart+19,ystart+18);
             ThinCursor;
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kUP: pos := 8;
               kShTAB: pos := 9;
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
             Case is_environment.keystroke of
               kUP: pos := 11;
               kShTAB: pos := 9;
               kDOWN: If (songdata.nm_tracks < 15) then pos := 13 else pos := 60;
               kTAB,kENTER: pos := 13;
               kLEFT: pos := 10;
               kRIGHT: If (songdata.nm_tracks < 14) then pos := 13 else pos := 57;
               kSPACE: vibrato_depth := 1;
             end;
           end;

       13: begin
             is_setting.character_set := ['0'..'9'];
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

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 14
             else If (is_environment.keystroke = kUP) then
                    If (songdata.nm_tracks < 15) then pos := 10
                    else pos := 60
                  else If (is_environment.keystroke = kShTAB) then pos := 11;
           end;

       14: begin
             is_setting.character_set := ['0'..'9'];
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

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) then pos := 15
             else If (is_environment.keystroke = kDOWN) then
                    If (songdata.nm_tracks < 18) then pos := 15
                    else pos := 69
                  else If (is_environment.keystroke = kUP) or
                          (is_environment.keystroke = kShTAB) then pos := 13;
           end;

       15: begin
             GotoXY(xstart+3,ystart+24);
             ThinCursor;
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kUP: If (songdata.nm_tracks < 18) then pos := 14 else pos := 69;
               kLEFT: If (songdata.nm_tracks < 18) then pos := 14 else pos := 155;
               kRIGHT: If (songdata.nm_tracks < 19) then pos := 16 else pos := 72;
               kShTAB: pos := 14;
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
             Case is_environment.keystroke of
               kUP: pos := 15;
               kLEFT: If (songdata.nm_tracks < 19) then pos := 15 else pos := 159;
               kRIGHT: If (songdata.nm_tracks < 20) then pos := 1 else pos := 75;
               kShTAB: pos := 15;
               kDOWN: pos := 1;
               kTAB,kENTER: pos := 78;
               kSPACE: volume_scaling := NOT volume_scaling;
             end;
           end;

       18..
       77: begin
             GotoXY(xstart+51+(pos-17-1) MOD 3*3,ystart+6+(pos-17-1) DIV 3);
             ThinCursor;
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kLEFT: pos := _left_pos_pan[pos-17];
               kRIGHT: pos := _right_pos_pan[pos-17];
               kUP: pos := _up_pos_pan[pos-17];
               kDOWN,kENTER:  pos := _down_pos_pan[pos-17];
               kShTAB: pos := 78;
               kTAB: pos := 84;
               kSPACE: begin
                         songdata.lock_flags[SUCC((pos-17-1) DIV 3)] :=
                         songdata.lock_flags[SUCC((pos-17-1) DIV 3)] AND NOT 3+
                         _pan_pos[(pos-17-1) MOD 3];
                         panlock := TRUE;
                       end;
             end;
           end;

       78..
       83: begin
             GotoXY(xstart+35,ystart+13+pos-78);
             ThinCursor;
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kLEFT: pos := _left_pos_4op[pos-77];
               kRIGHT: pos := _right_pos_4op[pos-77];
               kUP: pos := _up_pos_4op[pos-77];
               kDOWN: pos := _down_pos_4op[pos-77];
               kShTAB: pos := 16;
               kTAB,kENTER: pos := 18;
             end;

             If (is_environment.keystroke = kSPACE) then
               If (songdata.flag_4op OR (1 SHL PRED(pos-77)) <> songdata.flag_4op) then
                 begin
                   reset_player;
                   Case (pos-77) of
                     1: songdata.nm_tracks := min(songdata.nm_tracks,2);
                     2: songdata.nm_tracks := min(songdata.nm_tracks,4);
                     3: songdata.nm_tracks := min(songdata.nm_tracks,6);
                     4: songdata.nm_tracks := min(songdata.nm_tracks,11);
                     5: songdata.nm_tracks := min(songdata.nm_tracks,13);
                     6: songdata.nm_tracks := min(songdata.nm_tracks,15);
                   end;
                   songdata.flag_4op := songdata.flag_4op OR (1 SHL PRED(pos-77));
                   reset_player;
                   If (play_status = isStopped) then init_buffers;
                 end
               else
                 begin
                   reset_player;
                   songdata.flag_4op := songdata.flag_4op AND NOT (1 SHL PRED(pos-77));
                   reset_player;
                   If (play_status = isStopped) then init_buffers;
                 end;

             force_scrollbars := TRUE;
             PATTERN_ORDER_page_refresh(pattord_page);
             PATTERN_page_refresh(pattern_page);
             force_scrollbars := FALSE;
           end;

       84..
      163: begin
             GotoXY(xstart+64+(pos-83-1) MOD 4*4,ystart+6+(pos-83-1) DIV 4);
             ThinCursor;
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kLEFT: pos := _left_pos_lck[pos-83];
               kRIGHT: pos := _right_pos_lck[pos-83];
               kUP: pos := _up_pos_lck[pos-83];
               kDOWN,kENTER:  pos := _down_pos_lck[pos-83];
               kShTAB: Case (pos-83-1) MOD 4 of
                         0: pos := 18;
                         1: pos := 84;
                         2: pos := 85;
                         3: pos := 86;
                       end;

               kTAB: Case (pos-83-1) MOD 4 of
                       0: pos := 85;
                       1: pos := 86;
                       2: pos := 87;
                       3: pos := 1;
                     end;

               kSPACE: Case (pos-83-1) MOD 4 of
                         0: songdata.lock_flags[SUCC((pos-83-1) DIV 4)] :=
                            songdata.lock_flags[SUCC((pos-83-1) DIV 4)] XOR 8;
                         1: songdata.lock_flags[SUCC((pos-83-1) DIV 4)] :=
                            songdata.lock_flags[SUCC((pos-83-1) DIV 4)] XOR 4;

                         2: begin
                              songdata.lock_flags[SUCC((pos-83-1) DIV 4)] :=
                              songdata.lock_flags[SUCC((pos-83-1) DIV 4)] XOR $10;
                              lockvol := TRUE;
                            end;

                         3: begin
                              songdata.lock_flags[SUCC((pos-83-1) DIV 4)] :=
                              songdata.lock_flags[SUCC((pos-83-1) DIV 4)] XOR $20;
                              lockVP := TRUE;
                            end;
                       end;
             end;
           end;
      end;
_end:
{$IFDEF __TMT__}
    realtime_gfx_poll_proc;
    keyboard_reset_buffer_alt;
{$ELSE}
    emulate_screen;
{$ENDIF}
    until (is_environment.keystroke = kESC) or
          (is_environment.keystroke = kF1);

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
  HideCursor;
  Move(old_keys,is_setting.terminate_keys,SizeOf(old_keys));
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+79+2;
  move_to_screen_area[4] := ystart+26+1;
  move2screen;

  If (is_environment.keystroke = kF1) then
    begin
      HELP('song_variables');
      GOTO _jmp1;
    end;
end;

procedure NUKE;

var
  temp,temp1,temp2: Byte;

begin
{$IFDEF __TMT__}
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
          FillChar(pattdata^,SizeOf(pattdata^),0);
          PATTERN_ORDER_page_refresh(pattord_page);
          PATTERN_page_refresh(pattern_page);
          For temp2 := 0 to $7f do
            songdata.pattern_names[temp2] :=
              ' PAT_'+byte2hex(temp2)+'  ÷ ';
          pattern_list__page := 1;
        end;

      If (temp1 = 4) then
        begin
          For temp2 := 1 to 255 do
            begin
              FillChar(songdata.instr_names[temp2][2],SizeOf(songdata.instr_names[temp2])-2,0);
              songdata.instr_names[temp2] :=
                songdata.instr_names[temp2][1]+
                'iNS_'+byte2hex(temp2)+'÷ ';
            end;
        end;

      If (temp1 = 5) then
        FillChar(songdata.instr_data,SizeOf(songdata.instr_data),0);

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
          add_bank_position('?replace_window?pos',-1,1);
          add_bank_position('?replace_window?posfx',-1,1);
          For temp := 1 to _rearrange_nm_tracks do _rearrange_tracklist_idx[temp] := temp;
          _rearrange_track_pos := 1;
        end
      else module_archived := FALSE;
    end;
end;

procedure QUIT_request;

var
  temp: Byte;

begin
{$IFDEF __TMT__}
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

const
  last_dir:  array[1..4] of String[DIR_SIZE] = ('','','','');
  last_file: array[1..4] of String[FILENAME_SIZE] = ('FNAME:EXT','FNAME:EXT',
                                                     'FNAME:EXT','FNAME:EXT');

function FILE_open(masks: String; loadBankPossible: Boolean): Byte;

var
  temp: String;
  mpos,index: Byte;
  old_ext_proc: procedure;
  old_songdata_source: String;
  old_play_status: tPLAY_STATUS;
  old_tracing: Boolean;
  temp_marks: array[1..255] of Char;
  temp_marks2: array[0..$7f] of Char;
  flag: Byte;

label _jmp1;

begin
{$IFDEF __TMT__}
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
      temp := Fselect(masks);
      mn_environment.ext_proc := old_ext_proc;

      last_file[mpos] := fs_environment.last_file;
      last_dir[mpos]  := fs_environment.last_dir;

      If (mn_environment.keystroke <> kENTER) then EXIT
      else If (mpos = 1) then songdata_source := temp
           else instdata_source := temp;
    end
  else If (mpos = 1) then temp := songdata_source
       else temp := instdata_source;

  load_flag := BYTE_NULL;
  limit_exceeded := FALSE;
  HideCursor;

  nul_volume_bars;
  no_status_refresh := TRUE;

  If (ExtOnly(temp) = 'a2m') then a2m_file_loader;
  If (ExtOnly(temp) = 'a2t') then a2t_file_loader;
  If (ExtOnly(temp) = 'a2p') then a2p_file_loader;
  If (ExtOnly(temp) = 'amd') then amd_file_loader;
  If (ExtOnly(temp) = 'cff') then cff_file_loader;
  If (ExtOnly(temp) = 'dfm') then dfm_file_loader;
  If (ExtOnly(temp) = 'fmk') then fmk_file_loader;
  If (ExtOnly(temp) = 'hsc') then hsc_file_loader;
  If (ExtOnly(temp) = 'mtk') then mtk_file_loader;
  If (ExtOnly(temp) = 'rad') then rad_file_loader;
  If (ExtOnly(temp) = 's3m') then s3m_file_loader;
  If (ExtOnly(temp) = 'sat') then sat_file_loader;
  If (ExtOnly(temp) = 'sa2') then sa2_file_loader;
  If (ExtOnly(temp) = 'xms') then amd_file_loader;
  If (ExtOnly(temp) = 'a2i') then a2i_file_loader;
  If (ExtOnly(temp) = 'a2f') then a2f_file_loader;

  If (ExtOnly(temp) = 'a2b') then
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

  If (ExtOnly(temp) = 'a2w') then
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

  If (ExtOnly(temp) = 'bnk') then bnk_file_loader;
  If (ExtOnly(temp) = 'cif') then cif_file_loader;
  If (ExtOnly(temp) = 'fib') then fib_file_loader;
  If (ExtOnly(temp) = 'fin') then fin_file_loader;
  If (ExtOnly(temp) = 'ibk') then ibk_file_loader;
  If (ExtOnly(temp) = 'ins') then ins_file_loader;
  If (ExtOnly(temp) = 'sbi') then sbi_file_loader;
  If (ExtOnly(temp) = 'sgi') then sgi_file_loader;

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
           If (ExtOnly(temp) <> 'a2p') then
             For index := 1 to 255 do
               songdata.instr_names[index] :=
                 ' iNS_'+byte2hex(index)+'÷ '+
                 Copy(songdata.instr_names[index],10,32);

           If (ExtOnly(temp) <> 'a2p') then
             For index := 0 to $7f do
               songdata.pattern_names[index] :=
                 ' PAT_'+byte2hex(index)+'  ÷ '+
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
               add_bank_position('?replace_window?pos',-1,1);
               add_bank_position('?replace_window?posfx',-1,1);
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
              If (ExtOnly(temp) <> 'a2p') and
                 NOT (shift_pressed and (mpos = 1) and (load_flag <> BYTE_NULL) and NOT quick_cmd and
                                        (old_play_status = isPlaying)) then
                POSITIONS_reset;
           songdata_crc := Update32(songdata,SizeOf(songdata),0);
           If (ExtOnly(temp) <> 'a2p') then
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
           If (ExtOnly(temp) = 'bnk') or
              (ExtOnly(temp) = 'fib') or
              (ExtOnly(temp) = 'ibk') then GOTO _jmp1;

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
        If (ExtOnly(temp) <> 'a2p') and NOT tracing then POSITIONS_reset;
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

procedure show_progress(value: Longint);
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:show_progress';
{$ENDIF}
  If (value <> DWORD_NULL) then
    begin
      progress_new_value := Round(progress_step*value);
      If (progress_new_value <> progress_old_value) then
        begin
          progress_old_value := progress_new_value;
          ShowCStr(screen_ptr,
                   progress_xstart,progress_ystart,
                   '~'+ExpStrL('',progress_new_value,'Û')+'~'+
                   ExpStrL('',40-progress_new_value,'Û'),
                   dialog_background+dialog_prog_bar1,
                   dialog_background+dialog_prog_bar2);

          If (progress_new_value MOD 5 = 0) then
            begin
              realtime_gfx_poll_proc;
              emulate_screen;
            end;
        end
    end
  else begin
         ShowStr(screen_ptr,
                 progress_xstart,progress_ystart,
                 ExpStrL('',40,'Û'),
                 dialog_background+dialog_prog_bar1);
         realtime_gfx_poll_proc;
         emulate_screen;
       end;
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
  temps: String;
  xstart,ystart: Byte;
  temp_marks: array[1..255] of Char;
  temp_marks2: array[0..$7f] of Char;

procedure _restore;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2m_saver:_restore';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
end;

begin
{$IFDEF __TMT__}
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
  header.ffver := 11;
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
  HideCursor;
  If (header.patts = 0) then header.patts := 1;

  temps := 'aPLib';
  centered_frame(xstart,ystart,43,3,' '+temps+' ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;

  ShowCStr(screen_ptr,xstart+2,ystart+1,
           'COMPRESSiNG MODULE DATA [BLOCK ~01~ OF ~'+
           ExpStrL(Num2str((header.patts-1) DIV 8 +2,10),2,'0')+'~]',
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

  header.b0len := APACK_compress(songdata,buf1,SizeOf(songdata));
  For temp := 1 to 255 do
    Insert(temp_marks[temp]+
           'iNS_'+byte2hex(temp)+'÷ ',
           songdata.instr_names[temp],1);

  For temp := 0 to $7f do
    Insert(temp_marks2[temp]+
           'PAT_'+byte2hex(temp)+'  ÷ ',
           songdata.pattern_names[temp],1);

  BlockWriteF(f,buf1,header.b0len,temp);
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
  ShowStr(screen_ptr,xstart+33,ystart+1,'02',dialog_background+dialog_hi_text);

  header.b1len[0] := APACK_compress(pattdata^[0],buf1,SizeOf(pattdata^[0]));
  BlockWriteF(f,buf1,header.b1len[0],temp);
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
        ShowStr(screen_ptr,xstart+33,ystart+1,
                ExpStrL(Num2str(index+2,10),2,'0'),dialog_background+dialog_hi_text);

        header.b1len[index] := APACK_compress(pattdata^[index],buf1,SizeOf(pattdata^[index]));
        BlockWriteF(f,buf1,header.b1len[index],temp);
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
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXTN.PAS:_a2t_saver:_restore';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
end;

begin
{$IFDEF __TMT__}
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

  header.patln := songdata.patt_len;
  header.nmtrk := songdata.nm_tracks;
  header.mcspd := songdata.macro_speedup;
  header.is4op := songdata.flag_4op;
  Move(songdata.lock_flags,header.locks,SizeOf(header.locks));
  header.ffver := 11;

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
  HideCursor;
  If (header.patts = 0) then header.patts := 1;

  temps := 'aPLib';
  centered_frame(xstart,ystart,43,3,' '+temps+' ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;

  ShowCStr(screen_ptr,xstart+2,ystart+1,
           'COMPRESSiNG TiNY MODULE [BLOCK ~01~ OF ~'+
           ExpStrL(Num2str((header.patts-1) DIV 8 +6,10),2,'0')+'~]',
           dialog_background+dialog_text,
           dialog_background+dialog_hi_text);
  show_progress(DWORD_NULL);

  count_instruments(instruments);
  instruments := min(instruments,1);
  temp2 := instruments*SizeOf(songdata.instr_data[1]);

  header.b0len := APACK_compress(songdata.instr_data,buf1,temp2);
  BlockWriteF(f,buf1,header.b0len,temp);
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

  ShowStr(screen_ptr,xstart+33,ystart+1,'02',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buf1,header.b0len,header.crc32);

  temp2 := instruments*SizeOf(songdata.instr_macros[1]);
  header.b1len := APACK_compress(songdata.instr_macros,buf1,temp2);
  BlockWriteF(f,buf1,header.b1len,temp);
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

  ShowStr(screen_ptr,xstart+33,ystart+1,'03',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buf1,header.b1len,header.crc32);

  temp2 := SizeOf(songdata.macro_table);
  header.b2len := APACK_compress(songdata.macro_table,buf1,temp2);
  BlockWriteF(f,buf1,header.b2len,temp);
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

  ShowStr(screen_ptr,xstart+33,ystart+1,'04',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buf1,header.b2len,header.crc32);

  temp2 := SizeOf(songdata.dis_fmreg_col);
  header.b3len := APACK_compress(songdata.dis_fmreg_col,buf1,temp2);
  BlockWriteF(f,buf1,header.b3len,temp);
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

  ShowStr(screen_ptr,xstart+33,ystart+1,'05',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buf1,header.b3len,header.crc32);

  temp2 := SizeOf(songdata.pattern_order);
  header.b4len := APACK_compress(songdata.pattern_order,buf1,temp2);
  BlockWriteF(f,buf1,header.b4len,temp);
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

  ShowStr(screen_ptr,xstart+33,ystart+1,'06',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buf1,header.b4len,header.crc32);

  If (header.patts < 1*8) then temp2 := header.patts*SizeOf(pattdata^[0][0])
  else temp2 := SizeOf(pattdata^[0]);

  header.b5len[0] := APACK_compress(pattdata^[0],buf1,temp2);
  BlockWriteF(f,buf1,header.b5len[0],temp);
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
        ShowStr(screen_ptr,xstart+33,ystart+1,
                ExpStrL(Num2str(index+6,10),2,'0'),dialog_background+dialog_hi_text);

        If (header.patts < SUCC(index)*8) then
          temp2 := (header.patts-index*8)*SizeOf(pattdata^[index][0])
        else temp2 := SizeOf(pattdata^[index]);

        header.b5len[index] := APACK_compress(pattdata^[index],buf1,temp2);
        BlockWriteF(f,buf1,header.b5len[index],temp);
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
  crc: Word;
  temp_str: String;

begin
{$IFDEF __TMT__}
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

  progress_xstart := 0;
  progress_ystart := 0;
  header.ident := id;
  header.ffver := 9;

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

  Move(songdata.instr_data[current_inst],
       buf2,
       SizeOf(songdata.instr_data[current_inst]));

  temp_str := Copy(songdata.instr_names[current_inst],10,32);
  Move(temp_str,
       buf2[SizeOf(songdata.instr_data[current_inst])],
       Length(temp_str)+1);

  temp3 := SizeOf(songdata.instr_data[current_inst])+Length(temp_str)+2;
  temp2 := APACK_compress(buf2,buf3,temp3);

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
  temp_str: String;

begin
{$IFDEF __TMT__}
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

  progress_xstart := 0;
  progress_ystart := 0;
  header.ident := id;
  header.ffver := 1;

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
  Move(songdata.instr_data[current_inst],
       buf2,
       SizeOf(songdata.instr_data[current_inst]));
  Inc(temp3,SizeOf(songdata.instr_data[current_inst]));

  temp_str := Copy(songdata.instr_names[current_inst],10,32);
  Move(temp_str,
       buf2[temp3],
       Length(temp_str)+1);
  Inc(temp3,Length(temp_str)+1);

  temp2 := 0;
  Move(songdata.instr_macros[current_inst],buf3,
       SizeOf(songdata.instr_macros[current_inst]));
  Inc(temp2,SizeOf(songdata.instr_macros[current_inst]));

  tREGISTER_TABLE(Addr(buf3)^).arpeggio_table := 0;
  tREGISTER_TABLE(Addr(buf3)^).vibrato_table := 0;

  Move(songdata.dis_fmreg_col[current_inst],
       buf3[temp2],
       SizeOf(songdata.dis_fmreg_col[current_inst]));
  Inc(temp2,SizeOf(songdata.dis_fmreg_col[current_inst]));

  Move(buf3,buf2[temp3],temp2);
  Inc(temp3,temp2);
  temp2 := APACK_compress(buf2,buf3,temp3);

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
{$IFDEF __TMT__}
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

  progress_xstart := 0;
  progress_ystart := 0;
  header.crc32 := DWORD_NULL;
  header.ident := id;
  header.ffver := 10;

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
  header.b0len := APACK_compress(buf2,buf1,temp2);

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
{$IFDEF __TMT__}
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

  progress_xstart := 0;
  progress_ystart := 0;
  header.ident := id;
  header.ffver := 9;

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
  temp2 := APACK_compress(songdata.instr_names,buf1,temp3);

  For temp := 1 to 255 do
    Insert(temp_marks[temp]+
           'iNS_'+byte2hex(temp)+'÷ ',
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

begin
{$IFDEF __TMT__}
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

  progress_xstart := 0;
  progress_ystart := 0;

  header.crc32 := DWORD_NULL;
  header.ident := id;
  header.ffver := 2;

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
  header.b0len := APACK_compress(songdata.instr_names,buf1,temp3);

  For temp := 1 to 255 do
    Insert(temp_marks[temp]+
           'iNS_'+byte2hex(temp)+'÷ ',
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
  header.b1len := APACK_compress(songdata.macro_table,buf1,SizeOf(songdata.macro_table));

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
  header.b2len := APACK_compress(songdata.dis_fmreg_col,buf1,SizeOf(songdata.dis_fmreg_col));

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
{$IFDEF __TMT__}
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
    is_setting.character_set     := [#$20..#$ff];
    dl_setting.center_text       := FALSE;
    dl_setting.terminate_keys[3] := kTAB;
    is_setting.terminate_keys[3] := kTAB;
    is_environment.locate_pos    := 1;
    dl_environment.context       := ' TAB Ä FiLE SELECTOR ';

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
