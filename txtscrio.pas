{
        Hardware-specific text mode functions
}
unit TxtScrIO;
{$PACKRECORDS 1}
interface

const                          { sdl_screen_mode = 0/1/2}
  SCREEN_RES_x: Word = 720;    { 720 / 960 / 1440 }
  SCREEN_RES_y: Word = 480;    { 480 / 800 / 960 }
  MAX_COLUMNS: Byte = 90;      { 90 / 120 / 180 }
  MAX_ROWS: Byte = 40;         { 40 / 50 / 60 }
  MAX_TRACKS: Byte = 5;        { 5 / 7  / 11 }
  MAX_ORDER_COLS: Byte = 9;    { 9 / 13 / 22 }
  MAX_PATTERN_ROWS: Byte = 18; { 18 / 26 / 40 }
  INSCTRL_xshift: Byte = 0;    { 0 / 15 / 30 }
  INSCTRL_yshift: Byte = 0;    { 0 / 6  / 12 }
  PATTORD_xshift: Byte = 0;    { 0 / 1 / 0 }

var
  MaxLn,MaxCol,
  work_maxln,work_maxcol: Byte;
  v_ofs: Pointer;

procedure TxtScrIO_Init;

function  WhereX: Byte;
function  WhereY: Byte;
procedure GotoXY(x,y: Byte);

function  GetCursor: Longint;
procedure SetCursor(cursor: Longint);
procedure ThinCursor;
procedure WideCursor;
procedure HideCursor;
function  GetCursorShape: Word;
procedure SetCursorShape(shape: Word);

implementation

uses
  AdT2vscr,AdT2unit,
  TimerInt,DialogIO;

function WhereX: Byte;
begin
  WhereX := virtual_cur_pos AND $0ff;
end;

function  WhereY: Byte;
begin
  WhereY := virtual_cur_pos SHR 8;
end;

procedure GotoXY(x,y: Byte);
begin
  virtual_cur_pos := x OR (y SHL 8);
end;

function GetCursor: Longint;
begin
  GetCursor := 0;
end;

procedure SetCursor(cursor: Longint);
begin
  virtual_cur_pos := cursor SHR 16;
  SetCursorShape(cursor AND $0ffff);
end;

procedure ThinCursor;
begin
  SetCursorShape($0b0c);
end;

procedure WideCursor;
begin
  SetCursorShape($010c);
end;

procedure HideCursor;
begin
  SetCursorShape($1010);
end;

function GetCursorShape: Word;
begin
  GetCursorShape := virtual_cur_shape;
end;

procedure SetCursorShape(shape: Word);
begin
  virtual_cur_shape := shape;
end;

procedure TxtScrIO_Init;
begin
  TxtScrIO.v_ofs := Addr(AdT2vscr.vscreen);
  AdT2vscr.virtual_screen := Addr(AdT2vscr.vscreen);
  DialogIO.mn_environment.v_dest := Addr(AdT2vscr.vscreen);
  AdT2unit.centered_frame_vdest := Addr(AdT2vscr.vscreen);
  
  Case sdl_screen_mode of
    // classic view
    0: begin
         SCREEN_RES_X := 720;
         SCREEN_RES_Y := 480;
         MAX_COLUMNS := 90;
         MAX_ROWS := 40;
         MAX_ORDER_COLS := 9;
         MAX_TRACKS := 5;
         MAX_PATTERN_ROWS := 18;
         INSCTRL_xshift := 0;
         INSCTRL_yshift := 0;
         PATTORD_xshift := 0;
         MaxCol := MAX_COLUMNS;
         MaxLn := MAX_ROWS;
         hard_maxcol := MAX_COLUMNS;
         hard_maxln := 30;
         work_MaxCol := MAX_COLUMNS;
         work_MaxLn := 30;
       end;       
    // full-screen view
    1: begin
         SCREEN_RES_X := 960;
         SCREEN_RES_Y := 800;
         MAX_COLUMNS := 120;
         MAX_ROWS := 50;
         MAX_ORDER_COLS := 13;
         MAX_TRACKS := 7;
         MAX_PATTERN_ROWS := 28;
         INSCTRL_xshift := 15;
         INSCTRL_yshift := 6;
         PATTORD_xshift := 1;
         MaxCol := MAX_COLUMNS;
         MaxLn := MAX_ROWS;
         hard_maxcol := MAX_COLUMNS;
         hard_maxln := 50;
         work_MaxCol := MAX_COLUMNS;
         work_MaxLn := 40;
       end;
    // wide full-screen view
    2: begin
         SCREEN_RES_X := 1440;
         SCREEN_RES_Y := 960;
         MAX_COLUMNS := 180;
         MAX_ROWS := 60;
         MAX_ORDER_COLS := 22;
         MAX_TRACKS := 11;
         MAX_PATTERN_ROWS := 38;
         INSCTRL_xshift := 45;
         INSCTRL_yshift := 12;
         PATTORD_xshift := 0;
         MaxCol := MAX_COLUMNS;
         MaxLn := MAX_ROWS;
         hard_maxcol := MAX_COLUMNS;
         hard_maxln := 60;
         work_MaxCol := MAX_COLUMNS;
         work_MaxLn := 50;
       end;
  end;
  
  If (command_typing = 0) then PATEDIT_lastpos := 4*MAX_TRACKS
  else PATEDIT_lastpos := 10*MAX_TRACKS;
 
  patt_win[1] := patt_win_tracks[sdl_screen_mode][1];
  patt_win[2] := patt_win_tracks[sdl_screen_mode][2];
  patt_win[3] := patt_win_tracks[sdl_screen_mode][3];
  patt_win[4] := patt_win_tracks[sdl_screen_mode][4];
  patt_win[5] := patt_win_tracks[sdl_screen_mode][5];
end;

end.
