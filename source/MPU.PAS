{ --------------------------------------------------------------------------- }
{ - Audio Interface - MPU Interface (mpu.pas)                               - }
{ - Copyright (C) 2000 Jan Knipperts                                        - }
{ - Improvements (C) 2020 Alexandru Groza                                   - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit MPU;

interface

type
  TMPUResetMode = (
    mrmPowerOnDefaults,
    mrmDumbUART
  );

procedure MPUSetPorts(const ABasePort: Word);

function MPUReset(const AMPUResetMode: TMPUResetMode): Boolean;

implementation

uses
  Routines;

const
  { Status Port Bits }
  DRR             = $40; { MPU-401 'Ready to receive' mask }
  DSR             = $80; { MPU-401 'Ready to send' mask }

  { MPU Commands }
  CMD_UART        = $3F; { Become a dumb uart }
  CMD_RESET       = $FF; { Reset to default state }
  CMD_ACK         = $FE; { MPU's acknowledement of a command }

  kShortDelay     = 10;

var
  IGCommandPort: Word;
  IGStatusPort: Word;
  IGDataPort: Word;

{ private declarations }

procedure SendData(const AData: Byte);
begin
  repeat
  until (Port[IGStatusPort] and DRR) = $00;

  Port[IGDataPort] := AData;

  Delay(kShortDelay);
end;

{ public declarations }

procedure MPUSetPorts(const ABasePort: Word);
begin
  IGCommandPort := ABasePort + 1;
  IGStatusPort := ABasePort + 1;
  IGDataPort := ABasePort;
end;

function MPUReset(const AMPUResetMode: TMPUResetMode): Boolean;
var
  LRetries: Word;

begin
  Port[IGCommandPort] := CMD_RESET;

  if AMPUResetMode = mrmDumbUART then
  begin
    Delay(kShortDelay);

    LRetries := $FF;

    while ((Port[IGStatusPort] and DSR) <> 0) and (LRetries > 0) do
    begin
      Dec(LRetries);
    end;

    if (Port[IGDataPort] <> CMD_ACK) or (LRetries = 0) then
    begin
      MPUReset := False;
      Exit;
    end;

    Delay(kShortDelay);

    if (Port[IGStatusPort] and DRR) <> 0 then
    begin
      MPUReset := False;
      Exit;
    end;

    Port[IGCommandPort] := CMD_UART;

    Delay(kShortDelay);

    LRetries := $FF;

    while ((Port[IGStatusPort] and DSR) <> 0) and (LRetries > 0) do
    begin
      Dec(LRetries);
    end;

    if (Port[IGDataPort] <> CMD_ACK) or (LRetries = 0) then
    begin
      MPUReset := False;
      Exit;
    end;
  end;

  { Some devices need an additional "GM-Reset" sysex }
  SendData($F0);
  SendData($7E);
  SendData($7F);
  SendData($09);
  SendData($01);
  SendData($F7);

  MPUReset := True;
end;

end.
