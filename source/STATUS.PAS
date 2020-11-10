{ --------------------------------------------------------------------------- }
{ - Audio Interface - Status Subprogram (status.pas)                        - }
{ - Copyright (C) 1998-2020 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Status;

interface

uses
  Codec,
  Control;

procedure StatusWrite;

implementation

uses
  Consts,
  Crt,
  Routines,
  SBPro,
  Setup,
  Types;

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
  end;

{ private declarations }

procedure WriteItem(const AItem, AValue: String);
begin
  Write(AItem);
  GotoXY(kStatusValueX, WhereY);
  Write(cSemicolon + cSpace);
  TextColor(clHighlight);
  Write(AValue);
  TextColor(clNormal);
  Writeln;
end;

{ public declarations }

procedure StatusWrite;
var
  LStatusItems: TStatusItems;
  LFrequency: Word;
  LOutputFormat: TCodecOutputFormat;
  LSoundOutput: TSoundOutput;
  LFormat: String;
  LStereo: Boolean;
  LFilter: Boolean;

begin
  Writeln;
  Writeln(sStatusAIFModel);
  Writeln;

  FillChar(LStatusItems, SizeOf(LStatusItems), $00);

  case ControllerGetMode of
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
          cSpace + sBitDepth[GSBAudioConfig.BitDepth] + cSpace + sSoundOutput[TSoundOutput(LStereo)];
      end;

  end;

  LStatusItems.FM := GControllerConfig.BitOPL4 = bsNotSet;
  LStatusItems.MPU401 := GControllerConfig.BitMPU401 = bsSet;
  LStatusItems.GamePort := GControllerConfig.BitGPEN = bsSet;

  WriteItem(sStatusAIFMode, sAIFMode[LStatusItems.BitMOD]);
  WriteItem(sStatusBASE, IntToHex(LStatusItems.Address));
  WriteItem(sStatusIRQ, IfThenElse(LStatusItems.IRQ < $FF, IntToStr(LStatusItems.IRQ), sEnabledDisabled[False]));
  WriteItem(sStatusDRQ, IfThenElse(LStatusItems.DRQ < $FF, IntToStr(LStatusItems.DRQ), sEnabledDisabled[False]));
  WriteItem(sStatusDSP, IfThenElse(LStatusItems.DSP, sSBDSPVersions[GControllerConfig.SBDSPVersion], sNA));
  WriteItem(sStatusFM, IfThenElse(LStatusItems.FM, sOPL3, sNA));
  WriteItem(sStatusMPU401, IfThenElse(LStatusItems.MPU401, IntToHex(GControllerConfig.MPUBASE), sEnabledDisabled[False]));
  WriteItem(sStatusGamePort, IfThenElse(LStatusItems.GamePort, sEnabledDisabled[True], sEnabledDisabled[False]));
  WriteItem(sStatusOutputFormat, LStatusItems.OutputFormat);
end;

end.
