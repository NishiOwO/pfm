program fpmake;

uses
	fpmkunit;

var
	P : TPackage;
	T : TTarget;

begin
	with Installer do
	begin
		P := AddPackage('pfm');
		P.OSes := [win32, win64, netbsd, openbsd, freebsd, darwin, linux];
		P.SourcePath.Add('src');
		P.UnitPath.Add('src');
		T := P.Targets.AddProgram('pfm.pas');
		T.Options.Append('-Mobjfpc');
		T.Options.Append('-Sh');
		Run;
	end;
end.
