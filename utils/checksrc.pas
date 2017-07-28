uses
  DOS;

function check_extra_chars(var data; size: Dword): String;

var
  temp: Dword;
  xchars: String;

begin
  xchars := '';
  If (size = 0) then EXIT;

  For temp := 0 to PRED(size) do
    begin
      If (temp < PRED(size)) and
         (pBYTE(@data)[temp] = $0d) and
         (pBYTE(@data)[SUCC(temp)] = $0a) then
        CONTINUE;

      If (temp > 0) and
         (pBYTE(@data)[PRED(temp)] = $0d) and
         (pBYTE(@data)[temp] = $0a) then
        CONTINUE;

      If (pBYTE(@data)[temp] <= $1f) or
         (pBYTE(@data)[temp] >= $7f) then
        If (Pos(CHR(pBYTE(@data)[temp]),xchars) = 0) then
          xchars := xchars+CHR(pBYTE(@data)[temp]);
    end;

  check_extra_chars := xchars;
end;

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

procedure check_file(filename: String);

var
  f: File;
  buf: Pointer;
  size: Dword;
  idx: Byte;
  xchars: String;

begin
  Assign(f,'..\'+filename);
  Reset(f,1);
  size := FileSize(f);
  GetMem(buf,size);
  BlockRead(f,buf^,size);
  Close(f);
  xchars := check_extra_chars(buf^,size);
  If (xchars <> '') then
    begin
      WriteLn(filename,':');
      For idx := 1 to Length(xchars) do
        If (idx < Length(xchars)) then
          Write(byte2hex(ORD(xchars[idx])),', ')
        else WriteLn(byte2hex(ORD(xchars[idx])));
      WriteLn;
    end;
end;

var
  search: SearchRec;

begin
  FindFirst('..\*.pas',anyfile-volumeid-directory,search);
  While (DOSerror = 0) do
    begin
      check_file(search.name);
      FindNext(search);
    end;

  FindFirst('..\*.inc',anyfile-volumeid-directory,search);
  While (DOSerror = 0) do
    begin
      check_file(search.name);
      FindNext(search);
    end;
end.
