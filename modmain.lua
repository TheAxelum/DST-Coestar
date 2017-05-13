PrefabFiles = {
	"coestar",
	"coehort",
	"coehat",
	"coellection",
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
	
	Asset( "SOUNDPACKAGE", "sound/theme.fev"),
	Asset( "SOUND", "sound/theme_bank01.fsb"),

}

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local THEME_MAX_VOLUME = 1.5

-- The character select screen lines
STRINGS.CHARACTER_TITLES.coestar = "The Collector"
STRINGS.CHARACTER_NAMES.coestar = "Coestar"
STRINGS.CHARACTER_DESCRIPTIONS.coestar = "*Has a vast Coellection\n*Wears a cool hat\n*Thinks dark thoughts"
STRINGS.CHARACTER_QUOTES.coestar = "\"Nooo! Fuck you! Fuck all of you! Fuck everyone! Fuck off!\""

-- Custom speech strings
STRINGS.CHARACTERS.COESTAR = require "speech_coestar"

-- The character's name as appears in-game 
STRINGS.NAMES.COESTAR = "Coestar"

AddMinimapAtlas("images/map_icons/coestar.xml")

-- Override default widget setup for containers so that Coehort (and potentially other custom items) work on cave servers
local containers = require("containers")
local oldwidgetsetup = containers.widgetsetup
local MyContainers = {
	coehort = "treasurechest",
	coellection = "krampus_sack"
}

containers.widgetsetup = function(container, prefab, data)
	prefab = MyContainers[prefab or container.inst.prefab] or prefab
	oldwidgetsetup(container, prefab, data)
end


AddPlayerPostInit(function(inst)
	local TheFocalPoint = GLOBAL.TheFocalPoint
	local TheWorld = GLOBAL.TheWorld
	
	if inst.prefab == "coestar" then
		inst._themevolume = THEME_MAX_VOLUME
		
		inst:DoPeriodicTask(.1, function(inst)
			--print(inst:HasTag("play_themesong"))
			if inst:HasTag("play_themesong") and not inst:HasTag("themesong_playing") then
				print("Playing Themesong")
				inst._themevolume = THEME_MAX_VOLUME
				TheFocalPoint.SoundEmitter:SetVolume("screamaday", inst._themevolume)
				TheFocalPoint.SoundEmitter:PlaySound("theme/sound/music", "screamaday")
				TheFocalPoint.SoundEmitter:SetVolume("screamaday", inst._themevolume)
				inst:AddTag("themesong_playing")
			end
		
			if not TheWorld.state.isfullmoon and not inst:HasTag("coestar_slowtime") then
				if inst._themevolume > 0 and inst:HasTag("themesong_playing") then
					inst._themevolume = inst._themevolume - (THEME_MAX_VOLUME / 100)
					print(inst._themevolume)
					TheFocalPoint.SoundEmitter:SetVolume("screamaday", inst._themevolume)
				elseif inst:HasTag("themesong_playing") then
					print("Killing Sound")
					TheFocalPoint.SoundEmitter:KillSound("screamaday")
					inst:RemoveTag("play_themesong")
					inst:RemoveTag("themesong_playing")
					inst._themevolume = THEME_MAX_VOLUME
				end
			end
		end)
	elseif inst:HasTag("player") then
		TheFocalPoint.SoundEmitter:SetVolume("screamaday", 0)
	end
end)

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
AddModCharacter("coestar", "MALE")

