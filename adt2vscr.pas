{
    Virtual text screen stuff
    Various string functions dealing with text video memory layout (char+attr)
    Rendering virtual text screen to 8bpp video buffer
}
unit AdT2vscr;
{$PACKRECORDS 1}
interface

const                          { sdl_screen_mode = 0/1}
  MAX_COLUMNS: Byte = 90;      { 90 / 120 }
  MAX_ROWS: Byte = 40;         { 40 / 50  }
  MAX_TRACKS: Byte = 5;        { 5 / 7    }
  MAX_ORDER_COLS: Byte = 9;    { 9 / 13   }
  MAX_PATTERN_ROWS: Byte = 18; { 18 / 26  }
  INS_CTRL_xshift: Byte = 0;   { 0 / 10   }
  INS_CTRL_yshift: Byte = 0;   { 0 / 8    }  

var
  PATEDIT_lastpos: Byte;   
  
{$i font8x16.inc}
var
  vscreen: array[0..PRED(120*50*2)] of Byte;
  FB_xres,FB_yres,FB_rows: Longint; { framebuffer dimensions + rows to render }

const
  virtual_screen: Pointer = @vscreen;
  virtual_screen_font: Pointer = Addr(font8x16);
  virtual_screen__first_row: Longint = 0;
  virtual_cur_shape: Word = 0;
  virtual_cur_pos: Word = 0;
  cursor_sync: Boolean = FALSE;
  hard_maxcol: Byte = 0;
  hard_maxln:  Byte = 0;

const
  _FrameBuffer: pointer = NIL; { CHANGE TO SDL_SURFACE LATER }

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

procedure emulate_screen_all;
procedure move2screen_alt;
procedure show_str(xpos,ypos: Byte; str: String; color: Byte);
procedure show_cstr(xpos,ypos: Byte; str: String; attr1,attr2: Byte);
procedure show_vstr(xpos,ypos: Byte; str: String; color: Byte);
procedure show_vcstr(xpos,ypos: Byte; str: String; attr1,attr2: Byte);
procedure ShowStr(var dest; x,y: Byte; str: String; attr: Byte);
procedure ShowVStr(var dest; x,y: Byte; str: String; attr: Byte);
procedure ShowCStr(var dest; x,y: Byte; str: String; atr1,atr2: Byte);
procedure ShowCStr2(var dest; x,y: Byte; str: String; atr1,atr2: Byte);
procedure ShowVCStr(var dest; x,y: Byte; str: String; atr1,atr2: Byte);
procedure ShowVCStr2(var dest; x,y: Byte; str: String; atr1,atr2: Byte);
procedure ShowC3Str(var dest; x,y: Byte; str: String; atr1,atr2,atr3: Byte);
procedure ShowVC3Str(var dest; x,y: Byte; str: String; atr1,atr2,atr3: Byte);
function  CStrLen(str: String): Byte;
function  CStr2Len(str: String): Byte;
function  C3StrLen(str: String): Byte;
function  AbsPos(x,y: Byte): Word;
function  Color(fgnd,bgnd: Byte): Byte;
procedure CleanScreen(var dest);
procedure reset_critical_area;
procedure Frame(var dest; x1,y1,x2,y2,atr1: Byte; title: String; atr2: Byte; border: String);

const
  emulate_screen: Procedure = nil;

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

const
  solid1 = '        ';
  solid2 = 'ÛßÛÛÛÛÜÛ';
  single = 'ÚÄ¿³³ÀÄÙ';
  double = 'ÉÍ»ººÈÍ¼';
  dbside = 'ÖÄ·ººÓÄ½';
  dbtop  = 'ÕÍ¸³³ÔÍ¾';

implementation
uses
  AdT2unit,
  DialogIO,TxtScrIO;

procedure emulate_screen_all;

type
  pBYTE = ^BYTE;

var
  pD: pBYTE;
  pS: Pointer;
  mask: Byte;
  buffer_end: Longint;

const
  bit_pos: Byte = 0;
  bit_mask: Byte = 0;
  skip: Dword = 0;
  pos_x: Byte = 0;
  pos_y: Byte = 0;
  hundereds_counter: Longint = 0;

