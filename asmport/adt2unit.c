#include "defs.h"
#include "asmport.h"
#include "import.h"
#include "fpc.h"

// var_fnum // Fnum: array[0..11] of Word = ($157,$16b,$181,$198,$1b0,$1ca,$1e5,$202,$220,$241,$263,$287);
short var_fnum[] = {0x157,0x16b,0x181,0x198,0x1b0,0x1ca,0x1e5,0x202,0x220,0x241,0x263,0x287};

signed short ADT2UNIT____NFREQ_BYTE__WORD(unsigned char a1)
{
  int v1 = 0; // ebx@1
  signed __int16 result; // ax@2

  if ( a1 >= 0x60u )
  {
    result = 7854;
  }
  else
  {
    v1 = 2 * (a1 % 0xCu);
    result = var_fnum[v1] + (a1 / 0xCu << 10);
  }
  return result;
}

short ADT2UNIT____CALC_FREQ_SHIFT_UP_WORD_WORD__WORD(short a2, short a1)
{
  signed __int16 v2; // bx@1
  __int16 v3; // dx@1

  v2 = a1 + (a2 & 0x3FF);
  v3 = (unsigned __int16)(a2 & 0x1C00) >> 10;
  if ( (unsigned __int16)v2 >= 0x2AEu )
  {
    if ( v3 == 7 )
    {
      v2 = 686;
    }
    else
    {
      v2 -= 344;
      ++v3;
    }
  }
  return v2 + (v3 << 10) + (a2 & 0xE000);
}

short ADT2UNIT____CALC_FREQ_SHIFT_DOWN_WORD_WORD__WORD(short a2, short a1)
{
  signed __int16 v2; // bx@1
  __int16 v3; // dx@1

  v2 = (a2 & 0x3FF) - a1;
  v3 = (unsigned __int16)(a2 & 0x1C00) >> 10;
  if ( (unsigned __int16)v2 <= 0x156u )
  {
    if ( v3 )
    {
      v2 += 344;
      --v3;
    }
    else
    {
      v2 = 342;
    }
  }
  return v2 + (v3 << 10) + (a2 & 0xE000);
}

short ADT2UNIT____CALC_VIBTREM_SHIFT_BYTE_formal__WORD(unsigned char a2, unsigned char *a1)
{
  unsigned __int8 v2; // dh@1
  __int16 v3; // ax@1
  __int16 result; // ax@1
  char v5; // [sp+14h] [bp-Ch]@1

  v2 = *(_BYTE *)(a1 + 5 * a2 - 5);
  v3 = __ROL2__(
         (unsigned __int8)U__ADT2UNIT____VIBTREM_TABLE[(U__ADT2UNIT____VIBTREM_TABLE_SIZE - 1) & v2]
       * *(_BYTE *)(a1 + 5 * a2 - 2),
         1);
  result = __PAIR__(v3, HIBYTE(v3)) & 0x1FF;
  v5 = 1;
  if ( !((unsigned __int8)U__ADT2UNIT____VIBTREM_TABLE_SIZE & v2) )
    v5 = 0;
  *(_BYTE *)(a1 + 5 * a2 - 4) = v5;
  return result;
}

void ADT2UNIT____CHANGE_FREQ_BYTE_WORD_ASM(char a2, short a1)
{
  int v2; // ebx@5
  __int16 v3; // ax@5
  unsigned int v4; // ebx@5
  unsigned int v5; // ebx@6
  int v6; // ST0C_4@6
  int v7; // edx@6
  int v8; // ST08_4@6

  v2 = (unsigned __int8)a2 - 1;
  v3 = (U__ADT2UNIT____FREQ_TABLE[v2] & 0xE000) + (a1 & 0x1FFF);
  U__ADT2UNIT____FREQ_TABLE[v2] = v3;
  U__ADT2UNIT____FREQTABLE2[v2] = v3;
  v4 = (unsigned int)(v2 * 2) >> 1;
  if ( U__ADT2UNIT____CHANNEL_FLAG[v4] == 1 )
  {
    v5 = v4;
    v6 = (unsigned __int16)(U__ADT2UNIT_____CHAN_N[v5] + 160);
    v7 = (unsigned __int8)v3;
    v8 = (unsigned __int8)v3;
    LOWORD(v7) = U__ADT2UNIT_____CHAN_N[v5] + 176;
    TC__ADT2OPL3____OPL3OUT(HIBYTE(v3), v7);
    TC__ADT2OPL3____OPL3OUT(v8, v6);
  }
}

#define INSTRUMENT_SIZE 14

unsigned char ADT2UNIT____INS_PARAMETER_BYTE_BYTE__BYTE(unsigned char a2, unsigned char a1)
{
  return var_songdata__instr_data[(a2 - 1) * INSTRUMENT_SIZE + a1];
}

char ADT2UNIT____IS_DATA_EMPTY_formal_LONGINT__BOOLEAN(unsigned char *a2, unsigned int a1)
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

#define CHUNK_SIZE 6

