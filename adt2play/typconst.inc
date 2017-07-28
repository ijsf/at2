const
  NULL = $0ffffffff;
  BYTE_NULL = BYTE(NULL);
  WORD_NULL = WORD(NULL);
  DWORD_NULL = LONGINT(NULL);

const
  FFVER_A2M = 13;
  FFVER_A2T = 13;
  FFVER_A2I = 10;
  FFVER_A2F = 2;
  FFVER_A2P = 11;
  FFVER_A2B = 10;
  FFVER_A2W = 3;

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
  tARP_VIB_MACRO_TABLE = array[1..255] of tMACRO_TABLE;

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
  tINS_4OP_FLAGS = Record
                     num_4op: Byte;
                     idx_4op: array[1..128] of Byte;
                   end;
type
  pOLD_FIXED_SONGDATA = ^tOLD_FIXED_SONGDATA;
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
const
  MB_SIGNATURE = 'MB_1'; // Message Board v1.0
  MB_HSIZE = 50;         // 50x20 chr
  MB_VSIZE = 20;

type
  pMESSAGE_BOARD_DATA = ^tMESSAGE_BOARD_DATA;
  tMESSAGE_BOARD_DATA = Record
                          signature: array[0..3] of Char;
                          data: array[1..MB_VSIZE] of String[MB_HSIZE];
                        end;
type
  pFIXED_SONGDATA = ^tFIXED_SONGDATA;
  tFIXED_SONGDATA = Record
                      songname:      String[42];
                      composer:      String[42];
                      instr_names:   array[1..255] of String[42];
                      instr_data:    array[1..255] of tADTRACK2_INS;
                      instr_macros:  array[1..255] of tREGISTER_TABLE;
                      macro_table:   tARP_VIB_MACRO_TABLE;
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
                      ins_4op_flags: tINS_4OP_FLAGS;
                      reserved_data: array[0..PRED(1024)] of Byte;
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
  tOLD_VARIABLE_DATA1 = array[0..$0f] of array[0..$3f] of
                        array[1..9]   of tOLD_CHUNK;
type
  tOLD_VARIABLE_DATA2 = array[0..7]   of array[1..18] of
                        array[0..$3f] of tOLD_CHUNK;
type
  tVARIABLE_DATA = array[0..7]    of array[1..20] of
                   array[0..$0ff] of tCHUNK;
type
  tPATTERN_DATA = array[0..15] of tVARIABLE_DATA;

type
  tPLAY_STATUS = (isPlaying,isPaused,isStopped);

type
  tByteSet = Set of Byte;

const
  INSTRUMENT_SIZE = SizeOf(tADTRACK2_INS);
  CHUNK_SIZE = SizeOf(tCHUNK);
  PATTERN_SIZE = 20*256*CHUNK_SIZE;

type
  tCHAR8x8  = array[char] of array[0..7] of Byte;
  tCHAR8x16 = array[char] of array[0..15] of Byte;

type
  tRGB = Record r,g,b: Byte end;
  tRGB_PALETTE = array[0..255] of tRGB;

