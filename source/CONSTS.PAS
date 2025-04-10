{ --------------------------------------------------------------------------- }
{ - Audio Interface - Constants (consts.pas)                                - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Consts;

{$I cdefines.inc}

interface

uses
  Types,
  Video;

const
  sEmpty                       = '';
  sCRLF                        = #13#10;

  { program stringtable }
  sProgramTitle                = 'AUDIO INTERFACE ' +
                {$IFDEF PNPSETUP}'+PnP SETUP ' +{$ENDIF}
                                 ' VER. 3.1 REV. C';
  sProgramCopyright            = 'Copyright (C) 1998-2025 Microprogramming TECHNIQUES';
  sProgramAuthor               = 'Programming/PC Code: Alexandru Groza';
  sProgramRights               = 'All rights reserved.';

  sNotEnoughMemory             = 'Not enough conventional memory.';
  sParameterMissing            = 'Parameter(s) invalid or missing.';

  sTypeHelp                    = 'Type:' + #13#10 +
                                 '  aif.exe -help';

  sHelpUsage                   = 'Usage is:' + #13#10 +
                                 '  aif.exe' +
                                 ' [-?|-help]' +
                                 ' [-setup]' +
                {$IFDEF PNPSETUP}' [-pnpsetup]' +{$ENDIF}
                                 ' [-romsetup]' +
                                 ' [-mixer]' + #13#10 + '   ' +
                                 ' [-init|-wss|-sb]' +
                                 ' [-quiet]' +
                                 ' [-status]' +
                                 ' [-lineout=on|off]' + #13#10;

  sHelpWhere                   = 'Where:';
  sHelpParamHelp               = '  -?|-help  shows this screen; all other parameters are ignored';
  sHelpParamSetup              = '  -setup    starts the setup program; some parameters might be ignored';
  sHelpParamPnPSetup           = '  -pnpsetup starts the PnP setup program; some parameters are ignored';
  sHelpParamROMSetup           = '  -romsetup starts the (EEP)ROM setup program; some parameters are ignored';
  sHelpParamMixer              = '  -mixer    starts the volume mixer program';
  sHelpParamInit               = '  -init     initializes the audio interface to preset mode';
  sHelpParamWSS                = '  -wss      initializes the audio interface to Windows Sound System mode';
  sHelpParamSB                 = '  -sb       initializes the audio interface to Sound Blaster mode';
  sHelpParamQuiet              = '  -quiet    reduces text verbosity';
  sHelpParamStatus             = '  -status   displays the current audio interface configuration';
  sHelpParamLineOut            = '  -lineout  enables or disables line out relay; some parameters are ignored';

  sHelpExamples                = 'Examples:' + #13#10 +
                                 '  aif.exe -init' + #13#10 +
                                 '  aif.exe -mixer -init -quiet -status';

  sLoadingAIFConfig            = 'Loading Audio Interface Configuration';
  sLoadingAIFConfigDefault     = 'Loading Default Audio Interface Configuration';
  sAIFConfig                   = 'Audio Interface Configuration';
  sDetecting82c924             = 'Detecting OPTi 82c924 Sound Controller';
  sDetectingAD1845             = 'Detecting AD1845 / CS4231 Audio Codec';
  sDetectingAD1848             = 'Detecting AD1848 / CS4248 Audio Codec';
  sDetectingAD1848orAD1845     = 'Detecting AD1848 / CS4248 or AD1845 / CS4231';
  sInitializing82c924          = 'Initializing OPTi 82c924 Sound Controller';
  sInitializingAD1848          = 'Initializing AD1848 / CS4248 Audio Codec';
  sInitializingAD1845          = 'Initializing AD1845 / CS4231 Audio Codec';
  sInitializingMPU             = 'Initializing MPU-401 Interface';
  sMixerConfig                 = 'Audio Codec Mixer Configuration';
  sSettingMixerConfig          = 'Setting Audio Codec Mixer Configuration';
  sSettingSBMode               = 'Setting Sound Controller to Sound Blaster Mode';
  sSettingWSSMode              = 'Setting Sound Controller to Windows Sound System Mode';
  sAIFInitialization           = 'Audio Interface Initialization';

  sAIFInitializedSBMode        = 'Audio Interface initialized to Sound Blaster (SB) mode.';
  sAIFInitializedWSSMode       = 'Audio Interface initialized to Windows Sound System (WSS) mode.';

  sLineOutRelay                = 'Line Out relay control is ';

  sHardwareInitError           = 'Hardware initialization error.' + #13#10 +
                                 'Audio Interface is either not present or it is faulty.';
  sControllerReinitError       = 'Controller reinitialization error.' + #13#10 +
                                 'Audio Interface is faulty.';

  sMode                        = 'mode';
  sPnP                         = 'PnP';
  snonPnP                      = 'non-PnP';

  sAIFSoundBlaster             = 'Sound Blaster';
  sAIFWindowsSoundSystem       = 'Windows Sound System';

  sHz                          = 'Hz';

  s8bit                        = '8-bit';
  s16bit                       = '16-bit';

  sMono                        = 'Mono';
  sStereo                      = 'Stereo';

  s8bitUlaw                    = '8-bit æ-law';
  s8bitAlaw                    = '8-bit A-law';
  s8bitPCM                     = '8-bit PCM';
  s16bitPCM                    = '16-bit PCM';

  sSBDSPVersion21              = '2.1';
  sSBDSPVersion15              = '1.5';
  sSBDSPVersion32              = '3.2';
  sSBDSPVersion44              = '4.4';

  sOPL3                        = 'OPL3';

  sAudioCodecAD1848orCS4248    = 'AD1848 / CS4248';
  sAudioCodecAD1845orCS4231    = 'AD1845 / CS4231';

  sCrystal16and24MHz           = '16/24 MHz';
  sCrystal16MHz                = '16 MHz';

  sVolumeControlAutomatic      = 'Automatic';
  sVolumeControlNormal         = 'Normal';

  sNA                          = 'N/A';

  sFAILED                      = 'FAILED';
  sOK                          = 'OK';
  sCHANGED                     = 'CHANGED';
  sPENDING                     = 'PENDING';

  sNo                          = 'No';
  sYes                         = 'Yes';

  sDisabled                    = 'Disabled';
  sEnabled                     = 'Enabled';

  sFAILEDOK: packed array[Boolean] of String[Length(sFAILED)] = (
    sFAILED,
    sOK
  );

  sNoYes: packed array[Boolean] of String[Length(sYes)] = (
    sNo,
    sYes
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
  cSpace                       = ' ';
  cFullStop                    = '.';
  cComma                       = ',';
  cSemicolon                   = ':';
  cBackslash                   = '\';
  cSlash                       = '/';
  cEqual                       = '=';
  cMinus                       = '-';
  cOpenBracket                 = '(';
  cClosedBracket               = ')';
  cOpenSquareBracket           = '[';
  cClosedSquareBracket         = ']';

  { program commandline parameters }
  pHelpAlt                     = '-?';
  pHelp                        = '-help';
  pSetup                       = '-setup';
  pPnPSetup                    = '-pnpsetup';
  pROMSetup                    = '-romsetup';
  pMixer                       = '-mixer';
  pInit                        = '-init';
  pWSS                         = '-wss';
  pSB                          = '-sb';
  pQuiet                       = '-quiet';
  pStatus                      = '-status';
  pLineOut                     = '-lineout=';

  pOn                          = 'on';
  pOff                         = 'off';

  { program commandline parameters help }
  kHelpParametersBaseCount     = 9;
{$IFDEF PNPSETUP}
  kHelpParametersCount         = kHelpParametersBaseCount + 1;
{$ELSE}
  kHelpParametersCount         = kHelpParametersBaseCount;
{$ENDIF}
  kHelpParameters: packed array[0..kHelpParametersCount] of PChar = (
    sHelpParamHelp,
    sHelpParamSetup,
{$IFDEF PNPSETUP}
    sHelpParamPnPSetup,
{$ENDIF}
    sHelpParamROMSetup,
    sHelpParamMixer,
    sHelpParamInit,
    sHelpParamWSS,
    sHelpParamSB,
    sHelpParamQuiet,
    sHelpParamStatus,
    sHelpParamLineOut
  );

  { VersaVision UI support messages }
  sMessageBoxError             = 'Error';
  sMessageBoxQuestion          = 'Question';
  sMessageBoxInformation       = 'Information';

  sMessageBoxCancel            = 'Cancel';
  sMessageBoxClose             = 'Close';
  sMessageBoxYes               = 'Yes';
  sMessageBoxNo                = 'No';

  { file masks }
  fmBINFiles                   = 'bin';

  { file mode constants }
  fmReadOnly                   = 0;
  fmWriteOnly                  = 1;
  fmReadWrite                  = 2;

  { file record size }
  frsBinaryFileRecordSize      = 1;

  { general constants }
  kMaxByte                     = 255;
  kRequiredMemory              = 8192;

  { color constants }
  clError                      = clRed;
  clSuccess                    = clGreen;
  clNormal                     = clLightGray;
  clHighlight                  = clWhite;
  clChanged                    = clCyan;
  clPending                    = clLightCyan;

  clFAILEDOK: packed array[Boolean] of Byte = (
    clError,
    clSuccess
  );

  { program color theme }
  clInterfaceFore              = clBlack;
  clInterfaceBack              = clLightGray;

  clMessageBoxFore             = clWhite;
  clMessageBoxBack             = clRed;
  clMessageBoxBtnFore          = clBlue;
  clMessageBoxBtnBack          = clLightGray;
  clMessageBoxBtnAccel         = clRed;
  clMessageBoxBtnHighFore      = clWhite;
  clMessageBoxBtnHighBack      = clRed;
  clMessageBoxBtnHighAccel     = clBlack;

  { program constants }
  kOKFailedXPosition           = 60;

  { keyboard codes }
  kKeyBackspace                = #08;
  kKeyEnter                    = #13;
  kKeyEscape                   = #27;
  kKeyExtended                 = #00;
  kKeyUp                       = #72;
  kKeyDown                     = #80;
  kKeyLeft                     = #75;
  kKeyRight                    = #77;
  kKeyF4                       = #62;
  kKeyF5                       = #63;
  kKeyF6                       = #64;
  kKeyF7                       = #65;
  kKeyF8                       = #66;
  kKeyF9                       = #67;
  kKeyF10                      = #68;

  { Setup program stringtable }
  sSetupTitle                  = 'AUDIO INTERFACE SETUP';

  sSetupAIFMode                = 'Audio Interface Mode';
  sSetupWSSBASE                = 'WSS Address';
  sSetupWSSIRQ                 = 'WSS IRQ';
  sSetupWSSDRQ                 = 'WSS DMA';
  sSetupSBBASE                 = 'SB Address';
  sSetupSBIRQ                  = 'SB IRQ';
  sSetupSBDRQ                  = 'SB DMA';
  sSetupMPU401                 = 'MPU-401';
  sSetupMPUBASE                = 'MPU-401 Address';
  sSetupMPUIRQ                 = 'MPU-401 IRQ';
  sSetupGamePort               = 'Game Port';
  sSetupIDECDROM               = 'IDE CD-ROM';
  sSetupCFIX                   = 'Audio Codec';
  sSetupFMAP                   = 'Audio Codec Crystals';
  sSetupWSSSampleRate          = 'WSS Sampling Rate';
  sSetupWSSBitDepth            = 'WSS Bit Depth';
  sSetupWSSSoundOutput         = 'WSS Sound Output';
  sSetupSBSampleRate           = 'SB Sampling Rate';
  sSetupSBBitDepth             = 'SB Bit Depth';
  sSetupSBSoundOutput          = 'SB Sound Output';
  sSetupSBDSPVersion           = 'SB DSP Version';
  sSetupSBADPCM                = 'SB ADPCM';
  sSetupCFIFO                  = 'SB Command FIFO';
  sSetupAVC                    = 'Volume Control';

  sSetupCmdProgramCmds         = 'PROGRAM COMMANDS';
  sSetupCmdF8                  = 'F8';
  sSetupCmdDefaultConfig       = 'Default Configuration';
  sSetupCmdF9                  = 'F9';
  sSetupCmdReloadConfig        = 'Reload Configuration';
  sSetupCmdF10                 = 'F10';
  sSetupCmdSaveExit            = 'Save and Exit';
  sSetupCmdESC                 = 'ESC';
  sSetupCmdExit                = 'Exit';

  sSetupCmdOptionCmds          = 'OPTION COMMANDS';
  sSetupCmdUpDown              = '/';
  sSetupCmdSelectOption        = 'Select Option';
  sSetupCmdLeftRight           = #27'/'#26;
  sSetupCmdModifyOption        = 'Modify Option';

  sSetupSoundController        = 'SOUND CONTROLLER';
  sSetupOPTi82c924             = 'OPTi 82c924 REV. ';

  sSetupConfigChanged          = 'Audio Interface configuration has changed.' + #13#10 +
                                 'Save changes?';

  { Setup program color theme }
  clSetupFore                  = clLightGray;
  clSetupBack                  = clBlue;

  clSetupCmdHigh               = clLightCyan;
  clSetupCmdHeader             = clWhite;
  clSetupCmdFore               = clLightGray;
  clSetupCmdBack               = clDarkGray;

  { Setup program constants }
  kSetupStartupDelay           = 500;

  kSetupKeyX                   = 2;
  kSetupValueX                 = 25;
  kSetupKeyValueWidth          = 26;

  kSetupCommandsLeft           = 50;
  kSetupCommandsTop            = 2;
  kSetupCommandsWidth          = 31;
  kSetupCommandsHeight         = 24;

  kSetupCmdX                   = 52;

  kSetupCmdCount               = 5;

  kSetupSoundControllerY       = 23;
  kSetupOPTi82c924Y            = 24;

  kSetupOptionsLeft            = 1;
  kSetupOptionsTop             = 2;
  kSetupOptionsWidth           = 49;
  kSetupOptionsHeight          = 24;

  kSetupOptionX                = 1;
  kSetupOptionWidth            = 23;
  kSetupOptionHeight           = 1;
  kSetupOptionEditX            = 24;
  kSetupOptionEditWidth        = 26;
  kSetupOptionEditHeight       = 1;

  { Setup program default initialization values }
  kSetupBitMODDefault          = bsNotSet;
  kSetupBitPDNDefault          = bsNotSet;
  kSetupBitGPENDefault         = bsSet;

  kSetupBitOPL4Default         = bsNotSet;

  kSetupBitFMAPDefault         = bsNotSet;
  kSetupBitCMDPASDefault       = bsSet;

  kSetupBitADPCMENDefault      = bsSet;
  kSetupBitGPOUTDefault        = bsNotSet;
  kSetupBitPNPMODEDefault      = bsSet;
  kSetupBitFMCLKDefault        = bsNotSet;
  kSetupBitSILENCEDefault      = bsNotSet;

  kSetupBitAVCENDefault        = bsSet;
  kSetupBitOPL5Default         = bsNotSet;
  kSetupBitSHPASSDefault       = bsSet;
  kSetupBitSBACCESSDefault     = bsNotSet;
  kSetupBitCFIFODefault        = bsSet;
  kSetupBitEPENDefault         = bsSet;
  kSetupBitCFIXDefault         = bsSet;

  kSetupBitMPU401Default       = bsSet;
  kSetupBitDRQTMENDefault      = bsSet;
  kSetupBitAUDIOENDefault      = bsSet;

  kSetupWSSBASEDefault         = $0530;
  kSetupWSSIRQDefault          = $FF;
  kSetupWSSDRQDefault          = $01;

  kSetupSBBASEDefault          = $0220;
  kSetupSBIRQDefault           = $05;
  kSetupSBDRQDefault           = $01;
  kSetupSBDSPVerDefault        = sdVersion32;

  kSetupMPUBASEDefault         = $0330;
  kSetupMPUIRQDefault          = $09;

  kSetupCDBASEDefault          = $0340;
  kSetupCDIRQDefault           = $FF;
  kSetupCDDRQDefault           = $03;
  kSetupIDECDROMDefault        = bsNotSet;

  kSetupWSSSmpRateDefault      = sr44100;
  kSetupWSSBitDepthDefault     = bd16bit;
  kSetupWSSSndOutDefault       = soStereo;

  kSetupSBSmpRateDefault       = sr22050;
  kSetupSBBitDepthDefault      = bd8bit;
  kSetupSBSndOutDefault        = soStereo;

  { PnP Setup program stringtable }
  sPnPSetupTitle               = 'AUDIO INTERFACE PnP SETUP';

  sPnPSetupCmdProgramCmds      = 'PROGRAM COMMANDS';
  sPnPSetupCmdESC              = 'ESC';
  sPnPSetupCmdExit             = 'Exit';

  { PnP Setup program color theme }
  clPnPSetupFore               = clLightGray;
  clPnPSetupBack               = clBlue;

  clPnPSetupCmdHigh            = clLightCyan;
  clPnPSetupCmdHeader          = clWhite;
  clPnPSetupCmdFore            = clLightGray;
  clPnPSetupCmdBack            = clDarkGray;

  { PnP Setup program constants }
  kPnPSetupStartupDelay        = 500;

  kPnPSetupComponentsLeft      = 1;
  kPnPSetupComponentsTop       = 2;
  kPnPSetupComponentsWidth     = 49;
  kPnPSetupComponentsHeight    = 24;

  kPnPSetupCommandsLeft        = 50;
  kPnPSetupCommandsTop         = 2;
  kPnPSetupCommandsWidth       = 31;
  kPnPSetupCommandsHeight      = 24;

  kPnPSetupCmdX                = 52;

  kPnPSetupCmdCount            = 0;

  { ROM Setup program stringtable }
  sROMSetupTitle               = 'AUDIO INTERFACE (EEP)ROM SETUP';

  sROMSetupDefaultFilename     = 'eeprom.bin';

  sROMSetupFilename            = 'Filename';
  sROMSetupOperation           = 'Operation';
  sROMSetupStatus              = 'Status';
  sROMSetupEEPROM              = 'EEPROM';
  sROMSetup93C56A              = '93C56A';
  sROMSetupProgress            = 'Progress';
  sROMSetupRawData             = 'Raw Data';

  sROMSetupEraseFast           = 'erase (fast)';
  sROMSetupEraseSlow           = 'erase (slow)';
  sROMSetupRead                = 'read';
  sROMSetupWrite               = 'write';

  sROMSetupFileExists          = 'A file with this name already exists.' + #13#10 +
                                 'Overwrite file?';
  sROMSetupFileNotExists       = 'A file with this name does not exist.' + #13#10 +
                                 'Please specify a different filename.';

  sROMSetupCmdProgramCmds      = 'PROGRAM COMMANDS';
  sROMSetupCmdF4               = 'F4';
  sROMSetupCmdEditFilename     = 'Edit Filename';
  sROMSetupCmdF5               = 'F5';
  sROMSetupCmdEraseEEPROMF     = 'Erase EEPROM (Fast)';
  sROMSetupCmdF6               = 'F6';
  sROMSetupCmdEraseEEPROMS     = 'Erase EEPROM (Slow)';
  sROMSetupCmdF7               = 'F7';
  sROMSetupCmdReadEEPROM       = 'Read EEPROM';
  sROMSetupCmdF8               = 'F8';
  sROMSetupCmdWriteEEPROM      = 'Write EEPROM';
  sROMSetupCmdESC              = 'ESC';
  sROMSetupCmdExit             = 'Exit';

  { ROM Setup program color theme }
  clROMSetupFore               = clLightGray;
  clROMSetupBack               = clBlue;

  clROMSetupEditFore           = clROMSetupFore;
  clROMSetupEditBack           = clROMSetupBack;
  clROMSetupEditHighFore       = clWhite;
  clROMSetupEditHighBack       = clRed;

  clROMSetupProgressFore       = clROMSetupFore;
  clROMSetupProgressBack       = clROMSetupBack;
  clROMSetupProgressTitle      = clWhite;
  clROMSetupProgressColor      = clGreen;

  clROMSetupRawDataFore        = clROMSetupFore;
  clROMSetupRawDataBack        = clROMSetupBack;
  clROMSetupRawDataTitle       = clWhite;

  clROMSetupCmdHigh            = clLightCyan;
  clROMSetupCmdHeader          = clWhite;
  clROMSetupCmdFore            = clLightGray;
  clROMSetupCmdBack            = clDarkGray;

  { ROM Setup program constants }
  kROMSetupStartupDelay        = 500;
  kROMSetupOperationDelay      = 500;

  kROMSetupComponentsLeft      = 1;
  kROMSetupComponentsTop       = 2;
  kROMSetupComponentsWidth     = 49;
  kROMSetupComponentsHeight    = 24;

  kROMSetupKeyX                = 2;
  kROMSetupValueX              = 15;
  kROMSetupKeyValueWidth       = 26;

  kROMSetupKeyValueCount       = 3;

  kROMSetupEditX               = kROMSetupValueX;
  kROMSetupEditY               = 3;
  kROMSetupEditWidth           = 34;
  kROMSetupEditMaxLength       = kROMSetupEditWidth;

  kROMSetupProgressBarX        = kROMSetupKeyX;
  kROMSetupProgressBarY        = 8;
  kROMSetupProgressBarWidth    = 47;
  kROMSetupProgressBarMin      = 0;

  kROMSetupRawDataX            = kROMSetupKeyX;
  kROMSetupRawDataY            = 12;
  kROMSetupRawDataWidth        = 47;
  kROMSetupRawDataHeight       = 13;
  kROMSetupRawDataLength       = 43;

  kROMSetupOperationX          = kROMSetupValueX;
  kROMSetupOperationY          = 4;
  kROMSetupStatusX             = kROMSetupValueX;
  kROMSetupStatusY             = 5;
  kROMSetupOpStatusWidth       = 20;
  kROMSetupOpStatusHeight      = 2;

  kROMSetupCommandsLeft        = 50;
  kROMSetupCommandsTop         = 2;
  kROMSetupCommandsWidth       = 31;
  kROMSetupCommandsHeight      = 24;

  kROMSetupCmdX                = 52;

  kROMSetupCmdCount            = 5;

  { Mixer program stringtable }
  sMixerTitle                  = 'AUDIO INTERFACE MIXER';

  sMixerVolumeDAC              = 'DAC Output Volume';
  sMixerVolumeFMAUXIn          = 'FM Synthesizer & AUX In Volume';
  sMixerVolumeCDROMLineIn      = 'CD-ROM & Line In Volume';
  sMixerVolumeADCInputGain     = 'ADC Input Gain';
  sMixerVolumeDME              = 'Digital Mix Volume (Mono)';

  sMixerCmdProgramCmds         = 'PROGRAM COMMANDS';
  sMixerCmdF8                  = 'F8';
  sMixerCmdDefaultConfig       = 'Default Configuration';
  sMixerCmdF9                  = 'F9';
  sMixerCmdReloadConfig        = 'Reload Configuration';
  sMixerCmdF10                 = 'F10';
  sMixerCmdSaveExit            = 'Save and Exit';
  sMixerCmdESC                 = 'ESC';
  sMixerCmdExit                = 'Exit';

  sMixerCmdVolumeCmds          = 'VOLUME COMMANDS';
  sMixerCmdUpDown              = '/';
  sMixerCmdSelectDevice        = 'Select Device';
  sMixerCmdLeftRight           = #27'/'#26;
  sMixerCmdModifyVolume        = 'Modify Volume +SFT=L/R';

  sMixerCmdInputDeviceCmds     = 'INPUT DEVICE COMMANDS';
  sMixerCmd1                   = '1';
  sMixerCmdLineIn              = 'Line In';
  sMixerCmd2                   = '2';
  sMixerCmdFMAUXIn             = 'FM & AUX In';
  sMixerCmd3                   = '3';
  sMixerCmdMicrophone          = 'Microphone';
  sMixerCmd4                   = '4';
  sMixerCmdPostMixedDAC        = 'Post-Mixed DAC';

  sMixerCmdAdditionalCmds      = 'ADDITIONAL COMMANDS';
  sMixerCmd5                   = '5';
  sMixerCmdMicrophoneGain      = 'Microphone Gain +20dB';
  sMixerCmd6                   = '6';
  sMixerCmdDigitalMix          = 'Digital Mix';
  sMixerCmd7                   = '7';
  sMixerCmdOutputsEnabled      = 'Outputs Enabled';

  sMixerSliderLeft             = 'LEFT';
  sMixerSliderRight            = 'RIGHT';

  sMixerConfigChanged          = 'Mixer configuration has changed.' + #13#10 +
                                 'Save changes?';

  { Mixer program color theme }
  clMixerFore                  = clLightGray;
  clMixerBack                  = clBlue;

  clMixerSliderFore            = clMixerFore;
  clMixerSliderBack            = clMixerBack;
  clMixerSliderTitle           = clWhite;
  clMixerSliderText            = clLightGray;
  clMixerSliderHighFore        = clWhite;
  clMixerSliderHighBack        = clRed;
  clMixerSliderGrid            = clBrown;
  clMixerSliderTip             = clWhite;
  clMixerSliderNormal          = clLightGray;
  clMixerSliderLow             = clGreen;
  clMixerSliderMedium          = clLightGreen;
  clMixerSliderHigh            = clYellow;
  clMixerSliderVeryHigh        = clLightRed;

  clMixerStatCmdHigh           = clLightCyan;
  clMixerStatCmdHeader         = clWhite;
  clMixerStatCmdFore           = clLightGray;
  clMixerStatCmdBack           = clDarkGray;
  clMixerDynCmdHeader          = clWhite;
  clMixerDynCmdFore            = clLightGray;
  clMixerDynCmdBack            = clBlue;

  { Mixer program constants }
  kMixerStartupDelay           = 500;

  kMixerSlidersLeft            = 1;
  kMixerSlidersTop             = 2;
  kMixerSlidersWidth           = 49;
  kMixerSlidersHeight          = 24;
  kMixerSlidersLeftY           = 1;
  kMixerSlidersRightY          = 3;
  kMixerSlidersTipX            = 7;
  kMixerSlidersValueX          = 40;

  kMixerSliderX                = 2;

  kMixerDACSliderY             = 2;
  kMixerAUX1SliderY            = 7;
  kMixerAUX2SliderY            = 12;
  kMixerInputGainSliderY       = 17;
  kMixerDMESliderY             = 22;

  kMixerSliderMin              = 0;
  kMixerSliderMax              = 30;

  kMixerCommandsLeft           = 50;
  kMixerCommandsTop            = 2;
  kMixerCommandsWidth          = 31;
  kMixerCommandsHeight         = 12;

  kMixerCmdX                   = 52;

  kMixerStatCmdCount           = 5;
  kMixerDynCmdCount            = 6;

  kMixerOptionsLeft            = 50;
  kMixerOptionsTop             = 14;
  kMixerOptionsWidth           = 31;
  kMixerOptionsHeight          = 12;

  kMixerOptionX                = 57;
  kMixerOptionWidth            = 21;
  kMixerOptionHeight           = 1;

  { Mixer program default initialization values }
  kMixerDACDefault             = 14;
  kMixerAUX1Default            = 30;
  kMixerAUX2Default            = 0;
  kMixerInputDeviceDefault     = cidtLineIn;
  kMixerInputGainDefault       = 0;
  kMixerMicGainDefault         = False;
  kMixerDigitalMixDefault      = False;
  kMixerDMEDefault             = 0;
  kMixerOutputsEnDefault       = True;

  { Status program stringtable }
  sStatusAIFModel              = 'ISA Audio Interface model 2486-AIF-401';
  sStatusAIFMode               = 'Audio Interface Mode';
  sStatusBASE                  = 'Address';
  sStatusIRQ                   = 'Interrupt Request';
  sStatusDRQ                   = 'Direct Memory Access';
  sStatusDSP                   = 'DSP Version';
  sStatusFM                    = 'FM Synthesizer';
  sStatusMPU401                = 'MPU-401 Address';
  sStatusGamePort              = 'Game Port';
  sStatusOutputFormat          = 'Audio Output Format';
  sStatusLineOutRelay          = 'Line Out Relay';

  { Status program constants }
  kStatusItemX                 = 1;
  kStatusSemicolonX            = 23;
  kStatusValueX                = 25;

implementation

end.
