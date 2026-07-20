unit uJoystick;

interface

uses
  Winapi.Windows;

type
  TJoystickState = record
    X: Integer;
    Y: Integer;
    Z: Integer;
  end;

  TJoystickController = class
  private
    FJoystickId: UINT;
    FConnected: Boolean;
    FDeadZonePercent: Integer;
    function FindJoystick: Boolean;
    function ReadRaw(out AX, AY, AZ: DWORD): Boolean;
    function ScaleAxis(const Value: DWORD; const AMin, AMax: Integer): Integer;
  public
    constructor Create;
    function Poll(const AMin, AMax: Integer;
      out State: TJoystickState): Boolean;
    property Connected: Boolean read FConnected;
    property JoystickId: UINT read FJoystickId;
    property DeadZonePercent: Integer read FDeadZonePercent
      write FDeadZonePercent;
  end;

implementation

const
  WinMM = 'winmm.dll';
  JOY_RETURN_ALL = $000000FF;
  JOYERR_NOERROR = 0;
  JOY_RAW_MIN = 0;
  JOY_RAW_MAX = 65535;
  MAX_JOYSTICKS_TO_SCAN = 16;

type
  TJoyInfoEx = record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwXpos: DWORD;
    dwYpos: DWORD;
    dwZpos: DWORD;
    dwRpos: DWORD;
    dwUpos: DWORD;
    dwVpos: DWORD;
    dwButtons: DWORD;
    dwButtonNumber: DWORD;
    dwPOV: DWORD;
    dwReserved1: DWORD;
    dwReserved2: DWORD;
  end;

function joyGetNumDevs: UINT; stdcall; external WinMM name 'joyGetNumDevs';
function joyGetPosEx(uJoyID: UINT; var JoyInfoEx: TJoyInfoEx): UINT;
  stdcall; external WinMM name 'joyGetPosEx';

constructor TJoystickController.Create;
begin
  inherited Create;
  FJoystickId := High(UINT);
  FConnected := False;
  FDeadZonePercent := 5;
end;

function TJoystickController.ReadRaw(out AX, AY, AZ: DWORD): Boolean;
var
  Info: TJoyInfoEx;
begin
  FillChar(Info, SizeOf(Info), 0);
  Info.dwSize := SizeOf(Info);
  Info.dwFlags := JOY_RETURN_ALL;
  Result := joyGetPosEx(FJoystickId, Info) = JOYERR_NOERROR;
  if Result then
  begin
    AX := Info.dwXpos;
    AY := Info.dwYpos;
    AZ := Info.dwVpos; // канал рыскания, настроенный в 3DGraf
  end;
end;

function TJoystickController.FindJoystick: Boolean;
var
  Id, Count: UINT;
  X, Y, Z: DWORD;
begin
  Result := False;
  Count := joyGetNumDevs;
  if Count = 0 then
  begin
    FConnected := False;
    Exit;
  end;
  if Count > MAX_JOYSTICKS_TO_SCAN then
    Count := MAX_JOYSTICKS_TO_SCAN;

  for Id := 0 to Count - 1 do
  begin
    FJoystickId := Id;
    if ReadRaw(X, Y, Z) then
    begin
      FConnected := True;
      Exit(True);
    end;
  end;

  FJoystickId := High(UINT);
  FConnected := False;
end;

function TJoystickController.ScaleAxis(const Value: DWORD;
  const AMin, AMax: Integer): Integer;
var
  Center, SignedValue, DeadZone, HalfRange: Int64;
begin
  Center := (JOY_RAW_MIN + JOY_RAW_MAX) div 2;
  HalfRange := (JOY_RAW_MAX - JOY_RAW_MIN) div 2;
  SignedValue := Int64(Value) - Center;
  DeadZone := HalfRange * FDeadZonePercent div 100;

  if Abs(SignedValue) <= DeadZone then
    Exit(0);

  if SignedValue < 0 then
    SignedValue := SignedValue + DeadZone
  else
    SignedValue := SignedValue - DeadZone;

  HalfRange := HalfRange - DeadZone;
  if SignedValue < -HalfRange then
    SignedValue := -HalfRange
  else if SignedValue > HalfRange then
    SignedValue := HalfRange;

  if SignedValue < 0 then
    Result := Integer((-SignedValue * AMin) div HalfRange)
  else
    Result := Integer((SignedValue * AMax) div HalfRange);
end;

function TJoystickController.Poll(const AMin, AMax: Integer;
  out State: TJoystickState): Boolean;
var
  X, Y, Z: DWORD;
begin
  if (not FConnected) and (not FindJoystick) then
    Exit(False);

  if not ReadRaw(X, Y, Z) then
  begin
    FConnected := False;
    Exit(False);
  end;

  State.X := ScaleAxis(X, AMin, AMax);
  State.Y := ScaleAxis(Y, AMin, AMax);
  State.Z := ScaleAxis(Z, AMin, AMax);
  Result := True;
end;

end.
