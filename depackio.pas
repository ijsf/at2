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

unit DepackIO;
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

implementation

const
  WORKMEM_SIZE = 64*1024;

var
  work_mem: array[0..PRED(WORKMEM_SIZE)] of Byte;
  ibufCount,ibufSize: Word;
  input_size,output_size: Word;
  input_ptr,output_ptr,work_ptr: pByte;

var
  ibuf_idx,ibuf_end,obuf_idx,obuf_src: pByte;
  ctrl_bits,ctrl_mask,
  command,count,offs: Word;

{$IFNDEF CPU64}
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
{$ELSE}
procedure RDC_decode;
begin
  ctrl_mask := 0;
  ibuf_idx := input_ptr;
  obuf_idx := output_ptr;
  ibuf_end := input_ptr+input_size;

  While (ibuf_idx < ibuf_end) do
    begin
      ctrl_mask := ctrl_mask SHR 1;
      If (ctrl_mask = 0) then
      begin
        ctrl_bits := pWord(ibuf_idx)^;
        Inc(ibuf_idx,2);
        ctrl_mask := $8000;
      end;

      If (ctrl_bits AND ctrl_mask = 0) then
        begin
          obuf_idx^ := ibuf_idx^;
          Inc(ibuf_idx);
          Inc(obuf_idx);
          CONTINUE;
        end;

      command := (ibuf_idx^ SHR 4) AND 15;
      count := ibuf_idx^ AND 15;
      Inc(ibuf_idx);

      Case command Of
        // short RLE
        0: begin
             Inc(count,3);
             FillChar(obuf_idx^,count,ibuf_idx^);
             Inc(ibuf_idx);
             Inc(obuf_idx,count);
           end;
        // long RLE
        1: begin
             Inc(count,ibuf_idx^ SHL 4);
             Inc(ibuf_idx);
             Inc(count,19);
             FillChar(obuf_idx^,count,ibuf_idx^);
             Inc(ibuf_idx);
             Inc(obuf_idx, count);
           end;
        // long pattern
        2: begin
             offs := count+3;
             Inc(offs,ibuf_idx^ SHL 4);
             Inc(ibuf_idx);
             count := ibuf_idx^;
             Inc(ibuf_idx);
             Inc(count,16);
             obuf_src := obuf_idx-offs;
             Move(obuf_src^,obuf_idx^,count);
             Inc(obuf_idx,count);
           end;
        // short pattern
        else begin
               offs := count+3;
               Inc(offs,ibuf_idx^ SHL 4);
               Inc(ibuf_idx);
               obuf_src := obuf_idx-offs;
               Move(obuf_src^,obuf_idx^,command);
               Inc(obuf_idx,command);
             end;
      end;
    end;

  output_size := obuf_idx-output_ptr;
end;
{$ENDIF}

function RDC_decompress(var source,dest; size: Word): Word;
begin
  input_ptr := @source;
  output_ptr := @dest;
  input_size := size;
  RDC_decode;
  RDC_decompress := output_size;
end;

const
  N_BITS = 12;
  F_BITS = 4;
  THRESHOLD = 2;
  N = 1 SHL N_BITS;
  F = (1 SHL F_BITS)+THRESHOLD;

{$IFNDEF CPU64}

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
        add     cl,THRESHOLD
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

{$ELSE}

procedure LZSS_decode;

label
  j1,j2,j3,j4,j5;

var
  al,cl,ch,cf: Byte;
  dx: Word;
  ebx,edi: Dword;

procedure GetChar;
begin
  If (ibufCount < ibufSize) then
    begin
      al := input_ptr[ibufCount];
      Inc(ibufCount);
      cf := 0;
    end
  else
    cf := 1;
end;

procedure PutChar;
begin
  output_ptr[output_size] := al;
  Inc(output_size);
end;

begin
    ibufCount := 0;                  //        mov     ibufCount,0
    ibufSize := input_size;          //        mov     ax,input_size
                                     //        mov     ibufSize,ax
    output_size := 0;                //        mov     output_size,0
    ebx := 0;                        //        xor     ebx,ebx
    dx := 0;                         //        xor     edx,edx
    edi := N-F;                      //        mov     edi,N-F
j1: dx := dx SHR 1;                  //@@1:    shr     dx,1
    If (dx SHR 8 <> 0) then          //        or      dh,dh
      GOTO j2;                       //        jnz     @@2
    GetChar;                         //        call    GetChar
    If (cf = 1) then GOTO j5;        //        jc      @@5
    dx := $ff00 OR al;               //        mov     dh,0ffh
                                     //        mov     dl,al
