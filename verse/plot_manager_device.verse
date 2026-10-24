using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

plot_manager_device := class(creative_device):

    @editable
    Plots : []plant_growth_device = array{}

    @editable
    UnlockButtons : []conditional_button_device = array{}

    @editable
    CostRemovers : []item_granter_device = array{}

    @editable
    UnlockButtonVisibleMarkers : []billboard_device = array{}

    @editable
    UnlockButtonHiddenMarker : billboard_device = billboard_device{}

    # When true, the first plot (Plots[0]) is unlocked & planted at spawn (no cost),
    # so the player has a starter garden to harvest immediately (new tutorial flow).
    @editable
    StartWithFirstPlotUnlocked : logic = true

    var CurrentPlotIndex : int = 0

    OnBegin<override>()<suspends>:void=
        for (Marker : UnlockButtonVisibleMarkers):
            Marker.HideText()
        UnlockButtonHiddenMarker.HideText()

        for (Index -> Button : UnlockButtons):
            Button.ActivatedEvent.Subscribe(HandleUnlock)

        InitializeUnlockButtons()

        if (StartWithFirstPlotUnlocked?):
            AutoUnlockFirstPlot()

    # Unlocks & plants Plots[0] at spawn (no cost), then advances the visible unlock
    # button to index 1. Mirrors HandleUnlock(0) minus the cost grant.
    AutoUnlockFirstPlot():void=
        if (Plot := Plots[0]):
            spawn { Plot.UnlockPlot() }

        HiddenPos := UnlockButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UnlockButtonHiddenMarker.GetTransform().Rotation
        if (FirstButton := UnlockButtons[0]):
            if (FirstButton.TeleportTo[HiddenPos, HiddenRot]) {}
            FirstButton.Disable()

        set CurrentPlotIndex = 1

        if (NextButton := UnlockButtons[1]):
            if (NextMarker := UnlockButtonVisibleMarkers[1]):
                NextButtonPos := NextMarker.GetTransform().Translation
                NextButtonRot := NextMarker.GetTransform().Rotation
                if (NextButton.TeleportTo[NextButtonPos, NextButtonRot]) {}
                NextButton.Enable()

    InitializeUnlockButtons():void=
        HiddenPos := UnlockButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UnlockButtonHiddenMarker.GetTransform().Rotation

        for (Index -> Button : UnlockButtons):
            if (Index = 0):
                if (Marker := UnlockButtonVisibleMarkers[Index]):
                    ButtonPos := Marker.GetTransform().Translation
                    ButtonRot := Marker.GetTransform().Rotation
                    if (Button.TeleportTo[ButtonPos, ButtonRot]) {}
            else:
                if (Button.TeleportTo[HiddenPos, HiddenRot]) {}
                Button.Disable()

    HandleUnlock(Agent : agent):void=
        Index := CurrentPlotIndex

        if (CostRemover := CostRemovers[Index]):
            CostRemover.GrantItem(Agent)

        HiddenPos := UnlockButtonHiddenMarker.GetTransform().Translation
        HiddenRot := UnlockButtonHiddenMarker.GetTransform().Rotation

        if (CurrentButton := UnlockButtons[Index]):
            if (CurrentButton.TeleportTo[HiddenPos, HiddenRot]) {}
            CurrentButton.Disable()

        if (Plot := Plots[Index]):
            spawn { Plot.UnlockPlot() }

        NextIndex := Index + 1
        set CurrentPlotIndex = NextIndex

        if (NextButton := UnlockButtons[NextIndex]):
            if (NextMarker := UnlockButtonVisibleMarkers[NextIndex]):
                NextButtonPos := NextMarker.GetTransform().Translation
                NextButtonRot := NextMarker.GetTransform().Rotation
                if (NextButton.TeleportTo[NextButtonPos, NextButtonRot]) {}
                NextButton.Enable()
