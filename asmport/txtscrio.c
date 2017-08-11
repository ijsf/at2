#include "defs.h"
#include "asmport.h"
#include "import.h"
#include "fpc.h"

/*
FPC_SHORTSTR_TO_SHORTSTR

TC__TXTSCRIO____SCREEN_MEM_SIZE
TC__TXTSCRIO____SCREEN_PTR
TC__TXTSCRIO____AREA_X1
TC__TXTSCRIO____AREA_X2
TC__TXTSCRIO____AREA_Y1
TC__TXTSCRIO____AREA_Y2
TC__TXTSCRIO____MAXCOL
TC__TXTSCRIO____MAXLN
TC__TXTSCRIO____MOVE_TO_SCREEN_DATA
TC__TXTSCRIO____PTR_TEMP_SCREEN2
U__TXTSCRIO____TEMP_SCREEN2

TC__TXTSCRIO____FR_SETTING
TC__TXTSCRIO____FR_SETTING___UPDATE_AREA
TC__TXTSCRIO____FR_SETTING___WIDE_RANGE_TYPE
TC__TXTSCRIO____MOVE_TO_SCREEN_AREA
TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS1
TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS2
TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS3
*/

// var absolute_pos: Word;
short var_absolute_pos;

char TXTSCRIO____SHOW_STR_BYTE_BYTE_SHORTSTRING_BYTE(char a4, unsigned char a3, unsigned char *a2, char a1)
{
  int v4; // ebx@1
  char *v5; // edx@1
  __int16 v6; // ax@1
  char *v7; // esi@1
  unsigned __int8 v8; // cl@1
  
  /*
  unsigned __int8 v10; // [sp+Ch] [bp-11Ch]@1
  _BYTE v11[3]; // [sp+Dh] [bp-11Bh]@1
  */

  unsigned __int8 v12; // [sp+10Ch] [bp-1Ch]@2
  unsigned __int8 v13; // [sp+110h] [bp-18h]@2
  unsigned __int8 v14; // [sp+114h] [bp-14h]@2
  unsigned __int8 v15; // [sp+118h] [bp-10h]@2
  unsigned __int8 v16; // [sp+11Ch] [bp-Ch]@2
  unsigned __int8 v17; // [sp+120h] [bp-8h]@2
  char v18; // [sp+124h] [bp-4h]@2

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR((unsigned char *)str, 0xFFu, a2);

  HIWORD(v4) = 0;
  v5 = (char *)TC__TXTSCRIO____SCREEN_PTR;
  LOBYTE(v6) = str[0];
  v7 = (char *)&str[1];
  v8 = str[0];
  if ( str[0] )
  {
    v18 = TC__TXTSCRIO____AREA_X1 + 1;
    v17 = TC__TXTSCRIO____AREA_X1 + 2;
    v16 = TC__TXTSCRIO____AREA_X2 + 1;
    v15 = TC__TXTSCRIO____AREA_X2 + 2;
    v14 = TC__TXTSCRIO____AREA_Y1 + 1;
    v13 = TC__TXTSCRIO____AREA_Y2 + 1;
    v12 = 1;
    do
    {
      LOWORD(v4) = 2
                 * ((unsigned __int8)(a3 - 1) * (unsigned __int8)TC__TXTSCRIO____MAXCOL + (unsigned __int8)(v12 + a4 - 2));
      LOBYTE(v6) = v12 + a4 - 1;
      if ( ((unsigned __int8)v6 < v17 || (unsigned __int8)v6 > v15 || a3 != v13)
        && ((unsigned __int8)v6 < v16 || (unsigned __int8)v6 > v15 || a3 < v14 || a3 > v13) )
      {
        if ( (unsigned __int8)v6 < (unsigned __int8)TC__TXTSCRIO____AREA_X1
          || (unsigned __int8)v6 > (unsigned __int8)TC__TXTSCRIO____AREA_X2
          || a3 < (unsigned __int8)TC__TXTSCRIO____AREA_Y1
          || a3 > (unsigned __int8)TC__TXTSCRIO____AREA_Y2 )
        {
          LOBYTE(v6) = *v7++;
          HIBYTE(v6) = a1;
          *(_WORD *)&v5[v4] = v6;
        }
        else
        {
          LOBYTE(v6) = *v7++;
        }
      }
      else
      {
        v5[v4] = *v7++;
      }
      ++v12;
    }
    while ( v12 <= v8 );
  }
  return v6;
}

