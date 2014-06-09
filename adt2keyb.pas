unit AdT2keyb;
interface
 
var
  keydown: array[0..255] of Boolean;

procedure keyboard_init;
procedure keyboard_done;
procedure keyboard_toggle_sleep;
procedure screen_saver;
procedure keyboard_reset_buffer;
procedure wait_until_key_released;

function keypressed: Boolean;
function getkey: Word;
function scankey(scancode: Byte): Boolean;
procedure keyboard_poll_input;

function CapsLock: Boolean;
function NumLock: Boolean;
function shift_pressed: Boolean;
function left_shift_pressed: Boolean;
function right_shift_pressed: Boolean;
function alt_pressed: Boolean;
function ctrl_pressed: Boolean;

implementation

uses
  DOS,
  SDL_Types,SDL_Timer,SDL_Events,SDL_Keyboard,
  AdT2vscr,AdT2unit,AdT2ext2,AdT2sys,
  DialogIO,TxtScrIO,ParserIO;

const
  _numlock:    Boolean = FALSE;
  _capslock:   Boolean = FALSE;

{$i symtab.inc}
var
  keystate: ^BoolArray;
  varnum: Longint;

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

var
  event: SDL_Event;
  i,j: Integer;

begin
  Repeat emulate_screen until keypressed;
  Repeat
    If (SDL_PollEvent(@event) <> 0) then
      begin
        If (event.eventtype = SDL_EVENTQUIT) or _force_program_quit then
          begin
            _force_program_quit := TRUE;
            getkey := kESC;
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
                            getkey := symtab[j*10+4];
                            EXIT;
                          end;
                        getkey := (symtab[j*10] SHL 8) OR symtab[j*10+4];
                        EXIT;
                      end;
                    { CTRL }
                    If (keydown[SC_LCTRL] = TRUE) or (keydown[SC_RCTRL] = TRUE) then
                      begin
                        // impossible combination
                        If (symtab[j*10+3] = WORD_NULL) then CONTINUE;
                        If (symtab[j*10+3] > BYTE_NULL) then
                          begin
                            getkey := symtab[j*10+3];
                            EXIT;
                          end;
                        getkey := (symtab[j*10] SHL 8) OR symtab[j*10+3];
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
                        If (symtab[j*10+i] > BYTE_NULL) then getkey := symtab[j*10+i]
                        else getkey := (symtab[j*10] SHL 8) OR symtab[j*10+i];
                        EXIT;
                      end;
                    { normal ASCII }
                    i := 1;
                    If (_capslock = TRUE) then i := 6 // caps lock
                    else If (_numlock = TRUE) then i := 5; // num lock
                    // impossible combination
                    If (symtab[j*10+i] = WORD_NULL) then CONTINUE;
                    If (symtab[j*10+i] > BYTE_NULL) then getkey := symtab[j*10+i]
                    else getkey := (symtab[j*10] SHL 8) OR symtab[j*10+i]; // (scancode << 8) + ASCII
                    EXIT;
                  end;
              end;
          end;
      end;
  until FALSE;    
end;

function scankey(scancode: Byte): Boolean;
begin
  TranslateKeycodes;
  scankey := keydown[scancode];
end;

procedure keyboard_toggle_sleep;
begin
  // only relevant in DOS version
end;

procedure keyboard_init;
begin
  SDL_EnableKeyRepeat(sdl_typematic_delay,sdl_typematic_rate);
  keystate := SDL_GetKeyState(varnum);
end;

procedure keyboard_done;
begin
  // only relevant in DOS version
end;

procedure screen_saver;
begin
  // only relevant in DOS version
end;

procedure keyboard_reset_buffer;

var
  event: SDL_Event;

begin
  // flush all unused events
  While (SDL_PollEvent(@event) <> 0) do ;
end;

procedure wait_until_key_released;
begin
  _debug_str_ := 'ADT2KEYB.PAS:wait_until_key_released';
  Repeat
    emulate_screen;
    keyboard_poll_input;
  until Empty(keydown,SizeOf(keydown));
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

end.
