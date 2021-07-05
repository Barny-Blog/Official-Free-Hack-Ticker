unit Ticker;

interface

uses
  StrUtils, System.Classes, System.SysUtils, Generics.Collections, System.RegularExpressions,IdHTTP,IdGlobal;

type
  TActivity = class
  strict private
    fID: Integer;
    fTitle,
    fUser : String;
    fSection : String;
    fAlreadySent : Boolean;
    fIsShoutboxMessage : Boolean;
    fTimeString : String;
  public
    property ID: Integer read fID write fID;
    property Title: string read fTitle write fTitle;
    property User: string read fUser write fUser;
    property Section: string read fSection write fSection;
    property AlreadySent: Boolean read fAlreadySent write fAlreadySent;
    property IsShoutboxMessage : Boolean read fIsShoutboxMessage write fIsShoutboxMessage;
    property TimeString : String read fTimeString write fTimeString;
  end;

  TActivities = class(TList<TActivity>);

  TTicker = class(TObject)
  strict private
    fUsername,
    fPassword : String;
    fConn: TIdHTTP;
    fActivities : TActivities;
    fActivity : TActivity;
    fProofOfLogin : String;
    fLoggedIn : Boolean;
    function WasAlreadySent(aActivity : TActivity) : Boolean;
    function StripShoutboxMessage(aRaw : String) : String;
    function RemoveAllTags(aRaw : String) : String;
    procedure getShoutBoxMessages;
  public
    constructor Create(aUsername,aPassword: String);
    destructor Destroy; override;
    function Login : Boolean;
    function getActivities(aLast10:Boolean) : TActivities;
    function isLoggedIn : Boolean;
    procedure CleanLists;
    property Username: String read fUsername write fUsername;
    property Password: String read fPassword write fPassword;
    property LoggedIn: Boolean read fLoggedIn write fLoggedIn;
  end;

const
  cLoginURL = 'https://free-hack.com/login.php?do=login';
  cCheckLoginUrl = 'https://free-hack.com/index.php';
  cParseURL = 'https://free-hack.com/misc.php?show=latestposts&vsacb_resnr=5';
  cShoutboxMessagesURL = 'https://free-hack.com/misc.php?do=ccarc';
  cLoginName = 'vb_login_username=';
  cPasswordName = 'vb_login_md5password=';
  cPasswordNameUTF = 'vb_login_md5passwordutf=';
  cDoLogin = 'do=login';
  cHTTP_STATUS = 200;
  cHTTP_NOT_FOUND = 404;
  cHTTP_REDIRECTED = 301;
  cError = 'error';
  cReplaceHits = 'Hits/Antworten';
  cReplaceDatum = 'Datum/Zeit';
  cRegex_Posts = 'title=\".+\">[\[|<]';
  cRegex_Times = '\d{1,2}\-\d{1,2}\,\s\d{2}\:\d{2}';
  cRegex_Shoutbox = '\<font color\=\"{0,1}[\#|\w|\d]{6}.{1,}\<\/font>';
  cRegex_RemoveAllTags = '(\<.{1,}\/>)|(\<.{1,}\<.{1,2}\>)';
  cRegex_ReplaceQuote = '&quot;';
  cDelimeter = '$';
  cToReplace = '"';
  cDelimeterShoutbox = '>';
  cCutOffShoutboxMessage = '</font';


implementation

uses
  IdSSLOpenSSL, IdHashMessageDigest;

constructor TTicker.Create(aUsername, aPassword: string);
var
  MD5 : TIdHashMessageDigest5;
begin
  inherited Create;
  fUsername := aUsername;
  MD5 := TIdHashMessageDigest5.Create;
  try
    fPassword := IdGlobal.IndyLowerCase(MD5.HashStringAsHex(aPassword));
  finally
    MD5.Free;
  end;
  fActivities := TActivities.Create;
  fConn := TIdHTTP.Create(nil);
  fProofOfLogin := fUsername+'">Hallo, '+fUsername+'.</a>'
