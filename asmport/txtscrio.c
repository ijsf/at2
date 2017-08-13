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
unsigned short var_absolute_pos;

void TXTSCRIO____SHOW_STR_BYTE_BYTE_SHORTSTRING_BYTE(unsigned char a4, unsigned char a3, unsigned char *a2, unsigned char a1)
{
  int v4; // ebx@1
  unsigned char *v5; // edx@1
  unsigned short v6; // ax@1
  unsigned char *v7; // esi@1
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

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a2);

  HIWORD(v4) = 0;
  v5 = TC__TXTSCRIO____SCREEN_PTR;
  v7 = &str[1];
  v8 = str[0];
  if ( str[0] )
  {
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
}

void TXTSCRIO____SHOW_CSTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char a5, unsigned char a4, unsigned char *a3, unsigned char a2, unsigned char a1)
{
  int v5; // ebx@1
  unsigned char *v6; // edx@1
  int v7; // eax@1
  _BYTE *v8; // esi@1
  unsigned __int8 v9; // cl@1
  unsigned char v10; // ah@11
  int v11; // ST00_4@19
  unsigned char v12; // ah@19
  int v13; // ST00_4@22
  unsigned char v14; // ah@22
  int v16; // [sp-4h] [bp-134h]@11
  /*
  unsigned __int8 v17; // [sp+Ch] [bp-124h]@1
  _BYTE v18[3]; // [sp+Dh] [bp-123h]@1
  */
  unsigned char v19; // [sp+10Ch] [bp-24h]@1
  unsigned char v20; // [sp+110h] [bp-20h]@1
  unsigned __int8 v21; // [sp+114h] [bp-1Ch]@2
  unsigned __int8 v22; // [sp+118h] [bp-18h]@2
  unsigned __int8 v23; // [sp+11Ch] [bp-14h]@2
  unsigned __int8 v24; // [sp+120h] [bp-10h]@2
  unsigned __int8 v25; // [sp+124h] [bp-Ch]@2
  unsigned __int8 v26; // [sp+128h] [bp-8h]@2

  unsigned char str[255];
  v7 = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  v20 = a2;
  v19 = a1;
  HIWORD(v5) = 0;
  v6 = TC__TXTSCRIO____SCREEN_PTR;
  v8 = &str[1];
  v9 = str[0];
  if ( str[0] )
  {
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
              return;
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
              return;
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
              return;
            break;
          }
        }
        v6[v5] = v7;
      }
      ++v21;
    }
    while ( v21 <= v9 );
  }
}

void TXTSCRIO____SHOW_CSTR_ALT_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char a5, unsigned char a4, unsigned char *a3, unsigned char a2, unsigned char a1)
{
  int v5; // ebx@1
  unsigned char *v6; // edx@1
  int v7; // eax@1
  _BYTE *v8; // esi@1
  unsigned __int8 v9; // cl@1
  unsigned char v10; // ah@11
  int v11; // ST00_4@19
  unsigned char v12; // ah@19
  int v13; // ST00_4@22
  unsigned char v14; // ah@22
  int v16; // [sp-4h] [bp-134h]@11
  /*
  unsigned __int8 v17; // [sp+Ch] [bp-124h]@1
  _BYTE v18[3]; // [sp+Dh] [bp-123h]@1
  */
  unsigned char v19; // [sp+10Ch] [bp-24h]@1
  unsigned char v20; // [sp+110h] [bp-20h]@1
  unsigned __int8 v21; // [sp+114h] [bp-1Ch]@2
  unsigned __int8 v22; // [sp+118h] [bp-18h]@2
  unsigned __int8 v23; // [sp+11Ch] [bp-14h]@2
  unsigned __int8 v24; // [sp+120h] [bp-10h]@2
  unsigned __int8 v25; // [sp+124h] [bp-Ch]@2
  unsigned __int8 v26; // [sp+128h] [bp-8h]@2

  unsigned char str[255];
  v7 = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  v20 = a2;
  v19 = a1;
  HIWORD(v5) = 0;
  v6 = TC__TXTSCRIO____SCREEN_PTR;
  v8 = &str[1];
  v9 = str[0];
  if ( str[0] )
  {
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
              return;
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
              return;
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
              return;
            break;
          }
        }
        v6[v5] = v7;
      }
      ++v21;
    }
    while ( v21 <= v9 );
  }
}

