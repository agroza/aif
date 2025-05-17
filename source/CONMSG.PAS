{ --------------------------------------------------------------------------- }
{ - Audio Interface - Console Messages (conmsg.pas)                         - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$G+}

unit ConMsg;

interface

procedure ConMsgWriteProgramHeader;
procedure ConMsgWriteHelp;
procedure ConMsgWriteParameterMissing;
procedure ConMsgWriteStatus(const AMessage: String; const AStatus: Boolean);
procedure ConMsgWriteConfigChanged(const AMessage: String; const AStatus: Boolean);

implementation

uses
  Consts,
  Error,
  Params,
  Routines,
  Screen,
  Types,
  Video;

procedure ConMsgWriteProgramHeader;
begin
  VideoWriteNewln;

  VideoSetBackground(clBlack);

  VideoSetForeground(clHighlight);
  VideoWriteln(sProgramTitle);

  VideoSetForeground(clNormal);
  VideoWriteln(sProgramCopyright);
  VideoWriteln(sProgramAuthor);
  VideoWriteln(sProgramRights);

  VideoWriteNewln;
end;

procedure ConMsgWriteHelp;
var
  LHelpParameter: Byte;

begin
  VideoSetForeground(clNormal);
  VideoSetBackground(clBlack);

  VideoWriteln(sHelpUsage);
  VideoWriteln(sHelpWhere);

  for LHelpParameter := Low(kHelpParameters) to High(kHelpParameters) do
  begin
    VideoWriteln(StrPas(kHelpParameters[LHelpParameter]));
  end;

  VideoWriteNewln;
  VideoWriteln(sHelpExamples);
end;

procedure ConMsgWriteParameterMissing;
begin
  VideoSetForeground(clNormal);
  VideoSetBackground(clBlack);

  VideoWriteln(sParameterMissing);
  VideoWriteNewln;
  VideoWriteln(sTypeHelp);
end;

procedure ConMsgWriteStatus(const AMessage: String; const AStatus: Boolean);
begin
  if not GParameters.Quiet then
  begin
    ScreenWriteStatus(AMessage, sFAILEDOK[AStatus], clErrorSuccess[AStatus]);
  end;

  if not AStatus then
  begin
    ErrorWriteHalt;
  end;
end;

procedure ConMsgWriteConfigChanged(const AMessage: String; const AStatus: Boolean);
begin
  if not GParameters.Quiet and AStatus then
  begin
    ScreenWriteStatus(AMessage, sCHANGED, clChanged);

    if (GParameters.InitMode = imInvalid) and not GParameters.LineOut then
    begin
      ScreenWriteStatus(sAIFInitialization, sPENDING, clPending);
    end;
  end;
end;

end.
