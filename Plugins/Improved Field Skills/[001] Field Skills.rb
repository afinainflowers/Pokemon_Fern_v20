#===============================================================================
# Field Skill species data.
#===============================================================================
module GameData
  class Species
    attr_accessor :field_skills
    
    alias fieldskill_initialize initialize
    def initialize(hash)
      fieldskill_initialize(hash)
      @field_skills = []
    end
    
    def has_skill?(skill)
      skill = skill.upcase.to_sym if skill.is_a?(String)
      return @field_skills.any? { |s| s == skill }
    end
  end
end


#===============================================================================
# Miscellaneous checks for Field Skills.
#===============================================================================
def pbBadgeFromSkill(skill)
  case skill
  when :CUT       then badge = Settings::BADGE_FOR_CUT
  when :FLY       then badge = Settings::BADGE_FOR_FLY
  when :DIVE      then badge = Settings::BADGE_FOR_DIVE
  when :FLASH     then badge = Settings::BADGE_FOR_FLASH
  when :ROCKSMASH then badge = Settings::BADGE_FOR_ROCKSMASH
  when :STRENGTH  then badge = Settings::BADGE_FOR_STRENGTH
  when :SURF      then badge = Settings::BADGE_FOR_SURF
  when :WATERFALL then badge = Settings::BADGE_FOR_WATERFALL
  else badge = -1
  end
  return badge
end

class Pokemon
  def has_field_skill?
    return false if egg?
	# Checks for HM Skills.
    Settings::HM_SKILLS.each do |skill| 
      next if !GameData::Move.exists?(skill)
	  next if !HiddenMoveHandlers.hasHandler(skill)
      if Settings::HM_SKILLS_REQUIRE_BADGE
	    badge = pbBadgeFromSkill(skill)
		next if badge > 0 && !pbCheckHiddenMoveBadge(badge, false)
	  end
      return true if self.species_data.has_skill?(skill) || self.hasMove?(skill)
    end
	# Checks for Misc. Skills.
	Settings::MISC_SKILLS.each do |skill|
	  next if !GameData::Move.exists?(skill)
	  next if !HiddenMoveHandlers.hasHandler(skill)
	  next if Settings::MISC_SKILLS_REQUIRE_MOVE && !self.hasMove?(skill)
	  return true if self.species_data.has_skill?(skill) || self.hasMove?(skill)
	end
	# Checks for Heal Skills.
	Settings::HEAL_SKILLS.each do |skill|
	  next if !GameData::Move.exists?(skill)
	  next if Settings::HEAL_SKILLS_REQUIRE_MOVE && !self.hasMove?(skill)
	  return true if self.species_data.has_skill?(skill) || self.hasMove?(skill)
	end
    return false
  end
end

class Trainer
  def get_pokemon_with_move(move)
    pokemon_party.each { |pkmn| return pkmn if pkmn.hasMove?(move) || pkmn.species_data.has_skill?(move) }
    return nil
  end
  
  def get_pokemon_with_skill(skill)
    pokemon_party.each { |pkmn| return pkmn if pkmn.species_data.has_skill?(skill) }
    return nil
  end
end
  

