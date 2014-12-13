{
    procedure INSTRUMENT_test(instr,instr2: Byte; chan: Byte; fkey: Word;
                          process_macros: Boolean);
    function marked_instruments: Byte;
    function _1st_marked: Byte;
    function _2nd_marked: Byte;
    function _4op_to_test: Word;
    procedure reset_4op_to_test(_4op_type,ins2: Byte);
    procedure INSTRUMENT_CONTROL_page_refresh(page: Byte);
    procedure _show_adsr(var dest; xstart,ystart: Byte;
                     attack,decay,sustain,release,attenuation: Byte;
                     eg_type: Byte;
                     attr,attr_hi: Byte;
                     reset: Boolean);
    procedure INSTRUMENT_CONTROL_page_refresh_alt(page: Byte);
    procedure INSTRUMENT_CONTROL_edit;
    procedure copy_object;
    procedure paste_object(mode: Byte);
    procedure instr_control_ai;
    procedure instr_control_proc;
    function INSTRUMENT_CONTROL: Byte;
    procedure instr_control_proc_alt;
    function INSTRUMENT_CONTROL_alt(instr: Byte; title: String): Byte;
}

procedure INSTRUMENT_test(instr,instr2: Byte; chan: Byte; fkey: Word;
                          process_macros: Boolean);
const
  _4op_chan: array[1..6] of Byte = (2,4,6,11,13,15);
  _perc_sim_chan: array[19..20] of Byte = (18,17);

var
  idx,temp,temp2,temp3,temp5: Byte;
  valid_key,temp4: Boolean;
  chan_handle: array[1..18] of Byte;
  channels: Byte;

function output_note(chan,board_pos: Byte): Boolean;

var
  note: Byte;
  freq: Word;

begin
{$IFDEF __TMT__}
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
  If is_4op_mode and (instr2 <> BYTE_NULL) then chan := _4op_chan[chan];
  load_instrument(songdata.instr_data[instr],chan);

  If percussion_mode and
     (songdata.instr_data[instr].perc_voice in [4,5]) then
    load_instrument(songdata.instr_data[instr],_perc_sim_chan[chan]);

  If is_4op_mode and (instr2 <> BYTE_NULL) then
    load_instrument(songdata.instr_data[instr2],PRED(chan));

  freq := nFreq(note-1)+$2000+
          SHORTINT(tDUMMY_BUFF(Addr(songdata.instr_data[instr])^)[12]);

  event_table[chan].note := note;
  opl3out($0b0+_chan_n[chan],0);
  opl3out($0a0+_chan_n[chan],LO(freq));
  opl3out($0b0+_chan_n[chan],HI(freq));

  macro_speedup := songdata.macro_speedup;
  If (play_status = isStopped) then update_timer(songdata.tempo);

  freq_table[chan] := freq;
  freqtable2[chan] := freq;
  If process_macros then init_macro_table(chan,note,instr,freq)
  else begin
         macro_table[chan].fmreg_table := 0;
         macro_table[chan].arpg_table := 0;
         macro_table[chan].vib_table := 0;
       end;

  If is_4op_mode and (instr2 <> BYTE_NULL) then
    begin
      freq_table[PRED(chan)] := freq;
      freqtable2[PRED(chan)] := freq;
      If process_macros then init_macro_table(PRED(chan),note,instr2,freq)
      else begin
             macro_table[PRED(chan)].fmreg_table := 0;
             macro_table[PRED(chan)].arpg_table := 0;
             macro_table[PRED(chan)].vib_table := 0;
           end;
    end;
end;

begin { INSTRUMENT_test }
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_test';
{$ENDIF}
  If ctrl_pressed or alt_pressed or shift_pressed then EXIT;
  valid_key := FALSE;
  For temp := 1 to 29 do
    If NOT shift_pressed then
      If (board_scancodes[temp] = HI(fkey)) then
        begin valid_key := TRUE; BREAK; end;

  If NOT valid_key or
     NOT (temp+12*(current_octave-1)-1 in [0..12*8+1]) then EXIT;

  If Empty(songdata.instr_data[instr],SizeOf(songdata.instr_data[instr])) and
     NOT (is_4op_mode and (instr2 <> BYTE_NULL) and
          NOT Empty(songdata.instr_data[instr2],SizeOf(songdata.instr_data[instr2]))) then EXIT;

  temp2 := temp;
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
     NOT is_4op_mode then channels := 18
  else If NOT is_4op_mode then channels := 15
       else begin
              If (instr2 <> BYTE_NULL) then
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
{$IFDEF __TMT__}
          realtime_gfx_poll_proc;
{$ELSE}
          _emulate_screen_without_delay := TRUE;
          keyboard_poll_input;
{$ENDIF}
         keyboard_reset_buffer;
         emulate_screen;
        end;
    end
  else Repeat
{$IFNDEF __TMT__}
         keyboard_poll_input;
{$ENDIF}
         valid_key := FALSE;

         For temp := 1 to 29 do
           begin
             temp2 := board_scancodes[temp];
             temp4 := scankey(temp2);

             If NOT (is_4op_mode and (instr2 <> BYTE_NULL)) then
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
               If NOT ctrl_pressed then
                 begin
                   reset_chan_data(temp3);
                   chan_handle[temp3] := 0;
                 end
               else begin
                      key_off(temp3);
                      If alt_pressed then keyoff_loop[temp3] := TRUE;
                    end;
           end;
{$IFDEF __TMT__}
          realtime_gfx_poll_proc;
{$ELSE}
          _emulate_screen_without_delay := TRUE;
          keyboard_poll_input;
{$ENDIF}
         keyboard_reset_buffer;
         emulate_screen;
       until NOT valid_key;

  While ctrl_pressed do
    begin
{$IFDEF __TMT__}
          realtime_gfx_poll_proc;
{$ELSE}
          _emulate_screen_without_delay := TRUE;
          keyboard_poll_input;
{$ENDIF}
         keyboard_reset_buffer;
         emulate_screen;
    end;

  songdata.flag_4op := flag_4op_backup;
  Move(fmpar_table_backup,fmpar_table,SizeOf(fmpar_table));
  Move(volume_table_backup,volume_table,SizeOf(volume_table));
  Move(panning_table_backup,panning_table,SizeOf(panning_table));
  songdata.common_flag := common_flag_backup;
  volume_scaling := volume_scaling_backup;
  reset_player;

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
end;

var
  color_table: array[1..3] of Byte;

const
  last_marked: Byte = 0;

function marked_instruments: Byte;

var
  temp,result: Byte;

begin
  result := 0;
  For temp := 1 to 255 do
    If (songdata.instr_names[temp][1] = '') then
      Inc(result);
  marked_instruments := result;
end;

function _1st_marked: Byte;

var
  temp,result: Byte;

begin
  result := 0;
  For temp := 1 to 255 do
    If (songdata.instr_names[temp][1] = '') then
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
      If (songdata.instr_names[temp][1] = '') then
        begin
          result := temp;
          BREAK;
        end;
  _2nd_marked := result;
end;

function _4op_to_test: Word;

var
  result: Word;

begin
  If (marked_instruments = 0) or NOT is_4op_mode then result := 0
  else Case marked_instruments of
         1: result := instrum_page+_1st_marked SHL 8;
         2: If (last_marked <> _1st_marked) then result := _2nd_marked+_1st_marked SHL 8
            else result := _1st_marked+_2nd_marked SHL 8;
       end;
  _4op_to_test := result;
end;

procedure reset_4op_to_test(_4op_type,ins2: Byte);
begin
  Case _4op_type of
    1: If (marked_instruments = 2) then
         If (last_marked <> _1st_marked) then
           begin
             last_marked := _1st_marked;
             songdata.instr_names[_2nd_marked][1] := ' ';
           end
         else begin
                last_marked := _2nd_marked;
                songdata.instr_names[_1st_marked][1] := ' ';
              end;

    2: Case marked_instruments of
         1: begin
              songdata.instr_names[last_marked][1] := ' ';
              songdata.instr_names[ins2][1] := '';
              last_marked := ins2;
            end;

         2: If (last_marked <> _1st_marked) then
              begin
                last_marked := _2nd_marked;
                songdata.instr_names[_1st_marked][1] := ' ';
              end
            else begin
                   last_marked := _1st_marked;
                   songdata.instr_names[_2nd_marked][1] := ' ';
                 end;
       end;
    end;
end;

const
  _index: array[1..13] of Byte = (1,0,3,2,5,4,7,6,9,8,10,11,12);

procedure INSTRUMENT_CONTROL_page_refresh(page: Byte);