j2: If (dx AND 1 = 0) then           //@@2:    test    dx,1
      GOTO j3;                       //        jz      @@3
    GetChar;                         //        call    GetChar
    If (cf = 1) then GOTO j5;        //        jc      @@5
                                     //        push    esi
    work_ptr[edi] := al;             //        mov     esi,work_ptr
                                     //        add     esi,edi
                                     //        mov     byte ptr [esi],al
                                     //        pop     esi
    edi := (edi+1) AND (N-1);        //        inc     edi
                                     //        and     edi,N-1
    PutChar;                         //        caj    PutChar
    GOTO j1;                         //        jmp     @@1
j3: GetChar;                         //@@3:    caj    GetChar
    If (cf = 1) then GOTO j5;        //        jc      @@5
    ch := al;                        //        mov     ch,al
    GetChar;                         //        call    GetChar
    If (cf = 1) then GOTO j5;        //        jc      @@5
                                     //        mov     bh,al
                                     //        mov     cl,4
    ebx := (al SHL 4) AND $ff00;     //        shr     bh,cl
    ebx := ebx OR ch;                //        mov     bl,ch
                                     //        mov     cl,al
                                     //        and     cl,0fh
    cl := (al AND $0f)+THRESHOLD;    //        add     cl,THRESHOLD
    Inc(cl);                         //        inc     cl
j4: ebx := ebx AND (N-1);            //@@4:    and     ebx,N-1
                                     //        push    esi
    al := work_ptr[ebx];             //        mov     esi,work_ptr
                                     //        mov     al,byte ptr [esi+ebx]
                                     //        add     esi,edi
    work_ptr[edi] := al;             //        mov     byte ptr [esi],al
                                     //        pop     esi
    Inc(edi);                        //        inc     edi
    edi := edi AND (N-1);            //        and     edi,N-1
    PutChar;                         //        call    PutChar
    Inc(ebx);                        //        inc     ebx
    Dec(cl);                         //        dec     cl
    If (cl <> 0) then GOTO j4;       //        jnz     @@4
    GOTO j1;                         //        jmp     @@1
j5:                                  //@@5:
end;

{$ENDIF}

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
  le82a,le82b: Word;

const
  le7a: array[0..4] of Word = ($1ff,$3ff,$7ff,$0fff,$1fff);

{$IFNDEF CPU64}

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
        and     ax,le7a[ebx]
end;

procedure LZW_decode;
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
@@9:    mov     eax,edi
        sub     eax,output_ptr
        mov     output_size,ax
  end;
end;

{$ELSE}

var
  stack: array[WORD] of Byte;
  ax,bx,cx,sp: Word;
  edi,td: Dword;

procedure NextCode;

label j2;

begin
    bx := le82a;                    //        mov     bx,le82a
    ax := le82b;                    //        mov     ax,le82b
    td := (ax SHL 16)+bx;           //        add     bx,le78
    td := td + le78;                //        adc     ax,0
    le82a := td AND $ffff;          //        xchg    bx,le82a
    le82b := td SHR 16;             //        xchg    ax,le82b
    cx := bx AND 7;                 //        mov     cx,bx
    td := (ax SHL 16)+bx;           //        and     cx,7
    td := td SHR 1;                 //        shr     ax,1
                                    //        rcr     bx,1
    td := td SHR 1;                 //        shr     ax,1
                                    //        rcr     bx,1
    td := td SHR 1;                 //        shr     ax,1
    bx := td;                       //        rcr     bx,1
    td := input_ptr[bx]+            //        mov     esi,input_ptr
          (input_ptr[bx+1] shl 8)+  //        mov     ax,[ebx+esi]
          (input_ptr[bx+2] shl 16); //        mov     dl,[ebx+esi+2]
    If (cx = 0) then                //        or      cx,cx
      GOTO j2;                      //        jz      @@2
    While (cx <> 0) do
      begin                         //@@1:    shr     dl,1
        td := td SHR 1; Dec(cx);    //        rcr     ax,1
      end;                          //        loop    @@1
j2: bx := le78;                     //@@2:    mov     bx,le78
    Dec(bx,9);                      //        sub     bx,9
                                    //        shl     bx,1
    ax:=td AND le7a[bx];            //        and     ax,[ebx+le7a_0]
end;

procedure LZW_decode;

label
  j1,j2,j3,j4,j5,j7,j8,j9;

