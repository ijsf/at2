type
  tFM_INST_DATA = Record
                    AM_VIB_EG_modulator,
                    AM_VIB_EG_carrier,
                    KSL_VOLUM_modulator,
                    KSL_VOLUM_carrier,
                    ATTCK_DEC_modulator,
                    ATTCK_DEC_carrier,
                    SUSTN_REL_modulator,
                    SUSTN_REL_carrier,
                    WAVEFORM_modulator,
                    WAVEFORM_carrier,
                    FEEDBACK_FM: Byte;
                  end;
type
  tADTRACK2_INS = Record
                    fm_data: tFM_INST_DATA;
                    panning: Byte;
                    fine_tune: Shortint;
                    perc_voice: Byte;
                  end;
type
  tOLD_ADTRACK2_INS = Record
                        fm_data: tFM_INST_DATA;
                        panning: Byte;
                        fine_tune: Shortint;
                      end;
type
  tARPEGGIO_TABLE = Record
                      length,
                      speed,
                      loop_begin,
                      loop_length,
                      keyoff_pos: Byte;
                      data: array[1..255] of Byte;
                    end;
type
  tVIBRATO_TABLE = Record
                     length,
                     speed,
                     delay,
                     loop_begin,
                     loop_length,
                     keyoff_pos: Byte;
                     data: array[1..255] of Shortint;
                   end;
type
  tREGISTER_TABLE_DEF = Record
                          fm_data: tFM_INST_DATA;
                          freq_slide: Smallint;
                          panning: Byte;
                          duration: Byte;
                        end;
type
  tREGISTER_TABLE = Record
                      length,
                      loop_begin,
                      loop_length,
                      keyoff_pos,
                      arpeggio_table,
                      vibrato_table: Byte;
                      data: array[1..255] of tREGISTER_TABLE_DEF;
                    end;
type
  tMACRO_TABLE = Record
                   arpeggio: tARPEGGIO_TABLE;
                   vibrato:  tVIBRATO_TABLE;
                 end;
type
  tFM_PARAMETER_TABLE = Record
                          adsrw_car,
                          adsrw_mod: Record
                                       attck,dec,sustn,rel,
                                       wform: Byte;
                                     end;
                          connect,
                          feedb,
                          multipM,kslM,tremM,vibrM,ksrM,sustM,
                          multipC,kslC,tremC,vibrC,ksrC,sustC: Byte;
                        end;
type
  tDIS_FMREG_COL = array[0..27] of Boolean;

type
//  pOLD_FIXED_SONGDATA = ^tOLD_FIXED_SONGDATA;
  tOLD_FIXED_SONGDATA = Record
                          songname:      String[42];
                          composer:      String[42];
                          instr_names:   array[1..250] of String[32];
                          instr_data:    array[1..250] of tOLD_ADTRACK2_INS;
                          pattern_order: array[0..$7f] of Byte;
                          tempo:         Byte;
                          speed:         Byte;
                          common_flag:   Byte;
                        end;
type
//  pFIXED_SONGDATA = ^tFIXED_SONGDATA;
  tFIXED_SONGDATA = Record
                      songname:      String[42];
                      composer:      String[42];
                      instr_names:   array[1..255] of String[42];
                      instr_data:    array[1..255] of tADTRACK2_INS;
                      instr_macros:  array[1..255] of tREGISTER_TABLE;
                      macro_table:   array[1..255] of tMACRO_TABLE;
                      pattern_order: array[0..$7f] of Byte;
                      tempo:         Byte;
                      speed:         Byte;
                      common_flag:   Byte;
                      patt_len:      Word;
                      nm_tracks:     Byte;
                      macro_speedup: Word;
                      flag_4op:      Byte;
                      lock_flags:    array[1..20]  of Byte;
                      pattern_names: array[0..$7f] of String[42];
                      dis_fmreg_col: array[1..255] of tDIS_FMREG_COL;
                    end;
type
  tOLD_CHUNK = Record
                 note:       Byte;
                 instr_def:  Byte;
                 effect_def: Byte;
                 effect:     Byte;
               end;
type
  tCHUNK = Record
             note:        Byte;
             instr_def:   Byte;
             effect_def:  Byte;
             effect:      Byte;
             effect_def2: Byte;
             effect2:     Byte;
           end;
type
//  pOLD_VARIABLE_DATA1 = ^tOLD_VARIABLE_DATA1;
  tOLD_VARIABLE_DATA1 = array[0..$0f] of array[0..$3f] of
                        array[1..9]   of tOLD_CHUNK;
type
//  pOLD_VARIABLE_DATA2 = ^tOLD_VARIABLE_DATA2;
  tOLD_VARIABLE_DATA2 = array[0..7]   of array[1..18] of
                        array[0..$3f] of tOLD_CHUNK;
type
//  pVARIABLE_DATA = ^tVARIABLE_DATA;
  tVARIABLE_DATA = array[0..7]    of array[1..20] of
                   array[0..$0ff] of tCHUNK;
type
//  pPATTERN_DATA = ^tPATTERN_DATA;
  tPATTERN_DATA = array[0..15] of tVARIABLE_DATA;

type
//  pBACKUP = ^tBACKUP;
  tBACKUP = Record
              cursor: Longint;
              oldx:   Byte;
              oldy:   Byte;
              screen: array[1..180*60*SizeOf(WORD)] of Byte;
            end;
type
//  pDUMMY_BUFF = ^tDUMMY_BUFF;
  tDUMMY_BUFF = array[0..PRED(655350)] of Byte;

type
  tCOPY_OBJECT = (objNone,
                  objPatternDef,objPatternTable,
                  objInstrument,objInstrumentBank,
                  objNote,objInstrumentDef,objEffect,objEffect2,
                  objLine,objTrack,objPattern,objMarkedBlock,
                  objMacroTableLine,objMacroTableColumn,objMacroTable,
                  objInstrumentWithMacros);
type
  tMACRO_TABLE_TYPE = (mttFM_reg_table,mttArpeggio_table,mttVibrato_table);

