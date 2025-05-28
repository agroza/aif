{ --------------------------------------------------------------------------- }
{ - Audio Interface - System Timer (systimer.pas)                           - }
{ - Copyright (C) 1998-2025 Alexandru Groza of Microprogramming TECHNIQUES  - }
{ - All rights reserved.                                                    - }
{ --------------------------------------------------------------------------- }
{ - License: GNU General Public License v3.0                                - }
{ --------------------------------------------------------------------------- }

unit SysTimer;

interface

type
  TCallback = procedure;

procedure SysTimerInterruptHook(const ACallback: TCallback);
procedure SysTimerInterruptRelease; far;

implementation

uses
  Dos;

type
  TSysTimerControl = packed record
    Callback: TCallback;
    OldVector: Pointer;
    OldExitProc: Pointer;
  end;

const
  kSysTimerInterruptVector     = $1C;

var
  IGSysTimerControl: TSysTimerControl;

procedure SysTimerInterrupt; forward;

{ private declarations }

procedure SysTimerInterrupt; assembler;
asm
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  push ds
  push es
  push bp

  mov ax, seg IGSysTimerControl
  mov ds, ax

  cmp word ptr ds:[IGSysTimerControl.Callback + 2], 0
  je @@skipCallback
  cmp word ptr ds:[IGSysTimerControl.Callback], 0
  je @@skipCallback

  call dword ptr ds:[IGSysTimerControl.Callback]

@@skipCallback:
  cmp word ptr ds:[IGSysTimerControl.OldVector + 2], 0
  je @@exit
  cmp word ptr ds:[IGSysTimerControl.OldVector], 0
  je @@exit

{
  old $1C ISR call is skipped by intention, as it will just perform an IRET,
  rendering the SysTimerInterrupt stack unbalanced
}

@@exit:
  pop bp
  pop es
  pop ds
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax

  iret
end;

{ public declarations }

procedure SysTimerInterruptHook(const ACallback: TCallback);
begin
  IGSysTimerControl.Callback := ACallback;

  GetIntVec(kSysTimerInterruptVector, IGSysTimerControl.OldVector);
  SetIntVec(kSysTimerInterruptVector, Addr(SysTimerInterrupt));

  IGSysTimerControl.OldExitProc := ExitProc;
  ExitProc := Addr(SysTimerInterruptRelease);
end;

procedure SysTimerInterruptRelease;
begin
  SetIntVec(kSysTimerInterruptVector, IGSysTimerControl.OldVector);

  ExitProc := IGSysTimerControl.OldExitProc;
end;

end.
