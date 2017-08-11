unit AdT2sys;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

procedure draw_SDL_screen_720x480; external name '_ADT2SYS____DRAW_SDL_SCREEN_720X480';
procedure draw_SDL_screen_960x800; external name '_ADT2SYS____DRAW_SDL_SCREEN_960X800';
procedure draw_SDL_screen_1440x960; external name '_ADT2SYS____DRAW_SDL_SCREEN_1440X960';

const
  virtual_screen__first_row: Longint = 0; export name '_TC__ADT2SYS____VIRTUAL_SCREEN__FIRST_ROW';
  virtual_cur_shape: Word = 0; export name '_TC__ADT2SYS____VIRTUAL_CUR_SHAPE';
  virtual_cur_pos: Word = 0; export name '_TC__ADT2SYS____VIRTUAL_CUR_POS';
  slide_ticks: Longint = 0;
  reset_slide_ticks: Boolean = FALSE;
{$IFDEF GO32V2}
  gfx_ticks: Longint = 0;
  reset_gfx_ticks: Boolean = FALSE;
  scroll_ticks: Real = 0;
  mouse_active: Boolean = FALSE;
{$ENDIF}
  blink_ticks: Longint = 0;
  blink_flag: Boolean = FALSE;
  cursor_sync: Boolean = FALSE; export name '_TC__ADT2SYS____CURSOR_SYNC';
{$IFDEF GO32V2}
  _draw_screen_without_vsync: Boolean = FALSE;
  _draw_screen_without_delay: Boolean = FALSE;
{$ELSE}
  _draw_screen_without_delay: Boolean = FALSE;
  _update_sdl_screen: Boolean = FALSE;
  _name_scrl_shift_ctr: Shortint = 1;
  _name_scrl_shift: Byte = 0;
  _name_scrl_pending_frames: Longint = 0;
{$ENDIF}
  _cursor_blink_factor: Longint = 13; export name '_TC__ADT2SYS_____CURSOR_BLINK_FACTOR';
  _cursor_blink_pending_frames: Longint = 0; export name '_TC__ADT2SYS_____CURSOR_BLINK_PENDING_FRAMES';
  _generic_blink_event_flag: Boolean = FALSE;
  _realtime_gfx_no_update: Boolean = FALSE;
{$IFDEF GO32V2}
  _screen_refresh_pending_frames: Longint = 0;
  _custom_svga_cfg: array[1..31] of Record
                                      flag: Boolean;
                                      value: Longint;
                                    end
    = ((flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1),(flag: FALSE; value: -1),(flag: FALSE; value: -1),
       (flag: FALSE; value: -1));

{$ENDIF}

const
  _debug_: Boolean = FALSE;
  _last_debug_str_: String = '';
  _debug_str_: String = '';

const
  _force_program_quit: Boolean = FALSE;
  _traceprc_last_order: Byte = 0;
  _traceprc_last_pattern: Byte = 0;
  _traceprc_last_line: Byte = 0;
  _pattedit_lastpos: Byte = 0; export name '_TC__ADT2SYS_____PATTEDIT_LASTPOS';

procedure sys_init;
procedure sys_done;
procedure draw_screen;

{$IFNDEF GO32V2}

const
  _FrameBuffer: Pointer = NIL; export name '_TC__ADT2SYS_____FRAMEBUFFER';

procedure vid_Init;
procedure vid_Deinit;
procedure vid_SetVideoMode(do_delay: Boolean);
procedure vid_SetRGBPalette(var palette);
procedure vid_FadeOut;

{$ELSE}

var
  _FrameBuffer_mirror: array[0..PRED(1024*768)] of Byte;

{$ENDIF}

function iCASE_filename(str: String): String;
function Lower_filename(str: String): String;
function Upper_filename(str: String): String;

procedure ResetF_RW(var f: File);
procedure ResetF(var f: File);
procedure RewriteF(var f: File);
procedure BlockReadF(var f: File; var data; size: Longint; var bytes_read: Longint);
procedure BlockWriteF(var f: File; var data; size: Longint; var bytes_written: Longint);
procedure SeekF(var f: File; fpos: Longint);
procedure EraseF(var f: File);
procedure CloseF(var f: File);

implementation

