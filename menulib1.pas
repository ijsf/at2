unit MenuLib1;
{$PACKRECORDS 1}
interface

uses
  AdT2sys,Adt2vscr,AdT2unit,AdT2keyb,AdT2ext2,
  DialogIO,StringIO,TxtScrIO;

const
  MenuLib1_mn_setting: Record
                         frame_type:     String;
                         shadow_enabled: Boolean;
                         posbar_enabled: Boolean;
                         title_attr,
                         menu_attr,
                         text_attr,
                         text2_attr,
                         default_attr,
                         short_attr,
                         short2_attr,
                         disbld_attr,
                         contxt_attr,
                         contxt2_attr:   Byte;
                         center_box:     Boolean;
                         cycle_moves:    Boolean;
                         edit_contents:  Boolean;
                         reverse_use:    Boolean;
                         fixed_len:      Byte;
                         terminate_keys: array[1..50] of Word;
                       end

  = (frame_type:     single;
     shadow_enabled: TRUE;
     posbar_enabled: TRUE;
     title_attr:     $0f;
     menu_attr:      $07;
     text_attr:      $07;
     text2_attr:     $70;
     default_attr:   $0f;
     short_attr:     $0f;
     short2_attr:    $70;
     disbld_attr:    $07;
     contxt_attr:    $0f;
     contxt2_attr:   $07;
     center_box:     TRUE;
     cycle_moves:    TRUE;
     edit_contents:  FALSE;
     reverse_use:    FALSE;
     fixed_len:      0;
     terminate_keys: ($011b,$1c0d,$0000,$0000,$0000,
                      $0000,$0000,$0000,$0000,$0000,
                      $0000,$0000,$0000,$0000,$0000,
                      $0000,$0000,$0000,$0000,$0000,
                      $0000,$0000,$0000,$0000,$0000,
                      $0000,$0000,$0000,$0000,$0000,
                      $0000,$0000,$0000,$0000,$0000,
                      $0000,$0000,$0000,$0000,$0000,
                      $0000,$0000,$0000,$0000,$0000,
                      $0000,$0000,$0000,$0000,$0000));
var
  MenuLib1_mn_environment: Record
                             v_dest:     Pointer;
                             keystroke:  Word;
                             context:    String;
                             unpolite:   Boolean;
                             winshade:   Boolean;
                             edit_pos:   Byte;
                             curr_pos:   Word;
                             ext_proc:   procedure;
                             refresh:    procedure;
                             do_refresh: Boolean;
                             preview:    Boolean;
                             descr_len:  Byte;
                             descr:      Pointer;
                           end;

function MenuLib1_Menu(var data; x,y: Byte; spos: Word;
                       len,len2: Byte; count: Word; title: String): Word;
procedure MenuLib1_Init;

implementation

type
//  pDBUFFR = ^tDBUFFR;
  tDBUFFR = array[1.. 100] of Record
                                str: String;
                                pos: Byte;
                                key: Char;
                                use: Boolean;
                              end;
type
//  pMBUFFR = ^tMBUFFR;
  tMBUFFR = array[1..16384] of Record
                                 key: Char;
                                 use: Boolean;
                               end;
type
//  pBACKUP = ^tBACKUP;
  tBACKUP = Record
              cursor: Longint;
              oldx,
              oldy:   Byte;
              screen: array[1..8000] of Byte
            end;
var
  i,k,m,max: Word;
  len2b,page,first,last,temp,temp2,opage,opos: Word;
  old_fr_shadow_enabled: Boolean;
  key:    Word;
  solid:  Boolean;
  qflg:   Boolean;
  mbuf:   tMBUFFR;
  contxt: String;
  backup: tBACKUP;

var
  mnu_x,mnu_y,mnu_len,mnu_len2: Byte;
  mnu_data: Pointer;
  mnu_count: Word;

var
  vscrollbar_pos: Word;

function LookUpKey(key: Word; var table; size: Byte): Boolean; assembler;
asm
        push    ecx
        push    esi
        mov     esi,[table]
        xor     ecx,ecx
        mov     cl,size
        xor     eax,eax
        mov     al,1
        jecxz   @@3
@@1:    lodsw
        cmp     ax,key
        jz      @@2
        loop    @@1
@@2:    xor     eax,eax
        jecxz   @@3
        mov     al,1
