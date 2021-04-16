{ --------------------------------------------------------------------------- }
{ - Audio Interface - Sound Controller Interface (control.pas)              - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - Portions Copyright (C) 2018 Jan Knipperts                               - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Control;

interface

uses
  Types;

type
  TControllerConfig = record
    { Mode Control Register 1 Bits }
    BitMOD: TBitStatus;
    BitPDN: TBitStatus;
    BitGPEN: TBitStatus;

    { Mode Control Register 2 Bits }
    BitOPL4: TBitStatus;

    { Mode Control Register 3 Bits }
    BitFMAP: TBitStatus;
    BitCMDPAS: TBitStatus;

    { Mode Control Register 4 Bits }
    BitADPCMEN: TBitStatus;
    BitGPOUT: TBitStatus;
    BitPNPMODE: TBitStatus;
    BitFMCLK: TBitStatus;
    BitSILENCE: TBitStatus;

    { Mode Control Register 5 Bits }
    BitAVCEN: TBitStatus;
    BitOPL5: TBitStatus;
    BitSHPASS: TBitStatus;
    BitSBACCESS: TBitStatus;
    BitCFIFO: TBitStatus;
    BitEPEN: TBitStatus;
    BitCFIX: TBitStatus;

    { Mode Control Register 6 Bits }
    BitMPU401: TBitStatus;
    BitDRQTMEN: TBitStatus;
    BitAUDIOEN: TBitStatus;

    WSSBASE: Word;
    WSSIRQ: Byte;
    WSSDRQ: Byte;

    SBBASE: Word;
    SBIRQ: Byte;
    SBDRQ: Byte;
    SBDSPVersion: TCodecSBDSPVersion;

    MPUBASE: Word;
    MPUIRQ: Byte;

    CDBASE: Word;
    CDIRQ: Byte;
    CDDRQ: Byte;
    IDECDROM: TBitStatus;
  end;

var
  GAIFDetectionMode: TAIFDetectionMode;

function ControllerDetect: Boolean;
function ControllerGetRevision: Byte;

procedure ControllerResetRegisters;

function ControllerGetMode: TControllerMode;
procedure ControllerSetMode(const AControllerMode: TControllerMode; const AControllerConfig: TControllerConfig);

procedure ControllerAllowCodecAccess(const AControllerConfig: TControllerConfig);
procedure ControllerDisallowCodecAccess;

procedure ControllerSBADPCM(const AEnable: Boolean);
procedure ControllerAVC(const AEnable: Boolean);
procedure ControllerSilence(const AEnable: Boolean);
procedure ControllerPowerDown(const AEnable: Boolean);
procedure ControllerChipTest(const AEnable: Boolean);

function ControllerEraseEEPROM(AEraseMethod: TControllerEraseMethod; const AUpdateProgress: TUpdateProgress): Boolean;
function ControllerReadEEPROM(const AFileName: String; const AUpdateProgress: TUpdateProgress): Boolean;
function ControllerWriteEEPROM(const AFileName: String; const AUpdateProgress: TUpdateProgress): Boolean;

implementation

uses
  Consts,
  Routines;

const
  { General Controller Related Constants }
  kRegisterPassword          = $E5;

  { Controller Registers }
  kREGISTER_MC1              = $0F8D;
  kREGISTER_MC2              = $0F8E;
  kREGISTER_MC3              = $0F8F;
  kREGISTER_MC4              = $0F90;
  kREGISTER_MC5              = $0F91;
  kREGISTER_MC6              = $0F92;
  kREGISTER_MC7              = $0F93;

  kREGISTER_MC_INDIRECT_IDX  = $0F94;
  kREGISTER_MC_INDIRECT_DATA = $0F95;

  kREGISTER_PASSWORD         = $0F8F;

  { Controller Registers Default Values }
  kREGISTER_MC1_Default      = $00;
  kREGISTER_MC2_Default      = $03;
  kREGISTER_MC3_Default      = $F2;
  kREGISTER_MC4_Default      = $A2;
  kREGISTER_MC5_Default      = $2F;
  kREGISTER_MC6_Default      = $83;

  { Mode Control Register 1 Bits }
  kBitMOD                    = 7;
  kBitPDN                    = 6;
  kBitGPEN                   = 0;

  { Mode Control Register 2 Bits }
  kBitOPL4                   = 5;

  { Mode Control Register 3 Bits }
  kBitFMAP                   = 3;
  kBitDABASE                 = 2;
  kBitWRSROM                 = 1;
  kBitCMDPAS                 = 0;

  { Mode Control Register 4 Bits }
  kBitADPCMEN                = 7;
  kBitGPOUT                  = 6;
  kBitACKSIMEN               = 5;
  kBitPNPMODE                = 4;
  kBitFMCLK                  = 3;
  kBitSILENCE                = 2;

  { Mode Control Register 5 Bits }
  kBitAVCEN                  = 7;
  kBitOPL5                   = 6;
  kBitSHPASS                 = 5;
  kBitSBACCESS               = 4;
  kBitCFIFO                  = 3;
  kBitEPEN                   = 2;
  kBitCFIX                   = 1;
  kBitCDFTOEN                = 0;

  { Mode Control Register 6 Bits }
  kBitMPU401                 = 7;
  kBitDRQTMEN                = 2;
  kBitAUDIOEN                = 1;
  kBitATTNEN                 = 0;

  { Mode Control Register 7 Bits }
  kBitSROMCS                 = 2;
  kBitSROMCLK                = 1;
  kBitROMDOUT                = 0;

  { Mode Control Register 9 Bits }
  kBitROMIN                  = 5;

  { WSS Configuration Register Bits }
  kWSSConfigBitRes           = 7;
  kBitISS                    = 6;

  { EEPROM Communication }
  kEEPROMCommandEWDS         = $0800;
  kEEPROMCommandEWEN         = $0980;
  kEEPROMCommandERAL         = $0900;
  kEEPROMCommandWRAL         = $0880;
  kEEPROMCommandERASE        = $0E00;
  kEEPROMCommandREAD         = $0C00;
  kEEPROMCommandWRITE        = $0A00;

  kEEPROMReadyRetries        = $FFFF;
  kEEPROMSize                = 256;
  kEEPROMCommunicationDelay  = 1;

{ private declarations }

procedure SetBitStatus(var ABitVariable: TBitStatus; const AValue: Boolean);
begin
  if AValue then
  begin
    ABitVariable := bsSet;
  end else
  begin
    ABitVariable := bsNotSet;
  end;
end;

procedure SetBitByStatus(var AByte: Byte; const ABit: Byte; const ABitStatus: TBitStatus);
begin
  SetBit(AByte, ABit, ABitStatus = bsSet);
end;

function ControllerRead(const APort: Word): Byte;
begin
  asm
    cli
  end;

  case GAIFDetectionMode of
    dmPnP:
      begin
        Port[kREGISTER_PASSWORD - $80] := kRegisterPassword;
        ControllerRead := Port[APort - $80];
      end;

    dmnonPnP:
      begin
        Port[kREGISTER_PASSWORD] := kRegisterPassword;
        ControllerRead := Port[APort];
      end;

  end;

  asm
    sti
  end;
end;

procedure ControllerWrite(const APort: Word; const AValue: Byte);
begin
  asm
    cli
  end;

  case GAIFDetectionMode of
    dmPnP:
      begin
        Port[kREGISTER_PASSWORD - $80] := kRegisterPassword;
        Port[APort - $80] := AValue and $FF;
      end;

    dmnonPnP:
      begin
        Port[kREGISTER_PASSWORD] := kRegisterPassword;
        Port[APort] := AValue and $FF;
      end;

  end;

  asm
    sti
  end;
end;

procedure SetRegisterBit(const ARegister: Word; const ABit: Byte; const AValue: Boolean);
var
  LData: Byte;

begin
  LData := ControllerRead(ARegister);
  SetBit(LData, ABit, AValue);
  ControllerWrite(ARegister, LData);
end;

function Detect82c924(const AAIFDetectionMode: TAIFDetectionMode): Boolean;
{ Checks if the gate is closed on first I/O after writing the password. }
var
  LData: Byte;

begin
  GAIFDetectionMode := AAIFDetectionMode;

  LData := ControllerRead(kREGISTER_MC1);
  Detect82c924 := (LData <> $FF) and (LData <> Port[kREGISTER_MC1]);
end;

procedure SetWSSConfig(const AControllerConfig: TControllerConfig);
var
  LWSSIRQ: Byte;
  LWSSDRQ: Byte;
  LWSSConfig: byte;

begin
  case AControllerConfig.WSSIRQ of
    $07:
      LWSSIRQ := $01;

    $09:
      LWSSIRQ := $02;

    $0A:
      LWSSIRQ := $03;

    $0B:
      LWSSIRQ := $04;

  end;

  case AControllerConfig.WSSDRQ of
    $00:
      LWSSDRQ := $01;

    $01:
      LWSSDRQ := $02;

    $03:
      LWSSDRQ := $03;

  end;

  LWSSConfig := LWSSIRQ shl $03 or LWSSDRQ;

  SetBit(LWSSConfig, kBitISS, AControllerConfig.WSSIRQ = $FF);
  SetBit(LWSSConfig, kWSSConfigBitRes, GetBit(Port[AControllerConfig.WSSBASE], kWSSConfigBitRes));

  Port[AControllerConfig.WSSBASE] := LWSSConfig;
end;

function GetSoundBase(const AData: Byte): Word;
begin
  case AData and $30 of
    $00:
      GetSoundBase := $0530;

    $10:
      GetSoundBase := $0E80;

    $20:
      GetSoundBase := $0F40;

    $30:
      GetSoundBase := $0604;

  end;
end;

procedure SetSoundBase(var AData: Byte; const AValue: Word);
begin
  AData := AData and $CF;

  case AValue of
    $0530:
      AData := AData or $00;

    $0E80:
      AData := AData or $10;

    $0F40:
      AData := AData or $20;

    $0604:
      AData := AData or $30;

  end;
end;

function GetWSIRQ(const AData: Byte): Byte;
begin
  case AData and $38 of
    $00:
      GetWSIRQ := $FF;

    $08:
      GetWSIRQ := $07;

    $10:
      GetWSIRQ := $09;

    $18:
      GetWSIRQ := $0A;

    $20:
      GetWSIRQ := $0B;

  else
    GetWSIRQ := $EE;
  end;
end;

function GetWSDRQ(const AData: Byte): Byte;
begin
  case AData and $07 of
    $00, $04:
      GetWSDRQ := $FF;

    $01, $05:
      GetWSDRQ := $00;

    $02, $06:
      GetWSDRQ := $01;

    $03, $07:
      GetWSDRQ := $03;

  end;
end;

function GetIDECDROM(const AData: Byte): TBitStatus;
begin
  case AData and $0E of
    $08:
      GetIDECDROM := bsSet;

  else
    GetIDECDROM := bsNotSet;
  end;
end;

procedure SetIDECDROM(var AData: Byte; const AValue: TBitStatus);
begin
  AData := AData and $F1;

  case AValue of
    bsNotSet:
      AData := AData or $00;

    bsSet:
      AData := AData or $08;

  end;
end;

function GetCDSEL(const AData: Byte): Word;
begin
  case AData and $C0 of
    $00:
      GetCDSEL := $0340;

    $40:
      GetCDSEL := $0330;

    $80:
      GetCDSEL := $0360;

    $C0:
      GetCDSEL := $0320;

  end;
end;

procedure SetCDSEL(var AData: Byte; const AValue: Word);
begin
  AData := AData and $3F;

  case AValue of
    $0340:
      AData := AData or $00;

    $0330:
      AData := AData or $40;

    $0360:
      AData := AData or $80;

    $0320:
      AData := AData or $C0;

  end;
end;

function GetCDIRQ(const AData: Byte): Byte;
begin
  case AData and $1C of
    $00, $0C, $1C:
      GetCDIRQ := $FF;

    $04:
      GetCDIRQ := $05;

    $08:
      GetCDIRQ := $07;

    $10:
      GetCDIRQ := $09;

    $14:
      GetCDIRQ := $0A;

    $18:
      GetCDIRQ := $0B;

  end;
end;

procedure SetCDIRQ(var AData: Byte; const AValue: Byte);
begin
  AData := AData and $E3;

  case AValue of
    $FF:
      AData := AData or $00;

    $05:
      AData := AData or $04;

    $07:
      AData := AData or $08;

    $09:
      AData := AData or $10;

    $0A:
      AData := AData or $14;

    $0B:
      AData := AData or $18;

  end;
end;

function GetCDDRQ(const AData: Byte): Byte;
begin
  case AData and $03 of
    $00:
      GetCDDRQ := $03;

    $01:
      GetCDDRQ := $00;

    $02:
      GetCDDRQ := $01;

    $03:
      GetCDDRQ := $FF;

  end;
end;

procedure SetCDDRQ(var AData: Byte; const AValue: Byte);
begin
  AData := AData and $FC;

  case AValue of
    $03:
      AData := AData or $00;

    $00:
      AData := AData or $01;

    $01:
      AData := AData or $02;

    $FF:
      AData := AData or $03;

  end;
end;

function GetDABASE(const AData: Byte): Word;
begin
  case (AData shr kBitDABASE) and 1 of
    0:
      GetDABASE := $0220;

    1:
      GetDABASE := $0240;

  end;
end;

procedure SetDABASE(var AData: Byte; const AValue: Word);
begin
  SetBit(AData, kBitDABASE, AValue = $0240);
end;

function GetDAIRQ(const AData: Byte): Byte;
begin
  case AData and $C0 of
    $00:
      GetDAIRQ := $07;

    $40:
      GetDAIRQ := $0A;

    $80:
      GetDAIRQ := $05;

    $C0:
      GetDAIRQ := $FF;

  end;
end;

procedure SetDAIRQ(var AData: Byte; const AValue: Byte);
begin
  AData := AData and $3F;

  case AValue of
    $07:
      AData := AData or $00;

    $0A:
      AData := AData or $40;

    $05:
      AData := AData or $80;

    $FF:
      AData := AData or $3F;

  end;
end;

function GetDADRQ(const AData: Byte): Byte;
begin
  case AData and $30 of
    $00:
      GetDADRQ := $01;

    $10:
      GetDADRQ := $00;

    $20:
      GetDADRQ := $03;

    $30:
      GetDADRQ := $FF;

  end;
end;

procedure SetDADRQ(var AData: Byte; const AValue: Byte);
begin
  AData := AData and $CF;

  case AValue of
    $01:
      AData := AData or $00;

    $00:
      AData := AData or $10;

    $03:
      AData := AData or $20;

    $FF:
      AData := AData or $30;

  end;
end;

function GetSBDSPVersion(const AData: Byte): TCodecSBDSPVersion;
begin
  case AData and $03 of
    $00:
      GetSBDSPVersion := sdVersion21;

    $01:
      GetSBDSPVersion := sdVersion15;

    $02:
      GetSBDSPVersion := sdVersion32;

    $03:
      GetSBDSPVersion := sdVersion44;

  end;
end;

procedure SetSBDSPVersion(var AData: Byte; const AValue: TCodecSBDSPVersion);
begin
  AData := AData and $FC;

  case AValue of
    sdVersion21:
      AData := AData or $00;

    sdVersion15:
      AData := AData or $01;

    sdVersion32:
      AData := AData or $02;

    sdVersion44:
      AData := AData or $03;

  end;
end;

function GetMPUBASE(const AData: Byte): Word;
begin
  case AData and $60 of
    $00:
      GetMPUBASE := $0330;

    $20:
      GetMPUBASE := $0320;

    $40:
      GetMPUBASE := $0310;

    $60:
      GetMPUBASE := $0300;

  end;
end;

procedure SetMPUBASE(var AData: Byte; const AValue: Word);
begin
  AData := AData and $9F;

  case AValue of
    $0330:
      AData := AData or $00;

    $0320:
      AData := AData or $20;

    $0310:
      AData := AData or $40;

    $0300:
      AData := AData or $60;

  end;
end;

function GetMPUIRQ(const AData: Byte): Byte;
begin
  case AData and $18 of
    $00:
      GetMPUIRQ := $09;

    $08:
      GetMPUIRQ := $0A;

    $10:
      GetMPUIRQ := $05;

    $18:
      GetMPUIRQ := $07;

  end;
end;

procedure SetMPUIRQ(var AData: Byte; const AValue: Byte);
begin
  AData := AData and $E7;

  case AValue of
    $09:
      AData := AData or $00;

    $0A:
      AData := AData or $08;

    $05:
      AData := AData or $10;

    $07:
      AData := AData or $18;

  end;
end;

procedure GetConfig(var AControllerConfig: TControllerConfig);
var
  LData: Byte;
  LWSSData: Byte;

begin
  FillChar(AControllerConfig, SizeOf(AControllerConfig), $00);

  { Mode Control Register 1 }

  LData := ControllerRead(kREGISTER_MC1);

  SetBitStatus(AControllerConfig.BitMOD, GetBit(LData, kBitMOD));
  SetBitStatus(AControllerConfig.BitPDN, GetBit(LData, kBitPDN));

  AControllerConfig.WSSBASE := GetSoundBase(LData);

  LWSSData := Port[AControllerConfig.WSSbase];

  AControllerConfig.WSSIRQ := GetWSIRQ(LWSSData);
  AControllerConfig.WSSDRQ := GetWSDRQ(LWSSData);

  AControllerConfig.IDECDROM := GetIDECDROM(LData);

  SetBitStatus(AControllerConfig.BitGPEN, GetBit(LData, kBitGPEN));

  { Mode Control Register 2 }

  LData := ControllerRead(kREGISTER_MC2);

  SetBitStatus(AControllerConfig.BitOPL4, GetBit(LData, kBitOPL4));

  AControllerConfig.CDBASE := GetCDSEL(LData);
  AControllerConfig.CDIRQ := GetCDIRQ(LData);
  AControllerConfig.CDDRQ := GetCDDRQ(LData);

  { Mode Control Register 3 }

  LData := ControllerRead(kREGISTER_MC3);

  AControllerConfig.SBBASE := GetDABASE(LData);
  AControllerConfig.SBIRQ := GetDAIRQ(LData);
  AControllerConfig.SBDRQ := GetDADRQ(LData);

  SetBitStatus(AControllerConfig.BitFMAP, GetBit(LData, kBitFMAP));

  { Mode Control Register 4 }

  LData := ControllerRead(kREGISTER_MC4);

  SetBitStatus(AControllerConfig.BitADPCMEN, GetBit(LData, kBitADPCMEN));
  SetBitStatus(AControllerConfig.BitGPOUT, GetBit(LData, kBitGPOUT));
  SetBitStatus(AControllerConfig.BitPNPMODE, GetBit(LData, kBitPNPMODE));
  SetBitStatus(AControllerConfig.BitFMCLK, GetBit(LData, kBitFMCLK));
  SetBitStatus(AControllerConfig.BitSILENCE, GetBit(LData, kBitSILENCE));

  AControllerConfig.SBDSPVersion := GetSBDSPVersion(LData);

  { Mode Control Register 5 }

  LData := ControllerRead(kREGISTER_MC5);

  SetBitStatus(AControllerConfig.BitAVCEN, GetBit(LData, kBitAVCEN));
  SetBitStatus(AControllerConfig.BitOPL5, GetBit(LData, kBitOPL5));
  SetBitStatus(AControllerConfig.BitSHPASS, GetBit(LData, kBitSHPASS));
  SetBitStatus(AControllerConfig.BitSBACCESS, GetBit(LData, kBitSBACCESS));
  SetBitStatus(AControllerConfig.BitCFIFO, GetBit(LData, kBitCFIFO));
  SetBitStatus(AControllerConfig.BitEPEN, GetBit(LData, kBitEPEN));
  SetBitStatus(AControllerConfig.BitCFIX, GetBit(LData, kBitCFIX));

  { Mode Control Register 6 }

  LData := ControllerRead(kREGISTER_MC6);

  SetBitStatus(AControllerConfig.BitMPU401, GetBit(LData, kBitMPU401));

  AControllerConfig.MPUBASE := GetMPUBASE(LData);
  AControllerConfig.MPUIRQ := GetMPUIRQ(LData);
end;

procedure SetConfig(const AControllerMode: TControllerMode; const AControllerConfig: TControllerConfig);
var
  LData: Byte;

begin
  { Mode Control Register 1 }

  LData := 0;

  case AControllerMode of
    cmSB:
      SetBitByStatus(LData, kBitMOD, bsNotSet);

    cmWSS:
      SetBitByStatus(LData, kBitMOD, bsSet);

  end;

  SetBitByStatus(LData, kBitPDN, AControllerConfig.BitPDN);

  SetSoundBase(LData, AControllerConfig.WSSBase);
  SetIDECDROM(LData, AControllerConfig.IDECDROM);

  SetBitByStatus(LData, kBitGPEN, AControllerConfig.BitGPEN);

  ControllerWrite(kREGISTER_MC1, LData);

  { Mode Control Register 2 }

  LData := 0;

  SetBitByStatus(LData, kBitOPL4, AControllerConfig.BitOPL4);

  SetCDSEL(LData, AControllerConfig.CDBASE);
  SetCDIRQ(LData, AControllerConfig.CDIRQ);
  SetCDDRQ(LData, AControllerConfig.CDDRQ);

  ControllerWrite(kREGISTER_MC2, LData);

  { Mode Control Register 3 }

  LData := 0;

  SetDAIRQ(LData, AControllerConfig.SBIRQ);
  SetDADRQ(LData, AControllerConfig.SBDRQ);
  SetDABASE(LData, AControllerConfig.SBBASE);

  SetBitByStatus(LData, kBitFMAP, AControllerConfig.BitFMAP);
  SetBitByStatus(LData, kBitWRSROM, bsNotSet);
  SetBitByStatus(LData, kBitCMDPAS, AControllerConfig.BitCMDPAS);

  ControllerWrite(kREGISTER_MC3, LData);

  { Mode Control Register 4 }

  LData := 0;

  SetBitByStatus(LData, kBitADPCMEN, AControllerConfig.BitADPCMEN);
  SetBitByStatus(LData, kBitGPOUT, AControllerConfig.BitGPOUT);
  SetBitByStatus(LData, kBitACKSIMEN, bsSet);
  SetBitByStatus(LData, kBitPNPMODE, AControllerConfig.BitPNPMODE);
  SetBitByStatus(LData, kBitFMCLK, AControllerConfig.BitFMCLK);
  SetBitByStatus(LData, kBitSILENCE, AControllerConfig.BitSILENCE);

  case AControllerMode of
    cmSB:
      SetSBDSPVersion(LData, AControllerConfig.SBDSPVersion);

    cmWSS:
      SetSBDSPVersion(LData, sdVersion32);

  end;

  ControllerWrite(kREGISTER_MC4, LData);

  { Mode Control Register 5 }

  LData := 0;

  SetBitByStatus(LData, kBitAVCEN, AControllerConfig.BitAVCEN);
  SetBitByStatus(LData, kBitOPL5, AControllerConfig.BitOPL5);
  SetBitByStatus(LData, kBitSHPASS, AControllerConfig.BitSHPASS);
  SetBitByStatus(LData, kBitSBACCESS, AControllerConfig.BitSBACCESS);
  SetBitByStatus(LData, kBitCFIFO, AControllerConfig.BitCFIFO);
  SetBitByStatus(LData, kBitEPEN, AControllerConfig.BitEPEN);
  SetBitByStatus(LData, kBitCFIX, AControllerConfig.BitCFIX);
  SetBitByStatus(LData, kBitCDFTOEN, bsSet);

  ControllerWrite(kREGISTER_MC5, LData);

  { Mode Control Register 6 }

  LData := 0;

  SetBitByStatus(LData, kBitMPU401, AControllerConfig.BitMPU401);

  SetMPUBASE(LData, AControllerConfig.MPUBase);
  SetMPUIRQ(LData, AControllerConfig.MPUIRQ);

  SetBitByStatus(LData, kBitDRQTMEN, AControllerConfig.BitDRQTMEN);
  SetBitByStatus(LData, kBitAUDIOEN, AControllerConfig.BitAUDIOEN);
  SetBitByStatus(LData, kBitATTNEN, bsSet);

  ControllerWrite(kREGISTER_MC6, LData);

  if AControllerMode = cmWSS then
  begin
    SetWSSConfig(AControllerConfig);
  end;
end;

procedure EEPROMSetCS(const AValue: Boolean);
begin
  SetRegisterBit(kREGISTER_MC7, kBitSROMCS, AValue);
end;

procedure EEPROMClockPulse;
begin
  SetRegisterBit(kREGISTER_MC7, kBitSROMCLK, True);

  Routines.Delay(kEEPROMCommunicationDelay);

  SetRegisterBit(kREGISTER_MC7, kBitSROMCLK, False);

  Routines.Delay(kEEPROMCommunicationDelay);
end;

procedure EEPROMDataOut(const AValue: Boolean);
begin
  { TODO -oagroza -cImplement : Send data to indirect kREGISTER_MC9 / kBitROMIN. }

  Routines.Delay(kEEPROMCommunicationDelay);
end;

function EEPROMWaitReady: Boolean;
var
  LRetries: Word;

begin
  EEPROMSetCS(False);

  Routines.Delay(kEEPROMCommunicationDelay);

  EEPROMSetCS(True);

  LRetries := kEEPROMReadyRetries;

  while (not GetBit(ControllerRead(kREGISTER_MC7), kBitROMDOUT)) and (LRetries > 0) do
  begin
    Dec(LRetries);
  end;

  EEPROMWaitReady := LRetries > 0;
end;

procedure EEPROMSendCommand(const ACommand: Word);
var
  I: Byte;

begin
  for I := 11 downto 0 do
  begin
    EEPROMDataOut(Boolean((ACommand shr I) and $01));
    EEPROMClockPulse;
  end;

  { TODO -oagroza -cDecide : Is this instruction really needed? }
  EEPROMDataOut(False);
end;

function EEPROMGetData: Byte;
var
  I: Byte;
  LData: Byte;

begin
  LData := $00;

  for I := 7 downto 0 do
  begin
    EEPROMClockPulse;

    LData := LData or (Byte(GetBit(ControllerRead(kREGISTER_MC7), kBitROMDOUT)) shl I);
  end;

  EEPROMGetData := LData;
end;

procedure EEPROMSendData(const AData: Byte);
var
  I: Byte;

begin
  for I := 7 downto 0 do
  begin
    EEPROMDataOut(Boolean((AData shr I) and $01));
    EEPROMClockPulse;
  end;
end;

procedure EEPROMWriteDisable;
begin
  EEPROMSetCS(True);

  EEPROMSendCommand(kEEPROMCommandEWDS);

  EEPROMSetCS(False);
end;

procedure EEPROMWriteEnable;
begin
  EEPROMSetCS(True);

  EEPROMSendCommand(kEEPROMCommandEWEN);

  EEPROMSetCS(False);
end;

function EEPROMEraseAll: Boolean;
begin
  EEPROMSetCS(True);

  EEPROMSendCommand(kEEPROMCommandERAL);
  EEPROMEraseAll := EEPROMWaitReady;

  EEPROMSetCS(False);
end;

function EEPROMWriteAll(const AByte: Byte): Boolean;
begin
  EEPROMSetCS(True);

  EEPROMSendCommand(kEEPROMCommandWRAL);
  EEPROMSendData(AByte);
  EEPROMWriteAll := EEPROMWaitReady;

  EEPROMSetCS(False);
end;

function EEPROMErase(const AAddress: Word): Boolean;
begin
  EEPROMSetCS(True);

  EEPROMSendCommand(kEEPROMCommandERASE + AAddress);
  EEPROMErase := EEPROMWaitReady;

  EEPROMSetCS(False);
end;

function EEPROMRead(const AAddress: Word): Byte;
begin
  EEPROMSetCS(True);

  EEPROMSendCommand(kEEPROMCommandREAD + AAddress);
  EEPROMRead := EEPROMGetData;

  EEPROMSetCS(False);
end;

function EEPROMWrite(const AAddress: Word; const AByte: Byte): Boolean;
begin
  EEPROMSetCS(True);

  EEPROMSendCommand(kEEPROMCommandWRITE + AAddress);
  EEPROMSendData(AByte);
  EEPROMWrite := EEPROMWaitReady;

  EEPROMSetCS(False);
end;

{ public declarations }

function ControllerDetect: Boolean;
begin
  ControllerDetect := Detect82c924(dmPnP) or Detect82c924(dmnonPnP);
end;

function ControllerGetRevision: Byte;
var
  LData: Byte;

begin
  LData := ControllerRead(kREGISTER_MC3);
  ControllerGetRevision := (LData and $02) * 10 + (LData and $01);
end;

procedure ControllerResetRegisters;
begin
  ControllerWrite(kREGISTER_MC1, kREGISTER_MC1_Default);
  ControllerWrite(kREGISTER_MC2, kREGISTER_MC2_Default);
  ControllerWrite(kREGISTER_MC3, kREGISTER_MC3_Default);
  ControllerWrite(kREGISTER_MC4, kREGISTER_MC4_Default);
  ControllerWrite(kREGISTER_MC5, kREGISTER_MC5_Default);
  ControllerWrite(kREGISTER_MC6, kREGISTER_MC6_Default);
end;

function ControllerGetMode: TControllerMode;
begin
  if GetBit(ControllerRead(kREGISTER_MC1), kBitMOD) then
  begin
    ControllerGetMode := cmWSS;
  end else
  begin
    ControllerGetMode := cmSB;
  end;
end;

procedure ControllerSetMode(const AControllerMode: TControllerMode; const AControllerConfig: TControllerConfig);
begin
  SetConfig(AControllerMode, AControllerConfig);
end;

procedure ControllerAllowCodecAccess(const AControllerConfig: TControllerConfig);
begin
  ControllerSetMode(cmWSS, AControllerConfig);

  SetRegisterBit(kREGISTER_MC5, kBitSHPASS, False);
end;

procedure ControllerDisallowCodecAccess;
begin
  SetRegisterBit(kREGISTER_MC5, kBitSHPASS, True);
end;

procedure ControllerSBADPCM(const AEnable: Boolean);
begin
  SetRegisterBit(kREGISTER_MC4, kBitADPCMEN, AEnable);
end;

procedure ControllerAVC(const AEnable: Boolean);
begin
  SetRegisterBit(kREGISTER_MC5, kBitAVCEN, AEnable);
  SetRegisterBit(kREGISTER_MC5, kBitEPEN, AEnable);
end;

procedure ControllerSilence(const AEnable: Boolean);
begin
  SetRegisterBit(kREGISTER_MC4, kBitSILENCE, AEnable);
end;

procedure ControllerPowerDown(const AEnable: Boolean);
begin
  SetRegisterBit(kREGISTER_MC1, kBitPDN, AEnable);
end;

procedure ControllerChipTest(const AEnable: Boolean);
var
  LValue: Byte;

begin
  LValue := ControllerRead(kREGISTER_MC1);

  if AEnable then
  begin
    LValue := LValue or $0E;
  end else
  begin
    LValue := LValue and $F1;
  end;

  ControllerWrite(kREGISTER_MC1, LValue);
end;

function ControllerEraseEEPROM(AEraseMethod: TControllerEraseMethod; const AUpdateProgress: TUpdateProgress): Boolean;
var
  I: Word;
  LSucceeded: Boolean;

begin
  ControllerEraseEEPROM := False;

  LSucceeded := False;

  SetRegisterBit(kREGISTER_MC3, kBitWRSROM, True);

  EEPROMWriteEnable;

  case AEraseMethod of
    cemFast:
      begin
        LSucceeded := EEPROMEraseAll;
        if LSucceeded then
        begin
          for I := 0 to Pred(kEEPROMSize) do
          begin
            AUpdateProgress(I, $FF);
          end;
        end;
      end;

    cemSlow:
      begin
        for I := 0 to Pred(kEEPROMSize) do
        begin
          LSucceeded := EEPROMErase(I);
          if not LSucceeded then
          begin
            Break;
          end;

          AUpdateProgress(I, $FF);
        end;
      end;

  end;

  EEPROMWriteDisable;

  SetRegisterBit(kREGISTER_MC3, kBitWRSROM, False);

  ControllerEraseEEPROM := LSucceeded;
end;

function ControllerReadEEPROM(const AFileName: String; const AUpdateProgress: TUpdateProgress): Boolean;
var
  I: Word;
  LByte: Byte;
  LFile: File of Byte;

begin
  ControllerReadEEPROM := False;

  SetRegisterBit(kREGISTER_MC3, kBitWRSROM, True);

{$I-}
  Assign(LFile, AFileName);
  FileMode := fmReadWrite;
  Rewrite(LFile);
{$I+}
  for I := 0 to Pred(kEEPROMSize) do
  begin
    LByte := EEPROMRead(I);
{$I-}
    Write(LFile, LByte);
{$I+}
    if IOResult <> 0 then
    begin
      Break;
    end;

    AUpdateProgress(I, LByte);
  end;
{$I-}
  Close(LFile);
{$I+}

  SetRegisterBit(kREGISTER_MC3, kBitWRSROM, False);

  ControllerReadEEPROM := IOResult = 0;
end;

function ControllerWriteEEPROM(const AFileName: String; const AUpdateProgress: TUpdateProgress): Boolean;
var
  I: Word;
  LByte: Byte;
  LFile: File of Byte;
  LSucceeded: Boolean;

begin
  ControllerWriteEEPROM := False;

  LSucceeded := False;

  SetRegisterBit(kREGISTER_MC3, kBitWRSROM, True);

  EEPROMWriteEnable;

{$I-}
  Assign(LFile, AFileName);
  FileMode := fmReadOnly;
  Reset(LFile);
{$I+}
  for I := 0 to Pred(kEEPROMSize) do
  begin
{$I-}
    Read(LFile, LByte);
{$I+}
    if IOResult <> 0 then
    begin
      Break;
    end;

    LSucceeded := EEPROMWrite(I, LByte);
    if not LSucceeded then
    begin
      Break;
    end;

    AUpdateProgress(I, LByte);
  end;
{$I-}
  Close(LFile);
{$I+}

  EEPROMWriteDisable;

  SetRegisterBit(kREGISTER_MC3, kBitWRSROM, False);

  ControllerWriteEEPROM := (IOResult = 0) and LSucceeded;
end;

end.
