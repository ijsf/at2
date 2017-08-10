unit ParserIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

function SensitiveScan(var buf; skip,size: Longint; str: String): Longint;
function Compare(var buf1,buf2; size: Longint): Boolean;
function Empty(var buf; size: Longint): Boolean;
function Update16(var buf; size: Longint; crc: Word): Word;
function Update32(var buf; size: Longint; crc: Longint): Longint;

implementation

uses
  StringIO;

var CRC16_table: array[BYTE] of Word;
var CRC32_table: array[BYTE] of Longint;

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
