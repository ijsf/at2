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

{
    procedure import_standard_instrument_alt(var data);
    procedure import_fin_instrument_alt(var data);
    procedure import_hsc_instrument_alt(var data);
    procedure import_sat_instrument_alt(var data);
    procedure a2i_file_loader_alt(fname: String);
    procedure a2f_file_loader_alt(fname: String);
    procedure cif_file_loader_alt(fname: String);
    procedure fin_file_loader_alt(fname: String);
    procedure ins_file_loader_alt(fname: String);
    procedure sbi_file_loader_alt(fname: String);
    procedure sgi_file_loader_alt(fname: String);
    procedure import_instrument_from_data_record;
    procedure import_sbi_instrument_alt(var data);
    procedure test_instrument_alt(chan: Byte; fkey: Word; loadMacros: Boolean; bankSelector: Boolean; loadArpVib: Boolean;
                                  test_ins1,test_ins2: Byte);
    procedure test_instrument_alt2(chan: Byte; fkey: Word);
    procedure fselect_external_proc;
}

procedure import_standard_instrument_alt(var data);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:import_standard_instrument_alt';
{$ENDIF}
  With temp_instrument do
    begin
      fm_data.AM_VIB_EG_modulator := pBYTE(@data)[0];
      fm_data.AM_VIB_EG_carrier   := pBYTE(@data)[1];
      fm_data.KSL_VOLUM_modulator := pBYTE(@data)[2];
      fm_data.KSL_VOLUM_carrier   := pBYTE(@data)[3];
      fm_data.ATTCK_DEC_modulator := pBYTE(@data)[4];
      fm_data.ATTCK_DEC_carrier   := pBYTE(@data)[5];
      fm_data.SUSTN_REL_modulator := pBYTE(@data)[6];
      fm_data.SUSTN_REL_carrier   := pBYTE(@data)[7];
      fm_data.WAVEFORM_modulator  := pBYTE(@data)[8]  AND 3;
      fm_data.WAVEFORM_carrier    := pBYTE(@data)[9]  AND 3;
      fm_data.FEEDBACK_FM         := pBYTE(@data)[10] AND $0f;
    end;

  temp_instrument.panning := 0;
  temp_instrument.fine_tune := 0;
end;

procedure import_fin_instrument_alt(var data);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:import_fin_instrument_alt';
{$ENDIF}
  With temp_instrument do
    begin
      fm_data.AM_VIB_EG_modulator := pBYTE(@data)[0];
      fm_data.AM_VIB_EG_carrier   := pBYTE(@data)[1];
      fm_data.KSL_VOLUM_modulator := pBYTE(@data)[2];
      fm_data.KSL_VOLUM_carrier   := pBYTE(@data)[3];
      fm_data.ATTCK_DEC_modulator := pBYTE(@data)[4];
      fm_data.ATTCK_DEC_carrier   := pBYTE(@data)[5];
      fm_data.SUSTN_REL_modulator := pBYTE(@data)[6];
      fm_data.SUSTN_REL_carrier   := pBYTE(@data)[7];
      fm_data.WAVEFORM_modulator  := pBYTE(@data)[8]  AND 7;
      fm_data.WAVEFORM_carrier    := pBYTE(@data)[9]  AND 7;
      fm_data.FEEDBACK_FM         := pBYTE(@data)[10] AND $0f;
    end;

  temp_instrument.panning := 0;
  temp_instrument.fine_tune := 0;
end;

procedure import_hsc_instrument_alt(var data);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:import_hsc_instrument_alt';
{$ENDIF}
  With temp_instrument do
    begin
      fm_data.AM_VIB_EG_carrier   := pBYTE(@data)[0];
      fm_data.AM_VIB_EG_modulator := pBYTE(@data)[1];
      fm_data.KSL_VOLUM_carrier   := pBYTE(@data)[2];
      fm_data.KSL_VOLUM_modulator := pBYTE(@data)[3];
      fm_data.ATTCK_DEC_carrier   := pBYTE(@data)[4];
      fm_data.ATTCK_DEC_modulator := pBYTE(@data)[5];
      fm_data.SUSTN_REL_carrier   := pBYTE(@data)[6];
      fm_data.SUSTN_REL_modulator := pBYTE(@data)[7];
      fm_data.FEEDBACK_FM         := pBYTE(@data)[8]  AND $0f;
      fm_data.WAVEFORM_carrier    := pBYTE(@data)[9]  AND 3;
      fm_data.WAVEFORM_modulator  := pBYTE(@data)[10] AND 3;
    end;

  temp_instrument.panning := 0;
  temp_instrument.fine_tune := pBYTE(@data)[11] SHR 4;
end;

procedure import_sat_instrument_alt(var data);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:import_sat_instrument_alt';
{$ENDIF}
  With temp_instrument do
    begin
      fm_data.FEEDBACK_FM         := pBYTE(@data)[0] AND $0f;
      fm_data.AM_VIB_EG_modulator := pBYTE(@data)[1];
      fm_data.AM_VIB_EG_carrier   := pBYTE(@data)[2];
      fm_data.ATTCK_DEC_modulator := pBYTE(@data)[3];
      fm_data.ATTCK_DEC_carrier   := pBYTE(@data)[4];
      fm_data.SUSTN_REL_modulator := pBYTE(@data)[5];
      fm_data.SUSTN_REL_carrier   := pBYTE(@data)[6];
      fm_data.WAVEFORM_modulator  := pBYTE(@data)[7] AND 3;
      fm_data.WAVEFORM_carrier    := pBYTE(@data)[8] AND 3;
      fm_data.KSL_VOLUM_modulator := pBYTE(@data)[9];
      fm_data.KSL_VOLUM_carrier   := pBYTE(@data)[10];
    end;

  temp_instrument.panning := 0;
  temp_instrument.fine_tune := 0;
end;

procedure a2i_file_loader_alt(fname: String);

type
  tOLD_HEADER = Record
                  ident: array[1..7] of Char;
                  crc16: Word;
                  ffver: Byte;
                  b0len: Byte;
                end;
type
  tHEADER = Record
              ident: array[1..7] of Char;
              crc16: Word;
              ffver: Byte;
              b0len: Word;
            end;
const
  id = '_A2ins_';

