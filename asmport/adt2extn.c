#include "asmport.h"
#include "import.h"
#include "fpc.h"
#include "defs.h"

/*
TC__TXTSCRIO____MAXCOL
TC__ADT2UNIT____FX_DIGITS
*/

char ADT2EXTN___REMAP_OVERRIDE_FRAME_crc9EF426E9____OVERRIDE_ATTR_TSCREEN_MEM_PTR_BYTE_BYTE_BYTE_BYTE(void *dest, unsigned char x, unsigned char y, unsigned char len, unsigned char attr)
{
  int v5; // eax@0
  int v6; // ebx@1
  int v7; // edx@1
  char result; // al@1
  int v9; // ecx@1
  char *v10; // edi@2
  unsigned __int8 *v11; // edi@3

  v6 = (unsigned __int16)(2 * (unsigned __int8)(TC__TXTSCRIO____MAXCOL - 1));
  LOWORD(v5) = (unsigned __int8)(y - 1) * (unsigned __int8)TC__TXTSCRIO____MAXCOL;
  v7 = 2 * ((unsigned __int8)(x - 1) + v5);
  result = x;
  v9 = len;
  if ( len )
  {
    v10 = (char *)dest + v7;
    result = attr;
    do
    {
      v11 = (unsigned __int8 *)(v10 + 1);
      *v11 = attr;
      v10 = (char *)&v11[v6 + 1];
      --v9;
    }
    while ( v9 );
  }
  return result;
}

char ADT2EXTN___REPLACE_____FIND_FX_CHAR__BYTE(char a1)
{
  char *v2; // edi@1
  signed int v3; // ecx@1
  bool v4; // zf@3

  v2 = (char *)TC__ADT2UNIT____FX_DIGITS;
  v3 = 48;
  do
  {
    if ( !v3 )
      break;
    v4 = *v2++ == a1;
    --v3;
  }
  while ( !v4 );
  return (_BYTE)(v2 - (char *)TC__ADT2UNIT____FX_DIGITS - 1);
}