begin
  // blink cursor
  Inc(hundereds_counter);
  If (hundereds_counter > 12) then
    begin
      hundereds_counter := 0;
      cursor_sync := boolean(ord(cursor_sync) XOR 1);
    end;

  pD := _FrameBuffer + (FB_xres-MAX_COLUMNS*8) DIV 2 + (FB_yres-FB_rows*16) DIV 2 * FB_xres;
  buffer_end := FB_xres * FB_yres - (FB_xres-MAX_COLUMNS*8) DIV 2 - (FB_yres-FB_rows*16) DIV 2 * FB_xres;
  pS := virtual_screen;
  skip := virtual_screen__first_row; // always mouse_y*800, even if 1024*768
  For pos_y := 1 to MAX_ROWS do
    begin
      For bit_pos := 0 to 15 do
        begin
          // uncomment to render 8x16 font as 8x12; this allows to fit 90*40 rows into 720x480 window
          // If (bit_pos = 1) or (bit_pos = 5) or (bit_pos = 9) or (bit_pos = 13) then Inc(bit_pos);
          If (pD-_FrameBuffer >= buffer_end) then EXIT;
          If (skip = 0) then
            begin
              For pos_x := 1 to MAX_COLUMNS do
                begin
                  bit_mask := pBYTE(virtual_screen_font + pBYTE(pS)^ * 16 + bit_pos)^;
                  mask := $80;
                  While (mask > 0) do
                    begin
                      If (cursor_sync = TRUE) and
                         (pos_x = LO(virtual_cur_pos)) and
                         (pos_y = HI(virtual_cur_pos)) and
                         (bit_pos >= hi(virtual_cur_shape)) and
                         (bit_pos <= lo(virtual_cur_shape)) then
                        pD^ := pbyte(pS+1)^ AND $0f
                      else If (bit_mask AND mask <> 0) then pD^ := pBYTE(pS+1)^ AND $0f
                           else pD^ := pBYTE(pS+1)^ SHR 4;
                      Inc(pD);
                      mask := mask SHR 1;
                    end;
                    Inc(pS,2);
                end;
                Dec(pS,MAX_COLUMNS*2);
                Inc(pD,FB_xres-MAX_COLUMNS*8);
            end
          else
            Dec(skip,800);
        end;
        Inc(pS,MAX_COLUMNS*2);
    end;
end;

const
  SCREEN_SIZE = 120*50*SizeOf(WORD);

type
//  pSCREEN = ^tSCREEN;
  tSCREEN = array[0..PRED(SCREEN_SIZE)] of Byte;

var
  temp_screen: tSCREEN;
  area_x1,area_y1,area_x2,area_y2: Byte;

procedure move2screen_alt; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,dword ptr [virtual_screen]
        lea     edi,[temp_screen]
        mov     ecx,SCREEN_SIZE
        push    edi
        push    esi
        push    ecx
        rep     movsb
        mov     esi,[move_to_screen_data]
        lea     edi,[temp_screen]
        xor     ecx,ecx
        mov     cl,byte ptr [move_to_screen_area+1]
@@1:    push    ecx
        xor     ecx,ecx
        mov     cl,byte ptr [move_to_screen_area+0]
@@2:    pop     eax
        push    eax
        push    ecx
        push    eax
        call    AbsPos
        push    esi
        push    edi
        add     esi,eax
        add     edi,eax
        movsw
        pop     edi
        pop     esi
        inc     ecx
        cmp     cl,byte ptr [move_to_screen_area+2]
        jbe     @@2
        pop     ecx
        inc     ecx
        cmp     cl,byte ptr [move_to_screen_area+3]
        jbe     @@1
        pop     ecx
        pop     edi
        pop     esi
        rep     movsb
        pop     edi
        pop     esi
        pop     ecx
end;

procedure show_str(xpos,ypos: Byte; str: String; color: Byte); assembler;

var
  x11,x12,x21,x22,y11,y21: Byte;
  index: Byte;

asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        xor     ebx,ebx
        xor     ecx,ecx
        mov     edi,dword ptr [virtual_screen]
        mov     edx,edi
        mov     esi,[str]
        lodsb
        mov     cl,al
        or      ecx,ecx
        jz      @@7
        mov     al,area_x1
        mov     x11,al
        inc     x11
        mov     x12,al
        add     x12,2
        mov     al,area_x2
        mov     x21,al
        inc     x21
        mov     x22,al
        add     x22,2
        mov     al,area_y1
        mov     y11,al
        inc     y11
        mov     al,area_y2
        mov     y21,al
        inc     y21
        mov     index,1
