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

unit AdT2pack;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

function LZH_compress(var source,dest; size: Dword): Dword;
function LZH_compress_ultra(var source,dest; size: Dword): Dword;
function LZH_decompress(var source,dest; size: Dword): Dword;

implementation

uses
  AdT2sys,AdT2extn,AdT2unit;

const
  { DEFAULT COMPRESSION: buffer 4k, dictionary 8kb }
  WIN_SIZE_DEF = 1 SHL 12;
  DIC_SIZE_DEF = 1 SHL 13;
  { ULTRA COMPRESSION: buffer 32k, dictionary 16kb }
  WIN_SIZE_MAX = 1 SHL 15;
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
  WIN_SIZE: Word = WIN_SIZE_DEF;
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
  heap: array[0..NC] of Word;
  len_count: array[0..16] of Word;
  c_freq: array[0..2*(NC-1)] of Word;
  p_freq: array[0..2*(NP-1)] of Word;
  t_freq: array[0..2*(NT-1)] of Word;
  c_code: array[0..PRED(NC)] of Word;
  p_code: array[0..PRED(NT)] of Word;

var
  freq,sort_ptr,pos_ptr: pWORD;
  buf,len,stream,child_count,level: pBYTE;
  parent,previous,next: pWORD;
  bits,heap_size,remain,
  dec_counter,match_len: Integer;
  bit_buf,sbit_buf,bit_count,
  block_size,depth,c_pos,pos,out_pos,
  match_pos,dec_ptr,out_mask,avail: Word;
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
  If NOT really_no_status_refresh then
    show_progress(input_buffer_idx,3);
end;

procedure WriteDataBlock(ptr: Pointer; size: Word);
begin
  Move(ptr^,output_buffer^[output_buffer_idx],size);
  Inc(output_buffer_idx,size);
  If NOT really_no_status_refresh then
    show_progress(output_buffer_idx,3);
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
  progress_old_value := BYTE_NULL;
  progress_value := size;

  If ultra_compression_flag then
    begin
      WIN_SIZE := WIN_SIZE_MAX;
      DIC_SIZE := DIC_SIZE_MAX;
    end
  else begin
         WIN_SIZE := WIN_SIZE_DEF;
         DIC_SIZE := DIC_SIZE_DEF;
       end;

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

procedure CountLen(idx: Integer);
begin
  If (idx < bits) then
    If (depth < 16) then
      Inc(len_count[depth])
    else Inc(len_count[16])
  else begin
         Inc(depth);
         CountLen(l_tree[idx]);
         CountLen(r_tree[idx]);
         Dec(depth);
       end;
end;

procedure MakeLen(root: Integer);

var
  idx,idx2: Integer;
  sum: Word;

begin
  FillChar(len_count,SizeOf(len_count),0);
  CountLen(root);
  sum := 0;
  For idx := 16 downto 1 do
    Inc(sum,len_count[idx] SHL (16-idx));
  While (sum <> 0) do
    begin
      Dec(len_count[16]);
      For idx := 15 downto 1 do
        If (len_count[idx] <> 0) then
          begin
            Dec(len_count[idx]);
            Inc(len_count[SUCC(idx)],2);
            BREAK;
          end;
      Dec(sum);
    end;
  For idx := 16 downto 1 do
    begin
      idx2 := PRED(len_count[idx]);
      While (idx2 >= 0) do
        begin
          Dec(idx2);
          len^[sort_ptr^[0]] := idx;
          sort_ptr := Addr(sort_ptr^[1]);
        end;
    end;
end;

procedure DownHeap(idx: Integer);

var
  idx2,idx3: Integer;

begin
  idx2 := heap[idx];
  idx3 := idx SHL 1;
  While (idx3 <= heap_size) do
    begin
      If (idx3 < heap_size) and
         (freq^[heap[idx3]] > freq^[heap[SUCC(idx3)]]) then
        Inc(idx3);
      If (freq^[idx2] <= freq^[heap[idx3]]) then
        BREAK;
      heap[idx] := heap[idx3];
      idx := idx3;
      idx3 := idx SHL 1;
    end;
  heap[idx] := idx2;
end;

procedure MakeCode(bits: Integer; len: pBYTE; code: pWORD);

var
  idx,idx2: Integer;
  start: array[0..17] of Word;

