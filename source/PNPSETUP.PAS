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
  Consts,
  Control,
  Routines,
  Screen,
  Types,
  Video;

type
  TOperation = (
    opEraseFast,
    opEraseSlow,
    opRead,
    opWrite
  );

const
  kUICommands: packed array[0..kPnPSetupCmdCount] of TUICommand = (
    ( Y: 4; Accelerator: sPnPSetupCmdF4; Name: sPnPSetupCmdEditFilename ),
    ( Y: 6; Accelerator: sPnPSetupCmdF5; Name: sPnPSetupCmdEraseEEPROMF ),
    ( Y: 7; Accelerator: sPnPSetupCmdF6; Name: sPnPSetupCmdEraseEEPROMS ),
    ( Y: 8; Accelerator: sPnPSetupCmdF7; Name: sPnPSetupCmdReadEEPROM ),
    ( Y: 9; Accelerator: sPnPSetupCmdF8; Name: sPnPSetupCmdWriteEEPROM ),
    ( Y: 11; Accelerator: sPnPSetupCmdESC; Name: sPnPSetupCmdExit )
  );

  kUIKeyValues: packed array[0..kPnPSetupKeyValueCount] of TUIKeyValue = (
    ( Y: 3; Key: sPnPSetupFilename; Value: cMinus ),
    ( Y: 4; Key: sPnPSetupOperation; Value: cMinus ),
    ( Y: 5; Key: sPnPSetupStatus; Value: cMinus ),
    ( Y: 6; Key: sPnPSetupEEPROM; Value: sPnPSetup93C56A )
  );

  sOperations: packed array[TOperation] of String[Length(sPnPSetupEraseFast)] = (
    sPnPSetupEraseFast,
    sPnPSetupEraseSlow,
    sPnPSetupRead,
    sPnPSetupWrite
  );

var
  IGEdit: TEditData;
  IGProgressBar: TProgressBarData;
  IGRawData: TFramedAreaData;
  IGMessageBox: TMessageBoxData;

{ private declarations }

procedure UpdateProgressBar(const ABytes: Word; const AByte: Byte); far;
begin
  ScreenProgressBarSetProgress(IGProgressBar, ABytes);

  VideoWriteCharAttrAt(
    kPnPSetupRawDataX + 2 + (ABytes mod kPnPSetupRawDataLength),
    kPnPSetupRawDataY + 2 + (ABytes div kPnPSetupRawDataLength) mod kPnPSetupRawDataLength,
    Chr(AByte),
    VideoAttribute(
      clPnPSetupFore,
      clPnPSetupBack
    )
  );
end;

procedure ResetProgressBar;
begin
  Routines.Delay(kPnPSetupOperationDelay);

  ScreenProgressBarReset(IGProgressBar, kPnPSetupProgressBarMin);
end;

procedure ResetOperationStatus(const AOperation: TOperation);
begin
  VideoWriteRegion(
    kPnPSetupOperationX,
    kPnPSetupOperationY,
    kPnPSetupOpStatusWidth,
    kPnPSetupOpStatusHeight,
    cSpace,
    VideoAttribute(
      clPnPSetupFore,
      clPnPSetupBack
    )
  );

  VideoWriteStringAt(
    kPnPSetupOperationX,
    kPnPSetupOperationY,
    sOperations[AOperation],
    clPnPSetupFore,
    clPnPSetupBack
  );
end;

procedure DrawResult(const AValue: Boolean);
begin
  VideoWriteRegion(
    kPnPSetupStatusX,
    kPnPSetupStatusY,
    Length(sFAILEDOK[False]),
    1,
    cSpace,
    VideoAttribute(
      clPnPSetupFore,
      clPnPSetupBack
    )
  );

  VideoWriteStringAt(
    kPnPSetupStatusX,
    kPnPSetupStatusY,
    sFAILEDOK[AValue],
    clFAILEDOK[AValue],
    clPnPSetupBack
  );

  ResetProgressBar;
end;

procedure CreateComponents;
begin
  IGEdit.PositionX := kPnPSetupEditX;
  IGEdit.PositionY := kPnPSetupEditY;
  IGEdit.Width := kPnPSetupEditWidth;
  IGEdit.Colors.Foreground := clPnPSetupEditFore;
  IGEdit.Colors.Background := clPnPSetupEditBack;
  IGEdit.Colors.HighForeground := clPnPSetupEditHighFore;
  IGEdit.Colors.HighBackground := clPnPSetupEditHighBack;
  IGEdit.Text := sPnPSetupDefaultFilename;

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

  IGRawData.PositionX := kPnPSetupRawDataX;
  IGRawData.PositionY := kPnPSetupRawDataY;
  IGRawData.Width := kPnPSetupRawDataWidth;
  IGRawData.Height := kPnPSetupRawDataHeight;
  IGRawData.Colors.Foreground := clPnPSetupRawDataFore;
  IGRawData.Colors.Background := clPnPSetupRawDataBack;
  IGRawData.Colors.Title := clPnPSetupRawDataTitle;
  IGRawData.Title := sPnPSetupRawData;

  IGMessageBox.Colors.Foreground := clMessageBoxFore;
  IGMessageBox.Colors.Background := clMessageBoxBack;
  IGMessageBox.Colors.BtnForeground := clMessageBoxBtnFore;
  IGMessageBox.Colors.BtnBackground := clMessageBoxBtnBack;
  IGMessageBox.Colors.BtnAccelerator := clMessageBoxBtnAccel;
  IGMessageBox.Colors.BtnHighForeground := clMessageBoxBtnHighFore;
  IGMessageBox.Colors.BtnHighBackground := clMessageBoxBtnHighBack;
  IGMessageBox.Colors.BtnHighAccelerator := clMessageBoxBtnHighAccel;
