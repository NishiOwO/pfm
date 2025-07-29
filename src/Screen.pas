unit Screen;

interface
type
	TScreenIntegerPointer = ^Integer;

procedure ScreenClear();
procedure ScreenGotoXY(X : Integer; Y : Integer);
function ScreenReadKey() : Word;
procedure ScreenSetFG(FG : Byte);
procedure ScreenSetBG(BG : Byte);
procedure ScreenShowCursor();
procedure ScreenHideCursor();
procedure ScreenGetSize(Width : TScreenIntegerPointer; Height : TScreenIntegerPointer);
procedure ScreenInit();
procedure ScreenDeinit();

const
	ScreenBlack : Integer = 0;
	ScreenRed : Integer = 1;
	ScreenGreen : Integer = 2;
	ScreenYellow : Integer = 3;
	ScreenBlue : Integer = 4;
	ScreenMagenta : Integer = 5;
	ScreenCyan : Integer = 6;
	ScreenWhite : Integer = 7;

implementation
uses
	Keyboard,
	Sysutils,
{$ifdef unix}
	BaseUnix,
	Termio;

var
	OldT : TTermios;

procedure ScreenClear();
begin
	Write(#27 + '[2J' + #27 + '[1;1H');
end;

procedure ScreenGotoXY(X : Integer; Y : Integer);
begin
	Write(#27 + '[' + IntToStr(Y + 1) + ';' + IntToStr(X + 1) + 'H');
end;

function ShouldBeBright(C : Byte) : Boolean;
begin
	if (C = ScreenRed) or (C = ScreenYellow) then ShouldBeBright := True
	else ShouldBeBright := False;
end;

procedure ScreenSetFG(FG : Byte);
begin
	if ShouldBeBright(FG) then Write(#27 + '[' + IntToStr(90 + FG) + 'm')
	else Write(#27 + '[' + IntToStr(30 + FG) + 'm');
end;

procedure ScreenSetBG(BG : Byte);
begin
	if ShouldBeBright(BG) then Write(#27 + '[' + IntToStr(100 + BG) + 'm')
	else Write(#27 + '[' + IntToStr(40 + BG) + 'm');
end;

procedure ScreenShowCursor();
begin
	Write(#27 + '[?25h');
end;

procedure ScreenHideCursor();
begin
	Write(#27 + '[?25l');
end;

procedure ScreenGetSize(Width : TScreenIntegerPointer; Height : TScreenIntegerPointer);
var
	TermSize : TWinSize;
begin
	FPIOCtl(1, TIOCGWINSZ, @TermSize);
	Width^ := TermSize.ws_col;
	Height^ := TermSize.ws_row;
end;

procedure ScreenInit();
var
	NewT : Termios;
begin
	ScreenHideCursor();
	TCGetAttr(1, OldT);
	TCGetAttr(1, NewT);

	NewT.c_lflag := NewT.c_lflag and not(ECHO or ICANON);

	TCSetAttr(1, TCSANOW, NewT);
end;

procedure ScreenDeinit();
begin
	TCSetAttr(1, TCSANOW, OldT);
	ScreenShowCursor();
	ScreenClear();
	Write(#27 + '[m');
end;
{$endif}
{$ifdef windows}
	Windows;

const
	Win32Color : Array of Integer = (0,12,10,12,9,13,8,15);

procedure ScreenClear();
var
	Std : HANDLE;
	CSBI : CONSOLE_SCREEN_BUFFER_INFO;
	TopLeft : COORD;
	ScreenSize : DWORD;
	Written : DWORD;
begin
	Std := GetStdHandle(STD_OUTPUT_HANDLE);
	if not(GetConsoleScreenBufferInfo(Std, @CSBI)) then
	begin
		Exit;
	end;

	ScreenSize := CSBI.dwSize.X * (CSBI.dwSize.Y + 1);

	TopLeft.X := 0;
	TopLeft.Y := 0;
	FillConsoleOutputCharacter(Std, ' ', ScreenSize, TopLeft, @Written);
	FillConsoleOutputAttribute(Std, CSBI.wAttributes, ScreenSize, TopLeft, @Written);

	SetConsoleCursorPosition(Std, TopLeft);
end;

procedure ScreenGotoXY(X : Integer; Y : Integer);
var
	Std : HANDLE;
	C : COORD;
begin
	Std := GetStdHandle(STD_OUTPUT_HANDLE);
	C.X := X;
	C.Y := Y;

	SetConsoleCursorPosition(Std, C);
end;

procedure ScreenSetFG(FG : Byte);
var
	Std : HANDLE;
	CSBI : CONSOLE_SCREEN_BUFFER_INFO;
	C : WORD;
begin
	Std := GetStdHandle(STD_OUTPUT_HANDLE);
	if not(GetConsoleScreenBufferInfo(Std, @CSBI)) then
	begin
		Exit;
	end;

	C := CSBI.wAttributes and $fff0;
	C := C or Win32Color[FG];

	SetConsoleTextAttribute(Std, C);

	SetConsoleTextAttribute(Std, C);
end;

procedure ScreenSetBG(BG : Byte);
var
	Std : HANDLE;
	CSBI : CONSOLE_SCREEN_BUFFER_INFO;
	C : WORD;
begin
	Std := GetStdHandle(STD_OUTPUT_HANDLE);
	if not(GetConsoleScreenBufferInfo(Std, @CSBI)) then
	begin
		Exit;
	end;

	C := CSBI.wAttributes and $ff0f;
	C := C or (Win32Color[BG] shl 4);

	SetConsoleTextAttribute(Std, C);
end;

procedure ScreenShowCursor();
var
	Std : HANDLE;
	CCI : CONSOLE_CURSOR_INFO;
begin
	Std := GetStdHandle(STD_OUTPUT_HANDLE);
	CCI.dwSize := 100;
	CCI.bVisible := TRUE;
	SetConsoleCursorInfo(Std, @CCI);
end;

procedure ScreenHideCursor();
var
	Std : HANDLE;
	CCI : CONSOLE_CURSOR_INFO;
begin
	Std := GetStdHandle(STD_OUTPUT_HANDLE);
	CCI.dwSize := 100;
	CCI.bVisible := FALSE;
	SetConsoleCursorInfo(Std, @CCI);
end;

procedure ScreenGetSize(Width : TScreenIntegerPointer; Height : TScreenIntegerPointer);
var
	Std : HANDLE;
	CSBI : CONSOLE_SCREEN_BUFFER_INFO;
begin
	Std := GetStdHandle(STD_OUTPUT_HANDLE);
	if not(GetConsoleScreenBufferInfo(Std, @CSBI)) then
	begin
		Exit;
	end;

	Width^ := CSBI.srWindow.Right - CSBI.srWindow.Left + 1;
	Height^ := CSBI.srWindow.Bottom - CSBI.srWindow.Top + 1;
end;

procedure ScreenInit();
begin
	SetConsoleCP(437);
	SetConsoleOutputCP(437);
	ScreenHideCursor();
	InitKeyboard();
end;

procedure ScreenDeinit();
begin
	ScreenShowCursor();
	ScreenClear();
end;
{$endif}

function ScreenReadKey() : Word;
var
	K : TKeyEvent;
	C : Word;
begin
	K := GetKeyEvent();
	K := TranslateKeyEvent(K);
	C := Word(GetKeyEventChar(K));
	if C = 10 then C := 13;
	ScreenReadKey := C;
end;

end.
