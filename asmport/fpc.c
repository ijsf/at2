#include "defs.h"
#include "fpc.h"

int C_FPC_SHORTSTR_TO_SHORTSTR(unsigned char *a1, unsigned int a2, unsigned char *a3)
{
  _BYTE *v3; // edi@1
  unsigned int result; // eax@1
  unsigned char *v5; // esi@1
  unsigned char *v6; // edi@3
  size_t v7; // ecx@4
  unsigned char *v8; // edi@4
  unsigned char *v9; // esi@4
  unsigned int v10; // ecx@4

  v3 = a1;
  result = *a3;
  v5 = (a3 + 1);
  if ( result > a2 )
    result = a2;
  *v3 = result;
  v6 = (v3 + 1);
  if ( result >= 7 )
  {
    v7 = (size_t)(v6) & 3;
    qmemcpy((void *)v6, v5, v7);
    v9 = &v5[v7];
    v8 = (v6 + v7);
    v10 = result - v7;
    result = v10 & 3;
    v10 >>= 2;
    qmemcpy(v8, v9, 4 * v10);
    v5 = &v9[4 * v10];
    v6 = &v8[4 * v10];
  }
  qmemcpy((void *)v6, v5, result);
  return result;
}
