unit AdT2ext3;
{$IFNDEF __TMT__}
{$PACKRECORDS 1}
{$ENDIF}
interface

procedure a2m_file_loader;
procedure a2t_file_loader;
procedure a2p_file_loader;
procedure a2i_file_loader;
procedure a2f_file_loader;
procedure amd_file_loader;
procedure cff_file_loader;
procedure dfm_file_loader;
procedure fmk_file_loader;
procedure hsc_file_loader;
procedure mtk_file_loader;
procedure rad_file_loader;
procedure s3m_file_loader;
procedure sat_file_loader;
procedure sa2_file_loader;
procedure cif_file_loader;
procedure fin_file_loader;
procedure ins_file_loader;
procedure sbi_file_loader;
procedure sgi_file_loader;
procedure fselect_external_proc;
procedure import_standard_instrument_alt(var data);
procedure test_instrument_alt(chan: Byte; fkey: Word; loadMacros: Boolean; bankSelector: Boolean; loadArpVib: Boolean);
procedure test_instrument_alt2(chan: Byte; fkey: Word);

implementation

uses
{$IFDEF __TMT__}
  DOS,DPMI,
{$ELSE}
  DOS,
{$ENDIF}
  AdT2opl3,AdT2sys,AdT2keyb,AdT2unit,AdT2extn,AdT2ext2,AdT2ext4,AdT2ext5,AdT2text,AdT2apak,
  StringIO,DialogIO,ParserIO,DepackIO,TxtScrIO;

{$i iloadins.inc}
{$i iloaders.inc}

procedure a2i_file_loader;

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
  temp_str: String;

