﻿--
-- JSHB Warrior - crowd control module
--

if (select(2, UnitClass("player")) ~= "WARRIOR") then return end

local function stopCCTimer(spellID, targetGUID)
	for i=1,4 do
		if (JSHB.F.CrowdControl.ccFrame[i].active == true) and (JSHB.F.CrowdControl.ccFrame[i].spellID == spellID) and (JSHB.F.CrowdControl.ccFrame[i].guid == targetGUID) then
			JSHB.F.CrowdControl.ccFrame[i]:SetAlpha(0)
			JSHB.F.CrowdControl.ccFrame[i].guid = 0
			JSHB.F.CrowdControl.ccFrame[i].spellID = 0
			JSHB.F.CrowdControl.ccFrame[i].active = false
			JSHB.F.CrowdControl.ccFrame[i].killtime = 0

			if JSHB.F.CrowdControl.ccFrame[i].timer then
				JSHB.F.CrowdControl.ccFrame[i].timer.enabled = nil
				JSHB.F.CrowdControl.ccFrame[i].timer:Hide()
			end

			break -- Found the right one, stop the loop
		end
	end
end

local function addCCTimer(spellID, targetGUID, expireTime)
	for i=1,4 do
		if (JSHB.F.CrowdControl.ccFrame[i].active == false) then
			JSHB.F.CrowdControl.ccFrame[i].Icon:ClearAllPoints()
			JSHB.F.CrowdControl.ccFrame[i].Icon:SetAllPoints(JSHB.F.CrowdControl.ccFrame[i])
			JSHB.F.CrowdControl.ccFrame[i].Icon:SetTexture(select(3, GetSpellInfo(spellID) ))

			if JSHB.db.profile.crowdcontrol.enabletexcoords then
				JSHB.F.CrowdControl.ccFrame[i].Icon:SetTexCoord(unpack(JSHB.db.profile.crowdcontrol.texcoords) )
			end

			if JSHB.moversLocked then
				JSHB.F.CrowdControl.ccFrame[i]:SetAlpha(1)
			end

			JSHB.F.CrowdControl.ccFrame[i].killtime = GetTime() + expireTime + .2
			JSHB.F.CrowdControl.ccFrame[i].guid = targetGUID -- Need to know the target id associated with this frame.
			JSHB.F.CrowdControl.ccFrame[i].spellID = spellID
			JSHB.F.CrowdControl.ccFrame[i].active = true
			local timer = JSHB.F.CrowdControl.ccFrame[i].timer or JSHB.Timer_Create(JSHB.F.CrowdControl.ccFrame[i])
			timer.start = GetTime()
			timer.duration = expireTime
			timer.enabled = true
			timer.nextUpdate = 0
			timer:Show()
			break
		end
	end
end

local function refreshCCTimer(spellID, targetGUID, expireTime)
	for i=1,4 do
		if (JSHB.F.CrowdControl.ccFrame[i].active == true) and (JSHB.F.CrowdControl.ccFrame[i].spellID == spellID) and (JSHB.F.CrowdControl.ccFrame[i].guid == targetGUID) then
			JSHB.F.CrowdControl.ccFrame[i].killtime = GetTime() + expireTime + .2
			local timer = JSHB.F.CrowdControl.ccFrame[i].timer or JSHB.Timer_Create(JSHB.F.CrowdControl.ccFrame[i])
			timer.start = GetTime()
			timer.duration = expireTime
			timer.enabled = true
			timer.nextUpdate = 0
			timer:Show()
			break
		end
	end
end

