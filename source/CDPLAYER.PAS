{ --------------------------------------------------------------------------- }
{ - Audio Interface - CD Player Subprogram (cdplayer.pas)                   - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$G+}

unit CDPlayer;

interface

function CDPlayerConfigLoad: Boolean;
function CDPlayerConfigSave: Boolean;

procedure CDPlayerConfigDefault;

function CDPlayerStart: Boolean;

implementation

uses
  Dos,
  CDROM,
  Consts,
  Routines,
  Screen,
  SysTimer,
  Types,
  Video;

type
  TSysTimerTrigger = (
    sttQuarterSecond,
    sttFullSecond
  );

  TSysTimerTriggers = set of TSysTimerTrigger;

  TCDPlayerOption = (
    cdpAutoEject,
    cdpRepeatTrack,
    cdpRepeatAll,
    cdpShuffleOrder,
    cdpReverseOrder
  );

  TCDPlayerOptionData = packed record
    PositionY: Byte;
    Enabled: Boolean;
  end;

  PAudioTracks = ^TAudioTracks;
  TAudioTracks = packed array[1..1] of TAudioTrack;

  TCDPlayerTracks = packed record
    Data: PAudioTracks;
    OrderIndex: Byte;
  end;

  TCDPlayerDoor = packed record
    Closed: Boolean;
    Locked: Boolean;
  end;

  TCDPlayerStatus = (
    cdpsStop,
    cdpsPlay,
    cdpsPause
  );

  TCDPlayerTime = packed record
    TrackPlay: TTimeData;
    Track: TTimeData;
    DiskPlay: TTimeData;
    Disk: TTimeData;
  end;

  TCDPlayerControl = packed record
    WasReset: Boolean;
    OldDisk: Boolean;
    Play: Boolean;
    Pause: Boolean;
    LED: Boolean;
  end;

  TCDPlayerConfig = packed record
    DriveLetter: Char;
    AutoEject: Boolean;
    RepeatTrack: Boolean;
    RepeatAll: Boolean;
    ShuffleOrder: Boolean;
    ReverseOrder: Boolean;
  end;

  TCDPlayer = packed record
    AudioDisk: TAudioDisk;
    Tracks: TCDPlayerTracks;
    Door: TCDPlayerDoor;
    Disk: Boolean;
    Status: TCDPlayerStatus;
    Time: TCDPlayerTime;
    Control: TCDPlayerControl;
    Config: TCDPlayerConfig;
  end;

const
  kFileSignature: TFileSignature = 'AG86.CDP';

  cZero                        = '0';
  cOne                         = '1';
  cNine                        = '9';

  kSecondsLeadInPreGap         = 2;

  kCmdProgramCommandsY         = 3;
  kCmdChangeDriveY             = 4;
  kCmdOpenCloseDoorY           = 5;
  kCmdLockUnlockY              = 6;
  kCmdResetDriveY              = 7;
  kCmdPreviousY                = 9;
  kCmdPlayY                    = 10;
  kCmdPauseY                   = 11;
  kCmdStopY                    = 12;
  kCmdNextY                    = 13;
  kCmdRandomTrackY             = 15;
  kCmdQuickPlayY               = 16;
  kCmdExitY                    = 17;

  kCmdProgramOptionsY          = 19;
  kCmdAutoEjectY               = 20;
  kCmdRepeatTrackY             = 21;
  kCmdRepeatAllY               = 22;
  kCmdShuffleOrderY            = 23;
  kCmdReverseOrderY            = 24;

  kKVDriveLetterY              = 3;
  kKVDoorClosedY               = 4;
  kKVDoorLockedY               = 5;
  kKVDiskY                     = 6;
  kKVStatusY                   = 7;
  kKVTrackY                    = 8;
  kKVTotalTracksY              = 9;
  kKVTrackTimeY                = 10;
  kKVTrackPlayTimeY            = 11;
  kKVDiskTimeY                 = 12;
  kKVDiskPlayTimeY             = 13;

  kUIStatCommands: packed array[0..kCDPlayerStatCmdCount] of TUICommand = (
    ( Y: kCmdChangeDriveY; Accelerator: sCDPlayerCmdF4; Name: sCDPlayerCmdChangeDrive ),
    ( Y: kCmdOpenCloseDoorY; Accelerator: sCDPlayerCmdF5; Name: sCDPlayerCmdOpenCloseDoor ),
    ( Y: kCmdLockUnlockY; Accelerator: sCDPlayerCmdF6; Name: sCDPlayerCmdLockUnlock ),
    ( Y: kCmdResetDriveY; Accelerator: sCDPlayerCmdF7; Name: sCDPlayerCmdResetDrive ),
    ( Y: kCmdPreviousY; Accelerator: sCDPlayerCmdZ; Name: sCDPlayerCmdPrevious ),
    ( Y: kCmdPlayY; Accelerator: sCDPlayerCmdX; Name: sCDPlayerCmdPlay ),
    ( Y: kCmdPauseY; Accelerator: sCDPlayerCmdC; Name: sCDPlayerCmdPause ),
    ( Y: kCmdStopY; Accelerator: sCDPlayerCmdV; Name: sCDPlayerCmdStop ),
    ( Y: kCmdNextY; Accelerator: sCDPlayerCmdB; Name: sCDPlayerCmdNext ),
    ( Y: kCmdRandomTrackY; Accelerator: sCDPlayerCmdStar; Name: sCDPlayerCmdRandomTrack ),
    ( Y: kCmdQuickPlayY; Accelerator: sCDPlayerCmd1to9; Name: sCDPlayerCmdQuickPlay ),
    ( Y: kCmdExitY; Accelerator: sCDPlayerCmdESC; Name: sCDPlayerCmdExit )
  );

  kUIDynCommands: packed array[0..kCDPlayerDynCmdCount] of TUICommand = (
    ( Y: kCmdAutoEjectY; Accelerator: sCDPlayerCmd1; Name: sCDPlayerCmdAutoEject ),
    ( Y: kCmdRepeatTrackY; Accelerator: sCDPlayerCmd2; Name: sCDPlayerCmdRepeatTrack ),
    ( Y: kCmdRepeatAllY; Accelerator: sCDPlayerCmd3; Name: sCDPlayerCmdRepeatAll ),
    ( Y: kCmdShuffleOrderY; Accelerator: sCDPlayerCmd4; Name: sCDPlayerCmdShuffleOrder ),
    ( Y: kCmdReverseOrderY; Accelerator: sCDPlayerCmd5; Name: sCDPlayerCmdReverseOrder )
  );

  kUIKeyValues: packed array[0..kCDPlayerKeyValueCount] of TUIKeyValue = (
    ( Y: kKVDriveLetterY; Key: sCDPlayerDriveLetter; Value: cMinus ),
    ( Y: kKVDoorClosedY; Key: sCDPlayerDoorClosed; Value: cMinus ),
    ( Y: kKVDoorLockedY; Key: sCDPlayerDoorLocked; Value: cMinus ),
    ( Y: kKVDiskY; Key: sCDPlayerDisk; Value: cMinus ),
    ( Y: kKVStatusY; Key: sCDPlayerStatus; Value: cMinus ),
    ( Y: kKVTrackY; Key: sCDPlayerTrack; Value: cMinus ),
    ( Y: kKVTotalTracksY; Key: sCDPlayerTotalTracks; Value: cMinus ),
    ( Y: kKVTrackTimeY; Key: sCDPlayerTrackTime; Value: cMinus ),
    ( Y: kKVTrackPlayTimeY; Key: sCDPlayerTrackPlayTime; Value: cMinus ),
    ( Y: kKVDiskTimeY; Key: sCDPlayerDiskTime; Value: cMinus ),
    ( Y: kKVDiskPlayTimeY; Key: sCDPlayerDiskPlayTime; Value: cMinus )
  );

  sCDPlayerDisk: packed array[Boolean] of String[Length(sCDPlayerDiskUnloaded)] = (
    sCDPlayerDiskUnloaded,
    sCDPlayerDiskLoaded
  );

  sCDPlayerStatuses: packed array[TCDPlayerStatus] of PChar = (
    sCDPlayerStatusStop,
    sCDPlayerStatusPlay,
    sCDPlayerStatusPause
  );

