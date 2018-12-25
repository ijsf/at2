//  This file is part of Adlib Tracker II (AT2).
//
//  AT2 is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  AT2 is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with AT2.  If not, see <http://www.gnu.org/licenses/>.

unit A2scrIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

const
  _title_xpos = 10;
  _title_ypos = 8;
  _title_color = 160;
  _title_offset = 320*40;
  _timer_xpos = 198;
  _timer_ypos = 5;
  _timer_color = 1;
  _place_holder_color = 150;
  _progress_xpos = 8;
  _progress_ypos = 155;
  _progress_color = 251;
  _fname_xpos = 8;
  _fname_ypos = 170;
  _fname_color = 255;
  _pos_str_xpos = 8;
  _pos_str_ypos = 186;
  _pos_str_color = 252;

const
  _decay_bars_initialized: Boolean = FALSE;
  _decay_bar_xpos = 10;
  _decay_bar_ypos = 140;
  _decay_bar_palette_start = 250;
  _picture_mode: Boolean = FALSE;
  _window_top: Byte = 8;

var
  correction: Integer;
  entries,
  entries2: Byte;
  delay_counter: Byte;

procedure refresh_decay_bar(xpos: Word; level: Byte);
procedure decay_bars_refresh;
procedure wtext(xstart,ystart: Word; txt: String; color: Byte);
procedure wtext2(xstart,ystart: Word; txt: String; color: Byte);
procedure C3Write(str: String; atr1,atr2,atr3: Byte);
procedure C3WriteLn(str: String; atr1,atr2,atr3: Byte);
procedure CWriteLn(str: String; atr1,atr2: Byte);

function  _progress_str: String;
function  _timer_str: String;
function  _position_str: String;
function  _position_str2: String;

procedure toggle_picture_mode;
procedure fade_out;

implementation

uses
  GO32,
  A2data,A2player,A2fileIO,
  StringIO,TxtScrIO;

const
  _ptr_font8x8: Pointer = @font8x8;
  _ptr_font8x16: Pointer = @font8x16;
  _ptr_picture_palette: Pointer = @picture_palette;
  _ptr_picture_bitmap: Pointer = @picture_bitmap;

const
  decay_bar_rise: Real = 50.0;
  decay_bar_fall: Real = 5.00;

var
  old_decay_bar_value: array[1..25] of Byte;
  vmem_320x200: array[0..PRED(320*200)] of Byte;
  vmem_320x200_mirror: array[0..PRED(320*200)] of Byte;
  fade_buf,fade_buf2: tFADE_BUF;

procedure refresh_decay_bar(xpos: Word; level: Byte);

var
  _data_ofs: Dword;

begin
  _data_ofs := DWORD(Addr(vmem_320x200));
  asm
        mov     edi,_data_ofs
        mov     edx,[_ptr_picture_palette]
        mov     esi,[_ptr_picture_bitmap]
        mov     eax,_decay_bar_ypos
        mov     ebx,320
        mul     ebx
        movzx   ebx,xpos
        add     eax,ebx
        add     edi,eax
        cmp     level,BYTE_NULL
        jnz     @@1
        mov     level,0
        jmp     @@2
@@1:    cmp     level,2
        jae     @@2
        mov     level,2
@@2:    mov     ecx,10
        jecxz   @@10
@@3:    push    ecx
        push    edi
        mov     ecx,63*4/3
        jecxz   @@9
@@4:    mov     ebx,63*4/3
        sub     ebx,ecx
        movzx   eax,level
        cmp     ebx,eax
        jnae    @@5
        mov     ebx,edi
        sub     ebx,_data_ofs
        add     ebx,esi
        movzx   eax,byte ptr [ebx]
        jmp     @@8
@@5:    mov     eax,63*4/3
        push    edx
        xor     edx,edx
        sub     eax,ecx
        mov     ebx,5
        div     ebx
        mov     eax,edx
        pop     edx
        cmp     eax,3
        jbe     @@6
        mov     ebx,edi
        sub     ebx,_data_ofs
        add     ebx,esi
        movzx   eax,byte ptr [ebx]
        jmp     @@8
@@6:    or      eax,eax
        jnz     @@7
        xor     eax,eax
        jmp     @@8
@@7:    add     eax,_decay_bar_palette_start
        cmp     level,2
        jnbe    @@8
        mov     eax,_place_holder_color
@@8:    mov     byte ptr [edi],al
        sub     edi,320
        loop    @@4
