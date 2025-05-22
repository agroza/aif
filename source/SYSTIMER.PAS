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

procedure SysTimerInvokeOldISR(const AAddress: Pointer); forward;
procedure SysTimerInterrupt; interrupt; forward;

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

procedure SysTimerInvokeOldISR(const AAddress: Pointer); assembler;
asm
  pop bp
  add sp, 02h

  pop bx
  pop ax

  mov word ptr [bp + 0Eh], bx
  mov word ptr [bp + 10h], ax

  mov sp, bp

  pop bp
  pop es
  pop ds
  pop di
  pop si
  pop dx
  pop cx

  retf
end;

procedure SysTimerInterrupt;
begin
  if Assigned(IGSysTimerControl.Callback) then
  begin
    IGSysTimerControl.Callback;
  end;

  if Assigned(IGSysTimerControl.OldVector) then
  begin
    SysTimerInvokeOldISR(IGSysTimerControl.OldVector);
  end;
end;

end.
