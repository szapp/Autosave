/*
 * autosave.d
 * Source: https://forum.worldofplayers.de/forum/threads/1560461
 *
 * This script introduces auto saving the game in certain intervals in a range of save slots.
 * Saving is prevented as per usual and also in fights or when in threat. Multiple saving slots may be used to
 * alternate. Frequency and slots to use are adjustable in the Gothic.ini.
 *
 * - Requires Ikarus, LeGo (FrameFunctions)
 * - Compatible with Gothic 1 and Gothic 2
 *
 * Instructions
 * - Initialize from Init_Global with
 *     Autosave_Init();
 * - Additional adjustments can be made in the Gothic.ini (entries created on first use)
 *     [AUTOSAVE]
 *     minutes=10  // Saving frequency in minutes
 *     slotMin=18  // Range of saving slots to use
 *     slotMax=20  // i.e. here: use slots 18, 19 and 20
 *     counter=0   // Counter in the save slot name (increased internally)
 *
 *
 * Note: In order to use this script elsewhere, remove the "Ninja_" prefix from all symbols!
 */

/* Default values of constants */
const int    NINJA_AUTOSAVE_MINUTES   = 10;
const int    NINJA_AUTOSAVE_SLOT_MIN  = 18; // 0 is quick save
const int    NINJA_AUTOSAVE_SLOT_MAX  = 20;
const string NINJA_AUTOSAVE_NAME_PRE  = "    - Auto Save ";
const string NINJA_AUTOSAVE_NAME_POST = " -";
const int    NINJA_AUTOSAVE_DELAY     = 0; // Internal
var   int    Ninja_Autosave_FF;            // Internal

/*
 * Check if saving is currently possible
 */
func int Ninja_Autosave_Allow() {
    // Check if saving is possible
    const int CGameManager__MenuEnabled_G1 = 4362560; //0x429140
    const int CGameManager__MenuEnabled_G2 = 4369136; //0x42AAF0
    var int enable; var int enableRef;
    enableRef = _@(enable);
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(enableRef));
        CALL_PutRetValTo(0);
        CALL__thiscall(MEMINT_gameMan_Pointer_address, MEMINT_SwitchG1G2(CGameManager__MenuEnabled_G1,
                                                                         CGameManager__MenuEnabled_G2));
        call = CALL_End();
    };
    if (!enable) {
        return FALSE;
    };

    // Not in fight or during threat
    const int oCZoneMusic__s_herostatus_G1 =  9299208; //0x8DE508
    const int oCZoneMusic__s_herostatus_G2 = 10111520; //0x9A4A20
    if (MEM_ReadInt(MEMINT_SwitchG1G2(oCZoneMusic__s_herostatus_G1, oCZoneMusic__s_herostatus_G2))) {
        return FALSE;
    };

    // Capture cut scene camera
    const int zCCSCamera__inGameCamStored_G1 = 8833016; //0x86C7F8
    const int zCCSCamera__inGameCamStored_G2 = 9245096; //0x8D11A8
    if (MEM_ReadInt(MEMINT_SwitchG1G2(zCCSCamera__inGameCamStored_G1, zCCSCamera__inGameCamStored_G2))) {
        return FALSE;
    };

    // Check for EnforceSavingPolicy script
    if (MEM_FindParserSymbol("AllowSaving") != -1) {
        MEM_CallByString("AllowSaving");
        if (!MEM_PopIntResult()) {
            return FALSE;
        };
    };

    return TRUE;
};

/*
 * Trigger function called repeatedly
 */
func void Ninja_Autosave() {
    var FFItem this; this = get(Ninja_Autosave_FF);
    if (Ninja_Autosave_Allow()) {
        // After waiting, add some buffer time before immediately saving
        if (!this.delay) {
            this.delay = 500;
            return;
        };

        // Indicate auto save
        PrintScreen("Auto Save", -1, 1, "FONT_OLD_10_WHITE.TGA", 1);

        // Rotate slot number
        var int i; i = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "counter")) + 1;
        MEM_SetGothOpt("AUTOSAVE", "counter", IntToString(i));
        var int slot; slot = ((i-1) % (NINJA_AUTOSAVE_SLOT_MAX+1 - NINJA_AUTOSAVE_SLOT_MIN)) + NINJA_AUTOSAVE_SLOT_MIN;

        // Make slot name with increasing index
        var string slotName; slotName = NINJA_AUTOSAVE_NAME_PRE;
        slotName = ConcatStrings(slotName, IntToString(i));
        slotName = ConcatStrings(slotName, NINJA_AUTOSAVE_NAME_POST);

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

        // Add delay to avoid infinite loop
        this.next += NINJA_AUTOSAVE_DELAY;

        // Save game to save slot
        const int CGameManager__Write_Savegame_G1 = 4360080; //0x428790
        const int CGameManager__Write_Savegame_G2 = 4367056; //0x42A2D0
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL_IntParam(_@(slot));
            CALL__thiscall(MEMINT_gameMan_Pointer_address, MEMINT_SwitchG1G2(CGameManager__Write_Savegame_G1,
                                                                             CGameManager__Write_Savegame_G2));
            call = CALL_End();
        };
    } else if (this.delay) {
        MEM_Info("Autosave: Waiting to perform auto-save.");
        this.delay = 0;
    };
};

