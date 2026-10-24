using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

# --- Score persistence (personal best time, per player, per island) ---
# Saved across sessions/days on the PUBLISHED island only (always empty in
# editor playtests). Uses 1 of the island's 4 allowed persistent weak_maps.
score_data := class<final><persistable>:
    BestTimes : []int = array{}   # personal best times (seconds), sorted ascending, capped at 5

var ScoreMap : weak_map(player, score_data) = map{}

# --- Localized end-screen / restart strings ---
# Real literals inside <localizes> functions so they are extracted and translated.
# Rank words are their own messages and are composed into the sub-line / best-times
# lines via {Rank} substitution. (Pure numeric strings like the chrono and the
# formatted time keep going through StringToMessage — there is nothing to translate
# in "12:34:56".)
VictoryMsg<localizes>():message = "VICTORY!"
DefeatMsg<localizes>():message = "DEFEAT"
GoldMsg<localizes>():message = "GOLD"
SilverMsg<localizes>():message = "SILVER"
BronzeMsg<localizes>():message = "BRONZE"
NoneRankMsg<localizes>():message = "NONE"
DefeatSubMsg<localizes>(Time : string):message = "Time {Time}"
VictorySubMsg<localizes>(Time : string, Rank : message):message = "{Time}  -  {Rank}"
BestTimesHeaderMsg<localizes>():message = "Your best times"
BestLineMsg<localizes>(Pos : int, Time : string, Rank : message):message = "{Pos}. {Time}  {Rank}"
NoRecordMsg<localizes>():message = "No record yet"
NewBestMsg<localizes>():message = "NEW BEST!"
ReplayMsg<localizes>():message = "REPLAY"
RestartRunSignMsg<localizes>():message = "Restart Run"
RestartConfirmTitleMsg<localizes>():message = "Restart from zero?"
RestartConfirmSubMsg<localizes>():message = "Your current run will be lost."
RestartYesMsg<localizes>():message = "Yes, restart"
RestartNoMsg<localizes>():message = "No, keep playing"

