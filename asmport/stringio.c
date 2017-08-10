#include "asmport.h"
#include "fpc.h"
#include "defs.h"

/*
FPC_SHORTSTR_TO_SHORTSTR
*/

char STRINGIO____SAMENAME_SHORTSTRING_SHORTSTRING__BOOLEAN(unsigned char *a1, unsigned char *a2)
{
  __int16 v2; // dx@1
  char *v3; // esi@1
  int v4; // ecx@1
  char *v5; // edi@1
  __int16 v6; // bx@1
  char v7; // al@4
  unsigned __int8 v8; // ah@13
  unsigned __int8 v9; // al@16
  char v10; // al@30
  __int16 v11; // ax@43
  unsigned __int8 v13; // [sp+Ch] [bp-20Ch]@1
  _BYTE v14[3]; // [sp+Dh] [bp-20Bh]@1
  unsigned __int8 v15; // [sp+10Ch] [bp-10Ch]@1
  _BYTE v16[3]; // [sp+10Dh] [bp-10Bh]@1
  __int16 v18; // [sp+210h] [bp-8h]@1

  FPC_SHORTSTR_TO_SHORTSTR(&v15, 0xFFu, a2);
  FPC_SHORTSTR_TO_SHORTSTR(&v13, 0xFFu, a1);
  v18 = 0;
  v3 = v16;
  v4 = v15;
  v5 = v14;
  v6 = v13;
  if ( v15 )
  {
    do
    {
LABEL_4:
      while ( 1 )
      {
        v7 = *v3++;
        if ( v7 != 42 )
          break;
        LOWORD(v4) = v4 - 1;
        if ( !(_WORD)v4 )
          return 1;
        HIBYTE(v2) = 1;
        v18 = v4;
      }
      if ( v7 == 63 )
      {
        ++v5;
        if ( v6 )
          --v6;
      }
      else
      {
        if ( !v6 )
          goto LABEL_39;
        if ( v7 == 91 )
        {
          if ( *(_WORD *)v3 != 23871 )
          {
            v8 = *v5;
            LOBYTE(v2) = 0;
            if ( *v3 != 33 )
              goto LABEL_16;
            ++v3;
            LOWORD(v4) = v4 - 1;
            if ( (_WORD)v4 )
            {
              ++v2;
LABEL_16:
              while ( 1 )
              {
                v9 = *v3++;
                LOWORD(v4) = v4 - 1;
                if ( !(_WORD)v4 )
                  break;
                if ( v9 == 93 )
                  goto LABEL_28;
                if ( v8 == v9 )
                {
LABEL_26:
                  if ( (_BYTE)v2 )
                    goto LABEL_39;
                  ++v2;
LABEL_28:
                  if ( !(_BYTE)v2 )
                    goto LABEL_39;
                  if ( v9 == 93 )
                    goto LABEL_33;
                  goto LABEL_30;
                }
                if ( *v3 == 45 )
                {
                  ++v3;
                  LOWORD(v4) = v4 - 1;
                  if ( !(_WORD)v4 )
                    goto LABEL_39;
                  if ( v8 >= v9 )
                  {
                    v9 = *v3++;
                    LOWORD(v4) = v4 - 1;
                    if ( !(_WORD)v4 )
                      goto LABEL_39;
                    if ( v8 <= v9 )
                      goto LABEL_26;
                  }
                  else
                  {
                    ++v3;
                    LOWORD(v4) = v4 - 1;
                    if ( !(_WORD)v4 )
                      goto LABEL_39;
                  }
                }
              }
            }
            goto LABEL_39;
          }
          do
          {
LABEL_30:
            v10 = *v3++;
            --v4;
          }
          while ( v10 == 93 && v4 );
          if ( v10 != 93 )
            goto LABEL_39;
LABEL_33:
          --v6;
          ++v5;
        }
        else
        {
          if ( *v5 != v7 )
            goto LABEL_39;
          ++v5;
          --v6;
        }
      }
      HIBYTE(v2) = 0;
      LOWORD(v4) = v4 - 1;
    }
    while ( (_WORD)v4 );
    if ( v6 )
      goto LABEL_39;
    return 1;
  }
  if ( !v13 )
    return 1;
LABEL_39:
  if ( HIBYTE(v2) )
  {
    if ( v4 )
    {
      if ( v6 )
      {
        ++v5;
        if ( --v6 )
        {
          v11 = v18 - v4;
          LOWORD(v4) = v18;
          v3 = &v3[-v11 - 1];
          goto LABEL_4;
        }
      }
    }
  }
  return 0;
}
