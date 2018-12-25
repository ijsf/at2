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

unit A2fileIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

const
  _debug_str_: String = '';

const
  GENERIC_IO_BUFFER_SIZE = 1500*1024; // 1.5 MB I/O Buffer

type
  pGENERIC_IO_BUFFER = ^tGENERIC_IO_BUFFER;
  tGENERIC_IO_BUFFER = array[0..PRED(GENERIC_IO_BUFFER_SIZE)] of Byte;

var
  buf1: tGENERIC_IO_BUFFER;
  buf2: tGENERIC_IO_BUFFER;
  buf3: array[WORD] of Byte;
  buf4: array[WORD] of Byte;

const
  adjust_tracks: Boolean = TRUE;
  accurate_conv: Boolean = TRUE;
  fix_c_note_bug: Boolean = TRUE;

var
  songdata_source: String;
  songdata_title: String;
  load_flag: Byte;

procedure a2m_file_loader;
procedure a2t_file_loader;
procedure amd_file_loader;
procedure cff_file_loader;
procedure dfm_file_loader;
procedure mtk_file_loader;
procedure rad_file_loader;
procedure s3m_file_loader;
procedure fmk_file_loader;
procedure sat_file_loader;
procedure sa2_file_loader;
procedure hsc_file_loader;

procedure ResetF(var f: File);
procedure BlockReadF(var f: File; var data; size: Longint; var bytes_read: Longint);
procedure SeekF(var f: File; fpos: Longint);
procedure CloseF(var f: File);

implementation

uses
  DOS,
  A2player,A2depack,
  StringIO,ParserIO;

{$i iloaders.inc}

procedure ResetF(var f: File);

var
  fattr: Word;

begin
  _debug_str_:= 'ADT2SYS.PAS:ResetF_RW';
  GetFAttr(f,fattr);
  If (fattr AND ReadOnly = ReadOnly) then FileMode := 0;
  {$i-}
  Reset(f,1);
  {$i+}
end;

procedure BlockReadF(var f: File; var data; size: Longint; var bytes_read: Longint);
begin
  _debug_str_:= 'ADT2SYS.PAS:BlockReadF';
  {$i-}
  BlockRead(f,data,size,bytes_read);
  {$i+}
  If (IOresult <> 0) then bytes_read := 0;
end;

procedure SeekF(var f: File; fpos: Longint);
begin
  _debug_str_:= 'ADT2SYS.PAS:SeekF';
  {$i-}
  Seek(f,fpos);
  {$i+}
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
