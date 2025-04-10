{ --------------------------------------------------------------------------- }
{ - Audio Interface - Conditional Defines (cdefines.inc)                    - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{
  Disambiguation:
    * Undefine the appropriate statement to remove a sub-program from the
      main program compiled code.
    * Doing so reduces the executable file size, streamlining the driver,
      if required.
}

{$UNDEF PNPSETUP}
