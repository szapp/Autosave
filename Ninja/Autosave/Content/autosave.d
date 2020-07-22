/*
 * autosave.d
 * Source: https://forum.worldofplayers.de/forum/threads/
 *
 * This script introduces auto saving the game in certain intervals in a range of save slots.
 *
 * - Requires Ikarus, LeGo (FrameFunctions)
 * - Compatible with Gothic 1 and Gothic 2
 *
 * Instructions
 * - Initialize from Init_Global with
 *     Autosave_Init();
 * - Adjust saving frequency with AUTOSAVE_MINUTES (see below)
 * - Adjust the slots used with AUTOSAVE_SLOT_MIN and AUTOSAVE_SLOT_MAX
 *
 *
 * Note: In order to use this script elsewhere, remove the "Ninja_" prefix from all symbols!
 */

/* Constants */
const int    NINJA_AUTOSAVE_MINUTES  = 10;
const int    NINJA_AUTOSAVE_SLOT_MIN = 18; // 0 is quick save
const int    NINJA_AUTOSAVE_SLOT_MAX = 20;
const string NINJA_AUTOSAVE_SLOTNAME = "    - Auto Save -     ";
var   int    Ninja_Autosave_FF;    // Internal
var   int    Ninja_Autosave_Delay; // Internal

/*
 * Check if saving is currently possible
 */
func int Ninja_Autosave_Allow() {
    // Check if quick saving is possible
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

    return TRUE;
};

/*
 * Trigger function called repeatedly
 */
func void Ninja_Autosave() {
    var FFItem this; this = get(Ninja_Autosave_FF);
    if (Ninja_Autosave_Allow()) {
        PrintScreen("Auto Save", -1, 1, "FONT_OLD_10_WHITE.TGA", 1);

        // Rotate slot number
        var int i; i += 1;
        var int slot; slot = (i % (NINJA_AUTOSAVE_SLOT_MAX+1 - NINJA_AUTOSAVE_SLOT_MIN)) + NINJA_AUTOSAVE_SLOT_MIN;

        // Rename save slot in menu
        if (slot) {
            var string menuItmName; menuItmName = ConcatStrings("MENUITEM_SAVE_SLOT", IntToString(slot));
            var int menuItmPtr; menuItmPtr = MEM_GetMenuItemByString(menuItmName);
            if (menuItmPtr) {
                var zCMenuItem menuItm; menuItm = _^(menuItmPtr);
                MEM_WriteStringArray(menuItm.m_listLines_array, 0, NINJA_AUTOSAVE_SLOTNAME);
            };

            var int infoArr; infoArr = MEM_GameManager.savegameManager + 4; // zCArray *
            var int sinfo; sinfo = MEM_ArrayRead(infoArr, slot); // oCSavegameInfo *
            if (sinfo) {
                MEM_WriteString(sinfo + 64, NINJA_AUTOSAVE_SLOTNAME); // oCSavegameInfo->name
            };
        };

        // Add delay to avoid infinite loop
        this.next += Ninja_Autosave_Delay;

        // Save game to quick save slot
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
    ff.delay = Ninja_Autosave_Delay;
    ff.next = TimerGT() + ff.delay;
};

/*
 * Initialization function to be called from Init_Global
 */
func void _Ninja_Autosave_Init() {
    if (_LeGo_Flags & LeGo_FrameFunctions) {
        // Verify auto save slot
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
        Ninja_Autosave_Delay = NINJA_AUTOSAVE_MINUTES * 60 * 1000;

        // Start frame function and store handle
        if (!FF_Active(Ninja_Autosave)) {
            FF_ApplyExtGT(Ninja_Autosave, Ninja_Autosave_Delay, -1);
            Ninja_Autosave_FF = numHandles();
        };

        // Reset delay after saving/loading
        Ninja_Autosave_Reset();
        HookEngineF(oCSavegameManager__SetAndWriteSavegame, 5, Ninja_Autosave_Reset);
    };
};
