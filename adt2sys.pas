unit AdT2sys;
{$IFDEF __TMT__}
{$S-,Q-,R-,V-,B-,X+}
{$ELSE}
{$PACKRECORDS 1}
{$ENDIF}
interface

const
  virtual_screen__first_row: Longint = 0;
  virtual_cur_shape: Word = 0;
  virtual_cur_pos: Word = 0;
  slide_ticks: Longint = 0;
  reset_slide_ticks: Boolean = FALSE;
{$IFDEF __TMT__}
  gfx_ticks: Longint = 0;
  reset_gfx_ticks: Boolean = FALSE;
  vchg_ticks: Real = 0;
  scroll_ticks: Real = 0;
{$ENDIF}
  blink_ticks: Longint = 0;
  blink_flag: Boolean = FALSE;
  cursor_sync: Boolean = FALSE;
{$IFNDEF __TMT__}
  _emulate_screen_without_delay: Boolean = FALSE;
  _update_sdl_screen: Boolean = FALSE;
  _name_scrl_shift_ctr: Shortint = 1;
  _name_scrl_shift: Byte = 0;
  _name_scrl_pending_frames: Longint = 0;
{$ENDIF}
  _cursor_blink_factor: Longint = 13;
  _cursor_blink_pending_frames: Longint = 0;
  _generic_blink_event_flag: Boolean = FALSE;
  _realtime_gfx_no_update: Boolean = FALSE;
{$IFDEF __TMT__}
  _screen_refresh_pending_frames: Longint = 0;
{$ENDIF}

const
  _debug_: Boolean = FALSE;
  _last_debug_str_: String = '';
  _debug_str_: String = '';

const
  _force_program_quit: Boolean = FALSE;
  _update_tracepr_pending_flag: Boolean = FALSE;
  _update_pattern_pending_flag: Boolean = FALSE;
  _update_pattord_pending_flag: Boolean = FALSE;
  _update_statsln_pending_flag: Boolean = FALSE;
  _traceprc_last_order: Byte = 0;
  _traceprc_last_pattern: Byte = 0;
  _traceprc_last_line: Byte = 0;
  _pattedit_lastpos: Byte = 0;

procedure sys_init;
procedure sys_deinit;
procedure emulate_screen;

{$IFNDEF __TMT__}

const
  _FrameBuffer: Pointer = NIL;

procedure vid_Init;
procedure vid_Deinit;
procedure vid_SetVideoMode(do_delay: Boolean);
procedure vid_SetRGBPalette(var palette);
procedure vid_FadeOut;

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
{$IFDEF __TMT__}
  DOS,LFB256,
{$ELSE}
  DOS,SDL,SDL_Video,SDL_Timer,SDL__rwops,
  AdT2opl3,
{$ENDIF}
  AdT2unit,AdT2text,AdT2keyb,AdT2data,
  TxtScrIO,StringIO,ParserIO;

{$IFNDEF __TMT__}
var
  screen: PSDL_Surface;
  rgb_color_alt: array[0..15] of tRGB;
{$ENDIF}

procedure sys_init;
begin
{$IFNDEF __TMT__}
  vid_Init; // SDL video
  AdT2opl3.snd_Init; // SDL sound + opl3 emulation
{$ENDIF}
end;

procedure sys_deinit;
begin
{$IFNDEF __TMT__}
  vid_Deinit;
{$ENDIF}
end;

{$IFDEF __TMT__}

procedure emulate_screen_800x600_1;

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
        mov     edi,dword ptr [_FrameBuffer]
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

procedure emulate_screen_800x600_2;

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
        mov     edi,dword ptr [_FrameBuffer]
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

procedure emulate_screen_1024x768;

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
        mov     edi,dword ptr [_FrameBuffer]
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

procedure emulate_screen;
begin
  If (program_screen_mode < 3) or
     ((program_screen_mode = 3) and (comp_text_mode < 2)) then
    EXIT;
  If NOT (_screen_refresh_pending_frames > fps_down_factor) then
    EXIT
  else _screen_refresh_pending_frames := 0;
  Case program_screen_mode of
    3: emulate_screen_800x600_1;
    4: emulate_screen_800x600_2;
    5: emulate_screen_1024x768;
  end;
end;

{$ELSE}

procedure emulate_screen_720x480;

var
   bit_pos,bit_mask: Byte;
   pos_x,pos_y: Byte;
   skip: Dword;
   framebuffer_end: Dword;
   loop_idx1,loop_idx2,loop_idx3,
   loop_idx4: Dword;

begin
  asm
        mov     eax,_cursor_blink_factor
        cmp     _cursor_blink_pending_frames,eax
        jnae    @@1
        mov     _cursor_blink_pending_frames,0
        xor     byte ptr [cursor_sync],1
@@1:    lea     esi,[font8x16]
        mov     edi,dword ptr [_FrameBuffer]
        mov     framebuffer_end,edi
        add     framebuffer_end,720*480
        mov     ebx,dword ptr [screen_ptr]
        mov     eax,virtual_screen__first_row
        mov     skip,eax
        mov     loop_idx1,40
        mov     pos_y,1
@@2:    mov     bit_pos,0
        mov     loop_idx2,16
@@3:    mov     loop_idx3,90
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
        cmp     skip,0
        jz      @@6
        dec     skip
        jmp     @@9
