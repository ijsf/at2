uses DOS;

procedure header_data; assembler;
asm
 dd 0CD0083B8h,01110B810h,0B91000BBh,0D2330100h,0CD0128BDh,04C00B810h,0754C21CDh,073276550h
 dd 061686320h,074657372h
end;

{$i font8x16.inc}
var
  f: File;
  temp: Word;

begin
  Assign(f,'font.com');
  SetFAttr(f,ARCHIVE);
  Rewrite(f,1);
  BlockWrite(f,Addr(header_data)^,40);
  BlockWrite(f,Addr(font8x16)^,4096);
  Close(f);
end.