var
  IGSysTimerTickCount: Byte;
  IGSysTimerTriggers: TSysTimerTriggers;
  IGCDPlayerConfigChanged: Boolean;
  IGDriveLetterEdit: TEditData;
  IGKeyValues: packed array[0..kCDPlayerKeyValueCount] of TKeyValueData;
  IGTrackOrderFramedArea: TFramedAreaData;
  IGTrackProgressBar: TProgressBarData;
  IGDiskProgressBar: TProgressBarData;
  IGCDPLayerOptions: packed array[TCDPlayerOption] of TCDPlayerOptionData;
  IGMessageBox: TMessageBoxData;

  IGCDPlayer: TCDPlayer;

{ private declarations }

procedure SysTimerInit; forward;
procedure SysTimerCallback; far; forward;

procedure UIComponentsCreate; forward;
procedure UIComponentsDraw; forward;

procedure UICommandsDraw; forward;

procedure UIOptionInit(var AOptionData: TCDPlayerOptionData; const APositionY: Byte;
  const AEnabled: Boolean); forward;
procedure UIOptionsInit; forward;
procedure UIOptionsDraw; forward;
procedure UIOptionHighlight(const AOption: TCDPlayerOption); forward;
procedure UIOptionsHighlight; forward;
procedure UIOptionToggleHighlight(const AOption: TCDPlayerOption); forward;
procedure UIOptionHighlightMode(const AOption, ASearchFrom, ASearchTo: TCDPlayerOption); forward;
procedure UIOptionHighlightRepeatMode(const AOption: TCDPlayerOption); forward;
procedure UIOptionHighlightPlayMode(const AOption: TCDPlayerOption); forward;

procedure UICDEXVersionDraw; forward;

procedure UIDraw; forward;
procedure UILoop; forward;

procedure UIDisplayCDROMError(const AErrorCode: Byte); forward;
procedure UIEditDriveLetter; forward;
procedure UISetDrawValue(const AKVIndex: Byte; const AKVValue: String); forward;
procedure UISetDrawStatus(const ACDPlayerStatus: TCDPlayerStatus); forward;

procedure UIUpdateAll; forward;
procedure UIUpdateLED(const APositionY, AColor: Byte); forward;
procedure UIUpdateLEDs(const APlayState, APauseState, AStopState: Boolean); forward;
procedure UIUpdateControlLEDs; forward;
procedure UIUpdateDoorDisk; forward;
procedure UIUpdateStatus; forward;
procedure UIUpdateTrackTimeData; forward;
procedure UIResetTrackProgressBar; forward;
procedure UIResetDiskProgressBar; forward;
procedure UIUpdateAllResetProgressBars; forward;

procedure UITracksOrderDisplay; forward;

function CDSucceeded(const ACDROMStatus: Word): Boolean; forward;

procedure CDPlayerReset; forward;
procedure CDUpdateTrackTimeData; forward;
procedure CDLoadUnload; forward;
procedure CDLoad; forward;
procedure CDUnload; forward;
procedure CDLockUnlock; forward;
procedure CDResetDrive; forward;
procedure CDOpenCloseDoor; forward;

function CDTracksGetOrder(const ATrackNumber: Byte): Byte; forward;
procedure CDTracksRead; forward;
procedure CDTracksClear; forward;
procedure CDTracksSetPlayMode; forward;
procedure CDTracksNormalOrder; forward;
procedure CDTracksShuffleOrder; forward;
procedure CDTracksReverseOrder; forward;
procedure CDSwitchTrack(const ATrackNumber: Byte); forward;

procedure CDPlayPreviousTrack; forward;
procedure CDPlayTrack; forward;
procedure CDPauseTrack; forward;
procedure CDStopTrack; forward;
procedure CDPlayNextTrack; forward;
procedure CDPlayRandomTrack; forward;
procedure CDQuickPlay(const ATrackNumber: Byte); forward;
procedure CDPlayRemaining; forward;

function CDHasReached(const ACurrent, ATarget: TTimeData): Boolean; forward;
procedure CDCheckOptions; forward;

procedure CDPlayerConfigClearPlayMode; forward;
procedure CDPlayerConfigSet; forward;

procedure SysTimerInit;
begin
  IGSysTimerTriggers := [];
  IGSysTimerTickCount := 0;

  SysTimerInterruptHook(SysTimerCallback);
end;

procedure SysTimerCallback;
begin
  Inc(IGSysTimerTickCount);

  if IGSysTimerTickCount mod 5 = 0 then
  begin
    Include(IGSysTimerTriggers, sttQuarterSecond);
  end;

  if IGSysTimerTickCount >= 18 then
  begin
    IGSysTimerTickCount := 0;

    Include(IGSysTimerTriggers, sttFullSecond);
  end;
end;

procedure UIComponentsCreate;
var
  LKeyValue: Byte;

