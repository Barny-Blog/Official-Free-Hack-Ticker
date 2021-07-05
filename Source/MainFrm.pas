unit MainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Ticker, StrUtils, System.RegularExpressions, NotificationUnit,
  Vcl.ExtCtrls, Vcl.Menus, Vcl.AppEvnts,Settings;

type
  TMainFrame = class(TForm)
    gbStatus: TGroupBox;
    btnLogin: TButton;
    edUsername: TEdit;
    lblUsername: TLabel;
    edPassword: TEdit;
    lblPassword: TLabel;
    lblStatus: TLabel;
    lblStatusTitle: TLabel;
    tmUpdate: TTimer;
    gbOptions: TGroupBox;
    triIcon: TTrayIcon;
    mnuPopMenu: TPopupMenu;
    apeMinimize: TApplicationEvents;
    cbxSavePassword: TCheckBox;
    btnMinimize: TButton;
    lblCredits: TLabel;
    mniRepeatLast: TMenuItem;
    mniSettings: TMenuItem;
    mniClose: TMenuItem;
    cbxAutomaticLogin: TCheckBox;
    cbxShowShoutboxmessages: TCheckBox;
    procedure btnLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tmUpdateTimer(Sender: TObject);
    procedure triIconClick(Sender: TObject);
    procedure triIconMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure apeMinimizeMinimize(Sender: TObject);
    procedure btnMinimizeClick(Sender: TObject);
    procedure mniCloseClick(Sender: TObject);
    procedure mniSettingsClick(Sender: TObject);
    procedure mniRepeatLastClick(Sender: TObject);
    procedure cbxSavePasswordClick(Sender: TObject);
    procedure edUsernameExit(Sender: TObject);
    procedure edPasswordExit(Sender: TObject);
    procedure cbxAutomaticLoginClick(Sender: TObject);
    procedure cbxShowShoutboxmessagesClick(Sender: TObject);
    procedure apeMinimizeSettingChange(Sender: TObject; Flag: Integer;
      const Section: string; var Result: Integer);
  private
    fTicker : TTicker;
    fSendNotification : TSendNotification;
    fCheckLoginCounter : Integer;
    function IsWorkstationLocked: Boolean;
  public
    { Public declarations }
  end;

  TWaiting = class(TThread)
  private
    fTicker: TTicker;
    fSendNotification: TSendNotification;
    fLast10,
    fCHeckLogin : Boolean;

    procedure SendNotifications(aShowShoutboxMessages : Boolean);
  public
    constructor Create(aTicker: TTicker; aLast10: Boolean; aSendNotification: TSendNotification; aCheckLogin : Boolean);
    procedure Execute; override;
  end;

var
  MainFrame: TMainFrame;

const
  cLoggedIn = 'Angemeldet als: ';
  cNotLoggedIn = 'Nicht angemeldet';
  cLogIn = 'Anmelden';
  cLogOut = 'Abmelden';
  cLoginError = 'Fehler bei der Anmeldung!';
  cLostConnection = 'Verbindung verloren';

implementation

{$R *.dfm}

procedure TMainFrame.apeMinimizeMinimize(Sender: TObject);
begin
  Hide;
  WindowState := wsMinimized;
end;

procedure TMainFrame.apeMinimizeSettingChange(Sender: TObject; Flag: Integer;
  const Section: string; var Result: Integer);
begin
  if not IsWorkstationLocked then begin
    fSendNotification.Free;
    fSendNotification := TSendNotification.Create(Self);
  end;
end;

procedure TMainFrame.btnLoginClick(Sender: TObject);
begin
  if btnLogin.Caption = cLogIn then begin
    fTicker := TTicker.Create(edUsername.Text,edPassword.Text);
    edUsername.Enabled := false;
    edPassword.Enabled := false;
    if fTicker.login then begin
      tmUpdate.Enabled := true;
      lblStatus.Caption := cLoggedIn+fTicker.Username;
      lblStatus.Font.Color := clGreen;
      btnLogin.Caption := cLogOut;
      edUsername.Enabled := false;
      edPassword.Enabled := false;
      TWaiting.Create(fTicker,False,fSendNotification,false);
      Inc(fCheckLoginCounter);
    end else begin
      lblStatus.Caption := cLoginError;
      lblStatus.Font.Color := clRed;
      btnLogin.Caption := cLogIn;
      tmUpdate.Enabled := false;
      edUsername.Enabled := true;
      edPassword.Enabled := true;
    end;
  end else begin
    fTicker.Free;
    lblStatus.Caption := cNotLoggedIn;
    lblStatus.Font.Color := clRed;
    btnLogin.Caption := cLogIn;
    tmUpdate.Enabled := false;
    edUsername.Enabled := true;
    edPassword.Enabled := true;
  end;
