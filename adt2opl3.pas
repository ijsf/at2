unit AdT2opl3;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

{$IFDEF GO32V2}
const
  ___OPL3OUT_UNIT_DATA_START___: Dword = 0;
{$ENDIF}

procedure opl2out(reg,data: Word);
procedure opl3out_proc(reg,data: Word);
procedure opl3exp(data: Word);

type
  tOPL3OUT_proc = procedure(reg,data: Word);

const
  opl3out: tOPL3OUT_proc = @opl3out_proc;

{$IFDEF GO32V2}

const
  opl3port: Word = 0;
  opl_latency: Byte = 0;

function detect_OPL3: Boolean;

{$ELSE}

const
  renew_wav_files_flag: Boolean = TRUE;
  opl3_channel_recording_mode: Boolean = FALSE;
  opl3_record_channel: array[1..20] of Boolean = (
    FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,
    FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);

procedure flush_WAV_data;
procedure opl3_init;
procedure opl3_done;
procedure snd_init;
procedure snd_done;
procedure snd_SetTimer(value: Longint);
procedure update_recorded_channels;

const
  opl3_flushmode: Boolean = FALSE;

const
  WAV_BUFFER_SIZE = 18*512*1024; // cache buffer size -> 512k per file

var
  wav_buffer_len: Longint;
  wav_buffer: array[0..18,0..PRED(WAV_BUFFER_SIZE)] of Byte;

{$ENDIF}

{$IFDEF GO32V2}

const
  ___OPL3OUT_UNIT_DATA_END___: Dword = 0;

{$ENDIF}

implementation

{$IFDEF GO32V2}

uses
  GO32,
  AdT2sys,
  TxtScrIO;

{$IFDEF GO32V2}
procedure  ___OPL3OUT_IRQ_CODE_START___; begin end;
{$ENDIF}

var
  _opl_regs_cache: array[WORD] of Word;

procedure opl2out(reg,data: Word);
begin
  If (_opl_regs_cache[reg] <> data) then
    _opl_regs_cache[reg] := data
  else EXIT;

  asm
        mov     ax,reg
        mov     dx,word ptr [opl3port]
        or      ah,ah
        jz      @@1
        add     dx,2
@@1:    out     dx,al
        mov     ecx,6
@@2:    in      al,dx
        loop    @@2
        inc     dl
        mov     ax,data
        out     dx,al
        dec     dl
        mov     ecx,36
@@3:    in      al,dx
        loop    @@3
  end;
end;

procedure opl3out_proc(reg,data: Word);
begin
  If (_opl_regs_cache[reg] <> data) then
    _opl_regs_cache[reg] := data
  else EXIT;

  asm
        mov     ax,reg
        mov     dx,word ptr [opl3port]
        or      ah,ah
        jz      @@1
        add     dx,2
@@1:    out     dx,al
        inc     dl
        mov     ax,data
        out     dx,al
        dec     dl
        mov     ecx,26
@@2:    in      al,dx
        loop    @@2
  end;
end;

procedure opl3exp(data: Word);
begin
  if (_opl_regs_cache[(data AND $ff) OR $100] <> data SHR 8) then
    _opl_regs_cache[(data AND $ff) OR $100] := data SHR 8
  else EXIT;

  asm
        mov     ax,data
        mov     dx,word ptr [opl3port]
        add     dx,2
        out     dx,al
        mov     ecx,6
@@1:    in      al,dx
        loop    @@1
        inc     dl
        mov     al,ah
        out     dx,al
        mov     ecx,36
@@2:    in      al,dx
        loop    @@2
  end;
end;

{$IFDEF GO32V2}
procedure  ___OPL3OUT_IRQ_CODE_END___; begin end;
{$ENDIF}

function detect_OPL3: Boolean;

var
  result: Boolean;