begin
  IGDriveLetterEdit.PositionX := kCDPlayerValueX;
  IGDriveLetterEdit.PositionY := kCDPlayerEditY;
  IGDriveLetterEdit.Width := kCDPlayerEditWidth;
  IGDriveLetterEdit.MaxLength := kCDPlayerEditMaxLength;
  IGDriveLetterEdit.CharacterCase := ccUpperCase;
  IGDriveLetterEdit.Colors.Foreground := clCDPlayerEditFore;
  IGDriveLetterEdit.Colors.Background := clCDPlayerEditBack;
  IGDriveLetterEdit.Colors.HighForeground := clCDPlayerEditHighFore;
  IGDriveLetterEdit.Colors.HighBackground := clCDPlayerEditHighBack;
  IGDriveLetterEdit.Text := GCDROMData.CurrentDriveLetter + cSemicolon + cBackslash;

  for LKeyValue := Low(kUIKeyValues) to High(kUIKeyValues) do
  begin
    IGKeyValues[LKeyValue].KeyX := kCDPlayerKeyX;
    IGKeyValues[LKeyValue].ValueX := kCDPlayerValueX;
    IGKeyValues[LKeyValue].PositionY := kUIKeyValues[LKeyValue].Y;
    IGKeyValues[LKeyValue].Width := kCDPlayerKeyValueWidth;
    IGKeyValues[LKeyValue].Colors.Foreground := clCDPlayerFore;
    IGKeyValues[LKeyValue].Colors.Background := clCDPlayerBack;
    IGKeyValues[LKeyValue].Key := StrPas(kUIKeyValues[LKeyValue].Key);
    IGKeyValues[LKeyValue].Value := StrPas(kUIKeyValues[LKeyValue].Value);
  end;

  IGTrackOrderFramedArea.PositionX := kCDPlayerTrackOrderX;
  IGTrackOrderFramedArea.PositionY := kCDPlayerTrackOrderY;
  IGTrackOrderFramedArea.Width := kCDPlayerTrackOrderWidth;
  IGTrackOrderFramedArea.Height := kCDPlayerTrackOrderHeight;
  IGTrackOrderFramedArea.Colors.Foreground := clCDPlayerTrackOrderFore;
  IGTrackOrderFramedArea.Colors.Background := clCDPlayerTrackOrderBack;
  IGTrackOrderFramedArea.Colors.Title := clCDPlayerTrackOrderTitle;
  IGTrackOrderFramedArea.Title := sCDPlayerTrackOrder;

  IGTrackProgressBar.PositionX := kCDPlayerProgressBarX;
  IGTrackProgressBar.PositionY := kCDPlayerTrackProgressY;
  IGTrackProgressBar.Width := kCDPlayerProgressBarWidth;
  IGTrackProgressBar.Colors.Foreground := clCDPlayerProgressFore;
  IGTrackProgressBar.Colors.Background := clCDPlayerProgressBack;
  IGTrackProgressBar.Colors.Title := clCDPlayerProgressTitle;
  IGTrackProgressBar.Colors.Progress := clCDPlayerProgressColor;
  IGTrackProgressBar.DrawMode := dmRepaint;
  IGTrackProgressBar.Min := kCDPlayerProgressBarMin;
  IGTrackProgressBar.Max := 256;
  IGTrackProgressBar.Progress := 0;
  IGTrackProgressBar.Title := sCDPlayerTrackProgress;

  IGDiskProgressBar.PositionX := kCDPlayerProgressBarX;
  IGDiskProgressBar.PositionY := kCDPlayerDiskProgressY;
  IGDiskProgressBar.Width := kCDPlayerProgressBarWidth;
  IGDiskProgressBar.Colors.Foreground := clCDPlayerProgressFore;
  IGDiskProgressBar.Colors.Background := clCDPlayerProgressBack;
  IGDiskProgressBar.Colors.Title := clCDPlayerProgressTitle;
  IGDiskProgressBar.Colors.Progress := clCDPlayerProgressColor;
  IGDiskProgressBar.DrawMode := dmRepaint;
  IGDiskProgressBar.Min := kCDPlayerProgressBarMin;
  IGDiskProgressBar.Max := 256;
  IGDiskProgressBar.Progress := 0;
  IGDiskProgressBar.Title := sCDPlayerDiskProgress;

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
  LKeyValue: Byte;

begin
  VideoWriteRegion(
    kCDPlayerComponentsLeft,
    kCDPlayerComponentsTop,
    kCDPlayerComponentsWidth,
    kCDPlayerComponentsHeight,
    cSpace,
    VideoAttribute(
      clCDPlayerFore,
      clCDPlayerBack
    )
  );

  for LKeyValue := Low(kUIKeyValues) to High(kUIKeyValues) do
  begin
    ScreenKeyValueDraw(IGKeyValues[LKeyValue]);
  end;

  ScreenEditDraw(IGDriveLetterEdit);

  ScreenProgressBarDraw(IGTrackProgressBar);
  ScreenProgressBarDraw(IGDiskProgressBar);

  ScreenFramedAreaDraw(IGTrackOrderFramedArea);
end;

procedure UICommandsDraw;
var
  LUICommand: Byte;

begin
  VideoWriteRegion(
    kCDPlayerCommandsLeft,
    kCDPlayerCommandsTop,
    kCDPlayerCommandsWidth,
    kCDPlayerCommandsHeight,
    cSpace,
    VideoAttribute(
      clCDPlayerStatCmdFore,
      clCDPlayerDynCmdBack
    )
  );

  VideoWriteStringAt(
    kCDPlayerCmdX,
    kCmdProgramCommandsY,
    sCDPlayerCmdProgramCmds,
    clCDPlayerStatCmdHeader,
    clCDPlayerStatCmdBack
  );

  for LUICommand := Low(kUIStatCommands) to High(kUIStatCommands) do
  begin
    ScreenCommandDraw(
      kCDPlayerCmdX,
      kUIStatCommands[LUICommand].Y,
      clCDPlayerStatCmdHigh,
      clCDPlayerStatCmdFore,
      clCDPlayerStatCmdBack,
      StrPas(kUIStatCommands[LUICommand].Accelerator),
      StrPas(kUIStatCommands[LUICommand].Name)
    );
  end;
end;

procedure UIOptionInit(var AOptionData: TCDPlayerOptionData; const APositionY: Byte;
  const AEnabled: Boolean);
begin
  AOptionData.PositionY := APositionY;
  AOptionData.Enabled := AEnabled;
end;

procedure UIOptionsInit;
begin
  UIOptionInit(IGCDPlayerOptions[cdpAutoEject], kCmdAutoEjectY, IGCDPlayer.Config.AutoEject);
  UIOptionInit(IGCDPlayerOptions[cdpRepeatTrack], kCmdRepeatTrackY, IGCDPlayer.Config.RepeatTrack);
  UIOptionInit(IGCDPlayerOptions[cdpRepeatAll], kCmdRepeatAllY, IGCDPlayer.Config.RepeatAll);
  UIOptionInit(IGCDPlayerOptions[cdpShuffleOrder], kCmdShuffleOrderY, IGCDPlayer.Config.ShuffleOrder);
  UIOptionInit(IGCDPlayerOptions[cdpReverseOrder], kCmdReverseOrderY, IGCDPlayer.Config.ReverseOrder);
end;

procedure UIOptionsDraw;
var
  LUIDynCommand: Byte;

begin
  VideoWriteRegion(
    kCDPlayerOptionsLeft,
    kCDPlayerOptionsTop,
    kCDPlayerOptionsWidth,
    kCDPlayerOptionsHeight,
    cSpace,
    VideoAttribute(
      clCDPlayerDynCmdFore,
      clCDPlayerDynCmdBack
    )
  );

  VideoWriteStringAt(
    kCDPlayerCmdX,
    kCmdProgramOptionsY,
    sCDPlayerCmdProgramOptions,
    clCDPlayerDynCmdHeader,
    clCDPlayerDynCmdBack
  );

  for LUIDynCommand := Low(kUIDynCommands) to High(kUIDynCommands) do
  begin
    ScreenCommandDraw(
      kCDPlayerCmdX,
      kUIDynCommands[LUIDynCommand].Y,
      clCDPlayerStatCmdHigh,
      clCDPlayerDynCmdFore,
      clCDPlayerDynCmdBack,
      StrPas(kUIDynCommands[LUIDynCommand].Accelerator),
      StrPas(kUIDynCommands[LUIDynCommand].Name)
    );
  end;
end;

procedure UIOptionHighlight(const AOption: TCDPlayerOption);
var
  LAttribute: Byte;

begin
  if IGCDPLayerOptions[AOption].Enabled then
  begin
    LAttribute := VideoAttribute(clCDPlayerDynCmdHigh, clCDPlayerDynCmdBack);
  end else
  begin
    LAttribute := VideoAttribute(clCDPlayerDynCmdFore, clCDPlayerDynCmdBack);
  end;

  VideoHighlightRegion(
    kCDPlayerOptionX,
    IGCDPlayerOptions[AOption].PositionY,
    kCDPlayerOptionWidth,
    kCDPlayerOptionHeight,
    LAttribute
  );
