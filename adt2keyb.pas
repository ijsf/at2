unit AdT2keyb;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

{$IFDEF GO32V2}
{$MODE FPC}

const
  keyboard_sleep: Boolean = FALSE;
  CTRL_ALT_DEL_pressed: Boolean = FALSE;
  _ctrl_pressed: Boolean = FALSE;
  _2x_ctrl_pressed: Boolean = FALSE;

{$ENDIF}

procedure keyboard_init;
procedure keyboard_done;
procedure keyboard_reset_buffer;
procedure wait_until_F11_F12_released;
procedure keyboard_poll_input;
function  keypressed: Boolean;
function  getkey: Word;
function  scankey(scancode: Byte): Boolean;
function  CapsLock: Boolean;
function  NumLock: Boolean;
function  shift_pressed: Boolean;
function  left_shift_pressed: Boolean;
function  right_shift_pressed: Boolean;
function  alt_pressed: Boolean;
function  ctrl_pressed: Boolean;
function  ctrl_tab_pressed: Boolean;
function  LookUpKey(key: Word; var table; size: Byte): Boolean;
procedure screen_saver;

{$IFDEF GO32V2}

procedure keyboard_reset_buffer_alt;
procedure keyboard_toggle_sleep;
function  ScrollLock: Boolean;
function  both_shifts_pressed: Boolean;

{$ENDIF}

implementation

uses
{$IFNDEF UNIX}
  CRT,
{$ENDIF}
  DOS,
{$IFDEF GO32V2}
  GO32,
{$ELSE}
  SDL_Types,SDL_Timer,SDL_Events,SDL_Keyboard,
{$ENDIF}
  AdT2unit,AdT2sys,AdT2ext2,
  TxtScrIO,DialogIO,ParserIO;

var
{$IFDEF GO32V2}
  keydown: array[0..127] of Boolean;
{$ELSE}
  keydown: array[0..255] of Boolean;
{$ENDIF}

{$IFDEF GO32V2}

var
  oldint09_handler: tSegInfo;
  newint09_handler: tSegInfo;
  user_proc_ptr: Pointer;
  backupDS_adt2keyb: Word; EXTERNAL NAME '___v2prt0_ds_alias';

procedure newint09_proc; assembler;
asm
        cli
        push    ds
        push    es
        push    fs
        push    gs
        pushad
        mov     ax,cs:[backupDS_adt2keyb]
        mov     ds,ax
        mov     es,ax
        mov     ax,DosMemSelector
        mov     fs,ax
        call    dword ptr [user_proc_ptr]
        popad
        pop     gs
        pop     fs
        pop     es
        pop     ds
        jmp     cs:[oldint09_handler]
end;

procedure newint09_proc_end; begin end;

procedure int09_user_proc; forward;
procedure int09_user_proc_end; forward;

{$ELSE}

const
  _numlock:  Boolean = FALSE;
  _capslock: Boolean = FALSE;

var
  keystate: ^BoolArray;
  varnum: Longint;

{$ENDIF}

procedure keyboard_init;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2KEYB.PAS:keyboard_init';
  FillChar(keydown,SizeOf(keydown),FALSE);
  user_proc_ptr := @int09_user_proc;
  lock_data(user_proc_ptr,SizeOf(user_proc_ptr));
  lock_data(DosMemSelector,SizeOf(DosMemSelector));
  lock_code(@int09_user_proc,DWORD(@int09_user_proc_end)-DWORD(@int09_user_proc));
  lock_code(@newint09_proc,DWORD(@newint09_proc_end)-DWORD(@newint09_proc));
  newint09_handler.offset := @newint09_proc;
  newint09_handler.segment := get_cs;
  get_pm_interrupt($09,oldint09_handler);
  set_pm_interrupt($09,newint09_handler);
{$ELSE}
  SDL_EnableKeyRepeat(sdl_typematic_delay,sdl_typematic_rate);
  keystate := SDL_GetKeyState(varnum);
{$ENDIF}
end;

procedure keyboard_done;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2KEYB.PAS:keyboard_done';
  set_pm_interrupt($09,oldint09_handler);
  unlock_data(DosMemSelector,SizeOf(DosMemSelector));
  unlock_data(user_proc_ptr,SizeOf(user_proc_ptr));
  unlock_code(@int09_user_proc,DWORD(@int09_user_proc_end)-DWORD(@int09_user_proc));
  lock_code(@newint09_proc,DWORD(@newint09_proc_end)-DWORD(@newint09_proc));
  keyboard_reset_buffer;
{$ENDIF}
end;

