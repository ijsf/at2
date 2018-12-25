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

unit A2depack;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

// Compression algorithm: RDC
// Algorithm developed by Ed Ross
function RDC_decompress(var source,dest; size: Word): Word;

// Compression algorithm: LZSS
// Algorithm developed by Lempel-Ziv-Storer-Szymanski
function LZSS_decompress(var source,dest; size: Word): Word;

// Compression algorithm: LZW
// Algorithm developed by Lempel-Ziv-Welch
function LZW_decompress(var source,dest): Word;

// Compression algorithm: SixPack
// Algorithm developed by Philip G. Gage
function SIXPACK_decompress(var source,dest; size: Word): Word;

// Compression algorithm: aPack
// Algorithm developed by Joergen Ibsen
function APACK_decompress(var source,dest): Dword;

// Compression algorithm: LZH
// Algorithm developed by Haruhiko Okomura & Haruyasu Yoshizaki
function LZH_decompress(var source,dest; size: Dword): Dword;

implementation

uses
  A2fileIO;

const
  WORKMEM_SIZE = 64*1024;

var
  work_mem: array[0..PRED(WORKMEM_SIZE)] of Byte;
  ibufCount,ibufSize: Word;
  input_size,output_size: Word;
  input_ptr,output_ptr,work_ptr: Pointer;

var
  ibuf_idx,ibuf_end,obuf_idx,obuf_src: Pointer;
  ctrl_bits,ctrl_mask,
  command,count,offs: Word;

procedure RDC_decode;
begin
  asm
        mov     ctrl_mask,0
        mov     eax,input_ptr
        mov     ibuf_end,eax
        xor     eax,eax
        mov     ax,input_size
        add     ibuf_end,eax
        mov     eax,input_ptr
        mov     ibuf_idx,eax
        mov     eax,output_ptr
        mov     obuf_idx,eax
@@1:    xor     ecx,ecx
        mov     eax,ibuf_idx
        cmp     eax,ibuf_end
        jnb     @@7
        mov     ax,ctrl_mask
        shr     ax,1
        mov     ctrl_mask,ax
        or      ax,ax
        jnz     @@2
        mov     esi,ibuf_idx
        lodsw
        mov     ctrl_bits,ax
        add     ibuf_idx,2
        mov     ctrl_mask,8000h
@@2:    mov     ax,ctrl_bits
        and     ax,ctrl_mask
        or      ax,ax
        jnz     @@3
        mov     esi,ibuf_idx
        mov     edi,obuf_idx
        movsb
        inc     ibuf_idx
        inc     obuf_idx
        jmp     @@1
@@3:    xor     ah,ah
        mov     esi,ibuf_idx
        lodsb
        shr     ax,4
        and     ax,0fh
        mov     command,ax
        xor     ah,ah
        mov     esi,ibuf_idx
        lodsb
        and     ax,0fh
        mov     count,ax
        inc     ibuf_idx
        cmp     command,0
        jnz     @@4
        add     count,3
        mov     edi,obuf_idx
        mov     cx,count
        mov     esi,ibuf_idx
        lodsb
        rep     stosb
        inc     ibuf_idx
        mov     cx,count
        add     obuf_idx,ecx
        jmp     @@1
@@4:    cmp     command,1
        jnz     @@5
        xor     ah,ah
        mov     esi,ibuf_idx
        lodsb
        shl     ax,4
        add     count,ax
        inc     ibuf_idx
        add     count,19
        mov     edi,obuf_idx
        mov     cx,count
        mov     esi,ibuf_idx
        lodsb
        rep     stosb
        inc     ibuf_idx
        mov     cx,count
        add     obuf_idx,ecx
        jmp     @@1
@@5:    cmp     command,2
        jnz     @@6
        mov     ax,count
        add     ax,3
        mov     offs,ax
        xor     ah,ah
        mov     esi,ibuf_idx
        lodsb
        shl     ax,4
        add     offs,ax
        inc     ibuf_idx
        xor     ah,ah
        mov     esi,ibuf_idx
        lodsb
        mov     count,ax
        inc     ibuf_idx
        add     count,16
        mov     eax,obuf_idx
        mov     cx,offs
        sub     eax,ecx
        mov     obuf_src,eax
        mov     esi,eax
        mov     edi,obuf_idx
        mov     cx,count
        rep     movsb
        mov     cx,count
        add     obuf_idx,ecx
        jmp     @@1
@@6:    mov     ax,count
        add     ax,3
        mov     offs,ax
        xor     ah,ah
        mov     esi,ibuf_idx
        lodsb
        shl     ax,4
        add     offs,ax
        inc     ibuf_idx
        mov     eax,obuf_idx
        mov     cx,offs
        sub     eax,ecx
        mov     obuf_src,eax
        mov     esi,eax
        mov     edi,obuf_idx
        mov     cx,command
        rep     movsb
        mov     cx,command
        add     obuf_idx,ecx
        jmp     @@1
