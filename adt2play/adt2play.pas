program AdT2_Player;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
uses
  DOS,GO32,
  A2player,A2fileIO,A2scrIO,
  StringIO,TxtScrIO;

const
  VERSION_STR = '0.45';

const
  modname: array[1..15] of String[39] = (
    '/´DLiB TR/´CK3R ][ module',
    '/´DLiB TR/´CK3R ][ G3 module',
    '/´DLiB TR/´CK3R ][ tiny module',
    '/´DLiB TR/´CK3R ][ G3 tiny module',
    'Amusic module',
    'XMS-Tracker module',
    'BoomTracker 4.0 module',
    'Digital-FM module',
    'HSC AdLib Composer / HSC-Tracker module',
    'MPU-401 tr’kkîr module',
    'Reality ADlib Tracker module',
    'Scream Tracker 3.x module',
    'FM-Kingtracker module',
    'Surprise! AdLib Tracker module',
    'Surprise! AdLib Tracker 2.0 module');

var
  fkey: Word;
  index,last_order: Byte;
  dirinfo: SearchRec;
  dos_memavail: Word;
  mem_info: TFPCHeapStatus;
  free_mem: Longint;

var
  temp,temp2: Byte;
  _ParamStr: array[0..255] of String[80];

const
  jukebox: Boolean = FALSE;

const
  kBkSPC  = $0e08;
  kESC    = $011b;
  kENTER  = $1c0d;

function keypressed: Boolean; assembler;
asm
        mov     ah,01h
        int     16h
        mov     al,TRUE
        jnz     @@1
        mov     al,FALSE
@@1:
end;

procedure _list_title;
begin
  If iVGA then
    begin
      CWriteLn('',$07,0);
      CWriteLn('   subz3ro''s',$09,0);
      CWriteLn('       ÄÂÄ       ÄÄ',$09,0);
      CWriteLn('  /´DLiB³R/´CK3R ³³ PLAYER',$09,0);
      CWriteLn('   ³       ³     ÄÄ   '+VERSION_STR,$09,0);
      CWriteLn('',$07,0);
    end
  else begin
         WriteLn;
         WriteLn('   subz3ro''s');
         WriteLn('       ÄÂÄ       ÄÄ');
         WriteLn('  /´DLiB³R/´CK3R ³³ PLAYER');
         WriteLn('   ³       ³     ÄÄ   '+VERSION_STR);
         WriteLn;
       end;
end;

function _gfx_mode: Boolean;

var
  result: Boolean;
  temp: Byte;

begin
  result := FALSE;
  For temp := 1 to ParamCount do
    If (Lower(_ParamStr[temp]) = '/gfx') then
      begin
        result := TRUE;
        BREAK;
      end;
  _gfx_mode := result;
end;

var
  old_exit_proc: procedure;

procedure new_exit_proc;

var
  temp: Byte;

begin
  asm mov ax,03h; xor bh,bh; int 10h end;
  ExitProc := @old_exit_proc;

  If (ExitCode <> 0) then
    begin
      WriteLn('ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ');
      WriteLn('Û ABNORMAL PROGRAM TERMiNATiON Û');
      WriteLn('ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß');
      WriteLn('PROGRAM VERSION: ',VERSION_STR);
      WriteLn('ERROR #'+Num2str(ExitCode,10)+' at '+ExpStrL(Num2str(LONGINT(ErrorAddr),16),8,'0'));
      WriteLn('DEBUG INFO -> ',_debug_str_);
      WriteLn;
      WriteLn('Please send this information with brief description what you were doing');
      WriteLn('when you encountered this error to following email address:');
      WriteLn;
      WriteLn('subz3ro.altair@gmail.com');
      WriteLn;
      WriteLn('Thanks and sorry for your inconvenience! :-)');
      ErrorAddr := NIL;
      HALT(ExitCode);
    end
  else HALT(0);
end;

