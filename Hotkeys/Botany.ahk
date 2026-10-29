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
; Record each once: hover the control, press Ctrl+B, pick its name from the menu (sidebar plant icons are under
; "Plant slot"). Saved to [Controls] in BotanyPots.ini, window-relative like the pots. Grow, Next plant, Blank area
; and Grow All fall back to the game layout below when not recorded; every other control must be recorded before a macro
; uses it (a macro stops before its first click if one is missing). The Grow / plant / Dirt / Flower controls only
; show on a selected EMPTY pot, so record them with one selected.
global BotanyControlNames := ["Blank area", "Grow All", "Grow", "Next plant", "Previous plant", "Next dirt", "Previous dirt"
	, "Dirt max", "Dirt down", "Dirt interval", "Dirt up", "Flower max", "Flower down", "Flower interval", "Flower up"]
global BotanySlotCount := 24	; right-sidebar plant slots: a 2x12 grid, numbered down column 1 (1-12) then column 2 (13-24)

RecordBotanyControl()
{
	WinGetPos(,, &WinWidth, &WinHeight, "ahk_exe IdleSkilling.exe")
	MouseGetPos(&XMousePos, &YMousePos)
	xy := Round(XMousePos / WinWidth, 4) "," Round(YMousePos / WinHeight, 4)
	m := Menu()
	for name in BotanyControlNames
		m.Add(name, SaveControl.Bind(name))
	slots := Menu()
	Loop BotanySlotCount
		slots.Add("Slot " A_Index, SaveSlot.Bind(A_Index))
	m.Add("Plant slot (right sidebar)", slots)
	m.Show()

	SaveControl(name, *)
	{
		IniWrite(xy, BotanyPotsFile, "Controls", name)
		BotanyTip(name " recorded")
	}

	; A slot also stores its pixel colour, sampled with the mouse moved off it (in case of hover effects), so the
	; macros can tell later whether that icon is still there.
	SaveSlot(n, *)
	{
		MouseGetPos(&mx, &my)
		away := BotanyPoint("Blank area")
		MouseMove(away[1], away[2], 0)
		Sleep 200
		CoordMode("Pixel", "Window")
		color := PixelGetColor(XMousePos, YMousePos)
		MouseMove(mx, my, 0)
		IniWrite(xy "," color, BotanyPotsFile, "Controls", "Slot " n)
		BotanyTip("Slot " n " recorded (" color ")")
	}
}

; Returns [X, Y] (plus the recorded colour, for a slot) for a recorded control, or "" if it hasn't been recorded.
BotanyControl(name)
{
	v := StrSplit(IniRead(BotanyPotsFile, "Controls", name, ""), ",")
	if (v.Length < 2)
		return RegExMatch(name, "^Slot (\d+)$", &m) ? BotanySlotFromGrid(m[1] + 0) : ""
	for i, x in v
		v[i] := x + 0
	return v
}

; An unrecorded slot's position, derived from the recorded ones: the row step from the two recorded slots furthest
; apart, the column's X from the recorded slots in that column. Returns [X, Y] with no colour, or "" if there isn't
; enough recorded yet (needs two rows recorded somewhere, and one slot in the wanted column).
; ponytail: assumes even row spacing; record a slot by hand if a derived one lands off its icon.
BotanySlotFromGrid(n)
{
	rec := Map()
	Loop BotanySlotCount
	{
		v := StrSplit(IniRead(BotanyPotsFile, "Controls", "Slot " A_Index, ""), ",")
		if (v.Length >= 2)
			rec[A_Index] := [v[1] + 0, v[2] + 0]
	}
	row := (k) => Mod(k - 1, 12)
	col := (k) => (k - 1) // 12
	lo := 0, hi := 0
	for k in rec
	{
		if (!lo || row(k) < row(lo))
			lo := k
		if (!hi || row(k) > row(hi))
			hi := k
	}
	if (!lo || row(hi) = row(lo))
		return ""
	step := (rec[hi][2] - rec[lo][2]) / (row(hi) - row(lo))
	y := rec[lo][2] + (row(n) - row(lo)) * step
	sx := 0, cnt := 0
	for k, p in rec
		if (col(k) = col(n))
			sx += p[1], cnt++
	return cnt ? [sx / cnt, y] : ""
}