char TXTSCRIO____SHOW_CSTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(char a5, unsigned char a4, unsigned char *a3, char a2, char a1)
{
  int v5; // ebx@1
  char *v6; // edx@1
  int v7; // eax@1
  _BYTE *v8; // esi@1
  unsigned __int8 v9; // cl@1
  char v10; // ah@11
  int v11; // ST00_4@19
  char v12; // ah@19
  int v13; // ST00_4@22
  char v14; // ah@22
  int v16; // [sp-4h] [bp-134h]@11
  /*
  unsigned __int8 v17; // [sp+Ch] [bp-124h]@1
  _BYTE v18[3]; // [sp+Dh] [bp-123h]@1
  */
  char v19; // [sp+10Ch] [bp-24h]@1
  char v20; // [sp+110h] [bp-20h]@1
  unsigned __int8 v21; // [sp+114h] [bp-1Ch]@2
  unsigned __int8 v22; // [sp+118h] [bp-18h]@2
  unsigned __int8 v23; // [sp+11Ch] [bp-14h]@2
  unsigned __int8 v24; // [sp+120h] [bp-10h]@2
  unsigned __int8 v25; // [sp+124h] [bp-Ch]@2
  unsigned __int8 v26; // [sp+128h] [bp-8h]@2
  char v27; // [sp+12Ch] [bp-4h]@2

  unsigned char str[255];
  v7 = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  v20 = a2;
  v19 = a1;
  HIWORD(v5) = 0;
  v6 = (char *)TC__TXTSCRIO____SCREEN_PTR;
  LOBYTE(v7) = str[0];
  v8 = &str[1];
  v9 = str[0];
  if ( str[0] )
  {
    v27 = TC__TXTSCRIO____AREA_X1 + 1;
    v26 = TC__TXTSCRIO____AREA_X1 + 2;
    v25 = TC__TXTSCRIO____AREA_X2 + 1;
    v24 = TC__TXTSCRIO____AREA_X2 + 2;
    v23 = TC__TXTSCRIO____AREA_Y1 + 1;
    v22 = TC__TXTSCRIO____AREA_Y2 + 1;
    v21 = 1;
    do
    {
      LOWORD(v5) = 2
                 * ((unsigned __int8)(a4 - 1) * (unsigned __int8)TC__TXTSCRIO____MAXCOL + (unsigned __int8)(v21 + a5 - 2));
      LOBYTE(v7) = v21 + a5 - 1;
      BYTE1(v7) = a4;
      if ( ((unsigned __int8)v7 < v26 || (unsigned __int8)v7 > v24 || a4 != v22)
        && ((unsigned __int8)v7 < v25 || (unsigned __int8)v7 > v24 || a4 < v23 || a4 > v22) )
      {
        if ( (unsigned __int8)v7 < (unsigned __int8)TC__TXTSCRIO____AREA_X1
          || (unsigned __int8)v7 > (unsigned __int8)TC__TXTSCRIO____AREA_X2
          || a4 < (unsigned __int8)TC__TXTSCRIO____AREA_Y1
          || a4 > (unsigned __int8)TC__TXTSCRIO____AREA_Y2 )
        {
          while ( 1 )
          {
            LOBYTE(v7) = *v8++;
            if ( (_BYTE)v7 != 126 )
              break;
            v13 = v7;
            v14 = v20;
            v20 = v19;
            v19 = v14;
            v7 = v13;
            if ( v21 > --v9 )
              return v7;
          }
          BYTE1(v7) = v20;
          *(_WORD *)&v6[v5] = v7;
        }
        else
        {
          while ( 1 )
          {
            LOBYTE(v7) = *v8++;
            if ( (_BYTE)v7 != 126 )
              break;
            v11 = v7;
            v12 = v20;
            v20 = v19;
            v19 = v12;
            v7 = v11;
            if ( v21 > --v9 )
              return v7;
          }
        }
      }
      else
      {
        while ( 1 )
        {
          LOBYTE(v7) = *v8++;
          if ( (_BYTE)v7 != 126 )
            break;
          v16 = v7;
          v10 = v20;
          v20 = v19;
          v19 = v10;
          v7 = v16;
          if ( v21 > --v9 )
          {
            if ( (_BYTE)v16 == 126 )
              return v7;
            break;
          }
        }
        v6[v5] = v7;
      }
      ++v21;
    }
    while ( v21 <= v9 );
  }
  return v7;
}

char TXTSCRIO____SHOW_CSTR_ALT_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(char a5, unsigned char a4, unsigned char *a3, char a2, char a1)
{
  int v5; // ebx@1
  char *v6; // edx@1
  int v7; // eax@1
  _BYTE *v8; // esi@1
  unsigned __int8 v9; // cl@1
  char v10; // ah@11
  int v11; // ST00_4@19
  char v12; // ah@19
  int v13; // ST00_4@22
  char v14; // ah@22
  int v16; // [sp-4h] [bp-134h]@11
  /*
  unsigned __int8 v17; // [sp+Ch] [bp-124h]@1
  _BYTE v18[3]; // [sp+Dh] [bp-123h]@1
  */
  char v19; // [sp+10Ch] [bp-24h]@1
  char v20; // [sp+110h] [bp-20h]@1
  unsigned __int8 v21; // [sp+114h] [bp-1Ch]@2
  unsigned __int8 v22; // [sp+118h] [bp-18h]@2
  unsigned __int8 v23; // [sp+11Ch] [bp-14h]@2
  unsigned __int8 v24; // [sp+120h] [bp-10h]@2
  unsigned __int8 v25; // [sp+124h] [bp-Ch]@2
  unsigned __int8 v26; // [sp+128h] [bp-8h]@2
  char v27; // [sp+12Ch] [bp-4h]@2

  unsigned char str[255];
  v7 = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  v20 = a2;
  v19 = a1;
  HIWORD(v5) = 0;
  v6 = (char *)TC__TXTSCRIO____SCREEN_PTR;
  LOBYTE(v7) = str[0];
  v8 = &str[1];
  v9 = str[0];
  if ( str[0] )
  {
    v27 = TC__TXTSCRIO____AREA_X1 + 1;
    v26 = TC__TXTSCRIO____AREA_X1 + 2;
    v25 = TC__TXTSCRIO____AREA_X2 + 1;
    v24 = TC__TXTSCRIO____AREA_X2 + 2;
    v23 = TC__TXTSCRIO____AREA_Y1 + 1;
    v22 = TC__TXTSCRIO____AREA_Y2 + 1;
    v21 = 1;
    do
    {
      LOWORD(v5) = 2
                 * ((unsigned __int8)(a4 - 1) * (unsigned __int8)TC__TXTSCRIO____MAXCOL + (unsigned __int8)(v21 + a5 - 2));
      LOBYTE(v7) = v21 + a5 - 1;
      BYTE1(v7) = a4;
      if ( ((unsigned __int8)v7 < v26 || (unsigned __int8)v7 > v24 || a4 != v22)
        && ((unsigned __int8)v7 < v25 || (unsigned __int8)v7 > v24 || a4 < v23 || a4 > v22) )
      {
        if ( (unsigned __int8)v7 < (unsigned __int8)TC__TXTSCRIO____AREA_X1
          || (unsigned __int8)v7 > (unsigned __int8)TC__TXTSCRIO____AREA_X2
          || a4 < (unsigned __int8)TC__TXTSCRIO____AREA_Y1
          || a4 > (unsigned __int8)TC__TXTSCRIO____AREA_Y2 )
        {
          while ( 1 )
          {
            LOBYTE(v7) = *v8++;
            if ( (_BYTE)v7 != 10 )
              break;
            v13 = v7;
            v14 = v20;
            v20 = v19;
            v19 = v14;
            v7 = v13;
            if ( v21 > --v9 )
              return v7;
          }
          BYTE1(v7) = v20;
          *(_WORD *)&v6[v5] = v7;
        }
        else
        {
          while ( 1 )
          {
            LOBYTE(v7) = *v8++;
            if ( (_BYTE)v7 != 10 )
              break;
            v11 = v7;
            v12 = v20;
            v20 = v19;
            v19 = v12;
            v7 = v11;
            if ( v21 > --v9 )
              return v7;
          }
        }
      }
      else
      {
        while ( 1 )
        {
          LOBYTE(v7) = *v8++;
          if ( (_BYTE)v7 != 10 )
            break;
          v16 = v7;
          v10 = v20;
          v20 = v19;
          v19 = v10;
          v7 = v16;
          if ( v21 > --v9 )
          {
            if ( (_BYTE)v16 == 10 )
              return v7;
            break;
          }
        }
        v6[v5] = v7;
      }
      ++v21;
    }
    while ( v21 <= v9 );
  }
  return v7;
}