uses
{$IFDEF GO32V2}
  DOS,GO32,AdT2vesa,
{$ELSE}
  DOS,SDL,SDL_Video,SDL_Timer,SDL__rwops,
  AdT2opl3,
{$ENDIF}
  AdT2unit,AdT2text,AdT2keyb,AdT2data,
  TxtScrIO,StringIO,ParserIO;

{$IFNDEF GO32V2}
var
  screen: PSDL_Surface;
  rgb_color_alt: array[0..15] of tRGB;
{$ENDIF}

procedure sys_init;
begin
{$IFNDEF GO32V2}
  vid_Init; // SDL video
  AdT2opl3.snd_init; // SDL sound + opl3 emulation
{$ENDIF}
end;

procedure sys_done;
begin
{$IFNDEF GO32V2}
  vid_Deinit;
{$ENDIF}
end;

{$IFDEF GO32V2}

procedure draw_VESA_screen_800x600_1;

const
  H_RES = 800;
  V_RES = 600;
  H_CHR = 90;
  V_CHR = 30;

var
  bit_pos,bit_mask: Byte;
  cur_pos_lo,cur_pos_hi: Byte;
  cur_shape: Word;
  pos_x,pos_y: Byte;
  base_ofs,skip_ofs: Dword;
  loop_idx1,loop_idx2,loop_idx3,
  loop_idx4: Dword;

begin
  asm
        push    ebx
        push    esi
        push    edi
        mov     ax,word ptr [virtual_cur_pos]
        mov     cur_pos_lo,al
        mov     cur_pos_hi,ah
        mov     ax,word ptr [virtual_cur_shape]
        mov     cur_shape,ax
        mov     eax,_cursor_blink_factor
        cmp     _cursor_blink_pending_frames,eax
        jnae    @@1
        mov     _cursor_blink_pending_frames,0
        xor     byte ptr [cursor_sync],1
@@1:    lea     esi,[font8x16]
        lea     edi,[_FrameBuffer_mirror]
        mov     base_ofs,edi
        add     edi,(H_RES-H_CHR*8)/2+(V_RES-V_CHR*16)/2*H_RES
        mov     ebx,dword ptr [screen_ptr]
        mov     eax,virtual_screen__first_row
        mov     skip_ofs,eax
        movzx   eax,MAX_ROWS
        mov     loop_idx1,eax
        mov     pos_y,1
@@2:    mov     bit_pos,0
        mov     loop_idx2,16
@@3:    mov     loop_idx3,H_CHR
        mov     pos_x,1
@@4:    movzx   eax,byte ptr [ebx]
        mov     edx,16
        mul     edx
        movzx   edx,bit_pos
        add     eax,edx
        mov     dl,[esi+eax]
        mov     bit_mask,dl
        mov     loop_idx4,8
@@5:    mov     edx,1
        mov     ecx,loop_idx4
        shl     dx,cl
        shr     dx,1
        cmp     skip_ofs,0
        jz      @@6
        dec     skip_ofs
        jmp     @@9
@@6:    mov     eax,edi
        sub     eax,base_ofs
        cmp     eax,H_RES*V_RES-(H_RES-H_CHR*8)/2-(V_RES-V_CHR*16)/2*H_RES
        jnbe    @@12
        cmp     byte ptr [cursor_sync],1
        jnz     @@7
        movzx   eax,pos_x
        cmp     al,cur_pos_lo
        jnz     @@7
        mov     ax,cur_shape
        cmp     bit_pos,ah
        jb      @@7
        cmp     bit_pos,al
        ja      @@7
        movzx   eax,pos_y
        cmp     al,cur_pos_hi
        jnz     @@7
        mov     al,[ebx+1]
        and     al,01111b
        stosb
        jmp     @@9
@@7:    movzx   eax,bit_mask
        test    dl,al
        jz      @@8
        mov     al,[ebx+1]
        and     al,01111b
        stosb
        jmp     @@9
@@8:    mov     al,[ebx+1]
        shr     al,4
        stosb
@@9:    dec     loop_idx4
        cmp     loop_idx4,0
        ja      @@5
        add     ebx,2
        inc     pos_x
        dec     loop_idx3
        cmp     loop_idx3,0
        ja      @@4
        sub     ebx,H_CHR*2
        cmp     skip_ofs,0
        jz      @@10
        sub     skip_ofs,H_RES-H_CHR*8
        jmp     @@11
