require("stategraphs/commonstates")

local actionhandlers =
{

}

local events =
{
    
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),

    EventHandler("locomote", function(inst) 
        if not inst.sg:HasStateTag("busy") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("premoving")
                else
                    inst.sg:GoToState("idle")
                end
            end
        end
    end),

}

local function SoundPath(inst, event)
    local creature = "chester"

    return "dontstarve/creatures/" .. creature .. "/" .. event
end

local states =
{
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "die"))
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        end,
    },

    State{
        name = "premoving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        timeline=
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PushAnimation("walk_loop")
        end,

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        ontimeout = function(inst)
            --inst.sg:GoToState("taunt")
        end,

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            local animname = "idle"

            inst.AnimState:PlayAnimation("idle", true)
        end,
    },

	State{
        name = "open",
        tags = {"busy"},

        ontimeout = function(inst)
            --inst.sg:GoToState("close")
        end,

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
        end,
    },

	State{
        name = "close",
        tags = {"busy"},

        ontimeout = function(inst)
            --inst.sg:GoToState("idle")
        end,

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
        end,
		
		events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "hit",

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()            
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "hit_stunlock",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "hit_response"))
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

}

CommonStates.AddSleepStates(states,
{
    starttimeline = {
        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "fallAsleep")) end ),
    },
    sleeptimeline = 
    {
        TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "sleeping")) end ),
    },
    waketimeline = {
        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "wakeUp")) end ),
    },
})
CommonStates.AddFrozenStates(states)

return StateGraph("coehort", states, events, "idle", actionhandlers)
