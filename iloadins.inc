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
    procedure bnk_file_loader_alt(instr: Word);
    procedure fib_file_loader_alt(instr: Word);
    procedure import_sbi_instrument_alt(var data);
    procedure ibk_file_loader_alt(instr: Word);
    procedure test_instrument_alt(chan: Byte; fkey: Word);
    procedure test_instrument_alt2(chan: Byte; fkey: Word);
    procedure fselect_external_proc;
    procedure bnk_lister_external_proc;
    procedure fib_lister_external_proc;
    procedure ibk_lister_external_proc;
}
type
  tByteSet = Set of Byte;

var
  buf1,
  buf2,buf3: array[0..PRED(65535)] of Byte;

procedure import_standard_instrument_alt(var data);
begin
  With temp_instrument do
    begin
      fm_data.AM_VIB_EG_modulator := tDUMMY_BUFF(data)[0];
      fm_data.AM_VIB_EG_carrier   := tDUMMY_BUFF(data)[1];
      fm_data.KSL_VOLUM_modulator := tDUMMY_BUFF(data)[2];
      fm_data.KSL_VOLUM_carrier   := tDUMMY_BUFF(data)[3];
      fm_data.ATTCK_DEC_modulator := tDUMMY_BUFF(data)[4];
      fm_data.ATTCK_DEC_carrier   := tDUMMY_BUFF(data)[5];
      fm_data.SUSTN_REL_modulator := tDUMMY_BUFF(data)[6];
      fm_data.SUSTN_REL_carrier   := tDUMMY_BUFF(data)[7];
      fm_data.WAVEFORM_modulator  := tDUMMY_BUFF(data)[8]  AND 3;
      fm_data.WAVEFORM_carrier    := tDUMMY_BUFF(data)[9]  AND 3;
      fm_data.FEEDBACK_FM         := tDUMMY_BUFF(data)[10] AND $0f;
    end;

  temp_instrument.panning := 0;
  temp_instrument.fine_tune := 0;
end;

procedure import_fin_instrument_alt(var data);
begin
  With temp_instrument do
    begin
      fm_data.AM_VIB_EG_modulator := tDUMMY_BUFF(data)[0];
      fm_data.AM_VIB_EG_carrier   := tDUMMY_BUFF(data)[1];
      fm_data.KSL_VOLUM_modulator := tDUMMY_BUFF(data)[2];
      fm_data.KSL_VOLUM_carrier   := tDUMMY_BUFF(data)[3];
      fm_data.ATTCK_DEC_modulator := tDUMMY_BUFF(data)[4];
      fm_data.ATTCK_DEC_carrier   := tDUMMY_BUFF(data)[5];
      fm_data.SUSTN_REL_modulator := tDUMMY_BUFF(data)[6];
      fm_data.SUSTN_REL_carrier   := tDUMMY_BUFF(data)[7];
      fm_data.WAVEFORM_modulator  := tDUMMY_BUFF(data)[8]  AND 7;
      fm_data.WAVEFORM_carrier    := tDUMMY_BUFF(data)[9]  AND 7;
      fm_data.FEEDBACK_FM         := tDUMMY_BUFF(data)[10] AND $0f;
    end;

  temp_instrument.panning := 0;
  temp_instrument.fine_tune := 0;
end;

procedure import_hsc_instrument_alt(var data);
begin
  With temp_instrument do
    begin
      fm_data.AM_VIB_EG_carrier   := tDUMMY_BUFF(data)[0];
      fm_data.AM_VIB_EG_modulator := tDUMMY_BUFF(data)[1];
      fm_data.KSL_VOLUM_carrier   := tDUMMY_BUFF(data)[2];
      fm_data.KSL_VOLUM_modulator := tDUMMY_BUFF(data)[3];
      fm_data.ATTCK_DEC_carrier   := tDUMMY_BUFF(data)[4];
      fm_data.ATTCK_DEC_modulator := tDUMMY_BUFF(data)[5];
      fm_data.SUSTN_REL_carrier   := tDUMMY_BUFF(data)[6];
      fm_data.SUSTN_REL_modulator := tDUMMY_BUFF(data)[7];
      fm_data.FEEDBACK_FM         := tDUMMY_BUFF(data)[8]  AND $0f;
      fm_data.WAVEFORM_carrier    := tDUMMY_BUFF(data)[9]  AND 3;
      fm_data.WAVEFORM_modulator  := tDUMMY_BUFF(data)[10] AND 3;
    end;

  temp_instrument.panning := 0;
  temp_instrument.fine_tune := tDUMMY_BUFF(data)[11] SHR 4;
