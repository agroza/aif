{ --------------------------------------------------------------------------- }
{ - Audio Interface - PnP Setup Subprogram (pnpsetup.pas)                   - }
{ - Copyright (C) 1998-2022 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit PnPSetup;

interface

procedure PnPSetupStart;

implementation

uses
  Consts,
  Routines,
  Screen,
  Types,
  Video;

const
  kUICommands: packed array[0..kPnPSetupCmdCount] of TUICommand = (
    ( Y: 4; Accelerator: sPnPSetupCmdESC; Name: sPnPSetupCmdExit )
  );

{ private declarations }

procedure UIDrawComponents; forward;
procedure UIDrawCommands; forward;
procedure UIDraw; forward;
procedure UILoop; forward;

procedure UIDrawComponents;
begin
  VideoWriteRegion(
    kPnPSetupComponentsLeft,
    kPnPSetupComponentsTop,
    kPnPSetupComponentsWidth,
    kPnPSetupComponentsHeight,
    cSpace,
    VideoAttribute(
      clPnPSetupFore,
      clPnPSetupBack
    )
  );

  { TODO -oagroza -cRemove : Temporary code. }
  VideoWriteStringAt(
    2,
    3,
    'PnP Setup is not available at this moment.',
    clPnPSetupFore,
    clPnPSetupBack
  );
end;

procedure UIDrawCommands;
var
  LUICommand: Byte;

begin
  VideoWriteRegion(
    kPnPSetupCommandsLeft,
    kPnPSetupCommandsTop,
    kPnPSetupCommandsWidth,
    kPnPSetupCommandsHeight,
    cSpace,
    VideoAttribute(
      clPnPSetupCmdFore,
      clPnPSetupCmdBack
    )
  );

  VideoWriteStringAt(
    kPnPSetupCmdX,
    3,
    sPnPSetupCmdProgramCmds,
    clPnPSetupCmdHeader,
    clPnPSetupCmdBack
  );

  for LUICommand := Low(kUICommands) to High(kUICommands) do
  begin
    ScreenCommandDraw(
      kPnPSetupCmdX,
      kUICommands[LUICommand].Y,
      clPnPSetupCmdHigh,
      clPnPSetupCmdFore,
      clPnPSetupCmdBack,
      StrPas(kUICommands[LUICommand].Accelerator),
      StrPas(kUICommands[LUICommand].Name)
    );
  end;
end;

procedure UIDraw;
begin
  ScreenTitleBarDraw(clInterfaceFore, clInterfaceBack, clInterfaceFore, sPnPSetupTitle);

  UIDrawComponents;
  UIDrawCommands;
end;

procedure UILoop;
var
  LScanCode: Word;
  LKey: Char;

begin
  while True do
  begin
    LScanCode := GetScanCode;
    LKey := UpCase(GetStandardKey(LScanCode));

    case LKey of
      kKeyEscape:
        Break;

    end;
  end;
end;

{ public declarations }

procedure PnPSetupStart;
var
  LPositionY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kPnPSetupStartupDelay);

  VideoInitialize(LPositionY, LVideoRAMData);
  ScreenInitialize;

  UIDraw;
  UILoop;

  ScreenFinalize;
  VideoFinalize(LPositionY, LVideoRAMData);
end;

end.
