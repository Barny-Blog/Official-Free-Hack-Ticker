unit NotificationUnit;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.StdCtrls, Ticker, Vcl.Controls, Vcl.Graphics;

type
  TNotifyInfo = record
    IsBusy: Boolean;
    Position: Integer;
  end;

  TNotifyInfos = array of TNotifyInfo;

  TNotificationForm = class(TForm)
    lblTitle: TLabel;
    lblUser: TLabel;
    lblSection: TLabel;
    tmMove: TTimer;
    tmOrder: TTimer;
    tmBlendOut: TTimer;
    tmBlend: TTimer;
    imgLogo: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmOrderTimer(Sender: TObject);
    procedure tmBlendOutTimer(Sender: TObject);
    procedure tmMoveTimer(Sender: TObject);
    procedure tmBlendTimer(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure lblSectionClick(Sender: TObject);
    procedure lblTitleClick(Sender: TObject);
    procedure lblUserClick(Sender: TObject);
  strict private
    fUser,
    fTitle,
    fSection: string;
    fBlendOutTop: Boolean;
    fShowSpeed,
    fNo,
    fDiff,
    fBlendSpeed,
    fPositionIndex: Integer;
    fNotifyInfos: TNotifyInfos;
    procedure StopAndClose;
    procedure BlendOut;
    function HtmlColorToColor(AHtmlColor: string): TColor;
    function GetPrimaryMonitor : Integer;
  public
    constructor Create(AOwner: TComponent; aTitle, aUser, aSection: string; aShowSpeed: Integer; aBlendOutTop: Boolean; aNo: Integer; aBlendSpeed: Integer; aPositionIndex: Integer; aNotifyInfos: TNotifyInfos); reintroduce;
  end;

  TSendNotification = class
  strict private
    fActivities: TActivities;
    fNotificationForms: TNotificationForm;
    fOwner: TComponent;
    procedure GetMaxWindowsAndSetPosition;
  public
    fNotifyInfos : TNotifyInfos;
    constructor Create(aOwner: TComponent);
    destructor Destroy; override;
    procedure SendNotification(aActivity: TActivity);
  end;

  TNotify = class(TThread)
  strict private
    fActivity: TActivity;
    fOwner: TSendNotification;
    fMaster: TComponent;
    fPositionIndex: Integer;
    fNotifyInfos: TNotifyInfos;
  public
    function GetMonitor: TMonitor;
  public
    constructor Create(aActivity: TActivity; aOwner: TSendNotification; aMaster: TComponent; aNotifyInfos: TNotifyInfos);
    destructor Destroy; override;
    procedure Execute; override;
  end;

implementation

{$R *.dfm}

constructor TNotificationForm.Create(AOwner: TComponent; aTitle, aUser, aSection: string; aShowSpeed: Integer; aBlendOutTop: Boolean; aNo: Integer; aBlendSpeed: Integer; aPositionIndex: Integer; aNotifyInfos: TNotifyInfos);
begin
  inherited Create(AOwner);
  fTitle := aTitle;
  fSection := aSection;
  fUser := aUser;
  fShowSpeed := aShowSpeed;
  //fBlendOutTop := aBlendOutTop;
  fBlendOutTop := True;
  fNo := aNo;
  fBlendSpeed := aBlendSpeed;
  fPositionIndex := aPositionIndex;
  fNotifyInfos := aNotifyInfos;
  tmOrder.Interval := fShowSpeed;
  Self.Color := HtmlColorToColor('#4D4B4C');
end;

function TNotificationForm.HtmlColorToColor(AHtmlColor: string): TColor;
begin
  Delete(AHtmlColor, 1, 1);
  Result := StrToInt('$' + Copy(AHtmlColor, 5, 2) + Copy(AHtmlColor, 3, 2) + Copy(AHtmlColor, 1, 2));
end;

procedure TNotificationForm.FormCreate(Sender: TObject);
begin
  Self.AlphaBlend := True;
  Self.AlphaBlendValue := 0;
  Top := Screen.WorkAreaHeight - (Self.Height + 5);
  Left := ((Screen.Monitors[GetPrimaryMonitor].Left + Screen.Monitors[GetPrimaryMonitor].Width)-Width);
  fDiff := fNo;
  if lblUser.Canvas.TextWidth(fUser) > lblUser.Width then
    Height := Height + lblUser.Canvas.TextHeight(fUser);
  LblTitle.Caption := fTitle;
  lblUser.Caption := fUser;
  lblSection.Caption := fSection;
  tmBlendOut.Interval := 1;
  Self.AlphaBlendValue := 0;
  tmMove.Enabled := True;
  tmMove.Interval := fBlendSpeed;
  tmBlend.Enabled := True;
end;

function TNotificationForm.GetPrimaryMonitor;
var
  I : Integer;
begin
  for I := 0 to screen.MonitorCount do
    if screen.Monitors[I].Primary then
      Exit(I);
  Exit(0);
end;

procedure TNotificationForm.lblTitleClick(Sender: TObject);
begin
  BlendOut;
end;

procedure TNotificationForm.lblUserClick(Sender: TObject);
begin
  BlendOut;
end;

procedure TNotificationForm.lblSectionClick(Sender: TObject);
begin
  BlendOut;
end;

procedure TNotificationForm.FormClick(Sender: TObject);
begin
  BlendOut;
end;

procedure TNotificationForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  fNotifyInfos[fPositionIndex].IsBusy := False;
end;

procedure TNotificationForm.StopAndClose;
begin
  fNotifyInfos[fPositionIndex].IsBusy := False;
  tmBlendOut.Enabled := False;
  Close;
end;

procedure TNotificationForm.tmBlendOutTimer(Sender: TObject);
begin
  if fBlendOutTop then
    Self.Top := Self.Top - 5
  else begin
    Self.Left := Self.Left+5;
    Self.Width := Self.Width-5;
  end;
  if (Self.Top < (0 - Self.Height)) then
    StopAndClose;
  if Self.Left > Screen.Width then
    StopAndClose;
  if Self.AlphaBlendValue > 15 then
    Self.AlphaBlendValue := Self.AlphaBlendValue - 15
  else
    Self.AlphaBlendValue := 0;
  if Self.AlphaBlendValue = 0 then
    StopAndClose;
end;

procedure TNotificationForm.tmBlendTimer(Sender: TObject);
begin
  Self.AlphaBlend := True;
  Self.AlphaBlendValue := Self.AlphaBlendValue + 25;
  if Self.AlphaBlendValue >= 250 then begin
    Self.AlphaBlendValue := 255;
    tmBlend.Enabled := False;
  end;
end;

procedure TNotificationForm.tmMoveTimer(Sender: TObject);
begin
  if Self.Top >= fDiff then
    Self.Top := Self.Top - 5
  else begin
    tmOrder.Enabled := True;
    tmMove.Enabled := False;
  end;
end;

procedure TNotificationForm.tmOrderTimer(Sender: TObject);
begin
  Self.AlphaBlend := True;
  tmBlendOut.Enabled := True;
  tmOrder.Enabled := False;
end;

procedure TNotificationForm.BlendOut;
begin
  AlphaBlend := true;
  tmOrder.Enabled := false;
  tmBlendOut.Enabled := true;
end;

constructor TNotify.Create(aActivity: TActivity; aOwner: TSendNotification; aMaster: TComponent; aNotifyInfos: TNotifyInfos);
begin
  inherited Create;
  fActivity := aActivity;
  fOwner := aOwner;
  fMaster := aMaster;
  fNotifyInfos := aNotifyInfos;
  FreeOnTerminate := True;
end;

procedure TNotify.Execute;
var
  FoundPlace: Boolean;
  I,
  P: Integer;
  NotificationForms: TNotificationForm;
begin
  FoundPlace := False;
  while not FoundPlace do begin
    for I := 0 to High(fNotifyInfos) do
      with fNotifyInfos[I] do begin
        if not IsBusy then begin
          P := Position;
          fPositionIndex := I;
          IsBusy := True;
          FoundPlace := True;
          Break;
        end;
      end;
    if not FoundPlace then
      Self.Sleep(2500);
  end;
  Synchronize(
  procedure
  begin
    NotificationForms := TNotificationForm.Create(fMaster, fActivity.Title, fActivity.User, fActivity.Section, 9000, false, P, 10, fPositionIndex, fNotifyInfos);
    NotificationForms.Left := ((GetMonitor.Left + GetMonitor.Width) - NotificationForms.Width);
    NotificationForms.lblSection.Font.Name := 'Tahoma';
    NotificationForms.lblTitle.Font.Name := 'Tahoma';
    NotificationForms.lblUser.Font.Name := 'Tahoma';
    NotificationForms.FormStyle := fsStayOnTop;
    ShowWindow(NotificationForms.Handle, SW_SHOWNOACTIVATE);
    NotificationForms.Visible := true;
  end);
end;

destructor TNotify.Destroy;
begin
  inherited Destroy;
end;

function TNotify.GetMonitor: TMonitor;
begin
  Result := Screen.Monitors[0];
end;

constructor TSendNotification.Create(aOwner: TComponent);
begin
  inherited Create;
  fOwner := aOwner;
  fActivities := TActivities.Create;
  GetMaxWindowsAndSetPosition;
end;

destructor TSendNotification.Destroy;
begin
  fActivities.Free;
  inherited Destroy;
end;

procedure TSendNotification.SendNotification(aActivity: TActivity);
begin
  TNotify.Create(aActivity, Self, fOwner, fNotifyInfos);
end;

procedure TSendNotification.GetMaxWindowsAndSetPosition;
var
  MaxHeight,
  I,
  MaxWindows: Integer;
begin
  fNotificationForms := TNotificationForm.Create(fOwner, '0', '0', '0', 5000, False, 0, 10, 0, fNotifyInfos);
  try
    MaxHeight := Screen.Monitors[0].WorkAreaRect.Height;
    MaxWindows := MaxHeight div (fNotificationForms.Height + 5);
    SetLength(fNotifyInfos,MaxWindows);
    for I := 0 to High(fNotifyInfos) do begin
      fNotifyInfos[I].Position := (MaxHeight - (fNotificationForms.Height + 5));
      MaxHeight := fNotifyInfos[I].Position;
      fNotifyInfos[I].IsBusy := False;
    end;
  finally
    fNotificationForms.Free;
  end;
end;

end.

