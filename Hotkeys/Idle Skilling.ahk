SendMode "Input"  				; Recommended for new scripts due to its superior speed and reliability.
CoordMode "Mouse", "Window"  		; Set coordinates of mouse relative to the active window
#Requires AutoHotkey v2.0-beta
#SingleInstance

#include Coordinates.ahk
#include Utils.ahk
#include Spells.ahk
#include Botany.ahk
#include Tinkering.ahk
#include Crusades.ahk
#include Spelunking.ahk
#include Realm.ahk
#include RealmSetups.ahk
#include Smithing.ahk
#include VendingMachine.ahk
#include Hatchery.ahk
#include Asylum.ahk


#HotIf WinActive("Idle Skilling ahk_exe IdleSkilling.exe")


w:: Click(5)

^w:: Repeat("Click")

^!w:: SpamClickSilent


^q:: CheckPos


^c:: SwitchBasicSpells
	
^v:: SwitchAdvancedSpells


Right:: NextFlower

Left:: PrevFlower

^p:: RecordBotanyPot

^!p:: PreviewBotanyPots

^+p:: ClearBotanyPots

^b:: RecordBotanyControl

^!b:: PreviewBotanyControls

^h:: BotanyReplantAll(true)

^!h:: BotanyReplantAll(false)
^a:: BotanyGrowAllNow(true)	; Grow All (dry run)
^!a:: BotanyGrowAllNow(false)	; Grow All: the game plants or harvests each pot by its state, then a report
^!t:: BotanyTestSlots()	; click every plant slot with pot 1 selected (selection only, no Grow)

^g:: BotanyAdvance(true)	; ROUTINE (dry run): harvest, every pot to the next owned plant (wraps to weeds), 1% dirt+seed, Grow All

^!g:: BotanyAdvance(false)	; ROUTINE
^j:: BotanySetPlants(0, true)	; every pot: Next plant arrow only (dry run)
^!j:: BotanySetPlants(0, false)

^f:: BotanySetPlants(-1, true)	; every pot: plant N from the sidebar (asks N; dry run)

^!f:: BotanySetPlants(-1, false)

^l:: BotanyPrefillAll(1, 1, true)	; every pot: 1% dirt + 1% seed (dirt only on weeds; dry run)

^!l:: BotanyPrefillAll(1, 1, false)


s:: KillNextCrusade

^s:: SpamNextCrusade

r:: ResetAndBoost

^r:: SpamBoost


x:: ResetAndOpenTreasures

^x:: SpamTreasures


k:: ResetSetup2

t:: ActivateLaser

m:: CrackTheCode(0)
; 0


d:: FarmTraces

^d:: MaxEverything

c:: MaxLevelUp


a:: HatcheryHatch_Keep

z:: HatcheryTrash

y:: HatcheryUpgradeAll

^y:: SpamHatcheryUpgradeAll


n:: DefeatAsylum

^n:: SpamAsylum


#HotIf

	
^e:: ExitApp