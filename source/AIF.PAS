{ --------------------------------------------------------------------------- }
{ - Audio Interface - Program (aif.pas)                                     - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$M 16384, 65536, 655360}

{$I cdefines.inc}

{$IFDEF CPU16BIT}
  {$G+}
{$ENDIF}

program aif;

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
  Types,
  VVSubPrg;

var
  GConfigLoaded: Boolean;

begin
  ConMsgWriteProgramHeader;

  if {$IFDEF CPU16BIT}Error16bitCPURequired or {$ENDIF}
    ErrorNotEnoughMemory or ErrorDOS321Required then
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
        VVSubPrgExecute(ROMSetupStart);

        Exit;
      end;
{$IFDEF PNPSETUP}
      if GParameters.PnPSetup then
      begin
        VVSubPrgExecute(PnPSetupStart);

        Exit;
      end;
{$ENDIF}
      if GParameters.InitMode <> imNoInit then
      begin
        ErrorContinueOnErrors;

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
          ConMsgWriteConfigChanged(sAIFConfig, VVSubPrgExecute(SetupStart));
        end;

        if GParameters.Mixer then
        begin
          ConMsgWriteConfigChanged(sMixerConfig, VVSubPrgExecute(MixerStart));
        end;

        ErrorHaltOnErrors;

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
        ErrorHaltOnErrors;

        InitCDEXDriver;

        ErrorContinueOnErrors;

        GConfigLoaded := CDPlayerConfigLoad;
        ConMsgWriteStatus(sLoadingCDPConfig, GConfigLoaded);

        if not GConfigLoaded then
        begin
          CDPlayerConfigDefault;

          ConMsgWriteStatus(sLoadingCDPConfigDefault, True);
        end;

        ErrorHaltOnErrors;

        if VVSubPrgExecute(CDPlayerStart) or not GConfigLoaded then
        begin
          CDPlayerConfigSave;
        end;
      end;
{$ENDIF}
      if (GParameters.InitMode <> imNoInit) and GParameters.Status then
      begin
        StatusWrite;
      end;
    end else
    begin
      ConMsgWriteParameterMissing;
    end;
  end;
end.
