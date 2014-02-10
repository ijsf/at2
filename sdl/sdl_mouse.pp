unit SDL_mouse;

{  Automatically converted by H2PAS.EXE from SDL_mouse.h
   Utility made by Florian Klaempfl 25th-28th september 96
   Improvements made by Mark A. Malakanov 22nd-25th may 97 
   Further improvements by Michael Van Canneyt, April 1998 
   define handling and error recovery by Pierre Muller, June 1998 }

   { ***Edited by Daniel F Moisset, dmoisset@grulic.org.ar*** }

  interface

    uses SDL_types, SDL_video ;

  { C default packing is dword }

{$PACKRECORDS 4}

 { Pointers to basic pascal types, inserted by h2pas conversion program.}
  Type
     PByte     = ^Byte;

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

  { Include file for SDL mouse event handling  }
  type

  { Implementation dependent  }
     WMcursor = Pointer;

     pSDL_Cursor = ^SDL_Cursor ;
     SDL_Cursor = record
          area : SDL_Rect;              { The area of the mouse cursor  }
          hot_x : Sint16;
          hot_y : Sint16;               { The "tip" of the cursor  }
          data : ^Uint8;                { B/W cursor data  }
          mask : ^Uint8;                { B/W cursor mask  }
          save : array[0..1] of ^Uint8; { Place to save cursor area  }
          wm_cursor : ^WMcursor;        { Window-manager cursor  }
       end;

  { Function prototypes  }

  {
     Retrieve the current state of the mouse.
     The current button state is returned as a button bitmask, which can
     be tested using the SDL_BUTTON(X) function, and x and y are set to the
     current mouse cursor position.
    }
  function SDL_GetMouseState(var x:longint; var y:longint):Uint8;cdecl;

  {
     Retrieve the current state of the mouse.
     The current button state is returned as a button bitmask, which can
     be tested using the SDL_BUTTON(X) function, and x and y are set to the
     mouse deltas since the last call to SDL_GetRelativeMouseState.
    }
  function SDL_GetRelativeMouseState(var x:longint; var y:longint):Uint8;cdecl;

  {
     Set the position of the mouse cursor (generates a mouse motion event)
  }
  procedure SDL_WarpMouse(x:Uint16; y:Uint16);cdecl;

  {
     Create a cursor using the specified data and mask (in MSB format).
     The cursor width must be a multiple of 8 bits.
    
     The cursor is created in black and white according to the following:
     data  mask    resulting pixel on screen
      0     1       White
      1     1       Black
      0     0       Transparent
      1     0       Inverted color if possible, black if not.
    
     Cursors created with this function must be freed with SDL_FreeCursor.
    }
  function SDL_CreateCursor(data:pByte; mask:pByte; w:longint; h:longint; hot_x:longint;
             hot_y:longint):pSDL_Cursor;cdecl;

  {
     Set the currently active cursor to the specified one.
     If the cursor is currently visible, the change will be immediately 
     represented on the display.
    }
  procedure SDL_SetCursor(cursor:pSDL_Cursor);cdecl;

  {
     Returns the currently active cursor.
  }
  function SDL_GetCursor:pSDL_Cursor;cdecl;

  {
     Deallocates a cursor created with SDL_CreateCursor.
  }
  procedure SDL_FreeCursor(cursor:pSDL_Cursor);cdecl;

  {
     Toggle whether or not the cursor is shown on the screen.
     The cursor start off displayed, but can be turned off.
     SDL_ShowCursor returns True iff the cursor was being displayed
     before the call. You can query the current state passing a
     'toggle' value of -1
  }
  function SDL_ShowCursor(toggle:Longint):LongBool;cdecl;

  { Used as a mask when testing buttons in buttonstate
     Button 1:	Left mouse button
     Button 2:	Middle mouse button
     Button 3:	Right mouse button
    }
  function SDL_BUTTON(X : Uint8) : Uint8;

  const
     SDL_BUTTON_LEFT = 1;
     SDL_BUTTON_MIDDLE = 2;
     SDL_BUTTON_RIGHT = 3;
     SDL_BUTTON_LMASK = 1 shl SDL_BUTTON_LEFT;
     SDL_BUTTON_MMASK = 1 shl SDL_BUTTON_MIDDLE;
     SDL_BUTTON_RMASK = 1 shl SDL_BUTTON_RIGHT;

  implementation

  function SDL_GetMouseState(var x:longint; var y:longint):Uint8;cdecl;external 'SDL';

  function SDL_GetRelativeMouseState(var x:longint; var y:longint):Uint8;cdecl;external 'SDL';

  procedure SDL_WarpMouse(x:Uint16; y:Uint16);cdecl;external 'SDL';

  function SDL_CreateCursor(data:pByte; mask:pByte; w:longint; h:longint; hot_x:longint;
             hot_y:longint):pSDL_Cursor;cdecl;external 'SDL';

  procedure SDL_SetCursor(cursor:pSDL_Cursor);cdecl;external 'SDL';

  function SDL_GetCursor:pSDL_Cursor;cdecl;external 'SDL';

  procedure SDL_FreeCursor(cursor:pSDL_Cursor);cdecl;external 'SDL';

  function SDL_ShowCursor(toggle:longint):longBool;cdecl;external 'SDL';

  function SDL_BUTTON(X : Uint8 ) : Uint8;
    begin
       SDL_BUTTON:=SDL_PRESSED shl (X - 1);
    end;


end.
