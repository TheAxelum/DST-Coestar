local function MakeHat(name)
    local fname = name.."hat"
    local symname = name.."hat"
    local prefabname = symname

    --If you want to use generic_perish to do more, it's still
    --commented in all the relevant places below in this file.
    --[[local function generic_perish(inst)
        inst:Remove()
    end]]

    local function onequip(inst, owner, fname_override)
        local build = fname_override or fname

        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("equipskinneditem", inst:GetSkinName())
            owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, "swap_hat", inst.GUID, build)
        else
            owner.AnimState:OverrideSymbol("swap_hat", build, "swap_hat")
        end
        owner.AnimState:Show("HAT")
        owner.AnimState:Show("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Hide("HEAD")
            owner.AnimState:Show("HEAD_HAT")
        end

		inst._owner = owner
    end

    local function onunequip(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("unequipskinneditem", inst:GetSkinName())
        end

        owner.AnimState:ClearOverrideSymbol("swap_hat")
        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
        end
		
		inst._owner = nil

    end

    local function simple(custom_init)
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(symname)
        inst.AnimState:SetBuild(fname)
        inst.AnimState:PlayAnimation("anim")

        inst:AddTag("hat")

        if custom_init ~= nil then
            custom_init(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")
        inst:AddComponent("inspectable")

        inst:AddComponent("tradable")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)

        MakeHauntableLaunch(inst)

        return inst
    end

    local function default()
        return simple()
    end

	local function onhit(inst, damage)
		inst.components.armor:SetPercent(100)
		if inst._owner ~= nil and inst._owner.components.hunger then
			inst._owner.components.hunger:DoDelta(-damage / 10)
		end
	end
	
    local function coestar_custom_init(inst)
		inst:AddTag("metal")
    end

    local function coestar()
        local inst = simple(coestar_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end
		
        inst:AddComponent("armor")
        inst.components.armor:InitCondition(TUNING.ARMORGRASS, TUNING.ARMORGRASS_ABSORPTION)
		
		inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
		
		inst:ListenForEvent("armordamaged", onhit)
		
        return inst
    end


    local fn = coestar
    local assets = { Asset("ANIM", "anim/"..fname..".zip") }
    local prefabs = nil


    return Prefab(prefabname, fn or default, assets, prefabs)
end


return  MakeHat("coe")
