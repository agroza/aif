{ --------------------------------------------------------------------------- }
{ - Audio Interface - Error Handling (error.pas)                            - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Error;

interface

uses
  Types;

function ErrorNotEnoughMemory: Boolean;

procedure ErrorSetHaltOnErrors(const AValue: Boolean);
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
  );

var
  IGHaltOnErrors: Boolean;
  IGProgramError: TProgramError;

{ public declarations }

function ErrorNotEnoughMemory: Boolean;
begin
  if MaxAvail < kRequiredMemory then
  begin
    VideoWriteln(sNotEnoughMemory);

    ErrorNotEnoughMemory := True;
  end else
  begin
    ErrorNotEnoughMemory := False;
  end;
end;

procedure ErrorSetHaltOnErrors(const AValue: Boolean);
begin
  if IGHaltOnErrors <> AValue then
  begin
    IGHaltOnErrors := AValue;
  end;
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