@@6:    cmp     cursor_sync,1
        jnz     @@7
        movzx   eax,byte ptr [pos_x]
        cmp     al,byte ptr [virtual_cur_pos]
        jnz     @@7
        mov     ax,word ptr [virtual_cur_shape]
        cmp     bit_pos,ah
        jb      @@7
        cmp     bit_pos,al
        ja      @@7
        movzx   eax,pos_y
        cmp     al,byte ptr [virtual_cur_pos+1]
        jnz     @@7
        mov     al,[ebx+1]
        and     al,01111b
        cmp     edi,framebuffer_end
        ja      @@9
        stosb
        jmp     @@9
@@7:    movzx   eax,bit_mask
        test    dl,al
        jz      @@8
        mov     al,[ebx+1]
        and     al,01111b
        cmp     edi,framebuffer_end
        ja      @@9
        stosb
        jmp     @@9
@@8:    mov     al,[ebx+1]
        shr     al,4
        cmp     edi,framebuffer_end
        ja      @@9
        stosb
@@9:    dec     loop_idx4
        cmp     loop_idx4,0
        ja      @@5
        add     ebx,2
        inc     pos_x
        dec     loop_idx3
        cmp     loop_idx3,0
        ja      @@4
        sub     ebx,90*2
        inc     bit_pos
        dec     loop_idx2
        cmp     loop_idx2,0
        ja      @@3
        inc     pos_y
        add     ebx,90*2
        dec     loop_idx1
        cmp     loop_idx1,0
        ja      @@2
  end;
end;

procedure emulate_screen_960x800;

var
   bit_pos,bit_mask: Byte;
   pos_x,pos_y: Byte;
   loop_idx1,loop_idx2,loop_idx3,
   loop_idx4: Dword;

begin
  asm
        mov     eax,_cursor_blink_factor
        cmp     _cursor_blink_pending_frames,eax
        jnae    @@1
        mov     _cursor_blink_pending_frames,0
        xor     byte ptr [cursor_sync],1
@@1:    lea     esi,[font8x16]
        mov     edi,dword ptr [_FrameBuffer]
        mov     ebx,dword ptr [screen_ptr]
        mov     loop_idx1,50
        mov     pos_y,1
@@2:    mov     bit_pos,0
        mov     loop_idx2,16
@@3:    mov     loop_idx3,120
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
@@6:    cmp     cursor_sync,1
        jnz     @@7
        movzx   eax,byte ptr [pos_x]
        cmp     al,byte ptr [virtual_cur_pos]
        jnz     @@7
        mov     ax,word ptr [virtual_cur_shape]
        cmp     bit_pos,ah
        jb      @@7
        cmp     bit_pos,al
        ja      @@7
        movzx   eax,pos_y
        cmp     al,byte ptr [virtual_cur_pos+1]
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
        sub     ebx,120*2
        inc     bit_pos
        dec     loop_idx2
        cmp     loop_idx2,0
        ja      @@3
        inc     pos_y
        add     ebx,120*2
        dec     loop_idx1
        cmp     loop_idx1,0
        ja      @@2
  end;
end;

procedure emulate_screen_1440x960;

var
   bit_pos,bit_mask: Byte;
   pos_x,pos_y: Byte;
   loop_idx1,loop_idx2,loop_idx3,
   loop_idx4: Dword;

begin
  asm
        mov     eax,_cursor_blink_factor
        cmp     _cursor_blink_pending_frames,eax
        jnae    @@1
        mov     _cursor_blink_pending_frames,0
        xor     byte ptr [cursor_sync],1
@@1:    lea     esi,[font8x16]
        mov     edi,dword ptr [_FrameBuffer]
        mov     ebx,dword ptr [screen_ptr]
        mov     loop_idx1,60
        mov     pos_y,1
@@2:    mov     bit_pos,0
        mov     loop_idx2,16
@@3:    mov     loop_idx3,180
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
@@6:    cmp     cursor_sync,1
        jnz     @@7
        movzx   eax,byte ptr [pos_x]
        cmp     al,byte ptr [virtual_cur_pos]
        jnz     @@7
        mov     ax,word ptr [virtual_cur_shape]
        cmp     bit_pos,ah
        jb      @@7
        cmp     bit_pos,al
        ja      @@7
        movzx   eax,pos_y
        cmp     al,byte ptr [virtual_cur_pos+1]
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
        sub     ebx,180*2
        inc     bit_pos
        dec     loop_idx2
        cmp     loop_idx2,0
        ja      @@3
        inc     pos_y
        add     ebx,180*2
        dec     loop_idx1
        cmp     loop_idx1,0
        ja      @@2
  end;
end;

procedure emulate_screen_proc;
begin
  _update_sdl_screen := FALSE;
  If Compare(screen_ptr,ptr_screen_mirror,MAX_COLUMNS*MAX_ROWS*2) then EXIT
  else ScreenMemCopy(screen_ptr,ptr_screen_mirror);
  _cursor_blink_factor := ROUND(13/100*sdl_frame_rate);
  _update_sdl_screen := TRUE;
  Case program_screen_mode of
    0: emulate_screen_720x480;
    1: emulate_screen_960x800;
    2: emulate_screen_1440x960;
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

procedure emulate_screen;

const
   frame_start: Longint = 0;
   frame_end: Longint = 0;
   actual_frame_end: Longint = 0;

begin
  realtime_gfx_poll_proc;
  emulate_screen_proc;
  If _update_sdl_screen then SDL_Flip(screen);

  If _emulate_screen_without_delay then _emulate_screen_without_delay := FALSE
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