type
//  pCLIPBOARD = ^tCLIPBOARD;
  tCLIPBOARD = Record
                 object_type:   tCOPY_OBJECT;
                 block_hsize:   Byte;
                 block_vsize:   Byte;
                 pattern_order: array[0..$7f] of Byte;
                 pattern:       array[1..20] of array[0..$0ff] of tCHUNK;
                 instrument:    Record
                                  names:  array[1..255] of String[32];
                                  data:   array[1..255] of tADTRACK2_INS;
                                  macros: array[1..255] of tREGISTER_TABLE;
                                  arpvib: array[1..255] of tMACRO_TABLE;
                                  dis_fmreg_col: array[1..255] of tDIS_FMREG_COL;
                                                 {array[0..27]  of Boolean;}
                                end;
                 mcrtab_type:   tMACRO_TABLE_TYPE;
                 fmreg_table:   tREGISTER_TABLE;
                 macro_table:   tMACRO_TABLE;
                 fmtab_def_typ: Byte;
                 _string:       String;
               end;
type
  tDECAY_BAR = Record
                  dir1: Integer;
                  dir2: Integer;
                  lvl1: Real;
                  lvl2: Real;
                end;
type
  tVOLUM_BAR = Record
                  dir: Integer;
                  lvl: Real;
                end;
type
  tPLAY_STATUS = (isPlaying,isPaused,isStopped);

type
  tRGB = Record r,g,b,a: Byte end;

const
  INSTRUMENT_SIZE = SizeOf(tADTRACK2_INS);
  CHUNK_SIZE = SizeOf(tCHUNK);
  PATTERN_SIZE = 20*256*CHUNK_SIZE;
  NULL = $0ff;

const
  status_layout: array[tPLAY_STATUS] of String[10] = ('PLAYiNG   ',
                                                      'PAUSED    ',
                                                      'STOPPED   ');


{$IFDEF WINDOWS}
const PATHSEP: Char = '\';
const WILDCARD_ASTERISK: String = '*.*';
{$ELSE}
const PATHSEP: Char = '/';
const WILDCARD_ASTERISK: String = '*';
{$ENDIF}

const
  kF1     = $3b00; kLEFT   = $4b00; kENTER  = $1c0d; kAltN   = $3100;
  kF2     = $3c00; kShLEFT = $4b34; kCtENTR = $1c0a; kCtrlE  = $1205;
  kShF2   = $5500; kCtLEFT = $7300; kESC    = $011b; kCtrlQ  = $1011;
  kF3     = $3d00; kRIGHT  = $4d00; kTAB    = $0f09; kCtLbr  = $1a1b;
  kShF3   = $5600; kShRGHT = $4d36; kShTAB  = $0f00; kCtRbr  = $1b1d;
  kF4     = $3e00; kCtRGHT = $7400; kSPACE  = $3920; kCtrlF3 = $6000;
  kF5     = $3f00; kUP     = $4800; kBkSPC  = $0e08;
  kShF5   = $5800; kShUP   = $4838; kNPastr = $372a;
  kF6     = $4000; kDOWN   = $5000; kNPplus = $4e2b;
  kShF6   = $5900; kShDOWN = $5032; kNPmins = $4a2d;
  kF7     = $4100; kPgUP   = $4900; kAlt1   = $7800;
  kF8     = $4200; kNPPgUP = $4939; kAlt2   = $7900;
  kShF8   = $5b00; kCtPgUP = $8400; kAlt3   = $7a00;
  kF9     = $4300; kPgDOWN = $5100; kAlt4   = $7b00;
  kShF9   = $5c00; kNPPgDN = $5133; kAlt5   = $7c00;
  kF10    = $4400; kCtPgDN = $7600; kAlt6   = $7d00;
  kCtrlB  = $3002; kHOME   = $4700; kAlt7   = $7e00;
  kCtrlC  = $2e03; kNPHOME = $4737; kAlt8   = $7f00;
  kCtrlD  = $2004; kCtHOME = $7700; kAlt9   = $8000;
  kCtrlF  = $2106; kEND    = $4f00; kAlt0   = $8100;
  kCtrlI  = $1709; kNPEND  = $4f31; kAltC   = $2e00;
  kCtrlK  = $250b; kCtEND  = $7500; kAltM   = $3200;
  kCtrlM  = $320d; kINSERT = $5200; kAltP   = $1900;
  kCtrlN  = $310e; kDELETE = $5300; kAltQ   = $1000;
  kCtrlO  = $180f; kCtrlL  = $260c; kAltR   = $1300;
  kCtrlV  = $2f16; kCtrlS  = $1f13; kAltS   = $1f00;
  kCtrlX  = $2d18; kCtrlA  = $1e01; kNPins  = $5230;
  kWeird  = $2960; kAltF2  = $6900; kNPdel  = $532e;
  kAltL   = $2600; kAltA   = $1e00; kCHastr = $092a;
  kCtrlF2 = $5f00; kCHplus = $0d2b; kCtrlP  = $1910;
  kAltX   = $2d00; kCHmins = $0c2d; kCtBkSp = $0e7f;
  kCtrlT  = $1414; kCHlbrk = $1a5b; kAltF5  = $6c00;
  kCtrlR  = $1312; kCHrbrk = $1b5d; kAltF6  = $6d00;
  kCtrlW  = $1117; kCtrlH  = $2308; kAltF8  = $6f00;
  kSlash  = $352f; kCtrlF8 = $6500; kAltF9  = $7000;
  kSlashR = $2b5c; kCtrlF9 = $6600; kAltB   = $3000;

