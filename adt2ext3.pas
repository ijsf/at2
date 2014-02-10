unit AdT2ext3;
{$PACKRECORDS 1}
interface

procedure a2m_file_loader;
procedure a2t_file_loader;
procedure a2p_file_loader;
procedure a2i_file_loader;
procedure a2f_file_loader;
procedure a2b_file_loader;
procedure a2w_file_loader(loadMacros: Boolean);
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

implementation

uses
  DOS,
  AdT2sys,AdT2vscr,AdT2opl3,AdT2keyb,AdT2unit,AdT2extn,AdT2text,AdT2apak,
  StringIO,DialogIO,ParserIO,DepackIO,TxtScrIO;

{$i iloadins.inc}
{$i iloaders.inc}

end.