begin
  For temp := 0 to 255 do
    _ParamStr[temp] := ParamStr(temp);

  asm
        mov     bx,0ffffh
        mov     ah,48h
        int     21h
        mov     dos_memavail,bx
  end;

  If (dos_memavail*16 DIV 1024 < 120) then
    begin
      If _gfx_mode then _list_title;
      WriteLn('ERROR(1) - Insufficient DOS memory!');
      HALT(1);
    end;

   If NOT iVGA then
    begin
      WriteLn('ERROR(2) - Insufficient video equipment!');
      HALT(2);
    end;

  For temp := 1 to ParamCount do
    If (Lower(_ParamStr[temp]) = '/jukebox') then
      jukebox := TRUE;

  For temp := 1 to ParamCount do
    If (Lower(_ParamStr[temp]) = '/latency') then
      opl3out := opl2out;

  index := 0;
  If (ParamCount = 0) then
    begin
      If _gfx_mode then _list_title;
      CWriteLn('Syntax: '+BaseNameOnly(_ParamStr[0])+' files|wildcards [files|wildcards{...}] [options]',$07,0);
      CWriteLn('',$07,0);
      CWriteLn('Command-line options:',$07,0);
      CWriteLn('  /jukebox    play modules w/ no repeat',$07,0);
      CWriteLn('  /gfx        graphical interface',$07,0);
      CWriteLn('  /latency    compatibility mode for OPL3 latency',$07,0);
      HALT;
    end;

  @old_exit_proc := ExitProc;
  ExitProc := @new_exit_proc;
  mem_info := GetFPCHeapStatus;
  free_mem := mem_info.CurrHeapFree*1000;
  error_code := 0;
  temp := $80;

  Repeat
    If (free_mem > PATTERN_SIZE*temp) then
      begin
        max_patterns := temp;
        BREAK;
      end
    else If (temp-$10 >= $10) then Dec(temp,$10)
         else begin
                error_code := -2;
                BREAK;
              end;
  until FALSE;

  If (error_code <> -2) then
    GetMem(pattdata,PATTERN_SIZE*max_patterns);

  FillChar(decay_bar,SizeOf(decay_bar),0);
  play_status := isStopped;
  init_songdata;
  init_timer_proc;

  If _gfx_mode then
    toggle_picture_mode
  else begin
         FillWord(screen_ptr^,MAX_SCREEN_MEM_SIZE DIV 2,$0700);
         dosmemput($0b800,0,screen_ptr^,MAX_SCREEN_MEM_SIZE);
         GotoXY(1,1);
         _list_title;
       end;

  Repeat
    If NOT (index <> 0) then
      begin
        CWriteLn(FilterStr(DietStr('úù-Ä--ùú   úù-ÄÄÄÄÄÄÄÄÄÄÄÄÄÄ--ùú       úù-ÄÄÄ--ùú úù-ÄÄ-Äùú',
                                   PRED(MaxCol)),
                           '.',' '),$01,0);
        CWriteLn(                  '  ~[~SPACE~]~ Fast-Forward ~[~Ä~]~ Restart ~[~ÄÙ~]~ Next ~[~ESC~]~ Quit',$09,$01);
        CWriteLn(FilterStr(DietStr('úù-ÄÄÄÄÄÄÄÄÄÄ--ùú      úù-ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ-Äùú',
                                  PRED(MaxCol)),
                          '.',' '),$01,0);

        CWriteLn('',$07,0);
        _window_top := WhereY;
      end;

    Inc(index);
    If (_ParamStr[index][1] <> '/') then
      begin
        FindFirst(_ParamStr[index],AnyFile-VolumeID-Directory,dirinfo);
        If (DosError <> 0) then
          begin
            CWriteLn(DietStr('ERROR(2) - No such file "'+
                             Lower(_ParamStr[index])+'"',
                     PRED(MaxCol)),$07,0);
            CWriteLn('',$07,0);
            FindNext(dirinfo);
            CONTINUE;
          end;

        While NOT (DosError <> 0) do
          begin
            If (PathOnly(_ParamStr[index]) <> '') then
              songdata_source := Upper(PathOnly(_ParamStr[index])+dirinfo.name)
            else songdata_source := Upper(dirinfo.name);

            C3Write(DietStr('Loading "'+songdata_source+'" (please wait)',
                             PRED(MaxCol)),$07,0,0);
            wtext2(_timer_xpos,_timer_ypos,_timer_str,_timer_color);
            wtext(_progress_xpos,_progress_ypos,_progress_str,_progress_color);
            wtext(_pos_str_xpos,_pos_str_ypos,_position_str2+'  ',_pos_str_color);
            wtext2(_fname_xpos,_fname_ypos,ExpStrR(NameOnly(songdata_source),12,' '),_fname_color);
            wtext(_pos_str_xpos,_pos_str_ypos,ExpStrR('Loading...',35,' '),_pos_str_color);
            For temp := 1 to 10 do WaitRetrace;

            limit_exceeded := FALSE;
            load_flag := BYTE_NULL;
            _decay_bars_initialized := FALSE;
