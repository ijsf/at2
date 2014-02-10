{
        Hardware-specific text mode functions
}
unit TxtScrIO;
{$PACKRECORDS 1}
interface

var
  MaxLn,MaxCol,
  work_maxln,work_maxcol: Byte;
  v_ofs: Pointer;

procedure init;

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

procedure init;
begin
  TxtScrIO.v_ofs := addr(AdT2vscr.vscreen);
  AdT2vscr.virtual_screen := addr(AdT2vscr.vscreen);
  DialogIO.mn_environment.v_dest := addr(AdT2vscr.vscreen);
  AdT2unit.centered_frame_vdest := addr(AdT2vscr.vscreen);
  
  Case sdl_screen_mode of
    // classic view
    0: begin
         MAX_COLUMNS := 90;
         MAX_ROWS := 40;
         MAX_ORDER_COLS := 9;
         MAX_TRACKS := 5;
         MAX_PATTERN_ROWS := 18;
         INS_CTRL_xshift := 0;
         INS_CTRL_yshift := 0;
         MaxCol := MAX_COLUMNS;
         MaxLn := MAX_ROWS;
         hard_maxcol := MAX_COLUMNS;
         hard_maxln := 30;
         work_MaxCol := MAX_COLUMNS;
         work_MaxLn := 30;
       end;
       
    // full-screen view
    1: begin
         MAX_COLUMNS := 120;
         MAX_ROWS := 50;
         MAX_ORDER_COLS := 13;
         MAX_TRACKS := 7;
         MAX_PATTERN_ROWS := 28;
         INS_CTRL_xshift := 15;
         INS_CTRL_yshift := 6;
         MaxCol := MAX_COLUMNS;
         MaxLn := MAX_ROWS;
         hard_maxcol := MAX_COLUMNS;
         hard_maxln := 50;
         work_MaxCol := MAX_COLUMNS;
         work_MaxLn := 40;
       end;
  end;
  
  If (command_typing = 0) then PATEDIT_lastpos := 4*MAX_TRACKS
  else PATEDIT_lastpos := 10*MAX_TRACKS;
  
  Case MAX_TRACKS of
    5: begin
         patt_win[1] := patt_win_5tracks[1];
         patt_win[2] := patt_win_5tracks[2];
         patt_win[3] := patt_win_5tracks[3];
         patt_win[4] := patt_win_5tracks[4];
         patt_win[5] := patt_win_5tracks[5];
       end;
    7: begin
         patt_win[1] := patt_win_7tracks[1];
         patt_win[2] := patt_win_7tracks[2];
         patt_win[3] := patt_win_7tracks[3];
         patt_win[4] := patt_win_7tracks[4];
         patt_win[5] := patt_win_7tracks[5];
       end;
  end;
end;

end.
