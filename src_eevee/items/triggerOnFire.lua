local triggerOnFire = {}

local weaponFire = {}

--What you want to trigger here
local function PostShotFunctions(weapon)
	local init = tostring(weapon.SpawnerEntity.InitSeed)
	local weaponFireData = weaponFire[init]
	weaponFireData.TotalShots = weaponFireData.TotalShots + 1
	triggerOnFire:PostShotItems(weaponFireData)
end

local function PostFireFunctions(weapon)
	local init = tostring(weapon.SpawnerEntity.InitSeed)
	local weaponFireData = weaponFire[init]

	weaponFireData.TotalFired = weaponFireData.TotalFired + 1
	triggerOnFire:PostFireItems(weaponFireData)
end

local function InitWeapon(weapon)
	local init = tostring(weapon.SpawnerEntity.InitSeed)

	if not weaponFire[init] and (weapon.SpawnerEntity:ToPlayer() or weapon.SpawnerEntity:ToFamiliar()) then
		weaponFire[init] = {
			Parent = weapon.SpawnerEntity:ToPlayer() or weapon.SpawnerEntity:ToFamiliar(),
			TotalFired = 0,
			TotalShots = 0,
			FirstWeaponEntity = weapon,
			LastWeaponEntity = weapon
		}
		PostFireFunctions(weapon)
	end
	local weaponFireData = weaponFire[init]

	if not weaponFireData then return end

	weaponFireData.LastWeaponEntity = weapon

	if weaponFireData.FirstWeaponEntity.FrameCount ~= weaponFireData.LastWeaponEntity.FrameCount then
		weaponFireData.FirstWeaponEntity = weapon
		PostFireFunctions(weapon)
	end
	PostShotFunctions(weapon)
end

local function EntTypeIsWeaponType(weapon, player)
	local validEnt = false

	if weapon.Type == EntityType.ENTITY_TEAR
		and (
		player:HasWeaponType(WeaponType.WEAPON_TEARS)
			or player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS)
		)
		or weapon.Type == EntityType.ENTITY_LASER
		and (
		player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE)
			or player:HasWeaponType(WeaponType.WEAPON_LASER)
			or player:HasWeaponType(WeaponType.WEAPON_TECH_X)
		)
		or weapon.Type == EntityType.ENTITY_KNIFE and player:HasWeaponType(WeaponType.WEAPON_KNIFE)
		or weapon.Type == EntityType.ENTITY_EFFECT and (weapon.Variant == EffectVariant.TARGET and player:HasWeaponType(WeaponType.WEAPON_ROCKETS))
		or weapon.Type == EntityType.ENTITY_BOMBDROP and weapon.IsFetus
	then
		validEnt = true
	end

	return validEnt
end

local function IsFirstWeapon(weapon)
	local init = tostring(weapon.SpawnerEntity.InitSeed)
	local weaponFireData = weaponFire[init]
	local isFirst = false

	if weaponFireData
		and weaponFireData.LastWeaponEntity
		and weaponFireData.LastWeaponEntity.InitSeed == weapon.InitSeed
	then
		isFirst = true
	end

	return isFirst
end

--Knife Init, Bomb Init, Effect Init, Laser Init, and PostFireTear
function triggerOnFire:OnWeaponInit(weapon)
	if VeeHelper.EntitySpawnedByPlayer(weapon, true) then
		local player = weapon.SpawnerEntity:ToPlayer() or weapon.SpawnerEntity:ToFamiliar().Player

		if EntTypeIsWeaponType(weapon, player) then
			InitWeapon(weapon)
		end
	end
end

function triggerOnFire:OnLaserUpdate(laser)
	if IsFirstWeapon(laser)
		and laser.Timeout > 0
		and laser.SubType == LaserSubType.LASER_SUBTYPE_LINEAR
	then
		PostFireFunctions(laser)
		PostShotFunctions(laser)
	end
end

function triggerOnFire:OnTargetEffectUpdate(target)
	if IsFirstWeapon(target)
		and target.FrameCount % 10 == 0 --Doesn't trigger all 50 frames of its lifetime, instead only up to 5 times.
	then
		PostFireFunctions(target)
		PostShotFunctions(target)
	end