@@10:   add     edi,H_RES-H_CHR*8
@@11:   inc     bit_pos
        dec     loop_idx2
        cmp     loop_idx2,0
        ja      @@3
        inc     pos_y
        add     ebx,H_CHR*2
        dec     loop_idx1
        cmp     loop_idx1,0
        ja      @@2
@@12:
  end;
end;

procedure draw_VESA_screen_800x600_2;

const
  H_RES = 800;
  V_RES = 600;
  H_CHR = 90;
  V_CHR = 36;

var
  bit_pos,bit_mask: Byte;
  cur_pos_lo,cur_pos_hi: Byte;
  cur_shape: Word;
  pos_x,pos_y: Byte;
  base_ofs,skip_ofs: Dword;
  loop_idx1,loop_idx2,loop_idx3,
  loop_idx4: Dword;

begin
  asm
        mov     ax,word ptr [virtual_cur_pos]
        mov     cur_pos_lo,al
        mov     cur_pos_hi,ah
        mov     ax,word ptr [virtual_cur_shape]
        mov     cur_shape,ax
        mov     eax,_cursor_blink_factor
        cmp     _cursor_blink_pending_frames,eax
        jnae    @@1
        mov     _cursor_blink_pending_frames,0
        xor     byte ptr [cursor_sync],1
@@1:    lea     esi,[font8x16]
        lea     edi,[_FrameBuffer_mirror]
        mov     base_ofs,edi
        add     edi,(H_RES-H_CHR*8)/2+(V_RES-V_CHR*16)/2*H_RES
        mov     ebx,dword ptr [screen_ptr]
        mov     eax,virtual_screen__first_row
        mov     skip_ofs,eax
        movzx   eax,MAX_ROWS
        mov     loop_idx1,eax
        mov     pos_y,1
@@2:    mov     bit_pos,0
        mov     loop_idx2,16
@@3:    mov     loop_idx3,H_CHR
        mov     pos_x,1
@@4:    movzx   eax,byte ptr [ebx]
        mov     edx,16
        mul     edx
        movzx   edx,bit_pos
        add     eax,edx
        mov     dl,[esi+eax]
        mov     bit_mask,dl
        mov     loop_idx4,8
@@5:    mov     edx,1
        mov     ecx,loop_idx4
        shl     dx,cl
        shr     dx,1
        cmp     skip_ofs,0
        jz      @@6
        dec     skip_ofs
        jmp     @@9
@@6:    mov     eax,edi
        sub     eax,base_ofs
        cmp     eax,H_RES*V_RES-(H_RES-H_CHR*8)/2-(V_RES-V_CHR*16)/2*H_RES
        jnbe    @@12
        cmp     byte ptr [cursor_sync],1
        jnz     @@7
        movzx   eax,pos_x
        cmp     al,cur_pos_lo
        jnz     @@7
        mov     ax,cur_shape
        cmp     bit_pos,ah
        jb      @@7
        cmp     bit_pos,al
        ja      @@7
        movzx   eax,pos_y
        cmp     al,cur_pos_hi
        jnz     @@7
        mov     al,[ebx+1]
        and     al,01111b
        stosb
        jmp     @@9
@@7:    movzx   eax,bit_mask
        test    dl,al
        jz      @@8
        mov     al,[ebx+1]
        and     al,01111b
        stosb
        jmp     @@9
@@8:    mov     al,[ebx+1]
        shr     al,4
        stosb
@@9:    dec     loop_idx4
        cmp     loop_idx4,0
        ja      @@5
        add     ebx,2
        inc     pos_x
        dec     loop_idx3
        cmp     loop_idx3,0
        ja      @@4
        sub     ebx,H_CHR*2
        cmp     skip_ofs,0
        jz      @@10
        sub     skip_ofs,H_RES-H_CHR*8
        jmp     @@11
@@10:   add     edi,H_RES-H_CHR*8
@@11:   inc     bit_pos
        dec     loop_idx2
        cmp     loop_idx2,0
        ja      @@3
        inc     pos_y
        add     ebx,H_CHR*2
        dec     loop_idx1
        cmp     loop_idx1,0
        ja      @@2
@@12:
  end;
end;

procedure draw_VESA_screen_1024x768;

const
  H_RES = 1024;
  V_RES = 768;
  H_CHR = 120;
  V_CHR = 46;

