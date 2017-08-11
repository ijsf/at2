unit ParserIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

function SensitiveScan(var buf; skip,size: Longint; str: String): Longint; external name '_PARSERIO____SENSITIVESCAN_formal_LONGINT_LONGINT_SHORTSTRING__LONGINT';
function Compare(var buf1,buf2; size: Longint): Boolean; external name '_PARSERIO____COMPARE_formal_formal_LONGINT__BOOLEAN';
function Empty(var buf; size: Longint): Boolean; external name '_PARSERIO____EMPTY_formal_LONGINT__BOOLEAN';
function Update16(var buf; size: Longint; crc: Word): Word; external name '_PARSERIO____UPDATE16_formal_LONGINT_WORD__WORD';
function Update32(var buf; size: Longint; crc: Longint): Longint; external name '_PARSERIO____UPDATE32_formal_LONGINT_LONGINT__LONGINT';

implementation

uses
  StringIO;

var CRC16_table: array[BYTE] of Word; export name '_CRC16_table';
var CRC32_table: array[BYTE] of Longint; export name '_CRC32_table';

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
