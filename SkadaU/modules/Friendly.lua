Skada:AddLoadableModule("Friendly", function(Skada, L)
	if Skada.db.profile.modulesBlocked.Friendly then return end

	local mod = Skada:NewModule(L["Friendly damage list"])
	local modSpell = Skada:NewModule(L["Friendly damage: Spell list"])
	local modPlayer = Skada:NewModule(L["Friendly damage: Damaged player list"])
	local modPlayerSpell = Skada:NewModule(L["Friendly damage: Damaged player list > Spells"])

	mod.Order = 31

	----------------------------------------------------------------------------------------------------------------
	-- Record data to DB.
	local function log_friendly_damage(set, dmg)
		-- Get the player.
		local player = Skada:get_player(set, dmg.playerid, dmg.playername)
		if player then
			local amount = dmg.amount

			-- Also add to set total damage.
			set.friendlydamage = set.friendlydamage + amount

			-- Add spell to player if it does not exist.
			if not player.friendlydamagespells[dmg.spellname] then
				player.friendlydamagespells[dmg.spellname] = {id = dmg.spellid, hit = 0, damage = 0}
			end

			local spell = player.friendlydamagespells[dmg.spellname]
			-- Add to player total damage.
			player.friendlydamage = player.friendlydamage + amount

			spell.hit = spell.hit + 1

			if spell.max == nil or amount > spell.max then
				spell.max = amount
			end

			if (spell.min == nil or amount < spell.min) and not dmg.missed then
				spell.min = amount
			end

			spell.damage = spell.damage + amount
			
			-- Add friendly damage target.
			if not dmg.dstname then dmg.dstname = UNKNOWN end
			if not player.friendlydamaged[dmg.dstname] then
				player.friendlydamaged[dmg.dstname] = {}
			end

			local damaged = player.friendlydamaged[dmg.dstname]
			if not damaged[dmg.spellname] then
				damaged[dmg.spellname] = {id = dmg.spellid, amount = 0}
			end

			-- Add to destination.
			damaged[dmg.spellname].amount = damaged[dmg.spellname].amount + amount
		end
	end

	-- Listen combat log.
	local dmg = {}

	local function SpellDamageFriendly(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, samount)
		dmg.playerid = srcGUID
		dmg.playerflags = srcFlags
		dmg.dstname = dstName
		dmg.playername = srcName
		dmg.spellid = spellId
		dmg.spellname = spellName
		dmg.amount = samount

		Skada:FixPets(dmg)
		log_friendly_damage(Skada.current, dmg)
		log_friendly_damage(Skada.total, dmg)
	end

	local function SpellDamageFriendlyDot(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, samount)
		dmg.playerid = srcGUID
		dmg.playerflags = srcFlags
		dmg.dstname = dstName
		dmg.playername = srcName
		dmg.spellid = spellId
		dmg.spellname = spellName .. L[" (DoT)"]
		dmg.amount = samount

		Skada:FixPets(dmg)
		log_friendly_damage(Skada.current, dmg)
		log_friendly_damage(Skada.total, dmg)
	end

	local function SwingDamageFriendly(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, samount)
		dmg.playerid = srcGUID
		dmg.playername = srcName
		dmg.playerflags = srcFlags
		dmg.dstname = dstName
		dmg.spellid = 6603
		dmg.spellname = L["Attack"]
		dmg.amount = samount

		Skada:FixPets(dmg)
		log_friendly_damage(Skada.current, dmg)
		log_friendly_damage(Skada.total, dmg)
	end

	----------------------------------------------------------------------------------------------------------------
	-- Friendly Damage overview.
	function mod:Update(win, set)
		local max = 0
		local nr = 1

		for i, player in pairs(set._playeridx) do
			if player.friendlydamage > 0 then
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
				d.label = Skada.db.profile.showrealm and player.name or player.shortname

				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(player.friendlydamage), self.metadata.columns.Damage,
												string.format("%02.1f%%", player.friendlydamage / set.friendlydamage * 100), self.metadata.columns.Percent
											)

				d.value = player.friendlydamage
				d.id = player.id
				d.class = player.class
				d.role = player.role
				if player.friendlydamage > max then
					max = player.friendlydamage
				end
				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Detail spell of a player.
	function modSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["Friendly damage"]..": "..player.name
	end

	function modSpell:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player and (player.friendlydamage > 0) then
			for spellname, spell in pairs(player.friendlydamagespells) do

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
				d.label = spellname
				d.id = spellname
				local _, _, icon = GetSpellInfo(spell.id)
				d.icon = icon
				d.spellid = spell.id
				d.value = spell.damage
				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(spell.damage), self.metadata.columns.Damage,
												string.format("%02.1f%%", spell.damage / player.friendlydamage * 100), self.metadata.columns.Percent
											)
				if spell.damage > max then
					max = spell.damage
				end
				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Player view showing damaged mobs.
	function modPlayer:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		win.modedata.pname = player.name
		self.title = L["Damaged friend"]..": "..player.name
	end

	function modPlayer:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local max = 0
		local nr = 1

		if player and (player.friendlydamage > 0) then

			for name, tbl in pairs(player.friendlydamaged) do
				local amount = 0
				for spellname, spell in pairs(tbl) do
					amount = amount + spell.amount
				end
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
				d.label = name
				d.id = name
				d.value = amount
				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(amount), self.metadata.columns.Damage,
												string.format("%02.1f%%", amount / player.friendlydamage * 100), self.metadata.columns.Percent
											)
				if amount > max then
					max = amount
				end
				nr = nr + 1
			end
		end
		
		win.metadata.maxvalue = max
	end

	function modPlayerSpell:Enter(win, id, label)
		win.modedata.tname = label
		self.title =  L["Spell list"]..": "..win.modedata.pname.." > "..label
	end

	function modPlayerSpell:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local max = 0
		local nr = 1

		-- If we reset we have no data.
		if player then
			for name, tbl in pairs(player.friendlydamaged) do
				if name == win.modedata.tname then
					local total = 0
					for spellname, spell in pairs(tbl) do
						total = total + spell.amount
					end
					if total > 0 then
						for spellname, spell in pairs(tbl) do
							local d = win.dataset[nr] or {}
							win.dataset[nr] = d
							d.label = spellname
							d.id = spellname
							local _, _, icon = GetSpellInfo(spell.id)
							d.icon = icon
							d.spellid = spell.id
							d.value = spell.amount
							d.valuetext = Skada:FormatValueText(
															Skada:FormatNumber(spell.amount), self.metadata.columns.Damage,
															string.format("%02.1f%%", spell.amount / total * 100), self.metadata.columns.Percent
														)
							if spell.amount > max then
								max = spell.amount
							end
							nr = nr + 1
						end
					end
				end
			end
		end

		win.metadata.maxvalue = max
	end

	----------------------------------------------------------------------------------------------------------------
	-- Set mod property
	function mod:OnEnable()
		mod.metadata =				{showspots = true, click1 = modSpell, click2 = modPlayer, columns = {Damage = true, Percent = true}}
		modSpell.metadata =			{columns = {Damage = true, Percent = true}}
		modPlayer.metadata =		{click1 = modPlayerSpell, columns = {Damage = true, Percent = true}}
		modPlayerSpell.metadata =	{columns = {Damage = true, Percent = true}}

		Skada:RegisterForCL(SpellDamageFriendly, 'SPELL_DAMAGE', {src_is_interesting = true, dst_is_interesting = true})
		Skada:RegisterForCL(SpellDamageFriendly, 'RANGE_DAMAGE', {src_is_interesting = true, dst_is_interesting = true})
		Skada:RegisterForCL(SpellDamageFriendlyDot, 'SPELL_PERIODIC_DAMAGE', {src_is_interesting = true, dst_is_interesting = true})

		Skada:RegisterForCL(SwingDamageFriendly, 'SWING_DAMAGE', {src_is_interesting = true, dst_is_interesting = true})

		Skada:AddMode(self)
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)
	end

	function mod:GetSetSummary(set)
		return Skada:FormatNumber(set.friendlydamage)
	end

	function mod:AddPlayerAttributes(player)
		if not player.friendlydamage then
			player.friendlydamage = 0
			player.friendlydamagespells = {}
		end
		if not player.friendlydamaged then
			player.friendlydamaged = {}
		end
	end

	function mod:AddSetAttributes(set)
		if not set.friendlydamage then
			set.friendlydamage = 0
		end
	end
end)
