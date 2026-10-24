using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

# --- Localized quest strings ---
# Real literals inside <localizes> functions so the localization gather extracts
# them (a generic "{Text}" passthrough only registered the token, never the text).
# These are the English SOURCE; Auto Localization translates them into every culture.
QuestStep1Msg<localizes>():message = "Harvest your vegetable garden"
QuestStep2Msg<localizes>():message = "Improve your harvest"
QuestStep3Msg<localizes>():message = "Unlock the Forest"
QuestStep4Msg<localizes>():message = "Hire a lumberjack"
QuestStep5Msg<localizes>():message = "Upgrade your vegetable garden to Level 2"
QuestStep6Msg<localizes>():message = "Unlock a second vegetable garden"
QuestStep7Msg<localizes>():message = "Trigger the first zombie wave"
QuestStep8Msg<localizes>():message = "Upgrade your base to Level 2"
QuestStep9Msg<localizes>():message = "Unlock the Stone Mine"
QuestStep10Msg<localizes>():message = "Buy your first trophy"
QuestAllDoneMsg<localizes>():message = "Well done! Now unlock all 7 trophies as fast as you can!"
QuestCompleteMsg<localizes>(StepNumber : int, GoldAmount : int):message = "Quest {StepNumber}/10 complete! +{GoldAmount} Gold"
EmptyQuestMsg<localizes>():message = ""