end;

procedure TMainFrame.btnMinimizeClick(Sender: TObject);
begin
  Hide;
  WindowState := wsMinimized;
end;

procedure TMainFrame.cbxAutomaticLoginClick(Sender: TObject);
var
  Settings : TSettings;
begin
  Settings := TSettings.Create;
  try
    Settings.AutomaticLogin := cbxAutomaticLogin.Checked;
    Settings.SaveSettings;
  finally
    Settings.Free;
  end;

end;

procedure TMainFrame.cbxSavePasswordClick(Sender: TObject);
var
  Settings : TSettings;
begin
  Settings := TSettings.Create;
  try
    Settings.SavePassword := cbxSavePassword.Checked;
    if not cbxSavePassword.Checked then begin
      Settings.Username := '0';
      Settings.Password := '0';
      cbxAutomaticLogin.Checked := false;
      cbxAutomaticLogin.Enabled := false;
      Settings.AutomaticLogin := false;
    end else begin
      cbxAutomaticLogin.Enabled := true;
      if (edPassword.Text <> '') and (edUsername.Text <> '') then begin
        Settings.Username := edUsername.Text;
        Settings.Password := edPassword.Text;
      end;
    end;
    Settings.SaveSettings;
  finally
    Settings.Free;
  end;
end;

procedure TMainFrame.cbxShowShoutboxmessagesClick(Sender: TObject);
var
  Settings : TSettings;
begin
  Settings := TSettings.Create;
  try
    Settings.ShowShoutboxmessages := cbxShowShoutboxmessages.Checked;
    Settings.SaveSettings;
  finally
    Settings.Free;
  end;
end;

procedure TMainFrame.edPasswordExit(Sender: TObject);
var
  Settings : TSettings;
begin
  if (cbxSavePassword.Checked) and (edPassword.Text <> '')then begin
    Settings := TSettings.Create;
    try
      Settings.Password := edPassword.Text;
      Settings.SaveSettings;
    finally
      Settings.Free;
    end;
  end;
end;

procedure TMainFrame.edUsernameExit(Sender: TObject);
var
  Settings : TSettings;
begin
  if (cbxSavePassword.Checked) and (edUsername.Text <> '') then begin
    Settings := TSettings.Create;
    try
      Settings.Username := edUsername.Text;
      Settings.SaveSettings;
    finally
      Settings.Free;
    end;
  end;
end;

procedure TMainFrame.FormCreate(Sender: TObject);
var
  Settings : TSettings;
begin
  lblStatus.Font.Color := clRed;
  fSendNotification := TSendNotification.Create(Self);
  fCheckLoginCounter := 0;
  triIcon.Visible := True;
  Settings := TSettings.Create;
  try
    cbxShowShoutboxmessages.Checked := Settings.ShowShoutboxmessages;
    cbxSavePassword.Checked := Settings.SavePassword;
    if cbxSavePassword.Checked then begin
      if (Settings.Username <> '0') and (Settings.Password <> '')then begin
        edUsername.Text := Settings.Username;
        edPassword.Text := Settings.Password;
      end;
      cbxAutomaticLogin.Checked := Settings.AutomaticLogin;
    end else
      cbxAutomaticLogin.Enabled := cbxSavePassword.Checked;
  finally
    Settings.Free;
  end;

  if ((edUsername.Text <> '') and (edPassword.Text <> '')) and (cbxAutomaticLogin.Checked) then begin
    btnLogin.Click;
    Hide;
    WindowState := wsMinimized;
  end;
end;

procedure TMainFrame.mniCloseClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TMainFrame.mniRepeatLastClick(Sender: TObject);
begin
  TWaiting.Create(fTicker, True,fSendNotification,false);
end;

procedure TMainFrame.mniSettingsClick(Sender: TObject);
begin
  if Visible then begin
    WindowState := wsMinimized;
    Hide;
  end else begin
    Show;
    WindowState := wsNormal;
    Application.BringToFront;
  end;
