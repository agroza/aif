{ --------------------------------------------------------------------------- }
{ - Audio Interface - CD-ROM Support (cdrom.pas)                            - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$I cdefines.inc}

{$IFDEF CPU16BIT}
  {$G+}
{$ENDIF}

unit CDROM;

interface

type
  TCDROMData = packed record
    DriveCount: Byte;
    FirstDriveLetter: Char;
    CurrentDriveLetter: Char;
  end;

  TDeviceStatus = packed record
    DoorOpen: Boolean;
    DoorUnlocked: Boolean;
    CoockedAndRawReading: Boolean;
    ReadWrite: Boolean;
    DataAudioVideo: Boolean;
    Interleaving: Boolean;
    Prefetching: Boolean;
    ChannelManipulation: Boolean;
    HSGRedBookAddressing: Boolean;
  end;

  TAudioDisk = packed record
    LowestTrackNumber: Byte;
    HighestTrackNumber: Byte;
    LeadOutTrackSector: Longint;
  end;

  TAudioTrack = packed record
    Number: Byte;
    Order: Byte;
    Data: Boolean;
    StartSector: Longint;
    SectorCount: Longint;
  end;

  TTimeData = packed record
    case Boolean of
      True: (
        Frames: Byte;
        Seconds: Byte;
        Minutes: Byte;
        Reserved: Byte;
      );
      False: (
        Value: Longint;
      )
  end;

  TAudioQChannel = packed record
    TrackNumber: Byte;
    PointIndex: Byte;
    TrackTime: TTimeData;
    DiskTime: TTimeData;
  end;

  TAudioStatus = packed record
    Paused: Boolean;
    StartingLocation: Longint;
    EndingLocation: Longint;
  end;

var
  GCDROMData: TCDROMData;

function CDROMIsInit: Boolean;
procedure CDROMInitData;

function CDROMGetError(const AErrorCode: Byte): PChar;
function CDROMSucceeded(const AStatus: Word; var AErrorCode: Byte): Boolean;
function CDROMBusy(const AStatus: Word): Boolean;
function CDROMDriveReady(const AStatus: Word): Boolean;

function CDROMProbeSCSI: Boolean;

function CDROMDetectCDEX: Boolean;
function CDROMGetData(var ADriveCount: Byte; var AFirstDriveLetter: Char): Boolean;
function CDROMDriveCheck(const ADriveLetter: Char): Boolean;
function CDROMGetCDEXVersion: Word;

function CDROMGetDeviceStatus(var ADeviceStatus: TDeviceStatus): Word;

function CDROMGetAudioDiskInfo(var AAudioDisk: TAudioDisk): Word;
function CDROMGetAudioTrackInfo(const AAudioDisk: TAudioDisk; var AAudioTrack: TAudioTrack): Word;
function CDROMGetAudioQChannelInfo(var AAudioQChannel: TAudioQChannel): Word;
function CDROMGetAudioStatusInfo(var AAudioStatus: TAudioStatus): Word;

function CDROMEjectDisk: Word;
function CDROMLockUnlock(const ALock: Boolean): Word;
function CDROMResetDrive: Word;
function CDROMCloseTray: Word;

function CDROMPlayAudio(const AAudioTrack: TAudioTrack): Word;
function CDROMStopAudio: Word;
function CDROMResumeAudio: Word;

function CDROMTimeToLBA(const AValue: Longint): Longint;
function CDROMTimeToSeconds(const ATimeData: TTimeData): Word;
function CDROMFramesToSeconds(const AValue: Byte): Byte;
function CDROMFormatTime(const ATimeData: TTimeData): String;
procedure CDROMGetTrackPlayTime(const AAudioTrack: TAudioTrack; var ATimeData: TTimeData);

implementation

uses
  Consts,
  Routines;

