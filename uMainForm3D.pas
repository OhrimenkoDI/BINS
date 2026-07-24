unit uMainForm3D;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms3D, FMX.Types3D, FMX.Forms, FMX.Graphics, 
  FMX.Dialogs, System.Math.Vectors, FMX.Controls3D, FMX.Objects3D,
  FMX.OBJ.Importer, FMX.MaterialSources;

type
  TMainForm3D = class(TForm3D)
    Model3D1: TModel3D;
    Light1: TLight;
    LightMaterialSource1: TLightMaterialSource;
    StrokeCube1: TStrokeCube;
    procedure Form3DCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm3D: TMainForm3D;

implementation

{$R *.fmx}

procedure TMainForm3D.Form3DCreate(Sender: TObject);

  var
  Light: TLight;
  Material: TLightMaterialSource;
  i:integer;
begin

  if not Model3D1.LoadFromFile('Box055.obj') then
    raise Exception.Create('Ошибка загрузки OBJ');

  Model3D1.WrapMode := TMeshWrapMode.Fit;
  Model3D1.TwoSide := True;



  // 2. Создаем материал для контрастных граней
  Material := TLightMaterialSource.Create(nil);
  Material.Ambient := TAlphaColors.Darkgray; // Темный фоновый свет
  Material.Diffuse := TAlphaColors.White;    // Яркий основной цвет
  Material.Specular := TAlphaColors.White;   // Блики для контраста


  Model3D1.MeshCollection
  // 3. Назначаем материал модели
   // Проходим по всем сеткам, из которых состоит модель
  for i := 0 to Model3D1.MeshCollection.Count - 1 do
  begin
    // Назначаем материал каждой сетке
    Model3D1.MeshCollection[i].MaterialSource := MaterialSource;
  end;

end;

end;

end.
