        .386
        .model flat

        .code

        public  _aP_pack
        public  _aP_depack

$L1:    push    ebx
        push    ebp
        push    esi
        push    edi
        mov     edi,[esp+18h]
        xor     eax,eax
        cmp     edi,15
        jbe     short $L2
        mov     edi,15
$L2:    mov     ebp,[esp+1ch]
        mov     esi,[esp+14h]
$L3:    mov     bl,[esi]
        test    bl,bl
        jz      short $L6
        mov     ecx,esi
        mov     edx,edi
        sub     ecx,edi
$L4:    cmp     bl,[ecx]
        jz      short $L5
        dec     edx
        inc     ecx
        test    edx,edx
        jnz     short $L4
$L5:    add     eax,7
        test    edx,edx
        jnz     short $L7
        add     eax,2
        jmp     short $L7
$L6:    add     eax,7
$L7:    inc     esi
        dec     ebp
        jnz     short $L3
        pop     edi
        pop     esi
        pop     ebp
        pop     ebx
        ret
$L8:    mov     edx,[esp+4]
        push    esi
        mov     cl,[edx]
        test    cl,cl
        jz      $L21
        mov     esi,[esp+12]
        cmp     esi,15
        jbe     short $L9
        mov     esi,15
$L9:    mov     eax,edx
        sub     eax,esi
$L10:   cmp     cl,[eax]
        jz      short $L12
        dec     esi
        inc     eax
        test    esi,esi
        jnz     short $L10
$L11:   mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     $L19
        mov     ecx,$D6
        mov     dword ptr $D9,8
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     $L20
$L12:   test    esi,esi
        jz      short $L11
        mov     eax,$D9
        mov     edx,8
        dec     eax
        mov     $D9,eax
        jnz     short $L13
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L14
$L13:   mov     eax,$D8
$L14:   mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L15
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L16
$L15:   mov     eax,$D8
$L16:   mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L17
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L18
$L17:   mov     eax,$D8
$L18:   mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,esi
        and     eax,edx
        push    eax
        call    $L35
        mov     ecx,esi
        and     ecx,4
        push    ecx
        call    $L35
        mov     edx,esi
        and     edx,2
        push    edx
        call    $L35
        and     esi,1
        push    esi
        call    $L35
        add     esp,10h
        pop     esi
        ret
$L19:   mov     eax,$D8
$L20:   mov     cl,[eax]
        pop     esi
        shl     cl,1
        mov     [eax],cl
        mov     ecx,$D6
        mov     al,[edx]
        mov     [ecx],al
        mov     eax,$D6
        inc     eax
        mov     $D6,eax
        ret
$L21:   mov     eax,$D9
        mov     edx,8
        dec     eax
        mov     $D9,eax
        jnz     short $L22
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L23
$L22:   mov     eax,$D8
$L23:   mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L24
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L25
$L24:   mov     eax,$D8
$L25:   mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L26
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L27
$L26:   mov     eax,$D8
$L27:   mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L28
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L29
$L28:   mov     eax,$D8
$L29:   mov     cl,[eax]
        shl     cl,1
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L30
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L31
$L30:   mov     eax,$D8
$L31:   mov     cl,[eax]
        shl     cl,1
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L32
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L33
$L32:   mov     eax,$D8
$L33:   mov     cl,[eax]
        shl     cl,1
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L34
        mov     eax,$D6
        mov     $D9,edx
        mov     ecx,eax
        inc     eax
        mov     $D8,ecx
        mov     $D6,eax
        mov     al,[ecx]
        pop     esi
        shl     al,1
        mov     [ecx],al
        ret
$L34:   mov     ecx,$D8
        pop     esi
        shl     byte ptr [ecx],1
        ret
$L35:   mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L36
        mov     ecx,$D6
        mov     dword ptr $D9,8
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L37
$L36:   mov     eax,$D8
$L37:   mov     ecx,[esp+4]
        test    ecx,ecx
        mov     cl,[eax]
        jz      short $L38
        shl     cl,1
        inc     cl
        mov     [eax],cl
        ret
$L38:   shl     cl,1
        mov     [eax],cl
        ret
$L39:   mov     eax,[esp+4]
        mov     ecx,[esp+8]
        cmp     eax,80h
        jnc     short $L40
        cmp     ecx,4
        jnc     short $L40
        cmp     eax,$D11
        jz      $L75
        neg     eax
        sbb     eax,eax
        and     eax,6
        add     eax,5
        ret
$L40:   cmp     eax,$D11
        jz      $L75
        cmp     eax,80h
        jnc     short $L41
        sub     ecx,2
        jmp     short $L43
$L41:   cmp     eax,500h
        jc      short $L42
        dec     ecx
$L42:   cmp     eax,7d00h
        jc      short $L43
        dec     ecx
$L43:   shr     eax,8
        add     eax,3
        cmp     eax,2
        jnl     short $L44
        mov     edx,64h
        jmp     $L59
$L44:   cmp     eax,4
        jnl     short $L45
        mov     edx,2
        jmp     $L59
$L45:   cmp     eax,8
        jnl     short $L46
        mov     edx,4
        jmp     $L59
$L46:   cmp     eax,10h
        jnl     short $L47
        mov     edx,6
        jmp     $L59
$L47:   cmp     eax,20h
        jnl     short $L48
        mov     edx,8
        jmp     $L59
$L48:   cmp     eax,40h
        jnl     short $L49
        mov     edx,10
        jmp     $L59
$L49:   cmp     eax,80h
        jnl     short $L50
        mov     edx,12
        jmp     $L59
$L50:   cmp     eax,100h
        jnl     short $L51
        mov     edx,14
        jmp     short $L59
$L51:   cmp     eax,200h
        jnl     short $L52
        mov     edx,10h
        jmp     short $L59
$L52:   cmp     eax,400h
        jnl     short $L53
        mov     edx,12h
        jmp     short $L59
$L53:   cmp     eax,800h
        jnl     short $L54
        mov     edx,14h
        jmp     short $L59
