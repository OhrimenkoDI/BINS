{ **** UBPFD *********** by ****
>> Com порт - Асинхронная работа

Клас позволяет работать в асинхронном режиме с COM портом
// Class: TComPort
// Description: Asynchronous (overlapped) COM port
// Version: 1.0
// Date: 10-Jun-2003
// Author: Igor Pavlov, pavlov_igor@nm.ru
// Copyright: (c) 2003, Igor Pavlov
// *****************************************
// Edited and putched
// Date: 01/07/2003
// Author: Mukovoz IL'ya Sergeevich, nuclear@bel.ru

Зависимости: SysUtils, Windows, Variants, Classes, Dialogs
Автор:       Igor Pavlov, Mukovoz IL'ya, pavlov_igor@nm.ru, nuclear@bel.ru, ICQ:126654980
Copyright:   (c) 2003, Igor Pavlov
Дата:        30 июля 2003 г.
******************************* }

unit uComPort;

////////////////////////////////////////////////////////////////////////////////
// //
// Class: TComPort //
// //
// Description: Asynchronous (overlapped) COM port //
// Version: 1.0 //
// Date: 10-Jun-2003 //
// Author: Igor Pavlov, pavlov_igor@nm.ru //
// //
// Copyright: (c) 2003, Igor Pavlov //
// //
////////////////////////////////////////////////////////////////////////////////

//*******************************************************************************
// *
// Edited and putched *
// *
// Date: 01/07/2003 *
// Author: Mukovoz IL'ya Sergeevich, nuclear@bel.ru *
// *
//*******************************************************************************

interface

uses
  SysUtils, Windows, Variants, Classes, Dialogs;

type
  EComPortError = class(Exception);

  TBaudRate = (br110 = CBR_110,
               br300 = CBR_300,
               br600 = CBR_600,
               br1200 = CBR_1200,
               br2400 = CBR_2400,
               br4800 = CBR_4800,
               br9600 = CBR_9600,
               br14400 = CBR_14400,
               br19200 = CBR_19200,
               br38400 = CBR_38400,
               br56000 = CBR_56000,
               br57600 = CBR_57600,
               br115200 = CBR_115200,
               br128000 = CBR_128000,
               br230400 = 230400,
               br921600 = 921600,
               br256000 = CBR_256000);

  TComPort = class;

  {Reading thread}
  TReadThread = class(TThread)
  private
    FBuf: array[0..$FFFF] of Byte;
    FComPort  : TComPort;
    FOverRead : TOverlapped;
    FRead: DWORD;
    arrBytes: array of Byte;
    procedure DoRead;
//    procedure DoRead1;
  protected
    procedure Execute; override;
  public
    constructor Create(ComPort: TComPort);
    destructor Destroy; override;
  end;

  {Reading event}
  TReadEvent = procedure(Sender: TObject; ReadBytes: array of Byte) of object;

  {Com port class}
  TComPort = class
  private
    FOverWrite : TOverlapped;
    FPort : THandle;
    FPortName: String;
    FReadEvent: TReadEvent;
    FReadThread: TReadThread;
  public
    constructor Create(PortNumber: Cardinal; BaudRate: TBaudRate);
    destructor Destroy; override;
    procedure Write(WriteBytes: array of Byte);
  published
    property OnRead: TReadEvent read FReadEvent write FReadEvent;
    property PortName: String read FPortName;
  end;

implementation
uses Unit1;

constructor TReadThread.Create(ComPort: TComPort);
begin
  FComPort := ComPort;
  ZeroMemory(@FOverRead, SizeOf(FOverRead));

  {Event}
  FOverRead.hEvent := CreateEvent(nil, True, False, nil);

  if FOverRead.hEvent = Null then
    raise EComPortError.Create('Error creating read event');

  inherited Create(False);
end;

destructor TReadThread.Destroy;
begin
  CloseHandle(FOverRead.hEvent);

  inherited Destroy;
end;

