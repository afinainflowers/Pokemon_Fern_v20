#===============================================================================
# Initializes Battle UI elements.
#===============================================================================
class Battle::Scene
  alias enhanced_pbInitSprites pbInitSprites
  def pbInitSprites
    enhanced_pbInitSprites
    #---------------------------------------------------------------------------
    # Move info UI.
    #---------------------------------------------------------------------------
    @moveUIToggle = false
    @sprites["moveinfo"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["moveinfo"].z = 300
    @sprites["moveinfo"].visible = @moveUIToggle
    pbSetSmallFont(@sprites["moveinfo"].bitmap)
    @moveUIOverlay = @sprites["moveinfo"].bitmap
    #---------------------------------------------------------------------------
    # Battle info UI.
    #---------------------------------------------------------------------------
    @infoUIToggle = false
    @sprites["infobitmap"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["infobitmap"].z = 300
    @sprites["infobitmap"].visible = @infoUIToggle
    @infoUIOverlay1 = @sprites["infobitmap"].bitmap
    @sprites["infoselect"] = IconSprite.new(0, 0, @viewport)
    @sprites["infoselect"].setBitmap("Graphics/Plugins/Enhanced UI/Battle/battler_sel")
    @sprites["infoselect"].src_rect.set(0, 52, 166, 52)
    @sprites["infoselect"].visible = @infoUIToggle
    @sprites["infoselect"].z = 300
    @sprites["infotext"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["infotext"].z = 300
    @sprites["infotext"].visible = @infoUIToggle
    pbSetSmallFont(@sprites["infotext"].bitmap)
    @infoUIOverlay2 = @sprites["infotext"].bitmap
    @sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow", 8, 40, 28, 2, @viewport)
    @sprites["leftarrow"].x = -2
    @sprites["leftarrow"].y = 71
    @sprites["leftarrow"].z = 300
    @sprites["leftarrow"].play
    @sprites["leftarrow"].visible = false
    @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow", 8, 40, 28, 2, @viewport)
    @sprites["rightarrow"].x = Graphics.width - 38
    @sprites["rightarrow"].y = 71
    @sprites["rightarrow"].z = 300
    @sprites["rightarrow"].play
    @sprites["rightarrow"].visible = false
  end
  
  
  #-----------------------------------------------------------------------------
  # Toggles the visibility of the battle info UI.
  #-----------------------------------------------------------------------------
  def pbToggleBattleInfo
    return if pbInSafari?
    @infoUIToggle = !@infoUIToggle
    (@infoUIToggle) ? pbSEPlay("GUI party switch") : pbPlayCloseMenuSE
    @sprites["infobitmap"].visible = @infoUIToggle
    @sprites["infotext"].visible = @infoUIToggle
    pbUpdateBattlerSelection(true)
  end
  
  
  #-----------------------------------------------------------------------------
  # Toggles the visibility of the move info UI.
  #-----------------------------------------------------------------------------
  def pbToggleMoveInfo(battler, index = 0)
    @moveUIToggle = !@moveUIToggle
    (@moveUIToggle) ? pbSEPlay("GUI party switch") : pbPlayCloseMenuSE
    @sprites["moveinfo"].visible = @moveUIToggle
    pbUpdateTargetIcons
    pbUpdateMoveInfoWindow(battler, index)
  end
  
  
  #-----------------------------------------------------------------------------
  # Updates icon sprites to be used for the battle info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateBattlerIcons
    @battle.allBattlers.each do |b|
      next if !b
      poke = (b.opposes?) ? b.displayPokemon : b.pokemon
      if !b.fainted?
        @sprites["battler_icon#{b.index}"].pokemon = poke
        @sprites["battler_icon#{b.index}"].visible = @infoUIToggle
        @sprites["battler_icon#{b.index}"].setOffset(PictureOrigin::CENTER)
        @sprites["battler_icon#{b.index}"].zoom_x = 1
        @sprites["battler_icon#{b.index}"].zoom_y = 1
      else
        @sprites["battler_icon#{b.index}"].visible = false
      end
      pbUpdateOutline("battler_icon#{b.index}", poke)
      pbShowOutline("battler_icon#{b.index}", false)
    end
  end
  
  
  #-----------------------------------------------------------------------------
  # Updates icon sprites to be used for the move info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateTargetIcons
    idx = 0
    @battle.allBattlers.each do |b|
      if b && !b.fainted? && b.index.odd?
        @sprites["battler_icon#{b.index}"].pokemon = b.displayPokemon
        @sprites["battler_icon#{b.index}"].visible = @moveUIToggle
        @sprites["battler_icon#{b.index}"].x = Graphics.width - 32 - (idx * 64)
        @sprites["battler_icon#{b.index}"].y = 68
        @sprites["battler_icon#{b.index}"].zoom_x = 1
        @sprites["battler_icon#{b.index}"].zoom_y = 1
        idx += 1
      else
        @sprites["battler_icon#{b.index}"].visible = false
      end
    end
  end

  
  #-----------------------------------------------------------------------------
  # Handles the controls for the selection screen for the battle info UI.
  #-----------------------------------------------------------------------------
  def pbSelectBattlerInfo
    return if !@infoUIToggle
    idxSide = 0
    idxPoke = (@battle.pbSideBattlerCount(0) < 3) ? 0 : 1
    @sprites["infoselect"].x = (@battle.pbSideBattlerCount(0) == 2) ? 68 : 173 
    @sprites["infoselect"].y = 180
    battlers = [[], []]
    @battle.allSameSideBattlers.each { |b| battlers[0].push(b) }
    @battle.allOtherSideBattlers.reverse.each { |b| battlers[1].push(b) }
    battler = battlers[idxSide][idxPoke]
    pbShowOutline("battler_icon#{battler.index}")
    cw = @sprites["fightWindow"]
    switchUI = 0
    loop do
      pbUpdate(cw)
      pbUpdateSpriteHash(@sprites)
      oldSide = idxSide
      oldPoke = idxPoke
      break if Input.trigger?(Input::BACK) || Input.triggerex?(Settings::BATTLE_INFO_KEY)
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = pbOpenBattlerInfo(battler, battlers)
        case ret
        when Array
          idxSide, idxPoke = ret[0], ret[1]
          battler = battlers[idxSide][idxPoke]
          pbUpdateBattlerSelection
          pbShowOutline("battler_icon#{battler.index}")
        when Numeric
          switchUI = ret
          break
        when nil then break
        end
      elsif Input.trigger?(Input::LEFT) && @battle.pbSideBattlerCount(idxSide) > 1
        idxPoke -= 1
        idxPoke = @battle.pbSideBattlerCount(idxSide) - 1 if idxPoke < 0
        pbPlayCursorSE
      elsif Input.trigger?(Input::RIGHT) && @battle.pbSideBattlerCount(idxSide) > 1
        idxPoke += 1
        idxPoke = 0 if idxPoke > @battle.pbSideBattlerCount(idxSide) - 1
        pbPlayCursorSE
      elsif Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
        idxSide = (idxSide == 0) ? 1 : 0
        if idxPoke > @battle.pbSideBattlerCount(idxSide) - 1
          until idxPoke == @battle.pbSideBattlerCount(idxSide) - 1
            idxPoke -= 1
          end
        end
        pbPlayCursorSE
      elsif cw.visible && Input.triggerex?(Settings::MOVE_INFO_KEY)
        switchUI = 1
        break
      elsif PluginManager.installed?("Focus Meter System") && Input.triggerex?(Settings::FOCUS_PANEL_KEY)
        switchUI = 2
        break
      end
      if oldSide != idxSide || oldPoke != idxPoke
        @sprites["infoselect"].y = (idxSide == 0) ? 180 : 104
        case @battle.pbSideBattlerCount(idxSide)
        when 1 then @sprites["infoselect"].x = 173
        when 2 then @sprites["infoselect"].x = 68 + (208 * idxPoke)
        when 3 then @sprites["infoselect"].x = 4 + (169 * idxPoke)
        end
        battler = battlers[idxSide][idxPoke]
        @battle.allBattlers.each do |b|
          if b.index == battler.index
            pbShowOutline("battler_icon#{b.index}")
          else
            pbShowOutline("battler_icon#{b.index}", false)
          end
        end
      end
    end
    pbHideBattleInfo
    pbUpdateBattlerIcons
    case switchUI
    when 0 then pbPlayCloseMenuSE
    when 1 then pbToggleMoveInfo(battler, cw.index)
    when 2 then pbToggleFocusPanel if !cw.visible
    end
  end
  
  
  #-----------------------------------------------------------------------------
  # Handles the controls for the battle info UI.
  #-----------------------------------------------------------------------------
  def pbOpenBattlerInfo(battler, battlers)
    return if !@infoUIToggle
    ret = nil
    idx = 0
    battlerTotal = battlers.flatten
    for i in 0...battlerTotal.length
      idx = i if battler == battlerTotal[i]
    end
    maxSize = battlerTotal.length - 1
    @sprites["infoselect"].visible = false
    pbUpdateBattlerInfo(battler)
    cw = @sprites["fightWindow"]
    @sprites["leftarrow"].visible = true
    @sprites["rightarrow"].visible = true
    loop do
      oldIdx = idx
      pbUpdate(cw)
      pbUpdateSpriteHash(@sprites)
      break if Input.trigger?(Input::BACK)
      if Input.trigger?(Input::LEFT)
        idx -= 1
        idx = maxSize if idx < 0
      elsif Input.trigger?(Input::RIGHT)
        idx += 1
        idx = 0 if idx > maxSize
      elsif cw.visible && Input.triggerex?(Settings::MOVE_INFO_KEY)
        ret = 1
        break
      elsif PluginManager.installed?("Focus Meter System") && Input.triggerex?(Settings::FOCUS_PANEL_KEY)
        ret = 2
        break
      elsif Input.trigger?(Input::USE) || Input.triggerex?(Settings::BATTLE_INFO_KEY)
        ret = [0, 0]
        if battler.opposes?
          ret[0] = 1
          @battle.allOtherSideBattlers.reverse.each_with_index { |b, i| ret[1] = i if b == battler }
        else
          ret[0] = 0
          @battle.allSameSideBattlers.each_with_index { |b, i| ret[1] = i if b == battler }
        end
        pbPlayDecisionSE
        break
      end
      if oldIdx != idx
        pbPlayCursorSE
        battler = battlerTotal[idx]
        pbUpdateBattlerInfo(battler)
      end
    end
    @sprites["leftarrow"].visible = false
    @sprites["rightarrow"].visible = false
    return ret
  end
  
  
  #-----------------------------------------------------------------------------
  # Draws the selection screen for the battle info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateBattlerSelection(select = false)
    @infoUIOverlay1.clear
    @infoUIOverlay2.clear
    return if !@infoUIToggle
    xpos = 0
    ypos = 94
    base = Color.new(232, 232, 232)
    shadow = Color.new(72, 72, 72)
    path = "Graphics/Plugins/Enhanced UI/Battle/"
    textPos = []
    imagePos1 = [[path + "battler_sel_bg", xpos, ypos]]
    imagePos2 = []
    2.times do |side|
      count = @battle.pbSideBattlerCount(side)
      case side
      #-------------------------------------------------------------------------
      # Player's side.
      #-------------------------------------------------------------------------
      when 0
        # Draws Pokemon selection.
        @battle.allSameSideBattlers.each_with_index do |b, i|
          case count
          when 1 then iconX, bgX = 202, 173
          when 2 then iconX, bgX = 96 + (208 * i), 68 + (208 * i)
          when 3 then iconX, bgX = 32 + (168 * i), 4 + (169 * i)
          end
          iconY = ypos + 114
          nameX = iconX + 82
          @sprites["battler_icon#{b.index}"].x = iconX
          @sprites["battler_icon#{b.index}"].y = iconY
          pbSetWithOutline("battler_icon#{b.index}", [iconX, iconY, 400])
          imagePos1.push([path + "battler_sel", bgX, iconY - 28, 0, 0, 166, 52])
          imagePos2.push([path + "battler_owner", bgX + 36, iconY + 11],
                         [path + "battler_gender", bgX + 146, iconY - 37, b.gender * 22, 0, 22, 20])
          textPos.push([_INTL("{1}", b.pokemon.name), nameX, iconY - 16, 2, base, shadow],
                       [@battle.pbGetOwnerFromBattlerIndex(b.index).name, nameX - 10, iconY + 13, 2, base, shadow])
        end
        trainers = []
        @battle.player.each { |p| trainers.push(p) if p.able_pokemon_count > 0 }
        ballY = ypos + 154
        ballXFirst = 35
        ballXLast = Graphics.width - (16 * NUM_BALLS) - 35
        ballOffset = 2
      #-------------------------------------------------------------------------
      # Opponent's side.
      #-------------------------------------------------------------------------
      when 1
        # Draws Pokemon selection.
        @battle.allOtherSideBattlers.reverse.each_with_index do |b, i|
          case count
          when 1 then iconX, bgX = 202, 173
          when 2 then iconX, bgX = 96 + (208 * i), 68 + (208 * i)
          when 3 then iconX, bgX = 32 + (168 * i), 4 + (169 * i)
          end
          iconY = ypos + 38
          nameX = iconX + 82
          @sprites["battler_icon#{b.index}"].x = iconX
          @sprites["battler_icon#{b.index}"].y = iconY
          pbSetWithOutline("battler_icon#{b.index}", [iconX, iconY, 400])
          imagePos1.push([path + "battler_sel", bgX, iconY - 28, 0, 0, 166, 52])
          textPos.push([_INTL("{1}", b.displayPokemon.name), nameX, iconY - 16, 2, base, shadow])
          if @battle.trainerBattle?
            imagePos2.push([path + "battler_owner", bgX + 36, iconY + 11])
            textPos.push([@battle.pbGetOwnerFromBattlerIndex(b.index).name, nameX - 10, iconY + 13, 2, base, shadow])
          end
          imagePos2.push([path + "battler_gender", bgX + 146, iconY - 37, b.displayPokemon.gender * 22, 0, 22, 20])
        end
        trainers = []
        @battle.opponent.each { |p| trainers.push(p) if p.able_pokemon_count > 0 } if @battle.opponent
        ballY = ypos - 17
        ballXFirst = Graphics.width - (16 * NUM_BALLS) - 35
        ballXLast = 35
        ballOffset = 3
      end
      #-------------------------------------------------------------------------
      # Draws party ball lineups.
      #-------------------------------------------------------------------------
      ballXMiddle = (Graphics.width / 2) - 48
      ballX = ballXMiddle
      trainers.each do |trainer|
        if trainers.length > 1
          case trainer
          when trainers.first then ballX = ballXFirst
          when trainers.last  then ballX = ballXLast
          else                     ballX = ballXMiddle
          end
        end
        imagePos1.push([path + "battler_owner", ballX - 16, ballY - ballOffset])
        NUM_BALLS.times do |slot|
          idx = 0
          if !trainer.party[slot]                   then idx = 3 # Empty
          elsif !trainer.party[slot].able?          then idx = 2 # Fainted
          elsif trainer.party[slot].status != :NONE then idx = 1 # Status
          end
          imagePos2.push([path + "battler_ball", ballX + (slot * 16), ballY, idx * 15, 0, 15, 15])
        end
      end
    end
    pbUpdateBattlerIcons
    pbDrawImagePositions(@infoUIOverlay1, imagePos1)
    pbDrawImagePositions(@infoUIOverlay2, imagePos2)
    pbDrawTextPositions(@infoUIOverlay2, textPos)
    @sprites["infoselect"].visible = true
    pbSelectBattlerInfo if select
  end
  
  
  #-----------------------------------------------------------------------------
  # Draws the battle info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateBattlerInfo(battler)
    @infoUIOverlay1.clear
    @infoUIOverlay2.clear
    pbUpdateBattlerIcons
    return if !@infoUIToggle
    base = Color.new(232, 232, 232)
    shadow = Color.new(72, 72, 72)
    path = "Graphics/Plugins/Enhanced UI/Battle/"
    xpos = 28
    ypos = 25
    iconX = xpos + 29
    iconY = ypos + 62
    panelX = xpos + 239
    #---------------------------------------------------------------------------
    # Sets up general UI elements.
    poke = (battler.opposes?) ? battler.displayPokemon : battler.pokemon
    imagePos = [[path + "battle_info_bg", 0, 0],
                [path + "battle_info_ui", 0, 0],
                [path + "battler_gender", xpos + 146, ypos + 24, poke.gender * 22, 0, 22, 20]]
    textPos  = [[_INTL("{1}", poke.name), iconX + 83, iconY - 16, 2, base, shadow],
                [_INTL("Lv. {1}", battler.level), xpos + 17, ypos + 100, 0, base, shadow],
                [_INTL("Turn {1}", @battle.turnCount + 1), Graphics.width - xpos - 32, ypos + 6, 2, base, shadow]]
    #---------------------------------------------------------------------------
    # Updates battler icon.
    @battle.allBattlers.each do |b|
      @sprites["battler_icon#{b.index}"].x = iconX
      @sprites["battler_icon#{b.index}"].y = iconY
      @sprites["battler_icon#{b.index}"].visible = (b == battler)
    end
    #---------------------------------------------------------------------------
    # Sets up graphics for battler's HP and status.
    if battler.hp > 0
      w = battler.hp * 96 / battler.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2
      hpzone = 0
      hpzone = 1 if battler.hp <= (battler.totalhp / 2).floor
      hpzone = 2 if battler.hp <= (battler.totalhp / 4).floor
      imagePos.push(["Graphics/Pictures/Battle/overlay_hp", 86, 89, 0, hpzone * 6, w, 6])
    end
    if battler.status != :NONE
      iconPos = GameData::Status.get(battler.status).icon_position
      imagePos.push(["Graphics/Pictures/statuses", xpos + 79, ypos + 99, 0, iconPos * 16, 44, 16])
    end
    imagePos.push(["Graphics/Pictures/shiny", xpos - 3, ypos + 99]) if poke.shiny?
    #---------------------------------------------------------------------------
    # Displays owner's name for non-wild battlers.
    if !battler.wild?
      imagePos.push([path + "battler_owner", xpos - 34, ypos + 4])
      textPos.push([@battle.pbGetOwnerFromBattlerIndex(battler.index).name, xpos + 32, ypos + 6, 2, base, shadow])
    end
    #---------------------------------------------------------------------------
    # Displays HP, Item, and Ability information if battler is owned by the player.
    if battler.pbOwnedByPlayer?
      imagePos.push(
        [path + "battler_owner", xpos + 36, iconY + 11],
        [path + "battle_info_panel", panelX, 63, 0, 0, 218, 24],
        [path + "battle_info_panel", panelX, 87, 0, 0, 218, 24]
      )
      textPos.push(
        [_INTL("Abil."), xpos + 272, ypos + 42, 2, base, shadow],
        [_INTL("Item"), xpos + 272, ypos + 66, 2, base, shadow],
        [_INTL("{1}", battler.abilityName), xpos + 375, ypos + 42, 2, base, shadow],
        [_INTL("{1}", battler.itemName), xpos + 375, ypos + 66, 2, base, shadow],
        [sprintf("%d/%d", battler.hp, battler.totalhp), iconX + 73, iconY + 13, 2, base, shadow]
      )
    end
    #---------------------------------------------------------------------------
    # Draws text and displays for the battler's stat changes.
    [[:ATTACK,          _INTL("Attack")],
     [:DEFENSE,         _INTL("Defense")], 
     [:SPECIAL_ATTACK,  _INTL("Sp. Atk")], 
     [:SPECIAL_DEFENSE, _INTL("Sp. Def")], 
     [:SPEED,           _INTL("Speed")], 
     [:ACCURACY,        _INTL("Accuracy")], 
     [:EVASION,         _INTL("Evasion")],
     _INTL("Crit. Hit")
    ].each_with_index do |stat, i|
      if stat.is_a?(Array)
        color = shadow
        if battler.pbOwnedByPlayer?
          battler.pokemon.nature_for_stats.stat_changes.each do |s|
            if stat[0] == s[0]
              color = Color.new(136, 96, 72) if s[1] > 0
              color = Color.new(64, 120, 152) if s[1] < 0
            end
          end
        end
        textPos.push([stat[1], xpos + 17, ypos + 135 + (i * 24), 0, base, color])
        stage = battler.stages[stat[0]]
      else
        textPos.push([stat, xpos + 17, ypos + 135 + (i * 24), 0, base, shadow])
        stage = [battler.effects[PBEffects::FocusEnergy] + battler.effects[PBEffects::CriticalBoost], 4].min
      end
      arrow = (stage > 0) ? 0 : 1
      stage.abs.times { |t| imagePos.push([path + "battler_stats", xpos + 105 + (t * 18), ypos + 135 + (i * 24), arrow * 18, 0, 18, 18]) }
    end
    #---------------------------------------------------------------------------
    # Draws panels and text for all relevant battle effects affecting the battler.
    effects = []
    if @battle.field.weather != :None
      count = @battle.field.weatherDuration
      count = (count > 0) ? "#{count}/5" : "---"
      effects.push([GameData::BattleWeather.get(@battle.field.weather).name, count])
    end
    if @battle.field.terrain != :None
      count = @battle.field.terrainDuration
      count = (count > 0) ? "#{count}/5" : "---"
      effects.push([GameData::BattleTerrain.get(@battle.field.terrain).name + " " + _INTL("Terrain"), count])
    end
    # Effects that apply to the whole field.
    field_effects = {
      PBEffects::MudSportField   => [_INTL("Mud Sport"),       5],
      PBEffects::WaterSportField => [_INTL("Water Sport"),     5],
      PBEffects::TrickRoom       => [_INTL("Trick Room"),      5], 
      PBEffects::MagicRoom       => [_INTL("Magic Room"),      5],
      PBEffects::WonderRoom      => [_INTL("Wonder Room"),     5],
      PBEffects::Gravity         => [_INTL("Gravity"),         5],
      PBEffects::FairyLock       => [_INTL("Fairy Lock"),      2]
    }
    # Effects that apply to one side of the field.
    team_effects = {
      PBEffects::AuroraVeil      => [_INTL("Aurora Veil"),     5], 
      PBEffects::Reflect         => [_INTL("Reflect"),         5],
      PBEffects::LightScreen     => [_INTL("Light Screen"),    5],
      PBEffects::Mist            => [_INTL("Mist"),            5],
      PBEffects::Safeguard       => [_INTL("Safeguard"),       5],
      PBEffects::LuckyChant      => [_INTL("Lucky Chant"),     5],
      PBEffects::Tailwind        => [_INTL("Tailwind"),        4],
      PBEffects::Rainbow         => [_INTL("Rainbow"),         4],
      PBEffects::SeaOfFire       => [_INTL("Sea of Fire"),     4],
      PBEffects::Swamp           => [_INTL("Swamp"),           4]
    }
    # Effects that apply to an individual battler.
    battler_effects = {
      PBEffects::Disable         => [_INTL("Disable"),         5],
      PBEffects::Embargo         => [_INTL("Embargo"),         5],
      PBEffects::HealBlock       => [_INTL("Heal Block"),      5],
      PBEffects::MagnetRise      => [_INTL("Magnet Rise"),     5],
      PBEffects::Encore          => [_INTL("Encore"),          4],
      PBEffects::Taunt           => [_INTL("Taunt"),           4],
      PBEffects::PerishSong      => [_INTL("Perish Song"),     3],
      PBEffects::Telekinesis     => [_INTL("Telekinesis"),     3],
      PBEffects::ThroatChop      => [_INTL("Throat Chop"),     3]
    }
    if battler.effects[PBEffects::Trapping] > 0
      moveName = GameData::Move.get(battler.effects[PBEffects::TrappingMove]).name
      battler_effects[PBEffects::Trapping]  = [_INTL("{1}", moveName),   5]
    end
    # Adds plugin-specific effects.
    if PluginManager.installed?("ZUD Mechanics")
      team_effects[PBEffects::VineLash]     = [_INTL("G-Max Vine Lash"), 4]
      team_effects[PBEffects::Wildfire]     = [_INTL("G-Max Wildfire"),  4]
      team_effects[PBEffects::Cannonade]    = [_INTL("G-Max Cannonade"), 4]
      team_effects[PBEffects::Volcalith]    = [_INTL("G-Max Volcalith"), 4]
      battler_effects[PBEffects::Dynamax]   = [_INTL("Dynamax"), Settings::DYNAMAX_TURNS]
    end
    if PluginManager.installed?("Focus Meter System")
      team_effects[PBEffects::FocusedGuard] = [_INTL("Focused Guard"),   4]
      battler_effects[PBEffects::FocusLock] = [_INTL("Focus Lock"),      4]
    end
    # Draws a list of each of the above effects currently in play.
    field_effects.each do |key, value|
      next if @battle.field.effects[key] == 0
      count = @battle.field.effects[key]
      count = (count > 0) ? "#{count}/#{value[1]}" : "---"
      effects.push([value[0], count])
    end
    team_effects.each do |key, value|
      next if battler.pbOwnSide.effects[key] == 0
      count = battler.pbOwnSide.effects[key]
      count = (count > 0) ? "#{count}/#{value[1]}" : "---"
      effects.push([value[0], count])
    end
    battler_effects.each do |key, value|
      next if battler.effects[key] == 0
      count = battler.effects[key]
      count = (count > 0) ? "#{count}/#{value[1]}" : "---"
      count = "---" if value[0] == _INTL("Dynamax") && battler.effects[PBEffects::MaxRaidBoss]
      effects.push([value[0], count])
    end
    effects.each_with_index do |effect, i|
      break if i == 8
      imagePos.push([path + "battle_info_panel", panelX, ypos + 132 + (i * 24), 0, 24, 218, 24])
      textPos.push([effect[0], xpos + 321, ypos + 136 + (i * 24), 2, base, shadow],
                   [effect[1], xpos + 425, ypos + 136 + (i * 24), 2, base, shadow])
    end
    #---------------------------------------------------------------------------
    # Draws the battler's last used move.
    if battler.lastMoveUsed
      move = GameData::Move.get(battler.lastMoveUsed).name
      textPos.push([_INTL("Used: #{move}"), xpos + 314, ypos + 100, 2, base, shadow])
    end
    #---------------------------------------------------------------------------
    # Draws all of the above text and images.
    pbDrawImagePositions(@infoUIOverlay1, imagePos)
    pbDrawTextPositions(@infoUIOverlay2, textPos)
    #---------------------------------------------------------------------------
    # Draws the battler's types. Displays the "???" type on newly encountered species.
    if battler.effects[PBEffects::Illusion] && !battler.pbOwnedByPlayer?
      displayTypes = poke.types
      displayTypes.push(battler.effects[PBEffects::Type3]) if battler.effects[PBEffects::Type3]
    else
      displayTypes = battler.pbTypes(true)
    end
    if !(battler.pbOwnedByPlayer? || 
       $player.pokedex.battled_count(poke.species) > 0 || 
       $player.pokedex.owned?(poke.species)) || 
       displayTypes.empty?
      displayTypes = [:QMARKS]
    end
    typeY = (displayTypes.length == 3) ? ypos + 7 : ypos + 37
    typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    displayTypes.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      @infoUIOverlay1.blt(xpos + 171, typeY + (i * 30), typebitmap.bitmap, type_rect)
    end
  end
  
  
  #-----------------------------------------------------------------------------
  # Draws the move info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateMoveInfoWindow(battler, index)
    @moveUIOverlay.clear
    return if !@moveUIToggle
    xpos = 0
    ypos = 94
    move = battler.moves[index]
    path = "Graphics/Plugins/Enhanced UI/Battle/"
    #---------------------------------------------------------------------------
    # Draws the menu, and icons for move type and category.
    typenumber = GameData::Type.get(move.type).icon_position
    imagePos = [
      [path + "move_info_bg",        xpos, ypos],
      ["Graphics/Pictures/types",    xpos + 272, ypos + 4, 0, typenumber * 28, 64, 28],
      ["Graphics/Pictures/category", xpos + 336, ypos + 4, 0, move.category * 28, 64, 28]
    ]
    #---------------------------------------------------------------------------
    # Draws the effectiveness display for each opponent.
    idx = 0
    @battle.allBattlers.each do |b|
      next if b.index.even?
      if b && !b.fainted? && move.category < 2
        poke = b.displayPokemon
        unknown_species = ($player.pokedex.battled_count(poke.species) == 0 && !$player.pokedex.owned?(poke.species))
        value = Effectiveness.calculate(move.type, poke.types[0], poke.types[1])
        if unknown_species                             then effct = 0
        elsif Effectiveness.ineffective?(value)        then effct = 1
        elsif Effectiveness.not_very_effective?(value) then effct = 2
        elsif Effectiveness.super_effective?(value)    then effct = 3
        else effct = 4
        end
        imagePos.push([path + "move_effectiveness", Graphics.width - 64 - (idx * 64), ypos - 76, effct * 64, 0, 64, 76])
        @sprites["battler_icon#{b.index}"].visible = true
      else
        @sprites["battler_icon#{b.index}"].visible = false
      end
      idx += 1
    end
    #---------------------------------------------------------------------------
    # Draws icons for each relevant move flag.
    flagX = xpos + 5
    flagY = ypos + 32
    flagIcons = []
    if PluginManager.installed?("ZUD Mechanics")
      if move.zMove?
        flagIcons.push([path + "move_icons", flagX + (flagIcons.length * 26), flagY, 0 * 26, 0, 26, 28])
      elsif move.maxMove?
        flagIcons.push([path + "move_icons", flagX + (flagIcons.length * 26), flagY, 1 * 26, 0, 26, 28])
      end
    end
    if GameData::Target.get(move.target).targets_foe
      flagIcons.push([path + "move_icons", flagX + (flagIcons.length * 26), flagY, 2 * 26, 0, 26, 28]) if !move.flags.include?("CanProtect")
      flagIcons.push([path + "move_icons", flagX + (flagIcons.length * 26), flagY, 3 * 26, 0, 26, 28]) if !move.flags.include?("CanMirrorMove")
    end
    move.flags.each do |flag|
      idx = -1
      case flag
      when "Contact"             then idx = 4
      when "TramplesMinimize"    then idx = 5
      when "HighCriticalHitRate" then idx = 6
      when "ThawsUser"           then idx = 7
      when "Sound"               then idx = 8
      when "Punching"            then idx = 9
      when "Biting"              then idx = 10
      when "Bomb"                then idx = 11
      when "Pulse"               then idx = 12
      when "Powder"              then idx = 13
      when "Dance"               then idx = 14
      end
      next if idx < 0
      flagIcons.push([path + "move_icons", flagX + (flagIcons.length * 26), flagY, idx * 26, 0, 26, 28])
    end
    imagePos += flagIcons
    pbDrawImagePositions(@moveUIOverlay, imagePos)
    #---------------------------------------------------------------------------
    # Sets up move data.
    base = Color.new(232, 232, 232)
    shadow = Color.new(72, 72, 72)
    raised_base = Color.new(50, 205, 50)
    raised_shadow = Color.new(9, 121, 105)
    lowered_base = Color.new(248, 72, 72)
    lowered_shadow = Color.new(136, 48, 48)
    power = (move.baseDamage == 0) ? "---" : (move.baseDamage == 1) ? "???" : move.baseDamage.to_s
    accuracy = (move.accuracy == 0) ? "---" : move.accuracy.to_s
    effectrate = (move.addlEffect == 0) ? "---" : [:ICEFANG, :FIREFANG, :THUNDEFANG].include?(move.id) ? "10%" : move.addlEffect.to_s + "%"
    dmg_base = acc_base = eff_base = base
    dmg_shadow = acc_shadow = eff_shadow = shadow
    textPos = []
    #---------------------------------------------------------------------------
    # Sets up additional text for Z-Moves. (ZUD)
    if PluginManager.installed?("ZUD Mechanics") && move.zMove? && move.category == 2
      if GameData::PowerMove.stat_booster?(move.id)
        stats, stage = GameData::PowerMove.stat_with_stage(move.id)
        statname = (stats.length > 1) ? "stats" : GameData::Stat.get(stats.first).name
        case stage
        when 3 then boost = " drastically"
        when 2 then boost = " sharply"
        else        boost = ""
        end
        text = _INTL("Raises the user's #{statname}#{boost}.")
      elsif GameData::PowerMove.boosts_crit?(move.id)  then text = _INTL("Raises the user's critical hit rate.")
      elsif GameData::PowerMove.resets_stats?(move.id) then text = _INTL("Resets the user's lowered stat stages.")
      elsif GameData::PowerMove.heals_self?(move.id)   then text = _INTL("Fully restores the user's HP.")
      elsif GameData::PowerMove.heals_switch?(move.id) then text = _INTL("Fully restores an incoming Pokémon's HP.")
      elsif GameData::PowerMove.focus_user?(move.id)   then text = _INTL("The user becomes the center of attention.")
      end
      textPos.push([_INTL("Z-Power: #{text}"), xpos + 10, ypos + 128, 0, raised_base, raised_shadow]) if text
    #---------------------------------------------------------------------------
    # Sets up additional text for moves affected by Battle Styles. (PLA)
    elsif PluginManager.installed?("PLA Battle Styles") && move.mastered?
      case battler.style_trigger
      when 1
        if move.baseDamage > 1
          dmg_base = raised_base
          dmg_shadow = raised_shadow
        end
        if ![0, 100].include?(move.old_accuracy)
          acc_base = raised_base
          acc_shadow = raised_shadow
        end
        if ![0, 100].include?(move.old_addlEffect)
          eff_base = raised_base
          eff_shadow = raised_shadow
        end
        if move.strongStyleStatUp?
          textPos.push([_INTL("Strong Style: Number of stat stages raised +1."), xpos + 10, ypos + 128, 0, raised_base, raised_shadow])
        elsif move.strongStyleStatDown?
          textPos.push([_INTL("Strong Style: Number of stat stages lowered +1."), xpos + 10, ypos + 128, 0, raised_base, raised_shadow])
        elsif move.strongStyleHealing?
          textPos.push([_INTL("Strong Style: The amount of HP healed is increased."), xpos + 10, ypos + 128, 0, raised_base, raised_shadow])
        elsif move.strongStyleRecoil?
          textPos.push([_INTL("Strong Style: The amount of recoil taken is increased."), xpos + 10, ypos + 128, 0, lowered_base, lowered_shadow])
        end
      when 2
        if move.baseDamage > 1 
          dmg_base = lowered_base
          dmg_shadow = lowered_shadow
        end
        if move.agileStyleStatUp?
          textPos.push([_INTL("Agile Style: Number of stat stages raised -1."), xpos + 10, ypos + 128, 0, lowered_base, lowered_shadow])
          elsif move.agileStyleStatDown?
          textPos.push([_INTL("Agile Style: Number of stat stages lowered -1."), xpos + 10, ypos + 128, 0, lowered_base, lowered_shadow])
        elsif move.agileStyleHealing?
          textPos.push([_INTL("Agile Style: The amount of HP healed is reduced."), xpos + 10, ypos + 128, 0, lowered_base, lowered_shadow])
        elsif move.agileStyleRecoil?
          textPos.push([_INTL("Agile Style: The amount of recoil taken is reduced."), xpos + 10, ypos + 128, 0, raised_base, raised_shadow])
        end
      end
    end
    #---------------------------------------------------------------------------
    # Draws move data text.
    textPos.push(
      [move.name,       xpos + 10,            ypos + 8,  0, base, shadow],
      [_INTL("Pow:"),   Graphics.width - 86,  ypos + 10, 2, base, shadow],
      [_INTL("Acc:"),   Graphics.width - 86,  ypos + 39, 2, base, shadow],
      [_INTL("Effct:"), xpos + 287,           ypos + 39, 0, base, shadow],
      [power,           Graphics.width - 34,  ypos + 10, 2, dmg_base, dmg_shadow],
      [accuracy,        Graphics.width - 34,  ypos + 39, 2, acc_base, acc_shadow],
      [effectrate,      Graphics.width - 146, ypos + 39, 2, eff_base, eff_shadow]
    )
    pbDrawTextPositions(@moveUIOverlay, textPos)
    drawTextEx(@moveUIOverlay, xpos + 10, ypos + 70, Graphics.width - 10, 2, GameData::Move.get(move.id).description, base, shadow)
  end
end