@@3:    pop     esi
        pop     ecx
end;

function OutKey(str: String): Char;

var
  result: Char;

begin
  If SYSTEM.Pos('~',str) = 0 then result := '~'
  else If str[SYSTEM.Pos('~',str)+2] <> '~' then result := '~'
       else result := str[SYSTEM.Pos('~',str)+1];
  OutKey := result;
end;

function pstr(item: Word): String;

var
  temp: String;

begin
  If _debug_ then
    _debug_str_ := 'MENULIB1.PAS:pstr';
  Move(POINTER(Ptr(0,Ofs(mnu_data^)+(item-1)*(mnu_len+1)))^,temp,mnu_len+1);
  If NOT solid then pstr := ExpStrR(temp,mnu_len-2,' ')
  else pstr := ExpStrR(temp,mnu_len,' ');
end;

function pdes(item: Word): String;

var
  temp: String;

begin
  If _debug_ then
    _debug_str_ := 'MENULIB1.PAS:pdes';
  If mn_environment.descr <> NIL then
    Move(POINTER(Ptr(0,Ofs(mn_environment.descr^)+
      (item-1)*(mn_environment.descr_len+1)))^,temp,mn_environment.descr_len+1)
  else temp := '';
  pdes := ExpStrR(temp,mn_environment.descr_len,' ');
end;

procedure refresh;

procedure ShowCStr_clone(var dest; x,y: Byte; str: String;
                                   atr1,atr2,atr3,atr4: Byte);
var
  temp,len: Byte;
  highlighted: Boolean;

begin
  If _debug_ then
    _debug_str_ := 'MENULIB1.PAS:refresh:ShowCStr_clone';
  If NOT (MenuLib1_mn_setting.fixed_len <> 0) then
    begin
      ShowCStr(dest,x,y,str,atr1,atr2);
      EXIT;
    end;

  highlighted := FALSE;
  len := 0;
  For temp := 1 to Length(str) do
    If (str[temp] = '~') then highlighted := NOT highlighted
    else begin
           If (len < MenuLib1_mn_setting.fixed_len) then
             begin
               If NOT highlighted then ShowStr(dest,x+len,y,str[temp],atr1)
               else ShowStr(dest,x+len,y,str[temp],atr2);
               Inc(len);
             end
           else
             begin
               If NOT highlighted then ShowStr(dest,x+len,y,str[temp],atr3)
               else ShowStr(dest,x+len,y,str[temp],atr4);
               Inc(len);
             end
         end;
end;

begin
  If _debug_ then
    _debug_str_ := 'MENULIB1.PAS:refresh';
  If (page = opage) and (k = opos) and NOT MenuLib1_mn_environment.do_refresh then EXIT
  else begin
         opage := page;
         opos  := k;
         MenuLib1_mn_environment.do_refresh := FALSE;
       end;

  For i := page to mnu_len2+page-1 do
    If (i = k+page-1) then
      ShowCStr_clone(MenuLib1_mn_environment.v_dest^,mnu_x+1,mnu_y+k,
                     ExpStrR(pstr(k+page-1)+pdes(k+page-1),
                     max+(Length(pstr(k+page-1))+Length(pdes(k+page-1))-
                     CStrLen(pstr(k+page-1)+pdes(k+page-1))),' '),
                     MenuLib1_mn_setting.text2_attr,MenuLib1_mn_setting.short2_attr,
                     MenuLib1_mn_setting.text_attr,MenuLib1_mn_setting.short_attr)
    else
      If mbuf[i].use then
        ShowCStr(MenuLib1_mn_environment.v_dest^,mnu_x+1,mnu_y+i-page+1,
                 ExpStrR(pstr(i)+pdes(i),
                 max+(Length(pstr(i))+Length(pdes(k+page-1))-
                 CStrLen(pstr(i)+pdes(i))),' '),
                 MenuLib1_mn_setting.text_attr,MenuLib1_mn_setting.short_attr)
      else
        ShowCStr(MenuLib1_mn_environment.v_dest^,mnu_x+1,mnu_y+i-page+1,
                 ExpStrR(pstr(i)+pdes(i),
                 max+(Length(pstr(i))+Length(pdes(k+page-1))-
                 CStrLen(pstr(i)+pdes(i))),' '),
                 MenuLib1_mn_setting.disbld_attr,MenuLib1_mn_setting.disbld_attr);

  vscrollbar_pos :=
    VScrollBar(MenuLib1_mn_environment.v_dest^,mnu_x+max+1,mnu_y+1,temp2,mnu_count,k+page-1,
               vscrollbar_pos,MenuLib1_mn_setting.menu_attr,MenuLib1_mn_setting.menu_attr);