end;

procedure UIOptionsHighlight;
var
  LOption: TCDPlayerOption;

begin
  for LOption := Low(TCDPlayerOption) to High(TCDPlayerOption) do
  begin
    UIOptionHighlight(LOption);
  end;
end;

procedure UIOptionToggleHighlight(const AOption: TCDPlayerOption);
begin
  IGCDPlayerConfigChanged := True;

  IGCDPlayerOptions[AOption].Enabled := not IGCDPlayerOptions[AOption].Enabled;
  UIOptionHighlight(AOption);
end;

procedure UIOptionHighlightMode(const AOption, ASearchFrom, ASearchTo: TCDPlayerOption);
var
  LOldValue: Boolean;
  LOption: TCDPlayerOption;

begin
  IGCDPlayerConfigChanged := True;

  LOldValue := IGCDPlayerOptions[AOption].Enabled;

  for LOption := ASearchFrom to ASearchTo do
  begin
    IGCDPlayerOptions[LOption].Enabled := False;
    UIOptionHighlight(LOption);
  end;

  IGCDPlayerOptions[AOption].Enabled := not LOldValue;
  UIOptionHighlight(AOption);
end;

procedure UIOptionHighlightRepeatMode(const AOption: TCDPlayerOption);
begin
  UIOptionHighlightMode(AOption, cdpRepeatTrack, cdpRepeatAll);
end;

procedure UIOptionHighlightPlayMode(const AOption: TCDPlayerOption);
begin
  UIOptionHighlightMode(AOption, cdpShuffleOrder, cdpReverseOrder);

  CDTracksSetPlayMode;

  UITracksOrderDisplay;
end;

procedure UICDEXVersionDraw;
var
  LCDEXVersion: Word;

begin
  LCDEXVersion := CDROMGetCDEXVersion;

  VideoWriteStringAt(
    kCDPlayerCDROMExtensionsX,
    kCDPlayerCDROMExtensionsY,
    sCDPlayerCDROMExtensions,
    clCDPlayerFore,
    clCDPlayerBack
  );

  VideoWriteStringAt(
    kCDPlayerDriverVersionX,
    kCDPlayerDriverVersionY,
    sCDPlayerDriverVersion + IfThenElse(
      LCDEXVersion = 0,
      sNA,
      IntToStr(Hi(LCDEXVersion)) + cFullStop + IntToStr(Lo(LCDEXVersion))
    ),
    clCDPlayerFore,
    clCDPlayerBack
  );
end;

procedure UIDraw;
begin
  ScreenTitleBarDraw(clInterfaceFore, clInterfaceBack, clInterfaceFore, sCDPlayerTitle);

  UIComponentsCreate;
  UIComponentsDraw;

  UICommandsDraw;

  UIOptionsInit;
  UIOptionsDraw;
  UIOptionsHighlight;

  UICDEXVersionDraw;
end;

procedure UILoop;
var
  LScanCode: Word;
  LKey: Char;

begin
  while True do
  begin
    if GetKeyPressed then
    begin
      LScanCode := GetScanCode;
      LKey := UpCase(GetStandardKey(LScanCode));

      case LKey of
        kKeyExtended:
          begin
            case GetExtendedKey(LScanCode) of
              kKeyF5:
                UIEditDriveLetter;

              kKeyF6:
                CDOpenCloseDoor;

              kKeyF7:
                CDLockUnlock;

              kKeyF8:
                CDResetDrive;

            end;
          end;

        kKeyEscape:
          begin
            case IGCDPlayer.Status of
              cdpsPlay:
                begin
                  ScreenMessageBoxPrepare(
                    IGMessageBox,
                    sMessageBoxQuestion,
                    sCDPlayerBackgroundPlay,
                    [mbYes, mbNo, mbCancel],
                    mbYes
                  );

                  case ScreenMessageBoxDraw(IGMessageBox) of
                    mrCancel:
                      Continue;

                    mrNo:
                      CDStopTrack;

                    mrYes:
                      begin
                        CDPlayerConfigClearPlayMode;

                        CDPlayRemaining;

                        Break;
                      end;

                  end;
                end;

              cdpsPause:
                begin
                  ScreenMessageBoxPrepare(
                    IGMessageBox,
                    sMessageBoxQuestion,
                    sCDPlayerBackgroundPause,
                    [mbYes, mbNo, mbCancel],
                    mbYes
                  );

                  case ScreenMessageBoxDraw(IGMessageBox) of
                    mrCancel:
                      Continue;

                    mrNo:
                      CDStopTrack;

                    mrYes:
                      begin
                        CDPlayerConfigClearPlayMode;

                        Break;
                      end;

                  end;
                end;

            end;

            Break;
          end;

        sCDPlayerCmdZ:
          CDPlayPreviousTrack;

        sCDPlayerCmdX:
          CDPlayTrack;

        sCDPlayerCmdC:
          CDPauseTrack;

        sCDPlayerCmdV:
          CDStopTrack;

        sCDPlayerCmdB:
          CDPlayNextTrack;

        sCDPlayerCmdStar:
          CDPlayRandomTrack;

        cOne..cNine:
          CDQuickPlay(Ord(LKey) - Ord(cZero));

        sCDPlayerCmd1:
          UIOptionToggleHighlight(cdpAutoEject);

        sCDPlayerCmd2:
          UIOptionHighlightRepeatMode(cdpRepeatTrack);

        sCDPlayerCmd3:
          UIOptionHighlightRepeatMode(cdpRepeatAll);

        sCDPlayerCmd4:
          UIOptionHighlightPlayMode(cdpShuffleOrder);

        sCDPlayerCmd5:
          UIOptionHighlightPlayMode(cdpReverseOrder);

      end;
    end;

    if sttQuarterSecond in IGSysTimerTriggers then
    begin
      CDUpdateTrackTimeData;

      UIUpdateDoorDisk;
      CDCheckOptions;

      UIUpdateStatus;
      UIUpdateControlLEDs;

      Exclude(IGSysTimerTriggers, sttQuarterSecond);
    end;

    if sttFullSecond in IGSysTimerTriggers then
    begin
      UIUpdateTrackTimeData;

      Exclude(IGSysTimerTriggers, sttFullSecond);
    end;
  end;
end;

procedure UIDisplayCDROMError(const AErrorCode: Byte);
begin
  ScreenMessageBoxPrepare(
    IGMessageBox,
    sMessageBoxError,
    sCDPlayerCDROMError + StrPas(CDROMGetError(AErrorCode)),
    [mbClose],
    mbClose
  );

  ScreenMessageBoxDraw(IGMessageBox);
end;

procedure UIEditDriveLetter;
var
  LOldDriveLetter: String[kCDPlayerEditMaxLength];

begin
  LOldDriveLetter := IGDriveLetterEdit.Text;

  ScreenEditChange(IGDriveLetterEdit);

  if IGDriveLetterEdit.Text <> LOldDriveLetter then
  begin
    if CDROMDriveCheck(IGDriveLetterEdit.Text[1]) then
    begin
      CDPlayerReset;

      GCDROMData.CurrentDriveLetter := IGDriveLetterEdit.Text[1];

      IGCDPlayerConfigChanged := True;
    end else
    begin
      ScreenMessageBoxPrepare(
        IGMessageBox,
        sMessageBoxError,
        IGDriveLetterEdit.Text + sCDPlayerDriveNotCDROM,
        [mbClose],
        mbClose
      );

      ScreenMessageBoxDraw(IGMessageBox);

      IGDriveLetterEdit.Text := LOldDriveLetter;
      ScreenEditDraw(IGDriveLetterEdit);
    end;
  end;