void TXTSCRIO____SHOW_VSTR_BYTE_BYTE_SHORTSTRING_BYTE(unsigned char a4, unsigned char a3, unsigned char *a2, unsigned char a1)
{
  int v4; // ebx@1
  unsigned char *v5; // edx@1
  unsigned short v6; // ax@1
  unsigned char *v7; // esi@1
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

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a2);

  HIWORD(v4) = 0;
  v5 = TC__TXTSCRIO____SCREEN_PTR;
  v7 = &str[1];
  v8 = str[0];
  if ( str[0] )
  {
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
}

void TXTSCRIO____SHOW_VCSTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char a5, unsigned char a4, unsigned char *a3, unsigned char a2, unsigned char a1)
{
  int v5; // ebx@1
  unsigned char *v6; // edx@1
  int v7; // eax@1
  _BYTE *v8; // esi@1
  unsigned __int8 v9; // cl@1
  unsigned char v10; // ah@11
  int v11; // ST00_4@19
  unsigned char v12; // ah@19
  int v13; // ST00_4@22
  unsigned char v14; // ah@22
  int v16; // [sp-4h] [bp-134h]@11
  /*
  unsigned __int8 v17; // [sp+Ch] [bp-124h]@1
  _BYTE v18[3]; // [sp+Dh] [bp-123h]@1
  */
  unsigned char v19; // [sp+10Ch] [bp-24h]@1
  unsigned char v20; // [sp+110h] [bp-20h]@1
  unsigned __int8 v21; // [sp+114h] [bp-1Ch]@2
  unsigned __int8 v22; // [sp+118h] [bp-18h]@2
  unsigned __int8 v23; // [sp+11Ch] [bp-14h]@2
  unsigned __int8 v24; // [sp+120h] [bp-10h]@2
  unsigned __int8 v25; // [sp+124h] [bp-Ch]@2
  unsigned __int8 v26; // [sp+128h] [bp-8h]@2

  unsigned char str[255];
  v7 = FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  v20 = a2;
  v19 = a1;
  HIWORD(v5) = 0;
  v6 = TC__TXTSCRIO____SCREEN_PTR;
  v8 = &str[1];
  v9 = str[0];
  if ( str[0] )
  {
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
              return;
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
              return;
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
              return;
            break;
          }
        }
        v6[v5] = v7;
      }
      ++v21;
    }
    while ( v21 <= v9 );
  }
}

void dupchar(unsigned char column, unsigned char line, unsigned char c, unsigned char attr, int count, unsigned char *ptr)
{
  unsigned int pos = ((column-1) + ((line-1) * TC__TXTSCRIO____MAXCOL)) * 2;
  for(int i = 0; i < count; ++i) {
    unsigned char *w = (ptr + pos + i*2);
    *(w+0) = c;
    *(w+1) = attr;
  }
  var_absolute_pos = pos;
}

void TXTSCRIO____SHOWSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE(unsigned char *a5, unsigned char a4, unsigned char a3, unsigned char *a2, unsigned char a1)
{
  //__int64 v5; // rax@1
  unsigned short v6; // ax@1
  _BYTE *v7; // esi@1
  int v8; // ecx@1
  _WORD *v9; // edi@2
  /*
  char v12; // [sp+Ch] [bp-100h]@1
  _BYTE v13[3]; // [sp+Dh] [bp-FFh]@1
  */

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a2);

  dupchar(a4,a3,0,0,0,a5);
  v7 = &str[1];
  v8 = str[0];
  if ( v8 )
  {
    v9 = (_WORD *)((unsigned __int16)var_absolute_pos + a5);
    do
    {
      LOBYTE(v6) = *v7++;
      HIBYTE(v6) = a1;
      *v9 = v6;
      ++v9;
      --v8;
    }
    while ( v8 );
  }
}

