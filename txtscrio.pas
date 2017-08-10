unit TxtScrIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

const
  SCREEN_RES_x: Word = 720;
  SCREEN_RES_y: Word = 480;
  MAX_COLUMNS: Byte = 90;
  MAX_ROWS: Byte = 40;
  MAX_TRACKS: Byte = 5;
  MAX_ORDER_COLS: Byte = 9;
  MAX_PATTERN_ROWS: Byte = 18;
  INSCTRL_xshift: Byte = 0;
  INSCTRL_yshift: Shortint = 0;
  INSEDIT_yshift: Byte = 0;
  PATTORD_xshift: Byte = 0;
  GOTOXY_xshift: Byte = 0;

const
  MAX_SCREEN_MEM_SIZE = 180*60*2;
  SCREEN_MEM_SIZE: Longint = MAX_SCREEN_MEM_SIZE;

type
  tSCREEN_MEM = array[0..PRED(MAX_SCREEN_MEM_SIZE)] of Byte;
  tSCREEN_MEM_PTR = ^tSCREEN_MEM;

var
  temp_screen:          tSCREEN_MEM;
  temp_screen2:         tSCREEN_MEM;
  screen_backup:        tSCREEN_MEM;
  scr_backup:           tSCREEN_MEM;
  scr_backup2:          tSCREEN_MEM;
  screen_mirror:        tSCREEN_MEM;
  screen_emulator:      tSCREEN_MEM;
  centered_frame_vdest: tSCREEN_MEM_PTR;
  text_screen_shadow:   tSCREEN_MEM;

const
  screen_ptr:          Pointer = Addr(text_screen_shadow);
  ptr_temp_screen:     Pointer = Addr(temp_screen);
  ptr_temp_screen2:    Pointer = Addr(temp_screen2);
  ptr_screen_backup:   Pointer = Addr(screen_backup);
  ptr_scr_backup:      Pointer = Addr(scr_backup);
  ptr_scr_backup2:     Pointer = Addr(scr_backup2);
  ptr_screen_mirror:   Pointer = Addr(screen_mirror);
  ptr_screen_emulator: Pointer = Addr(screen_emulator);

const
  move_to_screen_data: Pointer = NIL;
  move_to_screen_area: array[1..4] of Byte = (0,0,0,0);
  move_to_screen_routine: procedure = NIL;

const
  program_screen_mode: Byte = 0;

const
  MaxLn: Byte = 0;
  MaxCol: Byte = 0;
  hard_maxcol: Byte = 0;
  hard_maxln:  Byte = 0;
  work_maxcol: Byte = 0;
  work_maxln:  Byte = 0;
  scr_font_width: Byte = 0;
  scr_font_height: Byte = 0;

const
  area_x1: Byte = 0;
  area_y1: Byte = 0;
  area_x2: Byte = 0;
  area_y2: Byte = 0;
  scroll_pos0: Byte = BYTE(NOT 0);
  scroll_pos1: Byte = BYTE(NOT 0);
  scroll_pos2: Byte = BYTE(NOT 0);
  scroll_pos3: Byte = BYTE(NOT 0);
  scroll_pos4: Byte = BYTE(NOT 0);

var
  cursor_backup: Longint;

const
  Black   = $00;  DGray    = $08;
  Blue    = $01;  LBlue    = $09;
  Green   = $02;  LGreen   = $0a;
  Cyan    = $03;  LCyan    = $0b;
  Red     = $04;  LRed     = $0c;
  Magenta = $05;  LMagenta = $0d;
  Brown   = $06;  Yellow   = $0e;
  LGray   = $07;  White    = $0f;
  Blink   = $80;

procedure show_str(xpos,ypos: Byte; str: String; color: Byte);
procedure show_cstr(xpos,ypos: Byte; str: String; attr1,attr2: Byte);
procedure show_cstr_alt(xpos,ypos: Byte; str: String; attr1,attr2: Byte);
procedure show_vstr(xpos,ypos: Byte; str: String; color: Byte);
procedure show_vcstr(xpos,ypos: Byte; str: String; attr1,attr2: Byte);
procedure ShowStr(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; attr: Byte);
procedure ShowVStr(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; attr: Byte);
procedure ShowCStr(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2: Byte);
procedure ShowCStr2(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2: Byte);
procedure ShowVCStr(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2: Byte);
procedure ShowC3Str(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2,atr3: Byte);
procedure ShowC4Str(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2,atr3,atr4: Byte);
procedure ShowVC3Str(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2,atr3: Byte);
function  CStrLen(str: String): Byte;
function  C3StrLen(str: String): Byte;
procedure ScreenMemCopy(source,dest: tSCREEN_MEM_PTR);
procedure move2screen_alt;

procedure move2screen;
procedure TxtScrIO_Init;
function  is_default_screen_mode: Boolean;
{$IFDEF GO32V2}
function  is_VESA_emulated_mode: Boolean;
function  get_VESA_emulated_mode_idx: Byte;
{$ENDIF}
function  is_scrollable_screen_mode: Boolean;

type
  tFRAME_SETTING = Record
                     shadow_enabled,
                     wide_range_type,
                     zooming_enabled,
                     update_area: Boolean;
                   end;
const
  fr_setting: tFRAME_SETTING =
    (shadow_enabled:  TRUE;
     wide_range_type: FALSE;
     zooming_enabled: FALSE;
     update_area:     TRUE);

procedure Frame(dest: tSCREEN_MEM_PTR; x1,y1,x2,y2,atr1: Byte;
                title: String; atr2: Byte; border: String);

function WhereX: Byte;
function WhereY: Byte;
procedure GotoXY(x,y: Byte);
function  GetCursor: Longint;
procedure SetCursor(cursor: Longint);
procedure ThinCursor;
procedure WideCursor;
procedure HideCursor;
function  GetCursorShape: Word;
procedure SetCursorShape(shape: Word);

const
  v_seg:  Word = $0b800;
  v_ofs:  Word = 0;
  v_mode: Byte = $03;

{$IFDEF GO32V2}

var
  DispPg: Byte;

type
  tCUSTOM_VIDEO_MODE = 0..52;

function  iVGA: Boolean;
procedure initialize;
procedure ResetMode;
procedure SetCustomVideoMode(vmode: tCUSTOM_VIDEO_MODE);
procedure GetRGBitem(color: Byte; var red,green,blue: Byte);
procedure SetRGBitem(color: Byte; red,green,blue: Byte);
procedure WaitRetrace;
procedure GetPalette(var pal; first,last: Word);
procedure SetPalette(var pal; first,last: Word);

type
  tFADE  = (first,fadeOut,fadeIn);
  tDELAY = (fast,delayed);

type
  tFADE_BUF = Record
                action: tFADE;
                pal0: array[0..255] of Record r,g,b: Byte end;
                pal1: array[0..255] of Record r,g,b: Byte end;
              end;

const
  fade_speed: Byte = 63;

