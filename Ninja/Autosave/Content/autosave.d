/*
 * autosave.d
 * Source: https://forum.worldofplayers.de/forum/threads/1560461
 *
 * This script introduces auto saving the game in certain intervals in a range of save slots.
 * Saving is prevented as per usual and also in fights or when in threat. Multiple saving slots may be used to
 * alternate. Frequency and slots to use are adjustable in the Gothic.ini.
 *
 * - Requires Ikarus, LeGo (HookEngine, Timer)
 * - Compatible with Gothic, Gothic Sequel, Gothic 2, and Gothic 2 NotR
 *
 * Instructions
 * - Initialize from Init_Global with
 *     Autosave_Init();
 * - Additional adjustments can be made in the Gothic.ini (entries created on first use)
 *     [AUTOSAVE]
 *     minutes=5   ; Saving frequency in minutes
 *     slotMin=18  ; Range of saving slots to use
 *     slotMax=20  ; i.e. here: use slots 18, 19 and 20
 *     events=0    ; Also save after events (0 = no, 1 = yes)
 *     counter=0   ; Counter in the save slot name (increased internally)
 *
 *
 * Note: In order to use this script elsewhere, remove the "Patch_" prefix from all symbols!
 */

/* Default values of constants */
const int    PATCH_AUTOSAVE_MINUTES   = 5;
const int    PATCH_AUTOSAVE_SLOT_MIN  = 18;  // 0 is quick save
const int    PATCH_AUTOSAVE_SLOT_MAX  = 20;
const int    PATCH_AUTOSAVE_EVENTS    = 0;   // Occasionally causes issues
const int    PATCH_AUTOSAVE_DEBUG     = 0;
const string PATCH_AUTOSAVE_NAME_PRE  = "    - Auto Save ";
const string PATCH_AUTOSAVE_NAME_POST = " -";
const int    PATCH_AUTOSAVE_SLOT_MINL = -1;    // Internal
const int    PATCH_AUTOSAVE_SLOT_MAXL = -1;    // Internal
const int    PATCH_AUTOSAVE_DELAY     = 0;     // Internal
const int    PATCH_AUTOSAVE_BUFFER    = 750;   // Internal
const int    PATCH_AUTOSAVE_EASE      = 0;     // Internal
const int    PATCH_AUTOSAVE_NEXT      = 0;     // Internal
const int    PATCH_AUTOSAVE_TRIGGER   = FALSE; // Internal
const int    PATCH_AUTOSAVE_WAIT      = FALSE; // Internal


/*
 * Debugging function
 */
func void Patch_Autosave_DebugPrint(var string reason) {
    if (PATCH_AUTOSAVE_DEBUG) {
        PrintScreen(reason, 1, 1, "FONT_OLD_10_WHITE.TGA", 1);
    };
};

/*
 * Check if saving is currently possible
 */
