{ --------------------------------------------------------------------------- }
{ - Audio Interface - Routines (routines.pas)                               - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Routines;

interface

uses
  Types;

procedure Delay(const ADuration: Word);

function GetScanCode: Word;
function GetStandardKey(const AScanCode: Word): Char;
function GetExtendedKey(const AScanCode: Word): Char;

function GetBit(const AByte, ABit: Byte): Boolean;
procedure SetBit(var AByte: Byte; const ABit: Byte; const AValue: Boolean);

function LocateByte(const AValue: Byte; const AArray: array of Byte): Byte;
function LocateWord(const AValue: Word; const AArray: array of Word): Word;

function FindSimpleParameter(const AParameter: String): Boolean;
function FindComplexParameter(const AParameter: String; var AValue: String): Boolean;
function FindComplexParameterValue(const AParameter, AValue: String): Boolean;

function IntToHex(const AInteger: Integer): String;
function StrToIntDef(const AString: String; const ADefault: Longint): Longint;
function AddSizeSeparator(const AString: String; const AUnitPresent: Boolean): String;
function LowerCase(const AString: String): String;
function StringOfChar(const ACharacter: Char; const ATimes: Byte): String;
function StrPas(const APChar: PChar): String;
function FindOccurences(const AString, ASubString: String): Byte;
procedure Split(const AString, ASubString: String; var AStrings: PStrings);
function MaxLength(const AStrings: PStrings; const AStringsCount: Byte): Byte;
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

function GetScanCode: Word; assembler;
asm
  xor ah,ah
  int 16h
end;

function GetStandardKey(const AScanCode: Word): Char; assembler;
asm
  mov ax,AScanCode
end;

function GetExtendedKey(const AScanCode: Word): Char; assembler;
asm
  mov ax,AScanCode
  xchg ah,al
end;

function GetBit(const AByte, ABit: Byte): Boolean;
begin
  GetBit := Boolean(Odd(AByte shr ABit));
end;

procedure SetBit(var AByte: Byte; const ABit: Byte; const AValue: Boolean);
begin
  if AValue then
  begin
    AByte := AByte or ($01 shl ABit);
  end else
  begin
    AByte := AByte and not ($01 shl ABit);
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

function FindComplexParameterValue(const AParameter, AValue: String): Boolean;
begin
  FindComplexParameterValue := LowerCase(
    Copy(
      AParameter,
      Succ(Pos(cEqual, AParameter)),
      Length(AValue)
    )
  ) = LowerCase(AValue);
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
    IntToHex[I] := kHexDigits[LInteger and $0F];
    LInteger := LInteger shr $04;
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
const
  kDecrementUnit   = 5;
  kDecrementNoUnit = 2;
  kDecrementDigits = 3;

var
  LPosition: Integer;
  LSeparatedString: String;

begin
  LSeparatedString := AString;

  if AString <> sEmpty then
  begin
    LPosition := Length(LSeparatedString);

    if AUnitPresent then
    begin
      Dec(LPosition, kDecrementUnit);
    end else
    begin
      Dec(LPosition, kDecrementNoUnit);
    end;

    while LPosition > 1 do
    begin
      Insert(cComma, LSeparatedString, LPosition);
      Dec(LPosition, kDecrementDigits);
    end;
  end;

  AddSizeSeparator := LSeparatedString;
end;

function LowerCase(const AString: String): String; assembler;
asm
  push ds

  cld

  lds si,[AString]
  les di,[@Result]
  lodsb
  stosb

  xor ah,ah
  xchg ax,cx
  jcxz @exit

@lowerCase:
  lodsb
  cmp al,'A'
  jb @nextByte
  cmp al,'Z'
  ja @nextByte
  add al,20h

@nextByte:
  stosb

  loop @lowerCase

@exit:
  pop ds
end;

function StringOfChar(const ACharacter: Char; const ATimes: Byte): String; assembler;
asm
  mov al,ACharacter
  xor ch,ch
  mov cl,ATimes
  les di,[@Result]

  cld

  mov es:[di],cl
  inc di
  repz stosb
end;

function StrPas(const APChar: PChar): String; assembler;
asm
  push ds

  cld

  les di,[APChar]
  xor al,al
  mov cx,0FFFFh
  repne scasb

  not cx
  dec cx

  lds si,[APChar]
  les di,[@Result]
  mov al,cl
  stosb
  rep movsb

  pop ds
end;

function FindOccurences(const AString, ASubString: String): Byte;
var
  LString: String;
  LOccurences: Byte;
  LPosition: Byte;

begin
  LString := AString;
  LOccurences := 0;

  repeat
    LPosition := Pos(ASubString, LString);

    if LPosition > 0 then
    begin
      Inc(LOccurences);
      Delete(LString, LPosition, Length(ASubString));
    end;
  until LPosition = 0;

  FindOccurences := LOccurences;
end;

procedure Split(const AString, ASubString: String; var AStrings: PStrings);
var
  LString: String;
  LStringIndex: Byte;
  LPosition: Byte;

begin
  LString := AString;
  LStringIndex := 0;

  repeat
    LPosition := Pos(ASubString, LString);

    if LPosition > 0 then
    begin
      AStrings^[LStringIndex] := Copy(LString, 1, Pred(LPosition));
      Delete(LString, 1, Pred(LPosition + Length(ASubString)));
      Inc(LStringIndex);
    end;
  until LPosition = 0;

  AStrings^[LStringIndex] := Copy(LString, 1, kMaxByte);
end;

function MaxLength(const AStrings: PStrings; const AStringsCount: Byte): Byte;
var
  LStringIndex: Byte;
  LCurrentLength: Byte;
  LMaxLength: Byte;

begin
  LMaxLength := Length(AStrings^[0]);

  for LStringIndex := 0 to AStringsCount do
  begin
    LCurrentLength := Length(AStrings^[LStringIndex]);

    if LCurrentLength > LMaxLength then
    begin
      LMaxLength := LCurrentLength;
    end;
  end;

  MaxLength := LMaxLength;
end;

function IntToStr(const AInteger: Longint): String;
var
  LString: String;

begin
  Str(AInteger, LString);
  IntToStr := LString;
end;

function PadPercent(const AInteger: Longint): String;
const
  kMaxLength  = 5;
  sPercentage = ' %';

var
  LPaddedString: String;

begin
  LPaddedString := IntToStr(AInteger) + sPercentage;
  Insert(StringOfChar(cSpace, kMaxLength - Length(LPaddedString)), LPaddedString, 1);

  PadPercent := LPaddedString;
end;

function PadCenter(const AString: String; const APads: Byte): String;
var
  LPaddedString: String;

begin
  LPaddedString := StringOfChar(cSpace, APads * 2);
  Insert(AString, LPaddedString, Succ(APads));

  PadCenter := LPaddedString;
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
  LDotPosition: Byte;

begin
  for LDotPosition := Length(AFileName) downto 1 do
  begin
    if AFileName[LDotPosition] = cFullStop then
    begin
      Break;
    end;
  end;

  if (LDotPosition = 1) and (AFileName[LDotPosition] <> cFullStop) then
  begin
    ReplaceFileExt := AFileName;
  end else
  begin
    ReplaceFileExt := Copy(AFileName, 1, LDotPosition) + AExtension;
  end;
end;

end.
