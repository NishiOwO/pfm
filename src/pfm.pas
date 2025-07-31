program pfm;

{$ifdef windows}
{$r ./pfm.rc}
{$endif}

uses
	UserInterface,
	Config;

begin
	ConfigInit();
	UIInit();
	UILoop();
	UIDeinit();
end.
