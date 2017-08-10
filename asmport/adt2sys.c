#include "asmport.h"
#include "fpc.h"
#include "defs.h"

/*
TC__ADT2DATA____FONT8X16
TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES
TC__ADT2SYS_____CURSOR_BLINK_FACTOR
TC__ADT2SYS____CURSOR_SYNC
TC__ADT2SYS_____FRAMEBUFFER
TC__ADT2SYS____VIRTUAL_CUR_POS
TC__ADT2SYS____VIRTUAL_CUR_SHAPE
TC__ADT2SYS____VIRTUAL_SCREEN__FIRST_ROW
TC__TXTSCRIO____SCREEN_PTR
*/

char ADT2SYS____DRAW_SDL_SCREEN_720X480()
{
  _BYTE *v0; // edi@3
  char *v1; // ebx@3
  int v2; // eax@6
  signed int v4; // [sp+Ch] [bp-28h]@6
  signed int v5; // [sp+10h] [bp-24h]@5
  signed int v6; // [sp+14h] [bp-20h]@4
  signed int v7; // [sp+18h] [bp-1Ch]@3
  unsigned int v8; // [sp+1Ch] [bp-18h]@3
  int v9; // [sp+20h] [bp-14h]@3
  char v10; // [sp+24h] [bp-10h]@3
  char v11; // [sp+28h] [bp-Ch]@5
  unsigned __int8 v12; // [sp+2Ch] [bp-8h]@6
  unsigned __int8 v13; // [sp+30h] [bp-4h]@4

  if ( TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES >= (unsigned int)TC__ADT2SYS_____CURSOR_BLINK_FACTOR )
  {
    TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES = 0;
    TC__ADT2SYS____CURSOR_SYNC ^= 1u;
  }
  v0 = (_BYTE *)TC__ADT2SYS_____FRAMEBUFFER;
  v8 = TC__ADT2SYS_____FRAMEBUFFER + 345600;
  v1 = (char *)TC__TXTSCRIO____SCREEN_PTR;
  v9 = TC__ADT2SYS____VIRTUAL_SCREEN__FIRST_ROW;
  v7 = 40;
  v10 = 1;
  do
  {
    v13 = 0;
    v6 = 16;
    do
    {
      v5 = 90;
      v11 = 1;
      do
      {
        v2 = v13 + 16 * (unsigned __int8)*v1;
        v12 = TC__ADT2DATA____FONT8X16[v2];
        v4 = 8;
        do
        {
          if ( v9 )
          {
            --v9;
          }
          else if ( TC__ADT2SYS____CURSOR_SYNC != 1
                 || v11 != (_BYTE)TC__ADT2SYS____VIRTUAL_CUR_POS
                 || v13 < HIBYTE(TC__ADT2SYS____VIRTUAL_CUR_SHAPE)
                 || v13 > (unsigned __int8)TC__ADT2SYS____VIRTUAL_CUR_SHAPE
                 || v10 != HIBYTE(TC__ADT2SYS____VIRTUAL_CUR_POS) )
          {
            if ( v12 & (unsigned __int8)((unsigned __int16)(1 << v4) >> 1) )
            {
              LOBYTE(v2) = v1[1] & 0xF;
              if ( (unsigned int)v0 <= v8 )
                *v0++ = v2;
            }
            else
            {
              LOBYTE(v2) = (unsigned __int8)v1[1] >> 4;
              if ( (unsigned int)v0 <= v8 )
                *v0++ = v2;
            }
          }
          else
          {
            LOBYTE(v2) = v1[1] & 0xF;
            if ( (unsigned int)v0 <= v8 )
              *v0++ = v2;
          }
          --v4;
        }
        while ( v4 );
        v1 += 2;
        ++v11;
        --v5;
      }
      while ( v5 );
      v1 -= 180;
      ++v13;
      --v6;
    }
    while ( v6 );
    ++v10;
    v1 += 180;
    --v7;
  }
  while ( v7 );
  return v2;
}