/*
 * Reset delay on saving
 */
func void Ninja_Autosave_Reset() {
    MEM_Info("Autosave: Reset delay.");
    var FFItem ff; ff = get(Ninja_Autosave_FF);
    ff.delay = NINJA_AUTOSAVE_DELAY;
    ff.next = TimerGT() + ff.delay;
};

/*
 * Set and read INI settings
 */
func void Ninja_Autosave_ReadIni() {
    // Set values to their defaults if they do not exist
    MEM_Info("Autosave: Initializing entries in Gothic.ini.");
    if (!MEM_GothOptExists("AUTOSAVE", "minutes")) {
        MEM_SetGothOpt("AUTOSAVE", "minutes", IntToString(NINJA_AUTOSAVE_MINUTES));
    };
    if (!MEM_GothOptExists("AUTOSAVE", "slotMin")) {
        MEM_SetGothOpt("AUTOSAVE", "slotMin", IntToString(MEMINT_SwitchG1G2(13, 18)));
    };
    if (!MEM_GothOptExists("AUTOSAVE", "slotMax")) {
        MEM_SetGothOpt("AUTOSAVE", "slotMax", IntToString(MEMINT_SwitchG1G2(15, 20)));
    };
    if (STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "counter")) < 1) { // Force non-negative values
        MEM_SetGothOpt("AUTOSAVE", "counter", "0");
    };

    // Read values
    NINJA_AUTOSAVE_MINUTES  = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "minutes"));
    NINJA_AUTOSAVE_SLOT_MIN = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "slotMin"));
    NINJA_AUTOSAVE_SLOT_MAX = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "slotMax"));

    // Verify auto save slot number range
    var int slotMax; slotMax = MEM_ReadInt(MEMINT_SwitchG1G2(/*0x7D1224*/8196644, /*0x82F2D0*/8581840));
    if (NINJA_AUTOSAVE_SLOT_MIN < 0) || (NINJA_AUTOSAVE_SLOT_MIN > slotMax) {
        NINJA_AUTOSAVE_SLOT_MIN = slotMax;
    };
    if (NINJA_AUTOSAVE_SLOT_MAX < 0) || (NINJA_AUTOSAVE_SLOT_MAX > slotMax) {
        NINJA_AUTOSAVE_SLOT_MAX = slotMax;
    };
    if (NINJA_AUTOSAVE_SLOT_MIN > NINJA_AUTOSAVE_SLOT_MAX) {
        NINJA_AUTOSAVE_SLOT_MAX = NINJA_AUTOSAVE_SLOT_MIN;
    };

    // Convert delay to milliseconds
    NINJA_AUTOSAVE_DELAY = NINJA_AUTOSAVE_MINUTES * 60 * 1000;
};

/*
 * Initialization function to be called from Init_Global
 */
func void _Ninja_Autosave_Init() {
    if (_LeGo_Flags & LeGo_FrameFunctions) {
        // Read INI settings
        Ninja_Autosave_ReadIni();
        HookEngineF(CGameManager__ApplySomeSettings, MEMINT_SwitchG1G2(7, 8), Ninja_Autosave_ReadIni);

        // Start frame function and store handle
        if (!FF_Active(Ninja_Autosave)) {
            FF_ApplyExtGT(Ninja_Autosave, NINJA_AUTOSAVE_DELAY, -1);
            Ninja_Autosave_FF = numHandles();
        };

        // Reset delay after saving/loading
        Ninja_Autosave_Reset();
        HookEngineF(oCSavegameManager__SetAndWriteSavegame, 5, Ninja_Autosave_Reset);
    };
};
