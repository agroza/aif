{ --------------------------------------------------------------------------- }
{ - Audio Interface - Mixer Subprogram (mixer.pas)                          - }
{ - Copyright (C) 1998-2022 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Mixer;

interface

uses
  Types;

function MixerSetConfig(const AInitMode: TAIFInitMode): Boolean;

procedure MixerDefaultConfig;

function MixerStart: Boolean;

implementation

uses
  Codec,
  Control,
  Consts,
  Routines,
  Setup,
  Screen,
  Video;

type
  TStereoSlider = (
    ssDACStereoSlider,
    ssAUX1StereoSlider,
    ssAUX2StereoSlider,
    ssInputGainStereoSlider,
    ssDMEStereoSlider
  );

  TMixerOption = (
    moLineIn,
    moFMAUXIn,
    moMicrophone,
    moPostMixedDAC,
    moMicrophoneGain,
    moDigitalMix,
    moOutputsEnabled
  );

  TMixerOptionData = packed record
    PositionY: Byte;
    Enabled: Boolean;
  end;

var
  IGMixerConfigChanged: Boolean;
  IGStereoSliders: packed array[TStereoSlider] of TStereoSliderData;
  IGMixerOptions: packed array[TMixerOption] of TMixerOptionData;
  IGMessageBox: TMessageBoxData;

const
  kUIStatCommands: packed array[0..kMixerStatCmdCount] of TUICommand = (
    ( Y: 4; Accelerator: sMixerCmdF8; Name: sMixerCmdDefaultConfig ),
    ( Y: 5; Accelerator: sMixerCmdF9; Name: sMixerCmdReloadConfig ),
    ( Y: 6; Accelerator: sMixerCmdF10; Name: sMixerCmdSaveExit ),
    ( Y: 8; Accelerator: sMixerCmdESC; Name: sMixerCmdExit ),
    ( Y: 11; Accelerator: sMixerCmdUpDown; Name: sMixerCmdSelectDevice ),
    ( Y: 12; Accelerator: sMixerCmdLeftRight; Name: sMixerCmdModifyVolume )
  );

  kUIDynCommands: packed array[0..kMixerDynCmdCount] of TUICommand = (
    ( Y: 16; Accelerator: sMixerCmd1; Name: sMixerCmdLineIn ),
    ( Y: 17; Accelerator: sMixerCmd2; Name: sMixerCmdFMAUXIn ),
    ( Y: 18; Accelerator: sMixerCmd3; Name: sMixerCmdMicrophone ),
    ( Y: 19; Accelerator: sMixerCmd4; Name: sMixerCmdPostMixedDAC ),
    ( Y: 22; Accelerator: sMixerCmd5; Name: sMixerCmdMicrophoneGain ),
    ( Y: 23; Accelerator: sMixerCmd6; Name: sMixerCmdDigitalMix ),
    ( Y: 24; Accelerator: sMixerCmd7; Name: sMixerCmdOutputsEnabled )
  );

{ private declarations }

procedure SetVolumes;
begin
  GCodecMixerConfig.DACLeft := IGStereoSliders[ssDACStereoSlider].LeftPosition;
  GCodecMixerConfig.DACRight := IGStereoSliders[ssDACStereoSlider].RightPosition;
  GCodecMixerConfig.AUX1Left := IGStereoSliders[ssAUX1StereoSlider].LeftPosition;
  GCodecMixerConfig.AUX1Right := IGStereoSliders[ssAUX1StereoSlider].RightPosition;
  GCodecMixerConfig.AUX2Left := IGStereoSliders[ssAUX2StereoSlider].LeftPosition;
  GCodecMixerConfig.AUX2Right := IGStereoSliders[ssAUX2StereoSlider].RightPosition;
  GCodecMixerConfig.InputGainLeft := IGStereoSliders[ssInputGainStereoSlider].LeftPosition div 2;
  GCodecMixerConfig.InputGainRight := IGStereoSliders[ssInputGainStereoSlider].RightPosition div 2;
  GCodecMixerConfig.DMELeftRight := IGStereoSliders[ssDMEStereoSlider].LeftPosition * 4;
end;

procedure InitSlider(const AStereoSlider: TStereoSlider; const APositionY: Byte;
  const ATitle: String; const ALocked: Boolean; const ALeftPosition, ARightPosition: Byte);
begin
  IGStereoSliders[AStereoSlider].PositionX := kMixerSliderX;
  IGStereoSliders[AStereoSlider].PositionY := APositionY;
  IGStereoSliders[AStereoSlider].Title := ATitle;
  IGStereoSliders[AStereoSlider].Colors.Foreground := clMixerSliderFore;
  IGStereoSliders[AStereoSlider].Colors.Background := clMixerSliderBack;
  IGStereoSliders[AStereoSlider].Colors.Title := clMixerSliderTitle;
  IGStereoSliders[AStereoSlider].Colors.Text := clMixerSliderText;
  IGStereoSliders[AStereoSlider].Colors.HighForeground := clMixerSliderHighFore;
  IGStereoSliders[AStereoSlider].Colors.HighBackground := clMixerSliderHighBack;
  IGStereoSliders[AStereoSlider].Colors.Grid := clMixerSliderGrid;
  IGStereoSliders[AStereoSlider].Colors.Tip := clMixerSliderTip;
  IGStereoSliders[AStereoSlider].Colors.Normal := clMixerSliderNormal;
  IGStereoSliders[AStereoSlider].Colors.Low := clMixerSliderLow;
  IGStereoSliders[AStereoSlider].Colors.Medium := clMixerSliderMedium;
  IGStereoSliders[AStereoSlider].Colors.High := clMixerSliderHigh;
  IGStereoSliders[AStereoSlider].Colors.VeryHigh := clMixerSliderVeryHigh;
  IGStereoSliders[AStereoSlider].Min := kMixerSliderMin;
  IGStereoSliders[AStereoSlider].Max := kMixerSliderMax;
  IGStereoSliders[AStereoSlider].Locked := ALocked;
  IGStereoSliders[AStereoSlider].LeftPosition := ALeftPosition;
  IGStereoSliders[AStereoSlider].RightPosition := ARightPosition;
end;

procedure CreateComponents;
begin
  InitSlider(
    ssDACStereoSlider,
    kMixerDACSliderY,
    sMixerVolumeDAC,
    False,
    GCodecMixerConfig.DACLeft,
    GCodecMixerConfig.DACRight
  );

  InitSlider(
    ssAUX1StereoSlider,
    kMixerAUX1SliderY,
    sMixerVolumeFMAUXIn,
    False,
    GCodecMixerConfig.AUX1Left,
    GCodecMixerConfig.AUX1Right
  );

  InitSlider(
    ssAUX2StereoSlider,
    kMixerAUX2SliderY,
    sMixerVolumeCDROMLineIn,
    False,
    GCodecMixerConfig.AUX2Left,
    GCodecMixerConfig.AUX2Right
  );

  InitSlider(
    ssInputGainStereoSlider,
    kMixerInputGainSliderY,
    sMixerVolumeADCInputGain,
    False,
    GCodecMixerConfig.InputGainLeft,
    GCodecMixerConfig.InputGainRight
  );

  InitSlider(
    ssDMEStereoSlider,
    kMixerDMESliderY,
    sMixerVolumeDME,
    True,
    GCodecMixerConfig.DMELeftRight,
    GCodecMixerConfig.DMELeftRight
  );

  IGMessageBox.Colors.Foreground := clMessageBoxFore;
  IGMessageBox.Colors.Background := clMessageBoxBack;
  IGMessageBox.Colors.BtnForeground := clMessageBoxBtnFore;
  IGMessageBox.Colors.BtnBackground := clMessageBoxBtnBack;
  IGMessageBox.Colors.BtnAccelerator := clMessageBoxBtnAccel;
  IGMessageBox.Colors.BtnHighForeground := clMessageBoxBtnHighFore;
  IGMessageBox.Colors.BtnHighBackground := clMessageBoxBtnHighBack;
  IGMessageBox.Colors.BtnHighAccelerator := clMessageBoxBtnHighAccel;

  ScreenMessageBoxPrepare(
    IGMessageBox,
    sMessageBoxQuestion,
    sMixerConfigChanged,
    [mbYes, mbNo],
    mbNo
  );
end;

procedure DrawComponents;
begin
  VideoWriteRegion(
    kMixerSlidersLeft,
    kMixerSlidersTop,
    kMixerSlidersWidth,
    kMixerSlidersHeight,
    cSpace,
    VideoAttribute(
      clMixerFore,
      clMixerBack
    )
  );

  ScreenStereoSliderDraw(IGStereoSliders[ssDACStereoSlider]);
  ScreenStereoSliderDraw(IGStereoSliders[ssAUX1StereoSlider]);
  ScreenStereoSliderDraw(IGStereoSliders[ssAUX2StereoSlider]);
  ScreenStereoSliderDraw(IGStereoSliders[ssInputGainStereoSlider]);
  ScreenStereoSliderDraw(IGStereoSliders[ssDMEStereoSlider]);
end;

procedure DrawCommands;
var
  LUIStatCommand: Byte;

begin
  VideoWriteRegion(
    kMixerCommandsLeft,
    kMixerCommandsTop,
    kMixerCommandsWidth,
    kMixerCommandsHeight,
    cSpace,
    VideoAttribute(
      clStatCmdFore,
      clStatCmdBack
    )
  );

  VideoWriteStringAt(
    kMixerCmdX,
    3,
    sMixerCmdProgramCmds,
    clStatCmdHeader,
    clStatCmdBack
  );

  VideoWriteStringAt(
    kMixerCmdX,
    10,
    sMixerCmdVolumeCmds,
    clStatCmdHeader,
    clStatCmdBack
  );

  for LUIStatCommand := Low(kUIStatCommands) to High(kUIStatCommands) do
  begin
    ScreenCommandDraw(
      kMixerCmdX,
      kUIStatCommands[LUIStatCommand].Y,
      clMixerCmdHigh,
      clStatCmdFore,
      clStatCmdBack,
      StrPas(kUIStatCommands[LUIStatCommand].Accelerator),
      StrPas(kUIStatCommands[LUIStatCommand].Name)
    );
  end;
end;

procedure SetInputConfigOptions;
begin
  if IGMixerOptions[moLineIn].Enabled then
  begin
    GCodecMixerConfig.InputDeviceLeft := cidtLineIn;
    GCodecMixerConfig.InputDeviceRight := cidtLineIn;
  end else
  if IGMixerOptions[moFMAUXIn].Enabled then
  begin
    GCodecMixerConfig.InputDeviceLeft := cidtAUX1In;
    GCodecMixerConfig.InputDeviceRight := cidtAUX1In;
  end else
  if IGMixerOptions[moMicrophone].Enabled then
  begin
    GCodecMixerConfig.InputDeviceLeft := cidtMicrophone;
    GCodecMixerConfig.InputDeviceRight := cidtMicrophone;
  end else
  if IGMixerOptions[moPostMixedDAC].Enabled then
  begin
    GCodecMixerConfig.InputDeviceLeft := cidtPostMixedDAC;
    GCodecMixerConfig.InputDeviceRight := cidtPostMixedDAC;
  end;

  GCodecMixerConfig.MicGainLeft := IGMixerOptions[moMicrophoneGain].Enabled;
  GCodecMixerConfig.MicGainRight := IGMixerOptions[moMicrophoneGain].Enabled;

  GCodecMixerConfig.DigitalMix := IGMixerOptions[moDigitalMix].Enabled;

  GCodecMixerConfig.OutputsEnabled := IGMixerOptions[moOutputsEnabled].Enabled;
end;

procedure InitOption(var AOptionData: TMixerOptionData; const APositionY: Byte; const AEnabled: Boolean);
begin
  AOptionData.PositionY := APositionY;
  AOptionData.Enabled := AEnabled;
end;

procedure InitOptions;
begin
  InitOption(IGMixerOptions[moLineIn], 16, GCodecMixerConfig.InputDeviceLeft = cidtLineIn);
  InitOption(IGMixerOptions[moFMAUXIn], 17, GCodecMixerConfig.InputDeviceLeft = cidtAUX1In);
  InitOption(IGMixerOptions[moMicrophone], 18, GCodecMixerConfig.InputDeviceLeft = cidtMicrophone);
  InitOption(IGMixerOptions[moPostMixedDAC], 19, GCodecMixerConfig.InputDeviceLeft = cidtPostMixedDAC);
  InitOption(IGMixerOptions[moMicrophoneGain], 22, GCodecMixerConfig.MicGainLeft or GCodecMixerConfig.MicGainRight);
  InitOption(IGMixerOptions[moDigitalMix], 23, GCodecMixerConfig.DigitalMix);
  InitOption(IGMixerOptions[moOutputsEnabled], 24, GCodecMixerConfig.OutputsEnabled);
end;

procedure DrawOptions;
var
  LUIDynCommand: Byte;

begin
  VideoWriteRegion(
    kMixerOptionsLeft,
    kMixerOptionsTop,
    kMixerOptionsWidth,
    kMixerOptionsHeight,
    cSpace,
    VideoAttribute(
      clDynCmdFore,
      clDynCmdBack
    )
  );

  VideoWriteStringAt(
    kMixerCmdX,
    15,
    sMixerCmdInputDeviceCmds,
    clDynCmdHeader,
    clDynCmdBack
  );

  VideoWriteStringAt(
    kMixerCmdX,
    21,
    sMixerCmdAdditionalCmds,
    clDynCmdHeader,
    clDynCmdBack
  );

  for LUIDynCommand := Low(kUIDynCommands) to High(kUIDynCommands) do
  begin
    ScreenCommandDraw(
      kMixerCmdX,
      kUIDynCommands[LUIDynCommand].Y,
      clMixerCmdHigh,
      clDynCmdFore,
      clDynCmdBack,
      StrPas(kUIDynCommands[LUIDynCommand].Accelerator),
      StrPas(kUIDynCommands[LUIDynCommand].Name)
    );
  end;
end;

procedure HighlightOption(const AOption: TMixerOption);
var
  LAttribute: Byte;

begin
  if IGMixerOptions[AOption].Enabled then
  begin
    LAttribute := VideoAttribute(clLightGreen, clDynCmdBack);
  end else
  begin
    LAttribute := VideoAttribute(clDynCmdFore, clDynCmdBack);
  end;

  VideoHighlightRegion(
    kMixerOptionX,
    IGMixerOptions[AOption].PositionY,
    kMixerOptionWidth,
    kMixerOptionHeight,
    LAttribute
  );
end;

procedure HighlightOptions;
var
  LOption: TMixerOption;

begin
  for LOption := Low(TMixerOption) to High(TMixerOption) do
  begin
    HighlightOption(LOption);
  end;
end;

procedure ToggleHighlightOption(const AOption: TMixerOption);
begin
  IGMixerConfigChanged := True;

  IGMixerOptions[AOption].Enabled := not IGMixerOptions[AOption].Enabled;
  HighlightOption(AOption);
end;

procedure HighlightInputDevice(const AOption: TMixerOption);
var
  LOption: TMixerOption;

begin
  IGMixerConfigChanged := True;

  for LOption := moLineIn to moPostMixedDAC do
  begin
    IGMixerOptions[LOption].Enabled := False;
    HighlightOption(LOption);
  end;

  IGMixerOptions[AOption].Enabled := True;
  HighlightOption(AOption);
end;

procedure DrawConfig;
begin
  CreateComponents;
  DrawComponents;

  InitOptions;
  DrawOptions;
  HighlightOptions;
end;

procedure UIDraw;
begin
  ScreenTitleBarDraw(clInterfaceFore, clInterfaceBack, clInterfaceFore, sMixerTitle);

  DrawCommands;
  DrawConfig;
end;

procedure ExitAndSave;
begin
  SetVolumes;
  SetInputConfigOptions;
  SetupSaveConfig;
end;

procedure UILoop;
var
  LScanCode: Word;
  LKey: Char;
  LStereoSlider: TStereoSlider;
  LSoundChannel: TCodecSoundChannel;

begin
  IGMixerConfigChanged := False;

  LStereoSlider := ssDACStereoSlider;
  LSoundChannel := scLeft;
  ScreenStereoSliderHighlight(IGStereoSliders[LStereoSlider], LSoundChannel, True);

  while True do
  begin
    LScanCode := GetScanCode;
    LKey := UpCase(GetStandardKey(LScanCode));

    case LKey of
      kKeyExtended:
        begin
          case GetExtendedKey(LScanCode) of
            kKeyF8:
              begin
                IGMixerConfigChanged := True;

                MixerDefaultConfig;
                DrawConfig;

                ScreenStereoSliderHighlight(IGStereoSliders[LStereoSlider], LSoundChannel, True);
              end;

            kKeyF9:
              begin
                if SetupLoadConfig then
                begin
                  IGMixerConfigChanged := True;

                  DrawConfig;
                end;

                ScreenStereoSliderHighlight(IGStereoSliders[LStereoSlider], LSoundChannel, True);
              end;

            kKeyF10:
              begin
                ExitAndSave;

                Break;
              end;

            kKeyUp:
              begin
                ScreenStereoSliderHighlight(IGStereoSliders[LStereoSlider], LSoundChannel, False);

                case LSoundChannel of
                  scLeft:
                    begin
                      Inc(LSoundChannel);

                      if LStereoSlider > Low(TStereoSlider) then
                      begin
                        Dec(LStereoSlider);
                      end else
                      begin
                        LStereoSlider := High(TStereoSlider);
                      end;
                    end;

                  scRight:
                    begin
                      Dec(LSoundChannel);
                    end;

                end;

                ScreenStereoSliderHighlight(IGStereoSliders[LStereoSlider], LSoundChannel, True);
              end;

            kKeyDown:
              begin
                ScreenStereoSliderHighlight(IGStereoSliders[LStereoSlider], LSoundChannel, False);

                case LSoundChannel of
                  scLeft:
                    begin
                      Inc(LSoundChannel);
                    end;

                  scRight:
                    begin
                      Dec(LSoundChannel);

                      if LStereoSlider < High(TStereoSlider) then
                      begin
                        Inc(LStereoSlider);
                      end else
                      begin
                        LStereoSlider := Low(TStereoSlider);
                      end;
                    end;

                end;

                ScreenStereoSliderHighlight(IGStereoSliders[LStereoSlider], LSoundChannel, True);
              end;

            kKeyLeft:
              begin
                IGMixerConfigChanged := True;
                ScreenStereoSliderMove(IGStereoSliders[LStereoSlider], LSoundChannel, sdDown);
              end;

            kKeyRight:
              begin
                IGMixerConfigChanged := True;
                ScreenStereoSliderMove(IGStereoSliders[LStereoSlider], LSoundChannel, sdUp);
              end;

          end;
        end;

      kKeyEscape:
        begin
          if IGMixerConfigChanged then
          begin
            case ScreenMessageBoxDraw(IGMessageBox) of
              mrCancel:
                Continue;

              mrNo:
                IGMixerConfigChanged := False;

              mrYes:
                ExitAndSave;

            end;
          end;

          Break;
        end;

      sMixerCmd1:
        HighlightInputDevice(moLineIn);

      sMixerCmd2:
        HighlightInputDevice(moFMAUXIn);

      sMixerCmd3:
        HighlightInputDevice(moMicrophone);

      sMixerCmd4:
        HighlightInputDevice(moPostMixedDAC);

      sMixerCmd5:
        ToggleHighlightOption(moMicrophoneGain);

      sMixerCmd6:
        ToggleHighlightOption(moDigitalMix);

      sMixerCmd7:
        ToggleHighlightOption(moOutputsEnabled);

    end;
  end;
end;

{ public declarations }

function MixerSetConfig(const AInitMode: TAIFInitMode): Boolean;
begin
  ControllerAllowCodecAccess(GControllerConfig);

  CodecSetVolume(cdtDAC, scLeft, GCodecMixerConfig.DACLeft);
  CodecSetVolume(cdtDAC, scRight, GCodecMixerConfig.DACRight);
  CodecSetVolume(cdtAUX1, scLeft, GCodecMixerConfig.AUX1Left);
  CodecSetVolume(cdtAUX1, scRight, GCodecMixerConfig.AUX1Right);
  CodecSetVolume(cdtAUX2, scLeft, GCodecMixerConfig.AUX2Left);
  CodecSetVolume(cdtAUX2, scRight, GCodecMixerConfig.AUX2Right);

  CodecSetInputConfig(GCodecMixerConfig.InputDeviceLeft, GCodecMixerConfig.MicGainLeft,
    GCodecMixerConfig.InputGainLeft, scLeft);
  CodecSetInputConfig(GCodecMixerConfig.InputDeviceRight, GCodecMixerConfig.MicGainRight,
    GCodecMixerConfig.InputGainRight, scRight);

  CodecSetDigitalMix(GCodecMixerConfig.DigitalMix, GCodecMixerConfig.DMELeftRight);

  MixerSetConfig :=
    (CodecGetVolume(cdtDAC, scLeft) = GCodecMixerConfig.DACLeft) and
    (CodecGetVolume(cdtDAC, scRight) = GCodecMixerConfig.DACRight) and
    (CodecGetVolume(cdtAUX1, scLeft) = GCodecMixerConfig.AUX1Left) and
    (CodecGetVolume(cdtAUX1, scRight) = GCodecMixerConfig.AUX1Right) and
    (CodecGetVolume(cdtAUX2, scLeft) = GCodecMixerConfig.AUX2Left) and
    (CodecGetVolume(cdtAUX2, scRight) = GCodecMixerConfig.AUX2Right) and
    (CodecGetInputDevice(scLeft) = GCodecMixerConfig.InputDeviceLeft) and
    (CodecGetInputDevice(scRight) = GCodecMixerConfig.InputDeviceRight) and
    (CodecGetMicGain(scLeft) = GCodecMixerConfig.MicGainLeft) and
    (CodecGetMicGain(scRight) = GCodecMixerConfig.MicGainRight) and
    (CodecGetInputGain(scLeft) = GCodecMixerConfig.InputGainLeft) and
    (CodecGetInputGain(scRight) = GCodecMixerConfig.InputGainRight);

  CodecSetOutputsEnabled(GCodecMixerConfig.OutputsEnabled);

  if AInitMode = imSB then
  begin
    ControllerSetMode(cmSB, GControllerConfig);
  end;

  ControllerDisallowCodecAccess;
end;

procedure MixerDefaultConfig;
begin
  GCodecMixerConfig.DACLeft := kMixerDACDefault;
  GCodecMixerConfig.DACRight := kMixerDACDefault;
  GCodecMixerConfig.AUX1Left := kMixerAUX1Default;
  GCodecMixerConfig.AUX1Right := kMixerAUX1Default;
  GCodecMixerConfig.AUX2Left := kMixerAUX2Default;
  GCodecMixerConfig.AUX2Right := kMixerAUX2Default;
  GCodecMixerConfig.InputDeviceLeft := kMixerInputDeviceDefault;
  GCodecMixerConfig.InputDeviceRight := kMixerInputDeviceDefault;
  GCodecMixerConfig.InputGainLeft := kMixerInputGainDefault;
  GCodecMixerConfig.InputGainRight := kMixerInputGainDefault;
  GCodecMixerConfig.MicGainLeft := kMixerMicGainDefault;
  GCodecMixerConfig.MicGainRight := kMixerMicGainDefault;
  GCodecMixerConfig.DigitalMix := kMixerDigitalMixDefault;
  GCodecMixerConfig.DMELeftRight := kMixerDMEDefault;
  GCodecMixerConfig.OutputsEnabled := kMixerOutputsEnDefault;
end;

function MixerStart: Boolean;
var
  LPositionY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kMixerStartupDelay);

  VideoInitialize(LPositionY, LVideoRAMData);
  ScreenInitialize;

  UIDraw;
  UILoop;

  ScreenFinalize;
  VideoFinalize(LPositionY, LVideoRAMData);

  MixerStart := IGMixerConfigChanged;
end;

end.
