unit AdT2opl3;
interface

const
  renew_wav_files_flag: Boolean = FALSE;
  opl3_channel_recording_mode: Boolean = FALSE;
  opl3_record_channel: array[1..20] of Boolean = (
    FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,
    FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);

procedure flush_WAV_data;
procedure opl2out(reg,data: Word);
procedure opl3out_proc(reg,data: Word);
procedure opl3exp(data: Word);
procedure opl3_init;
procedure opl3_deinit;
procedure snd_Init;
procedure snd_Deinit;
procedure snd_SetTimer(value: Longint);
procedure update_recorded_channels;

type
  tOPL3OUT_proc = procedure(reg,data: Word);

const
  opl3out: tOPL3OUT_proc = opl3out_proc;
  opl3_flushmode: Boolean = FALSE;

const
  WAV_BUFFER_SIZE = 18*256*1024; // cache buffer size -> 256k per file
 
var
  wav_buffer_len: Longint;  
  wav_buffer: array[0..18,0..PRED(WAV_BUFFER_SIZE)] of Byte;

implementation

uses
  MATH,SysUtils,
  AdT2unit,AdT2sys,TxtScrIO,StringIO,
  SDL_Types,SDL_Audio;

{$L ymf262.o}
{ ymf262.c needs some functions from msvcrt.dll which we need to emulate }
{_CRTIMP double __cdecl pow (double, double);}
function my_pow(a,b: Double): Double; cdecl; alias: '_pow';
begin
  my_pow := POWER(a,b);
end;

{_CRTIMP double __cdecl floor (double);}
function my_floor(a: Double): Double; cdecl; alias: '_floor';
begin
  my_floor := FLOOR(a);
end;

{_CRTIMP double __cdecl sin (double);}
function my_sin(a: Double): Double; cdecl; alias: '_sin';
begin
  my_sin := SIN(a);
end;

{_CRTIMP double __cdecl log (double);}
function my_log(a: Double): Double; cdecl; alias: '_log';
begin
  my_log := LN(a);
end;

{_CRTIMP void* __cdecl __MINGW_NOTHROW malloc (size_t) __MINGW_ATTRIB_MALLOC;}
function my_malloc(size: Longint): Pointer; cdecl; alias: '_malloc';
begin
  my_malloc := GetMem(size);
end;

{_CRTIMP void __cdecl __MINGW_NOTHROW free (void*);}
procedure my_free(p: Pointer); cdecl; alias: '_free';
begin
  FreeMem(p);
end;

{_CRTIMP void __cdecl __MINGW_NOTHROW free (void*);}
procedure my_memset(var s; c: Char; len: Longint); cdecl; alias: '_memset';
begin
  FillChar(s,len,c);
end;

const
  OPL3_SAMPLE_BITS = 16;
  OPL3_INTERNAL_FREQ = 14400000;

const
  YMF262_sample_buffer_ptr: Pointer = NIL;
  YMF262_sample_buffer_chan_ptr: array[1..18] of Pointer = (
    NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL);

var
  ymf262: Longint;
  sample_frame_size: Longint;  
  sdl_audio_spec: SDL_AudioSpec;

type
  pINT16 = ^Smallint;
  
function YMF262Init(num: Longint; clock: Longint; rate: Longint): Longint; cdecl; external;
procedure YMF262Shutdown; cdecl; external;
procedure YMF262ResetChip(which: Longint); cdecl; external;
function YMF262Write(which: Longint; addr: Longint; value: Longint): Longint; cdecl ;external;
procedure YMF262UpdateOne(which: Longint; buffer: pINT16; buffers_chan: array of pINT16; length: Longint); cdecl; external;

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
                             samples_sec:  44100;
                             bytes_sec:    2*44100*16 DIV 8;
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
        If NOT (opl3_record_channel[idx]) or (is_4op_chan(idx) and NOT (idx in [1,3,5,10,12,14])) then CONTINUE
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
	  If renew_wav_files_flag then RewriteF(wav_file)
      else ResetF(wav_file);
      {$i+}
      If renew_wav_files_flag or
	     (NOT renew_wav_files_flag and (IOresult <> 0)) then
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
          wav_header.file_size := wav_header.file_size+bytes_to_write;
          wav_header.data_size := wav_header.data_size+bytes_to_write;
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

  If opl3_channel_recording_mode then
    renew_wav_files_flag := FALSE;
