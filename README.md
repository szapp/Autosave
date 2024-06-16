# Autosave

[![Scripts](https://github.com/szapp/Autosave/actions/workflows/scripts.yml/badge.svg)](https://github.com/szapp/Autosave/actions/workflows/scripts.yml)
[![Validation](https://github.com/szapp/Autosave/actions/workflows/validation.yml/badge.svg)](https://github.com/szapp/Autosave/actions/workflows/validation.yml)
[![Build](https://github.com/szapp/Autosave/actions/workflows/build.yml/badge.svg)](https://github.com/szapp/Autosave/actions/workflows/build.yml)
[![GitHub release](https://img.shields.io/github/v/release/szapp/Autosave.svg)](https://github.com/szapp/Autosave/releases/latest)  
[![World of Gothic](https://raw.githubusercontent.com/szapp/patch-template/main/.github/actions/initialization/badges/wog.svg)](https://www.worldofgothic.de/dl/download_637.htm)
[![Spine](https://raw.githubusercontent.com/szapp/patch-template/main/.github/actions/initialization/badges/spine.svg)](https://clockwork-origins.com/spine)
[![Steam Gothic 1](https://img.shields.io/badge/steam-Gothic%201-2a3f5a?logo=steam&labelColor=1b2838)](https://steamcommunity.com/sharedfiles/filedetails/?id=2787012251)
[![Steam Gothic 2](https://img.shields.io/badge/steam-Gothic%202-2a3f5a?logo=steam&labelColor=1b2838)](https://steamcommunity.com/sharedfiles/filedetails/?id=2786999914)

This patch (Gothic, Gothic Sequel, Gothic 2 and Gothic 2 NotR) introduces auto saving.

This is a modular modification (a.k.a. patch or add-on) that can be installed and uninstalled at any time and is virtually compatible with any modification.
It supports <kbd>Gothic 1</kbd>, <kbd>Gothic Sequel</kbd>, <kbd>Gothic II (Classic)</kbd> and <kbd>Gothic II: NotR</kbd>.

<sup>Generated from [szapp/patch-template](https://github.com/szapp/patch-template).</sup>

## About

Saving occurs in fixed, adjustable intervals and only when possible.
Saving is suspended during fights or when in threat.
Certain events can additionally trigger auto saving, i.e chapter transitions or completing a quest.
One or multiple saving slots are reserved in the Gothic.ini, which are alternated for saving.
This allows to maintain the last X game saves, to prevent against accidental bad decisions or game save corruptions.
In order to always find the latest saved game, the auto saves are labeled incrementally, i.e. - Auto Save 42 -.

> [!WARNING]
> The default settings reserve the bottom three save slots\*.
> These should be backed up or re-saved to other slots before using this patch.
> Alternatively the reserved save slots can be adjusted in the Gothic.ini before first use (see below).
> Please carefully read the section "Notes" below.

\* Gothic 1: savegame13, savegame14, savegame15 — Gothic 2: savegame18, savegame19, savegame20

## INI settings

Saving frequency, the reserved save slots and event-based saving can be adjusted in the Gothic.ini in the section `[AUTOSAVE]`.
This section is created after first launch.

1. The interval of automatic saving can be set as integer with the setting `minutes`.
2. The range of reserved saving slots is adjustable with `slotMin` and `slotMax`.
In order to only use one save slot, set both to the same value.
Save slots are numbered from 1 to 15 (Gothic 1), and 1 to 20 (Gothic 2).
The number 0 represents the quick save slot.
> Example: A setting of 18 and 20 (or 13 and 15 in Gothic 1), reserves the bottom three save slots (18, 19 and 20 / 13, 14 and 15).
3. Event-based saving can be enabled with `events=1` and disabled with `events=0`.

## Notes

- When reserving all save slots and setting the interval small enough, manual saving may become obsolete.

- Extensive testing of different settings of the save slot reservation was difficult and **backing up the entire save game directory is highly recommended before usage of the patch!**

- If another mod already implements auto saves, this patch does not take any action.
If it does anyway, please report it [here](https://github.com/szapp/Autosave/issues) and I will adjust the patch.

- In order to show on-screen debug information, add `debug=1` to the section `[AUTOSAVE]` in the Gothic.ini.
Aside from showing the time until next saving, the reason for suspending the save is displayed.

- If saving is not possible at a specific time, the save is performed as soon as possible. And afterwards again at the normal interval of X minutes after the latest save. The interval is always in relation to the most recent save. That means even when manually saving, the next automatic save will be X minutes afterwards. This avoids too frequent saves.

- The default settings look like this: Save every 5 minutes and alternate over the bottom three slots.

  Gothic 1
  ```ini
  [AUTOSAVE]
  minutes=5
  slotMin=13
  slotMax=15
  events=0
  ```

  Gothic 2
  ```ini
  [AUTOSAVE]
  minutes=5
  slotMin=18
  slotMax=20
  events=0
  ```

## Installation

1. Download the latest release of `Autosave.vdf` from the [releases page](https://github.com/szapp/Autosave/releases/latest).

2. Copy the file `Autosave.vdf` to `[Gothic]\Data\`. To uninstall, remove the file again.

The patch is also available on
- [World of Gothic](https://www.worldofgothic.de/dl/download_637.htm) | [Forum thread](https://forum.worldofplayers.de/forum/threads/1560461)
- [Spine Mod-Manager](https://clockwork-origins.com/spine/)
- [Steam Workshop Gothic 1](https://steamcommunity.com/sharedfiles/filedetails/?id=2787012251)
- [Steam Workshop Gothic 2](https://steamcommunity.com/sharedfiles/filedetails/?id=2786999914)

### Requirements

<table><thead><tr><th>Gothic</th><th>Gothic Sequel</th><th>Gothic II (Classic)</th><th>Gothic II: NotR</th></tr></thead>
<tbody><tr><td><a href="https://www.worldofgothic.de/dl/download_34.htm">Version 1.08k_mod</a></td><td>Version 1.12f</td><td><a href="https://www.worldofgothic.de/dl/download_278.htm">Report version 1.30.0.0</a></td><td><a href="https://www.worldofgothic.de/dl/download_278.htm">Report version 2.6.0.0</a></td></tr></tbody>
<tbody><tr><td colspan="4" align="center"><a href="https://github.com/szapp/Ninja/wiki#wiki-content">Ninja 3</a> or higher</td></tr></tbody></table>

<!--

If you are interested in writing your own patch, please do not copy this patch!
Instead refer to the PATCH TEMPLATE to build a foundation that is customized to your needs!
The patch template can found at https://github.com/szapp/patch-template.

-->
