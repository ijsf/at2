unit DialogIO;
{$PACKRECORDS 1}
interface

uses
  DOS,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  AdT2sys,AdT2vscr,AdT2unit,AdT2keyb,AdT2ext2,
  StringIO,ParserIO,TxtScrIO;

type
  tDIALOG_SETTING = Record
                      frame_type:     String;
                      shadow_enabled: Boolean;
                      title_attr:     Byte;
                      box_attr:       Byte;
                      text_attr:      Byte;
                      text2_attr:     Byte;
                      keys_attr:      Byte;
                      keys2_attr:     Byte;
                      short_attr:     Byte;
                      short2_attr:    Byte;
                      disbld_attr:    Byte;
                      contxt_attr:    Byte;
                      contxt2_attr:   Byte;
                      xstart:         Byte;
                      ystart:         Byte;
                      center_box:     Boolean;
                      center_text:    Boolean;
                      cycle_moves:    Boolean;
                      all_enabled:    Boolean;
                      terminate_keys: array[1..50] of Word;
                    end;
type
  tMENU_SETTING = Record
                    frame_type:     String;
                    frame_enabled:  Boolean;
                    shadow_enabled: Boolean;
                    posbar_enabled: Boolean;
                    title_attr:     Byte;
                    menu_attr:      Byte;
                    text_attr:      Byte;
                    text2_attr:     Byte;
                    default_attr:   Byte;
                    short_attr:     Byte;
                    short2_attr:    Byte;
                    disbld_attr:    Byte;
                    contxt_attr:    Byte;
                    contxt2_attr:   Byte;
                    topic_attr:     Byte;
                    hi_topic_attr:  Byte;
                    topic_mask_chr: Set of Char;
                    center_box:     Boolean;
                    cycle_moves:    Boolean;
                    edit_contents:  Boolean;
                    reverse_use:    Boolean;
                    show_scrollbar: Boolean;
                    topic_len:      Byte;
                    fixed_len:      Byte;
                    terminate_keys: array[1..50] of Word;
                  end;
type
  tDIALOG_ENVIRONMENT = Record
                          keystroke: Word;
                          context:   String;
                          input_str: String;
                        end;
type
  tMENU_ENVIRONMENT = Record
                        v_dest:      Pointer;
                        keystroke:   Word;
                        context:     String;
                        unpolite:    Boolean;
                        winshade:    Boolean;
                        intact_area: Boolean;
                        edit_pos:    Byte;
                        curr_page:   Word;
                        curr_pos:    Word;
                        curr_item:   String;
                        ext_proc:    procedure;
                        ext_proc_rt: procedure;
                        refresh:     procedure;
                        do_refresh:  Boolean;
                        preview:     Boolean;
                        fixed_start: Byte;
                        descr_len:   Byte;
                        descr:       Pointer;
                        is_editing:  Boolean;
                        xpos,ypos:   Byte;
                        xsize,ysize: Byte;
                        desc_pos:    Byte;
                      end;

const
  FILENAME_SIZE = 80;
  DIR_SIZE = 170;
  PATH_SIZE = 255;

type
  tFSELECT_ENVIRONMENT = Record
                           last_file: String[FILENAME_SIZE];
                           last_dir:  String[DIR_SIZE];
                         end;
