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

Program Demo02 ;
{
  SDL4FreePascal Demo 02
  ======================
  
  Pixel access to the screen
}

Uses SDL, SDL_Video, crt;

Const
   width = 320 ;
   height = 240 ;
   colordepth = 16 ;
Type
   Pixel = Word ; { Must have colordepth bits }

Type
   { This type mimics the pixel surface srtucture: 'height' sequential rows
     of 'width' pixels each. }
   TpixelBuf = Array [0..height-1, 0..width-1] of Pixel ;

Var
   screen: PSDL_Surface ;

   { coordinates of the pixel we are changing (t is 'time') }
   t, x, y: Integer ;
   { red and blue components (green is not used in this demo ;-) ) }
   red, blue: Integer ;

   pixelcolor: Pixel ;
Begin
   { Initialization }
   SDL_Init (SDL_INIT_VIDEO) ;
   screen := SDL_SetVideoMode (width, height, colordepth, SDL_SWSURFACE) ;
   if screen = nil then
   Begin
       Writeln ('Couldn''t initialize video mode at ', width, 'x',
                height, 'x', colordepth, 'bpp') ;
       Halt(1)
   End ;

   for t:=-15 to 15 do
   Begin
      {For each frame t.... }
      for y:=0 to height-1 do
         for x:=0 to width-1 do
         { And for each pixel (x,y)...}
         Begin
            { Calculate red and blue pixel intensity (range 0..31, 5 bits for
              16bpp mode) }
            red := Trunc( Sin((8-t*0.4)*Pi*x/width)*10 )+20 ;
            blue := Trunc( Sin((12+t*0.2)*Pi*y/height)*12 )+19 ;
            { we make the pixel, masking lower 5 bits (just in case), and 
              adding. In 16bpp mode, red is shifted 11 bits, green is shifted 5
              bits (and has 6 bit depth), and blue is unshifted.
              Although calculating directly is faster, it depends on the format
              of the surface. You can always use SDL_MapRGB, which solves that
              automagically. }
            pixelcolor := (red and $1F) shl 11 + (blue and $1F) ;
            { A PSDL_Surface (let's call it 's') can be modified pixel by pixel
              through s^.pixels. That field points to a buffer of pixels, in
              reading order (left to right first, then top to bottom).
              Be careful with the length of each pixel line. The space 
              allocated for each scan line in the surface may be a little 
              larger than the requested size (is rounded up to the multiple of 
              some constant). You can tell how long (in bytes) each buffer scan 
              line really is reading s^.pitch (s^.width is the requested 
              width, in pixels).
              Some surfaces must be locked before using '.pixels', and unlocked
              after. Check SDL_LockSurface, SDL_UnlockSurface, and SDL_MUSTLOCK
            }
            Tpixelbuf(screen^.pixels^)[y,x] := pixelcolor
         End ;
      { You must call SDL_UpdateRect (check SDL_UpdateRects too), for ensuring
        that the physical display is updated after modifying a surface. 
        SDL_UpdateRect takes as parameters a video surface, and origin, width
        and height of a rectangle to be updated. If the last 4 parameters are 
        0, the whole surface is updated }
      SDL_UpdateRect (screen, 0, 0, 0, 0) ;
      Delay (50) ; { For animation timing... }
   End ;

   { Cleanup }
   SDL_FreeSurface (screen) ;
   SDL_Quit
End.