@@1:    mov     edi,edx
        xor     bx,bx
        mov     bl,xpos
        add     bl,index
        sub     bl,2
        mov     ah,ypos
        dec     ah
        mov     al,MaxCol
        mul     ah
        add     bx,ax
        shl     bx,1
        mov     al,xpos
        add     al,index
        dec     al
        mov     ah,ypos
        cmp     al,x12
        jnae    @@2
        cmp     al,x22
        jnbe    @@2
        cmp     ah,y21
        jne     @@2
        jmp     @@3
@@2:    cmp     al,x21
        jnae    @@4
        cmp     al,x22
        jnbe    @@4
        cmp     ah,y11
        jnae    @@4
        cmp     ah,y21
        jnbe    @@4
@@3:    add     edi,ebx
        movsb
        jmp     @@6
@@4:    cmp     al,area_x1
        jnae    @@5
        cmp     al,area_x2
        jnbe    @@5
        cmp     ah,area_y1
        jnae    @@5
        cmp     ah,area_y2
        jnbe    @@5
        lodsb
        jmp     @@6
@@5:    add     edi,ebx
        lodsb
        mov     ah,color
        stosw
@@6:    inc     index
        cmp     index,cl
        jbe     @@1
@@7:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure show_cstr(xpos,ypos: Byte; str: String; attr1,attr2: Byte); assembler;

var
  x11,x12,x21,x22,y11,y21: Byte;
  index,color1,color2: Byte;

asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     al,attr1
        mov     color1,al
        mov     al,attr2
        mov     color2,al
        xor     ebx,ebx
        xor     ecx,ecx
        mov     edi,dword ptr [virtual_screen]
        mov     edx,edi
        mov     esi,[str]
        lodsb
        mov     cl,al
        or      ecx,ecx
        jz      @@7
        mov     al,area_x1
        mov     x11,al
        inc     x11
        mov     x12,al
        add     x12,2
        mov     al,area_x2
        mov     x21,al
        inc     x21
        mov     x22,al
        add     x22,2
        mov     al,area_y1
        mov     y11,al
        inc     y11
        mov     al,area_y2
        mov     y21,al
        inc     y21
        mov     index,1
@@1:    mov     edi,edx
        xor     bx,bx
        mov     bl,xpos
        add     bl,index
        sub     bl,2
        mov     ah,ypos
        dec     ah
        mov     al,MaxCol
        mul     ah
        add     bx,ax
        shl     bx,1
        mov     al,xpos
        add     al,index
        dec     al
        mov     ah,ypos
        cmp     al,x12
        jnae    @@2
        cmp     al,x22
        jnbe    @@2
        cmp     ah,y21
        jne     @@2
        jmp     @@3
@@2:    cmp     al,x21
        jnae    @@4
        cmp     al,x22
        jnbe    @@4
        cmp     ah,y11
        jnae    @@4
        cmp     ah,y21
        jnbe    @@4
@@3:    add     edi,ebx
@@3a:   lodsb
        cmp     al,'~'
        jnz     @@3b
        push    eax
        mov     al,color1
        mov     ah,color2
        xchg    al,ah
        mov     color1,al
        mov     color2,ah
        pop     eax
        dec     cl
        cmp     index,cl
        jbe     @@3a
        cmp     al,'~'
        jz      @@7
@@3b:   stosb
        jmp     @@6
@@4:    cmp     al,area_x1
        jnae    @@5
        cmp     al,area_x2
        jnbe    @@5
        cmp     ah,area_y1
        jnae    @@5
        cmp     ah,area_y2
        jnbe    @@5
@@4a:   lodsb
        cmp     al,'~'
        jnz     @@6
        push    eax
        mov     al,color1
        mov     ah,color2
        xchg    al,ah
        mov     color1,al
        mov     color2,ah
        pop     eax
        dec     cl
        cmp     index,cl
        jbe     @@4a
        jmp     @@7
@@5:    add     edi,ebx
@@5a:   lodsb
        cmp     al,'~'
        jnz     @@5b
        push    eax
        mov     al,color1
        mov     ah,color2
        xchg    al,ah
        mov     color1,al
        mov     color2,ah
        pop     eax
        dec     cl
        cmp     index,cl
        jbe     @@5a
        jmp     @@7