begin
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2OPL3.PAS:detect_OPL3';

  asm
        push    dword 04h
        push    dword 80h
        push    dword 04h
        push    dword 60h
        call    opl2out
        call    WaitRetrace
        call    opl2out
        call    WaitRetrace
        mov     dx,opl3port
        in      al,dx
        and     al,0e0h
        mov     bl,al
        push    dword 04h
        push    dword 21h
        push    dword 02h
        push    dword 0ffh
        call    opl2out
        call    WaitRetrace
        call    opl2out
        call    WaitRetrace
        mov     dx,opl3port
        in      al,dx
        and     al,0e0h
        mov     bh,al
        cmp     bx,0c000h
        jnz     @@1
        push    dword 04h
        push    dword 80h
        push    dword 04h
        push    dword 60h
        call    opl2out
        call    WaitRetrace
        call    opl2out
        call    WaitRetrace
        mov     dx,opl3port
        in      al,dx
        and     al,6
        or      al,al
        jnz     @@1
        mov     result,TRUE
        jmp     @@2
  @@1:  mov     result,FALSE
  @@2:
  end;

  detect_OPL3 := result;
end;

{$ELSE}

uses
  MATH,SysUtils,
  AdT2unit,AdT2sys,TxtScrIO,StringIO,
  SDL_Types,SDL_Audio,OPL3EMU;

const
  opl3_sample_buffer_ptr: Pointer = NIL;
  opl3_sample_buffer_chan_ptr: array[1..18] of Pointer = (
    NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL);

var
  sample_frame_size: Longint;
  sdl_audio_spec: SDL_AudioSpec;

procedure flush_WAV_data;

type
  tWAV_HEADER = Record
     file_desc: array[0..3] of Char;    // =="RIFF"
     file_size: Dword;                  // ==filesize-8
     wav_desc: array[0..3] of Char;     // =="WAVE"
     format_desc: array[0..3] of Char;  // =="fmt "
     wav_size: Dword;                   // ==16
     wav_type: Word;                    // ==1 (PCM)
     num_channels: Word;                // ==2 (Stereo)
     samples_sec: Dword;                // sampling frequency
     bytes_sec: Dword;                  // ==num_channels*samples_sec*bits_sample/8
     block_align: Word;                 // ==num_channels*bits_sample/8
     bits_sample: Word;                 // ==16
     data_desc: array[0..3] of Char;    // "data"
     data_size: Dword;                  // size of data
   end;

const
  wav_header: tWAV_HEADER = (file_desc:    'RIFF';
                             file_size:    SizeOf(tWAV_HEADER)-8;
                             wav_desc:     'WAVE';
                             format_desc:  'fmt ';
                             wav_size:     16;
                             wav_type:     1;
                             num_channels: 2;
                             samples_sec:  49716;
                             bytes_sec:    2*49716*16 DIV 8;
                             block_align:  2*16 DIV 8;
                             bits_sample:  16;
                             data_desc:    'data';
                             data_size:    0);

var
  wav_file: File;
  temp,bytes_to_write: Longint;
  idx,from_ch,to_ch: Byte;
  filename_suffix: String;