var
  bit_pos,bit_mask: Byte;
  cur_pos_lo,cur_pos_hi: Byte;
  cur_shape: Word;
  pos_x,pos_y: Byte;
  base_ofs: Dword;
  loop_idx1,loop_idx2,loop_idx3,
  loop_idx4: Dword;

begin
  asm
        mov     ax,word ptr [virtual_cur_pos]
        mov     cur_pos_lo,al
        mov     cur_pos_hi,ah
        mov     ax,word ptr [virtual_cur_shape]
        mov     cur_shape,ax
        mov     eax,_cursor_blink_factor
        cmp     _cursor_blink_pending_frames,eax
        jnae    @@1
        mov     _cursor_blink_pending_frames,0
        xor     byte ptr [cursor_sync],1
@@1:    lea     esi,[font8x16]
        lea     edi,[_FrameBuffer_mirror]
        mov     base_ofs,edi
        add     edi,(H_RES-H_CHR*8)/2+(V_RES-V_CHR*16)/2*H_RES
        mov     ebx,dword ptr [screen_ptr]
        movzx   eax,MAX_ROWS
        mov     loop_idx1,eax
        mov     pos_y,1
@@2:    mov     bit_pos,0
        mov     loop_idx2,16
@@3:    mov     loop_idx3,H_CHR
        mov     pos_x,1
@@4:    movzx   eax,byte ptr [ebx]
        mov     edx,16
        mul     edx
        movzx   edx,bit_pos
        add     eax,edx
        mov     dl,[esi+eax]
        mov     bit_mask,dl
        mov     loop_idx4,8
@@5:    mov     edx,1
        mov     ecx,loop_idx4
        shl     dx,cl
        shr     dx,1
        mov     eax,edi
        sub     eax,base_ofs
        cmp     eax,H_RES*V_RES-(H_RES-H_CHR*8)/2-(V_RES-V_CHR*16)/2*H_RES
        jnbe    @@9
        cmp     byte ptr [cursor_sync],1
        jnz     @@6
        movzx   eax,pos_x
        cmp     al,cur_pos_lo
        jnz     @@6
        mov     ax,cur_shape
        cmp     bit_pos,ah
        jb      @@6
        cmp     bit_pos,al
        ja      @@6
        movzx   eax,pos_y
        cmp     al,cur_pos_hi
        jnz     @@6
        mov     al,[ebx+1]
        and     al,01111b
        stosb
        jmp     @@8
@@6:    movzx   eax,bit_mask
        test    dl,al
        jz      @@7
        mov     al,[ebx+1]
        and     al,01111b
        stosb
        jmp     @@8
@@7:    mov     al,[ebx+1]
        shr     al,4
        stosb
@@8:    dec     loop_idx4
        cmp     loop_idx4,0
        ja      @@5
        add     ebx,2
        inc     pos_x
        dec     loop_idx3
        cmp     loop_idx3,0
        ja      @@4
        sub     ebx,H_CHR*2
        add     edi,H_RES-H_CHR*8
        inc     bit_pos
        dec     loop_idx2
        cmp     loop_idx2,0
        ja      @@3
        inc     pos_y
        add     ebx,H_CHR*2
        dec     loop_idx1
        cmp     loop_idx1,0
        ja      @@2
@@9:
  end;
end;

procedure dump_VESA_buffer(buffer_size: Longint);

var
  dumped_data_size,bank_data_size: Longint;
  current_bank: Byte;

begin
  If NOT _draw_screen_without_vsync then
    WaitRetrace;
  dumped_data_size := 0;
  current_bank := 0;
  While (dumped_data_size < buffer_size) do
    begin
      If (dumped_data_size+65536 <= buffer_size) then
        bank_data_size := 65536
      else bank_data_size := buffer_size-dumped_data_size;
      VESA_SwitchBank(current_bank);
      dosmemput($0a000,0,_FrameBuffer_mirror[dumped_data_size],bank_data_size);
      Inc(dumped_data_size,bank_data_size);
      Inc(current_bank);
    end;
end;

procedure shift_text_screen;

var
  xsize: Byte;
  xshift: Byte;

begin
  xsize := SCREEN_RES_X DIV scr_font_width;
  xshift := (xsize-MAX_COLUMNS) DIV 2;
  FillChar(ptr_temp_screen2^,SCREEN_MEM_SIZE,0);
  asm
        mov     esi,dword ptr [screen_ptr]
        mov     edi,dword ptr [ptr_temp_screen2]
        cld
        movzx   ecx,MAX_ROWS
        movzx   ebx,xshift
        shl     ebx,1
        add     edi,ebx