@@5b:   mov     ah,color1
        stosw
@@6:    inc     index
        cmp     index,cl
        jbe     @@1
@@7:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure show_vstr(xpos,ypos: Byte; str: String; color: Byte); assembler;

var
  x11,x12,x21,x22,y11,y21: Byte;
  index: Byte;

asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        xor     ebx,ebx
        xor     ecx,ecx
        mov     edi,dword ptr [virtual_screen]
        mov     edx,edi
        mov     esi,[str]
        lodsb
        mov     cl,al
        or      ecx,ecx
        jz      @@7
        mov     al,area_x1
        mov     x11,al
        inc     x11
        mov     x12,al
        add     x12,2
        mov     al,area_x2
        mov     x21,al
        inc     x21
        mov     x22,al
        add     x22,2
        mov     al,area_y1
        mov     y11,al
        inc     y11
        mov     al,area_y2
        mov     y21,al
        inc     y21
        mov     index,1
@@1:    mov     edi,edx
        xor     bx,bx
        mov     bl,xpos
        dec     bl
        mov     ah,ypos
        add     ah,index
        sub     ah,2
        mov     al,MaxCol
        mul     ah
        add     bx,ax
        shl     bx,1
        mov     al,xpos
        mov     ah,ypos
        add     ah,index
        dec     ah
        cmp     al,x12
        jnae    @@2
        cmp     al,x22
        jnbe    @@2
        cmp     ah,y21
        jne     @@2
        jmp     @@3
@@2:    cmp     al,x21
        jnae    @@4
        cmp     al,x22
        jnbe    @@4
        cmp     ah,y11
        jnae    @@4
        cmp     ah,y21
        jnbe    @@4
@@3:    add     edi,ebx
        movsb
        jmp     @@6
@@4:    cmp     al,area_x1
        jnae    @@5
        cmp     al,area_x2
        jnbe    @@5
        cmp     ah,area_y1
        jnae    @@5
        cmp     ah,area_y2
        jnbe    @@5
        lodsb
        jmp     @@6
@@5:    add     edi,ebx
        lodsb
        mov     ah,color
        stosw
@@6:    inc     index
        cmp     index,cl
        jbe     @@1
@@7:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure show_vcstr(xpos,ypos: Byte; str: String; attr1,attr2: Byte); assembler;

var
  x11,x12,x21,x22,y11,y21: Byte;
  index,color1,color2: Byte;

asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     al,attr1
        mov     color1,al
        mov     al,attr2
        mov     color2,al
        xor     ebx,ebx
        xor     ecx,ecx
        mov     edi,dword ptr [virtual_screen]
        mov     edx,edi
        mov     esi,[str]
        lodsb
        mov     cl,al
        or      ecx,ecx
        jz      @@7
        mov     al,area_x1
        mov     x11,al
        inc     x11
        mov     x12,al
        add     x12,2
        mov     al,area_x2
        mov     x21,al
        inc     x21
        mov     x22,al
        add     x22,2
        mov     al,area_y1
        mov     y11,al
        inc     y11
        mov     al,area_y2
        mov     y21,al
        inc     y21
        mov     index,1
@@1:    mov     edi,edx
        xor     bx,bx
        mov     bl,xpos
        dec     bl
        mov     ah,ypos
        add     ah,index
        sub     ah,2
        mov     al,MaxCol
        mul     ah
        add     bx,ax
        shl     bx,1
        mov     al,xpos
        mov     ah,ypos
        add     ah,index
        dec     ah
        cmp     al,x12
        jnae    @@2
        cmp     al,x22
        jnbe    @@2
        cmp     ah,y21
        jne     @@2
        jmp     @@3
@@2:    cmp     al,x21
        jnae    @@4
        cmp     al,x22
        jnbe    @@4
        cmp     ah,y11
        jnae    @@4
        cmp     ah,y21
        jnbe    @@4
@@3:    add     edi,ebx
@@3a:   lodsb
        cmp     al,'~'
        jnz     @@3b
        push    eax
        mov     al,color1
        mov     ah,color2
        xchg    al,ah
        mov     color1,al
        mov     color2,ah
        pop     eax
        dec     cl
        cmp     index,cl
        jbe     @@3a
        cmp     al,'~'
        jz      @@7
