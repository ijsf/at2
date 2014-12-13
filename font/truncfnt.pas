uses DOS;

var
  f: File;
  temp: Word;
  buf: array[0..PRED(4096)] of Byte;

begin
  Assign(f,'font.com');
  Reset(f,1);
  Seek(f,40);
  BlockRead(f,buf,4096);
  SetFAttr(f,ARCHIVE);
  Rewrite(f,1);
  BlockWrite(f,buf,4096);
  Close(f);
end.
