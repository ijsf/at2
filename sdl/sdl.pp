unit SDL;

{  Automatically converted by H2PAS.EXE from SDL.h
   Utility made by Florian Klaempfl 25th-28th september 96
   Improvements made by Mark A. Malakanov 22nd-25th may 97 
   Further improvements by Michael Van Canneyt, April 1998 
   define handling and error recovery by Pierre Muller, June 1998 }

   { ***Edited by Daniel F Moisset, dmoisset@grulic.org.ar*** }

  interface

    uses SDL_types;

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

  { Main include header for the SDL library  }

  { As of version 0.5, SDL is loaded dynamically into the application  }

  { These are the flags which may be passed to SDL_Init() -- you should
     specify the subsystems which you will be using in your application.
   }

  const
     SDL_INIT_TIMER = $00000001;
     SDL_INIT_AUDIO = $00000010;
     SDL_INIT_VIDEO = $00000020;
     SDL_INIT_CDROM = $00000100;
     SDL_INIT_JOYSTICK = $00000200;
     SDL_INIT_NOPARACHUTE = $00100000; { Don't catch fatal signals  }
     SDL_INIT_EVENTTHREAD = $01000000; { Not supported on all OS's  }
     SDL_INIT_EVERYTHING = $0000FFFF;

  { This function loads the SDL dynamically linked library and initializes 
     the subsystems specified by 'flags' (and those satisfying dependencies)
    Unless the SDL_INIT_NOPARACHUTE flag is set, it will install cleanup
     signal handlers for some commonly ignored fatal signals (like SIGSEGV)
  }
  function SDL_Init(flags:Uint32):longint;cdecl;

  { This function initializes  specific SDL subsystems }
  function SDL_InitSubSystem(flags:Uint32):longint;cdecl;
  
  { This function cleans up specific SDL subsystems }
  Procedure SDL_QuitSubSystem(flags:Uint32);cdecl;
  
  { This function returns mask of the specified subsystems which have
    been initialized.
    If 'flags' is 0, it returns a mask of all initialized subsystems.
  }
  Function SDL_WasInit(flags:Uint32):Uint32;cdecl;
  
  { This function cleans up the initialized subsystems and unloads the
     dynamically linked library.  You should call it upon all exit conditions.
    }
  procedure SDL_Quit;cdecl;


  implementation

{$IFDEF LINUX}
  {$LINKLIB pthread}
{$ENDIF}
  function SDL_Init(flags:Uint32):longint;cdecl;external 'SDL';

  function SDL_InitSubSystem(flags:Uint32):longint;cdecl;external 'SDL';

  Procedure SDL_QuitSubSystem(flags:Uint32);cdecl;external 'SDL';

  Function SDL_WasInit(flags:Uint32):Uint32;cdecl;external 'SDL';

  procedure SDL_Quit;cdecl;external 'SDL';

end.
