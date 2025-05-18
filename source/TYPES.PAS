{ --------------------------------------------------------------------------- }
{ - Audio Interface - Types (types.pas)                                     - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$G+}

unit Types;

{$I cdefines.inc}

interface

type
  { general program types }
  TProgramError = (
    peHardwareInit,
    peControllerReinit
{$IFDEF CDPLAYER},
    peCDROMDriverInit
{$ENDIF}
  );

  TAIFDetectionMode = (
    dmPnP,
    dmnonPnP
  );

  TAIFInitMode = (
    imInvalid,
    imNoInit,
    imSetup,
    imWSS,
    imSB
  );

  TParameters = packed record
    ROMSetup: Boolean;
{$IFDEF PNPSETUP}
    PnPSetup: Boolean;
{$ENDIF}
    Setup: Boolean;
    Mixer: Boolean;
    LineOut: Boolean;
    LineOutRelay: Boolean;
    InitMode: TAIFInitMode;
    Quiet: Boolean;
{$IFDEF CDPLAYER}
    CDPlayer: Boolean;
{$ENDIF}
    Status: Boolean;
  end;

  TBitStatus = (
    bsNotSet,
    bsSet
  );

  TUpdateProgress = procedure(const ABytes: Word; const AByte: Byte);

  PStrings = ^TStrings;
  TStrings = packed array[0..0] of String;

  TFileSignature = packed array[0..7] of Char;

  { codec types }
  TCodecSampleRate = (
    sr5512,
    sr6615,
    sr8000,
    sr9600,
    sr11025,
    sr16000,
    sr18900,
    sr22050,
    sr27428,
    sr32000,
    sr33075,
    sr37800,
    sr44100,
    sr48000
  );

  TCodecBitDepth = (
    bd8bit,
    bd16bit
  );

  TCodecSoundOutput = (
    soMono,
    soStereo
  );

  TCodecSoundChannel = (
    scLeft,
    scRight,
    scLeftRight
  );

  TCodecDeviceType = (
    cdtAUX1,
    cdtAUX2,
    cdtDAC
  );

  TCodecInputDeviceType = (
    cidtLineIn,
    cidtAUX1In,
    cidtMicrophone,
    cidtPostMixedDAC
  );

  TCodecOutputFormat = (
    cof8bitUlawCompanded,
    cof8bitAlawCompanded,
    cof8bitUnsignedPCM,
    cof16bitTwosComplementPCM
  );

  TCodecSBDSPVersion = (
    sdVersion21,
    sdVersion15,
    sdVersion32,
    sdVersion44
  );

  { controller types }
  TControllerMode = (
    cmWSS,
    cmSB
  );

  TControllerEraseMethod = (
    cemFast,
    cemSlow
  );

  { UI types }
  TUICommand = packed record
    Y: Byte;
    Accelerator: PChar;
    Name: PChar;
  end;

  TUIKeyValue = packed record
    Y: Byte;
    Key: PChar;
    Value: PChar;
  end;

implementation

end.
