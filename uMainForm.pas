unit uMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Math, uModel, uModelQ,
  System.Math.Vectors, uQuaternion, Vcl.Clipbrd, uJoystick,
  uPowerGraphQuaternion, uPowerGraphUdpSplitter;

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    QuatW: TLabel;
    QuatX: TLabel;
    QuatY: TLabel;
    QuatZ: TLabel;
    Memo1: TMemo;
    Button1: TButton;
    ScrollBar1: TScrollBar;
    EdAz: TEdit;
    edEl: TEdit;
    BtSol: TButton;
    Pitch: TLabel;
    Yaw: TLabel;
    Roll: TLabel;
    ColorDialog1: TColorDialog;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure BtSolClick(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
  private
    { Private declarations }
    FJoystick: TJoystickController;
    FJoystickTimer: TTimer;
    FJoystickStatus: TLabel;
    FJoystickConnected: Boolean;
    FPowerGraphSplitter: TPowerGraphUdpSplitter;

    FHasSolution: Boolean;
    procedure JoystickTimer(Sender: TObject);
    procedure ApplyPowerGraphPacket(const Packet: TBytes);
    procedure UpdateTargetAndErrors;
    function QuaternionFromFinalZ(const AzimuthDeg, ElevationDeg: Double;
      out Q: TQuaternion): Boolean;
    function TryReadAngle(Edit: TEdit; out Value: Double): Boolean;
    function  d2x(Image:TImage;muxyz:tvec3;fixyz:tvec3;x,y,z:double):integer;
    function  d2y(Image:TImage;muxyz:tvec3;fixyz:tvec3;x,y,z:double):integer;
    procedure Line3D(Image:TImage;muxyz:tvec3;fixyz:tvec3;x1,y1,z1,x2,y2,z2:double;Color:TColor;Width:integer;st:string='');
    procedure redrawI(Image:TImage;muxyz:tvec3;fixyz:tvec3);
    procedure RedrawQ(Image:TImage;muxyz:tvec3;fixyz:tvec3;Quater:TQuaternion;stx,sty,stz:string);
   public
    { Public declarations }
    destructor Destroy; override;
    procedure ApplyUDPQuaternion(const W, X, Y, Z: Single;
      const Channels: TPowerGraphBnoData);
    procedure redraw;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  qInit;

  QBodyDjo := TQuaternion.Identity;
  FQStart := TQuaternion.Identity;
  FQFin := TQuaternion.Identity;
  FQTarget := TQuaternion.Identity;
  FHasSolution := False;

  FJoystickStatus := TLabel.Create(Self);
  FJoystickStatus.Parent := Panel1;
  FJoystickStatus.Left := 330;
  FJoystickStatus.Top := 8;
  FJoystickStatus.Caption := 'Joystick: search...';

  FJoystickConnected := False;
  FJoystick := TJoystickController.Create;
  FJoystickTimer := TTimer.Create(Self);
  FJoystickTimer.Interval := 20;
  FJoystickTimer.OnTimer := JoystickTimer;
  FJoystickTimer.Enabled := True;
  self.DoubleBuffered:=true;
  QuatW.Caption := 'qW: waiting';
  QuatX.Caption := 'qX: waiting';
  QuatY.Caption := 'qY: waiting';
  QuatZ.Caption := 'qZ: waiting';
  Memo1.Lines.Text := 'Quaternion: waiting';
  // Image1: вид справа, плоскость X-Z (Body FRD).
  // X направлена вправо (вперёд), Z направлена вниз.
  fixyz1[0]:=30;
  fixyz1[1]:=150;
  fixyz1[2]:=-90;
  muxyz1[0]:=180;
  muxyz1[1]:=180;
  muxyz1[2]:=180;

  // Image2: вид спереди, плоскость Y-Z.
  // Y направлена вправо, Z направлена вниз.
  fixyz2[0]:=0;
  fixyz2[1]:=0;
  fixyz2[2]:=-90;
  muxyz2[0]:=0;
  muxyz2[1]:=180;
  muxyz2[2]:=180;

  // Image3: вид сверху, плоскость X-Y.
  // X (нос) направлена вверх, Y (правое крыло) направлена вправо.
  fixyz3[0]:=0;
  fixyz3[1]:=90;
  fixyz3[2]:=0;
  muxyz3[0]:=180;
  muxyz3[1]:=180;
  muxyz3[2]:=  0;

  // Image4: аксонометрия Body FRD.
  // X: вправо-вверх 30 градусов; Y: влево-вниз 30 градусов; Z: вниз.
  fixyz4[0]:=30+180;
  fixyz4[1]:=150-180;
  fixyz4[2]:=90;
  muxyz4[0]:=180;
  muxyz4[1]:=180;
  muxyz4[2]:=180;

  redraw;
  FPowerGraphSplitter := TPowerGraphUdpSplitter.Create(31080, 31078,
    ApplyPowerGraphPacket);
 end;

destructor TMainForm.Destroy;
begin
  FreeAndNil(FPowerGraphSplitter);
  FreeAndNil(FJoystick);
  inherited;
end;

procedure TMainForm.ApplyPowerGraphPacket(const Packet: TBytes);
var
  Channels: TPowerGraphBnoData;
begin
  if TryDecodePowerGraphBnoData(Packet, Channels) then
    ApplyUDPQuaternion(
      Channels.Value[29], Channels.Value[30],
      Channels.Value[31], Channels.Value[32], Channels);
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  Clipboard.AsText := Memo1.Text;
end;

function TMainForm.TryReadAngle(Edit: TEdit; out Value: Double): Boolean;
var
  S: string;
begin
  S := Trim(Edit.Text);
  Result := TryStrToFloat(S, Value);
  if not Result then
  begin
    if FormatSettings.DecimalSeparator = ',' then
      S := StringReplace(S, '.', ',', [rfReplaceAll])
    else
      S := StringReplace(S, ',', '.', [rfReplaceAll]);
    Result := TryStrToFloat(S, Value);
  end;
end;

// расчет финального кватерниона
function TMainForm.QuaternionFromFinalZ(const AzimuthDeg,
  ElevationDeg: Double; out Q: TQuaternion): Boolean;
var
  Az, El, CEl: Double;
  XX, XY, XZ, YX, YY, YZ, ZX, ZY, ZZ: Double;
  L, Trace, S: Double;
begin
  // Navigation frame used by the received quaternion has Z pointing Up.
  // EdAz/edEl describe the forward/sight direction, which at the end is
  // Body -Z. Azimuth 0 is +X, positive azimuth turns toward +Y.
  Az := DegToRad(AzimuthDeg);
  El := DegToRad(ElevationDeg);
  CEl := Cos(El);
  ZY := -CEl * Cos(Az);
  ZX := -CEl * Sin(Az);
  ZZ := -Sin(El);

  // Zero-roll completion of the frame: Body X is the projection of Down (-Z)
  // onto the plane normal to Body Z. At elevation 0 Body X points Down.
  XX := ZZ * ZX;
  XY := ZZ * ZY;
  XZ := -1.0 + ZZ * ZZ;
  L := Sqrt(XX * XX + XY * XY + XZ * XZ);
  Result := L > 1.0E-8;
  if not Result then
    Exit;
  XX := XX / L;
  XY := XY / L;
  XZ := XZ / L;

  // Right-handed Body FRD frame: Y = Z x X, so X x Y = Z.
  YX := ZY * XZ - ZZ * XY;
  YY := ZZ * XX - ZX * XZ;
  YZ := ZX * XY - ZY * XX;

  // Rotation matrix columns are the Body X/Y/Z axes in navigation coordinates.
  Trace := XX + YY + ZZ;
  if Trace > 0 then
  begin
    S := 2.0 * Sqrt(Trace + 1.0);
    Q.W := 0.25 * S;
    Q.X := (YZ - ZY) / S;
    Q.Y := (ZX - XZ) / S;
    Q.Z := (XY - YX) / S;
  end
  else if (XX > YY) and (XX > ZZ) then
  begin
    S := 2.0 * Sqrt(1.0 + XX - YY - ZZ);
    Q.W := (YZ - ZY) / S;
    Q.X := 0.25 * S;
    Q.Y := (YX + XY) / S;
    Q.Z := (ZX + XZ) / S;
  end
  else if YY > ZZ then
  begin
    S := 2.0 * Sqrt(1.0 + YY - XX - ZZ);
    Q.W := (ZX - XZ) / S;
    Q.X := (YX + XY) / S;
    Q.Y := 0.25 * S;
    Q.Z := (ZY + YZ) / S;
  end
  else
  begin
    S := 2.0 * Sqrt(1.0 + ZZ - XX - YY);
    Q.W := (XY - YX) / S;
    Q.X := (ZX + XZ) / S;
    Q.Y := (ZY + YZ) / S;
    Q.Z := 0.25 * S;
  end;
  Q := Q.Normalize;
end;

procedure TMainForm.BtSolClick(Sender: TObject);
var
  Azimuth, Elevation: Double;
begin
  if not TryReadAngle(EdAz, Azimuth) then
  begin
    MessageDlg('Неверно задан азимут EdAz.', mtError, [mbOK], 0);
    Exit;
  end;
  if not TryReadAngle(edEl, Elevation) then
  begin
    MessageDlg('Неверно задан угол к горизонту edEl.', mtError, [mbOK], 0);
    Exit;
  end;

  // расчет финального кватерниона
  if not QuaternionFromFinalZ(Azimuth, Elevation, FQFin) then
  begin
    MessageDlg('Для вертикальной оси Z ориентация по азимуту не определена.',
      mtError, [mbOK], 0);
    Exit;
  end;

  FQStart := QBNO055.Normalize;
  FHasSolution := True;
end;

procedure TMainForm.ScrollBar1Change(Sender: TObject);
begin
end;

// расчет ошибки кватерниона и перевод в углы Эйлера для рулежки
procedure TMainForm.UpdateTargetAndErrors;
var
  T, VLen, Angle, K: Double;
  QError: TQuaternion;
begin
  // если нет расчета, то выход
  if not FHasSolution then
    Exit;

  T := EnsureRange(ScrollBar1.Position / 10.0, 0.0, 1.0);
  FQTarget := FQStart.Slerp(FQStart, FQFin, T).Normalize;

  // q3 and QTarget are q_nb. This product expresses the correction
  // from current attitude to target attitude in the current Body frame.
  QError := (QBNO055.Inverse * FQTarget).Normalize;
  if QError.W < 0 then
    QError := -QError;

  VLen := Sqrt(Sqr(QError.X) + Sqr(QError.Y) + Sqr(QError.Z));
  if VLen > 1.0E-8 then
  begin
    Angle := 2.0 * ArcTan2(VLen, QError.W);
    K := Angle / VLen;
  end
  else
    K := 2.0;

  Memo1.Lines.Add('');
  Memo1.Lines.Add('t                  ' + FormatFloat('0.000', T));
  Memo1.Lines.Add('QStart             ' + Format(
    'W=%0.6f X=%0.6f Y=%0.6f Z=%0.6f',
    [FQStart.W, FQStart.X, FQStart.Y, FQStart.Z]));
  Memo1.Lines.Add('QFin               ' + Format(
    'W=%0.6f X=%0.6f Y=%0.6f Z=%0.6f',
    [FQFin.W, FQFin.X, FQFin.Y, FQFin.Z]));
  Memo1.Lines.Add('QTarget            ' + Format(
    'W=%0.6f X=%0.6f Y=%0.6f Z=%0.6f',
    [FQTarget.W, FQTarget.X, FQTarget.Y, FQTarget.Z]));
  Memo1.Lines.Add('Pitch error        ' +
    FormatFloat('0.000', RadToDeg(K * QError.Y)) + ' deg');
  Memo1.Lines.Add('Roll error         ' +
    FormatFloat('0.000', RadToDeg(K * QError.X)) + ' deg'); {}
  Memo1.Lines.Add('Yaw error         ' +
    FormatFloat('0.000', RadToDeg(K * QError.Z)) + ' deg'); {}
end;

procedure TMainForm.ApplyUDPQuaternion(const W, X, Y, Z: Single;
  const Channels: TPowerGraphBnoData);
var
 vPitch,vRoll,vYaw,sinPitch:double;
begin
  // данные от датчика
  QBNO055.W := W;
  QBNO055.X := X;
  QBNO055.Y := Y;
  QBNO055.Z := Z;
  QBNO055 := QBNO055.Normalize;

  QModel.W :=  QBNO055.W;
  QModel.X :=  QBNO055.Y;
  QModel.Y :=  QBNO055.X;
  QModel.Z := -QBNO055.Z;

  // q3 = q_nb: преобразование из Body FRD в навигационную систему.
  // Получаем направления Forward, Right и Down после поворота аппарата.
  oX3 := QBNO055 * oX * QBNO055.Inverse;
  oY3 := QBNO055 * oY * QBNO055.Inverse;
  oZ3 := QBNO055 * oZ * QBNO055.Inverse;

  magVecLoc.W := 0.0;
  magVecLoc.X := Channels.Value[17];
  magVecLoc.Y := Channels.Value[18];
  magVecLoc.Z := Channels.Value[19];
  magVecWord := (QBNO055 * magVecLoc * QBNO055.Inverse).Normalize;

  GravVecLoc.W := 0.0;
  GravVecLoc.X := Channels.Value[20];
  GravVecLoc.Y := Channels.Value[21];
  GravVecLoc.Z := Channels.Value[22];
  GravVecWord := (QBNO055 * GravVecLoc * QBNO055.Inverse).Normalize;


  redrawI(Image1, muxyz1, fixyz1);
  redrawI(Image2, muxyz2, fixyz2);
  redrawI(Image3, muxyz3, fixyz3);
  redrawI(Image4, muxyz4, fixyz4);

  RedrawQ(Image1,muxyz1,fixyz4,QBNO055,'X','Y','Z'); // Рисуем оси кватерниона
  RedrawQ(Image2,muxyz2,fixyz4,QBNO055,'X','Y','Z'); // Рисуем оси кватерниона
  RedrawQ(Image3,muxyz3,fixyz4,QBNO055,'X','Y','Z'); // Рисуем оси кватерниона
  RedrawQ(Image4,muxyz4,fixyz4,QBNO055,'X','Y','Z'); // Рисуем оси кватерниона

  RedrawQ(Image1,muxyz1,fixyz4,FQTarget,'qfX','qfY','qfZ'); // Рисуем оси кватерниона
  RedrawQ(Image2,muxyz2,fixyz4,FQTarget,'qfX','qfY','qfZ'); // Рисуем оси кватерниона
  RedrawQ(Image3,muxyz3,fixyz4,FQTarget,'qfX','qfY','qfZ'); // Рисуем оси кватерниона
  RedrawQ(Image4,muxyz4,fixyz4,FQTarget,'qfX','qfY','qfZ'); // Рисуем оси кватерниона


  QBNO055:=QBNO055.Normalize;

 // Вычисляем синус тангажа (критическое значение для блокировки)
  with QBNO055 do
    sinPitch := 2.0 * (w * y - z * x);

  // Проверка на блокировку кардана (Gimbal lock)
  // Если sinPitch близок к ±1, значит тангаж = ±90°
  if Abs(sinPitch) >= 1.0 - 1e-6 then
  begin
    // Блокировка кардана! Тангаж = ±90°
    // В этом случае крен и рыскание становятся неразличимыми
    vPitch := Arcsin(sinPitch) * (180.0 / Pi);  // ±90°

    // При блокировке обнуляем крен и вычисляем только рыскание
    vRoll := 0.0;

    // Вычисляем рыскание (Yaw) по упрощенной формуле
    with QBNO055 do
      vYaw := ArcTan2(2.0 * (w * z - x * y), 1.0 - 2.0 * (y * y + z * z)) * (180.0 / Pi);
  end
  else
  begin
    // Нормальный режим - все углы вычисляются однозначно
    with QBNO055 do
    begin
      vPitch := Arcsin(sinPitch) * (180.0 / Pi);

      vRoll := ArcTan2(2.0 * (w * x + y * z),
                       1.0 - 2.0 * (x * x + y * y)) * (180.0 / Pi);

      vYaw := ArcTan2(2.0 * (w * z + x * y),
                      1.0 - 2.0 * (y * y + z * z)) * (180.0 / Pi);
    end;
  end;

  // Вывод результатов
  Pitch.Caption := 'Pitch  ' + FormatFloat('0.000000', vPitch);
  Roll.Caption  := 'Roll   ' + FormatFloat('0.000000', vRoll);
  Yaw.Caption   := 'Yaw    ' + FormatFloat('0.000000', vYaw);


  // Raw BNO055 quaternion after transport decoding and normalization.
  QuatW.Caption := 'qW  ' + FormatFloat('0.000000', QBNO055.W);
  QuatX.Caption := 'qX  ' + FormatFloat('0.000000', QBNO055.X);
  QuatY.Caption := 'qY  ' + FormatFloat('0.000000', QBNO055.Y);
  QuatZ.Caption := 'qZ  ' + FormatFloat('0.000000', QBNO055.Z);

  Memo1.Lines.BeginUpdate;
  try
    Memo1.Clear;
    // Channels written with SetCHANNELS_RAW: display without scaling.
    Memo1.Lines.Add('Ch09 BNO055CalSys     ' + IntToStr(Channels.Raw[9]));
    Memo1.Lines.Add('Ch10 BNO055CalGyro    ' + IntToStr(Channels.Raw[10]));
    Memo1.Lines.Add('Ch11 BNO055CalAccel   ' + IntToStr(Channels.Raw[11]));
    Memo1.Lines.Add('Ch12 BNO055CalMag     ' + IntToStr(Channels.Raw[12]));
    Memo1.Lines.Add('Ch13 BNO055DataReady  ' + IntToStr(Channels.Raw[13]));
    Memo1.Lines.Add('Ch14 BNO055DataOk     ' + IntToStr(Channels.Raw[14]));
    Memo1.Lines.Add('Ch15 BNO055RtStep     ' + IntToStr(Channels.Raw[15]));
    Memo1.Lines.Add('Ch16 MSPOrangeValid   ' + IntToStr(Channels.Raw[16]));

    // Channels written with SetCHANNELS: display restored physical values.
    Memo1.Lines.Add('Ch17 BNO055MagX       ' +
      FormatFloat('0.000000', Channels.Value[17]) + ' uT');
    Memo1.Lines.Add('Ch18 BNO055MagY       ' +
      FormatFloat('0.000000', Channels.Value[18]) + ' uT');
    Memo1.Lines.Add('Ch19 BNO055MagZ       ' +
      FormatFloat('0.000000', Channels.Value[19]) + ' uT');

    Memo1.Lines.Add('Ch20 GravityX         ' +
      FormatFloat('0.000000', Channels.Value[20]) + ' m/s2');
    Memo1.Lines.Add('Ch21 GravityY         ' +
      FormatFloat('0.000000', Channels.Value[21]) + ' m/s2');
    Memo1.Lines.Add('Ch22 GravityZ         ' +
      FormatFloat('0.000000', Channels.Value[22]) + ' m/s2');

    Memo1.Lines.Add('Ch23 BNO055GyroX      ' +
      FormatFloat('0.000000', Channels.Value[23]) + ' d/s');
    Memo1.Lines.Add('Ch24 BNO055GyroY      ' +
      FormatFloat('0.000000', Channels.Value[24]) + ' d/s');
    Memo1.Lines.Add('Ch25 BNO055GyroZ      ' +
      FormatFloat('0.000000', Channels.Value[25]) + ' d/s');

    Memo1.Lines.Add('Ch26 BNO055Heading    ' +
      FormatFloat('0.000000', Channels.Value[26]) + ' deg');
    Memo1.Lines.Add('Ch27 BNO055Roll       ' +
      FormatFloat('0.000000', Channels.Value[27]) + ' deg');
    Memo1.Lines.Add('Ch28 BNO055Pitch      ' +
      FormatFloat('0.000000', Channels.Value[28]) + ' deg');

    // Quaternion is displayed after physical scaling and normalization.
    Memo1.Lines.Add('Ch29 qW               ' +
      FormatFloat('0.000000', QBNO055.W));
    Memo1.Lines.Add('Ch30 qX               ' +
      FormatFloat('0.000000', QBNO055.X));
    Memo1.Lines.Add('Ch31 qY               ' +
      FormatFloat('0.000000', QBNO055.Y));
    Memo1.Lines.Add('Ch32 qZ               ' +
      FormatFloat('0.000000', QBNO055.Z));

    // если есть расчет на цель, то считаем углы для руления
    UpdateTargetAndErrors;
  finally
    Memo1.Lines.EndUpdate;
  end;



end;


procedure TMainForm.JoystickTimer(Sender: TObject);
const
  RotationSpeed = 1.5; // radians per second at full stick deflection
var
  JoyState: TJoystickState;
  DX, DY, DZ: Single;
  Angle: Single;
  Axis: TPoint3D;
  DeltaQ: TQuaternion;
begin
  if not FJoystick.Poll(-1000, 1000, JoyState) then
  begin
    if FJoystickConnected then
      FJoystickStatus.Caption := 'Joystick: disconnected';
    FJoystickConnected := False;
    Exit;
  end;

  if not FJoystickConnected then
    FJoystickStatus.Caption := 'Joystick: X/Y/V -> quaternion axis-angle';
  FJoystickConnected := True;

  // Один вектор углового перемещения в локальной системе аппарата.
  // Знаки осей сохранены из RotateW проекта 3DGraf.
  DX :=  JoyState.X / 1000 * RotationSpeed * FJoystickTimer.Interval / 1000;
  DY := -JoyState.Y / 1000 * RotationSpeed * FJoystickTimer.Interval / 1000;
  DZ := -JoyState.Z / 1000 * RotationSpeed * FJoystickTimer.Interval / 1000;

  Angle := Sqrt(DX * DX + DY * DY + DZ * DZ);
  if Angle = 0 then
    Exit;

  Axis := TPoint3D.Create(DX / Angle, DY / Angle, DZ / Angle);
  DeltaQ := TQuaternion.Create(Axis, Angle);
  QBodyDjo := (QBodyDjo * DeltaQ).Normalize;
//  UpdateQuaternionAxes;

  redrawI(Image1, muxyz1, fixyz1);
  redrawI(Image2, muxyz2, fixyz2);
  redrawI(Image3, muxyz3, fixyz3);
  redrawI(Image4, muxyz4, fixyz4);
end;

function TMainForm.d2x;
var
 h,w:integer;
begin
result:=0;
if abs(x)>5 then exit;
if abs(y)>5 then exit;
if abs(z)>5 then exit;

  w:=image.Width;
  h:=image.Height;
  result:=round(
          muxyz[0]*x*cos(fixyz[0]*deg)+
          muxyz[1]*y*cos(fixyz[1]*deg)+
          muxyz[2]*z*cos(fixyz[2]*deg))+w div 2;
end;

function TMainForm.d2y;
var
 h,w:integer;
begin
result:=0;
if abs(x)>5 then exit;
if abs(y)>5 then exit;
if abs(z)>5 then exit;

  w:=image.Width;
  h:=image.Height;
  result:=-round(
          muxyz[0]*x*sin(fixyz[0]*deg)+
          muxyz[1]*y*sin(fixyz[1]*deg)+
          muxyz[2]*z*sin(fixyz[2]*deg))+h div 2;
end;


procedure TMainForm.Line3D(
  Image:TImage;
  muxyz:tvec3;
  fixyz:tvec3;
  x1,y1,z1,x2,y2,z2:double;
  Color:TColor;
  Width:integer;
  st:string='');
var
 x,y:integer;
begin
  Image.Canvas.Pen.Color:=Color;
  Image.Canvas.Pen.Width:=Width;
  x:=d2x(Image,muxyz,fixyz,x1,y1,z1);
  y:=d2y(Image,muxyz,fixyz,x1,y1,z1);
  Image.Canvas.MoveTo(x,y);
  x:=d2x(Image,muxyz,fixyz,x2,y2,z2);
  y:=d2y(Image,muxyz,fixyz,x2,y2,z2);
  Image.Canvas.LineTo(x,y);
  Image.Canvas.TextOut(x,y,st);
end;


procedure TMainForm.redrawI(Image: TImage; muxyz, fixyz: tvec3);
begin
  with image.Canvas do FillRect(Rect(0,0,Width,Height));

  // Тонкие оси навигационной системы.
  Line3D(Image,muxyz,fixyz, 0,0,0,1,0,0,clRed  ,1,'E');
  Line3D(Image,muxyz,fixyz, 0,0,0,0,1,0,clGreen,1,'N');
  Line3D(Image,muxyz,fixyz, 0,0,0,0,0,1,clBlue ,1,'U');

  // Толстые оси текущей ориентации платформы.
//  with oX3 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clRed,    3,'X');
//  with oY3 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clGreen,  3,'Y');
//  with oZ3 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clBlue,   3,'Z');

  // Вектор магнитного поля
  with magVecWord do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clLime,    3,'Mag');

  // Вектор гравитации
  with GravVecWord do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clBlack,    3,'Grav');

end;

// рисуем кватернион на Image с подписями осей
procedure TMainForm.RedrawQ(Image:TImage;muxyz:tvec3;fixyz:tvec3;Quater: TQuaternion; stx, sty,
  stz: string);
var
  oXq,oYq,oZq : TQuaternion;  // оси
begin
  oXq := Quater * oX * Quater.Inverse;
  oYq := Quater * oY * Quater.Inverse;
  oZq := Quater * oZ * Quater.Inverse;

  // Толстые оси текущей ориентации платформы.
  with oXq do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,TColor($5050A7),  2, stx);
  with oYq do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,TColor($208020),  2, sty);
  with oZq do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,TColor($FF5050),  2, stz);


end;

procedure TMainForm.redraw;
begin
  redrawI(Image1,muxyz1,fixyz1);
  redrawI(Image2,muxyz2,fixyz2);
  redrawI(Image3,muxyz3,fixyz3);
  redrawI(Image4,muxyz4,fixyz4);
end;

end.