end;

procedure DrawComponents;
var
  LUIKeyValue: Byte;
  LKeyValueData: TKeyValueData;

begin
  VideoWriteRegion(
    kPnPSetupComponentsLeft,
    kPnPSetupComponentsTop,
    kPnPSetupComponentsWidth,
    kPnPSetupComponentsHeight,
    cSpace,
    VideoAttribute(
      clPnPSetupFore,
      clPnPSetupBack
    )
  );

  for LUIKeyValue := Low(kUIKeyValues) to High(kUIKeyValues) do
  begin
    LKeyValueData.KeyX := kPnPSetupKeyX;
    LKeyValueData.ValueX := kPnPSetupValueX;
    LKeyValueData.PositionY := kUIKeyValues[LUIKeyValue].Y;
    LKeyValueData.Width := kPnPSetupKeyValueWidth;
    LKeyValueData.Colors.Foreground := clPnPSetupFore;
    LKeyValueData.Colors.Background := clPnPSetupBack;
    LKeyValueData.Key := StrPas(kUIKeyValues[LUIKeyValue].Key);
    LKeyValueData.Value := StrPas(kUIKeyValues[LUIKeyValue].Value);

    ScreenKeyValueDraw(LKeyValueData);
  end;

  ScreenEditDraw(IGEdit);

  ScreenProgressBarDraw(IGProgressBar);

  ScreenFramedAreaDraw(IGRawData);
end;

procedure DrawCommands;
var
  LUICommand: Byte;

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

  for LUICommand := Low(kUICommands) to High(kUICommands) do
  begin
    ScreenCommandDraw(
      kPnPSetupCmdX,
      kUICommands[LUICommand].Y,
      clPnPSetupCmdHigh,
      clPnPSetupCmdFore,
      clPnPSetupCmdBack,
      StrPas(kUICommands[LUICommand].Accelerator),
      StrPas(kUICommands[LUICommand].Name)
    );
  end;
end;

procedure UIDraw;
begin
  ScreenTitleBarDraw(clInterfaceFore, clInterfaceBack, clInterfaceFore, sPnPSetupTitle);

  CreateComponents;

  DrawComponents;
  DrawCommands;
end;

procedure UILoop;
var
  LScanCode: Word;
  LKey: Char;

begin
  while True do
  begin
    LScanCode := GetScanCode;
    LKey := UpCase(GetStandardKey(LScanCode));

    case LKey of
      kKeyExtended:
        begin
          case GetExtendedKey(LScanCode) of
            kKeyF4:
              begin
                ScreenEditChange(IGEdit);
              end;

            kKeyF5:
              begin
                ResetOperationStatus(opEraseFast);
                DrawResult(ControllerEraseEEPROM(cemFast, UpdateProgressBar));
              end;

            kKeyF6:
              begin
                ResetOperationStatus(opEraseSlow);
                DrawResult(ControllerEraseEEPROM(cemSlow, UpdateProgressBar));
              end;

            kKeyF7:
              begin
                ResetOperationStatus(opRead);

                if FileExists(IGEdit.Text) then
                begin
                  ScreenMessageBoxPrepare(
                    IGMessageBox,
                    sMessageBoxQuestion,
                    sPnPSetupFileExists,
                    [mbYes, mbNo],
                    mbYes
                  );

                  if ScreenMessageBoxDraw(IGMessageBox) <> mrYes then
                  begin
                    DrawResult(False);

                    Continue;
                  end;
                end;

                DrawResult(ControllerReadEEPROM(IGEdit.Text, UpdateProgressBar));
              end;

            kKeyF8:
              begin
                ResetOperationStatus(opWrite);

                if FileExists(IGEdit.Text) then
                begin
                  DrawResult(ControllerWriteEEPROM(IGEdit.Text, UpdateProgressBar));
                end else
                begin
                  ScreenMessageBoxPrepare(
                    IGMessageBox,
                    sMessageBoxError,
                    sPnPSetupFileNotExists,
                    [mbClose],
                    mbClose
                  );

                  ScreenMessageBoxDraw(IGMessageBox);

                  DrawResult(False);
                end;
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
  LPositionY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kPnPSetupStartupDelay);

  VideoInitialize(LPositionY, LVideoRAMData);
  ScreenInitialize;

  UIDraw;
  UILoop;

  ScreenFinalize;
  VideoFinalize(LPositionY, LVideoRAMData);
end;

end.
