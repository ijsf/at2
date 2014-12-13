(**********************************************************)
(* VESA 2.0 Linear Framebuffer 256-color graphics library *)
(* for TMT Pascal Lite 2.02+                              *)
(* Unit version : 4.04                                    *)
(* Started      : 18.Feb.1998                             *)
(* Finished     : 24.Jun.1998                             *)
(* Last updated : 03.Jul.1999                             *)
(* System       : 32-bit DPMI                             *)
(*                                                        *)
(*   (C)oded by Asp / VR group                            *)
(*   This unlicensed material is protected                *)
(*   by the Second Law of Thermodynamics.                 *)
(*   All rights are free, all lefts reserved.             *)
(**********************************************************)


unit LFB256;
{$S-,Q-,R-,V-,B-,X+}

interface

 const Version='4.04';

 const _320x200=$13;
       _640x350=$11C;
       _640x400=$100;
       _640x480=$101;
       _800x600=$103;
       _1024x768=$105;

      (* Error codes *)
      (***************)

   NO_EROR=0;
   NOT_INITIALIZED=1;
   UNABLE_SET_MODE=2;
   INVALID_MODE=3;
   UNABLE_OPEN_FILE=4;
   UNABLE_REWRITE_FILE=5;
   INVALID_LOG_WIDTH=6;
   UNABLE_SET_WIDTH=7;
   UNABLE_SET_ORIGIN=8;
   INVALID_FILE_FMT=9;
   IMAGE_WIDTH_TOOBIG=10;


       _ErrorMessage:array[0..10] of string[50]=(
   'Operation successful',                                 (* 0 *)
   'Graphics system not initialized - call _VBE2_Init',    (* 1 *)
   'Unable to set videomode',                              (* 2 *)
   'Invalid mode number',                                  (* 3 *)
   'Unable to open file',                                  (* 4 *)
   'Unable to rewrite file',                               (* 5 *)
   'Invalid logical screen width specified',               (* 6 *)
   'Unable to set new logical screen width',               (* 7 *)
   'Unable to set new display origin',                     (* 8 *)
   'Invalid file format',                                  (* 9 *)
   'Image width too big');                                 (* 10 *)

       _WhitePalette:array[0..767] of byte=(63,...);
       _BlankPalette:array[0..767] of byte=(0,...);


 type  TModeInfo=record
  ModeNumber:word;
  XResolution:word;
  YResolution:word;
  BufferAddress:pointer;
 end;

       TWindow=record
  MinX,MinY,MaxX,MaxY:word;
 end;

       TRGB=record
  R,G,B:byte;
 end;

       TYUV=record
  Y,U,V:byte;
 end;

       TPalette=array[0..255] of TRGB;


 var _ModeList:array[0..255] of TModeInfo;

     _VESA_Version:word;      (* VESA version *)
     _OEM_String:string;      (* VESA OEM string *)
     _VESA_Capabilities:dword;      (* Hardware capabilities *)
     _VideoMemory:word;       (* Videomemory amount in Kb *)
     _OEM_SoftwareRevision:word; (* VESA implementation revision *)
     _OEM_VendorName:string;     (* VESA vendor name *)
     _OEM_ProductName:string;    (* VESA OEM product name *)
     _OEM_ProductRevision:string;   (* VESA OEM product revision *)

     _Mode:word;                (* Current videomode  *)
     _ModeIndex:byte;           (* Current mode index in _ModeList  *)
     _XResolution,              (* Current X resolution *)
     _YResolution:word;         (* Current Y resolution *)
     _MinClipX,                 (* Clipping window coordinates *)
     _MinClipY,
     _MaxClipX,
     _MaxClipY:word;
     _LogicalScreenWidth,        (* Virtual display size *)
     _LogicalScreenHeight:word;
     _OriginX,
     _OriginY:word;     (* Virtual display origin *)

     _FullScreen:TWindow;  (* Defines fullscreen window *)

     _NumberOfModes:byte;  (* Total LFB videomodes supported.
                              VGA 320x200x256 is always supported,
                              even if this variable is set to 0 *)

     _TransparentColor:byte;  (* "Transparent" color *)

     _FrameBuffer:pointer; (* LFB address for current mode *)
     _Font:pointer;        (* current font *)


   (* Initialization stuff *)
   (************************)

 procedure _VBE2_Init;
 procedure _VGA13_Init;     (* Use VGA 13h only *)
 function  _SetMode(Mode:word):smallint;
        (* Following one is only needed for compatibility w/ Graph unit *)
 procedure _InitGraph(XResolution,YResolution:word;VideoMem:word;LFB_Address:longint);

   (* Drawing routines *)
   (********************)

 procedure _PutPixel(x,y:smallint;Color:byte);
 procedure _PutTransparentPixel(x,y:smallint;Color:byte);
 function  _GetPixel(x,y:word):byte;
 procedure _Line(x1,y1,x2,y2:word;Color:byte);
 procedure _MaskedLine(x1,y1,x2,y2:word;Color:byte;Mask:word);
 procedure _HLine(x1,x2,y:smallint;Color:byte);
 procedure _VLine(x,y1,y2:smallint;Color:byte);
 procedure _Rectangle(x1,y1,x2,y2:word;Color:byte);
 procedure _Bar(x1,y1,x2,y2:word;Color:byte);
 procedure _Ellipse(xc,yc,rx,ry:word;Color:byte);
 procedure _FilledEllipse(xc,yc,rx,ry:word;Color:byte);
 procedure _Triangle(x1,y1,x2,y2,x3,y3:word;Color:byte);
 procedure _FillTriangle(x1,y1,x2,y2,x3,y3:word;Color:byte);
 procedure _FillPoly(var VertexArray;NumOfVertexes,Color:byte);

   (* Drawing routines with XOR *)
   (*****************************)

 procedure _XORPixel(x,y:smallint;Color:byte);
 procedure _XORTransparentPixel(x,y:smallint;Color:byte);
 procedure _XORLine(x1,y1,x2,y2:word;Color:byte);
 procedure _XORMaskedLine(x1,y1,x2,y2:word;Color:byte;Mask:word);
 procedure _XORHLine(x1,x2,y:smallint;Color:byte);
 procedure _XORVLine(x,y1,y2:smallint;Color:byte);
 procedure _XORRectangle(x1,y1,x2,y2:word;Color:byte);
 procedure _XORBar(x1,y1,x2,y2:word;Color:byte);
 procedure _XOREllipse(xc,yc,rx,ry:word;Color:byte);
 procedure _XORFilledEllipse(xc,yc,rx,ry:word;Color:byte);
 procedure _XORTriangle(x1,y1,x2,y2,x3,y3:word;Color:byte);
 procedure _XORFillTriangle(x1,y1,x2,y2,x3,y3:word;Color:byte);
 procedure _XORFillPoly(var VertexArray;NumOfVertexes,Color:byte);

   (* The same with clipping *)
   (**************************)

 procedure __PutPixel(x,y:smallint;Color:byte);
 procedure __PutTransparentPixel(x,y:smallint;Color:byte);
 function  __GetPixel(x,y:smallint):byte;
 procedure __Line(x1,y1,x2,y2:smallint;Color:byte);
 procedure __MaskedLine(x1,y1,x2,y2:smallint;Color:byte;Mask:word);
 procedure __HLine(x1,x2,y:smallint;Color:byte);
 procedure __VLine(x,y1,y2:smallint;Color:byte);
 procedure __Rectangle(x1,y1,x2,y2:smallint;Color:byte);
 procedure __Bar(x1,y1,x2,y2:smallint;Color:byte);
 procedure __Ellipse(xc,yc,rx,ry:smallint;Color:byte);
 procedure __FilledEllipse(xc,yc,rx,ry:smallint;Color:byte);
 procedure __Triangle(x1,y1,x2,y2,x3,y3:smallint;Color:byte);
 procedure __FillTriangle(x1,y1,x2,y2,x3,y3:smallint;Color:byte);
 procedure __FillPoly(var VertexArray;NumOfVertexes,Color:byte);

 procedure __XORPixel(x,y:smallint;Color:byte);
 procedure __XORTransparentPixel(x,y:smallint;Color:byte);
 procedure __XORLine(x1,y1,x2,y2:smallint;Color:byte);
 procedure __XORMaskedLine(x1,y1,x2,y2:smallint;Color:byte;Mask:word);
 procedure __XORHLine(x1,x2,y:smallint;Color:byte);
 procedure __XORVLine(x,y1,y2:smallint;Color:byte);
 procedure __XORRectangle(x1,y1,x2,y2:smallint;Color:byte);
 procedure __XORBar(x1,y1,x2,y2:smallint;Color:byte);
 procedure __XOREllipse(xc,yc,rx,ry:smallint;Color:byte);
 procedure __XORFilledEllipse(xc,yc,rx,ry:smallint;Color:byte);
 procedure __XORTriangle(x1,y1,x2,y2,x3,y3:smallint;Color:byte);
 procedure __XORFillTriangle(x1,y1,x2,y2,x3,y3:smallint;Color:byte);
 procedure __XORFillPoly(var VertexArray;NumOfVertexes,Color:byte);

   (* Palette routines *)
   (********************)

 procedure _GetPalette(var Palette);
 procedure _SetPalette(var Palette);
 procedure _Fade(var StartPalette,EndPalette;Speed:single);
 procedure _InitStepFade(var StartPalette,EndPalette;Speed:single);
 function  _StepFade:boolean;
 procedure _SetRGB(Color,R,G,B:byte);
 procedure _GetRGB(Color:byte;var R,G,B:byte);
 procedure _Convert8bppcTo6bppc(var Palette);
 function  _RGB2YUV(RGB:TRGB):TYUV;
 function  _YUV2RGB(YUV:TYUV):TRGB;
 procedure _GammaCorrect(var Palette;Gamma:single); (* Gamma is [0.5..2.0] *)
 procedure _GammaCorrectRGB(var Palette;Gamma:single);

   (* Getting/putting bitmaps *)
   (***************************)

 procedure _GetImage(x,y,Width,Height:word;Address:pointer);
 procedure _PutImage(x,y,Width,Height:word;Address:pointer);
 procedure _PutTransparentImage(x,y,Width,Height:word;Address:pointer);
 procedure _XORImage(x,y,Width,Height:word;Address:pointer);

   (* The same with clipping *)
   (**************************)

 procedure __GetImage(x,y:smallint;Width,Height:word;Address:pointer);
 procedure __PutImage(x,y:smallint;Width,Height:word;Address:pointer);
 procedure __PutTransparentImage(x,y:smallint;Width,Height:word;Address:pointer);
 procedure __XORImage(x,y:smallint;Width,Height:word;Address:pointer);

   (* Image files handling *)
   (************************)

 function  _PCX_Display(FileName:string;FileOffset:dword;x,y:word):smallint;
 function  _PCX_Buffer(FileName:string;FileOffset:dword;address:pointer):smallint;
 function  _SavePCX(FileName:string;x1,y1,x2,y2:word):smallint;
 function  _Get_PCX_Palette(FileName:string;var Palette):smallint;
 function  _Get_PCX_Size(FileName:string;FileOffset:dword;var PicSize:TWindow):smallint;

   (* Miscellaneous *)
   (*****************)

 procedure _SetTextMode;
 procedure _Fill(Color:byte);
 procedure _SetWindow(ClipWindow:TWindow);
 procedure _WaitForVSync;
 procedure _WaitForVSyncStart;
 procedure _Terminate(Message:string;Code:word);
 function  Copyleft_Id:string;

   (* Virtual display *)
   (*******************)

 function  _SetLogicalWidth(NewWidth:word):smallint;
 function  _SetDisplayOrigin(x,y:word):smallint;

   (* Virtual screens (pages) *)
   (***************************)

 procedure _SetVirtualOutput(Address:pointer);
 procedure _FlushVirtualScreen(Address:pointer);
 procedure _MoveToVirtualScreen(Address:pointer);
 procedure _SetNormalOutput;

   (* Fonts and text writing *)
   (**************************)

 procedure _SetFont(Font:pointer);
 procedure _WriteTransparentText(x,y:word;S:string;Color:byte);
 procedure __WriteTransparentText(x,y:word;S:string;Color:byte);
 procedure _WriteOverlappedText(x,y:word;S:string;Color,BkColor:byte);
 procedure __WriteOverlappedText(x,y:word;S:string;Color,BkColor:byte);


implementation
{$IFDEF __VER3__}
uses DPMI,Strings;
{$ELSE}
{$IFDEF __VER4__}
uses DPMI,Strings;
{$ELSE}
uses DPMILib,Strings;
{$ENDIF}

const _GraphicsSysInited:boolean=false;
      FatalError='Graphics system fatal: ';

var   Copyleft:string;        (* Copyleft message *)
      _IO_Buffer:array[1..8192] of byte;

(****************************************************************************

                     Initialization procedures

****************************************************************************)


procedure _VBE2_Init;

   (* This one must be called before all *)

