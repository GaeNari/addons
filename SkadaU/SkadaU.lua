
local Skada = LibStub("AceAddon-3.0"):NewAddon("Skada", "AceTimer-3.0")
_G.Skada = Skada

local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0", true)
local media = LibStub("LibSharedMedia-3.0")
local lds = LibStub:GetLibrary("LibDualSpec-1.0", 1)
local dataobj = ldb:NewDataObject("Skada", {label = "Skada", type = "data source", icon = "Interface\\Icons\\Spell_Lightning_LightningBolt01", text = "n/a"})
local popup, cleuFrame

-- Used for automatic stop on wipe option
local deathcounter = 0
local startingmembers = 0

-- Ultimate Edition version info variables
SkadaRevision = 40
SkadaVersion = 1
local displayRevision = 141
local baseRevision = "r619"

local isKR = GetLocale() == "koKR"

do
	popup = CreateFrame("Frame", nil, UIParent) -- Recycle the popup frame as an event handler.
	popup:SetScript("OnEvent", function(frame, event, ...)
		Skada[event](Skada, ...)
	end)

	popup:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 1, right = 1, top = 1, bottom = 1}}
	)
	popup:SetSize(250, 70)
	popup:SetPoint("CENTER", UIParent, "CENTER")
	popup:SetFrameStrata("DIALOG")
	popup:Hide()

	local text = popup:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
	text:SetPoint("TOP", popup, "TOP", 0, -10)
	text:SetText(L["Do you want to reset Skada?"])

	local accept = CreateFrame("Button", nil, popup)
	accept:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
	accept:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
	accept:SetSize(50, 50)
	accept:SetPoint("BOTTOM", popup, "BOTTOM", -50, 0)
	accept:SetScript("OnClick", function(f) Skada:Reset() f:GetParent():Hide() end)

	local close = CreateFrame("Button", nil, popup)
	close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
	close:SetSize(50, 50)
	close:SetPoint("BOTTOM", popup, "BOTTOM", 50, 0)
	close:SetScript("OnClick", function(f) f:GetParent():Hide() end)
	function Skada:ShowPopup()
		popup:Show()
	end
end

-- Keybindings
BINDING_HEADER_Skada = "Skada"
BINDING_NAME_SKADA_TOGGLE = L["Toggle window"]
BINDING_NAME_SKADA_RESET = L["Reset"]
BINDING_NAME_SKADA_NEWSEGMENT = L["Start new segment"]
BINDING_NAME_SKADA_STOP = L["Stop"]

-- The current set
Skada.current = nil

-- The total set
Skada.total = nil

-- The last set
Skada.last = nil

-- Modes - these are modules, really. Modeules?
local modes = {}

-- Pets; an array of pets and their owners.
local pets, players = {}, {}

-- Flag marking if we need an update.
local changed = true

-- Flag for if we were in a party/raid.
local wasinparty = nil

-- By default we just use RAID_CLASS_COLORS as class colors.
Skada.classcolors = RAID_CLASS_COLORS

-- The selected data feed.
local selectedfeed = nil

-- A list of data feeds available. Modules add to it.
local feeds = {}

-- Disabled flag.
local disabled = false

-- Our windows.
local windows = {}

-- Our display providers.
Skada.displays = {}

-- Timer for updating windows.
local update_timer = nil
local supdate_timer = nil

-- Timer for checking for combat end.
local tick_timer = nil

-- Check in Combat
local inCombat = false

-- Check pet battle
local onPetBattle = false

-- Check instance status
local isInPvP = false
local isInRaid = false
local wasininstance
local wasinpvp

-- cleu variables
local combatlogevents = {}
local band = bit.band
local PET_FLAGS = bit.bor(COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN)
local RAID_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)

-- Boss combat variables
local inBossCombat = false
local encounterProgress = false
local currentSetEnabled = true
local lastEncounterName = nil
local lastEnd = 0
local esCallCount = 0

local bossModCombat = false
local bossModCallCount = 0

local mapId = 0
local disableEPdetectionMap = {}

-- Caches
local IsEncounterInProgress, InCombatLockdown, UnitName, UnitGUID, UnitAffectingCombat, UnitExists = IsEncounterInProgress, InCombatLockdown, UnitName, UnitGUID, UnitAffectingCombat, UnitExists
local BreakUpLargeNumbers, mf, nm = BreakUpLargeNumbers, math.floor, math.max

-- This flag is used to mark a possible combat start.
local tentative = nil
local requiredTentativeCount = 0

-- AceTimer handle.
local tentativehandle = nil
local currentSetEnabler = nil
local ieeuEncounterCheker = nil

function Skada:GetWindows()
	return windows
end

local function find_mode(name)
	for i, mode in ipairs(modes) do
		if mode:GetName() == name then
			return mode
		end
	end
end

-- Our window type.
local Window = {}

local mt = {__index = Window}

function Window:new()
	return setmetatable(
		{
			-- The selected mode and set
			selectedmode = nil,
			selectedset = nil,

			-- Mode and set to return to after combat.
			restore_mode = nil,
			restore_set = nil,

			usealt = true,

			-- Our dataset.
			dataset = {},

			-- Metadata about our dataset.
			metadata = {},

			-- Our display provider.
			display = nil,

			-- Our mode traversing history.
			history = {},

			-- Mode data
			modedata = {},

			-- Flag for window-specific changes.
			changed = false,

		}, mt)
end

function Window:AddOptions()
	local db = self.db

	local options = {
			type="group",
			name=function() return db.name end,
			args={

				rename = {
					type="input",
					name=L["Rename window"],
					desc=L["Enter the name for the window."],
					get=function() return db.name end,
					set=function(win, val) 
						if val ~= db.name and val ~= "" then 
							local oldname = db.name
							db.name = val 
							Skada.options.args.windows.args[val] = Skada.options.args.windows.args[oldname]
							Skada.options.args.windows.args[oldname] = nil
						end 
					end,
					order=1,
				},

				locked = {
					type="toggle",
					name=L["Lock window"],
					desc=L["Locks the bar window in place."],
					order=2,
					get=function() return db.barslocked end,
					set=function()
						db.barslocked = not db.barslocked
						Skada:ApplySettings()
					end,
				},

				delete = {
					type="execute",
					name=L["Delete window"],
					desc=L["Deletes the chosen window."],
					order=20,
					width="full",
					confirm=function() return L["Are you sure you want to delete this window?"] end,
					func=function(self) Skada:DeleteWindow(db.name) end,
				},

			}
	}

	options.args.switchoptions = {
		type = "group",
		name = L["Mode switching"],
		order=4,
		args = {

			modeincombat = {
				type="select",
				name=L["Combat mode"],
				desc=L["Automatically switch to set 'Current' and this mode when entering combat."],
				values=function()
					local modes = {}
					modes[""] = L["None"]
					for i, mode in ipairs(Skada:GetModes()) do
						modes[mode:GetName()] = mode:GetName()
					end
					return modes
				end,
				get=function() return db.modeincombat end,
				set=function(win, mode) db.modeincombat = mode end,
				order=21,
			},

			wipemode = {
				type="select",
				name=L["Wipe mode"],
				desc=L["Automatically switch to set 'Current' and this mode after a wipe."],
				values=function()
					local modes = {}
					modes[""] = L["None"]
					for i, mode in ipairs(Skada:GetModes()) do
						modes[mode:GetName()] = mode:GetName()
					end
					return modes
				end,
				get=function() return db.wipemode end,
				set=function(win, mode) db.wipemode = mode end,
				order=21,
			},
			returnaftercombat = {
				type="toggle",
				name=L["Return after combat"],
				desc=L["Return to the previous set and mode after combat ends."],
				order=23,
	 			get=function() return db.returnaftercombat end,
		 		set=function() db.returnaftercombat = not db.returnaftercombat end,
		 		disabled=function() return db.returnaftercombat == nil end,
			},
		}
	}

	self.display:AddDisplayOptions(self, options.args)

	Skada.options.args.windows.args[self.db.name] = options
end

-- Sets a slave window for this window. This window will also be updated on view updates.
function Window:SetChild(window)
	self.child = window
end

function Window:destroy()
	self.dataset = nil

	self.display:Destroy(self)

	local name = self.db.name or Skada.windowdefaults.name
	Skada.options.args.windows.args[name] = nil -- remove from options
end

function Window:SetDisplay(name)
	-- Don't do anything if nothing actually changed.
	if name ~= self.db.display or self.display == nil then
		if self.display then
			-- Destroy old display.
			self.display:Destroy(self)
		end

		-- Set new display.
		self.db.display = name
		self.display = Skada.displays[self.db.display]

		-- Add options. Replaces old options.
		self:AddOptions()
	end
end

-- Tells window to update the display of its dataset, using its display provider.
function Window:UpdateDisplay()
	-- Fetch max value if our mode has not done this itself.
	if not self.metadata.maxvalue then
		self.metadata.maxvalue = 1
	end

	-- Display it.
	self.display:Update(self)
	self:set_mode_title()
end

function Window:Show()
	self.display:Show(self)
end

function Window:Hide()
	self.display:Hide(self)
end

function Window:IsShown()
	return self.display:IsShown(self)
end

function Window:Reset()
	wipe(self.dataset)
	self.totalvalue = nil
end

function Window:Wipe()
	-- Clear dataset.
	self:Reset()

	-- Clear display.
	self.display:Wipe(self)

	if self.child then
		self.child:Wipe()
	end
end

-- If selectedset is "current", returns current set if we are in combat, otherwise returns the last set.
function Window:get_selected_set()
	return Skada:find_set(self.selectedset)
end

-- Sets up the mode view.
function Window:DisplayMode(mode)
	if not self.history then
		self.history = {}
	end
	self:Wipe()

	local set = self.selectedset or self.db.set or "current"

	--settime format changed. check bad set variable.
	local chk = tonumber(set)
	if chk and ((chk > 30) or not Skada:find_set(chk)) then
		self.selectedset = "current"
		self.db.set = "current"
	elseif chk then
		self.selectedset = chk
		self.db.set = chk
	else
		self.selectedset = set
		self.db.set = set
	end

	self.selectedmode = mode
	if not mode.Enter then
		self.history = wipe(self.history or {})
		self.db.mode = mode:GetName()
	end
	self.metadata = wipe(self.metadata or {})

	-- Apply mode's metadata.
	if mode.metadata then
		for key, value in pairs(mode.metadata) do
			self.metadata[key] = value
		end
	end

	self.changed = true
	self:set_mode_title() -- in case data sets are empty

	if self.child then
		self.child:DisplayMode(mode)
	end

	Skada:UpdateDisplay(false)