; Moves the mouse over each control a macro would use (recorded or layout default) and each recorded slot, labelled, without clicking.
PreviewBotanyControls()
{
	names := BotanyControlNames.Clone()
	Loop BotanySlotCount
		names.Push("Slot " A_Index)
	shown := 0
	for name in names
	{
		try p := BotanyPoint(name)
		catch
			continue
		MouseMove(p[1], p[2])
		c := BotanyControl(name)
		ToolTip(name (!IsObject(c) ? " (layout default)" : (InStr(name, "Slot ") = 1 && c.Length < 3) ? " (from the grid)" : ""))
		Sleep 800
		shown++
	}
	BotanyTip(shown ? "Preview done" : "No botany controls recorded yet")
}


; ---- Game layout, pixel state and click helpers ----
; Positions are the game's own 960x544 layout (Qno2x.js scene 36, decoded 2026-10-26). The
; game window draws its own title bar ABOVE that layout (~29px at 958x572), so layout points
; are converted with BotanyWin(), which scales to the window width and adds the bar height.
global BotanyNextPlant := [668, 420]	; next-plant arrow center (box 647,400 43x40)
global BotanyGrowButton := [628, 467]	; Plant/Harvest button center (box 589,448 78x38)
global BotanyDeselect := [705, 200]	; empty spot that deselects the pot
global BotanyGrowAll := [116, 399]	; Grow All button center, no pot selected (CDP screenshot 2026-10-26, 958x572 window)
global BotanyLayoutDefaults := Map("Grow", BotanyGrowButton, "Next plant", BotanyNextPlant, "Blank area", BotanyDeselect, "Grow All", BotanyGrowAll)
global BotanyGame := "Idle Skilling ahk_exe IdleSkilling.exe"

; Game layout point -> window point, as [X, Y].
BotanyWin(pt)
{
	WinGetPos(,, &WinWidth, &WinHeight, "ahk_exe IdleSkilling.exe")
	s := WinWidth / 960
	return [Round(pt[1] * s), Round(WinHeight - 544 * s + pt[2] * s)]
}

; Window-relative fraction [0..1, 0..1] -> window point, as [X, Y].
BotanyFrac(f)
{
	WinGetPos(,, &WinWidth, &WinHeight, "ahk_exe IdleSkilling.exe")
	return [Round(f[1] * WinWidth), Round(f[2] * WinHeight)]
}

; Window point for a named control: its recording, else the layout default, else an error.
BotanyPoint(name)
{
	c := BotanyControl(name)
	if (IsObject(c))
		return BotanyFrac(c)
	if (BotanyLayoutDefaults.Has(name))
		return BotanyWin(BotanyLayoutDefaults[name])
	throw Error("'" name "' is not recorded yet (Ctrl+B)")
}

; Clicks window point xy, then waits for the game's UI. Dry run: moves the mouse there with a label instead.
; Throws when the game isn't the active window, so a macro never clicks into something else.
BotanyDo(xy, label, dryRun, wait := 300)
{
	if (!WinActive(BotanyGame))
		throw Error("Idle Skilling is not the active window (before: " label ")")
	if (dryRun)
	{
		MouseMove(xy[1], xy[2])
		ToolTip("would click: " label)
		Sleep 700
		return
	}
	ClickAny(xy[1], xy[2], 1)
	Sleep wait
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
			y += 6
		}
		x += 6
	}
	best := "unknown", top := 4	; ~55 samples at a 6 px step (was 189 at 3 px, threshold 14)
	for name, n in votes
		if (n > top)
			best := name, top := n
	return best
}

