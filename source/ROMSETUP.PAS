{ --------------------------------------------------------------------------- }
{ - Audio Interface - (EEP)ROM Setup Subprogram (romsetup.pas)              - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$G+}

unit ROMSetup;

interface

procedure ROMSetupStart;

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
  kCmdProgramCommandsY         = 3;
  kCmdEditFilenameY            = 4;
  kCmdEraseEEPROMFY            = 6;
  kCmdEraseEEPROMSY            = 7;
  kCmdReadEEPROMY              = 8;
  kCmdWriteEEPROMY             = 9;
  kCmdExitY                    = 11;

  kKVFilenameY                 = 3;
  kKVOperationY                = 4;
  kKVStatusY                   = 5;
  kKVEEPROMY                   = 6;

  kUICommands: packed array[0..kROMSetupCmdCount] of TUICommand = (
    ( Y: kCmdEditFilenameY; Accelerator: sROMSetupCmdF4; Name: sROMSetupCmdEditFilename ),
    ( Y: kCmdEraseEEPROMFY; Accelerator: sROMSetupCmdF5; Name: sROMSetupCmdEraseEEPROMF ),
    ( Y: kCmdEraseEEPROMSY; Accelerator: sROMSetupCmdF6; Name: sROMSetupCmdEraseEEPROMS ),
    ( Y: kCmdReadEEPROMY; Accelerator: sROMSetupCmdF7; Name: sROMSetupCmdReadEEPROM ),
    ( Y: kCmdWriteEEPROMY; Accelerator: sROMSetupCmdF8; Name: sROMSetupCmdWriteEEPROM ),
    ( Y: kCmdExitY; Accelerator: sROMSetupCmdESC; Name: sROMSetupCmdExit )
  );

  kUIKeyValues: packed array[0..kROMSetupKeyValueCount] of TUIKeyValue = (
    ( Y: kKVFilenameY; Key: sROMSetupFilename; Value: cMinus ),
    ( Y: kKVOperationY; Key: sROMSetupOperation; Value: cMinus ),
    ( Y: kKVStatusY; Key: sROMSetupStatus; Value: cMinus ),
    ( Y: kKVEEPROMY; Key: sROMSetupEEPROM; Value: sROMSetup93C56A )
  );

  sOperations: packed array[TOperation] of String[Length(sROMSetupEraseFast)] = (
    sROMSetupEraseFast,
    sROMSetupEraseSlow,
    sROMSetupRead,
    sROMSetupWrite
  );

var
  IGEdit: TEditData;
  IGProgressBar: TProgressBarData;
  IGRawData: TFramedAreaData;
  IGMessageBox: TMessageBoxData;

procedure UIComponentsCreate; forward;
procedure UIComponentsDraw; forward;
procedure UICommandsDraw; forward;

procedure UIProgressBarUpdate(const ABytes: Word; const AByte: Byte); far; forward;
procedure UIProgressBarReset; forward;

procedure UIOperationStatusReset(const AOperation: TOperation); forward;

procedure UIResultDraw(const AValue: Boolean); forward;

procedure UIDraw; forward;
procedure UILoop; forward;

{ private declarations }

