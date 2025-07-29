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
procedure UIButtonReset();
procedure UILoop();
procedure UIButton(X : Integer; Y : Integer; W : Integer; H : Integer; Show : String);

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

type
	TButton = record
		Show : String;
		X : Integer;
		Y : Integer;
		W : Integer;
		H : Integer;
		BG : Byte;
		FG : Byte;
	end;

var
	ColorStack : Array of Byte;
	ButtonIndex : Integer;
	SavedButtons : Array of TButton;

procedure UIButtonReset();
begin
	ButtonIndex := 0;
	SetLength(SavedButtons, 0);
end;

procedure UIButton(X : Integer; Y : Integer; W : Integer; H : Integer; Show : String);
var
	I : Integer;
	J : Integer;
begin
	for I := Y to (Y + H - 1) do
	for J := X to (X + W - 1) do
	begin
		ScreenGotoXY(J, I);
		Write(' ');
	end;
	ScreenGotoXY(X, Y + Floor(H / 2));
	Write('<');
	ScreenGotoXY(X + W - 1, Y + Floor(H / 2));
	Write('>');
	ScreenGotoXY(X + Floor((W - Length(Show)) / 2), Y + Floor(H / 2));
	Write(Show);

	SetLength(SavedButtons, Length(SavedButtons) + 1);
	SavedButtons[Length(SavedButtons) - 1].Show := Show;
	SavedButtons[Length(SavedButtons) - 1].X := X;
	SavedButtons[Length(SavedButtons) - 1].Y := Y;
	SavedButtons[Length(SavedButtons) - 1].W := W;
	SavedButtons[Length(SavedButtons) - 1].H := H;
	SavedButtons[Length(SavedButtons) - 1].FG := ColorStack[Length(ColorStack) - 2];
	SavedButtons[Length(SavedButtons) - 1].BG := ColorStack[Length(ColorStack) - 1];
end;

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

	for I := Y to (Y + H - 1) do
	begin
		for J := X to (X + W - 1) do
		begin
			ScreenGotoXY(J, I);
			if (I = Y) and (J = X) then Write(Border[UIBorderLT])
			else if (I = Y) and (J = (X + W - 1)) then Write(Border[UIBorderRT])
			else if (I = (Y + H - 1)) and (J = X) then Write(Border[UIBorderLB])
			else if (I = (Y + H - 1)) and (J = (X + W - 1)) then Write(Border[UIBorderRB])
			else if (J = X) or (J = (X + W - 1)) then Write(Border[UIBorderLR])
			else if (I = Y) or (I = (Y + H - 1)) then Write(Border[UIBorderTB])
			else Write(' ');
		end;
	end;
end;

procedure UIRedraw();
var
	X : Integer;
	Y : Integer;
begin
	ScreenClear();
	ScreenGetSize(@X, @Y);
	UIBox(0, 1, Floor(X / 2), Y - 1);
	UIBox(Floor(X / 2), 1, X - Floor(X / 2), Y - 1);
end;

function UIButtonLoop() : Integer;
var
	I : Integer;
	X : Integer;
	Y : Integer;
	W : Word;
begin
	repeat
	begin
		for I := 0 to (Length(SavedButtons) - 1) do
		begin
			ScreenGotoXY(SavedButtons[I].X, SavedButtons[I].Y);
			if I = ButtonIndex then UIPushColor(SavedButtons[I].BG, SavedButtons[I].FG)
			else UIPushColor(SavedButtons[I].FG, SavedButtons[I].BG);

			for Y := SavedButtons[I].Y to (SavedButtons[I].Y + SavedButtons[I].H - 1) do
			for X := SavedButtons[I].X to (SavedButtons[I].X + SavedButtons[I].W - 1) do
			begin
				ScreenGotoXY(X, Y);
				Write(' ');
			end;

			ScreenGotoXY(SavedButtons[I].X, SavedButtons[I].Y + Floor(SavedButtons[I].H / 2));
			Write('<');
			ScreenGotoXY(SavedButtons[I].X + SavedButtons[I].W - 1, SavedButtons[I].Y + Floor(SavedButtons[I].H / 2));
			Write('>');
			ScreenGotoXY(SavedButtons[I].X + Floor((SavedButtons[I].W - Length(SavedButtons[I].Show)) / 2), SavedButtons[I].Y + Floor(SavedButtons[I].H / 2));
			Write(SavedButtons[I].Show);
			UIPopColor();
		end;
		W := ScreenReadKey();
		if W = 9 then
		begin
			if ButtonIndex = (Length(SavedButtons) - 1) then
			begin
				ButtonIndex := 0;
			end
			else
			begin
				ButtonIndex := ButtonIndex + 1;
			end;
		end
		else if W = 13 then break;
	end
	until False;

	UIButtonLoop := ButtonIndex;
end;

function UIPopup(W : Integer; H : Integer; FG : Byte; BG : Byte; Title : String; Content : String; Buttons : Array of String) : Integer;
var
	X : Integer;
	Y : Integer;
	I : Integer;
	BX : Integer;
begin
	ScreenGetSize(@X, @Y);
	UIPushColor(ScreenWhite, ScreenRed);
	UIBox(Floor((X - W) / 2), Floor((Y - H) / 2), W, H);
	ScreenGotoXY(Floor((X - Length(Title) - 2) / 2), Floor((Y - H) / 2));
	Write(' ' + Title + ' ');
	ScreenGotoXY(Floor((X - Length(Content)) / 2), Floor((Y - H) / 2) + 1);
	Write(Content);

	BX := Floor((X - (Length(Buttons) - 1) - 8 * Length(Buttons)) / 2);
	UIButtonReset();
	for I := 0 to (Length(Buttons) - 1) do
	begin
		UIButton(BX, Floor((Y - H) / 2) + H - 2, 8, 1, Buttons[I]);
		BX := BX + 9;
	end;

	UIPopColor();

	UIPopup := UIButtonLoop();

	UIButtonReset();

	UIRedraw();
end;

function UIPopup(W : Integer; H : Integer; FG : Byte; BG : Byte; Title : String; Content : String) : Integer;
var
	Arr : Array of String;
begin
	SetLength(Arr, 0);
	UIPopup := UIPopup(W, H, FG, BG, Title, Content, Arr);
end;

procedure UIError(Content : String);
var
	W : Integer;
	H : Integer;
	OK : Array of String;
begin
	W := 75;
	H := 5;
	SetLength(OK, 1);
	OK[0] := 'OK';
	UIPopup(W, H, ScreenWhite, ScreenRed, 'Error', Content, OK);
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
end;

procedure UILoop();
begin
	while True do;
end;

end.