type
  TRequestHeader = packed record
    Length: Byte;
    Subunit: Byte;
    Command: Byte;
    Status: Word;
    Reserved: packed array[1..8] of Byte;
  end;

  TIOCTLInputRequest = packed record
    Header: TRequestHeader;
    MediaDescriptor: Byte;
    TransferAddressOffset: Word;
    TransferAddressSegment: Word;
    ByteCount: Word;
    StartSector: Word;
    VolumeID: Longint;
  end;

  TIOCTLOutputRequest = packed record
    Header: TRequestHeader;
    MediaDescriptor: Byte;
    TransferAddressOffset: Word;
    TransferAddressSegment: Word;
    ByteCount: Word;
    StartSector: Word;
    VolumeID: Longint;
  end;

  TPlayAudioRequest = packed record
    Header: TRequestHeader;
    AddressingMode: Byte;
    StartSector: Longint;
    SectorCount: Longint;
  end;

  TStopAudioRequest = packed record
    Header: TRequestHeader;
  end;

  TResumeAudioRequest = packed record
    Header: TRequestHeader;
  end;

  TDeviceStatusCtlBlock = packed record
    Command: Byte;
    DevStat: Longint;
  end;

  TAudioDiskInfoCtlBlock = packed record
    Command: Byte;
    LowestTrackNumber: Byte;
    HighestTrackNumber: Byte;
    LeadOutTrackSector: Longint;
  end;

  TAudioTrackInfoCtlBlock = packed record
    Command: Byte;
    Number: Byte;
    StartSector: Longint;
    Control: Byte;
  end;

  TAudioQChannelInfoCtlBlock = packed record
    Command: Byte;
    ControlADR: Byte;
    TrackNumber: Byte;
    PointIndex: Byte;
    TrackMinutes: Byte;
    TrackSeconds: Byte;
    TrackFrames: Byte;
    Reserved: Byte;
    DiskMinutes: Byte;
    DiskSeconds: Byte;
    DiskFrames: Byte;
  end;

  TAudioStatusInfoCtlBlock = packed record
    Command: Byte;
    Status: Word;
    StartingLocationLastPlay: Longint;
    EndingLocationLastPlay: Longint;
  end;

  TIOCTLOutputCtlBlock = packed record
    Command: Byte;
    Lock: Byte;
  end;

const
  kSecondsPerDay               = 86400;
  kSecondsPerHour              = 3600;
  kSecondsPerMinute            = 60;
  kSectorsPerSecond            = 75;
  kSectorsLeadInPreGap         = 150;

  kRedBookAddressingMode       = 1;

  { device driver commands }
  kDDCMD_IOCTL_INPUT           = 3;
  kDDCMD_IOCTL_OUTPUT          = 12;
  kDDCMD_PLAY_AUDIO            = 132;
  kDDCMD_STOP_AUDIO            = 133;
  kDDCMD_RESUME_AUDIO          = 136;

  { input control block commands }
  kICBCMD_DEVICE_STATUS        = 6;
  kICBCMD_AUDIO_DISK_INFO      = 10;
  kICBCMD_AUDIO_TRACK_INFO     = 11;
  kICBCMD_AUDIO_Q_CHANNEL_INFO = 12;
  kICBCMD_AUDIO_STATUS         = 15;

  { input control block command transfer bytes count }
  kICBTBC_DEVICE_STATUS        = 5;
  kICBTBC_AUDIO_DISK_INFO      = 7;
  kICBTBC_AUDIO_TRACK_INFO     = 7;
  kICBTBC_AUDIO_Q_CHANNEL_INFO = 11;
  kICBTBC_AUDIO_STATUS         = 11;

  { output control block commands }
  kOCBCMD_EJECT_DISK           = 0;
  kOCBCMD_LOCK_UNLOCK_DOOR     = 1;
  kOCBCMD_RESET_DRIVE          = 2;
  kOCBCMD_CLOSE_TRAY           = 5;

  { output control block command transfer bytes count }
  kOCBTBC_EJECT_DISK           = 1;
  kOCBTBC_LOCK_UNLOCK_DOOR     = 2;
  kOCBTBC_RESET_DRIVE          = 1;
  kOCBTBC_CLOSE_TRAY           = 1;

  { status word bits }
  kSWB_DONE                    = 8;
  kSWB_BUSY                    = 9;
  kSWB_ERROR                   = 15;

  { device status bits }
  kDSB_DOOR_CLOSED             = 0;
  kDSB_DOOR_LOCKED             = 1;
  kDSB_COOKED_RAW_READING      = 2;
  kDSB_READ_MODE               = 3;
  kDSB_DATA_READ_MODE          = 4;
  kDSB_INTERLEAVING            = 5;
  kDSB_RESERVED                = 6;
  kDSB_PREFETCHING             = 7;
  kDSB_CHANNEL_MANIPULATION    = 8;
  kDSB_ADDRESSING_MODE         = 9;

  { audio status bits }
  kASB_AUDIO_PAUSED            = 0;

  { status error codes }
  kERR_WRITE_PROTECT_VIOLATION = 0;
  kERR_UNKNOWN_UNIT            = 1;
  kERR_DRIVE_NOT_READY         = 2;
  kERR_UNKNOWN_COMMAND         = 3;
  kERR_CRC_ERROR               = 4;
  kERR_BAD_REQUEST_LENGTH      = 5;
  kERR_SEEK_ERROR              = 6;
  kERR_UNKNOWN_MEDIA           = 7;
  kERR_SECTOR_NOT_FOUND        = 8;
  kERR_RESERVED1               = 9;
  kERR_WRITE_FAULT             = 10;
  kERR_READ_FAULT              = 11;
  kERR_GENERAL_FAILURE         = 12;
  kERR_RESERVED2               = 13;
  kERR_RESERVED3               = 14;
  kERR_INVALID_DISK_CHANGE     = 15;
  kERR_UNKNOWN_ERROR           = 16;

  kErrorCodeTexts: packed array[kERR_WRITE_PROTECT_VIOLATION..kERR_UNKNOWN_ERROR] of PChar = (
    sCDROMWriteProtect,
    sCDROMUnknownUnit,
    sCDROMDriveNotReady,
    sCDROMUnknownCommand,
    sCDROMCRCError,
    sCDROMBadRequestLength,
    sCDROMSeekError,
    sCDROMUnknownMedia,
    sCDROMSectorNotFound,
    sCDROMReserved,
    sCDROMWriteFault,
    sCDROMReadFault,
    sCDROMGeneralFailure,
    sCDROMReserved,
    sCDROMReserved,
    sCDROMInvalidDiskChange,
    sCDROMUnknownError
  );

