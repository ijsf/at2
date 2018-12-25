//  This file is part of Adlib Tracker II (AT2).
//
//  AT2 is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  AT2 is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with AT2.  If not, see <http://www.gnu.org/licenses/>.

unit Adt2VESA;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

const
  VESA_640x480  = $101;
  VESA_800x600  = $103;
  VESA_1024x768 = $105;

const
  VESA_GraphicsSysInited: Boolean = FALSE;

type
  tModeInfo = Record
                ModeNumber: Word;
                XResolution: Word;
                YResolution: Word;
                BufferAddress: Pointer;
              end;
var
  VESA_NumberOfModes: Byte;         (* Total LFB videomodes supported *)
  VESA_FrameBuffer: Pointer;        (* LFB address for current mode *)
  VESA_ModeList: array[0..255] of tModeInfo;
  VESA_Version: Word;               (* VESA version *)
  VESA_OEM_String: String;          (* VESA OEM string *)
  VESA_Capabilities: Dword;         (* Hardware capabilities *)
  VESA_VideoMemory: Word;           (* Videomemory amount in Kb *)
  VESA_OEM_SoftwareRevision: Word;  (* VESA implementation revision *)
  VESA_OEM_VendorName: String;      (* VESA vendor name *)
  VESA_OEM_ProductName: String;     (* VESA OEM product name *)
  VESA_OEM_ProductRevision: String; (* VESA OEM product revision *)
  VESA_Mode: Word;                  (* Current videomode  *)
  VESA_ModeIndex: Byte;             (* Current mode index in VESA_ModeList  *)
  VESA_XResolution,                 (* Current X resolution *)
  VESA_YResolution: Word;           (* Current Y resolution *)

type
  tPaletteArray = array[0..767] of Byte;

var
  VESA_SegLFB: Word;
  StepWorkPalette: tPaletteArray;
  StepRealPal,StepDelta: array[0..767] of Single;
  FadeSteps: Word;

procedure VESA_Init;
function  VESA_SetMode(Mode: Word): Integer;
procedure VESA_GetPalette(var Palette);
procedure VESA_SetPalette(var Palette);
procedure VESA_InitStepFade(var StartPalette,EndPalette; Speed: Single);
procedure VESA_StepFade;
procedure VESA_SwitchBank(Bank: Byte);

implementation

uses
  GO32;

type
  tModeInfoBlock = Record
                     ModeAttributes: Word;
                     WinAAttributes: Byte;
                     WinBAttributes: Byte;
                     WinGranularity: Word;
                     WinSize: Word;
                     WinASegment: Word;
                     WinBSegment: Word;
                     WinFuncPtr: Pointer;
                     BytesPerScanLine: Word;
                     // VESA 1.2+ specific
                     XResolution: Word;
                     YResolution: Word;
                     XCharSize: Byte;
                     YCharSize: Byte;
                     NumberOfPlanes: Byte;
                     BitsPerPixel: Byte;
                     NumberOfBanks: Byte;
                     MemoryModel: Byte;
                     BankSize: Byte;
                     NumberOfImagePages: Byte;
                     Reserved1: Byte;
                     // direct color data
                     RedMaskSize: Byte;
                     RedFieldPosition: Byte;
                     GreenMaskSize: Byte;
                     GreenFieldPosition: Byte;
                     BlueMaskSize: Byte;
                     BlueFieldPosition: Byte;
                     RsvdMaskSize: Byte;
                     RsvdFieldPosition: Byte;
                     DirectColorModeInfo: Byte;
                     // VESA 2.0+ specific
                     PhysBasePtr: Pointer;
                     OffScreenMemOffset: Dword;
                     OffScreenMemSize: Word;
                     Reserved2: array[0..205] of Byte;
                   end;
type
  tModeList = array[0..127] of Word;
  tVESA_Info = Record
                 Signature: array[0..3] of Char;
                 Version: Word;
                 OEM_StringPtr: Dword;
                 Capabilities: Dword;
                 ModeListPtr: Dword;
                 VideoMemory: Word;
                 OEM_SoftwareRevision: Word;
                 OEM_VendorNamePtr: Dword;
                 OEM_ProductNamePtr: Dword;
                 OEM_ProductRevisionPtr: Dword;
                 Reserved: array[0..221] of Byte;
                 OEM_Data: array[0..255] of Byte;
               end;
var
  ModeList: tModeList;
  VESA_Info: tVESA_Info;
  ModeInfoBlock: tModeInfoBlock;

