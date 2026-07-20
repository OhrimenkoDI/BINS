unit uSolGiro;

interface
const
 deg = pi/180;
var
// единичные вектора локальных осей  х 30000
// (проекция на глобальные оси)
 OXl,OYl,OZl : array [0..2] of Integer;
// должны выполняться условая перпендикулярности
// и суммы квадратов

// угловые скорости с гироскопа
// за вычитом смещений с нуля
// максимум +-32768
 Wx,Wy,Wz    : array [0..2] of Smallint;

// угол поворота на шаге интегрирования
// Угловую скорость умножили на дельту таймера
// и Шыфтнули вправо до 32768 макс
 Fix,Fiy,Fiz    : array [0..2] of Integer;

Procedure GiroInit;
Procedure RorI(gvx,gvy,gvz:Smallint);
procedure rotateI(var x,y,z:integer; a,b,g : integer; fi:double);


implementation

Procedure GiroInit;
begin
// проекции локальных осей на глобальные
  OXl[0]:=65536;  // проекция на X
  OXl[1]:=0;       // проекция на Y
  OXl[2]:=0;       // проекция на Z

  OYl[0]:=0;       // проекция на X
  OYl[1]:=65536;  // проекция на Y
  OYl[2]:=0;       // проекция на Z

  OZl[0]:=0;       // проекция на X
  OZl[1]:=0;       // проекция на Y
  OZl[2]:=65536;  // проекция на Z
end;

procedure rotateI(var x,y,z:integer; a,b,g : integer; fi:double);
var
  x0,y0,z0 : integer;
  s,c,d    : double;
  xt,yt,zt : double;
  k:array[0..3,0..3] of double;
begin

  s:=(sin(deg*fi/4096)*65536);
  c:=(cos(deg*fi/4096)*65536);
  d:=65536-c;
  x0:=x;
  y0:=y;
  z0:=z;

  k[0,0]:=((c*65536*65536+d*a*a));
  k[0,1]:=((-s*g*65536+d*a*b));
  k[0,2]:=((s*b*65536+d*a*g));

  k[1,0]:=((s*g*65536+d*a*b));
  k[1,1]:=((c*65536*65536+d*b*b));
  k[1,2]:=((-s*a*65536+d*b*g));

  k[2,0]:=((-s*b*65536+d*a*g));
  k[2,1]:=((s*a*65536+d*b*g));
  k[2,2]:=((c*65536*65536+d*g*g));
 {
  k[0,0]:=(c+d*a*a);
  k[0,1]:=(-s*g+d*a*b);
  k[0,2]:=(s*b+d*a*g);

  k[1,0]:=(s*g+d*a*b);
  k[1,1]:=(c+d*b*b);
  k[1,2]:=(-s*a+d*b*g);

  k[2,0]:=(-s*b+d*a*g);
  k[2,1]:=(s*a+d*b*g);
  k[2,2]:=(c+d*g*g);  {}

xt:=x0*k[0,0]+   y0*k[0,1]+ z0*k[0,2];
yt:=x0*k[1,0]+   y0*k[1,1]+ z0*k[1,2];
zt:=x0*k[2,0]+   y0*k[2,1]+ z0*k[2,2];

x:=round(xt / (65536.0*65536.0*65536.0));
y:=round(yt / (65536.0*65536.0*65536.0));
z:=round(zt / (65536.0*65536.0*65536.0));{}
end;

Procedure RorI(gvx,gvy,gvz:Smallint);
var
 vx,vy,vz : Smallint; // локальные
 d:integer;
begin
{
// проекции угла поворота на глобальные оси
  vx:=gvx*OXl[0]+gvy*OYl[0]+gvz*OZl[0];
  vy:=gvx*OXl[1]+gvy*OYl[1]+gvz*OZl[1];
  vz:=gvx*OXl[2]+gvy*OYl[2]+gvz*OZl[2];

  d:=vx*vx+vy*vy+vz*vz;
  d:=round(sqrt(d));
  if d=0 then exit;

  vx:=vx div d;
  vy:=vy div d;
  vz:=vz div d;

// поворот в глобальной системе локальных осей
  rotateI(OXl[0],OXl[1],OXl[2],vx,vy,vz,d);
  rotateI(OYl[0],OYl[1],OYl[2],vx,vy,vz,d);
  rotateI(OZl[0],OZl[1],OZl[2],vx,vy,vz,d);
       {}
end;

end.

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// В ПИКе надо доделать Timer2 и умножать на
// реальное время при интегрировании

// Задача: Создать поддержку поворота
// вокруг произвольной оси на целых числах
// точную копию и сравнить результат для
// оценки точности (ожидаем 6 значащая цифра )