var
  f: File;
  header: tOLD_HEADER;
  header2: tHEADER;
  temp,temp2: Longint;
  crc: Word;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:a2i_file_loader_alt';
{$ENDIF}
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  {$i-}
  Assign(f,fname);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,header,SizeOf(header),temp);
  If NOT ((temp = SizeOf(header)) and (header.ident = id)) then
    begin
      CloseF(f);
      EXIT;
    end;

  If NOT (header.ffver in [1..FFVER_A2I]) then
    begin
      CloseF(f);
      EXIT;
    end;

  If (header.ffver in [1..4]) then
    begin
      BlockReadF(f,buf2,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := WORD_NULL;
      crc := Update16(header.b0len,1,crc);
      crc := Update16(buf2,header.b0len,crc);

      If (crc <> header.crc16) then
        begin
          CloseF(f);
          EXIT;
        end;

      Case header.ffver of
        4: Move(buf2,buf3,header.b0len);
        3: LZSS_decompress(buf2,buf3,header.b0len);
        2: LZW_decompress(buf2,buf3);
        1: SIXPACK_decompress(buf2,buf3,header.b0len);
      end;

      Move(buf3,temp_instrument,SizeOf(temp_instrument));
      temp_instrument.panning := 0;
    end;

  If (header.ffver in [5..8]) then
    begin
      BlockReadF(f,buf2,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := WORD_NULL;
      crc := Update16(header.b0len,1,crc);
      crc := Update16(buf2,header.b0len,crc);

      If (crc <> header.crc16) then
        begin
          CloseF(f);
          EXIT;
        end;

      Case header.ffver of
        8: Move(buf2,buf3,header.b0len);
        7: LZSS_decompress(buf2,buf3,header.b0len);
        6: LZW_decompress(buf2,buf3);
        5: SIXPACK_decompress(buf2,buf3,header.b0len);
      end;

      Move(buf3,temp_instrument,SizeOf(temp_instrument));
    end;

  If (header.ffver = 9) then
    begin
      ResetF(f);
      BlockReadF(f,header2,SizeOf(header2),temp);
      If NOT ((temp = SizeOf(header2)) and (header2.ident = id)) then
        begin
          CloseF(f);
          EXIT;
        end;

      BlockReadF(f,buf2,header2.b0len,temp);
      If NOT (temp = header2.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := WORD_NULL;
      crc := Update16(header2.b0len,1,crc);
      crc := Update16(buf2,header2.b0len,crc);

      If (crc <> header2.crc16) then
        begin
          CloseF(f);
          EXIT;
        end;

      APACK_decompress(buf2,buf3);
      Move(buf3,temp_instrument,SizeOf(temp_instrument));
    end;

  If (header.ffver = FFVER_A2I) then
    begin
      ResetF(f);
      BlockReadF(f,header2,SizeOf(header2),temp);
      If NOT ((temp = SizeOf(header2)) and (header2.ident = id)) then
        begin
          CloseF(f);
          EXIT;
        end;

      BlockReadF(f,buf2,header2.b0len,temp);
      If NOT (temp = header2.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := WORD_NULL;
      crc := Update16(header2.b0len,1,crc);
      crc := Update16(buf2,header2.b0len,crc);

      If (crc <> header2.crc16) then
        begin
          CloseF(f);
          EXIT;
        end;

      progress_num_steps := 0;
      temp := 0;
      temp2 := LZH_decompress(buf2,buf3,header2.b0len);
      Move(buf3[temp],temp_instrument,SizeOf(temp_instrument));
      Inc(temp,SizeOf(temp_instrument)); // instrument data
      Inc(temp,SUCC(buf3[temp])); // instrument name
      If (temp < temp2) then // more data present => 4op instrument
        begin
          Move(temp_instrument,temp_instrument2,SizeOf(temp_instrument2));
          Move(buf3[temp],temp_instrument,SizeOf(temp_instrument));
          Inc(temp,SizeOf(temp_instrument));
        end;
    end;

  CloseF(f);
  load_flag_alt := 1;
end;

procedure a2f_file_loader_alt(fname: String);

type
  tHEADER = Record
              ident: array[1..18] of Char;
              crc32: Longint;
              ffver: Byte;
              b0len: Word;
            end;
const
  id = '_a2ins_w/fm-macro_';

var
  f: File;
  header: tHEADER;
  crc,temp,temp2: Longint;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:a2f_file_loader_alt';
{$ENDIF}
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  FillChar(temp_instrument_macro,SizeOf(temp_instrument_macro),0);
  FillChar(temp_instrument_dis_fmreg_col,SizeOf(temp_instrument_dis_fmreg_col),0);
  {$i-}
  Assign(f,fname);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,header,SizeOf(header),temp);
  If NOT ((temp = SizeOf(header)) and (header.ident = id)) then
    begin
      CloseF(f);
      EXIT;
    end;

  If NOT (header.ffver in [1..FFVER_A2F]) then
    begin
      CloseF(f);
      EXIT;
    end;

  If (header.ffver = 1) then
    begin
      BlockReadF(f,buf2,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := DWORD_NULL;
      crc := Update32(header.b0len,1,crc);
      crc := Update32(buf2,header.b0len,crc);

      If (crc <> header.crc32) then
        begin
          CloseF(f);
          EXIT;
        end;

      APACK_decompress(buf2,buf3);
      Move(buf3,temp_instrument,SizeOf(temp_instrument));
      Move(buf3[SizeOf(songdata.instr_data[current_inst])+
                buf3[SizeOf(songdata.instr_data[current_inst])]+1],
           temp_instrument_macro,
           SizeOf(temp_instrument_macro));

      Move(buf3[SizeOf(songdata.instr_data[current_inst])+
                buf3[SizeOf(songdata.instr_data[current_inst])]+1+
                SizeOf(songdata.instr_macros[current_inst])],
           temp_instrument_dis_fmreg_col,
           SizeOf(temp_instrument_dis_fmreg_col));
    end;

  If (header.ffver = FFVER_A2F) then
    begin
      BlockReadF(f,buf2,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := DWORD_NULL;
      crc := Update32(header.b0len,1,crc);
      crc := Update32(buf2,header.b0len,crc);

      If (crc <> header.crc32) then
        begin
          CloseF(f);
          EXIT;
        end;

      progress_num_steps := 0;
      temp := 0;
      temp2 := LZH_decompress(buf2,buf3,header.b0len);
      Move(buf3[temp],temp_instrument,SizeOf(temp_instrument));
      Inc(temp,SizeOf(temp_instrument)); // instrument data
      Inc(temp,SUCC(buf3[temp])); // instrument name
      Move(buf3[temp],temp_instrument_macro,
           SizeOf(temp_instrument_macro));
      Inc(temp,SizeOf(temp_instrument_macro)); // instrument macro
      Move(buf3[temp],temp_instrument_dis_fmreg_col,
           SizeOf(temp_instrument_dis_fmreg_col));
      Inc(temp,SizeOf(temp_instrument_dis_fmreg_col)); // disabled FM-macro columns
      If (temp < temp2) then // more data present => 4op instrument
        begin
          Move(temp_instrument,temp_instrument2,SizeOf(temp_instrument2));
          Move(temp_instrument_macro,temp_instrument_macro2,SizeOf(temp_instrument_macro2));
          Move(temp_instrument_dis_fmreg_col,temp_instrument_dis_fmreg_col2,SizeOf(temp_instrument_dis_fmreg_col2));
          Move(buf3[temp],temp_instrument,SizeOf(temp_instrument));
          Inc(temp,SizeOf(temp_instrument));
          Inc(temp,SUCC(buf3[temp]));
          Move(buf3[temp],temp_instrument_macro,
               SizeOf(temp_instrument_macro));
          Inc(temp,SizeOf(temp_instrument_macro));
          Move(buf3[temp],temp_instrument_dis_fmreg_col,
               SizeOf(temp_instrument_dis_fmreg_col));
        end;
    end;

  CloseF(f);
  load_flag_alt := 1;
end;

procedure cif_file_loader_alt(fname: String);

const
  id = '<CUD-FM-Instrument>'+#26;

type
  tCIF_DATA = Record
                ident: array[1..20] of Char;
                idata: tFM_INST_DATA;
                resrv: Byte;
                iname: array[1..20] of Char;
              end;
var
  f: File;
  buffer: tCIF_DATA;
  temp: Longint;

const
  MIN_CIF_SIZE = SizeOf(buffer.ident)+
                 SizeOf(buffer.idata)+
                 SizeOf(buffer.resrv);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:cif_file_loader_alt';
{$ENDIF}
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  {$i-}
  Assign(f,fname);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,buffer,SizeOf(buffer),temp);
  If NOT ((temp >= MIN_CIF_SIZE) and (buffer.ident = id)) then
    begin
      CloseF(f);
      EXIT;
    end;

  import_hsc_instrument_alt(buffer.idata);
  temp_instrument.fine_tune := 0;
  CloseF(f);
  load_flag_alt := 1;
end;

type
  tFIN_DATA = Record
                dname: array[1..12] of Char;
                iname: array[1..27] of Char;
                idata: tFM_INST_DATA;
              end;

procedure fin_file_loader_alt(fname: String);

var
  f: File;
  buffer: tFIN_DATA;
  temp: Longint;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:fin_file_loader_alt';
{$ENDIF}
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  {$i-}
  Assign(f,fname);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,buffer,SizeOf(buffer),temp);
  If (temp <> SizeOf(buffer)) then
    begin
      CloseF(f);
      EXIT;
    end;

  import_fin_instrument_alt(buffer.idata);
  CloseF(f);
  load_flag_alt := 1;
end;

procedure ins_file_loader_alt(fname: String);

type
  tINS_DATA = Record
                idata: tFM_INST_DATA;
                slide: Byte;
                _SAdT: array[0..18] of Byte;
              end;
var
  f: File;
  buffer: tINS_DATA;
  temp: Longint;

function correct_ins(var data): Boolean;

var
  result: Boolean;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:ins_file_loader_alt:correct_ins';
{$ENDIF}
  result := TRUE;
  If NOT (tADTRACK2_INS(data).fm_data.WAVEFORM_modulator in [0..3]) then
    result := FALSE;
  If NOT (tADTRACK2_INS(data).fm_data.WAVEFORM_carrier in [0..3]) then
    result := FALSE;
  If NOT (tADTRACK2_INS(data).fm_data.FEEDBACK_FM in [0..15]) then
    result := FALSE;
  correct_ins := result;
end;

begin { ins_file_loader_alt }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:ins_file_loader_alt';
{$ENDIF}
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  {$i-}
  Assign(f,fname);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  If (FileSize(f) > SizeOf(buffer)) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,buffer,FileSize(f),temp);
  If (temp <> FileSize(f)) then
    begin
      CloseF(f);
      EXIT;
    end;

  Case force_ins of
    0: begin
         If (temp = 12) then
           import_standard_instrument_alt(buffer.idata);
         If (temp = 12) and NOT correct_ins(buffer.idata) then
           import_hsc_instrument_alt(buffer.idata)
         else If (temp > 12) then
                import_sat_instrument_alt(buffer.idata);
       end;

    1: import_hsc_instrument_alt(buffer.idata);
    2: import_sat_instrument_alt(buffer.idata);
    3: import_standard_instrument_alt(buffer.idata);
  end;

  CloseF(f);
  load_flag_alt := 1;
end;

procedure sbi_file_loader_alt(fname: String);

const
  id = 'SBI'+#26;

type
  tSBI_DATA = Record
                ident: array[1..4]  of Char;
                iname: array[1..32] of Char;
                idata: tFM_INST_DATA;
                dummy: array[1..5]  of Byte;
              end;
var
  f: File;
  buffer: tSBI_DATA;
  temp: Longint;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:sbi_file_loader_alt';
{$ENDIF}
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  {$i-}
  Assign(f,fname);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,buffer,SizeOf(buffer),temp);
  If NOT ((temp = SizeOf(buffer)) and (buffer.ident = id)) then
    begin
      CloseF(f);
      EXIT;
    end;

  import_standard_instrument_alt(buffer.idata);
  CloseF(f);
  load_flag_alt := 1;
end;

procedure sgi_file_loader_alt(fname: String);

type
  tSGI_DATA = Record
           { 0} attack_m,
           { 1} decay_m,
           { 2} sustain_m,
           { 3} release_m,
           { 4} waveform_m,
           { 5} mfmult_m,
           { 6} ksl_m,
           { 7} volume_m,
           { 8} ksr_m,
           { 9} tremolo_m,
           {10} vibrato_m,
           {11} eg_type_m,
           {12} attack_c,
           {13} decay_c,
           {14} sustain_c,
           {15} release_c,
           {16} waveform_c,
           {17} mfmult_c,
           {18} ksl_c,
           {19} volume_c,
           {20} ksr_c,
           {21} tremolo_c,
           {22} vibrato_c,
           {23} eg_type_c,
           {24} feedback,
           {25} fm:        Byte;
              end;
var
  f: File;
  buffer: tSGI_DATA;
  temp: Longint;

procedure import_sgi_instrument(inst: Byte; var data);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:sgi_file_loader_alt:import_sgi_instrument';
{$ENDIF}
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  With temp_instrument do
    begin
      fm_data.ATTCK_DEC_modulator := (pBYTE(@data)[1]  AND $0f)+
                                     (pBYTE(@data)[0]  AND $0f) SHL 4;
      fm_data.SUSTN_REL_modulator := (pBYTE(@data)[3]  AND $0f)+
                                     (pBYTE(@data)[2]  AND $0f) SHL 4;
      fm_data.WAVEFORM_modulator  := (pBYTE(@data)[4]  AND 3);
      fm_data.KSL_VOLUM_modulator := (pBYTE(@data)[7]  AND $3f)+
                                     (pBYTE(@data)[6]  AND 3) SHL 6;
      fm_data.AM_VIB_EG_modulator := (pBYTE(@data)[5]  AND $0f)+
                                     (pBYTE(@data)[8]  AND 1) SHL 4+
                                     (pBYTE(@data)[11] AND 1) SHL 5+
                                     (pBYTE(@data)[10] AND 1) SHL 6+
                                     (pBYTE(@data)[9]  AND 1) SHL 7;
      fm_data.ATTCK_DEC_carrier   := (pBYTE(@data)[13] AND $0f)+
                                     (pBYTE(@data)[12] AND $0f) SHL 4;
      fm_data.SUSTN_REL_carrier   := (pBYTE(@data)[15] AND $0f)+
                                     (pBYTE(@data)[14] AND $0f) SHL 4;
      fm_data.WAVEFORM_carrier    := (pBYTE(@data)[16] AND 3);
      fm_data.KSL_VOLUM_carrier   := (pBYTE(@data)[19] AND $3f)+
                                     (pBYTE(@data)[18] AND 3) SHL 6;
      fm_data.AM_VIB_EG_carrier   := (pBYTE(@data)[17] AND $0f)+
                                     (pBYTE(@data)[20] AND 1) SHL 4+
                                     (pBYTE(@data)[23] AND 1) SHL 5+
                                     (pBYTE(@data)[22] AND 1) SHL 6+
                                     (pBYTE(@data)[21] AND 1) SHL 7;
      fm_data.FEEDBACK_FM         := (pBYTE(@data)[25] AND 1)+
                                     (pBYTE(@data)[24] AND 7) SHL 1;
    end;
end;

begin { sgi_file_loader_alt }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:sgi_file_loader_alt';
{$ENDIF}
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  {$i-}
  Assign(f,fname);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,buffer,SizeOf(buffer),temp);
  If (temp <> SizeOf(buffer)) then
    begin
      CloseF(f);
      EXIT;
    end;

  import_sgi_instrument(current_inst,buffer);
  CloseF(f);
  load_flag_alt := 1;