char TXTSCRIO____SHOW_VSTR_BYTE_BYTE_SHORTSTRING_BYTE(unsigned char a4, char a3, unsigned char *a2, char a1)
{
  int v4; // ebx@1
  char *v5; // edx@1
  __int16 v6; // ax@1
  char *v7; // esi@1
  unsigned __int8 v8; // cl@1
  /*
  unsigned __int8 v10; // [sp+Ch] [bp-11Ch]@1
  _BYTE v11[3]; // [sp+Dh] [bp-11Bh]@1
  */
  unsigned __int8 v12; // [sp+10Ch] [bp-1Ch]@2
  unsigned __int8 v13; // [sp+110h] [bp-18h]@2
  unsigned __int8 v14; // [sp+114h] [bp-14h]@2
  unsigned __int8 v15; // [sp+118h] [bp-10h]@2
  unsigned __int8 v16; // [sp+11Ch] [bp-Ch]@2
  unsigned __int8 v17; // [sp+120h] [bp-8h]@2
  char v18; // [sp+124h] [bp-4h]@2

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a2);
  
  HIWORD(v4) = 0;
  v5 = (char *)TC__TXTSCRIO____SCREEN_PTR;
  LOBYTE(v6) = str[0];
  v7 = (char *)&str[1];
  v8 = str[0];
  if ( str[0] )
  {
    v18 = TC__TXTSCRIO____AREA_X1 + 1;
    v17 = TC__TXTSCRIO____AREA_X1 + 2;
    v16 = TC__TXTSCRIO____AREA_X2 + 1;
    v15 = TC__TXTSCRIO____AREA_X2 + 2;
    v14 = TC__TXTSCRIO____AREA_Y1 + 1;
    v13 = TC__TXTSCRIO____AREA_Y2 + 1;
    v12 = 1;
    do
    {
      LOWORD(v4) = 2
                 * ((unsigned __int8)(v12 + a3 - 2) * (unsigned __int8)TC__TXTSCRIO____MAXCOL + (unsigned __int8)(a4 - 1));
      LOBYTE(v6) = a4;
      HIBYTE(v6) = v12 + a3 - 1;
      if ( (a4 < v17 || a4 > v15 || HIBYTE(v6) != v13) && (a4 < v16 || a4 > v15 || HIBYTE(v6) < v14 || HIBYTE(v6) > v13) )
      {
        if ( a4 < (unsigned __int8)TC__TXTSCRIO____AREA_X1
          || a4 > (unsigned __int8)TC__TXTSCRIO____AREA_X2
          || HIBYTE(v6) < (unsigned __int8)TC__TXTSCRIO____AREA_Y1
          || HIBYTE(v6) > (unsigned __int8)TC__TXTSCRIO____AREA_Y2 )
        {
          LOBYTE(v6) = *v7++;
          HIBYTE(v6) = a1;
          *(_WORD *)&v5[v4] = v6;
        }
        else
        {
          LOBYTE(v6) = *v7++;
        }
      }
      else
      {
        v5[v4] = *v7++;
      }
      ++v12;
    }
    while ( v12 <= v8 );
  }
  return v6;
}

