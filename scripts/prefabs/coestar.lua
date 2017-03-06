
local MakePlayerCharacter = require "prefabs/player_common"

local COE_DEPRESSION_RATE = .01
local COE_DEPRESSION_TICK = 2
local COE_DEPRESSION_CHANGE_TICK = 10
local COE_DEPRESSION_MAX_RATE = 1

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}
local prefabs = {
	"coehort",
	"coehat"
}

-- Custom starting items
local start_inv = {
	"coehat"
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
		
		if data.depressionlevel then
			inst.depressionlevel = data.depressionlevel
			inst.depressiondir = data.depressiondir
			inst.depressiontarget = data.depressiontarget
			inst.depressed = data.depressed
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
		data.depressed = inst.depressed
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
	
	player.depressionlevel = 0
	player.depressiondir = 1
	player.depressiontarget = .85
	player.depressed = false
	
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
					sack.name = "The Coellection"
					sack.components.inventoryitem.cangoincontainer = true
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
	
	player:WatchWorldState("isnight", function(inst)
		
		-- This triggers when there is a full moon - it will start #ScreamADay
		inst:DoTaskInTime(1, function(inst)
			if TheWorld.state.isfullmoon then
				inst.components.talker:Say("Time for some #ScreamADay...")
				
				inst:DoTaskInTime(5, function(inst)
					inst.components.sanity:SetInducedInsanity("screamaday", true)
				end)
			end
		end)
	end)
	
	player:WatchWorldState("isday", function(inst)
		inst.components.sanity:SetInducedInsanity("screamaday", false)
	end)
	
	TheWorld:DoPeriodicTask(1, function()
		if TheWorld.state.isfullmoon then
			TheWorld.net.components.clock:OnUpdate(-.25)
		end
	end)
	
	player:DoPeriodicTask(COE_DEPRESSION_TICK, function(inst)
		if player.depressiontarget >= COE_DEPRESSION_MAX_RATE * .85 then
			inst.components.sanity:DoDelta(.01, true)
		else
			inst.components.sanity:DoDelta(-player.depressionlevel, true)
		end
	end)
	
	player:DoPeriodicTask(COE_DEPRESSION_CHANGE_TICK, function(inst)
		print("Depression: " .. tostring(inst.depressionlevel) .. " / " .. tostring(inst.depressiontarget))
		inst.depressionlevel = inst.depressionlevel + (COE_DEPRESSION_RATE * inst.depressiondir)
		
		if inst.depressionlevel >= inst.depressiontarget and inst.depressiondir > 0 then
			inst.depressiondir = -1
		elseif inst.depressionlevel <= 0 and inst.depressiondir < 0 then
			inst.depressionlevel = 0
			inst.depressiondir = 1
			inst.depressiontarget = math.random(15, COE_DEPRESSION_MAX_RATE * 100) / 100
			inst.depressed = true
			
			if inst.depressiontarget <= COE_DEPRESSION_MAX_RATE * .30 then
				inst.components.talker:Say("Things are looking up!", 2.5, true)
			elseif inst.depressiontarget <= COE_DEPRESSION_MAX_RATE * .60 then
				inst.components.talker:Say("Sorry guys, I'm just not feeling it today...", 2.5, true)
			elseif inst.depressiontarget < COE_DEPRESSION_MAX_RATE * .85 then
				inst.components.talker:Say("I want to feed chocolates to the dog that is my life.", 2.5, true)
			else
				inst.components.talker:Say("I feel fantasitic!", 2.5, true)
				inst.depressed = false
			end
		end
	end)
	
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
