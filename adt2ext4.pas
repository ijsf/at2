unit AdT2ext4;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

const
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
  arpvib_arpeggio_table: Byte = 1;
  arpvib_vibrato_table:  Byte = 1;

procedure MACRO_EDITOR(instr: Byte; arp_vib_mode: Boolean);
procedure MACRO_BROWSER(instrBrowser: Boolean; updateCurInstr: Boolean);

implementation

uses
{$IFDEF GO32V2}
  CRT,
{$ELSE}
  DOS,
{$ENDIF}
  AdT2opl3,AdT2sys,AdT2keyb,AdT2unit,AdT2extn,AdT2ext2,AdT2ext3,AdT2ext5,AdT2text,AdT2pack,
  StringIO,DialogIO,ParserIO,TxtScrIO,DepackIO;

const
  _pip_xloc: Byte = 1;
  _pip_yloc: Byte = 1;
  _pip_dest: tSCREEN_MEM_PTR = NIL;
  _pip_loop: Boolean = FALSE;
  _operator_enabled: array[1..4] of Boolean = (TRUE,TRUE,TRUE,TRUE);

procedure _preview_indic_proc(state: Byte);
begin
  Case state of
    0: ShowStr(_pip_dest,_pip_xloc,_pip_yloc,
               #16' PREViEW '#17,
               macro_background+macro_text_dis);
    1: ShowStr(_pip_dest,_pip_xloc,_pip_yloc,
               #16' PREViEW '#17,
               macro_background+macro_text);
    2: ShowStr(_pip_dest,_pip_xloc,_pip_yloc,
               #16' PREViEW '#17,
               NOT (macro_background+macro_text));
  end;

  If _pip_loop and (state <> 0) then
    ShowStr(_pip_dest,_pip_xloc,_pip_yloc-1,
            #12' LOOP',
            macro_background+macro_text)
  else ShowStr(_pip_dest,_pip_xloc,_pip_yloc-1,
               #12' LOOP',
               macro_background+macro_text_dis);
end;

var
  _m_temp,_m_temp2,_m_temp3,_m_temp5: Byte;
  _m_valid_key,_m_temp4: Boolean;
  _m_chan_handle: array[1..18] of Byte;
  _m_channels: Byte;
  _m_flag_4op: Byte;
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
  _bak_current_inst: Byte;
  _4op_mode: Boolean;

function _1op_preview_active: Boolean;

var
  temp,nm_slots: Byte;

begin
  nm_slots := 0;
  For temp := 1 to 4 do
    If _operator_enabled[temp] then
      Inc(nm_slots);
  _1op_preview_active := (nm_slots = 1);
end;

procedure _macro_preview_init(state,instr2: Byte);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:_macro_preview_init';
{$ENDIF}
  _4op_mode := (songdata.flag_4op <> 0) and (instr2 <> BYTE_NULL);

  Case state of
    0: begin
         Move(_m_fmpar_table_backup,fmpar_table,SizeOf(fmpar_table));
         Move(_m_volume_table_backup,volume_table,SizeOf(volume_table));
         Move(_m_panning_table_backup,panning_table,SizeOf(panning_table));
         songdata.instr_macros[_bak_current_inst].arpeggio_table := _bak_arpeggio_table;
         songdata.instr_macros[_bak_current_inst].vibrato_table := _bak_vibrato_table;
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
         _m_flag_4op := songdata.flag_4op;
         If NOT percussion_mode and
            NOT (songdata.flag_4op <> 0) then _m_channels := 18
         else If NOT (songdata.flag_4op <> 0) then _m_channels := 15
              else begin
                     If _4op_mode and NOT _1op_preview_active then
                       begin
                         _m_flag_4op := $3f;
                         _m_channels := 6;
                       end
                     else begin
                            _m_flag_4op := 0;
                            If NOT percussion_mode then _m_channels := 18
                            else _m_channels := 15;
                          end;
                   end;

         _bak_arpeggio_table := songdata.instr_macros[current_inst].arpeggio_table;
         _bak_vibrato_table := songdata.instr_macros[current_inst].vibrato_table;
         _bak_common_flag := songdata.common_flag;
         _bak_volume_scaling := volume_scaling;
         _bak_current_inst := current_inst;
         songdata.instr_macros[current_inst].arpeggio_table := ptr_arpeggio_table;
         songdata.instr_macros[current_inst].vibrato_table := ptr_vibrato_table;
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

         opl2out($01,$20);
         opl2out($08,$40);
         opl3exp($0105);
         opl3exp($04+_m_flag_4op SHL 8);

         key_off(17);
         key_off(18);
         opl2out(_instr[11],misc_register);

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
  ins: tADTRACK2_INS;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:_macro_preview_body:output_note';
{$ENDIF}

  note := board_pos+12*(current_octave-1);
  If NOT (note in [0..12*8+1]) then
    begin
      output_note := FALSE;
      EXIT;
    end;

  _m_chan_handle[chan] := board_scancodes[board_pos];
  If _4op_mode then
    chan := _4op_main_chan[chan];

  If _1op_preview_active then
    begin
      If _operator_enabled[1] or _operator_enabled[2] then
        ins := songdata.instr_data[instr]
      else ins := songdata.instr_data[instr2];
      pBYTE(@ins)[10] := pBYTE(@ins)[10] OR 1;
      load_instrument(ins,chan);
      If _operator_enabled[1] or _operator_enabled[2] then
        set_ins_volume($3f-ORD(_operator_enabled[1])*($3f-LO(volume_table[chan])),
                       $3f-ORD(_operator_enabled[2])*($3f-HI(volume_table[chan])),
                       chan)
      else set_ins_volume($3f-ORD(_operator_enabled[3])*($3f-LO(volume_table[chan])),
                          $3f-ORD(_operator_enabled[4])*($3f-HI(volume_table[chan])),
                          chan);
    end
  else
    begin
      load_instrument(songdata.instr_data[instr],chan);
      set_ins_volume($3f-ORD(_operator_enabled[1])*($3f-LO(volume_table[chan])),
                     $3f-ORD(_operator_enabled[2])*($3f-HI(volume_table[chan])),
                     chan);
      If percussion_mode and
         (songdata.instr_data[instr].perc_voice in [4,5]) then
        load_instrument(songdata.instr_data[instr],_perc_sim_chan[chan]);
      If _4op_mode then
        begin
          load_instrument(songdata.instr_data[instr2],PRED(chan));
          set_ins_volume($3f-ORD(_operator_enabled[3])*($3f-LO(volume_table[PRED(chan)])),
                         $3f-ORD(_operator_enabled[4])*($3f-HI(volume_table[PRED(chan)])),
                         PRED(chan));
        end;
    end;

  freq := nFreq(note-1)+$2000+
          SHORTINT(pBYTE(@Addr(songdata.instr_data[instr])^)[12]);
  event_table[chan].note := note;
  freq_table[chan] := freq;
  freqtable2[chan] := freq;
  key_on(chan);
  change_freq(chan,freq);

  If NOT (_1op_preview_active and (_operator_enabled[3] or _operator_enabled[4])) then
    init_macro_table(chan,note,instr,freq)
  else init_macro_table(chan,note,instr2,freq);

  If _4op_mode and NOT _1op_preview_active then
    init_macro_table(PRED(chan),note,instr2,freq);
end;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:_macro_preview_body';
{$ENDIF}
  If ctrl_pressed or alt_pressed or shift_pressed then EXIT;
  _m_valid_key := FALSE;
  For _m_temp := 1 to 29 do
    If NOT shift_pressed then
      If (board_scancodes[_m_temp] = HI(fkey)) then
        begin _m_valid_key := TRUE; BREAK; end;

  If NOT _m_valid_key or
     NOT (_m_temp+12*(current_octave-1)-1 in [0..12*8+1]) then EXIT;

  _m_temp2 := _m_temp;
  If percussion_mode and
     (songdata.instr_data[instr].perc_voice in [1..5]) then
    begin
      output_note(songdata.instr_data[instr].perc_voice+15,_m_temp2);
      While scankey(board_scancodes[_m_temp2]) do
        begin
{$IFDEF GO32V2}
          realtime_gfx_poll_proc;
{$ELSE}
          _draw_screen_without_delay := TRUE;
          keyboard_poll_input;
{$ENDIF}
          keyboard_reset_buffer;
          draw_screen;
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

            If NOT _4op_mode then
              begin
                _m_temp3 := get_chanpos(_m_chan_handle,_m_channels,_m_temp2);
                _m_temp5 := get_chanpos(_m_chan_handle,_m_channels,0)
              end
            else begin
                   _m_temp3 := get_chanpos2(_m_chan_handle,_m_channels,_m_temp2);
                   _m_temp5 := get_chanpos2(_m_chan_handle,_m_channels,0)
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
{$IFDEF GO32V2}
        realtime_gfx_poll_proc;
{$ELSE}
        _draw_screen_without_delay := TRUE;
        keyboard_poll_input;
{$ENDIF}
        keyboard_reset_buffer;
        draw_screen;
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
  _panning: array[0..2] of Char = #241'<>';
  _hex: array[0..15] of Char = '0123456789ABCDEF';

const
  new_keys: array[1..38] of Word = (kF1,kESC,kENTER,kSPACE,kTAB,kShTAB,kUP,kDOWN,
                                    kCtrlO,kF2,kCtrlF2,kF3,kCtrlL,kCtrlS,kCtrlM,
                                    kCtENTR,kAltC,kAltP,kCtrlC,kCtrlV,
                                    kCtPgUP,kCtPgDN,kSPACE,
                                    kCHplus,kNPplus,kCHmins,kNPmins,
                                    kCtLbr,kCtRbr,kAlt0,kAlt1,kAlt2,kAlt3,kAlt4,
                                    kCtHOME,kCtEND,kCtLEFT,kCtRGHT);
