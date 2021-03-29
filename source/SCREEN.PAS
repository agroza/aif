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
  TStereoSliderData = record
    PositionX: Byte;
    PositionY: Byte;
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

procedure ScreenWriteActionIf(const AMessage: String; const AAction, ACondition: Boolean);

procedure ScreenDrawTitleBar(const AForeColor, ABackColor, ATextColor: Byte; const ACaption: String);

procedure ScreenDrawStereoSlider(const ASliderData: TStereoSliderData);
procedure ScreenHighlightStereoSlider(const ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const AValue: Boolean);
procedure ScreenMoveStereoSlider(var ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const ADirection: TSliderDirection);

implementation

uses
  Consts,
  Crt,
  Routines,
  Video;

{ public declarations }

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
end;

procedure ScreenDrawTitleBar(const AForeColor, ABackColor, ATextColor: Byte; const ACaption: String);
begin
  VideoWriteRegion(k80x25Left, k80x25Top, k80x25Width, 1, cSpace, VideoAttribute(AForeColor, ABackColor));
  VideoWriteStringAt((k80x25Width div 2) - (Length(ACaption) div 2), k80x25Top, ACaption, ATextColor, ABackColor);
end;

function ScreenGetSliderBarColor(const APosition: Byte): Byte;
begin
  case APosition of
    0..10:
      ScreenGetSliderBarColor := clMixerSliderLow;

    11..20:
      ScreenGetSliderBarColor := clMixerSliderMedium;

    21..25:
      ScreenGetSliderBarColor := clMixerSliderHigh;

    26..30:
      ScreenGetSliderBarColor := clMixerSliderVeryHigh;

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
        LPositionY := 1;
      end;

    scRight:
      begin
        LPosition := ASliderData.RightPosition;
        LPositionY := 3;
      end;

  end;

  VideoWriteCharAttrAt(ASliderData.PositionX + LPosition + 7, ASliderData.PositionY + LPositionY,
    cMixerSliderTip, VideoAttribute(clMixerSliderTip, clMixerBack));
  VideoWriteStringAt(ASliderData.PositionX + 40, ASliderData.PositionY + LPositionY,
    PadPercent(Round((LPosition / ASliderData.Max) * 100)), clMixerSliderText, clMixerBack);
end;

procedure ScreenDrawSliderBar(const ASliderData: TStereoSliderData; const APosition, APositionY: Byte;
  const AChannelText: String; const AChar: Char);
var
  I: Byte;

begin
  VideoWriteStringAt(ASliderData.PositionX, ASliderData.PositionY + APositionY, AChannelText, clMixerSliderText, clMixerBack);

  for I := 0 to APosition do
  begin
    VideoWriteCharAttrAt(ASliderData.PositionX + I + 7, ASliderData.PositionY + APositionY,
      AChar, VideoAttribute(ScreenGetSliderBarColor(I), clMixerBack));
  end;

  if APosition < ASliderData.Max then
  begin
    for I := Succ(APosition) to ASliderData.Max do
    begin
      VideoWriteCharAttrAt(ASliderData.PositionX + I + 7, ASliderData.PositionY + APositionY,
        AChar, VideoAttribute(clMixerSliderNormal, clMixerBack));
    end;
  end;
end;

procedure ScreenDrawStereoSlider(const ASliderData: TStereoSliderData);
begin
  VideoWriteStringAt(ASliderData.PositionX + 7, ASliderData.PositionY, ASliderData.Title, clMixerSliderTitle, clMixerBack);
  VideoWriteStringAt(ASliderData.PositionX + 7, ASliderData.PositionY + 2, sMixerSliderGrid, clMixerSliderGrid, clMixerBack);

  ScreenDrawSliderBar(ASliderData, ASliderData.LeftPosition, 1, sMixerSliderLeft, 'ß');
  ScreenDrawSliderBar(ASliderData, ASliderData.RightPosition, 3, sMixerSliderRight, 'Ü');

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
          LLeftAttribute := VideoAttribute(clMixerSliderHighFore, clMixerSliderHighBack);
          LRightAttribute := VideoAttribute(clMixerSliderText, clMixerBack);
        end;

      scRight:
        begin
          LLeftAttribute := VideoAttribute(clMixerSliderText, clMixerBack);
          LRightAttribute := VideoAttribute(clMixerSliderHighFore, clMixerSliderHighBack);
        end;

    end;
  end else
  begin
    LLeftAttribute := VideoAttribute(clMixerSliderText, clMixerBack);
    LRightAttribute := VideoAttribute(clMixerSliderText, clMixerBack);
  end;

  VideoHighlightRegion(ASliderData.PositionX, ASliderData.PositionY + 1, 4, 1, LLeftAttribute);
  VideoHighlightRegion(ASliderData.PositionX, ASliderData.PositionY + 3, 5, 1, LRightAttribute);
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

        LAttribute := VideoAttribute(ScreenGetSliderBarColor(LDeletePosition), clMixerBack);
      end;

    sdDown:
      begin
        if APosition > ASliderData.Min then
        begin
          Dec(APosition);
        end;

        LAttribute := VideoAttribute(clMixerSliderNormal, clMixerBack);
      end;

  end;

  VideoWriteCharAttrAt(ASliderData.PositionX + LDeletePosition + 7, ASliderData.PositionY + APositionY, AChar, LAttribute);
end;

procedure ScreenMoveStereoSlider(var ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const ADirection: TSliderDirection);
begin
  if ASliderData.Locked then
  begin
    ScreenActStereoSlider(ASliderData, ASliderData.LeftPosition, ADirection, 1, 'ß');
    ScreenUpdateStereoSlider(ASliderData, scLeft);

    ScreenActStereoSlider(ASliderData, ASliderData.RightPosition, ADirection, 3, 'Ü');
    ScreenUpdateStereoSlider(ASliderData, scRight);
  end else
  begin
    case AChannel of
      scLeft:
        ScreenActStereoSlider(ASliderData, ASliderData.LeftPosition, ADirection, 1, 'ß');

      scRight:
        ScreenActStereoSlider(ASliderData, ASliderData.RightPosition, ADirection, 3, 'Ü');

    end;

    ScreenUpdateStereoSlider(ASliderData, AChannel);
  end;
end;

end.
