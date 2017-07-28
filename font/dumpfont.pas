uses DOS,AdT2data;

const
  _font_file_header_data: array[0..9] of Dword = (
    $0CD0083B8,$01110B810,$0B91000BB,$0D2330100,$0CD0128BD,$04C00B810,$0754C21CD,$073276550,
    $061686320,$074657372);

function Upper(str: String): String;
begin
  asm
        lea     esi,[str]
        mov     edi,@RESULT
        mov     al,[esi]
        inc     esi
        mov     [edi],al
        inc     edi
        xor     ecx,ecx
        mov     cl,al
        jecxz   @@3
@@1:    mov     al,[esi]
        inc     esi
        cmp     al,'a'
        jb      @@2
        cmp     al,'z'
        ja      @@2
        sub     al,20h
@@2:    mov     [edi],al
        inc     edi
        loop    @@1
@@3:
  end;
end;

function ExpStrL(str: String; size: Byte; chr: Char): String;
begin
  asm
        lea     esi,[str]
        mov     edi,@RESULT
        cld
        xor     ecx,ecx
        lodsb
        cmp     al,size
        jge     @@1
        mov     ah,al
        mov     al,size
        stosb
        mov     al,ah
        mov     cl,size
        sub     cl,al
        mov     al,chr
        rep     stosb
        mov     cl,ah
        rep     movsb
        jmp     @@2
@@1:    stosb
        mov     cl,al
        rep     movsb
@@2:
  end;
end;

function Num2str(num: Longint; base: Byte): String;

const
  hexa: array[0..PRED(16)+32] of Char = '0123456789ABCDEF'+
                                        #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0;
begin
  asm
        xor     eax,eax
        xor     edx,edx
        xor     edi,edi
        xor     esi,esi
        mov     eax,num
        xor     ebx,ebx
        mov     bl,base
        cmp     bl,2
        jb      @@3
        cmp     bl,16
        ja      @@3
        mov     edi,32
@@1:    dec     edi
        xor     edx,edx
        div     ebx
        mov     esi,edx
        mov     dl,byte ptr [hexa+esi]
        mov     byte ptr [hexa+edi+16],dl
        and     eax,eax
        jnz     @@1
        mov     esi,edi
        mov     ecx,32
        sub     ecx,edi
        mov     edi,@RESULT
        mov     al,cl
        stosb
@@2:    mov     al,byte ptr [hexa+esi+16]
        stosb
        inc     esi
        loop    @@2
        jmp     @@4
@@3:    mov     edi,@RESULT
        xor     al,al
        stosb
@@4:
  end;
end;

var
  f: File;
  t: Text;
  temp,temp2,temp3: Longint;
  offset: Longint;
  temps: String;
  buf: array[0..PRED(4096+40)] of Byte;

procedure _invoke_error_1;
begin
  WriteLn('Error writing FONT.COM');
  HALT(1);
end;

procedure _invoke_error_2;
begin
  WriteLn('Error reading FONT.COM');
  HALT(2);
end;

procedure _invoke_error_3;
begin
  WriteLn('Error writing FONT.DAT');
  HALT(3);
end;

begin
  If (Upper(ParamStr(1)) = '/FONT') then
    begin
      {$i-}
      Assign(f,'font.com');
      SetFAttr(f,ARCHIVE);
      Rewrite(f,1);
      {$i+}
      If (IOresult <> 0) then _invoke_error_1;
      BlockWrite(f,_font_file_header_data,40,temp);
      If (temp <> 40) then _invoke_error_1;
      BlockWrite(f,font8x16,4096,temp);
      If (temp <> 4096) then _invoke_error_1;
      {$i-}
      Close(f);
      {$i+}
      If (IOresult <> 0) then _invoke_error_1;
      HALT(0);
    end;

  If (Upper(ParamStr(1)) = '/DATA') then
    begin
      {$i-}
      Assign(f,'font.com');
      Reset(f,1);
      {$i+}
      If (IOresult <> 0) then _invoke_error_2;
      BlockRead(f,buf,SizeOf(buf),temp);
      If (FileSize(f) > 4096+40) or (temp < 4096+40) then _invoke_error_2;
      {$i-}
      Close(f);
      {$i+}
      If (IOresult <> 0) then _invoke_error_2;
      {$i-}
      Assign(t,'font.dat');
      Rewrite(t);
      {$i+}
      If (IOresult <> 0) then _invoke_error_3;
      WriteLn(t,'const');
      WriteLn(t,'  font8x16: array[0..1023] of Dword = (');
      offset := 40;
      For temp3 := 1 to 128 do
        begin
          Write(t,'    ');
          For temp2 := 1 to 8 do
            begin
              temps := '';
              For temp := 1 to 4 do
                begin
                  temps := ExpStrL(Num2str(buf[offset],16),2,'0')+temps;
                  Inc(offset);
                end;
              If (offset < 4096+40) then Write(t,'$'+temps+',')
              else Write(t,'$'+temps+');')
            end;
          WriteLn(t);
        end;
      {$i-}
      Close(t);
      {$i+}
      If (IOresult <> 0) then _invoke_error_3;
      HALT(0);
    end;

  WriteLn('Usage: DUMPFONT [/font] | [/data]');
end.