var
  temp: Byte;
  temp_str: String;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_page_refresh';
{$ENDIF}
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
            byte2hex(tDUMMY_BUFF(Addr(songdata.instr_data[page])^)[_index[temp]]),
            dialog_background+dialog_item);


  ShowCStr(mn_environment.v_dest,
           INSCTRL_xshift+30,INSCTRL_yshift+08+pos2[11],
           connection_str[tDUMMY_BUFF(Addr(songdata.instr_data[page])^)[_index[11]] AND 1]+'~/~'+
           CHR(ORD('0')+(tDUMMY_BUFF(Addr(songdata.instr_data[page])^)[_index[11]] SHR 1 AND 7)),
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

  Case songdata.instr_data[page].perc_voice of
    0: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~MELODiC~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    1: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:BD~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    2: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:SD~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    3: ShowCStr(mn_environment.v_dest,
                 INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:TT~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    4: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:TC~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    5: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:HH~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
  end;

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
           ExpStrR(temp_str,21+1,'Í'),
           dialog_background+dialog_border,
           dialog_background+dialog_context);

  STATUS_LINE_refresh;
end;

const
{$IFDEF __TMT__}
  ie_vsize_shift: array[0..5] of Byte = (0,12,12,0,0,0);
{$ELSE}
  ie_vsize_shift: array[0..2] of Byte = (0,12,12);
{$ENDIF}

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
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:_show_adsr';
{$ENDIF}
  fr_setting.update_area := FALSE;
  fr_setting.shadow_enabled := FALSE;

  adsr_bckg := instrument_adsr;
  If (program_screen_mode in [1,2]) then
    begin
      adsr_bckg := instrument_bckg;
      Frame(dest,xstart,ystart+1,xstart+61,ystart+11,
            instrument_bckg,'',0,solid1);
    end
  else If reset then
         Frame(dest,xstart,ystart,xstart+63,ystart+12,
               instrument_bckg,'',0,solid1)
       else Frame(dest,xstart,ystart,xstart+63,ystart+12,
                  instrument_adsr+instrument_text,' ADSR PREViEW ',instrument_adsr+instrument_text,double);

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

  If (decay = 0) and ((release <> 0) or ((sustain <> 0) and
                      (eg_type = 1))) then
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
            Copy(Copy(ExpStrR('ö',_conv(attack,16-attack),' ')+
                      ExpStrR('ö',_conv(decay,16-decay),' ')+
                      ExpStrR('ö',_conv(sustain,sustain),' ')+
                      ExpStrR('ö',_conv(release,15-release),' '),1,60-1)+
                 'ö'+ExpStrL('',60,' '),1,60),
             attr_hi)
  else
    ShowStr(dest,xstart+2,ystart+10,
            ExpStrR('ö',_conv(attack,16-attack),' ')+
            ExpStrR('ö',_conv(decay,16-decay),' ')+
            ExpStrR('ö',_conv(sustain,sustain),' ')+
            ExpStrR('ö',_conv(release,15-release)+
                        15-_conv(release,15-release)+
                        15-_conv(sustain,sustain)+
                        15-_conv(decay,16-decay)+
                        15-_conv(attack,16-attack),' '),
            attr_hi);

  If (release > 0) then
    ShowStr(dest,xstart+2,ystart+11,
            Copy(Copy(ExpStrR('A',_conv(attack,16-attack),'ú')+
                      ExpStrR('D',_conv(decay,16-decay),'ú')+
                      ExpStrR('S',_conv(sustain,sustain),'ú')+
                      ExpStrR('R',_conv(release,15-release),'ú'),1,60-1)+
                 ''+ExpStrL('',60,'ú'),1,60),
             attr_hi)
  else
    ShowStr(dest,xstart+2,ystart+11,
            ExpStrR('A',_conv(attack,16-attack),'ú')+
            ExpStrR('D',_conv(decay,16-decay),'ú')+
            ExpStrR('S',_conv(sustain,sustain),'ú')+
            ExpStrR('R',_conv(release,15-release)+
                         15-_conv(release,15-release)+
                         15-_conv(sustain,sustain)+
                         15-_conv(decay,16-decay)+
                        15-_conv(attack,16-attack),'ú'),
            attr_hi);
end;

procedure INSTRUMENT_CONTROL_page_refresh_alt(page: Byte);

var
  temp: Byte;
  temp_str: String;