begin
  start[1] := 0;
  For idx := 1 to 16 do
    start[SUCC(idx)] := (start[idx]+len_count[idx]) SHL 1;
  For idx := 0 to PRED(bits) do
    begin
      idx2 := len^[idx];
      code^[idx] := start[idx2];
      Inc(start[idx2]);
    end;
end;

function MakeTree(n_par: Integer;
                  f_par: pWORD;
                  l_par: pBYTE;
                  c_par: pWORD): Integer;
var
  idx,idx2,idx3,avail: Integer;

begin
  bits := n_par;
  freq := f_par;
  len := l_par;
  avail := bits;
  heap_size := 0;
  heap[1] := 0;

  For idx := 0 to PRED(bits) do
    begin
      len^[idx] := 0;
      If (freq^[idx] <> 0) then
        begin
          Inc(heap_size);
          heap[heap_size] := idx;
        end;
    end;

  If (heap_size < 2) then
    begin
      c_par^[heap[1]] := 0;
      MakeTree := heap[1];
      EXIT;
    end;

  For idx := (heap_size DIV 2) downto 1 do
    DownHeap(idx);
  sort_ptr := c_par;
  Repeat
    idx := heap[1];
    If (idx < bits) then
      begin
        sort_ptr^[0] := idx;
        sort_ptr := Addr(sort_ptr^[1]);
      end;
    heap[1] := heap[heap_size];
    Dec(heap_size);
    DownHeap(1);
    idx3 := heap[1];
    If (idx3 < bits) then
      begin
        sort_ptr^[0] := idx3;
        sort_ptr := Addr(sort_ptr^[1]);
      end;
    idx2 := avail;
    Inc(avail);
    freq^[idx2] := freq^[idx]+freq^[idx3];
    heap[1] := idx2;
    DownHeap(1);
    l_tree[idx2] := idx;
    r_tree[idx2] := idx3;
  until (heap_size <= 1);

  sort_ptr := c_par;
  MakeLen(idx2);
  MakeCode(n_par,l_par,c_par);
  MakeTree := idx2;
end;

procedure CountFreq;

var
  idx,idx2,bits,count: Integer;

begin
  For idx := 0 to PRED(NT) do
    t_freq[idx] := 0;
  bits := NC;
  While (bits > 0) and
        (c_len[PRED(bits)] = 0) do
    Dec(bits);
  idx := 0;
  While (idx < bits) do
    begin
      idx2 := c_len[idx];
      Inc(idx);
      If (idx2 = 0) then
        begin
          count := 1;
          While (idx < bits) and
                (c_len[idx] = 0) do
            begin
              Inc(idx);
              Inc(count);
            end;
          If (count <= 2) then
            Inc(t_freq[0],count)
          else If (count <= 18) then
                 Inc(t_freq[1])
                else If (count = 19) then
                       begin
                         Inc(t_freq[0]);
                         Inc(t_freq[1]);
                       end
                     else Inc(t_freq[2]);
        end
      else Inc(t_freq[idx2+2]);
    end;
end;

procedure WritePtrLen(bits,n_bit,s_bit: Integer);

var
  idx,idx2: Integer;

begin
  While (bits > 0) and
        (p_len[PRED(bits)] = 0) do
    Dec(bits);
  PutBits(n_bit,bits);
  idx := 0;
  While (idx < bits) do
    begin
      idx2 := p_len[idx];
      Inc(idx);
      If (idx2 <= 6) then
        PutBits(3,idx2)
      else begin
             Dec(idx2,3);
             PutBits(idx2,(1 SHL idx2)-2);
           end;
      If (idx = s_bit) then
        begin
          While (idx < 6) and
                (p_len[idx] = 0) do
            Inc(idx);
          PutBits(2,(idx-3) AND 3);
        end;
    end;
end;

procedure WriteCharLen;

var
  idx,idx2,bits,count: Integer;

begin
  bits := NC;
  While (bits > 0) and
        (c_len[PRED(bits)] = 0) do
    Dec(bits);
  PutBits(CBIT,bits);
  idx := 0;
  While (idx < bits) do
    begin
      idx2 := c_len[idx];
      Inc(idx);
      If (idx2 = 0) then
        begin
          count := 1;
          While (idx < bits) and
                (c_len[idx] = 0) do
            begin
              Inc(idx);
              Inc(count);
            end;
          If (count <= 2) then
            For idx2 := 0 to PRED(count) do
              PutBits(p_len[0],p_code[0])
          else If (count <= 18) then
                 begin
                   PutBits(p_len[1],p_code[1]);
                   PutBits(4,Count-3);
                 end
               else If (count = 19) then
                      begin
                        PutBits(p_len[0],p_code[0]);
                        PutBits(p_len[1],p_code[1]);
                        PutBits(4,15);
                      end
                    else begin
                           PutBits(p_len[2],p_code[2]);
                           PutBits(CBIT,count-20);
                         end;
        end
      else PutBits(p_len[idx2+2],p_code[idx2+2]);
    end;