@@9:    pop     edi
        pop     ecx
        inc     edi
        loop    @@3
@@10:
  end;
end;

procedure decay_bars_refresh;

var
  temp: Byte;

begin
  _debug_str_:= 'A2SCRIO.PAS:decay_bars_refresh';
  If NOT _picture_mode then EXIT;
  dosmemget($0a000,_title_offset,vmem_320x200[_title_offset],
            320*_decay_bar_ypos-_title_offset);
  If NOT _decay_bars_initialized then
    begin
      _decay_bars_initialized := TRUE;
      For temp := 1 to 25 do
        old_decay_bar_value[temp] := BYTE_NULL;
      For temp := 1 to 25 do
        begin
          decay_bar[temp].lvl := 0;
          decay_bar[temp].dir := -1;
          refresh_decay_bar(_decay_bar_xpos+PRED(temp)*12,0);
        end;
    end;

  For temp := 1 to 25 do
    begin
      If (decay_bar[temp].dir = 1) then
        decay_bar[temp].lvl := decay_bar[temp].lvl+
                 decay_bar[temp].dir*(decay_bar_rise/IRQ_freq*100)
      else
        decay_bar[temp].lvl := decay_bar[temp].lvl+
                 decay_bar[temp].dir*(decay_bar_fall/IRQ_freq*100);

      If (decay_bar[temp].lvl < 0) then decay_bar[temp].lvl := 0;
      If (decay_bar[temp].lvl > decay_bar[temp].max_lvl) then
        begin
          decay_bar[temp].dir := -1;
          If (decay_bar[temp].lvl > 63) then
            decay_bar[temp].lvl := 63;
        end;

      If (old_decay_bar_value[temp] <> ROUND(decay_bar[temp].lvl*4/3)) then
        begin
          refresh_decay_bar(_decay_bar_xpos+PRED(temp)*12,
                            ROUND(decay_bar[temp].lvl*4/3));
          old_decay_bar_value[temp] := ROUND(decay_bar[temp].lvl*4/3);
        end;
    end;
  dosmemput($0a000,_title_offset,vmem_320x200[_title_offset],
            320*_decay_bar_ypos-_title_offset);
end;

procedure wtext(xstart,ystart: Word; txt: String; color: Byte);

var
  x,y: Word;
  temp,i,j,b: Word;

begin
  _debug_str_:= 'A2SCRIO.PAS:wtext';
  If NOT _picture_mode then EXIT;
  dosmemget($0a000,320*ystart,vmem_320x200[320*ystart],(8+1)*320);
  Move(pGENERIC_IO_BUFFER(_ptr_picture_bitmap)^[320*ystart],
       vmem_320x200_mirror[320*ystart],(8+1)*320);

  x := xstart+1;
  y := ystart+1;

  For temp := 1 to Length(txt) do
    begin
      For j := 0 to 7 do
        begin
          b := tCHAR8x8(_ptr_font8x8^)[txt[temp]][j];
          For i := 7 downto 0 do
            If (b OR (1 SHL i) = b) then
              vmem_320x200_mirror[x+7-i+(y+j)*320] := 0
        end;
      Inc(x,8);
    end;

  x := xstart;
  y := ystart;

  For temp := 1 to Length(txt) do
    begin
      For j := 0 to 7 do
        begin
          b := tCHAR8x8(_ptr_font8x8^)[txt[temp]][j];
          For i := 7 downto 0 do
            If (b OR (1 SHL i) = b) then
              vmem_320x200[x+7-i+(y+j)*320] := color
            else vmem_320x200[x+7-i+(y+j)*320] := vmem_320x200_mirror[x+7-i+(y+j)*320];
        end;
      Inc(x,8);
    end;

  dosmemput($0a000,320*ystart,vmem_320x200[320*ystart],(8+1)*320);
end;

procedure wtext2(xstart,ystart: Word; txt: String; color: Byte);

const
  _double: array[0..15] of Byte = (0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7);

var
  x,y: Word;
  temp,i,j,b: Word;

