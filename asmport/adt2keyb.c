#include "asmport.h"
#include "fpc.h"
#include "defs.h"

/*
*/

char ADT2KEYB____LOOKUPKEY_WORD_formal_BYTE__BOOLEAN(short a3, short *a2, unsigned char a1)
{
  __int16 *v3; // esi@1
  int v4; // ecx@1
  __int16 v5; // ax@2
  char v7; // [sp+Ch] [bp-8h]@1

  v3 = a2;
  v4 = a1;
  v7 = 1;
  if ( a1 )
  {
    do
    {
      v5 = *v3;
      ++v3;
      if ( v5 == a3 )
        break;
      --v4;
    }
    while ( v4 );
    v7 = 0;
    if ( v4 )
      v7 = 1;
  }
  return v7;
}