$L54:   cmp     eax,1000h
        jnl     short $L55
        mov     edx,16h
        jmp     short $L59
$L55:   cmp     eax,2000h
        jnl     short $L56
        mov     edx,18h
        jmp     short $L59
$L56:   cmp     eax,4000h
        jnl     short $L57
        mov     edx,1ah
        jmp     short $L59
$L57:   cmp     eax,8000h
        jnl     short $L58
        mov     edx,1ch
        jmp     short $L59
$L58:   xor     edx,edx
        cmp     eax,10000h
        setnl   dl
        dec     edx
        and     edx,-2
        add     edx,20h
$L59:   cmp     ecx,2
        jnl     short $L60
        mov     eax,64h
        lea     eax,[eax+edx+10]
        ret
$L60:   cmp     ecx,4
        jnl     short $L61
        mov     eax,2
        lea     eax,[eax+edx+10]
        ret
$L61:   cmp     ecx,8
        jnl     short $L62
        mov     eax,4
        lea     eax,[eax+edx+10]
        ret
$L62:   cmp     ecx,10h
        jnl     short $L63
        mov     eax,6
        lea     eax,[eax+edx+10]
        ret
$L63:   cmp     ecx,20h
        jnl     short $L64
        mov     eax,8
        lea     eax,[eax+edx+10]
        ret
$L64:   cmp     ecx,40h
        jnl     short $L65
        mov     eax,10
        lea     eax,[eax+edx+10]
        ret
$L65:   cmp     ecx,80h
        jnl     short $L66
        mov     eax,12
        lea     eax,[eax+edx+10]
        ret
$L66:   cmp     ecx,100h
        jnl     short $L67
        mov     eax,14
        lea     eax,[eax+edx+10]
        ret
$L67:   cmp     ecx,200h
        jnl     short $L68
        mov     eax,10h
        lea     eax,[eax+edx+10]
        ret
$L68:   cmp     ecx,400h
        jnl     short $L69
        mov     eax,12h
        lea     eax,[eax+edx+10]
        ret
$L69:   cmp     ecx,800h
        jnl     short $L70
        mov     eax,14h
        lea     eax,[eax+edx+10]
        ret
$L70:   cmp     ecx,1000h
        jnl     short $L71
        mov     eax,16h
        lea     eax,[eax+edx+10]
        ret
$L71:   cmp     ecx,2000h
        jnl     short $L72
        mov     eax,18h
        lea     eax,[eax+edx+10]
        ret
$L72:   cmp     ecx,4000h
        jnl     short $L73
        mov     eax,1ah
        lea     eax,[eax+edx+10]
        ret
$L73:   cmp     ecx,8000h
        jnl     short $L74
        mov     eax,1ch
        lea     eax,[eax+edx+10]
        ret
$L74:   xor     eax,eax
        cmp     ecx,10000h
        setnl   al
        dec     eax
        and     al,0feh
        add     eax,20h
        lea     eax,[eax+edx+10]
        ret
$L75:   cmp     ecx,2
        jnl     short $L76
        mov     eax,64h
        add     eax,4
        ret
$L76:   cmp     ecx,4
        jnl     short $L77
        mov     eax,2
        add     eax,4
        ret
$L77:   cmp     ecx,8
        jnl     short $L78
        mov     eax,4
        add     eax,eax
        ret
$L78:   cmp     ecx,10h
        jnl     short $L79
        mov     eax,6
        add     eax,4
        ret
$L79:   cmp     ecx,20h
        jnl     short $L80
        mov     eax,8
        add     eax,4
        ret
$L80:   cmp     ecx,40h
        jnl     short $L81
        mov     eax,10
        add     eax,4
        ret
$L81:   cmp     ecx,80h
        jnl     short $L82
        mov     eax,12
        add     eax,4
        ret
$L82:   cmp     ecx,100h
        jnl     short $L83
        mov     eax,14
        add     eax,4
        ret
$L83:   cmp     ecx,200h
        jnl     short $L84
        mov     eax,10h
        add     eax,4
        ret
$L84:   cmp     ecx,400h
        jnl     short $L85
        mov     eax,12h
        add     eax,4
        ret
$L85:   cmp     ecx,800h
        jnl     short $L86
        mov     eax,14h
        add     eax,4
        ret
$L86:   cmp     ecx,1000h
        jnl     short $L87
        mov     eax,16h
        add     eax,4
        ret
$L87:   cmp     ecx,2000h
        jnl     short $L88
        mov     eax,18h
        add     eax,4
        ret
$L88:   cmp     ecx,4000h
        jnl     short $L89
        mov     eax,1ah
        add     eax,4
        ret
$L89:   cmp     ecx,8000h
        jnl     short $L90
        mov     eax,1ch
        add     eax,4
        ret
$L90:   xor     eax,eax
        cmp     ecx,10000h
        setnl   al
        dec     eax
        and     al,0feh
        add     eax,20h
        add     eax,4
        ret
$L91:   mov     edx,[esp+8]
        push    ebx
        mov     ebx,[esp+8]
        push    esi
        cmp     ebx,80h
        jnb     $L98
        cmp     edx,4
        jnb     $L98
        cmp     ebx,$D11
        jz      $L98
        mov     eax,$D9
        mov     esi,8
        dec     eax
        mov     $D9,eax
        jnz     short $L92
        mov     ecx,$D6
        mov     $D9,esi
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L93
$L92:   mov     eax,$D8
$L93:   mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L94
        mov     ecx,$D6
        mov     $D9,esi
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L95
$L94:   mov     eax,$D8
$L95:   mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L96
        mov     ecx,$D6
        mov     $D9,esi
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L97
$L96:   mov     eax,$D8
$L97:   mov     cl,[eax]
        and     dl,1
        shl     cl,1
        mov     [eax],cl
        mov     ecx,$D6
        mov     al,bl
        pop     esi
        shl     al,1
        add     dl,al
        mov     [ecx],dl
        mov     eax,$D6
        inc     eax
        mov     $D11,ebx
        mov     $D6,eax
        pop     ebx
        ret