func int Patch_Autosave_Allow() {
    const int oCNpc__player[4]             = {/*G1*/9288624, /*G1A*/9580852, /*G2*/9974236, /*G2A*/11216516};
    const int CGameManager__MenuEnabled[4] = {/*G1*/4362560, /*G1A*/4374000, /*G2*/4368336, /*G2A*/ 4369136};
    const int oCZoneMusic__s_herostatus[4] = {/*G1*/9299208, /*G1A*/9594720, /*G2*/9986808, /*G2A*/10111520};
    const int zCCSCamera__playing[4]       = {/*G1*/8833024, /*G1A*/9118444, /*G2*/9186136, /*G2A*/ 9245104};
    const int oCNpc__inventory2_offset_G112 = 1360;
    const int oCNpc__game_mode_G112        = 9581292; //0x9232EC
    const int oCItemContainer__IsOpen_G112 = 6908608; //0x696AC0

    // Check if player is set (rare cases during loading)
    var int playerPtr; playerPtr = MEM_ReadInt(oCNpc__player[AUTOSAVE_EXE]);
    if (!playerPtr) {
        return FALSE;
    };

    // Check if saving is possible
    if (CALL_Begin(call)) {
        const int call = 0;
        const int enable[2] = {0, 0};
        enable[1] = _@(enable);
        CALL_PtrParam(_@(enable[1]));
        CALL_PutRetValTo(0);
        CALL__thiscall(MEMINT_gameMan_Pointer_address, CGameManager__MenuEnabled[AUTOSAVE_EXE]);
        call = CALL_End();
    };
    if (enable) && (GOTHIC_BASE_VERSION == 112) {
        // Gothic Sequel is missing a check for open inventory, stealing, and looting
        enable = !MEM_ReadInt(oCNpc__game_mode_G112); // Not stealing or looting
        if (enable) {
            var int invPtr; invPtr = playerPtr + oCNpc__inventory2_offset_G112;
            if (CALL_Begin(call2)) {
                const int call2 = 0;
                CALL__thiscall(_@(invPtr), oCItemContainer__IsOpen_G112);
                call2 = CALL_End();
            };
            enable = !CALL_RetValAsInt();
        };
    };
    if (!enable) {
        Patch_Autosave_DebugPrint("Engine disallows saving");
        return FALSE;
    };

    // Not in fight or during threat
    if (MEM_ReadInt(oCZoneMusic__s_herostatus[AUTOSAVE_EXE])) {
        Patch_Autosave_DebugPrint("Currently in combat");
        return FALSE;
    };

    // Check for playing cut scene camera
    if (MEM_ReadInt(zCCSCamera__playing[AUTOSAVE_EXE])) {
        Patch_Autosave_DebugPrint("Cut scene camera is playing");
        PATCH_AUTOSAVE_EASE = 5000;
        return FALSE;
    };

    // Check for EnforceSavingPolicy script
    if (MEM_FindParserSymbol("AllowSaving") != -1) {
        MEM_CallByString("AllowSaving");
        if (!MEM_PopIntResult()) {
            Patch_Autosave_DebugPrint("Scripts disallow saving");
            return FALSE;
        };
    };

    return TRUE;
};

/*
 * Reset delay on saving/loading
 */
func void Patch_Autosave_Reset() {
    MEM_Info("Autosave: Reset delay.");
    PATCH_AUTOSAVE_NEXT = TimerGT() + PATCH_AUTOSAVE_DELAY;
    PATCH_AUTOSAVE_EASE = 0;
    PATCH_AUTOSAVE_WAIT = FALSE;
    PATCH_AUTOSAVE_TRIGGER = FALSE;
};

/*
 * Trigger function that is called repeatedly
 */
