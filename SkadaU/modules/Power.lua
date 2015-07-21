Skada:AddLoadableModule("Power", function(Skada, L)
	if Skada.db.profile.modulesBlocked.Power then return end

	local mod = Skada:NewModule(L["Mana gained"])
	local modPlayer = Skada:NewModule(L["Mana gained: Spell list"])

	mod.Order = 35

	local function log_gain(set, gain)
		-- Get the player from set.
		local player = Skada:get_player(set, gain.playerid, gain.playername, true)
		if player then
			local amount = gain.amount
			-- Make sure power type exists.
			if not player.power[gain.type] then
				player.power[gain.type] = {spells = {}, amount = 0}
			end

			-- Make sure set power type exists.
			if not set.power[gain.type] then
				set.power[gain.type] = 0
			end

			local ppower = player.power[gain.type]
			-- Add to player total.
			ppower.amount = ppower.amount + amount

			-- Also add to set total gain.
			set.power[gain.type] = set.power[gain.type] + amount

			-- Create spell if it does not exist.
			if not ppower.spells[gain.spellid] then
				ppower.spells[gain.spellid] = 0
			end

			ppower.spells[gain.spellid] = ppower.spells[gain.spellid] + amount
		end
	end

	local MANA = 0

	local gain = {}

	local function SpellEnergize(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, samount, powerType)
		gain.playerid = dstGUID
		gain.playerflags = srcFlags
		gain.playername = dstName
		gain.spellid = spellId
		gain.spellname = spellName
		gain.amount = samount
		gain.type = tonumber(powerType)

		Skada:FixPets(gain)
		log_gain(Skada.current, gain)
		log_gain(Skada.total, gain)
	end

	function mod:Update(win, set)
		local nr = 1
		local max = 0

		for i, player in pairs(set._playeridx) do
			if player.power[MANA] then

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = player.id
				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.value = player.power[MANA].amount
				d.valuetext = Skada:FormatNumber(player.power[MANA].amount)
				d.class = player.class
				d.role = player.role

				if player.power[MANA].amount > max then
					max = player.power[MANA].amount
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	function modPlayer:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = player.name
	end

	-- Detail view of a player.
	function modPlayer:Update(win, set)
		-- View spells for this player.

		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player then

			for spellid, amount in pairs(player.power[MANA].spells) do
				if player.power[MANA].amount > 0 then

					local name, _, icon = GetSpellInfo(spellid)

					local d = win.dataset[nr] or {}
					win.dataset[nr] = d

					d.id = spellid
					d.label = name
					d.value = amount
					d.valuetext = Skada:FormatNumber(amount)..(" (%02.1f%%)"):format(amount / player.power[MANA].amount * 100)
					d.icon = icon
					d.spellid = spellid

					if amount > max then
						max = amount
					end

					nr = nr + 1
				end
			end
		end

		win.metadata.hasicon = true
		win.metadata.maxvalue = max
	end

	function mod:OnEnable()
		mod.metadata		= {showspots = true, click1 = modPlayer}
		modPlayer.metadata	= {}

		Skada:RegisterForCL(SpellEnergize, 'SPELL_ENERGIZE', {src_is_interesting = true})
		Skada:RegisterForCL(SpellEnergize, 'SPELL_PERIODIC_ENERGIZE', {src_is_interesting = true})

		Skada:AddMode(self)
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)
	end

	function mod:GetSetSummary(set)
		return Skada:FormatNumber(set.power[MANA] or 0)
	end

	-- Called by Skada when a new player is added to a set.
	function mod:AddPlayerAttributes(player)
		if not player.power then
			player.power = {}
		end
	end

	-- Called by Skada when a new set is created.
	function mod:AddSetAttributes(set)
		if not set.power then
			set.power = {}
		end
	end
end)
