/*
 * Menu initialization function called by Ninja every time a menu is opened
 */
func void Ninja_Autosave_Menu(var int menuPtr) {
    // Only on game start
    const int once = 0;
    if (!once) {
        // Initialize Ikarus
        MEM_InitAll();

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

        NINJA_AUTOSAVE_MINUTES  = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "minutes"));
        NINJA_AUTOSAVE_SLOT_MIN = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "slotMin"));
        NINJA_AUTOSAVE_SLOT_MAX = STR_ToInt(MEM_GetGothOpt("AUTOSAVE", "slotMax"));

        once = 1;
    };
};


/*
 * Initialization function called by Ninja after "Init_Global" (G2) / "Init_<Levelname>" (G1)
 */
func void Ninja_Autosave_Init() {
    // Initialize Ikarus
    MEM_InitAll();

    // Make sure to only add the feature if it does not exist already in the mod
    if (MEM_FindParserSymbol("AUTOSAVE")    == -1)
    && (MEM_FindParserSymbol("B_AUTOSAVE")  == -1)
    && (MEM_FindParserSymbol("PO_AUTOSAVE") == -1) {
        // Wrapper for "LeGo_Init" to ensure correct LeGo initialization without breaking the mod
        LeGo_MergeFlags(LeGo_FrameFunctions);
        _Ninja_Autosave_Init();
    };
};