char TXTSCRIO____SHOW_VCSTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char a5, char a4, unsigned char *a3, char a2, char a1)
{
  int v5; // ebx@1
  char *v6; // edx@1
  int v7; // eax@1
  _BYTE *v8; // esi@1
  unsigned __int8 v9; // cl@1
  char v10; // ah@11
  int v11; // ST00_4@19
  char v12; // ah@19
  int v13; // ST00_4@22
  char v14; // ah@22
  int v16; // [sp-4h] [bp-134h]@11
  /*
  unsigned __int8 v17; // [sp+Ch] [bp-124h]@1
  _BYTE v18[3]; // [sp+Dh] [bp-123h]@1
  */
  char v19; // [sp+10Ch] [bp-24h]@1
  char v20; // [sp+110h] [bp-20h]@1
  unsigned __int8 v21; // [sp+114h] [bp-1Ch]@2
  unsigned __int8 v22; // [sp+118h] [bp-18h]@2
  unsigned __int8 v23; // [sp+11Ch] [bp-14h]@2
  unsigned __int8 v24; // [sp+120h] [bp-10h]@2
  unsigned __int8 v25; // [sp+124h] [bp-Ch]@2
  unsigned __int8 v26; // [sp+128h] [bp-8h]@2
  char v27; // [sp+12Ch] [bp-4h]@2

  unsigned char str[255];
  v7 = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);
  
  v20 = a2;
  v19 = a1;
  HIWORD(v5) = 0;
  v6 = (char *)TC__TXTSCRIO____SCREEN_PTR;
  LOBYTE(v7) = str[0];
  v8 = &str[1];
  v9 = str[0];
  if ( str[0] )
  {
    v27 = TC__TXTSCRIO____AREA_X1 + 1;
    v26 = TC__TXTSCRIO____AREA_X1 + 2;
    v25 = TC__TXTSCRIO____AREA_X2 + 1;
    v24 = TC__TXTSCRIO____AREA_X2 + 2;
    v23 = TC__TXTSCRIO____AREA_Y1 + 1;
    v22 = TC__TXTSCRIO____AREA_Y2 + 1;
    v21 = 1;
    do
    {
      LOWORD(v5) = 2
                 * ((unsigned __int8)(v21 + a4 - 2) * (unsigned __int8)TC__TXTSCRIO____MAXCOL + (unsigned __int8)(a5 - 1));
      BYTE1(v7) = v21 + a4 - 1;
      if ( (a5 < v26 || a5 > v24 || BYTE1(v7) != v22) && (a5 < v25 || a5 > v24 || BYTE1(v7) < v23 || BYTE1(v7) > v22) )
      {
        if ( a5 < (unsigned __int8)TC__TXTSCRIO____AREA_X1
          || a5 > (unsigned __int8)TC__TXTSCRIO____AREA_X2
          || BYTE1(v7) < (unsigned __int8)TC__TXTSCRIO____AREA_Y1
          || BYTE1(v7) > (unsigned __int8)TC__TXTSCRIO____AREA_Y2 )
        {
          while ( 1 )
          {
            LOBYTE(v7) = *v8++;
            if ( (_BYTE)v7 != 126 )
              break;
            v13 = v7;
            v14 = v20;
            v20 = v19;
            v19 = v14;
            v7 = v13;
            if ( v21 > --v9 )
              return v7;
          }
          BYTE1(v7) = v20;
          *(_WORD *)&v6[v5] = v7;
        }
        else
        {
          while ( 1 )
          {
            LOBYTE(v7) = *v8++;
            if ( (_BYTE)v7 != 126 )
              break;
            v11 = v7;
            v12 = v20;
            v20 = v19;
            v19 = v12;
            v7 = v11;
            if ( v21 > --v9 )
              return v7;
          }
        }
      }
      else
      {
        while ( 1 )
        {
          LOBYTE(v7) = *v8++;
          if ( (_BYTE)v7 != 126 )
            break;
          v16 = v7;
          v10 = v20;
          v20 = v19;
          v19 = v10;
          v7 = v16;
          if ( v21 > --v9 )
          {
            if ( (_BYTE)v16 == 126 )
              return v7;
            break;
          }
        }
        v6[v5] = v7;
      }
      ++v21;
    }
    while ( v21 <= v9 );
  }
  return v7;
}

long long TXTSCRIO____DUPCHAR(long long a1, int a2, unsigned char *a3)
{
  __int16 v3; // bx@1
  char v4; // t1^1@1
  _WORD *v5; // edi@2
  __int16 v6; // t2@2
  __int64 v8; // [sp-20h] [bp-2Ch]@1

  v8 = a1;
  v3 = a1;
  LODWORD(a1) = 0;
  v4 = BYTE1(a1);
  LOWORD(a1) = v3;
  HIBYTE(v3) = v4;
  LOBYTE(v3) = a1;
  LOWORD(a1) = v3 + BYTE1(a1) * (unsigned __int8)TC__TXTSCRIO____MAXCOL;
  LOBYTE(v3) = TC__TXTSCRIO____MAXCOL;
  LOWORD(a1) = 2 * (a1 - v3 - 1);
  if ( a2 )
  {
    v5 = (_WORD *)(a1 + a3);
    v6 = a1;
    LOWORD(a1) = WORD2(a1);
    WORD2(a1) = v6;
    while ( a2 )
    {
      *v5 = a1;
      ++v5;
      --a2;
    }
    LOWORD(a1) = WORD2(a1);
  }
  var_absolute_pos = a1;
  return v8;
}

char TXTSCRIO____SHOWSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE(unsigned char *a5, char a4, char a3, unsigned char *a2, char a1)
{
  __int64 v5; // rax@1
  __int16 v6; // ax@1
  _BYTE *v7; // esi@1
  int v8; // ecx@1
  _WORD *v9; // edi@2
  __int16 v10; // ax@2
  /*
  char v12; // [sp+Ch] [bp-100h]@1
  _BYTE v13[3]; // [sp+Dh] [bp-FFh]@1
  */

  unsigned char str[255];
  LODWORD(v5) = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a2);
  
  LOBYTE(v5) = a4;
  BYTE1(v5) = a3;
  TXTSCRIO____DUPCHAR(v5, 0, a5);
  LOBYTE(v6) = str[0];
  v7 = &str[1];
  LOBYTE(v8) = str[0];
  if ( v8 )
  {
    v9 = (_WORD *)((unsigned __int16)var_absolute_pos + a5);
    HIBYTE(v10) = a1;
    do
    {
      LOBYTE(v6) = *v7++;
      *v9 = v6;
      ++v9;
      --v8;
    }
    while ( v8 );
  }
  return v6;
}