local function stopAOETimer(spellID)
	for i=1,4 do
		if (JSHB.F.CrowdControl.ccFrame[i].active == true) and (JSHB.F.CrowdControl.ccFrame[i].spellID == spellID) then
			if (JSHB.F.CrowdControl.ccFrame[i].aoecount == 0) then
				JSHB.F.CrowdControl.ccFrame[i]:SetAlpha(0)
				JSHB.F.CrowdControl.ccFrame[i].isaoe = false
				JSHB.F.CrowdControl.ccFrame[i].aoecount = 0
				JSHB.F.CrowdControl.ccFrame[i].guid = 0
				JSHB.F.CrowdControl.ccFrame[i].spellID = 0
				JSHB.F.CrowdControl.ccFrame[i].active = false
				JSHB.F.CrowdControl.ccFrame[i].killtime = 0
				JSHB.F.CrowdControl.ccFrame[i].aoetext:Hide()

				if JSHB.F.CrowdControl.ccFrame[i].timer then
					JSHB.F.CrowdControl.ccFrame[i].timer.enabled = nil
					JSHB.F.CrowdControl.ccFrame[i].timer:Hide()
				end

				break
			else
				JSHB.F.CrowdControl.ccFrame[i].aoecount = JSHB.F.CrowdControl.ccFrame[i].aoecount - 1
				JSHB.F.CrowdControl.ccFrame[i].aoetext:SetFormattedText("%i", JSHB.F.CrowdControl.ccFrame[i].aoecount)
				break
			end
		end
	end
end

local function addAOETimer(spellID, expireTime)
	for i=1,4 do
		if (JSHB.F.CrowdControl.ccFrame[i].spellID == spellID) then
			JSHB.F.CrowdControl.ccFrame[i].aoecount = JSHB.F.CrowdControl.ccFrame[i].aoecount + 1
			JSHB.F.CrowdControl.ccFrame[i].aoetext:SetFormattedText("%i", JSHB.F.CrowdControl.ccFrame[i].aoecount)
			JSHB.F.CrowdControl.ccFrame[i].aoetext:Show()
			break
		else
			if (JSHB.F.CrowdControl.ccFrame[i].active == false) then
				JSHB.F.CrowdControl.ccFrame[i].Icon:ClearAllPoints()
				JSHB.F.CrowdControl.ccFrame[i].Icon:SetAllPoints(JSHB.F.CrowdControl.ccFrame[i])
				JSHB.F.CrowdControl.ccFrame[i].Icon:SetTexture(select(3, GetSpellInfo(spellID) ))

				if JSHB.db.profile.crowdcontrol.enabletexcoords then
					JSHB.F.CrowdControl.ccFrame[i].Icon:SetTexCoord(unpack(JSHB.db.profile.crowdcontrol.texcoords) )
				end

				if JSHB.moversLocked then
					JSHB.F.CrowdControl.ccFrame[i]:SetAlpha(1)
				end

				JSHB.F.CrowdControl.ccFrame[i].killtime = GetTime() + expireTime + .2
				JSHB.F.CrowdControl.ccFrame[i].spellID = spellID
				JSHB.F.CrowdControl.ccFrame[i].isaoe = true
				JSHB.F.CrowdControl.ccFrame[i].aoecount = 1
				JSHB.F.CrowdControl.ccFrame[i].active = true

				local timer = JSHB.F.CrowdControl.ccFrame[i].timer or JSHB.Timer_Create(JSHB.F.CrowdControl.ccFrame[i])
				timer.start = GetTime()
				timer.duration = expireTime
				timer.enabled = true
				timer.nextUpdate = 0
				timer:Show()

				JSHB.F.CrowdControl.ccFrame[i].aoetext:SetFormattedText("%i", JSHB.F.CrowdControl.ccFrame[i].aoecount)
				break
			end
		end
	end
end

local function refreshAOETimer(spellID, expireTime)
	local noFrame = true
	for i=1,4 do
		if (JSHB.F.CrowdControl.ccFrame[i].active == true) and (JSHB.F.CrowdControl.ccFrame[i].isaoe == true) and (JSHB.F.CrowdControl.ccFrame[i].spellID == spellID) then
			noFrame = false
			JSHB.F.CrowdControl.ccFrame[i].killtime = GetTime() + expireTime + .2
			local timer = JSHB.F.CrowdControl.ccFrame[i].timer or JSHB.Timer_Create(JSHB.F.CrowdControl.ccFrame[i])
			timer.start = GetTime()
			timer.duration = expireTime
			timer.enabled = true
			timer.nextUpdate = 0
			timer:Show()
			break
		end
	end

	if noFrame then
		addAOETimer(spellID, expireTime)
	end
end

