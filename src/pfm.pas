program pfm;

{$ifdef windows}
{$r ./pfm.rc}
{$endif}

uses
	UserInterface,
	Config,
	Sysutils;

function GetAppName() : String;
begin
	GetAppName := 'PFM';
end;

begin
	OnGetApplicationName := @GetAppName;
	ConfigInit();
	UIInit();
	UILoop();
	UIDeinit();
end.