procedure VgaFade(var data: tFADE_BUF; fade: tFADE; delay: tDELAY);
procedure RefreshEnable;
procedure RefreshDisable;
procedure Split2Static;
procedure SplitScr(line: Word);
procedure SetSize(columns,lines: Word);
procedure SetTextDisp(x,y: Word);
procedure set_vga_txtmode_80x25;
procedure set_svga_txtmode_100x38;
procedure set_svga_txtmode_128x48;
procedure set_custom_svga_txtmode;

type
  VGA_REGISTER = Record
                   port: Word;
                   idx: Byte;
                   val: Byte;
                 end;
type
  VGA_REG_DATA = array[1..29] of VGA_REGISTER;

const
  svga_txtmode_cols: Byte = 100;
  svga_txtmode_rows: Byte = 37;
  svga_txtmode_regs: VGA_REG_DATA = (
    (port: $3c2; idx: $00; val: $06b),  // Miscellaneous output
    (port: $3d4; idx: $00; val: $070),  // Horizontal total
    (port: $3d4; idx: $01; val: $063),  // Horizontal display enable end
    (port: $3d4; idx: $02; val: $064),  // Horizontal blank start
    (port: $3d4; idx: $03; val: $082),  // Horizontal blank end
    (port: $3d4; idx: $04; val: $065),  // Horizontal retrace start
    (port: $3d4; idx: $05; val: $082),  // Horizontal retrace end
    (port: $3d4; idx: $06; val: $070),  // Vertical total
    (port: $3d4; idx: $07; val: $0f0),  // Overflow register
    (port: $3d4; idx: $08; val: $000),  // Preset row scan
    (port: $3d4; idx: $09; val: $04f),  // Maximum scan line/char height
    (port: $3d4; idx: $10; val: $05b),  // Vertical retrace start
    (port: $3d4; idx: $11; val: $08c),  // Vertical retrace end
    (port: $3d4; idx: $12; val: $04f),  // Vertical display enable end
    (port: $3d4; idx: $13; val: $03c),  // Offset/logical width
    (port: $3d4; idx: $14; val: $000),  // Underline location
    (port: $3d4; idx: $15; val: $058),  // Vertical blank start
    (port: $3d4; idx: $16; val: $070),  // Vertical blank end
    (port: $3d4; idx: $17; val: $0a3),  // Mode control
    (port: $3c4; idx: $01; val: $001),  // Clock mode register
    (port: $3c4; idx: $03; val: $000),  // Character generator select
    (port: $3c4; idx: $04; val: $000),  // Memory mode register
    (port: $3ce; idx: $05; val: $010),  // Mode register
    (port: $3ce; idx: $06; val: $00e),  // Miscellaneous register
    (port: $3c0; idx: $10; val: $002),  // Mode control
    (port: $3c0; idx: $11; val: $000),  // Screen border color
    (port: $3c0; idx: $12; val: $00f),  // Color plane enable
    (port: $3c0; idx: $13; val: $000),  // Horizontal panning
    (port: $3c0; idx: $14; val: $000)); // Color select

{$ENDIF}

implementation

uses
{$IFDEF GO32V2}
  CRT,GO32,
{$ENDIF}
  AdT2unit,AdT2sys,AdT2ext2,
  DialogIO,ParserIO;

{$IFDEF GO32V2}

function WhereX: Byte;

var
  result: Byte;

begin
  asm
        mov     bh,DispPg
        mov     ah,03h
        int     10h
        inc     dl
        mov     result,dl
  end;
  WhereX := result;
end;

function WhereY: Byte;

var
  result: Byte;

begin
  asm
        mov     bh,DispPg
        mov     ah,03h
        int     10h
        inc     dh
        mov     result,dh
  end;
  WhereY := result;
end;

procedure GotoXY(x,y: Byte);
begin
  asm
        lea     edi,[virtual_cur_pos]
        mov     ah,y
        mov     al,x
        stosw
        mov     dh,y
        mov     dl,x
        add     dl,GOTOXY_xshift
        dec     dh
        dec     dl
        mov     bh,DispPg
        mov     ah,02h
        int     10h
  end;
end;

function GetCursor: Longint;

var
  result: Longint;

begin
  asm
        xor     edx,edx
        mov     bh,DispPg
        mov     ah,03h
        int     10h
        shl     edx,16
        xor     eax,eax
        push    edx
        call    GetCursorShape
        pop     edx
        add     edx,eax
        mov     result,edx
  end;
  GetCursor := result;
end;

procedure SetCursor(cursor: Longint);
begin
  asm
        lea     edi,[virtual_cur_pos]
        mov     ax,word ptr [cursor+2]
        stosw
        xor     eax,eax
        mov     ax,word ptr [cursor]
        push    eax
        call    SetCursorShape
        mov     dx,word ptr [cursor+2]
        mov     bh,DispPg
        mov     ah,02h
        int     10h
  end;
end;

procedure ThinCursor;
begin
  SetCursorShape($0d0e);
end;

procedure WideCursor;
begin
  SetCursorShape($010e);
end;

procedure HideCursor;
begin
  SetCursorShape($1010);
end;

function GetCursorShape: Word;

var
  result: Word;

begin
  asm
        mov     dx,03d4h
        mov     al,0ah
        out     dx,al
        inc     dx
        in      al,dx
        and     al,1fh
        mov     ah,al
        dec     dx
        mov     al,0bh
        out     dx,al
        inc     dx
        in      al,dx
        and     al,1fh
        mov     result,ax
  end;
  GetCursorShape := result;
end;

procedure SetCursorShape(shape: Word);
begin
  asm
        mov     ax,shape
        mov     word ptr [virtual_cur_shape],ax
        mov     dx,03d4h
        mov     al,0ah
        out     dx,al
        inc     dx
        in      al,dx
        mov     ah,byte ptr [shape+1]
        and     al,0e0h
        or      al,ah
        out     dx,al
        dec     dx
        mov     al,0bh
        out     dx,al
        inc     dx
        in      al,dx
        mov     ah,byte ptr [shape]
        and     al,0e0h
        or      al,ah
        out     dx,al
  end;
end;

{$ELSE}

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
  SetCursorShape(cursor AND WORD_NULL);
end;

procedure ThinCursor;
begin
  SetCursorShape($0d0e);
end;

procedure WideCursor;
begin
  SetCursorShape($010e);
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

{$ENDIF}

{$IFDEF GO32V2}

procedure initialize;
begin
  asm
        mov     ah,0fh
        int     10h
        and     al,7fh
        mov     v_mode,al
        mov     DispPg,bh
  end;

  MaxCol := MEM[SEG0040:$4a];
  MaxLn := SUCC(MEM[SEG0040:$84]);
  work_MaxLn  := MaxLn;
  work_MaxCol := MaxCol;
  FillWord(screen_ptr^,MAX_SCREEN_MEM_SIZE DIV 2,$0700);
  dosmemput(v_seg,v_ofs,screen_ptr^,MAX_SCREEN_MEM_SIZE);
end;

function iVGA: Boolean;

var
  result: Boolean;