begin
    sp := PRED(SizeOf(stack));
    le72 := 0;                                 //        mov     le72,0
    le78 := 9;                                 //        mov     le78,9
    le70 := $102;                              //        mov     le70,102h
    le74 := $200;                              //        mov     le74,200h
    edi := 0;                                  //        mov     edi,output_ptr
    ax := 0;                                   //        xor     eax,eax
    le6a := 0;                                 //        mov     le6a,ax
    le6c := 0;                                 //        mov     le6c,ax
    le6e := 0;                                 //        mov     le6e,ax
    le76 := 0;                                 //        mov     le76,al
    le77 := 0;                                 //        mov     le77,al
    le82a := 0;                                //        mov     le82a,ax
    le82b := 0;                                //        mov     le82b,ax
j1: NextCode;                                  //@@1:    call    NextCode
    If (ax <> $101) then                       //        cmp     ax,101h
      GOTO j2;                                 //        jnz     @@2
    GOTO j9;                                   //        jmp     @@9
j2: If (ax <> $100) then                       //@@2:    cmp     ax,100h
      GOTO j3;                                 //        jnz     @@3
    le78 := 9;                                 //        mov     le78,9
    le74 := $200;                              //        mov     le74,200h
    le70 := $102;                              //        mov     le70,102h
    NextCode;                                  //        caj    NextCode
    le6a := ax;                                //        mov     le6a,ax
    le6c := ax;                                //        mov     le6c,ax
    le77 := ax;                                //        mov     le77,al
    le76 := ax;                                //        mov     le76,al
                                               //        mov     al,le77
    output_ptr[edi] := ax;                     //        mov     byte ptr [edi],al
    Inc(edi);                                  //        inc     edi
    GOTO j1;                                   //        jmp     @@1
j3: le6a := ax;                                //@@3:    mov     le6a,ax
    le6e := ax;                                //        mov     le6e,ax
    If (ax < le70) then                        //        cmp     ax,le70
      GOTO j4;                                 //        jb      @@4
    ax := le6c;                                //        mov     ax,le6c
    le6a := ax;                                //        mov     le6a,ax
    ax := (ax AND $ff00)+le76;                 //        mov     al,le76
    Dec(sp); stack[sp] := ax;                  //        push    eax
    Inc(le72);                                 //        inc     le72
j4: If (le6a <= $ff) then                      //@@4:    cmp     le6a,0ffh
      GOTO j5;                                 //        jbe     @@5
                                               //        mov     esi,work_ptr
                                               //        mov     bx,le6a
    bx := le6a*3;                              //        shl     bx,1
    ax := (ax AND $ff00)+work_ptr[bx+2];       //        add     bx,le6a
    Dec(sp);                                   //        mov     al,[ebx+esi+2]
    stack[sp] := ax;                           //        push    eax
    Inc(le72);                                 //        inc     le72
    ax := work_ptr[bx]+(work_ptr[bx+1] SHL 8); //        mov     ax,[ebx+esi]
    le6a := ax;                                //        mov     le6a,ax
    GOTO j4;                                   //        jmp     @@4
j5: ax := le6a;                                //@@5:    mov     ax,le6a
    le76 := ax;                                //        mov     le76,al
    le77 := ax;                                //        mov     le77,al
    Dec(sp); stack[sp] := ax;                  //        push    eax
    Inc(le72);                                 //        inc     le72
                                               //        xor     ecx,ecx
    cx := le72;                                //        mov     cx,le72
    If (cx = 0) then GOTO j7;                  //        jecxz   @@7
    While (cx <> 0) do                         //
      begin                                    //
        ax := stack[sp]; Inc(sp);              //@@6:    pop     eax
        output_ptr[edi] := ax;                 //        mov     byte ptr [edi],al
        Inc(edi); Dec(cx);                     //        inc     edi
      end;                                     //        loop    @@6
j7: le72 := 0;                                 //@@7:    mov     le72,0
                                               //        push    esi
                                               //        mov     bx,le70
                                               //        shl     bx,1
    bx:=le70*3;                                //        add     bx,le70
                                               //        mov     esi,work_ptr
                                               //        mov     al,le77
    work_ptr[bx+2] := le77;                    //        mov     [ebx+esi+2],al
    work_ptr[bx+1] := le6c SHR 8;              //        mov     ax,le6c
    work_ptr[bx+0] := le6c;                    //        mov     [ebx+esi],ax
    Inc(le70);                                 //        inc     le70
                                               //        pop     esi
    ax := le6e;                                //        mov     ax,le6e
    le6c := ax;                                //        mov     le6c,ax
    bx := le70;                                //        mov     bx,le70
    If (bx < le74) then                        //        cmp     bx,le74
      GOTO j8;                                 //        jl      @@8
    If (le78 = 14) then                        //        cmp     le78,14
      GOTO j8;                                 //        jz      @@8
    Inc(le78);                                 //        inc     le78
    le74 := le74 SHL 1;                        //        shl     le74,1
