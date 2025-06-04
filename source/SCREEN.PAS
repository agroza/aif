{ --------------------------------------------------------------------------- }
{ - VersaVision Screen Routines (screen.pas)                                - }
{ - Integrant part of VersaVision Framework                                 - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$I cdefines.inc}

{$IFDEF CPU16BIT}
  {$G+}
{$ENDIF}

unit Screen;

interface

uses
  Types;

type
  TCharacterCase = (
    ccNormal,
    ccLowerCase,
    ccUpperCase
  );

  TKeyValueColors = packed record
    Foreground: Byte;
    Background: Byte;
  end;

  TKeyValueData = packed record
    KeyX: Byte;
    ValueX: Byte;
    PositionY: Byte;
    Width: Byte;
    Colors: TKeyValueColors;
    Key: String;
    Value: String;
  end;

  TEditColors = packed record
    Foreground: Byte;
    Background: Byte;
    HighForeground: Byte;
    HighBackground: Byte;
  end;

  TEditData = packed record
    PositionX: Byte;
    PositionY: Byte;
    Width: Byte;
    MaxLength: Byte;
    CharacterCase: TCharacterCase;
    Colors: TEditColors;
    Text: String;
  end;

  TFrameType = (
    ftSingle,
    ftWindow
  );

  TFrameColors = packed record
    Foreground: Byte;
    Background: Byte;
  end;

  TFrameData = packed record
    PositionX: Byte;
    PositionY: Byte;
    Width: Byte;
    Height: Byte;
    Colors: TFrameColors;
    FrameType: TFrameType;
  end;

  TFramedAreaColors = packed record
    Foreground: Byte;
    Background: Byte;
    Title: Byte;
  end;

  TFramedAreaData = packed record
    PositionX: Byte;
    PositionY: Byte;
    Width: Byte;
    Height: Byte;
    Colors: TFramedAreaColors;
    Title: String;
  end;

  TProgressBarColors = packed record
    Foreground: Byte;
    Background: Byte;
    Title: Byte;
    Progress: Byte;
  end;

  TProgressBarDrawMode = (
    dmUpdate,
    dmRepaint
  );

  TProgressBarDirection = (
    dirAscending,
    dirDescending
  );

  TProgressBarData = packed record
    PositionX: Byte;
    PositionY: Byte;
    Width: Byte;
    Colors: TProgressBarColors;
    DrawMode: TProgressBarDrawMode;
    Min: Word;
    Max: Word;
    Progress: Word;
    Title: String;
  end;

  TButtonColors = packed record
    Foreground: Byte;
    Background: Byte;
    Accelerator: Byte;
    HighForeground: Byte;
    HighBackground: Byte;
    HighAccelerator: Byte;
  end;

  TButtonData = packed record
    PositionX: Byte;
    PositionY: Byte;
    Width: Byte;
    Colors: TButtonColors;
    Text: String;
    Tag: Byte;
  end;

  TMessageBoxResult = (
    mrUndefined,
    mrCancel,
    mrClose,
    mrYes,
    mrNo
  );

  TMessageBoxColors = packed record
    Foreground: Byte;
    Background: Byte;
    BtnForeground: Byte;
    BtnBackground: Byte;
    BtnAccelerator: Byte;
    BtnHighForeground: Byte;
    BtnHighBackground: Byte;
    BtnHighAccelerator: Byte;
  end;

  TMessageBoxButton = (
    mbCancel,
    mbClose,
    mbYes,
    mbNo
  );

  TMessageBoxButtons = set of TMessageBoxButton;

  PMessageBoxButtonsData = ^TMessageBoxButtonsData;
  TMessageBoxButtonsData = packed array[0..0] of TButtonData;

  TMessageBoxData = packed record
    Colors: TMessageBoxColors;
    Title: String;
    Text: String;
    Buttons: TMessageBoxButtons;
    DefaultButton: TMessageBoxButton;
  end;

  TStereoSliderColors = packed record
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

  TStereoSliderData = packed record
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

procedure ScreenInitialize;
procedure ScreenFinalize;

procedure ScreenStoreFrameGlyphs;
procedure ScreenRestoreFrameGlyphs;
procedure ScreenSetVVFrameGlyphs;

procedure ScreenStoreColors;
procedure ScreenRestoreColors;
procedure ScreenSetVVColors;

procedure ScreenWriteStatus(const AMessage, AStatus: String; AColor: Byte);

procedure ScreenTitleBarDraw(const AForeground, ABackground, ATextColor: Byte; const ACaption: String);

procedure ScreenCommandDraw(const ALeft, ATop, AHighlight, AColor, ABackground: Byte; const AShortcut, ADescription: String);

procedure ScreenKeyValueDraw(const AKeyValueData: TKeyValueData);
procedure ScreenKeyValueSetValue(var AKeyValueData: TKeyValueData; const AValue: String);

procedure ScreenEditDraw(const AEditData: TEditData);
procedure ScreenEditChange(var AEditData: TEditData);

procedure ScreenFrameDraw(const AFrameData: TFrameData);

procedure ScreenFramedAreaDraw(const AFramedAreaData: TFramedAreaData);

procedure ScreenProgressBarDraw(const AProgressBarData: TProgressBarData);
procedure ScreenProgressBarUpdate(const AProgressBarData: TProgressBarData;
  const AProgressBarDirection: TProgressBarDirection);