end

local numsetfmts = 8
local function SetLabelFormat(name,starttime,endtime,fmt)
	fmt = fmt or Skada.db.profile.setformat
	local namelabel = name
	if fmt < 1 or fmt > numsetfmts then fmt = 3 end
	local timelabel = ""
	if starttime and endtime and fmt > 1 then
		local duration = SecondsToTime(endtime-starttime, false, false, 2)
		if duration == "" then
			duration = "0"..SECONDS
		end
		-- translate locale time abbreviations, whose escape sequences are not legal in chat
		Skada.getsetlabel_fs = Skada.getsetlabel_fs or UIParent:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
		Skada.getsetlabel_fs:SetText(duration)
		duration = "("..duration..")"

		if fmt == 2 then
			timelabel = duration
		elseif fmt == 3 then
			timelabel = date("%H:%M",starttime).." "..duration
		elseif fmt == 4 then
			timelabel = date("%I:%M",starttime).." "..duration
		elseif fmt == 5 then
			timelabel = date("%H:%M",starttime).." - "..date("%H:%M",endtime)
		elseif fmt == 6 then
			timelabel = date("%I:%M",starttime).." - "..date("%I:%M",endtime)
		elseif fmt == 7 then
			timelabel = date("%H:%M:%S",starttime).." - "..date("%H:%M:%S",endtime)
		elseif fmt == 8 then
			timelabel = date("%H:%M",starttime).." - "..date("%H:%M",endtime).." "..duration
		end
	end

	local comb
	if #namelabel == 0 or #timelabel == 0 then
		comb = namelabel..timelabel
	elseif timelabel:match("^%p") then
		comb = namelabel.." "..timelabel
	else
		comb = namelabel..": "..timelabel
	end
	-- provide both the combined label and the separated name/time labels
	return comb, namelabel, timelabel
end

function Skada:SetLabelFormats() -- for config option display
	local ret = {}
	local start = 1000007900
	for i=1,numsetfmts do
		ret[i] = SetLabelFormat("Hogger", start, start+380, i)
	end
	return ret
end

function Skada:GetSetLabel(set) -- return a nicely-formatted label for a set
	if not set then return "" end
	return SetLabelFormat(set.name or "Unknown", set.starttime, set.endtime or time())
end

function Window:set_mode_title()
	if not self.selectedmode or not self.selectedset then return end
	if self.selectedmode.NoTitleModify then return end
	local name = self.selectedmode.title or self.selectedmode:GetName()

	if self.db.titleset then
		local setname
		if self.selectedset == "current" then
			setname = L["Current"]
		elseif self.selectedset == "total" then
			setname = L["Total"]
		else
			local set = self:get_selected_set()
			if set then
				setname = Skada:GetSetLabel(set)
			end
		end
		if setname then
			name = name..": "..setname
		end
	end
	if disabled and (self.selectedset == "current" or self.selectedset == "total") then 
		-- indicate when data collection is disabled
		name = name.."  |cFFFF0000"..L["DISABLED"].."|r"
	end
	self.metadata.title = name
	self.display:SetTitle(self, name)
end

local function click_on_mode(win, id, label, button)
	if button == "LeftButton" then
		local mode = find_mode(id)
		if mode then
			win:DisplayMode(mode)
		end
	elseif button == "RightButton" then
		win:RightClick()
	end
end

-- Sets up the mode list.
function Window:DisplayModes(set)
	self.history = wipe(self.history or {})
	self:Wipe()

	--settime format changed. check bad set variable.
	local chk = tonumber(set)
	if chk and ((chk > 30) or not Skada:find_set(chk)) then
		self.selectedset = "current"
		self.db.set = "current"
	elseif chk then
		self.selectedset = chk
		self.db.set = chk
	else
		self.selectedset = set
		self.db.set = set
	end

	self.selectedmode = nil
	self.db.mode = nil

	self.metadata = wipe(self.metadata or {})

	self.metadata.title = L["Skada: Modes"]

	self.metadata.click = click_on_mode
	self.metadata.maxvalue = 1

	self.display:SetTitle(self, self.metadata.title)
	self.changed = true

	if self.child then
		self.child:DisplayModes(set)
	end

	Skada:UpdateDisplay(false)
end

local function click_on_set(win, id, label, button)
	if button == "LeftButton" then
		win:DisplayModes(id)
	elseif button == "RightButton" then
		win:RightClick()
	end
end

-- Sets up the set list.
function Window:DisplaySets(init)
	self.history = wipe(self.history or {})
	self:Wipe()

	self.metadata = wipe(self.metadata or {})

	self.selectedset = nil
	self.selectedmode = nil

	-- Save for posterity.
	if not init then
		self.db.set = nil
		self.db.mode = nil
	end

	self.metadata.title = L["Skada: Fights"]
	self.metadata.click = click_on_set
	self.metadata.maxvalue = 1
	self.changed = true

	if self.child then
		self.child:DisplaySets()
	end

	Skada:UpdateDisplay(false)
end

-- Default "right-click" behaviour in case no special click function is defined:
-- 1) If there is a mode traversal history entry, go to the last mode.
-- 2) Go to modes list if we are in a mode.
-- 3) Go to set list.
function Window:RightClick(group, button)
	if self.selectedmode then
		-- If mode traversal history exists, go to last entry, else mode list.
		if #self.history > 0 then
			self:DisplayMode(tremove(self.history))
		else
			self:DisplayModes(self.selectedset)
		end
	elseif self.selectedset then
		self:DisplaySets()
	end
end

function Skada:tcopy(to, from)
	for k,v in pairs(from) do
	if(type(v)=="table") then
		to[k] = {}
		Skada:tcopy(to[k], v);
	else
		to[k] = v;
	end
	end
end

function Skada:CreateWindow(name, db, display)
	if not db then
		db = {}
		self:tcopy(db, Skada.windowdefaults)
		table.insert(self.db.profile.windows, db)
	end
	if display then
		db.display = display
	end

	-- Migrate old settings.
	if not db.barbgcolor then
		db.barbgcolor = {r = 0.3, g = 0.3, b = 0.3, a = 0.6}
	end
	if not db.buttons then
		db.buttons = {menu = true, reset = true, report = true, mode = true, segment = true, stop = true}
	end
	if not db.scale then
		db.scale = 1
	end

	if not db.version then
		-- On changes that needs updates to window data structure, increment version in defaults and handle it after this bit.
		db.version = 1
		db.buttons.stop = true
	end

	local window = Window:new()
	window.db = db
	window.db.name = name

	if self.displays[window.db.display] then
		-- Set the window's display and call it's Create function.
		window:SetDisplay(window.db.display or "bar")

		window.display:Create(window)

		table.insert(windows, window)

		-- Set initial view, set list.
		window:DisplaySets(true)
		local rvscheduler = Skada:ScheduleTimer(function() Skada:RestoreView(window, window.db.set, window.db.mode) end, 1)
	else
		-- This window's display is missing.
		self:Print("Window '"..name.."' was not loaded because its display module, '"..window.db.display.."' was not found.")
	end

	return window
end

-- Deleted named window from our windows table, and also from db.
function Skada:DeleteWindow(name)
	for i, win in ipairs(windows) do
		if win.db.name == name then
			win:destroy()
			wipe(table.remove(windows, i))
		end
	end
	for i, win in ipairs(self.db.profile.windows) do
		if win.name == name then
			table.remove(self.db.profile.windows, i)
		end
	end
end

function Skada:Print(msg)
	print("|cFF33FF99Skada|r: "..msg)
end

function Skada:Debug(...)
	if not Skada.db.profile.debug then return end
	local msg = ""
	for i=1, select("#",...) do
		local v = tostring(select(i,...))
		if #msg > 0 then
			msg = msg .. ", "
		end
		msg = msg..v
	end
	print("|cFF33FF99Skada Debug|r: "..msg)
end

local function slashHandler(param)
	local reportusage = "/skada report [raid|party|instance|guild|officer|say] [current||total|set_num] [mode] [max_lines]"
	if param == "pets" then
		Skada:PetDebug()
	elseif param == "test" then
		Skada:OpenMenu()
	elseif param == "reset" then
		Skada:Reset()
	elseif param == "newsegment" then
		Skada:NewSegment()
	elseif param == "toggle" then
		Skada:ToggleWindow()
	elseif param == "debug" then
		Skada.db.profile.debug = not Skada.db.profile.debug
		Skada:Print("Debug mode "..(Skada.db.profile.debug and ("|cFF00FF00"..L["ENABLED"].."|r") or ("|cFFFF0000"..L["DISABLED"].."|r")))
	elseif param == "config" then
		InterfaceOptionsFrame_OpenToCategory(Skada.optionsFrame)
		InterfaceOptionsFrame_OpenToCategory(Skada.optionsFrame)
	elseif param:sub(1,6) == "report" then
		local chan = (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "instance") or
				(IsInRaid() and "raid") or
				(IsInGroup() and "party") or
				"say"
		local set = "current"
		local report_mode_name = L["Damage"]
		local w1, w2, w3, w4 = param:match("^%s*(%w*)%s*(%w*)%s*([^%d]-)%s*(%d*)%s*$",7)
		if w1 and #w1 > 0 then 
			chan = string.lower(w1)
		end
		if w2 and #w2 > 0 then
			w2 = tonumber(w2) or w2:lower()
			if Skada:find_set(w2) then 
				set = w2
			end
		end
		if w3 and #w3 > 0 then
			w3 = strtrim(w3)
			w3 = strtrim(w3,"'\"[]()") -- strip optional quoting
			if find_mode(w3) then 
				report_mode_name = w3
			end
		end
		local max = tonumber(w4) or 10

		if chan == "instance" then chan = "instance_chat" end
		if (chan == "say" or chan == "guild" or chan == "raid" or chan == "party" or chan == "officer" or chan == "instance_chat") then
			Skada:Report(chan, "preset", report_mode_name, set, max)
		else
			Skada:Print("Usage:")
			Skada:Print(("%-20s"):format(reportusage))
		end
	else
		Skada:Print("Usage:")
		Skada:Print(("%-20s"):format(reportusage))
		Skada:Print(("%-20s"):format("/skada reset"))
		Skada:Print(("%-20s"):format("/skada toggle"))
		Skada:Print(("%-20s"):format("/skada debug"))
		Skada:Print(("%-20s"):format("/skada newsegment"))
		Skada:Print(("%-20s"):format("/skada config"))
		print("<Version Info> Skada: Ultimate release "..displayRevision.."(based on "..baseRevision..")")
	end
