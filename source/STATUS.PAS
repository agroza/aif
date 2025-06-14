{ --------------------------------------------------------------------------- }
{ - Audio Interface - Status Subprogram (status.pas)                        - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$I cdefines.inc}

{$IFDEF CPU16BIT}
  {$G+}
{$ENDIF}

unit Status;

interface

procedure StatusWrite;

implementation

uses
  Codec,
  Consts,
  Control,
  Error,
  Init,
  Routines,
  SBPro,
  Setup,
  Types,
  Video;

type
  TStatusItems = packed record
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

procedure UIWriteItem(const AItem, AValue: String); forward;

{ private declarations }

procedure UIWriteItem(const AItem, AValue: String);
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
  LFormat: PChar;
  LStereo: Boolean;
  LFilter: Boolean;

begin
  VideoSetForeground(clNormal);
  VideoSetBackground(clBlack);

  VideoWriteNewln;
  VideoWriteln(sStatusAIFModel);
  VideoWriteNewln;

  FillChar(LStatusItems, SizeOf(TStatusItems), $00);

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
          cSpace + StrPas(LFormat) + cSpace + sSoundOutput[LSoundOutput];
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

  UIWriteItem(sStatusAIFMode, sAIFMode[LStatusItems.BitMOD]);
  UIWriteItem(sStatusBASE, IntToHex(LStatusItems.Address));
  UIWriteItem(sStatusIRQ, IfThenElse(LStatusItems.IRQ < $FF, IntToStr(LStatusItems.IRQ), sDisabledEnabled[False]));
  UIWriteItem(sStatusDRQ, IfThenElse(LStatusItems.DRQ < $FF, IntToStr(LStatusItems.DRQ), sDisabledEnabled[False]));
  UIWriteItem(sStatusDSP, IfThenElse(LStatusItems.DSP, sSBDSPVersions[GControllerConfig.SBDSPVersion], sNA));
  UIWriteItem(sStatusFM, IfThenElse(LStatusItems.FM, sOPL3, sNA));
  UIWriteItem(sStatusMPU401, IfThenElse(LStatusItems.MPU401, IntToHex(GControllerConfig.MPUBASE), sDisabledEnabled[False]));
  UIWriteItem(sStatusGamePort, IfThenElse(LStatusItems.GamePort, sDisabledEnabled[True], sDisabledEnabled[False]));
  UIWriteItem(sStatusOutputFormat, LStatusItems.OutputFormat);
  UIWriteItem(sStatusLineOutRelay, sDisabledEnabled[LStatusItems.LineOutRelay]);

  if not InitAIFController(LControllerMode) then
  begin
    ErrorSetProgramError(peControllerReinit);
    ErrorWriteHalt;
  end;
end;

end.