end;

procedure EncodePtr(ptr: Word);

var
  idx,idx2: Word;

begin
  idx := 0;
  idx2 := ptr;
  While (idx2 <> 0) do
    begin
      idx2 := idx2 SHR 1;
      Inc(idx);
    end;
  PutBits(p_len[idx],p_code[idx]);
  If (idx > 1) then
    PutBits(PRED(idx),ptr AND (PRED(1 SHL 16) SHR (17-idx)));
end;

procedure SendBlock;

var
  idx,idx2,flags,
  root,pos,size: Word;

begin
  root := MakeTree(NC,@c_freq,@c_len,@c_code);
  Size := c_freq[root];
  PutBits(16,size);
  If (root >= NC) then
    begin
      CountFreq;
      root := MakeTree(NT,@t_freq,@p_len,@p_code);
      If (root >= NT) then
        WritePtrLen(NT,TBIT,3)
      else begin
             PutBits(TBIT,0);
             PutBits(TBIT,root);
           end;
      WriteCharLen;
    end
  else begin
         PutBits(TBIT,0);
         PutBits(TBIT,0);
         PutBits(CBIT,0);
         PutBits(CBIT,root);
       end;
  root := MakeTree(NP,@p_freq,@p_len,@p_code);
  If (root >= NP) then
    WritePtrLen(NP,PBIT,-1)
  else begin
         PutBits(PBIT,0);
         PutBits(PBIT,root);
       end;
  pos := 0;
  For idx := 0 to PRED(size) do
    begin
      If (idx AND 7 = 0) then
        begin
          flags := buf^[pos];
          Inc(pos);
        end
      else flags:=flags SHL 1;
      If (flags AND (1 SHL 7) <> 0) then
        begin
          idx2 := buf^[pos]+(1 SHL 8);
          Inc(pos);
          PutBits(c_len[idx2],c_code[idx2]);
          idx2 := buf^[pos] SHL 8;
          Inc(pos);
          Inc(idx2,buf^[pos]);
          Inc(pos);
          EncodePtr(idx2);
        end
      else begin
             idx2 := buf^[pos];
             Inc(pos);
             PutBits(c_len[idx2],c_code[idx2]);
           end;
    end;
  For idx := 0 to PRED(NC) do
    c_freq[idx] := 0;
  For idx := 0 to PRED(NP) do
    p_freq[idx] := 0;
end;

procedure Output(code,c_ptr: Word);
begin
  out_mask := out_mask SHR 1;
  If (out_mask = 0) then
    begin
      out_mask := 1 SHL 7;
      If (out_pos >= WIN_SIZE-24) then
        begin
          SendBlock;
          out_pos := 0;
        end;
      c_pos := out_pos;
      Inc(out_pos);
      buf^[c_pos] := 0;
    end;
  buf^[out_pos] := code;
  Inc(out_pos);
  Inc(c_freq[code]);
  If (code >= 1 SHL 8) then
    begin
      buf^[c_pos] := buf^[c_pos] OR out_mask;
      buf^[out_pos] := c_ptr SHR 8;
      Inc(out_pos);
      buf^[out_pos] := c_ptr;
      Inc(out_pos);
      code := 0;
      While (c_ptr <> 0) do
        begin
          c_ptr := c_ptr SHR 1;
          Inc(code);
        end;
      Inc(p_freq[code]);
    end;
end;

procedure InitSlide;

var
  idx: Word;

begin
  For idx := DIC_SIZE to (DIC_SIZE+255) do
    begin
      level^[idx] := 1;
      pos_ptr^[idx] := 0;
    end;
  For idx := DIC_SIZE to PRED(2*DIC_SIZE) do
    parent^[idx] := 0;
  avail := 1;
  For idx := 1 to DIC_SIZE-2 do
    next^[idx] := SUCC(idx);
  next^[PRED(DIC_SIZE)] := 0;
  For idx := (2*DIC_SIZE) to MAX_HASH_VAL do
    next^[idx] := 0;