$L98:   mov     eax,$D9
        mov     esi,8
        dec     eax
        mov     $D9,eax
        jnz     short $L99
        mov     ecx,$D6
        mov     $D9,esi
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L100
$L99:   mov     eax,$D8
$L100:  mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L101
        mov     ecx,$D6
        mov     $D9,esi
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L102
$L101:  mov     eax,$D8
$L102:  mov     cl,[eax]
        shl     cl,1
        mov     [eax],cl
        mov     eax,$D11
        cmp     ebx,eax
        jz      short $L106
        mov     edx,ebx
        shr     edx,8
        add     edx,3
        push    edx
        call    $L110
        mov     eax,$D6
        add     esp,4
        mov     [eax],bl
        mov     ecx,$D6
        inc     ecx
        cmp     ebx,80h
        mov     $D6,ecx
        mov     $D11,ebx
        jnc     short $L104
        sub     dword ptr [esp+10h],2
$L103:  mov     edx,[esp+10h]
        push    edx
        call    $L110
        add     esp,4
        pop     esi
        pop     ebx
        ret
$L104:  cmp     ebx,500h
        jc      short $L105
        dec     dword ptr [esp+10h]
$L105:  cmp     ebx,7d00h
        jc      short $L103
        mov     eax,[esp+10h]
        dec     eax
        mov     edx,eax
        mov     [esp+10h],eax
        push    edx
        call    $L110
        add     esp,4
        pop     esi
        pop     ebx
        ret
$L106:  mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L107
        mov     ecx,$D6
        mov     $D9,esi
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L108
$L107:  mov     eax,$D8
$L108:  mov     cl,[eax]
        shl     cl,1
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L109
        mov     eax,$D6
        mov     $D9,esi
        mov     ecx,eax
        inc     eax
        mov     $D8,ecx
        mov     $D6,eax
        mov     al,[ecx]
        push    edx
        shl     al,1
        mov     [ecx],al
        call    near ptr $L110
        add     esp,4
        pop     esi
        pop     ebx
        ret
$L109:  mov     ecx,$D8
        push    edx
        shl     byte ptr [ecx],1
        call    near ptr $L110
        add     esp,4
        pop     esi
        pop     ebx
        ret
$L110:  mov     eax,[esp+4]
        push    esi
        mov     esi,[esp+8]
        xor     ecx,ecx
$L111:  mov     edx,eax
        and     edx,1
        inc     ecx
        shr     eax,1
        cmp     eax,1
        lea     esi,[edx+esi*2]
        jnbe    short $L111
        dec     ecx
        jz      short $L115
        push    edi
        mov     edi,ecx
$L112:  mov     eax,esi
        and     eax,1
        push    eax
        call    $L35
        mov     eax,$D9
        add     esp,4
        dec     eax
        mov     $D9,eax
        jnz     short $L113
        mov     ecx,$D6
        mov     dword ptr $D9,8
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L114
$L113:  mov     eax,$D8
$L114:  mov     cl,[eax]
        shl     cl,1
        inc     cl
        shr     esi,1
        dec     edi
        mov     [eax],cl
        jnz     short $L112
        pop     edi
$L115:  and     esi,1
        push    esi
        call    $L35
        mov     eax,$D9
        add     esp,4
        dec     eax
        mov     $D9,eax
        pop     esi
        jnz     short $L116
        mov     ecx,$D6
        mov     dword ptr $D9,8
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        shl     byte ptr [eax],1
        ret
$L116:  mov     eax,$D8
        shl     byte ptr [eax],1
        ret
$L117:  sub     esp,12
        mov     ecx,$D3
        mov     edx,$D5
        xor     eax,eax
        push    ebx
        mov     ebx,[esp+18h]
        mov     [esp+4],eax
        mov     [esp+8],eax
        mov     eax,$D4
        push    ebp
        push    esi
        cmp     eax,ebx
        push    edi
        jnb     $L123
$L118:  lea     esi,[ecx+16800h]
        cmp     esi,ecx
        jbe     short $L120
        cmp     ecx,edx
        jbe     short $L119
        sub     ecx,edx
        jmp     short $L121
$L119:  sub     ecx,edx
        add     ecx,16800h
        jmp     short $L121
$L120:  xor     ecx,ecx
$L121:  xor     edx,edx
        mov     dl,[eax]
        mov     esi,edx
        xor     edx,edx
        mov     dl,[eax+1]
        mov     eax,dword ptr $D2[esi*4]
        mov     edx,[eax+edx*4]
        mov     eax,$D1
        mov     [eax+ecx*4],edx
        mov     eax,$D4
        xor     ecx,ecx
        xor     edx,edx
        mov     cl,[eax]
        mov     dl,[eax+1]
        mov     eax,dword ptr $D2[ecx*4]
        mov     ecx,$D3
        mov     [eax+edx*4],ecx
        mov     ecx,$D3
        mov     edx,$D5
        mov     eax,$D4
        inc     ecx
        inc     eax
        mov     esi,ecx
        mov     $D3,ecx
        sub     esi,edx
        mov     $D4,eax
        cmp     esi,16800h
        jbe     short $L122
        lea     edx,[ecx-1]
        mov     $D5,edx
$L122:  cmp     eax,ebx
        jb      $L118
$L123:  mov     esi,[esp+2ch]
        mov     eax,16700h
        cmp     esi,eax
        jbe     short $L124
        mov     [esp+2ch],eax
$L124:  xor     eax,eax
        mov     al,[ebx]
        mov     esi,eax
        xor     eax,eax
        mov     al,[ebx+1]
        mov     esi,dword ptr $D2[esi*4]
        mov     esi,[esi+eax*4]
        test    esi,esi
        jz      $L147
        cmp     dword ptr [esp+2ch],1
        jbe     $L147
        mov     edi,$D10
        mov     ebp,$D1
        mov     dword ptr [esp+18h],800h
        lea     eax,[edi+esi]
        cmp     eax,ebx
        jc      short $L129
$L125:  test    esi,esi
        jz      short $L129
        lea     eax,[esi+16800h]
        cmp     eax,ecx
        jbe     short $L127
        cmp     esi,edx
        jbe     short $L126
        sub     esi,edx
        jmp     short $L128