end

local function sendchat(msg, chan, chantype)
	if chantype == "self" then
		-- To self.
		Skada:Print(msg)
	elseif chantype == "channel" then
		-- To channel.
		SendChatMessage(msg, "CHANNEL", nil, chan)
	elseif chantype == "preset" then
		-- To a preset channel id (say, guild, etc).
		SendChatMessage(msg, string.upper(chan))
	elseif chantype == "whisper" then
		-- To player.
		SendChatMessage(msg, "WHISPER", nil, chan)
	elseif chantype == "RealID" then
		BNSendWhisper(chan, msg)
	end
end

function Skada:Report(channel, chantype, report_mode_name, report_set_name, max, window)

	if (chantype == "channel") then
		local list = {GetChannelList()}
		for i=1,table.getn(list)/2 do
			if (Skada.db.profile.report.channel == list[i*2]) then
				channel = list[i*2-1]
				break
			end
		end
	end

	local report_table
	local report_set
	local report_mode
	if not window then
		report_mode = find_mode(report_mode_name)
		report_set = Skada:find_set(report_set_name)
		if report_set == nil then
			return
		end
		-- Create a temporary fake window.
		report_table = Window:new()

		-- Tell our mode to populate our dataset.
		report_mode:Update(report_table, report_set)
	else
		report_table = window
		report_set = window:get_selected_set()
		report_mode = window.selectedmode
	end

	if not report_set or not report_mode then
		Skada:Print(L["There is nothing to report."])
		return
	end

	-- Sort our temporary table according to value unless ordersort is set.
	if not report_table.metadata.ordersort then
		table.sort(report_table.dataset, Skada.valueid_sort)
	end

	-- Title
	sendchat(string.format(L["Skada: %s for %s:"], report_mode.title or report_mode:GetName(), Skada:GetSetLabel(report_set)), channel, chantype)

	-- For each item in dataset, print label and valuetext.
	local nr = 1
	for i, data in ipairs(report_table.dataset) do
		if data.id then
			local label
			if data.reportlabel then
				label = data.reportlabel
			elseif data.spellid then
				local link = GetSpellLink(data.spellid)
				local spell = GetSpellInfo(data.spellid)
				if data.label ~= spell then
					local name = data.label:match("^.+: ")
					local dot = data.label:match(L["DoT"]) and L[" (DoT)"]
					local hot = data.label:match(L["HoT"]) and L[" (HoT)"]
					label = (name or "")..link..(dot or "")..(hot or "")
				else
					label = link or data.label
				end
			else
				label = data.label
			end
			if data.label == L["Total"] and nr == 1 then
				nr = 0
			end
			if report_mode.metadata and report_mode.metadata.showspots then
				sendchat(("%2u. %s   %s"):format(nr, label, data.valuetext), channel, chantype)
			else
				sendchat(("%s   %s"):format(label, data.valuetext), channel, chantype)
			end
			nr = nr + 1
		end
		if nr > max then
			break
		end
	end

end

function Skada:RefreshMMButton()
	if icon then
		icon:Refresh("Skada", self.db.profile.icon)
		if self.db.profile.icon.hide then
			icon:Hide("Skada")
		else
			icon:Show("Skada")
		end
	end
end

function Skada:PetDebug()
	self:CheckGroup()
	self:Print("pets:")
	for pet, owner in pairs(pets) do
		self:Print("pet "..pet.." belongs to ".. owner.id..", "..owner.name)
	end
end

function Skada:SetActive(enable)
	if enable then
		for i, win in ipairs(windows) do
			win:Show()
		end
	else
		for i, win in ipairs(windows) do
			win:Hide()
		end
	end
	if not enable and self.db.profile.hidedisables then
		if not disabled then -- print a message when we change state
			self:Debug(L["Data Collection"].." ".."|cFFFF0000"..L["DISABLED"].."|r")
		end
		disabled = true
		cleuFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		if disabled then -- print a message when we change state
			self:Debug(L["Data Collection"].." ".."|cFF00FF00"..L["ENABLED"].."|r")
		end
		disabled = false
		cleuFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end

	Skada:UpdateDisplay(true) -- update title indicator
end

local groupUpdated = false
local groupUpdating = false

function Skada:CheckGroup()
	if not groupUpdating then
		groupUpdated = false
		groupUpdating = true
		table.wipe(players)
		local groupNum = GetNumGroupMembers()
		if IsInGroup() then
			local uId = (IsInRaid() and "raid") or "party"
			for i = 0, groupNum do
				local unit = (i == 0 and "player") or uId..i
				local name, server = UnitName(unit)
				local fullname
				if server and server ~= ""  then
					fullname = name.."-"..server
				end
				local playerGUID = UnitGUID(unit)
				if playerGUID and name and name ~= COMBATLOG_UNKNOWN_UNIT then
					players[playerGUID] = name
					local petGUID = UnitGUID(unit.."pet")
					if petGUID and not petGUID:match("Player") then
						pets[petGUID] = {id = playerGUID, name = fullname or name, shortname = name}
					end
				end
			end
		else
			local playerGUID = playerGUID
			if playerGUID then
				local name = UnitName("player")
				local petGUID = UnitGUID("playerpet")
				players[playerGUID] = name
				if petGUID and not petGUID:match("Player") then
					pets[petGUID] = {id = playerGUID, name = name, shortname = name}
				end
			end
		end
		-- Remove ungrouped pets
		for pet, owner in pairs(pets) do
			if not players[owner.id] then
				pets[pet] = nil
			end
		end
		requiredTentativeCount = nm(2, mf(groupNum / 2))
		groupUpdated = true
		groupUpdating = false
	end
end

function Skada:IsValidPlayer(guid)
	if groupUpdated and players[guid] then
		return true
	end
	return false
end

function Skada:IsValidPet(guid)
	if pets[guid] then
		return true
	end
	return false
end

-- Ask a mode to verify the contents of a set.
local function verify_set(mode, set)
	if mode.AddSetAttributes ~= nil then
		mode:AddSetAttributes(set)
	end
	for j, player in pairs(set._playeridx) do
		if mode.AddPlayerAttributes ~= nil then
			mode:AddPlayerAttributes(player, set)
		end
	end
end

function Skada:ZoneCheck()
	-- Check map id
	if mapId == 0 then
		SetMapToCurrentZone()
		mapId = GetCurrentMapAreaID()
	end

	-- Reset lastEncounterName
	lastEncounterName = nil

	-- Check if we are entering an instance.
	local inInstance, instanceType = IsInInstance()
	local isininstance = inInstance and (instanceType == "party" or instanceType == "raid")

	-- Update instance status.
	local pvpType, isFFA = GetZonePVPInfo()
	isInPvP = instanceType == "pvp" or instanceType == "arena" or pvpType == "arena" or pvpType == "combat" or isFFA
	isInRaid = instanceType == "raid"

	-- If we are entering an instance, and we were not previously in an instance, and we got this event before... and we have some data...
	if isininstance and wasininstance ~= nil and not wasininstance and self.db.profile.reset.instance ~= 1 and self.total ~= nil then
		if self.db.profile.reset.instance == 3 then
			Skada:ShowPopup()
		else
			self:Reset()
		end
	end

	-- Hide in PvP. Hide if entering a PvP instance, show if we are leaving one.
	if self.db.profile.hidepvp then
		if isInPvP then
			Skada:SetActive(false)
		elseif wasinpvp and not (self.db.profile.hidesolo and not IsInGroup()) then
			Skada:SetActive(true)
		end
	end

	-- Save a flag marking our previous (current) instance status.
	if isininstance then
		wasininstance = true
	else
		wasininstance = false
	end

	-- Save a flag marking out previous (current) pvp status.
	if isInPvP then
		wasinpvp = true
	else
		wasinpvp = false
	end

	-- mode update if needed.
	for i, mode in ipairs(modes) do
		if mode.ZoneCheck ~= nil then
			mode:ZoneCheck()
		end
	end

	-- make sure we update once on reload
	-- delay it because group is unavailable during first PLAYER_ENTERING_WORLD on login
	if wasinparty == nil then Skada:ScheduleTimer("GROUP_ROSTER_UPDATE", 1) end
end

-- Fired on entering a zone.
function Skada:ZONE_CHANGED_NEW_AREA()
	Skada:ZoneCheck()
end

-- Fired on blue bar screen
function Skada:PLAYER_ENTERING_WORLD()

	Skada:ZoneCheck() -- catch reloadui within a zone, which does not fire ZONE_CHANGED_NEW_AREA
	-- If this event fired in response to a login or teleport, zone info is usually not yet available 
	-- and will be caught by a sunsequent ZONE_CHANGED_NEW_AREA

	-- make sure we update once on reload
	-- delay it because group is unavailable during first PLAYER_ENTERING_WORLD on login
	if wasinparty == nil then Skada:ScheduleTimer("GROUP_ROSTER_UPDATE", 1) end
end

-- Check if we join a party/raid.
local function check_for_join_and_leave()
	if not IsInGroup() and wasinparty then
		-- We left a party.

		if Skada.db.profile.reset.leave == 3 then
			Skada:ShowPopup()
		elseif Skada.db.profile.reset.leave == 2 then
			Skada:Reset()
		end

		-- Hide window if we have enabled the "Hide when solo" option.
		if Skada.db.profile.hidesolo then
			Skada:SetActive(false)
		end
	end

	if IsInGroup() and wasinparty == false then -- if nil this is first check after reload/relog
		-- We joined a raid.

		if Skada.db.profile.reset.join == 3 then
			Skada:ShowPopup()
		elseif Skada.db.profile.reset.join == 2 then
			Skada:Reset()
		end

		-- Show window if we have enabled the "Hide when solo" option.
		-- But only when NOT in pvp if it's set to hide in pvp.
		if Skada.db.profile.hidesolo and not (Skada.db.profile.hidepvp and isInPvP) then
			Skada:SetActive(true)
		end
	end

	-- Mark our last party status.
	wasinparty = not not IsInGroup()
end

function Skada:GROUP_ROSTER_UPDATE()
	check_for_join_and_leave()

	-- Check for new pets.
	self:CheckGroup()

	for i, mode in ipairs(modes) do
		if mode.MemberChange ~= nil then
			mode:MemberChange()
		end
	end