char TXTSCRIO____SHOWVSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE(unsigned char *a5, char a4, char a3, unsigned char *a2, char a1)
{
  __int64 v5; // rax@1
  int v6; // ebx@1
  __int16 v7; // ax@1
  _BYTE *v8; // esi@1
  int v9; // ecx@1
  char *v10; // edi@2
  __int16 v11; // ax@2
  
  unsigned char str[255];
  LODWORD(v5) = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a2);
  
  v6 = (unsigned __int16)(2 * (unsigned __int8)(TC__TXTSCRIO____MAXCOL - 1));
  LOBYTE(v5) = a4;
  BYTE1(v5) = a3;
  TXTSCRIO____DUPCHAR(v5, 0, a5);
  LOBYTE(v7) = str[0];
  v8 = &str[1];
  LOBYTE(v9) = str[0];
  if ( v9 )
  {
    v10 = (char *)((unsigned __int16)var_absolute_pos + a5);
    HIBYTE(v11) = a1;
    do
    {
      LOBYTE(v7) = *v8++;
      *(_WORD *)v10 = v7;
      v10 += v6 + 2;
      --v9;
    }
    while ( v9 );
  }
  return v7;
}

char TXTSCRIO____SHOWCSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char *a6, char a5, char a4, unsigned char *a3, char a2, char a1)
{
  __int64 v6; // rax@1
  _BYTE *v7; // esi@1
  int v8; // ST00_4@2
  int v9; // ecx@2
  _WORD *v10; // edi@2
  char v11; // bh@2
  char v12; // t0@6

  unsigned char str[255];
  LODWORD(v6) = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  LOBYTE(v6) = str[0];
  v7 = &str[1];
  if ( str[0] )
  {
    v8 = str[0];
    LOBYTE(v6) = a5;
    BYTE1(v6) = a4;
    TXTSCRIO____DUPCHAR(v6, 0, a6);
    v9 = v8;
    v10 = (_WORD *)((unsigned __int16)var_absolute_pos + a6);
    BYTE1(v6) = a2;
    v11 = a1;
    do
    {
      while ( 1 )
      {
        LOBYTE(v6) = *v7++;
        if ( (_BYTE)v6 == 126 )
          break;
        *v10 = v6;
        ++v10;
        if ( !--v9 )
          return v6;
      }
      v12 = BYTE1(v6);
      BYTE1(v6) = v11;
      v11 = v12;
      --v9;
    }
    while ( v9 );
  }
  return v6;
}

char TXTSCRIO____SHOWCSTR2_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char *a6, char a5, char a4, unsigned char *a3, char a2, char a1)
{
  __int64 v6; // rax@1
  _BYTE *v7; // esi@1
  int v8; // ST00_4@2
  int v9; // ecx@2
  _WORD *v10; // edi@2
  char v11; // bh@2
  char v12; // t0@6

  unsigned char str[255];
  LODWORD(v6) = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  LOBYTE(v6) = str[0];
  v7 = &str[1];
  if ( str[0] )
  {
    v8 = str[0];
    LOBYTE(v6) = a5;
    BYTE1(v6) = a4;
    TXTSCRIO____DUPCHAR(v6, 0, a6);
    v9 = v8;
    v10 = (_WORD *)((unsigned __int16)var_absolute_pos + a6);
    BYTE1(v6) = a2;
    v11 = a1;
    do
    {
      while ( 1 )
      {
        LOBYTE(v6) = *v7++;
        if ( (_BYTE)v6 == 34 )
          break;
        *v10 = v6;
        ++v10;
        if ( !--v9 )
          return v6;
      }
      v12 = BYTE1(v6);
      BYTE1(v6) = v11;
      v11 = v12;
      --v9;
    }
    while ( v9 );
  }
  return v6;
}

char TXTSCRIO____SHOWVCSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char *a6, char a5, char a4, unsigned char *a3, char a2, char a1)
{
  unsigned __int16 v6; // bx@1
  __int64 v7; // rax@1
  _BYTE *v8; // esi@1
  int v9; // ST00_4@2
  int v10; // ecx@2
  char *v11; // edi@2
  char v12; // bh@2
  char v13; // t0@6
  
  unsigned char str[255];
  LODWORD(v7) = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  v6 = 2 * (unsigned __int8)(TC__TXTSCRIO____MAXCOL - 1);
  LOBYTE(v7) = str[0];
  v8 = &str[1];
  if ( str[0] )
  {
    v9 = str[0];
    LOBYTE(v7) = a5;
    BYTE1(v7) = a4;
    TXTSCRIO____DUPCHAR(v7, 0, a6);
    v10 = v9;
    v11 = (char *)((unsigned __int16)var_absolute_pos + a6);
    HIDWORD(v7) = v6;
    BYTE1(v7) = a2;
    v12 = a1;
    do
    {
      while ( 1 )
      {
        LOBYTE(v7) = *v8++;
        if ( (_BYTE)v7 == 126 )
          break;
        *(_WORD *)v11 = v7;
        v11 += HIDWORD(v7) + 2;
        if ( !--v10 )
          return v7;
      }
      v13 = BYTE1(v7);
      BYTE1(v7) = v12;
      v12 = v13;
      --v10;
    }
    while ( v10 );
  }
  return v7;
}

char TXTSCRIO____SHOWC3STR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE_BYTE(unsigned char *a7, char a6, char a5, unsigned char *a4, char a3, char a2, char a1)
{
  __int64 v7; // rax@1
  _BYTE *v8; // esi@1
  int v9; // ST00_4@2
  int v10; // ecx@2
  _WORD *v11; // edi@2
  char v12; // bl@2
  char v13; // bh@2
  char v14; // t0@7
  char v15; // t1@9

  unsigned char str[255];
  LODWORD(v7) = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a4);
  LOBYTE(v7) = str[0];
  v8 = &str[1];
  if ( str[0] )
  {
    v9 = str[0];
    LOBYTE(v7) = a6;
    BYTE1(v7) = a5;
    TXTSCRIO____DUPCHAR(v7, 0, a7);
    v10 = v9;
    v11 = (_WORD *)((unsigned __int16)var_absolute_pos + a7);
    BYTE1(v7) = a3;
    v12 = a2;
    v13 = a1;
    do
    {
      while ( 1 )
      {
        while ( 1 )
        {
          LOBYTE(v7) = *v8++;
          if ( (_BYTE)v7 != 126 )
            break;
          v14 = BYTE1(v7);
          BYTE1(v7) = v12;
          v12 = v14;
          if ( !--v10 )
            return v7;
        }
        if ( (_BYTE)v7 == 96 )
          break;
        *v11 = v7;
        ++v11;
        if ( !--v10 )
          return v7;
      }
      v15 = BYTE1(v7);
      BYTE1(v7) = v13;
      v13 = v15;
      --v10;
    }
    while ( v10 );
  }
  return v7;
}

