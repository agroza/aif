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

  TEditColors = record
    Foreground: Byte;
    Background: Byte;
    HighForeground: Byte;
    HighBackground: Byte;
  end;

  TEditData = record
    PositionX: Byte;
    PositionY: Byte;
    Width: Byte;
    Colors: TEditColors;
    Text: String;
  end;

  TFrameColors = record
    Foreground: Byte;
    Background: Byte;
    Title: Byte;
  end;

  TFrameData = record
    PositionX: Byte;
    PositionY: Byte;
    Width: Byte;
    Height: Byte;
    Colors: TFrameColors;
    Title: String;
  end;

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

procedure ScreenStereoSliderDraw(const ASliderData: TStereoSliderData);
procedure ScreenStereoSliderHighlight(const ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const AValue: Boolean);
procedure ScreenStereoSliderMove(var ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const ADirection: TSliderDirection);

procedure ScreenEditDraw(const AEditData: TEditData);
procedure ScreenEditChange(var AEditData: TEditData);

procedure ScreenSingleFrameDraw(const AFrameData: TFrameData);

procedure ScreenProgressBarDraw(const AProgressBarData: TProgressBarData);
procedure ScreenProgressBarUpdate(const AProgressBarData: TProgressBarData);
procedure ScreenProgressBarReset(const AProgressBarData: TProgressBarData);

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

  { UI objects constants. }
  sSliderGrid               = 'цдедедедедедедедедедедедедедед╢';
  cSliderTip                = 'ш';
  cSliderLeftBar            = 'ъ';
  cSliderRightBar           = 'э';

  cSingleFrameTopLeft       = 'з';
  cSingleFrameLeft          = 'Ё';
  cSingleFrameBottomLeft    = 'ю';
  cSingleFrameTopBottom     = 'д';
  cSingleFrameTopRight      = '©';
  cSingleFrameRight         = 'Ё';
  cSingleFrameBottomRight   = 'ы';

  cProgressBarEmpty         = '╟';
  cProgressBarFill          = 'ш';

  kProgressBarHeight        = 3;

var
  IGHaltOnErrors: Boolean;

  IGVGAPalette: array[kVGAPaletteStart..kVGAPaletteEnd] of TPaletteColor;

{ private and public declarations }

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

    VideoWriteCharAt(
      LPosition,
      LPositionY,
      cOpenSquareBracket
    );

    Inc(LPosition, 2);

    VideoWriteStringAt(
      LPosition,
      LPositionY,
      sFAILEDOK[AAction],
      clFAILEDOK[AAction],
      clBlack
    );

    Inc(LPosition, Succ(Length(sFAILEDOK[AAction])));

    VideoWriteCharAt(
      LPosition,
      LPositionY,
      cClosedSquareBracket
    );
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

function StereoSliderGetBarColor(const APosition: Byte; const AColors: TStereoSliderColors): Byte;
begin
  case APosition of
    0..10:
      StereoSliderGetBarColor := AColors.Low;

    11..20:
      StereoSliderGetBarColor := AColors.Medium;

    21..25:
      StereoSliderGetBarColor := AColors.High;

    26..30:
      StereoSliderGetBarColor := AColors.VeryHigh;

  end;
end;

procedure StereoSliderUpdate(const ASliderData: TStereoSliderData; const AChannel: TCodecSoundChannel);
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
    cSliderTip,
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