begin
{$IFDEF __TMT__}
    _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:a2i_file_loader';
{$ENDIF}
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - DiSK ERROR?$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2i LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,header,SizeOf(header),temp);
  If NOT ((temp = SizeOf(header)) and (header.ident = id)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2i LOADER ',1);
      EXIT;
    end;

  If NOT (header.ffver in [1..9]) then
    begin
      CloseF(f);
      Dialog('UNKNOWN FiLE FORMAT VERSiON$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2i LOADER ',1);
      EXIT;
    end;

  init_old_songdata;
  If (header.ffver in [1..4]) then
    begin
      BlockReadF(f,buf2,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2i LOADER ',1);
          EXIT;
        end;

      crc := WORD_NULL;
      crc := Update16(header.b0len,1,crc);
      crc := Update16(buf2,header.b0len,crc);

      If (crc <> header.crc16) then
        begin
          CloseF(f);
          Dialog('CRC FAiLED - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2i LOADER ',1);
          EXIT;
        end;

      Case header.ffver of
        4: Move(buf2,buf3,header.b0len);
        3: LZSS_decompress(buf2,buf3,header.b0len);
        2: LZW_decompress(buf2,buf3);
        1: SIXPACK_decompress(buf2,buf3,header.b0len);
      end;

      Move(buf3,
           old_songdata.instr_data[1],
           SizeOf(old_songdata.instr_data[1]));
      Move(buf3[SizeOf(old_songdata.instr_data[1])],
           temp_str,
           buf3[SizeOf(old_songdata.instr_data[1])]+1);

      old_songdata.instr_data[1].panning := 0;
      If (temp_str = '') then temp_str := Lower(NameOnly(instdata_source));
      old_songdata.instr_names[1] :=
        Copy(old_songdata.instr_names[1],1,9)+truncate_string(temp_str);
      import_single_old_instrument(Addr(old_songdata),current_inst,1);
    end;

  If (header.ffver in [5..8]) then
    begin
      BlockReadF(f,buf2,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2i LOADER ',1);
          EXIT;
        end;

      crc := WORD_NULL;
      crc := Update16(header.b0len,1,crc);
      crc := Update16(buf2,header.b0len,crc);

      If (crc <> header.crc16) then
        begin
          CloseF(f);
          Dialog('CRC FAiLED - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2i LOADER ',1);
          EXIT;
        end;

      Case header.ffver of
        8: Move(buf2,buf3,header.b0len);
        7: LZSS_decompress(buf2,buf3,header.b0len);
        6: LZW_decompress(buf2,buf3);
        5: SIXPACK_decompress(buf2,buf3,header.b0len);
      end;

      Move(buf3,
           old_songdata.instr_data[1],
           SizeOf(old_songdata.instr_data[1]));
      Move(buf3[SizeOf(old_songdata.instr_data[1])],
           temp_str,
           buf3[SizeOf(old_songdata.instr_data[1])]+1);

      If (temp_str = '') then temp_str := Lower(NameOnly(instdata_source));
      old_songdata.instr_names[1] :=
        Copy(old_songdata.instr_names[1],1,9)+truncate_string(temp_str);
      import_single_old_instrument(Addr(old_songdata),current_inst,1);
    end;

  If (header.ffver = 9) then
    begin
      ResetF(f);
      BlockReadF(f,header2,SizeOf(header2),temp);
      If NOT ((temp = SizeOf(header2)) and (header2.ident = id)) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2i LOADER ',1);
          EXIT;
        end;

      BlockReadF(f,buf2,header2.b0len,temp);
      If NOT (temp = header2.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2i LOADER ',1);
          EXIT;
        end;

      crc := WORD_NULL;
      crc := Update16(header2.b0len,1,crc);
      crc := Update16(buf2,header2.b0len,crc);

      If (crc <> header2.crc16) then
        begin
          CloseF(f);
          Dialog('CRC FAiLED - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2i LOADER ',1);
          EXIT;
        end;

      APACK_decompress(buf2,buf3);
      Move(buf3,
           songdata.instr_data[current_inst],
           SizeOf(songdata.instr_data[current_inst]));
      Move(buf3[SizeOf(songdata.instr_data[current_inst])],
           temp_str,
           buf3[SizeOf(songdata.instr_data[current_inst])]+1);

      If (temp_str = '') then temp_str := Lower(NameOnly(instdata_source));
      songdata.instr_names[current_inst] :=
        Copy(songdata.instr_names[current_inst],1,9)+truncate_string(temp_str);
    end;

  CloseF(f);
  load_flag := 1;
end;

procedure a2f_file_loader;

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
  temp_str: String;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:a2f_file_loader';
{$ENDIF}
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - DiSK ERROR?$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2F LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,header,SizeOf(header),temp);
  If NOT ((temp = SizeOf(header)) and (header.ident = id)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2F LOADER ',1);
      EXIT;
    end;

  If NOT (header.ffver in [1]) then
    begin
      CloseF(f);
      Dialog('UNKNOWN FiLE FORMAT VERSiON$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2F LOADER ',1);
      EXIT;
    end;

  If (header.ffver = 1) then
    begin
      BlockReadF(f,buf2,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2F LOADER ',1);
          EXIT;
        end;

      crc := DWORD_NULL;
      crc := Update32(header.b0len,1,crc);
      crc := Update32(buf2,header.b0len,crc);

      If (crc <> header.crc32) then
        begin
          CloseF(f);
          Dialog('CRC FAiLED - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2F LOADER ',1);
          EXIT;
        end;

      APACK_decompress(buf2,buf3);
      Move(buf3,
           songdata.instr_data[current_inst],
           SizeOf(songdata.instr_data[current_inst]));
      Move(buf3[SizeOf(songdata.instr_data[current_inst])],
           temp_str,
           buf3[SizeOf(songdata.instr_data[current_inst])]+1);

      If (temp_str = '') then temp_str := Lower(NameOnly(instdata_source));
      songdata.instr_names[current_inst] :=
        Copy(songdata.instr_names[current_inst],1,9)+truncate_string(temp_str);

      Move(buf3[SizeOf(songdata.instr_data[current_inst])+
                buf3[SizeOf(songdata.instr_data[current_inst])]+1],
           songdata.instr_macros[current_inst],
           SizeOf(songdata.instr_macros[current_inst]));

      Move(buf3[SizeOf(songdata.instr_data[current_inst])+
                buf3[SizeOf(songdata.instr_data[current_inst])]+1+
                SizeOf(songdata.instr_macros[current_inst])],
           songdata.dis_fmreg_col[current_inst],
           SizeOf(songdata.dis_fmreg_col[current_inst]));
    end;

  CloseF(f);
  load_flag := 1;
end;

procedure cif_file_loader;

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
  temp_str: String;

const
  MIN_CIF_SIZE = SizeOf(buffer.ident)+
                 SizeOf(buffer.idata)+
                 SizeOf(buffer.resrv);
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:cif_file_loader';
{$ENDIF}
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - DiSK ERROR?$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' CiF LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,buffer,SizeOf(buffer),temp);
  If NOT ((temp >= MIN_CIF_SIZE) and (buffer.ident = id)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' CiF LOADER ',1);
      EXIT;
    end;

  import_hsc_instrument(current_inst,buffer.idata);
  songdata.instr_data[current_inst].fine_tune := 0;

  temp_str := truncate_string(buffer.iname);
  If (temp_str = '') then temp_str := Lower(NameOnly(instdata_source));

  songdata.instr_names[current_inst] :=
    Copy(songdata.instr_names[current_inst],1,9)+temp_str;

  CloseF(f);
  load_flag := 1;
end;

procedure fin_file_loader;

var
  f: File;
  buffer: tFIN_DATA;
  temp: Longint;
  temp_str: String;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:fin_file_loader';
{$ENDIF}
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - DiSK ERROR?$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' FiN LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,buffer,SizeOf(buffer),temp);
  If (temp <> SizeOf(buffer)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' FiN LOADER ',1);
      EXIT;
    end;

  import_fin_instrument(current_inst,buffer.idata);
  If (Length(truncate_string(buffer.iname)) <= 32) then
    temp_str := truncate_string(buffer.iname)
  else temp_str := Lower(truncate_string(buffer.dname));
  If (temp_str = '') then temp_str := Lower(NameOnly(instdata_source));

  songdata.instr_names[current_inst] :=
    Copy(songdata.instr_names[current_inst],1,9)+Copy(temp_str,1,32);

  CloseF(f);
  load_flag := 1;
end;

procedure ins_file_loader;

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

begin { ins_file_loader }
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:ins_file_loader';
{$ENDIF}
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - DiSK ERROR?$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' iNS LOADER ',1);
      EXIT;
    end;

  If (FileSize(f) > SizeOf(buffer)) then
    begin
      CloseF(f);
      Dialog('UNKNOWN FiLE FORMAT TYPE$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' iNS LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,buffer,FileSize(f),temp);
  If (temp <> FileSize(f)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' iNS LOADER ',1);
      EXIT;
    end;

  Case force_ins of
    0: begin
         If (temp = 12) then
           import_standard_instrument(current_inst,buffer.idata);
         If (temp = 12) and NOT correct_ins(buffer.idata) then
           import_hsc_instrument(current_inst,buffer.idata)
         else If (temp > 12) then
                import_sat_instrument(current_inst,buffer.idata);
       end;

    1: import_hsc_instrument(current_inst,buffer.idata);
    2: import_sat_instrument(current_inst,buffer.idata);
    3: import_standard_instrument(current_inst,buffer.idata);
  end;

  songdata.instr_names[current_inst] :=
    Copy(songdata.instr_names[current_inst],1,9)+
    Lower(NameOnly(instdata_source));

  CloseF(f);
  load_flag := 1;
end;

procedure sbi_file_loader;

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
  temp_str: String;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:sbi_file_loader';
{$ENDIF}
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - DiSK ERROR?$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' SBi LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,buffer,SizeOf(buffer),temp);
  If NOT ((temp = SizeOf(buffer)) and (buffer.ident = id)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' SBi LOADER ',1);
      EXIT;
    end;

  import_standard_instrument(current_inst,buffer.idata);
  temp_str := truncate_string(buffer.iname);
  If (temp_str = '') then temp_str := Lower(NameOnly(instdata_source));

  songdata.instr_names[current_inst] :=
    Copy(songdata.instr_names[current_inst],1,9)+Copy(temp_str,1,32);

  CloseF(f);
  load_flag := 1;
end;

procedure import_sgi_instrument(inst: Byte; var data);
begin
  FillChar(songdata.instr_data[inst],
           SizeOf(songdata.instr_data[inst]),0);

  With songdata.instr_data[inst] do
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

procedure sgi_file_loader;

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
  temp_str: String;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:sgi_file_loader';
{$ENDIF}
  {$i-}
  Assign(f,instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - DiSK ERROR?$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' SGi LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,buffer,SizeOf(buffer),temp);
  If (temp <> SizeOf(buffer)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' SGi LOADER ',1);
      EXIT;
    end;

  import_sgi_instrument(current_inst,buffer);
  temp_str := Lower(NameOnly(instdata_source));
  songdata.instr_names[current_inst] :=
    Copy(songdata.instr_names[current_inst],1,9)+Copy(temp_str,1,32);

  CloseF(f);
  load_flag := 1;
end;

end.