end;

function MenuLib1_Menu(var data; x,y: Byte; spos: Word;
                       len,len2: Byte; count: Word; title: String): Word;

procedure SubPos(var p: Word);

var
  temp: Word;

begin
  temp := p;
  If (temp > 1) and mbuf[temp+page-2].use then Dec(temp)
  else If temp > 1 then begin Dec(temp); SubPos(temp); end
       else If page > first then Dec(page);
  If mbuf[temp+page-1].use then p := temp
  else If (temp+page-1 > first) then SubPos(temp);
end;

procedure AddPos(var p: Word);

var
  temp: Word;

begin
  temp := p;
  If (temp < len2) and (temp < last) and mbuf[temp+page].use then Inc(temp)
  else If (temp < len2) and (temp < last) then begin Inc(temp); AddPos(temp); end
       else If page+temp <= last then Inc(page);
  If mbuf[temp+page-1].use then p := temp
  else If (temp+page-1 < last) then AddPos(temp);
end;

procedure RetKey(code: Byte; var p: Word);

var
  temp: Byte;

begin
  p := 0;
  For temp := 1 to count do
    If (p = 0) and (UpCase(mbuf[temp].key) = UpCase(CHR(code))) then
      p := temp;
end;

procedure edit_contents(item: Word);

var
  temp: String;

