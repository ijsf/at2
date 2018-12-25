//  This file is part of Adlib Tracker II (AT2).
//
//  AT2 is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  AT2 is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with AT2.  If not, see <http://www.gnu.org/licenses/>.

const
  frame_solid_type1 = '        ';
  frame_solid_type2 = 'Û฿ÛÛÛÛÜÛ';
  frame_single      = 'ฺฤฟณณภฤู';
  frame_double      = 'ษอปบบศอผ';
  frame_double_side = 'ึฤทบบำฤฝ';
  frame_double_top  = 'ีอธณณิอพ';

const
  prog_exception_title =
    'ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ'#13#10+
    'Û ABNORMAL PROGRAM TERMiNATiON Û'#13#10+
    '฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿'#13#10;

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
  patt_tab_str: array[0..4] of String[18] = (
    'ออออออออออออออ',
    '~~อ~~อออออออออออ',
    'ออออ~~ออออออออ',
    'อออออออ~~ออออ',
    'อออออออออออ~~');

  ins_pan_str1: array[0..2] of String[23] = (
    '~๚~๚๚๚๚๚~~๚๚๚๚๚~๚~',
    '~~๚๚๚~๚~๚๚๚๚๚๚๚~๚~',
    '~๚~๚๚๚๚๚๚๚~๚~๚๚๚~~');

  ins_pan_str2: array[0..2] of String[7] = (
    '๚๚๚๚',
    '๚๚๚๚',
    '๚๚๚๚');

  voice_pan_str: array[0..3] of String[13] = (
    '~๚~๚~~๚~๚~',
    '~~~๚~๚๚~๚~',
    '~๚~๚๚~๚~~~',
    '๚๚๚๚๚๚๚');

  note_keyoff_str: array[0..2] of String[3] = (
    'þþþ',
    'อออ',
    '^^๚');

  perc_voice_str: array[0..5] of String[7] = (
    'MELODiC',
    'PERC:BD',
    'PERC:SD',
    'PERC:TT',
    'PERC:TC',
    'PERC:HH');

  a2b_header_str: array[1..3] of String[74] = (
    ' iNSTRUMENT                                 PANNiNG            iNSTRUMENT ',
    ' NAME    DESCRiPTiON                        ช  c  ซ   F.TUNE   VOiCE      ',
    'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');

  a2b_header_hires_str: array[1..3] of String[104] = (
    ' iNSTRUMENT                                                               PANNiNG            iNSTRUMENT ',
    ' NAME    DESCRiPTiON                        ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0   ช  c  ซ   F.TUNE   VOiCE      ',
    'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');

  av_browser_str: array[1..6] of String[75] = (
    'ฤฤฤฤาฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤาฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ',
    '    บ     ~ARPEGGiO MACRO TABLE~     บ        ~ViBRATO MACRO TABLE~',
    '    วฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤฤืฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤฤ',
    ' NO.บLEN. ณSPEEDณL.BEGณL.LENณK.OFF บLEN. ณSPEEDณDELAYณL.BEGณL.LENณK.OFF ',
    'ออออฮอออออุอออออุอออออุอออออุออออออฮอออออุอออออุอออออุอออออุอออออุออออออ',
    'ออออสอออออฯอออออฯอออออฯอออออฯออออออสอออออฯอออออฯอออออฯอออออฯอออออฯออออออ');

  a2w_header_str: array[1..3] of String[72] = (
    ' iNSTRUMENT                                 iNSTRUMENT                  ',
    ' NAME    DESCRiPTiON                        VOiCE     MACROS            ',
    'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');

  a2w_header_hires1_str: array[1..3] of String[102] = (
    ' iNSTRUMENT                                                               iNSTRUMENT                  ',
    ' NAME    DESCRiPTiON                        ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0   VOiCE     MACROS            ',
    'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');

  a2w_header_hires2_str: array[1..3] of String[121] = (
    ' iNSTRUMENT                                                               PANNiNG            iNSTRUMENT                  ',
    ' NAME    DESCRiPTiON                        ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0   ช  c  ซ   F.TUNE   VOiCE     MACROS            ',
    'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');

  bnk_header_str: array[1..3] of String[72] = (
    ' iNSTRUMENT                                  MELODiC/                   ',
    ' NAME         ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0    PERCUSSiON (VOiCE)         ',
    'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');

  fib_header_str: array[1..3] of String[72] = (
    ' DOS       iNSTRUMENT                                                   ',
    ' NAME      NAME                          ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0    ',
    'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');

  ibk_header_str: array[1..3] of String[44] = (
    ' iNSTRUMENT                                 ',
    ' NAME         ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0   ',
    'ออออออออออออออออออออออออออออออออออออออออออออ');

  debug_win_str1: array[1..3] of String[130] = (
    '     TRACK     ~ณ~          iNSTRUMENT          ~ณ~NOTE~ณ ~FX N๙1~ ณ ~FX N๙2~ ณ~FREQ~ณ ~VOL',
    'ฤฤยฤฤยฤฤฤยฤฤยฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤลฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤลฤฤฤฤลฤฤยฤฤ',
    'ฤฤมฤฤมฤฤฤมฤฤมฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤมฤฤ');

  debug_win_str2: array[1..3] of String[130] = (
    'TRACK~ณ~iNS~ณ~NOTE~ณ ~FX N๙1~ ณ ~FX N๙2~ ณ~FREQ~ณ~CN/FB/ADSR/WF/KSL/MUL/TRM/ViB/KSR/EG~ณ ~VOL',
    'ฤฤยฤฤลฤฤฤลฤฤฤฤลฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤลฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤยฤฤ',
    'ฤฤมฤฤมฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤมฤฤ');

  debug_win_str3: array[1..3] of String[130] = (
    'TRACK~ณ~iNS~ณ~NOTE~ณ ~FX N๙1~ ณ ~FX N๙2~ ณ~MACRO FM-REG~ ณ~MACRO ARPG~ณ~MACRO ViBR ~ณ~FREQ~ณ ~VOL',
    'ฤฤยฤฤลฤฤฤลฤฤฤฤลฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤลฤฤยฤฤ',
    'ฤฤมฤฤมฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤมฤฤ');