end;

procedure UISetDrawValue(const AKVIndex: Byte; const AKVValue: String);
begin
  ScreenKeyValueSetValue(IGKeyValues[AKVIndex], AKVValue);
end;

procedure UISetDrawStatus(const ACDPlayerStatus: TCDPlayerStatus);
begin
  if IGCDPlayer.Status <> ACDPlayerStatus then
  begin
    IGCDPlayer.Status := ACDPlayerStatus;
    UISetDrawValue(kCDPlayerKVStatus, StrPas(sCDPlayerStatuses[IGCDPlayer.Status]));
  end;
end;

procedure UIUpdateAll;
begin
  UISetDrawValue(kCDPlayerKVDoorClosed, sNoYes[IGCDPlayer.Door.Closed]);
  UISetDrawValue(kCDPlayerKVDoorLocked, sNoYes[IGCDPlayer.Door.Locked]);
  UISetDrawValue(kCDPlayerKVDisk, sCDPlayerDisk[IGCDPlayer.Disk]);
  UISetDrawValue(kCDPlayerKVStatus, StrPas(sCDPlayerStatuses[IGCDPlayer.Status]));
  UISetDrawValue(kCDPlayerKVTrack, IntToStr(IGCDPlayer.Tracks.OrderIndex));
  UISetDrawValue(kCDPlayerKVTotalTracks, IntToStr(IGCDPlayer.AudioDisk.HighestTrackNumber));
  UISetDrawValue(kCDPlayerKVTrackTime, CDROMFormatTime(IGCDPlayer.Time.Track));
  UISetDrawValue(kCDPlayerKVTrackPlayTime, CDROMFormatTime(IGCDPlayer.Time.TrackPlay));
  UISetDrawValue(kCDPlayerKVDiskTime, CDROMFormatTime(IGCDPlayer.Time.Disk));
  UISetDrawValue(kCDPlayerKVDiskPlayTime, CDROMFormatTime(IGCDPlayer.Time.DiskPlay));
end;

procedure UIUpdateLED(const APositionY, AColor: Byte);
begin
  VideoWriteAttrAt(
    kCDPlayerCmdLEDX,
    APositionY,
    VideoAttribute(
      AColor,
      clCDPlayerStatCmdBack
    )
  );
end;

procedure UIUpdateLEDs(const APlayState, APauseState, AStopState: Boolean);
begin
  UIUpdateLED(kCmdPlayY, clCDPlayerPlayLED[APlayState]);
  UIUpdateLED(kCmdPauseY, clCDPlayerPauseLED[APauseState]);
  UIUpdateLED(kCmdStopY, clCDPlayerStopLED[AStopState]);
end;

procedure UIUpdateControlLEDs;
begin
  case IGCDPlayer.Status of
    cdpsStop:
      begin
        UIUpdateLEDs(False, False, IGCDPlayer.Disk);

        Exit;
      end;

    cdpsPlay:
      UIUpdateLEDs(IGCDPlayer.Control.LED, False, False);

    cdpsPause:
      UIUpdateLEDs(True, IGCDPlayer.Control.LED, False);

  end;

  IGCDPlayer.Control.LED := not IGCDPlayer.Control.LED;
end;

procedure UIUpdateDoorDisk;
var
  LStatus: Word;
  LDeviceStatus: TDeviceStatus;
  LAudioStatus: TAudioStatus;

begin
  LStatus := CDROMGetDeviceStatus(LDeviceStatus);

  if CDSucceeded(LStatus) then
  begin
    if IGCDPlayer.Door.Closed <> not LDeviceStatus.DoorOpen then
    begin
      IGCDPlayer.Door.Closed := not LDeviceStatus.DoorOpen;
      UISetDrawValue(kCDPlayerKVDoorClosed, sNoYes[IGCDPlayer.Door.Closed]);

      IGCDPlayer.Disk := IGCDPlayer.Door.Closed and CDROMDriveReady(LStatus);
      UISetDrawValue(kCDPlayerKVDisk, sCDPlayerDisk[IGCDPlayer.Door.Closed]);

      if IGCDPlayer.Control.OldDisk <> IGCDPlayer.Disk then
      begin
        CDLoadUnload;

        IGCDPlayer.Control.OldDisk := IGCDPlayer.Door.Closed;
      end;
    end;

    if IGCDPlayer.Door.Locked <> not LDeviceStatus.DoorUnlocked then
    begin
      IGCDPlayer.Door.Locked := not LDeviceStatus.DoorUnlocked;
      UISetDrawValue(kCDPlayerKVDoorLocked, sNoYes[IGCDPlayer.Door.Locked]);
    end;

    IGCDPlayer.Control.Play := CDROMBusy(LStatus);

    if CDSucceeded(CDROMGetAudioStatusInfo(LAudioStatus)) then
    begin
      IGCDPlayer.Control.Pause := LAudioStatus.Paused;
    end;
  end;
end;

procedure UIUpdateStatus;
var
  LOldStatus: TCDPlayerStatus;
  LCDPlayerStatus: TCDPlayerStatus;

begin
  LOldStatus := IGCDPlayer.Status;

  if IGCDPlayer.Control.Play then
  begin
    LCDPlayerStatus := cdpsPlay;
  end else
  if IGCDPlayer.Control.Pause then
  begin
    LCDPlayerStatus := cdpsPause;
  end else
  begin
    LCDPlayerStatus := cdpsStop;
  end;

  if LCDPlayerStatus <> LOldStatus then
  begin
    UISetDrawStatus(LCDPlayerStatus);
  end;
end;

procedure UIUpdateTrackTimeData;
var
  LTrackSeconds: Word;
  LDiskSeconds: Word;

begin
  if IGCDPlayer.Disk then
  begin
    LTrackSeconds := CDROMTimeToSeconds(IGCDPlayer.Time.Track);
    LDiskSeconds := CDROMTimeToSeconds(IGCDPlayer.Time.Disk);

    if IGCDPlayer.Status = cdpsStop then
    begin
      IGCDPlayer.Time.Track.Value := 0;

      UIResetTrackProgressBar;
      ScreenProgressBarSetProgress(IGDiskProgressBar, LDiskSeconds - LTrackSeconds + 2);
    end else
    begin
      ScreenProgressBarSetProgress(IGTrackProgressBar, LTrackSeconds);
      ScreenProgressBarSetProgress(IGDiskProgressBar, LDiskSeconds);
    end;

    UISetDrawValue(kCDPlayerKVTrackTime, CDROMFormatTime(IGCDPlayer.Time.Track));
    UISetDrawValue(kCDPlayerKVDiskTime, CDROMFormatTime(IGCDPlayer.Time.Disk));
  end;
end;

procedure UIResetTrackProgressBar;
begin
  ScreenProgressBarReset(IGTrackProgressBar, kCDPlayerProgressBarMin);
end;

procedure UIResetDiskProgressBar;
begin
  ScreenProgressBarReset(IGDiskProgressBar, kCDPlayerProgressBarMin);