begin
  _debug_str_ := 'MENULIB1.PAS:MenuLib1_Menu:edit_contents';
  is_setting.append_enabled := TRUE;
  is_setting.character_set  := [#$20..#$ff];
  is_environment.locate_pos := 1;

  If (MenuLib1_mn_environment.edit_pos > 0) and (MenuLib1_mn_environment.edit_pos < max-2) then
    temp := Copy(pstr(item),MenuLib1_mn_environment.edit_pos+1,
                      Length(pstr(item))-MenuLib1_mn_environment.edit_pos+1)
  else
    temp := CutStr(pstr(item));

  While (temp <> '') and (temp[Length(temp)] = ' ') do Delete(temp,Length(temp),1);
  temp := InputStr(temp,x+1+MenuLib1_mn_environment.edit_pos,y+k,
               max-2-MenuLib1_mn_environment.edit_pos+1,
               max-2-MenuLib1_mn_environment.edit_pos+1,
               MenuLib1_mn_setting.text2_attr,MenuLib1_mn_setting.default_attr);

  If (is_environment.keystroke = $1c0d) then
    begin
      If (MenuLib1_mn_environment.edit_pos > 0) and (MenuLib1_mn_environment.edit_pos < max-2) then
        temp := Copy(pstr(item),1,MenuLib1_mn_environment.edit_pos)+temp
      else
        temp := CutStr(temp);
      Move(temp,POINTER(Ptr(0,Ofs(data)+(item-1)*(len+1)))^,len+1);
    end;

  ShowCStr(MenuLib1_mn_environment.v_dest^,x+1,y+k,
           ExpStrR(pstr(item),max+(Length(pstr(item)))-
           CStrLen(pstr(item)),' '),
           MenuLib1_mn_setting.text2_attr,MenuLib1_mn_setting.short2_attr);
end;

begin { MenuLib1_Menu }
  _debug_str_ := 'MENULIB1.PAS:MenuLib1_Menu';
  If count = 0 then begin MenuLib1_Menu := 0; EXIT; end;
  max := Length(title);
  mnu_data := Addr(data); mnu_count := count; mnu_len := len;

  If NOT MenuLib1_mn_environment.unpolite then
    begin
      Move(MenuLib1_mn_environment.v_dest^,backup.screen,SizeOf(backup.screen));
      backup.cursor := GetCursor;
      backup.oldx   := WhereX;
      backup.oldy   := WhereY;
    end;

  If (count < 1) then EXIT;
  vscrollbar_pos := BYTE_NULL;

  If NOT MenuLib1_mn_environment.preview then HideCursor;
  temp := 0;

  For i := 1 to count do
    begin
      mbuf[i].key := OutKey(pstr(i));
      If NOT MenuLib1_mn_setting.reverse_use then mbuf[i].use := mbuf[i].key <> '~'
      else mbuf[i].use := NOT (mbuf[i].key <> '~');
      If mbuf[i].use then temp := 1;
    end;

  solid := FALSE;
  If (temp = 0) then
    begin
      For temp := 1 to count do mbuf[temp].use := TRUE;
      solid := TRUE;
    end;

  For i := 1 to count do
    If max < CStrLen(pstr(i))+MenuLib1_mn_environment.descr_len then
      max := CStrLen(pstr(i))+MenuLib1_mn_environment.descr_len;

  If MenuLib1_mn_setting.center_box then
    begin
      x := (work_MaxCol-max-2) DIV 2+(work_MaxCol-max-2) MOD 2;
      y := (work_MaxLn-len2-1) DIV 2+(work_MaxLn-len2-1) MOD 2;
    end;

  mnu_x := x; mnu_y := y;
  len2b := len2;

  If NOT MenuLib1_mn_environment.unpolite then
    begin
      old_fr_shadow_enabled := fr_setting.shadow_enabled;
      fr_setting.shadow_enabled := MenuLib1_mn_setting.shadow_enabled;
      fr_setting.update_area := FALSE;
      Frame(MenuLib1_mn_environment.v_dest^,x,y,x+max+1,y+len2+1,MenuLib1_mn_setting.menu_attr,
            title,MenuLib1_mn_setting.title_attr,MenuLib1_mn_setting.frame_type);
      fr_setting.update_area := TRUE;
      fr_setting.shadow_enabled := old_fr_shadow_enabled;

      contxt := DietStr(MenuLib1_mn_environment.context,max+
        (Length(MenuLib1_mn_environment.context)-CStrLen(MenuLib1_mn_environment.context)));
      ShowCStr(MenuLib1_mn_environment.v_dest^,x+max+1-CStrLen(contxt),y+len2+1,
               contxt,MenuLib1_mn_setting.contxt_attr,MenuLib1_mn_setting.contxt2_attr);

      temp2 := len2;
      If len2 > count then len2 := count;
      If len2 < 1 then len2 := 1;
      If spos < 1 then spos := 1;
      If spos > count then spos := count;

      mnu_len2 := len2;
      MenuLib1_mn_environment.refresh := refresh;

      first := 1; While NOT mbuf[first].use do Inc(first);
      last  := count; While NOT mbuf[last].use do Dec(last);

      If (spos < first) or (spos > last) then spos := first;
      k := 1; page := 1; opage := WORD_NULL; opos := WORD_NULL;
      While (k+page-1 < spos) do AddPos(k);
    end;

  MenuLib1_mn_environment.curr_pos := k+page-1;
  MenuLib1_mn_environment.keystroke := WORD_NULL;
  If (Addr(MenuLib1_mn_environment.ext_proc) <> NIL) then MenuLib1_mn_environment.ext_proc;
    
  qflg := FALSE;
  If MenuLib1_mn_environment.preview then
    begin
      MenuLib1_mn_environment.preview  := FALSE;
      MenuLib1_mn_environment.unpolite := TRUE;
      refresh;
    end
  else
    Repeat
      key := getkey;
      If LookUpKey(key,MenuLib1_mn_setting.terminate_keys,50) then
        If NOT ((key = MenuLib1_mn_setting.terminate_keys[2]) and
                 MenuLib1_mn_setting.edit_contents) then qflg := TRUE
        else edit_contents(k+page-1);

      If NOT qflg then
        Case LO(key) of
          $00: If NOT shift_pressed and
                  NOT ctrl_pressed and NOT alt_pressed then
                 Case HI(key) of
                   $48: If (page+k-1 > first) or
                           NOT MenuLib1_mn_setting.cycle_moves then SubPos(k)
                        else begin
                               k := len2; page := count-len2+1;
                               If NOT mbuf[k+page-1].use then SubPos(k);
                             end;

                   $50: If (page+k-1 < last) or
                           NOT MenuLib1_mn_setting.cycle_moves then AddPos(k)
                        else begin
                               k := 1; page := 1;
                               If NOT mbuf[k+page-1].use then AddPos(k);
                             end;

                   $47: begin
                          k := 1; page := 1;
                          If NOT mbuf[k+page-1].use then AddPos(k);
                        end;

                   $4f: begin
                          k := len2; page := count-len2+1;
                          If NOT mbuf[k+page-1].use then SubPos(k);
                        end;

                   $49: For temp := 1 to len2-1 do SubPos(k);
                   $51: For temp := 1 to len2-1 do AddPos(k);
                 end;

        $32..$0ff:
          begin
            RetKey(Lo(key),m);
            If m <> 0 then
              begin
                refresh;
                k := m;
                If NOT ((key = MenuLib1_mn_setting.terminate_keys[2]) and
                         MenuLib1_mn_setting.edit_contents) then qflg := TRUE
                else edit_contents(m);
              end;
          end;
      end;

      MenuLib1_mn_environment.curr_pos := k+page-1;
      refresh;
      MenuLib1_mn_environment.keystroke := key;
      If (Addr(MenuLib1_mn_environment.ext_proc) <> NIL) then MenuLib1_mn_environment.ext_proc;
      emulate_screen;
      // keyboard_reset_buffer;
    until qflg or _force_program_quit;

  If MenuLib1_mn_environment.winshade and NOT MenuLib1_mn_environment.unpolite then
    begin
      If Addr(move_to_screen_routine) <> NIL then
        begin
          move_to_screen_data := Addr(backup.screen);
          move_to_screen_area[1] := x;
          move_to_screen_area[2] := y;
          move_to_screen_area[3] := x+max+1+2;
          move_to_screen_area[4] := y+len2b+1+1;
          move_to_screen_routine;
         end
      else
        Move(backup.screen,MenuLib1_mn_environment.v_dest^,SizeOf(backup.screen));
    end;

  MenuLib1_Menu := k+page-1;
end;

procedure MenuLib1_Init;
begin
    MenuLib1_mn_setting.frame_type     := single;
    MenuLib1_mn_setting.center_box     := FALSE;
    MenuLib1_mn_setting.shadow_enabled := FALSE;
    MenuLib1_mn_setting.cycle_moves    := FALSE;
    MenuLib1_mn_setting.title_attr     := dialog_background+dialog_title;
    MenuLib1_mn_setting.menu_attr      := dialog_background+dialog_text;
    MenuLib1_mn_setting.text_attr      := dialog_background+dialog_button;
    MenuLib1_mn_setting.text2_attr     := dialog_sel_btn_bck+dialog_sel_btn;
    MenuLib1_mn_setting.default_attr   := dialog_def_bckg+dialog_def;
    MenuLib1_mn_setting.short_attr     := dialog_background+dialog_short;
    MenuLib1_mn_setting.short2_attr    := dialog_sel_btn_bck+dialog_sel_short;
    MenuLib1_mn_setting.disbld_attr    := dialog_background+dialog_button_dis;
    MenuLib1_mn_setting.contxt_attr    := dialog_background+dialog_context;
    MenuLib1_mn_setting.contxt2_attr   := dialog_background+dialog_context_dis;
    MenuLib1_mn_setting.terminate_keys[3] := kTAB;
    MenuLib1_mn_setting.terminate_keys[4] := kLEFT;
    MenuLib1_mn_setting.terminate_keys[5] := kRIGHT;
    MenuLib1_mn_setting.terminate_keys[6] := kCtrlO;
    MenuLib1_mn_setting.terminate_keys[7] := kF1;
    MenuLib1_mn_setting.terminate_keys[8] := kShTAB;

    MenuLib1_mn_environment.v_dest     := screen_ptr;
    MenuLib1_mn_environment.keystroke  := $0000;
    MenuLib1_mn_environment.context    := '';
    MenuLib1_mn_environment.unpolite   := FALSE;
    MenuLib1_mn_environment.winshade   := TRUE;
    MenuLib1_mn_environment.ext_proc   := NIL;
    MenuLib1_mn_environment.refresh    := NIL;
    MenuLib1_mn_environment.do_refresh := FALSE;
    MenuLib1_mn_environment.preview    := FALSE;
    MenuLib1_mn_environment.descr_len  := 0;
    MenuLib1_mn_environment.descr      := NIL;
end;

end.
