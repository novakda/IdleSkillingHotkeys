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
; Positions are the game's own 960x544 layout (Qno2x.js scene 36, decoded 2026-10-26). The
; game window draws its own title bar ABOVE that layout (~29px at 958x572), so layout points
; are converted with BotanyWin(), which scales to the window width and adds the bar height.
; The Plant/Harvest button UPROOTS a growing pot and loses its progress, so this only acts on
; pots whose button shows the empty/Plant frame. Ready pots are skipped too: harvesting isn't
; wired in yet. Seed and flower amounts are left alone; the game stores them per pot.
global BotanyNextPlant := [668, 420]	; next-plant arrow center (box 647,400 43x40)
global BotanyGrowButton := [628, 467]	; Plant/Harvest button center (box 589,448 78x38)
global BotanyDeselect := [705, 200]	; empty spot that deselects the pot

; Game layout point -> window point, as [X, Y].
BotanyWin(pt)
{
	WinGetPos(,, &WinWidth, &WinHeight, "ahk_exe IdleSkilling.exe")
	s := WinWidth / 960
	return [Round(pt[1] * s), Round(WinHeight - 544 * s + pt[2] * s)]
}

BotanyClick(pt)
{
	w := BotanyWin(pt)
	ClickAny(w[1], w[2], 1)
}

; Reads the Plant/Harvest button's frame by voting over a patch of pixels around it, so the
; text on the button and a few pixels of misalignment don't matter. Frames (sprite-1133-0.png):
; pale green = empty (Plant), red = growing, strong green = ready, blue = ready + overgrown.
; Returns empty / growing / ready / overgrown, or "unknown" (no button, e.g. no pot selected).
; Checked against the four sprite frames and two live screenshots on 2026-10-26.
BotanyPotState()
{
	CoordMode("Pixel", "Window")
	c := BotanyWin(BotanyGrowButton)
	votes := Map("empty", 0, "growing", 0, "ready", 0, "overgrown", 0)
	x := c[1] - 30
	while (x <= c[1] + 30)
	{
		y := c[2] - 12
		while (y <= c[2] + 12)
		{
			px := PixelGetColor(x, y)
			r := (px >> 16) & 0xFF, g := (px >> 8) & 0xFF, b := px & 0xFF
			sat := Max(r, g, b) - Min(r, g, b)
			if (g >= r && g >= b && g > 140 && sat >= 25 && sat < 60)
				votes["empty"]++
			else if (sat >= 60)
			{
				if (r >= g && r >= b)
					votes["growing"]++
				else if (b >= g && b >= r)
					votes["overgrown"]++
				else
					votes["ready"]++
			}
			y += 3
		}
		x += 3
	}
	best := "unknown", top := 14
	for name, n in votes
		if (n > top)
			best := name, top := n
	return best
}

; dryRun: selects each pot and reads its state; plants nothing.
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
		Sleep 400
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
		BotanyClick(BotanyNextPlant)
		Sleep 250
		BotanyClick(BotanyGrowButton)
		Sleep 500
		report .= "Pot " i ": planted, now " BotanyPotState() "`n"
	}
	BotanyClick(BotanyDeselect)
	MsgBox(report, dryRun ? "Botany dry run" : "Botany replant")
}