function BCDToDecimal(const AValue: Byte): Byte; forward;

procedure CDROMSendDeviceRequest(const ADrive: Char; var ARequestHeader); forward;

procedure CDROMSendInputRequest(var AIOCTLInputRequest: TIOCTLInputRequest;
  var ACtlBlock; const AByteCount: Byte); forward;
function CDROMSendOutputRequest(const ACommand, AByteCount: Byte;
  const ALock: Boolean): Word; forward;

{ private declarations }

function BCDToDecimal(const AValue: Byte): Byte; assembler;
asm
  mov al, AValue
  mov cl, 04h
  shr al, cl

  mov cl, 10
  mul cl

  add al, AValue
  and al, 0Fh
end;

procedure CDROMSendDeviceRequest(const ADrive: Char; var ARequestHeader); assembler;
asm
  mov ax, 1510h
  les bx, [ARequestHeader]
  xor ch, ch
  mov cl, ADrive
  sub cl, 41h
  int 2Fh
end;

procedure CDROMSendInputRequest(var AIOCTLInputRequest: TIOCTLInputRequest;
  var ACtlBlock; const AByteCount: Byte);
begin
  AIOCTLInputRequest.Header.Length := SizeOf(TIOCTLInputRequest);
  AIOCTLInputRequest.Header.Subunit := 0;
  AIOCTLInputRequest.Header.Command := kDDCMD_IOCTL_INPUT;
  AIOCTLInputRequest.MediaDescriptor := 0;
  AIOCTLInputRequest.TransferAddressOffset := Ofs(ACtlBlock);
  AIOCTLInputRequest.TransferAddressSegment := Seg(ACtlBlock);
  AIOCTLInputRequest.ByteCount := AByteCount;
  AIOCTLInputRequest.StartSector := 0;
  AIOCTLInputRequest.VolumeID := 0;

  CDROMSendDeviceRequest(GCDROMData.CurrentDriveLetter, AIOCTLInputRequest);
end;

function CDROMSendOutputRequest(const ACommand, AByteCount: Byte;
  const ALock: Boolean): Word;
var
  LIOCTLOutput: TIOCTLOutputCtlBlock;
  LIOCTLOutputRequest: TIOCTLOutputRequest;

