{ --------------------------------------------------------------------------- }
{ - VersaVision Video Driver (Video.pas)                                    - }
{ - Integrant part of VersaVision Framework                                 - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Video;

interface

const
  { 80x25 screen coordinates }
  k80x25Left               = 1;
  k80x25Top                = 1;
  k80x25Width              = 80;
  k80x25Height             = 25;

  { general VGA constants }
  kVGAColumnCount          = 80;
  kVGARowCount             = 25;
  kVGAChAtSize             = 2;
  kVGARAMSize              = 4000;
  kVGAChWidth              = 8;
  kVGAChHeight             = 16;

  { VGA color constants }
  clBlack                  = 0;
  clBlue                   = 1;
  clGreen                  = 2;
  clCyan                   = 3;
  clRed                    = 4;
  clMagenta                = 5;
  clBrown                  = 6;
  clLightGray              = 7;
  clDarkGray               = 8;
  clLightBlue              = 9;
  clLightGreen             = 10;
  clLightCyan              = 11;
  clLightRed               = 12;
  clLightMagenta           = 13;
  clYellow                 = 14;
  clWhite                  = 15;

  { VGA Palette color constants }
  clVGAPaletteBlack        = 0;
  clVGAPaletteBlue         = 1;
  clVGAPaletteGreen        = 2;
  clVGAPaletteCyan         = 3;
  clVGAPaletteRed          = 4;
  clVGAPaletteMagenta      = 5;
  clVGAPaletteBrown        = 20;
  clVGAPaletteLightGray    = 7;
  clVGAPaletteDarkGray     = 56;
  clVGAPaletteLightBlue    = 57;
  clVGAPaletteLightGreen   = 58;
  clVGAPaletteLightCyan    = 59;
  clVGAPaletteLightRed     = 60;
  clVGAPaletteLightMagenta = 61;
  clVGAPaletteYellow       = 62;
  clVGAPaletteWhite        = 63;

  { VGA Palette constants }
  kVGAPaletteStart         = 0;
  kVGAPaletteEnd           = 15;
  kVGAPaletteIndex: array[kVGAPaletteStart..kVGAPaletteEnd] of Byte = (
    clVGAPaletteBlack,
    clVGAPaletteBlue,
    clVGAPaletteGreen,
    clVGAPaletteCyan,
    clVGAPaletteRed,
    clVGAPaletteMagenta,
    clVGAPaletteBrown,
    clVGAPaletteLightGray,
    clVGAPaletteDarkGray,
    clVGAPaletteLightBlue,
    clVGAPaletteLightGreen,
    clVGAPaletteLightCyan,
    clVGAPaletteLightRed,
    clVGAPaletteLightMagenta,
    clVGAPaletteYellow,
    clVGAPaletteWhite
  );

type
  TGlyphData = array[0..kVGAChHeight] of Byte;

  TPaletteColor = record
    RIntensity: Byte;
    GIntensity: Byte;
    BIntensity: Byte;
  end;

  PVideoRAMData = ^TVideoRAMData;
  TVideoRAMData = array[1..kVGARAMSize] of Byte;

  TVideoArea = record
    PositionX: Byte;
    PositionY: Byte;
    Width: Byte;
    Height: Byte;
  end;

  PVideoSection = ^TVideoSection;
  TVideoSection = array[1..1] of Byte;

procedure VideoInitialize(var APositionY: Byte; var AVideoRAMData: PVideoRAMData);
procedure VideoFinalize(var APositionY: Byte; var AVideoRAMData: PVideoRAMData);

procedure VideoGetGlyphData(const AIndex: Byte; var AGlyphData: TGlyphData);
procedure VideoSetGlyphData(const AIndex: Byte; const AGlyphData: TGlyphData);

procedure VideoGetPaletteColor(const AIndex: Byte; var APaletteColor: TPaletteColor);
procedure VideoSetPaletteColor(const AIndex: Byte; const APaletteColor: TPaletteColor);

procedure VideoEnableHighColors;
procedure VideoDisableHighColors;

procedure VideoEnableCursor;
procedure VideoDisableCursor;

procedure VideoClearScreen;
procedure VideoGetScreen(var AVideoRAMData: PVideoRAMData);
procedure VideoSetScreen(const AVideoRAMData: PVideoRAMData);

procedure VideoGetSection(var AVideoSection: PVideoSection; const AVideoArea: TVideoArea);
procedure VideoSetSection(var AVideoSection: PVideoSection; const AVideoArea: TVideoArea);

function VideoAttribute(const AForeground, ABackground: Byte): Byte;

procedure VideoWriteAttrAt(const ALeft, ATop, AAttribute: Byte);
procedure VideoWriteCharAt(const ALeft, ATop: Byte; const ACharacter: Char);
procedure VideoWriteCharAttrAt(const ALeft, ATop: Byte; const ACharacter: Char; const AAttribute: Byte);
procedure VideoWriteRegion(const ALeft, ATop, AWidth, AHeight: Byte; const ACharacter: Char; const AAttribute: Byte);
procedure VideoHighlightRegion(const ALeft, ATop, AWidth, AHeight: Byte; const AAttribute: Byte);
procedure VideoWriteStringAt(const ALeft, ATop: Byte; const AString: String; const AForeground, ABackground: Byte);
procedure VideoWriteNewln;

procedure VideoWrite(const AString: String);
procedure VideoWriteln(const AString: String);

procedure VideoSetForeground(const AColor: Byte);
procedure VideoSetBackground(const AColor: Byte);

procedure VideoGotoXY(const APositionX, APositionY: Byte);
function VideoWhereX: Byte;
function VideoWhereY: Byte;

implementation

const
  kVGARAMStartOffset    = $0000;
  kVGARAMAddress        = $B800;

  { Color Attributes }
  caDefaultAttribute    = $07;

  kEmptySpace           = ' ';

var
  IGForeground: Byte;
  IGBackground: Byte;

{ public declarations }

procedure VideoInitialize(var APositionY: Byte; var AVideoRAMData: PVideoRAMData);
begin
  APositionY := VideoWhereY;

  GetMem(AVideoRAMData, kVGARAMSize);
  VideoGetScreen(AVideoRAMData);
  VideoClearScreen;
  VideoEnableHighColors;
  VideoDisableCursor;
end;

procedure VideoFinalize(var APositionY: Byte; var AVideoRAMData: PVideoRAMData);
begin
  VideoEnableCursor;
  VideoDisableHighColors;
  VideoSetScreen(AVideoRAMData);
  FreeMem(AVideoRAMData, kVGARAMSize);

  VideoGotoXY(k80x25Left, APositionY);
end;

procedure VideoGetGlyphData(const AIndex: Byte; var AGlyphData: TGlyphData); assembler;
asm
  push bp
  push ds

  les di,[AGlyphData]

  push es
  push di

  xor ah,ah
  mov al,AIndex

  push ax

  mov ax,1130h
  mov bh,06h
  int 10h

  pop ax

  mov bx,cx
  mul bx

  push es
  pop ds

  mov si,bp
  add si,ax

  pop di
  pop es

  cld

  rep movsb

  pop ds
  pop bp
end;

procedure VideoSetGlyphData(const AIndex: Byte; const AGlyphData: TGlyphData); assembler;
asm
  push bp

  mov ax,1100h
  mov bh,kVGAChHeight
  xor bl,bl
  mov cx,01h
  xor dh,dh
  mov dl,AIndex

  les di,[AGlyphData]
  mov bp,di
  int 10h

  pop bp
end;

procedure VideoGetPaletteColor(const AIndex: Byte; var APaletteColor: TPaletteColor); assembler;
asm
  mov dx,03C6h
  mov al,0FFh
  out dx,al

  mov dx,03C7h
  mov al,AIndex
  out dx,al

  mov dx,03C9h
  les di,[APaletteColor]

  mov cx,03h

@getColor:
  in al,dx
  mov es:[di],al
  inc di

  loop @getColor
end;

procedure VideoSetPaletteColor(const AIndex: Byte; const APaletteColor: TPaletteColor); assembler;
asm
  push ds

  mov dx,03C6h
  mov al,0FFh
  out dx,al

  mov dx,03C8h
  mov al,AIndex
  out dx,al

  mov dx,03C9h
  les si,[APaletteColor]

  mov cx,03h

@setColor:
  mov al,es:[si]
  out dx,al
  inc si

  loop @setColor

  pop ds
end;

procedure VideoEnableHighColors; assembler;
asm
  mov ax,1003h
  xor bx,bx
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
  mov ax,kVGARAMAddress
  mov es,ax

  xor di,di
  mov ah,caDefaultAttribute
  mov al,kEmptySpace
  mov cx,2000

  cld

  rep stosw
end;

procedure VideoGetScreen(var AVideoRAMData: PVideoRAMData);
begin
  if Assigned(AVideoRAMData) then
  begin
    Move(
      Mem[kVGARAMAddress : kVGARAMStartOffset],
      AVideoRAMData^,
      kVGARAMSize
    );
  end;
end;

procedure VideoSetScreen(const AVideoRAMData: PVideoRAMData);
begin
  if Assigned(AVideoRAMData) then
  begin
    Move(
      AVideoRAMData^,
      Mem[kVGARAMAddress : kVGARAMStartOffset],
      kVGARAMSize
    );
  end;
end;

procedure VideoGetSection(var AVideoSection: PVideoSection; const AVideoArea: TVideoArea);
var
  LHeight: Integer;
  LVideoSectionSize: Integer;
  LVideoAreaWidthSize: Byte;

begin
  LVideoSectionSize := AVideoArea.Width * AVideoArea.Height * 2;
  LVideoAreaWidthSize := AVideoArea.Width * 2;

  GetMem(AVideoSection, LVideoSectionSize);

  for LHeight := 0 to Pred(AVideoArea.Height) do
  begin
    Move(
      Mem[kVGARAMAddress : ((AVideoArea.PositionY + LHeight) * kVGAColumnCount + Pred(AVideoArea.PositionX)) * 2],
      AVideoSection^,
      LVideoAreaWidthSize
    );

    Inc(AVideoSection, LVideoAreaWidthSize);
  end;

  Dec(AVideoSection, LVideoSectionSize);
end;

procedure VideoSetSection(var AVideoSection: PVideoSection; const AVideoArea: TVideoArea);
var
  LHeight: Integer;
  LVideoSectionSize: Integer;
  LVideoAreaWidthSize: Byte;

begin
  LVideoSectionSize := AVideoArea.Width * AVideoArea.Height * 2;
  LVideoAreaWidthSize := AVideoArea.Width * 2;

  for LHeight := 0 to Pred(AVideoArea.Height) do
  begin
    Move(
      AVideoSection^,
      Mem[kVGARAMAddress : ((AVideoArea.PositionY + LHeight) * kVGAColumnCount + Pred(AVideoArea.PositionX)) * 2],
      LVideoAreaWidthSize
    );

    Inc(AVideoSection, LVideoAreaWidthSize);
  end;

  Dec(AVideoSection, LVideoSectionSize);

  FreeMem(AVideoSection, LVideoSectionSize);
end;

function VideoAttribute(const AForeground, ABackground: Byte): Byte; assembler;
asm
  xor ah,ah
  mov al,ABackground
  mov cl,04h
  shl al,cl
  add al,AForeground
end;

procedure VideoWriteAttrAt(const ALeft, ATop, AAttribute: Byte); assembler;
asm
  mov ax,kVGARAMAddress
  mov es,ax

  xor ah,ah
  mov al,ATop
  dec al

  xor bh,bh
  mov bl,kVGAColumnCount
  mul bx

  shl ax,01h

  xor dh,dh
  mov dl,ALeft
  shl dx,01h
  dec dx

  add ax,dx
  mov di,ax

  mov al,AAttribute

  cld

  stosb
end;

procedure VideoWriteCharAt(const ALeft, ATop: Byte; const ACharacter: Char); assembler;
asm
  mov ax,kVGARAMAddress
  mov es,ax

  xor ah,ah
  mov al,ATop
  dec al

  xor bh,bh
  mov bl,kVGAColumnCount
  mul bx

  shl ax,01h

  xor dh,dh
  mov dl,ALeft
  shl dx,01h
  dec dx
  dec dx

  add ax,dx
  mov di,ax

  mov al,ACharacter

  cld

  stosb
end;

procedure VideoWriteCharAttrAt(const ALeft, ATop: Byte; const ACharacter: Char; const AAttribute: Byte); assembler;
asm
  mov ax,kVGARAMAddress
  mov es,ax

  xor ah,ah
  mov al,ATop
  dec al

  xor bh,bh
  mov bl,kVGAColumnCount
  mul bx

  shl ax,01h

  xor dh,dh
  mov dl,ALeft
  shl dx,01h
  dec dx
  dec dx

  add ax,dx
  mov di,ax

  mov ah,AAttribute
  mov al,ACharacter

  cld

  stosw
end;

procedure VideoWriteRegion(const ALeft, ATop, AWidth, AHeight: Byte; const ACharacter: Char;
  const AAttribute: Byte); assembler;
asm
  mov ax,kVGARAMAddress
  mov es,ax

  xor ch,ch

  cld

@calculatePosition:
  xor ah,ah
  mov al,ATop
  dec al
  add al,ch

  xor bh,bh
  mov bl,kVGAColumnCount
  mul bx

  shl ax,01h

  xor dh,dh
  mov dl,ALeft
  shl dx,01h
  dec dx
  dec dx

  add ax,dx
  mov di,ax

  mov ah,AAttribute
  mov al,ACharacter

  push cx

  xor ch,ch
  mov cl,AWidth

  rep stosw

  pop cx

  inc ch
  cmp ch,AHeight
  jnz @calculatePosition
end;

procedure VideoHighlightRegion(const ALeft, ATop, AWidth, AHeight: Byte; const AAttribute: Byte); assembler;
asm
  mov ax,kVGARAMAddress
  mov es,ax

  xor ch,ch

  cld

@calculatePosition:
  xor ah,ah
  mov al,ATop
  dec al
  add al,ch

  xor bh,bh
  mov bl,kVGAColumnCount
  mul bx

  shl ax,01h

  xor dh,dh
  mov dl,ALeft
  shl dx,01h
  dec dx
  dec dx

  add ax,dx
  mov di,ax

  mov ah,AAttribute

  mov cl,AWidth

@nextPosition:
  dec cl

  mov al,es:[di]

  stosw

  or cl,cl
  jnz @nextPosition

  inc ch
  cmp ch,AHeight
  jnz @calculatePosition
end;

procedure VideoWriteStringAt(const ALeft, ATop: Byte; const AString: String; const AForeground, ABackground: Byte); assembler;
asm
  push ds

  xor ah,ah
  mov al,ATop
  dec al

  mov cl,05h
  shl ax,cl
  mov di,ax
  mov cl,02h
  shl ax,cl
  add di,ax

  xor ah,ah
  mov al,ALeft
  dec al
  shl al,01h
  add di,ax

  mov ax,kVGARAMAddress
  mov es,ax

  mov ah,ABackground
  mov cl,04h
  shl ah,cl
  add ah,AForeground

  lds si,[AString]

  cld

  lodsb

  xor ch,ch
  mov cl,al
  jcxz @exit

@nextByte:
  lodsb

  stosw

  loop @nextByte

@exit:
  pop ds
end;

procedure VideoWriteNewln; assembler;
asm
  jmp @start

@@moveCursor:
  mov ah,02h
  xor bh,bh
  int 10h

  retn

@start:
  mov ah,03h
  xor bh,bh
  int 10h

  xor dl,dl

  cmp dh,kVGARowCount - 1
  jz @scrollUp
  inc dh

  call @@moveCursor

  jmp @exit

@scrollUp:
  call @@moveCursor

  mov ah,08h
  int 10h
  mov bh,ah

  mov ah,06h
  mov al,01h
  xor cx,cx
  mov dh,kVGARowCount
  dec dh
  mov dl,kVGAColumnCount
  dec dl
  int 10h

@exit:

end;

procedure VideoWrite(const AString: String); assembler;
asm
  jmp @start

@@moveCursor:
  push ax

  mov ah,02h
  xor bh,bh
  int 10h

  pop ax

  retn

@@calculatePosition:
  push ax
  push cx
  push dx

  mov cx,dx

  xor ah,ah
  mov al,ch
  xor bh,bh
  mov bl,kVGAColumnCount
  mul bx
  shl ax,01h
  xor dh,dh
  mov dl,cl
  shl dx,01h
  add ax,dx

  mov di,ax

  pop dx
  pop cx
  pop ax

  retn

@start:
  push ds

  mov ah,03h
  xor bh,bh
  int 10h

  mov ax,kVGARAMAddress
  mov es,ax

  mov ah,IGBackground
  mov cl,04h
  shl ah,cl
  add ah,IGForeground

  lds si,[AString]

  cld

  lodsb

  xor ch,ch
  mov cl,al
  jmp @checkLastByte

@getPosition:
  dec cx

@checkLastByte:
  jcxz @exit

  call @@calculatePosition

@nextByte:
  lodsb

  cmp al,13
  jz @carriageReturn
  cmp al,10
  jz @lineFeed

  stosw

  inc dl

  loop @nextByte

  jmp @exit

@carriageReturn:
  xor dl,dl

  call @@moveCursor

  jmp @getPosition

@lineFeed:
  cmp dh,kVGARowCount - 1
  jz @scrollUp
  inc dh

  call @@moveCursor

  jmp @getPosition

@scrollUp:
  call @@moveCursor

  push ax
  push cx
  push dx

  mov ah,08h
  int 10h
  mov bh,ah

  mov ah,06h
  mov al,01h
  xor cx,cx
  mov dh,kVGARowCount
  dec dh
  mov dl,kVGAColumnCount
  dec dl
  int 10h

  pop dx
  pop cx
  pop ax

  jmp @getPosition

@exit:
  pop ds
end;

procedure VideoWriteln(const AString: String);
begin
  VideoWrite(AString);
  VideoWriteNewln;
end;

procedure VideoSetForeground(const AColor: Byte);
begin
  if IGForeground <> AColor then
  begin
    IGForeground := AColor;
  end;
end;

procedure VideoSetBackground(const AColor: Byte);
begin
  if IGBackground <> AColor then
  begin
    IGBackground := AColor;
  end;
end;

procedure VideoGotoXY(const APositionX, APositionY: Byte); assembler;
asm
  mov ah,02h
  xor bh,bh
  mov dl,APositionX
  dec dl
  mov dh,APositionY
  dec dh
  int 10h
end;

function VideoWhereX: Byte; assembler;
asm
  mov ah,03h
  xor bh,bh
  int 10h
  inc dl
  mov al,dl
end;

function VideoWhereY: Byte; assembler;
asm
  mov ah,03h
  xor bh,bh
  int 10h
  inc dh
  mov al,dh
end;

end.