; True if sidebar slot n still shows the icon it had when recorded (each colour channel within the tolerance).
; ponytail: one pixel vs the recorded colour; if two plants match at that pixel, check FlowerTypeSELECTED over CDP instead.
global BotanySlotTolerance := 40
BotanySlotPresent(n)
{
	; Slot n is plant n at a fixed spot (unowned plants leave a gap; slot test 2026-10-29), so the game's own count
	; answers this when the debug connection is up. Pixel colour is the fallback.
	owned := BotanyOwned()
	if (IsObject(owned))
		return n + 1 <= owned.Length && owned[n + 1] > 0
	c := BotanyControl("Slot " n)
	if (!IsObject(c))
		throw Error("Slot " n " is not recorded, and the grid can't place it yet (record one slot in its column)")
	if (c.Length < 3)
		return true	; derived from the grid: no recorded colour to compare, so this click is unverified
	p := BotanyFrac(c)
	CoordMode("Pixel", "Window")
	px := PixelGetColor(p[1], p[2])
	d := 0
	for s in [16, 8, 0]
		d := Max(d, Abs(((px >> s) & 0xFF) - ((c[3] >> s) & 0xFF)))
	return d <= BotanySlotTolerance
}

; Pot states over CDP from the toolbox helper (bun src/botany-state.ts, in WSL): an array by pot number of
; {plant, state} (state empty / growing / ready), or "" when it can't be read (game not started from the
; "Idle Skilling (debug)" shortcut, WSL not up, ...). Read-only. Used to skip runs with nothing to do and as a
; second opinion; the pixel check still gates every Grow click.
; flowersOwned over CDP (index 0 = plant 0, so plant n is element n + 1), or "" when it can't be read.
BotanyOwned()
{
	static cache := "", at := 0
	if (IsObject(cache) && A_TickCount - at < 30000)	; one read per run, not one per pot
		return cache
	out := A_Temp "\botany-owned.json"
	try FileDelete(out)
	try
	{
		RunWait(A_ComSpec ' /c ' BotanyStateCmd ' > "' out '" 2>nul',, "Hide")
		json := FileRead(out)
	}
	catch
		return ""
	if (!RegExMatch(json, '"owned":\[([^\]]*)\]', &m))
		return ""
	owned := []
	for v in StrSplit(m[1], ",")
		owned.Push(IsNumber(v) ? v + 0 : 0)
	cache := owned, at := A_TickCount
	return owned
}

; Polls pot states over CDP until every pot satisfies ok(pot) or timeoutMs passes; returns the last read
; ("" when CDP is down: then it just waits a fixed 1 s per pot, since Grow All goes pot by pot).
BotanyWaitPots(ok, timeoutMs)
{
	start := A_TickCount
	loop
	{
		st := BotanyLiveState()
		if (!IsObject(st))
		{
			Sleep 1000 * BotanyPots().Length
			return ""
		}
		done := true
		for p in st
			if (!ok(p))
				done := false
		if (done || A_TickCount - start > timeoutMs)
			return st
		ToolTip("Waiting for Grow All to finish...")
		Sleep 500
	}
}

; The plant the selected pot is set to grow (FlowerTypeSELECTED[PotSelected]) over CDP, or 0 if unknown.
BotanySelectedPlant()
{
	out := A_Temp "\botany-sel.json"
	try FileDelete(out)
	try
	{
		RunWait(A_ComSpec ' /c ' BotanyStateCmd ' > "' out '" 2>nul',, "Hide")
		json := FileRead(out)
	}
	catch
		return 0
	if (!RegExMatch(json, '"selectedPot":(\d+)', &p) || !RegExMatch(json, '"sel":\[([^\]]*)\]', &m))
		return 0
	sel := StrSplit(m[1], ",")
	n := p[1] + 1
	return n <= sel.Length && IsNumber(sel[n]) ? sel[n] + 0 : 0
}

global BotanyStateCmd := 'wsl.exe -e bash -lc "cd ~/projects/idle-skilling-toolbox && bun src/botany-state.ts"'
BotanyLiveState()
{
	out := A_Temp "\botany-state.json"
	try FileDelete(out)
	try
	{
		RunWait(A_ComSpec ' /c ' BotanyStateCmd ' > "' out '" 2>nul',, "Hide")
		json := FileRead(out)
	}
	catch
		return ""
	pots := [], pos := 1
	while (pos := RegExMatch(json, '"plant":(\d+),"state":"(\w+)"', &m, pos))
		pots.Push({plant: m[1] + 0, state: m[2]}), pos += m.Len
	return pots.Length ? pots : ""
}


; ---- Botany macros ----
; Ctrl+E stops any of them (it exits the script).
BotanyReplantAll(dryRun := true) => BotanyRun(false, 0, dryRun)		; empty pots: next plant
BotanyCollectAndReplant(dryRun := true) => BotanyRun(true, 0, dryRun)	; Scenario 1: Grow All, then next plant

