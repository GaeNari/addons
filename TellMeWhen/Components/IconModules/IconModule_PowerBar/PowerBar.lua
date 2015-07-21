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
local LSM = LibStub("LibSharedMedia-3.0")
local _, pclass = UnitClass("Player")
local GetSpellInfo, UnitPower =
	  GetSpellInfo, UnitPower
local pairs, wipe, _G =
	  pairs, wipe, _G
local PowerBarColor = PowerBarColor

local defaultPowerTypes = {
	ROGUE		= SPELL_POWER_ENERGY,
	PRIEST		= SPELL_POWER_MANA,
	DRUID		= SPELL_POWER_MANA,
	WARRIOR		= SPELL_POWER_RAGE,
	MAGE		= SPELL_POWER_MANA,
	WARLOCK		= SPELL_POWER_MANA,
	PALADIN		= SPELL_POWER_MANA,
	SHAMAN		= SPELL_POWER_MANA,
	HUNTER		= SPELL_POWER_FOCUS,
	DEATHKNIGHT = SPELL_POWER_RUNIC_POWER,
	MONK 		= SPELL_POWER_ENERGY,
}
local defaultPowerType = defaultPowerTypes[pclass]

local PBarsToUpdate = {}

local PowerBar = TMW:NewClass("IconModule_PowerBar", "IconModule", "UpdateTableManager", "AceEvent-3.0", "AceTimer-3.0")
PowerBar:UpdateTable_Set(PBarsToUpdate)

PowerBar:RegisterAnchorableFrame("PowerBar")

function PowerBar:OnNewInstance(icon)
	local bar = CreateFrame("StatusBar", self:GetChildNameBase() .. "PowerBar", icon)
	self.bar = bar
	
	self.texture = bar:CreateTexture(nil, "OVERLAY")
	self.texture:SetAllPoints()
	bar:SetStatusBarTexture(self.texture)
	
	local colorinfo = PowerBarColor[defaultPowerType]
	if not colorinfo then
		error("No PowerBarColor was found for class " .. pclass .. "! Is the defaultPowerType for the class not defined?")
	end
	bar:SetStatusBarColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9)
	self.powerType = defaultPowerType
	
	self.Max = 1
	bar:SetMinMaxValues(0, self.Max)
	
	self.PBarOffs = 0
end

function PowerBar:OnEnable()
	local icon = self.icon
	local attributes = icon.attributes
	
	self.bar:Show()
	self.texture:SetTexture(LSM:Fetch("statusbar", TMW.db.profile.TextureName))
	
	self:SPELL(icon, attributes.spell)
end
function PowerBar:OnDisable()
	self.bar:Hide()
	self:UpdateTable_Unregister()
end

function PowerBar:OnUsed()
	PowerBar:RegisterEvent("SPELL_UPDATE_USABLE")
	PowerBar:RegisterEvent("UNIT_POWER_FREQUENT")
end
function PowerBar:OnUnused()
	PowerBar:UnregisterEvent("SPELL_UPDATE_USABLE")
	PowerBar:UnregisterEvent("UNIT_POWER_FREQUENT")
end


function PowerBar:SetSpell(spell)
	local bar = self.bar
	self.spell = spell
	self.spellLink = GetSpellLink(spell)

	
	if self.spellLink then
		-- We have to manually extract the spellID from the link because
		-- GetSpellInfo doesn't work for spell links since wotlk.
		self.spellID = self.spellLink:match("Hspell:(%d+)")
		
		self:UpdateCost()

		self:UpdateTable_Register()
		
		self:Update()

	-- Removes the bar from the update table. True is returned if it was in there.
	elseif self:UpdateTable_Unregister() then
		local value = self.Invert and self.Max or 0
		bar:SetValue(value)
		self.__value = value
		
		self:UpdateTable_Unregister()
	end
end





