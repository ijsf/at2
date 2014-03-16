unit AdT2extn;
{$PACKRECORDS 1}
interface

const
  _pip_xloc: Byte    = 1;
  _pip_yloc: Byte    = 1;
  _pip_dest: Pointer = NIL;
  _pip_loop: Boolean = FALSE;
  _arp_vib_loader: Boolean = FALSE;
  _arp_vib_mode: Boolean = FALSE;
  _macro_editor__pos: array[Boolean] of Byte = (1,8);
  _macro_editor__fmreg_hpos: array[Boolean] of Byte = (1,1);
  _macro_editor__fmreg_page: array[Boolean] of Byte = (1,1);
  _macro_editor__fmreg_left_margin: array[Boolean] of Byte = (1,1);
  _macro_editor__fmreg_cursor_pos: array[Boolean] of Byte = (1,1);
  _macro_editor__arpeggio_page: array[Boolean] of Byte = (1,1);
  _macro_editor__vibrato_hpos: array[Boolean] of Byte = (1,1);
  _macro_editor__vibrato_page: array[Boolean] of Byte = (1,1);

const
  remap_mtype:       Byte = 1;
  remap_ins1:        Byte = 1;
  remap_ins2:        Byte = 1;
  remap_selection:   Byte = 1;
  replace_selection: Byte = 1;
  replace_prompt:    Boolean = FALSE;
  replace_data:      Record
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
  scroll_pos0: Byte = $0ff;
  scroll_pos1: Byte = $0ff;
  scroll_pos2: Byte = $0ff;
  scroll_pos3: Byte = $0ff;
  scroll_pos4: Byte = $0ff;

const
  arpvib_arpeggio_table: Byte = 1;
  arpvib_vibrato_table:  Byte = 1;

const
  NULL = $0ff;

const
  copypos1: Byte = 1;
  copypos2: Byte = 1;
  copypos3: Byte = 1;
  copypos4: Byte = 1;
  clearpos: Byte = 1;
  pattern_list__page: Byte = 1;
  pattern2use: Byte = NULL;

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
procedure REPLACE;
procedure POSITIONS_reset;
procedure DEBUG_INFO;
procedure LINE_MARKING_SETUP;
procedure OCTAVE_CONTROL;
procedure SONG_VARIABLES;
procedure MACRO_EDITOR(instr: Byte; arp_vib_mode: Boolean);
procedure MACRO_BROWSER(instrBrowser: Boolean; updateCurInstr: Boolean);
procedure FILE_save(ext: String);
function  FILE_open(masks: String; loadBankPossible: Boolean): Byte;
procedure NUKE;
procedure QUIT_request;
procedure show_progress(value: Longint);

implementation

uses
  AdT2sys,AdT2vscr,AdT2opl3,AdT2keyb,
  AdT2unit,AdT2ext2,AdT2ext3,AdT2text,AdT2apak,
  StringIO,DialogIO,ParserIO,TxtScrIO,
  MenuLib1,MenuLib2;

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
  status_backup.replay_forbidden := replay_forbidden;
  status_backup.play_status := play_status;
  replay_forbidden := TRUE;
  If (play_status <> isStopped) then play_status := isPaused;
  PATTERN_position_preview(NULL,NULL,NULL,0);

  _1st_choice := NULL;
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
                         NOT (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) then
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
                       NOT (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) and
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
                         NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) then
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
                       NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) and
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
                           NOT (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) then
                          begin
                            If (_1st_choice <> NULL) then
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
                                _1st_choice := NULL;
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
                          If NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) then
                            begin
                              Inc(chunk.note,factor);
                              put_chunk(temp3,temp1,temp2,chunk);
                            end;
                      end
                    else
                      If NOT (chunk.note < 12*8+1) and
                         NOT (chunk.note in [fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) and
                             (chunk.instr_def = current_inst) then
                        begin
                          If (_1st_choice <> NULL) then
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
                              _1st_choice := NULL;
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
                        If NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) and
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
                           NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) then
                          begin
                            If (_1st_choice <> NULL) then
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
                                _1st_choice := NULL;
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
                          If NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) then
                            begin
                              Dec(chunk.note,factor);
                              put_chunk(temp3,temp1,temp2,chunk);
                            end;
                      end
                    else
                      If NOT (chunk.note >= factor+1) and
                         NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) and
                             (chunk.instr_def = current_inst) then
                        begin
                          If (_1st_choice <> NULL) then
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
                              _1st_choice := NULL;
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
                        If NOT (chunk.note in [0,fixed_note_flag+1..fixed_note_flag+12*8+1,NULL]) and
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

  PATTERN_position_preview(NULL,NULL,NULL,NULL);
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

const
  factor: array[1..17] of Byte = (1,12,1,12,1,12,1,12,NULL,
                                  1,12,1,12,1,12,1,12);
begin
  mn_setting.title_attr   := dialog_background+dialog_title;
  mn_setting.menu_attr    := dialog_background+dialog_border;
  mn_setting.text_attr    := dialog_background+dialog_text;
  mn_setting.text2_attr   := dialog_sel_btn_bck+dialog_sel_btn;
  mn_setting.short_attr   := dialog_background+dialog_short;
  mn_setting.short2_attr  := dialog_sel_btn_bck+dialog_sel_short;
  mn_setting.disbld_attr  := dialog_background+dialog_button_dis;
  mn_setting.contxt_attr  := dialog_background+dialog_context;
  mn_setting.contxt2_attr := dialog_background+dialog_context_dis;

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

  mn_setting.title_attr    := menu_background+menu_title;
  mn_setting.menu_attr     := menu_background+menu_border;
  mn_setting.text_attr     := menu_background+menu_item;
  mn_setting.text2_attr    := menu_sel_item_bckg+menu_sel_item;
  mn_setting.short_attr    := menu_background+menu_short;
  mn_setting.short2_attr   := menu_sel_item_bckg+menu_sel_short;
  mn_setting.disbld_attr   := menu_background+menu_item_dis;
  mn_setting.contxt_attr   := menu_background+menu_context;
  mn_setting.contxt2_attr  := menu_background+menu_context_dis;
  mn_setting.topic_attr    := menu_background+menu_topic;
  mn_setting.hi_topic_attr := menu_background+menu_hi_topic;

  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(pattern_page);
  mn_setting.fixed_len := 0;
  mn_setting.terminate_keys[3] := 0;
  mn_environment.context := '';
  mn_environment.ext_proc := NIL;
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
  If (_remap_pos = 1) then
    ShowStr(centered_frame_vdest^,_remap_xstart+8,_remap_ystart+1,'CURRENT iNSTRUMENT ('+
            byte2hex(MenuLib1_mn_environment.curr_pos)+')',
            dialog_background+dialog_hi_text)
  else
    ShowStr(centered_frame_vdest^,_remap_xstart+8,_remap_ystart+1,'CURRENT iNSTRUMENT ('+
            byte2hex(MenuLib1_mn_environment.curr_pos)+')',
            dialog_background+dialog_text);

  If (_remap_pos = 2) then
    ShowStr(centered_frame_vdest^,_remap_xstart+44,_remap_ystart+1,'NEW iNSTRUMENT ('+
            byte2hex(MenuLib2_mn_environment.curr_pos)+')',
            dialog_background+dialog_hi_text)
  else
    ShowStr(centered_frame_vdest^,_remap_xstart+44,_remap_ystart+1,'NEW iNSTRUMENT ('+
            byte2hex(MenuLib2_mn_environment.curr_pos)+')',
            dialog_background+dialog_text);

  If (_remap_pos = 3) then
    ShowStr(centered_frame_vdest^,_remap_xstart+18,_remap_ystart+_remap_inst_page_len+4,' PATTERN ',
            dialog_hi_text SHL 4)
  else If (remap_selection = 1) then
         ShowStr(centered_frame_vdest^,_remap_xstart+18,_remap_ystart+_remap_inst_page_len+4,' PATTERN ',
            dialog_sel_btn_bck+dialog_sel_btn)
       else
         ShowStr(centered_frame_vdest^,_remap_xstart+18,_remap_ystart+_remap_inst_page_len+4,' PATTERN ',
                 dialog_background+dialog_text);

  If (_remap_pos = 4) then
    ShowStr(centered_frame_vdest^,_remap_xstart+29,_remap_ystart+_remap_inst_page_len+4,' SONG ',
            dialog_hi_text SHL 4)
  else If (remap_selection = 2) then
         ShowStr(centered_frame_vdest^,_remap_xstart+29,_remap_ystart+_remap_inst_page_len+4,' SONG ',
                 dialog_sel_btn_bck+dialog_sel_btn)
       else
         ShowStr(centered_frame_vdest^,_remap_xstart+29,_remap_ystart+_remap_inst_page_len+4,' SONG ',
                 dialog_background+dialog_text);

  If (_remap_pos = 5) then
    ShowStr(centered_frame_vdest^,_remap_xstart+37,_remap_ystart+_remap_inst_page_len+4,' TRACK ',
            dialog_hi_text SHL 4)
  else If (remap_selection = 3) then
         ShowStr(centered_frame_vdest^,_remap_xstart+37,_remap_ystart+_remap_inst_page_len+4,' TRACK ',
                 dialog_sel_btn_bck+dialog_sel_btn)
       else
         ShowStr(centered_frame_vdest^,_remap_xstart+37,_remap_ystart+_remap_inst_page_len+4,' TRACK ',
                 dialog_background+dialog_text);

  If (_remap_pos = 6) then
    ShowStr(centered_frame_vdest^,_remap_xstart+46,_remap_ystart+_remap_inst_page_len+4,' BLOCK ',
            dialog_hi_text SHL 4)
  else If (remap_selection = 4) then
         ShowStr(centered_frame_vdest^,_remap_xstart+46,_remap_ystart+_remap_inst_page_len+4,' BLOCK ',
                 dialog_sel_btn_bck+dialog_sel_btn)
       else If marking then
              ShowStr(centered_frame_vdest^,_remap_xstart+46,_remap_ystart+_remap_inst_page_len+4,' BLOCK ',
                      dialog_background+dialog_text)
            else
              ShowStr(centered_frame_vdest^,_remap_xstart+46,_remap_ystart+_remap_inst_page_len+4,' BLOCK ',
                      dialog_background+dialog_button_dis);
end;

