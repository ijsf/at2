#include "fpc.h"
#include "defs.h"

int FPC_SHORTSTR_TO_SHORTSTR(unsigned char *a1, unsigned int a2, unsigned char *a3)
{
  _BYTE *v3; // edi@1
  int result; // eax@1
  char *v5; // esi@1
  int v6; // edi@3
  int v7; // ecx@4
  char *v8; // edi@4
  char *v9; // esi@4
  unsigned int v10; // ecx@4

  v3 = a1;
  result = *a3;
  v5 = a3 + 1;
  if ( result > a2 )
    result = a2;
  *v3 = result;
  v6 = (int)(v3 + 1);
  if ( result >= 7 )
  {
    v7 = -v6 & 3;
    qmemcpy((void *)v6, v5, v7);
    v9 = &v5[v7];
    v8 = (char *)(v6 + v7);
    v10 = result - v7;
    result = v10 & 3;
    v10 >>= 2;
    qmemcpy(v8, v9, 4 * v10);
    v5 = &v9[4 * v10];
    v6 = (int)&v8[4 * v10];
  }
  qmemcpy((void *)v6, v5, result);
  return result;
}

char * SYSTEM____FILLCHAR_formal_LONGINT_BYTE(char *result, unsigned int a2, char a3)
{
  char *v3; // edi@5

  if ( (signed int)a2 > 22 )
  {
    v3 = result;
    result = (char *)(16843009 * (unsigned __int8)a3);
    memset32(v3, (int)result, a2 >> 2);
    memset(&v3[4 * (a2 >> 2)], a3, a2 & 3);
  }
  else if ( (signed int)a2 > 0 )
  {
    do
    {
      *result++ = a3;
      --a2;
    }
    while ( a2 );
  }
  return result;
}
