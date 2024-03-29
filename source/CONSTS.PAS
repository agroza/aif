{ --------------------------------------------------------------------------- }
{ - Audio Interface - Constants (consts.pas)                                - }
{ - Copyright (C) 1998-2022 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Consts;

interface

uses
  Types,
  Video;

const
  sEmpty                    = '';
  sCRLF                     = #13#10;

  { program stringtable }
  sProgramTitle             = 'AUDIO INTERFACE  VER. 3.1 REV. B';
  sProgramCopyright         = 'Copyright (C) 1998-2022 Microprogramming TECHNIQUES';
  sProgramAuthor            = 'Programming/PC Code: Alexandru Groza';
  sProgramRights            = 'All rights reserved.';

  sParameterMissing         = 'Parameter(s) invalid or missing.';

  sTypeHelp                 = 'Type:' + #13#10 +
                              '  aif.exe -help';

  sHelpUsage                = 'Usage is:' + #13#10 +
                              '  aif.exe [-help] [-setup] [-pnpsetup] [-mixer] [-init | -wss | -sb]' + #13#10 +
                              '    [-quiet] [-status] [-lineout=on|off]' + #13#10;

  sHelpWhere                = 'Where:';

  sHelpParamHelp            = '  -help     shows this screen; all other parameters are ignored';
  sHelpParamSetup           = '  -setup    starts the setup program';
  sHelpParamPnPSetup        = '  -pnpsetup starts the PnP setup program; some parameters are ignored';
  sHelpParamMixer           = '  -mixer    starts the volume mixer program';
  sHelpParamInit            = '  -init     initializes the audio interface to preset mode';
  sHelpParamWSS             = '  -wss      initializes the audio interface to Windows Sound System mode';
  sHelpParamSB              = '  -sb       initializes the audio interface to Sound Blaster mode';
  sHelpParamQuiet           = '  -quiet    reduces text verbosity';
  sHelpParamStatus          = '  -status   displays the current audio interface configuration';
  sHelpParamLineOut         = '  -lineout  enables or disabled line out; some parameters are ignored';

  sHelpExamples             = 'Examples:' + #13#10 +
                              '  aif.exe -init' + #13#10 +
                              '  aif.exe -mixer -init -quiet -status';

  sLoadingConfiguration     = 'Loading Audio Interface Configuration';
  sDetecting82c924          = 'Detecting OPTi 82c924 Sound Controller';
  sDetectingAD1845          = 'Detecting AD1845 / CS4231 Audio Codec';
  sDetectingAD1848          = 'Detecting AD1848 / CS4248 Audio Codec';
  sDetectingAD1848orAD1845  = 'Detecting AD1848 / CS4248 or AD1845 / CS4231';
  sInitializing82c924       = 'Initializing OPTi 82c924 Sound Controller';
  sInitializingAD1848       = 'Initializing AD1848 / CS4248 Audio Codec';
  sInitializingAD1845       = 'Initializing AD1845 / CS4231 Audio Codec';
  sInitializingMPU          = 'Initializing MPU-401 Interface';
  sSettingMixerConfig       = 'Setting Audio Codec Mixer Configuration';
  sSettingSBMode            = 'Setting Sound Controller in Sound Blaster Mode';
  sSettingWSSMode           = 'Setting Sound Controller in Windows Sound System Mode';

  sAIInitializedSBMode      = 'Audio Interface initialized in Sound Blaster (SB) mode.';
  sAIInitializedWSSMode     = 'Audio Interface initialized in Windows Sound System (WSS) mode.';

  sLineOutRelay             = 'Line Out relay control is ';

  sHardwareInitError        = 'Hardware initialization error.' + #13#10 +
                              'Audio Interface is either not present or it is faulty.';
  sControllerReinitError    = 'Controller reinitialization error.' + #13#10 +
                              'Audio Interface is faulty.';

  sHardwareConfigChanged    = 'Hardware configuration has changed.' + #13#10 +
                              'Please initialize the audio interface.';

  sMode                     = 'mode';
  sPnP                      = 'PnP';
  snonPnP                   = 'non-PnP';

  sAIFSoundBlaster          = 'Sound Blaster';
  sAIFWindowsSoundSystem    = 'Windows Sound System';

  sHz                       = 'Hz';

  s8bit                     = '8-bit';
  s16bit                    = '16-bit';

  sMono                     = 'Mono';
  sStereo                   = 'Stereo';

  s8bitUlaw                 = '8-bit �-law';
  s8bitAlaw                 = '8-bit A-law';
  s8bitPCM                  = '8-bit PCM';
  s16bitPCM                 = '16-bit PCM';

  sSBDSPVersion21           = '2.1';
  sSBDSPVersion15           = '1.5';
  sSBDSPVersion32           = '3.2';
  sSBDSPVersion44           = '4.4';

  sOPL3                     = 'OPL3';

  sAudioCodecAD1848orCS4248 = 'AD1848 / CS4248';
  sAudioCodecAD1845orCS4231 = 'AD1845 / CS4231';

  sCrystal16and24MHz        = '16/24 MHz';
  sCrystal16MHz             = '16 MHz';

  sVolumeControlAutomatic   = 'Automatic';
  sVolumeControlNormal      = 'Normal';

  sNA                       = 'N/A';

  sFAILED                   = 'FAILED';
  sOK                       = 'OK';

  sDisabled                 = 'Disabled';
  sEnabled                  = 'Enabled';

  sFAILEDOK: packed array[Boolean] of String[Length(sFAILED)] = (
    sFAILED,
    sOK
  );

  sAIFMode: packed array[TBitStatus] of String[Length(sAIFWindowsSoundSystem)] = (
    sAIFSoundBlaster,
    sAIFWindowsSoundSystem
  );

  sDisabledEnabled: packed array[Boolean] of String[Length(sDisabled)] = (
    sDisabled,
    sEnabled
  );

  sBitDepth: packed array[TCodecBitDepth] of String[Length(s16bit)] = (
    s8bit,
    s16bit
  );

  sSoundOutput: packed array[TCodecSoundOutput] of String[Length(sStereo)] = (
    sMono,
    sStereo
  );

  sSBDSPVersions: packed array[TCodecSBDSPVersion] of String[Length(sSBDSPVersion21)] = (
    sSBDSPVersion21,
    sSBDSPVersion15,
    sSBDSPVersion32,
    sSBDSPVersion44
  );

  { single character constants }
  cSpace                    = ' ';
  cFullStop                 = '.';
  cComma                    = ',';
  cSemicolon                = ':';
  cBackslash                = '\';
  cSlash                    = '/';
  cEqual                    = '=';
  cMinus                    = '-';
  cOpenBracket              = '(';
  cClosedBracket            = ')';
  cOpenSquareBracket        = '[';
  cClosedSquareBracket      = ']';

  { program commandline parameters }
  pHelp                     = '-help';
  pSetup                    = '-setup';
  pPnPSetup                 = '-pnpsetup';
  pMixer                    = '-mixer';
  pInit                     = '-init';
  pWSS                      = '-wss';
  pSB                       = '-sb';
  pQuiet                    = '-quiet';
  pStatus                   = '-status';
  pLineOut                  = '-lineout=';

  pOn                       = 'on';
  pOff                      = 'off';

  { program commandline parameters help }
  kHelpParameters: packed array[0..9] of PChar = (
    sHelpParamHelp,
    sHelpParamSetup,
    sHelpParamPnPSetup,
    sHelpParamMixer,
    sHelpParamInit,
    sHelpParamWSS,
    sHelpParamSB,
    sHelpParamQuiet,
    sHelpParamStatus,
    sHelpParamLineOut
  );

  { VersaVision UI support messages }
  sMessageBoxError          = 'Error';
  sMessageBoxQuestion       = 'Question';

  sMessageBoxCancel         = 'Cancel';
  sMessageBoxClose          = 'Close';
  sMessageBoxYes            = 'Yes';
  sMessageBoxNo             = 'No';

  { file masks }
  fmBINFiles                = 'bin';

  { file mode constants }
  fmReadOnly                = 0;
  fmWriteOnly               = 1;
  fmReadWrite               = 2;

  { file record size }
  frsBinaryFileRecordSize   = 1;

  { general constants }
  kMaxByte                  = 255;

  { color constants }
  clError                   = clRed;
  clSuccess                 = clGreen;
  clNormal                  = clLightGray;
  clHighlight               = clWhite;

  clFAILEDOK: packed array[Boolean] of Byte = (
    clError,
    clSuccess
  );

  { program color theme }
  clInterfaceFore           = clBlack;
  clInterfaceBack           = clLightGray;

  clMessageBoxFore          = clWhite;
  clMessageBoxBack          = clRed;
  clMessageBoxBtnFore       = clBlue;
  clMessageBoxBtnBack       = clLightGray;
  clMessageBoxBtnAccel      = clRed;
  clMessageBoxBtnHighFore   = clWhite;
  clMessageBoxBtnHighBack   = clRed;
  clMessageBoxBtnHighAccel  = clBlack;

  { program constants }
  kOKFailedXPosition        = 60;

  { keyboard codes }
  kKeyBackspace             = #08;
  kKeyEnter                 = #13;
  kKeyEscape                = #27;
  kKeyExtended              = #00;
  kKeyUp                    = #72;
  kKeyDown                  = #80;
  kKeyLeft                  = #75;
  kKeyRight                 = #77;
  kKeyF4                    = #62;
  kKeyF5                    = #63;
  kKeyF6                    = #64;
  kKeyF7                    = #65;
  kKeyF8                    = #66;
  kKeyF9                    = #67;
  kKeyF10                   = #68;

  { Setup program stringtable }
  sSetupTitle               = 'AUDIO INTERFACE SETUP';

  sSetupAIFMode             = 'Audio Interface Mode';
  sSetupWSSBASE             = 'WSS Address';
  sSetupWSSIRQ              = 'WSS IRQ';
  sSetupWSSDRQ              = 'WSS DMA';
  sSetupSBBASE              = 'SB Address';
  sSetupSBIRQ               = 'SB IRQ';
  sSetupSBDRQ               = 'SB DMA';
  sSetupMPU401              = 'MPU-401';
  sSetupMPUBASE             = 'MPU-401 Address';
  sSetupMPUIRQ              = 'MPU-401 IRQ';
  sSetupGamePort            = 'Game Port';
  sSetupIDECDROM            = 'IDE CD-ROM';
  sSetupCFIX                = 'Audio Codec';
  sSetupFMAP                = 'Audio Codec Crystals';
  sSetupWSSSampleRate       = 'WSS Sampling Rate';
  sSetupWSSBitDepth         = 'WSS Bit Depth';
  sSetupWSSSoundOutput      = 'WSS Sound Output';
  sSetupSBSampleRate        = 'SB Sampling Rate';
  sSetupSBBitDepth          = 'SB Bit Depth';
  sSetupSBSoundOutput       = 'SB Sound Output';
  sSetupSBDSPVersion        = 'SB DSP Version';
  sSetupSBADPCM             = 'SB ADPCM';
  sSetupCFIFO               = 'SB Command FIFO';
  sSetupAVC                 = 'Volume Control';

  sSetupCmdProgramCmds      = 'PROGRAM COMMANDS';
  sSetupCmdF8               = 'F8';
  sSetupCmdDefaultConfig    = 'Default Configuration';
  sSetupCmdF9               = 'F9';
  sSetupCmdReloadConfig     = 'Reload Configuration';
  sSetupCmdF10              = 'F10';
  sSetupCmdSaveExit         = 'Save and Exit';
  sSetupCmdESC              = 'ESC';
  sSetupCmdExit             = 'Exit';

  sSetupCmdOptionCmds       = 'OPTION COMMANDS';
  sSetupCmdUpDown           = '/';
  sSetupCmdSelectOption     = 'Select Option';
  sSetupCmdLeftRight        = #27'/'#26;
  sSetupCmdModifyOption     = 'Modify Option';

  sSetupSoundController     = 'SOUND CONTROLLER';
  sSetupOPTi82c924          = 'OPTi 82c924 REV. ';

  sSetupConfigChanged       = 'Audio Interface configuration has changed.' + #13#10 +
                              'Save changes?';

  { Setup program color theme }
  clSetupFore               = clLightGray;
  clSetupBack               = clBlue;

  clSetupCmdHigh            = clLightCyan;
  clSetupCmdHeader          = clWhite;
  clSetupCmdFore            = clLightGray;
  clSetupCmdBack            = clDarkGray;

  { Setup program constants }
  kSetupStartupDelay        = 500;

  kSetupKeyX                = 2;
  kSetupValueX              = 25;
  kSetupKeyValueWidth       = 26;

  kSetupCommandsLeft        = 50;
  kSetupCommandsTop         = 2;
  kSetupCommandsWidth       = 31;
  kSetupCommandsHeight      = 24;

  kSetupCmdX                = 52;

  kSetupCmdCount            = 5;

  kSetupSoundControllerY    = 23;
  kSetupOPTi82c924Y         = 24;

  kSetupOptionsLeft         = 1;
  kSetupOptionsTop          = 2;
  kSetupOptionsWidth        = 49;
  kSetupOptionsHeight       = 24;

  kSetupOptionX             = 1;
  kSetupOptionWidth         = 23;
  kSetupOptionHeight        = 1;
  kSetupOptionEditX         = 24;
  kSetupOptionEditWidth     = 26;
  kSetupOptionEditHeight    = 1;

  { Setup program default initialization values }
  kSetupBitMODDefault       = bsNotSet;
  kSetupBitPDNDefault       = bsNotSet;
  kSetupBitGPENDefault      = bsSet;

  kSetupBitOPL4Default      = bsNotSet;

  kSetupBitFMAPDefault      = bsNotSet;
  kSetupBitCMDPASDefault    = bsSet;

  kSetupBitADPCMENDefault   = bsSet;
  kSetupBitGPOUTDefault     = bsNotSet;
  kSetupBitPNPMODEDefault   = bsSet;
  kSetupBitFMCLKDefault     = bsNotSet;
  kSetupBitSILENCEDefault   = bsNotSet;

  kSetupBitAVCENDefault     = bsSet;
  kSetupBitOPL5Default      = bsNotSet;
  kSetupBitSHPASSDefault    = bsSet;
  kSetupBitSBACCESSDefault  = bsNotSet;
  kSetupBitCFIFODefault     = bsSet;
  kSetupBitEPENDefault      = bsSet;
  kSetupBitCFIXDefault      = bsSet;

  kSetupBitMPU401Default    = bsSet;
  kSetupBitDRQTMENDefault   = bsSet;
  kSetupBitAUDIOENDefault   = bsSet;

  kSetupWSSBASEDefault      = $0530;
  kSetupWSSIRQDefault       = $FF;
  kSetupWSSDRQDefault       = $01;

  kSetupSBBASEDefault       = $0220;
  kSetupSBIRQDefault        = $05;
  kSetupSBDRQDefault        = $01;
  kSetupSBDSPVerDefault     = sdVersion32;

  kSetupMPUBASEDefault      = $0330;
  kSetupMPUIRQDefault       = $09;

  kSetupCDBASEDefault       = $0340;
  kSetupCDIRQDefault        = $FF;
  kSetupCDDRQDefault        = $03;
  kSetupIDECDROMDefault     = bsNotSet;

  kSetupWSSSmpRateDefault   = sr44100;
  kSetupWSSBitDepthDefault  = bd16bit;
  kSetupWSSSndOutDefault    = soStereo;

  kSetupSBSmpRateDefault    = sr22050;
  kSetupSBBitDepthDefault   = bd8bit;
  kSetupSBSndOutDefault     = soStereo;

  { PnP Setup program stringtable }
  sPnPSetupTitle            = 'AUDIO INTERFACE EEPROM PnP SETUP';

  sPnPSetupDefaultFilename  = 'eeprom.bin';

  sPnPSetupFilename         = 'Filename';
  sPnPSetupOperation        = 'Operation';
  sPnPSetupStatus           = 'Status';
  sPnPSetupEEPROM           = 'EEPROM';
  sPnPSetup93C56A           = '93C56A';
  sPnPSetupProgress         = 'Progress';
  sPnPSetupRawData          = 'Raw Data';

  sPnPSetupEraseFast        = 'erase (fast)';
  sPnPSetupEraseSlow        = 'erase (slow)';
  sPnPSetupRead             = 'read';
  sPnPSetupWrite            = 'write';

  sPnPSetupFileExists       = 'A file with this name already exists.' + #13#10 +
                              'Overwrite file?';
  sPnPSetupFileNotExists    = 'A file with this name does not exist.' + #13#10 +
                              'Please specify a different filename.';

  sPnPSetupCmdProgramCmds   = 'PROGRAM COMMANDS';
  sPnPSetupCmdF4            = 'F4';
  sPnPSetupCmdEditFilename  = 'Edit Filename';
  sPnPSetupCmdF5            = 'F5';
  sPnPSetupCmdEraseEEPROMF  = 'Erase EEPROM (Fast)';
  sPnPSetupCmdF6            = 'F6';
  sPnPSetupCmdEraseEEPROMS  = 'Erase EEPROM (Slow)';
  sPnPSetupCmdF7            = 'F7';
  sPnPSetupCmdReadEEPROM    = 'Read EEPROM';
  sPnPSetupCmdF8            = 'F8';
  sPnPSetupCmdWriteEEPROM   = 'Write EEPROM';
  sPnPSetupCmdESC           = 'ESC';
  sPnPSetupCmdExit          = 'Exit';

  { PnP Setup program color theme }
  clPnPSetupFore            = clLightGray;
  clPnPSetupBack            = clBlue;

  clPnPSetupEditFore        = clPnPSetupFore;
  clPnPSetupEditBack        = clPnPSetupBack;
  clPnPSetupEditHighFore    = clWhite;
  clPnPSetupEditHighBack    = clRed;

  clPnPSetupProgressFore    = clPnPSetupFore;
  clPnPSetupProgressBack    = clPnPSetupBack;
  clPnPSetupProgressTitle   = clWhite;
  clPnPSetupProgressColor   = clGreen;

  clPnPSetupRawDataFore     = clPnPSetupFore;
  clPnPSetupRawDataBack     = clPnPSetupBack;
  clPnPSetupRawDataTitle    = clWhite;

  clPnPSetupCmdHigh         = clLightCyan;
  clPnPSetupCmdHeader       = clWhite;
  clPnPSetupCmdFore         = clLightGray;
  clPnPSetupCmdBack         = clDarkGray;

  { PnP Setup program constants }
  kPnPSetupStartupDelay     = 500;
  kPnPSetupOperationDelay   = 500;

  kPnPSetupComponentsLeft   = 1;
  kPnPSetupComponentsTop    = 2;
  kPnPSetupComponentsWidth  = 49;
  kPnPSetupComponentsHeight = 24;

  kPnPSetupKeyX             = 2;
  kPnPSetupValueX           = 15;
  kPnPSetupKeyValueWidth    = 26;

  kPnPSetupKeyValueCount    = 3;

  kPnPSetupEditX            = kPnPSetupValueX;
  kPnPSetupEditY            = 3;
  kPnPSetupEditWidth        = 34;

  kPnPSetupProgressBarX     = kPnPSetupKeyX;
  kPnPSetupProgressBarY     = 8;
  kPnPSetupProgressBarWidth = 47;
  kPnPSetupProgressBarMin   = 0;

  kPnPSetupRawDataX         = kPnPSetupKeyX;
  kPnPSetupRawDataY         = 12;
  kPnPSetupRawDataWidth     = 47;
  kPnPSetupRawDataHeight    = 13;
  kPnPSetupRawDataLength    = 43;

  kPnPSetupOperationX       = kPnPSetupValueX;
  kPnPSetupOperationY       = 4;
  kPnPSetupStatusX          = kPnPSetupValueX;
  kPnPSetupStatusY          = 5;
  kPnPSetupOpStatusWidth    = 20;
  kPnPSetupOpStatusHeight   = 2;

  kPnPSetupCommandsLeft     = 50;
  kPnPSetupCommandsTop      = 2;
  kPnPSetupCommandsWidth    = 31;
  kPnPSetupCommandsHeight   = 24;

  kPnPSetupCmdX             = 52;

  kPnPSetupCmdCount         = 5;

  { Mixer program stringtable }
  sMixerTitle               = 'AUDIO INTERFACE MIXER';

  sMixerVolumeDAC           = 'DAC Output Volume';
  sMixerVolumeFMAUXIn       = 'FM Synthesizer & AUX In Volume';
  sMixerVolumeCDROMLineIn   = 'CD-ROM & Line In Volume';
  sMixerVolumeADCInputGain  = 'ADC Input Gain';
  sMixerVolumeDME           = 'Digital Mix Volume (Mono)';

  sMixerCmdProgramCmds      = 'PROGRAM COMMANDS';
  sMixerCmdF8               = 'F8';
  sMixerCmdDefaultConfig    = 'Default Configuration';
  sMixerCmdF9               = 'F9';
  sMixerCmdReloadConfig     = 'Reload Configuration';
  sMixerCmdF10              = 'F10';
  sMixerCmdSaveExit         = 'Save and Exit';
  sMixerCmdESC              = 'ESC';
  sMixerCmdExit             = 'Exit';

  sMixerCmdVolumeCmds       = 'VOLUME COMMANDS';
  sMixerCmdUpDown           = '/';
  sMixerCmdSelectDevice     = 'Select Device';
  sMixerCmdLeftRight        = #27'/'#26;
  sMixerCmdModifyVolume     = 'Modify Volume +SFT=L/R';

  sMixerCmdInputDeviceCmds  = 'INPUT DEVICE COMMANDS';
  sMixerCmd1                = '1';
  sMixerCmdLineIn           = 'Line In';
  sMixerCmd2                = '2';
  sMixerCmdFMAUXIn          = 'FM & AUX In';
  sMixerCmd3                = '3';
  sMixerCmdMicrophone       = 'Microphone';
  sMixerCmd4                = '4';
  sMixerCmdPostMixedDAC     = 'Post-Mixed DAC';

  sMixerCmdAdditionalCmds   = 'ADDITIONAL COMMANDS';
  sMixerCmd5                = '5';
  sMixerCmdMicrophoneGain   = 'Microphone Gain +20dB';
  sMixerCmd6                = '6';
  sMixerCmdDigitalMix       = 'Digital Mix';
  sMixerCmd7                = '7';
  sMixerCmdOutputsEnabled   = 'Outputs Enabled';

  sMixerSliderLeft          = 'LEFT';
  sMixerSliderRight         = 'RIGHT';

  sMixerConfigChanged       = 'Mixer configuration has changed.' + #13#10 +
                              'Save changes?';

  { Mixer program color theme }
  clMixerFore               = clLightGray;
  clMixerBack               = clBlue;

  clMixerSliderFore         = clMixerFore;
  clMixerSliderBack         = clMixerBack;
  clMixerSliderTitle        = clWhite;
  clMixerSliderText         = clLightGray;
  clMixerSliderHighFore     = clWhite;
  clMixerSliderHighBack     = clRed;
  clMixerSliderGrid         = clBrown;
  clMixerSliderTip          = clWhite;
  clMixerSliderNormal       = clLightGray;
  clMixerSliderLow          = clGreen;
  clMixerSliderMedium       = clLightGreen;
  clMixerSliderHigh         = clYellow;
  clMixerSliderVeryHigh     = clLightRed;

  clMixerCmdHigh            = clLightCyan;
  clStatCmdHeader           = clWhite;
  clStatCmdFore             = clLightGray;
  clStatCmdBack             = clDarkGray;
  clDynCmdHeader            = clWhite;
  clDynCmdFore              = clLightGray;
  clDynCmdBack              = clBlue;

  { Mixer program constants }
  kMixerStartupDelay        = 500;

  kMixerSlidersLeft         = 1;
  kMixerSlidersTop          = 2;
  kMixerSlidersWidth        = 49;
  kMixerSlidersHeight       = 24;
  kMixerSlidersLeftY        = 1;
  kMixerSlidersRightY       = 3;
  kMixerSlidersTipX         = 7;
  kMixerSlidersValueX       = 40;

  kMixerSliderX             = 2;

  kMixerDACSliderY          = 2;
  kMixerAUX1SliderY         = 7;
  kMixerAUX2SliderY         = 12;
  kMixerInputGainSliderY    = 17;
  kMixerDMESliderY          = 22;

  kMixerSliderMin           = 0;
  kMixerSliderMax           = 30;

  kMixerCommandsLeft        = 50;
  kMixerCommandsTop         = 2;
  kMixerCommandsWidth       = 31;
  kMixerCommandsHeight      = 12;

  kMixerCmdX                = 52;

  kMixerStatCmdCount        = 5;
  kMixerDynCmdCount         = 6;

  kMixerOptionsLeft         = 50;
  kMixerOptionsTop          = 14;
  kMixerOptionsWidth        = 31;
  kMixerOptionsHeight       = 12;

  kMixerOptionX             = 57;
  kMixerOptionWidth         = 21;
  kMixerOptionHeight        = 1;

  { Mixer program default initialization values }
  kMixerDACDefault          = 14;
  kMixerAUX1Default         = 30;
  kMixerAUX2Default         = 0;
  kMixerInputDeviceDefault  = cidtLineIn;
  kMixerInputGainDefault    = 0;
  kMixerMicGainDefault      = False;
  kMixerDigitalMixDefault   = False;
  kMixerDMEDefault          = 0;
  kMixerOutputsEnDefault    = True;

  { Status program stringtable }
  sStatusAIFModel           = 'ISA Audio Interface model 2486-AIF-401';
  sStatusAIFMode            = 'Audio Interface Mode';
  sStatusBASE               = 'Address';
  sStatusIRQ                = 'Interrupt Request';
  sStatusDRQ                = 'Direct Memory Access';
  sStatusDSP                = 'DSP Version';
  sStatusFM                 = 'FM Synthesizer';
  sStatusMPU401             = 'MPU-401 Address';
  sStatusGamePort           = 'Game Port';
  sStatusOutputFormat       = 'Audio Output Format';
  sStatusLineOutRelay       = 'Line Out Relay';

  { Status program constants }
  kStatusItemX              = 1;
  kStatusSemicolonX         = 23;
  kStatusValueX             = 25;

implementation

end.
