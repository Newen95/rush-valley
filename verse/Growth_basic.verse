using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

# --- Localized plant-info string ---
# Real literal inside a <localizes> function with substitution placeholders the
# translator keeps. The "[AUTO]" tag is its own message so it's translatable too.
PlantInfoMsg<localizes>(Prestige : int, Upgrade : int, Gold : int, Mode : message):message = "Lvl {Prestige} | Prestige {Upgrade}\n+{Gold} Gold/Harvest\n{Mode}"
AutoModeMsg<localizes>():message = "[AUTO]"
EmptyModeMsg<localizes>():message = ""

plant_growth_device := class(creative_device):

    @editable
    PlantStagesLevel1 : []creative_prop = array{}

    @editable
    PlantStagesLevel2 : []creative_prop = array{}

    @editable
    PlantStagesLevel3 : []creative_prop = array{}

    @editable
    PlantStagesLevel4 : []creative_prop = array{}

    @editable
    BubbleProp : creative_prop = creative_prop{}

    @editable
    PlotProp : creative_prop = creative_prop{}

    @editable
    HarvestButton : button_device = button_device{}

    @editable
    UpgradeButtonsLevel1 : []conditional_button_device = array{}

    @editable
    UpgradeButtonsLevel2 : []conditional_button_device = array{}

    @editable
    UpgradeButtonsLevel3 : []conditional_button_device = array{}

    @editable
    UpgradeButtonsLevel4 : []conditional_button_device = array{}

    @editable
    UpgradeCostRemoversLevel1 : []item_granter_device = array{}

    @editable
    UpgradeCostRemoversLevel2 : []item_granter_device = array{}

    @editable
    UpgradeCostRemoversLevel3 : []item_granter_device = array{}

    @editable
    UpgradeCostRemoversLevel4 : []item_granter_device = array{}

    @editable
    UpgradeButtonVisibleMarker : billboard_device = billboard_device{}

    @editable
    UpgradeButtonHiddenMarker : billboard_device = billboard_device{}

    @editable
    HarvestButtonVisibleMarker : billboard_device = billboard_device{}

    @editable
    AutoHarvestButtonVisibleMarker : billboard_device = billboard_device{}

    @editable
    PrestigeButtonVisibleMarker : billboard_device = billboard_device{}

    @editable
    AutoHarvestButton : conditional_button_device = conditional_button_device{}

    @editable
    AutoHarvestCostRemover : item_granter_device = item_granter_device{}

    @editable
    PrestigeButtons : []conditional_button_device = array{}

    @editable
    PrestigeCostRemovers : []item_granter_device = array{}

    @editable
    GoldGrantersLevel1 : []item_granter_device = array{}

    @editable
    GoldGrantersLevel2 : []item_granter_device = array{}

    @editable
    GoldGrantersLevel3 : []item_granter_device = array{}

    @editable
    GoldGrantersLevel4 : []item_granter_device = array{}

    @editable
    PlantationVFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    GrowthVFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    HarvestVFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    UpgradeVFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    PrestigeVFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    AutoHarvestVFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    PlantationSFX : audio_player_device = audio_player_device{}

    @editable
    GrowthSFX : audio_player_device = audio_player_device{}

    @editable
    HarvestSFX : audio_player_device = audio_player_device{}

    @editable
    UpgradeSFX : audio_player_device = audio_player_device{}

    @editable
    PrestigeSFX : audio_player_device = audio_player_device{}

    @editable
    AutoHarvestSFX : audio_player_device = audio_player_device{}

    @editable
    GrowthTime : float = 2.0

    @editable
    AutoHarvestDelay : float = 1.5

    @editable
    PlantInfoBillboard : billboard_device = billboard_device{}

    @editable
    GoldValuesLevel1 : []int = array{}

    @editable
    GoldValuesLevel2 : []int = array{}

    @editable
    GoldValuesLevel3 : []int = array{}

    @editable
    GoldValuesLevel4 : []int = array{}

    @editable
    PrestigeTransitionDelay : float = 2.0

    @editable
    RegrowthDelay : float = 3.0

    var IsUnlocked : logic = false
    var CurrentPrestigeLevel : int = 1
    var CurrentUpgradeLevel : int = 0
    var IsAutoHarvestEnabled : logic = false
    var AutoHarvestOwner : ?agent = false
    var IsReadyToHarvest : logic = false
    var CurrentGrowthStage : int = 0
    var IsGrowing : logic = false
    var VFXInitialized : logic = false

    # Incremented on every successful harvest. Read by Quest_Manager to detect the
    # very first harvest of the starter plot (tutorial quest #1).
    var HarvestCount : int = 0

    # Debounce guards: a held interact can fire a conditional_button's ActivatedEvent
    # twice, causing an accidental DOUBLE upgrade/prestige (and double spend). These
    # block the second activation.
    var UpgradeBusy : logic = false
    var PrestigeBusy : logic = false

    OnBegin<override>()<suspends>:void=
        UpgradeButtonVisibleMarker.HideText()
        UpgradeButtonHiddenMarker.HideText()
        HarvestButtonVisibleMarker.HideText()
        AutoHarvestButtonVisibleMarker.HideText()
        PrestigeButtonVisibleMarker.HideText()

        HideAllUpgradeButtons()
        HideAllPrestigeButtons()
        HideConditionalButtons()
        HideHarvestButton()
        HidePlot()
        BubbleProp.Hide()

        ForceStopAllVFX()
        Sleep(0.1)
        ForceStopAllVFX()

        set VFXInitialized = true

    ForceStopAllVFX():void=
        PlantationVFX.Disable()
        GrowthVFX.Disable()
        HarvestVFX.Disable()
        UpgradeVFX.Disable()
        PrestigeVFX.Disable()
        AutoHarvestVFX.Disable()

    HideAllUpgradeButtons():void=
        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation

        for (Button : UpgradeButtonsLevel1):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

        for (Button : UpgradeButtonsLevel2):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

        for (Button : UpgradeButtonsLevel3):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

        for (Button : UpgradeButtonsLevel4):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

    HideAllPrestigeButtons():void=
        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation

        for (Button : PrestigeButtons):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

    HideConditionalButtons():void=
        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation

        if (AutoHarvestButton.TeleportTo[HiddenPos, HiddenRot]) {}
        AutoHarvestButton.Disable()

    HideHarvestButton():void=
        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation
        if (HarvestButton.TeleportTo[HiddenPos, HiddenRot]) {}
        HarvestButton.Disable()

    ShowHarvestButton():void=
        VisiblePos := HarvestButtonVisibleMarker.GetTransform().Translation
        VisibleRot := HarvestButtonVisibleMarker.GetTransform().Rotation
        if (HarvestButton.TeleportTo[VisiblePos, VisibleRot]) {}
        HarvestButton.Enable()

    ShowConditionalButtons():void=
        AutoHarvestPos := AutoHarvestButtonVisibleMarker.GetTransform().Translation
        AutoHarvestRot := AutoHarvestButtonVisibleMarker.GetTransform().Rotation

        if (AutoHarvestButton.TeleportTo[AutoHarvestPos, AutoHarvestRot]) {}
        AutoHarvestButton.Enable()

        UpdatePrestigeButtonVisibility()

    GetMaxPrestigeLevel():int=
        AllPlantStages := array{PlantStagesLevel1, PlantStagesLevel2, PlantStagesLevel3, PlantStagesLevel4}
        var MaxLevel : int = 0
        
        for (Index -> Stages : AllPlantStages):
            if (Stages.Length > 0):
                set MaxLevel = Index + 1
        
        return MaxLevel

    UpdatePrestigeButtonVisibility():void=
        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation
        VisiblePos := PrestigeButtonVisibleMarker.GetTransform().Translation
        VisibleRot := PrestigeButtonVisibleMarker.GetTransform().Rotation

        MaxPrestigeLevel := GetMaxPrestigeLevel()

        for (Button : PrestigeButtons):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

        if (CurrentPrestigeLevel < MaxPrestigeLevel):
            PrestigeButtonIndex := CurrentPrestigeLevel - 1
            if (PrestigeButtonIndex >= 0, PrestigeButtonIndex < PrestigeButtons.Length):
                if (ActivePrestigeButton := PrestigeButtons[PrestigeButtonIndex]):
                    if (ActivePrestigeButton.TeleportTo[VisiblePos, VisibleRot]) {}
                    ActivePrestigeButton.Enable()

    UnlockPlot()<suspends>:void=
        set IsUnlocked = true

        HarvestButton.InteractedWithEvent.Subscribe(OnHarvest)
        AutoHarvestButton.ActivatedEvent.Subscribe(OnAutoHarvestPurchased)

        for (Index -> Button : PrestigeButtons):
            Button.ActivatedEvent.Subscribe(OnPrestigeButtonActivated)

        for (Button : UpgradeButtonsLevel1):
            Button.ActivatedEvent.Subscribe(OnUpgradeLevel1)

        for (Button : UpgradeButtonsLevel2):
            Button.ActivatedEvent.Subscribe(OnUpgradeLevel2)

        for (Button : UpgradeButtonsLevel3):
            Button.ActivatedEvent.Subscribe(OnUpgradeLevel3)

        for (Button : UpgradeButtonsLevel4):
            Button.ActivatedEvent.Subscribe(OnUpgradeLevel4)

        ShowPlot()
        ShowConditionalButtons()
        ShowHarvestButton()
        TeleportUpgradeButtonsForPrestigeLevel()
        UpdateUpgradeButtonsVisibility()
        UpdatePlantInfoDisplay()

        spawn { StartGrowthCycle() }

    ShowPlot():void=
        PlotProp.Show()

    HidePlot():void=
        PlotProp.Hide()
        HideAllPlants()
        HideHarvestButton()
        HideAllUpgradeButtons()
        HideAllPrestigeButtons()
        HideConditionalButtons()

    HideAllPlants():void=
        for (Stage : PlantStagesLevel1):
            Stage.Hide()
        for (Stage : PlantStagesLevel2):
            Stage.Hide()
        for (Stage : PlantStagesLevel3):
            Stage.Hide()
        for (Stage : PlantStagesLevel4):
            Stage.Hide()
        BubbleProp.Hide()

    GetButtonIndexToShow(MaxLevel : int):int=
        if (CurrentUpgradeLevel > MaxLevel):
            return MaxLevel
        else:
            return CurrentUpgradeLevel

    IsUpgradeMaxedOut(MaxLevel : int):logic=
        if (CurrentUpgradeLevel > MaxLevel):
            return true
        else:
            return false

    GetCurrentUpgradeButtons():[]conditional_button_device=
        if (CurrentPrestigeLevel = 1):
            return UpgradeButtonsLevel1
        else if (CurrentPrestigeLevel = 2):
            return UpgradeButtonsLevel2
        else if (CurrentPrestigeLevel = 3):
            return UpgradeButtonsLevel3
        else:
            return UpgradeButtonsLevel4

    GetCurrentUpgradeCostRemovers():[]item_granter_device=
        if (CurrentPrestigeLevel = 1):
            return UpgradeCostRemoversLevel1
        else if (CurrentPrestigeLevel = 2):
            return UpgradeCostRemoversLevel2
        else if (CurrentPrestigeLevel = 3):
            return UpgradeCostRemoversLevel3
        else:
            return UpgradeCostRemoversLevel4

    TeleportUpgradeButtonsForPrestigeLevel():void=
        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation
        VisiblePos := UpgradeButtonVisibleMarker.GetTransform().Translation
        VisibleRot := UpgradeButtonVisibleMarker.GetTransform().Rotation

        for (Button : UpgradeButtonsLevel1):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

        for (Button : UpgradeButtonsLevel2):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

        for (Button : UpgradeButtonsLevel3):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

        for (Button : UpgradeButtonsLevel4):
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

        CurrentButtons := GetCurrentUpgradeButtons()
        MaxLevel := CurrentButtons.Length - 1
        ButtonIndex := GetButtonIndexToShow(MaxLevel)
        
        if (ButtonIndex >= 0, ActiveButton := CurrentButtons[ButtonIndex]):
            if (ActiveButton.TeleportTo[VisiblePos, VisibleRot]) {}

    UpdateUpgradeButtonsVisibility():void=
        HiddenPos := UpgradeButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UpgradeButtonHiddenMarker.GetTransform().Rotation
        VisiblePos := UpgradeButtonVisibleMarker.GetTransform().Translation
        VisibleRot := UpgradeButtonVisibleMarker.GetTransform().Rotation

        CurrentButtons := GetCurrentUpgradeButtons()
        MaxLevel := CurrentButtons.Length - 1

        ButtonIndexToShow := GetButtonIndexToShow(MaxLevel)
        IsMaxedOut := IsUpgradeMaxedOut(MaxLevel)

        for (Index -> Button : CurrentButtons):
            # Only the active, not-yet-maxed button stays at the visible marker.
            # When maxed out, teleport it to the hidden marker too (Disable alone
            # just turns it red without removing it).
            if (Index = ButtonIndexToShow, IsMaxedOut = false):
                if (Button.TeleportTo[VisiblePos, VisibleRot]) {}
                Button.Enable()
            else:
                if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
                Button.Disable()

    OnPrestigeButtonActivated(Agent : agent):void=
        # Guard here (synchronous) so two rapid activations can't both spawn.
        if (PrestigeBusy?):
            return
        set PrestigeBusy = true
        spawn { HandlePrestige(Agent) }

    HandlePrestige(Agent : agent)<suspends>:void=
        MaxPrestigeLevel := GetMaxPrestigeLevel()

        if (CurrentPrestigeLevel < MaxPrestigeLevel):
            PrestigeCostIndex := CurrentPrestigeLevel - 1
            if (PrestigeCostIndex >= 0, PrestigeCostIndex < PrestigeCostRemovers.Length):
                if (CostRemover := PrestigeCostRemovers[PrestigeCostIndex]):
                    CostRemover.GrantItem(Agent)

            PlayPrestigeEffect()

            set IsGrowing = false
            set IsReadyToHarvest = false
            BubbleProp.Hide()
            HideAllPlants()

            set CurrentPrestigeLevel += 1
            set CurrentUpgradeLevel = 0

            TeleportUpgradeButtonsForPrestigeLevel()
            UpdateUpgradeButtonsVisibility()
            UpdatePrestigeButtonVisibility()
            UpdatePlantInfoDisplay()

            Sleep(PrestigeTransitionDelay)

            spawn { StartGrowthCycle() }

        # Release the guard once the transition is done (or immediately if maxed).
        set PrestigeBusy = false

    GetCurrentPlantStages():[]creative_prop=
        if (CurrentPrestigeLevel = 1):
            return PlantStagesLevel1
        else if (CurrentPrestigeLevel = 2):
            return PlantStagesLevel2
        else if (CurrentPrestigeLevel = 3):
            return PlantStagesLevel3
        else:
            return PlantStagesLevel4

    StartGrowthCycle()<suspends>:void=
        if (IsGrowing = true):
            return

        if (IsUnlocked = false):
            return

        set IsGrowing = true
        set IsReadyToHarvest = false
        set CurrentGrowthStage = 0
        HideAllPlants()
        BubbleProp.Hide()

        CurrentStages := GetCurrentPlantStages()
        StageCount := CurrentStages.Length

        if (StageCount = 0):
            set IsGrowing = false
            return

        for (Index := 0..StageCount - 1):
            if (IsUnlocked = false):
                set IsGrowing = false
                return

            if (IsGrowing = false):
                return

            set CurrentGrowthStage = Index
            ShowStage(Index)

            if (Index = 0):
                PlayPlantationEffect()
            else:
                PlayGrowthEffect()

            if (Index < StageCount - 1):
                Sleep(GrowthTime)

        set IsReadyToHarvest = true
        BubbleProp.Show()
        set IsGrowing = false

        if (IsAutoHarvestEnabled = true, Owner := AutoHarvestOwner?):
            Sleep(AutoHarvestDelay)
            if (IsReadyToHarvest = true):
                PerformHarvest(Owner)
                Sleep(RegrowthDelay)
                spawn { StartGrowthCycle() }
        else:
            spawn { WaitForManualHarvest() }

    ShowStage(Index : int):void=
        CurrentStages := GetCurrentPlantStages()

        for (Stage : PlantStagesLevel1):
            Stage.Hide()
        for (Stage : PlantStagesLevel2):
            Stage.Hide()
        for (Stage : PlantStagesLevel3):
            Stage.Hide()
        for (Stage : PlantStagesLevel4):
            Stage.Hide()

        for (I -> Stage : CurrentStages):
            if (I = Index):
                Stage.Show()
            else:
                Stage.Hide()

    WaitForManualHarvest()<suspends>:void=
        loop:
            Sleep(0.1)

            if (IsReadyToHarvest = false):
                Sleep(RegrowthDelay)
                spawn { StartGrowthCycle() }
                return

            if (IsAutoHarvestEnabled = true, Owner := AutoHarvestOwner?):
                Sleep(AutoHarvestDelay)
                if (IsReadyToHarvest = true):
                    PerformHarvest(Owner)
                    Sleep(RegrowthDelay)
                    spawn { StartGrowthCycle() }
                return

    OnHarvest(Agent : agent):void=
        if (IsReadyToHarvest = true, IsGrowing = false):
            PerformHarvest(Agent)

    PerformHarvest(Agent : agent):void=
        if (IsReadyToHarvest = true, IsGrowing = false):
            PlayHarvestEffect()
            GrantGold(Agent)
            set IsReadyToHarvest = false
            set HarvestCount += 1
            BubbleProp.Hide()
            HideAllPlants()

    GetCurrentGoldGranters():[]item_granter_device=
        if (CurrentPrestigeLevel = 1):
            return GoldGrantersLevel1
        else if (CurrentPrestigeLevel = 2):
            return GoldGrantersLevel2
        else if (CurrentPrestigeLevel = 3):
            return GoldGrantersLevel3
        else:
            return GoldGrantersLevel4

    GrantGold(Agent : agent):void=
        CurrentGranters := GetCurrentGoldGranters()

        if (CurrentUpgradeLevel >= 0, CurrentUpgradeLevel < CurrentGranters.Length):
            if (Granter := CurrentGranters[CurrentUpgradeLevel]):
                Granter.GrantItem(Agent)

    OnUpgradeLevel1(Agent : agent):void=
        if (CurrentPrestigeLevel = 1):
            OnUpgrade(Agent, UpgradeButtonsLevel1, UpgradeCostRemoversLevel1)

    OnUpgradeLevel2(Agent : agent):void=
        if (CurrentPrestigeLevel = 2):
            OnUpgrade(Agent, UpgradeButtonsLevel2, UpgradeCostRemoversLevel2)

    OnUpgradeLevel3(Agent : agent):void=
        if (CurrentPrestigeLevel = 3):
            OnUpgrade(Agent, UpgradeButtonsLevel3, UpgradeCostRemoversLevel3)

    OnUpgradeLevel4(Agent : agent):void=
        if (CurrentPrestigeLevel = 4):
            OnUpgrade(Agent, UpgradeButtonsLevel4, UpgradeCostRemoversLevel4)

    OnUpgrade(Agent : agent, Buttons : []conditional_button_device, CostRemovers : []item_granter_device):void=
        # Ignore a second activation from the same held press.
        if (UpgradeBusy?):
            return
        MaxLevel := Buttons.Length - 1

        if (CurrentUpgradeLevel <= MaxLevel):
            set UpgradeBusy = true
            if (Remover := CostRemovers[CurrentUpgradeLevel]):
                Remover.GrantItem(Agent)

            PlayUpgradeEffect()

            set CurrentUpgradeLevel += 1
            UpdateUpgradeButtonsVisibility()
            UpdatePlantInfoDisplay()

            spawn { ClearUpgradeBusy() }

    ClearUpgradeBusy()<suspends>:void=
        Sleep(0.5)
        set UpgradeBusy = false

    OnAutoHarvestPurchased(Agent : agent):void=
        if (IsAutoHarvestEnabled = false):
            AutoHarvestCostRemover.GrantItem(Agent)
            PlayAutoHarvestEffect()

            set IsAutoHarvestEnabled = true
            set AutoHarvestOwner = option{Agent}
            # Teleport the button to the hidden marker (not just Disable), so it
            # actually disappears like the upgrade buttons do.
            HideConditionalButtons()
            HideHarvestButton()
            UpdatePlantInfoDisplay()

    PlayPlantationEffect():void=
        if (VFXInitialized = true):
            PlantationVFX.Disable()
            PlantationVFX.Enable()
            # Restart via helper so rapid re-clicks replay the sound (Stop + 1 frame + Play)
            spawn { RestartSFX(PlantationSFX) }
            spawn { DisableVFXAfterDelay(PlantationVFX, 0.5) }

    PlayGrowthEffect():void=
        if (VFXInitialized = true):
            GrowthVFX.Disable()
            GrowthVFX.Enable()
            # Restart via helper so rapid re-clicks replay the sound (Stop + 1 frame + Play)
            spawn { RestartSFX(GrowthSFX) }
            spawn { DisableVFXAfterDelay(GrowthVFX, 0.3) }

    PlayHarvestEffect():void=
        if (VFXInitialized = true):
            HarvestVFX.Disable()
            HarvestVFX.Enable()
            # Restart via helper so rapid re-clicks replay the sound (Stop + 1 frame + Play)
            spawn { RestartSFX(HarvestSFX) }
            spawn { DisableVFXAfterDelay(HarvestVFX, 1.0) }

    PlayUpgradeEffect():void=
        if (VFXInitialized = true):
            UpgradeVFX.Disable()
            UpgradeVFX.Enable()
            # Restart via helper so rapid re-clicks replay the sound (Stop + 1 frame + Play)
            spawn { RestartSFX(UpgradeSFX) }
            spawn { DisableVFXAfterDelay(UpgradeVFX, 0.8) }

    PlayPrestigeEffect():void=
        if (VFXInitialized = true):
            PrestigeVFX.Disable()
            PrestigeVFX.Enable()
            # Restart via helper so rapid re-clicks replay the sound (Stop + 1 frame + Play)
            spawn { RestartSFX(PrestigeSFX) }
            spawn { DisableVFXAfterDelay(PrestigeVFX, 2.0) }

    PlayAutoHarvestEffect():void=
        if (VFXInitialized = true):
            AutoHarvestVFX.Disable()
            AutoHarvestVFX.Enable()
            # Restart via helper so rapid re-clicks replay the sound (Stop + 1 frame + Play)
            spawn { RestartSFX(AutoHarvestSFX) }
            spawn { DisableVFXAfterDelay(AutoHarvestVFX, 1.0) }

    # Restarts an audio device so it can replay on rapid re-clicks.
    # Stop() and Play() in the same frame is unreliable (the device processes
    # Stop at end of frame, cancelling the Play), so we yield one frame between.
    RestartSFX(SFX : audio_player_device)<suspends>:void=
        SFX.Stop()
        Sleep(0.0)
        SFX.Play()

    DisableVFXAfterDelay(VFXDevice : vfx_spawner_device, Delay : float)<suspends>:void=
        Sleep(Delay)
        VFXDevice.Disable()

    GetCurrentGoldValues():[]int=
        if (CurrentPrestigeLevel = 1):
            return GoldValuesLevel1
        else if (CurrentPrestigeLevel = 2):
            return GoldValuesLevel2
        else if (CurrentPrestigeLevel = 3):
            return GoldValuesLevel3
        else:
            return GoldValuesLevel4

    GetCurrentGoldValue():int=
        GoldValues := GetCurrentGoldValues()
        if (CurrentUpgradeLevel >= 0, CurrentUpgradeLevel < GoldValues.Length):
            if (Value := GoldValues[CurrentUpgradeLevel]):
                return Value
        return 0

    UpdatePlantInfoDisplay():void=
        GoldValue := GetCurrentGoldValue()
        var ModeMsg : message = EmptyModeMsg()
        if (IsAutoHarvestEnabled?):
            set ModeMsg = AutoModeMsg()
        DisplayUpgrade := CurrentUpgradeLevel + 1
        PlantInfoBillboard.SetText(PlantInfoMsg(CurrentPrestigeLevel, DisplayUpgrade, GoldValue, ModeMsg))
        PlantInfoBillboard.ShowText()
