{
    Functions for operating with normal strings
}
unit StringIO;
{$PACKRECORDS 1}
interface

type
  characters = Set of Char;

function Capitalize(str: String): String;
function Upper(str: String): String;
function Lower(str: String): String;
function iCASE(str: String): String;
function RotStrL(str1,str2: String; shift: Byte): String;
function RotStrR(str1,str2: String; shift: Byte): String;
function ExpStrL(str: String; size: Byte; chr: Char): String;
function ExpStrR(str: String; size: Byte; chr: Char): String;
function DietStr(str: String; size: Byte): String;
function CutStr(str: String): String;
function FlipStr(str: String): String;
function FilterStr(str: String; chr0,chr1: Char): String;
function FilterStr2(str: String; chr0: characters; chr1: Char): String;
function Num2str(num: Longint; base: Byte): String;
function Str2num(str: String; base: Byte): Longint;
function SameName(str1,str2: String): Boolean;
function PathOnly(path: String): String;
function NameOnly(path: String): String;
function BaseNameOnly(path: String): String;
function ExtOnly(path: String): String;
function byte2hex(value: Byte): String;
function byte2dec(value: Byte): String;

implementation

uses
  DOS;

function Capitalize(str: String): String; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,@result { [@result] }
        mov     al,[esi]
        inc     esi
        mov     [edi],al
        inc     edi
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@4
        mov     al,[esi]
        inc     esi
        cmp     al,'a'
        jb      @@0
        cmp     al,'z'
        ja      @@0
        sub     al,20h
@@0:    mov     [edi],al
        inc     edi
@@1:    mov     ah,al
        mov     al,[esi]
        inc     esi
        cmp     ah,' '
        jnz     @@2
        cmp     al,'a'
        jb      @@2
        cmp     al,'z'
        ja      @@2
        sub     al,20h
        jmp     @@3
@@2:    cmp     al,'A'
        jb      @@3
        cmp     al,'Z'
        ja      @@3
        add     al,20h
@@3:    mov     [edi],al
        inc     edi
        loop    @@1
@@4:
        pop     edi
        pop     esi
        pop     ecx
end;

function Upper(str: String): String; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,@result
        mov     al,[esi]
        inc     esi
        mov     [edi],al
        inc     edi
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@3
@@1:    mov     al,[esi]
        inc     esi
        cmp     al,'a'
        jb      @@2
        cmp     al,'z'
        ja      @@2
        sub     al,20h
@@2:    mov     [edi],al
        inc     edi
        loop    @@1
@@3:
        pop     edi
        pop     esi
        pop     ecx
end;

function Lower(str: String): String; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,@result
        mov     al,[esi]
        inc     esi
        mov     [edi],al
        inc     edi
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@3
@@1:    mov     al,[esi]
        inc     esi
        cmp     al,'A'
        jb      @@2
        cmp     al,'Z'
        ja      @@2
        add     al,20h
@@2:    mov     [edi],al
        inc     edi
        loop    @@1
@@3:
        pop     edi
        pop     esi
        pop     ecx
end;

function iCase(str: String): String; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,@result
        mov     al,[esi]
        inc     esi
        mov     [edi],al
        inc     edi
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@5
        push    edi
        push    ecx
@@1:    mov     al,[esi]
        inc     esi
        cmp     al,'a'
        jb      @@2
        cmp     al,'z'
        ja      @@2
        sub     al,20h
@@2:    mov     [edi],al
        inc     edi
        loop    @@1
        pop     ecx
        pop     edi
@@3:    mov     al,[edi]
        cmp     al,'i'-20h
        jnz     @@4
        add     al,20h
@@4:    mov     [edi],al
        inc     edi
        loop    @@3
@@5:
        pop     edi
        pop     esi
        pop     ecx
end;

function RotStrL(str1,str2: String; shift: Byte): String;
begin
  RotStrL := Copy(str1,shift+1,Length(str1)-shift)+
             Copy(str2,1,shift);
end;

function RotStrR(str1,str2: String; shift: Byte): String;
begin
  RotStrR := Copy(str2,Length(str2)-shift+1,shift)+
             Copy(str1,1,Length(str1)-shift);
end;

function ExpStrL(str: String; size: Byte; chr: Char): String; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,@result
        cld
        xor     ecx,ecx
        lodsb
        cmp     al,size
        jge     @@1
        mov     ah,al
        mov     al,size
        stosb
        mov     al,ah
        mov     cl,size
        sub     cl,al
        mov     al,chr
        rep     stosb
        mov     cl,ah
        rep     movsb
        jmp     @@2
@@1:    stosb
        mov     cl,al
        rep     movsb
