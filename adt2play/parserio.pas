unit ParserIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

function SensitiveScan(var buf; skip,size: Longint; str: String): Longint;
function Update16(var buf; size: Longint; crc: Word): Word;
function Update32(var buf; size: Longint; crc: Longint): Longint;

implementation

function SensitiveScan(var buf; skip,size: Longint; str: String): Longint;

var
  result: Longint;

begin
  asm
        mov     edi,[buf]
        add     edi,skip
        lea     esi,[str]
        mov     ecx,size
        sub     ecx,skip
        xor     eax,eax
        jecxz   @@3
        cld
        lodsb
        cmp     al,1
        jb      @@5
        ja      @@1
        lodsb
        repne   scasb
        jne     @@3
        jmp     @@5
@@1:    xor     ah,ah
        mov     ebx,eax
        dec     ebx
        mov     edx,ecx
        sub     edx,eax
        jb      @@3
        lodsb
        add     edx,2
@@2:    dec     edx
        mov     ecx,edx
        repne   scasb
        jne     @@3
        mov     edx,ecx
        mov     ecx,ebx
        rep     cmpsb
        je      @@4
        sub     ecx,ebx
        add     esi,ecx
        add     edi,ecx
        inc     edi
        or      edx,edx
        jne     @@2
@@3:    xor     eax,eax
        jmp     @@6
@@4:    sub     edi,ebx
@@5:    mov     eax,edi
        sub     eax,dword ptr [buf]
@@6:    dec     eax
        mov     result,eax
  end;
  SensitiveScan := result;
end;

var
  CRC16_table: array[BYTE] of Word;
  CRC32_table: array[BYTE] of Longint;

function Update16(var buf; size: Longint; crc: Word): Word;

var
  result: Word;

begin
  asm
        mov     esi,[buf]
        lea     edi,[CRC16_table]
        mov     bx,crc
        mov     ecx,size
        jecxz   @@2
@@1:    xor     ax,ax
        lodsb
        mov     dl,bh
        xor     dh,dh
        xor     bh,bh
        xor     bx,ax
        and     ebx,000000ffh
        shl     ebx,1
        mov     bx,[edi+ebx]
        xor     bx,dx
        loop    @@1
@@2:    mov     ax,bx
        mov     result,ax
  end;
  Update16 := result;
end;

function Update32(var buf; size: Longint; crc: Longint): Longint;

var
  result: Longint;

begin
  asm
        mov     esi,[buf]
        lea     edi,[CRC32_table]
        mov     ebx,crc
        mov     ecx,size
        jecxz   @@2
@@1:    xor     eax,eax
        lodsb
        xor     ebx,eax
        mov     edx,ebx
        and     ebx,000000ffh
        shl     ebx,2
        mov     ebx,[edi+ebx]
        shr     edx,8
        and     edx,00ffffffh
        xor     ebx,edx
        loop    @@1
@@2:    mov     eax,ebx
        mov     result,eax
  end;
  Update32 := result;
end;

procedure make_table_16bit;

var
  crc: Word;
  n,index: Byte;

begin
  For index := 0 to 255 do
  begin
    crc := index;
    For n := 1 to 8 do
      If Odd(crc) then crc := crc SHR 1 XOR $0a001
      else crc := crc SHR 1;
    CRC16_table[index] := crc;
  end;
end;

procedure make_table_32bit;

var
  crc: Dword;
  n,index: Byte;

begin
  For index := 0 to 255 do
    begin
      crc := index;
      For n := 1 to 8 do
        If Odd(crc) then crc := crc SHR 1 XOR $0edb88320
        else crc := crc SHR 1;
      CRC32_table[index] := crc;
    end;
end;

begin
  make_table_16bit;
  make_table_32bit;
end.