end;

function Child(pnode: Integer; chr: Byte): Integer;

var
  node: Integer;

begin
  node := next^[pnode+(chr SHL (DIC_BIT-9))+2*DIC_SIZE];
  parent^[0] := pnode;
  While (parent^[node] <> pnode) do
    node := next^[node];
  Child := node;
end;

procedure MakeChild(p_node: Integer;
                    chr: Byte;
                    c_node: Integer);
var
  idx,idx2: Integer;

begin
  idx := p_node+(chr SHL (DIC_BIT-9))+2*DIC_SIZE;
  idx2 := next^[idx];
  next^[idx] := c_node;
  next^[c_node] := idx2;
  previous^[idx2] := c_node;
  previous^[c_node] := idx;
  parent^[c_node] := p_node;
  Inc(child_count^[p_node]);
end;

procedure SplitTree(old: Integer);

var
  new,idx: Integer;

begin
  new := avail;
  avail := next^[new];
  child_count^[new] := 0;
  idx := previous^[old];
  previous^[new] := idx;
  next^[idx] := new;
  idx := next^[old];
  next^[new] := idx;
  previous^[idx] := new;
  parent^[new] := parent^[old];
  level^[new] := match_len;
  pos_ptr^[new] := pos;
  MakeChild(new,stream^[match_pos+match_len],old);
  MakeChild(new,stream^[pos+match_len],pos);
end;

procedure InsertNode;

var
  idx,idx2,idx3,idx4: Integer;
  chr: Byte;
  ptr1,ptr2: pCHAR;

begin
  If (match_len >= 4) then
    begin
      Dec(match_len);
      idx2 := SUCC(match_pos) OR DIC_SIZE;
      idx := parent^[idx2];
      While (idx = 0) do
        begin
          idx2 := next^[idx2];
          idx := parent^[idx2];
        end;
      While (level^[idx] >= match_len) do
        begin
          idx2 := idx;
          idx :=parent^[idx];
        end;
      idx4 := idx;
      While (pos_ptr^[idx4] < 0) do
        begin
          pos_ptr^[idx4] := pos;
          idx4 := parent^[idx4];
        end;
      If (idx4 < DIC_SIZE) then
        pos_ptr^[idx4] := pos OR PERC_FLAG;
    end
  else begin
         idx := stream^[pos]+DIC_SIZE;
         chr := stream^[SUCC(pos)];
         idx2 := Child(idx,chr);
         If (idx2 = 0) then
           begin
             MakeChild(idx,chr,pos);
             match_len := 1;
             EXIT;
           end;
         match_len := 2;
       end;

  Repeat
    If (idx2 >= DIC_SIZE) then
      begin
        idx3 := MAX_MATCH;
        match_pos := idx2;
      end
    else begin
           idx3 := level^[idx2];
           match_pos := pos_ptr^[idx2] AND NOT (1 SHL 15);
         end;
    If (match_pos >= pos) then
      Dec(match_pos,DIC_SIZE);
    ptr1 := Addr(stream^[pos+match_len]);
    ptr2 := Addr(stream^[match_pos+match_len]);
    While (match_len < idx3) do
      begin
        If (ptr1^ <> ptr2^) then
          begin
            SplitTree(idx2);
            EXIT;
          end;
        Inc(match_len);
        Inc(ptr1);
        Inc(ptr2);
      end;
    If (match_len >= MAX_MATCH) then
      BREAK;
    pos_ptr^[idx2] := pos;
    idx := idx2;
    idx2 := Child(idx,ORD(ptr1^));
    If (idx2 = 0) then
      begin
        MakeChild(idx,ORD(ptr1^),pos);
         EXIT;
      end;
    Inc(match_len);
  until FALSE;

  idx4 := previous^[idx2];
  previous^[pos] := idx4;
  next^[idx4] := pos;
  idx4 := next^[idx2];
  next^[pos] := idx4;
  previous^[idx4] := pos;
  parent^[pos] := idx;
  parent^[idx2] := 0;
  next^[idx2] := pos;
end;

procedure DeleteNode;

var
  idx,idx2,idx3,idx4: Integer;
  perc_idx: Integer;

