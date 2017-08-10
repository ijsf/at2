{
    procedure reset_instrument_preview;
    procedure INSTRUMENT_test(instr,instr2: Byte; chan: Byte; fkey: Word; process_macros: Boolean);
    function  _1st_marked: Byte;
    function  _2nd_marked: Byte;
    function  marked_instruments: Byte;
    procedure reset_marked_instruments;
    function  get_4op_to_test: Word;
    function  check_4op_to_test: Word;
    function  check_4op_instrument(ins: Byte): Word;
    function  check_4op_flag(ins: Byte): Boolean;
    procedure reset_4op_flag(ins: Byte);
    procedure set_4op_flag(ins: Byte);
    procedure update_4op_flag_marks;
    procedure INSTRUMENT_CONTROL_page_refresh(page: Byte);
    procedure _show_adsr(var dest; xstart,ystart: Byte;
                         attack,decay,sustain,release,attenuation: Byte;
                         eg_type: Byte;
                         attr,attr_hi: Byte;
                         reset: Boolean);
    procedure INSTRUMENT_CONTROL_page_refresh_alt(page: Byte);
    function  _4op_conn_to_idx(str: String): Byte;
    procedure _show_conn_scheme(xstart,ystart,conn: Byte; hi_op: tSET_OF_CHARS);
    function  _get_feedback_val: Byte;
    procedure _inc_feedback_val;
    procedure _dec_feedback_val;
    function  _get_finetune_val: Shortint;
    procedure _inc_finetune_val;
    procedure _dec_finetune_val;
    procedure _page_build;
    procedure _page_refresh;
    procedure _sync_radio_buttons;
    procedure INSTRUMENT_CONTROL_edit;
    procedure copy_object;
    procedure paste_object(mode: Byte);
    procedure instr_control_ai;
    procedure instr_control_proc;
    function  INSTRUMENT_CONTROL: Byte;
    procedure instr_control_proc_alt;
    function  INSTRUMENT_CONTROL_alt(instr: Byte; title: String): Byte;
}

const
  _ADSR_preview_flag: Boolean = TRUE;

const
  _operator_enabled: array[1..4] of Boolean = (TRUE,TRUE,TRUE,TRUE);
  _carrier_flag: array[BOOLEAN] of Byte = (2,1);
  _ins_mark_chr = #16;
  _4op_flag_chr_beg = #172;
  _4op_flag_chr_end = #173;
  _4op_flag_chars: Set of Char = [_4op_flag_chr_beg,_4op_flag_chr_end];
  _4op_connection_str: array[0..3] of String[5] = (
    'FM/FM','FM/AM','AM/FM','AM/AM');

procedure reset_instrument_preview;

var
  temp: Word;

begin
  If (play_status <> isPlaying) then reset_player;
  temp := check_4op_to_test;
  If NOT (temp <> 0) then
    update_instr_data(instrum_page)
  else begin
         update_instr_data(LO(temp));
         update_instr_data(HI(temp));
       end;
end;

procedure INSTRUMENT_test(instr,instr2: Byte; chan: Byte; fkey: Word; process_macros: Boolean);

var
  temp,temp2,temp3,temp5: Byte;
  valid_key,temp4: Boolean;
  chan_handle: array[1..20] of Byte;
  channels: Byte;
  _1op_preview,_4op_mode: Boolean;

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

function output_note(chan,board_pos: Byte): Boolean;

var
  note: Byte;
  freq: Word;
  ins: tADTRACK2_INS;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_test:output_note';
{$ENDIF}
  note := board_pos+12*(current_octave-1);
  If NOT (note in [0..12*8+1]) then
    begin
      output_note := FALSE;
      EXIT;
    end;

  chan_handle[chan] := board_scancodes[board_pos];
  If _4op_mode then
    chan := _4op_main_chan[chan];

  If _1op_preview then
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

  macro_speedup := songdata.macro_speedup;
  If (play_status = isStopped) then update_timer(songdata.tempo);

  freq := nFreq(note-1)+$2000+
          SHORTINT(pBYTE(@Addr(songdata.instr_data[instr])^)[12]);
  event_table[chan].note := note;
  freq_table[chan] := freq;
  freqtable2[chan] := freq;
  key_on(chan);
  change_freq(chan,freq);

  If process_macros then
    If NOT (_1op_preview and (_operator_enabled[3] or _operator_enabled[4])) then
      init_macro_table(chan,note,instr,freq)
    else init_macro_table(chan,note,instr2,freq)
  else begin
         macro_table[chan].fmreg_table := 0;
         macro_table[chan].arpg_table := 0;
         macro_table[chan].vib_table := 0;
       end;

  If _4op_mode and NOT _1op_preview then
    begin
      If process_macros then init_macro_table(PRED(chan),note,instr2,freq)
      else begin
             macro_table[PRED(chan)].fmreg_table := 0;
             macro_table[PRED(chan)].arpg_table := 0;
             macro_table[PRED(chan)].vib_table := 0;
           end;
    end;
end;