type TModeInfoBlock=record
      (* For all versions *)
   ModeAttributes:word;
   WinAAttributes:byte;
   WinBAttributes:byte;
   WinGranularity:word;
   WinSize:word;
   WinASegment:word;
   WinBSegment:word;
   WinFuncPtr:pointer;
   BytesPerScanLine:word;
      (* VESA 1.2+ specific *)
   XResolution:word;
   YResolution:word;
   XCharSize:byte;
   YCharSize:byte;
   NumberOfPlanes:byte;
   BitsPerPixel:byte;
   NumberOfBanks:byte;
   MemoryModel:byte;
   BankSize:byte;
   NumberOfImagePages:byte;
   Reserved1:byte;
      (* Direct color data *)
   RedMaskSize:byte;
   RedFieldPosition:byte;
   GreenMaskSize:byte;
   GreenFieldPosition:byte;
   BlueMaskSize:byte;
   BlueFieldPosition:byte;
   RsvdMaskSize:byte;
   RsvdFieldPosition:byte;
   DirectColorModeInfo:byte;
      (* VESA 2.0+ specific *)
   PhysBasePtr:pointer;
   OffScreenMemOffset:dword;
   OffScreenMemSize:word;
   Reserved2:array[0..205] of byte;
     end;

     TModeList=array[0..127] of word;

     TVESA_Info=record
   Signature:array[0..3] of char;
   Version:word;
   OEM_StringPtr:dword;
   Capabilities:dword;
   ModeListPtr:dword;
   VideoMemory:word;
   OEM_SoftwareRevision:word;
   OEM_VendorNamePtr:dword;
   OEM_ProductNamePtr:dword;
   OEM_ProductRevisionPtr:dword;
   Reserved:array[0..221] of byte;
   OEM_Data:array[0..255] of byte;
     end;

     Pointer16=record
   Offset:word;
   Segment:word;
     end;

var i,j:byte;
    ModeList:TModeList;
    VESA_Info:TVESA_Info;
    ModeInfoBlock:TModeInfoBlock;
    Regs:TRmRegs;
begin
 if _GraphicsSysInited then Exit;   (* Already initialized *)
 with _ModeList[0] do begin
   (* Add support for VGA 320x200 *)
  ModeNumber:=$13;
  XResolution:=320;
  YResolution:=200;
  BufferAddress:=Pointer($A0000);
 end;
 VESA_Info.Signature:='VBE2';
 Move(VESA_Info,pointer(Buf_32)^,4);
 ClearRmRegs(Regs);
 Regs.ax:=$4F00;
 Regs.es:=Buf_16;
 Regs.ds:=Regs.es;
 Regs.edi:=0;
 RealModeInt($10,Regs);    (* Request VESA 2.0 information *)
 Move(pointer(Buf_32)^,VESA_Info,SizeOf(TVESA_Info));
 if VESA_Info.Signature<>'VESA' then _Terminate(FatalError+'VESA BIOS extensions not found',2);
 _VESA_Version:=VESA_Info.Version;
 if Hi(_VESA_Version)<2 then _Terminate(FatalError+'VESA 2.0 required',3);
 _OEM_String:=StrPas(pchar(dword(Pointer16(VESA_Info.OEM_StringPtr).Segment) shl 4
                     +Pointer16(VESA_Info.OEM_StringPtr).Offset));
 _VESA_Capabilities:=VESA_Info.Capabilities;
 _VideoMemory:=VESA_Info.VideoMemory shl 6;
 _OEM_SoftwareRevision:=VESA_Info.OEM_SoftwareRevision;
 _OEM_VendorName:=StrPas(pchar(dword(Pointer16(VESA_Info.OEM_VendorNamePtr).Segment) shl 4
                     +Pointer16(VESA_Info.OEM_VendorNamePtr).Offset));
 _OEM_ProductName:=StrPas(pchar(dword(Pointer16(VESA_Info.OEM_ProductNamePtr).Segment) shl 4
                     +Pointer16(VESA_Info.OEM_ProductNamePtr).Offset));
 _OEM_ProductRevision:=StrPas(pchar(dword(Pointer16(VESA_Info.OEM_ProductRevisionPtr).Segment) shl 4
                     +Pointer16(VESA_Info.OEM_ProductRevisionPtr).Offset));

 Move(pointer(dword(Pointer16(VESA_Info.ModeListPtr).Segment) shl 4+
      Pointer16(VESA_Info.ModeListPtr).Offset)^,ModeList,256);

 i:=0;j:=1;
 repeat        (* find first LFB mode *)
  ClearRmRegs(Regs);
  Regs.ax:=$4F01;
  Regs.cx:=ModeList[i];
  Regs.es:=Buf_16;
  Regs.ds:=Regs.es;
  Regs.edi:=0;
  RealModeInt($10,Regs);
   (* Get mode information *)
  Move(pointer(Buf_32)^,ModeInfoBlock,SizeOf(TModeInfoBlock));
  Inc(i);
 until (((ModeInfoBlock.ModeAttributes and $0091)=$0091) and
     (ModeInfoBlock.NumberOfPlanes=1) and
     (ModeInfoBlock.BitsPerPixel=8)) or (ModeList[i-1]=$FFFF);

 if ModeList[i-1]<>$FFFF then begin
  Inc(j);
  with _ModeList[1] do begin
   ModeNumber:=ModeList[i-1];
   XResolution:=ModeInfoBlock.XResolution;
   YResolution:=ModeInfoBlock.YResolution;
   BufferAddress:=ModeInfoBlock.PhysBasePtr; (* get LFB physical address *)
  end;

  while ModeList[i]<>$FFFF do begin (* find remaining modes *)
   ClearRmRegs(Regs);
   Regs.ax:=$4F01;
   Regs.cx:=ModeList[i];
   Regs.es:=Buf_16;
   Regs.ds:=Regs.es;
   Regs.edi:=0;
   RealModeInt($10,Regs);
   (* Get mode information *)
   Move(pointer(Buf_32)^,ModeInfoBlock,SizeOf(TModeInfoBlock));
   if ((ModeInfoBlock.ModeAttributes and $0091)=$0091) and  (* LFB enabled *)
      (ModeInfoBlock.NumberOfPlanes=1) and         (* 1 bitblane *)
      (ModeInfoBlock.BitsPerPixel=8) then begin    (* 256 colors *)
       with _ModeList[j] do begin
        ModeNumber:=ModeList[i];
        XResolution:=ModeInfoBlock.XResolution;
        YResolution:=ModeInfoBlock.YResolution;
       end;
       Inc(j);
   end; (* if *)
   Inc(i);
  end; (* while *)
 end; (* if *)

 _NumberOfModes:=j-1;
 if _NumberOfModes>=1 then begin
  _ModeList[1].BufferAddress:=
   pointer(MapPhysicalToLinear(dword(_ModeList[1].BufferAddress),4096*1024));
  if _ModeList[1].BufferAddress=nil then
   _Terminate(FatalError+'cannot remap LFB to linear address space',1);
  for i:=2 to _NumberOfModes do _ModeList[i].BufferAddress:=_ModeList[1].BufferAddress;
 end;
 _Mode:=0;
 _GraphicsSysInited:=true;
end;

procedure _VGA13_Init;
begin
 if _GraphicsSysInited then Exit;   (* Already initialized *)
 with _ModeList[0] do begin
  ModeNumber:=$13;
  XResolution:=320;
  YResolution:=200;
  BufferAddress:=Pointer($A0000);
 end;
 _VESA_Version:=0;
 _VideoMemory:=64;
 _NumberOfModes:=0;
 _Mode:=0;
 _GraphicsSysInited:=true;
end;

function  _SetMode(Mode:word):smallint;
var i:byte;
label _exit;
begin
 if not _GraphicsSysInited then begin
  _SetMode:=NOT_INITIALIZED;
  Exit;
 end;
 _ModeIndex:=_NumberOfModes+1;
 for i:=0 to _NumberOfModes do
  if _ModeList[i].ModeNumber=Mode then begin _ModeIndex:=i;Break;end;
 if _ModeIndex=_NumberOfModes+1 then begin
  _SetMode:=INVALID_MODE;
  Exit;
 end;
 if Mode<>19 then Mode:=Mode or $4000;
 asm
  mov ax,$4F02
  mov bx,Mode
  int $10
  cmp ax,$004F
  je @@1
   (* error occurred *)
  mov ax,UNABLE_SET_MODE
  jmp _exit
 @@1:
 end;
 _Mode:=Mode;
 _XResolution:=_ModeList[_ModeIndex].XResolution;
 _YResolution:=_ModeList[_ModeIndex].YResolution;
 _MinClipX:=0;
 _MinClipY:=0;
 _MaxClipX:=_XResolution-1;
 _MaxClipY:=_YResolution-1;
 _LogicalScreenWidth:=_XResolution;
 _LogicalScreenHeight:=_YResolution;
 _OriginX:=0;
 _OriginY:=0;
 _FullScreen.MinX:=0;
 _FullScreen.MinY:=0;
 _FullScreen.MaxX:=_XResolution-1;
 _FullScreen.MaxY:=_YResolution-1;
 _Framebuffer:=_ModeList[_ModeIndex].BufferAddress;
 _TransparentColor:=0;
 _SetMode:=0;
_exit:
end;

procedure _InitGraph(XResolution,YResolution:word;VideoMem:word;LFB_Address:longint);

        (* This one must be called after SetSVGAMode in order to
           make possible simultaneous usage of Graph and LFB256 units *)

begin
 _ModeList[1].BufferAddress:=
  pointer(MapPhysicalToLinear(LFB_Address,4096*1024));
  if _ModeList[1].BufferAddress=nil then
   _Terminate(FatalError+'cannot remap LFB to linear address space',1);
 _FrameBuffer:=_ModeList[1].BufferAddress;
 _VideoMemory:=VideoMem;
 _ModeList[1].ModeNumber:=$FFFF;      (* Mode is set by Graph unit routines *)
 _ModeList[1].XResolution:=XResolution;
 _ModeList[1].YResolution:=YResolution;
 _ModeIndex:=1;         (* Current mode index is always 1 if using Graph *)
 _NumberOfModes:=1;     (* Only current mode available *)
 _Mode:=$FFFF;
 _LogicalScreenWidth:=XResolution;
 _LogicalScreenHeight:=YResolution;
 _OriginX:=0;
 _OriginY:=0;
 _MinClipX:=0;
 _MinClipY:=0;
 _MaxClipX:=_LogicalScreenWidth-1;
 _MaxClipY:=_LogicalScreenHeight-1;
 _FullScreen.MinX:=0;
 _FullScreen.MinY:=0;
 _FullScreen.MaxX:=_MaxClipX;
 _FullScreen.MaxY:=_MaxClipY;
 _TransparentColor:=0;
 _GraphicsSysInited:=true;
end;


(****************************************************************************

                            Drawing stuff

****************************************************************************)

procedure _PutPixel(x,y:smallint;Color:byte);assembler;
asm
 mov edi,_FrameBuffer      (* edi points to linear framebuffer *)
 movzx eax,y               (* eax <- y *)
 movzx edx,_LogicalScreenWidth  (* edx <- screen width *)
 mul edx                        (* eax <- y*_LogicalScreenWidth *)
 mov dx,x
 add eax,edx                    (* eax <- pixel offset *)
 add edi,eax                    (* edi points to pixel address *)
 mov al,Color                   (* prepare color *)
 mov [edi],al                   (* put pixel *)
end;

procedure _PutTransparentPixel(x,y:smallint;Color:byte);assembler;
asm
 mov cl,Color
 cmp cl,_TransparentColor
 je @@Exit
 mov edi,_FrameBuffer
 movzx eax,y
 movzx edx,_LogicalScreenWidth
 mul edx
 mov dx,x
 add eax,edx
 add edi,eax
 mov [edi],cl
@@Exit:
end;

function  _GetPixel(x,y:word):byte;assembler;
asm
 mov edi,_FrameBuffer
 movzx eax,y
 movzx edx,_LogicalScreenWidth
 mul edx
 mov dx,x
 add eax,edx
 add edi,eax
 mov al,[edi]
end;

procedure _HLine(x1,x2,y:smallint;Color:byte);assembler;
asm
 cld
 mov edi,_FrameBuffer      (* edi points to linear framebuffer *)
 movzx eax,y
 movzx ecx,_LogicalScreenWidth  (* ecx <- screen width *)
 mul ecx                        (* eax <- y*_LogicalScreenWidth *)
 mov dx,x1
 add eax,edx                    (* eax <- pixel offset *)
 add edi,eax                    (* edi points to first pixel address *)
 mov al,Color
 mov ah,al
 mov ebx,eax
 shl eax,16
 mov ax,bx                      (* eax now filled with color *)
 mov cx,x2
 sub ecx,edx
 inc ecx                        (* cx contains number of pixels to fill *)
 mov ebx,ecx
 shr ecx,2
 rep stosd                      (* fill line *)
 mov ecx,ebx
 and ecx,3
 rep stosb                      (* fill the rest of line if there is one *)
end;

procedure _VLine(x,y1,y2:smallint;Color:byte);assembler;
asm
 mov edi,_FrameBuffer      (* edi points to linear framebuffer *)
 movzx eax,y1              (* eax <- y *)
 movzx ecx,_LogicalScreenWidth  (* ecx <- screen width *)
 mul ecx                        (* eax <- y*_LogicalScreenWidth *)
 mov dx,x
 add eax,edx                    (* eax <- pixel offset *)
 add edi,eax                    (* edi points to first pixel address *)
 mov al,Color                   (* al <- color *)
 mov cx,y2
 sub cx,y1
 inc ecx                        (* cx <- number of pixels *)
 mov dx,_LogicalScreenWidth
@@1:
 mov [edi],al                   (* fill line *)
 add edi,edx
 loop @@1