end

function triggerOnFire:OnKnifeUpdate(knife)
	local data = knife:GetData()

	if IsFirstWeapon(knife) then
		if knife:IsFlying() and not data.KnifeFired then
			data.KnifeFired = true
			PostFireFunctions(knife)
			PostShotFunctions(knife)
		elseif not knife:IsFlying() and data.KnifeFired then
			data.KnifeFired = false
		end
	end
end

function triggerOnFire:ResetOnGameStart()
	weaponFire = {}
end

---------------------
--  ON FIRE ITEMS  --
---------------------

function triggerOnFire:Tech05(player)
	local tech05Delay = 2
	local playerType = player:GetPlayerType()
	local weaponFireData = player:GetData()

	if player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_5)
		and playerType == EEVEEMOD.PlayerType.EEVEE
		and not player:CanShoot()
		and player:GetFireDirection() ~= Direction.NO_DIRECTION
	then

		if not weaponFireData.EeveeTech05Timer then
			weaponFireData.EeveeTech05Timer = tech05Delay
		elseif weaponFireData.EeveeTech05Timer > 0 then
			weaponFireData.EeveeTech05Timer = weaponFireData.EeveeTech05Timer - 1
		else
			if EEVEEMOD.RandomNum(6) == 6 then
				local laser = player:FireTechLaser(player.Position, LaserOffset.LASER_TECH5_OFFSET, VeeHelper.GetIsaacShootingDirection(player, player.Position), false, false, player, 1)
				local weaponFireDataLaser = laser:GetData()
				weaponFireDataLaser.EeveeTech05Laser = true
			end
			weaponFireData.EeveeTech05Timer = tech05Delay
		end
	end
end

function triggerOnFire:Tech05StayOnPlayer(laser)
	local weaponFireDataLaser = laser:GetData()

	if weaponFireDataLaser.EeveeTech05Laser
		and laser.SpawnerEntity then
		local player = laser.SpawnerEntity:ToPlayer()
		laser.Position = (player.Position + VeeHelper.GetIsaacShootingDirection(player):Resized(20))
	end
end

function triggerOnFire:DeadTooth(player)
	local playerType = player:GetPlayerType()
	local data = player:GetData()

	if player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_TOOTH)
		and playerType == EEVEEMOD.PlayerType.EEVEE
		and not player:CanShoot()
	then
		if data.CustomDeadTooth and data.CustomDeadTooth:Exists() then
			local sprite = data.CustomDeadTooth:GetSprite()
			data.CustomDeadTooth.Position = player.Position
			if sprite:IsFinished("Appear") then
				sprite:Play("Loop", true)
			end
			if sprite:IsFinished("Dissappear") then
				data.CustomDeadTooth:Remove()
				data.CustomDeadTooth = nil
			end
			if player:GetFireDirection() == Direction.NO_DIRECTION
				and not sprite:IsPlaying("Dissappear")
			then
				sprite:Play("Dissappear", true)
			end
		else
			if player:GetFireDirection() ~= Direction.NO_DIRECTION then
				data.CustomDeadTooth = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART_RING, 0, player.Position, Vector.Zero, player)
				data.CustomDeadTooth.SpriteScale = Vector(0.8, 0.8)
				data.CustomDeadTooth:GetSprite():Play("Appear", true)
			end
		end
	end
end

local function ImmaculateHeart(player, direction)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_IMMACULATE_HEART)
		or EEVEEMOD.RandomNum(4) ~= 4 then
		return
	end
	local tear = player:FireTear(player.Position, direction, false, true, false, player, 1):ToTear()
	tear:AddTearFlags(TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_ORBIT_ADVANCED)
	tear.Color = Color(1.5, 2.0, 2.0, 1, 0, 0, 0)
	tear.FallingSpeed = -6.5
end