procedure UIComponentsCreate;
begin
  IGEdit.PositionX := kROMSetupEditX;
  IGEdit.PositionY := kROMSetupEditY;
  IGEdit.Width := kROMSetupEditWidth;
  IGEdit.MaxLength := kROMSetupEditMaxLength;
  IGEdit.CharacterCase := ccNormal;
  IGEdit.Colors.Foreground := clROMSetupEditFore;
  IGEdit.Colors.Background := clROMSetupEditBack;
  IGEdit.Colors.HighForeground := clROMSetupEditHighFore;
  IGEdit.Colors.HighBackground := clROMSetupEditHighBack;
  IGEdit.Text := sROMSetupDefaultFilename;

  IGProgressBar.PositionX := kROMSetupProgressBarX;
  IGProgressBar.PositionY := kROMSetupProgressBarY;
  IGProgressBar.Width := kROMSetupProgressBarWidth;
  IGProgressBar.Colors.Foreground := clROMSetupProgressFore;
  IGProgressBar.Colors.Background := clROMSetupProgressBack;
  IGProgressBar.Colors.Title := clROMSetupProgressTitle;
  IGProgressBar.Colors.Progress := clROMSetupProgressColor;
  IGProgressBar.DrawMode := dmUpdate;
  IGProgressBar.Min := kROMSetupProgressBarMin;
  IGProgressBar.Max := 256;
  IGProgressBar.Progress := 0;
  IGProgressBar.Title := sROMSetupProgress;

  IGRawData.PositionX := kROMSetupRawDataX;
  IGRawData.PositionY := kROMSetupRawDataY;
  IGRawData.Width := kROMSetupRawDataWidth;
  IGRawData.Height := kROMSetupRawDataHeight;
  IGRawData.Colors.Foreground := clROMSetupRawDataFore;
  IGRawData.Colors.Background := clROMSetupRawDataBack;
  IGRawData.Colors.Title := clROMSetupRawDataTitle;
  IGRawData.Title := sROMSetupRawData;

  IGMessageBox.Colors.Foreground := clMessageBoxFore;
  IGMessageBox.Colors.Background := clMessageBoxBack;
  IGMessageBox.Colors.BtnForeground := clMessageBoxBtnFore;
  IGMessageBox.Colors.BtnBackground := clMessageBoxBtnBack;
  IGMessageBox.Colors.BtnAccelerator := clMessageBoxBtnAccel;
  IGMessageBox.Colors.BtnHighForeground := clMessageBoxBtnHighFore;
  IGMessageBox.Colors.BtnHighBackground := clMessageBoxBtnHighBack;
  IGMessageBox.Colors.BtnHighAccelerator := clMessageBoxBtnHighAccel;
end;

procedure UIComponentsDraw;
var
  LUIKeyValue: Byte;
  LKeyValueData: TKeyValueData;

begin
  VideoWriteRegion(
    kROMSetupComponentsLeft,
    kROMSetupComponentsTop,
    kROMSetupComponentsWidth,
    kROMSetupComponentsHeight,
    cSpace,
    VideoAttribute(
      clROMSetupFore,
      clROMSetupBack
    )
  );

  for LUIKeyValue := Low(kUIKeyValues) to High(kUIKeyValues) do
  begin
    LKeyValueData.KeyX := kROMSetupKeyX;
    LKeyValueData.ValueX := kROMSetupValueX;
    LKeyValueData.PositionY := kUIKeyValues[LUIKeyValue].Y;
    LKeyValueData.Width := kROMSetupKeyValueWidth;
    LKeyValueData.Colors.Foreground := clROMSetupFore;
    LKeyValueData.Colors.Background := clROMSetupBack;
    LKeyValueData.Key := StrPas(kUIKeyValues[LUIKeyValue].Key);
    LKeyValueData.Value := StrPas(kUIKeyValues[LUIKeyValue].Value);

    ScreenKeyValueDraw(LKeyValueData);
  end;

  ScreenEditDraw(IGEdit);

  ScreenProgressBarDraw(IGProgressBar);

  ScreenFramedAreaDraw(IGRawData);
end;

procedure UICommandsDraw;
var
  LUICommand: Byte;

begin
  VideoWriteRegion(
    kROMSetupCommandsLeft,
    kROMSetupCommandsTop,
    kROMSetupCommandsWidth,
    kROMSetupCommandsHeight,
    cSpace,
    VideoAttribute(
      clROMSetupCmdFore,
      clROMSetupCmdBack
    )
  );

  VideoWriteStringAt(
    kROMSetupCmdX,
    kCmdProgramCommandsY,
    sROMSetupCmdProgramCmds,
    clROMSetupCmdHeader,
    clROMSetupCmdBack
  );

  for LUICommand := Low(kUICommands) to High(kUICommands) do
  begin
    ScreenCommandDraw(
      kROMSetupCmdX,
      kUICommands[LUICommand].Y,
      clROMSetupCmdHigh,
      clROMSetupCmdFore,
      clROMSetupCmdBack,
      StrPas(kUICommands[LUICommand].Accelerator),
      StrPas(kUICommands[LUICommand].Name)
    );
  end;