void TXTSCRIO____SHOWVSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE(unsigned char *a5, unsigned char a4, unsigned char a3, unsigned char *a2, unsigned char a1)
{
  //__int64 v5; // rax@1
  int v6; // ebx@1
  unsigned short v7; // ax@1
  _BYTE *v8; // esi@1
  int v9; // ecx@1
  unsigned char *v10; // edi@2
  unsigned short v11; // ax@2

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a2);

  v6 = (unsigned __int16)(2 * (unsigned __int8)(TC__TXTSCRIO____MAXCOL - 1));
  dupchar(a4,a3,0,0,0,a5);
  v8 = &str[1];
  v9 = str[0];
  if ( v9 )
  {
    v10 = (unsigned char *)((unsigned __int16)var_absolute_pos + a5);
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
}

void TXTSCRIO____SHOWCSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char *a6, unsigned char a5, unsigned char a4, unsigned char *a3, unsigned char a2, unsigned char a1)
{
  _WORD v6; // rax@1
  _BYTE *v7; // esi@1
  int v8; // ST00_4@2
  int v9; // ecx@2
  _WORD *v10; // edi@2
  unsigned char v11; // bh@2
  unsigned char v12; // t0@6

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  v7 = &str[1];
  if ( str[0] )
  {
    v8 = str[0];
    dupchar(a5,a4,0,0,0,a6);
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
          return;
      }
      v12 = BYTE1(v6);
      BYTE1(v6) = v11;
      v11 = v12;
      --v9;
    }
    while ( v9 );
  }
}

void TXTSCRIO____SHOWCSTR2_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char *a6, unsigned char a5, unsigned char a4, unsigned char *a3, unsigned char a2, unsigned char a1)
{
  _WORD v6; // rax@1
  _BYTE *v7; // esi@1
  int v8; // ST00_4@2
  int v9; // ecx@2
  _WORD *v10; // edi@2
  unsigned char v11; // bh@2
  unsigned char v12; // t0@6

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  v7 = &str[1];
  if ( str[0] )
  {
    v8 = str[0];
    dupchar(a5,a4,0,0,0,a6);
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
          return;
      }
      v12 = BYTE1(v6);
      BYTE1(v6) = v11;
      v11 = v12;
      --v9;
    }
    while ( v9 );
  }
}

void TXTSCRIO____SHOWVCSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(unsigned char *a6, unsigned char a5, unsigned char a4, unsigned char *a3, unsigned char a2, unsigned char a1)
{
  unsigned short v6; // bx@1
  _WORD v7; // rax@1
  _BYTE *v8; // esi@1
  int v9; // ST00_4@2
  int v10; // ecx@2
  unsigned char *v11; // edi@2
  unsigned char v12; // bh@2
  unsigned char v13; // t0@6

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a3);

  v6 = 2 * (unsigned __int8)(TC__TXTSCRIO____MAXCOL - 1);
  v8 = &str[1];
  if ( str[0] )
  {
    v9 = str[0];
    dupchar(a5,a4,0,0,0,a6);
    v10 = v9;
    v11 = (unsigned char *)((unsigned __int16)var_absolute_pos + a6);
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
        v11 += v6 + 2;
        if ( !--v10 )
          return;
      }
      v13 = BYTE1(v7);
      BYTE1(v7) = v12;
      v12 = v13;
      --v10;
    }
    while ( v10 );
  }
}