{
procedure TReadThread.DoRead1;
var
  i: Integer;
  TmpStr : string;
  st:string;
begin
  TmpStr := '';
  st:='';
  for i := 0 to FRead-1 do
  begin
    TmpStr := TmpStr + IntToHex(fbuf[i], 2);
    st:=st+(char(fbuf[i]));
  end;
  frmMain.Memo2.Lines.Add(st);
end;    {}


(*
procedure TReadThread.Execute;
var
 ComStat: TComStat;
 dwMask, dwError: DWORD;
 OverRead: TOverlapped;
// dwRead: DWORD;
 begin
 OverRead.hEvent := CreateEvent(nil, True, False, nil);
 if OverRead.hEvent = Null then
 raise Exception.Create('Error creating read event');

 FreeOnTerminate := True;

 while not Terminated do
 begin
 if not WaitCommEvent(FComPort.FPort, dwMask, @OverRead) then
 begin
 if GetLastError = ERROR_IO_PENDING then
 WaitForSingleObject(OverRead.hEvent, INFINITE)
 else
 raise Exception.Create('Error waiting port event');
 end;

 if not ClearCommError(FComPort.FPort, dwError, @ComStat) then
 raise Exception.Create('Error clearing port');

 FRead := ComStat.cbInQue;

 if FRead > 0 then
 begin
 if not ReadFile(FComPort.FPort, FBuf, FRead, FRead, @OverRead) then
 raise Exception.Create('Error reading port');
 // В Buf находятся прочитанные байты
 // Далее идет обработка принятых байтов
      Synchronize(DoRead1);
 end;
 end; {while}
 end;  *)

procedure TReadThread.Execute;
var
  ComStat: TComStat;
  dwMask, dwError: DWORD;
begin
  FreeOnTerminate := True;

  while not Terminated do
  begin
    if not WaitCommEvent(FComPort.FPort, dwMask, @FOverRead) then
    begin
      if GetLastError = ERROR_IO_PENDING then
        WaitForSingleObject(FOverRead.hEvent, INFINITE)
      else
        ;//      raise EComPortError.Create('Error waiting port ' + FComPort.PortName          + ' event');
    end;

    if Terminated then exit;

    if not Terminated then
      if not ClearCommError(FComPort.FPort, dwError, @ComStat) then
        raise EComPortError.Create('Error clearing port ' + FComPort.PortName);

    FRead := ComStat.cbInQue;

    if (FRead > 0) then
    begin
      if (not ReadFile(FComPort.FPort, FBuf, FRead, FRead, @FOverRead)) then
        raise EComPortError.Create('Error reading port ' + FComPort.PortName);

      Synchronize(DoRead);
//      DoRead;
    end;
  end; {while}
end;



procedure TReadThread.DoRead;
var
  i: Integer;
begin
if Assigned(FComPort) then
  if Assigned(FComPort.FReadEvent) then
  begin
    SetLength(arrBytes, FRead);
    for i := Low(FBuf) to FRead - 1 do
      arrBytes[i] := FBuf[i];

//      Synchronize(DoRead1);

    FComPort.FReadEvent(Self, arrBytes);

    arrBytes := nil;
  end;
end;

constructor TComPort.Create(PortNumber: Cardinal; BaudRate: TBaudRate);
var
  Dcb: TDcb;
begin
  inherited Create;

  ZeroMemory(@FOverWrite, SizeOf(FOverWrite));
  FPortName := 'COM' + IntToStr(PortNumber);

  {Open port}
  FPort := CreateFile(PChar(PortName),
    GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);

  if FPort = INVALID_HANDLE_VALUE then
    raise EComPortError.Create('Error opening port ' + PortName);

  try
    {Set port state}
    if not GetCommState(FPort, Dcb) then
      raise EComPortError.Create('Error setting port ' + PortName + ' state');

    Dcb.BaudRate := DWORD(BaudRate);
    Dcb.Parity := NOPARITY;
    Dcb.ByteSize := 8;
//    Dcb.StopBits := ONESTOPBIT;
//    Dcb.StopBits := ONE5STOPBITS;
    Dcb.StopBits := TWOSTOPBITS;

    if not SetCommState(FPort, Dcb) then
      raise EComPortError.Create('Error setting port ' + PortName + ' state');

    {Purge port}
    if not PurgeComm(FPort, PURGE_TXCLEAR or PURGE_RXCLEAR) then
      raise EComPortError.Create('Error purging port ' + PortName);

    {Set mask}
    if not SetCommMask(FPort, EV_RXCHAR) then
      raise EComPortError.Create('Error setting port ' + PortName + ' mask');

    FOverWrite.hEvent := CreateEvent(nil, True, False, nil);

    if FOverWrite.hEvent = Null then
      raise EComPortError.Create('Error creating write event');

    {Reading thread}
    FReadThread := TReadThread.Create(Self);
  except
    CloseHandle(FOverWrite.hEvent);
    CloseHandle(FPort);
    raise;
  end;
end;



destructor TComPort.Destroy;
begin
  if Assigned(FReadThread) then
    FReadThread.Terminate;
    
  CloseHandle(FOverWrite.hEvent);
  CloseHandle(FPort);

  inherited Destroy;
end;

var
  dwWrite: DWORD;
  l:integer;
procedure TComPort.Write(WriteBytes: array of Byte);
begin
l:=SizeOf(WriteBytes);
    if (not WriteFile(FPort, WriteBytes, SizeOf(WriteBytes), dwWrite, @FOverWrite))
    and (GetLastError <> ERROR_IO_PENDING) then
      raise EComPortError.Create('Error writing port ' + PortName);
end;

end.