begin
  LIOCTLOutput.Command := ACommand;
  LIOCTLOutput.Lock := Ord(ALock);

  LIOCTLOutputRequest.Header.Length := SizeOf(TIOCTLOutputRequest);
  LIOCTLOutputRequest.Header.Subunit := 0;
  LIOCTLOutputRequest.Header.Command := kDDCMD_IOCTL_OUTPUT;
  LIOCTLOutputRequest.MediaDescriptor := 0;
  LIOCTLOutputRequest.TransferAddressOffset := Ofs(LIOCTLOutput);
  LIOCTLOutputRequest.TransferAddressSegment := Seg(LIOCTLOutput);
  LIOCTLOutputRequest.ByteCount := AByteCount;
  LIOCTLOutputRequest.StartSector := 0;
  LIOCTLOutputRequest.VolumeID := 0;

  CDROMSendDeviceRequest(GCDROMData.CurrentDriveLetter, LIOCTLOutputRequest);

  CDROMSendOutputRequest := LIOCTLOutputRequest.Header.Status;
end;

{ public declarations }

function CDROMIsInit: Boolean;
begin
  CDROMIsInit := GCDROMData.FirstDriveLetter <> #0;
end;

procedure CDROMInitData;
begin
  FillChar(GCDROMData, SizeOf(TCDROMData), $00);

  CDROMGetData(GCDROMData.DriveCount, GCDROMData.FirstDriveLetter);
  GCDROMData.CurrentDriveLetter := GCDROMData.FirstDriveLetter;
end;

function CDROMGetError(const AErrorCode: Byte): PChar;
begin
  if AErrorCode <= kERR_INVALID_DISK_CHANGE then
  begin
    CDROMGetError := kErrorCodeTexts[AErrorCode];
  end else
  begin
    CDROMGetError := kErrorCodeTexts[kERR_UNKNOWN_ERROR];
  end;
end;

function CDROMSucceeded(const AStatus: Word; var AErrorCode: Byte): Boolean;
begin
  if (AStatus shr kSWB_ERROR) and 1 = 1 then
  begin
    AErrorCode := Lo(AStatus);

    CDROMSucceeded := False;
  end else
  begin
    CDROMSucceeded := True;
  end;
end;

function CDROMBusy(const AStatus: Word): Boolean;
begin
  CDROMBusy := (AStatus shr kSWB_BUSY) and 1 = 1;
end;

function CDROMDriveReady(const AStatus: Word): Boolean;
var
  LError: Byte;

begin
  if (AStatus shr kSWB_ERROR) and 1 = 1 then
  begin
    LError := Lo(AStatus);

    CDROMDriveReady :=
      (LError <> kERR_DRIVE_NOT_READY) and (LError <> kERR_GENERAL_FAILURE);
  end else
  begin
    CDROMDriveReady := True;
  end;
end;

function CDROMProbeSCSI: Boolean; assembler;
asm
  push ds

  mov ax, seg @Code
  mov ds, ax

  mov ax, 3D00h
  lea dx, @SCSIMGR
  int 21h

  jc @aspiNotInstalled

  xchg ax, bx

  mov ax, 3E00h
  int 21h

  mov al, True
  jmp @exit

@SCSIMGR:
  db 'SCSIMGR$',0

@aspiNotInstalled:
  xor ax, ax

@exit:
  pop ds
end;

function CDROMDetectCDEX: Boolean; assembler;
asm
  mov ax, 1500h
  xor bx, bx
  int 2Fh

  or bx, bx
  jz @notInstalled

  mov al, True
  jmp @exit

@notInstalled:
  xor ax, ax

@exit:

end;

function CDROMGetData(var ADriveCount: Byte; var AFirstDriveLetter: Char): Boolean; assembler;
asm
  mov ax, 1500h
  xor bx, bx
  int 2Fh

  or bx, bx
  jz @notInstalled

  mov ax, bx

  les bx, [ADriveCount]
  mov byte ptr es:[bx], al

  add cl, 41h
  les bx, [AFirstDriveLetter]
  mov byte ptr es:[bx], cl

  mov al, True
  jmp @exit

@notInstalled:
  xor ax, ax

@exit:

end;

function CDROMDriveCheck(const ADriveLetter: Char): Boolean; assembler;
asm
  mov ax, 150Bh
  xor ch, ch
  mov cl, ADriveLetter
  sub cl, 41h
  int 2Fh

  cmp bx, 0ADADh
  jne @notInstalled

  jmp @exit

@notInstalled:
  xor ax, ax

@exit:

end;

function CDROMGetCDEXVersion: Word; assembler;
asm
  mov ax, 150Ch
  xor bx, bx
  int 2Fh

  mov ax, bx
