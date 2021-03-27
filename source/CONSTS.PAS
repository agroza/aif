{ --------------------------------------------------------------------------- }
{ - Audio Interface - Constants (consts.pas)                                - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Consts;

interface

uses
  Types;

const
  sEmpty                  = '';

  { program stringtable }
  sProgramTitle            = 'AUDIO INTERFACE  VER. 2.4 REV. C';
  sProgramCopyright        = 'Copyright (C) 1998-2021 Microprogramming TECHNIQUES';
  sProgramAuthor           = 'Programming/PC Code: Alexandru Groza';
  sProgramRights           = 'All rights reserved.';

  sParameterMissing        = 'Parameter(s) invalid or missing.';

  sTypeHelp                = 'Type:' + #13#10 +
                             '  aif.exe -help';
  sHelpUsage               = 'Usage is:' + #13#10 +
                             '  aif.exe [-help] [-setup] [-mixer] [-init | -wss | -sb ] [-quiet] [-status]' + #13#10 +
                             '    [-lineout=on|off]' + #13#10;
  sHelpParameters1         = 'Where:' + #13#10 +
                             '  -help     shows this screen; all other parameters are ignored' + #13#10 +
                             '  -setup    starts the setup program; all other parameters are ignored' + #13#10 +
                             '  -mixer    starts the volume mixer program';
  sHelpParameters2         = '  -init     initializes the audio interface to preset mode' + #13#10 +
                             '  -wss      initializes the audio interface to Windows Sound System mode' + #13#10 +
                             '  -sb       initializes the audio interface to Sound Blaster mode';
  sHelpParameters3         = '  -quiet    reduces text verbosity' + #13#10 +
                             '  -status   displays the current audio interface configuration';
  sHelpParameters4         = '  -lineout  enables or disabled Line Out; all other parameters are ignored';

  sHelpExamples            = 'Examples:' + #13#10 +
                             '  aif.exe -init' + #13#10 +
                             '  aif.exe -mixer -init -quiet -status';

  sLoadingConfiguration    = 'Loading Audio Interface Configuration';
  sDetecting82c924         = 'Detecting OPTi 82c924 Sound Controller';
  sDetectingAD1845         = 'Detecting AD1845 / CS4231 Audio Codec';
  sDetectingAD1848         = 'Detecting AD1848 / CS4248 Audio Codec';
  sDetectingAD1848orAD1845 = 'Detecting AD1848 / CS4248 or AD1845 / CS4231';
  sInitializing82c924      = 'Initializing OPTi 82c924 Sound Controller';
  sInitializingAD1848      = 'Initializing AD1848 / CS4248 Audio Codec';
  sInitializingAD1845      = 'Initializing AD1845 / CS4231 Audio Codec';
  sInitializingMPU         = 'Initializing MPU-401 Interface';
  sSettingMixerConfig      = 'Setting Audio Codec Mixer Configuration';
  sSettingSBMode           = 'Setting Sound Controller in Sound Blaster Mode';
  sSettingWSSMode          = 'Setting Sound Controller in Windows Sound System Mode';

  sAIInitializedSBMode     = 'Audio Interface initialized in Sound Blaster (SB) mode.';
  sAIInitializedWSSMode    = 'Audio Interface initialized in Windows Sound System (WSS) mode.';

  sLineOutRelay            = 'Line Out relay control is ';

  sMode                    = 'mode';

  sHz                      = 'Hz';
  sOPL3                    = 'OPL3';

  s8bitUlaw                = '8-bit Ф-law';
  s8bitAlaw                = '8-bit A-law';
  s8bitPCM                 = '8-bit PCM';
  s16bitPCM                = '16-bit PCM';

  sNA                      = 'N/A';
  sOK                      = 'OK';
  sFAILED                  = 'FAILED';

  sAIFDetectionMode: array[TAIFDetectionMode] of String[7] = (
    'PnP',
    'non-PnP'
  );

  sAIFMode: array[TBitStatus] of String[20] = (
    'Sound Blaster',
    'Windows Sound System'
  );

  sEnabledDisabled: array[Boolean] of String[8] = (
    'Disabled',
    'Enabled'
  );

  sBSEnabledDisabled: array[TBitStatus] of String[8] = (
    'Disabled',
    'Enabled'
  );

  sBitDepth: array[TBitDepth] of String[6] = (
    '8-bit',
    '16-bit'
  );

  sSoundOutput: array[TSoundOutput] of String[6] = (
    'Mono',
    'Stereo'
  );

  sSBDSPVersions: array[TSBDSPVersion] of String[3] = (
    '2.1',
    '1.5',
    '3.2',
    '4.4'
  );

  sCFIX: array[TBitStatus] of String[16] = (
    'AD1848 / CS4248',
    'AD1845 / CS4231'
  );

  sFMAP: array[TBitStatus] of String[9] = (
    '16/24 MHz',
    '16 MHz'
  );

  sAVC: array[TBitStatus] of String[9] = (
    'Automatic',
    'Normal'
  );

  { single character constants }
  cSpace                   = ' ';
  cFullStop                = '.';
  cSemicolon               = ':';
  cSlash                   = '/';
  cEqual                   = '=';
  cOpenBracket             = '(';
  cClosedBracket           = ')';
  cOpenSquareBracket       = '[';
  cClosedSquareBracket     = ']';

  { program commandline parameters }
  pHelp                    = '-help';
  pSetup                   = '-setup';
  pMixer                   = '-mixer';
  pInit                    = '-init';
  pWSS                     = '-wss';
  pSB                      = '-sb';
  pQuiet                   = '-quiet';
  pStatus                  = '-status';
  pLineOut                 = '-lineout=';

  pOn                      = 'on';

  { file masks }
  fmBINFiles               = 'bin';

  { file mode constants }
  fmReadOnly               = 0;
  fmWriteOnly              = 1;
  fmReadWrite              = 2;

  { color constants }
  clBlack                  = 0;
  clBlue                   = 1;
  clGreen                  = 2;
  clCyan                   = 3;
  clRed                    = 4;
  clMagenta                = 5;
  clBrown                  = 6;
  clLightGray              = 7;
  clDarkGray               = 8;
  clLightBlue              = 9;
  clLightGreen             = 10;
  clLightCyan              = 11;
  clLightRed               = 12;
  clLightMagenta           = 13;
  clYellow                 = 14;
  clWhite                  = 15;

  clSuccess                = clGreen;
  clError                  = clRed;
  clNormal                 = clLightGray;
  clHighlight              = clWhite;

  { Program color theme }
  clInterfaceFore          = clBlack;
  clInterfaceBack          = clLightGray;

  { Program constants }
  kOKFailedXPosition       = 60;

  { keyboard codes }
  kKeyEscape               = #27;
  kKeyExtended             = #00;
  kKeyUp                   = #72;
  kKeyDown                 = #80;
  kKeyLeft                 = #75;
  kKeyRight                = #77;
  kKeyF8                   = #66;
  kKeyF9                   = #67;
  kKeyF10                  = #68;

  { Setup stringtable }
  sSetupTitle              = 'AUDIO INTERFACE SETUP';

  sSetupAIFMode            = 'Audio Interface Mode';
  sSetupWSSBASE            = 'WSS Address';
  sSetupWSSIRQ             = 'WSS IRQ';
  sSetupWSSDRQ             = 'WSS DMA';
  sSetupSBBASE             = 'SB Address';
  sSetupSBIRQ              = 'SB IRQ';
  sSetupSBDRQ              = 'SB DMA';
  sSetupMPU401             = 'MPU-401';
  sSetupMPUBASE            = 'MPU-401 Address';
  sSetupMPUIRQ             = 'MPU-401 IRQ';
  sSetupGamePort           = 'Game Port';
  sSetupIDECDROM           = 'IDE CD-ROM';
  sSetupCFIX               = 'Audio Codec';
  sSetupFMAP               = 'Audio Codec Crystals';
  sSetupWSSSampleRate      = 'WSS Sampling Rate';
  sSetupWSSBitDepth        = 'WSS Bit Depth';
  sSetupWSSSoundOutput     = 'WSS Sound Output';
  sSetupSBSampleRate       = 'SB Sampling Rate';
  sSetupSBBitDepth         = 'SB Bit Depth';
  sSetupSBSoundOutput      = 'SB Sound Output';
  sSetupSBDSPVersion       = 'SB DSP Version';
  sSetupSBADPCM            = 'SB ADPCM';
  sSetupCFIFO              = 'SB Command FIFO';
  sSetupAVC                = 'Volume Control';

  sSetupCmdProgramCmds     = 'PROGRAM COMMANDS';
  sSetupCmdF8              = 'F8';
  sSetupCmdDefaultConfig   = 'Default Configuration';
  sSetupCmdF9              = 'F9';
  sSetupCmdReloadConfig    = 'Reload Configuration';
  sSetupCmdF10             = 'F10';
  sSetupCmdSaveExit        = 'Save and Exit';
  sSetupCmdESC             = 'ESC';
  sSetupCmdExit            = 'Exit';

  sSetupCmdOptionCmds      = 'OPTION COMMANDS';
  sSetupCmdUpDown          = '/';
  sSetupCmdSelectOption    = 'Select Option';
  sSetupCmdLeftRight       = #27'/'#26;
  sSetupCmdModifyOption    = 'Modify Option';

  sSetupSoundController    = 'SOUND CONTROLLER';
  sSetupOPTi82c924         = 'OPTi 82c924 REV. ';

  { Setup color theme }
  clSetupFore              = clLightGray;
  clSetupBack              = clBlue;

  clSetupCmdHigh           = clLightCyan;
  clSetupCmdHeader         = clWhite;
  clSetupCmdFore           = clLightGray;
  clSetupCmdBack           = clDarkGray;

  { Setup constants }
  kSetupStartupDelay       = 500;

  kSetupNameX              = 2;
  kSetupValueX             = 25;

  kSetupCmdX               = 52;

  { Mixer stringtable }
  sMixerTitle              = 'AUDIO INTERFACE MIXER';

  sMixerVolumeDAC          = 'DAC Output Volume';
  sMixerVolumeFMAUXIn      = 'FM Synthesizer & AUX In Volume';
  sMixerVolumeCDROMLineIn  = 'CD-ROM & Line In Volume';
  sMixerVolumeADCInputGain = 'ADC Input Gain';
  sMixerVolumeDME          = 'Digital Mix Volume';

  sMixerCmdProgramCmds     = 'PROGRAM COMMANDS';
  sMixerCmdF8              = 'F8';
  sMixerCmdDefaultConfig   = 'Default Configuration';
  sMixerCmdF9              = 'F9';
  sMixerCmdReloadConfig    = 'Reload Configuration';
  sMixerCmdF10             = 'F10';
  sMixerCmdSaveExit        = 'Save and Exit';
  sMixerCmdESC             = 'ESC';
  sMixerCmdExit            = 'Exit';

  sMixerCmdVolumeCmds      = 'VOLUME COMMANDS';
  sMixerCmdUpDown          = '/';
  sMixerCmdSelectDevice    = 'Select Device';
  sMixerCmdLeftRight       = #27'/'#26;
  sMixerCmdModifyVolume    = 'Modify Volume';

  sMixerCmdInputDeviceCmds = 'INPUT DEVICE COMMANDS';
  sMixerCmd1               = '1';
  sMixerCmdLineIn          = 'Line In';
  sMixerCmd2               = '2';
  sMixerCmdFMAUXIn         = 'FM & AUX In';
  sMixerCmd3               = '3';
  sMixerCmdMicrophone      = 'Microphone';
  sMixerCmd4               = '4';
  sMixerCmdPostMixedDAC    = 'Post-Mixed DAC';

  sMixerCmdAdditionalCmds  = 'ADDITIONAL COMMANDS';
  sMixerCmd5               = '5';
  sMixerCmdMicrophoneGain  = 'Microphone Gain +20dB';
  sMixerCmd6               = '6';
  sMixerCmdDigitalMix      = 'Digital Mix';
  sMixerCmd7               = '7';
  sMixerCmdOutputsEnabled  = 'Outputs Enabled';

  sMixerSliderLeft         = 'LEFT';
  sMixerSliderRight        = 'RIGHT';
  sMixerSliderGrid         = 'цдедедедедедедедедедедедедедед╢';
  cMixerSliderTip          = 'ш';

  { Mixer color theme }
  clMixerFore              = clLightGray;
  clMixerBack              = clBlue;

  clMixerSliderTitle       = clWhite;
  clMixerSliderText        = clLightGray;
  clMixerSliderHighFore    = clWhite;
  clMixerSliderHighBack    = clRed;
  clMixerSliderGrid        = clDarkGray;
  clMixerSliderTip         = clWhite;
  clMixerSliderNormal      = clLightGray;
  clMixerSliderLow         = clGreen;
  clMixerSliderMedium      = clLightGreen;
  clMixerSliderHigh        = clYellow;
  clMixerSliderVeryHigh    = clLightRed;

  clMixerCmdHigh           = clLightCyan;
  clStatCmdHeader          = clWhite;
  clStatCmdFore            = clLightGray;
  clStatCmdBack            = clDarkGray;
  clDynCmdHeader           = clWhite;
  clDynCmdFore             = clLightGray;
  clDynCmdBack             = clBlue;

  { Mixer constants }
  kMixerStartupDelay       = 500;

  kMixerSliderX            = 2;

  kMixerCmdX               = 52;

  { Mixer default constants }
  kMixerDACDefault         = 14;
  kMixerAUX1Default        = 30;
  kMixerAUX2Default        = 0;
  { TODO -oagroza -cIdea : Move this type to global types? }
  {kMixerInputDeviceDefault = cidtLineIn;}
  kMixerInputGainDefault   = 0;
  kMixerMicGainDefault     = False;
  kMixerDigitalMixDefault  = False;
  kMixerDMEDefault         = 0;
  kMixerOutputsEnDefault   = True;

  { Status stringtable }
  sStatusAIFModel          = 'ISA Audio Interface model 2486-AIF-401';
  sStatusAIFMode           = 'Audio Interface Mode';
  sStatusBASE              = 'Address';
  sStatusIRQ               = 'Interrupt Request';
  sStatusDRQ               = 'Direct Memory Access';
  sStatusDSP               = 'DSP Version';
  sStatusFM                = 'FM Synthesizer';
  sStatusMPU401            = 'MPU-401 Address';
  sStatusGamePort          = 'Game Port';
  sStatusOutputFormat      = 'Audio Output Format';
  sStatusLineOutRelay      = 'Line Out Relay';

  { Status constants }
  kStatusValueX            = 22;

  kSBDSPVersions: array[TSBDSPVersion] of Byte = (
    2,
    1,
    3,
    4
  );

implementation

end.