var
  old_keys: array[1..38] of Word;
  temps,tstr: String;
  xstart,ystart,temp,temp1: Byte;
  fmreg_cursor_pos,
  fmreg_left_margin: Byte;
  fmreg_hpos: Byte;
  pos,vibrato_hpos: Byte;
  old_instr,old_pos,old_arp_ptr,old_vib_ptr: Byte;
  old_fmreg_page,old_arpeggio_page,
  old_vibrato_page: Byte;
  refresh_flag: Byte;
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:fmreg_def_attr';
{$ENDIF}

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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:_fmreg_str';
{$ENDIF}

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

      If (AM_VIB_EG_modulator SHR 7 = 0) then fmreg_str := fmreg_str+#250
      else fmreg_str := fmreg_str+'T';

      If (AM_VIB_EG_modulator SHR 6 AND 1 = 0) then fmreg_str := fmreg_str+#250
      else fmreg_str := fmreg_str+'V';

      If (AM_VIB_EG_modulator SHR 4 AND 1 = 0) then fmreg_str := fmreg_str+#250
      else fmreg_str := fmreg_str+'K';

      If (AM_VIB_EG_modulator SHR 5 AND 1 = 0) then fmreg_str := fmreg_str+#250' '
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

      If (AM_VIB_EG_carrier SHR 7 = 0) then fmreg_str := fmreg_str+#250
      else fmreg_str := fmreg_str+'T';

      If (AM_VIB_EG_carrier SHR 6 AND 1 = 0) then fmreg_str := fmreg_str+#250
      else fmreg_str := fmreg_str+'V';

      If (AM_VIB_EG_carrier SHR 4 AND 1 = 0) then fmreg_str := fmreg_str+#250
      else fmreg_str := fmreg_str+'K';

      If (AM_VIB_EG_carrier SHR 5 AND 1 = 0) then fmreg_str := fmreg_str+#250' '
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:_dis_fmreg_col';
{$ENDIF}

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
  _on_off: array[BOOLEAN] of Char = (#205,#254);

var
  temp: Byte;
  temp_str: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:_str1';
{$ENDIF}

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

procedure fmreg_page_refresh(xpos,ypos: Byte; page: Word);

var
  attr,attr2: Byte;
  temps,fmreg_str2: String;
  fmreg_col,index,
  index2: Byte;
  dummy_str: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:fmreg_page_refresh';
{$ENDIF}

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
  dummy_str :=  macro_retrig_str[songdata.instr_macros[instr].data[page AND $0ff].fm_data.
                                 FEEDBACK_FM SHR 5];
  If NOT arp_vib_mode then
    begin
      If (page <> EMPTY_FIELD) then
        If (page OR COMMON_FLAG <> page) then
          ShowC3Str(ptr_temp_screen,xpos,ypos,
                    '~'+byte2hex(page)+'~ '#179'~'+dummy_str+'~'#246'~'+
                    _str2(temps,31+window_area_inc_x)+'~',
                    macro_background+macro_text,
                    attr,
                    macro_background+macro_text_dis)
        else
          ShowC3Str(ptr_temp_screen,xpos-1,ypos,
                    ' ~'+byte2hex(page AND NOT COMMON_FLAG)+'~ '#179'~'+dummy_str+'~'#246'~'+
                    _str2(temps,31+window_area_inc_x)+'~ ',
                    macro_current_bckg+macro_current,
                    attr2,
                    macro_current_bckg+macro_current_dis)
      else
        ShowStr(ptr_temp_screen,xpos,ypos,ExpStrL('',36,' '),attr);
    end
  else
    begin
      If (page <> EMPTY_FIELD) then
        If (page OR COMMON_FLAG <> page) then
          ShowC3Str(ptr_temp_screen,xpos,ypos,
                    byte2hex(page)+' '#179'~'+dummy_str+'~'#246'~'+
                    _str2(temps,31+window_area_inc_x)+'~',
                    macro_background+macro_text_dis,
                    macro_background+macro_text_dis,
                    macro_background+macro_text_dis)
        else
          ShowC3Str(ptr_temp_screen,xpos-1,ypos,
                    ' '+
                    byte2hex(page AND NOT COMMON_FLAG)+' '#179'~'+dummy_str+'~'#246'~'+
                    _str2(temps,31+window_area_inc_x)+'~ ',
                    macro_background+macro_text_dis,
                    macro_background+macro_text_dis,
                    macro_background+macro_text_dis)
      else
        ShowStr(ptr_temp_screen,xpos,ypos,ExpStrL('',36,' '),
                macro_background+macro_text_dis);
    end;
end;

function arpeggio_def_attr(page: Byte): Word;

var
  attr,
  attr2: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:arpeggio_def_attr';
{$ENDIF}

  If (page <= songdata.macro_table[ptr_arpeggio_table].
              arpeggio.length) then
    If (page >= songdata.macro_table[ptr_arpeggio_table].
                arpeggio.loop_begin) and
       (page <= songdata.macro_table[ptr_arpeggio_table].
                arpeggio.loop_begin+
                PRED(songdata.macro_table[ptr_arpeggio_table].
                     arpeggio.loop_length)) and
       (songdata.macro_table[ptr_arpeggio_table].
        arpeggio.loop_begin > 0) and
       (songdata.macro_table[ptr_arpeggio_table].
        arpeggio.loop_length > 0) then
      begin
        attr := macro_background+macro_text_loop;
        attr2 := macro_current_bckg+macro_current_loop;
      end
    else If (page >= songdata.macro_table[ptr_arpeggio_table].
                     arpeggio.keyoff_pos) and
            (songdata.macro_table[ptr_arpeggio_table].
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:arpeggio_page_refresh';
{$ENDIF}

  attr  := LO(arpeggio_def_attr(page AND $0fff));
  attr2 := HI(arpeggio_def_attr(page AND $0fff));

  Case songdata.macro_table[ptr_arpeggio_table].
       arpeggio.data[page AND $0fff] of
    0: temps := #250#250#250;
    1..96: temps := '+'+ExpStrR(Num2str(songdata.macro_table[ptr_arpeggio_table].
                                        arpeggio.data[page AND $0fff],10),2,' ');
    $80..$80+12*8+1:
       temps := note_layout[songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.data[page AND $0fff]-$80];
  end;

  If (page <> EMPTY_FIELD) then
    If (page OR COMMON_FLAG <> page) then
      ShowCStr(ptr_temp_screen,xpos,ypos,
               '~'+byte2hex(page AND NOT COMMON_FLAG)+'~ '#179' ~'+
               temps+'~',
               macro_background+macro_text,attr)
    else
      ShowCStr(ptr_temp_screen,xpos-1,ypos,
               ' ~'+byte2hex(page AND NOT COMMON_FLAG)+'~ '#179' ~'+
               temps+'~ ',
               macro_current_bckg+macro_current,attr2)
  else
    ShowStr(ptr_temp_screen,xpos,ypos,ExpStrL('',9,' '),attr);
end;

function vibrato_def_attr(page: Byte): Word;

var
  attr,
  attr2: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:vibrato_def_attr';
{$ENDIF}

  If (page <= songdata.macro_table[ptr_vibrato_table].
              vibrato.length) then
    If (page >= songdata.macro_table[ptr_vibrato_table].
                vibrato.loop_begin) and
       (page <= songdata.macro_table[ptr_vibrato_table].
                vibrato.loop_begin+
                PRED(songdata.macro_table[ptr_vibrato_table].
                     vibrato.loop_length)) and
       (songdata.macro_table[ptr_vibrato_table].
        vibrato.loop_begin > 0) and
       (songdata.macro_table[ptr_vibrato_table].
        vibrato.loop_length > 0) then
      begin
        attr := macro_background+macro_text_loop;
        attr2 := macro_current_bckg+macro_current_loop;
      end
    else If (page >= songdata.macro_table[ptr_vibrato_table].
                     vibrato.keyoff_pos) and
            (songdata.macro_table[ptr_vibrato_table].
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:vibrato_page_refresh';
{$ENDIF}

  attr  := LO(vibrato_def_attr(page AND $0fff));
  attr2 := HI(vibrato_def_attr(page AND $0fff));

  If (songdata.macro_table[ptr_vibrato_table].
      vibrato.data[page AND $0fff] = 0) then temps := #250#250#250
  else If (songdata.macro_table[ptr_vibrato_table].
           vibrato.data[page AND $0fff] < 0) then
         temps := '-'+byte2hex(Abs(songdata.macro_table[ptr_vibrato_table].
                                   vibrato.data[page AND $0fff]))
       else
         temps := '+'+byte2hex(Abs(songdata.macro_table[ptr_vibrato_table].
                                   vibrato.data[page AND $0fff]));

  If (page <> EMPTY_FIELD) then
    If (page OR COMMON_FLAG <> page) then
      ShowCStr(ptr_temp_screen,xpos,ypos,
               '~'+byte2hex(page AND NOT COMMON_FLAG)+'~ '#179' ~'+
               temps+'~',
               macro_background+macro_text,attr)
    else
      ShowCStr(ptr_temp_screen,xpos-1,ypos,
               ' ~'+byte2hex(page AND NOT COMMON_FLAG)+'~ '#179' ~'+
               temps+'~ ',
               macro_current_bckg+macro_current,attr2)
  else
    ShowStr(ptr_temp_screen,xpos,ypos,ExpStrL('',9,' '),attr);
end;

procedure arpeggio_page_refresh_alt(xpos,ypos: Byte; page: Word);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:arpeggio_page_refresh_alt';
{$ENDIF}

  If (page <> EMPTY_FIELD) then
    If (page OR COMMON_FLAG <> page) then
      ShowCStr(ptr_temp_screen,xpos,ypos,
               byte2hex(page AND NOT COMMON_FLAG)+' '#179' ~'+
               #250#250#250'~',
               macro_background+macro_text_dis,
               macro_background+macro_text_dis)
    else
      ShowCStr(ptr_temp_screen,xpos-1,ypos,
               ' '+
               byte2hex(page AND NOT COMMON_FLAG)+' '#179' ~'+
               #250#250#250'~ ',
               macro_background+macro_text_dis,
               macro_background+macro_text_dis)
  else
    ShowStr(ptr_temp_screen,xpos,ypos,
            ExpStrL('',9,' '),
            macro_background+macro_text_dis);
end;

procedure vibrato_page_refresh_alt(xpos,ypos: Byte; page: Word);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:vibrato_page_refresh_alt';
{$ENDIF}

  temps := #250#250#250;
  If (page <> EMPTY_FIELD) then
    If (page OR COMMON_FLAG <> page) then
      ShowCStr(ptr_temp_screen,xpos,ypos,
               byte2hex(page AND NOT COMMON_FLAG)+' '#179' ~'+
               #250#250#250'~',
               macro_background+macro_text_dis,
               macro_background+macro_text_dis)
    else
      ShowCStr(ptr_temp_screen,xpos-1,ypos,
               ' '+
               byte2hex(page AND NOT COMMON_FLAG)+' '#179' ~'+
               #250#250#250'~ ',
               macro_background+macro_text_dis,
               macro_background+macro_text_dis)
  else
    ShowStr(ptr_temp_screen,xpos,ypos,
            ExpStrL('',9,' '),
            macro_background+macro_text_dis);
end;

function _gfx_bar_str(value: Byte; neg: Boolean): String;

var
  result: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:_gfx_bar_str';
{$ENDIF}
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:_fmreg_param';
{$ENDIF}
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
    25,26: If (fmreg_str[pos5[fmreg_hpos]] = #251) then result := 1
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

const
  flag_FMREG    = 1;
  flag_ARPEGGiO = 2;
  flag_VIBRATO  = 4;

procedure refresh(refresh_flag: Byte);

var
  nm_slots: Byte;
  temp,max_value: Integer;
  d_factor: Real;
  temp_str: String;
  _add_prev_size,
  _sub_prev_xpos_a,
  _sub_prev_xpos_v: Integer;
  _axis_attr: Byte;
  _4op_pos_shift,
  _4op_ins1,_4op_ins2: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:refresh';
{$ENDIF}
  For temp := 1 to 20 do
    If (pos = temp) then attr[temp] := macro_background+macro_hi_text
    else If (temp in [1..7]) and arp_vib_mode then
           attr[temp] := macro_background+macro_text_dis
         else If (temp in [8..13]) and
                 (ptr_arpeggio_table = 0) then
               attr[temp] := macro_background+macro_text_dis
              else If (temp in [14..20]) and
                      (ptr_vibrato_table = 0) then
                     attr[temp] := macro_background+macro_text_dis
                   else attr[temp] := macro_background+macro_text;

  If (ptr_arpeggio_table <> 0) then
    begin
      attr2[1] := macro_input_bckg+macro_input;
      attr2[3] := macro_background+macro_topic;
    end
  else begin
         attr2[1] := macro_background+macro_text_dis;
         attr2[3] := macro_background+macro_text_dis;
       end;

  If (ptr_vibrato_table <> 0) then
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

  If (pos = 7) then frame_type[1] := frame_double
  else frame_type[1] := frame_single;

  If (pos = 13) then frame_type[2] := frame_double
  else frame_type[2] := frame_single;

  If (pos = 20) then frame_type[3] := frame_double
  else frame_type[3] := frame_single;

  If NOT arp_vib_mode then
    begin
      ShowStr(ptr_temp_screen,xstart+2,ystart+1,'FM-REGiSTER',
              macro_background+macro_topic);
      ShowStr(ptr_temp_screen,xstart+2,ystart+2,'DEFiNiTiON MACRO-TABLE',
              macro_background+macro_topic);
    end
  else begin
         ShowStr(ptr_temp_screen,xstart+2,ystart+1,'FM-REGiSTER',
                 macro_background+macro_text_dis);
         ShowStr(ptr_temp_screen,xstart+2,ystart+2,'DEFiNiTiON MACRO-TABLE',
                 macro_background+macro_text_dis);
       end;

  ShowStr(ptr_temp_screen,xstart+2,ystart+3,
          ExpStrL('',78+window_area_inc_x,#205),
          macro_background+macro_text);

  ShowStr(ptr_temp_screen,xstart+2,ystart+10,
          ExpStrL('',78+window_area_inc_x,#205),
          macro_background+macro_text);

  ShowStr(ptr_temp_screen,xstart+2,ystart+22+window_area_inc_y,
          ExpStrL('',78+window_area_inc_x,#205),
          macro_background+macro_text);

  If NOT arp_vib_mode then
    begin
      ShowCStr(ptr_temp_screen,xstart+2,ystart+4,
               'LENGTH         ~'+
               byte2hex(songdata.instr_macros[instr].length)+' ~',
               attr[1],attr2[5]);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+5,
               'LOOP BEGiN     ~'+
               byte2hex(songdata.instr_macros[instr].loop_begin)+' ~',
               attr[2],attr2[5]);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+6,
               'LOOP LENGTH    ~'+
               byte2hex(songdata.instr_macros[instr].loop_length)+' ~',
               attr[3],attr2[5]);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+7,
               'KEY-OFF        ~'+
               byte2hex(songdata.instr_macros[instr].keyoff_pos)+' ~',
               attr[4],attr2[5]);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+8,
               'ARPEGGiO TABLE ~'+
               byte2hex(ptr_arpeggio_table)+' ~',
               attr[5],attr2[5]);

      ShowCStr(ptr_temp_screen,xstart+2,ystart+9,
               'ViBRATO TABLE  ~'+
               byte2hex(ptr_vibrato_table)+' ~',
               attr[6],attr2[5]);

      _add_prev_size := window_area_inc_x DIV 2;
      _sub_prev_xpos_a := 0;
      _sub_prev_xpos_v := 0;
    end
  else begin
         _add_prev_size := 0;
         _sub_prev_xpos_a := 20;
         _sub_prev_xpos_v := -3;
       end;

  ShowStr(ptr_temp_screen,xstart+48+window_area_inc_x,ystart+2,'ARPEGGiO ('+
          byte2hex(ptr_arpeggio_table)+')',
          attr2[3]);

  ShowCStr(ptr_temp_screen,xstart+48+window_area_inc_x,ystart+4,
           'LENGTH      ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.length)+' ~',
           attr[8],attr2[1]);

  ShowCStr(ptr_temp_screen,xstart+48+window_area_inc_x,ystart+5,
           'SPEED       ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.speed)+' ~',
           attr[9],attr2[1]);

  ShowCStr(ptr_temp_screen,xstart+48+window_area_inc_x,ystart+6,
           'LOOP BEGiN  ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.loop_begin)+' ~',
           attr[10],attr2[1]);

  ShowCStr(ptr_temp_screen,xstart+48+window_area_inc_x,ystart+7,
           'LOOP LENGTH ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.loop_length)+' ~',
           attr[11],attr2[1]);

  ShowCStr(ptr_temp_screen,xstart+48+window_area_inc_x,ystart+8,
           'KEY-OFF     ~'+
           byte2hex(songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.keyoff_pos)+' ~',
           attr[12],attr2[1]);

  ShowStr(ptr_temp_screen,xstart+65+window_area_inc_x,ystart+2,'ViBRATO ('+
          byte2hex(ptr_vibrato_table)+')',
          attr2[4]);

  ShowCStr(ptr_temp_screen,xstart+65+window_area_inc_x,ystart+4,
           'LENGTH      ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table].
                    vibrato.length)+' ~',
           attr[14],attr2[2]);

  ShowCStr(ptr_temp_screen,xstart+65+window_area_inc_x,ystart+5,
           'SPEED       ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table].
                    vibrato.speed)+' ~',
           attr[15],attr2[2]);

  ShowCStr(ptr_temp_screen,xstart+65+window_area_inc_x,ystart+6,
           'DELAY       ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table].
                    vibrato.delay)+' ~',
           attr[16],attr2[2]);

  ShowCStr(ptr_temp_screen,xstart+65+window_area_inc_x,ystart+7,
           'LOOP BEGiN  ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table].
                    vibrato.loop_begin)+' ~',
           attr[17],attr2[2]);

  ShowCStr(ptr_temp_screen,xstart+65+window_area_inc_x,ystart+8,
           'LOOP LENGTH ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table].
                    vibrato.loop_length)+' ~',
           attr[18],attr2[2]);

  ShowCStr(ptr_temp_screen,xstart+65+window_area_inc_x,ystart+9,
           'KEY-OFF     ~'+
           byte2hex(songdata.macro_table[ptr_vibrato_table].
                    vibrato.keyoff_pos)+' ~',
           attr[19],attr2[2]);

  fr_setting.update_area := FALSE;
  fr_setting.shadow_enabled := FALSE;

  If (refresh_flag AND flag_FMREG = flag_FMREG) then
    Frame(ptr_temp_screen,xstart+2,ystart+11,
          xstart+42+_add_prev_size*2,ystart+21+window_area_inc_y,
          attr[7],'',
          macro_background+macro_text,frame_type[1]);

  If (refresh_flag AND flag_ARPEGGIO = flag_ARPEGGIO) then
    Frame(ptr_temp_screen,xstart+48+window_area_inc_x,ystart+11,
          xstart+59+_add_prev_size*2,ystart+21+window_area_inc_y,
          attr[13],'',
          macro_background+macro_text,frame_type[2]);

  If (refresh_flag AND flag_VIBRATO = flag_VIBRATO) then
    Frame(ptr_temp_screen,xstart+65+window_area_inc_x,ystart+11,
          xstart+76+_add_prev_size*2,ystart+21+window_area_inc_y,
          attr[20],'',
          macro_background+macro_text,frame_type[3]);

  fr_setting.update_area := TRUE;
  fr_setting.shadow_enabled := TRUE;

  show_queue(xstart+4,ystart+11,9+window_area_inc_y,fmreg_page,255,1);
  If (refresh_flag AND flag_FMREG = flag_FMREG) then
    If NOT arp_vib_mode then
      begin
        HScrollBar(ptr_temp_screen,xstart+29+_add_prev_size*2,ystart+21+window_area_inc_y,
                   13,35,fmreg_hpos,WORD_NULL,
                   macro_scrbar_bckg+macro_scrbar_text,
                   macro_scrbar_bckg+macro_scrbar_mark);
        VScrollBar(ptr_temp_screen,xstart+43+_add_prev_size*2,ystart+12,
                   9+window_area_inc_y,255,fmreg_page,WORD_NULL,
                   macro_scrbar_bckg+macro_scrbar_text,
                   macro_scrbar_bckg+macro_scrbar_mark);
      end
    else
      begin
        HScrollBar(ptr_temp_screen,xstart+29+_add_prev_size*2,ystart+21+window_area_inc_y,
                   13,35,fmreg_hpos,WORD_NULL,
                   macro_background+macro_text_dis,
                   macro_background+macro_text_dis);
        VScrollBar(ptr_temp_screen,xstart+43+_add_prev_size*2,ystart+12,
                   9+window_area_inc_y,255,fmreg_page,WORD_NULL,
                   macro_background+macro_text_dis,
                   macro_background+macro_text_dis);
      end;

  If (pos = 7) then
    ShowStr(ptr_temp_screen,xstart+2+8,ystart+11,
            Copy(_str1(#205),fmreg_left_margin,31),
            attr[7])
  else
    ShowStr(ptr_temp_screen,xstart+2+8,ystart+11,
            Copy(_str1(#196),fmreg_left_margin,31),
            attr[7]);

  If (refresh_flag AND flag_ARPEGGIO = flag_ARPEGGIO) then
    If (ptr_arpeggio_table <> 0) then
      begin
        show_queue(xstart+50+_add_prev_size*2,ystart+11,9+window_area_inc_y,arpeggio_page,255,2);
        VScrollBar(ptr_temp_screen,xstart+60+_add_prev_size*2,ystart+12,
                   9+window_area_inc_y,255,arpeggio_page,WORD_NULL,
                   macro_scrbar_bckg+macro_scrbar_text,
                   macro_scrbar_bckg+macro_scrbar_mark)
      end
    else
      begin
        show_queue(xstart+50+_add_prev_size*2,ystart+11,9+window_area_inc_y,1,255,3);
        VScrollBar(ptr_temp_screen,xstart+60+_add_prev_size*2,ystart+12,
                   9+window_area_inc_y,255,1,WORD_NULL,
                   macro_background+macro_text_dis,
                   macro_background+macro_text_dis);
      end;

  If (refresh_flag AND flag_VIBRATO = flag_VIBRATO) then
    If (ptr_vibrato_table <> 0) then
      begin
        show_queue(xstart+67+_add_prev_size*2,ystart+11,9+window_area_inc_y,vibrato_page,255,4);
        VScrollBar(ptr_temp_screen,xstart+77+_add_prev_size*2,ystart+12,
                   9+window_area_inc_y,255,vibrato_page,WORD_NULL,
                   macro_scrbar_bckg+macro_scrbar_text,
                   macro_scrbar_bckg+macro_scrbar_mark);
      end
    else
      begin
        show_queue(xstart+67+_add_prev_size*2,ystart+11,9+window_area_inc_y,1,255,5);
        VScrollBar(ptr_temp_screen,xstart+77+_add_prev_size*2,ystart+12,
                   9+window_area_inc_y,255,1,WORD_NULL,
                   macro_background+macro_text_dis,
                   macro_background+macro_text_dis);
      end;

  If (pos <> 7) then
    ShowStr(ptr_temp_screen,xstart+2,ystart+23+window_area_inc_y,
            ExpStrR(macro_table_hint_str[pos],77,' '),
            macro_background+macro_hint)
  else ShowStr(ptr_temp_screen,xstart+2,ystart+23+window_area_inc_y,
               ExpStrR(macro_table_hint_str[20+fmreg_hpos],77,' '),
               macro_background+macro_hint);

  If (pos in [1..7]) then
    begin
      ShowStr(ptr_temp_screen,xstart+32+_add_prev_size,ystart+3,
              #253,
              macro_background+macro_text);
      ShowStr(ptr_temp_screen,xstart+32+_add_prev_size,ystart+10,
              #252,
              macro_background+macro_text);

      If NOT (fmreg_hpos in [29..33]) then
        begin
          ShowVStr(ptr_temp_screen,xstart+22,ystart+4,
                   #179#179#179#179#179#158,
                   macro_background+macro_text);
          ShowVStr(ptr_temp_screen,xstart+42+window_area_inc_x,ystart+4,
                   #179#179#179#179#179#158,
                   macro_background+macro_text);
        end
      else begin
             ShowVStr(ptr_temp_screen,xstart+22,ystart+4,
                      #179#179#158#179#179#179,
                      macro_background+macro_text);
             ShowVStr(ptr_temp_screen,xstart+42+window_area_inc_x,ystart+4,
                      #179#179#158#179#179#179,
                      macro_background+macro_text);
           end;

      max_value := 0;
      For temp := 1 to 255 do
        If (Abs(_fmreg_param(temp,fmreg_hpos)) > max_value) then
          max_value := Abs(_fmreg_param(temp,fmreg_hpos));

      If NOT (fmreg_hpos in [29..33]) then
        begin
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1,ystart+4,
                  ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                  macro_background+macro_topic);
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1,ystart+5,
                  '+',
                  macro_background+macro_topic);
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1,ystart+8,
                  ' ',
                  macro_background+macro_topic);
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1,ystart+9,
                  ExpStrR('',3,' '),
                  macro_background+macro_topic);
        end
      else
        begin
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1,ystart+4,
                  ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                  macro_background+macro_topic);
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1,ystart+5,
                  '+',
                  macro_background+macro_topic);
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1,ystart+8,
                  '-',
                  macro_background+macro_topic);
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1,ystart+9,
                  ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                  macro_background+macro_topic);
        end;

      If NOT (fmreg_hpos in [29..33]) then
        d_factor := 90/min(max_value,1)
      else d_factor := 45/min(max_value,1);

      If NOT (fmreg_hpos in [29..33]) then
        For temp := -9-_add_prev_size to 9+_add_prev_size do
          If (fmreg_page+temp >= 1) and (fmreg_page+temp <= 255) then
            If NOT _dis_fmreg_col(fmreg_hpos) then
              ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size,ystart+4,
                       ExpStrL(_gfx_bar_str(Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor),FALSE),6,' '),
                       LO(fmreg_def_attr(fmreg_page+temp)))
            else
              ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size,ystart+4,
                       ExpStrL(_gfx_bar_str(Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor),FALSE),6,' '),
                       macro_background+macro_text_dis)
          else
            ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size,ystart+4,
                     ExpStrL('',6,' '),
                     macro_background+macro_text)
      else
        For temp := -9-_add_prev_size to 9+_add_prev_size do
          If (fmreg_page+temp >= 1) and (fmreg_page+temp <= 255) then
            If (Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor) >= 0) then
              If NOT _dis_fmreg_col(fmreg_hpos) then
                ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size,ystart+4,
                         ExpStrR(ExpStrL(_gfx_bar_str(Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor),FALSE),3,' '),6,' '),
                         LO(fmreg_def_attr(fmreg_page+temp)))
              else
                ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size,ystart+4,
                         ExpStrR(ExpStrL(_gfx_bar_str(Round(_fmreg_param(fmreg_page+temp,fmreg_hpos)*d_factor),FALSE),3,' '),6,' '),
                         macro_background+macro_text_dis)
            else If NOT _dis_fmreg_col(fmreg_hpos) then
                   ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size,ystart+4,
                            ExpStrL(ExpStrR(_gfx_bar_str(Round(Abs(_fmreg_param(fmreg_page+temp,fmreg_hpos))*d_factor),TRUE),3,' '),6,' '),
                            LO(fmreg_def_attr(fmreg_page+temp)))
                 else
                   ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size,ystart+4,
                            ExpStrL(ExpStrR(_gfx_bar_str(Round(Abs(_fmreg_param(fmreg_page+temp,fmreg_hpos))*d_factor),TRUE),3,' '),6,' '),
                            macro_background+macro_text_dis)
          else
            ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size,ystart+4,
                     ExpStrR('',6,' '),
                     macro_background+macro_text);
    end;

  If (pos in [8..13]) or arp_vib_mode then
    begin
      If NOT (pos in [8..13]) then _axis_attr := macro_background+macro_topic
      else begin
             ShowStr(ptr_temp_screen,xstart+32+_add_prev_size-_sub_prev_xpos_a,ystart+3,
                     #253,
                     macro_background+macro_text);
             ShowStr(ptr_temp_screen,xstart+32+_add_prev_size-_sub_prev_xpos_a,ystart+10,
                     #252,
                     macro_background+macro_text);
           end;

      If (pos in [8..13]) then
        If arp_vib_mode then _axis_attr := macro_background+macro_hi_text
        else _axis_attr := macro_background+macro_text
      else _axis_attr := macro_background+macro_text;

      ShowVStr(ptr_temp_screen,xstart+22-_sub_prev_xpos_a,ystart+4,
               #179#179#179#179#179#158,
               _axis_attr);
      ShowVStr(ptr_temp_screen,xstart+42+window_area_inc_x-_sub_prev_xpos_a,ystart+4,
               #179#179#179#179#179#158,
               _axis_attr);

      max_value := 0;
      For temp := 1 to 255 do
        If (songdata.macro_table[ptr_arpeggio_table].
            arpeggio.data[temp] > max_value) then
          If (songdata.macro_table[ptr_arpeggio_table].
              arpeggio.data[temp] < $80) then
            max_value := Abs(songdata.macro_table[ptr_arpeggio_table].
                             arpeggio.data[temp]);

       If NOT arp_vib_mode then
         begin
           ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_a,ystart+4,
                   ExpStrR(Num2Str(max_value,10),3,' '),
                   macro_background+macro_topic);
           ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_a,ystart+5,
                   '+ ',
                   macro_background+macro_topic);
           ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_a,ystart+8,
                   '  ',
                   macro_background+macro_topic);
           ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_a,ystart+9,
                   ExpStrR('',3,' '),
                   macro_background+macro_topic);
         end
       else
         If (pos in [8..13]) then
           begin
             ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_a,ystart+4,
                     ExpStrR(Num2Str(max_value,10),3,' '),
                     macro_background+macro_hi_text);
             ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_a,ystart+5,
                     '+ ',
                     macro_background+macro_hi_text);
             ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_a,ystart+8,
                     '  ',
                     macro_background+macro_hi_text);
             ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_a,ystart+9,
                     ExpStrR('',3,' '),
                     macro_background+macro_hi_text);
           end;

      d_factor := 90/min(max_value,1);
      For temp := -9-_add_prev_size to 9+_add_prev_size do
        If (arpeggio_page+temp >= 1) and (arpeggio_page+temp <= 255) then
          If (songdata.macro_table[ptr_arpeggio_table].
              arpeggio.data[arpeggio_page+temp] < $80) then
            ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size-_sub_prev_xpos_a,ystart+4,
                     ExpStrL(_gfx_bar_str(Round(songdata.macro_table[ptr_arpeggio_table].
                                                arpeggio.data[arpeggio_page+temp]*d_factor),FALSE),6,' '),
                     LO(arpeggio_def_attr(arpeggio_page+temp)))
          else
            ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size-_sub_prev_xpos_a,ystart+4,
                     ExpStrL(FilterStr(note_layout[songdata.macro_table[ptr_arpeggio_table].
                                                   arpeggio.data[arpeggio_page+temp]-$80],'-',#241),6,' '),
                     LO(arpeggio_def_attr(arpeggio_page+temp)))
        else
          ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size-_sub_prev_xpos_a,ystart+4,
                   ExpStrL('',6,' '),
                   macro_background+macro_text);
    end;

  If (pos in [14..20]) or arp_vib_mode then
    begin
      If NOT (pos in [14..20]) then _axis_attr := macro_background+macro_text
      else begin
             ShowStr(ptr_temp_screen,xstart+32+_add_prev_size-_sub_prev_xpos_v,ystart+3,
                     #253,
                     macro_background+macro_text);
             ShowStr(ptr_temp_screen,xstart+32+_add_prev_size-_sub_prev_xpos_v,ystart+10,
                     #252,
                     macro_background+macro_text);
           end;

      If (pos in [14..20]) then
        If arp_vib_mode then _axis_attr := macro_background+macro_hi_text
        else _axis_attr := macro_background+macro_text
      else _axis_attr := macro_background+macro_text;

      ShowVStr(ptr_temp_screen,xstart+22-_sub_prev_xpos_v,ystart+4,
               #179#179#158#179#179#179,
               _axis_attr);
      ShowVStr(ptr_temp_screen,xstart+42+window_area_inc_x-_sub_prev_xpos_v,ystart+4,
               #179#179#158#179#179#179,
               _axis_attr);

      max_value := 0;
      For temp := 1 to 255 do
        If (Abs(songdata.macro_table[ptr_vibrato_table].
                vibrato.data[temp]) > max_value) then
          max_value := Abs(songdata.macro_table[ptr_vibrato_table].
                           vibrato.data[temp]);

      If NOT arp_vib_mode then
        begin
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_v,ystart+4,
                  ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                  macro_background+macro_topic);
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_v,ystart+5,
                  '+',
                  macro_background+macro_topic);
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_v,ystart+8,
                  '-',
                  macro_background+macro_topic);
          ShowStr(ptr_temp_screen,xstart+42+window_area_inc_x+1-_sub_prev_xpos_v,ystart+9,
                  ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
                  macro_background+macro_topic);
        end
      else
        If (pos in [14..20]) then
          begin
            ShowStr(ptr_temp_screen,xstart+20-_sub_prev_xpos_v,ystart+4,
                    ExpStrL(ExpStrL(Num2Str(max_value,16),2,'0'),2,' '),
                    macro_background+macro_hi_text);
            ShowStr(ptr_temp_screen,xstart+20-_sub_prev_xpos_v,ystart+5,
                    ' +',
                    macro_background+macro_hi_text);
            ShowStr(ptr_temp_screen,xstart+20-_sub_prev_xpos_v,ystart+8,
                    ' -',
                    macro_background+macro_hi_text);
            ShowStr(ptr_temp_screen,xstart+20-_sub_prev_xpos_v,ystart+9,
                    ExpStrL(ExpStrL(Num2Str(max_value,16),2,'0'),2,' '),
                    macro_background+macro_hi_text);
          end;

      d_factor := 45/min(max_value,1);
      For temp := -9-_add_prev_size to 9+_add_prev_size do
        If (vibrato_page+temp >= 1) and (vibrato_page+temp <= 255) then
          If (Round(songdata.macro_table[ptr_vibrato_table].
                    vibrato.data[vibrato_page+temp]*d_factor) >= 0) then
            ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size-_sub_prev_xpos_v,ystart+4,
                     ExpStrR(ExpStrL(_gfx_bar_str(Round(songdata.macro_table[ptr_vibrato_table].
                                                        vibrato.data[vibrato_page+temp]*d_factor),FALSE),3,' '),6,' '),
                     LO(vibrato_def_attr(vibrato_page+temp)))
          else
            ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size-_sub_prev_xpos_v,ystart+4,
                     ExpStrL(ExpStrR(_gfx_bar_str(Round(Abs(songdata.macro_table[ptr_vibrato_table].
                                                            vibrato.data[vibrato_page+temp])*d_factor),TRUE),3,' '),6,' '),
                     LO(vibrato_def_attr(vibrato_page+temp)))
        else
          ShowVStr(ptr_temp_screen,xstart+32+temp+_add_prev_size-_sub_prev_xpos_v,ystart+4,
                   ExpStrR('',6,' '),
                   macro_background+macro_text);
    end;

  If NOT (get_4op_to_test <> 0) then _4op_pos_shift := 0
  else _4op_pos_shift := 6;

  If (get_4op_to_test <> 0) then
    begin
      _4op_ins1 := HI(get_4op_to_test);
      _4op_ins2 := LO(get_4op_to_test);
      If (_4op_ins1 = _4op_ins2) then
        ShowC3Str(ptr_temp_screen,xstart+01,ystart+24+window_area_inc_y,
                  ' `[`'#244+byte2hex(_4op_ins1)+
                  ','#245+byte2hex(_4op_ins1)+' '+
                  connection_str[pBYTE(@Addr(songdata.instr_data[_4op_ins1])^)[10] AND 1]+'/'+
                  connection_str[pBYTE(@Addr(songdata.instr_data[_4op_ins2])^)[10] AND 1]+
                  '`]` ',
                  macro_background+macro_hi_text,
                  macro_hi_text SHL 4,
                  macro_background+macro_border)
      else
        If (current_inst = _4op_ins1) then
          ShowC3Str(ptr_temp_screen,xstart+01,ystart+24+window_area_inc_y,
                    ' `[`~'#244+byte2hex(_4op_ins1)+
                    '~,'#245+byte2hex(_4op_ins2)+' ~'+
                    connection_str[pBYTE(@Addr(songdata.instr_data[_4op_ins1])^)[10] AND 1]+'~/'+
                    connection_str[pBYTE(@Addr(songdata.instr_data[_4op_ins2])^)[10] AND 1]+
                    '`]` ',
                    macro_background+macro_hi_text,
                    macro_hi_text SHL 4,
                    macro_background+macro_border)
        else
          ShowC3Str(ptr_temp_screen,xstart+01,ystart+24+window_area_inc_y,
                    ' `[`'#244+byte2hex(_4op_ins1)+
                    ',~'#245+byte2hex(_4op_ins2)+'~ '+
                    connection_str[pBYTE(@Addr(songdata.instr_data[_4op_ins1])^)[10] AND 1]+'/~'+
                    connection_str[pBYTE(@Addr(songdata.instr_data[_4op_ins2])^)[10] AND 1]+
                    '~`]` ',
                    macro_background+macro_hi_text,
                    macro_hi_text SHL 4,
                    macro_background+macro_border);
    end
  else
    ShowCStr(ptr_temp_screen,
             xstart+01,ystart+24+window_area_inc_y,
             ' [~'+perc_voice_str[songdata.instr_data[current_inst].perc_voice]+'~] ',
             macro_background+macro_border,
             macro_background+macro_hi_text);

  If (songdata.instr_macros[current_inst].length <> 0) then
    temp_str := ' [~MACRO:FM'
  else temp_str := ' ';

  If NOT arp_vib_mode then
    begin
      If (ptr_arpeggio_table <> 0) then
        If (temp_str <> ' ') then temp_str := temp_str+'+ARP'
        else temp_str := temp_str+'[~MACRO:ARP';
      If (ptr_vibrato_table <> 0) then
        If (temp_str <> ' ') then temp_str := temp_str+'+ViB'
        else temp_str := temp_str+'[~MACRO:ViB';
    end;

  If (temp_str <> ' ') then
    temp_str := temp_str+'~] ';

  ShowCStr(ptr_temp_screen,xstart+11+_4op_pos_shift,ystart+24+window_area_inc_y,ExpStrR(temp_str,21+2,#205),
           macro_background+macro_border,
           macro_background+macro_hi_text);

  If (songdata.instr_data[instr].perc_voice in [2..5]) then
     begin
       temp_str := '```` ';
       nm_slots := 1;
     end
   else If NOT (get_4op_to_test <> 0) then
          begin
            temp_str := ' `[`12`]` ';
            nm_slots := 2;
          end
        else begin
               temp_str := ' `[`1234`]` ';
               nm_slots := 4;
             end;

  temp_str := temp_str+'[~SPEED:'+Num2str(songdata.tempo*songdata.macro_speedup,10)+#174+'~] ';
  ShowC3Str(ptr_temp_screen,xstart+window_area_inc_x+59,ystart+24+window_area_inc_y,
            ExpStrL(temp_str,28,#205),
            macro_background+macro_border,
            macro_background+macro_context,
            macro_background+macro_context_dis);

  If (nm_slots > 1) then
    For temp := 1 to nm_slots do
      If (NOT _operator_enabled[temp]) then
        ShowStr(ptr_temp_screen,xstart+window_area_inc_x+83-C3StrLen(temp_str)-1+temp,ystart+24+window_area_inc_y,
                #250,
                instrument_bckg+instrument_border);

  _preview_indic_proc(0);
  move2screen_alt;
end;

function hex(chr: Char): Byte;
begin
  hex := PRED(SYSTEM.Pos(UpCase(chr),_hex));
end;

procedure copy_object;

var
  temp: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:copy_object';
{$ENDIF}

  Case clipboard.object_type of
    objMacroTableLine:
      Case clipboard.mcrtab_type of
        mttFM_reg_table:
          clipboard.fmreg_table.data[1] :=
            songdata.instr_macros[instr].data[fmreg_page];

        mttArpeggio_table:
          clipboard.macro_table.arpeggio.data[1] :=
            songdata.macro_table[ptr_arpeggio_table].
            arpeggio.data[arpeggio_page];

        mttVibrato_table:
          clipboard.macro_table.vibrato.data[1] :=
            songdata.macro_table[ptr_vibrato_table].
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
            songdata.macro_table[ptr_arpeggio_table].arpeggio;

        mttVibrato_table:
          clipboard.macro_table.vibrato :=
            songdata.macro_table[ptr_vibrato_table].vibrato;
      end;

    objMacroTable:
      Case clipboard.mcrtab_type of
        mttFM_reg_table:
          clipboard.fmreg_table :=
            songdata.instr_macros[instr];

        mttArpeggio_table:
          clipboard.macro_table.arpeggio :=
            songdata.macro_table[ptr_arpeggio_table].arpeggio;

        mttVibrato_table:
          clipboard.macro_table.vibrato :=
            songdata.macro_table[ptr_vibrato_table].vibrato;
      end;
  end;
end;

procedure paste_object;

var
  temp: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:paste_object';
{$ENDIF}

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
            songdata.macro_table[ptr_arpeggio_table].
            arpeggio.data[arpeggio_page] :=
              clipboard.macro_table.arpeggio.data[1];

        mttVibrato_table:
          If (pos = 20) then
            songdata.macro_table[ptr_vibrato_table].
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
              songdata.macro_table[ptr_arpeggio_table].
              arpeggio.data[temp] :=
                clipboard.macro_table.arpeggio.data[temp];

        mttVibrato_table:
          If (pos in [14..20]) then
            For temp := 1 to 255 do
              songdata.macro_table[ptr_vibrato_table].
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
            songdata.macro_table[ptr_arpeggio_table].arpeggio :=
              clipboard.macro_table.arpeggio;

        mttVibrato_table:
          If (pos in [14..20]) then
            songdata.macro_table[ptr_vibrato_table].vibrato :=
              clipboard.macro_table.vibrato;
      end;
  end;
end;

procedure _scroll_cur_left;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:_scroll_cur_left';
{$ENDIF}
  Repeat
    If (fmreg_cursor_pos > 1) then Dec(fmreg_cursor_pos)
    else Dec(fmreg_left_margin);
  until (fmreg_str[PRED(fmreg_left_margin+fmreg_cursor_pos-1)] = ' ') or
        (fmreg_left_margin+fmreg_cursor_pos-1 = 1);
  fmreg_cursor_pos := pos5[fmreg_hpos]-fmreg_left_margin+1;
end;

procedure _scroll_cur_right;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR:_scroll_cur_right';
{$ENDIF}
  Repeat
    If (fmreg_cursor_pos < max(57,31+window_area_inc_x)) then Inc(fmreg_cursor_pos)
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

procedure _set_operator_flag(operator: Byte; toggle: Boolean);

var
  _temp_operator_enabled: array[1..4] of Boolean;

begin
  If (songdata.instr_data[instr].perc_voice in [2..5]) or
     (NOT (get_4op_to_test <> 0) and NOT (operator in [1..2])) or
     (NOT (operator in [1..4])) then
    EXIT;

  If NOT toggle then
    begin
      FillChar(_operator_enabled,SizeOf(_operator_enabled),FALSE);
      _operator_enabled[operator] := TRUE;
      EXIT;
    end;

  Move(_operator_enabled,_temp_operator_enabled,SizeOf(_temp_operator_enabled));
  If NOT (get_4op_to_test <> 0) and (operator in [1,2]) then
    begin
      _temp_operator_enabled[operator] := NOT _temp_operator_enabled[operator];
      If NOT ((_temp_operator_enabled[1] = FALSE) and
              (_temp_operator_enabled[2] = FALSE)) then
        Move(_temp_operator_enabled,_operator_enabled,SizeOf(_operator_enabled));
    end
  else If (get_4op_to_test <> 0) and (operator in [1,2,3,4]) then
         begin
           _temp_operator_enabled[operator] := NOT _temp_operator_enabled[operator];
           If NOT ((_temp_operator_enabled[1] = FALSE) and
                   (_temp_operator_enabled[2] = FALSE) and
                   (_temp_operator_enabled[3] = FALSE) and
                   (_temp_operator_enabled[4] = FALSE)) then
           Move(_temp_operator_enabled,_operator_enabled,SizeOf(_operator_enabled));
         end;
end;

function _check_macro_speed_change: Boolean;
begin
  _check_macro_speed_change := FALSE;
  Case is_environment.keystroke of
    kCtLbr:  If shift_pressed then
               begin
                 If (songdata.macro_speedup > 1) then
                   Dec(songdata.macro_speedup);
                 macro_speedup := songdata.macro_speedup;
                 keyboard_reset_buffer;
               end
             else If (current_inst > 1) then
                    begin
                      Dec(current_inst);
                      If NOT (marked_instruments = 2) then reset_marked_instruments;
                      instrum_page := current_inst;
                      FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
                      STATUS_LINE_refresh;
                      keyboard_reset_buffer;
                      _check_macro_speed_change := TRUE;
                    end;

    kCtRbr:  If shift_pressed then
               begin
                 Inc(songdata.macro_speedup);
                 If (calc_max_speedup(songdata.tempo) < songdata.macro_speedup) then
                   songdata.macro_speedup := calc_max_speedup(songdata.tempo);
                 macro_speedup := songdata.macro_speedup;
                 keyboard_reset_buffer;
               end
             else If (current_inst < 255) then
                    begin
                      Inc(current_inst);
                      If NOT (marked_instruments = 2) then reset_marked_instruments;
                      instrum_page := current_inst;
                      FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
                      STATUS_LINE_refresh;
                      keyboard_reset_buffer;
                      _check_macro_speed_change := TRUE;
                    end;
  end;

  If (is_environment.keystroke = kAlt0) or (is_environment.keystroke = kAlt1) or
     (is_environment.keystroke = kAlt2) or (is_environment.keystroke = kAlt3) or
     (is_environment.keystroke = kAlt4) then
    begin
      _check_macro_speed_change := TRUE;
      Case is_environment.keystroke of
        kAlt0:   FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
        kAlt1:   If shift_pressed then
                   _set_operator_flag(1,TRUE)
                 else _set_operator_flag(1,FALSE);
        kAlt2:   If shift_pressed then
                   _set_operator_flag(2,TRUE)
                 else _set_operator_flag(2,FALSE);
        kAlt3:   If shift_pressed then
                   _set_operator_flag(3,TRUE)
                 else _set_operator_flag(3,FALSE);
        kAlt4:   If shift_pressed then
                   _set_operator_flag(4,TRUE)
                 else _set_operator_flag(4,FALSE);
      end;
    end;
end;

procedure _check_fmreg_general_keys;
begin
  Case is_environment.keystroke of
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
  end;
end;

procedure _check_arp_general_keys;
begin
  Case is_environment.keystroke of
    kCtHOME:  If NOT shift_pressed then
                If (songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.length > 0) then
                  Dec(songdata.macro_table[ptr_arpeggio_table].
                      arpeggio.length)
                else
             else If (songdata.macro_table[ptr_arpeggio_table].
                      arpeggio.loop_begin > 0) then
                    begin
                      Dec(songdata.macro_table[ptr_arpeggio_table].
                          arpeggio.loop_begin);

                      While NOT ((songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table].
                                                        arpeggio.loop_begin+
                                              min0(songdata.macro_table[ptr_arpeggio_table].
                                                   arpeggio.loop_length-1,0)) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.loop_begin = 0) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.loop_length = 0) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.keyoff_pos = 0)) do
                        Inc(songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.keyoff_pos);

                    end;

    kCtEND:  If NOT shift_pressed then
               If (songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.length < 255) then
                 Inc(songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.length)
               else
             else If (songdata.macro_table[ptr_arpeggio_table].
                      arpeggio.loop_begin < 255) then
                    begin
                      Inc(songdata.macro_table[ptr_arpeggio_table].
                          arpeggio.loop_begin);

                      While NOT ((songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table].
                                                        arpeggio.loop_begin+
                                              min0(songdata.macro_table[ptr_arpeggio_table].
                                                   arpeggio.loop_length-1,0)) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.loop_begin = 0) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.loop_length = 0) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.keyoff_pos = 0)) do
                        Inc(songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.keyoff_pos);

                    end;

    kCtPgUP: If NOT shift_pressed then
               If (ptr_arpeggio_table > 1) then
                 Dec(ptr_arpeggio_table)
               else
             else If (songdata.macro_table[ptr_arpeggio_table].
                      arpeggio.loop_length > 0) then
                    begin
                      Dec(songdata.macro_table[ptr_arpeggio_table].
                          arpeggio.loop_length);

                      While NOT ((songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table].
                                                        arpeggio.loop_begin+
                                              min0(songdata.macro_table[ptr_arpeggio_table].
                                                   arpeggio.loop_length-1,0)) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.loop_begin = 0) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.loop_length = 0) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.keyoff_pos = 0)) do
                        Inc(songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.keyoff_pos);

                    end;

    kCtPgDN: If NOT shift_pressed then
               If (ptr_arpeggio_table < 255) then
                 Inc(ptr_arpeggio_table)
               else
             else If (songdata.macro_table[ptr_arpeggio_table].
                      arpeggio.loop_length < 255) then
                    begin
                      Inc(songdata.macro_table[ptr_arpeggio_table].
                          arpeggio.loop_length);

                      While NOT ((songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table].
                                                        arpeggio.loop_begin+
                                              min0(songdata.macro_table[ptr_arpeggio_table].
                                                   arpeggio.loop_length-1,0)) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.loop_begin = 0) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.loop_length = 0) or
                                 (songdata.macro_table[ptr_arpeggio_table].
                                  arpeggio.keyoff_pos = 0)) do
                        Inc(songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.keyoff_pos);

                    end;

  end;
