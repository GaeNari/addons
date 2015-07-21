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


---------- Libraries ----------
local LSM = LibStub("LibSharedMedia-3.0")
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local AceDB = LibStub("AceDB-3.0")

-- GLOBALS: LibStub
-- GLOBALS: TMWOptDB
-- GLOBALS: TELLMEWHEN_VERSION, TELLMEWHEN_VERSION_MINOR, TELLMEWHEN_VERSION_FULL, TELLMEWHEN_VERSIONNUMBER, TELLMEWHEN_MAXROWS
-- GLOBALS: NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR, INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED, SPELL_RECAST_TIME_MIN, SPELL_RECAST_TIME_SEC, NONE, SPELL_CAST_CHANNELED, NUM_BAG_SLOTS, CANCEL
-- GLOBALS: GameTooltip
-- GLOBALS: UIParent, WorldFrame, TellMeWhen_IconEditor, GameFontDisable, GameFontHighlight, CreateFrame, collectgarbage 
-- GLOBALS: PanelTemplates_TabResize, PanelTemplates_Tab_OnClick

---------- Upvalues ----------
local TMW = TMW
local L = TMW.L
local GetSpellInfo =
	  GetSpellInfo
local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, pcall, assert, rawget, rawset, unpack, select =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, getmetatable, setmetatable, pcall, assert, rawget, rawset, unpack, select
local strfind, strmatch, format, gsub, strsub, strtrim, strlen, strsplit, strlower, max, min, floor, ceil, log10 =
	  strfind, strmatch, format, gsub, strsub, strtrim, strlen, strsplit, strlower, max, min, floor, ceil, log10
local GetCursorPosition, GetCursorInfo, CursorHasSpell, CursorHasItem, ClearCursor =
	  GetCursorPosition, GetCursorInfo, CursorHasSpell, CursorHasItem, ClearCursor
local _G, bit, CopyTable, hooksecurefunc, IsAddOnLoaded, IsControlKeyDown, PlaySound =
	  _G, bit, CopyTable, hooksecurefunc, IsAddOnLoaded, IsControlKeyDown, PlaySound

local strlowerCache = TMW.strlowerCache
local GetSpellTexture = TMW.GetSpellTexture
local print = TMW.print
local Types = TMW.Types
local IE


---------- Locals ----------
local _, pclass = UnitClass("Player")
local tiptemp = {}
local get = TMW.get

---------- Globals ----------
--GLOBALS: BINDING_HEADER_TELLMEWHEN, BINDING_NAME_TELLMEWHEN_ICONEDITOR_UNDO, BINDING_NAME_TELLMEWHEN_ICONEDITOR_REDO
BINDING_HEADER_TELLMEWHEN = "TellMeWhen"
BINDING_NAME_TELLMEWHEN_ICONEDITOR_UNDO = L["UNDO_ICON"]
BINDING_NAME_TELLMEWHEN_ICONEDITOR_REDO = L["REDO_ICON"]


---------- Data ----------
local points = {
	TOPLEFT = L["TOPLEFT"],
	TOP = L["TOP"],
	TOPRIGHT = L["TOPRIGHT"],
	LEFT = L["LEFT"],
	CENTER = L["CENTER"],
	RIGHT = L["RIGHT"],
	BOTTOMLEFT = L["BOTTOMLEFT"],
	BOTTOM = L["BOTTOM"],
	BOTTOMRIGHT = L["BOTTOMRIGHT"],
} TMW.points = points

TMW.justifyPoints = {
	LEFT = L["LEFT"],
	CENTER = L["CENTER"],
	RIGHT = L["RIGHT"],
}
TMW.justifyVPoints = {
	TOP = L["TOP"],
	MIDDLE = L["CENTER"],
	BOTTOM = L["BOTTOM"],
}

TMW.operators = {
	{ tooltipText = L["CONDITIONPANEL_EQUALS"], 		value = "==", 	text = "==" },
	{ tooltipText = L["CONDITIONPANEL_NOTEQUAL"], 	 	value = "~=", 	text = "~=" },
	{ tooltipText = L["CONDITIONPANEL_LESS"], 			value = "<", 	text = "<" 	},
	{ tooltipText = L["CONDITIONPANEL_LESSEQUAL"], 		value = "<=", 	text = "<=" },
	{ tooltipText = L["CONDITIONPANEL_GREATER"], 		value = ">", 	text = ">" 	},
	{ tooltipText = L["CONDITIONPANEL_GREATEREQUAL"], 	value = ">=", 	text = ">=" },
}

TMW.EquivOriginalLookup = {}
TMW.EquivFullIDLookup = {}
TMW.EquivFullNameLookup = {}
TMW.EquivFirstIDLookup = {}
for category, b in pairs(TMW.OldBE) do
	for equiv, str in pairs(b) do
		TMW.EquivOriginalLookup[equiv] = str

		-- remove underscores
		str = gsub(str, "_", "")

		-- create the lookup tables first, so that we can have the first ID even if it will be turned into a name
		TMW.EquivFirstIDLookup[equiv] = strsplit(";", str) -- this is used to display them in the list (tooltip, name, id display)

		TMW.EquivFullIDLookup[equiv] = ";" .. str
		local tbl = TMW:SplitNames(str)
		for k, v in pairs(tbl) do
			tbl[k] = GetSpellInfo(v) or v
		end
		TMW.EquivFullNameLookup[equiv] = ";" .. table.concat(tbl, ";")
	end
end
for dispeltype, icon in pairs(TMW.DS) do
	TMW.EquivFirstIDLookup[dispeltype] = icon
end



---------- Miscellaneous ----------
TMW.Backupdb = CopyTable(TellMeWhenDB)
TMW.BackupDate = date("%I:%M:%S %p")

TMW.CI = setmetatable({}, {__index = function(tbl, k)
	if k == "ic" then
		return tbl.icon
	elseif k == "group" then
		return tbl.icon and tbl.icon.group
	elseif k == "ics" then
		return tbl.icon and tbl.icon:GetSettings()
	elseif k == "gs" then
		-- take no chances with errors occuring here
		return tbl.group and tbl.group:GetSettings()
	end
end}) local CI = TMW.CI		--current icon






-- ----------------------
-- WOW API HOOKS
-- ----------------------

