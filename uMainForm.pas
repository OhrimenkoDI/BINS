unit uMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,uComPort,Math,uModel,uModelQ,
  System.Math.Vectors, uQuaternion, Vcl.ComCtrls, uJoystick,
  uPowerGraphQuaternion;

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    BtOpenPort: TButton;
    BtClosePort: TButton;
    ComboCOM: TComboBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Memo1: TMemo;
    WAccFiltr0: TLabel;
    WAccFiltr1: TLabel;
    WAccFiltr2: TLabel;
    GyroZeroFiltr0: TLabel;
    GyroZeroFiltr1: TLabel;
    GyroZeroFiltr2: TLabel;
    pind1: TLabel;
    pind2: TLabel;
    pind0: TLabel;
    OXl2: TLabel;
    OYl2: TLabel;
    OZl0: TLabel;
    OZl1: TLabel;
    AccFiltr0: TLabel;
    AccFiltr1: TLabel;
    AccFiltr2: TLabel;
    iACC0: TLabel;
    iACC1: TLabel;
    iACC2: TLabel;
    Memo2: TMemo;
    TrackBar1: TTrackBar;
    iGir0: TLabel;
    iGir1: TLabel;
    iGir2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure BtClosePortClick(Sender: TObject);
    procedure BtOpenPortClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
  private
    { Private declarations }
    ng:integer;
    Port: TComPort;
    FJoystick: TJoystickController;
    FJoystickTimer: TTimer;
    FJoystickStatus: TLabel;
    FJoystickConnected: Boolean;
    FQuaternionReceiver: TPowerGraphQuaternionReceiver;
    procedure OnRead(Sender: TObject; ReadBytes: array of Byte);
    procedure JoystickTimer(Sender: TObject);
    procedure UpdateQuaternionAxes;
    function  d2x(Image:TImage;muxyz:tvec3;fixyz:tvec3;x,y,z:double):integer;
    function  d2y(Image:TImage;muxyz:tvec3;fixyz:tvec3;x,y,z:double):integer;
    procedure Line3D(Image:TImage;muxyz:tvec3;fixyz:tvec3;x1,y1,z1,x2,y2,z2:double;Color:TColor;Width:integer;st:string='');
    procedure redrawI(Image:TImage;muxyz:tvec3;fixyz:tvec3);
  public
    ReadBytes: array of byte;
    { Public declarations }
    destructor Destroy; override;
    procedure ApplyUDPQuaternion(const W, X, Y, Z: Single);
    procedure redraw;
  end;

var
  MainForm: TMainForm;

implementation

uses uGrafForm;

{$R *.dfm}

// Преобразование float32 Microchip -> float32 IEEE-754
//
function MCHPtoIEEE(a:dword):Single;
var
 x:array[0..3] of byte;
 s:Single;
begin
  Move(a,x,4);
    if (x[3] AND $01 )=$01 then begin        // Младший бит exp(Microchip) равен 1?
      x[3]:=x[3] shr 1;
      if (x[2]and $80)=$80 then
        x[3]:=x[3] or $80
      else
        x[2]:=x[2] or $80;
    end else begin
      x[3]:=x[3] shr 1;
      if (x[2]and $80)=$80 then begin
        x[3]:=x[3] or $80;
        x[2]:=x[2] AND not$80;
      end;
    end;
  move(x,s,4);
  result:=0;
  if IsNan(s) then begin
   // MainForm.Memo1.Lines.Add(FloatToStr(s));
   // MainForm.Memo1.Lines.Add(IntToHex(a,8))
  end
  else
    result:=s;
end;


function hextoint(st:string):dword;
var i:dword;
ch:byte;
begin
st:=UpperCase(st);
i:=0;
while length(st)>0 do begin
ch:=byte(st[1]);
if ch>$39 then ch:=ch-7;
ch:=ch-$30;
if ch>$F then begin
                hextoint:=dword(-1);
                exit;
              end;
i:=(i shl 4)+ch;
delete(st,1,1);
end;
hextoint:=i;
end;

Function HexToSmInt(st:string):Smallint;
begin
  Result:=Smallint(hextoint(st));
end;
///////////////////////////////

procedure TMainForm.FormCreate(Sender: TObject);
var
  i:integer;
