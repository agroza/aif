{ --------------------------------------------------------------------------- }
{ - Audio Interface - Commandline Parameters (params.pas)                   - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Params;

{$I cdefines.inc}

interface

uses
  Types;

var
  GParameters: TParameters;

function FindSimpleParameter(const AParameter: String): Boolean;
function FindComplexParameter(const AParameter: String; var AValue: String): Boolean;
function FindComplexParameterValue(const AParameter, AValue: String): Boolean;
function ProcessParameters: Boolean;

implementation

uses
  Consts,
  Routines;

{ public declarations }

function FindSimpleParameter(const AParameter: String): Boolean;
var
  LIndex: Integer;

begin
  FindSimpleParameter := False;

  for LIndex := 1 to ParamCount do
  begin
    if LowerCase(ParamStr(LIndex)) = AParameter then
    begin
      FindSimpleParameter := True;

      Break;
    end;
  end;
end;

function FindComplexParameter(const AParameter: String; var AValue: String): Boolean;
var
  LIndex: Integer;

begin
  FindComplexParameter := False;

  for LIndex := 1 to ParamCount do
  begin
    AValue := ParamStr(LIndex);

    if Pos(AParameter, LowerCase(AValue)) <> 0 then
    begin
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

function ProcessParameters: Boolean;
var
  LParameterLineOut: String;

begin
  FillChar(GParameters, SizeOf(TParameters), $00);

  if ParamCount > 0 then
  begin
    GParameters.Setup := FindSimpleParameter(pSetup);
{$IFDEF PNPSETUP}
    GParameters.PnPSetup := FindSimpleParameter(pPnPSetup);
{$ENDIF}
    GParameters.ROMSetup := FindSimpleParameter(pROMSetup);
    GParameters.Mixer := FindSimpleParameter(pMixer);

    if FindSimpleParameter(pInit) then
    begin
      GParameters.InitMode := imSetup;
    end else
    if FindSimpleParameter(pWSS) then
    begin
      GParameters.InitMode := imWSS;
    end else
    if FindSimpleParameter(pSB) then
    begin
      GParameters.InitMode := imSB;
    end else
    begin
      GParameters.InitMode := imInvalid;
    end;

    GParameters.Quiet := FindSimpleParameter(pQuiet);
    GParameters.Status := FindSimpleParameter(pStatus);

    GParameters.LineOut := FindComplexParameter(pLineOut, LParameterLineOut);

    if GParameters.LineOut then
    begin
      if FindComplexParameterValue(LParameterLineOut, pOn) then
      begin
        GParameters.LineOutRelay := True;
      end else
      if FindComplexParameterValue(LParameterLineOut, pOff) then
      begin
        GParameters.LineOutRelay := False;
      end else
      begin
        GParameters.LineOut := False;
      end;
    end;

    ProcessParameters :=
      GParameters.Setup or
{$IFDEF PNPSETUP}
      GParameters.PnPSetup or
{$ENDIF}
      GParameters.ROMSetup or
      GParameters.Mixer or
      GParameters.Status or
      GParameters.LineOut or
      (GParameters.InitMode <> imInvalid);
  end else
  begin
    ProcessParameters := False;
  end;
end;

end.
