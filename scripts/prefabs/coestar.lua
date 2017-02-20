
local MakePlayerCharacter = require "prefabs/player_common"

local COE_DEPRESSION_RATE = .01
local COE_DEPRESSION_TICK = 2
local COE_DEPRESSION_CHANGE_TICK = 10
local COE_DEPRESSION_MAX_RATE = 1

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}
local prefabs = {
	"coehort"
}

-- Custom starting items
local start_inv = {
}

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when reviving from ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "coestar_speed_mod", 1)
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
   inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "coestar_speed_mod")
end

-- When loading or spawning the character
local function onload(inst, data)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
	
	if data then
		if data.coehort ~= nil and inst.coehort == nil then
			local coehort = SpawnSaveRecord(data.coehort)
			if coehort ~= nil then
				coehort:LinkToPlayer(inst)
			end
		end
		
		if data.hascoehort then
			inst.hascoehort = data.hascoehort
		end
		
		if data.hascoellection then
			inst.hascoellection = data.hascoellection
		end
		
		if data.depressionlevel then
			inst.depressionlevel = data.depressionlevel
			inst.depressiondir = data.depressiondir
			inst.depressiontarget = data.depressiontarget
		end
	end
end

local function onsave(inst, data)
    if inst.coehort ~= nil and inst.coehort.components.health and inst.coehort.components.health:IsDead() == false then
        data.coehort = inst.coehort:GetSaveRecord()
    end
	
	if inst.hascoehort then
		data.hascoehort = inst.hascoehort
	end
	
	if inst.hascoellection then
		data.hascoellection = inst.hascoellection
	end
	
	if inst.depressionlevel then
		data.depressionlevel = inst.depressionlevel
		data.depressiondir = inst.depressiondir
		data.depressiontarget = inst.depressiontarget
	end
end

local function ondespawn(inst)
	if inst.hascoehort ~= nil then
        inst.coehort.components.health:SetInvincible(true)
		inst.coehort.AnimState:PlayAnimation("action")
        inst.coehort:DoTaskInTime(2, inst.coehort.Remove)
    end
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst) 
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "coestar.tex" )
end

-- This initializes for the server only. Components are added here.
local master_postinit = function(player)
	-- choose which sounds this character will play
	player.soundsname = "wolfgang"
	
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    --inst.talker_path_override = "dontstarve_DLC001/characters/"
	
	-- Stats	
	player.components.health:SetMaxHealth(150)
	player.components.hunger:SetMax(200)
	player.components.sanity:SetMax(200)
	
	player.depressionlevel = 0
	player.depressiondir = 1
	player.depressiontarget = .85
	
	-- Damage multiplier (optional)
    player.components.combat.damagemultiplier = 1
	
	-- Hunger rate (optional)
	player.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE
	
	-- Spawn coehort if he doesn't exist
	local SpawnCoehortFn = function(world, player)
		if player then
			player:DoTaskInTime(1,function(player)
				if player.prefab == "coestar" and player.hascoehort ~= true then
					player.hascoehort = true
					local coehort = SpawnPrefab("coehort")
					local x,y,z = player.Transform:GetWorldPosition()
					coehort.Transform:SetPosition(x,y,z)
					coehort:LinkToPlayer(player)
				end
			end)
		end
	end
	
	-- One time spawn of a krampus sack at Coe's feet when joining the game
	local SpawnCoellectionFn = function(world, player)
		if player then
			player:DoTaskInTime(1,function(player)
				if player.prefab == "coestar" and player.hascoellection ~= true then
					player.hascoellection = true
					local sack = SpawnPrefab("krampus_sack")
					local x,y,z = player.Transform:GetWorldPosition()
					sack.Transform:SetPosition(x,y,z)
					player.components.inventory:GiveItem(sack)
				end
			end)
		end
	end
		
	if TheWorld:HasTag("coehortspawnlistener") ~= true then
		TheWorld:ListenForEvent("ms_playerjoined", SpawnCoehortFn) 
		TheWorld:AddTag("coehortspawnlistener")
	end
	
	if TheWorld:HasTag("coellectiontspawnlistener") ~= true then
		TheWorld:ListenForEvent("ms_playerjoined", SpawnCoellectionFn) 
		TheWorld:AddTag("coellectiontspawnlistener")
	end
	
	player:DoPeriodicTask(COE_DEPRESSION_TICK, function(inst)
		if player.depressiontarget >= COE_DEPRESSION_MAX_RATE * .85 then
			inst.components.sanity:DoDelta(.01, true)
		else
			inst.components.sanity:DoDelta(-player.depressionlevel, true)
		end
	end)
	
	player:DoPeriodicTask(COE_DEPRESSION_CHANGE_TICK, function(inst)
		print("Depression: " .. tostring(player.depressionlevel) .. " / " .. tostring(player.depressiontarget))
		player.depressionlevel = player.depressionlevel + (COE_DEPRESSION_RATE * player.depressiondir)
		
		if player.depressionlevel >= player.depressiontarget and player.depressiondir > 0 then
			player.depressiondir = -1
		elseif player.depressionlevel <= 0 and player.depressiondir < 0 then
			player.depressionlevel = 0
			player.depressiondir = 1
			player.depressiontarget = math.random(15, COE_DEPRESSION_MAX_RATE * 100) / 100
			
			if player.depressiontarget <= COE_DEPRESSION_MAX_RATE * .30 then
				player.components.talker:Say("Things are looking up!", 2.5, true)
			elseif player.depressiontarget <= COE_DEPRESSION_MAX_RATE * .60 then
				player.components.talker:Say("Sorry guys, I'm just not feeling it today...", 2.5, true)
			elseif player.depressiontarget < COE_DEPRESSION_MAX_RATE * .85 then
				player.components.talker:Say("I want to feed chocolates to the dog that is my life.", 2.5, true)
			else
				player.components.talker:Say("I feel fantasitic!", 2.5, true)
			end
		end
	end)
	
	player.OnLoad = onload
    player.OnNewSpawn = onload
	player.OnDespawn = ondespawn
	player.OnSave = onsave
	
end

return MakePlayerCharacter("coestar", prefabs, assets, common_postinit, master_postinit, start_inv)
