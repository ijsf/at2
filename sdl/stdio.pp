unit stdio;

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

{ This unit groups some of the types/constants usually inside <stdio.h>, and
  required to compile the other SDL units. I know, I should do this more 
  cleanly, but I couldn't find an standard place to find this constants/types
  from freepascal
}

interface

  type
    { Some functions in SDL_rwops need a FILE* ... I don't know how to get
      one from freepascal }
    PFile = Pointer ; {FILE *}

  const
    { I should take this constants from some standard place... where? }
    SEEK_SET=0;  { Seek from beginning of file. }
    SEEK_CUR=1;  { Seek from current position. }
    SEEK_END=2;  { Seek from end of file. }

implementation

end.