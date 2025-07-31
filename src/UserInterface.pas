unit UserInterface;

interface
type
	TUIBorderList = Array of String;
	TUIInvalidatedRect = record
		X : Integer;
		Y : Integer;
		W : Integer;
		H : Integer;
		Invalidated : Boolean;
	end;

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
procedure UIShowWelcome();
procedure UIButton(X : Integer; Y : Integer; W : Integer; H : Integer; Show : String);
procedure UIInvalidateRect(X : Integer; Y : Integer; W : Integer; H : Integer);
procedure UICheckAll();

const
	UIBorderLT : Integer = 0;
	UIBorderRT : Integer = 1;
	UIBorderLB : Integer = 2;
	UIBorderRB : Integer = 3;
	UIBorderLR : Integer = 4;
	UIBorderTB : Integer = 5;
	UIBorderLV : Integer = 6;
	UIBorderRV : Integer = 7;
	UIBorderTH : Integer = 8;
	UIBorderBH : Integer = 9;
	UIVersion : String = '0.0.0';

implementation
uses
	Screen,
	Keyboard,
{$ifdef unix}
	BaseUnix,
{$endif}
	Math,
	Config;

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
	InvalidatedRect : TUIInvalidatedRect;

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
	SetLength(R, 10);
{$ifdef windows}
	R[UIBorderLT] := #218;
	R[UIBorderRT] := #191;
	R[UIBorderLB] := #192;
	R[UIBorderRB] := #217;
	R[UIBorderLR] := #179;
	R[UIBorderTB] := #196;
	R[UIBorderLV] := #195;
	R[UIBorderRV] := #180;
	R[UIBorderTH] := #194;
	R[UIBorderBH] := #193;
{$else}
	R[UIBorderLT] := '┌';
	R[UIBorderRT] := '┐';
	R[UIBorderLB] := '└';
	R[UIBorderRB] := '┘';
	R[UIBorderLR] := '│';
	R[UIBorderTB] := '─';
	R[UIBorderLV] := '├';
	R[UIBorderRV] := '┤';
	R[UIBorderTH] := '┬';
	R[UIBorderBH] := '┴';
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

	ScreenGotoXY(0, 0);
end;

procedure UIInvalidateRect(X : Integer; Y : Integer; W : Integer; H : Integer);
begin
	InvalidatedRect.X := X;
	InvalidatedRect.Y := Y;
	InvalidatedRect.W := W;
	InvalidatedRect.H := H;
	InvalidatedRect.Invalidated := True;
end;

procedure UIRedraw();
var
	X : Integer;
	Y : Integer;
begin
	ScreenClear();
	ScreenGetSize(@X, @Y);
	ScreenGotoXY(0, 0);

	UIInvalidateRect(0, 0, X, Y);
	UICheckAll();
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

function LineCount(S : String) : Integer;
var
	I : Integer;
begin
	LineCount := 1;
	for I := 1 to Length(S) do
	begin
		if S[I] = #10 then LineCount := LineCount + 1;
	end;
end;

function MaxLineLen(S : String) : Integer;
var
	I : Integer;
	Current : Integer;
	Bracket : Boolean;
begin
	MaxLineLen := 0;
	Current := 0;
	Bracket := False;
	for I := 1 to Length(S) do
	begin
		if S[I] = #10 then Current := 0
		else if S[I] = #60 then Bracket := True
		else if S[I] = #62 then Bracket := False
		else if not(Bracket) then
		begin
			Current := Current + 1;
			if Current > MaxLineLen then
			begin
				MaxLineLen := Current;
			end;
		end;
	end;
end;

function UIPopup(W : Integer; H : Integer; FG : Byte; BG : Byte; Title : String; Content : String; Buttons : Array of String) : Integer;
var
	X : Integer;
	Y : Integer;
	I : Integer;
	BX : Integer;
	MaxLen : Integer;
	CX : Integer;
	CY : Integer;
	Bracket : Boolean;
	BPos : Integer;
	TagStr : String;
	FGCol : Byte;
	BGCol : Byte;
	BXChr : String;
	Border : TUIBorderList;