end;

procedure UIUpdateAllResetProgressBars;
begin
  UIUpdateAll;

  UIResetTrackProgressBar;
  UIResetDiskProgressBar;
end;

procedure UITracksOrderDisplay;
var
  LIndex: Byte;
  LPositionX: Byte;
  LPositionY: Byte;
  LForeground: Byte;
  LString: String[kCDPlayerTrackOrderStrLen];

begin
  if IGCDPlayer.AudioDisk.HighestTrackNumber > 0 then
  begin
    LPositionY := Succ(IGTrackOrderFramedArea.PositionY);

    for LIndex := IGCDPlayer.AudioDisk.LowestTrackNumber to IGCDPlayer.AudioDisk.HighestTrackNumber do
    begin
      LString := IntToStr(IGCDPlayer.Tracks.Data^[LIndex].Order);
      LString[0] := Chr(kCDPlayerTrackOrderStrLen);

      if IGCDPlayer.Tracks.Data^[LIndex].Order < 10 then
      begin
        LString[2] := LString[1];
        LString[1] := Chr(48);
      end;

      if LIndex mod kCDPlayerTrackOrderLineItems = 1 then
      begin
        LPositionX := IGTrackOrderFramedArea.PositionX + 2;
        Inc(LPositionY);
      end;

      if LIndex < IGCDPlayer.Tracks.OrderIndex then
      begin
        LForeground := clCDPlayerTrackOrderPast;
      end else
      if LIndex = IGCDPlayer.Tracks.OrderIndex then
      begin
        LForeground := clCDPlayerTrackOrderCurrent;
      end else
      begin
        LForeground := clCDPlayerTrackOrderFuture;
      end;

      VideoWriteStringAt(
        LPositionX + (Pred(LIndex) mod kCDPlayerTrackOrderLineItems) *
          Succ(kCDPlayerTrackOrderStrLen),
        LPositionY,
        LString,
        LForeground,
        IGTrackOrderFramedArea.Colors.Background
      );
    end;
  end else
  begin
    VideoWriteRegion(
      IGTrackOrderFramedArea.PositionX + 1,
      IGTrackOrderFramedArea.PositionY + 2,
      IGTrackOrderFramedArea.Width - 2,
      IGTrackOrderFramedArea.Height - 2,
      cSpace,
      VideoAttribute(
        IGTrackOrderFramedArea.Colors.Foreground,
        IGTrackOrderFramedArea.Colors.Background
      )
    );
  end;
end;

function CDSucceeded(const ACDROMStatus: Word): Boolean;
var
  LErrorCode: Byte;

begin
  if CDROMSucceeded(ACDROMStatus, LErrorCode) then
  begin
    CDSucceeded := True;
  end else
  begin
    UIDisplayCDROMError(LErrorCode);

    CDSucceeded := False;
  end;
end;

procedure CDPlayerReset;
begin
  CDTracksClear;

  FillChar(IGCDPlayer, SizeOf(TCDPlayer) - SizeOf(TCDPlayerConfig), $00);
end;

procedure CDUpdateTrackTimeData;
var
  LErrorCode: Byte;
  LAudioQChannel: TAudioQChannel;
  LTrackOrder: Byte;

begin
  if IGCDPlayer.Disk and CDSucceeded(CDROMGetAudioQChannelInfo(LAudioQChannel)) then
  begin
    LTrackOrder := CDTracksGetOrder(LAudioQChannel.TrackNumber);

    if IGCDPlayer.Tracks.OrderIndex <> LTrackOrder then
    begin
      CDSwitchTrack(LTrackOrder);
    end;

    IGCDPlayer.Time.Track := LAudioQChannel.TrackTime;
    IGCDPlayer.Time.Disk := LAudioQChannel.DiskTime;
  end else
  begin
    IGCDPlayer.Time.Track.Value := 0;
    IGCDPlayer.Time.Disk.Value := 0;
  end;
end;

procedure CDLoadUnload;
begin
  if IGCDPlayer.Disk then
  begin
    CDLoad;
  end else
  begin
    CDUnload;
  end;
end;

procedure CDLoad;
begin
  if CDSucceeded(CDROMGetAudioDiskInfo(IGCDPlayer.AudioDisk)) then
  begin
    IGCDPlayer.Time.DiskPlay.Value := IGCDPlayer.AudioDisk.LeadOutTrackSector;

    FillChar(IGCDPlayer.Time.Track, SizeOf(TTimeData), $00);
    FillChar(IGCDPlayer.Time.Disk, SizeOf(TTimeData), $00);

    CDTracksRead;
    CDTracksSetPlayMode;

    CDSwitchTrack(IGCDPlayer.Tracks.Data^[IGCDPlayer.Tracks.OrderIndex].Order);

    IGDiskProgressBar.Max := CDROMTimeToSeconds(IGCDPlayer.Time.DiskPlay);
  end;

  UIUpdateAllResetProgressBars;
  UITracksOrderDisplay;
end;

procedure CDUnload;
begin
  CDStopTrack;

  CDPlayerReset;

  IGTrackProgressBar.Max := 0;
  IGDiskProgressBar.Max := 0;

  UIUpdateAllResetProgressBars;
  UITracksOrderDisplay;
end;

procedure CDLockUnlock;
var
  LDeviceStatus: TDeviceStatus;

begin
  if CDSucceeded(CDROMGetDeviceStatus(LDeviceStatus)) then
  begin
    CDROMLockUnlock(LDeviceStatus.DoorUnlocked);
  end;
end;

procedure CDResetDrive;
begin
  if IGCDPlayer.Status <> cdpsStop then
  begin
    CDStopTrack;
  end;

  if CDSucceeded(CDROMResetDrive) then
  begin
    CDLoad;

    IGCDPlayer.Control.WasReset := True;
  end;
end;

procedure CDOpenCloseDoor;
var
  LDeviceStatus: TDeviceStatus;

begin
  if CDSucceeded(CDROMGetDeviceStatus(LDeviceStatus)) then
  begin
    if LDeviceStatus.DoorOpen then
    begin
      CDSucceeded(CDROMCloseTray);
    end else
    begin
      if CDSucceeded(CDROMEjectDisk) then
      begin
        CDUnload;
      end;
    end;
  end;
end;

function CDTracksGetOrder(const ATrackNumber: Byte): Byte;
var
  LIndex: Byte;

begin
  for LIndex := IGCDPlayer.AudioDisk.LowestTrackNumber to IGCDPlayer.AudioDisk.HighestTrackNumber do
  begin
    if IGCDPlayer.Tracks.Data^[LIndex].Order = ATrackNumber then
    begin
      Break;
    end;
  end;

  CDTracksGetOrder := LIndex;
end;

procedure CDTracksRead;
var
  LIndex: Byte;

begin
  GetMem(IGCDPlayer.Tracks.Data, IGCDPlayer.AudioDisk.HighestTrackNumber * SizeOf(TAudioTrack));

  for LIndex := IGCDPlayer.AudioDisk.LowestTrackNumber to IGCDPlayer.AudioDisk.HighestTrackNumber do
  begin
    IGCDPlayer.Tracks.Data^[LIndex].Number := LIndex;
    IGCDPlayer.Tracks.Data^[LIndex].Order := LIndex;

    CDSucceeded(CDROMGetAudioTrackInfo(IGCDPlayer.AudioDisk, IGCDPlayer.Tracks.Data^[LIndex]));
  end;

  IGCDPlayer.Tracks.OrderIndex := IGCDPlayer.AudioDisk.LowestTrackNumber;
