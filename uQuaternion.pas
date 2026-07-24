unit uQuaternion;

interface

uses System.Types, System.Math.Vectors;

type
  TQuaternion = record
    constructor Create(const AAxis: TPoint3D; const AAngle: Single); overload;
    constructor Create(const AYaw, APitch, ARoll: Single); overload;
    constructor Create(const AMatrix: TMatrix3D); overload;

    class operator Implicit(const AQuaternion: TQuaternion): TMatrix3D;
    class operator Multiply(const AQuaternion1, AQuaternion2: TQuaternion): TQuaternion; overload;
    class operator Negative(const AQuaternion: TQuaternion):TQuaternion;


    // calculates quaternion magnitude
    function Length: Single;
    function Normalize: TQuaternion;
    function Inverse: TQuaternion;
    function Dot(a,b:TQuaternion):Single;
    function Lerp(q1, q2:TQuaternion; t:Single):TQuaternion;

    function Slerp(fromq, toq:TQuaternion; t:Single):TQuaternion;


    case Integer of
      0: (V: TVector3DType;);
      1: (ImagPart: TPoint3D;
          RealPart: Single;);
      2:  (X,Y,Z,W:Single);
  end;

  TQuaternionConstants = record helper for TQuaternion
    const Identity: TQuaternion = (ImagPart: (X: 0; Y: 0; Z: 0); RealPart: 1);
  end;



implementation

uses
  System.Math;

procedure SinCosSingle(const Theta: Single; var Sin, Cos: Single);
var
{$IF SizeOf(Extended) > SizeOf(Double)}
  S, C: Extended;
{$ELSE}
  S, C: Double;
{$ENDIF}
begin
  System.SineCosine(Theta, S, C);
  Sin := S;
  Cos := C;
end;


{ TQuaternion }

constructor TQuaternion.Create(const AAxis: TPoint3D; const AAngle: Single);
var
  AxisLen, Sine, Cosine: Single;
begin
  AxisLen := AAxis.Length;

  if AxisLen > 0 then
  begin
    SinCosSingle(AAngle / 2, Sine, Cosine);

    Self.RealPart := Cosine;
    Self.ImagPart := AAxis * (Sine / AxisLen);
  end else Self := Identity;
end;

constructor TQuaternion.Create(const AYaw, APitch, ARoll: Single);
begin
  Self := TQuaternion.Create(Point3D(0, 1, 0), AYaw) * TQuaternion.Create(Point3D(1, 0, 0), APitch)
    * TQuaternion.Create(Point3D(0, 0, 1), ARoll);
end;

constructor TQuaternion.Create(const AMatrix: TMatrix3D);
var
  Trace, S: double;
  NewQuat: TQuaternion;
begin
  Trace := AMatrix.m11 + AMatrix.m22 + AMatrix.m33;
  if Trace > EPSILON then
  begin
    S := 0.5 / Sqrt(Trace + 1.0);
    NewQuat.ImagPart.X := (AMatrix.M23 - AMatrix.M32) * S;
    NewQuat.ImagPart.Y := (AMatrix.M31 - AMatrix.M13) * S;
    NewQuat.ImagPart.Z := (AMatrix.M12 - AMatrix.M21) * S;
    NewQuat.RealPart := 0.5 * Sqrt(Trace + 1.0);
  end
  else if (AMatrix.M11 > AMatrix.M22) and (AMatrix.M11 > AMatrix.M33) then
  begin
    S := Sqrt(Max(EPSILON, 1 + AMatrix.M11 - AMatrix.M22 - AMatrix.M33)) * 2.0;
    NewQuat.ImagPart.X := 0.25 * S;
    NewQuat.ImagPart.Y := (AMatrix.M12 + AMatrix.M21) / S;
    NewQuat.ImagPart.Z := (AMatrix.M31 + AMatrix.M13) / S;
    NewQuat.RealPart := (AMatrix.M23 - AMatrix.M32) / S;
  end
  else if (AMatrix.M22 > AMatrix.M33) then
  begin
    S := Sqrt(Max(EPSILON, 1 + AMatrix.M22 - AMatrix.M11 - AMatrix.M33)) * 2.0;
    NewQuat.ImagPart.X := (AMatrix.M12 + AMatrix.M21) / S;
    NewQuat.ImagPart.Y := 0.25 * S;
    NewQuat.ImagPart.Z := (AMatrix.M23 + AMatrix.M32) / S;
    NewQuat.RealPart := (AMatrix.M31 - AMatrix.M13) / S;
  end else
  begin
    S := Sqrt(Max(EPSILON, 1 + AMatrix.M33 - AMatrix.M11 - AMatrix.M22)) * 2.0;
    NewQuat.ImagPart.X := (AMatrix.M31 + AMatrix.M13) / S;
    NewQuat.ImagPart.Y := (AMatrix.M23 + AMatrix.M32) / S;
    NewQuat.ImagPart.Z := 0.25 * S;
    NewQuat.RealPart := (AMatrix.M12 - AMatrix.M21) / S;
  end;
  Self := NewQuat.Normalize;