procedure VESA_Init;

var
  idx,idx2: Byte;
  regs: tRealRegs;
  dos_sel,dos_seg: Word;
  dos_mem_adr: Dword;

function GetVESAInfoStr(dpmiStrPtr: Dword): String;
begin
  GetVESAInfoStr := StrPas(PCHAR(POINTER(Ofs(VESA_Info)+WORD(dpmiStrPtr))));
end;

begin
  If VESA_GraphicsSysInited then EXIT;
  With VESA_ModeList[0] do
    begin
      ModeNumber := $13;
      XResolution := 320;
      YResolution := 200;
      BufferAddress := POINTER($A0000);
    end;

  dos_mem_adr := global_dos_alloc(SizeOf(tVESA_Info));
  dos_sel := WORD(dos_mem_adr);
  dos_seg := WORD(dos_mem_adr SHR 16);

  FillChar(VESA_Info,SizeOf(tVESA_Info),0);
  VESA_Info.Signature := 'VBE2';
  dosmemput(dos_seg,0,VESA_Info,4);

  regs.ax := $4f00;
  regs.ds := dos_seg;
  regs.es := dos_seg;
  regs.di := 0;
  RealIntr($10,regs);

  dosmemget(dos_seg,0,VESA_Info,SizeOf(tVESA_Info));
  global_dos_free(dos_sel);

  If (VESA_Info.Signature <> 'VESA') then
    EXIT; // ERROR: VESA BIOS extensions not found!
  VESA_Version := VESA_Info.Version;

  If (HI(VESA_Version) < 2) then
    EXIT; // ERROR: VESA 2.0 required!

  VESA_OEM_String := GetVESAInfoStr(VESA_Info.OEM_StringPtr);
  VESA_Capabilities := VESA_Info.Capabilities;
  VESA_VideoMemory := VESA_Info.VideoMemory SHL 6;
  VESA_OEM_SoftwareRevision := VESA_Info.OEM_SoftwareRevision;
  VESA_OEM_VendorName := GetVESAInfoStr(VESA_Info.OEM_VendorNamePtr);
  VESA_OEM_ProductName := GetVESAInfoStr(VESA_Info.OEM_ProductNamePtr);
  VESA_OEM_ProductRevision := GetVESAInfoStr(VESA_Info.OEM_ProductRevisionPtr);

  dpmi_dosmemget(WORD(VESA_Info.ModeListPtr SHR 16),
                 WORD(VESA_Info.ModeListPtr),
                 ModeList,
                 SizeOf(tModeList));

  dos_mem_adr := global_dos_alloc(SizeOf(tModeInfoBlock));
  dos_sel := WORD(dos_mem_adr);
  dos_seg := WORD(dos_mem_adr SHR 16);

  idx  := 0;
  idx2 := 1;

  Repeat
    regs.ax := $4f01;
    regs.cx := ModeList[idx];
    regs.ds := dos_seg;
    regs.es := dos_seg;
    regs.di := 0;
    RealIntr($10,regs);
    dosmemget(dos_seg,0,ModeInfoBlock,SizeOf(tModeInfoBlock));
    Inc(idx);
  until ((ModeInfoBlock.ModeAttributes AND $0091 = $0091) and
         (ModeInfoBlock.NumberOfPlanes = 1) and
         (ModeInfoBlock.BitsPerPixel = 8)) or (ModeList[idx-1] = $FFFF);

  If (ModeList[idx-1] <> $FFFF) then
    begin
      Inc(idx2);
      With VESA_ModeList[1] do
        begin
          ModeNumber := ModeList[idx-1];
          XResolution := ModeInfoBlock.XResolution;
          YResolution := ModeInfoBlock.YResolution;
          BufferAddress := ModeInfoBlock.PhysBasePtr;
        end;

      While (idx <= 127) and (ModeList[idx] <> $FFFF) do
        begin
          regs.ax := $4f01;
          regs.cx := ModeList[idx];
          regs.ds := dos_seg;
          regs.es := dos_seg;
          regs.di := 0;
          RealIntr($10,regs);
          dosmemget(dos_seg,0,ModeInfoBlock,SizeOf(tModeInfoBlock));
          If (ModeInfoBlock.ModeAttributes AND $0091 = $0091) and
             (ModeInfoBlock.NumberOfPlanes = 1) and
             (ModeInfoBlock.BitsPerPixel = 8) then
            begin
              With VESA_ModeList[idx2] do
                begin
                  ModeNumber := ModeList[idx];
                  XResolution := ModeInfoBlock.XResolution;
                  YResolution := ModeInfoBlock.YResolution;
                end;
              Inc(idx2);
            end;
          Inc(idx);
        end;
    end;

  global_dos_free(dos_sel);
  VESA_NumberOfModes := idx2-1;

  If (VESA_NumberOfModes >= 1) then
    begin
      VESA_ModeList[1].BufferAddress :=
        POINTER(DWORD(Get_Linear_Addr(DWORD(VESA_ModeList[1].BufferAddress),4096*1024)));
      If (VESA_ModeList[1].BufferAddress = NIL) then
        EXIT; // ERROR: Cannot remap LFB to linear address space!
      For idx := 2 to VESA_NumberOfModes do
        VESA_ModeList[idx].BufferAddress := VESA_ModeList[1].BufferAddress;
    end;

   VESA_Mode := 0;
  VESA_GraphicsSysInited := TRUE;