end;

procedure import_sbi_instrument_alt(var data);
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:import_sbi_instrument_alt';
{$ENDIF}
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  With temp_instrument do
    begin
      fm_data.AM_VIB_EG_modulator := pBYTE(@data)[0];
      fm_data.AM_VIB_EG_carrier   := pBYTE(@data)[1];
      fm_data.KSL_VOLUM_modulator := pBYTE(@data)[2];
      fm_data.KSL_VOLUM_carrier   := pBYTE(@data)[3];
      fm_data.ATTCK_DEC_modulator := pBYTE(@data)[4];
      fm_data.ATTCK_DEC_carrier   := pBYTE(@data)[5];
      fm_data.SUSTN_REL_modulator := pBYTE(@data)[6];
      fm_data.SUSTN_REL_carrier   := pBYTE(@data)[7];
      fm_data.WAVEFORM_modulator  := pBYTE(@data)[8]  AND 3;
      fm_data.WAVEFORM_carrier    := pBYTE(@data)[9]  AND 3;
      fm_data.FEEDBACK_FM         := pBYTE(@data)[10] AND $0f;
    end;

  temp_instrument.panning := 0;
  temp_instrument.fine_tune := 0;
end;

procedure ibk_file_loader_alt(instr: Word);

const
  id = 'IBK'+#26;

