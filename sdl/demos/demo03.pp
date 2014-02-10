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

Program Demo03 ;
{
  SDL4FreePascal Demo 03
  ======================
  
  Bitmap blits and animation
}

Uses SDL, SDL_Video, crt;

Const
   width = 320 ;
   height = 240 ;
   colordepth = 16 ;
   { diameter of the bouncing ball }
   ballsize = 20 ;
   { size of the paddle }
   paddlewidth = 6 ;
   paddleheight = 30 ;
   { number of iterations of the animation loop }
   duration = 500 ;
Type
   pixel = Word ;

Var
   screen: PSDL_Surface ;

   { I am using a surface to store each of the bitmaps. I could also use a
     single surface, but this way is easier. }
   bitmap1, bitmap2: PSDL_Surface ;

   { SDL_Rect structures represent rectangles. I need these for passing as 
   parameters to the blit function (and some others) }
   bsrect, bdrect, bdrect2: SDL_Rect ;
   psrect, pdrect, pdrect2: SDL_Rect ;

   { coordinates of the ball }
   x, y: Integer ;
   { speed of the ball }
   vx,vy: Integer ;
   { Iteration count}
   time: Integer ;

Function Render_ball (size: Longint) : PSDL_Surface ;
      { Returns a surface with the bitmap image of a ball of diameter `size' }
const
   { ambient light }
   ambient = 0.3 ;
   { directional light vector }
   lx = 0.5 ;
   ly = 0.3 ;
   lz = Sqrt(1-lx*lx-ly*ly) ;
Type
   { This time I'm using a monodimensional unbounded pixel array. That's 
     because I don't know exactly how long the buffer will be because SDL pads
     horizontal lines in the buffer }
   pixbuf = Array[0..0] of Pixel ;
Var
   Res: PSDL_Surface ;

   { This variables are using for rendering the ball, pixel by pixel}
   x, y : LongInt ;
   rx,ry,rz,r,int: Real ;
Begin
   { SDL_CreateRGBSurface creates a new surface, of a given type, size and
     colordepth. The four mask parameters below indicate the format of the
     surface (which bits are red, green, blue and alpha); I'm copying them 
     from the screen surface }
   Res := SDL_CreateRGBSurface (SDL_SWSURFACE, size, size, colordepth,
                                   screen^.format^.rmask,
                                   screen^.format^.gmask,
                                   screen^.format^.bmask,
                                   screen^.format^.amask) ;
   if Res = nil then
   Begin
       Writeln ('Couldn''t alloc bitmap surface') ;
       Halt(1)
   End ;

   { Render the ball}
   r := size/2.0 ;
   for x := 0 to size-1 do
      for y := 0 to size-1 do
      Begin
         { Calculate intensity for (x, y) }
         rx := (x-r)/r ;
         ry := (y-r)/r ;
         If rx*rx+ry*ry <= 1 then
         Begin
            rz := Sqrt (1-rx*rx-ry*ry) ;
            int := (rx*lx+ry*ly+rz*lz);
            if int < 0 then int := 0 ;
            int := int*(1-ambient)+ambient ;
         End
         else
            int := 0 ;
         { Now we fill the pixel. Note the use of Result^.pitch }
         pixbuf(Res^.pixels^)[y*Res^.pitch div 2+x] := Round(int*31) ;
      End ;
   Render_ball := Res ;
End;

Function Render_Paddle (size: Longint) : PSDL_Surface ;
      { Returns a surface with the bitmap image of a paddle of size `size' }
Type
   { This time I'm using a monodimensional unbounded pixel array. That's 
     because I don't know exactly how long the buffer will be because SDL pads
     horizontal lines in the buffer }
   pixbuf = Array[0..0] of Pixel ;
Var
   Res: PSDL_Surface ;

   { This variables are using for rendering the paddle, pixel by pixel}
   x, y : LongInt ;
Begin
   { SDL_CreateRGBSurface creates a new surface, of a given type, size and
     colordepth. The four mask parameters below indicate the format of the
     surface (which bits are red, green, blue and alpha); I'm copying them 
     from the screen surface }
   Res := SDL_CreateRGBSurface (SDL_SWSURFACE, paddlewidth, size, colordepth,
                                   screen^.format^.rmask,
                                   screen^.format^.gmask,
                                   screen^.format^.bmask,
                                   screen^.format^.amask) ;
   if Res = nil then
   Begin
       Writeln ('Couldn''t alloc bitmap surface') ;
       Halt(1)
   End ;

   { Render the paddle}
   for x := 0 to paddlewidth-1 do
      for y := 0 to size-1 do
      Begin
         { Now we fill the pixel. Note the use of Result^.pitch }
         pixbuf(Res^.pixels^)[y*Res^.pitch div 2+x] :=
         { This time we will calculate the pixel value using SDL_MapRGB. This
           function takes a surface format and the three color components in
           a 0-255 range, and returns the pixel value for that color in that
           format }
            SDL_MapRGB(Res^.format, 255 - x*40, 255, 0);
      End ;
   Render_paddle := Res ;
End;

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


   bitmap1 := Render_ball (ballsize) ;
   bitmap2 := Render_Paddle (paddleheight) ;
   x := 160 ;
   y := 120 ;
   vx := 4 ; vy := 6 ;
   { This rect structure is filled with the data for the origin of the blit; 
     in this case, is the whole surface }
   bsrect.x := 0 ; bsrect.y := 0 ;
   bsrect.w := ballsize ; bsrect.h := ballsize ;

   psrect.x := 0 ; psrect.y := 0 ;
   psrect.w := paddlewidth ; psrect.h := paddleheight ;

   bdrect.x := x ; bdrect.y := y ;
   bdrect.w := ballsize ; bdrect.h := ballsize ;

   pdrect.x := width-10 ; pdrect.y := y+(ballsize div 2)-(paddleheight div 2) ;
   pdrect.w := paddlewidth ; pdrect.h := paddleheight ;

   for time := 1 to duration do
   Begin
      bdrect2 := bdrect ;
      pdrect2 := pdrect ;
      { This rect is filled with the destination of the blit, coordinates 
        relative to the destination surface (screen). There is no need in
        setting the width and height, because it never changes }
      bdrect.x := x ;
      bdrect.y := y ;
      pdrect.y := y+(ballsize div 2)-(paddleheight div 2) ;
      { Don't move the paddle offscreen }
      if pdrect.y < 0 then pdrect.y := 0 ;
      if pdrect.y+pdrect.h >=height then pdrect.y := height-pdrect.h-1 ;
      { The bitmap from the `bitmap1' surface is copied to the screen surface.
        The areas in the surface to be copied are passed in srect and drect }
      SDL_BlitSurface (bitmap1, @bsrect, screen, @bdrect);
      SDL_BlitSurface (bitmap2, @psrect, screen, @pdrect);
      { Now the screen is updated (only the changed areas) }
      with bdrect do
         SDL_UpdateRect (screen, x, y, w, h ) ;
      with bdrect2 do
         SDL_UpdateRect (screen, x, y, w, h ) ;
      with pdrect do
         SDL_UpdateRect (screen, x, y, w, h ) ;
      with pdrect2 do
         SDL_UpdateRect (screen, x, y, w, h ) ;
      { SDL_FillRect fills a rectangle in a surface with a given color. We use
        it here to erase the ball we just drawed, putting a black rectangle 
        over it. Note that this black recctangle is never seen in the monitor
        because we draw the ball again before reupdating the screen. }
      SDL_FillRect (screen, @bdrect, $0000) ;
      { same for the paddle }
      SDL_FillRect (screen, @pdrect, $0000) ;
      { For animation timing... Comment or modify this for changing speed }
      Delay (25) ;
      { Move the ball }
      x := x + vx ;
      y := y + vy ;

      { Bounce against borders }
      If x+ballsize >= width-10 then
      Begin
         x:= width-ballsize-1-10 ;
         vx := -vx
      End ;
      If y+ballsize >= height then
      Begin
         y:= height-ballsize-1 ;
         vy := -vy
      End ;
      If x < 0 then
      Begin
         x := 0 ;
         vx := -vx ;
      End ;
      If y < 0 then
      Begin
         y := 0 ;
         vy := -vy ;
      End ;
   End ;

   { Cleanup }
   SDL_FreeSurface (bitmap1) ;
   SDL_FreeSurface (screen) ;
   SDL_Quit
End.
