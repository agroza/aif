{ --------------------------------------------------------------------------- }
{ - Audio Interface - Commandline Parameters (params.pas)                   - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$G+}

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
    GParameters.ROMSetup := FindSimpleParameter(pROMSetup);
{$IFDEF PNPSETUP}
    GParameters.PnPSetup := FindSimpleParameter(pPnPSetup);
{$ENDIF}
    GParameters.Setup := FindSimpleParameter(pSetup);
    GParameters.Mixer := FindSimpleParameter(pMixer);
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

    if FindSimpleParameter(pNoInit) then
    begin
      GParameters.InitMode := imNoInit;
    end else
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
{$IFDEF CDPLAYER}
    GParameters.CDPlayer := FindSimpleParameter(pCDPlayer);
{$ENDIF}
    GParameters.Status := FindSimpleParameter(pStatus);

    ProcessParameters :=
      GParameters.ROMSetup or
{$IFDEF PNPSETUP}
      GParameters.PnPSetup or
{$ENDIF}
      GParameters.Setup or
      GParameters.Mixer or
      GParameters.LineOut or
{$IFDEF CDPLAYER}
      GParameters.CDPlayer or
{$ENDIF}
      GParameters.Status or
      (GParameters.InitMode <> imInvalid);
  end else
  begin
    ProcessParameters := False;
  end;
end;

end.