char ADT2UNIT____GET_CHUNK_BYTE_BYTE_BYTE_TCHUNK(unsigned char pattern, unsigned char line, unsigned char channel, unsigned char *chunk)
{
  unsigned int v4; // eax@2

  if ( (pattern + 1) <= TC__ADT2UNIT____MAX_PATTERNS )
  {
    v4 = (8 * 20 * 256 * CHUNK_SIZE) * (pattern / 8);
    qmemcpy(
      chunk,
      (const void *)(v4 + ((20 * 256 * CHUNK_SIZE) * (pattern % 8u)) + ((256 * CHUNK_SIZE) * (channel - 1)) + (CHUNK_SIZE * line) + TC__ADT2UNIT____PATTDATA),
      CHUNK_SIZE);
  }
  else
  {
    v4 = 0;
    memset(chunk, 0, 6u);
  }
  return v4;
}

char ADT2UNIT____PUT_CHUNK_BYTE_BYTE_BYTE_TCHUNK(unsigned char pattern, unsigned char line, unsigned char channel, unsigned char *chunk)
{
  unsigned int v4; // eax@1

  v4 = pattern + 1;
  if ( (unsigned __int8)(pattern + 1) <= (unsigned __int8)TC__ADT2UNIT____MAX_PATTERNS )
  {
    v4 = (8 * 20 * 256 * CHUNK_SIZE) * (pattern / 8);
    qmemcpy(
      (void *)(v4 + (20 * 256 * CHUNK_SIZE) * (pattern % 8) + (CHUNK_SIZE * 256) * (channel - 1) + 6 * line + TC__ADT2UNIT____PATTDATA),
      chunk,
      CHUNK_SIZE);
    TC__ADT2UNIT____MODULE_ARCHIVED = 0;
  }
  else
  {
    U__ADT2UNIT____LIMIT_EXCEEDED = 1;
  }
  return v4;
}

int ADT2UNIT____GET_CHANPOS_formal_BYTE_BYTE__BYTE(unsigned char *a3, unsigned char a2, char a1)
{
  int i; // ebx@1
  _BYTE *v4; // edi@2
  bool v5; // zf@2
  int v6; // ecx@2
  int result; // eax@6

  for ( i = 0; ; ++i )
  {
    v4 = (_BYTE *)(i + a3);
    v6 = a2 - i;
    v5 = a2 == i;
    do
    {
      if ( !v6 )
        break;
      v5 = *v4++ == a1;
      --v6;
    }
    while ( !v5 );
    if ( !v5 )
      return 0;
    result = ADT2UNIT____IS_4OP_CHAN_BYTE__BOOLEAN(a2 - v6);
    if ( !(_BYTE)result )
      break;
  }
  return result;
}

int ADT2UNIT____GET_CHANPOS2_formal_BYTE_BYTE__BYTE(unsigned char *a3, unsigned char a2, char a1)
{
  _BYTE *v3; // edi@1
  bool v4; // zf@1
  int v5; // ecx@1
  int result; // eax@5

  v3 = a3;
  v4 = 1;
  v5 = a2;
  do
  {
    if ( !v5 )
      break;
    v4 = *v3++ == a1;
    --v5;
  }
  while ( !v4 );
  if ( v4 )
    result = a2 - v5;
  else
    result = 0;
  return result;
}

char ADT2UNIT____COUNT_CHANNEL_BYTE__BYTE(unsigned char a1)
{
  char v1; // al@1
  char result; // al@2

  v1 = a1
     / (unsigned __int8)((unsigned __int8)TC__ADT2SYS_____PATTEDIT_LASTPOS / (unsigned __int8)TC__TXTSCRIO____MAX_TRACKS);
  if ( a1
     % (unsigned __int8)((unsigned __int8)TC__ADT2SYS_____PATTEDIT_LASTPOS / (unsigned __int8)TC__TXTSCRIO____MAX_TRACKS) )
  {
    result = TC__ADT2UNIT____CHAN_POS + v1;
  }
  else
  {
    result = TC__ADT2UNIT____CHAN_POS + v1 - 1;
  }
  return result;
}

char ADT2UNIT____COUNT_POS_BYTE__BYTE(unsigned char a1)
{
  char v1; // ah@1
  char result; // al@1

  v1 = a1
     % (unsigned __int8)((unsigned __int8)TC__ADT2SYS_____PATTEDIT_LASTPOS / (unsigned __int8)TC__TXTSCRIO____MAX_TRACKS);
  result = v1 - 1;
  if ( !v1 )
    result = (unsigned __int8)TC__ADT2SYS_____PATTEDIT_LASTPOS / (unsigned __int8)TC__TXTSCRIO____MAX_TRACKS - 1;
  return result;
}

bool ADT2UNIT____IS_4OP_CHAN_BYTE__BOOLEAN(unsigned char a1)
{
  bool v2; // [sp+Ch] [bp-8h]@4

  if ( *var_songdata__flag_4op & 1 && a1 >= 1u && a1 <= 2u )
  {
    v2 = 1;
  }
  else if ( *var_songdata__flag_4op & 2 && a1 >= 3u && a1 <= 4u )
  {
    v2 = 1;
  }
  else if ( *var_songdata__flag_4op & 4 && a1 >= 5u && a1 <= 6u )
  {
    v2 = 1;
  }
  else if ( *var_songdata__flag_4op & 8 && a1 >= 0xAu && a1 <= 0xBu )
  {
    v2 = 1;
  }
  else if ( *var_songdata__flag_4op & 0x10 && a1 >= 0xCu && a1 <= 0xDu )
  {
    v2 = 1;
  }
  else
  {
    v2 = *var_songdata__flag_4op & 0x20 && a1 >= 0xEu && a1 <= 0xFu;
  }
  return v2;
}

