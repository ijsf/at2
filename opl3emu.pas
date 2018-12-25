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
//
//  ------------------------------------------------------------------
//  OPL3 EMULATOR
//  Based on NukedOPL3 1.6 by Nuke.YKT (Alexey Khokholov)
//  Special thanks to insane/Altair for initial C to Pascal conversion
//  ------------------------------------------------------------------

unit OPL3EMU;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

procedure OPL3EMU_init;
procedure OPL3EMU_WriteReg(reg: Word; data: Byte);
procedure OPL3EMU_PollProc(p_data: pDword; var ch_table);

implementation

const
  LOG_SIN_VAL: array[0..255] of Word = (
    $859,$6c3,$607,$58b,$52e,$4e4,$4a6,$471,$443,$41a,$3f5,$3d3,$3b5,$398,$37e,$365,
    $34e,$339,$324,$311,$2ff,$2ed,$2dc,$2cd,$2bd,$2af,$2a0,$293,$286,$279,$26d,$261,
    $256,$24b,$240,$236,$22c,$222,$218,$20f,$206,$1fd,$1f5,$1ec,$1e4,$1dc,$1d4,$1cd,
    $1c5,$1be,$1b7,$1b0,$1a9,$1a2,$19b,$195,$18f,$188,$182,$17c,$177,$171,$16b,$166,
    $160,$15b,$155,$150,$14b,$146,$141,$13c,$137,$133,$12e,$129,$125,$121,$11c,$118,
    $114,$10f,$10b,$107,$103,$0ff,$0fb,$0f8,$0f4,$0f0,$0ec,$0e9,$0e5,$0e2,$0de,$0db,
    $0d7,$0d4,$0d1,$0cd,$0ca,$0c7,$0c4,$0c1,$0be,$0bb,$0b8,$0b5,$0b2,$0af,$0ac,$0a9,
    $0a7,$0a4,$0a1,$09f,$09c,$099,$097,$094,$092,$08f,$08d,$08a,$088,$086,$083,$081,
    $07f,$07d,$07a,$078,$076,$074,$072,$070,$06e,$06c,$06a,$068,$066,$064,$062,$060,
    $05e,$05c,$05b,$059,$057,$055,$053,$052,$050,$04e,$04d,$04b,$04a,$048,$046,$045,
    $043,$042,$040,$03f,$03e,$03c,$03b,$039,$038,$037,$035,$034,$033,$031,$030,$02f,
    $02e,$02d,$02b,$02a,$029,$028,$027,$026,$025,$024,$023,$022,$021,$020,$01f,$01e,
    $01d,$01c,$01b,$01a,$019,$018,$017,$017,$016,$015,$014,$014,$013,$012,$011,$011,
    $010,$00f,$00f,$00e,$00d,$00d,$00c,$00c,$00b,$00a,$00a,$009,$009,$008,$008,$007,
    $007,$007,$006,$006,$005,$005,$005,$004,$004,$004,$003,$003,$003,$002,$002,$002,
    $002,$001,$001,$001,$001,$001,$001,$001,$000,$000,$000,$000,$000,$000,$000,$000);

  EXP_VAL: array[0..255] of Word = (
    $000,$003,$006,$008,$00b,$00e,$011,$014,$016,$019,$01c,$01f,$022,$025,$028,$02a,
    $02d,$030,$033,$036,$039,$03c,$03f,$042,$045,$048,$04b,$04e,$051,$054,$057,$05a,
    $05d,$060,$063,$066,$069,$06c,$06f,$072,$075,$078,$07b,$07e,$082,$085,$088,$08b,
    $08e,$091,$094,$098,$09b,$09e,$0a1,$0a4,$0a8,$0ab,$0ae,$0b1,$0b5,$0b8,$0bb,$0be,
    $0c2,$0c5,$0c8,$0cc,$0cf,$0d2,$0d6,$0d9,$0dc,$0e0,$0e3,$0e7,$0ea,$0ed,$0f1,$0f4,
    $0f8,$0fb,$0ff,$102,$106,$109,$10c,$110,$114,$117,$11b,$11e,$122,$125,$129,$12c,
    $130,$134,$137,$13b,$13e,$142,$146,$149,$14d,$151,$154,$158,$15c,$160,$163,$167,
    $16b,$16f,$172,$176,$17a,$17e,$181,$185,$189,$18d,$191,$195,$199,$19c,$1a0,$1a4,
    $1a8,$1ac,$1b0,$1b4,$1b8,$1bc,$1c0,$1c4,$1c8,$1cc,$1d0,$1d4,$1d8,$1dc,$1e0,$1e4,
    $1e8,$1ec,$1f0,$1f5,$1f9,$1fd,$201,$205,$209,$20e,$212,$216,$21a,$21e,$223,$227,
    $22b,$230,$234,$238,$23c,$241,$245,$249,$24e,$252,$257,$25b,$25f,$264,$268,$26d,
    $271,$276,$27a,$27f,$283,$288,$28c,$291,$295,$29a,$29e,$2a3,$2a8,$2ac,$2b1,$2b5,
    $2ba,$2bf,$2c4,$2c8,$2cd,$2d2,$2d6,$2db,$2e0,$2e5,$2e9,$2ee,$2f3,$2f8,$2fd,$302,
    $306,$30b,$310,$315,$31a,$31f,$324,$329,$32e,$333,$338,$33d,$342,$347,$34c,$351,
    $356,$35b,$360,$365,$36a,$370,$375,$37a,$37f,$384,$38a,$38f,$394,$399,$39f,$3a4,
    $3a9,$3ae,$3b4,$3b9,$3bf,$3c4,$3c9,$3cf,$3d4,$3da,$3df,$3e4,$3ea,$3ef,$3f5,$3fa);

  MULT_VAL: array[0..15] of Byte = (1,2,4,6,8,10,12,14,16,18,20,20,24,24,30,30);
  KSL_VAL: array[0..15] of Byte = (0,32,40,45,48,51,53,55,56,58,59,60,61,62,63,64);
  KSL_SHIFT: array[0..3] of Byte = (8,1,2,0);
  SL_VAL: array[0..15] of Byte = (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,31);
  VIB_SHIFT: array[0..7] of Byte = (3,1,0,1,3,1,0,1);
  VIB_S_SHIFT: array[0..7] of Shortint = (1,1,1,1,-1,-1,-1,-1);
  EG_IDX: array[0..15] of Byte =(0,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2);
  EG_SHIFT: array[0..15] of Shortint = (0,11,10,9,8,7,6,5,4,3,2,1,0,0,-1,-2);
  EG_VAL: array[0..2,0..3,0..7] of Byte = (((0,0,0,0,0,0,0,0),(0,0,0,0,0,0,0,0),(0,0,0,0,0,0,0,0),(0,0,0,0,0,0,0,0)),
                                           ((0,1,0,1,0,1,0,1),(0,1,0,1,1,1,0,1),(0,1,1,1,0,1,1,1),(0,1,1,1,1,1,1,1)),
                                           ((1,1,1,1,1,1,1,1),(2,2,1,1,1,1,1,1),(2,2,1,1,2,2,1,1),(2,2,2,2,2,2,1,1)));

  CH_5BIT_MASK: array[0..31] of Byte = (1,2,3,4,5,6,0,0,7,8,9,10,11,12,0,0,13,14,15,16,17,18,0,0,0,0,0,0,0,0,0,0);
  CH_SLOT_IDX: array[0..17] of Byte = (0,1,2,6,7,8,12,13,14,18,19,20,24,25,26,30,31,32);
  CH_4OP_MASK: array[0..17] of Byte = (4,5,6,1,2,3,0,0,0,13,14,15,10,11,12,0,0,0);
  CH_4OP_IDX: array[0..5] of Byte = (0,1,2,9,10,11);
  CH_MAPPING: array[0..17] of Byte = (
    3,0,       // 2OP | 4OP #1
    4,1,       // 2OP | 4OP #2
    5,2,       // 2OP | 4OP #3
    6,         // 2OP | RHYTHM: BD
    7,         // 2OP | RHYTHM: HH + SD
    8,         // 2OP | RHYTHM: TT + TC
    12,9,      // 2OP | 4OP #4
    13,10,     // 2OP | 4OP #5
    14,11,     // 2OP | 4OP #6
    15,        // 2OP
    16,        // 2OP
    17);       // 2OP

  NOISE_HASH_VAL = $306600;
  NOISE_XOR = $800302;
  WORD_NULL = WORD(NOT 0);