begin
	Border := UIGetBorder();

	ScreenGetSize(@X, @Y);
	UIPushColor(FG, BG);
	UIBox(Floor((X - W) / 2), Floor((Y - H) / 2), W, H);
	ScreenGotoXY(Floor((X - Length(Title) - 2) / 2), Floor((Y - H) / 2));
	Write(' ' + Title + ' ');

	MaxLen := MaxLineLen(Content);

	CX := 0;
	CY := 0;
	Bracket := False;
	for I := 1 to Length(Content) do
	begin
		if Content[I] = #10 then
		begin
			CX := 0;
			CY := CY + 1;
			if (CY = (H - 4)) then break;
		end
		else if Content[I] = #60 then
		begin
			Bracket := True;
			BPos := I + 1;
		end
		else if Content[I] = #62 then
		begin
			Bracket := False;
			TagStr := Copy(Content, BPos, I - BPos);
			FGCol := $ff;
			BGCol := $ff;
			if TagStr = 'FGBLACK' then FGCol := ScreenBlack
			else if TagStr = 'FGRED' then FGCol := ScreenRed
			else if TagStr = 'FGGREEN' then FGCol := ScreenGreen
			else if TagStr = 'FGYELLOW' then FGCol := ScreenYellow
			else if TagStr = 'FGBLUE' then FGCol := ScreenBlue
			else if TagStr = 'FGMAGENTA' then FGCol := ScreenMagenta
			else if TagStr = 'FGCYAN' then FGCol := ScreenCyan
			else if TagStr = 'FGWHITE' then FGCol := ScreenWhite
			else if TagStr = 'BGBLACK' then BGCol := ScreenBlack
			else if TagStr = 'BGRED' then BGCol := ScreenRed
			else if TagStr = 'BGGREEN' then BGCol := ScreenGreen
			else if TagStr = 'BGYELLOW' then BGCol := ScreenYellow
			else if TagStr = 'BGBLUE' then BGCol := ScreenBlue
			else if TagStr = 'BGMAGENTA' then BGCol := ScreenMagenta
			else if TagStr = 'BGCYAN' then BGCol := ScreenCyan
			else if TagStr = 'BGWHITE' then BGCol := ScreenWhite;

			if not(FGCol = $ff) then UIPushColor(FGCol, ColorStack[Length(ColorStack) - 1])
			else if not(BGCol = $ff) then UIPushColor(ColorStack[Length(ColorStack) - 2], BGCol)
			else
			begin
				if TagStr = 'POPCOLOR' then UIPopColor()
				else if (Length(TagStr) > 2) and (Copy(TagStr, 1, 1) = 'B') and (Copy(TagStr, 2, 1) = 'X') then
				begin
					BXChr := ' ';
					if TagStr = 'BXLT' then BXChr := Border[UIBorderLT]
					else if TagStr = 'BXRT' then BXChr := Border[UIBorderRT]
					else if TagStr = 'BXLB' then BXChr := Border[UIBorderLB]
					else if TagStr = 'BXRB' then BXChr := Border[UIBorderRB]
					else if TagStr = 'BXLR' then BXChr := Border[UIBorderLR]
					else if TagStr = 'BXTB' then BXChr := Border[UIBorderTB]
					else if TagStr = 'BXLV' then BXChr := Border[UIBorderLV]
					else if TagStr = 'BXRV' then BXChr := Border[UIBorderRV]
					else if TagStr = 'BXTH' then BXChr := Border[UIBorderTH]
					else if TagStr = 'BXBH' then BXChr := Border[UIBorderBH];
					ScreenGotoXY(Floor((X - MaxLen) / 2) + CX, Floor((Y - H) / 2) + 1 + CY);
					CX := CX + 1;
					Write(BXChr);
				end;
			end;
		end
		else if not(Bracket) then
		begin
			ScreenGotoXY(Floor((X - MaxLen) / 2) + CX, Floor((Y - H) / 2) + 1 + CY);
			CX := CX + 1;
			Write(Content[I]);
		end;
	end;

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

	UIInvalidateRect(Floor((X - W) / 2), Floor((Y - H) / 2), W, H);
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
	H := LineCount(Content) + 4;
	SetLength(OK, 1);
	OK[0] := 'OK';
	UIPopup(W, H, ScreenWhite, ScreenRed, 'Error', Content, OK);
end;

procedure UIInfo(Content : String);
var
	W : Integer;
	H : Integer;
	OK : Array of String;
begin
	W := 75;
	H := LineCount(Content) + 4;
	SetLength(OK, 1);
	OK[0] := 'OK';
	UIPopup(W, H, ScreenBlack, ScreenWhite, 'Info', Content, OK);
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