end;

procedure _Rectangle(x1,y1,x2,y2:word;Color:byte);assembler;
asm
 mov edi,_FrameBuffer
 movzx eax,y1
 movzx edx,_LogicalScreenWidth
 mul edx
 mov dx,x1
 add eax,edx
 add edi,eax
 xor ecx,ecx
 mov cx,x2
 sub cx,dx
 mov al,Color
 mov ah,al
 mov ebx,eax
 shl eax,16
 mov ax,bx
 inc ecx
 mov ebx,ecx
 shr ecx,2
 rep stosd        (* draw horizontal line *)
 mov ecx,ebx
 and ecx,3
 rep stosb
 movzx ebx,x2
 sub bx,x1
 mov dx,_LogicalScreenWidth
 sub edx,ebx
 dec edx           (* dx <- (screen width)-((pixels per line)-1)-1 *)
 dec ebx           (* bx <- (pixels per line)-2 *)
 mov cx,y2         (* cx <- (number of lines)-2 *)
 sub cx,y1
 jz @@Exit
 dec ecx
 jz @@DrawBottom
@@1:               (* draw vertical sides *)
 add edi,edx
 stosb
 add edi,ebx
 stosb
 loop @@1
@@DrawBottom:
 add edi,edx       (* draw bottom line *)
 inc ebx
 inc ebx
 mov ecx,ebx
 shr ecx,2
 rep stosd
 mov ecx,ebx
 and ecx,3
 rep stosb
@@Exit:
end;

procedure _Bar(x1,y1,x2,y2:word;Color:byte);assembler;
asm
 mov edi,_FrameBuffer
 movzx eax,y1
 movzx ecx,_LogicalScreenWidth
 mul ecx
 add edi,eax
 mov cx,x1
 add edi,ecx
 mov al,Color
 mov ah,al
 mov ebx,eax
 shl eax,16
 mov ax,bx
 mov bx,x2
 sub bx,x1
 inc ebx                         (* bx <- (pixels per line) *)
 mov dx,_LogicalScreenWidth
 sub edx,ebx
@@1:
 mov ecx,ebx
 shr ecx,2
 rep stosd                       (* fill horizontal line *)
 mov ecx,ebx
 and ecx,3
 rep stosb
 add edi,edx
 inc y1
 mov cx,y2
 cmp cx,y1                       (* repeat while y1<=y2 *)
 jns @@1
end;

