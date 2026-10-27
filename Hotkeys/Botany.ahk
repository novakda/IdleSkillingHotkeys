NextFlower()
{
	ClickRelative(nextFlowerX, nextFlowerY)
}

PrevFlower()
{
	ClickRelative(prevFlowerX, prevFlowerY)
}

; ---- Botany pot positions ----
; Step 1 toward a macro that collects every pot, advances to the next plant, then sets dirt
; and plants. Positions are window-relative (0..1) like Coordinates.ahk, so they survive a
; window resize, and are saved to BotanyPots.ini next to the script so they survive restarts.
; Record them once with the botany screen open: hover a pot, press the record hotkey, repeat.
global BotanyPotsFile := A_ScriptDir "\BotanyPots.ini"

RecordBotanyPot()
{
	WinGetPos(,, &WinWidth, &WinHeight, "ahk_exe IdleSkilling.exe")
	MouseGetPos(&XMousePos, &YMousePos)
	n := IniRead(BotanyPotsFile, "Pots", "Count", 0) + 1
	IniWrite(Round(XMousePos / WinWidth, 4) "," Round(YMousePos / WinHeight, 4), BotanyPotsFile, "Pots", n)
	IniWrite(n, BotanyPotsFile, "Pots", "Count")
	BotanyTip("Pot " n " recorded")
}

ClearBotanyPots()
{
	if (MsgBox("Forget all recorded botany pots?", "Botany", "YesNo") = "Yes")
	{
		try IniDelete(BotanyPotsFile, "Pots")
		BotanyTip("Botany pots cleared")
	}
}

; Returns the recorded pots as an array of [X, Y] window-relative pairs, in recording order.
BotanyPots()
{
	pots := []
	Loop IniRead(BotanyPotsFile, "Pots", "Count", 0)
	{
		xy := StrSplit(IniRead(BotanyPotsFile, "Pots", A_Index, ""), ",")
		if (xy.Length = 2)
			pots.Push([xy[1] + 0, xy[2] + 0])
	}
	return pots
}

; Moves the mouse over each recorded pot in order, without clicking, to check the recording.
PreviewBotanyPots()
{
	pots := BotanyPots()
	if (!pots.Length)
	{
		BotanyTip("No botany pots recorded yet")
		return
	}
	WinGetPos(,, &WinWidth, &WinHeight, "ahk_exe IdleSkilling.exe")
	for i, pot in pots
	{
		MouseMove(pot[1] * WinWidth, pot[2] * WinHeight)
		ToolTip("Pot " i " of " pots.Length)
		Sleep 600
	}
	BotanyTip("Preview done")
}

BotanyTip(text)
{
	ToolTip(text)
	SetTimer(() => ToolTip(), -1200)
}