end

function Skada:UNIT_PET()
	-- Check for new pets.
	self:CheckGroup()
end

function Skada:PET_BATTLE_OPENING_START()
	onPetBattle = true
	-- Hide during pet battles
	for i, win in ipairs(windows) do
		if win:IsShown() then
			win:Hide()
		end
	end
end

function Skada:PET_BATTLE_CLOSE()
	onPetBattle = false
	-- Restore after pet battles
	if not disabled then
		for i, win in ipairs(windows) do
			if not win.db.hidden and not win:IsShown() and not (self.db.profile.hidesolo and not IsInGroup()) and not (self.db.profile.hidepvp and isInPvP) then
				win:Show()
			end
		end
	end
end

-- Toggles all windows.
function Skada:ToggleWindow()
	for i, win in ipairs(windows) do
		if win:IsShown() then
			win.db.hidden = true
			win:Hide()
		else
			win.db.hidden = false
			win:Show()
		end
	end
end

local function createSet(setname)
	local set = {_playeridx = {}, name = setname, starttime = time(), ["time"] = 0}

	-- Tell each mode to apply its needed attributes.
	for i, mode in ipairs(modes) do verify_set(mode, set) end

	return set
end

function Skada:Reset(force)
	self:Wipe()

	pets, players = {}, {}
	self:CheckGroup()

	if tentativehandle ~= nil then
		self:CancelTimer(tentativehandle)
		tentativehandle = nil
	end
	if currentSetEnabler then
		self:CancelTimer(currentSetEnabler)
		currentSetEnabler = nil
	end
	if ieeuEncounterCheker then
		self:CancelTimer(ieeuEncounterCheker)
		ieeuEncounterCheker = nil
	end
	
	-- clear boss combat variables
	inBossCombat = false
	encounterProgress = false
	currentSetEnabled = true
	lastEncounterName = nil
	lastEnd = 0
	esCallCount = 0

	bossModCombat = false
	bossModCallCount = 0

	for i, mode in ipairs(modes) do
		if mode.Clear ~= nil then
			mode:Clear()
		end
	end

	-- wipe set
	if self.current ~= nil then
		wipe(self.current)
		self.current = createSet(L["Current"])
	end
	if self.total ~= nil then
		wipe(self.total)
		self.total = createSet(L["Total"])
		if InCombatLockdown() then
			self.total.combatstarttime = self.total.starttime
		else
			self.total.combatstarttime = nil
		end
		self.char.total = self.total
	end
	self.last = nil

	-- Delete sets that are not marked as persistent.
	for i=table.maxn(self.char.sets), 1, -1 do
		if not self.char.sets[i].keep or force then
			wipe(table.remove(self.char.sets, i))
		end
	end

	-- Don't leave windows pointing to deleted sets
	for _, win in ipairs(windows) do
		if win.selectedset ~= "total" then
			win.selectedset = "current"
			win.db.set = "current"
		end
		self:RestoreView(win, win.db.set, win.db.mode)
	end

	self:UpdateDisplay(true)
	self:Print(L["All data has been reset."])
	if not InCombatLockdown() then
		collectgarbage("collect")
	end
end

-- Delete a set.
function Skada:DeleteSet(set)
	if not set or set == "total" or set == "current" then return end

	for i, s in ipairs(self.char.sets) do
		if s == set then
			wipe(table.remove(self.char.sets, i))

			if set == self.last then
				self.last = nil
			end

			-- Don't leave windows pointing to deleted sets
			for _, win in ipairs(windows) do
				if win.selectedset == i then
					win.selectedset = "current"
					win.db.set = "current"
				elseif (tonumber(win.selectedset) or 0) > i then
					win.selectedset = win.selectedset - 1
					win.db.set = win.selectedset
				end
			end
			break
		end
	end
	self:Wipe()
	self:UpdateDisplay(true)
end

function Skada:ReloadSettings()
	-- Delete all existing windows in case of a profile change.
	for i, win in ipairs(windows) do
		win:destroy()
	end
	windows = {}

	-- Re-create windows
	-- As this can be called from a profile change as well as login, re-use windows when possible.
	for i, win in ipairs(self.db.profile.windows) do
		self:CreateWindow(win.name, win)
	end

	self.total = self.char.total

	-- Minimap button.
	if icon and not icon:IsRegistered("Skada") then
		icon:Register("Skada", dataobj, self.db.profile.icon)
	end

	self:RefreshMMButton()

	self:ApplySettings()
end

-- Applies settings to things like the bar window.
function Skada:ApplySettings()
	for i, win in ipairs(windows) do
		win:Wipe()
		win.display:ApplySettings(win)
	end

	-- Don't show window if we are solo, option.
	-- Don't show window in a PvP instance, option.
	if (self.db.profile.hidesolo and not IsInGroup()) or (self.db.profile.hidepvp and isInPvP) or onPetBattle then
		self:SetActive(false)
	else
		self:SetActive(true)

		-- Hide specific windows if window is marked as hidden (ie, if user manually hid the window, keep hiding it).
		for i, win in ipairs(windows) do
			if win.db.hidden and win:IsShown() then
				win:Hide()
			end
		end
	end

	-- Custom Version Check
	if SkadaVersion ~= SkadaRevision then
		SkadaVersion = SkadaRevision
		self:ScheduleTimer("Reset", 7, true)
		Skada.char.buffsDB = {}
		Skada.char.buffsCharDB = {}
	end

	self:UpdateDisplay(true)
end

-- Set a data feed as selectedfeed.
function Skada:SetFeed(feed)
	selectedfeed = feed
	self:UpdateDisplay()
end

-- Iterates over all players in a set and adds to the "time" variable
-- the time between first and last action.
local function setPlayerActiveTimes(set, totaltime)
	for i, player in pairs(set._playeridx) do
		if (player.last or 0) > 0 then
			if totaltime then
				if (player.last - totaltime) > set.time then
					player.time = player.time + set.time
				else
					player.time = player.time + (player.last - totaltime)
				end
			else
				if player.first < set.starttime then
					if (player.last - set.starttime) > set.time then
						player.time = player.time + set.time
					else
						player.time = player.time + (player.last - set.starttime)
					end
				else
					if (player.last - player.first) > set.time then
						player.time = player.time + set.time
					else
						player.time = player.time + (player.last - player.first)
					end
				end
			end
		elseif (groupUpdated and players[player.id or UNKNOWN]) and not totaltime and player.first then
			player.time = player.time + set.time
		end
	end
end

-- Starts a new segment, saving the current one first.
-- Does nothing if we are out of combat.
-- Useful for multi-part fights where you want individual segments for each part.
function Skada:NewSegment(bossName, startType)
	if self.current then
		self:EndCombat()
	end
	if startType then
		self:StartCombat(bossName, startType)
	end
end

function Skada:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
	--prevent double start.
	if inBossCombat then return end
	if time() - lastEnd < 60 then return end
	for i = 1, 5 do
		if UnitExists("boss"..i) then
			--ieeu unit name can't reliable. so use es name if available.
			local bossName = lastEncounterName or UnitName("boss"..i)
			self:NewSegment(bossName, "IEEU")
			return
		end
	end
end

-- es is not reliable. sometimes fires too late or too early.
-- if that, use ieeu for combat start.
function Skada:ENCOUNTER_START(_, bossName)
	--do not use encounter progress dectection for this map
	disableEPdetectionMap[mapId] = true
	--save es name ieeu can use
	lastEncounterName = bossName
	if inCombat then
		--only use esCallCount if no boss mod detected.
		--if not DBM and not BigWigsLoader then
		if not DBM then
			esCallCount = esCallCount + 1
		end
		--change boss name.
		self.current.mobname = bossName
		--update skada window immidately.
		currentSetEnabled = true
		if currentSetEnabler then
			self:CancelTimer(currentSetEnabler)
			currentSetEnabler = nil
		end
		self:UpdateDisplay(true)
	end
	--prevent double start.
	if inBossCombat then return end
	self:NewSegment(bossName, "ES")
end

function Skada:StartCombatByBossMod(bossName)
	--do not use encounter progress dectection for this map
	disableEPdetectionMap[mapId] = true
	--save boss mod boss name ieeu can use
	lastEncounterName = bossName
	if inCombat then
		-- add bossModCallCount
		bossModCallCount = bossModCallCount + 1
		--change boss name.
		self.current.mobname = bossName
		--save variables for wipe chek.
		bossModCombat = true
		--update skada window immidately.
		currentSetEnabled = true
		if currentSetEnabler then
			self:CancelTimer(currentSetEnabler)
			currentSetEnabler = nil
		end
		self:UpdateDisplay(true)
	end
	--prevent double start.
	if inBossCombat then return end
	self:NewSegment(bossName, "BossMod")
end

local function IsRaidInCombat()
	if InCombatLockdown() then
		return true
	else
		local uId = (IsInRaid() and "raid") or "party"
		local firstFound = false
		local secondFound = false
		for i = 1, GetNumGroupMembers() do
			if UnitExists(uId..i) and UnitAffectingCombat(uId..i) then
				if not IsInRaid() then
					return true
				elseif firstFound and secondFound then
					return true
				elseif not firstFound then
					firstFound = true
				elseif firstFound and not secondFound then
					secondFound = true
				end
			end
		end
	end
	return false
end

-- check if anyone in raid is in combat; if so, close up shop.
function Skada:Tick()
	if disabled or not inCombat or bossModCombat then
		self:CancelTimer(tick_timer)
		return
	end
	--EncounterStatus combat detection/end.
	if IsEncounterInProgress() ~= encounterProgress and not disableEPdetectionMap[mapId] then
		inBossCombat = IsEncounterInProgress()
		if inBossCombat then
			self:NewSegment(nil, "EncounterStatus")
		else
			self:EndCombat(nil, false)
		end
	end
	--normal combat end
	if not IsRaidInCombat() then
		self:EndCombat()
	end
end

function Skada:ENCOUNTER_END(_, bossName, _, _, success)
	--ignore ee if boss mod is installed.
	if bossModCombat then return end
	--prevent dupilcate combat end error.
	if not currentSetEnabled then return end
	--if you doing multiple boss encounter, encounter ends all boss defeated.
	esCallCount = esCallCount - 1
	if esCallCount < 1 and inBossCombat then
		lastEncounterName = nil
		self:EndCombat(bossName, success == 1)
	end
end

