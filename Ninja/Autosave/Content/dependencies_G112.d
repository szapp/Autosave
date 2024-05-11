const int AUTOSAVE_EXE = 1;
func int Autosave_SwitchExe(var int g1, var int g112, var int g130, var int g2) {
    return g112;
};


/*
 * CGameManager::Write_Savegame does not exist in Gothic 1.12f. The function below creates the code for the function.
 */
func int Patch_Autosave_CreateWriteSavegame() {
    const int ogamePtr  = MEMINT_oGame_Pointer_Address; // oCGame**
    const int savManPtr = 0; // oCSavegameManager*
    const int infoPtr   = 0; // oCSavegameInfo*
    const int texCnvPtr = 0; // zCTextureConvert*
    const int slotNr    = 0; // int
    const int day       = 0; // int
    const int hour      = 0; // int
    const int min       = 0; // int
    const int sec       = 0; // int
    const int dayPtr    = 0; // int*
    const int hourPtr   = 0; // int*
    const int minPtr    = 0; // int*
    const int strPtr    = 0; // int*
    const int wldPtr    = 0; // char*

    const int oCGame__GetTime                        = 6689408; //0x661280
    const int oCGame__Render                         = 6703344; //0x6648F0
    const int oCGame__WriteSavegame                  = 6690432; //0x661680
    const int CGameManager__GetPlaytimeSeconds       = 4367520; //0x42A4A0
    const int oCSavegameManager__GetSavegame         = 4432176; //0x43A130
    const int oCSavegameManager__SetAndWriteSavegame = 4431600; //0x439EF0
    const int oCSavegameInfo__UpdateThumbPic         = 4423648; //0x437FE0
    const int zCRnd_D3D__CreateTextureConvert        = 7697296; //0x757390
    const int zCRnd_D3D__Vid_GetFrontBufferCopy      = 7715120; //0x75B930
    const int zCTexConGeneric__deleting_destructor   = 7730864; //0x75F6B0
    const int zSTRING__operator_eq                   = 5067536; //0x4D5310

    const int code = 0;
    if (!code) {
        dayPtr  = _@(day);
        hourPtr = _@(hour);
        minPtr  = _@(min);

        CALL_Open();
        ASM_Open(512);

        // Get argument
        ASM_3(2376843); ASM_1(4);           // mov  eax, [esp+4h]
        ASM_1(163);     ASM_4(_@(slotNr));  // mov  [slotNr], eax

        // Backup registers
        ASM_1(86);                          // push esi
        ASM_1(81);                          // push ecx

        // Get oCSavegameManager
        ASM_2(18827);   ASM_1(32);          // mov  ecx, [ecx+20h]
        ASM_2(3465);    ASM_4(_@(savManPtr)); // mov  [savManPtr], ecx

        // Get oCSavegameInfo
        CALL_PutRetValTo(_@(infoPtr));
        CALL_PtrParam(_@(slotNr));
        CALL__thiscall(_@(savManPtr), oCSavegameManager__GetSavegame);

        // Set oCSavegameInfo.playTimeSec
        CALL_PutRetValTo(-1);
        CALL__thiscall(MEMINT_gameMan_Pointer_address, CGameManager__GetPlaytimeSeconds);
        ASM_2(13707);   ASM_4(_@(infoPtr)); // mov  esi, [infoPtr]
        ASM_2(34441);   ASM_4(136);         // mov  [esi+88h], eax

        // Set oCSavegameInfo.day / .hour / .min
        CALL_PtrParam(_@(minPtr));
        CALL_PtrParam(_@(hourPtr));
        CALL_PtrParam(_@(dayPtr));
        CALL__thiscall(ogamePtr, oCGame__GetTime);
        ASM_1(161);     ASM_4(_@(day));     // mov  eax, [day]
        ASM_2(34441);   ASM_4(104);         // mov  [esi+68h], eax
        ASM_1(161);     ASM_4(_@(hour));    // mov  eax, [hour]
        ASM_2(34441);   ASM_4(108);         // mov  [esi+6Ch], eax
        ASM_1(161);     ASM_4(_@(min));     // mov  eax, [min]
        ASM_2(34441);   ASM_4(112);         // mov  [esi+70h], eax

        // Set oCSavegameInfo.worldName
        ASM_2(3467);    ASM_4(ogamePtr);    // mov  ecx, [[ogamePtr]]
        ASM_2(18827);   ASM_1(8);           // mov  ecx, [ecx+8h]    // zCWorld
        ASM_2(35211);   ASM_4(25180);       // mov  ecx, [ecx+625Ch] // zString.ptr
        ASM_2(3465);    ASM_4(_@(wldPtr));  // mov  [wldPtr], ecx
        ASM_2(50819);   ASM_1(84);          // add  esi, 54h         // oCSavegameInfo.worldName
        ASM_2(13705);   ASM_4(_@(strPtr));  // mov  [strPtr], esi
        CALL_PtrParam(_@(wldPtr));
        CALL__thiscall(_@(strPtr), zSTRING__operator_eq);

        // Take screen shot and save game
        CALL_PutRetValTo(_@(texCnvPtr));
        CALL__thiscall(zrenderer_adr, zCRnd_D3D__CreateTextureConvert);
        CALL__thiscall(ogamePtr, oCGame__Render);
        CALL_PtrParam(_@(texCnvPtr));
        CALL__thiscall(zrenderer_adr, zCRnd_D3D__Vid_GetFrontBufferCopy);
        CALL_PtrParam(_@(TRUE));
        CALL_PtrParam(_@(slotNr));
        CALL__thiscall(ogamePtr, oCGame__WriteSavegame);
        CALL_PtrParam(_@(texCnvPtr));
        CALL__thiscall(_@(infoPtr), oCSavegameInfo__UpdateThumbPic);
        CALL_PtrParam(_@(TRUE));
        CALL__thiscall(_@(texCnvPtr), zCTexConGeneric__deleting_destructor);

        // Store additional information
        CALL_PtrParam(_@(infoPtr));
        CALL_PtrParam(_@(slotNr));
        CALL__thiscall(_@(savManPtr), oCSavegameManager__SetAndWriteSavegame);

        // Clean up and return
        ASM_1(89);                          // pop  ecx
        ASM_1(94);                          // pop  esi
        ASM_1(194);     ASM_2(4);           // retn 4h
        code = CALL_Close();
    };
    return code;
};