const
  inst_itm1: array[1..18] of Record str: String[24]; colr: Byte;
                             end = (

    (str: '~ENV.TYPE/MULT~ ฤฤฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~KSL/VOLUME~ ฤฤฤฤฤฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~ATTACK/DECAY~ ฤฤฤฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~SUSTAiN/RELEASE~ ฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~WAVEFORM~ ฤฤฤฤฤฤฤฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~CONNECTiON/FB~  ฤฤ';   colr: 1),
    (str: '~PANNiNG~  ฤฤ';         colr: 1),
    (str: '~F-TUNE~   ฤฤ';         colr: 1));

const
  inst_itm2: array[1..18] of Record str: String[25]; colr: Byte;
                             end = (

    (str: '~ENV.TYPE/MULT~ ฤฤฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~KSL/VOLUME~ ฤฤฤฤฤฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~ATTACK/DECAY~ ฤฤฤฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~SUSTAiN/RELEASE~ ฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~WAVEFORM~ ฤฤฤฤฤฤฤฤฤฤฟ  ';   colr: 1),
    (str: '~Carrier~            รฤ'; colr: 3),
    (str: '~Modulator~          ภฤ'; colr: 2),
    (str: '~CONNECTiON/FB~  ฤฤ';   colr: 1),
    (str: '~PANNiNG~  ฤฤ';         colr: 1),
    (str: '~F-TUNE~   ฤฤ';         colr: 1));