begin
  qInit;

  q3 := TQuaternion.Identity;
  UpdateQuaternionAxes;

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
  Memo1.Clear;
   Memo2.Clear;
  ng:=0;

  for i:=0 to 10 do
    ComboCOM.Items.Add('COM'+inttostr(i));
  ComboCOM.ItemIndex:=7;

  // Image1: вид справа, плоскость X-Z (Body FRD).
  // X направлена вправо (вперёд), Z направлена вниз.
  fixyz1[0]:=0;
  fixyz1[1]:=0;
  fixyz1[2]:=-90;
  muxyz1[0]:=200;
  muxyz1[1]:=  0;
  muxyz1[2]:=200;

  // Image2: вид спереди, плоскость Y-Z.
  // Y направлена вправо, Z направлена вниз.
  fixyz2[0]:=0;
  fixyz2[1]:=0;
  fixyz2[2]:=-90;
  muxyz2[0]:=0;
  muxyz2[1]:=200;
  muxyz2[2]:=200;

  // Image3: вид сверху, плоскость X-Y.
  // X (нос) направлена вверх, Y (правое крыло) направлена вправо.
  fixyz3[0]:=0;
  fixyz3[1]:=90;
  fixyz3[2]:=0;
  muxyz3[0]:=180;
  muxyz3[1]:=180;
  muxyz3[2]:=  0;

  // Image4: аксонометрия Body FRD.
  // X: вправо-вверх 60 градусов; Y: вправо-вниз 30 градусов; Z: вниз.
  fixyz4[0]:=30;
  fixyz4[1]:=150;
  fixyz4[2]:=90;
  muxyz4[0]:=180;
  muxyz4[1]:=180;
  muxyz4[2]:=180;

  redraw;
  FQuaternionReceiver := TPowerGraphQuaternionReceiver.Create(31078,
    ApplyUDPQuaternion);
 end;

destructor TMainForm.Destroy;
begin
  FreeAndNil(FQuaternionReceiver);
  FreeAndNil(FJoystick);
  inherited;
end;

procedure TMainForm.ApplyUDPQuaternion(const W, X, Y, Z: Single);
begin
  q3.W := W;
  q3.X := X;
  q3.Y := Y;
  q3.Z := Z;
  q3 := q3.Normalize;
  UpdateQuaternionAxes;

  redrawI(Image1, muxyz1, fixyz1);
  redrawI(Image2, muxyz2, fixyz2);
  redrawI(Image3, muxyz3, fixyz3);
  redrawI(Image4, muxyz4, fixyz4);
end;

procedure TMainForm.UpdateQuaternionAxes;
begin
  // q3 = q_nb: преобразование из Body FRD в навигационную систему.
  // Получаем направления Forward, Right и Down после поворота аппарата.
  oX3 := q3 * oX * q3.Inverse;
  oY3 := q3 * oY * q3.Inverse;
  oZ3 := q3 * oZ * q3.Inverse;
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
  q3 := (q3 * DeltaQ).Normalize;
  UpdateQuaternionAxes;

  redrawI(Image1, muxyz1, fixyz1);
  redrawI(Image2, muxyz2, fixyz2);
  redrawI(Image3, muxyz3, fixyz3);
  redrawI(Image4, muxyz4, fixyz4);
end;

var
  kbufer : array[0..20] of char;  // кольцевой буфер

procedure shbuf;
var
  i:integer;
begin
  for i:= 0 to 19 do
    kbufer[i]:=kbufer[i+1];
end;

procedure TMainForm.OnRead(Sender: TObject; ReadBytes: array of Byte);
var
 i,j:integer;
 dw:dword;
 sm:Smallint;
 w:word;
 st,st1:string[20];
