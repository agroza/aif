{ --------------------------------------------------------------------------- }
{ - VersaVision Screen Routines (Screen.pas)                                - }
{ - Integrant part of VersaVision Framework                                 - }
{ - Copyright (C) 1998-2021 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit Screen;

interface

uses
  Types;

type
  TKeyValueColors = record
    Foreground: Byte;
    Background: Byte;
  end;

  TKeyValueData = record
    NameX: Byte;
    ValueX: Byte;
    PositionY: Byte;
    Colors: TKeyValueColors;
    Name: String;
    Value: String
  end;

  TStereoSliderColors = record
    Foreground: Byte;
    Background: Byte;
    Title: Byte;
    Text: Byte;
    HighForeground: Byte;
    HighBackground: Byte;
    Grid: Byte;
    Tip: Byte;
    Normal: Byte;
    Low: Byte;
    Medium: Byte;
    High: Byte;
    VeryHigh: Byte;
  end;

  TStereoSliderData = record
    PositionX: Byte;
    PositionY: Byte;
    Colors: TStereoSliderColors;
    Min: Byte;
    Max: Byte;
    LeftPosition: Byte;
    RightPosition: Byte;
    Locked: Boolean;
    Title: String;
  end;

  TSliderDirection = (
    sdUp,
    sdDown
  );

  TProgressBarColors = record
    Foreground: Byte;
    Background: Byte;
    Title: Byte;
    Progress: Byte;
  end;

  TProgressBarData = record
    PositionX: Byte;
    PositionY: Byte;
    Width: Byte;
    Colors: TProgressBarColors;
    Min: Word;
    Max: Word;
    Progress: Word;
    Title: String;
  end;

procedure SetHaltOnErrors(const AValue: Boolean);

procedure ScreenWriteActionIf(const AMessage: String; const AAction, ACondition: Boolean);

procedure ScreenStoreColors;
procedure ScreenRestoreColors;
procedure ScreenSetVVColors;

procedure ScreenDrawTitleBar(const AForeColor, ABackColor, ATextColor: Byte; const ACaption: String);

procedure ScreenDrawCommand(const ALeft, ATop, AHighlight, AColor, ABackground: Byte; const AShortcut, ADescription: String);

procedure ScreenDrawKeyValue(const AKeyValueData: TKeyValueData);

procedure ScreenDrawStereoSlider(const ASliderData: TStereoSliderData);
procedure ScreenHighlightStereoSlider(const ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const AValue: Boolean);
procedure ScreenMoveStereoSlider(var ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const ADirection: TSliderDirection);

procedure ScreenUpdateProgressBar(const AProgressBarData: TProgressBarData);
procedure ScreenDrawProgressBar(const AProgressBarData: TProgressBarData);
procedure ScreenResetProgressBar(const AProgressBarData: TProgressBarData);

implementation

uses
  Consts,
  Crt,
  Routines,
  Video;

const
  kVVBlue: TPaletteColor = ( RIntensity: 0; GIntensity: 0; BIntensity: 16 );
  kVVRed: TPaletteColor = ( RIntensity: 32; GIntensity: 0; BIntensity: 0 );
  kVVBrown: TPaletteColor = ( RIntensity: 26; GIntensity: 26; BIntensity: 26 );
  kVVDarkGray: TPaletteColor = ( RIntensity: 10; GIntensity: 10; BIntensity: 10 );
  kVVLightGreen: TPaletteColor = ( RIntensity: 0; GIntensity: 48; BIntensity: 0 );
  kVVLightRed: TPaletteColor = ( RIntensity: 50; GIntensity: 30; BIntensity: 0 );
  kVVYellow: TPaletteColor = ( RIntensity: 50; GIntensity: 50; BIntensity: 0 );

var
  IGHaltOnErrors: Boolean;

  IGVGAPalette: array[kVGAPaletteStart..kVGAPaletteEnd] of TPaletteColor;

{ private declarations }

function ScreenGetSliderBarColor(const APosition: Byte; const AColors: TStereoSliderColors): Byte;
begin
  case APosition of
    0..10:
      ScreenGetSliderBarColor := AColors.Low;

    11..20:
      ScreenGetSliderBarColor := AColors.Medium;

    21..25:
      ScreenGetSliderBarColor := AColors.High;

    26..30:
      ScreenGetSliderBarColor := AColors.VeryHigh;

  end;
end;

procedure ScreenUpdateStereoSlider(const ASliderData: TStereoSliderData; const AChannel: TCodecSoundChannel);
var
  LPosition: Byte;
  LPositionY: Byte;

begin
  case AChannel of
    scLeft:
      begin
        LPosition := ASliderData.LeftPosition;
        LPositionY := kMixerSlidersLeftY;
      end;

    scRight:
      begin
        LPosition := ASliderData.RightPosition;
        LPositionY := kMixerSlidersRightY;
      end;

  end;

  VideoWriteCharAttrAt(
    ASliderData.PositionX + LPosition + kMixerSlidersTipX,
    ASliderData.PositionY + LPositionY,
    cMixerSliderTip,
    VideoAttribute(
      ASliderData.Colors.Tip,
      ASliderData.Colors.Background
    )
  );

  VideoWriteStringAt(
    ASliderData.PositionX + kMixerSlidersValueX,
    ASliderData.PositionY + LPositionY,
    PadPercent(Round((LPosition / ASliderData.Max) * 100)),
    ASliderData.Colors.Text,
    ASliderData.Colors.Background
  );
end;

procedure ScreenDrawSliderBar(const ASliderData: TStereoSliderData; const APosition, APositionY: Byte;
  const AChannelText: String; const AChar: Char);
var
  I: Byte;
  LAttribute: Byte;

begin
  VideoWriteStringAt(
    ASliderData.PositionX,
    ASliderData.PositionY + APositionY,
    AChannelText,
    ASliderData.Colors.Text,
    ASliderData.Colors.Background
  );

  for I := 0 to APosition do
  begin
    VideoWriteCharAttrAt(
      ASliderData.PositionX + I + kMixerSlidersTipX,
      ASliderData.PositionY + APositionY,
      AChar,
      VideoAttribute(
        ScreenGetSliderBarColor(I, ASliderData.Colors),
        ASliderData.Colors.Background
      )
    );
  end;

  LAttribute := VideoAttribute(
    ASliderData.Colors.Normal,
    ASliderData.Colors.Background
  );

  if APosition < ASliderData.Max then
  begin
    for I := Succ(APosition) to ASliderData.Max do
    begin
      VideoWriteCharAttrAt(
        ASliderData.PositionX + I + kMixerSlidersTipX,
        ASliderData.PositionY + APositionY,
        AChar,
        LAttribute
      );
    end;
  end;
end;

procedure ScreenActStereoSlider(const ASliderData: TStereoSliderData; var APosition: Byte;
  const ADirection: TSliderDirection; const APositionY: Byte; const AChar: Char);
var
  LDeletePosition: Byte;
  LAttribute: Byte;

begin
  LDeletePosition := APosition;

  case ADirection of
    sdUp:
      begin
        if APosition < ASliderData.Max then
        begin
          Inc(APosition);
        end;

        LAttribute := VideoAttribute(
          ScreenGetSliderBarColor(LDeletePosition, ASliderData.Colors),
          ASliderData.Colors.Background
        );
      end;

    sdDown:
      begin
        if APosition > ASliderData.Min then
        begin
          Dec(APosition);
        end;

        LAttribute := VideoAttribute(
          ASliderData.Colors.Normal,
          ASliderData.Colors.Background
        );
      end;

  end;

  VideoWriteCharAttrAt(
    ASliderData.PositionX + LDeletePosition + kMixerSlidersTipX,
    ASliderData.PositionY + APositionY,
    AChar,
    LAttribute
  );
end;

{ public declarations }

procedure SetHaltOnErrors(const AValue: Boolean);
begin
  if IGHaltOnErrors <> AValue then
  begin
    IGHaltOnErrors := AValue;
  end;
end;

procedure ScreenWriteActionIf(const AMessage: String; const AAction, ACondition: Boolean);
var
  LPosition: Byte;
  LPositionY: Byte;

begin
  if ACondition then
  begin
    Writeln(AMessage);

    LPosition := kOKFailedXPosition;
    LPositionY := Pred(WhereY);

    VideoWriteCharAt(LPosition, LPositionY, cOpenSquareBracket);
    Inc(LPosition, 2);

    if AAction then
    begin
      VideoWriteStringAt(LPosition, LPositionY, sOK, clSuccess, clBlack);
      Inc(LPosition, 3);
    end else
    begin
      VideoWriteStringAt(LPosition, LPositionY, sFAILED, clError, clBlack);
      Inc(LPosition, 7);
    end;

    VideoWriteCharAt(LPosition, LPositionY, cClosedSquareBracket);
  end;

  if IGHaltOnErrors and not AAction then
  begin
    Writeln;
    Writeln(sHardwareInitError);
    Halt(kHardwareInitError);
  end;
end;

procedure ScreenStoreColors;
var
  I: Byte;

begin
  for I := kVGAPaletteStart to kVGAPaletteEnd do
  begin
    VideoGetPaletteColor(kVGAPaletteIndex[I], IGVGAPalette[I]);
  end;
end;

procedure ScreenRestoreColors;
var
  I: Byte;

begin
  for I := kVGAPaletteStart to kVGAPaletteEnd do
  begin
    VideoSetPaletteColor(kVGAPaletteIndex[I], IGVGAPalette[I]);
  end;
end;

procedure ScreenSetVVColors;
begin
  ScreenStoreColors;

  VideoSetPaletteColor(clVGAPaletteBlue, kVVBlue);
  VideoSetPaletteColor(clVGAPaletteRed, kVVRed);
  VideoSetPaletteColor(clVGAPaletteBrown, kVVBrown);
  VideoSetPaletteColor(clVGAPaletteDarkGray, kVVDarkGray);
  VideoSetPaletteColor(clVGAPaletteLightRed, kVVLightRed);
  VideoSetPaletteColor(clVGAPaletteLightGreen, kVVLightGreen);
  VideoSetPaletteColor(clVGAPaletteYellow, kVVYellow);
end;

procedure ScreenDrawTitleBar(const AForeColor, ABackColor, ATextColor: Byte; const ACaption: String);
begin
  VideoWriteRegion(k80x25Left, k80x25Top, k80x25Width, 1, cSpace, VideoAttribute(AForeColor, ABackColor));
  VideoWriteStringAt((k80x25Width div 2) - (Length(ACaption) div 2), k80x25Top, ACaption, ATextColor, ABackColor);
end;

procedure ScreenDrawCommand(const ALeft, ATop, AHighlight, AColor, ABackground: Byte; const AShortcut, ADescription: String);
begin
  VideoWriteStringAt(ALeft, ATop, AShortcut, AHighlight, ABackground);
  VideoWriteStringAt(ALeft + 5, ATop, ADescription, AColor, ABackground);
end;

procedure ScreenDrawKeyValue(const AKeyValueData: TKeyValueData);
begin
  VideoWriteStringAt(
    AKeyValueData.NameX,
    AKeyValueData.PositionY,
    AKeyValueData.Name,
    AKeyValueData.Colors.Foreground,
    AKeyValueData.Colors.Background
  );

  VideoWriteCharAttrAt(
    AKeyValueData.ValueX - 2,
    AKeyValueData.PositionY,
    cSemicolon,
    VideoAttribute(
      AKeyValueData.Colors.Foreground,
      AKeyValueData.Colors.Background
    )
  );

  VideoWriteStringAt(
    AKeyValueData.ValueX,
    AKeyValueData.PositionY,
    AKeyValueData.Value,
    AKeyValueData.Colors.Foreground,
    AKeyValueData.Colors.Background
  );
end;

procedure ScreenDrawStereoSlider(const ASliderData: TStereoSliderData);
begin
  VideoWriteStringAt(
    ASliderData.PositionX + kMixerSlidersTipX,
    ASliderData.PositionY,
    ASliderData.Title,
    ASliderData.Colors.Title,
    ASliderData.Colors.Background
  );

  VideoWriteStringAt(
    ASliderData.PositionX + kMixerSlidersTipX,
    ASliderData.PositionY + 2,
    sMixerSliderGrid,
    ASliderData.Colors.Grid,
    ASliderData.Colors.Background
  );

  ScreenDrawSliderBar(ASliderData, ASliderData.LeftPosition, kMixerSlidersLeftY, sMixerSliderLeft, cMixerSliderLeftBar);
  ScreenDrawSliderBar(ASliderData, ASliderData.RightPosition, kMixerSlidersRightY, sMixerSliderRight, cMixerSliderRightBar);

  ScreenUpdateStereoSlider(ASliderData, scLeft);
  ScreenUpdateStereoSlider(ASliderData, scRight);
end;

procedure ScreenHighlightStereoSlider(const ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const AValue: Boolean);
var
  LLeftAttribute: Byte;
  LRightAttribute: Byte;

begin
  if AValue then
  begin
    case AChannel of
      scLeft:
        begin
          LLeftAttribute := VideoAttribute(
            ASliderData.Colors.HighForeground,
            ASliderData.Colors.HighBackground
          );

          LRightAttribute := VideoAttribute(
            ASliderData.Colors.Text,
            ASliderData.Colors.Background
          );
        end;

      scRight:
        begin
          LLeftAttribute := VideoAttribute(
            ASliderData.Colors.Text,
            ASliderData.Colors.Background
          );

          LRightAttribute := VideoAttribute(
            ASliderData.Colors.HighForeground,
            ASliderData.Colors.HighBackground
          );
        end;

    end;
  end else
  begin
    LLeftAttribute := VideoAttribute(
      ASliderData.Colors.Text,
      ASliderData.Colors.Background
    );

    LRightAttribute := VideoAttribute(
      ASliderData.Colors.Text,
      ASliderData.Colors.Background
    );
  end;

  VideoHighlightRegion(
    ASliderData.PositionX,
    ASliderData.PositionY + kMixerSlidersLeftY,
    4,
    1,
    LLeftAttribute
  );

  VideoHighlightRegion(
    ASliderData.PositionX,
    ASliderData.PositionY + kMixerSlidersRightY,
    5,
    1,
    LRightAttribute
  );
end;

procedure ScreenMoveStereoSlider(var ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const ADirection: TSliderDirection);
begin
  if ASliderData.Locked then
  begin
    ScreenActStereoSlider(ASliderData, ASliderData.LeftPosition, ADirection, kMixerSlidersLeftY, cMixerSliderLeftBar);
    ScreenUpdateStereoSlider(ASliderData, scLeft);

    ScreenActStereoSlider(ASliderData, ASliderData.RightPosition, ADirection, kMixerSlidersRightY, cMixerSliderRightBar);
    ScreenUpdateStereoSlider(ASliderData, scRight);
  end else
  begin
    case AChannel of
      scLeft:
        ScreenActStereoSlider(ASliderData, ASliderData.LeftPosition, ADirection, kMixerSlidersLeftY, cMixerSliderLeftBar);

      scRight:
        ScreenActStereoSlider(ASliderData, ASliderData.RightPosition, ADirection, kMixerSlidersRightY, cMixerSliderRightBar);

    end;

    ScreenUpdateStereoSlider(ASliderData, AChannel);
  end;
end;

procedure ScreenUpdateProgressBar(const AProgressBarData: TProgressBarData);
var
  LProgress: Real;

begin
  LProgress := AProgressBarData.Progress / AProgressBarData.Max;

  if AProgressBarData.Progress > 0 then
  begin
    VideoWriteCharAttrAt(
      Succ(AProgressBarData.PositionX) + Round(LProgress * (AProgressBarData.Width - 3)),
      AProgressBarData.PositionY + 2,
      cProgressBarFill,
      VideoAttribute(
        AProgressBarData.Colors.Progress,
        AProgressBarData.Colors.Background
      )
    );
  end;

  VideoWriteStringAt(
    AProgressBarData.PositionX + AProgressBarData.Width - 5,
    AProgressBarData.PositionY,
    PadPercent(Round(LProgress * 100)),
    AProgressBarData.Colors.Foreground,
    AProgressBarData.Colors.Background
  );
end;

procedure ScreenDrawProgressBar(const AProgressBarData: TProgressBarData);
var
  LGeneralAttribute: Byte;
  LProgressAttribute: Byte;

begin
  VideoWriteStringAt(
    AProgressBarData.PositionX,
    AProgressBarData.PositionY,
    AProgressBarData.Title,
    AProgressBarData.Colors.Title,
    AProgressBarData.Colors.Background
  );

  LGeneralAttribute := VideoAttribute(
    AProgressBarData.Colors.Foreground,
    AProgressBarData.Colors.Background
  );

  LProgressAttribute := VideoAttribute(
    AProgressBarData.Colors.Progress,
    AProgressBarData.Colors.Background
  );

  VideoWriteCharAttrAt(
    AProgressBarData.PositionX,
    AProgressBarData.PositionY + 1,
    cProgressBarTopLeft,
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    AProgressBarData.PositionX,
    AProgressBarData.PositionY + 2,
    cProgressBarLeft,
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    AProgressBarData.PositionX,
    AProgressBarData.PositionY + 3,
    cProgressBarBottomLeft,
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    Pred(AProgressBarData.PositionX + AProgressBarData.Width),
    AProgressBarData.PositionY + 1,
    cProgressBarTopRight,
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    Pred(AProgressBarData.PositionX + AProgressBarData.Width),
    AProgressBarData.PositionY + 2,
    cProgressBarRight,
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    Pred(AProgressBarData.PositionX + AProgressBarData.Width),
    AProgressBarData.PositionY + 3,
    cProgressBarBottomRight,
    LGeneralAttribute
  );

  VideoWriteRegion(
    Succ(AProgressBarData.PositionX),
    AProgressBarData.PositionY + 1,
    AProgressBarData.Width - 2,
    1,
    cProgressBarTopBottom,
    LGeneralAttribute
  );

  VideoWriteRegion(
    Succ(AProgressBarData.PositionX),
    AProgressBarData.PositionY + 2,
    AProgressBarData.Width - 2,
    1,
    cProgressBarEmpty,
    LProgressAttribute
  );

  VideoWriteRegion(
    Succ(AProgressBarData.PositionX),
    AProgressBarData.PositionY + 3,
    AProgressBarData.Width - 2,
    1,
    cProgressBarTopBottom,
    LGeneralAttribute
  );

  ScreenUpdateProgressBar(AProgressBarData);
end;

procedure ScreenResetProgressBar(const AProgressBarData: TProgressBarData);
begin
  VideoWriteRegion(
    Succ(AProgressBarData.PositionX),
    AProgressBarData.PositionY + 2,
    AProgressBarData.Width - 2,
    1,
    cProgressBarEmpty,
    VideoAttribute(
      AProgressBarData.Colors.Progress,
      AProgressBarData.Colors.Background
    )
  );

  ScreenUpdateProgressBar(AProgressBarData);
end;

end.