@@2:
        pop     edi
        pop     edi
        pop     ecx
end;

function ExpStrR(str: String; size: Byte; chr: Char): String; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,@result
        cld
        xor     ecx,ecx
        lodsb
        cmp     al,size
        jge     @@1
        mov     ah,al
        mov     al,size
        stosb
        mov     cl,ah
        rep     movsb
        mov     al,ah
        mov     cl,size
        sub     cl,al
        mov     al,chr
        rep     stosb
        jmp     @@2
@@1:    stosb
        mov     cl,al
        rep     movsb
@@2:
        pop     edi
        pop     edi
        pop     ecx
end;

function DietStr(str: String; size: Byte): String;
begin
  If (Length(str) <= size) then
    begin
      DietStr := str;
      EXIT;
    end;

  Repeat
    Delete(str,size DIV 2,1)
  until (Length(str)+3 = size);

  Insert('...',str,size DIV 2);
  DietStr := str
end;

function CutStr(str: String): String;
begin
  While (str[0] <> #0) and (str[1] in [#00,#32]) do Delete(str,1,1);
  While (str[0] <> #0) and (str[Length(str)] in [#00,#32]) do Delete(str,Length(str),1);
  CutStr := str;
end;

function FlipStr(str: String): String; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,@result
        mov     al,[esi]
        inc     esi
        mov     [edi],al
        inc     edi
        dec     edi
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@2
        add     edi,ecx
@@1:    mov     al,[esi]
        inc     esi
        mov     [edi],al
        dec     edi
        loop    @@1
@@2:
        pop     edi
        pop     edi
        pop     ecx
end;

function FilterStr(str: String; chr0,chr1: Char): String; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,[str]
        mov     edi,@result
        mov     al,[esi]
        inc     esi
        mov     [edi],al
        inc     edi
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@3
@@1:    mov     al,[esi]
        inc     esi
        cmp     al,chr0
        jnz     @@2
        mov     al,chr1
@@2:    mov     [edi],al
        inc     edi
        loop    @@1
@@3:
        pop     edi
        pop     edi
        pop     ecx
end;

const
  _treat_char: array[$80..$a5] of Char =
    'CueaaaaceeeiiiAAE_AooouuyOU_____aiounN';

function FilterStr2(str: String; chr0: characters; chr1: Char): String;

var
  temp: Byte;

begin
  For temp := 1 to Length(str) do
    If NOT (str[temp] in chr0) then
      If (str[temp] >= #$80) and (str[temp] <= #$a5) then
        str[temp] := _treat_char[BYTE(str[temp])]
      else If (str[temp] = #0) then str[temp] := ' '
           else str[temp] := chr1;
  FilterStr2 := str;
end;

function Num2str(num: Longint; base: Byte): String; assembler;

const
  hexa: array[0..PRED(16)+32] of Char = '0123456789ABCDEF'+
                                        #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        xor     eax,eax
        xor     edx,edx
        xor     edi,edi
        xor     esi,esi
        mov     eax,num
        xor     ebx,ebx
        mov     bl,base
        cmp     bl,2
        jb      @@3
        cmp     bl,16
        ja      @@3
        mov     edi,32
@@1:    dec     edi
        xor     edx,edx
        div     ebx
        mov     esi,edx
        mov     dl,byte ptr [hexa+esi]
        mov     byte ptr [hexa+edi+16],dl
        and     eax,eax
        jnz     @@1
        mov     esi,edi
        mov     ecx,32
        sub     ecx,edi
        mov     edi,@result
        mov     al,cl
        stosb
@@2:    mov     al,byte ptr [hexa+esi+16]
        stosb
        inc     esi
        loop    @@2
        jmp     @@4
@@3:    mov     edi,@result
        xor     al,al
        stosb
@@4:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

const
  digits: array[0..35] of Char = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

function Digit2index(digit: Char): Byte;

var
  index: Byte;

begin
  digit := UpCase(digit);
  index := 15;
  While (index > 0) and (digit <> digits[index]) do Dec(index);
  Digit2index := Index;
end;

function position_value(position,base: Byte): Longint;

var
  value: Longint;
  index: Byte;

begin
  value := 1;
  For index := 2 to position do value := value*base;
  position_value := value;
end;

function Str2num(str: String; base: Byte): Longint;

var
  value: Longint;
  index: Byte;

begin
  value := 0;
  For index := 1 to Length(str) do
    Inc(value,Digit2index(str[index])*
              position_value(Length(str)-index+1,base));
  Str2num := value;
end;

function SameName(str1,str2: String): Boolean; assembler;
const
  LastW: Word = 0;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     [LastW], 0 { FPC doesn't clean this up }
        xor     eax,eax
        xor     ecx,ecx
        xor     ebx,ebx
        mov     esi,[str1]
        mov     edi,[str2]
        xor     ah,ah
        mov     al,[esi]
        inc     esi
        mov     cx,ax
        mov     al,[edi]
        inc     edi
        mov     bx,ax
        or      cx,cx
        jnz     @@1
        or      bx,bx
        jz      @@13
        jmp     @@14
        xor     dh,dh
@@1:    mov     al,[esi]
        inc     esi
        cmp     al,'*'
        jne     @@2
        dec     cx
        jz      @@13
        mov     dh,1
        mov     LastW,cx
        jmp     @@1
@@2:    cmp     al,'?'
        jnz     @@3
        inc     edi
        or      bx,bx
        je      @@12
        dec     bx
        jmp     @@12
@@3:    or      bx,bx
        je      @@14
        cmp     al,'['
        jne     @@11
        cmp     word ptr [esi],']?'
        je      @@9
        mov     ah,byte ptr [edi]
        xor     dl,dl
        cmp     byte ptr [esi],'!'
        jnz     @@4
        inc     esi
        dec     cx
        jz      @@14
        inc     dx
@@4:    mov     al,[esi]
        inc     esi
        dec     cx
        jz      @@14
        cmp     al,']'
        je      @@7
        cmp     ah,al
        je      @@6
        cmp     byte ptr [esi],'-'
        jne     @@4
        inc     esi
        dec     cx
        jz      @@14
        cmp     ah,al
        jae     @@5
        inc     esi
        dec     cx
        jz      @@14
        jmp     @@4
@@5:    mov     al,[esi]
        inc     esi
        dec     cx
        jz      @@14
        cmp     ah,al
        ja      @@4
@@6:    or      dl,dl
        jnz     @@14
        inc     dx
@@7:    or      dl,dl
        jz      @@14
@@8:    cmp     al,']'
        je      @@10
@@9:    mov     al,[esi]
        inc     esi
        cmp     al,']'
        loopne  @@9
        jne     @@14
@@10:   dec     bx
        inc     edi
        jmp     @@12
@@11:   cmp     [edi],al
        jne     @@14
        inc     edi
        dec     bx
@@12:   xor     dh,dh
        dec     cx
        jnz     @@1
        or      bx,bx
        jnz     @@14
@@13:   mov     al,1
        jmp     @@16
@@14:   or      dh,dh
        jz      @@15
        jecxz   @@15
        or      bx,bx
        jz      @@15
        inc     edi
        dec     bx
        jz      @@15
        mov     ax,LastW
        sub     ax,cx
        add     cx,ax
        movsx   eax,ax { AAARGHHHH! I hunted for this 2 days! why it works with TMT? dunno... }
        sub     esi,eax
        dec     esi
        jmp     @@1
@@15:   mov     al,0
@@16:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

var
  dir:  DirStr;
  name: NameStr;
  ext:  ExtStr;

function PathOnly(path: String): String;
begin
  FSplit(path,dir,name,ext);
  PathOnly := dir;
end;

function NameOnly(path: String): String;
begin
  FSplit(path,dir,name,ext);
  NameOnly := name+ext;
end;

function BaseNameOnly(path: String): String;
begin
  FSplit(path,dir,name,ext);
  BaseNameOnly := name;
end;

function ExtOnly(path: String): String;
begin
  FSplit(path,dir,name,ext);
  Delete(ext,1,1);
  ExtOnly := ext;
end;

function byte2hex(value: Byte): String; assembler;
const
    data: array[0..15] of char = '0123456789ABCDEF';
asm
        push    ecx
        push    esi
        push    edi
        mov     edi,@result
        lea     ebx,[data]
        mov     al,2
        stosb
        mov     al,value
        xor     ah,ah
        mov     cl,16
        div     cl
        xlat
        stosb
        mov     al,ah
        xlat
        stosb
        pop     edi
        pop     esi
        pop     ecx
end;

function byte2dec(value: Byte): String; assembler;
const
    data: array[0..9] of char = '0123456789';
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     edi,@result
        lea     ebx,[data]
        mov     al,value
        xor     ah,ah
        mov     cl,100
        div     cl
        mov     ch,ah
        xchg    ah,al
        or      ah,ah
        jz      @@1
        mov     al,3
        stosb
        xchg    ah,al
        xlat
        stosb
        mov     al,ch
        jmp     @@2
@@1:    mov     al,2
        stosb
        mov     al,value
@@2:    xor     ah,ah
        mov     cl,10
        div     cl
        xlat
        stosb
        mov     al,ah
        xlat
        stosb
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

end.
