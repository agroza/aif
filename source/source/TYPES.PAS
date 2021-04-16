{ --------------------------------------------------------------------------- }
{ - Audio Interface - Types (types.pas)                                     - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Types;

interface

type
  { general program types }
  TAIFDetectionMode = (
    dmPnP,
    dmnonPnP
  );

  TAIFInitMode = (
    imInvalid,
    imSetup,
    imWSS,
    imSB
  );

  TParameters = record
    Setup: Boolean;
    PnPSetup: Boolean;
    Mixer: Boolean;
    InitMode: TAIFInitMode;
    Status: Boolean;
    Quiet: Boolean;
    LineOut: Boolean;
    LineOutRelay: Boolean;
  end;

  TBitStatus = (
    bsNotSet,
    bsSet
  );

  TUpdateProgress = procedure(const ABytes: Word; const AByte: Byte);

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
  TUICommand = record
    Y: Byte;
    Accelerator: PChar;
    Name: PChar;
  end;

  { PnP Setup types }
  TEEPROMOperation = (
    eoEraseFast,
    eoEraseSlow,
    eoRead,
    eoWrite
  );

implementation

end.