end;

procedure _check_vib_general_keys;
begin
  Case is_environment.keystroke of
    kCtHOME:  If NOT shift_pressed then
                If (songdata.macro_table[ptr_vibrato_table].
                   vibrato.length > 0) then
                  Dec(songdata.macro_table[ptr_vibrato_table].
                      vibrato.length)
                else
             else If (songdata.macro_table[ptr_vibrato_table].
                      vibrato.loop_begin > 0) then
                    begin
                      Dec(songdata.macro_table[ptr_vibrato_table].
                          vibrato.loop_begin);

                      While NOT ((songdata.macro_table[ptr_vibrato_table].
                                  vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table].
                                                       vibrato.loop_begin+
                                              min0(songdata.macro_table[ptr_vibrato_table].
                                                   vibrato.loop_length-1,0)) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.loop_begin = 0) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.loop_length = 0) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.keyoff_pos = 0)) do
                        Inc(songdata.macro_table[ptr_vibrato_table].
                            vibrato.keyoff_pos);

                    end;

    kCtEND:  If NOT shift_pressed then
               If (songdata.macro_table[ptr_vibrato_table].
                   vibrato.length < 255) then
                 Inc(songdata.macro_table[ptr_vibrato_table].
                   vibrato.length)
               else
             else If (songdata.macro_table[ptr_vibrato_table].
                      vibrato.loop_begin < 255) then
                    begin
                      Inc(songdata.macro_table[ptr_vibrato_table].
                          vibrato.loop_begin);

                      While NOT ((songdata.macro_table[ptr_vibrato_table].
                                  vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table].
                                                       vibrato.loop_begin+
                                              min0(songdata.macro_table[ptr_vibrato_table].
                                                   vibrato.loop_length-1,0)) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.loop_begin = 0) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.loop_length = 0) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.keyoff_pos = 0)) do
                        Inc(songdata.macro_table[ptr_vibrato_table].
                            vibrato.keyoff_pos);

                    end;

    kCtPgUP: If NOT shift_pressed then
               If (ptr_vibrato_table > 1) then
                 Dec(ptr_vibrato_table)
               else
             else If (songdata.macro_table[ptr_vibrato_table].
                      vibrato.loop_length > 0) then
                    begin
                      Dec(songdata.macro_table[ptr_vibrato_table].
                          vibrato.loop_length);

                      While NOT ((songdata.macro_table[ptr_vibrato_table].
                                  vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table].
                                                       vibrato.loop_begin+
                                              min0(songdata.macro_table[ptr_vibrato_table].
                                                   vibrato.loop_length-1,0)) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.loop_begin = 0) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.loop_length = 0) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.keyoff_pos = 0)) do
                        Inc(songdata.macro_table[ptr_vibrato_table].
                            vibrato.keyoff_pos);

                    end;

    kCtPgDN: If NOT shift_pressed then
               If (ptr_vibrato_table < 255) then
                 Inc(ptr_vibrato_table)
               else
             else If (songdata.macro_table[ptr_vibrato_table].
                      vibrato.loop_length < 255) then
                    begin
                      Inc(songdata.macro_table[ptr_vibrato_table].
                          vibrato.loop_length);

                      While NOT ((songdata.macro_table[ptr_vibrato_table].
                                  vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table].
                                                       vibrato.loop_begin+
                                              min0(songdata.macro_table[ptr_vibrato_table].
                                                   vibrato.loop_length-1,0)) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.loop_begin = 0) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.loop_length = 0) or
                                 (songdata.macro_table[ptr_vibrato_table].
                                  vibrato.keyoff_pos = 0)) do
                        Inc(songdata.macro_table[ptr_vibrato_table].
                            vibrato.keyoff_pos);

                    end;
  end;
