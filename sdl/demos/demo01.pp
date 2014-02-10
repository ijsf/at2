{
    SDL4FreePascal-1.2.0.0 - Simple DirectMedia Layer bindings for FreePascal
    Copyright (C) 2000, 2001  Daniel F Moisset

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

    Daniel F Moisset
    dmoisset@grulic.org.ar
}

Program Demo01 ;

{
  SDL4FreePascal Demo 01
  ======================
  
  Just set the video mode.
}

{ SDL: Initialization and cleanup routines for SDL 
  SDL_Video: The Video services 
  SDL_Types: Some Types and constants usually needed }
Uses SDL, SDL_Video, crt;

Const
   { These are the screen parameters (window or videomode).
      When using a depth non supported by hardware, SDL automatically converts
     to the requested depth, but it's slower than direct access.
   }
   width = 320 ;
   height = 240 ;
   colordepth = 16 ;

Var
   screen: PSDL_Surface ;
   { A PSDL_Surface is used to store bitmap video surfaces, for example the
     visible screen, non-visible areas of video memory, and memory areas used
     for storing pixmaps.
     This variable will be used to store the visible screen.
   }

Begin
   { SDL_Init must be called before doing anything with SDL.
     The parameter is a bitwise or of SDL_INIT_xxx constants, indicating 
     which SDL subsystems will be used. }
   SDL_Init (SDL_INIT_VIDEO) ;

   { SDL_SetVideoMode creates a surface attached to the visible screen or
     window. Its last parameter indicates several flags for the surface.
     In this demo we're creating the surface in system memory (instead of
     video memory). This makes for faster pixel r/w access, but eventually
     is necessary to spend some time copying it to real video memory. A 
     hardware surface must not be copied (it's already there), and may take
     advantage of hardware acceleration for blitting, but must be  locked 
     and unlocked when accessing }
   screen := SDL_SetVideoMode (width, height, colordepth, SDL_SWSURFACE) ;
   { SDL_SetVideoMode returns nil if something fails }
   if screen = nil then
   Begin
       Writeln ('Couldn''t initialize video mode at ', width, 'x',
                height, 'x', colordepth, 'bpp') ;
       Halt(1)
   End ;

   Delay(5000) ; { Wait 5 seconds }

   { Allocated surfaces must be freed using SDL_FreeSurface }
   SDL_FreeSurface (screen) ;
   { SDL_Quit closes SDL  }
   SDL_Quit ;
   { The window/videomode closes just here (it's not closed by FreeSurface) }

   WriteLn('Now we are not using SDL')
End.