const
  _index: array[1..13] of Byte = (1,0,3,2,5,4,7,6,9,8,10,11,12);

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_page_refresh_alt';
{$ENDIF}
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
            byte2hex(tDUMMY_BUFF(Addr(songdata.instr_data[page])^)[_index[temp]]),
            instrument_bckg+instrument_hi_text);

  ShowCStr(mn_environment.v_dest,
           INSCTRL_xshift+30,INSCTRL_yshift+08+pos2[11],
           connection_str[tDUMMY_BUFF(Addr(songdata.instr_data[page])^)[_index[11]] AND 1]+'~/~'+
           CHR(ORD('0')+(tDUMMY_BUFF(Addr(songdata.instr_data[page])^)[_index[11]] SHR 1 AND 7)),
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

  Case songdata.instr_data[page].perc_voice of
    0: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~MELODiC~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    1: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:BD~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    2: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:SD~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    3: ShowCStr(mn_environment.v_dest,
                 INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:TT~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    4: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:TC~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
    5: ShowCStr(mn_environment.v_dest,
                INSCTRL_xshift+09,INSCTRL_yshift+26,
                ' [~PERC:HH~] ',
                dialog_background+dialog_border,
                dialog_background+dialog_context);
  end;

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
           ExpStrR(temp_str,21+1,'Í'),
           dialog_background+dialog_border,
           dialog_background+dialog_context);
end;

procedure INSTRUMENT_CONTROL_edit;

const
  _ADSR_preview_flag: Boolean = TRUE;

const
  _text: array[1..24] of String[70] = (
    '~ATTACK RATE~                        ~WAVEFORM TYPE~',
    '~DECAY RATE~                         ( ) Sine',
    '                                                  ( ) Half-Sine',
    '~SUSTAiN LEVEL~                      ( ) Abs-Sine',
    '~RELEASE RATE~                       ( ) Pulse-Sine',
    '                                                  ( ) Sine (EPO)',
    '~OUTPUT LEVEL~       ( ) Abs-Sine (EPO)',
    '                                                  ( ) Square',
    '~KEY SCALiNG LEVEL~                                 ( ) Derived square',
    '( ) Default          ~GLOBAL iNSTRUMENT SETTiNGS~',
    '( ) 1.5 dB/octave    ~šššššššššššššššššššššššššš~',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '~AMPLiTUDE MODULATiON/ViBRATO/ENVELOPE GENERATOR TYPE/~',
    '~KEY SCALE RATE/FREQUENCY DATA MULTiPLiER~',
    '[ ] Tremolo (AM)',
    '[ ] Vibrato                Mult. ( ) 0 ( ) 1 ( ) 2 ( ) 3 ( ) 4 ( ) 5',
    '[ ] Key scale rate (KSR)         ( ) 6 ( ) 7 ( ) 8 ( ) 9 ( ) A ( ) B',
    '[ ] Sustain (EG type)            ( ) C ( ) D ( ) E ( ) F');

const
  _ext_carrier: array[1..6] of String[70] = (
    '( ) 3.0 dB/octave            ©     c     ª',
    '( ) 6.0 dB/octave    ~PANNiNG~ úúúúúúúúúúúúú',
    '',
    '~FiNE-TUNE~            ~FEEDBACK STRENGTH~ ',
    '  ~CONNECTiON TYPE~',
    'lower    ^    upper  ( ) FM ( ) Additive synthesis~');

const
  _ext_modulator: array[1..6] of String[70] = (
    '( ) 3.0 dB/octave            ~©     c     ª~',
    '( ) 6.0 dB/octave    ~PANNiNG úúúúúúúúúúúúú~',
    '',
    '~FiNE-TUNE            FEEDBACK STRENGTH ~  ',
    '~  CONNECTiON TYPE~',
    '~lower    ^    upper  ( ) FM ( ) Additive synthesis~');

const
  _ext_perc: array[1..3] of String[70] = (
    'FiNE-TUNE            ~FEEDBACK STRENGTH ~  ',
    '  ~CONNECTiON TYPE~',
    'lower    ^    upper  ~( ) FM ( ) Additive synthesis~');

const
  _hpos: array[1..20,1..7] of Byte = (
    (+15,+0,+0,+0,+0,+0,+0),
    (+15,+52,+0,+0,+0,+0,+0),
    (+52,+0,+0,+0,+0,+0,+0),
    (+15,+52,+0,+0,+0,+0,+0),
    (+15,+52,+0,+0,+0,+0,+0),
    (+52,+0,+0,+0,+0,+0,+0),
    (+15,+52,+0,+0,+0,+0,+0),
    (+52,+0,+0,+0,+0,+0,+0),
    (+52,+0,+0,+0,+0,+0,+0),
    (+2,+0,+0,+0,+0,+0,+0),
    (+2,+0,+0,+0,+0,+0,+0),
    (+0,+0,+0,+0,+0,+0,+0),
    (+0,+0,+0,+0,+0,+0,+0),
    (+0,+0,+0,+0,+0,+0,+0),
    (+0,+0,+0,+0,+0,+0,+0),
    (+0,+0,+0,+0,+0,+0,+0),
    (+2,+0,+0,+0,+0,+0,+0),
    (+2,+35,+41,+47,+53,+59,+65),
    (+2,+35,+41,+47,+53,+59,+65),
    (+2,+35,+41,+47,+53,+0,+0));

const
  _hpos_ext_carrier: array[1..5,1..7] of Byte = (
    (+2,+0,+0,+0,+0,+0,+0),
    (+2,+30,+36,+42,+0,+0,+0),
    (+40,+0,+0,+0,+0,+0,+0),
    (+1,+0,+0,+0,+0,+0,+0),
    (+23,+30,+0,+0,+0,+0,+0));

  _hpos_ext_modulator: array[1..5,1..7] of Byte = (
    (+2,+0,+0,+0,+0,+0,+0),
    (+2,+0,+0,+0,+0,+0,+0),
    (+0,+0,+0,+0,+0,+0,+0),
    (+0,+0,+0,+0,+0,+0,+0),
    (+0,+0,+0,+0,+0,+0,+0));

  _hpos_ext_perc: array[1..3,1..7] of Byte = (
    (+0,+0,+0,+0,+0,+0,+0),
    (+1,+0,+0,+0,+0,+0,+0),
    (+0,+0,+0,+0,+0,+0,+0));

const
  _vpos: array[1..20] of Byte = (+1,+2,+3,+4,+5,+6,+7,+8,+9,+10,+11,+12,+13,+15,+16,
                                 +17,+21,+22,+23,+24);

const
  _help_text: array[0..15] of String[35] = (
    '1 octave below',
    'at the voice''s specified frequency',
    '1 octave above',
    '1 octave and a 5th above',
    '2 octaves above',
    '2 octaves and a Major 3rd above',
    '2 octaves and a 5th above',
    '2 octaves and a Minor 7th above',
    '3 octaves above',
    '3 octaves and a Major 2nd above',
    '3 octaves and a Major 3rd above',
    '3 octaves and a Major 3rd above',
    '3 octaves and a 5th above',
    '3 octaves and a 5th above',
    '3 octaves and a Major 7th above',
    '3 octaves and a Major 7th above');

var
  temp: Byte;
  xstart,ystart: Byte;
  nope: Boolean;
  hpos,vpos: Byte;
  carrier: Boolean;
  inst: ^tADTRACK2_INS;

procedure page_build;

var
  temp: Byte;
  temp_str: String;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_edit:page_build';
{$ENDIF}
  ShowStr(ptr_temp_screen,xstart+45,ystart,
          byte2hex(instrum_page),
          instrument_bckg+instrument_title);

  If NOT (program_screen_mode in [1,2]) then
    ShowStr(ptr_temp_screen,xstart-1,ystart+25,#204+ExpStrL('',70,#205)+#185,instrument_bckg+instrument_border);

  Case inst^.perc_voice of
    0: ShowCStr(ptr_temp_screen,xstart,ystart+25,' [~MELODiC~]',
                instrument_bckg+instrument_border,
                instrument_bckg+instrument_context);
    1: ShowCStr(ptr_temp_screen,xstart,ystart+25,' [~PERC:BD~]',
                instrument_bckg+instrument_border,
                instrument_bckg+instrument_context);
    2: ShowCStr(ptr_temp_screen,xstart,ystart+25,' [~PERC:SD~]',
                instrument_bckg+instrument_border,
                instrument_bckg+instrument_context);
    3: ShowCStr(ptr_temp_screen,xstart,ystart+25,' [~PERC:TT~]',
                instrument_bckg+instrument_border,
                instrument_bckg+instrument_context);
    4: ShowCStr(ptr_temp_screen,xstart,ystart+25,' [~PERC:TC~]',
                instrument_bckg+instrument_border,
                instrument_bckg+instrument_context);
    5: ShowCStr(ptr_temp_screen,xstart,ystart+25,' [~PERC:HH~]',
                instrument_bckg+instrument_border,
                instrument_bckg+instrument_context);
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
           xstart+10,ystart+25,
           ExpStrR(temp_str,21+1,'Í'),
           instrument_bckg+instrument_border,
           instrument_bckg+instrument_context);

  ShowCStr(ptr_temp_screen,xstart+55,ystart+25,
           ExpStrL(' ~[SPEED:'+Num2str(songdata.tempo*songdata.macro_speedup,10)+#3+']~ ',17,'Í'),
           instrument_bckg+instrument_border,
           instrument_bckg+instrument_context);

  If carrier or (inst^.perc_voice in [2..5]) then
    begin
      Move(_ext_carrier,_text[12],SizeOf(_ext_carrier));
      Move(_hpos_ext_carrier,_hpos[12],SizeOf(_hpos_ext_carrier));

      If (inst^.perc_voice in [2..5]) then
        begin
          Move(_ext_perc,_text[15],SizeOf(_ext_perc));
          Move(_hpos_ext_perc,_hpos[14],SizeOf(_hpos_ext_perc));
        end
    end
  else
    begin
      Move(_ext_modulator,_text[12],SizeOf(_ext_modulator));
      Move(_hpos_ext_modulator,_hpos[12],SizeOf(_hpos_ext_modulator));
    end;

  If carrier then
    For temp := 1 to 24 do
      If NOT (temp in [10..17]) then
        ShowCStr(ptr_temp_screen,xstart+1,ystart+temp,_text[temp],
                 instrument_bckg+instrument_text,
                 instrument_bckg+instrument_car)
      else ShowCStr(ptr_temp_screen,xstart+1,ystart+temp,_text[temp],
                    instrument_bckg+instrument_text,
                    instrument_bckg+instrument_glob)
  else
    For temp := 1 to 24 do
      If NOT (temp in [10..17]) then
        ShowCStr(ptr_temp_screen,xstart+1,ystart+temp,_text[temp],
                 instrument_bckg+instrument_text,
                 instrument_bckg+instrument_mod)
      else If carrier or (inst^.perc_voice in [2..5]) then
             begin
               If NOT (temp in [15..17]) then
                 ShowCStr(ptr_temp_screen,xstart+1,ystart+temp,_text[temp],
                          instrument_bckg+instrument_text,
                          instrument_bckg+instrument_glob)
               else If (temp <> 17) then
                      ShowCStr(ptr_temp_screen,xstart+1,ystart+temp,_text[temp],
                               instrument_bckg+instrument_glob,
                               instrument_bckg+instrument_hid)
                    else ShowCStr(ptr_temp_screen,xstart+1,ystart+temp,_text[temp],
                                  instrument_bckg+instrument_text,
                                  instrument_bckg+instrument_hid);
             end
           else ShowCStr(ptr_temp_screen,xstart+1,ystart+temp,_text[temp],
                         instrument_bckg+instrument_text,
                         instrument_bckg+instrument_hid);

  If (_hpos[vpos,hpos] = 0) then begin vpos := 1; hpos := 1; end;
  Case hpos of
    1: Case vpos of
         1:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+1,'ATTACK RATE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+1,'ATTACK RATE',
                       instrument_bckg+instrument_hi_mod);

         2:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+2,'DECAY RATE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+2,'DECAY RATE',
                       instrument_bckg+instrument_hi_mod);
         3,6,8,
         9:  If carrier then
               ShowStr(ptr_temp_screen,xstart+51,ystart+1,'WAVEFORM TYPE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+51,ystart+1,'WAVEFORM TYPE',
                       instrument_bckg+instrument_hi_mod);

         4:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+4,'SUSTAiN LEVEL',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+4,'SUSTAiN LEVEL',
                       instrument_bckg+instrument_hi_mod);

         5:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+5,'RELEASE RATE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+5,'RELEASE RATE',
                       instrument_bckg+instrument_hi_mod);

         7:  If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+7,'OUTPUT LEVEL',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+7,'OUTPUT LEVEL',
                       instrument_bckg+instrument_hi_mod);
         10,11,12,
         13: If carrier then
               ShowStr(ptr_temp_screen,xstart+1,ystart+9,'KEY SCALiNG LEVEL',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+1,ystart+9,'KEY SCALiNG LEVEL',
                       instrument_bckg+instrument_hi_mod);

         14: ShowStr(ptr_temp_screen,xstart+22,ystart+15,'FEEDBACK STRENGTH',
                     instrument_bckg+instrument_hi_glob);

         15: ShowStr(ptr_temp_screen,xstart+1,ystart+15,'FiNE-TUNE',
                     instrument_bckg+instrument_hi_glob);

         16: ShowStr(ptr_temp_screen,xstart+22,ystart+16,'CONNECTiON TYPE',
                     instrument_bckg+instrument_hi_glob);
         17,18,19,
         20: If carrier then
               begin
                 ShowStr(ptr_temp_screen,xstart+1,ystart+19,'AMPLiTUDE MODULATiON/ViBRATO/ENVELOPE GENERATOR TYPE/',
                         instrument_bckg+instrument_hi_car);
                 ShowStr(ptr_temp_screen,xstart+1,ystart+20,'KEY SCALE RATE/FREQUENCY DATA MULTiPLiER',
                         instrument_bckg+instrument_hi_car);
               end
             else
               begin
                 ShowStr(ptr_temp_screen,xstart+1,ystart+19,'AMPLiTUDE MODULATiON/ViBRATO/ENVELOPE GENERATOR TYPE/',
                         instrument_bckg+instrument_hi_mod);
                 ShowStr(ptr_temp_screen,xstart+1,ystart+20,'KEY SCALE RATE/FREQUENCY DATA MULTiPLiER',
                         instrument_bckg+instrument_hi_mod);
               end;
       end;

    2,3,4,5,6,
    7: Case vpos of
         2,4,5,
         7:  If carrier then
               ShowStr(ptr_temp_screen,xstart+51,ystart+1,'WAVEFORM TYPE',
                       instrument_bckg+instrument_hi_car)
             else
               ShowStr(ptr_temp_screen,xstart+51,ystart+1,'WAVEFORM TYPE',
                       instrument_bckg+instrument_hi_mod);

         13: ShowStr(ptr_temp_screen,xstart+22,ystart+13,'PANNiNG',
                     instrument_bckg+instrument_hi_glob);

         16: ShowStr(ptr_temp_screen,xstart+22,ystart+16,'CONNECTiON TYPE',
                     instrument_bckg+instrument_hi_glob);
         18,19,
         20: If carrier then
               begin
                 ShowStr(ptr_temp_screen,xstart+1,ystart+19,'AMPLiTUDE MODULATiON/ViBRATO/ENVELOPE GENERATOR TYPE/',
                         instrument_bckg+instrument_hi_car);
                 ShowStr(ptr_temp_screen,xstart+1,ystart+20,'KEY SCALE RATE/FREQUENCY DATA MULTiPLiER',
                         instrument_bckg+instrument_hi_car);
               end
             else
               begin
                 ShowStr(ptr_temp_screen,xstart+1,ystart+19,'AMPLiTUDE MODULATiON/ViBRATO/ENVELOPE GENERATOR TYPE/',
                         instrument_bckg+instrument_hi_mod);
                 ShowStr(ptr_temp_screen,xstart+1,ystart+20,'KEY SCALE RATE/FREQUENCY DATA MULTiPLiER',
                         instrument_bckg+instrument_hi_mod);
               end;
       end;
  end;
