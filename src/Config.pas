unit Config;

interface
var
	ConfigFileAreaWidth : Integer;

procedure ConfigInit();

implementation
procedure ConfigInit();
begin
	ConfigFileAreaWidth := 20;
end;

end.