func void Patch_Autosave() {
    if (PATCH_AUTOSAVE_DEBUG) {
        var int msTotal; msTotal = PATCH_AUTOSAVE_NEXT - TimerGT();
        if (msTotal < 0) { msTotal = 0; };
        var int sec; sec = ((msTotal + 999) / 1000) % 60;
        var int min; min = ((msTotal + 999) / 1000) / 60;
        var string secStr; secStr = IntToString(sec);
        if (sec < 10) { secStr = ConcatStrings("0", secStr); };
        var string timeStr; timeStr = ConcatStrings(ConcatStrings(IntToString(min), ":"), secStr);
        if (PATCH_AUTOSAVE_TRIGGER) || (!MEM_Game.timeStep) { Patch_Autosave_DebugPrint(""); }
        else if ((min > 0) || (sec > 0)) { Patch_Autosave_DebugPrint(ConcatStrings("Saving in ", timeStr)); };
    };

    // Exit if time not reached
    if (PATCH_AUTOSAVE_NEXT > TimerGT()) {
        return;
    };

    // Exit if not allowed
    if (!Patch_Autosave_Allow()) {
        if (!PATCH_AUTOSAVE_WAIT) {
            MEM_Info("Autosave: Waiting to perform auto-save.");
            PATCH_AUTOSAVE_WAIT = TRUE;
        };
        return;
    } else if (PATCH_AUTOSAVE_WAIT) {
        // After waiting, add some buffer time before immediately saving
        PATCH_AUTOSAVE_NEXT = TimerGT() + PATCH_AUTOSAVE_BUFFER + PATCH_AUTOSAVE_EASE;

        // Reset
        PATCH_AUTOSAVE_WAIT = FALSE;
        PATCH_AUTOSAVE_EASE = 0;
        return;
    };

    // Prevent infinite loop on next frame
    if (!PATCH_AUTOSAVE_TRIGGER) {
        PATCH_AUTOSAVE_TRIGGER = TRUE;

        // Indicate auto save
        PrintScreen("Auto Save", -1, 1, "FONT_OLD_10_WHITE.TGA", 1);

        // Rotate slot number
        var int i; i = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "counter")) + 1;
        MEM_SetGothOpt("AUTOSAVE", "counter", IntToString(i));
        var int slot; slot = ((i-1) % (PATCH_AUTOSAVE_SLOT_MAX+1 - PATCH_AUTOSAVE_SLOT_MIN)) + PATCH_AUTOSAVE_SLOT_MIN;

        // Make slot name with increasing index
        var string slotName; slotName = PATCH_AUTOSAVE_NAME_PRE;
        slotName = ConcatStrings(slotName, IntToString(i));
        slotName = ConcatStrings(slotName, PATCH_AUTOSAVE_NAME_POST);

        // Rename save slot in menu
        if (slot) {
            var string menuItmName; menuItmName = ConcatStrings("MENUITEM_SAVE_SLOT", IntToString(slot));
            var int menuItmPtr; menuItmPtr = MEM_GetMenuItemByString(menuItmName);
            if (menuItmPtr) {
                var zCMenuItem menuItm; menuItm = _^(menuItmPtr);
                MEM_WriteStringArray(menuItm.m_listLines_array, 0, slotName);
            };

            var int infoArr; infoArr = MEM_GameManager.savegameManager + 4; // zCArray *
            var int sinfo; sinfo = MEM_ArrayRead(infoArr, slot); // oCSavegameInfo *
            if (sinfo) {
                MEM_WriteString(sinfo + 64, slotName); // oCSavegameInfo->name
            };
        };

        // Save game to save slot
        const int CGameManager__Write_Savegame[4] = {/*G1*/4360080, /*G1A*/0,       /*G2*/4366256, /*G2A*/4367056};
        const int oCGame__SetShowPlayerStatus[4]  = {/*G1*/6523872, /*G1A*/6680880, /*G2*/6709904, /*G2A*/7089552};
        if (CALL_Begin(call)) {
            const int call = 0;
            // The function does not exist in 1.12f, so create it
            if (GOTHIC_BASE_VERSION == 112) {
                MEM_CallByString("Patch_Autosave_CreateWriteSavegame");
                CGameManager__Write_Savegame[1] = MEM_PopIntResult();
            };
            CALL_PtrParam(_@(FALSE)); // Remove on-screen information for thumbnail
            CALL__thiscall(MEMINT_oGame_Pointer_Address, oCGame__SetShowPlayerStatus[AUTOSAVE_EXE]);
            CALL_IntParam(_@(slot));
            CALL__thiscall(MEMINT_gameMan_Pointer_address, CGameManager__Write_Savegame[AUTOSAVE_EXE]);
            CALL_PtrParam(_@(TRUE));  // Turn on-screen information back on
            CALL__thiscall(MEMINT_oGame_Pointer_Address, oCGame__SetShowPlayerStatus[AUTOSAVE_EXE]);
            call = CALL_End();
        };
    };
};

/*
 * Set a delay to trigger soon
 */
func void Patch_Autosave_TriggerDelayed(var int ms) {
    // If last save occurred more than 10 seconds ago or if saving is not possible anyway
    if (!PATCH_AUTOSAVE_WAIT) {
        var int timeSinceLast; timeSinceLast = PATCH_AUTOSAVE_DELAY - (PATCH_AUTOSAVE_NEXT - TimerGT());
        if (!Patch_Autosave_Allow()) || (timeSinceLast > (10000 - ms)) {
            // Trigger an auto save after a few milliseconds
            PATCH_AUTOSAVE_NEXT = TimerGT() + ms;
        };
    };
};

/*
 * Trigger saving on IntroduceChapter
 */
func void Patch_Autosave_OnIntroduceChapter() {
    Patch_Autosave_TriggerDelayed(2000);
};

/*
 * Trigger saving on Log_SetTopicStatus
 */
func void Patch_Autosave_OnChangeTopicStatus() {
    const int LOG_SUCCESS = 2;
    var int status; status = Autosave_SwitchExe(EBX, EBP, EBX, EBX);
    if (status == LOG_SUCCESS) {
        Patch_Autosave_TriggerDelayed(2000);
    };
};

/*
 * Initialize slot range limits based on the program and the slots available in the menu scripts
 */