j8: GOTO j1;                                   //@@8:    jmp     @@1
j9: output_size := edi;                        //@@9:    mov     output_size,ax
end;

{$ENDIF}

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
  ibitCount,ibitBuffer,obufCount: Word;

{$IFNDEF CPU64}

var
  index: Word;

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

{$ELSE}

procedure InitTree;

var
  index: Word;

begin
  For index := 2 to TWICEMAX do
    begin
      dad[index] := index DIV 2;
      frq[index] := 1;
    end;

  For index := 1 to MAXCHAR do
    begin
      leftC[index] := 2*index;
      rghtC[index] := 2*index+1;
    end;
end;

procedure UpdateFreq(a,b: Word);
begin
  Repeat
    frq[dad[a]] := frq[a]+frq[b];
    a := dad[a];
    If (a <> ROOT) then
      If (leftC[dad[a]] = a) then b := rghtC[dad[a]]
      else b := leftC[dad[a]];
  until (a = ROOT);

  If (frq[ROOT] = MAXFREQ) then
    For a := 1 to TWICEMAX do frq[a] := frq[a] SHR 1;
end;

procedure UpdateModel(code: Word);

var
  a,b,c,
  code1,code2: Word;

begin
  a := code+SUCCMAX;
  Inc(frq[a]);

  If (dad[a] <> ROOT) then
    begin
      code1 := dad[a];
      If (leftC[code1] = a) then UpdateFreq(a,rghtC[code1])
      else UpdateFreq(a,leftC[code1]);

      Repeat
        code2 := dad[code1];
        If (leftC[code2] = code1) then b := rghtC[code2]
        else b := leftC[code2];

        If (frq[a] > frq[b]) then
          begin
            If (leftC[code2] = code1) then rghtC[code2] := a
            else leftC[code2] := a;

            If (leftC[code1] = a) then
              begin
                leftC[code1] := b;
                c := rghtC[code1];
              end
            else begin
                   rghtC[code1] := b;
                   c := leftC[code1];
                 end;

            dad[b] := code1;
            dad[a] := code2;
            UpdateFreq(b,c);
            a := b;
          end;

        a := dad[a];
        code1 := dad[a];
      until (code1 = ROOT);
    end;
end;

function InputCode(bits: Word): Word;

var
  index,code: Word;

begin
  code := 0;
  For index := 1 to bits do
    begin
      If (ibitCount = 0) then
        begin
          If (ibufCount = MAXBUF) then ibufCount := 0;
          ibitBuffer := pWord(input_ptr)[ibufCount];
          Inc(ibufCount);
          ibitCount := 15;
        end
      else Dec(ibitCount);

      If (ibitBuffer > $7fff) then code := code OR bitValue[index];
      ibitBuffer := ibitBuffer SHL 1;
    end;

  InputCode := code;
end;

function Uncompress: Word;

var
  a: Word;

begin
  a := 1;
  Repeat
    If (ibitCount = 0) then
      begin
        If (ibufCount = MAXBUF) then ibufCount := 0;
        ibitBuffer := pWord(input_ptr)[ibufCount];
        Inc(ibufCount);
        ibitCount := 15;
      end
    else Dec(ibitCount);

    If (ibitBuffer > $7fff) then a := rghtC[a]
    else a := leftC[a];
    ibitBuffer := ibitBuffer SHL 1;
  until (a > MAXCHAR);

  Dec(a,SUCCMAX);
  UpdateModel(a);
  Uncompress := a;
end;

procedure SIXPACK_decode;

var
  i,j,k,t,c,
  count,dist,len,index: Word;

