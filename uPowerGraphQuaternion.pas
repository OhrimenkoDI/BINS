unit uPowerGraphQuaternion;

interface

uses
  System.SysUtils;

const
  POWERGRAPH_FIRST_BNO_CHANNEL = 9;
  POWERGRAPH_LAST_BNO_CHANNEL = 32;

type
  TPowerGraphRawChannels =
    array[POWERGRAPH_FIRST_BNO_CHANNEL..POWERGRAPH_LAST_BNO_CHANNEL] of SmallInt;
  TPowerGraphScaledChannels =
    array[POWERGRAPH_FIRST_BNO_CHANNEL..POWERGRAPH_LAST_BNO_CHANNEL] of Single;

  TPowerGraphBnoData = record
    Raw: TPowerGraphRawChannels;
    Value: TPowerGraphScaledChannels;
  end;

function TryDecodePowerGraphBnoData(const Packet: TBytes;
  out Data: TPowerGraphBnoData): Boolean;

implementation

function ReadUInt32LE(const Buffer: TBytes; const Offset: Integer): Cardinal;
begin
  Move(Buffer[Offset], Result, SizeOf(Result));
end;

function ReadInt16LE(const Buffer: TBytes; const Offset: Integer): SmallInt;
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

function Crc32(const Buffer: TBytes; const Offset, Count: Integer): Cardinal;
var
  I, BitIndex: Integer;
begin
  Result := $FFFFFFFF;
  for I := Offset to Offset + Count - 1 do
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

function DigitalToPhysical(const DigitalValue: SmallInt;
  const PhysicalMin, PhysicalMax: Single): Single;
begin
  if DigitalValue = 0 then
    Exit(0.0);

  Result := PhysicalMin +
    (Integer(DigitalValue) + 32768) *
    ((PhysicalMax - PhysicalMin) / 65535.0);
end;

function ScaleChannel(const Channel: Integer;
  const DigitalValue: SmallInt): Single;
begin
  case Channel of
    9..16:
      Result := DigitalValue;
    17..19:
      Result := DigitalToPhysical(DigitalValue, -2500.0, 2500.0);
    20..22:
      Result := DigitalToPhysical(DigitalValue, -20.0, 20.0);
    23..25:
      Result := DigitalToPhysical(DigitalValue, -1000.0, 1000.0);
    26:
      Result := DigitalToPhysical(DigitalValue, -360.0, 360.0);
    27..28:
      Result := DigitalToPhysical(DigitalValue, -180.0, 180.0);
    29..32:
      Result := DigitalToPhysical(DigitalValue, -1.0, 1.0);
  else
    Result := DigitalValue;
  end;
end;

function TryDecodePowerGraphBnoData(const Packet: TBytes;
  out Data: TPowerGraphBnoData): Boolean;
var
  Mask, PacketCrc, ReceivedCrc: Cardinal;
  Channel, Offset, PacketLength: Integer;
begin
  Result := False;
  FillChar(Data, SizeOf(Data), 0);

  if Length(Packet) < 12 then
    Exit;
  if (Packet[0] <> Ord('A')) or (Packet[1] <> Ord('D')) or
     (Packet[2] <> Ord('C')) or (Packet[3] <> Ord('O')) then
    Exit;

  Mask := ReadUInt32LE(Packet, 4);
  if (Mask and $FFFFFF00) <> $FFFFFF00 then
    Exit;

  PacketLength := 4 + 4 + CountSetBits(Mask) * 2 + 4;
  if PacketLength <> Length(Packet) then
    Exit;

  PacketCrc := Crc32(Packet, 0, PacketLength - 4);
  ReceivedCrc := ReadUInt32LE(Packet, PacketLength - 4);
  if PacketCrc <> ReceivedCrc then
    Exit;

  Offset := 8;
  for Channel := 1 to 32 do
    if (Mask and (Cardinal(1) shl (Channel - 1))) <> 0 then
    begin
      if Channel >= POWERGRAPH_FIRST_BNO_CHANNEL then
      begin
        Data.Raw[Channel] := ReadInt16LE(Packet, Offset);
        Data.Value[Channel] := ScaleChannel(Channel, Data.Raw[Channel]);
      end;
      Inc(Offset, 2);
    end;

  Result := True;
end;

end.
