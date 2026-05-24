-- Weapon customization logic (tints, attachments)
-- Intended to be called from server purchase events.

local function getWeaponHash(weaponName)
	return GetHashKey(weaponName)
end

local function notify(title, description, ntype)
	if not lib then return end
	lib.notify({ title = title, description = description, type = ntype or 'success' })
end

-- FiveM has component hashes for specific weapon classes; `DoesWeaponTakeWeaponComponent` tells us which are valid.
local Components = {
	flashlight = {
		`COMPONENT_AT_AR_FLSH`,
		`COMPONENT_AT_AR_FLSH_REH`,
		`COMPONENT_AT_PI_FLSH`,
		`COMPONENT_AT_PI_FLSH_02`,
		`COMPONENT_AT_PI_FLSH_03`,
	},
	suppressor_light = {
		`COMPONENT_AT_PI_SUPP`,
		`COMPONENT_AT_PI_SUPP_02`,
		`COMPONENT_CERAMICPISTOL_SUPP`,
		`COMPONENT_PISTOLXM3_SUPP`,
	},
	suppressor_heavy = {
		`COMPONENT_AT_AR_SUPP`,
		`COMPONENT_AT_AR_SUPP_02`,
		`COMPONENT_AT_SR_SUPP`,
		`COMPONENT_AT_SR_SUPP_03`,
	},
	grip = {
		`COMPONENT_AT_AR_AFGRIP`,
		`COMPONENT_AT_AR_AFGRIP_02`,
	},
	scope = {
		-- Macro
		`COMPONENT_AT_SCOPE_MACRO`,
		`COMPONENT_AT_SCOPE_MACRO_02`,
		`COMPONENT_AT_SCOPE_MACRO_MK2`,
		`COMPONENT_AT_SCOPE_MACRO_02_MK2`,
		`COMPONENT_AT_SCOPE_MACRO_02_SMG_MK2`,
		-- Small
		`COMPONENT_AT_SCOPE_SMALL`,
		`COMPONENT_AT_SCOPE_SMALL_02`,
		`COMPONENT_AT_SCOPE_SMALL_MK2`,
		`COMPONENT_AT_SCOPE_SMALL_SMG_MK2`,
		-- Medium
		`COMPONENT_AT_SCOPE_MEDIUM`,
		`COMPONENT_AT_SCOPE_MEDIUM_MK2`,
		-- Large
		`COMPONENT_AT_SCOPE_LARGE_MK2`,
		-- Advanced / max
		`COMPONENT_AT_SCOPE_MAX`,
		-- NV / thermal
		`COMPONENT_AT_SCOPE_NV`,
		`COMPONENT_AT_SCOPE_THERMAL`,
		-- Holo
		`COMPONENT_AT_PI_RAIL`,
		`COMPONENT_AT_PI_RAIL_02`,
		`COMPONENT_AT_SIGHTS`,
		`COMPONENT_AT_SIGHTS_SMG`,
	},
	clip_extended = {
		pistol = {
			`COMPONENT_APPISTOL_CLIP_02`,
			`COMPONENT_CERAMICPISTOL_CLIP_02`,
			`COMPONENT_COMBATPISTOL_CLIP_02`,
			`COMPONENT_HEAVYPISTOL_CLIP_02`,
			`COMPONENT_PISTOL_CLIP_02`,
			`COMPONENT_PISTOL_MK2_CLIP_02`,
			`COMPONENT_PISTOL50_CLIP_02`,
			`COMPONENT_SNSPISTOL_CLIP_02`,
			`COMPONENT_SNSPISTOL_MK2_CLIP_02`,
			`COMPONENT_VINTAGEPISTOL_CLIP_02`,
			`COMPONENT_TECPISTOL_CLIP_02`,
		},
		smg = {
			`COMPONENT_ASSAULTSMG_CLIP_02`,
			`COMPONENT_COMBATPDW_CLIP_02`,
			`COMPONENT_MACHINEPISTOL_CLIP_02`,
			`COMPONENT_MICROSMG_CLIP_02`,
			`COMPONENT_MINISMG_CLIP_02`,
			`COMPONENT_SMG_CLIP_02`,
			`COMPONENT_SMG_MK2_CLIP_02`,
		},
		shotgun = {
			`COMPONENT_ASSAULTSHOTGUN_CLIP_02`,
			`COMPONENT_HEAVYSHOTGUN_CLIP_02`,
		},
		rifle = {
			`COMPONENT_ADVANCEDRIFLE_CLIP_02`,
			`COMPONENT_ASSAULTRIFLE_CLIP_02`,
			`COMPONENT_ASSAULTRIFLE_MK2_CLIP_02`,
			`COMPONENT_BULLPUPRIFLE_CLIP_02`,
			`COMPONENT_BULLPUPRIFLE_MK2_CLIP_02`,
			`COMPONENT_CARBINERIFLE_CLIP_02`,
			`COMPONENT_CARBINERIFLE_MK2_CLIP_02`,
			`COMPONENT_COMPACTRIFLE_CLIP_02`,
			`COMPONENT_HEAVYRIFLE_CLIP_02`,
			`COMPONENT_MILITARYRIFLE_CLIP_02`,
			`COMPONENT_SPECIALCARBINE_CLIP_02`,
			`COMPONENT_SPECIALCARBINE_MK2_CLIP_02`,
			`COMPONENT_TACTICALRIFLE_CLIP_02`,
			`COMPONENT_BATTLERIFLE_CLIP_02`,
		},
		mg = {
			`COMPONENT_GUSENBERG_CLIP_02`,
			`COMPONENT_MG_CLIP_02`,
			`COMPONENT_COMBATMG_CLIP_02`,
			`COMPONENT_COMBATMG_MK2_CLIP_02`,
		},
		sniper = {
			`COMPONENT_HEAVYSNIPER_MK2_CLIP_02`,
			`COMPONENT_MARKSMANRIFLE_CLIP_02`,
			`COMPONENT_MARKSMANRIFLE_MK2_CLIP_02`,
		},
	},
}