type
  OPL3_CHAN_TYPE = (CH_2OP,CH_4OP_1,CH_4OP_2,CH_RHYTHM);
  EG_GEN_STATE = (EG_OFF,EG_ATTACK,EG_DECAY,EG_SUSTAIN,EG_RELEASE);
  CHAN_PTR_TABLE = array[0..17] of pDword;

  P_OPL3_CHIP = ^OPL3_CHIP;
  P_OPL3_SLOT = ^OPL3_SLOT;
  P_OPL3_CHAN = ^OPL3_CHAN;

  OPL3_SLOT = Record
    p_chan: P_OPL3_CHAN;
    p_chip: P_OPL3_CHIP;
    p_mod: pSmallint;
    p_trem: pByte;
    fb_out,
    prev_out,
    output: Smallint;
    pg_phase: Dword;
    eg_state: EG_GEN_STATE;
    eg_rout,
    eg_out: Smallint;
    eg_inc,
    eg_rate,
    eg_ksl: Byte;
    reg_vib,
    reg_type,
    reg_ksr,
    reg_mult,
    reg_ksl,
    reg_tl,
    reg_ar,
    reg_dr,
    reg_sl,
    reg_rr,
    reg_wf,
    key: Byte;
  end;

  OPL3_CHAN = Record
    p_slot: array[0..1] of P_OPL3_SLOT;
    p_chan: P_OPL3_CHAN;
    p_chip: P_OPL3_CHIP;
    p_out: array[0..3] of ^Smallint;
    ch_type: OPL3_CHAN_TYPE;
    fnum: Word;
    block,
    fb,
    con,
    alg,
    ksr: Byte;
    out_l,
    out_r: Word;
  end;

  OPL3_CHIP = Record
    chan: array[0..17] of OPL3_CHAN;
    slot: array[0..35] of OPL3_SLOT;
    timer: Word;
    nts_bit,
    dva_bit,
    dvb_bit: 0..1;
    rhy_flag: Byte;
    trem_dir: 0..1;
    trem_pos,
    trem_val,
    vib_pos: Byte;
    noise: Dword;
    output: array[0..1] of Longint;
    out_l: array[0..17] of Smallint;
    out_r: array[0..17] of Smallint;
    out_null: Smallint;
  end;

var
  opl3: OPL3_CHIP;

function limit_value(value,lo_bound,hi_bound: Longint): Longint;
begin
  If (value > hi_bound) then
    value := hi_bound
  else If (value < lo_bound) then
         value := lo_bound;
  limit_value := value;
end;

function envelope_calc_sin(wf: Byte; phase: Word; eg_out: Smallint): Smallint;

var
  output,
  level,
  invert: Word;