const
  ef_Arpeggio           = 0;
  ef_FSlideUp           = 1;
  ef_FSlideDown         = 2;
  ef_TonePortamento     = 3;
  ef_Vibrato            = 4;
  ef_TPortamVolSlide    = 5;
  ef_VibratoVolSlide    = 6;
  ef_FSlideUpFine       = 7;
  ef_FSlideDownFine     = 8;
  ef_SetModulatorVol    = 9;
  ef_VolSlide           = 10;
  ef_PositionJump       = 11;
  ef_SetInsVolume       = 12;
  ef_PatternBreak       = 13;
  ef_SetTempo           = 14;
  ef_SetSpeed           = 15;
  ef_TPortamVSlideFine  = 16;
  ef_VibratoVSlideFine  = 17;
  ef_SetCarrierVol      = 18;
  ef_SetWaveform        = 19;
  ef_VolSlideFine       = 20;
  ef_RetrigNote         = 21;
  ef_Tremolo            = 22;
  ef_Tremor             = 23;
  ef_ArpggVSlide        = 24;
  ef_ArpggVSlideFine    = 25;
  ef_MultiRetrigNote    = 26;
  ef_FSlideUpVSlide     = 27;
  ef_FSlideDownVSlide   = 28;
  ef_FSlUpFineVSlide    = 29;
  ef_FSlDownFineVSlide  = 30;
  ef_FSlUpVSlF          = 31;
  ef_FSlDownVSlF        = 32;
  ef_FSlUpFineVSlF      = 33;
  ef_FSlDownFineVSlF    = 34;
  ef_Extended           = 35;
  ef_Extended2          = 36;
  ef_SetGlobalVolume    = 37;
  ef_SwapArpeggio       = 38;
  ef_SwapVibrato        = 39;
  ef_ForceInsVolume     = 40;
  ef_Extended3          = 41;
  ef_ExtraFineArpeggio  = 42;
  ef_ExtraFineVibrato   = 43;
  ef_ExtraFineTremolo   = 44;
  ef_SetCustomSpeedTab  = 45;
  ef_GlobalFSlideUp     = 46;
  ef_GlobalFSlideDown   = 47;
  ef_ex_SetTremDepth    = 0;
  ef_ex_SetVibDepth     = 1;
  ef_ex_SetAttckRateM   = 2;
  ef_ex_SetDecayRateM   = 3;
  ef_ex_SetSustnLevelM  = 4;
  ef_ex_SetRelRateM     = 5;
  ef_ex_SetAttckRateC   = 6;
  ef_ex_SetDecayRateC   = 7;
  ef_ex_SetSustnLevelC  = 8;
  ef_ex_SetRelRateC     = 9;
  ef_ex_SetFeedback     = 10;
  ef_ex_SetPanningPos   = 11;
  ef_ex_PatternLoop     = 12;
  ef_ex_PatternLoopRec  = 13;
  ef_ex_ExtendedCmd     = 14;
  ef_ex_cmd_MKOffLoopDi = 0;
  ef_ex_cmd_MKOffLoopEn = 1;
  ef_ex_cmd_TPortaFKdis = 2;
  ef_ex_cmd_TPortaFKenb = 3;
  ef_ex_cmd_RestartEnv  = 4;
  ef_ex_cmd_4opVlockOff = 5;
  ef_ex_cmd_4opVlockOn  = 6;
  ef_ex_ExtendedCmd2    = 15;
  ef_ex_cmd2_RSS        = 0;
  ef_ex_cmd2_ResetVol   = 1;
  ef_ex_cmd2_LockVol    = 2;
  ef_ex_cmd2_UnlockVol  = 3;
  ef_ex_cmd2_LockVP     = 4;
  ef_ex_cmd2_UnlockVP   = 5;
  ef_ex_cmd2_VSlide_mod = 6;
  ef_ex_cmd2_VSlide_car = 7;
  ef_ex_cmd2_VSlide_def = 8;
  ef_ex_cmd2_LockPan    = 9;
  ef_ex_cmd2_UnlockPan  = 10;
  ef_ex_cmd2_VibrOff    = 11;
  ef_ex_cmd2_TremOff    = 12;
  ef_ex_cmd2_FVib_FGFS  = 13;
  ef_ex_cmd2_FTrm_XFGFS = 14;
  ef_ex_cmd2_NoRestart  = 15;
  ef_ex2_PatDelayFrame  = 0;
  ef_ex2_PatDelayRow    = 1;
  ef_ex2_NoteDelay      = 2;
  ef_ex2_NoteCut        = 3;
  ef_ex2_FineTuneUp     = 4;
  ef_ex2_FineTuneDown   = 5;
  ef_ex2_GlVolSlideUp   = 6;
  ef_ex2_GlVolSlideDn   = 7;
  ef_ex2_GlVolSlideUpF  = 8;
  ef_ex2_GlVolSlideDnF  = 9;
  ef_ex2_GlVolSldUpXF   = 10;
  ef_ex2_GlVolSldDnXF   = 11;
  ef_ex2_VolSlideUpXF   = 12;
  ef_ex2_VolSlideDnXF   = 13;
  ef_ex2_FreqSlideUpXF  = 14;
  ef_ex2_FreqSlideDnXF  = 15;
  ef_ex3_SetConnection  = 0;
  ef_ex3_SetMultipM     = 1;
  ef_ex3_SetKslM        = 2;
  ef_ex3_SetTremoloM    = 3;
  ef_ex3_SetVibratoM    = 4;
  ef_ex3_SetKsrM        = 5;
  ef_ex3_SetSustainM    = 6;
  ef_ex3_SetMultipC     = 7;
  ef_ex3_SetKslC        = 8;
  ef_ex3_SetTremoloC    = 9;
  ef_ex3_SetVibratoC    = 10;
  ef_ex3_SetKsrC        = 11;
  ef_ex3_SetSustainC    = 12;

const
  ef_fix1 = $80;
  ef_fix2 = $90;

const
  _panning: array[0..2] of Byte = ($30,$10,$20);

const
  _instr_data_ofs: array[1..13] of Byte = (1,0,3,2,5,4,7,6,9,8,10,11,12);
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
  _chmm_n: tTRACK_ADDR = ($003,$000,$004,$001,$005,$002,$006,$007,$008,$103,$100,$104,$101,$105,$102,$106,$107,$108,BYTE_NULL,BYTE_NULL);
  _chmm_m: tTRACK_ADDR = ($008,$000,$009,$001,$00a,$002,$010,$011,$012,$108,$100,$109,$101,$10a,$102,$110,$111,$112,BYTE_NULL,BYTE_NULL);
  _chmm_c: tTRACK_ADDR = ($00b,$003,$00c,$004,$00d,$005,$013,$014,$015,$10b,$103,$10c,$104,$10d,$105,$113,$114,$115,BYTE_NULL,BYTE_NULL);
                         {                                                                            BD   SD   TT   TC   HH }
  _chpm_n: tTRACK_ADDR = ($003,$000,$004,$001,$005,$002,$106,$107,$108,$103,$100,$104,$101,$105,$102,$006,$007,$008,$008,$007);
  _chpm_m: tTRACK_ADDR = ($008,$000,$009,$001,$00a,$002,$110,$111,$112,$108,$100,$109,$101,$10a,$102,$010,$014,$012,$015,$011);
  _chpm_c: tTRACK_ADDR = ($00b,$003,$00c,$004,$00d,$005,$113,$114,$115,$10b,$103,$10c,$104,$10d,$105,$013,BYTE_NULL,BYTE_NULL,BYTE_NULL,BYTE_NULL);

var
  _chan_n: tTRACK_ADDR;
  _chan_m: tTRACK_ADDR;
  _chan_c: tTRACK_ADDR;

const
  _4op_tracks_hi: Set of Byte = [1,3,5,10,12,14];
  _4op_tracks_lo: Set of Byte = [2,4,6,11,13,15];
  _4op_main_chan: array[1..6] of Byte = (2,4,6,11,13,15);

const
  _debug_str_: String = '';
