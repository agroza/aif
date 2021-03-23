{ --------------------------------------------------------------------------- }
{ - Audio Interface - Mixer Subprogram (mixer.pas)                          - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
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

procedure MixerStart;

implementation

uses
  Crt,
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

  TMixerOptionData = record
    PositionY: Byte;
    Enabled: Boolean;
  end;

const
  kMixerDACSliderY       = 2;
  kMixerAUX1SliderY      = 7;
  kMixerAUX2SliderY      = 12;
  kMixerInputGainSliderY = 17;
  kMixerDMESliderY       = 22;

  kMixerSliderMin        = 0;
  kMixerSliderMax        = 30;

var
  IGStereoSliders: array[TStereoSlider] of TStereoSliderData;
  IGMixerOptions: array[TMixerOption] of TMixerOptionData;

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
  IGStereoSliders[AStereoSlider].Min := kMixerSliderMin;
  IGStereoSliders[AStereoSlider].Max := kMixerSliderMax;
  IGStereoSliders[AStereoSlider].Locked := ALocked;
  IGStereoSliders[AStereoSlider].LeftPosition := ALeftPosition;
  IGStereoSliders[AStereoSlider].RightPosition := ARightPosition;
end;

procedure InitSliders;
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
end;

procedure DrawSliders;
begin
  VideoWriteRegion(1, 2, 49, 25, cSpace, VideoAttribute(clMixerFore, clMixerBack));

  ScreenDrawStereoSlider(IGStereoSliders[ssDACStereoSlider]);
  ScreenDrawStereoSlider(IGStereoSliders[ssAUX1StereoSlider]);
  ScreenDrawStereoSlider(IGStereoSliders[ssAUX2StereoSlider]);
  ScreenDrawStereoSlider(IGStereoSliders[ssInputGainStereoSlider]);
  ScreenDrawStereoSlider(IGStereoSliders[ssDMEStereoSlider]);
end;

procedure DrawCommand(const ALeft, ATop, AHighlight, AColor, ABackground: Byte; const AShortcut, ADescription: String);
begin
  VideoWriteStringAt(ALeft, ATop, AShortcut, AHighlight, ABackground);
  VideoWriteStringAt(ALeft + 5, ATop, ADescription, AColor, ABackground);
end;

procedure DrawCommands;
begin
  VideoWriteRegion(50, 2, 31, 12, cSpace, VideoAttribute(clStatCmdFore, clStatCmdBack));

  VideoWriteStringAt(kMixerCmdX, 3, sMixerCmdProgramCmds, clStatCmdHeader, clStatCmdBack);
  DrawCommand(kMixerCmdX, 4, clSetupCmdHigh, clStatCmdFore, clStatCmdBack, sMixerCmdF8, sMixerCmdDefaultConfig);
  DrawCommand(kMixerCmdX, 5, clMixerCmdHigh, clStatCmdFore, clStatCmdBack, sMixerCmdF9, sMixerCmdReloadConfig);
  DrawCommand(kMixerCmdX, 6, clMixerCmdHigh, clStatCmdFore, clStatCmdBack, sMixerCmdF10, sMixerCmdSaveExit);
  DrawCommand(kMixerCmdX, 7, clMixerCmdHigh, clStatCmdFore, clStatCmdBack, sMixerCmdESC, sMixerCmdExit);

  VideoWriteStringAt(kMixerCmdX, 10, sMixerCmdVolumeCmds, clStatCmdHeader, clStatCmdBack);
  DrawCommand(kMixerCmdX, 11, clMixerCmdHigh, clStatCmdFore, clStatCmdBack, sMixerCmdUpDown, sMixerCmdSelectDevice);
  DrawCommand(kMixerCmdX, 12, clMixerCmdHigh, clStatCmdFore, clStatCmdBack, sMixerCmdLeftRight, sMixerCmdModifyVolume);
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
begin
  VideoWriteRegion(50, 14, 31, 25, cSpace, VideoAttribute(clDynCmdFore, clDynCmdBack));

  VideoWriteStringAt(kMixerCmdX, 15, sMixerCmdInputDeviceCmds, clDynCmdHeader, clDynCmdBack);
  DrawCommand(kMixerCmdX, 16, clMixerCmdHigh, clDynCmdFore, clDynCmdBack, sMixerCmd1, sMixerCmdLineIn);
  DrawCommand(kMixerCmdX, 17, clMixerCmdHigh, clDynCmdFore, clDynCmdBack, sMixerCmd2, sMixerCmdFMAUXIn);
  DrawCommand(kMixerCmdX, 18, clMixerCmdHigh, clDynCmdFore, clDynCmdBack, sMixerCmd3, sMixerCmdMicrophone);
  DrawCommand(kMixerCmdX, 19, clMixerCmdHigh, clDynCmdFore, clDynCmdBack, sMixerCmd4, sMixerCmdPostMixedDAC);

  VideoWriteStringAt(kMixerCmdX, 21, sMixerCmdAdditionalCmds, clDynCmdHeader, clDynCmdBack);
  DrawCommand(kMixerCmdX, 22, clMixerCmdHigh, clDynCmdFore, clDynCmdBack, sMixerCmd5, sMixerCmdMicrophoneGain);
  DrawCommand(kMixerCmdX, 23, clMixerCmdHigh, clDynCmdFore, clDynCmdBack, sMixerCmd6, sMixerCmdDigitalMix);
  DrawCommand(kMixerCmdX, 24, clMixerCmdHigh, clDynCmdFore, clDynCmdBack, sMixerCmd7, sMixerCmdOutputsEnabled);
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

  VideoHighlightRegion(57, IGMixerOptions[AOption].PositionY, 21, 1, LAttribute);
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
  IGMixerOptions[AOption].Enabled := not IGMixerOptions[AOption].Enabled;
  HighlightOption(AOption);
end;

procedure HighlightInputDevice(const AOption: TMixerOption);
var
  LOption: TMixerOption;

begin
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
  InitSliders;
  DrawSliders;

  InitOptions;
  DrawOptions;
  HighlightOptions;
end;

procedure UIDraw;
begin
  ScreenDrawTitleBar(clInterfaceFore, clInterfaceBack, clInterfaceFore, sMixerTitle);

  DrawCommands;
  DrawConfig;
end;

procedure UILoop;
var
  LStereoSlider: TStereoSlider;
  LSoundChannel: TSoundChannel;

begin
  LStereoSlider := ssDACStereoSlider;
  LSoundChannel := scLeft;
  ScreenHighlightStereoSlider(IGStereoSliders[LStereoSlider], LSoundChannel, True);

  while True do
  begin
    case UpCase(ReadKey) of
      kKeyExtended:
        begin
          case ReadKey of
            kKeyF8:
              begin
                MixerDefaultConfig;
                DrawConfig;

                ScreenHighlightStereoSlider(IGStereoSliders[LStereoSlider], LSoundChannel, True);
              end;

            kKeyF9:
              begin
                if SetupLoadConfig then
                begin
                  DrawConfig;
                end;

                ScreenHighlightStereoSlider(IGStereoSliders[LStereoSlider], LSoundChannel, True);
              end;

            kKeyF10:
              begin
                SetVolumes;
                SetInputConfigOptions;
                SetupSaveConfig;

                Break;
              end;

            kKeyUp:
              begin
                ScreenHighlightStereoSlider(IGStereoSliders[LStereoSlider], LSoundChannel, False);

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

                ScreenHighlightStereoSlider(IGStereoSliders[LStereoSlider], LSoundChannel, True);
              end;

            kKeyDown:
              begin
                ScreenHighlightStereoSlider(IGStereoSliders[LStereoSlider], LSoundChannel, False);

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

                ScreenHighlightStereoSlider(IGStereoSliders[LStereoSlider], LSoundChannel, True);
              end;

            kKeyLeft:
              ScreenMoveStereoSlider(IGStereoSliders[LStereoSlider], LSoundChannel, sdDown);

            kKeyRight:
              ScreenMoveStereoSlider(IGStereoSliders[LStereoSlider], LSoundChannel, sdUp);

          end;

        end;

      kKeyEscape:
        Break;

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

  { TODO -oagroza -cRefactor : Set controller mode via appropriate parameter. }
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
  GCodecMixerConfig.InputDeviceLeft := cidtLineIn;
  GCodecMixerConfig.InputDeviceRight := cidtLineIn;
  GCodecMixerConfig.InputGainLeft := kMixerInputGainDefault;
  GCodecMixerConfig.InputGainRight := kMixerInputGainDefault;
  GCodecMixerConfig.MicGainLeft := kMixerMicGainDefault;
  GCodecMixerConfig.MicGainRight := kMixerMicGainDefault;
  GCodecMixerConfig.DigitalMix := kMixerDigitalMixDefault;
  GCodecMixerConfig.DMELeftRight := kMixerDMEDefault;
  GCodecMixerConfig.OutputsEnabled := kMixerOutputsEnDefault;
end;

procedure MixerStart;
var
  LSaveY: Byte;
  LVideoRAMData: PVideoRAMData;

begin
  Routines.Delay(kMixerStartupDelay);

  LSaveY := WhereY;

  GetMem(LVideoRAMData, kVGARAMSize);
  VideoSaveScreen(LVideoRAMData);
  VideoClearScreen;
  VideoEnableHighColors;
  VideoDisableCursor;

  UIDraw;
  UILoop;

  VideoEnableCursor;
  VideoDisableHighColors;
  VideoRestoreScreen(LVideoRAMData);
  FreeMem(LVideoRAMData, kVGARAMSize);

  GotoXY(k80x25Left, LSaveY);
end;

end.
