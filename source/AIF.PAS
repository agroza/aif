{ --------------------------------------------------------------------------- }
{ - Audio Interface - Program (aif.pas)                                     - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$M 16384, 0, 655360}

program aif;

uses
  Crt,
  Consts,
  Init,
  Mixer,
  Routines,
  Screen,
  Setup,
  PnPSetup,
  Status,
  Types;

function ProcessParameters: Boolean;
var
  LValue: String;

begin
  FillChar(GParameters, SizeOf(GParameters), $00);

  if ParamCount > 0 then
  begin
    GParameters.Setup := FindSimpleParameter(pSetup);
    GParameters.PnPSetup := FindSimpleParameter(pPnPSetup);
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

    GParameters.LineOut := FindComplexParameter(pLineOut, LValue);
    GParameters.LineOutRelay := GParameters.LineOut and
      (LowerCase(Copy(LValue, Succ(Pos(cEqual, LValue)), 3)) = pOn);

    ProcessParameters := GParameters.Setup or GParameters.PnPSetup or
      GParameters.Mixer or GParameters.Status or GParameters.LineOut or
      (GParameters.InitMode <> imInvalid);
  end else
  begin
    ProcessParameters := False;
  end;
end;

procedure WriteProgramHeader;
begin
  TextColor(clHighlight);
  Writeln;
  Writeln(sProgramTitle);

  TextColor(clNormal);
  Writeln(sProgramCopyright);
  Writeln(sProgramAuthor);
  Writeln(sProgramRights);
  Writeln;
end;

procedure WriteHelp;
var
  LHelpParameter: Byte;

begin
  Writeln(sHelpUsage);
  Writeln(sHelpWhere);

  for LHelpParameter := Low(kHelpParameters) to High(kHelpParameters) do
  begin
    Writeln(StrPas(kHelpParameters[LHelpParameter]));
  end;

  Writeln;
  Writeln(sHelpExamples);
end;

procedure WriteParameterError;
begin
  Writeln(sParameterMissing);
  Writeln;
  Writeln(sTypeHelp);
end;

var
  GPConfigLoaded: Boolean;

begin
  WriteProgramHeader;

  if (ParamCount > 0) and FindSimpleParameter(pHelp) then
  begin
    WriteHelp;
  end else
  begin
    if ProcessParameters then
    begin
      SetHaltOnErrors(False);

      GPConfigLoaded := SetupLoadConfig;
      ScreenWriteActionIf(sLoadingConfiguration, GPConfigLoaded, not GParameters.Quiet);

      if not GPConfigLoaded then
      begin
        SetupDefaultConfig;
        MixerDefaultConfig;
      end;

      if GParameters.Setup or not GPConfigLoaded then
      begin
        SetupStart;

        Exit;
      end;

      if GParameters.PnPSetup then
      begin
        PnPSetupStart;

        Exit;
      end;

      SetHaltOnErrors(True);

      InitAIFBasic;

      if (GParameters.InitMode = imSetup) or GParameters.LineOut then
      begin
        GParameters.InitMode := SetupGetInitMode;
      end;

      if GParameters.LineOut then
      begin
        InitLineOut;

        Exit;
      end;

      if GParameters.Mixer then
      begin
        MixerStart;
      end;

      if GParameters.InitMode <> imInvalid then
      begin
        InitAIFComplete;
      end;

      if GParameters.Status then
      begin
        StatusWrite;
      end;
    end else
    begin
      WriteParameterError;
    end;
  end;
end.