procedure ScreenProgressBarReset(var AProgressBarData: TProgressBarData; const AValue: Word);
procedure ScreenProgressBarSetProgress(var AProgressBarData: TProgressBarData; const AValue: Word);

procedure ScreenMessageBoxPrepare(var AMessageBoxData: TMessageBoxData; const ATitle, AText: String;
  const AButtons: TMessageBoxButtons; const ADefaultButton: TMessageBoxButton);
function ScreenMessageBoxDraw(const AMessageBoxData: TMessageBoxData): TMessageBoxResult;

procedure ScreenStereoSliderDraw(const ASliderData: TStereoSliderData);
procedure ScreenStereoSliderHighlight(const ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const AValue: Boolean);
procedure ScreenStereoSliderMove(var ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const ADirection: TSliderDirection);

implementation

uses
  Consts,
  Routines,
  Video;

type
  TWindowFrameBorder = (
    wfbBottomLeft,
    wfbBottom,
    wfbBottomRight
  );

  TWindowFrameBorderGlyph = packed record
    Ordinal: Byte;
    Data: TGlyphData;
  end;

  TFrameGlyphs = (
    fgTopLeft,
    fgLeft,
    fgBottomLeft,
    fgTop,
    fgTopRight,
    fgRight,
    fgBottomRight,
    fgBottom
  );

const
  { VersaVision frame border glyph data }
  kVVWindowFrameBorders: packed array[TWindowFrameBorder] of TWindowFrameBorderGlyph = (
    ( Ordinal: 200; Data: ( $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $FF, $FF, $FF, $FF ) ),
    ( Ordinal: 205; Data: ( $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF ) ),
    ( Ordinal: 201; Data: ( $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $FF, $FF, $FF, $FF ) )
  );

  { VersaVision color scheme data }
  kVVBlue: TPaletteColor = ( RIntensity: 0; GIntensity: 0; BIntensity: 16 );
  kVVRed: TPaletteColor = ( RIntensity: 32; GIntensity: 0; BIntensity: 0 );
  kVVBrown: TPaletteColor = ( RIntensity: 26; GIntensity: 26; BIntensity: 26 );
  kVVDarkGray: TPaletteColor = ( RIntensity: 10; GIntensity: 10; BIntensity: 10 );
  kVVLightGreen: TPaletteColor = ( RIntensity: 0; GIntensity: 48; BIntensity: 0 );
  kVVLightRed: TPaletteColor = ( RIntensity: 50; GIntensity: 28; BIntensity: 0 );
  kVVYellow: TPaletteColor = ( RIntensity: 50; GIntensity: 50; BIntensity: 0 );

  { UI objects constants }
  kTitleBarHeight              = 1;
  kKeyValueItemHeight          = 1;
  kEditHeight                  = 1;
  kFrameHeight                 = 1;

  kFrameGlyphs: packed array[TFrameType] of array[TFrameGlyphs] of Char = (
    ( 'з', 'Ё', 'ю', 'д', '©', 'Ё', 'ы', 'д' ),
    ( 'ш', 'щ', 'х', 'ш', 'ш', 'ч', 'и', 'м' )
  );

  cProgressBarEmpty            = '╟';
  cProgressBarFill             = 'ш';

  cProgressBarGlyph: packed array[TProgressBarDirection] of Char = (
    cProgressBarFill,
    cProgressBarEmpty
  );

  kProgressBarHeight           = 3;
  kProgressBarInternHeight     = 1;
  kButtonHeight                = 1;

  cButtonLeftDemarcation       = '';
  cButtonRightDemarcation      = '';

  kMessageBoxTitlePadding      = 1;
  kMessageBoxButtonPadding     = 2;

  sMessageBoxButtons: packed array[TMessageBoxButton] of PChar = (
    sMessageBoxCancel,
    sMessageBoxClose,
    sMessageBoxYes,
    sMessageBoxNo
  );

  kMessageBoxResults: packed array[TMessageBoxButton] of TMessageBoxResult = (
    mrCancel,
    mrClose,
    mrYes,
    mrNo
  );

  kSliderChannelHeight      = 1;

  sSliderGrid               = 'цдедедедедедедедедедедедедедед╢';
  cSliderTip                = 'ш';
  cSliderLeftBar            = 'ъ';
  cSliderRightBar           = 'э';

var
  IGWindowFrameBorders: packed array[TWindowFrameBorder] of TWindowFrameBorderGlyph;
  IGVGAPalette: packed array[kVGAPaletteStart..kVGAPaletteEnd] of TPaletteColor;

{ private and public declarations }

procedure ScreenInitialize;
begin
  ScreenSetVVFrameGlyphs;
  ScreenSetVVColors;
end;

procedure ScreenFinalize;
begin
  ScreenRestoreColors;
  ScreenRestoreFrameGlyphs;
end;

procedure ScreenStoreFrameGlyphs;
var
  LWindowFrameBorder: TWindowFrameBorder;