$L126:  sub     esi,edx
        add     esi,16800h
        jmp     short $L128
$L127:  xor     esi,esi
$L128:  mov     esi,[ebp+esi*4]
        lea     eax,[edi+esi]
        cmp     eax,ebx
        jnc     short $L125
$L129:  mov     edx,[esp+28h]
        mov     ecx,16700h
        cmp     edx,ecx
        jbe     short $L130
        mov     [esp+28h],ecx
$L130:  test    esi,esi
        jz      $L147
$L131:  mov     ecx,[esp+28h]
        mov     ebp,ebx
        sub     ebp,eax
        cmp     ebp,ecx
        jnbe    $L147
        mov     ecx,[esp+10h]
        mov     edi,2
        mov     dl,[eax+ecx]
        cmp     dl,[ecx+ebx]
        jz      short $L135
        cmp     ebp,$D11
        jz      short $L135
        mov     ecx,$D3
        lea     eax,[esi+16800h]
        cmp     eax,ecx
        jbe     short $L133
        mov     eax,$D5
        cmp     esi,eax
        jbe     short $L132
        sub     esi,eax
        jmp     short $L134
$L132:  sub     esi,eax
        add     esi,16800h
        jmp     short $L134
$L133:  xor     esi,esi
$L134:  mov     ecx,$D1
        mov     edx,$D10
        mov     esi,[ecx+esi*4]
        mov     ecx,[esp+18h]
        dec     ecx
        lea     eax,[edx+esi]
        mov     [esp+18h],ecx
        jz      $L147
        jmp     $L145
$L135:  mov     dl,[eax+2]
        lea     ecx,[ebx+2]
        cmp     dl,[ecx]
        jnz     short $L137
        sub     eax,ebx
$L136:  cmp     edi,[esp+2ch]
        jnc     short $L137
        mov     dl,[eax+ecx+1]
        inc     edi
        inc     ecx
        cmp     dl,[ecx]
        jz      short $L136
$L137:  cmp     edi,[esp+2ch]
        jz      $L146
        cmp     edi,[esp+10h]
        jbe     short $L138
        push    edi
        push    ebp
        call    $L39
        mov     ecx,[esp+1ch]
        mov     ebx,eax
        mov     eax,[esp+18h]
        push    eax
        push    ecx
        call    $L39
        sub     ebx,eax
        mov     eax,4ec4ec4fh
        shl     ebx,1
        imul    ebx
        mov     ecx,[esp+20h]
        add     esp,10h
        sar     edx,2
        mov     eax,edx
        shr     eax,1fh
        add     edx,eax
        add     edx,ecx
        cmp     edi,edx
        jnbe    short $L139
        mov     ebx,[esp+24h]
$L138:  cmp     ebp,$D11
        jnz     short $L141
        push    edi
        push    ebp
        call    $L39
        mov     ecx,[esp+18h]
        mov     edx,[esp+1ch]
        push    ecx
        push    edx
        mov     ebx,eax
        call    $L39
        mov     ecx,eax
        mov     eax,2aaaaaabh
        sub     ecx,ebx
        add     esp,10h
        imul    ecx
        mov     eax,edx
        shr     eax,1fh
        add     edx,eax
        mov     eax,[esp+10h]
        add     edx,edi
        cmp     edx,eax
        jc      short $L140
$L139:  mov     [esp+14h],ebp
        mov     [esp+10h],edi
$L140:  mov     ebx,[esp+24h]
$L141:  mov     eax,$D3
        lea     ecx,[esi+16800h]
        cmp     ecx,eax
        jbe     short $L143
        mov     eax,$D5
        cmp     esi,eax
        jbe     short $L142
        sub     esi,eax
        jmp     short $L144
$L142:  sub     esi,eax
        add     esi,16800h
        jmp     short $L144
$L143:  xor     esi,esi
$L144:  mov     edx,$D1
        mov     eax,$D10
        mov     ecx,[esp+18h]
        mov     esi,[edx+esi*4]
        add     eax,esi
        dec     ecx
        mov     [esp+18h],ecx
        jz      short $L147
$L145:  test    esi,esi
        jz      short $L147
        jmp     $L131
$L146:  mov     [esp+14h],ebp
        mov     [esp+10h],edi
$L147:  mov     eax,[esp+20h]
        mov     ecx,[esp+10h]
        mov     edx,[esp+14h]
        pop     edi
        pop     esi
        pop     ebp
        mov     [eax+4],ecx
        mov     [eax],edx
        pop     ebx
        add     esp,12
        ret
_ap_pack:
        mov     eax,[esp+4]
        sub     esp,2ch
        push    ebx
        push    ebp
        push    esi
        xor     esi,esi
        cmp     eax,esi
        push    edi
        jnz     short $L148
        pop     edi
        pop     esi
        pop     ebp
        xor     eax,eax
        pop     ebx
        add     esp,2ch
        ret
$L148:  mov     ecx,[esp+44h]
        cmp     ecx,esi
        jnz     short $L149
        pop     edi
        pop     esi
        pop     ebp
        xor     eax,eax
        pop     ebx
        add     esp,2ch
        ret
$L149:  mov     ebp,[esp+48h]
        cmp     ebp,2
        jnc     short $L150
        pop     edi
        pop     esi
        pop     ebp
        xor     eax,eax
        pop     ebx
        add     esp,2ch
        ret
$L150:  mov     edx,[esp+4ch]
        cmp     edx,esi
        jnz     short $L151
        pop     edi
        pop     esi
        pop     ebp
        xor     eax,eax
        pop     ebx
        add     esp,2ch
        ret
$L151:  mov     $D7,eax
        dec     eax
        mov     $D10,eax
        mov     $D6,ecx
        mov     $D1,edx
        mov     ecx,offset $D2
        add     edx,5a018h
$L152:  mov     [ecx],edx
        xor     eax,eax
