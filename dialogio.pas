unit DialogIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

uses
  DOS,
{$IFDEF GO32V2}
  GO32,
{$ENDIF}
{$IFDEF WINDOWS}
  WINDOWS,
{$ENDIF}
  AdT2unit,AdT2sys,AdT2keyb,AdT2text,
  TxtScrIO,StringIO,ParserIO;

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
                    homing_pos:     Longint;
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
                        v_dest:      tSCREEN_MEM_PTR;
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
                        own_refresh: Boolean;
                        preview:     Boolean;
                        fixed_start: Byte;
                        descr_len:   Byte;
                        descr:       Pointer;
                        is_editing:  Boolean;
                        xpos,ypos:   Byte;
                        xsize,ysize: Byte;
                        desc_pos:    Byte;
                        hlight_chrs: Byte;
                      end;

const
{$IFDEF GO32V2}
  FILENAME_SIZE = 12;
  DIR_SIZE = 80;
  PATH_SIZE = 80;
{$ELSE}
  FILENAME_SIZE = 255;
  DIR_SIZE = 170;
  PATH_SIZE = 255;
{$ENDIF}

type
  tFSELECT_ENVIRONMENT = Record
                           last_file: String[FILENAME_SIZE];
                           last_dir:  String[DIR_SIZE];
                         end;
