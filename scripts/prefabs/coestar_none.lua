local assets =
{
	Asset( "ANIM", "anim/coestar.zip" ),
	Asset( "ANIM", "anim/ghost_coestar_build.zip" ),
}

local skins =
{
	normal_skin = "coestar",
	ghost_skin = "ghost_coestar_build",
}

local base_prefab = "coestar"

local tags = {"COESTAR", "CHARACTER"}

return CreatePrefabSkin("coestar_none",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	tags = tags,
	
	skip_item_gen = true,
	skip_giftable_gen = true,
})