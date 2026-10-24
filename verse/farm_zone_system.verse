using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

resource_zone_device := class(creative_device):

    @editable
    ResourceProps : []creative_prop = array{}

    @editable
    UnlockButton : conditional_button_device = conditional_button_device{}

    @editable
    UnlockCostRemover : item_granter_device = item_granter_device{}

    @editable
    ResourceGranter : item_granter_device = item_granter_device{}

    @editable
    UnlockButtonHiddenMarker : billboard_device = billboard_device{}

    @editable
    UpgradeButtonVisibleMarker : billboard_device = billboard_device{}

    @editable
    BotGuards : []guard_spawner_device = array{}

    @editable
    BotSpawnMarkers : []billboard_device = array{}

    @editable
    BotVFX : []vfx_spawner_device = array{}

    @editable
    BotSFX : []audio_player_device = array{}

    @editable
    BotUpgradeButtons : []conditional_button_device = array{}

    @editable
    BotCostRemovers : []item_granter_device = array{}

    @editable
    BotCollectDelay : float = 3.0

    @editable
    BotVFXDelay : float = 3.0

    @editable
    BotVFXDuration : float = 0.5

    var ZoneOwner : ?agent = false
    var ActiveBotCount : int = 0
    var AutoCollectStarted : logic = false
    # Debounce: a held interact can fire the bot button twice → double bot / double
    # spend (the next button appears at the same spot). Blocks the second activation.
    var BotUpgradeBusy : logic = false

    OnBegin<override>()<suspends>:void=
        UpgradeButtonVisibleMarker.HideText()
        UnlockButtonHiddenMarker.HideText()

        HiddenPos := UnlockButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UnlockButtonHiddenMarker.GetTransform().Rotation

        for (Button : BotUpgradeButtons):
            Button.Disable()
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}

        for (Marker : BotSpawnMarkers):
            Marker.HideText()

        for (Prop : ResourceProps):
            Prop.Hide()

        SubscribeAllBotButtons()
        UnlockButton.ActivatedEvent.Subscribe(OnUnlock)

    SubscribeAllBotButtons():void=
        if (Button0 := BotUpgradeButtons[0]):
            Button0.ActivatedEvent.Subscribe(OnBotUpgrade0)
        if (Button1 := BotUpgradeButtons[1]):
            Button1.ActivatedEvent.Subscribe(OnBotUpgrade1)
        if (Button2 := BotUpgradeButtons[2]):
            Button2.ActivatedEvent.Subscribe(OnBotUpgrade2)
        if (Button3 := BotUpgradeButtons[3]):
            Button3.ActivatedEvent.Subscribe(OnBotUpgrade3)
        if (Button4 := BotUpgradeButtons[4]):
            Button4.ActivatedEvent.Subscribe(OnBotUpgrade4)
        if (Button5 := BotUpgradeButtons[5]):
            Button5.ActivatedEvent.Subscribe(OnBotUpgrade5)

    OnUnlock(Agent : agent):void=
        set ZoneOwner = option{Agent}
        UnlockCostRemover.GrantItem(Agent)

        for (Prop : ResourceProps):
            Prop.Show()

        HiddenPos := UnlockButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UnlockButtonHiddenMarker.GetTransform().Rotation
        if (UnlockButton.TeleportTo[HiddenPos, HiddenRot]) {}
        UnlockButton.Disable()

        if (FirstButton := BotUpgradeButtons[0]):
            VisiblePos := UpgradeButtonVisibleMarker.GetTransform().Translation
            VisibleRot := UpgradeButtonVisibleMarker.GetTransform().Rotation
            if (FirstButton.TeleportTo[VisiblePos, VisibleRot]) {}
            FirstButton.Enable()

    OnBotUpgrade0(Agent : agent):void= HandleBotUpgrade(0, Agent)
    OnBotUpgrade1(Agent : agent):void= HandleBotUpgrade(1, Agent)
    OnBotUpgrade2(Agent : agent):void= HandleBotUpgrade(2, Agent)
    OnBotUpgrade3(Agent : agent):void= HandleBotUpgrade(3, Agent)
    OnBotUpgrade4(Agent : agent):void= HandleBotUpgrade(4, Agent)
    OnBotUpgrade5(Agent : agent):void= HandleBotUpgrade(5, Agent)

    HandleBotUpgrade(Index : int, Agent : agent):void=
        # Ignore a second activation from the same held press.
        if (BotUpgradeBusy?):
            return
        if:
            CostRemover := BotCostRemovers[Index]
            Button := BotUpgradeButtons[Index]
        then:
            set BotUpgradeBusy = true
            CostRemover.GrantItem(Agent)
            
            HiddenPos := UnlockButtonHiddenMarker.GetTransform().Translation
            HiddenRot := UnlockButtonHiddenMarker.GetTransform().Rotation
            if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
            Button.Disable()

            set ActiveBotCount = ActiveBotCount + 1

            SpawnBot(Index)

            spawn { IndividualBotVFXLoop(Index) }

            StartAutoCollectIfNeeded()

            NextIndex := Index + 1
            if (NextIndex < BotUpgradeButtons.Length):
                if (NextButton := BotUpgradeButtons[NextIndex]):
                    VisiblePos := UpgradeButtonVisibleMarker.GetTransform().Translation
                    VisibleRot := UpgradeButtonVisibleMarker.GetTransform().Rotation
                    if (NextButton.TeleportTo[VisiblePos, VisibleRot]) {}
                    NextButton.Enable()

            spawn { ClearBotUpgradeBusy() }

    ClearBotUpgradeBusy()<suspends>:void=
        Sleep(0.5)
        set BotUpgradeBusy = false

    StartAutoCollectIfNeeded():void=
        if (AutoCollectStarted = false):
            set AutoCollectStarted = true
            spawn { GlobalAutoCollect() }

    SpawnBot(Index : int):void=
        if:
            Guard := BotGuards[Index]
            SpawnMarker := BotSpawnMarkers[Index]
        then:
            GuardPos := SpawnMarker.GetTransform().Translation
            GuardRot := SpawnMarker.GetTransform().Rotation

            if (Guard.TeleportTo[GuardPos, GuardRot]) {}
            Guard.Enable()
            Guard.Spawn()

            spawn { PlayBotVFX(Index) }

    IndividualBotVFXLoop(Index : int)<suspends>:void=
        loop:
            Sleep(BotVFXDelay)
            PlayBotVFX(Index)

    PlayBotVFX(Index : int)<suspends>:void=
        if:
            VFX := BotVFX[Index]
            SFX := BotSFX[Index]
        then:
            VFX.Enable()
            SFX.Play()
            Sleep(BotVFXDuration)
            VFX.Disable()

    GlobalAutoCollect()<suspends>:void=
        loop:
            Sleep(BotCollectDelay)

            if (Owner := ZoneOwner?):
                var i : int = 0
                loop:
                    if (i >= ActiveBotCount):
                        break
                    ResourceGranter.GrantItem(Owner)
                    set i = i + 1