end;

procedure TMainFrame.tmUpdateTimer(Sender: TObject);
begin
  fTicker.CleanLists;
  if fCheckLoginCounter = 3 then begin
    TWaiting.Create(fTicker, False,fSendNotification,true);
    fCheckLoginCounter := 0;
    if not fTicker.LoggedIn then begin // <-- We lost connection :(
      // Try to reconnect and cleanup all sessions
      fTicker.Free;
      fTicker := TTicker.Create(edUsername.Text,edPassword.Text);
      if not fTicker.login then begin
        lblStatus.Caption := cLostConnection;
        lblStatus.Font.Color := clRed;
        btnLogin.Caption := cLogIn;
        btnLogin.SetFocus;
        edUsername.Enabled := true;
        edPassword.Enabled := true;
        tmUpdate.Enabled := false;
      end;
    end;
  end else begin
    TWaiting.Create(fTicker, False,fSendNotification,false);
    Inc(fCheckLoginCounter);
  end;
end;

procedure TMainFrame.triIconClick(Sender: TObject);
begin
  if Visible then begin
    WindowState := wsMinimized;
    Hide;
  end else begin
    Show;
    WindowState := wsNormal;
    Application.BringToFront;
  end;
end;

procedure TMainFrame.triIconMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ssRight in Shift then begin
    if fTicker <> nil then
      mniRepeatLast.Enabled := fTicker.LoggedIn
    else
      mniRepeatLast.Enabled := false;
    SetForegroundWindow(Handle);
    mnuPopMenu.PopUp(Mouse.CursorPos.X, Mouse.CursorPos.Y);
    PostMessage(Handle, WM_NULL, 0, 0);
  end;
end;

constructor TWaiting.Create(aTicker: TTicker; aLast10: Boolean; aSendNotification: TSendNotification; aCheckLogin: Boolean);
begin
  inherited Create;
  fTicker := aTicker;
  fLast10 := aLast10;
  fSendNotification := aSendNotification;
  fCheckLogin := aChecKLogin;
  FreeOnTerminate := True;
end;

procedure TWaiting.Execute;
var
  I: Integer;
  Activities: TActivities;
  Settings : TSettings;
  ShowShoutboxmessage : Boolean;
begin
  Settings := TSettings.Create;
  try
    ShowShoutboxmessage := Settings.ShowShoutboxmessages;
  finally
    Settings.Free;
  end;
  if fLast10 then begin
    Activities := fTicker.GetActivities(true);
    for I := 0 to Activities.Count-1 do begin
      if Activities[I].IsShoutboxMessage then begin
        if ShowShoutboxmessage then begin
          fSendNotification.SendNotification(Activities[I]);
          Sleep(700);
        end;
      end else begin
        fSendNotification.SendNotification(Activities[I]);
        Sleep(700);
      end;
    end;
  end else begin
    if fCheckLogin then begin
      if fTicker.isLoggedIn then
        SendNotifications(ShowShoutboxmessage)
      else
        fTicker.LoggedIn := false;
    end else
      SendNotifications(ShowShoutboxmessage);
  end;
end;

procedure TWaiting.SendNotifications(aShowShoutboxMessages : Boolean);
var
  I: Integer;
  Activities: TActivities;
begin
  Activities := fTicker.GetActivities(false);
  for I := Activities.Count-1 downto 0 do
    if not Activities[I].AlreadySent then begin
      if Activities[I].IsShoutboxMessage then begin
        if aShowShoutboxMessages then begin
          Activities[I].AlreadySent := true;
          fSendNotification.SendNotification(Activities[I]);
          Self.Sleep(700);
        end;
      end else begin
        Activities[I].AlreadySent := true;
        fSendNotification.SendNotification(Activities[I]);
        Self.Sleep(700);
      end;
    end;
end;

function TMainFrame.IsWorkstationLocked: Boolean;
var
  hDesktop: HDESK;
begin
  Result := False;
  hDesktop := OpenDesktop('default',
    0, False,
    DESKTOP_SWITCHDESKTOP);
  if hDesktop <> 0 then
  begin
    Result := not SwitchDesktop(hDesktop);
    CloseDesktop(hDesktop);
  end;
end;

end.