end;

procedure page_refresh;

var
  temp,x0,y0: Byte;
  temps1,temps2: String;
  adsr_vpos: Byte;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_edit:page_refresh';
{$ENDIF}
  x0 := xstart;
  y0 := ystart;

  If NOT (program_screen_mode in [1,2]) then adsr_vpos := y0+10
  else adsr_vpos := y0+25;

  If (NOT ((vpos in [1,2,4,5,7,20]) and (hpos = 1)) or
      NOT _ADSR_preview_flag) then
    begin
      _show_adsr(ptr_temp_screen,x0+3,adsr_vpos,
                 BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL,
                 TRUE);
      page_build;
    end;

  If NOT (program_screen_mode in [1,2]) then
    begin
      If _ADSR_preview_flag then
        ShowCStr(ptr_temp_screen,xstart+29,ystart+25,' [ADSR:~ON~] '+#205,
                 instrument_bckg+instrument_border,
                 instrument_bckg+instrument_context)
      else
        ShowCStr(ptr_temp_screen,xstart+29,ystart+25,' [ADSR:~OFF~] ',
                 instrument_bckg+instrument_border,
                 instrument_bckg+instrument_context);
    end;

  If carrier then temp := inst^.fm_data.ATTCK_DEC_carrier
  else temp := inst^.fm_data.ATTCK_DEC_modulator;

  ShowCStr(ptr_temp_screen,x0+_hpos[1,1],y0+_vpos[1],'~'+
           ExpStrL('',   (temp SHR 4),'')+'~'+
           ExpStrL('',15-(temp SHR 4),''),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowCStr(ptr_temp_screen,x0+_hpos[2,1],y0+_vpos[2],'~'+
           ExpStrL('',   (temp AND $0f),'')+'~'+
           ExpStrL('',15-(temp AND $0f),''),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowStr(ptr_temp_screen,x0+_hpos[1,1]+16,y0+_vpos[1],
          ExpStrR(Num2str(temp SHR 4,16),1,' '),
          instrument_bckg+instrument_text);

  ShowStr(ptr_temp_screen,x0+_hpos[2,1]+16,y0+_vpos[2],
          ExpStrR(Num2str(temp AND $0f,16),1,' '),
          instrument_bckg+instrument_text);

  If carrier then temp := inst^.fm_data.SUSTN_REL_carrier
  else temp := inst^.fm_data.SUSTN_REL_modulator;

  ShowCStr(ptr_temp_screen,x0+_hpos[4,1],y0+_vpos[4],'~'+
           ExpStrL('',   (temp SHR 4),'')+'~'+
           ExpStrL('',15-(temp SHR 4),''),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowCStr(ptr_temp_screen,x0+_hpos[5,1],y0+_vpos[5],'~'+
           ExpStrL('',   (temp AND $0f),'')+'~'+
           ExpStrL('',15-(temp AND $0f),''),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowStr(ptr_temp_screen,x0+_hpos[4,1]+16,y0+_vpos[4],
          ExpStrR(Num2str(temp SHR 4,16),1,' '),
          instrument_bckg+instrument_text);

  ShowStr(ptr_temp_screen,x0+_hpos[5,1]+16,y0+_vpos[5],
          ExpStrR(Num2str(temp AND $0f,16),1,' '),
          instrument_bckg+instrument_text);

  If carrier then temp := inst^.fm_data.WAVEFORM_carrier
  else temp := inst^.fm_data.WAVEFORM_modulator;

  ShowVStr(ptr_temp_screen,x0+_hpos[2,2],y0+_vpos[2],
           ExpStrL('',temp AND 7,' ')+'û'+ExpStrL('',7-temp AND 7,' '),
           instrument_bckg+instrument_hi_text);

  If carrier then temp := inst^.fm_data.KSL_VOLUM_carrier
  else temp := inst^.fm_data.KSL_VOLUM_modulator;

  ShowCStr(ptr_temp_screen,x0+_hpos[7,1],y0+_vpos[7],'~'+
           ExpStrL('',   ((63-(temp AND $3f)) DIV 2),'')+'~'+
           ExpStrL('',31-((63-(temp AND $3f)) DIV 2),''),
           instrument_bckg+instrument_text,
           instrument_bckg+instrument_hi_text);

  ShowStr(ptr_temp_screen,x0+_hpos[7,1]+32,y0+_vpos[7],
          ExpStrR(Num2str(63-(temp AND $3f),16),2,' '),
          instrument_bckg+instrument_text);

  temp := temp SHR 6;
  temp := temp SHR 1+temp AND 1 SHL 1;
  ShowVStr(ptr_temp_screen,x0+_hpos[10,1],y0+_vpos[10],
           ExpStrL('',temp,' ')+'û'+ExpStrL('',3-temp,' '),
           instrument_bckg+instrument_hi_text);

  If carrier or (inst^.perc_voice in [2..5]) then
    begin
      Case inst^.panning of
        0: ShowCStr(ptr_temp_screen,x0+_hpos[13,2],y0+_vpos[13],'~ú~úúú~~úúú~ú~',
                   instrument_bckg+instrument_text,
                   instrument_bckg+instrument_hi_text);

        1: ShowCStr(ptr_temp_screen,x0+_hpos[13,2],y0+_vpos[13],'~~ú~ú~úúúúú~ú~',
                   instrument_bckg+instrument_text,
                   instrument_bckg+instrument_hi_text);

        2: ShowCStr(ptr_temp_screen,x0+_hpos[13,2],y0+_vpos[13],'~ú~úúúúú~ú~ú~~',
                   instrument_bckg+instrument_text,
                   instrument_bckg+instrument_hi_text);
      end;

      temp := Abs(inst^.fine_tune);
      temps1 := ExpStrL('',19,'');

      If (inst^.fine_tune > 0) then
        begin
          Delete(temps1,1+8+(temp DIV 15),3);
          Insert('',temps1,1+8+(temp DIV 15));
        end
      else
        begin
          Delete(temps1,1+8-(temp DIV 15),3);
          Insert('',temps1,1+8-(temp DIV 15));
        end;

      If (inst^.fine_tune > 0) then temps2 := '+'
      else If (inst^.fine_tune < 0) then temps2 := '-'
           else temps2 := '';

      ShowStr(ptr_temp_screen,x0+_hpos[15,1]+15,y0+_vpos[15]-1,
              ExpStrL(temps2+Num2str(temp,16),4,' '),
              instrument_bckg+instrument_text);

      ShowCStr(ptr_temp_screen,x0+_hpos[15,1],y0+_vpos[15],temps1,
               instrument_bckg+instrument_text,
               instrument_bckg+instrument_hi_text);

      If carrier then
        begin
          temp := inst^.fm_data.FEEDBACK_FM;
          ShowCStr(ptr_temp_screen,x0+_hpos[14,1],y0+_vpos[14],'~'+
                   ExpStrL('',   (temp SHR 1) AND 7, '')+'~'+
                   ExpStrL('',7-((temp SHR 1) AND 7),''),
                   instrument_bckg+instrument_text,
                   instrument_bckg+instrument_hi_text);

          ShowStr(ptr_temp_screen,x0+_hpos[14,1]+8,y0+_vpos[14],
                  ExpStrR(Num2str((temp SHR 1) AND 7,16),2,' '),
                  instrument_bckg+instrument_text);

          If (temp AND 1 = 0) then
            ShowCStr(ptr_temp_screen,x0+_hpos[16,1]-1,y0+_vpos[16],'(~û~) FM (~ ~) Additive synthesis',
                     instrument_bckg+instrument_text,
                     instrument_bckg+instrument_hi_text)
          else ShowCStr(ptr_temp_screen,x0+_hpos[16,1]-1,y0+_vpos[16],'(~ ~) FM (~û~) Additive synthesis',
                        instrument_bckg+instrument_text,
                        instrument_bckg+instrument_hi_text);
        end;
    end;

  If carrier then temp := inst^.fm_data.AM_VIB_EG_carrier
  else temp := inst^.fm_data.AM_VIB_EG_modulator;

  If  (temp SHR 7        = 0) then temps1 := ' '        else temps1 := 'û';
  If ((temp SHR 6) AND 1 = 0) then temps1 := temps1+' ' else temps1 := temps1+'û';
  If ((temp SHR 4) AND 1 = 0) then temps1 := temps1+' ' else temps1 := temps1+'û';
  If ((temp SHR 5) AND 1 = 0) then temps1 := temps1+' ' else temps1 := temps1+'û';

  ShowVStr(ptr_temp_screen,x0+_hpos[17,1],y0+_vpos[17],temps1,
           instrument_bckg+instrument_hi_text);

  temps1 := ExpStrL('',16,' '); temps1[(temp AND $0f)+1] := '.';
  If ((vpos in [18..20]) and (hpos in [2..7])) then
    ShowStr(ptr_temp_screen,x0+_hpos[20,2]-7,y0+_vpos[18]-1,
            ExpStrR(_help_text[(vpos-18)*6+hpos-2],34,' '),
            instrument_bckg+instrument_hi_text)
  else
    ShowStr(ptr_temp_screen,x0+_hpos[20,2]-7,y0+_vpos[18]-1,
            ExpStrR(_help_text[temp AND $0f],34,' '),
            instrument_bckg+instrument_hi_text);

  For temp := 1 to 6 do
    If (temps1[temp] = ' ') then
      ShowStr(ptr_temp_screen,x0+_hpos[18,2+temp-1],y0+_vpos[18],' ',
              instrument_bckg+instrument_hi_text)
    else ShowStr(ptr_temp_screen,x0+_hpos[18,2+temp-1],y0+_vpos[18],'û',
                 instrument_bckg+instrument_hi_text);

  For temp := 1 to 6 do
    If (temps1[6+temp] = ' ') then
      ShowStr(ptr_temp_screen,x0+_hpos[19,2+temp-1],y0+_vpos[19],' ',
              instrument_bckg+instrument_hi_text)
    else ShowStr(ptr_temp_screen,x0+_hpos[19,2+temp-1],y0+_vpos[19],'û',
                 instrument_bckg+instrument_hi_text);

  For temp := 1 to 4 do
    If (temps1[12+temp] = ' ') then
      ShowStr(ptr_temp_screen,x0+_hpos[20,2+temp-1],y0+_vpos[20],' ',
              instrument_bckg+instrument_hi_text)
    else ShowStr(ptr_temp_screen,x0+_hpos[20,2+temp-1],y0+_vpos[20],'û',
                 instrument_bckg+instrument_hi_text);

  If NOT (program_screen_mode in [1,2]) or
     ((vpos in [1,2,4,5,7,20]) and (hpos = 1) and
      _ADSR_preview_flag) then
    If NOT carrier or (inst^.perc_voice in [2..5]) then
      _show_adsr(ptr_temp_screen,x0+3,adsr_vpos,
                 inst^.fm_data.ATTCK_DEC_modulator SHR 4,
                 inst^.fm_data.ATTCK_DEC_modulator AND $0f,
                 inst^.fm_data.SUSTN_REL_modulator SHR 4,
                 inst^.fm_data.SUSTN_REL_modulator AND $0f,
                 inst^.fm_data.KSL_VOLUM_modulator AND $3f,
                 inst^.fm_data.AM_VIB_EG_modulator SHR 5 AND 1,
                 adsr_bckg+instrument_mod,
                 adsr_bckg+instrument_hi_mod,FALSE)
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

function min0(number: Integer): Integer;
begin
  If (number > 0) then min0 := number
  else min0 := 0;
end;

function _ftune(ftune: Integer): Integer;

var
  temp: Integer;

begin
  If (ftune DIV 15 = 0) and (ftune <> 0) then temp := 0
  else temp := ABS(ftune) DIV 15;
  _ftune := (ftune DIV min(ABS(ftune),1))*temp;
end;

const
  KSL_volume:    array[0..3] of Byte = (0,$80,$40,$0c0);
  AM_Vibrato_EG: array[0..3] of Byte = ($80,$40,$10,$20);
  panning_pos:   array[0..2] of Byte = (1,0,2);

label _jmp1,_end;

begin { INSTRUMENT_CONTROL_edit }
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_edit';
{$ENDIF}
  inst := Addr(songdata.instr_data[instrum_page]);
  If (inst^.perc_voice in [0,1]) then carrier := TRUE
  else carrier := FALSE;
  hpos := 1;
  vpos := 1;

_jmp1:
  If _force_program_quit then EXIT;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  HideCursor;

  ScreenMemCopy(screen_ptr,ptr_temp_screen);
  centered_frame_vdest := ptr_temp_screen;
  centered_frame(xstart,ystart,71,25+ie_vsize_shift[program_screen_mode],' iNSTRUMENT EDiTOR (iNS_  ) ',
                 instrument_bckg+instrument_border,
                 instrument_bckg+instrument_title,double);
  centered_frame_vdest := screen_ptr;

  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+71+2;
  move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode]+1;
{$IFDEF __TMT__}
  toggle_waitretrace := TRUE;
{$ENDIF}
  move2screen_alt;

  move_to_screen_area[1] := xstart+1;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+70;
  move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode];
  Inc(xstart);

  If NOT _force_program_quit then
    Repeat
      keyboard_poll_input;
      page_build;
      page_refresh;
      If (vpos in [1,2,4,5,7,14,15]) and (hpos = 1) then
        With songdata.instr_data[current_inst] do
          begin
            If (vpos <> 15) then SetCursorShape($010c)
            else SetCursorShape($0e0f);
            Case vpos of
              1: If carrier then
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0(fm_data.ATTCK_DEC_carrier SHR 4-1),
                          ystart+_vpos[vpos])
                 else
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0(fm_data.ATTCK_DEC_modulator SHR 4-1),
                          ystart+_vpos[vpos]);

              2: If carrier then
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0(fm_data.ATTCK_DEC_carrier AND $0f-1),
                          ystart+_vpos[vpos])
                 else
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0(fm_data.ATTCK_DEC_modulator AND $0f-1),
                          ystart+_vpos[vpos]);

              4: If carrier then
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0(fm_data.SUSTN_REL_carrier SHR 4-1),
                          ystart+_vpos[vpos])
                 else
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0(fm_data.SUSTN_REL_modulator SHR 4-1),
                          ystart+_vpos[vpos]);

              5: If carrier then
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0(fm_data.SUSTN_REL_carrier AND $0f-1),
                          ystart+_vpos[vpos])
                 else
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0(fm_data.SUSTN_REL_modulator AND $0f-1),
                          ystart+_vpos[vpos]);

              7: If carrier then
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0((63-fm_data.KSL_VOLUM_carrier AND $3f) DIV 2-1),
                          ystart+_vpos[vpos])
                 else
                   GotoXY(xstart+_hpos[vpos,hpos]+
                          min0((63-fm_data.KSL_VOLUM_modulator AND $3f) DIV 2-1),
                          ystart+_vpos[vpos]);

             14: GotoXY(xstart+_hpos[vpos,hpos]+
                        min0(fm_data.FEEDBACK_FM SHR 1 AND 7-1),
                        ystart+_vpos[vpos]);

             15: If (fine_tune > 0) then
                   GotoXY(xstart+_hpos[vpos,hpos]+1+8+_ftune(fine_tune)+1,
                          ystart+_vpos[vpos])
                 else If (fine_tune < 0) then
                        GotoXY(xstart+_hpos[vpos,hpos]+1+8+_ftune(fine_tune)-1,
                               ystart+_vpos[vpos])
                      else
                        GotoXY(xstart+_hpos[vpos,hpos]+1+8+_ftune(fine_tune),
                               ystart+_vpos[vpos]);
            end;
        end
      else
        begin
          ThinCursor;
          GotoXY(xstart+_hpos[vpos,hpos],ystart+_vpos[vpos]);
        end;

      nope := FALSE;
      if keypressed then fkey := getkey else GOTO _end;
      If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
        If (_4op_to_test <> 0) then
          INSTRUMENT_test(LO(_4op_to_test),HI(_4op_to_test),count_channel(pattern_hpos),fkey,TRUE)
        else INSTRUMENT_test(instrum_page,BYTE_NULL,count_channel(pattern_hpos),fkey,TRUE);

      Case fkey of
        kLEFT:   If (hpos > 1) and (_hpos[vpos,hpos-1] <> 0) then Dec(hpos)
                 else If (vpos > 1) then
                        begin
                          Repeat Dec(vpos) until (_hpos[vpos,1] <> 0);
                          hpos := 7;
                          While (hpos > 1) and (_hpos[vpos,hpos] = 0) do Dec(hpos);
                        end
                      else
                        begin
                          vpos := 20; hpos := 7;
                          While (hpos > 1) and (_hpos[vpos,hpos] = 0) do Dec(hpos);
                        end;

        kRIGHT:  If (hpos < 7) and (_hpos[vpos,hpos+1] <> 0) then Inc(hpos)
                 else If (vpos < 20) then
                        begin
                          Repeat Inc(vpos) until (_hpos[vpos,1] <> 0);
                          hpos := 1;
                        end
                      else begin vpos := 1; hpos := 1; end;

        kUP:     If (vpos > 1) then
                   begin
                     Repeat Dec(vpos) until (_hpos[vpos,1] <> 0);
                     temp := hpos; hpos := 7;
                     While (hpos > 1) and ((_hpos[vpos,hpos] = 0) or
                       (_hpos[vpos,hpos] > _hpos[vpos+1,temp])) do Dec(hpos);
                   end
                 else
                   begin
                     vpos := 20; temp := hpos; hpos := 7;
                     While (hpos > 1) and ((_hpos[vpos,hpos] = 0) or
                       (_hpos[vpos,hpos] > _hpos[vpos+1,temp])) do Dec(hpos);
                   end;

        kDOWN:   If (vpos < 20) then
                   begin
                     Repeat Inc(vpos) until (_hpos[vpos,1] <> 0);
                     temp := hpos; hpos := 7;
                     While (hpos > 1) and ((_hpos[vpos,hpos] = 0) or
                       (_hpos[vpos,hpos] > _hpos[vpos-1,temp])) do Dec(hpos);
                   end
                 else
                   begin
                     vpos := 1; temp := hpos; hpos := 7;
                     While (hpos > 1) and ((_hpos[vpos,hpos] = 0) or
                       (_hpos[vpos,hpos] > _hpos[vpos-1,temp])) do Dec(hpos);
                   end;

        kHOME:   begin vpos := 1; hpos := 1; end;

        kEND:    begin
                   vpos := 20; hpos := 7;
                   While (hpos > 1) and (_hpos[vpos,hpos] = 0) do Dec(hpos);
                 end;

        kTAB:    Case vpos of
                    1: begin vpos := 2; hpos := 1; end;

                    2: If (hpos = 1) then begin vpos := 4; hpos := 1; end
                       else begin vpos := 7; hpos := 1; end;

                    3: begin vpos := 7; hpos := 1; end;

                    4: If (hpos = 1) then begin vpos := 5; hpos := 1; end
                       else begin vpos := 7; hpos := 1; end;

                    5: If (hpos = 1) then begin vpos := 2; hpos := 2; end
                       else begin vpos := 7; hpos := 1; end;

                    6: begin vpos := 7; hpos := 1; end;

                    7: If (hpos = 1) then begin vpos := 10; hpos := 1; end
                       else begin vpos := 7; hpos := 1; end;

                    8,
                    9: begin vpos := 7; hpos := 1; end;

                   10,11,
                   12: If carrier or (inst^.perc_voice in [2..5]) then begin vpos := 13; hpos := 2; end
                       else begin vpos := 17; hpos := 1; end;

                   13: If (hpos = 1) then
                         begin
                           If carrier or (inst^.perc_voice in [2..5]) then begin vpos := 13; hpos := 2; end
                           else begin vpos := 17; hpos := 1; end;
                         end
                       else begin vpos := 15; hpos := 1; end;

                   14: begin vpos := 16; hpos := 1; end;

                   15: If NOT (inst^.perc_voice in [2..5]) then begin vpos := 14; hpos := 1; end
                       else begin vpos := 17; hpos := 1; end;

                   16: begin vpos := 17; hpos := 1; end;

                   17,18,19,
                   20: begin
                         vpos := 1;
                         hpos := 1;
                         If NOT (inst^.perc_voice in [2..5]) then
                           carrier := NOT carrier;
                       end;
                 end;

        kShTAB:  Case vpos of
                    1: begin
                         vpos := 18;
                         hpos := 2;
                         If NOT (inst^.perc_voice in [2..5]) then
                           carrier := NOT carrier;
                       end;

                    2: If (hpos = 1) then begin vpos := 1; hpos := 1; end
                       else begin vpos := 5; hpos := 1; end;

                    3: begin vpos := 5; hpos := 1; end;

                    4: If (hpos = 1) then begin vpos := 2; hpos := 1; end
                       else begin vpos := 5; hpos := 1; end;

                    5: If (hpos = 1) then begin vpos := 4; hpos := 1; end
                       else begin vpos := 5; hpos := 1; end;

                    6: begin vpos := 5; hpos := 1; end;

                    7: If (hpos = 1) then begin vpos := 2; hpos := 2; end
                       else begin vpos := 5; hpos := 1; end;

                    8,
                    9: begin vpos := 5; hpos := 1; end;

                   10,11,
                   12: begin vpos := 7; hpos := 1; end;

                   13: If (hpos = 1) then begin vpos := 7; hpos := 1; end
                       else begin vpos := 10; hpos := 1; end;

                   14: begin vpos := 15; hpos := 1; end;

                   15: begin vpos := 13; hpos := 2; end;

                   16: begin vpos := 14; hpos := 1; end;

                   17,18,19,
                   20: If carrier then begin vpos := 16; hpos := 1; end
                       else If (inst^.perc_voice in [2..5]) then begin vpos := 15; hpos := 1; end
                            else begin vpos := 10; hpos := 1; end;
                 end;

        kSPACE:  If ctrl_pressed then _ADSR_preview_flag := NOT _ADSR_preview_flag
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

                      10,11,
                      12: If carrier then
                            inst^.fm_data.KSL_VOLUM_carrier :=
                            inst^.fm_data.KSL_VOLUM_carrier AND $3f+KSL_volume[vpos-10]
                          else
                            inst^.fm_data.KSL_VOLUM_modulator :=
                            inst^.fm_data.KSL_VOLUM_modulator AND $3f+KSL_volume[vpos-10];

                      13: If (hpos = 1) then
                            begin
                              If carrier then
                                inst^.fm_data.KSL_VOLUM_carrier :=
                                inst^.fm_data.KSL_VOLUM_carrier AND $3f+KSL_volume[vpos-10]
                              else
                                inst^.fm_data.KSL_VOLUM_modulator :=
                                inst^.fm_data.KSL_VOLUM_modulator AND $3f+KSL_volume[vpos-10];
                             end
                           else inst^.panning := panning_pos[hpos-2];

                      16: inst^.fm_data.FEEDBACK_FM := hpos-1+
                          inst^.fm_data.FEEDBACK_FM AND $0e;

                      17,18,19,
                      20: If (hpos = 1) then
                            begin
                              If carrier then
                                inst^.fm_data.AM_VIB_EG_carrier :=
                                inst^.fm_data.AM_VIB_EG_carrier XOR AM_Vibrato_EG[vpos-17]
                              else
                                inst^.fm_data.AM_VIB_EG_modulator :=
                                inst^.fm_data.AM_VIB_EG_modulator XOR AM_Vibrato_EG[vpos-17];
                            end
                          else
                            begin
                              If carrier then
                                inst^.fm_data.AM_VIB_EG_carrier :=
                                inst^.fm_data.AM_VIB_EG_carrier AND $0f0+
                                (vpos-18)*6+hpos-2
                              else
                                inst^.fm_data.AM_VIB_EG_modulator :=
                                inst^.fm_data.AM_VIB_EG_modulator AND $0f0+
                                (vpos-18)*6+hpos-2;
                            end;
                     end;
                     update_instr_data(instrum_page);
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

                   If (vpos = 14) and
                     ((inst^.fm_data.FEEDBACK_FM SHR 1) AND 7 < 7) then
                       inst^.fm_data.FEEDBACK_FM :=
                       inst^.fm_data.FEEDBACK_FM AND 1+
                     ((inst^.fm_data.FEEDBACK_FM SHR 1) AND 7 +1) SHL 1;

                   If (vpos = 15) and (inst^.fine_tune < 127) then
                     Inc(inst^.fine_tune);
                   update_instr_data(instrum_page);
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

                   If (vpos = 14) and
                     ((inst^.fm_data.FEEDBACK_FM SHR 1) AND 7 > 0) then
                       inst^.fm_data.FEEDBACK_FM :=
                       inst^.fm_data.FEEDBACK_FM AND 1+
                     ((inst^.fm_data.FEEDBACK_FM SHR 1) AND 7 -1) SHL 1;

                   If (vpos = 15) and (inst^.fine_tune > -127) then
                     Dec(inst^.fine_tune);
                   update_instr_data(instrum_page);
                 end;

      kCtLbr:  If shift_pressed then
                 begin
                   If (songdata.macro_speedup > 1) then
                     Dec(songdata.macro_speedup);
                   macro_speedup := songdata.macro_speedup;
                   keyboard_reset_buffer;
                 end
               else If (_4op_to_test = 0) then
                      If (current_inst > 1) then
                        begin
                          Dec(current_inst);
                          instrum_page := current_inst;
                          STATUS_LINE_refresh;
                          inst := Addr(songdata.instr_data[instrum_page]);
                          If NOT (inst^.perc_voice in [0,1]) then
                            carrier := FALSE;
                          page_build;
                          page_refresh;
                        end;

      kCtRbr:  If shift_pressed then
                 begin
                   Inc(songdata.macro_speedup);
                   If (calc_max_speedup(songdata.tempo) < songdata.macro_speedup) then
                     songdata.macro_speedup := calc_max_speedup(songdata.tempo);
                   macro_speedup := songdata.macro_speedup;
                   keyboard_reset_buffer;
                 end
               else If (_4op_to_test = 0) then
                      If (current_inst < 255) then
                        begin
                          Inc(current_inst);
                          instrum_page := current_inst;
                          STATUS_LINE_refresh;
                          inst := Addr(songdata.instr_data[instrum_page]);
                          If NOT (inst^.perc_voice in [0,1]) then
                            carrier := FALSE;
                          page_build;
                          page_refresh;
                        end;

        kF1:     begin
                   Dec(xstart);
                   HideCursor;
                   move_to_screen_data := ptr_screen_backup;
                   move_to_screen_area[1] := xstart;
                   move_to_screen_area[2] := ystart;
                   move_to_screen_area[3] := xstart+71+2;
                   move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode]+1;
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
                   move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode]+1;
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
                   move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode]+1;
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
                   move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode]+1;
                   move2screen;

                   quick_cmd := FALSE;
                   FILE_open('*.a2i$*.a2f$*.a2b$*.a2w$'+
                             '*.bnk$*.cif$*.fib$*.fin$*.ibk$*.ins$*.sbi$*.sgi$',FALSE);// load bank is not possible
                   update_instr_data(instrum_page);
                   GOTO _jmp1;
                 end;

        kCtrlO:  begin
                   Dec(xstart);
                   HideCursor;
                   move_to_screen_data := ptr_screen_backup;
                   move_to_screen_area[1] := xstart;
                   move_to_screen_area[2] := ystart;
                   move_to_screen_area[3] := xstart+71+2;
                   move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode]+1;
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
                   move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode]+1;
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
                   move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode]+1;
                   move2screen;
                   MACRO_EDITOR(current_inst,TRUE);
                   GOTO _jmp1;
                 end;

        kENTER:  If (inst^.perc_voice in [0,1]) then
                   carrier := NOT carrier;
        else nope := TRUE;
      end;

      If shift_pressed and
         (UpCase(CHR(LO(fkey))) in ['M','B','S','T','C','H']) then
        begin
          Case UpCase(CHR(LO(fkey))) of
            'M': inst^.perc_voice := 0;
            'B': inst^.perc_voice := 1;
            'S': inst^.perc_voice := 2;
            'T': inst^.perc_voice := 3;
            'C': inst^.perc_voice := 4;
            'H': inst^.perc_voice := 5;
          end;
          If NOT (inst^.perc_voice in [0,1]) then carrier := FALSE;
          page_build;
          page_refresh;
          nope := FALSE;
        end;