var
  f: File;
  header: array[1..4] of Char;
  temp: Longint;
  instrument_data: Record
                     idata: tFM_INST_DATA;
                     dummy: array[1..5] of Byte;
                   end;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:ibk_file_loader_alt';
{$ENDIF}
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,header,SizeOf(header),temp);
  If (temp <> SizeOf(header)) or
     (header <> id) then
    begin
      CloseF(f);
      EXIT;
    end;

  SeekF(f,$004+PRED(instr)*SizeOf(instrument_data));
  If (IOresult <> 0) then EXIT;

  BlockReadF(f,instrument_data,SizeOf(instrument_data),temp);
  If (temp <> SizeOf(instrument_data)) then
    begin
      CloseF(f);
      EXIT;
    end;

  import_sbi_instrument_alt(instrument_data);
  CloseF(f);
  load_flag_alt := 1;
end;

var
  ins__fmreg_table_backup: tREGISTER_TABLE;
  ins__fmreg_table_backup2: tREGISTER_TABLE;
  ins__dis_fmreg_col_backup: tDIS_FMREG_COL;
  ins__dis_fmreg_col_backup2: tDIS_FMREG_COL;
  arp_vib_macro_table_backup: tARP_VIB_MACRO_TABLE;
  chan_handle: array[1..20] of Byte;

procedure test_instrument_alt(chan: Byte; fkey: Word; loadMacros: Boolean; bankSelector: Boolean; loadArpVib: Boolean;
                              test_ins1,test_ins2: Byte);

var
  temp,temp2,temp3,temp5: Byte;
  valid_key,temp4: Boolean;
  temps: String;
  channels: Byte;

function output_note(chan,board_pos: Byte): Boolean;

var
  note: Byte;
  freq: Word;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:test_instrument_alt:output_note';
{$ENDIF}
  note := board_pos+12*(current_octave-1);
  If NOT (note in [0..12*8+1]) then
    begin
      output_note := FALSE;
      EXIT;
    end;

  chan_handle[chan] := board_scancodes[board_pos];
  If (test_ins2 <> 0) then chan := _4op_main_chan[chan];
  load_instrument(temp_instrument,chan);

  If percussion_mode and
     (temp_instrument.perc_voice in [4,5]) then
    load_instrument(temp_instrument,_perc_sim_chan[chan]);

  If (test_ins2 <> 0) then
    load_instrument(temp_instrument2,PRED(chan));

  macro_speedup := songdata.macro_speedup;
  If (play_status = isStopped) then update_timer(songdata.tempo);

  freq := nFreq(note-1)+$2000+
          SHORTINT(pBYTE(@Addr(temp_instrument)^)[12]);
  event_table[chan].note := note;
  freq_table[chan] := freq;
  freqtable2[chan] := freq;
  key_on(chan);
  change_freq(chan,freq);

  If (test_ins2 = 0) then init_macro_table(chan,note,test_ins1,freq)
  else begin
         init_macro_table(chan,note,test_ins1,freq);
         freq_table[PRED(chan)] := freq;
         freqtable2[PRED(chan)] := freq;
         init_macro_table(PRED(chan),note,test_ins2,freq);
       end;
end;