function Skada:EnableCurrentSet()
	currentSetEnabled = true
	if inCombat then
		Skada:Wipe()
		Skada:UpdateDisplay(true)
	end
	--Skada:Print("Debug - Current Set enabled.")
end

function Skada:PLAYER_REGEN_DISABLED()
	-- Start a new set if we are not in one already.
	if not disabled then
		self:StartCombat()
	end
end

function Skada:StartCombat(bossName, startType)
	-- Check disabled
	if disabled then return end

	-- Check inCombat
	if inCombat then return end
	inCombat = true

	if not groupUpdated then
		self:CheckGroup()
	end

	-- Reset automatic stop on wipe variables
	deathcounter = 0
	startingmembers = GetNumGroupMembers()

	-- Cancel cancelling combat if needed.
	if tentativehandle ~= nil then
		self:CancelTimer(tentativehandle)
		tentativehandle = nil
	end
	if currentSetEnabler then
		self:CancelTimer(currentSetEnabler)
		currentSetEnabler = nil
	end
	if ieeuEncounterCheker then
		self:CancelTimer(ieeuEncounterCheker)
		ieeuEncounterCheker = nil
	end

	-- Create a new current set unless we are already have one (combat detection kicked in).
	if not self.current then
		self.current = createSet(L["Current"])
	end

	-- Also start the total set if it is nil.
	if self.total == nil then
		self.total = createSet(L["Total"])
		self.char.total = self.total
	end

	-- Check boss encounter
	if startType then
		inBossCombat = true
		self.current.gotboss = true
		self.current.mobname = bossName
		if startType == "ES" then
			encounterProgress = true
			--if not DBM and not BigWigsLoader then
			if not DBM then
				esCallCount = 1
			end
		elseif startType == "IEEU" then
			ieeuEncounterCheker = self:ScheduleTimer(function() encounterProgress = IsEncounterInProgress() end, 0.5)
		elseif startType == "BossMod" then
			bossModCombat = true
			encounterProgress = true
			bossModCallCount = 1
		else
			encounterProgress = true
		end
	end

	-- Save combat start time.
	self.total.endtime = nil
	if not self.total.combatstarttime then
		self.total.combatstarttime = time()
		self.current.starttime = self.total.combatstarttime
	end

	-- stop skada window update for 30s after boss ended. ieeu and encounter status detection can be bad, also stops it.
	if lastEnd > 0 then
		-- ignore stop window after 30s from boss killed. also ignore "ES" or "BossMod" combat start detetected.
		if (time() - lastEnd) > 30 or (startType or "") == "ES" or (startType or "") == "BossMod" then
			currentSetEnabled = true
			self:Wipe()
		else
			currentSetEnabled = false
			local delay = nm(30 - (time() - lastEnd), 0)
			if delay > 0 then
				currentSetEnabler = self:ScheduleTimer("EnableCurrentSet", delay)
			else
				currentSetEnabled = true
				self:Wipe()
			end
		end
	else
		currentSetEnabled = true
		self:Wipe()
	end

	-- Auto-switch set/mode if configured.
	for i, win in ipairs(windows) do
		if win.db.modeincombat ~= "" then
			-- First, get the mode. The mode may not actually be available.
			local mymode = find_mode(win.db.modeincombat)

			-- If the mode exists, switch to current set and this mode. Save current set/mode so we can return after combat if configured.
			if mymode ~= nil then

				if win.db.returnaftercombat then
					if win.selectedset then
						win.restore_set = win.selectedset
					end
					if win.selectedmode then
						win.restore_mode = win.selectedmode:GetName()
					end
				end

				win.selectedset = "current"
				win:DisplayMode(mymode)
			end
		end

		-- Hide in combat option.
		if not win.db.hidden and self.db.profile.hidecombat then
			win:Hide()
		end
	end

	-- update display
	if not update_timer then
		update_timer = self:ScheduleRepeatingTimer("UpdateDisplay", 0.5)
	end
	if not tick_timer then
		tick_timer = self:ScheduleRepeatingTimer("Tick", 2)
	end

	for i, mode in ipairs(modes) do
		if mode.StartCombat ~= nil then
			mode:StartCombat()
		end
	end

	self:UpdateDisplay(true)
end

--used by debuffs module
function Skada:InCombat()
	return inCombat
end

function Skada:EndCombat(bossName, success)
	-- Check inCombat
	if not inCombat then return end

	self:CancelTimer(update_timer)
	update_timer = nil
	self:CancelTimer(tick_timer)
	tick_timer = nil

	if not self.current.endtime then
		self.current.endtime = time()
	end
	self.current.time = self.current.endtime - self.current.starttime
	setPlayerActiveTimes(self.current)
	self.current.stopped = nil

	if not currentSetEnabled and not success then
		self.last = nil
	else
		self.last = self.current
	end

	if success ~= nil then
		--Skada:Print("Debug - Current Set disabled.")
		lastEnd = time()
		currentSetEnabled = false
		currentSetEnabler = self:ScheduleTimer("EnableCurrentSet", 30)
	end

	-- Add time spent to total set as well.
	self.total.endtime = self.current.endtime
	self.total.time = (self.total.time or 0) + self.total.endtime - (self.total.combatstarttime or self.current.starttime)
	setPlayerActiveTimes(self.total, self.total.combatstarttime)
	self.total.combatstarttime = nil

	for i, mode in ipairs(modes) do
		if mode.EndCombat ~= nil then
			mode:EndCombat()
		end
	end

	if not self.db.profile.onlykeepbosses or self.current.gotboss or success ~= nil then
		if (self.current.mobname ~= nil and (time() - self.current.starttime) > 10) or success then
			-- compute a count suffix for the set name
			local setname = bossName or self.current.mobname
			if self.db.profile.setnumber then
				local max = 0
				for _, set in ipairs(self.char.sets) do
					if set.name == setname and max == 0 then
						max = 1
					else
						local n,c = set.name:match("^(.-)%s*%((%d+)%)$")
						if n == setname then max = math.max(max,tonumber(c) or 0) end
					end
				end
				if max > 0 then
					setname = setname .. " ("..(max+1)..")"
				end
			end
			self.current.name = setname

			-- Tell each mode that set has finished and do whatever it wants to do about it.
			for i, mode in ipairs(modes) do
				if mode.SetComplete ~= nil then
					mode:SetComplete(self.current)
				end
			end

			-- Add set to sets.
			table.insert(self.char.sets, 1, self.current)
		end
	end

	-- Set player.first and player.last to nil in total set.
	-- Neccessary since first and last has no relevance over an entire raid.
	-- Modes should look at the "time" value if available.
	for i, player in pairs(self.total._playeridx) do
		player.first = nil
		player.last = nil
	end

	-- Reset current set.
	self.current = nil

	-- Find out number of non-persistent sets.
	local numsets = 0
	for i, set in ipairs(self.char.sets) do if not set.keep then numsets = numsets + 1 end end

	-- Trim segments; don't touch persistent sets.
	for i=table.maxn(self.char.sets), 1, -1 do
		if numsets > self.db.profile.setstokeep and not self.char.sets[i].keep then
			table.remove(self.char.sets, i)
			numsets = numsets - 1
		end
	end

	for i, win in ipairs(windows) do
		win:Wipe()

		-- Wipe mode - switch to current set and specific mode if no party/raid members are alive.
		-- Restore mode is not changed.
		if win.db.wipemode ~= "" and not IsEncounterInProgress() then
			self:RestoreView(win, "current", win.db.wipemode)
		elseif win.db.returnaftercombat then
			-- Auto-switch back to previous set/mode.
			self:RestoreView(win, win.restore_set or win.db.set, win.restore_mode or win.db.mode)

			win.restore_mode = nil
			win.restore_set = nil
		end

		-- Hide in combat option.
		if not win.db.hidden and self.db.profile.hidecombat and not disabled and not (self.db.profile.hidesolo and not IsInGroup()) and not (self.db.profile.hidepvp and isInPvP) then
			win:Show()
		end
	end

	-- End current set, clear variables
	inBossCombat = false
	encounterProgress = false
	esCallCount = 0

	bossModCombat = false
	bossModCallCount = 0

	inCombat = false

	self:UpdateDisplay(true) -- force required to update displays looking at older sets after insertion
end

-- Stops the current segment immediately.
-- To not complicate things, this only stops processing of CLEU events and sets the segment end time.
-- A stopped segment can be resumed.
function Skada:StopSegment()
	if self.current then
		self.current.stopped = true
		self.current.endtime = time()
		self.current.time = self.current.endtime - self.current.starttime
		Skada:Print(L["Record stopped."])
	end
end

-- Resumes a stopped segment.
function Skada:ResumeSegment()
	if self.current and self.current.stopped then
		self.current.stopped = nil
		self.current.endtime = nil
		self.current.time = 0
		Skada:Print(L["Record resumed."])
	end
end

-- Simply calls the same function on all windows.
function Skada:Wipe()
	for i, win in ipairs(windows) do
		win:Wipe()
	end
end

-- Attempts to restore a view (set and mode).
-- Set is either the set name ("total", "current"), or an index.
-- Mode is the name of a mode.
function Skada:RestoreView(win, set, mode)
	-- Find the mode. The mode may not actually be available.
	if mode then
		if set then
			win.selectedset = set
			win.db.set = set
		end
		local mymode = find_mode(mode)
		if mymode then
			win:DisplayMode(mymode)
		elseif set then
			win:DisplayModes(set)
		else
			win:DisplaySets()
		end
	elseif set then
		win:DisplayModes(set)
	else
		win:DisplaySets()
	end
end

-- If set is "current", returns current set if we are in combat, otherwise returns the last set.
function Skada:find_set(s)
	if s == "current" then
		if inCombat and currentSetEnabled then
			return Skada.current
		elseif Skada.last ~= nil then
			return Skada.last
		else
			return self.char.sets[1]
		end
	elseif s == "total" then
		return Skada.total
	else
		return self.char.sets[s]
	end
end

-- Returns a player from the current. Safe to use to simply view a player without creating an entry.
function Skada:find_player(set, playerid)
	if not playerid or playerid == "" then return end
	if set then
		-- use a private index here for more efficient lookup
		-- may eventually want to re-key .players by id but that would break external mods
		set._playeridx = set._playeridx or {}
		local player = set._playeridx[playerid]
		if player then return player end
	end
end