end;

procedure opl2out(reg,data: Word);
begin
  // relevant only for DOS version -> option opl_latency=1
  opl3out_proc(reg,data);
end;

procedure opl3out_proc(reg,data: Word);

var
  op: Longint;

begin
  op := 0;
  If (reg > 255) then
    begin
      op := 2;
      reg := reg AND $0ff;
    end;  
  YMF262Write(ymf262,op,reg);
  YMF262Write(ymf262,op+1,data);
end;

procedure opl3exp(data: Word);
begin
  YMF262Write(ymf262,2,data AND $0ff);
  YMF262Write(ymf262,3,data SHR 8);
end;

procedure opl3_init;
begin
  YMF262ResetChip(ymf262);
end;

procedure opl3_deinit;
begin
  SDL_PauseAudio(1);
end;

// value in Hz for timer
procedure snd_SetTimer(value: Longint);
begin
  If (value < 18) then value := 18;
  sample_frame_size := sdl_sample_rate DIV value;
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
  buffer_ptr_table: array[1..18] of pINT16;
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
        buffer_ptr_table[idx] := YMF262_sample_buffer_chan_ptr[idx]+counter*4;
      // update one step
      ymf262updateone(ymf262,YMF262_sample_buffer_ptr+counter*4,buffer_ptr_table,1);
    end;

  // update SDL Audio sample buffer
  Move(YMF262_sample_buffer_ptr^,stream^,len);
  If (play_status = isStopped) then EXIT;  
  
  // calculate cache buffer size
  If opl3_channel_recording_mode then
    buf_size := WAV_BUFFER_SIZE DIV 18 * get_num_files
  else buf_size := WAV_BUFFER_SIZE DIV 18; 
  
  // WAV dumper
  If (sdl_opl3_emulator <> 0) then
    If (wav_buffer_len+len <= buf_size) then
      begin
        // update main sample buffer
        Move(YMF262_sample_buffer_ptr^,wav_buffer[0][wav_buffer_len],len);
        // update partial channel sample buffers
        For idx := 1 to 18 do
          Move(YMF262_sample_buffer_chan_ptr[idx]^,wav_buffer[idx][wav_buffer_len],len);
        Inc(wav_buffer_len,len);
      end
    else
      begin
        // sample buffers full -> flush to disk!
        flush_WAV_data;
        // update main sample buffer
        Move(YMF262_sample_buffer_ptr^,wav_buffer[0][wav_buffer_len],len);
        // update partial channel sample buffers
        For idx := 1 to 18 do
          Move(YMF262_sample_buffer_chan_ptr[idx]^,wav_buffer[idx][wav_buffer_len],len);
        Inc(wav_buffer_len,len);
      end;
end;

procedure snd_Init;

var
  idx: Byte;

begin
  GetMem(YMF262_sample_buffer_ptr,sdl_sample_buffer*4);
  For idx := 1 to 18 do GetMem(YMF262_sample_buffer_chan_ptr[idx],sdl_sample_buffer*4);
  sample_frame_size := sdl_sample_rate DIV 50;
  
  ymf262 := YMF262Init(1,OPL3_INTERNAL_FREQ,sdl_sample_rate);
  opl3_init;
  
  sdl_audio_spec.freq := sdl_sample_rate;
  sdl_audio_spec.format := AUDIO_S16;
  sdl_audio_spec.channels := 2;
  sdl_audio_spec.samples := sdl_sample_buffer;
  @sdl_audio_spec.callback := @playcallback;
  sdl_audio_spec.userdata := NIL;

  If (SDL_Openaudio(@sdl_audio_spec,NIL) < 0) then
    begin
      WriteLn('SDL: Audio initialization error');
      HALT(1);
    end;
    
  WriteLn('  Sample buffer size: ',sdl_sample_buffer,' bytes');
  WriteLn('  Sampling rate: ',sdl_sample_rate,' Hz');
  SDL_PauseAudio(0);
end;

procedure snd_Deinit;

var
  idx: Byte;

begin
  YMF262Shutdown;
  SDL_PauseAudio(1);
  SDL_CloseAudio;
  FreeMem(YMF262_sample_buffer_ptr);
  For idx := 1 to 18 do FreeMem(YMF262_sample_buffer_chan_ptr[idx]);
  YMF262_sample_buffer_ptr := NIL;
end;

end.
