local preNpcCollision = {}

local alertSpecs = require("src_eevee.items.trinkets.alertSpecs")
local leafBlade = require("src_eevee.attacks.leafeon.leafBlade")

function preNpcCollision:main(npc, collider)
	if collider.Type == EntityType.ENTITY_PLAYER and collider:ToPlayer() then
		local useItemFunctions = {
			alertSpecs:OnCollisionGreedEnemy(npc, collider),
			leafBlade:SlashCollidedEnemy(npc, collider),
		}
		for i = 1, #useItemFunctions do
			if useItemFunctions[i] ~= nil then return useItemFunctions[i] end
		end
	end
end

function preNpcCollision:init(EeveeReunited)
	EeveeReunited:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, preNpcCollision.main)
end

return preNpcCollision