local costs = {
    [SPELL_POWER_MANA] = {
        MANA_COST_LARGE:gsub("%%s", "(.-)"), -- = "%s Mana";
        MANA_COST_LARGE_PER_TIME:gsub("%%s", "(.-)"), -- = "%s Mana, plus %s per sec";
        MANA_COST_LARGE_PER_TIME_NO_BASE:gsub("%%s", "(.-)"), -- = "%s Mana per sec";
        nil,
    },
    [SPELL_POWER_RAGE] = {
        RAGE_COST:gsub("%%d", "(%%d+)"), -- = "%d Rage";

        -- In deDE, this string is "%1$d Wut und %2$d pro Sek." wtf...
        GetLocale() == "deDE" and RAGE_COST_PER_TIME:gsub("%%%d%$d", "(%%d+)") or nil, -- = "%d Rage, plus %d per sec";
        GetLocale() ~= "deDE" and RAGE_COST_PER_TIME:gsub("%%d", "(%%d+)") or nil, -- = "%d Rage, plus %d per sec";


        RAGE_COST_PER_TIME_NO_BASE:gsub("%%d", "(%%d+)"), -- = "%d Rage per sec";
        nil,
    },
    [SPELL_POWER_FOCUS] = {
        FOCUS_COST:gsub("%%d", "(%%d+)"), -- = "%d Focus";
        FOCUS_COST_PER_TIME:gsub("%%d", "(%%d+)"), -- = "%d Focus, plus %d per sec";
        FOCUS_COST_PER_TIME_NO_BASE:gsub("%%d", "(%%d+)"), -- = "%d Focus per sec";
        nil,
    },
    [SPELL_POWER_ENERGY] = {
        ENERGY_COST:gsub("%%d", "(%%d+)"), -- = "%d Energy";
        ENERGY_COST_PER_TIME:gsub("%%d", "(%%d+)"), -- = "%d Energy, plus %d per sec";
        ENERGY_COST_PER_TIME_NO_BASE:gsub("%%d", "(%%d+)"), -- = "%d Energy per sec";
        nil,
    },
    [SPELL_POWER_RUNIC_POWER] = {
        RUNIC_POWER_COST:gsub("%%d", "(%%d+)"), -- = "%d Runic Power";
        RUNIC_POWER_COST_PER_TIME:gsub("%%d", "(%%d+)"), -- = "%d Runic Power, plus %d per sec";
        RUNIC_POWER_COST_PER_TIME_NO_BASE:gsub("%%d", "(%%d+)"), -- = "%d Runic Power per sec";
        nil,
    },
    [SPELL_POWER_SOUL_SHARDS] = {
        SOUL_SHARDS_COST:gsub("%%d", "(%%d+)"), -- = "%d Soul |4Shard:Shards;";
        SOUL_SHARDS_COST_PER_TIME:gsub("%%d", "(%%d+)"), -- = "%d Soul Shards, plus %d per sec";
        SOUL_SHARDS_COST_PER_TIME_NO_BASE:gsub("%%d", "(%%d+)"), -- = "%d Soul Shards per sec";
        nil,
    },
    [SPELL_POWER_HOLY_POWER] = {
        HOLY_POWER_COST:gsub("%%d", "(%%d+)"), -- = "%d Holy Power";
        nil,
    },
    [SPELL_POWER_CHI] = {
        CHI_COST:gsub("%%d", "(%%d+)"), -- = "%d Chi";
        CHI_COST_PER_TIME:gsub("%%d", "(%%d+)"), -- = "%d Chi, plus %d per sec";
        CHI_COST_PER_TIME_NO_BASE:gsub("%%d", "(%%d+)"), -- = "%d Chi per sec";
        nil,
    },
    [SPELL_POWER_SHADOW_ORBS] = {
        SHADOW_ORBS_COST, -- = "All Shadow Orbs";
        SHADOW_ORBS_COST_PER_TIME:gsub("%%d", "(%%d+)"), -- = "%d Shadow Orbs, plus %d per sec";
        SHADOW_ORBS_COST_PER_TIME_NO_BASE:gsub("%%d", "(%%d+)"), -- = "%d Shadow Orbs per sec";
        nil,
    },
    [SPELL_POWER_BURNING_EMBERS] = {
        BURNING_EMBERS_COST:gsub("%%d", "(%%d+)"), -- = "%d Burning |4Ember:Embers;";
        BURNING_EMBERS_COST_PER_TIME:gsub("%%d", "(%%d+)"), -- = "%d Burning Ember, plus%d per sec";
        BURNING_EMBERS_COST_PER_TIME_NO_BASE:gsub("%%d", "(%%d+)"), -- = "%d Burning Ember per sec";
        nil,
    },
    [SPELL_POWER_DEMONIC_FURY] = {
        DEMONIC_FURY_COST:gsub("%%d", "(%%d+)"), -- = "%d Demonic Fury";
        DEMONIC_FURY_COST_PER_TIME:gsub("%%d", "(%%d+)"), -- = "%d Demonic Fury, plus %d per sec";
        DEMONIC_FURY_COST_PER_TIME_NO_BASE:gsub("%%d", "(%%d+)"), -- = "%d Demonic Fury per sec";
        nil,
    },
}



