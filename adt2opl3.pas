unit AdT2opl3;

interface

procedure flush_WAV_data;
procedure opl3out_proc(reg,data: Word);
procedure opl3exp(data: Word);
procedure opl3_init;
procedure opl3_deinit;
procedure snd_Init;
procedure snd_Deinit;
procedure snd_SetTimer(value: Longint);

type
  tOPL3OUT_proc = procedure(reg,data: Word);

const
  opl3out: tOPL3OUT_proc = opl3out_proc;
  opl3_flushmode: Boolean = FALSE;

const
  WAV_BUFFER_SIZE = 256*1024;
 
var
  wav_buffer_len: Longint;  
  wav_buffer: array[0..PRED(WAV_BUFFER_SIZE)] of Byte;

implementation

uses
  MATH,SysUtils,
  AdT2unit,AdT2sys,TxtScrIO,StringIO,
  SDL_Types,SDL_Audio;

{$L ymf262.o}

{$IFNDEF LINUX}
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
{$ENDIF}

const
  OPL3_SAMPLE_BITS = 16;
  OPL3_INTERNAL_FREQ = 14400000;

type
  pINT16  = ^Smallint;

const
  YMF262_sample_buffer_ptr: Pointer = NIL;

var
  ymf262: Longint;
  sample_frame_size: Longint;  
  sdl_audio_spec: SDL_AudioSpec;
    
function YMF262Init(num: Longint; clock: Longint; rate: Longint): Longint; cdecl; external;
procedure YMF262Shutdown; cdecl; external;
procedure YMF262ResetChip(which: Longint); cdecl; external;
function YMF262Write(which: Longint; addr: Longint; value: Longint): Longint; cdecl ;external;
procedure YMF262UpdateOne(which: Longint; buffer: pINT16; length: Longint); cdecl; external;

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
   
procedure flush_WAV_data;

var
  wav_file: File;
  temp: Longint;
  
begin
  If (wav_buffer_len = 0) then EXIT;
  If NOT DirectoryExists(Copy(sdl_wav_directory,1,Length(sdl_wav_directory)-Length(NameOnly(sdl_wav_directory)))) then
    If NOT CreateDir(Copy(sdl_wav_directory,1,Length(sdl_wav_directory)-Length(NameOnly(sdl_wav_directory)))) then
      EXIT;
      
  If opl3_flushmode then Assign(wav_file,sdl_wav_directory)
  else Assign(wav_file,sdl_wav_directory+BaseNameOnly(songdata_title)+'.wav');
  
  // update WAV header
  {$i-}
  ResetF(wav_file);
  {$i+}
  If (IOresult <> 0) then
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
      wav_header.file_size := wav_header.file_size+wav_buffer_len;
      wav_header.data_size := wav_header.data_size+wav_buffer_len;
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
         wav_header.file_size := wav_header.file_size+wav_buffer_len;
         wav_header.data_size := wav_header.data_size+wav_buffer_len;
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

  // flush cached data
  {$i-}
  BlockWriteF(wav_file,wav_buffer,wav_buffer_len,temp);
  {$i+}
  If (IOresult <> 0) or (temp <> wav_buffer_len) then
    begin
      CloseF(wav_file);
      {$i-}
      EraseF(wav_file);
      {$i+}
      If (IOresult <> 0) then ;
    end
  else
    begin
      CloseF(wav_file);
      wav_buffer_len := 0;
    end;
end;

procedure opl3out_proc(reg, data: Word);

var
  op: Longint;

begin
  op := 0;
  If (reg > $0ff) then
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
  flush_WAV_data;
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
     
procedure playcallback(var userdata; stream: pByte; len: Longint); cdecl;

const
  counter_idx: Longint = 0;

var 
  counter: Longint;
  IRQ_freq_val: Longint;

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
        
      ymf262updateone(ymf262,YMF262_sample_buffer_ptr+counter*4,1);
    end;

  // update SDL Audio sample buffer
  Move(YMF262_sample_buffer_ptr^,stream^,len);
  
  // WAV dumper
  If (play_status = isPlaying) and (sdl_opl3_emulator <> 0) then
    If (wav_buffer_len+len <= WAV_BUFFER_SIZE) then
      begin
        Move(stream^,wav_buffer[wav_buffer_len],len);
        Inc(wav_buffer_len,len);
      end       
    else
      begin
        flush_WAV_data;
        Move(stream^,wav_buffer[wav_buffer_len],len);
        Inc(wav_buffer_len,len);
      end;        
end;

procedure snd_Init;
begin
  GetMem(YMF262_sample_buffer_ptr,sdl_sample_buffer*4);
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
  
  WriteLn('  Sample buffer size: ',sdl_audio_spec.samples,' samples (requested ',sdl_sample_buffer,')');
  WriteLn('  Sampling rate: ',sdl_audio_spec.freq,' Hz (requested ',sdl_sample_rate,')');

  sdl_sample_rate := sdl_audio_spec.freq;
  sdl_sample_buffer := sdl_audio_spec.samples;

  SDL_PauseAudio(0);
end;

procedure snd_Deinit;
begin
  YMF262Shutdown;
  SDL_PauseAudio(1);
  SDL_CloseAudio;
  FreeMem(YMF262_sample_buffer_ptr);
  YMF262_sample_buffer_ptr := NIL;
end;

end.