func void Patch_Autosave_InitializeRange() {
    // Smallest range supported by program
    const int SAVEGAME_SLOT_MIN_Addr[4] = {/*G1*/8196640, /*G1A*/8471012, /*G2*/8524492, /*G2A*/8581836};
    const int SAVEGAME_SLOT_MAX_Addr[4] = {/*G1*/8196644, /*G1A*/8471016, /*G2*/8524496, /*G2A*/8581840};
    PATCH_AUTOSAVE_SLOT_MINL = MEM_ReadInt(SAVEGAME_SLOT_MIN_Addr[AUTOSAVE_EXE]);
    PATCH_AUTOSAVE_SLOT_MAXL = MEM_ReadInt(SAVEGAME_SLOT_MAX_Addr[AUTOSAVE_EXE]);

    // Find the save menu
    var int saveMenuPtr; saveMenuPtr = MEM_GetMenuByString("MENU_SAVEGAME_SAVE"); // Name fixed by program
    if (!saveMenuPtr) {
        MEM_SendToSpy(zERR_TYPE_WARN, "Autosave: Save menu not found.");
        MEM_InfoBox("Autosave: Save menu not found.");
        return;
    };

    // Iterate over all menu entries to narrow down the available save slots
    var int slotMinMenu; slotMinMenu = 9999;
    var int slotMaxMenu; slotMaxMenu = -9999;
    var zCMenu saveMenu; saveMenu = _^(saveMenuPtr);
    repeat(i, saveMenu.m_listItems_numInArray); var int i;
        const int oCMenuSavegame__GetMenuItemSlotNr[4] = {/*G1*/4380384, /*G1A*/4393264, /*G2*/4389904, /*G2A*/4390704};
        var int menuItmPtr; menuItmPtr = MEM_ReadIntArray(saveMenu.m_listItems_array, i);
        if (CALL_Begin(call)) {
            const int call = 0;
            CALL_PtrParam(_@(menuItmPtr));
            CALL_PutRetValTo(_@(num));
            CALL__thiscall(_@(saveMenuPtr), oCMenuSavegame__GetMenuItemSlotNr[AUTOSAVE_EXE]);
            call = CALL_End();
        };
        var int num;
        if (num < PATCH_AUTOSAVE_SLOT_MINL) || (num > PATCH_AUTOSAVE_SLOT_MAXL) { continue; };
        if (slotMinMenu > num) { slotMinMenu = num; };
        if (slotMaxMenu < num) { slotMaxMenu = num; };
    end;

    // Update the limits if smaller range
    if (slotMinMenu != 9999) && (slotMaxMenu != -9999) && (slotMinMenu != slotMaxMenu) {
        PATCH_AUTOSAVE_SLOT_MINL = slotMinMenu;
        PATCH_AUTOSAVE_SLOT_MAXL = slotMaxMenu;
    };
};

/*
 * Verify slot number range
 */
func void Patch_Autosave_VerifyRange() {
    if (PATCH_AUTOSAVE_SLOT_MINL == -1) || (PATCH_AUTOSAVE_SLOT_MAXL == -1) {
        Patch_Autosave_InitializeRange();
    };

    // Update the ranges
    var int diff; diff = PATCH_AUTOSAVE_SLOT_MAX - PATCH_AUTOSAVE_SLOT_MIN;
    var int diffL; diffL = PATCH_AUTOSAVE_SLOT_MAXL - PATCH_AUTOSAVE_SLOT_MINL;
    if (diff < 0) {
        var int tmp; tmp = PATCH_AUTOSAVE_SLOT_MAX;
        PATCH_AUTOSAVE_SLOT_MAX = PATCH_AUTOSAVE_SLOT_MIN;
        PATCH_AUTOSAVE_SLOT_MIN = tmp;
        diff = -diff;
    };
    if (diff > diffL) {
        PATCH_AUTOSAVE_SLOT_MAX -= diff - diffL;
        diff = diffL;
    };

    if (PATCH_AUTOSAVE_SLOT_MAX > PATCH_AUTOSAVE_SLOT_MAXL) {
        PATCH_AUTOSAVE_SLOT_MAX = PATCH_AUTOSAVE_SLOT_MAXL;
        PATCH_AUTOSAVE_SLOT_MIN = PATCH_AUTOSAVE_SLOT_MAXL - diff;
    };
    if (PATCH_AUTOSAVE_SLOT_MIN < PATCH_AUTOSAVE_SLOT_MINL) {
        PATCH_AUTOSAVE_SLOT_MIN = PATCH_AUTOSAVE_SLOT_MINL;
        PATCH_AUTOSAVE_SLOT_MAX = PATCH_AUTOSAVE_SLOT_MINL + diff;
    };
};

