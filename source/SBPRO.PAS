{ --------------------------------------------------------------------------- }
{ - Audio Interface - Sound Blaster Pro Interface (sbpro.pas)               - }
{ - Copyright (C) 2000 Jan Knipperts                                        - }
{ - Improvements (C) 2020-2021 Alexandru Groza                              - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit SBPro;

interface

uses
  Routines,
  Types;

type
  TSBMixerDeviceType = (
    mdtMaster,
    mdtMicrophone,
    mdtCD,
    mdtLineIn,
    mdtVoice,
    mdtFM
  );

function SBDSPReset(const APort: Word): Boolean;
function SBDSPGetVersion: Byte;
procedure SBDSPEnableSpeaker(const AValue: Boolean);

procedure SBMixerReset;

function SBMixerGetVolume(const ADeviceType: TSBMixerDeviceType; const AChannel: TCodecSoundChannel): Byte;
procedure SBMixerSetVolume(const ADeviceType: TSBMixerDeviceType; const AChannel: TCodecSoundChannel; AVolume: Byte);

procedure SBMixerSetOutput(const AStereo, AFilter: Boolean);
procedure SBMixerGetOutput(var AStereo, AFilter: Boolean);

implementation

const
  kPORT_DSP_RESET_OFFSET              = $06;
  kPORT_DSP_READ_DATA_OFFSET          = $0A;
  kPORT_DSP_READ_BUFFER_STATUS_OFFSET = $0E;
  kPORT_DSP_WRITE_COMMAND_DATA_OFFSET = $0C;

  kPORT_MIXER_ADDRESS_OFFSET          = $04;
  kPORT_MIXER_DATA_OFFSET             = $05;

  kDSP_COMMAND_ENABLE_SPEAKER         = $D1;
  kDSP_COMMAND_DISABLE_SPEAKER        = $D3;
  kDSP_COMMAND_DSP_VERSION            = $E1;

  kMIXER_REGISTER_RESET               = $00;
  kMIXER_REGISTER_DAC_VOLUME          = $04;
  kMIXER_REGISTER_MICROPHONE_VOLUME   = $0A;
  kMIXER_REGISTER_OUTPUT_FILTER       = $0E;
  kMIXER_REGISTER_MASTER_VOLUME       = $22;
  kMIXER_REGISTER_FM_VOLUME           = $26;
  kMIXER_REGISTER_CD_VOLUME           = $28;
  kMIXER_REGISTER_LINE_IN_VOLUME      = $2E;

  kMIXER_COMMAND_RESET                = $FF;

  kDeviceTypes: array[TSBMixerDeviceType] of Byte = (
    kMIXER_REGISTER_MASTER_VOLUME,
    kMIXER_REGISTER_MICROPHONE_VOLUME,
    kMIXER_REGISTER_CD_VOLUME,
    kMIXER_REGISTER_LINE_IN_VOLUME,
    kMIXER_REGISTER_DAC_VOLUME,
    kMIXER_REGISTER_FM_VOLUME
  );

var
  IGSBPort: Word;

{ private declarations }

function DSPRead: Byte;
var
  LRetries: Word;

begin
  LRetries := $FFFF;

  while (Port[IGSBPort + kPORT_DSP_READ_BUFFER_STATUS_OFFSET] and $80 = $00) and (LRetries > 0) do
  begin
    Dec(LRetries);
  end;

  if LRetries > 0 then
  begin
    DSPRead := Port[IGSBPort + kPORT_DSP_READ_DATA_OFFSET];
  end else
  begin
    DSPRead := $FF;
  end;
end;

procedure DSPWrite(const AValue: Byte);
var
  LRetries: Word;

begin
  LRetries := $FF;

  while (Port[IGSBPort + kPORT_DSP_WRITE_COMMAND_DATA_OFFSET] and $80 <> $00) and (LRetries > 0) do
  begin
    Dec(LRetries);
  end;

  if LRetries > 0 then
  begin
    Port[IGSBPort + kPORT_DSP_WRITE_COMMAND_DATA_OFFSET] := AValue;
  end;
end;

function MixerRead(const AIndex: Byte): Byte;
begin
  Port[IGSBPort + kPORT_MIXER_ADDRESS_OFFSET] := AIndex;

  Delay(1);

  MixerRead := Port[IGSBPort + kPORT_MIXER_DATA_OFFSET];

  Delay(1);
end;

procedure MixerWrite(const AIndex, AValue: Byte);
begin
  Port[IGSBPort + kPORT_MIXER_ADDRESS_OFFSET] := AIndex;

  Delay(1);

  Port[IGSBPort + kPORT_MIXER_DATA_OFFSET] := AValue;

  Delay(1);
end;

{ public declarations }

function SBDSPReset(const APort: Word): Boolean;
begin
  Port[APort + kPORT_DSP_RESET_OFFSET] := 1;

  Delay(10);

  Port[APort + kPORT_DSP_RESET_OFFSET] := 0;

  Delay(10);

  if (Port[APort + kPORT_DSP_READ_BUFFER_STATUS_OFFSET] and $80 = $80) and
    (Port[APort + kPORT_DSP_READ_DATA_OFFSET] = $AA) then
  begin
    IGSBPort := APort;
    SBDSPReset := True;
  end else
  begin
    SBDSPReset := False;
  end;
end;

function SBDSPGetVersion: Byte;
begin
  DSPWrite(kDSP_COMMAND_DSP_VERSION);

  SBDSPGetVersion := DSPRead or DSPRead shl $04;
end;

procedure SBDSPEnableSpeaker(const AValue: Boolean);
begin
  if AValue then
  begin
    DSPWrite(kDSP_COMMAND_ENABLE_SPEAKER);
  end else
  begin
    DSPWrite(kDSP_COMMAND_DISABLE_SPEAKER);
  end;
end;

procedure SBMixerReset;
begin
  MixerWrite(kMIXER_REGISTER_RESET, kMIXER_COMMAND_RESET);
end;

function SBMixerGetVolume(const ADeviceType: TSBMixerDeviceType; const AChannel: TCodecSoundChannel): Byte;
var
  Volume: Byte;

begin
  Volume := MixerRead(kDeviceTypes[ADeviceType]);

  if (AChannel = scLeft) and (ADeviceType <> mdtMicrophone) then
  begin
    SBMixerGetVolume := Volume shr $05;
  end;

  if (AChannel = scRight) or (ADeviceType = mdtMicrophone) then
  begin
    SBMixerGetVolume := (Volume and $0F) shr $01;
  end;
end;

procedure SBMixerSetVolume(const ADeviceType: TSBMixerDeviceType; const AChannel: TCodecSoundChannel; AVolume: Byte);
var
  Volume: Byte;

begin
  if ADeviceType = mdtMicrophone then
  begin
    if AVolume > 3 then
    begin
      AVolume := 3;
    end;

    Volume := AVolume shl $01;
  end else
  begin
    if AVolume > 7 then
    begin
      AVolume := 7;
    end;

    if AChannel = scLeft then
    begin
      Volume := (SBMixerGetVolume(ADeviceType, scRight) shl $01) or (AVolume shl $05);
    end;

    if AChannel = scRight then
    begin
      Volume := (AVolume shl $01) or (SBMixerGetVolume(ADeviceType, scLeft) shl $05);
    end;

    if AChannel = scLeftRight then
    begin
      Volume := (AVolume shl $01) or (AVolume shl $05);
    end;
  end;

  MixerWrite(kDeviceTypes[ADeviceType], Volume);
end;

procedure SBMixerSetOutput(const AStereo, AFilter: Boolean);
var
  LValue: Byte;

begin
  if AStereo then
  begin
    LValue := $02;
  end else
  begin
    LValue := $00;
  end;

  if not AFilter then
  begin
    LValue := LValue or $20;
  end;

  MixerWrite(kMIXER_REGISTER_OUTPUT_FILTER, LValue);
end;

procedure SBMixerGetOutput(var AStereo, AFilter: Boolean);
var
  LValue: Byte;

begin
  LValue := MixerRead(kMIXER_REGISTER_OUTPUT_FILTER);

  AStereo := LValue and $02 = $02;
  AFilter := LValue and $20 = $20;
end;

end.
