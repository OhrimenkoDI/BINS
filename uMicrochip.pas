unit uMicrochip;

interface
uses Math,SysUtils;

type
  DWORD=LongWord;

Function MCHPtoIEEE(a:LongWord):Single;
Function HextoInt(st:string):integer;
Function HexToSmInt(st:string):Smallint;

implementation


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
  if not IsNan(s) then
    result:=s;
end;


end.
 