end;

label _jmp1,_jmp2,_end2;

begin { MACRO_EDITOR }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_EDITOR';
{$ENDIF}

  _arp_vib_mode := arp_vib_mode;
  If is_default_screen_mode then
    begin
       window_area_inc_x := 0;
       window_area_inc_y := 0;
    end
  else begin
         If NOT arp_vib_mode then window_area_inc_x := 10
         else window_area_inc_x := 0;
         window_area_inc_y := 10;
       end;

  call_pickup_proc := FALSE;
  _source_ins := instrum_page;
  call_pickup_proc2 := FALSE;
  _source_ins2 := instrum_page;

_jmp1:
  If NOT arp_vib_mode then
    begin
      ptr_arpeggio_table := songdata.instr_macros[instr].arpeggio_table;
      ptr_vibrato_table := songdata.instr_macros[instr].vibrato_table;
    end
  else begin
         ptr_arpeggio_table := arpvib_arpeggio_table;
         ptr_vibrato_table := arpvib_vibrato_table;
       end;

  pos := _macro_editor__pos[arp_vib_mode];
  If arp_vib_mode and (pos < 8) then pos := 8
  else If NOT arp_vib_mode and
          (((ptr_arpeggio_table = 0) and (pos in [8..13])) or
           ((ptr_vibrato_table = 0) and (pos in [14..20]))) then
          pos := 1;

  fmreg_hpos := _macro_editor__fmreg_hpos[arp_vib_mode];
  fmreg_page := _macro_editor__fmreg_page[arp_vib_mode];
  fmreg_left_margin := _macro_editor__fmreg_left_margin[arp_vib_mode];
  fmreg_cursor_pos := _macro_editor__fmreg_cursor_pos[arp_vib_mode];
  arpeggio_page := _macro_editor__arpeggio_page[arp_vib_mode];
  vibrato_hpos := _macro_editor__vibrato_hpos[arp_vib_mode];
  vibrato_page := _macro_editor__vibrato_page[arp_vib_mode];

  If _force_program_quit then EXIT;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  HideCursor;

  For temp := 1 to 255 do
    begin
      temp_marks[temp] := songdata.instr_names[temp][1];
      songdata.instr_names[temp][1] := ' ';
    end;

  songdata_crc := Update32(songdata,SizeOf(songdata),0);
  For temp := 1 to 255 do
    songdata.instr_names[temp][1] := temp_marks[temp];

  ScreenMemCopy(screen_ptr,ptr_temp_screen);
  centered_frame_vdest := ptr_temp_screen;

  If NOT arp_vib_mode then
    centered_frame(xstart,ystart,81+window_area_inc_x,24+window_area_inc_y,
                   ' iNSTRUMENT MACRO EDiTOR (iNS_  ) ',
                   macro_background+dialog_border,
                   macro_background+dialog_title,
                   frame_double)
  else
    centered_frame(xstart,ystart,81+window_area_inc_x,24+window_area_inc_y,
                   ' ARPEGGiO/ViBRATO MACRO EDiTOR (iNS_  ) ',
                   macro_background+dialog_border,
                   macro_background+dialog_title,
                   frame_double);

  _pip_xloc := xstart+30+(window_area_inc_x DIV 2);
  _pip_yloc := ystart+2;
  _pip_dest := ptr_temp_screen;

  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+81+2+window_area_inc_x;
  move_to_screen_area[4] := ystart+24+1+window_area_inc_y;
  refresh(flag_FMREG+flag_ARPEGGIO+flag_VIBRATO);

  move_to_screen_area[1] := xstart+1;
  move_to_screen_area[2] := ystart+1;
  move_to_screen_area[3] := xstart+80+window_area_inc_x;
  move_to_screen_area[4] := ystart+24+window_area_inc_y;

  If (pos = 1) then GotoXY(xstart+17,ystart+4);
  ThinCursor;
  centered_frame_vdest := screen_ptr;

  Move(is_setting.terminate_keys,old_keys,SizeOf(old_keys));
  Move(new_keys,is_setting.terminate_keys,SizeOf(new_keys));

  old_instr := instr;
  old_pos := pos;
  old_arp_ptr := ptr_arpeggio_table;
  old_vib_ptr := ptr_vibrato_table;
  old_fmreg_page := fmreg_page;
  old_arpeggio_page := arpeggio_page;
  old_vibrato_page := vibrato_page;

