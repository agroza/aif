{ --------------------------------------------------------------------------- }
{ - Audio Interface - Routines (routines.pas)                               - }
{ - Copyright (C) 1998-2020 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Routines;

interface

procedure Delay(const ADuration: Word);

function GetBit(const AByte, ABit: Byte): Boolean;
procedure SetBit(var AByte: Byte; const ABit: Byte; const AValue: Boolean);

function LocateByte(const AValue: Byte; const AArray: array of Byte): Byte;
function LocateWord(const AValue: Word; const AArray: array of Word): Word;

function FindSimpleParameter(const AParameter: String): Boolean;
function FindComplexParameter(const AParameter: String; var AValue: String): Boolean;

function IntToHex(const AInteger: Integer): String;
function StrToIntDef(const AString: String; const ADefault: Longint): Longint;
function AddSizeSeparator(const AString: String; const AUnitPresent: Boolean): String;
function LowerCase(const AString: String): String;
function StrPas(const APChar: PChar): String;
function IntToStr(const AInteger: Longint): String;
function PadPercent(const AInteger: Longint): String;
function PadCenter(const AString: String; const APads: Byte): String;
function IfThenElse(const ACondition: Boolean; const AThen, AElse: String): String;

function FileExists(const AFileName: String): Boolean;
function ReplaceFileExt(const AFileName, AExtension: String): String;

implementation

uses
  Consts;

{ public declarations }

procedure Delay(const ADuration: Word); assembler;
asm
  mov ax,1000
  mul ADuration
  mov cx,dx
  mov dx,ax
  mov ah,86h
  int 15h
end;

function GetBit(const AByte, ABit: Byte): Boolean;
begin
  GetBit := Boolean(Odd(AByte shr ABit));
end;

procedure SetBit(var AByte: Byte; const ABit: Byte; const AValue: Boolean);
begin
  if AValue then
  begin
    AByte := AByte or (1 shl ABit);
  end else
  begin
    AByte := AByte and not (1 shl ABit);
  end;
end;

function LocateByte(const AValue: Byte; const AArray: array of Byte): Byte;
var
  LIndex: Byte;

begin
  for LIndex := Low(AArray) to High(AArray) do
  begin
    if AArray[LIndex] = AValue then
    begin
      LocateByte := LIndex;
      Break;
    end;
  end;
end;

function LocateWord(const AValue: Word; const AArray: array of Word): Word;
var
  LIndex: Byte;

begin
  for LIndex := Low(AArray) to High(AArray) do
  begin
    if AArray[LIndex] = AValue then
    begin
      LocateWord := LIndex;
      Break;
    end;
  end;
end;

function FindSimpleParameter(const AParameter: String): Boolean;
var
  I: Integer;

begin
  FindSimpleParameter := False;

  for I := 1 to ParamCount do
  begin
    if LowerCase(ParamStr(I)) = AParameter then
    begin
      FindSimpleParameter := True;

      Break;
    end;
  end;
end;

function FindComplexParameter(const AParameter: String; var AValue: String): Boolean;
var
  I: Integer;

begin
  FindComplexParameter := False;

  for I := 1 to ParamCount do
  begin
    if Pos(AParameter, LowerCase(ParamStr(I))) <> 0 then
    begin
      AValue := ParamStr(I);

      FindComplexParameter := True;

      Break;
    end;
  end;
end;

function IntToHex(const AInteger: Integer): String;
const
  kHexLength = 4;
  kHexDigits: array[0..15] of Char = '0123456789ABCDEF';

var
  I: Integer;
  LInteger: Integer;

begin
  LInteger := AInteger;

  IntToHex[0] := Char(kHexLength);

  for I := kHexLength downto 1 do
  begin
    IntToHex[I] := kHexDigits[LInteger and $F];
    LInteger := LInteger shr 4;
  end;
end;

function StrToIntDef(const AString: String; const ADefault: Longint): Longint;
var
  LValue: Longint;
  LErrorCode: Integer;

begin
  Val(AString, LValue, LErrorCode);
  if LErrorCode = 0 then
  begin
    StrToIntDef := LValue;
  end else
  begin
    StrToIntDef := ADefault;
  end;
end;

function AddSizeSeparator(const AString: String; const AUnitPresent: Boolean): String;
var
  I: Integer;
  LString: String;

begin
  LString := AString;

  if AString <> '' then
  begin
    I := Length(LString);

    if AUnitPresent then
    begin
      Dec(I, 5);
    end else
    begin
      Dec(I, 2);
    end;

    while I > 1 do
    begin
      Insert(',', LString, I);
      Dec(I, 3);
    end;
  end;

  AddSizeSeparator := LString;
end;

function LowerCase(const AString: String): String; assembler;
asm
  push ds

  cld

  lds si,AString
  les di,@Result
  lodsb
  stosb

  xor ah,ah
  xchg ax,cx
  jcxz @exit

@lowercase:
  lodsb
  cmp al,'A'
  jb @next
  cmp al,'Z'
  ja @next
  add al,20h

@next:
  stosb
  loop @lowercase

@exit:
  pop ds

end;

function StrPas(const APChar: PChar): String; assembler;
asm
  push ds

  cld

  les di,APChar
  xor al,al
  mov cx,0FFFFh
  repne scasb

  not cx
  dec cx

  lds si,APChar
  les di,@Result
  mov al,cl
  stosb
  rep movsb

  pop ds
end;

function IntToStr(const AInteger: Longint): String;
var
  S: String;

begin
  Str(AInteger, S);
  IntToStr := S;
end;

function PadPercent(const AInteger: Longint): String;
var
  LSpaces: String;

begin
  case AInteger of
    0..9:
      LSpaces := '  ';

    10..99:
      LSpaces := ' ';

  else
    LSpaces := '';
  end;

  PadPercent := LSpaces + IntToStr(AInteger) + ' %';
end;

function PadCenter(const AString: String; const APads: Byte): String;
var
  I: Byte;
  LSpaces: String;

begin
  LSpaces := sEmpty;

  for I := 0 to Pred(APads) do
  begin
    LSpaces := LSpaces + cSpace;
  end;

  PadCenter := LSpaces + AString + LSpaces;
end;

function IfThenElse(const ACondition: Boolean; const AThen, AElse: String): String;
begin
  if ACondition then
  begin
    IfThenElse := AThen;
  end else
  begin
    IfThenElse := AElse;
  end;
end;

function FileExists(const AFileName: String): Boolean;
var
  LFile: File of Byte;

begin
{$I-}
  Assign(LFile, AFileName);
  Reset(LFile);
  Close(LFile);
{$I+}

  FileExists := IOResult = 0;
end;

function ReplaceFileExt(const AFileName, AExtension: String): String;
var
  I: Byte;

begin
  for I := Length(AFileName) downto 1 do
    if AFileName[I] = cFullStop then
      Break;

  if (I = 1) and (AFileName[I] <> cFullStop) then
  begin
    ReplaceFileExt := AFileName;
  end else
  begin
    ReplaceFileExt := Copy(AFileName, 1, I) + AExtension;
  end;
end;

end.