begin
  for LWindowFrameBorder := Low(kVVWindowFrameBorders) to High(kVVWindowFrameBorders) do
  begin
    IGWindowFrameBorders[LWindowFrameBorder].Ordinal := kVVWindowFrameBorders[LWindowFrameBorder].Ordinal;

    VideoGetGlyphData(
      IGWindowFrameBorders[LWindowFrameBorder].Ordinal,
      IGWindowFrameBorders[LWindowFrameBorder].Data
    );
  end;
end;

procedure ScreenRestoreFrameGlyphs;
var
  LWindowFrameBorder: TWindowFrameBorder;

begin
  for LWindowFrameBorder := Low(IGWindowFrameBorders) to High(IGWindowFrameBorders) do
  begin
    VideoSetGlyphData(
      IGWindowFrameBorders[LWindowFrameBorder].Ordinal,
      IGWindowFrameBorders[LWindowFrameBorder].Data
    );
  end;
end;

procedure ScreenSetVVFrameGlyphs;
var
  LWindowFrameBorder: TWindowFrameBorder;

begin
  ScreenStoreFrameGlyphs;

  for LWindowFrameBorder := Low(kVVWindowFrameBorders) to High(kVVWindowFrameBorders) do
  begin
    VideoSetGlyphData(
      kVVWindowFrameBorders[LWindowFrameBorder].Ordinal,
      kVVWindowFrameBorders[LWindowFrameBorder].Data
    );
  end;
end;

procedure ScreenStoreColors;
var
  LVGAColor: Byte;

begin
  for LVGAColor := kVGAPaletteStart to kVGAPaletteEnd do
  begin
    VideoGetPaletteColor(kVGAPaletteIndex[LVGAColor], IGVGAPalette[LVGAColor]);
  end;
end;

procedure ScreenRestoreColors;
var
  LVGAColor: Byte;

begin
  for LVGAColor := kVGAPaletteStart to kVGAPaletteEnd do
  begin
    VideoSetPaletteColor(kVGAPaletteIndex[LVGAColor], IGVGAPalette[LVGAColor]);
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

procedure ScreenWriteStatus(const AMessage, AStatus: String; AColor: Byte);
var
  LPositionX: Byte;
  LPositionY: Byte;

begin
  LPositionX := VideoWhereX;
  LPositionY := VideoWhereY;

  VideoWriteStringAt(
    LPositionX,
    LPositionY,
    AMessage,
    clNormal,
    clBlack
  );

  LPositionX := kOKFailedXPosition;

  VideoWriteCharAt(
    LPositionX,
    LPositionY,
    cOpenSquareBracket
  );

  Inc(LPositionX, 2);

  VideoWriteStringAt(
    LPositionX,
    LPositionY,
    AStatus,
    AColor,
    clBlack
  );

  Inc(LPositionX, Succ(Length(AStatus)));

  VideoWriteCharAt(
    LPositionX,
    LPositionY,
    cClosedSquareBracket
  );

  VideoWriteNewln;
end;

procedure ScreenTitleBarDraw(const AForeground, ABackground, ATextColor: Byte; const ACaption: String);
begin
  VideoWriteRegion(
    k80x25Left,
    k80x25Top,
    k80x25Width,
    kTitleBarHeight,
    cSpace,
    VideoAttribute(
      AForeground,
      ABackground
    )
  );

  VideoWriteStringAt(
    (k80x25Width div 2) - (Length(ACaption) div 2),
    k80x25Top,
    ACaption,
    ATextColor,
    ABackground
  );
end;

procedure ScreenCommandDraw(const ALeft, ATop, AHighlight, AColor, ABackground: Byte; const AShortcut, ADescription: String);
begin
  VideoWriteStringAt(
    ALeft,
    ATop,
    AShortcut,
    AHighlight,
    ABackground
  );

  VideoWriteStringAt(
    ALeft + 5,
    ATop,
    ADescription,
    AColor,
    ABackground
  );
end;

procedure ScreenKeyValueClearValue(const AKeyValueData: TKeyValueData);
begin
  VideoWriteRegion(
    AKeyValueData.ValueX,
    AKeyValueData.PositionY,
    AKeyValueData.Width,
    kKeyValueItemHeight,
    cSpace,
    VideoAttribute(
      AKeyValueData.Colors.Foreground,
      AKeyValueData.Colors.Background
    )
  );
end;

procedure ScreenKeyValueDrawValue(const AKeyValueData: TKeyValueData);
begin
  VideoWriteStringAt(
    AKeyValueData.ValueX,
    AKeyValueData.PositionY,
    AKeyValueData.Value,
    AKeyValueData.Colors.Foreground,
    AKeyValueData.Colors.Background
  );
end;

