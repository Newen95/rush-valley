using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters}
using { /UnrealEngine.com/Temporary/SpatialMath}
using { /Fortnite.com/Game }

enemy := class<concrete>():

    OnEnemyKilled : event(enemy) = event(enemy){}

    @editable PropManipulator : prop_manipulator_device = prop_manipulator_device{} 
    @editable DamageVolume : damage_volume_device = damage_volume_device{}
    @editable EnemyAsset : creative_prop = creative_prop{}
    
    var IsActive : logic = false
    var Looping : logic = true

    ForceKill():void=
        set Looping = false
        set IsActive = false
        DamageVolume.Disable()
        if (EnemyAsset.TeleportTo[vector3{X:=0.0, Y:=0.0, Z:=-10000.0}, IdentityRotation()]):
            ()

    @editable RunSpeed : float = 0.05
    @editable MaxHealth : float = 100.0

    @editable RunAnima : cinematic_sequence_device = cinematic_sequence_device{}
    @editable AAnim : cinematic_sequence_device = cinematic_sequence_device{}

    var CurrentHealth : float = 100.0

    InitEnemy(Agent:agent, SpawnPos:vector3, SpawnRot:rotation):void=
        set CurrentHealth = MaxHealth
        set IsActive = true
        DamageVolume.Enable()

        if (EnemyAsset.TeleportTo[SpawnPos, SpawnRot]):
            set Looping = true
            spawn{MovetoPlayer(Agent)}

        DamageVolume.AgentEntersEvent.Subscribe(Attack)
        DamageVolume.AgentExitsEvent.Subscribe(StopAttack)
        PropManipulator.DamagedEvent.Subscribe(OnDamaged)

    MovetoPlayer(Agent:agent)<suspends>:void=
        RunAnima.Play()
        loop:
            if (Looping = false):
                RunAnima.Stop()
                break

            Sleep(0.1)
            if(FortCharacter := Agent.GetFortCharacter[]):
                PropLocation := EnemyAsset.GetTransform().Translation
                PlayerLocation := FortCharacter.GetTransform().Translation

                if(LookDirection := (PlayerLocation - PropLocation).MakeUnitVector[]):
                    Yaw := RadiansToDegrees(ArcTan(LookDirection.Y, LookDirection.X)) -90.0
                    NewRotation := MakeRotationFromYawPitchRollDegrees(Yaw, 0.0, 0.0)
                    LerpLocation := Lerp(PropLocation, PlayerLocation, RunSpeed)
                    FinalLocation := vector3{X:=LerpLocation.X, Y:=LerpLocation.Y, Z := PropLocation.Z}

                    if (EnemyAsset.TeleportTo[FinalLocation, NewRotation]):
                        ()

    OnDamaged(Instigator:agent):void=
        if (Looping = true):
            set CurrentHealth -= 20.0
            if (CurrentHealth <= 0.0):
                Breakloop(option{Instigator})

    Breakloop(MaybeAgent : ?agent):void=
        if (Looping = true):
            set Looping = false
            set IsActive = false 
            DamageVolume.Disable()
            AAnim.Stop()

            HiddenLocation := vector3{X:= 0.0, Y:= 0.0, Z:= -5000.0}
            if (EnemyAsset.TeleportTo[HiddenLocation, IdentityRotation()]):
                ()

            OnEnemyKilled.Signal(Self)

    Attack(Agent:agent):void=
        AAnim.Play()

    StopAttack(Agent:agent):void=
        AAnim.Stop()

