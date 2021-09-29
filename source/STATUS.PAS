{ --------------------------------------------------------------------------- }
{ - Audio Interface - Status Subprogram (status.pas)                        - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Status;

interface

procedure StatusWrite;

implementation

uses
  Codec,
  Consts,
  Control,
  Init,
  Routines,
  SBPro,
  Setup,
  Types,
  Video;

type
  TStatusItems = record
    BitMOD: TBitStatus;
    Address: Word;
    IRQ: Byte;
    DRQ: Byte;
    DSP: Boolean;
    FM: Boolean;
    MPU401: Boolean;
    GamePort: Boolean;
    OutputFormat: String;
    LineOutRelay: Boolean;
  end;

{ private declarations }

procedure WriteItem(const AItem, AValue: String);
var
  LPositionY: Byte;

begin
  LPositionY := VideoWhereY;

  VideoWriteStringAt(kStatusItemX, LPositionY, AItem, clNormal, clBlack);
  VideoWriteCharAt(kStatusSemicolonX, LPositionY, cSemicolon);
  VideoWriteStringAt(kStatusValueX, LPositionY, AValue, clHighlight, clBlack);
  VideoWriteNewln;
end;

{ public declarations }

procedure StatusWrite;
var
  LStatusItems: TStatusItems;
  LControllerMode: TControllerMode;
  LFrequency: Word;
  LOutputFormat: TCodecOutputFormat;
  LSoundOutput: TCodecSoundOutput;
  LFormat: String;
  LStereo: Boolean;
  LFilter: Boolean;

begin
  VideoSetForeground(clNormal);
  VideoSetBackground(clBlack);

  VideoWriteNewln;
  VideoWriteln(sStatusAIFModel);
  VideoWriteNewln;

  FillChar(LStatusItems, SizeOf(LStatusItems), $00);

  LControllerMode := ControllerGetMode;

  case LControllerMode of
    cmWSS:
      begin
        CodecGetOutputFormat(LFrequency, LOutputFormat, LSoundOutput);

        case LOutputFormat of
          cof8bitUlawCompanded:
            LFormat := s8bitUlaw;

          cof8bitAlawCompanded:
            LFormat := s8bitAlaw;

          cof8bitUnsignedPCM:
            LFormat := s8bitPCM;

          cof16bitTwosComplementPCM:
            LFormat := s16bitPCM;

        end;

        LStatusItems.BitMOD := bsSet;
        LStatusItems.Address := GControllerConfig.WSSBASE;
        LStatusItems.IRQ := GControllerConfig.WSSIRQ;
        LStatusItems.DRQ := GControllerConfig.WSSDRQ;
        LStatusItems.DSP := False;
        LStatusItems.OutputFormat :=
          AddSizeSeparator(IntToStr(LFrequency) + cSpace + sHz, True) +
          cSpace + LFormat + cSpace + sSoundOutput[LSoundOutput];
      end;

    cmSB:
      begin
        SBDSPReset(GControllerConfig.SBBASE);
        SBMixerGetOutput(LStereo, LFilter);

        LStatusItems.BitMOD := bsNotSet;
        LStatusItems.Address := GControllerConfig.SBBASE;
        LStatusItems.IRQ := GControllerConfig.SBIRQ;
        LStatusItems.DRQ := GControllerConfig.SBDRQ;
        LStatusItems.DSP := True;
        LStatusItems.OutputFormat :=
          AddSizeSeparator(IntToStr(kSampleRates[GSBAudioConfig.SampleRate].Frequency) + cSpace + sHz, True) +
          cSpace + sBitDepth[GSBAudioConfig.BitDepth] + cSpace + sSoundOutput[TCodecSoundOutput(LStereo)];
      end;

  end;

  LStatusItems.FM := GControllerConfig.BitOPL4 = bsNotSet;
  LStatusItems.MPU401 := GControllerConfig.BitMPU401 = bsSet;
  LStatusItems.GamePort := GControllerConfig.BitGPEN = bsSet;

  ControllerAllowCodecAccess(GControllerConfig);
  LStatusItems.LineOutRelay := CodecGetOutputsEnabled;
  ControllerDisallowCodecAccess;

  WriteItem(sStatusAIFMode, sAIFMode[LStatusItems.BitMOD]);
  WriteItem(sStatusBASE, IntToHex(LStatusItems.Address));
  WriteItem(sStatusIRQ, IfThenElse(LStatusItems.IRQ < $FF, IntToStr(LStatusItems.IRQ), sDisabledEnabled[False]));
  WriteItem(sStatusDRQ, IfThenElse(LStatusItems.DRQ < $FF, IntToStr(LStatusItems.DRQ), sDisabledEnabled[False]));
  WriteItem(sStatusDSP, IfThenElse(LStatusItems.DSP, sSBDSPVersions[GControllerConfig.SBDSPVersion], sNA));
  WriteItem(sStatusFM, IfThenElse(LStatusItems.FM, sOPL3, sNA));
  WriteItem(sStatusMPU401, IfThenElse(LStatusItems.MPU401, IntToHex(GControllerConfig.MPUBASE), sDisabledEnabled[False]));
  WriteItem(sStatusGamePort, IfThenElse(LStatusItems.GamePort, sDisabledEnabled[True], sDisabledEnabled[False]));
  WriteItem(sStatusOutputFormat, LStatusItems.OutputFormat);
  WriteItem(sStatusLineOutRelay, sDisabledEnabled[LStatusItems.LineOutRelay]);

  if not InitAIFController(LControllerMode) then
  begin
    VideoWriteNewln;
    VideoWriteln(sControllerReinitError);

    Halt(kControllerReinitError);
  end;
end;

end.