begin
  asm
        mov     ax,1a00h
        int     10h
        cmp     al,1ah
        jnz     @@1
        cmp     bl,7
        jb      @@1
        cmp     bl,0ffh
        jnz     @@2
@@1:    mov     result,FALSE
        jmp     @@3
@@2:    mov     result,TRUE
@@3:
  end;
  iVGA := result;
end;

procedure ResetMode;
begin
  asm
        xor     ah,ah
        mov     al,v_mode
        mov     bh,DispPg
        int     10h
  end;
  v_seg := $0b800;
  v_ofs := 0;
  MaxCol := MEM[SEG0040:$4a];
  MaxLn := SUCC(MEM[SEG0040:$84]);
  FillWord(screen_ptr^,MAX_SCREEN_MEM_SIZE DIV 2,$0700);
  dosmemput(v_seg,v_ofs,screen_ptr^,MAX_SCREEN_MEM_SIZE);
end;

procedure GetRGBitem(color: Byte; var red,green,blue: Byte);
begin
  outportb($3c7,color);
  red   := inportb($3c9);
  green := inportb($3c9);
  blue  := inportb($3c9);
end;

procedure SetRGBitem(color: Byte; red,green,blue: Byte);
begin
  outportb($3c8,color);
  outportb($3c9,red);
  outportb($3c9,green);
  outportb($3c9,blue);
end;

procedure WaitRetrace;
begin
  asm
        mov     dx,3dah
@@1:    in      al,dx
        and     al,08h
        jnz     @@1
@@2:    in      al,dx
        and     al,08h
        jz      @@2
  end;
end;

procedure GetPalette(var pal; first,last: Word);
begin
  asm
        xor     eax,eax
        xor     ecx,ecx
        mov     ax,first
        mov     cx,last
        sub     ecx,eax
        inc     ecx
        mov     dx,03c7h
        out     dx,al
        add     dx,2
        mov     edi,[pal]
        add     edi,eax
        add     edi,eax
        add     edi,eax
        mov     eax,ecx
        add     ecx,eax
        add     ecx,eax
        rep     insb
  end;
end;

procedure SetPalette(var pal; first,last: Word);
begin
  asm
        mov     dx,03dah
@@1:    in      al,dx
        test    al,8
        jz      @@1
        xor     eax,eax
        xor     ecx,ecx
        mov     ax,first
        mov     cx,last
        sub     ecx,eax
        inc     ecx
        mov     dx,03c8h
        out     dx,al
        inc     dx
        mov     esi,[pal]
        add     esi,eax
        add     esi,eax
        add     esi,eax
        mov     eax,ecx
        add     ecx,eax
        add     ecx,eax
        rep     outsb
  end;
end;

procedure VgaFade(var data: tFADE_BUF; fade: tFADE; delay: tDELAY);

var
  i,j: Byte;

begin
  If (fade = fadeOut) and (data.action in [first,fadeIn]) then
    begin
      GetPalette(data.pal0,0,255);
      If delay = delayed then
        For i := fade_speed downto 0 do
          begin
            For j := 0 to 255 do
              begin
                data.pal1[j].r := data.pal0[j].r * i DIV fade_speed;
                data.pal1[j].g := data.pal0[j].g * i DIV fade_speed;
                data.pal1[j].b := data.pal0[j].b * i DIV fade_speed;
              end;
            SetPalette(data.pal1,0,255);
            CRT.Delay(1);
          end
      else
        begin
          FillChar(data.pal1,SizeOf(data.pal1),0);
          SetPalette(data.pal1,0,255);
        end;
      data.action := fadeOut;
    end;

  If (fade = fadeIn) and (data.action = fadeOut) then
    begin
      If delay = delayed then
        For i := 0 to fade_speed do
          begin
            For j := 0 to 255 do
              begin
                data.pal1[j].r := data.pal0[j].r * i DIV fade_speed;
                data.pal1[j].g := data.pal0[j].g * i DIV fade_speed;
                data.pal1[j].b := data.pal0[j].b * i DIV fade_speed;
              end;
            SetPalette(data.pal1,0,255);
            CRT.Delay(1);
          end
      else
        SetPalette(data.pal0,0,255);
      data.action := fadeIn;
    end;
end;

procedure RefreshEnable;
begin
  asm
        mov     ax,1200h
        mov     bl,36h
        int     10h
  end;
end;

procedure RefreshDisable;
begin
  asm
        mov     ax,1201h
        mov     bl,36h
        int     10h
  end;
end;

procedure Split2Static;
begin
  inportb($3da);
  outportb($3c0,$10 OR $20);
  outportb($3c0,inportb($3c1) OR $20);
end;

procedure SplitScr(line: Word);

var
  temp: Byte;

begin
  outportb($3d4,$18);
  outportb($3d5,LO(line));
  outportb($3d4,$07);
  temp := inportb($3d5);

  If (line < $100) then temp := temp AND $0ef
  else temp := temp OR $10;

  outportb($3d5,temp);
  outportb($3d4,$09);
  temp := inportb($3d5);

  If (line < $200) then temp := temp AND $0bf
  else temp := temp OR $40;

  outportb($3d5,temp);
end;

procedure SetSize(columns,lines: Word);
begin
  outportb($3d4,$13);
  outportb($3d5,columns SHR 1);
  MEMW[Seg0040:$4a] := columns;
  MEMW[Seg0040:$84] := lines-1;
  MEMW[Seg0040:$4c] := columns*lines;
end;

procedure SetTextDisp(x,y: Word);

var
  maxcol_val: Byte;

begin
  While (inportb($3da) AND 1 = 1) do ;
  While (inportb($3da) AND 1 <> 1) do ;

  If NOT (program_screen_mode in [4,5]) then
    maxcol_val := MaxCol
  else maxcol_val := SCREEN_RES_X DIV scr_font_width;

  outportb($3d4,$0c);
  outportw($3d5,HI(WORD((y DIV scr_font_height)*maxcol_val+(x DIV scr_font_width))));
  outportb($3d4,$0d);
  outportw($3d5,LO(WORD((y DIV scr_font_height)*maxcol_val+(x DIV scr_font_width))));
  outportb($3d4,$08);
  outportb($3d5,(inportb($3d5) AND $0e0) OR (y AND $0f));
end;

procedure SetCustomVideoMode(vmode: tCUSTOM_VIDEO_MODE);

