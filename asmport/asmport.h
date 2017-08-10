//
// S: string funcs
// V: var (reference) funcs
//

// adt2ext3_iloaders
//
// function _sar(op1,op2: Word): Byte;
char ADT2EXT3_____SAR_WORD_WORD__BYTE(short a1, short a2);

// adt2extn
//
// procedure override_attr(dest: tSCREEN_MEM_PTR; x,y: Byte; len: Byte; attr: Byte);
// function _find_fx(fx_str: Char): Byte;
char ADT2EXTN___REMAP_OVERRIDE_FRAME_crc9EF426E9____OVERRIDE_ATTR_TSCREEN_MEM_PTR_BYTE_BYTE_BYTE_BYTE(unsigned char attr, unsigned char len, unsigned char y, unsigned char x, void *dest);
char ADT2EXTN___REPLACE_____FIND_FX_CHAR__BYTE(char a1);

// adt2keyb
//
// V function LookUpKey(key: Word; var table; size: Byte): Boolean;
char ADT2KEYB____LOOKUPKEY_WORD_formal_BYTE__BOOLEAN(unsigned char a1, short *a2, short a3);

// adt2sys
//
// procedure draw_SDL_screen_720x480;
// procedure draw_SDL_screen_960x800;
// procedure draw_SDL_screen_1440x960;
char ADT2SYS____DRAW_SDL_SCREEN_720X480();
char ADT2SYS____DRAW_SDL_SCREEN_960X800();
char ADT2SYS____DRAW_SDL_SCREEN_1440X960();

// adt2unit
//
// function nFreq(note: Byte): Word;
// function calc_freq_shift_up(freq,shift: Word): Word;
// function calc_freq_shift_down(freq,shift: Word): Word;
// V function calc_vibtrem_shift(chan: Byte; var table_data): Word;
// procedure change_freq(chan: Byte; freq: Word);
// function ins_parameter(ins,param: Byte): Byte;
// V function is_data_empty(var buf; size: Longint): Boolean;
// V procedure get_chunk(pattern,line,channel: Byte; var chunk: tCHUNK);
// V procedure put_chunk(pattern,line,channel: Byte; chunk: tCHUNK);
// V function get_chanpos(var data; channels,scancode: Byte): Byte;
// V function get_chanpos2(var data; channels,scancode: Byte): Byte;
// function count_channel(hpos: Byte): Byte;
// function count_pos(hpos: Byte): Byte;
// function is_4op_chan(chan: Byte): Boolean;
signed short ADT2UNIT____NFREQ_BYTE__WORD(unsigned char a1);
short ADT2UNIT____CALC_FREQ_SHIFT_UP_WORD_WORD__WORD(short a1, short a2);
short ADT2UNIT____CALC_FREQ_SHIFT_DOWN_WORD_WORD__WORD(short a1, short a2);
short ADT2UNIT____CALC_VIBTREM_SHIFT_BYTE_formal__WORD(unsigned char *a1, unsigned char a2);
int ADT2UNIT____CHANGE_FREQ_BYTE_WORD(short a1, char a2);
char ADT2UNIT____INS_PARAMETER_BYTE_BYTE__BYTE(char a1, unsigned char a2);
char ADT2UNIT____IS_DATA_EMPTY_formal_LONGINT__BOOLEAN(unsigned int a1, unsigned char *a2);
char ADT2UNIT____GET_CHUNK_BYTE_BYTE_BYTE_TCHUNK(void *a1, unsigned char a2, unsigned char a3, unsigned char a4);
char ADT2UNIT____PUT_CHUNK_BYTE_BYTE_BYTE_TCHUNK(unsigned char *a1, unsigned char a2, unsigned char a3, unsigned char a4);
int ADT2UNIT____GET_CHANPOS_formal_BYTE_BYTE__BYTE(char a1, unsigned char a2, unsigned char *a3);
int ADT2UNIT____GET_CHANPOS2_formal_BYTE_BYTE__BYTE(char a1, unsigned char a2, unsigned char *a3);
char ADT2UNIT____COUNT_CHANNEL_BYTE__BYTE(unsigned char a1);
char ADT2UNIT____COUNT_POS_BYTE__BYTE(unsigned char a1);
bool ADT2UNIT____IS_4OP_CHAN_BYTE__BOOLEAN(unsigned char a1);

// depackio
//
// V function RDC_decompress(var source,dest; size: Word): Word;
// V function LZSS_decompress(var source,dest; size: Word): Word;
// V function LZW_decompress(var source,dest): Word;
// V function SIXPACK_decompress(var source,dest; size: Word): Word;
// V function APACK_decompress(var source,dest): Dword;
short DEPACKIO____RDC_DECOMPRESS_formal_formal_WORD__WORD(short a1, unsigned char *a2, unsigned char *a3);
short DEPACKIO____LZSS_DECOMPRESS_formal_formal_WORD__WORD(short a1, unsigned char *a2, unsigned char *a3);
short DEPACKIO____LZW_DECOMPRESS_formal_formal__WORD(unsigned char *a2, unsigned char *a3);
short DEPACKIO____SIXPACK_DECOMPRESS_formal_formal_WORD__WORD(short a1, unsigned char *a2, unsigned char *a3);
int DEPACKIO____APACK_DECOMPRESS_formal_formal__LONGWORD(unsigned char *a1, char *a2);