trophy_manager := class(creative_device):

    @editable
    GOLD_TIME : int = 960

    @editable
    SILVER_TIME : int = 1200

    @editable
    BRONZE_TIME : int = 1500

    @editable
    Trophy1Prop : creative_prop = creative_prop{}

    @editable
    Trophy2Prop : creative_prop = creative_prop{}

    @editable
    Trophy3Prop : creative_prop = creative_prop{}

    @editable
    Trophy4Prop : creative_prop = creative_prop{}

    @editable
    Trophy5Prop : creative_prop = creative_prop{}

    @editable
    Trophy6Prop : creative_prop = creative_prop{}

    @editable
    Trophy7Prop : creative_prop = creative_prop{}

    @editable
    Trophy1Button : conditional_button_device = conditional_button_device{}

    @editable
    Trophy2Button : conditional_button_device = conditional_button_device{}

    @editable
    Trophy3Button : conditional_button_device = conditional_button_device{}

    @editable
    Trophy4Button : conditional_button_device = conditional_button_device{}

    @editable
    Trophy5Button : conditional_button_device = conditional_button_device{}

    @editable
    Trophy6Button : conditional_button_device = conditional_button_device{}

    @editable
    Trophy7Button : conditional_button_device = conditional_button_device{}

    @editable
    ButtonHiddenMarker : billboard_device = billboard_device{}

    @editable
    Trophy7RequirementBillboard : billboard_device = billboard_device{}

    @editable
    TimerDisplay : billboard_device = billboard_device{}

    @editable
    EndGameDevice : end_game_device = end_game_device{}

    @editable
    IntroManager : intro_ui_manager = intro_ui_manager{}

    @editable
    Trophy1CostRemover : item_granter_device = item_granter_device{}

    @editable
    Trophy2CostRemover : item_granter_device = item_granter_device{}

    @editable
    Trophy3CostRemover : item_granter_device = item_granter_device{}

    @editable
    Trophy4CostRemover : item_granter_device = item_granter_device{}

    @editable
    Trophy5CostRemover : item_granter_device = item_granter_device{}

    @editable
    Trophy6CostRemover : item_granter_device = item_granter_device{}

    @editable
    Trophy7CostRemover : item_granter_device = item_granter_device{}

    @editable
    Trophy1VFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy2VFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy3VFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy4VFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy5VFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy6VFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy7VFX : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy1VFX_Final : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy2VFX_Final : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy3VFX_Final : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy4VFX_Final : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy5VFX_Final : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy6VFX_Final : vfx_spawner_device = vfx_spawner_device{}

    @editable
    Trophy1SFX : audio_player_device = audio_player_device{}

    @editable
    Trophy2SFX : audio_player_device = audio_player_device{}

    @editable
    Trophy3SFX : audio_player_device = audio_player_device{}

    @editable
    Trophy4SFX : audio_player_device = audio_player_device{}

    @editable
    Trophy5SFX : audio_player_device = audio_player_device{}

    @editable
    Trophy6SFX : audio_player_device = audio_player_device{}

    @editable
    Trophy7SFX : audio_player_device = audio_player_device{}

    @editable
    Trophy1SFX_Final : audio_player_device = audio_player_device{}

    @editable
    Trophy2SFX_Final : audio_player_device = audio_player_device{}

    @editable
    Trophy3SFX_Final : audio_player_device = audio_player_device{}

    @editable
    Trophy4SFX_Final : audio_player_device = audio_player_device{}

    @editable
    Trophy5SFX_Final : audio_player_device = audio_player_device{}

    @editable
    Trophy6SFX_Final : audio_player_device = audio_player_device{}

    # Master switch for the cheat/testing buttons. Leave OFF (unchecked) for the
    # published build; tick it in the Trophy Manager Details to bring the cheat
    # buttons back for testing. When off, the buttons are disabled AND teleported
    # out of sight so players never see them.
    @editable
    EnableCheats : logic = false

    @editable
    CheatButton1 : button_device = button_device{}

    @editable
    CheatButton2 : button_device = button_device{}

    @editable
    CheatButton3 : button_device = button_device{}

    @editable
    CheatButton4 : button_device = button_device{}

    @editable
    CheatGranter1 : item_granter_device = item_granter_device{}

    @editable
    CheatGranter2 : item_granter_device = item_granter_device{}

    @editable
    CheatGranter3 : item_granter_device = item_granter_device{}

    @editable
    CheatGranter4 : item_granter_device = item_granter_device{}

    # World button placed near the spawn/base. Interacting with it (Hold E) opens
    # a Yes/No confirmation before restarting the run from zero (ends the round ->
    # clean device rebuild). Lets the player bail out of a bad start without
    # finishing all 7 trophies first.
    @editable
    RestartButton : button_device = button_device{}

    # Static sign placed above/next to RestartButton. Duplicated from a requirement
    # billboard, so it starts hidden (those are revealed by Verse ShowText); we turn
    # it on in OnBegin so it stays visible the whole run.
    @editable
    RestartSignBillboard : billboard_device = billboard_device{}

    var Trophy1Unlocked : logic = false
    var Trophy2Unlocked : logic = false
    var Trophy3Unlocked : logic = false
    var Trophy4Unlocked : logic = false
    var Trophy5Unlocked : logic = false
    var Trophy6Unlocked : logic = false
    var Trophy7Unlocked : logic = false
    var TotalCentiseconds : int = 0   # final time in hundredths of a second
    var StartTime : float = 0.0       # GetSimulationElapsedTime() when the clock started
    var GameEnded : logic = false
    var ChronoBlocks : []text_block = array{}
    var ChronoCanvases : []canvas = array{}
    var ChronoPlayers : []player = array{}
    var RestartConfirmCanvas : ?canvas = false   # the open restart-confirmation overlay, if any
    var RestartConfirmPlayer : ?player = false

    OnBegin<override>()<suspends>:void=
        Trophy1Prop.Hide()
        Trophy2Prop.Hide()
        Trophy3Prop.Hide()
        Trophy4Prop.Hide()
        Trophy5Prop.Hide()
        Trophy6Prop.Hide()
        Trophy7Prop.Hide()

        Trophy7Button.Disable()

        RestartSignBillboard.SetText(RestartRunSignMsg())
        RestartSignBillboard.ShowText()

        Trophy1Button.ActivatedEvent.Subscribe(OnTrophy1Unlocked)
        Trophy2Button.ActivatedEvent.Subscribe(OnTrophy2Unlocked)
        Trophy3Button.ActivatedEvent.Subscribe(OnTrophy3Unlocked)
        Trophy4Button.ActivatedEvent.Subscribe(OnTrophy4Unlocked)
        Trophy5Button.ActivatedEvent.Subscribe(OnTrophy5Unlocked)
        Trophy6Button.ActivatedEvent.Subscribe(OnTrophy6Unlocked)
        Trophy7Button.ActivatedEvent.Subscribe(OnTrophy7Unlocked)
        SetupCheatButtons()
        RestartButton.InteractedWithEvent.Subscribe(OnRestartPressed)

        spawn{SetupChronoHUD()}
        spawn{StartTimerAfterIntro()}

    StartTimerAfterIntro()<suspends>:void=
        # The game clock only starts once the player has finished reading the intro.
        IntroManager.IntroFinishedEvent.Await()
        TimerLoop()

    OnCheat1(Agent : agent):void=
        CheatGranter1.GrantItem(Agent)

    OnCheat2(Agent : agent):void=
        CheatGranter2.GrantItem(Agent)

    OnCheat3(Agent : agent):void=
        CheatGranter3.GrantItem(Agent)

    OnCheat4(Agent : agent):void=
        CheatGranter4.GrantItem(Agent)

    SetupCheatButtons():void=
        # EnableCheats is an editor checkbox: ON = wire up and keep the cheat
        # buttons; OFF (release default) = disable them and move them out of sight.
        if (EnableCheats?):
            CheatButton1.Enable()
            CheatButton2.Enable()
            CheatButton3.Enable()
            CheatButton4.Enable()
            CheatButton1.InteractedWithEvent.Subscribe(OnCheat1)
            CheatButton2.InteractedWithEvent.Subscribe(OnCheat2)
            CheatButton3.InteractedWithEvent.Subscribe(OnCheat3)
            CheatButton4.InteractedWithEvent.Subscribe(OnCheat4)
        else:
            HideCheatButton(CheatButton1)
            HideCheatButton(CheatButton2)
            HideCheatButton(CheatButton3)
            HideCheatButton(CheatButton4)

    HideCheatButton(Button : button_device):void=
        # Disable() stops interaction; the teleport to the hidden marker also makes
        # the button itself disappear (Disable alone can leave it visible in place).
        Button.Disable()
        HiddenPos := ButtonHiddenMarker.GetTransform().Translation
        HiddenRot := ButtonHiddenMarker.GetTransform().Rotation
        if (Button.TeleportTo[HiddenPos, HiddenRot]) {}

    TimerLoop()<suspends>:void=
        # Anchor the clock to real simulation time so it stays accurate (a Sleep
        # tick-counter drifts) and exposes sub-second precision.
        set StartTime = GetSimulationElapsedTime()
        loop:
            if (GameEnded?):
                break
            UpdateTimerDisplay()
            Sleep(0.03)   # ~30 fps so the live hundredths read smoothly

    # Real elapsed time since the clock started, in hundredths of a second.
    ElapsedCentiseconds():int=
        var Result : int = 0
        Elapsed := GetSimulationElapsedTime() - StartTime
        Scaled := Elapsed * 100.0
        # Floor on a freely-bound float is failable here, so call it with [] in a
        # failure context (unlike FormatTime, where the arg comes from a checked /).
        if (Scaled > 0.0, Floored := Floor[Scaled]):
            set Result = Floored
        return Result

    UpdateTimerDisplay():void=
        ChronoMessage := StringToMessage(FormatTime(ElapsedCentiseconds()))
        for (Block : ChronoBlocks):
            Block.SetText(ChronoMessage)

    SetupChronoHUD()<suspends>:void=
        # Wait until the player has spawned a character; widgets added before spawn
        # are discarded by Fortnite, which is why the chrono never appeared.
        loop:
            Players := GetPlayspace().GetPlayers()
            if (Players.Length > 0, FirstPlayer := Players[0], FirstPlayer.GetFortCharacter[]):
                for (Player : Players):
                    AddChronoHUDToPlayer(Player)
                break
            Sleep(0.5)

    AddChronoHUDToPlayer(Player : player):void=
        ChronoBlock := text_block{
            DefaultText := StringToMessage("00:00:00")
            DefaultTextColor := color{R := 1.0, G := 1.0, B := 1.0}
            DefaultTextSize := 40.0
        }
        set ChronoBlocks += array{ChronoBlock}

        Background := color_block{
            DefaultColor := color{R := 0.02, G := 0.02, B := 0.06}
            DefaultOpacity := 0.5
        }

        # Background fills a FIXED-size box; the text is centered on top. This stops
        # the box from resizing (trembling) as the fast hundredths change the text
        # width — only the centered text itself breathes slightly.
        ChronoWithBackground := canvas{
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
                    Widget := ChronoBlock
                    Anchors := anchors{
                        Minimum := vector2{X := 0.5, Y := 0.5}
                        Maximum := vector2{X := 0.5, Y := 0.5}
                    }
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                }
            }
        }

        RootCanvas := canvas{
            Slots := array{
                canvas_slot{
                    Widget := ChronoWithBackground
                    # Stretched to a FIXED fraction of the screen width (16%, centered),
                    # so the box width is independent of the text — no tremble, and there
                    # is side padding. Vertically point-anchored: Top = y, Bottom = height.
                    Anchors := anchors{
                        Minimum := vector2{X := 0.435, Y := 0.0}
                        Maximum := vector2{X := 0.565, Y := 0.0}
                    }
                    Offsets := margin{Left := 0.0, Top := 55.0, Right := 0.0, Bottom := 93.0}
                }
            }
        }

        if (PlayerUI := GetPlayerUI[Player]):
            PlayerUI.AddWidget(RootCanvas, player_ui_slot{InputMode := ui_input_mode.None})
            set ChronoCanvases += array{RootCanvas}
            set ChronoPlayers += array{Player}

    GetTwoDigitString(Value : int):string=
        if (Value < 10):
            return "0{Value}"
        else:
            return "{Value}"

    # Takes a time in hundredths of a second, returns "MM:SS:CC".
    FormatTime(TotalCs : int):string=
        var TotalSecs : int = 0
        if (Div := TotalCs / 100):
            set TotalSecs = Floor(Div)
        Centis := TotalCs - (TotalSecs * 100)
        var Minutes : int = 0
        if (Div2 := TotalSecs / 60):
            set Minutes = Floor(Div2)
        Seconds := TotalSecs - (Minutes * 60)
        return "{GetTwoDigitString(Minutes)}:{GetTwoDigitString(Seconds)}:{GetTwoDigitString(Centis)}"

    # Localized rank name (thresholds in seconds). Used for the end-screen lines so
    # GOLD/SILVER/BRONZE are translated. (RankName, the plain-string version, is kept
    # for any non-display logic.)
    RankMessage(TotalCs : int):message=
        if (TotalCs <= GOLD_TIME * 100):
            return GoldMsg()
        else if (TotalCs <= SILVER_TIME * 100):
            return SilverMsg()
        else if (TotalCs <= BRONZE_TIME * 100):
            return BronzeMsg()
        return NoneRankMsg()

    # Takes a time in hundredths of a second; rank thresholds are in seconds.
    RankName(TotalCs : int):string=
        if (TotalCs <= GOLD_TIME * 100):
            return "GOLD"
        else if (TotalCs <= SILVER_TIME * 100):
            return "SILVER"
        else if (TotalCs <= BRONZE_TIME * 100):
            return "BRONZE"
        return "NONE"

    # Inserts NewTime into an already-ascending list, keeping it sorted.
    InsertSorted(Times : []int, NewTime : int):[]int=
        var Result : []int = array{}
        var Inserted : logic = false
        for (T : Times):
            if (not Inserted?, NewTime < T):
                set Result += array{NewTime}
                set Inserted = true
            set Result += array{T}
        if (not Inserted?):
            set Result += array{NewTime}
        return Result

    # Keeps only the first N elements of a list.
    TakeFirst(Times : []int, N : int):[]int=
        var Result : []int = array{}
        for (I -> T : Times):
            if (I < N):
                set Result += array{T}
        return Result

    # Index where NewTime would be inserted into an already-ascending list
    # (before the first strictly-greater element). Used to highlight the current run.
    InsertIndex(Times : []int, NewTime : int):int=
        var Index : int = 0
        for (T : Times):
            if (NewTime < T):
                return Index
            set Index += 1
        return Index

    StringToMessage<localizes>(Text : string):message = "{Text}"

    HideButton(Button : conditional_button_device):void=
        HiddenPos := ButtonHiddenMarker.GetTransform().Translation
        HiddenRot := ButtonHiddenMarker.GetTransform().Rotation
        if (Button.TeleportTo[HiddenPos, HiddenRot]) {}

    OnTrophy1Unlocked(Agent : agent):void=
        Trophy1CostRemover.GrantItem(Agent)
        set Trophy1Unlocked = true
        Trophy1Prop.Show()
        Trophy1VFX.Enable()
        Trophy1SFX.Play()
        HideButton(Trophy1Button)
        Trophy1Button.Disable()
        CheckAllTrophiesUnlocked()

    OnTrophy2Unlocked(Agent : agent):void=
        Trophy2CostRemover.GrantItem(Agent)
        set Trophy2Unlocked = true
        Trophy2Prop.Show()
        Trophy2VFX.Enable()
        Trophy2SFX.Play()
        HideButton(Trophy2Button)
        Trophy2Button.Disable()
        CheckAllTrophiesUnlocked()

    OnTrophy3Unlocked(Agent : agent):void=
        Trophy3CostRemover.GrantItem(Agent)
        set Trophy3Unlocked = true
        Trophy3Prop.Show()
        Trophy3VFX.Enable()
        Trophy3SFX.Play()
        HideButton(Trophy3Button)
        Trophy3Button.Disable()
        CheckAllTrophiesUnlocked()

    OnTrophy4Unlocked(Agent : agent):void=
        Trophy4CostRemover.GrantItem(Agent)
        set Trophy4Unlocked = true
        Trophy4Prop.Show()
        Trophy4VFX.Enable()
        Trophy4SFX.Play()
        HideButton(Trophy4Button)
        Trophy4Button.Disable()
        CheckAllTrophiesUnlocked()

    OnTrophy5Unlocked(Agent : agent):void=
        Trophy5CostRemover.GrantItem(Agent)
        set Trophy5Unlocked = true
        Trophy5Prop.Show()
        Trophy5VFX.Enable()
        Trophy5SFX.Play()
        HideButton(Trophy5Button)
        Trophy5Button.Disable()
        CheckAllTrophiesUnlocked()

    OnTrophy6Unlocked(Agent : agent):void=
        Trophy6CostRemover.GrantItem(Agent)
        set Trophy6Unlocked = true
        Trophy6Prop.Show()
        Trophy6VFX.Enable()
        Trophy6SFX.Play()
        HideButton(Trophy6Button)
        Trophy6Button.Disable()
        CheckAllTrophiesUnlocked()

    OnTrophy7Unlocked(Agent : agent):void=
        Trophy7CostRemover.GrantItem(Agent)
        set Trophy7Unlocked = true
        # Capture the precise finish time the instant the run ends (before any
        # Sleep in the result sequence would inflate it).
        set TotalCentiseconds = ElapsedCentiseconds()
        set GameEnded = true
        Trophy7Prop.Show()
        Trophy7SFX.Play()
        HideButton(Trophy7Button)
        Trophy7Button.Disable()

        Trophy1VFX_Final.Enable()
        Trophy2VFX_Final.Enable()
        Trophy3VFX_Final.Enable()
        Trophy4VFX_Final.Enable()
        Trophy5VFX_Final.Enable()
        Trophy6VFX_Final.Enable()

        Trophy1SFX_Final.Play()
        Trophy2SFX_Final.Play()
        Trophy3SFX_Final.Play()
        Trophy4SFX_Final.Play()
        Trophy5SFX_Final.Play()
        Trophy6SFX_Final.Play()

        spawn{ShowResultAndEndGame(Agent)}

    ShowResultAndEndGame(Agent : agent)<suspends>:void=
        FreezeAllPlayers()
        Sleep(1.0)
        Trophy7VFX.Enable()

        TimeText := FormatTime(TotalCentiseconds)

        var TitleMsg : message = DefeatMsg()
        var SubMsg : message = DefeatSubMsg(TimeText)
        var AccentColor : color = color{R := 0.90, G := 0.25, B := 0.25}

        if (TotalCentiseconds <= GOLD_TIME * 100):
            set TitleMsg = VictoryMsg()
            set SubMsg = VictorySubMsg(TimeText, GoldMsg())
            set AccentColor = color{R := 1.0, G := 0.84, B := 0.0}
        else if (TotalCentiseconds <= SILVER_TIME * 100):
            set TitleMsg = VictoryMsg()
            set SubMsg = VictorySubMsg(TimeText, SilverMsg())
            set AccentColor = color{R := 0.82, G := 0.85, B := 0.92}
        else if (TotalCentiseconds <= BRONZE_TIME * 100):
            set TitleMsg = VictoryMsg()
            set SubMsg = VictorySubMsg(TimeText, BronzeMsg())
            set AccentColor = color{R := 0.85, G := 0.55, B := 0.25}

        # --- Personal best times (persisted, victories only, top 5) ---
        var IsVictory : logic = false
        if (TotalCentiseconds <= BRONZE_TIME * 100):
            set IsVictory = true

        var BestTimesOut : []int = array{}
        var HighlightIndex : int = -1   # index of the just-finished run in the list (-1 = none)
        var IsNewBest : logic = false
        if (P := player[Agent]):
            var Times : []int = array{}
            if (Saved := ScoreMap[P]):
                set Times = Saved.BestTimes

            var PreviousBest : int = 0
            if (First := Times[0]):
                set PreviousBest = First

            # Only a victory (finished within Bronze) is recorded in the top 5.
            if (IsVictory?):
                if (PreviousBest = 0):
                    set IsNewBest = true
                else if (TotalCentiseconds < PreviousBest):
                    set IsNewBest = true

                # Where this run lands in the sorted list (before truncation).
                set HighlightIndex = InsertIndex(Times, TotalCentiseconds)
                set Times = TakeFirst(InsertSorted(Times, TotalCentiseconds), 5)
                # Writing to a weak_map is failable ('decides'), so it must sit in
                # a failure context — wrap it in an if even though it won't fail here.
                if (set ScoreMap[P] = score_data{BestTimes := Times}) {}

                # If the run fell outside the top 5, there is no line to highlight.
                if (HighlightIndex >= 5):
                    set HighlightIndex = -1

            set BestTimesOut = Times

        # Remove the on-screen chrono entirely (text + background); the final time
        # is shown in the result overlay.
        for (Index -> Canvas : ChronoCanvases):
            if (P := ChronoPlayers[Index], PlayerUI := GetPlayerUI[P]):
                PlayerUI.RemoveWidget(Canvas)

        # Centered full-screen overlay for every player, with a Replay button. There
        # is no auto-restart any more: the player reads their scores and clicks Replay
        # when ready (which ends the round -> fresh devices = a clean full reset).
        ShowEndScreen(TitleMsg, SubMsg, AccentColor, BestTimesOut, HighlightIndex, IsNewBest)

    FreezeAllPlayers():void=
        for (Player : GetPlayspace().GetPlayers()):
            if (Character := Player.GetFortCharacter[]):
                Character.PutInStasis(stasis_args{
                    AllowTurning := false
                    AllowFalling := false
                    AllowEmotes := false
                })

    OnReplayClicked(Message : widget_message):void=
        # End the current round; with Total Rounds > 1 the next round starts and
        # every device's OnBegin re-runs from a freshly rebuilt state (clean reset).
        EndGameDevice.Activate(Message.Player)

    # --- In-game restart (world button near spawn) ---

    OnRestartPressed(Agent : agent):void=
        # Ignore once the run is over (the end screen already offers REPLAY) or if
        # a confirmation is already open (avoids stacking overlays on repeat presses).
        if (GameEnded?):
            return
        if (RestartConfirmCanvas?):
            return
        if (P := player[Agent]):
            ShowRestartConfirm(P)

    OnRestartConfirmYes(Message : widget_message):void=
        # Same path as the end-screen REPLAY: end the round -> fresh devices = clean reset.
        EndGameDevice.Activate(Message.Player)

    OnRestartConfirmNo(Message : widget_message):void=
        CloseRestartConfirm()

    CloseRestartConfirm():void=
        if (Canvas := RestartConfirmCanvas?, Player := RestartConfirmPlayer?, PlayerUI := GetPlayerUI[Player]):
            PlayerUI.RemoveWidget(Canvas)
        set RestartConfirmCanvas = false
        set RestartConfirmPlayer = false

    ShowRestartConfirm(Player : player):void=
        TitleBlock := text_block{
            DefaultText := RestartConfirmTitleMsg()
            DefaultTextColor := color{R := 1.0, G := 0.84, B := 0.0}
            DefaultTextSize := 48.0
        }

        SubBlock := text_block{
            DefaultText := RestartConfirmSubMsg()
            DefaultTextColor := color{R := 1.0, G := 1.0, B := 1.0}
            DefaultTextSize := 28.0
        }

        # Loud = the affirmative (matches the REPLAY button); quiet = the safe "back out".
        YesButton := button_loud{DefaultText := RestartYesMsg()}
        NoButton := button_quiet{DefaultText := RestartNoMsg()}
        YesButton.OnClick().Subscribe(OnRestartConfirmYes)
        NoButton.OnClick().Subscribe(OnRestartConfirmNo)

        ButtonsRow := stack_box{
            Orientation := orientation.Horizontal
            Slots := array{
                stack_box_slot{
                    Widget := NoButton
                    Padding := margin{Left := 10.0, Right := 10.0}
                }
                stack_box_slot{
                    Widget := YesButton
                    Padding := margin{Left := 10.0, Right := 10.0}
                }
            }
        }

        Panel := stack_box{
            Orientation := orientation.Vertical
            Slots := array{
                stack_box_slot{
                    Widget := TitleBlock
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Bottom := 18.0}
                }
                stack_box_slot{
                    Widget := SubBlock
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Bottom := 30.0}
                }
                stack_box_slot{
                    Widget := ButtonsRow
                    HorizontalAlignment := horizontal_alignment.Center
                }
            }
        }

        Background := color_block{
            DefaultColor := color{R := 0.02, G := 0.02, B := 0.06}
            DefaultOpacity := 0.78
        }

        PaddedPanel := stack_box{
            Orientation := orientation.Vertical
            Slots := array{
                stack_box_slot{
                    Widget := Panel
                    Padding := margin{Top := 40.0, Bottom := 40.0, Left := 100.0, Right := 100.0}
                }
            }
        }

        ContentWithBackground := canvas{
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
                    Widget := PaddedPanel
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
                    Widget := ContentWithBackground
                    Anchors := anchors{
                        Minimum := vector2{X := 0.5, Y := 0.5}
                        Maximum := vector2{X := 0.5, Y := 0.5}
                    }
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                }
            }
        }

        if (PlayerUI := GetPlayerUI[Player]):
            PlayerUI.AddWidget(RootCanvas, player_ui_slot{InputMode := ui_input_mode.All})
            set RestartConfirmCanvas = option{RootCanvas}
            set RestartConfirmPlayer = option{Player}

    ShowEndScreen(TitleMsg : message, SubMsg : message, AccentColor : color, BestTimes : []int, HighlightIndex : int, IsNewBest : logic):void=
        for (Player : GetPlayspace().GetPlayers()):
            ShowEndScreenToPlayer(Player, TitleMsg, SubMsg, AccentColor, BestTimes, HighlightIndex, IsNewBest)

    ShowEndScreenToPlayer(Player : player, TitleMsg : message, SubMsg : message, AccentColor : color, BestTimes : []int, HighlightIndex : int, IsNewBest : logic):void=
        TitleBlock := text_block{
            DefaultText := TitleMsg
            DefaultTextColor := AccentColor
            DefaultTextSize := 70.0
        }

        SubBlock := text_block{
            DefaultText := SubMsg
            DefaultTextColor := color{R := 1.0, G := 1.0, B := 1.0}
            DefaultTextSize := 38.0
        }

        var PanelSlots : []stack_box_slot = array{
            stack_box_slot{
                Widget := TitleBlock
                HorizontalAlignment := horizontal_alignment.Center
                Padding := margin{Bottom := 18.0}
            }
            stack_box_slot{
                Widget := SubBlock
                HorizontalAlignment := horizontal_alignment.Center
            }
        }

        # Best-times section: one text_block per line so the just-finished run
        # (HighlightIndex) can be drawn bigger and in the accent color.
        if (BestTimes.Length > 0):
            BestHeaderBlock := text_block{
                DefaultText := BestTimesHeaderMsg()
                DefaultTextColor := color{R := 0.70, G := 0.70, B := 0.78}
                DefaultTextSize := 24.0
            }
            set PanelSlots += array{
                stack_box_slot{
                    Widget := BestHeaderBlock
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Top := 24.0, Bottom := 6.0}
                }
            }
            for (I -> T : BestTimes):
                var LineColor : color = color{R := 0.90, G := 0.90, B := 0.95}
                if (I = HighlightIndex):
                    # Light blue so it stands out from the gold/silver/bronze rank colors.
                    set LineColor = color{R := 0.35, G := 0.75, B := 1.0}
                LineBlock := text_block{
                    DefaultText := BestLineMsg(I + 1, FormatTime(T), RankMessage(T))
                    DefaultTextColor := LineColor
                    DefaultTextSize := 28.0
                }
                set PanelSlots += array{
                    stack_box_slot{
                        Widget := LineBlock
                        HorizontalAlignment := horizontal_alignment.Center
                        Padding := margin{Top := 3.0}
                    }
                }
        else:
            NoRecordBlock := text_block{
                DefaultText := NoRecordMsg()
                DefaultTextColor := color{R := 0.85, G := 0.85, B := 0.92}
                DefaultTextSize := 28.0
            }
            set PanelSlots += array{
                stack_box_slot{
                    Widget := NoRecordBlock
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Top := 22.0}
                }
            }

        # The NEW BEST! banner only appears when the player beat their record.
        if (IsNewBest?):
            NewBestBlock := text_block{
                DefaultText := NewBestMsg()
                DefaultTextColor := AccentColor
                DefaultTextSize := 34.0
            }
            set PanelSlots += array{
                stack_box_slot{
                    Widget := NewBestBlock
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Top := 12.0}
                }
            }

        # Highlighted Replay button (loudest button style, like the intro "Start!").
        ReplayButton := button_loud{DefaultText := ReplayMsg()}
        ReplayButton.OnClick().Subscribe(OnReplayClicked)
        set PanelSlots += array{
            stack_box_slot{
                Widget := ReplayButton
                HorizontalAlignment := horizontal_alignment.Center
                Padding := margin{Top := 34.0}
            }
        }

        Panel := stack_box{
            Orientation := orientation.Vertical
            Slots := PanelSlots
        }

        Background := color_block{
            DefaultColor := color{R := 0.02, G := 0.02, B := 0.06}
            DefaultOpacity := 0.78
        }

        PaddedPanel := stack_box{
            Orientation := orientation.Vertical
            Slots := array{
                stack_box_slot{
                    Widget := Panel
                    Padding := margin{Top := 40.0, Bottom := 40.0, Left := 100.0, Right := 100.0}
                }
            }
        }

        ContentWithBackground := canvas{
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
                    Widget := PaddedPanel
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
                    Widget := ContentWithBackground
                    Anchors := anchors{
                        Minimum := vector2{X := 0.5, Y := 0.5}
                        Maximum := vector2{X := 0.5, Y := 0.5}
                    }
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                }
            }
        }

        if (PlayerUI := GetPlayerUI[Player]):
            PlayerUI.AddWidget(RootCanvas, player_ui_slot{InputMode := ui_input_mode.All})

    CheckAllTrophiesUnlocked():void=
        if:
            Trophy1Unlocked?
            Trophy2Unlocked?
            Trophy3Unlocked?
            Trophy4Unlocked?
            Trophy5Unlocked?
            Trophy6Unlocked?
        then:
            Trophy7Button.Enable()
            Trophy7RequirementBillboard.HideText()
