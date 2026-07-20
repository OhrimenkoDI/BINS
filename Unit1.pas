unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls,uComPort,Math;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Image1: TImage;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Timer1: TTimer;
    ScrollBarX: TScrollBar;
    ScrollBarY: TScrollBar;
    ScrollBarZ: TScrollBar;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Button13: TButton;
    OpenDialog1: TOpenDialog;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
    Button14: TButton;
    Button15: TButton;
    ComboCOM: TComboBox;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Timer2: TTimer;
    Button16: TButton;
    Button17: TButton;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Button18: TButton;
    OpenDialog2: TOpenDialog;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    Label42: TLabel;
    Label43: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    GroupBox1: TGroupBox;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label32: TLabel;
    lRes: TLabel;
    Label33: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure ScrollBarXChange(Sender: TObject);
    procedure ScrollBarYChange(Sender: TObject);
    procedure ScrollBarZChange(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);

    procedure OnRead(Sender: TObject; ReadBytes: array of Byte);

    procedure Timer2Timer(Sender: TObject);
    procedure Button16Click(Sender: TObject);
    procedure Button17Click(Sender: TObject);
    procedure Button18Click(Sender: TObject);
    procedure Button15Click(Sender: TObject);
  private
    { Private declarations }
    Port: TComPort;
  public
    { Public declarations }
procedure RorW(gvx,gvy,gvz:Smallint;dt:word=0;rd:boolean=true);
    procedure Line3D(x1,y1,z1,x2,y2,z2:double;Color:TColor;Width:integer;st:string='');
    procedure init;
    procedure redraw;
  end;

var
  Form1: TForm1;

  type
 tGiro = record
   gx,gy,gz : Smallint;
   dt:dword;
 end;
var
  arGiro : array of tGiro;
  pos:integer;
  maxp:integer;

  ttime : word;  // время цикла
  ttemper : word;  //температура

  st:string;
    stp : string;
  cnt : integer;



implementation
uses uGiroSol;

{$R *.dfm}

const
 deg = pi/180;

// изометрия
 kx = 200;
 ky = 200;
 kz = 200;
 fix = -30;
 fiy = -150;
 fiz = 90; {}

