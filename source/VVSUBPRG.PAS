{ --------------------------------------------------------------------------- }
{ - Audio Interface - VersaVision Subprogram Runtime (vvsubprg.pas)         - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$I cdefines.inc}

{$IFDEF CPU16BIT}
  {$G+}
{$ENDIF}

unit VVSubPrg;

interface

type
  TVVSubPrgCallback = function: Boolean;

function VVSubPrgExecute(const ACallback: TVVSubPrgCallback): Boolean;

implementation

uses
  Routines,
  Screen,
  Video;

const
  kVVSubPrgStartupDelay        = 500;

{ public declarations }

function VVSubPrgExecute(const ACallback: TVVSubPrgCallback): Boolean;
var
  LPositionY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kVVSubPrgStartupDelay);

  VideoInitialize(LPositionY, LVideoRAMData);
  ScreenInitialize;

  VVSubPrgExecute := ACallback;

  ScreenFinalize;
  VideoFinalize(LPositionY, LVideoRAMData);
end;

end.
