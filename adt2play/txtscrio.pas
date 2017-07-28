unit TxtScrIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

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

const
  MAX_SCREEN_MEM_SIZE = 180*60*2;
  SCREEN_MEM_SIZE: Longint = MAX_SCREEN_MEM_SIZE;

type
  tSCREEN_MEM = array[0..PRED(MAX_SCREEN_MEM_SIZE)] of Byte;
  tSCREEN_MEM_PTR = ^tSCREEN_MEM;

var
  text_screen_shadow: tSCREEN_MEM;

const
  screen_ptr: Pointer = Addr(text_screen_shadow);
  v_seg:  Word = $0b800;
  v_ofs:  Word = 0;
  v_mode: Byte = $03;
  MaxLn:  Byte = 80;
  MaxCol: Byte = 25;

var
  cursor_backup: Longint;
  DispPg: Byte;

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

type
  tVIDEO_STATE = Record
                   cursor: Longint;
                   font: Byte;
                   MaxLn,MaxCol,v_mode,DispPg: Byte;
                   v_seg,v_ofs: Word;
                   screen: tSCREEN_MEM;
                   data: array[0..PRED(4096)] of Byte;
                 end;

procedure ShowC3Str(var dest; x,y: Byte; str: String; atr1,atr2,atr3: Byte);
function  iVGA:  Boolean;
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
procedure GetRGBitem(color: Byte; var red,green,blue: Byte);
procedure SetRGBitem(color: Byte; red,green,blue: Byte);
procedure GetPalette(var pal; first,last: Word);
procedure SetPalette(var pal; first,last: Word);
procedure WaitRetrace;
procedure VgaFade(var data: tFADE_BUF; fade: tFADE; delay: tDELAY);
procedure GetVideoState(var data: tVIDEO_STATE);
procedure SetVideoState(var data: tVIDEO_STATE; restore_screen: Boolean);

implementation
uses
  GO32;

var
  absolute_pos: Word;

procedure DupChar; assembler;
asm
        pushad                           {  IN/ al     -column        }
        xor     ebx,ebx                  {      ah     -line          }
        xchg    ax,bx                    {      dl     -character     }
        xor     eax,eax                  {      dh     -attribute     }
        xchg    ax,bx                    {      ecx    -count         }
        mov     bl,al                    {      edi    -ptr. to write }
        mov     al,MaxCol
        mul     ah
        add     ax,bx
        mov     bl,MaxCol
        sub     ax,bx
        dec     ax
        shl     ax,1
        jecxz   @@1
        add     edi,eax
        xchg    ax,dx
        rep     stosw
        xchg    ax,dx
@@1:    mov     absolute_pos,ax
        popad
end;

procedure ShowC3Str(var dest; x,y: Byte; str: String; atr1,atr2,atr3: Byte);
begin
  asm
        lea     esi,[str]
        mov     edi,dword ptr [dest]
        lodsb
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@3
        push    ecx
        mov     al,x
        mov     ah,y
        xor     ecx,ecx
        call    DupChar
        xor     edx,edx
        mov     dx,absolute_pos
        pop     ecx
        add     edi,edx
        mov     ah,atr1
        mov     bl,atr2
        mov     bh,atr3
@@1:    lodsb
        cmp     al,'~'
        jz      @@2
        cmp     al,'`'
        jz      @@3
        stosw
        loop    @@1
        jmp     @@4
@@2:    xchg    ah,bl
        loop    @@1
        jmp     @@4
@@3:    xchg    ah,bh
        loop    @@1
@@4:
  end;
end;

procedure ScreenMemCopy(source,dest: tSCREEN_MEM_PTR);
begin
  cursor_backup := GetCursor;
  asm
        xor     edx,edx
        mov     eax,SCREEN_MEM_SIZE
        cmp     eax,16
        jb      @@1
        mov     ecx,4
        div     ecx
        mov     ecx,eax
        jecxz   @@1
        mov     esi,dword ptr [source]
        mov     edi,dword ptr [dest]
        cld
        rep     movsd
        mov     ecx,edx
        jecxz   @@2
        rep     movsb
        jmp     @@2
@@1:    mov     ecx,SCREEN_MEM_SIZE
        mov     esi,dword ptr [source]
        mov     edi,dword ptr [dest]
        cld
        rep     movsb
@@2:
  end;
end;

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
        mov     dh,y
        mov     dl,x
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

procedure initialize;
begin
  asm
        mov     ah,0fh
        int     10h
        and     al,7fh
        mov     v_mode,al
        mov     DispPg,bh
  end;

  MaxCol := MEM[0:$44a];
  MaxLn := SUCC(MEM[0:$484]);
  FillWord(screen_ptr^,MAX_SCREEN_MEM_SIZE DIV 2,$0700);
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

const
  fade_first: Byte = 0;
  fade_last:  Byte = 255;