local function EyeOfGreed(player, direction, weaponFireData)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_EYE_OF_GREED)
		or weaponFireData.TotalShots <= 0
		or weaponFireData.TotalShots % 20 ~= 0
	then
		return
	end
	local dmgMult = player:GetNumCoins() > 0 and 1.5 or 1
	local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.COIN, 0, player.Position, direction, player):ToTear()
	tear:AddTearFlags(player.TearFlags)
	if player:GetNumCoins() > 0 then
		tear:AddTearFlags(TearFlags.TEAR_COIN_DROP | TearFlags.TEAR_MIDAS)
	end
	tear.CollisionDamage = player.Damage * dmgMult
	EEVEEMOD.sfx:Play(SoundEffect.SOUND_CASH_REGISTER)
end

local function LeadPencil(player, direction, weaponFireData)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LEAD_PENCIL)
		or weaponFireData.TotalShots <= 0
		or weaponFireData.TotalShots % 15 ~= 0
	then
		return
	end

	for _ = 1, 12 do
		local angledDir = direction:Rotated(EEVEEMOD.RandomNum(-5, 5))
		local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, EEVEEMOD.TearVariant.SWIFT_BLOOD, 0, player.Position, angledDir, player):ToTear()
		tear.FallingSpeed = (EEVEEMOD.RandomNum(-9, 2) * 1) - EEVEEMOD.RandomFloat()
		tear.FallingAcceleration = 0.5
		tear:GetSprite():Play("BloodTear" .. VeeHelper.TearDamageToSizeAnim(tear), true)
	end
end

local function MomsWig(player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_WIG) then
		return
	end
	local luckChance = 5 + 95 * (1 / 2) ^ (10 - player.Luck) --Thanks Nine for this because I'm dumb at math (I'm smart I swear I just don't take things into consideration)
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_MOMS_WIG)
	local numSpiders = player:GetNumBlueSpiders()

	if numSpiders < 5 and rng:RandomInt(100) <= luckChance then
		local target = player.Position + Vector(-50, 50):Rotated(EEVEEMOD.RandomNum(360))
		player:ThrowBlueSpider(player.Position, target)
	end
end

local function GhostPepperBirdsEye(player, direction)
	local hasBirdsEye = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRDS_EYE)
	local hasGhostPepper = player:HasCollectible(CollectibleType.COLLECTIBLE_GHOST_PEPPER)
	if hasBirdsEye
		or hasGhostPepper
	then
		local rng = hasBirdsEye and player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BIRDS_EYE) or player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_GHOST_PEPPER)
		local fireToShoot = hasBirdsEye and EffectVariant.RED_CANDLE_FLAME or EffectVariant.BLUE_FLAME
		local baseChance = (hasBirdsEye and hasGhostPepper) and 8 or 12
		local luckChance = 1 / (baseChance - player.Luck)
		local luckCap = baseChance == 8 and 7 or 10
		luckChance = math.abs(player.Luck) <= luckCap and luckChance or (luckChance / math.abs(luckChance)) * luckCap
		luckChance = luckChance * 100
		if rng:RandomInt(100) <= luckChance then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, fireToShoot, 0, player.Position, direction, player)
		end
	end
end

function triggerOnFire:PostShotItems(weaponFireData)
	local player = weaponFireData.Parent:ToFamiliar() and weaponFireData.Parent.Player or weaponFireData.Parent
	local direction = VeeHelper.GetIsaacShootingDirection(player, player.Position):Resized(10)
	if player:GetPlayerType() ~= EEVEEMOD.PlayerType.EEVEE then return end
	EyeOfGreed(player, direction, weaponFireData)
	LeadPencil(player, direction, weaponFireData)
end

function triggerOnFire:PostFireItems(weaponFireData)
	local player = weaponFireData.Parent:ToFamiliar() and weaponFireData.Parent.Player or weaponFireData.Parent
	local direction = VeeHelper.GetIsaacShootingDirection(player, player.Position):Resized(10)
	if player:GetPlayerType() ~= EEVEEMOD.PlayerType.EEVEE then return end
	ImmaculateHeart(player, direction)
	MomsWig(player)
	GhostPepperBirdsEye(player, direction)
end

return triggerOnFire