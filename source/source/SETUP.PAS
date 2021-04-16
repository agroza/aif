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
  Crt,
  Dos,
  Consts,
  Mixer,
  Routines,
  Screen,
  Video;

type
  TFileSignature = array[0..7] of Char;

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

  TSetupOptionData = record
    Name: String;
    PositionY: Byte;
    Low: Byte;
    High: Byte;
    Index: Byte;
    GSVFunction: TGSVFunction;
  end;

  TSetupConfig = record
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

const
  kFileSignature: TFileSignature = 'AG86.BIN';

  kWSSBASEs: array[0..3] of Word = ( $0530, $0E80, $0F40, $0604 );
  kWSSIRQs: array[0..4] of Byte = ( $07, $09, $0A, $0B, $FF );
  kWSSDRQs: array[0..3] of Byte = ( $00, $01, $03, $FF );
  kSBBASEs: array[0..1] of Word = ( $0220, $0240 );
  kSBIRQs: array[0..3] of Byte = ( $05, $07, $0A, $FF );
  kSBDRQs: array[0..3] of Byte = ( $00, $01, $03, $FF );
  kMPUBASEs: array[0..3] of Word = ( $0300, $0310, $0320, $0330 );
  kMPUIRQs: array[0..3] of Byte = ( $05, $07, $09, $0A );

  kUICommands: array[0..5] of TUICommand = (
    ( Y: 4; Accelerator: sSetupCmdF8; Name: sSetupCmdDefaultConfig ),
    ( Y: 5; Accelerator: sSetupCmdF9; Name: sSetupCmdReloadConfig ),
    ( Y: 6; Accelerator: sSetupCmdF10; Name: sSetupCmdSaveExit ),
    ( Y: 8; Accelerator: sSetupCmdESC; Name: sSetupCmdExit ),
    ( Y: 12; Accelerator: sSetupCmdUpDown; Name: sSetupCmdSelectOption ),
    ( Y: 13; Accelerator: sSetupCmdLeftRight; Name: sSetupCmdModifyOption )
  );

var
  IGSetupOptions: array[TSetupOption] of TSetupOptionData;
  IGSetupConfig: TSetupConfig;

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

procedure InitOption(const ASetupOption: TSetupOption; const AName: String;
  const AHigh, AIndex: Byte; const AGSVFunction: TGSVFunction);
begin
  IGSetupOptions[ASetupOption].Name := AName;
  IGSetupOptions[ASetupOption].High := AHigh;
  IGSetupOptions[ASetupOption].Index := AIndex;
  IGSetupOptions[ASetupOption].GSVFunction := AGSVFunction;
end;

procedure InitOptions;
var
  LSetupOption: TSetupOption;

