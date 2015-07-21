local AddonName, Addon = ...

local GetSpellBookItemInfo = _G.GetSpellBookItemInfo
local PickupSpellBookItem = _G.PickupSpellBookItem

--todo: cache this probably
local function getSpellBookIndex(flyoutId)
	local index  = 1
	local type, id
	
	repeat
		type, id = GetSpellBookItemInfo(index, 'spell')
		
		if type == 'FLYOUT' and flyoutId == id then
			return index
		end	
		
		index = index + 1
	until not (type and id)  
end

Addon.PickupFlyout = function(flyoutId)
	local index = getSpellBookIndex(flyoutId)
	
	if index then
		PickupSpellBookItem(index, 'spell')
		return true
	end	
end