local Parser, LT1, LT2 = TMW:GetParser()

function PowerBar:ScanForCost(spellID)
	if not spellID then
		return nil
	end

	Parser:SetOwner(UIParent, "ANCHOR_NONE")

	-- Prior to WoW 6.2, this function took a spell link and used Parser:SetHyperlink().
	-- In 6.2, setting a spell by hyperlink specifically omits the cost from the tooltip.
	-- In order to get the cost, we need to set it by ID.
	Parser:SetSpellByID(spellID)

	local costString = LT2:GetText()

	if not costString then
		-- Apparently this can happen sometimes.
		-- There are some obscure spells that it happens to all the time
		-- (because they really only have one line in their tooltip), but these spells aren't player spells.
		return 0, 0
	end

	for powerType, strings in pairs(costs) do
	    for _, string in pairs(strings) do
	        local amount = costString:match("^" .. string .. "$")

	        if amount then 
	            amount = amount:gsub("[^0-9]", "")
	            amount = tonumber(amount)

		        return amount, powerType
	        end
	    end
	end

	return 0, 0
end







function PowerBar:UpdateCost()
	local bar = self.bar
	local spell = self.spell
	
	if spell then
		local cost, powerType = self:ScanForCost(self.spellID)
		
		if cost then
		
			cost = powerType == SPELL_POWER_HOLY_POWER and 3 or cost or 0 -- holy power hack: always use a max of 3
			self.Max = cost
			bar:SetMinMaxValues(0, cost)
			self.__value = nil -- the displayed value might change when we change the max, so force an update
			
			powerType = powerType or defaultPowerType
			if powerType ~= self.powerType then
				local colorinfo = PowerBarColor[powerType] or PowerBarColor[defaultPowerType]
				
				bar:SetStatusBarColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9)
				self.powerType = powerType
			end
		end
	end
end

function PowerBar:Update(power, powerTypeNum)

	local bar = self.bar
	if not powerTypeNum then
		powerTypeNum = self.powerType
		power = UnitPower("player", powerTypeNum)
	end
	
	if powerTypeNum == self.powerType then
	
		local Max = self.Max
		local value

		if not self.Invert then
			value = Max - power + self.PBarOffs
		else
			value = power + self.PBarOffs
		end

		if value > Max then
			value = Max
		elseif value < 0 then
			value = 0
		end

		if self.__value ~= value then
			bar:SetValue(value)
			self.__value = value
		end
	end
end


function PowerBar:SPELL_UPDATE_USABLE()
	if TMW.Locked then
		for i = 1, #PBarsToUpdate do
			local Module = PBarsToUpdate[i]
			Module:UpdateCost()
		end
	end
end

function PowerBar:UNIT_POWER_FREQUENT(event, unit, powerType)
	if unit == "player" then
		local powerTypeNum = powerType and _G["SPELL_POWER_" .. powerType]
		local power = powerTypeNum and UnitPower("player", powerTypeNum)
		
		for i = 1, #PBarsToUpdate do
			local Module = PBarsToUpdate[i]
			Module:Update(power, powerTypeNum)
		end
	end
end


function PowerBar:SPELL(icon, spellChecked)
	self:SetSpell(spellChecked)
end
PowerBar:SetDataListner("SPELL")


TMW:RegisterCallback("TMW_LOCK_TOGGLED", function(event, Locked)
	if not Locked then
		PowerBar:UpdateTable_UnregisterAll()
	end
end)

