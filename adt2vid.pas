{
    Wrapper for video mode routines (text and graphics)
}
unit AdT2vid;
{$PACKRECORDS 1}
interface

procedure vid_Init;
procedure vid_Deinit;
procedure vid_SetVideoMode(do_delay: Boolean);
procedure vid_SetRGBPalette(var palette);
procedure vid_FadeOut;

implementation

uses
  CRT,
  SDL,SDL_Video,SDL_Timer,SDL__rwops,
  AdT2vscr,AdT2unit,AdT2ext2,DialogIO,TxtScrIO;

{$i adt2icon.inc}
var
  screen: PSDL_Surface;

procedure vid_Init;
begin
  SDL_Init(SDL_INIT_VIDEO or SDL_INIT_TIMER or SDL_INIT_AUDIO);
end;

procedure vid_Deinit;
begin
  SDL_FreeSurface(screen);
  SDL_Quit;
end;

var
  rgb_color_alt: array[0..15] of tRGB;

procedure vid_SetRGBPalette;
begin
  SDL_SetPalette(screen,SDL_PHYSPAL,SDL_ColorArray(palette),0,16);
end;

procedure vid_EmulateScreen;

const
  next_game_tick: Longint = 0;
  frame_start: Longint = 0;
  frame_end: Longint = 0;
  sleep_time: Longint = 0;
  frames: Longint = 0;

begin
  If (tracing = TRUE) then trace_update_proc;
  If (Addr(mn_environment.ext_proc_rt) <> NIL) then mn_environment.ext_proc_rt
  else update_without_trace;

  // do actual flip
  emulate_screen_all;
  SDL_Flip(screen);

  If (sdl_delay_ms = 0) then
    begin // keep framerate 60 fps
      Inc(next_game_tick,17);
      Inc(frames);
      frame_end := SDL_GetTicks;
      If (frame_end-frame_start >= 1000) then frames := 0;
      If (next_game_tick = 17) then Inc(next_game_tick,frame_end);
      sleep_time := next_game_tick-frame_end;
      If (sleep_time > 0) then SDL_Delay(sleep_time)
      else SDL_Delay(10);
      If (frames = 0) then frame_start := next_game_tick;
    end
  else
    SDL_Delay(sdl_delay_ms); // or do constant delay
end;

procedure vid_SetVideoMode(do_delay: Boolean);

var
  icon: pSDL_Surface;
  rwop: pSDL_RWops;

begin
  Case sdl_screen_mode of
    0: begin
         FB_xres := 720;
         FB_yres := 480;
         FB_rows := 30;
       end;
    1: begin
         FB_xres := 960;
         FB_yres := 800;
         FB_rows := 50;
       end;
  end;

  If do_delay then SDL_Delay(1000);
  screen := SDL_SetVideoMode(FB_xres,FB_yres,8,SDL_SWSURFACE);
  If (screen = NIL) then
    begin
      WriteLn('SDL: Couldn''t initialize video mode');
      HALT(1);
    end;

  vid_SetRGBPalette(Addr(rgb_color)^);
  Move(rgb_color,rgb_color_alt,SizeOf(rgb_color));
  emulate_screen := vid_EmulateScreen;
  _FrameBuffer := screen^.pixels;
  TxtScrIO.Init;
  rwop := SDL_RWFromMem(adt2_icon_bitmap,SizeOf(adt2_icon_bitmap));
  icon := SDL_LoadBMP_RW(rwop,TRUE);
  SDL_WM_SetIcon(icon,NIL);
  SDL_WM_SetCaption('/|DLiB TR/|CK3R ][ SDL',NIL);
end;

procedure vid_FadeOut;

var
  idx: Byte;

function min0(val: Longint): Longint;
begin
  If (val <= 0) then min0 := 0
  else min0 := val;
end;

begin
  For idx := 1 to 15 do
    begin
      rgb_color_alt[idx].r := min0(rgb_color_alt[idx].r-1);
      rgb_color_alt[idx].g := min0(rgb_color_alt[idx].g-1);
      rgb_color_alt[idx].b := min0(rgb_color_alt[idx].b-1);
    end;
  SDL_SetPalette(screen,SDL_PHYSPAL,SDL_ColorArray(Addr(rgb_color_alt)^),0,16);
end;

end.