begin
  If (parent^[pos] = 0) then
    EXIT;
  idx := previous^[pos];
  idx2 := next^[pos];
  next^[idx] := idx2;
  previous^[idx2] := idx;
  idx := parent^[pos];
  parent^[pos] := 0;

  Dec(child_count^[idx]);
  If (idx >= DIC_SIZE) or
     (child_count^[idx] > 1) then
    EXIT;
  idx3 := pos_ptr^[idx] AND NOT PERC_FLAG;
  If (idx3 >= pos) then
    Dec(idx3,DIC_SIZE);

  idx2 := idx3;
  perc_idx := parent^[idx];
  idx4 := pos_ptr^[perc_idx];
  While (idx4 AND PERC_FLAG <> 0) do
    begin
      idx4 := idx4 AND NOT PERC_FLAG;
      If (idx4 >= pos) then
      Dec(idx4,DIC_SIZE);
      If (idx4 > idx2) then
        idx2 := idx4;
      pos_ptr^[perc_idx] := idx2 OR DIC_SIZE;
      perc_idx := parent^[perc_idx];
      idx4 := pos_ptr^[perc_idx];
    end;
  If (perc_idx < DIC_SIZE) then
    begin
      If (idx4 >= pos) then
        Dec(idx4,DIC_SIZE);
      If (idx4 > idx2) then
        idx2 := idx4;
      pos_ptr^[perc_idx] := idx2 OR DIC_SIZE OR PERC_FLAG;
    end;

  idx2 := Child(idx,stream^[idx3+level^[idx]]);
  idx3 := previous^[idx2];
  idx4 := next^[idx2];
  next^[idx3] := idx4;
  previous^[idx4] := idx3;
  idx3 := previous^[idx];
  next^[idx3] := idx2;
  previous^[idx2] := idx3;
  idx3 := next^[idx];
  previous^[idx3] := idx2;
  next^[idx2] := idx3;
  parent^[idx2] := parent^[idx];
  parent^[idx] := 0;
  next^[idx] := avail;
  avail := idx;
end;

procedure GetNextMatch;

var
  bits: Integer;

begin
  Dec(remain);
  Inc(pos);
  If (pos = 2*DIC_SIZE) then
    begin
      Move(stream^[DIC_SIZE],stream^[0],DIC_SIZE+MAX_MATCH);
      bits := ReadDataBlock(Addr(stream^[DIC_SIZE+MAX_MATCH]),DIC_SIZE);
      Inc(remain,bits);
      pos := DIC_SIZE;
    end;
  DeleteNode;
  InsertNode;
end;

function LZH_compress(var source,dest; size: Dword): Dword;

var
  last_match_len,last_match_pos: Integer;

begin
  LZH_compress := 0;
  input_buffer := Addr(source);
  input_buffer_idx := 0;
  input_buffer_size := size;
  output_buffer := Addr(dest);
  output_buffer_idx := 0;
  output_buffer^[input_buffer_idx] := 0; // set 'default' compression flag
  Inc(output_buffer_idx);
  Move(size,output_buffer^[output_buffer_idx],SizeOf(size));
  Inc(output_buffer_idx,SizeOf(size));
  progress_old_value := BYTE_NULL;
  progress_value := size;

  WIN_SIZE := WIN_SIZE_DEF;
  DIC_SIZE := DIC_SIZE_DEF;
  GetMem(stream,2*DIC_SIZE+MAX_MATCH);
  GetMem(level,DIC_SIZE+256);
  GetMem(child_count,DIC_SIZE+256);
  GetMem(pos_ptr,(DIC_SIZE+256) SHL 1);
  GetMem(parent,(DIC_SIZE*2) SHL 1);
  GetMem(previous,(DIC_SIZE*2) SHL 1);
  GetMem(next,(MAX_HASH_VAL+1) SHL 1);

  depth := 0;
  InitSlide;
  GetMem(buf,WIN_SIZE);
  buf^[0] := 0;
  FillChar(c_freq,SizeOf(c_freq),0);
  FillChar(p_freq,SizeOf(p_freq),0);
  out_pos := 0;
  out_mask := 0;
  bit_count := 8;
  sbit_buf := 0;
  remain := ReadDataBlock(Addr(stream^[DIC_SIZE]),DIC_SIZE+MAX_MATCH);
  match_len := 0;
  pos := DIC_SIZE;
  InsertNode;
  If (match_len > remain) then
    match_len := remain;

  While (remain > 0) do
    begin
      last_match_len := match_len;
      last_match_pos := match_pos;
      GetNextMatch;
      If (match_len > remain) then
        match_len := remain;
      If (match_len > last_match_len) or
         (last_match_len < THRESHOLD) then
        Output(stream^[PRED(pos)],0)
      else begin
             Output(last_match_len+(256-THRESHOLD),(pos-last_match_pos-2) AND PRED(DIC_SIZE));
             Dec(last_match_len);
             While (last_match_len > 0) do
               begin
                 GetNextMatch;
                 Dec(last_match_len);
               end;
             If (match_len > remain) then
               match_len := remain;
           end;
    end;

  SendBlock;
  PutBits(7,0);
  FreeMem(buf,WIN_SIZE);
  FreeMem(next,(MAX_HASH_VAL+1) SHL 1);
  FreeMem(previous,(DIC_SIZE*2) SHL 1);
  FreeMem(parent,(DIC_SIZE*2) SHL 1);
  FreeMem(pos_ptr,(DIC_SIZE+256) SHL 1);
  FreeMem(child_count,DIC_SIZE+256);
  FreeMem(level,DIC_SIZE+256);
  FreeMem(stream,2*DIC_SIZE+MAX_MATCH);
  LZH_compress := output_buffer_idx;