begin
  bytes_to_write := wav_buffer_len;
  // flush when at least 1 sec of recorded data
  If (bytes_to_write < 2*sdl_sample_rate*16 DIV 8) then EXIT;
  If NOT ((play_status = isPlaying) and (sdl_opl3_emulator <> 0)) then EXIT;

  // prepare output directory
  If NOT DirectoryExists(Copy(sdl_wav_directory,1,Length(sdl_wav_directory)-Length(NameOnly(sdl_wav_directory)))) then
    If NOT CreateDir(Copy(sdl_wav_directory,1,Length(sdl_wav_directory)-Length(NameOnly(sdl_wav_directory)))) then
      EXIT;

  wav_buffer_len := 0;
  If NOT opl3_channel_recording_mode then
    begin
      from_ch := 0;
      to_ch := 0;
    end
  else
    begin
      from_ch := 1;
      If NOT percussion_mode then to_ch := songdata.nm_tracks
      else to_ch := 18;
    end;

  For idx := from_ch to to_ch do
    begin
      filename_suffix := '';
      If (idx <> 0) then
        If NOT (opl3_record_channel[idx]) or (is_4op_chan(idx) and NOT (idx in _4op_tracks_hi)) then CONTINUE
        else If NOT is_4op_chan(idx) then
               If percussion_mode then
                 Case idx of
                   16: filename_suffix := ' ('+ExpStrL(Num2str(idx,10),2,'0')+'_BD)';
                   17: filename_suffix := ' ('+ExpStrL(Num2str(idx,10),2,'0')+'_SD_HH)';
                   18: filename_suffix := ' ('+ExpStrL(Num2str(idx,10),2,'0')+'_TT_TC)';
                   else filename_suffix := ' ('+ExpStrL(Num2str(idx,10),2,'0')+')';
                 end
               else filename_suffix := ' ('+ExpStrL(Num2str(idx,10),2,'0')+')'
             else filename_suffix := ' ('+ExpStrL(Num2str(idx,10),2,'0')+'_'
                                         +ExpStrL(Num2str(idx+1,10),2,'0')+'_4OP)';

      If opl3_flushmode then
        Assign(wav_file,Copy(sdl_wav_directory,1,Length(sdl_wav_directory)-Length(NameOnly(sdl_wav_directory)))+
                        BaseNameOnly(sdl_wav_directory)+filename_suffix+'.wav')
      else Assign(wav_file,sdl_wav_directory+BaseNameOnly(songdata_title)+filename_suffix+'.wav');

      // update WAV header
      {$i-}
      If renew_wav_files_flag then
        begin
          RewriteF(wav_file);
          wav_header.file_size := 0;
          wav_header.data_size := 0;
        end
      else ResetF(wav_file);
      {$i+}
      If renew_wav_files_flag or (IOresult <> 0) then
        begin
          {$i-}
          RewriteF(wav_file);
          {$i+}
          If (IOresult <> 0) then
            begin
              Close(wav_file);
              {$i-}
              EraseF(wav_file);
              {$i+}
              If (IOresult <> 0) then ;
              EXIT;
            end;
          wav_header.samples_sec := sdl_sample_rate;
          wav_header.bytes_sec := 2*sdl_sample_rate*16 DIV 8;
          wav_header.file_size := bytes_to_write;
          wav_header.data_size := bytes_to_write;
          {$i-}
          BlockWriteF(wav_file,wav_header,SizeOf(wav_header),temp);
          {$i+}
          If (IOresult <> 0) or
             (temp <> SizeOf(wav_header)) then
            begin
              CloseF(wav_file);
              {$i-}
              EraseF(wav_file);
              {$i+}
              If (IOresult <> 0) then ;
              EXIT;
            end;
        end
      else begin
             {$i-}
             BlockReadF(wav_file,wav_header,SizeOf(wav_header),temp);
             {$i+}
             If (IOresult <> 0) or
                (temp <> SizeOf(wav_header)) then
               begin
                 CloseF(wav_file);
                 {$i-}
                 EraseF(wav_file);
                 {$i+}
                 If (IOresult <> 0) then ;
                 EXIT;
               end;
             wav_header.file_size := wav_header.file_size+bytes_to_write;
             wav_header.data_size := wav_header.data_size+bytes_to_write;
             {$i-}
             ResetF_RW(wav_file);
             {$i+}
             If (IOresult <> 0) then
               begin
                 CloseF(wav_file);
                 {$i-}
                 EraseF(wav_file);
                 {$i+}
                 If (IOresult <> 0) then ;
                 EXIT;
               end;
             {$i-}
             BlockWriteF(wav_file,wav_header,SizeOf(wav_header),temp);
             {$i+}
             If (IOresult <> 0) or
                (temp <> SizeOf(wav_header)) then
               begin
                 CloseF(wav_file);
                 {$i-}
                 EraseF(wav_file);
                 {$i+}
                 If (IOresult <> 0) then ;
                 EXIT;
               end;
             {$i-}
             SeekF(wav_file,FileSize(wav_file));
             {$i+}
             If (IOresult <> 0) then
               begin
                 CloseF(wav_file);
                 {$i-}
                 EraseF(wav_file);
                 {$i+}
                 If (IOresult <> 0) then ;
                 EXIT;
               end;
           end;

      // write sample data
      {$i-}
      BlockWriteF(wav_file,wav_buffer[idx],bytes_to_write,temp);
      {$i+}
      If (IOresult <> 0) or (temp <> bytes_to_write) then
        begin
          CloseF(wav_file);
          {$i-}
          EraseF(wav_file);
          {$i+}
          If (IOresult <> 0) then ;
        end
      else
        CloseF(wav_file);
    end;

  renew_wav_files_flag := FALSE;