@@7:    mov     eax,obuf_idx
        sub     eax,output_ptr
        mov     output_size,ax
  end;
end;

function RDC_decompress(var source,dest; size: Word): Word;
begin
  input_ptr := @source;
  output_ptr := @dest;
  input_size := size;
  RDC_decode;
  RDC_decompress := output_size;
end;

const
  N = 4096;
  F = 18;
  T = 2;

procedure GetChar; assembler;
asm
        push    ebx
        mov     bx,ibufCount
        cmp     bx,ibufSize
        jb      @@1
        jmp     @@2
@@1:    push    edi
        mov     edi,input_ptr
        mov     al,byte ptr [edi+ebx]
        pop     edi
        inc     ebx
        mov     ibufCount,bx
        pop     ebx
        clc
        jmp     @@3
@@2:    pop     ebx
        stc
@@3:
end;

procedure PutChar; assembler;
asm
        push    ebx
        mov     bx,output_size
        push    edi
        mov     edi,output_ptr
        mov     byte ptr [edi+ebx],al
        pop     edi
        inc     ebx
        mov     output_size,bx
        pop     ebx
end;

procedure LZSS_decode;
begin
  asm
        mov     ibufCount,0
        mov     ax,input_size
        mov     ibufSize,ax
        mov     output_size,0
        xor     ebx,ebx
        xor     edx,edx
        mov     edi,N-F
@@1:    shr     dx,1
        or      dh,dh
        jnz     @@2
        call    GetChar
        jc      @@5
        mov     dh,0ffh
        mov     dl,al
@@2:    test    dx,1
        jz      @@3
        call    GetChar
        jc      @@5
        push    esi
        mov     esi,work_ptr
        add     esi,edi
        mov     byte ptr [esi],al
        pop     esi
        inc     edi
        and     edi,N-1
        call    PutChar
        jmp     @@1
@@3:    call    GetChar
        jc      @@5
        mov     ch,al
        call    GetChar
        jc      @@5
        mov     bh,al
        mov     cl,4
        shr     bh,cl
        mov     bl,ch
        mov     cl,al
        and     cl,0fh
        add     cl,T
        inc     cl
@@4:    and     ebx,N-1
        push    esi
        mov     esi,work_ptr
        mov     al,byte ptr [esi+ebx]
        add     esi,edi
        mov     byte ptr [esi],al
        pop     esi
        inc     edi
        and     edi,N-1
        call    PutChar
        inc     ebx
        dec     cl
        jnz     @@4
        jmp     @@1
@@5:
  end;
end;

function LZSS_decompress(var source,dest; size: Word): Word;

begin
  input_ptr := @source;
  output_ptr := @dest;
  work_ptr := @work_mem;
  input_size := size;
  FillChar(work_ptr^,WORKMEM_SIZE,0);
  LZSS_decode;
  LZSS_decompress := output_size;
end;

var
  le76,le77: Byte;
  le6a,le6c,le6e,le70,le72,le74,le78,
  le7a_0,le7a_2,le7a_4,le7a_6,le7a_8,le82a,le82b: Word;

procedure NextCode; assembler;
asm
        mov     bx,le82a
        mov     ax,le82b
        add     bx,le78
        adc     ax,0
        xchg    bx,le82a
        xchg    ax,le82b
        mov     cx,bx
        and     cx,7
        shr     ax,1
        rcr     bx,1
        shr     ax,1
        rcr     bx,1
        shr     ax,1
        rcr     bx,1
        mov     esi,input_ptr
        mov     ax,[ebx+esi]
        mov     dl,[ebx+esi+2]
        or      cx,cx
        jz      @@2
@@1:    shr     dl,1
        rcr     ax,1
        loop    @@1
@@2:    mov     bx,le78
        sub     bx,9
        shl     bx,1
        and     ax,[ebx+le7a_0]
end;

function LZW_decode: Word;

var
  result: Word;

begin
  asm
        xor     eax,eax
        xor     ebx,ebx
        xor     ecx,ecx
        mov     le72,0
        mov     le78,9
        mov     le70,102h
        mov     le74,200h
        mov     edi,output_ptr
        xor     eax,eax
        mov     le6a,ax
        mov     le6c,ax
        mov     le6e,ax
        mov     le76,al
        mov     le77,al
        mov     le82a,ax
        mov     le82b,ax
        mov     le7a_0,1ffh
        mov     le7a_2,3ffh
        mov     le7a_4,7ffh
        mov     le7a_6,0fffh
        mov     le7a_8,1fffh
@@1:    call    NextCode
        cmp     ax,101h
        jnz     @@2
        jmp     @@9
@@2:    cmp     ax,100h
        jnz     @@3
        mov     le78,9
        mov     le74,200h
        mov     le70,102h
        call    NextCode
        mov     le6a,ax
        mov     le6c,ax
        mov     le77,al
        mov     le76,al
        mov     al,le77
        mov     byte ptr [edi],al
        inc     edi
        jmp     @@1
