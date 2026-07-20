program BINSyst;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uJoystick in 'uJoystick.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