end;

function VESA_SetMode(Mode: Word): Integer;

var
  idx: Byte;
  result: Integer;

begin
  If NOT VESA_GraphicsSysInited then
    begin
      VESA_SetMode := -1;
      EXIT;
    end;

  VESA_ModeIndex := VESA_NumberOfModes+1;
  For idx := 0 to VESA_NumberOfModes do
    If (VESA_ModeList[idx].ModeNumber = Mode) then
      begin
        Write(VESA_ModeList[idx].ModeNumber,',');
        VESA_ModeIndex := idx;
        BREAK;
      end;

  If (VESA_ModeIndex = VESA_NumberOfModes+1) then
    begin
      VESA_SetMode := -1;
      EXIT;
    end;

  If (Mode <> 19) then Mode := Mode OR $4000;
  asm
      mov       ax,4f02h
      mov       bx,Mode
      int       10h
      mov       result,0
      cmp       ax,4fh
      je        @@1
      mov       result,-1
@@1:
  end;

  VESA_SetMode := result;
  If (result <> 0) then EXIT;

  VESA_Mode := Mode;
  VESA_XResolution := VESA_ModeList[VESA_ModeIndex].XResolution;
  VESA_YResolution := VESA_ModeList[VESA_ModeIndex].YResolution;
  VESA_Framebuffer := VESA_ModeList[VESA_ModeIndex].BufferAddress;
end;

procedure VESA_GetPalette(var Palette); assembler;
asm
        mov     dx,3c7h
        xor     al,al
        out     dx,al
        mov     edi,Palette
        inc     dx
        inc     dx
        mov     ecx,768
        rep     insb
end;

procedure VESA_SetPalette(var Palette); assembler;
asm
        mov     dx,3dah
@@1:    in      al,dx
        test    al,8
        jz      @@1
        mov     dx,3c8h
        xor     al,al
        out     dx,al
        mov     esi,Palette
        inc     dx
        mov     ecx,768
        rep     outsb
end;

procedure VESA_InitStepFade(var StartPalette,EndPalette; Speed: Single);

var
  EndRealPal: array[0..767] of Single;
  idx: Word;

begin
  For idx := 0 to 767 do
    begin
      StepRealPal[idx] := tPaletteArray(StartPalette)[idx];
      StepWorkPalette[idx] := tPaletteArray(StartPalette)[idx];
      EndRealPal[idx] := tPaletteArray(EndPalette)[idx];
      StepDelta[idx] := (EndRealPal[idx]-StepRealPal[idx])/Speed;
    end;
  VESA_SetPalette(StartPalette);
  FadeSteps := TRUNC(Speed);
end;

procedure VESA_StepFade;

var
  idx: Word;

begin
  For idx := 0 to 767 do
    begin
      StepRealPal[idx] := StepRealPal[idx]+StepDelta[idx];
      StepWorkPalette[idx] := ROUND(StepRealPal[idx]);
    end;
  VESA_SetPalette(StepWorkPalette);
end;

procedure VESA_SwitchBank(Bank: Byte);

var
  regs: tRealRegs;
  granularity: Byte;

begin
  regs.ax := $4f05;
  regs.bx := 0;
  Case ModeInfoBlock.WinGranularity of
    32: granularity := 5;
    16: granularity := 4;
     8: granularity := 3;
     4: granularity := 2;
     2: granularity := 1;
     1: granularity := 0;
  end;
  regs.dx := bank SHL granularity;
  RealIntr($10,regs);
end;

end.
