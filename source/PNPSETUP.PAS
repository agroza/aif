{ --------------------------------------------------------------------------- }
{ - Audio Interface - PnP Setup Subprogram (pnpsetup.pas)                   - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit PnPSetup;

interface

procedure PnPSetupStart;

implementation

uses
  Crt,
  Consts,
  Control,
  Routines,
  Screen,
  Types,
  Video;

var
  IGFileName: String;
  IGProgressBar: TProgressBarData;

const
  kUICommands: array[0..5] of TUICommand = (
    ( Y: 4; Accelerator: sPnPSetupCmdF4; Name: sPnPSetupCmdEditFilename ),
    ( Y: 6; Accelerator: sPnPSetupCmdF5; Name: sPnPSetupCmdEraseEEPROMF ),
    ( Y: 7; Accelerator: sPnPSetupCmdF6; Name: sPnPSetupCmdEraseEEPROMS ),
    ( Y: 8; Accelerator: sPnPSetupCmdF7; Name: sPnPSetupCmdReadEEPROM ),
    ( Y: 9; Accelerator: sPnPSetupCmdF8; Name: sPnPSetupCmdWriteEEPROM ),
    ( Y: 11; Accelerator: sPnPSetupCmdESC; Name: sPnPSetupCmdExit )
  );

{ private declarations }

procedure UpdateProgressBar(const ABytes: Word); far;
begin
  IGProgressBar.Progress := ABytes;
  ScreenUpdateProgressBar(IGProgressBar);
end;

procedure ResetProgressBar;
begin
  Routines.Delay(kPnPSetupOperationDelay);
  IGProgressBar.Progress := 0;
  ScreenResetProgressBar(IGProgressBar);
end;

procedure ResetStatus(const AOperation: TEEPROMOperation);
begin
  VideoWriteRegion(
    kPnPSetupValueX,
    4,
    20,
    2,
    cSpace,
    VideoAttribute(
      clPnPSetupFore,
      clPnPSetupBack
    )
  );

  VideoWriteStringAt(
    kPnPSetupValueX,
    4,
    sEEPROMOperation[AOperation],
    clPnPSetupFore,
    clPnPSetupBack
  );
end;

procedure DrawResult(const AValue: Boolean);
begin
  VideoWriteRegion(
    kPnPSetupValueX,
    5,
    Length(sFAILEDOK[False]),
    1,
    cSpace,
    VideoAttribute(
      clPnPSetupFore,
      clPnPSetupBack
    )
  );

  VideoWriteStringAt(
    kPnPSetupValueX,
    5,
    sFAILEDOK[AValue],
    clFAILEDOK[AValue],
    clPnPSetupBack
  );

  ResetProgressBar;
end;

procedure DrawOption(const APositionY: Byte; const AName, AValue: String);
var
  LKeyValueData: TKeyValueData;

begin
  LKeyValueData.NameX := kPnPSetupNameX;
  LKeyValueData.ValueX := kPnPSetupValueX;
  LKeyValueData.PositionY := APositionY;
  LKeyValueData.Colors.Foreground := clPnPSetupFore;
  LKeyValueData.Colors.Background := clPnPSetupBack;
  LKeyValueData.Name := AName;
  LKeyValueData.Value := AValue;

  ScreenDrawKeyValue(LKeyValueData);
end;

procedure DrawOptions;
begin
  VideoWriteRegion(
    kPnPSetupOptionsLeft,
    kPnPSetupOptionsTop,
    kPnPSetupOptionsWidth,
    kPnPSetupOptionsHeight,
    cSpace,
    VideoAttribute(
      clPnPSetupFore,
      clPnPSetupBack
    )
  );

  DrawOption(3, sPnPSetupFilename, IGFileName);
  DrawOption(4, sPnPSetupOperation, cMinus);
  DrawOption(5, sPnPSetupStatus, cMinus);
  DrawOption(6, sPnPSetupEEPROM, sPnPSetup93C56A);
end;

procedure InitProgressBar;
begin
  IGProgressBar.PositionX := kPnPSetupProgressBarX;
  IGProgressBar.PositionY := kPnPSetupProgressBarY;
  IGProgressBar.Width := kPnPSetupProgressBarWidth;
  IGProgressBar.Colors.Foreground := clPnPSetupProgressFore;
  IGProgressBar.Colors.Background := clPnPSetupProgressBack;
  IGProgressBar.Colors.Title := clPnPSetupProgressTitle;
  IGProgressBar.Colors.Progress := clPnPSetupProgressColor;
  IGProgressBar.Min := kPnPSetupProgressBarMin;
  IGProgressBar.Max := 256;
  IGProgressBar.Title := sPnPSetupProgress;
end;

procedure DrawProgressBar;
begin
  ScreenDrawProgressBar(IGProgressBar);
end;

procedure DrawCommands;
var
  I: Byte;

begin
  VideoWriteRegion(
    kPnPSetupCommandsLeft,
    kPnPSetupCommandsTop,
    kPnPSetupCommandsWidth,
    kPnPSetupCommandsHeight,
    cSpace,
    VideoAttribute(
      clPnPSetupCmdFore,
      clPnPSetupCmdBack
    )
  );

  VideoWriteStringAt(
    kPnPSetupCmdX,
    3,
    sPnPSetupCmdProgramCmds,
    clPnPSetupCmdHeader,
    clPnPSetupCmdBack
  );

  for I := Low(kUICommands) to High(kUICommands) do
  begin
    ScreenDrawCommand(
      kPnPSetupCmdX,
      kUICommands[I].Y,
      clPnPSetupCmdHigh,
      clPnPSetupCmdFore,
      clPnPSetupCmdBack,
      StrPas(kUICommands[I].Accelerator),
      StrPas(kUICommands[I].Name)
    );
  end;
end;

procedure DrawConfig;
begin
  DrawOptions;

  InitProgressBar;
  DrawProgressBar;
end;

procedure UIDraw;
begin
  ScreenDrawTitleBar(clInterfaceFore, clInterfaceBack, clInterfaceFore, sPnPSetupTitle);

  DrawConfig;
  DrawCommands;
end;

procedure UILoop;
begin
  while True do
  begin
    case UpCase(ReadKey) of
      kKeyExtended:
        begin
          case ReadKey of
            kKeyF4:
              begin
                { TODO -oagroza -cImplement : Filename editor. }
              end;

            kKeyF5:
              begin
                ResetStatus(eoEraseFast);
                DrawResult(ControllerEraseEEPROM(cemFast, UpdateProgressBar));
              end;

            kKeyF6:
              begin
                ResetStatus(eoEraseSlow);
                DrawResult(ControllerEraseEEPROM(cemSlow, UpdateProgressBar));
              end;

            kKeyF7:
              begin
                ResetStatus(eoRead);
                DrawResult(ControllerReadEEPROM(IGFileName, UpdateProgressBar));
              end;

            kKeyF8:
              begin
                ResetStatus(eoWrite);
                DrawResult(ControllerWriteEEPROM(IGFileName, UpdateProgressBar));
              end;

          end;
        end;

      kKeyEscape:
        Break;

    end;
  end;
end;

{ public declarations }

procedure PnPSetupStart;
var
  LSaveY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kPnPSetupStartupDelay);

  LSaveY := WhereY;

  GetMem(LVideoRAMData, kVGARAMSize);
  VideoSaveScreen(LVideoRAMData);
  VideoClearScreen;
  VideoEnableHighColors;
  VideoDisableCursor;

  ScreenSetVVColors;

  IGFileName := sPnPSetupDefaultFilename;

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
