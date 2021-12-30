{ --------------------------------------------------------------------------- }
{ - Audio Interface - Program (aif.pas)                                     - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$M 16384, 65535, 655360}

program aif;

uses
  Consts,
  Error,
  Init,
  Mixer,
  Routines,
  Screen,
  Setup,
  PnPSetup,
  Status,
  Types,
  Video;

function ProcessParameters: Boolean;
var
  LParameterLineOut: String;

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
      GParameters.PnPSetup or
      GParameters.Mixer or
      GParameters.Status or
      GParameters.LineOut or
      (GParameters.InitMode <> imInvalid);
  end else
  begin
    ProcessParameters := False;
  end;
end;

procedure WriteProgramHeader;
begin
  VideoWriteNewln;

  VideoSetBackground(clBlack);

  VideoSetForeground(clHighlight);
  VideoWriteln(sProgramTitle);

  VideoSetForeground(clNormal);
  VideoWriteln(sProgramCopyright);
  VideoWriteln(sProgramAuthor);
  VideoWriteln(sProgramRights);

  VideoWriteNewln;
end;

procedure WriteHelp;
var
  LHelpParameter: Byte;

begin
  VideoSetForeground(clNormal);
  VideoSetBackground(clBlack);

  VideoWriteln(sHelpUsage);
  VideoWriteln(sHelpWhere);

  for LHelpParameter := Low(kHelpParameters) to High(kHelpParameters) do
  begin
    VideoWriteln(StrPas(kHelpParameters[LHelpParameter]));
  end;

  VideoWriteNewln;
  VideoWriteln(sHelpExamples);
end;

procedure WriteParameterError;
begin
  VideoSetForeground(clNormal);
  VideoSetBackground(clBlack);

  VideoWriteln(sParameterMissing);
  VideoWriteNewln;
  VideoWriteln(sTypeHelp);
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
      ErrorSetHaltOnErrors(False);

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

      ErrorSetHaltOnErrors(True);

      InitAIFBasic;

      if GParameters.PnPSetup then
      begin
        PnPSetupStart;

        Exit;
      end;

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
