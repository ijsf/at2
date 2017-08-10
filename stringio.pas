unit StringIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

type
  tCHARSET = Set of Char;

function _str2(str: String; len: Byte): String;
function byte2hex(value: Byte): String;
function byte2dec(value: Byte): String;
function Capitalize(str: String): String;
function Upper(str: String): String;
function Lower(str: String): String;
function iCASE(str: String): String;
function RotStrL(str1,str2: String; shift: Byte): String;
function RotStrR(str1,str2: String; shift: Byte): String;
function ExpStrL(str: String; size: Byte; chr: Char): String;
function ExpStrR(str: String; size: Byte; chr: Char): String;
function DietStr(str: String; size: Byte): String;
function CutStr(str: String): String;
function CutStrL(str: String; margin: Byte): String;
function CutStrR(str: String; margin: Byte): String;
function FlipStr(str: String): String;
function FilterStr(str: String; chr0,chr1: Char): String;
function FilterStr1(str: String; chr0: Char): String;
function FilterStr2(str: String; chr0: tCHARSET; chr1: Char): String;
function Num2str(num: Longint; base: Byte): String;
function Str2num(str: String; base: Byte): Longint;

type
  tINPUT_STR_SETTING = Record
                         insert_mode,
                         replace_enabled,
                         append_enabled:  Boolean;
                         char_filter,
                         character_set,
                         valid_chars,
                         word_characters: tCHARSET;
                         terminate_keys:  array[1..50] of Word;
                       end;
type
  tINPUT_STR_ENVIRONMENT = Record
                             keystroke: Word;
                             locate_pos: Byte;
                             insert_mode: Boolean;
                           end;
