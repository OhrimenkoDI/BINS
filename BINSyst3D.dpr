program BINSyst3D;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMainForm3D in 'uMainForm3D.pas' {MainForm3D};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm3D, MainForm3D);
  Application.Run;
end.
