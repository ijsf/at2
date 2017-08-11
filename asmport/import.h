extern "C" {

// (at2unit) songdata:      tFIXED_SONGDATA;
extern unsigned char *var_songdata__instr_data;
extern unsigned char *var_songdata__flag_4op;

// CRC16_table: array[BYTE] of Word; extern; cvar;
extern short *CRC16_table;

// CRC32_table: array[BYTE] of Longint; extern; cvar;
extern unsigned int *CRC32_table;

// const opl3out: tOPL3OUT_proc = opl3out_proc; export; cvar;
extern void TC__ADT2OPL3____OPL3OUT(short reg, short data);  // ACHTUNG: reversed params?

// const font8x16: array[0..1023] of Dword = (...)
extern unsigned int *TC__ADT2DATA____FONT8X16;

// fx_digits: array[0..47] of Char = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ&%!@=#$~^`><';
extern unsigned char *TC__ADT2UNIT____FX_DIGITS;

// _4op_tracks_hi: Set of Byte = [1,3,5,10,12,14];
extern unsigned char *TC__ADT2UNIT_____4OP_TRACKS_HI;

// vibtrem_table: array[0..255] of Byte;
extern unsigned char *U__ADT2UNIT____VIBTREM_TABLE;

// vibtrem_table_size: Byte;
extern unsigned char U__ADT2UNIT____VIBTREM_TABLE_SIZE;

// freq_table:    array[1..20] of Word;
extern short *U__ADT2UNIT____FREQ_TABLE;

// freqtable2:    array[1..20] of Word;
extern short *U__ADT2UNIT____FREQTABLE2;

// channel_flag:  array[1..20] of Boolean;
extern unsigned char *U__ADT2UNIT____CHANNEL_FLAG;

// tTRACK_ADDR = array[1..20] of Word;
// _chan_n: tTRACK_ADDR;
extern short *U__ADT2UNIT_____CHAN_N;

// limit_exceeded: Boolean;
extern unsigned char U__ADT2UNIT____LIMIT_EXCEEDED;

// chan_pos: Byte = 1;
extern unsigned char TC__ADT2UNIT____CHAN_POS;

// max_patterns:      Byte      = 128;
extern unsigned char TC__ADT2UNIT____MAX_PATTERNS;

// tCHUNK = Record
//            note:        Byte;
//            instr_def:   Byte;
//            effect_def:  Byte;
//            effect:      Byte;
//            effect_def2: Byte;
//            effect2:     Byte;
//          end;
// tVARIABLE_DATA = array[0..7]    of array[1..20] of
//                  array[0..$0ff] of tCHUNK;
// tPATTERN_DATA = array[0..15] of tVARIABLE_DATA;
// pattdata: ^tPATTERN_DATA = NIL;
extern unsigned char *TC__ADT2UNIT____PATTDATA;

// module_archived:   Boolean   = FALSE;
extern unsigned char TC__ADT2UNIT____MODULE_ARCHIVED;

// _pattedit_lastpos: Byte = 0;
extern unsigned char TC__ADT2SYS_____PATTEDIT_LASTPOS;

// _cursor_blink_pending_frames: Longint = 0;
extern unsigned int TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES;

// _cursor_blink_factor: Longint = 13;
extern unsigned int TC__ADT2SYS_____CURSOR_BLINK_FACTOR;

// cursor_sync: Boolean = FALSE;
extern unsigned char TC__ADT2SYS____CURSOR_SYNC;

// _FrameBuffer: Pointer = NIL;
extern unsigned char *TC__ADT2SYS_____FRAMEBUFFER;

// virtual_cur_pos: Word = 0;
extern short TC__ADT2SYS____VIRTUAL_CUR_POS;

// virtual_cur_shape: Word = 0;
extern short TC__ADT2SYS____VIRTUAL_CUR_SHAPE;

// virtual_screen__first_row: Longint = 0;
extern unsigned int TC__ADT2SYS____VIRTUAL_SCREEN__FIRST_ROW;

// tSCREEN_MEM = array[0..PRED(MAX_SCREEN_MEM_SIZE)] of Byte;
// temp_screen2:         tSCREEN_MEM;
extern unsigned char *U__TXTSCRIO____TEMP_SCREEN2;

// MAX_TRACKS: Byte = 5;
extern unsigned char TC__TXTSCRIO____MAX_TRACKS;

// SCREEN_MEM_SIZE: Longint = MAX_SCREEN_MEM_SIZE;
extern unsigned int TC__TXTSCRIO____SCREEN_MEM_SIZE;

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
extern unsigned char *TC__TXTSCRIO____FR_SETTING;  // shadow_enabled
extern unsigned char *TC__TXTSCRIO____FR_SETTING___UPDATE_AREA;
extern unsigned char *TC__TXTSCRIO____FR_SETTING___WIDE_RANGE_TYPE;

// move_to_screen_area: array[1..4] of Byte = (0,0,0,0);
extern unsigned char *TC__TXTSCRIO____MOVE_TO_SCREEN_AREA;
#define TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS1 (TC__TXTSCRIO____MOVE_TO_SCREEN_AREA+1)
#define TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS2 (TC__TXTSCRIO____MOVE_TO_SCREEN_AREA+2)
#define TC__TXTSCRIO____MOVE_TO_SCREEN_AREA___PLUS3 (TC__TXTSCRIO____MOVE_TO_SCREEN_AREA+3)

}