// диметрия
{ kx = 200;
 ky = 0;
 kz = 200;
 fix = 0;
 fiy = 225;
 fiz = 90; {}

function hextoint(st:string):integer;
var i:integer;
ch:byte;
begin
st:=UpperCase(st);
i:=0;
while length(st)>0 do begin
ch:=byte(st[1]);
if ch>$39 then ch:=ch-7;
ch:=ch-$30;
if ch>$F then begin
                hextoint:=-1;
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



procedure rotate(var x,y,z:double; a,b,g : double; fi:double);
var
  x0,y0,z0:double;
  s,c,d:double;
begin
  s:=sin(fi);
  c:=cos(fi);
  d:=1-c;
  x0:=x;
  y0:=y;
  z0:=z;
x:=x0*(c+d*a*a)+   y0*(-s*g+d*a*b)+z0*(s*b+d*a*g);
y:=x0*(s*g+d*a*b)+ y0*(c+d*b*b)+   z0*(-s*a+d*b*g);
z:=x0*(-s*b+d*a*g)+y0*(s*a+d*b*g)+ z0*(c+d*g*g);
end;


function d2x(x,y,z:double):integer;
var
 h,w:integer;
begin
result:=0;
if abs(x)>5 then exit;
if abs(y)>5 then exit;
if abs(z)>5 then exit;

  w:=Form1.image1.Width;
  h:=Form1.image1.Height;
  result:=round(
          kx*x*cos(fix*deg)+
          ky*y*cos(fiy*deg)+
          kz*z*cos(fiz*deg))+w div 2;
end;

function d2y(x,y,z:double):integer;
var
 h,w:integer;
begin
result:=0;
if abs(x)>5 then exit;
if abs(y)>5 then exit;
if abs(z)>5 then exit;

  w:=Form1.image1.Width;
  h:=Form1.image1.Height;
  result:=-round(
          kx*x*sin(fix*deg)+
          ky*y*sin(fiy*deg)+
          kz*z*sin(fiz*deg))+h div 2;
end;



procedure TForm1.Line3D(x1,y1,z1,x2,y2,z2:double;Color:TColor;Width:integer;st:string='');
var
 x,y:integer;
begin
  Image1.Canvas.Pen.Color:=Color;
  Image1.Canvas.Pen.Width:=Width;
  x:=d2x(x1,y1,z1);
  y:=d2y(x1,y1,z1);
  Image1.Canvas.MoveTo(x,y);
  x:=d2x(x2,y2,z2);
  y:=d2y(x2,y2,z2);
  Image1.Canvas.LineTo(x,y);
  Image1.Canvas.TextOut(x,y,st);
end;


var
 dx,dy,dz : double;
 xx,yx,zx : double;
 xy,yy,zy : double;
 xz,yz,zz : double;

 tx,ty,tz : double;


procedure TForm1.redraw;
var
 z,c,a,d:double;
 a1,a2,a3:double;
begin
  Label4.Caption:=IntToStr(ScrollBarX.Position);
  Label5.Caption:=IntToStr(ScrollBarY.Position);
  Label6.Caption:=IntToStr(ScrollBarZ.Position);

  with image1.Canvas do FillRect(Rect(0,0,Width,Height));

  Line3D(0,0,0,1,0,0,clRed  ,1,'X');
  Line3D(0,0,0,0,1,0,clGreen,1,'Y');
  Line3D(0,0,0,0,0,1,clBlue ,1,'Z');


{  Line3D(dx,dy,dz,xx+dx,yx+dy,zx+dz,clRed,2,'X');
  Line3D(dx,dy,dz,xy+dx,yy+dy,zy+dz,clGreen,2,'Y');
  Line3D(dx,dy,dz,xz+dx,yz+dy,zz+dz,clBlue,2,'Z');{}

  Line3D(-dx,-dy,-dz,OXl[0]-dx,OXl[1]-dy,OXl[2]-dz,clRed,  3,'X');
  Line3D(-dx,-dy,-dz,OYl[0]-dx,OYl[1]-dy,OYl[2]-dz,clGreen,3,'Y');
  Line3D(-dx,-dy,-dz,OZl[0]-dx,OZl[1]-dy,OZl[2]-dz,clBlue, 3,'Z');

// вектор гравитации с датчика ускорения     K L M
//  Line3D(-dx,-dy,-dz,GAcc[0]-dx,GAcc[1]-dy,GAcc[2]-dz,clOlive, 3,'GAcc');

// вектор гравитации расчитаный с гироскопа  O P R
  Line3D(-dx,-dy,-dz,GGyro[0]-dx,GGyro[1]-dy,GGyro[2]-dz,clLime, 3,'GGyro');

// вектор гравитации с датчика ускорения фильтрованый  S Q T
//  Line3D(-dx,-dy,-dz,GAccFiltr[0]-dx,GAccFiltr[1]-dy,GAccFiltr[2]-dz,clMaroon, 3,'GAccFiltr');



  Line3D(tx,ty,tz,tx+0.1,ty+0.1,tz+0.1,clBlue  ,5,'Q');

{
  Label1.Caption:=FloatToStr(sqrt(sqr(xx)+sqr(yx)+sqr(zx)));
  Label2.Caption:=FloatToStr(sqrt(sqr(xy)+sqr(yy)+sqr(zy)));
  Label3.Caption:=FloatToStr(sqrt(sqr(xz)+sqr(yz)+sqr(zz)));{}

  Label1.Caption:=FloatToStr(sqrt(sqr(xx)+sqr(yx)+sqr(zx)));
  Label2.Caption:=FloatToStr(sqrt(sqr(xy)+sqr(yy)+sqr(zy)));
  Label3.Caption:=FloatToStr(sqrt(sqr(xz)+sqr(yz)+sqr(zz)));

// косинусы угла между осями
{
  Label8.Caption:=FloatToStr((xx*xy+yx*yy+zx*zy)/(sqrt(sqr(xx)+sqr(yx)+sqr(zx))*sqrt(sqr(xy)+sqr(yy)+sqr(zy))));
  Label9.Caption:=FloatToStr((xx*xz+yx*yz+zx*zz)/(sqrt(sqr(xx)+sqr(yx)+sqr(zx))*sqrt(sqr(xz)+sqr(yz)+sqr(zz))));
 Label10.Caption:=FloatToStr((xz*xy+yz*yy+zz*zy)/(sqrt(sqr(xz)+sqr(yz)+sqr(zz))*sqrt(sqr(xy)+sqr(yy)+sqr(zy))));
 {}
{  Label8.Caption:=FloatToStr((xx*xy+yx*yy+zx*zy)/(sqrt(sqr(xx)+sqr(yx)+sqr(zx))*sqrt(sqr(xy)+sqr(yy)+sqr(zy))));
  Label9.Caption:=FloatToStr((xx*xz+yx*yz+zx*zz)/(sqrt(sqr(xx)+sqr(yx)+sqr(zx))*sqrt(sqr(xz)+sqr(yz)+sqr(zz))));
 Label10.Caption:=FloatToStr((xz*xy+yz*yy+zz*zy)/(sqrt(sqr(xz)+sqr(yz)+sqr(zz))*sqrt(sqr(xy)+sqr(yy)+sqr(zy))));{}

  z:=(sqrt(sqr(xy)+sqr(yy)+sqr(zy))*sqrt(sqr(OXl[0])+sqr(OXl[1])+sqr(OXl[2])));
if z<>0 then begin
    c:=(xy*OXl[0]+yy*OXl[1]+zy*OXl[2])/z;
    a:=ArcCos(c)/pi*180;
    Label8.Caption:=FloatToStr(c);
    Label11.Caption:=FloatToStr(a);
end;

  z:=(sqrt(sqr(xy)+sqr(yy)+sqr(zy))*sqrt(sqr(OYl[0])+sqr(OYl[1])+sqr(OYl[2])));
if z<>0 then begin
    c:=(xy*OYl[0]+yy*OYl[1]+zy*OYl[2])/z;
    a:=ArcCos(c)/pi*180;
    Label9.Caption:=FloatToStr(c);
    Label12.Caption:=FloatToStr(a);
end;

  z:=(sqrt(sqr(xy)+sqr(yy)+sqr(zy))*sqrt(sqr(OZl[0])+sqr(OZl[1])+sqr(OZl[2])));
if z<>0 then begin
    c:=(xy*OZl[0]+yy*OZl[1]+zy*OZl[2])/z;
    a:=ArcCos(c)/pi*180;
    Label10.Caption:=FloatToStr(c);
    Label13.Caption:=FloatToStr(a);
end;


{Memo1.Clear;
 Memo1.Lines.Add(format('%7f; %7f; %7f;',[xx,yx,zx]));
 Memo1.Lines.Add(format('%7f; %7f; %7f;',[xy,yy,zy]));
 Memo1.Lines.Add(format('%7f; %7f; %7f;',[xz,yz,zz]));
 Memo1.Lines.Add('----------');
 Memo1.Lines.Add(format('%7f; %7f; %7f;',[OXl[0],OXl[1],OXl[2]]));
 Memo1.Lines.Add(format('%7f; %7f; %7f;',[Oyl[0],OYl[1],OYl[2]]));
 Memo1.Lines.Add(format('%7f; %7f; %7f;',[Ozl[0],OZl[1],OZl[2]]));{}

 // косинусы угла между подвижными осями
 d:=(sqrt(sqr(OXl[0])+sqr(OXl[1])+sqr(OXl[2]))*sqrt(sqr(OYl[0])+sqr(OYl[1])+sqr(OYl[2])));
 if d>0 then
  Label14.Caption:=FormatFloat('0.############',abs(1000000*(OXl[0]*OYl[0]+OXl[1]*OYl[1]+OXl[2]*OYl[2])/d));

 d:=(sqrt(sqr(OZl[0])+sqr(OZl[1])+sqr(OZl[2]))*sqrt(sqr(OYl[0])+sqr(OYl[1])+sqr(OYl[2])));
 if d>0 then
  Label15.Caption:=FormatFloat('0.############',abs(1000000*(OZl[0]*OYl[0]+OZl[1]*OYl[1]+OZl[2]*OYl[2])/d));

 d:=(sqrt(sqr(OXl[0])+sqr(OXl[1])+sqr(OXl[2]))*sqrt(sqr(OZl[0])+sqr(OZl[1])+sqr(OZl[2])));
 if d>0 then
  Label16.Caption:=FormatFloat('0.############',abs(1000000*(OXl[0]*OZl[0]+OXl[1]*OZl[1]+OXl[2]*OZl[2])/d));


//нормальность
  Label17.Caption:=FormatFloat('0.#########',
  (sqrt(sqr(OXl[0])+sqr(OXl[1])+sqr(OXl[2]))));

  Label18.Caption:=FormatFloat('0.#########',
  (sqrt(sqr(OYl[0])+sqr(OYl[1])+sqr(OYl[2]))));

  Label19.Caption:=FormatFloat('0.#########',
  (sqrt(sqr(OZl[0])+sqr(OZl[1])+sqr(OZl[2]))));

//Среднее смещение ноля на гироскопе
  Label20.Caption:='Wx: '+FormatFloat('0.#########',GyroZeroFiltr[0]);

  Label21.Caption:='Wy: '+FormatFloat('0.#########',GyroZeroFiltr[1]);

  Label22.Caption:='Wz: '+FormatFloat('0.#########',GyroZeroFiltr[2]);


// вектор гравитации с датчика ускорения чистый  K L M
  Label29.Caption:=FormatFloat('0.###',{ArcSin}(GAcc[0]){/deg});

  Label30.Caption:=FormatFloat('0.###',{ArcSin}(GAcc[1]){/deg});

  Label31.Caption:=FormatFloat('0.###',{ArcSin}(GAcc[2]){/deg});

{  lRes.Caption:=FormatFloat('0.###',ArcTan2(
  sqrt(sqr(GAcc[0])+sqr(GAcc[1])),-GAcc[2])/deg);{}


  // интеграл ускорения - скорость
  Label39.Caption:=FormatFloat('0.###',SPD[0]);

  Label40.Caption:=FormatFloat('0.###',SPD[1]);

  Label41.Caption:=FormatFloat('0.###',SPD[2]);

  // интеграл скорости - путь
  Label23.Caption:=FormatFloat('0.###',DIST[0]);

  Label24.Caption:=FormatFloat('0.###',DIST[1]);

  Label25.Caption:=FormatFloat('0.###',DIST[2]);





// углы X Y в
  Label27.Caption:=FormatFloat('0.###',Tan(ArcSin(GAccFiltr[0]))*1000)+' мм/м';

  Label28.Caption:=FormatFloat('0.###',Tan(ArcSin(GAccFiltr[1]))*1000)+' мм/м';

// время цикла
  Label26.Caption:='Время цыкла '+FormatFloat('0.',ttime);

  // время цикла
  Label33.Caption:='Температура '+FormatFloat('0.',ttemper);




end;

procedure TForm1.ScrollBarXChange(Sender: TObject);
begin
  redraw;
end;

procedure TForm1.ScrollBarYChange(Sender: TObject);
begin
  redraw;
end;

procedure TForm1.ScrollBarZChange(Sender: TObject);
begin
  redraw;
end;
var
n:byte;
procedure TForm1.Timer1Timer(Sender: TObject);
var
 b:integer;
begin
if maxp=-1 then begin
 RorW(ScrollBarX.Position,
      ScrollBarY.Position,
      ScrollBarZ.Position);
 exit;
end;{}
{if pos<maxp then begin
  RorW(arGiro[pos].gx,arGiro[pos].gy,arGiro[pos].gz,arGiro[pos].dt);
  inc(n);
  inc(pos);
end;

{
b:=round(random*5);
  case b of
    0:Button2.Click;
    1:Button3.Click;
    2:Button4.Click;
    3:Button5.Click;
    4:Button6.Click;
    5:Button7.Click;
  end;{}
end;

procedure TForm1.Button10Click(Sender: TObject);
begin
  ScrollBarX.Position:=0;
end;

procedure TForm1.Button11Click(Sender: TObject);
begin
  ScrollBarY.Position:=0;
end;

procedure TForm1.Button12Click(Sender: TObject);
begin
  ScrollBarZ.Position:=0;
end;
//*****************************

//*****************************
procedure TForm1.Button13Click(Sender: TObject);
var
 fn:TFileName;
 stl:TStringList;
 i,j: integer;
 st:string;
 t0,t1,dt:dword;
begin
  if not OpenDialog1.Execute then exit;
  fn:=OpenDialog1.FileName;
  stl:=TStringList.Create;
  stl.LoadFromFile(fn);
  i:=0;
  j:=0;
  t0:=0;
  t1:=0;
  SetLength(arGiro,stl.Count);
  while i<stl.Count do begin
    st:=stl.Strings[i];
    if copy(st,1,6)='Girosc' then begin
      arGiro[j].gz:=HexToSmInt(copy(st, 7,4));
      arGiro[j].gx:=HexToSmInt(copy(st,11,4));
      arGiro[j].gy:=HexToSmInt(copy(st,15,4));
      t1:=hextoint(copy(st,19,8));
      arGiro[j].dt:=word(t1);
      t0:=t1;
      inc(j);
    end;
    inc(i);
  end;
  SetLength(arGiro,j);
  maxp:=j;
  pos:=0;

  stl.free;
  Memo1.Lines.Add('Girosc - '+inttostr(j));
  Memo1.Lines.BeginUpdate;
  for i := 0 to j - 1 do
    Memo1.Lines.Add(format('%5d; %7d; %7d; %7d; %7d;',[i,arGiro[i].gx,arGiro[i].gy,arGiro[i].gz,arGiro[i].dt and $FFFFFF]));
  Memo1.Lines.EndUpdate;
  Memo1.Lines.SaveToFile('D:\Docum\2013-ODI\programs\3DGraf\Data\Temp\temp.lst');


end;

procedure TForm1.Button14Click(Sender: TObject);
begin
  st:='';
  Port := TComPort.Create(ComboCOM.ItemIndex, br115200);
  Port.OnRead := OnRead;
  Timer1.Enabled:=true;
end;

procedure TForm1.Button15Click(Sender: TObject);
begin
  Port.free;
  Timer1.Enabled:=False;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  redraw;
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  init;
end;

procedure TForm1.Button9Click(Sender: TObject);
var
 b:integer;
begin
  b:=0;
while pos<maxp do begin
  RorW(arGiro[pos].gx,arGiro[pos].gy,arGiro[pos].gz,0,false);
  inc(pos);
  inc(b);
  if (b mod 1000)=0 then begin
    Label7.Caption:=IntToStr(pos);
    redraw;
    Application.ProcessMessages;
  end;
end;
  Label7.Caption:=IntToStr(pos);
  redraw;
end;


procedure TForm1.RorW(gvx,gvy,gvz:Smallint;dt:word=0;rd:boolean=true);
var
 vx,vy,vz,d : double; // локальные
begin

  RotateW(gvx,gvy,gvz,dt);

  tx:=tx+OXl[0]*0.001;
  ty:=ty+OXl[1]*0.001;
  tz:=tz+OXl[2]*0.001;

{
// расчет угла поворота
// 1. учет смещение ноля
   gvx:=gvx-7.438;
   gvy:=gvy+7.031;
   gvz:=gvz-2.437;
// 2. умножаем на время
   gvx:=gvx*dt/5000000;
   gvy:=gvy*dt/5000000;
   gvz:=gvz*dt/5000000;
// 3. умножаем на укловой коэфициент 2000 град в сек
   gvx:=gvx*deg*390;
   gvy:=gvy*deg*390;
   gvz:=gvz*deg*390;

// проекции угла поворота на глобальные оси
  vx:=gvx*xx+gvy*xy+gvz*xz;
  vy:=gvx*yx+gvy*yy+gvz*yz;
  vz:=gvx*zx+gvy*zy+gvz*zz;

  d:=sqrt(sqr(vx)+sqr(vy)+sqr(vz));
  if d=0 then exit;

  vx:=vx/d;
  vy:=vy/d;
  vz:=vz/d;

// поворот в глобальной системе
  rotate(xx,yx,zx,vx,vy,vz,d*deg/100);
  rotate(xy,yy,zy,vx,vy,vz,d*deg/100);
  rotate(xz,yz,zz,vx,vy,vz,d*deg/100);

          {}
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 i:integer;
begin
  Form1.DoubleBuffered:=true;
  init;
  redraw;
  Memo1.Clear;
  GiroInit;

for i:=0 to 10 do
  ComboCOM.Items.Add('COM'+inttostr(i));
ComboCOM.ItemIndex:=2;
// Button14.Click;
end;


procedure TForm1.init;
begin
 maxp:=-1;

  dx:=0;
  dy:=0;
  dz:=0;

  xx:=1;    yx:=0;     zx:=0;  // определяет ось X
  xy:=0;    yy:=1;     zy:=0;  // определяет ось Y
  xz:=0;    yz:=0;     zz:=1;  // определяет ось Z

  tx:=0;
  ty:=0;
  tz:=0;

  GiroInit;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  rotateI(OYl[0],OYl[1],OYl[2],5*deg);

  rotate(xx,yx,zx,xy,yy,zy,5*deg);

  rotate(xz,yz,zz,xy,yy,zy,5*deg);

  redraw;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  rotateI(OXl[0],OXl[1],OXl[2],5*deg);{}

//  rotate(xy,yy,zy,xx,yx,zx,5*deg);
//  rotate(xz,yz,zz,xx,yx,zx,5*deg);
  redraw;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  rotateI(OXl[0],OXl[1],OXl[2],-5*deg);{}

  rotate(xy,yy,zy,xx,yx,zx,-5*deg);
  rotate(xz,yz,zz,xx,yx,zx,-5*deg);

  redraw;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  rotateI(OYl[0],OYl[1],OYl[2],-5*deg);

  rotate(xx,yx,zx,xy,yy,zy,-5*deg);
  rotate(xz,yz,zz,xy,yy,zy,-5*deg);
  redraw;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  rotateI(OZl[0],OZl[1],OZl[2],5*deg);

  rotate(xx,yx,zx,xz,yz,zz,5*deg);
  rotate(xy,yy,zy,xz,yz,zz,5*deg);
  redraw;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  rotateI(OZl[0],OZl[1],OZl[2],-5*deg);

  rotate(xx,yx,zx,xz,yz,zz,-5*deg);
  rotate(xy,yy,zy,xz,yz,zz,-5*deg);
  redraw;
end;


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
    Form1.Memo1.Lines.Add(FloatToStr(s));
    Form1.Memo1.Lines.Add(IntToHex(a,8))
  end
  else
    result:=s;
end;


var
  kbufer : array[0..9] of char;


procedure shbuf;
var
  i:integer;
begin
  for i:= 0 to 8 do
    kbufer[i]:=kbufer[i+1];
end;

procedure TForm1.OnRead(Sender: TObject; ReadBytes: array of Byte);
var
 i:integer;
 dw:dword;
 sm:Smallint;
 w:word;
 st:string;
begin
//  FillChar(kbufer,sizeof(kbufer),0);
  for i := Low(ReadBytes) to High(ReadBytes) do
  begin
    if (ReadBytes[i]>=byte('0'))or(ReadBytes[i]=13) then begin
      shbuf;
      kbufer[9]:=char(ReadBytes[i]);
      st:=copy(kbufer,1,10);
      if kbufer[0]=#13 then
        case kbufer[1] of
          'A' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  OXt[0]:=MCHPtoIEEE(dw);
                end;
          'B' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  OXt[1]:=MCHPtoIEEE(dw);
                end;
          'C' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  OXt[2]:=MCHPtoIEEE(dw);
                end;
/////////////////////////////////////////////////////////
          'D' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  OYt[0]:=MCHPtoIEEE(dw);
                end;
          'E' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  OYt[1]:=MCHPtoIEEE(dw);
                end;
          'F' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  OYt[2]:=MCHPtoIEEE(dw);
                end;
//////////////////////////////////////////////////////////
          'G' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  OZt[0]:=MCHPtoIEEE(dw);
                end;
          'I' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  OZt[1]:=MCHPtoIEEE(dw);
                end;
          'J' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  OZt[2]:=MCHPtoIEEE(dw);
                end;
////////////////////////////////////////////////////////
// среднее смещение ноля на гироскопе
          'X' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  GyroZeroFiltr[0]:=MCHPtoIEEE(dw);
                end;
          'Y' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  GyroZeroFiltr[1]:=MCHPtoIEEE(dw);
                end;
          'Z' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  GyroZeroFiltr[2]:=MCHPtoIEEE(dw);

                  OXl:=OXt;
                  OYl:=OYt;
                  OZl:=OZt;
                end;
//////////////////////////////////////////////////////////
// вектор гравитации с датчика ускорения
          'K' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  GAcc[0]:=MCHPtoIEEE(dw);
                end;
          'L' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  GAcc[1]:=MCHPtoIEEE(dw);
                end;
          'M' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  GAcc[2]:=MCHPtoIEEE(dw);
                end;
/////////////////////////////////////////////////////////////
// вектор гравитации расчитаный с гироскопа
          'O' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  GGyro[0]:=MCHPtoIEEE(dw);
                end;
          'P' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  GGyro[1]:=MCHPtoIEEE(dw);
                end;

          'R' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  GGyro[2]:=MCHPtoIEEE(dw);
                end;
/////////////////////////////////////////////////////////////
          // вектор гравитации расчитаный с гироскопа
          'S' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  SPD[0]:=MCHPtoIEEE(dw);
                end;
          'Q' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  SPD[1]:=MCHPtoIEEE(dw);
                end;

          'T' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  SPD[2]:=MCHPtoIEEE(dw);
                end;
          // скорости
          's' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  DIST[0]:=MCHPtoIEEE(dw);
                end;
          'q' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  DIST[1]:=MCHPtoIEEE(dw);
                end;

          't' : begin
                  dw:=hextoint(copy(kbufer,3,8));
                  DIST[2]:=MCHPtoIEEE(dw);
                end;
/////////////////////////////////////////////////////////////////

          'W' : begin
                  w:=hextoint(copy(kbufer,3,8));
                  ttime:=w;
                  redraw;
                end;

          'V' : begin
                  w:=hextoint(copy(kbufer,3,8));
                  ttemper:=w;
                  redraw;
                end;


        end;
    end;
    end;
end;

var
nom:integer;
rNorma,d1:double;

procedure TForm1.Timer2Timer(Sender: TObject);

begin
inc(nom);
if nom>=6 then nom:=1;

 RorW(ScrollBarX.Position,
      ScrollBarY.Position,
      ScrollBarZ.Position,round(now*24*60*60*100000));

 { Gr[0]:= OXl[2];
  Gr[1]:= OYl[2];
  Gr[2]:=-OZl[2];   {}



      redraw;
      exit;

 { G0[0]:=1;
  G0[1]:=1.2;
  G0[2]:=0.5;

// вектор гравитации
   { G[0]:=-iACC_X;
    G[1]:=-iACC_Y;
    G[2]:=-iACC_Z;

    rNorma:=sqrt(G[0]*G[0]+G[1]*G[1]+G[2]*G[2]);
    if rNorma>0 then begin
      G[0]:=G[0]/rNorma;
      G[1]:=G[1]/rNorma;
      G[2]:=G[2]/rNorma;
    end;

// 2. Перпендикулярная ось вращения
    pind[0] := OZl[1] * G[2] - OZl[2] * G[1];
    pind[1] := OZl[2] * G[0] - OZl[0] * G[2];
    pind[2] := OZl[0] * G[1] - OZl[1] * G[0];

// 3. Вращаем
    rotateI(pind[0], pind[1],  pind[2],  0.001);{}

// 4. Нормализуем OZl
    rNorma:=0.5+0.5*(OZl[0]*OZl[0]+OZl[1]*OZl[1]+OZl[2]*OZl[2]);
    if rNorma>0 then begin
      OZl[0]:=OZl[0]/rNorma;
      OZl[1]:=OZl[1]/rNorma;
      OZl[2]:=OZl[2]/rNorma;
    end;
    
// 5. Перпендикулируем ось OXl
  OXl[0] := OYl[1] * OZl[2] - OYl[2] * OZl[1];
  OXl[1] := OYl[2] * OZl[0] - OYl[0] * OZl[2];
  OXl[2] := OYl[0] * OZl[1] - OYl[1] * OZl[0];

// 6. Нормализуем OXl
    rNorma:=0.5+0.5*(OXl[0]*OXl[0]+OXl[1]*OXl[1]+OXl[2]*OXl[2]);
    if rNorma>0 then begin
      OXl[0]:=OXl[0]/rNorma;
      OXl[1]:=OXl[1]/rNorma;
      OXl[2]:=OXl[2]/rNorma;
    end;
    
// 7. Перпендикулируем ось OYl
  OYl[0] := OZl[1] * OXl[2] - OZl[2] * OXl[1];
  OYl[1] := OZl[2] * OXl[0] - OZl[0] * OXl[2];
  OYl[2] := OZl[0] * OXl[1] - OZl[1] * OXl[0]; {}


 redraw;

end;

procedure TForm1.Button16Click(Sender: TObject);
begin
  rotateI(0,  1,  0,  5*deg);{}
end;

procedure TForm1.Button17Click(Sender: TObject);
var
  d:double;
begin
  OYt[0]:=OYl[0]-0.267;
  OYt[1]:=0;
  OYt[2]:=OYl[2]-0.534;

 begin
  d:=sqrt(sqr(OYt[0])+sqr(OYt[1])+sqr(OYt[2]));
  if d=0 then exit;
  OYt[0]:=OYt[0]/d;
  OYt[1]:=OYt[1]/d;
  OYt[2]:=OYt[2]/d; {}
end;

  rotateI(-OYt[0],  OYt[1],  -OYt[2],  0.01*d);{}

  redraw;
end;

procedure TForm1.Button18Click(Sender: TObject);
var
  arrBytes: array of Byte;
  str:TMemoryStream;
  fn:tfilename;
begin
  If not OpenDialog1.Execute then exit;
  fn:=OpenDialog1.FileName;

  str:=TMemoryStream.Create;
  str.LoadFromFile(fn);
  SetLength(arrBytes, str.size);
  str.Read(arrBytes[0],str.size);
  OnRead(self,arrBytes);
  str.Free;

end;

end.

// определить функции пересчета трех мерных
// координат на плоскость с центром в середине экрана.
// Для начала это изометрия 120 градусов
// с kx,ky,kz = 1.0

// Заданы угловые скорости по осям
// Вращать объект

// Загрузить данные из файла и подставлять их
// по очереди

// подключаем модуль COM
// пропускае данные через кольцо
// пишем во временные переменные
// при получение Z2 делаем рефриш