@@3:    mov     le6a,ax
        mov     le6e,ax
        cmp     ax,le70
        jb      @@4
        mov     ax,le6c
        mov     le6a,ax
        mov     al,le76
        push    eax
        inc     le72
@@4:    cmp     le6a,0ffh
        jbe     @@5
        mov     esi,work_ptr
        mov     bx,le6a
        shl     bx,1
        add     bx,le6a
        mov     al,[ebx+esi+2]
        push    eax
        inc     le72
        mov     ax,[ebx+esi]
        mov     le6a,ax
        jmp     @@4
@@5:    mov     ax,le6a
        mov     le76,al
        mov     le77,al
        push    eax
        inc     le72
        xor     ecx,ecx
        mov     cx,le72
        jecxz   @@7
@@6:    pop     eax
        mov     byte ptr [edi],al
        inc     edi
        loop    @@6
@@7:    mov     le72,0
        push    esi
        mov     bx,le70
        shl     bx,1
        add     bx,le70
        mov     esi,work_ptr
        mov     al,le77
        mov     [ebx+esi+2],al
        mov     ax,le6c
        mov     [ebx+esi],ax
        inc     le70
        pop     esi
        mov     ax,le6e
        mov     le6c,ax
        mov     bx,le70
        cmp     bx,le74
        jl      @@8
        cmp     le78,14
        jz      @@8
        inc     le78
        shl     le74,1
@@8:    jmp     @@1
@@9:    mov     output_size,ax
        mov     result,ax
  end;
  LZW_decode := result;
end;

function LZW_decompress(var source,dest): Word;
begin
  input_ptr := @source;
  output_ptr := @dest;
  work_ptr := @work_mem;
  LZW_decode;
  LZW_decompress := output_size;
end;

const
  MAXFREQ       = 2000;
  MINCOPY       = 3;
  MAXCOPY       = 255;
  COPYRANGES    = 6;
  TERMINATE     = 256;
  FIRSTCODE     = 257;
  ROOT          = 1;
  CODESPERRANGE = MAXCOPY-MINCOPY+1;
  MAXCHAR       = FIRSTCODE+COPYRANGES*CODESPERRANGE-1;
  SUCCMAX       = MAXCHAR+1;
  TWICEMAX      = 2*MAXCHAR+1;
  MAXBUF        = PRED(64*1024);
  MAXDISTANCE   = 21389;
  MAXSIZE       = 21389+MAXCOPY;

const
  BitValue: array[1..14] of Word = (1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192);
  CopyBits: array[0..PRED(COPYRANGES)] of Word = (4,6,8,10,12,14);
  CopyMin:  array[0..PRED(COPYRANGES)] of Word = (0,16,80,336,1360,5456);

var
  leftC,rghtC: array[0..MAXCHAR] of Word;
  dad,frq: array[0..TWICEMAX] of Word;
  index,ibitCount,ibitBuffer,obufCount: Word;

procedure InitTree;
begin
  asm
        xor     edi,edi
        mov     di,2
        mov     bx,2
        mov     cx,1
@@1:    xor     dx,dx
        mov     ax,di
        div     bx
        push    edi
        shl     di,1
        mov     word ptr dad[edi],ax
        mov     word ptr frq[edi],cx
        pop     edi
        inc     di
        cmp     di,TWICEMAX
        jbe     @@1
        mov     di,1
@@2:    xor     dx,dx
        mov     ax,di
        mul     bx
        push    edi
        shl     di,1
        mov     word ptr leftC[edi],ax
        inc     ax
        mov     word ptr rghtC[edi],ax
        pop     edi
        inc     di
        cmp     di,MAXCHAR
        jbe     @@2
  end;
end;

procedure UpdateFreq(a,b: Word);
begin
  asm
        xor     ecx,ecx
        xor     edi,edi
@@1:    mov     di,a
        shl     di,1
        mov     bx,word ptr frq[edi]
        mov     di,b
        shl     di,1
        add     bx,word ptr frq[edi]
        mov     di,a
        shl     di,1
        mov     dx,word ptr dad[edi]
        mov     di,dx
        shl     di,1
        mov     word ptr frq[edi],bx
        mov     a,dx
        cmp     a,ROOT
        jz      @@3
        mov     di,a
        shl     di,1
        mov     di,word ptr dad[edi]
        mov     ax,di
        shl     di,1
        mov     bx,word ptr leftC[edi]
        cmp     a,bx
        jnz     @@2
        mov     di,ax
        shl     di,1
        mov     bx,word ptr rghtC[edi]
        mov     b,bx
        jmp     @@3
@@2:    mov     di,ax
        shl     di,1
        mov     bx,word ptr leftC[edi]
        mov     b,bx