@@1:    xchg    ecx,edx
        movzx   ecx,xsize
        rep     movsw
        xchg    ecx,edx
        loop    @@1
  end;
end;

procedure draw_screen;
begin
  If _draw_screen_without_delay then
    _draw_screen_without_delay := FALSE
  else If do_synchronize and NOT (_screen_refresh_pending_frames > fps_down_factor) then
        EXIT
      else _screen_refresh_pending_frames := 0;
  If Compare(screen_ptr,ptr_screen_mirror,(SCREEN_RES_X DIV scr_font_width)*MAX_ROWS*2) then
    EXIT
  else begin
         ScreenMemCopy(screen_ptr,ptr_screen_mirror);
         If NOT is_VESA_emulated_mode then
           begin
             If NOT _draw_screen_without_vsync then
               WaitRetrace;
             If NOT (program_screen_mode in [4,5]) then
               dosmemput(v_seg,v_ofs,screen_ptr^,MAX_COLUMNS*MAX_ROWS*2)
             else begin
                    shift_text_screen;
                    dosmemput(v_seg,v_ofs,ptr_temp_screen2^,(SCREEN_RES_X DIV scr_font_width)*MAX_ROWS*2);
                  end;
           end;
       end;
  _draw_screen_without_vsync := FALSE;
  If is_VESA_emulated_mode then
    Case get_VESA_emulated_mode_idx of
      0: begin
           draw_VESA_screen_800x600_1;
           dump_VESA_buffer(800*600);
         end;

      1: begin
           draw_VESA_screen_800x600_2;
           dump_VESA_buffer(800*600);
         end;

      2: begin
           draw_VESA_screen_1024x768;
           dump_VESA_buffer(1024*768);
         end;
    end;
end;

{$ELSE}

procedure draw_screen_proc;
begin
  _update_sdl_screen := FALSE;
  If Compare(screen_ptr,ptr_screen_mirror,(SCREEN_RES_X DIV scr_font_width)*MAX_ROWS*2) then EXIT
  else ScreenMemCopy(screen_ptr,ptr_screen_mirror);
  _cursor_blink_factor := ROUND(13/100*sdl_frame_rate);
  _update_sdl_screen := TRUE;
  Case program_screen_mode of
    0: draw_SDL_screen_720x480;
    1: draw_SDL_screen_960x800;
    2: draw_SDL_screen_1440x960;
  end;
end;

procedure vid_Init;
begin
  SDL_Init(SDL_INIT_VIDEO or SDL_INIT_TIMER or SDL_INIT_AUDIO);
end;

procedure vid_Deinit;
begin
  SDL_FreeSurface(screen);
  SDL_Quit;
end;

procedure vid_SetRGBPalette(var palette);
begin
  SDL_SetPalette(screen,SDL_PHYSPAL,SDL_ColorArray(palette),0,16);
end;

procedure draw_screen;

const
   frame_start: Longint = 0;
   frame_end: Longint = 0;
   actual_frame_end: Longint = 0;

begin
  realtime_gfx_poll_proc;
  draw_screen_proc;
  If _update_sdl_screen then SDL_Flip(screen);

  If _draw_screen_without_delay then _draw_screen_without_delay := FALSE
  else begin // keep framerate
         actual_frame_end := SDL_GetTicks;
         frame_end := frame_start+(1000 DIV sdl_frame_rate);
         // always sleep at least 2 msec
         If (actual_frame_end+2 > frame_end) then frame_end := actual_frame_end+2;
         SDL_Delay(frame_end-actual_frame_end);
         frame_start := SDL_GetTicks;
       end;
end;

procedure vid_SetVideoMode(do_delay: Boolean);

var
  icon: pSDL_Surface;
  rwop: pSDL_RWops;
  win_title: String;