end;

function CDROMGetDeviceStatus(var ADeviceStatus: TDeviceStatus): Word;
var
  LIOCTLInputRequest: TIOCTLInputRequest;
  LDeviceStatusCtlBlock: TDeviceStatusCtlBlock;

begin
  LDeviceStatusCtlBlock.Command := kICBCMD_DEVICE_STATUS;

  CDROMSendInputRequest(
    LIOCTLInputRequest,
    LDeviceStatusCtlBlock,
    kICBTBC_DEVICE_STATUS
  );

  ADeviceStatus.DoorOpen := (LDeviceStatusCtlBlock.DevStat shr kDSB_DOOR_CLOSED) and 1 = 1;
  ADeviceStatus.DoorUnlocked := (LDeviceStatusCtlBlock.DevStat shr kDSB_DOOR_LOCKED) and 1 = 1;
  ADeviceStatus.CoockedAndRawReading := (LDeviceStatusCtlBlock.DevStat shr kDSB_COOKED_RAW_READING) and 1 = 1;
  ADeviceStatus.ReadWrite := (LDeviceStatusCtlBlock.DevStat shr kDSB_READ_MODE) and 1 = 1;
  ADeviceStatus.DataAudioVideo := (LDeviceStatusCtlBlock.DevStat shr kDSB_DATA_READ_MODE) and 1 = 1;
  ADeviceStatus.Interleaving := (LDeviceStatusCtlBlock.DevStat shr kDSB_INTERLEAVING) and 1 = 1;
  ADeviceStatus.Prefetching := (LDeviceStatusCtlBlock.DevStat shr kDSB_PREFETCHING) and 1 = 1;
  ADeviceStatus.ChannelManipulation := (LDeviceStatusCtlBlock.DevStat shr kDSB_CHANNEL_MANIPULATION) and 1 = 1;
  ADeviceStatus.HSGRedBookAddressing := (LDeviceStatusCtlBlock.DevStat shr kDSB_ADDRESSING_MODE) and 1 = 1;

  CDROMGetDeviceStatus := LIOCTLInputRequest.Header.Status;
end;

function CDROMGetAudioDiskInfo(var AAudioDisk: TAudioDisk): Word;
var
  LIOCTLInputRequest: TIOCTLInputRequest;
  LAudioDiskInfoCtlBlock: TAudioDiskInfoCtlBlock;

begin
  LAudioDiskInfoCtlBlock.Command := kICBCMD_AUDIO_DISK_INFO;

  CDROMSendInputRequest(
    LIOCTLInputRequest,
    LAudioDiskInfoCtlBlock,
    kICBTBC_AUDIO_DISK_INFO
  );

  AAudioDisk.LowestTrackNumber := LAudioDiskInfoCtlBlock.LowestTrackNumber;
  AAudioDisk.HighestTrackNumber := LAudioDiskInfoCtlBlock.HighestTrackNumber;
  AAudioDisk.LeadOutTrackSector := LAudioDiskInfoCtlBlock.LeadOutTrackSector;

  CDROMGetAudioDiskInfo := LIOCTLInputRequest.Header.Status;
end;

function CDROMGetAudioTrackInfo(const AAudioDisk: TAudioDisk; var AAudioTrack: TAudioTrack): Word;
var
  LIOCTLInputRequest: TIOCTLInputRequest;
  LAudioTrackInfoCtlBlock: TAudioTrackInfoCtlBlock;
  LStatus: Word;
  LErrorCode: Byte;
  LEndSector: TTimeData;