@@3:    cmp     a,ROOT
        jnz     @@1
        mov     bx,MAXFREQ
        mov     di,ROOT
        shl     di,1
        cmp     word ptr frq[edi],bx
        jnz     @@5
        lea     esi,[frq]
        lea     edi,[frq]
        mov     cx,TWICEMAX
        movsw
@@4:    lodsw
        shr     ax,1
        stosw
        loop    @@4
@@5:
  end;
end;

procedure UpdateModel(code: Word);
begin
  asm
        xor     ecx,ecx
        xor     edi,edi
        mov     bx,code
        add     bx,SUCCMAX
        mov     di,bx
        shl     di,1
        mov     ax,di
        mov     cx,word ptr frq[edi]
        inc     cx
        mov     word ptr frq[edi],cx
        mov     di,ax
        mov     cx,ROOT
        cmp     word ptr dad[edi],cx
        jz      @@10
        mov     dx,word ptr dad[edi]
        push    edi
        lea     edi,[leftC]
        mov     cx,dx
        shl     cx,1
        add     edi,ecx
        mov     si,word ptr [edi]
        pop     edi
        cmp     si,bx
        jnz     @@1
        mov     di,dx
        shl     di,1
        mov     si,word ptr rghtC[edi]
@@1:    push    ebx
        push    edx
        push    ebx
        push    esi
        call    UpdateFreq
        pop     edx
        pop     ebx
@@2:    xor     edi,edi
        mov     di,dx
        shl     di,1
        mov     ax,word ptr dad[edi]
        mov     di,ax
        shl     di,1
        mov     cx,di
        cmp     word ptr leftC[edi],dx
        jnz     @@3
        mov     di,cx
        mov     si,word ptr rghtC[edi]
        jmp     @@4
@@3:    mov     si,word ptr leftC[edi]
@@4:    xor     edi,edi
        mov     di,bx
        shl     di,1
        push    eax
        mov     ax,word ptr frq[edi]
        mov     di,si
        shl     di,1
        mov     cx,ax
        pop     eax
        cmp     cx,word ptr frq[edi]
        jbe     @@9
        mov     di,ax
        shl     di,1
        mov     cx,di
        cmp     word ptr leftC[edi],dx
        jnz     @@5
        mov     di,cx
        mov     word ptr rghtC[edi],bx
        jmp     @@6
@@5:    xor     edi,edi
        mov     di,cx
        mov     word ptr leftC[edi],bx
@@6:    lea     edi,[leftC]
        xor     ecx,ecx
        mov     cx,dx
        shl     cx,1
        add     edi,ecx
        cmp     word ptr [edi],bx
        jnz     @@7
        mov     word ptr [edi],si
        xor     edi,edi
        mov     di,cx
        mov     cx,word ptr rghtC[edi]
        jmp     @@8
@@7:    xor     edi,edi
        mov     di,cx
        mov     word ptr rghtC[edi],si
        mov     cx,word ptr leftC[edi]
@@8:    xor     edi,edi
        mov     di,si
        shl     di,1
        mov     word ptr dad[edi],dx
        mov     di,bx
        shl     di,1
        mov     word ptr dad[edi],ax
        push    esi
        push    esi
        push    ecx
        call    UpdateFreq
        pop     ebx
@@9:    xor     edi,edi
        mov     di,bx
        shl     di,1
        mov     bx,word ptr dad[edi]
        mov     di,bx
        shl     di,1
        mov     dx,word ptr dad[edi]
        cmp     dx,ROOT
        jnz     @@2
@@10:
  end;
end;

function InputCode(bits: Word): Word;

var
  result: Word;

begin
  asm
        xor     bx,bx
        xor     ecx,ecx
        mov     cx,1
@@1:    cmp     ibitCount,0
        jnz     @@3
        cmp     ibufCount,MAXBUF
        jnz     @@2
        mov     ax,input_size
        mov     ibufCount,0
@@2:    mov     edi,input_ptr
        xor     edx,edx
        mov     dx,ibufCount
        shl     dx,1
        add     edi,edx
        mov     ax,[edi]
        mov     ibitBuffer,ax
        inc     ibufCount
        mov     ibitCount,15
        jmp     @@4
@@3:    dec     ibitCount
@@4:    cmp     ibitBuffer,7fffh
        jbe     @@5
        xor     edi,edi
        mov     di,cx
        dec     di
        shl     di,1
        mov     ax,word ptr BitValue[edi]
        or      bx,ax
@@5:    shl     ibitBuffer,1
        inc     cx
        cmp     cx,bits
        jbe     @@1
        mov     ax,bx
        mov     result,ax
  end;
  InputCode := result;
end;

function Uncompress: Word;

var
  result: Word;

begin
  asm
        xor     eax,eax
        xor     ebx,ebx
        mov     bx,1
        mov     dx,ibitCount
        mov     cx,ibitBuffer
        mov     ax,ibufCount
@@1:    or      dx,dx
        jnz     @@3
        cmp     ax,MAXBUF
        jnz     @@2
        mov     ax,input_size
        xor     ax,ax
