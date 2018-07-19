unit SDL_audio;

{  Automatically converted by H2PAS.EXE from SDL_audio.h
   Utility made by Florian Klaempfl 25th-28th september 96
   Improvements made by Mark A. Malakanov 22nd-25th may 97 
   Further improvements by Michael Van Canneyt, April 1998 
   define handling and error recovery by Pierre Muller, June 1998 }

   { ***Edited by Daniel F Moisset, dmoisset@grulic.org.ar*** }

  interface

    uses SDL_types,SDL__rwops;
  { C default packing is dword }

{$PACKRECORDS C}

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

  type

  { Access to the raw audio mixing buffer for the SDL library  }
    { The calculated values in this structure are calculated by SDL_OpenAudio  }
     pSDL_AudioSpec = ^SDL_AudioSpec;
     SDL_AudioSpec = record
          freq : longint;       { DSP frequency -- samples per second  }
          format : Uint16;      { Audio data format  }
          channels : Uint8;     { Number of channels: 1 mono, 2 stereo  }
          silence : Uint8;      { Audio buffer silence value (calculated)  }
          samples : Uint16;     { Audio buffer size in samples  }
          size : Uint32;        { Audio buffer size in bytes (calculated)  }
          { This function is called when the audio device needs more data.
  	   'stream' is a pointer to the audio data buffer
  	   'len' is the length of that buffer in bytes.
  	   Once the callback returns, the buffer will no longer be valid.
           Stereo samples are stored in a LRLRLR ordering.
          }
          callback : procedure (var userdata; stream:pByte; len:longint);cdecl;
          userdata : pointer;
       end;

  const
  { Audio format flags (defaults to LSB byte order)  }
     { Unsigned 8-bit samples  }
     AUDIO_U8 = $0008;
     { Signed 8-bit samples  }
     AUDIO_S8 = $8008;
     { Unsigned 16-bit samples  }
     AUDIO_U16LSB = $0010;
     { Signed 16-bit samples  }
     AUDIO_S16LSB = $8010;
     { As above, but big-endian byte order  }
     AUDIO_U16MSB = $1010;
     { As above, but big-endian byte order  }
     AUDIO_S16MSB = $9010;
     AUDIO_U16 = AUDIO_U16LSB;
     AUDIO_S16 = AUDIO_S16LSB;

  type
   { A structure to hold a set of audio conversion filters and buffers  }

     pSDL_AudioCVT = ^SDL_AudioCVT;
     SDL_FilterFunction = procedure (cvt:pSDL_AudioCVT; format:Uint16);cdecl;
     SDL_AudioCVT = record
          needed : longint;     { Set to 1 if conversion possible  }
          src_format : Uint16;  { Source audio format  }
          dst_format : Uint16;  { Target audio format  }
          rate_incr : double;   { Rate conversion increment  }
          buf : ^Uint8;         { Buffer to hold entire audio data  }
          len : longint;        { Length of original audio buffer  }
          len_cvt : longint;    { Length of converted audio buffer  }
          len_mult : longint;   { buffer must be len*len_mult big  }
          len_ratio : double;   { Given len, final size is len*len_ratio  }
          filters : array[0..9] of SDL_FilterFunction;
          filter_index : longint;{ Current audio conversion function  }
       end;

  { Function prototypes  }

  {
     This function opens the audio device with the desired parameters, and
     returns 0 if successful, placing the actual hardware parameters in the
     structure pointed to by 'obtained'.  If 'obtained' is nil, the audio
     data passed to the callback function will be guaranteed to be in the
     requested format, and will be automatically converted to the hardware
     audio format if necessary.  This function returns -1 if it failed 
     to open the audio device, or couldn't set up the audio thread.
    
     When filling in the desired audio spec structure,
      'desired^.freq' should be the desired audio frequency in samples-per-second.
      'desired^.format' should be the desired audio format.
      'desired^.samples' is the desired size of the audio buffer, in samples.
         This number should be a power of two, and may be adjusted by the audio
         driver to a value more suitable for the hardware.  Good values seem to
         range between 512 and 8096 inclusive, depending on the application and
         CPU speed.  Smaller values yield faster response time, but can lead
         to underflow if the application is doing heavy processing and cannot
         fill the audio buffer in time.  A stereo sample consists of both right
         and left channels in LR ordering.
         Note that the number of samples is directly related to time by the
         following formula:  ms = (samples*1000)/freq
      'desired^.size' is the size in bytes of the audio buffer, and is
         calculated by SDL_OpenAudio.
      'desired^.silence' is the value used to set the buffer to silence,
         and is calculated by SDL_OpenAudio.
      'desired^.callback' should be set to a function that will be called
         when the audio device is ready for more data.  It is passed a pointer
         to the audio buffer, and the length in bytes of the audio buffer.
         This function usually runs in a separate thread, and so you should
         protect data structures that it accesses by calling SDL_LockAudio
         and SDL_UnlockAudio in your code.
      'desired^.userdata' is passed as the first parameter to your callback
         function.
    
     The audio device starts out playing silence when it's opened, and should
     be enabled for playing by calling SDL_PauseAudio(0) when you are ready
     for your audio callback function to be called.  Since the audio driver
     may modify the requested size of the audio buffer, you should allocate
     any local mixing buffers after you open the audio device.
    }

  function SDL_OpenAudio(desired, obtained:pSDL_AudioSpec):longint;cdecl;

  type
    SDL_audiostatus = Longint;
      Const
        SDL_AUDIO_STOPPED = 0 ;
        SDL_AUDIO_PLAYING = 1 ;
        SDL_AUDIO_PAUSED = 2 ;

  { Get the current audio state }
  Function SDL_GetAudioStatus: SDL_audiostatus; cdecl;
  
  {
     This function pauses and unpauses the audio callback processing.
     It should be called with a parameter of 0 after opening the audio
     device to start playing sound.  This is so you can safely initialize
     data for your callback function after opening the audio device.
     Silence will be written to the audio device during the pause.
    }
  procedure SDL_PauseAudio(pause_on:longint);cdecl;

  {
     This function loads a WAVE from the data source, automatically freeing
     that source if 'freesrc' is True.  For example, to load a WAVE file,
     you could do:
    	SDL_LoadWAV_RW(SDL_RWFromFile('sample.wav', 'rb'), 1, ...);
    
     If this function succeeds, it returns the given SDL_AudioSpec,
     filled with the audio data format of the wave data, and sets
     'audio_buf' to a getmem'd buffer containing the audio data,
     and sets 'audio_len' to the length of that audio buffer, in bytes.
     You need to free the audio buffer with SDL_FreeWAV when you are 
     done with it.
    
     This function returns nil and sets the SDL error message if the 
     wave file cannot be opened, uses an unknown data format, or is 
     corrupt.  Currently raw and MS-ADPCM WAVE files are supported.
    }
  function SDL_LoadWAV_RW(src:pSDL_RWops; freesrc:LongBool; spec:pSDL_AudioSpec;
    var audio_buf:pByte; var audio_len:Uint32):pSDL_AudioSpec;cdecl;

  { Compatibility convenience function -- loads a WAV from a file  }
  function SDL_LoadWAV(filename:PChar; spec:pSDL_AudioSpec;
    var audio_buf:pByte; var audio_len : Uint32) : pSDL_AudioSpec;

  {
     This function frees data previously allocated with SDL_LoadWAV_RW
  }
  procedure SDL_FreeWAV(audio_buf:pByte);cdecl;

  {
     This function takes a source format and rate and a destination format
     and rate, and initializes the 'cvt' structure with information needed
     by SDL_ConvertAudio to convert a buffer of audio data from one format
     to the other.
     This function returns 0, or -1 if there was an error.
    }
  function SDL_BuildAudioCVT(cvt:pSDL_AudioCVT; src_format:Uint16; src_channels:Uint8; src_rate:longint; dst_format:Uint16;
             dst_channels:Uint8; dst_rate:longint):longint;cdecl;

  { Once you have initialized the 'cvt' structure using SDL_BuildAudioCVT,
     created an audio buffer cvt^.buf, and filled it with cvt^.len bytes of
     audio data in the source format, this function will convert it in-place
     to the desired format.
     The data conversion may expand the size of the audio data, so the buffer
     cvt^.buf should be allocated after the cvt structure is initialized by
     SDL_BuildAudioCVT, and should be cvt^.len*cvt^.len_mult bytes long.
    }
  function SDL_ConvertAudio(cvt:pSDL_AudioCVT):longint;cdecl;

  const
     SDL_MIX_MAXVOLUME = 128;
  {
     This takes two audio buffers of the playing audio format and mixes
     them, performing addition, volume adjustment, and overflow clipping.
     The volume ranges from 0 - 128, and should be set to SDL_MIX_MAXVOLUME
     for full audio volume.  Note this does not change hardware volume.
     This is provided for convenience -- you can mix your own audio data.
    }

  procedure SDL_MixAudio(dst:pByte; src:pByte; len:Uint32; volume:longint);cdecl;

  {
     The lock manipulated by these functions protects the callback function.
     During a LockAudio/UnlockAudio pair, you can be guaranteed that the
     callback function is not running.  Do not call these from the callback
     function or you will cause deadlock.
    }
  procedure SDL_LockAudio;cdecl;
  procedure SDL_UnlockAudio;cdecl;

  {
     This function shuts down audio processing and closes the audio device.
  }
  procedure SDL_CloseAudio;cdecl;


  implementation

  function SDL_OpenAudio(desired, obtained:pSDL_AudioSpec):longint;cdecl;external 'SDL';

  Function SDL_GetAudioStatus: SDL_audiostatus;cdecl;external 'SDL';

  procedure SDL_PauseAudio(pause_on:longint);cdecl;external 'SDL';

  function SDL_LoadWAV_RW(src:pSDL_RWops; freesrc:LongBool; spec:pSDL_AudioSpec;
    var audio_buf:pByte; var audio_len:Uint32):pSDL_AudioSpec;cdecl;external 'SDL';

  function SDL_LoadWAV(filename:PChar; spec:pSDL_AudioSpec;
    var audio_buf:pByte; var audio_len : Uint32) : pSDL_AudioSpec;
  begin
    SDL_LoadWAV:=SDL_LoadWAV_RW(SDL_RWFromFile(filename,'rb'),True,spec,audio_buf,audio_len);
  end;

  procedure SDL_FreeWAV(audio_buf:pByte);cdecl;external 'SDL';

  function SDL_BuildAudioCVT(cvt:pSDL_AudioCVT; src_format:Uint16; src_channels:Uint8; src_rate:longint; dst_format:Uint16; 
             dst_channels:Uint8; dst_rate:longint):longint;cdecl;external 'SDL';

  function SDL_ConvertAudio(cvt:pSDL_AudioCVT):longint;cdecl;external 'SDL';

  procedure SDL_MixAudio(dst:pByte; src:pByte; len:Uint32; volume:longint);cdecl;external 'SDL';

  procedure SDL_LockAudio;cdecl;external 'SDL';

  procedure SDL_UnlockAudio;cdecl;external 'SDL';

  procedure SDL_CloseAudio;cdecl;external 'SDL';

end.
