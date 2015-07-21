Skada:AddLoadableModule("Interrupts", function(Skada, L)
	if Skada.db.profile.modulesBlocked.Interrupts then return end

	local mod = Skada:NewModule(L["Interrupts"])
	local modSpell = Skada:NewModule(L["Interrupts: Interrupted spell"])
	local modPlayer = Skada:NewModule(L["Interrupts: Interrupted spell > Targets"])

	mod.Order = 51

	local function log_interrupt(set, interrupt)
		local player = Skada:get_player(set, interrupt.playerid, interrupt.playername)
		if player then
			-- Add to player interrupts.
			player.interrupts = player.interrupts + 1

			-- Add to spell count.
			if not interrupt.dstname then interrupt.dstname = UNKNOWN end
			if not player.interruptspells[interrupt.extraspellid] then
				player.interruptspells[interrupt.extraspellid] = {amount = 0, targets = {}}
			end
			local spell = player.interruptspells[interrupt.extraspellid]

			spell.amount = spell.amount + 1
			
			-- Add to target count
			if not spell.targets[interrupt.dstname] then
				spell.targets[interrupt.dstname] = 0
			end

			spell.targets[interrupt.dstname] = spell.targets[interrupt.dstname] + 1

			-- Also add to set total interrupts.
			set.interrupts = set.interrupts + 1
		end
	end

	local interrupt = {}

	local function SpellInterrupt(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, sextraSpellId, sextraSpellName, sextraSchool)
		interrupt.playerid = srcGUID
		interrupt.playername = srcName
		interrupt.playerflags = srcFlags
		interrupt.dstname = dstName
		interrupt.spellid = spellId
		interrupt.spellname = spellName
		interrupt.extraspellid = sextraSpellId
		interrupt.extraspellname = sextraSpellName

		Skada:FixPets(interrupt)

		log_interrupt(Skada.current, interrupt)
		log_interrupt(Skada.total, interrupt)
	end

	function mod:Update(win, set)
		local max = 0
		local nr = 1
		for i, player in pairs(set._playeridx) do
			if player.interrupts > 0 then

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.value = player.interrupts
				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.valuetext = Skada:FormatHitNumber(player.interrupts)
				d.id = player.id
				d.class = player.class
				d.role = player.role
				if player.interrupts > max then
					max = player.interrupts
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	function modSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		win.modedata.pname = player.name
		self.title = L["Interrupts"]..": "..player.name
	end

	-- Detail view of a player.
	function modSpell:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player then
			for spellid, tbl in pairs(player.interruptspells) do
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

	function modPlayer:Enter(win, id, label)
		win.modedata.spellid = id
		modPlayer.title = L["Interrupts"]..": "..win.modedata.pname.." > "..label
	end

	-- Detail view of a player.
	function modPlayer:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player then
			for spellid, tbl in pairs(player.interruptspells) do
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

		Skada:RegisterForCL(SpellInterrupt, 'SPELL_INTERRUPT', {src_is_interesting = true})

		Skada:AddMode(self)	
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)
	end

	function mod:AddToTooltip(set, tooltip)
		GameTooltip:AddDoubleLine(L["Interrupts"], set.interrupts, 1,1,1)
	end

	function mod:GetSetSummary(set)
		return Skada:FormatHitNumber(set.interrupts)
	end

	-- Called by Skada when a new player is added to a set.
	function mod:AddPlayerAttributes(player)
		if not player.interrupts then
			player.interrupts = 0
		end
		if not player.interruptspells then
			player.interruptspells = {}
		end
	end

	-- Called by Skada when a new set is created.
	function mod:AddSetAttributes(set)
		if not set.interrupts then
			set.interrupts = 0
		end
	end
end)
