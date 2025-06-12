{ --------------------------------------------------------------------------- }
{ - Audio Interface - Version Scheme (version.inc)                          - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{$DEFINE BETA}

  sMajor    = '3';
  sMinor    = '5';
  sBuild    = '648';
  sRevision = 'B';
  sVersion  = 'VER.'#32 + sMajor + '.' + sMinor + '.' + sBuild +
              {$IFDEF BETA}'-á' + {$ENDIF}#32'REV.'#32 + sRevision;
