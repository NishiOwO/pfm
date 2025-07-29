program pfm;

{$ifdef windows}
{$r ./pfm.rc}
{$endif}

uses
	UserInterface;

begin
	UIInit();
	UILoop();
	UIDeinit();
end.
