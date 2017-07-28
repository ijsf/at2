unit SDL__rwops;

{  Automatically converted by H2PAS.EXE from SDL_rwops.h
   Utility made by Florian Klaempfl 25th-28th september 96
   Improvements made by Mark A. Malakanov 22nd-25th may 97 
   Further improvements by Michael Van Canneyt, April 1998 
   define handling and error recovery by Pierre Muller, June 1998 }

   { ***Edited by Daniel F Moisset, dmoisset@grulic.org.ar*** }

  interface

    uses SDL_types, stdio;
  { C default packing is dword }

{$PACKRECORDS 4}

 { Pointers to basic pascal types, inserted by h2pas conversion program.}
  Type
     PByte     = ^Byte;

  {
      SDL - Simple DirectMedia Layer
      Copyright (C) 1997, 1998, 1999  Sam Lantinga
  
      This library is free software; you can redistribute it and/or
      modify it under the terms of the GNU Library General Public
      License as published by the Free Software Foundation; either
      version 2 of the License, or (at your option) any later version.
  
      This library is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
      Library General Public License for more details.
  
      You should have received a copy of the GNU Library General Public
      License along with this library; if not, write to the Free
      Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
  
      Sam Lantinga
      slouken@devolution.com
   }

  { This file provides a general interface for SDL to read and write
     data sources.  It can easily be extended to files, memory, etc.
   }

  { This is the read/write operation structure -- very basic  }

  type

     pSDL_RWops = ^SDL_RWops;
     SDL_RWops = record
          { Seek to 'offset' relative to whence, one of stdio's whence values:
                 SEEK_SET, SEEK_CUR, SEEK_END
            Returns the final offset in the data source.
          }
          seek : function (context:pSDL_RWops; offset:longint; whence:longint):longint;cdecl;
          { Read up to 'num' objects each of size 'objsize' from the data
            source to the area pointed at by 'ptr'.
            Returns the number of objects read, or -1 if the read failed.
          }
          read : function (context:pSDL_RWops; var data; size:longint; maxnum:longint):longint;
          { Write exactly 'num' objects each of size 'objsize' from the area
            pointed at by 'ptr' to data source.
            Returns 'num', or -1 if the write failed.
          }
          write : function (context:pSDL_RWops; var data; size:longint; num:longint):longint;
          { Close and free an allocated SDL_FSops structure  }
          close : function (context:pSDL_RWops):longint;
          optype : Uint32;
          hidden : record
              case longint of
                 0 : ( stdio : record
                         autoclose : longint;
                         fp : PFile; {C file *}
                       end
                     );
                 1 : ( mem : record
                         base : PByte;
                         here : PByte;
                         stop : PByte;
                       end
                     );
                 2 : ( unknown : record
                         data1 : pointer;
                       end 
                     );
              end;
       end;

  { Functions to create SDL_RWops structures from various data sources  }

  function SDL_RWFromFile(filename:pchar; mode:pchar):pSDL_RWops;cdecl;

  function SDL_RWFromFP(fp:Pointer; autoclose:longint):pSDL_RWops;cdecl;

  function SDL_RWFromMem(var mem; size:longint):pSDL_RWops;cdecl;

  function SDL_AllocRW:pSDL_RWops;cdecl;

  { Macros to easily read and write from an SDL_RWops structure  }
  function SDL_RWseek(ctx: pSDL_RWops;offset,whence : longint) : longint;

  function SDL_RWtell(ctx : pSDL_RWops) : longint;

  function SDL_RWread(ctx : pSDL_RWops; var data;size,n : longint) : longint;

  function SDL_RWwrite(ctx : pSDL_RWops; var data;size,n : longint) : longint;

  function SDL_RWclose(ctx : pSDL_RWops) : longint;

  implementation

  function SDL_RWFromFile(filename:pchar; mode:pchar):pSDL_RWops;cdecl;external 'SDL';

  function SDL_RWFromFP(fp:Pointer; autoclose:longint):pSDL_RWops;cdecl;external 'SDL';

  function SDL_RWFromMem(var mem; size:longint):pSDL_RWops;cdecl;external 'SDL';

  function SDL_AllocRW:pSDL_RWops;cdecl;external 'SDL';

  function SDL_RWseek(ctx: pSDL_RWops;offset,whence : longint) : longint;
    begin
       SDL_RWseek:=ctx^.seek(ctx,offset,whence);
    end;

  function SDL_RWtell(ctx : pSDL_RWops) : longint;
    begin
       SDL_RWtell:=ctx^.seek(ctx,0,SEEK_CUR);
    end;

  function SDL_RWread(ctx : pSDL_RWops; var data;size,n : longint) : longint;
    begin
       SDL_RWread:=ctx^.read(ctx,data,size,n);
    end;

  function SDL_RWwrite(ctx : pSDL_RWops; var data;size,n : longint) : longint;
    begin
       SDL_RWwrite:=ctx^.write(ctx,data,size,n);
    end;

  function SDL_RWclose(ctx : pSDL_RWops) : longint;
    begin
       SDL_RWclose:=ctx^.close(ctx);
    end;


end.