@@2:    shl     ax,1
        mov     edi,input_ptr
        add     edi,eax
        shr     ax,1
        mov     cx,[edi]
        inc     ax
        mov     dx,15
        jmp     @@4
@@3:    dec     dx
@@4:    cmp     cx,7fffh
        jbe     @@5
        mov     edi,ebx
        shl     edi,1
        mov     bx,word ptr rghtC[edi]
        jmp     @@6
@@5:    mov     edi,ebx
        shl     edi,1
        mov     bx,word ptr leftC[edi]
@@6:    shl     cx,1
        cmp     bx,MAXCHAR
        jle     @@1
        sub     bx,SUCCMAX
        mov     ibitCount,dx
        mov     ibitBuffer,cx
        mov     ibufCount,ax
        push    ebx
        push    ebx
        call    UpdateModel
        pop     eax
        mov     result,ax
  end;
  Uncompress := result;
end;

procedure SIXPACK_decode;
begin
  asm
        mov     ibitCount,0
        mov     ibitBuffer,0
        mov     obufCount,0
        mov     ibufCount,0
        xor     ebx,ebx
        xor     ecx,ecx
        mov     count,0
        call    InitTree
        call    Uncompress
@@1:    cmp     ax,TERMINATE
        jz      @@10
        cmp     ax,256
        jae     @@3
        mov     edi,output_ptr
        push    ebx
        mov     bx,obufCount
        add     edi,ebx
        pop     ebx
        stosb
        inc     obufCount
        mov     bx,MAXBUF
        cmp     obufCount,bx
        jnz     @@2
        mov     output_size,bx
        mov     obufCount,0
@@2:    mov     edi,work_ptr
        push    ebx
        mov     bx,count
        add     edi,ebx
        pop     ebx
        stosb
        inc     count
        cmp     count,MAXSIZE
        jnz     @@9
        mov     count,0
        jmp     @@9
@@3:    sub     ax,FIRSTCODE
        mov     cx,ax
        xor     dx,dx
        mov     bx,CODESPERRANGE
        div     bx
        mov     index,ax
        xor     dx,dx
        mul     bx
        mov     bx,cx
        add     bx,MINCOPY
        sub     bx,ax
        mov     si,bx
        xor     edi,edi
        mov     di,index
        shl     di,1
        mov     bx,word ptr CopyBits[edi]
        push    ebx
        call    InputCode
        add     ax,si
        xor     edi,edi
        mov     di,index
        shl     di,1
        add     ax,word ptr CopyMin[edi]
        mov     bx,count
        mov     dx,bx
        sub     dx,ax
        mov     cx,dx
        cmp     count,ax
        jae     @@4
        add     cx,MAXSIZE
@@4:    xor     dx,dx
@@5:    mov     edi,work_ptr
        add     edi,ecx
        mov     al,byte ptr [edi]
        mov     edi,output_ptr
        push    ebx
        mov     bx,obufCount
        add     edi,ebx
        pop     ebx
        mov     byte ptr [edi],al
        inc     obufCount
        mov     ax,MAXBUF
        cmp     obufCount,ax
        jnz     @@6
        mov     output_size,ax
        mov     obufCount,0
@@6:    mov     edi,work_ptr
        push    edi
        add     edi,ecx
        mov     al,byte ptr [edi]
        pop     edi
        add     edi,ebx
        mov     byte ptr [edi],al
        inc     bx
        cmp     bx,MAXSIZE
        jnz     @@7
        xor     bx,bx
@@7:    inc     cx
        cmp     cx,MAXSIZE
        jnz     @@8
        xor     cx,cx
@@8:    inc     dx
        cmp     dx,si
        jb      @@5
        mov     ax,si
        add     count,ax
        cmp     count,MAXSIZE
        jb      @@9
        sub     count,MAXSIZE
@@9:    call    Uncompress
        jmp     @@1
@@10:   mov     bx,obufCount
        mov     output_size,bx
  end;
end;

function SIXPACK_decompress(var source,dest; size: Word): Word;
begin
  input_ptr := @source;
  output_ptr := @dest;
  work_ptr := @work_mem;
  input_size := size;
  SIXPACK_decode;
  SIXPACK_decompress := output_size;
end;

function APACK_decompress(var source,dest): Dword;

var
  temp,result: Dword;

begin
  asm
        mov     esi,[source]
        mov     edi,[dest]
        cld
        mov     dl,80h
@@1:    movsb
@@2:    add     dl,dl
        jnz     @@3
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@3:    jnc     @@1
        xor     ecx,ecx
        add     dl,dl
        jnz     @@4
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@4:    jnc     @@8
        xor     eax,eax
        add     dl,dl
        jnz     @@5
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@5:    jnc     @@15
        inc     ecx
        mov     al,10h
@@6:    add     dl,dl
        jnz     @@7
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@7:    adc     al,al
        jnc     @@6
        jnz     @@24
        stosb
        jmp     @@2