-- Returns or creates a player in the current.
function Skada:get_player(set, playerid, playername, notimerecord)
	if not playerid or playerid == "" then return end
	-- Add player to set if it does not exist.
	local player = Skada:find_player(set, playerid)

	if not player then
		-- If we do not supply a playername (often the case in submodes), we can not create an entry.
		if not playername then
			return
		end

		local _, playerClass = UnitClass(playername)
		local playerRole = UnitGroupRolesAssigned(playername)
		player = {id = playerid, class = playerClass, role = playerRole, name = playername, shortname = playername, first = time(), ["time"] = 0}

		-- Tell each mode to apply its needed attributes.
		for i, mode in ipairs(modes) do
			if mode.AddPlayerAttributes ~= nil then
				mode:AddPlayerAttributes(player, set)
			end
		end

		-- Strip realm name
		-- This is done after module processing due to cross-realm names messing with modules (death log for example, which needs to do UnitHealthMax on the playername).
		local player_name = string.split("-", playername)
		player.shortname = player_name or playername

		set._playeridx = set._playeridx or {}
		set._playeridx[playerid] = player
	end

	if player.name == COMBATLOG_UNKNOWN_UNIT and playername and playername ~= COMBATLOG_UNKNOWN_UNIT then -- fixup players created before we had their info
		player.name = playername
		local _, playerClass = UnitClass(playername)
		local player_name = string.split("-", playername)
		local playerRole = UnitGroupRolesAssigned(playername)
		player.class = playerClass
		player.shortname = player_name or playername
		player.role = playerRole
	end

	-- The total set clears out first and last timestamps.
	if not player.first then
		player.first = time()
	end

	-- Mark now as the last time player did something worthwhile.
	if not notimerecord then
		player.last = time()
	end
	changed = true
	return player
end

function Skada:RegisterForCL(func, event, flags, force)
	if not combatlogevents[event] then
		combatlogevents[event] = {}
	end
	tinsert(combatlogevents[event], {["func"] = func, ["flags"] = flags, ["force"] = force})
end