begin
  count := 0;
  InitTree;
  c := Uncompress;

  While (c <> TERMINATE) do
    begin
      If (c < 256) then
        begin
          output_ptr[obufCount] := c;
          Inc(obufCount);
          If (obufCount = MAXBUF) then
            begin
              output_size := MAXBUF;
              obufCount := 0;
            end;

          work_ptr[count] := c;
          Inc(count);
          If (count = MAXSIZE) then count := 0;
        end
      else begin
             t := c-FIRSTCODE;
             index := t DIV CODESPERRANGE;
             len := t+MINCOPY-index*CODESPERRANGE;
             dist := InputCode(CopyBits[index])+len+CopyMin[index];

             j := count;
             k := count-dist;
             If (count < dist) then Inc(k,MAXSIZE);

             For i := 0 to PRED(len) do
               begin
                 output_ptr[obufCount] := work_ptr[k];
                 Inc(obufCount);
                 If (obufCount = MAXBUF) then
                   begin
                     output_size := MAXBUF;
                     obufCount := 0;
                   end;

                 work_ptr[j] := work_ptr[k];
                 Inc(j);
                 Inc(k);
                 If (j = MAXSIZE) then j := 0;
                 If (k = MAXSIZE) then k := 0;
               end;

             Inc(count,len);
             If (count >= MAXSIZE) then Dec(count,MAXSIZE);
           end;

      c := Uncompress;
    end;

  output_size := obufCount;
end;

{$ENDIF}

function SIXPACK_decompress(var source,dest; size: Word): Word;
begin
  input_ptr := @source;
  output_ptr := @dest;
  work_ptr := @work_mem;
  input_size := size;
  ibitCount  := 0;
  ibitBuffer := 0;
  obufCount  := 0;
  ibufCount  := 0;
  SIXPACK_decode;
  SIXPACK_decompress := output_size;
end;

{$IFNDEF CPU64}
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
{$ELSE}
function APACK_decompress(var source,dest): Dword;

var
  temp,res,swp,eax,ecx: Dword;
  tsi,esi,edi: pByte;
  ncf,cf,dl: Byte;

label
  j1,j2,j3,j4,j5,j6,j7,j8,j9,j10,j11,j12,j13,
  j14,j15,j16,j17,j18,j19,j20,j21,j22,j23,j24,j25;

begin
     esi := @source;                                  //       mov     esi,[source]
     edi := @dest;                                    //       mov     edi,[dest]
     temp := 0; res := 0;                             //       cld
     dl := $80;                                       //       mov     dl,80h
j1:  edi^ := esi^; Inc(esi); Inc(edi); Inc(res);      //@@1:   movsb
j2:  cf := dl SHR 7; dl := dl SHL 1;                  //@@2:   add     dl,dl
     If (dl <> 0) then GOTO j3;                       //       jnz     @@3
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl := (dl SHL 1)+cf; cf := ncf; //       adc     dl,dl
j3:  If (cf = 0) then GOTO j1;                        //@@3:   jnc     @@1
     ecx := 0;                                        //       xor     ecx,ecx
     cf := dl SHR 7; dl := dl SHL 1;                  //       add     dl,dl
     If (dl <> 0) then GOTO j4;                       //       jnz     @@4
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl := (dl SHL 1)+cf; cf := ncf; //       adc     dl,dl
j4:  If (cf =0 ) then GOTO j8;                        //@@4:   jnc     @@8
     eax := 0;                                        //       xor     eax,eax
     cf := dl SHR 7; dl := dl SHL 1;                  //       add     dl,dl
     If (dl <> 0) then GOTO j5;                       //       jnz     @@5
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl := (dl SHL 1)+cf; cf := ncf; //       adc     dl,dl
j5:  If (cf = 0) then GOTO j15;                       //@@5:   jnc     @@15
     Inc(ecx);                                        //       inc     ecx
     eax := $10;                                      //       mov     al,10h
j6:  cf := dl SHR 7; dl := (dl SHL 1);                //@@6:   add     dl,dl
     If (dl <> 0) then GOTO j7;                       //       jnz     @@7
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl:= (dl SHL 1)+cf; cf := ncf;  //       adc     dl,dl
j7:  ncf := (eax SHR 7) AND 1;
     eax := (eax AND $ffffff00)+BYTE((eax SHL 1)+cf);
     cf := ncf;                                       //@@7:   adc     al,al
     If (cf = 0) then GOTO j6;                        //       jnc     @@6
     If (eax <> 0) then GOTO j24;                     //       jnz     @@24
     edi^ := eax; Inc(edi); Inc(res);                 //       stosb
     GOTO j2;                                         //       jmp     @@2
