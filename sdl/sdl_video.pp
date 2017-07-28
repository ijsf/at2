unit SDL_video;

{  Automatically converted by H2PAS.EXE from SDL_video.h
   Utility made by Florian Klaempfl 25th-28th september 96
   Improvements made by Mark A. Malakanov 22nd-25th may 97 
   Further improvements by Michael Van Canneyt, April 1998 
   define handling and error recovery by Pierre Muller, June 1998 }

   { ***Edited by Daniel F Moisset, dmoisset@grulic.org.ar*** }

  interface

    uses SDL_types, SDL__rwops ;

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
    { Header file for access to the SDL raw framebuffer window  }

    { Useful data types  }
   
    const
       SDL_ALPHA_OPAQUE = 255;
       SDL_ALPHA_TRANSPARENT = 0;

    type

       PSDL_Rect = ^SDL_Rect;
       SDL_Rect = record
            x : Sint16;
            y : Sint16;
            w : Uint16;
            h : Uint16;
         end;
       PSDL_RectArray = ^SDL_RectArray;
       SDL_RectArray = array[0..0] of SDL_Rect ;

       PSDL_Color = ^SDL_COLOR ;
       SDL_Color = record
            r : Uint8;
            g : Uint8;
            b : Uint8;
            unused : Uint8;
         end;
       PSDL_ColorArray = ^SDL_ColorArray;
       SDL_ColorArray = Array[0..0] of SDL_Color ;

       SDL_Palette = record
            ncolors : longint;
            colors : PSDL_ColorArray;
         end;
    { Everything in the pixel format structure is read-only  }

       PSDL_PixelFormat = ^SDL_PixelFormat;
       SDL_PixelFormat = record
            palette : ^SDL_Palette;
            BitsPerPixel : Uint8;
            BytesPerPixel : Uint8;
            Rloss : Uint8;
            Gloss : Uint8;
            Bloss : Uint8;
            Aloss : Uint8;
            Rshift : Uint8;
            Gshift : Uint8;
            Bshift : Uint8;
            Ashift : Uint8;
            Rmask : Uint32;
            Gmask : Uint32;
            Bmask : Uint32;
            Amask : Uint32;
            { RGB color key information  }
            colorkey : Uint32;
            { Alpha value information (per-surface alpha)  }
            alpha : Uint8;
         end;

    { This structure should be treated as read-only, except for 'pixels',
       which, if not nil, contains the raw pixel data for the surface.
     }
       PSDL_Surface = ^SDL_Surface;
       SDL_Surface = record
            flags : Uint32;             { Read only }
            format : ^SDL_PixelFormat;  { Read only }
            w : longint;                { Read only }
            h : longint;                { Read only }
            pitch : Uint16;             { Read only }
            pixels : pointer;           { Read-write }
            offset : longint;           { Private }
            { Hardware-specific surface info }
            hwdata : Pointer; { ***"struct private_hwdata *"*** }
            clip_rect: SDL_Rect; { clipping information }
            unused1: Uint32;     { for binary compatibility }
            locked: Uint32;      { allow recursive locks }
            { info for fast blit mapping to other surfaces }
            map : Pointer;              { Private } { ***"struct SDL_BlitMap *"*** }
            { format version, bumped at every evrsion to invalidate blit maps }
            format_version: Longint;
            { Reference count -- used when freeing surface }
            refcount : longint;         { Read mostly }
         end;

       SDL_blit = function (src:PSDL_Surface; srcrect:pSDL_Rect;
                            dst:PSDL_Surface; dstrect:pSDL_Rect):longint;cdecl;


    { These are the currently supported flags for the SDL_surface  }

    const
    { Available for SDL_CreateRGBSurface or SDL_SetVideoMode  }
       
       SDL_SWSURFACE = $00000000; { Surface is in system memory  }
       SDL_HWSURFACE = $00000001; { Surface is in video memory  }
       SDL_ASYNCBLIT = $00000004; { Use asynchronous blits if possible  }
    { Available for SDL_SetVideoMode  }
       { Allow any video depth/pixel-format  }
       SDL_ANYFORMAT = $10000000;
       { Surface has exclusive palette  }
       SDL_HWPALETTE = $20000000;
       { Set up double-buffered video mode  }
       SDL_DOUBLEBUF = $40000000;
       { Surface is a full screen display  }
       SDL_FULLSCREEN = $80000000;
       { Create an OpenGL rendering context}
       SDL_OPENGL = $00000002;
       { Create an OpenGL rendering context and use it for blitting }
       SDL_OPENGLBLIT = $0000000A;
       { This video mode may be resized }
       SDL_RESIZABLE = $00000010;
       { No window caption or edge frame }
       SDL_NOFRAME = $00000020;
    { Used internally (read-only)  }
       { Blit uses hardware acceleration  }
       SDL_HWACCEL = $00000100;
       { Blit uses a source color key  }
       SDL_SRCCOLORKEY = $00001000;
       { Private flag  }
       SDL_RLEACCELOK = $00002000;
       { Surface is RLE encoded  }
       SDL_RLEACCEL = $00004000;
       { Blit uses source alpha blending  }
       SDL_SRCALPHA = $00010000;
       { Surface uses preallocated memory  }
       SDL_PREALLOC = $01000000;

    { Useful for determining the video hardware capabilities  }

    type
       PSDL_VideoInfo = ^SDL_VideoInfo;
       SDL_VideoInfo = record
            flag0 : longint;
            video_mem : Uint32;         { The total amount of video memory (in K)  }
            vfmt : ^SDL_PixelFormat;    { Value: The format of the video surface  }
         end;

    { *** Accessors for the flags of SDL_VideoInfo *** }

    { Flag: Can you create hardware surfaces?  }
    function hw_available(var a : SDL_VideoInfo) : Uint32;
    procedure set_hw_available(var a : SDL_VideoInfo; __hw_available : Uint32);

    { Flag: Can you talk to a window manager?  }
    function wm_available(var a : SDL_VideoInfo) : Uint32;
    procedure set_wm_available(var a : SDL_VideoInfo; __wm_available : Uint32);
    function UnusedBits1(var a : SDL_VideoInfo) : Uint32;
    procedure set_UnusedBits1(var a : SDL_VideoInfo; __UnusedBits1 : Uint32);
    function UnusedBits2(var a : SDL_VideoInfo) : Uint32;
    procedure set_UnusedBits2(var a : SDL_VideoInfo; __UnusedBits2 : Uint32);

    { Flag: Accelerated blits HW --> HW  }
    function blit_hw(var a : SDL_VideoInfo) : Uint32;
    procedure set_blit_hw(var a : SDL_VideoInfo; __blit_hw : Uint32);

    { Flag: Accelerated blits with Colorkey  }
    function blit_hw_CC(var a : SDL_VideoInfo) : Uint32;
    procedure set_blit_hw_CC(var a : SDL_VideoInfo; __blit_hw_CC : Uint32);

    { Flag: Accelerated blits with Alpha  }
    function blit_hw_A(var a : SDL_VideoInfo) : Uint32;
    procedure set_blit_hw_A(var a : SDL_VideoInfo; __blit_hw_A : Uint32);

    { Flag: Accelerated blits SW --> HW  }
    function blit_sw(var a : SDL_VideoInfo) : Uint32;
    procedure set_blit_sw(var a : SDL_VideoInfo; __blit_sw : Uint32);

    { Flag: Accelerated blits with Colorkey  }
    function blit_sw_CC(var a : SDL_VideoInfo) : Uint32;
    procedure set_blit_sw_CC(var a : SDL_VideoInfo; __blit_sw_CC : Uint32);

    { Flag: Accelerated blits with Alpha  }
    function blit_sw_A(var a : SDL_VideoInfo) : Uint32;
    procedure set_blit_sw_A(var a : SDL_VideoInfo; __blit_sw_A : Uint32);

    { Flag: Accelerated color fill  }
    function blit_fill(var a : SDL_VideoInfo) : Uint32;
    procedure set_blit_fill(var a : SDL_VideoInfo; __blit_fill : Uint32);
    function UnusedBits3(var a : SDL_VideoInfo) : Uint32;
    procedure set_UnusedBits3(var a : SDL_VideoInfo; __UnusedBits3 : Uint32);

    { Evaluates to true if the surface needs to be locked before access  }
    Function SDL_MUSTLOCK (surface: PSDL_Surface): Boolean ;

    { The most common video overlay formats.
      For an explanation of these pixel formats, see:
 	http://www.webartz.com/fourcc/indexyuv.htm
 
      For information on the relationship between color spaces, see:
      http://www.neuro.sfc.keio.ac.jp/~aly/polygon/info/color-space-faq.html
    }
    const
      SDL_YV12_OVERLAY=$32315659; { Planar mode: Y + V + U  (3 planes) }
      SDL_IYUV_OVERLAY=$56555949; { Planar mode: Y + U + V  (3 planes) }
      SDL_YUY2_OVERLAY=$32595559; { Packed mode: Y0+U0+Y1+V0 (1 plane) }
      SDL_UYVY_OVERLAY=$59565955; { Packed mode: U0+Y0+V0+Y1 (1 plane) }
      SDL_YVYU_OVERLAY=$55595659; { Packed mode: Y0+V0+Y1+U0 (1 plane) }

    { The YUV hardware video overlay }
    
    type
       TSDL_Plane = Array[0..0] of Uint8;
       PSDL_Plane = ^TSDL_Plane;
       TSDL_Overlay_PlaneArray = Array[0..0] of PSDL_Plane ;
       PSDL_Overlay_PlaneArray = ^TSDL_Overlay_PlaneArray ;
       
       pSDL_Overlay = ^SDL_Overlay;
       SDL_Overlay = record
            format: Uint32;                  { Read-only }
            w, h: Longint;                   { Read-only }
            planes: Longint;                 { Read-only }
            pitches: ^Uint16;                { Read-only }
            pixels: PSDL_Overlay_PlaneArray; { Read-write }
     
            { Hardware-specific surface info }
            hwfuncs: Pointer; { struct private_yuvhwfuncs * }
            hwdata: Pointer;  { struct private_yuvhwdata * }
     
            { Special flags }
            flag0: LongInt ;
         end ;

    { *** Accessors for the flags of SDL_Overlay *** }

    { Flag: This overlay hardware accelerated? }
    function hw_overlay (var o: SDL_Overlay): Uint32;
    procedure set_hw_overlay (var o: SDL_Overlay; value: Uint32);

    const
       SDL_GL_RED_SIZE = 0 ;
       SDL_GL_GREEN_SIZE = 1 ;
       SDL_GL_BLUE_SIZE = 2 ;
       SDL_GL_ALPHA_SIZE = 3 ;
       SDL_GL_BUFFER_SIZE = 4 ;
       SDL_GL_DOUBLEBUFFER = 5 ;
       SDL_GL_DEPTH_SIZE = 6 ;
       SDL_GL_STENCIL_SIZE = 7 ;
       SDL_GL_ACCUM_RED_SIZE = 8 ;
       SDL_GL_ACCUM_GREEN_SIZE = 9 ;
       SDL_GL_ACCUM_BLUE_SIZE = 10 ;
       SDL_GL_ACCUM_ALPHA_SIZE = 11 ;
    type
    { Public enumeration for setting the OpenGL window attributes. }
       SDL_GLattr = LongInt ;
    const
    { flags for SDL_SetPalette() }
       SDL_LOGPAL = $01;
       SDL_PHYSPAL = $02;

    { Function prototypes  }

    {
       These functions are used internally, and should not be used unless you
       have a specific need to specify the video driver you want to use.
       You should normally use SDL_Init or SDL_InitSubSystem.
      
       SDL_VideoInit initializes the video subsystem -- sets up a connection
       to the window manager, etc, and determines the current video mode and
       pixel format, but does not initialize a window or graphics mode.
       Note that event handling is activated by this routine.
      
       If you use both sound and video in your application, you need to call
       SDL_Init before opening the sound device, otherwise under Win32 DirectX,
       you won't be able to set full-screen display modes.
      }
    { SDL_VideoInit }
    { SDL_VideoQuit }
    { This function fills the given character buffer with the name of the
      video driver, and returns a pointer to it if the video driver has
      been initialized.  It returns nil if no driver has been initialized.
    }
    { SDL_VideoDriverName }

    {
       This function returns a pointer to the current display surface.
       If SDL is doing format conversion on the display surface, this
       function returns the publicly visible surface, not the real video
       surface.
    }

    function SDL_GetVideoSurface:PSDL_Surface;cdecl;

    {
       This function returns a read-only pointer to information about the
       video hardware.  If this is called before SDL_SetVideoMode(), the 'vfmt'
       member of the returned structure will contain the pixel format of the
       "best" video mode.
    }
    function SDL_GetVideoInfo:PSDL_VideoInfo;cdecl;

    { 
       Check to see if a particular video mode is supported.
       It returns 0 if the requested mode is not supported under any bit depth,
       or returns the bits-per-pixel of the closest available mode with the
       given width and height.  If this bits-per-pixel is different from the
       one used when setting the video mode, SDL_SetVideoMode will succeed,
       but will emulate the requested bits-per-pixel with a shadow surface.
      
       The arguments to SDL_VideoModeOK are the same ones you would pass to
       SDL_SetVideoMode
      }
    function SDL_VideoModeOK(width:longint; height:longint; bpp:longint; flags:Uint32):longint;cdecl;

    {
       Return a pointer to an array of available screen dimensions for the
       given format and video flags, sorted largest to smallest.  Returns 
       NULL if there are no dimensions available for a particular format, 
       or (SDL_Rect   )-1 if any dimension is okay for the given format.
      
       If 'format' is NULL, the mode list will be for the format given 
       by SDL_GetVideoInfo()->vfmt
    }
    function SDL_ListModes(format:pSDL_PixelFormat; flags:Uint32):PSDL_RectArray;cdecl;

    {
       Set up a video mode with the specified width, height and bits-per-pixel.
      
       If 'bpp' is 0, it is treated as the current display bits per pixel.
      
       If SDL_ANYFORMAT is set in 'flags', the SDL library will try to set the
       requested bits-per-pixel, but will return whatever video pixel format is
       available.  The default is to emulate the requested pixel format if it
       is not natively available.
      
       If SDL_HWSURFACE is set in 'flags', the video surface will be placed in
       video memory, if possible, and you may have to call SDL_LockSurface
       in order to access the raw framebuffer.  Otherwise, the video surface
       will be created in system memory.
       
       If SDL_ASYNCBLIT is set in 'flags', SDL will try to perform rectangle
       updates asynchronously, but you must always lock before accessing
       pixels.
       SDL will wait for updates to complete before returning from the lock.

       If SDL_HWPALETTE is set in 'flags', the SDL library will guarantee
       that the colors set by SDL_SetColors will be the colors you get.
       Otherwise, in 8-bit mode, SDL_SetColors may not be able to set all
       of the colors exactly the way they are requested, and you should look
       at the video surface structure to determine the actual palette.
       If SDL cannot guarantee that the colors you request can be set, 
       i.e. if the colormap is shared, then the video surface may be created
       under emulation in system memory, overriding the SDL_HWSURFACE flag.
      
       If SDL_FULLSCREEN is set in 'flags', the SDL library will try to set
       a fullscreen video mode.  The default is to create a windowed mode
       if the current graphics system has a window manager.
       If the SDL library is able to set a fullscreen video mode, this flag 
       will be set in the surface that is returned.
      
       If SDL_DOUBLEBUF is set in 'flags', the SDL library will try to set up
       two surfaces in video memory and swap between them when you call 
       SDL_Flip.  This is usually slower than the normal single-buffering
       scheme, but prevents "tearing" artifacts caused by modifying video 
       memory while the monitor is refreshing.  It should only be used by 
       applications that redraw the entire screen on every update.

       If SDL_RESIZABLE is set in 'flags', the SDL library will allow the
       window manager, if any, to resize the window at runtime. When this
       occurs, SDL will send a SDL_VIDEORESIZE event to your application,
       and you must respond to the event by re-calling SDL_SetVideoMode
       with the requested size (or another size that suits the application).
       
       If SDL_NOFRAME is set in 'flags', the SDL library will create a window
       without any title bar or frame decoration. Fullscreen video modes have
       this flag set automatically.
       
       This function returns the video framebuffer surface, or nil if it fails.
       
       If you rely on functionality provided by certain video flags, check the
       flags of the returned surface to make sure that functionality is
       available. SDL will fall back to reduced functionality if the exact
       flags you wanted are not available.
      }
    function SDL_SetVideoMode(width:longint; height:longint; bpp:longint; flags:Uint32):PSDL_Surface;cdecl;

    {
       Makes sure the given list of rectangles is updated on the given screen.
       If 'x', 'y', 'w' and 'h' are all 0, SDL_UpdateRect will update the entire
       screen.
       These functions should not be called while 'screen' is locked.
      }
    procedure SDL_UpdateRects(screen:pSDL_Surface; numrects:longint; var rects:SDL_RectArray);cdecl;

    procedure SDL_UpdateRect(screen:pSDL_Surface; x:Sint32; y:Sint32; w:Uint32; h:Uint32);cdecl;

    {
       On hardware that supports double-buffering, this function sets up a flip
       and returns.  The hardware will wait for vertical retrace, and then swap
       video buffers before the next video surface blit or lock will return.
       On hardware that doesn not support double-buffering, this is equivalent
       to calling SDL_UpdateRect(screen, 0, 0, 0, 0);
       The SDL_DOUBLEBUF flag must have been passed to SDL_SetVideoMode when
       setting the video mode for this function to perform hardware flipping.
       This function returns 0 if successful, or -1 if there was an error.
      }
    function SDL_Flip(screen:pSDL_Surface):longint;cdecl;

    { Set the gamma correction for each of the color channels.
      The gamma values range (approximately) between 0.1 and 10.0
      
      If this function isn't supported directly by the hardware, it will
      be emulated using gamma ramps, if available.  Iff successful, this
      function returns False.
    }
    function SDL_SetGamma (red, green, blue: Single): LongBool;cdecl;
    
    { Set the gamma translation table for the red, green, and blue channels
      of the video hardware.  Each table is an array of 256 16-bit quantities,
      representing a mapping between the input and output for that channel.
      The input is the index into the array, and the output is the 16-bit
      gamma value at that index, scaled to the output color precision.
      
      You may pass nil for any of the channels to leave it unchanged.
      If the call succeeds, it will return False.  If the display driver or
      hardware does not support gamma translation, or otherwise fails,
      this function will return True.
    }
    type
       TGammaRamp = array[Byte] of Word;
       PGammaRamp = ^TGammaRamp;
    function SDL_SetGammaRamp (red, green, blue: PGammaRamp): LongBool;cdecl;

    {
       Sets a portion of the colormap for the given 8-bit surface.  If 'surface'
       is not a palettized surface, this function does nothing, returning 0.
       If all of the colors were set as passed to SDL_SetColors, it will
       return 1.  If not all the color entries were set exactly as given,
       it will return 0, and you should look at the surface palette to
       determine the actual color palette.
      
       When 'surface' is the surface associated with the current display, the
       display colormap will be updated with the requested colors.  If 
       SDL_HWPALETTE was set in SDL_SetVideoMode flags, SDL_SetColors
       will always return 1, and the palette is guaranteed to be set the way
       you desire, even if the window colormap has to be warped or run under
       emulation.
      }
    function SDL_SetColors(surface:pSDL_Surface; var colors:SDL_ColorArray; firstcolor:longint; ncolors:longint):longint;cdecl;

    {
      Sets a portion of the colormap for a given 8-bit surface.
      'flags' is one or both of:
      SDL_LOGPAL  -- set logical palette, which controls how blits are mapped
                     to/from the surface,
      SDL_PHYSPAL -- set physical palette, which controls how pixels look on
                     the screen
      Only screens have physical palettes. Separate change of physical/logical
      palettes is only possible if the screen has SDL_HWPALETTE set.
     
      The return value is True iff all colours could be set as requested.
     
      SDL_SetColors is equivalent to calling this function with
          flags = (SDL_LOGPAL|SDL_PHYSPAL).
    }
    function SDL_SetPalette(surface:pSDL_Surface; flags: Longint; var colors:SDL_ColorArray; firstcolor:longint; ncolors:longint):longBool;cdecl;
    
    {
       Maps an RGB triple to an opaque pixel value for a given pixel format
    }
    function SDL_MapRGB(format:pSDL_PixelFormat; r, g, b:Uint8):Uint32;cdecl;

    {
       Maps an RGBA quadruple to a pixel value for a given pixel format
    }
    function SDL_MapRGBA(format:pSDL_PixelFormat; r, g, b, a:Uint8):Uint32;cdecl;
    
    {
       Maps a pixel value into the RGB components for a given pixel format
    }
    procedure SDL_GetRGB(pixel:Uint32; fmt:pSDL_PixelFormat; var r,g,b:Uint8);cdecl;

    {
       Maps a pixel value into the RGBA components for a given pixel format
    }
    procedure SDL_GetRGBA(pixel:Uint32; fmt:pSDL_PixelFormat; var r,g,b,a:Uint8);cdecl;

    {
       Allocate and free an RGB surface (must be called after SDL_SetVideoMode)
       If the depth is 4 or 8 bits, an empty palette is allocated for the surface.
       If the depth is greater than 8 bits, the pixel format is set using the
       flags '[RGB]mask'.
       If the function runs out of memory, it will return nil.
      
       The 'flags' tell what kind of surface to create.
       SDL_SWSURFACE means that the surface should be created in system memory.
       SDL_HWSURFACE means that the surface should be created in video memory,
       with the same format as the display surface.  This is useful for surfaces
       that will not change much, to take advantage of hardware acceleration
       when being blitted to the display surface.
       SDL_ASYNCBLIT means that SDL will try to perform asynchronous blits with
       this surface, but you must always lock it before accessing the pixels.
       SDL will wait for current blits to finish before returning from the lock.
       SDL_SRCCOLORKEY indicates that the surface will be used for colorkey blits.
       If the hardware supports acceleration of colorkey blits between
       two surfaces in video memory, SDL will try to place the surface in
       video memory. If this isn't possible or if there is no hardware
       acceleration available, the surface will be placed in system memory.
       SDL_SRCALPHA means that the surface will be used for alpha blits and 
       if the hardware supports hardware acceleration of alpha blits between
       two surfaces in video memory, to place the surface in video memory
       if possible, otherwise it will be placed in system memory.
       If the surface is created in video memory, blits will be _much_ faster,
       but the surface format must be identical to the video surface format,
       and the only way to access the pixels member of the surface is to use
       the SDL_LockSurface and SDL_UnlockSurface calls.
       If the requested surface actually resides in video memory, SDL_HWSURFACE
       will be set in the flags member of the returned surface.  If for some
       reason the surface could not be placed in video memory, it will not have
       the SDL_HWSURFACE flag set, but will be created in system memory instead
      }


    function SDL_CreateRGBSurface(flags:Uint32; width:longint; height:longint; depth:longint; Rmask:Uint32;
               Gmask:Uint32; Bmask:Uint32; Amask:Uint32):PSDL_Surface;cdecl;

    { This is an alias for SDL_CreateRGBSurface}
    function SDL_AllocSurface(flags:Uint32; width:longint; height:longint; depth:longint; Rmask:Uint32;
               Gmask:Uint32; Bmask:Uint32; Amask:Uint32):PSDL_Surface;

    function SDL_CreateRGBSurfaceFrom(pixels:pointer; width:longint; height:longint; depth:longint; pitch:longint;
               Rmask:Uint32; Gmask:Uint32; Bmask:Uint32; Amask:Uint32):PSDL_Surface;cdecl;

    procedure SDL_FreeSurface(surface:pSDL_Surface);cdecl;

    {
       SDL_LockSurface sets up a surface for directly accessing the pixels.
       Between calls to SDL_LockSurface/SDL_UnlockSurface, you can write
       to and read from 'surface->pixels', using the pixel format stored in 
       'surface->format'.  Once you are done accessing the surface, you should 
       use SDL_UnlockSurface to release it.
      
       Not all surfaces require locking.  If SDL_MUSTLOCK(surface) evaluates
       to 0, then you can read and write to the surface at any time, and the
       pixel format of the surface will not change.  In particular, if the
       SDL_HWSURFACE flag is not given when calling SDL_SetVideoMode, you
       will not need to lock the display surface before accessing it.
       
       No operating system or library calls should be made between lock/unlock
       pairs, as critical system locks may be held during this time.
      
       SDL_LockSurface returns 0, or -1 if the surface couldn't be locked.
      }
    function SDL_LockSurface(surface:pSDL_Surface):longint;cdecl;

    procedure SDL_UnlockSurface(surface:pSDL_Surface);cdecl;

    {
       Load a surface from a seekable SDL data source (memory or file.)
       If 'freesrc' is True, the source will be closed after being read.
       Returns the new surface, or nil if there was an error.
       The new surface should be freed with SDL_FreeSurface.
      }
    function SDL_LoadBMP_RW(src:pSDL_RWops; freesrc:LongBool):PSDL_Surface;cdecl;

    { Convenience macro -- load a surface from a file  }
    function SDL_LoadBMP(filename:PChar) : PSDL_Surface;

    {
       Save a surface to a seekable SDL data source (memory or file.)
       If 'freedst' is True, the source will be closed after being written.
       Returns 0 if successful or -1 if there was an error.
      }
    function SDL_SaveBMP_RW(surface:pSDL_Surface; dst:pSDL_RWops; freedst:LongBool):longint;cdecl;

    { Convenience macro -- save a surface to a file  }
    function SDL_SaveBMP(surface: pSDL_Surface;filename:PChar) : longint;

    {
       Sets the color key (transparent pixel) in a blittable surface.
       If 'flag' is SDL_SRCCOLORKEY (optionally OR'd with SDL_RLEACCEL), 
       'key' will be the transparent pixel in the source image of a blit.
       SDL_RLEACCEL requests RLE acceleration for the surface if present,
       and removes RLE acceleration if absent.
       If 'flag' is 0, this function clears any current color key.
       This function returns 0, or -1 if there was an error.
      }
    function SDL_SetColorKey(surface:pSDL_Surface; flag:Uint32; key:Uint32):longint;cdecl;

    {
       This function sets the alpha value for the entire surface, as opposed to
       using the alpha component of each pixel. This value measures the range
       of transparency of the surface, 0 being completely transparent to 255
       being completely opaque. An 'alpha' value of 255 causes blits to be
       opaque, the source pixels copied to the destination (the default). Note
       that per-surface alpha can be combined with colorkey transparency.

       If 'flag' is 0, alpha blending is disabled for the surface.
       If 'flag' is SDL_SRCALPHA, alpha blending is enabled for the surface.
       OR:ing the flag with SDL_RLEACCEL requests RLE acceleration for the
       surface; if SDL_RLEACCEL is not specified, the RLE accel will be removed.
    }
    function SDL_SetAlpha(surface:pSDL_Surface; flag:Uint32; alpha:Uint8):longint;cdecl;

    {
       Sets the clipping rectangle for the destination surface in a blit.
      
       If the clip rectangle is nil, clipping will be disabled.
       If the clip rectangle doesn't intersect the surface, the function will
       return False and blits will be completely clipped.  Otherwise the
       function returns True and blits to the surface will be clipped to
       the intersection of the surface area and the clipping rectangle.
      
       Note that blits are automatically clipped to the edges of the source
       and destination surfaces.
    }
    function SDL_SetClipRect(surface:pSDL_Surface; rect:pSDL_Rect): SDL_Bool;cdecl;

    {
       Gets the clipping rectangle for the destination surface in a blit.
       'rect' will be filled with the correct values.
    }
    procedure SDL_GetClipRect(surface: pSDL_Surface; var rect: SDL_Rect);cdecl;

    {
       Creates a new surface of the specified format, and then copies and maps 
       the given surface to it so the blit of the converted surface will be as 
       fast as possible.  If this function fails, it returns nil.
      
       The 'flags' parameter is passed to SDL_CreateRGBSurface and has those 
       semantics. You can also pass SDL_RLEACCEL in the flags parameter and
       SDL will try to RLE accelerate colorkey and alpha blits in the resulting
       surface.
      
       This function is used internally by SDL_DisplayFormat.
      }
    function SDL_ConvertSurface(src:pSDL_Surface; fmt:pSDL_PixelFormat; flags:Uint32):PSDL_Surface;cdecl;

    {
       This performs a fast blit from the source surface to the destination
       surface.  It assumes that the source and destination rectangles are
       the same size.  If either 'srcrect' or 'dstrect' are nil, the entire
       surface (src or dst) is copied.  The final blit rectangles are saved
       in 'srcrect' and 'dstrect' after all clipping is performed.
       If the blit is successful, it returns 0, otherwise it returns -1.
      
       The blit function should not be called on a locked surface.
      
       The blit semantics for surfaces with and without alpha and colorkey
       are defined as follows:
       
       RGBA->RGB:
           SDL_SRCALPHA set:
           alpha-blend (using alpha-channel).
           SDL_SRCCOLORKEY ignored.
           SDL_SRCALPHA not set:
       	   copy RGB.
       	   if SDL_SRCCOLORKEY set, only copy the pixels matching the
       	   RGB values of the source colour key, ignoring alpha in the
       	   comparison.
       
       RGB->RGBA:
           SDL_SRCALPHA set:
       	   alpha-blend (using the source per-surface alpha value);
       	   set destination alpha to opaque.
           SDL_SRCALPHA not set:
       	   copy RGB, set destination alpha to opaque.
           both:
       	   if SDL_SRCCOLORKEY set, only copy the pixels matching the
       	   source colour key.
       
       RGBA->RGBA:
           SDL_SRCALPHA set:
       	   alpha-blend (using the source alpha channel) the RGB values;
       	   leave destination alpha untouched. [Note: is this correct?]
       	   SDL_SRCCOLORKEY ignored.
           SDL_SRCALPHA not set:
       	   copy all of RGBA to the destination.
       	   if SDL_SRCCOLORKEY set, only copy the pixels matching the
       	   RGB values of the source colour key, ignoring alpha in the
       	   comparison.
        
       RGB->RGB: 
           SDL_SRCALPHA set:
        	alpha-blend (using the source per-surface alpha value).
           SDL_SRCALPHA not set:
       	   copy RGB.
           both:
       	   if SDL_SRCCOLORKEY set, only copy the pixels matching the
           source colour key.

       If either of the surfaces were in video memory, and the blit returns -2,
       the video memory was lost, so it should be reloaded with artwork and 
       re-blitted:
       
       while SDL_BlitSurface(image, imgrect, screen, dstrect) = -2 do
       Begin
          while SDL_LockSurface(image) < 0 do
             Sleep(10);
          -- Write image pixels to image->pixels --
          SDL_UnlockSurface(image);
       End;

       This happens under DirectX 5.0 when the system switches away from your
       fullscreen application.  The lock will also fail until you have access
       to the video memory again.
    }

    { You should call SDL_BlitSurface unless you know exactly how SDL
       blitting works internally and how to use the other blit functions.
     }

    function SDL_BlitSurface(src:pSDL_Surface; srcrect:pSDL_Rect; dst:pSDL_Surface; dstrect:pSDL_Rect):longint;

    { This is the public blit function, SDL_BlitSurface, and it performs
       rectangle validation and clipping before passing it to SDL_LowerBlit
     }

    function SDL_UpperBlit(src:pSDL_Surface; srcrect:pSDL_Rect; dst:pSDL_Surface; dstrect:pSDL_Rect):longint;cdecl;

    { This is a semi-private blit function and it performs low-level surface
       blitting only.
     }
    function SDL_LowerBlit(src:pSDL_Surface; srcrect:pSDL_Rect; dst:pSDL_Surface; dstrect:pSDL_Rect):longint;cdecl;

    {
       This function performs a fast fill of the given rectangle with 'color'
       The given rectangle is clipped to the destination surface clip area
       and the final fill rectangle is saved in the passed in pointer.
       If 'dstrect' is nil, the whole surface will be filled with 'color'
       The color should be a pixel of the format used by the surface, and 
       can be generated by the SDL_MapRGB() function.
       This function returns 0 on success, or -1 on error.
      }
    function SDL_FillRect(dst:pSDL_Surface; dstrect:pSDL_Rect; color:Uint32):longint;cdecl;

    { 
       This function takes a surface and copies it to a new surface of the
       pixel format and colors of the video framebuffer, suitable for fast
       blitting onto the display surface.  It calls SDL_ConvertSurface
      
       If you want to take advantage of hardware colorkey or alpha blit
       acceleration, you should set the colorkey and alpha value before
       calling this function.
      
       If the conversion fails or runs out of memory, it returns nil
      }
    function SDL_DisplayFormat(surface:pSDL_Surface):PSDL_Surface;cdecl;

    { 
       This function takes a surface and copies it to a new surface of the
       pixel format and colors of the video framebuffer (if possible),
       suitable for fast alpha blitting onto the display surface.
       The new surface will always have an alpha channel.
       
       If you want to take advantage of hardware colorkey or alpha blit
       acceleration, you should set the colorkey and alpha value before
       calling this function.
       
       If the conversion fails or runs out of memory, it returns nil
    }
    function SDL_DisplayFormatAlpha(surface:pSDL_Surface):pSDL_Surface;cdecl;

    { * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * }
    { * YUV video surface overlay functions                                 * }
    { * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * }
 
    { This function creates a video output overlay
      Calling the returned surface an overlay is something of a misnomer because
      the contents of the display surface underneath the area where the overlay
      is shown is undefined - it may be overwritten with the converted YUV data.
    }
    function SDL_CreateYUVOverlay (width, height: Longint; format: Uint32;
                                   display: pSDL_Surface): pSDL_Overlay;cdecl;  
 
    { Lock an overlay for direct access, and unlock it when you are done }
    function SDL_LockYUVOverlay(var overlay: SDL_Overlay):Longint;cdecl;
    procedure SDL_UnlockYUVOverlay(var overlay: SDL_Overlay);cdecl;

    { Blit a video overlay to the display surface.
      The contents of the video surface underneath the blit destination are
      not defined.  
      The width and height of the destination rectangle may be different from
      that of the overlay, but currently only 2x scaling is supported.
    }
    function SDL_DisplayYUVOverlay(var overlay:SDL_Overlay; var dstrect: SDL_Rect):Longint;cdecl;

    { Free a video overlay }
    procedure SDL_FreeYUVOverlay(var overlay: SDL_Overlay);cdecl;

    { * * * * * * * * * * * *  * * * * * * * * * * * * * * * * * * * * * * * }
    { * OpenGL support functions.                                          * }
    { * * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * }

    { Dynamically load a GL driver, if SDL is built with dynamic GL.
 
      SDL links normally with the OpenGL library on your system by default,
      but you can compile it to dynamically load the GL driver at runtime.
      If you do this, you need to retrieve all of the GL functions used in
      your program from the dynamic library using SDL_GL_GetProcAddress().

      This is disabled in default builds of SDL.
    }
    function SDL_GL_LoadLibrary(path: PChar):Longint;cdecl;

    { Get the address of a GL function (for extension functions) }
    procedure SDL_GL_GetProcAddress(proc: PChar);cdecl;

    { Set an attribute of the OpenGL subsystem before intialization. }
    function SDL_GL_SetAttribute(attr: SDL_GLattr; value: Longint):Longint;cdecl;

    { Get an attribute of the OpenGL subsystem from the windowing
      interface, such as glX. This is of course different from getting
      the values from SDL's internal OpenGL subsystem, which only
      stores the values you request before initialization.

      Developers should track the values they pass into SDL_GL_SetAttribute
      themselves if they want to retrieve these values.
    }
    function SDL_GL_GetAttribute (attr: SDL_GLattr; var value: Longint):Longint;cdecl;

    { Swap the OpenGL buffers, if double-buffering is supported. }
    Procedure SDL_GL_SwapBuffers; cdecl;

    {
      Internal functions that should not be called unless you have read
      and understood the source code for these functions.
    }
    {extern DECLSPEC void SDL_GL_UpdateRects(int numrects, SDL_Rect* rects);
    extern DECLSPEC void SDL_GL_Lock(void);
    extern DECLSPEC void SDL_GL_Unlock(void);}

    { These functions allow interaction with the window manager, if any.         }

    {
       Sets/Gets the title and icon text of the display window
    }
    procedure SDL_WM_SetCaption(title:pchar; icon:pchar);cdecl;
    procedure SDL_WM_GetCaption(title:ppchar; icon:ppchar);cdecl;

    {
       Sets the icon for the display window.
       This function must be called before the first call to SDL_SetVideoMode.
       It takes an icon surface, and a mask in MSB format.
       If 'mask' is nil, the entire icon surface will be used as the icon.
      }
    procedure SDL_WM_SetIcon(icon:pSDL_Surface; mask:pByte);cdecl;

  implementation

    { *** masks for implementing the bit fields accesors of SDL_VideoInfo *** }
    const
       bm_SDL_VideoInfo_hw_available = $1;
       bp_SDL_VideoInfo_hw_available = 0;
       bm_SDL_VideoInfo_wm_available = $2;
       bp_SDL_VideoInfo_wm_available = 1;
       bm_SDL_VideoInfo_UnusedBits1 = $FC;
       bp_SDL_VideoInfo_UnusedBits1 = 2;
       bm_SDL_VideoInfo_UnusedBits2 = $100;
       bp_SDL_VideoInfo_UnusedBits2 = 8;
       bm_SDL_VideoInfo_blit_hw = $200;
       bp_SDL_VideoInfo_blit_hw = 9;
       bm_SDL_VideoInfo_blit_hw_CC = $400;
       bp_SDL_VideoInfo_blit_hw_CC = 10;
       bm_SDL_VideoInfo_blit_hw_A = $800;
       bp_SDL_VideoInfo_blit_hw_A = 11;
       bm_SDL_VideoInfo_blit_sw = $1000;
       bp_SDL_VideoInfo_blit_sw = 12;
       bm_SDL_VideoInfo_blit_sw_CC = $2000;
       bp_SDL_VideoInfo_blit_sw_CC = 13;
       bm_SDL_VideoInfo_blit_sw_A = $4000;
       bp_SDL_VideoInfo_blit_sw_A = 14;
       bm_SDL_VideoInfo_blit_fill = $8000;
       bp_SDL_VideoInfo_blit_fill = 15;
       bm_SDL_VideoInfo_UnusedBits3 = $FFFF0000;
       bp_SDL_VideoInfo_UnusedBits3 = 16;

    { *** bit fields accesors of SDL_VideoInfo *** }
    function hw_available(var a : SDL_VideoInfo) : Uint32;
      begin
         hw_available:=(a.flag0 and bm_SDL_VideoInfo_hw_available) shr bp_SDL_VideoInfo_hw_available;
      end;

    procedure set_hw_available(var a : SDL_VideoInfo; __hw_available : Uint32);
      begin
         a.flag0:=a.flag0 or ((__hw_available shl bp_SDL_VideoInfo_hw_available) and bm_SDL_VideoInfo_hw_available);
      end;

    function wm_available(var a : SDL_VideoInfo) : Uint32;
      begin
         wm_available:=(a.flag0 and bm_SDL_VideoInfo_wm_available) shr bp_SDL_VideoInfo_wm_available;
      end;

    procedure set_wm_available(var a : SDL_VideoInfo; __wm_available : Uint32);
      begin
         a.flag0:=a.flag0 or ((__wm_available shl bp_SDL_VideoInfo_wm_available) and bm_SDL_VideoInfo_wm_available);
      end;

    function UnusedBits1(var a : SDL_VideoInfo) : Uint32;
      begin
         UnusedBits1:=(a.flag0 and bm_SDL_VideoInfo_UnusedBits1) shr bp_SDL_VideoInfo_UnusedBits1;
      end;

    procedure set_UnusedBits1(var a : SDL_VideoInfo; __UnusedBits1 : Uint32);
      begin
         a.flag0:=a.flag0 or ((__UnusedBits1 shl bp_SDL_VideoInfo_UnusedBits1) and bm_SDL_VideoInfo_UnusedBits1);
      end;

    function UnusedBits2(var a : SDL_VideoInfo) : Uint32;
      begin
         UnusedBits2:=(a.flag0 and bm_SDL_VideoInfo_UnusedBits2) shr bp_SDL_VideoInfo_UnusedBits2;
      end;

    procedure set_UnusedBits2(var a : SDL_VideoInfo; __UnusedBits2 : Uint32);
      begin
         a.flag0:=a.flag0 or ((__UnusedBits2 shl bp_SDL_VideoInfo_UnusedBits2) and bm_SDL_VideoInfo_UnusedBits2);
      end;

    function blit_hw(var a : SDL_VideoInfo) : Uint32;
      begin
         blit_hw:=(a.flag0 and bm_SDL_VideoInfo_blit_hw) shr bp_SDL_VideoInfo_blit_hw;
      end;

    procedure set_blit_hw(var a : SDL_VideoInfo; __blit_hw : Uint32);
      begin
         a.flag0:=a.flag0 or ((__blit_hw shl bp_SDL_VideoInfo_blit_hw) and bm_SDL_VideoInfo_blit_hw);
      end;

    function blit_hw_CC(var a : SDL_VideoInfo) : Uint32;
      begin
         blit_hw_CC:=(a.flag0 and bm_SDL_VideoInfo_blit_hw_CC) shr bp_SDL_VideoInfo_blit_hw_CC;
      end;

    procedure set_blit_hw_CC(var a : SDL_VideoInfo; __blit_hw_CC : Uint32);
      begin
         a.flag0:=a.flag0 or ((__blit_hw_CC shl bp_SDL_VideoInfo_blit_hw_CC) and bm_SDL_VideoInfo_blit_hw_CC);
      end;

    function blit_hw_A(var a : SDL_VideoInfo) : Uint32;
      begin
         blit_hw_A:=(a.flag0 and bm_SDL_VideoInfo_blit_hw_A) shr bp_SDL_VideoInfo_blit_hw_A;
      end;

    procedure set_blit_hw_A(var a : SDL_VideoInfo; __blit_hw_A : Uint32);
      begin
         a.flag0:=a.flag0 or ((__blit_hw_A shl bp_SDL_VideoInfo_blit_hw_A) and bm_SDL_VideoInfo_blit_hw_A);
      end;

    function blit_sw(var a : SDL_VideoInfo) : Uint32;
      begin
         blit_sw:=(a.flag0 and bm_SDL_VideoInfo_blit_sw) shr bp_SDL_VideoInfo_blit_sw;
      end;

    procedure set_blit_sw(var a : SDL_VideoInfo; __blit_sw : Uint32);
      begin
         a.flag0:=a.flag0 or ((__blit_sw shl bp_SDL_VideoInfo_blit_sw) and bm_SDL_VideoInfo_blit_sw);
      end;

    function blit_sw_CC(var a : SDL_VideoInfo) : Uint32;
      begin
         blit_sw_CC:=(a.flag0 and bm_SDL_VideoInfo_blit_sw_CC) shr bp_SDL_VideoInfo_blit_sw_CC;
      end;

    procedure set_blit_sw_CC(var a : SDL_VideoInfo; __blit_sw_CC : Uint32);
      begin
         a.flag0:=a.flag0 or ((__blit_sw_CC shl bp_SDL_VideoInfo_blit_sw_CC) and bm_SDL_VideoInfo_blit_sw_CC);
      end;

    function blit_sw_A(var a : SDL_VideoInfo) : Uint32;
      begin
         blit_sw_A:=(a.flag0 and bm_SDL_VideoInfo_blit_sw_A) shr bp_SDL_VideoInfo_blit_sw_A;
      end;

    procedure set_blit_sw_A(var a : SDL_VideoInfo; __blit_sw_A : Uint32);
      begin
         a.flag0:=a.flag0 or ((__blit_sw_A shl bp_SDL_VideoInfo_blit_sw_A) and bm_SDL_VideoInfo_blit_sw_A);
      end;

    function blit_fill(var a : SDL_VideoInfo) : Uint32;
      begin
         blit_fill:=(a.flag0 and bm_SDL_VideoInfo_blit_fill) shr bp_SDL_VideoInfo_blit_fill;
      end;

    procedure set_blit_fill(var a : SDL_VideoInfo; __blit_fill : Uint32);
      begin
         a.flag0:=a.flag0 or ((__blit_fill shl bp_SDL_VideoInfo_blit_fill) and bm_SDL_VideoInfo_blit_fill);
      end;

    function UnusedBits3(var a : SDL_VideoInfo) : Uint32;
      begin
         UnusedBits3:=(a.flag0 and bm_SDL_VideoInfo_UnusedBits3) shr bp_SDL_VideoInfo_UnusedBits3;
      end;

    procedure set_UnusedBits3(var a : SDL_VideoInfo; __UnusedBits3 : Uint32);
      begin
         a.flag0:=a.flag0 or ((__UnusedBits3 shl bp_SDL_VideoInfo_UnusedBits3) and bm_SDL_VideoInfo_UnusedBits3);
      end;

    { *** masks for implementing the bit fields accesors of SDL_Overlay *** }
    const
       bm_SDL_Overlay_hw_overlay = $1;
       bp_SDL_Overlay_hw_overlay = 0;

    { *** bit fields accesors of SDL_Overlay *** }
    function hw_overlay (var o: SDL_Overlay): Uint32;
    Begin
       hw_overlay := (o.flag0 and bm_SDL_Overlay_hw_overlay) shr bp_SDL_Overlay_hw_overlay ;
    End;

    procedure set_hw_overlay (var o: SDL_Overlay; value: Uint32);
    Begin
       o.flag0 := o.flag0 or ( (value shl bp_SDL_Overlay_hw_overlay) and bm_SDL_Overlay_hw_overlay) ;
    End;    

    function SDL_GetVideoSurface:PSDL_Surface;cdecl;external 'SDL';

    function SDL_GetVideoInfo:PSDL_VideoInfo;cdecl;external 'SDL';

    function SDL_VideoModeOK(width:longint; height:longint; bpp:longint; flags:Uint32):longint;cdecl;external 'SDL';

    function SDL_ListModes(format:pSDL_PixelFormat; flags:Uint32):PSDL_RectArray;cdecl;external 'SDL';

    function SDL_SetVideoMode(width:longint; height:longint; bpp:longint; flags:Uint32):PSDL_Surface;cdecl;external 'SDL';

    procedure SDL_UpdateRects(screen:pSDL_Surface; numrects:longint; var rects:SDL_RectArray);cdecl;external 'SDL';

    procedure SDL_UpdateRect(screen:pSDL_Surface; x:Sint32; y:Sint32; w:Uint32; h:Uint32);cdecl;external 'SDL';

    function SDL_Flip(screen:pSDL_Surface):longint;cdecl;external 'SDL';

    function SDL_SetGamma (red, green, blue: Single): LongBool;cdecl;external 'SDL';

    function SDL_SetGammaRamp (red, green, blue: PGammaRamp): LongBool;cdecl;external 'SDL';

    function SDL_SetColors(surface:pSDL_Surface; var colors:SDL_ColorArray; firstcolor:longint; ncolors:longint):longint;cdecl;external 'SDL';

    function SDL_SetPalette(surface:pSDL_Surface; flags: Longint; var colors:SDL_ColorArray; firstcolor:longint; ncolors:longint):longBool;cdecl;external 'SDL';

    function SDL_MapRGB(format:pSDL_PixelFormat; r:Uint8; g:Uint8; b:Uint8):Uint32;cdecl;external 'SDL';

    function SDL_MapRGBA(format:pSDL_PixelFormat; r, g, b, a:Uint8):Uint32;cdecl;external 'SDL';

    procedure SDL_GetRGB(pixel:Uint32; fmt:pSDL_PixelFormat; var r,g,b:Uint8);cdecl;external 'SDL';

    procedure SDL_GetRGBA(pixel:Uint32; fmt:pSDL_PixelFormat; var r,g,b,a:Uint8);cdecl;external 'SDL';

    function SDL_CreateRGBSurface(flags:Uint32; width:longint; height:longint; depth:longint; Rmask:Uint32;
               Gmask:Uint32; Bmask:Uint32; Amask:Uint32):PSDL_Surface;cdecl;external 'SDL';

    function SDL_CreateRGBSurfaceFrom(pixels:pointer; width:longint; height:longint; depth:longint; pitch:longint;
               Rmask:Uint32; Gmask:Uint32; Bmask:Uint32; Amask:Uint32):PSDL_Surface;cdecl;external 'SDL';

    procedure SDL_FreeSurface(surface:pSDL_Surface);cdecl;external 'SDL';

    function SDL_LockSurface(surface:pSDL_Surface):longint;cdecl;external 'SDL';

    procedure SDL_UnlockSurface(surface:pSDL_Surface);cdecl;external 'SDL';

    function SDL_LoadBMP_RW(src:pSDL_RWops; freesrc:LongBool):PSDL_Surface;cdecl;external 'SDL';

    function SDL_SaveBMP_RW(surface:pSDL_Surface; dst:pSDL_RWops; freedst:LongBool):longint;cdecl;external 'SDL';

    function SDL_SetColorKey(surface:pSDL_Surface; flag:Uint32; key:Uint32):longint;cdecl;external 'SDL';

    function SDL_SetAlpha(surface:pSDL_Surface; flag:Uint32; alpha:Uint8):longint;cdecl;external 'SDL';

    function SDL_SetClipRect(surface:pSDL_Surface; rect:pSDL_Rect): SDL_Bool;cdecl;external 'SDL';

    procedure SDL_GetClipRect(surface: pSDL_Surface; var rect: SDL_Rect);cdecl;external 'SDL';

    function SDL_ConvertSurface(src:pSDL_Surface; fmt:pSDL_PixelFormat; flags:Uint32):PSDL_Surface;cdecl;external 'SDL';

    function SDL_UpperBlit(src:pSDL_Surface; srcrect:pSDL_Rect; dst:pSDL_Surface; dstrect:pSDL_Rect):longint;cdecl;external 'SDL';

    function SDL_LowerBlit(src:pSDL_Surface; srcrect:pSDL_Rect; dst:pSDL_Surface; dstrect:pSDL_Rect):longint;cdecl;external 'SDL';

    function SDL_FillRect(dst:pSDL_Surface; dstrect:pSDL_Rect; color:Uint32):longint;cdecl;external 'SDL';

    function SDL_DisplayFormat(surface:pSDL_Surface):PSDL_Surface;cdecl;external 'SDL';

    function SDL_DisplayFormatAlpha(surface:pSDL_Surface):pSDL_Surface;cdecl; external 'SDL';

    function SDL_CreateYUVOverlay (width, height: Longint; format: Uint32;
                                   display: pSDL_Surface): pSDL_Overlay;cdecl;external 'SDL';

    function SDL_LockYUVOverlay(var overlay: SDL_Overlay):Longint;cdecl;external 'SDL';

    procedure SDL_UnlockYUVOverlay(var overlay: SDL_Overlay);cdecl;external 'SDL';

    function SDL_DisplayYUVOverlay(var overlay:SDL_Overlay; var dstrect: SDL_Rect):Longint;cdecl;external 'SDL';

    procedure SDL_FreeYUVOverlay(var overlay: SDL_Overlay);cdecl;external 'SDL';

    function SDL_GL_LoadLibrary(path: PChar):Longint;cdecl;external 'SDL';

    procedure SDL_GL_GetProcAddress(proc: PChar);cdecl;external 'SDL';

    function SDL_GL_SetAttribute(attr: SDL_GLattr; value: Longint):Longint;cdecl;external 'SDL';

    function SDL_GL_GetAttribute (attr: SDL_GLattr; var value: Longint):Longint;cdecl; external 'SDL';

    Procedure SDL_GL_SwapBuffers; cdecl; external 'SDL';

    procedure SDL_WM_SetCaption(title:pchar; icon:pchar);cdecl;external 'SDL';

    procedure SDL_WM_GetCaption(title:ppchar; icon:ppchar);cdecl;external 'SDL';

    procedure SDL_WM_SetIcon(icon:pSDL_Surface; mask:pByte);cdecl;external 'SDL';

    { Macro }
    Function SDL_MUSTLOCK (surface: PSDL_Surface): Boolean ;
    Begin
      SDL_MUSTLOCK := (surface^.offset<>0) or
         ((surface^.flags and (SDL_HWSURFACE or SDL_ASYNCBLIT or SDL_RLEACCEL)) <>0)
    End ;

    {alias for SDL_CreateRGBSurface}
    function SDL_AllocSurface(flags:Uint32; width:longint; height:longint; depth:longint; Rmask:Uint32; 
               Gmask:Uint32; Bmask:Uint32; Amask:Uint32):PSDL_Surface;
    Begin
      SDL_AllocSurface := SDL_CreateRGBSurface (flags, width, height,
               depth, Rmask, Gmask, Bmask, Amask);
    End;

    {convenience macros}
    function SDL_LoadBMP(filename:PChar) : PSDL_Surface;
    Begin
       SDL_LoadBMP := SDL_LoadBMP_RW (SDL_RWFromFile(filename, 'rb'), True)
    End;

    function SDL_SaveBMP(surface: pSDL_Surface;filename:PChar) : longint;
    begin
      SDL_SaveBMP := SDL_SaveBMP_RW(surface,SDL_RWFromFile(filename,'wb'), True);
    end;

    { alias for SDL_UpperBlit }
    function SDL_BlitSurface(src:pSDL_Surface; srcrect:pSDL_Rect; dst:pSDL_Surface; dstrect:pSDL_Rect):longint;
    Begin
       SDL_BlitSurface := SDL_UpperBlit(src, srcrect, dst, dstrect)
    End ;

end.
