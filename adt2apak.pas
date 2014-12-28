unit AdT2apak;
{$IFDEF __TMT__}
{$S-,Q-,R-,V-,B-,X+}
{$ELSE}
{$PACKRECORDS 1}
{$ENDIF}
interface

function APACK_compress(var input,output; size: Longint): Longint;
function APACK_decompress(var input,output): Longint;

implementation

uses
  AdT2sys,AdT2extn,AdT2unit;

const
  AP_PACK_CONTINUE = 1;
  AP_PACK_BREAK    = 0;

type
  tWORKMEM_TYPE = array[0..PRED(640*1024)] of Byte;

var
  workmem: tWORKMEM_TYPE;

{$IFDEF __TMT__}

{$L aplib.obj}
function _aP_pack: Longint; external;
function _aP_depack: Longint; external;

{$ELSE}

{$L aplib.o}
function aP_pack(var input, output; size: Longint; workmem: tWORKMEM_TYPE; status: Pointer): Longint; stdcall; external name '_aP_pack';
function aP_depack(var input, output): Longint; stdcall; external name '_aP_depack';

{$ENDIF}

{$IFDEF __TMT__}

function callback: Longint; assembler;
asm
        pushad
        push    dword [ebp+08h]
        call    show_progress
        popad
        mov     eax,AP_PACK_CONTINUE
end;

function aP_pack(var input,output; size: Longint; workmem: tWORKMEM_TYPE;
                 status: Pointer): Longint; assembler;
asm
        push    status
        push    workmem
        push    size
        push    output
        push    input
        call    _aP_pack
end;

{$ELSE}

function callback(param1,param2: Longint): Longint; cdecl;
begin
  asm pushad end;
  show_progress(param1);
  asm popad end;
  callback := AP_PACK_CONTINUE;
end;

{$ENDIF}

function APACK_compress(var input,output; size: Longint): Longint;
begin
{$IFDEF __TMT__}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2APAK.PAS:APACK_compress';
{$ENDIF}
  progress_old_value := BYTE_NULL;
  progress_step := 40/size;
  FillChar(workmem,SizeOf(workmem),0);
  APACK_compress := aP_pack(input,output,size,workmem,@callback);
end;

{$IFDEF __TMT__}

function APACK_decompress(var input,output): Longint; assembler;
asm
        push    output
        push    input
        call    _aP_depack
end;

{$ELSE}

function APACK_decompress(var input,output): Longint;
begin
  _debug_str_ := 'ADT2APAK.PAS:APACK_decompress';
  APACK_decompress := aP_depack(input, output);
end;

{$ENDIF}

end.
