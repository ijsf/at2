/*
  PASCAL      C

  Longint     int
  Smallint    short
  Shortint    char
  Dword       unsigned int
  Longword    unsigned int
  Word        unsigned short
  Byte        unsigned char
*/

#define MAX_SCREEN_MEM_SIZE 180*60*2

extern "C" {

// (at2unit) songdata:      tFIXED_SONGDATA;
extern unsigned char *var_songdata__instr_data;
extern unsigned char *var_songdata__flag_4op;

// const opl3out: tOPL3OUT_proc = opl3out_proc; export; cvar;
extern void TC__ADT2OPL3____OPL3OUT(unsigned short reg, unsigned short data);

// const font8x16: array[0..1023] of Dword = (...)
extern unsigned char TC__ADT2DATA____FONT8X16[];

// fx_digits: array[0..47] of Char = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ&%!@=#$~^`><';
extern unsigned char TC__ADT2UNIT____FX_DIGITS[48];

// _4op_tracks_hi: Set of Byte = [1,3,5,10,12,14];
// The compiler stores small sets (less than 32 elements) in a Longint, if the type range allows it. This allows for faster processing and decreases program size. Otherwise, sets are stored in 32 bytes.
extern unsigned int TC__ADT2UNIT_____4OP_TRACKS_HI;

// vibtrem_table: array[0..255] of Byte;
extern unsigned char U__ADT2UNIT____VIBTREM_TABLE[256];

// vibtrem_table_size: Byte;
extern unsigned char U__ADT2UNIT____VIBTREM_TABLE_SIZE;

// freq_table:    array[1..20] of Word;
extern unsigned short U__ADT2UNIT____FREQ_TABLE[20];

// freqtable2:    array[1..20] of Word;
extern unsigned short U__ADT2UNIT____FREQTABLE2[20];

// channel_flag:  array[1..20] of Boolean;
extern unsigned char U__ADT2UNIT____CHANNEL_FLAG[20];

// tTRACK_ADDR = array[1..20] of Word;
// _chan_n: tTRACK_ADDR;
extern unsigned short U__ADT2UNIT_____CHAN_N[20];

// chan_pos: Byte = 1;
extern unsigned char TC__ADT2UNIT____CHAN_POS;

// max_patterns:      Byte      = 128;
extern unsigned char TC__ADT2UNIT____MAX_PATTERNS;

// _pattedit_lastpos: Byte = 0;
extern unsigned char TC__ADT2SYS_____PATTEDIT_LASTPOS;

// _cursor_blink_pending_frames: Longint = 0;
extern int TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES;

// _cursor_blink_factor: Longint = 13;
extern int TC__ADT2SYS_____CURSOR_BLINK_FACTOR;

// cursor_sync: Boolean = FALSE;
extern unsigned char TC__ADT2SYS____CURSOR_SYNC;

// _FrameBuffer: Pointer = NIL;
extern unsigned char *TC__ADT2SYS_____FRAMEBUFFER;

// virtual_cur_pos: Word = 0;
extern unsigned short TC__ADT2SYS____VIRTUAL_CUR_POS;

// virtual_cur_shape: Word = 0;
extern unsigned short TC__ADT2SYS____VIRTUAL_CUR_SHAPE;

// virtual_screen__first_row: Longint = 0;
extern int TC__ADT2SYS____VIRTUAL_SCREEN__FIRST_ROW;

// tSCREEN_MEM = array[0..PRED(MAX_SCREEN_MEM_SIZE)] of Byte;
// temp_screen2:         tSCREEN_MEM;
extern unsigned char U__TXTSCRIO____TEMP_SCREEN2[MAX_SCREEN_MEM_SIZE];

// MAX_TRACKS: Byte = 5;
extern unsigned char TC__TXTSCRIO____MAX_TRACKS;

// SCREEN_MEM_SIZE: Longint = MAX_SCREEN_MEM_SIZE;
extern int TC__TXTSCRIO____SCREEN_MEM_SIZE;

// screen_ptr:          Pointer = Addr(text_screen_shadow);
extern unsigned char *TC__TXTSCRIO____SCREEN_PTR;

// area_x1: Byte = 0;
extern unsigned char TC__TXTSCRIO____AREA_X1;

// area_x2: Byte = 0;
extern unsigned char TC__TXTSCRIO____AREA_X2;

// area_y1: Byte = 0;
extern unsigned char TC__TXTSCRIO____AREA_Y1;

// area_y2: Byte = 0;
extern unsigned char TC__TXTSCRIO____AREA_Y2;

// MaxCol: Byte = 0;
extern unsigned char TC__TXTSCRIO____MAXCOL;

// MaxLn: Byte = 0;
extern unsigned char TC__TXTSCRIO____MAXLN;

// move_to_screen_data: Pointer = NIL;
extern unsigned char *TC__TXTSCRIO____MOVE_TO_SCREEN_DATA;

// ptr_temp_screen2:    Pointer = Addr(temp_screen2);
extern unsigned char *TC__TXTSCRIO____PTR_TEMP_SCREEN2;

// type
//   tFRAME_SETTING = Record
//                      shadow_enabled,
//                      wide_range_type,
//                      zooming_enabled,
//                      update_area: Boolean;
//                    end;
//  fr_setting: tFRAME_SETTING =
//    (shadow_enabled:  TRUE;
//     wide_range_type: FALSE;
//     zooming_enabled: FALSE;
//     update_area:     TRUE);
extern unsigned char get_fr_setting_shadow_enabled();
extern unsigned char get_fr_setting_wide_range_type();
extern unsigned char get_fr_setting_zooming_enabled();
extern unsigned char get_fr_setting_update_area();

// move_to_screen_area: array[1..4] of Byte = (0,0,0,0);
extern unsigned char TC__TXTSCRIO____MOVE_TO_SCREEN_AREA[4];
#define TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS1 (TC__TXTSCRIO____MOVE_TO_SCREEN_AREA+1)
#define TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS2 (TC__TXTSCRIO____MOVE_TO_SCREEN_AREA+2)
#define TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS3 (TC__TXTSCRIO____MOVE_TO_SCREEN_AREA+3)

}