$L153:  mov     edi,[ecx]
        add     eax,4
        cmp     eax,400h
        mov     [eax+edi-4],esi
        jc      short $L153
        add     ecx,4
        add     edx,400h
        cmp     ecx,offset $D3
        jc      short $L152
        mov     ecx,$D7
        mov     edx,$D1
        or      eax,-1
        mov     edi,1
        mov     $D11,eax
        mov     $D3,edi
        mov     $D5,esi
        mov     $D4,ecx
        mov     [edx],esi
        mov     ecx,$D7
        mov     [esp+4ch],esi
        mov     [esp+14h],esi
        mov     dl,[ecx]
        mov     ecx,$D6
        mov     [esp+18h],eax
        mov     [ecx],dl
        mov     edx,$D7
        mov     ecx,$D6
        inc     edx
        inc     ecx
        cmp     ebp,edi
        mov     $D7,edx
        mov     $D6,ecx
        mov     $D9,edi
        jbe     $L216
        jmp     short $L155
$L154:  mov     edx,$D7
        mov     ecx,$D6
$L155:  mov     eax,[esp+50h]
        test    eax,eax
        jz      short $L156
        mov     ebx,[esp+14h]
        inc     ebx
        test    bl,7fh
        mov     [esp+14h],ebx
        jnz     short $L156
        mov     ebp,[esp+44h]
        sub     ecx,ebp
        mov     ebp,[esp+40h]
        sub     edx,ebp
        push    ecx
        push    edx
        call    eax
        add     esp,8
        test    eax,eax
        jz      $L223
$L156:  cmp     edi,[esp+18h]
        jnz     short $L157
        mov     eax,[esp+38h]
        mov     edx,[esp+34h]
        mov     [esp+20h],eax
        mov     [esp+1ch],edx
        jmp     short $L158
$L157:  mov     eax,[esp+48h]
        mov     ecx,$D7
        sub     eax,edi
        lea     edx,[esp+1ch]
        push    eax
        push    edi
        push    ecx
        push    edx
        call    $L117
        mov     eax,[esp+30h]
        add     esp,10h
$L158:  cmp     eax,2
        jl      $L199
        mov     ecx,$D11
        mov     edx,[esp+1ch]
        cmp     edx,ecx
        mov     dword ptr [esp+10h],0
        jnz     short $L160
        cmp     esi,1
        jbe     $L180
        cmp     [esp+2ch],ecx
        jz      $L180
        mov     eax,[esp+4ch]
        push    esi
        push    edi
        push    eax
        call    $L1
        mov     ebx,[esp+38h]
        push    esi
        push    ebx
        mov     ebp,eax
        call    $L39
        add     esp,14h
        cmp     eax,ebp
        jnl     $L179
        cmp     ebx,500h
        jl      short $L159
        cmp     esi,2
        jz      $L179
$L159:  cmp     ebx,7d00h
        jl      short $L160
        cmp     esi,3
        jz      $L179
$L160:  mov     ebp,[esp+48h]
        mov     edx,$D7
        sub     ebp,edi
        lea     ebx,[edi+1]
        inc     edx
        lea     eax,[esp+34h]
        lea     ecx,[ebp-1]
        push    ecx
        push    ebx
        push    edx
        push    eax
        call    $L117
        mov     eax,[esp+44h]
        mov     ecx,[esp+2ch]
        add     esp,10h
        cmp     eax,ecx
        mov     [esp+18h],ebx
        jl      short $L161
        mov     ecx,[esp+38h]
        push    ecx
        push    eax
        call    $L39
        mov     edx,[esp+28h]
        mov     ebx,eax
        mov     eax,[esp+24h]
        push    edx
        push    eax
        call    $L39
        mov     ecx,eax
        mov     eax,38e38e39h
        sub     ecx,ebx
        add     esp,10h
        shl     ecx,1
        imul    ecx
        sar     edx,1
        mov     eax,[esp+20h]
        mov     ecx,edx
        shr     ecx,1fh
        add     edx,ecx
        mov     ecx,[esp+38h]
        add     edx,ecx
        cmp     eax,edx
        jnl     short $L163
        jmp     short $L162
$L161:  mov     edx,[esp+38h]
        push    edx
        push    eax
        call    $L39
        mov     ecx,[esp+24h]
        mov     ebx,eax
        mov     eax,[esp+28h]
        push    eax
        push    ecx
        call    $L39
        sub     eax,ebx
        mov     ecx,[esp+48h]
        cwd
        and     edx,3
        add     esp,10h
        add     edx,eax
        mov     eax,[esp+20h]
        sar     edx,2
        add     edx,ecx
        cmp     eax,edx
        jnl     short $L163
$L162:  mov     dword ptr [esp+10h],1
$L163:  test    esi,esi
        jbe     short $L166
        cmp     ecx,eax
        jl      short $L165
        mov     eax,[esp+34h]
        push    ecx
        push    eax
        call    $L39
        mov     ecx,[esp+28h]
        mov     edx,[esp+24h]
        push    ecx
        push    edx
        mov     ebx,eax
        call    $L39
        add     esp,10h
        cmp     ebx,eax
        jnl     short $L164
        mov     dword ptr [esp+10h],1
$L164:  mov     eax,[esp+20h]
$L165:  test    esi,esi
$L166:  jnz     short $L168
        cmp     [esp+38h],eax
        jnl     short $L168
        mov     eax,$D7
        push    +1
        push    edi
        push    eax
        call    $L1
        mov     ecx,[esp+44h]
        mov     edx,[esp+40h]
        push    ecx
        push    edx
        mov     ebx,eax
        call    $L39
        mov     ecx,[esp+30h]
        lea     ebx,[ebx+eax+1]
        mov     eax,[esp+34h]
        push    eax
        push    ecx
        call    $L39
        add     esp,1ch
        cmp     ebx,eax
        jng     short $L167
        mov     eax,[esp+20h]
        mov     dword ptr [esp+10h],0
        jmp     short $L169
$L167:  mov     eax,[esp+20h]
$L168:  mov     ecx,[esp+10h]
        test    ecx,ecx
        jnz     $L197
