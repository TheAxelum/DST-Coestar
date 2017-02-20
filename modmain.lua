PrefabFiles = {
	"coestar",
	"coehort",
	"coestar_none",
}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/coestar.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/coestar.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/coestar.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/coestar.xml" ),
	
    Asset( "IMAGE", "images/selectscreen_portraits/coestar_silho.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/coestar_silho.xml" ),

    Asset( "IMAGE", "bigportraits/coestar.tex" ),
    Asset( "ATLAS", "bigportraits/coestar.xml" ),
	
	Asset( "IMAGE", "images/map_icons/coestar.tex" ),
	Asset( "ATLAS", "images/map_icons/coestar.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_coestar.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_coestar.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_ghost_coestar.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_coestar.xml" ),
	
	Asset( "IMAGE", "images/avatars/self_inspect_coestar.tex" ),
    Asset( "ATLAS", "images/avatars/self_inspect_coestar.xml" ),
	
	Asset( "IMAGE", "images/names_coestar.tex" ),
    Asset( "ATLAS", "images/names_coestar.xml" ),
	
    Asset( "IMAGE", "bigportraits/coestar_none.tex" ),
    Asset( "ATLAS", "bigportraits/coestar_none.xml" ),

}

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS

-- The character select screen lines
STRINGS.CHARACTER_TITLES.coestar = "The Collector"
STRINGS.CHARACTER_NAMES.coestar = "Coestar"
STRINGS.CHARACTER_DESCRIPTIONS.coestar = "*Coecrates! They could contain anything!\n*Has a vast Coellection\n*Has a cool hat"
STRINGS.CHARACTER_QUOTES.coestar = "\"Nooo! Fuck you! Fuck all of you! Fuck everyone! Fuck off!\""

-- Custom speech strings
STRINGS.CHARACTERS.COESTAR = require "speech_coestar"

-- The character's name as appears in-game 
STRINGS.NAMES.COESTAR = "Coestar"

AddMinimapAtlas("images/map_icons/coestar.xml")

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
AddModCharacter("coestar", "MALE")