{$IFDEF GO32V2}

function keypressed: Boolean;
begin
  realtime_gfx_poll_proc;
  draw_screen;
  // filter out CTRL+TAB combo as it is handled within timer routine
  If ctrl_tab_pressed then
    begin
      keyboard_reset_buffer;
      keypressed := FALSE;
    end
  else keypressed := CRT.KeyPressed;
end;

function getkey: Word;

var
  result: Word;
  key_c,scan_c: Byte;

begin
  no_status_refresh := FALSE;
  While NOT keypressed do
    begin
      realtime_gfx_poll_proc;
      draw_screen;
      If (seconds_counter >= ssaver_time) then screen_saver;
    end;
  key_c := BYTE(CRT.ReadKey);
  If (key_c = 0) then result := BYTE(CRT.ReadKey) SHL 8
  else begin
         scan_c := inportb($60);
         If (scan_c > $80) then scan_c := scan_c-$80;
         result := key_c+(scan_c SHL 8);
       end;
  getkey := result;
end;

function scankey(scancode: Byte): Boolean;
begin
  scankey := keydown[scancode];
end;

{$ASMMODE INTEL}

procedure int09_user_proc; assembler;
asm
        push    eax
        push    ebx
        push    es
        push    ds
        call    process_global_keys
        pop     ds
        pop     es
        mov     dword ptr [seconds_counter],0
        in      al,60h
        xor     ebx,ebx
        mov     bx,ax
        and     bx,007fh
        and     al,80h
        jz      @@4
@@1:    mov     byte ptr keydown[ebx],0
        cmp     ebx,1dh // [Ctrl]
        jnz     @@3
        cmp     byte ptr [_ctrl_pressed],1
        jnz     @@2
        mov     byte ptr [_2x_ctrl_pressed],1
@@2:    mov     byte ptr [_ctrl_pressed],1
@@3:    jmp     @@5
@@4:    mov     byte ptr keydown[ebx],1
        cmp     ebx,1dh // [Ctrl]
        jz      @@5
        mov     byte ptr [_ctrl_pressed],0
        mov     byte ptr [_2x_ctrl_pressed],0
@@5:    cmp     keyboard_sleep,1
        jz      @@10
        cmp     byte ptr keydown[1dh],1 // [Ctrl]
        jnz     @@6
        cmp     byte ptr keydown[38h],1 // [Alt]
        jnz     @@6
        cmp     byte ptr keydown[4ah],1 // *[-]
        jz      @@10
        cmp     byte ptr keydown[4eh],1 // *[+]
        jz      @@10
@@6:    cmp     byte ptr keydown[1dh],1 // [Ctrl]
        jnz     @@7
        cmp     byte ptr keydown[38h],1 // [Alt]
        jnz     @@7
        cmp     byte ptr keydown[53h],1 // [Del]
        jz      @@9
@@7:    cmp     byte ptr keydown[1dh],1 // [Ctrl]
        jnz     @@8
        cmp     byte ptr keydown[02h],1 // *[1]
        jz      @@10
        cmp     byte ptr keydown[03h],1 // *[2]
        jz      @@10
        cmp     byte ptr keydown[04h],1 // *[3]
        jz      @@10
        cmp     byte ptr keydown[05h],1 // *[4]
        jz      @@10
        cmp     byte ptr keydown[06h],1 // *[5]
        jz      @@10
        cmp     byte ptr keydown[07h],1 // *[6]
        jz      @@10
        cmp     byte ptr keydown[08h],1 // *[7]
        jz      @@10
        cmp     byte ptr keydown[09h],1 // *[8]
        jz      @@10
@@8:    jmp     @@11
@@9:    mov     CTRL_ALT_DEL_pressed,1
@@10:   in      al,61h
        mov     ah,al
        or      al,80h
        out     61h,al
        xchg    ah,al
        out     61h,al
        mov     al,20h
        out     20h,al
        pop     ebx
        pop     eax
        jmp     @@12
@@11:   pop     ebx
        pop     eax
@@12:
end;

procedure int09_user_proc_end; begin end;

procedure keyboard_toggle_sleep;
begin
  keyboard_sleep := NOT keyboard_sleep;