# --- Localized wave/HUD strings ---
# Real literals inside <localizes> functions (the old generic "{Text}" passthrough
# only registered the token, so none of these were ever translatable). Dynamic
# values stay as {substitution} placeholders the translator keeps in place.
LevelReadyMsg<localizes>(Level : int):message = "Enemy waves ready (Lvl {Level})! Press the button to fight."
YouDiedMsg<localizes>():message = "You died! Get ready to retry the waves..."
RelaunchMsg<localizes>():message = "Press the button to relaunch the waves."
WaveStartsInMsg<localizes>(Seconds : int):message = "WAVE STARTS IN {Seconds}..."
LetsGoMsg<localizes>():message = "LET'S GO!"
LevelWavesMsg<localizes>(Level : int, Waves : int):message = "LEVEL {Level}: {Waves} WAVES"
WaveCountMsg<localizes>(Current : int, Total : int):message = "Wave {Current} / {Total}"
ZoneSecuredMsg<localizes>():message = "Zone secured! 2 minutes rest."
NextWaveInMsg<localizes>(MinStr : string, SecStr : string):message = "Next wave available in: {MinStr}:{SecStr}"
ButtonReactivatedMsg<localizes>():message = "Button reactivated!"
WaveCompleteMsg<localizes>(Gold : int):message = "Wave complete! +{Gold} Gold"
EmptyWaveMsg<localizes>():message = ""

