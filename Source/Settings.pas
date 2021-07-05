unit Settings;

interface

uses
  Windows, System.SysUtils, System.Variants, System.Classes, Registry, shellAPI, System.StrUtils, Contnrs, IdCoderMIME,Math;

type
  TSettings = class
  strict private
    fSavePassword,
    fAutomaticLogin,
    fShowShoutboxmessages : Boolean;
    fUsername,
    fPassword : String;
    function encryptPassword(aUnencryptedPassword : String) : String;
  	function Decode64(S: string): string;
	  function Encode64(S: string): string;
    function SettingsSaved : Boolean;
    procedure LoadSettings;
    procedure CreateDefault;
  public
    constructor Create;
    procedure SaveSettings;
    function decryptPassword(aEncryptedPassword : String) : String;
    property Username : String read fUsername write fUsername;
    property Password : String read fPassword write fPassword;
    property SavePassword : Boolean read fSavePassword write fSavePassword;
    property AutomaticLogin : Boolean read fAutomaticLogin write fAutomaticLogin;
    property ShowShoutboxmessages : Boolean read fShowShoutboxmessages write fShowShoutboxmessages;
  end;

const
  cPool = 'aba5acD2eFgH4i5j6k7lM898900�NOPqmRsTquVW';
  cRegKey = 'Software\FH\Ticker';
  cDefaultSavePassword = False;
  cDefaultUsername = '0';
  cDefaultPassword = '0';
  cDefaultAutomaticLogin = False;
  cDefaultShowShoutboxmessages = False;
  cKeyUsername = 'Username';
  cKeyPassword = 'Password';
  cKeySavePassword = 'SavePassword';
  cKeyAutomaticLogin = 'AutomaticLogin';
  cKeyShowShoutboxmessages = 'Shoutbox';

implementation

constructor TSettings.Create;
begin
  inherited Create;
  if SettingsSaved then
    LoadSettings
  else
    CreateDefault;
end;

procedure TSettings.SaveSettings;
var
  Reg : TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey(cRegKey,true);
    Reg.WriteString(cKeyUsername,fUsername);
    Reg.WriteString(cKeyPassword,EncryptPassword(fPassword));
    Reg.WriteBool(cKeySavePassword,fSavePassword);
    Reg.WriteBool(cKeyAutomaticLogin,fAutomaticLogin);
    Reg.WriteBool(cKeyShowShoutboxmessages,fShowShoutboxmessages);
  finally
    Reg.CloseKey;
    Reg.Free;
  end;
end;

procedure TSettings.CreateDefault;
var
  Reg : TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey(cRegKey,true);
    Reg.WriteString(cKeyUsername,cDefaultUsername);
    Reg.WriteString(cKeyPassword,EncryptPassword(cDefaultPassword));
    Reg.WriteBool(cKeySavePassword,cDefaultSavePassword);
    Reg.WriteBool(cKeyAutomaticLogin,cDefaultAutomaticLogin);
    Reg.WriteBool(cKeyShowShoutboxmessages,cDefaultShowShoutboxmessages);
  finally
    Reg.CloseKey;
    Reg.Free;
  end;
  fUsername := cDefaultUsername;
  fPassword := cDefaultPassword;
  fSavePassword := cDefaultSavePassword;
  fAutomaticLogin := cDefaultAutomaticLogin;
  fShowShoutboxmessages := cDefaultShowShoutboxmessages;
end;

function TSettings.SettingsSaved : Boolean;
var
  Reg: TRegistry;
  Saved : Boolean;
begin
  Reg := TRegistry.Create;
  Saved := false;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.KeyExists(cRegKey) then begin
      Reg.OpenKey(cRegKey,false);
      Saved := Reg.ValueExists(cKeySavePassword);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
  Exit(Saved);
end;

procedure TSettings.LoadSettings;
var
  Reg : TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey(cRegKey,true);
    fUsername := Reg.ReadString(cKeyUsername);
    fPassword := DecryptPassword(Reg.ReadString(cKeyPassword));
    fSavePassword := Reg.ReadBool(cKeySavePassword);
    fAutomaticLogin := Reg.ReadBool(cKeyAutomaticLogin);
    fShowShoutboxmessages := Reg.ReadBool(cKeyShowShoutboxmessages);
  finally
    Reg.CloseKey;
    Reg.Free;
  end;
end;

function TSettings.Encode64(S: string): string;
var
  IdEncoderMIME: TIdEncoderMIME;
begin
  IdEncoderMIME := TIdEncoderMIME.Create(nil);
  try
    Result := IdEncoderMIME.EncodeString(S);
  finally
    IdEncoderMIME.Free;
  end;
end;

function TSettings.Decode64(S: string): string;
var
  IdDecoderMIME: TIdDecoderMIME;
begin
  IdDecoderMIME := TIdDecoderMIME.Create(nil);
  try
    Result := IdDecoderMIME.DecodeString(S);
  finally
    IdDecoderMIME.Free;
  end;
end;

function TSettings.DecryptPassword(aEncryptedPassword : String) : String;
begin
  // Function modified for security purpose. Be aware of no encryption in this version!
  Exit(aEncryptedPassword);
end;

function TSettings.EncryptPassword(aUnencryptedPassword : String) : String;
begin
  // Function modified for security purpose. Be aware of no encryption in this version!
  Exit(aUnencryptedPassword);
end;

end.
