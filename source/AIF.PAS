{ --------------------------------------------------------------------------- }
{ - Audio Interface - Program (aif.pas)                                     - }
{ - Copyright (C) 1998-2020 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

program aif;

uses
  Crt,
  Consts,
  Init,
  Mixer,
  Routines,
  Screen,
  Setup,
  Status,
  Types;

var
  GParameters: TParameters;

function ProcessParameters(var AParameters: TParameters): Boolean;
begin
  FillChar(AParameters, SizeOf(AParameters), $00);

  if ParamCount > 0 then
  begin
    AParameters.Setup := FindSimpleParameter(pSetup);
    AParameters.Mixer := FindSimpleParameter(pMixer);

    if FindSimpleParameter(pInit) then
    begin
      case GControllerConfig.BitMOD of
        bsNotSet:
          GParameters.InitMode := imSB;

        bsSet:
          GParameters.InitMode := imWSS;

      end;
    end else
    if FindSimpleParameter(pWSS) then
    begin
      AParameters.InitMode := imWSS;
    end else
    if FindSimpleParameter(pSB) then
    begin
      AParameters.InitMode := imSB;
    end;

    AParameters.Quiet := FindSimpleParameter(pQuiet);
    AParameters.Status := FindSimpleParameter(pStatus);

    ProcessParameters := AParameters.Setup or AParameters.Mixer or
      AParameters.Status or (AParameters.InitMode <> imInvalid);
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
begin
  Writeln(sHelpUsage);
  Writeln(sHelpParameters1);
  Writeln(sHelpParameters2);
  Writeln(sHelpParameters3);

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
  GValue: Boolean;
  GString: String;

begin
  WriteProgramHeader;

  if (ParamCount > 0) and FindSimpleParameter(pHelp) then
  begin
    WriteHelp;
  end else
  begin
    if ProcessParameters(GParameters) then
    begin
      GValue := SetupLoadConfig;
      ScreenWriteActionIf(sLoadingConfiguration, GValue, not GParameters.Quiet);

      if not GValue then
      begin
        SetupDefaultConfig;
        MixerDefaultConfig;
      end;

      if GParameters.Setup or not GValue then
      begin
        SetupStart;
        Exit;
      end;

      GValue := InitControllerDetect(GString);
      ScreenWriteActionIf(sDetecting82c924 + GString, GValue, not GParameters.Quiet);

      GValue := InitCodecDetect(GString);
      ScreenWriteActionIf(GString, GValue, not GParameters.Quiet);

      if GParameters.Mixer then
      begin
        MixerStart;
      end;

      if GParameters.InitMode <> imInvalid then
      begin
        ScreenWriteActionIf(sInitializing82c924, InitControllerInitialize, not GParameters.Quiet);
        ScreenWriteActionIf(IfThenElse(GNewChip, sInitializingAD1845, sInitializingAD1848),
          InitCodecInitialize, not GParameters.Quiet);

        ScreenWriteActionIf(sInitializingMPU, InitMPUInitialize, not GParameters.Quiet);
        { TODO -oagroza -cImplement : Weird way of passing SB parameter. }
        ScreenWriteActionIf(sSettingMixerConfig, MixerSetConfig(GParameters.InitMode = imSB), not GParameters.Quiet);

        InitAISetMode(GParameters);
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