//            If _gfx_mode then decay_bars_refresh;

            a2m_file_loader;
            If (load_flag = BYTE_NULL) then a2t_file_loader;
            If (load_flag = BYTE_NULL) then amd_file_loader;
            If (load_flag = BYTE_NULL) then cff_file_loader;
            If (load_flag = BYTE_NULL) then dfm_file_loader;
            If (load_flag = BYTE_NULL) then mtk_file_loader;
            If (load_flag = BYTE_NULL) then rad_file_loader;
            If (load_flag = BYTE_NULL) then s3m_file_loader;
            If (load_flag = BYTE_NULL) then fmk_file_loader;
            If (load_flag = BYTE_NULL) then sat_file_loader;
            If (load_flag = BYTE_NULL) then sa2_file_loader;
            If (load_flag = BYTE_NULL) then hsc_file_loader;
            If (load_flag = BYTE_NULL) or
               (load_flag = $7f) then
              begin
                CWriteLn(DietStr(ExpStrR('ERROR(3) - Invalid module ('+songdata_source+')',
                                         PRED(MaxCol),' '),
                                 PRED(MaxCol)),$07,0);
                CWriteLn('',$07,0);
                FindNext(dirinfo);
                CONTINUE;
              end;

            last_order := 0;
            entries := 0;
            If limit_exceeded then
              begin
                CWriteLn(DietStr(ExpStrR('ERROR(1) - Insufficient memory!',
                                         PRED(MaxCol),' '),
                         PRED(MaxCol)),$07,0);
                CWriteLn('',$07,0);
                FindNext(dirinfo);
                CONTINUE;
              end;

            count_order(entries);
            correction := calc_following_order(0);
            entries2 := entries;
            If (correction <> -1) then Dec(entries,correction)
            else entries := 0;
            CWriteLn(DietStr(ExpStrR('Playing '+modname[load_flag]+' "'+
                                     songdata_source+'"',
                                     PRED(MaxCol),' '),
                             PRED(MaxCol)),$07,0);
            temp2 := PRED(WhereY);

            If (entries = 0) then
              begin
                If NOT _picture_mode then GotoXY(1,temp2);
                CWriteLn(DietStr(ExpStrR('Playing '+modname[load_flag]+' "'+
                                         songdata_source+'"',
                                         PRED(MaxCol),' '),
                                 PRED(MaxCol)),$08,0);
                CWriteLn(DietStr(ExpStrR(''+NameOnly(songdata_source)+' [stopped] ['+
                                         ExpStrL(Num2str(TRUNC(time_playing) DIV 60,10),2,'0')+
                                         ':'+ExpStrL(Num2str(TRUNC(time_playing) MOD 60,10),2,'0')+']',
                                         PRED(MaxCol),' '),
                                 PRED(MaxCol)),$07,0);
                CWriteLn('',$07,0);
                FindNext(dirinfo);
                CONTINUE;
              end;

            start_playing;
            set_overall_volume(63);

            Repeat
              If (overall_volume = 63) then
                C3Write(DietStr(_position_str+'  ',PRED(MaxCol)),$0f,0,0);
              wtext2(_timer_xpos,_timer_ypos,_timer_str,_timer_color);
              wtext(_progress_xpos,_progress_ypos,_progress_str,_progress_color);
              wtext(_pos_str_xpos,_pos_str_ypos,_position_str2+'  ',_pos_str_color);

              If (inportb($60) = $39) { SPACE pressed } then
                begin
                  If (overall_volume > 32) then
                    For temp := 63 downto 32 do
                      begin
                        set_overall_volume(temp);
                        delay_counter := 0;
                        While (delay_counter < overall_volume DIV 20) do
                          begin
                            If timer_200hz_flag then
                              begin
                                timer_200hz_flag := FALSE;
                                Inc(delay_counter);
                                C3Write(DietStr(_position_str+'',PRED(MaxCol)),$0f,0,0);
                                wtext2(_timer_xpos,_timer_ypos,_timer_str,_timer_color);
                                wtext(_progress_xpos,_progress_ypos,_progress_str,_progress_color);
                                wtext(_pos_str_xpos,_pos_str_ypos,_position_str2+'',_pos_str_color);
                                If timer_50hz_flag then
                                  begin
                                    timer_50hz_flag := FALSE;
                                    If NOT fast_forward then
                                      decay_bars_refresh;
                                  end;
                              end;
                            MEMW[0:$041c] := MEMW[0:$041a];
                          end;
                      end
                  else begin
                         If timer_200hz_flag then
                           begin
                             timer_200hz_flag := FALSE;
                             C3Write(DietStr(_position_str+'',PRED(MaxCol)),$0f,0,0);
                             wtext2(_timer_xpos,_timer_ypos,_timer_str,_timer_color);
                             wtext(_progress_xpos,_progress_ypos,_progress_str,_progress_color);
                             wtext(_pos_str_xpos,_pos_str_ypos,_position_str2+'',_pos_str_color);
                             If timer_50hz_flag then
                               begin
                                 timer_50hz_flag := FALSE;
                                 If NOT fast_forward then
                                   decay_bars_refresh;
                               end;
                           end;
                         MEMW[0:$041c] := MEMW[0:$041a];
                       end;
                  fast_forward := TRUE;
                end
              else If (inportb($60) = $0b9) { SPACE released } then
                     begin
                       fast_forward := FALSE;
                       If (overall_volume < 63) then
                         For temp := 32 to 63 do
                           begin
                             set_overall_volume(temp);
                             delay_counter := 0;
                             While (delay_counter < overall_volume DIV 20) do
                               begin
                                 If (timer_200hz_counter = 0) then
                                   begin
                                     Inc(delay_counter);
                                     C3Write(DietStr(_position_str+'  ',PRED(MaxCol)),$0f,0,0);
                                     wtext2(_timer_xpos,_timer_ypos,_timer_str,_timer_color);
                                     wtext(_progress_xpos,_progress_ypos,_progress_str,_progress_color);
                                     wtext(_pos_str_xpos,_pos_str_ypos,_position_str2+'  ',_pos_str_color);
                                     If timer_50hz_flag then
                                       begin
                                         timer_50hz_flag := FALSE;
                                         decay_bars_refresh;
                                       end;
                                   end;
                                 MEMW[0:$041c] := MEMW[0:$041a];
                               end;
                           end;
                     end;

              If (NOT fast_forward and timer_50hz_flag) or
                 (fast_forward and timer_20hz_flag) then
                begin
                  If NOT fast_forward then timer_50hz_flag := FALSE
                  else timer_20hz_flag := FALSE;
                  decay_bars_refresh;
                end;

              If NOT keypressed then fkey := WORD_NULL
              else asm
                       xor      ax,ax
                       int      16h
                       mov      fkey,ax
                   end;

              MEMW[0:$041c] := MEMW[0:$041a];
              If jukebox and (last_order <> current_order) then
                begin
                  If (last_order > current_order) and
                     (last_order = PRED(entries2)) then BREAK
                  else last_order := current_order;
                end;

              If (fkey = kBkSPC) then
                begin
                  fade_out;
                  stop_playing;
                  set_overall_volume(63);
                  start_playing;
                end;
            until (fkey = kENTER) or
                  (fkey = kESC);

            fade_out;
            stop_playing;
            If NOT _picture_mode then GotoXY(1,temp2);
            CWriteLn(DietStr(ExpStrR('Playing '+modname[load_flag]+' "'+
                                     songdata_source+'"',
                                     PRED(MaxCol),' '),
                             PRED(MaxCol)),$08,0);
            CWriteLn(DietStr(ExpStrR(''+NameOnly(songdata_source)+' [stopped] ['+
                                     ExpStrL(Num2str(TRUNC(time_playing) DIV 60,10),2,'0')+
                                     ':'+ExpStrL(Num2str(TRUNC(time_playing) MOD 60,10),2,'0')+']',
                                     PRED(MaxCol),' '),
                             PRED(MaxCol)),$07,0);
            CWriteLn('',$07,0);
            If (fkey = kESC) then BREAK;
            FindNext(dirinfo);
          end;
      end;
  until (index = ParamCount);
  done_timer_proc;
end.
