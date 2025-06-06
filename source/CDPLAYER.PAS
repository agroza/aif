{ --------------------------------------------------------------------------- }
{ - Audio Interface - CD Player Subprogram (cdplayer.pas)                   - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$I cdefines.inc}

{$IFDEF CPU16BIT}
  {$G+}
{$ENDIF}

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
    stt50ms,
    stt250ms,
    stt500ms,
    stt1000ms
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
    Index: Byte;
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
    Track: TTimeData;
    TrackPlay: TTimeData;
    Disc: TTimeData;
    DiscPlay: TTimeData;
  end;

  TCDPlayerControl = packed record
    WasReset: Boolean;
    OldDisc: Boolean;
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
    AudioDisc: TAudioDisc;
    Tracks: TCDPlayerTracks;
    Door: TCDPlayerDoor;
    Disc: Boolean;
    Status: TCDPlayerStatus;
    Time: TCDPlayerTime;
    Control: TCDPlayerControl;
    Config: TCDPlayerConfig;
  end;

const
  kFileSignature: TFileSignature = 'AG86.CDP';

  kQuarterSecondMarkers        = [4, 9, 14, 18];
  kHalfSecondMarkers           = [9, 18];
  kFullSecondMarker            = 18;

  cZero                        = '0';
  cOne                         = '1';
  cNine                        = '9';

  kSecondsPerMinute            = 60;
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
  kKVDiscY                     = 6;
  kKVStatusY                   = 7;
  kKVTrackY                    = 8;
  kKVTotalTracksY              = 9;
  kKVTrackTimeY                = 10;
  kKVTrackPlayTimeY            = 11;
  kKVDiscTimeY                 = 12;
  kKVDiscPlayTimeY             = 13;

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
    ( Y: kKVDiscY; Key: sCDPlayerDisc; Value: cMinus ),
    ( Y: kKVStatusY; Key: sCDPlayerStatus; Value: cMinus ),
    ( Y: kKVTrackY; Key: sCDPlayerTrack; Value: cMinus ),
    ( Y: kKVTotalTracksY; Key: sCDPlayerTotalTracks; Value: cMinus ),
    ( Y: kKVTrackTimeY; Key: sCDPlayerTrackTime; Value: cMinus ),
    ( Y: kKVTrackPlayTimeY; Key: sCDPlayerTrackPlayTime; Value: cMinus ),
    ( Y: kKVDiscTimeY; Key: sCDPlayerDiscTime; Value: cMinus ),
    ( Y: kKVDiscPlayTimeY; Key: sCDPlayerDiscPlayTime; Value: cMinus )
  );

  sCDPlayerDisc: packed array[Boolean] of String[Length(sCDPlayerDiscUnloaded)] = (
    sCDPlayerDiscUnloaded,
    sCDPlayerDiscLoaded
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
  IGDiscProgressBar: TProgressBarData;
  IGCDPLayerOptions: packed array[TCDPlayerOption] of TCDPlayerOptionData;
  IGMessageBox: TMessageBoxData;

  IGCDPlayer: TCDPlayer;

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
procedure UIUpdateDoorDisc; forward;
procedure UIUpdateStatus; forward;
procedure UIUpdateAudioQChannel; forward;
procedure UIResetTrackProgressBar; forward;
procedure UIResetDiscProgressBar; forward;
procedure UIUpdateAllResetProgressBars; forward;

procedure UITracksOrderDisplay; forward;

function CDSucceeded(const ACDROMStatus: Word): Boolean; forward;

procedure CDPlayerReset; forward;
procedure CDUpdateAudioQChannel; forward;
procedure CDLoadUnload; forward;
procedure CDLoad; forward;
procedure CDUnload; forward;
procedure CDLockUnlock; forward;
procedure CDResetDrive; forward;
procedure CDOpenCloseDoor; forward;

function CDTracksGetOrder(const ATrackNumber: Byte): Byte; forward;
procedure CDTracksRead; forward;
procedure CDTracksClear; forward;
procedure CDTracksClearPlayed; forward;
procedure CDTracksSetPlayMode; forward;
procedure CDTracksNormalOrder; forward;
procedure CDTracksShuffleOrder; forward;
procedure CDTracksReverseOrder; forward;
procedure CDTracksSwapOrder(const ASource, ADestination: Byte); forward;
procedure CDTracksSwitch(const ATrackNumber: Byte); forward;

procedure CDStartPlayback; forward;
procedure CDPlayPreviousTrack; forward;
procedure CDPlayTrack; forward;
procedure CDPauseTrack; forward;
procedure CDStopTrack; forward;
procedure CDPlayNextTrack; forward;
procedure CDPlayRandomTrack; forward;
procedure CDQuickPlay(const ATrackNumber: Byte); forward;
procedure CDPlayRemaining; forward;

function CDHasReached(const ACurrent, ATarget: TTimeData): Boolean; forward;
procedure CDPerformStateLogic; forward;

procedure CDPlayerConfigClearPlayMode; forward;
procedure CDPlayerConfigSet; forward;

{ private declarations }

procedure SysTimerInit;
begin
  IGSysTimerTickCount := 0;
  IGSysTimerTriggers := [];

  SysTimerInterruptHook(SysTimerCallback);
end;

procedure SysTimerCallback;
begin
  Inc(IGSysTimerTickCount);

  Include(IGSysTimerTriggers, stt50ms);

  if IGSysTimerTickCount in kQuarterSecondMarkers then
  begin
    Include(IGSysTimerTriggers, stt250ms);
  end;

  if IGSysTimerTickCount in kHalfSecondMarkers then
  begin
    Include(IGSysTimerTriggers, stt500ms);
  end;

  if IGSysTimerTickCount >= kFullSecondMarker then
  begin
    IGSysTimerTickCount := 0;

    Include(IGSysTimerTriggers, stt1000ms);
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
  IGTrackProgressBar.Max := kCDPlayerProgressBarMaxDef;
  IGTrackProgressBar.Progress := kCDPlayerProgressBarMin;
  IGTrackProgressBar.Title := sCDPlayerTrackProgress;

  IGDiscProgressBar.PositionX := kCDPlayerProgressBarX;
  IGDiscProgressBar.PositionY := kCDPlayerDiscProgressY;
  IGDiscProgressBar.Width := kCDPlayerProgressBarWidth;
  IGDiscProgressBar.Colors.Foreground := clCDPlayerProgressFore;
  IGDiscProgressBar.Colors.Background := clCDPlayerProgressBack;
  IGDiscProgressBar.Colors.Title := clCDPlayerProgressTitle;
  IGDiscProgressBar.Colors.Progress := clCDPlayerProgressColor;
  IGDiscProgressBar.DrawMode := dmRepaint;
  IGDiscProgressBar.Min := kCDPlayerProgressBarMin;
  IGDiscProgressBar.Max := kCDPlayerProgressBarMaxDef;
  IGDiscProgressBar.Progress := kCDPlayerProgressBarMin;
  IGDiscProgressBar.Title := sCDPlayerDiscProgress;

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
  ScreenProgressBarDraw(IGDiscProgressBar);

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
    kCDPlayerCDEXDriverVersionX,
    kCDPlayerCDEXDriverVersionY,
    sCDPlayerCDEXDriverVersion +
      IfThenElse(
        LCDEXVersion = 0,
        sNA,
        IntToStr(Hi(LCDEXVersion)) + cFullStop + IntToStr(Lo(LCDEXVersion))
      ) +
      sCDPlayerDriveTypeSeparator + sCDPlayerCDROMDriveType[CDROMProbeSCSI],
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

    if stt50ms in IGSysTimerTriggers then
    begin
      Exclude(IGSysTimerTriggers, stt50ms);

      CDUpdateAudioQChannel;
      CDPerformStateLogic;
    end;

    if stt250ms in IGSysTimerTriggers then
    begin
      Exclude(IGSysTimerTriggers, stt250ms);

      UIUpdateDoorDisc;
      UIUpdateStatus;
    end;

    if stt500ms in IGSysTimerTriggers then
    begin
      Exclude(IGSysTimerTriggers, stt500ms);

      UIUpdateControlLEDs;
    end;

    if stt1000ms in IGSysTimerTriggers then
    begin
      Exclude(IGSysTimerTriggers, stt1000ms);

      UIUpdateAudioQChannel;
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
  UISetDrawValue(kCDPlayerKVDisc, sCDPlayerDisc[IGCDPlayer.Disc]);
  UISetDrawValue(kCDPlayerKVStatus, StrPas(sCDPlayerStatuses[IGCDPlayer.Status]));
  UISetDrawValue(kCDPlayerKVTrack, IntToStr(IGCDPlayer.Tracks.Index));
  UISetDrawValue(kCDPlayerKVTotalTracks, IntToStr(IGCDPlayer.AudioDisc.HighestTrackNumber));
  UISetDrawValue(kCDPlayerKVTrackTime, CDROMFormatTime(IGCDPlayer.Time.Track));
  UISetDrawValue(kCDPlayerKVTrackPlayTime, CDROMFormatTime(IGCDPlayer.Time.TrackPlay));
  UISetDrawValue(kCDPlayerKVDiscTime, CDROMFormatTime(IGCDPlayer.Time.Disc));
  UISetDrawValue(kCDPlayerKVDiscPlayTime, CDROMFormatTime(IGCDPlayer.Time.DiscPlay));
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
        UIUpdateLEDs(False, False, IGCDPlayer.Disc);

        Exit;
      end;

    cdpsPlay:
      UIUpdateLEDs(IGCDPlayer.Control.LED, False, False);

    cdpsPause:
      UIUpdateLEDs(True, IGCDPlayer.Control.LED, False);

  end;

  IGCDPlayer.Control.LED := not IGCDPlayer.Control.LED;
end;

procedure UIUpdateDoorDisc;
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

      IGCDPlayer.Disc := IGCDPlayer.Door.Closed and CDROMDriveReady(LStatus);
      UISetDrawValue(kCDPlayerKVDisc, sCDPlayerDisc[IGCDPlayer.Door.Closed]);

      if IGCDPlayer.Control.OldDisc <> IGCDPlayer.Disc then
      begin
        CDLoadUnload;

        IGCDPlayer.Control.OldDisc := IGCDPlayer.Door.Closed;
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

procedure UIUpdateAudioQChannel;
var
  LTrackSeconds: Word;
  LDiscSeconds: Word;

begin
  if IGCDPlayer.Disc then
  begin
    LTrackSeconds := CDROMTimeToSeconds(IGCDPlayer.Time.Track);
    LDiscSeconds := CDROMTimeToSeconds(IGCDPlayer.Time.Disc);

    if IGCDPlayer.Status = cdpsStop then
    begin
      IGCDPlayer.Time.Track.Value := 0;

      UIResetTrackProgressBar;
      ScreenProgressBarSetProgress(IGDiscProgressBar,
        LDiscSeconds - LTrackSeconds + kSecondsLeadInPreGap);
    end else
    begin
      ScreenProgressBarSetProgress(IGTrackProgressBar, LTrackSeconds);
      ScreenProgressBarSetProgress(IGDiscProgressBar, LDiscSeconds);
    end;

    UISetDrawValue(kCDPlayerKVTrackTime, CDROMFormatTime(IGCDPlayer.Time.Track));
    UISetDrawValue(kCDPlayerKVDiscTime, CDROMFormatTime(IGCDPlayer.Time.Disc));
  end;
end;

procedure UIResetTrackProgressBar;
begin
  ScreenProgressBarReset(IGTrackProgressBar, kCDPlayerProgressBarMin);
end;

procedure UIResetDiscProgressBar;
begin
  ScreenProgressBarReset(IGDiscProgressBar, kCDPlayerProgressBarMin);
end;

procedure UIUpdateAllResetProgressBars;
begin
  UIUpdateAll;

  UIResetTrackProgressBar;
  UIResetDiscProgressBar;
end;

procedure UITracksOrderDisplay;
var
  LIndex: Byte;
  LPositionX: Byte;
  LPositionY: Byte;
  LForeground: Byte;
  LString: String[kCDPlayerTrackOrderStrLen];

begin
  if IGCDPlayer.AudioDisc.HighestTrackNumber > 0 then
  begin
    LPositionY := Succ(IGTrackOrderFramedArea.PositionY);

    for LIndex := IGCDPlayer.AudioDisc.LowestTrackNumber to IGCDPlayer.AudioDisc.HighestTrackNumber do
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

      if LIndex = IGCDPlayer.Tracks.Index then
      begin
        LForeground := clCDPlayerTrackOrderCurrent;
      end else
      begin
        LForeground := clCDPlayerTrackOrderPlayed[
          IGCDPlayer.Tracks.Data^[
            IGCDPlayer.Tracks.Data^[
              LIndex
            ].Order
          ].Played
        ];
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

procedure CDUpdateAudioQChannel;
var
  LAudioQChannel: TAudioQChannel;
  LTrackNumber: Byte;

begin
  if IGCDPlayer.Disc and CDSucceeded(CDROMGetAudioQChannelInfo(LAudioQChannel)) then
  begin
    LTrackNumber := LAudioQChannel.TrackNumber;

    if LTrackNumber = 0 then
    begin
      LTrackNumber := IGCDPlayer.AudioDisc.HighestTrackNumber;
    end;

    if IGCDPlayer.Tracks.Index <> CDTracksGetOrder(LTrackNumber) then
    begin
      CDTracksSwitch(LTrackNumber);
    end;

    IGCDPlayer.Time.Track := LAudioQChannel.TrackTime;
    IGCDPlayer.Time.Disc := LAudioQChannel.DiscTime;
  end else
  begin
    IGCDPlayer.Time.Track.Value := 0;
    IGCDPlayer.Time.Disc.Value := 0;
  end;
end;

procedure CDLoadUnload;
begin
  if IGCDPlayer.Disc then
  begin
    CDLoad;
  end else
  begin
    CDUnload;
  end;
end;

procedure CDLoad;
var
  LPlayIndex: Byte;

begin
  if CDSucceeded(CDROMGetAudioDiscInfo(IGCDPlayer.AudioDisc)) then
  begin
    FillChar(IGCDPlayer.Time, SizeOf(TCDPlayerTime), $00);
    IGCDPlayer.Time.DiscPlay.Value := IGCDPlayer.AudioDisc.LeadOutTrackSector;

    CDTracksRead;
    CDTracksSetPlayMode;

    if IGCDPlayer.Control.WasReset then
    begin
      LPlayIndex := IGCDPlayer.AudioDisc.HighestTrackNumber;
    end else
    begin
      LPlayIndex := IGCDPlayer.Tracks.Data^[IGCDPlayer.Tracks.Index].Order;
    end;

    IGDiscProgressBar.Max := CDROMTimeToSeconds(IGCDPlayer.Time.DiscPlay);

    UIUpdateAllResetProgressBars;

    CDTracksSwitch(LPlayIndex);
  end;
end;

procedure CDUnload;
begin
  CDStopTrack;

  CDPlayerReset;

  IGTrackProgressBar.Max := kCDPlayerProgressBarMaxDef;
  IGDiscProgressBar.Max := kCDPlayerProgressBarMaxDef;

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
  CDUnload;

  if CDSucceeded(CDROMResetDrive) then
  begin
    IGCDPlayer.Control.WasReset := True;

    CDLoad;
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
      if CDSucceeded(CDROMEjectDisc) then
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
  for LIndex := IGCDPlayer.AudioDisc.LowestTrackNumber to IGCDPlayer.AudioDisc.HighestTrackNumber do
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
  GetMem(IGCDPlayer.Tracks.Data, IGCDPlayer.AudioDisc.HighestTrackNumber * SizeOf(TAudioTrack));

  for LIndex := IGCDPlayer.AudioDisc.LowestTrackNumber to IGCDPlayer.AudioDisc.HighestTrackNumber do
  begin
    IGCDPlayer.Tracks.Data^[LIndex].Number := LIndex;
    IGCDPlayer.Tracks.Data^[LIndex].Order := LIndex;
    IGCDPlayer.Tracks.Data^[LIndex].Played := False;

    CDSucceeded(CDROMGetAudioTrackInfo(IGCDPlayer.AudioDisc, IGCDPlayer.Tracks.Data^[LIndex]));
  end;
end;

procedure CDTracksClear;
var
  LSizeOf: Word;

begin
  if IGCDPlayer.Disc and (IGCDPlayer.Tracks.Data <> nil) then
  begin
    LSizeOf := IGCDPlayer.AudioDisc.HighestTrackNumber * SizeOf(TAudioTrack);

    FillChar(IGCDPlayer.Tracks.Data^, LSizeOf, $00);
    FreeMem(IGCDPlayer.Tracks.Data, LSizeOf);

    FillChar(IGCDPlayer.Tracks, SizeOf(TAudioTracks), $00);
  end;
end;

procedure CDTracksClearPlayed;
var
  LIndex: Byte;

begin
  for LIndex := IGCDPlayer.AudioDisc.LowestTrackNumber to IGCDPlayer.AudioDisc.HighestTrackNumber do
  begin
    IGCDPlayer.Tracks.Data^[LIndex].Played := False;
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
end;

procedure CDTracksNormalOrder;
var
  LIndex: Byte;

begin
  for LIndex := IGCDPlayer.AudioDisc.LowestTrackNumber to IGCDPlayer.AudioDisc.HighestTrackNumber do
  begin
    IGCDPlayer.Tracks.Data^[LIndex].Order := LIndex;
  end;
end;

procedure CDTracksShuffleOrder;
var
  LIndex: Byte;

begin
  Randomize;

  for LIndex := IGCDPlayer.AudioDisc.HighestTrackNumber downto Succ(IGCDPlayer.AudioDisc.LowestTrackNumber) do
  begin
    CDTracksSwapOrder(LIndex, Succ(Random(LIndex)));
  end;
end;

procedure CDTracksReverseOrder;
var
  LIndex: Byte;

begin
  for LIndex := IGCDPlayer.AudioDisc.LowestTrackNumber to IGCDPlayer.AudioDisc.HighestTrackNumber div 2 do
  begin
    CDTracksSwapOrder(LIndex, Succ(IGCDPlayer.AudioDisc.HighestTrackNumber - LIndex));
  end;
end;

procedure CDTracksSwapOrder(const ASource, ADestination: Byte);
var
  LOrder: Byte;

begin
  LOrder := IGCDPlayer.Tracks.Data^[ASource].Order;

  IGCDPlayer.Tracks.Data^[ASource].Order :=
    IGCDPlayer.Tracks.Data^[ADestination].Order;

  IGCDPlayer.Tracks.Data^[ADestination].Order := LOrder;
end;

procedure CDTracksSwitch(const ATrackNumber: Byte);
begin
  IGCDPlayer.Tracks.Index := CDTracksGetOrder(ATrackNumber);

  IGCDPlayer.Time.Track.Value := 0;
  CDROMGetTrackPlayTime(IGCDPlayer.Tracks.Data^[ATrackNumber], IGCDPlayer.Time.TrackPlay);

  IGTrackProgressBar.Max :=
    CDROMTimeToSeconds(IGCDPlayer.Time.TrackPlay) - kSecondsLeadInPreGap;

  UISetDrawValue(kCDPlayerKVTrack, IntToStr(ATrackNumber));
  UISetDrawValue(kCDPlayerKVTrackPlayTime, CDROMFormatTime(IGCDPlayer.Time.TrackPlay));

  UITracksOrderDisplay;

  UIResetTrackProgressBar;
end;

procedure CDStartPlayback;
var
  LPlayIndex: Byte;

begin
  if IGCDPlayer.Disc then
  begin
    CDStopTrack;

    LPlayIndex := IGCDPlayer.Tracks.Data^[IGCDPlayer.Tracks.Index].Order;

    CDTracksSwitch(LPlayIndex);

    if IGCDPlayer.Tracks.Data^[LPlayIndex].Data then
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
      if CDSucceeded(CDROMPlayAudio(IGCDPlayer.Tracks.Data^[LPlayIndex])) then
      begin
        IGCDPlayer.Control.Play := True;
        IGCDPlayer.Control.Pause := False;
        IGCDPlayer.Control.LED := True;

        IGCDPlayer.Tracks.Data^[LPlayIndex].Played := True;
      end;
    end;
  end;
end;

procedure CDPlayPreviousTrack;
begin
  if IGCDPlayer.Disc then
  begin
    if IGCDPlayer.Tracks.Index = IGCDPlayer.AudioDisc.LowestTrackNumber then
    begin
      IGCDPlayer.Tracks.Index := IGCDPlayer.AudioDisc.HighestTrackNumber;
    end else
    begin
      Dec(IGCDPlayer.Tracks.Index);
    end;

    CDStartPlayback;
  end;
end;

procedure CDPlayTrack;
begin
  if IGCDPlayer.Control.WasReset then
  begin
    IGCDPlayer.Tracks.Index := IGCDPlayer.AudioDisc.LowestTrackNumber;

    IGCDPlayer.Control.WasReset := False;
  end;

  CDStartPlayback;
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
  if IGCDPlayer.Disc then
  begin
    if IGCDPlayer.Tracks.Index = IGCDPlayer.AudioDisc.HighestTrackNumber then
    begin
      IGCDPlayer.Tracks.Index := IGCDPlayer.AudioDisc.LowestTrackNumber;
    end else
    begin
      Inc(IGCDPlayer.Tracks.Index);
    end;

    CDStartPlayback;
  end;
end;

procedure CDPlayRandomTrack;
begin
  if IGCDPlayer.Disc then
  begin
    Randomize;

    IGCDPlayer.Tracks.Index := CDTracksGetOrder(
      Random(
        Succ(
          IGCDPlayer.AudioDisc.HighestTrackNumber -
          IGCDPlayer.AudioDisc.LowestTrackNumber
        )
      ) + IGCDPlayer.AudioDisc.LowestTrackNumber
    );

    CDStartPlayback;
  end;
end;

procedure CDQuickPlay(const ATrackNumber: Byte);
begin
  if IGCDPlayer.Disc and
    (ATrackNumber >= IGCDPlayer.AudioDisc.LowestTrackNumber) and
    (ATrackNumber <= IGCDPlayer.AudioDisc.HighestTrackNumber) then
  begin
    IGCDPlayer.Tracks.Index := CDTracksGetOrder(ATrackNumber);

    CDStartPlayback;
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
    LAudioTrack.StartSector := LAudioQChannel.DiscTime.Value;
    LAudioTrack.SectorCount := CDROMTimeToLBA(IGCDPlayer.AudioDisc.LeadOutTrackSector) -
      CDROMTimeToLBA(LAudioTrack.StartSector);

    CDSucceeded(CDROMStopAudio);
    CDSucceeded(CDROMPlayAudio(LAudioTrack));
  end;
end;

function CDHasReached(const ACurrent, ATarget: TTimeData): Boolean;
begin
  CDHasReached :=
    ACurrent.Minutes * kSecondsPerMinute +
    ACurrent.Seconds + kSecondsLeadInPreGap +
    CDROMFramesToSeconds(ACurrent.Frames) >=
    ATarget.Minutes * kSecondsPerMinute +
    ATarget.Seconds +
    CDROMFramesToSeconds(ATarget.Frames);
end;

procedure CDPerformStateLogic;
begin
  if IGCDPlayer.Disc and CDHasReached(IGCDPlayer.Time.Track, IGCDPlayer.Time.TrackPlay) then
  begin
    if IGCDPlayerOptions[cdpRepeatTrack].Enabled then
    begin
      CDStartPlayback;
    end else
    if IGCDPlayer.Tracks.Index = IGCDPlayer.AudioDisc.HighestTrackNumber then
    begin
      CDTracksClearPlayed;

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
begin
  CDPlayerReset;

  SysTimerInit;

  UIDraw;
  UILoop;

  SysTimerInterruptRelease;

  CDPlayerConfigSet;

  CDPlayerStart := IGCDPlayerConfigChanged;
end;

end.
