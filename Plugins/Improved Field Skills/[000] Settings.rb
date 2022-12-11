module Settings
  #-----------------------------------------------------------------------------
  # Field Skills that require badges to use.
  #-----------------------------------------------------------------------------
  HM_SKILLS    = [:CUT,         # HM01
                  :FLY,         # HM02
                  :SURF,        # HM03
                  :STRENGTH,    # HM04
                  :WATERFALL,   # HM05
                  :DIVE,        # HM06
                  :FLASH,       # Legacy HM
                  :ROCKSMASH,   # Legacy HM
                 ]
                 
  #-----------------------------------------------------------------------------
  # Field Skills that don't require badges to use.
  #-----------------------------------------------------------------------------
  MISC_SKILLS  = [:WHIRLPOOL,   # Legacy HM (Not implemented in Essentials)
                  :DEFOG,       # Legacy HM (Not implemented in Essentials)
                  :ROCKCLIMB,   # Legacy HM (Not implemented in Essentials)
                  :DIG,         # Field Move
                  :TELEPORT,    # Field Move
                  :SWEETSCENT,  # Field Move
                  :HEADBUTT,    # Field Move
                  :SECRETPOWER, # Field Move (Not implemented in Essentials)
                 ]
                 
  #-----------------------------------------------------------------------------
  # Moves that are used to heal party HP. Any move added here will function as
  # a healing field skill.
  #-----------------------------------------------------------------------------
  HEAL_SKILLS  = [:SOFTBOILED, 
                  :MILKDRINK
                 ]
                 
  #-----------------------------------------------------------------------------
  # Toggles whether HM_SKILLS that have badge requirements should be hidden 
  # in the party menu if the appropriate badges for unlocking that Field Skill
  # have not yet been acquired.
  #-----------------------------------------------------------------------------
  HM_SKILLS_REQUIRE_BADGE = false
  
  #-----------------------------------------------------------------------------
  # Toggles whether or not MISC_SKILLS require the Pokemon to know the move for
  # that skill to appear in the menu.
  #-----------------------------------------------------------------------------
  MISC_SKILLS_REQUIRE_MOVE = false
  
  #-----------------------------------------------------------------------------
  # Toggles whether or not HEAL_SKILLS require the Pokemon to know the move for
  # that skill to appear in the menu.
  #-----------------------------------------------------------------------------
  HEAL_SKILLS_REQUIRE_MOVE = true
end