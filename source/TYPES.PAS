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

  TBitDepth = (
    bd8bit,
    bd16bit
  );

  TSoundOutput = (
    soMono,
    soStereo
  );

  TSoundChannel = (
    scLeft,
    scRight,
    scLeftRight
  );

  TSampleRate = (
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

  TSBDSPVersion = (
    sdVersion21,
    sdVersion15,
    sdVersion32,
    sdVersion44
  );

  TControllerMode = (
    cmWSS,
    cmSB
  );

implementation

end.