_end:
{$IFDEF __TMT__}
    keyboard_reset_buffer_alt;
{$ELSE}
    emulate_screen;
{$ENDIF}
    until (nope and (fkey = kESC)) or _force_program_quit;

  Dec(xstart);
  HideCursor;
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+71+2;
  move_to_screen_area[4] := ystart+25+ie_vsize_shift[program_screen_mode]+1;
  move2screen;
end;

procedure copy_object;

var
  temp: Byte;

begin
{$IFDEF __TMT__}
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
{$IFDEF __TMT__}
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
             update_instr_data(instrum_page);
           end;

        1: begin
             songdata.instr_data[instrum_page] := clipboard.instrument.data[1];
             update_instr_data(instrum_page);
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
             update_instr_data(instrum_page);
           end;

        1: begin
             songdata.instr_data[instrum_page] := clipboard.instrument.data[1];
             songdata.instr_macros[instrum_page] := clipboard.instrument.macros[1];
             songdata.dis_fmreg_col[instrum_page] := clipboard.instrument.dis_fmreg_col[1];
             update_instr_data(instrum_page);
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
{$IFDEF __TMT__}
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
  temp_inst: Record
               name:   String;
               data:   tADTRACK2_INS;
               macros: tREGISTER_TABLE;
             end;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:instr_control_proc';
{$ENDIF}
  Case mn_environment.keystroke of
      kNPmins: If (play_status <> isStopped) then
                 If NOT mn_environment.is_editing then
                   If NOT play_single_patt then
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
                               If shift_pressed then calibrate_player(temp,temp2,TRUE,FALSE)
                               else calibrate_player(temp,0,TRUE,FALSE);
                             end;
                         end;
                     end;

      kNPplus: If (play_status <> isStopped) then
                 If NOT mn_environment.is_editing then
                   If NOT play_single_patt then
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
                               If shift_pressed then calibrate_player(temp,temp2,TRUE,FALSE)
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
                 end;

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
                 While (songdata.instr_names[ins1][1] <> '') do Inc(ins1);
                 ins2 := SUCC(ins1);
                 While (songdata.instr_names[ins2][1] <> '') do Inc(ins2);

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

                 mn_environment.do_refresh := TRUE;
                 mn_environment.refresh;
               end;

    kSPACE:  begin
               If (songdata.instr_names[instrum_page][1] <> '') then
                 begin
                   If (marked_instruments < 2) then
                     begin
                       songdata.instr_names[instrum_page][1] := '';
                       last_marked := instrum_page;
                     end
                   else begin
                          songdata.instr_names[last_marked][1] := ' ';
                          songdata.instr_names[instrum_page][1] := '';
                          last_marked := instrum_page;
                        end;
                 end
               else songdata.instr_names[instrum_page][1] := ' ';

               mn_environment.do_refresh := TRUE;
               mn_environment.refresh;
             end;
  end;

  instrum_page := mn_environment.curr_pos;
  current_inst := instrum_page;

  If shift_pressed and
     (UpCase(CHR(LO(mn_environment.keystroke))) in ['M','B','S','T','C','H']) then
    Case UpCase(CHR(LO(mn_environment.keystroke))) of
      'M': songdata.instr_data[current_inst].perc_voice := 0;
      'B': songdata.instr_data[current_inst].perc_voice := 1;
      'S': songdata.instr_data[current_inst].perc_voice := 2;
      'T': songdata.instr_data[current_inst].perc_voice := 3;
      'C': songdata.instr_data[current_inst].perc_voice := 4;
      'H': songdata.instr_data[current_inst].perc_voice := 5;
    end;

  INSTRUMENT_CONTROL_page_refresh(instrum_page);
  If (marked_instruments = 1) then
    begin
      For temp := 1 to 255 do
        If (temp <> last_marked) then
          songdata.instr_names[temp][1] := ' ';
      If (instrum_page <> last_marked) then
        songdata.instr_names[instrum_page][1] := '>';
      mn_environment.do_refresh := TRUE;
      mn_environment.refresh;
    end;

  If is_4op_mode then
    Case marked_instruments of
      0: begin
           ShowStr(mn_environment.v_dest,INSCTRL_xshift+39,INSCTRL_yshift+26,
                   ExpStrL('',17,'Í'),
                   dialog_background+dialog_border);
           STATUS_LINE_refresh;
         end;

      1: begin
           temps := connection_str[tDUMMY_BUFF(Addr(songdata.instr_data[_1st_marked])^)[_index[11]] AND 1]+'/'+
                    connection_str[tDUMMY_BUFF(Addr(songdata.instr_data[instrum_page])^)[_index[11]] AND 1];
           ShowCStr(mn_environment.v_dest,INSCTRL_xshift+41,INSCTRL_yshift+26,
                  ' õ~'+byte2hex(_1st_marked)+
                  '~,ô~'+byte2hex(instrum_page)+'~ '+temps+' ',
                  dialog_background+dialog_border,
                  dialog_background+dialog_context);
         end;

      2: If (last_marked <> _1st_marked) then
           begin
             temps := connection_str[tDUMMY_BUFF(Addr(songdata.instr_data[_1st_marked])^)[_index[11]] AND 1]+'/'+
                      connection_str[tDUMMY_BUFF(Addr(songdata.instr_data[_2nd_marked])^)[_index[11]] AND 1];
             ShowCStr(mn_environment.v_dest,INSCTRL_xshift+41,INSCTRL_yshift+26,
                      ' õ~'+byte2hex(_1st_marked)+
                      '~,ô~'+byte2hex(_2nd_marked)+'~ '+temps+' ',
                      dialog_background+dialog_border,
                      dialog_background+dialog_context);
           end
         else
           begin
             temps := connection_str[tDUMMY_BUFF(Addr(songdata.instr_data[_2nd_marked])^)[_index[11]] AND 1]+'/'+
                      connection_str[tDUMMY_BUFF(Addr(songdata.instr_data[_1st_marked])^)[_index[11]] AND 1];
             ShowCStr(mn_environment.v_dest,INSCTRL_xshift+41,INSCTRL_yshift+26,
                      ' õ~'+byte2hex(_2nd_marked)+
                      '~,ô~'+byte2hex(_1st_marked)+'~ '+temps+' ',
                      dialog_background+dialog_border,
                      dialog_background+dialog_context);
           end
    end
  else ShowStr(mn_environment.v_dest,INSCTRL_xshift+41,INSCTRL_yshift+26,
               ExpStrL('',17,'Í'),
               dialog_background+dialog_border);

  If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
    If (_4op_to_test <> 0) then
      INSTRUMENT_test(LO(_4op_to_test),HI(_4op_to_test),count_channel(pattern_hpos),mn_environment.keystroke,TRUE)
    else INSTRUMENT_test(instrum_page,BYTE_NULL,count_channel(pattern_hpos),mn_environment.keystroke,TRUE);
