{ --------------------------------------------------------------------------- }
{ - Audio Interface - MPU Interface (mpu.pas)                               - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - Portions Copyright (C) 2000 Jan Knipperts                               - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$I cdefines.inc}

{$IFDEF CPU16BIT}
  {$G+}
{$ENDIF}

unit MPU;

interface

type
  TMPUResetMode = (
    mrmPowerOnDefaults,
    mrmUARTMode
  );

procedure MPUSetPorts(const ABasePort: Word);

function MPUReset(const AMPUResetMode: TMPUResetMode): Boolean;

implementation

uses
  Routines;

const
  { general MPU-401 related constants }
  kDataCommunicationDelay = 10;
  kStatusPortReadRetries  = $FF;

  { MPU-401 bit masks }
  MPU_MASK_DRR            = $40; { data read register }
  MPU_MASK_DSR            = $80; { data set ready }

  { MPU-401 commands }
  MPU_CMD_UART_MODE       = $3F; { dumb UART mode }
  MPU_CMD_ACK             = $FE; { acknowledge response }
  MPU_CMD_RESET           = $FF; { total reset }

  { MPU-401 system exclusive messages }
  kGMResetSysEx: packed array[0..5] of Byte = ( $F0, $7E, $7F, $09, $01, $F7 );

var
  IGDataPort: Word;
  IGStatusPort: Word;
  IGCommandPort: Word;

function SendDataWaitStatus(const APort: Word; const AData, AMask: Byte): Boolean; forward;

{ private declarations }

function SendDataWaitStatus(const APort: Word; const AData, AMask: Byte): Boolean;
var
  LByte: Byte;
  LRetries: Byte;

begin
  Port[APort] := AData;

  Routines.Delay(kDataCommunicationDelay);

  LByte := Port[APort];

  LRetries := kStatusPortReadRetries;

  while ((Port[IGStatusPort] and AMask) <> 0) and (LRetries > 0) do
  begin
    Dec(LRetries);
  end;

  SendDataWaitStatus := LRetries > 0;
end;

{ public declarations }

procedure MPUSetPorts(const ABasePort: Word);
begin
  IGDataPort := ABasePort;
  IGStatusPort := Succ(ABasePort);
  IGCommandPort := Succ(ABasePort);
end;

function MPUReset(const AMPUResetMode: TMPUResetMode): Boolean;
var
  LByte: Byte;

begin
  MPUReset := False;

  if not SendDataWaitStatus(IGCommandPort, MPU_CMD_RESET, MPU_MASK_DRR) then
  begin
    Exit;
  end;

  if AMPUResetMode = mrmUARTMode then
  begin
    if not SendDataWaitStatus(IGCommandPort, MPU_CMD_UART_MODE, MPU_MASK_DSR) then
    begin
      Exit;
    end;
  end;

  for LByte := Low(kGMResetSysEx) to High(kGMResetSysEx) do
  begin
    if not SendDataWaitStatus(IGDataPort, kGMResetSysEx[LByte], MPU_MASK_DRR) then
    begin
      Exit;
    end;
  end;

  MPUReset := True;
end;

end.
