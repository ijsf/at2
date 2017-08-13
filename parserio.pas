unit ParserIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

function SensitiveScan(var buf; skip,size: Longint; str: String): Longint; cdecl; external name 'PARSERIO____SENSITIVESCAN_formal_LONGINT_LONGINT_SHORTSTRING__LONGINT';
function Compare(var buf1,buf2; size: Longint): Boolean; cdecl; external name 'PARSERIO____COMPARE_formal_formal_LONGINT__BOOLEAN';
function Empty(var buf; size: Longint): Boolean; cdecl; external name 'PARSERIO____EMPTY_formal_LONGINT__BOOLEAN';
function Update16(var buf; size: Longint; crc: Word): Word; cdecl; external name 'PARSERIO____UPDATE16_formal_LONGINT_WORD__WORD';
function Update32(var buf; size: Longint; crc: Longint): Longint; cdecl; external name 'PARSERIO____UPDATE32_formal_LONGINT_LONGINT__LONGINT';
procedure make_table_16bit; cdecl; external name 'PARSERIO____MAKE_TABLE_16BIT';
procedure make_table_32bit; cdecl; external name 'PARSERIO____MAKE_TABLE_32BIT';

implementation

uses
  StringIO;

begin
  make_table_16bit;
  make_table_32bit;
end.