end;

function LZH_compress_ultra(var source,dest; size: Dword): Dword;

var
  last_match_len,last_match_pos: Integer;

begin
  LZH_compress_ultra := 0;
  input_buffer := Addr(source);
  input_buffer_idx := 0;
  input_buffer_size := size;
  output_buffer := Addr(dest);
  output_buffer_idx := 0;
  output_buffer^[input_buffer_idx] := 1; // set 'ultra' compression flag
  Inc(output_buffer_idx);
  Move(size,output_buffer^[output_buffer_idx],SizeOf(size));
  Inc(output_buffer_idx,SizeOf(size));
  progress_old_value := BYTE_NULL;
  progress_value := size;

  WIN_SIZE := WIN_SIZE_MAX;
  DIC_SIZE := DIC_SIZE_MAX;
  GetMem(stream,2*DIC_SIZE+MAX_MATCH);
  GetMem(level,DIC_SIZE+256);
  GetMem(child_count,DIC_SIZE+256);
  GetMem(pos_ptr,(DIC_SIZE+256) SHL 1);
  GetMem(parent,(DIC_SIZE*2) SHL 1);
  GetMem(previous,(DIC_SIZE*2) SHL 1);
  GetMem(next,(MAX_HASH_VAL+1) SHL 1);

  depth := 0;
  InitSlide;
  GetMem(buf,WIN_SIZE);
  buf^[0] := 0;
  FillChar(c_freq,SizeOf(c_freq),0);
  FillChar(p_freq,SizeOf(p_freq),0);
  out_pos := 0;
  out_mask := 0;
  bit_count := 8;
  sbit_buf := 0;
  remain := ReadDataBlock(Addr(stream^[DIC_SIZE]),DIC_SIZE+MAX_MATCH);
  match_len := 0;
  pos := DIC_SIZE;
  InsertNode;
  If (match_len > remain) then
    match_len := remain;

  While (remain > 0) do
    begin
      last_match_len := match_len;
      last_match_pos := match_pos;
      GetNextMatch;
      If (match_len > remain) then
        match_len := remain;
      If (match_len > last_match_len) or
         (last_match_len < THRESHOLD) then
        Output(stream^[PRED(pos)],0)
      else begin
             Output(last_match_len+(256-THRESHOLD),(pos-last_match_pos-2) AND PRED(DIC_SIZE));
             Dec(last_match_len);
             While (last_match_len > 0) do
               begin
                 GetNextMatch;
                 Dec(last_match_len);
               end;
             If (match_len > remain) then
               match_len := remain;
           end;
    end;

  SendBlock;
  PutBits(7,0);
  FreeMem(buf,WIN_SIZE);
  FreeMem(next,(MAX_HASH_VAL+1) SHL 1);
  FreeMem(previous,(DIC_SIZE*2) SHL 1);
  FreeMem(parent,(DIC_SIZE*2) SHL 1);
  FreeMem(pos_ptr,(DIC_SIZE+256) SHL 1);
  FreeMem(child_count,DIC_SIZE+256);
  FreeMem(level,DIC_SIZE+256);
  FreeMem(stream,2*DIC_SIZE+MAX_MATCH);
  LZH_compress_ultra := output_buffer_idx;
end;

end.