char TXTSCRIO____SHOWC4STR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE_BYTE_BYTE(unsigned char *a8, char a7, char a6, unsigned char *a5, char a4, char a3, char a2, char a1)
{
  __int64 v8; // rax@1
  _BYTE *v9; // esi@1
  int v10; // ST00_4@2
  int v11; // ecx@2
  _WORD *v12; // edi@2
  char v13; // bl@2
  char v14; // bh@2
  char v15; // t0@8
  char v16; // t1@10
  char v17; // t2@12
  /*
  unsigned __int8 v19; // [sp+Ch] [bp-100h]@1
  _BYTE v20[3]; // [sp+Dh] [bp-FFh]@1
  */

  unsigned char str[255];
  LODWORD(v8) = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a5);

  LOBYTE(v8) = str[0];
  v9 = &str[1];
  if ( str[0] )
  {
    v10 = str[0];
    LOBYTE(v8) = a7;
    BYTE1(v8) = a6;
    TXTSCRIO____DUPCHAR(v8, 0, a8);
    v11 = v10;
    v12 = (_WORD *)((unsigned __int16)var_absolute_pos + a8);
    BYTE1(v8) = a4;
    v13 = a3;
    v14 = a2;
    BYTE4(v8) = a1;
    do
    {
      while ( 1 )
      {
        while ( 1 )
        {
          while ( 1 )
          {
            LOBYTE(v8) = *v9++;
            if ( (_BYTE)v8 != 126 )
              break;
            v15 = BYTE1(v8);
            BYTE1(v8) = v13;
            v13 = v15;
            if ( !--v11 )
              return v8;
          }
          if ( (_BYTE)v8 != 96 )
            break;
          v16 = BYTE1(v8);
          BYTE1(v8) = v14;
          v14 = v16;
          if ( !--v11 )
            return v8;
        }
        if ( (_BYTE)v8 == 94 )
          break;
        *v12 = v8;
        ++v12;
        if ( !--v11 )
          return v8;
      }
      v17 = BYTE1(v8);
      BYTE1(v8) = BYTE4(v8);
      BYTE4(v8) = v17;
      --v11;
    }
    while ( v11 );
  }
  return v8;
}

char TXTSCRIO____SHOWVC3STR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE_BYTE(unsigned char *a7, char a6, char a5, unsigned char *a4, char a3, char a2, char a1)
{
  unsigned __int16 v7; // bx@1
  __int64 v8; // rax@1
  _BYTE *v9; // esi@1
  int v10; // ST00_4@2
  int v11; // ecx@2
  char *v12; // edi@2
  char v13; // bl@2
  char v14; // bh@2
  char v15; // t0@7
  char v16; // t1@9

  unsigned char str[255];
  LODWORD(v8) = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a4);

  v7 = 2 * (unsigned __int8)(TC__TXTSCRIO____MAXCOL - 1);
  LOBYTE(v8) = str[0];
  v9 = &str[1];
  if ( str[0] )
  {
    v10 = str[0];
    LOBYTE(v8) = a6;
    BYTE1(v8) = a5;
    TXTSCRIO____DUPCHAR(v8, 0, a7);
    v11 = v10;
    v12 = (char *)((unsigned __int16)var_absolute_pos + a7);
    HIDWORD(v8) = v7;
    BYTE1(v8) = a3;
    v13 = a2;
    v14 = a1;
    do
    {
      while ( 1 )
      {
        while ( 1 )
        {
          LOBYTE(v8) = *v9++;
          if ( (_BYTE)v8 != 126 )
            break;
          v15 = BYTE1(v8);
          BYTE1(v8) = v13;
          v13 = v15;
          if ( !--v11 )
            return v8;
        }
        if ( (_BYTE)v8 == 96 )
          break;
        *(_WORD *)v12 = v8;
        v12 += HIDWORD(v8) + 2;
        if ( !--v11 )
          return v8;
      }
      v16 = BYTE1(v8);
      BYTE1(v8) = v14;
      v14 = v16;
      --v11;
    }
    while ( v11 );
  }
  return v8;
}

char TXTSCRIO____CSTRLEN_SHORTSTRING__BYTE(unsigned char *a1)
{
  char *v1; // esi@1
  char v2; // bl@1
  int v3; // ecx@1
  char v4; // al@2

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a1);

  v1 = (char *)&str[1];
  v2 = 0;
  v3 = str[0];
  if ( str[0] )
  {
    do
    {
      while ( 1 )
      {
        v4 = *v1++;
        if ( v4 == 126 )
          break;
        ++v2;
        if ( !--v3 )
          return v2;
      }
      --v3;
    }
    while ( v3 );
  }
  return v2;
}

char TXTSCRIO____C3STRLEN_SHORTSTRING__BYTE(unsigned char *a1)
{
  char *v1; // esi@1
  char v2; // bl@1
  int v3; // ecx@1
  char v4; // al@2

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a1);

  v1 = (char *)&str[1];
  v2 = 0;
  v3 = str[0];
  if ( str[0] )
  {
    do
    {
      while ( 1 )
      {
        while ( 1 )
        {
          v4 = *v1++;
          if ( v4 != 126 )
            break;
          if ( !--v3 )
            return v2;
        }
        if ( v4 == 96 )
          break;
        ++v2;
        if ( !--v3 )
          return v2;
      }
      --v3;
    }
    while ( v3 );
  }
  return v2;
}

