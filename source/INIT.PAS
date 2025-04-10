{ --------------------------------------------------------------------------- }
{ - Audio Interface - Initialization Subprogram (init.pas)                  - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Init;

interface

uses
  Types;

function InitAIFController(const AControllerMode: TControllerMode): Boolean;

procedure InitLineOut;

procedure InitAIFBasic;
procedure InitAIFComplete;

implementation

uses
  Codec,
  Consts,
  Control,
  Error,
  Mixer,
  MPU,
  Params,
  Routines,
  SBPro,
  Screen,
  Setup,
  Video;

const
  kVolumeNorm = 4.28;

  kSBDSPVersions: packed array[TCodecSBDSPVersion] of Byte = (
    2,
    1,
    3,
    4
  );

  sAIFDetectionMode: packed array[TAIFDetectionMode] of String[Length(snonPnP)] = (
    sPnP,
    snonPnP
  );

var
  GINewChip: Boolean;

{ private declarations }

procedure AISetAudioOutputFormat(const ACodecAudioConfig: TCodecAudioConfig); forward;
function AISetWSSMode: Boolean; forward;
function AISetSBMode: Boolean; forward;
function AIControllerDetect(var AOutputString: String): Boolean; forward;
function AIControllerInitialize: Boolean; forward;
function AICodecDetect(var AOutputString: String): Boolean; forward;
function AICodecInitialize: Boolean; forward;
function AIMPUInitialize: Boolean; forward;
procedure AISetMode(const AParameters: TParameters); forward;

procedure AISetAudioOutputFormat(const ACodecAudioConfig: TCodecAudioConfig);
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

  AISetAudioOutputFormat(GWSSAudioConfig);

  ControllerDisallowCodecAccess;

  AISetWSSMode := CodecDetectWSS;
end;

function AISetSBMode: Boolean;
begin
  ControllerAllowCodecAccess(GControllerConfig);

  AISetAudioOutputFormat(GSBAudioConfig);

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

function AIControllerDetect(var AOutputString: String): Boolean;
begin
  if ControllerDetect then
  begin
    AOutputString := cSpace + cOpenBracket + sAIFDetectionMode[GAIFDetectionMode] + cSpace + sMode + cClosedBracket;
    AIControllerDetect := True;
  end else
  begin
    AOutputString := sEmpty;
    AIControllerDetect := False;
  end;
end;

function AIControllerInitialize: Boolean;
begin
  AIControllerInitialize := True;
end;

function AICodecDetect(var AOutputString: String): Boolean;
var
  LControllerSBMode: Boolean;

begin
  LControllerSBMode := ControllerGetMode = cmSB;

  ControllerAllowCodecAccess(GControllerConfig);

  if CodecDetect(GControllerConfig.WSSBASE) then
  begin
    GINewChip := CodecDetectNew;

    AOutputString := IfThenElse(GINewChip, sDetectingAD1845, sDetectingAD1848);
    AICodecDetect := True;
  end else
  begin
    AOutputString := sDetectingAD1848orAD1845;
    AICodecDetect := False;
  end;

  if LControllerSBMode then
  begin
    ControllerSetMode(cmSB, GControllerConfig);
  end;

  ControllerDisallowCodecAccess;
end;

function AICodecInitialize: Boolean;
begin
  ControllerAllowCodecAccess(GControllerConfig);

  AICodecInitialize := CodecInitialize and CodecDetectWSS;

  ControllerDisallowCodecAccess;
end;

function AIMPUInitialize: Boolean;
begin
  if GControllerConfig.BitMPU401 = bsSet then
  begin
    MPUSetPorts(GControllerConfig.MPUBASE);

    AIMPUInitialize := MPUReset(mrmPowerOnDefaults) or MPUReset(mrmUARTMode);
  end else
  begin
    AIMPUInitialize := False;
  end;
end;

procedure AISetMode(const AParameters: TParameters);
var
  LAction: Boolean;

begin
  VideoSetForeground(clNormal);
  VideoSetBackground(clBlack);

  case AParameters.InitMode of
    imWSS:
      begin
        LAction := AISetWSSMode;
        ScreenWriteStatusOf(sSettingWSSMode, LAction, not AParameters.Quiet);

        if LAction and AParameters.Quiet then
        begin
          VideoWriteln(sAIFInitializedWSSMode);
        end;
      end;

    imSB:
      begin
        LAction := AISetSBMode;
        ScreenWriteStatusOf(sSettingSBMode, LAction, not AParameters.Quiet);

        if LAction and AParameters.Quiet then
        begin
          VideoWriteln(sAIFInitializedSBMode);
        end;
      end;

  end;
end;

{ public declarations }

function InitAIFController(const AControllerMode: TControllerMode): Boolean;
begin
  case AControllerMode of
    cmWSS:
      InitAIFController := AISetWSSMode;

    cmSB:
      InitAIFController := AISetSBMode;

  end;
end;

procedure InitLineOut;
begin
  GCodecMixerConfig.OutputsEnabled := GParameters.LineOutRelay;

  InitAIFComplete;

  VideoSetForeground(clNormal);
  VideoSetBackground(clBlack);

  VideoWriteNewln;
  VideoWriteln(sLineOutRelay + LowerCase(sDisabledEnabled[GCodecMixerConfig.OutputsEnabled]) + cFullStop);
end;

procedure InitAIFBasic;
var
  LValue: Boolean;
  LString: String;

begin
  ErrorSetProgramError(peHardwareInit);

  LValue := AIControllerDetect(LString);
  ScreenWriteStatusOf(sDetecting82c924 + LString, LValue, not GParameters.Quiet);

  LValue := AICodecDetect(LString);
  ScreenWriteStatusOf(LString, LValue, not GParameters.Quiet);
end;

procedure InitAIFComplete;
begin
  ScreenWriteStatusOf(sInitializing82c924, AIControllerInitialize, not GParameters.Quiet);
  ScreenWriteStatusOf(IfThenElse(GINewChip, sInitializingAD1845, sInitializingAD1848),
    AICodecInitialize, not GParameters.Quiet);

  ScreenWriteStatusOf(sInitializingMPU, AIMPUInitialize, not GParameters.Quiet);
  ScreenWriteStatusOf(sSettingMixerConfig, MixerSetConfig(GParameters.InitMode), not GParameters.Quiet);

  AISetMode(GParameters);

  ScreenWriteStatusOf(sAIFInitialization, True, not GParameters.Quiet);
end;

end.