const
    SC_ESCAPE   = $01;
    SC_1        = $02;
    SC_2        = $03;
    SC_3        = $04;
    SC_4        = $05;
    SC_5        = $06;
    SC_6        = $07;
    SC_7        = $08;
    SC_8        = $09;
    SC_9        = $0A;
    SC_0        = $0B;
    SC_MINUS    = $0C;
    SC_EQUALS   = $0D;
    SC_BACKSPACE = $0E;
    SC_TAB      = $0F;
    SC_Q        = $10;
    SC_W        = $11;
    SC_E        = $12;
    SC_R        = $13;
    SC_T        = $14;
    SC_Y        = $15;
    SC_U        = $16;
    SC_I        = $17;
    SC_O        = $18;
    SC_P        = $19;
    SC_LEFTBRACKET = $1A;
    SC_RIGHTBRACKET = $1B;
    SC_ENTER    = $1C;
//  SC_CONTROL  = $1D;
    SC_A        = $1E;
    SC_S        = $1F;
    SC_D        = $20;
    SC_F        = $21;
    SC_G        = $22;
    SC_H        = $23;
    SC_J        = $24;
    SC_K        = $25;
    SC_L        = $26;
    SC_SEMICOLON = $27;
    SC_QUOTE    = $28;
    SC_TILDE    = $29;
    SC_LSHIFT   = $2A;
    SC_BACKSLASH = $2B;
    SC_Z        = $2C;
    SC_X        = $2D;
    SC_C        = $2E;
    SC_V        = $2F;
    SC_B        = $30;
    SC_N        = $31;
    SC_M        = $32;
    SC_COMMA    = $33;
    SC_PERIOD   = $34;
    SC_SLASH    = $35;
    SC_RSHIFT   = $36;
    SC_MULTIPLY = $37;
//  SC_ALT      = $38;
    SC_SPACE    = $39;
    SC_CAPSLOCK = $3A;
    SC_F1       = $3B;
    SC_F2       = $3C;
    SC_F3       = $3D;
    SC_F4       = $3E;
    SC_F5       = $3F;
    SC_F6       = $40;
    SC_F7       = $41;
    SC_F8       = $42;
    SC_F9       = $43;
    SC_F10      = $44;
    SC_NUMLOCK  = $45;
    SC_SCROLLLOCK = $46;
    SC_HOME     = $47;
    SC_UP       = $48;
    SC_PAGEUP   = $49;
    SC_MINUS2   = $4A;
    SC_LEFT     = $4B;
    SC_RIGHT    = $4D;
    SC_PLUS     = $4E;
    SC_END      = $4F;
    SC_DOWN     = $50;
    SC_PAGEDOWN = $51;
    SC_INSERT   = $52;
    SC_DELETE   = $53;
    SC_F11      = $57;
    SC_F12      = $58;
    SC_LWIN     = $7D;
    SC_RWIN     = $7E;
    SC_MENU     = $7F;
{ Fictive scan codes }
    SC_LALT     = $FC;  { Left ALT }
    SC_RALT     = $FD;  { Right ALT }
    SC_LCTRL    = $FE;  { Left CTRL }
    SC_RCTRL    = $FF;  { Right CTRL }

const
  patt_win_tracks: array[0..2,1..5] of String[176] = (
    ('ษออออหอออออออออออออออออออออออออออ PATTERN EDiTOR (  ) ออออออออออออออออออออออออออหออออป',
     'บLiNEบ 1            ณ 2            ณ 3            ณ 4            ณ 5            บLiNEบ',
     'ฬออออฮออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออฮออออน',
     'บ    บ              ณ              ณ              ณ              ณ              บ    บ',
     'ศออออสออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออสออออผ'),
    ('ษออออหออออออออออออออออออออออออออออออออออออออออออ PATTERN EDiTOR (  ) อออออออออออออออออออออออออออออออออออออออออหออออป',
     'บLiNEบ 1            ณ 2            ณ 3            ณ 4            ณ 5            ณ 6            ณ 7            บLiNEบ',
     'ฬออออฮออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออฮออออน',
     'บ    บ              ณ              ณ              ณ              ณ              ณ              ณ              บ    บ',
     'ศออออสออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออสออออผ'),
    ('ษออออหออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ PATTERN EDiTOR (  ) อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออหออออป',
     'บLiNEบ 1            ณ 2            ณ 3            ณ 4            ณ 5            ณ 6            ณ 7            ณ 8            ณ 9            ณ 10           ณ 11           บLiNEบ',
     'ฬออออฮออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออัออออออออออออออฮออออน',
     'บ    บ              ณ              ณ              ณ              ณ              ณ              ณ              ณ              ณ              ณ              ณ              บ    บ',
     'ศออออสออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออฯออออออออออออออสออออผ'));

  patt_win: array[1..5] of String[176] = ('','','','','');

  debug_win: array[1..3] of String[82] = (
    'ฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤลฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤลฤฤฤฤลฤฤฤฤฤยฤฤฤฤฤลฤฤยฤฤ',
    '   ณ                              ณ    ณ        ณ        ณ    ณ     ณ     ณ  ณ  ',
    'ฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤมฤฤฤฤฤมฤฤมฤฤ');

const
  inst_itm1: array[1..18] of Record str: String[24]; colr: Byte;
                             end = (

    (str: '~AM/ViB/EG/KSR/MUL~ ฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~KSL/VOLUME~ ฤฤฤฤฤฤฤฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~ATTACK/DECAY~ ฤฤฤฤฤฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~SUSTAiN/RELEASE~ ฤฤฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~WAVEFORM~ ฤฤฤฤฤฤฤฤฤฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~FEEDBACK/FM~ ฤฤฤฤฤฤฤฤฤ'; colr: 1),
    (str: '~PANNiNG~ ฤฤฤฤฤ';         colr: 1),
    (str: '~FiNE-TUNE~ ฤฤฤ';         colr: 1));

