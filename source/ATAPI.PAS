{ --------------------------------------------------------------------------- }
{ - Audio Interface - ATAPI Interface (atapi.pas)                           - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$I cdefines.inc}

{$IFDEF CPU16BIT}
  {$G+}
{$ENDIF}

unit ATAPI;

interface

function ATAPIProbe(var AInterface, ADrive: Byte; var AModel: String): Boolean;

implementation

const
  kATA_POLLING_TIMEOUT         = 65535;

  kATA_DEVICE_MASTER           = $0A0;

  kATA_DEVICE_ERROR            = $01;
  kATA_DEVICE_BUSY             = $80;
  kATA_DEVICE_DRQ              = $08;
  kATA_DEVICE_ABORT            = $04;
  kATA_DEVICE_SRST             = $04;

  kATAPI_LOW_CYLINDER_MARKER   = $014;
  kATAPI_HIGH_CYLINDER_MARKER  = $0EB;

  kATA_IDENTIFY_BUFFER_SIZE    = 256;

  kATA_DRIVE_MODEL_INDEX       = 27;
  kATA_DRIVE_MODEL_LENGTH      = 20;
  kATA_DRIVE_REVISION_INDEX    = 23;
  kATA_DRIVE_REVISION_LENGTH   = 4;

  { ATA interfaces }
  kATA_INTERFACE_PRIMARY       = $01F0;
  kATA_INTERFACE_SECONDARY     = $0170;
  kATA_INTERFACE_TERTIARY      = $01E8;
  kATA_INTERFACE_QUATERNARY    = $0168;

  { ATA control register mapping }
  kATA_REGISTER_CONTROL_OFFSET = $0206;

  { ATA registers }
  kATA_REGISTER_DATA           = $00;
  kATA_REGISTER_ERROR          = $01;
  kATA_REGISTER_WRITE_PRECOMP  = $01;
  kATA_REGISTER_SECTOR_COUNT   = $02;
  kATA_REGISTER_SECTOR_NUMBER  = $03;
  kATA_REGISTER_LOW_CYLINDER   = $04;
  kATA_REGISTER_HIGH_CYLINDER  = $05;
  kATA_REGISTER_DRIVE_SELECT   = $06;
  kATA_REGISTER_STATUS         = $07;
  kATA_REGISTER_COMMAND        = $07;

  { ATA commands }
  kATA_COMMAND_IDENTIFY        = $EC;
  kATAPI_COMMAND_IDENTIFY      = $A1;

  kDriveMaster                 = 0;
  kDriveSlave                  = 1;

  kDriveTypeNone               = 0;
  kDriveTypeATA                = 1;
  kDriveTypeATAPI              = 2;

  kInterfaces: array[0..3] of Word = (
    kATA_INTERFACE_PRIMARY,
    kATA_INTERFACE_SECONDARY,
    kATA_INTERFACE_TERTIARY,
    kATA_INTERFACE_QUATERNARY
  );

function Probe(const AInterface: Word; const ADrive: Byte;
  var AModel: String; const AIncludeRevision: Boolean): Byte; forward;

{ private declarations }

function Probe(const AInterface: Word; const ADrive: Byte;
  var AModel: String; const AIncludeRevision: Boolean): Byte; assembler;
var
  LIdentifyResponse: array[0..Pred(kATA_IDENTIFY_BUFFER_SIZE)] of Word;

asm
  push ds

  jmp @start

@@procDriveSelect:
  mov ah, ADrive
  mov al, kATA_DEVICE_MASTER
  mov cl, 04h
  shl ah, cl
  or al, ah
  mov dx, AInterface
  add dx, kATA_REGISTER_DRIVE_SELECT
  out dx, al

  mov cx, 05h
  mov dx, AInterface
  add dx, kATA_REGISTER_CONTROL_OFFSET

@wait400ns:
  in al, dx
  loop @wait400ns

  retn

@@procWaitNotBusyDRQ:
  mov cx, kATA_POLLING_TIMEOUT

@waitNotBusy:
  in al, dx
  test al, kATA_DEVICE_BUSY
  jz @waitDRQLoop
  loop @waitNotBusy
  jmp @endWaitNotBusyDRQ

@waitDRQLoop:
  mov cx, kATA_POLLING_TIMEOUT