function JSHB.SetupCrowdControlModule(lockName)

	-- Deconstruction
	if JSHB.F.CrowdControl then
		JSHB.F.CrowdControl:Hide()
		JSHB.F.CrowdControl.ccFrame[1]:SetScript("OnUpdate", nil)
		JSHB.F.CrowdControl.ccFrame[1]:UnregisterAllEvents()
		for i=1,4 do
			JSHB.F.CrowdControl.ccFrame[i]:SetAlpha(0)
		end
		JSHB.DeregisterMovableFrame("MOVER_CROWDCONTROL")
		JSHB.F.CrowdControl:SetParent(nil)
	end

	-- Construction
	if not JSHB.db.profile.crowdcontrol.enabled then return end

	local CROWDCONTROL_UPDATEINTERVAL = 0.15

	-- Create the Frame
	JSHB.F.CrowdControl = JSHB.MakeFrame(JSHB.F.CrowdControl, "Frame", "JSCM_CROWDCONTROL", JSHB.db.profile.crowdcontrol.anchor[2] or UIParent)
	JSHB.F.CrowdControl:SetParent(JSHB.db.profile.crowdcontrol.anchor[2] or UIParent)
	JSHB.F.CrowdControl:ClearAllPoints()
	JSHB.F.CrowdControl:SetSize(50, 50) -- Temporary, will set it after we get offsets
	JSHB.F.CrowdControl:SetPoint(JSHB.GetActiveAnchor(JSHB.db.profile.crowdcontrol.anchor) )
	JSHB.F.CrowdControl.ccFrame = {}
	for i=1,4 do -- Allocating 4 frames, more than enough, low overhead
		JSHB.F.CrowdControl.ccFrame[i] = JSHB.MakeFrame(JSHB.F.CrowdControl.ccFrame[i], "Frame", nil, JSHB.F.CrowdControl)
		JSHB.F.CrowdControl.ccFrame[i]:SetParent(JSHB.F.CrowdControl)
		JSHB.F.CrowdControl.ccFrame[i]:ClearAllPoints()
		JSHB.F.CrowdControl.ccFrame[i]:SetSize(JSHB.db.profile.crowdcontrol.iconsize, JSHB.db.profile.crowdcontrol.iconsize)
		JSHB.F.CrowdControl.ccFrame[i]:SetPoint("CENTER", JSHB.F.CrowdControl, "CENTER") -- Temporary
		JSHB.F.CrowdControl.ccFrame[i].background = JSHB.MakeBackground(JSHB.F.CrowdControl.ccFrame[i], JSHB.db.profile.crowdcontrol, nil, JSHB.F.CrowdControl.ccFrame[i].background)
		JSHB.F.CrowdControl.ccFrame[i]:ClearAllPoints() -- Now that we made the backdrop/border we have offsets to use.
		local x = ( (i-1) * (JSHB.GetFrameOffset(JSHB.F.CrowdControl.ccFrame[i], "LEFT", 1) + JSHB.GetFrameOffset(JSHB.F.CrowdControl.ccFrame[i], "RIGHT", 1) + JSHB.db.profile.crowdcontrol.iconsize + 2) )
		if JSHB.db.profile.crowdcontrol.anchor[4] >= 0 then -- Expand to Right
			JSHB.F.CrowdControl.ccFrame[i]:SetPoint("TOPLEFT", JSHB.F.CrowdControl, "TOPLEFT", x, 0)
		else -- Expand to Left
			JSHB.F.CrowdControl.ccFrame[i]:SetPoint("TOPRIGHT", JSHB.F.CrowdControl, "TOPRIGHT", -x, 0)
		end
		JSHB.F.CrowdControl.ccFrame[i].Icon = JSHB.F.CrowdControl.ccFrame[i].Icon or JSHB.F.CrowdControl.ccFrame[i]:CreateTexture(nil, "BACKGROUND")
		JSHB.F.CrowdControl.ccFrame[i].Icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up") -- Temporary Texture
		if JSHB.db.profile.crowdcontrol.enabletexcoords then
			JSHB.F.CrowdControl.ccFrame[i].Icon:SetTexCoord(unpack(JSHB.db.profile.crowdcontrol.texcoords) )
		else
			JSHB.F.CrowdControl.ccFrame[i].Icon:SetTexCoord(0, 1, 0, 1)
		end
		JSHB.F.CrowdControl.ccFrame[i]:SetAlpha(0)
		JSHB.F.CrowdControl.ccFrame[i]:Show()
		JSHB.F.CrowdControl.ccFrame[i].guid = 0
		JSHB.F.CrowdControl.ccFrame[i].spellID = 0
		JSHB.F.CrowdControl.ccFrame[i].active = false
		JSHB.F.CrowdControl.ccFrame[i].aoecount = 0
		JSHB.F.CrowdControl.ccFrame[i].isaoe = false

		-- setup counter text for AOE CC
		JSHB.F.CrowdControl.ccFrame[i].aoetext = JSHB.F.CrowdControl.ccFrame[i].aoetext or JSHB.F.CrowdControl.ccFrame[i]:CreateFontString(nil, "OVERLAY")
		JSHB.F.CrowdControl.ccFrame[i].aoetext:ClearAllPoints()
		JSHB.F.CrowdControl.ccFrame[i].aoetext:SetFont(JSHB.GetActiveFont(JSHB.db.profile.crowdcontrol.aoefont) )
		JSHB.F.CrowdControl.ccFrame[i].aoetext:SetTextColor(unpack(JSHB.db.profile.crowdcontrol.aoefontcolor) )
		JSHB.F.CrowdControl.ccFrame[i].aoetext:SetPoint("BOTTOMRIGHT", JSHB.F.CrowdControl.ccFrame[i], "BOTTOMRIGHT", 1  + JSHB.db.profile.crowdcontrol.aoefontoffset, 1)
		JSHB.F.CrowdControl.ccFrame[i].aoetext:SetJustifyH("BOTTOM")
	end
	-- Properly set the host frame's size for the movers functionality
	JSHB.F.CrowdControl:SetSize(
		( (JSHB.db.profile.crowdcontrol.iconsize +
				(JSHB.GetFrameOffset(JSHB.F.CrowdControl.ccFrame[1], "LEFT", 1) + JSHB.GetFrameOffset(JSHB.F.CrowdControl.ccFrame[1], "RIGHT", 1) + 2) ) * 3) -
				JSHB.GetFrameOffset(JSHB.F.CrowdControl.ccFrame[1], "LEFT", 1) - JSHB.GetFrameOffset(JSHB.F.CrowdControl.ccFrame[1], "RIGHT", 1) - 2,
		JSHB.db.profile.crowdcontrol.iconsize)
	-- Register the mover frame
	JSHB.RegisterMovableFrame(
		"MOVER_CROWDCONTROL",
		JSHB.F.CrowdControl,
		JSHB.F.CrowdControl,
		JSHB.L["Crowd Control"],
		JSHB.db.profile.crowdcontrol,
		JSHB.SetupCrowdControlModule,
		JSHB.defaults.profile.crowdcontrol,
		JSHB.db.profile.crowdcontrol
	)
	-- First frame calls the update routine.
	JSHB.F.CrowdControl.ccFrame[1].updateTimer = 0
	JSHB.F.CrowdControl.ccFrame[1]:SetScript("OnUpdate",
		function(s, elapsed)
			s.updateTimer = s.updateTimer + elapsed
			if s.updateTimer > CROWDCONTROL_UPDATEINTERVAL then
				s._j = 1
				for i=1,4 do
					if (JSHB.F.CrowdControl.ccFrame[i].active == true) then
						if (JSHB.F.CrowdControl.ccFrame[i].killtime < GetTime() ) then
							if (JSHB.F.CrowdControl.ccFrame[i].isaoe) then
								stopAOETimer(JSHB.F.CrowdControl.ccFrame[i].spellID)
							else
								stopCCTimer(JSHB.F.CrowdControl.ccFrame[i].spellID, JSHB.F.CrowdControl.ccFrame[i].guid)
							end
						elseif (JSHB.F.CrowdControl.ccFrame[i].isaoe) and (JSHB.F.CrowdControl.ccFrame[i].aoecount == 0) then
							stopAOETimer(JSHB.F.CrowdControl.ccFrame[i].spellID)
						else
							s._x = ( (s._j-1) * (JSHB.GetFrameOffset(JSHB.F.CrowdControl.ccFrame[i], "LEFT", 1) + JSHB.GetFrameOffset(JSHB.F.CrowdControl.ccFrame[i], "RIGHT", 1) + JSHB.db.profile.crowdcontrol.iconsize + 2) )
							if JSHB.db.profile.crowdcontrol.anchor[4] >= 0 then -- Expand to Right
								JSHB.F.CrowdControl.ccFrame[i]:SetPoint("TOPLEFT", JSHB.F.CrowdControl, "TOPLEFT", s._x, 0)
							else -- Expand to Left
								JSHB.F.CrowdControl.ccFrame[i]:SetPoint("TOPRIGHT", JSHB.F.CrowdControl, "TOPRIGHT", -s._x, 0)
							end
							s._j = s._j + 1
						end
					end
				end
			end
		end
	)

	-- Event handler
	JSHB.F.CrowdControl.ccFrame[1]:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	JSHB.F.CrowdControl.ccFrame[1]:SetScript("OnEvent",
		function(s, event, ...)
			s._, s._subEvent, s._, s._sourceGUID, s._, s._, s._, s._destGUID, s._, s._destFlags, s._, s._spellId = ...

			if (s._subEvent == "SPELL_AURA_APPLIED") then
				-- Hamstring
				if (s._spellId == 1715) and (s._sourceGUID == UnitGUID("player")) and (JSHB.db.profile.crowdcontrol.hamstring) then
					addCCTimer(1715, s._destGUID, 15)
				-- Storm Bolt
				elseif (s._spellId == 132169) and (s._sourceGUID == UnitGUID("player")) and (JSHB.db.profile.crowdcontrol.stormbolt) then
					addCCTimer(132169, s._destGUID, 4)
				-- Intimidating Shout
				elseif (s._spellId == 5246) and (s._sourceGUID == UnitGUID("player")) and (JSHB.db.profile.crowdcontrol.intimidatingshout) then
					addAOETimer(5246, 8)
				-- Piercing Howl
				elseif (s._spellId == 12323) and (s._sourceGUID == UnitGUID("player")) and (JSHB.db.profile.crowdcontrol.piercinghowl) then
					addAOETimer(12323, 15)
				-- Thunder Clap
				elseif (s._spellId == 6343) and (s._sourceGUID == UnitGUID("player")) and (JSHB.db.profile.crowdcontrol.thunderclap) then
					addAOETimer(6343, 10)
				-- Shockwave
				elseif (s._spellId == 132168) and (s._sourceGUID == UnitGUID("player")) and (JSHB.db.profile.crowdcontrol.shockwave) then
					addAOETimer(132168, 4)
				end
			elseif (s._subEvent == "SPELL_AURA_REFRESH") then
				-- Hamstring
				if (s._spellId == 1715) and (s._sourceGUID == UnitGUID("player")) and (JSHB.db.profile.crowdcontrol.hamstring) then
					refreshCCTimer(1715, s._destGUID, 15)
				-- Piercing Howl
				elseif (s._spellId == 12323) and (s._sourceGUID == UnitGUID("player")) and (JSHB.db.profile.crowdcontrol.piercinghowl) then
					refreshAOETimer(12323, 15)
				-- Thunder Clap
				elseif (s._spellId == 6343) and (s._sourceGUID == UnitGUID("player")) and (JSHB.db.profile.crowdcontrol.thunderclap) then
					refreshAOETimer(6343, 10)
				end
			elseif (s._subEvent == "SPELL_AURA_REMOVED") then
				-- Hamstring
				if (s._spellId == 1715) and (s._sourceGUID == UnitGUID("player")) then
					stopCCTimer(1715, s._destGUID)
				-- Storm Bolt
				elseif (s._spellId == 132169) and (s._sourceGUID == UnitGUID("player")) then
					stopCCTimer(132169, s._destGUID)
				-- Intimidating Shout
				elseif (s._spellId == 5246) and (s._sourceGUID == UnitGUID("player")) then
					stopAOETimer(5246)
				-- Piercing Howl
				elseif (s._spellId == 12323) and (s._sourceGUID == UnitGUID("player")) then
					stopAOETimer(12323)
				-- Thunder Clap
				elseif (s._spellId == 6343) and (s._sourceGUID == UnitGUID("player")) then
					stopAOETimer(6343)
				-- Shockwave
				elseif (s._spellId == 132168) and (s._sourceGUID == UnitGUID("player")) then
					stopAOETimer(132168)
				end
			end	
		end)
	JSHB.F.CrowdControl:Show()
end