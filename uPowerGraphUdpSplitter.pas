unit uPowerGraphUdpSplitter;

interface

uses
  System.Classes, System.SysUtils, Winapi.WinSock;

type
  TPowerGraphPacketEvent = procedure(const Packet: TBytes) of object;

  TPowerGraphUdpSplitter = class(TThread)
  private
    FReceiverSocket: TSocket;
    FSenderSocket: TSocket;
    FListenPort: Word;
    FTargetPort: Word;
    FOnLatestPacket: TPowerGraphPacketEvent;
    procedure DeliverLatestPacket(const Packet: TBytes);
  protected
    procedure Execute; override;
  public
    constructor Create(const AListenPort, ATargetPort: Word;
      const AOnLatestPacket: TPowerGraphPacketEvent);
    destructor Destroy; override;
  end;

implementation

uses
  System.Generics.Collections, Winapi.Windows, Winapi.MMSystem;

const
  INVALID_UDP_SOCKET = TSocket(INVALID_SOCKET);
  DEFAULT_SEND_INTERVAL = 1.0 / 110.0;
  MIN_SEND_INTERVAL = 0.001;
  MAX_SEND_INTERVAL = 0.100;
  PERIOD_SMOOTHING = 0.25;
  MAX_POWERGRAPH_PACKET_SIZE = 4 + 4 + 32 * 2 + 4;
  MAX_UDP_DATAGRAM_SIZE = 65535;

function MonotonicSeconds: Double;
var
  Counter, Frequency: Int64;
begin
  QueryPerformanceCounter(Counter);
  QueryPerformanceFrequency(Frequency);
  Result := Counter / Frequency;
end;

function ReadUInt32LE(const Buffer: TBytes; const Offset: Integer): Cardinal;
begin
  Move(Buffer[Offset], Result, SizeOf(Result));
end;

function CountSetBits(Value: Cardinal): Integer;
begin
  Result := 0;
  while Value <> 0 do
  begin
    Inc(Result, Value and 1);
    Value := Value shr 1;
  end;
end;

function FindMagic(const Buffer: TBytes): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Length(Buffer) - 4 do
    if (Buffer[I] = Ord('A')) and (Buffer[I + 1] = Ord('D')) and
       (Buffer[I + 2] = Ord('C')) and (Buffer[I + 3] = Ord('O')) then
      Exit(I);
end;

procedure DeletePrefix(var Buffer: TBytes; const Count: Integer);
var
  Remaining: Integer;
begin
  if Count <= 0 then
    Exit;
  Remaining := Length(Buffer) - Count;
  if Remaining > 0 then
    Move(Buffer[Count], Buffer[0], Remaining);
  SetLength(Buffer, Remaining);
end;

procedure AppendBytes(var Buffer: TBytes; const Source; const Count: Integer);
var
  OldLength: Integer;
begin
  if Count <= 0 then
    Exit;
  OldLength := Length(Buffer);
  SetLength(Buffer, OldLength + Count);
  Move(Source, Buffer[OldLength], Count);
end;

procedure ExtractPowerGraphPackets(var Buffer: TBytes;
  const Packets: TList<TBytes>);
var
  Start, PacketLength, KeepCount: Integer;
  Mask: Cardinal;
begin
  while True do
  begin
    Start := FindMagic(Buffer);
    if Start < 0 then
    begin
      KeepCount := Length(Buffer);
      if KeepCount > 3 then
        KeepCount := 3;
      if KeepCount > 0 then
        Move(Buffer[Length(Buffer) - KeepCount], Buffer[0], KeepCount);
      SetLength(Buffer, KeepCount);
      Exit;
    end;

    if Start > 0 then
      DeletePrefix(Buffer, Start);
    if Length(Buffer) < 8 then
      Exit;

    Mask := ReadUInt32LE(Buffer, 4);
    PacketLength := 4 + 4 + CountSetBits(Mask) * 2 + 4;
    if PacketLength > MAX_POWERGRAPH_PACKET_SIZE then
    begin
      DeletePrefix(Buffer, 1);
      Continue;
    end;
    if Length(Buffer) < PacketLength then
      Exit;

    Packets.Add(Copy(Buffer, 0, PacketLength));
    DeletePrefix(Buffer, PacketLength);
  end;
end;

constructor TPowerGraphUdpSplitter.Create(const AListenPort, ATargetPort: Word;
  const AOnLatestPacket: TPowerGraphPacketEvent);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FReceiverSocket := INVALID_UDP_SOCKET;
  FSenderSocket := INVALID_UDP_SOCKET;
  FListenPort := AListenPort;
  FTargetPort := ATargetPort;
  FOnLatestPacket := AOnLatestPacket;
end;

destructor TPowerGraphUdpSplitter.Destroy;
begin
  Terminate;
  if FReceiverSocket <> INVALID_UDP_SOCKET then
  begin
    closesocket(FReceiverSocket);
    FReceiverSocket := INVALID_UDP_SOCKET;
  end;
  if FSenderSocket <> INVALID_UDP_SOCKET then
  begin
    closesocket(FSenderSocket);
    FSenderSocket := INVALID_UDP_SOCKET;
  end;
  WaitFor;
  inherited;