const
  vmode_data: array[0..52,0..63] of Byte = (

{ 1..5   - BIOS variables,
  6..9   - Sequencer,
  10     - Miscellaneous Output,
  11..35 - CRTC,
  36..55 - Attribute,
  56..64 - Graphics   }

{  0, Text 36x14, 9x14, complete }
(  36,  13,  14,   0, 4,     8,   3,   0,   2,    99,
  40, 35, 36,138, 38,192,183, 31,  0,205, 11, 12,  0,  0,  0,
   0,148,134,135, 18, 31,142,177,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{  1, Text 40x14, 8x14, complete }
(  40,  13,  14,   0, 5,     9,   3,   0,   2,    99,
  45, 39, 40,144, 43,160,183, 31,  0,205, 11, 12,  0,  0,  0,
   0,148,134,135, 20, 31,142,177,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{  2, Text 40x14, 9x14, complete }
(  40,  13,  14,   0, 5,     8,   3,   0,   2,   103,
  45, 39, 40,144, 43,160,183, 31,  0,205, 11, 12,  0,  0,  0,
   0,148,134,135, 20, 31,142,177,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{  3, Text 46x14, 8x14, complete }
(  46,  13,  14,   0, 6,     9,   3,   0,   2,   103,
  52, 45, 46,151, 50,150,183, 31,  0,205, 11, 12,  0,  0,  0,
   0,148,134,135, 23, 31,142,177,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{  4, Text 36x15, 9x16, complete }
(  36,  14,  16,  0, 5,     8,   3,   0,   2,   227,
  40, 35, 36,138, 38,192, 11, 62,  0,207, 13, 14,  0,  0,  0,
   0,234,172,223, 18, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{  5, Text 40x15, 8x16, complete }
(  40,  14,  16,   0, 5,     9,   3,   0,   2,   227,
  45, 39, 40,144, 43,160, 11, 62,  0,207, 13, 14,  0,  0,  0,
   0,234,172,223, 20, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{  6, Text 40x15, 9x16, complete }
(  40,  14,  16,   0, 5,     8,   3,   0,   2,   231,
  45, 39, 40,144, 43,160, 11, 62,  0,207, 13, 14,  0,  0,  0,
   0,234,172,223, 20, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{  7, Text 46x15, 8x16, complete }
(  46,  14,  16,   0, 6,     9,   3,   0,   2,   231,
  52, 45, 46,151, 50,150, 11, 62,  0,207, 13, 14,  0,  0,  0,
   0,234,172,223, 23, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{  8, Text 36x17, 9x14, complete }
(  36,  16,  14,   0, 5,     8,   3,   0,   2,   227,
  40, 35, 36,138, 38,192,  7, 62,  0,205, 11, 12,  0,  0,  0,
   0,230,168,219, 18, 31,227,  2,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{  9, Text 40x17, 8x14, complete }
(  40,  16,  14,   0, 6,     9,   3,   0,   2,   227,
  45, 39, 40,144, 43,160,  7, 62,  0,205, 11, 12,  0,  0,  0,
   0,230,168,219, 20, 31,227,  2,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 10, Text 40x17, 9x14, complete }
(  40,  16,  14,   0, 6,     8,   3,   0,   2,   231,
  45, 39, 40,144, 43,160,  7, 62,  0,205, 11, 12,  0,  0,  0,
   0,230,168,219, 20, 31,227,  2,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 11, Text 46x17, 9x14, complete }
(  46,  16,  14,   0, 7,     9,   3,   0,   2,   231,
  52, 45, 46,151, 50,150,  7, 62,  0,205, 11, 12,  0,  0,  0,
   0,230,168,219, 23, 31,227,  2,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{ 12, Text 36x22, 9x16, complete }
(  36,  21,  16,   0, 7,     8,   3,   0,   2,   163,
  40, 35, 36,138, 38,192,193, 31,  0, 79, 13, 14,  0,  0,  0,
   0,133,165, 95, 18, 31,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 13, Text 40x22, 8x16, complete }
(  40,  21,  16,   0, 7,     9,   3,   0,   2,   163,
  45, 39, 40,144, 43,160,193, 31,  0, 79, 13, 14,  0,  0,  0,
   0,133,165, 95, 20, 31,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 14, Text 40x22, 9x16, complete }
(  40,  21,  16,   0, 7,     8,   3,   0,   2,   167,
  45, 39, 40,144, 43,160,193, 31,  0, 79, 13, 14,  0,  0,  0,
   0,133,165, 95, 20, 31,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 15, Text 46x22, 8x16, complete }
(  46,  21,  16,   0, 8,     9,   3,   0,   2,   167,
  52, 45, 46,151, 50,150,193, 31,  0, 79, 13, 14,  0,  0,  0,
   0,133,165, 95, 23, 31,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 16, Text 70x22, 9x16, complete }
(  70,  21,  16,   0,13,     0,   3,   0,   2,   163,
  83, 69, 70,150, 75, 21,193, 31,  0, 79, 13, 14,  0,  0,  0,
   0,133,165, 95, 35, 31,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 17, Text 80x22, 8x16, complete }
(  80,  21,  16,   0,14,     1,   3,   0,   2,   163,
  95, 79, 80,130, 85,129,193, 31,  0, 79, 13, 14,  0,  0,  0,
   0,133,165, 95, 40, 31,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 18, Text 80x22, 9x16, complete }
(  80,  21,  16,   0,14,     0,   3,   0,   2,   167,
  95, 79, 80,130, 85,129,193, 31,  0, 79, 13, 14,  0,  0,  0,
   0,133,165, 95, 40, 31,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 19, Text 90x22, 8x16, complete }
(  90,  21,  16,   0,16,     1,   3,   0,   2,   167,
 107, 89, 90,142, 95,138,193, 31,  0, 79, 13, 14,  0,  0,  0,
   0,133,165, 95, 45, 31,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{ 20, Text 36x25, 9x16, complete }
(  36,  24,  16,   0, 8,     8,   3,   0,   2,    99,
  40, 35, 36,138, 38,192,191, 31,  0, 79, 13, 14,  0,  0,  0,
   0,156,142,143, 18, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 21, Text 40x25, 8x16, complete }
(  40,  24,  16,   0, 8,     9,   3,   0,   2,    99,
  45, 39, 40,144, 43,160,191, 31,  0, 79, 13, 14,  0,  0,  0,
   0,156,142,143, 20, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 22, Text 40x25, 9x16, complete }
(  40,  24,  16,   0, 8,     8,   3,   0,   2,   103,
  45, 39, 40,144, 43,160,191, 31,  0, 79, 13, 14,  0,  0,  0,
   0,156,142,143, 20, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 23, Text 46x25, 8x16, complete }
(  46,  24,  16,   0,10,     9,   3,   0,   2,   103,
  52, 45, 46,151, 50,150,191, 31,  0, 79, 13, 14,  0,  0,  0,
   0,156,142,143, 23, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 24, Text 70x25, 9x16, complete }
(  70,  24,  16,   0,14,     0,   3,   0,   2,   99,
  83, 69, 70,150, 75, 21,191, 31,  0, 79, 13, 14,  0,  0,  0,
   0,156,142,143, 35, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 25, Text 80x25, 8x16, complete }
(  80,  24,  16,   0,16,     1,   3,   0,   2,   99,
  95, 79, 80,130, 85,129,191, 31,  0, 79, 13, 14,  0,  0,  0,
   0,156,142,143, 40, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 26, Text 80x25, 9x16, standard }
(  80,  24,  16,   0,16,     0,   3,   0,   2,   103,
  95, 79, 80,130, 85,129,191, 31,  0, 79, 13, 14,  0,  0,  0,
   0,156,142,143, 40, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 27, Text 90x25, 8x16, complete }
(  90,  24,  16,  0, 18  ,   1,   3,   0,   2,  103,
 107, 89, 90,142, 95,138,191, 31,  0, 79, 13, 14,  0,  0,  0,
   0,156,142,143, 45, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{ 28, Text 46x29, 8x16, complete }
(  46,  28,  14,   0,11,     9,   3,   0,   2,   103,
  52, 45, 46,151, 50,150,193, 31,  0, 77, 11, 12,  0,  0,  0,
   0,159,145,149, 23, 31,155,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 29, Text 70x29, 9x14, complete }
(  70,  28,  14,  0, 16  ,   0,   3,   0,   2,   99,
  83, 69, 70,150, 75, 21,193, 31,  0, 77, 11, 12,  0,  0,  0,
   0,159,145,149, 35, 31,155,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 30, Text 80x29, 8x14, complete }
(  80,  28,  14,  0, 19  ,   1,   3,   0,   2,   99,
  95, 79, 80,130, 85,129,193, 31,  0, 77, 11, 12,  0,  0,  0,
   0,159,145,149, 40, 31,155,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 31, Text 80x29, 9x14, complete }
(  80,  28,  14,  0, 19  ,   0,   3,   0,   2,  103,
  95, 79, 80,130, 85,129,193, 31,  0, 77, 11, 12,  0,  0,  0,
   0,159,145,149, 40, 31,155,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 32, Text 90x29, 8x14, complete }
(  90,  28,  14,  0, 21  ,   1,   3,   0,   2,  103,
 107, 89, 90,142, 95,138,193, 31,  0, 77, 11, 12,  0,  0,  0,
   0,159,145,149, 45, 31,155,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{ 33, Text 70x30, 9x16, complete }
(  70,  29,  16,  0, 17  ,   0,   3,   0,   2,  227,
  83, 69, 70,150, 75, 21, 11, 62,  0, 79, 13, 14,  0,  0,  0,
   0,234,172,223, 35, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 34, Text 80x30, 8x16, complete }
(  80,  29,  16,  0, 19  ,   1,   3,   0,   2,  227,
  95, 79, 80,130, 85,129, 11, 62,  0, 79, 13, 14,  0,  0,  0,
   0,234,172,223, 40, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 35, Text 80x30, 9x16, complete }
(  80,  29,  16,  0, 19  ,   0,   3,   0,   2,  231,
  95, 79, 80,130, 85,129, 11, 62,  0, 79, 13, 14,  0,  0,  0,
   0,234,172,223, 40, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 36, Text 90x30, 8x16 ,complete }
(  90,  29,  16,  0, 22  ,   1,   3,   0,   2,  231,
 107, 89, 90,142, 95,138, 11, 62,  0, 79, 13, 14,  0,  0,  0,
   0,234,172,223, 45, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{ 37, Text 70x34, 9x14, complete }
(  70,  33,  14,  0, 19  ,   0,   3,   0,   2,  227,
  83, 69, 70,150, 75, 21,  7, 62,  0, 77, 11, 12,  0,  0,  0,
   0,230,168,219, 35, 31,227,  2,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 38, Text 80x34, 8x14, complete }
(  80,  33,  14,  0, 22  ,   1,   3,   0,   2,  227,
  95, 79, 80,130, 85,129,  7, 62,  0, 77, 11, 12,  0,  0,  0,
   0,230,168,219, 40, 31,227,  2,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 39, Text 80x34, 9x14, complete }
(  80,  33,  14,  0, 22  ,   0,   3,   0,   2,  231,
  95, 79, 80,130, 85,129,  7, 62,  0, 77, 11, 12,  0,  0,  0,
   0,230,168,219, 40, 31,227,  2,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 40, Text 90x34, 8x14, complete }
(  90,  33,  14,  0, 24  ,   1,   3,   0,   2,  231,
 107, 89, 90,142, 95,138,  7, 62,  0, 77, 11, 12,  0,  0,  0,
   0,230,168,219, 45, 31,227,  2,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{ 41, Text 70x44, 9x8, complete }
(  70,  43,   8,   0,25,     0,   3,   0,   2,   163,
  83, 69, 70,150, 75, 21,193, 31,  0, 71,  6,  7,  0,  0,  0,
   0,133,135, 95, 35, 15,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 42, Text 80x44, 8x8, complete }
(  80,  43,   8,   0,28,     1,   3,   0,   2,   163,
  95, 79, 80,130, 85,129,193, 31,  0, 71,  6,  7,  0,  0,  0,
   0,133,135, 95, 40, 15,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 43, Text 80x44, 9x8, complete }
(  80,  43,   8,   0,28,     0,   3,   0,   2,   167,
  95, 79, 80,130, 85,129,193, 31,  0, 71,  6,  7,  0,  0,  0,
   0,133,135, 95, 40, 15,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 44, Text 90x44, 8x8, complete }
(  90,  43,   8,   0,31,     1,   3,   0,   2,   167,
 107, 89, 90,142, 95,138,193, 31,  0, 71,  6,  7,  0,  0,  0,
   0,133,135, 95, 45, 15,101,187,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{ 45, Text 70x50, 9x8, complete }
(  70,  49,   8,   0,28,     0,   3,   0,   2,   99,
  83, 69, 70,150, 75, 21,191, 31,  0, 71,  6,  7,  0,  0,  0,
   0,156,142,143, 35, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 46, Text 80x50, 8x8, complete }
(  80,  49,   8,   0,32,     1,   3,   0,   2,   99,
  95, 79, 80,130, 85,129,191, 31,  0, 71,  6,  7,  0,  0,  0,
   0,156,142,143, 40, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 47, Text 80x50, 9x8, standard }
(  80,  49,   8,   0,32,     0,   3,   0,   2,   103,
  95, 79, 80,130, 85,129,191, 31,  0, 71,  6,  7,  0,  0,  0,
   0,156,142,143, 40, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63, 12,  0, 15, 8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 48, Text 90x50, 8x8, complete }
(  90,  49,   8,  0, 36  ,   1,   3,   0,   2,  103,
 107, 89, 90,142, 95,138,191, 31,  0, 71,  6,  7,  0,  0,  0,
   0,156,142,143, 45, 31,150,185,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),


{ 49, Text 70x60, 9x8, complete }
(  70,  59,   8,  0, 33  ,   0,   3,   0,   2,  227,
  83, 69, 70,150, 75, 21, 11, 62,  0, 71,  6,  7,  0,  0,  0,
   0,234,172,223, 35, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 50, Text 80x60, 8x8, complete }
(  80,  59,   8,  0, 38  ,   1,   3,   0,   2,  227,
  95, 79, 80,130, 85,129, 11, 62,  0, 71,  6,  7,  0,  0,  0,
   0,234,172,223, 40, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 51, Text 80x60, 9x8, complete }
(  80,  59,   8,  0, 38  ,   0,   3,   0,   2,  231,
  95, 79, 80,130, 85,129, 11, 62,  0, 71,  6,  7,  0,  0,  0,
   0,234,172,223, 40, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  8,
    0,   0,   0,   0,   0,  16,  14,   0, 255),

{ 52, Text 90x60, 8x8, complete }
(  90,  59,   8,128, 42  ,   1,   3,   0,   2,  231,
 107, 89, 90,142, 95,138, 11, 62,  0, 71,  6,  7,  0,  0,  0,
   0,234,172,223, 45, 31,231,  6,163,255,  0,  1,  2,  3,  4,
   5, 20,  7, 56, 57, 58, 59, 60, 61, 62, 63,  8,  0, 15,  0,
    0,   0,   0,   0,   0,  16,  14,   0, 255)

);

var
  _seg0040: Dword;
  temp: Byte;

begin
  _seg0040 := Seg0040;
  asm
        movzx   eax,vmode
        shl     eax,6
        lea     esi,[vmode_data]
        add     esi,eax
        mov     dx,3cch
        in      al,dx
        mov     dl,0d4h
        test    al,1
        jnz     @@1
        mov     dl,0b4h
@@1:    add     dx,6
        in      al,dx
        xor     al,al
        mov     dx,3c0h
        out     dx,al
        mov     ax,100h
        mov     dx,3c4h
        out     dx,ax
        add     esi,5
        mov     ecx,4
        mov     al,1
        mov     dx,3c4h
@@2:    mov     ah,[esi]
        inc     esi
        out     dx,ax
        inc     al
        loop    @@2
        mov     al,[esi]
        inc     esi
        mov     dx,3c2h
        out     dx,al
        mov     dx,3c4h
        mov     ax,300h
        out     dx,ax
        mov     dx,3cch
        in      al,dx
        mov     dl,0d4h
        test    al,1
        jnz     @@3
        mov     dl,0b4h
@@3:    mov     edi,_seg0040
        shl     edi,4
        add     edi,63h
        shl     edi,4
        mov     [edi],dx
        mov     al,11h
        out     dx,al
        inc     dx
        mov     ah,al
        in      al,dx
        dec     dx
        xchg    al,ah
        and     ah,7fh
        out     dx,ax
        mov     ecx,25
        xor     al,al
@@4:    mov     ah,[esi]
        inc     esi
        out     dx,ax
        inc     al
        loop    @@4
        add     dx,6
        in      al,dx
        xor     ah,ah
        mov     ecx,20
        mov     dx,3c0h
@@5:    mov     al,ah
        out     dx,al
        inc     ah
        mov     al,[esi]
        inc     esi
        out     dx,al
        loop    @@5
        xor     al,al
        mov     ecx,9
        mov     dx,3ceh
@@6:    mov     ah,[esi]
        inc     esi
        out     dx,ax
        inc     al
        loop    @@6
        mov     dx,3c0h
        mov     al,32
        out     dx,al
  end;

  MEM[SEG0040:$4a] := vmode_data[vmode,0];
  MEM[SEG0040:$84] := vmode_data[vmode,1];
  MEM[SEG0040:$85] := vmode_data[vmode,2];
  MEM[SEG0040:$4c] := vmode_data[vmode,3];
  MEM[SEG0040:$4d] := vmode_data[vmode,4];
  For temp := 0 to 16 do MEM[SEG0040:$4e+temp] := 0;

  MEM[SEG0040:$60] := vmode_data[vmode,20];
  MEM[SEG0040:$61] := vmode_data[vmode,21];
  MEM[SEG0040:$62] := 0;

  Case vmode_data[vmode,2] of
     8: asm mov ah,11h; mov al,2; xor bx,bx; int 10h end;
    14: asm mov ah,11h; mov al,1; xor bx,bx; int 10h end;
    16: asm mov ah,11h; mov al,4; xor bx,bx; int 10h end;
  end;

  initialize;
  dosmemput(v_seg,v_ofs,screen_ptr^,MAX_SCREEN_MEM_SIZE);
end;

procedure set_vga_txtmode_80x25;
begin
  asm
        mov     ax,03h
        xor     bh,bh
        int     10h
  end;

  v_seg := $0b800;
  v_ofs := 0;
  MaxCol := 80;
  MaxLn := 25;

  FillWord(screen_ptr^,MAX_SCREEN_MEM_SIZE DIV 2,$0700);
  dosmemput(v_seg,v_ofs,screen_ptr^,MAX_SCREEN_MEM_SIZE);
end;

procedure set_svga_txtmode_100x38;

var
  crt_address: Word;

begin
  // set VESA gfx mode 102h (800x600)
  asm
      mov  ax,4f02h
      mov  bx,102h
      int  10h
  end;

  // rerogram CRT controller
  crt_address := MEMW[SEG0040:$63];
  asm
      cli
      mov  dx,crt_address
      // clear write protection for CRT register 0-7
      mov  al,11h        // vertical retrace end register bit 7 reset
      out  dx,al
      inc  dx
      in   al,dx
      and  al,7fh
      out  dx,al
      dec  dx
      mov  al,9
      out  dx,al
      inc  dx
      in   al,dx
      and  al,0e0h       // clear bits 0-4
      or   al,0fh        // set max scan line to 15
      out  dx,al
      dec  dx
      mov  ax,0e0ah
      out  dx,ax
      mov  ax,0f0bh
      out  dx,ax
      mov  al,17h       // mode control register
      out  dx,al
      inc  dx
      in   al,dx
      and  al,not 40h   // set byte mode
      out  dx,al
      dec  dx
      // restore write protection for CRT register 0-7
      mov  al,11h
      out  dx,al
      inc  dx
      in   al,dx
      or   al,80h
      out  dx,al
      dec  dx
      // write sequencer: make planes 2+3 write protected
      mov  dx,3c4h
      mov  al,2
      mov  ah,3
      out  dx,ax
      // set odd/even mode, reset chain 4, more than 64 kB
      mov  dx,3c4h
      mov  al,4
      mov  ah,2
      out  dx,ax
      // write graphics controller
      mov  dx,3ceh
      mov  ax,1005h  // set write mode 0, read mode 0, odd/even addressing
      out  dx,ax
      mov  dx,3ceh
      mov  al,6
      out  dx,al
      inc  dx
      in   al,dx
      and  al,0f0h
      or   al,0eh    // set B800h as base, set text mode, set odd/even
      out  dx,al
      // write attribute controller
      mov  dx,3cch
      in   al,dx
      mov  dx,3dah
      test al,1
      jnz  @@1
      mov  dx,3bah
@@1:  in   al,dx     // reset attribute controller
      mov  dx,3c0h
      mov  al,10h    // select mode register
      out  dx,al
      mov  al,0      // set text mode [bit 0=0]
      out  dx,al
      mov  al,20h    // turn screen on again
      out  dx,al
      sti
  end;

  MaxCol := 100;
  MaxLn := 38;
  MEM[SEG0040:$4a] := MaxCol;
  MEM[SEG0040:$84] := MaxLn-1;

  initialize;
  dosmemput(v_seg,v_ofs,screen_ptr^,MAX_SCREEN_MEM_SIZE);
end;

procedure set_svga_txtmode_128x48;

var
  crt_address: Word;

begin
  // set VESA gfx mode 104h (1024x768)
  asm
      mov  ax,4f02h
      mov  bx,104h
      int  10h
  end;

  // rerogram CRT controller
  crt_address := MEMW[SEG0040:$63];
  asm
      cli
      mov  dx,crt_address
      // clear write protection for CRT register 0-7
      mov  al,11h        // vertical retrace end register bit 7 reset
      out  dx,al
      inc  dx
      in   al,dx
      and  al,7fh
      out  dx,al
      dec  dx
      mov  al,9
      out  dx,al
      inc  dx
      in   al,dx
      and  al,0e0h       // clear bits 0-4
      or   al,0fh        // set max scan line to 15
      out  dx,al
      dec  dx
      mov  ax,0e0ah
      out  dx,ax
      mov  ax,0f0bh
      out  dx,ax
      mov  al,17h       // mode control register
      out  dx,al
      inc  dx
      in   al,dx
      and  al,not 40h   // set byte mode
      out  dx,al
      dec  dx
      // restore write protection for CRT register 0-7
      mov  al,11h
      out  dx,al
      inc  dx
      in   al,dx
      or   al,80h
      out  dx,al
      dec  dx
      // write sequencer: make planes 2+3 write protected
      mov  dx,3c4h
      mov  al,2
      mov  ah,3
      out  dx,ax
      // set odd/even mode, reset chain 4, more than 64 kB
      mov  dx,3c4h
      mov  al,4
      mov  ah,2
      out  dx,ax
      // write graphics controller
      mov  dx,3ceh
      mov  ax,1005h  // set write mode 0, read mode 0, odd/even addressing
      out  dx,ax
      mov  dx,3ceh
      mov  al,6
      out  dx,al
      inc  dx
      in   al,dx
      and  al,0f0h
      or   al,0eh    // set B800h as base, set text mode, set odd/even
      out  dx,al
      // write attribute controller
      mov  dx,3cch
      in   al,dx
      mov  dx,3dah
      test al,1
      jnz  @@1
      mov  dx,3bah
@@1:  in   al,dx     // reset attribute controller
      mov  dx,3c0h
      mov  al,10h    // select mode register
      out  dx,al
      mov  al,0      // set text mode [bit 0=0]
      out  dx,al
      mov  al,20h    // turn screen on again
      out  dx,al
      sti
  end;

  MaxCol := 128;
  MaxLn := 48;
  MEM[SEG0040:$4a] := MaxCol;
  MEM[SEG0040:$84] := MaxLn-1;

  initialize;
  dosmemput(v_seg,v_ofs,screen_ptr^,MAX_SCREEN_MEM_SIZE);
end;

const
  ATTRCON_ADDR   = $3c0; // Attribute Controller
  MISC_ADDR      = $3c2; // Miscellaneous Register
  VGAENABLE_ADDR = $3c3; // VGA Enable Register
  SEQ_ADDR       = $3c4; // Sequencer
  GRACON_ADDR    = $3ce; // Graphics Controller
  CRTC_ADDR      = $3d4; // CRT Controller
  STATUS_ADDR    = $3da; // Status Register

procedure LoadVgaRegisters(reg: VGA_REG_DATA);

procedure out_reg(reg: VGA_REGISTER);
begin
  Case (reg.port) of
    ATTRCON_ADDR:
      begin
        inportb(STATUS_ADDR);
        outportb(ATTRCON_ADDR,reg.idx OR $20);
        outportb(ATTRCON_ADDR,reg.val);
      end;

    MISC_ADDR,
    VGAENABLE_ADDR:
      outportb(reg.port,reg.val);

    else begin
           outportb(reg.port,reg.idx);
           outportb(reg.port+1,reg.val);
         end;
  end;
end;

var
  idx,temp: Byte;

begin
  outportb($3d4,$11);
  temp := inportb($3d5) AND $7f;
  outportb($3d4,$11);
  outportb($3d5,temp);
  For idx := 1 to 29 do out_reg(reg[idx]);
end;

procedure set_custom_svga_txtmode;
begin
  LoadVgaRegisters(svga_txtmode_regs);
  MaxCol := svga_txtmode_cols;
  MaxLn := svga_txtmode_rows;
  MEM[SEG0040:$4a] := MaxCol;
  MEM[SEG0040:$84] := MaxLn-1;
  initialize;
  dosmemput(v_seg,v_ofs,screen_ptr^,MAX_SCREEN_MEM_SIZE);
end;

{$ENDIF}

procedure move2screen;

var
  screen_ptr_backup: Pointer;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'TXTSCRIO.PAS:move2screen';
{$ENDIF}
  HideCursor;
  screen_ptr_backup := screen_ptr;
  screen_ptr := move_to_screen_data;
  area_x1 := 0;
  area_y1 := 0;
  area_x2 := 0;
  area_y2 := 0;
  scroll_pos0 := BYTE_NULL;
  scroll_pos1 := BYTE_NULL;
  scroll_pos2 := BYTE_NULL;
  scroll_pos3 := BYTE_NULL;
  scroll_pos4 := BYTE_NULL;
  PATTERN_ORDER_page_refresh(pattord_page);
  PATTERN_page_refresh(pattern_page);
  status_refresh;
  decay_bars_refresh;
  ScreenMemCopy(screen_ptr,screen_ptr_backup);
  screen_ptr := screen_ptr_backup;
  SetCursor(cursor_backup);
end;

function is_default_screen_mode: Boolean;
begin
{$IFDEF GO32V2}
  is_default_screen_mode :=
    (program_screen_mode = 0) or
    ((program_screen_mode = 3) and (comp_text_mode < 4));
{$ELSE}
  is_default_screen_mode := (program_screen_mode = 0);
{$ENDIF}
end;

{$IFDEF GO32V2}
function is_VESA_emulated_mode: Boolean;
begin
  is_VESA_emulated_mode := (program_screen_mode = 3) and
                           (comp_text_mode > 1);
end;

function get_VESA_emulated_mode_idx: Byte;
begin
  get_VESA_emulated_mode_idx := min(comp_text_mode-2,0);
end;
{$ENDIF}

function is_scrollable_screen_mode: Boolean;
begin
{$IFDEF GO32V2}
  is_scrollable_screen_mode :=
    (program_screen_mode = 0) or
        ((program_screen_mode = 3) and (comp_text_mode < 2)) or
    (is_VESA_emulated_mode and (get_VESA_emulated_mode_idx in [0,1]));
{$ELSE}
  is_scrollable_screen_mode := (program_screen_mode = 0);
{$ENDIF}
end;

procedure TxtScrIO_Init;

var
  temp: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'TXTSCRIO.PAS:TxtScrIO_Init';
  program_screen_mode := screen_mode;
{$ENDIF}

  mn_environment.v_dest := screen_ptr;
  centered_frame_vdest := screen_ptr;

{$IFDEF GO32V2}
  If NOT is_VESA_emulated_mode then
{$ENDIF}
    Case program_screen_mode of
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
           INSEDIT_yshift := 0;
           PATTORD_xshift := 0;
           MaxCol := MAX_COLUMNS;
           MaxLn := MAX_ROWS;
           hard_maxcol := MAX_COLUMNS;
           hard_maxln := 30;
           work_MaxCol := MAX_COLUMNS;
           work_MaxLn := 30;
           scr_font_width := 8;
           scr_font_height := 16;
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
           INSEDIT_yshift := 12;
           PATTORD_xshift := 1;
           MaxCol := MAX_COLUMNS;
           MaxLn := MAX_ROWS;
           hard_maxcol := MAX_COLUMNS;
           hard_maxln := 50;
           work_MaxCol := MAX_COLUMNS;
           work_MaxLn := 40;
           scr_font_width := 8;
           scr_font_height := 16;
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
           INSEDIT_yshift := 12;
           PATTORD_xshift := 0;
           MaxCol := MAX_COLUMNS;
           MaxLn := MAX_ROWS;
           hard_maxcol := MAX_COLUMNS;
           hard_maxln := 60;
           work_MaxCol := MAX_COLUMNS;
           work_MaxLn := 50;
           scr_font_width := 8;
           scr_font_height := 16;
         end;
      // 90x47
      4: begin
           SCREEN_RES_X := 800;
           SCREEN_RES_Y := 600;
           MAX_COLUMNS := 90;
           MAX_ROWS := 38;
           MAX_ORDER_COLS := 9;
           MAX_TRACKS := 5;
           MAX_PATTERN_ROWS := 16;
           INSCTRL_xshift := 0;
           INSCTRL_yshift := 4;
           INSEDIT_yshift := 12;
           PATTORD_xshift := 0;
           MaxCol := MAX_COLUMNS;
           MaxLn := MAX_ROWS;
           hard_maxcol := MAX_COLUMNS;
           hard_maxln := 38;
           work_MaxCol := MAX_COLUMNS;
           work_MaxLn := 38;
           scr_font_width := 8;
           scr_font_height := 16;
           GOTOXY_xshift := ((SCREEN_RES_X DIV scr_font_width)-MAX_COLUMNS) DIV 2;
         end;
      // 120x47
      5: begin
           SCREEN_RES_X := 1024;
           SCREEN_RES_Y := 768;
           MAX_COLUMNS := 120;
           MAX_ROWS := 48;
           MAX_ORDER_COLS := 13;
           MAX_TRACKS := 7;
           MAX_PATTERN_ROWS := 26;
           INSCTRL_xshift := 15;
           INSCTRL_yshift := 7;
           INSEDIT_yshift := 12;
           PATTORD_xshift := 1;
           MaxCol := MAX_COLUMNS;
           MaxLn := MAX_ROWS;
           hard_maxcol := MAX_COLUMNS;
           hard_maxln := 48;
           work_MaxCol := MAX_COLUMNS;
           work_MaxLn := 48;
           scr_font_width := 8;
           scr_font_height := 16;
           GOTOXY_xshift := ((SCREEN_RES_X DIV scr_font_width)-MAX_COLUMNS) DIV 2;
         end;
{$IFDEF GO32V2}
      // compatibility text-mode
      3: Case comp_text_mode of
           0,
           1: begin
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
                INSEDIT_yshift := 0;
                MaxCol := MAX_COLUMNS;
                MaxLn := MAX_ROWS;
                hard_maxcol := MAX_COLUMNS;
                hard_maxln := 30;
                work_MaxCol := MAX_COLUMNS;
                work_MaxLn := 30;
                scr_font_width := 9;
                scr_font_height := 16;
              end;
         end;
    end
  else
    // VESA-emulated text-mode
    Case get_VESA_emulated_mode_idx of
      // 90x30 (default mode)
      0: begin
           SCREEN_RES_X := 800;
           SCREEN_RES_Y := 600;
           MAX_COLUMNS := 90;
           MAX_ROWS := 40;
           MAX_ORDER_COLS := 9;
           MAX_TRACKS := 5;
           MAX_PATTERN_ROWS := 18;
           INSCTRL_xshift := 0;
           INSCTRL_yshift := 0;
           INSEDIT_yshift := 0;
           PATTORD_xshift := 0;
           MaxCol := MAX_COLUMNS;
           MaxLn := MAX_ROWS;
           hard_maxcol := MAX_COLUMNS;
           hard_maxln := 30;
           work_MaxCol := MAX_COLUMNS;
           work_MaxLn := 30;
           scr_font_width := 8;
           scr_font_height := 16;
         end;
      // 90x47
      1: begin
           SCREEN_RES_X := 800;
           SCREEN_RES_Y := 600;
           MAX_COLUMNS := 90;
           MAX_ROWS := 46;
           MAX_ORDER_COLS := 9;
           MAX_TRACKS := 5;
           MAX_PATTERN_ROWS := 24;
           INSCTRL_xshift := 0;
           INSCTRL_yshift := 4;
           INSEDIT_yshift := 0;
           PATTORD_xshift := 0;
           MaxCol := MAX_COLUMNS;
           MaxLn := MAX_ROWS;
           hard_maxcol := MAX_COLUMNS;
           hard_maxln := 36;
           work_MaxCol := MAX_COLUMNS;
           work_MaxLn := 36;
           scr_font_width := 8;
           scr_font_height := 16;
         end;
      // 120x47
      2: begin
           SCREEN_RES_X := 1024;
           SCREEN_RES_Y := 768;
           MAX_COLUMNS := 120;
           MAX_ROWS := 46;
           MAX_ORDER_COLS := 13;
           MAX_TRACKS := 7;
           MAX_PATTERN_ROWS := 24;
           INSCTRL_xshift := 15;
           INSCTRL_yshift := 7;
           INSEDIT_yshift := 12;
           PATTORD_xshift := 1;
           MaxCol := MAX_COLUMNS;
           MaxLn := MAX_ROWS;
           hard_maxcol := MAX_COLUMNS;
           hard_maxln := 47;
           work_MaxCol := MAX_COLUMNS;
           work_MaxLn := 36;
           scr_font_width := 8;
           scr_font_height := 16;
         end;
    end;
{$ELSE}
    end;
{$ENDIF}

  FillWord(screen_ptr^,MAX_SCREEN_MEM_SIZE DIV 2,$0700);
  SCREEN_MEM_SIZE := (SCREEN_RES_X DIV scr_font_width)*MAX_ROWS*2;
  move_to_screen_routine := @move2screen;

  If (command_typing = 0) then _pattedit_lastpos := 4*MAX_TRACKS
  else _pattedit_lastpos := 10*MAX_TRACKS;

  Case MAX_COLUMNS of
    120: temp := 1;
    180: temp := 2;
    else temp := 0;
  end;

  patt_win[1] := patt_win_tracks[temp][1];
  patt_win[2] := patt_win_tracks[temp][2];
  patt_win[3] := patt_win_tracks[temp][3];
  patt_win[4] := patt_win_tracks[temp][4];
  patt_win[5] := patt_win_tracks[temp][5];
end;

end.
