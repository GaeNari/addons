--[[
	ActionSets, a module for saving and loading action slots
--]]

local AddonName, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local ActionSets = Dominos:NewModule('ActionSets', 'AceEvent-3.0', 'AceConsole-3.0'); Dominos.ActionSets = ActionSets

--constants
local ConfigVersion = 1
local MAX_BUTTONS = 120
local PLAYER_CLASS = (select(2, UnitClass('player')))

-- locals for speed
local strsplit = _G.strsplit
local strjoin = _G.strjoin
local GetActionInfo = _G.GetActionInfo
local HasAction = _G.HasAction
local SetAction = Addon.SetAction
local ClearMountCache = Addon.ClearMountCache


--[[ Events ]]--

function ActionSets:OnInitialize()
	self:InitDatabase()
end

function ActionSets:OnEnable()
	if self:IsActionSetProfileEmpty() then
		self:SaveActions()
	end

	self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
	self:RegisterEvent('COMPANION_LEARNED')
	self:RegisterEvent('COMPANION_UNLEARNED')
end

function ActionSets:OnNewProfile()
	self:SaveActions()
end

function ActionSets:OnProfileChanged()
	if self:IsActionSetProfileEmpty() then
		self:SaveActions()
	else
		self:RestoreActions()
	end
end

function ActionSets:OnProfileCopied()
	if self:IsActionSetProfileEmpty() then
		self:SaveActions()
	else
		self:RestoreActions()
	end
end

function ActionSets:OnProfileReset()
	self:SaveActions()
end

function ActionSets:ACTIONBAR_SLOT_CHANGED(event, slot)
	if slot ~= nil then
		self:SaveAction(slot, GetActionInfo(slot))
	end
end

function ActionSets:COMPANION_LEARNED(event, companionType)
	if companionType == nil or companionType == 'MOUNT' then
		ClearMountCache()
	end
end

function ActionSets:COMPANION_UNLEARNED()
	if companionType == nil or companionType == 'MOUNT' then
		ClearMountCache()
	end
end


--[[ DB Settings ]]--

function ActionSets:InitDatabase()
	local db = Dominos.db:RegisterNamespace('ActionSets', self:GetDatabaseDefaults())

	db.RegisterCallback(self, 'OnNewProfile')
	db.RegisterCallback(self, 'OnProfileChanged')
	db.RegisterCallback(self, 'OnProfileCopied')
	db.RegisterCallback(self, 'OnProfileReset')

	if db.global.version ~= ConfigVersion then
		self:UpgradeDatabase(db)
	end

	self.db = db
end

function ActionSets:GetDatabaseDefaults()
	return {
		profile = {
			[PLAYER_CLASS] = {
				actionSets = {},
			}
		}
	}
end

function ActionSets:UpgradeDatabase(db)
	db.global.version = ConfigVersion
end

function ActionSets:IsActionSetProfileEmpty()
	return not next(self:GetActionSetProfile())
end

function ActionSets:GetActionSetProfile()
	return self.db.profile[PLAYER_CLASS].actionSets
end


--[[ Storage API ]]--

function ActionSets:SaveActions()
	for slot = 1, MAX_BUTTONS do
		self:SaveAction(slot, GetActionInfo(slot))
	end
end

function ActionSets:SaveAction(slot, ...)
	local actionSets = self:GetActionSetProfile()

	if select('#', ...) > 0 then
		actionSets[slot] = strjoin('|', GetActionInfo(slot))
	else
		actionSets[slot] = nil
	end
end

function ActionSets:GetSavedActionInfo(slot)
	local info = self:GetActionSetProfile()[slot]

	if info then
		return strsplit('|', info)
	end
end

function ActionSets:RestoreActions()
	self:UnregisterEvent('ACTIONBAR_SLOT_CHANGED')

	for slot = 1, MAX_BUTTONS do
		self:RestoreAction(slot)
	end

	self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
end

function ActionSets:RestoreAction(slot)
	SetAction(slot, self:GetSavedActionInfo(slot))
end