end;

procedure CDTracksClear;
var
  LSizeOf: Word;

begin
  if IGCDPlayer.Disk and (IGCDPlayer.Tracks.Data <> nil) then
  begin
    LSizeOf := IGCDPlayer.AudioDisk.HighestTrackNumber * SizeOf(TAudioTrack);

    FillChar(IGCDPlayer.Tracks.Data^, LSizeOf, $00);
    FreeMem(IGCDPlayer.Tracks.Data, LSizeOf);

    FillChar(IGCDPlayer.Tracks, SizeOf(TAudioTracks), $00);
  end;
end;

procedure CDTracksSetPlayMode;
begin
  if IGCDPlayerOptions[cdpShuffleOrder].Enabled then
  begin
    CDTracksShuffleOrder;
  end else
  if IGCDPlayerOptions[cdpReverseOrder].Enabled then
  begin
    CDTracksReverseOrder;
  end else
  begin
    CDTracksNormalOrder;
  end;

  IGCDPlayer.Tracks.OrderIndex := CDTracksGetOrder(
    IGCDPlayer.Tracks.Data^[IGCDPlayer.Tracks.OrderIndex].Number);
end;

procedure CDTracksNormalOrder;
var
  LIndex: Byte;

begin
  for LIndex := IGCDPlayer.AudioDisk.LowestTrackNumber to IGCDPlayer.AudioDisk.HighestTrackNumber do
  begin
    IGCDPlayer.Tracks.Data^[LIndex].Order := LIndex;
  end;
end;

procedure CDTracksShuffleOrder;
var
  LIndex: Byte;
  LRandomIndex: Byte;
  LTrackNumber: Byte;

begin
  Randomize;

  for LIndex := IGCDPlayer.AudioDisk.HighestTrackNumber downto Succ(IGCDPlayer.AudioDisk.LowestTrackNumber) do
  begin
    LRandomIndex := Succ(Random(LIndex));

    LTrackNumber := IGCDPlayer.Tracks.Data^[LIndex].Order;
    IGCDPlayer.Tracks.Data^[LIndex].Order := IGCDPlayer.Tracks.Data^[LRandomIndex].Order;
    IGCDPlayer.Tracks.Data^[LRandomIndex].Order := LTrackNumber;
  end;
end;

procedure CDTracksReverseOrder;
var
  LIndex: Byte;
  LTrackNumber: Byte;

begin
  for LIndex := IGCDPlayer.AudioDisk.LowestTrackNumber to IGCDPlayer.AudioDisk.HighestTrackNumber div 2 do
  begin
    LTrackNumber := IGCDPlayer.Tracks.Data^[LIndex].Order;
    IGCDPlayer.Tracks.Data^[LIndex].Order :=
      IGCDPlayer.Tracks.Data^[Succ(IGCDPlayer.AudioDisk.HighestTrackNumber - LIndex)].Order;
    IGCDPlayer.Tracks.Data^[Succ(IGCDPlayer.AudioDisk.HighestTrackNumber - LIndex)].Order := LTrackNumber;
  end;
end;

procedure CDSwitchTrack(const ATrackNumber: Byte);
begin
  IGCDPlayer.Tracks.OrderIndex := CDTracksGetOrder(ATrackNumber);

  CDROMGetTrackPlayTime(IGCDPlayer.Tracks.Data^[ATrackNumber], IGCDPlayer.Time.TrackPlay);

  UISetDrawValue(kCDPlayerKVTrack, IntToStr(ATrackNumber));
  UISetDrawValue(kCDPlayerKVTrackPlayTime, CDROMFormatTime(IGCDPlayer.Time.TrackPlay));

  UITracksOrderDisplay;

  IGTrackProgressBar.Max := CDROMTimeToSeconds(IGCDPlayer.Time.TrackPlay) -
    kSecondsLeadInPreGap;

  UIResetTrackProgressBar;
end;

procedure CDPlayPreviousTrack;
begin
  if IGCDPlayer.Disk then
  begin
    if IGCDPlayer.Tracks.OrderIndex = IGCDPlayer.AudioDisk.LowestTrackNumber then
    begin
      IGCDPlayer.Tracks.OrderIndex := IGCDPlayer.AudioDisk.HighestTrackNumber;
    end else
    begin
      Dec(IGCDPlayer.Tracks.OrderIndex);
    end;

    CDPlayTrack;
  end;
end;

procedure CDPlayTrack;
var
  LTrackOrder: Byte;

begin
  if IGCDPlayer.Disk then
  begin
    CDStopTrack;

    if IGCDPlayer.Control.WasReset then
    begin
      LTrackOrder := IGCDPlayer.Tracks.Data^[IGCDPlayer.AudioDisk.LowestTrackNumber].Order;

      IGCDPlayer.Control.WasReset := False;
    end else
    begin
      LTrackOrder := IGCDPlayer.Tracks.Data^[IGCDPlayer.Tracks.OrderIndex].Order;
    end;

    CDSwitchTrack(LTrackOrder);

    if IGCDPlayer.Tracks.Data^[LTrackOrder].Data then
    begin
      ScreenMessageBoxPrepare(
        IGMessageBox,
        sMessageBoxInformation,
        sCDPlayerCDROMDataTrack,
        [mbClose],
        mbClose
      );

      ScreenMessageBoxDraw(IGMessageBox);
    end else
    begin
      if CDSucceeded(CDROMPlayAudio(IGCDPlayer.Tracks.Data^[LTrackOrder])) then
      begin
        IGCDPLayer.Control.Play := True;
        IGCDPLayer.Control.Pause := False;
        IGCDPlayer.Control.LED := True;
      end;
    end;
  end;
end;

procedure CDPauseTrack;
begin
  if IGCDPlayer.Control.Play then
  begin
    if CDSucceeded(CDROMStopAudio) then
    begin
      IGCDPLayer.Control.Play := False;
      IGCDPlayer.Control.Pause := True;
    end;
  end else
  if IGCDPlayer.Control.Pause then
  begin
    if CDSucceeded(CDROMResumeAudio) then
    begin
      IGCDPLayer.Control.Play := True;
      IGCDPLayer.Control.Pause := False;
    end;
  end;
end;

procedure CDStopTrack;
var
  LSucceeded: Boolean;

begin
  if IGCDPlayer.Control.Pause and CDSucceeded(CDROMStopAudio) then
  begin
    IGCDPlayer.Control.Pause := False;
  end else
  if IGCDPlayer.Control.Play and CDSucceeded(CDROMStopAudio) and
    CDSucceeded(CDROMStopAudio) then
  begin
    IGCDPlayer.Control.Play := False;
  end;
end;

procedure CDPlayNextTrack;
begin
  if IGCDPlayer.Disk then
  begin
    if IGCDPlayer.Tracks.OrderIndex = IGCDPlayer.AudioDisk.HighestTrackNumber then
    begin
      IGCDPlayer.Tracks.OrderIndex := IGCDPlayer.AudioDisk.LowestTrackNumber;
    end else
    begin
      Inc(IGCDPlayer.Tracks.OrderIndex);
    end;

    CDPlayTrack;
  end;
end;