begin
//  FillChar(kbufer,sizeof(kbufer),0);
  for i := Low(ReadBytes) to High(ReadBytes) do
  begin
    if (ReadBytes[i]>=byte('0'))or(ReadBytes[i]=13) then begin
      shbuf;
      kbufer[19]:=char(ReadBytes[i]);

      if kbufer[19]=#13 then begin
        st:='';
        for j:=0 to 18 do
          if kbufer[j]>#0 then
            st:=st+char(kbufer[j]);
        FillChar(kbufer,sizeof(kbufer),0);

               // глобальная ось X
        if (st[1]='X')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          OXl[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // глобальная ось Y
        if (st[1]='Y')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          OYl[byte(st[2] )-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // глобальная ось Z
        if (st[1]='Z')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          OZl[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // фильтрованное смещение ноля гироскопа
        if (st[1]='g')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          GyroZeroFiltr[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // фильтрованый вектор гравитации с датчика ускорения
        if (st[1]='f')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          AccFiltr[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // фильтрованый вектор мнимого ускорения в глобальных координатах без ускорения свободного падения
        if (st[1]='w')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          WAccFiltr[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // вектор мнимого ускорения в глобальных координатах без ускорения свободного падения
        if (st[1]='W')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          WAcc[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // Вектор гравитации с датчика ускорения в единицах g=9.819 (Питер)
        if (st[1]='A')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          ACC_XYZ[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // Вектор гравитации с датчика ускорения нормализованый до 1
        if (st[1]='S')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          AccNorm[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // Вектор гравитации с датчика ускорения чистаые данные
        if (st[1]='i')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          iACC[byte(st[2])-byte('0')]:=integer(dw);
        end;

        // Вектор угловой скорости
        if (st[1]='G')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          iGir[byte(st[2])-byte('0')]:=integer(dw);
        end;


        if (st[1]='P')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          pind[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;



        // Скорости полученные интегрированием
        if (st[1]='D')and(st[2]>='0')and(st[2]<='2') then begin
          dw:=hextoint(copy(st,3,8));
          SPD_XYZ[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        // Путь полученные интегрированием  скорости
        if (st[1]='d')and(st[2]>='0')and(st[2]<='2') then begin
          st1:=copy(st,3,8);
          dw:=hextoint(st1);
          DIST_XYZ[byte(st[2])-byte('0')]:=MCHPtoIEEE(dw);
        end;

        if (st[1]='t') then begin
          redraw;
        end;



      end; //if kbufer[19]=13 then begin

    end;
    end;
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


procedure TMainForm.Line3D;
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

  // глобальные оси
  Line3D(Image,muxyz,fixyz, 0,0,0,1,0,0,clRed  ,1,'X');
  Line3D(Image,muxyz,fixyz, 0,0,0,0,1,0,clGreen,1,'Y');
  Line3D(Image,muxyz,fixyz, 0,0,0,0,0,1,clBlue ,1,'Z');  {}

  //  три вектора локальных осей
  Line3D(Image,muxyz,fixyz,0,0,0,OXl[0],OXl[1],OXl[2],clRed,  3,'X');
  Line3D(Image,muxyz,fixyz,0,0,0,OYl[0],OYl[1],OYl[2],clGreen,3,'Y');
  Line3D(Image,muxyz,fixyz,0,0,0,OZl[0],OZl[1],OZl[2],clBlue, 3,'Z');

  //  три вектора локальных осей
  with oX1 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clRed,    3,'X');
  with oY1 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clGreen,  3,'Y');
  with oZ1 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clBlue,   3,'Z');
  //  три вектора локальных осей
  with oX2 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clRed,    3,'X');
  with oY2 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clGreen,  3,'Y');
  with oZ2 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clBlue,   3,'Z');
  //  три вектора локальных осей
  with oX3 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clRed,    3,'X');
  with oY3 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clGreen,  3,'Y');
  with oZ3 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clBlue,   3,'Z');
  //  три вектора локальных осей
  with q1 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clBlack,   1,'q1');
  with q2 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clBlack,   1,'q2');
  with q3 do Line3D(Image,muxyz,fixyz,0,0,0,x,y,z,clBlack,   1,'q3');
  {}

  //  проекция вектора гравитации на глобальные оси
  Line3D(Image,muxyz,fixyz,0,0,0,
    (-OXl[0]*AccFiltr[0]-OYl[0]*AccFiltr[1]+OZl[0]*AccFiltr[2])/gpiter,
    (-OXl[1]*AccFiltr[0]-OYl[1]*AccFiltr[1]+OZl[1]*AccFiltr[2])/gpiter,
    -(-OXl[2]*AccFiltr[0]-OYl[2]*AccFiltr[1]+OZl[2]*AccFiltr[2])/gpiter,
    clRed,  3,'G');
