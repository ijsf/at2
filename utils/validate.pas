uses DOS,StringIO;

var
  f,t: Text;
  txt: String;
  year,month,day,dayw,
  hour,minute,second,hundred: Word;
  date_str,time_str: String;

begin
  Assign(f,'adt2text.pas');
  Reset(f);

  Assign(t,'adt2text.new');
  Rewrite(t);

  GetDate(year,month,day,dayw);
  GetTime(hour,minute,second,hundred);

  date_str := ExpStrL(Num2str(month,10),2,'0')+'-'+
              ExpStrL(Num2str(day,10),2,'0')+'-'+
              Num2str(year,10);

  If (hour >= 12) then
    If (hour = 12) then
      time_str := Num2str(hour,10)+':'+
                  ExpStrL(Num2str(minute,10),2,'0')+'pm'
    else time_str := Num2str(hour-12,10)+':'+
                     ExpStrL(Num2str(minute,10),2,'0')+'pm'
  else If (hour = 0) then
         time_str := Num2str(hour+12,10)+':'+
                     ExpStrL(Num2str(minute,10),2,'0')+'am'
       else time_str := Num2str(hour,10)+':'+
                        ExpStrL(Num2str(minute,10),2,'0')+'am';

  While NOT EOF(f) do
    begin
      ReadLn(f,txt);
      If (Copy(txt,1,3) = '{__') and (Copy(txt,10,3) = '__}') then
        If (Copy(txt,4,6) = 'AT2REV') then
          txt := Copy(txt,1,12)+'at2rev  = '''+ParamStr(2)+''';'
        else If (Copy(txt,4,6) = 'AT2VER') then
               txt := Copy(txt,1,12)+'at2ver  = '''+ParamStr(1)+''';'
             else If (Copy(txt,4,6) = 'AT2DAT') then
                    txt := Copy(txt,1,12)+'at2date = '''+date_str+''';'
                  else If (Copy(txt,4,6) = 'AT2LNK') then
                         txt := Copy(txt,1,12)+'at2link = '''+time_str+''';';
      WriteLn(t,txt);
    end;

  Close(f); Erase(f);
  Close(t);
  Rename(t,'adt2text.pas');
end.