// parserio
//
// SV function SensitiveScan(var buf; skip,size: Longint; str: String): Longint;
// V function Compare(var buf1,buf2; size: Longint): Boolean;
// V function Empty(var buf; size: Longint): Boolean;
// V function Update16(var buf; size: Longint; crc: Word): Word;
// V function Update32(var buf; size: Longint; crc: Longint): Longint;
int PARSERIO____SENSITIVESCAN_formal_LONGINT_LONGINT_SHORTSTRING__LONGINT(unsigned char *str, int size, int skip, unsigned char *buf);
char PARSERIO____COMPARE_formal_formal_LONGINT__BOOLEAN(unsigned int a1, unsigned char *a2, unsigned char *a3);
char PARSERIO____EMPTY_formal_LONGINT__BOOLEAN(unsigned int a1, unsigned char *a2);
short PARSERIO____UPDATE16_formal_LONGINT_WORD__WORD(short a1, int a2, char *a3);
unsigned int PARSERIO____UPDATE32_formal_LONGINT_LONGINT__LONGINT(unsigned int a1, int a2, unsigned char *a3);

// stringio
//
// S function SameName(str1,str2: String): Boolean;
char STRINGIO____SAMENAME_SHORTSTRING_SHORTSTRING__BOOLEAN(unsigned char *a1, unsigned char *a2);

// txtscrio
//
// S procedure show_str(xpos,ypos: Byte; str: String; color: Byte);
// S procedure show_cstr(xpos,ypos: Byte; str: String; attr1,attr2: Byte);
// S procedure show_cstr_alt(xpos,ypos: Byte; str: String; attr1,attr2: Byte);
// S procedure show_vstr(xpos,ypos: Byte; str: String; color: Byte);
// S procedure show_vcstr(xpos,ypos: Byte; str: String; attr1,attr2: Byte);
// S procedure ShowStr(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; attr: Byte);
// S procedure ShowVStr(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; attr: Byte);
// S procedure ShowCStr(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2: Byte);
// S procedure ShowCStr2(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2: Byte);
// S procedure ShowVCStr(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2: Byte);
// S procedure ShowC3Str(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2,atr3: Byte);
// S procedure ShowC4Str(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2,atr3,atr4: Byte);
// S procedure ShowVC3Str(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String; atr1,atr2,atr3: Byte);
// S function CStrLen(str: String): Byte;
// S function C3StrLen(str: String): Byte;
// procedure ScreenMemCopy(source,dest: tSCREEN_MEM_PTR);
// S procedure Frame(dest: tSCREEN_MEM_PTR; x1,y1,x2,y2,atr1: Byte; title: String; atr2: Byte; border: String);
// procedure move2screen_alt;
char TXTSCRIO____SHOW_STR_BYTE_BYTE_SHORTSTRING_BYTE(char a1, unsigned char *a2, unsigned char a3, char a4);
char TXTSCRIO____SHOW_CSTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(char a1, char a2, unsigned char *a3, unsigned char a4, char a5);
char TXTSCRIO____SHOW_CSTR_ALT_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(char a1, char a2, unsigned char *a3, unsigned char a4, char a5);
char TXTSCRIO____SHOW_VSTR_BYTE_BYTE_SHORTSTRING_BYTE(char a1, unsigned char *a2, char a3, unsigned char a4);
char TXTSCRIO____SHOW_VCSTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(char a1, char a2, unsigned char *a3, char a4, unsigned char a5);
char TXTSCRIO____SHOWSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE(char a1, unsigned char *a2, char a3, char a4, int a5);
char TXTSCRIO____SHOWVSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE(char a1, unsigned char *a2, char a3, char a4, int a5);
char TXTSCRIO____SHOWCSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(char a1, char a2, unsigned char *a3, char a4, char a5, int a6);
char TXTSCRIO____SHOWCSTR2_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(char a1, char a2, unsigned char *a3, char a4, char a5, int a6);
char TXTSCRIO____SHOWVCSTR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE(char a1, char a2, unsigned char *a3, char a4, char a5, int a6);
char TXTSCRIO____SHOWC3STR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE_BYTE(char a1, char a2, char a3, unsigned char *a4, char a5, char a6, int a7);
char TXTSCRIO____SHOWC4STR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE_BYTE_BYTE(char a1, char a2, char a3, char a4, unsigned char *a5, char a6, char a7, int a8);
char TXTSCRIO____SHOWVC3STR_TSCREEN_MEM_PTR_BYTE_BYTE_SHORTSTRING_BYTE_BYTE_BYTE(char a1, char a2, char a3, unsigned char *a4, char a5, char a6, int a7);
char TXTSCRIO____CSTRLEN_SHORTSTRING__BYTE(unsigned char *a1);
char TXTSCRIO____C3STRLEN_SHORTSTRING__BYTE(unsigned char *a1);
unsigned int TXTSCRIO____SCREENMEMCOPY_TSCREEN_MEM_PTR_TSCREEN_MEM_PTR(void *a1, const void *a2);
char TXTSCRIO____FRAME_crc0EA7F576(unsigned char *a1, char a2, unsigned char *a3, char a4, char a5, char a6, char a7, char a8, int a9);
short TXTSCRIO____MOVE2SCREEN_ALT();
