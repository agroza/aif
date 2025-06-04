{ --------------------------------------------------------------------------- }
{ - Audio Interface - Conditional Defines (cdefines.inc)                    - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

{
  Notes:
    * A 16-bit CPU is required by the Audio Interface hardware.
    * Since the CD Player sub-program could be independently used with 8-bit
      (i.e.: 8088-class) CPUs, with or without a sound card installed, the
      following directive can be undefined.
}

{$DEFINE CPU16BIT}

{
  Disambiguation:
    * Undefine the appropriate statement to remove a sub-program from the
      main program compiled code.
    * Doing so reduces the executable file size, streamlining the driver,
      if required.
}

{.$DEFINE PNPSETUP}
{$DEFINE CDPLAYER}