@@3b:   stosb
        jmp     @@6
@@4:    cmp     al,area_x1
        jnae    @@5
        cmp     al,area_x2
        jnbe    @@5
        cmp     ah,area_y1
        jnae    @@5
        cmp     ah,area_y2
        jnbe    @@5
@@4a:   lodsb
        cmp     al,'~'
        jnz     @@6
        push    eax
        mov     al,color1
        mov     ah,color2
        xchg    al,ah
        mov     color1,al
        mov     color2,ah
        pop     eax
        dec     cl
        cmp     index,cl
        jbe     @@4a
        jmp     @@7
@@5:    add     edi,ebx
@@5a:   lodsb
        cmp     al,'~'
        jnz     @@5b
        push    eax
        mov     al,color1
        mov     ah,color2
        xchg    al,ah
        mov     color1,al
        mov     color2,ah
        pop     eax
        dec     cl
        cmp     index,cl
        jbe     @@5a
        jmp     @@7
@@5b:   mov     ah,color1
        stosw
@@6:    inc     index
        cmp     index,cl
        jbe     @@1
@@7:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

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

procedure ShowStr(var dest; x,y: Byte; str: String; attr: Byte); assembler;
asm
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     edi,[dest]
        mov     esi,[str]
        mov     al,x
        mov     ah,y
        xor     ecx,ecx
        call    DupChar
        xor     edx,edx
        mov     dx,absolute_pos
        lodsb
        mov     cl,al
        jecxz   @@2
        add     edi,edx
        mov     ah,attr
@@1:    lodsb
        stosw
        loop    @@1
@@2:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
end;

procedure ShowVStr(var dest; x,y: Byte; str: String; attr: Byte); assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     al,MaxCol
        dec     al
        xor     ah,ah
        xor     ebx,ebx
        mov     bl,2
        mul     bl
        mov     bx,ax
        mov     edi,[dest]
        mov     esi,[str]
        mov     al,x
        mov     ah,y
        xor     ecx,ecx
        call    DupChar
        xor     edx,edx
        mov     dx,absolute_pos
        lodsb
        mov     cl,al
        jecxz   @@2
        add     edi,edx
        mov     ah,attr
@@1:    lodsb
        stosw
        add     edi,ebx
        loop    @@1
@@2:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure ShowCStr(var dest; x,y: Byte; str: String; atr1,atr2: Byte); assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,[dest]
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
        mov     bh,atr2
@@1:    lodsb
        cmp     al,'~'
        jz      @@2
        stosw
        loop    @@1
        jmp     @@3
@@2:    xchg    ah,bh
        loop    @@1
@@3:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure ShowCStr2(var dest; x,y: Byte; str: String; atr1,atr2: Byte); assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,[dest]
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
        mov     bh,atr2
@@1:    lodsb
        cmp     al,'`'
        jz      @@2
        stosw
        loop    @@1
        jmp     @@3
@@2:    xchg    ah,bh
        loop    @@1
@@3:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure ShowVCStr(var dest; x,y: Byte; str: String; atr1,atr2: Byte); assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     al,MaxCol
        dec     al
        xor     ah,ah
        mov     bl,2
        mul     bl
        mov     bx,ax
        mov     esi,[str]
        mov     edi,[dest]
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
        mov     dx,bx
        mov     ah,atr1
        mov     bh,atr2
@@1:    lodsb
        cmp     al,'~'
        jz      @@2
        stosw
        add     edi,edx
        loop    @@1
        jmp     @@3
@@2:    xchg    ah,bh
        loop    @@1
@@3:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure ShowVCStr2(var dest; x,y: Byte; str: String; atr1,atr2: Byte); assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     al,MaxCol
        dec     al
        xor     ah,ah
        mov     bl,2
        mul     bl
        mov     bx,ax
        mov     esi,[str]
        mov     edi,[dest]
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
        mov     dx,bx
        mov     ah,atr1
        mov     bh,atr2
@@1:    lodsb
        cmp     al,'`'
        jz      @@2
        stosw
        add     edi,edx
        loop    @@1
        jmp     @@3
@@2:    xchg    ah,bh
        loop    @@1
