require "prefabutil"
local brain = require "brains/coehortbrain"

local WAKE_TO_FOLLOW_DISTANCE = 14
local SLEEP_NEAR_LEADER_DISTANCE = 7
local COLOR_TWEEN_SPEED = 2
local COEHORT_LIGHT_RADIUS = 8

local assets =
{
    Asset("ANIM", "anim/ui_chester_shadow_3x4.zip"),
    Asset("ANIM", "anim/ui_chest_3x3.zip"),

    Asset("ANIM", "anim/chester.zip"),
    Asset("ANIM", "anim/chester_build.zip"),
    Asset("ANIM", "anim/chester_shadow_build.zip"),
    Asset("ANIM", "anim/chester_snow_build.zip"),

    Asset("SOUND", "sound/chester.fsb"),

    Asset("MINIMAP_IMAGE", "chester"),
    Asset("MINIMAP_IMAGE", "chestershadow"),
    Asset("MINIMAP_IMAGE", "chestersnow"),
	
	Asset("ANIM", "anim/coehort.zip"),
}

local prefabs =
{
    "chesterlight",
    "chester_transform_fx",
    "globalmapiconunderfog",
}

local sounds =
{
    hurt = "dontstarve/creatures/chester/hurt",
    pant = "dontstarve/creatures/chester/pant",
    death = "dontstarve/creatures/chester/death",
    open = "dontstarve/creatures/chester/open",
    close = "dontstarve/creatures/chester/close",
    pop = "dontstarve/creatures/chester/pop",
    boing = "dontstarve/creatures/chester/boing",
    lick = "dontstarve/creatures/chester/lick",
}

local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst) or not inst._isnight
end

local function ShouldSleep(inst)
    --print(inst, "ShouldSleep", DefaultSleepTest(inst), not inst.sg:HasStateTag("open"), inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
    return DefaultSleepTest(inst) and inst._isnight and not inst.sg:HasStateTag("open") and not TheWorld.state.isfullmoon
end

local function ShouldKeepTarget()
    return false -- chester can't attack, and won't sleep if he has a target
end

local function OnOpen(inst)
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("open")
    end
end

local function OnClose(inst)
    if not inst.components.health:IsDead() and inst.sg.currentstate.name ~= "transition" then
        inst.sg:GoToState("close")
    end
end

local function OnSave(inst, data)

end

local function OnHaunt(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        inst.components.hauntable.panic = true
        inst.components.hauntable.panictimer = TUNING.HAUNT_PANIC_TIME_SMALL
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function LinkToPlayer(inst, player)
    inst.persists = false
    inst._playerlink = player
    player.coehort = inst
	player.components.leader:AddFollower(inst, true)  	
end

local function TweenBlue(inst)
	inst.components.colourtweener:StartTween({.0828, .4020, 1, 1}, COLOR_TWEEN_SPEED, function()
		inst:DoTaskInTime(1, function()
			inst:PushEvent("tween_blue_end")
		end)
	end)
end

local function TweenPink(inst)
	inst.components.colourtweener:StartTween({.4349, .2442 , .3209, 1}, COLOR_TWEEN_SPEED, function()
		inst:DoTaskInTime(1, function()
			inst:PushEvent("tween_pink_end")
		end)		
	end)
end

local function MaxLightRadius(inst)
	if inst._playerlink then
		local depression = inst._playerlink.depressiontarget
		if TheWorld.state.isfullmoon or not inst._playerlink.depressed then
			depression = 2
		end
		
		print(COEHORT_LIGHT_RADIUS * math.abs(1 - depression))
		
		return (COEHORT_LIGHT_RADIUS * math.abs(1 - depression))
	else
		return COEHORT_LIGHT_RADIUS
	end
end

local function create_chester()
    local inst = CreateEntity()

	inst.name = "Chestar"
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()

    MakeFlyingCharacterPhysics(inst, 1, .5)
    

    inst:AddTag("companion")
    inst:AddTag("scarytoprey")
    inst:AddTag("notraptrigger")
    inst:AddTag("noauradamage")
	inst:AddTag("notarget")

    inst.MiniMapEntity:SetIcon("chester.png")
    inst.MiniMapEntity:SetCanUseCache(false)

    inst.AnimState:SetBank("coehort")
    inst.AnimState:SetBuild("coehort")

    inst.DynamicShadow:SetSize(2, 1.5)

    inst.Transform:SetFourFaced()

    inst.entity:SetPristine()
	
	inst._isnight = false
	inst._lightrad = MaxLightRadius(inst)
	
	inst.entity:AddLight()
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(inst._lightrad)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(1, 1, 1)
	
	inst.Light:Enable(true)

    if not TheWorld.ismastersim then
        return inst
    end
	
    ------------------------------------------
	
	inst:DoPeriodicTask(.1, function()
		inst.Light:SetColour(inst.AnimState:GetMultColour())
		
		if inst._isnight and inst._lightrad > 0 then
			inst._lightrad = inst._lightrad - .01
		elseif not inst._isnight and inst._lightrad < MaxLightRadius(inst) then
			inst._lightrad = MaxLightRadius(inst)
		end
		
		inst.Light:SetRadius(inst._lightrad)
	end)
	
	inst:WatchWorldState("isday", function()
		inst._isnight = false
	end, TheWorld)
	
	inst:WatchWorldState("isnight", function()
		inst._isnight = true
	end, TheWorld)
	
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "chester_body"
    inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

    inst:AddComponent("health")
	inst.components.health:SetInvincible(true)
    inst.components.health:SetMaxHealth(TUNING.CHESTER_HEALTH)
    inst.components.health:StartRegen(TUNING.CHESTER_HEALTH_REGEN_AMOUNT, TUNING.CHESTER_HEALTH_REGEN_PERIOD)

    inst:AddComponent("inspectable")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED + 1
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED + 1

    inst:AddComponent("follower")

    inst:AddComponent("knownlocations")

    MakeSmallBurnableCharacter(inst, "chester_body")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("treasurechest")
	inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)
	
	inst:AddComponent("colourtweener")
	inst.AnimState:SetMultColour(.0828, .4020, .5152, 1)
	inst.AnimState:SetLightOverride(3)
	inst:ListenForEvent("tween_blue_end", TweenPink)
	inst:ListenForEvent("tween_pink_end", TweenBlue)
	
	TweenPink(inst)

    MakeHauntableDropFirstItem(inst)
    AddHauntableCustomReaction(inst, OnHaunt, false, false, true)

    inst.sounds = sounds

    inst:SetStateGraph("SGcoehort")
    inst.sg:GoToState("idle")

    inst:SetBrain(brain)
	
	inst.LinkToPlayer = LinkToPlayer

    inst.OnSave = OnSave
    --inst.OnPreLoad = OnPreLoad

    return inst
end

return Prefab("coehort", create_chester, assets, prefabs)