const
  is_setting: tINPUT_STR_SETTING =
    (insert_mode:     TRUE;
     replace_enabled: TRUE;
     append_enabled:  TRUE;
     char_filter:     [#32..#255];
     character_set:   [#32..#255];
     valid_chars:     [#32..#255];
     word_characters: ['A'..'Z','a'..'z','0'..'9','_'];
     terminate_keys:  ($011b,$1c0d,$0000,$0000,$0000,
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
  is_environment: tINPUT_STR_ENVIRONMENT;

function InputStr(s: String; x,y,ln,ln1: Byte; atr1,atr2: Byte): String;
function SameName(str1,str2: String): Boolean;
function PathOnly(path: String): String;
function NameOnly(path: String): String;
function BaseNameOnly(path: String): String;
function ExtOnly(path: String): String;

procedure StringIO_Init;

implementation

uses
  DOS,
  AdT2unit,AdT2sys,AdT2keyb,
  TxtScrIO,
  strutils, sysutils;

{
  function _str2(str: String; len: Byte): String;
  begin
    asm
          lea     esi,[str]
          mov     edi,@RESULT
          movzx   ebx,len
          xor     edx,edx # edx = 0
        
          push    edi # edi = &RESULT[0]
          lodsb # load from esi (str[0]) in al, increment
          inc     edi # edi++
          xor     ecx,ecx
          mov     ecx,ebx # len == null
          jecxz   @@3
          movzx   ecx,al # str[i] == null
          jecxz   @@3
  @@1:    cmp     edx,ebx # edx = counter, ebx = len
          jae     @@3
          lodsb # load from esi, increment
          stosb # copy into edi, increment
          cmp     al,'`'
          jz      @@2 # jump if str[i] == '`'
          inc     edx
  @@2:    loop    @@1
  @@3:    pop     edi # edi = &RESULT[0]

          mov     eax,esi
          lea     esi,[str]
          sub     eax,esi
          dec     eax
          stosb # copy into edi (RESULT[0], length)
    end;
  end;
}
function _str2(str: String; len: Byte): String;
var
  i: Byte;
  j: Byte;
  strOut: String;
begin
  if (len <> 0) and (Length(str) <> 0) then
    i := 0;
    j := 0;
    begin
      while (i <= len) do
        begin
          strOut[j] := str[j];
          if str[j] <> '`' then
            inc(i);
          inc(j);
        end;
    end;
  _str2 := strOut;
end;

function byte2hex(value: Byte): String;
begin
  byte2hex := hexStr(value, 2);
end;

function byte2dec(value: Byte): String;
var
  s : String;
begin
  Str(value, s);
  byte2dec := s;
end;

function Capitalize(str: String): String;
begin
  Capitalize := AnsiProperCase(str, StdWordDelims);
end;

function Upper(str: String): String;
begin
  Upper := UpperCase(str);
end;

function Lower(str: String): String;
begin
  Lower := LowerCase(str);
  end;

function iCase(str: String): String;
begin
  iCase := ReplaceStr(Upper(str), 'I', 'i');
end;

function RotStrL(str1,str2: String; shift: Byte): String;
begin
  RotStrL := Copy(str1,shift+1,Length(str1)-shift)+
             Copy(str2,1,shift);
end;

function RotStrR(str1,str2: String; shift: Byte): String;
begin
  RotStrR := Copy(str2,Length(str2)-shift+1,shift)+
             Copy(str1,1,Length(str1)-shift);
end;

function ExpStrL(str: String; size: Byte; chr: Char): String;
begin
  ExpStrL := AddChar(chr, str, size);
end;

function ExpStrR(str: String; size: Byte; chr: Char): String;
begin
  ExpStrR := AddCharR(chr, str, size);
end;

function DietStr(str: String; size: Byte): String;
begin
  If (Length(str) <= size) then
    begin
      DietStr := str;
      EXIT;
    end;

  Repeat
    Delete(str,size DIV 2,1)
  until (Length(str)+3 = size);

  Insert('...',str,size DIV 2);
  DietStr := str
end;

function CutStr(str: String): String;
begin
  While (BYTE(str[0]) <> 0) and (str[1] = ' ') do
    Delete(str,1,1);
  While (BYTE(str[0]) <> 0) and (str[BYTE(str[0])] = ' ') do
    Delete(str,BYTE(str[0]),1);
  CutStr := str;
end;

function CutStrL(str: String; margin: Byte): String;

var
  idx: Byte;

begin
  If (margin = 0) then margin := Length(str)
  else If (margin > Length(str)) then
         margin := Length(str);
  idx := 0;
  While (idx+1 <= margin) and (str[idx+1] = ' ') do
    Inc(idx);
  If (idx <> 0) then Delete(str,1,idx);
  CutStrL := str;
end;

function CutStrR(str: String; margin: Byte): String;

var
  idx: Byte;

begin
  If (margin > Length(str)) then
    margin := Length(str);
  idx := 0;
  While (str[BYTE(str[0])-idx] = ' ') and
        (BYTE(str[0])-idx >= margin) do
    Inc(idx);
  Dec(BYTE(str[0]),idx);
  CutStrR := str;
end;

function FlipStr(str: String): String;
begin
  FlipStr := ReverseString(str);
end;

function FilterStr(str: String; chr0,chr1: Char): String;
begin
  FilterStr := ReplaceStr(str, chr0, chr1);
end;

function FilterStr1(str: String; chr0: Char): String;
begin
  FilterStr1 := DelChars(str, chr0);
end;

const
  _treat_char: array[$80..$a5] of Char =
    'CueaaaaceeeiiiAAE_AooouuyOU_____aiounN';

function FilterStr2(str: String; chr0: tCHARSET; chr1: Char): String;

var
  temp: Byte;

begin
  For temp := 1 to Length(str) do
    If NOT (str[temp] in chr0) then
      If (str[temp] >= #128) and (str[temp] <= #165) then
        str[temp] := _treat_char[BYTE(str[temp])]
      else If (str[temp] = #0) then str[temp] := ' '
           else str[temp] := chr1;
  FilterStr2 := str;
end;

function Num2str(num: Longint; base: Byte): String;
begin
  Num2str := Dec2Numb(num, 1, base);
end;

const
  digits: array[0..35] of Char = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

function Digit2index(digit: Char): Byte;

var
  index: Byte;

begin
  digit := UpCase(digit);
  index := 15;
  While (index > 0) and (digit <> digits[index]) do Dec(index);
  Digit2index := Index;
end;

function position_value(position,base: Byte): Longint;

var
  value: Longint;
  index: Byte;

begin
  value := 1;
  For index := 2 to position do value := value*base;
  position_value := value;
end;

function Str2num(str: String; base: Byte): Longint;

var
  value: Longint;
  index: Byte;

begin
  value := 0;
  For index := 1 to Length(str) do
    Inc(value,Digit2index(str[index])*
              position_value(Length(str)-index+1,base));
  Str2num := value;
end;

function InputStr(s: String; x,y,ln,ln1: Byte; atr1,atr2: Byte): String;

var
  appn,for1st,qflg,ins: Boolean;
  cloc,xloc,xint,attr: Byte;
  key: Word;
  s1,s2: String;

function more(value1,value2: Byte): Byte;
begin
  If (value1 >= value2) then more := value1
  else more := value2;
end;

label _end;

begin { InputStr }
{$IFDEF GO32V2}
  _last_debug_str_ := _debug_str_;
  _debug_str_ := 'STRINGIO.PAS:InputStr';
{$ENDIF}
  s := Copy(s,1,ln);
  If (is_environment.locate_pos > ln1) then
    is_environment.locate_pos := ln1;
  If (is_environment.locate_pos > Length(s)+1) then
    is_environment.locate_pos := Length(s);

  cloc := is_environment.locate_pos;
  xloc := is_environment.locate_pos;
  xint := x;
  qflg := FALSE;
  ins  := is_setting.insert_mode;
  appn := NOT is_setting.append_enabled;

  Dec(x);
  If ins then ThinCursor else WideCursor;
  s1 := s;
  If (BYTE(s1[0]) > ln1) then s1[0] := CHR(ln1);

  ShowStr(screen_ptr,xint,y,ExpStrR('',ln1,' '),atr1);
  ShowStr(screen_ptr,xint,y,FilterStr2(s1,is_setting.char_filter,'_'),atr2);
  for1st := TRUE;

  Repeat
    s2 := s1;
    If (xloc = 1) then s1 := Copy(s,cloc,ln1)
    else s1 := Copy(s,cloc-xloc+1,ln1);

    If NOT appn then attr := atr2
    else attr := atr1;

    If appn and for1st then
      begin
        ShowStr(screen_ptr,xint,y,ExpStrR(FilterStr2(s1,is_setting.char_filter,'_'),ln1,' '),atr1);
        for1st := FALSE;
      end;

    If (s2 <> s1) then
      ShowStr(screen_ptr,xint,y,ExpStrR(FilterStr2(s1,is_setting.char_filter,'_'),ln1,' '),atr1);

    If (ln1 < ln) then
      If (cloc-xloc > 0) and (Length(s) > 0) then
        ShowStr(screen_ptr,xint,y,#17,(attr AND $0f0)+$0f)
      else If (cloc-xloc = 0) and (Length(s) <> 0) then
             ShowStr(screen_ptr,xint,y,s[1],attr)
           else
             ShowStr(screen_ptr,xint,y,' ',atr1);

    If (ln1 < ln) then
      If (cloc-xloc+ln1 < Length(s)) then
        ShowStr(screen_ptr,xint+ln1-1,y,#16,(attr AND $0f0)+$0f)
      else If (cloc-xloc+ln1 = Length(s)) then
             ShowStr(screen_ptr,xint+ln1-1,y,FilterStr2(s[Length(s)],is_setting.char_filter,'_'),attr)
           else
             ShowStr(screen_ptr,xint+ln1-1,y,' ',atr1);

    GotoXY(x+xloc,y);
    If keypressed then key := getkey else GOTO _end;
    If LookupKey(key,is_setting.terminate_keys,50) then qflg := TRUE;

    If NOT qflg then
      Case key of
        kTAB: appn := TRUE;

        kCtrlY: begin
                  appn := TRUE;
                  s := '';
                  cloc := 1;
                  xloc := 1;
                end;

        kCtrlT: begin
                  appn := TRUE;
                  While (s[cloc] in is_setting.word_characters) and
                        (cloc <= Length(s)) do Delete(s,cloc,1);

                  While NOT (s[cloc] in is_setting.word_characters) and
                            (cloc <= Length(s)) do Delete(s,cloc,1);
                end;

        kCtrlK: begin
                  appn := TRUE;
                  Delete(s,cloc,Length(s));
                end;

        kCtBkSp: begin
                   appn := TRUE;
                   While (s[cloc-1] in is_setting.word_characters) and
                         (cloc > 1) do
                     begin
                       Dec(cloc); Delete(s,cloc,1);
                       If (xloc > 1) then Dec(xloc);
                     end;

                   While NOT (s[cloc-1] in is_setting.word_characters) and
                             (cloc > 1) do
                     begin
                       Dec(cloc); Delete(s,cloc,1);
                       If (xloc > 1) then Dec(xloc);
                     end;
                 end;

        kBkSPC: begin
                  appn := TRUE;
                  If (cloc > 1) then
                    begin
                      If (xloc > 1) then Dec(xloc);
                      Dec(cloc); Delete(s,cloc,1);
                    end;
                end;

        kDELETE: begin
                   appn := TRUE;
                   If (cloc <= Length(s)) then Delete(s,cloc,1);
                 end;

        kCtLEFT: begin
                   appn := TRUE;
                   While (s[cloc] in is_setting.word_characters) and
                         (cloc > 1) do
                     begin
                       Dec(cloc);
                       If (xloc > 1) then Dec(xloc);
                     end;

                   While NOT (s[cloc] in is_setting.word_characters) and
                             (cloc > 1) do
                     begin
                       Dec(cloc);
                       If (xloc > 1) then Dec(xloc);
                     end;
                 end;

        kCtRGHT: begin
                   appn := TRUE;
                   While (s[cloc] in is_setting.word_characters) and
                         (cloc < Length(s)) do
                     begin
                       Inc(cloc);
                       If (xloc < ln1) then Inc(xloc);
                     end;

                   While NOT (s[cloc] in is_setting.word_characters) and
                             (cloc < Length(s)) do
                     begin
                       Inc(cloc);
                       If (xloc < ln1) then Inc(xloc);
                     end;
                 end;

        kLEFT: begin
                 appn := TRUE;
                 If (cloc > 1) then Dec(cloc);
                 If (xloc > 1) then Dec(xloc);
               end;

        kRIGHT: begin
                  appn := TRUE;
                  If (cloc < Length(s)) or ((cloc = Length(s)) and
                       ((Length(s) < more(ln,ln1)))) then
                    Inc(cloc);
                  If (xloc < ln1) and (xloc <= Length(s)) then Inc(xloc);
                end;

        kINSERT: If is_setting.replace_enabled then
                   begin
                     ins := NOT ins;
                     If ins then ThinCursor else WideCursor;
                   end;

        kHOME: begin
                 appn := TRUE;
                 cloc := 1;
                 xloc := 1;
               end;

        kEND: begin
                appn := TRUE;
                If (Length(s) < more(ln,ln1)) then cloc := Succ(Length(s))
                else cloc := Length(s);
                If (cloc < ln1) then xloc := cloc else xloc := ln1;
              end;

        else If (CHR(LO(key)) in tCHARSET(is_setting.character_set)) then
               begin
                 If NOT appn then begin s := ''; cloc := 1; xloc := 1; end;
                 appn := TRUE;
                 If ins and (Length(CutStrR(s,cloc)) < ln) then
                   begin
                     If (Length(CutStrR(s,cloc)) < ln) then
                       Insert(CHR(LO(key)),s,cloc)
                     else s[cloc] := CHR(LO(key));
                     s := FilterStr2(s,is_setting.valid_chars,'_');
                     If (cloc < ln) then Inc(cloc);
                     If (xloc < ln) and (xloc < ln1) then Inc(xloc)
                   end
                 else
                   If (Length(s) < ln) or NOT ins then
                     begin
                       If (cloc > Length(s)) and (Length(s) < ln) then
                         Inc(BYTE(s[0]));
                       s[cloc] := CHR(LO(key));
                       s := FilterStr2(s,is_setting.valid_chars,'_');
                       If (cloc < ln) then Inc(cloc);
                       If (xloc < ln) and (xloc < ln1) then Inc(xloc);
                     end;
               end;
      end;
_end:
{$IFDEF GO32V2}
      // draw_screen;
      keyboard_reset_buffer_alt;
{$ELSE}
      draw_screen;
      // keyboard_reset_buffer;
{$ENDIF}
  until qflg;

  If (cloc = 0) then is_environment.locate_pos := 1
  else is_environment.locate_pos := cloc;
  is_environment.keystroke := key;
  is_environment.insert_mode := ins;
  InputStr := s;
end;

var
  dir:  DirStr;
  name: NameStr;
  ext:  ExtStr;

function PathOnly(path: String): String;
begin
  FSplit(path,dir,name,ext);
  PathOnly := dir;
end;

function NameOnly(path: String): String;
begin
  FSplit(path,dir,name,ext);
  NameOnly := name+ext;
end;

function BaseNameOnly(path: String): String;
begin
  FSplit(path,dir,name,ext);
  BaseNameOnly := name;
end;

function ExtOnly(path: String): String;
begin
  FSplit(path,dir,name,ext);
  Delete(ext,1,1);
  ExtOnly := Lower_filename(ext);
end;

procedure StringIO_Init;
begin
  is_environment.locate_pos := 1;
  is_setting.char_filter := _valid_characters;
  is_setting.valid_chars := _valid_characters;
end;

end.
