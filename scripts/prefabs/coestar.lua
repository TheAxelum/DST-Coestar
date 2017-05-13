
local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}
local prefabs = {
	"coehort",
	"coehat",
	"coellection"
}

-- Custom starting items
local start_inv = {
	"coehat",
	"coellection"
}

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when reviving from ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "coestar_speed_mod", 1)

	if inst.hascoehort then
		inst.coehort:LinkToPlayer(inst)
	end
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
	player.components.health:SetMaxHealth(200)
	player.components.hunger:SetMax(200)
	player.components.sanity:SetMax(200)
	
	-- Damage multiplier (optional)
    player.components.combat.damagemultiplier = 1
	
	-- Hunger rate (optional)
	player.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE
	
	player:AddComponent("depression")
	
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
	

		
	if TheWorld:HasTag("coehortspawnlistener") ~= true then
		TheWorld:ListenForEvent("ms_playerjoined", SpawnCoehortFn) 
		TheWorld:AddTag("coehortspawnlistener")
	end
	
	
	player:WatchWorldState("isnight", function(inst)
		
		-- This triggers when there is a full moon - it will start #ScreamADay
		inst:DoTaskInTime(1, function(inst)
			if TheWorld.state.isfullmoon and not inst:HasTag("playerghost") then
				inst.components.talker:Say("Time for some #ScreamADay...")
				
				inst:DoTaskInTime(10, function(inst)
					inst.components.sanity:SetInducedInsanity("screamaday", true)
					TheWorld:AddTag("coestar_slowtime")
				end)
			end
		end)
		
		-- Fires after the full moon ends
		if TheWorld.state.isfullmoon and not inst:HasTag("playerghost") then
			local x, y, z = inst.Transform:GetWorldPosition()
			inst.components.sanity:DoDelta(50)
			
			local shadows = TheSim:FindEntities(x, y, z, 30,
				{ "_combat", "_health" },
				{ "character", "INLIMBO", "glommer", "companion" },
				{ "shadow", "shadowcreature" })
				
			for i, shadow in ipairs(shadows) do
				shadow.components.combat:DropTarget(false)
			end
		end
	end)
	
	player:WatchWorldState("isday", function(inst)
		TheWorld:RemoveTag("coestar_slowtime")
		inst:RemoveTag("play_themesong")
		
		inst.components.sanity:SetInducedInsanity("screamaday", false)
	end)
	
	if not TheWorld:HasTag("coestar_slowtime_listener") then
		TheWorld:AddTag("coestar_slowtime_listener")
		TheWorld:DoPeriodicTask(1, function()
			if TheWorld.state.isfullmoon and TheWorld:HasTag("coestar_slowtime") then
				TheWorld.net.components.clock:OnUpdate(-.50)
				player:AddTag("play_themesong")
			end
		end)
	end
	
	player.OnLoad = onload
    player.OnNewSpawn = onload
	player.OnDespawn = ondespawn
	player.OnSave = onsave
	
	
	
	player:ListenForEvent("equip", function(inst)
		local hat = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
		if hat and hat.prefab ~= "coehat" then
			inst.components.inventory:DropItem(hat)
			inst.components.inventory:Unequip(EQUIPSLOTS.HEAD, true)
			inst.components.talker:Say("I'm not wearing that crap.")
		end
	end)
	
end

return MakePlayerCharacter("coestar", prefabs, assets, common_postinit, master_postinit, start_inv)
