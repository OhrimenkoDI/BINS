unit uPowerGraphQuaternion;

interface

uses
  System.Classes, Winapi.WinSock;

type
  TQuaternionReceivedEvent = procedure(const W, X, Y, Z: Single) of object;

  TPowerGraphQuaternionReceiver = class(TThread)
  private
    FSocket: TSocket;
    FPort: Word;
    FOnQuaternion: TQuaternionReceivedEvent;
    procedure DeliverQuaternion(const W, X, Y, Z: Single);
  protected
    procedure Execute; override;
  public
    constructor Create(const APort: Word;
      const AOnQuaternion: TQuaternionReceivedEvent);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

const
  INVALID_UDP_SOCKET = TSocket(INVALID_SOCKET);

function ReadUInt32LE(const Buffer: array of Byte; const Offset: Integer): Cardinal;
begin
  Move(Buffer[Offset], Result, SizeOf(Result));
end;

function ReadInt16LE(const Buffer: array of Byte; const Offset: Integer): SmallInt;
begin
  Move(Buffer[Offset], Result, SizeOf(Result));
end;

function Crc32(const Buffer: array of Byte; const Count: Integer): Cardinal;
var
  I, BitIndex: Integer;
begin
  Result := $FFFFFFFF;
  for I := 0 to Count - 1 do
  begin
    Result := Result xor Buffer[I];
    for BitIndex := 0 to 7 do
      if (Result and 1) <> 0 then
        Result := (Result shr 1) xor $EDB88320
      else
        Result := Result shr 1;
  end;
  Result := not Result;
end;

function DigitalToQuaternion(const Value: SmallInt): Single;
begin
  // Inverse of SetCHANNELS for the physical range -1.0 .. +1.0.
  Result := -1.0 + (Integer(Value) + 32768) * (2.0 / 65535.0);
  if Value = 0 then
    Result := 0.0;
end;

constructor TPowerGraphQuaternionReceiver.Create(const APort: Word;
  const AOnQuaternion: TQuaternionReceivedEvent);
begin
  // Create(False) starts the thread from TThread.AfterConstruction, after all
  // receiver fields below have been initialized. Calling Start here would make
  // AfterConstruction attempt a second start.
  inherited Create(False);
  FreeOnTerminate := False;
  FSocket := INVALID_UDP_SOCKET;
  FPort := APort;
  FOnQuaternion := AOnQuaternion;
end;

destructor TPowerGraphQuaternionReceiver.Destroy;
begin
  Terminate;
  if FSocket <> INVALID_UDP_SOCKET then
  begin
    closesocket(FSocket);
    FSocket := INVALID_UDP_SOCKET;
  end;
  WaitFor;
  inherited;
end;

procedure TPowerGraphQuaternionReceiver.DeliverQuaternion(
  const W, X, Y, Z: Single);
begin
  if Assigned(FOnQuaternion) then
    FOnQuaternion(W, X, Y, Z);
end;

procedure TPowerGraphQuaternionReceiver.Execute;
var
  Addr, SourceAddr: TSockAddrIn;
  SourceLen, ReadCount: Integer;
  Buffer: array[0..65534] of Byte;
  Mask, PacketCrc, ReceivedCrc: Cardinal;
  Channel, Offset, PacketLength: Integer;
  Values: array[29..32] of SmallInt;
  W, X, Y, Z: Single;
begin
  FSocket := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if FSocket = INVALID_UDP_SOCKET then
    Exit;

  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  Addr.sin_addr.S_addr := INADDR_ANY;
  Addr.sin_port := htons(FPort);
  if bind(FSocket, Addr, SizeOf(Addr)) = SOCKET_ERROR then
    Exit;

  while not Terminated do
  begin
    SourceLen := SizeOf(SourceAddr);
    ReadCount := recvfrom(FSocket, Buffer[0], SizeOf(Buffer), 0,
      SourceAddr, SourceLen);
    if Terminated then
      Break;
    if ReadCount < 12 then
      Continue;
    if (Buffer[0] <> Ord('A')) or (Buffer[1] <> Ord('D')) or
       (Buffer[2] <> Ord('C')) or (Buffer[3] <> Ord('O')) then
      Continue;

    Mask := ReadUInt32LE(Buffer, 4);
    if (Mask and $F0000000) <> $F0000000 then
      Continue;

    Offset := 8;
    FillChar(Values, SizeOf(Values), 0);
    for Channel := 1 to 32 do
      if (Mask and (Cardinal(1) shl (Channel - 1))) <> 0 then
      begin
        if Offset + 2 > ReadCount then
          Break;
        if Channel >= 29 then
          Values[Channel] := ReadInt16LE(Buffer, Offset);
        Inc(Offset, 2);
      end;

    PacketLength := Offset + SizeOf(Cardinal);
    if PacketLength <> ReadCount then
      Continue;
    PacketCrc := Crc32(Buffer, Offset);
    ReceivedCrc := ReadUInt32LE(Buffer, Offset);
    if PacketCrc <> ReceivedCrc then
      Continue;

    W := DigitalToQuaternion(Values[29]);
    X := DigitalToQuaternion(Values[30]);
    Y := DigitalToQuaternion(Values[31]);
    Z := DigitalToQuaternion(Values[32]);
    Synchronize(
      procedure
      begin
        DeliverQuaternion(W, X, Y, Z);
      end);
  end;
end;

var
  WSAData: TWSAData;

initialization
  WSAStartup($0202, WSAData);

finalization
  WSACleanup;

end.