$L169:  cmp     eax,2
        jle     $L180
        mov     ecx,$D7
        lea     edx,[ebp-2]
        lea     eax,[edi+2]
        push    edx
        add     ecx,2
        push    eax
        lea     edx,[esp+2ch]
        push    ecx
        push    edx
        call    $L117
        mov     eax,[esp+34h]
        mov     ecx,[esp+2ch]
        add     esp,10h
        cmp     eax,ecx
        mov     ecx,[esp+28h]
        push    ecx
        push    eax
        jl      short $L170
        call    $L39
        mov     edx,[esp+28h]
        mov     ebx,eax
        mov     eax,[esp+24h]
        push    edx
        push    eax
        call    $L39
        sub     eax,ebx
        add     esp,10h
        cwd
        and     edx,3
        add     edx,eax
        sar     edx,2
        jmp     short $L171
$L170:  call    $L39
        mov     edx,[esp+28h]
        mov     ebx,eax
        mov     eax,[esp+24h]
        push    edx
        push    eax
        call    $L39
        mov     ecx,eax
        mov     eax,2e8ba2e9h
        sub     ecx,ebx
        add     esp,10h
        shl     ecx,1
        imul    ecx
        sar     edx,1
        mov     ecx,edx
        shr     ecx,1fh
        add     edx,ecx
$L171:  mov     ecx,[esp+28h]
        mov     eax,[esp+20h]
        add     edx,ecx
        cmp     eax,edx
        jnl     short $L172
        mov     ebx,1
        mov     [esp+10h],ebx
        jmp     short $L173
$L172:  mov     ebx,[esp+10h]
$L173:  test    esi,esi
        jbe     short $L174
        cmp     ecx,eax
        jl      short $L174
        mov     edx,[esp+24h]
        push    ecx
        push    edx
        call    $L39
        mov     ecx,[esp+24h]
        mov     ebx,eax
        mov     eax,[esp+28h]
        push    eax
        push    ecx
        call    $L39
        add     esp,10h
        cmp     ebx,eax
        jl      $L196
        mov     eax,[esp+20h]
        mov     ebx,[esp+10h]
$L174:  test    ebx,ebx
        jnz     $L197
        cmp     eax,3
        jle     $L180
        mov     eax,$D7
        add     ebp,-3
        lea     edx,[edi+3]
        push    ebp
        add     eax,3
        push    edx
        lea     ecx,[esp+2ch]
        push    eax
        push    ecx
        call    $L117
        mov     eax,[esp+34h]
        mov     ecx,[esp+2ch]
        add     esp,10h
        cmp     eax,ecx
        jl      short $L175
        mov     edx,[esp+28h]
        push    edx
        push    eax
        call    $L39
        mov     ecx,[esp+24h]
        mov     ebp,eax
        mov     eax,[esp+28h]
        push    eax
        push    ecx
        call    $L39
        sub     eax,ebp
        mov     ecx,[esp+38h]
        cwd
        and     edx,3
        add     esp,10h
        add     edx,eax
        mov     eax,[esp+20h]
        sar     edx,2
        add     edx,ecx
        cmp     eax,edx
        jnl     short $L177
        jmp     short $L176
$L175:  mov     ecx,[esp+28h]
        push    ecx
        push    eax
        call    $L39
        mov     edx,[esp+28h]
        mov     ebp,eax
        mov     eax,[esp+24h]
        push    edx
        push    eax
        call    $L39
        mov     ecx,eax
        mov     eax,2e8ba2e9h
        sub     ecx,ebp
        add     esp,10h
        shl     ecx,1
        imul    ecx
        sar     edx,1
        mov     eax,[esp+20h]
        mov     ecx,edx
        shr     ecx,1fh
        add     edx,ecx
        mov     ecx,[esp+28h]
        add     edx,ecx
        cmp     eax,edx
        jnl     short $L177
$L176:  mov     ebx,1
$L177:  test    esi,esi
        jbe     short $L178
        cmp     ecx,eax
        jl      short $L178
        mov     edx,[esp+24h]
        push    ecx
        push    edx
        call    $L39
        mov     ecx,[esp+24h]
        mov     ebp,eax
        mov     eax,[esp+28h]
        push    eax
        push    ecx
        call    $L39
        add     esp,10h
        cmp     ebp,eax
        jl      $L196
        mov     eax,[esp+20h]
$L178:  test    ebx,ebx
        jnz     $L197
        jmp     short $L180
$L179:  mov     eax,[esp+20h]
$L180:  test    esi,esi
        jz      $L188
        cmp     esi,1
        jbe     $L187
        mov     eax,[esp+48h]
        mov     edx,esi
        sub     edx,edi
        add     eax,edx
        cmp     eax,esi
        jbe     short $L181
        mov     eax,esi
$L181:  mov     ebx,[esp+4ch]
        mov     ecx,edi
        sub     ecx,esi
        push    eax
        push    ecx
        lea     edx,[esp+2ch]
        push    ebx
        push    edx
        call    $L117
        mov     eax,[esp+38h]
        add     esp,10h
        cmp     eax,esi
        jc      short $L182
        mov     eax,[esp+24h]
        push    esi
        push    eax
        call    $L39
        mov     ecx,[esp+34h]
        push    esi
        push    ecx
        mov     ebp,eax
        call    $L39
        add     esp,10h
        cmp     eax,ebp
        jng     short $L182
        mov     edx,[esp+24h]
        mov     eax,[esp+28h]
        mov     [esp+2ch],edx
        mov     [esp+30h],eax
$L182:  push    esi
        push    edi
        push    ebx
        call    $L1
        mov     ecx,[esp+38h]
        push    esi
        push    ecx
        mov     ebp,eax
        call    $L39
        add     esp,14h
        cmp     eax,ebp
        jnl     $L186
        mov     edx,[esp+1ch]
        mov     eax,$D11
        cmp     edx,eax
        jnz     short $L183
        push    esi
        push    edi
        push    ebx
        call    $L1
        mov     ecx,[esp+28h]
        mov     ebx,eax
        mov     eax,[esp+2ch]
        push    eax
        push    ecx
        call    $L39
        mov     edx,[esp+34h]
        add     ebx,eax
        mov     eax,[esp+30h]
        push    edx
        inc     eax
        push    eax
        call    $L39
        mov     ecx,[esp+48h]
        push    esi
        push    ecx
        mov     ebp,eax
        call    $L39
        add     ebp,eax
        add     esp,24h
        cmp     ebx,ebp
        mov     ebx,[esp+4ch]
        jng     short $L186
