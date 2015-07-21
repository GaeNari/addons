﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local SUG = TMW.SUG
local strlowerCache = TMW.strlowerCache

local _, pclass = UnitClass("Player")


local Module = SUG:NewModule("glyphs", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}

function Module:OnInitialize()
	for i = 1, GetNumGlyphs() do
		local type, _, _, _, glyphID, link = GetGlyphInfo(i)
		if type ~= "header" then
			local _, name = strmatch(link, "|Hglyph:(%d+)|h%[(.*)%]|h|r")
			name = strlowerCache[name]
			self.table[i] = name
		end
	end
end
function Module:Table_Get()
	return self.table
end
function Module:Entry_AddToList_1(f, index)
	local _, _, _, texture, glyphID, link = GetGlyphInfo(index)
	local _, name = strmatch(link, "|Hglyph:(%d+)|h%[(.*)%]|h|r")

	f.Name:SetText(name)
	f.ID:SetText(glyphID)

	f.tooltipmethod = "SetGlyphByID"
	f.tooltiparg = glyphID

	f.insert = SUG.inputType == "number" and glyphID or name
	f.insert2 = SUG.inputType ~= "number" and glyphID or name

	f.Icon:SetTexture(texture)
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName

	if SUG.inputType == "number" then
		local len = #SUG.lastName - 1
		local match = tonumber(SUG.lastName)
		for index, name in pairs(tbl) do
			local _, _, _, _, id = GetGlyphInfo(index)
			if min(id, floor(id / 10^(floor(log10(id)) - len))) == match then -- this looks like shit, but is is approx 300% more efficient than the below commented line
		--	if strfind(id, atBeginning) then
				suggestions[#suggestions + 1] = index
			end
		end
	else
		for index, name in pairs(tbl) do
			local matcher = lastName
			if #lastName < 2 then
				matcher = atBeginning
			end
			
			-- name here is Glyph of Fancy Spell
			if strfind(name, matcher) then
				suggestions[#suggestions + 1] = index
			else
			
				-- name here is Fancy Spell
				name = GetGlyphInfo(index)
				name = strlowerCache[name]
				if strfind(name, matcher) then
					suggestions[#suggestions + 1] = index
				end
			end
		end
	end
end
function Module.Sorter_Glyphs(a, b)
	if SUG.inputType == "number" then
		--sort by id
		return a < b
	else
		--sort by name
		local nameA, nameB = Module.table[a], Module.table[b]

		if nameA == nameB then
			--sort identical names by ID
			return a < b
		else
			--sort by name
			return nameA < nameB
		end
	end
end
function Module:Table_GetSorter()
	return self.Sorter_Glyphs
end



local Module = SUG:NewModule("stances", SUG:GetModule("spell"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]

Module.stances = {
	WARRIOR = {
		[2457] = 	GetSpellInfo(2457), 	-- Battle Stance
		[71] = 		GetSpellInfo(71),		-- Defensive Stance
		[2458] = 	GetSpellInfo(2458), 	-- Berserker Stance
		[156291] = 	GetSpellInfo(156291), 	-- Gladiator Stance
	},
	DRUID = {
		[5487] = 	GetSpellInfo(5487), 	-- Bear Form
		[768] = 	GetSpellInfo(768),		-- Cat Form
		[783] = 	GetSpellInfo(783),		-- Travel Form
		[24858] = 	GetSpellInfo(24858), 	-- Moonkin Form
		[33891] = 	GetSpellInfo(33891), 	-- Incarnation: Tree of Life
		[171745] = 	GetSpellInfo(171745), 	-- Claws of Shirvallah	
	},
	PRIEST = {
		[15473] = 	GetSpellInfo(15473), 	-- Shadowform	
	},
	ROGUE = {
		[1784] = 	GetSpellInfo(1784), 	-- Stealth	
	},
	DEATHKNIGHT = {
		[48263] = 	GetSpellInfo(48263), 	-- Blood Presence
		[48266] = 	GetSpellInfo(48266), 	-- Frost Presence
		[48265] = 	GetSpellInfo(48265), 	-- Unholy Presence	
	},
	PALADIN = {
		[105361] = 	GetSpellInfo(105361), 	-- Seal of Command
		[20165] = 	GetSpellInfo(20165), 	-- Seal of Insight
		[20164] = 	GetSpellInfo(20164),	-- Seal of Justice
		[20154] = 	GetSpellInfo(20154), 	-- Seal of Righteousness
		[31801] = 	GetSpellInfo(31801),	-- Seal of Truth
	},
	WARLOCK = {
		[103958] = 	GetSpellInfo(103958),	-- Metamorphosis
	},
	MONK = {
		[115069] = 	GetSpellInfo(115069),	-- Sturdy Ox
		[115070] = 	GetSpellInfo(115070),	-- Wise Serpent
		[103985] = 	GetSpellInfo(103985),	-- Fierce Tiger
		[154436] =  GetSpellInfo(154436),	-- Spirited Crane
	},
}
function Module:Table_Get()
	return self.stances[pclass]
end
function Module:Entry_AddToList_1(f, spellID)
	if spellID == 0 then
		f.Name:SetText(NONE)

		f.tooltiptitle = NONE

		f.insert = NONE

		f.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	else
		local name, _, tex = GetSpellInfo(spellID)

		f.Name:SetText(name)

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = spellID

		f.insert = name

		f.Icon:SetTexture(tex)
	end
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	local lastName = SUG.lastName

	for id, name in pairs(tbl) do
		if strfind(strlower(name), atBeginning) then
			suggestions[#suggestions + 1] = id
		end
	end
end
function Module:Table_GetSpecialSuggestions_1(suggestions, tbl, ...)
	local atBeginning = SUG.atBeginning
	if strfind(strlower(NONE), atBeginning) then
		suggestions[#suggestions + 1] = 0
	end
end



local Module = SUG:NewModule("talents", SUG:GetModule("spell"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}

function Module:OnInitialize()
	-- nothing
end
function Module:Table_Get()
	wipe(self.table)

	for spec = 1, MAX_TALENT_GROUPS do
		for tier = 1, MAX_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				local id, name = GetTalentInfo(tier, column, spec)
				
				local lower = name and strlowerCache[name]
				if lower then
					self.table[id] = lower
				end
			end
		end
	end

	return self.table
end
function Module:Table_GetSorter()
	return nil
end
function Module:Entry_AddToList_1(f, id)
	local id, name, iconTexture = GetTalentInfoByID(id) -- restore case

	f.Name:SetText(name)
	f.ID:SetText(id)

	f.tooltipmethod = "SetHyperlink"
	f.tooltiparg = GetTalentLink(id)

	f.insert = name
	f.insert2 = id

	f.Icon:SetTexture(iconTexture)
end
Module.Entry_Colorize_1 = TMW.NULLFUNC



local Module = SUG:NewModule("tracking", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]

local TrackingCache = {}
function Module:Table_Get()
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		TrackingCache[i] = strlower(name)
	end
	
	return TrackingCache
end
function Module:Table_GetSorter()
	return nil
end
function Module:Entry_AddToList_1(f, id)
	local name, texture = GetTrackingInfo(id)

	f.Name:SetText(name)
	f.ID:SetText(nil)

	f.tooltiptitle = name
	
	f.insert = name

	f.Icon:SetTexture(texture)
end



local Module = SUG:NewModule("blizzequipset", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]

local EquipSetCache = {}
function Module:Table_Get()
	for i = 1, GetNumEquipmentSets() do
		local name, icon = GetEquipmentSetInfo(i)

		EquipSetCache[i] = strlower(name)
	end
	
	return EquipSetCache
end
function Module:Table_GetSorter()
	return nil
end
function Module:Entry_AddToList_1(f, id)
	local name, icon = GetEquipmentSetInfo(id)

	f.Name:SetText(name)
	f.ID:SetText(nil)

	f.tooltipmethod = "SetEquipmentSet"
	f.tooltiparg = name

	f.insert = name

	f.Icon:SetTexture(icon)
end



