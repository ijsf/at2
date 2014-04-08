unit AdT2sys;

interface

const
  _debug_: Boolean = FALSE;
  _debug_str_: String = '';

procedure sys_init;
procedure sys_deinit;

procedure ResetF_RW(var f: File);
procedure ResetF(var f: File);
procedure RewriteF(var f: File);
procedure BlockReadF(var f: File; var data; size: Longint; var bytes_read: Longint);
procedure BlockWriteF(var f: File; var data; size: Longint; var bytes_written: Longint);
procedure SeekF(var f: File; fpos: Longint);
procedure EraseF(var f: File);
procedure CloseF(var f: File);

implementation

uses
  DOS,
  SDL,SDL_Timer,
  AdT2unit,AdT2vid,AdT2opl3,AdT2vscr,AdT2text,AdT2keyb,
  TxtScrIO;

procedure sys_init;
begin
  AdT2vid.vid_Init; // SDL video
  AdT2opl3.snd_Init; // SDL sound + opl3 emulation
end;

procedure sys_deinit;
begin
  AdT2vid.vid_Deinit;
end;

procedure ResetF_RW(var f: File);

var
  fattr: Word;

begin
  _debug_str_:= 'ADT2SYS.PAS:ResetF_RW';
  GetFAttr(f,fattr);
  If (fattr AND ReadOnly = ReadOnly) then
    SetFAttr(f,fattr AND NOT ReadOnly);
  If (DosError <> 0) then ;
  FileMode := 2;
  {$i-}
  Reset(f,1);
  {$i+}
end;

procedure ResetF(var f: File);

var
  fattr: Word;

begin
  _debug_str_:= 'ADT2SYS.PAS:ResetF';
  GetFAttr(f,fattr);
  If (fattr AND ReadOnly = ReadOnly) then
    FileMode := 0;
  {$i-}
  Reset(f,1);
  {$i+}
end;

procedure RewriteF(var f: File);

var
  fattr: Word;

  begin
  _debug_str_:= 'ADT2SYS.PAS:RewriteF';
  GetFAttr(f,fattr);
  If (fattr AND ReadOnly = ReadOnly) then
    SetFAttr(f,fattr AND NOT ReadOnly);
  {$i-}
  Rewrite(f,1);
  {$i+}
end;

procedure BlockReadF(var f: File; var data; size: Longint; var bytes_read: Longint);
begin
  _debug_str_:= 'ADT2SYS.PAS:BlockReadF';
  {$i-}
  BlockRead(f,data,size,bytes_read);
  {$i+}
  If (IOresult <> 0) then
    bytes_read := 0;
end;

procedure BlockWriteF(var f: File; var data; size: Longint; var bytes_written: Longint);
begin
  _debug_str_:= 'ADT2SYS.PAS:BlockWriteF';
  {$i-}
  BlockWrite(f,data,size,bytes_written);
  {$i+}
  If (IOresult <> 0) then
    bytes_written := 0;
end;

procedure SeekF(var f: File; fpos: Longint);
begin
  _debug_str_:= 'ADT2SYS.PAS:SeekF';
  {$i-}
  Seek(f,fpos);
  {$i+}
end;

procedure EraseF(var f: File);
begin
  _debug_str_:= 'ADT2SYS.PAS:EraseF';
  {$i-}
  Erase(f);
  {$i+}
  If (IOresult <> 0) then ;
end;

procedure CloseF(var f: File);
begin
  _debug_str_:= 'ADT2SYS.PAS:CloseF';
  {$i-}
  Close(f);
  {$i+}
  If (IOresult <> 0) then ;
end;

end.