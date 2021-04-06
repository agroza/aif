{ --------------------------------------------------------------------------- }
{ - Audio Interface - PnP Setup Subprogram (pnpsetup.pas)                   - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit PnPSetup;

interface

procedure PnPSetupStart;

implementation

uses
  Crt,
  Consts,
  Routines,
  Screen,
  Types,
  Video;

const
  kUICommands: array[0..0] of TUICommand = (
    ( Y: 7; Accelerator: sPnPSetupCmdESC; Name: sPnPSetupCmdExit )
  );

{ private declarations }

procedure DrawOptions;
begin
  VideoWriteRegion(kPnPSetupOptionsLeft, kPnPSetupOptionsTop, kPnPSetupOptionsWidth,
    kPnPSetupOptionsHeight, cSpace, VideoAttribute(clPnPSetupFore, clPnPSetupBack));
end;

procedure DrawCommands;
var
  I: Byte;

begin
  VideoWriteRegion(kPnPSetupCommandsLeft, kPnPSetupCommandsTop, kPnPSetupCommandsWidth,
    kPnPSetupCommandsHeight, cSpace, VideoAttribute(clPnPSetupCmdFore, clPnPSetupCmdBack));

  VideoWriteStringAt(kPnPSetupCmdX, 3, sPnPSetupCmdProgramCmds, clPnPSetupCmdHeader, clPnPSetupCmdBack);

  for I := Low(kUICommands) to High(kUICommands) do
  begin
    ScreenDrawCommand(kPnPSetupCmdX, kUICommands[I].Y, clPnPSetupCmdHigh, clPnPSetupCmdFore,
      clPnPSetupCmdBack, StrPas(kUICommands[I].Accelerator), StrPas(kUICommands[I].Name));
  end;
end;

procedure DrawConfig;
begin
  DrawOptions;
end;

procedure UIDraw;
begin
  ScreenDrawTitleBar(clInterfaceFore, clInterfaceBack, clInterfaceFore, sPnPSetupTitle);

  DrawConfig;
  DrawCommands;
end;

procedure UILoop;
begin
  while True do
  begin
    case UpCase(ReadKey) of
      kKeyExtended:
        begin
          case ReadKey of
            kKeyF8:
              begin

              end;

            kKeyF9:
              begin

              end;

            kKeyF10:
              begin
                ;
              end;

          end;
        end;

      kKeyEscape:
        Break;

    end;
  end;
end;

{ public declarations }

procedure PnPSetupStart;
var
  LSaveY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kPnPSetupStartupDelay);

  LSaveY := WhereY;

  GetMem(LVideoRAMData, kVGARAMSize);
  VideoSaveScreen(LVideoRAMData);
  VideoClearScreen;
  VideoEnableHighColors;
  VideoDisableCursor;

  ScreenSetVVColors;

  UIDraw;
  UILoop;

  ScreenRestoreColors;

  VideoEnableCursor;
  VideoDisableHighColors;
  VideoRestoreScreen(LVideoRAMData);
  FreeMem(LVideoRAMData, kVGARAMSize);

  GotoXY(k80x25Left, LSaveY);
end;

end.
