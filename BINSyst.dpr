program BINSyst;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uJoystick in 'uJoystick.pas',
  uPowerGraphQuaternion in 'uPowerGraphQuaternion.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