const
  inst_text: array[1..23] of String[72] = (
    '~ATTACK RATE~   ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ                     ~WAVEFORM TYPE~',
    '~DECAY RATE~    ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ                     ( ) Sine',
    '                                                  ( ) Half-Sine',
    '~SUSTAiN LEVEL~ ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ                     ( ) Abs-Sine',
    '~RELEASE RATE~  ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ                     ( ) Pulse-Sine',
    '                                                  ( ) Sine (EPO)',
    '~OUTPUT LEVEL~  ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ     ( ) Abs-Sine (EPO)',
    '                                                  ( ) Square',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '~ENVELOPE TYPE              FREQUENCY DATA MULTiPLiER~',
    '[ ] Tremolo (AM)',
    '[ ] Vibrato                ( )'#159'0 ( )'#159'1  ( )'#159'2  ( )'#159'3  ( )'#159'4  ( )'#159'5',
    '[ ] Key scale rate (KSR)   ( )'#159'6  ( )'#159'7  ( )'#159'8  ( )'#159'9  ( )'#159'10 ( )'#159'10',
    '[ ] Sustain                ( )'#159'12 ( )'#159'12 ( )'#159'15 ( )'#159'15');

const
  inst_text_ext_2op: array[1..9] of String[72] = (
    '~KEY SCALiNG LEVEL~   `GLOBAL iNSTRUMENT SETTiNGS`    ( ) Derived square',
    '( ) Default         ``',
    '( ) 1.5 dB/octave   `CONNECTiON`                    `FEEDBACK`',
    '( ) 3.0 dB/octave   ( ) FM                        ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ',
    '( ) 6.0 dB/octave   ( ) AM                        MiN           MAX',
    '                    ^( ) FM/FM^',
    '~PANNiNG~             ^( ) FM/AM^                     `F-TUNE`',
    'ช       c       ซ   ^( ) AM/FM^                     ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ',
    '๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚   ^( ) AM/AM^                     -       ๙       +');

const
  inst_text_ext_perc: array[1..9] of String[72] = (
    '~KEY SCALiNG LEVEL~   ^GLOBAL iNSTRUMENT SETTiNGS^    ( ) Derived square',
    '( ) Default         ^^',
    '( ) 1.5 dB/octave   ^CONNECTiON                    FEEDBACK        0^',
    '( ) 3.0 dB/octave   ^( ) FM                        ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ^',
    '( ) 6.0 dB/octave   ^( ) AM                        MiN           MAX^',
    '                    ^( ) FM/FM^',
    '~PANNiNG~             ^( ) FM/AM^                     `F-TUNE`',
    'ช       c       ซ   ^( ) AM/FM^                     ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ',
    '๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚   ^( ) AM/AM^                     -       ๙       +');

const
  inst_text_ext_4op: array[1..9] of String[72] = (
    '~KEY SCALiNG LEVEL~   `GLOBAL iNSTRUMENT SETTiNGS`    ( ) Derived square',
    '( ) Default         ``',
    '( ) 1.5 dB/octave   `CONNECTiON`                    `FEEDBACK`',
    '( ) 3.0 dB/octave   ^( ) FM^                        ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ',
    '( ) 6.0 dB/octave   ^( ) AM^                        MiN           MAX',
    '                    ( ) FM/FM',
    '~PANNiNG~             ( ) FM/AM                     `F-TUNE`',
    'ช       c       ซ   ( ) AM/FM                     ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ',
    '๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚   ( ) AM/AM                     -       ๙       +');

const
  inst_con_scheme: array[0..6,1..6] of String[17] = (
    ('                 ',
     '                 ',
     '   ฺฤฤฤฟ         ',
     '   ภÛ1ÛมÛ2Û'#26'     ',
     '                 ',
     '                 '),
    ('                 ',
     '   ฺฤฤฤฟ         ',
     '   ภÛ1Ûมฟ        ',
     '        ณ        ',
     '    Û2Ûฤม'#26'       ',
     '                 '),
    ('                 ',
     '                 ',
     'ฺฤฤฤฟ            ',
     'ภÛ1ÛมÛ2ÛฤÛ3ÛฤÛ4Û'#26,
     '                 ',
     '                 '),
    ('                 ',
     ' ฺฤฤฤฟ           ',
     ' ภÛ1Ûมฤฤฤฤฤฤฤฤฟ  ',
     '              ณ  ',
     '  Û2ÛฤÛ3ÛฤÛ4Ûฤม'#26' ',
     '                 '),
    ('                 ',
     '  ฺฤฤฤฟ          ',
     '  ภÛ1ÛมÛ2Ûฤฟ     ',
     '           ร'#26'    ',
     '   Û3ÛฤÛ4Ûฤู    ',
     '                 '),
    (' ฺฤฤฤฟ           ',
     ' ภÛ1Ûมฤฤฤฤฟ      ',
     '          ณ      ',
     '  Û2ÛฤÛ3Ûฤล'#26'     ',
     '          ณ      ',
     '  Û4Ûฤฤฤฤฤู      '),
    ('                 ',
     '                 ',
     '                 ',
     '                 ',
     '                 ',
     '                 '));

const
  copy_menu_str1: array[1..15] of String[30] = (
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

  copy_menu_str2: array[1..15] of String[30] = (
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

  copy_menu_str3: array[1..15] of String[30] = (
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

  copy_menu_str4: array[1..15] of String[30] = (
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

  copy_marked_str: array[1..2] of String[30] = (
    ' COPY MARKED BLOCK',
    ' COPY MARKED BLOC~K~');

  copy_macro_str: array[1..4] of String[30] = (
    ' COPY MACRO-TABLE LiNE',
    ' COPY M~A~CRO-TABLE LiNE',
    ' COPY MACRO-TABLE COLUMN',
    ' COPY MA~C~RO-TABLE COLUMN');

const
  transp_menu_str1: array[1..17] of String[50] = (
    ' [~1~]   1 UP   ฟ',
    ' [~2~]  12 UP   ๖ CURRENT',
    ' [~3~]   1 DOWN ๘ iNSTRUMENT         ฺฤฤฤฤฤฤฤฤฤฟ',
    '',
    ' [~5~]   1 UP   ฟ                    ภฤฤฤฤฤฤฤฤฤู',
    ' [~6~]  12 UP   ๖ ALL',
    ' [~7~]   1 DOWN ๘ iNSTRUMENTS',
    ' [~8~]  12 DOWN ู',
    '',
    ' [~A~]   1 UP   ฟ',
    ' [~B~]  12 UP   ๖ CURRENT',
    ' [~C~]   1 DOWN ๘ iNSTRUMENT         ฺฤฤฤฤฤฤฤฤฤฟ',
    '',
    ' [~E~]   1 UP   ฟ                    ภฤฤฤฤฤฤฤฤฤู',
    ' [~F~]  12 UP   ๖ ALL',
    ' [~G~]   1 DOWN ๘ iNSTRUMENTS',
    ' [~H~]  12 DOWN ู');

  transp_menu_str2: array[1..8] of String[50] = (
    ' [~A~]   1 UP   ฟ',
    ' [~B~]  12 UP   ๖ CURRENT',
    ' [~C~]   1 DOWN ๘ iNSTRUMENT         ฺฤฤฤฤฤฤฤฤฤฟ',
    '',
    ' [~E~]   1 UP   ฟ                    ภฤฤฤฤฤฤฤฤฤู',
    ' [~F~]  12 UP   ๖ ALL',
    ' [~G~]   1 DOWN ๘ iNSTRUMENTS',
    ' [~H~]  12 DOWN ู');

  transp_menu_str3: array[1..8] of String[50] = (
    ' [A]   1 UP   ฟ',
    ' [B]  12 UP   ๖ CURRENT',
    ' [C]   1 DOWN ๘ iNSTRUMENT         ฺฤฤฤฤฤฤฤฤฤฟ',
    ' [D]  12 DOWN ู                    ณ  BLOCK  ณ',
    ' [E]   1 UP   ฟ                    ภฤฤฤฤฤฤฤฤฤู',
    ' [F]  12 UP   ๖ ALL',
    ' [G]   1 DOWN ๘ iNSTRUMENTS',
    ' [H]  12 DOWN ู');

  transp_menu_str4: array[1..4] of String[50] = (
    ' [~4~]  12 DOWN ู                    ณ PATTERN ณ',
    ' [~D~]  12 DOWN ู                    ณ  SONG   ณ',
    ' [~4~]  12 DOWN ู                    ณ  TRACK  ณ',
    ' [~D~]  12 DOWN ู                    ณ  BLOCK  ณ');

  transp_mnu_str5: array[1..19] of String[32] = (
    '~CURRENT~',
    '~iNSTRUMENT         ษอออออออออป~',
    'ALL',
    'iNSTRUMENTS',
    'CURRENT',
    'iNSTRUMENT         ~ษอออออออออป~',
    '~ALL~',
    '~iNSTRUMENTS~',
    'iNSTRUMENT         ฺฤฤฤฤฤฤฤฤฤฟ',
    '~บ PATTERN บ~',
    '~บ  TRACK  บ~',
    'ณ PATTERN ณ',
    'ณ  TRACK  ณ',
    '~บ  SONG   บ~',
    '~บ  BLOCK  บ~',
    'ณ  SONG   ณ',
    'ณ  BLOCK  ณ',
    '~ศอออออออออผ~',
    'ภฤฤฤฤฤฤฤฤฤู');

const
  macro_table_hint_str: array[1..20+35] of String[77] = (
    'Length of FM-register definition macro-table {1-FF} (0 means no macros)',
    'Loop cycle starting position {1-FF} (0 means no loop)',
    'Length of loop cycle {1-FF} (0 means no loop)',
    'Key-Off jump position {1-FF} (0 means no jump)',
    'Arpeggio table number {1-FF} (0 means no arpeggio)',
    'Vibrato table number {1-FF} (0 means no vibrato)',
    '',
    'Length of arpeggio macro-table {1-FF} (0 means no macros)',
    'Speed of arpeggio in macro-table {1-FF} (0 means no arpeggio)',
    'Loop cycle starting position {1-FF} (0 means no loop)',
    'Length of loop cycle {1-FF} (0 means no loop)',
    'Key-Off jump position {1-FF} (0 means no jump)',
    'Number of half-tones to add [1-96] or fixed-note [C,C-,C#,C1,C-1,C#1,...]',
    'Length of vibrato macro-table {1-FF} (0 means no macros)',
    'Speed of vibrato in macro-table {1-FF} (0 means no vibrato)',
    'Delay before starting vibrato in macro-table {1-FF} (0 means no delay)',
    'Loop cycle starting position {1-FF} (0 means no loop)',
    'Length of loop cycle {1-FF} (0 means no loop)',
    'Key-Off jump position {1-FF} (0 means no jump)',
    'Frequency to add {1..7F} or subtract {-7F..-1}',

    'Attack rate [modulator] {0-F}',
    'Decay rate [modulator] {0-F}',
    'Sustain level [modulator] {0-F}',
    'Release rate [modulator] {0-F}',
    'Waveform type [modulator] {0-7}',
    'Output level [modulator] {0-3F}',
    'Output level [modulator] {0-3F}',
    'Key scaling level [modulator] {0-3}',
    'Multiplier [modulator] {0-F}',
    'Amplitude modulation (tremolo) [modulator] {on/off}',
    'Vibrato [modulator] {on/off}',
    'Key scale rate [modulator] {on/off}',
    'Sustain [modulator] {on/off}',
    'Attack rate [carrier] {0-F}',
    'Decay rate [carrier] {0-F}',
    'Sustain level [carrier] {0-F}',
    'Release rate [carrier] {0-F}',
    'Waveform type [carrier] {0-7}',
    'Output level [carrier] {0-3F}',
    'Output level [carrier] {0-3F}',
    'Key scaling level [carrier] {0-3}',
    'Multiplier [carrier] {0-F}',
    'Amplitude modulation (tremolo) [carrier] {on/off}',
    'Vibrato [carrier] {on/off}',
    'Key scale rate [carrier] {on/off}',
    'Sustain [carrier] {on/off}',
    'Connection type {0-1} (0=FM,1=AM)',
    'Feedback {0-7}',
    'Frequency slide {-FFF..+FFF}',
    'Frequency slide {-FFF..+FFF}',
    'Frequency slide {-FFF..+FFF}',
    'Frequency slide {-FFF..+FFF}',
    'Panning {Left/Center/Right}',
    'Duration {1-FF} (0 means skip)',
    'Duration {1-FF} (0 means skip)');

  inst_mult_hint: array[0..15] of String[35] = (
    '1 octave below',
    'at the voice''s specified frequency',
    '1 octave above',
    '1 octave and a 5th above',
    '2 octaves above',
    '2 octaves and a Major 3rd above',
    '2 octaves and a 5th above',
    '2 octaves and a Minor 7th above',
    '3 octaves above',
    '3 octaves and a Major 2nd above',
    '3 octaves and a Major 3rd above',
    '3 octaves and a Major 3rd above',
    '3 octaves and a 5th above',
    '3 octaves and a 5th above',
    '3 octaves and a Major 7th above',
    '3 octaves and a Major 7th above');