; Scenario 2: Grow All, then plant sidebar slot `slot` (asks which when 0).
BotanyCollectAndPlant(slot := 0, dryRun := true)
{
	if (!slot)
	{
		r := InputBox("Sidebar plant slot to plant (1-" BotanySlotCount "):", "Botany", "w260 h110", 1)
		if (r.Result != "OK" || !IsInteger(r.Value) || r.Value < 1 || r.Value > BotanySlotCount)
			return
		slot := r.Value + 0
	}
	BotanyRun(true, slot, dryRun)
}

; One pass over the recorded pots, in order.
; collect: first click the blank area (deselects the pot, shows Grow All) and Grow All.
; slot: 0 = the Next plant arrow (next plant in order; seed/flower amounts unchanged), N = sidebar plant slot N.
; The Grow button UPROOTS a growing pot, so a pot is planted only when its button reads EMPTY at that moment.
; Dry run: selects each pot to read it (harmless, as before) but only points at every other click.
BotanyRun(collect, slot, dryRun)
{
	pots := BotanyPots()
	if (!pots.Length)
		return BotanyTip("No botany pots recorded yet (Ctrl+P)")
	title := dryRun ? "Botany dry run" : "Botany"
	pick := slot ? "Slot " slot : "Next plant"
	live := BotanyLiveState()
	if (IsObject(live))
	{
		empty := 0, ready := 0
		for p in live
			empty += (p.state = "empty"), ready += (p.state = "ready")
		; Grow All clears every occupied pot, growing or ready, and growing pots still yield (Dan, 2026-10-29).
		if (!empty && !(collect && empty < live.Length))
			return MsgBox("Nothing to do: no pot is empty" (collect ? " or ready" : "") " (read over CDP).", title)
	}
	what := (collect ? "Collect all (Grow All), then plant " : "Plant ") (slot ? "sidebar slot " slot : "the next plant") " in every EMPTY pot?"
	if (!dryRun && MsgBox(what "`nGrowing pots are skipped. Ctrl+E stops.", title, "YesNo") != "Yes")
		return
	WinActivate(BotanyGame)
	Sleep 200
	report := IsObject(live) ? "" : "(CDP state unavailable: pixel check only)`n"
	try
	{
		; Resolve every point first, so a missing recording stops before the first click.
		pickXY := BotanyPoint(pick), growXY := BotanyPoint("Grow")
		if (collect)
		{
			blankXY := BotanyPoint("Blank area"), allXY := BotanyPoint("Grow All")
			BotanyDo(blankXY, "blank area (shows Grow All)", dryRun)
			BotanyDo(allXY, "Grow All", dryRun, 1500)
		}
		; One CDP read for every pot's state (after Grow All has collected); the per-pot pixel check
		; (~190 pixel reads, seconds per pot) is only the fallback when the debug connection is down.
		; Grow All works through the pots one at a time (Dan), so wait until it has finished harvesting.
		now := (collect && !dryRun) ? BotanyWaitPots((p) => p.state = "empty", 60000) : live
		for i, pot in pots
		{
			BotanyDo(BotanyFrac(pot), "pot " i, false, 250)
			state := (IsObject(now) && i <= now.Length) ? now[i].state : BotanyPotState()
			if (state = "unknown")
				throw Error("can't read pot " i "'s button (Botany screen open? pot positions right?)")
			willCollect := dryRun && collect && (state = "ready" || state = "overgrown")
			if (state != "empty" && !willCollect)
			{
				report .= "Pot " i ": " state ", skipped`n"
				continue
			}
			if (!collect && IsObject(live) && i <= live.Length && live[i].state != "empty")
			{
				report .= "Pot " i ": CDP says " live[i].state ", skipped`n"
				continue
			}
			if (slot && !BotanySlotPresent(slot))
				throw Error("sidebar slot " slot " doesn't show its plant (none owned, or the sidebar moved)")
			BotanyDo(pickXY, pick, dryRun, 250)
			if (collect)	; set only; the second Grow All below plants every pot at once
				report .= "Pot " i ": " (dryRun ? state (willCollect ? " (Grow All would collect it)" : "") ", would set" : "set") "`n"
			else
			{
				BotanyDo(growXY, "Grow", dryRun, 100)	; Dan: after Grow, move straight on
				report .= "Pot " i ": " (dryRun ? state ", would plant" : "planted") "`n"
			}
		}
		; Grow All harvests when pots are ready and plants when they're empty (Dan, 2026-10-29), so a second
		; press plants every pot with what it was just set to.
		if (collect)
		{
			BotanyDo(blankXY, "blank area (shows Grow All)", dryRun)
			BotanyDo(allXY, "Grow All (plants every pot)", dryRun, 1000)
			if (!dryRun)
				BotanyWaitPots((p) => p.state != "empty", 60000)
		}
	}
	catch Error as e
		report .= "STOPPED: " e.Message "`n"
	ToolTip()
	try BotanyDo(BotanyPoint("Blank area"), "deselect", false, 200)
	if (!dryRun && IsObject(after := BotanyLiveState()))
	{
		report .= "Plant per pot now (CDP):"
		for p in after
			report .= " " p.plant
	}
	MsgBox(report, title)
}