begin
  _debug_str_:= 'A2SCRIO.PAS:wtext2';
  If NOT _picture_mode then EXIT;
  dosmemget($0a000,320*ystart,vmem_320x200[320*ystart],(16+1)*320);
  Move(pGENERIC_IO_BUFFER(_ptr_picture_bitmap)^[320*ystart],
       vmem_320x200_mirror[320*ystart],(16+1)*320);

  x := xstart+1;
  y := ystart+1;

  For temp := 1 to Length(txt) do
    begin
      For j := 0 to 15 do
        begin
          b := tCHAR8x16(_ptr_font8x16^)[txt[temp]][j];
          For i := 15 downto 0 do
            If (b OR (1 SHL _double[i]) = b) then
              vmem_320x200_mirror[x+15-i+(y+j)*320] := 0
        end;
      Inc(x,16);
    end;

  x := xstart;
  y := ystart;

  For temp := 1 to Length(txt) do
    begin
      For j := 0 to 15 do
        begin
          b := tCHAR8x16(_ptr_font8x16^)[txt[temp]][j];
          For i := 15 downto 0 do
            If (b OR (1 SHL _double[i]) = b) then
              vmem_320x200[x+15-i+(y+j)*320] := color
            else vmem_320x200[x+15-i+(y+j)*320] := vmem_320x200_mirror[x+15-i+(y+j)*320];
        end;
      Inc(x,16);
    end;

  dosmemput($0a000,320*ystart,vmem_320x200[320*ystart],(16+1)*320);
end;

procedure C3Write(str: String; atr1,atr2,atr3: Byte);
begin
  _debug_str_:= 'A2SCRIO.PAS:CWrite';
  If _picture_mode then EXIT;
  dosmemget($0b800,0,screen_ptr^,MAX_SCREEN_MEM_SIZE);
  ShowC3Str(screen_ptr^,WhereX,WhereY,str,atr1,atr2,atr3);
  dosmemput($0b800,0,screen_ptr^,MAX_SCREEN_MEM_SIZE);
  GotoXY(1,WhereY);
end;

procedure C3WriteLn(str: String; atr1,atr2,atr3: Byte);
begin
  _debug_str_:= 'A2SCRIO.PAS:C3WriteLn';
  If _picture_mode then EXIT;
  ShowC3Str(screen_ptr^,WhereX,WhereY,str,
            atr1,atr2,atr3);
  WriteLn;
end;

procedure CWriteLn(str: String; atr1,atr2: Byte);

var
  temp: Word;
  attr,posx,posy: Byte;
  color2: Boolean;

begin
  _debug_str_:= 'A2SCRIO.PAS:CWriteLn';
  If _picture_mode then EXIT;
  color2 := FALSE;
  attr := atr1;
  posx := WhereX;
  posy := WhereY;

  For temp := 1 to Length(str) do
    If (str[temp] <> '~') then
      begin
        dosmemput($0b800,(posx-1+(posy-1)*MaxCol) SHL 1,BYTE(str[temp]),1);
        dosmemput($0b800,(posx-1+(posy-1)*MaxCol) SHL 1+1,attr,1);
        If (posx < MaxCol) then Inc(posx)
        else begin
               posx := 1;
               Inc(posy);
               If (posy > MaxLn) then
                 begin
                   asm
                        mov     ah,06h
                        mov     al,1
                        mov     bh,07h
                        mov     ch,_window_top
                        mov     cl,1
                        mov     dh,MaxLn
                        mov     dl,MaxCol
                        dec     ch
                        dec     cl
                        dec     dh
                        dec     dl
                        int     10h
                   end;
                   Dec(posy);
                 end;
             end;
      end
    else begin
           color2 := NOT color2;
           If color2 then attr := atr2 else attr := atr1;
         end;

  Inc(posy);
  If (posy > MaxLn) then
    begin
      asm
           mov     ah,06h
           mov     al,1
           mov     bh,07h
           mov     ch,_window_top
           mov     cl,1
           mov     dh,MaxLn
           mov     dl,MaxCol
           dec     ch
           dec     cl
           dec     dh
           dec     dl
           int     10h
      end;
      Dec(posy);
    end;

  posx := 1;
  GotoXY(posx,posy);
end;

function __progress_str(value: Byte): String;

var
  result: String;

begin
  result := '';
  Repeat
    If (value > 4) then
      begin
        result := result+#4;
        Dec(value,4);
      end;
    If (value <= 4) and (value <> 0) then
      result := result+CHR(0+value)
  until (value <= 4);
  __progress_str := result;
end;