end;

function INSTRUMENT_CONTROL: Byte;

const
  new_keys: array[1..20] of Word = (kESC,kENTER,kTAB,kShTAB,kCtrlO,kCtrlM,kAltC,kCtrlA,kCtrlQ,kCtrlE,
                                    kF1,kF2,kF4,kAltF2,kCtrlF2,kCtrlS,kShF2,kF3,kCtrlL,kShF3);
var
  old_keys: array[1..20] of Word;
  temp: Byte;
  temp_marks: array[1..255] of Char;

label _jmp1;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL';
{$ENDIF}
  For temp := 1 to 255 do
    begin
      temp_marks[temp] := songdata.instr_names[temp][1];
      songdata.instr_names[temp][1] := ' ';
    end;

  songdata_crc := Update32(ptr_songdata,SizeOf(songdata),0);
  For temp := 1 to 255 do
    songdata.instr_names[temp][1] := temp_marks[temp];

_jmp1:
  If _force_program_quit then EXIT;

  keyboard_reset_buffer;
  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  mn_environment.v_dest := ptr_temp_screen;
  ScreenMemCopy(screen_ptr,mn_environment.v_dest);

  mn_setting.center_box := FALSE;
  mn_setting.cycle_moves := FALSE;
  mn_environment.edit_pos := 9;
  mn_environment.ext_proc := instr_control_proc;
  mn_environment.ext_proc_rt := instr_control_ai;
  mn_environment.context := ' TAB Ä EDiTOR ';

  Move(mn_setting.terminate_keys,old_keys,SizeOf(old_keys));
  Move(new_keys,mn_setting.terminate_keys,SizeOf(new_keys));

  Frame(ptr_temp_screen,INSCTRL_xshift+07,INSCTRL_yshift+05,
        INSCTRL_xshift+83,INSCTRL_yshift+26,
        dialog_background+dialog_border,
        ' iNSTRUMENT CONTROL (iNS_  ) ',
        dialog_background+dialog_title,
        double);

  fr_setting.update_area := FALSE;
  fr_setting.shadow_enabled := FALSE;
  Frame(ptr_temp_screen,INSCTRL_xshift+09,INSCTRL_yshift+06,
        INSCTRL_xshift+34,INSCTRL_yshift+25,
        dialog_background+dialog_border,
        '',
        dialog_background+dialog_title,
        single);

  Frame(ptr_temp_screen,INSCTRL_xshift+36,INSCTRL_yshift+06,
        INSCTRL_xshift+81,INSCTRL_yshift+25,
        dialog_background+dialog_border,
        '',
        dialog_background+dialog_title,
        single);

  ShowStr(ptr_temp_screen,INSCTRL_xshift+66,INSCTRL_yshift+25,
                         ' TAB Ä EDITOR ',
                          dialog_background+dialog_context);
  ShowStr(ptr_temp_screen,INSCTRL_xshift+58,INSCTRL_yshift+26,
                         ' [SHiFT] TAB Ä MACROS ',
                          dialog_background+dialog_context);

  ShowVStr(mn_environment.v_dest,INSCTRL_xshift+37,INSCTRL_yshift+07,ExpStrL('',18,#28),
           dialog_background+instrument_ai_off);
  ShowVStr(mn_environment.v_dest,INSCTRL_xshift+38,INSCTRL_yshift+06,'Â'+ExpStrL('',18,'³')+'Á',
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
  If NOT _force_program_quit then
    Menu(songdata.instr_names,INSCTRL_xshift+38,INSCTRL_yshift+06,instrum_page,42,18,255,'');

  INSTRUMENT_CONTROL_page_refresh(instrum_page);
  move_to_screen_data := ptr_temp_screen;
  move_to_screen_area[1] := INSCTRL_xshift+7;
  move_to_screen_area[2] := INSCTRL_yshift+5;
  move_to_screen_area[3] := INSCTRL_xshift+83+2;
  move_to_screen_area[4] := INSCTRL_yshift+26+1;
{$IFDEF __TMT__}
  toggle_waitretrace := TRUE;
{$ENDIF}
  move2screen_alt;

  mn_environment.v_dest := screen_ptr;
  If NOT _force_program_quit then
    temp := Menu(songdata.instr_names,INSCTRL_xshift+38,INSCTRL_yshift+06,instrum_page,42,18,255,'');

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

  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := INSCTRL_xshift+7;
  move_to_screen_area[2] := INSCTRL_yshift+5;
  move_to_screen_area[3] := INSCTRL_xshift+83+2;
  move_to_screen_area[4] := INSCTRL_yshift+26+1;
  move2screen;

  Case mn_environment.keystroke of
    kAltC:   begin
               mn_setting.cycle_moves := TRUE;
               temp := Menu(copymnu1,01,01,copypos1,30,15,15,' COPY OBJECT ');
               If (mn_environment.keystroke <> kESC) then
                 begin
                   copypos1 := temp;
                   clipboard.object_type := tCOPY_OBJECT(temp);
                   copy_object;
                 end;
               GOTO _jmp1;
             end;

    kTAB:    begin
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
               update_instr_data(instrum_page);
               quick_cmd := FALSE;
               GOTO _jmp1;
             end;

    kF4,
    kCtrlA:  begin
               NUKE;
               GOTO _jmp1;
             end;
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

  If (mn_environment.keystroke = kENTER) then INSTRUMENT_CONTROL := instrum_page
  else INSTRUMENT_CONTROL := 0;
end;

procedure instr_control_proc_alt;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:instr_control_proc_alt';
{$ENDIF}
  INSTRUMENT_CONTROL_page_refresh_alt(mn_environment.curr_pos);
  If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
    If (_4op_to_test <> 0) then
      INSTRUMENT_test(LO(_4op_to_test),HI(_4op_to_test),count_channel(pattern_hpos),mn_environment.keystroke,FALSE)
    else INSTRUMENT_test(mn_environment.curr_pos,BYTE_NULL,count_channel(pattern_hpos),mn_environment.keystroke,FALSE);
end;

function INSTRUMENT_CONTROL_alt(instr: Byte; title: String): Byte;

var
  temp: Byte;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'INSTEDIT.INC:INSTRUMENT_CONTROL_alt';
{$ENDIF}
  keyboard_reset_buffer;
  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  mn_environment.v_dest := ptr_temp_screen;
  ScreenMemCopy(screen_ptr,mn_environment.v_dest);

  mn_setting.center_box := FALSE;
  mn_setting.cycle_moves := FALSE;
  mn_environment.ext_proc := instr_control_proc_alt;
  mn_environment.ext_proc_rt := instr_control_ai;

  Frame(ptr_temp_screen,INSCTRL_xshift+07,INSCTRL_yshift+05,
        INSCTRL_xshift+83,INSCTRL_yshift+26,
        dialog_background+dialog_border,
        ' '+title+' ',
        dialog_background+dialog_title,
        double);

  fr_setting.update_area := FALSE;
  fr_setting.shadow_enabled := FALSE;
  Frame(ptr_temp_screen,INSCTRL_xshift+09,INSCTRL_yshift+06,
        INSCTRL_xshift+34,INSCTRL_yshift+25,
        instrument_bckg+instrument_border,
        '',
        instrument_bckg+instrument_title,
        single);

  Frame(ptr_temp_screen,INSCTRL_xshift+36,INSCTRL_yshift+06,
        INSCTRL_xshift+81,INSCTRL_yshift+25,
        instrument_bckg+instrument_border,
        '',
        instrument_bckg+instrument_title,
        single);

  ShowVStr(mn_environment.v_dest,INSCTRL_xshift+37,INSCTRL_yshift+07,ExpStrL('',18,#28),
           dialog_background+instrument_ai_off);
  ShowVStr(mn_environment.v_dest,INSCTRL_xshift+38,INSCTRL_yshift+06,'Â'+ExpStrL('',18,'³')+'Á',
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
{$IFDEF __TMT__}
  toggle_waitretrace := TRUE;
{$ENDIF}
  move2screen_alt;

  mn_environment.v_dest := screen_ptr;
  If NOT _force_program_quit then
    temp := Menu(songdata.instr_names,INSCTRL_xshift+38,INSCTRL_yshift+06,instr,42,18,255,'');

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