const
  inst_itm2: array[1..18] of Record str: String[24]; colr: Byte;
                             end = (

    (str: '~AM/ViB/EG/KSR/MUL~ ฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~KSL/VOLUME~ ฤฤฤฤฤฤฤฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~ATTACK/DECAY~ ฤฤฤฤฤฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~SUSTAiN/RELEASE~ ฤฤฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~WAVEFORM~ ฤฤฤฤฤฤฤฤฤฤฟ  '; colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~FEEDBACK/FM~ ฤฤฤฤฤฤฤฤฤ'; colr: 1),
    (str: '~PANNiNG~ ฤฤฤฤฤ';         colr: 1),
    (str: '~FiNE-TUNE~ ฤฤฤ';         colr: 1));


const
  note_layout: array[0..12*8+1] of String[3] = (
   '   ',
   'C-1','C#1','D-1','D#1','E-1','F-1','F#1','G-1','G#1','A-1','A#1','%-1',
   'C-2','C#2','D-2','D#2','E-2','F-2','F#2','G-2','G#2','A-2','A#2','%-2',
   'C-3','C#3','D-3','D#3','E-3','F-3','F#3','G-3','G#3','A-3','A#3','%-3',
   'C-4','C#4','D-4','D#4','E-4','F-4','F#4','G-4','G#4','A-4','A#4','%-4',
   'C-5','C#5','D-5','D#5','E-5','F-5','F#5','G-5','G#5','A-5','A#5','%-5',
   'C-6','C#6','D-6','D#6','E-6','F-6','F#6','G-6','G#6','A-6','A#6','%-6',
   'C-7','C#7','D-7','D#7','E-7','F-7','F#7','G-7','G#7','A-7','A#7','%-7',
   'C-8','C#8','D-8','D#8','E-8','F-8','F#8','G-8','G#8','A-8','A#8','%-8',
   'C-9');

const
  board_scancodes: array[1..29] of Byte = (
    $2c,$1f,$2d,$20,$2e,$2f,$22,$30,$23,$31,$24,$32,
    $10,$03,$11,$04,$12,$13,$06,$14,$07,$15,$08,$16,$17,$0a,$18,$0b,$19);

const
  fx_digits: array[0..44] of Char = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ&%!@=#$~^';
  NM_FX_DIGITS = SizeOf(fx_digits);

const
  b_note: Char = 'b';

const
  pos1: array[1..22] of Byte = (+07,+14,+21,+28,+35,+42,+49,+56,+63,+70,+77,+84,+91,+98,+105,+112,+119,+126,+133,+140,+147,+154);
  pos2: array[1..13] of Byte = (+00,+01,+03,+04,+06,+07,+09,+10,+12,+13,+14,+15,+16);
  { 0123456789ABCDEF }
  { ... 00 000 000ณ  }
  { ^   ^  ^   ^     }

  pos3: array[1..44] of Byte = (+00,+04,+07,+11,      {1}
                                +15,+19,+22,+26,      {2}
                                +30,+34,+37,+41,      {3}
                                +45,+49,+52,+56,      {4}
                                +60,+64,+67,+71,      {5}
                                +75,+79,+82,+86,      {6}
                                +90,+94,+97,+101,     {7}
                                +105,+109,+112,+116,  {8}
                                +120,+124,+127,+131,  {9}
                                +135,+139,+142,+146,  {10}
                                +150,+154,+157,+161); {11}
  { 0123456789ABCDEF }
  { ... 00 000 000ณ  }
  { ^ ^ ^^ ^^^ ^^^   }

  pos4: array[1..110] of Byte = (+00,+02,+04,+05,+07,+08,+09,+11,+12,+13,            {1}
                                 +15,+17,+19,+20,+22,+23,+24,+26,+27,+28,            {2}
                                 +30,+32,+34,+35,+37,+38,+39,+41,+42,+43,            {3}
                                 +45,+47,+49,+50,+52,+53,+54,+56,+57,+58,            {4}
                                 +60,+62,+64,+65,+67,+68,+69,+71,+72,+73,            {5}
                                 +75,+77,+79,+80,+82,+83,+84,+86,+87,+88,            {6}
                                 +90,+92,+94,+95,+97,+98,+99,+101,+102,+103,         {7}
                                 +105,+107,+109,+110,+112,+113,+114,+116,+117,+118,  {8}
                                 +120,+122,+124,+125,+127,+128,+129,+131,+132,+133,  {9}
                                 +135,+137,+139,+140,+142,+143,+144,+146,+147,+148,  {10}
                                 +150,+152,+154,+155,+157,+158,+159,+161,+162,+163); {11}

  pos5: array[1..35] of Byte = (+1,+3,+5,+7,+9,+11,+12,+14,+16,+18,
                                +19,+20,+21,+23,+25,+27,+29,+31,+33,+34,
                                +36,+38,+40,+41,+42,+43,+45,+47,
                                +49,+50,+51,+52,+54,+56,+57);

  pos6: array[1..11] of Byte = (+1,+2,+3,+5,+6,+8,+9,+10,+12,+13,+14);

const
  copymnu1: array[1..15] of String[30] = (
    ' COPY ORDER DEF.',
    ' COPY ORDER TABLE',
    ' COPY ~i~NSTRUMENT',
    ' COPY iNSTRUMENT ~B~ANK',
    ' COPY NOTE',
    ' COPY iNSTRUMENT DEF.',
    ' COPY 1ST EFFECT',
    ' COPY 2ND EFFECT',
    ' COPY LiNE',
    ' COPY TRACK',
    ' COPY PATTERN',
    ' COPY MARKED BLOCK',
    ' COPY MACRO-TABLE LiNE',
    ' COPY MACRO-TABLE COLUMN',
    ' COPY MACRO-TABLE');
  copymnu2: array[1..15] of String[30] = (
    ' COPY ORDER DEF.',
    ' COPY ORDER TABLE',
    ' COPY iNSTRUMENT',
    ' COPY iNSTRUMENT BANK',
    ' COPY ~N~OTE',
    ' COPY iN~S~TRUMENT DEF.',
    ' COPY ~1~ST EFFECT',
    ' COPY ~2~ND EFFECT',
    ' COPY ~L~iNE',
    ' COPY ~T~RACK',
    ' COPY ~P~ATTERN',
    '',
    ' COPY MACRO-TABLE LiNE',
    ' COPY MACRO-TABLE COLUMN',
    ' COPY MACRO-TABLE');
  copymnu3: array[1..15] of String[30] = (
    ' COPY ~O~RDER DEF.',
    ' COPY O~R~DER TABLE',
    ' COPY iNSTRUMENT',
    ' COPY iNSTRUMENT BANK',
    ' COPY NOTE',
    ' COPY iNSTRUMENT DEF.',
    ' COPY 1ST EFFECT',
    ' COPY 2ND EFFECT',
    ' COPY LiNE',
    ' COPY TRACK',
    ' COPY PATTERN',
    ' COPY MARKED BLOCK',
    ' COPY MACRO-TABLE LiNE',
    ' COPY MACRO-TABLE COLUMN',
    ' COPY MACRO-TABLE');
  copymnu4: array[1..15] of String[30] = (
    ' COPY ORDER DEF.',
    ' COPY ORDER TABLE',
    ' COPY iNSTRUMENT',
    ' COPY iNSTRUMENT BANK',
    ' COPY NOTE',
    ' COPY iNSTRUMENT DEF.',
    ' COPY 1ST EFFECT',
    ' COPY 2ND EFFECT',
    ' COPY LiNE',
    ' COPY TRACK',
    ' COPY PATTERN',
    ' COPY MARKED BLOCK',
    ' COPY M~A~CRO-TABLE LiNE',
    ' COPY MA~C~RO-TABLE COLUMN',
    ' COPY ~M~ACRO-TABLE');
  copymark: array[1..2] of String[30] = (
    ' COPY MARKED BLOCK',
    ' COPY MARKED BLOC~K~');
  copymacr: array[1..4] of String[30] = (
    ' COPY MACRO-TABLE LiNE',
    ' COPY M~A~CRO-TABLE LiNE',
    ' COPY MACRO-TABLE COLUMN',
    ' COPY MA~C~RO-TABLE COLUMN');

const
  _valid_characters: Set of Char = [#$00,#$20..#$7e,#$b0..#$df,#$fa,#$fb,#$fe,#$ff];

const
  _panning: array[0..2] of Byte = ($30,$10,$20);

const
  _instr:  array[0..11] of Byte = ($20, $20,
                                   $40, $40,
                                   $60, $60,
                                   $80, $80,
                                   $0e0,$0e0,
                                   $0c0,
                                   $0bd);
type
  tTRACK_ADDR = array[1..20] of Word;

const                    { 01 - 02 - 03 - 04 - 05 - 06 - 07 - 08 - 09 - 10 - 11 - 12 - 13 - 14 - 15 - 16 - 17 - 18 - 19 - 20 }
  _chmm_n: tTRACK_ADDR = ($003,$000,$004,$001,$005,$002,$006,$007,$008,$103,$100,$104,$101,$105,$102,$106,$107,$108,NULL,NULL);
  _chmm_m: tTRACK_ADDR = ($008,$000,$009,$001,$00a,$002,$010,$011,$012,$108,$100,$109,$101,$10a,$102,$110,$111,$112,NULL,NULL);
  _chmm_c: tTRACK_ADDR = ($00b,$003,$00c,$004,$00d,$005,$013,$014,$015,$10b,$103,$10c,$104,$10d,$105,$113,$114,$115,NULL,NULL);
                         {                                                                            BD   SD   TT   TC   HH }
  _chpm_n: tTRACK_ADDR = ($003,$000,$004,$001,$005,$002,$106,$107,$108,$103,$100,$104,$101,$105,$102,$006,$007,$008,$008,$007);
  _chpm_m: tTRACK_ADDR = ($008,$000,$009,$001,$00a,$002,$110,$111,$112,$108,$100,$109,$101,$10a,$102,$010,$014,$012,$015,$011);
  _chpm_c: tTRACK_ADDR = ($00b,$003,$00c,$004,$00d,$005,$113,$114,$115,$10b,$103,$10c,$104,$10d,$105,$013,NULL,NULL,NULL,NULL);

var
  _chan_n: tTRACK_ADDR;
  _chan_m: tTRACK_ADDR;
  _chan_c: tTRACK_ADDR;
  _ch_tmp: tTRACK_ADDR;

const
  tracing:    Boolean = FALSE;
  marking:    Boolean = FALSE;
  debugging:  Boolean = FALSE;
  quick_cmd:  Boolean = FALSE;

const
  ef_Arpeggio          = 0;
  ef_FSlideUp          = 1;
  ef_FSlideDown        = 2;
  ef_TonePortamento    = 3;
  ef_Vibrato           = 4;
  ef_TPortamVolSlide   = 5;
  ef_VibratoVolSlide   = 6;
  ef_FSlideUpFine      = 7;
  ef_FSlideDownFine    = 8;
  ef_SetModulatorVol   = 9;
  ef_VolSlide          = 10;
  ef_PositionJump      = 11;
  ef_SetInsVolume      = 12;
  ef_PatternBreak      = 13;
  ef_SetTempo          = 14;
  ef_SetSpeed          = 15;
  ef_TPortamVSlideFine = 16;
  ef_VibratoVSlideFine = 17;
  ef_SetCarrierVol     = 18;
  ef_SetWaveform       = 19;
  ef_VolSlideFine      = 20;
  ef_RetrigNote        = 21;
  ef_Tremolo           = 22;
  ef_Tremor            = 23;
  ef_ArpggVSlide       = 24;
  ef_ArpggVSlideFine   = 25;
  ef_MultiRetrigNote   = 26;
  ef_FSlideUpVSlide    = 27;
  ef_FSlideDownVSlide  = 28;
  ef_FSlUpFineVSlide   = 29;
  ef_FSlDownFineVSlide = 30;
  ef_FSlUpVSlF         = 31;
  ef_FSlDownVSlF       = 32;
  ef_FSlUpFineVSlF     = 33;
  ef_FSlDownFineVSlF   = 34;
  ef_Extended          = 35;
  ef_Extended2         = 36;
  ef_SetGlobalVolume   = 37;
  ef_SwapArpeggio      = 38;
  ef_SwapVibrato       = 39;
  ef_ForceInsVolume    = 40;
  ef_Extended3         = 41;
  ef_ExtraFineArpeggio = 42;
  ef_ExtraFineVibrato  = 43;
  ef_ExtraFineTremolo  = 44;
  ef_ex_SetTremDepth   = 0;
  ef_ex_SetVibDepth    = 1;
  ef_ex_SetAttckRateM  = 2;
  ef_ex_SetDecayRateM  = 3;
  ef_ex_SetSustnLevelM = 4;
  ef_ex_SetRelRateM    = 5;
  ef_ex_SetAttckRateC  = 6;
  ef_ex_SetDecayRateC  = 7;
  ef_ex_SetSustnLevelC = 8;
  ef_ex_SetRelRateC    = 9;
  ef_ex_SetFeedback    = 10;
  ef_ex_SetPanningPos  = 11;
  ef_ex_PatternLoop    = 12;
  ef_ex_PatternLoopRec = 13;
  ef_ex_MacroKOffLoop  = 14;
  ef_ex_ExtendedCmd    = 15;
  ef_ex_cmd_RSS        = 0;
  ef_ex_cmd_ResetVol   = 1;
  ef_ex_cmd_LockVol    = 2;
  ef_ex_cmd_UnlockVol  = 3;
  ef_ex_cmd_LockVP     = 4;
  ef_ex_cmd_UnlockVP   = 5;
  ef_ex_cmd_VSlide_mod = 6;
  ef_ex_cmd_VSlide_car = 7;
  ef_ex_cmd_VSlide_def = 8;
  ef_ex_cmd_LockPan    = 9;
  ef_ex_cmd_UnlockPan  = 10;
  ef_ex_cmd_VibrOff    = 11;
  ef_ex_cmd_TremOff    = 12;
  ef_ex_cmd_FineVibr   = 13;
  ef_ex_cmd_FineTrem   = 14;
  ef_ex_cmd_NoRestart  = 15;
  ef_ex2_PatDelayFrame = 0;
  ef_ex2_PatDelayRow   = 1;
  ef_ex2_NoteDelay     = 2;
  ef_ex2_NoteCut       = 3;
  ef_ex2_FineTuneUp    = 4;
  ef_ex2_FineTuneDown  = 5;
  ef_ex2_GlVolSlideUp  = 6;
  ef_ex2_GlVolSlideDn  = 7;
  ef_ex2_GlVolSlideUpF = 8;
  ef_ex2_GlVolSlideDnF = 9;
  ef_ex2_GlVolSldUpXF  = 10;
  ef_ex2_GlVolSldDnXF  = 11;
  ef_ex2_VolSlideUpXF  = 12;
  ef_ex2_VolSlideDnXF  = 13;
  ef_ex2_FreqSlideUpXF = 14;
  ef_ex2_FreqSlideDnXF = 15;
  ef_ex3_SetConnection = 0;
  ef_ex3_SetMultipM    = 1;
  ef_ex3_SetKslM       = 2;
  ef_ex3_SetTremoloM   = 3;
  ef_ex3_SetVibratoM   = 4;
  ef_ex3_SetKsrM       = 5;
  ef_ex3_SetSustainM   = 6;
  ef_ex3_SetMultipC    = 7;
  ef_ex3_SetKslC       = 8;
  ef_ex3_SetTremoloC   = 9;
  ef_ex3_SetVibratoC   = 10;
  ef_ex3_SetKsrC       = 11;
  ef_ex3_SetSustainC   = 12;

const
  ef_fix1 = $80;
  ef_fix2 = $90;

const
  a2m_default_path:    String  = '';
  a2t_default_path:    String  = '';
  a2i_default_path:    String  = '';
  a2f_default_path:    String  = '';
  a2p_default_path:    String  = '';
  a2b_default_path:    String  = '';
  a2w_default_path:    String  = '';
  sdl_screen_mode:     Byte = 0;
  sdl_opl3_emulator:   Byte = 0;
{$IFDEF WINDOWS}
  sdl_wav_directory:   String  = 'wav_files\';
{$ELSE}
  sdl_wav_directory:   String  = 'wav_files/';
{$ENDIF}
  sdl_sample_rate:     Longint = 44100;
  sdl_sample_buffer:   Longint = 2048;
  sdl_frame_rate:      Byte    = 100;
  sdl_typematic_delay: Longint = 250;
  sdl_typematic_rate:  Longint = 30;
  init_tempo:          Byte    = 50;
  init_speed:          Byte    = 6;
  init_macro_speedup:  Word    = 1;
  midiboard:           Boolean = TRUE;
  midisynth:           Boolean = FALSE;
  default_octave:      Byte    = 4;
  patt_len:            Word    = 64;
  nm_tracks:           Byte    = 18;
  mod_description:     Boolean = FALSE;
  highlight_controls:  Boolean = TRUE;
  use_H_for_B:         Boolean = FALSE;
  linefeed:            Boolean = TRUE;
  update_ins:          Boolean = FALSE;
  cycle_pattern:       Boolean = FALSE;
  command_typing:      Byte    = 1;
  backspace_dir:       Byte    = 1;
  mark_line:           Byte    = 4;
  scroll_bars:         Boolean = TRUE;
  ssaver_time:         Longint = 300;
  timer_fix:           Boolean = TRUE;
  decay_bar_rise:      Real    = 3.00;
  decay_bar_fall:      Real    = 0.30;
  force_ins:           Byte    = 0;
  pattern_layout:      Byte    = 0;
  trace_by_default:    Boolean = TRUE;
  nosync_by_default:   Boolean = FALSE;
  keep_position:       Boolean = TRUE;
  alt_ins_name:        Boolean = TRUE;
  adjust_tracks:       Boolean = TRUE;
  mark_lines:          Boolean = FALSE;
  accurate_conv:       Boolean = FALSE;
  fix_c_note_bug:      Boolean = TRUE;
  analyzer_bckg:       Byte    = $010;
  analyzer:            Byte    = $03;
  analyzer_ovrllvol:   Byte    = $03;
  analyzer_volumelvl:  Byte    = $07;
  analyzer_modulator:  Byte    = $02;
  analyzer_carrier:    Byte    = $03;
  pattern_bckg:        Byte    = $010;
  pattern_border:      Byte    = $0f;
  pattern_pos_indic:   Byte    = $0b;
  pattern_pan_indic:   Byte    = $03;
  pattern_gpan_indic:  Byte    = $0f;
  pattern_lock_indic:  Byte    = $07;
  pattern_4op_indic:   Byte    = $0e;
  pattern_perc_indic:  Byte    = $0f;
  pattern_chan_indic:  Byte    = $0e;
  pattern_row_bckg:    Byte    = $050;
  pattern_row_bckg_p:  Byte    = $0c0;
  pattern_row_bckg_m:  Byte    = $0b0;
  pattern_block_bckg:  Byte    = $020;
  pattern_line:        Byte    = $03;
  pattern_line_p:      Byte    = $00;
  pattern_line_m:      Byte    = $0b;
  pattern_hi_line:     Byte    = $0b;
  pattern_hi_line_m:   Byte    = $03;
  pattern_note:        Byte    = $07;
  pattern_hi_note:     Byte    = $0f;
  pattern_note0:       Byte    = $03;
  pattern_hi_note0:    Byte    = $0c;
  pattern_note_hid:    Byte    = $09;
  pattern_hi_note_h:   Byte    = $07;
  pattern_inst:        Byte    = $02;
  pattern_hi_inst:     Byte    = $0a;
  pattern_inst0:       Byte    = $02;
  pattern_hi_inst0:    Byte    = $0a;
  pattern_cmnd:        Byte    = $07;
  pattern_hi_cmnd:     Byte    = $0f;
  pattern_cmnd0:       Byte    = $03;
  pattern_hi_cmnd0:    Byte    = $0b;
  pattern_note_m:      Byte    = $09;
  pattern_note0_m:     Byte    = $09;
  pattern_note_hid_m:  Byte    = $0d;
  pattern_inst_m:      Byte    = $02;
  pattern_inst0_m:     Byte    = $02;
  pattern_cmnd_m:      Byte    = $09;
  pattern_cmnd0_m:     Byte    = $09;
  pattern_note_b:      Byte    = $0f;
  pattern_note0_b:     Byte    = $0b;
  pattern_note_hid_b:  Byte    = $05;
  pattern_inst_b:      Byte    = $0a;
  pattern_inst0_b:     Byte    = $0a;
  pattern_cmnd_b:      Byte    = $0f;
  pattern_cmnd0_b:     Byte    = $0b;
  pattern_fix_note:    Byte    = $0b;
  pattern_hi_fx_note:  Byte    = $0e;
  pattern_fix_note_m:  Byte    = $0e;
  pattern_fix_note_b:  Byte    = $0e;
  pattern_cmnd_ctrl:   Byte    = $0d;
  pattern_input_bckg:  Byte    = $0b0;
  pattern_input:       Byte    = $00;
  pattern_input_warn:  Byte    = $080;
  debug_info_bckg:     Byte    = $040;
  debug_info_border:   Byte    = $05;
  debug_info_topic:    Byte    = $0e;
  debug_info_txt:      Byte    = $07;
  debug_info_hi_txt:   Byte    = $0f;
  debug_info_txt_hid:  Byte    = $06;
  debug_info_mod:      Byte    = $02;
  debug_info_hi_mod:   Byte    = $0a;
  debug_info_car:      Byte    = $03;
  debug_info_hi_car:   Byte    = $0b;
  debug_info_4op:      Byte    = $08;
  debug_info_perc:     Byte    = $08;
  help_background:     Byte    = $040;
  help_title:          Byte    = $0b;
  help_border:         Byte    = $0f;
  help_topic:          Byte    = $0c;
  help_text:           Byte    = $07;
  help_hi_text:        Byte    = $0c;
  help_keys:           Byte    = $0f;
  help_indicators:     Byte    = $0e;
  dialog_background:   Byte    = $040;
  dialog_title:        Byte    = $0b;
  dialog_border:       Byte    = $0f;
  dialog_text:         Byte    = $0d;
  dialog_hi_text:      Byte    = $0e;
  dialog_hid:          Byte    = $06;
  dialog_button:       Byte    = $0f;
  dialog_short:        Byte    = $0e;
  dialog_button_dis:   Byte    = $07;
  dialog_sel_btn_bck:  Byte    = $070;
  dialog_sel_btn:      Byte    = $00;
  dialog_sel_short:    Byte    = $04;
  dialog_context:      Byte    = $0e;
  dialog_context_dis:  Byte    = $07;
  dialog_input_bckg:   Byte    = $070;
  dialog_input:        Byte    = $00;
  dialog_def_bckg:     Byte    = $0c0;
  dialog_def:          Byte    = $00;
  dialog_prog_bar1:    Byte    = $09;
  dialog_prog_bar2:    Byte    = $0b;
  macro_background:    Byte    = $040;
  macro_title:         Byte    = $0b;
  macro_border:        Byte    = $0f;
  macro_topic:         Byte    = $0c;
  macro_text:          Byte    = $0d;
  macro_hi_text:       Byte    = $0e;
  macro_text_dis:      Byte    = $06;
  macro_text_loop:     Byte    = $0c;
  macro_text_keyoff:   Byte    = $03;
  macro_current_bckg:  Byte    = $050;
  macro_current:       Byte    = $0d;
  macro_current_dis:   Byte    = $00;
  macro_current_loop:  Byte    = $0c;
  macro_current_koff:  Byte    = $0b;
  macro_input_bckg:    Byte    = $070;
  macro_input:         Byte    = $00;
  macro_def_bckg:      Byte    = $0c0;
  macro_def:           Byte    = $00;
  macro_scrbar_bckg:   Byte    = $070;
  macro_scrbar_text:   Byte    = $00;
  macro_scrbar_mark:   Byte    = $0f;
  macro_hint:          Byte    = $07;
  menu_background:     Byte    = $040;
  menu_title:          Byte    = $0b;
  menu_border:         Byte    = $0f;
  menu_topic:          Byte    = $0d;
  menu_hi_topic:       Byte    = $0e;
  menu_item:           Byte    = $0f;
  menu_short:          Byte    = $0e;
  menu_item_dis:       Byte    = $07;
  menu_sel_item_bckg:  Byte    = $070;
  menu_sel_item:       Byte    = $00;
  menu_sel_short:      Byte    = $04;
  menu_default_bckg:   Byte    = $0c0;
  menu_default:        Byte    = $00;
  menu_context:        Byte    = $0e;
  menu_context_dis:    Byte    = $07;
  scrollbar_bckg:      Byte    = $030;
  scrollbar_text:      Byte    = $00;
  scrollbar_mark:      Byte    = $0b;
  scrollbar_2nd_mark:  Byte    = $0f;
  main_background:     Byte    = $010;
  main_title:          Byte    = $0b;
  main_border:         Byte    = $0b;
  main_stat_line:      Byte    = $03;
  main_hi_stat_line:   Byte    = $0b;
  main_behavior:       Byte    = $0d;
  status_background:   Byte    = $010;
  status_border:       Byte    = $0e;
  status_static_txt:   Byte    = $0b;
  status_dynamic_txt:  Byte    = $0f;
  status_play_state:   Byte    = $07;
  status_text_dis:     Byte    = $05;
  order_background:    Byte    = $010;
  order_hi_bckg:       Byte    = $050;
  order_border:        Byte    = $0a;
  order_entry:         Byte    = $03;
  order_hi_entry:      Byte    = $0b;
  order_pattn:         Byte    = $07;
  order_pattn_jump:    Byte    = $02;
  order_hi_pattn:      Byte    = $0f;
  order_played_b:      Byte    = $0c0;
  order_played:        Byte    = $00;
  order_input_bckg:    Byte    = $0b0;
  order_input:         Byte    = $00;
  order_input_warn:    Byte    = $0c0;
  instrument_bckg:     Byte    = $040;
  instrument_title:    Byte    = $0b;
  instrument_border:   Byte    = $0f;
  instrument_text:     Byte    = $07;
  instrument_hi_text:  Byte    = $0f;
  instrument_glob:     Byte    = $0d;
  instrument_hi_glob:  Byte    = $0f;
  instrument_hid:      Byte    = $06;
  instrument_mod:      Byte    = $02;
  instrument_car:      Byte    = $03;
  instrument_hi_mod:   Byte    = $0a;
  instrument_hi_car:   Byte    = $0b;
  instrument_context:  Byte    = $0e;
  instrument_adsr:     Byte    = $10;
  instrument_ai_off:   Byte    = $06;
  instrument_ai_on:    Byte    = $0d;
  instrument_ai_trig:  Byte    = $0e;

const
  rgb_color: array[0..15] of tRGB = (
    (r: 00 SHL 2; g: 00 SHL 2; b: 00 SHL 2; a: 00),
    (r: 05 SHL 2; g: 10 SHL 2; b: 30 SHL 2; a: 00),
    (r: 00 SHL 2; g: 30 SHL 2; b: 30 SHL 2; a: 00),
    (r: 00 SHL 2; g: 30 SHL 2; b: 40 SHL 2; a: 00),
    (r: 00 SHL 2; g: 00 SHL 2; b: 20 SHL 2; a: 00),
    (r: 15 SHL 2; g: 25 SHL 2; b: 35 SHL 2; a: 00),
    (r: 00 SHL 2; g: 10 SHL 2; b: 25 SHL 2; a: 00),
    (r: 20 SHL 2; g: 30 SHL 2; b: 40 SHL 2; a: 00),
    (r: 45 SHL 2; g: 35 SHL 2; b: 50 SHL 2; a: 00),
    (r: 10 SHL 2; g: 20 SHL 2; b: 30 SHL 2; a: 00),
    (r: 20 SHL 2; g: 40 SHL 2; b: 40 SHL 2; a: 00),
    (r: 20 SHL 2; g: 40 SHL 2; b: 50 SHL 2; a: 00),
    (r: 25 SHL 2; g: 35 SHL 2; b: 50 SHL 2; a: 00),
    (r: 30 SHL 2; g: 35 SHL 2; b: 45 SHL 2; a: 00),
    (r: 35 SHL 2; g: 60 SHL 2; b: 60 SHL 2; a: 00),
    (r: 40 SHL 2; g: 50 SHL 2; b: 55 SHL 2; a: 00));

const
  vga_rgb_color: array[0..15] of tRGB = (
    (r: $000; g: $000; b: $000; a: 00),
    (r: $000; g: $000; b: $0aa; a: 00),
    (r: $000; g: $0aa; b: $000; a: 00),
    (r: $000; g: $0aa; b: $0aa; a: 00),
    (r: $0aa; g: $000; b: $000; a: 00),
    (r: $0aa; g: $000; b: $0aa; a: 00),
    (r: $0aa; g: $055; b: $000; a: 00),
    (r: $0aa; g: $0aa; b: $0aa; a: 00),
    (r: $055; g: $055; b: $055; a: 00),
    (r: $055; g: $055; b: $0ff; a: 00),
    (r: $055; g: $0ff; b: $055; a: 00),
    (r: $055; g: $0ff; b: $0ff; a: 00),
    (r: $0ff; g: $055; b: $055; a: 00),
    (r: $0ff; g: $055; b: $0ff; a: 00),
    (r: $0ff; g: $0ff; b: $055; a: 00),
    (r: $0ff; g: $0ff; b: $0ff; a: 00));

const
  fade_delay_tab: array[0..63] of Byte = (
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    3,3,3,3,3,3,3,3,3,3,3,
    4,4,4,4,4,4,4,
    5,5,5,5);