$L183:  mov     eax,[esp+2ch]
        mov     ecx,$D11
        cmp     eax,ecx
        jz      short $L185
        cmp     eax,500h
        jl      short $L184
        cmp     esi,2
        jz      short $L186
$L184:  cmp     eax,7d00h
        jl      short $L185
        cmp     esi,3
        jz      short $L186
$L185:  push    esi
        push    eax
        call    $L91
        mov     eax,[esp+28h]
        add     esp,8
        xor     esi,esi
        jmp     short $L189
$L186:  push    edi
        push    ebx
        call    $L8
        add     esp,8
        inc     ebx
        dec     esi
        jnz     short $L186
        mov     eax,[esp+20h]
        mov     [esp+4ch],ebx
        jmp     short $L189
$L187:  mov     ebx,[esp+4ch]
        push    edi
        push    ebx
        call    $L8
        mov     eax,[esp+28h]
        add     esp,8
        xor     esi,esi
        jmp     short $L189
$L188:  mov     ebx,[esp+4ch]
$L189:  cmp     eax,3
        jg      short $L194
        mov     edx,$D7
        push    eax
        push    edi
        push    edx
        call    $L1
        mov     ecx,[esp+28h]
        mov     ebp,eax
        mov     eax,[esp+2ch]
        push    eax
        push    ecx
        call    $L39
        add     esp,14h
        cmp     eax,ebp
        mov     eax,[esp+20h]
        jg      short $L191
        mov     ecx,[esp+1ch]
        mov     edx,$D11
        cmp     ecx,edx
        jz      short $L195
        cmp     ecx,500h
        jl      short $L190
        cmp     eax,2
        jz      short $L191
$L190:  cmp     ecx,7d00h
        jl      short $L195
$L191:  test    eax,eax
        jz      short $L193
        mov     ebx,eax
$L192:  mov     edx,$D7
        push    edi
        push    edx
        call    $L8
        mov     ecx,$D7
        add     esp,8
        inc     ecx
        dec     ebx
        mov     $D7,ecx
        jnz     short $L192
        mov     eax,[esp+20h]
$L193:  lea     edi,[edi+eax-1]
        jmp     short $L202
$L194:  mov     ecx,[esp+1ch]
$L195:  push    eax
        push    ecx
        call    $L91
        mov     eax,[esp+28h]
        mov     ecx,$D7
        add     esp,8
        add     ecx,eax
        mov     $D7,ecx
        lea     edi,[edi+eax-1]
        jmp     short $L203
$L196:  mov     eax,[esp+20h]
$L197:  test    esi,esi
        jnz     short $L198
        mov     ebx,$D7
        mov     [esp+30h],eax
        mov     eax,[esp+1ch]
        inc     esi
        mov     [esp+2ch],eax
        mov     eax,ebx
        inc     eax
        mov     [esp+4ch],ebx
        mov     $D7,eax
        jmp     short $L203
$L198:  mov     eax,$D7
        mov     ebx,[esp+4ch]
        inc     esi
        inc     eax
        mov     $D7,eax
        jmp     short $L203
$L199:  test    esi,esi
        jz      short $L200
        inc     esi
        jmp     short $L201
$L200:  mov     ecx,$D7
        push    edi
        push    ecx
        call    $L8
        add     esp,8
$L201:  inc     dword ptr $D7
$L202:  mov     ebx,[esp+4ch]
$L203:  test    esi,esi
        jz      $L209
        cmp     esi,[esp+30h]
        jnz     $L209
        mov     eax,[esp+48h]
        mov     edx,esi
        sub     edx,edi
        add     eax,edx
        cmp     eax,esi
        jbe     short $L204
        mov     eax,esi
$L204:  mov     ecx,edi
        push    eax
        sub     ecx,esi
        lea     edx,[esp+28h]
        push    ecx
        push    ebx
        push    edx
        call    $L117
        mov     eax,[esp+38h]
        add     esp,10h
        cmp     eax,esi
        jc      short $L205
        mov     eax,[esp+24h]
        push    esi
        push    eax
        call    $L39
        mov     ecx,[esp+34h]
        push    esi
        push    ecx
        mov     ebp,eax
        call    $L39
        add     esp,10h
        cmp     eax,ebp
        jng     short $L205
        mov     edx,[esp+24h]
        mov     eax,[esp+28h]
        mov     [esp+2ch],edx
        mov     [esp+30h],eax
$L205:  push    esi
        push    edi
        push    ebx
        call    $L1
        mov     ecx,[esp+38h]
        push    esi
        push    ecx
        mov     ebp,eax
        call    $L39
        add     esp,14h
        cmp     eax,ebp
        jnl     short $L208
        mov     eax,[esp+2ch]
        mov     ecx,$D11
        cmp     eax,ecx
        jz      short $L207
        cmp     eax,500h
        jl      short $L206
        cmp     esi,2
        jz      short $L208
$L206:  cmp     eax,7d00h
        jl      short $L207
        cmp     esi,3
        jz      short $L208
$L207:  push    esi
        push    eax
        call    $L91
        add     esp,8
        xor     esi,esi
        jmp     short $L209
$L208:  push    edi
        push    ebx
        call    $L8
        add     esp,8
        inc     ebx
        dec     esi
        mov     [esp+4ch],ebx
        jnz     short $L208