begin
  phase := phase AND $3ff;
  output := 0;
  invert := 0;

  Case wf of
    // Sine
    0: begin
         If (phase AND $200 <> 0) then
           invert := NOT invert;
         If (phase AND $100 <> 0) then
           output := LOG_SIN_VAL[(phase AND $0ff) XOR $0ff]
         else output := LOG_SIN_VAL[phase and $0ff];
       end;

    // Half-Sine
    1: begin
         If (phase AND $200 <> 0) then
           output := $1000
         else If (phase AND $100 <> 0) then
                output := LOG_SIN_VAL[(phase AND $0ff) xor $0ff]
              else output := LOG_SIN_VAL[phase AND $0ff];
       end;

    // Abs-Sine
    2: begin
         If (phase AND $100 <> 0) then
           output := LOG_SIN_VAL[(phase AND $0ff) XOR $0ff]
         else output := LOG_SIN_VAL[phase AND $0ff];
       end;

    // Pulse-Sine
    3: begin
         If (phase AND $100 <> 0) then
           output := $1000
         else output := LOG_SIN_VAL[phase AND $0ff];
       end;

    // Sine (EPO)
    4: begin
         If (phase AND $300 = $100) then
           invert := NOT invert;
         If (phase AND $200 <> 0) then
           output := $1000
         else If (phase AND $80 <> 0) then
                output := LOG_SIN_VAL[((phase XOR $0ff) SHL 1) AND $0ff]
              else output := LOG_SIN_VAL[(phase SHL 1) AND $0ff];
       end;

    // Abs-Sine (EPO)
    5: begin
         If (phase AND $200 <> 0) then
           output := $1000
         else If (phase AND $80 <> 0) then
                output := LOG_SIN_VAL[((phase XOR $0ff) SHL 1) AND $0ff]
              else output := LOG_SIN_VAL[(phase SHL 1) AND $0ff];
       end;

    // Square
    6: begin
         If (phase AND $200 <> 0) then
           invert := WORD_NULL;
         output := 0;
       end;

    // Derived Square
    7: begin
         If (phase AND $200 <> 0) then
           begin
             invert := NOT invert;
             phase := (phase AND $1ff) XOR $1ff;
           end;
         output := phase SHL 3;
       end;
  end;

  level := limit_value(output + (eg_out SHL 3),0,$1fff);
  envelope_calc_sin := SMALLINT(((EXP_VAL[(level AND $0ff) XOR $0ff] OR $400) SHL 1) SHR
                                (level SHR 8)) XOR invert;
end;

function envelope_calc_rate(p_slot: P_OPL3_SLOT; reg_rate: Byte): Byte;

var
  rate: Byte;

begin
  If (reg_rate = 0) then
    begin
      envelope_calc_rate := 0;
      EXIT;
    end;

  rate := (reg_rate SHL 2);
  If (p_slot^.reg_ksr <> 0) then
    Inc(rate,p_slot^.p_chan^.ksr)
  else
    Inc(rate,(p_slot^.p_chan^.ksr SHR 2));
  envelope_calc_rate := limit_value(rate,0,60);
end;

procedure envelope_update_ksl(p_slot: P_OPL3_SLOT);

var
  ksl: Smallint;

begin
  ksl := (KSL_VAL[p_slot^.p_chan^.fnum SHR 6] SHL 2) -
         (8 - p_slot^.p_chan^.block) SHL 5;
  p_slot^.eg_ksl := limit_value(ksl,0,255);
end;

procedure envelope_update_rate(p_slot: P_OPL3_SLOT);
begin
  Case p_slot^.eg_state of
    EG_OFF:     p_slot^.eg_rate := 0;
    EG_ATTACK:  p_slot^.eg_rate := envelope_calc_rate(p_slot,p_slot^.reg_ar);
    EG_DECAY:   p_slot^.eg_rate := envelope_calc_rate(p_slot,p_slot^.reg_dr);
    EG_SUSTAIN,
    EG_RELEASE: p_slot^.eg_rate := envelope_calc_rate(p_slot,p_slot^.reg_rr);
  end;
end;

procedure envelope_calc(p_slot: P_OPL3_SLOT);

var
  rate_hi,
  rate_lo: Byte;

begin
  rate_hi := p_slot^.eg_rate SHR 2;
  rate_lo := p_slot^.eg_rate AND 3;

  // calculate increment step for output
  If (EG_SHIFT[rate_hi] > 0) then
    begin
       If ((p_slot^.p_chip^.timer AND ((1 SHL EG_SHIFT[rate_hi]) - 1)) = 0) then
         p_slot^.eg_inc := EG_VAL[EG_IDX[rate_hi],rate_lo,
                                  ((p_slot^.p_chip^.timer) SHR EG_SHIFT[rate_hi]) AND 7]
       else
         p_slot^.eg_inc := 0;
    end
  else
    p_slot^.eg_inc := EG_VAL[EG_IDX[rate_hi],rate_lo,
                             p_slot^.p_chip^.timer AND 7] SHL Abs(EG_SHIFT[rate_hi]);

  p_slot^.eg_out := p_slot^.eg_rout +
                    p_slot^.reg_tl SHL 2 +
                    p_slot^.eg_ksl SHR KSL_SHIFT[p_slot^.reg_ksl] +
                    p_slot^.p_trem^; // apply LFO tremolo

  Case p_slot^.eg_state of
    EG_OFF:
      p_slot^.eg_rout := $1ff;

    EG_ATTACK:
      If (p_slot^.eg_rout <> 0) then
        begin
          Inc(p_slot^.eg_rout,((NOT p_slot^.eg_rout) * p_slot^.eg_inc) SHR 3);
          limit_value(p_slot^.eg_rout,0,$1ff);
        end
      else
        begin
          // continue with decay if max. level is reached
          p_slot^.eg_state := EG_DECAY;
          envelope_update_rate(p_slot);
        end;

    EG_DECAY:
      If (p_slot^.eg_rout < SMALLINT(p_slot^.reg_sl) SHL 4) then
        Inc(p_slot^.eg_rout,p_slot^.eg_inc)
      else
        begin
          // sustain level was reached
          p_slot^.eg_state := EG_SUSTAIN;
          envelope_update_rate(p_slot);
        end;

    EG_SUSTAIN,
    EG_RELEASE:
      If (p_slot^.eg_state = EG_SUSTAIN) and
         (p_slot^.reg_type <> 0) then
        // sustain phase
      else
        If (p_slot^.eg_rout < $1ff) then
          Inc(p_slot^.eg_rout,p_slot^.eg_inc)
        else
          begin
            // switch off generator if min. level is reached
            p_slot^.eg_state := EG_OFF;
            p_slot^.eg_rout := $1ff;
            envelope_update_rate(p_slot);
          end;
  end;
end;

