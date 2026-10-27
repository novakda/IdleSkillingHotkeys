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


; ---- Botany replant macro (v1: empty pots only) ----
; Positions come from the game's 960x544 layout (Qno2x.js scene 36, decoded 2026-10-26):
; next-plant arrow (647,400), Plant/Harvest button (589,448) 78x38, deselect spot (705,200).
; The Plant/Harvest button UPROOTS a growing pot and loses its progress, so this only acts on
; pots whose button shows the empty/Plant frame, read from a pixel on the button. Ready pots
; are skipped too: harvesting isn't wired in yet. Seed and flower amounts are left alone; the
; game stores them per pot.
global BotanyNextPlant := [0.696, 0.772]
global BotanyGrowButton := [0.654, 0.858]
global BotanyGrowProbe := [0.624, 0.858]	; a pixel 10px in from the button's left edge
global BotanyDeselect := [0.734, 0.368]
; Frame colors sampled from sprite-1133-0.png at that probe point.
global BotanyFrameColors := Map("empty", 0xD0FFCE, "growing", 0xFB7070, "ready", 0x44F761, "overgrown", 0x53CAFF)

; Returns empty / growing / ready / overgrown, or "unknown" if the probe matches none closely.
BotanyPotState()
{
	CoordMode("Pixel", "Window")
	WinGetPos(,, &WinWidth, &WinHeight, "ahk_exe IdleSkilling.exe")
	c := PixelGetColor(BotanyGrowProbe[1] * WinWidth, BotanyGrowProbe[2] * WinHeight)
	best := "unknown", bestD := 60
	for name, ref in BotanyFrameColors
	{
		d := Abs((c >> 16) - (ref >> 16)) + Abs(((c >> 8) & 0xFF) - ((ref >> 8) & 0xFF)) + Abs((c & 0xFF) - (ref & 0xFF))
		if (d < bestD)
			best := name, bestD := d
	}
	return best
}

; dryRun: moves the mouse and reads each pot's state, clicks nothing except selecting pots.
; Live: for each EMPTY pot, advance to the next plant and plant it. Ctrl+E stops the script.
BotanyReplantAll(dryRun := true)
{
	pots := BotanyPots()
	if (!pots.Length)
	{
		BotanyTip("No botany pots recorded yet (Ctrl+P)")
		return
	}
	if (!dryRun && MsgBox("Plant the next plant in every EMPTY pot?`nGrowing and ready pots are skipped.", "Botany", "YesNo") != "Yes")
		return
	report := ""
	for i, pot in pots
	{
		ClickRelative(pot[1], pot[2])
		Sleep 300
		state := BotanyPotState()
		if (state != "empty")
		{
			report .= "Pot " i ": " state ", skipped`n"
			continue
		}
		if (dryRun)
		{
			report .= "Pot " i ": empty, would advance + plant`n"
			continue
		}
		ClickRelative(BotanyNextPlant[1], BotanyNextPlant[2])
		Sleep 250
		ClickRelative(BotanyGrowButton[1], BotanyGrowButton[2])
		Sleep 400
		after := BotanyPotState()
		report .= "Pot " i ": planted, now " after "`n"
	}
	ClickRelative(BotanyDeselect[1], BotanyDeselect[2])
	MsgBox(report, dryRun ? "Botany dry run" : "Botany replant")
}