Quest_Manager := class(creative_device):

    @editable
    BaseManager : base_upgrade_manager = base_upgrade_manager{}

    # Starter garden plot (Plots[0] of the plot_manager). Used to detect the first
    # harvest (#1), the crop-yield upgrade (#2, in-game "prestige") and the garden
    # level-up (#5, in-game "potager niv2"). NOTE the code<->UX naming swap:
    #   in-game "prestige"  == CurrentUpgradeLevel  (yield boost, cheap)
    #   in-game "garden lvl" == CurrentPrestigeLevel (structural, resets the above)
    @editable
    StarterPlot : plant_growth_device = plant_growth_device{}

    @editable
    ForestUnlockButton : conditional_button_device = conditional_button_device{}

    # "Hire a lumberjack" button = first bot button of the Forest resource zone.
    @editable
    LumberjackButton : conditional_button_device = conditional_button_device{}

    # Used to detect the 2nd garden plot unlock (CurrentPlotIndex goes 0 -> 1).
    @editable
    PlotManager : plot_manager_device = plot_manager_device{}

    # The wave Start button (same device the Wave_Manager listens to).
    @editable
    WaveStartButton : button_device = button_device{}

    @editable
    StoneUnlockButton : conditional_button_device = conditional_button_device{}

    # The first trophy's purchase button (cheapest; the intended tutorial target,
    # also flagged visually for the player). Buying it completes quest #10.
    @editable
    Trophy1Button : conditional_button_device = conditional_button_device{}

    @editable
    QuestHUD : hud_message_device = hud_message_device{}

    @editable
    RewardGranter : item_granter_device = item_granter_device{}

    @editable
    QuestCompleteSound : audio_player_device = audio_player_device{}

    # Played when a NEW quest title appears (in ShowNewQuest). Pick a short UI
    # "notification / objective received" sound on this device in the editor.
    @editable
    QuestStartSound : audio_player_device = audio_player_device{}

    # Coin/gold chime, played slightly AFTER the completion sound to reinforce the
    # reward ("ding" then *coins*). Pick a short coin/money sound in the editor.
    @editable
    GoldSound : audio_player_device = audio_player_device{}

    # Delay between the completion sound and the coin sound (the "one-two" gap).
    @editable
    GoldSoundDelay : float = 0.35

    # Minimum time a freshly-shown quest title stays on screen before its completion
    # can register. Guarantees the player always SEES a new quest, even if its action
    # was already done (otherwise the title would flash by in milliseconds).
    @editable
    NewQuestDisplayTime : float = 1.5

    # --- Quest beacon (visual "go here" indicator) ---
    # Beacon device set to the "Arrow" particle style: a downward-pointing arrow that
    # hovers and bobs on its own above the active quest's target. The device handles the
    # animation AND orientation, so the code only teleports it onto the target + toggles it.
    @editable
    QuestArrowBeacon : beacon_device = beacon_device{}

    # Minimap / overview-map marker for the active quest's target. Teleported and toggled
    # in lockstep with the arrow beacon. Configure its icon/color in the editor.
    @editable
    QuestMapIndicator : map_indicator_device = map_indicator_device{}

    # One position marker per quest (index 0 -> quest 1, ... index 9 -> quest 10).
    # The beacon teleports onto QuestTargetMarkers[StepNumber-1] for each quest.
    @editable
    QuestTargetMarkers : []billboard_device = array{}

    # Extra Z offset above the marker. The beacon arrow already floats by itself, so 0 is
    # usually fine; raise it if the arrow sits too low/high over the target.
    @editable
    ArrowHeight : float = 0.0

    # Duration of the ONE-SHOT directional pulse fired toward the target when a new quest
    # appears: a single attention ping, then it stops (no continuous nagging for players
    # going at their own pace). Set to 0 to effectively disable the ping.
    @editable
    ObjectivePulseTime : float = 1.5

    # Purchase/trigger flags, tracked from the start so a quest still completes if the
    # action was done before that quest step was reached.
    var ForestBought : logic = false
    var LumberjackHired : logic = false
    var StoneBought : logic = false
    var WaveStarted : logic = false
    var TrophyBought : logic = false

    var QuestTextBlocks : []text_block = array{}
    # Root canvas + owning player of each on-screen quest HUD, kept so the HUD can be
    # removed once the quest line is finished (clean screen for the trophy-hunt phase).
    var QuestHUDEntries : []tuple(player, canvas) = array{}
    # NOTE: a <localizes> call is "divergent" and can't be a data-member default,
    # so this is an optional message (none until the first quest title is set).
    var CurrentQuestMessage : ?message = false

    OnBegin<override>()<suspends>:void=
        ForestUnlockButton.ActivatedEvent.Subscribe(OnForestBought)
        LumberjackButton.ActivatedEvent.Subscribe(OnLumberjackHired)
        StoneUnlockButton.ActivatedEvent.Subscribe(OnStoneBought)
        WaveStartButton.InteractedWithEvent.Subscribe(OnWaveStarted)
        Trophy1Button.ActivatedEvent.Subscribe(OnTrophyBought)

        QuestArrowBeacon.Disable()
        QuestMapIndicator.Disable()

        spawn{SetupQuestHUD()}

        Sleep(2.0)
        StartQuestLine()

    OnForestBought(Agent : agent):void= set ForestBought = true
    OnLumberjackHired(Agent : agent):void= set LumberjackHired = true
    OnStoneBought(Agent : agent):void= set StoneBought = true
    OnWaveStarted(Agent : agent):void= set WaveStarted = true
    OnTrophyBought(Agent : agent):void= set TrophyBought = true

    StartQuestLine()<suspends>:void=

        ShowNewQuest(1, QuestStep1Msg())
        WaitUntilHarvested()
        CompleteQuest(1, 100)

        ShowNewQuest(2, QuestStep2Msg())
        WaitUntilCropUpgraded()
        CompleteQuest(2, 100)

        ShowNewQuest(3, QuestStep3Msg())
        WaitUntilForestBought()
        CompleteQuest(3, 100)

        ShowNewQuest(4, QuestStep4Msg())
        WaitUntilLumberjackHired()
        CompleteQuest(4, 100)

        ShowNewQuest(5, QuestStep5Msg())
        WaitUntilGardenLevel(2)
        CompleteQuest(5, 100)

        ShowNewQuest(6, QuestStep6Msg())
        WaitUntilSecondPlot()
        CompleteQuest(6, 100)

        ShowNewQuest(7, QuestStep7Msg())
        WaitUntilWaveStarted()
        CompleteQuest(7, 100)

        ShowNewQuest(8, QuestStep8Msg())
        WaitUntilBaseLevel(2)
        CompleteQuest(8, 100)

        ShowNewQuest(9, QuestStep9Msg())
        WaitUntilStoneBought()
        CompleteQuest(9, 100)

        ShowNewQuest(10, QuestStep10Msg())
        WaitUntilTrophyBought()
        CompleteQuest(10, 100)

        UpdateQuestTitle(QuestAllDoneMsg())
        QuestCompleteSound.Play()

        # Leave the final "all done — go get the trophies" message up briefly, then
        # remove the quest HUD entirely so the screen is clean for the trophy hunt.
        Sleep(6.0)
        HideQuestHUD()

    HideQuestHUD():void=
        for (Entry : QuestHUDEntries):
            if (PlayerUI := GetPlayerUI[Entry(0)]):
                PlayerUI.RemoveWidget(Entry(1))
        set QuestHUDEntries = array{}

    # --- Completion detectors ---

    WaitUntilHarvested()<suspends>:void=
        loop:
            if (StarterPlot.HarvestCount >= 1):
                break
            Sleep(0.2)

    # In-game "prestige" (yield boost) == CurrentUpgradeLevel.
    WaitUntilCropUpgraded()<suspends>:void=
        loop:
            if (StarterPlot.CurrentUpgradeLevel >= 1):
                break
            Sleep(0.2)

    # In-game "garden level / potager niv2" == CurrentPrestigeLevel (starts at 1).
    WaitUntilGardenLevel(TargetLevel : int)<suspends>:void=
        loop:
            if (StarterPlot.CurrentPrestigeLevel >= TargetLevel):
                break
            Sleep(0.2)

    # The starter plot is auto-unlocked at spawn (CurrentPlotIndex starts at 1), so
    # unlocking a SECOND plot brings the index to 2.
    WaitUntilSecondPlot()<suspends>:void=
        loop:
            if (PlotManager.CurrentPlotIndex >= 2):
                break
            Sleep(0.2)

    WaitUntilBaseLevel(TargetLevel : int)<suspends>:void=
        loop:
            if (BaseManager.CurrentBaseLevel >= TargetLevel):
                break
            Sleep(1.0)

    WaitUntilForestBought()<suspends>:void=
        loop:
            if (ForestBought?):
                break
            Sleep(0.2)

    WaitUntilLumberjackHired()<suspends>:void=
        loop:
            if (LumberjackHired?):
                break
            Sleep(0.2)

    WaitUntilStoneBought()<suspends>:void=
        loop:
            if (StoneBought?):
                break
            Sleep(0.2)

    WaitUntilWaveStarted()<suspends>:void=
        loop:
            if (WaveStarted?):
                break
            Sleep(0.2)

    WaitUntilTrophyBought()<suspends>:void=
        loop:
            if (TrophyBought?):
                break
            Sleep(0.2)

    # Shows a brand-new quest title and keeps it on screen for at least
    # NewQuestDisplayTime, so consecutive (or pre-satisfied) quests are always seen.
    ShowNewQuest(StepNumber : int, Msg : message)<suspends>:void=
        RelocateBeacon(StepNumber)
        spawn{ PulseObjective() }
        UpdateQuestTitle(Msg)
        QuestStartSound.Play()
        Sleep(NewQuestDisplayTime)

    # --- Quest beacon ---

    # Snaps the beacon onto this quest's target marker and enables it. The beacon arrow
    # points down and bobs on its own, so there's nothing to animate or orient here.
    # Disable -> teleport -> enable gives a clean snap. No-op if the marker slot is empty.
    RelocateBeacon(StepNumber : int):void=
        Index := StepNumber - 1
        if (Marker := QuestTargetMarkers[Index]):
            T := Marker.GetTransform()
            Pos := T.Translation + vector3{X := 0.0, Y := 0.0, Z := ArrowHeight}
            QuestArrowBeacon.Disable()
            if (QuestArrowBeacon.TeleportTo[Pos, IdentityRotation()]) {}
            QuestArrowBeacon.Enable()
            # Minimap / overview-map marker: same target, ground position (Z is irrelevant on the map).
            QuestMapIndicator.Disable()
            if (QuestMapIndicator.TeleportTo[T.Translation, IdentityRotation()]) {}
            QuestMapIndicator.Enable()

    HideBeacon():void=
        QuestArrowBeacon.Disable()
        QuestMapIndicator.Disable()

    # One-shot: pulses the map indicator toward each player for ObjectivePulseTime, then
    # stops. Spawned from ShowNewQuest so it never blocks the quest flow.
    PulseObjective()<suspends>:void=
        for (Player : GetPlayspace().GetPlayers(), Agent := agent[Player]):
            QuestMapIndicator.ActivateObjectivePulse(Agent)
        Sleep(ObjectivePulseTime)
        for (Player : GetPlayspace().GetPlayers(), Agent := agent[Player]):
            QuestMapIndicator.DeactivateObjectivePulse(Agent)

    CompleteQuest(StepNumber : int, GoldAmount : int)<suspends>:void=
        # Hide the beacon during the "X/10 complete" interlude (target is already done);
        # the next ShowNewQuest relocates and re-shows it on the next target.
        HideBeacon()

        # The RewardGranter device must be configured to grant GoldAmount (100) gold
        # per call, so a single GrantItem call per player replaces the GoldAmount-long loop.
        for (Player : GetPlayspace().GetPlayers(), Agent := agent[Player]):
            RewardGranter.GrantItem(Agent)

        QuestCompleteSound.Play()
        spawn { PlayGoldSound() }
        UpdateQuestTitle(QuestCompleteMsg(StepNumber, GoldAmount))
        Sleep(2.5)

    # Plays the coin/gold sound a short beat after the completion sound.
    PlayGoldSound()<suspends>:void=
        Sleep(GoldSoundDelay)
        GoldSound.Play()

    UpdateQuestTitle(Msg : message):void=
        set CurrentQuestMessage = option{Msg}
        for (Block : QuestTextBlocks):
            Block.SetText(Msg)

    SetupQuestHUD()<suspends>:void=
        # Wait until the player has spawned, then build the on-screen quest widget.
        loop:
            Players := GetPlayspace().GetPlayers()
            if (Players.Length > 0, FirstPlayer := Players[0], FirstPlayer.GetFortCharacter[]):
                for (Player : Players):
                    AddQuestHUDToPlayer(Player)
                break
            Sleep(0.5)

    AddQuestHUDToPlayer(Player : player):void=
        QuestBlock := text_block{
            DefaultTextColor := color{R := 1.0, G := 1.0, B := 1.0}
            DefaultTextSize := 30.0
        }
        # Apply the current quest text if one has already been set.
        if (M := CurrentQuestMessage?):
            QuestBlock.SetText(M)
        set QuestTextBlocks += array{QuestBlock}

        Background := color_block{
            DefaultColor := color{R := 0.02, G := 0.02, B := 0.06}
            DefaultOpacity := 0.6
        }

        PaddedQuest := stack_box{
            Orientation := orientation.Vertical
            Slots := array{
                stack_box_slot{
                    Widget := QuestBlock
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Top := 12.0, Bottom := 12.0, Left := 36.0, Right := 36.0}
                }
            }
        }

        QuestWithBackground := canvas{
            Slots := array{
                canvas_slot{
                    Widget := Background
                    Anchors := anchors{
                        Minimum := vector2{X := 0.0, Y := 0.0}
                        Maximum := vector2{X := 1.0, Y := 1.0}
                    }
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                }
                canvas_slot{
                    Widget := PaddedQuest
                    Anchors := anchors{
                        Minimum := vector2{X := 0.0, Y := 0.0}
                        Maximum := vector2{X := 1.0, Y := 1.0}
                    }
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                }
            }
        }

        RootCanvas := canvas{
            Slots := array{
                canvas_slot{
                    Widget := QuestWithBackground
                    Anchors := anchors{
                        Minimum := vector2{X := 0.5, Y := 0.12}
                        Maximum := vector2{X := 0.5, Y := 0.12}
                    }
                    Alignment := vector2{X := 0.5, Y := 0.0}
                    SizeToContent := true
                }
            }
        }

        if (PlayerUI := GetPlayerUI[Player]):
            PlayerUI.AddWidget(RootCanvas, player_ui_slot{InputMode := ui_input_mode.None})
            set QuestHUDEntries += array{(Player, RootCanvas)}