procedure eg_key_on_off(p_slot: P_OPL3_SLOT; key_on: Boolean);
begin
  If key_on then
    begin
      If (p_slot^.key = 0) then
        begin
          p_slot^.eg_state := EG_ATTACK;
          envelope_update_rate(p_slot);
          If (p_slot^.eg_rate SHR 2 = $0f) then
            begin
              p_slot^.eg_state := EG_DECAY;
              envelope_update_rate(p_slot);
              p_slot^.eg_rout := 0;
            end;
          p_slot^.pg_phase := 0;
        end;

      If (p_slot^.p_chan^.ch_type <> CH_RHYTHM) then
        p_slot^.key := p_slot^.key OR 1
      else
        p_slot^.key := p_slot^.key OR 2;

      If (p_slot^.reg_ar = 0) then
        begin
          // faked decay prevents restart of envelope if AR=0
          p_slot^.eg_state := EG_DECAY;
          Inc(p_slot^.eg_rout);
        end;
    end
  else
    // key off
    If (p_slot^.key <> 0) then
      begin
        If (p_slot^.p_chan^.ch_type <> CH_RHYTHM) then
          p_slot^.key := p_slot^.key AND $0fe
        else
          p_slot^.key := p_slot^.key AND $0fd;

        If (p_slot^.key = 0) then
          begin
            p_slot^.eg_state := EG_RELEASE;
            envelope_update_rate(p_slot);
          end;
      end;
end;

procedure pg_generate(p_slot: P_OPL3_SLOT);

var
  fnum: Word;
  fnum_hi: Byte;

begin
  fnum := p_slot^.p_chan^.fnum;
  If (p_slot^.reg_vib <> 0) then
    begin
      // apply LFO vibrato
      fnum_hi := fnum SHR (7 + VIB_SHIFT[(p_slot^.p_chip^.timer SHR 10) AND 7] +
                               (1 - p_slot^.p_chip^.dvb_bit));
      Inc(fnum,fnum_hi * VIB_S_SHIFT[(p_slot^.p_chip^.timer SHR 10) AND 7]);
    end;

  Inc(p_slot^.pg_phase,(((fnum SHL p_slot^.p_chan^.block) SHR 1) *
                        MULT_VAL[p_slot^.reg_mult]) SHR 1);
end;

procedure update_lfo_eg_ksr_mult(p_slot: P_OPL3_SLOT; data: Byte);
begin
  // assign LFO tremolo
  If ((data SHR 7) AND 1 <> 0) then
    p_slot^.p_trem := @p_slot^.p_chip^.trem_val
  else p_slot^.p_trem := @p_slot^.p_chip^.out_null;

  p_slot^.reg_vib := (data SHR 6) AND 1;
  p_slot^.reg_type := (data SHR 5) AND 1;
  p_slot^.reg_ksr := (data SHR 4) AND 1;
  p_slot^.reg_mult := data AND $0f;
  envelope_update_rate(p_slot);
end;

procedure update_ksl_tl(p_slot: P_OPL3_SLOT; data: Byte);
begin
  p_slot^.reg_ksl := (data SHR 6) AND 3;
  p_slot^.reg_tl := data AND $3f;
  envelope_update_ksl(p_slot);
end;

procedure update_ar_dr(p_slot: P_OPL3_SLOT; data: Byte);
begin
  p_slot^.reg_ar := (data SHR 4) AND $0f;
  p_slot^.reg_dr := data AND $0f;
  envelope_update_rate(p_slot);
end;

procedure update_sl_rr(p_slot: P_OPL3_SLOT; data: Byte);
begin
  p_slot^.reg_sl := SL_VAL[(data SHR 4) AND $0f];
  p_slot^.reg_rr := data AND $0f;
  envelope_update_rate(p_slot);
end;

procedure slot_generate(p_slot: P_OPL3_SLOT; phase: Word);
begin
  If (phase = WORD_NULL) then
    phase := WORD(p_slot^.pg_phase SHR 9) + p_slot^.p_mod^;
  p_slot^.output := envelope_calc_sin(p_slot^.reg_wf,phase,p_slot^.eg_out);
end;

procedure slot_calc_fb(p_slot: P_OPL3_SLOT);
begin
  If (p_slot^.p_chan^.fb <> 0) then
    p_slot^.fb_out := (p_slot^.prev_out + p_slot^.output) SHR
                      (9 - p_slot^.p_chan^.fb)
  else
    p_slot^.fb_out := 0;
  p_slot^.prev_out := p_slot^.output;
end;