-- The basic idea for CL processing:
-- Modules register for interest in a certain event, along with the function to call and the flags determining if the particular event is interesting.
-- On a new event, loop through the interested parties.
-- The flags are checked, and the flag value (say, that the SRC must be interesting, ie, one of the raid) is only checked once, regardless
-- of how many modules are interested in the event. The check is also only done on the first flag that requires it.
cleuFrame = CreateFrame("Frame") -- Dedicated event handler for a small performance improvement.
cleuFrame:SetScript("OnEvent", function(frame, event, timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)
	local src_is_interesting = nil
	local dst_is_interesting = nil

	-- Optional tentative combat detection.
	-- Instead of simply checking when we enter combat, combat start is also detected based on needing a certain
	-- amount of interesting (as defined by our modules) CL events.
	if not Skada.current and Skada.db.profile.tentativestart and currentSetEnabled and srcGUID ~= dstGUID and (eventtype == 'SPELL_DAMAGE' or eventtype == 'SPELL_BUILDING_DAMAGE' or eventtype == 'RANGE_DAMAGE' or eventtype == 'SWING_DAMAGE' or eventtype == 'SPELL_PERIODIC_DAMAGE') then
		src_is_interesting = band(srcFlags, RAID_FLAGS) ~= 0 or (pets[srcGUID] and band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0) or (groupUpdated and players[srcGUID] and band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)
		if src_is_interesting and not inCombat then
			Skada.current = createSet(L["Current"])
			-- Also create total set if needed.
			if not Skada.total then
				Skada.total = createSet(L["Total"])
			end

			if not tentativehandle then
				tentativehandle = Skada:ScheduleTimer(function()
										tentative = nil
										tentativehandle = nil
										Skada.current = nil
									end, 1)

				tentative = 0
			end
		end
	end

	-- Pet summons.
	-- Pet scheme: save the GUID in a table along with the GUID of the owner.
	-- Note to self: this needs 1) to be made self-cleaning so it can't grow too much, and 2) saved persistently.
	-- Now also done on raid roster/party changes.
	if eventtype == 'SPELL_SUMMON' and band(srcFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 and (band(srcFlags, RAID_FLAGS) ~= 0 or band(srcFlags, PET_FLAGS) ~= 0) then
		local spellid = ...
		-- assign pet normally
		-- fix heart seeker bug (filter it)
		if srcGUID and dstGUID and (groupUpdated and players[srcGUID]) and (spellid and (spellid ~= 180410)) then
			local name = srcName or UNKNOWN
			pets[dstGUID] = {id = srcGUID, name = name, shortname = players[srcGUID]}
		end
	end

	-- Stop automatically on wipe to discount meaningless data.
	if Skada.current and Skada.db.profile.autostop then
		-- Add to death counter when a player dies.
		if Skada.current and eventtype == 'UNIT_DIED' and ((band(srcFlags, RAID_FLAGS) ~= 0 and band(srcFlags, PET_FLAGS) == 0) or (groupUpdated and players[srcGUID] and band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)) then
			deathcounter = deathcounter + 1
			-- If we reached the treshold for stopping the segment, do so.
			if deathcounter > 0 and deathcounter / startingmembers >= 0.5 and not Skada.current.stopped then
				Skada:Print('Stopping for wipe.')
				Skada:StopSegment()
			end
		end
		-- Subtract from death counter when a player is ressurected.
		if Skada.current and eventtype == 'SPELL_RESURRECT' and ((band(srcFlags, RAID_FLAGS) ~= 0 and band(srcFlags, PET_FLAGS) == 0) or (groupUpdated and players[srcGUID] and band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)) then
			deathcounter = deathcounter - 1
		end
	end

	if combatlogevents[eventtype] then
		for i, mod in ipairs(combatlogevents[eventtype]) do
			-- If segment is stopped, stop processing here.
			if (Skada.current and not Skada.current.stopped) or mod.force then
				local fail = false

				if mod.flags.src_is_interesting_nopets then
					local src_is_interesting_nopets = (band(srcFlags, RAID_FLAGS) ~= 0 and band(srcFlags, PET_FLAGS) == 0) or (groupUpdated and players[srcGUID] and band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)
					if src_is_interesting_nopets then
						src_is_interesting = true
					else
						fail = true
					end
				end
				if not fail and mod.flags.dst_is_interesting_nopets then
					local dst_is_interesting_nopets = (band(dstFlags, RAID_FLAGS) ~= 0 and band(dstFlags, PET_FLAGS) == 0) or (groupUpdated and players[dstGUID] and band(dstFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)
					if dst_is_interesting_nopets then
						dst_is_interesting = true
					else
						fail = true
					end
				end
				if not fail and (mod.flags.src_is_interesting or mod.flags.src_is_not_interesting) then
					if not src_is_interesting then
						src_is_interesting = band(srcFlags, RAID_FLAGS) ~= 0 or (pets[srcGUID] and band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0) or (groupUpdated and players[srcGUID] and band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)
					end
					if mod.flags.src_is_interesting and not src_is_interesting then
						fail = true
					end
					if mod.flags.src_is_not_interesting and src_is_interesting then
						if srcGUID and srcGUID:match("-") then--only drops valid guid
							fail = true
						end
					end
					if mod.flags.src_is_not_interesting and not src_is_interesting and band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == 0 and srcGUID and (srcGUID:match("Player") or srcGUID:match("Pet")) then
						fail = true
					end
				end
				if not fail and (mod.flags.dst_is_interesting or mod.flags.dst_is_not_interesting) then
					if not dst_is_interesting then
						dst_is_interesting = band(dstFlags, RAID_FLAGS) ~= 0 or (pets[srcGUID] and band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0) or (groupUpdated and players[dstGUID] and band(dstFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)
					end
					if mod.flags.dst_is_interesting and not dst_is_interesting then
						fail = true
					end
					if mod.flags.dst_is_not_interesting and dst_is_interesting then
						if dstGUID and dstGUID:match("-") then--only drops valid guid
							fail = true
						end
					end
					if mod.flags.dst_is_not_interesting and not dst_is_interesting and band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == 0 and dstGUID and (dstGUID:match("Player") or dstGUID:match("Pet")) then
						fail = true
					end
				end

				-- Pass along event if it did not fail our tests.
				if not fail then
					mod.func(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)

					-- If our "tentative" flag is set and reached the treshold, this means combat really did start.
					if tentativehandle and not mod.force then
						if i == 1 then
							tentative = tentative + 1
						end
						if tentative == requiredTentativeCount then
							Skada:CancelTimer(tentativehandle)
							tentative = nil
							tentativehandle = nil
							Skada:StartCombat()
						end
					end
				end
			end
		end
	end

	-- Note: relies on src_is_interesting having been checked.
	if Skada.current and src_is_interesting and not Skada.current.mobname then
		-- Store mob name for set name. For now, just save first unfriendly name available, or first boss available.
		if band(dstFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0 then
			Skada.current.mobname = dstName
		end
	end
end)

--
-- Data broker
--

function dataobj:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()

	local set
	if inCombat then
		set = Skada.current
	elseif Skada.last then
		set = Skada.last
	else
		set = Skada.char.sets[1]
	end
	if set then
		GameTooltip:AddLine(L["Skada summary"], 0, 1, 0)
		for i, mode in ipairs(modes) do
			if mode.AddToTooltip ~= nil then
				mode:AddToTooltip(set, GameTooltip)
			end
		end
 	end

	GameTooltip:AddLine(L["Hint: Left-Click to toggle Skada window."], 0, 1, 0)
	GameTooltip:AddLine(L["Shift + Left-Click to reset."], 0, 1, 0)
	GameTooltip:AddLine(L["Right-click to open menu"], 0, 1, 0)

	GameTooltip:Show()
end

function dataobj:OnLeave()
	GameTooltip:Hide()
end

function dataobj:OnClick(button)
	if button == "LeftButton" and IsShiftKeyDown() then
		Skada:Reset()
	elseif button == "LeftButton" then
		Skada:ToggleWindow()
	elseif button == "RightButton" then
		Skada:OpenMenu()
	end
end

function Skada:SpecialUpdate()
	for i, win in ipairs(windows) do
		if win.selectedmode and win.selectedmode.SpecialUpdate then
			local set = win:get_selected_set()
			win.selectedmode:SpecialUpdate(win, set)
			win:UpdateDisplay()
		end
	end
end

function Skada:UpdateDisplay(force)
	-- Force an update by setting our "changed" flag to true.
	if force then
		changed = true
	end

	-- Update data feed.
	-- This is done even if our set has not changed, since for example DPS changes even though the data does not.
	-- Does not update feed text if nil.
	if selectedfeed ~= nil then
		local feedtext = selectedfeed()
		if feedtext then
			dataobj.text = feedtext
		end
	end

	local supdate_found = false

	for i, win in ipairs(windows) do
		if not supdate_found and win.selectedmode and win.selectedmode.SpecialUpdate then
			supdate_found = true
		end
		if (changed or win.changed or inCombat) then
			win.changed = false
			if win.selectedmode then -- Force mode display for display systems which do not handle navigation.
				if win.selectedmode.ManualUpdate then
					if force ~= nil then
						win.selectedmode:ManualUpdate()
					end
				elseif not win.selectedmode.SpecialUpdate then
					local set = win:get_selected_set()

					if set then
						-- Let mode update data.
						if win.selectedmode.Update then
							win.selectedmode:Update(win, set)
						else
							self:Print("Mode "..win.selectedmode:GetName().." does not have an Update function!")
						end

						-- Add a total bar using the mode summaries optionally.
						if self.db.profile.showtotals and win.selectedmode.GetSetSummary then
							win.totalvalue = win.selectedmode:GetSetSummary(set)
						end

					end

					-- Let window display the data.
					win:UpdateDisplay()
				end
			elseif win.selectedset then
				local set = win:get_selected_set()

				-- View available modes.
				for i, mode in ipairs(modes) do

					local d = win.dataset[i] or {}
					win.dataset[i] = d

					d.id = mode:GetName()
					d.label = mode:GetName()
					d.value = 1
					d.order = mode.Order or 999
					if set and mode.GetSetSummary ~= nil then
						d.valuetext = mode:GetSetSummary(set)
					end
				end

				win.metadata.ordercustomized = true

				-- Let window display the data.
				win:UpdateDisplay()
			else
				-- View available sets.
				local nr = 1
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = "total"
				d.label = L["Total"]
				d.value = 1

				nr = nr + 1
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = "current"
				d.label = L["Current"]
				d.value = 1

				for i, set in ipairs(self.char.sets) do
					nr = nr + 1
					local d = win.dataset[nr] or {}
					win.dataset[nr] = d

					d.id = tostring(i)
					d.label, d.valuetext = select(2,Skada:GetSetLabel(set))
					d.value = 1
					if set.keep then
						d.emphathize = true
					end
				end

				win.metadata.ordersort = true

				-- Let window display the data.
				win:UpdateDisplay()
			end
		end
	end

	if supdate_found then
		self:SpecialUpdate()
		if not supdate_timer then
			supdate_timer = self:ScheduleRepeatingTimer("SpecialUpdate", 0.5)
		end
	else
		self:CancelTimer(supdate_timer)
		supdate_timer = nil
	end
	-- Mark as unchanged.
	changed = false
end

--[[

API
Everything below this is OK to use in modes.

--]]

function Skada:GetSets()
	return self.char.sets
end

function Skada:GetModes()
	return modes
end

-- Formats a number into human readable form.
function Skada:FormatNumber(number, isDps)
	if number then
		local nf = self.db.profile.numberformat
		if not isKR and nf < 4 then
			nf = nf + 3
		end
		if (nf == 1) or (not isDps and (nf == 2 or nf == 3)) then
			if number >= 100000000 then
				return ("%02.2f"..L["Eok"]):format(number / 100000000)
			elseif number >= 10000 then
				return ("%02.1f"..L["Man"]):format(number / 10000)
			elseif nf == 3 then
				return mf(number)
			else
				return BreakUpLargeNumbers(mf(number))
			end
		elseif (nf == 4) or (not isDps and (nf == 5 or nf == 6)) then
			if number >= 1000000 then
				return 	("%02.2fM"):format(number / 1000000)
			elseif number >= 1000 then
				return 	("%02.1fK"):format(number / 1000)
			else
				return mf(number)
			end
		elseif nf == 1 or nf == 2 or nf == 4 or nf == 5 or nf == 7 then
			return BreakUpLargeNumbers(mf(number))
		else
			return mf(number)
		end
	end
end

function Skada:FormatHitNumber(number, noPostfix)
	if number then
		local nf = self.db.profile.numberformat
		local postfix = ""
		if not noPostfix and isKR then
			postfix = L["Hwoe"]
		end
		if nf == 1 or nf == 2 or nf == 4 or nf == 5 or nf == 7 then
			return BreakUpLargeNumbers(mf(number))..postfix
		else
			return mf(number)..postfix
		end
	end
end

local function scan_for_columns(mode)
	-- Only process if not already scanned.
	if not mode.scanned then
		mode.scanned = true

		-- Add options for this mode if available.
		if mode.metadata and mode.metadata.columns then
			Skada:AddColumnOptions(mode)
		end

		-- Scan any linked modes.
		if mode.metadata then
			if mode.metadata.click1 then
				scan_for_columns(mode.metadata.click1)
			end
			if mode.metadata.click2 then
				scan_for_columns(mode.metadata.click2)
			end
			if mode.metadata.click3 then
				scan_for_columns(mode.metadata.click3)
			end
		end
	end
end

-- Register a mode.
function Skada:AddMode(mode)
	-- Ask mode to verify our sets.
	-- Needed in case we enable a mode and we have old data.
	if self.total then
		verify_set(mode, self.total)
	end
	if self.current then
		verify_set(mode, self.current)
	end
	for i, set in ipairs(self.char.sets) do
		verify_set(mode, set)
	end

	table.insert(modes, mode)

	-- Find if we now have our chosen feed.
	-- Also a bit ugly.
	if selectedfeed == nil and self.db.profile.feed ~= "" then
		for name, feed in pairs(feeds) do
			if name == self.db.profile.feed then
				self:SetFeed(feed)
			end
		end
	end

	-- Add column configuration if available.
	if mode.metadata then
		scan_for_columns(mode)
	end

	-- Sort modes.
	table.sort(modes, function(a, b) return (a.Order or 9999) < (b.Order or 9999) end)

	-- Remove all bars and start over to get ordering right.
	-- Yes, this all sucks - the problem with this and the above is that I don't know when
	-- all modules are loaded. :/
	for i, win in ipairs(windows) do
		win:Wipe()
	end
	changed = true
end

-- Unregister a mode.
function Skada:RemoveMode(mode)
	table.remove(modes, mode)
end

function Skada:GetFeeds()
	return feeds
end

-- Register a data feed.
function Skada:AddFeed(name, func)
	feeds[name] = func
end

-- Unregister a data feed.
function Skada:RemoveFeed(name, func)
	for i, feed in ipairs(feeds) do
		if feed.name == name then
			table.remove(feeds, i)
		end
	end
end

--[[

Sets

--]]

function Skada:GetSetTime(set)
	local maxtime = 0

	if set.time > 0 then
		maxtime = set.time
	end

	if not set.endtime then
		if set.combatstarttime then -- for total set.
			maxtime = maxtime + (time() - set.combatstarttime)
		else
			maxtime = maxtime + (time() - set.starttime)
		end
	end

	return maxtime
end

-- Returns the time (in seconds) a player has been active for a set.
function Skada:PlayerActiveTime(set, player)
	local maxtime = 0

	-- Add recorded time (for total set)
	if player.time > 0 then
		maxtime = player.time
	end

	-- Add in-progress time if set is not ended.
	if (not set.endtime or set.stopped) and player.first and (player.last or 0) > 0 then
		if set.combatstarttime then -- for total set.
			maxtime = maxtime + (player.last - set.combatstarttime)
		else
			if player.first < set.starttime then
				maxtime = maxtime + (player.last - set.starttime)
			else
				maxtime = maxtime + (player.last - player.first)
			end
		end
	end
	return maxtime
end

-- Modify objects if they are pets.
-- Expects to find "playerid", "playername", and optionally "spellname" in the object.
-- Playerid and playername are exchanged for the pet owner's, and spellname is modified to include pet name.
function Skada:FixPets(action)
	if action then
		-- fix for Stampede
		if not action.playername then action.playername = UNKNOWN end
		local pet = pets[action.playerid] and action.playerflags and band(action.playerflags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0
		if pet then
			-- process pet
			if (self.db.profile.mergepets) then
				if action.spellname then
					action.spellname = action.playername..": "..action.spellname
				end
				action.playername = pet.name
				action.playerid = pet.id
			else
				action.playername = pet.shortname..": "..action.playername
				action.playerid = pet.id..action.playerid
			end
		else
			-- Always process my pet even pets table broken.
			if action.playerflags and band(action.playerflags, COMBATLOG_OBJECT_TYPE_PET) ~= 0 and band(action.playerflags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
				if action.playerid and not action.playerid:match("Player") then
					if (self.db.profile.mergepets) then
						if action.spellname then
							action.spellname = action.playername..": "..action.spellname
						end
						action.playername = UnitName("player")
						action.playerid = UnitGUID("player")
					else
						action.playername = UnitName("player")..": "..action.playername
						action.playerid = UnitGUID("player")..action.playerid
					end
				end
			-- Fix for guardians; requires "playerflags" to be set from CL.
			-- This only works for one self. Other player's guardians are all lumped into one.
			elseif action.playerflags and band(action.playerflags, COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 and band(action.playerflags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
				if action.spellname then
					action.spellname = action.playername..": "..action.spellname
				end
				action.playername = UnitName("player")
				action.playerid = UnitGUID("player")
			-- drop unknown pets
			elseif not players[action.playerid] and action.playerflags and band(action.playerflags, COMBATLOG_OBJECT_TYPE_PET + COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then
				action.playername = nil
				action.playerid = nil
			end
		end
	end
end

function Skada:SetTooltipPosition(tooltip, frame)
	local p = self.db.profile.tooltippos
	if p == "default" then
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -40, 40);
	elseif p == "topleft" then
		tooltip:SetOwner(frame, "ANCHOR_NONE")
		tooltip:SetPoint("TOPRIGHT", frame, "TOPLEFT")
	elseif p == "topright" then
		tooltip:SetOwner(frame, "ANCHOR_NONE")
		tooltip:SetPoint("TOPLEFT", frame, "TOPRIGHT")
	end
end

-- Format value text in a standardized way. Up to 3 value and boolean (show/don't show) combinations are accepted.
-- Values are rendered from left to right.
-- Idea: "compile" a function on the fly instead and store in mode for re-use.
function Skada:FormatValueText(...)
	local value1, bool1, value2, bool2, value3, bool3 = ...

	-- This construction is a little silly.
	if bool1 and bool2 and bool3 then
		return value1.." ("..value2..", "..value3..")"
	elseif bool1 and bool2 then
		return value1.." ("..value2..")"
	elseif bool1 and bool3 then
		return value1.." ("..value3..")"
	elseif bool2 and bool3 then
		return value2.." ("..value3..")"
	elseif bool2 then
		return value2
	elseif bool1 then
		return value1
	elseif bool3 then
		return value3
	end
end

local function value_sort(a,b)
	if not a or a.value == nil then
		return false
	elseif not b or b.value == nil then
		return true
	else
		return a.value > b.value
	end
end

function Skada.valueid_sort(a,b)
	if not a or a.value == nil or a.id == nil then
		return false
	elseif not b or b.value == nil or b.id == nil then
		return true
	else
		return a.value > b.value
	end
end

local ttwin = Window:new()
local white = {r = 1, g = 1, b = 1}
-- Tooltip display. Shows subview data for a specific row.
-- Using a fake window, the subviews are asked to populate the window's dataset normally.
function Skada:AddSubviewToTooltip(tooltip, win, mode, id, label)
	-- Clean dataset.
	wipe(ttwin.dataset)

	-- Tell mode we are entering our real window.
	mode:Enter(win, id, label)
	ttwin.modedata = win.modedata

	-- Ask mode to populate dataset in our fake window.
	mode:Update(ttwin, win:get_selected_set())

	-- Sort dataset unless we are using ordersort.
	if not mode.metadata or not mode.metadata.ordersort then
		table.sort(ttwin.dataset, value_sort)
	end

	-- Show title and data if we have data.
	if #ttwin.dataset > 0 then
		tooltip:AddLine(mode.title or mode:GetName(), 1,1,1)

		-- Display the top X, default 3, rows.
		local nr = 0
		for i, data in ipairs(ttwin.dataset) do
			if data.id and nr < Skada.db.profile.tooltiprows then
				nr = nr + 1

				local color = white
				if data.color then
					-- Explicit color from dataset.
					color = data.color
				elseif data.class then
					-- Class color.
					local color = Skada.classcolors[data.class]
				end

				local label = data.label
				if mode.metadata and mode.metadata.showspots then
					label = nr..". "..label
				end
				tooltip:AddDoubleLine(label, data.valuetext, color.r, color.g, color.b)
			end
		end

		-- Add an empty line.
		tooltip:AddLine(" ")
	end
end

do
	function Skada:OnInitialize()
		-- Register some SharedMedia goodies.
		media:Register("font", "Adventure",				[[Interface\Addons\SkadaU\fonts\Adventure.ttf]])
		media:Register("font", "ABF",					[[Interface\Addons\SkadaU\fonts\ABF.ttf]])
		media:Register("font", "Vera Serif",			[[Interface\Addons\SkadaU\fonts\VeraSe.ttf]])
		media:Register("font", "Diablo",				[[Interface\Addons\SkadaU\fonts\Avqest.ttf]])
		media:Register("font", "Accidental Presidency",	[[Interface\Addons\SkadaU\fonts\Accidental Presidency.ttf]])
		media:Register("statusbar", "Aluminium",		[[Interface\Addons\SkadaU\statusbar\Aluminium]])
		media:Register("statusbar", "Armory",			[[Interface\Addons\SkadaU\statusbar\Armory]])
		media:Register("statusbar", "BantoBar",			[[Interface\Addons\SkadaU\statusbar\BantoBar]])
		media:Register("statusbar", "Glaze2",			[[Interface\Addons\SkadaU\statusbar\Glaze2]])
		media:Register("statusbar", "Gloss",			[[Interface\Addons\SkadaU\statusbar\Gloss]])
		media:Register("statusbar", "Graphite",			[[Interface\Addons\SkadaU\statusbar\Graphite]])
		media:Register("statusbar", "Grid",				[[Interface\Addons\SkadaU\statusbar\Grid]])
		media:Register("statusbar", "Healbot",			[[Interface\Addons\SkadaU\statusbar\Healbot]])
		media:Register("statusbar", "LiteStep",			[[Interface\Addons\SkadaU\statusbar\LiteStep]])
		media:Register("statusbar", "Minimalist",		[[Interface\Addons\SkadaU\statusbar\Minimalist]])
		media:Register("statusbar", "Otravi",			[[Interface\Addons\SkadaU\statusbar\Otravi]])
		media:Register("statusbar", "Outline",			[[Interface\Addons\SkadaU\statusbar\Outline]])
		media:Register("statusbar", "Perl",				[[Interface\Addons\SkadaU\statusbar\Perl]])
		media:Register("statusbar", "Smooth",			[[Interface\Addons\SkadaU\statusbar\Smooth]])
		media:Register("statusbar", "Round",			[[Interface\Addons\SkadaU\statusbar\Round]])
		media:Register("statusbar", "TukTex",			[[Interface\Addons\SkadaU\statusbar\normTex]])

		-- Some sounds (copied from Omen).
		media:Register("sound", "Rubber Ducky", [[Sound\Doodad\Goblin_Lottery_Open01.ogg]])
		media:Register("sound", "Cartoon FX", [[Sound\Doodad\Goblin_Lottery_Open03.ogg]])
		media:Register("sound", "Explosion", [[Sound\Doodad\Hellfire_Raid_FX_Explosion05.ogg]])
		media:Register("sound", "Shing!", [[Sound\Doodad\PortcullisActive_Closed.ogg]])
		media:Register("sound", "Wham!", [[Sound\Doodad\PVP_Lordaeron_Door_Open.ogg]])
		media:Register("sound", "Simon Chime", [[Sound\Doodad\SimonGame_LargeBlueTree.ogg]])
		media:Register("sound", "War Drums", [[Sound\Event Sounds\Event_wardrum_ogre.ogg]])
		media:Register("sound", "Cheer", [[Sound\Event Sounds\OgreEventCheerUnique.ogg]])
		media:Register("sound", "Humm", [[Sound\Spells\SimonGame_Visual_GameStart.ogg]])
		media:Register("sound", "Short Circuit", [[Sound\Spells\SimonGame_Visual_BadPress.ogg]])
		media:Register("sound", "Fel Portal", [[Sound\Spells\Sunwell_Fel_PortalStand.ogg]])
		media:Register("sound", "Fel Nova", [[Sound\Spells\SeepingGaseous_Fel_Nova.ogg]])
		media:Register("sound", "You Will Die!", [[Sound\Creature\CThun\CThunYouWillDie.ogg]])

		-- DB
		self.db = LibStub("AceDB-3.0"):New("SkadaDB", self.defaults, "Default")
		if type(SkadaPerCharDB) ~= "table" then SkadaPerCharDB = {} end
		self.char = SkadaPerCharDB
		self.char.sets = self.char.sets or {}
		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Skada", self.options, true)
		self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Skada", "Skada: Ultimate")

		-- Profiles
		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Skada-Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db), true)
		self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Skada-Profiles", "Profiles", "Skada: Ultimate")

		-- Dual spec profiles
		if lds then
			lds:EnhanceDatabase(self.db, "SkadaDB")
			lds:EnhanceOptions(LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db), self.db)
		end

		-- Slash Handler
		SLASH_SKADA1 = "/skada"
		SlashCmdList.SKADA = slashHandler

		self.db.RegisterCallback(self, "OnProfileChanged", "ReloadSettings")
		self.db.RegisterCallback(self, "OnProfileCopied", "ReloadSettings")
		self.db.RegisterCallback(self, "OnProfileReset", "ReloadSettings")

		-- Migrate old settings.
		if self.db.profile.barmax then
			self:Print("Migrating old settings somewhat gracefully. This should only happen once.")
			self.db.profile.barmax = nil
			self.db.profile.background.height = 200
		end

		-- XXX temp
		self.db.profile.modulesToSkip = nil
	end
end

local function bossModStart(_, mod)
	if not mod.type or (mod.type ~= "SCENARIO") then
		Skada:StartCombatByBossMod(mod.displayName or mod.combatInfo.name)
	end
end

local function bossModEnd(name, success)
	--if you doing multiple boss encounter, encounter ends all boss defeated.
	bossModCallCount = bossModCallCount - 1
	if (bossModCallCount < 1) or not success then
		lastEncounterName = nil
		Skada:EndCombat(name, success)
	end
end

local function bossModKill(_, mod)
	if not mod.type or (mod.type ~= "SCENARIO") then
		bossModEnd(mod.displayName or mod.combatInfo.name, true)
	end
end

local function bossModWipe(_, mod)
	if not mod.type or (mod.type ~= "SCENARIO") then
		bossModEnd(mod.displayName or mod.combatInfo.name, false)
	end
end

function Skada:Hook()
	if DBM and not self.DBMhook then
		self.DBMhook = true
		DBM:RegisterCallback("pull", bossModStart)
		DBM:RegisterCallback("kill", bossModKill)
		DBM:RegisterCallback("wipe", bossModWipe)
	end
	-- if dbm and bigwigs both installed, ignore bigwigs
	--[[if BigWigsLoader and not self.bigwigshook and not DBM then
		self.bigwigshook = true
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossEngage", bossModStart)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWin", bossModKill)
		BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossWipe", bossModWipe)
	end]]
end

function Skada:OnEnable()
	self:ReloadSettings()

	cleuFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	popup:RegisterEvent("PLAYER_ENTERING_WORLD")
	popup:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	popup:RegisterEvent("GROUP_ROSTER_UPDATE")
	popup:RegisterEvent("UNIT_PET")
	popup:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	popup:RegisterEvent("PLAYER_REGEN_DISABLED")

	popup:RegisterEvent("PET_BATTLE_OPENING_START")
	popup:RegisterEvent("PET_BATTLE_CLOSE")

	popup:RegisterEvent("ENCOUNTER_START")
	popup:RegisterEvent("ENCOUNTER_END")

	if type(CUSTOM_CLASS_COLORS) == "table" then
		Skada.classcolors = CUSTOM_CLASS_COLORS
	end
	
	if self.moduleList then
		for i = 1, #self.moduleList do
			self.moduleList[i](self, L)
		end
		self.moduleList = nil
	end

	self:Hook()
	-- Instead of listening for callbacks on SharedMedia we simply wait a few seconds and then re-apply settings
	-- to catch any missing media. Lame? Yes.
	self:ScheduleTimer("ApplySettings", 2)
end

function Skada:AddLoadableModule(name, func)
	if not self.moduleList then self.moduleList = {} end
	self.moduleList[#self.moduleList+1] = func
	self:AddLoadableModuleCheckbox(name, L[name])
end
