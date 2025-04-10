{ --------------------------------------------------------------------------- }
{ - Audio Interface - (EEP)ROM Setup Subprogram (romsetup.pas)              - }
{ - Copyright (C) 1998-2022 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

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
  kUICommands: packed array[0..kROMSetupCmdCount] of TUICommand = (
    ( Y: 4; Accelerator: sROMSetupCmdF4; Name: sROMSetupCmdEditFilename ),
    ( Y: 6; Accelerator: sROMSetupCmdF5; Name: sROMSetupCmdEraseEEPROMF ),
    ( Y: 7; Accelerator: sROMSetupCmdF6; Name: sROMSetupCmdEraseEEPROMS ),
    ( Y: 8; Accelerator: sROMSetupCmdF7; Name: sROMSetupCmdReadEEPROM ),
    ( Y: 9; Accelerator: sROMSetupCmdF8; Name: sROMSetupCmdWriteEEPROM ),
    ( Y: 11; Accelerator: sROMSetupCmdESC; Name: sROMSetupCmdExit )
  );

  kUIKeyValues: packed array[0..kROMSetupKeyValueCount] of TUIKeyValue = (
    ( Y: 3; Key: sROMSetupFilename; Value: cMinus ),
    ( Y: 4; Key: sROMSetupOperation; Value: cMinus ),
    ( Y: 5; Key: sROMSetupStatus; Value: cMinus ),
    ( Y: 6; Key: sROMSetupEEPROM; Value: sROMSetup93C56A )
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

{ private declarations }

procedure UIUpdateProgressBar(const ABytes: Word; const AByte: Byte); far; forward;
procedure UIResetProgressBar; forward;
procedure UIResetOperationStatus(const AOperation: TOperation); forward;
procedure UIDrawResult(const AValue: Boolean); forward;
procedure UICreateComponents; forward;
procedure UIDrawComponents; forward;
procedure UIDrawCommands; forward;
procedure UIDraw; forward;
procedure UILoop; forward;

procedure UIUpdateProgressBar(const ABytes: Word; const AByte: Byte);
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

procedure UIResetProgressBar;
begin
  Routines.Delay(kROMSetupOperationDelay);

  ScreenProgressBarReset(IGProgressBar, kROMSetupProgressBarMin);
end;

procedure UIResetOperationStatus(const AOperation: TOperation);
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

procedure UIDrawResult(const AValue: Boolean);
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
    clFAILEDOK[AValue],
    clROMSetupBack
  );

  UIResetProgressBar;
end;

procedure UICreateComponents;
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

procedure UIDrawComponents;
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

procedure UIDrawCommands;
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
    3,
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

procedure UIDraw;
begin
  ScreenTitleBarDraw(clInterfaceFore, clInterfaceBack, clInterfaceFore, sROMSetupTitle);

  UICreateComponents;

  UIDrawComponents;
  UIDrawCommands;
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
                UIResetOperationStatus(opEraseFast);
                UIDrawResult(ControllerEraseEEPROM(cemFast, UIUpdateProgressBar));
              end;

            kKeyF6:
              begin
                UIResetOperationStatus(opEraseSlow);
                UIDrawResult(ControllerEraseEEPROM(cemSlow, UIUpdateProgressBar));
              end;

            kKeyF7:
              begin
                UIResetOperationStatus(opRead);

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
                    UIDrawResult(False);

                    Continue;
                  end;
                end;

                UIDrawResult(ControllerReadEEPROM(IGEdit.Text, UIUpdateProgressBar));
              end;

            kKeyF8:
              begin
                UIResetOperationStatus(opWrite);

                if FileExists(IGEdit.Text) then
                begin
                  UIDrawResult(ControllerWriteEEPROM(IGEdit.Text, UIUpdateProgressBar));
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

                  UIDrawResult(False);
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
