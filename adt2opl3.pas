unit AdT2opl3;

interface

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

implementation

uses
  MATH,
  AdT2unit,TxtScrIO,
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

type
  pINT16  = ^Smallint;

const
  DBOBPL_BUFFER_SIZE = 4096;
  YMF262_sample_buffer_ptr: Pointer = NIL;

var
  ymf262: Longint;
  DBOPL_sample_buffer: array[0..DBOBPL_BUFFER_SIZE*2] of Longint;
  sample_frame_size: Longint;  
  sdl_audio_spec: SDL_AudioSpec;
  
function YMF262Init(num: Longint; clock: Longint; rate: Longint): Longint; cdecl; external;
procedure YMF262Shutdown; cdecl; external;
procedure YMF262ResetChip(which: Longint); cdecl; external;
function YMF262Write(which: Longint; addr: Longint; value: Longint): Longint; cdecl ;external;
procedure YMF262UpdateOne(which: Longint; buffer: pINT16; length: Longint); cdecl; external;

{$link dbopl.o}
procedure DBOPL_Init(rate: Longint); cdecl; external;
procedure DBOPL_WriteReg(addr: Longint; value: Byte); cdecl; external;
procedure DBOPL_Generate(length: Longint; buffer: Pointer); cdecl; external;

procedure opl3out_proc(reg, data: Word);

var
  op: Longint;

begin
  Case sdl_opl3_emulator of
    0: begin
         op := 0;
         If (reg > $0ff) then
           begin
             op := 2;
             reg := reg AND $0ff;
           end;  
         YMF262Write(ymf262,op,reg);
         YMF262Write(ymf262,op+1,data);
       end;
    1: DBOPL_WriteReg(reg,data);
  end;  
end;

procedure opl3exp(data: Word);
begin
  Case sdl_opl3_emulator of
    0: begin
         YMF262Write(ymf262,2,data AND $0ff);
         YMF262Write(ymf262,3,data SHR 8);
       end;
    1: DBOPL_WriteReg((data AND $0ff) OR $100,data SHR 8);
  end;
end;

procedure opl3_init;
begin
  YMF262ResetChip(ymf262);
  DBOPL_Init(sdl_sample_rate);
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
  mix_buf_ptr: array[0..1] of Longint;
  IRQ_freq_val: Longint;
	
begin
  If NOT rewind then
    IRQ_freq_val := IRQ_freq
  else IRQ_freq_val := IRQ_freq * 20;
       
  For counter := 0 to (sdl_sample_buffer-1) do
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

          If macro_ticklooper = 0 then
	      macro_poll_proc;

          Inc(ticklooper);
          If (ticklooper >= IRQ_freq_val DIV tempo) then
	        ticklooper := 0;

          Inc(macro_ticklooper);
          If (macro_ticklooper >= IRQ_freq_val DIV (tempo*macro_speedup)) then
	      macro_ticklooper := 0;
        end;
        
        Case sdl_opl3_emulator of
          0: ymf262updateone(ymf262,YMF262_sample_buffer_ptr+counter*4,1);
          1: begin
               DBOPL_Generate(1,@mix_buf_ptr);
               DBOPL_sample_buffer[counter] := WORD(mix_buf_ptr[0]) OR WORD(mix_buf_ptr[1]) SHL 16;
             end;   
        end;
    end;

  // update SDL Audio sample buffer
  Case sdl_opl3_emulator of  
    0: Move(YMF262_sample_buffer_ptr^,stream^,len);
    1: Move(DBOPL_sample_buffer[0],stream^,len);
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
    end
  else
    Case sdl_opl3_emulator of
      0: WriteLn('OPL3 emulation core: MAME');
      1: WriteLn('OPL3 emulation core: DOSBox');
    end;
    
  WriteLn('  Sample buffer size: ',sdl_sample_buffer,' bytes');
  WriteLn('  Sampling rate: ',sdl_sample_rate,' Hz');
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
