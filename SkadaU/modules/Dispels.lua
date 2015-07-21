Skada:AddLoadableModule("Dispels", function(Skada, L)
	if Skada.db.profile.modulesBlocked.Dispels then return end

	local mod = Skada:NewModule(L["Dispels"])
	local modSpell = Skada:NewModule(L["Dispels: Dispeled spell"])
	local modPlayer = Skada:NewModule(L["Dispels: Dispeled spell > Targets"])

	mod.Order = 61

	local function log_dispell(set, dispell)
		local player = Skada:get_player(set, dispell.playerid, dispell.playername)
		if player then
			-- Add to player dispels.
			player.dispells = player.dispells + 1

			-- Add to spell count.
			if not dispell.dstname then dispell.dstname = UNKNOWN end
			if not player.dispellspells[dispell.extraspellid] then
				player.dispellspells[dispell.extraspellid] = {amount = 0, targets = {}}
			end
			local spell = player.dispellspells[dispell.extraspellid]

			spell.amount = spell.amount + 1
			
			-- Add to target count
			if not spell.targets[dispell.dstname] then
				spell.targets[dispell.dstname] = 0
			end

			spell.targets[dispell.dstname] = spell.targets[dispell.dstname] + 1

			-- Also add to set total dispels.
			set.dispells = set.dispells + 1
		end
	end

	local dispell = {}

	local function SpellDispel(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, sextraSpellId, sextraSpellName, sextraSchool, auraType)
		dispell.playerid = srcGUID
		dispell.playername = srcName
		dispell.playerflags = srcFlags
		dispell.dstname = dstName
		dispell.spellid = spellId
		dispell.spellname = spellName
		dispell.extraspellid = sextraSpellId
		dispell.extraspellname = sextraSpellName

		Skada:FixPets(dispell)

		log_dispell(Skada.current, dispell)
		log_dispell(Skada.total, dispell)
	end

	function mod:Update(win, set)
		local max = 0
		local nr = 1

		for i, player in pairs(set._playeridx) do
			if player.dispells > 0 then

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
				d.value = player.dispells
				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.class = player.class
				d.role = player.role
				d.id = player.id
				d.valuetext = Skada:FormatHitNumber(player.dispells)
				if player.dispells > max then
					max = player.dispells
				end
				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Detail view of a player.
	function modSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		win.modedata.pname = player.name
		self.title = L["Dispels"]..": "..player.name
	end

	function modSpell:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player then
			for spellid, tbl in pairs(player.dispellspells) do
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = spellid
				local name, _, icon = GetSpellInfo(spellid)
				d.label = name
				d.value = tbl.amount
				d.valuetext = Skada:FormatHitNumber(tbl.amount)
				d.icon = icon
				d.spellid = spellid

				if tbl.amount > max then
					max = tbl.amount
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Detail view of a player.
	function modPlayer:Enter(win, id, label)
		win.modedata.spellid = id
		self.title = L["Dispels"]..": "..win.modedata.pname.." > "..label
	end

	function modPlayer:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player then
			for spellid, tbl in pairs(player.dispellspells) do
				if win.modedata.spellid == spellid then
					for name, amount in pairs(tbl.targets) do
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
			end
		end

		win.metadata.maxvalue = max
	end

	function mod:OnEnable()
		mod.metadata 		= {showspots = true, click1 = modSpell}
		modSpell.metadata	= {click1 = modPlayer}
		modPlayer.metadata	= {}

		Skada:RegisterForCL(SpellDispel, 'SPELL_STOLEN', {src_is_interesting = true})
		Skada:RegisterForCL(SpellDispel, 'SPELL_DISPEL', {src_is_interesting = true})

		Skada:AddMode(self)
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)
	end

	function mod:AddToTooltip(set, tooltip)
		GameTooltip:AddDoubleLine(L["Dispels"], set.dispells, 1,1,1)
	end

	function mod:GetSetSummary(set)
		return Skada:FormatHitNumber(set.dispells)
	end

	-- Called by Skada when a new player is added to a set.
	function mod:AddPlayerAttributes(player)
		if not player.dispells then
			player.dispells = 0
		end
		if not player.dispellspells then
			player.dispellspells = {}
		end
	end

	-- Called by Skada when a new set is created.
	function mod:AddSetAttributes(set)
		if not set.dispells then
			set.dispells = 0
		end
	end
end)