@@8:    inc     ecx
@@9:    add     dl,dl
        jnz     @@10
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@10:   adc     ecx,ecx
        add     dl,dl
        jnz     @@11
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@11:   jc      @@9
        dec     ecx
        loop    @@16
        xor     ecx,ecx
        inc     ecx
@@12:   add     dl,dl
        jnz     @@13
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@13:   adc     ecx,ecx
        add     dl,dl
        jnz     @@14
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@14:   jc      @@12
        jmp     @@23
@@15:   lodsb
        shr     eax,1
        jz      @@25
        adc     ecx,ecx
        jmp     @@20
@@16:   xchg    eax,ecx
        dec     eax
        shl     eax,8
        lodsb
        xor     ecx,ecx
        inc     ecx
@@17:   add     dl,dl
        jnz     @@18
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@18:   adc     ecx,ecx
        add     dl,dl
        jnz     @@19
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
@@19:   jc      @@17
        cmp     eax,32000
        jae     @@20
        cmp     ah,5
        jae     @@21
        cmp     eax,7fh
        ja      @@22
@@20:   inc     ecx
@@21:   inc     ecx
@@22:   xchg    eax,temp
@@23:   mov     eax,temp
@@24:   push    esi
        mov     esi,edi
        sub     esi,eax
        rep     movsb
        pop     esi
        jmp     @@2
@@25:   sub     edi,[dest]
        mov     result,edi
  end;
  APACK_decompress := result;
end;

const
  { DEFAULT COMPRESSION: dictionary 8kb }
  DIC_SIZE_DEF = 1 SHL 13;
  { ULTRA COMPRESSION: dictionary 16kb }
  DIC_SIZE_MAX = 1 SHL 14;

const
  MATCH_BIT = 8;
  MAX_MATCH = 1 SHL MATCH_BIT;
  THRESHOLD = 2;
  PBIT = 14;
  TBIT = 15;
  CBIT = 16;
  DIC_BIT = 14;
  CODE_BIT = 16;
  NC = 255 + MAX_MATCH + 2 - THRESHOLD;
  NP = DIC_BIT + 1;
  NT = CODE_BIT + 3;
  MAX_HASH_VAL = 3 * (1 SHL DIC_BIT) + ((1 SHL DIC_BIT) SHR 9 + 1) * 255;
  PERC_FLAG = 32768;

const
  DIC_SIZE: Word = DIC_SIZE_DEF;

type
  pWORD = ^tWORD;
  tWORD = array[0..PRED((1 SHL DIC_BIT))] of Integer;
  pBYTE = ^tBYTE;
  tBYTE = array[0..PRED(2*(1 SHL DIC_BIT))] of Byte;

var
  l_tree,r_tree: array[0..2*(NC-1)] of Word;
  p_table: array[0..255] of Word;
  p_len: array[0..PRED(NT)] of Byte;
  c_table: array[0..4095] of Word;
  c_len: array[0..PRED(NC)] of Byte;

var
  dec_counter: Integer;
  bit_buf,sbit_buf,bit_count,block_size,dec_ptr: Word;
  input_buffer,output_buffer: pGENERIC_IO_BUFFER;
  input_buffer_idx,output_buffer_idx: Dword;
  size_unpacked,input_buffer_size: Dword;

function ReadDataBlock(ptr: Pointer; size: Word): Word;

var
  result: Word;

begin
  If (input_buffer_size-input_buffer_idx >= size) then
    result := size
  else result := input_buffer_size-input_buffer_idx;
  Move(input_buffer^[input_buffer_idx],ptr^,result);
  Inc(input_buffer_idx,result);
  ReadDataBlock := result;
end;

procedure WriteDataBlock(ptr: Pointer; size: Word);
begin
  Move(ptr^,output_buffer^[output_buffer_idx],size);
  Inc(output_buffer_idx,size);
end;

procedure FillBitBuffer(bits: Integer);
begin
  bit_buf := (bit_buf SHL bits);
  While (bits > bit_count) do
    begin
      Dec(bits,bit_count);
      bit_buf := bit_buf OR (sbit_buf SHL bits);
      If (input_buffer_idx <= input_buffer_size) then
        begin
          sbit_buf := input_buffer^[input_buffer_idx];
          Inc(input_buffer_idx);
        end
      else sbit_buf := 0;
      bit_count := 8;
    end;
  Dec(bit_count,bits);
  bit_buf := bit_buf OR (sbit_buf SHR bit_count);
end;

function GetBits(bits: Integer): Word;
begin
  GetBits := bit_buf SHR (16-bits);
  FillBitBuffer(bits);
end;