end;

destructor TTicker.Destroy;
var
  I : Integer;
begin
  if fActivities <> nil then begin
    for I := 0 to fActivities.Count-1 do
      if fActivities[I] <> nil then
        fActivities[I].Free;
    fActivities.Free;
  end;
  if fConn <> nil then  
    fConn.Free;
  inherited Destroy;
end;

function TTicker.Login : Boolean;
var
  Data: TStringList;
  Response: string;
  SSLIOHandlerSocketOpenSSL : TIdSSLIOHandlerSocketOpenSSL;
begin
  Data := TStringList.Create;
  Data.Add(cLoginName+fUsername);
  Data.Add(cPasswordName+fPassword);
  Data.Add(cPasswordNameUTF+fPassword);
  Data.Add(cDoLogin);
  try
    fConn.HandleRedirects := true;
    fConn.AllowCookies := true;
    SSLIOHandlerSocketOpenSSL := TIdSSLIOHandlerSocketOpenSSL.Create(fConn);
    SSLIOHandlerSocketOpenSSL.SSLOptions.SSLVersions := [sslvTLSv1_2];
    fConn.IOHandler := SSLIOHandlerSocketOpenSSL;
    Response := fConn.Post(cLoginURL,Data);
    if cHTTP_STATUS = fConn.ResponseCode then begin
      Response := fConn.Get(cCheckLoginUrl);
      if ContainsText(Response,fProofOfLogin) then begin
        Result := true;
        fLoggedIn := true;
      end else begin
        Result := false;
        fLoggedIn := false;
      end;
    end else if cHTTP_NOT_FOUND = fConn.ResponseCode then begin
      Result := false;
      fLoggedIn := false;
    end else begin
      Result := false;
      fLoggedIn := false;
    end;
  finally
    Data.Free;
  end;
end;

function TTicker.getActivities(aLast10:Boolean) : TActivities;
var
  Regex : TRegex;
  Match : TMatch;
  List,
  Times,
  Temp,
  ToParse : TStringlist;
  I,
  Counter : Integer;
  Response : String;
begin
  if aLast10 then
    Exit(fActivities);
  ToParse := TStringlist.Create;
  List := TStringlist.Create;
  Times := TStringlist.Create;
  try
    Response := fConn.Get(cParseURL);
    Regex := TRegex.Create(cRegex_Posts);
    for Match in Regex.Matches(Response) do
      List.Add(Match.Value);
    Regex := TRegex.Create(cRegex_Times);
    for Match in Regex.Matches(Response) do
      Times.Add(Match.Value);
    for I := 0 to List.Count-1 do begin
      Temp := TStringlist.Create;
      try
        List[I] := stringreplace(List[I], cToReplace, cDelimeter, [rfReplaceAll, rfIgnoreCase]);
        ExtractStrings([cDelimeter], [], PChar(List[I]), Temp);
        if (not ContainsText(Temp[1],cReplaceHits)) AND (not ContainsText(Temp[1],cReplaceDatum)) then
          ToParse.Add(stringreplace(Temp[1], '&amp;', '&', [rfReplaceAll, rfIgnoreCase]));
      finally
        Temp.Free;
      end;
    end;
    I := 0;
    Counter := 0;
    while I < ToParse.Count-1 do begin
      fActivity := TActivity.Create;
      if fActivities.Count > 0 then
        fActivity.ID := fActivities[fActivities.Count-1].ID+1
      else
        fActivity.ID := I;
      fActivity.Title := ToParse[I];
      fActivity.User := ToParse[I+1];
      fActivity.Section := 'Forum: '+ToParse[I+2];
      fActivity.AlreadySent := False;
      fActivity.IsShoutboxMessage := False;
      fActivity.TimeString := Times[Counter];
      if WasAlreadySent(fActivity) then
        fActivity.Free
      else
        fActivities.Add(fActivity);
      inc(I,3);
      inc(Counter);
    end;
    // 'CleanLists' may cause several issues when displaying new messages
    //CleanLists;
  finally
    List.Free;
    Times.Free;
    ToParse.Free;
  end;
  getShoutBoxMessages;
  Exit(fActivities);