end;

procedure UIProgressBarUpdate(const ABytes: Word; const AByte: Byte);
begin
  ScreenProgressBarSetProgress(IGProgressBar, ABytes);

  VideoWriteCharAttrAt(
    kROMSetupRawDataX + 2 + (ABytes mod kROMSetupRawDataLength),
    kROMSetupRawDataY + 2 + (ABytes div kROMSetupRawDataLength) mod kROMSetupRawDataLength,
    Chr(AByte),
    VideoAttribute(
      clROMSetupFore,
      clROMSetupBack
    )
  );
end;

procedure UIProgressBarReset;
begin
  Routines.Delay(kROMSetupOperationDelay);

  ScreenProgressBarReset(IGProgressBar, kROMSetupProgressBarMin);
end;

procedure UIOperationStatusReset(const AOperation: TOperation);
begin
  VideoWriteRegion(
    kROMSetupOperationX,
    kROMSetupOperationY,
    kROMSetupOpStatusWidth,
    kROMSetupOpStatusHeight,
    cSpace,
    VideoAttribute(
      clROMSetupFore,
      clROMSetupBack
    )
  );

  VideoWriteStringAt(
    kROMSetupOperationX,
    kROMSetupOperationY,
    sOperations[AOperation],
    clROMSetupFore,
    clROMSetupBack
  );
end;

procedure UIResultDraw(const AValue: Boolean);
begin
  VideoWriteRegion(
    kROMSetupStatusX,
    kROMSetupStatusY,
    Length(sFAILEDOK[False]),
    1,
    cSpace,
    VideoAttribute(
      clROMSetupFore,
      clROMSetupBack
    )
  );

  VideoWriteStringAt(
    kROMSetupStatusX,
    kROMSetupStatusY,
    sFAILEDOK[AValue],
    clErrorSuccess[AValue],
    clROMSetupBack
  );

  UIProgressBarReset;
end;

procedure UIDraw;
begin
  ScreenTitleBarDraw(clInterfaceFore, clInterfaceBack, clInterfaceFore, sROMSetupTitle);

  UIComponentsCreate;
  UIComponentsDraw;

  UICommandsDraw;
end;

procedure UILoop;
var
  LScanCode: Word;
  LKey: Char;
      i: integer;
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
                UIOperationStatusReset(opEraseFast);
                UIResultDraw(ControllerEraseEEPROM(cemFast, UIProgressBarUpdate));
              end;

            kKeyF6:
              begin
                UIOperationStatusReset(opEraseSlow);
                UIResultDraw(ControllerEraseEEPROM(cemSlow, UIProgressBarUpdate));
              end;

            kKeyF7:
              begin
                UIOperationStatusReset(opRead);

                if FileExists(IGEdit.Text) then
                begin
                  ScreenMessageBoxPrepare(
                    IGMessageBox,
                    sMessageBoxQuestion,
                    sROMSetupFileExists,
                    [mbYes, mbNo],
                    mbYes
                  );

                  if ScreenMessageBoxDraw(IGMessageBox) <> mrYes then
                  begin
                    UIResultDraw(False);

                    Continue;
                  end;
                end;

                UIResultDraw(ControllerReadEEPROM(IGEdit.Text, UIProgressBarUpdate));
              end;

            kKeyF8:
              begin
                UIOperationStatusReset(opWrite);

                if FileExists(IGEdit.Text) then
                begin
                  UIResultDraw(ControllerWriteEEPROM(IGEdit.Text, UIProgressBarUpdate));
                end else
                begin
                  ScreenMessageBoxPrepare(
                    IGMessageBox,
                    sMessageBoxError,
                    sROMSetupFileNotExists,
                    [mbClose],
                    mbClose
                  );

                  ScreenMessageBoxDraw(IGMessageBox);

                  UIResultDraw(False);
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

procedure ROMSetupStart;
var
  LPositionY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kROMSetupStartupDelay);

  VideoInitialize(LPositionY, LVideoRAMData);
  ScreenInitialize;

  UIDraw;
  UILoop;

  ScreenFinalize;
  VideoFinalize(LPositionY, LVideoRAMData);
end;

end.