void TXTSCRIO____SHOWC3STR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE_BYTE(unsigned char *a7, unsigned char a6, unsigned char a5, unsigned char *a4, unsigned char a3, unsigned char a2, unsigned char a1)
{
  _WORD v7; // rax@1
  _BYTE *v8; // esi@1
  int v9; // ST00_4@2
  int v10; // ecx@2
  _WORD *v11; // edi@2
  unsigned char v12; // bl@2
  unsigned char v13; // bh@2
  unsigned char v14; // t0@7
  unsigned char v15; // t1@9

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a4);
  v8 = &str[1];
  if ( str[0] )
  {
    v9 = str[0];
    dupchar(a6,a5,0,0,0,a7);
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
            return;
        }
        if ( (_BYTE)v7 == 96 )
          break;
        *v11 = v7;
        ++v11;
        if ( !--v10 )
          return;
      }
      v15 = BYTE1(v7);
      BYTE1(v7) = v13;
      v13 = v15;
      --v10;
    }
    while ( v10 );
  }
}

void TXTSCRIO____SHOWC4STR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE_BYTE_BYTE(unsigned char *a8, unsigned char a7, unsigned char a6, unsigned char *a5, unsigned char a4, unsigned char a3, unsigned char a2, unsigned char a1)
{
  _WORD v8; // rax@1
  _BYTE *v9; // esi@1
  int v10; // ST00_4@2
  int v11; // ecx@2
  _WORD *v12; // edi@2
  unsigned char v13; // bl@2
  unsigned char v14; // bh@2
  unsigned char v15; // t0@8
  unsigned char v16; // t1@10
  unsigned char v17; // t2@12
  /*
  unsigned __int8 v19; // [sp+Ch] [bp-100h]@1
  _BYTE v20[3]; // [sp+Dh] [bp-FFh]@1
  */

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a5);

  v9 = &str[1];
  if ( str[0] )
  {
    v10 = str[0];
    dupchar(a7,a6,0,0,0,a8);
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
              return;
          }
          if ( (_BYTE)v8 != 96 )
            break;
          v16 = BYTE1(v8);
          BYTE1(v8) = v14;
          v14 = v16;
          if ( !--v11 )
            return;
        }
        if ( (_BYTE)v8 == 94 )
          break;
        *v12 = v8;
        ++v12;
        if ( !--v11 )
          return;
      }
      v17 = BYTE1(v8);
      BYTE1(v8) = a1;
      a1 = v17;
      --v11;
    }
    while ( v11 );
  }
}

void TXTSCRIO____SHOWVC3STR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE_BYTE(unsigned char *a7, unsigned char a6, unsigned char a5, unsigned char *a4, unsigned char a3, unsigned char a2, unsigned char a1)
{
  unsigned __int16 v7; // bx@1
  _WORD v8; // rax@1
  _BYTE *v9; // esi@1
  int v10; // ST00_4@2
  int v11; // ecx@2
  unsigned char *v12; // edi@2
  unsigned char v13; // bl@2
  unsigned char v14; // bh@2
  unsigned char v15; // t0@7
  unsigned char v16; // t1@9

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a4);

  v7 = 2 * (unsigned __int8)(TC__TXTSCRIO____MAXCOL - 1);
  v9 = &str[1];
  if ( str[0] )
  {
    v10 = str[0];
    dupchar(a6,a5,0,0,0,a7);
    v11 = v10;
    v12 = (unsigned char *)((unsigned __int16)var_absolute_pos + a7);
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
            return;
        }
        if ( (_BYTE)v8 == 96 )
          break;
        *(_WORD *)v12 = v8;
        v12 += v7 + 2;
        if ( !--v11 )
          return;
      }
      v16 = BYTE1(v8);
      BYTE1(v8) = v14;
      v14 = v16;
      --v11;
    }
    while ( v11 );
  }
}

unsigned char TXTSCRIO____CSTRLEN_SHORTSTRING__BYTE(unsigned char *a1)
{
  unsigned char *v1; // esi@1
  unsigned char v2; // bl@1
  int v3; // ecx@1
  unsigned char v4; // al@2

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a1);

  v1 = &str[1];
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