function _progress_str: String;
begin
  If (songdata.patt_len = 0) then EXIT;
  If (entries <> 0) then
     _progress_str :=
       ExpStrR(__progress_str(
                 ROUND(4*38/entries*(current_order-correction+
                 1/songdata.patt_len*(current_line+1)))),38,#0)
  else _progress_str := ExpStrR('',38,#0);
end;

function _timer_str: String;
begin
  _timer_str := ExpStrL(Num2str(song_timer DIV 60,10),2,'0')+':'+
                ExpStrL(Num2str(song_timer MOD 60,10),2,'0')+'.'+
                Num2str(song_timer_tenths DIV 10,10);
end;

function _position_str: String;
begin
  If (songdata.patt_len = 0) then EXIT;
  If (entries <> 0) then
    _position_str :=
      'Order '+ExpStrL(Num2str(current_order,10),3,'0')+'/'+
               ExpStrL(Num2str(PRED(entries2),10),3,'0')+', '+
      'pattern '+ExpStrL(Num2str(current_pattern,10),3,'0')+', '+
      'row '+ExpStrL(Num2str(current_line,10),3,'0')+' '+
      '['+ExpStrL(Num2str(ROUND(100/entries*(current_order-correction+
          1/songdata.patt_len*(current_line+1))),10),3,'0')+'%] '+
      '['+_timer_str+']'+' '
  else _position_str :=
         'Order '+ExpStrL(Num2str(current_order,10),3,'0')+'/'+
                  ExpStrL(Num2str(PRED(entries2),10),3,'0')+', '+
         'pattern '+ExpStrL(Num2str(current_pattern,10),3,'0')+', '+
         'row '+ExpStrL(Num2str(current_line,10),3,'0')+' '+
         '['+ExpStrL('',3,'0')+'%] '+
         '['+_timer_str+']'+' ';
end;

function _position_str2: String;
begin
  _position_str2 :=
    'Order '+ExpStrL(Num2str(current_order,10),3,'0')+'/'+
             ExpStrL(Num2str(PRED(entries2),10),3,'0')+', '+
    'pattern '+ExpStrL(Num2str(current_pattern,10),3,'0')+', '+
    'row '+ExpStrL(Num2str(current_line,10),3,'0')+' ';
end;

procedure toggle_picture_mode;

var
  index: Byte;

begin
  _debug_str_:= 'A2SCRIO.PAS:toggle_picture_mode';
  If NOT _picture_mode then
    begin
      fade_speed := 16;
      fade_buf.action := first;
      VgaFade(fade_buf,fadeOut,delayed);
      For index := 1 to 20 do WaitRetrace;
      asm mov ax,13h; int 10h end;

      For index := 1 to 20 do WaitRetrace;
      For index := 0 to 255 do
        SetRGBitem(index,tRGB_PALETTE(_ptr_picture_palette^)[index].r,
                         tRGB_PALETTE(_ptr_picture_palette^)[index].g,
                         tRGB_PALETTE(_ptr_picture_palette^)[index].b);

      fade_speed := 16;
      fade_buf.action := first;
      VgaFade(fade_buf2,fadeOut,fast);

      dosmemput($0a000,0,_ptr_picture_bitmap^,320*200);
      _picture_mode := NOT _picture_mode;
      wtext(_title_xpos,_title_ypos,'/´T2 PLAYER',_title_color);
      VgaFade(fade_buf2,fadeIn,delayed);
    end
  else begin
         _picture_mode := NOT _picture_mode;
         VgaFade(fade_buf2,fadeOut,delayed);
         asm
             mov   ax,03h
             xor   bh,bh
             int   10h
         end;
       end;
end;

procedure fade_out;

var
  temp: Byte;

begin
  _debug_str_:= 'A2SCRIO.PAS:fade_out';
  For temp := overall_volume downto 0 do
    begin
      set_overall_volume(temp);
      delay_counter := 0;
      While (delay_counter < overall_volume DIV 20) do
        begin
          If timer_200hz_flag then
            begin
              timer_200hz_flag := FALSE;
              Inc(delay_counter);
              C3Write(DietStr(_position_str+'',PRED(MaxCol)),$0f,0,0);
              wtext2(_timer_xpos,_timer_ypos,_timer_str,_timer_color);
              wtext(_progress_xpos,_progress_ypos,_progress_str,_progress_color);
              wtext(_pos_str_xpos,_pos_str_ypos,_position_str2+'',_pos_str_color);
              If timer_50hz_flag then
                begin
                  timer_50hz_flag := FALSE;
                  decay_bars_refresh;
                end;
            end;
          MEMW[0:$041c] := MEMW[0:$041a];
        end;
    end;
end;

end.