#===============================================================================
# Field Skill menu handler.
#===============================================================================
MenuHandlers.add(:party_menu, :field_skill, {
  "name"      => _INTL("Skills"),
  "order"     => 21,
  "condition" => proc { |screen, party, party_idx| next party[party_idx].has_field_skill? },
  "effect"    => proc { |screen, party, party_idx|
    ret = nil
    pkmn = party[party_idx]
    command = 0
    loop do
	  skills = []
      commands = []
	  #-------------------------------------------------------------------------
	  # Adds HM Skills.
	  #-------------------------------------------------------------------------
	  Settings::HM_SKILLS.each do |skill|
	    next if !GameData::Move.exists?(skill)
		next if !HiddenMoveHandlers.hasHandler(skill)
		next if !pkmn.species_data.has_skill?(skill) && !pkmn.hasMove?(skill)
		badge = pbBadgeFromSkill(skill)
		next if Settings::HM_SKILLS_REQUIRE_BADGE && badge > 0 && !pbCheckHiddenMoveBadge(badge, false)
		color = (pbCanUseHiddenMove?(pkmn, skill, false) && pbCheckHiddenMoveBadge(badge, false)) ? 1 : 4
		commands.push([GameData::Move.get(skill).name, color])
		skills.push(skill)
	  end
	  #-------------------------------------------------------------------------
	  # Adds Misc. Skills.
	  #-------------------------------------------------------------------------
	  Settings::MISC_SKILLS.each do |skill|
	    next if !GameData::Move.exists?(skill)
		next if !HiddenMoveHandlers.hasHandler(skill)
		if Settings::MISC_SKILLS_REQUIRE_MOVE
		  next if !pkmn.hasMove?(skill)
		else
		  next if !pkmn.species_data.has_skill?(skill) && !pkmn.hasMove?(skill)
		end
		color = (pbCanUseHiddenMove?(pkmn, skill, false)) ? 1 : 4
		commands.push([GameData::Move.get(skill).name, color])
		skills.push(skill)
	  end
	  #-------------------------------------------------------------------------
	  # Adds Heal Skills.
	  #-------------------------------------------------------------------------
	  Settings::HEAL_SKILLS.each do |skill|
	    next if !GameData::Move.exists?(skill)
		if Settings::HEAL_SKILLS_REQUIRE_MOVE
		  next if !pkmn.hasMove?(skill)
		else
		  next if !pkmn.species_data.has_skill?(skill) && !pkmn.hasMove?(skill)
		end
		color = (pkmn.hp >= [(pkmn.totalhp / 5).floor, 1].max) ? 1 : 4
		commands.push([GameData::Move.get(skill).name, color])
		skills.push(skill)
	  end
      commands.push("Cancel")
      command = screen.scene.pbShowCommands(_INTL("Do what with {1}?", pkmn.name), commands, command)
      if command < 0 || command >= commands.length - 1
	    break
      else
	    #-----------------------------------------------------------------------
		# Performs Heal Skill effect.
		#-----------------------------------------------------------------------
	    if Settings::HEAL_SKILLS.include?(skills[command])
          amt = [(pkmn.totalhp / 5).floor, 1].max
          if pkmn.hp <= amt
            screen.scene.pbDisplay(_INTL("Not enough HP..."))
            next
          end
          screen.scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
          new_party_idx = old_party_idx = party_idx
          loop do
            screen.scene.pbPreSelect(old_party_idx)
            new_party_idx = screen.scene.pbChoosePokemon(true, new_party_idx)
            break if new_party_idx < 0
            newpkmn = party[new_party_idx]
            movename = commands[command]
            if new_party_idx == old_party_idx
              screen.scene.pbDisplay(_INTL("{1} can't use {2} on itself!", pkmn.name, movename))
            elsif newpkmn.egg?
              screen.scene.pbDisplay(_INTL("{1} can't be used on an Egg!", movename))
            elsif newpkmn.fainted? || newpkmn.hp == newpkmn.totalhp
              screen.scene.pbDisplay(_INTL("{1} can't be used on that Pokémon.", movename))
            else
              pkmn.hp -= amt
              hpgain = pbItemRestoreHP(newpkmn, amt)
              screen.scene.pbDisplay(_INTL("{1}'s HP was restored by {2} points.", newpkmn.name, hpgain))
              screen.scene.pbRefresh
            end
            break if pkmn.hp <= amt
          end
          screen.scene.pbSelect(old_party_idx)
          screen.scene.pbRefresh
		#-----------------------------------------------------------------------
		# Performs HM and other field skill effects.
		#-----------------------------------------------------------------------
        else
          if pbCanUseHiddenMove?(pkmn, skills[command])
            if pbConfirmUseHiddenMove(pkmn, skills[command])
              screen.scene.pbEndScene
              if skills[command] == :FLY
                new_scene = PokemonRegionMap_Scene.new(-1, false)
                new_screen = PokemonRegionMapScreen.new(new_scene)
                ret = new_screen.pbStartFlyScreen
                if ret
                  $game_temp.fly_destination = ret
                  ret = [pkmn, skills[command]]
				  break
                end
                screen.scene.pbStartScene(
                  party, (party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel.")
                )
                break
              end
              ret = [pkmn, skills[command]]
            end
			break if ret
          end
        end
      end
    end
	next ret
  }
})


#===============================================================================
# Ready Menu compatibility.
#===============================================================================
def pbUseKeyItem
  real_moves = []
  # Adds available HM Skills.
  Settings::HM_SKILLS.each do |skill|
    next if !GameData::Move.exists?(skill)
	next if !HiddenMoveHandlers.hasHandler(skill)
    $player.party.each_with_index do |pkmn, i|
      next if pkmn.egg?
	  next if !pkmn.species_data.has_skill?(skill) && !pkmn.hasMove?(skill)
      if Settings::HM_SKILLS_REQUIRE_BADGE
	    badge = pbBadgeFromSkill(skill)
		next if badge > 0 && !pbCheckHiddenMoveBadge(badge, false)
	  end
      real_moves.push([skill, i]) if pbCanUseHiddenMove?(pkmn, skill, false)
	  break
    end
  end
  # Adds available Misc. Skills.
  Settings::MISC_SKILLS.each do |skill|
    next if !GameData::Move.exists?(skill)
	next if !HiddenMoveHandlers.hasHandler(skill)
    $player.party.each_with_index do |pkmn, i|
      next if pkmn.egg?
	  next if Settings::MISC_SKILLS_REQUIRE_MOVE && !self.hasMove?(skill)
	  next if !pkmn.species_data.has_skill?(skill) && !pkmn.hasMove?(skill)
      real_moves.push([skill, i]) if pbCanUseHiddenMove?(pkmn, skill, false)
	  break
    end
  end
  real_items = []
  $bag.registered_items.each do |i|
    itm = GameData::Item.get(i).id
    real_items.push(itm) if $bag.has?(itm)
  end
  if real_items.length == 0 && real_moves.length == 0
    pbMessage(_INTL("An item in the Bag can be registered to this key for instant use."))
  else
    $game_temp.in_menu = true
    $game_map.update
    sscene = PokemonReadyMenu_Scene.new
    sscreen = PokemonReadyMenu.new(sscene)
    sscreen.pbStartReadyMenu(real_moves, real_items)
    $game_temp.in_menu = false
  end
end


#===============================================================================
# Compiler
#===============================================================================
module Compiler
  module_function
  
  PLUGIN_FILES += ["Improved Field Skills"] 
  
  #-----------------------------------------------------------------------------
  # Compiles species field skills.
  #-----------------------------------------------------------------------------
  def compile_field_skills(path = "PBS/Plugins/Improved Field Skills/field_skills.txt")
    compile_pbs_file_message_start(path)
    File.open(path, "rb") { |f|
      FileLineData.file = path
      idx = 0
      pbEachFileSectionEx(f) { |contents, species_id|
        FileLineData.setSection(species_id, "header", nil)
        id = species_id.to_sym
        next if !GameData::Species.try_get(id)
        species = GameData::Species::DATA[id]
        key = "Skills"
        if nil_or_empty?(contents[key])
          contents[key] = nil
          next
        end
        FileLineData.setSection(species_id, key, contents[key])
        value = pbGetCsvRecord(contents[key], key, [0, "*e", :Move])
        value = nil if value.is_a?(Array) && value.length == 0
        contents[key] = value
        species.field_skills = contents[key]
      }
    }
    process_pbs_file_message_end
    GameData::Species.save
  end
  
  #-----------------------------------------------------------------------------
  # Writes the field_skills.txt PBS file.
  #-----------------------------------------------------------------------------
  def write_field_skills(path = "PBS/Plugins/Improved Field Skills/field_skills.txt")
    write_pbs_file_message_start(path)
    File.open(path, "wb") { |f|
      idx = 0
      GameData::Species.each do |s|
        echo "." if idx % 50 == 0
        idx += 1
        Graphics.update if idx % 250 == 0
        skills = []
        moves = s.get_family_moves
        Settings::HM_SKILLS.each { |skill| skills.push(skill) if moves.include?(skill) }
		Settings::MISC_SKILLS.each { |skill| skills.push(skill) if moves.include?(skill) }
		Settings::HEAL_SKILLS.each { |skill| skills.push(skill) if moves.include?(skill) }
        if !skills.empty?
          f.write("\#-------------------------------\r\n")
          f.write(sprintf("[%s]\r\n", s.id))
          f.write(sprintf("Skills = %s\r\n", skills.join(",")))
        end
      end
    }
    process_pbs_file_message_end
  end
end