procedure chan_set_alg(p_chan: P_OPL3_CHAN);
begin
  Case p_chan^.ch_type of
    CH_2OP:
      Case (p_chan^.alg AND 1) of
        0: begin
             // FM
             p_chan^.p_slot[0]^.p_mod := @p_chan^.p_slot[0]^.fb_out;
             p_chan^.p_slot[1]^.p_mod := @p_chan^.p_slot[0]^.output;
             p_chan^.p_out[0] := @p_chan^.p_slot[1]^.output;
             p_chan^.p_out[1] := @p_chan^.p_chip^.out_null;
             p_chan^.p_out[2] := @p_chan^.p_chip^.out_null;
             p_chan^.p_out[3] := @p_chan^.p_chip^.out_null;
           end;

        1: begin
             // AM
             p_chan^.p_slot[0]^.p_mod := @p_chan^.p_slot[0]^.fb_out;
             p_chan^.p_slot[1]^.p_mod := @p_chan^.p_chip^.out_null;
             p_chan^.p_out[0] := @p_chan^.p_slot[0]^.output;
             p_chan^.p_out[1] := @p_chan^.p_slot[1]^.output;
             p_chan^.p_out[2] := @p_chan^.p_chip^.out_null;
             p_chan^.p_out[3] := @p_chan^.p_chip^.out_null;
           end;
      end;

    CH_4OP_2:
      begin
        p_chan^.p_chan^.p_out[0] := @p_chan^.p_chip^.out_null;
        p_chan^.p_chan^.p_out[1] := @p_chan^.p_chip^.out_null;
        p_chan^.p_chan^.p_out[2] := @p_chan^.p_chip^.out_null;
        p_chan^.p_chan^.p_out[3] := @p_chan^.p_chip^.out_null;

        Case (p_chan^.alg AND 3) of
          0: begin
               // FM-FM
               p_chan^.p_chan^.p_slot[0]^.p_mod := @p_chan^.p_chan^.p_slot[0]^.fb_out;
               p_chan^.p_chan^.p_slot[1]^.p_mod := @p_chan^.p_chan^.p_slot[0]^.output;
               p_chan^.p_slot[0]^.p_mod := @p_chan^.p_chan^.p_slot[1]^.output;
               p_chan^.p_slot[1]^.p_mod := @p_chan^.p_slot[0]^.output;
               p_chan^.p_out[0] := @p_chan^.p_slot[1]^.output;
               p_chan^.p_out[1] := @p_chan^.p_chip^.out_null;
               p_chan^.p_out[2] := @p_chan^.p_chip^.out_null;
               p_chan^.p_out[3] := @p_chan^.p_chip^.out_null;
             end;

          1: begin
               // FM-AM
               p_chan^.p_chan^.p_slot[0]^.p_mod := @p_chan^.p_chan^.p_slot[0]^.fb_out;
               p_chan^.p_chan^.p_slot[1]^.p_mod := @p_chan^.p_chan^.p_slot[0]^.output;
               p_chan^.p_slot[0]^.p_mod := @p_chan^.p_chip^.out_null;
               p_chan^.p_slot[1]^.p_mod := @p_chan^.p_slot[0]^.output;
               p_chan^.p_out[0] := @p_chan^.p_chan^.p_slot[1]^.output;
               p_chan^.p_out[1] := @p_chan^.p_slot[1]^.output;
               p_chan^.p_out[2] := @p_chan^.p_chip^.out_null;
               p_chan^.p_out[3] := @p_chan^.p_chip^.out_null;
             end;

          2: begin
               // AM-AM
               p_chan^.p_chan^.p_slot[0]^.p_mod := @p_chan^.p_chan^.p_slot[0]^.fb_out;
               p_chan^.p_chan^.p_slot[1]^.p_mod := @p_chan^.p_chip^.out_null;
               p_chan^.p_slot[0]^.p_mod := @p_chan^.p_chan^.p_slot[1]^.output;
               p_chan^.p_slot[1]^.p_mod := @p_chan^.p_slot[0]^.output;
               p_chan^.p_out[0] := @p_chan^.p_chan^.p_slot[0]^.output;
               p_chan^.p_out[1] := @p_chan^.p_slot[1]^.output;
               p_chan^.p_out[2] := @p_chan^.p_chip^.out_null;
               p_chan^.p_out[3] := @p_chan^.p_chip^.out_null;
             end;

          3: begin
               // AM-FM
               p_chan^.p_chan^.p_slot[0]^.p_mod := @p_chan^.p_chan^.p_slot[0]^.fb_out;
               p_chan^.p_chan^.p_slot[1]^.p_mod := @p_chan^.p_chip^.out_null;
               p_chan^.p_slot[0]^.p_mod := @p_chan^.p_chan^.p_slot[1]^.output;
               p_chan^.p_slot[1]^.p_mod := @p_chan^.p_chip^.out_null;
               p_chan^.p_out[0] := @p_chan^.p_chan^.p_slot[0]^.output;
               p_chan^.p_out[1] := @p_chan^.p_slot[0]^.output;
               p_chan^.p_out[2] := @p_chan^.p_slot[1]^.output;
               p_chan^.p_out[3] := @p_chan^.p_chip^.out_null;
             end;
        end;
      end;

    CH_RHYTHM:
      Case (p_chan^.alg AND 1) of
        0: begin
             // FM
             p_chan^.p_slot[0]^.p_mod := @p_chan^.p_slot[0]^.fb_out;
             p_chan^.p_slot[1]^.p_mod := @p_chan^.p_slot[0]^.output;
           end;

        1: begin
             // AM
             p_chan^.p_slot[0]^.p_mod := @p_chan^.p_slot[0]^.fb_out;
             p_chan^.p_slot[1]^.p_mod := @p_chan^.p_chip^.out_null;
           end;
      end;
  end;
end;

procedure chan_update_rhythm(p_chip: P_OPL3_CHIP; data: Byte);
begin
  p_chip^.rhy_flag := data AND $3f;
  If (p_chip^.rhy_flag AND $20 <> 0) then
    begin
      // BD
      p_chip^.chan[6].ch_type := CH_RHYTHM;
      p_chip^.chan[6].p_out[0] := @p_chip^.chan[6].p_slot[1]^.output;
      p_chip^.chan[6].p_out[1] := @p_chip^.chan[6].p_slot[1]^.output;
      p_chip^.chan[6].p_out[2] := @p_chip^.out_null;
      p_chip^.chan[6].p_out[3] := @p_chip^.out_null;

      chan_set_alg(@p_chip^.chan[6]);
      eg_key_on_off(p_chip^.chan[6].p_slot[0],p_chip^.rhy_flag AND $10 <> 0);
      eg_key_on_off(p_chip^.chan[6].p_slot[1],p_chip^.rhy_flag AND $10 <> 0);

      // HH + SD
      p_chip^.chan[7].ch_type := CH_RHYTHM;
      p_chip^.chan[7].p_out[0] := @p_chip^.chan[7].p_slot[0]^.output;
      p_chip^.chan[7].p_out[1] := @p_chip^.chan[7].p_slot[0]^.output;
      p_chip^.chan[7].p_out[2] := @p_chip^.chan[7].p_slot[1]^.output;
      p_chip^.chan[7].p_out[3] := @p_chip^.chan[7].p_slot[1]^.output;

      eg_key_on_off(p_chip^.chan[7].p_slot[0],p_chip^.rhy_flag AND 1 <> 0);
      eg_key_on_off(p_chip^.chan[7].p_slot[1],p_chip^.rhy_flag AND 8 <> 0);

      // TT + TC
      p_chip^.chan[8].ch_type := CH_RHYTHM;
      p_chip^.chan[8].p_out[0] := @p_chip^.chan[8].p_slot[0]^.output;
      p_chip^.chan[8].p_out[1] := @p_chip^.chan[8].p_slot[0]^.output;
      p_chip^.chan[8].p_out[2] := @p_chip^.chan[8].p_slot[1]^.output;
      p_chip^.chan[8].p_out[3] := @p_chip^.chan[8].p_slot[1]^.output;

      eg_key_on_off(p_chip^.chan[8].p_slot[0],p_chip^.rhy_flag AND 4 <> 0);
      eg_key_on_off(p_chip^.chan[8].p_slot[1],p_chip^.rhy_flag AND 2 <> 0);
    end
  else
    begin
      // reset chan. 6/7/8 to 2OP
      p_chip^.chan[6].ch_type := CH_2OP;
      chan_set_alg(@p_chip^.chan[6]);
      p_chip^.chan[7].ch_type := CH_2OP;
      chan_set_alg(@p_chip^.chan[7]);
      p_chip^.chan[8].ch_type := CH_2OP;
      chan_set_alg(@p_chip^.chan[8]);
    end;