local function getWeaponGroupForClip(weaponName)
	local name = tostring(weaponName):lower()

	if name:find('pistol') or name:find('snspistol') or name:find('revolver') or name:find('heavypistol') or name:find('vintagepistol') then
		return 'pistol'
	end

	if name:find('smg') or name:find('micro') or name:find('minismg') or name:find('machinepistol') or name:find('combatpdw') then
		return 'smg'
	end

	if name:find('shotgun') then
		return 'shotgun'
	end

	if name:find('mg') or name:find('minigun') or name:find('gusenberg') or name:find('combatmg') then
		return 'mg'
	end

	if name:find('sniper') or name:find('marksmanrifle') then
		return 'sniper'
	end

	-- Default to rifle/carbine style.
	return 'rifle'
end

local function tryGiveComponent(ped, weaponHash, componentList)
	for _, componentHash in ipairs(componentList) do
		if DoesWeaponTakeWeaponComponent(weaponHash, componentHash) and not HasPedGotWeaponComponent(ped, weaponHash, componentHash) then
			GiveWeaponComponentToPed(ped, weaponHash, componentHash)
			return true
		end
	end
	return false
end

RegisterNetEvent('phantom_weapons:client:applyTint', function(weaponName, tintId)
	local ped = PlayerPedId()
	local weaponHash = getWeaponHash(weaponName)

	if not HasPedGotWeapon(ped, weaponHash, false) then
		notify('Tint Failed', 'Equip the weapon before applying tint.', 'error')
		return
	end

	-- Ensure the tint applies to the current weapon state.
	SetCurrentPedWeapon(ped, weaponHash, true)
	SetPedWeaponTintIndex(ped, weaponHash, tintId)

	local tint = Config and Config.WeaponTints and Config.WeaponTints.colors and Config.WeaponTints.colors[tintId + 1]
	notify('Tint Applied', tint and tint.name or ('Tint #' .. tostring(tintId)), 'success')
end)

RegisterNetEvent('phantom_weapons:client:applyAttachment', function(weaponName, attachment)
	local ped = PlayerPedId()
	local weaponHash = getWeaponHash(weaponName)
	local name = tostring(attachment):lower()

	if not HasPedGotWeapon(ped, weaponHash, false) then
		notify('Attachment Failed', 'Equip the weapon before applying attachments.', 'error')
		return
	end

	SetCurrentPedWeapon(ped, weaponHash, true)

	local applied = false
	if name:find('clip') then
		-- This config has multiple clip variants, but the component data bundled with `ox_inventory` only includes extended clips.
		local group = getWeaponGroupForClip(weaponName)
		local clipList = Components.clip_extended[group] or Components.clip_extended.rifle
		applied = tryGiveComponent(ped, weaponHash, clipList)
	elseif name == 'suppressor' then
		applied = tryGiveComponent(ped, weaponHash, Components.suppressor_light)
		if not applied then
			applied = tryGiveComponent(ped, weaponHash, Components.suppressor_heavy)
		end
	elseif name == 'scope' then
		applied = tryGiveComponent(ped, weaponHash, Components.scope)
	elseif name == 'grip' then
		applied = tryGiveComponent(ped, weaponHash, Components.grip)
	elseif name == 'flashlight' then
		applied = tryGiveComponent(ped, weaponHash, Components.flashlight)
	elseif name == 'laser' then
		notify('Laser Not Available', 'Laser component mappings are not included in this setup.', 'error')
		return
	else
		notify('Attachment Unknown', ('No mapping for "%s".'):format(tostring(attachment)), 'error')
		return
	end

	if applied then
		notify('Attachment Added', tostring(attachment):gsub('_', ' '):upper(), 'success')
	else
		notify('Attachment Failed', 'This attachment is not valid for the selected weapon.', 'error')
	end
end)

