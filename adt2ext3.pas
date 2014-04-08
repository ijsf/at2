unit AdT2ext3;
{$PACKRECORDS 1}
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

function  get_bank_position(bank_name: String; bank_size: Longint): Longint;
procedure add_bank_position(bank_name: String; bank_size: Longint; bank_position: Longint);

implementation

uses
  DOS,
  AdT2sys,AdT2vscr,AdT2opl3,AdT2keyb,AdT2unit,
  AdT2extn,AdT2text,AdT2apak,AdT2ext2,
  StringIO,DialogIO,ParserIO,DepackIO,TxtScrIO;

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
                                        
function get_bank_position(bank_name: String; bank_size: Longint): Longint;

var
  idx: Longint;
  result: Longint;
  
begin
  result := 0;
  bank_name := CutStr(Upper(bank_name));
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
  idx: Longint;
  found_flag: Boolean;
  
begin
  found_flag := FALSE;
  bank_name := CutStr(Upper(bank_name));
  For idx := 1 to bank_position_list_size do
    If (bank_position_list[idx].bank_name = bank_name) and
       ((bank_position_list[idx].bank_size = bank_size) or
        (bank_size = -1)) then
      begin
        found_flag := TRUE;
        BREAK;
      end;
  If found_flag then
    begin
      bank_position_list[idx].bank_position := bank_position;
      EXIT;
    end;    
  If (bank_position_list_size+1 <= MAX_NUM_BANK_POSITIONS) then
    Inc(bank_position_list_size)
  else
    For idx := 1 to bank_position_list_size-1 do
      bank_position_list[idx] := bank_position_list[idx+1];

  bank_position_list[bank_position_list_size].bank_name := bank_name;
  bank_position_list[bank_position_list_size].bank_size := bank_size;
  bank_position_list[bank_position_list_size].bank_position := bank_position;
end;
 
var
  xstart_arp,ystart_arp,xstart_vib,ystart_vib: Byte;
  scrollbar_xstart,scrollbar_ystart,scrollbar_size: Byte;
  macro_table_size: Byte;
  arpeggio_table_idx,vibrato_table_idx: Byte;
  arpeggio_table_pos,vibrato_table_pos: Byte;
 
procedure a2w_macro_lister_external_proc_callback; forward;
 
{$i iloadins.inc}
{$i iloaders.inc}

end.