begin
  LAudioTrackInfoCtlBlock.Command := kICBCMD_AUDIO_TRACK_INFO;
  LAudioTrackInfoCtlBlock.Number := AAudioTrack.Number;

  CDROMSendInputRequest(
    LIOCTLInputRequest,
    LAudioTrackInfoCtlBlock,
    kICBTBC_AUDIO_TRACK_INFO
  );

  AAudioTrack.Data := LAudioTrackInfoCtlBlock.Control and $40 = $40;
  AAudioTrack.StartSector := LAudioTrackInfoCtlBlock.StartSector;

  LStatus := LIOCTLInputRequest.Header.Status;
  if CDROMSucceeded(LStatus, LErrorCode) then
  begin
    if AAudioTrack.Number = AAudioDisk.HighestTrackNumber then
    begin
      LEndSector.Value := AAudioDisk.LeadOutTrackSector;
    end else
    begin
      LAudioTrackInfoCtlBlock.Number := Succ(AAudioTrack.Number);

      CDROMSendDeviceRequest(
        GCDROMData.CurrentDriveLetter,
        LIOCTLInputRequest
      );

      LStatus := LIOCTLInputRequest.Header.Status;
      if CDROMSucceeded(LStatus, LErrorCode) then
      begin
        LEndSector.Value := LAudioTrackInfoCtlBlock.StartSector;
      end else
      begin
        LEndSector.Value := AAudioDisk.LeadOutTrackSector;
      end;
    end;

    AAudioTrack.SectorCount :=
      CDROMTimeToLBA(LEndSector.Value) -
      CDROMTimeToLBA(AAudioTrack.StartSector)-
      kSectorsLeadInPreGap;
  end;

  CDROMGetAudioTrackInfo := LStatus;
end;

function CDROMGetAudioQChannelInfo(var AAudioQChannel: TAudioQChannel): Word;
var
  LIOCTLInputRequest: TIOCTLInputRequest;
  LAudioQChannelInfoCtlBlock: TAudioQChannelInfoCtlBlock;

begin
  LAudioQChannelInfoCtlBlock.Command := kICBCMD_AUDIO_Q_CHANNEL_INFO;

  CDROMSendInputRequest(
    LIOCTLInputRequest,
    LAudioQChannelInfoCtlBlock,
    kICBTBC_AUDIO_Q_CHANNEL_INFO
  );

  AAudioQChannel.TrackNumber := BCDToDecimal(LAudioQChannelInfoCtlBlock.TrackNumber);
  AAudioQChannel.PointIndex := LAudioQChannelInfoCtlBlock.PointIndex;
  AAudioQChannel.TrackTime.Minutes := LAudioQChannelInfoCtlBlock.TrackMinutes;
  AAudioQChannel.TrackTime.Seconds := LAudioQChannelInfoCtlBlock.TrackSeconds;
  AAudioQChannel.TrackTime.Frames := LAudioQChannelInfoCtlBlock.TrackFrames;
  AAudioQChannel.DiskTime.Minutes := LAudioQChannelInfoCtlBlock.DiskMinutes;
  AAudioQChannel.DiskTime.Seconds := LAudioQChannelInfoCtlBlock.DiskSeconds;
  AAudioQChannel.DiskTime.Frames := LAudioQChannelInfoCtlBlock.DiskFrames;

  CDROMGetAudioQChannelInfo := LIOCTLInputRequest.Header.Status;
end;

function CDROMGetAudioStatusInfo(var AAudioStatus: TAudioStatus): Word;
var
  LIOCTLInputRequest: TIOCTLInputRequest;
  LAudioStatusInfoCtlBlock: TAudioStatusInfoCtlBlock;

begin
  LAudioStatusInfoCtlBlock.Command := kICBCMD_AUDIO_STATUS;

  CDROMSendInputRequest(
    LIOCTLInputRequest,
    LAudioStatusInfoCtlBlock,
    kICBTBC_AUDIO_STATUS
  );

  AAudioStatus.Paused := (LAudioStatusInfoCtlBlock.Status shr kASB_AUDIO_PAUSED) and 1 = 1;
  AAudioStatus.StartingLocation := LAudioStatusInfoCtlBlock.StartingLocationLastPlay;
  AAudioStatus.EndingLocation := LAudioStatusInfoCtlBlock.EndingLocationLastPlay;

  CDROMGetAudioStatusInfo := LIOCTLInputRequest.Header.Status;
end;

function CDROMEjectDisk: Word;
begin
  CDROMEjectDisk := CDROMSendOutputRequest(
    kOCBCMD_EJECT_DISK,
    kOCBTBC_EJECT_DISK,
    False
  );
end;

function CDROMLockUnlock(const ALock: Boolean): Word;
begin
  CDROMLockUnlock := CDROMSendOutputRequest(
    kOCBCMD_LOCK_UNLOCK_DOOR,
    kOCBTBC_LOCK_UNLOCK_DOOR,
    ALock
  );
end;

function CDROMResetDrive: Word;
begin
  CDROMResetDrive := CDROMSendOutputRequest(
    kOCBCMD_RESET_DRIVE,
    kOCBTBC_RESET_DRIVE,
    False
  );
