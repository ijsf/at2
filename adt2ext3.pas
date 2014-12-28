unit AdT2ext3;
{$IFDEF __TMT__}
{$S-,Q-,R-,V-,B-,X+}
{$ELSE}
{$PACKRECORDS 1}
{$ENDIF}
interface

const
  arp_tab_selected: Boolean = FALSE;
  vib_tab_selected: Boolean = FALSE;

var
  ptr_arpeggio_table: Byte;
  ptr_vibrato_table: Byte;

procedure a2m_file_loader;
procedure a2t_file_loader;
procedure a2p_file_loader;
procedure a2i_file_loader;
procedure a2f_file_loader;
procedure a2b_file_loader(bankSelector: Boolean; loadBankPossible: Boolean);
procedure a2w_file_loader(loadFromFile: Boolean; loadMacros: Boolean; bankSelector: Boolean;
                          loadBankPossible: Boolean; updateCurInstr: Boolean);
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
procedure bnk_file_loader;
procedure cif_file_loader;
procedure fib_file_loader;
procedure fin_file_loader;
procedure ibk_file_loader;
procedure ins_file_loader;
procedure sbi_file_loader;
procedure sgi_file_loader;
procedure fselect_external_proc;

const
  MAX_NUM_BANK_POSITIONS = 1000;

const
  bank_position_list_size: Longint = 0;

var
  bank_position_list:
    array[1..MAX_NUM_BANK_POSITIONS] of Record
                                          bank_name: String;
                                          bank_size: Longint;
                                          bank_position: Longint;
                                        end;

function  get_bank_position(bank_name: String; bank_size: Longint): Longint;
procedure add_bank_position(bank_name: String; bank_size: Longint; bank_position: Longint);

implementation

uses
{$IFDEF __TMT__}
  DOS,DPMI,
{$ELSE}
  DOS,
{$ENDIF}
  AdT2opl3,AdT2sys,AdT2keyb,AdT2unit,AdT2extn,AdT2ext2,AdT2ext4,AdT2text,AdT2apak,
  StringIO,DialogIO,ParserIO,DepackIO,TxtScrIO;

var
  xstart_arp,ystart_arp,xstart_vib,ystart_vib: Byte;
  scrollbar_xstart,scrollbar_ystart,scrollbar_size: Byte;
  macro_table_size: Byte;
  arpeggio_table_idx,vibrato_table_idx: Byte;
  arpeggio_table_pos,vibrato_table_pos: Byte;

procedure a2w_macro_lister_external_proc_callback; forward;

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
      import_single_old_instrument(old_songdata,current_inst,1);
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
      import_single_old_instrument(old_songdata,current_inst,1);
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
  buf1: tCIF_DATA;
  temp: Longint;
  temp_str: String;

const
  MIN_CIF_SIZE = SizeOf(buf1.ident)+
                 SizeOf(buf1.idata)+
                 SizeOf(buf1.resrv);
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

  BlockReadF(f,buf1,SizeOf(buf1),temp);
  If NOT ((temp >= MIN_CIF_SIZE) and (buf1.ident = id)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' CiF LOADER ',1);
      EXIT;
    end;

  import_hsc_instrument(current_inst,buf1.idata);
  songdata.instr_data[current_inst].fine_tune := 0;

  temp_str := truncate_string(buf1.iname);
  If (temp_str = '') then temp_str := Lower(NameOnly(instdata_source));

  songdata.instr_names[current_inst] :=
    Copy(songdata.instr_names[current_inst],1,9)+temp_str;

  CloseF(f);
  load_flag := 1;
end;

procedure fin_file_loader;

var
  f: File;
  buf1: tFIN_DATA;
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

  BlockReadF(f,buf1,SizeOf(buf1),temp);
  If (temp <> SizeOf(buf1)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' FiN LOADER ',1);
      EXIT;
    end;

  import_fin_instrument(current_inst,buf1.idata);
  If (Length(truncate_string(buf1.iname)) <= 32) then
    temp_str := truncate_string(buf1.iname)
  else temp_str := Lower(truncate_string(buf1.dname));
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
  buf1: tINS_DATA;
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

  If (FileSize(f) > SizeOf(buf1)) then
    begin
      CloseF(f);
      Dialog('UNKNOWN FiLE FORMAT TYPE$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' iNS LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,buf1,FileSize(f),temp);
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
           import_standard_instrument(current_inst,buf1.idata);
         If (temp = 12) and NOT correct_ins(buf1.idata) then
           import_hsc_instrument(current_inst,buf1.idata)
         else If (temp > 12) then
                import_sat_instrument(current_inst,buf1.idata);
       end;

    1: import_hsc_instrument(current_inst,buf1.idata);
    2: import_sat_instrument(current_inst,buf1.idata);
    3: import_standard_instrument(current_inst,buf1.idata);
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
  buf1: tSBI_DATA;
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

  BlockReadF(f,buf1,SizeOf(buf1),temp);
  If NOT ((temp = SizeOf(buf1)) and (buf1.ident = id)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' SBi LOADER ',1);
      EXIT;
    end;

  import_standard_instrument(current_inst,buf1.idata);
  temp_str := truncate_string(buf1.iname);
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
  buf1: tSGI_DATA;
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

  BlockReadF(f,buf1,SizeOf(buf1),temp);
  If (temp <> SizeOf(buf1)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' SGi LOADER ',1);
      EXIT;
    end;

  import_sgi_instrument(current_inst,buf1);
  temp_str := Lower(NameOnly(instdata_source));
  songdata.instr_names[current_inst] :=
    Copy(songdata.instr_names[current_inst],1,9)+Copy(temp_str,1,32);

  CloseF(f);
  load_flag := 1;
end;

var
  xstart,ystart: Byte;
  window_xsize,window_ysize: Byte;
  context_str: String;
  context_str2: String;

var
  temp_marks: array[1..255] of Char;
  a2b_queue: array[1..255+3] of String[74];
  a2b_queue_more: array[1..255+3] of String[104];
  a2w_queue: array[1..255+3] of String[72];
  a2w_queue_more: array[1..255+3] of String[102];
  a2w_queue_more2: array[1..255+3] of String[121];
  a2w_queue_m: array[1..255+5] of String[72];
  a2w_institle_pos: Byte;
  update_current_inst: Boolean;

function count_instruments: Byte;

var
  result: Byte;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:count_instruments';
{$ENDIF}
  result := 255;
  While (result > 0) and
        Empty(temp_songdata.instr_data[result],INSTRUMENT_SIZE) do
    Dec(result);
  count_instruments := result;
end;

function count_macros: Byte;

var
  result: Byte;

begin
  result := 255;
  While (result > 0) and Empty(temp_songdata.macro_table[result].arpeggio,
                               SizeOf(tARPEGGIO_TABLE))
                     and Empty(temp_songdata.macro_table[result].vibrato,
                               SizeOf(tVIBRATO_TABLE)) do
    Dec(result);
  count_macros := result;
end;

function get_free_arpeggio_table_idx(data: tARPEGGIO_TABLE): Byte;

var
  result: Byte;
  free_flag: Boolean;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:get_free_arpeggio_table_idx';
{$ENDIF}
  result := 0;
  free_flag := FALSE;

  // first try to find empty space or same macro for overwriting
  Repeat
    Inc(result);
    If Empty(songdata.macro_table[result].arpeggio,
             SizeOf(tARPEGGIO_TABLE)) or
       Compare(songdata.macro_table[result].arpeggio,data,
               SizeOf(tARPEGGIO_TABLE)) then
      free_flag := TRUE;
  until free_flag or (result = 255);

  // next to find dummy macro (length=0) for overwriting
  If NOT free_flag then
    Repeat
      If (temp_songdata.macro_table[result].arpeggio.length = 0) then
        free_flag := TRUE
      else Dec(result);
    until free_flag or (result = 0);

  get_free_arpeggio_table_idx := result;
end;

function get_free_vibrato_table_idx(data: tVIBRATO_TABLE): Byte;

var
  result: Byte;
  free_flag: Boolean;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:get_free_vibrato_table_idx';
{$ENDIF}
  result := 0;
  free_flag := FALSE;

  // first try to find empty space or same macro for overwriting
  Repeat
    Inc(result);
    If Empty(songdata.macro_table[result].vibrato,
             SizeOf(tViBRATO_TABLE)) or
       Compare(songdata.macro_table[result].vibrato,data,
               SizeOf(tVIBRATO_TABLE)) then
      free_flag := TRUE;
  until free_flag or (result = 255);

  // next to find dummy macro (length=0) for overwriting
  If NOT free_flag then
    Repeat
      If (temp_songdata.macro_table[result].vibrato.length = 0) then
        free_flag := TRUE
      else Dec(result);
    until free_flag or (result = 0);

  get_free_vibrato_table_idx := result;
end;

function _gfx_bar_str(value: Byte; neg: Boolean): String;

var
  result: String;

begin
  result := '';
  If NOT neg then
    Repeat
      If (value > 15) then
        begin
          result := result+#219;
          Dec(value,15);
        end;
      If (value <= 15) and (value <> 0) then
        result := result+CHR(127+value)
    until (value <= 15)
  else Repeat
         If (value > 15) then
           begin
             result := #219+result;
             Dec(value,15);
           end;
         If (value <= 15) and (value <> 0) then
           result := CHR(158-value)+result;
       until (value <= 15);
  _gfx_bar_str := flipstr(result);
end;

procedure a2b_file_loader(bankSelector: Boolean; loadBankPossible: Boolean);

type
  tOLD_HEADER = Record
                  ident: array[1..11] of Char;
                  crc32: Longint;
                  ffver: Byte;
                  b0len: Word;
                end;
type
  tHEADER = Record
              ident: array[1..11] of Char;
              crc32: Longint;
              ffver: Byte;
              b0len: Longint;
            end;
const
  id = '_A2insbank_';

var
  f: File;
  header: tOLD_HEADER;
  header2: tHEADER;
  crc,temp: Longint;
  old_external_proc: procedure;
  old_topic_len: Byte;
  old_cycle_moves: Boolean;
  idx,index,nm_valid: Byte;
  temp_str: String;

const
  new_keys: array[1..3] of Word = (kESC,kENTER,kCtENTR);