unsigned int TXTSCRIO____SCREENMEMCOPY_TSCREEN_MEM_PTR_TSCREEN_MEM_PTR(const void *a2, void *a1)
{
  unsigned int result; // eax@1
  unsigned int v3; // edx@2

  result = TC__TXTSCRIO____SCREEN_MEM_SIZE;
  if ( (unsigned int)TC__TXTSCRIO____SCREEN_MEM_SIZE >= 0x10
    && (result = TC__TXTSCRIO____SCREEN_MEM_SIZE / 4u,
        v3 = TC__TXTSCRIO____SCREEN_MEM_SIZE % 4u,
        TC__TXTSCRIO____SCREEN_MEM_SIZE / 4u) )
  {
    qmemcpy(a1, a2, 4 * result);
    if ( v3 )
      qmemcpy((char *)a1 + 4 * result, (char *)a2 + 4 * result, v3);
  }
  else
  {
    qmemcpy(a1, a2, TC__TXTSCRIO____SCREEN_MEM_SIZE);
  }
  return result;
}

char TXTSCRIO____FRAME_crc0EA7F576(unsigned char *a9, char a8, char a7, char a6, char a5, char a4, unsigned char *a3, char a2, unsigned char *a1)
{
  __int64 v9; // rax@1
  char v10; // bh@3
  _WORD *v11; // edi@3
  __int64 v12; // rax@4
  int v13; // ecx@4
  char v14; // bl@4
  __int64 v15; // rax@6
  __int64 v16; // rax@7
  int v17; // ecx@7
  __int64 v18; // rax@7
  __int64 v19; // rax@7
  char v20; // bl@7
  __int64 v21; // rax@8
  int v22; // ecx@8
  __int64 v23; // rax@8
  __int64 v24; // rax@9
  int v25; // ecx@9
  __int64 v26; // rax@9
  __int64 v27; // rax@9
  int v28; // ecx@9
  _BYTE *v29; // esi@10
  int v30; // ecx@10
  char v31; // bl@13
  _BYTE *v32; // edi@14
  _BYTE *v33; // edi@15
  int v34; // ST00_4@17
  _BYTE *v35; // edi@17
  int v36; // ecx@17
  /*
  char v38; // [sp+Ch] [bp-218h]@1
  char v39; // [sp+Dh] [bp-217h]@7
  char v40; // [sp+Eh] [bp-216h]@7
  char v41; // [sp+Fh] [bp-215h]@7
  char v42; // [sp+10h] [bp-214h]@8
  char v43; // [sp+11h] [bp-213h]@8
  char v44; // [sp+12h] [bp-212h]@9
  char v45; // [sp+13h] [bp-211h]@9
  char v46; // [sp+14h] [bp-210h]@9
  */
  /*
  char v47; // [sp+10Ch] [bp-118h]@1
  _BYTE v48[3]; // [sp+10Dh] [bp-117h]@10
  */
  unsigned char *v49; // [sp+20Ch] [bp-18h]@3
  char v50; // [sp+210h] [bp-14h]@4
  char v51; // [sp+214h] [bp-10h]@4
  char v52; // [sp+218h] [bp-Ch]@4
  char v53; // [sp+21Ch] [bp-8h]@4
  char v54; // [sp+220h] [bp-4h]@4

  unsigned char str1[255];
  FPC_SHORTSTR_TO_SHORTSTR((unsigned char *)str1, 0xFFu, a3);

  unsigned char str2[255];
  LODWORD(v9) = FPC_SHORTSTR_TO_SHORTSTR(str2, 0xFFu, a1);

  if ( *TC__TXTSCRIO____FR_SETTING___UPDATE_AREA == 1 )
  {
    TC__TXTSCRIO____AREA_X1 = a8;
    TC__TXTSCRIO____AREA_Y1 = a7;
    TC__TXTSCRIO____AREA_X2 = a6;
    TC__TXTSCRIO____AREA_Y2 = a5;
  }
  v10 = *TC__TXTSCRIO____FR_SETTING;
  v11 = (_WORD *)a9;
  v49 = a9;
  if ( *TC__TXTSCRIO____FR_SETTING___WIDE_RANGE_TYPE )
  {
    v54 = 4;
    v53 = -1;
    v52 = 7;
    v51 = 1;
    v50 = 2;
    LOBYTE(v9) = a8 - 3;
    BYTE1(v9) = a7 - 1;
    BYTE4(v9) = 32;
    BYTE5(v9) = a4;
    v13 = (unsigned __int8)(a6 - a8 + 7); // ACHTUNG
    v12 = TXTSCRIO____DUPCHAR(v9, v13, a9);
    BYTE1(v12) = a5 + 1;
    v9 = TXTSCRIO____DUPCHAR(v12, v13, a9);
    v14 = a7;
    do
    {
      LOBYTE(v9) = a8 - 3;
      BYTE1(v9) = v14;
      BYTE4(v9) = 32;
      v15 = TXTSCRIO____DUPCHAR(v9, 3, a9);
      LOBYTE(v15) = a6 + 1;
      BYTE4(v15) = 32;
      v9 = TXTSCRIO____DUPCHAR(v15, 3, a9);
      ++v14;
    }
    while ( v14 <= a5 );
  }
  else
  {
    v54 = 1;
    v53 = 2;
    v52 = 1;
    v51 = 0;
    v50 = 1;
  }
  LOBYTE(v9) = a8;
  BYTE1(v9) = a7;
  BYTE4(v9) = str2[1];
  BYTE5(v9) = a4;
  v16 = TXTSCRIO____DUPCHAR(v9, 1, a9);
  LOBYTE(v16) = v16 + 1;
  BYTE4(v16) = str2[2];
  BYTE5(v16) = a4;
  LOBYTE(v17) = a6 - a8 - 1;
  v18 = TXTSCRIO____DUPCHAR(v16, v17, a9);
  LOBYTE(v18) = a6;
  BYTE4(v18) = str2[3];
  BYTE5(v18) = a4;
  v19 = TXTSCRIO____DUPCHAR(v18, 1, a9);
  v20 = a7;
  do
  {
    ++v20;
    LOBYTE(v19) = a8;
    BYTE1(v19) = v20;
    BYTE4(v19) = str2[4];
    BYTE5(v19) = a4;
    v21 = TXTSCRIO____DUPCHAR(v19, 1, a9);
    LOBYTE(v21) = v21 + 1;
    BYTE4(v21) = 32;
    BYTE5(v21) = a4;
    LOBYTE(v22) = a6 - a8 - 1;
    v23 = TXTSCRIO____DUPCHAR(v21, v22, a9);
    LOBYTE(v23) = a6;
    BYTE4(v23) = str2[5];
    BYTE5(v23) = a4;
    v19 = TXTSCRIO____DUPCHAR(v23, 1, a9);
  }
  while ( v20 < a5 );
  LOBYTE(v19) = a8;
  BYTE1(v19) = a5;
  BYTE4(v19) = str2[6];
  BYTE5(v19) = a4;
  v24 = TXTSCRIO____DUPCHAR(v19, 1, a9);
  LOBYTE(v24) = v24 + 1;
  BYTE4(v24) = str2[7];
  LOBYTE(v25) = a6 - a8 - 1;
  v26 = TXTSCRIO____DUPCHAR(v24, v25, a9);
  LOBYTE(v26) = a6;
  BYTE4(v26) = str2[8];
  BYTE5(v26) = a4;
  v27 = TXTSCRIO____DUPCHAR(v26, 1, a9);
  LOBYTE(v28) = str1[0];
  if ( v28 )
  {
    LODWORD(v27) = (unsigned __int8)(a6 - a8 - str1[0]);
    LOBYTE(v27) = (unsigned __int8)(a6 - a8 - str1[0]) % 2u + a8 + (unsigned __int8)(a6 - a8 - str1[0]) / 2u;
    BYTE1(v27) = a7;
    v27 = TXTSCRIO____DUPCHAR(v27, 0, a9);
    v11 = (_WORD *)((unsigned __int16)var_absolute_pos + v49);
    v29 = &str1[1];
    LOBYTE(v30) = str1[0];
    BYTE1(v27) = a2;
    do
    {
      LOBYTE(v27) = *v29++;
      *v11 = v27;
      ++v11;
      --v30;
    }
    while ( v30 );
  }
  if ( v10 )
  {
    v31 = a7 - v51;
    do
    {
      ++v31;
      LOBYTE(v27) = v54 + a6;
      BYTE1(v27) = v31;
      v27 = TXTSCRIO____DUPCHAR(v27, 0, (unsigned char *)v11);
      v32 = (_BYTE *)((unsigned __int16)var_absolute_pos + v49 + 1);
      *v32 = 7;
      v32 += 2;
      *v32 = 7;
      v11 = (unsigned short *)v32 + 1;
      if ( (unsigned __int8)TC__TXTSCRIO____MAXCOL > 0xB4u )
      {
        v33 = (unsigned char *)((char *)v11 + 1);
        *v33 = 7;
        v11 = (unsigned short *)v33 + 1;  // ACHTUNG
      }
    }
    while ( v31 <= a5 );
    LOBYTE(v27) = v53 + a8;
    BYTE1(v27) = v50 + a5;
    v34 = TXTSCRIO____DUPCHAR(v27, 0, (unsigned char *)v11); // ACHTUNG
    v35 = (_BYTE *)((unsigned __int16)var_absolute_pos + v49 + 1);
    LOBYTE(v27) = 7;
    LOBYTE(v36) = v52 + a6 - a8;
    if ( (unsigned __int8)TC__TXTSCRIO____MAXLN >= 0x3Cu )
      LOBYTE(v36) = v36 - 1;
    do
    {
      *v35 = 7;
      v35 += 2;
      --v36;
    }
    while ( v36 );
  }
  return v27;
}

