program FhTicker;

uses
  Vcl.Forms,
  MainFrm in 'Source\MainFrm.pas' {MainFrame},
  Ticker in 'Source\Ticker.pas',
  NotificationUnit in 'Source\NotificationUnit.pas' {NotificationForm},
  Settings in 'Source\Settings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFrame, MainFrame);
  Application.Run;
end.