const
  dl_setting: tDIALOG_SETTING =
    (frame_type:     frame_single;
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
    (frame_type:     frame_single;
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
     homing_pos:     0;
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
  dl_environment: tDIALOG_ENVIRONMENT;
  mn_environment: tMENU_ENVIRONMENT;
  fs_environment: tFSELECT_ENVIRONMENT;

function Dialog(text,keys,title: String; spos: Byte): Byte;
function Menu(var data; x,y: Byte; spos: Word;
              len,len2: Byte; count: Word; title: String): Word;
function Fselect(mask: String): String;
function HScrollBar(dest: tSCREEN_MEM_PTR; x,y: Byte; size: Byte; len1,len2,pos: Word;
                    atr1,atr2: Byte): Word;
function VScrollBar(dest: tSCREEN_MEM_PTR; x,y: Byte; size: Byte; len1,len2,pos: Word;
                    atr1,atr2: Byte): Word;
procedure DialogIO_Init;

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
var
  idx,idx2,idx3,pos,max,mx2,num,nm2,
  xstart,ystart,count,
  ln,ln1,len2b,atr1,atr2,
  page,first,last,temp,temp2,opage,opos: Word;
  old_fr_shadow_enabled: Boolean;
  key:    Word;
  str:    String;
  solid:  Boolean;
  qflg:   Boolean;
  dbuf:   tDBUFFR;
  mbuf:   tMBUFFR;
  contxt: String;

function OutKey(str: String): Char;

var
  result: Char;

begin
  If (SYSTEM.Pos('~',str) = 0) then result := '~'
  else If (str[SYSTEM.Pos('~',str)+2] <> '~') then result := '~'
       else result := str[SYSTEM.Pos('~',str)+1];
  OutKey := result;
end;

function ReadChunk(str: String; pos: Byte): String;

var
  result: String;

begin
  Delete(str,1,pos-1);
  If (SYSTEM.Pos('$',str) = 0) then result := ''
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
  else If (temp > 1) then begin Dec(temp); SubPos(temp); end;
  If dbuf[temp].use then p := temp;
end;

procedure AddPos(var p: Word);

var
  temp: Word;

begin
  temp := p;
  If (temp < nm2) and dbuf[temp+1].use then Inc(temp)
  else If (temp < nm2) then begin Inc(temp); AddPos(temp); end;
  If dbuf[temp].use then p := temp;
end;

procedure ShowItem;
begin
  If (idx2 = 0) then EXIT;
  If (idx2 <> idx3) then
    ShowCStr(screen_ptr,dbuf[idx3].pos,ystart+num+1,dbuf[idx3].str,
             dl_setting.keys_attr,dl_setting.short_attr);

    ShowCStr(screen_ptr,dbuf[idx2].pos,ystart+num+1,dbuf[idx2].str,
             dl_setting.keys2_attr,dl_setting.short2_attr);
  idx3 := idx2;
end;

function RetKey(code: Byte): Word;

var
  temp: Byte;

begin
  RetKey := 0;
  For temp := 1 to nm2 do
    If (UpCase(dbuf[temp].key) = UpCase(CHR(code))) then
      begin
        RetKey := temp;
        BREAK;
      end;
end;

function CurrentKey(pos: Byte): Byte;

var
  idx,temp: Byte;

begin
  temp := 0;
  For idx := 1 to nm2 do
    If (pos in [dbuf[idx].pos,dbuf[idx].pos+CStrLen(dbuf[idx].str)-1]) then
      temp := idx;
  CurrentKey := temp;
end;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:Dialog';
{$ENDIF}
  pos := 1;
  max := Length(title);
  num := 0;

  ScreenMemCopy(screen_ptr,ptr_scr_backup);
  HideCursor;

  Repeat
    str := ReadChunk(text,pos);
    Inc(pos,Length(str)+1);
    If (CStrLen(str) > max) then max := CStrLen(str);
    If (str <> '') then Inc(num);
  until (pos >= Length(text)) or (str = '');

  pos := 1;
  mx2 := 0;
  nm2 := 0;

  If (Copy(keys,1,14) = '%string_input%') then
    begin
      Inc(pos,14);
      str := ReadChunk(keys,pos); ln := Str2num(str,10);
      If (str = '') then EXIT;
      Inc(pos,Length(str)+1);

      str := ReadChunk(keys,pos); ln1 := Str2num(str,10); mx2 := ln1;
      If (str = '') then EXIT;
      Inc(pos,Length(str)+1);

      str := ReadChunk(keys,pos); atr1 := Str2num(str,16);
      If (str = '') then EXIT;
      Inc(pos,Length(str)+1);

      str := ReadChunk(keys,pos); atr2 := Str2num(str,16);
      If (str = '') then EXIT;
      Inc(pos,Length(str)+1);
    end
  else
    begin
      Repeat
        str := ReadChunk(keys,pos);
        Inc(pos,Length(str)+1);
        If (str <> '') then
          begin
            Inc(nm2);
            dbuf[nm2].str := ' '+str+' ';
            dbuf[nm2].key := OutKey(str);
            If NOT dl_setting.all_enabled then dbuf[nm2].use := dbuf[nm2].key <> '~'
            else dbuf[nm2].use := TRUE;
            If (nm2 > 1) then
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

  If (max < mx2) then max := mx2
  else
    begin
      ln1 := max;
      If (ln < max) then ln := max;
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
  Frame(screen_ptr,xstart,ystart,xstart+max+3,ystart+num+2,
        dl_setting.box_attr,title,dl_setting.title_attr,
        dl_setting.frame_type);
  fr_setting.shadow_enabled := old_fr_shadow_enabled;

  pos := 1;
  contxt := DietStr(dl_environment.context,max+
    (Length(dl_environment.context)-CStrLen(dl_environment.context)));
  ShowCStr(screen_ptr,xstart+max+3-CStrLen(contxt),ystart+num+2,
           contxt,dl_setting.contxt_attr,dl_setting.contxt2_attr);

  For idx := 1 to num do
    begin
      str := ReadChunk(text,pos);
      Inc(pos,Length(str)+1);
      If dl_setting.center_text then
        ShowCStr(screen_ptr,xstart+2,ystart+idx,
                 ExpStrL(str,Length(str)+(max-CStrLen(str)) DIV 2,' '),
                 dl_setting.text_attr,dl_setting.text2_attr)
      else
        ShowCStr(screen_ptr,xstart+2,ystart+idx,
                 str,dl_setting.text_attr,dl_setting.text2_attr);
    end;

  If (Copy(keys,1,14) = '%string_input%') then
    begin
      ThinCursor;
      str := InputStr(dl_environment.input_str,
                      xstart+2,ystart+num+1,ln,ln1,atr1,atr2);
      If is_environment.keystroke = kENTER then dl_environment.input_str := str;
      dl_environment.keystroke := is_environment.keystroke;
      HideCursor;
    end
  else
    begin
      For idx := 1 to nm2 do
        begin
          Inc(dbuf[idx].pos,xstart+(max-mx2) DIV 2+1);
          If dbuf[idx].use then
            ShowCStr(screen_ptr,dbuf[idx].pos,ystart+num+1,
                     dbuf[idx].str,dl_setting.keys_attr,dl_setting.short_attr)
          else
            ShowCStr(screen_ptr,dbuf[idx].pos,ystart+num+1,
                     dbuf[idx].str,dl_setting.disbld_attr,dl_setting.disbld_attr);
        end;

      If (spos < 1) then spos := 1;
      If (spos > nm2) then spos := nm2;

      idx2 := spos;
      idx3 := 1;

      If NOT dbuf[idx2].use then
        begin
          SubPos(idx2);
          If NOT dbuf[idx2].use then AddPos(idx2);
        end;

      ShowItem;
      ShowItem;
      qflg := FALSE;
      If (keys = '$') then EXIT;

      Repeat
        key := getkey;
        If LookUpKey(key,dl_setting.terminate_keys,50) then qflg := TRUE;

        If NOT qflg then
          If (LO(key) in [$20..$0ff]) then
            begin
              idx := RetKey(LO(key));
              If (idx <> 0) then
                begin
                  qflg := TRUE;
                  idx2 := idx;
                end;
            end
          else If NOT shift_pressed and
                  NOT ctrl_pressed and NOT alt_pressed then
                 Case key of
                   kLEFT: If (idx2 > 1) or
                             NOT dl_setting.cycle_moves then SubPos(idx2)
                          else begin
                                 idx2 := nm2;
                                 If NOT dbuf[idx2].use then SubPos(idx2);
                               end;

                   kRIGHT: If (idx2 < nm2) or
                              NOT dl_setting.cycle_moves then
                             begin
                               temp := idx2;
                               AddPos(idx2);
                               If (idx2 = temp) then
                                 begin
                                   idx2 := 1;
                                   If NOT dbuf[idx2].use then AddPos(idx2);
                                 end;
                             end
                           else begin
                                  idx2 := 1;
                                  If NOT dbuf[idx2].use then AddPos(idx2);
                                end;

                   kHOME: begin
                            idx2 := 1;
                            If NOT dbuf[idx2].use then AddPos(idx2);
                          end;

                   kEND: begin
                           idx2 := nm2;
                           If NOT dbuf[idx2].use then SubPos(idx2);
                         end;
                 end;

        ShowItem;
{$IFNDEF GO32V2}
        draw_screen;
{$ENDIF}
      until qflg or _force_program_quit;

      Dialog := idx2;
      dl_environment.keystroke := key;
    end;

  If move_to_screen_routine <> NIL then
    begin
      move_to_screen_data := ptr_scr_backup;
      move_to_screen_area[1] := xstart;
      move_to_screen_area[2] := ystart;
      move_to_screen_area[3] := xstart+max+3+2;
      move_to_screen_area[4] := ystart+num+2+1;
      move_to_screen_routine;
    end
  else
    ScreenMemCopy(ptr_scr_backup,screen_ptr);
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:pstr';
{$ENDIF}
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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:pdes';
{$ENDIF}
  If (mn_environment.descr <> NIL) and (item <= mnu_count) then
    Move(POINTER(Ptr(0,Ofs(mn_environment.descr^)+
      (item-1)*(mn_environment.descr_len+1)))^,temp,mn_environment.descr_len+1)
  else temp := '';
  pdes := ExpStrR(temp,mn_environment.descr_len,' ');
end;

procedure refresh;

procedure ShowCStr_clone(dest: tSCREEN_MEM_PTR; x,y: Byte; str: String;
                         atr1,atr2,atr3,atr4: Byte);
var
  temp,
  len,len2: Byte;
  highlighted: Boolean;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:refresh:ShowCStr_clone';
{$ENDIF}
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

var
  item_str,item_str_alt,
  item_str2,item_str2_alt: String;
  desc_str,desc_str2,desc_str3: String;

begin { refresh }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:refresh';
{$ENDIF}
  If (page = opage) and (idx2 = opos) and NOT mn_environment.do_refresh then EXIT
  else begin
         opage := page;
         opos  := idx2;
         mn_environment.do_refresh := FALSE;
       end;

  If NOT mn_environment.own_refresh then
    For idx := page to mnu_len2+page-1 do
      begin
        item_str := pstr(idx-page+1);
        item_str_alt := pstr(idx);
        item_str2 := pstr2(idx2+page-1);
        item_str2_alt := pstr2(idx);
        desc_str := pdes(idx-page+1);
        desc_str2 := pdes(idx);
        desc_str3 := pdes(idx2+page-1);

        If (mn_environment.hlight_chrs <> 0) and (item_str <> '') then
          item_str := '~'+Copy(item_str,1,mn_environment.hlight_chrs)+
                      '~'+Copy(item_str,mn_environment.hlight_chrs+1,Length(item_str)-mn_environment.hlight_chrs);
        If (mn_environment.hlight_chrs <> 0) and (item_str_alt <> '') then
          item_str_alt := '~'+Copy(item_str_alt,1,mn_environment.hlight_chrs)+
                          '~'+Copy(item_str_alt,mn_environment.hlight_chrs+1,Length(item_str_alt)-mn_environment.hlight_chrs);
        If (mn_environment.hlight_chrs <> 0) and (item_str2 <> '') then
          item_str2 := '~'+Copy(item_str2,1,mn_environment.hlight_chrs)+
                       '~'+Copy(item_str2,mn_environment.hlight_chrs+1,Length(item_str2)-mn_environment.hlight_chrs);
        If (mn_environment.hlight_chrs <> 0) and (item_str2_alt <> '') then
          item_str2_alt := '~'+Copy(item_str2_alt,1,mn_environment.hlight_chrs)+
                           '~'+Copy(item_str2_alt,mn_environment.hlight_chrs+1,Length(item_str2_alt)-mn_environment.hlight_chrs);

        If (idx = idx2+page-1) then
          ShowCStr_clone(mn_environment.v_dest,mnu_x+1,mnu_y+idx2,
                         ExpStrR(item_str2+desc_str3,
                         max+(Length(item_str2)+Length(desc_str3)-
                         (C3StrLen(item_str2)+CStrLen(desc_str3))),' '),
                         mn_setting.text2_attr,
                         mn_setting.short2_attr,
                         mn_setting.text_attr,
                         mn_setting.short_attr)
        else
          If (idx-page+1 <= mnu_topic_len) then
            ShowCStr(mn_environment.v_dest,mnu_x+1,mnu_y+idx-page+1,
                     ExpStrR(item_str+desc_str,
                     max+(Length(item_str)+Length(desc_str3)-
                     CStrLen(item_str+desc_str)),' '),
                     mn_setting.topic_attr,
                     mn_setting.hi_topic_attr)
          else
            If mbuf[idx].use then
              ShowC3Str(mn_environment.v_dest,mnu_x+1,mnu_y+idx-page+1,
                        ExpStrR(item_str2_alt+desc_str2,
                        max+(Length(item_str2_alt)+Length(desc_str3)-
                        (C3StrLen(item_str2_alt)+CStrLen(desc_str2))),' '),
                        mn_setting.text_attr,
                        mn_setting.short_attr,
                        mn_setting.topic_attr)
            else
              ShowCStr(mn_environment.v_dest,mnu_x+1,mnu_y+idx-page+1,
                       ExpStrR(item_str_alt+desc_str2,
                       max+(Length(item_str_alt)+Length(desc_str3)-
                       CStrLen(item_str_alt+desc_str2)),' '),
                       mn_setting.disbld_attr,
                       mn_setting.disbld_attr);
      end;

  If mn_setting.show_scrollbar then
    vscrollbar_pos :=
      VScrollBar(mn_environment.v_dest,mnu_x+max+1,mnu_y+1-mn_setting.topic_len,
                 temp2,mnu_count,idx2+page-1,
                 vscrollbar_pos,mn_setting.menu_attr,mn_setting.menu_attr);
end;

function Menu(var data; x,y: Byte; spos: Word;
              len,len2: Byte; count: Word; title: String): Word;

procedure SubPos(var p: Word);

var
  temp: Word;

begin
  temp := p;
  If (temp > 1) and mbuf[temp+page-2].use then
    Dec(temp)
  else If (temp > 1) then
         begin
           Dec(temp);
           SubPos(temp);
         end
       else If (page > first) then
              Dec(page);
  If mbuf[temp+page-1].use then p := temp
  else If (temp+page-1 > first) then SubPos(temp);
end;

procedure AddPos(var p: Word);

var
  temp: Word;

begin
  temp := p;
  If (temp < len2) and (temp < last) and
     mbuf[temp+page].use then
    Inc(temp)
  else If (temp < len2) and (temp < last) then
         begin
           Inc(temp);
           AddPos(temp);
         end
       else If (page+temp <= last) then
              Inc(page);
  If mbuf[temp+page-1].use then p := temp
  else If (temp+page-1 < last) then AddPos(temp);
end;

function RetKey(code: Byte): Word;

var
  temp: Byte;

begin
  RetKey := 0;
  For temp := 1 to count do
    If (UpCase(mbuf[temp].key) = UpCase(CHR(code))) then
      begin
        RetKey := temp;
        BREAK;
      end;
end;

procedure edit_contents(item: Word);

var
  item_str,temp: String;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:Menu:edit_contents';
{$ENDIF}
  is_setting.append_enabled := TRUE;
  is_setting.character_set  := [' '..'_','a'..'}',#128..#255]; // exclude ` and ~ characters
  is_environment.locate_pos := 1;

  item_str := pstr(item);
  If (mn_environment.edit_pos > 0) and (mn_environment.edit_pos < max-2) then
    temp := Copy(item_str,mn_environment.edit_pos+1,
                 Length(item_str)-mn_environment.edit_pos+1)
  else
    temp := CutStr(item_str);

  mn_environment.is_editing := TRUE;
  While (temp <> '') and (temp[Length(temp)] = ' ') do Delete(temp,Length(temp),1);
  temp := InputStr(temp,x+1+mn_environment.edit_pos,y+idx2,
               max-2-mn_environment.edit_pos+1,
               max-2-mn_environment.edit_pos+1,
               mn_setting.text2_attr,mn_setting.default_attr);
  mn_environment.is_editing := FALSE;

  HideCursor;
  If (is_environment.keystroke = kENTER) then
    begin
      If (mn_environment.edit_pos > 0) and (mn_environment.edit_pos < max-2) then
        temp := Copy(item_str,1,mn_environment.edit_pos)+temp
      else
        temp := CutStr(temp);
      Move(temp,POINTER(Ptr(0,Ofs(data)+(item-1)*(len+1)))^,len+1);
    end;

  mn_environment.do_refresh := TRUE;
  refresh;
end;

begin { Menu }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:Menu';
{$ENDIF}
  If (count = 0) then
    begin
      Menu := 0;
      EXIT;
    end;

  max := Length(title);
  mnu_data := Addr(data);
  mnu_count := count;
  mnu_len := len;

  If NOT mn_environment.unpolite then
    ScreenMemCopy(mn_environment.v_dest,ptr_scr_backup2);

  If (count < 1) then EXIT;
  vscrollbar_pos := WORD_NULL;

  If NOT mn_environment.preview then HideCursor;
  temp := 0;

  For idx := 1 to count do
    begin
      mbuf[idx].key := OutKey(pstr(idx));
      If NOT mn_setting.reverse_use then mbuf[idx].use := mbuf[idx].key <> '~'
      else mbuf[idx].use := NOT (mbuf[idx].key <> '~');
      If mbuf[idx].use then temp := 1;
    end;

  solid := FALSE;
  If (temp = 0) then
    begin
      For temp := 1 to count do mbuf[temp].use := TRUE;
      solid := TRUE;
    end;

  For idx := 1 to count do
    If (max < CStrLen(pstr(idx))+mn_environment.descr_len) then
      max := CStrLen(pstr(idx))+mn_environment.descr_len;

  If mn_setting.center_box then
    begin
      x := (work_MaxCol-max-2) DIV 2+(work_MaxCol-max-2) MOD 2;
      y := (work_MaxLn-len2-1) DIV 2+(work_MaxLn-len2-1) MOD 2;
    end;

  mnu_x := x;
  mnu_y := y;
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
        Frame(mn_environment.v_dest,x,y,x+max+1,y+len2+1,mn_setting.menu_attr,
              title,mn_setting.title_attr,mn_setting.frame_type);
      If mn_environment.intact_area then
        fr_setting.update_area := TRUE;
      fr_setting.shadow_enabled := old_fr_shadow_enabled;

      contxt := DietStr(mn_environment.context,max+
        (Length(mn_environment.context)-CStrLen(mn_environment.context)));
      If mn_setting.frame_enabled then
        ShowC3Str(mn_environment.v_dest,x+1,y+len2+1,
                  '`'+ExpStrL('',max-CStrLen(contxt),
                              mn_setting.frame_type[2])+'`'+
                  contxt,
                  mn_setting.contxt_attr,
                  mn_setting.contxt2_attr,
                  mn_setting.menu_attr);

      temp2 := len2;
      mnu_len2 := len2;

      If (len2 > count) then len2 := count;
      If (len2 < 1) then len2 := 1;
      If (spos < 1) then spos := 1;
      If (spos > count) then spos := count;

      mn_environment.refresh := @refresh;

      first := 1;
      last := count;
      While NOT mbuf[first].use do Inc(first);
      While NOT mbuf[last].use do Dec(last);

      If (first <= mn_setting.topic_len) then
        first := SUCC(mn_setting.topic_len);
      If (spos < first) or (spos > last) then
        spos := first;
      idx2 := 1;
      page := 1;
      opage := WORD_NULL;
      opos := WORD_NULL;
      While (idx2+page-1 < spos) do AddPos(idx2);
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

      For temp := 1 to mn_setting.topic_len do SubPos(idx2);
      Dec(count,mn_setting.topic_len);
      Dec(mnu_count,mn_setting.topic_len);
      Dec(first,mn_setting.topic_len);
      Dec(last,mn_setting.topic_len);
      refresh;
    end
  else
    refresh;

  mn_environment.curr_page := page;
  mn_environment.curr_pos := idx2+page-1;
  mn_environment.curr_item := CutStr(pstr(idx2+page-1));
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
          If (LO(key) in [$20..$0ff]) then
            begin
              idx := RetKey(LO(key));
              If (idx <> 0) then
                begin
                  refresh;
                  idx2 := idx;
                  If NOT ((key = mn_setting.terminate_keys[2]) and
                           mn_setting.edit_contents) then qflg := TRUE
                  else edit_contents(idx);
                end;
            end
          else If NOT shift_pressed and
                  NOT ctrl_pressed and NOT alt_pressed then
                 Case key of
                   kUP: If (page+idx2-1 > first) or
                          NOT mn_setting.cycle_moves then SubPos(idx2)
                        else begin
                               idx2 := len2;
                               page := count-len2+1;
                               If NOT mbuf[idx2+page-1].use then SubPos(idx2);
                             end;
                   kDOWN: If (page+idx2-1 < last) or
                            NOT mn_setting.cycle_moves then AddPos(idx2)
                          else begin
                                 idx2 := 1;
                                 page := 1;
                                 If NOT mbuf[idx2+page-1].use then AddPos(idx2);
                               end;
                   kHOME: begin
                            If (mn_setting.homing_pos = 0) then begin idx2 := 1; page := 1; end
                            else If (idx2+page-1 > mn_setting.homing_pos) and
                                    (mn_setting.homing_pos < count) then
                                   Repeat SubPos(idx2) until (idx2+page-1 <= mn_setting.homing_pos)
                                 else begin
                                        idx2 := 1;
                                        page := 1;
                                      end;
                            If NOT mbuf[idx2+page-1].use then AddPos(idx2);
                          end;

                   kEND: begin
                           If (mn_setting.homing_pos = 0) then begin idx2 := len2; page := count-len2+1; end
                           else If (idx2+page-1 < mn_setting.homing_pos) and
                                   (mn_setting.homing_pos < count) then
                                  Repeat
                                    AddPos(idx2);
                                  until (idx2+page-1 >= mn_setting.homing_pos)
                                else begin
                                       idx2 := len2;
                                       page := count-len2+1;
                                     end;
                           If NOT mbuf[idx2+page-1].use then SubPos(idx2);
                         end;

                   kPgUP: If (idx2+page-1-(len2-1) > mn_setting.homing_pos) or
                             (idx2+page-1 <= mn_setting.homing_pos) or
                             (mn_setting.homing_pos = 0) or
                             NOT (mn_setting.homing_pos < count) then
                            For temp := 1 to len2-1 do SubPos(idx2)
                          else Repeat
                                 SubPos(idx2);
                               until (idx2+page-1 <= mn_setting.homing_pos);

                   kPgDOWN: If (idx2+page-1+(len2-1) < mn_setting.homing_pos) or
                               (idx2+page-1 >= mn_setting.homing_pos) or
                               (mn_setting.homing_pos = 0) or
                               NOT (mn_setting.homing_pos < count) then
                              For temp := 1 to len2-1 do AddPos(idx2)
                            else Repeat
                                   AddPos(idx2);
                                 until (idx2+page-1 >= mn_setting.homing_pos);
                 end;

        If LookUpKey(key,mn_setting.terminate_keys,50) then
          If NOT ((key = mn_setting.terminate_keys[2]) and
                   mn_setting.edit_contents) then qflg := TRUE
          else edit_contents(idx2+page-1);

        mn_environment.curr_page := page;
        mn_environment.curr_pos := idx2+page-1;
        mn_environment.curr_item := CutStr(pstr(idx2+page-1));
        refresh;
        mn_environment.keystroke := key;
        If (Addr(mn_environment.ext_proc) <> NIL) then mn_environment.ext_proc;
{$IFNDEF GO32V2}
        draw_screen;
{$ENDIF}
      until qflg or _force_program_quit;
    end;

  If mn_environment.winshade and NOT mn_environment.unpolite then
    begin
      If (move_to_screen_routine <> NIL) then
        begin
          move_to_screen_data := ptr_scr_backup2;
          move_to_screen_area[1] := x;
          move_to_screen_area[2] := y;
          move_to_screen_area[3] := x+max+1+2;
          move_to_screen_area[4] := y+len2b+1+1;
          move_to_screen_routine;
         end
      else
        ScreenMemCopy(ptr_scr_backup2,mn_environment.v_dest);
    end;

  Menu := idx2+page-1;
end;

const
  MAX_FILES = 4096;
  UPDIR_STR = #19'updir';
{$IFDEF UNIX}
  DRIVE_DIVIDER = 0;
{$ELSE}
  DRIVE_DIVIDER = 1;
{$ENDIF}

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
{$IFDEF GO32V2}
  tMNUDAT = array[1..MAX_FILES] of String[1+12+1];
{$ELSE}
  tMNUDAT = array[1..MAX_FILES] of String[1+23+1];
{$ENDIF}

type
  tDSCDAT = array[1..MAX_FILES] of String[20];

var
  menudat: tMNUDAT;
  descr: tDSCDAT;
  masks: array[1..20] of String;
  fstream: tSTREAM;
{$IFNDEF GO32V2}
  drive_list: array[0..128] of Char;
{$ENDIF}

function LookUpMask(filename: String): Boolean;

var
  temp: Byte;
  okay: Boolean;

begin
  okay := FALSE;
  For temp := 1 to count do
{$IFDEF GO32V2}
    If SameName(Upper(masks[temp]),Upper(filename)) then
{$ELSE}
    If (Upper(Copy(masks[temp],3,Length(masks[temp]))) = Upper(ExtOnly(filename))) then
{$ENDIF}
      begin
        okay := TRUE;
        BREAK;
      end;
  LookUpMask := okay;
end;

{$IFDEF GO32V2}

function valid_drive(drive: Char): Boolean;

function phantom_drive(drive: Char): Boolean;

var
  regs: tRealRegs;

begin
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:phantom_drive';

  regs.ax := $440e;
  regs.bl := BYTE(UpCase(drive))-$40;
  RealIntr($21,regs);

  If Odd(regs.flags) then phantom_drive := FALSE
  else If (regs.al = 0) then phantom_drive := FALSE
       else phantom_drive := (regs.al <> BYTE(UpCase(drive))-$40);
end;

var
  regs: tRealRegs;
  dos_sel,dos_seg: Word;
  dos_mem_adr: Dword;
  dos_data: array[0..PRED(40)] of Byte;

begin
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:valid_drive';

  dos_mem_adr := global_dos_alloc(40);
  dos_sel := WORD(dos_mem_adr);
  dos_seg := WORD(dos_mem_adr SHR 16);

  dos_data[0] := BYTE(UpCase(drive));
  dos_data[1] := BYTE(':');
  dos_data[2] := 0;
  dosmemput(dos_seg,0,dos_data,40);

  regs.ax := $2906;
  regs.si := 0;
  regs.di := 3;
  regs.ds := dos_seg;
  regs.es := dos_seg;
  RealIntr($21,regs);

  global_dos_free(dos_sel);
  valid_drive := (regs.al <> BYTE_NULL) and NOT phantom_drive(drive);
end;

{$ELSE}

function valid_drive(drive: Char; var info: String): Boolean;

var
  idx: Byte;

begin
  valid_drive := FALSE;
  info := '';
  {$IFNDEF UNIX}
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

{$ENDIF}

procedure make_stream(path,mask: String; var stream: tSTREAM);

var
  search: SearchRec;
  count1,count2: Word;
  drive: Char;

{$IFNDEF GO32V2}

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

{$ENDIF}

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
{$IFDEF GO32V2}
    While (i < r) and (stream.stuff[i].name < cmp) do
      Inc(i);
    While (j > l) and (stream.stuff[j].name > cmp) do
      Dec(j);
{$ELSE}
    While (i < r) and
          (CompareStr(stream.stuff[i].name,cmp) = isLess) do
      Inc(i);
    While (j > l) and
          (CompareStr(stream.stuff[j].name,cmp) = isMore) do
      Dec(j);
{$ENDIF}

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
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:make_stream';
{$ELSE}
{$IFNDEF UNIX}
  GetLogicalDriveStrings(SizeOf(drive_list),drive_list);
{$ENDIF}
{$ENDIF}

  count1 := 0;
  For drive := 'A' to 'Z' do
{$IFDEF GO32V2}
    If valid_drive(drive) then
{$ELSE}
    If valid_drive(drive,stream.stuff[SUCC(count1)].info) then
{$ENDIF}
      begin
        Inc(count1);
        stream.stuff[count1].name := drive;
        stream.stuff[count1].attr := volumeid;
        stream.stuff[count1].size := 0;
      end;

  Inc(count1);
  stream.stuff[count1].name := '~'+#255+'~';
  stream.stuff[count1].attr := volumeid;

  count2 := 0;
  stream.drive_count := count1;

{$IFDEF GO32V2}
  If (DiskSize(ORD(UpCase(path[1]))-ORD('A')+1) > 0) then
    begin
{$ENDIF}
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

{$IFNDEF GO32V2}
  If (Length(path) > 3) and (count1 = stream.drive_count) then
    begin
      Inc(count1);
      stream.stuff[count1].name := UPDIR_STR;
      stream.stuff[count1].attr := search.attr;
    end;
{$ENDIF}

      FindFirst(path+WILDCARD_ASTERISK,anyfile-volumeid-directory,search);
      While (DOSerror = 0) and (count1+count2 < MAX_FILES) do
        begin
          If LookUpMask(search.name) then
            begin
          search.name := Lower_filename(search.name);
              Inc(count2);
              stream.stuff[count1+count2].name := search.name;
              stream.stuff[count1+count2].attr := search.attr;
              stream.stuff[count1+count2].size := search.size;
            end;
          FindNext(search);
        end;
{$IFDEF GO32V2}
    end;
{$ENDIF}

  QuickSort(stream.drive_count+DRIVE_DIVIDER,count1);
  QuickSort(count1+DRIVE_DIVIDER,count1+count2);

  stream.count := count1+count2;
  stream.match_count := count2;
end;

var
  path: array[1..26] of String[PATH_SIZE];
  old_fselect_external_proc: Procedure;

procedure new_fselect_external_proc;
begin
  mn_environment.curr_item := fstream.stuff[mn_environment.curr_pos].name;
  If (old_fselect_external_proc <> NIL) then old_fselect_external_proc;
end;

function Fselect(mask: String): String;

var
{$IFNDEF GO32V2}
  temp1: Longint;
{$ENDIF}
  temp2: Longint;
  temp3,temp4: String;
  temp5: Longint;
  temp6,temp7: String;
  temps: String;
  temp8: Longint;
  lastp: Longint;
  idx: Byte;

function path_filter(path: String): String;
begin
  If (Length(path) > 3) and (path[Length(path)] = PATHSEP) then
    Delete(path,Length(path),1);
  path_filter := Upper_filename(path);
end;

label _jmp1;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:Fselect';
{$ENDIF}

_jmp1:

  idx := 1;
  count := 0;

  Repeat
    temp6 := Upper(ReadChunk(mask,idx));
    Inc(idx,Length(temp6)+1);
    If NOT (temp6 = '') then
      begin
        Inc(count);
        masks[count] := temp6;
      end;
  until (idx >= Length(mask)) or (temp6 = '');

  {$i-}
  GetDir(0,temp6);
  {$i+}

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
  ScreenMemCopy(screen_ptr,ptr_scr_backup);

  Repeat
    path[SUCC(ORD(UpCase(temp3[1]))-ORD('A'))] := path_filter(temp3);
    make_stream(temp3,mask,fstream);

{$IFDEF GO32V2}

    For temp2 := 1 to fstream.count do
      If (fstream.stuff[temp2].name <> UPDIR_STR) then
        begin
          menudat[temp2] := ' '+ExpStrR(BaseNameOnly(
                                   FilterStr2(fstream.stuff[temp2].name,_valid_characters,'_')),8,' ')+' '+
                                 ExpStrR(ExtOnly(
                                   fstream.stuff[temp2].name),3,' ')+' ';
          If (fstream.stuff[temp2].attr AND directory <> 0) then
            menudat[temp2] := iCASE(menudat[temp2]);
        end
      else
        begin
          menudat[temp2] := ExpStrR(' ..',mn_environment.descr_len,' ');
          fstream.stuff[temp2].name := '..';
        end;

    For temp2 := 1 to fstream.count do
      If (fstream.stuff[temp2].attr = volumeid) then
        begin
          If (fstream.stuff[temp2].name = '~'+#255+'~') then descr[temp2] := ''
          else
            descr[temp2] := '[~DRiVE~]';
        end
      else If (fstream.stuff[temp2].attr AND directory <> 0) then
             begin
               If fstream.stuff[temp2].name = '..' then
                 descr[temp2] := ExpStrL('[UP-DiR]',mn_environment.descr_len-1,' ')
               else
                 descr[temp2] := ExpStrL('[DiR]',mn_environment.descr_len-1,' ')
             end
           else
             begin
               temp7 := Num2str(fstream.stuff[temp2].size,10);
               descr[temp2] := '';
               For temp8 := 1 to Length(temp7) do
                 If (temp8 MOD 3 <> 0) or (temp8 = Length(temp7)) then
                   descr[temp2] := temp7[Length(temp7)-temp8+1]+descr[temp2]
                 else
                   descr[temp2] := ','+temp7[Length(temp7)-temp8+1]+descr[temp2];
               descr[temp2] := ExpStrL(descr[temp2],mn_environment.descr_len-1,' ');
             end;

{$ELSE}

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
            temp7 := iCASE_filename(DietStr(FilterStr2(fstream.stuff[temp2].name,_valid_characters_fname,'_'),temp1));
            If (Length(temp7) < 24) then
              begin
                menudat[temp2] := ' '+ExpStrR(temp7,24,' ')+' ';
                descr[temp2] := ExpStrR('',mn_environment.descr_len-1-10,' ');
              end
            else
              begin
                menudat[temp2] := ' '+iCASE_filename(ExpStrR(Copy(temp7,1,24),24,' '));
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
          If (fstream.stuff[temp2].name = '~'+#255+'~') then descr[temp2] := ''
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

{$ENDIF}

    For temp2 := 1 to fstream.count do
      If (SYSTEM.Pos('~',fstream.stuff[temp2].name) <> 0) and
         (fstream.stuff[temp2].name <> '~'+#255+'~') then
        While (SYSTEM.Pos('~',menudat[temp2]) <> 0) do
          menudat[temp2][SYSTEM.Pos('~',menudat[temp2])] := PATHSEP;

    temp5 := fstream.drive_count+DRIVE_DIVIDER;
    While (temp5 <= fstream.count) and (temp4 <> '') and
          (temp4 <> fstream.stuff[temp5].name) do Inc(temp5);
    If (temp5 > fstream.count) then temp5 := 1;

    For temp2 := 1 to fstream.count do
      If (Lower_filename(fstream.stuff[temp2].name) = fs_environment.last_file) and
         NOT (fstream.stuff[temp2].attr AND volumeid <> 0) then
        begin
          lastp := temp2;
          BREAK;
        end;

    If (Lower_filename(fstream.stuff[temp2].name) <> fs_environment.last_file) then
      lastp := 0;

    If (lastp = 0) or
       (lastp > MAX_FILES) then lastp := temp5;

    mn_setting.reverse_use := TRUE;
    mn_environment.context := ' ~'+Num2str(fstream.match_count,10)+' FiLES FOUND~ ';
    mn_setting.terminate_keys[3] := kBkSPC;
{$IFDEF UNIX}
    mn_setting.terminate_keys[4] := kSlash;
{$ELSE}
    mn_setting.terminate_keys[4] := kSlashR;
{$ENDIF}
    mn_setting.terminate_keys[5] := kF1;
    old_fselect_external_proc := mn_environment.ext_proc;
    mn_environment.ext_proc := @new_fselect_external_proc;

    temp := 1;
    While (temp < fstream.count) and (SYSTEM.Pos('[UP-DiR]',descr[temp]) = 0) do Inc(temp);
    If (temp < fstream.count) then mn_setting.homing_pos := temp
    else mn_setting.homing_pos := fstream.drive_count+DRIVE_DIVIDER;

{$IFDEF UNIX}
    Dec(fstream.count);
{$ENDIF}

{$IFDEF GO32V2}
    temp2 := Menu(menudat,01,01,lastp,
                  1+12+1,AdT2unit.max(work_MaxLn-7,30),fstream.count,' '+
                  iCASE(DietStr(path_filter(temp3),28)+' '));
{$ELSE}
    temp2 := Menu(menudat,01,01,lastp,
                  1+23+1,AdT2unit.max(work_MaxLn-5,30),fstream.count,' '+
                  iCASE(DietStr(FilterStr2(path_filter(temp3),_valid_characters_fname,'_'),38))+' ');
{$ENDIF}

    mn_environment.ext_proc := old_fselect_external_proc;
    mn_setting.reverse_use := FALSE;
    mn_environment.context := '';
    mn_setting.terminate_keys[3] := 0;
    mn_setting.terminate_keys[4] := 0;
    mn_setting.terminate_keys[5] := 0;

    If (mn_environment.keystroke = kENTER) and
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
            fs_environment.last_file := Lower_filename(temp4);
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
    else If (mn_environment.keystroke = kENTER) and
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
         else If (mn_environment.keystroke = kBkSPC) then
                If shift_pressed then
                  begin
                    If (home_dir_path <> '') then
                      temps := home_dir_path
                    else temps := PathOnly(ParamStr(0));
                    If (temps[Length(temps)] <> PATHSEP) then
                      temps := temps+'\';
                    {$i-}
                    ChDir(Copy(temps,1,Length(temps)-1));
                    {$i+}
                    If (IOresult = 0) then
                      begin
                        temp3 := temps;
                        temp4 := '..';
                      end
                    else begin
                           {$i-}
                           ChDir(temp3);
                           {$i+}
                           If (IOresult <> 0) then ;
                         end;
                  end
                else If (SYSTEM.Pos(PATHSEP,Copy(temp3,3,Length(temp3)-3)) <> 0) then
                       begin
                         Delete(temp3,Length(temp3),1);
                         temp4 := NameOnly(temp3);
                         While (temp3[Length(temp3)] <> PATHSEP) do
                           Delete(temp3,Length(temp3),1);
                         fs_environment.last_file := Lower_filename(temp4);
                         {$i-}
                         ChDir(Copy(temp3,1,Length(temp3)-1));
                         {$i+}
                         If (IOresult <> 0) then ;
                       end
                     else
{$IFDEF UNIX}
              else If (mn_environment.keystroke = kSlash) then
{$ELSE}
              else If (mn_environment.keystroke = kSlashR) then
{$ENDIF}
                     begin
                       temp3 := Copy(temp3,1,3);
                       temp4 := '';
                       fs_environment.last_file := temp4;
                       {$i-}
                       ChDir(Copy(temp3,1,Length(temp3)-1));
                       {$i+}
                       If (IOresult <> 0) then ;
                     end
                   else fs_environment.last_file := Lower_filename(fstream.stuff[temp2].name);
  until (mn_environment.keystroke = kENTER) or
        (mn_environment.keystroke = kESC) or
        (mn_environment.keystroke = kF1);

  mn_environment.descr_len := 0;
  mn_environment.descr := NIL;
  mn_environment.winshade := TRUE;
  mn_setting.frame_enabled := TRUE;
  mn_setting.shadow_enabled := TRUE;
  mn_setting.homing_pos := 0;

  move_to_screen_data := ptr_scr_backup;
  move_to_screen_area[1] := mn_environment.xpos;
  move_to_screen_area[2] := mn_environment.ypos;
  move_to_screen_area[3] := mn_environment.xpos+mn_environment.xsize+2+1;
  move_to_screen_area[4] := mn_environment.ypos+mn_environment.ysize+1;
  move2screen;

  If (mn_environment.keystroke = kF1) then
    begin
      HELP('file_browser');
      GOTO _jmp1;
    end;

  Fselect := temp3+fstream.stuff[temp2].name;
  fs_environment.last_dir := path[SUCC(ORD(UpCase(temp3[1]))-ORD('A'))];
  {$i-}
  ChDir(temp6);
  {$i+}
  If (IOresult <> 0) then ;
  If (mn_environment.keystroke = kESC) then Fselect := '';
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

function HScrollBar(dest: tSCREEN_MEM_PTR; x,y: Byte; size: Byte; len1,len2,pos: Word;
                    atr1,atr2: Byte): Word;
var
  temp: Word;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:HScrollBar';
{$ENDIF}
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
      ShowStr(dest,x,y,#17+ExpStrL('',size-2,#176)+#16,atr1);
      If (size-2-1 < 10) then ShowStr(dest,x+1+temp,y,#178,atr2)
      else ShowStr(dest,x+1+temp,y,#178#178#178,atr2);
    end
  else ShowCStr(dest,x,y,'~'#17'~'+ExpStrL('',size-2,#177)+'~'#16'~',atr2,atr1);
  HScrollBar := pos;
end;

function VScrollBar(dest: tSCREEN_MEM_PTR; x,y: Byte; size: Byte; len1,len2,pos: Word;
                    atr1,atr2: Byte): Word;
var
  temp: Word;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:VScrollBar';
{$ENDIF}
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
      ShowVStr(dest,x,y,#30+ExpStrL('',size-2,#176)+#31,atr1);
      If (size-2-1 < 10) then ShowStr(dest,x,y+1+temp,#178,atr2)
      else ShowVStr(dest,x,y+1+temp,#178#178#178,atr2);
    end
  else ShowVCStr(dest,x,y,'~'#30'~'+ExpStrL('',size-2,#177)+'~'#31'~',atr2,atr1);
  VScrollBar := pos;
end;

procedure DialogIO_Init;

var
  index: Byte;

begin
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'DIALOGIO.PAS:DialogIO_Init';
{$ENDIF}

  dl_setting.frame_type      := frame_double;
  dl_setting.title_attr      := dialog_background+dialog_title;
  dl_setting.box_attr        := dialog_background+dialog_border;
  dl_setting.text_attr       := dialog_background+dialog_text;
  dl_setting.text2_attr      := dialog_background+dialog_hi_text;
  dl_setting.keys_attr       := dialog_background+dialog_item;
  dl_setting.keys2_attr      := dialog_sel_itm_bck+dialog_sel_itm;
  dl_setting.short_attr      := dialog_background+dialog_short;
  dl_setting.short2_attr     := dialog_sel_itm_bck+dialog_sel_short;
  dl_setting.disbld_attr     := dialog_background+dialog_item_dis;
  dl_setting.contxt_attr     := dialog_background+dialog_context;
  dl_setting.contxt2_attr    := dialog_background+dialog_context_dis;

  mn_setting.frame_type      := frame_double;
  mn_setting.title_attr      := dialog_background+dialog_title;
  mn_setting.menu_attr       := dialog_background+dialog_border;
  mn_setting.text_attr       := dialog_background+dialog_item;
  mn_setting.text2_attr      := dialog_sel_itm_bck+dialog_sel_itm;
  mn_setting.default_attr    := dialog_def_bckg+dialog_def;
  mn_setting.short_attr      := dialog_background+dialog_short;
  mn_setting.short2_attr     := dialog_sel_itm_bck+dialog_sel_short;
  mn_setting.disbld_attr     := dialog_background+dialog_item_dis;
  mn_setting.contxt_attr     := dialog_background+dialog_context;
  mn_setting.contxt2_attr    := dialog_background+dialog_context_dis;
  mn_setting.topic_attr      := dialog_background+dialog_topic;
  mn_setting.hi_topic_attr   := dialog_background+dialog_hi_topic;
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
  mn_environment.own_refresh := FALSE;
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
  mn_environment.hlight_chrs := 0;

  For index := 1 to 26 do
    path[index] := CHR(ORD('a')+PRED(index))+':'+PATHSEP;
end;

end.