procedure REMAP_instr_control_proc;
begin
  _remap_refresh_proc;
  If (remap_mtype = 1) then
    INSTRUMENT_test(MenuLib1_mn_environment.curr_pos,NULL,count_channel(pattern_hpos),
                    MenuLib1_mn_environment.keystroke,TRUE)
  else
    INSTRUMENT_test(MenuLib2_mn_environment.curr_pos,NULL,count_channel(pattern_hpos),
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
  MenuLib1_mn_environment.ext_proc := NIL;
  MenuLib2_mn_environment.ext_proc := NIL;

  move_to_screen_data := Addr(backup.screen);
  move_to_screen_area[1] := _remap_xstart;
  move_to_screen_area[2] := _remap_ystart;
  move_to_screen_area[3] := _remap_xstart+71+2;
  move_to_screen_area[4] := _remap_ystart+_remap_inst_page_len+5+1;
  move2screen;
end;

procedure override_frame(var dest; x,y: Byte; frame: String; attr: Byte);

procedure override_attr(var dest; x,y: Byte; len: Byte; attr: Byte); assembler;
asm
        push    ebx
        push    ecx
        push    edx
        mov     al,MaxCol
        dec     al
        xor     ah,ah
        xor     ebx,ebx
        mov     bl,2
        mul     bl
        mov     bx,ax
        mov     edi,[dest]
        mov     al,x
        mov     ah,y
        push    eax
        push    ebx
        mov     al,MaxCol
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
        pop     edx
        pop     ecx
        pop     ebx
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

  Move(v_ofs^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;

  HideCursor;
  count_patterns(patterns);

  Move(v_ofs^,vscreen,SizeOf(vscreen));

  centered_frame_vdest := Addr(vscreen);
  centered_frame(_remap_xstart,_remap_ystart,71,_remap_inst_page_len+5,' REMAP iNSTRUMENT ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);

  MenuLib1_mn_environment.curr_pos := remap_ins1;
  MenuLib2_mn_environment.curr_pos := remap_ins2;

  MenuLib1_mn_environment.v_dest := Addr(vscreen);
  MenuLib2_mn_environment.v_dest := Addr(vscreen);
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
    override_frame(centered_frame_vdest^,_remap_xstart+2,_remap_ystart+2,
                   double,dialog_background+dialog_hi_text)
  else override_frame(centered_frame_vdest^,_remap_xstart+2,_remap_ystart+2,
                      single,dialog_background+dialog_text);

  If (_remap_pos = 2) then
    override_frame(centered_frame_vdest^,_remap_xstart+36,_remap_ystart+2,
                   double,dialog_background+dialog_hi_text)
  else override_frame(centered_frame_vdest^,_remap_xstart+36,_remap_ystart+2,
                      single,dialog_background+dialog_text);

  _remap_refresh_proc;
  move_to_screen_data := Addr(vscreen);
  move_to_screen_area[1] := _remap_xstart;
  move_to_screen_area[2] := _remap_ystart;
  move_to_screen_area[3] := _remap_xstart+71+2;
  move_to_screen_area[4] := _remap_ystart+_remap_inst_page_len+5+1;
  move2screen_alt;

  centered_frame_vdest := v_ofs;
  MenuLib1_mn_environment.v_dest := v_ofs;
  MenuLib2_mn_environment.v_dest := v_ofs;

  If NOT _force_program_quit then
    Repeat
      If (_remap_pos = 1) then
        begin
          override_frame(v_ofs^,_remap_xstart+2,_remap_ystart+2,
                         double,dialog_background+dialog_hi_text);
          MenuLib1_mn_setting.menu_attr := dialog_background+dialog_hi_text;
        end
      else
        begin
          override_frame(v_ofs^,_remap_xstart+2,_remap_ystart+2,
                         single,dialog_background+dialog_text);
          MenuLib1_mn_setting.menu_attr := dialog_background+dialog_text;
        end;

      If (_remap_pos = 2) then
        begin
          override_frame(v_ofs^,_remap_xstart+36,_remap_ystart+2,
                         double,dialog_background+dialog_hi_text);
          MenuLib2_mn_setting.menu_attr := dialog_background+dialog_hi_text;
        end
      else
        begin
          override_frame(v_ofs^,_remap_xstart+36,_remap_ystart+2,
                         single,dialog_background+dialog_text);
          MenuLib2_mn_setting.menu_attr := dialog_background+dialog_text;
        end;

      Case _remap_pos of
        1: begin
             remap_ins1 := MenuLib1_Menu(temp_instr_names,_remap_xstart+2,_remap_ystart+2,
                                   remap_ins1,32,_remap_inst_page_len,255,'');
             Case MenuLib1_mn_environment.keystroke of
               kShTAB: _remap_pos := 2+remap_selection;
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
               kTAB: _remap_pos := 2+remap_selection;
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
               kTAB: _remap_pos := 1;
               kShTAB: _remap_pos := 2;
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
               kTAB: _remap_pos := 1;
               kShTAB: _remap_pos := 2;
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
               kTAB: _remap_pos := 1;
               kShTAB: _remap_pos := 2;
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
               kTAB: _remap_pos := 1;
               kShTAB: _remap_pos := 2;
               kENTER: qflag := TRUE;
               kESC: begin _remap_pos := 1; qflag := TRUE; end;
               kCtrlO: begin reset_screen; OCTAVE_CONTROL; GOTO _jmp1; end;
               kF1: begin reset_screen; HELP('remap_dialog'); GOTO _jmp1; end;
             end;
           end;
      end;

      If (_remap_pos < 3) then remap_mtype := _remap_pos else remap_selection := _remap_pos-2;
      _remap_refresh_proc;
      emulate_screen;
    until qflag;

  MenuLib1_mn_environment.ext_proc := NIL;
  MenuLib2_mn_environment.ext_proc := NIL;

  move_to_screen_data := Addr(backup.screen);
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
    ['0'..'9','A'..'Z','&','%','!','@','=','#','$','~','^'],
    ['0'..'9','A'..'F'],
    ['0'..'9','A'..'F'],
    ['0'..'9','A'..'Z','&','%','!','@','=','#','$','~','^'],
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
  If (pos in [1..11]) then
    ShowStr(centered_frame_vdest^,xstart+2,ystart+1,
            'NOTE,iNSTRUMENT,FX Nù1/Nù2 TO FiND',
            dialog_background+dialog_hi_text)
  else ShowStr(centered_frame_vdest^,xstart+2,ystart+1,
               'NOTE,iNSTRUMENT,FX Nù1/Nù2 TO FiND',
               dialog_background+dialog_text);

  If (pos in [12..22]) then
    ShowStr(centered_frame_vdest^,xstart+2,ystart+4,
            'NEW NOTE,iNSTRUMENT,FX Nù1/Nù2',
            dialog_background+dialog_hi_text)
  else ShowStr(centered_frame_vdest^,xstart+2,ystart+4,
               'NEW NOTE,iNSTRUMENT,FX Nù1/Nù2',
               dialog_background+dialog_text);

  ShowCStr2(centered_frame_vdest^,xstart+2,ystart+2,
            '`'+FilterStr(replace_data.event_to_find.note,'?','ú')+'` '+
            '`'+FilterStr(replace_data.event_to_find.inst,'?','ú')+'` '+
            '`'+FilterStr(replace_data.event_to_find.fx_1,'?','ú')+'` '+
            '`'+FilterStr(replace_data.event_to_find.fx_2,'?','ú')+'`',
            dialog_background+dialog_text,
            dialog_input_bckg+dialog_input);

  ShowCStr2(centered_frame_vdest^,xstart+2,ystart+5,
            '`'+FilterStr(replace_data.new_event.note,'?','ú')+'` '+
            '`'+FilterStr(replace_data.new_event.inst,'?','ú')+'` '+
            '`'+FilterStr(replace_data.new_event.fx_1,'?','ú')+'` '+
            '`'+FilterStr(replace_data.new_event.fx_2,'?','ú')+'`',
            dialog_background+dialog_text,
            dialog_input_bckg+dialog_input);

  If (pos = 27) then
    ShowC3Str(centered_frame_vdest^,xstart+2,ystart+7,
              '~[~`'+_on_off[BYTE(replace_prompt)]+'`~]~ PROMPT ON REPLACE',
              dialog_background+dialog_hi_text,
              dialog_background+dialog_text,
              dialog_background+dialog_button)
  else ShowCStr(centered_frame_vdest^,xstart+2,ystart+7,
                '[~'+_on_off[BYTE(replace_prompt)]+'~] PROMPT ON REPLACE',
                dialog_background+dialog_text,
                dialog_background+dialog_button);

  If (pos = 23) then
    ShowStr(centered_frame_vdest^,xstart+2,ystart+9,' PATTERN ',
            dialog_hi_text SHL 4)
  else If (replace_selection = 1) then
         ShowStr(centered_frame_vdest^,xstart+2,ystart+9,' PATTERN ',
            dialog_sel_btn_bck+dialog_sel_btn)
       else
         ShowStr(centered_frame_vdest^,xstart+2,ystart+9,' PATTERN ',
                 dialog_background+dialog_text);

  If (pos = 24) then
    ShowStr(centered_frame_vdest^,xstart+13,ystart+9,' SONG ',
            dialog_hi_text SHL 4)
  else If (replace_selection = 2) then
         ShowStr(centered_frame_vdest^,xstart+13,ystart+9,' SONG ',
                 dialog_sel_btn_bck+dialog_sel_btn)
       else
         ShowStr(centered_frame_vdest^,xstart+13,ystart+9,' SONG ',
                 dialog_background+dialog_text);

  If (pos = 25) then
    ShowStr(centered_frame_vdest^,xstart+21,ystart+9,' TRACK ',
            dialog_hi_text SHL 4)
  else If (replace_selection = 3) then
         ShowStr(centered_frame_vdest^,xstart+21,ystart+9,' TRACK ',
                 dialog_sel_btn_bck+dialog_sel_btn)
       else
         ShowStr(centered_frame_vdest^,xstart+21,ystart+9,' TRACK ',
                 dialog_background+dialog_text);

  If (pos = 26) then
    ShowStr(centered_frame_vdest^,xstart+30,ystart+9,' BLOCK ',
            dialog_hi_text SHL 4)
  else If (replace_selection = 4) then
         ShowStr(centered_frame_vdest^,xstart+30,ystart+9,' BLOCK ',
                 dialog_sel_btn_bck+dialog_sel_btn)
       else If marking then
              ShowStr(centered_frame_vdest^,xstart+30,ystart+9,' BLOCK ',
                      dialog_background+dialog_text)
            else
              ShowStr(centered_frame_vdest^,xstart+30,ystart+9,' BLOCK ',
                      dialog_background+dialog_button_dis);
end;

procedure reset_screen;
begin
  HideCursor;
  move_to_screen_data := Addr(backup.screen);
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
  If (layout = _keyoff_str[pattern_layout]) then temp := NULL
  else For temp := 0 to 12*8+1 do
         If SameName(note_layout[temp],layout) then BREAK;
  _find_note := temp;
end;

function _find_fx(fx_str: Char): Byte; assembler;
asm
        push    ebx
        push    ecx
        push    edi
        lea     edi,[fx_digits]
        mov     ebx,edi
        mov     al,fx_str
        mov     ecx,NM_FX_DIGITS
        repnz   scasb
        sub     edi,ebx
        mov     eax,edi
        dec     eax
        pop     edi
        pop     ecx
        pop     ebx
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
  _cancel: Boolean;
  chr: Char;
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
  If (replace_selection = 4) and NOT marking then replace_selection := 1;
  pos := 1;
  qflag := FALSE;
  _charset[1] := ['A',UpCase(b_note),'C'..'G'];

_jmp1:
  If _force_program_quit then EXIT;

  Move(v_ofs^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;

  HideCursor;
  count_patterns(patterns);

  Move(v_ofs^,vscreen,SizeOf(vscreen));
  centered_frame_vdest := Addr(vscreen);
  centered_frame(xstart,ystart,38,10,' REPLACE ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);

  move_to_screen_data := Addr(vscreen);
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+38+2;
  move_to_screen_area[4] := ystart+10+1;

  refresh;
  ShowStr(centered_frame_vdest^,xstart+1,ystart+8,
          ExpStrL('',38-1,''),
          dialog_background+dialog_context_dis);

  move2screen_alt;

  centered_frame_vdest := v_ofs;

  If NOT _force_program_quit then
    Repeat
      If (pos in [1..22,27]) then ThinCursor
      else HideCursor;

      Case pos of
        1..11: begin
                 GotoXY(xstart+1+pos6[pos],ystart+2);
                 fkey := getkey;

                 Case fkey of
                   kTAB: pos := 12;
                   kShTAB: pos := 22+replace_selection;
                   kLEFT: If (pos > 1) then Dec(pos);
                   kRIGHT: Inc(pos);
                   kHOME: pos := 1;
                   kEND: pos := 11;
                   kDOWN: Inc(pos,11);
                   kESC: qflag := TRUE;
                   kENTER: begin pos := 22+replace_selection; qflag := TRUE; end;
                   kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;

                   kCtBkSp: begin
                              replace_data.event_to_find.note := 'úúú';
                              replace_data.event_to_find.inst := 'úú';
                              replace_data.event_to_find.fx_1 := 'úúú';
                              replace_data.event_to_find.fx_2 := 'úúú';
                            end;

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
                                      If (note[1] in ['E','F',b_note]) and
                                         (note[2] = '#') then
                                        note[2] := '-';

                                      If (note[1] <> 'C') and (note[3] = '9') then
                                        note[3] := '8';
                                    end;

                                 2: If NOT ((note[1] in ['E','F',b_note]) and
                                            (chr = '#')) then
                                      note[2] := chr;

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
                    kTAB,kDOWN: pos := 27;
                    kShTAB: pos := 1;
                    kLEFT: Dec(pos);
                    kRIGHT: If (pos < 22) then Inc(pos) else pos := 27;
                    kHOME: pos := 12;
                    kEND: pos := 22;
                    kUP: Dec(pos,11);
                    kESC: qflag := TRUE;
                    kENTER: begin pos := 22+replace_selection; qflag := TRUE; end;
                    kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;

                    kCtBkSp: begin
                               replace_data.new_event.note := 'úúú';
                               replace_data.new_event.inst := 'úú';
                               replace_data.new_event.fx_1 := 'úúú';
                               replace_data.new_event.fx_2 := 'úúú';
                             end;

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
                                       If (note[1] in ['E','F',b_note]) and
                                          (note[2] = '#') then
                                         note[2] := '-';

                                       If (note[1] <> 'C') and (note[3] = '9') then
                                         note[3] := '8';
                                     end;

                                  2: If NOT ((note[1] in ['E','F',b_note]) and
                                             (chr = '#')) then
                                       note[2] := chr;

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
                kLEFT: pos := 22;
                kUP,kShTAB: pos := 12;
                kTAB: pos := 22+replace_selection;
                kENTER: qflag := TRUE;
                kSPACE: replace_prompt := NOT replace_prompt;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;

        23: begin
              fkey := getkey;
              Case fkey of
                kHOME: pos := 23;
                kEND,kLEFT: If marking then pos := 26 else pos := 25;
                kRIGHT: pos := 24;
                kTAB: pos := 1;
                kShTAB: pos := 27;
                kENTER: qflag := TRUE;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;

        24: begin
              fkey := getkey;
              Case fkey of
                kHOME: pos := 23;
                kEND: If marking then pos := 26 else pos := 25;
                kLEFT: pos := 23;
                kRIGHT: pos := 25;
                kTAB: pos := 1;
                kShTAB: pos := 27;
                kENTER: qflag := TRUE;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;

        25: begin
              fkey := getkey;
              Case fkey of
                kHOME: pos := 23;
                kEND: If marking then pos := 26 else pos := 25;
                kLEFT: pos := 24;
                kRIGHT: If marking then pos := 26 else pos := 23;
                kTAB: pos := 1;
                kShTAB: pos := 27;
                kENTER: qflag := TRUE;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;

        26: begin
              fkey := getkey;
              Case fkey of
                kHOME: pos := 23;
                kEND: pos := 26;
                kLEFT: pos := 25;
                kRIGHT: pos := 23;
                kTAB: pos := 1;
                kShTAB: pos := 27;
                kENTER: qflag := TRUE;
                kESC: begin pos := 1; qflag := TRUE; end;
                kF1: begin reset_screen; HELP('replace_dialog'); GOTO _jmp1; end;
              end;
            end;
      end;

      If (pos in [23..26]) then replace_selection := pos-22;
      refresh;
      emulate_screen;
    until qflag;

  HideCursor;
  move_to_screen_data := Addr(backup.screen);
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
      PATTERN_position_preview(NULL,NULL,NULL,0);

      event_to_find.note := FilterStr(replace_data.event_to_find.note,'ú','?');
      event_to_find.inst := FilterStr(replace_data.event_to_find.inst,'ú','?');
      event_to_find.fx_1 := FilterStr(replace_data.event_to_find.fx_1,'ú','?');
      event_to_find.fx_2 := FilterStr(replace_data.event_to_find.fx_2,'ú','?');

      new_event.note := FilterStr(replace_data.new_event.note,'ú','?');
      new_event.inst := FilterStr(replace_data.new_event.inst,'ú','?');
      new_event.fx_1 := FilterStr(replace_data.new_event.fx_1,'ú','?');
      new_event.fx_2 := FilterStr(replace_data.new_event.fx_2,'ú','?');

      Case pos-22 of
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

                If (chunk.note <> 0) and
                   (new_event.note <> '???') then
                  Case chunk.note of
                    1..12*8+1: If SameName(event_to_find.note,note_layout[chunk.note]) then
                                 chunk.note := _find_note(_wildcard_str(new_event.note,note_layout[chunk.note]));

                    fixed_note_flag+
                    1..
                    fixed_note_flag+
                    12*8+1: If SameName(event_to_find.note,note_layout[chunk.note-fixed_note_flag]) then
                              chunk.note := fixed_note_flag+_find_note(_wildcard_str(new_event.note,note_layout[chunk.note-fixed_note_flag]));

                    NULL: If (FilterStr(event_to_find.note,'?','ú') = _keyoff_str[pattern_layout]) and
                             NOT (SYSTEM.Pos('?',new_event.note) <> 0) then
                            chunk.note := _find_note(new_event.note);
                  end;

                If (chunk.instr_def <> 0) and
                   (new_event.inst <> '??') then
                  If SameName(event_to_find.inst,byte2hex(chunk.instr_def)) and
                     SameName(event_to_find.fx_1,fx_digits[chunk.effect_def]+byte2hex(chunk.effect)) and
                     SameName(event_to_find.fx_2,fx_digits[chunk.effect_def2]+byte2hex(chunk.effect2)) then
                    chunk.instr_def := Str2num(_wildcard_str(new_event.inst,byte2hex(chunk.instr_def)),16);

                If (chunk.effect_def+chunk.effect <> 0) and
                   (new_event.fx_1 <> '???') then
                  If SameName(event_to_find.inst,byte2hex(chunk.instr_def)) and
                     SameName(event_to_find.fx_1,fx_digits[chunk.effect_def]+byte2hex(chunk.effect)) and
                     SameName(event_to_find.fx_2,fx_digits[chunk.effect_def2]+byte2hex(chunk.effect2)) then
                    begin
                      chunk.effect_def := _find_fx(_wildcard_str(new_event.fx_1[1],fx_digits[chunk.effect_def])[1]);
                      chunk.effect := Str2num(_wildcard_str(new_event.fx_1[2]+new_event.fx_1[3],byte2hex(chunk.effect)),16);
                    end;

                If (chunk.effect_def2+chunk.effect2 <> 0) and
                   (new_event.fx_2 <> '???') then
                  If SameName(event_to_find.inst,byte2hex(chunk.instr_def)) and
                     SameName(event_to_find.fx_1,fx_digits[chunk.effect_def]+byte2hex(chunk.effect)) and
                     SameName(event_to_find.fx_2,fx_digits[chunk.effect_def2]+byte2hex(chunk.effect2)) then
                    begin
                      chunk.effect_def2 := _find_fx(_wildcard_str(new_event.fx_2[1],fx_digits[chunk.effect_def2])[1]);
                      chunk.effect2 := Str2num(_wildcard_str(new_event.fx_2[2]+new_event.fx_2[3],byte2hex(chunk.effect2)),16);
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

      PATTERN_position_preview(NULL,NULL,NULL,NULL);
      replay_forbidden := status_backup.replay_forbidden;
      play_status := status_backup.play_status;
    end;

  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(pattern_page);
end;

procedure POSITIONS_reset;
begin
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

function effect_str(effect_def,effect: Byte): String;
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
            ef_ex_cmd_FineVibr:   effect_str := 'VibrFine';
            ef_ex_cmd_FineTrem:   effect_str := 'TremFine';
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

const
  _perc_char: array[1..5] of Char = ' ¡¢£¤';
  _panning: array[0..3] of String = ('','``','``','``');
  _connection: array[0..1] of String = ('FM','AM');
  _off_on: array[1..4,0..1] of Char = ('úT','úV','úK','úS');

var
  temp,temp2,atr1,atr2,atr3,atr4,xstart,ystart: Byte;
  temps,temps2: String;
  old_debugging,old_replay_forbidden: Boolean;
  old_play_status: tPLAY_STATUS;
  _reset_state: Boolean;

begin { DEBUG_INFO }
  Move(v_ofs^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;

  HideCursor;
  centered_frame(xstart,ystart,83,songdata.nm_tracks+6,'',
                 debug_info_bckg+debug_info_border,
                 debug_info_bckg,double);

  _reset_state := FALSE;
  Repeat
    If space_pressed and (play_status <> isStopped) then
      If NOT _reset_state then
        begin
          _reset_state := TRUE;
          old_debugging := debugging;
          old_play_status := play_status;
          old_replay_forbidden := replay_forbidden;
          debugging := TRUE;
          play_status := isPlaying;
          replay_forbidden := FALSE;
        end;

    If NOT shift_pressed then
      begin
        ShowCStr(v_ofs^,xstart+2,ystart+1,
                 '     TRACK     ~³~          iNSTRUMENT          ~³~NOTE~³ ~FX Nù1~ ³ ~FX Nù2~ ³~FREQ~³ ~VOL',
                 debug_info_bckg+debug_info_topic,debug_info_bckg+debug_info_border);
        ShowStr(v_ofs^,xstart+2,ystart+2,
                'ÄÄÂÄÄÂÄÄÄÂÄÄÂÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÂÄÄ',
                debug_info_bckg+debug_info_border);
        ShowStr(v_ofs^,xstart+2,ystart+songdata.nm_tracks+3,
                'ÄÄÁÄÄÁÄÄÄÁÄÄÁÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÁÄÄ',
                debug_info_bckg+debug_info_border);
      end
    else begin
           ShowCStr(v_ofs^,xstart+2,ystart+1,
                   'TRACK~³~iNS~³~NOTE~³ ~FX Nù1~ ³ ~FX Nù2~ ³~FREQ~³~CN/FB/ADSR/WF/KSL/MUL/TRM/ViB/KSR/EG~³ ~VOL',
                    debug_info_bckg+debug_info_topic,debug_info_bckg+debug_info_border);
           ShowStr(v_ofs^,xstart+2,ystart+2,
                   'ÄÄÂÄÄÅÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÂÄÄ',
                   debug_info_bckg+debug_info_border);
           ShowStr(v_ofs^,xstart+2,ystart+songdata.nm_tracks+3,
                   'ÄÄÁÄÄÁÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÁÄÄ',
                   debug_info_bckg+debug_info_border);
         end;

    If NOT play_single_patt and NOT replay_forbidden and
       repeat_pattern then temps := '~~'
    else temps := '';

    If NOT play_single_patt then
      ShowCStr(v_ofs^,
               xstart+2,ystart+songdata.nm_tracks+4,
               '~ORDER/PATTERN/ROW~  '+byte2hex(current_order)+'/'+
               byte2hex(current_pattern)+'/'+
               byte2hex(current_line),
               debug_info_bckg+debug_info_txt,
               debug_info_bckg+debug_info_hi_txt)
    else
      ShowCStr(v_ofs^,
               xstart+2,ystart+songdata.nm_tracks+4,
               '~ORDER/PATTERN/ROW~  --/'+
               byte2hex(current_pattern)+'/'+
               byte2hex(current_line),
               debug_info_bckg+debug_info_txt,
               debug_info_bckg+debug_info_hi_txt);

    ShowCStr(v_ofs^,
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

    ShowCStr(v_ofs^,
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

    ShowCStr(v_ofs^,
             xstart+36,ystart+songdata.nm_tracks+4,
             '~TREMOLO/ViBRATO DEPTH~ '+
             temps+'/'+temps2,
             debug_info_bckg+debug_info_txt,
             debug_info_bckg+debug_info_hi_txt);

    ShowCStr(v_ofs^,
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

    ShowCStr(v_ofs^,
             xstart+74,ystart+songdata.nm_tracks+4,
             temps,
             debug_info_bckg+debug_info_txt,
             debug_info_bckg+debug_info_hi_txt);

    For temp := 1 to songdata.nm_tracks do
      begin
        If channel_flag[temp] then
          If event_new[temp] then atr1 := debug_info_bckg+debug_info_hi_txt
          else atr1 := debug_info_bckg+debug_info_txt
        else atr1 := debug_info_bckg+debug_info_txt_hid;

        If channel_flag[temp] then
          If event_new[temp] then atr2 := debug_info_bckg+debug_info_hi_txt
          else atr2 := debug_info_bckg+debug_info_txt
        else atr2 := debug_info_bckg+debug_info_txt_hid;

        If channel_flag[temp] then
          If event_new[temp] then atr3 := debug_info_bckg+debug_info_hi_car
          else atr3 := debug_info_bckg+debug_info_car
        else atr3 := debug_info_bckg+debug_info_txt_hid;

        If channel_flag[temp] then
          If event_new[temp] then atr4 := debug_info_bckg+debug_info_hi_mod
          else atr4 := debug_info_bckg+debug_info_mod
        else atr4 := debug_info_bckg+debug_info_txt_hid;

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

        ShowStr(v_ofs^,xstart+1,ystart+temp+2,
                temps,
                debug_info_bckg+debug_info_perc);

        ShowCStr(v_ofs^,xstart+2,ystart+temp+2,
                 ExpStrL(Num2str(temp,10),2,' '),
                 atr1,
                 debug_info_bckg+debug_info_txt_hid);

        If NOT shift_pressed then
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

        If NOT shift_pressed then
          begin
            If pan_lock[temp] then
              ShowC3Str(v_ofs^,xstart+4,ystart+temp+2,
                        '~³~'+_panning[temp2]+'~³~',
                        atr2,
                        debug_info_bckg+debug_info_border,
                        debug_info_bckg+debug_info_txt_hid)
            else ShowC3Str(v_ofs^,xstart+4,ystart+temp+2,
                           '~³~'+_panning[temp2]+'~³~',
                           atr3,
                           debug_info_bckg+debug_info_border,
                           debug_info_bckg+debug_info_txt_hid);

            ShowC3Str(v_ofs^,xstart+8,ystart+temp+2,
                      temps2+'~³~',
                      atr2,
                      debug_info_bckg+debug_info_border,
                      debug_info_bckg+debug_info_txt_hid);

            If NOT (is_4op_chan(temp) and
                   (temp in [1,3,5,10,12,14])) then
              ShowCStr(v_ofs^,xstart+18,ystart+temp+2,
                       temps+'~³~'+
                       note_str(event_table[temp].note,temp)+'~³~'+
                       effect_str(event_table[temp].effect_def,
                                  event_table[temp].effect)+'~³~'+
                       effect_str(event_table[temp].effect_def2,
                                  event_table[temp].effect2)+'~³~'+
                       ExpStrL(Num2str(freqtable2[temp] AND $1fff,16),4,'0')+'~³~',
                       atr1,
                       debug_info_bckg+debug_info_border)
            else
              ShowCStr(v_ofs^,xstart+18,ystart+temp+2,
                       temps+'~³~    ~³~'+
                       effect_str(event_table[temp].effect_def,
                                  event_table[temp].effect)+'~³~'+
                       effect_str(event_table[temp].effect_def2,
                                  event_table[temp].effect2)+'~³~    ~³~',
                       atr1,
                       debug_info_bckg+debug_info_border);

            If NOT (percussion_mode and (temp in [17..20])) then
              ShowCStr(v_ofs^,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~³~',
                       atr3,
                       debug_info_bckg+debug_info_border)
            else
              ShowCStr(v_ofs^,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~³~',
                       debug_info_bckg+debug_info_bckg SHR 4,
                       debug_info_bckg+debug_info_border);
          end
        else
          begin
            If pan_lock[temp] then
              ShowC3Str(v_ofs^,xstart+4,ystart+temp+2,
                        '~³~'+_panning[temp2]+'~³~',
                        atr2,
                        debug_info_bckg+debug_info_border,
                        debug_info_bckg+debug_info_txt_hid)
            else ShowC3Str(v_ofs^,xstart+4,ystart+temp+2,
                           '~³~'+_panning[temp2]+'~³~',
                           atr3,
                           debug_info_bckg+debug_info_border,
                           debug_info_bckg+debug_info_txt_hid);

            If NOT (is_4op_chan(temp) and
                   (temp in [1,3,5,10,12,14])) then
              ShowCStr(v_ofs^,xstart+8,ystart+temp+2,
                       temps+'~³~'+
                       note_str(event_table[temp].note,temp)+'~³~'+
                       effect_str(event_table[temp].effect_def,
                                  event_table[temp].effect)+'~³~'+
                       effect_str(event_table[temp].effect_def2,
                                  event_table[temp].effect2)+'~³~'+
                       ExpStrL(Num2str(freqtable2[temp] AND $1fff,16),4,'0')+'~³~',
                       atr1,debug_info_bckg+debug_info_border)
            else
              ShowCStr(v_ofs^,xstart+8,ystart+temp+2,
                       temps+'~³~    ~³~'+
                       effect_str(event_table[temp].effect_def,
                                  event_table[temp].effect)+'~³~'+
                       effect_str(event_table[temp].effect_def2,
                                  event_table[temp].effect2)+'~³~'+
                       '    ~³~',
                       atr1,debug_info_bckg+debug_info_border);

            If NOT (percussion_mode and (temp in [17..20])) then
              ShowStr(v_ofs^,xstart+40,ystart+temp+2,
                      _connection[fmpar_table[temp].connect]+' '+
                      Num2str(fmpar_table[temp].feedb,16)+' ',
                      atr1)
            else
              ShowStr(v_ofs^,xstart+40,ystart+temp+2,
                      ExpStrL('',5,' '),
                      atr1);

            If NOT (percussion_mode and (temp in [17..20])) then
              ShowCStr(v_ofs^,xstart+45,ystart+temp+2,
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
                       debug_info_bckg+debug_info_border)
            else
              ShowCStr(v_ofs^,xstart+45,ystart+temp+2,
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
                       debug_info_bckg+debug_info_bckg SHR 4,
                       debug_info_bckg+debug_info_border);

            ShowCStr(v_ofs^,xstart+61,ystart+temp+2,
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
                     debug_info_bckg+debug_info_border);

            If NOT (percussion_mode and (temp in [17..20])) then
              ShowCStr(v_ofs^,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~³~',
                       atr3,
                       debug_info_bckg+debug_info_border)
            else
              ShowCStr(v_ofs^,xstart+77,ystart+temp+2,
                       ExpStrL(Num2str(carrier_vol[temp],16),2,'0')+'~³~',
                       debug_info_bckg+debug_info_bckg SHR 4,
                       debug_info_bckg+debug_info_border);
          end;

        ShowCStr(v_ofs^,xstart+80,ystart+temp+2,
                 ExpStrL(Num2str(modulator_vol[temp],16),2,'0'),
                 atr4,debug_info_bckg+debug_info_border);
      end;

    If (@trace_update_proc <> NIL) then trace_update_proc // later put this into emulate_screen
    else If (play_status = isPlaying) then
           begin
             PATTERN_ORDER_page_refresh(pattord_page);
             PATTERN_page_refresh(pattern_page);
           end;
    keyboard_reset_buffer;
    emulate_screen;
  until NOT ((scankey(SC_LCTRL) or scankey(SC_RCTRL)) and { CTRL }
             (scankey(SC_LALT) or scankey(SC_RALT))); { ALT }

  If _reset_state then
    begin
      debugging := old_debugging;
      play_status := old_play_status;
      replay_forbidden := old_replay_forbidden;
    end;

  move_to_screen_data := Addr(backup.screen);
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+83+2;
  move_to_screen_area[4] := ystart+songdata.nm_tracks+6+1;
  move2screen;
end;

procedure LINE_MARKING_SETUP;
begin
  dl_setting.all_enabled := TRUE;
  mark_line := Dialog('USE CURSOR KEYS OR DiRECTLY PRESS ~HOTKEY~ TO SETUP COUNTER$',
                      '~1~$~2~$~3~$~4~$~5~$~6~$~7~$~8~$~9~$10$11$12$13$14$15$16$',
                      ' LiNE MARKiNG SETUP ',mark_line);
  dl_setting.all_enabled := FALSE;
end;

procedure OCTAVE_CONTROL;
begin
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
  songdata_crc := Update32(songdata,SizeOf(songdata),0);
  count_order(temp1);
  count_patterns(temp2);
  count_instruments(temp3);
  pos := 1;

_jmp1:
  If _force_program_quit then EXIT;

  Move(v_ofs^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;

  HideCursor;

  Move(v_ofs^,vscreen,SizeOf(vscreen));
  centered_frame_vdest := Addr(vscreen);
  centered_frame(xstart,ystart,79,26,' SONG VARiABLES ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,
                 double);
  centered_frame_vdest := v_ofs;

  move_to_screen_data := Addr(vscreen);
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+79+2;
  move_to_screen_area[4] := ystart+26+1;
  move2screen_alt;

  move_to_screen_area[1] := xstart+1;
  move_to_screen_area[2] := ystart+1;
  move_to_screen_area[3] := xstart+78;
  move_to_screen_area[4] := ystart+25;

  ShowCStr(vscreen,xstart+2,ystart+6,
           'iNSTRUMENTS: ~'+Num2str(temp3,10)+'/255~  ',
           dialog_background+dialog_text,
           dialog_background+dialog_context_dis);

  ShowCStr(vscreen,xstart+25,ystart+6,
           'PATTERNS: ~'+Num2str(temp2,10)+'/'+Num2str(max_patterns,10)+'~  ',
           dialog_background+dialog_text,
           dialog_background+dialog_context_dis);

  ShowCStr(vscreen,xstart+2,ystart+7,
           'ORDER LiST ENTRiES: ~'+Num2str(temp1,10)+'/128~  ',
           dialog_background+dialog_text,
           dialog_background+dialog_context_dis);

  ShowStr(vscreen,xstart+51,ystart+2,
           'iNiTiAL LOCK SETTiNGS',dialog_background+dialog_context_dis);
  ShowStr(vscreen,xstart+51,ystart+3,
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

      ShowStr(vscreen,xstart+34,ystart+12,'4-OP TRACK EXT.',attr[78]);
      For temp := 1 to 6 do
        If (songdata.flag_4op OR (1 SHL PRED(temp)) = songdata.flag_4op) then
          ShowCStr(vscreen,xstart+34,ystart+13+temp-1,
                   '[~û~] ñ'+_4op_str[temp],
                   dialog_background+dialog_text,
                   dialog_background+dialog_button)
        else
          ShowCStr(vscreen,xstart+34,ystart+13+temp-1,
                   '[~ ~] ñ'+_4op_str[temp],
                   dialog_background+dialog_text,
                   dialog_background+dialog_button);

    ShowStr(vscreen,xstart+51,ystart+4,'PANNiNG',
            attr[18]);
    ShowStr(vscreen,xstart+51,ystart+5,'©    ª',
            attr[18]);

    ShowVStr(vscreen,xstart+64,ystart+4,'M',attr[84]);
    ShowVStr(vscreen,xstart+68,ystart+4,'C',attr[85]);
    ShowVStr(vscreen,xstart+72,ystart+4,'V',attr[86]);
    ShowVStr(vscreen,xstart+76,ystart+4,'P',attr[87]);
    ShowVStr(vscreen,xstart+65,ystart+4,#10, attr[84]);
    ShowVStr(vscreen,xstart+69,ystart+4,#10, attr[85]);
    ShowVStr(vscreen,xstart+73,ystart+4,'+', attr[86]);
    ShowVStr(vscreen,xstart+77,ystart+4,'+', attr[87]);

      For temp := 1 to 20 do
        If (temp <= songdata.nm_tracks) then
          begin
            Case songdata.lock_flags[temp] AND 3 of
              0: ShowCStr(vscreen,xstart+51,ystart+6+temp-1,
                          '~ú~ú~~ú~ú~',
                          dialog_background+dialog_text,
                          dialog_background+dialog_button);
              1: ShowCStr(vscreen,xstart+51,ystart+6+temp-1,
                          '~~~ú~úú~ú~',
                          dialog_background+dialog_text,
                          dialog_background+dialog_button);
              2: ShowCStr(vscreen,xstart+51,ystart+6+temp-1,
                          '~ú~úú~ú~~~',
                          dialog_background+dialog_text,
                          dialog_background+dialog_button);
            end;
            ShowCStr(vscreen,xstart+60,ystart+6+temp-1,
                     '~'+ExpStrL(Num2str(temp,10),2,' ')+'~  '+
                     _on_off[songdata.lock_flags[temp] SHR 3 AND 1]+' ~ö~ '+
                     _on_off[songdata.lock_flags[temp] SHR 2 AND 1]+' ~ö~ '+
                     _on_off[songdata.lock_flags[temp] SHR 4 AND 1]+' ~ö~ '+
                     _on_off[songdata.lock_flags[temp] SHR 5 AND 1],
                     dialog_background+dialog_button,
                     dialog_background+dialog_context_dis);
          end
        else ShowStr(vscreen,xstart+51,ystart+6+temp-1,
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

      ShowVStr(vscreen,xstart+50,ystart+6,
               ExpStrR(temps,20,' '),
               dialog_background+dialog_context_dis);

      ShowStr(vscreen,xstart+2,ystart+1,
        'SONGNAME',attr[1]);
      ShowStr(vscreen,xstart+2,ystart+3,
        'COMPOSER',attr[2]);
      ShowStr(vscreen,xstart+2,ystart+9,
        'SONG TEMPO',attr[3]);
      ShowStr(vscreen,xstart+2,ystart+10,
        'SONG SPEED',attr[4]+attr[5]);

      ShowCStr(vscreen,xstart+26,ystart+10,
        '[ ] ~update~',dialog_background+dialog_text,attr[4]+attr[5]);

      ShowCStr(vscreen,xstart+2,ystart+11,
        '~MACRODEF.~ ',dialog_background+dialog_text,attr[17]);

      If speed_update then ShowStr(vscreen,xstart+27,ystart+10,'û',dialog_background+dialog_button)
      else ShowStr(vscreen,xstart+27,ystart+10,' ',dialog_background+dialog_button);

      ShowCStr(vscreen,xstart+2,ystart+13,
        '[ ] ~TRACK VOLUME LOCK~',dialog_background+dialog_text,attr[6]);
      ShowCStr(vscreen,xstart+2,ystart+14,
        '[ ] ~TRACK PANNiNG LOCK~',dialog_background+dialog_text,attr[7]);
      ShowCStr(vscreen,xstart+2,ystart+15,
        '[ ] ~VOLUME PEAK LOCK~',dialog_background+dialog_text,attr[8]);

      If lockvol then ShowStr(vscreen,xstart+3,ystart+13,'û',dialog_background+dialog_button)
      else ShowStr(vscreen,xstart+3,ystart+13,' ',dialog_background+dialog_button);

      If panlock then ShowStr(vscreen,xstart+3,ystart+14,'û',dialog_background+dialog_button)
      else ShowStr(vscreen,xstart+3,ystart+14,' ',dialog_background+dialog_button);

      If lockVP then ShowStr(vscreen,xstart+3,ystart+15,'û',dialog_background+dialog_button)
      else ShowStr(vscreen,xstart+3,ystart+15,' ',dialog_background+dialog_button);

      ShowStr(vscreen,xstart+2,ystart+17,
        'TREMOLO DEPTH',attr[9]+attr[10]);

      ShowStr(vscreen,xstart+2,ystart+18,
        '( ) 1 dB',dialog_background+dialog_text);
      ShowStr(vscreen,xstart+2,ystart+19,
        '( ) 4.8 dB',dialog_background+dialog_text);

      If (tremolo_depth = 0) then ShowVStr(vscreen,xstart+3,ystart+18,'û ',dialog_background+dialog_button)
      else ShowVStr(vscreen,xstart+3,ystart+18,' û',dialog_background+dialog_button);

      ShowStr(vscreen,xstart+18,ystart+17,
        'ViBRATO DEPTH',attr[11]+attr[12]);

      ShowStr(vscreen,xstart+18,ystart+18,
        '( ) 7%',dialog_background+dialog_text);
      ShowStr(vscreen,xstart+18,ystart+19,
        '( ) 14%',dialog_background+dialog_text);

      If (vibrato_depth = 0) then ShowVStr(vscreen,xstart+19,ystart+18,'û ',dialog_background+dialog_button)
      else ShowVStr(vscreen,xstart+19,ystart+18,' û',dialog_background+dialog_button);

      ShowStr(vscreen,xstart+2,ystart+21,
        'PATTERN LENGTH',attr[13]);
      ShowStr(vscreen,xstart+2,ystart+22,
        'NUMBER OF TRACKS',attr[14]);

      ShowCStr(vscreen,xstart+2,ystart+24,
        '[ ] ~PERCUSSiON TRACK EXTENSiON ( ,¡,¢,£,¤)~',dialog_background+dialog_text,attr[15]);

      If percussion_mode then ShowStr(vscreen,xstart+3,ystart+24,'û',dialog_background+dialog_button)
      else ShowStr(vscreen,xstart+3,ystart+24,' ',dialog_background+dialog_button);

      ShowCStr(vscreen,xstart+2,ystart+25,
        '[ ] ~VOLUME SCALiNG~',dialog_background+dialog_text,attr[16]);

      If volume_scaling then ShowStr(vscreen,xstart+3,ystart+25,'û',dialog_background+dialog_button)
      else ShowStr(vscreen,xstart+3,ystart+25,' ',dialog_background+dialog_button);

      is_setting.append_enabled := TRUE;
      is_environment.locate_pos := 1;

      ShowStr(vscreen,xstart+2,ystart+2,
              ExpStrR(songdata.songname,46,' '),
              dialog_input_bckg+dialog_input);

      ShowStr(vscreen,xstart+2,ystart+4,
              ExpStrR(songdata.composer,46,' '),
              dialog_input_bckg+dialog_input);

      ShowCStr(vscreen,xstart+13,ystart+9,
               ExpStrR(Num2str(songdata.tempo,10),4,' ')+
               '~ {1..255}~',
               dialog_input_bckg+dialog_input,
               dialog_background+dialog_text);

      ShowCStr(vscreen,xstart+13,ystart+10,
               ExpStrR(Num2str(songdata.speed,16),4,' ')+
               '~ {1..FF}~',
               dialog_input_bckg+dialog_input,
               dialog_background+dialog_text);

      ShowCStr(vscreen,xstart+13,ystart+11,
               '~'+ExpStrR(Num2str(songdata.macro_speedup,10),4,' ')+'~'+
               ' {1..'+Num2str(calc_max_speedup(songdata.tempo),10)+'}   ',
               dialog_background+dialog_text,
               dialog_input_bckg+dialog_input);

      ShowCStr(vscreen,xstart+19,ystart+21,
               ExpStrR(Num2str(songdata.patt_len,10),3,' ')+
               '~ {1..256}~',
               dialog_input_bckg+dialog_input,
               dialog_background+dialog_text);

      ShowCStr(vscreen,xstart+19,ystart+22,
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
      emulate_screen;
    until (is_environment.keystroke = kESC) or
          (is_environment.keystroke = kF1);

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

  HideCursor;
  Move(old_keys,is_setting.terminate_keys,SizeOf(old_keys));
  move_to_screen_data := Addr(backup.screen);
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

procedure _showstr(var dest; x,y: Byte; str: String; attr: Byte); assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     edi,[dest]
        mov     esi,[str]
        xor     eax,eax
        xor     ebx,ebx
        mov     al,MaxCol
        mov     bl,y
        dec     bl
        mul     bl
        mov     bl,x
        dec     bl
        mov     edx,eax
        add     edx,ebx
        shl     edx,1
        lodsb
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@2
        add     edi,edx
        mov     ah,attr
@@1:    lodsb
        stosw
        loop    @@1
@@2:    pop        edi
        pop        esi
        pop        edx
        pop        ecx
        pop        ebx
end;

procedure _preview_indic_proc(state: Byte);
begin
  Case state of
    0: _showstr(_pip_dest^,_pip_xloc,_pip_yloc,
                ' PREViEW ',
                macro_background+macro_text_dis);
    1: _showstr(_pip_dest^,_pip_xloc,_pip_yloc,
                ' PREViEW ',
                macro_background+macro_text);
    2: _showstr(_pip_dest^,_pip_xloc,_pip_yloc,
                ' PREViEW ',
                NOT (macro_background+macro_text));
  end;

  If _pip_loop and (state <> 0) then
    _showstr(_pip_dest^,_pip_xloc,_pip_yloc-1,
             ' LOOP',
             macro_background+macro_text)
  else _showstr(_pip_dest^,_pip_xloc,_pip_yloc-1,
                ' LOOP',
                macro_background+macro_text_dis);
end;

const
  _m_4op_chan: array[1..6] of Byte = (2,4,6,11,13,15);
  _m_perc_sim_chan: array[19..20] of Byte = (18,17);

var
  _m_temp,_m_temp2,_m_temp3,_m_temp5: Byte;
  _m_valid_key,_m_temp4: Boolean;
  _m_chan_handle: array[1..18] of Byte;
  _m_channels: Byte;
  _m_flag_4op_backup: Byte;
  _m_event_table_bak: array[1..20] of tCHUNK;
  _m_freq_table_bak,_m_freqtable2_bak: array[1..20] of Word;
  _m_keyoff_loop_bak: array[1..20] of Boolean;
  _m_channel_flag_backup: array[1..20] of Boolean;
  _m_fmpar_table_backup: array[1..20] of tFM_PARAMETER_TABLE;
  _m_volume_table_backup: array[1..20] of Word;
  _m_pan_lock_backup: array[1..20] of Boolean;
  _m_volume_lock_backup: array[1..20] of Boolean;
  _m_peak_lock_backup: array[1..20] of Boolean;
  _m_panning_table_backup: array[1..20] of Byte;
  _m_status_backup: Record
                      replay_forbidden: Boolean;
                      play_status: tPLAY_STATUS;
                    end;

var
  _bak_arpeggio_table,
  _bak_vibrato_table: Byte;
  _bak_common_flag: Byte;
  _bak_volume_scaling: Boolean;

procedure _macro_preview_init(state,instr2: Byte);
begin
  Case state of
    0: begin
         songdata.flag_4op := _m_flag_4op_backup;
         Move(_m_fmpar_table_backup,fmpar_table,SizeOf(fmpar_table));
         Move(_m_volume_table_backup,volume_table,SizeOf(volume_table));
         Move(_m_panning_table_backup,panning_table,SizeOf(panning_table));
         songdata.instr_macros[current_inst].arpeggio_table := _bak_arpeggio_table;
         songdata.instr_macros[current_inst].vibrato_table := _bak_vibrato_table;
         songdata.common_flag := _bak_common_flag;
         volume_scaling := _bak_volume_scaling;
         reset_player;

         Move(_m_channel_flag_backup,channel_flag,SizeOf(channel_flag));
         Move(_m_event_table_bak,event_table,SizeOf(event_table));
         Move(_m_pan_lock_backup,pan_lock,SizeOf(pan_lock));
         Move(_m_volume_lock_backup,volume_lock,SizeOf(volume_lock));
         Move(_m_peak_lock_backup,peak_lock,SizeOf(volume_lock));

         really_no_status_refresh := FALSE;
         Move(_m_freq_table_bak,freq_table,SizeOf(freq_table));
         Move(_m_freqtable2_bak,freqtable2,SizeOf(freqtable2));
         Move(_m_keyoff_loop_bak,keyoff_loop,SizeOf(keyoff_loop));
         FillChar(macro_table,SizeOf(macro_table),0);
         replay_forbidden := _m_status_backup.replay_forbidden;
         play_status := _m_status_backup.play_status;
       end;

    1: begin
         _m_status_backup.replay_forbidden := replay_forbidden;
         _m_status_backup.play_status := play_status;
         replay_forbidden := TRUE;
         If (play_status <> isStopped) then play_status := isPaused;
         nul_volume_bars;
         really_no_status_refresh := TRUE;
         reset_player;

         FillChar(_m_chan_handle,SizeOf(_m_chan_handle),0);
         Move(channel_flag,_m_channel_flag_backup,SizeOf(_m_channel_flag_backup));
         Move(event_table,_m_event_table_bak,SizeOf(_m_event_table_bak));
         FillChar(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
         Move(pan_lock,_m_pan_lock_backup,SizeOf(pan_lock));
         Move(volume_lock,_m_volume_lock_backup,SizeOf(volume_lock));
         Move(peak_lock,_m_peak_lock_backup,SizeOf(volume_lock));
         Move(panning_table,_m_panning_table_backup,SizeOf(panning_table));
         FillChar(pan_lock,SizeOf(pan_lock),0);
         FillChar(volume_lock,SizeOf(volume_lock),0);
         FillChar(peak_lock,SizeOf(volume_lock),0);
         _m_flag_4op_backup := songdata.flag_4op;
         If NOT percussion_mode and
            NOT is_4op_mode then _m_channels := 18
         else If NOT is_4op_mode then _m_channels := 15
              else begin
                     If (instr2 <> NULL) then
                       begin
                         songdata.flag_4op := $3f;
                         _m_channels := 6;
                       end
                     else begin
                            songdata.flag_4op := 0;
                            If NOT percussion_mode then _m_channels := 18
                            else _m_channels := 15;
                          end;
                   end;

         _bak_arpeggio_table := songdata.instr_macros[current_inst].arpeggio_table;
         _bak_vibrato_table := songdata.instr_macros[current_inst].vibrato_table;
         _bak_common_flag := songdata.common_flag;
         _bak_volume_scaling := volume_scaling;
         songdata.instr_macros[current_inst].arpeggio_table := ptr_arpeggio_table^;
         songdata.instr_macros[current_inst].vibrato_table := ptr_vibrato_table^;
         songdata.common_flag := songdata.common_flag AND NOT $80;
         volume_scaling := FALSE;
         reset_player;

         Move(fmpar_table,_m_fmpar_table_backup,SizeOf(_m_fmpar_table_backup));
         Move(volume_table,_m_volume_table_backup,SizeOf(_m_volume_table_backup));
         Move(freq_table,_m_freq_table_bak,SizeOf(freq_table));
         Move(freqtable2,_m_freqtable2_bak,SizeOf(freqtable2));
         Move(keyoff_loop,_m_keyoff_loop_bak,SizeOf(keyoff_loop));
         FillChar(keyoff_loop,SizeOf(keyoff_loop),FALSE);

         misc_register := current_tremolo_depth SHL 7+
                          current_vibrato_depth SHL 6+
                          BYTE(percussion_mode) SHL 5;
         key_off(17);
         key_off(18);
         opl3out(_instr[11],misc_register);

         macro_speedup := songdata.macro_speedup;
         If (play_status = isStopped) then update_timer(songdata.tempo);
       end;
  end;
end;

procedure _macro_preview_body(instr,instr2,chan: Byte; fkey: Word);

function output_note(chan,board_pos: Byte): Boolean;

var
  note: Byte;
  freq: Word;

begin
  note := board_pos+12*(current_octave-1);
  If NOT (note in [0..12*8+1]) then
    begin
      output_note := FALSE;
      EXIT;
    end;

  _m_chan_handle[chan] := board_scancodes[board_pos];
  If is_4op_mode and (instr2 <> NULL) then chan := _m_4op_chan[chan];
  load_instrument(songdata.instr_data[instr],chan);

  If percussion_mode and
     (songdata.instr_data[instr].perc_voice in [4,5]) then
    load_instrument(songdata.instr_data[instr],_m_perc_sim_chan[chan]);

  If is_4op_mode and (instr2 <> NULL) then
    load_instrument(songdata.instr_data[instr2],PRED(chan));

  freq := nFreq(note-1)+$2000+
          SHORTINT(tDUMMY_BUFF(Addr(songdata.instr_data[instr])^)[12]);

  event_table[chan].note := note;
  opl3out($0b0+_chan_n[chan],0);
  opl3out($0a0+_chan_n[chan],LO(freq));
  opl3out($0b0+_chan_n[chan],HI(freq));

  freq_table[chan] := freq;
  freqtable2[chan] := freq;
  init_macro_table(chan,note,instr,freq);

  If is_4op_mode and (instr2 <> NULL) then
    begin
      freq_table[PRED(chan)] := freq;
      freqtable2[PRED(chan)] := freq;
      init_macro_table(PRED(chan),note,instr2,freq);
    end;
end;

function chanpos(var data; channels,scancode: Byte): Byte; assembler;
asm
        xor     ebx,ebx
@@1:    mov     edi,[data]
        add     edi,ebx
        xor     ecx,ecx
        mov     cl,channels
        mov     al,scancode
        sub     ecx,ebx
        repnz   scasb
        jnz     @@2
        xor     eax,eax
        mov     al,channels
        sub     eax,ecx
        jmp     @@3
@@2:    xor     eax,eax
        jmp     @@5
@@3:    pusha
        push    eax
        call    is_4op_chan
        or      al,al
        jz      @@4
        popa
        inc     ebx
        jmp     @@1
@@4:    popa
@@5:
end;

function chanpos2(var data; channels,scancode: Byte): Byte; assembler;
asm
        mov     edi,[data]
        xor     ecx,ecx
        mov     cl,channels
        mov     al,scancode
        repnz   scasb
        jnz     @@1
        xor     eax,eax
        mov     al,channels
        sub     eax,ecx
        jmp     @@2
@@1:    xor     eax,eax
@@2:
end;

begin { _macro_preview_body }
  If ctrl_pressed or alt_pressed or shift_pressed then EXIT;
  _m_valid_key := FALSE;
  For _m_temp := 1 to 29 do
    If NOT shift_pressed then
      If (board_scancodes[_m_temp] = HI(fkey)) then
        begin _m_valid_key := TRUE; BREAK; end;

  If NOT _m_valid_key or
     NOT (_m_temp+12*(current_octave-1)-1 in [0..12*8+1]) then EXIT;

  If NOT percussion_mode then _m_channels := 18
  else _m_channels := 15;

  _m_temp2 := _m_temp;
  If percussion_mode and
     (songdata.instr_data[instr].perc_voice in [1..5]) then
    begin
      output_note(songdata.instr_data[instr].perc_voice+15,_m_temp2);
      While scankey(board_scancodes[_m_temp2]) do
        begin
          emulate_screen;
          keyboard_reset_buffer;
        end;
    end
  else
    begin
      Repeat
        _m_valid_key := FALSE;

        For _m_temp := 1 to 29 do
          begin
            _m_temp2 := board_scancodes[_m_temp];
            _m_temp4 := scankey(_m_temp2);

            If NOT (is_4op_mode and (instr2 <> NULL)) then
              begin
                _m_temp3 := chanpos(_m_chan_handle,_m_channels,_m_temp2);
                _m_temp5 := chanpos(_m_chan_handle,_m_channels,0)
              end
            else begin
                   _m_temp3 := chanpos2(_m_chan_handle,_m_channels,_m_temp2);
                   _m_temp5 := chanpos2(_m_chan_handle,_m_channels,0)
                 end;

            If _m_temp4 then _m_valid_key := TRUE;
            If _m_temp4 and (_m_temp3 = 0) and (_m_temp5 <> 0) then
              output_note(_m_temp5,_m_temp);

            If NOT _m_temp4 and (_m_temp3 <> 0) then
              begin
                key_off(_m_temp3);
                _m_chan_handle[_m_temp3] := 0;
              end;
          end;

        emulate_screen;
        keyboard_reset_buffer;
      until NOT _m_valid_key;
    end;
end;

procedure MACRO_EDITOR(instr: Byte; arp_vib_mode: Boolean);

const
  EMPTY_FIELD = $0ffff;
  COMMON_FLAG = $08000;

var
  window_area_inc_x: Byte;
  window_area_inc_y: Byte;

// replacement for indirect call, cause FreePascal loses track of local variables and segment faults
// when indirectly calling some other nested procedure
procedure fmreg_page_refresh(xpos,ypos: Byte; page: Word); forward;
procedure arpeggio_page_refresh(xpos,ypos: Byte; page: Word); forward;
procedure arpeggio_page_refresh_alt(xpos,ypos: Byte; page: Word); forward;
procedure vibrato_page_refresh(xpos,ypos: Byte; page: Word); forward;
procedure vibrato_page_refresh_alt(xpos,ypos: Byte; page: Word); forward;

procedure _show_proc(show_proc_index: integer; xpos,ypos: Byte; page: Word);
begin
  Case show_proc_index of
    1: fmreg_page_refresh(xpos,ypos,page);
    2: arpeggio_page_refresh(xpos,ypos,page);
    3: arpeggio_page_refresh_alt(xpos,ypos,page);
    4: vibrato_page_refresh(xpos,ypos,page);
    5: vibrato_page_refresh_alt(xpos,ypos,page);
  end;
end;

procedure show_queue(x,y: Byte; page_len: Byte; page,len: Word; show_proc_index: integer);

var
  temp1,temp3: Byte;
  spos,epos: Byte;

begin
  If (PRED(page) < page_len DIV 2) then
    spos := page_len DIV 2-PRED(page)
  else spos := 0;
  If (PRED(page) > len-page_len DIV 2-1) then
    epos := PRED(page)-(len-page_len DIV 2-1)
  else epos := 0;

  If (spos <> 0) or (epos <> 0) then
    begin
      If (spos <> 0) then
        For temp3 := 1 to spos do
          _show_proc(show_proc_index,x,y+temp3,EMPTY_FIELD);

      If (epos <> 0) then
        For temp3 := page_len downto page_len-epos+1 do
          _show_proc(show_proc_index,x,y+temp3,EMPTY_FIELD);

    end;

  For temp1 := 1+spos to page_len-epos do
    If (temp1 <> SUCC(page_len DIV 2)) then
      _show_proc(show_proc_index,x,y+temp1,PRED(page)+temp1-page_len DIV 2)
    else
      _show_proc(show_proc_index,x,y+temp1,PRED(page)+temp1-page_len DIV 2+COMMON_FLAG);
end;

const
  HINT_STR: array[1..20+35] of String[77] = (
    'Length of FM-register definition macro-table {1-FF} (0 means no macros)',
    'Loop cycle starting position {1-FF} (0 means no loop)',
    'Length of loop cycle {1-FF} (0 means no loop)',
    'Key-Off jump position {1-FF} (0 means no jump)',
    'Arpeggio table number {1-FF} (0 means no arpeggio)',
    'Vibrato table number {1-FF} (0 means no vibrato)',
    '',
    'Length of arpeggio macro-table {1-FF} (0 means no macros)',
    'Speed of arpeggio in macro-table {1-FF} (0 means no arpeggio)',
    'Loop cycle starting position {1-FF} (0 means no loop)',
    'Length of loop cycle {1-FF} (0 means no loop)',
    'Key-Off jump position {1-FF} (0 means no jump)',
    'Number of half-tones to add [1-96] or fixed-note [C,C-,C#,C1,C-1,C#1,...]',
    'Length of vibrato macro-table {1-FF} (0 means no macros)',
    'Speed of vibrato in macro-table {1-FF} (0 means no vibrato)',
    'Delay before starting vibrato in macro-table {1-FF} (0 means no delay)',
    'Loop cycle starting position {1-FF} (0 means no loop)',
    'Length of loop cycle {1-FF} (0 means no loop)',
    'Key-Off jump position {1-FF} (0 means no jump)',
    'Frequency to add {1..7F} or subtract {-7F..-1}',

    'Attack rate [modulator] {0-F}',
    'Decay rate [modulator] {0-F}',
    'Sustain level [modulator] {0-F}',
    'Release rate [modulator] {0-F}',
    'Waveform type [modulator] {0-7}',
    'Output level [modulator] {0-3F}',
    'Output level [modulator] {0-3F}',
    'Key scaling level [modulator] {0-3}',
    'Multiplier [modulator] {0-F}',
    'Amplitude modulation (tremolo) [modulator] {on/off}',
    'Vibrato [modulator] {on/off}',
    'Key scale rate [modulator] {on/off}',
    'Sustain (EG type) [modulator] {on/off}',
    'Attack rate [carrier] {0-F}',
    'Decay rate [carrier] {0-F}',
    'Sustain level [carrier] {0-F}',
    'Release rate [carrier] {0-F}',
    'Waveform type [carrier] {0-7}',
    'Output level [carrier] {0-3F}',
    'Output level [carrier] {0-3F}',
    'Key scaling level [carrier] {0-3}',
    'Multiplier [carrier] {0-F}',
    'Amplitude modulation (tremolo) [carrier] {on/off}',
    'Vibrato [carrier] {on/off}',
    'Key scale rate [carrier] {on/off}',
    'Sustain (EG type) [carrier] {on/off}',
    'Connection type {0-1} (0=FM,1=AM)',
    'Feedback {0-7}',
    'Frequency slide {-FFF..+FFF}',
    'Frequency slide {-FFF..+FFF}',
    'Frequency slide {-FFF..+FFF}',
    'Frequency slide {-FFF..+FFF}',
    'Panning {Left/Center/Right}',
    'Duration {1-FF} (0 means skip)',
    'Duration {1-FF} (0 means skip)');

const
  _panning: array[0..2] of Char = 'ñ<>';
  _hex: array[0..15] of Char = '0123456789ABCDEF';

const
  new_keys: array[1..31] of Word = (kF1,kESC,kENTER,kSPACE,kTAB,kShTAB,kUP,kDOWN,
                                    kCtrlO,kF2,kCtrlF2,kF3,kCtrlL,kCtrlS,kCtrlM,
                                    kCtENTR,kAltC,kAltP,kCtrlC,kCtrlV,
                                    kCtPgUP,kCtPgDN,kSPACE,kNPplus,kNPmins,
                                    kCtLbr,kCtRbr,
                                    kCtHOME,kCtEND,kCtLEFT,kCtRGHT);
var
  old_keys: array[1..31] of Word;
  temps,tstr: String;
  xstart,ystart,temp,temp1: Byte;
  fmreg_cursor_pos,
  fmreg_left_margin: Byte;
  fmreg_hpos: Byte;
  pos,vibrato_hpos: Byte;
  attr: array[1..20] of Byte;
  frame_type: array[1..3] of String;
  fmreg_page,arpeggio_page,
  vibrato_page: Byte;
  fmreg_str: String;
  call_pickup_proc,call_pickup_proc2: Boolean;
  nope: Boolean;
  attr2: array[1..5] of Byte;
  _source_ins,_source_ins2: Byte;
  temp_marks: array[1..255] of Char;


function min0(number: Integer; flag: Integer): Integer;
begin
  If (number > 0) then min0 := number
  else min0 := flag;
end;

function fmreg_def_attr(page: Byte): Word;

var
  attr,
  attr2: Byte;

begin
  If (page <= songdata.instr_macros[instr].length) then
    If (page >= songdata.instr_macros[instr].loop_begin) and
       (page <= songdata.instr_macros[instr].loop_begin+
                PRED(songdata.instr_macros[instr].loop_length)) and
       (songdata.instr_macros[instr].loop_begin > 0) and
       (songdata.instr_macros[instr].loop_length > 0) then
      begin
        attr := macro_background+macro_text_loop;
        attr2 := macro_current_bckg+macro_current_loop;
      end
    else If (page >= songdata.instr_macros[instr].keyoff_pos) and
            (songdata.instr_macros[instr].keyoff_pos > 0) then
           begin
             attr := macro_background+macro_text_keyoff;
             attr2 := macro_current_bckg+macro_current_koff;
           end
         else
           begin
             attr := macro_background+macro_text;
             attr2 := macro_current_bckg+macro_current;
           end
  else
    begin
      attr := macro_background+macro_text_dis;
      attr2 := macro_current_bckg+macro_current_dis;
    end;

  fmreg_def_attr := attr+attr2 SHL 8;
end;

function _fmreg_str(page: Byte): String;

var
  fmreg_str: String;

begin
  With songdata.instr_macros[instr].data[page].fm_data do
    begin
      fmreg_str := _hex[ATTCK_DEC_modulator SHR 4]+' '+
                   _hex[ATTCK_DEC_modulator AND $0f]+' '+
                   _hex[SUSTN_REL_modulator SHR 4]+' '+
                   _hex[SUSTN_REL_modulator AND $0f]+' '+
                   _hex[WAVEFORM_modulator AND 7]+' '+
                   byte2hex(KSL_VOLUM_modulator AND $3f)+' '+
                   _hex[KSL_VOLUM_modulator SHR 6]+' '+
                   _hex[AM_VIB_EG_modulator AND $0f]+' ';

      If (AM_VIB_EG_modulator SHR 7 = 0) then fmreg_str := fmreg_str+'ú'
      else fmreg_str := fmreg_str+'T';

      If (AM_VIB_EG_modulator SHR 6 AND 1 = 0) then fmreg_str := fmreg_str+'ú'
      else fmreg_str := fmreg_str+'V';

      If (AM_VIB_EG_modulator SHR 4 AND 1 = 0) then fmreg_str := fmreg_str+'ú'
      else fmreg_str := fmreg_str+'K';

      If (AM_VIB_EG_modulator SHR 5 AND 1 = 0) then fmreg_str := fmreg_str+'ú '
      else fmreg_str := fmreg_str+'S ';

      fmreg_str := fmreg_str+
                   _hex[ATTCK_DEC_carrier SHR 4]+' '+
                   _hex[ATTCK_DEC_carrier AND $0f]+' '+
                   _hex[SUSTN_REL_carrier SHR 4]+' '+
                   _hex[SUSTN_REL_carrier AND $0f]+' '+
                   _hex[WAVEFORM_carrier AND 7]+' '+
                   byte2hex(KSL_VOLUM_carrier AND $3f)+' '+
                   _hex[KSL_VOLUM_carrier SHR 6]+' '+
                   _hex[AM_VIB_EG_carrier AND $0f]+' ';

      If (AM_VIB_EG_carrier SHR 7 = 0) then fmreg_str := fmreg_str+'ú'
      else fmreg_str := fmreg_str+'T';

      If (AM_VIB_EG_carrier SHR 6 AND 1 = 0) then fmreg_str := fmreg_str+'ú'
      else fmreg_str := fmreg_str+'V';

      If (AM_VIB_EG_carrier SHR 4 AND 1 = 0) then fmreg_str := fmreg_str+'ú'
      else fmreg_str := fmreg_str+'K';

      If (AM_VIB_EG_carrier SHR 5 AND 1 = 0) then fmreg_str := fmreg_str+'ú '
      else fmreg_str := fmreg_str+'S ';

      fmreg_str := fmreg_str+_hex[FEEDBACK_FM AND 1]+' ';
      fmreg_str := fmreg_str+_hex[FEEDBACK_FM SHR 1 AND 7]+' ';
    end;

  With songdata.instr_macros[instr].data[page] do
    begin
      If (freq_slide < 0) then fmreg_str := fmreg_str+'-'+ExpStrL(Num2str(Abs(freq_slide),16),3,'0')+' '
      else fmreg_str := fmreg_str+'+'+ExpStrL(Num2str(Abs(freq_slide),16),3,'0')+' ';

      fmreg_str := fmreg_str+
                   _panning[panning]+' '+
                   byte2hex(duration);
    end;

  _fmreg_str := fmreg_str;
end;

function _dis_fmreg_col(fmreg_col: Byte): Boolean;

var
  result: Boolean;

begin
  result := FALSE;
  Case fmreg_col of
    1,2,3,4,
    5: If songdata.dis_fmreg_col[instr][fmreg_col-1] then
         result := TRUE;
    6,
    7: If songdata.dis_fmreg_col[instr][5] then
         result := TRUE;

    8,9,10,11,12,13,
    14,15,16,17,
    18: If songdata.dis_fmreg_col[instr][fmreg_col-2] then
          result := TRUE;
    19,
    20: If songdata.dis_fmreg_col[instr][17] then
          result := TRUE;

    21,22,23,24,
    25,26,27,
    28: If songdata.dis_fmreg_col[instr][fmreg_col-3] then
          result := TRUE;

    29,30,31,
    32: If songdata.dis_fmreg_col[instr][26] then
          result := TRUE;

    33: If songdata.dis_fmreg_col[instr][27] then
          result := TRUE;
  end;

  If (fmreg_col in [14..28]) and
     (songdata.instr_data[current_inst].perc_voice in [2..5]) then
    result := TRUE;

    _dis_fmreg_col := result;
end;

function _str1(def_chr: Char): String;

const
  _on_off: array[BOOLEAN] of Char = ('Í','þ');

var
  temp: Byte;
  temp_str: String;

begin
  temp_str := '';
  _on_off[FALSE] := def_chr;

  For temp := 0 to 4 do
    temp_str := temp_str+
                _on_off[songdata.dis_fmreg_col[instr][temp]]+def_chr;

  temp_str := temp_str+
              _on_off[songdata.dis_fmreg_col[instr][5]]+
              _on_off[songdata.dis_fmreg_col[instr][5]]+def_chr;

  temp_str := temp_str+
              _on_off[songdata.dis_fmreg_col[instr][6]]+
              def_chr+
              _on_off[songdata.dis_fmreg_col[instr][7]]+def_chr;

  temp_str := temp_str+
              _on_off[songdata.dis_fmreg_col[instr][8]]+
              _on_off[songdata.dis_fmreg_col[instr][9]]+
              _on_off[songdata.dis_fmreg_col[instr][10]]+
              _on_off[songdata.dis_fmreg_col[instr][11]]+def_chr;

  For temp := 12 to 16 do
    temp_str := temp_str+
                _on_off[songdata.dis_fmreg_col[instr][temp]]+def_chr;

  temp_str := temp_str+
              _on_off[songdata.dis_fmreg_col[instr][17]]+
              _on_off[songdata.dis_fmreg_col[instr][17]]+def_chr;

  temp_str := temp_str+
              _on_off[songdata.dis_fmreg_col[instr][18]]+def_chr+
              _on_off[songdata.dis_fmreg_col[instr][19]]+def_chr;

  temp_str := temp_str+
              _on_off[songdata.dis_fmreg_col[instr][20]]+
              _on_off[songdata.dis_fmreg_col[instr][21]]+
              _on_off[songdata.dis_fmreg_col[instr][22]]+
              _on_off[songdata.dis_fmreg_col[instr][23]]+def_chr;

  For temp := 24 to 25 do
    temp_str := temp_str+
                _on_off[songdata.dis_fmreg_col[instr][temp]]+def_chr;

  temp_str := temp_str+
              _on_off[songdata.dis_fmreg_col[instr][26]]+
              _on_off[songdata.dis_fmreg_col[instr][26]]+
              _on_off[songdata.dis_fmreg_col[instr][26]]+
              _on_off[songdata.dis_fmreg_col[instr][26]]+def_chr;

  temp_str := temp_str+
              _on_off[songdata.dis_fmreg_col[instr][27]];

  _str1 := temp_str;
end;

function _str2(str: String; len: Byte): String; assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,@result
        movzx   ebx,len
        xor     edx,edx
        push    edi
        lodsb
        inc     edi
        xor     ecx,ecx
        mov     ecx,ebx
        jecxz   @@3
        movzx   ecx,al
        jecxz   @@3
@@1:    cmp     edx,ebx
        jae     @@3
        lodsb
        stosb
        cmp     al,'`'
        jz      @@2
        inc     edx
@@2:    loop    @@1
@@3:    pop     edi
        mov     eax,esi
        sub     eax,[str]
        dec     eax
        stosb
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure fmreg_page_refresh(xpos,ypos: Byte; page: Word);

var
  attr,attr2: Byte;
  temps,fmreg_str2: String;
  fmreg_col,index,
  index2: Byte;
  dummy_str: String;

begin
  attr := LO(fmreg_def_attr(page AND $0fff));
  attr2 := HI(fmreg_def_attr(page AND $0fff));
  fmreg_str := _fmreg_str(page AND $0fff);
  fmreg_str2 := fmreg_str;

  index := 0;
  index2 := 0;

  For fmreg_col := 1 to 35-1 do
    If _dis_fmreg_col(fmreg_col) then
      begin
        Insert('`',fmreg_str2,pos5[fmreg_col]+index);
        Insert('`',fmreg_str2,pos5[fmreg_col]+index+2);
        If (pos5[fmreg_col] < fmreg_left_margin) then Inc(index2,2);
        Inc(index,2);
      end;

  temps := Copy(fmreg_str2,fmreg_left_margin+index2,
                Length(fmreg_str2)-fmreg_left_margin-index2+1);

  If (songdata.instr_macros[instr].data[page AND $0ff].fm_data.
      FEEDBACK_FM OR $80 <> songdata.instr_macros[instr].data[page AND $0ff].fm_data.
                            FEEDBACK_FM) then
    dummy_str := '`'+#$0d+'`'
  else dummy_str := #$0d;

  If NOT arp_vib_mode then
    begin
      If (page <> EMPTY_FIELD) then
        If (page OR COMMON_FLAG <> page) then
          ShowC3Str(vscreen,xpos,ypos,
                    '~'+byte2hex(page)+'~ ³~'+dummy_str+'~ö~'+
                    _str2(temps,31+window_area_inc_x)+'~',
                    macro_background+macro_text,
                    attr,
                    macro_background+macro_text_dis)
        else
          ShowC3Str(vscreen,xpos-1,ypos,
                    ' ~'+byte2hex(page AND NOT COMMON_FLAG)+'~ ³~'+dummy_str+'~ö~'+
                    _str2(temps,31+window_area_inc_x)+'~ ',
                    macro_current_bckg+macro_current,
                    attr2,
                    macro_current_bckg+macro_current_dis)
      else
        ShowStr(vscreen,xpos,ypos,ExpStrL('',36,' '),attr);
    end
  else
    begin
      If (page <> EMPTY_FIELD) then
        If (page OR COMMON_FLAG <> page) then
          ShowC3Str(vscreen,xpos,ypos,
                    byte2hex(page)+' ³~'+dummy_str+'~ö~'+
                    _str2(temps,31+window_area_inc_x)+'~',
                    macro_background+macro_text_dis,
                    macro_background+macro_text_dis,
                    macro_background+macro_text_dis)
        else
          ShowC3Str(vscreen,xpos-1,ypos,
                    ' '+
                    byte2hex(page AND NOT COMMON_FLAG)+' ³~'+dummy_str+'~ö~'+
                    _str2(temps,31+window_area_inc_x)+'~ ',
                    macro_background+macro_text_dis,
                    macro_background+macro_text_dis,
                    macro_background+macro_text_dis)
      else
        ShowStr(vscreen,xpos,ypos,ExpStrL('',36,' '),
                macro_background+macro_text_dis);
    end;
end;

function arpeggio_def_attr(page: Byte): Word;

var
  attr,
  attr2: Byte;

begin
  If (page <= songdata.macro_table[ptr_arpeggio_table^].
              arpeggio.length) then
    If (page >= songdata.macro_table[ptr_arpeggio_table^].
                arpeggio.loop_begin) and
       (page <= songdata.macro_table[ptr_arpeggio_table^].
                arpeggio.loop_begin+
                PRED(songdata.macro_table[ptr_arpeggio_table^].
                     arpeggio.loop_length)) and
       (songdata.macro_table[ptr_arpeggio_table^].
        arpeggio.loop_begin > 0) and
       (songdata.macro_table[ptr_arpeggio_table^].
        arpeggio.loop_length > 0) then
      begin
        attr := macro_background+macro_text_loop;
        attr2 := macro_current_bckg+macro_current_loop;
      end
    else If (page >= songdata.macro_table[ptr_arpeggio_table^].
                     arpeggio.keyoff_pos) and
            (songdata.macro_table[ptr_arpeggio_table^].
             arpeggio.keyoff_pos > 0) then
           begin
             attr := macro_background+macro_text_keyoff;
             attr2 := macro_current_bckg+macro_current_koff;
           end
         else begin
                attr := macro_background+macro_text;
                attr2 := macro_current_bckg+macro_current;
              end
  else begin
         attr := macro_background+macro_text_dis;
         attr2 := macro_current_bckg+macro_current_dis;
       end;

  arpeggio_def_attr := attr+attr2 SHL 8;
end;

procedure arpeggio_page_refresh(xpos,ypos: Byte; page: Word);

var
  attr,attr2: Byte;
  temps: String;

begin
  attr  := LO(arpeggio_def_attr(page AND $0fff));
  attr2 := HI(arpeggio_def_attr(page AND $0fff));

  Case songdata.macro_table[ptr_arpeggio_table^].
       arpeggio.data[page AND $0fff] of
    0: temps := 'úúú';
    1..96: temps := '+'+ExpStrR(Num2str(songdata.macro_table[ptr_arpeggio_table^].
                                        arpeggio.data[page AND $0fff],10),2,' ');
    $80..$80+12*8+1:
       temps := note_layout[songdata.macro_table[ptr_arpeggio_table^].
                            arpeggio.data[page AND $0fff]-$80];
  end;

  If (page <> EMPTY_FIELD) then
    If (page OR COMMON_FLAG <> page) then
      ShowCStr(vscreen,xpos,ypos,
               '~'+byte2hex(page AND NOT COMMON_FLAG)+'~ ³ ~'+
               temps+'~',
               macro_background+macro_text,attr)
    else
      ShowCStr(vscreen,xpos-1,ypos,
               ' ~'+byte2hex(page AND NOT COMMON_FLAG)+'~ ³ ~'+
               temps+'~ ',
               macro_current_bckg+macro_current,attr2)
  else
    ShowStr(vscreen,xpos,ypos,ExpStrL('',9,' '),attr);
end;

function vibrato_def_attr(page: Byte): Word;

var
  attr,
  attr2: Byte;

begin
  If (page <= songdata.macro_table[ptr_vibrato_table^].
              vibrato.length) then
    If (page >= songdata.macro_table[ptr_vibrato_table^].
                vibrato.loop_begin) and
       (page <= songdata.macro_table[ptr_vibrato_table^].
                vibrato.loop_begin+
                PRED(songdata.macro_table[ptr_vibrato_table^].
                     vibrato.loop_length)) and
       (songdata.macro_table[ptr_vibrato_table^].
        vibrato.loop_begin > 0) and
       (songdata.macro_table[ptr_vibrato_table^].
        vibrato.loop_length > 0) then
      begin
        attr := macro_background+macro_text_loop;
        attr2 := macro_current_bckg+macro_current_loop;
      end
    else If (page >= songdata.macro_table[ptr_vibrato_table^].
                     vibrato.keyoff_pos) and
            (songdata.macro_table[ptr_vibrato_table^].
             vibrato.keyoff_pos > 0) then
           begin
             attr := macro_background+macro_text_keyoff;
             attr2 := macro_current_bckg+macro_current_koff;
           end
         else begin
                attr := macro_background+macro_text;
                attr2 := macro_current_bckg+macro_current;
              end
  else begin
         attr := macro_background+macro_text_dis;
         attr2 := macro_current_bckg+macro_current_dis;
       end;

  vibrato_def_attr := attr+attr2 SHL 8;
end;

procedure vibrato_page_refresh(xpos,ypos: Byte; page: Word);

var
  attr,attr2: Byte;
  temps: String;

begin
  attr  := LO(vibrato_def_attr(page AND $0fff));
  attr2 := HI(vibrato_def_attr(page AND $0fff));

  If (songdata.macro_table[ptr_vibrato_table^].
      vibrato.data[page AND $0fff] = 0) then temps := 'úúú'
  else If (songdata.macro_table[ptr_vibrato_table^].
           vibrato.data[page AND $0fff] < 0) then
         temps := '-'+byte2hex(Abs(songdata.macro_table[ptr_vibrato_table^].
                                  vibrato.data[page AND $0fff]))
       else
         temps := '+'+byte2hex(Abs(songdata.macro_table[ptr_vibrato_table^].
                                  vibrato.data[page AND $0fff]));

  If (page <> EMPTY_FIELD) then
    If (page OR COMMON_FLAG <> page) then
      ShowCStr(vscreen,xpos,ypos,
               '~'+byte2hex(page AND NOT COMMON_FLAG)+'~ ³ ~'+
               temps+'~',
               macro_background+macro_text,attr)
    else
      ShowCStr(vscreen,xpos-1,ypos,
               ' ~'+byte2hex(page AND NOT COMMON_FLAG)+'~ ³ ~'+
               temps+'~ ',
               macro_current_bckg+macro_current,attr2)
  else
    ShowStr(vscreen,xpos,ypos,ExpStrL('',9,' '),attr);
end;

procedure arpeggio_page_refresh_alt(xpos,ypos: Byte; page: Word);
begin
  If (page <> EMPTY_FIELD) then
    If (page OR COMMON_FLAG <> page) then
      ShowCStr(vscreen,xpos,ypos,
               byte2hex(page AND NOT COMMON_FLAG)+' ³ ~'+
               'úúú'+'~',
               macro_background+macro_text_dis,
               macro_background+macro_text_dis)
    else
      ShowCStr(vscreen,xpos-1,ypos,
               ' '+
               byte2hex(page AND NOT COMMON_FLAG)+' ³ ~'+
               'úúú'+'~ ',
               macro_background+macro_text_dis,
               macro_background+macro_text_dis)
  else
    ShowStr(vscreen,xpos,ypos,
            ExpStrL('',9,' '),
            macro_background+macro_text_dis);
end;

procedure vibrato_page_refresh_alt(xpos,ypos: Byte; page: Word);
begin
  temps := 'úúú';
  If (page <> EMPTY_FIELD) then
    If (page OR COMMON_FLAG <> page) then
      ShowCStr(vscreen,xpos,ypos,
               byte2hex(page AND NOT COMMON_FLAG)+' ³ ~'+
               'úúú'+'~',
               macro_background+macro_text_dis,
               macro_background+macro_text_dis)
    else
      ShowCStr(vscreen,xpos-1,ypos,
               ' '+
               byte2hex(page AND NOT COMMON_FLAG)+' ³ ~'+
               'úúú'+'~ ',
               macro_background+macro_text_dis,
               macro_background+macro_text_dis)
  else
    ShowStr(vscreen,xpos,ypos,
            ExpStrL('',9,' '),
            macro_background+macro_text_dis);
end;

function _gfx_bar_str(value: Byte; neg: Boolean): String;

var
  result: String;

begin
  result := '';
  If NOT neg then
    Repeat
      If (value > 15) then
        begin
          result := result+#219;
          Dec(value,15);
        end;
      If (value <= 15) and (value <> 0) then
        result := result+CHR(127+value)
    until (value <= 15)
  else Repeat
         If (value > 15) then
           begin
             result := #219+result;
             Dec(value,15);
           end;
         If (value <= 15) and (value <> 0) then
           result := CHR(158-value)+result;
       until (value <= 15);
  _gfx_bar_str := flipstr(result);
end;

function _fmreg_param(page,fmreg_hpos: Byte): Integer;

var
  result: Integer;
  fmreg_str: String;

begin
  fmreg_str := _fmreg_str(page);
  Case fmreg_hpos of
    {%n}
    1,2,3,4,5,8,9,14,15,16,17,
    18,21,22,27,28: result := Str2num(fmreg_str[pos5[fmreg_hpos]],16);

    {%nn}
    6,7:   result := Str2num(Copy(fmreg_str,pos5[6],2),16);
    19,20: result := Str2num(Copy(fmreg_str,pos5[19],2),16);
    34,35: result := Str2num(Copy(fmreg_str,pos5[34],2),16);

    {sw}
    10,11,12,13,23,24,
    25,26: If (fmreg_str[pos5[fmreg_hpos]] = 'û') then result := 1
              else result := 0;

    {fsl}
    29,30,31,32: begin
                   result := Str2num(Copy(fmreg_str,pos5[30],3),16);
                   If (fmreg_str[pos5[29]] = '-') then result := -result;
                 end;
    {pan}
    33: Case SYSTEM.Pos(fmreg_str[pos5[33]],_panning) of
          1: result := 0;
          2: result := -1;
          3: result := 1;
        end;
  end;
  _fmreg_param := result;
end;

procedure refresh;

var
  temp,max_value: Integer;
  d_factor: Real;
  temp_str: String;

begin
  For temp := 1 to 20 do
    If (pos = temp) then attr[temp] := macro_background+macro_hi_text
    else If (temp in [1..7]) and arp_vib_mode then
           attr[temp] := macro_background+macro_text_dis
         else If (temp in [8..13]) and
                 (ptr_arpeggio_table^ = 0) then
               attr[temp] := macro_background+macro_text_dis
              else If (temp in [14..20]) and
                      (ptr_vibrato_table^ = 0) then
                     attr[temp] := macro_background+macro_text_dis
                   else attr[temp] := macro_background+macro_text;

  If (ptr_arpeggio_table^ <> 0) then
    begin
      attr2[1] := macro_input_bckg+macro_input;
      attr2[3] := macro_background+macro_topic;
    end
  else begin
         attr2[1] := macro_background+macro_text_dis;
         attr2[3] := macro_background+macro_text_dis;
       end;

  If (ptr_vibrato_table^ <> 0) then
    begin
      attr2[2] := macro_input_bckg+macro_input;
      attr2[4] := macro_background+macro_topic;
    end
  else begin
         attr2[2] := macro_background+macro_text_dis;
         attr2[4] := macro_background+macro_text_dis;
       end;

  If NOT arp_vib_mode then attr2[5] := macro_input_bckg+macro_input
  else attr2[5] := macro_background+macro_text_dis;

  If (pos = 7) then frame_type[1] := double
  else frame_type[1] := single;

  If (pos = 13) then frame_type[2] := double
  else frame_type[2] := single;

  If (pos = 20) then frame_type[3] := double
  else frame_type[3] := single;

  If NOT arp_vib_mode then
    begin
      ShowStr(vscreen,xstart+2,ystart+1,'FM-REGiSTER',
              macro_background+macro_topic);
      ShowStr(vscreen,xstart+2,ystart+2,'DEFiNiTiON MACRO-TABLE',
              macro_background+macro_topic);
    end
  else begin
         ShowStr(vscreen,xstart+2,ystart+1,'FM-REGiSTER',
                 macro_background+macro_text_dis);
         ShowStr(vscreen,xstart+2,ystart+2,'DEFiNiTiON MACRO-TABLE',
                 macro_background+macro_text_dis);
       end;

  ShowStr(vscreen,xstart+2,ystart+3,
          ExpStrL('',78+window_area_inc_x,'Í'),
          macro_background+macro_text);

  ShowStr(vscreen,xstart+2,ystart+10,
          ExpStrL('',78+window_area_inc_x,'Í'),
          macro_background+macro_text);

  ShowStr(vscreen,xstart+2,ystart+22+window_area_inc_y,
          ExpStrL('',78+window_area_inc_x,'Í'),
          macro_background+macro_text);

  ShowCStr(vscreen,xstart+2,ystart+4,
           'LENGTH         ~'+
           byte2hex(songdata.instr_macros[instr].length)+' ~',
           attr[1],attr2[5]);

  ShowCStr(vscreen,xstart+2,ystart+5,
           'LOOP BEGiN     ~'+
           byte2hex(songdata.instr_macros[instr].loop_begin)+' ~',
           attr[2],attr2[5]);

  ShowCStr(vscreen,xstart+2,ystart+6,
           'LOOP LENGTH    ~'+
           byte2hex(songdata.instr_macros[instr].loop_length)+' ~',
           attr[3],attr2[5]);

  ShowCStr(vscreen,xstart+2,ystart+7,
           'KEY-OFF        ~'+
           byte2hex(songdata.instr_macros[instr].keyoff_pos)+' ~',
           attr[4],attr2[5]);

  ShowCStr(vscreen,xstart+2,ystart+8,
           'ARPEGGiO TABLE ~'+
           byte2hex(ptr_arpeggio_table^)+' ~',
           attr[5],attr2[5]);

  ShowCStr(vscreen,xstart+2,ystart+9,
           'ViBRATO TABLE  ~'+
           byte2hex(ptr_vibrato_table^)+' ~',
           attr[6],attr2[5]);

  ShowStr(vscreen,xstart+48+window_area_inc_x,ystart+2,'ARPEGGiO ('+
          byte2hex(ptr_arpeggio_table^)+')',
          attr2[3]);

  ShowCStr(vscreen,xstart+48+window_area_inc_x,ystart+4,
           'LENGTH      ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                   arpeggio.length)+' ~',
           attr[8],attr2[1]);

  ShowCStr(vscreen,xstart+48+window_area_inc_x,ystart+5,
           'SPEED       ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                   arpeggio.speed)+' ~',
           attr[9],attr2[1]);

  ShowCStr(vscreen,xstart+48+window_area_inc_x,ystart+6,
           'LOOP BEGiN  ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                   arpeggio.loop_begin)+' ~',
           attr[10],attr2[1]);

  ShowCStr(vscreen,xstart+48+window_area_inc_x,ystart+7,
           'LOOP LENGTH ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                   arpeggio.loop_length)+' ~',
           attr[11],attr2[1]);

  ShowCStr(vscreen,xstart+48+window_area_inc_x,ystart+8,
           'KEY-OFF     ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                   arpeggio.keyoff_pos)+' ~',
           attr[12],attr2[1]);

  ShowStr(vscreen,xstart+65+window_area_inc_x,ystart+2,'ViBRATO ('+
          byte2hex(ptr_vibrato_table^)+')',
          attr2[4]);

  ShowCStr(vscreen,xstart+65+window_area_inc_x,ystart+4,
           'LENGTH      ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table^].
                   vibrato.length)+' ~',
           attr[14],attr2[2]);

  ShowCStr(vscreen,xstart+65+window_area_inc_x,ystart+5,
           'SPEED       ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table^].
                   vibrato.speed)+' ~',
           attr[15],attr2[2]);

  ShowCStr(vscreen,xstart+65+window_area_inc_x,ystart+6,
           'DELAY       ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table^].
                   vibrato.delay)+' ~',
           attr[16],attr2[2]);

  ShowCStr(vscreen,xstart+65+window_area_inc_x,ystart+7,
           'LOOP BEGiN  ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table^].
                   vibrato.loop_begin)+' ~',
           attr[17],attr2[2]);

  ShowCStr(vscreen,xstart+65+window_area_inc_x,ystart+8,
           'LOOP LENGTH ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table^].
                   vibrato.loop_length)+' ~',
           attr[18],attr2[2]);

  ShowCStr(vscreen,xstart+65+window_area_inc_x,ystart+9,
           'KEY-OFF     ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table^].
                   vibrato.keyoff_pos)+' ~',
           attr[19],attr2[2]);

  fr_setting.update_area := FALSE;
  fr_setting.shadow_enabled := FALSE;

  Frame(vscreen,xstart+2,ystart+11,
        xstart+42+window_area_inc_y,ystart+21+window_area_inc_y,
        attr[7],'',
        macro_background+macro_text,frame_type[1]);

  Frame(vscreen,xstart+48+window_area_inc_x,ystart+11,
        xstart+59+window_area_inc_x,ystart+21+window_area_inc_y,
        attr[13],'',
        macro_background+macro_text,frame_type[2]);

  Frame(vscreen,xstart+65+window_area_inc_x,ystart+11,
        xstart+76+window_area_inc_x,ystart+21+window_area_inc_y,
        attr[20],'',
        macro_background+macro_text,frame_type[3]);

  fr_setting.update_area := TRUE;
  fr_setting.shadow_enabled := TRUE;

  show_queue(xstart+4,ystart+11,9+window_area_inc_y,fmreg_page,255,1);
  If NOT arp_vib_mode then
    begin
      HScrollBar(vscreen,xstart+29+window_area_inc_x,ystart+21+window_area_inc_y,
                 13,35,fmreg_hpos,$0ffff,
                 macro_scrbar_bckg+macro_scrbar_text,
                 macro_scrbar_bckg+macro_scrbar_mark);
      VScrollBar(vscreen,xstart+43+window_area_inc_x,ystart+12,
                 9+window_area_inc_y,255,fmreg_page,$0ffff,
                 macro_scrbar_bckg+macro_scrbar_text,
                 macro_scrbar_bckg+macro_scrbar_mark);
    end
  else
    begin
      HScrollBar(vscreen,xstart+29+window_area_inc_x,ystart+21+window_area_inc_y,
                 13,35,fmreg_hpos,$0ffff,
                 macro_background+macro_text_dis,
                 macro_background+macro_text_dis);
      VScrollBar(vscreen,xstart+43+window_area_inc_x,ystart+12,
                 9+window_area_inc_y,255,fmreg_page,$0ffff,
                 macro_background+macro_text_dis,
                 macro_background+macro_text_dis);
    end;

  If (pos = 7) then
    ShowStr(vscreen,xstart+2+8,ystart+11,
            Copy(_str1('Í'),fmreg_left_margin,31),
            attr[7])
  else
    ShowStr(vscreen,xstart+2+8,ystart+11,
            Copy(_str1('Ä'),fmreg_left_margin,31),
            attr[7]);

  If (ptr_arpeggio_table^ <> 0) then
    begin
      show_queue(xstart+50+window_area_inc_x,ystart+11,9+window_area_inc_y,arpeggio_page,255,2);
      VScrollBar(vscreen,xstart+60+window_area_inc_x,ystart+12,
                 9+window_area_inc_y,255,arpeggio_page,$0ffff,
                 macro_scrbar_bckg+macro_scrbar_text,
                 macro_scrbar_bckg+macro_scrbar_mark)
    end
  else
    begin
      show_queue(xstart+50+window_area_inc_x,ystart+11,9+window_area_inc_y,1,255,3);
      VScrollBar(vscreen,xstart+60+window_area_inc_x,ystart+12,
                 9+window_area_inc_y,255,1,$0ffff,
                 macro_background+macro_text_dis,
                 macro_background+macro_text_dis);
    end;

  If (ptr_vibrato_table^ <> 0) then
    begin
      show_queue(xstart+67+window_area_inc_x,ystart+11,9+window_area_inc_y,vibrato_page,255,4);
      VScrollBar(vscreen,xstart+77+window_area_inc_x,ystart+12,
                 9+window_area_inc_y,255,vibrato_page,$0ffff,
                 macro_scrbar_bckg+macro_scrbar_text,
                 macro_scrbar_bckg+macro_scrbar_mark);
    end
  else
    begin
      show_queue(xstart+67+window_area_inc_x,ystart+11,9+window_area_inc_y,1,255,5);
      VScrollBar(vscreen,xstart+77+window_area_inc_x,ystart+12,
                 9+window_area_inc_y,255,1,$0ffff,
                 macro_background+macro_text_dis,
                 macro_background+macro_text_dis);
    end;

  If (pos <> 7) then
    ShowStr(vscreen,xstart+2,ystart+23+window_area_inc_y,
            ExpStrR(HINT_STR[pos],77,' '),
            macro_background+macro_hint)
  else ShowStr(vscreen,xstart+2,ystart+23+window_area_inc_y,
               ExpStrR(HINT_STR[20+fmreg_hpos],77,' '),
               macro_background+macro_hint);

  Case pos of
    1..7:  begin
             ShowStr(vscreen,xstart+32+(window_area_inc_x DIV 2),ystart+3,
                     'ý',
                     macro_background+macro_text);
             ShowStr(vscreen,xstart+32+(window_area_inc_x DIV 2),ystart+10,
                     'ü',
                     macro_background+macro_text);

             If NOT (fmreg_hpos in [29..33]) then
               begin
                 ShowVStr(vscreen,xstart+22,ystart+4,
                          '³³³³³ž',
                          macro_background+macro_text);
                 ShowVStr(vscreen,xstart+42+window_area_inc_x,ystart+4,
                          '³³³³³ž',
                          macro_background+macro_text);
               end
             else begin
                    ShowVStr(vscreen,xstart+22,ystart+4,
                             '³³ž³³³',
                             macro_background+macro_text);
                    ShowVStr(vscreen,xstart+42+window_area_inc_x,ystart+4,
                             '³³ž³³³',
                             macro_background+macro_text);
                  end;

             For temp := 1 to 19+window_area_inc_x do
               ShowVStr(vscreen,xstart+22+temp,ystart+4,
                        ExpStrL('',6,' '),
                        macro_background+macro_text);

             max_value := 0;
             For temp := 1 to 255 do
               If (Abs(_fmreg_param(temp,fmreg_hpos)) > max_value) then
                 max_value := Abs(_fmreg_param(temp,fmreg_hpos));

             If NOT (fmreg_hpos in [29..33]) then
               begin               
                 ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+4,
                         ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                         macro_background+macro_topic);
                 ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+5,
                         '+',
                         macro_background+macro_topic);
                 ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+8,
                         ' ',
                         macro_background+macro_topic);
                 ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+9,
                         ExpStrR('',3,' '),
                         macro_background+macro_topic);
               end
             else      
               begin
                 ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+4,
                         ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                         macro_background+macro_topic);
                 ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+5,
                         '+',
                         macro_background+macro_topic);
                 ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+8,
                         '-',
                         macro_background+macro_topic);
                 ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+9,
                         ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                         macro_background+macro_topic);
               end;

             If NOT (fmreg_hpos in [29..33]) then
               d_factor := 90/min(max_value,1)
             else d_factor := 45/min(max_value,1);

             If NOT (fmreg_hpos in [29..33]) then
               For temp := -9-(window_area_inc_x DIV 2) to 9+(window_area_inc_x DIV 2) do
                 If (fmreg_page+temp >= 1) and (fmreg_page+temp <= 255) then
                   If NOT _dis_fmreg_col(fmreg_hpos) then
                     ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                              ExpStrL(_gfx_bar_str(Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor),FALSE),6,' '),
                              LO(fmreg_def_attr(fmreg_page+temp)))
                   else
                     ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                              ExpStrL(_gfx_bar_str(Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor),FALSE),6,' '),
                              macro_background+macro_text_dis)
                 else ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                               ExpStrL('',6,' '),
                               macro_background+macro_text)
             else For temp := -9-(window_area_inc_x DIV 2) to 9+(window_area_inc_x DIV 2) do
                    If (fmreg_page+temp >= 1) and (fmreg_page+temp <= 255) then
                      If (Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor) >= 0) then
                        If NOT _dis_fmreg_col(fmreg_hpos) then
                          ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                                   ExpStrL(_gfx_bar_str(Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor),FALSE),3,' '),
                                   LO(fmreg_def_attr(fmreg_page+temp)))
                        else
                          ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                                   ExpStrL(_gfx_bar_str(Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor),FALSE),3,' '),
                                   macro_background+macro_text_dis)
                      else If NOT _dis_fmreg_col(fmreg_hpos) then
                             ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+7,
                                      ExpStrR(_gfx_bar_str(Round(Abs(_fmreg_param(fmreg_page+temp,fmreg_hpos))*d_factor),TRUE),3,' '),
                                      LO(fmreg_def_attr(fmreg_page+temp)))
                           else
                             ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+7,
                                      ExpStrR(_gfx_bar_str(Round(Abs(_fmreg_param(fmreg_page+temp,fmreg_hpos))*d_factor),TRUE),3,' '),
                                      macro_background+macro_text_dis)
                    else ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                                  ExpStrL('',3,' '),
                                  macro_background+macro_text);
        end;

    8..13: begin
             ShowStr(vscreen,xstart+32+(window_area_inc_x DIV 2),ystart+3,
                     'ý',
                     macro_background+macro_text);
             ShowStr(vscreen,xstart+32+(window_area_inc_x DIV 2),ystart+10,
                     'ü',
                     macro_background+macro_text);
             ShowVStr(vscreen,xstart+22,ystart+4,
                      '³³³³³ž',
                      macro_background+macro_text);
             ShowVStr(vscreen,xstart+42+window_area_inc_x,ystart+4,
                      '³³³³³ž',
                      macro_background+macro_text);

             For temp := 1 to 19+window_area_inc_x do
               ShowVStr(vscreen,xstart+22+temp,ystart+4,
                        ExpStrL('',6,' '),
                        macro_background+macro_text);

             max_value := 0;
             For temp := 1 to 255 do
               If (songdata.macro_table[ptr_arpeggio_table^].
                   arpeggio.data[temp] > max_value) then
                 If (songdata.macro_table[ptr_arpeggio_table^].
                     arpeggio.data[temp] < $80) then
                   max_value := Abs(songdata.macro_table[ptr_arpeggio_table^].
                                    arpeggio.data[temp]);

             ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+4,
                     ExpStrR(Num2Str(max_value,10),3,' '),
                     macro_background+macro_topic);
             ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+5,
                     '+',
                     macro_background+macro_topic);
             ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+8,
                     ' ',
                     macro_background+macro_topic);
             ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+9,
                     ExpStrR('',3,' '),
                     macro_background+macro_topic);

             d_factor := 90/min(max_value,1);
             For temp := -9-(window_area_inc_x DIV 2) to 9+(window_area_inc_x DIV 2) do
               If (arpeggio_page+temp >= 1) and (arpeggio_page+temp <= 255) then
                 If (songdata.macro_table[ptr_arpeggio_table^].
                     arpeggio.data[arpeggio_page+temp] < $80) then
                   ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                            ExpStrL(_gfx_bar_str(Round(songdata.macro_table[ptr_arpeggio_table^].
                                                       arpeggio.data[arpeggio_page+temp]*d_factor),FALSE),6,' '),
                            LO(arpeggio_def_attr(arpeggio_page+temp)))
                 else ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                               ExpStrL(FilterStr(note_layout[songdata.macro_table[ptr_arpeggio_table^].
                                                             arpeggio.data[arpeggio_page+temp]-$80],'-','ñ'),6,' '),
                               LO(arpeggio_def_attr(arpeggio_page+temp)))
               else ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                             ExpStrL('',6,' '),
                             macro_background+macro_text);
        end;

    14..20: begin
              ShowStr(vscreen,xstart+32+(window_area_inc_x DIV 2),ystart+3,
                      'ý',
                      macro_background+macro_text);
              ShowStr(vscreen,xstart+32+(window_area_inc_x DIV 2),ystart+10,
                      'ü',
                      macro_background+macro_text);
              ShowVStr(vscreen,xstart+22,ystart+4,
                       '³³ž³³³',
                       macro_background+macro_text);
              ShowVStr(vscreen,xstart+42+window_area_inc_x,ystart+4,
                       '³³ž³³³',
                       macro_background+macro_text);

              For temp := 1 to 19+window_area_inc_x do
                ShowVStr(vscreen,xstart+22+temp,ystart+4,
                         ExpStrL('',6,' '),
                         macro_background+macro_text);

              max_value := 0;
              For temp := 1 to 255 do
                If (Abs(songdata.macro_table[ptr_vibrato_table^].
                        vibrato.data[temp]) > max_value) then
                  max_value := Abs(songdata.macro_table[ptr_vibrato_table^].
                                   vibrato.data[temp]);

              ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+4,
                      ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                      macro_background+macro_topic);
              ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+5,
                      '+',
                      macro_background+macro_topic);
              ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+8,
                      '-',
                      macro_background+macro_topic);
              ShowStr(vscreen,xstart+42+window_area_inc_x+1,ystart+9,
                      ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                      macro_background+macro_topic);

              d_factor := 45/min(max_value,1);
              For temp := -9-(window_area_inc_x DIV 2) to 9+(window_area_inc_x DIV 2) do
                If (vibrato_page+temp >= 1) and (vibrato_page+temp <= 255) then
                  If (Round(songdata.macro_table[ptr_vibrato_table^].
                            vibrato.data[vibrato_page+temp]*d_factor) >= 0) then
                    ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                             ExpStrL(_gfx_bar_str(Round(songdata.macro_table[ptr_vibrato_table^].
                                                        vibrato.data[vibrato_page+temp]*d_factor),FALSE),3,' '),
                             LO(vibrato_def_attr(vibrato_page+temp)))
                  else ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+7,
                                ExpStrR(_gfx_bar_str(Round(Abs(songdata.macro_table[ptr_vibrato_table^].
                                                               vibrato.data[vibrato_page+temp])*d_factor),TRUE),3,' '),
                                LO(vibrato_def_attr(vibrato_page+temp)))
                else ShowVStr(vscreen,xstart+32+temp+(window_area_inc_x DIV 2),ystart+4,
                              ExpStrL('',3,' '),
                              macro_background+macro_text);
        end;
  end;

  Case songdata.instr_data[current_inst].perc_voice of
    0: ShowCStr(vscreen,
                xstart+01,ystart+24+window_area_inc_y,
                ' [MELODiC] ',
                macro_background+macro_border,
                macro_background+macro_hi_text);
    1: ShowCStr(vscreen,
                xstart+01,ystart+24+window_area_inc_y,
                ' [PERC:BD] ',
                macro_background+macro_border,
                macro_background+macro_hi_text);
    2: ShowCStr(vscreen,
                xstart+01,ystart+24+window_area_inc_y,
                ' [PERC:SD] ',
                macro_background+macro_border,
                macro_background+macro_hi_text);
    3: ShowCStr(vscreen,
                 xstart+01,ystart+24+window_area_inc_y,
                ' [PERC:TT] ',
                macro_background+macro_border,
                macro_background+macro_hi_text);
    4: ShowCStr(vscreen,
                xstart+01,ystart+24+window_area_inc_y,
                ' [PERC:TC] ',
                macro_background+macro_border,
                macro_background+macro_hi_text);
    5: ShowCStr(vscreen,
                xstart+01,ystart+24+window_area_inc_y,
                ' [PERC:HH] ',
                macro_background+macro_border,
                macro_background+macro_hi_text);
  end;

  If (songdata.instr_macros[current_inst].length <> 0) then temp_str := ' [~MACRO:FM'
  else temp_str := ' ';

  With songdata.macro_table[ptr_arpeggio_table^].arpeggio do
    If (length <> 0) then // and (speed <> 0) then
      If (temp_str <> ' ') then temp_str := temp_str+'+ARP'
      else temp_str := temp_str+'[~MACRO:ARP';

  With songdata.macro_table[ptr_vibrato_table^].vibrato do
    If (length <> 0) then // and (speed <> 0) then
      If (temp_str <> ' ') then temp_str := temp_str+'+ViB'
      else temp_str := temp_str+'[~MACRO:ViB';

  If (temp_str <> ' ') then temp_str := temp_str+'~] ';

  ShowCStr(vscreen,xstart+11,ystart+24+window_area_inc_y,ExpStrR(temp_str,21+2,'Í'),
           macro_background+macro_border,
           macro_background+macro_hi_text);
 
  ShowCStr(vscreen,xstart+window_area_inc_x+66,ystart+24+window_area_inc_y,
           ExpStrL(' ~[SPEED:'+Num2str(tempo*songdata.macro_speedup,10)+#3+']~ ',17,'Í'),
           macro_background+macro_border,
           macro_background+macro_hi_text);

  _preview_indic_proc(0);
  move2screen_alt;
end;

function hex(chr: Char): Byte;
begin hex := PRED(SYSTEM.Pos(UpCase(chr),_hex)); end;

procedure copy_object;

var
  temp: Byte;

begin
  Case clipboard.object_type of
    objMacroTableLine:
      Case clipboard.mcrtab_type of
        mttFM_reg_table:
          clipboard.fmreg_table.data[1] :=
            songdata.instr_macros[instr].data[fmreg_page];

        mttArpeggio_table:
          clipboard.macro_table.arpeggio.data[1] :=
            songdata.macro_table[ptr_arpeggio_table^].
            arpeggio.data[arpeggio_page];

        mttVibrato_table:
          clipboard.macro_table.vibrato.data[1] :=
            songdata.macro_table[ptr_vibrato_table^].
            vibrato.data[vibrato_page];
      end;

    objMacroTableColumn:
      Case clipboard.mcrtab_type of
        mttFM_reg_table:
          begin
            clipboard.fmtab_def_typ := fmreg_hpos;
            For temp := 1 to 255 do
              clipboard.fmreg_table.data[temp] :=
                songdata.instr_macros[instr].data[temp];
          end;

        mttArpeggio_table:
          clipboard.macro_table.arpeggio :=
            songdata.macro_table[ptr_arpeggio_table^].arpeggio;

        mttVibrato_table:
          clipboard.macro_table.vibrato :=
            songdata.macro_table[ptr_vibrato_table^].vibrato;
      end;

    objMacroTable:
      Case clipboard.mcrtab_type of
        mttFM_reg_table:
          clipboard.fmreg_table :=
            songdata.instr_macros[instr];

        mttArpeggio_table:
          clipboard.macro_table.arpeggio :=
            songdata.macro_table[ptr_arpeggio_table^].arpeggio;

        mttVibrato_table:
          clipboard.macro_table.vibrato :=
            songdata.macro_table[ptr_vibrato_table^].vibrato;
      end;
  end;
end;

procedure paste_object;

var
  temp: Byte;

begin
  Case clipboard.object_type of
    objMacroTableLine:
      Case clipboard.mcrtab_type of
        mttFM_reg_table:
          If (pos = 7) then
            begin
              temp := songdata.instr_macros[instr].data[fmreg_page].
                      fm_data.FEEDBACK_FM;
              songdata.instr_macros[instr].data[fmreg_page] :=
                clipboard.fmreg_table.data[1];
              songdata.instr_macros[instr].data[fmreg_page].
                fm_data.FEEDBACK_FM := temp AND $0c0+
              songdata.instr_macros[instr].data[fmreg_page].
                fm_data.FEEDBACK_FM;
            end;

        mttArpeggio_table:
          If (pos = 13) then
            songdata.macro_table[ptr_arpeggio_table^].
            arpeggio.data[arpeggio_page] :=
              clipboard.macro_table.arpeggio.data[1];

        mttVibrato_table:
          If (pos = 20) then
            songdata.macro_table[ptr_vibrato_table^].
            vibrato.data[vibrato_page] :=
              clipboard.macro_table.vibrato.data[1];
      end;

    objMacroTableColumn:
      Case clipboard.mcrtab_type of
        mttFM_reg_table:
          For temp := 1 to 255 do
            With songdata.instr_macros[instr].data[temp] do
              Case clipboard.fmtab_def_typ of
                1: fm_data.ATTCK_DEC_modulator :=
                   clipboard.fmreg_table.data[temp].fm_data.ATTCK_DEC_modulator AND $0f0+
                   fm_data.ATTCK_DEC_modulator AND $0f;
                2: fm_data.ATTCK_DEC_modulator :=
                   fm_data.ATTCK_DEC_modulator AND $0f0+
                   clipboard.fmreg_table.data[temp].fm_data.ATTCK_DEC_modulator AND $0f;
                3: fm_data.SUSTN_REL_modulator :=
                   clipboard.fmreg_table.data[temp].fm_data.SUSTN_REL_modulator AND $0f0+
                   fm_data.SUSTN_REL_modulator AND $0f;
                4: fm_data.SUSTN_REL_modulator :=
                   fm_data.SUSTN_REL_modulator AND $0f0+
                   clipboard.fmreg_table.data[temp].fm_data.SUSTN_REL_modulator AND $0f;
                5: fm_data.WAVEFORM_modulator :=
                   clipboard.fmreg_table.data[temp].fm_data.WAVEFORM_modulator;
                6,
                7: fm_data.KSL_VOLUM_modulator :=
                   fm_data.KSL_VOLUM_modulator AND $0c0+
                   clipboard.fmreg_table.data[temp].fm_data.KSL_VOLUM_modulator AND $3f;
                8: fm_data.KSL_VOLUM_modulator :=
                   fm_data.KSL_VOLUM_modulator AND $3f+
                   clipboard.fmreg_table.data[temp].fm_data.KSL_VOLUM_modulator AND $0c0;
                9: fm_data.AM_VIB_EG_modulator :=
                   fm_data.AM_VIB_EG_modulator AND $0f0+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_modulator AND $0f;
               10: fm_data.AM_VIB_EG_modulator :=
                   fm_data.AM_VIB_EG_modulator AND $7f+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_modulator AND $80;
               11: fm_data.AM_VIB_EG_modulator :=
                   fm_data.AM_VIB_EG_modulator AND $0bf+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_modulator AND $40;
               12: fm_data.AM_VIB_EG_modulator :=
                   fm_data.AM_VIB_EG_modulator AND $0ef+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_modulator AND $10;
               13: fm_data.AM_VIB_EG_modulator :=
                   fm_data.AM_VIB_EG_modulator AND $0df+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_modulator AND $20;
               14: fm_data.ATTCK_DEC_carrier :=
                   clipboard.fmreg_table.data[temp].fm_data.ATTCK_DEC_carrier AND $0f0+
                   fm_data.ATTCK_DEC_carrier AND $0f;
               15: fm_data.ATTCK_DEC_carrier :=
                   fm_data.ATTCK_DEC_carrier AND $0f0+
                   clipboard.fmreg_table.data[temp].fm_data.ATTCK_DEC_carrier AND $0f;
               16: fm_data.SUSTN_REL_carrier :=
                   clipboard.fmreg_table.data[temp].fm_data.SUSTN_REL_carrier AND $0f0+
                   fm_data.SUSTN_REL_carrier AND $0f;
               17: fm_data.SUSTN_REL_carrier :=
                   fm_data.SUSTN_REL_carrier AND $0f0+
                   clipboard.fmreg_table.data[temp].fm_data.SUSTN_REL_carrier AND $0f;
               18: fm_data.WAVEFORM_carrier :=
                   clipboard.fmreg_table.data[temp].fm_data.WAVEFORM_carrier;
               19,
               20: fm_data.KSL_VOLUM_carrier :=
                   fm_data.KSL_VOLUM_carrier AND $0c0+
                   clipboard.fmreg_table.data[temp].fm_data.KSL_VOLUM_carrier AND $3f;
               21: fm_data.KSL_VOLUM_carrier :=
                   fm_data.KSL_VOLUM_carrier AND $3f+
                   clipboard.fmreg_table.data[temp].fm_data.KSL_VOLUM_carrier AND $0c0;
               22: fm_data.AM_VIB_EG_carrier :=
                   fm_data.AM_VIB_EG_carrier AND $0f0+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_carrier AND $0f;
               23: fm_data.AM_VIB_EG_carrier :=
                   fm_data.AM_VIB_EG_carrier AND $7f+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_carrier AND $80;
               24: fm_data.AM_VIB_EG_carrier :=
                   fm_data.AM_VIB_EG_carrier AND $0bf+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_carrier AND $40;
               25: fm_data.AM_VIB_EG_carrier :=
                   fm_data.AM_VIB_EG_carrier AND $0ef+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_carrier AND $10;
               26: fm_data.AM_VIB_EG_carrier :=
                   fm_data.AM_VIB_EG_carrier AND $0df+
                   clipboard.fmreg_table.data[temp].fm_data.AM_VIB_EG_carrier AND $20;
               27: fm_data.FEEDBACK_FM :=
                   fm_data.FEEDBACK_FM AND $0fe+
                   clipboard.fmreg_table.data[temp].fm_data.FEEDBACK_FM AND 1;
               28: fm_data.FEEDBACK_FM :=
                   fm_data.FEEDBACK_FM AND $0c1+
                   clipboard.fmreg_table.data[temp].fm_data.FEEDBACK_FM AND $03e;
               29,30,31,
               32: freq_slide :=
                   clipboard.fmreg_table.data[temp].freq_slide;
               33: panning :=
                   clipboard.fmreg_table.data[temp].panning;
               34,
               35: duration :=
                   clipboard.fmreg_table.data[temp].duration;
              end;

        mttArpeggio_table:
          If (pos in [8..13]) then
            For temp := 1 to 255 do
              songdata.macro_table[ptr_arpeggio_table^].
              arpeggio.data[temp] :=
                clipboard.macro_table.arpeggio.data[temp];

        mttVibrato_table:
          If (pos in [14..20]) then
            For temp := 1 to 255 do
              songdata.macro_table[ptr_vibrato_table^].
              vibrato.data[temp] :=
                clipboard.macro_table.vibrato.data[temp];
      end;

    objMacroTable:
      Case clipboard.mcrtab_type of
        mttFM_reg_table:
          If (pos in [1..7]) then
            songdata.instr_macros[instr] :=
              clipboard.fmreg_table;

        mttArpeggio_table:
          If (pos in [8..13]) then
            songdata.macro_table[ptr_arpeggio_table^].arpeggio :=
              clipboard.macro_table.arpeggio;

        mttVibrato_table:
          If (pos in [14..20]) then
            songdata.macro_table[ptr_vibrato_table^].vibrato :=
              clipboard.macro_table.vibrato;
      end;
  end;
end;

procedure _scroll_cur_left;
begin
  Repeat
    If (fmreg_cursor_pos > 1) then Dec(fmreg_cursor_pos)
    else Dec(fmreg_left_margin);
  until (fmreg_str[PRED(fmreg_left_margin+fmreg_cursor_pos-1)] = ' ') or
        (fmreg_left_margin+fmreg_cursor_pos-1 = 1);
  fmreg_cursor_pos := pos5[fmreg_hpos]-fmreg_left_margin+1;
end;

procedure _scroll_cur_right;
begin
  Repeat
    If (fmreg_cursor_pos < 31+window_area_inc_x) then Inc(fmreg_cursor_pos)
    else Inc(fmreg_left_margin);
  until (fmreg_str[SUCC(fmreg_left_margin+fmreg_cursor_pos-1)] = ' ') or
        (fmreg_left_margin+fmreg_cursor_pos-1 = 57);
  fmreg_cursor_pos := pos5[fmreg_hpos]-fmreg_left_margin+1;
end;

function _inc(value,limit: Integer): Integer;
begin
  If (value < limit) then Inc(value);
  _inc := value;
end;

function _dec(value,limit: Integer): Integer;
begin
  If (value > limit) then Dec(value);
  _dec := value;
end;

label _jmp1,_jmp2,_end2;

begin { MACRO_EDITOR }
  _arp_vib_mode := arp_vib_mode;
  If (sdl_screen_mode = 0) then
    begin
       window_area_inc_x := 0;
       window_area_inc_y := 0;
    end
  else begin
         window_area_inc_x := 10;
         window_area_inc_y := 10;
       end;

  call_pickup_proc := FALSE;
  _source_ins := instrum_page;
  call_pickup_proc2 := FALSE;
  _source_ins2 := instrum_page;
 
_jmp1:
  If NOT arp_vib_mode then
    begin
      ptr_arpeggio_table := Addr(songdata.instr_macros[instr].arpeggio_table);
      ptr_vibrato_table := Addr(songdata.instr_macros[instr].vibrato_table);
    end
  else begin
         ptr_arpeggio_table := Addr(arpvib_arpeggio_table);
         ptr_vibrato_table := Addr(arpvib_vibrato_table);
       end;
   
  pos := _macro_editor__pos[arp_vib_mode];
  If arp_vib_mode and (pos < 8) then pos := 8
  else If NOT arp_vib_mode and
          (((ptr_arpeggio_table^ = 0) and (pos in [8..13])) or
           ((ptr_vibrato_table^ = 0) and (pos in [14..20]))) then
          pos := 1;

  fmreg_hpos := _macro_editor__fmreg_hpos[arp_vib_mode];
  fmreg_page := _macro_editor__fmreg_page[arp_vib_mode];
  fmreg_left_margin := _macro_editor__fmreg_left_margin[arp_vib_mode];
  fmreg_cursor_pos := _macro_editor__fmreg_cursor_pos[arp_vib_mode];
  arpeggio_page := _macro_editor__arpeggio_page[arp_vib_mode];
  vibrato_hpos := _macro_editor__vibrato_hpos[arp_vib_mode];
  vibrato_page := _macro_editor__vibrato_page[arp_vib_mode];

  If _force_program_quit then EXIT;

  Move(v_ofs^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;

  HideCursor;
  For temp := 1 to 255 do
    begin
      temp_marks[temp] := songdata.instr_names[temp][1];
      songdata.instr_names[temp][1] := ' ';
    end;

  songdata_crc := Update32(songdata,SizeOf(songdata),0);
  For temp := 1 to 255 do
    songdata.instr_names[temp][1] := temp_marks[temp];

  Move(v_ofs^,vscreen,SizeOf(vscreen));
  centered_frame_vdest := Addr(vscreen);

  If NOT arp_vib_mode then
    centered_frame(xstart,ystart,81+window_area_inc_x,24+window_area_inc_y,
                  ' iNSTRUMENT MACRO EDiTOR (iNS_  ) ',
                   macro_background+dialog_border,
                   macro_background+dialog_title,
                   double)
  else
    centered_frame(xstart,ystart,81+window_area_inc_x,24+window_area_inc_y,
                  ' ARPEGGiO/ViBRATO MACRO EDiTOR (iNS_  ) ',
                   macro_background+dialog_border,
                   macro_background+dialog_title,
                   double);

  _pip_xloc := xstart+30+(window_area_inc_x DIV 2);
  _pip_yloc := ystart+2;
  _pip_dest := Addr(vscreen);

  move_to_screen_data := Addr(vscreen);
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+81+2+window_area_inc_x;
  move_to_screen_area[4] := ystart+24+1+window_area_inc_y;
  refresh;

  move_to_screen_area[1] := xstart+1;
  move_to_screen_area[2] := ystart+1;
  move_to_screen_area[3] := xstart+80+window_area_inc_x;
  move_to_screen_area[4] := ystart+24+window_area_inc_y;

  If (pos = 1) then GotoXY(xstart+17,ystart+4);
  ThinCursor;
  centered_frame_vdest := v_ofs;

  Move(is_setting.terminate_keys,old_keys,SizeOf(old_keys));
  Move(new_keys,is_setting.terminate_keys,SizeOf(new_keys));

_jmp2:
  If NOT arp_vib_mode then
    begin
      songdata.instr_macros[instr].arpeggio_table := ptr_arpeggio_table^;
      songdata.instr_macros[instr].vibrato_table := ptr_vibrato_table^;
    end;

  If (instr <> current_inst) then
    instr := current_inst;

  If NOT arp_vib_mode then
    begin
      ptr_arpeggio_table := Addr(songdata.instr_macros[instr].arpeggio_table);
      ptr_vibrato_table := Addr(songdata.instr_macros[instr].vibrato_table);
    end;

  If arp_vib_mode and (pos < 8) then pos := 8
  else If NOT arp_vib_mode and
          (((ptr_arpeggio_table^ = 0) and (pos in [8..13])) or
           ((ptr_vibrato_table^ = 0) and (pos in [14..20]))) then
          pos := 1;
       
  If NOT arp_vib_mode then
    ShowStr(centered_frame_vdest^,xstart+54+(window_area_inc_x DIV 2),ystart,
            byte2hex(instr),macro_background+dialog_title)
  else
    ShowStr(centered_frame_vdest^,xstart+57+(window_area_inc_x DIV 2),ystart,
            byte2hex(instr),macro_background+dialog_title);

  If NOT _force_program_quit then
    Repeat
      refresh;
      is_setting.append_enabled := TRUE;
      is_environment.locate_pos := 1;

      Case pos of

    (* FM_op_table table - pos: 1..7 *)

        1: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.instr_macros[instr].length),
                                 xstart+17,ystart+4,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.instr_macros[instr].length := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.instr_macros[instr].length < 255) then
                            Inc(songdata.instr_macros[instr].length);
                 kNPmins: If (songdata.instr_macros[instr].length > 0) then
                            Dec(songdata.instr_macros[instr].length);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 2
             else If (is_environment.keystroke = kUP) then pos := 7
                  else If (is_environment.keystroke = kShTAB) then
                         If (ptr_vibrato_table^ <> 0) then pos := 20
                         else If (ptr_arpeggio_table^ <> 0) then pos := 13
                              else pos := 7;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.instr_macros[instr].length > 0) then
                             Dec(songdata.instr_macros[instr].length)
                           else
                        else If (songdata.instr_macros[instr].loop_begin > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.instr_macros[instr].length < 255) then
                            Inc(songdata.instr_macros[instr].length)
                          else
                        else If (songdata.instr_macros[instr].loop_begin < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtLEFT: If (ptr_vibrato_table^ <> 0) then pos := 14
                        else If (ptr_arpeggio_table^ <> 0) then pos := 8;

               kCtRGHT: If (ptr_arpeggio_table^ <> 0) then pos := 8
                        else If (ptr_vibrato_table^ <> 0) then pos := 14;

               kCtPgUP: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtPgDN: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttFM_reg_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

        2: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.instr_macros[instr].loop_begin),
                                 xstart+17,ystart+5,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.instr_macros[instr].loop_begin := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.instr_macros[instr].loop_begin < 255) then
                            Inc(songdata.instr_macros[instr].loop_begin);
                 kNPmins: If (songdata.instr_macros[instr].loop_begin > 0) then
                            Dec(songdata.instr_macros[instr].loop_begin);
               end;

             While NOT ((songdata.instr_macros[instr].keyoff_pos > songdata.instr_macros[instr].loop_begin+
                                     min0(songdata.instr_macros[instr].loop_length-1,0)) or
                        (songdata.instr_macros[instr].loop_begin = 0) or
                        (songdata.instr_macros[instr].loop_length = 0) or
                        (songdata.instr_macros[instr].keyoff_pos = 0)) do
               Inc(songdata.instr_macros[instr].keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 3
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 1;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.instr_macros[instr].length > 0) then
                             Dec(songdata.instr_macros[instr].length)
                           else
                        else If (songdata.instr_macros[instr].loop_begin > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.instr_macros[instr].length < 255) then
                            Inc(songdata.instr_macros[instr].length)
                          else
                        else If (songdata.instr_macros[instr].loop_begin < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtLEFT: If (ptr_vibrato_table^ <> 0) then pos := 17
                        else If (ptr_arpeggio_table^ <> 0) then pos := 10;

               kCtRGHT: If (ptr_arpeggio_table^ <> 0) then pos := 10
                        else If (ptr_vibrato_table^ <> 0) then pos := 17;

               kCtPgUP: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtPgDN: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttFM_reg_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

        3: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.instr_macros[instr].loop_length),
                                 xstart+17,ystart+6,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.instr_macros[instr].loop_length := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.instr_macros[instr].loop_length < 255) then
                            Inc(songdata.instr_macros[instr].loop_length);
                 kNPmins: If (songdata.instr_macros[instr].loop_length > 0) then
                            Dec(songdata.instr_macros[instr].loop_length);
               end;

             While NOT ((songdata.instr_macros[instr].keyoff_pos > songdata.instr_macros[instr].loop_begin+
                                     min0(songdata.instr_macros[instr].loop_length-1,0)) or
                        (songdata.instr_macros[instr].loop_begin = 0) or
                        (songdata.instr_macros[instr].loop_length = 0) or
                        (songdata.instr_macros[instr].keyoff_pos = 0)) do
               Inc(songdata.instr_macros[instr].keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 4
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 2;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.instr_macros[instr].length > 0) then
                             Dec(songdata.instr_macros[instr].length)
                           else
                        else If (songdata.instr_macros[instr].loop_begin > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.instr_macros[instr].length < 255) then
                            Inc(songdata.instr_macros[instr].length)
                          else
                        else If (songdata.instr_macros[instr].loop_begin < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtLEFT: If (ptr_vibrato_table^ <> 0) then pos := 18
                        else If (ptr_arpeggio_table^ <> 0) then pos := 11;

               kCtRGHT: If (ptr_arpeggio_table^ <> 0) then pos := 11
                        else If (ptr_vibrato_table^ <> 0) then pos := 18;

               kCtPgUP: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtPgDN: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttFM_reg_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

        4: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.instr_macros[instr].keyoff_pos),
                                 xstart+17,ystart+7,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   (Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255) and
                   (Str2num(temps,16) > songdata.instr_macros[instr].loop_begin+
                                        min0(songdata.instr_macros[instr].loop_length-1,0)) or
                   (songdata.instr_macros[instr].loop_begin = 0) or
                   (songdata.instr_macros[instr].loop_length = 0) or
                   (Str2num(temps,16) = 0);

             songdata.instr_macros[instr].keyoff_pos := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.instr_macros[instr].loop_begin = 0) or
                             (songdata.instr_macros[instr].loop_length = 0) or
                             (songdata.instr_macros[instr].keyoff_pos <> 0) then
                            If (songdata.instr_macros[instr].keyoff_pos < 255) then
                              Inc(songdata.instr_macros[instr].keyoff_pos)
                            else
                          else If (songdata.instr_macros[instr].loop_begin+
                                   songdata.instr_macros[instr].loop_length <= 255) then
                                 songdata.instr_macros[instr].keyoff_pos :=
                                   songdata.instr_macros[instr].loop_begin+
                                   songdata.instr_macros[instr].loop_length;

                 kNPmins: If (min0(songdata.instr_macros[instr].keyoff_pos-1,0) > songdata.instr_macros[instr].loop_begin+
                                min0(songdata.instr_macros[instr].loop_length-1,0)) or
                             ((songdata.instr_macros[instr].keyoff_pos > 0) and
                             ((songdata.instr_macros[instr].loop_begin = 0) or
                              (songdata.instr_macros[instr].loop_length = 0))) then
                            Dec(songdata.instr_macros[instr].keyoff_pos);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 5
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 3;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.instr_macros[instr].length > 0) then
                             Dec(songdata.instr_macros[instr].length)
                           else
                        else If (songdata.instr_macros[instr].loop_begin > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.instr_macros[instr].length < 255) then
                            Inc(songdata.instr_macros[instr].length)
                          else
                        else If (songdata.instr_macros[instr].loop_begin < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtLEFT: If (ptr_vibrato_table^ <> 0) then pos := 19
                        else If (ptr_arpeggio_table^ <> 0) then pos := 12;

               kCtRGHT: If (ptr_arpeggio_table^ <> 0) then pos := 12
                        else If (ptr_vibrato_table^ <> 0) then pos := 19;

               kCtPgUP: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtPgDN: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttFM_reg_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

        5: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(ptr_arpeggio_table^),
                                 xstart+17,ystart+8,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             ptr_arpeggio_table^ := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (ptr_arpeggio_table^ < 255) then
                            Inc(ptr_arpeggio_table^);
                 kNPmins: If (ptr_arpeggio_table^ > 0) then
                            Dec(ptr_arpeggio_table^);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 6
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 4;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.instr_macros[instr].length > 0) then
                             Dec(songdata.instr_macros[instr].length)
                           else
                        else If (songdata.instr_macros[instr].loop_begin > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.instr_macros[instr].length < 255) then
                            Inc(songdata.instr_macros[instr].length)
                          else
                        else If (songdata.instr_macros[instr].loop_begin < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtLEFT: If (ptr_vibrato_table^ <> 0) then pos := 14
                        else If (ptr_arpeggio_table^ <> 0) then pos := 8;

               kCtRGHT: If (ptr_arpeggio_table^ <> 0) then pos := 8
                        else If (ptr_vibrato_table^ <> 0) then pos := 14;

               kCtPgUP: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtPgDN: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttFM_reg_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

        6: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(ptr_vibrato_table^),
                                 xstart+17,ystart+9,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             ptr_vibrato_table^ := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (ptr_vibrato_table^ < 255) then
                            Inc(ptr_vibrato_table^);
                 kNPmins: If (ptr_vibrato_table^ > 0) then
                            Dec(ptr_vibrato_table^);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 7
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 5;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.instr_macros[instr].length > 0) then
                             Dec(songdata.instr_macros[instr].length)
                           else
                        else If (songdata.instr_macros[instr].loop_begin > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.instr_macros[instr].length < 255) then
                            Inc(songdata.instr_macros[instr].length)
                          else
                        else If (songdata.instr_macros[instr].loop_begin < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtLEFT: If (ptr_vibrato_table^ <> 0) then pos := 14
                        else If (ptr_arpeggio_table^ <> 0) then pos := 8;

               kCtRGHT: If (ptr_arpeggio_table^ <> 0) then pos := 8
                        else If (ptr_vibrato_table^ <> 0) then pos := 14;

               kCtPgUP: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtPgDN: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttFM_reg_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

        7: begin
             GotoXY(xstart+10+fmreg_cursor_pos-1,ystart+16+(window_area_inc_y DIV 2));
             is_environment.keystroke := getkey;

             If (HI(is_environment.keystroke) = HI(kSlashR)) then
               With songdata.instr_macros[instr].data[fmreg_page] do
                 begin
                   nope := TRUE;
                   Case fmreg_hpos of
                     10: fm_data.AM_VIB_EG_modulator :=
                         fm_data.AM_VIB_EG_modulator XOR $80;
                     11: fm_data.AM_VIB_EG_modulator :=
                         fm_data.AM_VIB_EG_modulator XOR $40;
                     12: fm_data.AM_VIB_EG_modulator :=
                         fm_data.AM_VIB_EG_modulator XOR $10;
                     13: fm_data.AM_VIB_EG_modulator :=
                         fm_data.AM_VIB_EG_modulator XOR $20;

                     23: fm_data.AM_VIB_EG_carrier :=
                         fm_data.AM_VIB_EG_carrier XOR $80;
                     24: fm_data.AM_VIB_EG_carrier :=
                         fm_data.AM_VIB_EG_carrier XOR $40;
                     25: fm_data.AM_VIB_EG_carrier :=
                         fm_data.AM_VIB_EG_carrier XOR $10;
                     26: fm_data.AM_VIB_EG_carrier :=
                         fm_data.AM_VIB_EG_carrier XOR $20;

                     33: begin
                           nope := FALSE;
                           Case panning of
                             0: panning := 2;
                             1: panning := 0;
                             2: panning := 1;
                           end;
                         end
                     else
                       nope := FALSE;
                   end;

                   If nope then
                     If (fmreg_page < 255) then Inc(fmreg_page)
                     else If cycle_pattern then fmreg_page := 1;
                 end;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.instr_macros[instr].length > 0) then
                             Dec(songdata.instr_macros[instr].length)
                           else
                        else If (songdata.instr_macros[instr].loop_begin > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.instr_macros[instr].length < 255) then
                            Inc(songdata.instr_macros[instr].length)
                          else
                        else If (songdata.instr_macros[instr].loop_begin < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_begin);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtPgUP: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length > 0) then
                               begin
                                 Dec(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtPgDN: If NOT shift_pressed then
                        else If (songdata.instr_macros[instr].loop_length < 255) then
                               begin
                                 Inc(songdata.instr_macros[instr].loop_length);
                                 While NOT ((songdata.instr_macros[instr].
                                             keyoff_pos > songdata.instr_macros[instr].
                                                                  loop_begin+
                                                         min0(songdata.instr_macros[instr].
                                                              loop_length-1,0)) or
                                            (songdata.instr_macros[instr].loop_begin = 0) or
                                            (songdata.instr_macros[instr].loop_length = 0) or
                                            (songdata.instr_macros[instr].keyoff_pos = 0)) do
                                   Inc(songdata.instr_macros[instr].keyoff_pos);
                               end;

               kCtLEFT: If NOT shift_pressed then
                          If (ptr_vibrato_table^ <> 0) then pos := 20
                          else If (ptr_arpeggio_table^ <> 0) then pos := 13
                               else
                        else If (fmreg_page > songdata.instr_macros[instr].length) then
                               fmreg_page := min(1,songdata.instr_macros[instr].length)
                             else fmreg_page := 1;

               kCtRGHT: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ <> 0) then pos := 13
                          else If (ptr_vibrato_table^ <> 0) then pos := 20
                               else
                        else If (fmreg_page < songdata.instr_macros[instr].length) then
                               fmreg_page := min(1,songdata.instr_macros[instr].length)
                             else fmreg_page := 255;

               kUP: If (fmreg_page > 1) then Dec(fmreg_page)
                    else If cycle_pattern then fmreg_page := 255;

               kDOWN: If (fmreg_page < 255) then Inc(fmreg_page)
                      else If cycle_pattern then fmreg_page := 1;

               kShUP: If shift_pressed then
                        If (fmreg_page > 1) then Dec(fmreg_page)
                        else If cycle_pattern then fmreg_page := 255;

               kShDOWN: If shift_pressed then
                          If (fmreg_page < 255) then Inc(fmreg_page)
                          else If cycle_pattern then fmreg_page := 1;

               kPgUP: If (fmreg_page > 16) then Dec(fmreg_page,16)
                      else fmreg_page := 1;

               kPgDOWN: If (fmreg_page+16 < 255) then Inc(fmreg_page,16)
                        else fmreg_page := 255;

               kHOME: If NOT shift_pressed then fmreg_page := 1
                      else begin
                             fmreg_hpos := 1;
                             fmreg_cursor_pos := 1;
                             fmreg_left_margin := 1;
                           end;

               kEND: If NOT shift_pressed then fmreg_page := 255
                     else begin
                            fmreg_hpos := 35;
                            fmreg_cursor_pos := 31;
                            fmreg_left_margin := pos5[fmreg_hpos]-31+1;
                          end;

               kNPHOME: If shift_pressed then
                          begin
                            fmreg_hpos := 1;
                            fmreg_cursor_pos := 1;
                            fmreg_left_margin := 1;
                          end;

               kNPEND: If shift_pressed then
                         begin
                           fmreg_hpos := 35;
                           fmreg_cursor_pos := 31;
                           fmreg_left_margin := pos5[fmreg_hpos]-31+1;
                         end;

               kLEFT: If (fmreg_hpos > 1) then
                        begin
                          Dec(fmreg_hpos);
                          _scroll_cur_left;
                        end
                      else If cycle_pattern then
                             begin
                               fmreg_hpos := 35;
                               fmreg_cursor_pos := 31;
                               fmreg_left_margin := pos5[fmreg_hpos]-31+1;
                             end;

               kRIGHT: If (fmreg_hpos < 35) then
                         begin
                           Inc(fmreg_hpos);
                           _scroll_cur_right;
                         end
                       else If cycle_pattern then
                              begin
                                fmreg_hpos := 1;
                                fmreg_cursor_pos := 1;
                                fmreg_left_margin := 1;
                              end;

               kTAB: If (ptr_arpeggio_table^ <> 0) then pos := 8
                     else If (ptr_vibrato_table^ <> 0) then pos := 14
                            else pos := 1;

               kShTAB: pos := 6;

               kENTER: If NOT shift_pressed then
                         begin
                           If (ptr_arpeggio_table^ <> 0) then pos := 8
                           else If (ptr_vibrato_table^ <> 0) then pos := 14
                                else pos := 1;
                         end
                       else call_pickup_proc2 := TRUE;

               kCtrlC: begin
                         If NOT shift_pressed then clipboard.object_type := objMacroTableLine
                         else clipboard.object_type := objMacroTableColumn;
                         clipboard.mcrtab_type := mttFM_reg_table;
                         copy_object;
                       end;
               kCtrlV,
               kAltP: begin
                        paste_object;
                        If (clipboard.object_type = objMacroTableLine) and
                           (clipboard.mcrtab_type = mttFM_reg_table) then
                          If (fmreg_page < 255) then Inc(fmreg_page)
                          else If cycle_pattern then fmreg_page := 1;
                      end;

               kCtrlN: begin
                         songdata.instr_macros[instr].data[fmreg_page].fm_data.
                           FEEDBACK_FM :=
                         songdata.instr_macros[instr].data[fmreg_page].fm_data.
                           FEEDBACK_FM XOR $80;
                         If (fmreg_page < 255) then Inc(fmreg_page)
                         else If cycle_pattern then fmreg_page := 1;
                       end;

               kAltN:  If ctrl_pressed then
                         For temp := 1 to 255 do
                            songdata.instr_macros[instr].data[temp].fm_data.
                              FEEDBACK_FM :=
                            songdata.instr_macros[instr].data[temp].fm_data.
                              FEEDBACK_FM AND $7f;

               kCtENTR: If NOT shift_pressed then
                          begin
                            temp := songdata.instr_macros[instr].data[fmreg_page].
                                    fm_data.FEEDBACK_FM;
                            songdata.instr_macros[instr].data[fmreg_page].fm_data :=
                              songdata.instr_data[instr].fm_data;
                            songdata.instr_macros[instr].data[fmreg_page].
                            fm_data.FEEDBACK_FM := temp AND $0c0+
                              songdata.instr_data[instr].fm_data.FEEDBACK_FM;

                            songdata.instr_macros[instr].data[fmreg_page].panning :=
                              songdata.instr_data[instr].panning;
                            songdata.instr_macros[instr].data[fmreg_page].duration :=
                              min(songdata.instr_macros[instr].data[fmreg_page].duration,1);

                            With songdata.instr_macros[instr].data[fmreg_page].fm_data do
                              begin
                                KSL_VOLUM_modulator := KSL_VOLUM_modulator AND $c0+
                                                       63-KSL_VOLUM_modulator AND $3f;
                                KSL_VOLUM_carrier := KSL_VOLUM_carrier AND $c0+
                                                     63-KSL_VOLUM_carrier AND $3f;
                              end;

                            If (fmreg_page < 255) then Inc(fmreg_page)
                            else If cycle_pattern then fmreg_page := 1;
                          end
                        else call_pickup_proc := TRUE;

               kINSERT: begin
                          For temp := 255-1 downto fmreg_page do
                            begin
                              songdata.instr_macros[instr].data[SUCC(temp)] :=
                                songdata.instr_macros[instr].data[temp]
                            end;
                          FillChar(songdata.instr_macros[instr].data[fmreg_page],
                                   SizeOf(songdata.instr_macros[instr].data[fmreg_page]),0);
                        end;

               kDELETE: begin
                          For temp := fmreg_page to 255-1 do
                            begin
                              songdata.instr_macros[instr].data[temp] :=
                                songdata.instr_macros[instr].data[SUCC(temp)]
                            end;
                          FillChar(songdata.instr_macros[instr].data[255],
                                   SizeOf(songdata.instr_macros[instr].data[255]),0);
                        end;

               kNPplus: If shift_pressed then
                          With songdata.instr_macros[instr].data[fmreg_page] do
                            Case fmreg_hpos of
                              1: fm_data.ATTCK_DEC_modulator :=
                                 _inc(fm_data.ATTCK_DEC_modulator SHR 4,15) SHL 4+
                                 fm_data.ATTCK_DEC_modulator AND $0f;
                              2: fm_data.ATTCK_DEC_modulator :=
                                 fm_data.ATTCK_DEC_modulator AND $0f0+
                                 _inc(fm_data.ATTCK_DEC_modulator AND $0f,15);
                              3: fm_data.SUSTN_REL_modulator :=
                                 _inc(fm_data.SUSTN_REL_modulator SHR 4,15) SHL 4+
                                 fm_data.SUSTN_REL_modulator AND $0f;
                              4: fm_data.SUSTN_REL_modulator :=
                                 fm_data.SUSTN_REL_modulator AND $0f0+
                                 _inc(fm_data.SUSTN_REL_modulator AND $0f,15);
                              5: fm_data.WAVEFORM_modulator :=
                                 _inc(fm_data.WAVEFORM_modulator,7);
                              6,
                              7: fm_data.KSL_VOLUM_modulator :=
                                 fm_data.KSL_VOLUM_modulator AND $0c0+
                                 _inc(fm_data.KSL_VOLUM_modulator AND $3f,63);
                              8: fm_data.KSL_VOLUM_modulator :=
                                 fm_data.KSL_VOLUM_modulator AND $3f+
                                 _inc(fm_data.KSL_VOLUM_modulator SHR 6,3) SHL 6;
                              9: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0f0+
                                 _inc(fm_data.AM_VIB_EG_modulator AND $0f,15);
                             10: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $7f+
                                 _inc(fm_data.AM_VIB_EG_modulator SHR 7,1) SHL 7;
                             11: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0bf+
                                 _inc(fm_data.AM_VIB_EG_modulator SHR 6 AND 1,1) SHL 6;
                             12: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0ef+
                                 _inc(fm_data.AM_VIB_EG_modulator SHR 4 AND 1,1) SHL 4;
                             13: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0df+
                                 _inc(fm_data.AM_VIB_EG_modulator SHR 5 AND 1,1) SHL 5;
                             14: fm_data.ATTCK_DEC_carrier :=
                                 _inc(fm_data.ATTCK_DEC_carrier SHR 4,15) SHL 4+
                                 fm_data.ATTCK_DEC_carrier AND $0f;
                             15: fm_data.ATTCK_DEC_carrier :=
                                 fm_data.ATTCK_DEC_carrier AND $0f0+
                                 _inc(fm_data.ATTCK_DEC_carrier AND $0f,15);
                             16: fm_data.SUSTN_REL_carrier :=
                                 _inc(fm_data.SUSTN_REL_carrier SHR 4,15) SHL 4+
                                 fm_data.SUSTN_REL_carrier AND $0f;
                             17: fm_data.SUSTN_REL_carrier :=
                                 fm_data.SUSTN_REL_carrier AND $0f0+
                                 _inc(fm_data.SUSTN_REL_carrier AND $0f,15);
                             18: fm_data.WAVEFORM_carrier :=
                                 _inc(fm_data.WAVEFORM_carrier,7);
                             19,
                             20: fm_data.KSL_VOLUM_carrier :=
                                 fm_data.KSL_VOLUM_carrier AND $0c0+
                                 _inc(fm_data.KSL_VOLUM_carrier AND $3f,63);
                             21: fm_data.KSL_VOLUM_carrier :=
                                 fm_data.KSL_VOLUM_carrier AND $3f+
                                 _inc(fm_data.KSL_VOLUM_carrier SHR 6,3) SHL 6;
                             22: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $0f0+
                                 _inc(fm_data.AM_VIB_EG_carrier AND $0f,15);
                             23: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $7f+
                                 _inc(fm_data.AM_VIB_EG_carrier SHR 7,1) SHL 7;
                             24: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $0bf+
                                 _inc(fm_data.AM_VIB_EG_carrier SHR 6 AND 1,1) SHL 6;
                             25: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $0ef+
                                 _inc(fm_data.AM_VIB_EG_carrier SHR 4 AND 1,1) SHL 4;
                             26: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $0df+
                                 _inc(fm_data.AM_VIB_EG_carrier SHR 5 AND 1,1) SHL 5;
                             27: fm_data.FEEDBACK_FM :=
                                 fm_data.FEEDBACK_FM AND $0fe+
                                 _inc(fm_data.FEEDBACK_FM AND 1,1);
                             28: fm_data.FEEDBACK_FM :=
                                 fm_data.FEEDBACK_FM AND 1+
                                 _inc(fm_data.FEEDBACK_FM SHR 1,7) SHL 1;

                             29,30,31,
                             32: freq_slide :=
                                 _inc(freq_slide,1023);
                             33: Case panning of
                                   0: panning := 2;
                                   1: panning := 0;
                                 end;
                             34,
                             35: duration :=
                                 _inc(duration,255);
                            end;

               kNPmins: If shift_pressed then
                          With songdata.instr_macros[instr].data[fmreg_page] do
                            Case fmreg_hpos of
                              1: fm_data.ATTCK_DEC_modulator :=
                                 _dec(fm_data.ATTCK_DEC_modulator SHR 4,0) SHL 4+
                                 fm_data.ATTCK_DEC_modulator AND $0f;
                              2: fm_data.ATTCK_DEC_modulator :=
                                 fm_data.ATTCK_DEC_modulator AND $0f0+
                                 _dec(fm_data.ATTCK_DEC_modulator AND $0f,0);
                              3: fm_data.SUSTN_REL_modulator :=
                                 _dec(fm_data.SUSTN_REL_modulator SHR 4,0) SHL 4+
                                 fm_data.SUSTN_REL_modulator AND $0f;
                              4: fm_data.SUSTN_REL_modulator :=
                                 fm_data.SUSTN_REL_modulator AND $0f0+
                                 _dec(fm_data.SUSTN_REL_modulator AND $0f,0);
                              5: fm_data.WAVEFORM_modulator :=
                                 _dec(fm_data.WAVEFORM_modulator,0);
                              6,
                              7: fm_data.KSL_VOLUM_modulator :=
                                 fm_data.KSL_VOLUM_modulator AND $0c0+
                                 _dec(fm_data.KSL_VOLUM_modulator AND $3f,0);
                              8: fm_data.KSL_VOLUM_modulator :=
                                 fm_data.KSL_VOLUM_modulator AND $3f+
                                 _dec(fm_data.KSL_VOLUM_modulator SHR 6,0) SHL 6;
                              9: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0f0+
                                 _dec(fm_data.AM_VIB_EG_modulator AND $0f,0);
                             10: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $7f+
                                 _dec(fm_data.AM_VIB_EG_modulator SHR 7,0) SHL 7;
                             11: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0bf+
                                 _dec(fm_data.AM_VIB_EG_modulator SHR 6 AND 1,0) SHL 6;
                             12: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0ef+
                                 _dec(fm_data.AM_VIB_EG_modulator SHR 4 AND 1,0) SHL 4;
                             13: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0df+
                                 _dec(fm_data.AM_VIB_EG_modulator SHR 5 AND 1,0) SHL 5;
                             14: fm_data.ATTCK_DEC_carrier :=
                                 _dec(fm_data.ATTCK_DEC_carrier SHR 4,0) SHL 4+
                                 fm_data.ATTCK_DEC_carrier AND $0f;
                             15: fm_data.ATTCK_DEC_carrier :=
                                 fm_data.ATTCK_DEC_carrier AND $0f0+
                                 _dec(fm_data.ATTCK_DEC_carrier AND $0f,0);
                             16: fm_data.SUSTN_REL_carrier :=
                                 _dec(fm_data.SUSTN_REL_carrier SHR 4,0) SHL 4+
                                 fm_data.SUSTN_REL_carrier AND $0f;
                             17: fm_data.SUSTN_REL_carrier :=
                                 fm_data.SUSTN_REL_carrier AND $0f0+
                                 _dec(fm_data.SUSTN_REL_carrier AND $0f,0);
                             18: fm_data.WAVEFORM_carrier :=
                                 _dec(fm_data.WAVEFORM_carrier,0);
                             19,
                             20: fm_data.KSL_VOLUM_carrier :=
                                 fm_data.KSL_VOLUM_carrier AND $0c0+
                                 _dec(fm_data.KSL_VOLUM_carrier AND $3f,0);
                             21: fm_data.KSL_VOLUM_carrier :=
                                 fm_data.KSL_VOLUM_carrier AND $3f+
                                 _dec(fm_data.KSL_VOLUM_carrier SHR 6,0) SHL 6;
                             22: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $0f0+
                                 _dec(fm_data.AM_VIB_EG_carrier AND $0f,0);
                             23: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $7f+
                                 _dec(fm_data.AM_VIB_EG_carrier SHR 7,0) SHL 7;
                             24: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $0bf+
                                 _dec(fm_data.AM_VIB_EG_carrier SHR 6 AND 1,0) SHL 6;
                             25: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $0ef+
                                 _dec(fm_data.AM_VIB_EG_carrier SHR 4 AND 1,0) SHL 4;
                             26: fm_data.AM_VIB_EG_carrier :=
                                 fm_data.AM_VIB_EG_carrier AND $0df+
                                 _dec(fm_data.AM_VIB_EG_carrier SHR 5 AND 1,0) SHL 5;
                             27: fm_data.FEEDBACK_FM :=
                                 fm_data.FEEDBACK_FM AND $0fe+
                                 _dec(fm_data.FEEDBACK_FM AND 1,0);
                             28: fm_data.FEEDBACK_FM :=
                                 fm_data.FEEDBACK_FM AND 1+
                                 _dec(fm_data.FEEDBACK_FM SHR 1,0) SHL 1;

                             29,30,31,
                             32: freq_slide :=
                                 _dec(freq_slide,-1023);
                             33: Case panning of
                                   0: panning := 1;
                                   2: panning := 0;
                                 end;
                             34,
                             35: duration :=
                                 _dec(duration,0);
                            end;

               kBkSPC: If NOT shift_pressed then
                         With songdata.instr_macros[instr].data[fmreg_page] do
                           begin
                             Case fmreg_hpos of
                               1: fm_data.ATTCK_DEC_modulator :=
                                  fm_data.ATTCK_DEC_modulator AND $0f;
                               2: fm_data.ATTCK_DEC_modulator :=
                                  fm_data.ATTCK_DEC_modulator AND $0f0;
                               3: fm_data.SUSTN_REL_modulator :=
                                  fm_data.SUSTN_REL_modulator AND $0f;
                               4: fm_data.SUSTN_REL_modulator :=
                                  fm_data.SUSTN_REL_modulator AND $0f0;
                               5: fm_data.WAVEFORM_modulator := 0;
                               6,
                               7: fm_data.KSL_VOLUM_modulator :=
                                  fm_data.KSL_VOLUM_modulator AND $0c0;
                               8: fm_data.KSL_VOLUM_modulator :=
                                  fm_data.KSL_VOLUM_modulator AND $3f;
                               9: fm_data.AM_VIB_EG_modulator :=
                                  fm_data.AM_VIB_EG_modulator AND $0f0;
                              10: fm_data.AM_VIB_EG_modulator :=
                                  fm_data.AM_VIB_EG_modulator AND $7f;
                              11: fm_data.AM_VIB_EG_modulator :=
                                  fm_data.AM_VIB_EG_modulator AND $0bf;
                              12: fm_data.AM_VIB_EG_modulator :=
                                  fm_data.AM_VIB_EG_modulator AND $0ef;
                              13: fm_data.AM_VIB_EG_modulator :=
                                  fm_data.AM_VIB_EG_modulator AND $0df;

                              14: fm_data.ATTCK_DEC_carrier :=
                                  fm_data.ATTCK_DEC_carrier AND $0f;
                              15: fm_data.ATTCK_DEC_carrier :=
                                  fm_data.ATTCK_DEC_carrier AND $0f0;
                              16: fm_data.SUSTN_REL_carrier :=
                                  fm_data.SUSTN_REL_carrier AND $0f;
                              17: fm_data.SUSTN_REL_carrier :=
                                  fm_data.SUSTN_REL_carrier AND $0f0;
                              18: fm_data.WAVEFORM_carrier := 0;
                              19,
                              20: fm_data.KSL_VOLUM_carrier :=
                                  fm_data.KSL_VOLUM_carrier AND $0c0;
                              21: fm_data.KSL_VOLUM_carrier :=
                                  fm_data.KSL_VOLUM_carrier AND $3f;
                              22: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $0f0;
                              23: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $7f;
                              24: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $0bf;
                              25: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $0ef;
                              26: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $0df;

                              27: fm_data.FEEDBACK_FM :=
                                  fm_data.FEEDBACK_FM AND $0fe;
                              28: fm_data.FEEDBACK_FM :=
                                  fm_data.FEEDBACK_FM AND $0c1;

                              29,30,31,
                              32: freq_slide := 0;

                              33: panning := 0;
                              34,
                              35: duration := 0;
                             end;

                             If (fmreg_page < 255) then Inc(fmreg_page)
                             else If cycle_pattern then fmreg_page := 1;
                           end
                       else begin
                              FillChar(songdata.instr_macros[instr].data[fmreg_page].fm_data,
                                       SizeOf(songdata.instr_macros[instr].data[fmreg_page].fm_data),0);
                              songdata.instr_macros[instr].data[fmreg_page].freq_slide := 0;
                              songdata.instr_macros[instr].data[fmreg_page].panning := 0;
                              songdata.instr_macros[instr].data[fmreg_page].duration := 0;
                              If (fmreg_page < 255) then Inc(fmreg_page)
                              else If cycle_pattern then fmreg_page := 1;
                            end;

               kCtBkSp: Case fmreg_hpos of
                          1,2,3,4,
                          5: songdata.dis_fmreg_col[instr][fmreg_hpos-1] :=
                               NOT songdata.dis_fmreg_col[instr][fmreg_hpos-1];
                          6,
                          7: songdata.dis_fmreg_col[instr][5] :=
                               NOT songdata.dis_fmreg_col[instr][5];

                          8,9,10,11,12,13,
                          14,15,16,17,
                          18: songdata.dis_fmreg_col[instr][fmreg_hpos-2] :=
                                NOT songdata.dis_fmreg_col[instr][fmreg_hpos-2];
                          19,
                          20: songdata.dis_fmreg_col[instr][17] :=
                                NOT songdata.dis_fmreg_col[instr][17];

                          21,22,23,24,
                          25,26,27,
                          28: songdata.dis_fmreg_col[instr][fmreg_hpos-3] :=
                                NOT songdata.dis_fmreg_col[instr][fmreg_hpos-3];

                          29,30,31,
                          32: songdata.dis_fmreg_col[instr][26] :=
                                NOT songdata.dis_fmreg_col[instr][26];

                          33: songdata.dis_fmreg_col[instr][27] :=
                                NOT songdata.dis_fmreg_col[instr][27];
                        end;

               kAltS:   Case fmreg_hpos of
                          1,2,3,4,
                          5: For temp := 0 to 27 do
                               If (temp <> fmreg_hpos-1) then
                                 songdata.dis_fmreg_col[instr][temp] := TRUE
                               else songdata.dis_fmreg_col[instr][temp] := FALSE;
                          6,
                          7: For temp := 0 to 27 do
                               If (temp <> 5) then
                                 songdata.dis_fmreg_col[instr][temp] := TRUE
                               else songdata.dis_fmreg_col[instr][temp] := FALSE;

                          8,9,10,11,12,13,
                          14,15,16,17,
                          18: For temp := 0 to 27 do
                               If (temp <> fmreg_hpos-2) then
                                 songdata.dis_fmreg_col[instr][temp] := TRUE
                               else songdata.dis_fmreg_col[instr][temp] := FALSE;
                          19,
                          20: For temp := 0 to 27 do
                               If (temp <> 17) then
                                 songdata.dis_fmreg_col[instr][temp] := TRUE
                               else songdata.dis_fmreg_col[instr][temp] := FALSE;

                          21,22,23,24,
                          25,26,27,
                          28: For temp := 0 to 27 do
                               If (temp <> fmreg_hpos-3) then
                                 songdata.dis_fmreg_col[instr][temp] := TRUE
                               else songdata.dis_fmreg_col[instr][temp] := FALSE;

                          29,30,31,
                          32: For temp := 0 to 27 do
                               If (temp <> 26) then
                                 songdata.dis_fmreg_col[instr][temp] := TRUE
                               else songdata.dis_fmreg_col[instr][temp] := FALSE;

                          33: For temp := 0 to 27 do
                               If (temp <> 27) then
                                 songdata.dis_fmreg_col[instr][temp] := TRUE
                               else songdata.dis_fmreg_col[instr][temp] := FALSE;
                        end;

               kAltR: For temp := 0 to 27 do
                        songdata.dis_fmreg_col[instr][temp] := FALSE;

               kNPastr: For temp := 0 to 27 do
                          songdata.dis_fmreg_col[instr][temp] :=
                            NOT songdata.dis_fmreg_col[instr][temp];
             end;

             If (UpCase(CHAR(LO(is_environment.keystroke))) in ['0'..'9','A'..'F']) and
                NOT shift_pressed then
               With songdata.instr_macros[instr].data[fmreg_page] do
                 begin
                   nope := TRUE;
                   Case fmreg_hpos of
                     1: fm_data.ATTCK_DEC_modulator :=
                        hex(CHAR(LO(is_environment.keystroke))) SHL 4+
                        fm_data.ATTCK_DEC_modulator AND $0f;
                     2: fm_data.ATTCK_DEC_modulator :=
                        fm_data.ATTCK_DEC_modulator AND $0f0+
                        hex(CHAR(LO(is_environment.keystroke)));
                     3: fm_data.SUSTN_REL_modulator :=
                        hex(CHAR(LO(is_environment.keystroke))) SHL 4+
                        fm_data.SUSTN_REL_modulator AND $0f;
                     4: fm_data.SUSTN_REL_modulator :=
                        fm_data.SUSTN_REL_modulator AND $0f0+
                        hex(CHAR(LO(is_environment.keystroke)));

                     5: If (hex(CHAR(LO(is_environment.keystroke))) <= 7) then
                          fm_data.WAVEFORM_modulator :=
                          hex(CHAR(LO(is_environment.keystroke)))
                        else nope := FALSE;

                     6: If (hex(CHAR(LO(is_environment.keystroke))) <= 3) then
                          fm_data.KSL_VOLUM_modulator :=
                          fm_data.KSL_VOLUM_modulator AND $0cf+
                          hex(CHAR(LO(is_environment.keystroke))) SHL 4
                        else nope := FALSE;

                     7: fm_data.KSL_VOLUM_modulator :=
                        fm_data.KSL_VOLUM_modulator AND $0f0+
                        hex(CHAR(LO(is_environment.keystroke)));

                     8: If (hex(CHAR(LO(is_environment.keystroke))) <= 3) then
                          fm_data.KSL_VOLUM_modulator :=
                          fm_data.KSL_VOLUM_modulator AND $3f+
                          hex(CHAR(LO(is_environment.keystroke))) SHL 6
                        else nope := FALSE;

                     9: fm_data.AM_VIB_EG_modulator :=
                        fm_data.AM_VIB_EG_modulator AND $0f0+
                        hex(CHAR(LO(is_environment.keystroke)));


                    14: fm_data.ATTCK_DEC_carrier :=
                        hex(CHAR(LO(is_environment.keystroke))) SHL 4+
                        fm_data.ATTCK_DEC_carrier AND $0f;
                    15: fm_data.ATTCK_DEC_carrier :=
                        fm_data.ATTCK_DEC_carrier AND $0f0+
                        hex(CHAR(LO(is_environment.keystroke)));
                    16: fm_data.SUSTN_REL_carrier :=
                        hex(CHAR(LO(is_environment.keystroke))) SHL 4+
                        fm_data.SUSTN_REL_carrier AND $0f;
                    17: fm_data.SUSTN_REL_carrier :=
                        fm_data.SUSTN_REL_carrier AND $0f0+
                        hex(CHAR(LO(is_environment.keystroke)));

                    18: If (hex(CHAR(LO(is_environment.keystroke))) <= 7) then
                          fm_data.WAVEFORM_carrier :=
                          hex(CHAR(LO(is_environment.keystroke)))
                        else nope := FALSE;

                    19: If (hex(CHAR(LO(is_environment.keystroke))) <= 3) then
                          fm_data.KSL_VOLUM_carrier :=
                          fm_data.KSL_VOLUM_carrier AND $0cf+
                          hex(CHAR(LO(is_environment.keystroke))) SHL 4
                        else nope := FALSE;

                    20: fm_data.KSL_VOLUM_carrier :=
                        fm_data.KSL_VOLUM_carrier AND $0f0+
                        hex(CHAR(LO(is_environment.keystroke)));

                    21: If (hex(CHAR(LO(is_environment.keystroke))) <= 3) then
                          fm_data.KSL_VOLUM_carrier :=
                          fm_data.KSL_VOLUM_carrier AND $3f+
                          hex(CHAR(LO(is_environment.keystroke))) SHL 6
                        else nope := FALSE;

                    22: fm_data.AM_VIB_EG_carrier :=
                        fm_data.AM_VIB_EG_carrier AND $0f0+
                        hex(CHAR(LO(is_environment.keystroke)));

                    27: If (hex(CHAR(LO(is_environment.keystroke))) <= 1) then
                          fm_data.FEEDBACK_FM :=
                          hex(CHAR(LO(is_environment.keystroke)))+
                          fm_data.FEEDBACK_FM AND $0fe
                        else nope := FALSE;

                    28: If (hex(CHAR(LO(is_environment.keystroke))) <= 7) then
                          fm_data.FEEDBACK_FM :=
                          fm_data.FEEDBACK_FM AND $0c1+
                          hex(CHAR(LO(is_environment.keystroke))) SHL 1
                        else nope := FALSE;

                    30: If (freq_slide > 0) or
                           ((freq_slide = 0) and
                            (songdata.instr_macros[instr].data[min(fmreg_page-1,1)].freq_slide >= 0)) then
                          freq_slide := freq_slide AND $0ff+
                          hex(CHAR(LO(is_environment.keystroke))) SHL 8
                        else freq_slide := -(Abs(freq_slide) AND $0ff+
                             hex(CHAR(LO(is_environment.keystroke))) SHL 8);

                    31: If (freq_slide > 0) or
                           ((freq_slide = 0) and
                            (songdata.instr_macros[instr].data[min(fmreg_page-1,1)].freq_slide >= 0)) then
                          freq_slide := freq_slide AND $0f0f+
                          hex(CHAR(LO(is_environment.keystroke))) SHL 4
                        else freq_slide := -(Abs(freq_slide) AND $0f0f+
                             hex(CHAR(LO(is_environment.keystroke))) SHL 4);

                    32: If (freq_slide > 0) or
                           ((freq_slide = 0) and
                            (songdata.instr_macros[instr].data[min(fmreg_page-1,1)].freq_slide >= 0)) then
                          freq_slide := freq_slide AND $0ff0+
                          hex(CHAR(LO(is_environment.keystroke)))
                        else freq_slide := -(Abs(freq_slide) AND $0ff0+
                             hex(CHAR(LO(is_environment.keystroke))));

                    34: duration :=
                        duration AND $0f+
                        hex(CHAR(LO(is_environment.keystroke))) SHL 4;
                    35: duration :=
                        duration AND $0f0+
                        hex(CHAR(LO(is_environment.keystroke)));
                    else
                      nope := FALSE;
                   end;

                   If nope then
                     Case fmreg_hpos of
                       6,19,30,31,
                       34:    If NOT (command_typing = 2) then
                                begin
                                  If (fmreg_page < 255) then Inc(fmreg_page)
                                  else If cycle_pattern then fmreg_page := 1;
                                end
                              else begin
                                     Inc(fmreg_hpos);
                                     _scroll_cur_right;
                                   end;
                       7,20,32,
                       35:    begin
                                If (command_typing = 2) then
                                  begin
                                    If (fmreg_hpos <> 32) then Dec(fmreg_hpos)
                                    else Dec(fmreg_hpos,2);
                                    _scroll_cur_left;
                                  end;
                                If (fmreg_page < 255) then Inc(fmreg_page)
                                else If cycle_pattern then fmreg_page := 1;
                              end;
                       else If (fmreg_page < 255) then Inc(fmreg_page)
                            else If cycle_pattern then fmreg_page := 1;
                     end;
                 end;

             If (UpCase(CHAR(LO(is_environment.keystroke))) in ['L','C','R']) and
                NOT shift_pressed then
               With songdata.instr_macros[instr].data[fmreg_page] do
                 begin
                   nope := TRUE;
                   Case fmreg_hpos of
                     33: Case UpCase(CHAR(LO(is_environment.keystroke))) of
                           'L': panning := 1;
                           'C': panning := 0;
                           'R': panning := 2;
                         end;
                     else
                       nope := FALSE;
                   end;

                   If nope then
                     If (fmreg_page < 255) then Inc(fmreg_page)
                     else If cycle_pattern then fmreg_page := 1;
                 end;

             If (UpCase(CHAR(LO(is_environment.keystroke))) in ['+','-']) and
                NOT shift_pressed and (fmreg_hpos in [29..32]) then
               With songdata.instr_macros[instr].data[fmreg_page] do
                 begin
                   Case UpCase(CHAR(LO(is_environment.keystroke))) of
                     '+': freq_slide := Abs(freq_slide);
                     '-': freq_slide := -Abs(freq_slide);
                   end;

                   If (fmreg_page < 255) then Inc(fmreg_page)
                   else If cycle_pattern then fmreg_page := 1;
                  end;

             If shift_pressed and ((is_environment.keystroke = kUP) or (is_environment.keystroke = kDOWN) or
                                   (is_environment.keystroke = kShUP) or (is_environment.keystroke = kShDOWN)) then
               begin
                 If (ptr_arpeggio_table^ <> 0) then
                   arpeggio_page := fmreg_page;
                 If (ptr_vibrato_table^ <> 0) then
                   vibrato_page := fmreg_page;
               end;
           end;

    (* Arpeggio table - pos: 8..13 *)

        8: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                                         arpeggio.length),
                                 xstart+60+window_area_inc_x,ystart+4,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_arpeggio_table^].
             arpeggio.length := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.length);
                 kNPmins: If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length > 0) then
                            Dec(songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.length);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 9
             else If (is_environment.keystroke = kUP) then pos := 13
                  else If (is_environment.keystroke = kShTAB) then
                         If NOT arp_vib_mode then pos := 7
                         else pos := 20;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length > 0) then
                             Dec(songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.length)
                           else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtLEFT: If NOT arp_vib_mode then pos := 1
                        else pos := 14;

               kCtRGHT: If arp_vib_mode then pos := 14
                        else If (ptr_vibrato_table^ <> 0) then pos := 14
                             else pos := 1;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ > 1) then
                            Dec(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ < 255) then
                            Inc(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttArpeggio_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

        9: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                                         arpeggio.speed),
                                 xstart+60+window_area_inc_x,ystart+5,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_arpeggio_table^].
             arpeggio.speed := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.speed < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.speed);
                 kNPmins: If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.speed > 0) then
                            Dec(songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.speed);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 10
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 8;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length > 0) then
                             Dec(songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.length)
                           else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtLEFT: If NOT arp_vib_mode then pos := 1
                        else pos := 15;

               kCtRGHT: If arp_vib_mode then pos := 15
                        else If (ptr_vibrato_table^ <> 0) then pos := 15
                             else pos := 1;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ > 1) then
                            Dec(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ < 255) then
                            Inc(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttArpeggio_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       10: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                                         arpeggio.loop_begin),
                                 xstart+60+window_area_inc_x,ystart+6,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_arpeggio_table^].
             arpeggio.loop_begin := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.loop_begin < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.loop_begin);
                 kNPmins: If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.loop_begin > 0) then
                            Dec(songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.loop_begin);
               end;

             While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                         arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                               arpeggio.loop_begin+
                                     min0(songdata.macro_table[ptr_arpeggio_table^].
                                          arpeggio.loop_length-1,0)) or
                        (songdata.macro_table[ptr_arpeggio_table^].
                         arpeggio.loop_begin = 0) or
                        (songdata.macro_table[ptr_arpeggio_table^].
                         arpeggio.loop_length = 0) or
                        (songdata.macro_table[ptr_arpeggio_table^].
                         arpeggio.keyoff_pos = 0)) do
               Inc(songdata.macro_table[ptr_arpeggio_table^].
                   arpeggio.keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 11
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 9;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length > 0) then
                             Dec(songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.length)
                           else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtLEFT: If NOT arp_vib_mode then pos := 2
                        else pos := 17;

               kCtRGHT: If arp_vib_mode then pos := 17
                        else If (ptr_vibrato_table^ <> 0) then pos := 17
                             else pos := 2;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ > 1) then
                            Dec(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ < 255) then
                            Inc(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttArpeggio_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       11: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                                         arpeggio.loop_length),
                                 xstart+60+window_area_inc_x,ystart+7,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_arpeggio_table^].
             arpeggio.loop_length := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.loop_length < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.loop_length);
                 kNPmins: If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.loop_length > 0) then
                            Dec(songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.loop_length);
               end;

             While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                         arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                               arpeggio.loop_begin+
                                     min0(songdata.macro_table[ptr_arpeggio_table^].
                                          arpeggio.loop_length-1,0)) or
                        (songdata.macro_table[ptr_arpeggio_table^].
                         arpeggio.loop_begin = 0) or
                        (songdata.macro_table[ptr_arpeggio_table^].
                         arpeggio.loop_length = 0) or
                        (songdata.macro_table[ptr_arpeggio_table^].
                         arpeggio.keyoff_pos = 0)) do
               Inc(songdata.macro_table[ptr_arpeggio_table^].
                   arpeggio.keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 12
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 10;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length > 0) then
                             Dec(songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.length)
                           else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtLEFT: If NOT arp_vib_mode then pos := 3
                        else pos := 18;

               kCtRGHT: If arp_vib_mode then pos := 18
                        else If (ptr_vibrato_table^ <> 0) then pos := 18
                             else pos := 3;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ > 1) then
                            Dec(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ < 255) then
                            Inc(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttArpeggio_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       12: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table^].
                                         arpeggio.keyoff_pos),
                                 xstart+60+window_area_inc_x,ystart+8,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   (Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255) and
                   (Str2num(temps,16) > songdata.macro_table[ptr_arpeggio_table^].
                                        arpeggio.loop_begin+
                                        min0(songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length-1,0)) or
                   (songdata.macro_table[ptr_arpeggio_table^].
                    arpeggio.loop_begin = 0) or
                   (songdata.macro_table[ptr_arpeggio_table^].
                    arpeggio.loop_length = 0) or
                   (Str2num(temps,16) = 0);

             songdata.macro_table[ptr_arpeggio_table^].
             arpeggio.keyoff_pos := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.loop_begin = 0) or
                             (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.loop_length = 0) or
                             (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.keyoff_pos <> 0) then
                            If (songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.keyoff_pos < 255) then
                              Inc(songdata.macro_table[ptr_arpeggio_table^].
                                  arpeggio.keyoff_pos)
                            else
                          else If (songdata.macro_table[ptr_arpeggio_table^].
                                   arpeggio.loop_begin+
                                   songdata.macro_table[ptr_arpeggio_table^].
                                   arpeggio.loop_length <= 255) then
                                 songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.keyoff_pos :=
                                   songdata.macro_table[ptr_arpeggio_table^].
                                   arpeggio.loop_begin+
                                   songdata.macro_table[ptr_arpeggio_table^].
                                   arpeggio.loop_length;

                 kNPmins: If (min0(songdata.macro_table[ptr_arpeggio_table^].
                                   arpeggio.keyoff_pos-1,0) > songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_begin+
                                min0(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length-1,0)) or
                             ((songdata.macro_table[ptr_arpeggio_table^].
                               arpeggio.keyoff_pos > 0) and
                             ((songdata.macro_table[ptr_arpeggio_table^].
                               arpeggio.loop_begin = 0) or
                              (songdata.macro_table[ptr_arpeggio_table^].
                               arpeggio.loop_length = 0))) then
                            Dec(songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.keyoff_pos);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 13
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 11;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length > 0) then
                             Dec(songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.length)
                           else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtLEFT: If NOT arp_vib_mode then pos := 4
                        else pos := 19;

               kCtRGHT: If arp_vib_mode then pos := 19
                        else If (ptr_vibrato_table^ <> 0) then pos := 19
                             else pos := 4;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ > 1) then
                            Dec(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ < 255) then
                            Inc(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttArpeggio_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       13: begin
             GotoXY(xstart+55+window_area_inc_x,ystart+16+(window_area_inc_y DIV 2));
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length > 0) then
                             Dec(songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.length)
                           else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.length)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ > 1) then
                            Dec(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_arpeggio_table^ < 255) then
                            Inc(ptr_arpeggio_table^)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table^].
                                 arpeggio.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.loop_length);

                                 While NOT ((songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table^].
                                                                  arpeggio.loop_begin+
                                                         min0(songdata.macro_table[ptr_arpeggio_table^].
                                                              arpeggio.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_begin = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.loop_length = 0) or
                                            (songdata.macro_table[ptr_arpeggio_table^].
                                             arpeggio.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_arpeggio_table^].
                                       arpeggio.keyoff_pos);

                               end;

               kCtLEFT: If NOT shift_pressed then
                          If NOT arp_vib_mode then pos := 7
                          else pos := 20
                        else If (arpeggio_page > songdata.macro_table[ptr_arpeggio_table^].arpeggio.length) then
                               arpeggio_page := min(1,songdata.macro_table[ptr_arpeggio_table^].arpeggio.length)
                             else arpeggio_page := 1;

               kCtRGHT: If NOT shift_pressed then
                          If NOT arp_vib_mode then
                            If (ptr_vibrato_table^ <> 0) then pos := 20
                            else pos := 7
                          else pos := 20
                        else If (arpeggio_page < songdata.macro_table[ptr_arpeggio_table^].arpeggio.length) then
                               arpeggio_page := min(1,songdata.macro_table[ptr_arpeggio_table^].arpeggio.length)
                             else arpeggio_page := 255;

               kUP,kShUP: If (arpeggio_page > 1) then Dec(arpeggio_page)
                          else If cycle_pattern then arpeggio_page := 255;

               kDOWN,kShDOWN: If (arpeggio_page < 255) then Inc(arpeggio_page)
                              else If cycle_pattern then arpeggio_page := 1;

               kPgUP: If (arpeggio_page > 16) then Dec(arpeggio_page,16)
                      else arpeggio_page := 1;

               kPgDOWN: If (arpeggio_page+16 < 255) then Inc(arpeggio_page,16)
                        else arpeggio_page := 255;

               kHOME: arpeggio_page := 1;

               kEND: arpeggio_page := 255;

               kENTER,kTAB: If NOT arp_vib_mode then
                              If (ptr_vibrato_table^ <> 0) then pos := 14
                              else pos := 1
                            else pos := 14;

               kShTAB: pos := 12;

               kCtrlC: begin
                         If NOT shift_pressed then clipboard.object_type := objMacroTableLine
                         else clipboard.object_type := objMacroTableColumn;
                         clipboard.mcrtab_type := mttArpeggio_table;
                         copy_object;
                       end;
               kCtrlV,
               kAltP: begin
                        paste_object;
                        If (clipboard.object_type = objMacroTableLine) and
                           (clipboard.mcrtab_type = mttArpeggio_table) then
                          If (arpeggio_page < 255) then Inc(arpeggio_page)
                          else If cycle_pattern then arpeggio_page := 1;
                      end;

               kNPplus: If shift_pressed then
                          If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.data[arpeggio_page] < $80) then
                            If (songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.data[arpeggio_page] < 96) then
                              Inc(songdata.macro_table[ptr_arpeggio_table^].
                                  arpeggio.data[arpeggio_page])
                            else
                          else If (songdata.macro_table[ptr_arpeggio_table^].
                                   arpeggio.data[arpeggio_page] < $80+96+1) then
                                 Inc(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.data[arpeggio_page]);

               kNPmins: If shift_pressed then
                          If (songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.data[arpeggio_page] < $80) then
                            If (songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.data[arpeggio_page] > 1) then
                              Dec(songdata.macro_table[ptr_arpeggio_table^].
                                  arpeggio.data[arpeggio_page])
                            else
                          else If (songdata.macro_table[ptr_arpeggio_table^].
                                   arpeggio.data[arpeggio_page] > $80+1) then
                                 Dec(songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.data[arpeggio_page]);
               kBkSPC: begin
                         songdata.macro_table[ptr_arpeggio_table^].
                         arpeggio.data[arpeggio_page] := 0;
                         If (arpeggio_page < 255) then Inc(arpeggio_page)
                         else If cycle_pattern then arpeggio_page := 1;
                       end;

               kINSERT: begin
                          For temp := 255-1 downto arpeggio_page do
                            begin
                              songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.data[SUCC(temp)] :=
                                songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.data[temp]
                            end;
                          FillChar(songdata.macro_table[ptr_arpeggio_table^].
                                   arpeggio.data[arpeggio_page],
                                   SizeOf(songdata.macro_table[ptr_arpeggio_table^].
                                          arpeggio.data[arpeggio_page]),0);
                        end;

               kDELETE: begin
                          For temp := arpeggio_page to 255-1 do
                            begin
                              songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.data[temp] :=
                                songdata.macro_table[ptr_arpeggio_table^].
                                arpeggio.data[SUCC(temp)]
                            end;
                          FillChar(songdata.macro_table[ptr_arpeggio_table^].
                                   arpeggio.data[255],
                                   SizeOf(songdata.macro_table[ptr_arpeggio_table^].
                                          arpeggio.data[255]),0);
                        end;
             end;

             If shift_pressed and ((is_environment.keystroke = kUP) or (is_environment.keystroke = kDOWN) or
                                   (is_environment.keystroke = kShUP) or (is_environment.keystroke = kShDOWN)) then
               begin
                 fmreg_page := arpeggio_page;
                 If (ptr_vibrato_table^ <> 0) then
                   vibrato_page := arpeggio_page;
               end;

             If (UpCase(CHAR(LO(is_environment.keystroke))) in ['A',UpCase(b_note),'C'..'G']) and
                NOT shift_pressed then
               begin
                 nope := FALSE;
                 is_setting.append_enabled := FALSE;
                 is_setting.character_set  := ['1'..'9','a',b_note,'c'..'g',
                                               'A',UpCase(b_note),'C'..'F','#','-'];
                 is_environment.locate_pos := 2;
                 tstr := CHAR(LO(is_environment.keystroke));

                 Repeat
                   tstr := InputStr(tstr,xstart+55+window_area_inc_x,ystart+16+(window_area_inc_y DIV 2),3,3,
                                    macro_input_bckg+macro_input,
                                    macro_def_bckg+macro_def);
                   is_setting.append_enabled := TRUE;

                   If (UpCase(tstr[1]) in ['+','0'..'9','A',UpCase(b_note),'C'..'G']) and
                     ((is_environment.keystroke = kENTER) or
                      (is_environment.keystroke = kUP) or
                      (is_environment.keystroke = kDOWN) or
                      (is_environment.keystroke = kTAB) or
                      (is_environment.keystroke = kShTAB)) then
                     begin
                       nope := FALSE;
                       If (tstr[1] = '+') then Delete(tstr,1,1);
                       If (tstr[1] in ['0'..'9']) and
                          (Str2num(tstr,10) >= 0) and (Str2num(tstr,10) <= 96) then
                         begin
                           nope := TRUE;
                           songdata.macro_table[ptr_arpeggio_table^].
                           arpeggio.data[arpeggio_page] := Str2num(tstr,10);
                           If (arpeggio_page < 255) then Inc(arpeggio_page)
                           else If cycle_pattern then arpeggio_page := 1;
                         end
                       else begin
                              If (Length(tstr) = 2) then
                                If tstr[2] in ['1'..'9'] then Insert('-',tstr,2)
                                else If tstr[2] in ['-','#'] then
                                       tstr := tstr + Num2str(current_octave,10);

                              If (Length(tstr) = 1) then
                                tstr := tstr + '-' + Num2str(current_octave,10);

                              For temp1 := 1 to 12*8+1 do
                                If (Upper(tstr) = note_layout[temp1]) then
                                  begin
                                    nope := TRUE;
                                    songdata.macro_table[ptr_arpeggio_table^].
                                    arpeggio.data[arpeggio_page] := $80+temp1;
                                    BREAK;
                                  end;

                              If NOT nope and (Length(tstr) = 2) then
                                For temp1 := 1 to 12*8+1 do
                                  If (Copy(Upper(tstr),1,2) = Copy(note_layout[temp1],1,2)) then
                                    begin
                                      nope := TRUE;
                                      songdata.macro_table[ptr_arpeggio_table^].
                                      arpeggio.data[arpeggio_page] := $80+temp1;
                                      BREAK;
                                    end;

                              If nope then
                                Case is_environment.keystroke of
                                  kUP:
                                    If (arpeggio_page > 1) then Dec(arpeggio_page)
                                    else If cycle_pattern then arpeggio_page := 255;

                                  kDOWN,
                                  kENTER:
                                    If (arpeggio_page < 255) then Inc(arpeggio_page)
                                    else If cycle_pattern then arpeggio_page := 1;
                                end;

                              If NOT nope then
                                Case songdata.macro_table[ptr_arpeggio_table^].
                                     arpeggio.data[arpeggio_page] of
                                  0: tstr := '+0';
                                  1..96: tstr := '+'+Num2str(songdata.macro_table[ptr_arpeggio_table^].
                                                             arpeggio.data[arpeggio_page],10);
                                  $80..$80+12*8+1:
                                     tstr := note_layout[songdata.macro_table[ptr_arpeggio_table^].
                                                         arpeggio.data[arpeggio_page]-$80];
                                end;
                            end;
                     end;
                 until (nope or (is_environment.keystroke = kESC)) and
                       ((is_environment.keystroke = kESC) or
                        (is_environment.keystroke = kENTER) or
                        (is_environment.keystroke = kUP) or
                        (is_environment.keystroke = kDOWN) or
                        (is_environment.keystroke = kTAB) or
                        (is_environment.keystroke = kShTAB));
                 nope := FALSE;
                 Case is_environment.keystroke of
                   kTAB: If (ptr_vibrato_table^ <> 0) then pos := 14
                         else pos := 1;
                   kShTAB: pos := 12;
                   kESC: is_environment.keystroke := kENTER;
                 end;
               end;

             If (UpCase(CHAR(LO(is_environment.keystroke))) in ['+','0'..'9']) and
                NOT shift_pressed then
               begin
                 nope := FALSE;
                 is_setting.append_enabled := FALSE;
                 is_setting.character_set  := ['+','0'..'9'];
                 is_environment.locate_pos := 2;
                 tstr := CHAR(LO(is_environment.keystroke));

                 If (CHAR(LO(is_environment.keystroke)) <> '+') then
                   begin
                     tstr := '+'+tstr;
                     Inc(is_environment.locate_pos);
                   end;

                 Repeat
                   tstr := InputStr(tstr,xstart+55+window_area_inc_x,ystart+16+(window_area_inc_y DIV 2),3,3,
                                    macro_input_bckg+macro_input,
                                    macro_def_bckg+macro_def);
                   is_setting.append_enabled := TRUE;

                   temps := tstr;
                   If ((is_environment.keystroke = kENTER) or
                       (is_environment.keystroke = kUP) or
                       (is_environment.keystroke = kDOWN) or
                       (is_environment.keystroke = kTAB) or
                       (is_environment.keystroke = kShTAB)) then
                     begin
                       nope := FALSE;
                       If (tstr[1] = '+') then Delete(tstr,1,1);

                       If (tstr[1] in ['0'..'9']) and
                          (Str2num(tstr,10) >= 0) and (Str2num(tstr,10) <= 96) then
                         begin
                           nope := TRUE;
                           songdata.macro_table[ptr_arpeggio_table^].
                           arpeggio.data[arpeggio_page] := Str2num(tstr,10);
                         end
                       else tstr := temps;

                       If nope then
                         Case is_environment.keystroke of
                           kUP:
                             If (arpeggio_page > 1) then Dec(arpeggio_page)
                             else If cycle_pattern then arpeggio_page := 255;

                           kDOWN,
                           kENTER:
                             If (arpeggio_page < 255) then Inc(arpeggio_page)
                             else If cycle_pattern then arpeggio_page := 1;
                         end;

                       If NOT nope then
                         Case songdata.macro_table[ptr_arpeggio_table^].
                              arpeggio.data[arpeggio_page] of
                           0: tstr := '+0';
                           1..96: tstr := '+'+Num2str(songdata.macro_table[ptr_arpeggio_table^].
                                                      arpeggio.data[arpeggio_page],10);
                           $80..$80+12*8+1:
                              tstr := note_layout[songdata.macro_table[ptr_arpeggio_table^].
                                                  arpeggio.data[arpeggio_page]-$80];
                         end;
                     end;
                 until (nope or (is_environment.keystroke = kESC)) and
                       ((is_environment.keystroke = kESC) or
                        (is_environment.keystroke = kENTER) or
                        (is_environment.keystroke = kUP) or
                        (is_environment.keystroke = kDOWN) or
                        (is_environment.keystroke = kTAB) or
                        (is_environment.keystroke = kShTAB));
                 nope := FALSE;
                 Case is_environment.keystroke of
                   kTAB: If NOT arp_vib_mode then
                           If (ptr_vibrato_table^ <> 0) then pos := 14
                           else pos := 1
                         else pos := 14;
                   kShTAB: pos := 12;
                   kESC: is_environment.keystroke := kENTER;
                 end;
               end;
           end;

    (* Vibrato table - pos: 14..20 *)

       14: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table^].
                                         vibrato.length),
                                 xstart+77+window_area_inc_x,ystart+4,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table^].
                      vibrato.length := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.length);
                 kNPmins: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length > 0) then
                            Dec(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.length);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 15
             else If (is_environment.keystroke = kUP) then pos := 20
                  else If (is_environment.keystroke = kShTAB) then
                         If NOT arp_vib_mode then
                           If (ptr_arpeggio_table^ <> 0) then pos := 13
                           else pos := 7
                         else pos := 13;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length > 0) then
                             Dec(songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.length)
                           else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtLEFT: If arp_vib_mode then pos := 8
                        else If (ptr_arpeggio_table^ <> 0) then pos := 8
                             else pos := 1;

               kCtRGHT: If arp_vib_mode then pos := 8
                        else pos := 1;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_vibrato_table^ > 1) then
                            Dec(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_vibrato_table^ < 255) then
                            Inc(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttVibrato_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       15: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table^].
                                         vibrato.speed),
                                 xstart+77+window_area_inc_x,ystart+5,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table^].
                      vibrato.speed := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.speed < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.speed);
                 kNPmins: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.speed > 0) then
                            Dec(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.speed);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 16
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 14;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length > 0) then
                             Dec(songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.length)
                           else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtLEFT: If arp_vib_mode then pos := 9
                        else If (ptr_arpeggio_table^ <> 0) then pos := 9
                             else pos := 1;

               kCtRGHT: If arp_vib_mode then pos := 9
                        else pos := 1;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_vibrato_table^ > 1) then
                            Dec(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_vibrato_table^ < 255) then
                            Inc(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttVibrato_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       16: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table^].
                                         vibrato.delay),
                                 xstart+77+window_area_inc_x,ystart+6,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table^].
                      vibrato.delay := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.delay < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.delay);
                 kNPmins: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.delay > 0) then
                            Dec(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.delay);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 17
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 15;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length > 0) then
                             Dec(songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.length)
                           else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtLEFT: If arp_vib_mode then pos := 8
                        else If (ptr_arpeggio_table^ <> 0) then pos := 8
                             else pos := 1;

               kCtRGHT: If arp_vib_mode then pos := 8
                        else pos := 1;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_vibrato_table^ > 1) then
                            Dec(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_vibrato_table^ < 255) then
                            Inc(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttVibrato_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       17: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table^].
                                         vibrato.loop_begin),
                                 xstart+77+window_area_inc_x,ystart+7,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table^].
                      vibrato.loop_begin := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.loop_begin < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.loop_begin);
                 kNPmins: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.loop_begin > 0) then
                            Dec(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.loop_begin);
               end;

             While NOT ((songdata.macro_table[ptr_vibrato_table^].
                         vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                              vibrato.loop_begin+
                                     min0(songdata.macro_table[ptr_vibrato_table^].
                                          vibrato.loop_length-1,0)) or
                        (songdata.macro_table[ptr_vibrato_table^].
                         vibrato.loop_begin = 0) or
                        (songdata.macro_table[ptr_vibrato_table^].
                         vibrato.loop_length = 0) or
                        (songdata.macro_table[ptr_vibrato_table^].
                         vibrato.keyoff_pos = 0)) do
               Inc(songdata.macro_table[ptr_vibrato_table^].
                   vibrato.keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 18
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 16;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length > 0) then
                             Dec(songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.length)
                           else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtLEFT: If arp_vib_mode then pos := 10
                        else If (ptr_arpeggio_table^ <> 0) then pos := 10
                             else pos := 2;

               kCtRGHT: If arp_vib_mode then pos := 10
                        else pos := 2;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_vibrato_table^ > 1) then
                            Dec(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_vibrato_table^ < 255) then
                            Inc(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttVibrato_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       18: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table^].
                                         vibrato.loop_length),
                                 xstart+77+window_area_inc_x,ystart+8,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table^].
                      vibrato.loop_length := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.loop_length < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.loop_length);
                 kNPmins: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.loop_length > 0) then
                            Dec(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.loop_length);
               end;

             While NOT ((songdata.macro_table[ptr_vibrato_table^].
                         vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                              vibrato.loop_begin+
                                     min0(songdata.macro_table[ptr_vibrato_table^].
                                          vibrato.loop_length-1,0)) or
                        (songdata.macro_table[ptr_vibrato_table^].
                         vibrato.loop_begin = 0) or
                        (songdata.macro_table[ptr_vibrato_table^].
                         vibrato.loop_length = 0) or
                        (songdata.macro_table[ptr_vibrato_table^].
                         vibrato.keyoff_pos = 0)) do
               Inc(songdata.macro_table[ptr_vibrato_table^].
                   vibrato.keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 19
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 17;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length > 0) then
                             Dec(songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.length)
                           else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtLEFT: If arp_vib_mode then pos := 11
                        else If (ptr_arpeggio_table^ <> 0) then pos := 11
                             else pos := 3;

               kCtRGHT: If arp_vib_mode then pos := 11
                        else pos := 3;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_vibrato_table^ > 1) then
                            Dec(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_vibrato_table^ < 255) then
                            Inc(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttVibrato_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       19: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table^].
                                         vibrato.keyoff_pos),
                                 xstart+77+window_area_inc_x,ystart+9,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   (Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255) and
                   (Str2num(temps,16) > songdata.macro_table[ptr_vibrato_table^].
                                        vibrato.loop_begin+
                                        min0(songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length-1,0)) or
                   (songdata.macro_table[ptr_vibrato_table^].
                    vibrato.loop_begin = 0) or
                   (songdata.macro_table[ptr_vibrato_table^].
                    vibrato.loop_length = 0) or
                   (Str2num(temps,16) = 0);

             songdata.macro_table[ptr_vibrato_table^].
                      vibrato.keyoff_pos := Str2num(temps,16);
             If shift_pressed then
               Case is_environment.keystroke of
                 kNPplus: If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.loop_begin = 0) or
                             (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.loop_length = 0) or
                             (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.keyoff_pos <> 0) then
                            If (songdata.macro_table[ptr_vibrato_table^].
                                vibrato.keyoff_pos < 255) then
                              Inc(songdata.macro_table[ptr_vibrato_table^].
                                  vibrato.keyoff_pos)
                            else
                          else If (songdata.macro_table[ptr_vibrato_table^].
                                   vibrato.loop_begin+
                                   songdata.macro_table[ptr_vibrato_table^].
                                   vibrato.loop_length <= 255) then
                                 songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.keyoff_pos :=
                                   songdata.macro_table[ptr_vibrato_table^].
                                   vibrato.loop_begin+
                                   songdata.macro_table[ptr_vibrato_table^].
                                   vibrato.loop_length;

                 kNPmins: If (min0(songdata.macro_table[ptr_vibrato_table^].
                                   vibrato.keyoff_pos-1,0) > songdata.macro_table[ptr_vibrato_table^].
                                                             vibrato.loop_begin+
                                min0(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length-1,0)) or
                             ((songdata.macro_table[ptr_vibrato_table^].
                               vibrato.keyoff_pos > 0) and
                             ((songdata.macro_table[ptr_vibrato_table^].
                               vibrato.loop_begin = 0) or
                              (songdata.macro_table[ptr_vibrato_table^].
                               vibrato.loop_length = 0))) then
                            Dec(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.keyoff_pos);
               end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 20
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 18;

             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length > 0) then
                             Dec(songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.length)
                           else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtLEFT: If arp_vib_mode then pos := 12
                        else If (ptr_arpeggio_table^ <> 0) then pos := 12
                             else pos := 4;

               kCtRGHT: If arp_vib_mode then pos := 12
                        else pos := 4;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_vibrato_table^ > 1) then
                            Dec(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_vibrato_table^ < 255) then
                            Inc(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtrlC:  begin
                          clipboard.object_type := objMacroTable;
                          clipboard.mcrtab_type := mttVibrato_table;
                          copy_object;
                        end;
               kCtrlV,
               kAltP:   paste_object;
             end;
           end;

       20: begin
             GotoXY(xstart+72+vibrato_hpos-1+window_area_inc_x,ystart+16+(window_area_inc_y DIV 2));
             is_environment.keystroke := getkey;
             Case is_environment.keystroke of
               kCtLbr:  If shift_pressed then
                          begin
                            If (songdata.macro_speedup > 1) then
                              Dec(songdata.macro_speedup);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst > 1) then
                                 begin
                                   Dec(current_inst);
                                   instrum_page := current_inst;
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtRbr:  If shift_pressed then
                          begin
                            Inc(songdata.macro_speedup);
                            If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                              songdata.macro_speedup := calc_max_speedup(tempo);
                            macro_speedup := songdata.macro_speedup;
                          end
                        else If (_4op_to_test = 0) then
                               If (current_inst < 255) then
                                 begin
                                   Inc(current_inst);
                                   instrum_page := current_inst;
                                   reset_4op_to_test(1,NULL);
                                   STATUS_LINE_refresh;
                                   GOTO _jmp2;
                                 end;

               kCtHOME:  If NOT shift_pressed then
                           If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length > 0) then
                             Dec(songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.length)
                           else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtEND:  If NOT shift_pressed then
                          If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                              vibrato.length)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_begin < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_begin);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtPgUP: If NOT shift_pressed then
                          If (ptr_vibrato_table^ > 1) then
                            Dec(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length > 0) then
                               begin
                                 Dec(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtPgDN: If NOT shift_pressed then
                          If (ptr_vibrato_table^ < 255) then
                            Inc(ptr_vibrato_table^)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table^].
                                 vibrato.loop_length < 255) then
                               begin
                                 Inc(songdata.macro_table[ptr_vibrato_table^].
                                     vibrato.loop_length);

                                 While NOT ((songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table^].
                                                                  vibrato.loop_begin+
                                                         min0(songdata.macro_table[ptr_vibrato_table^].
                                                              vibrato.loop_length-1,0)) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_begin = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.loop_length = 0) or
                                            (songdata.macro_table[ptr_vibrato_table^].
                                             vibrato.keyoff_pos = 0)) do
                                   Inc(songdata.macro_table[ptr_vibrato_table^].
                                       vibrato.keyoff_pos);

                               end;

               kCtLEFT: If NOT shift_pressed then
                          If NOT arp_vib_mode then
                            If (ptr_arpeggio_table^ <> 0) then pos := 13
                            else pos := 7
                          else pos := 13
                        else If (vibrato_page > songdata.macro_table[ptr_vibrato_table^].vibrato.length) then
                               vibrato_page := min(1,songdata.macro_table[ptr_vibrato_table^].vibrato.length)
                             else vibrato_page := 1;

               kCtRGHT: If NOT shift_pressed then
                          If NOT arp_vib_mode then pos := 7
                          else pos := 13
                        else If (vibrato_page < songdata.macro_table[ptr_vibrato_table^].vibrato.length) then
                               vibrato_page := min(1,songdata.macro_table[ptr_vibrato_table^].vibrato.length)
                             else vibrato_page := 255;

               kUP,kShUP: If (vibrato_page > 1) then Dec(vibrato_page)
                          else If cycle_pattern then vibrato_page := 255;

               kDOWN,kShDOWN: If (vibrato_page < 255) then Inc(vibrato_page)
                              else If cycle_pattern then vibrato_page := 1;

               kPgUP: If (vibrato_page > 16) then Dec(vibrato_page,16)
                      else vibrato_page := 1;

               kPgDOWN: If (vibrato_page+16 < 255) then Inc(vibrato_page,16)
                        else vibrato_page := 255;

               kHOME: vibrato_page := 1;

               kEND: vibrato_page := 255;

               kLEFT: If (vibrato_hpos > 1) then Dec(vibrato_hpos)
                      else vibrato_hpos := 3;

               kRIGHT: If (vibrato_hpos < 3) then Inc(vibrato_hpos)
                       else vibrato_hpos := 1;

               kENTER,kTAB: If NOT arp_vib_mode then pos := 1
                            else pos := 8;

               kShTAB: pos := 19;

               kCtrlC: begin
                         If NOT shift_pressed then clipboard.object_type := objMacroTableLine
                         else clipboard.object_type := objMacroTableColumn;
                         clipboard.mcrtab_type := mttVibrato_table;
                         copy_object;
                       end;
               kCtrlV,
               kAltP: begin
                        paste_object;
                        If (clipboard.object_type = objMacroTableLine) and
                           (clipboard.mcrtab_type = mttVibrato_table) then
                          If (vibrato_page < 255) then Inc(vibrato_page)
                          else If cycle_pattern then vibrato_page := 1;
                      end;

               kNPplus: If shift_pressed then
                          If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.data[vibrato_page] < 127) then
                            Inc(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.data[vibrato_page]);

               kNPmins: If shift_pressed then
                          If (songdata.macro_table[ptr_vibrato_table^].
                              vibrato.data[vibrato_page] > -127) then
                            Dec(songdata.macro_table[ptr_vibrato_table^].
                                vibrato.data[vibrato_page]);
               kBkSPC: begin
                         songdata.macro_table[ptr_vibrato_table^].
                         vibrato.data[vibrato_page] := 0;
                         If (vibrato_page < 255) then Inc(vibrato_page)
                         else If cycle_pattern then vibrato_page := 1;
                       end;

               kINSERT: begin
                          For temp := 255-1 downto vibrato_page do
                            begin
                              songdata.macro_table[ptr_vibrato_table^].
                              vibrato.data[SUCC(temp)] :=
                                songdata.macro_table[ptr_vibrato_table^].
                                vibrato.data[temp]
                            end;
                          FillChar(songdata.macro_table[ptr_vibrato_table^].
                                   vibrato.data[vibrato_page],
                                   SizeOf(songdata.macro_table[ptr_vibrato_table^].
                                          vibrato.data[vibrato_page]),0);
                        end;

               kDELETE: begin
                          For temp := vibrato_page to 255-1 do
                            begin
                              songdata.macro_table[ptr_vibrato_table^].
                              vibrato.data[temp] :=
                                songdata.macro_table[ptr_vibrato_table^].
                                vibrato.data[SUCC(temp)]
                            end;
                          FillChar(songdata.macro_table[ptr_vibrato_table^].
                                   vibrato.data[255],
                                   SizeOf(songdata.macro_table[ptr_vibrato_table^].
                                          vibrato.data[255]),0);
                        end;
             end;

             If shift_pressed and ((is_environment.keystroke = kUP) or (is_environment.keystroke = kDOWN) or
                                   (is_environment.keystroke = kShUP) or (is_environment.keystroke = kShDOWN)) then
               begin
                 fmreg_page := vibrato_page;
                 If (ptr_arpeggio_table^ <> 0) then
                   arpeggio_page := vibrato_page;
               end;

             If (UpCase(CHAR(LO(is_environment.keystroke))) in ['0'..'9','A'..'F','+','-']) and
                NOT shift_pressed then
               With songdata.macro_table[ptr_vibrato_table^].vibrato do
                 begin
                   nope := TRUE;
                   Case vibrato_hpos of
                     1: Case UpCase(CHAR(LO(is_environment.keystroke))) of
                          '+': data[vibrato_page] := Abs(data[vibrato_page]);
                          '-': data[vibrato_page] := -Abs(data[vibrato_page]);
                          else nope := FALSE;
                        end;

                     2: Case UpCase(CHAR(LO(is_environment.keystroke))) of
                          '0'..'7': If (data[vibrato_page] > 0) or
                                       ((data[vibrato_page] = 0) and
                                        (data[min(vibrato_page-1,1)] >= 0)) then
                                      data[vibrato_page] :=
                                      data[vibrato_page] AND $0f+
                                      hex(CHAR(LO(is_environment.keystroke))) SHL 4
                                    else data[vibrato_page] :=
                                         -(Abs(data[vibrato_page]) AND $0f+
                                           hex(CHAR(LO(is_environment.keystroke))) SHL 4);

                          '8'..'F': If (data[vibrato_page] > 0) or
                                       ((data[vibrato_page] = 0) and
                                        (data[min(vibrato_page-1,1)] >= 0)) then
                                      data[vibrato_page] := $7f
                                    else data[vibrato_page] := -$7f;

                          '+': data[vibrato_page] := Abs(data[vibrato_page]);
                          '-': data[vibrato_page] := -Abs(data[vibrato_page]);
                        end;

                     3: Case UpCase(CHAR(LO(is_environment.keystroke))) of
                          '0'..'9',
                          'A'..'F': If (data[vibrato_page] > 0) or
                                       ((data[vibrato_page] = 0) and
                                        (data[min(vibrato_page-1,1)] >= 0)) then
                                      data[vibrato_page] :=
                                      data[vibrato_page] AND $0f0+
                                      hex(CHAR(LO(is_environment.keystroke)))
                                    else data[vibrato_page] :=
                                         -(Abs(data[vibrato_page]) AND $0f0+
                                           hex(CHAR(LO(is_environment.keystroke))));

                          '+': data[vibrato_page] := Abs(data[vibrato_page]);
                          '-': data[vibrato_page] := -Abs(data[vibrato_page]);
                        end;

                   end;

                   If nope then
                     Case vibrato_hpos of
                       1,3: begin
                              If (command_typing = 2) and
                                 NOT (UpCase(CHAR(LO(is_environment.keystroke))) in ['-','+']) and
                                 (vibrato_hpos = 3) then Dec(vibrato_hpos);
                              If (vibrato_page < 255) then Inc(vibrato_page)
                              else If cycle_pattern then vibrato_page := 1;
                            end;
                       2:   If NOT (command_typing = 2) or
                               (UpCase(CHAR(LO(is_environment.keystroke))) in ['-','+']) then
                              begin
                                If (vibrato_page < 255) then Inc(vibrato_page)
                                else If cycle_pattern then vibrato_page := 1;
                              end
                            else Inc(vibrato_hpos);
                     end;
                 end;
           end;
      end;

      If NOT shift_pressed and (is_environment.keystroke = kSPACE) then
        begin
          refresh;
          HideCursor;
          _pip_dest := v_ofs;
          If (_4op_to_test <> 0) then _macro_preview_init(1,BYTE(NOT NULL))
          else _macro_preview_init(1,NULL);

          If ctrl_pressed and (is_environment.keystroke = kSPACE) then
            begin
              _pip_loop := TRUE;
              For temp := 1 to 20 do keyoff_loop[temp] := _pip_loop;
            end
          else For temp := 1 to 20 do keyoff_loop[temp] := _pip_loop;

          macro_preview_indic_proc := _preview_indic_proc;
          is_environment.keystroke := $0ffff;

          If NOT _force_program_quit then
          Repeat
            If keypressed then
              begin
                is_environment.keystroke := getkey;
                Case is_environment.keystroke of
                  kCtLbr:  If shift_pressed then
                             begin
                               If (songdata.macro_speedup > 1) then
                                 Dec(songdata.macro_speedup);
                               macro_speedup := songdata.macro_speedup;
                               reset_player;                               
                             end
                           else If (_4op_to_test = 0) then
                                  If (current_inst > 1) then
                                    Dec(current_inst);

                  kCtRbr:  If shift_pressed then
                             begin
                               Inc(songdata.macro_speedup);
                               If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                                 songdata.macro_speedup := calc_max_speedup(tempo);
                               macro_speedup := songdata.macro_speedup;
                               reset_player;
                             end
                           else If (_4op_to_test = 0) then
                                  If (current_inst < 255) then
                                    Inc(current_inst);
                end;

                If (is_environment.keystroke = kCtLbr) or
                   (is_environment.keystroke = kCtRbr) then
                  begin                    
                    ShowCStr(centered_frame_vdest^,xstart+window_area_inc_x+66,ystart+24+window_area_inc_y,
                             ExpStrL(' ~[SPEED:'+Num2str(tempo*songdata.macro_speedup,10)+#3+']~ ',17,'Í'),
                             macro_background+macro_border,
                             macro_background+macro_hi_text);
                    instrum_page := current_inst;
                    STATUS_LINE_refresh;
                    instr := current_inst;
                    If NOT arp_vib_mode then
                      ShowStr(centered_frame_vdest^,xstart+48,ystart,byte2hex(instr),
                              macro_background+dialog_title);
                    refresh;
                  end;

                If (_4op_to_test <> 0) then
                  _macro_preview_body(LO(_4op_to_test),HI(_4op_to_test),count_channel(pattern_hpos),is_environment.keystroke)
                else _macro_preview_body(instrum_page,NULL,count_channel(pattern_hpos),is_environment.keystroke);

                If ctrl_pressed and NOT shift_pressed and
                   (is_environment.keystroke = kSPACE) then
                  begin
                    _pip_loop := NOT _pip_loop;
                    For temp := 1 to 20 do keyoff_loop[temp] := _pip_loop;
                    is_environment.keystroke := $0ffff;
                  end;

                If shift_pressed and (is_environment.keystroke = kSPACE) then
                  is_environment.keystroke := $0ffff;
              end
            else If NOT (seconds_counter >= ssaver_time) then GOTO _end2 //CONTINUE
                 else begin
                        screen_saver;
                        GOTO _end2; //CONTINUE;
                      end;
          _end2:
            emulate_screen;
          until (is_environment.keystroke = kSPACE) or
                (is_environment.keystroke = kESC);

          If (_4op_to_test <> 0) then _macro_preview_init(0,BYTE(NOT NULL))
          else _macro_preview_init(0,NULL);
          macro_preview_indic_proc := NIL;
          _pip_dest := Addr(vscreen);
          ThinCursor;
        end;
      emulate_screen;
    until (is_environment.keystroke = kESC)    or
          (is_environment.keystroke = kAltC)   or
          (is_environment.keystroke = kCtrlO)  or
          (is_environment.keystroke = kF1)     or
          (is_environment.keystroke = kF2)     or
          (is_environment.keystroke = kCtrlF2) or
          (is_environment.keystroke = kF3)     or
          (is_environment.keystroke = kCtrlL)  or
          (is_environment.keystroke = kCtrlS)  or
          (is_environment.keystroke = kCtrlM)  or
          call_pickup_proc or
          call_pickup_proc2;

  _macro_editor__pos[arp_vib_mode] := pos;
  _macro_editor__fmreg_hpos[arp_vib_mode] := fmreg_hpos;
  _macro_editor__fmreg_page[arp_vib_mode] := fmreg_page;
  _macro_editor__fmreg_left_margin[arp_vib_mode] := fmreg_left_margin;
  _macro_editor__fmreg_cursor_pos[arp_vib_mode] := fmreg_cursor_pos;
  _macro_editor__arpeggio_page[arp_vib_mode] := arpeggio_page;
  _macro_editor__vibrato_hpos[arp_vib_mode] := vibrato_hpos;
  _macro_editor__vibrato_page[arp_vib_mode] := vibrato_page;

  If NOT arp_vib_mode then
    begin
      songdata.instr_macros[instr].arpeggio_table := ptr_arpeggio_table^;
      songdata.instr_macros[instr].vibrato_table := ptr_vibrato_table^;
    end
  else begin
         arpvib_arpeggio_table := ptr_arpeggio_table^;
         arpvib_vibrato_table := ptr_vibrato_table^;
       end;

  For temp := 1 to 255 do
    begin
      temp_marks[temp] := songdata.instr_names[temp][1];
      songdata.instr_names[temp][1] := ' ';
    end;

  If (Update32(songdata,SizeOf(songdata),0) <> songdata_crc) then
    module_archived := FALSE;

  For temp := 1 to 255 do
    songdata.instr_names[temp][1] := temp_marks[temp];

  HideCursor;
  Move(old_keys,is_setting.terminate_keys,SizeOf(old_keys));
  move_to_screen_data := Addr(backup.screen);
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+81+2+window_area_inc_x;
  move_to_screen_area[4] := ystart+24+1+window_area_inc_x;
  move2screen;
 
  Case is_environment.keystroke of
    kAltC:   begin
               If (pos in [7,13,20]) then
                 begin
                   copymnu4[13] := copymacr[2];
                   copymnu4[14] := copymacr[4];
                 end
               else begin
                      copymnu4[13] := copymacr[1];
                      copymnu4[14] := copymacr[3];
                    end;

               mn_setting.cycle_moves := TRUE;
               temp := Menu(copymnu4,01,01,copypos4,30,15,15,' COPY OBJECT ');
               copymnu4[13] := copymacr[2];
               copymnu4[14] := copymacr[4];
               If (mn_environment.keystroke <> kESC) then
                 begin
                   copypos4 := temp;
                   clipboard.object_type := tCOPY_OBJECT(temp);
                   Case pos of
                     1..7:   clipboard.mcrtab_type := mttFM_reg_table;
                     8..13:  clipboard.mcrtab_type := mttArpeggio_table;
                     14..20: clipboard.mcrtab_type := mttVibrato_table;
                   end;
                   copy_object;
                 end;
               GOTO _jmp1;
             end;

    kENTER:  If call_pickup_proc2 then
               begin
                 call_pickup_proc2 := FALSE;
                 temp := INSTRUMENT_CONTROL_alt(_source_ins2,'PASTE DATA TO REGiSTERS [iNS_'+
                                                             byte2hex(_source_ins2)+']');
                 If (temp <> 0) then
                   begin
                     _source_ins2 := temp;
                     songdata.instr_data[_source_ins2].fm_data :=
                     songdata.instr_macros[instr].data[fmreg_page].fm_data;
                     songdata.instr_data[_source_ins2].panning :=
                     songdata.instr_macros[instr].data[fmreg_page].panning;
                     songdata.instr_data[_source_ins2].fine_tune :=
                     songdata.instr_data[instr].fine_tune;
                     songdata.instr_data[_source_ins2].perc_voice :=
                     songdata.instr_data[instr].perc_voice;

                     songdata.instr_data[_source_ins2].fm_data.FEEDBACK_FM :=
                     songdata.instr_data[_source_ins2].fm_data.FEEDBACK_FM AND $3f;

                     With  songdata.instr_data[_source_ins2].fm_data do
                       begin
                         KSL_VOLUM_modulator := KSL_VOLUM_modulator AND $c0+
                                                63-KSL_VOLUM_modulator AND $3f;
                         KSL_VOLUM_carrier := KSL_VOLUM_carrier AND $c0+
                                              63-KSL_VOLUM_carrier AND $3f;
                       end;
                   end;
                 GOTO _jmp1;
               end;

    kCtENTR: If call_pickup_proc then
               begin
                 call_pickup_proc := FALSE;
                 temp := INSTRUMENT_CONTROL_alt(_source_ins,'PASTE DATA FROM REGiSTERS [iNS_'+
                                                            byte2hex(_source_ins)+']');
                 If (temp <> 0) then
                   begin
                     _source_ins := temp;
                     temp := songdata.instr_macros[instr].data[fmreg_page].
                             fm_data.FEEDBACK_FM;
                     songdata.instr_macros[instr].data[fmreg_page].fm_data :=
                       songdata.instr_data[_source_ins].fm_data;
                     songdata.instr_macros[instr].data[fmreg_page].
                     fm_data.FEEDBACK_FM := temp AND $0c0+
                       songdata.instr_data[_source_ins].fm_data.FEEDBACK_FM AND $3f;

                     songdata.instr_macros[instr].data[fmreg_page].panning :=
                       songdata.instr_data[_source_ins].panning;
                     songdata.instr_macros[instr].data[fmreg_page].duration :=
                       min(songdata.instr_macros[instr].data[fmreg_page].duration,1);

                     With songdata.instr_macros[instr].data[fmreg_page].fm_data do
                       begin
                         KSL_VOLUM_modulator := KSL_VOLUM_modulator AND $c0+
                                                63-KSL_VOLUM_modulator AND $3f;
                         KSL_VOLUM_carrier := KSL_VOLUM_carrier AND $c0+
                                              63-KSL_VOLUM_carrier AND $3f;
                       end;

                     If (fmreg_page < 255) then Inc(fmreg_page)
                     else If cycle_pattern then fmreg_page := 1;
                   end;
                 GOTO _jmp1;
               end;
    kF2,
    kCtrlS:  begin
               quick_cmd := FALSE;
               If NOT arp_vib_mode then FILE_save('a2f')
               else FILE_save('a2w');
               GOTO _jmp1;
             end;

    kCtrlF2: begin
               quick_cmd := FALSE;
               If NOT arp_vib_mode then FILE_save('a2w');
               GOTO _jmp1;
             end;
    kF3,
    kCtrlL:  begin
               If (pos < 8) then
                 temps := '*.a2i$*.a2f$*.a2b$*.a2w$'+
                          '*.bnk$*.cif$*.fib$*.fin$*.ibk$*.ins$*.sbi$*.sgi$'
               else temps := '*.a2w$';
               quick_cmd := FALSE;
               If NOT (pos < 8) then _arp_vib_loader := TRUE
               else _arp_vib_loader := FALSE;
               If _arp_vib_loader then
                 begin
                   arp_tab_selected := pos in [8..13];
                   vib_tab_selected := pos in [14..20];
                   If NOT arp_vib_mode then
                     begin
                       arpvib_arpeggio_table := ptr_arpeggio_table^;
                       arpvib_vibrato_table := ptr_vibrato_table^;
                     end;  
                 end
               else begin
                      arp_tab_selected := ptr_arpeggio_table^ <> 0;
                      vib_tab_selected := ptr_vibrato_table^ <> 0;
                      If NOT (arp_tab_selected or vib_tab_selected) then
                        begin
                          arp_tab_selected := TRUE;
                          vib_tab_selected := TRUE;
                        end;  
                    end;
               FILE_open(temps,FALSE);
               update_instr_data(instrum_page);
               GOTO _jmp1;
             end;

    kCtrlO:  begin OCTAVE_CONTROL; GOTO _jmp1; end;

    kCtrlM:  begin
               MACRO_BROWSER((pos < 8),FALSE);
               GOTO _jmp1;
             end;

    kF1:     begin
               If NOT arp_vib_mode then HELP('macro_editor')
               else HELP('macro_editor_(av)');
               GOTO _jmp1;
             end;
  end;
  _pip_loop := FALSE;
end;

procedure MACRO_BROWSER(instrBrowser: Boolean; updateCurInstr: Boolean);
begin
  songdata_crc := Update32(songdata,SizeOf(songdata),0);
  a2w_file_loader(FALSE,NOT instrBrowser,TRUE,FALSE,updateCurInstr); // browse internal A2W data
  If (Update32(songdata,SizeOf(songdata),0) <> songdata_crc) then
    module_archived := FALSE;
end;

procedure NUKE;

var
  temp1,temp2: Byte;

begin
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
          add_bank_position('?internal_instrument_data',255+3,1);
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
          _macro_editor__arpeggio_page[FALSE] := 1;
          _macro_editor__arpeggio_page[TRUE] := 1;
          _macro_editor__vibrato_hpos[FALSE] := 1;
          _macro_editor__vibrato_hpos[TRUE] := 1;
          _macro_editor__vibrato_page[FALSE] := 1;
          _macro_editor__vibrato_page[TRUE] := 1;      
        end
      else module_archived := FALSE;
    end;
end;

procedure QUIT_request;

var
  temp: Byte;

begin
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
  flag := NULL;
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

  load_flag := NULL;
  limit_exceeded := FALSE;
  HideCursor;
  
  temp := Lower(temp); { is only used for checking file extension from now on }

  If (quick_cmd) and
     NOT ((ExtOnly(temp) = 'a2i') or
          (ExtOnly(temp) = 'a2f') or
          (ExtOnly(temp) = 'a2p')) then
    EXIT;

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
               add_bank_position('?internal_instrument_data',255+3,1);
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
               _macro_editor__arpeggio_page[FALSE] := 1;
               _macro_editor__arpeggio_page[TRUE] := 1;
               _macro_editor__vibrato_hpos[FALSE] := 1;
               _macro_editor__vibrato_hpos[TRUE] := 1;
               _macro_editor__vibrato_page[FALSE] := 1;
               _macro_editor__vibrato_page[TRUE] := 1;
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
                 NOT (shift_pressed and (mpos = 1) and (load_flag <> NULL) and NOT quick_cmd and
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
    If (load_flag <> NULL) then module_archived := FALSE
    else If NOT quick_cmd then
           If (ExtOnly(temp) = 'bnk') or
              (ExtOnly(temp) = 'fib') or
              (ExtOnly(temp) = 'ibk') then GOTO _jmp1;

  If (load_flag <> NULL) then
    begin
      songdata.songname := FilterStr2(songdata.songname,_valid_characters,'_');
      songdata.composer := FilterStr2(songdata.composer,_valid_characters,'_');

      For index := 1 to 255 do
        songdata.instr_names[index] :=
          Copy(songdata.instr_names[index],1,9)+
          FilterStr2(Copy(cstr2str(songdata.instr_names[index]),10,32),_valid_characters,'_');
    end;

  If shift_pressed and
     (mpos = 1) and (load_flag <> NULL) and NOT quick_cmd and
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
  FillData(ai_table,SizeOf(ai_table),0);
  no_status_refresh := FALSE;
  FILE_open := flag;
end;

procedure show_progress(value: Longint);
begin
  If (value <> NOT 0) then
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
          If (progress_new_value MOD 5 = 0) then
            emulate_screen;
        end;
    end
  else begin
         ShowStr(v_ofs^,
                 progress_xstart,progress_ystart,
                 ExpStrL('',40,'Û'),
                 dialog_background+dialog_prog_bar1);

         If tracing then trace_update_proc
         else If (play_status = isPlaying) then
                begin
                  PATTERN_ORDER_page_refresh(pattord_page);
                  PATTERN_page_refresh(pattern_page);
                end;
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
  move_to_screen_data := Addr(backup.screen);
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
end;

begin
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
             begin CloseF(f); _a2m_saver := NULL; EXIT; end;
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
  header.crc32 := NOT 0;
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

  Move(v_ofs^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;

  HideCursor;
  If (header.patts = 0) then header.patts := 1;
  temps := 'aPLib';

  centered_frame(xstart,ystart,43,3,' '+temps+' ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;

  ShowCStr(v_ofs^,xstart+2,ystart+1,
    'COMPRESSiNG MODULE DATA [BLOCK ~01~ OF ~'+
    ExpStrL(Num2str((header.patts-1) DIV 8 +2,10),2,'0')+'~]',
    dialog_background+dialog_text,
    dialog_background+dialog_hi_text);
  show_progress(NOT 0);

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

  header.b0len := APACK_compress(songdata,buffer,SizeOf(songdata));
  For temp := 1 to 255 do
    Insert(temp_marks[temp]+
           'iNS_'+byte2hex(temp)+'÷ ',
           songdata.instr_names[temp],1);

  For temp := 0 to $7f do
    Insert(temp_marks2[temp]+
           'PAT_'+byte2hex(temp)+'  ÷ ',
           songdata.pattern_names[temp],1);

  BlockWriteF(f,buffer,header.b0len,temp);
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

  header.crc32 := Update32(buffer,header.b0len,header.crc32);
  ShowStr(v_ofs^,xstart+33,ystart+1,'02',dialog_background+dialog_hi_text);

  header.b1len[0] := APACK_compress(pattdata^[0],buffer,SizeOf(pattdata^[0]));
  BlockWriteF(f,buffer,header.b1len[0],temp);
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

  header.crc32 := Update32(buffer,header.b1len[0],header.crc32);
  For index := 1 to 15 do
    If ((header.patts-1) DIV 8 > PRED(index)) then
      begin
        ShowStr(v_ofs^,xstart+33,ystart+1,
                ExpStrL(Num2str(index+2,10),2,'0'),dialog_background+dialog_hi_text);

        header.b1len[index] := APACK_compress(pattdata^[index],buffer,SizeOf(pattdata^[index]));
        BlockWriteF(f,buffer,header.b1len[index],temp);
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
        header.crc32 := Update32(buffer,header.b1len[index],header.crc32);
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
  move_to_screen_data := Addr(backup.screen);
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
end;

begin
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
             begin CloseF(f); _a2t_saver := NULL; EXIT; end;
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
  header.crc32 := NOT 0;
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

  Move(v_ofs^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;

  HideCursor;
  If (header.patts = 0) then header.patts := 1;

  temps := 'aPLib';
  centered_frame(xstart,ystart,43,3,' '+temps+' ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);

  progress_xstart := xstart+2;
  progress_ystart := ystart+2;

  ShowCStr(v_ofs^,xstart+2,ystart+1,
    'COMPRESSiNG TiNY MODULE [BLOCK ~01~ OF ~'+
    ExpStrL(Num2str((header.patts-1) DIV 8 +6,10),2,'0')+'~]',
    dialog_background+dialog_text,
    dialog_background+dialog_hi_text);
  show_progress(NOT 0);

  count_instruments(instruments);
  instruments := min(instruments,1);
  temp2 := instruments*SizeOf(songdata.instr_data[1]);

  header.b0len := APACK_compress(songdata.instr_data,buffer,temp2);
  BlockWriteF(f,buffer,header.b0len,temp);
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

  ShowStr(v_ofs^,xstart+33,ystart+1,'02',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buffer,header.b0len,header.crc32);

  temp2 := instruments*SizeOf(songdata.instr_macros[1]);
  header.b1len := APACK_compress(songdata.instr_macros,buffer,temp2);
  BlockWriteF(f,buffer,header.b1len,temp);
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

  ShowStr(v_ofs^,xstart+33,ystart+1,'03',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buffer,header.b1len,header.crc32);

  temp2 := SizeOf(songdata.macro_table);
  header.b2len := APACK_compress(songdata.macro_table,buffer,temp2);
  BlockWriteF(f,buffer,header.b2len,temp);
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

  ShowStr(v_ofs^,xstart+33,ystart+1,'04',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buffer,header.b2len,header.crc32);

  temp2 := SizeOf(songdata.dis_fmreg_col);
  header.b3len := APACK_compress(songdata.dis_fmreg_col,buffer,temp2);
  BlockWriteF(f,buffer,header.b3len,temp);
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

  ShowStr(v_ofs^,xstart+33,ystart+1,'05',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buffer,header.b3len,header.crc32);

  temp2 := SizeOf(songdata.pattern_order);
  header.b4len := APACK_compress(songdata.pattern_order,buffer,temp2);
  BlockWriteF(f,buffer,header.b4len,temp);
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

  ShowStr(v_ofs^,xstart+33,ystart+1,'06',dialog_background+dialog_hi_text);
  header.crc32 := Update32(buffer,header.b4len,header.crc32);

  If (header.patts < 1*8) then temp2 := header.patts*SizeOf(pattdata^[0][0])
  else temp2 := SizeOf(pattdata^[0]);

  header.b5len[0] := APACK_compress(pattdata^[0],buffer,temp2);
  BlockWriteF(f,buffer,header.b5len[0],temp);
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

  header.crc32 := Update32(buffer,header.b5len[0],header.crc32);
  For index := 1 to 15 do
    If ((header.patts-1) DIV 8 > PRED(index)) then
      begin
        ShowStr(v_ofs^,xstart+33,ystart+1,
                ExpStrL(Num2str(index+6,10),2,'0'),dialog_background+dialog_hi_text);

        If (header.patts < SUCC(index)*8) then
          temp2 := (header.patts-index*8)*SizeOf(pattdata^[index][0])
        else temp2 := SizeOf(pattdata^[index]);

        header.b5len[index] := APACK_compress(pattdata^[index],buffer,temp2);
        BlockWriteF(f,buffer,header.b5len[index],temp);
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
        header.crc32 := Update32(buffer,header.b5len[index],header.crc32);
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

type
//  pBUFFER = ^tBUFFER;
  tBUFFER = array[0..PRED(65535)] of Byte;

var
  buf1,buf2: tBUFFER;

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
             begin CloseF(f); _a2i_saver := NULL; EXIT; end;
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
       buf1,
       SizeOf(songdata.instr_data[current_inst]));

  temp_str := Copy(songdata.instr_names[current_inst],10,32);
  Move(temp_str,
       buf1[SizeOf(songdata.instr_data[current_inst])],
       Length(temp_str)+1);

  temp3 := SizeOf(songdata.instr_data[current_inst])+Length(temp_str)+2;
  temp2 := APACK_compress(buf1,buf2,temp3);

  BlockWriteF(f,buf2,temp2,temp);
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
  crc := WORD(NOT 0);
  crc := Update16(header.b0len,1,crc);
  crc := Update16(buf2,header.b0len,crc);
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
             begin CloseF(f); _a2f_saver := NULL; EXIT; end;
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
       buf1,
       SizeOf(songdata.instr_data[current_inst]));
  Inc(temp3,SizeOf(songdata.instr_data[current_inst]));

  temp_str := Copy(songdata.instr_names[current_inst],10,32);
  Move(temp_str,
       buf1[temp3],
       Length(temp_str)+1);
  Inc(temp3,Length(temp_str)+1);

  temp2 := 0;
  Move(songdata.instr_macros[current_inst],buf2,
       SizeOf(songdata.instr_macros[current_inst]));
  Inc(temp2,SizeOf(songdata.instr_macros[current_inst]));

  tREGISTER_TABLE(Addr(buf2)^).arpeggio_table := 0;
  tREGISTER_TABLE(Addr(buf2)^).vibrato_table := 0;

  Move(songdata.dis_fmreg_col[current_inst],
       buf2[temp2],
       SizeOf(songdata.dis_fmreg_col[current_inst]));
  Inc(temp2,SizeOf(songdata.dis_fmreg_col[current_inst]));

  Move(buf2,buf1[temp3],temp2);
  Inc(temp3,temp2);
  temp2 := APACK_compress(buf1,buf2,temp3);

  BlockWriteF(f,buf2,temp2,temp);
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
  header.crc32 := NOT 0;
  header.crc32 := Update32(header.b0len,1,header.crc32);
  header.crc32 := Update32(buf2,header.b0len,header.crc32);
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
             begin CloseF(f); _a2p_saver := NULL; EXIT; end;
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
  header.crc32 := NOT 0;
  header.ident := id;
  header.ffver := 10;

  If (pattern2use <> NULL) then
    Move(pattdata^[pattern2use DIV 8][pattern2use MOD 8],
         buf1,
         PATTERN_SIZE)
  else
    Move(pattdata^[pattern_patt DIV 8][pattern_patt MOD 8],
         buf1,
         PATTERN_SIZE);

  If (pattern2use <> NULL) then
    temp_str := Copy(songdata.pattern_names[pattern2use],12,30)
  else temp_str := Copy(songdata.pattern_names[pattern_patt],12,30);

  FillChar(temp_str[SUCC(Length(temp_str))],30-Length(temp_str),0);
  Move(temp_str,buf1[PATTERN_SIZE],Length(temp_str)+1);

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
  header.b0len := APACK_compress(buf1,buffer,temp2);

  BlockWriteF(f,buffer,header.b0len,temp);
  If NOT (temp = header.b0len) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2P SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buffer,header.b0len,header.crc32);
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
             begin CloseF(f); _a2b_saver := NULL; EXIT; end;
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
  temp2 := APACK_compress(songdata.instr_names,buffer,temp3);

  For temp := 1 to 255 do
    Insert(temp_marks[temp]+
           'iNS_'+byte2hex(temp)+'÷ ',
           songdata.instr_names[temp],1);

  BlockWriteF(f,buffer,temp2,temp);
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
  crc := NOT 0;
  crc := Update32(header.b0len,2,crc);
  crc := Update32(buffer,header.b0len,crc);
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
             begin CloseF(f); _a2w_saver := NULL; EXIT; end;
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

  header.crc32 := NOT 0;
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
  header.b0len := APACK_compress(songdata.instr_names,buffer,temp3);

  For temp := 1 to 255 do
    Insert(temp_marks[temp]+
           'iNS_'+byte2hex(temp)+'÷ ',
           songdata.instr_names[temp],1);

  BlockWriteF(f,buffer,header.b0len,temp);
  If NOT (temp = header.b0len) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2W SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buffer,header.b0len,header.crc32);
  header.b1len := APACK_compress(songdata.macro_table,buffer,SizeOf(songdata.macro_table));

  BlockWriteF(f,buffer,header.b1len,temp);
  If NOT (temp = header.b1len) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2W SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buffer,header.b1len,header.crc32);
  header.b2len := APACK_compress(songdata.dis_fmreg_col,buffer,SizeOf(songdata.dis_fmreg_col));

  BlockWriteF(f,buffer,header.b2len,temp);
  If NOT (temp = header.b2len) then
    begin
      CloseF(f);
      EraseF(f);
      Dialog('ERROR WRiTiNG DATA - DiSK FULL?$'+
             'SAViNG STOPPED$',
             '~O~KAY$',' A2W SAVER ',1);
      EXIT;
    end;

  header.crc32 := Update32(buffer,header.b2len,header.crc32);
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
  old_songdata_source := songdata_source;
  old_instdata_source := instdata_source;

  If (songdata_source <> '') then
    songdata_source := iCASE_file(PathOnly(songdata_source))+
                             Lower_file(BaseNameOnly(songdata_source))+'.'+ext;

  If (instdata_source <> '') then
    instdata_source := iCASE_file(PathOnly(instdata_source))+
                             Lower_file(BaseNameOnly(instdata_source))+'.'+ext;
_jmp1:
  If quick_cmd then
    If ((Lower_file(ext) = 'a2m') or (Lower_file(ext) = 'a2t')) and
        (songdata_source <> '') then GOTO _jmp2;

  Repeat
    is_setting.append_enabled    := TRUE;
    is_setting.character_set     := [#$20..#$ff];
    dl_setting.center_text       := FALSE;
    dl_setting.terminate_keys[3] := kTAB;
    is_setting.terminate_keys[3] := kTAB;
    is_environment.locate_pos    := 1;
    dl_environment.context       := ' TAB Ä DiRLiST ';

    If (Lower_file(ext) = 'a2i') then
      begin
        If NOT alt_ins_name then
          begin
            If (a2i_default_path = '') then dl_environment.input_str := instdata_source
            else dl_environment.input_str := iCASE_file(a2i_default_path)+NameOnly(instdata_source);
          end
        else dl_environment.input_str := iCASE_file(a2i_default_path)+
               'instr'+ExpStrL(Num2str(current_inst,10),3,'0')+'.a2i';
      end;

    If (Lower_file(ext) = 'a2f') then
      begin
        If NOT alt_ins_name then
          begin
            If (a2f_default_path = '') then dl_environment.input_str := instdata_source
            else dl_environment.input_str := iCASE_file(a2f_default_path)+NameOnly(instdata_source);
          end
        else dl_environment.input_str := iCASE_file(a2f_default_path)+
               'instr'+ExpStrL(Num2str(current_inst,10),3,'0')+'.a2f';
      end;

    If (Lower_file(ext) = 'a2b') then
      If (a2b_default_path = '') then dl_environment.input_str := instdata_source
      else dl_environment.input_str := iCASE_file(a2b_default_path)+NameOnly(instdata_source);

    If (Lower_file(ext) = 'a2w') then
      If (a2w_default_path = '') then dl_environment.input_str := instdata_source
      else dl_environment.input_str := iCASE_file(a2w_default_path)+NameOnly(instdata_source);

    If (Lower_file(ext) = 'a2m') then
      If (a2m_default_path = '') then dl_environment.input_str := songdata_source
      else dl_environment.input_str := iCASE_file(a2m_default_path)+NameOnly(songdata_source);

    If (Lower_file(ext) = 'a2t') then
      If (a2t_default_path = '') then dl_environment.input_str := songdata_source
      else dl_environment.input_str := iCASE_file(a2t_default_path)+NameOnly(songdata_source);

    If (Lower_file(ext) = 'a2p') then
      If (a2p_default_path = '') then dl_environment.input_str := songdata_source
      else dl_environment.input_str := iCASE_file(a2p_default_path)+NameOnly(songdata_source);

    Dialog('{PATH}[FiLENAME] EXTENSiON iS SET TO "'+iCASE_file(ext)+'"$',
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
        If (Lower_file(ext) = 'a2m') then
          songdata_source := iCASE_file(PathOnly(dl_environment.input_str))+
                             Lower_file(BaseNameOnly(dl_environment.input_str))+
                             '.a2m';

        If (Lower_file(ext) = 'a2t') then
          songdata_source := iCASE_file(PathOnly(dl_environment.input_str))+
                             Lower_file(BaseNameOnly(dl_environment.input_str))+
                             '.a2t';

        If (Lower_file(ext) = 'a2p') then
          songdata_source := iCASE_file(PathOnly(dl_environment.input_str))+
                             Lower_file(BaseNameOnly(dl_environment.input_str))+
                             '.a2p';

        If (Lower_file(ext) = 'a2i') then
          instdata_source := iCASE_file(PathOnly(dl_environment.input_str))+
                             Lower_file(BaseNameOnly(dl_environment.input_str))+
                             '.a2i';

        If (Lower_file(ext) = 'a2f') then
          instdata_source := iCASE_file(PathOnly(dl_environment.input_str))+
                             Lower_file(BaseNameOnly(dl_environment.input_str))+
                             '.a2f';

        If (Lower_file(ext) = 'a2b') then
          instdata_source := iCASE_file(PathOnly(dl_environment.input_str))+
                             Lower_file(BaseNameOnly(dl_environment.input_str))+
                             '.a2b';

        If (Lower_file(ext) = 'a2w') then
          instdata_source := iCASE_file(PathOnly(dl_environment.input_str))+
                             Lower_file(BaseNameOnly(dl_environment.input_str))+
                             '.a2w';
      end;

    quit_flag := TRUE;
    If (dl_environment.keystroke = kTAB) then
      begin
        If (Lower_file(ext) <> 'a2i') and (Lower_file(ext) <> 'a2f') and
           (Lower_file(ext) <> 'a2b') and (Lower_file(ext) <> 'a2w') then mpos := 3
        else mpos := 4;

        fs_environment.last_file := last_file[mpos];
        fs_environment.last_dir  := last_dir[mpos];

        temp_str := Fselect('*.'+ext+'$');

        last_file[mpos] := fs_environment.last_file;
        last_dir[mpos]  := fs_environment.last_dir;

        If (mn_environment.keystroke = kESC) then quit_flag := FALSE
        else begin
               If (Lower_file(ext) = 'a2m') then
                 songdata_source := iCASE_file(PathOnly(temp_str))+
                                    Lower_file(BaseNameOnly(temp_str))+'.a2m';

               If (Lower_file(ext) = 'a2t') then
                 songdata_source := iCASE_file(PathOnly(temp_str))+
                                    Lower_file(BaseNameOnly(temp_str))+'.a2t';

               If (Lower_file(ext) = 'a2p') then
                 songdata_source := iCASE_file(PathOnly(temp_str))+
                                    Lower_file(BaseNameOnly(temp_str))+'.a2p';

               If (Lower_file(ext) = 'a2i') then
                 instdata_source := iCASE_file(PathOnly(temp_str))+
                                    Lower_file(BaseNameOnly(temp_str))+'.a2i';

               If (Lower_file(ext) = 'a2f') then
                 instdata_source := iCASE_file(PathOnly(temp_str))+
                                    Lower_file(BaseNameOnly(temp_str))+'.a2f';

               If (Lower_file(ext) = 'a2b') then
                 instdata_source := iCASE_file(PathOnly(temp_str))+
                                    Lower_file(BaseNameOnly(temp_str))+'.a2b';

               If (Lower_file(ext) = 'a2w') then
                 instdata_source := iCASE_file(PathOnly(temp_str))+
                                    Lower_file(BaseNameOnly(temp_str))+'.a2w';
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
 If (Lower_file(ext) = 'a2i') or (Lower_file(ext) = 'a2f') or
    (Lower_file(ext) = 'a2b') or (Lower_file(ext) = 'a2w') then
    temp_str := instdata_source;
  If (Lower_file(ext) = 'a2m') or (Lower_file(ext) = 'a2t') or (Lower_file(ext) = 'a2p') then
    temp_str := songdata_source;

  If (Lower_file(ext) = 'a2m') then temp := _a2m_saver;
  If (Lower_file(ext) = 'a2t') then temp := _a2t_saver;
  If (Lower_file(ext) = 'a2i') then temp := _a2i_saver;
  If (Lower_file(ext) = 'a2f') then temp := _a2f_saver;
  If (Lower_file(ext) = 'a2p') then temp := _a2p_saver;
  If (Lower_file(ext) = 'a2b') then temp := _a2b_saver;
  If (Lower_file(ext) = 'a2w') then temp := _a2w_saver;

  If (temp = NULL) then GOTO _jmp1;
end;

end.