_jmp2:
  If NOT arp_vib_mode then
    begin
      songdata.instr_macros[instr].arpeggio_table := ptr_arpeggio_table;
      songdata.instr_macros[instr].vibrato_table := ptr_vibrato_table;
    end;

  If (instr <> current_inst) then
    instr := current_inst;

  If NOT arp_vib_mode then
    begin
      ptr_arpeggio_table := songdata.instr_macros[instr].arpeggio_table;
      ptr_vibrato_table := songdata.instr_macros[instr].vibrato_table;
    end;

  If arp_vib_mode and (pos < 8) then pos := 8
  else If NOT arp_vib_mode and
          (((ptr_arpeggio_table = 0) and (pos in [8..13])) or
           ((ptr_vibrato_table = 0) and (pos in [14..20]))) then
          pos := 1;

  If NOT arp_vib_mode then
    ShowStr(centered_frame_vdest,xstart+54+(window_area_inc_x DIV 2),ystart,
            byte2hex(instr),macro_background+dialog_title)
  else
    ShowStr(centered_frame_vdest,xstart+57+(window_area_inc_x DIV 2),ystart,
            byte2hex(instr),macro_background+dialog_title);

  If NOT _force_program_quit then
    Repeat
      If arp_vib_mode then refresh(flag_ARPEGGIO+flag_VIBRATO)
      else begin
             Case pos of
               1..7:   begin
                         refresh_flag := flag_FMREG;
                         If (old_pos in [8..13]) or
                            (old_arpeggio_page <> arpeggio_page) or
                            (old_arp_ptr <> ptr_arpeggio_table) or
                            (old_instr <> instr) then
                           refresh_flag := refresh_flag+flag_ARPEGGIO;
                         If (old_pos in [14..20]) or
                            (old_vibrato_page <> vibrato_page) or
                            (old_vib_ptr <> ptr_vibrato_table) or
                            (old_instr <> instr) then
                           refresh_flag := refresh_flag+flag_VIBRATO;
                       end;

               8..13:  begin
                         refresh_flag := flag_ARPEGGIO;
                         If (old_pos in [1..7]) or
                            (old_fmreg_page <> fmreg_page) or
                            (old_instr <> instr) then
                           refresh_flag := refresh_flag+flag_FMREG;
                         If (old_pos in [14..20]) or
                            (old_vibrato_page <> vibrato_page) or
                            (old_vib_ptr <> ptr_vibrato_table) or
                            (old_instr <> instr) then
                           refresh_flag := refresh_flag+flag_VIBRATO;
                       end;

               14..20: begin
                         refresh_flag := flag_VIBRATO;
                         If (old_pos in [1..7]) or
                            (old_fmreg_page <> fmreg_page) or
                            (old_instr <> instr) then
                           refresh_flag := refresh_flag+flag_FMREG;
                         If (old_pos in [8..13]) or
                            (old_arpeggio_page <> arpeggio_page) or
                            (old_arp_ptr <> ptr_arpeggio_table) or
                            (old_instr <> instr) then
                           refresh_flag := refresh_flag+flag_ARPEGGIO;
                       end;
             end;

             old_instr := instr;
             old_pos := pos;
             old_arp_ptr := ptr_arpeggio_table;
             old_vib_ptr := ptr_vibrato_table;
             old_fmreg_page := fmreg_page;
             old_arpeggio_page := arpeggio_page;
             old_vibrato_page := vibrato_page;
             refresh(refresh_flag);
           end;

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
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.instr_macros[instr].length < 255) then
                          Inc(songdata.instr_macros[instr].length);
               kCHmins,
               kNPmins: If (songdata.instr_macros[instr].length > 0) then
                          Dec(songdata.instr_macros[instr].length);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 2
             else If (is_environment.keystroke = kUP) then pos := 7
                  else If (is_environment.keystroke = kShTAB) then
                         If (ptr_vibrato_table <> 0) then pos := 20
                         else If (ptr_arpeggio_table <> 0) then pos := 13
                              else pos := 7;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_fmreg_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If (ptr_vibrato_table <> 0) then pos := 14
                        else If (ptr_arpeggio_table <> 0) then pos := 8;

               kCtRGHT: If (ptr_arpeggio_table <> 0) then pos := 8
                        else If (ptr_vibrato_table <> 0) then pos := 14;

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
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.instr_macros[instr].loop_begin < 255) then
                          Inc(songdata.instr_macros[instr].loop_begin);
               kCHmins,
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

             If _check_macro_speed_change then GOTO _jmp2;
             _check_fmreg_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If (ptr_vibrato_table <> 0) then pos := 17
                        else If (ptr_arpeggio_table <> 0) then pos := 10;

               kCtRGHT: If (ptr_arpeggio_table <> 0) then pos := 10
                        else If (ptr_vibrato_table <> 0) then pos := 17;

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
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.instr_macros[instr].loop_length < 255) then
                          Inc(songdata.instr_macros[instr].loop_length);
               kCHmins,
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

             If _check_macro_speed_change then GOTO _jmp2;
             _check_fmreg_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If (ptr_vibrato_table <> 0) then pos := 18
                        else If (ptr_arpeggio_table <> 0) then pos := 11;

               kCtRGHT: If (ptr_arpeggio_table <> 0) then pos := 11
                        else If (ptr_vibrato_table <> 0) then pos := 18;

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
             Case is_environment.keystroke of
               kCHplus,
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
               kCHmins,
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

             If _check_macro_speed_change then GOTO _jmp2;
             _check_fmreg_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If (ptr_vibrato_table <> 0) then pos := 19
                        else If (ptr_arpeggio_table <> 0) then pos := 12;

               kCtRGHT: If (ptr_arpeggio_table <> 0) then pos := 12
                        else If (ptr_vibrato_table <> 0) then pos := 19;

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
               temps := InputStr(byte2hex(ptr_arpeggio_table),
                                 xstart+17,ystart+8,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             ptr_arpeggio_table := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (ptr_arpeggio_table < 255) then
                          Inc(ptr_arpeggio_table);
               kCHmins,
               kNPmins: If (ptr_arpeggio_table > 0) then
                          Dec(ptr_arpeggio_table);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 6
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 4;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_fmreg_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If (ptr_vibrato_table <> 0) then pos := 14
                        else If (ptr_arpeggio_table <> 0) then pos := 8;

               kCtRGHT: If (ptr_arpeggio_table <> 0) then pos := 8
                        else If (ptr_vibrato_table <> 0) then pos := 14;
             end;
           end;

        6: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(ptr_vibrato_table),
                                 xstart+17,ystart+9,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             ptr_vibrato_table := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (ptr_vibrato_table < 255) then
                          Inc(ptr_vibrato_table);
               kCHmins,
               kNPmins: If (ptr_vibrato_table > 0) then
                          Dec(ptr_vibrato_table);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 7
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 5;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_fmreg_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If (ptr_vibrato_table <> 0) then pos := 14
                        else If (ptr_arpeggio_table <> 0) then pos := 8;

               kCtRGHT: If (ptr_arpeggio_table <> 0) then pos := 8
                        else If (ptr_vibrato_table <> 0) then pos := 14;

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

             If _check_macro_speed_change then GOTO _jmp2;
             _check_fmreg_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If NOT shift_pressed then
                          If (ptr_vibrato_table <> 0) then pos := 20
                          else If (ptr_arpeggio_table <> 0) then pos := 13
                               else
                        else If (fmreg_page > songdata.instr_macros[instr].length) then
                               fmreg_page := min(1,songdata.instr_macros[instr].length)
                             else fmreg_page := 1;

               kCtRGHT: If NOT shift_pressed then
                          If (ptr_arpeggio_table <> 0) then pos := 13
                          else If (ptr_vibrato_table <> 0) then pos := 20
                               else
                        else If (fmreg_page < songdata.instr_macros[instr].length) then
                               fmreg_page := min(1,songdata.instr_macros[instr].length)
                             else fmreg_page := 255;

               kUP: If (fmreg_page > 1) then Dec(fmreg_page)
                    else If cycle_pattern then fmreg_page := 255;

               kDOWN: If (fmreg_page < 255) then Inc(fmreg_page)
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
                            fmreg_cursor_pos := max(57,31+window_area_inc_x);
                            fmreg_left_margin := min(pos5[fmreg_hpos]-(31+window_area_inc_x)+1,1);
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
                           fmreg_cursor_pos := max(57,31+window_area_inc_x);
                           fmreg_left_margin := min(pos5[fmreg_hpos]-(31+window_area_inc_x)+1,1);
                         end;

               kLEFT: If (fmreg_hpos > 1) then
                        begin
                          Dec(fmreg_hpos);
                          _scroll_cur_left;
                        end
                      else If cycle_pattern then
                             begin
                               fmreg_hpos := 35;
                               fmreg_cursor_pos := max(57,31+window_area_inc_x);
                               fmreg_left_margin := min(pos5[fmreg_hpos]-(31+window_area_inc_x)+1,1);
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

               kTAB: If (ptr_arpeggio_table <> 0) then pos := 8
                     else If (ptr_vibrato_table <> 0) then pos := 14
                            else pos := 1;

               kShTAB: pos := 6;

               kENTER: If NOT shift_pressed then
                         begin
                           If (ptr_arpeggio_table <> 0) then pos := 8
                           else If (ptr_vibrato_table <> 0) then pos := 14
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

               kAltC: If ctrl_pressed and (fmreg_hpos in [1..13]) then
                        For temp := 1 to 255 do
                          With songdata.instr_macros[instr].data[temp] do
                            Case fmreg_hpos of
                              1: fm_data.ATTCK_DEC_modulator :=
                                 (fm_data.ATTCK_DEC_carrier SHR 4) SHL 4+
                                 fm_data.ATTCK_DEC_modulator AND $0f;
                              2: fm_data.ATTCK_DEC_modulator :=
                                 fm_data.ATTCK_DEC_modulator AND $0f0+
                                 (fm_data.ATTCK_DEC_carrier AND $0f);
                              3: fm_data.SUSTN_REL_modulator :=
                                 (fm_data.SUSTN_REL_carrier SHR 4) SHL 4+
                                 fm_data.SUSTN_REL_modulator AND $0f;
                              4: fm_data.SUSTN_REL_modulator :=
                                 fm_data.SUSTN_REL_modulator AND $0f0+
                                 (fm_data.SUSTN_REL_carrier AND $0f);
                              5: fm_data.WAVEFORM_modulator :=
                                 fm_data.WAVEFORM_carrier;
                              6,
                              7: fm_data.KSL_VOLUM_modulator :=
                                 fm_data.KSL_VOLUM_modulator AND $0c0+
                                 (fm_data.KSL_VOLUM_carrier AND $3f);
                              8: fm_data.KSL_VOLUM_modulator :=
                                 fm_data.KSL_VOLUM_modulator AND $3f+
                                 (fm_data.KSL_VOLUM_carrier SHR 6) SHL 6;
                              9: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0f0+
                                 (fm_data.AM_VIB_EG_carrier AND $0f);
                             10: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $7f+
                                 (fm_data.AM_VIB_EG_carrier SHR 7) SHL 7;
                             11: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0bf+
                                 (fm_data.AM_VIB_EG_carrier SHR 6 AND 1) SHL 6;
                             12: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0ef+
                                 (fm_data.AM_VIB_EG_carrier SHR 4 AND 1) SHL 4;
                             13: fm_data.AM_VIB_EG_modulator :=
                                 fm_data.AM_VIB_EG_modulator AND $0df+
                                 (fm_data.AM_VIB_EG_carrier SHR 5 AND 1) SHL 5;
                            end;

               kAltM: If ctrl_pressed and (fmreg_hpos in [14..26]) then
                        For temp := 1 to 255 do
                          With songdata.instr_macros[instr].data[temp] do
                            Case fmreg_hpos of
                              14: fm_data.ATTCK_DEC_carrier :=
                                  (fm_data.ATTCK_DEC_modulator SHR 4) SHL 4+
                                  fm_data.ATTCK_DEC_carrier AND $0f;
                              15: fm_data.ATTCK_DEC_carrier :=
                                  fm_data.ATTCK_DEC_carrier AND $0f0+
                                  (fm_data.ATTCK_DEC_modulator AND $0f);
                              16: fm_data.SUSTN_REL_carrier :=
                                  (fm_data.SUSTN_REL_modulator SHR 4) SHL 4+
                                  fm_data.SUSTN_REL_carrier AND $0f;
                              17: fm_data.SUSTN_REL_carrier :=
                                  fm_data.SUSTN_REL_carrier AND $0f0+
                                  (fm_data.SUSTN_REL_modulator AND $0f);
                              18: fm_data.WAVEFORM_carrier :=
                                  fm_data.WAVEFORM_modulator;
                              19,
                              20: fm_data.KSL_VOLUM_carrier :=
                                  fm_data.KSL_VOLUM_carrier AND $0c0+
                                  (fm_data.KSL_VOLUM_modulator AND $3f);
                              21: fm_data.KSL_VOLUM_carrier :=
                                  fm_data.KSL_VOLUM_carrier AND $3f+
                                  (fm_data.KSL_VOLUM_modulator SHR 6) SHL 6;
                              22: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $0f0+
                                  (fm_data.AM_VIB_EG_modulator AND $0f);
                              23: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $7f+
                                  (fm_data.AM_VIB_EG_modulator SHR 7) SHL 7;
                              24: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $0bf+
                                  (fm_data.AM_VIB_EG_modulator SHR 6 AND 1) SHL 6;
                              25: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $0ef+
                                  (fm_data.AM_VIB_EG_modulator SHR 4 AND 1) SHL 4;
                              26: fm_data.AM_VIB_EG_carrier :=
                                  fm_data.AM_VIB_EG_carrier AND $0df+
                                  (fm_data.AM_VIB_EG_modulator SHR 5 AND 1) SHL 5;
                             end;

               kCtrlE: begin
                         If (songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM OR MACRO_ENVELOPE_RESTART_FLAG <>
                             songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM) then
                           songdata.instr_macros[instr].data[fmreg_page].fm_data.
                             FEEDBACK_FM :=
                             songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM AND $1f + MACRO_ENVELOPE_RESTART_FLAG
                         else
                           songdata.instr_macros[instr].data[fmreg_page].fm_data.
                             FEEDBACK_FM :=
                             songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM AND $1f;
                         If (fmreg_page < 255) then Inc(fmreg_page)
                         else If cycle_pattern then fmreg_page := 1;
                       end;

               kCtrlN: begin
                         If (songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM OR MACRO_NOTE_RETRIG_FLAG <>
                             songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM) then
                           songdata.instr_macros[instr].data[fmreg_page].fm_data.
                             FEEDBACK_FM :=
                             songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM AND $1f + MACRO_NOTE_RETRIG_FLAG
                         else
                           songdata.instr_macros[instr].data[fmreg_page].fm_data.
                             FEEDBACK_FM :=
                             songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM AND $1f;
                         If (fmreg_page < 255) then Inc(fmreg_page)
                         else If cycle_pattern then fmreg_page := 1;
                       end;

               kCtrlZ: begin
                         If (songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM OR MACRO_ZERO_FREQ_FLAG <>
                             songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM) then
                           songdata.instr_macros[instr].data[fmreg_page].fm_data.
                             FEEDBACK_FM :=
                             songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM AND $1f + MACRO_ZERO_FREQ_FLAG
                         else
                           songdata.instr_macros[instr].data[fmreg_page].fm_data.
                             FEEDBACK_FM :=
                             songdata.instr_macros[instr].data[fmreg_page].fm_data.
                               FEEDBACK_FM AND $1f;
                         If (fmreg_page < 255) then Inc(fmreg_page)
                         else If cycle_pattern then fmreg_page := 1;
                       end;

               kAltE:  If ctrl_pressed then
                         For temp := 1 to 255 do
                           If (songdata.instr_macros[instr].data[temp].fm_data.
                                 FEEDBACK_FM OR MACRO_ENVELOPE_RESTART_FLAG =
                               songdata.instr_macros[instr].data[temp].fm_data.
                                 FEEDBACK_FM) then
                             songdata.instr_macros[instr].data[temp].fm_data.
                               FEEDBACK_FM :=
                               songdata.instr_macros[instr].data[temp].fm_data.
                                 FEEDBACK_FM AND $1f;

               kAltN:  If ctrl_pressed then
                         For temp := 1 to 255 do
                           If (songdata.instr_macros[instr].data[temp].fm_data.
                                 FEEDBACK_FM OR MACRO_NOTE_RETRIG_FLAG =
                               songdata.instr_macros[instr].data[temp].fm_data.
                                 FEEDBACK_FM) then
                             songdata.instr_macros[instr].data[temp].fm_data.
                               FEEDBACK_FM :=
                               songdata.instr_macros[instr].data[temp].fm_data.
                                 FEEDBACK_FM AND $1f;

              kAltZ:  If ctrl_pressed then
                         For temp := 1 to 255 do
                           If (songdata.instr_macros[instr].data[temp].fm_data.
                                 FEEDBACK_FM OR MACRO_ZERO_FREQ_FLAG =
                               songdata.instr_macros[instr].data[temp].fm_data.
                                 FEEDBACK_FM) then
                             songdata.instr_macros[instr].data[temp].fm_data.
                               FEEDBACK_FM :=
                               songdata.instr_macros[instr].data[temp].fm_data.
                                 FEEDBACK_FM AND $1f;

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
               kCHplus,
               kNPplus: With songdata.instr_macros[instr].data[fmreg_page] do
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
               kCHmins,
               kNPmins: With songdata.instr_macros[instr].data[fmreg_page] do
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

               kAstrsk,
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
                (fmreg_hpos = 29) then
               With songdata.instr_macros[instr].data[fmreg_page] do
                 begin
                   Case UpCase(CHAR(LO(is_environment.keystroke))) of
                     '+': freq_slide := Abs(freq_slide);
                     '-': freq_slide := -Abs(freq_slide);
                   end;

                   If (fmreg_page < 255) then Inc(fmreg_page)
                   else If cycle_pattern then fmreg_page := 1;
                 end;

             If shift_pressed and ((is_environment.keystroke = kUP) or (is_environment.keystroke = kDOWN)) then
               begin
                 If (ptr_arpeggio_table <> 0) then
                   arpeggio_page := fmreg_page;
                 If (ptr_vibrato_table <> 0) then
                   vibrato_page := fmreg_page;
               end;
           end;

    (* Arpeggio table - pos: 8..13 *)

        8: begin
             is_setting.character_set := ['0'..'9','a'..'f','A'..'F'];
             Repeat
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table].
                                          arpeggio.length),
                                 xstart+60+window_area_inc_x,ystart+4,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_arpeggio_table].
             arpeggio.length := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.length < 255) then
                          Inc(songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.length);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.length > 0) then
                          Dec(songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.length);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 9
             else If (is_environment.keystroke = kUP) then pos := 13
                  else If (is_environment.keystroke = kShTAB) then
                         If NOT arp_vib_mode then pos := 7
                         else pos := 20;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_arp_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If NOT arp_vib_mode then pos := 1
                        else pos := 14;

               kCtRGHT: If arp_vib_mode then pos := 14
                        else If (ptr_vibrato_table <> 0) then pos := 14
                             else pos := 1;

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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table].
                                          arpeggio.speed),
                                 xstart+60+window_area_inc_x,ystart+5,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_arpeggio_table].
             arpeggio.speed := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.speed < 255) then
                          Inc(songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.speed);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.speed > 0) then
                          Dec(songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.speed);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 10
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 8;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_arp_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If NOT arp_vib_mode then pos := 1
                        else pos := 15;

               kCtRGHT: If arp_vib_mode then pos := 15
                        else If (ptr_vibrato_table <> 0) then pos := 15
                             else pos := 1;

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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table].
                                          arpeggio.loop_begin),
                                 xstart+60+window_area_inc_x,ystart+6,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_arpeggio_table].
             arpeggio.loop_begin := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.loop_begin < 255) then
                          Inc(songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.loop_begin);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.loop_begin > 0) then
                          Dec(songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.loop_begin);
             end;

             While NOT ((songdata.macro_table[ptr_arpeggio_table].
                         arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table].
                                               arpeggio.loop_begin+
                                     min0(songdata.macro_table[ptr_arpeggio_table].
                                          arpeggio.loop_length-1,0)) or
                        (songdata.macro_table[ptr_arpeggio_table].
                         arpeggio.loop_begin = 0) or
                        (songdata.macro_table[ptr_arpeggio_table].
                         arpeggio.loop_length = 0) or
                        (songdata.macro_table[ptr_arpeggio_table].
                         arpeggio.keyoff_pos = 0)) do
               Inc(songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 11
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 9;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_arp_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If NOT arp_vib_mode then pos := 2
                        else pos := 17;

               kCtRGHT: If arp_vib_mode then pos := 17
                        else If (ptr_vibrato_table <> 0) then pos := 17
                             else pos := 2;

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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table].
                                          arpeggio.loop_length),
                                 xstart+60+window_area_inc_x,ystart+7,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_arpeggio_table].
             arpeggio.loop_length := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.loop_length < 255) then
                          Inc(songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.loop_length);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.loop_length > 0) then
                          Dec(songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.loop_length);
             end;

             While NOT ((songdata.macro_table[ptr_arpeggio_table].
                         arpeggio.keyoff_pos > songdata.macro_table[ptr_arpeggio_table].
                                               arpeggio.loop_begin+
                                     min0(songdata.macro_table[ptr_arpeggio_table].
                                          arpeggio.loop_length-1,0)) or
                        (songdata.macro_table[ptr_arpeggio_table].
                         arpeggio.loop_begin = 0) or
                        (songdata.macro_table[ptr_arpeggio_table].
                         arpeggio.loop_length = 0) or
                        (songdata.macro_table[ptr_arpeggio_table].
                         arpeggio.keyoff_pos = 0)) do
               Inc(songdata.macro_table[ptr_arpeggio_table].
                   arpeggio.keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 12
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 10;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_arp_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If NOT arp_vib_mode then pos := 3
                        else pos := 18;

               kCtRGHT: If arp_vib_mode then pos := 18
                        else If (ptr_vibrato_table <> 0) then pos := 18
                             else pos := 3;

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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_arpeggio_table].
                                           arpeggio.keyoff_pos),
                                 xstart+60+window_area_inc_x,ystart+8,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   (Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255) and
                   (Str2num(temps,16) > songdata.macro_table[ptr_arpeggio_table].
                                        arpeggio.loop_begin+
                                        min0(songdata.macro_table[ptr_arpeggio_table].
                                             arpeggio.loop_length-1,0)) or
                   (songdata.macro_table[ptr_arpeggio_table].
                    arpeggio.loop_begin = 0) or
                   (songdata.macro_table[ptr_arpeggio_table].
                    arpeggio.loop_length = 0) or
                   (Str2num(temps,16) = 0);

             songdata.macro_table[ptr_arpeggio_table].
             arpeggio.keyoff_pos := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.loop_begin = 0) or
                           (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.loop_length = 0) or
                           (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.keyoff_pos <> 0) then
                          If (songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.keyoff_pos < 255) then
                            Inc(songdata.macro_table[ptr_arpeggio_table].
                                arpeggio.keyoff_pos)
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table].
                                 arpeggio.loop_begin+
                                 songdata.macro_table[ptr_arpeggio_table].
                                 arpeggio.loop_length <= 255) then
                               songdata.macro_table[ptr_arpeggio_table].
                               arpeggio.keyoff_pos :=
                                 songdata.macro_table[ptr_arpeggio_table].
                                 arpeggio.loop_begin+
                                 songdata.macro_table[ptr_arpeggio_table].
                                 arpeggio.loop_length;
               kCHmins,
               kNPmins: If (min0(songdata.macro_table[ptr_arpeggio_table].
                                 arpeggio.keyoff_pos-1,0) > songdata.macro_table[ptr_arpeggio_table].
                                                            arpeggio.loop_begin+
                              min0(songdata.macro_table[ptr_arpeggio_table].
                                   arpeggio.loop_length-1,0)) or
                           ((songdata.macro_table[ptr_arpeggio_table].
                             arpeggio.keyoff_pos > 0) and
                           ((songdata.macro_table[ptr_arpeggio_table].
                             arpeggio.loop_begin = 0) or
                            (songdata.macro_table[ptr_arpeggio_table].
                             arpeggio.loop_length = 0))) then
                          Dec(songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.keyoff_pos);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 13
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 11;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_arp_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If NOT arp_vib_mode then pos := 4
                        else pos := 19;

               kCtRGHT: If arp_vib_mode then pos := 19
                        else If (ptr_vibrato_table <> 0) then pos := 19
                             else pos := 4;

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
             If _check_macro_speed_change then GOTO _jmp2;
             _check_arp_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If NOT shift_pressed then
                          If NOT arp_vib_mode then pos := 7
                          else pos := 20
                        else If (arpeggio_page > songdata.macro_table[ptr_arpeggio_table].arpeggio.length) then
                               arpeggio_page := min(1,songdata.macro_table[ptr_arpeggio_table].arpeggio.length)
                             else arpeggio_page := 1;

               kCtRGHT: If NOT shift_pressed then
                          If NOT arp_vib_mode then
                            If (ptr_vibrato_table <> 0) then pos := 20
                            else pos := 7
                          else pos := 20
                        else If (arpeggio_page < songdata.macro_table[ptr_arpeggio_table].arpeggio.length) then
                               arpeggio_page := min(1,songdata.macro_table[ptr_arpeggio_table].arpeggio.length)
                             else arpeggio_page := 255;

               kUP: If (arpeggio_page > 1) then Dec(arpeggio_page)
                    else If cycle_pattern then arpeggio_page := 255;

               kDOWN: If (arpeggio_page < 255) then Inc(arpeggio_page)
                      else If cycle_pattern then arpeggio_page := 1;

               kPgUP: If (arpeggio_page > 16) then Dec(arpeggio_page,16)
                      else arpeggio_page := 1;

               kPgDOWN: If (arpeggio_page+16 < 255) then Inc(arpeggio_page,16)
                        else arpeggio_page := 255;

               kHOME: arpeggio_page := 1;

               kEND: arpeggio_page := 255;

               kENTER,kTAB: If NOT arp_vib_mode then
                              If (ptr_vibrato_table <> 0) then pos := 14
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

               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.data[arpeggio_page] < $80) then
                          If (songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.data[arpeggio_page] < 96) then
                            Inc(songdata.macro_table[ptr_arpeggio_table].
                                arpeggio.data[arpeggio_page])
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table].
                                 arpeggio.data[arpeggio_page] < $80+96+1) then
                               Inc(songdata.macro_table[ptr_arpeggio_table].
                                   arpeggio.data[arpeggio_page]);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_arpeggio_table].
                            arpeggio.data[arpeggio_page] < $80) then
                          If (songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.data[arpeggio_page] > 1) then
                            Dec(songdata.macro_table[ptr_arpeggio_table].
                                arpeggio.data[arpeggio_page])
                          else
                        else If (songdata.macro_table[ptr_arpeggio_table].
                                 arpeggio.data[arpeggio_page] > $80+1) then
                               Dec(songdata.macro_table[ptr_arpeggio_table].
                                   arpeggio.data[arpeggio_page]);

               kBkSPC: begin
                         songdata.macro_table[ptr_arpeggio_table].
                         arpeggio.data[arpeggio_page] := 0;
                         If (arpeggio_page < 255) then Inc(arpeggio_page)
                         else If cycle_pattern then arpeggio_page := 1;
                       end;

               kINSERT: begin
                          For temp := 255-1 downto arpeggio_page do
                            begin
                              songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.data[SUCC(temp)] :=
                                songdata.macro_table[ptr_arpeggio_table].
                                arpeggio.data[temp]
                            end;
                          FillChar(songdata.macro_table[ptr_arpeggio_table].
                                   arpeggio.data[arpeggio_page],
                                   SizeOf(songdata.macro_table[ptr_arpeggio_table].
                                          arpeggio.data[arpeggio_page]),0);
                        end;

               kDELETE: begin
                          For temp := arpeggio_page to 255-1 do
                            begin
                              songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.data[temp] :=
                                songdata.macro_table[ptr_arpeggio_table].
                                arpeggio.data[SUCC(temp)]
                            end;
                          FillChar(songdata.macro_table[ptr_arpeggio_table].
                                   arpeggio.data[255],
                                   SizeOf(songdata.macro_table[ptr_arpeggio_table].
                                          arpeggio.data[255]),0);
                        end;
             end;

             If shift_pressed and ((is_environment.keystroke = kUP) or (is_environment.keystroke = kDOWN)) then
               begin
                 fmreg_page := arpeggio_page;
                 If (ptr_vibrato_table <> 0) then
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
                           songdata.macro_table[ptr_arpeggio_table].
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
                                    songdata.macro_table[ptr_arpeggio_table].
                                    arpeggio.data[arpeggio_page] := $80+temp1;
                                    BREAK;
                                  end;

                              If NOT nope and (Length(tstr) = 2) then
                                For temp1 := 1 to 12*8+1 do
                                  If (Copy(Upper(tstr),1,2) = Copy(note_layout[temp1],1,2)) then
                                    begin
                                      nope := TRUE;
                                      songdata.macro_table[ptr_arpeggio_table].
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
                                Case songdata.macro_table[ptr_arpeggio_table].
                                     arpeggio.data[arpeggio_page] of
                                  0: tstr := '+0';
                                  1..96: tstr := '+'+Num2str(songdata.macro_table[ptr_arpeggio_table].
                                                             arpeggio.data[arpeggio_page],10);
                                  $80..$80+12*8+1:
                                     tstr := note_layout[songdata.macro_table[ptr_arpeggio_table].
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
                   kTAB: If (ptr_vibrato_table <> 0) then pos := 14
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
                           songdata.macro_table[ptr_arpeggio_table].
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
                         Case songdata.macro_table[ptr_arpeggio_table].
                              arpeggio.data[arpeggio_page] of
                           0: tstr := '+0';
                           1..96: tstr := '+'+Num2str(songdata.macro_table[ptr_arpeggio_table].
                                                      arpeggio.data[arpeggio_page],10);
                           $80..$80+12*8+1:
                              tstr := note_layout[songdata.macro_table[ptr_arpeggio_table].
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
                           If (ptr_vibrato_table <> 0) then pos := 14
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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.length),
                                 xstart+77+window_area_inc_x,ystart+4,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table].
                      vibrato.length := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.length < 255) then
                          Inc(songdata.macro_table[ptr_vibrato_table].
                              vibrato.length);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.length > 0) then
                          Dec(songdata.macro_table[ptr_vibrato_table].
                              vibrato.length);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 15
             else If (is_environment.keystroke = kUP) then pos := 20
                  else If (is_environment.keystroke = kShTAB) then
                         If NOT arp_vib_mode then
                           If (ptr_arpeggio_table <> 0) then pos := 13
                           else pos := 7
                         else pos := 13;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_vib_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If arp_vib_mode then pos := 8
                        else If (ptr_arpeggio_table <> 0) then pos := 8
                             else pos := 1;

               kCtRGHT: If arp_vib_mode then pos := 8
                        else pos := 1;

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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.speed),
                                 xstart+77+window_area_inc_x,ystart+5,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table].
                      vibrato.speed := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.speed < 255) then
                          Inc(songdata.macro_table[ptr_vibrato_table].
                              vibrato.speed);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.speed > 0) then
                          Dec(songdata.macro_table[ptr_vibrato_table].
                              vibrato.speed);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 16
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 14;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_vib_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If arp_vib_mode then pos := 9
                        else If (ptr_arpeggio_table <> 0) then pos := 9
                             else pos := 1;

               kCtRGHT: If arp_vib_mode then pos := 9
                        else pos := 1;

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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.delay),
                                 xstart+77+window_area_inc_x,ystart+6,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table].
                      vibrato.delay := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.delay < 255) then
                          Inc(songdata.macro_table[ptr_vibrato_table].
                              vibrato.delay);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.delay > 0) then
                          Dec(songdata.macro_table[ptr_vibrato_table].
                              vibrato.delay);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 17
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 15;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_vib_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If arp_vib_mode then pos := 8
                        else If (ptr_arpeggio_table <> 0) then pos := 8
                             else pos := 1;

               kCtRGHT: If arp_vib_mode then pos := 8
                        else pos := 1;

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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.loop_begin),
                                 xstart+77+window_area_inc_x,ystart+7,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table].
                      vibrato.loop_begin := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.loop_begin < 255) then
                          Inc(songdata.macro_table[ptr_vibrato_table].
                              vibrato.loop_begin);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.loop_begin > 0) then
                          Dec(songdata.macro_table[ptr_vibrato_table].
                              vibrato.loop_begin);
             end;

             While NOT ((songdata.macro_table[ptr_vibrato_table].
                         vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table].
                                              vibrato.loop_begin+
                                     min0(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.loop_length-1,0)) or
                        (songdata.macro_table[ptr_vibrato_table].
                         vibrato.loop_begin = 0) or
                        (songdata.macro_table[ptr_vibrato_table].
                         vibrato.loop_length = 0) or
                        (songdata.macro_table[ptr_vibrato_table].
                         vibrato.keyoff_pos = 0)) do
               Inc(songdata.macro_table[ptr_vibrato_table].
                   vibrato.keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 18
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 16;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_vib_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If arp_vib_mode then pos := 10
                        else If (ptr_arpeggio_table <> 0) then pos := 10
                             else pos := 2;

               kCtRGHT: If arp_vib_mode then pos := 10
                        else pos := 2;

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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.loop_length),
                                 xstart+77+window_area_inc_x,ystart+8,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   ((Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255));

             songdata.macro_table[ptr_vibrato_table].
                      vibrato.loop_length := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.loop_length < 255) then
                          Inc(songdata.macro_table[ptr_vibrato_table].
                              vibrato.loop_length);
               kCHmins,
               kNPmins: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.loop_length > 0) then
                          Dec(songdata.macro_table[ptr_vibrato_table].
                              vibrato.loop_length);
             end;

             While NOT ((songdata.macro_table[ptr_vibrato_table].
                         vibrato.keyoff_pos > songdata.macro_table[ptr_vibrato_table].
                                              vibrato.loop_begin+
                                     min0(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.loop_length-1,0)) or
                        (songdata.macro_table[ptr_vibrato_table].
                         vibrato.loop_begin = 0) or
                        (songdata.macro_table[ptr_vibrato_table].
                         vibrato.loop_length = 0) or
                        (songdata.macro_table[ptr_vibrato_table].
                         vibrato.keyoff_pos = 0)) do
               Inc(songdata.macro_table[ptr_vibrato_table].
                   vibrato.keyoff_pos);

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 19
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 17;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_vib_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If arp_vib_mode then pos := 11
                        else If (ptr_arpeggio_table <> 0) then pos := 11
                             else pos := 3;

               kCtRGHT: If arp_vib_mode then pos := 11
                        else pos := 3;

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
               temps := InputStr(byte2hex(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.keyoff_pos),
                                 xstart+77+window_area_inc_x,ystart+9,
                                 2,2,
                                 macro_input_bckg+macro_input,
                                 macro_def_bckg+macro_def);
             until (is_environment.keystroke = kESC) or
                   (Str2num(temps,16) >= 0) and (Str2num(temps,16) <= 255) and
                   (Str2num(temps,16) > songdata.macro_table[ptr_vibrato_table].
                                        vibrato.loop_begin+
                                        min0(songdata.macro_table[ptr_vibrato_table].
                                             vibrato.loop_length-1,0)) or
                   (songdata.macro_table[ptr_vibrato_table].
                    vibrato.loop_begin = 0) or
                   (songdata.macro_table[ptr_vibrato_table].
                    vibrato.loop_length = 0) or
                   (Str2num(temps,16) = 0);

             songdata.macro_table[ptr_vibrato_table].
                      vibrato.keyoff_pos := Str2num(temps,16);
             Case is_environment.keystroke of
               kCHplus,
               kNPplus: If (songdata.macro_table[ptr_vibrato_table].
                            vibrato.loop_begin = 0) or
                           (songdata.macro_table[ptr_vibrato_table].
                            vibrato.loop_length = 0) or
                           (songdata.macro_table[ptr_vibrato_table].
                            vibrato.keyoff_pos <> 0) then
                          If (songdata.macro_table[ptr_vibrato_table].
                              vibrato.keyoff_pos < 255) then
                            Inc(songdata.macro_table[ptr_vibrato_table].
                                vibrato.keyoff_pos)
                          else
                        else If (songdata.macro_table[ptr_vibrato_table].
                                 vibrato.loop_begin+
                                 songdata.macro_table[ptr_vibrato_table].
                                 vibrato.loop_length <= 255) then
                               songdata.macro_table[ptr_vibrato_table].
                               vibrato.keyoff_pos :=
                                 songdata.macro_table[ptr_vibrato_table].
                                 vibrato.loop_begin+
                                 songdata.macro_table[ptr_vibrato_table].
                                 vibrato.loop_length;
               kCHmins,
               kNPmins: If (min0(songdata.macro_table[ptr_vibrato_table].
                                 vibrato.keyoff_pos-1,0) > songdata.macro_table[ptr_vibrato_table].
                                                           vibrato.loop_begin+
                              min0(songdata.macro_table[ptr_vibrato_table].
                                   vibrato.loop_length-1,0)) or
                           ((songdata.macro_table[ptr_vibrato_table].
                             vibrato.keyoff_pos > 0) and
                           ((songdata.macro_table[ptr_vibrato_table].
                             vibrato.loop_begin = 0) or
                            (songdata.macro_table[ptr_vibrato_table].
                             vibrato.loop_length = 0))) then
                          Dec(songdata.macro_table[ptr_vibrato_table].
                              vibrato.keyoff_pos);
             end;

             If (is_environment.keystroke = kENTER) or
                (is_environment.keystroke = kTAB) or
                (is_environment.keystroke = kDOWN) then pos := 20
             else If (is_environment.keystroke = kUP) or
                     (is_environment.keystroke = kShTAB) then pos := 18;

             If _check_macro_speed_change then GOTO _jmp2;
             _check_vib_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If arp_vib_mode then pos := 12
                        else If (ptr_arpeggio_table <> 0) then pos := 12
                             else pos := 4;

               kCtRGHT: If arp_vib_mode then pos := 12
                        else pos := 4;

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
             If _check_macro_speed_change then GOTO _jmp2;
             _check_vib_general_keys;

             Case is_environment.keystroke of
               kCtLEFT: If NOT shift_pressed then
                          If NOT arp_vib_mode then
                            If (ptr_arpeggio_table <> 0) then pos := 13
                            else pos := 7
                          else pos := 13
                        else If (vibrato_page > songdata.macro_table[ptr_vibrato_table].vibrato.length) then
                               vibrato_page := min(1,songdata.macro_table[ptr_vibrato_table].vibrato.length)
                             else vibrato_page := 1;

               kCtRGHT: If NOT shift_pressed then
                          If NOT arp_vib_mode then pos := 7
                          else pos := 13
                        else If (vibrato_page < songdata.macro_table[ptr_vibrato_table].vibrato.length) then
                               vibrato_page := min(1,songdata.macro_table[ptr_vibrato_table].vibrato.length)
                             else vibrato_page := 255;

               kUP: If (vibrato_page > 1) then Dec(vibrato_page)
                    else If cycle_pattern then vibrato_page := 255;

               kDOWN: If (vibrato_page < 255) then Inc(vibrato_page)
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

               kBkSPC: begin
                         songdata.macro_table[ptr_vibrato_table].
                         vibrato.data[vibrato_page] := 0;
                         If (vibrato_page < 255) then Inc(vibrato_page)
                         else If cycle_pattern then vibrato_page := 1;
                       end;

               kINSERT: begin
                          For temp := 255-1 downto vibrato_page do
                            begin
                              songdata.macro_table[ptr_vibrato_table].
                              vibrato.data[SUCC(temp)] :=
                                songdata.macro_table[ptr_vibrato_table].
                                vibrato.data[temp]
                            end;
                          FillChar(songdata.macro_table[ptr_vibrato_table].
                                   vibrato.data[vibrato_page],
                                   SizeOf(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.data[vibrato_page]),0);
                        end;

               kDELETE: begin
                          For temp := vibrato_page to 255-1 do
                            begin
                              songdata.macro_table[ptr_vibrato_table].
                              vibrato.data[temp] :=
                                songdata.macro_table[ptr_vibrato_table].
                                vibrato.data[SUCC(temp)]
                            end;
                          FillChar(songdata.macro_table[ptr_vibrato_table].
                                   vibrato.data[255],
                                   SizeOf(songdata.macro_table[ptr_vibrato_table].
                                          vibrato.data[255]),0);
                        end;
             end;

             If shift_pressed and ((is_environment.keystroke = kUP) or (is_environment.keystroke = kDOWN)) then
               begin
                 fmreg_page := vibrato_page;
                 If (ptr_arpeggio_table <> 0) then
                   arpeggio_page := vibrato_page;
               end;

             If (UpCase(CHAR(LO(is_environment.keystroke))) in ['0'..'9','A'..'F','+','-']) then
               With songdata.macro_table[ptr_vibrato_table].vibrato do
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

                          '+': begin
                                 If (data[vibrato_page] < $7f) then Inc(data[vibrato_page]);
                                 nope := FALSE;
                               end;
                          '-': begin
                                 If (data[vibrato_page] > -$7f) then Dec(data[vibrato_page]);
                                 nope := FALSE;
                               end;
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
                          '+': begin
                                 If (data[vibrato_page] < $7f) then Inc(data[vibrato_page]);
                                 nope := FALSE;
                               end;
                          '-': begin
                                 If (data[vibrato_page] > -$7f) then Dec(data[vibrato_page]);
                                 nope := FALSE;
                               end;
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
          refresh(0);
          HideCursor;
          _pip_dest := screen_ptr;
          If (get_4op_to_test <> 0) then _macro_preview_init(1,BYTE(NOT BYTE_NULL))
          else _macro_preview_init(1,BYTE_NULL);

          If ctrl_pressed and (is_environment.keystroke = kSPACE) then
            begin
              _pip_loop := TRUE;
              For temp := 1 to 20 do keyoff_loop[temp] := _pip_loop;
            end
          else For temp := 1 to 20 do keyoff_loop[temp] := _pip_loop;

          macro_preview_indic_proc := _preview_indic_proc;
          is_environment.keystroke := WORD_NULL;

          If NOT _force_program_quit then
            Repeat
              // update octave
              For temp := 1 to 8 do
                If (temp <> current_octave) then
                  show_str(30+temp,30,CHR(48+temp),
                           main_background+main_stat_line)
                else show_str(30+temp,30,CHR(48+temp),
                              main_background+main_hi_stat_line);

              If keypressed then
                begin
                  is_environment.keystroke := getkey;
                  Case is_environment.keystroke of
                    kF7: For temp := 1 to 20 do reset_chan_data(temp);

                    kCtLbr:  If shift_pressed then
                               begin
                                 If (songdata.macro_speedup > 1) then
                                   Dec(songdata.macro_speedup);
                                 macro_speedup := songdata.macro_speedup;
                                 reset_player;
                               end
                             else If (current_inst > 1) then
                                    begin
                                      Dec(current_inst);
                                      If NOT (marked_instruments = 2) then reset_marked_instruments;
                                      instrum_page := current_inst;
                                      FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
                                      STATUS_LINE_refresh;
                                      reset_player;
                                    end;

                    kCtRbr:  If shift_pressed then
                               begin
                                 Inc(songdata.macro_speedup);
                                 If (calc_max_speedup(songdata.tempo) < songdata.macro_speedup) then
                                   songdata.macro_speedup := calc_max_speedup(songdata.tempo);
                                 macro_speedup := songdata.macro_speedup;
                                 reset_player;
                               end
                             else If (current_inst < 255) then
                                    begin
                                      Inc(current_inst);
                                      If NOT (marked_instruments = 2) then reset_marked_instruments;
                                      instrum_page := current_inst;
                                      FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
                                      STATUS_LINE_refresh;
                                      reset_player;
                                    end;

                    kAlt0:   FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
                    kAlt1:   If shift_pressed then
                               _set_operator_flag(1,TRUE)
                             else _set_operator_flag(1,FALSE);
                    kAlt2:   If shift_pressed then
                               _set_operator_flag(2,TRUE)
                             else _set_operator_flag(2,FALSE);
                    kAlt3:   If shift_pressed then
                               _set_operator_flag(3,TRUE)
                             else _set_operator_flag(3,FALSE);
                    kAlt4:   If shift_pressed then
                               _set_operator_flag(4,TRUE)
                             else _set_operator_flag(4,FALSE);
                  end;

                  If (is_environment.keystroke = kCtLbr) or (is_environment.keystroke = kCtRbr) or
                     (is_environment.keystroke = kAlt0)  or (is_environment.keystroke = kAlt1)  or
                     (is_environment.keystroke = kAlt2)  or (is_environment.keystroke = kAlt3)  or
                     (is_environment.keystroke = kAlt4) then
                    begin
                      keyboard_reset_buffer;
                      If NOT arp_vib_mode then
                        begin
                          songdata.instr_macros[instr].arpeggio_table := ptr_arpeggio_table;
                          songdata.instr_macros[instr].vibrato_table := ptr_vibrato_table;
                        end;

                      If (get_4op_to_test <> 0) then _macro_preview_init(0,BYTE(NOT BYTE_NULL))
                      else _macro_preview_init(0,BYTE_NULL);
                      instr := current_inst;

                      If NOT arp_vib_mode then
                        begin
                          ptr_arpeggio_table := songdata.instr_macros[instr].arpeggio_table;
                          ptr_vibrato_table := songdata.instr_macros[instr].vibrato_table;
                        end;

                      If arp_vib_mode and (pos < 8) then pos := 8
                      else If NOT arp_vib_mode and
                              (((ptr_arpeggio_table = 0) and (pos in [8..13])) or
                               ((ptr_vibrato_table = 0) and (pos in [14..20]))) then
                              pos := 1;

                      If NOT arp_vib_mode then
                        ShowStr(centered_frame_vdest,xstart+54+(window_area_inc_x DIV 2),ystart,
                                byte2hex(instr),macro_background+dialog_title)
                      else
                        ShowStr(centered_frame_vdest,xstart+57+(window_area_inc_x DIV 2),ystart,
                                byte2hex(instr),macro_background+dialog_title);

                      refresh(flag_FMREG+flag_ARPEGGIO+flag_VIBRATO);
                      If (get_4op_to_test <> 0) then _macro_preview_init(1,BYTE(NOT BYTE_NULL))
                      else _macro_preview_init(1,BYTE_NULL);
                    end;

                  If (get_4op_to_test <> 0) then
                    _macro_preview_body(LO(get_4op_to_test),HI(get_4op_to_test),count_channel(pattern_hpos),is_environment.keystroke)
                  else _macro_preview_body(instrum_page,BYTE_NULL,count_channel(pattern_hpos),is_environment.keystroke);

                  If ctrl_pressed and NOT shift_pressed and
                     (is_environment.keystroke = kSPACE) then
                    begin
                      _pip_loop := NOT _pip_loop;
                      For temp := 1 to 20 do keyoff_loop[temp] := _pip_loop;
                      is_environment.keystroke := WORD_NULL;
                    end;

                  If shift_pressed and (is_environment.keystroke = kSPACE) then
                    is_environment.keystroke := WORD_NULL;
                end
              else If NOT (seconds_counter >= ssaver_time) then GOTO _end2 //CONTINUE
                   else begin
                          screen_saver;
                          GOTO _end2; //CONTINUE;
                        end;
