{ --------------------------------------------------------------------------- }
{ - Audio Interface - Program (aif.pas)                                     - }
{ - Copyright (C) 1998-2022 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$M 16384, 65535, 655360}

program aif;

{$I cdefines.inc}

uses
  ConMsg,
  Consts,
  Error,
  Init,
  Mixer,
  Params,
  Screen,
  Setup,
  PnPSetup,
  ROMSetup,
  Status,
  Types;

var
  GConfigLoaded: Boolean;

begin
  ConMsgWriteProgramHeader;

  if ErrorNotEnoughMemory then
  begin
    Exit;
  end;

  if (ParamCount > 0) and (FindSimpleParameter(pHelpAlt) or FindSimpleParameter(pHelp)) then
  begin
    ConMsgWriteHelp;
  end else
  begin
    if ProcessParameters then
    begin
      ErrorSetHaltOnErrors(False);

      GConfigLoaded := SetupLoadConfig;
      ScreenWriteStatusOf(sLoadingAIFConfig, GConfigLoaded, not GParameters.Quiet);

      if not GConfigLoaded then
      begin
        SetupDefaultConfig;
        MixerDefaultConfig;

        ScreenWriteStatusOf(sLoadingAIFConfigDefault, True, not GParameters.Quiet);
      end;

      if GParameters.Setup or not GConfigLoaded then
      begin
        if SetupStart then
        begin
          ConMsgWriteConfigChanged(sAIFConfig, GParameters.InitMode = imInvalid);
        end;
      end;

      ErrorSetHaltOnErrors(True);

      InitAIFBasic;
{$IFDEF PNPSETUP}
      if GParameters.PnPSetup then
      begin
        PnPSetupStart;

        Exit;
      end;
{$ENDIF}
      if GParameters.ROMSetup then
      begin
        ROMSetupStart;

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
        if MixerStart then
        begin
          ConMsgWriteConfigChanged(sMixerConfig, GParameters.InitMode = imInvalid);
        end;
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
      ConMsgWriteParameterMissing;
    end;
  end;
end.
