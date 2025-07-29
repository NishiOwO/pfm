unit UserInterface;

interface
type
	TUIBorderList = Array of String;

procedure UIInit();
procedure UIRedraw();
procedure UIError(Content : String);
function UIGetBorder() : TUIBorderList;
procedure UIBox(X : Integer; Y : Integer; W : Integer; H : Integer);
procedure UIPushColor(FG : Byte; BG : Byte);
procedure UIPopColor();
procedure UIDeinit();

const
	UIBorderLT : Integer = 1;
	UIBorderRT : Integer = 2;
	UIBorderLB : Integer = 3;
	UIBorderRB : Integer = 4;
	UIBorderLR : Integer = 5;
	UIBorderTB : Integer = 6;

implementation
uses
	Screen,
	Keyboard,
{$ifdef unix}
	BaseUnix,
{$endif}
	Math;

var
	ColorStack : Array of Byte;

procedure UIPushColor(FG : Byte; BG : Byte);
begin
	SetLength(ColorStack, Length(ColorStack) + 2);
	ColorStack[Length(ColorStack) - 2] := FG;
	ColorStack[Length(ColorStack) - 1] := BG;
	ScreenSetFG(FG);
	ScreenSetBG(BG);
end;

procedure UIPopColor();
begin
	SetLength(ColorStack, Length(ColorStack) - 2);
	ScreenSetFG(ColorStack[Length(ColorStack) - 2]);
	ScreenSetBG(ColorStack[Length(ColorStack) - 1]);
end;

function UIGetBorder() : TUIBorderList;
var
	R : TUIBorderList;
begin
	SetLength(R, 6);
{$ifdef windows}
	R[UIBorderLT] := #218;
	R[UIBorderRT] := #191;
	R[UIBorderLB] := #192;
	R[UIBorderRB] := #217;
	R[UIBorderLR] := #179;
	R[UIBorderTB] := #196;
{$else}
	R[UIBorderLT] := '┌';
	R[UIBorderRT] := '┐';
	R[UIBorderLB] := '└';
	R[UIBorderRB] := '┘';
	R[UIBorderLR] := '│';
	R[UIBorderTB] := '─';
{$endif}
	UIGetBorder := R;
end;

procedure UIBox(X : Integer; Y : Integer; W : Integer; H : Integer);
var
	I : Integer;
	J : Integer;
	Border : TUIBorderList;
begin
	Border := UIGetBorder();

	for I := Y to (Y + H) do
	begin
		for J := X to (X + W) do
		begin
			ScreenGotoXY(J, I);
			if (I = Y) and (J = X) then Write(Border[UIBorderLT])
			else if (I = Y) and (J = (X + W)) then Write(Border[UIBorderRT])
			else if (I = (Y + H)) and (J = X) then Write(Border[UIBorderLB])
			else if (I = (Y + H)) and (J = (X + W)) then Write(Border[UIBorderRB])
			else if (J = X) or (J = (X + W)) then Write(Border[UIBorderLR])
			else if (I = Y) or (I = (Y + H)) then Write(Border[UIBorderTB])
			else Write(' ');
		end;
	end;
end;

procedure UIRedraw();
begin
	ScreenClear();
end;

procedure UIError(Content : String);
var
	X : Integer;
	Y : Integer;
	W : Integer;
	H : Integer;
begin
	ScreenGetSize(@X, @Y);
	W := 75;
	H := 5;
	UIPushColor(ScreenWhite, ScreenRed);
	UIBox(Floor((X - W) / 2), Floor((Y - H) / 2), W, H);
	ScreenGotoXY(Floor((X - 7) / 2), Floor((Y - H) / 2));
	Write(' Error ');
	ScreenGotoXY(Floor((X - Length(Content)) / 2), Floor((Y - H) / 2) + 1);
	Write(Content);
	ScreenGotoXY(Floor((X - 8) / 2), Floor((Y - H) / 2) + 4);
	UIPushColor(ScreenRed, ScreenWhite);
	Write(' < OK > ');
	UIPopColor();
	UIPopColor();
	repeat until ScreenReadKey() = #13;
end;

function UIExit(WasItBreak : Boolean) : Boolean;
begin
	ScreenDeinit();
	UIExit := False;
end;

procedure UIDeinit();
begin
	UIExit(False);
end;

procedure UIExit2();
begin
	UIExit(False);
end;

{$ifdef unix}
procedure UIExit3(sig : cint); cdecl;
begin
	UIExit(False);
	Halt(0);
end;
{$endif}

procedure UIInit();
begin
	SetLength(ColorStack, 0);
	SysSetCtrlBreakHandler(@UIExit);
	AddExitProc(@UIExit2);
{$ifdef unix}
	FpSignal(SIGINT, @UIExit3);
	FpSignal(SIGTERM, @UIExit3);
{$endif}
	ScreenInit();
	UIPushColor(ScreenWhite, ScreenBlue);
	UIRedraw();
	UIError('something went wrong!');
end;

end.