begin
  for LSetupOption := Low(TSetupOption) to High(LSetupOption) do
  begin
    IGSetupOptions[LSetupOption].PositionY := Byte(LSetupOption) + 2;
    IGSetupOptions[LSetupOption].Low := 0;
  end;

  InitOption(
    soAIFMode,
    sSetupAIFMode,
    Byte(High(sAIFMode)),
    Byte(IGSetupConfig.AIFMode),
    GSVAIFMode
  );

  InitOption(
    soWSSBASE,
    sSetupWSSBASE,
    High(kWSSBASEs),
    LocateWord(IGSetupConfig.WSSBASE, kWSSBASEs),
    GSVWSSBASE
  );

  InitOption(
    soWSSIRQ,
    sSetupWSSIRQ,
    High(kWSSIRQs),
    LocateByte(IGSetupConfig.WSSIRQ, kWSSIRQs),
    GSVWSSIRQ
  );

  InitOption(
    soWSSDRQ,
    sSetupWSSDRQ,
    High(kWSSDRQs),
    LocateByte(IGSetupConfig.WSSDRQ, kWSSDRQs),
    GSVWSSDRQ
  );

  InitOption(
    soSBBASE,
    sSetupSBBASE,
    High(kSBBASEs),
    LocateWord(IGSetupConfig.SBBASE, kSBBASEs),
    GSVSBBASE
  );

  InitOption(
    soSBIRQ,
    sSetupSBIRQ,
    High(kSBIRQs),
    LocateByte(IGSetupConfig.SBIRQ, kSBIRQs),
    GSVSBIRQ
  );

  InitOption(
    soSBDRQ,
    sSetupSBDRQ,
    High(kSBDRQs),
    LocateByte(IGSetupConfig.SBDRQ, kSBDRQs),
    GSVSBDRQ
  );

  InitOption(
    soMPU401,
    sSetupMPU401,
    Byte(High(sBSDisabledEnabled)),
    Byte(IGSetupConfig.MPU401),
    GSVMPU401
  );

  InitOption(
    soMPUBASE,
    sSetupMPUBASE,
    High(kMPUBASEs),
    LocateWord(IGSetupConfig.MPUBASE, kMPUBASEs),
    GSVMPUBASE
  );

  InitOption(
    soMPUIRQ,
    sSetupMPUIRQ,
    High(kMPUIRQs),
    LocateByte(IGSetupConfig.MPUIRQ, kMPUIRQs),
    GSVMPUIRQ
  );

  InitOption(
    soGamePort,
    sSetupGamePort,
    Byte(High(sBSDisabledEnabled)),
    Byte(IGSetupConfig.GamePort),
    GSVGamePort
  );

  InitOption(
    soIDECDROM,
    sSetupIDECDROM,
    Byte(High(sBSDisabledEnabled)),
    Byte(IGSetupConfig.IDECDROM),
    GSVIDECDROM
  );

  InitOption(
    soCFIX,
    sSetupCFIX,
    Byte(High(sCFIX)),
    Byte(IGSetupConfig.CFIX),
    GSVCFIX
  );

  InitOption(
    soFMAP,
    sSetupFMAP,
    Byte(High(sBSDisabledEnabled)),
    Byte(IGSetupConfig.FMAP),
    GSVFMAP
  );

  InitOption(
    soWSSSampleRate,
    sSetupWSSSampleRate,
    Byte(High(kSampleRates)),
    Byte(IGSetupConfig.WSSSampleRate),
    GSVWSSSampleRate
  );

  InitOption(
    soWSSBitDepth,
    sSetupWSSBitDepth,
    Byte(High(sBitDepth)),
    Byte(IGSetupConfig.WSSBitDepth),
    GSVWSSBitDepth
  );

  InitOption(
    soWSSSoundOutput,
    sSetupWSSSoundOutput,
    Byte(High(sSoundOutput)),
    Byte(IGSetupConfig.WSSSoundOutput),
    GSVWSSSoundOutput
  );

  InitOption(
    soSBSampleRate,
    sSetupSBSampleRate,
    Byte(High(kSampleRates)),
    Byte(IGSetupConfig.SBSampleRate),
    GSVSBSampleRate
  );

  InitOption(
    soSBBitDepth,
    sSetupSBBitDepth,
    Byte(High(sBitDepth)),
    Byte(IGSetupConfig.SBBitDepth),
    GSVSBBitDepth
  );

  InitOption(
    soSBSoundOutput,
    sSetupSBSoundOutput,
    Byte(High(sSoundOutput)),
    Byte(IGSetupConfig.SBSoundOutput),
    GSVSBSoundOutput
  );

  InitOption(
    soSBDSPVersion,
    sSetupSBDSPVersion,
    Byte(High(sSBDSPVersions)),
    Byte(IGSetupConfig.SBDSPVersion),
    GSVSBDSPVersion
  );

  InitOption(
    soSBADPCM,
    sSetupSBADPCM,
    Byte(High(sBSDisabledEnabled)),
    Byte(IGSetupConfig.SBADPCM),
    GSVSBADPCM
  );

  InitOption(
    soCFIFO,
    sSetupCFIFO,
    Byte(High(sBSDisabledEnabled)),
    Byte(IGSetupConfig.CFIFO),
    GSVCFIFO
  );

  InitOption(
    soAVC,
    sSetupAVC,
    Byte(High(sBSDisabledEnabled)),
    Byte(IGSetupConfig.AVC),
    GSVAVC
  );
end;

procedure DrawOption(const APositionY: Byte; const AName, AValue: String);
var
  LKeyValueData: TKeyValueData;

begin
  LKeyValueData.NameX := kSetupNameX;
  LKeyValueData.ValueX := kSetupValueX;
  LKeyValueData.PositionY := APositionY;
  LKeyValueData.Colors.Foreground := clSetupFore;
  LKeyValueData.Colors.Background := clSetupBack;
  LKeyValueData.Name := AName;
  LKeyValueData.Value := AValue;

  ScreenDrawKeyValue(LKeyValueData);