end;

procedure opl2out(reg,data: Word);
begin
  // relevant only for DOS version -> option opl_latency=1
  opl3out_proc(reg,data);
end;

procedure opl3out_proc(reg,data: Word);
begin
  OPL3EMU_WriteReg(reg,data);
end;

procedure opl3exp(data: Word);
begin
  OPL3EMU_WriteReg((data AND $ff) OR $100,data SHR 8);
end;

procedure opl3_init;
begin
  OPL3EMU_init;
end;

procedure opl3_done;
begin
  SDL_PauseAudio(1);
end;

// value in Hz for timer
procedure snd_SetTimer(value: Longint);
begin
  If (value < 18) then value := 18;
  sample_frame_size := ROUND(sdl_sample_rate/value*(1+sdl_timer_slowdown/100));
end;

function get_num_files: Byte;

var
  idx,result: Byte;

begin
  result := 18;
  For idx := 1 to 18 do
    If NOT opl3_record_channel[idx] then Dec(result);
  If (result <> 0) then get_num_files := result
  else get_num_files := 1;
end;

procedure update_recorded_channels;

var
  idx: Byte;

begin
  For idx := 1 to 20 do
    If channel_flag[idx] then opl3_record_channel[idx] := TRUE
    else opl3_record_channel[idx] := FALSE;
  For idx := SUCC(songdata.nm_tracks) to 20 do
    opl3_record_channel[idx] := FALSE;
  If percussion_mode then
    begin
      If NOT channel_flag[19] then opl3_record_channel[18] := FALSE;
      If NOT channel_flag[20] then opl3_record_channel[17] := FALSE;
    end;
end;

procedure playcallback(var userdata; stream: pByte; len: Longint); cdecl;

const
  counter_idx: Longint = 0;

var
  counter: Longint;
  idx: Byte;
  IRQ_freq_val: Longint;
  buffer_ptr_table: array[1..18] of pDword;
  buf_size: Longint;

begin
  If NOT rewind then
    IRQ_freq_val := IRQ_freq
  else IRQ_freq_val := IRQ_freq * 20;

  For counter := 0 to PRED(len DIV 4) do
    begin
      Inc(counter_idx);
      If (counter_idx >= sample_frame_size) then
        begin
          counter_idx := 0;
          If (ticklooper > 0) then
            If (fast_forward or rewind) and NOT replay_forbidden then
              poll_proc
            else
          else If NOT replay_forbidden then
                 poll_proc;

          If (macro_ticklooper = 0) then
            macro_poll_proc;

          Inc(ticklooper);
          If (ticklooper >= IRQ_freq_val DIV tempo) then
            ticklooper := 0;

          Inc(macro_ticklooper);
          If (macro_ticklooper >= IRQ_freq_val DIV (tempo*macro_speedup)) then
            macro_ticklooper := 0;
        end;

      // update partial channel sample buffer pointers
      For idx := 1 to 18 do
        buffer_ptr_table[idx] := opl3_sample_buffer_chan_ptr[idx]+counter*4;
      // update one step
      OPL3EMU_PollProc(opl3_sample_buffer_ptr+counter*4,buffer_ptr_table);
    end;

  // update SDL Audio sample buffer
  Move(opl3_sample_buffer_ptr^,stream^,len);
  If (play_status = isStopped) then
    begin
      wav_buffer_len := 0;
      EXIT;
    end;

  // calculate cache buffer size
  If opl3_channel_recording_mode then
    buf_size := WAV_BUFFER_SIZE DIV 18 * get_num_files
  else buf_size := WAV_BUFFER_SIZE DIV 18;

  // WAV dumper
  If (sdl_opl3_emulator <> 0) then
    If (wav_buffer_len+len <= buf_size) then
      begin
        // update main sample buffer
        Move(opl3_sample_buffer_ptr^,wav_buffer[0][wav_buffer_len],len);
        // update partial channel sample buffers
        For idx := 1 to 18 do
          Move(opl3_sample_buffer_chan_ptr[idx]^,wav_buffer[idx][wav_buffer_len],len);
        Inc(wav_buffer_len,len);
      end
    else
      begin
        // sample buffers full -> flush to disk!
        flush_WAV_data;
        // update main sample buffer
        Move(opl3_sample_buffer_ptr^,wav_buffer[0][wav_buffer_len],len);
        // update partial channel sample buffers
        For idx := 1 to 18 do
          Move(opl3_sample_buffer_chan_ptr[idx]^,wav_buffer[idx][wav_buffer_len],len);
        Inc(wav_buffer_len,len);
      end;
