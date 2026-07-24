unit uModelQ;

interface

uses uQuaternion;

var
  oX,oY,oZ : TQuaternion;  // оси
  oX3,oY3,oZ3 : TQuaternion;  // текущие оси платформы

  magVecLoc : TQuaternion;  // магнитный вектор локальный
  magVecWord : TQuaternion;  // магнитный вектор мировой

  GravVecLoc : TQuaternion;  // магнитный вектор локальный
  GravVecWord : TQuaternion;  // магнитный вектор мировой

  FQStart: TQuaternion;    // стартовый кватернион
  FQFin: TQuaternion;      // финальный кватернион
  FQTarget: TQuaternion;   // целевой кватернион   зависит от параметра например высоты




  QBodyDjo,QBNO055,QModel : TQuaternion;            // текущая ориентация

procedure qInit;


implementation

procedure qInit;
begin
  // Правая связанная система Body FRD:
  // oX = Forward (нос), oY = Right (правое крыло), oZ = Down (низ).
  with oX do begin
    ImagPart.x:=1;
    ImagPart.y:=0;
    ImagPart.z:=0;
    RealPart:=0;
  end;

  with oY do begin
    ImagPart.x:=0;
    ImagPart.y:=1;
    ImagPart.z:=0;
    RealPart:=0;
  end;

  with oZ do begin
    ImagPart.x:=0;
    ImagPart.y:=0;
    ImagPart.z:=1;
    RealPart:=0;
  end;

end;

end.