end;

procedure DrawOptions;
var
  LSetupOption: TSetupOption;
  LSetupOptionData: TSetupOptionData;

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
    LSetupOptionData := IGSetupOptions[LSetupOption];

    DrawOption(
      LSetupOptionData.PositionY,
      LSetupOptionData.Name,
      LSetupOptionData.GSVFunction(LSetupOptionData.Index, False)
    );
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
    IGSetupOptions[ASetupOption].PositionY,
    kSetupOptionWidth,
    kSetupOptionHeight,
    LAttribute
  );

  VideoHighlightRegion(
    kSetupOptionEditX,
    IGSetupOptions[ASetupOption].PositionY,
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
  LSetupOptionData := IGSetupOptions[ASetupOption];
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

  IGSetupOptions[ASetupOption].Index := LIndex;
end;

procedure DrawCommands;
var
  I: Byte;

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

  for I := Low(kUICommands) to High(kUICommands) do
  begin
    ScreenDrawCommand(
      kSetupCmdX,
      kUICommands[I].Y,
      clSetupCmdHigh,
      clSetupCmdFore,
      clSetupCmdBack,
      StrPas(kUICommands[I].Accelerator),
      StrPas(kUICommands[I].Name)
    );
  end;
end;

procedure DrawRevision;
var
  LControllerRevision: Byte;
  LRevisionString: String;

begin
  LControllerRevision := ControllerGetRevision;
  LRevisionString := IntToStr(LControllerRevision div 10) + cFullStop + IntToStr(LControllerRevision mod 10);

  VideoWriteStringAt(
    kSetupCmdX,
    23,
    sSetupSoundController,
    clSetupCmdHeader,
    clSetupCmdBack
  );

  VideoWriteStringAt(
    kSetupCmdX,
    24,
    sSetupOPTi82c924 + LRevisionString,
    clSetupCmdFore,
    clSetupCmdBack
  );
end;

procedure DrawConfig;
begin
  InitConfig;
  InitOptions;
  DrawOptions;
end;

procedure UIDraw;
begin
  ScreenDrawTitleBar(clInterfaceFore, clInterfaceBack, clInterfaceFore, sSetupTitle);

  DrawConfig;
  DrawCommands;
  DrawRevision;
end;

procedure UILoop;
var
  LSetupOption: TSetupOption;

begin
  LSetupOption := Low(TSetupOption);
  HighlightOption(LSetupOption, True);

  while True do
  begin
    case UpCase(ReadKey) of
      kKeyExtended:
        begin
          case ReadKey of
            kKeyF8:
              begin
                SetupDefaultConfig;
                DrawConfig;

                HighlightOption(LSetupOption, True);
              end;

            kKeyF9:
              begin
                if SetupLoadConfig then
                begin
                  DrawConfig;
                end;

                HighlightOption(LSetupOption, True);
              end;

            kKeyF10:
              begin
                ApplyConfig;
                SetupSaveConfig;

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
        Break;

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

  LFileName := ReplaceFileExt(FExpand(ParamStr(0)), fmBINFiles);

  if not FileExists(LFileName) then
    Exit;

  FillChar(GControllerConfig, SizeOf(GControllerConfig), $00);

{$I-}
  Assign(LFile, LFileName);
  FileMode := fmReadOnly;
  Reset(LFile, 1);

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

  LFileName := ReplaceFileExt(FExpand(ParamStr(0)), fmBINFiles);

{$I-}
  Assign(LFile, LFileName);
  FileMode := fmReadWrite;
  Rewrite(LFile, 1);

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
  LSaveY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kSetupStartupDelay);

  LSaveY := WhereY;

  GetMem(LVideoRAMData, kVGARAMSize);
  VideoStoreScreen(LVideoRAMData);
  VideoClearScreen;
  VideoEnableHighColors;
  VideoDisableCursor;

  ScreenSetVVColors;

  UIDraw;
  UILoop;

  ScreenRestoreColors;

  VideoEnableCursor;
  VideoDisableHighColors;
  VideoRestoreScreen(LVideoRAMData);
  FreeMem(LVideoRAMData, kVGARAMSize);

  GotoXY(k80x25Left, LSaveY);
end;

end.
