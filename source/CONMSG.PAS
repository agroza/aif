{ --------------------------------------------------------------------------- }
{ - Audio Interface - Console Messages (conmsg.pas)                         - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit ConMsg;

interface

procedure ConMsgWriteProgramHeader;
procedure ConMsgWriteHelp;
procedure ConMsgWriteParameterMissing;
procedure ConMsgWriteConfigChanged(const AMessage: String; const AInitMessage: Boolean);

implementation

uses
  Consts,
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

procedure ConMsgWriteConfigChanged(const AMessage: String; const AInitMessage: Boolean);
begin
  ScreenWriteStatus(AMessage, sCHANGED, clChanged, not GParameters.Quiet);

  if AInitMessage then
  begin
    ScreenWriteStatus(sAIFInitialization, sPENDING, clPending, not GParameters.Quiet);
  end;
end;

end.