_end2:
{$IFDEF GO32V2}
              keyboard_reset_buffer_alt;
{$ELSE}
              draw_screen;
{$ENDIF}
            until (is_environment.keystroke = kSPACE) or
                  (is_environment.keystroke = kESC);

            If (get_4op_to_test <> 0) then _macro_preview_init(0,BYTE(NOT BYTE_NULL))
            else _macro_preview_init(0,BYTE_NULL);
            macro_preview_indic_proc := NIL;
            _pip_dest := ptr_temp_screen;
            ThinCursor;
          end;
{$IFDEF GO32V2}
       keyboard_reset_buffer_alt;
{$ELSE}
       draw_screen;
{$ENDIF}
      until (is_environment.keystroke = kESC)    or
            (is_environment.keystroke = kCtrlO)  or
            (is_environment.keystroke = kF1)     or
            (is_environment.keystroke = kF2)     or
            (is_environment.keystroke = kCtrlF2) or
            (is_environment.keystroke = kF3)     or
            (is_environment.keystroke = kCtrlL)  or
            (is_environment.keystroke = kCtrlS)  or
            (is_environment.keystroke = kCtrlM)  or
            (NOT ctrl_pressed and (is_environment.keystroke = kAltC)) or
            call_pickup_proc or
            call_pickup_proc2;

  FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
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
      songdata.instr_macros[instr].arpeggio_table := ptr_arpeggio_table;
      songdata.instr_macros[instr].vibrato_table := ptr_vibrato_table;
    end
  else begin
         If shift_pressed then
           begin
             songdata.instr_macros[current_inst].arpeggio_table := ptr_arpeggio_table;
             songdata.instr_macros[current_inst].vibrato_table := ptr_vibrato_table;
           end;
         arpvib_arpeggio_table := ptr_arpeggio_table;
         arpvib_vibrato_table := ptr_vibrato_table;
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
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+81+2+window_area_inc_x;
  move_to_screen_area[4] := ystart+24+1+window_area_inc_x;
  move2screen;

  Case is_environment.keystroke of
    kAltC:   If NOT ctrl_pressed then
                   begin
                 If (pos in [7,13,20]) then
                   begin
                     copy_menu_str4[13] := copy_macro_str[2];
                     copy_menu_str4[14] := copy_macro_str[4];
                   end
                 else begin
                        copy_menu_str4[13] := copy_macro_str[1];
                        copy_menu_str4[14] := copy_macro_str[3];
                      end;

                 mn_setting.cycle_moves := TRUE;
                 temp := Menu(copy_menu_str4,01,01,copypos4,30,15,15,' COPY OBJECT ');
                 copy_menu_str4[13] := copy_macro_str[2];
                 copy_menu_str4[14] := copy_macro_str[4];
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
                 temp := INSTRUMENT_CONTROL_alt(_source_ins2,'FM-REGiSTER MACRO: PASTE DATA TO iNSTRUMENT');
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
                 temp := INSTRUMENT_CONTROL_alt(_source_ins,'FM-REGiSTER MACRO: PASTE DATA FROM iNSTRUMENT');
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
                       arpvib_arpeggio_table := ptr_arpeggio_table;
                       arpvib_vibrato_table := ptr_vibrato_table;
                     end;
                 end
               else begin
                      arp_tab_selected := ptr_arpeggio_table <> 0;
                      vib_tab_selected := ptr_vibrato_table <> 0;
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT4.PAS:MACRO_BROWSER';
{$ENDIF}
  songdata_crc := Update32(songdata,SizeOf(songdata),0);
  a2w_file_loader(FALSE,NOT instrBrowser,TRUE,FALSE,updateCurInstr); // browse internal A2W data
  If (Update32(songdata,SizeOf(songdata),0) <> songdata_crc) then
    module_archived := FALSE;
end;

end.