end;

procedure update_fnum_block_ksr(p_chan: P_OPL3_CHAN; data: Byte; msb_flag: Boolean);
begin
  If (p_chan^.ch_type = CH_4OP_2) then
    EXIT;

  If msb_flag then
    begin
      // update upper bits
      p_chan^.fnum := (p_chan^.fnum AND $300) OR data;
      p_chan^.ksr := (p_chan^.block SHL 1) OR
                     ((p_chan^.fnum SHR (9 - p_chan^.p_chip^.nts_bit)) AND 1);
    end
  else
    begin
      // update lower bits
      p_chan^.fnum := (p_chan^.fnum AND $0ff) OR
                      ((data AND 3) SHL 8);
      p_chan^.block := (data shr 2) AND 7;
      p_chan^.ksr := (p_chan^.block SHL 1) OR
                     ((p_chan^.fnum SHR (9 - p_chan^.p_chip^.nts_bit)) AND 1);
    end;

  envelope_update_ksl(p_chan^.p_slot[0]);
  envelope_update_ksl(p_chan^.p_slot[1]);
  envelope_update_rate(p_chan^.p_slot[0]);
  envelope_update_rate(p_chan^.p_slot[1]);

  If (p_chan^.ch_type = CH_4OP_1) then
    begin
      p_chan^.p_chan^.fnum := p_chan^.fnum;
      p_chan^.p_chan^.ksr := p_chan^.ksr;

      If msb_flag then
        p_chan^.p_chan^.block := p_chan^.block;

      envelope_update_ksl(p_chan^.p_chan^.p_slot[0]);
      envelope_update_ksl(p_chan^.p_chan^.p_slot[1]);
      envelope_update_rate(p_chan^.p_chan^.p_slot[0]);
      envelope_update_rate(p_chan^.p_chan^.p_slot[1]);
    end;
end;

procedure update_fb_con(p_chan: P_OPL3_CHAN; data: Byte);
begin
  p_chan^.fb := (data AND $0e) SHR 1;
  p_chan^.con := data AND 1;
  p_chan^.alg := p_chan^.con;

  Case p_chan^.ch_type of
    CH_2OP,
    CH_RHYTHM:
      chan_set_alg(p_chan);

    CH_4OP_1:
      begin
        p_chan^.p_chan^.alg := 4 OR
                               (p_chan^.con SHL 1) OR
                               (p_chan^.p_chan^.con);
        chan_set_alg(p_chan^.p_chan);
      end;

    CH_4OP_2:
      begin
        p_chan^.alg := 4 OR
                       (p_chan^.p_chan^.con SHL 1) OR
                       (p_chan^.con);
        chan_set_alg(p_chan);
      end;
  end;

  // trigger output to left
  If ((data SHR 4) AND 1 <> 0) then
    p_chan^.out_l := WORD_NULL
  else p_chan^.out_l := 0;

  // trigger output to right
  If ((data SHR 5) AND 1 <> 0) then
    p_chan^.out_r := WORD_NULL
  else p_chan^.out_r := 0;
end;

procedure generate_rhythm_slots(p_chip: P_OPL3_CHIP);

var
  p_slot: P_OPL3_SLOT;
  phase,phase_lo,phase_hi,phase_bit: Word;

procedure calc_phase_slot7_slot8;
begin
  phase_lo := (p_chip^.chan[7].p_slot[0]^.pg_phase SHR 9) AND $3ff;
  phase_hi := (p_chip^.chan[8].p_slot[1]^.pg_phase SHR 9) AND $3ff;

  If ((phase_lo AND 8) OR
      (((phase_lo SHR 5) XOR phase_lo) AND 4) OR
      (((phase_hi SHR 2) XOR phase_hi) AND 8) <> 0) then
    phase_bit := 1
  else
    phase_bit := 0;
end;

begin
  // BD
  p_slot := p_chip^.chan[6].p_slot[0];
  slot_generate(p_slot,WORD(p_slot^.pg_phase SHR 9) + (p_slot^.p_mod^));
  p_slot := p_chip^.chan[6].p_slot[1];
  slot_generate(p_slot,WORD(p_slot^.pg_phase SHR 9) + (p_slot^.p_mod^));

  // HH
  p_slot := p_chip^.chan[7].p_slot[0];
  calc_phase_slot7_slot8;
  phase := (phase_bit SHL 9) OR
           WORD($34 SHL ((phase_bit XOR (p_chip^.noise AND 1) SHL 1)));
  slot_generate(p_slot,phase);

  // TT
  p_slot := p_chip^.chan[8].p_slot[0];
  slot_generate(p_slot,WORD(p_slot^.pg_phase SHR 9));

  // SD
  p_slot := p_chip^.chan[7].p_slot[1];
  calc_phase_slot7_slot8;
  phase := ($100 SHL ((phase_lo SHR 8) AND 1)) XOR
           WORD((p_chip^.noise AND 1) SHL 8);
  slot_generate(p_slot,phase);

  // TC
  p_slot := p_chip^.chan[8].p_slot[1];
  phase := $100 OR (phase_bit SHL 9);
  slot_generate(p_slot,phase);