@@3:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure ShowC3Str(var dest; x,y: Byte; str: String; atr1,atr2,atr3: Byte); assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,[dest]
        lodsb
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@4
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
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure ShowVC3Str(var dest; x,y: Byte; str: String; atr1,atr2,atr3: Byte); assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     al,MaxCol
        dec     al
        xor     ah,ah
        mov     bl,2
        mul     bl
        mov     bx,ax
        mov     esi,[str]
        mov     edi,[dest]
        lodsb
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@4
        push    ecx
        mov     al,x
        mov     ah,y
        xor     ecx,ecx
        call    DupChar
        xor     edx,edx
        mov     dx,absolute_pos
        pop     ecx
        add     edi,edx
        mov     dx,bx
        mov     ah,atr1
        mov     bl,atr2
        mov     bh,atr3
@@1:    lodsb
        cmp     al,'~'
        jz      @@2
        cmp     al,'`'
        jz      @@3
        stosw
        add     edi,edx
        loop    @@1
        jmp     @@4
@@2:    xchg    ah,bl
        loop    @@1
        jmp     @@4
@@3:    xchg    ah,bh
        loop    @@1
@@4:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

function CStrLen(str: String): Byte; assembler;
asm
        push    ebx
        push    ecx
        push    esi
        mov     esi,[str]
        lodsb
        xor     ebx,ebx
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@3
@@1:    lodsb
        cmp     al,'~'
        jz      @@2
        inc     ebx
        loop    @@1
        jmp     @@3
@@2:    loop    @@1
@@3:    mov     eax,ebx
        pop     esi
        pop     ecx
        pop     ebx
end;

function CStr2Len(str: String): Byte; assembler;
asm
        push    ebx
        push    ecx
        push    esi
        mov     esi,[str]
        lodsb
        xor     ebx,ebx
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@3
@@1:    lodsb
        cmp     al,'`'
        jz      @@2
        inc     ebx
        loop    @@1
        jmp     @@3
@@2:    loop    @@1
@@3:    mov     eax,ebx
        pop     esi
        pop     ecx
        pop     ebx
end;

function C3StrLen(str: String): Byte; assembler;
asm
        push    ebx
        push    ecx
        push    esi
        mov     esi,[str]
        lodsb
        xor     ebx,ebx
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@4
@@1:    lodsb
        cmp     al,'~'
        jz      @@2
        cmp     al,'`'
        jz      @@3
        inc     ebx
        loop    @@1
        jmp     @@4
@@2:    loop    @@1
        jmp     @@4
@@3:    loop    @@1
@@4:    mov     eax,ebx
        pop     esi
        pop     ecx
        pop     ebx
end;

function AbsPos(x,y: Byte): Word; assembler;
asm
        push    ecx // AAARRRGHHH!!! another stupid bug !!! TMT saves all the regs, but FPC not!!!
        mov     al,x // move2screen_alt relies on ecx being saved!
        mov     ah,y
        xor     ecx,ecx
        call    DupChar
        mov     ax,absolute_pos
        pop     ecx
end;

function Color(fgnd,bgnd: Byte): Byte;
begin
    Color := (bgnd SHL 8) OR fgnd;
end;

procedure CleanScreen(var dest);

type
  tVIRTUAL_SCREEN = array[0..PRED(120)*PRED(50)] of Word;

var
  idx1,idx2: Byte;

begin
  For idx2 := 0 to PRED(120) do
    For idx1 := 0 to PRED(50) do
      tVIRTUAL_SCREEN(dest)[idx2*MaxLn+idx1] := $0007;
end;

procedure Frame(var dest; x1,y1,x2,y2,atr1: Byte;
                          title: String; atr2: Byte; border: String); assembler;
var
  xexp1,xexp2,xexp3,yexp1,yexp2: Byte;
  offs: Longint;

asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        cmp     fr_setting.update_area,1
        jnz     @@0
        mov     al,x1
        mov     area_x1,al
        mov     al,y1
        mov     area_y1,al
        mov     al,x2
        mov     area_x2,al
        mov     al,y2
        mov     area_y2,al
@@0:    mov     bl,fr_setting.wide_range_type
        mov     bh,fr_setting.shadow_enabled
        mov     esi,[border]
        mov     edi,[dest]
        mov     offs,edi
        cmp     bl,0
        je      @@1
        mov     xexp1,4
        mov     xexp2,-1
        mov     xexp3,7
        mov     yexp1,1
        mov     yexp2,2
        jmp     @@2
