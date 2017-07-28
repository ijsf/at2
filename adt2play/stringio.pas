unit StringIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

function byte2hex(value: Byte): String;
function byte2dec(value: Byte): String;
function Capitalize(str: String): String;
function Upper(str: String): String;
function Lower(str: String): String;
function ExpStrL(str: String; size: Byte; chr: Char): String;
function ExpStrR(str: String; size: Byte; chr: Char): String;
function DietStr(str: String; size: Byte): String;
function CutStr(str: String): String;
function FilterStr(str: String; chr0,chr1: Char): String;
function Num2str(num: Longint; base: Byte): String;
function Str2num(str: String; base: Byte): Longint;
function PathOnly(path: String): String;
function NameOnly(path: String): String;
function BaseNameOnly(path: String): String;
function ExtOnly(path: String): String;

implementation

uses
  DOS;

function byte2hex(value: Byte): String;

const
  data: array[0..15] of char = '0123456789ABCDEF';

begin
  asm
        mov     edi,@RESULT
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
  end;
end;

function byte2dec(value: Byte): String;

const
  data: array[0..9] of char = '0123456789';

begin
  asm
        mov     edi,@RESULT
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
  end;
end;

function Capitalize(str: String): String;
begin
  asm
        lea     esi,[str]
        mov     edi,@RESULT
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
  end;
end;

function Upper(str: String): String;
begin
  asm
        lea     esi,[str]
        mov     edi,@RESULT
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
  end;
end;

function Lower(str: String): String;
begin
  asm
        lea     esi,[str]
        mov     edi,@RESULT
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
  end;
end;

function ExpStrL(str: String; size: Byte; chr: Char): String;
begin
  asm
        lea     esi,[str]
        mov     edi,@RESULT
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
  end;
end;

function ExpStrR(str: String; size: Byte; chr: Char): String;
begin
  asm
        lea     esi,[str]
        mov     edi,@RESULT
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
  end;
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

function FilterStr(str: String; chr0,chr1: Char): String;
begin
  asm
        lea     esi,[str]
        mov     edi,@RESULT
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
  end;
end;

function Num2str(num: Longint; base: Byte): String;

const
  hexa: array[0..PRED(16)+32] of Char = '0123456789ABCDEF'+
                                        #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0;
begin
  asm
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
        mov     edi,@RESULT
        mov     al,cl
        stosb
@@2:    mov     al,byte ptr [hexa+esi+16]
        stosb
        inc     esi
        loop    @@2
        jmp     @@4
@@3:    mov     edi,@RESULT
        xor     al,al
        stosb
@@4:
  end;
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
  If (Pos('\',path) <> 0) then
    begin
      FSplit(path,dir,name,ext);
      NameOnly := name+ext;
    end
  else NameOnly := path;
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
  ExtOnly := Lower(ext);
end;

end.