procedure _Line(x1,y1,x2,y2:word;Color:byte);assembler;

        (* This is Bresenham line. This code is raw-ported
           from plain C, so don't be scared too much <g> *)

var d,_dx,_dy,aincr,bincr,yincr:smallint;
asm
 mov ax,x1
 cmp ax,x2
 je @@Vertical
 jbe @@1                (* if x1>x2 *)
 mov bx,x2
 mov x1,bx
 mov x2,ax              (* swap x1,x2 *)
 mov ax,y1
 mov bx,y2
 mov y1,bx
 mov y2,ax              (* swap y1,y2 *)
@@1:
 mov cx,_LogicalScreenWidth
 mov ax,y1
 mov bx,y2
 cmp bx,ax
 ja @@2                 (* if y2>y1 *)
 neg cx                 (* yincr=-(_LogicalScreenWidth) *)
@@2:
 mov yincr,cx           (* else yincr=_LogicalScreenWidth *)
 sub bx,ax              (* bx <- (y2-y1) *)
 jns @@3
 neg bx
@@3:
 mov _dy,bx             (* _dy=abs(y2-y1) *)
 mov ax,x2
 sub ax,x1
 mov _dx,ax             (* _dx=x2-x1 *)
 cmp ax,bx
 jb @@45                (* if _dx>=_dy *)
 shl bx,1
 mov bincr,bx           (* bincr=2*_dy *)
 sub bx,ax
 mov d,bx               (* d=2*_dy-_dx *)
 mov ax,_dy
 sub ax,_dx
 jmp @@Continue
@@45:                   (* else *)
 shl ax,1
 mov bincr,ax           (* bincr=2*_dx *)
 sub ax,bx
 mov d,ax               (* d=2*_dx-_dy *)
 mov ax,_dx
 sub ax,_dy
@@Continue:
 sal ax,1
 mov aincr,ax           (* aincr=2*(_dx-_dy) or aincr=2*(_dy-_dx) *)

 movzx edx,_LogicalScreenWidth
 movzx eax,y1
 mul edx
 mov edi,_FrameBuffer
 add edi,eax
 mov dx,x1
 add edi,edx
 mov bl,Color
 mov [edi],bl        (* PutPixel(x,y) *)

 movsx edx,yincr
 mov ax,_dx
 cmp ax,_dy
 jb @@LessThen45

@@6:
 inc edi                (* x+=1 *)
 inc x1
 mov ax,d
 cmp ax,0
 js @@4                 (* if d>=0 *)
 add edi,edx            (* y+=yincr *)
 add ax,aincr           (* d+=aincr *)
 jmp @@5
@@4:                    (* else *)
 add ax,bincr           (* d+=bincr *)
@@5:
 mov d,ax
 mov [edi],bl           (* PutPixel(x,y) *)

 mov ax,x2
 cmp ax,x1
 ja @@6                 (* if x<x2 then loop *)
 jmp @@Exit

@@LessThen45:
 xor edx,0
 jns @@Positive
 mov cx,-1
 jmp @@6_
@@Positive:
 mov cx,1
@@6_:
 add edi,edx            (* y+=yinc *)
 add y1,cx
 mov ax,d
 cmp ax,0
 js @@4_                (* if d>=0 *)
 inc edi                (* x+=1 *)
 add ax,aincr           (* d+=aincr *)
 jmp @@5_
@@4_:                   (* else *)
 add ax,bincr           (* d+=bincr *)
@@5_:
 mov d,ax
 mov [edi],bl           (* PutPixel(x,y) *)

 mov ax,y2
 cmp ax,y1
 jne @@6_               (* if y<y2 then loop *)
 jmp @@Exit

@@Vertical:             (* draw vertical line *)
 mov ax,y1
 cmp ax,y2
 jbe @@7                (* if y1>y2 *)
 mov bx,y2
 mov y1,bx
 mov y2,ax              (* swap y1,y2 *)
@@7:
 mov edi,_FrameBuffer   (* edi points to linear framebuffer *)
 movzx eax,y1           (* eax <- y *)
 movzx ecx,_LogicalScreenWidth   (* ecx <- screen width *)
 mul ecx                         (* eax <- y*_LogicalScreenWidth *)
 mov dx,x1
 add eax,edx                     (* eax <- pixel offset *)
 add edi,eax                     (* edi points to first pixel address *)
 mov al,Color                    (* al <- color *)
 mov cx,y2
 sub cx,y1
 inc ecx                         (* cx <- number of pixels *)
 mov dx,_LogicalScreenWidth
@@8:
 mov [edi],al           (* fill line *)
 add edi,edx
 loop @@8

@@Exit:
end;

procedure _MaskedLine(x1,y1,x2,y2:word;Color:byte;Mask:word);assembler;
var d,_dx,_dy,aincr,bincr,yincr:smallint;
asm
 mov ax,x1
 cmp ax,x2
 je @@Vertical
 jbe @@1                (* if x1>x2 *)
 mov bx,x2
 mov x1,bx
 mov x2,ax              (* swap x1,x2 *)
 mov ax,y1
 mov bx,y2
 mov y1,bx
 mov y2,ax              (* swap y1,y2 *)
@@1:
 mov cx,_LogicalScreenWidth
 mov ax,y1
 mov bx,y2
 cmp bx,ax
 ja @@2                 (* if y2>y1 *)
 neg cx                 (* yincr=-(_LogicalScreenWidth) *)
@@2:
 mov yincr,cx           (* else yincr=_LogicalScreenWidth *)
 sub bx,ax              (* bx <- (y2-y1) *)
 jns @@3
 neg bx
@@3:
 mov _dy,bx             (* _dy=abs(y2-y1) *)
 mov ax,x2
 sub ax,x1
 mov _dx,ax             (* _dx=x2-x1 *)
 cmp ax,bx
 jb @@45                (* if _dx>=_dy *)
 shl bx,1
 mov bincr,bx           (* bincr=2*_dy *)
 sub bx,ax
 mov d,bx               (* d=2*_dy-_dx *)
 mov ax,_dy
 sub ax,_dx
 jmp @@Continue
@@45:                   (* else *)
 shl ax,1
 mov bincr,ax           (* bincr=2*_dx *)
 sub ax,bx
 mov d,ax               (* d=2*_dx-_dy *)
 mov ax,_dx
 sub ax,_dy
@@Continue:
 sal ax,1
 mov aincr,ax           (* aincr=2*(_dx-_dy) or aincr=2*(_dy-_dx) *)

 movzx edx,_LogicalScreenWidth
 movzx eax,y1
 mul edx
 mov edi,_FrameBuffer
 add edi,eax
 mov dx,x1
 add edi,edx
 mov bl,Color
 rol Mask,1
 jnc @@Skip1stPix
 mov [edi],bl           (* PutPixel(x,y) *)
@@Skip1stPix:

 movsx edx,yincr
 mov ax,_dx
 cmp ax,_dy
 jb @@LessThen45

@@6:
 inc edi                (* x+=1 *)
 inc x1
 mov ax,d
 cmp ax,0
 js @@4                 (* if d>=0 *)
 add edi,edx            (* y+=yincr *)
 add ax,aincr           (* d+=aincr *)
 jmp @@5
@@4:                    (* else *)
 add ax,bincr           (* d+=bincr *)
@@5:
 mov d,ax
 rol Mask,1
 jnc @@SkipPix
 mov [edi],bl           (* PutPixel(x,y) *)
@@SkipPix:

 mov ax,x2
 cmp ax,x1
 ja @@6                 (* if x<x2 then loop *)
 jmp @@Exit

@@LessThen45:
 xor edx,0
 jns @@Positive
 mov cx,-1
 jmp @@6_
@@Positive:
 mov cx,1
@@6_:
 add edi,edx            (* y+=yinc *)
 add y1,cx
 mov ax,d
 cmp ax,0
 js @@4_                (* if d>=0 *)
 inc edi                (* x+=1 *)
 add ax,aincr           (* d+=aincr *)
 jmp @@5_
@@4_:                   (* else *)
 add ax,bincr           (* d+=bincr *)
@@5_:
 mov d,ax
 rol Mask,1
 jnc @@SkipPix_
 mov [edi],bl           (* PutPixel(x,y) *)
@@SkipPix_:

 mov ax,y2
 cmp ax,y1
 jne @@6_               (* if y<y2 then loop *)
 jmp @@Exit

@@Vertical:             (* draw vertical line *)
 mov ax,y1
 cmp ax,y2
 jbe @@7                (* if y1>y2 *)
 mov bx,y2
 mov y1,bx
 mov y2,ax              (* swap y1,y2 *)
@@7:
 mov edi,_FrameBuffer   (* edi points to linear framebuffer *)
 movzx eax,y1           (* eax <- y *)
 movzx ecx,_LogicalScreenWidth  (* ecx <- screen width *)
 mul ecx                        (* eax <- y*_LogicalScreenWidth *)
 mov dx,x1
 add eax,edx                    (* eax <- pixel offset *)
 add edi,eax                    (* edi points to first pixel address *)
 mov al,Color                   (* al <- color *)
 mov cx,y2
 sub cx,y1
 inc ecx                        (* cx <- number of pixels *)
 mov dx,_LogicalScreenWidth
@@8:
 rol Mask,1
 jnc @@SkipPix__
 mov [edi],al           (* fill line *)
@@SkipPix__:
 add edi,edx
 loop @@8

@@Exit:
end;

procedure Ellipse(xc,yc,rx,ry:smallint;Color:byte;
                  procedure PutPixel(x,y:smallint;Color:byte);
                  procedure VLine(x,y1,y2:smallint;Color:byte);
                  procedure HLine(x1,x2,y:smallint;Color:byte));
   (* Common ellipse routine *)
var x,y:word;
    a,b,a2,b2:longint;
    d,dx,dy:longint;
begin
 if rx=0 then begin
  VLine(xc,yc-ry,yc+ry,Color); Exit;
 end;
 if ry=0 then begin
  HLine(xc-rx,xc+rx,yc,Color); Exit;
 end;
 x:=0; y:=ry; a:=rx*rx;
 a2:=a shl 1; b:=ry*ry; b2:=b shl 1;
 d:=b-a*ry+(a shr 2); dx:=0; dy:=a2*ry;
 while dx<dy do begin
  PutPixel(xc+x,yc+y,Color);
  PutPixel(xc-x,yc+y,Color);
  PutPixel(xc+x,yc-y,Color);
  PutPixel(xc-x,yc-y,Color);
  if d>0 then begin y:=y-1; dy:=dy-a2; d:=d-dy; end;
  x:=x+1; dx:=dx+b2; d:=d+b+dx;
 end;
 d:=d+((3*(a-b)div 2-(dx+dy))div 2);
 while y>0 do begin
  PutPixel(xc+x,yc+y,Color);
  PutPixel(xc-x,yc+y,Color);
  PutPixel(xc+x,yc-y,Color);
  PutPixel(xc-x,yc-y,Color);
  if d<0 then begin x:=x+1; dx:=dx+b2; d:=d+dx; end;
  y:=y-1; dy:=dy-a2; d:=d+a-dy;
 end;
 PutPixel(xc+x,yc,Color);
 PutPixel(xc-x,yc,Color);
end;

procedure FilledEllipse(xc,yc,rx,ry:smallint;Color:byte;
                        procedure VLine(x,y1,y2:smallint;Color:byte);
                        procedure HLine(x1,x2,y:smallint;Color:byte));
   (* Common filled ellipde routine *)
var x,y:word;
    a,b,a2,b2:longint;
    d,dx,dy:longint;
begin
 if rx=0 then begin
  VLine(xc,yc-ry,yc+ry,Color); Exit;
 end;
 if ry=0 then begin
  HLine(xc-rx,xc+rx,yc,Color); Exit;
 end;
 x:=0; y:=ry; a:=rx*rx; b:=ry*ry;
 a2:=a shl 1; b2:=b shl 1;
 d:=b-a*ry+(a shr 2); dx:=0; dy:=a2*ry;
 VLine(xc,yc-y,yc+y,Color);
 while dx<dy do begin
  if d>0 then begin Dec(y); Dec(dy,a2); Dec(d,dy); end;
  Inc(x); Inc(dx,b2); Inc(d,b+dx);
  VLine(xc-x,yc-y,yc+y,Color);
  VLine(xc+x,yc-y,yc+y,Color);
 end;
 d:=d+((3*(a-b)div 2-(dx+dy))div 2);
 while y>0 do begin
  if d<0 then begin
   Inc(x); Inc(dx,b2); Inc(d,b+dx);
   VLine(xc-x,yc-y,yc+y,Color);
   VLine(xc+x,yc-y,yc+y,Color);
  end;
  Dec(y); Dec(dy,a2); Inc(d,a-dy);
 end;
end;

procedure _Ellipse(xc,yc,rx,ry:word;Color:byte);
begin
 Ellipse(xc,yc,rx,ry,Color,_PutPixel,_VLine,_HLine);
end;

procedure _FilledEllipse(xc,yc,rx,ry:word;Color:byte);
begin
 FilledEllipse(xc,yc,rx,ry,Color,_VLine,_HLine);
end;

procedure _Triangle(x1,y1,x2,y2,x3,y3:word;Color:byte);
begin
 _Line(x1,y1,x2,y2,Color);
 _Line(x2,y2,x3,y3,Color);
 _Line(x3,y3,x1,y1,Color);
end;

procedure FillTriangle(x1,y1,x2,y2,x3,y3:smallint;Color:byte;
                       HLine:pointer);
assembler;
var ymin,xmin,ymid,xmid,ymax,xmax,xmid2,i:longint;
asm
 mov ax,y1
 cmp ax,y2
 jle @@1
 xchg ax,y2
 mov y1,ax
 mov ax,x1
 xchg ax,x2
 mov x1,ax
@@1:
 mov ax,y1
 cmp ax,y3
 jle @@2
 xchg ax,y3
 mov y1,ax
 mov ax,x1
 xchg ax,x3
 mov x1,ax
@@2:
 mov ax,y2
 cmp ax,y3
 jle @@4
 xchg ax,y3
 mov y2,ax
 mov ax,x2
 xchg ax,x3
 mov x2,ax
@@4:
 movzx eax,y1
 mov ymin,eax
 movzx eax,x1
 mov xmin,eax
 movzx eax,y2
 mov ymid,eax
 movzx eax,x2
 mov xmid,eax
 movzx eax,y3
 mov ymax,eax
 movzx eax,x3
 mov xmax,eax
 sub eax,xmin
 mov ebx,ymid
 sub ebx,ymin
 imul ebx
 mov ebx,ymax
 sub ebx,ymin
 jz @@exit      (* ymin=ymax *)
 idiv ebx
 add eax,xmin
 mov xmid2,eax
 cmp eax,xmid
 jge @@5
 xchg eax,xmid
 mov xmid2,eax
@@5:
 mov eax,ymin
 cmp eax,ymid
 je @@6
 mov eax,ymin
 mov i,eax
@@loop1:
 mov eax,xmid
 sub eax,xmin
 mov ebx,i
 sub ebx,ymin
 imul ebx
 mov ebx,ymid
 sub ebx,ymin
 idiv ebx
 add eax,xmin
 push eax
 mov eax,xmid2
 sub eax,xmin
 mov ebx,i
 sub ebx,ymin
 imul ebx
 mov ebx,ymid
 sub ebx,ymin
 idiv ebx
 add eax,xmin
 push eax
 push i
 push dword ptr color
 call HLine
 inc i
 mov eax,i
 sub eax,ymid
 cmp ax,2
 ja @@loop1
@@6:
 mov eax,ymid
 cmp eax,ymax
 je @@exit
 mov eax,ymid
 mov i,eax
@@loop2:
 mov eax,xmax
 sub eax,xmid
 mov ebx,i
 sub ebx,ymid
 imul ebx
 mov ebx,ymax
 sub ebx,ymid
 idiv ebx
 add eax,xmid
 push eax
 mov eax,xmax
 sub eax,xmid2
 mov ebx,i
 sub ebx,ymid
 imul ebx
 mov ebx,ymax
 sub ebx,ymid
 idiv ebx
 add eax,xmid2
 push eax
 push i
 push dword ptr color
 call HLine
 inc i
 mov eax,i
 sub eax,ymax
 cmp ax,0
 ja @@loop2
@@exit:
end;

procedure _FillTriangle(x1,y1,x2,y2,x3,y3:word;Color:byte);
begin
 FillTriangle(x1,y1,x2,y2,x3,y3,Color,@_HLine);
end;

procedure _FillPoly(var VertexArray;NumOfVertexes,Color:byte);
type TVertex=record
      x,y:smallint;
     end;
     TVertexArray=array[1..256] of TVertex;
begin
 if NumOfVertexes=1 then begin
  _PutPixel(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,color);
  Exit;
 end;
 if NumOfVertexes=2 then begin
  _Line(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,
      TVertexArray(VertexArray)[2].x,TVertexArray(VertexArray)[2].y,
      color);
  Exit;
 end;
 repeat
  _FillTriangle(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,
          TVertexArray(VertexArray)[NumOfVertexes-1].x,TVertexArray(VertexArray)[NumOfVertexes-1].y,
          TVertexArray(VertexArray)[NumOfVertexes].x,TVertexArray(VertexArray)[NumOfVertexes].y,
          color);
  Dec(NumOfVertexes);
 until NumOfVertexes=2;
end;


(****************************************************************************

                        XOR'ed drawing stuff

****************************************************************************)

procedure _XORPixel(x,y:smallint;Color:byte);assembler;
asm
 mov edi,_FrameBuffer
 movzx eax,y
 movzx edx,_LogicalScreenWidth
 mul edx
 mov dx,x
 add eax,edx
 add edi,eax
 mov al,Color
 xor byte ptr [edi],al
end;

procedure _XORTransparentPixel(x,y:smallint;Color:byte);assembler;
asm
 mov cl,Color
 cmp cl,_TransparentColor
 je @@Exit
 mov edi,_FrameBuffer
 movzx eax,y
 movzx edx,_LogicalScreenWidth
 mul edx
 mov dx,x
 add eax,edx
 add edi,eax
 xor byte ptr [edi],cl
@@Exit:
end;

procedure _XORLine(x1,y1,x2,y2:word;Color:byte);assembler;
var d,_dx,_dy,aincr,bincr,yincr:smallint;
asm
 mov ax,x1
 cmp ax,x2
 je @@Vertical
 jbe @@1
 mov bx,x2
 mov x1,bx
 mov x2,ax
 mov ax,y1
 mov bx,y2
 mov y1,bx
 mov y2,ax
@@1:
 mov cx,_LogicalScreenWidth
 mov ax,y1
 mov bx,y2
 cmp bx,ax
 ja @@2
 neg cx
@@2:
 mov yincr,cx
 sub bx,ax
 jns @@3
 neg bx
@@3:
 mov _dy,bx
 mov ax,x2
 sub ax,x1
 mov _dx,ax
 cmp ax,bx
 jb @@45
 shl bx,1
 mov bincr,bx
 sub bx,ax
 mov d,bx
 mov ax,_dy
 sub ax,_dx
 jmp @@Continue
@@45:
 shl ax,1
 mov bincr,ax
 sub ax,bx
 mov d,ax
 mov ax,_dx
 sub ax,_dy
@@Continue:
 sal ax,1
 mov aincr,ax

 movzx edx,_LogicalScreenWidth
 movzx eax,y1
 mul edx
 mov edi,_FrameBuffer
 add edi,eax
 mov dx,x1
 add edi,edx
 mov bl,Color
 xor byte ptr [edi],bl

 movsx edx,yincr
 mov ax,_dx
 cmp ax,_dy
 jb @@LessThen45

@@6:
 inc edi
 inc x1
 mov ax,d
 cmp ax,0
 js @@4
 add edi,edx
 add ax,aincr
 jmp @@5
@@4:
 add ax,bincr
@@5:
 mov d,ax
 xor byte ptr [edi],bl

 mov ax,x2
 cmp ax,x1
 ja @@6
 jmp @@Exit

@@LessThen45:
 xor edx,0
 jns @@Positive
 mov cx,-1
 jmp @@6_
@@Positive:
 mov cx,1
@@6_:
 add edi,edx
 add y1,cx
 mov ax,d
 cmp ax,0
 js @@4_
 inc edi
 add ax,aincr
 jmp @@5_
@@4_:
 add ax,bincr
@@5_:
 mov d,ax
 xor byte ptr [edi],bl

 mov ax,y2
 cmp ax,y1
 jne @@6_
 jmp @@Exit

@@Vertical:
 mov ax,y1
 cmp ax,y2
 jbe @@7
 mov bx,y2
 mov y1,bx
 mov y2,ax
@@7:
 mov edi,_FrameBuffer
 movzx eax,y1
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x1
 add eax,edx
 add edi,eax
 mov al,Color
 mov cx,y2
 sub cx,y1
 inc ecx
 mov dx,_LogicalScreenWidth
@@8:
 xor byte ptr [edi],al
 add edi,edx
 loop @@8

@@Exit:
end;

procedure _XORMaskedLine(x1,y1,x2,y2:word;Color:byte;Mask:word);assembler;
var d,_dx,_dy,aincr,bincr,yincr:smallint;
asm
 mov ax,x1
 cmp ax,x2
 je @@Vertical
 jbe @@1
 mov bx,x2
 mov x1,bx
 mov x2,ax
 mov ax,y1
 mov bx,y2
 mov y1,bx
 mov y2,ax
@@1:
 mov cx,_LogicalScreenWidth
 mov ax,y1
 mov bx,y2
 cmp bx,ax
 ja @@2
 neg cx
@@2:
 mov yincr,cx
 sub bx,ax
 jns @@3
 neg bx
@@3:
 mov _dy,bx
 mov ax,x2
 sub ax,x1
 mov _dx,ax
 cmp ax,bx
 jb @@45
 shl bx,1
 mov bincr,bx
 sub bx,ax
 mov d,bx
 mov ax,_dy
 sub ax,_dx
 jmp @@Continue
@@45:
 shl ax,1
 mov bincr,ax
 sub ax,bx
 mov d,ax
 mov ax,_dx
 sub ax,_dy
@@Continue:
 sal ax,1
 mov aincr,ax

 movzx edx,_LogicalScreenWidth
 movzx eax,y1
 mul edx
 mov edi,_FrameBuffer
 add edi,eax
 mov dx,x1
 add edi,edx
 mov bl,Color
 rol Mask,1
 jnc @@Skip1stPix
 xor byte ptr [edi],bl
@@Skip1stPix:

 movsx edx,yincr
 mov ax,_dx
 cmp ax,_dy
 jb @@LessThen45

@@6:
 inc edi
 inc x1
 mov ax,d
 cmp ax,0
 js @@4
 add edi,edx
 add ax,aincr
 jmp @@5
@@4:
 add ax,bincr
@@5:
 mov d,ax
 rol Mask,1
 jnc @@SkipPix
 xor byte ptr [edi],bl
@@SkipPix:

 mov ax,x2
 cmp ax,x1
 ja @@6
 jmp @@Exit

@@LessThen45:
 xor edx,0
 jns @@Positive
 mov cx,-1
 jmp @@6_
@@Positive:
 mov cx,1
@@6_:
 add edi,edx
 add y1,cx
 mov ax,d
 cmp ax,0
 js @@4_
 inc edi
 add ax,aincr
 jmp @@5_
@@4_:
 add ax,bincr
@@5_:
 mov d,ax
 rol Mask,1
 jnc @@SkipPix_
 xor byte ptr [edi],bl
@@SkipPix_:

 mov ax,y2
 cmp ax,y1
 jne @@6_
 jmp @@Exit

@@Vertical:
 mov ax,y1
 cmp ax,y2
 jbe @@7
 mov bx,y2
 mov y1,bx
 mov y2,ax
@@7:
 mov edi,_FrameBuffer
 movzx eax,y1
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x1
 add eax,edx
 add edi,eax
 mov al,Color
 mov cx,y2
 sub cx,y1
 inc ecx
 mov dx,_LogicalScreenWidth
@@8:
 rol Mask,1
 jnc @@SkipPix__
 xor byte ptr [edi],al
@@SkipPix__:
 add edi,edx
 loop @@8

@@Exit:
end;

procedure _XORHLine(x1,x2,y:smallint;Color:byte);assembler;
asm
 cld
 mov edi,_FrameBuffer      (* edi points to linear framebuffer *)
 movzx eax,y
 movzx ecx,_LogicalScreenWidth  (* ecx <- screen width *)
 mul ecx                        (* eax <- y*_LogicalScreenWidth *)
 mov dx,x1
 add eax,edx                    (* eax <- pixel offset *)
 add edi,eax                    (* edi points to first pixel address *)
 mov al,Color
 mov ah,al
 mov ebx,eax
 shl eax,16
 mov ax,bx                      (* eax now filled with color *)
 mov cx,x2
 sub cx,dx
 inc ecx                        (* cx contains number of pixels to fill *)
 mov ebx,ecx
 shr ecx,2
 jecxz @@2
@@1:
 xor [edi],eax
 add edi,4           (* fill line *)
 loop @@1
 mov ecx,ebx
 and ecx,3
@@2:
 jecxz @@exit
 xor byte ptr [edi],al
 inc edi             (* fill the rest of line if there is one *)
 loop @@2
@@exit:
end;

procedure _XORVLine(x,y1,y2:smallint;Color:byte);assembler;
asm
 mov edi,_FrameBuffer      (* edi points to linear framebuffer *)
 movzx eax,y1              (* eax <- y *)
 movzx ecx,_LogicalScreenWidth  (* ecx <- screen width *)
 mul ecx                        (* eax <- y*_LogicalScreenWidth *)
 mov dx,x
 add eax,edx                    (* eax <- pixel offset *)
 add edi,eax                    (* edi points to first pixel address *)
 mov al,Color                   (* al <- color *)
 mov cx,y2
 sub cx,y1
 inc ecx                        (* cx <- number of pixels *)
 jecxz @@exit
 mov dx,_LogicalScreenWidth
@@1:
 xor byte ptr [edi],al          (* fill line *)
 add edi,edx
 loop @@1
@@exit:
end;

procedure _XORRectangle(x1,y1,x2,y2:word;Color:byte);assembler;
asm
 mov edi,_FrameBuffer
 movzx eax,y1
 movzx edx,_LogicalScreenWidth
 mul edx
 mov dx,x1
 add eax,edx
 add edi,eax
 xor ecx,ecx
 mov cx,x2
 sub cx,dx
 mov al,Color
 mov ah,al
 mov ebx,eax
 shl eax,16
 mov ax,bx
 inc ecx
 mov ebx,ecx
 shr ecx,2
 jecxz @@2
@@1:
 xor [edi],eax
 add edi,4
 loop @@1
 mov ecx,ebx
 and ecx,3
@@2:
 jecxz @@21
 xor byte ptr [edi],al
 inc edi
 loop @@2
@@21:
 movzx ebx,x2
 sub bx,x1
 mov dx,_LogicalScreenWidth
 sub edx,ebx
 dec edx           (* dx <- (screen width)-((pixels per line)-1)-1 *)
 dec ebx           (* bx <- (pixels per line)-2 *)
 mov cx,y2         (* cx <- (number of lines)-2 *)
 sub cx,y1
 jz @@Exit
 dec ecx
 jz @@DrawBottom
@@3:               (* draw vertical sides *)
 add edi,edx
 xor byte ptr [edi],al
 inc edi
 add edi,ebx
 xor byte ptr [edi],al
 inc edi
 loop @@3
@@DrawBottom:
 add edi,edx       (* draw bottom line *)
 inc ebx
 inc ebx
 mov ecx,ebx
 shr ecx,2
 jecxz @@5
@@4:
 xor [edi],eax
 add edi,4
 loop @@4
 mov ecx,ebx
 and ecx,3
@@5:
 jecxz @@exit
 xor byte ptr [edi],al
 inc edi
 loop @@5
@@Exit:
end;

procedure _XORBar(x1,y1,x2,y2:word;Color:byte);assembler;
asm
 mov edi,_FrameBuffer
 movzx eax,y1
 movzx ecx,_LogicalScreenWidth
 mul ecx
 add edi,eax
 mov cx,x1
 add edi,ecx
 mov al,Color
 mov ah,al
 mov ebx,eax
 shl eax,16
 mov ax,bx
 mov bx,x2
 sub bx,x1
 inc ebx                         (* bx <- (pixels per line) *)
 mov dx,_LogicalScreenWidth
 sub edx,ebx
@@1:
 mov ecx,ebx
 shr ecx,2
 jecxz @@3
@@2:
 xor [edi],eax
 add edi,4
 loop @@2
 mov ecx,ebx
 and ecx,3
@@3:
 jecxz @@31
 xor byte ptr [edi],al
 inc edi
 loop @@3
@@31:
 add edi,edx
 inc y1
 mov cx,y2
 cmp cx,y1                      (* repeat while y1<=y2 *)
 jns @@1
end;

procedure _XOREllipse(xc,yc,rx,ry:word;Color:byte);
begin
 Ellipse(xc,yc,rx,ry,Color,_XORPixel,_XORVLine,_XORHLine);
end;

procedure _XORFilledEllipse(xc,yc,rx,ry:word;Color:byte);
begin
 FilledEllipse(xc,yc,rx,ry,Color,_XORVLine,_XORHLine);
end;

procedure _XORTriangle(x1,y1,x2,y2,x3,y3:word;Color:byte);
begin
 _XORLine(x1,y1,x2,y2,Color);
 _XORLine(x2,y2,x3,y3,Color);
 _XORLine(x3,y3,x1,y1,Color);
end;

procedure _XORFillTriangle(x1,y1,x2,y2,x3,y3:word;Color:byte);
begin
 FillTriangle(x1,y1,x2,y2,x3,y3,Color,@_XORHLine);
end;

procedure _XORFillPoly(var VertexArray;NumOfVertexes,Color:byte);
type TVertex=record
      x,y:smallint;
     end;
     TVertexArray=array[1..256] of TVertex;
begin
 if NumOfVertexes=1 then begin
  _XORPixel(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,color);
  Exit;
 end;
 if NumOfVertexes=2 then begin
  _XORLine(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,
      TVertexArray(VertexArray)[2].x,TVertexArray(VertexArray)[2].y,
      color);
  Exit;
 end;
 repeat
  _XORFillTriangle(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,
              TVertexArray(VertexArray)[NumOfVertexes-1].x,TVertexArray(VertexArray)[NumOfVertexes-1].y,
              TVertexArray(VertexArray)[NumOfVertexes].x,TVertexArray(VertexArray)[NumOfVertexes].y,
              Color);
  Dec(NumOfVertexes);
 until NumOfVertexes=2;
end;


(****************************************************************************

                     Drawing stuff with clipping

****************************************************************************)

procedure __PutPixel(x,y:smallint;Color:byte);
begin
 if (x>=_MinClipX) and
    (x<=_MaxClipX) and
    (y>=_MinClipY) and
    (y<=_MaxClipY) then _PutPixel(x,y,Color);
end;

procedure __PutTransparentPixel(x,y:smallint;Color:byte);
begin
 if (x>=_MinClipX) and
    (x<=_MaxClipX) and
    (y>=_MinClipY) and
    (y<=_MaxClipY) then _PutTransparentPixel(x,y,Color);
end;

function  __GetPixel(x,y:smallint):byte;
begin
 if (x>=_MinClipX) and
    (x<=_MaxClipX) and
    (y>=_MinClipY) and
    (y<=_MaxClipY) then __GetPixel:=_GetPixel(x,y)
 else __GetPixel:=0;
end;


procedure xchange(var a,b:smallint);
var c:smallint;
begin
 c:=a;a:=b;b:=c;
end;

function OutCode(x,y:smallint):smallint;
var code:smallint;
begin
 code:=0;
 if x<_MinClipX then code:=(code or 1);
 if y<_MinClipY then code:=(code or 2);
 if x>_MaxClipX then code:=(code or 4);
 if y>_MaxClipY then code:=(code or 8);
 OutCode:=code;
end;

function ClipLine(var x1,y1,x2,y2:smallint):boolean;

(* This is Sutherland - Cohen clipping algorithm *)

var code1,code2:smallint;
    inside,outside:boolean;
begin
 code1:=OutCode(x1,y1);
 code2:=OutCode(x2,y2);
 inside:=(code1 or code2)=0;
 outside:=(code1 and code2)<>0;
 while (not inside) and (not outside) do begin
  if code1=0 then begin
   xchange(x1,x2);
   xchange(y1,y2);
   xchange(code1,code2);
  end;
  if (code1 and 1)<>0 then begin
   y1:=y1+longint(y2-y1)*(_MinClipX-x1) div (x2-x1);
   x1:=_MinClipX;
  end else
  if (code1 and 2)<>0 then begin
   x1:=x1+longint(x2-x1)*(_MinClipY-y1) div (y2-y1);
   y1:=_MinClipY;
  end else
  if (code1 and 4)<>0 then begin
   y1:=y1+longint(y2-y1)*(_MaxClipX-x1) div (x2-x1);
   x1:=_MaxClipX;
  end else
  if (code1 and 8)<>0 then begin
   x1:=x1+longint(x2-x1)*(_maxClipY-y1) div (y2-y1);
   y1:=_MaxClipY;
  end;
  code1:=OutCode(x1,y1);
  code2:=OutCode(x2,y2);
  inside:=(code1 or code2)=0;
  outside:=(code1 and code2)<>0;
 end;
 ClipLine:=(not outside);
end;

procedure __Line(x1,y1,x2,y2:smallint;Color:byte);
begin
 if ClipLine(x1,y1,x2,y2) then _Line(x1,y1,x2,y2,Color);
end;

procedure __MaskedLine(x1,y1,x2,y2:smallint;Color:byte;Mask:word);
var MaskShift:word;
begin
 if x1<_MinClipX then MaskShift:=(_MinClipX-x1) mod 16 else MaskShift:=0;
 if ClipLine(x1,y1,x2,y2) then _MaskedLine(x1,y1,x2,y2,Color,Mask shl MaskShift);
end;

procedure __HLine(x1,x2,y:smallint;Color:byte);
begin
 if (y<_MinClipY) or
    (y>_MaxClipY) or
    (x1>_MaxClipX) or
    (x2<_MinClipX) then Exit;
 if x1<_MinClipX then x1:=_MinClipX;
 if x2>_MaxClipX then x2:=_MaxClipX;
 _HLine(x1,x2,y,Color);
end;

procedure __VLine(x,y1,y2:smallint;Color:byte);
begin
 if (x<_MinClipX) or
    (x>_MaxClipX) or
    (y1>_MaxClipY) or
    (y2<_MinClipY) then Exit;
 if y1<_MinClipY then y1:=_MinClipY;
 if y2>_MaxClipY then y2:=_MaxClipY;
 _VLine(x,y1,y2,Color);
end;

procedure __Rectangle(x1,y1,x2,y2:smallint;Color:byte);
begin
 __HLine(x1,x2,y1,Color);
 __VLine(x1,y1,y2,Color);
 __VLine(x2,y1,y2,Color);
 __HLine(x1,x2,y2,Color);
end;

procedure __Bar(x1,y1,x2,y2:smallint;Color:byte);
begin
 if (x1>_MaxClipX) or
    (y1>_MaxClipY) or
    (x2<_MinClipX) or
    (y2<_MinClipY) then Exit;
 if x1<_MinClipX then x1:=_MinClipX;
 if y1<_MinClipY then y1:=_MinClipY;
 if x2>_MaxClipX then x2:=_MaxClipX;
 if y2>_MaxClipY then Y2:=_MaxClipY;
 _Bar(x1,y1,x2,y2,Color);
end;

procedure __Ellipse(xc,yc,rx,ry:smallint;Color:byte);
begin
 Ellipse(xc,yc,rx,ry,Color,__PutPixel,__VLine,__HLine);
end;

procedure __FilledEllipse(xc,yc,rx,ry:smallint;Color:byte);
begin
 FilledEllipse(xc,yc,rx,ry,Color,__VLine,__HLine);
end;

procedure __Triangle(x1,y1,x2,y2,x3,y3:smallint;Color:byte);
begin
 __Line(x1,y1,x2,y2,Color);
 __Line(x2,y2,x3,y3,Color);
 __Line(x3,y3,x1,y1,Color);
end;

procedure __FillTriangle(x1,y1,x2,y2,x3,y3:smallint;Color:byte);
begin
 FillTriangle(x1,y1,x2,y2,x3,y3,Color,@__HLine);
end;

procedure __FillPoly(var VertexArray;NumOfVertexes,Color:byte);
type TVertex=record
      x,y:smallint;
     end;
     TVertexArray=array[1..256] of TVertex;
begin
 if NumOfVertexes=1 then begin
  __PutPixel(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,color);
  Exit;
 end;
 if NumOfVertexes=2 then begin
  __Line(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,
      TVertexArray(VertexArray)[2].x,TVertexArray(VertexArray)[2].y,
      color);
  Exit;
 end;
 repeat
  __FillTriangle(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,
          TVertexArray(VertexArray)[NumOfVertexes-1].x,TVertexArray(VertexArray)[NumOfVertexes-1].y,
          TVertexArray(VertexArray)[NumOfVertexes].x,TVertexArray(VertexArray)[NumOfVertexes].y,
          color);
  Dec(NumOfVertexes);
 until NumOfVertexes=2;
end;

procedure __XORPixel(x,y:smallint;Color:byte);
begin
 if (x>=_MinClipX) and
    (x<=_MaxClipX) and
    (y>=_MinClipY) and
    (y<=_MaxClipY) then _XORPixel(x,y,Color);
end;

procedure __XORTransparentPixel(x,y:smallint;Color:byte);
begin
 if (x>=_MinClipX) and
    (x<=_MaxClipX) and
    (y>=_MinClipY) and
    (y<=_MaxClipY) then _XORTransparentPixel(x,y,Color);
end;

procedure __XORLine(x1,y1,x2,y2:smallint;Color:byte);
begin
 if ClipLine(x1,y1,x2,y2) then _XORLine(x1,y1,x2,y2,Color);
end;

procedure __XORMaskedLine(x1,y1,x2,y2:smallint;Color:byte;Mask:word);
begin
 if ClipLine(x1,y1,x2,y2) then _XORMaskedLine(x1,y1,x2,y2,Color,Mask);
end;

procedure __XORHLine(x1,x2,y:smallint;Color:byte);
begin
 if (y<_MinClipY) or
    (y>_MaxClipY) or
    (x1>_MaxClipX) or
    (x2<_MinClipX) then Exit;
 if x1<_MinClipX then x1:=_MinClipX;
 if x2>_MaxClipX then x2:=_MaxClipX;
 _XORHLine(x1,x2,y,Color);
end;

procedure __XORVLine(x,y1,y2:smallint;Color:byte);
begin
 if (x<_MinClipX) or
    (x>_MaxClipX) or
    (y1>_MaxClipY) or
    (y2<_MinClipY) then Exit;
 if y1<_MinClipY then y1:=_MinClipY;
 if y2>_MaxClipY then y2:=_MaxClipY;
 _XORVLine(x,y1,y2,Color);
end;

procedure __XORRectangle(x1,y1,x2,y2:smallint;Color:byte);
begin
 __XORHLine(x1,x2,y1,Color);
 __XORVLine(x1,y1,y2,Color);
 __XORVLine(x2,y1,y2,Color);
 __XORHLine(x1,x2,y2,Color);
end;

procedure __XORBar(x1,y1,x2,y2:smallint;Color:byte);
begin
 if (x1>_MaxClipX) or
    (y1>_MaxClipY) or
    (x2<_MinClipX) or
    (y2<_MinClipY) then Exit;
 if x1<_MinClipX then x1:=_MinClipX;
 if y1<_MinClipY then y1:=_MinClipY;
 if x2>_MaxClipX then x2:=_MaxClipX;
 if y2>_MaxClipY then Y2:=_MaxClipY;
 _XORBar(x1,y1,x2,y2,Color);
end;

procedure __XOREllipse(xc,yc,rx,ry:smallint;Color:byte);
begin
 Ellipse(xc,yc,rx,ry,Color,__XORPixel,__XORVLine,__XORHLine);
end;

procedure __XORFilledEllipse(xc,yc,rx,ry:smallint;Color:byte);
begin
 FilledEllipse(xc,yc,rx,ry,Color,__XORVLine,__XORHLine);
end;

procedure __XORTriangle(x1,y1,x2,y2,x3,y3:smallint;Color:byte);
begin
 __XORLine(x1,y1,x2,y2,Color);
 __XORLine(x2,y2,x3,y3,Color);
 __XORLine(x3,y3,x1,y1,Color);
end;

procedure __XORFillTriangle(x1,y1,x2,y2,x3,y3:smallint;Color:byte);
begin
 FillTriangle(x1,y1,x2,y2,x3,y3,Color,@__XORHLine);
end;

procedure __XORFillPoly(var VertexArray;NumOfVertexes,Color:byte);
type TVertex=record
      x,y:smallint;
     end;
     TVertexArray=array[1..256] of TVertex;
begin
 if NumOfVertexes=1 then begin
  __XORPixel(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,color);
  Exit;
 end;
 if NumOfVertexes=2 then begin
  __XORLine(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,
       TVertexArray(VertexArray)[2].x,TVertexArray(VertexArray)[2].y,
       Color);
  Exit;
 end;
 repeat
  __XORFillTriangle(TVertexArray(VertexArray)[1].x,TVertexArray(VertexArray)[1].y,
               TVertexArray(VertexArray)[NumOfVertexes-1].x,TVertexArray(VertexArray)[NumOfVertexes-1].y,
               TVertexArray(VertexArray)[NumOfVertexes].x,TVertexArray(VertexArray)[NumOfVertexes].y,
               Color);
  Dec(NumOfVertexes);
 until NumOfVertexes=2;
end;


(****************************************************************************

                        Palette programming

****************************************************************************)

procedure _GetPalette(var Palette);assembler;
asm
 mov dx,$3C7
 xor al,al
 out dx,al
 mov edi,Palette
 inc dx
 inc dx
 mov ecx,768
 rep insb
end;

procedure _SetPalette(var Palette);assembler;
asm
 mov dx,$3DA
@@1:
 in al,dx
 test al,8
 jz @@1
 mov dx,$3C8
 xor al,al
 out dx,al
 mov esi,Palette
 inc dx
 mov ecx,768
 rep outsb
end;

type TPaletteArray=array[0..767] of byte;
     TRGBArray=array[0..255] of TRGB;

procedure _Fade(var StartPalette,EndPalette;Speed:single);

(* You need _big_ stack for this! At least 16 K must be available *)

var delta:array [0..767] of single;
    startrealpal,endrealpal:array [0..767] of single;
    currentpal:TPaletteArray;
    i,j:word;
begin
 for i:=0 to 767 do begin
  startrealpal[i]:=TPaletteArray(StartPalette)[i];
  currentpal[i]:=TPaletteArray(StartPalette)[i];
  endrealpal[i]:=TPaletteArray(EndPalette)[i];
  delta[i]:=(endrealpal[i]-startrealpal[i])/Speed;
 end;
 _SetPalette(StartPalette);
 for i:=1 to Trunc(Speed) do begin
  for j:=0 to 767 do begin
   startrealpal[j]+:=delta[j];
   currentpal[j]:=Round(startrealpal[j]);
  end;
  _SetPalette(currentpal);
 end;
end;

var StepWorkPalette:TPaletteArray;
    StepRealPal,StepDelta:array [0..767] of single;
    FadeSteps:word;

procedure _InitStepFade(var StartPalette,EndPalette;Speed:single);
var endrealpal:array [0..767] of single;
    i:word;
begin
 for i:=0 to 767 do begin
  StepRealPal[i]:=TPaletteArray(StartPalette)[i];
  StepWorkPalette[i]:=TPaletteArray(StartPalette)[i];
  endrealpal[i]:=TPaletteArray(EndPalette)[i];
  StepDelta[i]:=(endrealpal[i]-StepRealPal[i])/Speed;
 end;
 _SetPalette(StartPalette);
 FadeSteps:=Trunc(Speed);
end;

function  _StepFade:boolean;
const CurrentStep:word=0;
var j:word;
begin
(* Inc(CurrentStep);
 if CurrentStep>FadeSteps then begin
  CurrentStep:=FadeSteps+1;
  Result:=false;
  Exit;
 end
 else*) begin
  for j:=0 to 767 do begin
   StepRealPal[j]+:=StepDelta[j];
   StepWorkPalette[j]:=Round(StepRealPal[j]);
  end;
  _SetPalette(StepWorkPalette);
  Result:=true;
 end;
end;

procedure _SetRGB(Color,R,G,B:byte);assembler;
asm
 mov dx,$3C8
 mov al,Color
 out dx,al
 mov dx,$3C9
 mov al,R
 out dx,al
 mov al,G
 out dx,al
 mov al,B
 out dx,al
end;

procedure _GetRGB(Color:byte;var R,G,B:byte);assembler;
asm
 mov dx,$3C7
 mov al,Color
 out dx,al
 mov dx,$3C9
 mov edi,R
 in al,dx
 mov [edi],al
 mov edi,G
 in al,dx
 mov [edi],al
 mov edi,B
 in al,dx
 mov [edi],al
end;

procedure _Convert8bppcTo6bppc(var Palette);assembler;
asm
 mov esi,Palette
 mov edi,Palette
 mov ecx,768
@@1:
 lodsb
 shr al,2
 stosb
 loop @@1
end;

function  _RGB2YUV(RGB:TRGB):TYUV;
var Dummy:smallint;
begin
 with RGB do begin
  Result.Y:=Round(0.299*R+0.587*G+0.114*B);
  Dummy:=Round(0.1687*R-0.3313*G+0.5*B); if Dummy<0 then Dummy:=0;
  Result.U:=byte(Dummy);
  Dummy:=Round(0.5*R-0.4187*G+0.0813*B); if Dummy<0 then Dummy:=0;
  Result.V:=byte(Dummy);
 end;
end;

function  _YUV2RGB(YUV:TYUV):TRGB;
var Dummy:smallint;
begin
 with YUV do begin
  Dummy:=Round(0.894*Y-0.468*U+1.623*V);
  if Dummy<0 then Dummy:=0;
  if Dummy>63 then Dummy:=63;
  Result.R:=byte(dummy);
  Dummy:=Round(1.158*Y-0.16*U-0.638*V);
  if Dummy<0 then Dummy:=0;
  if Dummy>63 then Dummy:=63;
  Result.G:=byte(Dummy);
  Dummy:=Round(0.466*Y+2.052*U-0.971*V);
  if Dummy<0 then Dummy:=0;
  if Dummy>63 then Dummy:=63;
  Result.B:=byte(Dummy);
 end;
end;

procedure _GammaCorrect(var Palette;Gamma:single);
var i:byte;
    tempy:single;
    YUV:TYUV;
begin
 if Gamma<0.5 then Gamma:=0.5;
 if Gamma>2 then Gamma:=2;
 for i:=0 to 255 do begin
  YUV:=_RGB2YUV(TRGBArray(Palette)[i]);
  tempy:=YUV.Y;
  if tempy<=63 then tempy:=Exp(Gamma*Ln(tempy+1))-1;
  if tempy<0 then tempy:=0;
  if tempy>63 then tempy:=63;
  YUV.Y:=Round(tempy);
  TRGBArray(Palette)[i]:=_YUV2RGB(YUV);
 end;
end;

procedure _GammaCorrectRGB(var Palette;Gamma:single);
var i:byte;
    temp:single;
begin
 if Gamma<0.5 then Gamma:=0.5;
 if Gamma>2 then Gamma:=2;
 for i:=0 to 255 do begin
  temp:=TRGBArray(Palette)[i].R;
  if temp<=63 then temp:=Exp(Gamma*Ln(temp+1))-1;
  if temp<0 then temp:=0;
  if temp>63 then temp:=63;
  TRGBArray(Palette)[i].R:=Round(temp);
  temp:=TRGBArray(Palette)[i].G;
  if temp<=63 then temp:=Exp(Gamma*Ln(temp+1))-1;
  if temp<0 then temp:=0;
  if temp>63 then temp:=63;
  TRGBArray(Palette)[i].G:=Round(temp);
  temp:=TRGBArray(Palette)[i].B;
  if temp<=63 then temp:=Exp(Gamma*Ln(temp+1))-1;
  if temp<0 then temp:=0;
  if temp>63 then temp:=63;
  TRGBArray(Palette)[i].B:=Round(temp);
 end;
end;


(****************************************************************************

        Get image / put image and other bitmap manipulations

****************************************************************************)

procedure _GetImage(x,y,Width,Height:word;Address:pointer);assembler;
asm
 cmp Height,0
 je @@Exit
 mov esi,_FrameBuffer
 movzx eax,y
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x
 add eax,edx
 add esi,eax

 mov dx,_LogicalScreenWidth
 sub dx,Width
 mov edi,Address

 movzx ebx,Width
@@1:
 mov ecx,ebx
 shr ecx,2
 rep movsd
 mov ecx,ebx
 and ecx,3
 rep movsb              (* moved one line *)
 add esi,edx            (* set to next line begin *)
 dec Height             (* all lines already? *)
 jnz @@1
@@Exit:
end;

procedure _PutImage(x,y,Width,Height:word;Address:pointer);assembler;
asm
 cmp Height,0
 je @@Exit
 mov edi,_FrameBuffer
 movzx eax,y
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x
 add eax,edx
 add edi,eax                    (* edi now contains offset of image start *)

 mov dx,_LogicalScreenWidth
 sub dx,Width
 mov esi,Address                (* esi - source address *)

 movzx ebx,Width
@@1:
 mov ecx,ebx
 shr ecx,2
 rep movsd
 mov ecx,ebx
 and ecx,3
 rep movsb                      (* moved one line *)
 add edi,edx                    (* set to next line begin *)
 dec Height                     (* all lines already? *)
 jnz @@1
@@Exit:
end;

procedure _PutTransparentImage(x,y,Width,Height:word;Address:pointer);assembler;
asm
 cmp Height,0
 je @@Exit
 mov edi,_FrameBuffer
 movzx eax,y
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x
 add eax,edx
 add edi,eax                    (* edi now contains offset of image start *)

 mov dx,_LogicalScreenWidth
 sub dx,Width
 mov ah,_TransparentColor
 mov esi,Address                (* esi - source address *)

@@1:
 mov cx,Width
@@3:
 lodsb
 cmp al,ah                      (* if transparent color *)
 je @@2                         (* then don't put it *)
 mov [edi],al
@@2:
 inc edi
 loop @@3
 add edi,edx                    (* set to next line begin *)
 dec Height                     (* all lines already? *)
 jnz @@1
@@Exit:
end;

procedure _XORImage(x,y,Width,Height:word;Address:pointer);assembler;
asm
 cmp Height,0
 je @@Exit
 mov edi,_FrameBuffer
 movzx eax,y
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x
 add eax,edx
 add edi,eax                    (* edi now contains offset of image start *)

 mov dx,_LogicalScreenWidth
 sub dx,Width
 mov esi,Address                (* esi - source address *)

@@1:
 mov cx,Width
@@3:
 mov bl,[esi]
 inc esi
 xor byte ptr [edi],bl
 inc edi
 loop @@3
 add edi,edx                    (* set to next line begin *)
 dec Height                     (* all lines already? *)
 jnz @@1
@@Exit:
end;


procedure __GetImage(x,y:smallint;Width,Height:word;Address:pointer);assembler;

(* Address must point to zero- (or whatever is needed) filled buffer *)

var TopCut,LeftCut,RightCut,OldWidth:dword;
asm
 cmp Height,0
 je @@Exit
 mov TopCut,0
 mov LeftCut,0
 mov RightCut,0
 movzx eax,Width
 mov OldWidth,eax

 mov ax,y
 cmp ax,_MaxClipY
 jg @@Exit
 cmp ax,_MinClipY
 jge @@1
                (* if cut at top *)
 mov bx,_MinClipY
 mov y,bx
 sub bx,ax
 mov word ptr TopCut,bx
 sub Height,bx
@@1:
 mov ax,y
 add ax,Height
 dec ax
 cmp ax,_MinClipY
 jl @@Exit
 cmp ax,_MaxClipY
 jle @@2
                (* if cut at bottom *)
 mov bx,_MaxClipY
 sub bx,y
 inc bx
 mov Height,bx
@@2:
 mov ax,x
 cmp ax,_MaxClipX
 jg @@Exit
 cmp ax,_MinClipX
 jge @@3
                (* if cut at left side *)
 mov bx,_MinClipX
 mov x,bx
 sub bx,ax
 mov word ptr LeftCut,bx
 sub Width,bx
@@3:
 mov ax,x
 add ax,Width
 dec ax
 cmp ax,_MinClipX
 jl @@Exit
 cmp ax,_MaxClipX
 jle @@4
                (* if cut at right side *)
 mov bx,_MaxClipX
 sub bx,x
 inc bx
 mov Width,bx
 sub ax,_MaxClipX
 mov word ptr RightCut,ax
@@4:

 mov esi,_FrameBuffer
 movzx eax,y
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x
 add eax,edx
 add esi,eax                    (* esi now contains offset of image start *)

 mov edi,Address                (* edi is destination buffer address *)
 mov eax,TopCut
 mul OldWidth
 add edi,eax
 add edi,LeftCut
 mov eax,LeftCut
 add eax,RightCut
 mov dx,_LogicalScreenWidth
 sub dx,Width

 movzx ebx,Width
@@5:
 mov ecx,ebx
 shr ecx,2
 rep movsd
 mov ecx,ebx
 and ecx,3
 rep movsb                      (* moved one line *)
 add esi,edx                    (* set to next line begin *)
 add edi,eax
 dec Height                     (* all lines already? *)
 jnz @@5

@@Exit:
end;


procedure __PutImage(x,y:smallint;Width,Height:word;Address:pointer);assembler;
var TopCut,LeftCut,RightCut,OldWidth:dword;
asm
 cmp Height,0
 je @@Exit
 mov TopCut,0
 mov LeftCut,0
 mov RightCut,0
 movzx eax,Width
 mov OldWidth,eax

 mov ax,y
 cmp ax,_MaxClipY
 jg @@Exit
 cmp ax,_MinClipY
 jge @@1
                (* if cut at top *)
 mov bx,_MinClipY
 mov y,bx
 sub bx,ax
 mov word ptr TopCut,bx
 sub Height,bx
@@1:
 mov ax,y
 add ax,Height
 dec ax
 cmp ax,_MinClipY
 jl @@Exit
 cmp ax,_MaxClipY
 jle @@2
                (* if cut at bottom *)
 mov bx,_MaxClipY
 sub bx,y
 inc bx
 mov Height,bx
@@2:
 mov ax,x
 cmp ax,_MaxClipX
 jg @@Exit
 cmp ax,_MinClipX
 jge @@3
                (* if cut at left side *)
 mov bx,_MinClipX
 mov x,bx
 sub bx,ax
 mov word ptr LeftCut,bx
 sub Width,bx
@@3:
 mov ax,x
 add ax,Width
 dec ax
 cmp ax,_MinClipX
 jl @@Exit
 cmp ax,_MaxClipX
 jle @@4
                (* if cut at right side *)
 mov bx,_MaxClipX
 sub bx,x
 inc bx
 mov Width,bx
 sub ax,_MaxClipX
 mov word ptr RightCut,ax
@@4:

 mov edi,_FrameBuffer
 movzx eax,y
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x
 add eax,edx
 add edi,eax            (* edi now contains offset of image start *)

 mov esi,Address
 mov eax,TopCut
 mul OldWidth
 add esi,eax
 add esi,LeftCut
 mov eax,LeftCut
 add eax,RightCut
 mov dx,_LogicalScreenWidth
 sub dx,Width

 movzx ebx,Width
@@5:
 mov ecx,ebx
 shr ecx,2
 rep movsd
 mov ecx,ebx
 and ecx,3
 rep movsb              (* moved one line *)
 add edi,edx            (* set to next line begin *)
 add esi,eax
 dec Height             (* all lines already? *)
 jnz @@5

@@Exit:
end;

procedure __PutTransparentImage(x,y:smallint;Width,Height:word;Address:pointer);assembler;
var TopCut,LeftCut,RightCut,OldWidth:dword;
asm
 cmp Height,0
 je @@Exit
 mov TopCut,0
 mov LeftCut,0
 mov RightCut,0
 movzx eax,Width
 mov OldWidth,eax

 mov ax,y
 cmp ax,_MaxClipY
 jg @@Exit
 cmp ax,_MinClipY
 jge @@1
                (* if cut at top *)
 mov bx,_MinClipY
 mov y,bx
 sub bx,ax
 mov word ptr TopCut,bx
 sub Height,bx
@@1:
 mov ax,y
 add ax,Height
 dec ax
 cmp ax,_MinClipY
 jl @@Exit
 cmp ax,_MaxClipY
 jle @@2
                (* if cut at bottom *)
 mov bx,_MaxClipY
 sub bx,y
 inc bx
 mov Height,bx
@@2:
 mov ax,x
 cmp ax,_MaxClipX
 jg @@Exit
 cmp ax,_MinClipX
 jge @@3
                (* if cut at left side *)
 mov bx,_MinClipX
 mov x,bx
 sub bx,ax
 mov word ptr LeftCut,bx
 sub Width,bx
@@3:
 mov ax,x
 add ax,Width
 dec ax
 cmp ax,_MinClipX
 jl @@Exit
 cmp ax,_MaxClipX
 jle @@4
                (* if cut at right side *)
 mov bx,_MaxClipX
 sub bx,x
 inc bx
 mov Width,bx
 sub ax,_MaxClipX
 mov word ptr RightCut,ax
@@4:

 mov edi,_FrameBuffer
 movzx eax,y
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x
 add eax,edx
 add edi,eax                    (* edi now contains offset of image start *)

 mov bh,_TransparentColor
 mov esi,Address                (* esi - source address *)
 mov eax,TopCut
 mul OldWidth
 add esi,eax
 add esi,LeftCut                (* esi - source address + clipped offset *)
 mov eax,LeftCut
 add eax,RightCut
 mov dx,_LogicalScreenWidth
 sub dx,Width

@@5:
 mov cx,Width
@@7:
 mov bl,[esi]
 inc esi
 cmp bl,bh              (* if transparent color *)
 je @@6                 (* then don't put it *)
 mov [edi],bl
@@6:
 inc edi
 loop @@7
 add edi,edx            (* set to next line begin *)
 add esi,eax
 dec Height             (* all lines already? *)
 jnz @@5

@@Exit:
end;

procedure __XORImage(x,y:smallint;Width,Height:word;Address:pointer);assembler;
var TopCut,LeftCut,RightCut,OldWidth:dword;
asm
 cmp Height,0
 je @@Exit
 mov TopCut,0
 mov LeftCut,0
 mov RightCut,0
 movzx eax,Width
 mov OldWidth,eax

 mov ax,y
 cmp ax,_MaxClipY
 jg @@Exit
 cmp ax,_MinClipY
 jge @@1
                (* if cut at top *)
 mov bx,_MinClipY
 mov y,bx
 sub bx,ax
 mov word ptr TopCut,bx
 sub Height,bx
@@1:
 mov ax,y
 add ax,Height
 dec ax
 cmp ax,_MinClipY
 jl @@Exit
 cmp ax,_MaxClipY
 jle @@2
                (* if cut at bottom *)
 mov bx,_MaxClipY
 sub bx,y
 inc bx
 mov Height,bx
@@2:
 mov ax,x
 cmp ax,_MaxClipX
 jg @@Exit
 cmp ax,_MinClipX
 jge @@3
                (* if cut at left *)
 mov bx,_MinClipX
 mov x,bx
 sub bx,ax
 mov word ptr LeftCut,bx
 sub Width,bx
@@3:
 mov ax,x
 add ax,Width
 dec ax
 cmp ax,_MinClipX
 jl @@Exit
 cmp ax,_MaxClipX
 jle @@4
                (* if cut at right *)
 mov bx,_MaxClipX
 sub bx,x
 inc bx
 mov Width,bx
 sub ax,_MaxClipX
 mov word ptr RightCut,ax
@@4:

 mov edi,_FrameBuffer
 movzx eax,y
 movzx ecx,_LogicalScreenWidth
 mul ecx
 mov dx,x
 add eax,edx
 add edi,eax                    (* edi now contains offset of image start *)

 mov esi,Address                (* esi - source address *)
 mov eax,TopCut
 mul OldWidth
 add esi,eax
 add esi,LeftCut                (* esi - source address + clipped offset *)
 mov eax,LeftCut
 add eax,RightCut
 mov dx,_LogicalScreenWidth
 sub dx,Width

@@5:
 mov cx,Width
@@7:
 mov bl,[esi]
 inc esi
 xor byte ptr [edi],bl
 inc edi
 loop @@7
 add edi,edx                    (* set to next line begin *)
 add esi,eax
 dec Height                     (* all lines already? *)
 jnz @@5

@@Exit:
end;


(****************************************************************************

                        Working with files

****************************************************************************)

type T_PCX_Header=packed record
 Signature:byte;
 Version:byte;
 Encoding:byte;
 BPP:byte;
 XMin,YMin,XMax,YMax:word;
 XResolution:word;
 YResolution:word;
 Palette:array[0..47] of byte;
 Reserved1:byte;
 Planes:byte;
 BPL:word;
 PaletteDescriptor:word;
 PPIx:word;
 PPIy:word;
 Reserved2:array[0..53] of byte;
end;

function  _PCX_Display(FileName:string;FileOffset:dword;x,y:word):smallint;
var InCounter,OutCounter:word;
    i,LineCounter:word;
    Header:T_PCX_Header;
    Dummy:longint;
    Count,Data:byte;
    f:file;
begin
 Assign(f,FileName);
 {$I-}
 Reset(f,1);
 if IOResult<>0 then begin
  _PCX_Display:=UNABLE_OPEN_FILE;
  Exit;
 end;
 {$I+}
 Seek(f,FileOffset);
 BlockRead(f,Header,128);
 with Header do
  if (Signature<>$0A) or (BPP<>8) or (Planes<>1) then begin
   _PCX_Display:=INVALID_FILE_FMT;
   Close(f);
   Exit;
  end;
 if (Header.XMax-Header.XMin+1)>4096 then begin
  _PCX_Display:=IMAGE_WIDTH_TOOBIG;
  Close(f);
  Exit;
 end;
 InCounter:=1;OutCounter:=1;LineCounter:=0;
 BlockRead(f,_IO_Buffer,4096,Dummy);
 repeat
  if (_IO_Buffer[InCounter] and $C0)=$C0 then begin
   Count:=(_IO_Buffer[InCounter]) and $3F;
   Inc(InCounter);
   if InCounter=4097 then begin
    InCounter:=1;
    BlockRead(f,_IO_Buffer,4096,Dummy);
   end;
   Data:=_IO_Buffer[InCounter];
   Inc(InCounter);
   if InCounter=4097 then begin
    InCounter:=1;
    BlockRead(f,_IO_Buffer,4096,Dummy);
   end;
  end
  else begin
   Count:=1;
   Data:=_IO_Buffer[InCounter];
   Inc(InCounter);
   if InCounter=4097 then begin
    InCounter:=1;
    BlockRead(f,_IO_Buffer,4096,Dummy);
   end;
  end;
  for i:=1 to Count do begin
   _IO_Buffer[OutCounter+4096]:=Data;
   Inc(OutCounter);
   if OutCounter=Header.BPL+1 then begin
    OutCounter:=1;
    Inc(LineCounter);
    __PutImage(x,y,Header.XMax-Header.XMin+1,1,@_IO_Buffer[4097]);
    Inc(y);
   end;
  end;
 until LineCounter=Header.YMax-Header.YMin+1;
 Close(f);
 _PCX_Display:=0;
end;

function  _PCX_Buffer(FileName:string;FileOffset:dword;Address:pointer):smallint;
var InCounter,OutCounter:word;
    i,LineCounter:word;
    Header:T_PCX_Header;
    Dummy:longint;
    Count,Data:byte;
    f:file;
begin
 Assign(f,FileName);
 {$I-}
 Reset(f,1);
 if IOResult<>0 then begin
  _PCX_Buffer:=UNABLE_OPEN_FILE;
  Exit;
 end;
 {$I+}
 Seek(f,FileOffset);
 BlockRead(f,Header,128);
 with Header do
  if (Signature<>$0A) or (BPP<>8) or (Planes<>1) then begin
   _PCX_Buffer:=INVALID_FILE_FMT;
   Close(f);
   Exit;
  end;
 if (Header.XMax-Header.XMin+1)>4096 then begin
  _PCX_Buffer:=IMAGE_WIDTH_TOOBIG;
  Close(f);
  Exit;
 end;
 InCounter:=1;OutCounter:=1;LineCounter:=0;
 BlockRead(f,_IO_Buffer,4096,Dummy);
 repeat
  if (_IO_Buffer[InCounter] and $C0)=$C0 then begin
   Count:=(_IO_Buffer[InCounter]) and $3F;
   Inc(InCounter);
   if InCounter=4097 then begin
    InCounter:=1;
    BlockRead(f,_IO_Buffer,4096,Dummy);
   end;
   Data:=_IO_Buffer[InCounter];
   Inc(InCounter);
   if InCounter=4097 then begin
    InCounter:=1;
    BlockRead(f,_IO_Buffer,4096,Dummy);
   end;
  end
  else begin
   Count:=1;
   Data:=_IO_Buffer[InCounter];
   Inc(InCounter);
   if InCounter=4097 then begin
    InCounter:=1;
    BlockRead(f,_IO_Buffer,4096,Dummy);
   end;
  end;
  for i:=1 to Count do begin
   _IO_Buffer[OutCounter+4096]:=Data;
   Inc(OutCounter);
   if OutCounter=Header.BPL+1 then begin
    OutCounter:=1;
    Inc(LineCounter);
    Move(_IO_Buffer[4097],Address^,Header.XMax-Header.XMin+1);
    Address:=Pointer(dword(Address)+Header.XMax-Header.XMin+1);
   end;
  end;
 until LineCounter=Header.YMax-Header.YMin+1;
 Close(f);
 _PCX_Buffer:=0;
end;

function  _SavePCX(FileName:string;x1,y1,x2,y2:word):smallint;
var Header:T_PCX_Header;
    Palette256:array[-1..767] of byte;
    f:file;
    Len,i,InPos,OutPos:word;
    Data,Count:byte;
begin
 Len:=x2-x1+1;
 if Len>4096 then begin
  _SavePCX:=IMAGE_WIDTH_TOOBIG;
  Exit;
 end;
 _GetPalette(Palette256[0]);
 for i:=0 to 767 do Palette256[i]:=round(Palette256[i]*255/63);
 Palette256[-1]:=$0C;
 with Header do begin
  Signature:=$0A;
  Version:=5;
  Encoding:=1;
  BPP:=8;
  XMin:=x1;
  YMin:=y1;
  XMax:=x2;
  YMax:=y2;
  PPIx:=Round(_XResolution/11);
  PPIy:=Round(_YResolution/8.5);
  for i:=0 to 47 do Palette[i]:=Palette256[i];
  Reserved1:=0;
  Planes:=1;
  BPL:=Len; if Odd(BPL) then Inc(BPL);
  PaletteDescriptor:=1;
  XResolution:=_XResolution;
  YResolution:=_YResolution;
  for i:=0 to 53 do Reserved2[i]:=0;
 end;
 Assign(f,FileName);
 {$I-}
 Rewrite(f,1);
 if IOResult<>0 then begin
  _SavePCX:=UNABLE_REWRITE_FILE;
  Exit;
 end;
 {$I+}
 BlockWrite(f,Header,128);
 OutPos:=1;
 for i:=y1 to y2 do begin
  _GetImage(x1,i,Len,1,@_IO_Buffer);
  InPos:=1;
  repeat
   Data:=_IO_Buffer[InPos];Count:=1;
   Inc(InPos);
   repeat
    if InPos=Header.BPL+1 then break;
    if _IO_Buffer[InPos]=Data then begin
     Inc(Count);
     Inc(InPos);
    end
    else break;
   until Count=63;
   if (Count>1) or ((Data and $C0)=$C0) then begin
    _IO_Buffer[OutPos+4096]:=($C0 or Count); Inc(OutPos);
    if OutPos=4097 then begin OutPos:=1; BlockWrite(f,_IO_Buffer[4097],4096); end;
   end;
   _IO_Buffer[OutPos+4096]:=Data; Inc(OutPos);
   if OutPos=4097 then begin OutPos:=1; BlockWrite(f,_IO_Buffer[4097],4096); end;
   if InPos=Header.BPL+1 then break;
  until false;
 end;
 if OutPos>1 then BlockWrite(f,_IO_Buffer[4097],OutPos-1);
 BlockWrite(f,Palette256[-1],769);
 Close(f);
end;

function _Get_PCX_Palette(FileName:string;var Palette):smallint;
var f:file;
    Test:byte;
    i:word;
type TPalette=array[0..767] of byte;
begin
 Assign(f,FileName);
 {$I-}
 Reset(f,1);
 if IOResult<>0 then begin
  _Get_PCX_Palette:=UNABLE_OPEN_FILE;
  Exit;
 end;
 {$I+}
 if FileSize(f)<(769+SizeOf(T_PCX_Header)) then begin
  _Get_PCX_Palette:=INVALID_FILE_FMT;
  Close(f);
  Exit;
 end;
 Seek(f,FileSize(f)-769);
 BlockRead(f,Test,1);
 if Test<>$0C then begin
  _Get_PCX_Palette:=INVALID_FILE_FMT;
  Close(f);
  Exit;
 end;
 BlockRead(f,Palette,768);
 for i:=0 to 767 do TPalette(Palette)[i]:=round(TPalette(Palette)[i]*63/255);
 Close(f);
 _Get_PCX_Palette:=0;
end;

function  _Get_PCX_Size(FileName:string;FileOffset:dword;var PicSize:TWindow):smallint;
var Header:T_PCX_Header;
    f:file;
begin
 Assign(f,FileName);
 {$I-}
 Reset(f,1);
 if IOResult<>0 then begin
  Result:=UNABLE_OPEN_FILE;
  Exit;
 end;
 {$I+}
 Seek(f,FileOffset);
 BlockRead(f,Header,128);
 with Header do
  if (Signature<>$0A) or (BPP<>8) or (Planes<>1) then begin
   Result:=INVALID_FILE_FMT;
   Close(f);
   Exit;
  end;
 PicSize.MinX:=Header.XMin;
 PicSize.MinY:=Header.YMin;
 PicSize.MaxX:=Header.XMax;
 PicSize.MaxY:=Header.YMax;
 Close(f); Result:=0;
end;


(****************************************************************************

                             Miscellaneous

****************************************************************************)

procedure _SetWindow(ClipWindow:TWindow);
begin
 with ClipWindow do begin
  _MinClipX:=MinX;
  _MinClipY:=MinY;
  _MaxClipX:=MaxX;
  _MaxClipY:=MaxY;
 end;
end;

procedure _SetTextmode;assembler;
asm
 mov ax,3
 int $10
 mov _Mode,0
end;

procedure _Terminate(Message:string;Code:word);
begin
 _SetTextMode;
 WriteLn(Message);
 Halt(Code);
end;

procedure _Fill(Color:byte);
begin
 FillChar(_Framebuffer^,
          dword(_LogicalScreenWidth)*_LogicalScreenHeight,
          char(Color));
end;

procedure _WaitForVSync;assembler;
asm
 mov dx,$3DA
@@0:
 in al,dx
 test al,8
 jnz @@0
@@1:
 in al,dx
 test al,8
 jz @@1
end;

procedure _WaitForVSyncStart;assembler;
asm
 mov dx,$3DA
@@1:
 in al,dx
 test al,8
 jz @@1
end;

function Copyleft_Id:string;
begin
 Copyleft_Id:=Copyleft;
end;


(****************************************************************************

                        Virtual display control

****************************************************************************)

function  _SetLogicalWidth(NewWidth:word):smallint;
begin
 if _Mode=19 then begin
  _SetLogicalWidth:=INVALID_MODE;
  Exit;
 end;
 if (dword(NewWidth)*_LogicalScreenHeight)>
  (dword(_VideoMemory) shl 10) then begin
  _SetLogicalWidth:=INVALID_LOG_WIDTH;
  Exit;
 end;
 asm
  mov ax,$4F06
  xor bl,bl
  mov cx,NewWidth
  int $10
  cmp ax,$004F
  jne @@error
  mov _LogicalScreenWidth,cx
  dec cx
  mov _FullScreen.MaxX,cx
  mov _LogicalScreenHeight,dx
  dec dx
  mov _FullScreen.MaxY,dx
  xor ax,ax
  jmp @@Exit
 @@error:
  mov ax,UNABLE_SET_WIDTH
 @@Exit:
 end;
end;

function  _SetDisplayOrigin(x,y:word):smallint;assembler;
asm
 mov ax,$4F07
 mov bx,$0080
 mov cx,x
 mov dx,y
 int $10
 cmp ax,$004F
 jne @@error
 mov _OriginX,cx
 mov _OriginY,dx
 xor ax,ax
 jmp @@Exit
@@error:
 mov ax,UNABLE_SET_ORIGIN
@@Exit:
end;


(****************************************************************************

                        Virtual screens control

****************************************************************************)

procedure _SetVirtualOutput(Address:pointer);
begin
 _Framebuffer:=Address;
end;

procedure _FlushVirtualScreen(Address:pointer);
begin
 Move(Address^,_ModeList[_ModeIndex].BufferAddress^,
     dword(_LogicalScreenWidth)*_LogicalScreenHeight);
end;

procedure _MoveToVirtualScreen(Address:pointer);
begin
 Move(_ModeList[_ModeIndex].BufferAddress^,Address^,
     dword(_LogicalScreenWidth)*_LogicalScreenHeight);
end;

procedure _SetNormalOutput;
begin
 _Framebuffer:=_ModeList[_ModeIndex].BufferAddress;
end;


(****************************************************************************

                        Fonts and text handling

****************************************************************************)

type TFont=array[0..255,0..15] of byte;

procedure _SetFont(Font:pointer);
begin
 _Font:=Font;
end;

procedure _WriteTransparentText(x,y:word;S:string;Color:byte);
var i,j:byte;
begin
 if _Font=nil then Exit;
 for i:=1 to Length(S) do begin
  for j:=0 to 15 do
   _MaskedLine(x,y+j,x+7,y+j,Color,word(TFont(_Font^)[Ord(S[i]),j]) shl 8);
  Inc(x,8);
 end;
end;

procedure __WriteTransparentText(x,y:word;S:string;Color:byte);
var i,j:byte;
begin
 if _Font=nil then Exit;
 for i:=1 to Length(S) do begin
  for j:=0 to 15 do
   __MaskedLine(x,y+j,x+7,y+j,Color,word(TFont(_Font^)[Ord(S[i]),j]) shl 8);
  Inc(x,8);
 end;
end;

procedure _WriteOverlappedText(x,y:word;S:string;Color,BkColor:byte);
var i,j:byte;
begin
 if _Font=nil then Exit;
 for i:=1 to Length(S) do begin
  for j:=0 to 15 do begin
   _HLine(x,x+7,y+j,BkColor);
   _MaskedLine(x,y+j,x+7,y+j,Color,word(TFont(_Font^)[Ord(S[i]),j]) shl 8);
  end;
  Inc(x,8);
 end;
end;

procedure __WriteOverlappedText(x,y:word;S:string;Color,BkColor:byte);
var i,j:byte;
begin
 if _Font=nil then Exit;
 for i:=1 to Length(S) do begin
  for j:=0 to 15 do begin
   __HLine(x,x+7,y+j,BkColor);
   __MaskedLine(x,y+j,x+7,y+j,Color,word(TFont(_Font^)[Ord(S[i]),j]) shl 8);
  end;
  Inc(x,8);
 end;
end;

(****************************************************************************

                             Finalization

****************************************************************************)
var OldExit:pointer;

procedure LFB256_ExitProc;
begin
 ExitProc:=OldExit;
 if _GraphicsSysInited and (_NumberOfModes>=1) then
  FreePhysicalMap(dword(_ModeList[1].BufferAddress));
 if _Mode<>0 then _SetTextMode;
end;

(****************************************************************************

                            Initialization

****************************************************************************)

begin
 Copyleft:=#13+#10+' SuperVGA library Version '+Version+'.DPMI32'+#13+#10+
           ' Virtual Research independent group production (C) 1998-1999'+#13+#10;
 _FrameBuffer:=nil;
 _Font:=nil;
 _Mode:=0;
 OldExit:=ExitProc;
 ExitProc:=@LFB256_ExitProc;
end.

