using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

# --- Localized UI strings ---
# Single-page intro. Each literal lives inside a parameter-less <localizes> function
# so the localization gather extracts the REAL text (not a generic "{Text}"
# passthrough), which is what lets Auto Localization translate every line into all
# supported languages.
IntroTitleMsg<localizes>():message = "Welcome to Rush Valley! 🌾"
IntroContentMsg<localizes>():message = "🏆 Your goal: unlock all 7 trophies — as fast as you can!\n\n🏁 Gold < 16:00   ·   Silver < 20:00   ·   Bronze < 25:00\n\n🌱 Follow the quests to grow, automate and defend your farm.\n\nReady?"
StartButtonMsg<localizes>():message = "Let's go! 🚜"

intro_ui_manager := class(creative_device):

    # Signaled when the player closes the intro (clicks "GO!"), so other
    # devices (e.g. the trophy timer) can start the game at that moment.
    IntroFinishedEvent : event() = event(){}

    var CurrentCanvas : ?canvas = false
    var CurrentPlayer : ?player = false

    OnBegin<override>()<suspends> : void =
        Sleep(0.5)

        Players := GetPlayspace().GetPlayers()
        for (Player : Players):
            spawn{ ShowIntroToPlayer(Player) }

    ShowIntroToPlayer(Player : player)<suspends> : void =
        set CurrentPlayer = option{Player}

        if (Character := Player.GetFortCharacter[]):
            Character.PutInStasis(stasis_args{
                AllowTurning := false
                AllowFalling := false
                AllowEmotes := false
            })

        Sleep(0.0)

        CreateIntroUI(Player)

    CreateIntroUI(Player : player) : void =
        TitleBlock := text_block{
            DefaultText := IntroTitleMsg()
            DefaultTextColor := color{R := 1.0, G := 0.85, B := 0.0}
            DefaultTextSize := 48.0
        }

        ContentBlock := text_block{
            DefaultText := IntroContentMsg()
            DefaultTextColor := color{R := 1.0, G := 1.0, B := 1.0}
        }

        GoBtn := button_loud{DefaultText := StartButtonMsg()}
        GoBtn.OnClick().Subscribe(OnGoClicked)

        MainLayout := stack_box{
            Orientation := orientation.Vertical
            Slots := array{
                stack_box_slot{
                    Widget := TitleBlock
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Bottom := 45.0}
                }
                stack_box_slot{
                    Widget := ContentBlock
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Bottom := 35.0}
                }
                stack_box_slot{
                    Widget := GoBtn
                    HorizontalAlignment := horizontal_alignment.Center
                }
            }
        }

        BackgroundColor := color_block{
            DefaultColor := color{R := 0.05, G := 0.1, B := 0.2}
            DefaultOpacity := 0.9
        }

        PaddedContent := stack_box{
            Orientation := orientation.Vertical
            Slots := array{
                stack_box_slot{
                    Widget := MainLayout
                    Padding := margin{Top := 40.0, Bottom := 40.0, Left := 60.0, Right := 60.0}
                }
            }
        }

        ContentWithBackground := canvas{
            Slots := array{
                canvas_slot{
                    Widget := BackgroundColor
                    Anchors := anchors{
                        Minimum := vector2{X := 0.0, Y := 0.0}
                        Maximum := vector2{X := 1.0, Y := 1.0}
                    }
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                }
                canvas_slot{
                    Widget := PaddedContent
                    Anchors := anchors{
                        Minimum := vector2{X := 0.0, Y := 0.0}
                        Maximum := vector2{X := 1.0, Y := 1.0}
                    }
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                }
            }
        }

        IntroCanvas := canvas{
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

        set CurrentCanvas = option{IntroCanvas}

        if (PlayerUI := GetPlayerUI[Player]):
            PlayerUI.AddWidget(IntroCanvas, player_ui_slot{InputMode := ui_input_mode.All})

    OnGoClicked(Message : widget_message) : void =
        CloseIntroUI()

    CloseIntroUI() : void =
        if (Canvas := CurrentCanvas?, Player := CurrentPlayer?):
            if (PlayerUI := GetPlayerUI[Player]):
                PlayerUI.RemoveWidget(Canvas)

        if (Player := CurrentPlayer?):
            if (Character := Player.GetFortCharacter[]):
                Character.ReleaseFromStasis()

        set CurrentCanvas = false
        set CurrentPlayer = false

        IntroFinishedEvent.Signal()
