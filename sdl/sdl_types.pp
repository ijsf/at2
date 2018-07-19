unit SDL_types;

{  Automatically converted by H2PAS.EXE from SDL_types.h
   Utility made by Florian Klaempfl 25th-28th september 96
   Improvements made by Mark A. Malakanov 22nd-25th may 97 
   Further improvements by Michael Van Canneyt, April 1998 
   define handling and error recovery by Pierre Muller, June 1998 }

   { ***Edited by Daniel F Moisset, dmoisset@grulic.org.ar*** }

  interface

  { C default packing is dword }

{$PACKRECORDS C}
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
  { General data types used by the SDL library  }

{ 
   /* The number of elements in a table */
   #define SDL_TABLESIZE(table)  (sizeof(table)/sizeof(table[0]))
}

    { Basic data types  }

    type

       Uint8 = byte;
       Sint8 = shortint;

       Uint16 = word;
       Sint16 = SmallInt;

       Uint32 = cardinal;
       Sint32 = Longint;

       Uint64 = record
          hi, lo: Uint32 ;
       end ;

       SDL_Bool = LongBool ;
    { General keyboard/mouse state definitions  }
    const
      SDL_PRESSED = 1 ;
      SDL_RELEASED = 0;

  implementation


end.
