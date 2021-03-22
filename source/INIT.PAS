{ --------------------------------------------------------------------------- }
{ - Audio Interface - Initialization Subprogram (init.pas)                  - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Init;

interface

uses
  Types;

type
  TParameters = record
    Setup: Boolean;
    Mixer: Boolean;
    InitMode: TAIFInitMode;
    Status: Boolean;
    Quiet: Boolean;
    LineOut: Boolean;
    LineOutRelay: Boolean;
  end;

var
  GParameters: TParameters;

procedure InitLineOut(var AParameters: TParameters);

procedure InitAIFBasic;
procedure InitAIFComplete;

implementation

uses
  Codec,
  Consts,
  Control,
  Mixer,
  MPU,
  Routines,
  SBPro,
  Screen,
  Setup;

const
  kVolumeNorm = 4.28;

var
  GNewChip: Boolean;

{ private declarations }

procedure SetAudioOutputFormat(const ACodecAudioConfig: TCodecAudioConfig);
var
  LFormat: TCodecOutputFormat;

begin
  case ACodecAudioConfig.BitDepth of
    bd8bit:
      LFormat := cof8bitUnsignedPCM;

    bd16bit:
      LFormat := cof16bitTwosComplementPCM;

  end;

  CodecSetOutputFormat(kSampleRates[ACodecAudioConfig.SampleRate].Frequency, LFormat, ACodecAudioConfig.SoundOutput);
end;

function AISetWSSMode: Boolean;
begin
  ControllerAllowCodecAccess(GControllerConfig);

  SetAudioOutputFormat(GWSSAudioConfig);

  ControllerDisallowCodecAccess;

  AISetWSSMode := CodecDetectWSS;
end;

function AISetSBMode: Boolean;
begin
  ControllerAllowCodecAccess(GControllerConfig);

  SetAudioOutputFormat(GSBAudioConfig);

  ControllerSetMode(cmSB, GControllerConfig);

  ControllerDisallowCodecAccess;

  if SBDSPReset(GControllerConfig.SBBASE) and (SBDSPGetVersion shr $04 = kSBDSPVersions[GControllerConfig.SBDSPVersion]) then
  begin
    AISetSBMode := True;

    SBMixerReset;

    SBMixerSetVolume(mdtMaster, scLeft, Round((GCodecMixerConfig.DACLeft / kVolumeNorm)));
    SBMixerSetVolume(mdtMaster, scRight, Round((GCodecMixerConfig.DACRight / kVolumeNorm)));
    SBMixerSetVolume(mdtFM, scLeft, Round((GCodecMixerConfig.AUX1Left / kVolumeNorm)));
    SBMixerSetVolume(mdtFM, scRight, Round((GCodecMixerConfig.AUX1Right / kVolumeNorm)));
    SBMixerSetVolume(mdtCD, scLeft, Round((GCodecMixerConfig.AUX2Left / kVolumeNorm)));
    SBMixerSetVolume(mdtCD, scRight, Round((GCodecMixerConfig.AUX2Right / kVolumeNorm)));

    SBMixerSetOutput(GSBAudioConfig.SoundOutput = soStereo, True);

    ControllerAVC(GControllerConfig.BitAVCEN = bsNotSet);
  end else
  begin
    AISetSBMode := False;
  end;
end;

{ TODO -oagroza -cRename : Remove Init prefix. }

function InitControllerDetect(var AOutputString: String): Boolean;
begin
  if ControllerDetect then
  begin
    AOutputString := cSpace + cOpenBracket + IfThenElse(GPnPMode, sModePnP, sModenonPnP) + cSpace + sMode + cClosedBracket;
    InitControllerDetect := True;
  end else
  begin
    InitControllerDetect := False;
  end;
end;

function InitControllerInitialize: Boolean;
begin
  InitControllerInitialize := True;
end;

function InitCodecDetect(var AOutputString: String): Boolean;
var
  LControllerSBMode: Boolean;

begin
  LControllerSBMode := ControllerGetMode = cmSB;

  ControllerAllowCodecAccess(GControllerConfig);

  if CodecDetect(GControllerConfig.WSSBASE) then
  begin
    GNewChip := CodecDetectNew;

    AOutputString := IfThenElse(GNewChip, sDetectingAD1845, sDetectingAD1848);
    InitCodecDetect := True;
  end else
  begin
    AOutputString := sDetectingAD1848orAD1845;
    InitCodecDetect := False;
  end;

  if LControllerSBMode then
  begin
    ControllerSetMode(cmSB, GControllerConfig);
  end;

  ControllerDisallowCodecAccess;
end;

function InitCodecInitialize: Boolean;
begin
  ControllerAllowCodecAccess(GControllerConfig);

  InitCodecInitialize := CodecInitialize and CodecDetectWSS;

  ControllerDisallowCodecAccess;
end;

function MPUInitialize: Boolean;
begin
  if GControllerConfig.BitMPU401 = bsSet then
  begin
    MPUSetPorts(GControllerConfig.MPUBASE);

    MPUReset(mrmPowerOnDefaults);

    if not MPUReset(mrmDumbUART) then
    begin
      MPUInitialize := False;
      Exit;
    end;

    MPUReset(mrmPowerOnDefaults);

    MPUInitialize := True;
  end else
  begin
    MPUInitialize := False;
  end;
end;

procedure AISetMode(const AParameters: TParameters);
var
  LAction: Boolean;

begin
  case AParameters.InitMode of
    imWSS:
      begin
        LAction := AISetWSSMode;
        ScreenWriteActionIf(sSettingWSSMode, LAction, not AParameters.Quiet);

        if LAction and AParameters.Quiet then
        begin
          Writeln(sAIInitializedWSSMode);
        end;
      end;

    imSB:
      begin
        LAction := AISetSBMode;
        ScreenWriteActionIf(sSettingSBMode, LAction, not AParameters.Quiet);

        if LAction and AParameters.Quiet then
        begin
          Writeln(sAIInitializedSBMode);
        end;
      end;

  end;
end;

{ public declarations }

procedure InitLineOut(var AParameters: TParameters);
begin
  AParameters.InitMode := SetupGetInitMode;
  GCodecMixerConfig.OutputsEnabled := AParameters.LineOutRelay;

  InitAIFComplete;

  Writeln;
  Writeln(sLineOutRelay + LowerCase(sEnabledDisabled[GCodecMixerConfig.OutputsEnabled]) + cFullStop);
end;

procedure InitAIFBasic;
var
  LValue: Boolean;
  LString: String;

begin
  InitControllerDetect(LString);
  ScreenWriteActionIf(sDetecting82c924 + LString, LValue, not GParameters.Quiet);

  LValue := InitCodecDetect(LString);
  ScreenWriteActionIf(LString, LValue, not GParameters.Quiet);
end;

procedure InitAIFComplete;
begin
  ScreenWriteActionIf(sInitializing82c924, InitControllerInitialize, not GParameters.Quiet);
  ScreenWriteActionIf(IfThenElse(GNewChip, sInitializingAD1845, sInitializingAD1848),
    InitCodecInitialize, not GParameters.Quiet);

  ScreenWriteActionIf(sInitializingMPU, MPUInitialize, not GParameters.Quiet);
  { TODO -oagroza -cRefactor : Suboptimal way of passing SB parameter. }
  ScreenWriteActionIf(sSettingMixerConfig, MixerSetConfig(GParameters.InitMode = imSB), not GParameters.Quiet);

  AISetMode(GParameters);
end;

end.