procedure VgaFade(var data: tFADE_BUF; fade: tFADE; delay: tDELAY);

var
  i,j: Byte;

begin
  If (fade = fadeOut) and (data.action in [first,fadeIn]) then
    begin
      GetPalette(data.pal0,fade_first,fade_last);
      If delay = delayed then
        For i := fade_speed downto 0 do
          begin
            For j := fade_first to fade_last do
              begin
                data.pal1[j].r := data.pal0[j].r * i DIV fade_speed;
                data.pal1[j].g := data.pal0[j].g * i DIV fade_speed;
                data.pal1[j].b := data.pal0[j].b * i DIV fade_speed;
              end;
            SetPalette(data.pal1,fade_first,fade_last);
            WaitRetrace;
          end
      else
        begin
          FillChar(data.pal1,SizeOf(data.pal1),0);
          SetPalette(data.pal1,fade_first,fade_last);
        end;
      data.action := fadeOut;
    end;

  If (fade = fadeIn) and (data.action = fadeOut) then
    begin
      If delay = delayed then
        For i := 0 to fade_speed do
          begin
            For j := fade_first to fade_last do
              begin
                data.pal1[j].r := data.pal0[j].r * i DIV fade_speed;
                data.pal1[j].g := data.pal0[j].g * i DIV fade_speed;
                data.pal1[j].b := data.pal0[j].b * i DIV fade_speed;
              end;
            SetPalette(data.pal1,fade_first,fade_last);
            WaitRetrace;
          end
      else
        SetPalette(data.pal0,fade_first,fade_last);
      data.action := fadeIn;
    end;
end;

var
  regs: tRealRegs;
  dos_sel,dos_seg: Word;
  dos_mem_adr: Dword;
  bios_data_backup: array[0..167] of Byte;

procedure GetVideoState(var data: tVIDEO_STATE);
begin
  asm
        mov     ah,0fh
        int     10h
        and     al,7fh
        mov     v_mode,al
        mov     DispPg,bh
  end;

  dosmemget(v_seg,v_ofs,data.screen,MAX_SCREEN_MEM_SIZE);
  data.cursor := GetCursor;
  data.font := MEMW[Seg0040:$85];
  data.v_seg := $0b800;
  data.v_ofs := MEM[Seg0040:$4e];
  data.DispPg := DispPg;
  data.v_mode := v_mode;
  data.MaxCol := MEM[Seg0040:$4a];
  data.MaxLn := SUCC(MEM[Seg0040:$84]);

  dosmemget(Seg0040,0,bios_data_backup,168);
  dos_mem_adr := global_dos_alloc(SizeOf(tVIDEO_STATE(data).data));
  dos_sel := WORD(dos_mem_adr);
  dos_seg := WORD(dos_mem_adr SHR 16);
  regs.cx := 7;
  regs.es := dos_seg;
  regs.ax := $1c01;
  RealIntr($10,regs);
  dosmemput(Seg0040,0,bios_data_backup,168);
  dosmemget(dos_seg,0,tVIDEO_STATE(data).data,SizeOf(tVIDEO_STATE(data).data));
  global_dos_free(dos_sel);
end;

procedure SetVideoState(var data: tVIDEO_STATE; restore_screen: Boolean);
begin
  v_seg  := data.v_seg;
  v_ofs  := data.v_ofs;
  v_mode := data.v_mode;
  DispPg := data.DispPg;

  asm
        movzx   ax,v_mode
        mov     bh,DispPg
        int     10h
  end;

  MaxCol := data.MaxCol;
  MaxLn := data.MaxLn;

  dosmemget(Seg0040,0,bios_data_backup,168);
  dos_mem_adr := global_dos_alloc(SizeOf(tVIDEO_STATE(data).data));
  dos_sel := WORD(dos_mem_adr);
  dos_seg := WORD(dos_mem_adr SHR 16);
  dosmemput(dos_seg,0,tVIDEO_STATE(data).data,SizeOf(tVIDEO_STATE(data).data));

  regs.cx := 7;
  regs.es := dos_seg;
  regs.ax := $1c02;
  RealIntr($10,regs);
  global_dos_free(dos_sel);
  dosmemput(Seg0040,0,bios_data_backup,168);

  MEM[Seg0040:$4e] := data.v_ofs;
  MEM[Seg0040:$4a] := MaxCol;
  MEM[Seg0040:$84] := PRED(MaxLn);

  Case data.font of
     8:  asm mov ax,1112h; xor bl,bl; int 10h end;
    14:  asm mov ax,1111h; xor bl,bl; int 10h end;
    else asm mov ax,1114h; xor bl,bl; int 10h end;
  end;

  SetCursor(data.cursor);
  If restore_screen then
    dosmemput(v_seg,v_ofs,data.screen,MAX_SCREEN_MEM_SIZE);
end;

begin
  initialize;
end.
