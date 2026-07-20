unit uModelQ;

interface

uses uQuaternion;

var
  oX,oY,oZ : TQuaternion;  // оси
  oX1,oY1,oZ1 : TQuaternion;  // оси
  oX2,oY2,oZ2 : TQuaternion;  // оси
  oX3,oY3,oZ3 : TQuaternion;  // оси
  q1,q2,q3 : TQuaternion;

procedure qInit;


implementation

procedure qInit;
begin

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
