using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# --- Localized base/billboard strings ---
# Real literals inside <localizes> functions. The composed "UNLOCKS" checklist is
# built from sub-messages ({Garden} etc.) so every translatable line is extracted
# while the symbolic "[X]"/"[ ]" checkbox stays a plain (untranslated) substitution.
BaseLvl1RequiredMsg<localizes>():message = "Base Lvl 1 Required"
BaseLvl2RequiredMsg<localizes>():message = "Base Lvl 2 Required"
BaseLvl3RequiredMsg<localizes>():message = "Base Lvl 3 Required"
BaseLevelMsg<localizes>(Level : int):message = "Base Level {Level}"
UnlocksDisplayMsg<localizes>(Garden : message, Forest : message, Stone : message, Metal : message):message = "UNLOCKS\n{Garden}\n{Forest}\n{Stone}\n{Metal}"
GardenLineMsg<localizes>(Box : string):message = "{Box} Garden (Lvl 1)"
ForestLineMsg<localizes>(Box : string):message = "{Box} Forest Zone (Lvl 1)"
StoneLineMsg<localizes>(Box : string):message = "{Box} Stone Mine (Lvl 2)"
MetalLineMsg<localizes>(Box : string):message = "{Box} Metal Mine (Lvl 3)"

base_upgrade_manager := class(creative_device):

    @editable
    BaseLevelDisplay : billboard_device = billboard_device{}

    @editable
    UnlocksDisplay : billboard_device = billboard_device{}

    var CurrentBaseLevel : int = 0

    # When true, the base starts already at Level 1 (new tutorial flow: no
    # pallet-breaking / first upgrade needed). The garden's starter plot is
    # unlocked separately by the plot_manager (StartWithFirstPlotUnlocked).
    @editable
    StartAtLevel1 : logic = true

    @editable
    MyWaveManager : Wave_Manager = Wave_Manager{}

    @editable
    BaseLevel0 : creative_prop = creative_prop{}

    @editable
    BaseLevel1 : creative_prop = creative_prop{}

    @editable
    BaseLevel2 : creative_prop = creative_prop{}

    @editable
    BaseLevel3 : creative_prop = creative_prop{}

    @editable
    UpgradeButton1 : conditional_button_device = conditional_button_device{}

    @editable
    UpgradeButton2 : conditional_button_device = conditional_button_device{}

    @editable
    UpgradeButton3 : conditional_button_device = conditional_button_device{}

    @editable
    CostRemover1 : item_granter_device = item_granter_device{}

    @editable
    CostRemover2 : item_granter_device = item_granter_device{}

    @editable
    CostRemover3 : item_granter_device = item_granter_device{}

    @editable
    UpgradeButton1VisibleMarker : billboard_device = billboard_device{}

    @editable
    UpgradeButton2VisibleMarker : billboard_device = billboard_device{}

    @editable
    UpgradeButton3VisibleMarker : billboard_device = billboard_device{}

    @editable
    UpgradeButtonHiddenMarker : billboard_device = billboard_device{}

    @editable
    FirstGardenUnlockButton : conditional_button_device = conditional_button_device{}

    @editable
    ForestZoneUnlockButton : conditional_button_device = conditional_button_device{}

    @editable
    StoneMineUnlockButton : conditional_button_device = conditional_button_device{}

    @editable
    MetalMineUnlockButton : conditional_button_device = conditional_button_device{}

    @editable
    FirstGardenRequirementBillboard : billboard_device = billboard_device{}

    @editable
    ForestZoneRequirementBillboard : billboard_device = billboard_device{}

    @editable
    StoneMineRequirementBillboard : billboard_device = billboard_device{}

    @editable
    MetalMineRequirementBillboard : billboard_device = billboard_device{}

    OnBegin<override>()<suspends>:void=
        UpgradeButton1VisibleMarker.HideText()
        UpgradeButton2VisibleMarker.HideText()
        UpgradeButton3VisibleMarker.HideText()
        UpgradeButtonHiddenMarker.HideText()

        UpgradeButton1.ActivatedEvent.Subscribe(OnUpgrade1)
        UpgradeButton2.ActivatedEvent.Subscribe(OnUpgrade2)
        UpgradeButton3.ActivatedEvent.Subscribe(OnUpgrade3)

        InitializeBase()

    InitializeBase():void=
        set CurrentBaseLevel = 0
        MyWaveManager.ApplyLevel(CurrentBaseLevel)
        UpdateBaseLevelDisplay()
        UpdateUnlocksDisplay()

        BaseLevel0.Show()
        BaseLevel1.Hide()
        BaseLevel2.Hide()
        BaseLevel3.Hide()

        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation

        Button1Pos := UpgradeButton1VisibleMarker.GetTransform().Translation
        Button1Rot := UpgradeButton1VisibleMarker.GetTransform().Rotation

        if (UpgradeButton1.TeleportTo[Button1Pos, Button1Rot]) {}
        UpgradeButton1.Enable()

        if (UpgradeButton2.TeleportTo[HiddenPos, HiddenRot]) {}
        UpgradeButton2.Disable()

        if (UpgradeButton3.TeleportTo[HiddenPos, HiddenRot]) {}
        UpgradeButton3.Disable()

        FirstGardenUnlockButton.Disable()
        ForestZoneUnlockButton.Disable()
        StoneMineUnlockButton.Disable()
        MetalMineUnlockButton.Disable()

        FirstGardenRequirementBillboard.SetText(BaseLvl1RequiredMsg())
        FirstGardenRequirementBillboard.ShowText()
        ForestZoneRequirementBillboard.SetText(BaseLvl1RequiredMsg())
        ForestZoneRequirementBillboard.ShowText()
        StoneMineRequirementBillboard.SetText(BaseLvl2RequiredMsg())
        StoneMineRequirementBillboard.ShowText()
        MetalMineRequirementBillboard.SetText(BaseLvl3RequiredMsg())
        MetalMineRequirementBillboard.ShowText()

        if (StartAtLevel1?):
            SetupLevel1StartState()

    # Puts the world in the post-"upgrade to Lvl 1" state at spawn, WITHOUT charging
    # the player and WITHOUT enabling a "buy garden" button (the starter plot is
    # auto-unlocked by the plot_manager). The forest stays a quest step (#3).
    SetupLevel1StartState():void=
        set CurrentBaseLevel = 1
        MyWaveManager.ApplyLevel(CurrentBaseLevel)
        UpdateBaseLevelDisplay()
        UpdateUnlocksDisplay()

        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation
        if (UpgradeButton1.TeleportTo[HiddenPos, HiddenRot]) {}
        UpgradeButton1.Disable()

        BaseLevel0.Hide()
        BaseLevel1.Show()

        Button2Pos := UpgradeButton2VisibleMarker.GetTransform().Translation
        Button2Rot := UpgradeButton2VisibleMarker.GetTransform().Rotation
        if (UpgradeButton2.TeleportTo[Button2Pos, Button2Rot]) {}
        UpgradeButton2.Enable()

        ForestZoneUnlockButton.Enable()
        ForestZoneRequirementBillboard.HideText()

        # Garden is free now (starter plot auto-unlocked), so no "buy garden" button.
        FirstGardenRequirementBillboard.HideText()

    OnUpgrade1(Agent : agent):void=
        CostRemover1.GrantItem(Agent)

        set CurrentBaseLevel = 1
        MyWaveManager.SetLevel(CurrentBaseLevel)
        UpdateBaseLevelDisplay()
        UpdateUnlocksDisplay()

        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation
        if (UpgradeButton1.TeleportTo[HiddenPos, HiddenRot]) {}
        UpgradeButton1.Disable()

        BaseLevel0.Hide()
        BaseLevel1.Show()

        Button2Pos := UpgradeButton2VisibleMarker.GetTransform().Translation
        Button2Rot := UpgradeButton2VisibleMarker.GetTransform().Rotation
        if (UpgradeButton2.TeleportTo[Button2Pos, Button2Rot]) {}
        UpgradeButton2.Enable()

        FirstGardenUnlockButton.Enable()
        ForestZoneUnlockButton.Enable()

        FirstGardenRequirementBillboard.HideText()
        ForestZoneRequirementBillboard.HideText()

    OnUpgrade2(Agent : agent):void=
        CostRemover2.GrantItem(Agent)

        set CurrentBaseLevel = 2
        MyWaveManager.SetLevel(CurrentBaseLevel)
        UpdateBaseLevelDisplay()
        UpdateUnlocksDisplay()

        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation
        if (UpgradeButton2.TeleportTo[HiddenPos, HiddenRot]) {}
        UpgradeButton2.Disable()

        BaseLevel1.Hide()
        BaseLevel2.Show()

        Button3Pos := UpgradeButton3VisibleMarker.GetTransform().Translation
        Button3Rot := UpgradeButton3VisibleMarker.GetTransform().Rotation
        if (UpgradeButton3.TeleportTo[Button3Pos, Button3Rot]) {}
        UpgradeButton3.Enable()

        StoneMineUnlockButton.Enable()

        StoneMineRequirementBillboard.HideText()

    OnUpgrade3(Agent : agent):void=
        CostRemover3.GrantItem(Agent)

        set CurrentBaseLevel = 3
        MyWaveManager.SetLevel(CurrentBaseLevel)
        UpdateBaseLevelDisplay()
        UpdateUnlocksDisplay()

        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation
        if (UpgradeButton3.TeleportTo[HiddenPos, HiddenRot]) {}
        UpgradeButton3.Disable()

        BaseLevel2.Hide()
        BaseLevel3.Show()

        MetalMineUnlockButton.Enable()

        MetalMineRequirementBillboard.HideText()

    UpdateBaseLevelDisplay():void=
        BaseLevelDisplay.SetText(BaseLevelMsg(CurrentBaseLevel))
        BaseLevelDisplay.ShowText()

    UpdateUnlocksDisplay():void=
        # Checkboxes are symbolic (not translated); the labels live in the
        # per-line <localizes> functions, composed into one message below.
        var GardenBox : string = "[ ]"
        var ForestBox : string = "[ ]"
        var StoneBox : string = "[ ]"
        var MetalBox : string = "[ ]"

        if (CurrentBaseLevel >= 1):
            set GardenBox = "[X]"
            set ForestBox = "[X]"
        if (CurrentBaseLevel >= 2):
            set StoneBox = "[X]"
        if (CurrentBaseLevel >= 3):
            set MetalBox = "[X]"

        UnlocksMessage := UnlocksDisplayMsg(
            GardenLineMsg(GardenBox),
            ForestLineMsg(ForestBox),
            StoneLineMsg(StoneBox),
            MetalLineMsg(MetalBox))
        UnlocksDisplay.SetText(UnlocksMessage)
        UnlocksDisplay.ShowText()