var
  old_keys: array[1..3] of Word;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:a2b_file_loader';
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
             '~O~KAY$',' A2B LOADER ',1);
      EXIT;
    end;

  temp_songdata := songdata;
  BlockReadF(f,header,SizeOf(header),temp);
  If NOT ((temp = SizeOf(header)) and (header.ident = id)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2B LOADER ',1);
      EXIT;
    end;

  If NOT (header.ffver in [1..9]) then
    begin
      CloseF(f);
      Dialog('UNKNOWN FiLE FORMAT VERSiON$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2B LOADER ',1);
      EXIT;
    end;

  init_old_songdata;
  If (header.ffver in [1..4]) then
    begin
      FillChar(buf1,SizeOf(buf1),0);
      BlockReadF(f,buf1,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2B LOADER ',1);
          EXIT;
        end;

      crc := DWORD_NULL;
      crc := Update32(header.b0len,2,crc);
      crc := Update32(buf1,header.b0len,crc);

      If (crc <> header.crc32) then
        begin
          CloseF(f);
          Dialog('CRC FAiLED - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2B LOADER ',1);
          EXIT;
        end;

      Case header.ffver of
        4: Move(buf1,old_songdata.instr_names,header.b0len);
        3: LZSS_decompress(buf1,old_songdata.instr_names,header.b0len);
        2: LZW_decompress(buf1,old_songdata.instr_names);
        1: SIXPACK_decompress(buf1,old_songdata.instr_names,header.b0len);
      end;

      For temp := 1 to 250 do
        old_songdata.instr_data[temp].panning := 0;
      import_old_instruments(old_songdata,temp_songdata,1,250);
    end;

  If (header.ffver in [5..8]) then
    begin
      FillChar(buf1,SizeOf(buf1),0);
      BlockReadF(f,buf1,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2B LOADER ',1);
          EXIT;
        end;

      crc := DWORD_NULL;
      crc := Update32(header.b0len,2,crc);
      crc := Update32(buf1,header.b0len,crc);

      If (crc <> header.crc32) then
        begin
          CloseF(f);
          Dialog('CRC FAiLED - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2B LOADER ',1);
          EXIT;
        end;

      Case header.ffver of
        8: Move(buf1,old_songdata.instr_names,header.b0len);
        7: LZSS_decompress(buf1,old_songdata.instr_names,header.b0len);
        6: LZW_decompress(buf1,old_songdata.instr_names);
        5: SIXPACK_decompress(buf1,old_songdata.instr_names,header.b0len);
      end;
      import_old_instruments(old_songdata,temp_songdata,1,250);
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
                 '~O~KAY$',' A2B LOADER ',1);
          EXIT;
        end;

      FillChar(buf1,SizeOf(buf1),0);
      BlockReadF(f,buf1,header2.b0len,temp);
      If NOT (temp = header2.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2B LOADER ',1);
          EXIT;
        end;

      crc := DWORD_NULL;
      crc := Update32(header2.b0len,2,crc);
      crc := Update32(buf1,header2.b0len,crc);

      If (crc <> header2.crc32) then
        begin
          CloseF(f);
          Dialog('CRC FAiLED - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2B LOADER ',1);
          EXIT;
        end;

      For temp := 1 to 255 do
        temp_marks[temp] := temp_songdata.instr_names[temp][1];

      APACK_decompress(buf1,temp_songdata.instr_names);
      For temp := 1 to 255 do
        Insert(temp_marks[temp]+
               'iNS_'+byte2hex(temp)+'๗ ',
               temp_songdata.instr_names[temp],1);
    end;

  FillChar(temp_songdata.dis_fmreg_col,SizeOf(temp_songdata.dis_fmreg_col),FALSE);
  CloseF(f);

  If NOT bankSelector then
    begin
      songdata.instr_names := temp_songdata.instr_names;
      songdata.instr_data := temp_songdata.instr_data;
      load_flag := 1;
      EXIT;
    end;

  a2b_queue[1]       := ' iNSTRUMENT                                 PANNiNG            iNSTRUMENT ';
  a2b_queue[2]       := ' NAME    DESCRiPTiON                        ฉ  c  ช   F.TUNE   VOiCE      ';
  a2b_queue[3]       := 'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ';
  a2b_queue_more[1]  := ' iNSTRUMENT                                                               PANNiNG            iNSTRUMENT ';
  a2b_queue_more[2]  := ' NAME    DESCRiPTiON                        ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0   ฉ  c  ช   F.TUNE   VOiCE      ';
  a2b_queue_more[3]  := 'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ';

  nm_valid := count_instruments;
  If (nm_valid = 0) then nm_valid := 1;

  For idx := 1 to nm_valid do
    begin
      a2b_queue[3+idx] := '~'+ExpStrR(Copy(temp_songdata.instr_names[idx],1,9)+'~'+
                          Copy(temp_songdata.instr_names[idx],10,32),45,' ');
      a2b_queue_more[3+idx] := a2b_queue[3+idx];

      With temp_songdata.instr_data[idx].fm_data do
        begin
          a2b_queue_more[3+idx] := a2b_queue_more[3+idx]+
            byte2hex(AM_VIB_EG_carrier)+
            byte2hex(AM_VIB_EG_modulator)+' '+
            byte2hex(KSL_VOLUM_carrier)+
            byte2hex(KSL_VOLUM_modulator)+' '+
            byte2hex(ATTCK_DEC_carrier)+
            byte2hex(ATTCK_DEC_modulator)+' '+
            byte2hex(SUSTN_REL_carrier)+
            byte2hex(SUSTN_REL_modulator)+' '+
            byte2hex(WAVEFORM_carrier)+
            byte2hex(WAVEFORM_modulator)+' '+
            byte2hex(FEEDBACK_FM)+'   ';
        end;

      temp_str := '๚๚๚๚๚๚๚';
      Case temp_songdata.instr_data[idx].panning of
        0: temp_str := '๚๚๚๚';
        1: temp_str := '๚๚๚๚';
        2: temp_str := '๚๚๚๚';
      end;

      a2b_queue[3+idx] := a2b_queue[3+idx]+temp_str+'   ';
          a2b_queue_more[3+idx] := a2b_queue_more[3+idx]+temp_str+'   ';
      If (temp_songdata.instr_data[idx].fine_tune > 0) then
        temp_str := '+'+ExpStrR(Num2str(temp_songdata.instr_data[idx].fine_tune,16),5,' ')
      else If (temp_songdata.instr_data[idx].fine_tune < 0) then
             temp_str := '-'+ExpStrR(Num2str(0-temp_songdata.instr_data[idx].fine_tune,16),5,' ')
           else temp_str := ExpStrR('',6,' ');

          a2b_queue[3+idx] := a2b_queue[3+idx]+temp_str+'   ';
          a2b_queue_more[3+idx] := a2b_queue_more[3+idx]+temp_str+'   ';
      temp_str := '       ';
      Case temp_songdata.instr_data[idx].perc_voice of
        0: temp_str := 'MELODiC';
        1: temp_str := 'PERC:BD';
        2: temp_str := 'PERC:SD';
        3: temp_str := 'PERC:TT';
        4: temp_str := 'PERC:TC';
        5: temp_str := 'PERC:HH';
      end;

      a2b_queue[3+idx] := a2b_queue[3+idx]+temp_str;
      a2b_queue_more[3+idx] := a2b_queue_more[3+idx]+temp_str;
    end;

  Move(mn_setting.terminate_keys,old_keys,SizeOf(old_keys));
  old_external_proc := mn_environment.ext_proc;
  old_topic_len := mn_setting.topic_len;
  old_cycle_moves := mn_setting.cycle_moves;

  Move(new_keys,mn_setting.terminate_keys,SizeOf(new_keys));
  mn_environment.ext_proc := a2b_lister_external_proc;
  mn_setting.topic_len := 3;
  mn_setting.cycle_moves := FALSE;

  If loadBankPossible then
    mn_environment.context := ' ~[~'+Num2str(nm_valid,10)+'~/255]~ ^ENTER ฤ LOAD COMPLETE BANK '
  else mn_environment.context := '~[~'+Num2str(nm_valid,10)+'~/255]~';

  keyboard_reset_buffer;
  If NOT _force_program_quit then
    If (program_screen_mode in [0,3,4,5]) then
      index := Menu(a2b_queue,01,01,min(1,get_bank_position(instdata_source,nm_valid)),
                    74,20,nm_valid+3,' '+iCASE(NameOnly(instdata_source))+' ')
    else index := Menu(a2b_queue_more,01,01,min(1,get_bank_position(instdata_source,nm_valid)),
                       104,30,nm_valid+3,' '+iCASE(NameOnly(instdata_source))+' ');

  add_bank_position(instdata_source,nm_valid,index+3);
  Move(old_keys,mn_setting.terminate_keys,SizeOf(old_keys));
  mn_environment.ext_proc := old_external_proc;
  mn_setting.topic_len := old_topic_len;
  mn_setting.cycle_moves := old_cycle_moves;

  If (mn_environment.keystroke = kENTER) or
     (loadBankPossible and (mn_environment.keystroke = kCtENTR)) then
    begin
      If (mn_environment.keystroke = kENTER) then
        begin
          songdata.instr_data[current_inst] := temp_songdata.instr_data[index];
          songdata.instr_names[current_inst] := Copy(songdata.instr_names[current_inst],1,9)+
                                                Copy(temp_songdata.instr_names[index],10,32);
        end
      else
        begin
          songdata.instr_data := temp_songdata.instr_data;
          For idx := 1 to 255 do
            songdata.instr_names[idx] := Copy(songdata.instr_names[idx],1,9)+
                                         Copy(temp_songdata.instr_names[idx],10,32);
        end;
      load_flag := 1;
      load_flag_alt := BYTE_NULL;
    end;
  keyboard_reset_buffer;
end;

procedure _macro_preview_refresh;

var
  temp,max_value: Integer;
  d_factor: Real;

function arpeggio_def_attr(page: Byte): Word;

var
  attr,
  attr2: Byte;

begin
  If (page <= temp_songdata.macro_table[arpeggio_table_idx].
              arpeggio.length) then
    If (page >= temp_songdata.macro_table[arpeggio_table_idx].
                arpeggio.loop_begin) and
       (page <= temp_songdata.macro_table[arpeggio_table_idx].
                arpeggio.loop_begin+
                PRED(temp_songdata.macro_table[arpeggio_table_idx].
                     arpeggio.loop_length)) and
       (temp_songdata.macro_table[arpeggio_table_idx].
        arpeggio.loop_begin > 0) and
       (temp_songdata.macro_table[arpeggio_table_idx].
        arpeggio.loop_length > 0) then
      begin
        attr := macro_background+macro_text_loop;
        attr2 := macro_current_bckg+macro_current_loop;
      end
    else If (page >= temp_songdata.macro_table[arpeggio_table_idx].
                     arpeggio.keyoff_pos) and
            (temp_songdata.macro_table[arpeggio_table_idx].
             arpeggio.keyoff_pos > 0) then
           begin
             attr := macro_background+macro_text_keyoff;
             attr2 := macro_current_bckg+macro_current_koff;
           end
         else begin
                attr := macro_background+macro_text;
                attr2 := macro_current_bckg+macro_current;
              end
  else begin
         attr := macro_background+macro_text_dis;
         attr2 := macro_current_bckg+macro_current_dis;
       end;

  arpeggio_def_attr := attr+attr2 SHL 8;
end;

function vibrato_def_attr(page: Byte): Word;

var
  attr,
  attr2: Byte;

begin
  If (page <= temp_songdata.macro_table[vibrato_table_idx].
              vibrato.length) then
    If (page >= temp_songdata.macro_table[vibrato_table_idx].
                vibrato.loop_begin) and
       (page <= temp_songdata.macro_table[vibrato_table_idx].
                vibrato.loop_begin+
                PRED(temp_songdata.macro_table[vibrato_table_idx].
                     vibrato.loop_length)) and
       (temp_songdata.macro_table[vibrato_table_idx].
        vibrato.loop_begin > 0) and
       (temp_songdata.macro_table[vibrato_table_idx].
        vibrato.loop_length > 0) then
      begin
        attr := macro_background+macro_text_loop;
        attr2 := macro_current_bckg+macro_current_loop;
      end
    else If (page >= temp_songdata.macro_table[vibrato_table_idx].
                     vibrato.keyoff_pos) and
            (temp_songdata.macro_table[vibrato_table_idx].
             vibrato.keyoff_pos > 0) then
           begin
             attr := macro_background+macro_text_keyoff;
             attr2 := macro_current_bckg+macro_current_koff;
           end
         else begin
                attr := macro_background+macro_text;
                attr2 := macro_current_bckg+macro_current;
              end
  else begin
         attr := macro_background+macro_text_dis;
         attr2 := macro_current_bckg+macro_current_dis;
       end;

  vibrato_def_attr := attr+attr2 SHL 8;
end;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:_macro_preview_refresh';
{$ENDIF}
  // arpeggio preview
  ShowStr(centered_frame_vdest,xstart_arp+15,ystart_arp,
          'ý',
          macro_background+macro_topic2);
  ShowStr(centered_frame_vdest,xstart_arp+15,ystart_arp+7,
          'ü',
          macro_background+macro_topic2);
  ShowVStr(centered_frame_vdest,xstart_arp,ystart_arp+1,
           'ณณณณณ',
           macro_background+macro_text);
  ShowVStr(centered_frame_vdest,xstart_arp+30,ystart_arp+1,
           'ณณณณณ',
           macro_background+macro_text);

  max_value := 0;
  For temp := 1 to 255 do
    If (temp_songdata.macro_table[arpeggio_table_idx].
        arpeggio.data[temp] > max_value) then
      If (temp_songdata.macro_table[arpeggio_table_idx].
          arpeggio.data[temp] < $80) then
        max_value := Abs(temp_songdata.macro_table[arpeggio_table_idx].
                         arpeggio.data[temp]);

  ShowStr(centered_frame_vdest,xstart_arp+31,ystart_arp+1,
          ExpStrR(Num2Str(max_value,10),3,' '),
          macro_background+macro_topic);
  ShowStr(centered_frame_vdest,xstart_arp+31,ystart_arp+2,
          '+',
          macro_background+macro_topic);

  d_factor := 90/min(max_value,1);
  For temp := -14 to 14 do
    If (arpeggio_table_pos+temp >= 1) and (arpeggio_table_pos+temp <= 255) then
      If (temp_songdata.macro_table[arpeggio_table_idx].
          arpeggio.data[arpeggio_table_pos+temp] < $80) then
        ShowVStr(centered_frame_vdest,xstart_arp+15+temp,ystart_arp+1,
                 ExpStrL(_gfx_bar_str(Round(temp_songdata.macro_table[arpeggio_table_idx].
                                            arpeggio.data[arpeggio_table_pos+temp]*d_factor),FALSE),6,' '),
                 LO(arpeggio_def_attr(arpeggio_table_pos+temp)))
      else ShowVStr(centered_frame_vdest,xstart_arp+15+temp,ystart_arp+1,
                    ExpStrL(FilterStr(note_layout[temp_songdata.macro_table[arpeggio_table_idx].
                                                  arpeggio.data[arpeggio_table_pos+temp]-$80],'-','๑'),6,' '),
                    LO(arpeggio_def_attr(arpeggio_table_pos+temp)))
    else ShowVStr(centered_frame_vdest,xstart_arp+15+temp,ystart_arp+1,
                  ExpStrL('',6,' '),
                  macro_background+macro_text);

  // vibrato preview
  ShowStr(centered_frame_vdest,xstart_vib+15,ystart_vib,
          'ý',
          macro_background+macro_topic2);
  ShowStr(centered_frame_vdest,xstart_vib+15,ystart_vib+7,
          'ü',
          macro_background+macro_topic2);
  ShowVStr(centered_frame_vdest,xstart_vib,ystart_vib+1,
           'ณณณณณ',
           macro_background+macro_text);
  ShowVStr(centered_frame_vdest,xstart_vib+30,ystart_vib+1,
           'ณณณณณ',
           macro_background+macro_text);

  max_value := 0;
  For temp := 1 to 255 do
    If (Abs(temp_songdata.macro_table[vibrato_table_idx].
            vibrato.data[temp]) > max_value) then
      max_value := Abs(temp_songdata.macro_table[vibrato_table_idx].
                       vibrato.data[temp]);

  ShowStr(centered_frame_vdest,xstart_vib+31,ystart_vib+1,
          ExpStrR(Num2Str(max_value,10),3,' '),
          macro_background+macro_topic);
  ShowStr(centered_frame_vdest,xstart_vib+31,ystart_vib+2,
          '+',
          macro_background+macro_topic);
  ShowStr(centered_frame_vdest,xstart_vib+31,ystart_vib+5,
          '-',
          macro_background+macro_topic);
  ShowStr(centered_frame_vdest,xstart_vib+31,ystart_vib+6,
          ExpStrR(Num2Str(max_value,10),3,' '),
          macro_background+macro_topic);

  d_factor := 45/min(max_value,1);
  For temp := -14 to 14 do
    If (vibrato_table_pos+temp >= 1) and (vibrato_table_pos+temp <= 255) then
      If (Round(temp_songdata.macro_table[vibrato_table_idx].
                vibrato.data[vibrato_table_pos+temp]*d_factor) >= 0) then
        ShowVStr(centered_frame_vdest,xstart_vib+15+temp,ystart_vib+1,
                 ExpStrR(ExpStrL(_gfx_bar_str(Round(temp_songdata.macro_table[vibrato_table_idx].
                                                    vibrato.data[vibrato_table_pos+temp]*d_factor),FALSE),3,' '),6,' '),
                 LO(vibrato_def_attr(vibrato_table_pos+temp)))
      else ShowVStr(centered_frame_vdest,xstart_vib+15+temp,ystart_vib+1,
                    ExpStrL(ExpStrR(_gfx_bar_str(Round(Abs(temp_songdata.macro_table[vibrato_table_idx].
                                                           vibrato.data[vibrato_table_pos+temp])*d_factor),TRUE),3,' '),6,' '),
                    LO(vibrato_def_attr(vibrato_table_pos+temp)))
    else ShowVStr(centered_frame_vdest,xstart_vib+15+temp,ystart_vib+1,
                  ExpStrR('',6,' '),
                  macro_background+macro_text);
end;

procedure a2w_macro_lister_external_proc;

const
  _check_chr: array[BOOLEAN] of Char = ('๛',' ');

var
  temp,idx: Byte;
  attr,attr2,attr3: Byte;
  temps: String;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:a2w_macro_lister_external_proc';
{$ENDIF}
  temps := Copy(mn_environment.curr_item,2,2);
  idx := Str2num(temps,16);
  If (idx = 0) then idx := 1;

  VScrollBar(centered_frame_vdest,scrollbar_xstart,scrollbar_ystart,
             scrollbar_size,macro_table_size,idx,WORD_NULL,
             macro_background+macro_border,
             macro_background+macro_border);

  arpeggio_table_idx := idx;
  vibrato_table_idx := idx;

  Case mn_environment.keystroke of
    kSPACE:  begin
               If shift_pressed then
                 begin
                   arp_tab_selected := NOT arp_tab_selected;
                   If alt_pressed then
                                     begin
                       temp_songdata.instr_macros[current_inst].arpeggio_table := 0;
                                           arp_tab_selected := FALSE;
                                         end;
                               If arp_tab_selected then
                                 temp_songdata.instr_macros[current_inst].arpeggio_table := arpeggio_table_idx
                               else If NOT alt_pressed then
                                      temp_songdata.instr_macros[current_inst].arpeggio_table := songdata.instr_macros[current_inst].arpeggio_table;
                 end;
               If ctrl_pressed then
                 begin
                   vib_tab_selected := NOT vib_tab_selected;
                   If alt_pressed then
                                     begin
                       temp_songdata.instr_macros[current_inst].vibrato_table := 0;
                                           vib_tab_selected := FALSE;
                                         end;
                               If vib_tab_selected then
                                 temp_songdata.instr_macros[current_inst].vibrato_table := vibrato_table_idx
                               else If NOT alt_pressed then
                                      temp_songdata.instr_macros[current_inst].vibrato_table := songdata.instr_macros[current_inst].vibrato_table;
                 end;
             end;

        kESC:    begin
                   temp_songdata.instr_macros[current_inst].arpeggio_table := songdata.instr_macros[current_inst].arpeggio_table;
                           temp_songdata.instr_macros[current_inst].vibrato_table := songdata.instr_macros[current_inst].vibrato_table;
                           EXIT;
                 end;

        kENTER:  begin
                   If NOT arp_tab_selected and (temp_songdata.instr_macros[current_inst].arpeggio_table = 0) then
                             songdata.instr_macros[current_inst].arpeggio_table := 0;
                   If NOT vib_tab_selected and (temp_songdata.instr_macros[current_inst].vibrato_table = 0) then
                             songdata.instr_macros[current_inst].vibrato_table := 0;
                           EXIT;
                 end;
    kLEFT,
    kShLEFT: If shift_pressed then
               If (arpeggio_table_pos > 1) then
                 Dec(arpeggio_table_pos);

    kCtLEFT: begin
               If shift_pressed then
                 If (arpeggio_table_pos > 1) then
                   Dec(arpeggio_table_pos);
               If (vibrato_table_pos > 1) then
                 Dec(vibrato_table_pos);
             end;
    kRIGHT,
    kShRGHT: If shift_pressed then
               If (arpeggio_table_pos < 255) then
                 Inc(arpeggio_table_pos);

    kCtRGHT: begin
               If shift_pressed then
                 If (arpeggio_table_pos < 255) then
                   Inc(arpeggio_table_pos);
               If (vibrato_table_pos < 255) then
                 Inc(vibrato_table_pos);
             end;

    kPgUP:   If shift_pressed then
               If (arpeggio_table_pos-18 > 1) then
                 Dec(arpeggio_table_pos,18)
               else arpeggio_table_pos := 1;

    kCtPgUP: begin
               If shift_pressed then
                 If (arpeggio_table_pos-18 > 1) then
                   Dec(arpeggio_table_pos,18)
                 else arpeggio_table_pos := 1;
               If (vibrato_table_pos-18 > 1) then
                 Dec(vibrato_table_pos,18)
               else vibrato_table_pos := 1;
             end;

    kPgDOWN: If shift_pressed then
               If (arpeggio_table_pos+18 < 255) then
                 Inc(arpeggio_table_pos,18)
               else arpeggio_table_pos := 255;

    kCtPgDN: begin
               If shift_pressed then
                 If (arpeggio_table_pos+18 < 255) then
                   Inc(arpeggio_table_pos,18)
                 else arpeggio_table_pos := 255;
               If (vibrato_table_pos+18 < 255) then
                 Inc(vibrato_table_pos,18)
               else vibrato_table_pos := 255;
             end;

    kHOME:   If shift_pressed then
               If (arpeggio_table_pos > temp_songdata.macro_table[idx].arpeggio.length) then
                 arpeggio_table_pos := min(1,temp_songdata.macro_table[idx].arpeggio.length)
               else arpeggio_table_pos := 1;

    kCtHOME: If (vibrato_table_pos > temp_songdata.macro_table[idx].vibrato.length) then
               vibrato_table_pos := min(1,temp_songdata.macro_table[idx].vibrato.length)
             else vibrato_table_pos := 1;

    kEND:    If shift_pressed then
               If (arpeggio_table_pos < temp_songdata.macro_table[idx].arpeggio.length) then
                 arpeggio_table_pos := temp_songdata.macro_table[idx].arpeggio.length
               else arpeggio_table_pos := 255;

    kCtEND:  If (vibrato_table_pos < temp_songdata.macro_table[idx].vibrato.length) then
                 vibrato_table_pos := temp_songdata.macro_table[idx].vibrato.length
             else vibrato_table_pos := 255;

    kCtLbr:  If shift_pressed then
               begin
                 If (songdata.macro_speedup > 1) then
                   Dec(songdata.macro_speedup);
                 macro_speedup := songdata.macro_speedup;
                 keyboard_reset_buffer;
               end
             else If (_4op_to_test = 0) then
                    If (current_inst > 1) and update_current_inst then
                      begin
                        Dec(current_inst);
                        instrum_page := current_inst;
                        STATUS_LINE_refresh;
                        keyboard_reset_buffer;
                      end;

    kCtRbr:  If shift_pressed then
               begin
                 Inc(songdata.macro_speedup);
                 If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                   songdata.macro_speedup := calc_max_speedup(tempo);
                 macro_speedup := songdata.macro_speedup;
                 keyboard_reset_buffer;
               end
             else If (_4op_to_test = 0) then
                    If (current_inst < 255) and update_current_inst then
                      begin
                        Inc(current_inst);
                        instrum_page := current_inst;
                        STATUS_LINE_refresh;
                        keyboard_reset_buffer;
                      end;
   end;

  If arp_tab_selected then
    begin
      attr := macro_hi_text SHL 4+macro_background SHR 4;
      attr2 := macro_background+macro_hi_text;
      attr3 := macro_hi_text SHL 4+macro_background SHR 4;
      temp := arpeggio_table_idx;
    end
  else
    begin
      attr := macro_background+macro_hi_text;
      If (temp_songdata.instr_macros[current_inst].arpeggio_table <> 0) then
        attr2 := macro_background+macro_hi_text
      else attr2 := macro_background+macro_text_dis;
      attr3 := macro_background+macro_text;
      temp := temp_songdata.instr_macros[current_inst].arpeggio_table;
    end;

  ShowC3Str(centered_frame_vdest,xstart_arp-1,ystart_arp+8,
            '`[`'+_check_chr[NOT arp_tab_selected and (temp_songdata.instr_macros[current_inst].arpeggio_table = 0)]+
            '`]`~ '+byte2hex(temp)+'~',
            attr,attr2,attr3);

  If vib_tab_selected then
    begin
      attr := macro_hi_text SHL 4+macro_background SHR 4;
      attr2 := macro_background+macro_hi_text;
      attr3 := macro_hi_text SHL 4+macro_background SHR 4;
      temp := vibrato_table_idx;
    end
  else
    begin
      attr := macro_background+macro_hi_text;
      If (temp_songdata.instr_macros[current_inst].vibrato_table <> 0) then
        attr2 := macro_background+macro_hi_text
      else attr2 := macro_background+macro_text_dis;
      attr3 := macro_background+macro_text;
      temp := temp_songdata.instr_macros[current_inst].vibrato_table;
    end;

  ShowC3Str(centered_frame_vdest,xstart_vib-1,ystart_vib+8,
            '`[`'+_check_chr[NOT vib_tab_selected and (temp_songdata.instr_macros[current_inst].vibrato_table = 0)]+
            '`]`~ '+byte2hex(temp)+'~',
            attr,attr2,attr3);

  If (arpeggio_table_pos > 15) then
    ShowStr(centered_frame_vdest,xstart_arp+6,ystart_arp+8,'',
            macro_background+macro_text)
  else ShowStr(centered_frame_vdest,xstart_arp+6,ystart_arp+8,'',
               macro_background+macro_text_dis);

  If (arpeggio_table_pos < temp_songdata.macro_table[idx].arpeggio.length-15+1) then
    ShowStr(centered_frame_vdest,xstart_arp+25,ystart_arp+8,'',
            macro_background+macro_text)
  else ShowStr(centered_frame_vdest,xstart_arp+25,ystart_arp+8,'',
               macro_background+macro_text_dis);

  If (vibrato_table_pos > 15) then
    ShowStr(centered_frame_vdest,xstart_vib+6,ystart_vib+8,'',
            macro_background+macro_text)
  else ShowStr(centered_frame_vdest,xstart_vib+6,ystart_vib+8,'',
               macro_background+macro_text_dis);

  If (vibrato_table_pos < temp_songdata.macro_table[idx].vibrato.length-15+1) then
    ShowStr(centered_frame_vdest,xstart_vib+24,ystart_vib+8,'',
            macro_background+macro_text)
  else ShowStr(centered_frame_vdest,xstart_vib+24,ystart_vib+8,'',
               macro_background+macro_text_dis);

  ShowCStr(centered_frame_vdest,xstart_arp+10,ystart_vib+8,
           'ARPEGGiO (~'+byte2hex(arpeggio_table_pos)+'~)',
           macro_background+macro_text,
           macro_background+macro_hi_text);
  ShowCStr(centered_frame_vdest,xstart_vib+10,ystart_vib+8,
           'ViBRATO (~'+byte2hex(vibrato_table_pos)+'~)',
           macro_background+macro_text,
           macro_background+macro_hi_text);

  temps := '`'+ExpStrL('`'+context_str2+context_str+' [SPEED:'+Num2str(tempo*songdata.macro_speedup,10)+#3+'] ',40,'อ');
  ShowC3Str(centered_frame_vdest,xstart+window_xsize-C3StrLen(temps),ystart+window_ysize,
            temps,
            macro_background+macro_context,
            macro_background+macro_context_dis,
            macro_background+macro_border);

  If (a2w_institle_pos <> 0) then
    ShowStr(centered_frame_vdest,mn_environment.xpos+a2w_institle_pos,mn_environment.ypos,
            byte2hex(current_inst),
            macro_background+macro_title);

  arpvib_arpeggio_table := arpeggio_table_idx;
  arpvib_vibrato_table := vibrato_table_idx;

  _macro_preview_refresh;
  a2w_macro_lister_external_proc_callback;
end;

const
  _panning: array[0..2] of Char = '๑<>';
  _hex: array[0..15] of Char = '0123456789ABCDEF';
  _fmreg_add_prev_size: Byte = 0;

var
  fmreg_cursor_pos: Byte;
  fmreg_left_margin: Byte;
  fmreg_hpos: Byte;
  fmreg_vpos: Byte;
  fmreg_instr: Byte;
  fmreg_page: Byte;
  fmreg_str: String;
  fmreg_scrlbar_size: Byte;
  fmreg_scrlbar_items: Byte;

function min0(number: Integer; flag: Integer): Integer;
begin
  If (number > 0) then min0 := number
  else min0 := flag;
end;

function fmreg_def_attr(page: Byte): Word;

var
  attr,
  attr2: Byte;

begin
  If (page <= temp_songdata.instr_macros[fmreg_instr].length) then
    If (page >= temp_songdata.instr_macros[fmreg_instr].loop_begin) and
       (page <= temp_songdata.instr_macros[fmreg_instr].loop_begin+
                PRED(temp_songdata.instr_macros[fmreg_instr].loop_length)) and
       (temp_songdata.instr_macros[fmreg_instr].loop_begin > 0) and
       (temp_songdata.instr_macros[fmreg_instr].loop_length > 0) then
      begin
        attr := macro_background+macro_text_loop;
        attr2 := macro_current_bckg+macro_current_loop;
      end
    else If (page >= temp_songdata.instr_macros[fmreg_instr].keyoff_pos) and
            (temp_songdata.instr_macros[fmreg_instr].keyoff_pos > 0) then
           begin
             attr := macro_background+macro_text_keyoff;
             attr2 := macro_current_bckg+macro_current_koff;
           end
         else
           begin
             attr := macro_background+macro_text;
             attr2 := macro_current_bckg+macro_current;
           end
  else
    begin
      attr := macro_background+macro_text_dis;
      attr2 := macro_current_bckg+macro_current_dis;
    end;

  fmreg_def_attr := attr+attr2 SHL 8;
end;

function _fmreg_str(page: Byte): String;

var
  fmreg_str: String;

begin
  With temp_songdata.instr_macros[fmreg_instr].data[page].fm_data do
    begin
      fmreg_str := _hex[ATTCK_DEC_modulator SHR 4]+' '+
                   _hex[ATTCK_DEC_modulator AND $0f]+' '+
                   _hex[SUSTN_REL_modulator SHR 4]+' '+
                   _hex[SUSTN_REL_modulator AND $0f]+' '+
                   _hex[WAVEFORM_modulator AND 7]+' '+
                   byte2hex(KSL_VOLUM_modulator AND $3f)+' '+
                   _hex[KSL_VOLUM_modulator SHR 6]+' '+
                   _hex[AM_VIB_EG_modulator AND $0f]+' ';

      If (AM_VIB_EG_modulator SHR 7 = 0) then fmreg_str := fmreg_str+'๚'
      else fmreg_str := fmreg_str+'T';

      If (AM_VIB_EG_modulator SHR 6 AND 1 = 0) then fmreg_str := fmreg_str+'๚'
      else fmreg_str := fmreg_str+'V';

      If (AM_VIB_EG_modulator SHR 4 AND 1 = 0) then fmreg_str := fmreg_str+'๚'
      else fmreg_str := fmreg_str+'K';

      If (AM_VIB_EG_modulator SHR 5 AND 1 = 0) then fmreg_str := fmreg_str+'๚ '
      else fmreg_str := fmreg_str+'S ';

      fmreg_str := fmreg_str+
                   _hex[ATTCK_DEC_carrier SHR 4]+' '+
                   _hex[ATTCK_DEC_carrier AND $0f]+' '+
                   _hex[SUSTN_REL_carrier SHR 4]+' '+
                   _hex[SUSTN_REL_carrier AND $0f]+' '+
                   _hex[WAVEFORM_carrier AND 7]+' '+
                   byte2hex(KSL_VOLUM_carrier AND $3f)+' '+
                   _hex[KSL_VOLUM_carrier SHR 6]+' '+
                   _hex[AM_VIB_EG_carrier AND $0f]+' ';

      If (AM_VIB_EG_carrier SHR 7 = 0) then fmreg_str := fmreg_str+'๚'
      else fmreg_str := fmreg_str+'T';

      If (AM_VIB_EG_carrier SHR 6 AND 1 = 0) then fmreg_str := fmreg_str+'๚'
      else fmreg_str := fmreg_str+'V';

      If (AM_VIB_EG_carrier SHR 4 AND 1 = 0) then fmreg_str := fmreg_str+'๚'
      else fmreg_str := fmreg_str+'K';

      If (AM_VIB_EG_carrier SHR 5 AND 1 = 0) then fmreg_str := fmreg_str+'๚ '
      else fmreg_str := fmreg_str+'S ';

      fmreg_str := fmreg_str+_hex[FEEDBACK_FM AND 1]+' ';
      fmreg_str := fmreg_str+_hex[FEEDBACK_FM SHR 1 AND 7]+' ';
    end;

  With temp_songdata.instr_macros[fmreg_instr].data[page] do
    begin
      If (freq_slide < 0) then fmreg_str := fmreg_str+'-'+ExpStrL(Num2str(Abs(freq_slide),16),3,'0')+' '
      else fmreg_str := fmreg_str+'+'+ExpStrL(Num2str(Abs(freq_slide),16),3,'0')+' ';

      fmreg_str := fmreg_str+
                   _panning[panning]+' '+
                   byte2hex(duration);
    end;

  _fmreg_str := fmreg_str;
end;

function _dis_fmreg_col(fmreg_col: Byte): Boolean;

var
  result: Boolean;

begin
  result := FALSE;
  Case fmreg_col of
    1,2,3,4,
    5: If temp_songdata.dis_fmreg_col[fmreg_instr][fmreg_col-1] then
         result := TRUE;
    6,
    7: If temp_songdata.dis_fmreg_col[fmreg_instr][5] then
         result := TRUE;

    8,9,10,11,12,13,
    14,15,16,17,
    18: If temp_songdata.dis_fmreg_col[fmreg_instr][fmreg_col-2] then
          result := TRUE;
    19,
    20: If temp_songdata.dis_fmreg_col[fmreg_instr][17] then
          result := TRUE;

    21,22,23,24,
    25,26,27,
    28: If temp_songdata.dis_fmreg_col[fmreg_instr][fmreg_col-3] then
          result := TRUE;

    29,30,31,
    32: If temp_songdata.dis_fmreg_col[fmreg_instr][26] then
          result := TRUE;

    33: If temp_songdata.dis_fmreg_col[fmreg_instr][27] then
          result := TRUE;
  end;

  If (fmreg_col in [14..28]) and
     (temp_songdata.instr_data[current_inst].perc_voice in [2..5]) then
    result := TRUE;

    _dis_fmreg_col := result;
end;

function _str1(def_chr: Char): String;

const
  _on_off: array[BOOLEAN] of Char = ('อ','þ');

var
  temp: Byte;
  temp_str: String;

begin
  temp_str := '';
  _on_off[FALSE] := def_chr;

  For temp := 0 to 4 do
    temp_str := temp_str+
                _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][temp]]+def_chr;

  temp_str := temp_str+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][5]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][5]]+def_chr;

  temp_str := temp_str+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][6]]+
              def_chr+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][7]]+def_chr;

  temp_str := temp_str+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][8]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][9]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][10]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][11]]+def_chr;

  For temp := 12 to 16 do
    temp_str := temp_str+
                _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][temp]]+def_chr;

  temp_str := temp_str+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][17]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][17]]+def_chr;

  temp_str := temp_str+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][18]]+def_chr+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][19]]+def_chr;

  temp_str := temp_str+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][20]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][21]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][22]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][23]]+def_chr;

  For temp := 24 to 25 do
    temp_str := temp_str+
                _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][temp]]+def_chr;

  temp_str := temp_str+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][26]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][26]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][26]]+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][26]]+def_chr;

  temp_str := temp_str+
              _on_off[temp_songdata.dis_fmreg_col[fmreg_instr][27]];

  _str1 := temp_str;