end;

procedure TPowerGraphUdpSplitter.DeliverLatestPacket(const Packet: TBytes);
begin
  if Assigned(FOnLatestPacket) then
    FOnLatestPacket(Packet);
end;

procedure TPowerGraphUdpSplitter.Execute;
var
  ListenAddr, SourceAddr, TargetAddr: TSockAddrIn;
  SourceLen, ReadCount, SocketError, I: Integer;
  NonBlocking: u_long;
  Datagram: array[0..MAX_UDP_DATAGRAM_SIZE - 1] of Byte;
  StreamBuffer, Packet, LatestPacket: TBytes;
  NewPackets: TList<TBytes>;
  PacketQueue: TQueue<TBytes>;
  ReceivedAt, LastDatagramAt, EstimatedPeriod: Double;
  SendInterval, NextSendAt, MeasuredPeriod, NowSeconds: Double;
  TimerPeriodActive: Boolean;
begin
  TimerPeriodActive := timeBeginPeriod(1) = TIMERR_NOERROR;
  NewPackets := TList<TBytes>.Create;
  PacketQueue := TQueue<TBytes>.Create;
  try
    FReceiverSocket := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    FSenderSocket := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (FReceiverSocket = INVALID_UDP_SOCKET) or
       (FSenderSocket = INVALID_UDP_SOCKET) then
      Exit;

    FillChar(ListenAddr, SizeOf(ListenAddr), 0);
    ListenAddr.sin_family := AF_INET;
    ListenAddr.sin_addr.S_addr := INADDR_ANY;
    ListenAddr.sin_port := htons(FListenPort);
    if bind(FReceiverSocket, ListenAddr, SizeOf(ListenAddr)) = SOCKET_ERROR then
      Exit;

    NonBlocking := 1;
    if ioctlsocket(FReceiverSocket, FIONBIO, NonBlocking) = SOCKET_ERROR then
      Exit;

    FillChar(TargetAddr, SizeOf(TargetAddr), 0);
    TargetAddr.sin_family := AF_INET;
    TargetAddr.sin_addr.S_addr := htonl(INADDR_LOOPBACK);
    TargetAddr.sin_port := htons(FTargetPort);

    SendInterval := DEFAULT_SEND_INTERVAL;
    NextSendAt := MonotonicSeconds;
    LastDatagramAt := 0;
    EstimatedPeriod := 0;

    while not Terminated do
    begin
      while not Terminated do
      begin
        SourceLen := SizeOf(SourceAddr);
        ReadCount := recvfrom(FReceiverSocket, Datagram[0], SizeOf(Datagram), 0,
          SourceAddr, SourceLen);
        if ReadCount = SOCKET_ERROR then
        begin
          SocketError := WSAGetLastError;
          if SocketError = WSAEWOULDBLOCK then
            Break;
          if Terminated then
            Exit;
          Break;
        end;

        ReceivedAt := MonotonicSeconds;
        AppendBytes(StreamBuffer, Datagram[0], ReadCount);
        NewPackets.Clear;
        ExtractPowerGraphPackets(StreamBuffer, NewPackets);
        if NewPackets.Count = 0 then
          Continue;

        // The local visualization needs only the newest sample from the batch.
        LatestPacket := NewPackets[NewPackets.Count - 1];
        Synchronize(
          procedure
          begin
            DeliverLatestPacket(LatestPacket);
          end);

        if LastDatagramAt > 0 then
        begin
          MeasuredPeriod := ReceivedAt - LastDatagramAt;
          if EstimatedPeriod = 0 then
            EstimatedPeriod := MeasuredPeriod
          else
            EstimatedPeriod := EstimatedPeriod +
              PERIOD_SMOOTHING * (MeasuredPeriod - EstimatedPeriod);

          SendInterval := EstimatedPeriod / NewPackets.Count;
          if SendInterval < MIN_SEND_INTERVAL then
            SendInterval := MIN_SEND_INTERVAL;
          if SendInterval > MAX_SEND_INTERVAL then
            SendInterval := MAX_SEND_INTERVAL;
        end;

        LastDatagramAt := ReceivedAt;
        PacketQueue.Clear;
        for I := 0 to NewPackets.Count - 1 do
          PacketQueue.Enqueue(NewPackets[I]);
        NextSendAt := ReceivedAt;
      end;

      NowSeconds := MonotonicSeconds;
      if (PacketQueue.Count > 0) and (NowSeconds >= NextSendAt) then
      begin
        Packet := PacketQueue.Dequeue;
        sendto(FSenderSocket, Packet[0], Length(Packet), 0,
          TargetAddr, SizeOf(TargetAddr));
        NextSendAt := NowSeconds + SendInterval;
      end;

      Sleep(1);
    end;
  finally
    PacketQueue.Free;
    NewPackets.Free;
    if TimerPeriodActive then
      timeEndPeriod(1);
  end;
end;

var
  WSAData: TWSAData;

initialization
  WSAStartup($0202, WSAData);

finalization
  WSACleanup;

end.