begin
  If do_delay then SDL_Delay(1000);
  screen := SDL_SetVideoMode(SCREEN_RES_x,SCREEN_RES_y,8,SDL_SWSURFACE);
  If (screen = NIL) then
    begin
      WriteLn('SDL: Couldn''t initialize video mode');
      HALT(1);
    end;

  vid_SetRGBPalette(Addr(rgb_color)^);
  Move(rgb_color,rgb_color_alt,SizeOf(rgb_color));
  _FrameBuffer := screen^.pixels;
  rwop := SDL_RWFromMem(adt2_icon_bitmap,SizeOf(adt2_icon_bitmap));
  icon := SDL_LoadBMP_RW(rwop,TRUE);
  SDL_WM_SetIcon(icon,NIL);
  win_title := '/|DLiB TR/|CK3R ][ SDL'+#0;
  SDL_WM_SetCaption(Addr(win_title[1]),NIL);
end;

procedure vid_FadeOut;

var
  idx: Byte;

function min0(val: Longint): Longint;
begin
  If (val <= 0) then min0 := 0
  else min0 := val;
end;

begin
  For idx := 1 to 15 do
    begin
      rgb_color_alt[idx].r := min0(rgb_color_alt[idx].r-1);
      rgb_color_alt[idx].g := min0(rgb_color_alt[idx].g-1);
      rgb_color_alt[idx].b := min0(rgb_color_alt[idx].b-1);
    end;
  SDL_SetPalette(screen,SDL_PHYSPAL,SDL_ColorArray(Addr(rgb_color_alt)^),0,16);
end;

{$ENDIF}

function iCASE_filename(str: String): String;
begin
{$IFDEF UNIX}
  iCASE_filename := str;
{$ELSE}
  iCASE_filename := iCASE(str);
{$ENDIF}
end;

function Lower_filename(str: String): String;
begin
{$IFDEF UNIX}
  Lower_filename := str;
{$ELSE}
  Lower_filename := Lower(str);
{$ENDIF}
end;

function Upper_filename(str: String): String;
begin
{$IFDEF UNIX}
  Upper_filename := str;
{$ELSE}
  Upper_filename := Upper(str);
{$ENDIF}
end;

procedure ResetF_RW(var f: File);

var
  fattr: Word;

begin
  _debug_str_:= 'ADT2SYS.PAS:ResetF_RW';
  GetFAttr(f,fattr);
  If (fattr AND ReadOnly = ReadOnly) then
    SetFAttr(f,fattr AND NOT ReadOnly);
  If (DosError <> 0) then ;
  FileMode := 2;
  {$i-}
  Reset(f,1);
  {$i+}
end;

procedure ResetF(var f: File);

var
  fattr: Word;

begin
  _debug_str_:= 'ADT2SYS.PAS:ResetF';
  GetFAttr(f,fattr);
  If (fattr AND ReadOnly = ReadOnly) then
    FileMode := 0;
  {$i-}
  Reset(f,1);
  {$i+}
end;

procedure RewriteF(var f: File);

var
  fattr: Word;

begin
  _debug_str_:= 'ADT2SYS.PAS:RewriteF';
  GetFAttr(f,fattr);
  If (fattr AND ReadOnly = ReadOnly) then
    SetFAttr(f,fattr AND NOT ReadOnly);
  {$i-}
  Rewrite(f,1);
  {$i+}
end;

procedure BlockReadF(var f: File; var data; size: Longint; var bytes_read: Longint);
begin
  _debug_str_:= 'ADT2SYS.PAS:BlockReadF';
  {$i-}
  BlockRead(f,data,size,bytes_read);
  {$i+}
  If (IOresult <> 0) then
    bytes_read := 0;
end;

procedure BlockWriteF(var f: File; var data; size: Longint; var bytes_written: Longint);
begin
  _debug_str_:= 'ADT2SYS.PAS:BlockWriteF';
  {$i-}
  BlockWrite(f,data,size,bytes_written);
  {$i+}
  If (IOresult <> 0) then
    bytes_written := 0;
end;

procedure SeekF(var f: File; fpos: Longint);
begin
  _debug_str_:= 'ADT2SYS.PAS:SeekF';
  {$i-}
  Seek(f,fpos);
  {$i+}
end;

procedure EraseF(var f: File);
begin
  _debug_str_:= 'ADT2SYS.PAS:EraseF';
  {$i-}
  Erase(f);
  {$i+}
  If (IOresult <> 0) then ;
end;

procedure CloseF(var f: File);
begin
  _debug_str_:= 'ADT2SYS.PAS:CloseF';
  {$i-}
  Close(f);
  {$i+}
  If (IOresult <> 0) then ;
end;

end.
