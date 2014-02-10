unit TimerInt;
{$PACKRECORDS 1}
interface

procedure TimerSetup(Hz: Longint);
procedure TimerDone;
procedure TimerInstallHandler(handler: Pointer);
procedure TimerRemoveHandler;

implementation

uses
  AdT2opl3,
  SDL_Types, SDL_Timer;

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
