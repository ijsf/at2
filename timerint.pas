unit TimerInt;
{$IFDEF __TMT__}
{$S-,Q-,R-,V-,B-,X+}
{$ELSE}
{$PACKRECORDS 1}
{$ENDIF}
interface

procedure TimerSetup(Hz: Longint);
procedure TimerDone;
procedure TimerInstallHandler(handler: Pointer);
procedure TimerRemoveHandler;

implementation

{$IFDEF __TMT__}
uses
  DOS,
  AdT2unit,AdT2sys;

var
  oldint08: FarPointer;
  newint08: Pointer;
  counter,
  clock_ticks,clock_flag: Word;
  ticks: Longint;

const
  timer_handler: Pointer = NIL;

procedure int08; interrupt;
begin
  asm
{$IFNDEF _32BIT}
        cmp     word ptr timer_handler,0
        jnz     @@1
        cmp     word ptr timer_handler+2,0
        jz      @@2
@@1:    push    ds
        call    [timer_handler]
        pop     ds
@@2:    mov     ax,word ptr ticks
        mov     bx,word ptr ticks+2
        add     ax,1
        adc     bx,0
        mov     word ptr ticks,ax
        mov     word ptr ticks+2,bx
        inc     clock_ticks
        mov     ax,clock_ticks
        cmp     ax,clock_flag
        jb      @@3
        mov     clock_ticks,0
        pushf
        call    [oldint08]
        jmp     @@ret
@@3:    mov     al,60h
        out     20h,al
{$ELSE}
        cmp     timer_handler,0
        jz      @@1
        push    ds
        push    es
        call    [timer_handler]
        pop     es
        pop     ds
@@1:    inc     ticks
        inc     clock_ticks
        mov     ax,clock_ticks
        cmp     ax,clock_flag
        jnz     @@2
        mov     clock_ticks,0
        pushfd
        call    [oldint08]
        jmp     @@ret
@@2:    mov     al,60h
        out     20h,al
{$ENDIF}
@@ret:
  end;
end;

procedure DisableTimerIRQ;
begin
  asm
        in      al,21h
        or      al,1
        out     21h,al
  end;
end;

procedure EnableTimerIRQ;
begin
  asm
        in      al,21h
        and     al,0feh
        out     21h,al
  end;
end;

procedure TimerSetup(Hz: Longint);
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'TIMERINT.PAS:TimerSetup';
{$ENDIF}
  If (Hz < 19) then Hz := 19;
  If (Hz > 1193180) then Hz := 1193180;

  counter := 1193180 DIV Hz;
  clock_flag := Hz*1000 DIV 18206;
  newint08 := @int08;
  ticks := 0;
  clock_ticks := 0;

  DisableTimerIRQ;
  asm
        mov     al,36h
        out     43h,al
        mov     bx,counter
        mov     al,bl
        out     40h,al
        mov     al,bh
        out     40h,al
  end;

  SetIntVec($08,newint08);
  EnableTimerIRQ;
end;

procedure TimerDone;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'TIMERINT.PAS:TimerDone';
{$ENDIF}
  DisableTimerIRQ;
  asm
        mov     al,36h
        out     43h,al
        xor     ax,ax
        out     40h,al
        out     40h,al
  end;

  SetIntVec($08,oldint08);
  EnableTimerIRQ;
end;

procedure TimerInstallHandler(handler: Pointer);
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'TIMERINT.PAS:TimerInstallHandler';
{$ENDIF}
  DisableTimerIRQ;
  timer_handler := handler;
  EnableTimerIRQ;
end;

procedure TimerRemoveHandler;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'TIMERINT.PAS:TimerRemoveHandler';
{$ENDIF}
  DisableTimerIRQ;
  timer_handler := NIL;
  EnableTimerIRQ;
end;

begin
  GetIntVec($08,oldint08);
end.

{$ELSE}

uses
  SDL_Types,SDL_Timer,
  AdT2opl3;

const
  timer_handler: Procedure = NIL;
  TimerID: SDL_TimerID = NIL;
  _interval: longint = 1000 DIV 50; // 1000 ms / Hz

function TimerCallback(interval: Uint32; param: Pointer):Uint32; cdecl;
begin
  If (@timer_handler <> NIL) then timer_handler;
  TimerCallback := _interval; // trick to alter delay rate on the fly
end;

procedure TimerSetup(Hz: Longint);
begin
  _interval := 1000 DIV Hz;
  // only activate timer once, later only alter delay rate
  If (TimerID = NIL) then
    begin
      TimerID := SDL_AddTimer(_interval,SDL_NewTimerCallback(@TimerCallBack),NIL);
      If (TimerID = NIL) then
        Writeln('SDL: Error creating timer');
    end;
  snd_SetTimer(Hz);
end;

procedure TimerDone;
begin
end;

procedure TimerInstallHandler(handler: Pointer);
begin
  @timer_handler := handler;
end;

procedure TimerRemoveHandler;
begin
  @timer_handler := NIL;
end;

end.

{$ENDIF}