procedure PutBits(bits: Integer; xbits: Word);
begin
  If (bits < bit_count) then
    begin
      Dec(bit_count,bits);
      sbit_buf := sbit_buf OR (xbits SHL bit_count);
    end
  else begin
         Dec(bits,bit_count);
         output_buffer^[output_buffer_idx] := sbit_buf OR (xbits SHR bits);
         Inc(output_buffer_idx);
         If (bits < 8) then
           begin
             bit_count := 8-bits;
             sbit_buf := xbits SHL bit_count;
           end
         else begin
                output_buffer^[output_buffer_idx] := xbits SHR (bits-8);
                Inc(output_buffer_idx);
                bit_count := 16-bits;
                sbit_buf := xbits SHL bit_count;
              end;
       end;
end;

procedure MakeTable(n_char: Integer;
                    bit_len: pBYTE;
                    bits: Integer;
                    table: pWORD);
var
  count,weight: array[1..16] of Word;
  start: array[1..17] of Word;
  idx,idx2,len,chr,j_bits,avail,next_c,mask: Integer;
  ptr: pWORD;

begin
  FillChar(count,SizeOf(count),0);
  FillChar(weight,SizeOf(weight),0);
  FillChar(start,SizeOf(start),0);

  For idx := 0 to PRED(n_char) do
    Inc(count[bit_len^[idx]]);
  start[1] := 0;
  For idx := 1 to 16 do
    start[SUCC(idx)] := start[idx]+(count[idx] SHL (16-idx));
  j_bits := 16-bits;
  For idx := 1 to bits do
    begin
      start[idx] := start[idx] SHR j_bits;
      weight[idx] := 1 SHL (bits-idx);
    end;
  idx := SUCC(bits);
  While (idx <= 16) do
    begin
      weight[idx] := 1 SHL (16-idx);
      Inc(idx);
    end;
  idx := start[SUCC(bits)] SHR j_bits;
  If (idx <> 0) then
    begin
      idx2 := 1 SHL bits;
      If (idx <> idx2) then
        begin
          FillWord(table^[idx],idx2-idx,0);
          idx := idx2;
        end;
    end;
  avail := n_char;
  mask := 1 SHL (15-bits);
  For chr := 0 to PRED(n_char) do
    begin
      len := bit_len^[chr];
      If (len = 0) then
        CONTINUE;
      idx2 := start[len];
      next_c := idx2+weight[len];
      If (len <= bits) then
        For idx := idx2 to PRED(next_c) do
          table^[idx] := chr
       else begin
              ptr := Addr(table^[WORD(idx2) SHR j_bits]);
              idx := len-bits;
              While (idx <> 0) do
                begin
                  If (ptr^[0] = 0) then
                    begin
                      r_tree[avail] := 0;
                      l_tree[avail] := 0;
                      ptr^[0] := avail;
                      Inc(avail);
                    end;
                  If (idx2 AND mask <> 0) then
                    ptr := Addr(r_tree[ptr^[0]])
                  else ptr := Addr(l_tree[ptr^[0]]);
                  idx2 := idx2 SHL 1;
                  Dec(idx);
                end;
              ptr^[0] := chr;
            end;
      start[len] := next_c;
    end;
end;

procedure ReadPtrLen(n_char,n_bit,i_bit: Integer);

var
  idx,chr,bits: Integer;
  mask: Word;

begin
  bits := GetBits(n_bit);
  If (bits = 0) then
    begin
      chr := GetBits(n_bit);
      FillChar(p_len,SizeOf(p_len),0);
      FillWord(p_table,SizeOf(p_table) DIV 2,chr);
    end
  else begin
         idx := 0;
         While (idx < bits) do
           begin
             chr := bit_buf SHR (16-3);
             If (chr = 7) then
               begin
                 mask := 1 SHL (16-4);
                 While (mask AND bit_buf <> 0) do
                   begin
                     mask := mask SHR 1;
                     Inc(chr);
                   end;
               end;
             If (chr < 7) then
               FillBitBuffer(3)
             else FillBitBuffer(chr-3);
             p_len[idx] := chr;
             Inc(idx);
             If (idx = i_bit) then
               begin
                 chr := PRED(GetBits(2));
                 While (chr >= 0) do
                   begin
                     p_len[idx] := 0;
                     Inc(idx);
                     Dec(chr);
                   end;
               end;
           end;
         If (idx < n_char) then
           begin
             FillWord(p_len[idx],n_char-idx,0);
             idx := n_char;
           end;
         MakeTable(n_char,@p_len,8,@p_table);
       end;
end;

procedure ReadCharLen;

var
  idx,chr,bits: Integer;
  mask: Word;

