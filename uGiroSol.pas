// расчет положения по данным гироскопа
// в реалтайме
unit uGiroSol;
interface

const
 deg = pi/180;
var
// единичные вектора локальных осей
// (проекция на глобальные оси)
 OXl,OYl,OZl,OXt,OYt,OZt,
  GyroZeroFiltr,      // сфильтрованное смещение ноля гироскопа  X Y Z
  GAcc,      // вектор гравитации с датчика ускорения     K L M
  GAccFiltr, // вектор гравитации с датчика ускорения фильтрованый  S Q T
  SPD,
  DIST,
  GGyro,       // вектор гравитации расчитаный с гироскопа  O P R
  GLF,       // вектор перпиндикуляр
  Zg,Xg {}: array [0..2] of double;
// должны выполняться условая перпендикулярности
// и суммы квадратов

// угловые скорости с гироскопа
 Wx,Wy,Wz    : array [0..2] of double;

// угол поворота на шаге интегрирования
 Fix,Fiy,Fiz    : array [0..2] of double;
 
 GirRun : boolean;

Procedure GiroInit;

procedure rotateI(a,b,g : double; fi:double);
procedure rotateG(a,b,g : double; fi:double);

procedure RotateW(wx,wy,wz:Smallint;t1:word);

implementation
uses SysUtils;

Function mCos(fi:real):real;
begin
result:= -0.499734*fi*fi + 1.000000;
end;

Function mSin(fi:real):real;
begin
result:=  0.999097*fi;
end;


Procedure GiroInit;
begin
// проекции локальных осей на глобальные
  OXl[0]:=1;  // проекция на X
  OXl[1]:=0;       // проекция на Y
  OXl[2]:=0;       // проекция на Z

  OYl[0]:=0;       // проекция на X
  OYl[1]:=1;       // проекция на Y
  OYl[2]:=0;       // проекция на Z


  OZl[0]:=0;       // проекция на X
  OZl[1]:=0;       // проекция на Y
  OZl[2]:=1;  // проекция на Z

  GAcc[0]:=0;
  GAcc[1]:=0;
  GAcc[2]:=-1;

  GGyro[0]:=0;
  GGyro[1]:=0;
  GGyro[2]:=-1;

// глобальная ось X
  Xg[0]:=1;  // проекция на X
  Xg[1]:=0;  // проекция на Y
  Xg[2]:=0;  // проекция на Z

// глобальная ось Z
  Zg[0]:=0;  // проекция на X
  Zg[1]:=0;  // проекция на Y
  Zg[2]:=1;  // проекция на Z


  GirRun:=false;
end;


// поворот осей OXl и OYl на угол
procedure rotateI(a,b,g : double; fi:double);
var
  x0,y0,z0:double;
  s,c,d:double;
  dab:double;
  da,db,dag,dbg,sg,sa,sb:double;
  k00,k01,k02,k10,k11,k12,k20,k21,k22 : double;
begin
  s:=sin(fi);
  c:=cos(fi);
  d:=1-c;

  da:=d*a;
  db:=d*b;
  dab:=da*b;
  dag:=da*g;
  dbg:=db*g;
  sg:=s*g;
  sa:=s*a;
  sb:=s*b;
  
  k00:=(c+da*a);  k01:=(-sg+dab);  k02:=(sb+dag);
  k10:=(sg+dab);  k11:=(c+db*b);   k12:=(-sa+dbg);
  k20:=(-sb+dag); k21:=(sa+dbg);   k22:=(c+d*g*g);

// повернули ось Х
  x0:=OXl[0];
  y0:=OXl[1];
  z0:=OXl[2];
  OXl[0]:=x0*k00+ y0*k01 + z0*k02;
  OXl[1]:=x0*k10+ y0*k11 + z0*k12;
  OXl[2]:=x0*k20+ y0*k21 + z0*k22;

// повернули ось Y
  x0:=OYl[0];
  y0:=OYl[1];
  z0:=OYl[2];
  OYl[0]:=x0*k00+ y0*k01 + z0*k02;
  OYl[1]:=x0*k10+ y0*k11 + z0*k12;
  OYl[2]:=x0*k20+ y0*k21 + z0*k22;

// повернули ось Z
  x0:=OZl[0];
  y0:=OZl[1];
  z0:=OZl[2];
  OZl[0]:=x0*k00+ y0*k01 + z0*k02;
  OZl[1]:=x0*k10+ y0*k11 + z0*k12;
  OZl[2]:=x0*k20+ y0*k21 + z0*k22;
  {}

end;

// поворот осей OXl и OYl на угол
procedure rotateG(a,b,g : double; fi:double);
var
  x0,y0,z0:double;
  s,c,d:double;
  dab:double;
  da,db,dag,dbg,sg,sa,sb:double;
  k00,k01,k02,k10,k11,k12,k20,k21,k22 : double;
begin
  s:=sin(fi);
  c:=cos(fi);
  d:=1-c;

  da:=d*a;
  db:=d*b;
  dab:=da*b;
  dag:=da*g;
  dbg:=db*g;
  sg:=s*g;
  sa:=s*a;
  sb:=s*b;
  
  k00:=(c+da*a);  k01:=(-sg+dab);  k02:=(sb+dag);
  k10:=(sg+dab);  k11:=(c+db*b);   k12:=(-sa+dbg);
  k20:=(-sb+dag); k21:=(sa+dbg);   k22:=(c+d*g*g);

// повернули ось Х
  x0:=GAcc[0];
  y0:=GAcc[1];
  z0:=GAcc[2];
  GAcc[0]:=x0*k00+ y0*k01 + z0*k02;
  GAcc[1]:=x0*k10+ y0*k11 + z0*k12;
  GAcc[2]:=x0*k20+ y0*k21 + z0*k22;

  {}

end;

var
  t0:word;

const
  k=deg*15/5000000;
procedure RotateW(wx,wy,wz:Smallint;t1:word);
var
 vx,vy,vz,d : double; // локальные
 gvx,gvy,gvz:double;
 dt:word;
begin
  if not GirRun then begin
    GirRun:=true;
    t0:=t1;
    exit;
  end;

  dt:=t1-t0;
  t0:=t1;
// расчет угла поворота
// 1. учет смещение ноля
   gvx:=wx- 7.438*0;
   gvy:=-wy+7.031*0;
   gvz:=-wz-2.437*0;
// 2. умножаем на время и на угловой коэфициент 2000 град в сек
   gvx:=gvx*dt*k;
   gvy:=gvy*dt*k;
   gvz:=gvz*dt*k;

// проекции угла поворота на глобальные оси
  vx:=gvx*OXl[0]+gvy*OYl[0]+gvz*OZl[0];
  vy:=gvx*OXl[1]+gvy*OYl[1]+gvz*OZl[1];
  vz:=gvx*OXl[2]+gvy*OYl[2]+gvz*OZl[2];

  gvx:=vx*vx;
  gvy:=vy*vy;
  gvz:=vz*vz;

  d:=sqrt(gvx+gvy+gvz);

  if d=0 then exit;

  vx:=vx/d;
  vy:=vy/d;
  vz:=vz/d;
  
  rotateI(vx,vy,vz,d);
//  rotateI(0.57735,0.57735,0.57735,0.01);


end;


end.