end;

procedure TTicker.getShoutBoxMessages;
var
  Regex : TRegex;
  Match : TMatch;
  List : TStringList;
  I : Integer;
  Response : String;
begin
  List := TStringList.Create;
  try
    Response := fConn.Get(cShoutboxMessagesURL);
    Regex := TRegex.Create(cRegex_Shoutbox);
    for Match in Regex.Matches(Response) do
      List.Add(Match.Value);
    for I := 0 to List.Count-1 do
        List[I] := stringreplace(List[I], cToReplace, cDelimeter, [rfReplaceAll, rfIgnoreCase]);
    I := 0;
    while I < 10 do begin
      fActivity := TActivity.Create;
      if fActivities.Count > 0 then
        fActivity.ID := fActivities[fActivities.Count-1].ID+1
      else
        fActivity.ID := I;
      fActivity.Title := StripShoutboxMessage(List[I]);
      fActivity.User := StripShoutboxMessage(List[I+1]);
      fActivity.Section := 'Shoutbox: ';
      fActivity.TimeString := '00:00';
      fActivity.IsShoutboxMessage := True;
      fActivity.AlreadySent := False;
      if WasAlreadySent(fActivity) then
        fActivity.Free
      else
        fActivities.Add(fActivity);
      Inc(I,2);
    end;
  finally
    List.Free;
  end;
end;

function TTicker.StripShoutboxMessage(aRaw: String) : String;
var
  I : Integer;
begin
  I := 1;
  while I < Length(aRaw) do
    if aRaw[I] <> '>' then
      Inc(I)
    else
      break;
  Inc(I);
  aRaw := Copy(aRaw,I,Length(aRaw));
  I := Length(aRaw);
  while I > 0 do
    if aRaw[I] <> '<' then
      Dec(I)
    else
      break;
  Dec(I);
  aRaw := Copy(aRaw,1,I);

  if ContainsText(aRaw,'&quot;') then
    aRaw := TRegex.Replace(aRaw,cRegex_ReplaceQuote,'"');

  if (not ContainsText(aRaw,'<b>')) and (not ContainsText(aRaw,'</b>')) then
    Exit(RemoveAllTags(aRaw))
  else
    Exit(StripShoutboxMessage(aRaw));
end;

function TTicker.RemoveAllTags(aRaw : String) : String;
begin
  Exit(TRegex.Replace(aRaw,cRegex_RemoveAllTags,''));
end;

procedure TTicker.CleanLists;
var
  I : Integer;
  Activity : TActivity;
begin
  if fActivities.Count > 70 then begin
    for I := 0 to 30 do
      if (fActivities[I].AlreadySent) and (fActivities[I].IsShoutboxMessage) then begin
        Activity := fActivities[I];
        fActivities.Remove(Activity);
        Activity.Free;
      end;
  end;
end;

function TTicker.WasAlreadySent(aActivity: TActivity) : Boolean;
var
  I : Integer;
begin
  for I := 0 to fActivities.Count-1 do
    if (fActivities[I].Title = aActivity.Title) and (fActivities[I].User = aActivity.User) and (fActivities[I].TimeString = aActivity.TimeString) then
      if (fActivities[I].Section = aActivity.Section) then
        Exit(True);
  Exit(False);
end;

function TTicker.isLoggedIn : Boolean;
var
  Response : String;
begin
  if fConn <> nil then begin
    Response := fConn.Get(cCheckLoginUrl);
    if fConn.ResponseCode = cHTTP_STATUS then
      if ContainsText(Response,fProofOfLogin) then
        Exit(True);
    Exit(False);
  end else
    Exit(False);
end;

end.