end;

procedure import_sat_instrument_alt(var data);
begin
  With temp_instrument do
    begin
      fm_data.FEEDBACK_FM         := tDUMMY_BUFF(data)[0] AND $0f;
      fm_data.AM_VIB_EG_modulator := tDUMMY_BUFF(data)[1];
      fm_data.AM_VIB_EG_carrier   := tDUMMY_BUFF(data)[2];
      fm_data.ATTCK_DEC_modulator := tDUMMY_BUFF(data)[3];
      fm_data.ATTCK_DEC_carrier   := tDUMMY_BUFF(data)[4];
      fm_data.SUSTN_REL_modulator := tDUMMY_BUFF(data)[5];
      fm_data.SUSTN_REL_carrier   := tDUMMY_BUFF(data)[6];
      fm_data.WAVEFORM_modulator  := tDUMMY_BUFF(data)[7] AND 3;
      fm_data.WAVEFORM_carrier    := tDUMMY_BUFF(data)[8] AND 3;
      fm_data.KSL_VOLUM_modulator := tDUMMY_BUFF(data)[9];
      fm_data.KSL_VOLUM_carrier   := tDUMMY_BUFF(data)[10];
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
  temp: Longint;
  crc: Word;

begin
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

  If NOT (header.ffver in [1..9]) then
    begin
      CloseF(f);
      EXIT;
    end;

  If (header.ffver in [1..4]) then
    begin
      BlockReadF(f,buf1,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := WORD(NOT 0);
      crc := Update16(header.b0len,1,crc);
      crc := Update16(buf1,header.b0len,crc);

      If (crc <> header.crc16) then
        begin
          CloseF(f);
          EXIT;
        end;

      Case header.ffver of
        4: Move(buf1,buf2,header.b0len);
        3: LZSS_decompress(buf1,buf2,header.b0len);
        2: LZW_decompress(buf1,buf2);
        1: SIXPACK_decompress(buf1,buf2,header.b0len);
      end;

      Move(buf2,temp_instrument,SizeOf(temp_instrument));
      temp_instrument.panning := 0;
    end;

  If (header.ffver in [5..8]) then
    begin
      BlockReadF(f,buf1,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := WORD(NOT 0);
      crc := Update16(header.b0len,1,crc);
      crc := Update16(buf1,header.b0len,crc);

      If (crc <> header.crc16) then
        begin
          CloseF(f);
          EXIT;
        end;

      Case header.ffver of
        8: Move(buf1,buf2,header.b0len);
        7: LZSS_decompress(buf1,buf2,header.b0len);
        6: LZW_decompress(buf1,buf2);
        5: SIXPACK_decompress(buf1,buf2,header.b0len);
      end;

      Move(buf2,temp_instrument,SizeOf(temp_instrument));
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

      BlockReadF(f,buf1,header2.b0len,temp);
      If NOT (temp = header2.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := WORD(NOT 0);
      crc := Update16(header2.b0len,1,crc);
      crc := Update16(buf1,header2.b0len,crc);

      If (crc <> header2.crc16) then
        begin
          CloseF(f);
          EXIT;
        end;

      APACK_decompress(buf1,buf2);
      Move(buf2,temp_instrument,SizeOf(temp_instrument));
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
  crc,temp: Longint;

begin
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

  If NOT (header.ffver in [1]) then
    begin
      CloseF(f);
      EXIT;
    end;

  If (header.ffver = 1) then
    begin
      BlockReadF(f,buf1,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          EXIT;
        end;

      crc := NOT 0;
      crc := Update32(header.b0len,1,crc);
      crc := Update32(buf1,header.b0len,crc);

      If (crc <> header.crc32) then
        begin
          CloseF(f);
          EXIT;
        end;

      APACK_decompress(buf1,buf2);
      Move(buf2,temp_instrument,SizeOf(temp_instrument));
      Move(buf2[SizeOf(songdata.instr_data[current_inst])+
                buf2[SizeOf(songdata.instr_data[current_inst])]+1],
           temp_instrument_macro,
           SizeOf(temp_instrument_macro));

      Move(buf2[SizeOf(songdata.instr_data[current_inst])+
                buf2[SizeOf(songdata.instr_data[current_inst])]+1+
                SizeOf(songdata.instr_macros[current_inst])],
           temp_instrument_dis_fmreg_col,
           SizeOf(temp_instrument_dis_fmreg_col));
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
  {temp_str: String;}

begin
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
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  With temp_instrument do
    begin
      fm_data.ATTCK_DEC_modulator := (tDUMMY_BUFF(data)[1]  AND $0f)+
                                     (tDUMMY_BUFF(data)[0]  AND $0f) SHL 4;
      fm_data.SUSTN_REL_modulator := (tDUMMY_BUFF(data)[3]  AND $0f)+
                                     (tDUMMY_BUFF(data)[2]  AND $0f) SHL 4;
      fm_data.WAVEFORM_modulator  := (tDUMMY_BUFF(data)[4]  AND 3);
      fm_data.KSL_VOLUM_modulator := (tDUMMY_BUFF(data)[7]  AND $3f)+
                                     (tDUMMY_BUFF(data)[6]  AND 3) SHL 6;
      fm_data.AM_VIB_EG_modulator := (tDUMMY_BUFF(data)[5]  AND $0f)+
                                     (tDUMMY_BUFF(data)[8]  AND 1) SHL 4+
                                     (tDUMMY_BUFF(data)[11] AND 1) SHL 5+
                                     (tDUMMY_BUFF(data)[10] AND 1) SHL 6+
                                     (tDUMMY_BUFF(data)[9]  AND 1) SHL 7;
      fm_data.ATTCK_DEC_carrier   := (tDUMMY_BUFF(data)[13] AND $0f)+
                                     (tDUMMY_BUFF(data)[12] AND $0f) SHL 4;
      fm_data.SUSTN_REL_carrier   := (tDUMMY_BUFF(data)[15] AND $0f)+
                                     (tDUMMY_BUFF(data)[14] AND $0f) SHL 4;
      fm_data.WAVEFORM_carrier    := (tDUMMY_BUFF(data)[16] AND 3);
      fm_data.KSL_VOLUM_carrier   := (tDUMMY_BUFF(data)[19] AND $3f)+
                                     (tDUMMY_BUFF(data)[18] AND 3) SHL 6;
      fm_data.AM_VIB_EG_carrier   := (tDUMMY_BUFF(data)[17] AND $0f)+
                                     (tDUMMY_BUFF(data)[20] AND 1) SHL 4+
                                     (tDUMMY_BUFF(data)[23] AND 1) SHL 5+
                                     (tDUMMY_BUFF(data)[22] AND 1) SHL 6+
                                     (tDUMMY_BUFF(data)[21] AND 1) SHL 7;
      fm_data.FEEDBACK_FM         := (tDUMMY_BUFF(data)[25] AND 1)+
                                     (tDUMMY_BUFF(data)[24] AND 7) SHL 1;
    end;
end;

begin { sgi_file_loader_alt }
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

type
  tBNK_HEADER = Record
                  fver_major    : Byte;
                  fver_minor    : Byte;
                  signature     : array[1..6] of Char;
                  entries_used  : Word;
                  total_entries : Word;
                  name_offset   : Longint;
                  data_offset   : Longint;
                  filler        : array[1..8] of Byte;
                end;
type
  tBNK_NAME_RECORD = Record
                       data_index : Word;
                       usage_flag : Boolean;
                       ins_name   : array[1..9] of Char;
                     end;
type
  tBNK_OPERATOR = Record
                    ksl,
                    freq_mult,
                    feedback,
                    attack,
                    sust_level,
                    sustain,
                    decay,
                    release,
                    output,
                    am,
                    vib,
                    ksr,
                    fm: Byte;
                  end;
type
  tBNK_DATA_RECORD = Record
                       mode      : Byte;
                       voice_num : Byte;
                       modulator : tBNK_OPERATOR;
                       carrier   : tBNK_OPERATOR;
                       wform_mod : Byte;
                       wform_car : Byte;
                     end;
const
  bnk_id = 'ADLIB-';
  MAX_TIMBRES = 4096;

var
  bnk_queue: array[1..MAX_TIMBRES+3] of String[72];
  bnk_skip: Byte;
  name_record: tBNK_NAME_RECORD;
  data_record: tBNK_DATA_RECORD;

procedure import_instrument_from_data_record;
begin
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  With temp_instrument.fm_data do
    begin
      AM_VIB_EG_modulator :=
        data_record.modulator.freq_mult AND $0f+
        data_record.modulator.ksr       AND 1 SHL 4+
        data_record.modulator.sustain   AND 1 SHL 5+
        data_record.modulator.vib       AND 1 SHL 6+
        data_record.modulator.am        AND 1 SHL 7;

      AM_VIB_EG_carrier :=
        data_record.carrier.freq_mult AND $0f+
        data_record.carrier.ksr       AND 1 SHL 4+
        data_record.carrier.sustain   AND 1 SHL 5+
        data_record.carrier.vib       AND 1 SHL 6+
        data_record.carrier.am        AND 1 SHL 7;

      KSL_VOLUM_modulator :=
        data_record.modulator.output AND $3f+
        data_record.modulator.ksl    AND 3 SHL 6;

      KSL_VOLUM_carrier :=
        data_record.carrier.output AND $3f+
        data_record.carrier.ksl    AND 3 SHL 6;

      ATTCK_DEC_modulator :=
        data_record.modulator.decay  AND $0f+
        data_record.modulator.attack AND $0f SHL 4;

      ATTCK_DEC_carrier :=
        data_record.carrier.decay  AND $0f+
        data_record.carrier.attack AND $0f SHL 4;

      SUSTN_REL_modulator :=
        data_record.modulator.release    AND $0f+
        data_record.modulator.sust_level AND $0f SHL 4;

      SUSTN_REL_carrier :=
        data_record.carrier.release    AND $0f+
        data_record.carrier.sust_level AND $0f SHL 4;

      WAVEFORM_modulator :=
        data_record.wform_mod AND 7;

      WAVEFORM_carrier :=
        data_record.wform_car AND 7;

      FEEDBACK_FM :=
        data_record.modulator.fm XOR 1 AND 1+
        data_record.modulator.feedback AND 7 SHL 1;
    end;

  If (data_record.voice_num in [6..10]) then
    temp_instrument.perc_voice := data_record.voice_num-5;
end;

procedure bnk_file_loader_alt(instr: Word);

var
  f: File;
  header: tBNK_HEADER;
  temp: Longint;

begin
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
  If (temp <> SizeOf(header)) then
    begin
      CloseF(f);
      EXIT;
    end;

  If NOT ((header.fver_major = 1) and (header.fver_minor = 0)) then
    begin
      CloseF(f);
      EXIT;
    end;

  If (instr > max(header.total_entries,MAX_TIMBRES)) or
     (header.signature <> bnk_id) or
     (header.total_entries < header.entries_used) then
    begin
      CloseF(f);
      EXIT;
    end;

  SeekF(f,header.name_offset+PRED(instr)*SizeOf(name_record));
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,name_record,SizeOf(name_record),temp);
  If (temp <> SizeOf(name_record)) then
    begin
      CloseF(f);
      EXIT;
    end;

  SeekF(f,header.data_offset+name_record.data_index*SizeOf(data_record));
  If (IOresult <> 0) then
    begin
      CloseF(f);
      EXIT;
    end;

  BlockReadF(f,data_record,SizeOf(data_record),temp);
  If (temp <> SizeOf(data_record)) then
    begin
      CloseF(f);
      EXIT;
    end;

  import_instrument_from_data_record;
  CloseF(f);
  load_flag_alt := 1;
end;

type
  tFIB_HEADER = Record
                  ident: array[1..4] of Char;
                  nmins: Word;
                end;

procedure fib_file_loader_alt(instr: Word);

const
  id = 'FIB'+#$f4;

var
  f: File;
  ident: array[1..4] of Char;
  header: tFIB_HEADER;
  temp: Longint;
  instrument_data: tFIN_DATA;

begin
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
     (header.ident <> id) then
    begin
      CloseF(f);
      EXIT;
    end;

  SeekF(f,SizeOf(header)+header.nmins*SizeOf(instrument_data));
  If (IOresult <> 0) then EXIT;

  BlockReadF(f,ident,SizeOf(ident),temp);
  If (temp <> SizeOf(ident)) or
     (ident <> id) then
    begin
      CloseF(f);
      EXIT;
    end;

  SeekF(f,SizeOf(header)+PRED(instr)*SizeOf(instrument_data));
  If (IOresult <> 0) then EXIT;

  BlockReadF(f,instrument_data,SizeOf(instrument_data),temp);
  If (temp <> SizeOf(instrument_data)) then
    begin
      CloseF(f);
      EXIT;
    end;

  import_standard_instrument_alt(instrument_data.idata);
  CloseF(f);
  load_flag_alt := 1;
end;

var
  ibk_queue: array[1..128+3] of String[45];
  ibk_skip: Byte;

procedure import_sbi_instrument_alt(var data);
begin
  FillChar(temp_instrument,SizeOf(temp_instrument),0);
  With temp_instrument do
    begin
      fm_data.AM_VIB_EG_modulator := tDUMMY_BUFF(data)[0];
      fm_data.AM_VIB_EG_carrier   := tDUMMY_BUFF(data)[1];
      fm_data.KSL_VOLUM_modulator := tDUMMY_BUFF(data)[2];
      fm_data.KSL_VOLUM_carrier   := tDUMMY_BUFF(data)[3];
      fm_data.ATTCK_DEC_modulator := tDUMMY_BUFF(data)[4];
      fm_data.ATTCK_DEC_carrier   := tDUMMY_BUFF(data)[5];
      fm_data.SUSTN_REL_modulator := tDUMMY_BUFF(data)[6];
      fm_data.SUSTN_REL_carrier   := tDUMMY_BUFF(data)[7];
      fm_data.WAVEFORM_modulator  := tDUMMY_BUFF(data)[8]  AND 3;
      fm_data.WAVEFORM_carrier    := tDUMMY_BUFF(data)[9]  AND 3;
      fm_data.FEEDBACK_FM         := tDUMMY_BUFF(data)[10] AND $0f;
    end;

  temp_instrument.panning := 0;
  temp_instrument.fine_tune := 0;
end;

procedure ibk_file_loader_alt(instr: Word);

const
  id = 'IBK'+#$1a;

var
  f: File;
  header: array[1..4] of Char;
  temp: Longint;
  instrument_data: Record
                     idata: tFM_INST_DATA;
                     dummy: array[1..5] of Byte;
                   end;

begin
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
  ins__dis_fmreg_col_backup: tDIS_FMREG_COL;
  chan_handle: array[1..18] of Byte;

procedure test_instrument_alt(chan: Byte; fkey: Word);

const
  _perc_sim_chan: array[19..20] of Byte = (18,17);

var
  temp,temp2,temp3,temp5: Byte;
  {freq: Word;}
  valid_key,temp4: Boolean;
  temps: String;
  channels: Byte;

function output_note(chan,board_pos: Byte): Boolean;

var
  note: Byte;
  freq: Word;

begin
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
          SHORTINT(tDUMMY_BUFF(addr(temp_instrument)^)[12]);

  event_table[chan].note := note;
  opl3out($0b0+_chan_n[chan],0);
  opl3out($0a0+_chan_n[chan],LO(freq));
  opl3out($0b0+_chan_n[chan],HI(freq));

  macro_speedup := songdata.macro_speedup;
  If (play_status = isStopped) then update_timer(songdata.tempo);

  freq_table[chan] := freq;
  freqtable2[chan] := freq;
  init_macro_table(chan,note,current_inst,freq);
end;

function chanpos(var data; channels,scancode: Byte): Byte; assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        xor     ebx,ebx
@@1:    mov     edi,[data]
        add     edi,ebx
        xor     ecx,ecx
        mov     cl,channels
        mov     al,scancode
        sub     ecx,ebx
        jecxz   @@2
        repnz   scasb
        jnz     @@2
        xor     eax,eax
        mov     al,channels
        sub     eax,ecx
        jmp     @@3
@@2:    xor     eax,eax
        jmp     @@5
@@3:    pusha
        push    eax
        call    is_4op_chan
        or      al,al
        jz      @@4
        popa
        inc     ebx
        jmp     @@1
@@4:    popa
@@5:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

begin { test_instrument_alt }
  valid_key := FALSE;
  For temp := 1 to 29 do
    If NOT shift_pressed then
      If (board_scancodes[temp] = HI(fkey)) then
        begin valid_key := TRUE; BREAK; end;

  If NOT valid_key or
     NOT (temp+12*(current_octave-1)-1 in [0..12*8+1]) then EXIT;

  If NOT percussion_mode then channels := 18
  else channels := 15;

  temp2 := temp;
  temp := Pos(' ',mn_environment.curr_item);
  temps := mn_environment.curr_item;
  While (temps[temp] = ' ') do Delete(temps,temp,1);
  Insert('.',temps,temp);
  load_flag_alt := NULL;

  keyboard_toggle_sleep;
  If (ExtOnly(temps) = 'a2i') then
    a2i_file_loader_alt(temps)
  else If (ExtOnly(temps) = 'a2f') then
         a2f_file_loader_alt(temps)
       else If (ExtOnly(temps) = 'cif') then
              cif_file_loader_alt(temps)
            else If (ExtOnly(temps) = 'fin') then
                   fin_file_loader_alt(temps)
                 else If (ExtOnly(temps) = 'ins') then
                        ins_file_loader_alt(temps)
                       else If (ExtOnly(temps) = 'sbi') then
                              sbi_file_loader_alt(temps)
                             else If (ExtOnly(temps) = 'sgi') then
                                    sgi_file_loader_alt(temps);

  keyboard_toggle_sleep;
  If (load_flag_alt = NULL) then EXIT;

  status_backup.replay_forbidden := replay_forbidden;
  status_backup.play_status := play_status;
  replay_forbidden := TRUE;
  If (play_status <> isStopped) then play_status := isPaused;
  nul_volume_bars;
  really_no_status_refresh := TRUE;
  reset_player;

  If (ExtOnly(temps) = 'a2f') then
    begin
      Move(songdata.instr_macros[current_inst],
           ins__fmreg_table_backup,
           SizeOf(ins__fmreg_table_backup));
      Move(songdata.dis_fmreg_col[current_inst],
           ins__dis_fmreg_col_backup,
           SizeOf(ins__dis_fmreg_col_backup));

      Move(temp_instrument_macro,
           songdata.instr_macros[current_inst],
           SizeOf(songdata.instr_macros[current_inst]));
      Move(temp_instrument_dis_fmreg_col,
           songdata.dis_fmreg_col[current_inst],
           SizeOf(songdata.dis_fmreg_col[current_inst]));
    end;

  Move(channel_flag,channel_flag_backup,SizeOf(channel_flag_backup));
  Move(event_table,event_table_backup,SizeOf(event_table_backup));
  common_flag_backup := songdata.common_flag;
  volume_scaling_backup := volume_scaling;
  songdata.common_flag := songdata.common_flag AND NOT $80;
  volume_scaling := FALSE;
  FillData(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
  Move(pan_lock,pan_lock_backup,SizeOf(pan_lock));
  Move(volume_lock,volume_lock_backup,SizeOf(volume_lock));
  Move(peak_lock,peak_lock_backup,SizeOf(volume_lock));
  Move(panning_table,panning_table_backup,SizeOf(panning_table));
  FillChar(pan_lock,SizeOf(pan_lock),0);
  FillChar(volume_lock,SizeOf(volume_lock),0);
  FillChar(peak_lock,SizeOf(volume_lock),0);
  flag_4op_backup := songdata.flag_4op;
  If NOT percussion_mode and
     NOT is_4op_mode then channels := 18
  else If NOT is_4op_mode then channels := 15
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
  opl3out(_instr[11],misc_register);

  If percussion_mode and
     (temp_instrument.perc_voice in [1..5]) then
    begin
      output_note(temp_instrument.perc_voice+15,temp2);
      While scankey(board_scancodes[temp2]) do
        begin
          keyboard_poll_input;
          emulate_screen;
        end;
    end
  else Repeat
         valid_key := FALSE;

         For temp := 1 to 29 do
           begin
             temp2 := board_scancodes[temp];
             temp3 := chanpos(chan_handle,channels,temp2);
             temp4 := scankey(temp2);
             temp5 := chanpos(chan_handle,channels,0);

             If temp4 then valid_key := TRUE;
             If temp4 and (temp3 = 0) and (temp5 <> 0) then
               output_note(temp5,temp);

             If NOT temp4 and (temp3 <> 0) then
               If NOT ctrl_pressed then
                 begin
                   reset_chan_data(temp3);
                   chan_handle[temp3] := 0;
                 end
               else begin
                      key_off(temp3);
                      If alt_pressed then keyoff_loop[temp3] := TRUE;
                    end;
           end;
         keyboard_poll_input;
         emulate_screen;
       until NOT valid_key;

  While ctrl_pressed do
    begin
      keyboard_poll_input;
      emulate_screen;
    end;

  If (ExtOnly(temps) = 'a2f') then
    begin
      Move(ins__fmreg_table_backup,
           songdata.instr_macros[current_inst],
           SizeOf(songdata.instr_macros[current_inst]));
      Move(ins__dis_fmreg_col_backup,
           songdata.dis_fmreg_col[current_inst],
           SizeOf(songdata.dis_fmreg_col[current_inst]));
    end;

  songdata.flag_4op := flag_4op_backup;
  Move(fmpar_table_backup,fmpar_table,SizeOf(fmpar_table));
  Move(volume_table_backup,volume_table,SizeOf(volume_table));
  Move(panning_table_backup,panning_table,SizeOf(panning_table));
  songdata.common_flag := common_flag_backup;
  volume_scaling := volume_scaling_backup;
  reset_player;

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
end;

procedure test_instrument_alt2(chan: Byte; fkey: Word);

const
  _perc_sim_chan: array[19..20] of Byte = (18,17);

var
  temp,temp2,temp3,temp5: Byte;
  {freq: Word;}
  valid_key,temp4: Boolean;
  temps: String;
  channels: Byte;

function output_note(chan,board_pos: Byte): Boolean;

var
  note: Byte;
  freq: Word;

begin
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
          SHORTINT(tDUMMY_BUFF(addr(temp_instrument)^)[12]);

  event_table[chan].note := note;
  opl3out($0b0+_chan_n[chan],0);
  opl3out($0a0+_chan_n[chan],LO(freq));
  opl3out($0b0+_chan_n[chan],HI(freq));

  macro_speedup := songdata.macro_speedup;
  If (play_status = isStopped) then update_timer(songdata.tempo);

  freq_table[chan] := freq;
  freqtable2[chan] := freq;
  init_macro_table(chan,note,current_inst,freq);
end;

function chanpos(var data; channels,scancode: Byte): Byte; assembler;
asm
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi
        xor     ebx,ebx
@@1:    mov     edi,[data]
        add     edi,ebx
        xor     ecx,ecx
        mov     cl,channels
        mov     al,scancode
        sub     ecx,ebx
        jecxz   @@2
        repnz   scasb
        jnz     @@2
        xor     eax,eax
        mov     al,channels
        sub     eax,ecx
        jmp     @@3
@@2:    xor     eax,eax
        jmp     @@5
@@3:    pusha
        push    eax
        call    is_4op_chan
        or      al,al
        jz      @@4
        popa
        inc     ebx
        jmp     @@1
@@4:    popa
@@5:
        pop     edi
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
end;

begin { test_instrument_alt2 }
  valid_key := FALSE;
  For temp := 1 to 29 do
    If NOT shift_pressed then
      If (board_scancodes[temp] = HI(fkey)) then
        begin valid_key := TRUE; BREAK; end;

  If NOT valid_key or
     NOT (temp+12*(current_octave-1)-1 in [0..12*8+1]) then EXIT;

  If NOT percussion_mode then channels := 18
  else channels := 15;

  temp2 := temp;
  temp := Pos(' ',mn_environment.curr_item);
  temps := mn_environment.curr_item;
  While (temps[temp] = ' ') do Delete(temps,temp,1);
  Insert('.',temps,temp);
  load_flag_alt := NULL;

  keyboard_toggle_sleep;
  If (ExtOnly(temps) = 'bnk') then
    bnk_file_loader_alt(Str2num(BaseNameOnly(mn_environment.curr_item),10))
  else If (ExtOnly(temps) = 'fib') then
         fib_file_loader_alt(Str2num(BaseNameOnly(mn_environment.curr_item),10))
       else If (ExtOnly(temps) = 'ibk') then
              ibk_file_loader_alt(Str2num(BaseNameOnly(mn_environment.curr_item),10));

  keyboard_toggle_sleep;
  If (load_flag_alt = NULL) then EXIT;

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
  FillData(channel_flag,SizeOf(channel_flag),BYTE(TRUE));
  flag_4op_backup := songdata.flag_4op;
  If NOT percussion_mode and
     NOT is_4op_mode then channels := 18
  else If NOT is_4op_mode then channels := 15
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
  opl3out(_instr[11],misc_register);

  If percussion_mode and
     (temp_instrument.perc_voice in [1..5]) then
    begin
      output_note(temp_instrument.perc_voice+15,temp2);
      While scankey(board_scancodes[temp2]) do
        begin
          keyboard_poll_input;
          emulate_screen;
        end;
    end
  else Repeat
         valid_key := FALSE;

         For temp := 1 to 29 do
           begin
             temp2 := board_scancodes[temp];
             temp3 := chanpos(chan_handle,channels,temp2);
             temp4 := scankey(temp2);
             temp5 := chanpos(chan_handle,channels,0);

             If temp4 then valid_key := TRUE;
             If temp4 and (temp3 = 0) and (temp5 <> 0) then
               output_note(temp5,temp);

             If NOT temp4 and (temp3 <> 0) then
               If NOT ctrl_pressed then
                 begin
                   reset_chan_data(temp3);
                   chan_handle[temp3] := 0;
                 end
               else begin
                      key_off(temp3);
                      If alt_pressed then keyoff_loop[temp3] := TRUE;
                    end;
           end;
         keyboard_poll_input;
         emulate_screen;
       until NOT valid_key;

  While ctrl_pressed do
    begin
      keyboard_poll_input;
      emulate_screen;
    end;

  songdata.flag_4op := flag_4op_backup;
  Move(fmpar_table_backup,fmpar_table,SizeOf(fmpar_table));
  Move(volume_table_backup,volume_table,SizeOf(volume_table));
  Move(panning_table_backup,panning_table,SizeOf(panning_table));
  songdata.common_flag := common_flag_backup;
  volume_scaling := volume_scaling_backup;
  reset_player;

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
end;

procedure fselect_external_proc;

{var
  ins1,ins2: Byte;
  temp_inst: Record
               name: String[32];
               data: tADTRACK2_INS;
             end;}
begin
  If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
    test_instrument_alt(count_channel(pattern_hpos),
                        mn_environment.keystroke);
end;

procedure bnk_lister_external_proc;
begin
  mn_environment.curr_item :=
    Num2str(mn_environment.curr_pos+bnk_skip,10)+'.bnk';
  If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
    test_instrument_alt2(count_channel(pattern_hpos),
                         mn_environment.keystroke);
end;

procedure fib_lister_external_proc;
begin
  mn_environment.curr_item :=
    Num2str(mn_environment.curr_pos+bnk_skip,10)+'.fib';
  If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
    test_instrument_alt2(count_channel(pattern_hpos),
                         mn_environment.keystroke);
end;

procedure ibk_lister_external_proc;
begin
  mn_environment.curr_item :=
    Num2str(mn_environment.curr_pos+ibk_skip,10)+'.ibk';
  If NOT shift_pressed and NOT alt_pressed and NOT ctrl_pressed then
    test_instrument_alt2(count_channel(pattern_hpos),
                         mn_environment.keystroke);
end;