end;

function TQuaternion.Dot(a, b: TQuaternion): Single;
begin
  Result := a.x * b.x + a.y * b.y + a.z * b.z + a.W * b.W;
end;

class operator TQuaternion.Implicit(const AQuaternion: TQuaternion): TMatrix3D;
var
  NormQuat: TQuaternion;
  xx, xy, xz, xw, yy, yz, yw, zz, zw: Single;
begin
  NormQuat := AQuaternion.Normalize;

{$EXCESSPRECISION OFF}
  xx := NormQuat.ImagPart.X * NormQuat.ImagPart.X;
  xy := NormQuat.ImagPart.X * NormQuat.ImagPart.Y;
  xz := NormQuat.ImagPart.X * NormQuat.ImagPart.Z;
  xw := NormQuat.ImagPart.X * NormQuat.RealPart;
  yy := NormQuat.ImagPart.Y * NormQuat.ImagPart.Y;
  yz := NormQuat.ImagPart.Y * NormQuat.ImagPart.Z;
  yw := NormQuat.ImagPart.Y * NormQuat.RealPart;
  zz := NormQuat.ImagPart.Z * NormQuat.ImagPart.Z;
  zw := NormQuat.ImagPart.Z * NormQuat.RealPart;
{$EXCESSPRECISION ON}

  FillChar(Result, Sizeof(Result), 0);
  Result.M11 := 1 - 2 * (yy + zz);
  Result.M21 := 2 * (xy - zw);
  Result.M31 := 2 * (xz + yw);
  Result.M12 := 2 * (xy + zw);
  Result.M22 := 1 - 2 * (xx + zz);
  Result.M32 := 2 * (yz - xw);
  Result.M13 := 2 * (xz - yw);
  Result.M23 := 2 * (yz + xw);
  Result.M33 := 1 - 2 * (xx + yy);
  Result.M44 := 1;
end;

function TQuaternion.Inverse: TQuaternion;
begin
  result := self;
  with result.ImagPart do begin
    X := -X;
    Y := -Y;
    Z := -Z;
  end;
  result.RealPart := result.RealPart;
end;

