unit AdT2apak;
{$PACKRECORDS 1}
interface

function APACK_compress(var input,output; size: Longint): Longint;
function APACK_decompress(var input,output): Longint;

implementation

uses
  AdT2extn,AdT2unit;

const
  AP_PACK_CONTINUE = 1;
  AP_PACK_BREAK    = 0;

type
  tWORKMEM_TYPE = array[0..PRED(640*1024)] of Byte;

var
  workmem: tWORKMEM_TYPE;
  
{$L aplib.o}
function aP_pack(var input, output; size: Longint; workmem: tWORKMEM_TYPE; status: Pointer): Longint; stdcall; external name '_aP_pack';
function aP_depack(var input, output): Longint; stdcall; external name '_aP_depack';

function callback(param1,param2: Longint): Longint; cdecl;
begin
	asm pushad end;
	show_progress(param1);
	asm popad end;
	callback := AP_PACK_CONTINUE;
end;

function APACK_compress(var input,output; size: Longint): Longint;
begin
  progress_old_value := NULL;
  progress_step := 40/size;
  FillChar(workmem, SizeOf(workmem), 0);
  APACK_compress := aP_pack(input, output, size, workmem, @callback);
end;

function APACK_decompress(var input,output): Longint;
begin
	APACK_decompress := aP_depack(input, output);
end;

end.
