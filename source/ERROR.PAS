{ --------------------------------------------------------------------------- }
{ - Audio Interface - Error Handling (error.pas)                            - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$I cdefines.inc}

{$IFDEF CPU16BIT}
  {$G+}
{$ENDIF}

unit Error;

interface

uses
  Types;

function Error16bitCPURequired: Boolean;
function ErrorNotEnoughMemory: Boolean;
function ErrorDOS321Required: Boolean;

procedure ErrorHaltOnErrors;
procedure ErrorContinueOnErrors;
procedure ErrorSetProgramError(const AValue: TProgramError);

procedure ErrorWriteHalt;

implementation

uses
  Consts,
  Routines,
  Video;

const
  sProgramErrors: packed array[TProgramError] of PChar = (
    sHardwareInitError,
    sControllerReinitError
{$IFDEF CDPLAYER},
    sCDROMDriverInitError
{$ENDIF}
  );

var
  IGHaltOnErrors: Boolean;
  IGProgramError: TProgramError;

function DetectDOS321: Boolean; forward;

{ private declarations }

function DetectDOS321: Boolean; assembler;
asm
  mov ah, 30h
  int 21h

  jc @unsupportedVersion

  cmp al, 3
  ja @supportedVersion
  cmp ah, 21
  jae @supportedVersion

@unsupportedVersion:
  xor ax, ax
  jmp @exit

@supportedVersion:
  mov al, True

@exit:

end;

{ public declarations }

function Error16bitCPURequired: Boolean;
begin
  if not Detect286CPU then
  begin
    VideoWriteln(sError16bitCPURequired);

    Error16bitCPURequired := True;
  end else
  begin
    Error16bitCPURequired := False;
  end;
end;

function ErrorNotEnoughMemory: Boolean;
begin
  if MaxAvail < kRequiredMemory then
  begin
    VideoWriteln(sErrorNotEnoughMemory);

    ErrorNotEnoughMemory := True;
  end else
  begin
    ErrorNotEnoughMemory := False;
  end;
end;

function ErrorDOS321Required: Boolean;
begin
  if not DetectDos321 then
  begin
    VideoWriteln(sErrorDOS321Required);

    ErrorDOS321Required := True;
  end else
  begin
    ErrorDOS321Required := False;
  end;
end;

procedure ErrorHaltOnErrors; assembler;
asm
  mov IGHaltOnErrors, True
end;

procedure ErrorContinueOnErrors; assembler;
asm
  mov IGHaltOnErrors, False
end;

procedure ErrorSetProgramError(const AValue: TProgramError);
begin
  if IGProgramError <> AValue then
  begin
    IGProgramError := AValue;
  end;
end;

procedure ErrorWriteHalt;
begin
  if IGHaltOnErrors then
  begin
    VideoSetForeground(clNormal);
    VideoSetBackground(clBlack);

    VideoWriteNewln;
    VideoWriteln(StrPas(sProgramErrors[IGProgramError]));

    Halt(Word(IGProgramError));
  end;
end;

end.
