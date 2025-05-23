{ --------------------------------------------------------------------------- }
{ - Audio Interface - PnP Setup Subprogram (pnpsetup.pas)                   - }
{ - Copyright (C) 1998-2022 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$G+}

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
  clForeground                 = clLightGray;
  clBackground                 = clBlue;

  clCmdHighlight               = clLightCyan;
  clCmdHeader                  = clWhite;
  clCmdForeground              = clLightGray;
  clCmdBackground              = clDarkGray;

  kStartupDelay                = 500;

  kUIComponentsLeft            = 1;
  kUIComponentsTop             = 2;
  kUIComponentsWidth           = 49;
  kUIComponentsHeight          = 24;

  kUICommandsLeft              = 50;
  kUICommandsTop               = 2;
  kUICommandsWidth             = 31;
  kUICommandsHeight            = 24;

  kUICommandX                  = 52;

  kUIProgramCommandY           = 3;
  kUICmdExitY                  = 4;

  kUICommandCount              = 0;

  kUICommands: packed array[0..kUICommandCount] of TUICommand = (
    ( Y: kUICmdExitY; Accelerator: sPnPSetupCmdESC; Name: sPnPSetupCmdExit )
  );

procedure UIComponentsDraw; forward;

procedure UICommandsDraw; forward;

procedure UIDraw; forward;
procedure UILoop; forward;

{ private declarations }

procedure UIComponentsDraw;
begin
  VideoWriteRegion(
    kUIComponentsLeft,
    kUIComponentsTop,
    kUIComponentsWidth,
    kUIComponentsHeight,
    cSpace,
    VideoAttribute(
      clForeground,
      clBackground
    )
  );

  { TODO -oagroza -cRemove : Temporary code. }
  VideoWriteStringAt(
    2,
    3,
    'PnP Setup is not available at this moment.',
    clForeground,
    clBackground
  );
end;

procedure UICommandsDraw;
var
  LUICommand: Byte;

begin
  VideoWriteRegion(
    kUICommandsLeft,
    kUICommandsTop,
    kUICommandsWidth,
    kUICommandsHeight,
    cSpace,
    VideoAttribute(
      clCmdForeground,
      clCmdBackground
    )
  );

  VideoWriteStringAt(
    kUICommandX,
    kUIProgramCommandY,
    sPnPSetupCmdProgramCmds,
    clCmdHeader,
    clCmdBackground
  );

  for LUICommand := Low(kUICommands) to High(kUICommands) do
  begin
    ScreenCommandDraw(
      kUICommandX,
      kUICommands[LUICommand].Y,
      clCmdHighlight,
      clCmdForeground,
      clCmdBackground,
      StrPas(kUICommands[LUICommand].Accelerator),
      StrPas(kUICommands[LUICommand].Name)
    );
  end;
end;

procedure UIDraw;
begin
  ScreenTitleBarDraw(clInterfaceFore, clInterfaceBack, clInterfaceFore, sPnPSetupTitle);

  UIComponentsDraw;

  UICommandsDraw;
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
  Routines.Delay(kStartupDelay);

  VideoInitialize(LPositionY, LVideoRAMData);
  ScreenInitialize;

  UIDraw;
  UILoop;

  ScreenFinalize;
  VideoFinalize(LPositionY, LVideoRAMData);
end;

end.
