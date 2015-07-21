Skada:AddLoadableModule("CC", function(Skada, L)
	if Skada.db.profile.modulesBlocked.CC then return end

	local mod = Skada:NewModule(L["CC breakers"])
	local modMobList = Skada:NewModule(L["CC breakers: Broken mob list"])

	mod.Order = 71

	-- CC spell IDs shamelessly stolen from Recount - thanks!
	local CCId={
		[118]=true, -- Polymorph
		[28272]=true, -- Polymorph Pig
		[28271]=true, -- Polymorph Turtle
		[61305]=true, -- Polymorph Black Cat
		[61721]=true, -- Polymorph Rabbit
		[61780]=true, -- Polymorph Turkey
		[9484]=true, -- Shackle Undead
		[3355]=true, -- Freezing Trap
		[19386]=true, -- Wyvern Sting
		[339]=true, -- Entangling Roots
		[2637]=true, -- Hibernate
		[6770]=true, -- Sap
		[6358]=true, -- Seduction (succubus)
		[20066]=true, -- Repentance
		[51514]=true, -- Hex
		[76780]=true, -- Bind Elemental
	}

	local function log_ccbreak(set, cc)
		-- Fetch the player.
		local player = Skada:get_player(set, cc.playerid, cc.playername)
		if player then
			-- Add to player count.
			player.ccbreaks = player.ccbreaks + 1
			
			-- Add dest name count.
			if not cc.dstName then cc.dstName = UNKNOWN end
			if not player.ccbreaktargets[cc.dstName] then
				player.ccbreaktargets[cc.dstName] = 0
			end
			player.ccbreaktargets[cc.dstName] = player.ccbreaktargets[cc.dstName] + 1

			-- Add to set count.
			set.ccbreaks = set.ccbreaks + 1
		end
	end

	local cc = {}

	local function SpellAuraBroken(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool, auraType)
		if CCId[spellId] then
			cc.playerid = srcGUID
			cc.playerflags = srcFlags
			cc.playername = srcName
			cc.dstName = dstName

			Skada:FixPets(cc)
			-- Log CC break.
			log_ccbreak(Skada.current, cc)
			log_ccbreak(Skada.total, cc)
		end
	end

	function mod:Update(win, set)
		local max = 0
		local nr = 1
		for i, player in pairs(set._playeridx) do
			if player.ccbreaks > 0 then

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.value = player.ccbreaks
				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.valuetext = Skada:FormatHitNumber(player.ccbreaks)
				d.id = player.id
				d.class = player.class
				d.role = player.role
				if player.ccbreaks > max then
					max = player.ccbreaks
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Detail view of a player.
	function modMobList:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["CC breaks"]..": "..player.name
	end

	function modMobList:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player then
			for name, amount in pairs(player.ccbreaktargets) do
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = name
				d.label = name
				d.value = amount
				d.valuetext = Skada:FormatHitNumber(amount)

				if amount > max then
					max = amount
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	function mod:OnEnable()
		mod.metadata =			{showspots = true, click1 = modMobList}
		modMobList.metadata =	{}

		Skada:RegisterForCL(SpellAuraBroken, 'SPELL_AURA_BROKEN', {src_is_interesting = true})
		Skada:RegisterForCL(SpellAuraBroken, 'SPELL_AURA_BROKEN_SPELL', {src_is_interesting = true})

		Skada:AddMode(self)
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)
	end

	function mod:AddToTooltip(set, tooltip)
		GameTooltip:AddDoubleLine(L["CC breaks"], set.ccbreaks, 1,1,1)
	end

	function mod:GetSetSummary(set)
		return Skada:FormatHitNumber(set.ccbreaks)
	end

	-- Called by Skada when a new player is added to a set.
	function mod:AddPlayerAttributes(player)
		if not player.ccbreaks then
			player.ccbreaks = 0
		end
		if not player.ccbreaktargets then
			player.ccbreaktargets = {}
		end
	end

	-- Called by Skada when a new set is created.
	function mod:AddSetAttributes(set)
		if not set.ccbreaks then
			set.ccbreaks = 0
		end
	end

	function mod:OnInitialize()
	end
end)