end;

procedure update_key(p_chan: P_OPL3_CHAN; key_on: Boolean);
begin
  Case p_chan^.ch_type of
    CH_2OP,
    CH_4OP_1,
    CH_RHYTHM:
      begin
        eg_key_on_off(p_chan^.p_slot[0],key_on);
        eg_key_on_off(p_chan^.p_slot[1],key_on);

        If (p_chan^.ch_type = CH_4OP_1) then
          begin
            eg_key_on_off(p_chan^.p_chan^.p_slot[0],key_on);
            eg_key_on_off(p_chan^.p_chan^.p_slot[1],key_on);
          end;
      end;
  end;
end;

procedure chan_update_4op(p_chip: P_OPL3_CHIP; data: Byte);

var
  bit_num: Byte;

begin
  For bit_num := 0 to 5 do
    If ((data SHR bit_num) AND 1 <> 0) then
      begin
        // set chan. to 4OP
        p_chip^.chan[CH_4OP_IDX[bit_num]].ch_type := CH_4OP_1;
        p_chip^.chan[CH_4OP_IDX[bit_num]+3].ch_type := CH_4OP_2;
      end
    else
      begin
        // reset chan. to 2OP
        p_chip^.chan[CH_4OP_IDX[bit_num]].ch_type := CH_2OP;
        p_chip^.chan[CH_4OP_IDX[bit_num]+3].ch_type := CH_2OP;
      end;
end;

function chip_generate(p_chip: P_OPL3_CHIP): Dword;

var
  slot_num: Byte;
  accm: Smallint;
  lr_mix: array[0..1] of Smallint;

begin
  // generate slot data
  For slot_num := 0 to 35 do
    begin
      slot_calc_fb(@p_chip^.slot[slot_num]);
      pg_generate(@p_chip^.slot[slot_num]);
      envelope_calc(@p_chip^.slot[slot_num]);
      slot_generate(@p_chip^.slot[slot_num],WORD_NULL);
    end;

  // rhythm mode
  If (p_chip^.rhy_flag AND $20 <> 0) then
    generate_rhythm_slots(p_chip);

  // update channel mixer
  lr_mix[1] := limit_value(p_chip^.output[1],-$7fff,$7fff);
  lr_mix[0] := limit_value(p_chip^.output[0],-$7fff,$7fff);
  p_chip^.output[0] := 0;
  p_chip^.output[1] := 0;

  // left output
  For slot_num := 0 to 17 do
    begin
      accm := p_chip^.chan[slot_num].p_out[0]^ +
              p_chip^.chan[slot_num].p_out[1]^ +
              p_chip^.chan[slot_num].p_out[2]^ +
              p_chip^.chan[slot_num].p_out[3]^;
      Inc(p_chip^.output[0],SMALLINT(accm AND p_chip^.chan[slot_num].out_l));
      p_chip^.out_l[slot_num] := SMALLINT(accm AND p_chip^.chan[slot_num].out_l);
    end;

  // right output
  For slot_num := 0 to 17 do
    begin
      accm := p_chip^.chan[slot_num].p_out[0]^ +
              p_chip^.chan[slot_num].p_out[1]^ +
              p_chip^.chan[slot_num].p_out[2]^ +
              p_chip^.chan[slot_num].p_out[3]^;
      Inc(p_chip^.output[1],SMALLINT(accm AND p_chip^.chan[slot_num].out_r));
      p_chip^.out_r[slot_num] := SMALLINT(accm AND p_chip^.chan[slot_num].out_r);
    end;

  // update LFO tremolo
  If (p_chip^.timer AND $3f = $3f) then
    begin
      If (p_chip^.trem_dir = 0) then
        begin
          If (p_chip^.trem_pos < 105) then
            Inc(p_chip^.trem_pos)
          else
            begin
              Dec(p_chip^.trem_pos);
              p_chip^.trem_dir := 1;
            end
        end
      else
        begin
          If (p_chip^.trem_pos > 0) then
            Dec(p_chip^.trem_pos)
          else
            begin
              Inc(p_chip^.trem_pos);
              p_chip^.trem_dir := 0;
            end;
        end;

      p_chip^.trem_val := (p_chip^.trem_pos SHR 2) SHR
                          ((1 - p_chip^.dva_bit) SHL 1);
    end;

  // update noise generator
  If (p_chip^.noise AND 1 <> 0) then
    p_chip^.noise := p_chip^.noise XOR NOISE_XOR;

  p_chip^.noise := p_chip^.noise SHR 1;
  Inc(p_chip^.timer);

  chip_generate := (WORD(lr_mix[1]) SHL 16) OR WORD(lr_mix[0]);
end;

procedure OPL3EMU_init;

var
  slot_num,
  chan_num: Byte;

begin
  // initialize slot data
  For slot_num := 0 to 35 do
    begin
      opl3.slot[slot_num].p_chip := @opl3;
      opl3.slot[slot_num].p_mod := @opl3.out_null;
      opl3.slot[slot_num].eg_rout := $1ff;
      opl3.slot[slot_num].eg_out := $1ff;
      opl3.slot[slot_num].eg_state := EG_OFF;
      opl3.slot[slot_num].p_trem := @opl3.out_null;
    end;

  // initialize chan. data
  For chan_num := 0 to 17 do
    begin
      opl3.out_l[chan_num] := 0;
      opl3.out_r[chan_num] := 0;
      opl3.chan[chan_num].out_l := WORD_NULL;
      opl3.chan[chan_num].out_r := WORD_NULL;
      opl3.chan[chan_num].p_chip := @opl3;
      opl3.chan[chan_num].ch_type := CH_2OP;
      opl3.chan[chan_num].p_out[0] := @opl3.out_null;
      opl3.chan[chan_num].p_out[1] := @opl3.out_null;
      opl3.chan[chan_num].p_out[2] := @opl3.out_null;
      opl3.chan[chan_num].p_out[3] := @opl3.out_null;
      opl3.chan[chan_num].p_slot[0] := @opl3.slot[CH_SLOT_IDX[chan_num]];
      opl3.chan[chan_num].p_slot[1] := @opl3.slot[CH_SLOT_IDX[chan_num]+3];
      opl3.slot[CH_SLOT_IDX[chan_num]].p_chan := @opl3.chan[chan_num];
      opl3.slot[CH_SLOT_IDX[chan_num]+3].p_chan := @opl3.chan[chan_num];

      If (CH_4OP_MASK[chan_num] <> 0) then
        opl3.chan[chan_num].p_chan := @opl3.chan[PRED(CH_4OP_MASK[chan_num])];

      chan_set_alg(@opl3.chan[chan_num]);
  end;

  // initialize chip data
  opl3.noise := NOISE_HASH_VAL;
  opl3.timer := 0;
  opl3.nts_bit := 0;
  opl3.dva_bit := 0;
  opl3.dvb_bit := 0;
  opl3.rhy_flag := 0;
  opl3.vib_pos := 0;
  opl3.trem_dir := 0;
  opl3.trem_pos := 0;
  opl3.trem_val := 0;
  opl3.output[0] := 0;
  opl3.output[1] := 0;