procedure CDPlayRandomTrack;
begin
  if IGCDPlayer.Disk then
  begin
    Randomize;

    IGCDPlayer.Tracks.OrderIndex := CDTracksGetOrder(Random(Succ(
      IGCDPlayer.AudioDisk.HighestTrackNumber - IGCDPlayer.AudioDisk.LowestTrackNumber)) +
      IGCDPlayer.AudioDisk.LowestTrackNumber);

    CDPlayTrack;
  end;
end;

procedure CDQuickPlay(const ATrackNumber: Byte);
begin
  if IGCDPlayer.Disk and (ATrackNumber >= IGCDPlayer.AudioDisk.LowestTrackNumber) and
    (ATrackNumber <= IGCDPlayer.AudioDisk.HighestTrackNumber) then
  begin
    IGCDPlayer.Tracks.OrderIndex := CDTracksGetOrder(ATrackNumber);

    CDPlayTrack;
  end;
end;

procedure CDPlayRemaining;
var
  LAudioQChannel: TAudioQChannel;
  LAudioTrack: TAudioTrack;

begin
  if CDSucceeded(CDROMGetAudioQChannelInfo(LAudioQChannel)) then
  begin
    LAudioTrack.Number := LAudioQChannel.TrackNumber;
    LAudioTrack.Data := False;
    LAudioTrack.StartSector := LAudioQChannel.DiskTime.Value;
    LAudioTrack.SectorCount := CDROMTimeToLBA(IGCDPlayer.AudioDisk.LeadOutTrackSector) -
      CDROMTimeToLBA(LAudioTrack.StartSector);

    CDSucceeded(CDROMStopAudio);
    CDSucceeded(CDROMPlayAudio(LAudioTrack));
  end;
end;

function CDHasReached(const ACurrent, ATarget: TTimeData): Boolean;
begin
  CDHasReached :=
    ACurrent.Minutes * 60 + ACurrent.Seconds + kSecondsLeadInPreGap >=
    ATarget.Minutes * 60 + ATarget.Seconds;
end;

procedure CDCheckOptions;
begin
  if IGCDPlayer.Disk and CDHasReached(IGCDPlayer.Time.Track, IGCDPlayer.Time.TrackPlay) then
  begin
    if IGCDPlayerOptions[cdpRepeatTrack].Enabled then
    begin
      CDPlayTrack;
    end else
    if IGCDPlayer.Tracks.OrderIndex = IGCDPlayer.Tracks.Data^[
      IGCDPlayer.AudioDisk.HighestTrackNumber].Order then
    begin
      if IGCDPlayerOptions[cdpRepeatAll].Enabled then
      begin
        CDPlayNextTrack;
      end else
      if IGCDPlayerOptions[cdpAutoEject].Enabled then
      begin
        CDOpenCloseDoor;
      end else
      begin
        CDResetDrive;
      end;
    end else
    begin
      CDPlayNextTrack;
    end;
  end;
end;

procedure CDPlayerConfigClearPlayMode;
begin
  IGCDPLayerOptions[cdpShuffleOrder].Enabled := False;
  IGCDPLayerOptions[cdpReverseOrder].Enabled := False;

  IGCDPlayerConfigChanged := True;
end;

procedure CDPlayerConfigSet;
begin
  IGCDPlayer.Config.AutoEject := IGCDPlayerOptions[cdpAutoEject].Enabled;
  IGCDPlayer.Config.RepeatTrack := IGCDPlayerOptions[cdpRepeatTrack].Enabled;
  IGCDPlayer.Config.RepeatAll := IGCDPlayerOptions[cdpRepeatAll].Enabled;
  IGCDPlayer.Config.ShuffleOrder := IGCDPlayerOptions[cdpShuffleOrder].Enabled;
  IGCDPlayer.Config.ReverseOrder := IGCDPlayerOptions[cdpReverseOrder].Enabled;
end;

{ public declarations }

function CDPlayerConfigLoad: Boolean;
var
  LIOSucceeded: Boolean;
  LFile: File;
  LFileName: String;
  LFileSignature: TFileSignature;

begin
  IGCDPlayerConfigChanged := False;

  FillChar(LFileSignature, SizeOf(TFileSignature), $00);

  LFileName := FileReplaceExt(FExpand(ParamStr(0)), fmCDPFiles);

  if FileExists(LFileName) then
  begin
    FileMode := fmReadOnly;
{$I-}
    Assign(LFile, LFileName);
    Reset(LFile, frsBinaryFileRecordSize);
{$I+}
    LIOSucceeded := IOResult = 0;

    if LIOSucceeded then
    begin
      BlockRead(LFile, LFileSignature, SizeOf(TFileSignature));
      BlockRead(LFile, IGCDPlayer.Config, SizeOf(TCDPlayerConfig));
{$I-}
      Close(LFile);
{$I+}
      LIOSucceeded := IOResult = 0;

      if LIOSucceeded then
      begin
        if CDROMDriveCheck(IGCDPlayer.Config.DriveLetter) then
        begin
          GCDROMData.CurrentDriveLetter := IGCDPlayer.Config.DriveLetter;
        end else
        begin
          IGCDPlayer.Config.DriveLetter := GCDROMData.CurrentDriveLetter;

          IGCDPlayerConfigChanged := True;
        end;
      end;
    end;
  end;

  CDPlayerConfigLoad := LIOSucceeded and (LFileSignature = kFileSignature);
end;

function CDPlayerConfigSave: Boolean;
var
  LIOSucceeded: Boolean;
  LFile: File;
  LFileName: String;

begin
  IGCDPlayer.Config.DriveLetter := GCDROMData.CurrentDriveLetter;

  LFileName := FileReplaceExt(FExpand(ParamStr(0)), fmCDPFiles);

  FileMode := fmReadWrite;
{$I-}
  Assign(LFile, LFileName);
  Rewrite(LFile, frsBinaryFileRecordSize);
{$I+}
  LIOSucceeded := IOResult = 0;

  if LIOSucceeded then
  begin
    BlockWrite(LFile, kFileSignature, SizeOf(TFileSignature));
    BlockWrite(LFile, IGCDPlayer.Config, SizeOf(IGCDPLayer.Config));
{$I-}
    Close(LFile);
{$I+}
    LIOSucceeded := IOResult = 0;
  end;

  CDPlayerConfigSave := LIOSucceeded;
end;

procedure CDPlayerConfigDefault;
begin
  IGCDPlayer.Config.AutoEject := kCDPlayerAutoEjectDefault;
  IGCDPlayer.Config.RepeatTrack := kCDPlayerRepeatTrackDefault;
  IGCDPlayer.Config.RepeatAll := kCDPlayerRepeatAllDefault;
  IGCDPlayer.Config.ShuffleOrder := kCDPlayerShuffleOrderDefault;
  IGCDPlayer.Config.ReverseOrder := kCDPlayerReverseOrderDefault;
end;

function CDPlayerStart: Boolean;
var
  LPositionY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kCDPlayerStartupDelay);

  VideoInitialize(LPositionY, LVideoRAMData);
  ScreenInitialize;

  CDPlayerReset;

  SysTimerInit;

  UIDraw;
  UILoop;

  SysTimerInterruptRelease;

  CDPlayerConfigSet;

  ScreenFinalize;
  VideoFinalize(LPositionY, LVideoRAMData);

  CDPlayerStart := IGCDPlayerConfigChanged;
end;

end.