procedure ScreenKeyValueDraw(const AKeyValueData: TKeyValueData);
begin
  VideoWriteStringAt(
    AKeyValueData.KeyX,
    AKeyValueData.PositionY,
    AKeyValueData.Key,
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

  ScreenKeyValueDrawValue(AKeyValueData);
end;

procedure ScreenKeyValueSetValue(var AKeyValueData: TKeyValueData; const AValue: String);
begin
  if AKeyValueData.Value <> AValue then
  begin
    AKeyValueData.Value := AValue;
    ScreenKeyValueClearValue(AKeyValueData);
    ScreenKeyValueDrawValue(AKeyValueData);
  end;
end;

procedure EditUpdate(const AEditData: TEditData);
begin
  VideoWriteRegion(
    AEditData.PositionX,
    AEditData.PositionY,
    AEditData.Width,
    kEditHeight,
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
    kEditHeight,
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
    kEditHeight,
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

  VideoGotoXY(AEditData.PositionX + Length(AEditData.Text), AEditData.PositionY);
  VideoEnableCursor;

  LInput := AEditData.Text;
  LAttribute := VideoAttribute(
    AEditData.Colors.HighForeground,
    AEditData.Colors.HighBackground
  );

  while True do
  begin
    LKey := GetStandardKey(GetScanCode);

    case LKey of
      kKeyBackspace:
        begin
          if Length(LInput) > 0 then
          begin
            Delete(LInput, Length(LInput), 1);

            VideoWriteCharAttrAt(
              Pred(VideoWhereX),
              AEditData.PositionY,
              cSpace,
              LAttribute
            );

            VideoGotoXY(Pred(VideoWhereX), VideoWhereY);
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
          if Length(LInput) < MinByte(AEditData.MaxLength, AEditData.Width) then
          begin
            case AEditData.CharacterCase of
              ccNormal:
                ;

              ccLowerCase:
                LKey := LoCase(LKey);

              ccUpperCase:
                LKey := UpCase(LKey);

            end;

            LInput := LInput + LKey;

            VideoWriteCharAttrAt(
              VideoWhereX,
              AEditData.PositionY,
              LKey,
              LAttribute
            );

            VideoGotoXY(Succ(VideoWhereX), AEditData.PositionY);
          end;
        end;

    end;
  end;

  VideoDisableCursor;

  EditNormal(AEditData);
  EditUpdate(AEditData);
end;

procedure ScreenFrameDraw(const AFrameData: TFrameData);
var
  LHeight: Byte;
  LGeneralAttribute: Byte;

begin
  LGeneralAttribute := VideoAttribute(
    AFrameData.Colors.Foreground,
    AFrameData.Colors.Background
  );

  VideoWriteCharAttrAt(
    AFrameData.PositionX,
    Succ(AFrameData.PositionY),
    kFrameGlyphs[AFrameData.FrameType][fgTopLeft],
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    AFrameData.PositionX,
    AFrameData.PositionY + AFrameData.Height,
    kFrameGlyphs[AFrameData.FrameType][fgBottomLeft],
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    Pred(AFrameData.PositionX + AFrameData.Width),
    Succ(AFrameData.PositionY),
    kFrameGlyphs[AFrameData.FrameType][fgTopRight],
    LGeneralAttribute
  );

  VideoWriteCharAttrAt(
    Pred(AFrameData.PositionX + AFrameData.Width),
    AFrameData.PositionY + AFrameData.Height,
    kFrameGlyphs[AFrameData.FrameType][fgBottomRight],
    LGeneralAttribute
  );

  VideoWriteRegion(
    Succ(AFrameData.PositionX),
    Succ(AFrameData.PositionY),
    AFrameData.Width - 2,
    kFrameHeight,
    kFrameGlyphs[AFrameData.FrameType][fgTop],
    LGeneralAttribute
  );

  VideoWriteRegion(
    Succ(AFrameData.PositionX),
    AFrameData.PositionY + AFrameData.Height,
    AFrameData.Width - 2,
    kFrameHeight,
    kFrameGlyphs[AFrameData.FrameType][fgBottom],
    LGeneralAttribute
  );

  for LHeight := 2 to Pred(AFrameData.Height) do
  begin
    VideoWriteCharAttrAt(
      AFrameData.PositionX,
      AFrameData.PositionY + LHeight,
      kFrameGlyphs[AFrameData.FrameType][fgLeft],
      LGeneralAttribute
    );

    VideoWriteCharAttrAt(
      Pred(AFrameData.PositionX + AFrameData.Width),
      AFrameData.PositionY + LHeight,
      kFrameGlyphs[AFrameData.FrameType][fgRight],
      LGeneralAttribute
    );
  end;
end;

procedure ScreenFramedAreaDraw(const AFramedAreaData: TFramedAreaData);
var
  LFrameData: TFrameData;

begin
  VideoWriteStringAt(
    AFramedAreaData.PositionX,
    AFramedAreaData.PositionY,
    AFramedAreaData.Title,
    AFramedAreaData.Colors.Title,
    AFramedAreaData.Colors.Background
  );

  LFrameData.PositionX := AFramedAreaData.PositionX;
  LFrameData.PositionY := AFramedAreaData.PositionY;
  LFrameData.Width := AFramedAreaData.Width;
  LFrameData.Height := AFramedAreaData.Height;
  LFrameData.Colors.Foreground := AFramedAreaData.Colors.Foreground;
  LFrameData.Colors.Background := AFramedAreaData.Colors.Background;
  LFrameData.FrameType := ftSingle;

  ScreenFrameDraw(LFrameData);
end;

procedure ScreenProgressBarDraw(const AProgressBarData: TProgressBarData);
var
  LFramedAreaData: TFramedAreaData;

begin
  LFramedAreaData.PositionX := AProgressBarData.PositionX;
  LFramedAreaData.PositionY := AProgressBarData.PositionY;
  LFramedAreaData.Width := AProgressBarData.Width;
  LFramedAreaData.Height := kProgressBarHeight;
  LFramedAreaData.Colors.Foreground := AProgressBarData.Colors.Foreground;
  LFramedAreaData.Colors.Background := AProgressBarData.Colors.Background;
  LFramedAreaData.Colors.Title := AProgressBarData.Colors.Title;
  LFramedAreaData.Title := AProgressBarData.Title;

  ScreenFramedAreaDraw(LFramedAreaData);

  VideoWriteRegion(
    Succ(AProgressBarData.PositionX),
    AProgressBarData.PositionY + 2,
    AProgressBarData.Width - 2,
    kProgressBarInternHeight,
    cProgressBarEmpty,
    VideoAttribute(
      AProgressBarData.Colors.Progress,
      AProgressBarData.Colors.Background
    )
  );

  ScreenProgressBarUpdate(AProgressBarData, dirAscending);
end;

procedure ScreenProgressBarUpdate(const AProgressBarData: TProgressBarData;
  const AProgressBarDirection: TProgressBarDirection);
var
  LProgress: Real;
  LProgressWidth: Word;
  LVideoAttribute: Byte;

  procedure InternalUpdate;
  var
    LProgressBarGlyph: Char;

    procedure FillUnit(const AOffset: Byte);
    begin
      VideoWriteCharAttrAt(
        Succ(AProgressBarData.PositionX) + AOffset,
        AProgressBarData.PositionY + 2,
        LProgressBarGlyph,
        LVideoAttribute
      );
    end;

  begin
    if LProgressWidth >= AProgressBarData.Width - 2 then
    begin
      Dec(LProgressWidth);
    end;

    if AProgressBarData.Progress = AProgressBarData.Min then
    begin
      LProgressBarGlyph := cProgressBarEmpty;
    end else
    begin
      LProgressBarGlyph := cProgressBarGlyph[AProgressBarDirection];

      if (LProgressWidth = Succ(AProgressBarData.Min)) and
        (AProgressBarDirection = dirAscending) then
      begin
        FillUnit(Pred(LProgressWidth));
      end;
    end;

    FillUnit(LProgressWidth);
  end;

  procedure InternalRepaint;
  var
    LPositionX: Byte;

  begin
    LPositionX := Succ(AProgressBarData.PositionX);

    if AProgressBarDirection = dirDescending then
    begin
      Inc(LPositionX, LProgressWidth);
      LProgressWidth := AProgressBarData.Width - 2 - LProgressWidth;
    end;

    VideoWriteRegion(
      LPositionX,
      AProgressBarData.PositionY + 2,
      LProgressWidth,
      kProgressBarInternHeight,
      cProgressBarGlyph[AProgressBarDirection],
      LVideoAttribute
    );
  end;

begin
  if AProgressBarData.Max > 0 then
  begin
    LProgress := AProgressBarData.Progress / AProgressBarData.Max;
    LProgressWidth := Round(LProgress * (AProgressBarData.Width - 2));

    LVideoAttribute := VideoAttribute(
      AProgressBarData.Colors.Progress,
      AProgressBarData.Colors.Background
    );

    case AProgressBarData.DrawMode of
      dmUpdate:
        InternalUpdate;

      dmRepaint:
        InternalRepaint;

    end;

    VideoWriteStringAt(
      AProgressBarData.PositionX + AProgressBarData.Width - 5,
      AProgressBarData.PositionY,
      PadPercent(Round(LProgress * 100)),
      AProgressBarData.Colors.Foreground,
      AProgressBarData.Colors.Background
    );
  end;
end;

procedure ScreenProgressBarReset(var AProgressBarData: TProgressBarData; const AValue: Word);
begin
  VideoWriteRegion(
    Succ(AProgressBarData.PositionX),
    AProgressBarData.PositionY + 2,
    AProgressBarData.Width - 2,
    kProgressBarInternHeight,
    cProgressBarEmpty,
    VideoAttribute(
      AProgressBarData.Colors.Progress,
      AProgressBarData.Colors.Background
    )
  );

  ScreenProgressBarSetProgress(AProgressBarData, AValue);
end;

procedure ScreenProgressBarSetProgress(var AProgressBarData: TProgressBarData; const AValue: Word);
var
  LDirection: TProgressBarDirection;

begin
  if AValue < AProgressBarData.Min then
  begin
    LDirection := dirDescending;
    AProgressBarData.Progress := AProgressBarData.Min;
  end else
  if AValue > AProgressBarData.Max then
  begin
    LDirection := dirAscending;
    AProgressBarData.Progress := AProgressBarData.Max;
  end else
  begin
    LDirection := TProgressBarDirection(AProgressBarData.Progress >= AValue);
    AProgressBarData.Progress := AValue;
  end;

  ScreenProgressBarUpdate(AProgressBarData, LDirection);
end;

procedure ScreenButtonDraw(const AButtonData: TButtonData);
begin
  VideoWriteStringAt(
    AButtonData.PositionX,
    AButtonData.PositionY,
    AButtonData.Text,
    AButtonData.Colors.Foreground,
    AButtonData.Colors.Background
  );

  VideoWriteAttrAt(
    AButtonData.PositionX + kMessageBoxButtonPadding,
    AButtonData.PositionY,
    VideoAttribute(
      AButtonData.Colors.Accelerator,
      AButtonData.Colors.Background
    )
  );
end;

procedure ScreenButtonNormal(const AButtonData: TButtonData);
begin
  VideoHighlightRegion(
    AButtonData.PositionX,
    AButtonData.PositionY,
    Length(AButtonData.Text),
    kButtonHeight,
    VideoAttribute(
      AButtonData.Colors.Foreground,
      AButtonData.Colors.Background
    )
  );

  VideoWriteAttrAt(
    AButtonData.PositionX + kMessageBoxButtonPadding,
    AButtonData.PositionY,
    VideoAttribute(
      AButtonData.Colors.Accelerator,
      AButtonData.Colors.Background
    )
  );

  VideoWriteCharAt(
    AButtonData.PositionX,
    AButtonData.PositionY,
    cSpace
  );

  VideoWriteCharAt(
    Pred(AButtonData.PositionX + AButtonData.Width),
    AButtonData.PositionY,
    cSpace
  );
end;

procedure ScreenButtonHighlight(const AButtonData: TButtonData);
var
  LHighAttribute: Byte;

begin
  VideoHighlightRegion(
    AButtonData.PositionX,
    AButtonData.PositionY,
    Length(AButtonData.Text),
    kButtonHeight,
    VideoAttribute(
      AButtonData.Colors.HighBackground,
      AButtonData.Colors.HighForeground
    )
  );

  LHighAttribute := VideoAttribute(
    AButtonData.Colors.HighAccelerator,
    AButtonData.Colors.HighForeground
  );

  VideoWriteAttrAt(
    AButtonData.PositionX + kMessageBoxButtonPadding,
    AButtonData.PositionY,
    LHighAttribute
  );

  VideoWriteCharAttrAt(
    AButtonData.PositionX,
    AButtonData.PositionY,
    cButtonLeftDemarcation,
    LHighAttribute
  );

  VideoWriteCharAttrAt(
    Pred(AButtonData.PositionX + AButtonData.Width),
    AButtonData.PositionY,
    cButtonRightDemarcation,
    LHighAttribute
  );
end;

function MessageBoxButtonCount(const AButtons: TMessageBoxButtons): Byte;
var
  LButton: TMessageBoxButton;
  LButtonCount: Byte;

begin
  LButtonCount := 0;

  for LButton := Low(TMessageBoxButton) to High(TMessageBoxButton) do
  begin
    if LButton in AButtons then
    begin
      Inc(LButtonCount);
    end;
  end;

  MessageBoxButtonCount := Pred(LButtonCount);
end;

procedure MessageBoxCreateButton(var AButtonsData: PMessageBoxButtonsData;
  const AButtonIndex, ALeft, ATop: Byte; var ALeftOffset: Byte;
  const AButton: TMessageBoxButton; const AMessageBoxColors: TMessageBoxColors);
var
  LButtonText: String;
  LPaddedText: String;
  LPaddedTextLength: Byte;
  LLeft: Byte;

begin
  LButtonText := StrPas(sMessageBoxButtons[AButton]);
  LPaddedText := PadCenter(LButtonText, kMessageBoxButtonPadding);
  LPaddedTextLength := Length(LPaddedText);

  LLeft := ALeft - LPaddedTextLength - ALeftOffset;
  Inc(ALeftOffset, Succ(LPaddedTextLength));

  AButtonsData^[AButtonIndex].PositionX := LLeft;
  AButtonsData^[AButtonIndex].PositionY := ATop;
  AButtonsData^[AButtonIndex].Width := LPaddedTextLength;
  AButtonsData^[AButtonIndex].Colors.Foreground := AMessageBoxColors.BtnForeground;
  AButtonsData^[AButtonIndex].Colors.Background := AMessageBoxColors.BtnBackground;
  AButtonsData^[AButtonIndex].Colors.Accelerator := AMessageBoxColors.BtnAccelerator;
  AButtonsData^[AButtonIndex].Colors.HighForeground := AMessageBoxColors.BtnHighForeground;
  AButtonsData^[AButtonIndex].Colors.HighBackground := AMessageBoxColors.BtnHighBackground;
  AButtonsData^[AButtonIndex].Colors.HighAccelerator := AMessageBoxColors.BtnHighAccelerator;
  AButtonsData^[AButtonIndex].Text := LPaddedText;
  AButtonsData^[AButtonIndex].Tag := Byte(AButton);
end;

procedure MessageBoxCreateButtons(const AButtonsX, AButtonsY: Byte;
  const AMessageBoxData: TMessageBoxData; var AButtonsData: PMessageBoxButtonsData);
var
  LButton: TMessageBoxButton;
  LLeftOffset: Byte;
  LButtonIndex: Byte;

begin
  LLeftOffset := 0;
  LButtonIndex := 0;

  for LButton := Low(TMessageBoxButton) to High(TMessageBoxButton) do
  begin
    if LButton in AMessageBoxData.Buttons then
    begin
      MessageBoxCreateButton(
        AButtonsData,
        LButtonIndex,
        AButtonsX,
        AButtonsY,
        LLeftOffset,
        LButton,
        AMessageBoxData.Colors
      );

      Inc(LButtonIndex);
    end;
  end;
end;

procedure MessageBoxDrawButtons(var AButtonsData: PMessageBoxButtonsData;
  const AButtonCount: Byte);
var
  LButtonIndex: Byte;

begin
  for LButtonIndex := 0 to AButtonCount do
  begin
    ScreenButtonDraw(AButtonsData^[LButtonIndex]);
  end;
end;

function MessageBoxDefaultIndex(var AButtonsData: PMessageBoxButtonsData;
  const AButtonCount: Byte; const ADefaultButton: TMessageBoxButton): Byte;
var
  LButtonIndex: Byte;

begin
  for LButtonIndex := 0 to AButtonCount do
  begin
    if AButtonsData^[LButtonIndex].Tag = Byte(ADefaultButton) then
    begin
      MessageBoxDefaultIndex := LButtonIndex;

      Break;
    end;
  end;
end;

function MessageBoxAccelerator(const AAccelerator: Char; const AMessageBoxButtons: TMessageBoxButtons): TMessageBoxResult;
var
  LButton: TMessageBoxButton;

begin
  for LButton := Low(TMessageBoxButton) to High(TMessageBoxButton) do
  begin
    if LButton in AMessageBoxButtons then
    begin
      if UpCase(sMessageBoxButtons[LButton][0]) = AAccelerator then
      begin
        MessageBoxAccelerator := kMessageBoxResults[LButton];

        Exit;
      end;
    end;
  end;

  MessageBoxAccelerator := mrUndefined;
end;

function MessageBoxEventHandler(var AButtonsData: PMessageBoxButtonsData;
  const AMessageBoxData: TMessageBoxData): TMessageBoxResult;
var
  LScanCode: Word;
  LKey: Char;
  LButtonCount: Byte;
  LButtonIndex: Byte;
  LMessageBoxResult: TMessageBoxResult;

begin
  LButtonCount := MessageBoxButtonCount(AMessageBoxData.Buttons);
  LButtonIndex := MessageBoxDefaultIndex(AButtonsData, LButtonCount, AMessageBoxData.DefaultButton);
  ScreenButtonHighlight(AButtonsData^[LButtonIndex]);

  while True do
  begin
    LScanCode := GetScanCode;
    LKey := UpCase(GetStandardKey(LScanCode));

    case LKey of
      kKeyExtended:
        begin
          case GetExtendedKey(LScanCode) of
            kKeyLeft:
              begin
                ScreenButtonNormal(AButtonsData^[LButtonIndex]);

                if LButtonIndex < LButtonCount then
                begin
                  Inc(LButtonIndex);
                end else
                begin
                  LButtonIndex := 0;
                end;

                ScreenButtonHighlight(AButtonsData^[LButtonIndex]);
              end;

            kKeyRight:
              begin
                ScreenButtonNormal(AButtonsData^[LButtonIndex]);

                if LButtonIndex > 0 then
                begin
                  Dec(LButtonIndex);
                end else
                begin
                  LButtonIndex := LButtonCount;
                end;

                ScreenButtonHighlight(AButtonsData^[LButtonIndex]);
              end;

          end;
        end;

      kKeyEnter:
        begin
          MessageBoxEventHandler := kMessageBoxResults[TMessageBoxButton(AButtonsData^[LButtonIndex].Tag)];

          Break;
        end;

      kKeyEscape:
        begin
          MessageBoxEventHandler := mrCancel;

          Break;
        end;

    else
      LMessageBoxResult := MessageBoxAccelerator(LKey, AMessageBoxData.Buttons);

      case LMessageBoxResult of
        mrUndefined:
          Continue;

      else
        MessageBoxEventHandler := LMessageBoxResult;

        Break;
      end;
    end;
  end;
end;

procedure ScreenMessageBoxPrepare(var AMessageBoxData: TMessageBoxData; const ATitle, AText: String;
  const AButtons: TMessageBoxButtons; const ADefaultButton: TMessageBoxButton);
begin
  AMessageBoxData.Title := ATitle;
  AMessageBoxData.Text := AText;
  AMessageBoxData.Buttons := AButtons;
  AMessageBoxData.DefaultButton := ADefaultButton;
end;

function ScreenMessageBoxDraw(const AMessageBoxData: TMessageBoxData): TMessageBoxResult;
var
  LIndex: Byte;
  LStringsCount: Byte;
  LStringsSize: Word;
  LStrings: PStrings;
  LMaxLength: Integer;
  LVideoArea: TVideoArea;
  LVideoSection: PVideoSection;
  LFrameData: TFrameData;
  LButtonCount: Byte;
  LButtonsDataSize: Word;
  LButtonsData: PMessageBoxButtonsData;

begin
  LStringsCount := FindOccurences(AMessageBoxData.Text, sCRLF);
  LStringsSize := Succ(LStringsCount) * kMaxByte;

  GetMem(LStrings, LStringsSize);

  Split(AMessageBoxData.Text, sCRLF, LStrings);

  LMaxLength := MaxLength(LStrings, LStringsCount);

  LVideoArea.PositionX := (k80x25Width div 2) - ((LMaxLength + 4) div 2);
  LVideoArea.PositionY := (k80x25Height div 2) - 3;
  LVideoArea.Width := LMaxLength + 4;
  LVideoArea.Height := LStringsCount + 7;

  VideoGetSection(LVideoSection, LVideoArea);

  LFrameData.PositionX := LVideoArea.PositionX;
  LFrameData.PositionY := LVideoArea.PositionY;
  LFrameData.Width := LVideoArea.Width;
  LFrameData.Height := Pred(LVideoArea.Height);
  LFrameData.Colors.Foreground := AMessageBoxData.Colors.Foreground;
  LFrameData.Colors.Background := AMessageBoxData.Colors.Background;
  LFrameData.FrameType := ftWindow;

  ScreenFrameDraw(LFrameData);

  VideoWriteStringAt(
    LVideoArea.PositionX,
    Succ(LVideoArea.PositionY),
    PadCenter(AMessageBoxData.Title, kMessageBoxTitlePadding),
    AMessageBoxData.Colors.Background,
    AMessageBoxData.Colors.Foreground
  );

  VideoWriteRegion(
    Succ(LVideoArea.PositionX),
    LVideoArea.PositionY + 2,
    LMaxLength + 2,
    LFrameData.Height - 2,
    cSpace,
    VideoAttribute(
      AMessageBoxData.Colors.Foreground,
      AMessageBoxData.Colors.Background
    )
  );

  for LIndex := 0 to LStringsCount do
  begin
    VideoWriteStringAt(
      LVideoArea.PositionX + 2,
      LVideoArea.PositionY + 3 + LIndex,
      LStrings^[LIndex],
      AMessageBoxData.Colors.Foreground,
      AMessageBoxData.Colors.Background
    );
  end;

  LButtonCount := MessageBoxButtonCount(AMessageBoxData.Buttons);
  LButtonsDataSize := SizeOf(TButtonData) * LButtonCount;

  GetMem(LButtonsData, LButtonsDataSize);

  MessageBoxCreateButtons(
    LVideoArea.PositionX + LFrameData.Width - 2,
    Pred(LVideoArea.PositionY + LFrameData.Height),
    AMessageBoxData,
    LButtonsData
  );

  MessageBoxDrawButtons(LButtonsData, LButtonCount);

  ScreenMessageBoxDraw := MessageBoxEventHandler(LButtonsData, AMessageBoxData);

  FreeMem(LButtonsData, LButtonsDataSize);

  VideoSetSection(LVideoSection, LVideoArea);

  FreeMem(LStrings, LStringsSize);
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
  LPosition: Byte;
  LAttribute: Byte;

begin
  VideoWriteStringAt(
    ASliderData.PositionX,
    ASliderData.PositionY + APositionY,
    AChannelText,
    ASliderData.Colors.Text,
    ASliderData.Colors.Background
  );

  for LPosition := 0 to APosition do
  begin
    VideoWriteCharAttrAt(
      ASliderData.PositionX + LPosition + kMixerSlidersTipX,
      ASliderData.PositionY + APositionY,
      AChar,
      VideoAttribute(
        StereoSliderGetBarColor(LPosition, ASliderData.Colors),
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
    for LPosition := Succ(APosition) to ASliderData.Max do
    begin
      VideoWriteCharAttrAt(
        ASliderData.PositionX + LPosition + kMixerSlidersTipX,
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
  LAttribute: Byte;
  LHighAttribute: Byte;
  LLeftAttribute: Byte;
  LRightAttribute: Byte;

begin
  LAttribute := VideoAttribute(
    ASliderData.Colors.Text,
    ASliderData.Colors.Background
  );

  LHighAttribute := VideoAttribute(
    ASliderData.Colors.HighForeground,
    ASliderData.Colors.HighBackground
  );

  if AValue then
  begin
    case AChannel of
      scLeft:
        begin
          LLeftAttribute := LHighAttribute;
          LRightAttribute := LAttribute;
        end;

      scRight:
        begin
          LLeftAttribute := LAttribute;
          LRightAttribute := LHighAttribute;
        end;

    end;
  end else
  begin
    LLeftAttribute := LAttribute;
    LRightAttribute := LAttribute;
  end;

  VideoHighlightRegion(
    ASliderData.PositionX,
    ASliderData.PositionY + kMixerSlidersLeftY,
    Length(sMixerSliderLeft),
    kSliderChannelHeight,
    LLeftAttribute
  );

  VideoHighlightRegion(
    ASliderData.PositionX,
    ASliderData.PositionY + kMixerSlidersRightY,
    Length(sMixerSliderRight),
    kSliderChannelHeight,
    LRightAttribute
  );
end;

procedure ScreenStereoSliderMove(var ASliderData: TStereoSliderData;
  const AChannel: TCodecSoundChannel; const ADirection: TSliderDirection);
var
  LStoreLock: Boolean;

begin
  LStoreLock := ASliderData.Locked;
  if not LStoreLock then
  begin
    ASliderData.Locked := GetShiftDown;
  end;

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
        StereoSliderAct(ASliderData, ASliderData.LeftPosition, ADirection, kMixerSlidersLeftY, cSliderLeftBar);

      scRight:
        StereoSliderAct(ASliderData, ASliderData.RightPosition, ADirection, kMixerSlidersRightY, cSliderRightBar);

    end;

    StereoSliderUpdate(ASliderData, AChannel);
  end;

  if not LStoreLock then
  begin
    ASliderData.Locked := LStoreLock;
  end;
end;

end.
