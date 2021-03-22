{ --------------------------------------------------------------------------- }
{ - Audio Interface - Audio Codec Interface (codec.pas)                     - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - Portions Copyright (C) 2019 Jan Knipperts                               - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Codec;

interface

uses
  Types;

type
  TCodecDeviceType = (
    cdtAUX1,
    cdtAUX2,
    cdtDAC
  );

  TCodecInputDeviceType = (
    cidtLineIn,
    cidtAUX1In,
    cidtMicrophone,
    cidtPostMixedDAC
  );

  TCodecOutputFormat = (
    cof8bitUlawCompanded,
    cof8bitAlawCompanded,
    cof8bitUnsignedPCM,
    cof16bitTwosComplementPCM
  );

  TCodecAudioConfig = record
    SampleRate: TSampleRate;
    BitDepth: TBitDepth;
    SoundOutput: TSoundOutput;
  end;

  TCodecMixerConfig = record
    DACLeft: Byte;
    DACRight: Byte;
    AUX1Left: Byte;
    AUX1Right: Byte;
    AUX2Left: Byte;
    AUX2Right: Byte;
    InputDeviceLeft: TCodecInputDeviceType;
    InputDeviceRight: TCodecInputDeviceType;
    InputGainLeft: Byte;
    InputGainRight: Byte;
    MicGainLeft: Boolean;
    MicGainRight: Boolean;
    DigitalMix: Boolean;
    DMELeftRight: Byte;
    OutputsEnabled: Boolean;
  end;

  TSampleRateData = record
    Divider: Byte;
    Crystal: Byte;
    Frequency: Word;
  end;

const
  kSampleRates: array[TSampleRate] of TSampleRateData = (
    ( Divider: 0; Crystal: 2; Frequency:  5512 ),
    ( Divider: 7; Crystal: 2; Frequency:  6615 ),
    ( Divider: 0; Crystal: 1; Frequency:  8000 ),
    ( Divider: 7; Crystal: 1; Frequency:  9600 ),
    ( Divider: 1; Crystal: 2; Frequency: 11025 ),
    ( Divider: 1; Crystal: 1; Frequency: 16000 ),
    ( Divider: 2; Crystal: 2; Frequency: 18900 ),
    ( Divider: 3; Crystal: 2; Frequency: 22050 ),
    ( Divider: 2; Crystal: 1; Frequency: 27428 ),
    ( Divider: 3; Crystal: 1; Frequency: 32000 ),
    ( Divider: 6; Crystal: 2; Frequency: 33075 ),
    ( Divider: 4; Crystal: 2; Frequency: 37800 ),
    ( Divider: 5; Crystal: 2; Frequency: 44100 ),
    ( Divider: 6; Crystal: 1; Frequency: 48000 )
  );

var
  GCodecRevision: Byte;

function CodecDetect(const AWSSBASE: Word): Boolean;
function CodecDetectNew: Boolean;
function CodecDetectWSS: Boolean;

function CodecInitialize: Boolean;

procedure CodecGetOutputFormat(var AFrequency: Word; var AFormat: TCodecOutputFormat; var ASoundOutput: TSoundOutput);
procedure CodecSetOutputFormat(const AFrequency: Word; const AFormat: TCodecOutputFormat; const ASoundOutput: TSoundOutput);

function CodecGetInputGain(const AChannel: TSoundChannel): Byte;
function CodecGetInputDevice(const AChannel: TSoundChannel): TCodecInputDeviceType;
function CodecGetMicGain(const AChannel: TSoundChannel): Boolean;
procedure CodecSetInputConfig(const AInputDeviceType: TCodecInputDeviceType; const AMicrophoneGain: Boolean;
  const AInputGain: Byte; const AChannel: TSoundChannel);

procedure CodecSetDigitalMix(const AEnabled: Boolean; AVolume: Byte);

function CodecGetVolume(const ADeviceType: TCodecDeviceType; const AChannel: TSoundChannel): Byte;
procedure CodecSetVolume(const ADeviceType: TCodecDeviceType; const AChannel: TSoundChannel; AVolume: Byte);

procedure CodecMuteAUX1(const AChannel: TSoundChannel; const AMute: Boolean);
procedure CodecMuteAUX2(const AChannel: TSoundChannel; const AMute: Boolean);
procedure CodecMuteDAC(const AChannel: TSoundChannel; const AMute: Boolean);

procedure CodecSetLEDEnabled(const AValue: Boolean);

function CodecGetOutputsEnabled: Boolean;
procedure CodecSetOutputsEnabled(const AValue: Boolean);

implementation

uses
  Routines;

type
  TCodecConfig = record
    WSSPort: Word;
    Address: Word;
    Data: Word;
    Status: Word;
    PIO: Word;
  end;

const
  { General Codec Related Constants }
  kRetries                            = $FFFF;

  { Codec Direct Registers }
  kREGISTER_CODEC_INDEX_OFFSET        = 4;
  kREGISTER_CODEC_INDEXED_DATA_OFFSET = 5;
  kREGISTER_CODEC_STATUS_OFFSET       = 6;
  kREGISTER_CODEC_DIRECT_DATA_OFFSET  = 7;

  { Codec Indirect Registers }
  kREGISTER_LEFT_INPUT_CONTROL        = $00;
  kREGISTER_RIGHT_INPUT_CONTROL       = $01;
  kREGISTER_LEFT_AUX1_INPUT_CONTROL   = $02;
  kREGISTER_RIGHT_AUX1_INPUT_CONTROL  = $03;
  kREGISTER_LEFT_AUX2_INPUT_CONTROL   = $04;
  kREGISTER_RIGHT_AUX2_INPUT_CONTROL  = $05;
  kREGISTER_LEFT_DAC_CONTROL          = $06;
  kREGISTER_RIGHT_DAC_CONTROL         = $07;
  kREGISTER_CLOCK_DATA_FORMAT         = $08;
  kREGISTER_INTERFACE_CONFIGURATION   = $09;
  kREGISTER_PIN_CONTROL               = $0A;
  kREGISTER_TEST_INITIALIZATION       = $0B;
  kREGISTER_MISCELLANEOUS_CONTROL     = $0C;
  kREGISTER_DIGITAL_MIX               = $0D;
  kREGISTER_UPPER_BASE_COUNT          = $0E;
  kREGISTER_LOWER_BASE_COUNT          = $0F;
  kREGISTER_ALT_FEAT_ENABLE           = $10;

  { Index Register Bits }
  kBitMCE                             = 6;

  { Left Input Control Register Bits }
  kBitLMGE                            = 5;

  { Right Input Control Register }
  kBitRMGE                            = 5;

  { Left Auxiliary #1 Input Control Register }
  kBitLMX1                            = 7;

  { Right Auxiliary #1 Input Control Register }
  kBitRMX1                            = 7;

  { Left Auxiliary #2 Input Control Register }
  kBitLMX2                            = 7;

  { Right Auxiliary #2 Input Control Register }
  kBitRMX2                            = 7;

  { Left DAC Control Register }
  kBitLDM                             = 7;

  { Right DAC Control Register }
  kBitRDM                             = 7;

  { Clock and Data Format Register }
  kBitSM                              = 4;
  kBitCSS                             = 0;

  { Interface Configuration Register }
  kBitACAL                            = 3;
  kBitSDC                             = 2;
  kBitCEN                             = 1;
  kBitPEN                             = 0;

  { Pin Control Register }
  kBitXCTL1                           = 7;
  kBitXCTL0                           = 6;
  kBitIEN                             = 1;

  { Test and Initialization Register }
  kBitACI                             = 5;

  { Miscellaneous Information Register }
  kBitMODE2                           = 6;

  { Digital Mix Control Register }
  kBitDME                             = 0;

  kRegisterResetValue: array[0..15] of Byte = (
    $00, { Left Input Control Register }
    $00, { Right Input Control Register }
    $80, { Left Auxiliary #1 Input Control Register }
    $80, { Right Auxiliary #1 Input Control Register }
    $80, { Left Auxiliary #2 Input Control Register }
    $80, { Right Auxiliary #2 Input Control Register }
    $80, { Left DAC Control Register }
    $80, { Right DAC Control Register }
    $00, { Clock and Data Format Register }
    $08, { Interface Configuration Register }
    $42, { Pin Control Register }
    $00, { Test and Initialization Register }
    $0A, { Miscellaneous Control Register }
    $00, { Digital Mix Control Register }
    $00, { Upper Base Count Register }
    $00  { Lower Base Count Register }
  );

  kDeviceTypes: array[TCodecDeviceType] of Byte = (
    kREGISTER_LEFT_AUX1_INPUT_CONTROL,
    kREGISTER_LEFT_AUX2_INPUT_CONTROL,
    kREGISTER_LEFT_DAC_CONTROL
  );

var
  GICodecConfig: TCodecConfig;

{ private declarations }

procedure SetConfig(const AAddress: Word);
begin
  GICodecConfig.WSSPort := AAddress;
  GICodecConfig.Address := AAddress + kREGISTER_CODEC_INDEX_OFFSET;
  GICodecConfig.Data := AAddress + kREGISTER_CODEC_INDEXED_DATA_OFFSET;
  GICodecConfig.Status := AAddress + kREGISTER_CODEC_STATUS_OFFSET;
  GICodecConfig.PIO := AAddress + kREGISTER_CODEC_DIRECT_DATA_OFFSET;
end;

function CodecIsReady: Boolean;
var
  LRetries: Word;

begin
  LRetries := kRetries;

  while (Port[GICodecConfig.Address] = $80) and (LRetries > 0) do
  begin
    Dec(LRetries);
  end;

  CodecIsReady := LRetries > 0;
end;

function CodecRead(const ARegister: Byte): Byte;
var
  LOldRegister: Byte;

begin
  asm
    cli
  end;

  if CodecIsReady then
  begin
    LOldRegister := Port[GICodecConfig.Address];
    Port[GICodecConfig.Address] := (LOldRegister and $F0) or (ARegister and $1F);

    Delay(1);

    CodecRead := Port[GICodecConfig.Data];

    Port[GICodecConfig.Address] := LOldRegister;

    Delay(1);
  end;

  asm
    sti
  end;
end;

procedure CodecWrite(const ARegister: Byte; AData: Byte);
var
  LOldRegister: Byte;

begin
  asm
    cli
  end;

  if CodecIsReady then
  begin
    LOldRegister := Port[GICodecConfig.Address];
    Port[GICodecConfig.Address] := (LOldRegister and $F0) or (ARegister and $1F);

    Delay(1);

    Port[GICodecConfig.Data] := AData;

    Delay(1);

    AData := Port[GICodecConfig.Data];

    Port[GICodecConfig.Address] := LOldRegister;

    Delay(1);
  end;

  asm
    sti
  end;
end;

procedure SetRegisterBit(const ARegister, ABit: Byte; const AValue: Boolean);
var
  LValue: Byte;

begin
  LValue := CodecRead(ARegister);
  SetBit(LValue, ABit, AValue);
  CodecWrite(ARegister, LValue);
end;

function SetMCE(const AValue: Boolean): Boolean;
var
  LValue: Byte;
  LRetries: Word;

begin
  LValue := Port[GICodecConfig.Address];
  SetBit(LValue, kBitMCE, AValue);

  LRetries := kRetries;

  while (Port[GICodecConfig.Address] <> LValue) and (LRetries > 0) do
  begin
    Port[GICodecConfig.Address] := LValue;
    Dec(LRetries);
  end;

  SetMCE := LRetries > 0;
end;

function WaitForCalibration: Boolean;
var
  LRetries: Word;

begin
  LRetries := kRetries;

  while CodecIsReady and (GetBit(CodecRead(kREGISTER_TEST_INITIALIZATION), kBitACI)) and (LRetries > 0) do
  begin
    Dec(LRetries);
  end;

  WaitForCalibration := CodecIsReady and (not GetBit(CodecRead(kREGISTER_TEST_INITIALIZATION), kBitACI));
end;

function CodecCalibrate: Boolean;
var
  LPinControlMask: Byte;

begin
  asm
    cli
  end;

  LPinControlMask := CodecRead(kREGISTER_PIN_CONTROL) and $40;

  CodecWrite(kREGISTER_PIN_CONTROL, LPinControlMask);

  SetMCE(True);

  CodecWrite(kREGISTER_INTERFACE_CONFIGURATION, $0C);

  if not WaitForCalibration then
  begin
    CodecCalibrate := False;
    Exit;
  end;

  SetMCE(False);

  Port[GICodecConfig.Status] := $00;

  CodecWrite(kREGISTER_LOWER_BASE_COUNT, $FF);
  CodecWrite(kREGISTER_UPPER_BASE_COUNT, $FF);

  CodecWrite(kREGISTER_PIN_CONTROL, $82 or LPinControlMask);

  CodecCalibrate := True;

  asm
    sti
  end;
end;

{ public declarations }

function CodecDetect(const AWSSBASE: Word): Boolean;
begin
  SetConfig(AWSSBASE);

  if Port[GICodecConfig.WSSPort] = $FF then
  begin
    CodecDetect := False;
  end else
  begin
    if CodecIsReady then
    begin
      GCodecRevision := CodecRead(kREGISTER_MISCELLANEOUS_CONTROL) and $0F;
      CodecDetect := GCodecRevision <> $FF;
    end else
    begin
      CodecDetect := False;
    end;
  end;
end;

function CodecDetectNew: Boolean;
begin
  SetRegisterBit(kREGISTER_MISCELLANEOUS_CONTROL, kBitMODE2, True);

  if CodecRead(kREGISTER_ALT_FEAT_ENABLE) = CodecRead(kREGISTER_LEFT_INPUT_CONTROL) then
  begin
    CodecDetectNew := False;
  end else
  begin
    CodecWrite(kREGISTER_MISCELLANEOUS_CONTROL, $00);
    CodecDetectNew := True;
  end;
end;

function CodecDetectWSS: Boolean;
var
  LValue: Byte;

begin
  LValue := Port[GICodecConfig.WSSPort + 3] and $3F;
  CodecDetectWSS := (LValue = $04) or (LValue = $0F) or (LValue = $00);
end;

function CodecInitialize: Boolean;
var
  I: Integer;
  LResult: Boolean;

begin
  asm
    cli
  end;

  if CodecIsReady then
  begin
    SetMCE(True);

    for I := Low(kRegisterResetValue) to High(kRegisterResetValue) do
    begin
      CodecWrite(I, kRegisterResetValue[I]);
    end;

    SetMCE(False);

    LResult := WaitForCalibration;

    if LResult then
    begin
      CodecWrite(kREGISTER_MISCELLANEOUS_CONTROL, $00);
    end;

    CodecInitialize := LResult;
  end else
  begin
    CodecInitialize := False;
  end;

  asm
    sti
  end;
end;

procedure CodecGetOutputFormat(var AFrequency: Word; var AFormat: TCodecOutputFormat; var ASoundOutput: TSoundOutput);
var
  LOutputFormat: Byte;
  LSampleRate: TSampleRate;
  LDivider: Byte;
  LCrystal: Byte;

begin
  LOutputFormat := CodecRead(kREGISTER_CLOCK_DATA_FORMAT);

  case LOutputFormat and $60 of
    $20:
      AFormat := cof8bitUlawCompanded;

    $60:
      AFormat := cof8bitAlawCompanded;

    $00:
      AFormat := cof8bitUnsignedPCM;

    $40:
      AFormat := cof16bitTwosComplementPCM;

  end;

  if GetBit(LOutputFormat, kBitSM) then
  begin
    ASoundOutput := soStereo;
  end else
  begin
    ASoundOutput := soMono;
  end;

  LOutputFormat := LOutputFormat and $0F;
  LCrystal := Succ(Ord(GetBit(LOutputFormat, kBitCSS)));
  LDivider := LOutputFormat shr $01;

  for LSampleRate := Low(TSampleRate) to High(TSampleRate) do
  begin
    if (LDivider = kSampleRates[LSampleRate].Divider) and
       (LCrystal = kSampleRates[LSampleRate].Crystal) then
    begin
      AFrequency := kSampleRates[LSampleRate].Frequency;
      Break;
    end;
  end;
end;

procedure CodecSetOutputFormat(const AFrequency: Word; const AFormat: TCodecOutputFormat; const ASoundOutput: TSoundOutput);
var
  LSampleRate: TSampleRate;
  LOutputFormat: Byte;

begin
  for LSampleRate := Low(TSampleRate) to High(TSampleRate) do
    if AFrequency = kSampleRates[LSampleRate].Frequency then
      Break;

  LOutputFormat := kSampleRates[LSampleRate].Divider shl $01;

  SetBit(LOutputFormat, kBitCSS, kSampleRates[LSampleRate].Crystal = 2);

  LOutputFormat := LOutputFormat and $9F;

  case AFormat of
    cof8bitUlawCompanded:
      LOutputFormat := LOutputFormat or $20;

    cof8bitAlawCompanded:
      LOutputFormat := LOutputFormat or $60;

    cof8bitUnsignedPCM:
      LOutputFormat := LOutputFormat or $00;

    cof16bitTwosComplementPCM:
      LOutputFormat := LOutputFormat or $40;

  end;

  SetBit(LOutputFormat, kBitSM, ASoundOutput = soStereo);

  SetMCE(True);

  CodecWrite(kREGISTER_CLOCK_DATA_FORMAT, LOutputFormat);

  SetMCE(False);

  CodecCalibrate;
end;

function CodecGetInputDevice(const AChannel: TSoundChannel): TCodecInputDeviceType;
var
  LInputDevice: Byte;

begin
  case AChannel of
    scLeft:
      LInputDevice := CodecRead(kREGISTER_LEFT_INPUT_CONTROL);

    scRight:
      LInputDevice := CodecRead(kREGISTER_RIGHT_INPUT_CONTROL);

    scLeftRight:
      LInputDevice :=
        CodecRead(kREGISTER_LEFT_INPUT_CONTROL) or
        CodecRead(kREGISTER_RIGHT_INPUT_CONTROL);

  end;

  case LInputDevice and $C0 of
    $00:
      CodecGetInputDevice := cidtLineIn;

    $40:
      CodecGetInputDevice := cidtAUX1In;

    $80:
      CodecGetInputDevice := cidtMicrophone;

    $C0:
      CodecGetInputDevice := cidtPostMixedDAC;

  end;
end;

function CodecGetMicGain(const AChannel: TSoundChannel): Boolean;
begin
  case AChannel of
    scLeft:
      CodecGetMicGain := GetBit(CodecRead(kREGISTER_LEFT_INPUT_CONTROL), kBitLMGE);

    scRight:
      CodecGetMicGain := GetBit(CodecRead(kREGISTER_RIGHT_INPUT_CONTROL), kBitRMGE);

    scLeftRight:
      CodecGetMicGain :=
        GetBit(CodecRead(kREGISTER_LEFT_INPUT_CONTROL), kBitLMGE) or
        GetBit(CodecRead(kREGISTER_RIGHT_INPUT_CONTROL), kBitRMGE);

  end;
end;

function CodecGetInputGain(const AChannel: TSoundChannel): Byte;
var
  LGain: Byte;
  LGainLeft: Byte;
  LGainRight: Byte;

begin
  LGainLeft := CodecRead(kREGISTER_LEFT_INPUT_CONTROL) and $0F;
  LGainRight := CodecRead(kREGISTER_RIGHT_INPUT_CONTROL) and $0F;

  case AChannel of
    scLeft:
      LGain := LGainLeft;

    scRight:
      LGain := LGainRight;

    scLeftRight:
      LGain := (LGainLeft + LGainRight) div 2;

  end;

  CodecGetInputGain := 15 - LGain;
end;

procedure CodecSetInputConfig(const AInputDeviceType: TCodecInputDeviceType; const AMicrophoneGain: Boolean;
  const AInputGain: Byte; const AChannel: TSoundChannel);
var
  LInputConfig: Byte;

begin
  LInputConfig := AInputGain;

  if LInputConfig > 15 then
  begin
    LInputConfig := 15;
  end;

  LInputConfig := (15 - LInputConfig) and $0F;

  case AInputDeviceType of
    cidtLineIn:
      LInputConfig := LInputConfig or $00;

    cidtAUX1In:
      LInputConfig := LInputConfig or $40;

    cidtMicrophone:
      LInputConfig := LInputConfig or $80;

    cidtPostMixedDAC:
      LInputConfig := LInputConfig or $C0;

  end;

  SetBit(LInputConfig, kBitLMGE, AMicrophoneGain);

  case AChannel of
    scLeft:
      CodecWrite(kREGISTER_LEFT_INPUT_CONTROL, LInputConfig);

    scRight:
      CodecWrite(kREGISTER_RIGHT_INPUT_CONTROL, LInputConfig);

    scLeftRight:
      begin
        CodecWrite(kREGISTER_LEFT_INPUT_CONTROL, LInputConfig);
        CodecWrite(kREGISTER_RIGHT_INPUT_CONTROL, LInputConfig);
      end;

  end;
end;

procedure CodecSetDigitalMix(const AEnabled: Boolean; AVolume: Byte);
var
  LValue: Byte;

begin
  if AVolume > 63 then
  begin
    AVolume := 63;
  end;

  AVolume := 63 - AVolume;

  LValue := AVolume shl $02;
  SetBit(LValue, kBitDME, AEnabled);
  CodecWrite(kREGISTER_DIGITAL_MIX, LValue);
end;

function CodecGetVolume(const ADeviceType: TCodecDeviceType; const AChannel: TSoundChannel): Byte;
var
  LRegister: Byte;
  LVolume: Byte;
  LVolumeLeft: Byte;
  LVolumeRight: Byte;

begin
  LRegister := kDeviceTypes[ADeviceType];

  LVolumeLeft := CodecRead(LRegister) and $1F;
  LVolumeRight := CodecRead(Succ(LRegister)) and $1F;

  case AChannel of
    scLeft:
      LVolume := LVolumeLeft;

    scRight:
      LVolume := LVolumeRight;

    scLeftRight:
      LVolume := (LVolumeLeft + LVolumeRight) div 2;

  end;

  CodecGetVolume := 30 - LVolume;
end;

procedure CodecSetVolume(const ADeviceType: TCodecDeviceType; const AChannel: TSoundChannel; AVolume: Byte);
var
  LRegister: Byte;

begin
  if AVolume > 30 then
  begin
    AVolume := 30;
  end;

  AVolume := 30 - AVolume;

  if AVolume = 30 then
  begin
    SetBit(AVolume, 7, True);
  end;

  LRegister := kDeviceTypes[ADeviceType];

  case AChannel of
    scLeft:
      CodecWrite(LRegister, AVolume);

    scRight:
      CodecWrite(Succ(LRegister), AVolume);

    scLeftRight:
      begin
        CodecWrite(LRegister, AVolume);
        CodecWrite(Succ(LRegister), AVolume);
      end;

  end;
end;

procedure CodecMuteAUX1(const AChannel: TSoundChannel; const AMute: Boolean);
begin
  case AChannel of
    scLeft:
      SetRegisterBit(kREGISTER_LEFT_AUX1_INPUT_CONTROL, kBitLMX1, AMute);

    scRight:
      SetRegisterBit(kREGISTER_RIGHT_AUX1_INPUT_CONTROL, kBitRMX1, AMute);

    scLeftRight:
      begin
        SetRegisterBit(kREGISTER_LEFT_AUX1_INPUT_CONTROL, kBitLMX1, AMute);
        SetRegisterBit(kREGISTER_RIGHT_AUX1_INPUT_CONTROL, kBitRMX1, AMute);
      end;

  end;
end;

procedure CodecMuteAUX2(const AChannel: TSoundChannel; const AMute: Boolean);
begin
  case AChannel of
    scLeft:
      SetRegisterBit(kREGISTER_LEFT_AUX2_INPUT_CONTROL, kBitLMX2, AMute);

    scRight:
      SetRegisterBit(kREGISTER_RIGHT_AUX2_INPUT_CONTROL, kBitRMX2, AMute);

    scLeftRight:
      begin
        SetRegisterBit(kREGISTER_LEFT_AUX2_INPUT_CONTROL, kBitLMX2, AMute);
        SetRegisterBit(kREGISTER_RIGHT_AUX2_INPUT_CONTROL, kBitRMX2, AMute);
      end;

  end;
end;

procedure CodecMuteDAC(const AChannel: TSoundChannel; const AMute: Boolean);
begin
  case AChannel of
    scLeft:
      SetRegisterBit(kREGISTER_LEFT_DAC_CONTROL, kBitLDM, AMute);

    scRight:
      SetRegisterBit(kREGISTER_RIGHT_DAC_CONTROL, kBitRDM, AMute);

    scLeftRight:
      begin
        SetRegisterBit(kREGISTER_LEFT_DAC_CONTROL, kBitLDM, AMute);
        SetRegisterBit(kREGISTER_RIGHT_DAC_CONTROL, kBitRDM, AMute);
      end;

  end;
end;

procedure CodecSetLEDEnabled(const AValue: Boolean);
begin
  SetRegisterBit(kREGISTER_PIN_CONTROL, kBitXCTL1, AValue);
end;

function CodecGetOutputsEnabled: Boolean;
begin
  CodecGetOutputsEnabled := not GetBit(CodecRead(kREGISTER_PIN_CONTROL), kBitXCTL0);
end;

procedure CodecSetOutputsEnabled(const AValue: Boolean);
begin
  SetRegisterBit(kREGISTER_PIN_CONTROL, kBitXCTL0, not AValue);
end;

end.