$L209:  mov     eax,[esp+48h]
        inc     edi
        cmp     edi,eax
        jb      $L154
        test    esi,esi
        jz      short $L216
        cmp     esi,1
        jbe     short $L214
        mov     ebx,[esp+4ch]
        push    esi
        push    edi
        push    ebx
        call    $L1
        mov     edx,[esp+38h]
        push    esi
        push    edx
        mov     ebp,eax
        call    $L39
        add     esp,14h
        cmp     eax,ebp
        jg      short $L212
        mov     eax,[esp+2ch]
        mov     ecx,$D11
        cmp     eax,ecx
        jz      short $L211
        cmp     eax,500h
        jl      short $L210
        cmp     esi,2
        jz      short $L212
$L210:  cmp     eax,7d00h
        jl      short $L211
        cmp     esi,3
        jz      short $L212
$L211:  push    esi
        push    eax
        call    $L91
        jmp     short $L215
$L212:  test    esi,esi
        jbe     short $L216
$L213:  push    edi
        push    ebx
        call    $L8
        add     esp,8
        inc     ebx
        dec     esi
        jnz     short $L213
        jmp     short $L216
$L214:  mov     eax,[esp+4ch]
        push    edi
        push    eax
        call    $L8
$L215:  add     esp,8
$L216:  mov     eax,$D9
        mov     edx,8
        dec     eax
        mov     $D9,eax
        jnz     short $L217
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L218
$L217:  mov     eax,$D8
$L218:  mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L219
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L220
$L219:  mov     eax,$D8
$L220:  mov     cl,[eax]
        shl     cl,1
        inc     cl
        mov     [eax],cl
        mov     eax,$D9
        dec     eax
        mov     $D9,eax
        jnz     short $L221
        mov     ecx,$D6
        mov     $D9,edx
        mov     eax,ecx
        inc     ecx
        mov     $D8,eax
        mov     $D6,ecx
        jmp     short $L222
$L221:  mov     eax,$D8
$L222:  mov     bl,[eax]
        shl     bl,1
        mov     [eax],bl
        mov     edx,$D6
        mov     byte ptr [edx],0
        mov     eax,$D9
        mov     esi,$D6
        lea     ecx,[eax-1]
        mov     eax,$D8
        inc     esi
        mov     $D6,esi
        mov     dl,[eax]
        shl     dl,cl
        mov     [eax],dl
        mov     eax,[esp+50h]
        test    eax,eax
        jz      short $L224
        mov     ecx,$D6
        mov     ebp,[esp+44h]
        mov     edx,$D7
        mov     edi,[esp+40h]
        sub     ecx,ebp
        sub     edx,edi
        push    ecx
        push    edx
        call    eax
        add     esp,8
        test    eax,eax
        jnz     short $L224
$L223:  pop     edi
        pop     esi
        pop     ebp
        xor     eax,eax
        pop     ebx
        add     esp,2ch
        ret
$L224:  mov     eax,$D6
        mov     ecx,[esp+44h]
        sub     eax,ecx
$L225:  pop     edi
        pop     esi
        pop     ebp
        pop     ebx
        add     esp,2ch
        ret
_ap_depack:
        pusha
        mov     esi,[esp+24h]
        mov     edi,[esp+28h]
        cld
        mov     dl,80h
$L226:  mov     al,[esi]
        inc     esi
        mov     [edi],al
        inc     edi
$L227:  add     dl,dl
        jnz     short $L228
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L228:  jnc     short $L226
        add     dl,dl
        jnz     short $L229
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L229:  jnc     short $L236
        xor     eax,eax
        add     dl,dl
        jnz     short $L230
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L230:  jnb     $L250
        add     dl,dl
        jnz     short $L231
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L231:  adc     eax,eax
        add     dl,dl
        jnz     short $L232
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L232:  adc     eax,eax
        add     dl,dl
        jnz     short $L233
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L233:  adc     eax,eax
        add     dl,dl
        jnz     short $L234
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L234:  adc     eax,eax
        jz      short $L235
        push    edi
        sub     edi,eax
        mov     al,[edi]
        pop     edi
$L235:  mov     [edi],al
        inc     edi
        jmp     short $L227
$L236:  mov     eax,1
$L237:  add     dl,dl
        jnz     short $L238
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L238:  adc     eax,eax
        add     dl,dl
        jnz     short $L239
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L239:  jc      short $L237
        sub     eax,2
        jnz     short $L243
        mov     ecx,1
$L240:  add     dl,dl
        jnz     short $L241
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L241:  adc     ecx,ecx
        add     dl,dl
        jnz     short $L242
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L242:  jc      short $L240
        push    esi
        mov     esi,edi
        sub     esi,ebp
        rep     movsb
        pop     esi
        jmp     $L227
$L243:  dec     eax
        shl     eax,8
        mov     al,[esi]
        inc     esi
        mov     ebp,eax
        mov     ecx,1
$L244:  add     dl,dl
        jnz     short $L245
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L245:  adc     ecx,ecx
        add     dl,dl
        jnz     short $L246
        mov     dl,[esi]
        inc     esi
        adc     dl,dl
$L246:  jc      short $L244
        cmp     eax,7d00h
        jnc     short $L248
        cmp     eax,500h
        jc      short $L247
        inc     ecx
        push    esi
        mov     esi,edi
        sub     esi,eax
        rep     movsb
        pop     esi
        jmp     $L227
$L247:  cmp     eax,7fh
        jnbe    short $L249
$L248:  add     ecx,2
$L249:  push    esi
        mov     esi,edi
        sub     esi,eax
        rep     movsb
        pop     esi
        jmp     $L227
$L250:  mov     al,[esi]
        inc     esi
        xor     ecx,ecx
        shr     al,1
        jz      short $L251
        adc     ecx,2
        mov     ebp,eax
        push    esi
        mov     esi,edi
        sub     esi,eax
        rep     movsb
        pop     esi
        jmp     $L227
$L251:  sub     edi,[esp+28h]
        mov     [esp+1ch],edi
        popa
        ret

        .data?

$D1     dd      ?
$D2     dd      256 dup(?)
$D3     dd      ?
$D4     dd      ?
$D5     dd      ?
$D6     dd      ?
$D7     dd      ?
$D8     dd      ?
$D9     dd      ?
$D10    dd      ?
$D11    dd      ?


        end
