{ --------------------------------------------------------------------------- }
{ - Audio Interface - Setup Subprogram (setup.pas)                          - }
{ - Copyright (C) 1998-2020 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Setup;

interface

uses
  Codec,
  Control;

var
  GControllerConfig: TControllerConfig;
  GWSSAudioConfig: TCodecAudioConfig;
  GSBAudioConfig: TCodecAudioConfig;
  GCodecMixerConfig: TCodecMixerConfig;

function SetupLoadConfig: Boolean;
function SetupSaveConfig: Boolean;

procedure SetupDefaultConfig;

procedure SetupStart;

implementation

uses
  Crt,
  Dos,
  Consts,
  Mixer,
  Routines,
  Screen,
  Types,
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
    WSSSampleRate: TSampleRate;
    WSSBitDepth: TBitDepth;
    WSSSoundOutput: TSoundOutput;
    SBSampleRate: TSampleRate;
    SBBitDepth: TBitDepth;
    SBSoundOutput: TSoundOutput;
    SBDSPVersion: TSBDSPVersion;
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

  GSVWSSIRQ := IfThenElse(LWSSIRQ = $FF, sEnabledDisabled[False], IntToStr(kWSSIRQs[AIndex]));
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

  GSVWSSDRQ := IfThenElse(LWSSDRQ = $FF, sEnabledDisabled[False], IntToStr(kWSSDRQs[AIndex]));
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

  GSVSBIRQ := IfThenElse(LSBIRQ = $FF, sEnabledDisabled[False], IntToStr(kSBIRQs[AIndex]));
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

  GSVSBDRQ := IfThenElse(LSBDRQ = $FF, sEnabledDisabled[False], IntToStr(kSBDRQs[AIndex]));
end;

function GSVMPU401(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.MPU401 := TBitStatus(AIndex);
  end;

  GSVMPU401 := sBSEnabledDisabled[TBitStatus(AIndex)];
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

  GSVGamePort := sBSEnabledDisabled[TBitStatus(AIndex)];
end;

function GSVIDECDROM(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.IDECDROM := TBitStatus(AIndex);
  end;

  GSVIDECDROM := sBSEnabledDisabled[TBitStatus(AIndex)];
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
    IGSetupConfig.WSSSampleRate := TSampleRate(AIndex);
  end;

  GSVWSSSampleRate := AddSizeSeparator(IntToStr(kSampleRates[TSampleRate(AIndex)].Frequency) + cSpace + sHz, True);
end;

function GSVWSSBitDepth(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.WSSBitDepth := TBitDepth(AIndex);
  end;

  GSVWSSBitDepth := sBitDepth[TBitDepth(AIndex)];
end;

function GSVWSSSoundOutput(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.WSSSoundOutput := TSoundOutput(AIndex);
  end;

  GSVWSSSoundOutput := sSoundOutput[TSoundOutput(AIndex)];
end;

function GSVSBSampleRate(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBSampleRate := TSampleRate(AIndex);
  end;

  GSVSBSampleRate := AddSizeSeparator(IntToStr(kSampleRates[TSampleRate(AIndex)].Frequency) + cSpace + sHz, True);
end;

function GSVSBBitDepth(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBBitDepth := TBitDepth(AIndex);
  end;

  GSVSBBitDepth := sBitDepth[TBitDepth(AIndex)];
end;

function GSVSBSoundOutput(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBSoundOutput := TSoundOutput(AIndex);
  end;

  GSVSBSoundOutput := sSoundOutput[TSoundOutput(AIndex)];
end;

function GSVSBDSPVersion(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBDSPVersion := TSBDSPVersion(AIndex);
  end;

  GSVSBDSPVersion := sSBDSPVersions[TSBDSPVersion(AIndex)];
end;

function GSVSBADPCM(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.SBADPCM := TBitStatus(AIndex);
  end;

  GSVSBADPCM := sBSEnabledDisabled[TBitStatus(AIndex)];
end;

function GSVCFIFO(const AIndex: Byte; const ASetValue: Boolean): String;
begin
  if ASetValue then
  begin
    IGSetupConfig.CFIFO := TBitStatus(AIndex);
  end;

  GSVCFIFO := sBSEnabledDisabled[TBitStatus(AIndex)];
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
    Byte(High(sBSEnabledDisabled)),
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
    Byte(High(sBSEnabledDisabled)),
    Byte(IGSetupConfig.GamePort),
    GSVGamePort
  );

  InitOption(
    soIDECDROM,
    sSetupIDECDROM,
    Byte(High(sBSEnabledDisabled)),
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
    Byte(High(sBSEnabledDisabled)),
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
    Byte(High(sBSEnabledDisabled)),
    Byte(IGSetupConfig.SBADPCM),
    GSVSBADPCM
  );

  InitOption(
    soCFIFO,
    sSetupCFIFO,
    Byte(High(sBSEnabledDisabled)),
    Byte(IGSetupConfig.CFIFO),
    GSVCFIFO
  );

  InitOption(
    soAVC,
    sSetupAVC,
    Byte(High(sBSEnabledDisabled)),
    Byte(IGSetupConfig.AVC),
    GSVAVC
  );
end;

procedure DrawOption(const APositionY: Byte; const AName, AValue: String);
begin
  VideoWriteStringAt(kSetupNameX, APositionY, AName, clSetupFore, clSetupBack);
  VideoWriteCharAttrAt(kSetupValueX - 2, APositionY, cSemicolon, VideoAttribute(clSetupFore, clSetupBack));
  VideoWriteStringAt(kSetupValueX, APositionY, AValue, clSetupFore, clSetupBack);
end;

procedure DrawOptions;
var
  LSetupOption: TSetupOption;
  LSetupOptionData: TSetupOptionData;

begin
  VideoWriteRegion(1, 2, 49, 25, cSpace, VideoAttribute(clSetupFore, clSetupBack));

  for LSetupOption := Low(TSetupOption) to High(TSetupOption) do
  begin
    LSetupOptionData := IGSetupOptions[LSetupOption];

    DrawOption(LSetupOptionData.PositionY, LSetupOptionData.Name,
      LSetupOptionData.GSVFunction(LSetupOptionData.Index, False));
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

  VideoHighlightRegion(1, IGSetupOptions[ASetupOption].PositionY, 23, 1, LAttribute);
  VideoHighlightRegion(24, IGSetupOptions[ASetupOption].PositionY, 26, 1, LEditAttribute);
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

  VideoWriteRegion(24, LSetupOptionData.PositionY, 26, 1, cSpace, VideoAttribute(clRed, clRed));
  VideoWriteStringAt(kSetupValueX, LSetupOptionData.PositionY, LSetupOptionData.GSVFunction(LIndex, True), clYellow, clRed);

  IGSetupOptions[ASetupOption].Index := LIndex;
end;

procedure DrawCommand(const ALeft, ATop, AHighlight, AColor, ABackground: Byte; const AShortcut, ADescription: String);
begin
  VideoWriteStringAt(ALeft, ATop, AShortcut, AHighlight, ABackground);
  VideoWriteStringAt(ALeft + 5, ATop, ADescription, AColor, ABackground);
end;

procedure DrawCommands;
begin
  VideoWriteRegion(50, 2, 31, 25, cSpace, VideoAttribute(clSetupCmdFore, clSetupCmdBack));

  VideoWriteStringAt(kSetupCmdX, 3, sSetupCmdProgramCmds, clSetupCmdHeader, clSetupCmdBack);
  DrawCommand(kSetupCmdX, 4, clSetupCmdHigh, clSetupCmdFore, clSetupCmdBack, sSetupCmdF8, sSetupCmdDefaultConfig);
  DrawCommand(kSetupCmdX, 5, clSetupCmdHigh, clSetupCmdFore, clSetupCmdBack, sSetupCmdF9, sSetupCmdReloadConfig);
  DrawCommand(kSetupCmdX, 6, clSetupCmdHigh, clSetupCmdFore, clSetupCmdBack, sSetupCmdF10, sSetupCmdSaveExit);
  DrawCommand(kSetupCmdX, 7, clSetupCmdHigh, clSetupCmdFore, clSetupCmdBack, sSetupCmdESC, sSetupCmdExit);

  VideoWriteStringAt(kSetupCmdX, 11, sSetupCmdOptionCmds, clSetupCmdHeader, clSetupCmdBack);
  DrawCommand(kSetupCmdX, 12, clSetupCmdHigh, clSetupCmdFore, clSetupCmdBack, sMixerCmdUpDown, sSetupCmdSelectOption);
  DrawCommand(kSetupCmdX, 13, clSetupCmdHigh, clSetupCmdFore, clSetupCmdBack, sMixerCmdLeftRight, sSetupCmdModifyOption);
end;

procedure DrawRevisions;
var
  LControllerRevision: Byte;
  LRevisionString: String;

begin
  LControllerRevision := ControllerGetRevision;
  LRevisionString := IntToStr(LControllerRevision div 10) + cFullStop + IntToStr(LControllerRevision mod 10);

  VideoWriteStringAt(kSetupCmdX, 23, sSetupSoundController, clSetupCmdHeader, clSetupCmdBack);
  VideoWriteStringAt(kSetupCmdX, 24, sSetupOPTi82c924 + LRevisionString, clSetupCmdFore, clSetupCmdBack);
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
  DrawRevisions;
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

  if (IOResult <> 0) or (LFileSignature <> kFileSignature) then
    Exit;

  SetupLoadConfig := True;
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
  Rewrite(LFile, 1);

  BlockWrite(LFile, kFileSignature, SizeOf(kFileSignature));
  BlockWrite(LFile, GControllerConfig, SizeOf(GControllerConfig));
  BlockWrite(LFile, GWSSAudioConfig, SizeOf(GWSSAudioConfig));
  BlockWrite(LFile, GSBAudioConfig, SizeOf(GSBAudioConfig));
  BlockWrite(LFile, GCodecMixerConfig, SizeOf(GCodecMixerConfig));

  Close(LFile);
{$I+}

  if IOResult <> 0 then
    Exit;

  SetupSaveConfig := True;
end;

procedure SetupDefaultConfig;
begin
  { Controller Register Configuration }

  { Mode Control Register 1 Bits }
  GControllerConfig.BitMOD := bsNotSet;
  GControllerConfig.BitPDN := bsNotSet;
  GControllerConfig.BitGPEN := bsSet;

  { Mode Control Register 2 Bits }
  GControllerConfig.BitOPL4 := bsNotSet;

  { Mode Control Register 3 Bits }
  GControllerConfig.BitFMAP := bsNotSet;
  GControllerConfig.BitCMDPAS := bsSet;

  { Mode Control Register 4 Bits }
  GControllerConfig.BitADPCMEN := bsSet;
  GControllerConfig.BitGPOUT := bsNotSet;
  GControllerConfig.BitPNPMODE := bsSet;
  GControllerConfig.BitFMCLK := bsNotSet;
  GControllerConfig.BitSILENCE := bsNotSet;

  { Mode Control Register 5 Bits }
  GControllerConfig.BitAVCEN := bsSet;
  GControllerConfig.BitOPL5 := bsNotSet;
  GControllerConfig.BitSHPASS := bsSet;
  GControllerConfig.BitSBACCESS := bsNotSet;
  GControllerConfig.BitCFIFO := bsSet;
  GControllerConfig.BitEPEN := bsSet;
  GControllerConfig.BitCFIX := bsSet;

  { Mode Control Register 6 Bits }
  GControllerConfig.BitMPU401 := bsSet;
  GControllerConfig.BitDRQTMEN := bsSet;
  GControllerConfig.BitAUDIOEN := bsSet;

  GControllerConfig.WSSBASE := $0530;
  GControllerConfig.WSSIRQ := $FF;
  GControllerConfig.WSSDRQ := 1;

  GControllerConfig.SBBASE := $0220;
  GControllerConfig.SBIRQ := 5;
  GControllerConfig.SBDRQ := 1;
  GControllerConfig.SBDSPVersion := sdVersion32;

  GControllerConfig.MPUBASE := $330;
  GControllerConfig.MPUIRQ := 9;

  GControllerConfig.CDBASE := $0340;
  GControllerConfig.CDIRQ := $FF;
  GControllerConfig.CDDRQ := 3;
  GControllerConfig.IDECDROM := bsNotSet;

  { Codec WSS Mode Audio Configuration }

  GWSSAudioConfig.SampleRate := sr44100;
  GWSSAudioConfig.BitDepth := bd16bit;
  GWSSAudioConfig.SoundOutput := soStereo;

  { Codec SB Mode Audio Configuration }

  GSBAudioConfig.SampleRate := sr22050;
  GSBAudioConfig.BitDepth := bd8bit;
  GSBAudioConfig.SoundOutput := soStereo;
end;

procedure SetupStart;
var
  LSaveY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kSetupStartupDelay);

  LSaveY := WhereY;

  GetMem(LVideoRAMData, kVGARAMSize);
  VideoSaveScreen(LVideoRAMData);
  VideoClearScreen;
  VideoEnableHighColors;
  VideoDisableCursor;

  UIDraw;
  UILoop;

  VideoEnableCursor;
  VideoDisableHighColors;
  VideoRestoreScreen(LVideoRAMData);
  FreeMem(LVideoRAMData, kVGARAMSize);

  GotoXY(k80x25Left, LSaveY);
end;

end.
