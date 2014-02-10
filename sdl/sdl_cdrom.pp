unit SDL_cdrom;

{  Automatically converted by H2PAS.EXE from SDL_cdrom.h
   Utility made by Florian Klaempfl 25th-28th september 96
   Improvements made by Mark A. Malakanov 22nd-25th may 97 
   Further improvements by Michael Van Canneyt, April 1998 
   define handling and error recovery by Pierre Muller, June 1998 }


  interface

  uses SDL_types ;

  { C default packing is dword }

{$PACKRECORDS 4}

 { Pointers to basic pascal types, inserted by h2pas conversion program.}
  Type
     PLongint  = ^Longint;
     PByte     = ^Byte;
     PWord     = ^Word;
     PInteger  = ^Integer;
     PCardinal = ^Cardinal;
     PReal     = ^Real;
     PDouble   = ^Double;

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

  { This is the CD-audio control API for Simple DirectMedia Layer  }

  { In order to use these functions, SDL_Init must have been called
     with the SDL_INIT_CDROM flag.  This causes SDL to scan the system
     for CD-ROM drives, and load appropriate drivers.
   }
  { The maximum number of CD-ROM tracks on a disk  }

  const
     SDL_MAX_TRACKS = 99;
  { The types of CD-ROM track possible  }
     SDL_AUDIO_TRACK = $00;
     SDL_DATA_TRACK = $04;
  { The possible states which a CD-ROM drive can be in.  }

  type

     CDstatus =  Longint;
       Const
       CD_TRAYEMPTY = 0;
       CD_STOPPED = 1;
       CD_PLAYING = 2;
       CD_PAUSED = 3;
       CD_ERROR = -(1);

  { Given a status, returns true if there's a disk in the drive  }
  function CD_INDRIVE(status : longint) : longBool;

  type

     SDL_CDtrack = record
          id : Uint8;         { Track number  }
          track_type : Uint8; { Data or audio track  }
          unused: Uint16;
          length : Uint32;    { Length, in frames, of this track  }
          offset : Uint32;    { Offset, in frames, from start of disk  }
       end;
  { This structure is only current as of the last call to SDL_CDStatus  }

     PSDL_CD = ^SDL_CD ;
     SDL_CD = record
          id : longint;        { Private drive identifier  }
          status : CDstatus;   { Current drive status  }
          numtracks : longint; { The rest of this structure is only valid if there's a CD in drive  }
          cur_track : longint; { Number of tracks on disk  }
          cur_frame : longint; { Current track position  }
          { Current frame offset within current track  }
          track : array[0..SDL_MAX_TRACKS] of SDL_CDtrack;
       end;

  { Conversion functions from frames to Minute/Second/Frames and vice versa  }

  const
     CD_FPS = 75;

    procedure FRAMES_TO_MSF(v: Longint; var m,s,f: Longint) ;

    { CD-audio API functions:  }

    { Returns the number of CD-ROM drives on the system, or -1 if
       SDL_Init has not been called with the SDL_INIT_CDROM flag.
      }
    function SDL_CDNumDrives:Longint;cdecl;

    { Returns a human-readable, system-dependent identifier for the CD-ROM.
       Example:
    	"/dev/cdrom"
    	"E:"
    	"/dev/disk/ide/1/master"
     }
    function SDL_CDName(drive:longint):Pchar;cdecl;

    { Opens a CD-ROM drive for access.  It returns a drive handle on success,
       or NULL if the drive was invalid or busy.  This newly opened CD-ROM
       becomes the default CD used when other CD functions are passed a NULL
       CD-ROM handle.
       Drives are numbered starting with 0.  Drive 0 is the system default CD-ROM.
     }
    function SDL_CDOpen(drive:longint):PSDL_CD;cdecl;

    { This function returns the current status of the given drive.
       If the drive has a CD in it, the table of contents of the CD and current
       play position of the CD will be stored in the SDL_CD structure.
     }
    function SDL_CDStatus(var cdrom:SDL_CD):CDstatus;cdecl;

    { Play the given CD starting at 'start_track' and 'start_frame' for 'ntracks'
       tracks and 'nframes' frames.  If both 'ntrack' and 'nframe' are 0, play 
       until the end of the CD.  This function will skip data tracks.
       This function should only be called after calling SDL_CDStatus to 
       get track information about the CD.
       For example:
    	(* Play entire CD: *)
    	if CD_INDRIVE(SDL_CDStatus(cdrom)) then
    		SDL_CDPlayTracks(cdrom, 0, 0, 0, 0);
    	(* Play last track: *)
    	if CD_INDRIVE(SDL_CDStatus(cdrom)) then
    		SDL_CDPlayTracks(cdrom, cdrom^.numtracks-1, 0, 0, 0);
    	(* Play first and second track and 10 seconds of third track: *0
    	if CD_INDRIVE(SDL_CDStatus(cdrom)) then
    		SDL_CDPlayTracks(cdrom, 0, 0, 2, 10);
    
       This function returns 0, or -1 if there was an error.
     }
    function SDL_CDPlayTracks(cdrom:pSDL_CD; start_track:longint; start_frame:longint; ntracks:longint; nframes:longint):longint;cdecl;

    { Play the given CD starting at 'start' frame for 'length' frames.
       It returns 0, or -1 if there was an error.
     }
    function SDL_CDPlay(cdrom:pSDL_CD; start:longint; length:longint):longint;cdecl;

    { Pause play -- returns 0, or -1 on error  }
    function SDL_CDPause(cdrom:pSDL_CD):longint;cdecl;

    { Resume play -- returns 0, or -1 on error  }
    function SDL_CDResume(cdrom:pSDL_CD):longint;cdecl;

    { Stop play -- returns 0, or -1 on error  }
    function SDL_CDStop(cdrom:pSDL_CD):longint;cdecl;

    { Eject CD-ROM -- returns 0, or -1 on error  }
    function SDL_CDEject(cdrom:pSDL_CD):longint;cdecl;

    { Closes the handle for the CD-ROM drive  }
    procedure SDL_CDClose(cdrom:pSDL_CD);cdecl;

  implementation

  { Implementation of macros }
  function CD_INDRIVE(status : longint) : longBool;
    begin
       CD_INDRIVE:=(longint(status)) > 0;
    end;

  procedure FRAMES_TO_MSF(v: Longint; var m,s,f: Longint) ;
    Begin
       f := v mod CD_FPS ;
       v := v div CD_FPS ;
       s := v mod 60 ;
       v := v div 60 ;
       m := v ;
    End ;

    { External functions }
    function SDL_CDNumDrives:LongInt;cdecl;external 'SDL';
    function SDL_CDName(drive:longint):Pchar;cdecl;external 'SDL';
    function SDL_CDOpen(drive:longint):PSDL_CD;cdecl;external 'SDL';
    function SDL_CDStatus(var cdrom:SDL_CD):CDstatus;cdecl;external 'SDL';
    function SDL_CDPlayTracks(cdrom:pSDL_CD; start_track:longint; start_frame:longint; ntracks:longint; nframes:longint):longint;cdecl;external 'SDL';
    function SDL_CDPlay(cdrom:pSDL_CD; start:longint; length:longint):longint;cdecl;external 'SDL';
    function SDL_CDPause(cdrom:pSDL_CD):longint;cdecl;external 'SDL';
    function SDL_CDResume(cdrom:pSDL_CD):longint;cdecl;external 'SDL';
    function SDL_CDStop(cdrom:pSDL_CD):longint;cdecl;external 'SDL';
    function SDL_CDEject(cdrom:pSDL_CD):longint;cdecl;external 'SDL';
    procedure SDL_CDClose(cdrom:pSDL_CD);cdecl;external 'SDL';

end.