/*
 * Set and read INI settings
 */
func void Patch_Autosave_ReadIni() {
    // Verify auto save slot number range (defaults)
    Patch_Autosave_VerifyRange();

    // Set values to their defaults if they do not exist
    MEM_Info("Autosave: Initializing entries in Gothic.ini.");
    if (!MEM_GothOptExists("AUTOSAVE", "minutes")) {
        MEM_SetGothOpt("AUTOSAVE", "minutes", IntToString(PATCH_AUTOSAVE_MINUTES));
    };
    if (!MEM_GothOptExists("AUTOSAVE", "slotMin")) {
        MEM_SetGothOpt("AUTOSAVE", "slotMin", IntToString(PATCH_AUTOSAVE_SLOT_MIN));
    };
    if (!MEM_GothOptExists("AUTOSAVE", "slotMax")) {
        MEM_SetGothOpt("AUTOSAVE", "slotMax", IntToString(PATCH_AUTOSAVE_SLOT_MAX));
    };
    if (!MEM_GothOptExists("AUTOSAVE", "events")) {
        MEM_SetGothOpt("AUTOSAVE", "events", IntToString(PATCH_AUTOSAVE_EVENTS));
    };
    if (STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "counter")) < 1) { // Force non-negative values
        MEM_SetGothOpt("AUTOSAVE", "counter", "0");
    };

    // Read values
    PATCH_AUTOSAVE_MINUTES  = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "minutes"));
    PATCH_AUTOSAVE_SLOT_MIN = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "slotMin"));
    PATCH_AUTOSAVE_SLOT_MAX = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "slotMax"));
    PATCH_AUTOSAVE_EVENTS   = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "events"));
    PATCH_AUTOSAVE_DEBUG    = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "debug"));

    // Verify auto save slot number range (loaded values)
    Patch_Autosave_VerifyRange();

    // Convert delay to milliseconds
    if (PATCH_AUTOSAVE_MINUTES) <= 0 {
        PATCH_AUTOSAVE_MINUTES = 1;
    };
    PATCH_AUTOSAVE_DELAY = PATCH_AUTOSAVE_MINUTES * 60 * 1000;

    // A bit redundant, but reflects any adjustments in the INI file
    MEM_SetGothOpt("AUTOSAVE", "minutes", IntToString(PATCH_AUTOSAVE_MINUTES));
    MEM_SetGothOpt("AUTOSAVE", "slotMin", IntToString(PATCH_AUTOSAVE_SLOT_MIN));
    MEM_SetGothOpt("AUTOSAVE", "slotMax", IntToString(PATCH_AUTOSAVE_SLOT_MAX));
};

/*
 * Initialization function to be called from Init_Global
 */
func void Patch_Autosave_Init() {
    if (_LeGo_Flags & LeGo_Timer) {
        // Read INI settings
        Patch_Autosave_ReadIni();
        HookEngineF(CGameManager__ApplySomeSettings, Autosave_SwitchExe(7, 7, 8, 8), Patch_Autosave_ReadIni);

        // Start the watcher
        HookEngineF(oCGame__Render, 7, Patch_Autosave);

        // Reset delay after saving/loading
        Patch_Autosave_Reset();
        HookEngineF(oCSavegameManager__SetAndWriteSavegame, 5, Patch_Autosave_Reset);

        // Event-based saving
        const int IntroduceChapter[4]          = {/*G1*/6678032, /*G1A*/6854224, /*G2*/6938112, /*G2A*/7320800};
        const int Log_SetTopicStatus_status[4] = {/*G1*/6633725, /*G1A*/6803886, /*G2*/6844477, /*G2A*/7225165};
        if (PATCH_AUTOSAVE_EVENTS) {
            HookEngineF(IntroduceChapter[AUTOSAVE_EXE],          7, Patch_Autosave_OnIntroduceChapter);
            HookEngineF(Log_SetTopicStatus_status[AUTOSAVE_EXE], 6, Patch_Autosave_OnChangeTopicStatus);
        } else {
            // When disabling during the game (i.e. if there was menu option), remove the hook
            RemoveHookF(IntroduceChapter[AUTOSAVE_EXE],          7, Patch_Autosave_OnIntroduceChapter);
            RemoveHookF(Log_SetTopicStatus_status[AUTOSAVE_EXE], 6, Patch_Autosave_OnChangeTopicStatus);
        };
    };
};