const
  dl_setting: tDIALOG_SETTING =
    (frame_type:     single;
     shadow_enabled: TRUE;
     title_attr:     $0f;
     box_attr:       $07;
     text_attr:      $07;
     text2_attr:     $0f;
     keys_attr:      $07;
     keys2_attr:     $70;
     short_attr:     $0f;
     short2_attr:    $70;
     disbld_attr:    $07;
     contxt_attr:    $0f;
     contxt2_attr:   $07;
     xstart:         01;
     ystart:         01;
     center_box:     TRUE;
     center_text:    TRUE;
     cycle_moves:    TRUE;
     all_enabled:    FALSE;
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
const
  mn_setting: tMENU_SETTING =
    (frame_type:     single;
     frame_enabled:  TRUE;
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
     topic_attr:     $07;
     hi_topic_attr:  $0f;
     topic_mask_chr: [];
     center_box:     TRUE;
     cycle_moves:    TRUE;
     edit_contents:  FALSE;
     reverse_use:    FALSE;
     show_scrollbar: TRUE;
     topic_len:      0;
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
const
  move_to_screen_data: Pointer = NIL;
  move_to_screen_area: array[1..4] of Byte = (0,0,0,0);
  move_to_screen_routine: procedure = move2screen;

var
  dl_environment: tDIALOG_ENVIRONMENT;
  mn_environment: tMENU_ENVIRONMENT;
  fs_environment: tFSELECT_ENVIRONMENT;

function Dialog(text,keys,title: String; spos: Byte): Byte;
function Menu(var data; x,y: Byte; spos: Word;
              len,len2: Byte; count: Word; title: String): Word;
function Fselect(mask: String): String;
function HScrollBar(var dest; x,y: Byte; size: Byte; len1,len2,pos: Word;
                    atr1,atr2: Byte): Word;
function VScrollBar(var dest; x,y: Byte; size: Byte; len1,len2,pos: Word;
                    atr1,atr2: Byte): Word;
procedure DialogIO_Init;

function Lower_file(s: String) : String;
function iCASE_file(s: String) : String;

implementation

type
  tDBUFFR = array[1.. 100] of Record
                                str: String;
                                pos: Byte;
                                key: Char;
                                use: Boolean;
                              end;
type
  tMBUFFR = array[1..16384] of Record
                                 key: Char;
                                 use: Boolean;
                               end;
type
  tBACKUP = Record
              cursor: Longint;
              oldx,
              oldy:   Byte;
              screen: array[1..180*60*SizeOf(WORD)] of Byte;
            end;
var
  i,k,l,m,pos,max,mx2,num,nm2,xstart,ystart,count,
  ln,ln1,len2b,atr1,atr2,page,first,last,temp,temp2,opage,opos: Word;
  old_fr_shadow_enabled: Boolean;
  key:    Word;
  str:    String;
  solid:  Boolean;
  qflg:   Boolean;
  dbuf:   tDBUFFR;
  mbuf:   tMBUFFR;
  contxt: String;
  backup: tBACKUP;

function iCASE_file(s: String) : String;

begin
{$ifdef UNIX}
  iCASE_file := s;
{$else}
  iCASE_file := iCASE(s);
{$endif}
end;


function Lower_file(s: String) : String;

begin
{$ifdef UNIX}
  Lower_file := s;
{$else}
  Lower_file := Lower(s);
{$endif}
end;


function OutStr(var queue; len: Byte; order: Word): String; assembler;
asm
        push    ecx
        push    esi
        push    edi
        mov     esi,[queue]
        mov     edi,@result
        xor     ecx,ecx
        mov     cx,order
        dec     ecx
        xor     eax,eax
        mov     al,len
        inc     eax
        jecxz   @@2
@@1:    add     esi,eax
        loop    @@1
@@2:    xor     ecx,ecx
        mov     cl,al
        rep     movsb
        pop     edi
        pop     esi
        pop     ecx
end;

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

function ReadChunk(str: String; pos: Byte): String;

var
  result: String;

begin
  Delete(str,1,pos-1);
  If SYSTEM.Pos('$',str) = 0 then result := ''
  else result := Copy(str,1,SYSTEM.Pos('$',str)-1);
  ReadChunk := result;
end;

function Dialog(text,keys,title: String; spos: Byte): Byte;

procedure SubPos(var p: Word);

var
  temp: Word;

begin
  temp := p;
  If (temp > 1) and dbuf[temp-1].use then Dec(temp)
  else If temp > 1 then begin Dec(temp); SubPos(temp); end;
  If dbuf[temp].use then p := temp;
end;

procedure AddPos(var p: Word);

var
  temp: Word;

begin
  temp := p;
  If (temp < nm2) and dbuf[temp+1].use then Inc(temp)
  else If temp < nm2 then begin Inc(temp); AddPos(temp); end;
  If dbuf[temp].use then p := temp;
end;

procedure ShowItem;
begin
  If k = 0 then EXIT;
  If k <> l then
    ShowCStr(screen_ptr^,dbuf[l].pos,ystart+num+1,dbuf[l].str,
             dl_setting.keys_attr,dl_setting.short_attr);

    ShowCStr(screen_ptr^,dbuf[k].pos,ystart+num+1,dbuf[k].str,
             dl_setting.keys2_attr,dl_setting.short2_attr);
  l := k;
end;

procedure RetKey(code: Byte; var p: Word);

var
  temp: Byte;

begin
  p := 0;
  For temp := 1 to nm2 do
    If (p = 0) and (UpCase(dbuf[temp].key) = UpCase(CHR(code))) then p := temp;
end;

function CurrentKey(pos: Byte): Byte;

var
  i,temp: Byte;

begin
  temp := 0;
  For i := 1 to nm2 do
    If pos in [dbuf[i].pos,dbuf[i].pos+CStrLen(dbuf[i].str)-1] then
      temp := i;
  CurrentKey := temp;
end;

begin
  _debug_str_ := 'DIALOGIO.PAS:Dialog';
  pos := 1;
  max := Length(title);
  num := 0;

  Move(screen_ptr^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;

  HideCursor;
  Repeat
    str := ReadChunk(text,pos);
    Inc(pos,Length(str)+1);
    If CStrLen(str) > max then max := CStrLen(str);
    If str <> '' then Inc(num);
  until (pos >= Length(text)) or (str = '');

  pos := 1;
  mx2 := 0;
  nm2 := 0;

  If Copy(keys,1,14) = '%string_input%' then
    begin
      Inc(pos,14);
      str := ReadChunk(keys,pos); ln := Str2num(str,10);
      If str = '' then EXIT;
      Inc(pos,Length(str)+1);

      str := ReadChunk(keys,pos); ln1 := Str2num(str,10); mx2 := ln1;
      If str = '' then EXIT;
      Inc(pos,Length(str)+1);

      str := ReadChunk(keys,pos); atr1 := Str2num(str,16);
      If str = '' then EXIT;
      Inc(pos,Length(str)+1);

      str := ReadChunk(keys,pos); atr2 := Str2num(str,16);
      If str = '' then EXIT;
      Inc(pos,Length(str)+1);
    end
  else
    begin
      Repeat
        str := ReadChunk(keys,pos);
        Inc(pos,Length(str)+1);
        If str <> '' then
          begin
            Inc(nm2);
            dbuf[nm2].str := ' '+str+' ';
            dbuf[nm2].key := OutKey(str);
            If NOT dl_setting.all_enabled then dbuf[nm2].use := dbuf[nm2].key <> '~'
            else dbuf[nm2].use := TRUE;
            If nm2 > 1 then
              begin
                dbuf[nm2].pos := dbuf[nm2-1].pos+CStrLen(dbuf[nm2-1].str)+1;
                Inc(mx2,CStrLen(dbuf[nm2].str)+1);
              end
            else
              begin
                dbuf[nm2].pos := 1;
                Inc(mx2,CStrLen(dbuf[nm2].str));
              end;
          end;
      until (pos >= Length(keys)) or (str = '');
    end;

  If max < mx2 then max := mx2
  else
    begin
      ln1 := max;
      If ln < max then ln := max;
    end;

  If dl_setting.center_box then
    begin
      xstart := (work_MaxCol-(max+4)) DIV 2+(work_MaxCol-(max+4)) MOD 2;
      ystart := (work_MaxLn -(num+2)) DIV 2+(work_MaxLn -(num+2)) MOD 2;
    end
  else
    begin
      xstart := dl_setting.xstart;
      ystart := dl_setting.ystart;
    end;

  old_fr_shadow_enabled := fr_setting.shadow_enabled;
  fr_setting.shadow_enabled := dl_setting.shadow_enabled;
  Frame(screen_ptr^,xstart,ystart,xstart+max+3,ystart+num+2,
        dl_setting.box_attr,title,dl_setting.title_attr,
        dl_setting.frame_type);
  fr_setting.shadow_enabled := old_fr_shadow_enabled;

  pos := 1;
  contxt := DietStr(dl_environment.context,max+
    (Length(dl_environment.context)-CStrLen(dl_environment.context)));
  ShowCStr(screen_ptr^,xstart+max+3-CStrLen(contxt),ystart+num+2,
           contxt,dl_setting.contxt_attr,dl_setting.contxt2_attr);

  For i := 1 to num do
    begin
      str := ReadChunk(text,pos);
      Inc(pos,Length(str)+1);
      If dl_setting.center_text then
        ShowCStr(screen_ptr^,xstart+2,ystart+i,
                 ExpStrL(str,Length(str)+(max-CStrLen(str)) DIV 2,' '),
                 dl_setting.text_attr,dl_setting.text2_attr)
      else
        ShowCStr(screen_ptr^,xstart+2,ystart+i,
                 str,dl_setting.text_attr,dl_setting.text2_attr);
    end;

  If Copy(keys,1,14) = '%string_input%' then
    begin
      ThinCursor;
      str := InputStr(dl_environment.input_str,
                      xstart+2,ystart+num+1,ln,ln1,atr1,atr2);
      If is_environment.keystroke = $1c0d then dl_environment.input_str := str;
      dl_environment.keystroke := is_environment.keystroke;
      HideCursor;
    end
  else
    begin
      For i := 1 to nm2 do
        begin
          Inc(dbuf[i].pos,xstart+(max-mx2) DIV 2+1);
          If dbuf[i].use then
            ShowCStr(screen_ptr^,dbuf[i].pos,ystart+num+1,
                     dbuf[i].str,dl_setting.keys_attr,dl_setting.short_attr)
          else
            ShowCStr(screen_ptr^,dbuf[i].pos,ystart+num+1,
                     dbuf[i].str,dl_setting.disbld_attr,dl_setting.disbld_attr);
        end;

      If spos < 1 then spos := 1;
      If spos > nm2 then spos := nm2;

      k := spos;
      l := 1;

      If NOT dbuf[k].use then
        begin
          SubPos(k);
          If NOT dbuf[k].use then AddPos(k);
        end;

      ShowItem;
      ShowItem;
      qflg := FALSE;
      If keys = '$' then EXIT;

      Repeat
        key := getkey;
        If LookUpKey(key,dl_setting.terminate_keys,50) then qflg := TRUE;

        If NOT qflg then
          Case LO(key) of
            $00: If NOT shift_pressed and
                    NOT ctrl_pressed and NOT alt_pressed then
                   Case HI(key) of
                     $4b: If (k > 1) or
                             NOT dl_setting.cycle_moves then SubPos(k)
                          else begin
                                 k := nm2;
                                 If NOT dbuf[k].use then SubPos(k);
                               end;

                     $4d: If (k < nm2) or
                             NOT dl_setting.cycle_moves then
                            begin
                              temp := k;
                              AddPos(k);
                              If (k = temp) then
                                begin
                                  k := 1;
                                  If NOT dbuf[k].use then AddPos(k);
                                end;
                            end
                          else begin
                                 k := 1;
                                 If NOT dbuf[k].use then AddPos(k);
                               end;

                     $47: begin
                            k := 1;
                            If NOT dbuf[k].use then AddPos(k);
                          end;

                     $4f: begin
                            k := nm2;
                            If NOT dbuf[k].use then SubPos(k);
                          end;
                   end;

            $20..$0ff:
              begin
                RetKey(LO(key),m);
                If m <> 0 then begin qflg := TRUE; k := m; end;
              end;
          end;

        ShowItem;
        emulate_screen;
      until qflg or _force_program_quit;

      Dialog := k;
      dl_environment.keystroke := key;
    end;

  If Addr(move_to_screen_routine) <> NIL then
    begin
      move_to_screen_data := Addr(backup.screen);
      move_to_screen_area[1] := xstart;
      move_to_screen_area[2] := ystart;
      move_to_screen_area[3] := xstart+max+3+2;
      move_to_screen_area[4] := ystart+num+2+1;
      move_to_screen_routine;
    end
  else
    Move(backup.screen,screen_ptr^,SizeOf(backup.screen));
end;

var
  mnu_x,mnu_y,mnu_len,mnu_len2,mnu_topic_len: Byte;
  mnu_data: Pointer;
  mnu_count: Word;

var
  vscrollbar_pos: Word;

function pstr(item: Word): String;

var
  temp: String;

begin
  If _debug_ then
    _debug_str_ := 'DIALOGIO.PAS:pstr';
  If (item <= mnu_count) then
    Move(POINTER(Ptr(0,Ofs(mnu_data^)+(item-1)*(mnu_len+1)))^,temp,mnu_len+1)
  else temp := '';
  If NOT solid then pstr := ExpStrR(temp,mnu_len-2,' ')
  else pstr := ExpStrR(temp,mnu_len,' ');
end;

function pstr2(item: Word): String;

var
  idx: Byte;
  temp,result: String;

begin
  If (item <= mnu_count) then
    Move(POINTER(Ptr(0,Ofs(mnu_data^)+(item-1)*(mnu_len+1)))^,temp,mnu_len+1)
  else temp := '';
  If NOT solid then temp := ExpStrR(temp,mnu_len-2,' ')
  else temp := ExpStrR(temp,mnu_len,' ');
  If (mn_setting.fixed_len <> 0) then result := temp
  else begin
         result := '';
         For idx := 1 to Length(temp) do
         If (temp[idx] in mn_setting.topic_mask_chr) then
           result := result+'`'+temp[idx]+'`'
         else result := result+temp[idx];
       end;
  pstr2 := result;
end;

function pdes(item: Word): String;

var
  temp: String;

begin
  If _debug_ then
    _debug_str_ := 'DIALOGIO.PAS:pdes';
  If (mn_environment.descr <> NIL) and (item <= mnu_count) then
    Move(POINTER(Ptr(0,Ofs(mn_environment.descr^)+
      (item-1)*(mn_environment.descr_len+1)))^,temp,mn_environment.descr_len+1)
  else temp := '';
  pdes := ExpStrR(temp,mn_environment.descr_len,' ');
end;

procedure refresh;

procedure ShowCStr_clone(var dest; x,y: Byte; str: String;
                                   atr1,atr2,atr3,atr4: Byte);
var
  temp,
  len,len2: Byte;
  highlighted: Boolean;

begin
  If _debug_ then
    _debug_str_ := 'DIALOGIO.PAS:refresh:ShowCStr_clone';
  If NOT (mn_setting.fixed_len <> 0) then
    begin
      ShowC3Str(dest,x,y,str,atr1,atr2,atr1 AND $0f0+mn_setting.topic_attr AND $0f);
      EXIT;
    end;

  highlighted := FALSE;
  len := 0;
  len2 := 0;
  For temp := 1 to Length(str) do
    If (str[temp] = '~') then highlighted := NOT highlighted
    else begin
           If (temp >= mn_environment.fixed_start) and
              (len < mn_setting.fixed_len) then
             begin
               If NOT highlighted then ShowStr(dest,x+len2,y,str[temp],atr1)
               else ShowStr(dest,x+len2,y,str[temp],atr2);
               Inc(len);
               Inc(len2);
             end
           else
             begin
               If NOT highlighted then ShowStr(dest,x+len2,y,str[temp],atr3)
               else ShowStr(dest,x+len2,y,str[temp],atr4);
               If (temp >= mn_environment.fixed_start) then Inc(len);
               Inc(len2);
             end
         end;
end;

begin { refresh }
  If _debug_ then
    _debug_str_ := 'DIALOGIO.PAS:refresh';
  If (page = opage) and (k = opos) and NOT mn_environment.do_refresh then EXIT
  else begin
         opage := page;
         opos  := k;
         mn_environment.do_refresh := FALSE;
       end;

  For i := page to mnu_len2+page-1 do
    If (i = k+page-1) then
      ShowCStr_clone(mn_environment.v_dest^,mnu_x+1,mnu_y+k,
                     ExpStrR(pstr2(k+page-1)+pdes(k+page-1),
                     max+(Length(pstr2(k+page-1))+Length(pdes(k+page-1))-
                     (C3StrLen(pstr2(k+page-1))+CStrLen(pdes(k+page-1)))),' '),
                     mn_setting.text2_attr,
                     mn_setting.short2_attr,
                     mn_setting.text_attr,
                     mn_setting.short_attr)
    else
      If (i-page+1 <= mnu_topic_len) then
        ShowCStr(mn_environment.v_dest^,mnu_x+1,mnu_y+i-page+1,
                 ExpStrR(pstr(i-page+1)+pdes(i-page+1),
                 max+(Length(pstr(i-page+1))+Length(pdes(k+page-1))-
                 CStrLen(pstr(i-page+1)+pdes(i-page+1))),' '),
                 mn_setting.topic_attr,
                 mn_setting.hi_topic_attr)
      else
        If mbuf[i].use then
          ShowC3Str(mn_environment.v_dest^,mnu_x+1,mnu_y+i-page+1,
                    ExpStrR(pstr2(i)+pdes(i),
                    max+(Length(pstr2(i))+Length(pdes(k+page-1))-
                    (C3StrLen(pstr2(i))+CStrLen(pdes(i)))),' '),
                    mn_setting.text_attr,
                    mn_setting.short_attr,
                    mn_setting.topic_attr)
        else
          ShowCStr(mn_environment.v_dest^,mnu_x+1,mnu_y+i-page+1,
                   ExpStrR(pstr(i)+pdes(i),
                   max+(Length(pstr(i))+Length(pdes(k+page-1))-
                   CStrLen(pstr(i)+pdes(i))),' '),
                   mn_setting.disbld_attr,
                   mn_setting.disbld_attr);

  If mn_setting.show_scrollbar then
    vscrollbar_pos :=
      VScrollBar(mn_environment.v_dest^,mnu_x+max+1,mnu_y+1-mn_setting.topic_len,
                 temp2,mnu_count,k+page-1,
                 vscrollbar_pos,mn_setting.menu_attr,mn_setting.menu_attr);
end;

function Menu(var data; x,y: Byte; spos: Word;
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
  _debug_str_ := 'DIALOGIO.PAS:Menu:edit_contents';
  is_setting.append_enabled := TRUE;
  is_setting.character_set  := [#$20..#$7d,#$7f..#$ff];
  is_environment.locate_pos := 1;

  If (mn_environment.edit_pos > 0) and (mn_environment.edit_pos < max-2) then
    temp := Copy(pstr(item),mn_environment.edit_pos+1,
                      Length(pstr(item))-mn_environment.edit_pos+1)
  else
    temp := CutStr(pstr(item));

  mn_environment.is_editing := TRUE;
  While (temp <> '') and (temp[Length(temp)] = ' ') do Delete(temp,Length(temp),1);
  temp := InputStr(temp,x+1+mn_environment.edit_pos,y+k,
               max-2-mn_environment.edit_pos+1,
               max-2-mn_environment.edit_pos+1,
               mn_setting.text2_attr,mn_setting.default_attr);
  mn_environment.is_editing := FALSE;

  HideCursor;
  If (is_environment.keystroke = $1c0d) then
    begin
      If (mn_environment.edit_pos > 0) and (mn_environment.edit_pos < max-2) then
        temp := Copy(pstr(item),1,mn_environment.edit_pos)+temp
      else
        temp := CutStr(temp);
      Move(temp,POINTER(Ptr(0,Ofs(data)+(item-1)*(len+1)))^,len+1);
    end;

  mn_environment.do_refresh := TRUE;
  refresh;
end;

begin { Menu }
  _debug_str_ := 'DIALOGIO.PAS:Menu';
  If count = 0 then begin Menu := 0; EXIT; end;
  max := Length(title);
  mnu_data := Addr(data); mnu_count := count; mnu_len := len;

  If NOT mn_environment.unpolite then
    begin
      Move(mn_environment.v_dest^,backup.screen,SizeOf(backup.screen));
      backup.cursor := GetCursor;
      backup.oldx   := WhereX;
      backup.oldy   := WhereY;
    end;

  If (count < 1) then EXIT;
  vscrollbar_pos := WORD_NULL;

  If NOT mn_environment.preview then HideCursor;
  temp := 0;

  For i := 1 to count do
    begin
      mbuf[i].key := OutKey(pstr(i));
      If NOT mn_setting.reverse_use then mbuf[i].use := mbuf[i].key <> '~'
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
    If max < CStrLen(pstr(i))+mn_environment.descr_len then
      max := CStrLen(pstr(i))+mn_environment.descr_len;

  If mn_setting.center_box then
    begin
      x := (work_MaxCol-max-2) DIV 2+(work_MaxCol-max-2) MOD 2;
      y := (work_MaxLn-len2-1) DIV 2+(work_MaxLn-len2-1) MOD 2;
    end;

  mnu_x := x; mnu_y := y;
  len2b := len2;
  mn_environment.xpos := x;
  mn_environment.ypos := y;
  mn_environment.xsize := max+1;
  mn_environment.ysize := len2+1;
  mn_environment.desc_pos := y+len2+1;

  If NOT mn_environment.unpolite then
    begin
      old_fr_shadow_enabled := fr_setting.shadow_enabled;
      fr_setting.shadow_enabled := mn_setting.shadow_enabled;
      If mn_environment.intact_area then
        fr_setting.update_area := FALSE;
      If mn_setting.frame_enabled then
        Frame(mn_environment.v_dest^,x,y,x+max+1,y+len2+1,mn_setting.menu_attr,
              title,mn_setting.title_attr,mn_setting.frame_type);
      If mn_environment.intact_area then
        fr_setting.update_area := TRUE;
      fr_setting.shadow_enabled := old_fr_shadow_enabled;

      contxt := DietStr(mn_environment.context,max+
        (Length(mn_environment.context)-CStrLen(mn_environment.context)));
      If mn_setting.frame_enabled then
        ShowC3Str(mn_environment.v_dest^,x+1,y+len2+1,
                  '`'+ExpStrL('',max-CStrLen(contxt),
                              mn_setting.frame_type[2])+'`'+
                  contxt,
                  mn_setting.contxt_attr,
                  mn_setting.contxt2_attr,
                  mn_setting.menu_attr);

      temp2 := len2;
      mnu_len2 := len2;

      If len2 > count then len2 := count;
      If len2 < 1 then len2 := 1;
      If spos < 1 then spos := 1;
      If spos > count then spos := count;

      mn_environment.refresh := refresh;

      first := 1; While NOT mbuf[first].use do Inc(first);
      last  := count; While NOT mbuf[last].use do Dec(last);

      If (first <= mn_setting.topic_len) then first := SUCC(mn_setting.topic_len);
      If (spos < first) or (spos > last) then spos := first;
      k := 1; page := 1; opage := WORD_NULL; opos := WORD_NULL;
      While (k+page-1 < spos) do AddPos(k);
    end;

  mnu_topic_len := mn_setting.topic_len;
  If (mnu_topic_len <> 0) then
    begin
      mn_setting.topic_len := 0;
      refresh;

      mn_setting.topic_len := mnu_topic_len;
      mnu_topic_len := 0;
      mnu_data := POINTER(Ofs(data)+SUCC(len)*mn_setting.topic_len);

      Inc(mnu_y,mn_setting.topic_len);
      Dec(len2,mn_setting.topic_len);
      Dec(mnu_len2,mn_setting.topic_len);
      Move(mbuf[SUCC(mn_setting.topic_len)],mbuf[1],
              (count-mn_setting.topic_len)*SizeOf(mbuf[1]));

      For temp := 1 to mn_setting.topic_len do SubPos(k);
      Dec(count,mn_setting.topic_len);
      Dec(mnu_count,mn_setting.topic_len);
      Dec(first,mn_setting.topic_len);
      Dec(last,mn_setting.topic_len);
    end
  else
    refresh;

  mn_environment.curr_page := page;
  mn_environment.curr_pos := k+page-1;
  mn_environment.curr_item := CutStr(pstr(k+page-1));
  mn_environment.keystroke := WORD_NULL;
  If (Addr(mn_environment.ext_proc) <> NIL) then mn_environment.ext_proc;
  
  qflg := FALSE;
  If mn_environment.preview then
    begin
      mn_environment.preview  := FALSE;
      mn_environment.unpolite := TRUE;
    end
  else
    begin
      Repeat
        mn_environment.keystroke := key;
        key := getkey;
        If NOT qflg then
          Case LO(key) of
            $00: If NOT shift_pressed and
                    NOT ctrl_pressed and NOT alt_pressed then
                   Case HI(key) of
                     $48: If (page+k-1 > first) or
                             NOT mn_setting.cycle_moves then SubPos(k)
                          else begin
                                 k := len2; page := count-len2+1;
                                 If NOT mbuf[k+page-1].use then SubPos(k);
                               end;

                     $50: If (page+k-1 < last) or
                             NOT mn_setting.cycle_moves then AddPos(k)
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

            $20..$0ff:
              begin
                RetKey(LO(key),m);
                If m <> 0 then
                  begin
                    refresh;
                    k := m;
                    If NOT ((key = mn_setting.terminate_keys[2]) and
                             mn_setting.edit_contents) then qflg := TRUE
                    else edit_contents(m);
                  end;
              end;
          end;

        If LookUpKey(key,mn_setting.terminate_keys,50) then
          If NOT ((key = mn_setting.terminate_keys[2]) and
                   mn_setting.edit_contents) then qflg := TRUE
          else edit_contents(k+page-1);

        mn_environment.curr_page := page;
        mn_environment.curr_pos := k+page-1;
        mn_environment.curr_item := CutStr(pstr(k+page-1));
        refresh;
        mn_environment.keystroke := key;
        If (Addr(mn_environment.ext_proc) <> NIL) then mn_environment.ext_proc;
        emulate_screen;
        // keyboard_reset_buffer;
      until qflg or _force_program_quit;
    end;

  If mn_environment.winshade and NOT mn_environment.unpolite then
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
        Move(backup.screen,mn_environment.v_dest^,SizeOf(backup.screen));
    end;

  Menu := k+page-1;
end;

const
  MAX_FILES = 4096;
  UPDIR_STR = 'updir';

type
  tSEARCH = Record
              name: String[FILENAME_SIZE];
              attr: Word;
              info: String;
              size: Longint;
            end;
type
  tSTREAM = Record
              stuff: array[1..MAX_FILES] of tSEARCH;
              count: Word;
              drive_count: Word;
              match_count: Word;
            end;
type
  tMNUDAT = array[1..MAX_FILES] of String[1+23+1];

type
  tDSCDAT = array[1..MAX_FILES] of String[20];

var
  menudat: tMNUDAT;
  descr: tDSCDAT;
  masks: array[1..20] of String;
  fstream: tSTREAM;
  drive_list: array[0..128] of Char;

function LookUpMask(filename: String): Boolean;

var
  temp: Byte;
  okay: Boolean;

begin
  okay := FALSE;
  For temp := 1 to count do
    If (Upper(Copy(masks[temp],3,Length(masks[temp]))) = Upper(ExtOnly(filename))) then
      begin
        okay := TRUE;
        BREAK;
      end;
  LookUpMask := okay;
end;

function valid_drive(drive: Char; var info: String): Boolean;

var
  idx: Byte;

begin
  valid_drive := FALSE;
  info := '';
  {$IFDEF WINDOWS}
  idx := 0;
  For idx := 0 to 128 do
    If (drive_list[idx] = drive) then
      begin
        info := 'DRiVE';
        BREAK;
      end;
  {$ENDIF}
  If (info <> '') then valid_drive := TRUE;
end;

procedure make_stream(path,mask: String; var stream: tSTREAM);

var
  search: SearchRec;
  count1,count2: Word;
  drive: Char;

type
  tCOMPARE_STR_RESULT = (isLess,isMore,isEqual);

function CompareStr(str1,str2: String): tCOMPARE_STR_RESULT;

var
  idx,len: Byte;
  result: tCOMPARE_STR_RESULT;

begin
  If (str1 = UPDIR_STR) then result := isLess
  else If (str2 = UPDIR_STR) then result := isMore
       else result := isEqual;

  If (result <> isEqual) then
    begin
      CompareStr := result;
      EXIT;
    end;

  str1 := Upper(FilterStr2(str1,_valid_characters_fname,'_'));
  str2 := Upper(FilterStr2(str2,_valid_characters_fname,'_'));

  If (Length(str1) > Length(str2)) then len := Length(str1)
  else len := Length(str2);

  For idx := 1 to len do
    If (FilterStr2(str1[idx],_valid_characters,#01) > FilterStr2(str2[idx],_valid_characters,#01)) then
      begin
        result := isMore;
        BREAK;
      end
    else If (str1[idx] < str2[idx]) then
           begin
             result := isLess;
             BREAK;
           end;

  If (result = isEqual) then
    If (Length(str1) < Length(str2)) then
      result := isLess
    else If (Length(str1) > Length(str2)) then
           result := isMore;

  CompareStr := result;
end;

procedure QuickSort(l,r: Word);

var
  i,j: Word;
  cmp: String;
  tmp: tSEARCH;

begin
  If (l >= r) then EXIT;
  cmp := stream.stuff[(l+r) DIV 2].name;
  i := l;
  j := r;

  Repeat
    While (i < r) and
          (CompareStr(stream.stuff[i].name,cmp) = isLess) do
      Inc(i);

    While (j > l) and
          (CompareStr(stream.stuff[j].name,cmp) = isMore) do
      Dec(j);

    If (i <= j) then
      begin
        tmp := stream.stuff[i];
        stream.stuff[i] := stream.stuff[j];
        stream.stuff[j] := tmp;
        Inc(i);
        Dec(j);
      end;
  until (i > j);

  If (l < j) then QuickSort(l,j);
  If (i < r) then QuickSort(i,r);
end;

begin
  _debug_str_ := 'DIALOGIO.PAS:make_stream';
  {$IFDEF WINDOWS}
  GetLogicalDriveStrings(SizeOf(drive_list),drive_list);
  {$ENDIF}
  count1 := 0;
  For drive := 'A' to 'Z' do
    If valid_drive(drive,stream.stuff[SUCC(count1)].info) then
      begin
        Inc(count1);
        stream.stuff[count1].name := drive;
        stream.stuff[count1].attr := volumeid;
        stream.stuff[count1].size := 0;
      end;

  Inc(count1);
  stream.stuff[count1].name := '~'+#$ff+'~';
  stream.stuff[count1].attr := volumeid;

  count2 := 0;
  stream.drive_count := count1;
  FindFirst(path+WILDCARD_ASTERISK,anyfile-volumeid,search);
  While (DOSerror = 0) and (count1 < MAX_FILES) do
    begin
      If (search.attr AND directory <> 0) and (search.name = '.') then
        begin
          FindNext(search);
          CONTINUE;
        end
      else If (search.attr AND directory <> 0) and
              NOT ((search.name = '..') and (Length(path) = 3)) then
             begin
               If (search.name <> '..') then search.name := search.name
               else search.name := UPDIR_STR;
               Inc(count1);
               stream.stuff[count1].name := search.name;
               stream.stuff[count1].attr := search.attr;
             end;
      FindNext(search);
    end;

  If (Length(path) > 3) and (count1 = stream.drive_count) then
    begin
      Inc(count1);
      stream.stuff[count1].name := UPDIR_STR;
      stream.stuff[count1].attr := search.attr;
    end;

  FindFirst(path+WILDCARD_ASTERISK,anyfile-volumeid-directory,search);
  While (DOSerror = 0) and (count1+count2 < MAX_FILES) do
    begin
      If LookUpMask(search.name) then
        begin
          search.name := Lower_file(search.name);
          Inc(count2);
          stream.stuff[count1+count2].name := search.name;
          stream.stuff[count1+count2].attr := search.attr;
          stream.stuff[count1+count2].size := search.size;
        end;
      FindNext(search);
    end;

  QuickSort(stream.drive_count+1,count1);
  QuickSort(count1+1,count1+count2);
  stream.count := count1+count2;
  stream.match_count := count2;
end;

var
  path: array[1..26] of String[PATH_SIZE];
  old_fselect_external_proc: Procedure;

procedure new_fselect_external_proc;
begin
  mn_environment.curr_item := fstream.stuff[mn_environment.curr_pos].name;
  If (@old_fselect_external_proc <> NIL) then old_fselect_external_proc;
end;

function Fselect(mask: String): String;

var
  temp1,temp2: Longint;
  temp3,temp4: String;
  temp5: Longint;
  temp6,temp7: String;
  temp8: Longint;
  lastp: Longint;
  idx: Byte;
  backup: tBACKUP;
  _preview_step: Boolean;

function path_filter(path: String): String;
begin
  If (Length(path) > 3) and (path[Length(path)] = PATHSEP) then
    Delete(path,Length(path),1);
  path_filter := Upper(path);
end;

begin
  _debug_str_ := 'DIALOGIO.PAS:Fselect';
  idx := 1;
  count := 0;

  Repeat // split mask string into masks and fill masks[1..20] array
    temp6 := Upper(ReadChunk(mask,idx)); // read first part: *.a2m etc
    Inc(idx ,Length(temp6)+1); // advance
    If NOT (temp6 = '') then
      begin
        Inc(count);
        masks[count] := temp6;
      end;
  until (idx >= Length(mask)) or (temp6 = '');

  {$i-}
  GetDir(0,temp6); // get current dir
  {$i+}

  // if error, take last dir
  If (IOresult <> 0) then
    temp6 := fs_environment.last_dir;

  If (fs_environment.last_dir <> '') then
    begin
      {$i-}
      ChDir(fs_environment.last_dir);
      {$i+}
      If (IOresult <> 0) then
        begin
          {$i-}
          ChDir(temp6);
          {$i+}
          If (IOresult <> 0) then ;
          fs_environment.last_file := 'FNAME:EXT';
        end;
    end;

  {$i-}
  GetDir(0,temp3);
  {$i+}
  If (IOresult <> 0) then temp3 := temp6;
  If (temp3[Length(temp3)] <> PATHSEP) then temp3 := temp3+PATHSEP;
  mn_setting.cycle_moves  := FALSE;
  temp4 := '';

  mn_environment.descr_len := 20;
  mn_environment.descr := Addr(descr);
  mn_environment.winshade := FALSE;

  _preview_step := TRUE;
  Move(screen_ptr^,backup.screen,SizeOf(backup.screen));
  backup.cursor := GetCursor;
  backup.oldx   := WhereX;
  backup.oldy   := WhereY;

  Repeat
    path[SUCC(ORD(UpCase(temp3[1]))-ORD('A'))] := path_filter(temp3);
    make_stream(temp3,mask,fstream);

    For temp2 := 1 to fstream.count do
      If (fstream.stuff[temp2].attr AND directory <> 0) then
        If (fstream.stuff[temp2].name = UPDIR_STR) then
          begin
            menudat[temp2] := ' '+ExpStrR('..',24,' ')+' ';
            descr[temp2] := ExpStrL('[UP-DiR]',mn_environment.descr_len-1,' ');
            fstream.stuff[temp2].name := '..';
          end
        else
          begin
            temp1 := 24+(mn_environment.descr_len-1-10);
            temp7 := iCASE_file(DietStr(FilterStr2(fstream.stuff[temp2].name,_valid_characters_fname,'_'),temp1));
            If (Length(temp7) < 24) then
              begin
                menudat[temp2] := ' '+ExpStrR(temp7,24,' ')+' ';
                descr[temp2] := ExpStrR('',mn_environment.descr_len-1-10,' ');
              end
            else
              begin
                menudat[temp2] := ' '+iCASE_file(ExpStrR(Copy(temp7,1,24),24,' '));
                descr[temp2] := ExpStrR(Copy(temp7,25,Length(temp7)-23),mn_environment.descr_len-1-10,' ');
              end;
            descr[temp2] := descr[temp2]+ExpStrL('[DiR]',10,' ');
          end
      else
        menudat[temp2] := ' '+ExpStrR(DietStr(BaseNameOnly(
                                FilterStr2(fstream.stuff[temp2].name,_valid_characters_fname,'_')),23),23,' ')+' ';

    For temp2 := 1 to fstream.count do
      If (fstream.stuff[temp2].attr = volumeid) then
        begin
          If (fstream.stuff[temp2].name = '~'+#$ff+'~') then descr[temp2] := ''
          else descr[temp2] := '[~'+fstream.stuff[temp2].info+'~]';
        end
      else If NOT (fstream.stuff[temp2].attr AND directory <> 0) then
             begin
               temp7 := Num2str(fstream.stuff[temp2].size,10);
               descr[temp2] := '';
               For temp8 := 1 to Length(temp7) do
                 If (temp8 MOD 3 <> 0) or (temp8 = Length(temp7)) then
                   descr[temp2] := temp7[Length(temp7)-temp8+1]+descr[temp2]
                 else
                   descr[temp2] := ','+temp7[Length(temp7)-temp8+1]+descr[temp2];
               descr[temp2] := ExpStrR(Copy(ExtOnly(
                                 fstream.stuff[temp2].name),1,3),3,' ')+' '+
                                 ExpStrL(DietStr(descr[temp2],mn_environment.descr_len-1-4),
                                         mn_environment.descr_len-1-4,' ');
             end;

    For temp2 := 1 to fstream.count do
      If (SYSTEM.Pos('~',fstream.stuff[temp2].name) <> 0) and
         (fstream.stuff[temp2].name <> '~'+#$ff+'~') then
        While (SYSTEM.Pos('~',menudat[temp2]) <> 0) do
          menudat[temp2][SYSTEM.Pos('~',menudat[temp2])] := PATHSEP;

    temp5 := fstream.drive_count+1;
    While (temp5 <= fstream.count) and (temp4 <> '') and
          (temp4 <> fstream.stuff[temp5].name) do Inc(temp5);
    If (temp5 > fstream.count) then temp5 := 1;

    For temp2 := 1 to fstream.count do
      If (Lower_file(fstream.stuff[temp2].name) = fs_environment.last_file) then
        begin lastp := temp2; BREAK; end;
    If (Lower_file(fstream.stuff[temp2].name) <> fs_environment.last_file) then
      lastp := 0;

    If (lastp = 0) or
       (lastp > MAX_FILES) then lastp := temp5;

    mn_setting.reverse_use := TRUE;
    mn_environment.context := ' ~'+Num2str(fstream.match_count,10)+' FiLES FOUND~ ';
    mn_setting.terminate_keys[3] := $0e08;
    mn_setting.terminate_keys[4] := $2b5c;
    old_fselect_external_proc := mn_environment.ext_proc;
    mn_environment.ext_proc := new_fselect_external_proc;

    mn_setting.frame_enabled := _preview_step;
    mn_setting.shadow_enabled := _preview_step;

    If (program_screen_mode = 0) then
      temp2 := Menu(menudat,01,01,lastp,
                    1+23+1,work_MaxLn-5,fstream.count,' '+
                    iCASE(DietStr(FilterStr2(path_filter(temp3),_valid_characters_fname,'_'),40))+' ')
    else
      temp2 := Menu(menudat,01,01,lastp,
                    1+23+1,work_MaxLn-15,fstream.count,' '+
                    iCASE(DietStr(FilterStr2(path_filter(temp3),_valid_characters_fname,'_'),40))+' ');

    _preview_step := FALSE;
    mn_environment.ext_proc := old_fselect_external_proc;
    mn_setting.reverse_use := FALSE;
    mn_environment.context := '';
    mn_setting.terminate_keys[3] := 0;
    mn_setting.terminate_keys[4] := 0;

    If (mn_environment.keystroke = $1c0d) and
       (fstream.stuff[temp2].attr AND directory <> 0) then
      begin
        fs_environment.last_file := 'FNAME:EXT';
        mn_environment.keystroke := WORD_NULL;
        If (fstream.stuff[temp2].name = '..') then
          begin
            Delete(temp3,Length(temp3),1);
            temp4 := NameOnly(temp3);
            While (temp3[Length(temp3)] <> PATHSEP) do
              Delete(temp3,Length(temp3),1);
            fs_environment.last_file := Lower_file(temp4);
          end
        else
          begin
            temp3 := temp3+fstream.stuff[temp2].name+PATHSEP;
            temp4 := '';
            fs_environment.last_file := temp4;
          end;
        {$i-}
        ChDir(Copy(temp3,1,Length(temp3)-1));
        {$i+}
        If (IOresult <> 0) then ;
      end
    else If (mn_environment.keystroke = $1c0d) and
            (fstream.stuff[temp2].attr AND volumeid <> 0) then
           begin
             fs_environment.last_file := 'FNAME:EXT';
             mn_environment.keystroke := WORD_NULL;
             {$i-}
             ChDir(path[SUCC(ORD(UpCase(fstream.stuff[temp2].name[1]))-ORD('A'))]);
             {$i+}
             If (IOresult <> 0) then temp3 := path[SUCC(ORD(UpCase(fstream.stuff[temp2].name[1]))-ORD('A'))]
             else begin
                    {$i-}
                    GetDir(0,temp3);
                    {$i+}
                    If (IOresult <> 0) then temp3 := temp6;
                  end;
             If (temp3[Length(temp3)] <> PATHSEP) then temp3 := temp3+PATHSEP;
             temp4 := '';
             fs_environment.last_file := temp4;
           end
         else If (mn_environment.keystroke = $0e08) and
                 (SYSTEM.Pos(PATHSEP,Copy(temp3,3,Length(temp3)-3)) <> 0) then
                begin
                  Delete(temp3,Length(temp3),1);
                  temp4 := NameOnly(temp3);
                  While (temp3[Length(temp3)] <> PATHSEP) do
                    Delete(temp3,Length(temp3),1);
                  fs_environment.last_file := Lower_file(temp4);
                  {$i-}
                  ChDir(Copy(temp3,1,Length(temp3)-1));
                  {$i+}
                  If (IOresult <> 0) then ;
                end
              else If (mn_environment.keystroke = $2b5c) then
                     begin
                       temp3 := Copy(temp3,1,3);
                       temp4 := '';
                       fs_environment.last_file := temp4;
                       {$i-}
                       ChDir(Copy(temp3,1,Length(temp3)-1));
                       {$i+}
                       If (IOresult <> 0) then ;
                     end
                   else fs_environment.last_file := Lower_file(fstream.stuff[temp2].name);
  until (mn_environment.keystroke = $1c0d) or
        (mn_environment.keystroke = $011b);

  mn_environment.descr_len := 0;
  mn_environment.descr := NIL;
  mn_environment.winshade := TRUE;
  mn_setting.frame_enabled := TRUE;
  mn_setting.shadow_enabled := TRUE;

  move_to_screen_data := Addr(backup.screen);
  move_to_screen_area[1] := mn_environment.xpos;
  move_to_screen_area[2] := mn_environment.ypos;
  move_to_screen_area[3] := mn_environment.xpos+mn_environment.xsize+2+1;
  move_to_screen_area[4] := mn_environment.ypos+mn_environment.ysize+1;
  move2screen;

  Fselect := temp3+fstream.stuff[temp2].name;
  fs_environment.last_dir := path[SUCC(ORD(UpCase(temp3[1]))-ORD('A'))];
  {$i-}
  ChDir(temp6);
  {$i+}
  If (IOresult <> 0) then ;
  If (mn_environment.keystroke = $011b) then Fselect := '';
end;

function _partial(max,val: Word; base: Byte): Word;

var
  temp1,temp2: Real;
  temp3: Word;

begin
  temp1 := max/base;
  temp2 := (max/base)/2;
  temp3 := 0;
  While (temp2 < val) do
    begin
      temp2 := temp2+temp1;
      Inc(temp3);
    end;
  _partial := temp3;
end;

function HScrollBar(var dest; x,y: Byte; size: Byte; len1,len2,pos: Word;
                   atr1,atr2: Byte): Word;
var
  temp: Word;

begin
  _debug_str_ := 'DIALOGIO.PAS:HScrollBar';
  If (size > work_MaxCol-x) then size := work_MaxCol-x;
  If (size < 5) then size := 5;

  If (size-2-1 < 10) then temp := _partial(len1,len2,size-2-1)
  else temp := _partial(len1,len2,size-2-1-2);

  If (pos = temp) then
    begin
      HScrollBar := temp;
      EXIT;
    end;

  If (size < len1) then
    begin
      pos := temp;
      ShowStr(dest,x,y,''+ExpStrL('',size-2,'°')+'',atr1);
      If (size-2-1 < 10) then ShowStr(dest,x+1+temp,y,'²',atr2)
      else ShowStr(dest,x+1+temp,y,'²²²',atr2);
    end
  else ShowCStr(dest,x,y,'~~'+ExpStrL('',size-2,'±')+'~~',atr2,atr1);
  HScrollBar := pos;
end;

function VScrollBar(var dest; x,y: Byte; size: Byte; len1,len2,pos: Word;
                   atr1,atr2: Byte): Word;
var
  temp: Word;

begin
  _debug_str_ := 'DIALOGIO.PAS:VScrollBar';
  If (size > work_MaxLn-y) then size := work_MaxLn-y;
  If (size < 5) then size := 5;

  If (size-2-1 < 10) then temp := _partial(len1,len2,size-2-1)
  else temp := _partial(len1,len2,size-2-1-2);

  If (pos = temp) then
    begin
      VScrollBar := temp;
      EXIT;
    end;

  If (size < len1) then
    begin
      pos := temp;
      ShowVStr(dest,x,y,''+ExpStrL('',size-2,'°')+'',atr1);
      If (size-2-1 < 10) then ShowStr(dest,x,y+1+temp,'²',atr2)
      else ShowVStr(dest,x,y+1+temp,'²²²',atr2);
    end
  else ShowVCStr(dest,x,y,'~~'+ExpStrL('',size-2,'±')+'~~',atr2,atr1);
  VScrollBar := pos;
end;

procedure DialogIO_Init;

var
  index: Byte;

begin
  dl_setting.frame_type      := double;
  dl_setting.title_attr      := dialog_background+dialog_title;
  dl_setting.box_attr        := dialog_background+dialog_border;
  dl_setting.text_attr       := dialog_background+dialog_text;
  dl_setting.text2_attr      := dialog_background+dialog_hi_text;
  dl_setting.keys_attr       := dialog_background+dialog_button;
  dl_setting.keys2_attr      := dialog_sel_btn_bck+dialog_sel_btn;
  dl_setting.short_attr      := dialog_background+dialog_short;
  dl_setting.short2_attr     := dialog_sel_btn_bck+dialog_sel_short;
  dl_setting.disbld_attr     := dialog_background+dialog_button_dis;
  dl_setting.contxt_attr     := dialog_background+dialog_context;
  dl_setting.contxt2_attr    := dialog_background+dialog_context_dis;

  mn_setting.frame_type      := double;
  mn_setting.title_attr      := menu_background+menu_title;
  mn_setting.menu_attr       := menu_background+menu_border;
  mn_setting.text_attr       := menu_background+menu_item;
  mn_setting.text2_attr      := menu_sel_item_bckg+menu_sel_item;
  mn_setting.default_attr    := menu_default_bckg+menu_default;
  mn_setting.short_attr      := menu_background+menu_short;
  mn_setting.short2_attr     := menu_sel_item_bckg+menu_sel_short;
  mn_setting.disbld_attr     := menu_background+menu_item_dis;
  mn_setting.contxt_attr     := menu_background+menu_context;
  mn_setting.contxt2_attr    := menu_background+menu_context_dis;
  mn_setting.topic_attr      := menu_background+menu_topic;
  mn_setting.hi_topic_attr   := menu_background+menu_hi_topic;
  mn_setting.topic_mask_chr  := [];

  mn_environment.v_dest      := screen_ptr;
  dl_environment.keystroke   := $0000;
  mn_environment.keystroke   := $0000;
  dl_environment.context     := '';
  mn_environment.context     := '';
  mn_environment.unpolite    := FALSE;
  dl_environment.input_str   := '';
  mn_environment.winshade    := TRUE;
  mn_environment.intact_area := FALSE;
  mn_environment.ext_proc    := NIL;
  mn_environment.ext_proc_rt := NIL;
  mn_environment.refresh     := NIL;
  mn_environment.do_refresh  := FALSE;
  mn_environment.preview     := FALSE;
  mn_environment.fixed_start := 0;
  mn_environment.descr_len   := 0;
  mn_environment.descr       := NIL;
  mn_environment.is_editing  := FALSE;
  fs_environment.last_file   := 'FNAME:EXT';
  fs_environment.last_dir    := '';
  mn_environment.xpos        := 0;
  mn_environment.xpos        := 0;
  mn_environment.xsize       := 0;
  mn_environment.ysize       := 0;
  mn_environment.desc_pos    := 0;

  For index := 1 to 26 do
    path[index] := CHR(ORD('a')+PRED(index))+':'+PATHSEP;
end;

end.