void TXTSCRIO____MOVE2SCREEN_ALT()
{
  __int64 v0; // rax@0
  unsigned char *v1; // esi@2
  char *v2; // edi@2
  char v3; // cl@2
  char v4; // cl@3
  char v5; // ST10_1@4
  char v7; // [sp+Ch] [bp-8h]@3

  if ( TC__TXTSCRIO____MOVE_TO_SCREEN_DATA )
  {
    qmemcpy(&U__TXTSCRIO____TEMP_SCREEN2, TC__TXTSCRIO____SCREEN_PTR, TC__TXTSCRIO____SCREEN_MEM_SIZE);
    v1 = TC__TXTSCRIO____MOVE_TO_SCREEN_DATA;
    v2 = (char *)TC__TXTSCRIO____PTR_TEMP_SCREEN2;
    v3 = *TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS1;
    do
    {
      v7 = v3;
      v4 = *TC__TXTSCRIO____MOVE_TO_SCREEN_AREA;
      do
      {
        v5 = v4;
        LOBYTE(v0) = v4;
        BYTE1(v0) = v7;
        v0 = TXTSCRIO____DUPCHAR(v0, 0, (unsigned char *)v2);
        LOWORD(v0) = *(_WORD *)(v1 + (unsigned __int16)var_absolute_pos);
        *(_WORD *)&v2[(unsigned __int16)var_absolute_pos] = v0;
        v4 = v5 + 1;
      }
      while ( (unsigned __int8)(v5 + 1) <= (unsigned __int8)*TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS2 );
      v3 = v7 + 1;
    }
    while ( (unsigned __int8)(v7 + 1) <= (unsigned __int8)*TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS3 );
    qmemcpy(TC__TXTSCRIO____SCREEN_PTR, &U__TXTSCRIO____TEMP_SCREEN2, TC__TXTSCRIO____SCREEN_MEM_SIZE);
  }
}