function GameTooltip:TMW_SetEquiv(equiv)
	GameTooltip:AddLine(L[equiv], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	GameTooltip:AddLine(IE:Equiv_GenerateTips(equiv), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
end


-- GLOBALS: ChatEdit_InsertLink
TMW:NewClass("ChatEdit_InsertLink_Hook"){
	OnNewInstance = function(self, editbox, func)		
		TMW:ValidateType(2, "ChatEdit_InsertLink_Hook:New()", editbox, "frame")
		TMW:ValidateType(3, "ChatEdit_InsertLink_Hook:New()", func, "function")
		
		self.func = func
		self.editbox = editbox
	end,
	
	Call = function(self, text, linkType, linkData)
		if self.editbox:HasFocus() then
			return TMW.safecall(self.func, self, text, linkType, linkData)
		end
	end,
}

local old_ChatEdit_InsertLink = ChatEdit_InsertLink
local function hook_ChatEdit_InsertLink(text)	
	if type(text) ~= "string" then
		return false
	end
	
	local Type, data = strmatch(text, "|H(.-):(.-)|h")
	
	for _, instance in pairs(TMW.Classes.ChatEdit_InsertLink_Hook.instances) do
		local executionSuccess, insertResult = instance:Call(text, Type, data)
		if executionSuccess and insertResult then
			return insertResult
		end
	end
	
	return false
end

function ChatEdit_InsertLink(...)
	local executionSuccess, insertSuccess = TMW.safecall(hook_ChatEdit_InsertLink, ...)
	if executionSuccess and insertSuccess then
		return insertSuccess
	else
		return old_ChatEdit_InsertLink(...)
	end
end





-- ----------------------
-- GENERAL CONFIG FUNCTIONS
-- ----------------------

---------- Icon Utilities ----------
function TMW:GetIconMenuText(ics)
	local Type = ics.Type or ""
	local typeData = Types[Type]

	local text, tooltip, dontShorten = typeData:GetIconMenuText(ics)
	text = tostring(text)
	
	tooltip = tooltip or ""
	
	text = text == "" and (L["UNNAMED"] .. ((Type ~= "" and typeData and (" - " .. typeData.name) or ""))) or text
	local textshort = not dontShorten and strsub(text, 1, 40) or text

	if strlen(text) > 40 and not dontShorten then
		textshort = textshort .. "..."
	end

	tooltip =	tooltip ..
				((Type ~= "" and typeData.name) or "") ..
				((ics.Enabled and "") or "\r\n(" .. L["DISABLED"] .. ")")

	return text, textshort, tooltip
end

function TMW:GuessIconTexture(ics)
	local tex

	if ics.CustomTex then
		tex = TMW:GetTexturePathFromSetting(ics.CustomTex)
	end
	
	if not tex then
		tex = TMW.Types[ics.Type]:GuessIconTexture(ics)
	end
	
	if not tex then
		tex = "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	
	return tex
end

function TMW:PrepareIconSettingsForCopying(ics, gs)
	TMW:Fire("TMW_ICON_PREPARE_SETTINGS_FOR_COPY", ics, gs)
end

function TMW.IconsSort(a, b)
	local icon1, icon2 = _G[a], _G[b]
	local g1 = icon1.group:GetID()
	local g2 = icon2.group:GetID()
	if g1 ~= g2 then
		return g1 < g2
	else
		return icon1:GetID() < icon2:GetID()
	end
end



---------- Misc Utilities ----------
local ScrollContainerHook_Hide = function(c) c.ScrollFrame:Hide() end
local ScrollContainerHook_Show = function(c) c.ScrollFrame:Show() end
local ScrollContainerHook_OnSizeChanged = function(c) c.ScrollFrame:Show() end
function TMW:ConvertContainerToScrollFrame(container, exteriorScrollBarPosition, scrollBarXOffs, scrollBarSizeX, leftSide)
	
	local name = container:GetName() and container:GetName() .. "ScrollFrame"
	local ScrollFrame = CreateFrame("ScrollFrame", name, container:GetParent(), "TellMeWhen_ScrollFrameTemplate")
	
	-- Make the ScrollFrame clone the container's position and size
	local x, y = container:GetSize()
	ScrollFrame:SetSize(x, y)
	for i = 1, container:GetNumPoints() do
		ScrollFrame:SetPoint(container:GetPoint(i))
	end
	

	-- Make the container be the ScrollFrame's ScrollChild.
	-- Fix its size to take the full width.
	container:ClearAllPoints()
	ScrollFrame:SetScrollChild(container)
	container:SetSize(x, 1)
	
	local relPoint = leftSide and "LEFT" or "RIGHT"
	if exteriorScrollBarPosition then
		ScrollFrame.ScrollBar:SetPoint("LEFT", ScrollFrame, relPoint, scrollBarXOffs or 0, 0)
	else
		ScrollFrame.ScrollBar:SetPoint("RIGHT", ScrollFrame, relPoint, scrollBarXOffs or 0, 0)
	end
	
	if scrollBarSizeX then
		ScrollFrame.ScrollBar:SetWidth(scrollBarSizeX)
	end
	
	container.ScrollFrame = ScrollFrame
	ScrollFrame.container = container

	hooksecurefunc(container, "Hide", ScrollContainerHook_Hide)
	hooksecurefunc(container, "Show", ScrollContainerHook_Show)
	
end







-- -------------
-- GROUP CONFIG
-- -------------

---------- Add/Delete ----------
function TMW:Group_Delete(group)
	local domain = group.Domain
	local groupID = group.ID

	tremove(TMW.db[domain].Groups, groupID)
	TMW.db[domain].NumGroups = TMW.db[domain].NumGroups - 1


	-- -- Delay these updates to try and avoid these errors: 
	-- -- AceConfigDialog-3.0-58.lua:804: attempt to index field "rootframe" (a nil value) 
	-- TMW:ScheduleTimer(function()
		TMW:Update()

		IE:Load(1)
		TMW.ACEOPTIONS:NotifyChanges()
	-- end, 0.1)
end

function TMW:Group_Add(domain, view)
	if InCombatLockdown() then
		-- Error if we are in combat because TMW:Update() won't create the group instantly if we are.
		error("TMW: Can't add groups while in combat")
	end

	local groupID = TMW.db[domain].NumGroups + 1

	TMW.db[domain].NumGroups = groupID

	local gs = TMW.db[domain].Groups[groupID]

	if view then
		gs.View = view
		
		local viewData = TMW.Views[view]
		if viewData then
			viewData:Group_OnCreate(gs)
		end
	end

	TMW:Update()

	local group = TMW[domain][groupID]

	TMW.ACEOPTIONS:CompileOptions()
	TMW.ACEOPTIONS:NotifyChanges()

	return group
end

function TMW:Group_Swap(domain, groupID1, groupID2)
	local Groups = TMW.db[domain].Groups
	
	-- The point of this is to keep the icon editor's
	-- current icon the same before and after the swap.
	local iconID, groupGUID
	if CI.icon then
		iconID = CI.icon.ID
		groupGUID = CI.group:GetGUID()
	end

	Groups[groupID1], Groups[groupID2] = Groups[groupID2], Groups[groupID1]

	TMW:Update()

	IE:Load(1, groupGUID and TMW:GetDataOwner(groupGUID)[iconID])
end


---------- Etc ----------
function TMW:Group_HasIconData(group)
	for ics in group:InIconSettings() do
		if not TMW:DeepCompare(TMW.DEFAULT_ICON_SETTINGS, ics) then
			return true
		end
	end

	return false
end





-- ----------------------
-- ICON EDITOR
-- ----------------------

IE = TMW:NewModule("IconEditor", "AceEvent-3.0", "AceTimer-3.0") TMW.IE = IE
IE.Tabs = {}

IE.CONST = {
	TAB_OFFS_X = -18,
	IE_HEIGHT_MIN = 400,
	IE_HEIGHT_MAX = 1200,
}

function IE:OnInitialize()
	-- if the file IS required for gross functionality
	if not TMW.DROPDOWNMENU then
		-- GLOBALS: StaticPopupDialogs, StaticPopup_Show, EXIT_GAME, CANCEL, ForceQuit
		StaticPopupDialogs["TMWOPT_RESTARTNEEDED"] = {
			text = L["ERROR_MISSINGFILE_OPT"], 
			button1 = EXIT_GAME,
			button2 = CANCEL,
			OnAccept = ForceQuit,
			timeout = 0,
			showAlert = true,
			whileDead = true,
			preferredIndex = 3, -- http://forums.wowace.com/showthread.php?p=320956
		}
		StaticPopup_Show("TMWOPT_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "TellMeWhen_Options/TMWUIDropDownMenu.lua") -- arg3 could also be L["ERROR_MISSINGFILE_REQFILE"]
		return

	-- if the file is NOT required for gross functionality
	elseif not TMW.DOGTAG then
		StaticPopupDialogs["TMWOPT_RESTARTNEEDED"] = {
			text = L["ERROR_MISSINGFILE_OPT_NOREQ"], 
			button1 = EXIT_GAME,
			button2 = CANCEL,
			OnAccept = ForceQuit,
			timeout = 0,
			showAlert = true,
			whileDead = true,
			preferredIndex = 3, -- http://forums.wowace.com/showthread.php?p=320956
		}
		StaticPopup_Show("TMWOPT_RESTARTNEEDED", TELLMEWHEN_VERSION_FULL, "TellMeWhen/Components/Core/Common/DogTags/config.lua") -- arg3 could also be L["ERROR_MISSINGFILE_REQFILE"]
	end

	TMW:Fire("TMW_OPTIONS_LOADING")
	TMW:UnregisterAllCallbacks("TMW_OPTIONS_LOADING")

	-- Make TMW.IE be the same as IE.
	-- IE[0] = TellMeWhen_IconEditor[0] (already done in .xml)
	local meta = CopyTable(getmetatable(IE))
	meta.__index = getmetatable(TellMeWhen_IconEditor).__index
	setmetatable(IE, meta)


	hooksecurefunc("PickupSpellBookItem", function(...) IE.DraggingInfo = {...} end)
	WorldFrame:HookScript("OnMouseDown", function()
		IE.DraggingInfo = nil
	end)
	hooksecurefunc("ClearCursor", IE.BAR_HIDEGRID)
	IE:RegisterEvent("PET_BAR_HIDEGRID", "BAR_HIDEGRID")
	IE:RegisterEvent("ACTIONBAR_HIDEGRID", "BAR_HIDEGRID")


	IE:InitializeDatabase()


	IE:HookScript("OnShow", function()
		TMW:RegisterCallback("TMW_ONUPDATE_POST", IE)
	end)
	IE:HookScript("OnHide", function()
		TMW:UnregisterCallback("TMW_ONUPDATE_POST", IE)
	end)
	IE:SetScript("OnUpdate", IE.OnUpdate)
	IE.iconsToUpdate = {}

	TMW:RegisterCallback("TMW_GROUP_SETUP_POST", function(event, group)
		if CI.group == group then
			IE:CheckLoadedIconIsValid()
		end
	end)

	IE.history = {}
	IE.historyState = 0


	IE.MainTab = TMW.Classes.IconEditorTab:NewTab("MAIN", 1, "Main")
	IE.MainTab:SetText(TMW.L["MAIN"])
	TMW:TT(IE.MainTab, "MAIN", "MAIN_DESC")
	

	-- Create resizer
	self.resizer = TMW.Classes.Resizer_Generic:New(self)
	self.resizer:Show()
	self.resizer.scale_min = 0.4
	self.resizer.y_min = 400
	self.resizer.y_max = 1200
	self.resizer:SetModes(self.resizer.MODE_SCALE, self.resizer.MODE_SIZE)
	function self.resizer:SizeUpdated()
		TMW.IE.db.global.EditorHeight = IE:GetHeight()
		TMW.IE.db.global.EditorScale = IE:GetScale()
	end

	IE.Initialized = true

	TMW:Fire("TMW_OPTIONS_LOADED")
	TMW:UnregisterAllCallbacks("TMW_OPTIONS_LOADED")
	IE.OnInitialize = nil
end




---------------------------------
-- Database Management
---------------------------------

IE.Defaults = {
	global = {
		LastChangelogVersion = 0,
		TellMeWhenDBBackupDate = 0,
		EditorScale		= 0.9,
		EditorHeight	= 600,
		ConfigWarning	= true,
		ConfigWarningN	= 0,
		SimpleGSTab		= true,
	},
}

IE.UpgradeTable = {}
IE.UpgradeTableByVersions = {}

function IE:RegisterDatabaseDefaults(defaults)
	assert(type(defaults) == "table", "arg1 to RegisterProfileDefaults must be a table")
	
	if IE.InitializedDatabase then
		error("Defaults are being registered too late. They need to be registered before the database is initialized.", 2)
	end
	
	-- Copy the defaults into the main defaults table.
	TMW:MergeDefaultsTables(defaults, IE.Defaults)
end

function IE:GetBaseUpgrades()			-- upgrade functions
	return {
		[62218] = {
			global = function(self)
				IE.db.global.EditorScale = TMW.db.global.EditorScale or 0.9
				TMW.db.global.EditorScale = nil
				
				IE.db.global.EditorHeight = TMW.db.global.EditorHeight or 600
				TMW.db.global.EditorHeight = nil
				
				IE.db.global.ConfigWarning = TMW.db.global.ConfigWarning or true
				TMW.db.global.ConfigWarning = nil
				
			end,
			profile = function(self)
				-- Do Stuff
			end,
		},
	}
end

function IE:RegisterUpgrade(version, data)
	assert(not data.Version, "Upgrade data cannot store a value with key 'Version' because it is a reserved key.")
	
	if IE.HaveUpgradedOnce then
		error("Upgrades are being registered too late. They need to be registered before any upgrades occur.", 2)
	end
	
	local upgradeSet = IE.UpgradeTableByVersions[version]
	if upgradeSet then
		-- An upgrade set already exists for this version, so we need to merge the two.
		for k, v in pairs(data) do
			if upgradeSet[k] ~= nil then
				if type(v) == "function" then
					-- If we already have a function with the same key (E.g. 'icon' or 'group')
					-- then hook the existing function so that both run
					hooksecurefunc(upgradeSet, k, v)
				else
					-- If we already have data with the same key (some kind of helper data for the upgrade)
					-- then raise an error because there will certainly be conflicts.
					error(("A value with key %q already exists for upgrades for version %d. Please choose a different key to store it in to prevent conflicts.")
					:format(k, version), 2)
				end
			else
				-- There was nothing already in place, so just stick it in the upgrade set as-is.
				upgradeSet[k] = v
			end
		end
	else
		-- An upgrade set doesn't exist for this version,
		-- so just use the table that was passed in and process it as a new upgrade set.
		data.Version = version
		IE.UpgradeTableByVersions[version] = data
		tinsert(IE.UpgradeTable, data)
	end
end

function IE:SortUpgradeTable()
	sort(IE.UpgradeTable, TMW.UpgradeTableSorter)
end

function IE:GetUpgradeTable()	
	if IE.GetBaseUpgrades then		
		for version, data in pairs(IE:GetBaseUpgrades()) do
			IE:RegisterUpgrade(version, data)
		end
		
		IE.GetBaseUpgrades = nil
	end
	
	IE:SortUpgradeTable()
	
	return IE.UpgradeTable
end


function IE:DoUpgrade(type, version, ...)
	assert(_G.type(type) == "string")
	assert(_G.type(version) == "number")
	
	-- upgrade the actual requested setting
	for k, v in ipairs(IE:GetUpgradeTable()) do
		if v.Version > version then
			if v[type] then
				v[type](v, ...)
			end
		end
	end
	
	TMW:Fire("TMW_IE_UPGRADE_REQUESTED", type, version, ...)

	-- delegate out to sub-types
	if type == "global" then
	
		-- delegate to locale
		if IE.db.sv.locale then
			for locale, ls in pairs(IE.db.sv.locale) do
				IE:DoUpgrade("locale", version, ls, locale)
			end
		end
	
		--All Global Upgrades Complete
		TMWOptDB.Version = TELLMEWHEN_VERSIONNUMBER
	elseif type == "profile" then
		
		-- Put any sub-type upgrade delegation here...
		

		
		--All Profile Upgrades Complete
		IE.db.profile.Version = TELLMEWHEN_VERSIONNUMBER
	end
	
	IE.HaveUpgradedOnce = true
end


function IE:RawUpgrade()

	IE.RawUpgrade = nil
	

	-- Begin DB upgrades that need to be done before defaults are added.
	-- Upgrades here should always do everything needed to every single profile,
	-- and remember to check if a table exists before iterating/indexing it.

	if TMWOptDB and TMWOptDB.profiles then
		--[[
		if TMWOptDB.Version < 41402 then
			...

			for _, p in pairs(TMWOptDB.profiles) do
				...
			end
		end
		]]
		
	end
	
	TMW:Fire("TMW_IE_DB_PRE_DEFAULT_UPGRADES")
	TMW:UnregisterAllCallbacks("TMW_IE_DB_PRE_DEFAULT_UPGRADES")
end

function IE:UpgradeGlobal()
	if TMWOptDB.Version < TELLMEWHEN_VERSIONNUMBER then
		IE:DoUpgrade("global", TMWOptDB.Version, IE.db.global)
	end

	-- This function isn't needed anymore
	IE.UpgradeGlobal = nil
end

function IE:UpgradeProfile()
	-- Set the version for the current profile to the current version if it is a new profile.
	IE.db.profile.Version = IE.db.profile.Version or TELLMEWHEN_VERSIONNUMBER
		
	if TMWOptDB.Version < TELLMEWHEN_VERSIONNUMBER then
		IE:DoUpgrade("global", TMWOptDB.Version, IE.db.global)
	end
	
	if IE.db.profile.Version < TELLMEWHEN_VERSIONNUMBER then
		IE:DoUpgrade("profile", IE.db.profile.Version, IE.db.profile)
	end
end


function IE:InitializeDatabase()
	
	IE.InitializeDatabase = nil
	
	IE.InitializedDatabase = true
	
	TMW:Fire("TMW_IE_DB_INITIALIZING")
	TMW:UnregisterAllCallbacks("TMW_IE_DB_INITIALIZING")
	
	--------------- Database ---------------
	local TMWOptDB_alias
	if TMWOptDB and TMWOptDB.Version == nil then
		-- if TMWOptDB.Version is nil then we are upgrading from a version from before
		-- AceDB-3.0 was used for the options settings.

		TMWOptDB_alias = TMWOptDB

		-- Overwrite the old database (we will restore from the alias in a second)
		-- 62216 was the first version to use AceDB-3.0
		_G.TMWOptDB = {Version = 62216}

	elseif type(TMWOptDB) ~= "table" then
		-- TMWOptDB might not exist if this is a fresh install
		-- or if the user is upgrading from a really old version that doesn't use TMWOptDB.
		_G.TMWOptDB = {Version = TELLMEWHEN_VERSIONNUMBER}
	end
	
	
	-- Handle upgrades that need to be done before defaults are added to the database.
	-- Primary purpose of this is to properly upgrade settings if a default has changed.
	IE:RawUpgrade()
	
	-- Initialize the database
	IE.db = AceDB:New("TMWOptDB", IE.Defaults)
	
	if TMWOptDB_alias then
		for k, v in pairs(TMWOptDB_alias) do
			IE.db.global[k] = v
		end
		
		IE.db = AceDB:New("TMWOptDB", IE.Defaults)
	end
	
	IE.db.RegisterCallback(IE, "OnProfileChanged",	"OnProfile")
	IE.db.RegisterCallback(IE, "OnProfileCopied",	"OnProfile")
	IE.db.RegisterCallback(IE, "OnProfileReset",	"OnProfile")
	IE.db.RegisterCallback(IE, "OnNewProfile",		"OnProfile")
	
	-- Handle normal upgrades after the database has been initialized.
	IE:UpgradeGlobal()
	IE:UpgradeProfile()

	if TMW.DBWasEmpty and IE.db.global.TellMeWhenDBBackup then
		-- TellMeWhenDB was corrupted. Restore from the backup and notify user.
		TellMeWhenDB = IE.db.global.TellMeWhenDBBackup

		TMW:InitializeDatabase()
		TMW.db.profile.Locked = false

		TMW:ScheduleUpdate(1)

		TellMeWhen_DBRestoredNofication:SetTime(IE.db.global.TellMeWhenDBBackupDate)
		TellMeWhen_DBRestoredNofication:Show()

	elseif not TMW.DBWasEmpty --[[and IE.db.global.TellMeWhenDBBackupDate + 86400 < time()]] then
		-- TellMeWhenDB was not corrupt, so back it up.
		-- I have opted against only creating the backup after the old one reaches a certain age.
		IE.db.global.TellMeWhenDBBackupDate = time()
		IE.db.global.TellMeWhenDBBackup = TellMeWhenDB
	end

	TMW:Fire("TMW_IE_DB_INITIALIZED")
	TMW:UnregisterAllCallbacks("TMW_IE_DB_INITIALIZED")
end

function IE:OnProfile(event, arg2, arg3)

	if IE.Initialized then
		TMW.ACEOPTIONS:CompileOptions() -- redo groups in the options

		-- Reload the icon editor.
		IE:Load(1)
	
		TMW:Fire("TMW_IE_ON_PROFILE", event, arg2, arg3)
	end
end

TMW:RegisterCallback("TMW_ON_PROFILE", function(event, arg2, arg3)
	IE.db:SetProfile(TMW.db:GetCurrentProfile())
end)

 



TMW:NewClass("IconEditorTab", "Button"){
	
	NewTab = function(self, identifier, order, attachedFrame)
		self:AssertSelfIsClass()
		
		TMW:ValidateType("2 (identifier)", "IconEditorTab:NewTab(identifier, order, attachedFrame)", identifier, "string")
		TMW:ValidateType("3 (order)", "IconEditorTab:NewTab(identifier, order, attachedFrame)", order, "number")
		TMW:ValidateType("4 (attachedFrame)", "IconEditorTab:NewTab(identifier, order, attachedFrame)", attachedFrame, "string")
		
		local tab = self:New("Button", "TellMeWhen_IconEditorTab" .. #IE.Tabs + 1, TellMeWhen_IconEditor, "CharacterFrameTabButtonTemplate")
		
		tab.doesIcon = 1
		tab.doesGroup = 1
	
		tab.identifier = identifier
		tab.order = order
		tab.attachedFrame = attachedFrame
		
		IE.Tabs[#IE.Tabs + 1] = tab
		tab:SetID(#IE.Tabs)
		
		TellMeWhen_IconEditor.numTabs = #IE.Tabs
		
		TMW:SortOrderedTables(IE.Tabs)
		
		
		for id, tab in pairs(IE.Tabs) do
			if id == 1 then
				tab:SetPoint("BOTTOMLEFT", 0, -30)
			else
				tab:SetPoint("LEFT", IE.Tabs[id - 1], "RIGHT", IE.CONST.TAB_OFFS_X, 0)
			end
		end
		
		PanelTemplates_TabResize(tab, -6)
				
		return tab
	end,
	
	OnClick = function(self)
		if self.doesGroup and not CI.icon then
			self:ClickHandlerBase(IE.NotLoadedMessage)
		else
			IE.NotLoadedMessage:Hide()
			self:ClickHandler()
		end
	end,
	
	ClickHandlerBase = function(self, frame)
		-- invoke blizzard's tab click function to set the apperance of all the tabs
		PanelTemplates_Tab_OnClick(self, self:GetParent())
		PlaySound("igCharacterInfoTab")

		-- hide all tabs' frames, including the current tab so that the OnHide and OnShow scripts fire
		for _, tab in ipairs(IE.Tabs) do
			local frame = tab.attachedFrame
			if TellMeWhen_IconEditor[frame] then
				TellMeWhen_IconEditor[frame]:Hide()
			end
		end
		IE.NotLoadedMessage:Hide()

		local oldTab = IE.CurrentTab
		
		-- state the current tab.
		-- this is used in many other places, including inside some OnShow scripts, so it MUST go before the :Show()s below
		IE.CurrentTab = self

		-- show the selected tab's frame
		if frame then
			frame:Show()
		end

		-- show the icon editor
		--IE:Show()
		
		TMW:Fire("TMW_CONFIG_TAB_CLICKED", IE.CurrentTab, oldTab)
	end,
	
	ClickHandler = function(self)
		local frame = TellMeWhen_IconEditor[self.attachedFrame]
		if not frame then
			TMW:Error(("Couldn't find child of TellMeWhen_IconEditor with key %q"):format(self.attachedFrame))
		end

		self:ClickHandlerBase(frame)
	end,

	SetupHeader = function(self)
		local titlePrepend = "TellMeWhen v" .. TELLMEWHEN_VERSION_FULL

		local icon = CI.icon
		local group = CI.group


		if icon and self.doesGroup and self.doesIcon then
			-- For IconEditor tabs that can configure icons

			local groupName = group:GetGroupName(1)
			local name = L["GROUPICON"]:format(groupName, icon.ID)
			if group.Domain == "global" then
				name = L["DOMAIN_GLOBAL"] .. " " .. name
			end
			
			IE.Header:SetText(titlePrepend .. " - " .. name)

			IE.Header:SetFontObject(GameFontNormal)

			if IE.Header:IsTruncated() then
				IE.Header:SetFontObject(GameFontNormalSmall)
				local truncAmt = 3
				while IE.Header:IsTruncated() and truncAmt < #groupName + 4 do


					local name = L["GROUPICON"]:format(groupName:sub(1, -truncAmt - 4) .. "..." .. groupName:sub(-4), icon.ID)
					if group.Domain == "global" then
						name = L["DOMAIN_GLOBAL"] .. " " .. name
					end

					IE.Header:SetText(titlePrepend .. " - " .. name)
					truncAmt = truncAmt + 1
				end
			end

			if icon then
				IE.icontexture:SetTexture(icon.attributes.texture)
			end
			IE.BackButton:Show()
			IE.ForwardsButton:Show()

			IE.Header:SetPoint("LEFT", IE.ForwardsButton, "RIGHT", 4, 0)
		else
			-- For IconEditor tabs that can't configure icons (tabs handled here might not configure groups either)
			IE.icontexture:SetTexture(nil)
			IE.BackButton:Hide()
			IE.ForwardsButton:Hide()

			-- Setting this relative to icontexture makes it roughly centered
			-- (it gets offset to the left by the exit button)
			IE.Header:SetPoint("LEFT", IE.icontexture, "RIGHT", 4, 0)
			
			if group and self.doesGroup then
				-- for group config tabs, don't show icon info. Just show group info.
				local name = L["fGROUP"]:format(group:GetGroupName(1))
				if group.Domain == "global" then
					name = L["DOMAIN_GLOBAL"] .. " " .. name
				end
				IE.Header:SetText(titlePrepend .. " - " .. name)
			else
				IE.Header:SetText(titlePrepend)
			end
		end
	end,
	
	SetTitleComponents = function(self, doesIcon, doesGroup)
		self.doesIcon = doesIcon
		self.doesGroup = doesGroup
	end,
	


	OnShow = function(self)
		PanelTemplates_TabResize(self, -6)
		self:SetFrameLevel(self:GetParent():GetFrameLevel() - 1)
	end,
	OnHide = function(self)
		self:SetWidth(TMW.IE.CONST.TAB_OFFS_X)
	end,
	
	OnSizeChanged = function(self)
		PanelTemplates_TabResize(self, -6)
	end,
	
	METHOD_EXTENSIONS = {
		SetText = function(self, text)
			PanelTemplates_TabResize(self, -6)
		end,
	}
}


function IE:OnUpdate()
	local icon = CI.icon

	-- update the top of the icon editor with the information of the current icon.
	-- this is done in an OnUpdate because it is just too hard to track when the texture changes sometimes.
	-- I don't want to fill up the main addon with configuration code to notify the IE of texture changes	
	local tab = IE.CurrentTab
	if tab then
		tab:SetupHeader()
	end
	
	
	if IE.isMoving then
		local cursorCurrentX, cursorCurrentY = GetCursorPosition()
		local deltaX, deltaY = IE.cursorStartX - cursorCurrentX, IE.cursorStartY - cursorCurrentY
		
		local scale = IE:GetEffectiveScale()
		deltaX, deltaY = deltaX/scale, deltaY/scale
		
		local a, b, c = IE:GetPoint()
		IE:ClearAllPoints()
		IE:SetPoint(a, b, c, IE.startX - deltaX, IE.startY - deltaY)
	end
end


function IE:BAR_HIDEGRID()
	IE.DraggingInfo = nil
end

function IE:TMW_ONUPDATE_POST(...)
	-- run updates for any icons that are queued
	for i, icon in ipairs(IE.iconsToUpdate) do
		if icon:IsGroupController() then
			TMW.safecall(icon.group.Setup, icon.group)
		else
			TMW.safecall(icon.Setup, icon)
		end
	end
	wipe(IE.iconsToUpdate)

	-- check and see if the settings of the current icon have changed.
	-- if they have, create a history point (or at least try to)
	-- IMPORTANT: do this after running icon updates <because of an old antiquated reason which no longer applies, but if it ain't broke, don't fix it>
	IE:AttemptBackup(TMW.CI.icon)
end

TMW:RegisterCallback("TMW_CONFIG_TAB_CLICKED", function(event, tab)
	IE:UndoRedoChanged()

	if tab.doesIcon then
		IE.ResetButton:Enable()
	else
		IE.ResetButton:Disable()
	end
end)

TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	-- GLOBALS: TellMeWhen_ConfigWarning
	if not TMW.Locked then
		if IE.db.global.ConfigWarning then
			TellMeWhen_ConfigWarning:Show()
		else
			TellMeWhen_ConfigWarning:Hide()
		end
	else
		TellMeWhen_ConfigWarning:Hide()
	end

	IE:SaveSettings()
end)

TMW:RegisterCallback("TMW_GROUP_SETUP_POST", function()
	-- GLOBALS: TellMeWhen_NoGroupsWarning
	if not TMW.Locked then
		for group in TMW:InGroups() do
			if group:IsVisible() then
				TellMeWhen_NoGroupsWarning:Hide()
				return
			end
		end

		TellMeWhen_NoGroupsWarning:Show()
	else
		TellMeWhen_NoGroupsWarning:Hide()
	end
end)

IE:RegisterEvent("PLAYER_REGEN_DISABLED", function()
	if not TMW.ALLOW_LOCKDOWN_CONFIG then
		IE:Hide()
		LibStub("AceConfigDialog-3.0"):Close("TMWStandalone")
	end
end)

TMW:RegisterCallback("TMW_LOCK_TOGGLED", function(event, Locked)
	if Locked and not CI.icon then
		IE:Hide()
	end
end)

function IE:StartMoving()
	IE.startX, IE.startY = select(4, IE:GetPoint())
	IE.cursorStartX, IE.cursorStartY = GetCursorPosition()
	IE.isMoving = true
end

function IE:StopMovingOrSizing()
	IE.isMoving = false
end


---------- Interface ----------
IE.AllDisplayPanels = {}
local panelList = {}

function IE:PositionPanels()
	for _, frame in pairs(IE.AllDisplayPanels) do
		frame:Hide()
	end
	
	if not CI.icon then
		return
	end

	wipe(panelList)
	for _, Component in pairs(CI.icon.Components) do
		if Component:ShouldShowConfigPanels(CI.icon) then
			for _, panelInfo in pairs(Component.ConfigPanels) do
				tinsert(panelList, panelInfo)
			end		
		end
	end
	
	TMW:SortOrderedTables(panelList)
	
	local ParentLeft, ParentRight = TellMeWhen_IconEditorMainPanelsLeft, TellMeWhen_IconEditorMainPanelsRight
	for i = 1, #ParentLeft do
		ParentLeft[i] = nil
	end
	for i = 1, #ParentRight do
		ParentRight[i] = nil
	end
	
	for i, panelInfo in ipairs(panelList) do
		local GenericComponent = panelInfo.component
		
		local parent
		if GenericComponent.className == "IconType" then 
			parent = ParentLeft
		else
			parent = ParentRight
		end
		
		local frame
		-- Get the frame for the panel if it already exists, or create it if it doesn't.
		if panelInfo.panelType == "XMLTemplate" then
			frame = IE.AllDisplayPanels[panelInfo.xmlTemplateName]
			
			if not frame then
				frame = TMW.C.Config_Panel:New("Frame", panelInfo.xmlTemplateName, parent, panelInfo.xmlTemplateName)

				IE.AllDisplayPanels[panelInfo.xmlTemplateName] = frame
			end
		elseif panelInfo.panelType == "ConstructorFunc" then
			frame = IE.AllDisplayPanels[panelInfo] 
			
			if not frame then
				frame = TMW.C.Config_Panel:New("Frame", panelInfo.frameName, parent, "TellMeWhen_OptionsModuleContainer")

				IE.AllDisplayPanels[panelInfo] = frame
				TMW.safecall(panelInfo.func, frame)
			end
		end
		
		if frame and frame:ShouldShow() then
			if type(parent[#parent]) == "table" then
				frame:SetPoint("TOP", parent[#parent], "BOTTOM", 0, -11)
			else
				frame:SetPoint("TOP", 0, -11)
			end
			parent[#parent + 1] = frame
			
			
			frame:Show()

			frame:Setup(panelInfo)
			
			TMW:Fire("TMW_CONFIG_PANEL_SETUP", frame, panelInfo)
		end	
	end	
	
	local IE_FL = IE:GetFrameLevel()
	for i = 1, #ParentLeft do
		ParentLeft[i]:SetFrameLevel(IE_FL + 3) --(#ParentLeft-i+1)*3)
	end
	for i = 1, #ParentRight do
		ParentRight[i]:SetFrameLevel(IE_FL + 3) --(#ParentRight-i+1)*3)
	end
end

function IE:DistributeFrameAnchorsLaterally(parent, numPerRow, ...)
	local numChildFrames = select("#", ...)
	
	local parentWidth = parent:GetWidth()

	local paddingPerSide = 5 -- constant
	local parentWidth_padded = parentWidth - paddingPerSide*2
	
	local widthPerFrame = parentWidth_padded/numPerRow
	
	local lastChild
	for i = 1, numChildFrames do
		local child = select(i, ...)
		
		local yOffset = 0
		for i = 1, child:GetNumPoints() do
			local point, relativeTo, relativePoint, x, y = child:GetPoint(i)
			if point == "LEFT" then
				yOffset = y or 0
				break
			end
		end
		
		if lastChild then
			child:SetPoint("LEFT", lastChild, "RIGHT", widthPerFrame - lastChild:GetWidth(), yOffset)
		else
			child:SetPoint("LEFT", paddingPerSide, yOffset)
		end
		lastChild = child
	end
end

function IE:Load(isRefresh, icon, isHistoryChange)
	TMW.ACEOPTIONS:CompileOptions()

	if icon ~= nil then
		local ic_old = CI.icon

		if type(icon) == "table" then
			PlaySound("igCharacterInfoTab")
			IE:SaveSettings()
			
			CI.icon = icon

			if IE.history[#IE.history] ~= icon and not isHistoryChange then
				-- if we are using an old history point (i.e. we hit back a few times and then loaded a new icon),
				-- delete all history points from the current one forward so that we dont jump around wildly when backing and forwarding
				for i = IE.historyState + 1, #IE.history do
					IE.history[i] = nil
				end

				IE.history[#IE.history + 1] = icon

				-- set the history state to the latest point
				IE.historyState = #IE.history
				-- notify the back and forwards buttons that there was a change so they can :Enable() or :Disable()
				IE:BackFowardsChanged()
			end
			
			if ic_old ~= CI.icon then
				IE.Main.PanelsLeft.ScrollFrame:SetVerticalScroll(0)
				IE.Main.PanelsRight.ScrollFrame:SetVerticalScroll(0)
			end


		elseif icon == false then
			CI.icon = nil
		end

		if IE.CurrentTab then
			IE.CurrentTab:OnClick()
		else
			IE.MainTab:OnClick()
		end

		TMW:Fire("TMW_CONFIG_ICON_LOADED_CHANGED", CI.icon, ic_old)
	end

	local shouldShow = true
	if TellMeWhen_ChangelogDialog and TellMeWhen_ChangelogDialog.showIEOnClose then
		-- Wait for the changelog to hide before attemping to load again
		return
	end

	if IE.db.global.LastChangelogVersion > 0 then
		if IE.db.global.LastChangelogVersion < TELLMEWHEN_VERSIONNUMBER then
			if IE.db.global.LastChangelogVersion < TELLMEWHEN_FORCECHANGELOG -- forced
			or TELLMEWHEN_VERSION_MINOR == "" -- upgraded to a release version (e.g. 7.0.0 release)
			or floor(IE.db.global.LastChangelogVersion/100) < floor(TELLMEWHEN_VERSIONNUMBER/100) -- upgraded to a new minor version (e.g. 6.2.6 release -> 7.0.0 alpha)
			then
				IE:ShowChangelog(IE.db.global.LastChangelogVersion, true)
				shouldShow = false

				TMW.HELP:Show{
					code = "CHANGELOG_INFO",
					codeOrder = 100,
					codeOnlyOnce = false,

					icon = nil,
					parent = TellMeWhen_ChangelogDialog,
					x = 0,
					y = -40,
					relativeTo = TellMeWhen_ChangelogDialog,
					relativePoint = "TOPLEFT",
					text = format(L["CHANGELOG_INFO"], TELLMEWHEN_VERSION_FULL)
				}
			
			else
				TMW:Printf(L["CHANGELOG_MSG"], TELLMEWHEN_VERSION_FULL)
			end

			IE.db.global.LastChangelogVersion = TELLMEWHEN_VERSIONNUMBER
		end
	else
		IE.db.global.LastChangelogVersion = TELLMEWHEN_VERSIONNUMBER
	end

	if not IE:IsShown() then
		if isRefresh then
			return
		elseif shouldShow then
			IE:Show()
		end
	end
	
	if 0 > IE:GetBottom() then
		IE.db.global.EditorScale = IE.Defaults.global.EditorScale
		IE.db.global.EditorHeight = IE.Defaults.global.EditorHeight
	end
	
	IE:SetScale(IE.db.global.EditorScale)
	IE:SetHeight(IE.db.global.EditorHeight)

	
	if CI.icon then
		-- This is really really important. The icon must be setup so that it has the correct components implemented
		-- so that the correct config panels will be loaded and shown for the icon.
		CI.icon:Setup()

		IE:PositionPanels()
		
		if CI.ics.Type == "" then
			IE.Main.Type:SetText(L["ICONMENU_TYPE"])
		else
			local Type = rawget(TMW.Types, CI.ics.Type)
			if Type then
				IE.Main.Type:SetText(Type.name)
			else
				IE.Main.Type:SetText(CI.ics.Type .. ": UNKNOWN TYPE")
			end
		end

		IE.ResetButton:Enable()

		IE:ScheduleIconSetup()

		-- It is intended that this happens at the end instead of the beginning.
		-- Table accesses that trigger metamethods flesh out an icon's settings with new things that aren't there pre-load (usually)
		if icon then
			IE:AttemptBackup(CI.icon)
		end

		TMW:Fire("TMW_CONFIG_ICON_LOADED", CI.icon)
	else
		IE.ResetButton:Disable()
	end
	
	IE:UndoRedoChanged()

	TMW:Fire("TMW_CONFIG_LOADED")
end

function IE:CheckLoadedIconIsValid()
	if not TMW.IE:IsShown() then
		return
	end

	if not CI.icon then
		return
	elseif
		not CI.group:IsValid()
		or not CI.icon:IsInRange()
		or CI.icon:IsControlled()
	then
		TMW.IE:Load(nil, false)
	end
end


function IE:Reset()	
	IE:SaveSettings() -- this is here just to clear the focus of editboxes, not to actually save things
	
	CI.icon:DisableIcon()
	
	TMW.CI.gs.Icons[CI.icon.ID] = nil
	
	TMW:Fire("TMW_ICON_SETTINGS_RESET", CI.icon)
	
	CI.icon:Setup()
	
	IE:Load(1)
	
	IE.MainTab:Click()
end


---------- Spell/Item Dragging ----------
function IE:SpellItemToIcon(icon, func, arg1)
	if not icon.IsIcon then
		return
	end

	local t, data, subType, param4
	local input
	if not (CursorHasSpell() or CursorHasItem()) and IE.DraggingInfo then
		t = "spell"
		data, subType = unpack(IE.DraggingInfo)
	else
		t, data, subType, param4 = GetCursorInfo()
	end
	IE.DraggingInfo = nil

	if not t then
		return
	end

	IE:SaveSettings()

	-- create a backup before doing things
	IE:AttemptBackup(icon)

	-- handle the drag based on icon type
	local success
	if func then
		success = func(arg1, icon, t, data, subType, param4)
	else
		success = icon.typeData:DragReceived(icon, t, data, subType, param4)
	end
	if not success then
		return
	end

	ClearCursor()
	icon:Setup()
	IE:Load(1)
end


---------- Settings ----------



TMW:NewClass("Config_Frame", "Frame"){
	-- Constructor
	OnNewInstance_Frame = function(self, data)
		-- Setup callbacks that will load the settings when needed.
		TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", self, "ReloadSetting")
		TMW:RegisterCallback("TMW_CONFIG_ICON_HISTORY_STATE_CREATED", self, "ReloadSetting")
		TMW:RegisterCallback("TMW_CONFIG_ICON_HISTORY_STATE_CHANGED", self, "ReloadSetting")

		if data then
			-- Set appearance and settings
			self.data = data
			self.setting = data.setting

			if self.data.title or self.data.tooltip then
				self:SetTooltip(self.data.title, self.data.tooltip)
			end
		end
	end,
	

	-- Script Handlers
	OnEnable = function(self)
		self:SetAlpha(1)
		
		if self.data.disabledtooltip then
			self:SetTooltip(self.data.title, self.data.tooltip)
		end
	end,
	
	OnDisable = function(self)
		self:SetAlpha(0.2)
		
		if self.data.disabledtooltip then
			self:SetTooltip(self.data.title, self.data.disabledtooltip)
		end
	end,
	

	-- Methods
	Enabled = true,
	IsEnabled = function(self)
		return self.Enabled
	end,
	SetEnabled = function(self, enabled)		
		if self.Enabled ~= enabled then
			self.Enabled = enabled
			if enabled then
				self:OnEnable()
			else
				self:OnDisable()
			end
		end
	end,
	Enable = function(self)
		self:SetEnabled(true)
	end,
	Disable = function(self)
		self:SetEnabled(false)
	end,

	CheckDisabled = function(self)
		if self.data.disabled ~= nil then
			if get(self.data.disabled, self) then
				self:Disable()
			else
				self:Enable()
			end
		end
	end,
	
	CheckHidden = function(self)
		if self.data.hidden ~= nil then
			if get(self.data.hidden, self) then
				self:Hide()
			else
				self:Show()
			end
		end
	end,
	
	CheckInteractionStates = function(self)
		self:CheckDisabled()
		self:CheckHidden()
	end,
	
	SetTooltip = function(self, title, text)
		if self.SetMotionScriptsWhileDisabled then
			TMW:TT(self, title, text, 1, 1, nil)
		else
			TMW:TT(self, title, text, 1, 1, "IsEnabled")
		end
	end,
	
	ConstrainLabel = function(self, anchorTo, anchorPoint, ...)
		assert(self.text, "frame does not have a self.text object to constrain.")

		self.text:SetPoint("RIGHT", anchorTo, anchorPoint or "LEFT", ...)
		
		-- Have to do this or else the text won't multiline/wordwrap when it should.
		-- 30 is just an arbitrarily large number.
		self.text:SetHeight(30)
		self.text:SetMaxLines(3)
	end,

	GetSettingTable = function(self)
		return CI.ics
	end,

	ReloadSetting = TMW.NULLFUNC
}

TMW:NewClass("Config_Panel", "Config_Frame"){
	SetHeight_base = TMW.C.Config_Panel.SetHeight,
}{
	OnNewInstance_Frame = TMW.NULLFUNC,
	CheckDisabled = TMW.NULLFUNC,

	OnNewInstance_Panel = function(self)
		if self:GetHeight() <= 0 then
			self:SetHeight_base(1)
		end
		local hue = 2/3
		
		self.Background:SetTexture(hue, hue, hue) -- HUEHUEHUE
		self.Background:SetGradientAlpha("VERTICAL", 1, 1, 1, 0.05, 1, 1, 1, 0.10)

		self.height = self:GetHeight()
	end,

	Flash = function(self, dur)
		local start = GetTime()
		local duration = 0
		local period = 0.2

		while duration < dur do
			duration = duration + (period * 2)
		end
		local ticker
		ticker = C_Timer.NewTicker(0.01, function() 
			local bg = TellMeWhen_DotwatchSettings.Background

			local timePassed = GetTime() - start
			local fadingIn = FlashPeriod == 0 or floor(timePassed/period) % 2 == 1

			if FlashPeriod ~= 0 then
				local remainingFlash = timePassed % period
				local offs
				if fadingIn then
					offs = (period-remainingFlash)/period
				else
					offs = (remainingFlash/period)
				end
				offs = offs*0.3
				bg:SetGradientAlpha("VERTICAL", 1, 1, 1, 0.05 + offs, 1, 1, 1, 0.10 + offs)
			end

			if timePassed > duration then
				bg:SetGradientAlpha("VERTICAL", 1, 1, 1, 0.05, 1, 1, 1, 0.10)
				ticker:Cancel()
			end	
		end)
	end,

	SetTitle = function(self, text)
		self.Header:SetText(text)
	end,

	Setup = function(self, panelInfo)
		self.panelInfo = panelInfo
		if panelInfo then
			self.supplementalData = panelInfo.supplementalData
		end


		get(self.OnSetup, self, panelInfo, self.supplementalData) 

		if type(self.supplementalData) == "table" then
			self.data = self.supplementalData
			self:CheckInteractionStates()

			-- Cheater! (We arent getting anything)
			-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
			get(self.supplementalData.OnSetup, self, panelInfo, self.supplementalData) 
		end
	end,

	ShouldShow = function(self)
		return true
	end,

	SetHeight = function(self, height)
		if self.__oldHeight then
			self.__oldHeight = height
		else
			self:SetHeight_base(height)
		end
	end,
	OnHide = function(self)
		local p, r, t, x, y = self:GetPoint(1)
		self:SetPoint(p, r, t, x, 1)

		-- Set the height to 1 so things anchored under it are positioned right.
		-- Can't set height to 0 anymore in WoD.
		self.__oldHeight = self:GetHeight()
		self:SetHeight_base(1)
	end,
	OnShow = function(self)
		local p, r, t, x, y = self:GetPoint(1)
		self:SetPoint(p, r, t, x, -11)

		-- Restore the old height if it is still set to 1.
		if self.__oldHeight and floor(self:GetHeight() + 0.5) == 1 then
			self:SetHeight_base(self.__oldHeight)
			self.__oldHeight = nil
		end
	end,

	--[[
	SetHeight = function(self, endHeight)
		-- This function currently disabled because of frame level issues.
		-- Top frames need to be above lower frames, but editboxes seem to go underneath everything for some reason.
		-- It doesn't look awful, but I'm going to leave it disabled till I decide otherwise.
		
		if not self.__animateHeightHooked then
			self.__animateHeightHooked = true
			self:HookScript("OnUpdate", function()
				if self.__animateHeight_duration then
					if TMW.time - self.__animateHeight_startTime > self.__animateHeight_duration then
						self.__animateHeight_duration = nil
						self:SetHeight_base(self.__animateHeight_end)
						return  
					end
					
					local pct = (TMW.time - self.__animateHeight_startTime)/self.__animateHeight_duration
					
					self:SetHeight_base((pct*self.__animateHeight_delta)+self.__animateHeight_start)
				end
			end)    
		end
		
		self.__animateHeight_start = self:GetHeight()
		self.__animateHeight_end = endHeight
		self.__animateHeight_delta = self.__animateHeight_end - self.__animateHeight_start
		self.__animateHeight_startTime = TMW.time
		self.__animateHeight_duration = 0.1
	end,]]
}


TMW:NewClass("Config_CheckButton", "CheckButton", "Config_Frame"){
	-- Constructor
	OnNewInstance_CheckButton = function(self, data)
		self.text:SetText(get(self.data.label or self.data.title))
		self:SetMotionScriptsWhileDisabled(true)
	end,


	-- Script Handlers
	OnClick = function(self, button)
		local settings = self:GetSettingTable()

		local checked = not not self:GetChecked()

		if self.data.invert then
			checked = not checked
		end

		if checked then
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
		end

		if settings and self.setting then
			if self.data.value == nil then
				settings[self.setting] = checked
			else --if checked then
				settings[self.setting] = self.data.value
				self:SetChecked(true)
			end
			IE:ScheduleIconSetup()
		end
		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnClick, self, button) 

		self:OnState()
	end,


	-- Methods
	OnState = function(self)
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnState, self) 
	end,
	
	ReloadSetting = function(self)
		local settings = self:GetSettingTable()

		if settings then
			if self.data.value ~= nil then
				self:SetChecked(settings[self.setting] == self.data.value)
			else
				if self.data.invert then
					self:SetChecked(not settings[self.setting])
				else
					self:SetChecked(settings[self.setting])
				end
			end
			self:CheckInteractionStates()
			self:OnState()
		end
	end,
}

TMW:NewClass("Config_EditBox", "EditBox", "Config_Frame"){
	
	-- Constructor
	OnNewInstance_EditBox = function(self, data)
		TMW:RegisterCallback("TMW_CONFIG_SAVE_SETTINGS", self, "ClearFocus")

		self.BackgroundText:SetWidth(self:GetWidth())
		if data and data.label then
			self.label = data.label
		end
	end,
	

	-- Scripts
	OnEditFocusLost = function(self, button)
		self:SaveSetting()
		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnEditFocusLost, self, button) 
	end,

	OnTextChanged = function(self, button)		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnTextChanged, self, button) 
	end,

	METHOD_EXTENSIONS = {
		OnEnable = function(self)
			self:EnableMouse(true)
			self:EnableKeyboard(true)
		end,

		OnDisable = function(self)
			self:ClearFocus()
			self:EnableMouse(false)
			self:EnableKeyboard(false)
		end,
	},
	

	-- Methods
	SaveSetting = function(self)
		local settings = self:GetSettingTable()

		if settings and self.setting then
			local value
			if self.data.doCleanString then
				value = TMW:CleanString(self)
			else
				value = self:GetText()
			end
			
			value = get(self.data.ModifySettingValue, self, value) or value

			settings[self.setting] = value
		
			IE:ScheduleIconSetup()
		end
	end,

	ReloadSetting = function(self, eventMaybe)
		local settings = self:GetSettingTable()

		if settings then
			if not (eventMaybe == "TMW_CONFIG_ICON_HISTORY_STATE_CREATED" and self:HasFocus()) and self.setting then
				self:SetText(settings[self.setting] or "")
			end
			self:CheckInteractionStates()
			self:ClearFocus()
		end
	end,
}

TMW:NewClass("Config_Slider", "Slider", "Config_Frame")
{
	-- Saving base methods.
	-- This is done in a separate call to make sure it happens before 
	-- new ones overwrite the base methods.

	Show_base = TMW.C.Config_Slider.Show,
	Hide_base = TMW.C.Config_Slider.Hide,

	SetValue_base = TMW.C.Config_Slider.SetValue,
	GetValue_base = TMW.C.Config_Slider.GetValue,

	GetValueStep_base = TMW.C.Config_Slider.GetValueStep,

	GetMinMaxValues_base = TMW.C.Config_Slider.GetMinMaxValues,
	SetMinMaxValues_base = TMW.C.Config_Slider.SetMinMaxValues,
}{

	Config_EditBox_Slider = TMW:NewClass("Config_EditBox_Slider", "Config_EditBox"){
		
		-- Constructor
		OnNewInstance_EditBox_Slider = function(self, data)
			self:EnableMouseWheel(true)
		end,
		

		-- Scripts
		OnEditFocusLost = function(self, button)
			local text = tonumber(self:GetText())
			if text then
				self.Slider:SetValue(text)
				self.Slider:SaveSetting()
			end

			self:SetText(self.Slider:GetValue())
		end,


		OnMouseDown = function(self, button)
			if button == "RightButton" and not self.Slider:ShouldForceEditBox() then
				self.Slider:UseSlider()
			end
		end,

		OnMouseWheel = function(self, ...)
			self.Slider:GetScript("OnMouseWheel")(self.Slider, ...)
		end,

		METHOD_EXTENSIONS = {
			OnEnable = function(self)
				self:EnableMouse(true)
				self:EnableKeyboard(true)
			end,

			OnDisable = function(self)
				self:ClearFocus()
				self:EnableMouse(false)
				self:EnableKeyboard(false)
			end,
		},
		

		-- Methods
		ReloadSetting = function(self)
			self:SetText(self.Slider:GetValue())
		end,
	},

	EditBoxShowing = false,

	MODE_STATIC = 1,
	MODE_ADJUSTING = 2,

	FORCE_EDITBOX_THRESHOLD = 10e5,

	range = 10,

	formatter = TMW.C.Formatter.PASS,
	extremesFormatter = TMW.C.Formatter.PASS,

	-- Constructor
	OnNewInstance_Slider = function(self, data)
		self.min, self.max = self:GetMinMaxValues()

		self:SetMode(self.MODE_STATIC)

		if data.min and data.max then
			self:SetMinMaxValues(data.min, data.max)
		end
		if data.range then
			self:SetRange(data.range)
		end

		self:SetValueStep(data.step or self:GetValueStep() or 1)
		self:SetWheelStep(data.wheelStep)
		
		self.text:SetText(data.label or data.title)


		self:SetTooltip(data.title, data.tooltip)

		
		self:EnableMouseWheel(true)
	end,

	-- Blizzard Overrides
	GetValue = function(self)
		if self.EditBoxShowing then
			local text = self.EditBox:GetText()
			if text == "" then
				text = 0
			end

			text = tonumber(text)
			if text then
				return self:CalculateValueRoundedToStep(text)
			end
		end

		return self:CalculateValueRoundedToStep(self:GetValue_base())
	end,
	SetValue = function(self, value)
		self.scriptFiredOnValueChanged = nil

		if value < self.min then
			value = self.min
		elseif value > self.max then
			value = self.max
		end
		value = self:CalculateValueRoundedToStep(value)

		self:UpdateRange(value)
		self:SetValue_base(value)
		if self.EditBoxShowing then
			self.EditBox:SetText(value)
		end

		if not self.scriptFiredOnValueChanged and value ~= self:GetValue_base() then
			self:OnValueChanged()
		end
	end,

	GetMinMaxValues = function(self)
		local min, max = self:GetMinMaxValues_base()

		min = self:CalculateValueRoundedToStep(min)
		max = self:CalculateValueRoundedToStep(max)

		return min, max
	end,
	SetMinMaxValues = function(self, min, max)
		min = min or -math.huge
		max = max or math.huge

		if min > max then
			error("min can't be bigger than max")
		end

		self.min = min
		self.max = max

		if self.mode == self.MODE_STATIC then
			self:SetMinMaxValues_base(min, max)
		elseif not self.EditBoxShowing then
			self:UpdateRange()
		end
	end,

	GetValueStep = function(self)
		local step = self:GetValueStep_base()
		return floor((step*10^5) + .5) / 10^5
	end,

	SetWheelStep = function(self, wheelStep)
		self.wheelStep = wheelStep
	end,
	GetWheelStep = function(self)
		return self.wheelStep or self:GetValueStep()
	end,


	Show = function(self)
		if self.EditBoxShowing then
			self.EditBox:Show()
		else
			self:Show_base()
		end
	end,
	Hide = function(self)
		self:Hide_base()
		if self.EditBoxShowing then
			self.EditBox:Hide()
		end
	end,

	-- Script Handlers
	OnMinMaxChanged = function(self)
		self:UpdateTexts()
	end,

	OnValueChanged = function(self)
		if not self.__fixingValueStep then
			self.__fixingValueStep = true
			self:SetValue_base(self:GetValue())
			self.__fixingValueStep = nil
		else
			return
		end

		self.scriptFiredOnValueChanged = true

		if self.EditBox then
			self.EditBox:SetText(self:GetValue())
		end

		if self:ShouldForceEditBox() and not self.EditBoxShowing then
			self:SaveSetting()
			self:UseEditBox()
		end

		self:UpdateTexts()
		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnValueChanged, self) 
	end,

	OnMouseDown = function(self, button)
		if button == "RightButton" then
			self:UseEditBox()

			self:ReloadSetting()
		end
	end,

	OnMouseUp = function(self)
		if self.mode == self.MODE_ADJUSTING then
			self:UpdateRange()
		end
		
		self:SaveSetting()
	end,
	
	OnMouseWheel = function(self, delta)
		if self:IsEnabled() then
			if IsShiftKeyDown() then
				delta = delta*10
			end
			if IsControlKeyDown() then
				delta = delta*60
			end
			if delta == 1 or delta == -1 then
				delta = delta*(self:GetWheelStep() or 1)
			end

			local level = self:GetValue() + delta

			self:SetValue(level)

			self:SaveSetting()
		end
	end,

	-- Methods
	SetRange = function(self, range)
		self.range = range
		self:UpdateRange()
	end,
	GetRange = function(self)
		return self.range
	end,

	CalculateValueRoundedToStep = function(self, value)
		if value == math.huge or value == -math.huge then
			return value
		end
		
		local step = self:GetValueStep()

		return floor(value * (1/step) + 0.5) / (1/step)
	end,

	SetMode = function(self, mode)
		self.mode = mode

		if mode == self.MODE_STATIC then
			self:UseSlider()
		end

		self:UpdateRange()
	end,
	GetMode = function(self)
		return self.mode
	end,


	ShouldForceEditBox = function(self)
		if self:GetMode() == self.MODE_STATIC then
			return false
		elseif self:GetValue() > self.FORCE_EDITBOX_THRESHOLD then
			return true
		end
	end,

	UseEditBox = function(self)
		if self:GetMode() == self.MODE_STATIC then
			return
		end

		if not self.EditBox then
			local name = self:GetName() and self:GetName() .. "Box" or nil
			self.EditBox = self.Config_EditBox_Slider:New("EditBox", name, self:GetParent(), "TellMeWhen_InputBoxTemplate", nil, {})
			self.EditBox.Slider = self

			self.EditBox:SetPoint("TOP", self, "TOP", 0, -4)
			self.EditBox:SetPoint("LEFT", self, "LEFT", 2, 0)
			self.EditBox:SetPoint("RIGHT", self)

			self.EditBox:SetText(self:GetValue())

			if self.ttData then
				self:SetTooltip(unpack(self.ttData))
			end
		end

		if not self.EditBoxShowing then
			PlaySound("igMainMenuOptionCheckBoxOn")
			
			self.EditBoxShowing = true
			
			if self.text:GetParent() == self then
				self.text:SetParent(self.EditBox)
			end

			self.EditBox:Show()
			self:Hide_base()

			self:ReloadSetting()
		end
	end,
	UseSlider = function(self)
		if self.EditBoxShowing then
			PlaySound("igMainMenuOptionCheckBoxOn")

			self.EditBoxShowing = false

			if self.text:GetParent() == self.EditBox then
				self.text:SetParent(self)
			end

			if self.EditBox:IsShown() then
				self:Show_base()
			end
			self.EditBox:Hide()
			self:UpdateRange()

			self:ReloadSetting()
		end
	end,


	SetTextFormatter = function(self, formatter, extremesFormatter)
		TMW:ValidateType("2 (formatter)", (self:GetName() or "<unnamed>") .. ":SetTextFormatter(formatter)", formatter, "Formatter;nil")
		TMW:ValidateType("3 (extremesFormatter)", (self:GetName() or "<unnamed>") .. ":SetTextFormatter(formatter [,extremesFormatter])", extremesFormatter, "Formatter;nil")

		self.formatter = formatter or TMW.C.Formatter.PASS
		self.extremesFormatter = extremesFormatter or formatter or TMW.C.Formatter.PASS

		self:UpdateTexts()
	end,

	SetStaticMidText = function(self, text)
		self.staticMidText = text

		self:UpdateTexts()
	end,

	TT_textFunc = function(self)
		local text = self.ttData[2]

		if not text then
			text = ""
		else
			text = text .. "\r\n\r\n"
		end

		if self:GetObjectType() == "Slider" then
			if self:GetMode() == self.MODE_ADJUSTING then
				text = text .. L["CNDT_SLIDER_DESC_CLICKSWAP_TOMANUAL"]
			else
				return self.ttData[2]
			end
		else -- EditBox
			if self.Slider:ShouldForceEditBox() then
				text = text .. L["CNDT_SLIDER_DESC_CLICKSWAP_TOSLIDER_DISALLOWED"]:format(TMW.C.Formatter.COMMANUMBER:Format(self.Slider.FORCE_EDITBOX_THRESHOLD))
			else
				text = text .. L["CNDT_SLIDER_DESC_CLICKSWAP_TOSLIDER"]
			end
		end

		return text
	end,

	SetTooltip = function(self, title, text)
		self.ttData = {title, text}

		TMW:TT(self, title, self.TT_textFunc, 1, 1)

		if self.EditBox then
			TMW:TT(self.EditBox, title, self.TT_textFunc, 1, 1)
			self.EditBox.ttData = self.ttData
		end
	end,

	UpdateTexts = function(self)
		if self.staticMidText then
			self.Mid:SetText(self.staticMidText)
		else
			self.formatter:SetFormattedText(self.Mid, self:GetValue())
		end

		local minValue, maxValue = self:GetMinMaxValues()
		
		self.extremesFormatter:SetFormattedText(self.Low, minValue)
		self.extremesFormatter:SetFormattedText(self.High, maxValue)
	end,


	UpdateRange = function(self, value)
		if self.mode == self.MODE_ADJUSTING then
			local deviation = ceil(self.range/2)
			local val = value or self:GetValue()

			local newmin = min(max(self.min, val - deviation), self.max)
			local newmax = max(min(self.max, val + deviation), self.min)
			--newmax = min(newmax, self.max)

			self:SetMinMaxValues_base(newmin, newmax)
		else
			self:SetMinMaxValues_base(self.min, self.max)
		end
	end,


	SaveSetting = function(self)
		local settings = self:GetSettingTable()

		if settings and self.setting then
		
			TMW:TT_Update(self.EditBoxShowing and self.EditBox or self)

			local value = self:GetValue()
			value = get(self.data.ModifySettingValue, self, value) or value
			
			settings[self.setting] = value
			
			IE:ScheduleIconSetup()
		end
	end,

	ReloadSetting = function(self)
		local settings = self:GetSettingTable()

		if settings and self.setting then
			self:SetValue(settings[self.setting])
			
			self:CheckInteractionStates()
		end
	end,
}

TMW:NewClass("Config_Slider_Alpha", "Config_Slider"){
	-- Constructor
	OnNewInstance_Slider_Alpha = function(self, data)
		self:SetMinMaxValues(0, 1)
		self:SetValueStep(0.01)
		
		local color = 34/0xFF
		self.Low:SetTextColor(color, color, color, 1)
		self.High:SetTextColor(color, color, color, 1)
	end,


	-- Script Handlers
	OnMinMaxChanged = function(self)
		local minValue, maxValue = self:GetMinMaxValues()
		
		self.Low:SetText(minValue * 100 .. "%")
		self.High:SetText(maxValue * 100 .. "%")
		
		self:UpdateTexts()
	end,

	METHOD_EXTENSIONS = {
		OnDisable = function(self)
			self:SetValue(0)
			self:UpdateTexts() -- For the initial disable, so text doesn't go orange
		end,
	},
	

	-- Methods
	FakeSetValue = function(self, value)
		self:SetValue(value)
	end,
	
	UpdateTexts = function(self)
		local value = self:GetValue()
				
		if value and self:IsEnabled() then
			if value == self.data.setOrangeAtValue then
				self.Mid:SetText("|cffff7400" .. value * 100 .. "%")
			else
				self.Mid:SetText(value * 100 .. "%")
			end
		else
			self.Mid:SetText(value * 100 .. "%")
		end
	end,
}


TMW:NewClass("Config_BitflagBase"){
	-- Constructor
	OnNewInstance_BitflagBase = function(self, data)
		if data.bit then
			self.bit = data.bit
		end

		if data.bit then
			self.bit = data.bit
		else
			local bitID = data.value or self:GetID()
			assert(bitID, "Couldn't figure out what bit " .. self:GetName() .. " is supposed to operate on!")
			
			self.bit = bit.lshift(1, (data.value or self:GetID()) - 1)
		end
	end,


	-- Script Handlers
	OnClick = function(self, button)	
		local settings = self:GetSettingTable()

		if settings and self.setting then
			settings[self.setting] = bit.bxor(settings[self.setting], self.bit)
			
			IE:ScheduleIconSetup()
		end
		
		-- Cheater! (We arent getting anything)
		-- (I'm using get as a wrapper so I don't have to check if the function exists before calling it)
		get(self.data.OnClick, self, button) 
	end,
	

	-- Methods
	ReloadSetting = function(self)
		local settings = self:GetSettingTable()

		if settings then
			self:SetChecked(bit.band(settings[self.setting], self.bit) == self.bit)
		end
		
		self:CheckInteractionStates()
	end,
}

TMW:NewClass("Config_CheckButton_BitToggle", "Config_BitflagBase", "Config_CheckButton")

TMW:NewClass("Config_Frame_WhenChecks", "Config_Frame"){
	-- Constructor
	OnNewInstance_Frame_WhenChecks = function(self, data)
		local data = self.data
		
		-- ShowWhen toggle
		assert(data.bit, "SettingWhenCheckSet's data table must declare a bit flag to be toggled in ics.ShowWhen! (data.bit)")
		
		self.Check.tmwClass = "Config_CheckButton_BitToggle"
		TMW:CInit(self.Check, {
			setting = "ShowWhen",
			bit = data.bit,
		})
		
		
		-- Alpha slider
		assert(data.alphaSettingName, "SettingWhenCheckSet's data table must declare an alpha setting to be used! (data.alphaSettingName)")
		
		TMW:CInit(self.Alpha, {
			setting = data.alphaSettingName,
			setOrangeAtValue = data.setOrangeAtValue or 0,
			disabled = function(self)
				local ics = TMW.CI.ics
				if ics then
					return bit.band(ics.ShowWhen, data.bit) == 0
				end
			end,
		})
		
		-- Reparent the label text on the slider so that it will be at full opacity even while disabled.
		self.Alpha.text:SetParent(self)

		TMW:RegisterCallback("TMW_CONFIG_PANEL_SETUP", self)
	end,
	

	-- Script Handlers
	OnEnable = function(self)
		self.Check:CheckInteractionStates()
		self.Alpha:CheckInteractionStates()
	end,
	
	OnDisable = function(self)
		self.Check:Disable()
		self.Alpha:Disable()
	end,
	

	-- Methods
	TMW_CONFIG_PANEL_SETUP = function(self, event, frame, panelInfo)
		if frame == self:GetParent() then
			local supplementalData = panelInfo.supplementalData
			
			assert(supplementalData, "Supplemental data (arg5 to RegisterConfigPanel_XMLTemplate) must be provided for TellMeWhen_WhenChecks!")
			
			-- Set the title for the frame
			frame.Header:SetText(supplementalData.text)
			
			-- Numeric keys in supplementalData point to the tables that have the data for that specified bit toggle
			local supplementalDataForBit = supplementalData[self.data.bit]
			if supplementalDataForBit then
				self.Check:SetTooltip(
					L["ICONMENU_SHOWWHEN_SHOWWHEN_WRAP"]:format(supplementalDataForBit.text),
					supplementalDataForBit.tooltipText or L["ICONMENU_SHOWWHEN_SHOW_GENERIC_DESC"]
				)
				
				self.Alpha.text:SetText(supplementalDataForBit.text)
				self.Alpha:SetTooltip(
					L["ICONMENU_SHOWWHEN_OPACITYWHEN_WRAP"]:format(supplementalDataForBit.text),
					supplementalDataForBit.tooltipText or L["ICONMENU_SHOWWHEN_OPACITY_GENERIC_DESC"]
				)
				self:Show()
			else
				self:Hide()
			end
		end
	end,

	ReloadSetting = function(self)
		-- Bad Things happen if this isn't defined
	end,
}


TMW:NewClass("Config_ColorButton", "Button", "Config_Frame"){
	
	OnNewInstance_ColorButton = function(self, data)
		assert(self.background1 and self.text and self.swatch, 
			"This setting frame doesn't inherit from the thing that it should have inherited from")

		self.text:SetText(get(data.label or data.title))
	end,
	
	OnClick = function(self, button)
		local settings = self:GetSettingTable()

		local prevRGBA = {self:GetRGBA()}
		self.prevRGBA = prevRGBA

		self:GenerateMethods()

		ColorPickerFrame.func = self.colorFunc
		ColorPickerFrame.opacityFunc = self.colorFunc
		ColorPickerFrame.cancelFunc = self.cancelFunc

		ColorPickerFrame:SetColorRGB(unpack(prevRGBA))
		ColorPickerFrame.hasOpacity = self.data.hasOpacity
		ColorPickerFrame.opacity = 1 - prevRGBA[4]

		ColorPickerFrame:Show()
	end,

	-- We have to do this for these to have access to self.
	GenerateMethods = function(self)
		self.colorFunc = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = 1 - OpacitySliderFrame:GetValue()

			self:SetRGBA(r, g, b, a)

			self:ReloadSetting()

			TMW.IE:ScheduleIconSetup()
		end

		self.cancelFunc = function()
			self:SetRGBA(unpack(self.prevRGBA))

			self:ReloadSetting()

			TMW.IE:ScheduleIconSetup()
		end

		self.GenerateMethods = TMW.NULLFUNC
	end,

	ReloadSetting = function(self)
		local settings = self:GetSettingTable()

		if settings then
			self.swatch:SetTexture(self:GetRGBA())

			self:CheckInteractionStates()
		end
	end,

	GetRGBA = function(self)
		if self.data.GetRGBA then
			return self.data.GetRGBA(self)
		else
			local settings = self:GetSettingTable()
			local c = settings[self.setting]
			return c.r, c.g, c.b, c.a
		end
	end,

	SetRGBA = function(self, r, g, b, a)
		if self.data.SetRGBA then
			return self.data.SetRGBA(self, r, g, b, a)
		else
			local settings = self:GetSettingTable()
			local c = settings[self.setting]

			c.r, c.g, c.b, c.a = r, g, b, a
		end
	end,
}

TMW:NewClass("Config_Button_Rune", "Button", "Config_BitflagBase", "Config_Frame"){
	-- Constructor
	Runes = {
		"Blood",
		"Unholy",
		"Frost",
	},

	OnNewInstance_Button_Rune = function(self, data)
		self.runeNumber = data.value or self:GetID()

		-- detect what texture should be used
		local runeType = ((self.runeNumber-1)%6)+1 -- gives 1, 2, 3, 4, 5, 6
		local runeName = self.Runes[ceil(runeType/2)] -- Gives "Blood", "Unholy", "Frost"
		
		if self.runeNumber > 6 then
			self.texture:SetTexture("Interface\\AddOns\\TellMeWhen\\Textures\\" .. runeName)
		else
			self.texture:SetTexture("Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-" .. runeName)
		end

		self.bit = bit.lshift(1, self.runeNumber - 1)
	end,


	-- Methods
	checked = false,
	GetChecked = function(self)
		return self.checked
	end,

	SetChecked = function(self, checked)
		self.checked = checked
		if checked then
			self.Check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
		else
			self.Check:SetTexture(nil)
		end
	end,
}



function IE:BuildSimpleCheckSettingFrame(parent, arg2, arg3)
	local className, allData, objectType
	if arg3 ~= nil then
		allData = arg3
		className = arg2
	else
		allData = arg2
		className = "Config_CheckButton"
	end
	local class = TMW.Classes[className]
	local objectType = class.isFrameObject
	
	assert(class, "Couldn't find class named " .. className .. ".")
	assert(type(objectType) == "string", "Couldn't find a WoW frame object type for class named " .. className .. ".")
	assert(type(className) == "string", "Usage: IE:BuildSimpleCheckSettingFrame(parent, [, className], allData)")
	assert(type(allData) == "table", "Usage: IE:BuildSimpleCheckSettingFrame(parent, [, className], allData)")
	
	
	local lastCheckButton
	local numFrames = 0
	local numPerRow = allData.numPerRow or min(#allData, 2)
	for i, data in ipairs(allData) do
		if data ~= nil and data ~= false then -- skip over nils/false (dont freak out about them, they are probably intentional)
		
			assert(type(data) == "table", "All values in allData must be tables!")
			
			local setting = data.setting -- the setting that the check will handle
			-- the setting is used by the current icon type, and doesnt have an override that is "hiding" the check, so procede to set it up
			
			-- An human-friendly-ish unique (hopefully) identifier for the frame
			local identifier = setting .. (data.value ~= nil and tostring(data.value) or "")
			
			local f = parent[identifier]
			if not f then
				f = class:New(objectType, parent:GetName() .. identifier, parent, "TellMeWhen_CheckTemplate", nil, data)
				parent[identifier] = f
				parent[i] = f
			end
			
			if lastCheckButton then
				-- Anchor it to the previous check if it isn't the first one.
				if numFrames%numPerRow == 0 then
					f:SetPoint("TOP", parent[i-numPerRow], "BOTTOM", 0, 2)
				else
					-- This will get overwritten soon.
					--f:SetPoint("LEFT", "RIGHT", 5, 0)
				end
			else
				-- Anchor the first check to the parent. The left anchor will be handled by DistributeFrameAnchorsLaterally.
				f:SetPoint("TOP", 0, -1)
			end
			lastCheckButton = f
			
			f.row = ceil(i/numPerRow)
			
			numFrames = numFrames + 1
		end
	end
	
	-- Set the bounds of the label text on all the checkboxes to prevent overlapping.
	for i = 1, #parent do
		local f0 = parent[i]
		local f1 = parent[i+1]
		
		if not f1 or f1.row ~= f0.row then
			f0:ConstrainLabel(parent, "RIGHT", -1, 0)
		else
			f0:ConstrainLabel(f1)
		end
	end
	
	TMW:RegisterCallback("TMW_CONFIG_ICON_LOADED", function()
		for i = 1, #parent, numPerRow do
			IE:DistributeFrameAnchorsLaterally(parent, numPerRow, unpack(parent, i))
		end		
	end)
	
	parent:SetHeight(ceil(numFrames/numPerRow)*30)
	
	return parent
end

function IE:SaveSettings()	
	TMW:Fire("TMW_CONFIG_SAVE_SETTINGS")
	if CI.icon then
		TMW.safecall(CI.icon.Setup, CI.icon)
	end
end


---------- Equivalancies ----------
function IE:Equiv_GenerateTips(equiv)
	local IDs = TMW:SplitNames(TMW.EquivFullIDLookup[equiv])
	local original = TMW:SplitNames(TMW.EquivOriginalLookup[equiv])

	for k, v in pairs(IDs) do
		local name, _, texture = GetSpellInfo(v)
		if not name then
			if TMW.debug then
				TMW:Error("INVALID ID FOUND: %s:%s", equiv, v)
				name = "INVALID " .. v
			else
				name = v
			end
			texture = "Interface\\Icons\\INV_Misc_QuestionMark"
		end

		-- If this spell is tracked only by ID, add the ID in parenthesis
		local originalSpell = tostring(original[k])
		if originalSpell:sub(1, 1) ~= "_" then
			name = format("%s |cff7f6600(%d)|r", name, originalSpell)
		end

		tiptemp[name] = tiptemp[name] or "|T" .. texture .. ":0|t" .. name
	end

	local r = ""
	for name, line in TMW:OrderedPairs(tiptemp) do
		r = r .. line .. "\r\n"
	end

	r = strtrim(r, "\r\n ;")
	wipe(tiptemp)
	return r
end
TMW:MakeSingleArgFunctionCached(IE, "Equiv_GenerateTips")


---------- Dropdowns ----------
function IE:Type_DropDown()
	for _, typeData in ipairs(TMW.OrderedTypes) do
		if CI.ics.Type == typeData.type or not get(typeData.hidden) then
			if typeData.menuSpaceBefore then
				TMW.DD:AddSpacer()
			end

			local info = TMW.DD:CreateInfo()
			
			info.text = get(typeData.name)
			info.value = typeData.type
			
			local allowed = typeData:IsAllowedByView(CI.icon.viewData.view)
			info.disabled = not allowed

			local desc = get(typeData.desc)
				
			if not allowed then
				desc = (desc and desc .. "\r\n\r\n" or "") .. L["ICONMENU_TYPE_DISABLED_BY_VIEW"]:format(CI.icon.viewData.name)
			end

			if typeData.canControlGroup then
				desc = (desc and desc .. "\r\n\r\n" or "") .. L["ICONMENU_TYPE_CANCONTROL"]
			end

			if desc then
				info.tooltipTitle = typeData.tooltipTitle or info.text
				info.tooltipText = desc
				info.tooltipWhileDisabled = true
			end
			
			info.checked = (info.value == CI.ics.Type)
			info.func = IE.Type_Dropdown_OnClick
			info.arg1 = typeData
			
			info.icon = get(typeData.menuIcon)
			info.tCoordLeft = 0.07
			info.tCoordRight = 0.93
			info.tCoordTop = 0.07
			info.tCoordBottom = 0.93
				
			TMW.DD:AddButton(info)

			if typeData.menuSpaceAfter then
				TMW.DD:AddSpacer()
			end
		end
	end
end

function IE:Type_Dropdown_OnClick()
	-- Automatically enable the icon when the user chooses an icon type
	-- when the icon was of the default (unconfigured) type.
	if CI.ics.Type == "" then
		CI.ics.Enabled = true
	end

	CI.icon:SetInfo("texture", nil)

	local oldType = CI.ics.Type
	CI.ics.Type = self.value

	TMW:Fire("TMW_CONFIG_ICON_TYPE_CHANGED", CI.icon, CI.ics.Type, oldType)
	
	CI.icon:Setup()
	
	IE:Load(1)
end


---------- Tooltips ----------
--local cachednames = {}
function IE:GetRealNames(Name)
	-- gets a table of all of the spells names in the name box in the IE. Splits up equivalancies and turns IDs into names

	local outTable = {}

	local text = TMW:CleanString(Name)
	
	local CI_typeData = Types[CI.ics.Type]
	local checksItems = CI_typeData.checksItems
	
	-- Note 11/12/12 (WoW 5.0.4) - caching causes incorrect results with "replacement spells" after switching specs like the corruption/immolate pair 
	--if cachednames[CI.ics.Type .. SoI .. text] then return cachednames[CI.ics.Type .. SoI .. text] end

	local tbl
	if checksItems then
		tbl = TMW:GetItems(text)
	else
		tbl = TMW:GetSpells(text).Array
	end
	local durations = TMW:GetSpells(text).Durations

	local Cache = TMW:GetModule("SpellCache"):GetCache()
	
	for k, v in pairs(tbl) do
		local name, texture
		if checksItems then
			name = v:GetName() or v.what or ""
			texture = v:GetIcon()
		else
			name, _, texture = GetSpellInfo(v)
			texture = texture or GetSpellTexture(name or v)
			
			if not name and Cache then
				local lowerv = strlower(v)
				for id, lowername in pairs(Cache) do
					if lowername == lowerv then
						local newname, _, newtex = GetSpellInfo(id)
						name = newname
						if not texture then
							texture = newtex
						end
						break
					end
				end
			end
			
			name = name or v or ""

			texture = texture or GetSpellTexture(name)
		end

		local dur = ""
		if CI_typeData.DurationSyntax or durations[k] > 0 then
			dur = ": "..TMW:FormatSeconds(durations[k])
		end

		local str = (texture and ("|T" .. texture .. ":0|t") or "") .. name .. dur

		if type(v) == "number" and tonumber(name) ~= v then
			str = str .. format(" |cff7f6600(%d)|r", v)
		end

		tinsert(outTable,  str)
	end

	return outTable
end

function GameTooltip:TMW_AddSpellBreakdown(tbl)
	if #tbl <= 0 then
		return
	end

	GameTooltip:AddLine(" ")

	local numLines = GameTooltip:NumLines()
	
	-- Need to do this so that we can get the widths of the lines.
	GameTooltip:Show()
	
	
	local longest = 100
	for i = 1, numLines do
		longest = max(longest, _G["GameTooltipTextLeft" .. i]:GetWidth())
	end


	-- Completely unscientific adjustment to prevent extremely tall tooltips:
	longest = max(longest, #tbl*3)

	
	local numLines = numLines + 1
	
	local i = 1
	
	while i <= #tbl do
		while _G["GameTooltipTextLeft" .. numLines]:GetStringWidth() < longest and i <= #tbl do
			local fs = _G["GameTooltipTextLeft" .. numLines]
			local s = tostring(tbl[i]):trim(" ")
			if fs:GetText() == nil then
				GameTooltip:AddLine(s, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, nil)
			else
				fs:SetText(fs:GetText() .. "; " .. s)
			end
			i = i + 1
		end
		numLines = numLines + 1
	end
end


---------- Icon Update Scheduler ----------
function IE:ScheduleIconSetup(icon)
	-- this is a handler to prevent the spamming of icon:Setup().
	if not icon then
		icon = CI.icon
	end

	if not TMW.tContains(IE.iconsToUpdate, icon) then
		tinsert(IE.iconsToUpdate, icon)
	end
end






-- -----------------------
-- IMPORT/EXPORT
-- -----------------------

---------- High-level Functions ----------
function TMW:Import(SettingsItem, ...)
	local settings = SettingsItem.Settings
	local version = SettingsItem.Version
	local type = SettingsItem.Type

	assert(settings, "Missing settings to import")
	assert(version, "Missing version of settings")
	assert(type, "No settings type specified!")

	TMW.DD:CloseDropDownMenus()

	TMW:Fire("TMW_IMPORT_PRE", SettingsItem, ...)
	
	local SharableDataType = TMW.approachTable(TMW, "Classes", "SharableDataType", "types", SettingsItem.Type)
	if SharableDataType and SharableDataType.Import_ImportData then
		SharableDataType:Import_ImportData(SettingsItem, ...)

		TMW:Update()
		IE:Load(1)
		
		TMW:Print(L["IMPORT_SUCCESSFUL"])
	else
		TMW:Print(L["IMPORTERROR_INVALIDTYPE"])
	end

	TMW:Fire("TMW_IMPORT_POST", SettingsItem, ...)
	
	TMW.ACEOPTIONS:CompileOptions()
	TMW.ACEOPTIONS:NotifyChanges()
end

function TMW:ImportPendingConfirmation(SettingsItem, luaDetections, callArgsAfterSuccess)
	TellMeWhen_ConfirmImportedLuaDialog:StartConfirmations(SettingsItem, luaDetections, callArgsAfterSuccess)
end

---------- Serialization ----------
function TMW:SerializeData(data, type, ...)
	-- nothing more than a wrapper for AceSerializer-3.0
	assert(data, "No data to serialize!")
	assert(type, "No data type specified!")
	return TMW:Serialize(data, TELLMEWHEN_VERSIONNUMBER, " ~", type, ...)
end

function TMW:MakeSerializedDataPretty(string)
	return string:
	gsub("(^[^tT%d][^^]*^[^^]*)", "%1 "): -- add spaces between tables to clean it up a little
	gsub("~J", "~J "): -- ~J is the escape for a newline
	gsub("%^ ^", "^^") -- remove double space at the end
end

function TMW:DeserializeDatum(string)
	local success, data, version, spaceControl, type = TMW:Deserialize(string)
	
	if not success or not data then
		-- corrupt/incomplete string
		return nil
	end

	if spaceControl then
		if spaceControl:find("`|") then
			-- EVERYTHING is fucked up. try really hard to salvage it. It probably won't be completely successful
			return TMW:DeserializeDatum(string:gsub("`", "~`"):gsub("~`|", "~`~|"))
		elseif spaceControl:find("`") then
			-- if spaces have become corrupt, then reformat them and... re-deserialize (lol)
			return TMW:DeserializeDatum(string:gsub("`", "~`"))
		elseif spaceControl:find("~|") then
			-- if pipe characters have been screwed up by blizzard's cute little method of escaping things combined with AS-3.0's cute way of escaping things, try to fix them.
			return TMW:DeserializeDatum(string:gsub("~||", "~|"))
		end
	end

	if not version then
		-- if the version is not included in the data,
		-- then it must have been before the first version that included versions in export strings/comm,
		-- so just take a guess that it was the first version that had version checks with it.
		version = 41403
	end

	if version <= 45809 and not type and data.Type then
		-- 45809 was the last version to contain untyped data messages.
		-- It only supported icon imports/exports, so the type has to be an icon.
		type = "icon"
	end

	if version <= 60032 and type == "global" then
		-- 60032 was the last version that used "global" as the identifier for "profile"
		type = "profile"
	end

	if not TMW.Classes.SharableDataType.types[type] then
		-- unknown data type
		return nil
	end


	-- finally, we have everything we need. create a result object and return it.
	local result = {
		data = data,
		type = type,
		version = version,
		select(6, TMW:Deserialize(string)), -- capture all extra args
	}

	return result
end

function TMW:DeserializeData(str)
	if not str then 
		return
	end

	local results

	str = gsub(str, "[%c ]", "")

	for string in gmatch(str, "(^%d+.-^^)") do
		results = results or {}

		local result = TMW:DeserializeDatum(string)

		tinsert(results, result)
	end

	return results
end


---------- Settings Manipulation ----------
function TMW:GetSettingsString(type, settings, defaults, ...)
	assert(settings, "No data to serialize!")
	assert(type, "No data type specified!")
	assert(defaults, "No defaults specified!")

	-- ... contains additional data that may or may not be used/needed
	settings = CopyTable(settings)
	settings = TMW:CleanSettings(type, settings, defaults)
	return TMW:SerializeData(settings, type, ...)
end

function TMW:GetSettingsStrings(strings, type, settings, defaults, ...)
	assert(settings, "No data to serialize!")
	assert(type, "No data type specified!")
	assert(defaults, "No defaults specified!")

	IE:SaveSettings()
	local strings = strings or {}

	local string = TMW:GetSettingsString(type, settings, defaults, ...)
	if not TMW.tContains(strings, string) then
		tinsert(strings, string)

		TMW:Fire("TMW_EXPORT_SETTINGS_REQUESTED", strings, type, settings)
	end

	TMW.tRemoveDuplicates(strings)

	return strings
end

function TMW:CleanDefaults(settings, defaults, blocker)
	-- make sure and pass in a COPY of the settings, not the original settings
	-- the following function is a slightly modified version of the one that AceDB uses to strip defaults.

	-- remove all metatables from the db, so we don't accidentally create new sub-tables through them
	setmetatable(settings, nil)
	-- loop through the defaults and remove their content
	for k,v in pairs(defaults) do
		if k == "*" or k == "**" then
			if type(v) == "table" then
				-- Loop through all the actual k,v pairs and remove
				for key, value in pairs(settings) do
					if type(value) == "table" then
						-- if the key was not explicitly specified in the defaults table, just strip everything from * and ** tables
						if defaults[key] == nil and (not blocker or blocker[key] == nil) then
							TMW:CleanDefaults(value, v)
							-- if the table is empty afterwards, remove it
							if next(value) == nil then
								settings[key] = nil
							end
						-- if it was specified, only strip ** content, but block values which were set in the key table
						elseif k == "**" then
							TMW:CleanDefaults(value, v, defaults[key])
						end
					end
				end
			elseif k == "*" then
				-- check for non-table default
				for key, value in pairs(settings) do
					if defaults[key] == nil and v == value then
						settings[key] = nil
					end
				end
			end
		elseif type(v) == "table" and type(settings[k]) == "table" then
			-- if a blocker was set, dive into it, to allow multi-level defaults
			TMW:CleanDefaults(settings[k], v, blocker and blocker[k])
			if next(settings[k]) == nil then
				settings[k] = nil
			end
		else
			-- check if the current value matches the default, and that its not blocked by another defaults table
			if settings[k] == defaults[k] and (not blocker or blocker[k] == nil) then
				settings[k] = nil
			end
		end
	end
	return settings
end

function TMW:CleanSettings(type, settings, defaults)
	return TMW:CleanDefaults(settings, defaults)
end


---------- Dropdown ----------


TMW:RegisterCallback("TMW_CONFIG_REQUEST_AVAILABLE_IMPORT_EXPORT_TYPES", function(event, editbox, import, export)
	if editbox == TMW.IE.ExportBox then	
		
		if IE.CurrentTab.doesGroup then	
			import.group_overwrite = CI.group
			export.group = CI.group
		end
		
		if IE.CurrentTab.doesIcon then
			import.icon = CI.icon
			export.icon = CI.icon
		end
	end
end)

TMW:RegisterCallback("TMW_CONFIG_REQUEST_AVAILABLE_IMPORT_EXPORT_TYPES", function(event, editbox, import, export)
	if editbox.IsImportExportWidget then
		local info = editbox.obj.userdata
		
		import.group_overwrite = TMW.FindGroupFromInfo(info)
		export.group = TMW.FindGroupFromInfo(info)
	end
end)






-- ----------------------
-- UNDO/REDO
-- ----------------------


IE.RapidSettings = {
	-- settings that can be changed very rapidly, i.e. via mouse wheel or in a color picker
	-- consecutive changes of these settings will be ignored by the undo/redo module
	r = true,
	g = true,
	b = true,
	a = true,
	Size = true,
	Level = true,
	Alpha = true,
	UnAlpha = true,
	GUID = true,
}
function IE:RegisterRapidSetting(setting)
	IE.RapidSettings[setting] = true
end

---------- Comparison ----------
function IE:GetCompareResultsPath(match, ...)
	if match then
		return true
	end
	local path = ""
	local setting
	for i, v in TMW:Vararg(...) do
		if i == 1 then
			setting = v
		end
		path = path .. v .. "."
	end
	return path, setting
end


---------- DoStuff ----------
function IE:AttemptBackup(icon)
	if not icon then return end

	if not icon.history then
		-- create the needed infrastructure for storing icon history if it does not exist.
		-- this includes creating the first history point
		icon.history = {TMW:CopyWithMetatable(icon:GetSettings())}
		icon.historyState = #icon.history

		-- notify the undo and redo buttons that there was a change so they can :Enable() or :Disable()
		IE:UndoRedoChanged()
	else
		-- the needed stuff for undo and redo already exists, so lets delve into the meat of the process.

		-- compare the current icon settings with what we have in the currently used history point
		-- the currently used history point may or may not be the most recent settings of the icon, but we want to check ics against what is being used.
		-- result is either (true) if there were no changes in the settings, or a string representing the key path to the first setting change that was detected.
		--(it was likely only one setting that changed, but not always)
		local result, changedSetting = IE:GetCompareResultsPath(TMW:DeepCompare(icon.history[icon.historyState], icon:GetSettings()))
		if type(result) == "string" then
			-- if we are using an old history point (i.e. we hit undo a few times and then made a change),
			-- delete all history points from the current one forward so that we dont jump around wildly when undoing and redoing
			for i = icon.historyState + 1, #icon.history do
				icon.history[i] = nil
			end

			-- if the last setting that was changed is the same as the most recent setting that was changed,
			-- and if the setting is one that can be changed very rapidly,
			-- delete the previous history point so that we dont murder our memory usage and piss off the user as they undo a number from 1 to 10, 0.1 per click.
			if icon.lastChangePath == result and IE.RapidSettings[changedSetting] and icon.historyState > 1 then
				icon.history[#icon.history] = nil
				icon.historyState = #icon.history
			end
			icon.lastChangePath = result

			-- finally, create the newest history point.
			-- we copy with with the metatable so that when doing comparisons against the current icon settings, we can invoke metamethods.
			-- this is needed because otherwise an empty event table (icon:GetSettings().Events) will not match a fleshed out one that has no non-default data in it.
			icon.history[#icon.history + 1] = TMW:CopyWithMetatable(icon:GetSettings())

			-- set the history state to the latest point
			icon.historyState = #icon.history
			-- notify the undo and redo buttons that there was a change so they can :Enable() or :Disable()
			IE:UndoRedoChanged()
			
			TMW:Fire("TMW_CONFIG_ICON_HISTORY_STATE_CREATED", icon)
		end
	end
end

function IE:DoUndoRedo(direction)
	local icon = CI.icon
	
	IE:UndoRedoChanged()

	if not icon.history[icon.historyState + direction] then return end -- not valid, so don't try

	icon.historyState = icon.historyState + direction

	TMW.CI.gs.Icons[CI.icon.ID] = nil -- recreated when passed into CTIPWM
	TMW:CopyTableInPlaceWithMeta(icon.history[icon.historyState], CI.ics)
	
	CI.icon:Setup() -- do an immediate setup for good measure
	
	TMW:Fire("TMW_CONFIG_ICON_HISTORY_STATE_CHANGED", icon)

	TMW.DD:CloseDropDownMenus()
	IE:Load(1)
	
	IE:UndoRedoChanged()
end


---------- Interface ----------
function IE:UndoRedoChanged()
	if not IE.CurrentTab or not IE.CurrentTab.doesIcon then
		IE.UndoButton:Disable()
		IE.RedoButton:Disable()

		return
	end

	local icon = CI.icon

	if icon then
		if not icon.historyState or icon.historyState - 1 < 1 then
			IE.UndoButton:Disable()
		else
			IE.UndoButton:Enable()
		end

		if not icon.historyState or icon.historyState + 1 > #icon.history then
			IE.RedoButton:Disable()
		else
			IE.RedoButton:Enable()
		end
	end
end


---------- Back/Fowards ----------
function IE:DoBackForwards(direction)
	if not IE.history[IE.historyState + direction] then return end -- not valid, so don't try

	IE.historyState = IE.historyState + direction

	TMW.DD:CloseDropDownMenus()
	IE:Load(nil, IE.history[IE.historyState], true)

	IE:BackFowardsChanged()
end

function IE:BackFowardsChanged()
	if IE.historyState - 1 < 1 then
		IE.BackButton:Disable()
		IE.CanBack = false
	else
		IE.BackButton:Enable()
		IE.CanBack = true
	end

	if IE.historyState + 1 > #IE.history then
		IE.ForwardsButton:Disable()
		IE.CanFowards = false
	else
		IE.ForwardsButton:Enable()
		IE.CanFowards = true
	end
end







-- ----------------------
-- CHANGELOG
-- ----------------------

function IE:CreateChangelogDialog()
	if not TellMeWhen_ChangelogDialog then
		CreateFrame("Frame", "TellMeWhen_ChangelogDialog", UIParent, "TellMeWhen_ChangelogDialogTemplate")
	end

	return TellMeWhen_ChangelogDialog
end

local changelogEnd = "<p align='center'>|cff666666To see the changelog for versions up to v" ..
(TMW.CHANGELOG_LASTVER or "???") .. ", type /tmw changelog.|r</p>"
local changelogEndAll = "<p align='center'>|cff666666For older versions, visit TellMeWhen's AddOn page on Curse.com|r</p>"

function IE:ShowChangelog(lastVer, showIEOnClose)
	if not lastVer then lastVer = 0 end

	local CHANGELOGS = IE:ProcessChangelogData()

	local dialog = IE:CreateChangelogDialog()
	dialog.showIEOnClose = showIEOnClose

	local texts = {}

	for version, text in TMW:OrderedPairs(CHANGELOGS, nil, nil, true) do
		if lastVer >= version then
			if lastVer > 0 then
				text = text:gsub("</h1>", " (" .. L["CHANGELOG_LAST_VERSION"] .. ")</h1>")
			end
				
			tinsert(texts, text)
			break
		else
			tinsert(texts, text)
		end
	end

	if lastVer > 0 then
		tinsert(texts, changelogEnd .. changelogEndAll)
	else
		tinsert(texts, changelogEndAll)
	end

	local body = format("<html><body>%s</body></html>", table.concat(texts, "<br/>"))
	dialog.scrollContainer.html:SetText(body)

	-- This has to be stored because there is no GetText method.
	dialog.scrollContainer.html.text = body

	if showIEOnClose then
		dialog.Okay:SetText(TMW.L["CHANGELOG_OKAY_OPENIE"])
	else
		dialog.Okay:SetText(OKAY)
	end

	dialog:Show()
end

local function htmlEscape(char)
	if char == "&" then
		return "&amp;"
	elseif char == "<" then
		return "&lt;"
	elseif char == ">" then
		return "&gt;"
	end
end

local bulletColors = {
	"4FD678",
	"2F99FF",
	"F62FAD",
}

local function bullets(b, text)
	local numDashes = #b 
	
	if numDashes <= 0 then
		return "><p>" .. text .. "</p><"
	end

	local color = bulletColors[(numDashes-1) % #bulletColors + 1]
	
	-- This is not a regular space. It is U+2002 - EN SPACE
	local dashes = (" "):rep(numDashes) .. "•"

	return "><p>|cFF" .. color .. dashes .. " |r" .. text .. "</p><"
end

local CHANGELOGS
function IE:ProcessChangelogData()
	if CHANGELOGS then
		return CHANGELOGS
	end

	CHANGELOGS = {}

	if not TMW.CHANGELOG then
		TMW:Error("There was an error loading TMW's changelog data.")
		TMW:Print("There was an error loading TMW's changelog data.")
	end

	local log = TMW.CHANGELOG

	log = log:gsub("([&<>])", htmlEscape)        
	log = log:trim(" \t\r\n")

	-- Replace 4 equals with h2
	log = log:gsub("[ \t]*====(.-)====[ \t]*", "<h2>%1</h2>")

	-- Replace 3 equals with h1, formatting as a version name
	log = log:gsub("[ \t]*===(.-)===[ \t]*", "<h1>TellMeWhen %1</h1>")

	-- Remove extra space after closing header tags
	log = log:gsub("(</h.>)%s*", "%1")

	-- Remove extra space before opening header tags.
	log = log:gsub("%s*(<h.>)", "%1")

	-- Convert newlines to <br/>
	log = log:gsub("\r\n", "<br/>")
	log = log:gsub("\n", "<br/>")

	-- Put a break at the end for the next gsub - it relies on a tag of some kind
	-- being at the end of each line.
	log = log .. "<br/>"

	-- Convert asterisks to colored dashes
	log = log:gsub(">%s*(*+)%s*(.-)<", bullets)

	-- Remove double breaks 
	log = log:gsub("<br/><br/>", "<br/>")

	-- Remove breaks between paragraphs
	log = log:gsub("</p><br/><p>", "</p><p>")

	-- Add breaks between paragraphs and h2ss
	-- Put an empty paragraph in since they are smaller than a full break.
	log = log:gsub("</p>%s*<h2>", "</p><p> </p><h2>")

	-- Add a "General" header before the first paragraph after an h1
	log = log:gsub("</h1>%s*<p>", "</h1><h2>General</h2><p>")


	local subStart, subEnd = 0, 0
	repeat
		local done

		-- Find the start of a version
		subStart, endH1 = log:find("<h1>", subEnd)

		-- Find the start of the next version
		subEnd = log:find("<h1>", endH1)

		if not subEnd then
			-- We're at the end of the data. Set the length of the data as the end position.
			subEnd = #log
			done = true
		else
			-- We want to end just before the start of the next version.
			subEnd = subEnd - 1
		end

		local versionString = log:match("TellMeWhen v([0-9%.]+)", subStart):gsub("%.", "")
		local versionNumber = tonumber(versionString) * 100
		
		-- A full version's changelog is between subStart and subEnd. Store it.
		CHANGELOGS[versionNumber] = log:sub(subStart, subEnd)
	until done

	-- Send this out to the garbage collector
	TMW.CHANGELOG = nil

	return CHANGELOGS
end


