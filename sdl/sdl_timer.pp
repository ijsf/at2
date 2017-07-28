unit SDL_timer;

{  Automatically converted by H2PAS.EXE from SDL_timer.h
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

  { Header for the SDL time management routines  }

  const
     { This is the OS scheduler timeslice, in milliseconds }
     SDL_TIMESLICE = 10;
     { This is the maximum resolution of the timer on all platforms }
     TIMER_RESOLUTION = 10;  { Experimentally determined  }

  { Get the number of milliseconds since the SDL library initialization.
     Note that this value wraps if the program runs for more than ~49 days.
    }
  function SDL_GetTicks:Uint32;cdecl;

  { Wait a specified number of milliseconds before returning  }
  procedure SDL_Delay(ms:Uint32);cdecl;


  type
  { Function prototype for the timer callback function  }
     SDL_TimerCallback = function (interval:Uint32):Longbool;cdecl;

  { Set a callback to run after the specified number of milliseconds has
     elapsed. The callback function is passed the current timer interval
     and returns the next timer interval.  If the returned value is the 
     same as the one passed in, the periodic alarm continues, otherwise a
     new alarm is scheduled. If the callback returns False, the periodic
     alarm is cancelled. 
    
     To cancel a currently running timer, call SDL_SetTimer(0, nil);
    
     The timer callback function may run in a different thread than your
     main code, and so shouldn't call any functions from within itself.
    
     The maximum resolution of this timer is 10 ms, which means that if
     you request a 16 ms timer, your callback will run approximately 20 ms
     later on an unloaded system.  If you wanted to set a flag signaling
     a frame update at 30 frames per second (every 33 ms), you might set a 
     timer for 30 ms:
       SDL_SetTimer((33 div 10)*10, flag_update);
    
     If you use this function, you need to pass SDL_INIT_TIMER to SDL_Init.
    
     Under UNIX, you should not use raise or use SIGALRM and this function
     in the same program, as it is implemented using setitimer().  You also
     should not use this function in multi-threaded applications as signals
     to multi-threaded apps have undefined behavior in some implementations.
    }
  function SDL_SetTimer(interval:Uint32; callback:SDL_TimerCallback):longint;cdecl;

  { New timer API, supports multiple timers
    Written by Stephane Peter <megastep@lokigames.com> }

  { Function prototypye for the new timer callback function.
    The callback function is passed the current timer interval and returns
    the next timer interval.  If the returned value is the same as the one
    passed in, the periodic alarm continues, otherwise a new alarm is
    scheduled.  If the callback returns 0, the periodic alarm is cancelled.
  }
  type
     SDL_NewTimerCallback = function (interval: Uint32;
                                      param: Pointer):Uint32; cdecl;

     _SDL_TimerID = record end ; { No public Data}
     SDL_TimerID = ^_SDL_TimerID ;
     
  { Add a new timer to the pool of timers already running.
    Returns a timer ID, or Nil when an error occurs.
  }
  function SDL_AddTimer (interval: Uint32; callback: SDL_NewTimerCallback; 
                         param: Pointer): SDL_TimerID ; cdecl;

  { Remove one of the multiple timers knowing its ID.
    Returns a boolean value indicating success.
  }
  function SDL_RemoveTimer (t: SDL_TimerID): SDL_bool;cdecl;

  implementation

  function SDL_GetTicks:Uint32;cdecl;external 'SDL';

  procedure SDL_Delay(ms:Uint32);cdecl;external 'SDL';

  function SDL_SetTimer(interval:Uint32; callback:SDL_TimerCallback):longint;cdecl;external 'SDL';

  function SDL_AddTimer (interval: Uint32; callback: SDL_NewTimerCallback; 
                         param: Pointer): SDL_TimerID ; cdecl;external 'SDL';

  function SDL_RemoveTimer (t: SDL_TimerID): SDL_bool;cdecl;external 'SDL';

end.