class operator TQuaternion.Multiply(const AQuaternion1, AQuaternion2: TQuaternion): TQuaternion;
begin
  Result.RealPart := AQuaternion1.RealPart * AQuaternion2.RealPart - AQuaternion1.ImagPart.X * AQuaternion2.ImagPart.X
    - AQuaternion1.ImagPart.Y * AQuaternion2.ImagPart.Y - AQuaternion1.ImagPart.Z * AQuaternion2.ImagPart.Z;
  Result.ImagPart.X := AQuaternion1.RealPart * AQuaternion2.ImagPart.X + AQuaternion2.RealPart * AQuaternion1.ImagPart.X
    + AQuaternion1.ImagPart.Y * AQuaternion2.ImagPart.Z - AQuaternion1.ImagPart.Z * AQuaternion2.ImagPart.Y;
  Result.ImagPart.Y := AQuaternion1.RealPart * AQuaternion2.ImagPart.Y + AQuaternion2.RealPart * AQuaternion1.ImagPart.Y
    + AQuaternion1.ImagPart.Z * AQuaternion2.ImagPart.X - AQuaternion1.ImagPart.X * AQuaternion2.ImagPart.Z;
  Result.ImagPart.Z := AQuaternion1.RealPart * AQuaternion2.ImagPart.Z + AQuaternion2.RealPart * AQuaternion1.ImagPart.Z
    + AQuaternion1.ImagPart.X * AQuaternion2.ImagPart.Y - AQuaternion1.ImagPart.Y * AQuaternion2.ImagPart.X;
end;

function TQuaternion.Length: Single;
begin
  Result := Sqrt(Self.ImagPart.DotProduct(Self.ImagPart) + Self.RealPart * Self.RealPart);
end;

function TQuaternion.Lerp(q1, q2: TQuaternion; t: Single): TQuaternion;
var
  q:TQuaternion;
begin
  if t<0 then t:=0;
  if t>1 then t:=1;

  if Dot(q1, q2) < 0 then begin
		q.x := q1.x + t * (-q2.x -q1.x);
		q.y := q1.y + t * (-q2.y -q1.y);
		q.z := q1.z + t * (-q2.z -q1.z);
		q.w := q1.w + t * (-q2.w -q1.w);
  end else begin
		q.x := q1.x + (q2.x - q1.x) * t;
		q.y := q1.y + (q2.y - q1.y) * t;
		q.z := q1.z + (q2.z - q1.z) * t;
		q.w := q1.w + (q2.w - q1.w) * t;
  end;

  Result := q.Normalize;
end;


class operator TQuaternion.Negative(
  const AQuaternion: TQuaternion): TQuaternion;
begin
  result.x:=-AQuaternion.x;
  result.y:=-AQuaternion.y;
  result.z:=-AQuaternion.z;
  result.w:=-AQuaternion.w;
end;

function TQuaternion.Normalize: TQuaternion;
var
  QuatLen, InvLen: Single;
begin
  QuatLen := Self.Length;
  if QuatLen > EPSILON2 then
  begin
{$EXCESSPRECISION OFF}
    InvLen := 1 / QuatLen;
    Result.ImagPart := Self.ImagPart * InvLen;
    Result.RealPart := Self.RealPart * InvLen;
{$EXCESSPRECISION ON}
  end
  else
    Result := Identity;
end;

function TQuaternion.Slerp(fromq, toq: TQuaternion; t: Single): TQuaternion;
var
  sinAngle, cosAngle, angle, invSinAngle : Single;
  t1, t2 : Single;
begin
  if t<0 then t:=0;
  if t>1 then t:=1;

    fromq := fromq.Normalize;
    toq := toq.Normalize;
	cosAngle := Dot(fromq, toq);

    if cosAngle < 0 then begin
        cosAngle := -cosAngle;
        toq := -toq;
    end;

    cosAngle := EnsureRange(cosAngle, -1.0, 1.0);

    if cosAngle < 0.95 then begin
	    angle 	:= ArcCos(cosAngle);
		  sinAngle := sin(angle);
      invSinAngle := 1 / sinAngle;
      t1 := sin((1 - t) * angle) * invSinAngle;
      t2 := sin(t * angle) * invSinAngle;
		  with Result do begin
        x := fromq.x * t1 + toq.x * t2;
        y := fromq.y * t1 + toq.y * t2 ;
        z := fromq.z * t1 + toq.z * t2;
        w := fromq.w * t1 + toq.w * t2;
      end;
      Result := Result.Normalize;
    end else begin
	   	Result := Lerp(fromq, toq, t)
    end
end;

end.