unsigned char TXTSCRIO____C3STRLEN_SHORTSTRING__BYTE(unsigned char *a1)
{
  unsigned char *v1; // esi@1
  unsigned char v2; // bl@1
  int v3; // ecx@1
  unsigned char v4; // al@2

  unsigned char str[255];
  FPC_SHORTSTR_TO_SHORTSTR(str, 0xFFu, a1);

  v1 = &str[1];
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

void TXTSCRIO____SCREENMEMCOPY_TSCREEN_MEM_PTR_TSCREEN_MEM_PTR(const void *source, void *dest)
{
  // ACHTUNG
  // cursor_backup := GetCursor;

  qmemcpy(dest, source, TC__TXTSCRIO____SCREEN_MEM_SIZE);
}

void TXTSCRIO____FRAME_crc0EA7F576(unsigned char *dest, unsigned char x1, unsigned char y1, unsigned char x2, unsigned char y2, unsigned char atr1, unsigned char *title, unsigned char atr2, unsigned char *border)
{
  unsigned char v10; // bh@3
  _WORD *v11; // edi@3
  unsigned char v14; // bl@4
  unsigned char v20; // bl@7
  _WORD v27; // rax@9
  int v28; // ecx@9
  _BYTE *v29; // esi@10
  int v30; // ecx@10
  unsigned char v31; // bl@13
  _BYTE *v32; // edi@14
  _BYTE *v33; // edi@15
  _BYTE *v35; // edi@17
  int v36; // ecx@17
  unsigned char *v49; // [sp+20Ch] [bp-18h]@3
  unsigned char v50; // [sp+210h] [bp-14h]@4
  unsigned char v51; // [sp+214h] [bp-10h]@4
  unsigned char v52; // [sp+218h] [bp-Ch]@4
  unsigned char v53; // [sp+21Ch] [bp-8h]@4
  unsigned char v54; // [sp+220h] [bp-4h]@4

  unsigned char title_[255];
  FPC_SHORTSTR_TO_SHORTSTR(title_, 0xFFu, title);

  unsigned char border_[255];
  FPC_SHORTSTR_TO_SHORTSTR(border_, 0xFFu, border);

  if ( get_fr_setting_update_area() )
  {
    TC__TXTSCRIO____AREA_X1 = x1;
    TC__TXTSCRIO____AREA_Y1 = y1;
    TC__TXTSCRIO____AREA_X2 = x2;
    TC__TXTSCRIO____AREA_Y2 = y2;
  }
  v10 = get_fr_setting_shadow_enabled();
  v11 = (_WORD *)dest;
  v49 = dest;
  if ( get_fr_setting_wide_range_type() )
  {
    v54 = 4;
    v53 = -1;
    v52 = 7;
    v51 = 1;
    v50 = 2;
    dupchar(x1 - 3, y1 - 1, 32, atr1, x2 - x1 + 7, dest);
    dupchar(x1 - 3, y2 + 1, 32, atr1, x2 - x1 + 7, dest);
    v14 = y1;
    do
    {
      dupchar(x1 - 3, v14, 32, atr1, 3, dest);
      dupchar(x2 + 1, v14, 32, atr1, 3, dest);
      ++v14;
    }
    while ( v14 <= y2 );
  }
  else
  {
    v54 = 1;
    v53 = 2;
    v52 = 1;
    v51 = 0;
    v50 = 1;
  }
  dupchar(x1, y1, border_[1], atr1, 1, dest);
  dupchar(x1 + 1, y1, border_[2], atr1, x2 - x1 - 1, dest);
  dupchar(x2, y1, border_[3], atr1, 1, dest);
  v20 = y1;
  do
  {
    ++v20;
    dupchar(x1, v20, border_[4], atr1, 1, dest);
    dupchar(x1 + 1, v20, 32, atr1, x2 - x1 - 1, dest);
    dupchar(x2, v20, border_[5], atr1, 1, dest);
  }
  while ( v20 < y2 );
  dupchar(x1, y2, border_[6], atr1, 1, dest);
  dupchar(x1 + 1, y2, border_[7], atr1, x2 - x1 - 1, dest);
  dupchar(x2, y2, border_[8], atr1, 1, dest);
  v28 = title_[0];
  if ( v28 )
  {
    //LOBYTE(v27) = (unsigned __int8)(x2 - x1 - title_[0]) % 2u + x1 + (unsigned __int8)(x2 - x1 - title_[0]) / 2u;
    dupchar(
      x1 + ((x2 - x1 - title_[0]) / 2) + ((x2 - x1 - title_[0]) % 2),
      y1,
      0, 0, 0, dest);
  
    v11 = (_WORD *)((unsigned __int16)var_absolute_pos + v49);
    v29 = &title_[1];
    v30 = title_[0];
    BYTE1(v27) = atr2;
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
    v31 = y1 - v51;
    do
    {
      ++v31;
      dupchar(v54 + x2, v31, 0, 0, 0, (unsigned char *)v11);
      v32 = (_BYTE *)((unsigned __int16)var_absolute_pos + v49 + 1);
      *v32 = 7;
      v32 += 2;
      *v32 = 7;
      v11 = (unsigned short *)(v32 + 1);
      if ( (unsigned __int8)TC__TXTSCRIO____MAXCOL > 180 )
      {
        v33 = (unsigned char *)(v11 + 1);
        *v33 = 7;
        v11 = (unsigned short *)(v33 + 1);  // ACHTUNG
      }
    }
    while ( v31 <= y2 );
    dupchar(v53 + x1, v50 + y2, 0, 0, 0, (unsigned char *)v11);
    v35 = (_BYTE *)((unsigned __int16)var_absolute_pos + v49 + 1);
    LOBYTE(v27) = 7;
    v36 = v52 + x2 - x1;
    if ( (unsigned __int8)TC__TXTSCRIO____MAXLN >= 60 )
      v36 = v36 - 1;
    do
    {
      *v35 = 7;
      v35 += 2;
      --v36;
    }
    while ( v36 );
  }
}

void TXTSCRIO____MOVE2SCREEN_ALT()
{
  unsigned char *v1; // esi@2
  unsigned char *v2; // edi@2
  unsigned char v3; // cl@2
  unsigned char v4; // cl@3
  unsigned char v5; // ST10_1@4
  unsigned char v7; // [sp+Ch] [bp-8h]@3

  if ( TC__TXTSCRIO____MOVE_TO_SCREEN_DATA )
  {
    qmemcpy(&U__TXTSCRIO____TEMP_SCREEN2, TC__TXTSCRIO____SCREEN_PTR, TC__TXTSCRIO____SCREEN_MEM_SIZE);
    v1 = TC__TXTSCRIO____MOVE_TO_SCREEN_DATA;
    v2 = TC__TXTSCRIO____PTR_TEMP_SCREEN2;
    v3 = *TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS1;
    do
    {
      v7 = v3;
      v4 = *TC__TXTSCRIO____MOVE_TO_SCREEN_AREA;
      do
      {
        v5 = v4;
        dupchar(v4, v7, 0, 0, 0, (unsigned char *)v2);
        *(_WORD *)&v2[(unsigned __int16)var_absolute_pos] = *(_WORD *)(v1 + (unsigned __int16)var_absolute_pos);
        v4 = v5 + 1;
      }
      while ( (unsigned __int8)(v5 + 1) <= (unsigned __int8)*TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS2 );
      v3 = v7 + 1;
    }
    while ( (unsigned __int8)(v7 + 1) <= (unsigned __int8)*TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS3 );
    qmemcpy(TC__TXTSCRIO____SCREEN_PTR, &U__TXTSCRIO____TEMP_SCREEN2, TC__TXTSCRIO____SCREEN_MEM_SIZE);
  }
}
