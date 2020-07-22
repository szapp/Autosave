/*
 * Menu initialization function called by Ninja every time a menu is opened
 */
func void Ninja_Autosave_Menu(var int menuPtr) {
    // Only on game start
    const int once = 0;
    if (!once) {
        // Initialize Ikarus
        MEM_InitAll();
        Ninja_Autosave_ReadIni();
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
