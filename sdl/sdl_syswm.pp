unit SDL_syswm;

{  Automatically converted by H2PAS.EXE from SDL_syswm.h
   Utility made by Florian Klaempfl 25th-28th september 96
   Improvements made by Mark A. Malakanov 22nd-25th may 97 
   Further improvements by Michael Van Canneyt, April 1998 
   define handling and error recovery by Pierre Muller, June 1998 }


  interface

  { C default packing is dword }

{$PACKRECORDS 4}

  {
      SDL - Simple DirectMedia Layer
      Copyright (C) 1997, 1998, 1999, 2000, 2001  Sam Lantinga
  
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
  { Include file for SDL custom system window manager hooks  }

  { Your application has access to a special type of event 'SDL_SYSWMEVENT',
     which contains window-manager specific information and arrives whenever
     an unhandled window event occurs.  This event is ignored by default, but
     you can enable it with SDL_EventState()
   }
  type
    pSDL_SysWMinfo = ^SDL_SysWMinfo ;
    SDL_SysWMinfo = record
                      { ***Not implemented*** }
                    end;

    pSDL_SysWMmsg = ^SDL_SysWMmsg ;
    SDL_SysWMmsg = record
                     { ***Not implemented*** }
                   end;

  { Function prototypes  }
  {
     This function gives you custom hooks into the window manager information.
     It fills the structure pointed to by 'info' with custom information and
     returns 1 if the function is implemented.  If it's not implemented, or
     the version member of the 'info' structure is invalid, it returns 0. 
    }

  function SDL_GetWMInfo(info:pSDL_SysWMinfo):longint;cdecl;

  implementation

  function SDL_GetWMInfo(info:pSDL_SysWMinfo):longint;cdecl;external 'SDL';


end.