end;

function CDROMCloseTray: Word;
begin
  CDROMCloseTray := CDROMSendOutputRequest(
    kOCBCMD_CLOSE_TRAY,
    kOCBTBC_CLOSE_TRAY,
    False
  );
end;

function CDROMPlayAudio(const AAudioTrack: TAudioTrack): Word;
var
  LPlayAudioRequest: TPlayAudioRequest;

begin
  LPlayAudioRequest.Header.Length := SizeOf(TPlayAudioRequest);
  LPlayAudioRequest.Header.Subunit := 0;
  LPlayAudioRequest.Header.Command := kDDCMD_PLAY_AUDIO;
  LPlayAudioRequest.AddressingMode := kRedBookAddressingMode;
  LPlayAudioRequest.StartSector := AAudioTrack.StartSector;
  LPlayAudioRequest.SectorCount := AAudioTrack.SectorCount;

  CDROMSendDeviceRequest(GCDROMData.CurrentDriveLetter, LPlayAudioRequest);

  CDROMPlayAudio := LPlayAudioRequest.Header.Status;
end;

function CDROMStopAudio: Word;
var
  LStopAudioRequest: TStopAudioRequest;

begin
  LStopAudioRequest.Header.Length := SizeOf(TStopAudioRequest);
  LStopAudioRequest.Header.Subunit := 0;
  LStopAudioRequest.Header.Command := kDDCMD_STOP_AUDIO;

  CDROMSendDeviceRequest(GCDROMData.CurrentDriveLetter, LStopAudioRequest);

  CDROMStopAudio := LStopAudioRequest.Header.Status;
end;

function CDROMResumeAudio: Word;
var
  LResumeAudioRequest: TResumeAudioRequest;

begin
  LResumeAudioRequest.Header.Length := SizeOf(TResumeAudioRequest);
  LResumeAudioRequest.Header.Subunit := 0;
  LResumeAudioRequest.Header.Command := kDDCMD_RESUME_AUDIO;

  CDROMSendDeviceRequest(GCDROMData.CurrentDriveLetter, LResumeAudioRequest);

  CDROMResumeAudio := LResumeAudioRequest.Header.Status;
end;

function CDROMTimeToLBA(const AValue: Longint): Longint;
var
  LTimeData: TTimeData;

begin
  LTimeData.Value := AValue;

  CDROMTimeToLBA := (Longint(LTimeData.Minutes) * kSecondsPerMinute +
    LTimeData.Seconds) * kSectorsPerSecond + LTimeData.Frames - kSectorsLeadInPreGap;
end;

function CDROMTimeToSeconds(const ATimeData: TTimeData): Word;
begin
  CDROMTimeToSeconds :=
    CDROMFramesToSeconds(ATimeData.Frames) +
    ATimeData.Seconds +
    ATimeData.Minutes * kSecondsPerMinute;
end;

function CDROMFramesToSeconds(const AValue: Byte): Byte;
begin
  if AValue >= Succ(kSectorsPerSecond) div 2 then
  begin
    CDROMFramesToSeconds := 1;
  end else
  begin
    CDROMFramesToSeconds := 0;
  end;
end;

function CDROMFormatTime(const ATimeData: TTimeData): String;
const
  kFormatTimeLength = 5;

var
  LFormatTime: String[kFormatTimeLength];

begin
  LFormatTime[0] := Chr(kFormatTimeLength);
  LFormatTime[1] := Chr(ATimeData.Minutes div 10 + $30);
  LFormatTime[2] := Chr(ATimeData.Minutes mod 10 + $30);
  LFormatTime[3] := cSemicolon;
  LFormatTime[4] := Chr(ATimeData.Seconds div 10 + $30);
  LFormatTime[5] := Chr(ATimeData.Seconds mod 10 + $30);

  CDROMFormatTime := LFormatTime;
end;

procedure CDROMGetTrackPlayTime(const AAudioTrack: TAudioTrack; var ATimeData: TTimeData);
begin
  ATimeData.Frames := AAudioTrack.SectorCount mod kSectorsPerSecond;
  ATimeData.Seconds := (AAudioTrack.SectorCount div kSectorsPerSecond) mod kSecondsPerMinute;
  ATimeData.Minutes := AAudioTrack.SectorCount div kSectorsPerSecond div kSecondsPerMinute;
end;

end.