begin { test_instrument_alt }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:test_instrument_alt';
{$ENDIF}
  valid_key := FALSE;
  For temp := 1 to 29 do
    If NOT shift_pressed then
      If (board_scancodes[temp] = HI(fkey)) then
        begin
          valid_key := TRUE;
          BREAK;
        end;

  If scankey(SC_F7) then
    For temp := 1 to 20 do reset_chan_data(temp);

  If NOT valid_key or
     NOT (temp+12*(current_octave-1)-1 in [0..12*8+1]) then EXIT;

  If NOT percussion_mode then channels := 18
  else channels := 15;

  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  FillChar(temp_instrument2,SizeOf(temp_instrument2),0);
  temp2 := temp;

  If bankSelector or loadArpVib then
    If NOT loadArpVib then
      begin
        temps := '';
        load_flag_alt := BYTE_NULL;
        If (test_ins2 = 0) then
          begin
            Move(temp_songdata.instr_data[test_ins1],
                 temp_instrument,
                 SizeOf(temp_instrument));
            Move(temp_songdata.instr_macros[test_ins1],
                 temp_instrument_macro,
                 SizeOf(temp_instrument_macro));
            Move(temp_songdata.dis_fmreg_col[test_ins1],
                 temp_instrument_dis_fmreg_col,
                 SizeOf(temp_instrument_dis_fmreg_col));
          end
        else begin
               Move(temp_songdata.instr_data[test_ins1],
                    temp_instrument,
                    SizeOf(temp_instrument));
               Move(temp_songdata.instr_macros[test_ins1],
                    temp_instrument_macro,
                    SizeOf(temp_instrument_macro));
               Move(temp_songdata.dis_fmreg_col[test_ins1],
                    temp_instrument_dis_fmreg_col,
                    SizeOf(temp_instrument_dis_fmreg_col));
               Move(temp_songdata.instr_data[test_ins2],
                    temp_instrument2,
                    SizeOf(temp_instrument2));
               Move(temp_songdata.instr_macros[test_ins2],
                    temp_instrument_macro2,
                    SizeOf(temp_instrument_macro2));
               Move(temp_songdata.dis_fmreg_col[test_ins2],
                    temp_instrument_dis_fmreg_col2,
                    SizeOf(temp_instrument_dis_fmreg_col2));
             end;
      end
    else
      begin
        load_flag_alt := BYTE_NULL;
        If (test_ins2 = 0) then
          begin
            Move(songdata.instr_data[test_ins1],
                 temp_instrument,
                 SizeOf(temp_instrument));
            Move(songdata.instr_macros[test_ins1],
                 temp_instrument_macro,
                 SizeOf(temp_instrument_macro));
            Move(songdata.dis_fmreg_col[test_ins1],
                 temp_instrument_dis_fmreg_col,
                 SizeOf(temp_instrument_dis_fmreg_col));
          end
        else begin
               Move(songdata.instr_data[test_ins1],
                    temp_instrument,
                    SizeOf(temp_instrument));
               Move(songdata.instr_macros[test_ins1],
                    temp_instrument_macro,
                    SizeOf(temp_instrument_macro));
               Move(songdata.dis_fmreg_col[test_ins1],
                    temp_instrument_dis_fmreg_col,
                    SizeOf(temp_instrument_dis_fmreg_col));
               Move(songdata.instr_data[test_ins2],
                    temp_instrument2,
                    SizeOf(temp_instrument2));
               Move(songdata.instr_macros[test_ins2],
                    temp_instrument_macro2,
                    SizeOf(temp_instrument_macro2));
               Move(songdata.dis_fmreg_col[test_ins2],
                    temp_instrument_dis_fmreg_col2,
                    SizeOf(temp_instrument_dis_fmreg_col2));
             end;
      end
  else
    begin
      temps := mn_environment.curr_item;
      load_flag_alt := BYTE_NULL;
{$IFDEF GO32V2}
      keyboard_toggle_sleep;
{$ENDIF}
      If (Lower(ExtOnly(temps)) = 'a2i') then
        a2i_file_loader_alt(temps)
      else If (Lower(ExtOnly(temps)) = 'a2f') then
             a2f_file_loader_alt(temps)
           else If (Lower(ExtOnly(temps)) = 'cif') then
                  cif_file_loader_alt(temps)
                else If (Lower(ExtOnly(temps)) = 'fin') then
                       fin_file_loader_alt(temps)
                     else If (Lower(ExtOnly(temps)) = 'ins') then
                            ins_file_loader_alt(temps)
                           else If (Lower(ExtOnly(temps)) = 'sbi') then
                                  sbi_file_loader_alt(temps)
                                 else If (Lower(ExtOnly(temps)) = 'sgi') then
                                        sgi_file_loader_alt(temps);
{$IFDEF GO32V2}
      keyboard_toggle_sleep;
{$ENDIF}
      If (load_flag_alt = BYTE_NULL) then EXIT;
    end;

  If (test_ins2 <> 0) and Empty(temp_instrument2,SizeOf(temp_instrument2)) and
                          Empty(temp_instrument_macro2,SizeOf(temp_instrument_macro2)) then
    test_ins2 := 0;

  Move(songdata.macro_table,
       arp_vib_macro_table_backup,
       SizeOf(arp_vib_macro_table_backup));

  If loadArpVib then
    begin
      If arp_tab_selected then
        begin
          temp_instrument_macro.arpeggio_table := arpvib_arpeggio_table;
          Move(temp_songdata.macro_table[arpvib_arpeggio_table].arpeggio,
               songdata.macro_table[arpvib_arpeggio_table].arpeggio,
               SizeOf(songdata.macro_table[arpvib_arpeggio_table]));
        end
      else temp_instrument_macro.arpeggio_table := 0;
      If vib_tab_selected then
        begin
          temp_instrument_macro.vibrato_table := arpvib_vibrato_table;
          Move(temp_songdata.macro_table[arpvib_vibrato_table].vibrato,
               songdata.macro_table[arpvib_vibrato_table].vibrato,
               SizeOf(songdata.macro_table[arpvib_vibrato_table]));
        end
      else temp_instrument_macro.vibrato_table := 0;
      If (test_ins2 = 0) then
        Move(temp_instrument_macro,
             songdata.instr_macros[test_ins1],
             SizeOf(songdata.instr_macros[test_ins1]))
      else begin
             Move(temp_instrument_macro,
                  songdata.instr_macros[test_ins1],
                  SizeOf(songdata.instr_macros[test_ins1]));
             Move(temp_instrument_macro2,
                  songdata.instr_macros[test_ins2],
                  SizeOf(songdata.instr_macros[test_ins2]));
           end;
    end
  else If bankSelector and loadMacros then
         begin
           If (temp_instrument_macro.arpeggio_table <> 0) then
             Move(temp_songdata.macro_table[temp_instrument_macro.arpeggio_table].arpeggio,
                  songdata.macro_table[temp_instrument_macro.arpeggio_table].arpeggio,
                  SizeOf(songdata.macro_table[temp_instrument_macro.arpeggio_table]));
           If (temp_instrument_macro.vibrato_table <> 0) then
             Move(temp_songdata.macro_table[temp_instrument_macro.vibrato_table].vibrato,
                  songdata.macro_table[temp_instrument_macro.vibrato_table].vibrato,
                  SizeOf(songdata.macro_table[temp_instrument_macro.vibrato_table]));
         end;

  If (Empty(temp_instrument,SizeOf(temp_instrument)) and
      Empty(temp_instrument_macro,SizeOf(temp_instrument_macro))) or
     ((test_ins2 <> 0) and Empty(temp_instrument2,SizeOf(temp_instrument2)) and
                           Empty(temp_instrument_macro2,SizeOf(temp_instrument_macro2))) then
    EXIT;

  ins_trailing_flag := TRUE;
  status_backup.replay_forbidden := replay_forbidden;
  status_backup.play_status := play_status;
  replay_forbidden := TRUE;
  If (play_status <> isStopped) then play_status := isPaused;
  nul_volume_bars;
  really_no_status_refresh := TRUE;
  reset_player;

  If (Lower(ExtOnly(temps)) = 'a2f') or loadMacros or loadArpVib then
    If (test_ins2 = 0) then
      begin
        Move(songdata.instr_macros[test_ins1],
             ins__fmreg_table_backup,
             SizeOf(ins__fmreg_table_backup));
        Move(songdata.dis_fmreg_col[test_ins1],
             ins__dis_fmreg_col_backup,
             SizeOf(ins__dis_fmreg_col_backup));
        Move(temp_instrument_macro,
             songdata.instr_macros[test_ins1],
             SizeOf(songdata.instr_macros[test_ins1]));
        Move(temp_instrument_dis_fmreg_col,
             songdata.dis_fmreg_col[test_ins1],
             SizeOf(songdata.dis_fmreg_col[test_ins1]));
      end
    else begin
           Move(songdata.instr_macros[test_ins1],
                ins__fmreg_table_backup,
                SizeOf(ins__fmreg_table_backup));
           Move(songdata.dis_fmreg_col[test_ins1],
                ins__dis_fmreg_col_backup,
                SizeOf(ins__dis_fmreg_col_backup));
           Move(temp_instrument_macro,
                songdata.instr_macros[test_ins1],
                SizeOf(songdata.instr_macros[test_ins1]));
           Move(temp_instrument_dis_fmreg_col,
                songdata.dis_fmreg_col[test_ins1],
                SizeOf(songdata.dis_fmreg_col[test_ins1]));
           Move(songdata.instr_macros[test_ins2],
                ins__fmreg_table_backup2,
                SizeOf(ins__fmreg_table_backup));
           Move(songdata.dis_fmreg_col[test_ins2],
                ins__dis_fmreg_col_backup2,
                SizeOf(ins__dis_fmreg_col_backup));
           Move(temp_instrument_macro2,
                songdata.instr_macros[test_ins2],
                SizeOf(songdata.instr_macros[test_ins2]));
           Move(temp_instrument_dis_fmreg_col2,
                songdata.dis_fmreg_col[test_ins2],
                SizeOf(songdata.dis_fmreg_col[test_ins2]));
         end
  else
    begin
      Move(songdata.instr_macros[test_ins1],
           ins__fmreg_table_backup,
           SizeOf(ins__fmreg_table_backup));
      Move(songdata.dis_fmreg_col[test_ins1],
           ins__dis_fmreg_col_backup,
           SizeOf(ins__dis_fmreg_col_backup));
      FillChar(songdata.instr_macros[test_ins1],SizeOf(songdata.instr_macros[test_ins1]),0);
      FillChar(songdata.dis_fmreg_col[test_ins1],SizeOf(songdata.dis_fmreg_col[test_ins1]),0);

          If (test_ins2 <> 0) then
        begin
          Move(songdata.instr_macros[test_ins2],
               ins__fmreg_table_backup2,
               SizeOf(ins__fmreg_table_backup));
          Move(songdata.dis_fmreg_col[test_ins2],
               ins__dis_fmreg_col_backup2,
               SizeOf(ins__dis_fmreg_col_backup));
          FillChar(songdata.instr_macros[test_ins2],SizeOf(songdata.instr_macros[test_ins2]),0);
          FillChar(songdata.dis_fmreg_col[test_ins2],SizeOf(songdata.dis_fmreg_col[test_ins2]),0);
        end;
    end;

  Move(channel_flag,channel_flag_backup,SizeOf(channel_flag_backup));
  Move(event_table,event_table_backup,SizeOf(event_table_backup));
  common_flag_backup := songdata.common_flag;
  volume_scaling_backup := volume_scaling;
  songdata.common_flag := songdata.common_flag AND NOT $80;
  volume_scaling := FALSE;
  FillChar(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
  Move(pan_lock,pan_lock_backup,SizeOf(pan_lock));
  Move(volume_lock,volume_lock_backup,SizeOf(volume_lock));
  Move(peak_lock,peak_lock_backup,SizeOf(volume_lock));
  Move(panning_table,panning_table_backup,SizeOf(panning_table));
  FillChar(pan_lock,SizeOf(pan_lock),0);
  FillChar(volume_lock,SizeOf(volume_lock),0);
  FillChar(peak_lock,SizeOf(volume_lock),0);
  flag_4op_backup := songdata.flag_4op;
  If NOT percussion_mode and
     NOT (songdata.flag_4op <> 0) then channels := 18
  else If NOT (songdata.flag_4op <> 0) then channels := 15
       else If (test_ins2 <> 0) then
              begin
                songdata.flag_4op := $3f;
                channels := 6;
              end
            else begin
                   songdata.flag_4op := 0;
                   If NOT percussion_mode then channels := 18
                   else channels := 15;
                 end;

  reset_player;
  FillChar(chan_handle,SizeOf(chan_handle),0);
  Move(fmpar_table,fmpar_table_backup,SizeOf(fmpar_table_backup));
  Move(volume_table,volume_table_backup,SizeOf(volume_table_backup));
  Move(freq_table,freq_table_backup,SizeOf(freq_table));
  Move(freqtable2,freqtable2_backup,SizeOf(freqtable2));
  Move(keyoff_loop,keyoff_loop_backup,SizeOf(keyoff_loop));
  FillChar(keyoff_loop,SizeOf(keyoff_loop),FALSE);

  misc_register := current_tremolo_depth SHL 7+
                   current_vibrato_depth SHL 6+
                   BYTE(percussion_mode) SHL 5;
  key_off(17);
  key_off(18);
  opl2out(_instr[11],misc_register);

  If percussion_mode and
     (temp_instrument.perc_voice in [1..5]) then
    begin
      output_note(temp_instrument.perc_voice+15,temp2);
      While scankey(board_scancodes[temp2]) do
        begin
{$IFDEF GO32V2}
          realtime_gfx_poll_proc;
{$ELSE}
          _draw_screen_without_delay := TRUE;
          keyboard_poll_input;
{$ENDIF}
          keyboard_reset_buffer;
          draw_screen;
        end;
    end
  else Repeat
         valid_key := FALSE;
         For temp := 1 to 29 do
           begin
             temp2 := board_scancodes[temp];
             temp4 := scankey(temp2);

             If NOT ((songdata.flag_4op <> 0) and (test_ins2 <> 0)) then
               begin
                 temp3 := get_chanpos(chan_handle,channels,temp2);
                 temp5 := get_chanpos(chan_handle,channels,0);
               end
             else begin
                    temp3 := get_chanpos2(chan_handle,channels,temp2);
                    temp5 := get_chanpos2(chan_handle,channels,0);
                  end;

             If temp4 then valid_key := TRUE;
             If temp4 and (temp3 = 0) and (temp5 <> 0) then
               output_note(temp5,temp);

             If NOT temp4 and (temp3 <> 0) then
               begin
                 chan_handle[temp3] := 0;
                 key_off(temp3);
                 If alt_pressed then keyoff_loop[temp3] := TRUE;
               end;
           end;

{$IFDEF GO32V2}
         realtime_gfx_poll_proc;
{$ELSE}
         _draw_screen_without_delay := TRUE;
         keyboard_poll_input;
{$ENDIF}
         keyboard_reset_buffer;
         draw_screen;
       until NOT valid_key;

  While ctrl_pressed do
    begin
{$IFDEF GO32V2}
      realtime_gfx_poll_proc;
{$ELSE}
      _draw_screen_without_delay := TRUE;
      keyboard_poll_input;
{$ENDIF}
      keyboard_reset_buffer;
      draw_screen;
    end;

  For temp := 1 to 20 do key_off(temp);

  Move(ins__fmreg_table_backup,
       songdata.instr_macros[test_ins1],
       SizeOf(songdata.instr_macros[test_ins1]));
  Move(ins__dis_fmreg_col_backup,
       songdata.dis_fmreg_col[test_ins1],
       SizeOf(songdata.dis_fmreg_col[test_ins1]));

  If (test_ins2 <> 0) then
    begin
      Move(ins__fmreg_table_backup,
           songdata.instr_macros[test_ins1],
           SizeOf(songdata.instr_macros[test_ins1]));
      Move(ins__dis_fmreg_col_backup,
           songdata.dis_fmreg_col[test_ins1],
           SizeOf(songdata.dis_fmreg_col[test_ins1]));
      Move(ins__fmreg_table_backup2,
           songdata.instr_macros[test_ins2],
           SizeOf(songdata.instr_macros[test_ins2]));
      Move(ins__dis_fmreg_col_backup2,
           songdata.dis_fmreg_col[test_ins2],
           SizeOf(songdata.dis_fmreg_col[test_ins2]));
    end;

  Move(arp_vib_macro_table_backup,
       songdata.macro_table,
       SizeOf(songdata.macro_table));

  songdata.flag_4op := flag_4op_backup;
  Move(fmpar_table_backup,fmpar_table,SizeOf(fmpar_table));
  Move(volume_table_backup,volume_table,SizeOf(volume_table));
  Move(panning_table_backup,panning_table,SizeOf(panning_table));
  songdata.common_flag := common_flag_backup;
  volume_scaling := volume_scaling_backup;
  If (status_backup.play_status = isPlaying) then reset_player;

  Move(channel_flag_backup,channel_flag,SizeOf(channel_flag));
  Move(event_table_backup,event_table,SizeOf(event_table));
  Move(pan_lock_backup,pan_lock,SizeOf(pan_lock));
  Move(volume_lock_backup,volume_lock,SizeOf(volume_lock));
  Move(peak_lock_backup,peak_lock,SizeOf(volume_lock));

  really_no_status_refresh := FALSE;
  Move(freq_table_backup,freq_table,SizeOf(freq_table));
  Move(freqtable2_backup,freqtable2,SizeOf(freqtable2));
  Move(keyoff_loop_backup,keyoff_loop,SizeOf(keyoff_loop));
  FillChar(macro_table,SizeOf(macro_table),0);
  replay_forbidden := status_backup.replay_forbidden;
  play_status := status_backup.play_status;
  ins_trailing_flag := FALSE;
  keyboard_reset_buffer;
end;

procedure test_instrument_alt2(chan: Byte; fkey: Word);

var
  temp,temp2,temp3,temp5: Byte;
  valid_key,temp4: Boolean;
  temps: String;
  channels: Byte;

function output_note(chan,board_pos: Byte): Boolean;

var
  note: Byte;
  freq: Word;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:test_instrument_alt2:output_note';
{$ENDIF}
  note := board_pos+12*(current_octave-1);
  If NOT (note in [0..12*8+1]) then
    begin
      output_note := FALSE;
      EXIT;
    end;

  chan_handle[chan] := board_scancodes[board_pos];
  load_instrument(temp_instrument,chan);

  If percussion_mode and
     (temp_instrument.perc_voice in [4,5]) then
    load_instrument(temp_instrument,_perc_sim_chan[chan]);

  freq := nFreq(note-1)+$2000+
          SHORTINT(pBYTE(@Addr(temp_instrument)^)[12]);
  event_table[chan].note := note;
  freq_table[chan] := freq;
  freqtable2[chan] := freq;
  key_on(chan);
  change_freq(chan,freq);

  macro_speedup := songdata.macro_speedup;
  If (play_status = isStopped) then update_timer(songdata.tempo);

  freq_table[chan] := freq;
  freqtable2[chan] := freq;
  init_macro_table(chan,note,current_inst,freq);
end;

begin { test_instrument_alt2 }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:test_instrument_alt2';
{$ENDIF}
  valid_key := FALSE;
  For temp := 1 to 29 do
    If NOT shift_pressed then
      If (board_scancodes[temp] = HI(fkey)) then
        begin
          valid_key := TRUE;
          BREAK;
        end;

  If scankey(SC_F7) then
    For temp := 1 to 20 do reset_chan_data(temp);

  If NOT valid_key or
     NOT (temp+12*(current_octave-1)-1 in [0..12*8+1]) then EXIT;

  If NOT percussion_mode then channels := 18
  else channels := 15;

  temp2 := temp;
  temps := mn_environment.curr_item;
  load_flag_alt := BYTE_NULL;

  If Empty(temp_instrument,SizeOf(temp_instrument)) then EXIT;
{$IFDEF GO32V2}
  keyboard_toggle_sleep;
{$ENDIF}
  If (Lower(ExtOnly(temps)) = 'bnk') then
    bnk_file_loader_alt(Str2num(BaseNameOnly(mn_environment.curr_item),10))
  else If (Lower(ExtOnly(temps)) = 'fib') then
         fib_file_loader_alt(Str2num(BaseNameOnly(mn_environment.curr_item),10))
       else If (Lower(ExtOnly(temps)) = 'ibk') then
              ibk_file_loader_alt(Str2num(BaseNameOnly(mn_environment.curr_item),10));

{$IFDEF GO32V2}
  keyboard_toggle_sleep;
{$ENDIF}
  If (load_flag_alt = BYTE_NULL) then EXIT;

  ins_trailing_flag := TRUE;
  status_backup.replay_forbidden := replay_forbidden;
  status_backup.play_status := play_status;
  replay_forbidden := TRUE;
  If (play_status <> isStopped) then play_status := isPaused;
  nul_volume_bars;
  really_no_status_refresh := TRUE;
  reset_player;

  Move(channel_flag,channel_flag_backup,SizeOf(channel_flag_backup));
  Move(event_table,event_table_backup,SizeOf(event_table_backup));
  common_flag_backup := songdata.common_flag;
  volume_scaling_backup := volume_scaling;
  songdata.common_flag := songdata.common_flag AND NOT $80;
  volume_scaling := FALSE;
  FillChar(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
  flag_4op_backup := songdata.flag_4op;
  If NOT percussion_mode and
     NOT (songdata.flag_4op <> 0) then channels := 18
  else If NOT (songdata.flag_4op <> 0) then channels := 15
       else begin
              songdata.flag_4op := 0;
              If NOT percussion_mode then channels := 18
              else channels := 15;
            end;

  reset_player;
  FillChar(chan_handle,SizeOf(chan_handle),0);
  Move(pan_lock,pan_lock_backup,SizeOf(pan_lock));
  Move(volume_lock,volume_lock_backup,SizeOf(volume_lock));
  Move(peak_lock,peak_lock_backup,SizeOf(volume_lock));
  Move(panning_table,panning_table_backup,SizeOf(panning_table));
  FillChar(pan_lock,SizeOf(pan_lock),0);
  FillChar(volume_lock,SizeOf(volume_lock),0);
  FillChar(peak_lock,SizeOf(volume_lock),0);
  Move(fmpar_table,fmpar_table_backup,SizeOf(fmpar_table_backup));
  Move(volume_table,volume_table_backup,SizeOf(volume_table_backup));
  Move(freq_table,freq_table_backup,SizeOf(freq_table));
  Move(freqtable2,freqtable2_backup,SizeOf(freqtable2));
  Move(keyoff_loop,keyoff_loop_backup,SizeOf(keyoff_loop));
  FillChar(keyoff_loop,SizeOf(keyoff_loop),FALSE);

  misc_register := current_tremolo_depth SHL 7+
                   current_vibrato_depth SHL 6+
                   BYTE(percussion_mode) SHL 5;
  key_off(17);
  key_off(18);
  opl2out(_instr[11],misc_register);

  If percussion_mode and
     (temp_instrument.perc_voice in [1..5]) then
    begin
      output_note(temp_instrument.perc_voice+15,temp2);
      While scankey(board_scancodes[temp2]) do
        begin
{$IFDEF GO32V2}
          realtime_gfx_poll_proc;
{$ELSE}
          _draw_screen_without_delay := TRUE;
          keyboard_poll_input;
{$ENDIF}
          keyboard_reset_buffer;
          draw_screen;
        end;
    end
  else Repeat
         valid_key := FALSE;

         For temp := 1 to 29 do
           begin
             temp2 := board_scancodes[temp];
             temp3 := get_chanpos(chan_handle,channels,temp2);
             temp4 := scankey(temp2);
             temp5 := get_chanpos(chan_handle,channels,0);

             If temp4 then valid_key := TRUE;
             If temp4 and (temp3 = 0) and (temp5 <> 0) then
               output_note(temp5,temp);

             If NOT temp4 and (temp3 <> 0) then
               begin
                 chan_handle[temp3] := 0;
                 key_off(temp3);
                 If alt_pressed then keyoff_loop[temp3] := TRUE;
               end;
           end;
{$IFDEF GO32V2}
         realtime_gfx_poll_proc;
{$ELSE}
         _draw_screen_without_delay := TRUE;
         keyboard_poll_input;
{$ENDIF}
         keyboard_reset_buffer;
         draw_screen;
       until NOT valid_key;

  While ctrl_pressed do
    begin
{$IFDEF GO32V2}
      realtime_gfx_poll_proc;
{$ELSE}
      _draw_screen_without_delay := TRUE;
      keyboard_poll_input;
{$ENDIF}
      keyboard_reset_buffer;
      draw_screen;
    end;

  For temp := 1 to 20 do key_off(temp);
  songdata.flag_4op := flag_4op_backup;
  Move(fmpar_table_backup,fmpar_table,SizeOf(fmpar_table));
  Move(volume_table_backup,volume_table,SizeOf(volume_table));
  Move(panning_table_backup,panning_table,SizeOf(panning_table));
  songdata.common_flag := common_flag_backup;
  volume_scaling := volume_scaling_backup;
  If (status_backup.play_status = isPlaying) then reset_player;

  Move(channel_flag_backup,channel_flag,SizeOf(channel_flag));
  Move(event_table_backup,event_table,SizeOf(event_table));
  Move(pan_lock_backup,pan_lock,SizeOf(pan_lock));
  Move(volume_lock_backup,volume_lock,SizeOf(volume_lock));
  Move(peak_lock_backup,peak_lock,SizeOf(volume_lock));

  really_no_status_refresh := FALSE;
  Move(freq_table_backup,freq_table,SizeOf(freq_table));
  Move(freqtable2_backup,freqtable2,SizeOf(freqtable2));
  Move(keyoff_loop_backup,keyoff_loop,SizeOf(keyoff_loop));
  FillChar(macro_table,SizeOf(macro_table),0);
  replay_forbidden := status_backup.replay_forbidden;
  play_status := status_backup.play_status;
  ins_trailing_flag := FALSE;
  keyboard_reset_buffer;
end;

procedure fselect_external_proc;

var
  test_ins1: Byte;
  test_ins2: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ILOADINS.INC:fselect_external_proc';
{$ENDIF}
  If (songdata.flag_4op <> 0) then
    begin
      If (current_inst < 255) then
        test_ins1 := current_inst
      else test_ins1 := PRED(current_inst);
      test_ins2 := SUCC(test_ins1);
    end
  else
    begin
      test_ins1 := current_inst;
      test_ins2 := 0;
    end;
  If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
    test_instrument_alt(count_channel(pattern_hpos),
                        mn_environment.keystroke,
                        FALSE,FALSE,FALSE,
                        test_ins1,test_ins2);
end;