j8:  Inc(ecx);                                        //@@8:   inc     ecx
j9:  cf := dl SHR 7; dl := dl SHL 1;                  //@@9:   add     dl,dl
     If (dl <> 0) then GOTO j10;                      //       jnz     @@10
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl := (dl SHL 1)+cf; cf := ncf; //       adc     dl,dl
j10: ecx := ecx+ecx+cf;                               //@@10:  adc     ecx,ecx
     cf := dl SHR 7; dl := dl SHL 1;                  //       add     dl,dl
     If (dl <> 0) then GOTO j11;                      //       jnz     @@11
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl := (dl SHL 1)+cf; cf := ncf; //       adc     dl,dl
j11: If (cf = 1) then GOTO j9;                        //@@11:  jc      @@9
     Dec(ecx);                                        //       dec     ecx
     Dec(ecx); If (ecx <> 0) then GOTO j16;           //       loop    @@16
     ecx := 0;                                        //       xor     ecx,ecx
     Inc(ecx);                                        //       inc     ecx
j12: cf := dl SHR 7; dl := dl SHL 1;                  //@@12:  add     dl,dl
     If (dl <> 0) then GOTO j13;                      //       jnz     @@13
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl := (dl SHL 1)+cf; cf := ncf; //       adc     dl,dl
j13: ecx := ecx+ecx+cf;                               //@@13:  adc     ecx,ecx
     cf := dl SHR 7; dl := dl SHL 1;                  //       add     dl,dl
     If (dl <> 0) then GOTO j14;                      //       jnz     @@14
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl := (dl SHL 1)+cf; cf := ncf; //       adc     dl,dl
j14: If (cf = 1) then GOTO j12;                       //@@14:  jc      @@12
     GOTO j23;                                        //       jmp     @@23
j15: eax := esi^; Inc(esi);                           //@@15:  lodsb
     cf := eax AND 1; eax := eax SHR 1;               //       shr     eax,1
     If (eax = 0) then GOTO j25;                      //       jz      @@25
     ecx := ecx+ecx+cf;                               //       adc     ecx,ecx
     GOTO j20;                                        //       jmp     @@20
j16: swp := eax; eax := ecx; ecx := swp;              //@@16:  xchg    eax,ecx
     Dec(eax);                                        //       dec     eax
     eax := (eax SHL 8)+esi^;                         //       shl     eax,8
     Inc(esi);                                        //       lodsb
     ecx := 0;                                        //       xor     ecx,ecx
     Inc(ecx);                                        //       inc     ecx
j17: cf := dl SHR 7; dl := dl SHL 1;                  //@@17:  add     dl,dl
     If (dl <> 0) then GOTO j18;                      //       jnz     @@18
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl := (dl SHL 1)+cf; cf := ncf; //       adc     dl,dl
j18: ecx := ecx+ecx+cf;                               //@@18:  adc     ecx,ecx
     cf := dl SHR 7; dl := dl SHL 1;                  //       add     dl,dl
     If (dl <> 0) then GOTO j19;                      //       jnz     @@19
     dl := esi^;                                      //       mov     dl,[esi]
     Inc(esi);                                        //       inc     esi
     ncf := dl SHR 7; dl := (dl SHL 1)+cf; cf := ncf; //       adc     dl,dl
j19: If (cf = 1) then GOTO j17;                       //@@19:  jc      @@17
     If (eax >= 32000) then                           //       cmp     eax,32000
       GOTO j20;                                      //       jae     @@20
     If (eax >= 1280) then                            //       cmp     ah,5
       GOTO j21;                                      //       jae     @@21
     If (eax > 127) then                              //       cmp     eax,7fh
       GOTO j22;                                      //       ja      @@22
j20: Inc(ecx);                                        //@@20:  inc     ecx
j21: Inc(ecx);                                        //@@21:  inc     ecx
j22: swp := temp; temp := eax; eax := swp;            //@@22:  xchg    eax,temp
j23: eax := temp;                                     //@@23:  mov     eax,temp
j24:                                                  //@@24:  push    esi
     tsi := edi;                                      //       mov     esi,edi
     Dec(tsi,eax);                                    //       sub     esi,eax
     While (ecx <> 0) do                              //
       begin                                          //
         edi^ := tsi^;                                //       rep     movsb
         Inc(tsi); Inc(edi); Inc(res);                //
         Dec(ecx);                                    //
       end;                                           //       pop     esi
     GOTO j2;                                         //       jmp     @@2
j25:                                                  //@@25:  sub     edi,[dest]
                                                      //       mov     result,edi
  APACK_decompress := res;
end;
{$ENDIF}

end.
