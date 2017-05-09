local DEBUG = true
local DEPRESSION_RATE = .01
local DEPRESSION_TICK = 2
local DEPRESSION_CHANGE_TICK = 10
local DEPRESSION_MAX_RATE = 1

local function init(self)
	local player = self.inst
	
	if self.initialized then 
		return false
	end
	
	self.initialized = true
	
	player:DoPeriodicTask(DEPRESSION_TICK, function(inst)
		player:PushEvent("depressiontick", {max_rate = DEPRESSION_MAX_RATE})
	end)
	
	player:DoPeriodicTask(DEPRESSION_CHANGE_TICK, function(inst)
		if DEBUG then print("Depression: " .. tostring(inst.components.depression.level) .. " / " .. tostring(inst.components.depression.target)) end
		inst.components.depression.level = inst.components.depression.level + (DEPRESSION_RATE * inst.components.depression.dir)
		
		if inst.components.depression.level >= inst.components.depression.target and inst.components.depression.dir > 0 then
			inst.components.depression.dir = -1
		elseif inst.components.depression.level <= 0 and inst.components.depression.dir < 0 then
			inst.components.depression.level = 0
			inst.components.depression.dir = 1
			inst.components.depression.target = math.random(15, DEPRESSION_MAX_RATE * 100) / 100
			inst.components.depression.depressed = true
			
			if inst.components.depression.target <= DEPRESSION_MAX_RATE * .30 then
				inst.components.talker:Say("Things are looking up!", 2.5, true)
			elseif inst.components.depression.target <= DEPRESSION_MAX_RATE * .60 then
				inst.components.talker:Say("Sorry guys, I'm just not feeling it today...", 2.5, true)
			elseif inst.components.depression.target < DEPRESSION_MAX_RATE * .85 then
				inst.components.talker:Say("I want to feed chocolates to the dog that is my life.", 2.5, true)
			else
				inst.components.talker:Say("I feel fantasitic!", 2.5, true)
				inst.components.depression.depressed = false
			end
		end
	end)
	
	player:ListenForEvent("depressiontick", function(inst, data)
		if inst.components.depression.target >= data.max_rate * .85 then
			if DEBUG then print("Do happy tick") end
			
			inst.components.sanity:DoDelta(.01, true)
		else
			if DEBUG then print("Do depressed tick") end
			inst.components.sanity:DoDelta(-inst.components.depression.level, true)
		end
	end)
end

local Depression = Class(function(self, inst)
    self.inst = inst
    self.level = 0
	self.dir = 1
	self.target = .85
	self.depressed = false
	self.initialized = false


	self:OnLoad()
	
	--inst:DoTaskInTime(1, function() init(self) end)

    self.inst:StartUpdatingComponent(self)
end,
nil,
{
    
})

function Depression:OnSave()
    local data = {
        level = self.level,
        dir = self.dir,
		target = self.target,
		depressed = self.depressed
    }
	
	return data	
end

function Depression:OnLoad(data)

	if data then
	
		if data.level ~= nil then
			self.level = data.level
		end

		if data.dir ~= nil then
			self.dir = data.dir
		end
		
		if data.target ~= nil then
			self.target = data.target
		end
		
		if data.depressed ~=nil then
			self.depressed = data.depressed
		end
		
		print("Depression Loaded")
	end
	
	init(self)
end

return Depression