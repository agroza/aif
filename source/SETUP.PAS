{ --------------------------------------------------------------------------- }
{ - Audio Interface - Setup Subprogram (setup.pas)                          - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Setup;

interface

uses
  Codec,
  Control,
  Types;

var
  GControllerConfig: TControllerConfig;
  GWSSAudioConfig: TCodecAudioConfig;
  GSBAudioConfig: TCodecAudioConfig;
  GCodecMixerConfig: TCodecMixerConfig;

function SetupLoadConfig: Boolean;
function SetupSaveConfig: Boolean;

procedure SetupDefaultConfig;

function SetupGetInitMode: TAIFInitMode;

procedure SetupStart;

implementation

uses
  Dos,
  Consts,
  Mixer,
  Routines,
  Screen,
  Video;

type
  TFileSignature = packed array[0..7] of Char;

  TArrayAdvance = (
    aaPrevious,
    aaNext
  );

  TSetupOption = (
    soAIFMode,
    soWSSBASE,
    soWSSIRQ,
    soWSSDRQ,
    soSBBASE,
    soSBIRQ,
    soSBDRQ,
    soMPU401,
    soMPUBASE,
    soMPUIRQ,
    soGamePort,
    soIDECDROM,
    soCFIX,
    soFMAP,
    soWSSSampleRate,
    soWSSBitDepth,
    soWSSSoundOutput,
    soSBSampleRate,
    soSBBitDepth,
    soSBSoundOutput,
    soSBDSPVersion,
    soSBADPCM,
    soCFIFO,
    soAVC
  );

  TGSVFunction = function(const AIndex: Byte; const ASetValue: Boolean): String;

  TSetupOptionData = packed record
    Name: PChar;
    PositionY: Byte;
    Low: Byte;
    High: Byte;
    Index: Byte;
    GSVFunction: TGSVFunction;
  end;

  TSetupConfig = packed record
    AIFMode: TBitStatus;
    WSSBASE: Word;
    WSSIRQ: Byte;
    WSSDRQ: Byte;
    SBBASE: Word;
    SBIRQ: Byte;
    SBDRQ: Byte;
    MPU401: TBitStatus;
    MPUBASE: Word;
    MPUIRQ: Byte;
    GamePort: TBitStatus;
    IDECDROM: TBitStatus;
    CFIX: TBitStatus;
    FMAP: TBitStatus;
    WSSSampleRate: TCodecSampleRate;
    WSSBitDepth: TCodecBitDepth;
    WSSSoundOutput: TCodecSoundOutput;
    SBSampleRate: TCodecSampleRate;
    SBBitDepth: TCodecBitDepth;
    SBSoundOutput: TCodecSoundOutput;
    SBDSPVersion: TCodecSBDSPVersion;
    SBADPCM: TBitStatus;
    CFIFO: TBitStatus;
    AVC: TBitStatus;
  end;

{$F+}

function GSVAIFMode(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVWSSBASE(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVWSSIRQ(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVWSSDRQ(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVSBBASE(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVSBIRQ(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVSBDRQ(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVMPU401(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVMPUBASE(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVMPUIRQ(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVGamePort(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVIDECDROM(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVCFIX(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVFMAP(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVWSSSampleRate(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVWSSBitDepth(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVWSSSoundOutput(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVSBSampleRate(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVSBBitDepth(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVSBSoundOutput(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVSBDSPVersion(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVSBADPCM(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVCFIFO(const AIndex: Byte; const ASetValue: Boolean): String; forward;
function GSVAVC(const AIndex: Byte; const ASetValue: Boolean): String; forward;

{$F-}

const
  kFileSignature: TFileSignature = 'AG86.BIN';

  kUICommands: packed array[0..kSetupCmdCount] of TUICommand = (
    ( Y: 4; Accelerator: sSetupCmdF8; Name: sSetupCmdDefaultConfig ),
    ( Y: 5; Accelerator: sSetupCmdF9; Name: sSetupCmdReloadConfig ),
    ( Y: 6; Accelerator: sSetupCmdF10; Name: sSetupCmdSaveExit ),
    ( Y: 8; Accelerator: sSetupCmdESC; Name: sSetupCmdExit ),
    ( Y: 12; Accelerator: sSetupCmdUpDown; Name: sSetupCmdSelectOption ),
    ( Y: 13; Accelerator: sSetupCmdLeftRight; Name: sSetupCmdModifyOption )
  );

  kSetupOptions: packed array[TSetupOption] of TSetupOptionData = (
    ( Name: sSetupAIFMode; PositionY: 2; Low: 0; High: 0; Index: 0; GSVFunction: GSVAIFMode ),
    ( Name: sSetupWSSBASE; PositionY: 3; Low: 0; High: 0; Index: 0; GSVFunction: GSVWSSBASE ),
    ( Name: sSetupWSSIRQ; PositionY: 4; Low: 0; High: 0; Index: 0; GSVFunction: GSVWSSIRQ ),
    ( Name: sSetupWSSDRQ; PositionY: 5; Low: 0; High: 0; Index: 0; GSVFunction: GSVWSSDRQ ),
    ( Name: sSetupSBBASE; PositionY: 6; Low: 0; High: 0; Index: 0; GSVFunction: GSVSBBASE ),
    ( Name: sSetupSBIRQ; PositionY: 7; Low: 0; High: 0; Index: 0; GSVFunction: GSVSBIRQ ),
    ( Name: sSetupSBDRQ; PositionY: 8; Low: 0; High: 0; Index: 0; GSVFunction: GSVSBDRQ ),
    ( Name: sSetupMPU401; PositionY: 9; Low: 0; High: 0; Index: 0; GSVFunction: GSVMPU401 ),
    ( Name: sSetupMPUBASE; PositionY: 10; Low: 0; High: 0; Index: 0; GSVFunction: GSVMPUBASE ),
    ( Name: sSetupMPUIRQ; PositionY: 11; Low: 0; High: 0; Index: 0; GSVFunction: GSVMPUIRQ ),
    ( Name: sSetupGamePort; PositionY: 12; Low: 0; High: 0; Index: 0; GSVFunction: GSVGamePort ),
    ( Name: sSetupIDECDROM; PositionY: 13; Low: 0; High: 0; Index: 0; GSVFunction: GSVIDECDROM ),
    ( Name: sSetupCFIX; PositionY: 14; Low: 0; High: 0; Index: 0; GSVFunction: GSVCFIX ),
    ( Name: sSetupFMAP; PositionY: 15; Low: 0; High: 0; Index: 0; GSVFunction: GSVFMAP ),
    ( Name: sSetupWSSSampleRate; PositionY: 16; Low: 0; High: 0; Index: 0; GSVFunction: GSVWSSSampleRate ),
    ( Name: sSetupWSSBitDepth; PositionY: 17; Low: 0; High: 0; Index: 0; GSVFunction: GSVWSSBitDepth ),
    ( Name: sSetupWSSSoundOutput; PositionY: 18; Low: 0; High: 0; Index: 0; GSVFunction: GSVWSSSoundOutput ),
    ( Name: sSetupSBSampleRate; PositionY: 19; Low: 0; High: 0; Index: 0; GSVFunction: GSVSBSampleRate ),
    ( Name: sSetupSBBitDepth; PositionY: 20; Low: 0; High: 0; Index: 0; GSVFunction: GSVSBBitDepth ),
    ( Name: sSetupSBSoundOutput; PositionY: 21; Low: 0; High: 0; Index: 0; GSVFunction: GSVSBSoundOutput ),
    ( Name: sSetupSBDSPVersion; PositionY: 22; Low: 0; High: 0; Index: 0; GSVFunction: GSVSBDSPVersion ),
    ( Name: sSetupSBADPCM; PositionY: 23; Low: 0; High: 0; Index: 0; GSVFunction: GSVSBADPCM ),
    ( Name: sSetupCFIFO; PositionY: 24; Low: 0; High: 0; Index: 0; GSVFunction: GSVCFIFO ),
    ( Name: sSetupAVC; PositionY: 25; Low: 0; High: 0; Index: 0; GSVFunction: GSVAVC )
  );

  kWSSBASEs: packed array[0..3] of Word = ( $0530, $0E80, $0F40, $0604 );
  kWSSIRQs: packed array[0..4] of Byte = ( $07, $09, $0A, $0B, $FF );
  kWSSDRQs: packed array[0..3] of Byte = ( $00, $01, $03, $FF );
  kSBBASEs: packed array[0..1] of Word = ( $0220, $0240 );
  kSBIRQs: packed array[0..3] of Byte = ( $05, $07, $0A, $FF );
  kSBDRQs: packed array[0..3] of Byte = ( $00, $01, $03, $FF );
  kMPUBASEs: packed array[0..3] of Word = ( $0300, $0310, $0320, $0330 );
  kMPUIRQs: packed array[0..3] of Byte = ( $05, $07, $09, $0A );

  sBSDisabledEnabled: packed array[TBitStatus] of String[Length(sDisabled)] = (
    sDisabled,
    sEnabled
  );

  sCFIX: packed array[TBitStatus] of String[Length(sAudioCodecAD1848orCS4248)] = (
    sAudioCodecAD1848orCS4248,
    sAudioCodecAD1845orCS4231
  );

  sFMAP: packed array[TBitStatus] of String[Length(sCrystal16and24MHz)] = (
    sCrystal16and24MHz,
    sCrystal16MHz
  );

  sAVC: packed array[TBitStatus] of String[Length(sVolumeControlAutomatic)] = (
    sVolumeControlAutomatic,
    sVolumeControlNormal
  );

var
  IGSetupConfigChanged: Boolean;
  IGSetupConfig: TSetupConfig;
  IGMessageBox: TMessageBoxData;

{ private declarations }

procedure ApplyConfig;
begin
  GControllerConfig.BitMOD := IGSetupConfig.AIFMode;
  GControllerConfig.WSSBASE := IGSetupConfig.WSSBASE;
  GControllerConfig.WSSIRQ := IGSetupConfig.WSSIRQ;
  GControllerConfig.WSSDRQ := IGSetupConfig.WSSDRQ;
  GControllerConfig.SBBASE := IGSetupConfig.SBBASE;
  GControllerConfig.SBIRQ := IGSetupConfig.SBIRQ;
  GControllerConfig.SBDRQ := IGSetupConfig.SBDRQ;
  GControllerConfig.BitMPU401 := IGSetupConfig.MPU401;
  GControllerConfig.MPUBASE := IGSetupConfig.MPUBASE;
  GControllerConfig.MPUIRQ := IGSetupConfig.MPUIRQ;
  GControllerConfig.BitGPEN := IGSetupConfig.GamePort;
  GControllerConfig.IDECDROM := IGSetupConfig.IDECDROM;
  GControllerConfig.BitCFIX := IGSetupConfig.CFIX;
  GControllerConfig.BitFMAP := IGSetupConfig.FMAP;
  GWSSAudioConfig.SampleRate := IGSetupConfig.WSSSampleRate;
  GWSSAudioConfig.BitDepth := IGSetupConfig.WSSBitDepth;
  GWSSAudioConfig.SoundOutput := IGSetupConfig.WSSSoundOutput;
  GSBAudioConfig.SampleRate := IGSetupConfig.SBSampleRate;
  GSBAudioConfig.BitDepth := IGSetupConfig.SBBitDepth;
  GSBAudioConfig.SoundOutput := IGSetupConfig.SBSoundOutput;
  GControllerConfig.SBDSPVersion := IGSetupConfig.SBDSPVersion;
  GControllerConfig.BitADPCMEN := IGSetupConfig.SBADPCM;
  GControllerConfig.BitCFIFO := IGSetupConfig.CFIFO;
  GControllerConfig.BitAVCEN := IGSetupConfig.AVC;
end;

procedure InitConfig;
begin
  IGSetupConfig.AIFMode := GControllerConfig.BitMOD;
  IGSetupConfig.WSSBASE := GControllerConfig.WSSBASE;
  IGSetupConfig.WSSIRQ := GControllerConfig.WSSIRQ;
  IGSetupConfig.WSSDRQ := GControllerConfig.WSSDRQ;
  IGSetupConfig.SBBASE := GControllerConfig.SBBASE;
  IGSetupConfig.SBIRQ := GControllerConfig.SBIRQ;
  IGSetupConfig.SBDRQ := GControllerConfig.SBDRQ;
  IGSetupConfig.MPU401 := GControllerConfig.BitMPU401;
  IGSetupConfig.MPUBASE := GControllerConfig.MPUBASE;
  IGSetupConfig.MPUIRQ := GControllerConfig.MPUIRQ;
  IGSetupConfig.GamePort := GControllerConfig.BitGPEN;
  IGSetupConfig.IDECDROM := GControllerConfig.IDECDROM;
  IGSetupConfig.CFIX := GControllerConfig.BitCFIX;
  IGSetupConfig.FMAP := GControllerConfig.BitFMAP;
  IGSetupConfig.WSSSampleRate := GWSSAudioConfig.SampleRate;
  IGSetupConfig.WSSBitDepth := GWSSAudioConfig.BitDepth;
  IGSetupConfig.WSSSoundOutput := GWSSAudioConfig.SoundOutput;
  IGSetupConfig.SBSampleRate := GSBAudioConfig.SampleRate;
  IGSetupConfig.SBBitDepth := GSBAudioConfig.BitDepth;
  IGSetupConfig.SBSoundOutput := GSBAudioConfig.SoundOutput;
  IGSetupConfig.SBDSPVersion := GControllerConfig.SBDSPVersion;
  IGSetupConfig.SBADPCM := GControllerConfig.BitADPCMEN;
  IGSetupConfig.CFIFO := GControllerConfig.BitCFIFO;
  IGSetupConfig.AVC := GControllerConfig.BitAVCEN;
end;

{$F+}

function GSVAIFMode(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.AIFMode := TBitStatus(AIndex);
  end;

  GSVAIFMode := sAIFMode[TBitStatus(AIndex)];
end;

function GSVWSSBASE(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.WSSBASE := kWSSBASEs[AIndex];
  end;

  GSVWSSBASE := IntToHex(kWSSBASEs[AIndex]);
end;

function GSVWSSIRQ(const AIndex: Byte; const ASetValue: Boolean): String;
var
  LWSSIRQ: Byte;

begin
  LWSSIRQ := kWSSIRQs[AIndex];

  if ASetValue then
  begin
    IGSetupConfig.WSSIRQ := LWSSIRQ;
  end;

  GSVWSSIRQ := IfThenElse(LWSSIRQ = $FF, sDisabledEnabled[False], IntToStr(kWSSIRQs[AIndex]));
end;

function GSVWSSDRQ(const AIndex: Byte; const ASetValue: Boolean): String;
var
  LWSSDRQ: Byte;

begin
  LWSSDRQ := kWSSDRQs[AIndex];

  if ASetValue then
  begin
    IGSetupConfig.WSSDRQ := LWSSDRQ;
  end;

  GSVWSSDRQ := IfThenElse(LWSSDRQ = $FF, sDisabledEnabled[False], IntToStr(kWSSDRQs[AIndex]));
end;

function GSVSBBASE(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBBASE := kSBBASEs[AIndex];
  end;

  GSVSBBASE := IntToHex(kSBBASEs[AIndex]);
end;

function GSVSBIRQ(const AIndex: Byte; const ASetValue: Boolean): String;
var
  LSBIRQ: Byte;

begin
  LSBIRQ := kSBIRQs[AIndex];

  if ASetValue then
  begin
    IGSetupConfig.SBIRQ := LSBIRQ;
  end;

  GSVSBIRQ := IfThenElse(LSBIRQ = $FF, sDisabledEnabled[False], IntToStr(kSBIRQs[AIndex]));
end;

function GSVSBDRQ(const AIndex: Byte; const ASetValue: Boolean): String;
var
  LSBDRQ: Byte;

begin
  LSBDRQ := kSBDRQs[AIndex];

  if ASetValue then
  begin
    IGSetupConfig.SBDRQ := LSBDRQ;
  end;

  GSVSBDRQ := IfThenElse(LSBDRQ = $FF, sDisabledEnabled[False], IntToStr(kSBDRQs[AIndex]));
end;

function GSVMPU401(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.MPU401 := TBitStatus(AIndex);
  end;

  GSVMPU401 := sBSDisabledEnabled[TBitStatus(AIndex)];
end;

function GSVMPUBASE(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.MPUBASE := kMPUBASEs[AIndex];
  end;

  GSVMPUBASE := IntToHex(kMPUBASEs[AIndex]);
end;

function GSVMPUIRQ(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.MPUIRQ := kMPUIRQs[AIndex];
  end;

  GSVMPUIRQ := IntToStr(kMPUIRQs[AIndex]);
end;

function GSVGamePort(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.GamePort := TBitStatus(AIndex);
  end;

  GSVGamePort := sBSDisabledEnabled[TBitStatus(AIndex)];
end;

function GSVIDECDROM(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.IDECDROM := TBitStatus(AIndex);
  end;

  GSVIDECDROM := sBSDisabledEnabled[TBitStatus(AIndex)];
end;

function GSVCFIX(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.CFIX := TBitStatus(AIndex);
  end;

  GSVCFIX := sCFIX[TBitStatus(AIndex)];
end;

function GSVFMAP(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.FMAP := TBitStatus(AIndex);
  end;

  GSVFMAP := sFMAP[TBitStatus(AIndex)];
end;

function GSVWSSSampleRate(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.WSSSampleRate := TCodecSampleRate(AIndex);
  end;

  GSVWSSSampleRate := AddSizeSeparator(IntToStr(kSampleRates[TCodecSampleRate(AIndex)].Frequency) + cSpace + sHz, True);
end;

function GSVWSSBitDepth(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.WSSBitDepth := TCodecBitDepth(AIndex);
  end;

  GSVWSSBitDepth := sBitDepth[TCodecBitDepth(AIndex)];
end;

function GSVWSSSoundOutput(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.WSSSoundOutput := TCodecSoundOutput(AIndex);
  end;

  GSVWSSSoundOutput := sSoundOutput[TCodecSoundOutput(AIndex)];
end;

function GSVSBSampleRate(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBSampleRate := TCodecSampleRate(AIndex);
  end;

  GSVSBSampleRate := AddSizeSeparator(IntToStr(kSampleRates[TCodecSampleRate(AIndex)].Frequency) + cSpace + sHz, True);
end;

function GSVSBBitDepth(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBBitDepth := TCodecBitDepth(AIndex);
  end;

  GSVSBBitDepth := sBitDepth[TCodecBitDepth(AIndex)];
end;

function GSVSBSoundOutput(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBSoundOutput := TCodecSoundOutput(AIndex);
  end;

  GSVSBSoundOutput := sSoundOutput[TCodecSoundOutput(AIndex)];
end;

function GSVSBDSPVersion(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBDSPVersion := TCodecSBDSPVersion(AIndex);
  end;

  GSVSBDSPVersion := sSBDSPVersions[TCodecSBDSPVersion(AIndex)];
end;

function GSVSBADPCM(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBADPCM := TBitStatus(AIndex);
  end;

  GSVSBADPCM := sBSDisabledEnabled[TBitStatus(AIndex)];
end;

function GSVCFIFO(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.CFIFO := TBitStatus(AIndex);
  end;

  GSVCFIFO := sBSDisabledEnabled[TBitStatus(AIndex)];
end;

function GSVAVC(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.AVC := TBitStatus(AIndex);
  end;

  GSVAVC := sAVC[TBitStatus(AIndex)];
end;

{$F-}

procedure InitOptionVector(const ASetupOption: TSetupOption; const AHigh, AIndex: Byte);
begin
  kSetupOptions[ASetupOption].High := AHigh;
  kSetupOptions[ASetupOption].Index := AIndex;
end;

procedure InitOptionVectors;
begin
  InitOptionVector(soAIFMode, Byte(High(sAIFMode)), Byte(IGSetupConfig.AIFMode));
  InitOptionVector(soWSSBASE, High(kWSSBASEs), LocateWord(IGSetupConfig.WSSBASE, kWSSBASEs));
  InitOptionVector(soWSSIRQ, High(kWSSIRQs), LocateByte(IGSetupConfig.WSSIRQ, kWSSIRQs));
  InitOptionVector(soWSSDRQ, High(kWSSDRQs), LocateByte(IGSetupConfig.WSSDRQ, kWSSDRQs));
  InitOptionVector(soSBBASE, High(kSBBASEs), LocateWord(IGSetupConfig.SBBASE, kSBBASEs));
  InitOptionVector(soSBIRQ, High(kSBIRQs), LocateByte(IGSetupConfig.SBIRQ, kSBIRQs));
  InitOptionVector(soSBDRQ, High(kSBDRQs), LocateByte(IGSetupConfig.SBDRQ, kSBDRQs));
  InitOptionVector(soMPU401, Byte(High(sBSDisabledEnabled)), Byte(IGSetupConfig.MPU401));
  InitOptionVector(soMPUBASE, High(kMPUBASEs), LocateWord(IGSetupConfig.MPUBASE, kMPUBASEs));
  InitOptionVector(soMPUIRQ, High(kMPUIRQs), LocateByte(IGSetupConfig.MPUIRQ, kMPUIRQs));
  InitOptionVector(soGamePort, Byte(High(sBSDisabledEnabled)), Byte(IGSetupConfig.GamePort));
  InitOptionVector(soIDECDROM, Byte(High(sBSDisabledEnabled)), Byte(IGSetupConfig.IDECDROM));
  InitOptionVector(soCFIX, Byte(High(sCFIX)), Byte(IGSetupConfig.CFIX));
  InitOptionVector(soFMAP, Byte(High(sBSDisabledEnabled)), Byte(IGSetupConfig.FMAP));
  InitOptionVector(soWSSSampleRate, Byte(High(kSampleRates)), Byte(IGSetupConfig.WSSSampleRate));
  InitOptionVector(soWSSBitDepth, Byte(High(sBitDepth)), Byte(IGSetupConfig.WSSBitDepth));
  InitOptionVector(soWSSSoundOutput, Byte(High(sSoundOutput)), Byte(IGSetupConfig.WSSSoundOutput));
  InitOptionVector(soSBSampleRate, Byte(High(kSampleRates)), Byte(IGSetupConfig.SBSampleRate));
  InitOptionVector(soSBBitDepth, Byte(High(sBitDepth)), Byte(IGSetupConfig.SBBitDepth));
  InitOptionVector(soSBSoundOutput, Byte(High(sSoundOutput)), Byte(IGSetupConfig.SBSoundOutput));
  InitOptionVector(soSBDSPVersion, Byte(High(sSBDSPVersions)), Byte(IGSetupConfig.SBDSPVersion));
  InitOptionVector(soSBADPCM, Byte(High(sBSDisabledEnabled)), Byte(IGSetupConfig.SBADPCM));
  InitOptionVector(soCFIFO, Byte(High(sBSDisabledEnabled)), Byte(IGSetupConfig.CFIFO));
  InitOptionVector(soAVC, Byte(High(sBSDisabledEnabled)), Byte(IGSetupConfig.AVC));
end;

procedure DrawOptions;
var
  LSetupOption: TSetupOption;
  LSetupOptionData: TSetupOptionData;
  LKeyValueData: TKeyValueData;

begin
  VideoWriteRegion(
    kSetupOptionsLeft,
    kSetupOptionsTop,
    kSetupOptionsWidth,
    kSetupOptionsHeight,
    cSpace,
    VideoAttribute(
      clSetupFore,
      clSetupBack
    )
  );

  for LSetupOption := Low(TSetupOption) to High(TSetupOption) do
  begin
    LSetupOptionData := kSetupOptions[LSetupOption];

    LKeyValueData.KeyX := kSetupKeyX;
    LKeyValueData.ValueX := kSetupValueX;
    LKeyValueData.PositionY := LSetupOptionData.PositionY;
    LKeyValueData.Width := kSetupKeyValueWidth;
    LKeyValueData.Colors.Foreground := clSetupFore;
    LKeyValueData.Colors.Background := clSetupBack;
    LKeyValueData.Key := StrPas(LSetupOptionData.Name);
    LKeyValueData.Value := LSetupOptionData.GSVFunction(LSetupOptionData.Index, False);

    ScreenKeyValueDraw(LKeyValueData);
  end;
end;

procedure HighlightOption(const ASetupOption: TSetupOption; const AValue: Boolean);
var
  LAttribute: Byte;
  LEditAttribute: Byte;

begin
  if AValue then
  begin
    LAttribute := VideoAttribute(clWhite, clRed);
    LEditAttribute := VideoAttribute(clYellow, clRed);
  end else
  begin
    LAttribute := VideoAttribute(clSetupFore, clSetupBack);
    LEditAttribute := VideoAttribute(clSetupFore, clSetupBack);
  end;

  VideoHighlightRegion(
    kSetupOptionX,
    kSetupOptions[ASetupOption].PositionY,
    kSetupOptionWidth,
    kSetupOptionHeight,
    LAttribute
  );

  VideoHighlightRegion(
    kSetupOptionEditX,
    kSetupOptions[ASetupOption].PositionY,
    kSetupOptionEditWidth,
    kSetupOptionEditHeight,
    LEditAttribute
  );
end;

procedure EditOption(const ASetupOption: TSetupOption; const AArrayAdvance: TArrayAdvance);
var
  LSetupOptionData: TSetupOptionData;
  LIndex: Byte;

begin
  IGSetupConfigChanged := True;

  LSetupOptionData := kSetupOptions[ASetupOption];
  LIndex := LSetupOptionData.Index;

  case AArrayAdvance of
    aaPrevious:
      begin
        if LIndex > LSetupOptionData.Low then
        begin
          Dec(LIndex);
        end else
        begin
          LIndex := LSetupOptionData.High;
        end;
      end;

    aaNext:
      begin
        if LIndex < LSetupOptionData.High then
        begin
          Inc(LIndex);
        end else
        begin
          LIndex := LSetupOptionData.Low;
        end;
      end;

  end;

  VideoWriteRegion(
    kSetupOptionEditX,
    LSetupOptionData.PositionY,
    kSetupOptionEditWidth,
    kSetupOptionEditHeight,
    cSpace,
    VideoAttribute(
      clRed,
      clRed
    )
  );

  VideoWriteStringAt(
    kSetupValueX,
    LSetupOptionData.PositionY,
    LSetupOptionData.GSVFunction(LIndex, True),
    clYellow,
    clRed
  );

  kSetupOptions[ASetupOption].Index := LIndex;
end;

procedure CreateComponents;
begin
  IGMessageBox.Colors.Foreground := clMessageBoxFore;
  IGMessageBox.Colors.Background := clMessageBoxBack;
  IGMessageBox.Colors.BtnForeground := clMessageBoxBtnFore;
  IGMessageBox.Colors.BtnBackground := clMessageBoxBtnBack;
  IGMessageBox.Colors.BtnAccelerator := clMessageBoxBtnAccel;
  IGMessageBox.Colors.BtnHighForeground := clMessageBoxBtnHighFore;
  IGMessageBox.Colors.BtnHighBackground := clMessageBoxBtnHighBack;
  IGMessageBox.Colors.BtnHighAccelerator := clMessageBoxBtnHighAccel;

  ScreenMessageBoxPrepare(
    IGMessageBox,
    sMessageBoxQuestion,
    sSetupConfigChanged,
    [mbYes, mbNo],
    mbNo
  );
end;

procedure DrawCommands;
var
  LUICommand: Byte;

begin
  VideoWriteRegion(
    kSetupCommandsLeft,
    kSetupCommandsTop,
    kSetupCommandsWidth,
    kSetupCommandsHeight,
    cSpace,
    VideoAttribute(
      clSetupCmdFore,
      clSetupCmdBack
    )
  );

  VideoWriteStringAt(
    kSetupCmdX,
    3,
    sSetupCmdProgramCmds,
    clSetupCmdHeader,
    clSetupCmdBack
  );

  VideoWriteStringAt(
    kSetupCmdX,
    11,
    sSetupCmdOptionCmds,
    clSetupCmdHeader,
    clSetupCmdBack
  );

  for LUICommand := Low(kUICommands) to High(kUICommands) do
  begin
    ScreenCommandDraw(
      kSetupCmdX,
      kUICommands[LUICommand].Y,
      clSetupCmdHigh,
      clSetupCmdFore,
      clSetupCmdBack,
      StrPas(kUICommands[LUICommand].Accelerator),
      StrPas(kUICommands[LUICommand].Name)
    );
  end;
end;

procedure DrawRevision;
var
  LControllerRevision: Byte;

begin
  LControllerRevision := ControllerGetRevision;

  VideoWriteStringAt(
    kSetupCmdX,
    kSetupSoundControllerY,
    sSetupSoundController,
    clSetupCmdHeader,
    clSetupCmdBack
  );

  VideoWriteStringAt(
    kSetupCmdX,
    kSetupOPTi82c924Y,
    sSetupOPTi82c924 + IntToStr(LControllerRevision div 10) + cFullStop + IntToStr(LControllerRevision mod 10),
    clSetupCmdFore,
    clSetupCmdBack
  );
end;

procedure DrawConfig;
begin
  InitConfig;
  InitOptionVectors;
  DrawOptions;
end;

procedure UIDraw;
begin
  ScreenTitleBarDraw(clInterfaceFore, clInterfaceBack, clInterfaceFore, sSetupTitle);

  CreateComponents;

  DrawConfig;
  DrawCommands;
  DrawRevision;
end;

procedure ExitAndSave;
begin
  ApplyConfig;
  SetupSaveConfig;
end;

procedure UILoop;
var
  LScanCode: Word;
  LKey: Char;
  LSetupOption: TSetupOption;

begin
  IGSetupConfigChanged := False;

  LSetupOption := Low(TSetupOption);
  HighlightOption(LSetupOption, True);

  while True do
  begin
    LScanCode := GetScanCode;
    LKey := UpCase(GetStandardKey(LScanCode));
  
    case LKey of
      kKeyExtended:
        begin
          case GetExtendedKey(LScanCode) of
            kKeyF8:
              begin
                IGSetupConfigChanged := True;

                SetupDefaultConfig;
                DrawConfig;

                HighlightOption(LSetupOption, True);
              end;

            kKeyF9:
              begin
                if SetupLoadConfig then
                begin
                  IGSetupConfigChanged := True;

                  DrawConfig;
                end;

                HighlightOption(LSetupOption, True);
              end;

            kKeyF10:
              begin
                ExitAndSave;

                Break;
              end;

            kKeyUp:
              begin
                HighlightOption(LSetupOption, False);

                if LSetupOption > Low(TSetupOption) then
                begin
                  Dec(LSetupOption);
                end else
                begin
                  LSetupOption := High(TSetupOption);
                end;

                HighlightOption(LSetupOption, True);
              end;

            kKeyDown:
              begin
                HighlightOption(LSetupOption, False);

                if LSetupOption < High(TSetupOption) then
                begin
                  Inc(LSetupOption);
                end else
                begin
                  LSetupOption := Low(TSetupOption);
                end;

                HighlightOption(LSetupOption, True);
              end;

            kKeyLeft:
              EditOption(LSetupOption, aaPrevious);

            kKeyRight:
              EditOption(LSetupOption, aaNext);

          end;
        end;

      kKeyEscape:
        begin
          if IGSetupConfigChanged then
          begin
            case ScreenMessageBoxDraw(IGMessageBox) of
              mrCancel:
                Continue;

              mrNo:
                Break;

              mrYes:
                begin
                  ExitAndSave;

                  Break;
                end;

            end;
          end else
          begin
            Break;
          end;
        end;

    end;
  end;
end;

{ public declarations }

function SetupLoadConfig: Boolean;
var
  LFile: File;
  LFileName: String;
  LFileSignature: TFileSignature;

begin
  SetupLoadConfig := False;

  LFileName := FileReplaceExt(FExpand(ParamStr(0)), fmBINFiles);

  if not FileExists(LFileName) then
    Exit;

  FillChar(GControllerConfig, SizeOf(GControllerConfig), $00);

{$I-}
  Assign(LFile, LFileName);
  FileMode := fmReadOnly;
  Reset(LFile, frsBinaryFileRecordSize);

  BlockRead(LFile, LFileSignature, SizeOf(kFileSignature));
  BlockRead(LFile, GControllerConfig, SizeOf(GControllerConfig));
  BlockRead(LFile, GWSSAudioConfig, SizeOf(GWSSAudioConfig));
  BlockRead(LFile, GSBAudioConfig, SizeOf(GSBAudioConfig));
  BlockRead(LFile, GCodecMixerConfig, SizeOf(GCodecMixerConfig));

  Close(LFile);
{$I+}

  SetupLoadConfig := (IOResult = 0) and (LFileSignature = kFileSignature);
end;

function SetupSaveConfig: Boolean;
var
  LFile: File;
  LFileName: String;

begin
  SetupSaveConfig := False;

  LFileName := FileReplaceExt(FExpand(ParamStr(0)), fmBINFiles);

{$I-}
  Assign(LFile, LFileName);
  FileMode := fmReadWrite;
  Rewrite(LFile, frsBinaryFileRecordSize);

  BlockWrite(LFile, kFileSignature, SizeOf(kFileSignature));
  BlockWrite(LFile, GControllerConfig, SizeOf(GControllerConfig));
  BlockWrite(LFile, GWSSAudioConfig, SizeOf(GWSSAudioConfig));
  BlockWrite(LFile, GSBAudioConfig, SizeOf(GSBAudioConfig));
  BlockWrite(LFile, GCodecMixerConfig, SizeOf(GCodecMixerConfig));

  Close(LFile);
{$I+}

  SetupSaveConfig := IOResult = 0;
end;

procedure SetupDefaultConfig;
begin
  { Controller Register Configuration }

  { Mode Control Register 1 Bits }
  GControllerConfig.BitMOD := kSetupBitMODDefault;
  GControllerConfig.BitPDN := kSetupBitPDNDefault;
  GControllerConfig.BitGPEN := kSetupBitGPENDefault;

  { Mode Control Register 2 Bits }
  GControllerConfig.BitOPL4 := kSetupBitOPL4Default;

  { Mode Control Register 3 Bits }
  GControllerConfig.BitFMAP := kSetupBitFMAPDefault;
  GControllerConfig.BitCMDPAS := kSetupBitCMDPASDefault;

  { Mode Control Register 4 Bits }
  GControllerConfig.BitADPCMEN := kSetupBitADPCMENDefault;
  GControllerConfig.BitGPOUT := kSetupBitGPOUTDefault;
  GControllerConfig.BitPNPMODE := kSetupBitPNPMODEDefault;
  GControllerConfig.BitFMCLK := kSetupBitFMCLKDefault;
  GControllerConfig.BitSILENCE := kSetupBitSILENCEDefault;

  { Mode Control Register 5 Bits }
  GControllerConfig.BitAVCEN := kSetupBitAVCENDefault;
  GControllerConfig.BitOPL5 := kSetupBitOPL5Default;
  GControllerConfig.BitSHPASS := kSetupBitSHPASSDefault;
  GControllerConfig.BitSBACCESS := kSetupBitSBACCESSDefault;
  GControllerConfig.BitCFIFO := kSetupBitCFIFODefault;
  GControllerConfig.BitEPEN := kSetupBitEPENDefault;
  GControllerConfig.BitCFIX := kSetupBitCFIXDefault;

  { Mode Control Register 6 Bits }
  GControllerConfig.BitMPU401 := kSetupBitMPU401Default;
  GControllerConfig.BitDRQTMEN := kSetupBitDRQTMENDefault;
  GControllerConfig.BitAUDIOEN := kSetupBitAUDIOENDefault;

  GControllerConfig.WSSBASE := kSetupWSSBASEDefault;
  GControllerConfig.WSSIRQ := kSetupWSSIRQDefault;
  GControllerConfig.WSSDRQ := kSetupWSSDRQDefault;

  GControllerConfig.SBBASE := kSetupSBBASEDefault;
  GControllerConfig.SBIRQ := kSetupSBIRQDefault;
  GControllerConfig.SBDRQ := kSetupSBDRQDefault;
  GControllerConfig.SBDSPVersion := kSetupSBDSPVerDefault;

  GControllerConfig.MPUBASE := kSetupMPUBASEDefault;
  GControllerConfig.MPUIRQ := kSetupMPUIRQDefault;

  GControllerConfig.CDBASE := kSetupCDBASEDefault;
  GControllerConfig.CDIRQ := kSetupCDIRQDefault;
  GControllerConfig.CDDRQ := kSetupCDDRQDefault;
  GControllerConfig.IDECDROM := kSetupIDECDROMDefault;

  { Codec WSS Mode Audio Configuration }

  GWSSAudioConfig.SampleRate := kSetupWSSSmpRateDefault;
  GWSSAudioConfig.BitDepth := kSetupWSSBitDepthDefault;
  GWSSAudioConfig.SoundOutput := kSetupWSSSndOutDefault;

  { Codec SB Mode Audio Configuration }

  GSBAudioConfig.SampleRate := kSetupSBSmpRateDefault;
  GSBAudioConfig.BitDepth := kSetupSBBitDepthDefault;
  GSBAudioConfig.SoundOutput := kSetupSBSndOutDefault;
end;

function SetupGetInitMode: TAIFInitMode;
begin
  case GControllerConfig.BitMOD of
    bsNotSet:
      SetupGetInitMode := imSB;

    bsSet:
      SetupGetInitMode := imWSS;

  end;
end;

procedure SetupStart;
var
  LPositionY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kSetupStartupDelay);

  VideoInitialize(LPositionY, LVideoRAMData);
  ScreenInitialize;

  UIDraw;
  UILoop;

  ScreenFinalize;
  VideoFinalize(LPositionY, LVideoRAMData);
end;

end.
