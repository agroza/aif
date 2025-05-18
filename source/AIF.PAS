{ --------------------------------------------------------------------------- }
{ - Audio Interface - Program (aif.pas)                                     - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$G+}
{$M 16384, 65535, 655360}

program aif;

{$I cdefines.inc}

uses
  CDPlayer,
  ConMsg,
  Consts,
  Error,
  Init,
  Mixer,
  Params,
  Setup,
  PnPSetup,
  ROMSetup,
  Status,
  Types;

var
  GConfigLoaded: Boolean;

begin
  ConMsgWriteProgramHeader;

  if Error16bitCPURequired or ErrorNotEnoughMemory then
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
      if GParameters.ROMSetup then
      begin
        ROMSetupStart;

        Exit;
      end;
{$IFDEF PNPSETUP}
      if GParameters.PnPSetup then
      begin
        PnPSetupStart;

        Exit;
      end;
{$ENDIF}
      if GParameters.InitMode <> imNoInit then
      begin
        ErrorSetHaltOnErrors(False);

        GConfigLoaded := SetupConfigLoad;
        ConMsgWriteStatus(sLoadingAIFConfig, GConfigLoaded);

        if not GConfigLoaded then
        begin
          SetupConfigDefault;
          MixerConfigDefault;

          ConMsgWriteStatus(sLoadingAIFConfigDefault, True);
        end;

        if GParameters.Setup or not GConfigLoaded then
        begin
          ConMsgWriteConfigChanged(sAIFConfig, SetupStart);
        end;

        if GParameters.Mixer then
        begin
          ConMsgWriteConfigChanged(sMixerConfig, MixerStart);
        end;

        ErrorSetHaltOnErrors(True);

        InitAIFBasic;

        if GParameters.LineOut then
        begin
          InitLineOut;
        end;

        if (GParameters.InitMode = imSetup) or
          ((GParameters.InitMode = imInvalid) and GParameters.LineOut) then
        begin
          GParameters.InitMode := SetupGetInitMode;
        end;

        if GParameters.InitMode <> imInvalid then
        begin
          InitAIFComplete;
        end;
      end;
{$IFDEF CDPLAYER}
      if GParameters.CDPlayer then
      begin
        ErrorSetHaltOnErrors(False);

        InitCDEXDriver;

        GConfigLoaded := CDPlayerConfigLoad;
        ConMsgWriteStatus(sLoadingCDPConfig, GConfigLoaded);

        if not GConfigLoaded then
        begin
          CDPlayerConfigDefault;

          ConMsgWriteStatus(sLoadingCDPConfigDefault, True);
        end;

        ErrorSetHaltOnErrors(True);

        if CDPlayerStart or not GConfigLoaded then
        begin
          CDPlayerConfigSave;
        end;
      end;
{$ENDIF}
      if GParameters.InitMode <> imNoInit then
      begin
        if GParameters.Status then
        begin
          StatusWrite;
        end;
      end;
    end else
    begin
      ConMsgWriteParameterMissing;
    end;
  end;
end.