end;

function _str2(str: String; len: Byte): String;
begin
  asm
        lea     esi,[str]
        mov     edi,@RESULT
        movzx   ebx,len
        xor     edx,edx
        push    edi
        lodsb
        inc     edi
        xor     ecx,ecx
        mov     ecx,ebx
        jecxz   @@3
        movzx   ecx,al
        jecxz   @@3
@@1:    cmp     edx,ebx
        jae     @@3
        lodsb
        stosb
        cmp     al,'`'
        jz      @@2
        inc     edx
@@2:    loop    @@1
@@3:    pop     edi
        mov     eax,esi
        lea     esi,[str]
        sub     eax,esi
        dec     eax
        stosb
  end;
end;

procedure fmreg_page_refresh(xpos,ypos: Byte; page: Word);

var
  attr: Byte;
  temps,fmreg_str2: String;
  fmreg_col,index,
  index2: Byte;
  dummy_str: String;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:fmreg_page_refresh';
{$ENDIF}
  attr := LO(fmreg_def_attr(page AND $0fff));
  fmreg_str := _fmreg_str(page AND $0fff);
  fmreg_str2 := fmreg_str;

  index := 0;
  index2 := 0;

  For fmreg_col := 1 to 35-1 do
    If _dis_fmreg_col(fmreg_col) then
      begin
        Insert('`',fmreg_str2,pos5[fmreg_col]+index);
        Insert('`',fmreg_str2,pos5[fmreg_col]+index+2);
        If (pos5[fmreg_col] < fmreg_left_margin) then Inc(index2,2);
        Inc(index,2);
      end;

  temps := Copy(fmreg_str2,fmreg_left_margin+index2,
                Length(fmreg_str2)-fmreg_left_margin-index2+1);

  If (temp_songdata.instr_macros[fmreg_instr].data[page AND $0ff].fm_data.
      FEEDBACK_FM OR $80 <> temp_songdata.instr_macros[fmreg_instr].data[page AND $0ff].fm_data.
                            FEEDBACK_FM) then
    dummy_str := '`'+#$0d+'`'
  else dummy_str := #$0d;

  ShowC3Str(centered_frame_vdest,xpos+3,ypos,
            'ณ~'+dummy_str+'~๖~'+
            _str2(temps,31+window_xsize-82-_fmreg_add_prev_size)+'~',
            macro_background+macro_text,
            attr,
            macro_background+macro_text_dis)
end;

procedure _scroll_cur_left;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:_scroll_cur_left';
{$ENDIF}
  Repeat
    If (fmreg_cursor_pos > 1) then Dec(fmreg_cursor_pos)
    else Dec(fmreg_left_margin);
  until (fmreg_str[PRED(fmreg_left_margin+fmreg_cursor_pos-1)] = ' ') or
        (fmreg_left_margin+fmreg_cursor_pos-1 = 1);
  fmreg_cursor_pos := pos5[fmreg_hpos]-fmreg_left_margin+1;
end;