begin
  bits := GetBits(CBIT);
  If (bits = 0) then
    begin
      chr := GetBits(CBIT);
      FillChar(c_len,SizeOf(c_len),0);
      FillWord(c_table,SizeOf(c_table) DIV 2,chr);
    end
  else begin
         idx := 0;
         While (idx < bits) do
           begin
             chr := p_table[bit_buf SHR (16-8)];
             If (chr >= NT) then
               begin
                 mask := 1 SHL (16-9);
                 Repeat
                   If (bit_buf AND mask <> 0) then
                     chr := r_tree[chr]
                   else chr := l_tree[chr];
                   mask := mask SHR 1;
                 until (chr < NT);
               end;
             FillBitBuffer(p_len[chr]);
             If (chr <= 2) then
               begin
                 If (chr = 1) then
                   chr := 2+GetBits(4)
                 else If (chr = 2) then
                        chr := 19+GetBits(CBIT);
                 While (chr >= 0) do
                   begin
                     c_len[idx] := 0;
                     Inc(idx);
                     Dec(chr);
                   end;
               end
             else begin
                    c_len[idx] := chr-2;
                    Inc(idx);
                  end;
           end;
         While (idx < NC) do
           begin
             c_len[idx] := 0;
             Inc(idx);
           end;
         MakeTable(NC,@c_len,12,@c_table);
       end;
end;

function DecodeChar: Word;

var
  chr,mask: Word;

begin
  If (block_size = 0) then
    begin
      block_size := GetBits(16);
      ReadPtrLen(NT,TBIT,3);
      ReadCharLen;
      ReadPtrLen(NP,PBIT,-1);
    end;
  Dec(block_size);
  chr := c_table[bit_buf SHR (16-12)];
  If (chr >= NC) then
    begin
      mask := 1 SHL (16-13);
      Repeat
        If (bit_buf AND mask <> 0) then
          chr := r_tree[chr]
        else chr := l_tree[chr];
        mask := mask SHR 1;
      until (chr < NC);
    end;
  FillBitBuffer(c_len[chr]);
  DecodeChar := chr;
end;

function DecodePtr: Word;

var
  ptr,mask: Word;

begin
  ptr := p_table[bit_buf SHR (16-8)];
  If (ptr >= NP) then
    begin
      mask := 1 SHL (16-9);
      Repeat
        If (bit_buf AND mask <> 0) then
          ptr := r_tree[ptr]
        else ptr := l_tree[ptr];
        mask := mask SHR 1;
      until (ptr < NP);
    end;
  FillBitBuffer(p_len[ptr]);
  If (ptr <> 0) then
    begin
      Dec(ptr);
      ptr := (1 SHL ptr)+GetBits(ptr);
    end;
  DecodePtr := ptr;
end;

procedure DecodeBuffer(count: Word; buffer: pBYTE);

var
  idx,idx2: Word;

begin
  idx2 := 0;
  Dec(dec_counter);
  While (dec_counter >= 0) do
    begin
      buffer^[idx2] := buffer^[dec_ptr];
      dec_ptr := SUCC(dec_ptr) AND PRED(DIC_SIZE);
      Inc(idx2);
      If (idx2 = count) then
        EXIT;
      Dec(dec_counter);
    end;
  Repeat
    idx := DecodeChar;
    If (idx <= 255) then
      begin
        buffer^[idx2] := idx;
        Inc(idx2);
        If (idx2 = count) then
          EXIT;
      end
    else begin
           dec_counter := idx-(256-THRESHOLD);
           dec_ptr := (idx2-DecodePtr-1) AND PRED(DIC_SIZE);
           Dec(dec_counter);
           While (dec_counter >= 0) do
             begin
               buffer^[idx2] := buffer^[dec_ptr];
               dec_ptr := SUCC(dec_ptr) AND PRED(DIC_SIZE);
               Inc(idx2);
               If (idx2 = count) then
                 EXIT;
               Dec(dec_counter);
             end;
         end;
  until FALSE;
end;

function LZH_decompress(var source,dest; size: Dword): Dword;

var
  ptr: pBYTE;
  size_temp: Dword;
  ultra_compression_flag: Boolean;

begin
  LZH_decompress := 0;
  input_buffer := Addr(source);
  input_buffer_idx := 0;
  ultra_compression_flag := BOOLEAN(input_buffer^[input_buffer_idx]);
  Inc(input_buffer_idx);
  input_buffer_size := size;
  output_buffer := Addr(dest);
  output_buffer_idx := 0;
  Move(input_buffer^[input_buffer_idx],size_unpacked,SizeOf(size_unpacked));
  Inc(input_buffer_idx,SizeOf(size_unpacked));
  size := size_unpacked;

  If ultra_compression_flag then DIC_SIZE := DIC_SIZE_MAX
  else DIC_SIZE := DIC_SIZE_DEF;

  GetMem(ptr,DIC_SIZE);
  bit_buf := 0;
  sbit_buf := 0;
  bit_count := 0;
  FillBitBuffer(16);
  block_size := 0;
  dec_counter := 0;

  While (size > 0) do
    begin
      If (size > DIC_SIZE) then
        size_temp := DIC_SIZE
      else size_temp := size;
      DecodeBuffer(size_temp,ptr);
      WriteDataBlock(ptr,size_temp);
      Dec(size,size_temp);
    end;

  FreeMem(ptr,DIC_SIZE);
  LZH_decompress := size_unpacked;
end;

end.