@waitDRQ:
  in al, dx
  test al, kATA_DEVICE_DRQ
  jnz @endWaitNotBusyDRQ
  loop @waitDRQ

@endWaitNotBusyDRQ:
  retn

@start:
  mov dx, AInterface
  add dx, kATA_REGISTER_CONTROL_OFFSET
  mov al, kATA_DEVICE_SRST
  out dx, al

  mov cx, 0FFFFh

@resetDelay:
  loop @resetDelay

  xor al, al
  out dx, al

@w:
  mov dx, AInterface
  add dx, kATA_REGISTER_STATUS
  in al, dx
  test al, 80h
  jnz @w

  xor al, al
  mov cx, 04h
  mov dx, AInterface
  add dx, kATA_REGISTER_WRITE_PRECOMP

@zeroSectorAndCylinderRegs:
  inc dx
  out dx, al
  loop @zeroSectorAndCylinderRegs

  call @@procDriveSelect
  mov bl, kDriveTypeATA

  mov al, kATA_COMMAND_IDENTIFY
  mov dx, AInterface
  add dx, kATA_REGISTER_COMMAND
  out dx, al

  call @@procWaitNotBusyDRQ
  jnz @readWords
  test al, kATA_DEVICE_ERROR
  jz @noDevice

  mov dx, AInterface
  add dx, kATA_REGISTER_ERROR
  in al, dx
  test al, kATA_DEVICE_ABORT
  jz @noDevice

  mov dx, AInterface
  add dx, kATA_REGISTER_LOW_CYLINDER
  in al, dx
  cmp al, kATAPI_LOW_CYLINDER_MARKER
  jne @noDevice

  inc dx
  in al, dx
  cmp al, kATAPI_HIGH_CYLINDER_MARKER
  jne @noDevice

  call @@procDriveSelect
  mov bl, kDriveTypeATAPI

  mov al, kATAPI_COMMAND_IDENTIFY
  mov dx, AInterface
  add dx, kATA_REGISTER_COMMAND
  out dx, al

  call @@procWaitNotBusyDRQ
  jnz @readWords
  test al, kATA_DEVICE_ERROR
  jz @noDevice

@readWords:
  cld

  mov ax, cs
  mov es, ax
  lea di, [LIdentifyResponse]
  mov cx, kATA_IDENTIFY_BUFFER_SIZE
  mov dx, AInterface
  add dx, kATA_REGISTER_DATA

  cli

@readData:
  in ax, dx
  stosw
  loop @readData

  sti

  mov ax, cs
  mov ds, ax
  lea si, [LIdentifyResponse]
  add si, kATA_DRIVE_MODEL_INDEX * 2
  les di, [AModel]
  inc di

  mov cx, kATA_DRIVE_MODEL_LENGTH
  xor dx, dx

@buildString:
  lodsw
  xchg ah, al
  stosw
  add dl, 02h
  loop @buildString

@trimEnd:
  dec di
  cmp byte ptr es:[di], ' '
  jne @checkRevision
  dec dl
  jmp @trimEnd

@checkRevision:
  cmp AIncludeRevision, True
  jne @setLength

  or dh, dh
  jnz @setLength

  mov ax, 'R '
  stosw
  mov ax, 'VE'
  stosw
  mov ax, ' .'
  stosw
  add dl, 06h

  sub si, kATA_DRIVE_MODEL_LENGTH * 2 + kATA_DRIVE_REVISION_LENGTH * 2
  mov cx, kATA_DRIVE_REVISION_LENGTH
  inc dh
  jmp @buildString

@noDevice:
  xor dl, dl
  mov bl, kDriveTypeNone

@setLength:
  les di, [AModel]
  mov al, dl
  stosb

  mov al, bl

  pop ds
end;

{ public declarations }

function ATAPIProbe(var AInterface, ADrive: Byte; var AModel: String): Boolean;
var
  LInterface: Byte;
  LDrive: Byte;

begin
  for LInterface := Low(kInterfaces) to High(kInterfaces) do
  begin
    for LDrive := kDriveMaster to kDriveSlave do
    begin
      if Probe(kInterfaces[LInterface], LDrive, AModel, True) = kDriveTypeATAPI then
      begin
        AInterface := LInterface;
        ADrive := LDrive;

        ATAPIProbe := True;

        Exit;
      end;
    end;
  end;

  ATAPIProbe := False;
end;

end.