procedure _scroll_cur_right;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:_scroll_cur_right';
{$ENDIF}
  Repeat
    If (fmreg_cursor_pos < 31+window_xsize-82-_fmreg_add_prev_size) then Inc(fmreg_cursor_pos)
    else Inc(fmreg_left_margin);
  until (fmreg_str[SUCC(fmreg_left_margin+fmreg_cursor_pos-1)] = ' ') or
        (fmreg_left_margin+fmreg_cursor_pos-1 = 57);
  fmreg_cursor_pos := pos5[fmreg_hpos]-fmreg_left_margin+1;
end;

procedure _dec_fmreg_hpos;

var
  old_hpos_idx: Byte;
  new_hpos_idx: Byte;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:_dec_fmreg_hpos';
{$ENDIF}
  old_hpos_idx := pos5vw[fmreg_hpos];
  Repeat
    Dec(fmreg_hpos);
    new_hpos_idx := pos5vw[fmreg_hpos];
    _scroll_cur_left;
  until (fmreg_hpos = 1) or (old_hpos_idx <> new_hpos_idx);
  If (fmreg_hpos > 1) then
    While (pos5vw[PRED(fmreg_hpos)] = pos5vw[fmreg_hpos]) do
      begin
        Dec(fmreg_hpos);
        _scroll_cur_left;
      end;
end;

procedure _inc_fmreg_hpos;

var
  old_hpos_idx: Byte;
  new_hpos_idx: Byte;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:_inc_fmreg_hpos';
{$ENDIF}
  old_hpos_idx := pos5vw[fmreg_hpos];
  Repeat
    Inc(fmreg_hpos);
    new_hpos_idx := pos5vw[fmreg_hpos];
    _scroll_cur_right;
  until (fmreg_hpos = 35-1) or (old_hpos_idx <> new_hpos_idx);
end;

function _fmreg_param(page,fmreg_hpos: Byte): Integer;

var
  result: Integer;
  fmreg_str: String;

begin
  fmreg_str := _fmreg_str(page);
  Case fmreg_hpos of
    {%n}
    1,2,3,4,5,8,9,14,15,16,17,
    18,21,22,27,28: result := Str2num(fmreg_str[pos5[fmreg_hpos]],16);

    {%nn}
    6,7:   result := Str2num(Copy(fmreg_str,pos5[6],2),16);
    19,20: result := Str2num(Copy(fmreg_str,pos5[19],2),16);
    34,35: result := Str2num(Copy(fmreg_str,pos5[34],2),16);

    {sw}
    10,11,12,13,23,24,
    25,26: If (fmreg_str[pos5[fmreg_hpos]] = '๛') then result := 1
              else result := 0;

    {fsl}
    29,30,31,32: begin
                   result := Str2num(Copy(fmreg_str,pos5[30],3),16);
                   If (fmreg_str[pos5[29]] = '-') then result := -result;
                 end;
    {pan}
    33: Case SYSTEM.Pos(fmreg_str[pos5[33]],_panning) of
          1: result := 0;
          2: result := -1;
          3: result := 1;
        end;
  end;
  _fmreg_param := result;
end;

procedure _fmreg_macro_preview_refresh(xstart,ystart: Byte; page: Byte);

var
  temp,max_value: Integer;
  d_factor: Real;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:_fmreg_macro_preview_refresh';
{$ENDIF}
  ShowStr(centered_frame_vdest,xstart+10+(_fmreg_add_prev_size DIV 2),ystart,
          'ý',
          macro_background+macro_topic2);
  ShowStr(centered_frame_vdest,xstart+10+(_fmreg_add_prev_size DIV 2),ystart+7,
          'ü',
          macro_background+macro_topic2);

  If NOT (fmreg_hpos in [29..33]) then
    begin
      ShowVStr(centered_frame_vdest,xstart,ystart+1,
               'ณณณณณ',
               macro_background+macro_text);
      ShowVStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size,ystart+1,
               'ณณณณณ',
               macro_background+macro_text);
    end
  else begin
         ShowVStr(centered_frame_vdest,xstart,ystart+1,
                  'ณณณณณ',
                  macro_background+macro_text);
         ShowVStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size,ystart+1,
                  'ณณณณณ',
                  macro_background+macro_text);
       end;

  max_value := 0;
  For temp := 1 to 255 do
    If (Abs(_fmreg_param(temp,fmreg_hpos)) > max_value) then
      max_value := Abs(_fmreg_param(temp,fmreg_hpos));

  If NOT (fmreg_hpos in [29..33]) then
    begin
      ShowStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size+1,ystart+1,
              ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
              macro_background+macro_topic);
      ShowStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size+1,ystart+2,
              '+',
              macro_background+macro_topic);
      ShowStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size+1,ystart+5,
              ' ',
              macro_background+macro_topic);
      ShowStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size+1,ystart+6,
              ExpStrR('',3,' '),
              macro_background+macro_topic);
    end
  else
    begin
      ShowStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size+1,ystart+1,
              ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
              macro_background+macro_topic);
      ShowStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size+1,ystart+2,
              '+',
              macro_background+macro_topic);
      ShowStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size+1,ystart+5,
              '-',
              macro_background+macro_topic);
      ShowStr(centered_frame_vdest,xstart+20+_fmreg_add_prev_size+1,ystart+6,
              ExpStrR(ExpStrL(Num2Str(max_value,16),2,'0'),3,' '),
              macro_background+macro_topic);
    end;

  If NOT (fmreg_hpos in [29..33]) then
    d_factor := 90/min(max_value,1)
  else d_factor := 45/min(max_value,1);

  If NOT (fmreg_hpos in [29..33]) then
    For temp := -9-(_fmreg_add_prev_size DIV 2) to 9+(_fmreg_add_prev_size DIV 2) do
      If (page+temp >= 1) and (page+temp <= 255) then
        If NOT _dis_fmreg_col(fmreg_hpos) then
          ShowVStr(centered_frame_vdest,xstart+10+temp+(_fmreg_add_prev_size DIV 2),ystart+1,
                   ExpStrL(_gfx_bar_str(Round(_fmreg_param(page+temp,fmreg_hpos)*d_factor),FALSE),6,' '),
                   LO(fmreg_def_attr(page+temp)))
        else
          ShowVStr(centered_frame_vdest,xstart+10+temp+(_fmreg_add_prev_size DIV 2),ystart+1,
                   ExpStrL(_gfx_bar_str(Round(_fmreg_param(page+temp,fmreg_hpos)*d_factor),FALSE),6,' '),
                   macro_background+macro_text_dis)
      else ShowVStr(centered_frame_vdest,xstart+10+temp+(_fmreg_add_prev_size DIV 2),ystart+1,
                    ExpStrL('',6,' '),
                    macro_background+macro_text)
  else For temp := -9-(_fmreg_add_prev_size DIV 2) to 9+(_fmreg_add_prev_size DIV 2) do
         If (page+temp >= 1) and (page+temp <= 255) then
           If (Round(_fmreg_param(page+temp,fmreg_hpos)*d_factor) >= 0) then
             If NOT _dis_fmreg_col(fmreg_hpos) then
               ShowVStr(centered_frame_vdest,xstart+10+temp+(_fmreg_add_prev_size DIV 2),ystart+1,
                        ExpStrR(ExpStrL(_gfx_bar_str(Round(_fmreg_param(page+temp,fmreg_hpos)*d_factor),FALSE),3,' '),6,' '),
                        LO(fmreg_def_attr(page+temp)))
             else
               ShowVStr(centered_frame_vdest,xstart+10+temp+(_fmreg_add_prev_size DIV 2),ystart+1,
                        ExpStrR(ExpStrL(_gfx_bar_str(Round(_fmreg_param(page+temp,fmreg_hpos)*d_factor),FALSE),3,' '),6,' '),
                        macro_background+macro_text_dis)
           else If NOT _dis_fmreg_col(fmreg_hpos) then
                  ShowVStr(centered_frame_vdest,xstart+10+temp+(_fmreg_add_prev_size DIV 2),ystart+1,
                           ExpStrL(ExpStrR(_gfx_bar_str(Round(Abs(_fmreg_param(page+temp,fmreg_hpos))*d_factor),TRUE),3,' '),6,' '),
                           LO(fmreg_def_attr(page+temp)))
                else
                  ShowVStr(centered_frame_vdest,xstart+10+temp+(_fmreg_add_prev_size DIV 2),ystart+1,
                           ExpStrL(ExpStrR(_gfx_bar_str(Round(Abs(_fmreg_param(page+temp,fmreg_hpos))*d_factor),TRUE),3,' '),6,' '),
                           macro_background+macro_text_dis)
         else ShowVStr(centered_frame_vdest,xstart+10+temp+(_fmreg_add_prev_size DIV 2),ystart+1,
                       ExpStrL('',6,' '),
                       macro_background+macro_text);
end;

procedure a2w_lister_external_proc;