begin { INSTRUMENT_test }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_test';
{$ENDIF}
  If ctrl_pressed or alt_pressed or shift_pressed then EXIT;

  _1op_preview := _1op_preview_active;
  _4op_mode := NOT _1op_preview_active and (songdata.flag_4op <> 0) and (instr2 <> 0);

  valid_key := FALSE;
  For temp := 1 to 29 do
    If NOT shift_pressed then
      If (board_scancodes[temp] = HI(fkey)) then
        begin valid_key := TRUE; BREAK; end;

  If NOT valid_key or
     NOT (temp+12*(current_octave-1)-1 in [0..12*8+1]) then EXIT;

  If (Empty(songdata.instr_data[instr],SizeOf(songdata.instr_data[instr])) and
      Empty(songdata.instr_macros[instr],SizeOf(songdata.instr_macros[instr]))) or
     (_4op_mode and Empty(songdata.instr_data[instr2],SizeOf(songdata.instr_data[instr2])) and
                    Empty(songdata.instr_macros[instr2],SizeOf(songdata.instr_macros[instr2]))) then
    EXIT;

  temp2 := temp;
  ins_trailing_flag := TRUE;
  status_backup.replay_forbidden := replay_forbidden;
  status_backup.play_status := play_status;
  replay_forbidden := TRUE;
  If (play_status <> isStopped) then play_status := isPaused;
  nul_volume_bars;
  really_no_status_refresh := TRUE;

  Move(channel_flag,channel_flag_backup,SizeOf(channel_flag_backup));
  Move(event_table,event_table_backup,SizeOf(event_table_backup));
  common_flag_backup := songdata.common_flag;
  volume_scaling_backup := volume_scaling;
  songdata.common_flag := songdata.common_flag AND NOT $80;
  volume_scaling := FALSE;
  FillChar(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
  Move(pan_lock,pan_lock_backup,SizeOf(pan_lock));
  Move(volume_lock,volume_lock_backup,SizeOf(volume_lock));
  Move(peak_lock,peak_lock_backup,SizeOf(volume_lock));
  Move(panning_table,panning_table_backup,SizeOf(panning_table));
  FillChar(pan_lock,SizeOf(pan_lock),0);
  FillChar(volume_lock,SizeOf(volume_lock),0);
  FillChar(peak_lock,SizeOf(volume_lock),0);
  flag_4op_backup := songdata.flag_4op;
  If NOT percussion_mode and
     NOT (songdata.flag_4op <> 0) then channels := 18
  else If NOT (songdata.flag_4op <> 0) then channels := 15
       else begin
              If _4op_mode then
                begin
                  songdata.flag_4op := $3f;
                  channels := 6;
                end
              else begin
                     songdata.flag_4op := 0;
                     If NOT percussion_mode then channels := 18
                     else channels := 15;
                   end;
            end;

  reset_player;
  FillChar(chan_handle,SizeOf(chan_handle),0);
  Move(fmpar_table,fmpar_table_backup,SizeOf(fmpar_table_backup));
  Move(volume_table,volume_table_backup,SizeOf(volume_table_backup));
  Move(freq_table,freq_table_backup,SizeOf(freq_table));
  Move(freqtable2,freqtable2_backup,SizeOf(freqtable2));
  Move(keyoff_loop,keyoff_loop_backup,SizeOf(keyoff_loop));
  FillChar(keyoff_loop,SizeOf(keyoff_loop),FALSE);

  misc_register := current_tremolo_depth SHL 7+
                   current_vibrato_depth SHL 6+
                   BYTE(percussion_mode) SHL 5;
  key_off(17);
  key_off(18);
  opl2out(_instr[11],misc_register);

  If percussion_mode and
     (songdata.instr_data[instr].perc_voice in [1..5]) then
    begin
      output_note(songdata.instr_data[instr].perc_voice+15,temp2);
      While scankey(board_scancodes[temp2]) do
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
  else Repeat
{$IFNDEF GO32V2}
         keyboard_poll_input;
{$ENDIF}
         valid_key := FALSE;
         For temp := 1 to 29 do
           begin
             temp2 := board_scancodes[temp];
             temp4 := scankey(temp2);

             If NOT _4op_mode then
               begin
                 temp3 := get_chanpos(chan_handle,channels,temp2);
                 temp5 := get_chanpos(chan_handle,channels,0);
               end
             else begin
                    temp3 := get_chanpos2(chan_handle,channels,temp2);
                    temp5 := get_chanpos2(chan_handle,channels,0);
                  end;

             If temp4 then valid_key := TRUE;
             If temp4 and (temp3 = 0) and (temp5 <> 0) then
               output_note(temp5,temp);

             If NOT temp4 and (temp3 <> 0) then
               begin
                 chan_handle[temp3] := 0;
                 key_off(temp3);
                 If alt_pressed then keyoff_loop[temp3] := TRUE;
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
       until NOT valid_key;

  While ctrl_pressed do
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

  For temp := 1 to 20 do key_off(temp);
  songdata.flag_4op := flag_4op_backup;
  Move(fmpar_table_backup,fmpar_table,SizeOf(fmpar_table));
  Move(volume_table_backup,volume_table,SizeOf(volume_table));
  Move(panning_table_backup,panning_table,SizeOf(panning_table));
  songdata.common_flag := common_flag_backup;
  volume_scaling := volume_scaling_backup;
  If (status_backup.play_status = isPlaying) then reset_player;

  Move(channel_flag_backup,channel_flag,SizeOf(channel_flag));
  Move(event_table_backup,event_table,SizeOf(event_table));
  Move(pan_lock_backup,pan_lock,SizeOf(pan_lock));
  Move(volume_lock_backup,volume_lock,SizeOf(volume_lock));
  Move(peak_lock_backup,peak_lock,SizeOf(volume_lock));

  really_no_status_refresh := FALSE;
  Move(freq_table_backup,freq_table,SizeOf(freq_table));
  Move(freqtable2_backup,freqtable2,SizeOf(freqtable2));
  Move(keyoff_loop_backup,keyoff_loop,SizeOf(keyoff_loop));
  FillChar(macro_table,SizeOf(macro_table),0);
  replay_forbidden := status_backup.replay_forbidden;
  play_status := status_backup.play_status;
  ins_trailing_flag := FALSE;
  keyboard_reset_buffer;
end;

var
  color_table: array[1..3] of Byte;

function _1st_marked: Byte;

var
  temp,result: Byte;

begin
  result := 0;
  For temp := 1 to 255 do
    If (songdata.instr_names[temp][1] = _ins_mark_chr) then
      begin
        result := temp;
        BREAK;
      end;
  _1st_marked := result;
end;

function _2nd_marked: Byte;

var
  temp,result: Byte;

begin
  result := 0;
  If (_1st_marked <> 0) then
    For temp := SUCC(_1st_marked) to 255 do
      If (songdata.instr_names[temp][1] = _ins_mark_chr) then
        begin
          result := temp;
          BREAK;
        end;
  _2nd_marked := result;
end;

function marked_instruments: Byte;

var
  temp,result: Byte;

begin
  result := 0;
  For temp := 1 to 255 do
    If (songdata.instr_names[temp][1] = _ins_mark_chr) then
      Inc(result);
  marked_instruments := result;
end;

procedure reset_marked_instruments;
begin
  If (marked_instruments < 2) then
   If (songdata.instr_names[instrum_page][1] = _ins_mark_chr) then
     songdata.instr_names[instrum_page][1] := ' '
   else
  else begin
         songdata.instr_names[_2nd_marked][1] := ' ';
         songdata.instr_names[_1st_marked][1] := ' ';
       end;
  update_4op_flag_marks;
end;

function get_4op_to_test: Word;

var
  result: Word;

begin
  result := 0;
  If (songdata.flag_4op <> 0) then
    If check_4op_flag(current_inst) then
      result := SUCC(current_inst)+current_inst SHL 8
    else If (current_inst > 1) and check_4op_flag(PRED(current_inst)) then
           result := current_inst+PRED(current_inst) SHL 8;
  get_4op_to_test := result;
end;

function check_4op_to_test: Word;

var
  result: Word;

begin
  result := 0;
  If check_4op_flag(current_inst) then
    result := SUCC(current_inst)+current_inst SHL 8
  else If (current_inst > 1) and check_4op_flag(PRED(current_inst)) then
         result := current_inst+PRED(current_inst) SHL 8;
  check_4op_to_test := result;
end;

function check_4op_instrument(ins: Byte): Word;

var
  result: Word;

begin
  result := 0;
  If check_4op_flag(ins) then
    result := SUCC(ins)+ins SHL 8
  else If (ins > 1) and check_4op_flag(PRED(ins)) then
         result := ins+PRED(ins) SHL 8;
  check_4op_instrument := result;
end;

function check_4op_flag(ins: Byte): Boolean;

var
  result: Boolean;
  idx: Byte;

begin
  result := FALSE;
  For idx := 1 to songdata.ins_4op_flags.num_4op do
    If (songdata.ins_4op_flags.idx_4op[idx] = ins) then
      begin
        result := TRUE;
        BREAK;
      end;
  check_4op_flag := result;
end;

procedure reset_4op_flag(ins: Byte);

var
  temp_ins_4op_flags: tINS_4OP_FLAGS;
  idx: Byte;

begin
  If NOT check_4op_flag(ins) then EXIT;
  temp_ins_4op_flags.num_4op := 0;
  idx := 1;
  While (idx <= songdata.ins_4op_flags.num_4op) and
        (songdata.ins_4op_flags.idx_4op[idx] < ins) do
    begin
      Inc(temp_ins_4op_flags.num_4op);
      temp_ins_4op_flags.idx_4op[temp_ins_4op_flags.num_4op] :=
        songdata.ins_4op_flags.idx_4op[idx];
      Inc(idx);
    end;
  Inc(idx);
  While (idx <= songdata.ins_4op_flags.num_4op) do
    begin
      Inc(temp_ins_4op_flags.num_4op);
      temp_ins_4op_flags.idx_4op[temp_ins_4op_flags.num_4op] :=
        songdata.ins_4op_flags.idx_4op[idx];
      Inc(idx);
    end;
  songdata.ins_4op_flags := temp_ins_4op_flags;
end;

procedure set_4op_flag(ins: Byte);

var
  temp_ins_4op_flags: tINS_4OP_FLAGS;
  idx: Byte;

begin
  If (ins = 255) then EXIT;
  If check_4op_flag(ins) then
    reset_4op_flag(ins);
  If (ins > 1) and check_4op_flag(PRED(ins)) then
    reset_4op_flag(PRED(ins));
  If (ins < 255) and check_4op_flag(SUCC(ins)) then
    reset_4op_flag(SUCC(ins));
  temp_ins_4op_flags.num_4op := 0;
  idx := 1;
  While (idx <= songdata.ins_4op_flags.num_4op) and
        (songdata.ins_4op_flags.idx_4op[idx] < ins) do
    begin
      Inc(temp_ins_4op_flags.num_4op);
      temp_ins_4op_flags.idx_4op[temp_ins_4op_flags.num_4op] :=
        songdata.ins_4op_flags.idx_4op[idx];
      Inc(idx);
    end;
  Inc(temp_ins_4op_flags.num_4op);
  temp_ins_4op_flags.idx_4op[temp_ins_4op_flags.num_4op] := ins;
  While (idx <= songdata.ins_4op_flags.num_4op) do
    begin
      Inc(temp_ins_4op_flags.num_4op);
      temp_ins_4op_flags.idx_4op[temp_ins_4op_flags.num_4op] :=
        songdata.ins_4op_flags.idx_4op[idx];
      Inc(idx);
    end;
  songdata.ins_4op_flags := temp_ins_4op_flags;
end;

procedure update_4op_flag_marks;

var
  temp: Byte;

begin
  For temp := 1 to PRED(255) do
    If NOT check_4op_flag(temp) then
      begin
        If (songdata.instr_names[temp][1] in _4op_flag_chars) then
          songdata.instr_names[temp][1] := ' ';
        If (songdata.instr_names[SUCC(temp)][1] in _4op_flag_chars) then
          songdata.instr_names[SUCC(temp)][1] := ' ';
      end;
  For temp := 1 to PRED(255) do
    If check_4op_flag(temp) then
      begin
        If (songdata.instr_names[temp][1] = ' ') then
          songdata.instr_names[temp][1] := _4op_flag_chr_beg;
        If (songdata.instr_names[SUCC(temp)][1] = ' ') then
          songdata.instr_names[SUCC(temp)][1] := _4op_flag_chr_end;
      end;
end;

procedure INSTRUMENT_CONTROL_page_refresh(page: Byte);

var
  temp: Byte;
  temp_str: String;
  _status_shift_pos: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_page_refresh';
{$ENDIF}
  update_4op_flag_marks;
  If (ins_parameter(page,10) AND 1 <> 1) then
    For temp := 1 to 18 do
      ShowCStr(mn_environment.v_dest,
               INSCTRL_xshift+10,INSCTRL_yshift+06+temp,
               inst_itm1[temp].str,
               dialog_background+dialog_contxt_dis2,
               color_table[inst_itm1[temp].colr])
  else
    For temp := 1 to 18 do
      ShowCStr(mn_environment.v_dest,
               INSCTRL_xshift+10,INSCTRL_yshift+06+temp,
               inst_itm2[temp].str,
               dialog_background+dialog_contxt_dis2,
               color_table[inst_itm2[temp].colr]);

  ShowStr(mn_environment.v_dest,
          INSCTRL_xshift+56,INSCTRL_yshift+05,
          byte2hex(page),
          dialog_background+dialog_title);

  For temp := 1 to 10 do
    ShowStr(mn_environment.v_dest,
            INSCTRL_xshift+32,INSCTRL_yshift+08+pos2[temp],
            byte2hex(pBYTE(@Addr(songdata.instr_data[page])^)[_instr_data_ofs[temp]]),
            dialog_background+dialog_item);

  ShowCStr(mn_environment.v_dest,
           INSCTRL_xshift+30,INSCTRL_yshift+08+pos2[11],
           connection_str[pBYTE(@Addr(songdata.instr_data[page])^)[_instr_data_ofs[11]] AND 1]+'~/~'+
           CHR(ORD('0')+(pBYTE(@Addr(songdata.instr_data[page])^)[_instr_data_ofs[11]] SHR 1 AND 7)),
           dialog_background+dialog_item,
           color_table[inst_itm1[temp].colr]);

  Case songdata.instr_data[page].panning of
    0: ShowStr(mn_environment.v_dest,
               INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[12],
               'CENTER',
               dialog_background+dialog_item);
    1: ShowStr(mn_environment.v_dest,
               INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[12],
               'LEFT  ',
               dialog_background+dialog_item);
    2: ShowStr(mn_environment.v_dest,
               INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[12],
               'RiGHT ',
               dialog_background+dialog_item);
  end;

  If (songdata.instr_data[page].fine_tune < 0) then
    ShowStr(mn_environment.v_dest,
            INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[13],
            '-'+ExpStrR(Num2str(Abs(songdata.instr_data[page].fine_tune),16),2,' '),
            dialog_background+dialog_item)
  else
    ShowStr(mn_environment.v_dest,
            INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[13],
            '+'+ExpStrR(Num2str(Abs(songdata.instr_data[page].fine_tune),16),2,' '),
            dialog_background+dialog_item);

  _status_shift_pos := 0;
  If (check_4op_flag(page) or ((page > 1) and check_4op_flag(PRED(page)))) then
    begin
      _status_shift_pos := 5;
      ShowCStr(mn_environment.v_dest,
               INSCTRL_xshift+09,INSCTRL_yshift+26,
               ' [~'#4#3'~] '#205#205#205,
               dialog_background+dialog_border,
               dialog_background+dialog_context)
    end
  else
    ShowCStr(mn_environment.v_dest,
             INSCTRL_xshift+09,INSCTRL_yshift+26,
             ' [~'+perc_voice_str[songdata.instr_data[page].perc_voice]+'~] ',
             dialog_background+dialog_border,
             dialog_background+dialog_context);

  If (songdata.instr_macros[page].length <> 0) then temp_str := ' [~MACRO:FM'
  else temp_str := ' ';

  With songdata.macro_table[
       songdata.instr_macros[page].arpeggio_table].arpeggio do
    If (songdata.instr_macros[page].arpeggio_table <> 0) then
      If (temp_str <> ' ') then temp_str := temp_str+'+ARP'
      else temp_str := temp_str+'[~MACRO:ARP';

  With songdata.macro_table[
       songdata.instr_macros[page].vibrato_table].vibrato do
    If (songdata.instr_macros[page].vibrato_table <> 0) then
      If (temp_str <> ' ') then temp_str := temp_str+'+ViB'
      else temp_str := temp_str+'[~MACRO:ViB';

  If (temp_str <> ' ') then temp_str := temp_str+'~] ';

  ShowCStr(mn_environment.v_dest,INSCTRL_xshift+19-_status_shift_pos,INSCTRL_yshift+26,
           ExpStrR(temp_str,27,#205),
           dialog_background+dialog_border,
           dialog_background+dialog_context);

  STATUS_LINE_refresh;
end;

var
  adsr_bckg: Byte;

procedure _show_adsr(dest: tSCREEN_MEM_PTR; xstart,ystart: Byte;
                     attack,decay,sustain,release,attenuation: Byte;
                     eg_type: Byte;
                     attr,attr_hi: Byte;
                     reset: Boolean);

function _gfx_bar_str(value: Byte): String;

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
      result := result+CHR(127+value)
  until (value <= 15);
  _gfx_bar_str := flipstr(result);
end;

var
  index,pos: Integer;
  temp,temp2: Real;

function _conv(value,variant: Byte): Byte;
begin
  If (value <> 0) then _conv := variant
  else _conv := 1;
end;

begin { _show_adsr }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:_show_adsr';
{$ENDIF}
  fr_setting.update_area := FALSE;
  fr_setting.shadow_enabled := FALSE;

  If NOT is_default_screen_mode then
    Frame(dest,xstart,ystart+1,xstart+61,ystart+11,
          instrument_bckg,'',0,frame_solid_type1)
  else If reset then
         Frame(dest,xstart,ystart,xstart+63,ystart+12,
               instrument_bckg,'',0,frame_solid_type1)
       else Frame(dest,xstart,ystart,xstart+63,ystart+12,
                  instrument_adsr+instrument_text,' ADSR PREViEW ',
                  instrument_adsr+instrument_text,
                  frame_double);

  fr_setting.update_area := TRUE;
  fr_setting.shadow_enabled := TRUE;

  If (attack <> 0) then
    attack := min(ROUND(15/ln(15)*ln(attack)),1);

  If (decay <> 0) then
    decay := min(ROUND(15/ln(15)*ln(decay)),1)
  else sustain := 0;

  If (sustain <> 0) then
    sustain := min(ROUND(15/ln(15)*ln(sustain)),1);

  If (release <> 0) then
    release := min(ROUND(15/ln(15)*ln(release)),1);

  If reset then EXIT;
  pos := 1;
  temp := 0;

  For index := 0 to (15-attack) do
    begin
      temp := temp+8*16/(16-attack);
      If (attack <> 0) then
        begin
          ShowVStr(dest,xstart+1+pos,ystart+1,
                   ExpStrL(_gfx_bar_str(ROUND(temp/63*(63-attenuation))),9,' '),
                   attr_hi);
          Inc(pos);
        end;
    end;

  If (attack = 0) then
    begin
      Inc(pos);
      temp := 8*16;
    end;

  If (decay = 0) and ((release <> 0) or
                      ((sustain <> 0) and (eg_type = 1))) then
    decay := 15;

  If (decay <> 0) then
    For index := 0 to (15-decay) do
      begin
        temp := temp-8*16/16*sustain/(16-decay);
        ShowVStr(dest,xstart+1+pos,ystart+1,
                 ExpStrL(_gfx_bar_str(ROUND(temp/63*(63-attenuation))),9,' '),
                 attr_hi);
        Inc(pos);
      end;

  If (decay = 0) then
    Inc(pos);

  If (eg_type <> 1) and (release <> 0) then
    sustain := 0;

  If (sustain = 0) and (release <> 0) then
    sustain := 1;

  For index := 1 to sustain do
    If (sustain <> 0) then
      begin
        ShowVStr(dest,xstart+1+pos,ystart+1,
                 ExpStrL(_gfx_bar_str(ROUND(temp/63*(63-attenuation))),9,' '),
                 attr_hi);
        Inc(pos);
      end;

  If (sustain = 0) then
    Inc(pos);

  temp2 := temp;
  For index := 1 to (15-release) do
    begin
      temp := temp-temp2/(16-release);
      If (release <> 0) and (temp > 0) then
        begin
          If (eg_type <> 1) then
            ShowVStr(dest,xstart+1+pos,ystart+1,
                     ExpStrL(_gfx_bar_str(ROUND(temp/63*(63-attenuation))),9,' '),
                     attr_hi)
          else
            ShowVStr(dest,xstart+1+pos,ystart+1,
                     ExpStrL(_gfx_bar_str(ROUND(temp/63*(63-attenuation))),9,' '),
                     attr);
          Inc(pos);
        end;
    end;

  If (release > 0) then
    ShowStr(dest,xstart+2,ystart+10,
            Copy(Copy(ExpStrR(#246,_conv(attack,16-attack),' ')+
                      ExpStrR(#246,_conv(decay,16-decay),' ')+
                      ExpStrR(#246,_conv(sustain,sustain),' ')+
                      ExpStrR(#246,_conv(release,15-release),' '),1,60-1)+
                 #246+ExpStrL('',60,' '),1,60),
             attr_hi)
  else
    ShowStr(dest,xstart+2,ystart+10,
            ExpStrR(#246,_conv(attack,16-attack),' ')+
            ExpStrR(#246,_conv(decay,16-decay),' ')+
            ExpStrR(#246,_conv(sustain,sustain),' ')+
            ExpStrR(#246,_conv(release,15-release)+
                        15-_conv(release,15-release)+
                        15-_conv(sustain,sustain)+
                        15-_conv(decay,16-decay)+
                        15-_conv(attack,16-attack),' '),
            attr_hi);

  If (release > 0) then
    ShowStr(dest,xstart+2,ystart+11,
            Copy(Copy(ExpStrR('A',_conv(attack,16-attack),#250)+
                      ExpStrR('D',_conv(decay,16-decay),#250)+
                      ExpStrR('S',_conv(sustain,sustain),#250)+
                      ExpStrR('R',_conv(release,15-release),#250),1,60-1)+
                 #175+ExpStrL('',60,#250),1,60),
             attr_hi)
  else
    ShowStr(dest,xstart+2,ystart+11,
            ExpStrR('A',_conv(attack,16-attack),#250)+
            ExpStrR('D',_conv(decay,16-decay),#250)+
            ExpStrR('S',_conv(sustain,sustain),#250)+
            ExpStrR('R',_conv(release,15-release)+
                         15-_conv(release,15-release)+
                         15-_conv(sustain,sustain)+
                         15-_conv(decay,16-decay)+
                         15-_conv(attack,16-attack),#250),
            attr_hi);
end;

procedure INSTRUMENT_CONTROL_page_refresh_alt(page: Byte);

var
  temp: Byte;
  temp_str: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_page_refresh_alt';
{$ENDIF}
  update_4op_flag_marks;
  If (ins_parameter(page,10) AND 1 <> 1) then
    For temp := 1 to 18 do
      ShowCStr(mn_environment.v_dest,INSCTRL_xshift+10,INSCTRL_yshift+06+temp,inst_itm1[temp].str,
               dialog_background+dialog_contxt_dis2,
               color_table[inst_itm1[temp].colr])
  else
    For temp := 1 to 18 do
      ShowCStr(mn_environment.v_dest,INSCTRL_xshift+10,INSCTRL_yshift+06+temp,inst_itm2[temp].str,
               dialog_background+dialog_contxt_dis2,
               color_table[inst_itm2[temp].colr]);

  For temp := 1 to 10 do
    ShowStr(mn_environment.v_dest,INSCTRL_xshift+32,INSCTRL_yshift+08+pos2[temp],
            byte2hex(pBYTE(@Addr(songdata.instr_data[page])^)[_instr_data_ofs[temp]]),
            instrument_bckg+instrument_hi_text);

  ShowCStr(mn_environment.v_dest,
           INSCTRL_xshift+30,INSCTRL_yshift+08+pos2[11],
           connection_str[pBYTE(@Addr(songdata.instr_data[page])^)[_instr_data_ofs[11]] AND 1]+'~/~'+
           CHR(ORD('0')+(pBYTE(@Addr(songdata.instr_data[page])^)[_instr_data_ofs[11]] SHR 1 AND 7)),
           dialog_background+dialog_item,
           color_table[inst_itm1[temp].colr]);

  Case songdata.instr_data[page].panning of
    0: ShowStr(mn_environment.v_dest,INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[12],
               'CENTER',
               instrument_bckg+instrument_hi_text);
    1: ShowStr(mn_environment.v_dest,INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[12],
               'LEFT  ',
               instrument_bckg+instrument_hi_text);
    2: ShowStr(mn_environment.v_dest,INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[12],
               'RiGHT ',
               instrument_bckg+instrument_hi_text);
  end;

  If (songdata.instr_data[page].fine_tune < 0) then
    ShowStr(mn_environment.v_dest,INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[13],
            '-'+ExpStrR(Num2str(Abs(songdata.instr_data[page].fine_tune),16),2,' '),
            instrument_bckg+instrument_hi_text)
  else
    ShowStr(mn_environment.v_dest,INSCTRL_xshift+24,INSCTRL_yshift+08+pos2[13],
            '+'+ExpStrR(Num2str(Abs(songdata.instr_data[page].fine_tune),16),2,' '),
            instrument_bckg+instrument_hi_text);

  ShowCStr(mn_environment.v_dest,
           INSCTRL_xshift+09,INSCTRL_yshift+26,
           ' [~'+perc_voice_str[songdata.instr_data[page].perc_voice]+'~] ',
           dialog_background+dialog_border,
           dialog_background+dialog_context);

  If (songdata.instr_macros[page].length <> 0) then temp_str := ' [~MACRO:FM'
  else temp_str := ' ';

  With songdata.macro_table[
       songdata.instr_macros[page].arpeggio_table].arpeggio do
    If (songdata.instr_macros[page].arpeggio_table <> 0) then
      If (temp_str <> ' ') then temp_str := temp_str+'+ARP'
      else temp_str := temp_str+'[~MACRO:ARP';

  With songdata.macro_table[
       songdata.instr_macros[page].vibrato_table].vibrato do
    If (songdata.instr_macros[page].vibrato_table <> 0) then
      If (temp_str <> ' ') then temp_str := temp_str+'+ViB'
      else temp_str := temp_str+'[~MACRO:ViB';

  If (temp_str <> ' ') then temp_str := temp_str+'~] ';

  ShowCStr(mn_environment.v_dest,INSCTRL_xshift+19,INSCTRL_yshift+26,
           ExpStrR(temp_str,21+1,#205),
           dialog_background+dialog_border,
           dialog_background+dialog_context);
end;

var
  temp: Byte;
  xstart,ystart: Byte;
  nope: Boolean;
  hpos,vpos: Byte;
  carrier: Boolean;
  inst: ^tADTRACK2_INS;

type
  tSET_OF_CHARS = Set of Char;
  tBYTE_PTR = ^Byte;

function _4op_conn_to_idx(str: String): Byte;

var
  idx,result: Byte;
  temps: String;

begin
  temps := FilterStr1(str,'~');
  result := 2;
  For idx := 0 to 3 do
    If (temps = _4op_connection_str[idx]) then
      begin
        Inc(result,idx);
        BREAK;
      end;
  _4op_conn_to_idx := result;
end;

procedure _show_conn_scheme(xstart,ystart,conn: Byte; hi_op: tSET_OF_CHARS);

var
  idx,idx2: Byte;
  result: array[1..6] of String;

begin
  For idx2 := 1 to 6 do
    begin
      result[idx2] := '';
      idx := 1;
      While (idx <= 17) do
        If (inst_con_scheme[conn][idx2][idx] = #219) and
           (inst_con_scheme[conn][idx2][idx+1] in ['1'..'4']) then
          begin
            If (inst_con_scheme[conn][idx2][idx+1] in hi_op) then
              result[idx2] := result[idx2]+'`'#219'`^'+inst_con_scheme[conn][idx2][idx+1]+'^`'#219'`'
            else result[idx2] := result[idx2]+#219'~'+inst_con_scheme[conn][idx2][idx+1]+'~'#219;
            Inc(idx,3);
          end
        else begin
               result[idx2] := result[idx2]+inst_con_scheme[conn][idx2][idx];
               Inc(idx);
             end;
    end;
  For idx := 1 to 6 do
    ShowC4Str(ptr_temp_screen,xstart,ystart+idx-1,result[idx],
              instrument_bckg+instrument_glob,
              instrument_glob SHL 4,
              instrument_bckg+instrument_hi_glob,
              instrument_hi_glob SHL 4);
end;

function _get_feedback_val: Byte;
begin
  If NOT (get_4op_to_test <> 0) then
    _get_feedback_val := (songdata.instr_data[current_inst].fm_data.FEEDBACK_FM SHR 1) AND 7
  else _get_feedback_val := (songdata.instr_data[LO(get_4op_to_test)].fm_data.FEEDBACK_FM SHR 1) AND 7;
end;

procedure _inc_feedback_val;

var
  feedb_ptr: tBYTE_PTR;

begin
  If NOT (get_4op_to_test <> 0) then
    feedb_ptr := tBYTE_PTR(Addr(songdata.instr_data[current_inst].fm_data.FEEDBACK_FM))
  else feedb_ptr := tBYTE_PTR(Addr(songdata.instr_data[LO(get_4op_to_test)].fm_data.FEEDBACK_FM));
  If ((feedb_ptr^ SHR 1) AND 7 < 7) then
    feedb_ptr^ := feedb_ptr^ AND 1+((feedb_ptr^ SHR 1) AND 7 +1) SHL 1;
end;

procedure _dec_feedback_val;

var
  feedb_ptr: tBYTE_PTR;

begin
  If NOT (get_4op_to_test <> 0) then
    feedb_ptr := tBYTE_PTR(Addr(songdata.instr_data[current_inst].fm_data.FEEDBACK_FM))
  else feedb_ptr := tBYTE_PTR(Addr(songdata.instr_data[LO(get_4op_to_test)].fm_data.FEEDBACK_FM));
  If ((feedb_ptr^ SHR 1) AND 7 > 0) then
    feedb_ptr^ := feedb_ptr^ AND 1+((feedb_ptr^ SHR 1) AND 7 -1) SHL 1;
end;

function _get_finetune_val: Shortint;
begin
  If NOT (get_4op_to_test <> 0) then
    _get_finetune_val := songdata.instr_data[current_inst].fine_tune
  else _get_finetune_val := songdata.instr_data[LO(get_4op_to_test)].fine_tune;
end;

procedure _inc_finetune_val;
begin
  If NOT (get_4op_to_test <> 0) then
    songdata.instr_data[current_inst].fine_tune := max(songdata.instr_data[current_inst].fine_tune+1,127)
  else songdata.instr_data[LO(get_4op_to_test)].fine_tune := max(songdata.instr_data[LO(get_4op_to_test)].fine_tune+1,127);
end;

procedure _dec_finetune_val;
begin
  If NOT (get_4op_to_test <> 0) then
    songdata.instr_data[current_inst].fine_tune := min(songdata.instr_data[current_inst].fine_tune-1,-127)
  else songdata.instr_data[LO(get_4op_to_test)].fine_tune := min(songdata.instr_data[LO(get_4op_to_test)].fine_tune-1,-127);
end;

var
  _curr_connection_str: String;
  _status_shift_pos: Byte;
  _4op_conn_str: String;
  _4op_slot_str: String;
  _4op_slot_chr: tSET_OF_CHARS;
  _col_mod,_col_hi_mod: Byte;

procedure _page_build;

var
  temp,nm_slots: Byte;
  temp_str: String;
  _pan_4op: String;
  _feedb_4op: String;
  _ftune_4op: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_edit:page_build';
{$ENDIF}
  ShowStr(ptr_temp_screen,xstart+45,ystart,
          byte2hex(instrum_page),
          instrument_bckg+instrument_title);

  If NOT is_default_screen_mode then
    ShowStr(ptr_temp_screen,xstart-1,ystart+24,
            #204+ExpStrL('',70,#205)+#185,
            instrument_bckg+instrument_border);

  If NOT (inst^.perc_voice in [2..5]) and (get_4op_to_test <> 0) then
    begin
      If (LO(get_4op_to_test) = HI(get_4op_to_test)) then
        _4op_conn_str := connection_str[pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] AND 1]+'/'+
                         connection_str[pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] AND 1]
      else If (current_inst = HI(get_4op_to_test)) then
             _4op_conn_str := '~'+connection_str[pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] AND 1]+'~/'+
                              connection_str[pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] AND 1]
           else
             _4op_conn_str := connection_str[pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] AND 1]+'/~'+
                               connection_str[pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] AND 1]+'~';
      If (current_inst = LO(get_4op_to_test)) then
        If NOT carrier then
          If (HI(get_4op_to_test) <> LO(get_4op_to_test)) then
            begin
              _4op_slot_str := '~1~`'#27'`2`'#27'`3`'#27'`4';
              _4op_slot_chr := ['1'];
            end
          else begin
                 _4op_slot_str := '~1~`'#27'`2`'#27'`~3~`'#27'`4';
                 _4op_slot_chr := ['1','3']
               end
        else If (HI(get_4op_to_test) <> LO(get_4op_to_test)) then
               begin
                 _4op_slot_str := '1`'#27'`~2~`'#27'`3`'#27'`4';
                 _4op_slot_chr := ['2'];
               end
             else begin
                    _4op_slot_str := '1`'#27'`~2~`'#27'`3`'#27'`~4~';
                    _4op_slot_chr := ['2','4'];
                  end
      else If NOT carrier then
             If (HI(get_4op_to_test) <> LO(get_4op_to_test)) then
               begin
                 _4op_slot_str := '1`'#27'`2`'#27'`~3~`'#27'`4';
                 _4op_slot_chr := ['3'];
               end
             else begin
                    _4op_slot_str := '~1~`'#27'`2`'#27'`~3~`'#27'`4';
                    _4op_slot_chr := ['1','3'];
                  end
           else If (HI(get_4op_to_test) <> LO(get_4op_to_test)) then
                  begin
                    _4op_slot_str := '1`'#27'`2`'#27'`3`'#27'`~4~';
                    _4op_slot_chr := ['4'];
                  end
                else begin
                       _4op_slot_str := '1`'#27'`~2~`'#27'`3`'#27'`~4~';
                       _4op_slot_chr := ['2','4'];
                     end;
    end;

  If (inst^.perc_voice in [2..5]) then
    begin
      Move(inst_text_ext_perc,inst_text[9],SizeOf(inst_text_ext_perc));
      Move(inst_hpos_ext_perc,inst_hpos[12],SizeOf(inst_hpos_ext_perc));
    end
  else If NOT (get_4op_to_test <> 0) then
         begin
           Move(inst_text_ext_2op,inst_text[9],SizeOf(inst_text_ext_2op));
           Move(inst_hpos_ext_2op,inst_hpos[12],SizeOf(inst_hpos_ext_2op));
         end
       else begin
              Move(inst_text_ext_4op,inst_text[9],SizeOf(inst_text_ext_4op));
              Move(inst_hpos_ext_4op,inst_hpos[12],SizeOf(inst_hpos_ext_4op));
            end;

  If NOT (inst^.perc_voice in [2..5]) and
     ((NOT (get_4op_to_test <> 0) and carrier) or
      ((get_4op_to_test <> 0) and (('2' in _4op_slot_chr) or ('4' in _4op_slot_chr)))) then
    For temp := 1 to 24 do
      ShowC4Str(ptr_temp_screen,xstart+1,ystart+temp,inst_text[temp],
                instrument_bckg+instrument_text,
                instrument_bckg+instrument_car,
                instrument_bckg+instrument_glob,
                instrument_bckg+instrument_hid)
  else
    For temp := 1 to 24 do
      ShowC4Str(ptr_temp_screen,xstart+1,ystart+temp,inst_text[temp],
                instrument_bckg+instrument_text,
                instrument_bckg+instrument_mod,
                instrument_bckg+instrument_glob,
                instrument_bckg+instrument_hid);

  If (inst^.perc_voice in [2..5]) then _status_shift_pos := 5
  else If NOT (get_4op_to_test <> 0) then _status_shift_pos := 9
       else _status_shift_pos := 19;

  If NOT (inst^.perc_voice in [2..5]) and (get_4op_to_test <> 0) then
    begin
      If (LO(get_4op_to_test) = HI(get_4op_to_test)) then
        ShowC3Str(ptr_temp_screen,xstart,ystart+24,
                  ' `[`'#244+byte2hex(HI(get_4op_to_test))+
                  ','#245+byte2hex(HI(get_4op_to_test))+' '+_4op_conn_str+'`]` ',
                  instrument_bckg+instrument_context,
                  instrument_context SHL 4,
                  instrument_bckg+instrument_border)
      else If (current_inst = HI(get_4op_to_test)) then
             ShowC3Str(ptr_temp_screen,xstart,ystart+24,
                       ' `[`~'#244+byte2hex(HI(get_4op_to_test))+
                       '~,'#245+byte2hex(LO(get_4op_to_test))+' '+_4op_conn_str+'`]` ',
                       instrument_bckg+instrument_context,
                       instrument_context SHL 4,
                       instrument_bckg+instrument_border)
           else ShowC3Str(ptr_temp_screen,xstart,ystart+24,
                          ' `[`'#244+byte2hex(HI(get_4op_to_test))+
                          ',~'#245+byte2hex(LO(get_4op_to_test))+'~ '+_4op_conn_str+'`]` ',
                          instrument_bckg+instrument_context,
                          instrument_context SHL 4,
                          instrument_bckg+instrument_border);
      _show_conn_scheme(xstart+32,ystart+11,_4op_conn_to_idx(_4op_conn_str),_4op_slot_chr);
      ShowC3Str(ptr_temp_screen,xstart+17,ystart+24,'`[`'#4#3':'+_4op_slot_str+'`]` ',
                instrument_bckg+instrument_context,
                instrument_context SHL 4,
                instrument_bckg+instrument_border);
    end
  else
    begin
      If NOT (inst^.perc_voice in [2..5]) then
        _show_conn_scheme(xstart+32,ystart+11,inst^.fm_data.FEEDBACK_FM AND 1,[CHR(BYTE(carrier)+ORD('1'))])
      else _show_conn_scheme(xstart+32,ystart+11,6,['1']);
      Case inst^.perc_voice of
        0: ShowCStr(ptr_temp_screen,xstart,ystart+24,' [~MELODiC~]',
                    instrument_bckg+instrument_border,
                    instrument_bckg+instrument_context);
        1: ShowCStr(ptr_temp_screen,xstart,ystart+24,' [~PERC:BD~]',
                    instrument_bckg+instrument_border,
                    instrument_bckg+instrument_context);
        2: ShowCStr(ptr_temp_screen,xstart,ystart+24,' [~PERC:SD~]',
                    instrument_bckg+instrument_border,
                    instrument_bckg+instrument_context);
        3: ShowCStr(ptr_temp_screen,xstart,ystart+24,' [~PERC:TT~]',
                    instrument_bckg+instrument_border,
                    instrument_bckg+instrument_context);
        4: ShowCStr(ptr_temp_screen,xstart,ystart+24,' [~PERC:TC~]',
                    instrument_bckg+instrument_border,
                    instrument_bckg+instrument_context);
        5: ShowCStr(ptr_temp_screen,xstart,ystart+24,' [~PERC:HH~]',
                    instrument_bckg+instrument_border,
                    instrument_bckg+instrument_context);
      end;
      If (inst^.perc_voice in [2..5]) then
        ShowCStr(ptr_temp_screen,xstart+10,ystart+24,
                 ' [~'#1#3'~] ',
                 instrument_bckg+instrument_border,
                 instrument_bckg+instrument_context)
      else
        If NOT carrier then
          ShowC3Str(ptr_temp_screen,xstart+10,ystart+24,' `[`'#2#3':~1~`'#27'`2`]`',
                    instrument_bckg+instrument_context,
                    instrument_context SHL 4,
                    instrument_bckg+instrument_border)
        else
          ShowC3Str(ptr_temp_screen,xstart+10,ystart+24,' `[`'#2#3':1`'#27'`~2~`]`',
                    instrument_bckg+instrument_context,
                    instrument_context SHL 4,
                    instrument_bckg+instrument_border);
    end;

  If (songdata.instr_macros[instrum_page].length <> 0) then temp_str := ' [~MACRO:FM'
  else temp_str := ' ';

  With songdata.macro_table[
       songdata.instr_macros[instrum_page].arpeggio_table].arpeggio do
    If (songdata.instr_macros[instrum_page].arpeggio_table <> 0) then
      If (temp_str <> ' ') then temp_str := temp_str+'+ARP'
      else temp_str := temp_str+'[~MACRO:ARP';

  With songdata.macro_table[
       songdata.instr_macros[instrum_page].vibrato_table].vibrato do
    If (songdata.instr_macros[instrum_page].vibrato_table <> 0) then
      If (temp_str <> ' ') then temp_str := temp_str+'+ViB'
      else temp_str := temp_str+'[~MACRO:ViB';

  If (temp_str <> ' ') then temp_str := temp_str+'~] ';

  ShowCStr(ptr_temp_screen,
           xstart+10+_status_shift_pos,ystart+24,
           ExpStrR(temp_str,39,#205),
           instrument_bckg+instrument_border,
           instrument_bckg+instrument_context);

   If (inst^.perc_voice in [2..5]) then
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
  ShowC3Str(ptr_temp_screen,xstart+48,ystart+24,
            ExpStrL(temp_str,28,#205),
            instrument_bckg+instrument_border,
            instrument_bckg+instrument_context,
            instrument_bckg+instrument_con_dis);

  If (nm_slots > 1) then
    For temp := 1 to nm_slots do
      If (NOT _operator_enabled[temp]) then
        ShowStr(ptr_temp_screen,xstart+72-C3StrLen(temp_str)-1+temp,ystart+24,
                #250,
                instrument_bckg+instrument_border);

  If (inst_hpos[vpos,hpos] = 0) then
    begin
      vpos := 1;
      hpos := 1;
    end;

  If NOT (get_4op_to_test <> 0) then
    begin
      _pan_4op := '     ';
      _feedb_4op :=  '    ';
      _ftune_4op :=  '    ';
    end
  else begin
         If (current_inst = HI(get_4op_to_test)) then
           _pan_4op := '('#244#2#3')'
         else _pan_4op := '('#245#2#3')';
         _feedb_4op := '['#4#3']';
         _ftune_4op := '['#4#3']'
       end;

  If NOT (inst^.perc_voice in [2..5]) then
    begin
      _col_mod := instrument_mod;
      _col_hi_mod := instrument_hi_mod;
    end
  else begin
         _col_mod := instrument_glob;
         _col_hi_mod := instrument_hi_glob;
       end;

  If NOT ((vpos = 1) and (hpos = 1)) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+1,ystart+1,'~A~TTACK RATE',
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else
      ShowCStr(ptr_temp_screen,xstart+1,ystart+1,'~A~TTACK RATE',
               instrument_bckg+_col_mod,
               instrument_bckg+_col_hi_mod);

  If NOT ((vpos = 2) and (hpos = 1)) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+1,ystart+2,'~D~ECAY RATE',
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else
      ShowCStr(ptr_temp_screen,xstart+1,ystart+2,'~D~ECAY RATE',
               instrument_bckg+_col_mod,
               instrument_bckg+_col_hi_mod);

  If NOT ((vpos in [3,6,8,9]) and (hpos = 1)) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+51,ystart+1,'~W~AVEFORM TYPE',
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else
      ShowCStr(ptr_temp_screen,xstart+51,ystart+1,'~W~AVEFORM TYPE',
               instrument_bckg+_col_mod,
               instrument_bckg+_col_hi_mod);

  If NOT ((vpos = 4) and (hpos = 1)) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+1,ystart+4,'~S~USTAiN LEVEL',
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else
      ShowCStr(ptr_temp_screen,xstart+1,ystart+4,'~S~USTAiN LEVEL',
               instrument_bckg+_col_mod,
               instrument_bckg+_col_hi_mod);

  If NOT ((vpos = 5) and (hpos = 1)) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+1,ystart+5,'~R~ELEASE RATE',
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else
      ShowCStr(ptr_temp_screen,xstart+1,ystart+5,'~R~ELEASE RATE',
               instrument_bckg+_col_mod,
               instrument_bckg+_col_hi_mod);

  If NOT ((vpos = 7) and (hpos = 1)) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+1,ystart+7,'~O~UTPUT LEVEL',
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else
      ShowCStr(ptr_temp_screen,xstart+1,ystart+7,'~O~UTPUT LEVEL',
               instrument_bckg+_col_mod,
               instrument_bckg+_col_hi_mod);

  If NOT ((vpos in [10..13]) and (hpos = 1)) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+1,ystart+9,'~K~EY SCALiNG LEVEL',
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else
      ShowCStr(ptr_temp_screen,xstart+1,ystart+9,'~K~EY SCALiNG LEVEL',
               instrument_bckg+_col_mod,
               instrument_bckg+_col_hi_mod);

  If NOT (inst^.perc_voice in [2..5]) then
    begin
      If NOT (((vpos in [12,13]) and (hpos = 2)) or
              ((vpos in [14,15]) and (hpos = 1)) or
              ((vpos = 17) and (hpos = 4))) then
        ShowCStr(ptr_temp_screen,xstart+21,ystart+11,'~C~ONNECTiON',
                 instrument_bckg+instrument_glob,
                 instrument_bckg+instrument_hi_glob);

      If NOT ((vpos = 12) and (hpos = 3)) then
        ShowCStr(ptr_temp_screen,xstart+51,ystart+11,'~F~EEDBACK '+_feedb_4op,
                 instrument_bckg+instrument_glob,
                 instrument_bckg+instrument_hi_glob);
    end;

  If NOT ((vpos = 16) and (hpos = 2)) then
    ShowCStr(ptr_temp_screen,xstart+51,ystart+15,'F-~T~UNE '+_ftune_4op,
             instrument_bckg+instrument_glob,
             instrument_bckg+instrument_hi_glob);

  If NOT ((vpos = 17) and (hpos in [1..3])) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+1,ystart+15,'~P~ANNiNG '+_pan_4op,
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else ShowCStr(ptr_temp_screen,xstart+1,ystart+15,'~P~ANNiNG '+_pan_4op,
                  instrument_bckg+_col_mod,
                  instrument_bckg+_col_hi_mod);

  If NOT ((vpos in [18..21]) and (hpos = 1)) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+1,ystart+19,'~E~NVELOPE TYPE',
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else
      ShowCStr(ptr_temp_screen,xstart+1,ystart+19,'~E~NVELOPE TYPE',
               instrument_bckg+_col_mod,
               instrument_bckg+_col_hi_mod);

  If NOT ((vpos in [18..20]) and (hpos > 1)) then
    If carrier then
      ShowCStr(ptr_temp_screen,xstart+28,ystart+19,'FREQUENCY DATA ~M~ULTiPLiER',
               instrument_bckg+instrument_car,
               instrument_bckg+instrument_hi_car)
    else
      ShowCStr(ptr_temp_screen,xstart+28,ystart+19,'FREQUENCY DATA ~M~ULTiPLiER',
               instrument_bckg+_col_mod,
               instrument_bckg+_col_hi_mod);

  Case hpos of
    1: Case vpos of
         1:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+1,'ATTACK RATE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+1,'ATTACK RATE',
                       instrument_bckg+_col_hi_mod);

         2:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+2,'DECAY RATE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+2,'DECAY RATE',
                       instrument_bckg+_col_hi_mod);
         3,6,8,
         9:  If carrier then
               ShowStr(ptr_temp_screen,xstart+51,ystart+1,'WAVEFORM TYPE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+51,ystart+1,'WAVEFORM TYPE',
                       instrument_bckg+_col_hi_mod);

         4:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+4,'SUSTAiN LEVEL',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+4,'SUSTAiN LEVEL',
                       instrument_bckg+_col_hi_mod);

         5:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+5,'RELEASE RATE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+5,'RELEASE RATE',
                       instrument_bckg+_col_hi_mod);

         7:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+7,'OUTPUT LEVEL',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+7,'OUTPUT LEVEL',
                       instrument_bckg+_col_hi_mod);

         10..17: If (vpos in [10..13]) and (hpos = 1) then
                   If carrier then
                     ShowStr(ptr_temp_screen,xstart+1,ystart+9,'KEY SCALiNG LEVEL',
                             instrument_bckg+instrument_hi_car)
                   else
                     ShowStr(ptr_temp_screen,xstart+1,ystart+9,'KEY SCALiNG LEVEL',
                             instrument_bckg+_col_hi_mod)
                 else If (vpos <> 17) then
                        ShowStr(ptr_temp_screen,xstart+21,ystart+11,'CONNECTiON',
                                instrument_bckg+instrument_hi_glob)
                      else If carrier then
                             ShowStr(ptr_temp_screen,xstart+1,ystart+15,'PANNiNG '+_pan_4op,
                                     instrument_bckg+instrument_hi_car)
                           else
                             ShowStr(ptr_temp_screen,xstart+1,ystart+15,'PANNiNG '+_pan_4op,
                                     instrument_bckg+_col_hi_mod);
         18,19,20,
         21: If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+19,'ENVELOPE TYPE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+19,'ENVELOPE TYPE',
                       instrument_bckg+_col_hi_mod);
       end;

    2,3,4,5,6,
    7: Case vpos of
         2,4,5,
         7:  If carrier then
               ShowStr(ptr_temp_screen,xstart+51,ystart+1,'WAVEFORM TYPE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+51,ystart+1,'WAVEFORM TYPE',
                       instrument_bckg+_col_hi_mod);

         12..17:  If (vpos = 12) and (hpos = 3) then
                    ShowStr(ptr_temp_screen,xstart+51,ystart+11,'FEEDBACK '+_feedb_4op,
                            instrument_bckg+instrument_hi_glob)
                  else If (vpos = 16) and (hpos = 2) then
                         ShowStr(ptr_temp_screen,xstart+51,ystart+15,'F-TUNE '+_ftune_4op,
                                 instrument_bckg+instrument_hi_glob)
                       else If (vpos = 17) and (hpos in [1..3]) then
                              If carrier then
                                ShowStr(ptr_temp_screen,xstart+1,ystart+15,'PANNiNG '+_pan_4op,
                                        instrument_bckg+instrument_hi_car)
                              else ShowStr(ptr_temp_screen,xstart+1,ystart+15,'PANNiNG '+_pan_4op,
                                           instrument_bckg+_col_hi_mod)
                            else ShowStr(ptr_temp_screen,xstart+21,ystart+11,'CONNECTiON',
                                         instrument_bckg+instrument_hi_glob);
         18,19,20,
         21: If carrier then
               ShowStr(ptr_temp_screen,xstart+28,ystart+19,'FREQUENCY DATA MULTiPLiER',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+28,ystart+19,'FREQUENCY DATA MULTiPLiER',
                       instrument_bckg+_col_hi_mod);
       end;
  end;
end;

procedure _page_refresh;

var
  temp,x0,y0: Byte;
  temps1,temps2: String;
  adsr_vpos: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_edit:page_refresh';
{$ENDIF}
  x0 := xstart;
  y0 := ystart;

  If is_default_screen_mode then
    begin
	  adsr_vpos := y0+9;
	  adsr_bckg := instrument_adsr;
	end  
  else
    begin
	  adsr_vpos := y0+24;
      adsr_bckg := instrument_bckg;
	end;

  If (NOT ((vpos in [1,2,4,5,7,21]) and (hpos = 1)) or
      NOT _ADSR_preview_flag) then
    begin
      _show_adsr(ptr_temp_screen,x0+3,adsr_vpos,
                 BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL,
				 adsr_bckg,adsr_bckg,
                 TRUE);
      _page_build;
    end;

  If carrier then temp := inst^.fm_data.ATTCK_DEC_carrier
  else temp := inst^.fm_data.ATTCK_DEC_modulator;

  ShowCStr(ptr_temp_screen,x0+inst_hpos[1,1],y0+inst_vpos[1],'~'+
           ExpStrL('',   (temp SHR 4),#14)+'~'+
           ExpStrL('',15-(temp SHR 4),#14),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowCStr(ptr_temp_screen,x0+inst_hpos[2,1],y0+inst_vpos[2],'~'+
           ExpStrL('',   (temp AND $0f),#14)+'~'+
           ExpStrL('',15-(temp AND $0f),#14),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowStr(ptr_temp_screen,x0+inst_hpos[1,1]+16,y0+inst_vpos[1],
          ExpStrR(Num2str(temp SHR 4,16),1,' '),
          instrument_bckg+instrument_text);

  ShowStr(ptr_temp_screen,x0+inst_hpos[2,1]+16,y0+inst_vpos[2],
          ExpStrR(Num2str(temp AND $0f,16),1,' '),
          instrument_bckg+instrument_text);

  If carrier then temp := inst^.fm_data.SUSTN_REL_carrier
  else temp := inst^.fm_data.SUSTN_REL_modulator;

  ShowCStr(ptr_temp_screen,x0+inst_hpos[4,1],y0+inst_vpos[4],'~'+
           ExpStrL('',   (temp SHR 4),#14)+'~'+
           ExpStrL('',15-(temp SHR 4),#14),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowCStr(ptr_temp_screen,x0+inst_hpos[5,1],y0+inst_vpos[5],'~'+
           ExpStrL('',   (temp AND $0f),#14)+'~'+
           ExpStrL('',15-(temp AND $0f),#14),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowStr(ptr_temp_screen,x0+inst_hpos[4,1]+16,y0+inst_vpos[4],
          ExpStrR(Num2str(temp SHR 4,16),1,' '),
          instrument_bckg+instrument_text);

  ShowStr(ptr_temp_screen,x0+inst_hpos[5,1]+16,y0+inst_vpos[5],
          ExpStrR(Num2str(temp AND $0f,16),1,' '),
          instrument_bckg+instrument_text);

  If carrier then temp := inst^.fm_data.WAVEFORM_carrier
  else temp := inst^.fm_data.WAVEFORM_modulator;

  ShowVStr(ptr_temp_screen,x0+inst_hpos[2,2],y0+inst_vpos[2],
           ExpStrL('',temp AND 7,' ')+#11+ExpStrL('',7-temp AND 7,' '),
           instrument_bckg+instrument_hi_text);

  If carrier then temp := inst^.fm_data.KSL_VOLUM_carrier
  else temp := inst^.fm_data.KSL_VOLUM_modulator;

  ShowCStr(ptr_temp_screen,x0+inst_hpos[7,1],y0+inst_vpos[7],'~'+
           ExpStrL('',   ((63-(temp AND $3f)) DIV 2),#14)+'~'+
           ExpStrL('',31-((63-(temp AND $3f)) DIV 2),#14),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowStr(ptr_temp_screen,x0+inst_hpos[7,1]+32,y0+inst_vpos[7],
          ExpStrR(Num2str(63-(temp AND $3f),16),2,' '),
          instrument_bckg+instrument_text);

  temp := temp SHR 6;
  temp := temp SHR 1+temp AND 1 SHL 1;
  ShowVStr(ptr_temp_screen,x0+inst_hpos[10,1],y0+inst_vpos[10],
           ExpStrL('',temp,' ')+#11+ExpStrL('',3-temp,' '),
           instrument_bckg+instrument_hi_text);

  ShowCStr(ptr_temp_screen,x0+inst_hpos[17,1],y0+inst_vpos[17],ins_pan_str1[inst^.panning],
               instrument_bckg+instrument_text,
               instrument_bckg+instrument_hi_text);

  If NOT (inst^.perc_voice in [2..5]) then
    begin
      temp := inst^.fm_data.FEEDBACK_FM;
      ShowCStr(ptr_temp_screen,x0+inst_hpos[12,3],y0+inst_vpos[12],'~'+
               ExpStrL('',   ROUND(_get_feedback_val*(17/7)),#14)+'~'+
               ExpStrL('',17-ROUND(_get_feedback_val*(17/7)),#14),
               instrument_bckg+instrument_text,
               instrument_bckg+instrument_hi_text);

      ShowStr(ptr_temp_screen,x0+inst_hpos[12,3]+16,y0+inst_vpos[12]-1,
              ExpStrR(Num2str(_get_feedback_val,16),2,' '),
              instrument_bckg+instrument_text);

      _curr_connection_str := ExpStrR('',6,' ');
      If NOT (get_4op_to_test <> 0) then
        If (temp AND 1 = 0) then _curr_connection_str[1] := #11
        else _curr_connection_str[2] := #11
      else _curr_connection_str[_4op_conn_to_idx(_4op_conn_str)+1] := #11;

      If NOT (get_4op_to_test <> 0) then
        ShowVStr(ptr_temp_screen,x0+inst_hpos[12,2],y0+inst_vpos[12],_curr_connection_str,
                 instrument_bckg+instrument_hi_text)
      else
        ShowVStr(ptr_temp_screen,x0+inst_hpos[14,1],y0+inst_vpos[12],_curr_connection_str,
                 instrument_bckg+instrument_hi_text);
    end;

  If (_get_finetune_val >= 0) then temp := _get_finetune_val
  else temp := 0-_get_finetune_val;
  temps1 := ExpStrL('',17,#14);
  If (vpos = 16) and (hpos = 2) then temps2 := #15'~'#15'~'#15
  else temps2 := #15'`'#15'`'#15;

  If (_get_finetune_val > 0) then
    begin
      Delete(temps1,1+7+(temp DIV 18),3);
      Insert(temps2,temps1,1+7+(temp DIV 18));
    end
  else
    begin
      Delete(temps1,1+7-(temp DIV 18),3);
      Insert(temps2,temps1,1+7-(temp DIV 18));
    end;

  If (_get_finetune_val > 0) then temps2 := '+'
  else If (_get_finetune_val < 0) then temps2 := '-'
       else temps2 := '';

  ShowStr(ptr_temp_screen,x0+inst_hpos[16,2]+14,y0+inst_vpos[16]-1,
          ExpStrL(temps2+ExpStrL(Num2str(temp,16),2,'0'),3,' '),
          instrument_bckg+instrument_text);

  ShowC3Str(ptr_temp_screen,x0+inst_hpos[16,2],y0+inst_vpos[16],temps1,
            instrument_bckg+instrument_text,
            instrument_bckg+instrument_hi_text,
            instrument_bckg+instrument_glob);

  If carrier then temp := inst^.fm_data.AM_VIB_EG_carrier
  else temp := inst^.fm_data.AM_VIB_EG_modulator;

  If  (temp SHR 7        = 0) then temps1 := ' '        else temps1 := #251;
  If ((temp SHR 6) AND 1 = 0) then temps1 := temps1+' ' else temps1 := temps1+#251;
  If ((temp SHR 4) AND 1 = 0) then temps1 := temps1+' ' else temps1 := temps1+#251;
  If ((temp SHR 5) AND 1 = 0) then temps1 := temps1+' ' else temps1 := temps1+#251;

  ShowVStr(ptr_temp_screen,x0+inst_hpos[18,1],y0+inst_vpos[18],temps1,
           instrument_bckg+instrument_hi_text);

  temps1 := ExpStrL('',16,' '); temps1[(temp AND $0f)+1] := '.';
  If ((vpos in [19..21]) and (hpos in [2..7])) then
    ShowStr(ptr_temp_screen,x0+inst_hpos[21,2]-1,y0+inst_vpos[19]-1,
            ExpStrR(inst_mult_hint[(vpos-19)*6+hpos-2],34,' '),
            instrument_bckg+instrument_hi_text)
  else
    ShowStr(ptr_temp_screen,x0+inst_hpos[21,2]-1,y0+inst_vpos[19]-1,
            ExpStrR(inst_mult_hint[temp AND $0f],34,' '),
            instrument_bckg+instrument_hi_text);

  For temp := 1 to 6 do
    If (temps1[temp] = ' ') then
      ShowStr(ptr_temp_screen,x0+inst_hpos[19,2+temp-1],y0+inst_vpos[19],' ',
              instrument_bckg+instrument_hi_text)
    else ShowStr(ptr_temp_screen,x0+inst_hpos[19,2+temp-1],y0+inst_vpos[19],#11,
                 instrument_bckg+instrument_hi_text);

  For temp := 1 to 6 do
    If (temps1[6+temp] = ' ') then
      ShowStr(ptr_temp_screen,x0+inst_hpos[20,2+temp-1],y0+inst_vpos[20],' ',
              instrument_bckg+instrument_hi_text)
    else ShowStr(ptr_temp_screen,x0+inst_hpos[20,2+temp-1],y0+inst_vpos[20],#11,
                 instrument_bckg+instrument_hi_text);

  For temp := 1 to 4 do
    If (temps1[12+temp] = ' ') then
      ShowStr(ptr_temp_screen,x0+inst_hpos[21,2+temp-1],y0+inst_vpos[21],' ',
              instrument_bckg+instrument_hi_text)
    else ShowStr(ptr_temp_screen,x0+inst_hpos[21,2+temp-1],y0+inst_vpos[21],#11,
                 instrument_bckg+instrument_hi_text);

  If NOT is_default_screen_mode or
     ((vpos in [1,2,4,5,7,21]) and (hpos = 1) and
      _ADSR_preview_flag) then
    If NOT carrier or (inst^.perc_voice in [2..5]) then
      _show_adsr(ptr_temp_screen,x0+3,adsr_vpos,
                 inst^.fm_data.ATTCK_DEC_modulator SHR 4,
                 inst^.fm_data.ATTCK_DEC_modulator AND $0f,
                 inst^.fm_data.SUSTN_REL_modulator SHR 4,
                 inst^.fm_data.SUSTN_REL_modulator AND $0f,
                 inst^.fm_data.KSL_VOLUM_modulator AND $3f,
                 inst^.fm_data.AM_VIB_EG_modulator SHR 5 AND 1,
                 adsr_bckg+_col_mod,
                 adsr_bckg+_col_hi_mod,FALSE)
    else
      _show_adsr(ptr_temp_screen,x0+3,adsr_vpos,
                 inst^.fm_data.ATTCK_DEC_carrier SHR 4,
                 inst^.fm_data.ATTCK_DEC_carrier AND $0f,
                 inst^.fm_data.SUSTN_REL_carrier SHR 4,
                 inst^.fm_data.SUSTN_REL_carrier AND $0f,
                 inst^.fm_data.KSL_VOLUM_carrier AND $3f,
                 inst^.fm_data.AM_VIB_EG_carrier SHR 5 AND 1,
                 adsr_bckg+instrument_car,
                 adsr_bckg+instrument_hi_car,FALSE);

  move2screen_alt;
end;

procedure _sync_radio_buttons;

var
  temp: Byte;

begin
  If ((vpos in [1,2,4,5,7]) and (hpos = 2)) or (vpos in [3,6,8,9]) then // sync WAVEFORM
    begin
      If carrier then vpos := 2+songdata.instr_data[current_inst].fm_data.WAVEFORM_carrier
      else vpos := 2+songdata.instr_data[current_inst].fm_data.WAVEFORM_modulator;
      If (vpos in [1,2,4,5,7]) then hpos := 2
      else If (vpos in [3,6,8,9]) then hpos := 1;
    end;

  If (vpos in [10..13]) and (hpos = 1) then // sync SCALING LEVEL
    begin
      If carrier then temp := songdata.instr_data[current_inst].fm_data.KSL_VOLUM_carrier
      else temp := songdata.instr_data[current_inst].fm_data.KSL_VOLUM_modulator;
      temp := temp SHR 6;
      temp := temp SHR 1+temp AND 1 SHL 1;
      vpos := 10+temp;
      hpos := 1;
    end;

  If (vpos = 17) and (hpos in [1..3]) then // sync PANNING
    Case inst^.panning of
      1: begin vpos := 17; hpos := 1; end;
      0: begin vpos := 17; hpos := 2; end;
      2: begin vpos := 17; hpos := 3; end;
    end;

  If ((vpos in [12,13]) and (hpos = 2)) or
     ((vpos in [14,15,16]) and (hpos = 1)) or ((vpos = 17) and (hpos = 4)) then // sync CONNECTION
    Case Pos(#11,_curr_connection_str) of
      1: begin vpos := 12; hpos := 2; end;
      2: begin vpos := 13; hpos := 2; end;
      3: begin vpos := 14; hpos := 1; end;
      4: begin vpos := 15; hpos := 1; end;
      5: begin vpos := 16; hpos := 1; end;
      6: begin vpos := 17; hpos := 3; end;
    end;

  If (vpos in [19..21]) and (hpos > 1) then // sync FREQ. DATA MULT.
    begin
      If carrier then temp := inst^.fm_data.AM_VIB_EG_carrier AND $0f
      else temp := inst^.fm_data.AM_VIB_EG_modulator AND $0f;
      hpos := 2+(temp MOD 6);
      vpos := 19+(temp DIV 6);
    end;
end;

procedure INSTRUMENT_CONTROL_edit;

function min0(number: Integer): Integer;
begin
  If (number > 0) then min0 := number
  else min0 := 0;
end;

function _ftune(ftune: Integer): Integer;

var
  temp: Integer;

begin
  If (ftune DIV 18 = 0) and (ftune <> 0) then temp := 0
  else temp := ABS(ftune) DIV 18;
  _ftune := (ftune DIV min(ABS(ftune),1))*temp;
end;

function _check_hpos_idx_l(vpos: Byte): Byte;

var
  idx: Byte;

begin
  _check_hpos_idx_l := 0;
  For idx := 1 to inst_hpos_max do
    If (inst_hpos[vpos,idx] <> 0) then
      begin
        _check_hpos_idx_l := idx;
        BREAK;
      end;
end;

function _check_hpos_idx_r(vpos: Byte): Byte;

var
  idx: Byte;

begin
  _check_hpos_idx_r := 0;
  For idx := inst_hpos_max downto 1 do
    If (inst_hpos[vpos,idx] <> 0) then
      begin
        _check_hpos_idx_r := idx;
        BREAK;
      end;
end;

procedure _set_operator_flag(oper: Byte; toggle: Boolean);

var
  _temp_operator_enabled: array[1..4] of Boolean;

begin
  If (inst^.perc_voice in [2..5]) or
     (NOT (get_4op_to_test <> 0) and NOT (oper in [1..2])) or
     (NOT (oper in [1..4])) then
    EXIT;

  If NOT toggle then
    begin
      FillChar(_operator_enabled,SizeOf(_operator_enabled),FALSE);
      _operator_enabled[oper] := TRUE;
      EXIT;
    end;

  Move(_operator_enabled,_temp_operator_enabled,SizeOf(_temp_operator_enabled));
  If NOT (get_4op_to_test <> 0) and (oper in [1,2]) then
    begin
      _temp_operator_enabled[oper] := NOT _temp_operator_enabled[oper];
      If NOT ((_temp_operator_enabled[1] = FALSE) and
              (_temp_operator_enabled[2] = FALSE)) then
        Move(_temp_operator_enabled,_operator_enabled,SizeOf(_operator_enabled));
    end
  else If (get_4op_to_test <> 0) and (oper in [1,2,3,4]) then
         begin
           _temp_operator_enabled[oper] := NOT _temp_operator_enabled[oper];
           If NOT ((_temp_operator_enabled[1] = FALSE) and
                   (_temp_operator_enabled[2] = FALSE) and
                   (_temp_operator_enabled[3] = FALSE) and
                   (_temp_operator_enabled[4] = FALSE)) then
           Move(_temp_operator_enabled,_operator_enabled,SizeOf(_operator_enabled));
         end;
end;

const
  KSL_volume:    array[0..3] of Byte = (0,$80,$40,$0c0);
  AM_Vibrato_EG: array[0..3] of Byte = ($80,$40,$10,$20);
  panning_pos:   array[0..2] of Byte = (1,0,2);

label _jmp1,_end;

begin { INSTRUMENT_CONTROL_edit }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_edit';
{$ENDIF}
  inst := Addr(songdata.instr_data[instrum_page]);
  FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
  If NOT (inst^.perc_voice in [2..5]) then
    If remember_ins_pos then
      begin
        temp := get_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?carrier',-1);
        If (temp <> 2) then carrier := TRUE
        else carrier := FALSE;
      end
    else carrier := TRUE
  else carrier := FALSE;

  If NOT remember_ins_pos then
    begin
      hpos := 1;
      vpos := 1;
    end
  else
    If carrier then
      begin
        hpos := min(get_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?carrier?hpos',-1),1);
        vpos := min(get_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?carrier?vpos',-1),1);
      end
    else begin
           hpos := min(get_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?modulator?hpos',-1),1);
           vpos := min(get_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?modulator?vpos',-1),1);
         end;
_jmp1:
  If _force_program_quit then EXIT;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  HideCursor;

  ScreenMemCopy(screen_ptr,ptr_temp_screen);
  centered_frame_vdest := ptr_temp_screen;
  centered_frame(xstart,ystart,71,24+INSEDIT_yshift,' iNSTRUMENT EDiTOR (iNS_  ) ',
                 instrument_bckg+instrument_border,
                 instrument_bckg+instrument_title,
                 frame_double);
  centered_frame_vdest := screen_ptr;

  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+71+2;
  move_to_screen_area[4] := ystart+24+INSEDIT_yshift+1;
  move2screen_alt;

  move_to_screen_area[1] := xstart+1;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+70;
  move_to_screen_area[4] := ystart+24+INSEDIT_yshift;
  Inc(xstart);

  _page_build;
  _sync_radio_buttons;

  If NOT _force_program_quit then
    Repeat
      keyboard_poll_input;
      _page_build;
      _page_refresh;
      If ((vpos in [1,2,4,5,7]) and (hpos = 1)) or
         ((vpos = 12) and (hpos = 3)) or
         ((vpos = 16) and (hpos = 2)) then
        With songdata.instr_data[current_inst] do
          begin
            Case vpos of
              1: If carrier then
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0(fm_data.ATTCK_DEC_carrier SHR 4-1),
                          ystart+inst_vpos[vpos])
                 else
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0(fm_data.ATTCK_DEC_modulator SHR 4-1),
                          ystart+inst_vpos[vpos]);

              2: If carrier then
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0(fm_data.ATTCK_DEC_carrier AND $0f-1),
                          ystart+inst_vpos[vpos])
                 else
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0(fm_data.ATTCK_DEC_modulator AND $0f-1),
                          ystart+inst_vpos[vpos]);

              4: If carrier then
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0(fm_data.SUSTN_REL_carrier SHR 4-1),
                          ystart+inst_vpos[vpos])
                 else
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0(fm_data.SUSTN_REL_modulator SHR 4-1),
                          ystart+inst_vpos[vpos]);

              5: If carrier then
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0(fm_data.SUSTN_REL_carrier AND $0f-1),
                          ystart+inst_vpos[vpos])
                 else
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0(fm_data.SUSTN_REL_modulator AND $0f-1),
                          ystart+inst_vpos[vpos]);

              7: If carrier then
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0((63-fm_data.KSL_VOLUM_carrier AND $3f) DIV 2-1),
                          ystart+inst_vpos[vpos])
                 else
                   GotoXY(xstart+inst_hpos[vpos,hpos]+
                          min0((63-fm_data.KSL_VOLUM_modulator AND $3f) DIV 2-1),
                          ystart+inst_vpos[vpos]);

             12: GotoXY(xstart+inst_hpos[vpos,hpos]+
                        min0(ROUND(_get_feedback_val*(17/7))-1),
                        ystart+inst_vpos[vpos]);

             16: If (_get_finetune_val > 0) then
                   GotoXY(xstart+inst_hpos[vpos,hpos]+7+_ftune(_get_finetune_val)+1,
                          ystart+inst_vpos[vpos])
                 else If (_get_finetune_val < 0) then
                        GotoXY(xstart+inst_hpos[vpos,hpos]+1+7+_ftune(_get_finetune_val)-1,
                               ystart+inst_vpos[vpos])
                      else
                        GotoXY(xstart+inst_hpos[vpos,hpos]+1+7+_ftune(_get_finetune_val),
                               ystart+inst_vpos[vpos]);
            end;
          SetCursorShape($010c);
        end
      else
        begin
          ThinCursor;
          GotoXY(xstart+inst_hpos[vpos,hpos],ystart+inst_vpos[vpos]);
        end;

      nope := FALSE;
      If keypressed then fkey := getkey else GOTO _end;
      If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
        If (get_4op_to_test <> 0) then
          INSTRUMENT_test(LO(get_4op_to_test),HI(get_4op_to_test),count_channel(pattern_hpos),fkey,TRUE)
        else INSTRUMENT_test(instrum_page,0,count_channel(pattern_hpos),fkey,TRUE);

      Case fkey of
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

        kAltA:   begin hpos := 1; vpos := 1; end;
        kAltD:   begin hpos := 1; vpos := 2; end;
        kAltS:   begin hpos := 1; vpos := 4; end;
        kAltR:   begin hpos := 1; vpos := 5; end;
        kAltO:   begin hpos := 1; vpos := 7; end;

        kAltW:   begin
                   If carrier then vpos := 2+inst^.fm_data.WAVEFORM_carrier
                   else vpos := 2+inst^.fm_data.WAVEFORM_modulator;
                   If (vpos in [2,4,5,7]) then hpos := 2 else hpos := 1;
                 end;

        kAltK:   begin
                   If carrier then temp := inst^.fm_data.KSL_VOLUM_carrier
                   else temp := inst^.fm_data.KSL_VOLUM_modulator;
                   temp := temp SHR 6;
                   temp := temp SHR 1+temp AND 1 SHL 1;
                   vpos := 10+temp;
                   hpos := 1;
                 end;

        kAltP:   Case inst^.panning of
                   1: begin vpos := 17; hpos := 1; end;
                   0: begin vpos := 17; hpos := 2; end;
                   2: begin vpos := 17; hpos := 3; end;
                 end;

        kAltC:   If NOT (inst^.perc_voice in [2..5]) then
                   Case Pos(#11,_curr_connection_str) of
                     1: begin vpos := 12; hpos := 2; end;
                     2: begin vpos := 13; hpos := 2; end;
                     3: begin vpos := 14; hpos := 1; end;
                     4: begin vpos := 15; hpos := 1; end;
                     5: begin vpos := 16; hpos := 1; end;
                     6: begin vpos := 17; hpos := 4; end;
                   end;

        kAltF:   If NOT (inst^.perc_voice in [2..5]) then
                   begin vpos := 12; hpos := 3; end;

        kAltT:   begin vpos := 16; hpos := 2; end;
        kAltE:   begin vpos := 18; hpos := 1; end;

        kAltM:   begin
                   If carrier then temp := inst^.fm_data.AM_VIB_EG_carrier AND $0f
                   else temp := inst^.fm_data.AM_VIB_EG_modulator AND $0f;
                   hpos := 2+(temp MOD 6);
                   vpos := 19+(temp DIV 6);
                 end;

        kLEFT:   If (hpos-1 >= 1) and (inst_hpos[vpos,hpos-1] <> 0) then Dec(hpos)
                 else If (hpos-2 >= 1) and (inst_hpos[vpos,hpos-2] <> 0) then Dec(hpos,2)
                      else If (vpos > 1) then
                             begin
                               Repeat Dec(vpos) until (_check_hpos_idx_r(vpos) <> 0);
                               hpos := _check_hpos_idx_r(vpos);
                             end
                           else
                             begin
                               vpos := inst_vpos_max; hpos := inst_hpos_max;
                               While (hpos > 1) and (inst_hpos[vpos,hpos] = 0) do Dec(hpos);
                             end;

        kRIGHT:  If (hpos+1 <= inst_hpos_max) and (inst_hpos[vpos,hpos+1] <> 0) then Inc(hpos)
                 else If (hpos+2 <= inst_hpos_max) and (inst_hpos[vpos,hpos+2] <> 0) then Inc(hpos,2)
                      else If (vpos < inst_vpos_max) then
                             begin
                               Repeat Inc(vpos) until (_check_hpos_idx_l(vpos) <> 0);
                               hpos := _check_hpos_idx_l(vpos);
                             end
                           else begin vpos := 1; hpos := 1; end;

        kUP:          If (vpos > 1) then
                        begin
                          Repeat Dec(vpos) until (inst_hpos[vpos,1] <> 0);
                     temp := hpos; hpos := inst_hpos_max;
                     While (hpos > 1) and ((inst_hpos[vpos,hpos] = 0) or
                       (inst_hpos[vpos,hpos] > inst_hpos[vpos+1,temp])) do Dec(hpos);
                   end
                 else
                   begin
                     vpos := inst_vpos_max; temp := hpos; hpos := inst_hpos_max;
                     While (hpos > 1) and ((inst_hpos[vpos,hpos] = 0) or
                       (inst_hpos[vpos,hpos] > inst_hpos[vpos+1,temp])) do Dec(hpos);
                   end;

        kDOWN:   If (vpos < inst_vpos_max) then
                   begin
                     Repeat Inc(vpos) until (inst_hpos[vpos,1] <> 0);
                     temp := hpos; hpos := inst_hpos_max;
                     While (hpos > 1) and ((inst_hpos[vpos,hpos] = 0) or
                       (inst_hpos[vpos,hpos] > inst_hpos[vpos-1,temp])) do Dec(hpos);
                   end
                 else
                   begin
                     vpos := 1; temp := hpos; hpos := inst_hpos_max;
                     While (hpos > 1) and ((inst_hpos[vpos,hpos] = 0) or
                       (inst_hpos[vpos,hpos] > inst_hpos[vpos-1,temp])) do Dec(hpos)
                   end;

        kHOME:   begin vpos := 1; hpos := 1; end;

        kEND:    begin
                   vpos := inst_vpos_max; hpos := inst_hpos_max;
                   While (hpos > 1) and (inst_hpos[vpos,hpos] = 0) do Dec(hpos);
                 end;

        kTAB:    Case vpos of
                    1: begin vpos := 2; hpos := 1; end; // ATTACK RATE -> DECAY RATE

                    2: If (hpos = 1) then begin vpos := 4; hpos := 1; end // DECAY RATE -> SUSTAIN LEVEL
                       else begin vpos := 7; hpos := 1; end; // WAVEFORM TYPE -> OUTPUT LEVEL

                    3:  begin vpos := 7; hpos := 1; end; // WAVEFORM TYPE -> OUTPUT LEVEL

                    4: If (hpos = 1) then begin vpos := 5; hpos := 1; end // SUSTAIN LEVEL -> RELEASE RATE
                       else begin vpos := 7; hpos := 1; end; // WAVEFORM TYPE -> OUTPUT LEVEL

                    5: If (hpos = 1) then // RELEASE RATE -> WAVEFORM TYPE
                         begin
                           If carrier then vpos := 2+inst^.fm_data.WAVEFORM_carrier
                           else vpos := 2+inst^.fm_data.WAVEFORM_modulator;
                           If (vpos in [2,4,5,7]) then hpos := 2 else hpos := 1;
                         end
                       else begin vpos := 7; hpos := 1; end; // WAVEFORM TYPE -> OUTPUT LEVEL

                    6: begin vpos := 7; hpos := 1; end; // WAVEFORM TYPE -> OUTPUT LEVEL

                    7: If (hpos = 1) then // OUTPUT LEVEL -> KEY SCALiNG LEVEL
                         begin
                           If carrier then temp := inst^.fm_data.KSL_VOLUM_carrier
                           else temp := inst^.fm_data.KSL_VOLUM_modulator;
                           temp := temp SHR 6;
                           temp := temp SHR 1+temp AND 1 SHL 1;
                           vpos := 10+temp;
                           hpos := 1;
                         end
                       else begin vpos := 7; hpos := 1; end; // WAVEFORM TYPE -> OUTPUT LEVEL

                    8,
                    9: begin vpos := 7; hpos := 1; end; // WAVEFORM TYPE -> OUTPUT LEVEL

                   10,11,12,
                   13: If (hpos = 1) then // KEY SCALING LEVEL -> PANNING
                         Case inst^.panning of
                           1: begin vpos := 17; hpos := 1; end;
                           0: begin vpos := 17; hpos := 2; end;
                           2: begin vpos := 17; hpos := 3; end;
                         end
                       else If (vpos in [12,13]) and (hpos = 2) then // CONNECTION -> FEEDBACK
                              begin vpos := 12; hpos := 3; end
                            else begin vpos := 16; hpos := 2; end; // FEEDBACK -> F-TUNE

                   14,15,
                   16: If (hpos = 1) then // CONNECTION -> FEEDBACK
                         begin vpos := 12; hpos := 3; end
                       else begin vpos := 18; hpos := 1; end; // F-TUNE -> AM/VIB/EG/KSR

                   17: If (hpos in [1,2,3]) then
                         If NOT (inst^.perc_voice in [2..5]) then // PANNING -> CONNECTION
                           Case Pos(#11,_curr_connection_str) of
                             1: begin vpos := 12; hpos := 2; end;
                             2: begin vpos := 13; hpos := 2; end;
                             3: begin vpos := 14; hpos := 1; end;
                             4: begin vpos := 15; hpos := 1; end;
                             5: begin vpos := 16; hpos := 1; end;
                             6: begin vpos := 17; hpos := 3; end;
                           end
                         else begin vpos := 16; hpos := 2; end // PERC:SD/TT/TC/HH == PANNING -> F-TUNE
                       else begin vpos := 12; hpos := 3; end; // CONNECTION -> FEEDBACK

                   18,19,20,
                   21: If (vpos = 18) or (hpos = 1) then // AM/VIB/EG/KSR -> FREQ. DATA MULT.
                         begin
                           If carrier then temp := inst^.fm_data.AM_VIB_EG_carrier AND $0f
                           else temp := inst^.fm_data.AM_VIB_EG_modulator AND $0f;
                           hpos := 2+(temp MOD 6);
                           vpos := 19+(temp DIV 6);
                         end
                       else begin // *NEXT SLOT*
                              vpos := 1;
                              hpos := 1;
                              If NOT (inst^.perc_voice in [2..5]) then
                                begin
                                  carrier := NOT carrier;
                                  If carrier and (get_4op_to_test <> 0) then
                                    begin
                                      If (current_inst = LO(get_4op_to_test)) then current_inst := HI(get_4op_to_test)
                                      else current_inst := LO(get_4op_to_test);
                                      instrum_page := current_inst;
                                      STATUS_LINE_refresh;
                                      inst := Addr(songdata.instr_data[instrum_page]);
                                      _page_build;
                                      _page_refresh;
                                    end;
                                end;
                       end;
                 end;

        kShTAB:  Case vpos of
                    1: begin // *PREVIOUS SLOT*
                         If NOT (inst^.perc_voice in [2..5]) then
                           begin
                             carrier := NOT carrier;
                             If NOT carrier and (get_4op_to_test <> 0) then
                               begin
                                 If (current_inst = LO(get_4op_to_test)) then current_inst := HI(get_4op_to_test)
                                 else current_inst := LO(get_4op_to_test);
                                 instrum_page := current_inst;
                                 STATUS_LINE_refresh;
                                 inst := Addr(songdata.instr_data[instrum_page]);
                                 _page_build;
                                 _page_refresh;
                               end;
                           end;
                         If carrier then temp := inst^.fm_data.AM_VIB_EG_carrier AND $0f
                         else temp := inst^.fm_data.AM_VIB_EG_modulator AND $0f;
                         hpos := 2+(temp MOD 6);
                         vpos := 19+(temp DIV 6);
                       end;

                    2: If (hpos = 1) then begin vpos := 1; hpos := 1; end // DECAY RATE -> ATTACK RATE
                       else begin vpos := 5; hpos := 1; end; // WAVEFORM TYPE -> RELEASE RATE

                    3: begin vpos := 5; hpos := 1; end; // WAVEFORM TYPE -> RELEASE RATE

                    4: If (hpos = 1) then begin vpos := 2; hpos := 1; end
                       else begin vpos := 5; hpos := 1; end; // WAVEFORM TYPE -> RELEASE RATE

                    5: If (hpos = 1) then begin vpos := 4; hpos := 1; end
                       else begin vpos := 5; hpos := 1; end; // WAVEFORM TYPE -> RELEASE RATE

                    6: begin vpos := 5; hpos := 1; end; // WAVEFORM TYPE -> RELEASE RATE

                    7: If (hpos = 1) then // OUTPUT LEVEL -> WAVEFORM TYPE
                         begin
                           If carrier then vpos := 2+inst^.fm_data.WAVEFORM_carrier
                           else vpos := 2+inst^.fm_data.WAVEFORM_modulator;
                           If (vpos in [2,4,5,7]) then hpos := 2 else hpos := 1;
                         end
                       else begin vpos := 5; hpos := 1; end; // WAVEFORM TYPE -> RELEASE RATE
                    8,
                    9: begin vpos := 5; hpos := 1; end; // WAVEFORM TYPE -> RELEASE RATE

                   10,11,12,
                   13: If (hpos = 1) then // KEY SCALING RATE -> OUTPUT LEVEL
                         begin vpos := 7; hpos := 1; end
                       else If (hpos = 2) then // CONNECTION -> PANNING
                              Case inst^.panning of
                                1: begin vpos := 17; hpos := 1; end;
                                0: begin vpos := 17; hpos := 2; end;
                                2: begin vpos := 17; hpos := 3; end;
                              end
                            else Case Pos(#11,_curr_connection_str) of // FEEDBACK -> CONNECTION
                                   1: begin vpos := 12; hpos := 2; end;
                                   2: begin vpos := 13; hpos := 2; end;
                                   3: begin vpos := 14; hpos := 1; end;
                                   4: begin vpos := 15; hpos := 1; end;
                                   5: begin vpos := 16; hpos := 1; end;
                                   6: begin vpos := 17; hpos := 3; end;
                                 end;
                   14,15,
                   16: If (hpos = 1) then // CONNECTION -> PANNING
                         Case inst^.panning of
                           1: begin vpos := 17; hpos := 1; end;
                           0: begin vpos := 17; hpos := 2; end;
                           2: begin vpos := 17; hpos := 3; end;
                         end
                       else If NOT (inst^.perc_voice in [2..5]) then // F-TUNE -> FEEDBACK
                              begin vpos := 12; hpos := 3; end
                            else Case inst^.panning of // PERC:SD/TT/TC/HH == F-TUNE -> PANNING
                                   1: begin vpos := 17; hpos := 1; end;
                                   0: begin vpos := 17; hpos := 2; end;
                                   2: begin vpos := 17; hpos := 3; end;
                                 end;

                   17: If (hpos in [1,2,3]) then // PANNING -> KEY SCALING LEVEL
                         begin
                           If carrier then temp := inst^.fm_data.KSL_VOLUM_carrier
                           else temp := inst^.fm_data.KSL_VOLUM_modulator;
                           temp := temp SHR 6;
                           temp := temp SHR 1+temp AND 1 SHL 1;
                           vpos := 10+temp;
                           hpos := 1;
                         end
                       else Case inst^.panning of // CONNECTION -> PANNING
                              1: begin vpos := 17; hpos := 1; end;
                              0: begin vpos := 17; hpos := 2; end;
                              2: begin vpos := 17; hpos := 3; end;
                            end;

                   18,19,20,
                   21: If (vpos = 18) or (hpos = 1) then
                         begin vpos := 16; hpos := 2; end // AM/VIB/EG/KSR -> F-TUNE
                       else begin vpos := 18; hpos := 1; end; // FREQ. DATA MULT. -> AM/VIB/EG/KSR
                 end;

        kSPACE:  If ctrl_pressed then
                   _ADSR_preview_flag := NOT _ADSR_preview_flag
                 else
                   begin
                     Case vpos of
                       2: If (hpos = 2) then
                            If carrier then inst^.fm_data.WAVEFORM_carrier := 0
                            else inst^.fm_data.WAVEFORM_modulator := 0;

                       3: If carrier then inst^.fm_data.WAVEFORM_carrier := 1
                          else inst^.fm_data.WAVEFORM_modulator := 1;

                       4: If (hpos = 2) then
                            If carrier then inst^.fm_data.WAVEFORM_carrier := 2
                            else inst^.fm_data.WAVEFORM_modulator := 2;

                       5: If (hpos = 2) then
                            If carrier then inst^.fm_data.WAVEFORM_carrier := 3
                            else inst^.fm_data.WAVEFORM_modulator := 3;

                       6: If carrier then inst^.fm_data.WAVEFORM_carrier := 4
                          else inst^.fm_data.WAVEFORM_modulator := 4;

                       7: If (hpos = 2) then
                            If carrier then inst^.fm_data.WAVEFORM_carrier := 5
                            else inst^.fm_data.WAVEFORM_modulator := 5;

                       8: If carrier then inst^.fm_data.WAVEFORM_carrier := 6
                          else inst^.fm_data.WAVEFORM_modulator := 6;

                       9: If carrier then inst^.fm_data.WAVEFORM_carrier := 7
                          else inst^.fm_data.WAVEFORM_modulator := 7;

                      10..16,
                      17: If (vpos in [10..13]) and (hpos = 1) then
                            If carrier then
                              inst^.fm_data.KSL_VOLUM_carrier :=
                              inst^.fm_data.KSL_VOLUM_carrier AND $3f+KSL_volume[vpos-10]
                            else
                              inst^.fm_data.KSL_VOLUM_modulator :=
                              inst^.fm_data.KSL_VOLUM_modulator AND $3f+KSL_volume[vpos-10]
                          else If ((vpos in [12,13]) and (hpos = 2)) or
                                  ((vpos in [14,15,16]) and (hpos = 1)) or
                                  ((vpos = 17) and (hpos = 4)) then
                                 Case vpos  of
                                   12,13: If NOT (get_4op_to_test <> 0) then
                                            inst^.fm_data.FEEDBACK_FM := vpos-12+inst^.fm_data.FEEDBACK_FM AND $0e;
                                   14: If (get_4op_to_test <> 0) then
                                         begin
                                           pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] := 0+
                                           pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] AND $0e;
                                           pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] := 0+
                                           pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] AND $0e;
                                         end;
                                   15: If (get_4op_to_test <> 0) then
                                         begin
                                           pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] := 0+
                                           pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] AND $0e;
                                           pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] := 1+
                                           pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] AND $0e;
                                         end;
                                   16: If (get_4op_to_test <> 0) then
                                         begin
                                           pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] := 1+
                                           pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] AND $0e;
                                           pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] := 0+
                                           pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] AND $0e;
                                         end;
                                   17: If (get_4op_to_test <> 0) then
                                         begin
                                           pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] := 1+
                                           pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] AND $0e;
                                           pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] := 1+
                                           pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] AND $0e;
                                         end;
                                 end
                               else If (vpos = 17) and (hpos in [1..3]) then
                                      inst^.panning := panning_pos[hpos-1];
                      18,19,20,
                      21: If (vpos = 18) or (hpos = 1) then
                            begin
                              If carrier then
                                inst^.fm_data.AM_VIB_EG_carrier :=
                                inst^.fm_data.AM_VIB_EG_carrier XOR AM_Vibrato_EG[vpos-18]
                              else
                                inst^.fm_data.AM_VIB_EG_modulator :=
                                inst^.fm_data.AM_VIB_EG_modulator XOR AM_Vibrato_EG[vpos-18];
                            end
                          else
                            begin
                              If carrier then
                                inst^.fm_data.AM_VIB_EG_carrier :=
                                inst^.fm_data.AM_VIB_EG_carrier AND $0f0+
                                (vpos-19)*6+hpos-2
                              else
                                inst^.fm_data.AM_VIB_EG_modulator :=
                                inst^.fm_data.AM_VIB_EG_modulator AND $0f0+
                                (vpos-19)*6+hpos-2;
                            end;
                     end;
                     reset_instrument_preview;
                   end;
        kPgUP,
        kCHplus,
        kNPplus: begin
                   If carrier then
                     begin
                       If (vpos = 1) and
                          (inst^.fm_data.ATTCK_DEC_carrier SHR 4 < $0f) then
                           inst^.fm_data.ATTCK_DEC_carrier :=
                           inst^.fm_data.ATTCK_DEC_carrier AND $0f+
                          (inst^.fm_data.ATTCK_DEC_carrier SHR 4 +1) SHL 4;

                       If (vpos = 2) and (hpos = 1) and
                          (inst^.fm_data.ATTCK_DEC_carrier AND $0f < $0f) then
                           Inc(inst^.fm_data.ATTCK_DEC_carrier);

                       If (vpos = 4) and (hpos = 1) and
                          (inst^.fm_data.SUSTN_REL_carrier SHR 4 < $0f) then
                           inst^.fm_data.SUSTN_REL_carrier :=
                           inst^.fm_data.SUSTN_REL_carrier AND $0f+
                          (inst^.fm_data.SUSTN_REL_carrier SHR 4 +1) SHL 4;

                       If (vpos = 5) and (hpos = 1) and
                          (inst^.fm_data.SUSTN_REL_carrier AND $0f < $0f) then
                           Inc(inst^.fm_data.SUSTN_REL_carrier);

                       If (vpos = 7) and (hpos = 1) and
                          (inst^.fm_data.KSL_VOLUM_carrier AND $3f > 0) then
                           Dec(inst^.fm_data.KSL_VOLUM_carrier);
                     end
                   else
                     begin
                       If (vpos = 1) and
                          (inst^.fm_data.ATTCK_DEC_modulator SHR 4 < $0f) then
                           inst^.fm_data.ATTCK_DEC_modulator :=
                           inst^.fm_data.ATTCK_DEC_modulator AND $0f+
                          (inst^.fm_data.ATTCK_DEC_modulator SHR 4 +1) SHL 4;

                       If (vpos = 2) and (hpos = 1) and
                          (inst^.fm_data.ATTCK_DEC_modulator AND $0f < $0f) then
                           Inc(inst^.fm_data.ATTCK_DEC_modulator);

                       If (vpos = 4) and (hpos = 1) and
                          (inst^.fm_data.SUSTN_REL_modulator SHR 4 < $0f) then
                           inst^.fm_data.SUSTN_REL_modulator :=
                           inst^.fm_data.SUSTN_REL_modulator AND $0f+
                          (inst^.fm_data.SUSTN_REL_modulator SHR 4 +1) SHL 4;

                       If (vpos = 5) and (hpos = 1) and
                          (inst^.fm_data.SUSTN_REL_modulator AND $0f < $0f) then
                           Inc(inst^.fm_data.SUSTN_REL_modulator);

                       If (vpos = 7) and (hpos = 1) and
                          (inst^.fm_data.KSL_VOLUM_modulator AND $3f > 0) then
                           Dec(inst^.fm_data.KSL_VOLUM_modulator);
                     end;

                   If (vpos = 12) and (hpos = 3) then _inc_feedback_val;
                   If (vpos = 16) and (hpos = 2) then _inc_finetune_val;
                   reset_instrument_preview;
                 end;

        kPgDOWN,
        kCHmins,
        kNPmins: begin
                   If carrier then
                     begin
                       If (vpos = 1) and
                          (inst^.fm_data.ATTCK_DEC_carrier SHR 4 > 0) then
                           inst^.fm_data.ATTCK_DEC_carrier :=
                           inst^.fm_data.ATTCK_DEC_carrier AND $0f+
                          (inst^.fm_data.ATTCK_DEC_carrier SHR 4 -1) SHL 4;

                       If (vpos = 2) and (hpos = 1) and
                          (inst^.fm_data.ATTCK_DEC_carrier AND $0f > 0) then
                           Dec(inst^.fm_data.ATTCK_DEC_carrier);

                       If (vpos = 4) and (hpos = 1) and
                          (inst^.fm_data.SUSTN_REL_carrier SHR 4 > 0) then
                           inst^.fm_data.SUSTN_REL_carrier :=
                           inst^.fm_data.SUSTN_REL_carrier AND $0f+
                          (inst^.fm_data.SUSTN_REL_carrier SHR 4 -1) SHL 4;

                       If (vpos = 5) and (hpos = 1) and
                          (inst^.fm_data.SUSTN_REL_carrier AND $0f > 0) then
                           Dec(inst^.fm_data.SUSTN_REL_carrier);

                       If (vpos = 7) and (hpos = 1) and
                          (inst^.fm_data.KSL_VOLUM_carrier AND $3f < $3f) then
                           Inc(inst^.fm_data.KSL_VOLUM_carrier);
                     end
                   else
                     begin
                       If (vpos = 1) and
                          (inst^.fm_data.ATTCK_DEC_modulator SHR 4 > 0) then
                           inst^.fm_data.ATTCK_DEC_modulator :=
                           inst^.fm_data.ATTCK_DEC_modulator AND $0f+
                          (inst^.fm_data.ATTCK_DEC_modulator SHR 4 -1) SHL 4;

                       If (vpos = 2) and (hpos = 1) and
                          (inst^.fm_data.ATTCK_DEC_modulator AND $0f > 0) then
                           Dec(inst^.fm_data.ATTCK_DEC_modulator);

                       If (vpos = 4) and (hpos = 1) and
                          (inst^.fm_data.SUSTN_REL_modulator SHR 4 > 0) then
                           inst^.fm_data.SUSTN_REL_modulator :=
                           inst^.fm_data.SUSTN_REL_modulator AND $0f+
                          (inst^.fm_data.SUSTN_REL_modulator SHR 4 -1) SHL 4;

                       If (vpos = 5) and (hpos = 1) and
                          (inst^.fm_data.SUSTN_REL_modulator AND $0f > 0) then
                           Dec(inst^.fm_data.SUSTN_REL_modulator);

                       If (vpos = 7) and (hpos = 1) and
                          (inst^.fm_data.KSL_VOLUM_modulator AND $3f < $3f) then
                           Inc(inst^.fm_data.KSL_VOLUM_modulator);
                     end;

                   If (vpos = 12) and (hpos = 3) then _dec_feedback_val;
                   If (vpos = 16) and (hpos = 2) then _dec_finetune_val;
                   reset_instrument_preview;
                 end;

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
                        reset_marked_instruments;
                        instrum_page := current_inst;
                        STATUS_LINE_refresh;
                        inst := Addr(songdata.instr_data[instrum_page]);
                        If NOT (inst^.perc_voice in [2..5]) then carrier := TRUE
                        else carrier := FALSE;
                        FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
                        _page_build;
                        _page_refresh;
                        _sync_radio_buttons;
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
                        reset_marked_instruments;
                        instrum_page := current_inst;
                        STATUS_LINE_refresh;
                        inst := Addr(songdata.instr_data[instrum_page]);
                        If NOT (inst^.perc_voice in [2..5]) then carrier := TRUE
                        else carrier := FALSE;
                        FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
                        _page_build;
                        _page_refresh;
                        _sync_radio_buttons;
                      end;

        kF1:     begin
                   Dec(xstart);
                   HideCursor;
                   move_to_screen_data := ptr_screen_backup;
                   move_to_screen_area[1] := xstart;
                   move_to_screen_area[2] := ystart;
                   move_to_screen_area[3] := xstart+71+2;
                   move_to_screen_area[4] := ystart+24+INSEDIT_yshift+1;
                   move2screen;
                   HELP('instrument_editor');
                   GOTO _jmp1;
                 end;
        kF2,
        kCtrlS:  begin
                   Dec(xstart);
                   HideCursor;
                   move_to_screen_data := ptr_screen_backup;
                   move_to_screen_area[1] := xstart;
                   move_to_screen_area[2] := ystart;
                   move_to_screen_area[3] := xstart+71+2;
                   move_to_screen_area[4] := ystart+24+INSEDIT_yshift+1;
                   move2screen;

                   quick_cmd := FALSE;
                   FILE_save('a2i');
                   GOTO _jmp1;
                 end;

        kShF2:   begin
                   Dec(xstart);
                   HideCursor;
                   move_to_screen_data := ptr_screen_backup;
                   move_to_screen_area[1] := xstart;
                   move_to_screen_area[2] := ystart;
                   move_to_screen_area[3] := xstart+71+2;
                   move_to_screen_area[4] := ystart+24+INSEDIT_yshift+1;
                   move2screen;

                   quick_cmd := FALSE;
                   FILE_save('a2f');
                   GOTO _jmp1;
                 end;
        kF3,
        kCtrlL:  begin
                   Dec(xstart);
                   HideCursor;
                   move_to_screen_data := ptr_screen_backup;
                   move_to_screen_area[1] := xstart;
                   move_to_screen_area[2] := ystart;
                   move_to_screen_area[3] := xstart+71+2;
                   move_to_screen_area[4] := ystart+24+INSEDIT_yshift+1;
                   move2screen;

                   FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
                   quick_cmd := FALSE;
                   FILE_open('*.a2i$*.a2f$*.a2b$*.a2w$'+
                             '*.bnk$*.cif$*.fib$*.fin$*.ibk$*.ins$*.sbi$*.sgi$',FALSE);// load bank is not possible
                   reset_instrument_preview;
                   GOTO _jmp1;
                 end;

        kF7:     For temp := 1 to 20 do reset_chan_data(temp);

        kCtrlO:  begin
                   Dec(xstart);
                   HideCursor;
                   move_to_screen_data := ptr_screen_backup;
                   move_to_screen_area[1] := xstart;
                   move_to_screen_area[2] := ystart;
                   move_to_screen_area[3] := xstart+71+2;
                   move_to_screen_area[4] := ystart+24+INSEDIT_yshift+1;
                   move2screen;
                   OCTAVE_CONTROL;
                   GOTO _jmp1;
                 end;

        kCtrlQ:  begin
                   Dec(xstart);
                   HideCursor;
                   move_to_screen_data := ptr_screen_backup;
                   move_to_screen_area[1] := xstart;
                   move_to_screen_area[2] := ystart;
                   move_to_screen_area[3] := xstart+71+2;
                   move_to_screen_area[4] := ystart+24+INSEDIT_yshift+1;
                   move2screen;
                   MACRO_EDITOR(current_inst,FALSE);
                   GOTO _jmp1;
                 end;

        kCtrlE:  begin
                   Dec(xstart);
                   HideCursor;
                   move_to_screen_data := ptr_screen_backup;
                   move_to_screen_area[1] := xstart;
                   move_to_screen_area[2] := ystart;
                   move_to_screen_area[3] := xstart+71+2;
                   move_to_screen_area[4] := ystart+24+INSEDIT_yshift+1;
                   move2screen;
                   MACRO_EDITOR(current_inst,TRUE);
                   GOTO _jmp1;
                 end;

        kENTER:  If NOT (inst^.perc_voice in [2..5]) then
                   If NOT shift_pressed then
                     begin
                       If remember_ins_pos then
                         If carrier then
                           begin
                             add_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?carrier?hpos',-1,hpos);
                             add_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?carrier?vpos',-1,vpos);
                           end
                         else begin
                                add_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?modulator?hpos',-1,hpos);
                                add_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?modulator?vpos',-1,vpos);
                              end;
                       carrier := NOT carrier;
                       If carrier and
                          (get_4op_to_test <> 0) then
                         begin
                           If (current_inst = LO(get_4op_to_test)) then current_inst := HI(get_4op_to_test)
                           else current_inst := LO(get_4op_to_test);
                           instrum_page := current_inst;
                           STATUS_LINE_refresh;
                           inst := Addr(songdata.instr_data[instrum_page]);
                           _page_build;
                           _page_refresh;
                         end;
                       _sync_radio_buttons;
                     end
                   else
                     With songdata.instr_data[instrum_page].fm_data do
                       If carrier then
                         begin
                           ATTCK_DEC_carrier := ATTCK_DEC_modulator;
                           AM_VIB_EG_carrier := AM_VIB_EG_modulator;
                           KSL_VOLUM_carrier := KSL_VOLUM_modulator;
                           SUSTN_REL_carrier := SUSTN_REL_modulator;
                           WAVEFORM_carrier  := WAVEFORM_modulator;
                         end
                       else
                         begin
                           AM_VIB_EG_modulator := AM_VIB_EG_carrier;
                           KSL_VOLUM_modulator := KSL_VOLUM_carrier;
                           ATTCK_DEC_modulator := ATTCK_DEC_carrier;
                           SUSTN_REL_modulator := SUSTN_REL_carrier;
                           WAVEFORM_modulator  := WAVEFORM_carrier;
                         end;
        else nope := TRUE;
      end;

    If shift_pressed and (UpCase(CHR(LO(fkey))) in ['M','O','B','S','T','C','H']) then
      begin
        If (UpCase(CHR(LO(fkey))) = 'O') then
          begin
            songdata.instr_data[instrum_page].perc_voice := 0;
            If (instrum_page <> 255) then songdata.instr_data[SUCC(instrum_page)].perc_voice := 0
            else songdata.instr_data[PRED(instrum_page)].perc_voice := 0;
            If (instrum_page <> 255) then
              If check_4op_flag(instrum_page) then
                reset_4op_flag(instrum_page)
              else set_4op_flag(instrum_page)
            else If check_4op_flag(PRED(instrum_page)) then
                   reset_4op_flag(PRED(instrum_page))
                 else set_4op_flag(PRED(instrum_page));
            update_4op_flag_marks;
          end
        else If NOT check_4op_flag(instrum_page) then
               Case UpCase(CHR(LO(fkey))) of
                 'M': inst^.perc_voice := 0;
                 'B': inst^.perc_voice := 1;
                 'S': inst^.perc_voice := 2;
                 'T': inst^.perc_voice := 3;
                 'C': inst^.perc_voice := 4;
                 'H': inst^.perc_voice := 5;
               end;
        update_4op_flag_marks;
      end;
_end:
{$IFDEF GO32V2}
    keyboard_reset_buffer_alt;
{$ELSE}
    draw_screen;
{$ENDIF}
  until (nope and (fkey = kESC)) or _force_program_quit;

  FillChar(_operator_enabled,SizeOf(_operator_enabled),TRUE);
  If remember_ins_pos then
    begin
      add_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?carrier',-1,_carrier_flag[carrier]);
      If carrier then
        begin
          add_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?carrier?hpos',-1,hpos);
          add_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?carrier?vpos',-1,vpos);
        end
      else begin
             add_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?modulator?hpos',-1,hpos);
             add_bank_position('?instrument_editor?'+byte2hex(instrum_page)+'?modulator?vpos',-1,vpos);
           end;
    end;

  Dec(xstart);
  HideCursor;
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+71+2;
  move_to_screen_area[4] := ystart+24+INSEDIT_yshift+1;
  move2screen;
end;

procedure copy_object;

var
  temp: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:copy_object';
{$ENDIF}
  Case clipboard.object_type of
    objInstrument:
      begin
        clipboard.instrument.names[1] :=
                  Copy(songdata.instr_names[instrum_page],10,32);
        clipboard.instrument.data[1] := songdata.instr_data[instrum_page];
      end;

    objInstrumentWithMacros:
      begin
        clipboard.instrument.names[1] :=
                  Copy(songdata.instr_names[instrum_page],10,32);
        clipboard.instrument.data[1] := songdata.instr_data[instrum_page];
        clipboard.instrument.macros[1] := songdata.instr_macros[instrum_page];
        clipboard.instrument.dis_fmreg_col[1] := songdata.dis_fmreg_col[instrum_page];
      end;

    objInstrumentBank:
      For temp := 1 to 255 do
        begin
          clipboard.instrument.names[temp] :=
                    Copy(songdata.instr_names[temp],10,32);
          clipboard.instrument.data[temp] := songdata.instr_data[temp];
          clipboard.instrument.macros[temp] := songdata.instr_macros[temp];
          clipboard.instrument.arpvib[temp] := songdata.macro_table[temp];
          clipboard.instrument.dis_fmreg_col[temp] := songdata.dis_fmreg_col[temp];
        end;
  end;
end;

procedure paste_object(mode: Byte);

var
  temp: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:paste_object';
{$ENDIF}
  Case clipboard.object_type of
    objInstrument:
      Case mode of
        0: begin
             songdata.instr_names[instrum_page] :=
                      Copy(songdata.instr_names[instrum_page],1,9)+
                      clipboard.instrument.names[1];
             songdata.instr_data[instrum_page] := clipboard.instrument.data[1];
             reset_instrument_preview;
           end;

        1: begin
             songdata.instr_data[instrum_page] := clipboard.instrument.data[1];
             reset_instrument_preview;
           end;

        2: songdata.instr_names[instrum_page] :=
                    Copy(songdata.instr_names[instrum_page],1,9)+
                    clipboard.instrument.names[1];
      end;

    objInstrumentWithMacros:
      Case mode of
        0: begin
             songdata.instr_names[instrum_page] :=
                      Copy(songdata.instr_names[instrum_page],1,9)+
                      clipboard.instrument.names[1];
             songdata.instr_data[instrum_page] := clipboard.instrument.data[1];
             songdata.instr_macros[instrum_page] := clipboard.instrument.macros[1];
             songdata.dis_fmreg_col[instrum_page] := clipboard.instrument.dis_fmreg_col[1];
             reset_instrument_preview;
           end;

        1: begin
             songdata.instr_data[instrum_page] := clipboard.instrument.data[1];
             songdata.instr_macros[instrum_page] := clipboard.instrument.macros[1];
             songdata.dis_fmreg_col[instrum_page] := clipboard.instrument.dis_fmreg_col[1];
             reset_instrument_preview;
           end;

        2: songdata.instr_names[instrum_page] :=
                    Copy(songdata.instr_names[instrum_page],1,9)+
                    clipboard.instrument.names[1];
      end;

    objInstrumentBank:
      For temp := 1 to 255 do
        Case mode of
          0: begin
               songdata.instr_names[temp] :=
                        Copy(songdata.instr_names[temp],1,9)+
                        clipboard.instrument.names[temp];
               songdata.instr_data[temp] := clipboard.instrument.data[temp];
               songdata.instr_macros[temp] := clipboard.instrument.macros[temp];
               songdata.macro_table[temp] := clipboard.instrument.arpvib[temp];
               songdata.dis_fmreg_col[temp] := clipboard.instrument.dis_fmreg_col[temp];
               update_instr_data(temp);
             end;

          1: begin
               songdata.instr_data[temp] := clipboard.instrument.data[temp];
               songdata.instr_macros[temp] := clipboard.instrument.macros[temp];
               songdata.macro_table[temp] := clipboard.instrument.arpvib[temp];
               songdata.dis_fmreg_col[temp] := clipboard.instrument.dis_fmreg_col[temp];
               update_instr_data(temp);
             end;

          2: songdata.instr_names[temp] :=
                      Copy(songdata.instr_names[temp],1,9)+
                      clipboard.instrument.names[temp];
        end;
  end;
end;

procedure instr_control_ai;

var
  temp,temp2: Byte;
  iflag: array[1..18] of Byte;
  istr: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:instr_control_ai';
{$ENDIF}
  istr := '';
  For temp := 1 to 18 do
    iflag[temp] := ai_table[mn_environment.curr_page+temp-1];

  For temp2 := 1 to 18 do
    begin
      For temp := 1 to songdata.nm_tracks do
        If (event_table[temp].instr_def = mn_environment.curr_page+temp2-1) then
          If channel_flag[temp] then
            If event_new[temp] and (iflag[temp] < 2) then iflag[temp2] := 2
            else If (iflag[temp2] < 1) then iflag[temp2] := 1;

      Case iflag[temp2] of
        0: istr := istr+#28;
        1: istr := istr+'~'#28'~';
        2: istr := istr+'`'#11'`';
      end;
    end;

  For temp := 1 to 18 do
    If (iflag[temp] <> 0) then
      ai_table[mn_environment.curr_page+temp-1] := 1;

  ShowVC3Str(mn_environment.v_dest,
             INSCTRL_xshift+37,
             INSCTRL_yshift+07,
             istr,
             dialog_background+instrument_ai_off,
             dialog_background+instrument_ai_on,
             dialog_background+instrument_ai_trig);
end;

procedure instr_control_proc;

var
  temp,temp2,ins1,ins2: Byte;
  temps: String;
  ins_4op,ins_4op_2: Word;
  temp_inst: Record
               name:   String;
               data:   tADTRACK2_INS;
               macros: tREGISTER_TABLE;
             end;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:instr_control_proc';
{$ENDIF}
  Case mn_environment.keystroke of
      kCtLEFT: If NOT debugging and (play_status = isPlaying) then
                 rewind := TRUE;

      kCtRGHT: If NOT debugging and (play_status = isPlaying) then
                 fast_forward := TRUE;
      kCHmins,
      kNPmins,
      kCtHOME: If (play_status <> isStopped) then
                 If NOT mn_environment.is_editing then
                   If NOT play_single_patt then
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
                               If (mn_environment.keystroke = kCtHOME) then calibrate_player(temp,temp2,TRUE,FALSE)
                               else calibrate_player(temp,0,TRUE,FALSE);
                             end;
                         end;
                     end;
      kCHplus,
      kNPplus,
      kCtEND:  If (play_status <> isStopped) then
                 If NOT mn_environment.is_editing then
                   If NOT play_single_patt then
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
                               If (mn_environment.keystroke = kCtEND) then calibrate_player(temp,temp2,TRUE,FALSE)
                               else calibrate_player(temp,0,TRUE,FALSE);
                             end;
                         end;
                     end;

      kF5:     If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                 end
               else
                 Case play_status of
                   isPlaying: begin
                                debugging := FALSE;
                                If NOT nosync_by_default or nosync_by_default then
                                  no_sync_playing := TRUE;
                              end;

                   isPaused:  begin
                                debugging := FALSE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;
                                If NOT nosync_by_default or nosync_by_default then
                                  no_sync_playing := TRUE;
                              end;

                   isStopped: begin
                                If NOT nosync_by_default or nosync_by_default then
                                  no_sync_playing := TRUE;
                                start_playing;
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

      kF7:     If (play_status <> isStopped) then
                 begin
                   fade_out_playback(FALSE);
                   stop_playing;
                   PATTERN_ORDER_page_refresh(pattord_page);
                   PATTERN_page_refresh(pattern_page);
                 end
               else For temp := 1 to 20 do reset_chan_data(temp);

      kF9:     If play_single_patt and (play_status = isPaused) then
                 begin
                   replay_forbidden := FALSE;
                   play_status := isPlaying;
                 end
               else
                 Case play_status of
                   isPlaying: begin
                                debugging := FALSE;
                                repeat_pattern := TRUE;
                                If NOT nosync_by_default or nosync_by_default then
                                  no_sync_playing := TRUE;
                              end;

                   isPaused:  begin
                                debugging := FALSE;
                                repeat_pattern := TRUE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;
                                If NOT nosync_by_default or nosync_by_default then
                                  no_sync_playing := TRUE;
                              end;

                   isStopped: begin
                                start_playing;
                                debugging := FALSE;
                                repeat_pattern := TRUE;
                                replay_forbidden := FALSE;
                                play_status := isPlaying;
                                If NOT nosync_by_default or nosync_by_default then
                                  no_sync_playing := TRUE;
                              end;
                 end;

    kCtrlC:  begin
               If NOT shift_pressed then clipboard.object_type := objInstrument
               else clipboard.object_type := objInstrumentWithMacros;
               copy_object;
             end;

    kAltP:   begin
               paste_object(0);
               mn_environment.do_refresh := TRUE;
               mn_environment.refresh;
             end;

    kCtrlV:  begin
               If NOT shift_pressed then paste_object(0) else paste_object(1);
               mn_environment.do_refresh := TRUE;
               mn_environment.refresh;
             end;

    kAltV:   begin
               If NOT shift_pressed then paste_object(2);
               mn_environment.do_refresh := TRUE;
               mn_environment.refresh;
             end;

    kCtrlW:  If (marked_instruments = 2) then
               begin
                 ins1 := 1;
                 While (songdata.instr_names[ins1][1] <> _ins_mark_chr) do Inc(ins1);
                 ins2 := SUCC(ins1);
                 While (songdata.instr_names[ins2][1] <> _ins_mark_chr) do Inc(ins2);

                 ins_4op := check_4op_instrument(ins1);
                 ins_4op_2 := check_4op_instrument(ins2);
                 If NOT ((ins_4op <> 0) and (ins_4op_2 <> 0)) then
                   begin
                     temp_inst.name   := songdata.instr_names[ins1];
                     temp_inst.data   := songdata.instr_data[ins1];
                     temp_inst.macros := songdata.instr_macros[ins1];
                     songdata.instr_macros[ins1] := songdata.instr_macros[ins2];
                     songdata.instr_macros[ins2] := temp_inst.macros;
                     songdata.instr_data[ins1] := songdata.instr_data[ins2];
                     update_instr_data(ins1);
                     songdata.instr_data[ins2] := temp_inst.data;
                     update_instr_data(ins2);
                     If NOT shift_pressed then
                       begin
                         songdata.instr_names[ins1] :=
                           Copy(songdata.instr_names[ins1],1,9)+
                           Copy(songdata.instr_names[ins2],10,32);
                         songdata.instr_names[ins2] :=
                           Copy(songdata.instr_names[ins2],1,9)+
                           Copy(temp_inst.name,10,32);
                       end;
                   end
                 else begin
                        // 4OP 1/2
                        temp_inst.name   := songdata.instr_names[HI(ins_4op)];
                        temp_inst.data   := songdata.instr_data[HI(ins_4op)];
                        temp_inst.macros := songdata.instr_macros[HI(ins_4op)];
                        songdata.instr_macros[HI(ins_4op)] := songdata.instr_macros[HI(ins_4op_2)];
                        songdata.instr_macros[HI(ins_4op_2)] := temp_inst.macros;
                        songdata.instr_data[HI(ins_4op)] := songdata.instr_data[HI(ins_4op_2)];
                        update_instr_data(HI(ins_4op));
                        songdata.instr_data[HI(ins_4op_2)] := temp_inst.data;
                        update_instr_data(HI(ins_4op_2));
                        If NOT shift_pressed then
                          begin
                            songdata.instr_names[HI(ins_4op)] :=
                              Copy(songdata.instr_names[HI(ins_4op)],1,9)+
                              Copy(songdata.instr_names[HI(ins_4op_2)],10,32);
                            songdata.instr_names[HI(ins_4op_2)] :=
                              Copy(songdata.instr_names[HI(ins_4op_2)],1,9)+
                              Copy(temp_inst.name,10,32);
                          end;
                        // 4OP 2/2
                        temp_inst.name   := songdata.instr_names[LO(ins_4op)];
                        temp_inst.data   := songdata.instr_data[LO(ins_4op)];
                        temp_inst.macros := songdata.instr_macros[LO(ins_4op)];
                        songdata.instr_macros[LO(ins_4op)] := songdata.instr_macros[LO(ins_4op_2)];
                        songdata.instr_macros[LO(ins_4op_2)] := temp_inst.macros;
                        songdata.instr_data[LO(ins_4op)] := songdata.instr_data[LO(ins_4op_2)];
                        update_instr_data(LO(ins_4op));
                        songdata.instr_data[LO(ins_4op_2)] := temp_inst.data;
                        update_instr_data(LO(ins_4op_2));
                        If NOT shift_pressed then
                          begin
                            songdata.instr_names[LO(ins_4op)] :=
                              Copy(songdata.instr_names[LO(ins_4op)],1,9)+
                              Copy(songdata.instr_names[LO(ins_4op_2)],10,32);
                            songdata.instr_names[LO(ins_4op_2)] :=
                              Copy(songdata.instr_names[LO(ins_4op_2)],1,9)+
                              Copy(temp_inst.name,10,32);
                          end;
                      end;
                 mn_environment.do_refresh := TRUE;
                 mn_environment.refresh;
               end;

    kTAB:    reset_marked_instruments;

    kSPACE:  begin
               If (songdata.instr_names[instrum_page][1] <> _ins_mark_chr) then
                 If (marked_instruments < 2) then
                   songdata.instr_names[instrum_page][1] := _ins_mark_chr
                 else begin
                        reset_marked_instruments;
                        songdata.instr_names[instrum_page][1] := _ins_mark_chr;
                      end
               else reset_marked_instruments;

               mn_environment.do_refresh := TRUE;
               mn_environment.refresh;
             end;
  end;

  instrum_page := mn_environment.curr_pos;
  current_inst := instrum_page;

  If shift_pressed and (UpCase(CHR(LO(mn_environment.keystroke))) in ['M','O','B','S','T','C','H']) then
    If (UpCase(CHR(LO(mn_environment.keystroke))) = 'O') then
      begin
        songdata.instr_data[current_inst].perc_voice := 0;
        If (current_inst <> 255) then songdata.instr_data[SUCC(current_inst)].perc_voice := 0
        else songdata.instr_data[PRED(current_inst)].perc_voice := 0;
        If (current_inst <> 255) then
          If check_4op_flag(current_inst) then
            reset_4op_flag(current_inst)
          else set_4op_flag(current_inst)
        else If check_4op_flag(PRED(current_inst)) then
               reset_4op_flag(PRED(current_inst))
             else set_4op_flag(PRED(current_inst));
        update_4op_flag_marks;
        mn_environment.do_refresh := TRUE;
        mn_environment.refresh;
      end
    else If NOT check_4op_flag(current_inst) then
           Case UpCase(CHR(LO(mn_environment.keystroke))) of
             'M': songdata.instr_data[current_inst].perc_voice := 0;
             'B': songdata.instr_data[current_inst].perc_voice := 1;
             'S': songdata.instr_data[current_inst].perc_voice := 2;
             'T': songdata.instr_data[current_inst].perc_voice := 3;
             'C': songdata.instr_data[current_inst].perc_voice := 4;
             'H': songdata.instr_data[current_inst].perc_voice := 5;
           end;

  INSTRUMENT_CONTROL_page_refresh(instrum_page);
  If (get_4op_to_test <> 0) and (songdata.flag_4op <> 0) then
    begin
      temps := connection_str[pBYTE(@Addr(songdata.instr_data[HI(get_4op_to_test)])^)[_instr_data_ofs[11]] AND 1]+'/'+
               connection_str[pBYTE(@Addr(songdata.instr_data[LO(get_4op_to_test)])^)[_instr_data_ofs[11]] AND 1];
      ShowCStr(mn_environment.v_dest,INSCTRL_xshift+39,INSCTRL_yshift+26,
               ' ~[~'#244+byte2hex(HI(get_4op_to_test))+
               ','#245+byte2hex(LO(get_4op_to_test))+' '+temps+'~]~ ',
               dialog_background+dialog_context,
               dialog_background+dialog_border);
    end
  else If (check_4op_to_test <> 0) then
          ShowCStr(mn_environment.v_dest,INSCTRL_xshift+39,INSCTRL_yshift+26,
                   ExpStrR(' ~[~'#2#3' MODE~]~ ',17,#205),
                   dialog_background+dialog_context,
                   dialog_background+dialog_border)
       else ShowStr(mn_environment.v_dest,INSCTRL_xshift+39,INSCTRL_yshift+26,
                    ExpStrL('',17,#205),
                    dialog_background+dialog_border);

  If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
    If (get_4op_to_test <> 0) then
      INSTRUMENT_test(LO(get_4op_to_test),HI(get_4op_to_test),count_channel(pattern_hpos),mn_environment.keystroke,TRUE)
    else INSTRUMENT_test(instrum_page,0,count_channel(pattern_hpos),mn_environment.keystroke,TRUE);
end;

function INSTRUMENT_CONTROL: Byte;

const
  new_keys: array[1..20] of Word = (kESC,kENTER,kTAB,kShTAB,kCtrlO,kCtrlM,kAltC,kCtrlA,kCtrlQ,kCtrlE,
                                    kF1,kF2,kF4,kAltF2,kCtrlF2,kCtrlS,kShF2,kF3,kCtrlL,kShF3);
var
  old_keys: array[1..20] of Word;
  temp: Byte;

label _jmp1;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL';
{$ENDIF}
  update_4op_flag_marks;
  songdata_crc := Update32(songdata,SizeOf(songdata),0);

  _jmp1:
  If _force_program_quit then EXIT;

  keyboard_reset_buffer;
  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  mn_environment.v_dest := ptr_temp_screen;
  ScreenMemCopy(screen_ptr,mn_environment.v_dest);

  mn_setting.center_box := FALSE;
  mn_setting.cycle_moves := FALSE;
  mn_environment.edit_pos := 9;
  mn_environment.ext_proc := @instr_control_proc;
  mn_environment.ext_proc_rt := @instr_control_ai;
  mn_environment.context := ' TAB '#196#16' EDiTOR ';

  Move(mn_setting.terminate_keys,old_keys,SizeOf(old_keys));
  Move(new_keys,mn_setting.terminate_keys,SizeOf(new_keys));

  Frame(ptr_temp_screen,INSCTRL_xshift+07,INSCTRL_yshift+05,
        INSCTRL_xshift+83,INSCTRL_yshift+26,
        dialog_background+dialog_border,
        ' iNSTRUMENT CONTROL (iNS_  ) ',
        dialog_background+dialog_title,
        frame_double);

  fr_setting.update_area := FALSE;
  fr_setting.shadow_enabled := FALSE;
  Frame(ptr_temp_screen,INSCTRL_xshift+09,INSCTRL_yshift+06,
        INSCTRL_xshift+34,INSCTRL_yshift+25,
        dialog_background+dialog_border,
        '',
        dialog_background+dialog_title,
        frame_single);
  Frame(ptr_temp_screen,INSCTRL_xshift+36,INSCTRL_yshift+06,
        INSCTRL_xshift+81,INSCTRL_yshift+25,
        dialog_background+dialog_border,
        '',
        dialog_background+dialog_title,
        frame_single);

  ShowStr(ptr_temp_screen,INSCTRL_xshift+66,INSCTRL_yshift+25,
                         ' TAB '#196#16' EDITOR ',
                          dialog_background+dialog_context);
  ShowStr(ptr_temp_screen,INSCTRL_xshift+58,INSCTRL_yshift+26,
                         ' [SHiFT] TAB '#196#16' MACROS ',
                          dialog_background+dialog_context);

  ShowVStr(mn_environment.v_dest,INSCTRL_xshift+37,INSCTRL_yshift+07,
           ExpStrL('',18,#28),
           dialog_background+instrument_ai_off);
  ShowVStr(mn_environment.v_dest,INSCTRL_xshift+38,INSCTRL_yshift+06,
           #194+ExpStrL('',18,#179)+#193,
           dialog_background+dialog_border);

  fr_setting.shadow_enabled := TRUE;

  color_table[1] := dialog_background+dialog_context_dis;
  color_table[2] := dialog_background+dialog_mod_text;
  color_table[3] := dialog_background+dialog_car_text;

  If (ins_parameter(instrum_page,10) AND 1 <> 1) then
    For temp := 1 to 18 do
      ShowCStr(ptr_temp_screen,INSCTRL_xshift+10,INSCTRL_yshift+06+temp,inst_itm1[temp].str,
               dialog_background+dialog_contxt_dis2,
               color_table[inst_itm1[temp].colr])
  else
    For temp := 1 to 18 do
      ShowCStr(ptr_temp_screen,INSCTRL_xshift+10,INSCTRL_yshift+06+temp,inst_itm2[temp].str,
               dialog_background+dialog_contxt_dis2,
               color_table[inst_itm2[temp].colr]);

  mn_setting.edit_contents := TRUE;
  mn_setting.shadow_enabled := FALSE;
  mn_setting.frame_enabled := FALSE;
  mn_environment.unpolite := FALSE;
  mn_environment.preview := TRUE;
  mn_environment.hlight_chrs := 1;

  If NOT _force_program_quit then
    Menu(songdata.instr_names,INSCTRL_xshift+38,INSCTRL_yshift+06,instrum_page,42,18,255,'');

  INSTRUMENT_CONTROL_page_refresh(instrum_page);
  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := INSCTRL_xshift+7;
  move_to_screen_area[2] := INSCTRL_yshift+5;
  move_to_screen_area[3] := INSCTRL_xshift+83+2;
  move_to_screen_area[4] := INSCTRL_yshift+26+1;
  move2screen_alt;

  mn_environment.v_dest := screen_ptr;
  If NOT _force_program_quit then
    temp := Menu(songdata.instr_names,INSCTRL_xshift+38,INSCTRL_yshift+06,instrum_page,42,18,255,'');

  reset_marked_instruments;
  mn_environment.unpolite := FALSE;
  mn_environment.preview := FALSE;
  mn_setting.frame_enabled := TRUE;
  mn_setting.shadow_enabled := TRUE;
  fr_setting.update_area := TRUE;
  mn_setting.center_box  := TRUE;
  mn_environment.context := '';

  Move(old_keys,mn_setting.terminate_keys,SizeOf(old_keys));
  mn_setting.edit_contents := FALSE;
  mn_environment.ext_proc := NIL;
  mn_environment.ext_proc_rt := NIL;
  mn_environment.hlight_chrs := 0;

  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := INSCTRL_xshift+7;
  move_to_screen_area[2] := INSCTRL_yshift+5;
  move_to_screen_area[3] := INSCTRL_xshift+83+2;
  move_to_screen_area[4] := INSCTRL_yshift+26+1;
  move2screen;

  Case mn_environment.keystroke of
    kAltC:   begin
               mn_setting.cycle_moves := TRUE;
               temp := Menu(copy_menu_str1,01,01,copypos1,30,15,15,' COPY OBJECT ');
               If (mn_environment.keystroke <> kESC) then
                 begin
                   copypos1 := temp;
                   clipboard.object_type := tCOPY_OBJECT(temp);
                   copy_object;
                 end;
               GOTO _jmp1;
             end;

    kTAB:    begin
               If (get_4op_to_test <> 0) then
                 begin
                   If (songdata.instr_data[HI(get_4op_to_test)].perc_voice <> 0) then
                     songdata.instr_data[HI(get_4op_to_test)].perc_voice := 0;
                   If (songdata.instr_data[LO(get_4op_to_test)].perc_voice <> 0) then
                     songdata.instr_data[LO(get_4op_to_test)].perc_voice := 0;
                 end;
               INSTRUMENT_CONTROL_edit;
               GOTO _jmp1;
             end;

    kCtrlQ,
    kShTAB:  begin
               MACRO_EDITOR(instrum_page,FALSE);
               GOTO _jmp1;
             end;

    kCtrlO:  begin
               OCTAVE_CONTROL;
               mn_environment.keystroke := BYTE_NULL;
               GOTO _jmp1;
             end;

    kCtrlE:  begin
               MACRO_EDITOR(current_inst,TRUE);
               GOTO _jmp1;
             end;

    kCtrlM:  begin
               MACRO_BROWSER(TRUE,TRUE);
               GOTO _jmp1;
             end;

    kF1:     begin HELP('instrument_control'); GOTO _jmp1; end;
    kF2,
    kCtrlS:  begin
               quick_cmd := FALSE;
               FILE_save('a2i');
               GOTO _jmp1;
             end;

    kAltF2:  begin
               quick_cmd := FALSE;
               FILE_save('a2b');
               GOTO _jmp1;
             end;

    kShF2:   begin
               quick_cmd := FALSE;
               FILE_save('a2f');
               GOTO _jmp1;
             end;

    kCtrlF2: begin
               quick_cmd := FALSE;
               FILE_save('a2w');
               GOTO _jmp1;
             end;
    kF3,
    kShF3,
    kCtrlL:  begin
               If (mn_environment.keystroke = kShF3) then quick_cmd := TRUE;
               FILE_open('*.a2i$*.a2f$*.a2b$*.a2w$'+
                         '*.bnk$*.cif$*.fib$*.fin$*.ibk$*.ins$*.sbi$*.sgi$',TRUE);// load bank is possible
               reset_instrument_preview;
               update_4op_flag_marks;
               quick_cmd := FALSE;
               GOTO _jmp1;
             end;

    kF4,
    kCtrlA:  begin
               NUKE;
               GOTO _jmp1;
             end;
  end;

  If (Update32(songdata,SizeOf(songdata),0) <> songdata_crc) then
    module_archived := FALSE;

  If (mn_environment.keystroke = kENTER) then INSTRUMENT_CONTROL := instrum_page
  else INSTRUMENT_CONTROL := 0;
end;

procedure instr_control_proc_alt;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:instr_control_proc_alt';
{$ENDIF}
  INSTRUMENT_CONTROL_page_refresh_alt(mn_environment.curr_pos);
  If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
    If (get_4op_to_test <> 0) then
      INSTRUMENT_test(LO(get_4op_to_test),HI(get_4op_to_test),count_channel(pattern_hpos),mn_environment.keystroke,FALSE)
    else INSTRUMENT_test(mn_environment.curr_pos,0,count_channel(pattern_hpos),mn_environment.keystroke,FALSE);
end;

function INSTRUMENT_CONTROL_alt(instr: Byte; title: String): Byte;

var
  temp: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_alt';
{$ENDIF}
  keyboard_reset_buffer;
  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  mn_environment.v_dest := ptr_temp_screen;
  ScreenMemCopy(screen_ptr,mn_environment.v_dest);

  mn_setting.center_box := FALSE;
  mn_setting.cycle_moves := FALSE;
  mn_environment.ext_proc := @instr_control_proc_alt;
  mn_environment.ext_proc_rt := @instr_control_ai;

  Frame(ptr_temp_screen,INSCTRL_xshift+07,INSCTRL_yshift+05,
        INSCTRL_xshift+83,INSCTRL_yshift+26,
        dialog_background+dialog_border,
        ' '+title+' ',
        dialog_background+dialog_title,
        frame_double);

  fr_setting.update_area := FALSE;
  fr_setting.shadow_enabled := FALSE;
  Frame(ptr_temp_screen,INSCTRL_xshift+09,INSCTRL_yshift+06,
        INSCTRL_xshift+34,INSCTRL_yshift+25,
        instrument_bckg+instrument_border,
        '',
        instrument_bckg+instrument_title,
        frame_single);
  Frame(ptr_temp_screen,INSCTRL_xshift+36,INSCTRL_yshift+06,
        INSCTRL_xshift+81,INSCTRL_yshift+25,
        instrument_bckg+instrument_border,
        '',
        instrument_bckg+instrument_title,
        frame_single);

  ShowVStr(mn_environment.v_dest,INSCTRL_xshift+37,INSCTRL_yshift+07,
           ExpStrL('',18,#28),
           dialog_background+instrument_ai_off);
  ShowVStr(mn_environment.v_dest,INSCTRL_xshift+38,INSCTRL_yshift+06,
           #194+ExpStrL('',18,#179)+#193,
           dialog_background+dialog_border);

  fr_setting.shadow_enabled := TRUE;

  color_table[1] := instrument_bckg+instrument_text;
  color_table[2] := instrument_bckg+instrument_hi_mod;
  color_table[3] := instrument_bckg+instrument_hi_car;

  If (ins_parameter(instr,10) AND 1 <> 1) then
    For temp := 1 to 18 do
      ShowCStr(ptr_temp_screen,INSCTRL_xshift+10,INSCTRL_yshift+06+temp,inst_itm1[temp].str,
               dialog_background+dialog_contxt_dis2,
               color_table[inst_itm1[temp].colr])
  else
    For temp := 1 to 18 do
      ShowCStr(ptr_temp_screen,INSCTRL_xshift+10,INSCTRL_yshift+06+temp,inst_itm2[temp].str,
               dialog_background+dialog_contxt_dis2,
               color_table[inst_itm2[temp].colr]);

  mn_setting.shadow_enabled := FALSE;
  mn_setting.frame_enabled := FALSE;

  mn_environment.unpolite := FALSE;
  mn_environment.preview := TRUE;

  If NOT _force_program_quit then
    Menu(songdata.instr_names,INSCTRL_xshift+38,INSCTRL_yshift+06,instr,42,18,255,'');

  INSTRUMENT_CONTROL_page_refresh_alt(instr);
  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := INSCTRL_xshift+7;
  move_to_screen_area[2] := INSCTRL_yshift+5;
  move_to_screen_area[3] := INSCTRL_xshift+83+2;
  move_to_screen_area[4] := INSCTRL_yshift+26+1;
  move2screen_alt;

  mn_environment.v_dest := screen_ptr;
  If NOT _force_program_quit then
    temp := Menu(songdata.instr_names,INSCTRL_xshift+38,INSCTRL_yshift+06,instr,42,18,255,'');

  reset_marked_instruments;
  mn_environment.unpolite := FALSE;
  mn_environment.preview := FALSE;
  mn_setting.frame_enabled := TRUE;
  mn_setting.shadow_enabled := TRUE;
  fr_setting.update_area := TRUE;
  mn_setting.center_box  := TRUE;
  mn_environment.context := '';
  mn_environment.ext_proc := NIL;
  mn_environment.ext_proc_rt := NIL;

  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := INSCTRL_xshift+7;
  move_to_screen_area[2] := INSCTRL_yshift+5;
  move_to_screen_area[3] := INSCTRL_xshift+83+2;
  move_to_screen_area[4] := INSCTRL_yshift+26+1;
  move2screen;

  If (mn_environment.keystroke = kENTER) then INSTRUMENT_CONTROL_alt := temp
  else INSTRUMENT_CONTROL_alt := 0;
end;
