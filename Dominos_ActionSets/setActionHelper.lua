local AddonName, Addon = ...

local tonumber = _G.tonumber
local ClearCursor = _G.ClearCursor
local PickupAction = _G.PickupAction
local PlaceAction = _G.PlaceAction
local PickupItem = _G.PickupItem
local PickupMacro = _G.PickupMacro
local PickupPetAction = _G.PickupPetAction
local PickupSpell = _G.PickupSpell
local PickupCompanion = _G.PickupCompanion
local PickupEquipmentSet = _G.PickupEquipmentSet
local PickupPet =  _G.C_PetJournal.PickupPet
local PickupFlyout = Addon.PickupFlyout
local PickupMount = Addon.PickupMount

local setActionHandlers = {
	clear = function(slot)
		if HasAction(slot) then
			PickupAction(slot)
			ClearCursor()
		end
	end,

	item = function(slot, itemId, ...)
		local currentType, currentItemId = GetActionInfo(slot)

		if not(currentType  == 'item' and currentItemId == itemId) then
			PickupItem(itemId)
			return true
		end
	end,
	
	flyout = function(slot, flyoutId)
		local currentType, currentFlyoutId = GetActionInfo(slot)

		if not(currentType  == 'flyout' and currentFlyoutId == flyoutId) then
			return PickupFlyout(flyoutId)
		end
	end,
	
	macro = function(slot, flyoutId)
		local currentType, currentFlyoutId = GetActionInfo(slot)

		if not(currentType  == 'macro' and currentFlyoutId == flyoutId) then
			PickupMacro(macroId)
			return true
		end
	end,	

	petaction = function(slot, petActionId)
		local currentType, currentPetActionId = GetActionInfo(slot)

		if not(currentType  == 'petaction' and currentPetActionId == petActionId) then
			PickupPetAction(petActionId)
			return true
		end
	end,

	spell = function(slot, spellId)
		local currentType, currentSpellId = GetActionInfo(slot)

		if not(currentType  == 'spell' and currentSpellId == spellId) then
			PickupSpell(spellId)
			return true
		end
	end,

	companion = function(slot, companionId, companionType)
		local currentType, currentCompanionId, currentCompanionType = GetActionInfo(slot)

		if not(currentType  == 'companion' and currentCompanionId == companionId and currentCompanionType == companionType) then
			PickupCompanion(companionType, companionId)
			return true
		end
	end,

	equipmentset = function(slot, setId)
		local currentType, currentSetId = GetActionInfo(slot)

		if not(currentType == 'equipmentset' and currentSetId == setId) then
			PickupEquipmentSet(setId)
			return true
		end
	end,

	summonmount = function(slot, mountId)
		local currentType, currentMountId = GetActionInfo(slot)

		if not(currentType == 'summonmount' and currentMountId == mountId) then
			return PickupMount(mountId)
		end
	end,

	summonpet = function(slot, petId)
		local currentType, currentPetId = GetActionInfo(slot)

		if not(currentType == 'summonpet' and currentPetId == petId) then
			PickupPet(petId)
			return true
		end
	end
}

Addon.SetAction = function(slot, type, id, subtype)
	local handler = setActionHandlers[type or 'clear']

	if handler then
		local id = tonumber(id) or id

		if handler(slot, id, subtype) then
			PlaceAction(slot)
		end
	else
		print(AddonName, 'Unhandled action type:', type)
	end
end