end;

procedure OPL3EMU_WriteReg(reg: Word; data: Byte);

var
  reg_hi,
  reg_lo: Byte;

begin
  reg := reg AND $1ff;
  reg_hi := (reg SHR 8) AND 1;
  reg_lo := reg AND $0ff;

  Case reg_lo of
    // misc. registers
    $01..$08:
      If (reg_hi <> 0) then
        begin
          If (reg_lo AND $0f = 4) then
            // 4OP con. sel.
            chan_update_4op(@opl3,data);
        end
      else If (reg_lo AND $0f = 8) then
             // bit 'NTS'
             // 0 -> LSB for key is bit 10 of Fnum
             // 1 -> LSB for key is bit 9 of Fnum
             opl3.nts_bit := (data SHR 6) AND 1;

    // AM/VIB/EGT/KSR/MULT
    $20..$35:
      If (CH_5BIT_MASK[reg_lo AND $1f] <> 0) then
        update_lfo_eg_ksr_mult(@opl3.slot[18 * reg_hi + PRED(CH_5BIT_MASK[reg_lo AND $1f])],
                               data);

    // KSL/TL
    $40..$55:
      If (CH_5BIT_MASK[reg_lo AND $1f] <> 0) then
        update_ksl_tl(@opl3.slot[18 * reg_hi + PRED(CH_5BIT_MASK[reg_lo AND $1f])],
                      data);

    // AR/DR
    $60..$75:
      If (CH_5BIT_MASK[reg_lo AND $1f] <> 0) then
        update_ar_dr(@opl3.slot[18 * reg_hi + PRED(CH_5BIT_MASK[reg_lo AND $1f])],
                     data);

    // SL/RR
    $80..$95:
      If (CH_5BIT_MASK[reg_lo AND $1f] <> 0) then
        update_sl_rr(@opl3.slot[18 * reg_hi + PRED(CH_5BIT_MASK[reg_lo AND $1f])],
                     data);

    // Fnum/block/KSR
    $0a0..$a8:
      update_fnum_block_ksr(@opl3.chan[9 * reg_hi + (reg_lo AND $0f)],
                            data,TRUE); // MSB part

    // Fnum/block/KSR
    $0b0..$0b8:
      begin
        // Fnum/block/KSR
        update_fnum_block_ksr(@opl3.chan[9 * reg_hi + (reg_lo AND $0f)],
                              data,FALSE); // LSB part
        // key on/off
        update_key(@opl3.chan[9 * reg_hi + (reg_lo AND $0f)],data AND $20 <> 0);
      end;

    // LFO/rhythm
    $0bd:
      If (reg_hi = 0) then
        begin
          // bit 'DAM' (LFO tremolo)
          opl3.dva_bit := data SHR 7;
          // bit 'DVB' (LFO vibrato)
          opl3.dvb_bit := (data SHR 6) AND 1;
          // rhythm mode flag
          chan_update_rhythm(@opl3,data);
        end;

    // slot/feedback/con.
    $0c0..$0c8:
      update_fb_con(@opl3.chan[9 * reg_hi + (reg_lo AND $0f)],
                    data);

    // waveform sel.
    $0e0..$0f5:
      If (CH_5BIT_MASK[reg_lo AND $1f] <> 0) then
        opl3.slot[18 * reg_hi + PRED(CH_5BIT_MASK[reg_lo AND $1f])].reg_wf := data AND 7;
  end;
end;

procedure OPL3EMU_PollProc(p_data: pDword; var ch_table);

var
  chan_num: Byte;
  temp: Dword;

begin
  // assign main output
  p_data^ := chip_generate(@opl3);

  // assign per-channel output
  For chan_num := 0 to 17 do
    CHAN_PTR_TABLE(ch_table)[chan_num]^:=
      (WORD(opl3.out_r[CH_MAPPING[chan_num]]) SHL 16) OR
       WORD(opl3.out_l[CH_MAPPING[chan_num]]);

  // sort rhythm channels as last
  If (opl3.rhy_flag AND $20 <> 0) then
    begin
      temp := CHAN_PTR_TABLE(ch_table)[15]^;
      CHAN_PTR_TABLE(ch_table)[15]^ := CHAN_PTR_TABLE(ch_table)[6]^;
      CHAN_PTR_TABLE(ch_table)[6]^ := temp;
      temp := CHAN_PTR_TABLE(ch_table)[16]^;
      CHAN_PTR_TABLE(ch_table)[16]^ := CHAN_PTR_TABLE(ch_table)[7]^;
      CHAN_PTR_TABLE(ch_table)[7]^ := temp;
      temp := CHAN_PTR_TABLE(ch_table)[17]^;
      CHAN_PTR_TABLE(ch_table)[17]^ := CHAN_PTR_TABLE(ch_table)[8]^;
      CHAN_PTR_TABLE(ch_table)[8]^ := temp;
    end;
end;

end.
