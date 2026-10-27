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


; ---- Botany controls ----
; On a pot with nothing to harvest, the plant and dirt controls sit at the bottom of the
; screen in fixed places. Record each once: hover the control, press the hotkey, pick its
; name from the menu. Saved to [Controls] in BotanyPots.ini, window-relative like the pots.
global BotanyControlNames := ["Harvest", "Next plant", "Previous plant", "Next dirt", "Previous dirt", "Plant"]

RecordBotanyControl()
{
	WinGetPos(,, &WinWidth, &WinHeight, "ahk_exe IdleSkilling.exe")
	MouseGetPos(&XMousePos, &YMousePos)
	xy := Round(XMousePos / WinWidth, 4) "," Round(YMousePos / WinHeight, 4)
	m := Menu()
	for name in BotanyControlNames
		m.Add(name, SaveControl.Bind(name))
	m.Show()

	SaveControl(name, *)
	{
		IniWrite(xy, BotanyPotsFile, "Controls", name)
		BotanyTip(name " recorded")
	}
}

; Returns [X, Y] for a recorded control, or "" if it hasn't been recorded.
BotanyControl(name)
{
	xy := StrSplit(IniRead(BotanyPotsFile, "Controls", name, ""), ",")
	return xy.Length = 2 ? [xy[1] + 0, xy[2] + 0] : ""
}

; Moves the mouse over each recorded control, labelled, without clicking.
PreviewBotanyControls()
{
	WinGetPos(,, &WinWidth, &WinHeight, "ahk_exe IdleSkilling.exe")
	shown := 0
	for name in BotanyControlNames
	{
		c := BotanyControl(name)
		if (c = "")
			continue
		MouseMove(c[1] * WinWidth, c[2] * WinHeight)
		ToolTip(name)
		Sleep 800
		shown++
	}
	BotanyTip(shown ? "Preview done" : "No botany controls recorded yet")
}