//  Line3D(Image,muxyz,fixyz,0,0,0,OYl[0],OYl[1],OYl[2],clGreen,3,'Y');
//  Line3D(Image,muxyz,fixyz,0,0,0,OZl[0],OZl[1],OZl[2],clBlue, 3,'Z');




  {Line3D(Image,muxyz,fixyz,0,0,0,ACC_XYZ[0]/gpiter,ACC_XYZ[1]/gpiter,ACC_XYZ[2]/gpiter,clBlue, 3,'rACC_XYZ');
  Line3D(Image,muxyz,fixyz,0,0,0,AccNorm[0],AccNorm[1],AccNorm[2],clBlue, 3,'GAcc');
  {
  rACC_XYZGL[0]:= rACC_XYZ[0]*OXl[0]+ rACC_XYZ[1]*OYl[0]- rACC_XYZ[2]*OZl[0];
  rACC_XYZGL[1]:= rACC_XYZ[0]*OXl[1]+ rACC_XYZ[1]*OYl[1]- rACC_XYZ[2]*OZl[1];
  rACC_XYZGL[2]:= rACC_XYZ[0]*OXl[2]+ rACC_XYZ[1]*OYl[2]- rACC_XYZ[2]*OZl[2];
  {}{
  rACC_XYZGL[0]:=-rACC_XYZGL[0]/gpiter;
  rACC_XYZGL[1]:=-rACC_XYZGL[1]/gpiter;
  rACC_XYZGL[2]:=-rACC_XYZGL[2]/gpiter;
  {}
//  Line3D(Image,muxyz,fixyz,0,0,0,DIST_XYZ[0],DIST_XYZ[1],DIST_XYZ[2],clAqua, 3,'W');
{}
end;

procedure TMainForm.TrackBar1Change(Sender: TObject);
var
  t:Single;
begin
  t:=TrackBar1.Position/100;

  q1  := TQuaternion.Create(TPoint3D.Create(1,0,1),-185*deg);
  q2  := TQuaternion.Create(TPoint3D.Create(0,1,1),50*deg);
  q3  := q3.Slerp(q1,q2,t);

  oX1:=q1*oX*q1.Inverse;
  oY1:=q1*oY*q1.Inverse;
  oZ1:=q1*oZ*q1.Inverse;

  oX2:=q2*oX*q2.Inverse;
  oY2:=q2*oY*q2.Inverse;
  oZ2:=q2*oZ*q2.Inverse;

  oX3:=q3*oX*q3.Inverse;
  oY3:=q3*oY*q3.Inverse;
  oZ3:=q3*oZ*q3.Inverse;

  redraw;
end;

procedure TMainForm.redraw;
begin
  redrawI(Image1,muxyz1,fixyz1);
  redrawI(Image2,muxyz2,fixyz2);
  redrawI(Image3,muxyz3,fixyz3);
  redrawI(Image4,muxyz4,fixyz4);


  OXl2.Caption:=FormatFloat('0.####',ArcSin(OXl[2])/deg);
  OYl2.Caption:=FormatFloat('0.####',ArcSin(OYl[2])/deg);
  OZl0.Caption:=FormatFloat('0.####',ArcSin(OZl[0])/deg);
  OZl1.Caption:=FormatFloat('0.####',ArcSin(OZl[1])/deg);

  AccFiltr0.Caption:='AccFiltrX '+FormatFloat('0.####',AccFiltr[0]);
  AccFiltr1.Caption:='AccFiltrY '+FormatFloat('0.####',AccFiltr[1]);
  AccFiltr2.Caption:='AccFiltrZ '+FormatFloat('0.####',AccFiltr[2]);

  iACC0.Caption:='iACCX '+inttostr(iACC[0]);
  iACC1.Caption:='iACCY '+inttostr(iACC[1]);
  iACC2.Caption:='iACCZ '+inttostr(iACC[2]);

  iGir0.Caption:='iGirX '+inttostr(iGir[0]);
  iGir1.Caption:='iGirY '+inttostr(iGir[1]);
  iGir2.Caption:='iGirZ '+inttostr(iGir[2]);


  GyroZeroFiltr0.Caption:='GZF '+FormatFloat('0.####',GyroZeroFiltr[0]);
  GyroZeroFiltr1.Caption:='GZF '+FormatFloat('0.####',GyroZeroFiltr[1]);
  GyroZeroFiltr2.Caption:='GZF '+FormatFloat('0.####',GyroZeroFiltr[2]);

  WAccFiltr0.Caption:='WAccFiltr '+FormatFloat('0.####',WAccFiltr[0]);
  WAccFiltr1.Caption:='WAccFiltr '+FormatFloat('0.####',WAccFiltr[1]);
  WAccFiltr2.Caption:='WAccFiltr '+FormatFloat('0.####',WAccFiltr[2]);

  pind0.Caption:=FormatFloat('0.####',pind[0]);
  pind1.Caption:=FormatFloat('0.####',pind[1]);
  pind2.Caption:=FormatFloat('0.####',pind[2]);

  Memo1.Lines.BeginUpdate;

  Memo1.Lines.Clear;

  Memo1.Lines.Add(FormatFloat('0.####',SPD_XYZ[0]));
  Memo1.Lines.Add(FormatFloat('0.####',SPD_XYZ[1]));
  Memo1.Lines.Add(FormatFloat('0.####',SPD_XYZ[2]));  {}

  Memo1.Lines.Add(FormatFloat('0.####',DIST_XYZ[0]));
  Memo1.Lines.Add(FormatFloat('0.####',DIST_XYZ[1]));
  Memo1.Lines.Add(FormatFloat('0.####',DIST_XYZ[2]));  {}

  Memo2.Lines.Add(FormatFloat('0.####',DIST_XYZ[0])+';'+
                  FormatFloat('0.####',DIST_XYZ[1])+';'+
                  FormatFloat('0.####',DIST_XYZ[2]));

  Memo1.Lines.EndUpdate;


  if GrafForm=nil then exit;

{  GrafForm.Series1.AddXY(ng,WAccFiltr[0]);
  GrafForm.Series2.AddXY(ng,WAccFiltr[1]);
  GrafForm.Series3.AddXY(ng,WAccFiltr[2]); {}

{  GrafForm.Series1.AddXY(ng,SPD_XYZ[0]);
  GrafForm.Series2.AddXY(ng,SPD_XYZ[1]);
  GrafForm.Series3.AddXY(ng,SPD_XYZ[2]);

  GrafForm.Series4.AddXY(ng,DIST_XYZ[0]);
  GrafForm.Series5.AddXY(ng,DIST_XYZ[1]);
  GrafForm.Series6.AddXY(ng,DIST_XYZ[2]);

  with GrafForm.Series1 do if count>40 then delete(0);
  with GrafForm.Series2 do if count>40 then delete(0);
  with GrafForm.Series3 do if count>40 then delete(0);
  with GrafForm.Series4 do if count>40 then delete(0);
  with GrafForm.Series5 do if count>40 then delete(0);
  with GrafForm.Series6 do if count>40 then delete(0);   {}

  inc(ng);
end;

procedure TMainForm.BtClosePortClick(Sender: TObject);
begin
  Port.free;
end;

procedure TMainForm.BtOpenPortClick(Sender: TObject);
begin
  Port := TComPort.Create(ComboCOM.ItemIndex, br115200);
  Port.OnRead := OnRead;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  GrafForm.Show;
end;

procedure TMainForm.Button2Click(Sender: TObject);

begin
  {интерполяция здесь
  //https://russianblogs.com/article/1756381934/
  https://www.youtube.com/redirect?event=video_description&redir_token=QUFFLUhqa3lQdi1pbXF6MHhBLUJyU2VjT1A0ZlhTaHNNd3xBQ3Jtc0ttM0pmZUl0RFlveDJCUWxoNzdSWUk3NXlud0p1UWF6VGN3QlFvMUhtRi1vVW9qai1YRHlqaGxFTlh1YkU1Y1NJUW1BNlRHY0FCbnBtRU05RWFqRWg0ZUlpbGlqRm96UmE0ZHFVRUtNTWVnVkVoeXF3bw&q=https%3A%2F%2Fgithub.com%2FEgoMoose%2FExampleDump%2Fblob%2Fmaster%2FScripts%2Fslerp.lua
  https://github.com/EgoMooseOldProjects/ExampleDump/blob/master/Scripts/slerp.lua
   {}

  q1  := TQuaternion.Create(TPoint3D.Create(0,0,1),5*deg);
  q2  := TQuaternion.Create(TPoint3D.Create(0,1,1),5*deg);
  q3  := TQuaternion.Create(TPoint3D.Create(1,1,1),5*deg);

  oX1:=q1*oX*q1.Inverse;
  oY1:=q1*oY*q1.Inverse;
  oZ1:=q1*oZ*q1.Inverse;

  oX2:=q2*oX*q2.Inverse;
  oY2:=q2*oY*q2.Inverse;
  oZ2:=q2*oZ*q2.Inverse;

  oX3:=q3*oX*q3.Inverse;
  oY3:=q3*oY*q3.Inverse;
  oZ3:=q3*oZ*q3.Inverse;

  redraw;
end;

end.