procedure UIResize(sig : cint); cdecl;
begin
	UIRedraw();
end;
{$endif}

procedure UIShowWelcome();
var
	Welcome : String;
begin
	Welcome := '';

	Welcome := Welcome + 'Welcome to...' + #10;
	Welcome := Welcome + '<BXTH><BXTB><BXRT><BXSP><BXTH><BXTB><BXRT><BXSP><BXLT><BXTB><BXTH><BXTB><BXRT>' + #10;
	Welcome := Welcome + '<BXLR><BXSP><BXLR><BXSP><BXLR><BXSP><BXSP><BXSP><BXLR><BXSP><BXLR><BXSP><BXLR>' + #10;
	Welcome := Welcome + '<BXLV><BXTB><BXRB><BXSP><BXLV><BXTB><BXRV><BXSP><BXLR><BXSP><BXLR><BXSP><BXLR>' + #10;
	Welcome := Welcome + '<BXLR><BXSP><BXSP><BXSP><BXLR><BXSP><BXSP><BXSP><BXLR><BXSP><BXLR><BXSP><BXLR> - <FGBLUE>Pascal File Manager<POPCOLOR>' + #10;
	Welcome := Welcome + '<BXBH><BXSP><BXSP><BXSP><BXBH><BXSP><BXSP><BXSP><BXBH><BXSP><BXSP><BXSP><BXBH>' + #10;
	Welcome := Welcome + #10;
	Welcome := Welcome + 'Copyright (C) 2025 Nishi and contributors...' + #10;
	Welcome := Welcome + '<FGBLUE>PFM<POPCOLOR> is licensed under the 3-clause BSD license' + #10;
	Welcome := Welcome + #10;
	Welcome := Welcome + 'Version <FGYELLOW><BGBLUE> ' + UIVersion + ' <POPCOLOR><POPCOLOR> - <FGYELLOW><BGBLUE>';
{$ifdef RELEASE}
	Welcome := Welcome + ' Release ';
{$endif}
{$ifdef DEBUG}
	Welcome := Welcome + ' Debug ';
{$endif}
	Welcome := Welcome + '<POPCOLOR><POPCOLOR> Build' + #10;

	UIInfo(Welcome);
end;

procedure UICheckAll();
var
	X : Integer;
	Y : Integer;
	I : Integer;
begin
	if not(InvalidatedRect.Invalidated) then Exit;

	ScreenGetSize(@X, @Y);

	if InvalidatedRect.Y = 0 then
	begin
		ScreenGotoXY(0, 0);
		UIPushColor(ScreenBlack, ScreenCyan);
		for I := 0 to (X - 1) do Write(' ');
		UIPopColor();
	end;

	if (InvalidatedRect.X >= 0) and (InvalidatedRect.X <= (X - ConfigFileAreaWidth)) and ((InvalidatedRect.Y + InvalidatedRect.H) >= 1) then
	begin
		UIBox(0, 1, X - ConfigFileAreaWidth, Y - 1);
	end;

	if ((InvalidatedRect.X + InvalidatedRect.W) >= (X - ConfigFileAreaWidth)) and ((InvalidatedRect.Y + InvalidatedRect.H) >= 1) then
	begin
		UIBox(X - ConfigFileAreaWidth, 1, ConfigFileAreaWidth, 3);
	end;

	if ((InvalidatedRect.X + InvalidatedRect.W) >= (X - ConfigFileAreaWidth)) and ((InvalidatedRect.Y + InvalidatedRect.H) >= (3 + 1)) then
	begin
		UIBox(X - ConfigFileAreaWidth, 3 + 1, ConfigFileAreaWidth, Y - 3 - 1);
	end;

	InvalidatedRect.Invalidated := False;
end;

procedure UIInit();
begin
	SetLength(ColorStack, 0);
	SysSetCtrlBreakHandler(@UIExit);
	AddExitProc(@UIExit2);
{$ifdef unix}
	FpSignal(SIGINT, @UIExit3);
	FpSignal(SIGTERM, @UIExit3);
	FpSignal(SIGWINCH, @UIResize);
{$endif}
	InvalidatedRect.Invalidated := False;
	ScreenInit();
	UIPushColor(ScreenWhite, ScreenBlue);
	UIRedraw();
end;

procedure UILoop();
begin
	while True do
	begin
		UICheckAll();
	end;
end;

end.
