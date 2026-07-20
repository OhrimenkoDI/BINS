unit uGrafForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  System.Math.Vectors;

type
  TGrafForm = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GrafForm: TGrafForm;

  q:TQuaternion3D;

implementation

{$R *.dfm}

procedure TGrafForm.Button1Click(Sender: TObject);
begin
Hide;
end;

end.
