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
            TimeEvent(3*FRAMES, function(inst) end),
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
            TimeEvent(0*FRAMES, function(inst) end),
            TimeEvent(3*FRAMES, function(inst) end),
            TimeEvent(7*FRAMES, function(inst) end),
            TimeEvent(12*FRAMES, function(inst) end),
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
        tags = {"open", "busy"},

        ontimeout = function(inst)
            inst.sg:GoToState("close")
        end,

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,
    },

	State{
        name = "close",
        tags = {"busy"},

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
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
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

}

CommonStates.AddSleepStates(states,
{
    starttimeline = {
        TimeEvent(0*FRAMES, function(inst) end ),
    },
    sleeptimeline = 
    {
        TimeEvent(35*FRAMES, function(inst) end ),
    },
    waketimeline = {
        TimeEvent(0*FRAMES, function(inst) end ),
    },
})
CommonStates.AddFrozenStates(states)

return StateGraph("coehort", states, events, "idle", actionhandlers)
