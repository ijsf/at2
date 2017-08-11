#include "defs.h"
#include "asmport.h"
#include "import.h"
#include "fpc.h"

/*
FPC_SHORTSTR_TO_SHORTSTR

CRC16_table
CRC32_table
*/

int PARSERIO____SENSITIVESCAN_formal_LONGINT_LONGINT_SHORTSTRING__LONGINT(unsigned char *buf, int skip, int size, unsigned char *strin)
{
  _BYTE *v4; // edi@1
  unsigned int v5; // ecx@1
  int v6; // eax@1
  bool v7; // zf@2
  int v8; // ebx@8
  unsigned char *v9; // esi@9
  int v10; // edx@9
  bool v11; // zf@10
  int v12; // edx@10
  int v13; // ecx@10
  int v14; // ecx@14
  int v15; // ecx@18
  int v16; // eax@19
  /*
  unsigned __int8 str_; // [sp+Ch] [bp-108h]@1
  char v19; // [sp+Dh] [bp-107h]@5
  __int16 v20; // [sp+Eh] [bp-106h]@9
  */

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, (_BYTE *)strin);

  v4 = (_BYTE *)(skip + buf);
  v5 = size - skip;
  HIWORD(v6) = 0;
  if ( size != skip )
  {
    LOBYTE(v6) = str[0];
    v7 = str[0] == 1;
    if ( str[0] < 1u )
    {
LABEL_21:
      //v16 = (int)&v4[-buf];
      v16 = (size_t)(v4 - buf);
      return v16 - 1;
    }
    if ( str[0] > 1u )
    {
      BYTE1(v6) = 0;
      v8 = v6 - 1;
      if ( v5 >= v6 )
      {
        v9 = &str[2];
        v10 = v5 - v6 + 2;
        do
        {
          v12 = v10 - 1;
          v11 = v12 == 0;
          v13 = v12;
          do
          {
            if ( !v13 )
              break;
            v11 = *v4++ == str[1];
            --v13;
          }
          while ( !v11 );
          if ( !v11 )
            break;
          v10 = v13;
          v14 = v6 - 1;
          do
          {
            if ( !v14 )
              break;
            v11 = *(_BYTE *)v9 == *v4;
            v9 = (unsigned char *)((char *)v9 + 1);
            ++v4;
            --v14;
          }
          while ( v11 );
          if ( v11 )
          {
            v4 -= v8;
            goto LABEL_21;
          }
          v15 = v14 - v8;
          v9 = (unsigned char *)((char *)v9 + v15);
          v4 += v15 + 1;
        }
        while ( v10 );
      }
    }
    else
    {
      do
      {
        if ( !v5 )
          break;
        v7 = *v4++ == str[1];
        --v5;
      }
      while ( !v7 );
      if ( v7 )
        goto LABEL_21;
    }
  }
  v16 = 0;
  return v16 - 1;
}

char PARSERIO____COMPARE_formal_formal_LONGINT__BOOLEAN(unsigned char *a3, unsigned char *a2, unsigned int a1)
{
  bool v3; // zf@1
  bool v4; // zf@2
  unsigned int v5; // ecx@2
  _DWORD *v6; // esi@3
  _DWORD *v7; // edi@3
  unsigned int v8; // ecx@7
  unsigned int v9; // ecx@13
  _BYTE *v10; // esi@14
  _BYTE *v11; // edi@14
  char v13; // [sp+Ch] [bp-8h]@11

  v3 = a1 == 16;
  if ( a1 < 0x10 )
  {
    v9 = a1;
    if ( !a1 )
      goto LABEL_23;
    v10 = a3;
    v11 = a2;
    do
    {
      if ( !v9 )
        break;
      v3 = *v10++ == *v11++;
      --v9;
    }
    while ( v3 );
    if ( !v3 )
      v13 = 0;
    else
LABEL_23:
      v13 = 1;
  }
  else
  {
    v5 = a1 / 4;
    if ( !(a1 / 4) )
      goto LABEL_24;
    v6 = (_DWORD *)a3;
    v7 = (_DWORD *)a2;
    do
    {
      if ( !v5 )
        break;
      v4 = *v6 == *v7;
      ++v6;
      ++v7;
      --v5;
    }
    while ( v4 );
    if ( !v4 )
      goto LABEL_25;
    v8 = a1 % 4;
    if ( !(a1 % 4) )
      goto LABEL_24;
    do
    {
      if ( !v8 )
        break;
      v4 = *(_BYTE *)v6 == *(_BYTE *)v7;
      v6 = (_DWORD *)((char *)v6 + 1);
      v7 = (_DWORD *)((char *)v7 + 1);
      --v8;
    }
    while ( v4 );
    if ( !v4 )
LABEL_25:
      v13 = 0;
    else
LABEL_24:
      v13 = 1;
  }
  return v13;
}

char PARSERIO____EMPTY_formal_LONGINT__BOOLEAN(unsigned char *a2, unsigned int a1)
{
  unsigned int v2; // ecx@2
  _DWORD *v3; // edi@3
  bool v4; // zf@3
  unsigned int v5; // ecx@7
  unsigned int v6; // ecx@13
  _BYTE *v7; // edi@14
  bool v8; // zf@14
  char v10; // [sp+Ch] [bp-8h]@11

  if ( a1 < 0x10 )
  {
    v6 = a1;
    if ( !a1 )
      goto LABEL_23;
    v7 = a2;
    v8 = 1;
    do
    {
      if ( !v6 )
        break;
      v8 = *v7++ == 0;
      --v6;
    }
    while ( v8 );
    if ( !v8 )
      v10 = 0;
    else
LABEL_23:
      v10 = 1;
  }
  else
  {
    v2 = a1 / 4;
    if ( !(a1 / 4) )
      goto LABEL_24;
    v3 = (_DWORD *)a2;
    v4 = 1;
    do
    {
      if ( !v2 )
        break;
      v4 = *v3 == 0;
      ++v3;
      --v2;
    }
    while ( v4 );
    if ( !v4 )
      goto LABEL_25;
    v5 = a1 % 4;
    if ( !(a1 % 4) )
      goto LABEL_24;
    do
    {
      if ( !v5 )
        break;
      v4 = *(_BYTE *)v3 == 0;
      v3 = (_DWORD *)((char *)v3 + 1);
      --v5;
    }
    while ( v4 );
    if ( !v4 )
LABEL_25:
      v10 = 0;
    else
LABEL_24:
      v10 = 1;
  }
  return v10;
}

short PARSERIO____UPDATE16_formal_LONGINT_WORD__WORD(char *a3, int a2, short a1)
{
  char *v3; // esi@1
  __int16 v4; // bx@1
  int i; // ecx@1
  char v6; // al@2

  v3 = a3;
  v4 = a1;
  for ( i = a2; i; --i )
  {
    v6 = *v3++;
    v4 = HIBYTE(v4) ^ CRC16_table[(unsigned __int8)(v6 ^ v4)];
  }
  return v4;
}

unsigned int PARSERIO____UPDATE32_formal_LONGINT_LONGINT__LONGINT(unsigned char *a3, int a2, unsigned int a1)
{
  _BYTE *v3; // esi@1
  unsigned int v4; // ebx@1
  int i; // ecx@1
  int v6; // eax@2

  v3 = a3;
  v4 = a1;
  for ( i = a2; i; --i )
  {
    v6 = *v3++;
    v4 = ((unsigned int)0x00ffffff & ((v6 ^ v4) >> 8)) ^ CRC32_table[(v6 ^ v4) & 0xFF];
  }
  return v4;
}