var
  idx: Byte;
  temps: String;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:a2w_lister_external_proc';
{$ENDIF}
  Case mn_environment.keystroke of
    kUP:     If shift_pressed then
               If (fmreg_vpos > 1) then Dec(fmreg_vpos)
               else If (fmreg_page > 1) then Dec(fmreg_page);

    kDOWN:   If shift_pressed then
               If (fmreg_vpos < 6) then Inc(fmreg_vpos)
               else If (fmreg_page < 255-6+1) then Inc(fmreg_page);

    kPgUP:   If shift_pressed then
               If (fmreg_page > 6) then Dec(fmreg_page,6)
               else If (fmreg_page > 1) then fmreg_page := 1
                    else fmreg_vpos := 1;

    kPgDOWN: If shift_pressed then
               If (fmreg_page+6 < 255-6+1) then Inc(fmreg_page,6)
               else If (fmreg_page < 255-6+1) then fmreg_page := 255-6+1
                    else fmreg_vpos := 6;

    kHOME:   If shift_pressed then
               begin
                 fmreg_page := 1;
                 fmreg_vpos := 1;
               end;

    kEND:    If shift_pressed then
               begin
                 fmreg_page := 255-6+1;
                 fmreg_vpos := 6;
               end;

    kCtHOME: begin
               fmreg_hpos := 1;
               fmreg_cursor_pos := 1;
               fmreg_left_margin := 1;
             end;

    kCtEND:  begin
               fmreg_hpos := 35-1;
               fmreg_cursor_pos := max(pos5[fmreg_hpos],31+window_xsize-82-_fmreg_add_prev_size);
               fmreg_left_margin := min(pos5[35]-(31+window_xsize-82-_fmreg_add_prev_size),1);
               _dec_fmreg_hpos;
               _inc_fmreg_hpos;
             end;

    kLEFT:   If shift_pressed then
               If (fmreg_hpos > 1) then _dec_fmreg_hpos
               else If cycle_pattern then
                      begin
                        fmreg_hpos := 35-1;
                        fmreg_cursor_pos := max(pos5[fmreg_hpos],31+window_xsize-82-_fmreg_add_prev_size);
                        fmreg_left_margin := min(pos5[35]-(31+window_xsize-82-_fmreg_add_prev_size),1);
                        _dec_fmreg_hpos;
                        _inc_fmreg_hpos;
                      end;

    kRIGHT:  If shift_pressed then
               If (fmreg_hpos < 35-1) then _inc_fmreg_hpos
                else If cycle_pattern then
                       begin
                         fmreg_hpos := 1;
                         fmreg_cursor_pos := 1;
                         fmreg_left_margin := 1;
                       end;

    kCtLbr:  If shift_pressed then
               begin
                 If (songdata.macro_speedup > 1) then
                   Dec(songdata.macro_speedup);
                 macro_speedup := songdata.macro_speedup;
                 keyboard_reset_buffer;
               end
             else If (_4op_to_test = 0) then
                    If (current_inst > 1) and update_current_inst then
                      begin
                        Dec(current_inst);
                        instrum_page := current_inst;
                        STATUS_LINE_refresh;
                        keyboard_reset_buffer;
                      end;

    kCtRbr:  If shift_pressed then
               begin
                 Inc(songdata.macro_speedup);
                 If (calc_max_speedup(tempo) < songdata.macro_speedup) then
                   songdata.macro_speedup := calc_max_speedup(tempo);
                 macro_speedup := songdata.macro_speedup;
                 keyboard_reset_buffer;
               end
             else If (_4op_to_test = 0) then
                    If (current_inst < 255) and update_current_inst then
                      begin
                        Inc(current_inst);
                        instrum_page := current_inst;
                        STATUS_LINE_refresh;
                        keyboard_reset_buffer;
                      end;
   end;

  fmreg_instr := Str2num(Copy(mn_environment.curr_item,7,2),16);
  If update_current_inst then
    begin
      current_inst := fmreg_instr;
      instrum_page := fmreg_instr;
      STATUS_LINE_refresh;
    end;

  If (a2w_institle_pos <> 0) then
    ShowStr(centered_frame_vdest,mn_environment.xpos+a2w_institle_pos,mn_environment.ypos,
            byte2hex(current_inst),
            macro_background+macro_title);

  temps := '`'+ExpStrL('`'+context_str2+context_str+' [SPEED:'+Num2str(tempo*songdata.macro_speedup,10)+#3+'] ',40,'อ');
  ShowC3Str(centered_frame_vdest,xstart+window_xsize-C3StrLen(temps),ystart+window_ysize,
            temps,
            macro_background+macro_context,
            macro_background+macro_context_dis,
            macro_background+macro_border);

  ShowCStr(centered_frame_vdest,xstart+2,ystart+window_ysize-10+2,
           'LENGTH:    ~'+
           byte2hex(temp_songdata.instr_macros[fmreg_instr].length)+' ~',
           macro_background+macro_topic,
           macro_background+macro_text);

  ShowCStr(centered_frame_vdest,xstart+2,ystart+window_ysize-10+3,
           'LOOP BEG.: ~'+
           byte2hex(temp_songdata.instr_macros[fmreg_instr].loop_begin)+' ~',
           macro_background+macro_topic,
           macro_background+macro_text);

  ShowCStr(centered_frame_vdest,xstart+2,ystart+window_ysize-10+4,
           'LOOP LEN.: ~'+
           byte2hex(temp_songdata.instr_macros[fmreg_instr].loop_length)+' ~',
           macro_background+macro_topic,
           macro_background+macro_text);

  ShowCStr(centered_frame_vdest,xstart+2,ystart+window_ysize-10+5,
           'KEY-OFF:   ~'+
           byte2hex(temp_songdata.instr_macros[fmreg_instr].keyoff_pos)+' ~',
           macro_background+macro_topic,
           macro_background+macro_text);

  ShowCStr(centered_frame_vdest,xstart+2,ystart+window_ysize-10+6,
           'ARP.TABLE: ~'+
           byte2hex(temp_songdata.instr_macros[fmreg_instr].arpeggio_table)+' ~',
           macro_background+macro_topic,
           macro_background+macro_text);

  ShowCStr(centered_frame_vdest,xstart+2,ystart+window_ysize-10+7,
           'ViB.TABLE: ~'+
           byte2hex(temp_songdata.instr_macros[fmreg_instr].vibrato_table)+' ~',
           macro_background+macro_topic,
           macro_background+macro_text);

  VScrollBar(centered_frame_vdest,xstart+window_xsize,ystart+3,
             fmreg_scrlbar_size,fmreg_scrlbar_items,mn_environment.curr_pos,WORD_NULL,
             macro_background+macro_border,
             macro_background+macro_border);
  VScrollBar(centered_frame_vdest,xstart+window_xsize,ystart+window_ysize-10+1,
             8,255-6,fmreg_page,WORD_NULL,
             macro_background+macro_border,
             macro_background+macro_border);

  _fmreg_macro_preview_refresh(xstart+17,ystart+window_ysize-10+1,fmreg_page+fmreg_vpos-1);
  ShowCStr(centered_frame_vdest,xstart+49+_fmreg_add_prev_size,ystart+window_ysize-10+1,
           ExpStrL('',fmreg_cursor_pos,'อ')+'~'+#31+'~'+
           ExpStrL('',window_xsize-49-_fmreg_add_prev_size-fmreg_cursor_pos-1,'อ'),
           macro_background+macro_topic2,
           macro_background+macro_hi_text);
  ShowCStr(centered_frame_vdest,xstart+49+_fmreg_add_prev_size,ystart+window_ysize-2,
           ExpStrL('',fmreg_cursor_pos,'อ')+'~'+#30+'~'+
           ExpStrL('',window_xsize-49-_fmreg_add_prev_size-fmreg_cursor_pos-1,'อ'),
           macro_background+macro_topic2,
           macro_background+macro_hi_text);
  ShowStr(centered_frame_vdest,xstart+2,ystart+window_ysize-1,
          ExpStrR(macro_table_hint_str[20+fmreg_hpos],window_xsize-2,' '),
          macro_background+macro_hint);

  For idx := 1 to 6 do
    begin
      If (idx = fmreg_vpos) then
        ShowStr(centered_frame_vdest,xstart+43+_fmreg_add_prev_size,ystart+window_ysize-10+1+idx,
                #16+byte2hex(fmreg_page+idx-1)+#17,
                macro_background+macro_hi_text)
      else ShowStr(centered_frame_vdest,xstart+43+_fmreg_add_prev_size,ystart+window_ysize-10+1+idx,
                   ' '+byte2hex(fmreg_page+idx-1)+' ',
                   macro_background+macro_topic);
      fmreg_page_refresh(xstart+44+_fmreg_add_prev_size,ystart+window_ysize-10+1+idx,fmreg_page+idx-1);
    end;
  a2w_lister_external_proc_callback;
end;

procedure a2w_file_loader(loadFromFile: Boolean; loadMacros: Boolean; bankSelector: Boolean;
                          loadBankPossible: Boolean; updateCurInstr: Boolean);
type
  tOLD_HEADER = Record
                  ident: array[1..20] of Char;
                  crc32: Longint;
                  ffver: Byte;
                  b0len: Longint;
                  b1len: Longint;
                end;
type
  tHEADER = Record
              ident: array[1..20] of Char;
              crc32: Longint;
              ffver: Byte;
              b0len: Longint;
              b1len: Longint;
              b2len: Longint;
            end;
const
  id = '_A2insbank_w/macros_';

var
  f: File;
  a2w_instdata_source: String;
  header: tHEADER;
  header2: tOLD_HEADER;
  crc,temp: Longint;
  idx,index,nm_valid: Byte;
  idx1,idx2: Integer;
  temp_str: String;
  arpvib_arpeggio_table_bak: Byte;
  arpvib_vibrato_table_bak: Byte;
  browser_flag: Boolean;

  // backup of Menu settings / variables
  old_external_proc: procedure;
  old_topic_len: Byte;
  old_cycle_moves: Boolean;
  old_topic_mask_chr: Set of Char;
  old_frame_enabled: Boolean;
  old_shadow_enabled: Boolean;
  old_winshade: Boolean;
  old_center_box: Boolean;
  old_show_scrollbar: Boolean;
  old_text_attr,
  old_text2_attr,
  old_short_attr,
  old_short2_attr,
  old_disbld_attr,
  old_contxt_attr,
  old_contxt2_attr,
  old_topic_attr,
  old_hi_topic_attr: Byte;

const
  new_keys: array[1..5] of Word = (kESC,kENTER,kF1,kTAB,kCtENTR);

var
  old_keys: array[1..50] of Word;

label _jmp1,_jmp1e,_jmp2,_jmp2e,_end;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:a2w_file_loader';
{$ENDIF}
  songdata_bak := songdata;
  arpvib_arpeggio_table_bak := arpvib_arpeggio_table;
  arpvib_vibrato_table_bak := arpvib_vibrato_table;
  temp_songdata := songdata_bak;
  update_current_inst := updateCurInstr;

  If NOT loadFromFile and bankSelector and
     NOT loadBankPossible then
    begin
      a2w_instdata_source := '';
      If loadMacros and _arp_vib_mode then
        begin
          arp_tab_selected := TRUE;
          vib_tab_selected := TRUE;
        end
      else
        begin
          arp_tab_selected := songdata.instr_macros[current_inst].arpeggio_table <> 0;
          vib_tab_selected := songdata.instr_macros[current_inst].vibrato_table <> 0;
        end;

      If loadMacros then
        GOTO _jmp1 // Arpeggio/Vibrato Macro Browser
      else GOTO _jmp2; // Instrument Macro Browser
    end
  else a2w_instdata_source := instdata_source;

  {$i-}
  Assign(f,a2w_instdata_source);
  ResetF(f);
  {$i+}
  If (IOresult <> 0) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - DiSK ERROR?$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2W LOADER ',1);
      EXIT;
    end;

  FillChar(buf1,SizeOf(buf1),0);
  BlockReadF(f,header,SizeOf(header),temp);

  If NOT ((temp = SizeOf(header)) and (header.ident = id)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2W LOADER ',1);
      EXIT;
    end;

  If NOT (header.ffver in [1,2]) then
    begin
      CloseF(f);
      Dialog('UNKNOWN FiLE FORMAT VERSiON$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' A2W LOADER ',1);
      EXIT;
    end;

  If (header.ffver = 1) then
    begin
      ResetF(f);
      BlockReadF(f,header2,SizeOf(header2),temp);
      If NOT ((temp = SizeOf(header2)) and (header2.ident = id)) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      crc := DWORD_NULL;
      BlockReadF(f,buf1,header2.b0len,temp);
      If NOT (temp = header2.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      crc := Update32(buf1,temp,crc);
      BlockReadF(f,buf1,header2.b1len,temp);
      If NOT (temp = header2.b1len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      crc := Update32(buf1,temp,crc);
      crc := Update32(header2.b0len,2,crc);
      crc := Update32(header2.b1len,2,crc);

      If (crc <> header2.crc32) then
        begin
          CloseF(f);
          Dialog('CRC FAiLED - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      SeekF(f,SizeOf(header2));
      If (IOresult <> 0) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      BlockReadF(f,buf1,header2.b0len,temp);
      If NOT (temp = header2.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      For temp := 1 to 255 do
        temp_marks[temp] := temp_songdata.instr_names[temp][1];

      APACK_decompress(buf1,temp_songdata.instr_names);
      For temp := 1 to 255 do
        Insert(temp_marks[temp]+
               'iNS_'+byte2hex(temp)+'๗ ',
               temp_songdata.instr_names[temp],1);

      BlockReadF(f,buf1,header2.b1len,temp);
      If NOT (temp = header2.b1len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      APACK_decompress(buf1,temp_songdata.macro_table);
      FillChar(temp_songdata.dis_fmreg_col,SizeOf(temp_songdata.dis_fmreg_col),FALSE);
    end;

  If (header.ffver = 2) then
    begin
      crc := DWORD_NULL;
      BlockReadF(f,buf1,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      crc := Update32(buf1,temp,crc);
      BlockReadF(f,buf1,header.b1len,temp);
      If NOT (temp = header.b1len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      crc := Update32(buf1,temp,crc);
      BlockReadF(f,buf1,header.b2len,temp);
      If NOT (temp = header.b2len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      crc := Update32(buf1,temp,crc);
      crc := Update32(header.b0len,2,crc);
      crc := Update32(header.b1len,2,crc);
      crc := Update32(header.b2len,2,crc);

      If (crc <> header.crc32) then
        begin
          CloseF(f);
          Dialog('CRC FAiLED - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      SeekF(f,SizeOf(header));
      If (IOresult <> 0) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      BlockReadF(f,buf1,header.b0len,temp);
      If NOT (temp = header.b0len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      For temp := 1 to 255 do
        temp_marks[temp] := temp_songdata.instr_names[temp][1];

      APACK_decompress(buf1,temp_songdata.instr_names);
      For temp := 1 to 255 do
        Insert(temp_marks[temp]+
               'iNS_'+byte2hex(temp)+'๗ ',
               temp_songdata.instr_names[temp],1);

      BlockReadF(f,buf1,header.b1len,temp);
      If NOT (temp = header.b1len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      APACK_decompress(buf1,temp_songdata.macro_table);
      BlockReadF(f,buf1,header.b2len,temp);
      If NOT (temp = header.b2len) then
        begin
          CloseF(f);
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' A2W LOADER ',1);
          EXIT;
        end;

      APACK_decompress(buf1,temp_songdata.dis_fmreg_col);
    end;

  CloseF(f);
  browser_flag := FALSE;

  If loadMacros then
    begin
_jmp1:
      ScreenMemCopy(screen_ptr,ptr_screen_backup);
      nm_valid := count_macros;
      If (nm_valid = 0) then nm_valid := 1;

      If NOT bankSelector then
        begin
          mn_environment.keystroke := kCtENTR;
          arp_tab_selected := TRUE;
          vib_tab_selected := TRUE;
          GOTO _jmp1e;
        end;

      window_xsize := 73;
      If (program_screen_mode in [0,3,4,5]) then window_ysize := max(nm_valid+5,15)+10
      else window_ysize := max(nm_valid+5,20)+10;
      If (a2w_instdata_source <> '') theN temp_str := ' '+iCASE(NameOnly(a2w_instdata_source))+'  A/V MACROS '
      else temp_str := ' ARPEGGiO/ViBRATO MACRO BROWSER ';

      If update_current_inst then temp_str := temp_str + '(iNS_  ) '
      else temp_str := temp_str + '[iNS_  ] ';
      a2w_institle_pos := (window_xsize DIV 2)+(Length(temp_str) DIV 2)-3;

      ScreenMemCopy(screen_ptr,ptr_temp_screen);
      centered_frame_vdest := ptr_temp_screen;
      centered_frame(xstart,ystart,window_xsize,window_ysize,
                     temp_str,
                     macro_background+macro_border,
                     macro_background+macro_title,double);

      ShowStr(centered_frame_vdest,xstart+1,ystart+window_ysize-10+1,
              'ออออสอออออฯอออออฯอออออฯอออออฯออออออสอออออฯอออออฯอออออฯอออออฯอออออฯออออออ',
              macro_background+macro_topic2);

      ShowStr(centered_frame_vdest,xstart+1,ystart+window_ysize-2,
              ExpStrR('',72,'อ'),
              macro_background+macro_topic2);

      context_str := ' ~[~'+Num2str(nm_valid,10)+'~/255]~';
      xstart_arp := xstart+3;
      ystart_arp := ystart+window_ysize-10+1;
      xstart_vib := xstart+38;
      ystart_vib := ystart+window_ysize-10+1;
      scrollbar_xstart := xstart+window_xsize;
      scrollbar_ystart := ystart+1;
      scrollbar_size := window_ysize-10+1;
      macro_table_size := nm_valid;

      If (a2w_instdata_source <> '') then temp_str := a2w_instdata_source
      else temp_str := '?internal_instrument_data';

      arpeggio_table_pos := min(1,get_bank_position(temp_str+'?macro_av?arp_pos',nm_valid));
      vibrato_table_pos := min(1,get_bank_position(temp_str+'?macro_av?vib_pos',nm_valid));

      a2w_queue_m[1] := 'ฤฤฤฤาฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤาฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ';
      a2w_queue_m[2] := '    บ     ~ARPEGGiO MACRO TABLE~     บ        ~ViBRATO MACRO TABLE~';
      a2w_queue_m[3] := '    วฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤฤืฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤฤ';
      a2w_queue_m[4] := ' NO.บLEN. ณSPEEDณL.BEGณL.LENณK.OFF บLEN. ณSPEEDณDELAYณL.BEGณL.LENณK.OFF ';
      a2w_queue_m[5] := 'ออออฮอออออุอออออุอออออุอออออุออออออฮอออออุอออออุอออออุอออออุอออออุออออออ';

      For idx := 1 to nm_valid do
        begin
          a2w_queue_m[5+idx] := ' ~'+byte2hex(idx)+'~ บ';
          If Empty(temp_songdata.macro_table[idx].arpeggio,SizeOf(tARPEGGIO_TABLE)) then
            a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๚๚  ณ'+
                                                     ' ๚๚  ณ'+
                                                     ' ๚๚  ณ'+
                                                     ' ๚๚  ณ'+
                                                     ' ๚๚   บ'
          else
            With temp_songdata.macro_table[idx].arpeggio do
              begin
                If (length > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(length)+'  ณ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙  ณ';
                If (speed > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(speed)+'  ณ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙  ณ';
                If (loop_begin > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(loop_begin)+'  ณ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙  ณ';
                If (loop_length > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(loop_length)+'  ณ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙  ณ';
                If (keyoff_pos > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(keyoff_pos)+'   บ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙   บ';
              end;

          If Empty(temp_songdata.macro_table[idx].vibrato,SizeOf(tViBRATO_TABLE)) then
            a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๚๚  ณ'+
                                                     ' ๚๚  ณ'+
                                                     ' ๚๚  ณ'+
                                                     ' ๚๚  ณ'+
                                                     ' ๚๚  ณ'+
                                                     ' ๚๚'
          else
            With temp_songdata.macro_table[idx].vibrato do
              begin
                If (length > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(length)+'  ณ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙  ณ';
                If (speed > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(speed)+'  ณ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙  ณ';
                If (delay > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(delay)+'  ณ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙  ณ';
                If (loop_begin > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(loop_begin)+'  ณ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙  ณ';
                If (loop_length > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(loop_length)+'  ณ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙  ณ';
                If (keyoff_pos > 0) then
                  a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' '+byte2hex(keyoff_pos)+'   บ'
                else a2w_queue_m[5+idx] := a2w_queue_m[5+idx]+' ๙๙';
              end;
        end;

      Move(mn_setting.terminate_keys,old_keys,SizeOf(old_keys));
      old_external_proc := mn_environment.ext_proc;
      old_topic_len := mn_setting.topic_len;
      old_cycle_moves := mn_setting.cycle_moves;
      old_topic_mask_chr := mn_setting.topic_mask_chr;
      old_frame_enabled := mn_setting.frame_enabled;
      old_shadow_enabled := mn_setting.shadow_enabled;
      old_winshade := mn_environment.winshade;
      old_center_box := mn_setting.center_box;
      old_show_scrollbar := mn_setting.show_scrollbar;
      old_text_attr := mn_setting.text_attr;
      old_text2_attr := mn_setting.text2_attr;
      old_short_attr := mn_setting.short_attr;
      old_short2_attr := mn_setting.short2_attr;
      old_disbld_attr := mn_setting.disbld_attr;
      old_contxt_attr := mn_setting.contxt_attr;
      old_contxt2_attr := mn_setting.contxt2_attr;
      old_topic_attr := mn_setting.topic_attr;
      old_hi_topic_attr := mn_setting.hi_topic_attr;

      Move(new_keys,mn_setting.terminate_keys,SizeOf(new_keys));
      mn_setting.terminate_keys[4] := 0; // TAB possible only in FM-Register bank browser
      If NOT loadBankPossible then
        mn_setting.terminate_keys[5] := 0; // ^ENTER possible only in Arpeggio/Vibrato Macro Editor

      mn_environment.ext_proc := a2w_macro_lister_external_proc;
      mn_setting.topic_len := 5;
      mn_setting.cycle_moves := FALSE;
      mn_setting.topic_mask_chr := ['ณ','บ'];
      mn_setting.frame_enabled := FALSE;
      mn_setting.shadow_enabled := FALSE;
      mn_environment.winshade := FALSE;
      mn_setting.center_box := FALSE;
      mn_setting.show_scrollbar := FALSE;
      mn_environment.unpolite := FALSE;
      mn_environment.preview := TRUE;
      mn_environment.v_dest := ptr_temp_screen;
      mn_setting.text_attr := macro_background+macro_item;
      mn_setting.text2_attr := macro_sel_itm_bck+macro_sel_itm;
      mn_setting.short_attr := macro_background+macro_short;
      mn_setting.short2_attr := macro_sel_itm_bck+macro_sel_short;
      mn_setting.disbld_attr := macro_background+macro_item_dis;
      mn_setting.contxt_attr := macro_background+macro_context;
      mn_setting.contxt2_attr := macro_background+macro_context_dis;
      mn_setting.topic_attr := macro_background+macro_topic2;
      mn_setting.hi_topic_attr := macro_background+macro_hi_topic;

      If (a2w_instdata_source <> '') then temp_str := a2w_instdata_source
      else temp_str := '?internal_instrument_data';

      If (program_screen_mode in [0,3,4,5]) then
        Menu(a2w_queue_m,xstart,ystart,
             min(1,get_bank_position(temp_str+'?macro_av?pos',nm_valid)),
             72,max(nm_valid+5,15),nm_valid+5,'')
      else Menu(a2w_queue_m,xstart,ystart,
                    min(1,get_bank_position(temp_str+'?macro_av?pos',nm_valid)),
                72,max(nm_valid+5,20),nm_valid+5,'');

      move_to_screen_data := ptr_temp_screen;
      move_to_screen_area[1] := xstart;
      move_to_screen_area[2] := ystart;
      move_to_screen_area[3] := xstart+window_xsize+2+1;
      move_to_screen_area[4] := ystart+window_ysize+1;
{$IFDEF __TMT__}
      toggle_waitretrace := TRUE;
{$ENDIF}
      move2screen_alt;

      mn_environment.unpolite := FALSE;
      mn_environment.preview := FALSE;
      mn_environment.v_dest := screen_ptr;
      centered_frame_vdest := mn_environment.v_dest;

      keyboard_reset_buffer;
      If NOT _force_program_quit then
        If (program_screen_mode in [0,3,4,5]) then
          index := Menu(a2w_queue_m,xstart,ystart,
                        min(1,get_bank_position(temp_str+'?macro_av?pos',nm_valid)),
                        72,max(nm_valid+5,15),nm_valid+5,'')
        else index := Menu(a2w_queue_m,xstart,ystart,
                           min(1,get_bank_position(temp_str+'?macro_av?pos',nm_valid)),
                           72,max(nm_valid+5,20),nm_valid+5,'');

      add_bank_position(temp_str+'?macro_av?pos',nm_valid,index+5);
      add_bank_position(temp_str+'?macro_av?arp_pos',nm_valid,arpeggio_table_pos);
      add_bank_position(temp_str+'?macro_av?vib_pos',nm_valid,vibrato_table_pos);

      Move(old_keys,mn_setting.terminate_keys,SizeOf(old_keys));
      mn_environment.ext_proc := old_external_proc;
      mn_setting.topic_len := old_topic_len;
      mn_setting.cycle_moves := old_cycle_moves;
      mn_setting.topic_mask_chr := old_topic_mask_chr;
      mn_setting.frame_enabled := old_frame_enabled;
      mn_setting.shadow_enabled := old_shadow_enabled;
      mn_environment.winshade := old_winshade;
      mn_setting.center_box := old_center_box;
      mn_setting.show_scrollbar := old_show_scrollbar;
      mn_setting.text_attr := old_text_attr;
      mn_setting.text2_attr := old_text2_attr;
      mn_setting.short_attr := old_short_attr;
      mn_setting.short2_attr := old_short2_attr;
      mn_setting.disbld_attr := old_disbld_attr;
      mn_setting.contxt_attr := old_contxt_attr;
      mn_setting.contxt2_attr := old_contxt2_attr;
      mn_setting.topic_attr := old_topic_attr;
      mn_setting.hi_topic_attr := old_hi_topic_attr;

      move_to_screen_data := ptr_screen_backup;
      move_to_screen_area[1] := xstart;
      move_to_screen_area[2] := ystart;
      move_to_screen_area[3] := xstart+window_xsize+2+1;
      move_to_screen_area[4] := ystart+window_ysize+1;
      move2screen;

      If (mn_environment.keystroke = kF1) then
        begin
          HELP('macro_browser_av');
          If NOT _force_program_quit then GOTO _jmp1;
        end;

      If NOT loadMacros and (mn_environment.keystroke = kESC) then
        begin
          songdata := songdata_bak;
          load_flag := BYTE_NULL;
          load_flag_alt := BYTE_NULL;
          GOTO _jmp2;
        end;
_jmp1e:
      If (mn_environment.keystroke = kENTER) or
         (loadBankPossible and (mn_environment.keystroke = kCtENTR)) then
        begin
          If (mn_environment.keystroke = kENTER) then
            begin
              If loadMacros or _arp_vib_loader then
                begin
                  arpvib_arpeggio_table := arpvib_arpeggio_table_bak;
                  arpvib_vibrato_table := arpvib_vibrato_table_bak;
                  If arp_tab_selected then
                    songdata.macro_table[arpvib_arpeggio_table].arpeggio := temp_songdata.macro_table[index].arpeggio;
                  If vib_tab_selected then
                    songdata.macro_table[arpvib_vibrato_table].vibrato := temp_songdata.macro_table[index].vibrato;
                end
              else
                begin
                  idx1 := -1;
                  idx2 := -1;
                  If arp_tab_selected then
                    idx1 := get_free_arpeggio_table_idx(temp_songdata.macro_table[index].arpeggio);
                  If vib_tab_selected then
                    idx2 := get_free_vibrato_table_idx(temp_songdata.macro_table[index].vibrato);

                  temp_str := '';
                  If (idx1 = 0) then
                    If (idx2 = 0) then
                      temp_str := '~ARPEGGiO/ViBRATO'
                    else temp_str := '~ARPEGGiO'
                  else If (idx2 = 0) then
                         temp_str := '~ViBRATO';

                  If NOT (temp_str <> '') then
                    begin
                      If (idx1 > 0) then
                        begin
                          songdata.macro_table[idx1].arpeggio := temp_songdata.macro_table[index].arpeggio;
                          songdata.instr_macros[current_inst].arpeggio_table := idx1;
                        end;
                      If (idx2 > 0) then
                        begin
                          songdata.macro_table[idx2].vibrato := temp_songdata.macro_table[index].vibrato;
                          songdata.instr_macros[current_inst].vibrato_table := idx2;
                        end;
                    end
                  else begin
                         Dialog('RELATED '+temp_str+' DATA~ WAS NOT LOADED!$'+
                                'FREE SOME SPACE iN MACRO TABLES AND ~REPEAT THiS ACTiON~$',
                                '~O~K$',' A2W LOADER ',1);
                         GOTO _end;
                       end;
                end;
              load_flag := 1;
              load_flag_alt := BYTE_NULL;
            end
          else
            begin
              temp_str := '';
              If arp_tab_selected then temp_str := 'ARPEGGiO';
              If vib_tab_selected then
                If (temp_str <> '') then temp_str := temp_str+'/ViBRATO'
                else temp_str := 'ViBRATO';
              If NOT (NOT arp_tab_selected and NOT vib_tab_selected) or (nm_valid < 2) then
                begin
                  If bankSelector then
                    index := Dialog('ALL UNSAVED '+temp_str+' MACRO DATA WiLL BE LOST$'+
                                    'DO YOU WiSH TO CONTiNUE?$',
                                    '~Y~UP$~N~OPE$',' A2W LOADER ',1)
                  else begin
                         index := 1;
                         dl_environment.keystroke := kENTER;
                       end;
                  If (dl_environment.keystroke <> kESC) and (index = 1) then
                    begin
                      For idx := 1 to 255 do
                        If NOT (idx > nm_valid) then
                          begin
                            If arp_tab_selected then
                              songdata.macro_table[idx].arpeggio := temp_songdata.macro_table[idx].arpeggio;
                            If vib_tab_selected then
                              songdata.macro_table[idx].vibrato := temp_songdata.macro_table[idx].vibrato;
                          end
                        else begin
                               FillChar(songdata.macro_table[idx].arpeggio,SizeOf(songdata.macro_table[idx].arpeggio),0);
                               FillChar(songdata.macro_table[idx].vibrato,SizeOf(songdata.macro_table[idx].vibrato),0);
                             end;
                      load_flag := 1;
                      load_flag_alt := BYTE_NULL;
                    end;
                end;
            end;
        end;
    end
  else
    begin
_jmp2:
      browser_flag := FALSE;
      ScreenMemCopy(screen_ptr,ptr_screen_backup);

      a2w_queue[1]       := ' iNSTRUMENT                                 iNSTRUMENT                  ';
      a2w_queue[2]       := ' NAME    DESCRiPTiON                        VOiCE     MACROS            ';
      a2w_queue[3]       := 'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ';
      a2w_queue_more[1]  := ' iNSTRUMENT                                                               iNSTRUMENT                  ';
      a2w_queue_more[2]  := ' NAME    DESCRiPTiON                        ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0   VOiCE     MACROS            ';
      a2w_queue_more[3]  := 'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ';
      a2w_queue_more2[1] := ' iNSTRUMENT                                                               PANNiNG            iNSTRUMENT                  ';
      a2w_queue_more2[2] := ' NAME    DESCRiPTiON                        ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0   ฉ  c  ช   F.TUNE   VOiCE     MACROS            ';
      a2w_queue_more2[3] := 'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ';

      nm_valid := count_instruments;
      If (nm_valid = 0) then nm_valid := 1;

      If NOT bankSelector then
        begin
          mn_environment.keystroke := kCtENTR;
          GOTO _jmp2e;
        end;

      context_str := '';
      context_str2 := '';
      If (a2w_instdata_source = '') then nm_valid := 255
      else begin
             context_str := ' ~[~'+Num2str(nm_valid,10)+'~/255]~';
             If NOT loadBankPossible then context_str2 := ' ~[BANK]~'
             else context_str2 := ' [BANK]';
           end;

      For idx := 1 to nm_valid do
        begin
          a2w_queue[3+idx] := '~'+ExpStrR(Copy(temp_songdata.instr_names[idx],1,9)+'~'+
                              Copy(temp_songdata.instr_names[idx],10,32),45,' ');
          a2w_queue_more[3+idx] := a2w_queue[3+idx];

          With temp_songdata.instr_data[idx].fm_data do
            begin
              a2w_queue_more[3+idx] := a2w_queue_more[3+idx]+
                byte2hex(AM_VIB_EG_carrier)+
                byte2hex(AM_VIB_EG_modulator)+' '+
                byte2hex(KSL_VOLUM_carrier)+
                byte2hex(KSL_VOLUM_modulator)+' '+
                byte2hex(ATTCK_DEC_carrier)+
                byte2hex(ATTCK_DEC_modulator)+' '+
                byte2hex(SUSTN_REL_carrier)+
                byte2hex(SUSTN_REL_modulator)+' '+
                byte2hex(WAVEFORM_carrier)+
                byte2hex(WAVEFORM_modulator)+' '+
                byte2hex(FEEDBACK_FM)+'   ';
            end;

          temp_str := '๚๚๚๚๚๚๚';
          Case temp_songdata.instr_data[idx].panning of
            0: temp_str := '๚๚๚๚';
            1: temp_str := '๚๚๚๚';
            2: temp_str := '๚๚๚๚';
          end;

          a2w_queue_more2[3+idx] := a2w_queue_more[3+idx]+temp_str+'   ';
          If (temp_songdata.instr_data[idx].fine_tune > 0) then
            temp_str := '+'+ExpStrR(Num2str(temp_songdata.instr_data[idx].fine_tune,16),5,' ')
          else If (temp_songdata.instr_data[idx].fine_tune < 0) then
                 temp_str := '-'+ExpStrR(Num2str(0-temp_songdata.instr_data[idx].fine_tune,16),5,' ')
               else temp_str := ExpStrR('',6,' ');

          a2w_queue_more2[3+idx] := a2w_queue_more2[3+idx]+temp_str+'   ';
          temp_str := '       ';
          Case temp_songdata.instr_data[idx].perc_voice of
            0: temp_str := 'MELODiC';
            1: temp_str := 'PERC:BD';
            2: temp_str := 'PERC:SD';
            3: temp_str := 'PERC:TT';
            4: temp_str := 'PERC:TC';
            5: temp_str := 'PERC:HH';
          end;

          a2w_queue[3+idx] := a2w_queue[3+idx]+temp_str;
          a2w_queue_more[3+idx] := a2w_queue_more[3+idx]+temp_str;
          a2w_queue_more2[3+idx] := a2w_queue_more2[3+idx]+temp_str;

          If (temp_songdata.instr_macros[idx].length <> 0) then temp_str := ' MACRO:FM'
          else temp_str := ' ';

          With temp_songdata.macro_table[
               temp_songdata.instr_macros[idx].arpeggio_table].arpeggio do
            If (temp_songdata.instr_macros[idx].arpeggio_table <> 0) then
              If (temp_str <> ' ') then temp_str := temp_str+'+ARP'
              else temp_str := temp_str+'MACRO:ARP';

          With temp_songdata.macro_table[
               temp_songdata.instr_macros[idx].vibrato_table].vibrato do
            If (temp_songdata.instr_macros[idx].vibrato_table <> 0) then
              If (temp_str <> ' ') then temp_str := temp_str+'+ViB'
              else temp_str := temp_str+'MACRO:ViB';

          a2w_queue[3+idx] := a2w_queue[3+idx]+'  '+ExpStrR(temp_str,18,' ');
          a2w_queue_more[3+idx] := a2w_queue_more[3+idx]+'  '+ExpStrR(temp_str,18,' ');
          a2w_queue_more2[3+idx] := a2w_queue_more2[3+idx]+'  '+ExpStrR(temp_str,18,' ');
        end;

      If (a2w_instdata_source <> '') then temp_str := a2w_instdata_source
      else temp_str := '?internal_instrument_data';

      idx := min(1,get_bank_position(temp_str+'?macro?pos',nm_valid));
      fmreg_page := min(1,get_bank_position(temp_str+'?macro?fmreg_page',nm_valid));
      fmreg_hpos := min(1,get_bank_position(temp_str+'?macro?fmreg_hpos',nm_valid));
      fmreg_vpos := min(1,get_bank_position(temp_str+'?macro?fmreg_vpos',nm_valid));
      fmreg_left_margin := min(1,get_bank_position(temp_str+'?macro?fmreg_left_margin',nm_valid));
      fmreg_cursor_pos := min(1,get_bank_position(temp_str+'?macro?fmreg_cursor_pos',nm_valid));

      If (a2w_instdata_source <> '') then temp_str := ' '+iCASE(NameOnly(a2w_instdata_source))+' '
      else begin
             If updateCurInstr then add_bank_position('?internal_instrument_data?pos',255,current_inst);
             temp_str := ' iNSTRUMENT MACRO BROWSER ';
           end;

      Case program_screen_mode of
        0,3,4,
        5: begin
             window_xsize := 73;
             window_ysize := max(nm_valid+3,15)+10;
           end;
        1: begin
             window_xsize := 103;
             window_ysize := max(nm_valid+3,20)+10;
           end;
        2: begin
             window_xsize := 122;
             window_ysize := max(nm_valid+3,20)+10;
           end;
      end;

      xstart := ((work_MaxCol-window_xsize) DIV 2);
      ystart := ((work_MaxLn-window_ysize) DIV 2)+1;
      fmreg_scrlbar_items := nm_valid;
      fmreg_scrlbar_size := window_ysize-10-2;
      If NOT (program_screen_mode in [0,3,4,5]) then _fmreg_add_prev_size := 10
      else _fmreg_add_prev_size := 0;

      If update_current_inst then
        begin
          temp_str := temp_str + '(iNS_  ) ';
          idx := current_inst;
        end
      else temp_str := temp_str + '[iNS_  ] ';
      a2w_institle_pos := (window_xsize DIV 2)+(Length(temp_str) DIV 2)-3;

      ScreenMemCopy(screen_ptr,ptr_temp_screen);
      centered_frame_vdest := ptr_temp_screen;
      centered_frame(xstart,ystart,window_xsize,window_ysize,
                     temp_str,
                     macro_background+macro_border,
                     macro_background+macro_title,double);

      ShowStr(centered_frame_vdest,xstart+1,ystart+window_ysize-10+1,
              ExpStrR('',window_xsize-1,'อ'),
              macro_background+macro_topic2);
      ShowStr(centered_frame_vdest,xstart+1,ystart+window_ysize-2,
              ExpStrR('',window_xsize-1,'อ'),
              macro_background+macro_topic2);
      ShowVStr(centered_frame_vdest,xstart+42+_fmreg_add_prev_size,ystart+window_ysize-10+1,
               'หบบบบบบส',
               macro_background+macro_topic2);

      Move(mn_setting.terminate_keys,old_keys,SizeOf(old_keys));
      old_external_proc := mn_environment.ext_proc;
      old_topic_len := mn_setting.topic_len;
      old_cycle_moves := mn_setting.cycle_moves;
      old_topic_mask_chr := mn_setting.topic_mask_chr;
      old_frame_enabled := mn_setting.frame_enabled;
      old_shadow_enabled := mn_setting.shadow_enabled;
      old_winshade := mn_environment.winshade;
      old_center_box := mn_setting.center_box;
      old_show_scrollbar := mn_setting.show_scrollbar;
      old_text_attr := mn_setting.text_attr;
      old_text2_attr := mn_setting.text2_attr;
      old_short_attr := mn_setting.short_attr;
      old_short2_attr := mn_setting.short2_attr;
      old_disbld_attr := mn_setting.disbld_attr;
      old_contxt_attr := mn_setting.contxt_attr;
      old_contxt2_attr := mn_setting.contxt2_attr;
      old_topic_attr := mn_setting.topic_attr;
      old_hi_topic_attr := mn_setting.hi_topic_attr;

      Move(new_keys,mn_setting.terminate_keys,SizeOf(new_keys));
      If NOT loadBankPossible then
        mn_setting.terminate_keys[5] := 0; // ^ENTER possible only in Instrument Control

      mn_environment.ext_proc := a2w_lister_external_proc;
      mn_setting.topic_len := 3;
      mn_setting.cycle_moves := FALSE;
      mn_setting.frame_enabled := FALSE;
      mn_setting.shadow_enabled := FALSE;
      mn_environment.winshade := FALSE;
      mn_setting.center_box := FALSE;
      mn_setting.show_scrollbar := FALSE;
      mn_environment.unpolite := FALSE;
      mn_environment.preview := TRUE;
      mn_environment.v_dest := ptr_temp_screen;
      mn_setting.text_attr := macro_background+macro_item;
      mn_setting.text2_attr := macro_sel_itm_bck+macro_sel_itm;
      mn_setting.short_attr := macro_background+macro_short;
      mn_setting.short2_attr := macro_sel_itm_bck+macro_sel_short;
      mn_setting.disbld_attr := macro_background+macro_item_dis;
      mn_setting.contxt_attr := macro_background+macro_context;
      mn_setting.contxt2_attr := macro_background+macro_context_dis;
      mn_setting.topic_attr := macro_background+macro_topic2;
      mn_setting.hi_topic_attr := macro_background+macro_hi_topic;

      If NOT _force_program_quit then
        If (program_screen_mode in [0,3,4,5]) then
          index := Menu(a2w_queue,xstart,ystart,idx+3,72,max(nm_valid+3,15),nm_valid+3,temp_str)
        else If (program_screen_mode = 1) then
               index := Menu(a2w_queue_more,xstart,ystart,idx+3,102,max(nm_valid+3,20),nm_valid+3,temp_str)
             else index := Menu(a2w_queue_more2,xstart,ystart,idx+3,121,max(nm_valid+3,20),nm_valid+3,temp_str);

      move_to_screen_data := ptr_temp_screen;
      move_to_screen_area[1] := xstart;
      move_to_screen_area[2] := ystart;
      move_to_screen_area[3] := xstart+window_xsize+2+1;
      move_to_screen_area[4] := ystart+window_ysize+1;
{$IFDEF __TMT__}
      toggle_waitretrace := TRUE;
{$ENDIF}
      move2screen_alt;

      mn_environment.unpolite := FALSE;
      mn_environment.preview := FALSE;
      mn_environment.v_dest := screen_ptr;
      centered_frame_vdest := mn_environment.v_dest;

      keyboard_reset_buffer;
      If NOT _force_program_quit then
        If (program_screen_mode in [0,3,4,5]) then
          index := Menu(a2w_queue,xstart,ystart,idx+3,72,max(nm_valid+3,15),nm_valid+3,temp_str)
        else If (program_screen_mode = 1) then
               index := Menu(a2w_queue_more,xstart,ystart,idx+3,102,max(nm_valid+3,20),nm_valid+3,temp_str)
             else index := Menu(a2w_queue_more2,xstart,ystart,idx+3,121,max(nm_valid+3,20),nm_valid+3,temp_str);

      If (a2w_instdata_source <> '') then temp_str := a2w_instdata_source
      else temp_str := '?internal_instrument_data';

      add_bank_position(temp_str+'?macro?pos',nm_valid,index);
      add_bank_position(temp_str+'?macro?fmreg_page',nm_valid,fmreg_page);
      add_bank_position(temp_str+'?macro?fmreg_hpos',nm_valid,fmreg_hpos);
      add_bank_position(temp_str+'?macro?fmreg_vpos',nm_valid,fmreg_vpos);
      add_bank_position(temp_str+'?macro?fmreg_left_margin',nm_valid,fmreg_left_margin);
      add_bank_position(temp_str+'?macro?fmreg_cursor_pos',nm_valid,fmreg_cursor_pos);

      Move(old_keys,mn_setting.terminate_keys,SizeOf(old_keys));
      mn_environment.ext_proc := old_external_proc;
      mn_setting.topic_len := old_topic_len;
      mn_setting.cycle_moves := old_cycle_moves;
      mn_setting.topic_mask_chr := old_topic_mask_chr;
      mn_setting.frame_enabled := old_frame_enabled;
      mn_setting.shadow_enabled := old_shadow_enabled;
      mn_environment.winshade := old_winshade;
      mn_setting.center_box := old_center_box;
      mn_setting.show_scrollbar := old_show_scrollbar;
      mn_setting.text_attr := old_text_attr;
      mn_setting.text2_attr := old_text2_attr;
      mn_setting.short_attr := old_short_attr;
      mn_setting.short2_attr := old_short2_attr;
      mn_setting.disbld_attr := old_disbld_attr;
      mn_setting.contxt_attr := old_contxt_attr;
      mn_setting.contxt2_attr := old_contxt2_attr;
      mn_setting.topic_attr := old_topic_attr;
      mn_setting.hi_topic_attr := old_hi_topic_attr;

      move_to_screen_data := ptr_screen_backup;
      move_to_screen_area[1] := xstart;
      move_to_screen_area[2] := ystart;
      move_to_screen_area[3] := xstart+window_xsize+2+1;
      move_to_screen_area[4] := ystart+window_ysize+1;
      move2screen;

      centered_frame_vdest := screen_ptr;
      If (mn_environment.keystroke = kESC) then
        GOTO _end;

      If (mn_environment.keystroke = kTAB) then
        begin
          songdata.instr_data[current_inst] := temp_songdata.instr_data[index];
          songdata.instr_macros[current_inst] := temp_songdata.instr_macros[index];
          songdata.dis_fmreg_col[current_inst] := temp_songdata.dis_fmreg_col[index];
          songdata.instr_names[current_inst] := Copy(songdata.instr_names[current_inst],1,9)+
                                                Copy(temp_songdata.instr_names[index],10,32);
          arp_tab_selected := songdata.instr_macros[current_inst].arpeggio_table <> 0;
          vib_tab_selected := songdata.instr_macros[current_inst].vibrato_table <> 0;
          loadMacros := FALSE;
          browser_flag := TRUE;
          GOTO _jmp1;
        end;

      If (mn_environment.keystroke = kF1) then
        begin
          HELP('macro_browser');
          If NOT _force_program_quit then GOTO _jmp2;
        end;
_jmp2e:
      If (mn_environment.keystroke = kENTER) or
         (loadBankPossible and (mn_environment.keystroke = kCtENTR)) then
        begin
          If (mn_environment.keystroke = kENTER) then
            begin
              songdata.instr_data[current_inst] := temp_songdata.instr_data[index];
              songdata.instr_macros[current_inst] := temp_songdata.instr_macros[index];
              songdata.dis_fmreg_col[current_inst] := temp_songdata.dis_fmreg_col[index];
              songdata.instr_names[current_inst] := Copy(songdata.instr_names[current_inst],1,9)+
                                                    Copy(temp_songdata.instr_names[index],10,32);
              idx1 := -1;
              idx2 := -1;
              If (songdata.instr_macros[current_inst].arpeggio_table <> 0) then
                idx1 := get_free_arpeggio_table_idx(temp_songdata.macro_table[
                                                    songdata.instr_macros[current_inst].arpeggio_table].arpeggio);
              If (songdata.instr_macros[current_inst].vibrato_table <> 0) then
                idx2 := get_free_vibrato_table_idx(temp_songdata.macro_table[
                                                   songdata.instr_macros[current_inst].vibrato_table].vibrato);
              temp_str := '';
              If (idx1 = 0) then
                If (idx2 = 0) then
                  temp_str := '~ARPEGGiO/ViBRATO'
                else temp_str := '~ARPEGGiO'
              else If (idx2 = 0) then
                     temp_str := '~ViBRATO';

              If NOT (temp_str <> '') then
                begin
                  If (idx1 > 0) then
                    begin
                      songdata.macro_table[idx1].arpeggio :=
                      temp_songdata.macro_table[songdata.instr_macros[current_inst].arpeggio_table].arpeggio;
                      songdata.instr_macros[current_inst].arpeggio_table := idx1;
                    end;
                  If (idx2 > 0) then
                    begin
                      songdata.macro_table[idx2].vibrato :=
                      temp_songdata.macro_table[songdata.instr_macros[current_inst].vibrato_table].vibrato;
                      songdata.instr_macros[current_inst].vibrato_table := idx2;
                    end
                end
              else Dialog('RELATED '+temp_str+' DATA~ WAS NOT LOADED!$'+
                          'FREE SOME SPACE iN MACRO TABLES AND ~REPEAT THiS ACTiON~$',
                          '~O~K$',' A2W LOADER ',1);
              load_flag := 1;
              load_flag_alt := BYTE_NULL;
            end
          else
            begin
              If bankSelector then
                index := Dialog('ALL UNSAVED iNSTRUMENT AND MACRO DATA WiLL BE LOST$'+
                                'DO YOU WiSH TO CONTiNUE?$',
                                '~Y~UP$~N~OPE$',' A2W LOADER ',1)
              else begin
                     index := 1;
                     dl_environment.keystroke := kENTER;
                   end;

              If (dl_environment.keystroke <> kESC) and (index = 1) then
                begin
                  temp_str := '';
                  For idx := 1 to 255 do
                    If NOT (idx > nm_valid) then
                      begin
                        songdata.instr_data[idx] := temp_songdata.instr_data[idx];
                        songdata.instr_macros[idx] := temp_songdata.instr_macros[idx];
                        songdata.dis_fmreg_col[idx] := temp_songdata.dis_fmreg_col[idx];
                        songdata.instr_names[idx] := Copy(songdata.instr_names[idx],1,9)+
                                                     Copy(temp_songdata.instr_names[idx],10,32);

                        idx1 := -1;
                        idx2 := -1;
                        If (songdata.instr_macros[idx].arpeggio_table <> 0) then
                          idx1 := get_free_arpeggio_table_idx(temp_songdata.macro_table[
                                                              songdata.instr_macros[idx].arpeggio_table].arpeggio);
                        If (songdata.instr_macros[idx].vibrato_table <> 0) then
                          idx2 := get_free_vibrato_table_idx(temp_songdata.macro_table[
                                                             songdata.instr_macros[idx].vibrato_table].vibrato);
                        If (temp_str = '') then
                          If (idx1 = 0) then
                            If (idx2 = 0) then
                              temp_str := '~ARPEGGiO/ViBRATO'
                            else temp_str := '~ARPEGGiO'
                          else If (idx2 = 0) then
                                 temp_str := '~ViBRATO';

                        If (idx1 > 0) then
                          begin
                            songdata.macro_table[idx1].arpeggio :=
                            temp_songdata.macro_table[songdata.instr_macros[idx].arpeggio_table].arpeggio;
                            songdata.instr_macros[idx].arpeggio_table := idx1;
                          end;
                        If (idx2 > 0) then
                          begin
                            songdata.macro_table[idx2].vibrato :=
                            temp_songdata.macro_table[songdata.instr_macros[idx].vibrato_table].vibrato;
                            songdata.instr_macros[idx].vibrato_table := idx2;
                          end;
                      end
                    else begin
                           FillChar(songdata.instr_data[idx],SizeOf(songdata.instr_data[idx]),0);
                           FillChar(songdata.instr_macros[idx],SizeOf(songdata.instr_macros[idx]),0);
                           FillChar(songdata.dis_fmreg_col[idx],SizeOf(songdata.dis_fmreg_col[idx]),0);
                           songdata.instr_names[idx] := Copy(songdata.instr_names[current_inst],1,9);
                         end;

                  If (temp_str <> '') then
                    Dialog('RELATED '+temp_str+' DATA~ WAS NOT LOADED!$'+
                           'FREE SOME SPACE iN MACRO TABLES AND ~REPEAT THiS ACTiON~$',
                           '~O~K$',' A2W LOADER ',1);
                  load_flag := 1;
                  load_flag_alt := BYTE_NULL;
                end;
            end;
        end;
      end;
_end:
  If browser_flag then GOTO _jmp2;
  arpvib_arpeggio_table := arpvib_arpeggio_table_bak;
  arpvib_vibrato_table := arpvib_vibrato_table_bak;
{$IFDEF __TMT__}
  keyboard_reset_buffer_alt;
{$ENDIF}
end;

procedure bnk_file_loader;

const
  _perc_voice: array[1..5] of String[2] = ('BD','SD','TT','TC','HH');

var
  f: File;
  header: tBNK_HEADER;
  temp: Longint;
  index: Word;
  old_external_proc: procedure;
  old_topic_len: Byte;
  old_cycle_moves: Boolean;
  xstart,ystart: Byte;
  nm_valid: Word;

procedure _restore;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:bnk_file_loader:_restore';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
end;

begin { bnk_file_loader }
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:bnk_file_loader';
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
             '~O~KAY$',' BNK LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,header,SizeOf(header),temp);
  If (temp <> SizeOf(header)) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' BNK LOADER ',1);
      EXIT;
    end;

  If NOT ((header.fver_major = 1) and (header.fver_minor = 0)) then
    begin
      CloseF(f);
      Dialog('UNKNOWN FiLE FORMAT VERSiON$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' BNK LOADER ',1);
      EXIT;
    end;

  If (header.signature <> bnk_id) or
     (header.total_entries < header.entries_used) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' BNK LOADER ',1);
      EXIT;
    end;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  dl_environment.context := ' ESC ฤ STOP ';
  centered_frame(xstart,ystart,43,3,' '+iCASE(NameOnly(instdata_source))+' ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);
  ShowStr(screen_ptr,xstart+43-Length(dl_environment.context),ystart+3,
          dl_environment.context,
          dialog_background+dialog_border);
  dl_environment.context := '';

  bnk_queue[1] := ' iNSTRUMENT                                  MELODiC/                   ';
  bnk_queue[2] := ' NAME         ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0    PERCUSSiON (VOiCE)         ';
  bnk_queue[3] := 'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ';

  progress_old_value := BYTE_NULL;
  progress_step := 40/max(header.total_entries,MAX_TIMBRES);
  progress_xstart := xstart+2;
  progress_ystart := ystart+2;

  ShowCStr(screen_ptr,xstart+2,ystart+1,
           'LOADiNG CONTENTS [RECORD ~'+
           ExpStrL(Num2str(0,10),5,'0')+'~ OF ~'+
           ExpStrL(Num2str(max(header.total_entries,MAX_TIMBRES),10),5,'0')+'~]',
           dialog_background+dialog_text,
           dialog_background+dialog_hi_text);

  show_progress(0);
  nm_valid := 0;
  bnk_skip := 0;

  For index := 1 to max(header.total_entries,MAX_TIMBRES) do
    begin
      If keypressed and (index > 1) then
        begin
          fkey := getkey;
          If (fkey = kESC) then
            begin
              Dec(index);
              BREAK;
            end;
        end;

      ShowCStr(screen_ptr,xstart+2+25,ystart+1,
               '~'+
               ExpStrL(Num2str(index,10),5,'0')+'~ OF ~'+
               ExpStrL(Num2str(max(header.total_entries,MAX_TIMBRES),10),5,'0')+'~]',
               dialog_background+dialog_text,
               dialog_background+dialog_hi_text);
      show_progress(index);

      SeekF(f,header.name_offset+PRED(index)*SizeOf(name_record));
      If (IOresult <> 0) then
        begin
          CloseF(f);
          _restore;
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' BNK LOADER ',1);
          EXIT;
        end;

      BlockReadF(f,name_record,SizeOf(name_record),temp);
      If (temp <> SizeOf(name_record)) then
        begin
          CloseF(f);
          _restore;
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' BNK LOADER ',1);
          EXIT;
        end;

      SeekF(f,header.data_offset+name_record.data_index*SizeOf(data_record));
      If (IOresult <> 0) then
        begin
          CloseF(f);
          _restore;
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' BNK LOADER ',1);
          EXIT;
        end;

      BlockReadF(f,data_record,SizeOf(data_record),temp);
      If (temp <> SizeOf(data_record)) then
        begin
          CloseF(f);
          _restore;
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' BNK LOADER ',1);
          EXIT;
        end;

      import_instrument_from_data_record;
      If name_record.usage_flag then
        begin
          bnk_queue[3+index-bnk_skip] := '~ ~~';
          Inc(nm_valid);
        end
      else
        begin
          If (nm_valid = 0) then
            begin
              Inc(bnk_skip);
              CONTINUE;
            end;
          bnk_queue[3+index-bnk_skip] := ' ';
        end;

      bnk_queue[3+index-bnk_skip] := bnk_queue[3+index-bnk_skip]+
        ExpStrR(CutStr(asciiz_string(name_record.ins_name)),11,' ')+'~  ';

      With temp_instrument.fm_data do
        begin
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(AM_VIB_EG_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(AM_VIB_EG_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(KSL_VOLUM_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(KSL_VOLUM_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(ATTCK_DEC_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(ATTCK_DEC_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(SUSTN_REL_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(SUSTN_REL_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(WAVEFORM_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(WAVEFORM_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(FEEDBACK_FM)+'    ';
        end;

      Case data_record.mode of
        0: bnk_queue[3+index-bnk_skip] :=
             bnk_queue[3+index-bnk_skip]+'MELODiC';
        1: Case data_record.voice_num of
             6..10: bnk_queue[3+index-bnk_skip] :=
                      bnk_queue[3+index-bnk_skip]+'PERCUSSiON ('+
                      _perc_voice[data_record.voice_num-5]+')';
             else bnk_queue[3+index-bnk_skip] :=
                    bnk_queue[3+index-bnk_skip]+'PERCUSSiON (??)';
           end;
        else
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+'???';
      end;
    end;

  CloseF(f);
  _restore;
  If (nm_valid = 0) then EXIT;

  If (index = header.total_entries) and
     (bnk_skip = 0) then
    mn_environment.context := '~[~'+Num2str(nm_valid,10)+'~/'+
                                    Num2str(index,10)+']~'
  else
    mn_environment.context := '['+Num2str(nm_valid,10)+']~['+
                                  Num2str(index,10)+'/'+
                                  Num2str(header.total_entries,10)+']~';

  old_external_proc := mn_environment.ext_proc;
  old_topic_len := mn_setting.topic_len;
  old_cycle_moves := mn_setting.cycle_moves;
  mn_environment.ext_proc := bnk_lister_external_proc;
  mn_setting.topic_len := 3;
  mn_setting.cycle_moves := FALSE;

  keyboard_reset_buffer;
  If NOT _force_program_quit then
    index := Menu(bnk_queue,01,01,min(1,get_bank_position(instdata_source,nm_valid)),
                  72,20,nm_valid+3,' '+iCASE(NameOnly(instdata_source))+' ');

  add_bank_position(instdata_source,nm_valid,index+3);
  mn_environment.ext_proc := old_external_proc;
  mn_setting.topic_len := old_topic_len;
  mn_setting.cycle_moves := old_cycle_moves;

  If (mn_environment.keystroke = kENTER) then
    begin
      load_flag := 1;
      load_flag_alt := BYTE_NULL;
      bnk_file_loader_alt(bnk_skip+index);
      If (load_flag_alt <> BYTE_NULL) then
        begin
          songdata.instr_data[current_inst] := temp_instrument;
          songdata.instr_names[current_inst] :=
            Copy(songdata.instr_names[current_inst],1,9)+
            Copy(bnk_queue[3+index],5,8);
        end;
    end;
end;

procedure fib_file_loader;

const
  id = 'FIB'+#$f4;

var
  f: File;
  ident: array[1..4] of Char;
  header: tFIB_HEADER;
  temp: Longint;
  index: Word;
  old_external_proc: procedure;
  old_topic_len: Byte;
  old_cycle_moves: Boolean;
  xstart,ystart: Byte;
  instrument_data: tFIN_DATA;
  nm_valid: Word;

procedure _restore;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:fib_file_loader:_restore';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
end;

begin { fib_file_loader }
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:fib_file_loader';
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
             '~O~KAY$',' FiB LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,header,SizeOf(header),temp);
  If (temp <> SizeOf(header)) or
     (header.ident <> id) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' FiB LOADER ',1);
      EXIT;
    end;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  dl_environment.context := ' ESC ฤ STOP ';
  centered_frame(xstart,ystart,43,3,' '+iCASE(NameOnly(instdata_source))+' ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);
  ShowStr(screen_ptr,xstart+43-Length(dl_environment.context),ystart+3,
          dl_environment.context,
          dialog_background+dialog_border);
  dl_environment.context := '';

  bnk_queue[1] := ' DOS       iNSTRUMENT                                                   ';
  bnk_queue[2] := ' NAME      NAME                          ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0    ';
  bnk_queue[3] := 'ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ';

  progress_old_value := BYTE_NULL;
  progress_step := 40/max(header.nmins,MAX_TIMBRES);
  progress_xstart := xstart+2;
  progress_ystart := ystart+2;

  ShowCStr(screen_ptr,xstart+2,ystart+1,
           'LOADiNG CONTENTS [RECORD ~'+
           ExpStrL(Num2str(0,10),5,'0')+'~ OF ~'+
           ExpStrL(Num2str(max(header.nmins,MAX_TIMBRES),10),5,'0')+'~]',
           dialog_background+dialog_text,
           dialog_background+dialog_hi_text);

  show_progress(0);
  nm_valid := 0;
  bnk_skip := 0;

  For index := 1 to max(header.nmins,MAX_TIMBRES) do
    begin
      If keypressed and (index > 1) then
        begin
          fkey := getkey;
          If (fkey = kESC) then
            begin
              Dec(index);
              BREAK;
            end;
        end;

      ShowCStr(screen_ptr,xstart+2+25,ystart+1,
               '~'+
               ExpStrL(Num2str(index,10),5,'0')+'~ OF ~'+
               ExpStrL(Num2str(max(header.nmins,MAX_TIMBRES),10),5,'0')+'~]',
               dialog_background+dialog_text,
               dialog_background+dialog_hi_text);
      show_progress(index);

      BlockReadF(f,instrument_data,SizeOf(instrument_data),temp);
      If (temp <> SizeOf(instrument_data)) then
        begin
          CloseF(f);
          _restore;
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' FiB LOADER ',1);
          EXIT;
        end;

      import_standard_instrument_alt(instrument_data.idata);
      If NOT Empty(instrument_data.idata,SizeOf(instrument_data.idata)) then
        begin
          bnk_queue[3+index-bnk_skip] := '~ ~~';
          Inc(nm_valid);
        end
      else
        begin
          If (nm_valid = 0) then
            begin
              Inc(bnk_skip);
              CONTINUE;
            end;
          bnk_queue[3+index-bnk_skip] := ' ';
        end;

      bnk_queue[3+index-bnk_skip] := bnk_queue[3+index-bnk_skip]+
        ExpStrR(Upper(CutStr(BaseNameOnly(instrument_data.dname))),8,' ')+'~  ';
      bnk_queue[3+index-bnk_skip] := bnk_queue[3+index-bnk_skip]+
        ExpStrR(CutStr(instrument_data.iname),27,' ')+'   ';

      With temp_instrument.fm_data do
        begin
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(AM_VIB_EG_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(AM_VIB_EG_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(KSL_VOLUM_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(KSL_VOLUM_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(ATTCK_DEC_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(ATTCK_DEC_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(SUSTN_REL_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(SUSTN_REL_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(WAVEFORM_carrier);
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(WAVEFORM_modulator)+' ';
          bnk_queue[3+index-bnk_skip] :=
            bnk_queue[3+index-bnk_skip]+byte2hex(FEEDBACK_FM)+'  ';
        end;
    end;

  SeekF(f,SizeOf(header)+header.nmins*SizeOf(instrument_data));
  If (IOresult <> 0) then
    begin
      CloseF(f);
      _restore;
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' FiB LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,ident,SizeOf(ident),temp);
  If (temp <> SizeOf(ident)) or
     (ident <> id) then
    begin
      CloseF(f);
      _restore;
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' FiB LOADER ',1);
      EXIT;
    end;

  CloseF(f);
  _restore;

  If (nm_valid = 0) then EXIT;
  If (index = header.nmins) and (bnk_skip = 0) then
    mn_environment.context := '~[~'+Num2str(nm_valid,10)+'~/'+
                                    Num2str(index,10)+']~'
  else
    mn_environment.context := '['+Num2str(nm_valid,10)+']~['+
                                  Num2str(index,10)+'/'+
                                  Num2str(128,10)+']~';

  old_external_proc := mn_environment.ext_proc;
  old_topic_len := mn_setting.topic_len;
  old_cycle_moves := mn_setting.cycle_moves;
  mn_environment.ext_proc := fib_lister_external_proc;
  mn_setting.topic_len := 3;
  mn_setting.cycle_moves := FALSE;

  keyboard_reset_buffer;
  If NOT _force_program_quit then
    index := Menu(bnk_queue,01,01,min(1,get_bank_position(instdata_source,nm_valid)),
                  72,20,nm_valid+3,' '+iCASE(NameOnly(instdata_source))+' ');

  add_bank_position(instdata_source,nm_valid,index+3);
  mn_environment.ext_proc := old_external_proc;
  mn_setting.topic_len := old_topic_len;
  mn_setting.cycle_moves := old_cycle_moves;

  If (mn_environment.keystroke = kENTER) then
    begin
      load_flag := 1;
      load_flag_alt := BYTE_NULL;
      fib_file_loader_alt(index+bnk_skip);
      If (load_flag_alt <> BYTE_NULL) then
        begin
          songdata.instr_data[current_inst] := temp_instrument;
          If (CutStr(Copy(bnk_queue[3+index],16,27)) <> '') then
            songdata.instr_names[current_inst] :=
              Copy(songdata.instr_names[current_inst],1,9)+
              Copy(bnk_queue[3+index],16,27)
          else
            songdata.instr_names[current_inst] :=
              Copy(songdata.instr_names[current_inst],1,9)+
              Copy(bnk_queue[3+index],5,8)
        end;
    end;
end;

procedure ibk_file_loader;

const
  id = 'IBK'+#$1a;

var
  f: File;
  header: array[1..4] of Char;
  temp: Longint;
  index: Word;
  old_external_proc: procedure;
  old_topic_len: Byte;
  old_cycle_moves: Boolean;
  xstart,ystart: Byte;
  nm_valid: Word;
  instrument_name: array[1..9] of Char;
  instrument_data: Record
                     idata: tFM_INST_DATA;
                     dummy: array[1..5] of Byte;
                   end;

procedure _restore;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:ibk_file_loader:_restore';
{$ENDIF}
  move_to_screen_data := ptr_screen_backup;
  move_to_screen_area[1] := xstart;
  move_to_screen_area[2] := ystart;
  move_to_screen_area[3] := xstart+43+2+1;
  move_to_screen_area[4] := ystart+3+1;
  move2screen;
end;

begin { ibk_file_loader }
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:ibk_file_loader';
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
             '~O~KAY$',' iBK LOADER ',1);
      EXIT;
    end;

  BlockReadF(f,header,SizeOf(header),temp);
  If (temp <> SizeOf(header)) or
     (header <> id) then
    begin
      CloseF(f);
      Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
             'LOADiNG STOPPED$',
             '~O~KAY$',' iBK LOADER ',1);
      EXIT;
    end;

  ScreenMemCopy(screen_ptr,ptr_screen_backup);
  dl_environment.context := ' ESC ฤ STOP ';
  centered_frame(xstart,ystart,43,3,' '+iCASE(NameOnly(instdata_source))+' ',
                 dialog_background+dialog_border,
                 dialog_background+dialog_title,double);
  ShowStr(screen_ptr,xstart+43-Length(dl_environment.context),ystart+3,
          dl_environment.context,
          dialog_background+dialog_border);
  dl_environment.context := '';

  ibk_queue[1] := ' iNSTRUMENT                                 ';
  ibk_queue[2] := ' NAME         ฺ20ฟ ฺ40ฟ ฺ60ฟ ฺ80ฟ ฺE0ฟ C0   ';
  ibk_queue[3] := 'ออออออออออออออออออออออออออออออออออออออออออออ';

  progress_old_value := BYTE_NULL;
  progress_step := 40/128;
  progress_xstart := xstart+2;
  progress_ystart := ystart+2;

  ShowCStr(screen_ptr,xstart+2,ystart+1,
           'LOADiNG CONTENTS [RECORD ~'+
           ExpStrL(Num2str(0,10),5,'0')+'~ OF ~'+
           ExpStrL(Num2str(128,10),5,'0')+'~]',
           dialog_background+dialog_text,
           dialog_background+dialog_hi_text);

  show_progress(0);
  nm_valid := 0;
  ibk_skip := 0;

  For index := 1 to 128 do
    begin
      If keypressed and (index > 1) then
        begin
          fkey := getkey;
          If (fkey = kESC) then
            begin
              Dec(index);
              BREAK;
            end;
        end;

      ShowCStr(screen_ptr,xstart+2+25,ystart+1,
               '~'+
               ExpStrL(Num2str(index,10),5,'0')+'~ OF ~'+
               ExpStrL(Num2str(128,10),5,'0')+'~]',
               dialog_background+dialog_text,
               dialog_background+dialog_hi_text);
      show_progress(index);

      SeekF(f,$004+PRED(index)*SizeOf(instrument_data));
      If (IOresult <> 0) then
        begin
          CloseF(f);
          _restore;
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' iBK LOADER ',1);
          EXIT;
        end;

      BlockReadF(f,instrument_data,SizeOf(instrument_data),temp);
      If (temp <> SizeOf(instrument_data)) then
        begin
          CloseF(f);
          _restore;
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' iBK LOADER ',1);
          EXIT;
        end;

      SeekF(f,$804+PRED(index)*SizeOf(instrument_name));
      If (IOresult <> 0) then
        begin
          CloseF(f);
          _restore;
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' iBK LOADER ',1);
          EXIT;
        end;

      BlockReadF(f,instrument_name,SizeOf(instrument_name),temp);
      If (temp <> SizeOf(instrument_name)) then
        begin
          CloseF(f);
          _restore;
          Dialog('ERROR READiNG DATA - FiLE CORRUPTED$'+
                 'LOADiNG STOPPED$',
                 '~O~KAY$',' iBK LOADER ',1);
          EXIT;
        end;

      import_sbi_instrument_alt(instrument_data);
      If NOT Empty(instrument_data,SizeOf(instrument_data)) then
        begin
          ibk_queue[3+index-ibk_skip] := '~ ~~';
          Inc(nm_valid);
        end
      else
        begin
          If (nm_valid = 0) then
            begin
              Inc(ibk_skip);
              CONTINUE;
            end;
          ibk_queue[3+index-ibk_skip] := ' ';
        end;

      ibk_queue[3+index-ibk_skip] := ibk_queue[3+index-ibk_skip]+
        ExpStrR(CutStr(asciiz_string(instrument_name)),11,' ')+'~  ';

      With temp_instrument.fm_data do
        begin
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(AM_VIB_EG_carrier);
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(AM_VIB_EG_modulator)+' ';
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(KSL_VOLUM_carrier);
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(KSL_VOLUM_modulator)+' ';
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(ATTCK_DEC_carrier);
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(ATTCK_DEC_modulator)+' ';
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(SUSTN_REL_carrier);
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(SUSTN_REL_modulator)+' ';
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(WAVEFORM_carrier);
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(WAVEFORM_modulator)+' ';
          ibk_queue[3+index-ibk_skip] :=
            ibk_queue[3+index-ibk_skip]+byte2hex(FEEDBACK_FM)+'  ';
        end;
    end;

  CloseF(f);

  _restore;

  If (nm_valid = 0) then EXIT;
  If (index = 128) and (ibk_skip = 0) then
    mn_environment.context := '~[~'+Num2str(nm_valid,10)+'~/'+
                                    Num2str(index,10)+']~'
  else
    mn_environment.context := '['+Num2str(nm_valid,10)+']~['+
                                  Num2str(index,10)+'/'+
                                  Num2str(128,10)+']~';

  old_external_proc := mn_environment.ext_proc;
  old_topic_len := mn_setting.topic_len;
  old_cycle_moves := mn_setting.cycle_moves;
  mn_environment.ext_proc := ibk_lister_external_proc;
  mn_setting.topic_len := 3;
  mn_setting.cycle_moves := FALSE;

  keyboard_reset_buffer;
  If NOT _force_program_quit then
    index := Menu(ibk_queue,01,01,min(1,get_bank_position(instdata_source,nm_valid)),
                  45,20,nm_valid+3,' '+iCASE(NameOnly(instdata_source))+' ');

  add_bank_position(instdata_source,nm_valid,index+3);
  mn_environment.ext_proc := old_external_proc;
  mn_setting.topic_len := old_topic_len;
  mn_setting.cycle_moves := old_cycle_moves;

  If (mn_environment.keystroke = kENTER) then
    begin
      load_flag := 1;
      load_flag_alt := BYTE_NULL;
      ibk_file_loader_alt(index+ibk_skip);
      If (load_flag_alt <> BYTE_NULL) then
        begin
          songdata.instr_data[current_inst] := temp_instrument;
          songdata.instr_names[current_inst] :=
            Copy(songdata.instr_names[current_inst],1,9)+
            Copy(ibk_queue[3+index],5,8);
        end;
    end;
end;

function get_bank_position(bank_name: String; bank_size: Longint): Longint;

var
  idx: Longint;
  result: Longint;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:get_bank_position';
{$ENDIF}
  result := 0;
  bank_name := CutStr(Upper_filename(bank_name));
  For idx := 1 to bank_position_list_size do
    If (bank_position_list[idx].bank_name = bank_name) and
       ((bank_position_list[idx].bank_size = bank_size) or
        (bank_size = -1)) then
      begin
        result := bank_position_list[idx].bank_position;
        BREAK;
      end;
  get_bank_position := result;
end;

procedure add_bank_position(bank_name: String; bank_size: Longint; bank_position: Longint);

var
  idx,idx2: Longint;
  found_flag: Boolean;

begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2EXT3.PAS:add_bank_position';
{$ENDIF}
  found_flag := FALSE;
  bank_name := CutStr(Upper_filename(bank_name));
  For idx := 1 to bank_position_list_size do
    If (bank_position_list[idx].bank_name = bank_name) and
       ((bank_position_list[idx].bank_size = bank_size) or
        (bank_size = -1)) then
      begin
        found_flag := TRUE;
        idx2 := idx;
        BREAK;
      end;

  If found_flag then
    begin
      bank_position_list[idx2].bank_position := bank_position;
      EXIT;
    end;

  If (bank_position_list_size < MAX_NUM_BANK_POSITIONS) then
    Inc(bank_position_list_size)
  else
    begin
      bank_position_list_size := MAX_NUM_BANK_POSITIONS;
      For idx := 1 to PRED(bank_position_list_size) do
        bank_position_list[idx] := bank_position_list[idx+1];
    end;

  bank_position_list[bank_position_list_size].bank_name := bank_name;
  bank_position_list[bank_position_list_size].bank_size := bank_size;
  bank_position_list[bank_position_list_size].bank_position := bank_position;
end;

end.
