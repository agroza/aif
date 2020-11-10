{ --------------------------------------------------------------------------- }
{ - VersaVision Video Driver (Video.pas)                                    - }
{ - Integrant part of VersaVision Framework                                 - }
{ - Copyright (C) 1998-2020 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Video;

interface

const
  { 80x25 screen coordinates }
  k80x25Left            = 1;
  k80x25Top             = 1;
  k80x25Width           = 80;
  k80x25Height          = 25;

  kVGAColumnCount       = 80;
  kVGARowCount          = 25;
  kVGAChAtSize          = 2;
  kVGARAMSize           = 4000;

type
  PVideoRAMData = ^TVideoRAMData;
  TVideoRAMData = array[1..kVGARAMSize] of Byte;

procedure VideoEnableHighColors;
procedure VideoDisableHighColors;

procedure VideoEnableCursor;
procedure VideoDisableCursor;

procedure VideoClearScreen;
procedure VideoSaveScreen(const AVideoRAMData: PVideoRAMData);
procedure VideoRestoreScreen(const AVideoRAMData: PVideoRAMData);

function VideoAttribute(const AForeColor, ABackColor: Byte): Byte;

procedure VideoWriteAttrAt(const ALeft, ATop, AAttribute: Byte);
procedure VideoWriteCharAt(const ALeft, ATop: Byte; const ACharacter: Char);
procedure VideoWriteCharAttrAt(const ALeft, ATop: Byte; const ACharacter: Char; const AAttribute: Byte);

procedure VideoWriteStringAt(const ALeft, ATop: Word; const AString: String; const AForeColor, ABackColor: Byte);

procedure VideoWriteRegion(const ALeft, ATop, AWidth, AHeight: Byte; const ACharacter: Char; const AAttribute: Byte);
procedure VideoHighlightRegion(const ALeft, ATop, AWidth, AHeight: Byte; const AAttribute: Byte);

implementation

const
  kVGARAMStartOffset    = $0000;
  kVGARAMAddress        = $B800;

  { Color Attributes }
  caDefaultAttribute    = $07;

  kEmptySpace           = ' ';

{ public declarations }

procedure VideoEnableHighColors; assembler;
asm
  mov ax,1003h
  mov bx,0000h
  int 10h
end;

procedure VideoDisableHighColors; assembler;
asm
  mov ax,1003h
  mov bx,0001h
  int 10h
end;

procedure VideoEnableCursor; assembler;
asm
  mov ah,01h
  mov cx,0607h
  int 10h
end;

procedure VideoDisableCursor; assembler;
asm
  mov ah,01h
  mov ch,20h
  int 10h
end;

procedure VideoClearScreen; assembler;
asm
  push es

  mov ax,kVGARAMAddress
  mov es,ax
  xor di,di
  mov ah,caDefaultAttribute
  mov al,kEmptySpace
  mov cx,2000

  cld

  rep stosw

  pop es
end;

procedure VideoSaveScreen(const AVideoRAMData: PVideoRAMData);
begin
  if Assigned(AVideoRAMData) then
    Move(Mem[kVGARAMAddress:kVGARAMStartOffset], AVideoRAMData^, kVGARAMSize);
end;

procedure VideoRestoreScreen(const AVideoRAMData: PVideoRAMData);
begin
  if Assigned(AVideoRAMData) then
    Move(AVideoRAMData^, Mem[kVGARAMAddress:kVGARAMStartOffset], kVGARAMSize);
end;

function VideoAttribute(const AForeColor, ABackColor: Byte): Byte; assembler;
asm
  xor ah,ah
  mov al,ABackColor
  shl al,1
  shl al,1
  shl al,1
  shl al,1
  add al,AForeColor
end;

procedure VideoWriteAttrAt(const ALeft, ATop, AAttribute: Byte); assembler;
asm
  mov ax,kVGARAMAddress
  mov es,ax

  xor ah,ah
  mov al,ATop
  dec ax

  xor bh,bh
  mov bl,kVGAColumnCount
  mul bx

  shl ax,1

  xor dh,dh
  mov dl,ALeft
  shl dx,1
  dec dx

  add ax,dx
  mov di,ax

  mov al,AAttribute

  mov byte ptr [es:di],al
end;

procedure VideoWriteCharAt(const ALeft, ATop: Byte; const ACharacter: Char); assembler;
asm
  mov ax,kVGARAMAddress
  mov es,ax

  xor ah,ah
  mov al,ATop
  dec ax

  xor bh,bh
  mov bl,kVGAColumnCount
  mul bx

  shl ax,1

  xor dh,dh
  mov dl,ALeft
  shl dx,1
  dec dx
  dec dx

  add ax,dx
  mov di,ax

  mov al,ACharacter

  mov byte ptr [es:di],al
end;

procedure VideoWriteCharAttrAt(const ALeft, ATop: Byte; const ACharacter: Char; const AAttribute: Byte); assembler;
asm
  mov ax,kVGARAMAddress
  mov es,ax

  xor ah,ah
  mov al,ATop
  dec ax

  xor bh,bh
  mov bl,kVGAColumnCount
  mul bx

  shl ax,1

  xor dh,dh
  mov dl,ALeft
  shl dx,1
  dec dx
  dec dx

  add ax,dx
  mov di,ax

  mov ah,AAttribute
  mov al,ACharacter

  mov word ptr [es:di],ax
end;

procedure VideoWriteStringAt(const ALeft, ATop: Word; const AString: String; const AForeColor, ABackColor: Byte); assembler;
asm
  dec ALeft

  mov ax,ATop
  dec ax
  mov cl,5
  shl ax,cl
  mov di,ax
  mov cl,2
  shl ax,cl
  add di,ax
  shl ALeft,1
  add di,ALeft

  mov ax,kVGARAMAddress
  mov es,ax

  xor ch,ch
  push ds

  lds si,AString
  lodsb

  mov cl,al
  mov ah,ABackColor
  shl ah,1
  shl ah,1
  shl ah,1
  shl ah,1
  add ah,AForeColor
  jcxz @@done

@@writenext:
  lodsb
  stosw
  loop @@writenext

@@done:
  pop ds

end;

procedure VideoWriteRegion(const ALeft, ATop, AWidth, AHeight: Byte; const ACharacter: Char; const AAttribute: Byte);
var
  I: Byte;
  J: Byte;

begin
  for I := ALeft to Pred(ALeft + AWidth) do
    for J := ATop to Pred(ATop + AHeight) do
      VideoWriteCharAttrAt(I, J, ACharacter, AAttribute);
end;

procedure VideoHighlightRegion(const ALeft, ATop, AWidth, AHeight: Byte; const AAttribute: Byte);
var
  I: Byte;
  J: Byte;

begin
  for I := ALeft to Pred(ALeft + AWidth) do
    for J := ATop to Pred(ATop + AHeight) do
      VideoWriteAttrAt(I, J, AAttribute);
end;

end.