end;

procedure keyboard_reset_buffer;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2KEYB.PAS:keyboard_reset_buffer';
{$ENDIF}
  MEMW[0:$041c] := MEMW[0:$041a];
end;

procedure keyboard_reset_buffer_alt;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2KEYB.PAS:keyboard_reset_buffer_alt';
{$ENDIF}
  If (MEMW[0:$041c]-MEMW[0:$041a] > 5) then
    MEMW[0:$041c] := MEMW[0:$041a];
end;

procedure wait_until_F11_F12_released;
begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2KEYB.PAS:wait_until_key_released';
{$ENDIF}
  Repeat
    realtime_gfx_poll_proc;
    draw_screen;
    keyboard_reset_buffer;
    If (inportb($60) > $80) then FillChar(keydown,SizeOf(keydown),0);
  until NOT keydown[$57] and NOT keydown[$58];
end;

procedure keyboard_poll_input;
begin
  // relevant for SDL version only
end;

var
  temp_buf: array[1..32,1..255] of Record
                                     r,g,b: Byte;
                                   end;
procedure screen_saver;

procedure fadeout;

var
  r,g,b: Byte;
  index: Byte;
  depth: Byte;

function min0(val: Integer): Integer;
begin
  If (val <= 0) then min0 := 0
  else min0 := val;
end;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2KEYB.PAS:screen_saver:fadeout';
{$ENDIF}
  For depth := 1 to 32 do
    begin
      For index := 1 to 255 do
        begin
          GetRGBitem(index,r,g,b);
          temp_buf[depth][index].r := r;
          temp_buf[depth][index].g := g;
          temp_buf[depth][index].b := b;
          SetRGBitem(index,min0(r-1),min0(g-1),min0(b-1));
        end;
      WaitRetrace;
      realtime_gfx_poll_proc;
      If (depth MOD 4 = 0) then draw_screen;
      keyboard_reset_buffer;
    end;
end;

procedure fadein;

var
  index: Byte;
  depth: Byte;


begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2KEYB.PAS:screen_saver:fadein';
{$ENDIF}
  For depth := 32 downto 1 do
    begin
      For index := 1 to 255 do
        SetRGBitem(index,temp_buf[depth][index].r,
                         temp_buf[depth][index].g,
                         temp_buf[depth][index].b);
      If (depth MOD 4 <> 0) then WaitRetrace;
      realtime_gfx_poll_proc;
      If (depth MOD 4 = 0) then draw_screen;
      keyboard_reset_buffer;
    end;
end;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'ADT2KEYB.PAS:screen_saver';
{$ENDIF}
  If (ssaver_time = 0) then EXIT;
  fadeout;
  Repeat
    realtime_gfx_poll_proc;
    draw_screen;
  until (seconds_counter = 0);
  fadein;
end;

var
  keyboard_flag: Byte ABSOLUTE 0:$0417;

function CapsLock: Boolean;
begin
  CapsLock := (keyboard_flag OR $40 = keyboard_flag);
end;

function NumLock: Boolean;
begin
  NumLock := (keyboard_flag OR $20 = keyboard_flag);
end;

function ScrollLock: Boolean;
begin
  ScrollLock := (keyboard_flag OR $10 = keyboard_flag);
end;

function shift_pressed: Boolean;
begin
  shift_pressed := (keyboard_flag OR 1 = keyboard_flag) or
                   (keyboard_flag OR 2 = keyboard_flag);
end;

function left_shift_pressed: Boolean;
begin
  left_shift_pressed := (keyboard_flag OR 2 = keyboard_flag);
end;

function right_shift_pressed: Boolean;
begin
  right_shift_pressed := (keyboard_flag OR 1 = keyboard_flag);
end;

function both_shifts_pressed: Boolean;
begin
  both_shifts_pressed := (keyboard_flag OR 1 = keyboard_flag) and
                         (keyboard_flag OR 2 = keyboard_flag);
end;

function alt_pressed: Boolean;
begin
  alt_pressed := scankey(SC_ALT);
end;

function ctrl_pressed: Boolean;
begin
  ctrl_pressed := scankey(SC_CTRL);
end;

{$ELSE}