procedure StereoSliderDrawBar(const ASliderData: TStereoSliderData; const APosition, APositionY: Byte;
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
        StereoSliderGetBarColor(I, ASliderData.Colors),
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

procedure StereoSliderAct(const ASliderData: TStereoSliderData; var APosition: Byte;
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
          StereoSliderGetBarColor(LDeletePosition, ASliderData.Colors),
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

procedure ScreenStereoSliderDraw(const ASliderData: TStereoSliderData);
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
    sSliderGrid,
    ASliderData.Colors.Grid,
    ASliderData.Colors.Background
  );

  StereoSliderDrawBar(ASliderData, ASliderData.LeftPosition, kMixerSlidersLeftY, sMixerSliderLeft, cSliderLeftBar);
  StereoSliderDrawBar(ASliderData, ASliderData.RightPosition, kMixerSlidersRightY, sMixerSliderRight, cSliderRightBar);

  StereoSliderUpdate(ASliderData, scLeft);
  StereoSliderUpdate(ASliderData, scRight);
end;

procedure ScreenStereoSliderHighlight(const ASliderData: TStereoSliderData;
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

procedure ScreenStereoSliderMove(var ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const ADirection: TSliderDirection);
begin
  if ASliderData.Locked then
  begin
    StereoSliderAct(ASliderData, ASliderData.LeftPosition, ADirection, kMixerSlidersLeftY, cSliderLeftBar);
    StereoSliderUpdate(ASliderData, scLeft);

    StereoSliderAct(ASliderData, ASliderData.RightPosition, ADirection, kMixerSlidersRightY, cSliderRightBar);
    StereoSliderUpdate(ASliderData, scRight);
  end else
  begin
    case AChannel of
      scLeft:
        begin
          StereoSliderAct(ASliderData, ASliderData.LeftPosition, ADirection, kMixerSlidersLeftY, cSliderLeftBar);
        end;

      scRight:
        begin
          StereoSliderAct(ASliderData, ASliderData.RightPosition, ADirection, kMixerSlidersRightY, cSliderRightBar);
        end;

    end;

    StereoSliderUpdate(ASliderData, AChannel);
  end;
end;

procedure EditUpdate(const AEditData: TEditData);
begin
  VideoWriteRegion(
    AEditData.PositionX,
    AEditData.PositionY,
    AEditData.Width,
    1,
    cSpace,
    VideoAttribute(
      AEditData.Colors.Foreground,
      AEditData.Colors.Background
    )
  );

  VideoWriteStringAt(
    AEditData.PositionX,
    AEditData.PositionY,
    AEditData.Text,
    AEditData.Colors.Foreground,
    AEditData.Colors.Background
  );
end;

procedure EditNormal(const AEditData: TEditData);
begin
  VideoHighlightRegion(
    AEditData.PositionX,
    AEditData.PositionY,
    AEditData.Width,
    1,
    VideoAttribute(
      AEditData.Colors.Foreground,
      AEditData.Colors.Background
    )
  );
end;

procedure EditHighlight(const AEditData: TEditData);
begin
  VideoHighlightRegion(
    AEditData.PositionX,
    AEditData.PositionY,
    AEditData.Width,
    1,
    VideoAttribute(
      AEditData.Colors.HighForeground,
      AEditData.Colors.HighBackground
    )
  );
end;

procedure ScreenEditDraw(const AEditData: TEditData);
begin
  EditNormal(AEditData);
  EditUpdate(AEditData);
end;

procedure ScreenEditChange(var AEditData: TEditData);
var
  LKey: Char;
  LInput: String;
  LAttribute: Byte;

begin
  EditHighlight(AEditData);

  GotoXY(AEditData.PositionX + Length(AEditData.Text), AEditData.PositionY);
  VideoEnableCursor;

  LInput := AEditData.Text;
  LAttribute := VideoAttribute(
    AEditData.Colors.HighForeground,
    AEditData.Colors.HighBackground
  );

  while True do
  begin
    LKey := ReadKey;

    case LKey of
      kKeyBackspace:
        begin
          if LInput <> sEmpty then
          begin
            Delete(LInput, Length(LInput), 1);

            VideoWriteCharAttrAt(
              Pred(WhereX),
              AEditData.PositionY,
              cSpace,
              LAttribute
            );

            GotoXY(Pred(WhereX), WhereY);
          end;
        end;

      kKeyEnter:
        begin
          AEditData.Text := LInput;

          Break;
        end;

      kKeyEscape:
        Break;

      cFullStop, cSemicolon, cBackslash, '0'..'9', 'a'..'z', 'A'..'Z':
        begin
          if Length(LInput) < AEditData.Width then
          begin
            LInput := LInput + LKey;

            VideoWriteCharAttrAt(
              WhereX,
              AEditData.PositionY,
              LKey,
              LAttribute
            );

            GotoXY(Succ(WhereX), AEditData.PositionY);
          end;
        end;

    end;
  end;

  VideoDisableCursor;

  EditNormal(AEditData);
  EditUpdate(AEditData);
end;

procedure ScreenSingleFrameDraw(const AFrameData: TFrameData);
var
  I: Byte;
  LGeneralAttribute: Byte;

begin
  VideoWriteStringAt(
    AFrameData.PositionX,
    AFrameData.PositionY,
    AFrameData.Title,
    AFrameData.Colors.Title,
    AFrameData.Colors.Background
  );

  LGeneralAttribute := VideoAttribute(
    AFrameData.Colors.Foreground,
    AFrameData.Colors.Background
  );

  VideoWriteCharAttrAt(
    AFrameData.PositionX,
    AFrameData.PositionY + 1,
    cSingleFrameTopLeft,
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    AFrameData.PositionX,
    AFrameData.PositionY + AFrameData.Height,
    cSingleFrameBottomLeft,
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    Pred(AFrameData.PositionX + AFrameData.Width),
    AFrameData.PositionY + 1,
    cSingleFrameTopRight,
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    Pred(AFrameData.PositionX + AFrameData.Width),
    AFrameData.PositionY + AFrameData.Height,
    cSingleFrameBottomRight,
    LGeneralAttribute
  );

  VideoWriteRegion(
    Succ(AFrameData.PositionX),
    AFrameData.PositionY + 1,
    AFrameData.Width - 2,
    1,
    cSingleFrameTopBottom,
    LGeneralAttribute
  );

  VideoWriteRegion(
    Succ(AFrameData.PositionX),
    AFrameData.PositionY + AFrameData.Height,
    AFrameData.Width - 2,
    1,
    cSingleFrameTopBottom,
    LGeneralAttribute
  );

  for I := 2 to Pred(AFrameData.Height) do
  begin
    VideoWriteCharAttrAt(
      AFrameData.PositionX,
      AFrameData.PositionY + I,
      cSingleFrameLeft,
      LGeneralAttribute
    );

    VideoWriteCharAttrAt(
      Pred(AFrameData.PositionX + AFrameData.Width),
      AFrameData.PositionY + I,
      cSingleFrameRight,
      LGeneralAttribute
    );
  end;
end;

procedure ScreenProgressBarDraw(const AProgressBarData: TProgressBarData);
var
  LFrameData: TFrameData;

begin
  LFrameData.PositionX := AProgressBarData.PositionX;
  LFrameData.PositionY := AProgressBarData.PositionY;
  LFrameData.Width := AProgressBarData.Width;
  LFrameData.Height := kProgressBarHeight;
  LFrameData.Colors.Foreground := AProgressBarData.Colors.Foreground;
  LFrameData.Colors.Background := AProgressBarData.Colors.Background;
  LFrameData.Colors.Title := AProgressBarData.Colors.Title;
  LFrameData.Title := AProgressBarData.Title;

  ScreenSingleFrameDraw(LFrameData);

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

  ScreenProgressBarUpdate(AProgressBarData);
end;

procedure ScreenProgressBarUpdate(const AProgressBarData: TProgressBarData);
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

procedure ScreenProgressBarReset(const AProgressBarData: TProgressBarData);
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

  ScreenProgressBarUpdate(AProgressBarData);
end;

end.