end;

procedure snd_init;

var
  idx: Byte;

begin
  GetMem(opl3_sample_buffer_ptr,sdl_sample_buffer*4);
  For idx := 1 to 18 do GetMem(opl3_sample_buffer_chan_ptr[idx],sdl_sample_buffer*4);
  sample_frame_size := ROUND(sdl_sample_rate/50*(1+sdl_timer_slowdown/100));;

  opl3_init;

  sdl_audio_spec.freq := sdl_sample_rate;
  sdl_audio_spec.format := AUDIO_S16;
  sdl_audio_spec.channels := 2;
  sdl_audio_spec.samples := sdl_sample_buffer;
  sdl_audio_spec.callback := @playcallback;
  sdl_audio_spec.userdata := NIL;

  If (SDL_Openaudio(@sdl_audio_spec,NIL) < 0) then
    begin
      WriteLn('SDL: Audio initialization error');
      HALT(1);
    end;

  WriteLn('  Sample buffer size: ',sdl_audio_spec.samples,' samples (requested ',sdl_sample_buffer,')');
  WriteLn('  Sampling rate: ',sdl_audio_spec.freq,' Hz (requested ',sdl_sample_rate,')');

  sdl_sample_rate := sdl_audio_spec.freq;
  sdl_sample_buffer := sdl_audio_spec.samples;

  SDL_PauseAudio(0);
end;

procedure snd_done;

var
  idx: Byte;

begin
  SDL_PauseAudio(1);
  SDL_CloseAudio;
  FreeMem(opl3_sample_buffer_ptr);
  For idx := 1 to 18 do FreeMem(opl3_sample_buffer_chan_ptr[idx]);
  opl3_sample_buffer_ptr := NIL;
end;

{$ENDIF}

{$IFDEF GO32V2}

var
  old_exit_proc: procedure;

procedure new_exit_proc;
begin
  Lock_Data(___OPL3OUT_UNIT_DATA_START___,DWORD(Addr(___OPL3OUT_UNIT_DATA_END___))-DWORD(Addr(___OPL3OUT_UNIT_DATA_START___)));
  Lock_Code(@___OPL3OUT_IRQ_CODE_START___,DWORD(@___OPL3OUT_IRQ_CODE_END___)-DWORD(@___OPL3OUT_IRQ_CODE_START___));
  ExitProc := @old_exit_proc;
end;

begin
  FillWord(_opl_regs_cache,SizeOf(_opl_regs_cache) DIV SizeOf(WORD),NOT 0);
  Lock_Data(___OPL3OUT_UNIT_DATA_START___,DWORD(Addr(___OPL3OUT_UNIT_DATA_END___))-DWORD(Addr(___OPL3OUT_UNIT_DATA_START___)));
  Lock_Code(@___OPL3OUT_IRQ_CODE_START___,DWORD(@___OPL3OUT_IRQ_CODE_END___)-DWORD(@___OPL3OUT_IRQ_CODE_START___));
  @old_exit_proc := ExitProc;
  ExitProc := @new_exit_proc;

{$ENDIF}

end.