const
  SYMTABSIZE = $65;
  symtab: array[0..PRED(SYMTABSIZE*10)] of word = (

{ Key   Scan    ASCII   Shift   Ctrl    Alt     Num     Caps    Sh+Caps Sh+Num  SDLK_Keycode}
{ Esc } $01,    $1B,    $1B,    $F000,  $F000,  $1B,    $1B,    $1B,    $1B,    SDLK_ESCAPE,
{ 1! }  $02,    $31,    $21,    $0200,  $7800,  $31,    $31,    $21,    $21,    SDLK_1,
{ 2@ }  $03,    $32,    $40,    $0300,  $7900,  $32,    $32,    $40,    $40,    SDLK_2,
{ 3# }  $04,    $33,    $23,    $0400,  $7A00,  $33,    $33,    $23,    $23,    SDLK_3,
{ 4$ }  $05,    $34,    $24,    $0500,  $7B00,  $34,    $34,    $24,    $24,    SDLK_4,
{ 5% }  $06,    $35,    $25,    $0600,  $7C00,  $35,    $35,    $25,    $25,    SDLK_5,
{ 6^ }  $07,    $36,    $5E,    $0700,  $7D00,  $36,    $36,    $5E,    $5E,    SDLK_6,
{ 7& }  $08,    $37,    $26,    $0800,  $7E00,  $37,    $37,    $26,    $26,    SDLK_7,
{ 8* }  $09,    $38,    $2A,    $0900,  $7F00,  $38,    $38,    $2A,    $2A,    SDLK_8,
{ 9( }  $0A,    $39,    $28,    $0A00,  $8000,  $39,    $39,    $28,    $28,    SDLK_9,
{ 0) }  $0B,    $30,    $29,    $0B00,  $8100,  $30,    $30,    $29,    $29,    SDLK_0,
{ -_ }  $0C,    $2D,    $5F,    $1F,    $8200,  $2D,    $2D,    $5F,    $5F,    SDLK_MINUS,
{ =+ }  $0D,    $3D,    $2B,    $F000,  $8300,  $3D,    $3D,    $2B,    $2B,    SDLK_EQUALS,
{Bksp}  $0E,    $08,    $08,    $7F,    $F000,  $08,    $08,    $08,    $08,    SDLK_BACKSPACE,
{ Tab}  $0F,    $09,    $0F00,  $F000,  $F000,  $09,    $09,    $0F00,  $0F00,  SDLK_TAB,
{ Q }   $10,    $71,    $51,    $11,    $1000,  $71,    $51,    $71,    $51,    SDLK_q,
{ W }   $11,    $77,    $57,    $17,    $1100,  $77,    $57,    $77,    $57,    SDLK_w,
{ E }   $12,    $65,    $45,    $05,    $1200,  $65,    $45,    $65,    $45,    SDLK_e,
{ R }   $13,    $72,    $52,    $12,    $1300,  $72,    $52,    $72,    $52,    SDLK_r,
{ T }   $14,    $74,    $54,    $14,    $1400,  $74,    $54,    $74,    $54,    SDLK_t,
{ Y }   $15,    $79,    $59,    $19,    $1500,  $79,    $59,    $79,    $59,    SDLK_y,
{ U }   $16,    $75,    $55,    $15,    $1600,  $75,    $55,    $75,    $55,    SDLK_u,
{ I }   $17,    $69,    $49,    $09,    $1700,  $69,    $49,    $69,    $49,    SDLK_i,
{ O }   $18,    $6F,    $4F,    $0F,    $1800,  $6F,    $4F,    $6F,    $4F,    SDLK_o,
{ P }   $19,    $70,    $50,    $10,    $1900,  $70,    $50,    $70,    $50,    SDLK_p,
{ [ }   $1A,    $5B,    $7B,    $1B,    $F000,  $5B,    $5B,    $7B,    $7B,    SDLK_LEFTBRACKET,
{ ] }   $1B,    $5D,    $7D,    $1D,    $F000,  $5D,    $5D,    $7D,    $7D,    SDLK_RIGHTBRACKET,
{enter} $1C,    $0D,    $0D,    $0A,    $F000,  $0D,    $0D,    $0D,    $0D,    SDLK_RETURN,
{ A }   $1E,    $61,    $41,    $01,    $1E00,  $61,    $41,    $61,    $41,    SDLK_a,
{ S }   $1F,    $73,    $53,    $13,    $1F00,  $73,    $53,    $73,    $53,    SDLK_s,
{ D }   $20,    $64,    $44,    $04,    $2000,  $64,    $44,    $64,    $44,    SDLK_d,
{ F }   $21,    $66,    $46,    $06,    $2100,  $66,    $46,    $66,    $46,    SDLK_f,
{ G }   $22,    $67,    $47,    $07,    $2200,  $67,    $47,    $67,    $47,    SDLK_g,
{ H }   $23,    $68,    $48,    $08,    $2300,  $68,    $48,    $68,    $48,    SDLK_h,
{ J }   $24,    $6A,    $4A,    $0A,    $2400,  $6A,    $4A,    $6A,    $4A,    SDLK_j,
{ K }   $25,    $6B,    $4B,    $0B,    $2500,  $6B,    $4B,    $6B,    $4B,    SDLK_k,
{ L }   $26,    $6C,    $4C,    $0C,    $2600,  $6C,    $4C,    $6C,    $4C,    SDLK_l,
{ ;:}   $27,    $3B,    $3A,    $F000,  $F000,  $3B,    $3B,    $3A,    $3A,    SDLK_SEMICOLON,
{ '"}   $28,    $27,    $22,    $F000,  $F000,  $27,    $27,    $22,    $22,    SDLK_QUOTE,
{ `~}   $29,    $60,    $7E,    $F000,  $F000,  $60,    $60,    $7E,    $7E,    SDLK_BACKQUOTE,
{Lshft} $2A,    $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  SDLK_LSHIFT,
{ \|}   $2B,    $5C,    $7C,    $1C,    $F000,  $5C,    $5C,    $7C,    $7C,    SDLK_BACKSLASH,
{ Z }   $2C,    $7A,    $5A,    $1A,    $2C00,  $7A,    $5A,    $7A,    $5A,    SDLK_z,
{ X }   $2D,    $78,    $58,    $18,    $2D00,  $78,    $58,    $78,    $58,    SDLK_x,
{ C }   $2E,    $63,    $43,    $03,    $2E00,  $63,    $43,    $63,    $43,    SDLK_c,
{ V }   $2F,    $76,    $56,    $16,    $2F00,  $76,    $56,    $76,    $56,    SDLK_v,
{ B }   $30,    $62,    $42,    $02,    $3000,  $62,    $42,    $62,    $42,    SDLK_b,
{ Key   Scan    ASCII   Shift   Ctrl    Alt     Num     Caps    Sh+Caps Sh+Num  SDLK_Keycode}
{ N }   $31,    $6E,    $4E,    $0E,    $3100,  $6E,    $4E,    $6E,    $4E,    SDLK_n,
{ M }   $32,    $6D,    $4D,    $0D,    $3200,  $6D,    $4D,    $6D,    $4D,    SDLK_m,
{ ,<}   $33,    $2C,    $3C,    $F000,  $F000,  $2C,    $2C,    $3C,    $3C,    SDLK_COMMA,
{ .>}   $34,    $2E,    $3E,    $F000,  $F000,  $2E,    $2E,    $3E,    $3E,    SDLK_PERIOD,
{ /?}   $35,    $2F,    $3F,    $F000,  $F000,  $2F,    $2F,    $3F,    $3F,    SDLK_SLASH,
{Rshft} $36,    $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  SDLK_RSHIFT,
{PrtSc} $37,    $2A,    $F000,  $F000,  $F000,  $2A,    $2A,    $F000,  $F000,  SDLK_PRINT,
{space} $39,    $20,    $20,    $20,    $20,    $20,    $20,    $20,    $20,    SDLK_SPACE,
{caps}  $3A,    $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  SDLK_CAPSLOCK,
{ F1 }  $3B,    $3B00,  $5400,  $5E00,  $6800,  $3B00,  $3B00,  $5400,  $5400,  SDLK_F1,
{ F2 }  $3C,    $3C00,  $5500,  $5F00,  $6900,  $3C00,  $3C00,  $5500,  $5500,  SDLK_F2,
{ F3 }  $3D,    $3D00,  $5600,  $6000,  $6A00,  $3D00,  $3D00,  $5600,  $5600,  SDLK_F3,
{ F4 }  $3E,    $3E00,  $5700,  $6100,  $6B00,  $3E00,  $3E00,  $5700,  $5700,  SDLK_F4,
{ F5 }  $3F,    $3F00,  $5800,  $6200,  $6C00,  $3F00,  $3F00,  $5800,  $5800,  SDLK_F5,
{ F6 }  $40,    $4000,  $5900,  $6300,  $6D00,  $4000,  $4000,  $5900,  $5900,  SDLK_F6,
{ F7 }  $41,    $4100,  $5A00,  $6400,  $6E00,  $4100,  $4100,  $5A00,  $5A00,  SDLK_F7,
{ F8 }  $42,    $4200,  $5B00,  $6500,  $6F00,  $4200,  $4200,  $5B00,  $5B00,  SDLK_F8,
{ F9 }  $43,    $4300,  $5C00,  $6600,  $7000,  $4300,  $4300,  $5C00,  $5C00,  SDLK_F9,
{ F10}  $44,    $4400,  $5D00,  $6700,  $7100,  $4400,  $4400,  $5D00,  $5D00,  SDLK_F10,
{ num}  $45,    $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  SDLK_NUMLOCK,
{scrl}  $46,    $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  SDLK_SCROLLOCK,
{home}  $47,    $4700,  $4700,  $7700,  $F000,  $4700,  $4700,  $4700,  $4700,  SDLK_HOME,
{ up }  $48,    $0000,  $4800,  $F000,  $F000,  $4800,  $4800,  $4800,  $4800,  SDLK_UP,
{pgup}  $49,    $4900,  $4900,  $8400,  $F000,  $4900,  $4900,  $4900,  $4900,  SDLK_PAGEUP,
{ np-}  $4A,    $2D,    $2D,    $F000,  $F000,  $2D,    $2D,    $2D,    $2D,    SDLK_KP_MINUS,
{left}  $4B,    $4B00,  $4B00,  $7300,  $F000,  $4B00,  $4B00,  $4B00,  $4B00,  SDLK_LEFT,
{centr} $4C,    $4C00,  $4C00,  $F000,  $F000,  $4C00,  $4C00,  $4C00,  $4C00,  SDLK_UNKNOWN,
{right} $4D,    $4D00,  $4D00,  $7400,  $F000,  $4D00,  $4D00,  $4D00,  $4D00,  SDLK_RIGHT,
{ np+}  $4E,    $2B,    $2B,    $F000,  $F000,  $2B,    $2B,    $2B,    $2B,    SDLK_KP_PLUS,
{end}   $4F,    $4F00,  $4F00,  $7500,  $F000,  $4F00,  $4F00,  $4F00,  $4F00,  SDLK_END,
{down}  $50,    $0000,  $5000,  $F000,  $F000,  $5000,  $5000,  $5000,  $5000,  SDLK_DOWN,
{pgdn}  $51,    $5100,  $5100,  $7600,  $F000,  $5100,  $5100,  $5100,  $5100,  SDLK_PAGEDOWN,
{ ins}  $52,    $5200,  $5200,  $F000,  $F000,  $5200,  $5200,  $5200,  $5200,  SDLK_INSERT,
{ del}  $53,    $5300,  $5300,  $F000,  $F000,  $5300,  $5300,  $5300,  $5300,  SDLK_DELETE,
{ F11}  $57,    $4500,  $5E00,  $6800,  $F000,  $4500,  $4500,  $5E00,  $5E00,  SDLK_F11,
{ F12}  $58,    $4500,  $F000,  $6900,  $F000,  $4600,  $4600,  $5F00,  $5F00,  SDLK_F12,
{ np0 } $52,    $5200,  $5200,  $F000,  $F000,  $30,    $30,    $29,    $30,    SDLK_KP0,
{ np1 } $4F,    $4F00,  $4F00,  $F000,  $F000,  $31,    $31,    $21,    $31,    SDLK_KP1,
{ np2 } $50,    $5000,  $5000,  $F000,  $F000,  $32,    $32,    $40,    $32,    SDLK_KP2,
{ np3 } $51,    $5100,  $5100,  $F000,  $F000,  $33,    $33,    $23,    $33,    SDLK_KP3,
{ np4 } $4B,    $4B00,  $4B00,  $F000,  $F000,  $34,    $34,    $24,    $34,    SDLK_KP4,
{ np5 } $4C,    $4C00,  $4C00,  $F000,  $F000,  $35,    $35,    $25,    $35,    SDLK_KP5,
{ np6 } $4D,    $4D00,  $4D00,  $F000,  $F000,  $36,    $36,    $5E,    $36,    SDLK_KP6,
{ np7 } $47,    $4700,  $4700,  $F000,  $F000,  $37,    $37,    $26,    $37,    SDLK_KP7,
{ np8 } $48,    $4800,  $4800,  $F000,  $F000,  $38,    $38,    $2A,    $38,    SDLK_KP8,
{ np9 } $49,    $4900,  $4900,  $F000,  $F000,  $39,    $39,    $28,    $39,    SDLK_KP9,
{ np. } $53,    $5300,  $5300,  $F000,  $F000,  $2E,    $2E,    $3E,    $3E,    SDLK_KP_PERIOD,
{ np/ } $35,    $2F,    $2F,    $F000,  $F000,  $2F,    $2F,    $2F,    $2F,    SDLK_KP_DIVIDE,
{ np* } $37,    $2A,    $2A,    $F000,  $F000,  $2A,    $2A,    $2A,    $2A,    SDLK_KP_MULTIPLY,
{NPent} $1C,    $0D,    $0D,    $0A,    $F000,  $0D,    $0D,    $0A,    $0A,    SDLK_KP_ENTER,
{LALT}  $FC,    $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  SDLK_LALT,
{RALT}  $FD,    $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  SDLK_RALT,
{LCTRL} $FE,    $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  SDLK_LCTRL,
{RCTRL} $FF,    $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  $FFFF,  SDLK_RCTRL
{ Key   Scan    ASCII   Shift   Ctrl    Alt     Num     Caps    Sh+Caps Sh+Num  SDLK_Keycode}
);

procedure TranslateKeycodes;

var
  i,j: Integer;
  modkeys: SDLMod;

begin
  // translate SDL_Keycodes to scancodes
  For i := 0 to SDLK_LAST do
    For j := 0 to PRED(SYMTABSIZE) do
      If (i = symtab[j*10+9]) then
        keydown[symtab[j*10]] := keystate^[i];

  // read capslock and numlock state
  modkeys := SDL_GetModState;
  _capslock := (modkeys AND KMOD_CAPS) <> 0;
  _numlock := (modkeys AND KMOD_NUM) <> 0;
end;

procedure keyboard_poll_input;
begin
  SDL_PumpEvents;
  TranslateKeycodes;
  process_global_keys;
end;

function keypressed: Boolean;

var
  event: SDL_Event;

begin
  keypressed := FALSE;
  Repeat
    keyboard_poll_input;
    If (SDL_PeepEvents(event,1,SDL_PEEKEVENT,SDL_QUITMASK) > 0) then
      begin
        _force_program_quit := TRUE;
        keypressed := TRUE;
        EXIT;
      end;
    If (SDL_PeepEvents(event,1,SDL_PEEKEVENT,SDL_MOUSEEVENTMASK) > 0) then
      begin
        // skip mouse events
        SDL_PeepEvents(event,1,SDL_GETEVENT,SDL_MOUSEEVENTMASK);
        CONTINUE;
      end;
    If (SDL_PeepEvents(event,1,SDL_PEEKEVENT,SDL_KEYDOWNMASK) > 0) then
      If (event.key.keysym.sym >= SDLK_NUMLOCK) then
        begin
          // skip modifier key presses
          SDL_PeepEvents(event,1,SDL_GETEVENT,SDL_KEYDOWNMASK);
          CONTINUE;
        end
      else
        keypressed := TRUE;
    EXIT;
  until FALSE;
end;

function getkey: Word;

function getkey_proc: Word;

var
  event: SDL_Event;
  i,j: Integer;

begin
  Repeat
    draw_screen;
    If (SDL_PollEvent(@event) <> 0) then
      begin
        If (event.eventtype = SDL_EVENTQUIT) or _force_program_quit then
          begin
            _force_program_quit := TRUE;
            getkey_proc := kESC;
            EXIT;
          end;
        // skip all other event except key presses
        If (event.eventtype <> SDL_KEYDOWN) then CONTINUE
        else
          begin
            // skip all modifier keys
            If (event.key.keysym.sym >= SDLK_NUMLOCK) then CONTINUE;
            // roll thru symtab, form correct getkey value
            For j := 0 to PRED(SYMTABSIZE) do
              begin
                If (event.key.keysym.sym = symtab[j*10+9]) then
                  begin // first check with modifier keys, order: ALT, CTRL, SHIFT (as DOS does)
                    { ALT }
                    If (keydown[SC_LALT] = TRUE) or (keydown[SC_RALT] = TRUE) then
                      begin
                        // impossible combination
                        If (symtab[j*10+4] = WORD_NULL) then CONTINUE;
                        If (symtab[j*10+4] > BYTE_NULL) then
                          begin
                            getkey_proc := symtab[j*10+4];
                            EXIT;
                          end;
                        getkey_proc := (symtab[j*10] SHL 8) OR symtab[j*10+4];
                        EXIT;
                      end;
                    { CTRL }
                    If (keydown[SC_LCTRL] = TRUE) or (keydown[SC_RCTRL] = TRUE) then
                      begin
                        // impossible combination
                        If (symtab[j*10+3] = WORD_NULL) then CONTINUE;
                        If (symtab[j*10+3] > BYTE_NULL) then
                          begin
                            getkey_proc := symtab[j*10+3];
                            EXIT;
                          end;
                        getkey_proc := (symtab[j*10] SHL 8) OR symtab[j*10+3];
                        EXIT;
                      end;
                    { SHIFT }
                    If (keydown[SC_LSHIFT] = TRUE) or (keydown[SC_RSHIFT] = TRUE) then
                      begin
                        i := 2; // SHIFT
                        If (_capslock = TRUE) then i := 7 // caps lock
                        else If (_numlock = TRUE) then i := 8; // num lock
                        // impossible combination
                        If (symtab[j*10+i] = WORD_NULL) then CONTINUE;
                        If (symtab[j*10+i] > BYTE_NULL) then getkey_proc := symtab[j*10+i]
                        else getkey_proc := (symtab[j*10] SHL 8) OR symtab[j*10+i];
                        EXIT;
                      end;
                    { normal ASCII }
                    i := 1;
                    If (_capslock = TRUE) then i := 6 // caps lock
                    else If (_numlock = TRUE) then i := 5; // num lock
                    // impossible combination
                    If (symtab[j*10+i] = WORD_NULL) then CONTINUE;
                    If (symtab[j*10+i] > BYTE_NULL) then getkey_proc := symtab[j*10+i]
                    else getkey_proc := (symtab[j*10] SHL 8) OR symtab[j*10+i]; // (scancode << 8) + ASCII
                    EXIT;
                  end;
              end;
          end;
      end;
  until FALSE;
end;

begin
  Repeat draw_screen until keypressed;
  // filter out CTRL+TAB combo as it is handled within timer routine
  If ctrl_tab_pressed then
    begin
      draw_screen;
      keyboard_reset_buffer;
      getkey := WORD_NULL;
    end
  else getkey := getkey_proc;
end;

function scankey(scancode: Byte): Boolean;
begin
  TranslateKeycodes;
  scankey := keydown[scancode];
end;

procedure keyboard_reset_buffer;

var
  event: SDL_Event;

begin
  // flush all unused events
  While (SDL_PollEvent(@event) <> 0) do ;
end;

procedure wait_until_F11_F12_released;
begin
  _debug_str_ := 'ADT2KEYB.PAS:wait_until_F11_F12_released';
  Repeat
    draw_screen;
    SDL_PumpEvents;
    TranslateKeycodes;
  until NOT keydown[SC_F11] and NOT keydown[SC_F12];
  keyboard_reset_buffer;
end;

function CapsLock: Boolean;
begin
  CapsLock := _capslock;
end;

function NumLock: Boolean;
begin
  NumLock := _numlock;
end;

function shift_pressed: Boolean;
begin
  shift_pressed := scankey(SC_LSHIFT) or scankey(SC_RSHIFT);
end;

function left_shift_pressed: Boolean;
begin
  left_shift_pressed := scankey(SC_LSHIFT);
end;

function right_shift_pressed: Boolean;
begin
  right_shift_pressed := scankey(SC_RSHIFT);
end;

function alt_pressed: Boolean;
begin
  alt_pressed := scankey(SC_LALT) or scankey(SC_RALT);
end;

function ctrl_pressed: Boolean;
begin
  ctrl_pressed := scankey(SC_LCTRL) or scankey(SC_RCTRL);
end;

procedure screen_saver;
begin
  // relevant for DOS version only
end;

{$ENDIF}

function ctrl_tab_pressed: Boolean;
begin
  ctrl_tab_pressed := ctrl_pressed and scankey(SC_TAB);
end;

end.