char ADT2SYS____DRAW_SDL_SCREEN_960X800()
{
  _BYTE *v0; // edi@3
  char *v1; // ebx@3
  char result; // al@12
  signed int v3; // [sp+Ch] [bp-20h]@6
  signed int v4; // [sp+10h] [bp-1Ch]@5
  signed int v5; // [sp+14h] [bp-18h]@4
  signed int v6; // [sp+18h] [bp-14h]@3
  char v7; // [sp+1Ch] [bp-10h]@3
  char v8; // [sp+20h] [bp-Ch]@5
  unsigned __int8 v9; // [sp+24h] [bp-8h]@6
  unsigned __int8 v10; // [sp+28h] [bp-4h]@4

  if ( TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES >= (unsigned int)TC__ADT2SYS_____CURSOR_BLINK_FACTOR )
  {
    TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES = 0;
    TC__ADT2SYS____CURSOR_SYNC ^= 1u;
  }
  v0 = (_BYTE *)TC__ADT2SYS_____FRAMEBUFFER;
  v1 = (char *)TC__TXTSCRIO____SCREEN_PTR;
  v6 = 50;
  v7 = 1;
  do
  {
    v10 = 0;
    v5 = 16;
    do
    {
      v4 = 120;
      v8 = 1;
      do
      {
        v9 = *(&TC__ADT2DATA____FONT8X16[16 * (unsigned __int8)*v1] + v10);
        v3 = 8;
        do
        {
          if ( TC__ADT2SYS____CURSOR_SYNC != 1
            || v8 != (_BYTE)TC__ADT2SYS____VIRTUAL_CUR_POS
            || v10 < HIBYTE(TC__ADT2SYS____VIRTUAL_CUR_SHAPE)
            || v10 > (unsigned __int8)TC__ADT2SYS____VIRTUAL_CUR_SHAPE
            || v7 != HIBYTE(TC__ADT2SYS____VIRTUAL_CUR_POS) )
          {
            if ( v9 & (unsigned __int8)((unsigned __int16)(1 << v3) >> 1) )
            {
              result = v1[1] & 0xF;
              *v0++ = result;
            }
            else
            {
              result = (unsigned __int8)v1[1] >> 4;
              *v0++ = result;
            }
          }
          else
          {
            result = v1[1] & 0xF;
            *v0++ = result;
          }
          --v3;
        }
        while ( v3 );
        v1 += 2;
        ++v8;
        --v4;
      }
      while ( v4 );
      v1 -= 240;
      ++v10;
      --v5;
    }
    while ( v5 );
    ++v7;
    v1 += 240;
    --v6;
  }
  while ( v6 );
  return result;
}

char ADT2SYS____DRAW_SDL_SCREEN_1440X960()
{
  _BYTE *v0; // edi@3
  char *v1; // ebx@3
  char result; // al@12
  signed int v3; // [sp+Ch] [bp-20h]@6
  signed int v4; // [sp+10h] [bp-1Ch]@5
  signed int v5; // [sp+14h] [bp-18h]@4
  signed int v6; // [sp+18h] [bp-14h]@3
  char v7; // [sp+1Ch] [bp-10h]@3
  char v8; // [sp+20h] [bp-Ch]@5
  unsigned __int8 v9; // [sp+24h] [bp-8h]@6
  unsigned __int8 v10; // [sp+28h] [bp-4h]@4

  if ( TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES >= (unsigned int)TC__ADT2SYS_____CURSOR_BLINK_FACTOR )
  {
    TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES = 0;
    TC__ADT2SYS____CURSOR_SYNC ^= 1u;
  }
  v0 = (_BYTE *)TC__ADT2SYS_____FRAMEBUFFER;
  v1 = (char *)TC__TXTSCRIO____SCREEN_PTR;
  v6 = 60;
  v7 = 1;
  do
  {
    v10 = 0;
    v5 = 16;
    do
    {
      v4 = 180;
      v8 = 1;
      do
      {
        v9 = *(&TC__ADT2DATA____FONT8X16[16 * (unsigned __int8)*v1] + v10);
        v3 = 8;
        do
        {
          if ( TC__ADT2SYS____CURSOR_SYNC != 1
            || v8 != (_BYTE)TC__ADT2SYS____VIRTUAL_CUR_POS
            || v10 < HIBYTE(TC__ADT2SYS____VIRTUAL_CUR_SHAPE)
            || v10 > (unsigned __int8)TC__ADT2SYS____VIRTUAL_CUR_SHAPE
            || v7 != HIBYTE(TC__ADT2SYS____VIRTUAL_CUR_POS) )
          {
            if ( v9 & (unsigned __int8)((unsigned __int16)(1 << v3) >> 1) )
            {
              result = v1[1] & 0xF;
              *v0++ = result;
            }
            else
            {
              result = (unsigned __int8)v1[1] >> 4;
              *v0++ = result;
            }
          }
          else
          {
            result = v1[1] & 0xF;
            *v0++ = result;
          }
          --v3;
        }
        while ( v3 );
        v1 += 2;
        ++v8;
        --v4;
      }
      while ( v4 );
      v1 -= 360;
      ++v10;
      --v5;
    }
    while ( v5 );
    ++v7;
    v1 += 360;
    --v6;
  }
  while ( v6 );
  return result;
}