@@1:    mov     xexp1,1
        mov     xexp2,2
        mov     xexp3,1
        mov     yexp1,0
        mov     yexp2,1
        jmp     @@4
@@2:    mov     al,x1
        sub     al,3
        mov     ah,y1
        dec     ah
        mov     dl,' '
        mov     dh,atr1
        xor     ecx,ecx
        mov     cl,x2
        sub     cl,x1
        add     cl,7
        call    DupChar
        mov     ah,y2
        inc     ah
        call    DupChar
        mov     bl,y1
@@3:    mov     al,x1
        sub     al,3
        mov     ah,bl
        mov     dl,' '
        mov     ecx,3
        call    DupChar
        mov     al,x2
        inc     al
        mov     dl,' '
        mov     ecx,3
        call    DupChar
        inc     bl
        cmp     bl,y2
        jng     @@3
@@4:    mov     al,x1
        mov     ah,y1
        mov     dl,[esi+1]
        mov     dh,atr1
        mov     ecx,1
        push    edi
        call    DupChar
        inc     al
        mov     dl,[esi+2]
        mov     dh,atr1
        mov     cl,x2
        sub     cl,x1
        dec     cl
        call    DupChar
        mov     al,x2
        mov     dl,[esi+3]
        mov     dh,atr1
        mov     ecx,1
        call    DupChar
        mov     bl,y1
@@5:    inc     bl
        mov     al,x1
        mov     ah,bl
        mov     dl,[esi+4]
        mov     dh,atr1
        mov     ecx,1
        call    DupChar
        inc     al
        mov     dl,' '
        mov     dh,atr1
        mov     cl,x2
        sub     cl,x1
        dec     cl
        call    DupChar
        mov     al,x2
        mov     dl,[esi+5]
        mov     dh,atr1
        mov     ecx,1
        call    DupChar
        cmp     bl,y2
        jnge    @@5
        mov     al,x1
        mov     ah,y2
        mov     dl,[esi+6]
        mov     dh,atr1
        mov     ecx,1
        call    DupChar
        inc     al
        mov     dl,[esi+7]
        mov     cl,x2
        sub     cl,x1
        dec     cl
        call    DupChar
        mov     al,x2
        mov     dl,[esi+8]
        mov     dh,atr1
        mov     ecx,1
        call    DupChar
        mov     esi,[title]
        mov     cl,[esi]
        jecxz   @@7
        xor     eax,eax
        mov     al,x2
        sub     al,x1
        sub     al,cl
        mov     bl,2
        div     bl
        add     al,x1
        add     al,ah
        mov     ah,y1
        xor     ecx,ecx
        call    DupChar
        push    eax
        xor     eax,eax
        mov     ax,absolute_pos
        mov     edi,offs
        add     edi,eax
        pop     eax
        lodsb
        mov     cl,al
        mov     ah,atr2
@@6:    lodsb
        stosw
        loop    @@6
@@7:    cmp     bh,0
        je      @@11
        mov     bl,y1
        sub     bl,yexp1
@@8:    inc     bl
        mov     al,x2
        add     al,xexp1
        mov     ah,bl
        xor     ecx,ecx
        call    DupChar
        push    eax
        xor     eax,eax
        mov     ax,absolute_pos
        mov     edi,offs
        add     edi,eax
        pop     eax
        inc     edi
        mov     al,07
        stosb
        cmp     MaxLn,120
        jae     @@9
        inc     edi
        stosb
        cmp     MaxCol,132
        jna     @@9
        inc     edi
        stosb
@@9:    cmp     bl,y2
        jng     @@8
        mov     al,x1
        add     al,xexp2
        mov     ah,y2
        add     ah,yexp2
        xor     ecx,ecx
        call    DupChar
        push    eax
        xor     eax,eax
        mov     ax,absolute_pos
        mov     edi,offs
        add     edi,eax
        pop     eax
        inc     edi
        mov     al,07
        mov     cl,x2
        sub     cl,x1
        add     cl,xexp3
        cmp     MaxLn,45
        jb      @@10
        dec     cl
@@10:   stosb
        inc     edi
        loop    @@10
@@11:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

procedure reset_critical_area;
begin
  area_x1 := 0;
  area_y1 := 0;
  area_x2 := 0;
  area_y2 := 0;
end;

end.
