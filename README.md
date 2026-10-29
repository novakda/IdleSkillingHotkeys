# IdleSkillingHotkeys - AutoClicker

Those scripts are a bunch of hotkeys I created for the game Idle Skilling (steam version).

While admins on the official discord do not make the following distinction, I believe that
a HotKey is very different from scripting. While creating those Hotkeys, I focus entirely on removing
a boring aspect of the game while not gaining any advantage on other players.
For example, being able to open treasure bags, boost your tinkering gear, or simply change your flower to the next one
without clicking 6000000000 times. This does not gain time, simply gets rid of your boredom.

Remember that there are a lot of issues with those scripts, you can notify them to me in the 'Issues' tab of this repository.
Same goes for suggestions/changes.


## Requirements

AHK v2 needs to be installed. [Click here](https://www.autohotkey.com/v2/) to install it.
Idle Skilling is obviously recommended. Those shortcuts are for the steam version.

## Usage

Start the script ```Idle Skilling.ahk``` (double click on it).
You can edit the scripts as much as you like by opening them with a text editor.
You can change the hotkeys in the ```Idle Skilling.ahk``` file.
If the change is relevant for everyone, don't hesitate creating an issue on this repository, I will make the change.

## Hotkeys

|Keys|Area|Effect|
|:-----:|:---:|---|
|`W`|Any|Click 5 times at the position of your mouse. Holding it will spam click|
|`Ctrl + W`|Any|Toggle hotkey for the 'Click' action. It spams Click at the current cursor location. See Toggle section|
|`Ctrl + Alt + W`|Any|Toggle hotkey for the 'Click' action. It spams Click at the initial cursor location. Do not forget to toggle off when done|
|`Ctrl + Q`|Any|Give mouse location. Debug purpose|
|`Ctrl + E`|Any|Close the script and disable any ongoing hotkey. Very useful if fail|
|`Ctrl + C`|Battle|Switch the first line of spells. I am aware that it already exists a hotkey for that, but it is slow|
|`Ctrl + V`|Battle|Switch the second line of spells. Same than above, the provided hotkey are slow|
|`1`, `2`, `3`, `4`, `5`|Battle|Spell 1 to 5. I did not override those hotkeys, they are already included into the game and work very well.|
|`C`|Smithing|Craft 1000M of the selected item.|
|`D`|Smithing|Farm traces. It will go through all items and craft ~5k items|
|`Ctrl + D`|Smithing|Go through all items and craft 1000M items|
|`Right Arrow`|Botany|Change flower to the next one|
|`Left Arrow`|Botany|Change flower to the previous one|
|`Ctrl + P`|Botany|Record the botany pot under the mouse (next number). Saved to BotanyPots.ini|
|`Ctrl + Alt + P`|Botany|Preview: move the mouse over every recorded pot in order, no clicks|
|`Ctrl + Shift + P`|Botany|Forget all recorded pots|
|`Ctrl + B`|Botany|Record the control under the mouse: pick its name from the menu (sidebar plant icons are under Plant slot). See Botany macros|
|`Ctrl + Alt + B`|Botany|Preview: move the mouse over every control the macros use, labelled, no clicks|
|`Ctrl + H`|Botany|Dry run: select each pot, read whether it is empty/growing/ready, report what it would do. Plants nothing|
|`Ctrl + Alt + H`|Botany|Replant: for every EMPTY pot, advance to the next plant and plant it. Growing and ready pots are skipped (the Plant button uproots growing pots)|
|`Ctrl + Alt + G`|Botany|**The routine, one keystroke:** harvest every pot (Grow All, waits until all are empty), set every pot to the NEXT plant you own from the sidebar (after the last, back to weeds), set 1% seed only when leaving weeds (the game keeps dirt and seed amounts), then Grow All to plant. Ends with a tooltip listing each pot's plant. Asks first only if a pot hasn't finished a growth cycle (it would yield nothing)|
|`Ctrl + G`|Botany|Dry run of the routine: points at each click with a tooltip, changes nothing|
|`Ctrl + Alt + R`|Botany|Reset: harvest, every pot back to weeds (sidebar slot 1), Grow All. `Ctrl + Shift + Alt + R` is the dry run|
|`Ctrl + J` / `Ctrl + Alt + J`|Botany|Every pot: click the Next plant arrow (no Grow). Dry run / live|
|`Ctrl + F` / `Ctrl + Alt + F`|Botany|Every pot: set plant N from the sidebar (asks N; slot N = plant N; stops if you don't own it). No Grow. Dry run / live|
|`Ctrl + L` / `Ctrl + Alt + L`|Botany|Every pot: 1% dirt and 1% seed (dirt only on weeds): 25%, Down x4, 1%, Up. Dry run / live|
|`Ctrl + A` / `Ctrl + Alt + A`|Botany|Grow All: the game runs its own per-pot Grow (plants empty pots, harvests planted ones), the macro waits and reports. Dry run / live|
|`Ctrl + Alt + T`|Botany|Slot test: select pot 1 and click every sidebar plant slot in turn (selection only, no Grow)|
|`S`|Crusade|Defeat a crusade and goes next|
|`Ctrl + S`|Crusade|Toggle action for the action above (crusade + next)|
|`R`|Boost|Maybe the most useful one. It resets and boosts your gear|
|`Ctrl + R`|Boost|Toggle hotkey for the action above (tinkering boost). Useful to increase boostio level|
|`X`|Spelunking|Extract, open bags and jump again|
|`Ctrl + X`|Spelunking|Toggle hotkey for the action above (bag extraction)|
|`K`|Realm|Create all the needed minions for you. More information in the Realm section|
|`T`|Realm|Activate tower laser and comes back to the middle panel.|
|`A`|Hatchery|Press on Hatch or Keep when on an nest with eggs|
|`Z`|Hatchery|Press on Trash when on an nest with eggs|
|`Y`|Hatchery|Upgrade the nest. It will ask for how many crowns you want, and your multi level|
|`Ctrl + Y`|Hatchery|Toggle hotkey for the action above (nest prestige)|
|`N`|Asylum boss|Knock Knock then defeats the boss. Compatible with Gorshank. Probably doesn't work with long animation raids (sentinel)|
|`Ctrl + N`|Asylum boss|Toggle hotkey for the action above (asylum boss)|

## Botany macros

How it works (learned 2026-10-29): Grow All is the game's own per-pot Grow run in a loop, about 0.65 s per pot;
on an empty pot it plants, on a planted pot it harvests (a pot yields once it has finished one growth cycle).
The sidebar has 24 plant slots in a 2x12 grid (column 1 = plants 1-12, column 2 = 13-24); each plant has a
fixed slot, and plants you don't own leave a gap. Weeds (plant 1) take dirt only; every later plant also takes
the previous plant as seed. The game keeps each pot's last dirt and seed amounts.

One-time recording, on the Botany screen (`Ctrl + Alt + P` / `Ctrl + Alt + B` check them without clicking):

1. Pots: hover each pot in order and press `Ctrl + P` (done: 14 pots in BotanyPots.ini).
2. With no pot selected: `Ctrl + B` > Blank area, and Grow All (it has a built-in default).
3. Select a pot set to a plant after weeds, so both amount selectors show. With `Ctrl + B`, record Grow, Next plant,
   and dirt/flower down and up. The interval row (1, 1k, 1m, 1b, 1%, 5%, 25%) is shared by both and already in
   BotanyPots.ini.
4. Sidebar: record slot 1, slot 12 and slot 13 (`Ctrl + B` > Plant slot); the rest are placed from the grid.
   `Ctrl + Alt + T` checks them all.
5. Dry-run first (`Ctrl + G`, `Ctrl + Shift + Alt + R`), then the live keys.

Safety: every click checks the game is the active window; a missing recording stops a macro before its first click;
`Ctrl + E` stops everything. The macros read the game over CDP (below) to know each pot's state and plant and what
you own; without the debug connection, the routine refuses to run and the other macros fall back to pixel checks.

### OCR or CDP instead of pixels?

- **OCR:** yes, AutoHotkey v2 can call the built-in Windows OCR (Windows.Media.Ocr) through the community `OCR.ahk` library (Descolada). It works on screen pixels, so it breaks on the same things as pixel checks (scale, overlays) and is slower.
- **CDP (recommended):** the game is an Electron app. Started from the `Idle Skilling (debug)` shortcut (`--remote-debugging-port=9333`), its state can be read directly. The macros already do this when it is available: they run `bun src/botany-state.ts` from the idle-skilling-toolbox repo in WSL, which prints each pot's plant (`FlowerType`) and state (empty / growing / ready, from `HerbloreAnimationOVERGROWTH`) plus `flowersOwned`, read-only. It also reads `FlowerTypeSELECTED` (what each pot is set to grow). The macros use it to skip runs with nothing to do, pick the next owned plant, wait for Grow All to finish, and report each pot afterwards.

## Realm - Setups

You can provide a setup that will automatically be created/leveled up for you
- You need to have exactly one pet in your barn (to not be interrupted by the first boss death after a reset)
- You can decide the pets to create in ```RealmSetup.ahk```:
  - Provide the list of pet names. They will be created in order, and it does not include the first pet (the one already in the barn)
- Feel free to create/ask for new setups.

> **Warning**
>
> Scissarus will completely mess up the level up of all the minions that are created after it. It is recommended to either
> create Scissarus last, or to temporarily create a Lizardman instead, and level it up by hand. There is no way to fix this.

## Toggles

I added toggled hotkeys. If you press on ```Ctrl + W``` for example, it will repeat the 'Click' action until you press ```Ctrl + W``` again.
Not all hotkeys are supported, I will add more in the future.

## Vending machine

I added the hotkey ```M``` to bruteforce all vending machine combination. It takes around 8 hours to try them all.