; PREFILL PLANTS AND SEEDS on the selected EMPTY pot: for Dirt, then Flower (the previous plant): Max (25%),
; Down x BotanyPrefillDowns, pick the interval, then Up pct/interval times. Dan uses 1% of each.
global BotanyPrefillStep := 1		; % per Up click at the recorded interval
global BotanyPrefillDowns := 4	; Down clicks after Max
BotanyPrefill(dirtPct := 1, flowerPct := 1, dryRun := true)
{
	title := dryRun ? "Botany prefill dry run" : "Botany prefill"
	if (!dryRun && MsgBox("Set dirt to " dirtPct "% and flowers to " flowerPct "% on the selected pot?", title, "YesNo") != "Yes")
		return
	WinActivate(BotanyGame)
	Sleep 200
	try
	{
		pts := Map()
		for field in ["Dirt", "Flower"]
			for c in ["max", "down", "interval", "up"]
				pts[field " " c] := BotanyPoint(field " " c)
		if (BotanyPotState() != "empty")
			throw Error("select an EMPTY pot first (the amount controls only show there)")
		; Weeds (plant 1) have no prior plant, so there is no flower selector: dirt only. Unknown (no CDP): both.
		plant := BotanySelectedPlant()
		steps := plant = 1 ? Map("Dirt", dirtPct) : Map("Dirt", dirtPct, "Flower", flowerPct)
		if (plant = 1)
			BotanyTip("Weeds selected: dirt only")
		for field, pct in steps
		{
			BotanyDo(pts[field " max"], field " max", dryRun)
			Loop BotanyPrefillDowns
				BotanyDo(pts[field " down"], field " down " A_Index, dryRun, 150)
			BotanyDo(pts[field " interval"], field " interval", dryRun)
			Loop Round(pct / BotanyPrefillStep)
				BotanyDo(pts[field " up"], field " up " A_Index, dryRun, 150)
		}
		ToolTip()
		BotanyTip(dryRun ? "Prefill dry run done" : "Prefilled")
	}
	catch Error as e
	{
		ToolTip()
		MsgBox("Stopped: " e.Message, title)
	}
}

; Test the plant slots: select pot 1, then click each sidebar slot 1-24 in turn (1.5 s apart) and tooltip which one.
; Selecting a plant only changes what the pot will grow next; nothing is planted (no Grow click). Ctrl+E stops.
BotanyTestSlots()
{
	try
	{
		pots := BotanyPots()
		if (!pots.Length)
			throw Error("no pots recorded")
		BotanyDo(BotanyFrac(pots[1]), "pot 1", false, 600)
		Loop BotanySlotCount
		{
			try xy := BotanyPoint("Slot " A_Index)
			catch
			{
				BotanyTip("Slot " A_Index ": no position, skipped")
				Sleep 800
				continue
			}
			ToolTip("Slot " A_Index)
			BotanyDo(xy, "slot " A_Index, false, 1500)
		}
		BotanyTip("Slot test done")
	}
	catch as e
		BotanyTip("Slot test stopped: " e.Message)
}