Wave_Manager := class(creative_device):

    var ActiveLevel : int = 1

    @editable 
    StartButton : button_device = button_device{} 
    
    @editable 
    WeaponGranter : item_granter_device = item_granter_device{}

    @editable
    GoldGranter : item_granter_device = item_granter_device{}

    @editable 
    WeaponRemover : item_remover_device = item_remover_device{}
    
    @editable
    HUDMessageDevice : hud_message_device = hud_message_device{}
    
    @editable
    CooldownBillboard : billboard_device = billboard_device{}
    
    @editable 
    EnemyPool : []enemy = array{}
    
    @editable 
    SpawnPoints : []creative_prop = array{}
    
    @editable
    PlayerSpawner : player_spawner_device = player_spawner_device{}

    @editable 
    BaseEnemiesPerWave : int = 1
    
    @editable 
    WavesPerBaseLevel : int = 1

    @editable
    GoldRewardPerLevel : int = 100

    # Flat number of GoldGranter calls per wave (each call grants GoldRewardPerLevel).
    # Replaces the old ActiveLevel scaling → the reward no longer grows with base level.
    # 2 x 100 = 200 gold per wave.
    @editable
    GoldGranterCallsPerWave : int = 2

    # Cooldown (seconds) before the Start button reactivates after a level is cleared.
    @editable
    WaveCooldownSeconds : int = 120

    var CurrentWaveIndex : int = 0
    var AliveEnemies : int = 0
    var GameStarted : logic = false
    var TotalWavesForCurrentLevel : int = 0
    var WaveFailed : logic = false

    OnBegin<override>()<suspends>:void=
        StartButton.InteractedWithEvent.Subscribe(OnStartButtonClicked)
        PlayerSpawner.SpawnedEvent.Subscribe(OnLatePlayerSpawned)
        PlayerSpawner.SpawnedEvent.Subscribe(WatchPlayerDeath)

    # Sets the wave-level values only (no on-screen prompt). Used at spawn so the
    # player doesn't see a premature "waves ready" message before the tutorial.
    ApplyLevel(Level : int):void=
        set ActiveLevel = Level
        if (Level > 0):
            set TotalWavesForCurrentLevel = Level * WavesPerBaseLevel
        else:
            set TotalWavesForCurrentLevel = 1

    # Sets the level AND shows the "enemy waves ready" prompt (used on base upgrades).
    SetLevel(Level : int):void=
        ApplyLevel(Level)
        HUDMessageDevice.SetText(LevelReadyMsg(Level))
        HUDMessageDevice.Show()

    OnStartButtonClicked(Agent:agent):void=
        StartButton.Disable()
        set GameStarted = true
        set WaveFailed = false
        StartWavesForLevel(ActiveLevel)

    StartWavesForLevel(Level : int):void=
        set ActiveLevel = Level
        
        if (Level > 0):
            set TotalWavesForCurrentLevel = Level * WavesPerBaseLevel
        else:
            set TotalWavesForCurrentLevel = 1
            
        set CurrentWaveIndex = 0
        spawn { PrepareAndStartWaves(Level) }

    WatchPlayerDeath(Agent:agent):void=
        spawn { MonitorPlayerDeath(Agent) }

    MonitorPlayerDeath(Agent:agent)<suspends>:void=
        loop:
            if(FortCharacter := Agent.GetFortCharacter[]):
                FortCharacter.EliminatedEvent().Await()
                if (GameStarted = true, WaveFailed = false):
                    OnPlayerDied()
                    break
            Sleep(0.0)

    OnPlayerDied():void=
        set WaveFailed = true

        for (E : EnemyPool):
            if (E.IsActive?):
                E.ForceKill()

        HUDMessageDevice.SetText(YouDiedMsg())
        HUDMessageDevice.Show()

        spawn { ReadyRetryAfterDeath() }

    ReadyRetryAfterDeath()<suspends>:void=
        # Brief settle so the in-flight spawn loop sees WaveFailed and stops before
        # the player can relaunch. No lockout: the only real penalty is the gold you
        # miss out on for the failed wave and the time lost on the speedrun clock.
        Sleep(1.5)

        # Strip the weapon (this also clears the copy re-granted on respawn) so the
        # next launch hands out exactly one fresh weapon instead of stacking them.
        for (Player : GetPlayspace().GetPlayers(), CurrentAgent := agent[Player]):
            WeaponRemover.Remove(CurrentAgent)

        # Restart this level's waves from the beginning on the next launch.
        set CurrentWaveIndex = 0

        HUDMessageDevice.SetText(RelaunchMsg())
        HUDMessageDevice.Show()
        StartButton.Enable()
        # WaveFailed stays true; OnStartButtonClicked clears it when the player relaunches.

    KillAllActiveEnemies():void=
        for (E : EnemyPool):
            if (E.IsActive?):
                E.Breakloop(false)

    OnLatePlayerSpawned(Agent:agent):void=
        # On this solo island the only spawn after the game starts is a respawn after
        # death. While WaveFailed is set (post-death, until the player relaunches), strip
        # any weapon at the moment the character respawns so the player isn't left armed
        # between attempts — the fresh weapon is handed out when the waves relaunch.
        # (Removing the old grant-on-respawn here is what stops the rifle lingering in
        # the inventory after dying.)
        if (WaveFailed = true):
            WeaponRemover.Remove(Agent)

    PrepareAndStartWaves(Level : int)<suspends>:void=
        for (I := 0..4):
            if (WaveFailed = true):
                return
            SecondsRemaining := 5 - I
            HUDMessageDevice.SetText(WaveStartsInMsg(SecondsRemaining))
            HUDMessageDevice.Show()
            Sleep(1.0)

        if (WaveFailed = true):
            return
        HUDMessageDevice.SetText(LetsGoMsg())
        HUDMessageDevice.Show()
        Sleep(1.0)

        for (Player : GetPlayspace().GetPlayers(), CurrentAgent := agent[Player]):
            WeaponGranter.GrantItem(CurrentAgent)

        HUDMessageDevice.SetText(LevelWavesMsg(Level, TotalWavesForCurrentLevel))
        HUDMessageDevice.Show()

        if (PlayerList := GetPlayspace().GetPlayers(), FirstPlayer := PlayerList[0], FirstAgent := agent[FirstPlayer]):
            spawn { StartWave(FirstAgent) }

    StartWave(Agent:agent)<suspends>:void=
        if (WaveFailed = true):
            return
        if (CurrentWaveIndex < TotalWavesForCurrentLevel):
            EnemiesToSpawn := (ActiveLevel * 2) + CurrentWaveIndex + BaseEnemiesPerWave
            set AliveEnemies = EnemiesToSpawn

            HUDMessageDevice.SetText(WaveCountMsg(CurrentWaveIndex + 1, TotalWavesForCurrentLevel))
            HUDMessageDevice.Show()

            var SpawnedThisWave : int = 0
            loop:
                if (WaveFailed = true):
                    return
                if (SpawnedThisWave >= EnemiesToSpawn):
                    break
                FoundEnemy : ?enemy = FindAvailableEnemy()
                if (E := FoundEnemy?):
                    if (SpawnIndex := Mod[SpawnedThisWave, SpawnPoints.Length], SpawnPoint := SpawnPoints[SpawnIndex]):
                        Trans := SpawnPoint.GetTransform()
                        spawn { WatchEnemyDeath(E) }
                        E.InitEnemy(Agent, Trans.Translation, Trans.Rotation)
                        set SpawnedThisWave += 1
                        Sleep(0.5)
                else:
                    break
            # Pool shortage only: lower the live count by the shortfall.
            # (Overwriting AliveEnemies to SpawnedThisWave erased kills that
            # happened DURING the spawn loop, leaving the count stuck above 0 so
            # the next wave never triggered — worst on the biggest/last wave.)
            if (SpawnedThisWave < EnemiesToSpawn):
                set AliveEnemies -= (EnemiesToSpawn - SpawnedThisWave)
        else:
            spawn { FinishLevelLogic() }

    FinishLevelLogic()<suspends>:void=
        if (WaveFailed = true):
            return
        HUDMessageDevice.SetText(ZoneSecuredMsg())
        HUDMessageDevice.Show()

        for (Player : GetPlayspace().GetPlayers(), CurrentAgent := agent[Player]):
            WeaponRemover.Remove(CurrentAgent)

        var SecondsRemaining : int = WaveCooldownSeconds
        loop:
            if (SecondsRemaining <= 0):
                break
            var Minutes : int = 0
            var Seconds : int = SecondsRemaining
            if (Div := SecondsRemaining / 60):
                set Minutes = Floor(Div)
            set Seconds = SecondsRemaining - (Minutes * 60)
            MinStr := GetTwoDigitString(Minutes)
            SecStr := GetTwoDigitString(Seconds)
            CooldownBillboard.SetText(NextWaveInMsg(MinStr, SecStr))
            Sleep(1.0)
            set SecondsRemaining -= 1

        CooldownBillboard.SetText(EmptyWaveMsg())
        HUDMessageDevice.SetText(ButtonReactivatedMsg())
        HUDMessageDevice.Show()
        StartButton.Enable()

    GetTwoDigitString(Value : int):string=
        if (Value < 10):
            return "0{Value}"
        else:
            return "{Value}"

    FindAvailableEnemy() : ?enemy =
        for (E : EnemyPool):
            if (not E.IsActive?):
                return option{E}
        return false

    WatchEnemyDeath(E : enemy)<suspends>:void=
        E.OnEnemyKilled.Await()
        OnEnemyDead(E)

    OnEnemyDead(DeadEnemy:enemy):void=
        if (WaveFailed = true):
            return
        set AliveEnemies -= 1
        if (AliveEnemies <= 0):
            set CurrentWaveIndex += 1
            spawn { NextWaveDelay() }

    NextWaveDelay()<suspends>:void=
        if (WaveFailed = true):
            return
        # Flat reward = GoldGranterCallsPerWave * GoldRewardPerLevel (no longer scales
        # with base level). The GoldGranter device must grant GoldRewardPerLevel (100)
        # gold per call, so we make GoldGranterCallsPerWave calls (2 x 100 = 200).
        RewardQuantity := GoldGranterCallsPerWave * GoldRewardPerLevel
        if (RewardQuantity > 0):
            for (Player : GetPlayspace().GetPlayers(), CurrentAgent := agent[Player]):
                for (I := 1..GoldGranterCallsPerWave):
                    GoldGranter.GrantItem(CurrentAgent)

            HUDMessageDevice.SetText(WaveCompleteMsg(RewardQuantity))
            HUDMessageDevice.Show()

        Sleep(4.0)

        if (WaveFailed = true):
            return
        if (CurrentWaveIndex < TotalWavesForCurrentLevel):
             # No weapon re-grant here: the weapon handed out at level start
             # (and on late join) persists between waves. GrantItem gives a NEW
             # copy each call, so re-granting every wave made the rifles pile up.
             if (PlayerList := GetPlayspace().GetPlayers(), FirstPlayer := PlayerList[0], FirstAgent := agent[FirstPlayer]):
                 spawn { StartWave(FirstAgent) }
        else:
             spawn { FinishLevelLogic() }