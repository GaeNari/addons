Skada:AddLoadableModule("DamageTaken", function(Skada, L)
	if Skada.db.profile.modulesBlocked.DamageTaken then return end

	local mod = Skada:NewModule(L["Damage taken list"])
	local modPlayerSpell = Skada:NewModule(L["Damage taken: Player taken spell list"])
	local spell = Skada:NewModule(L["Damage taken by spell"])
	local spellPlayer = Skada:NewModule(L["Damage taken by spell: Player list"])
	local mob = Skada:NewModule(L["Damage taken by mob"])
	local mobPlayer = Skada:NewModule(L["Damage taken by mob: Player list"])
	local mobPlayerSpell = Skada:NewModule(L["Damage taken by mob: Player list > Spells"])

	mod.Order = 21
	spell.Order = 22
	mob.Order = 23

	----------------------------------------------------------------------------------------------------------------
	-- Record data to DB.
	local function log_damage_taken(set, dmg)
		-- Get the player.
		local player = Skada:get_player(set, dmg.playerid, dmg.playername)
		if player then
			local amount = dmg.amount
			-- Also add to set total damage taken.
			set.damagetaken = set.damagetaken + amount

			-- Add spell to player if it does not exist.
			if not player.damagetakenspells[dmg.spellname] or not player.damagetakenspells[dmg.spellname]['absorbed'] then
				player.damagetakenspells[dmg.spellname] = {id = dmg.spellid, name = dmg.spellname, damage = 0, totalhits = 0, min = nil, max = nil, crushing = 0, glancing = 0, resisted = 0, critical = 0, absorbed = 0, blocked = 0, multistrike = 0, multistrikehit = 0}
			end

			local spell = player.damagetakenspells[dmg.spellname]
			-- Add to player total damage.
			player.damagetaken = player.damagetaken + amount

			-- Get the spell from player.
			spell.id = dmg.spellid
			spell.damage = spell.damage + amount

			if dmg.crushing and not dmg.multistrike then
				spell.crushing = spell.crushing + 1
			end

			if dmg.blocked then
				spell.blocked = spell.blocked + dmg.blocked
			end

			if dmg.absorbed then
				spell.absorbed = spell.absorbed + dmg.absorbed
			end

			if dmg.critical and not dmg.multistrike then
				spell.critical = spell.critical + 1
			end

			if dmg.resisted then
				spell.resisted = spell.resisted + dmg.resisted
			end

			if dmg.glancing and not dmg.multistrike then
				spell.glancing = spell.glancing + 1
			end

			if (spell.max == nil or amount > spell.max) and not dmg.multistrike then
				spell.max = amount
			end

			if (spell.min == nil or amount < spell.min) and not dmg.multistrike then
				spell.min = amount
			end
			spell.totalhits = (spell.totalhits or 0) + 1
			if dmg.multistrike and not dmg.missed then
				spell.multistrikehit = (spell.multistrikehit or 0) + 1
				spell.multistrike = (spell.multistrike or 0) + amount
			end

			if set == Skada.current then
				if not dmg.mobname then dmg.mobname = UNKNOWN end
				if not player.damagetakenmobs[dmg.mobname] then
					player.damagetakenmobs[dmg.mobname] = {amount = 0, spell = {}}
				end
				local dmgMob = player.damagetakenmobs[dmg.mobname]
				if not dmgMob.spell[dmg.spellname] then
					dmgMob.spell[dmg.spellname] = {id = dmg.spellid, amount = 0}
				end
				dmgMob.amount = dmgMob.amount + amount
				dmgMob.spell[dmg.spellname].amount = dmgMob.spell[dmg.spellname].amount + amount
			end
		end
	end

	-- Listen combat log.
	local dmg = {}

	local function SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing, soffhand, smultistrike)
		dmg.playerid = dstGUID
		dmg.playername = dstName
		dmg.mobname = srcName
		dmg.spellid = spellId
		dmg.spellname = spellName
		dmg.amount = samount
		dmg.blocked = sblocked
		dmg.absorbed = sabsorbed
		dmg.critical = scritical
		dmg.resisted = sresisted
		dmg.glancing = sglancing
		dmg.crushing = scrushing
		dmg.offhand = soffhand
		dmg.multistrike = smultistrike

		log_damage_taken(Skada.current, dmg)
		log_damage_taken(Skada.total, dmg)
	end

	local function SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing, soffhand, smultistrike)
		dmg.playerid = dstGUID
		dmg.playername = dstName
		dmg.mobname = srcName
		dmg.spellid = 6603
		dmg.spellname = L["Attack"]
		dmg.amount = samount
		dmg.blocked = sblocked
		dmg.absorbed = sabsorbed
		dmg.critical = scritical
		dmg.resisted = sresisted
		dmg.glancing = sglancing
		dmg.crushing = scrushing
		dmg.offhand = soffhand
		dmg.multistrike = smultistrike

		log_damage_taken(Skada.current, dmg)
		log_damage_taken(Skada.total, dmg)
	end

	----------------------------------------------------------------------------------------------------------------
	-- Damage taken overview.
	function mod:Update(win, set)
		local max = 0

		local nr = 1
		for i, player in pairs(set._playeridx) do
			if player.damagetaken > 0 then
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				local totaltime = Skada:PlayerActiveTime(set, player)
				local dtps = player.damagetaken / math.max(1,totaltime)

				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.value = player.damagetaken

				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(player.damagetaken), self.metadata.columns.Damage,
												Skada:FormatNumber(dtps, true), self.metadata.columns.DTPS,
												string.format("%02.1f%%", player.damagetaken / set.damagetaken * 100), self.metadata.columns.Percent
											)
				d.id = player.id
				d.class = player.class
				d.role = player.role

				if player.damagetaken > max then
					max = player.damagetaken
				end
				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Damage taken spell list per player
	local function playerspell_tooltip(win, id, label, tooltip)
		local player = Skada:find_player(win:get_selected_set(), win.modedata.playerid)
		if player then
			local spell = player.damagetakenspells[label]
			if spell and (spell.totalhits > 0) then
				local rdamage = spell.damage - (spell.multistrike or 0)
				local rhits = spell.totalhits - (spell.multistrikehit or 0)
				tooltip:AddLine(player.name..": "..label)
				tooltip:AddDoubleLine(L["Hit"]..":", Skada:FormatHitNumber(rhits), 255,255,255,255,255,255)
				if spell.critical > 0 then
					tooltip:AddDoubleLine(L["Critical"]..":", Skada:FormatHitNumber(spell.critical), 255,255,255,255,255,255)
				end
				if spell.multistrikehit > 0 then
					tooltip:AddDoubleLine(L["Multistrike"]..":", Skada:FormatHitNumber(spell.multistrikehit), 255,255,255,255,255,255)
				end
				if spell.glancing > 0 then
					tooltip:AddDoubleLine(L["Glancing"]..":", Skada:FormatHitNumber(spell.glancing), 255,255,255,255,255,255)
				end
				if spell.crushing > 0 then
					tooltip:AddDoubleLine(L["Crushing"]..":", Skada:FormatHitNumber(spell.crushing), 255,255,255,255,255,255)
				end
				if spell.max and spell.min then
					tooltip:AddDoubleLine(L["Minimum hit:"], Skada:FormatNumber(spell.min), 255,255,255,255,255,255)
					tooltip:AddDoubleLine(L["Maximum hit:"], Skada:FormatNumber(spell.max), 255,255,255,255,255,255)
				end
				tooltip:AddDoubleLine(L["Average hit:"], Skada:FormatNumber(math.floor(rdamage / rhits)), 255,255,255,255,255,255)
				if spell.multistrike > 0 then
					tooltip:AddDoubleLine(L["Multistrike damage:"], Skada:FormatNumber(spell.multistrike), 255,255,255,255,255,255)
				end
			end
		end
	end

	function modPlayerSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["Damage taken"]..": "..player.name
	end

	function modPlayerSpell:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)

		local max = 0
		local nr = 1
		if player and (player.damagetaken > 0) then
			for spellname, spell in pairs(player.damagetakenspells) do

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.label = spellname
				d.value = spell.damage
				local _, _, icon = GetSpellInfo(spell.id)
				d.icon = icon
				d.id = spellname
				d.spellid = spell.id
				d.valuetext = Skada:FormatNumber(spell.damage)..(" (%02.1f%%)"):format(spell.damage / player.damagetaken * 100)

				if spell.damage > max then
					max = spell.damage
				end

				nr = nr + 1
			end

			-- Sort the possibly changed bars.
			win.metadata.maxvalue = max
		end
	end

	-- Damage taken by spell overview
	local function spell_tooltip(win, id, label, tooltip)
		local tmp = {}
		local set = win:get_selected_set()
		for i, player in pairs(set._playeridx) do
			if player.damagetaken > 0 then
				for name, spell in pairs(player.damagetakenspells) do
					if not tmp[name] then
						tmp[name] = {id = spell.id, damage = spell.damage, totalhits = spell.totalhits, min = spell.min, max = spell.max}
					else
						tmp[name].damage = tmp[name].damage + spell.damage
						tmp[name].totalhits = tmp[name].totalhits + spell.totalhits
						if spell.min < tmp[name].min then
							tmp[name].min = spell.min
						end
						if spell.max > tmp[name].max then
							tmp[name].max = spell.max
						end
					end
				end
			end
		end
		if tmp[label] and (tmp[label].totalhits > 0) then
			tooltip:AddLine(label)
			tooltip:AddDoubleLine(L["Hit:"], Skada:FormatHitNumber(tmp[label].totalhits), 255,255,255,255,255,255)
			if tmp[label].max and tmp[label].min then
				tooltip:AddDoubleLine(L["Minimum hit:"], Skada:FormatNumber(tmp[label].min), 255,255,255,255,255,255)
				tooltip:AddDoubleLine(L["Maximum hit:"], Skada:FormatNumber(tmp[label].max), 255,255,255,255,255,255)
			end
			tooltip:AddDoubleLine(L["Average hit:"], Skada:FormatNumber(math.floor(tmp[label].damage / tmp[label].totalhits)), 255,255,255,255,255,255)
		end
	end

	function spell:Update(win,set)
		if set.damagetaken == 0 then return end
		local max = 0

		-- Aggregate the data.
		local tmp = {}
		for i, player in pairs(set._playeridx) do
			if player.damagetaken > 0 then
				for name, spell in pairs(player.damagetakenspells) do
					if not tmp[name] then
						tmp[name] = {id = spell.id, damage = spell.damage}
					else
						tmp[name].damage = tmp[name].damage + spell.damage
					end
				end
			end
		end

		local nr = 1
		for name, spell in pairs(tmp) do
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d

			d.label = name
			d.value = spell.damage
			d.valuetext = Skada:FormatNumber(spell.damage)..(" (%02.1f%%)"):format(spell.damage / set.damagetaken * 100)
			d.id = name
			local _, _, icon = GetSpellInfo(spell.id)
			d.icon = icon
			d.spellid = spell.id

			if spell.damage > max then
				max = spell.damage
			end
			nr = nr + 1
		end
		win.metadata.maxvalue = max
	end

	-- Damage taken player list for specific spell.
	function spellPlayer:Enter(win, id, label)
		win.modedata.spellname = id
		self.title = L["Taken spell"]..": "..label
	end

	function spellPlayer:Update(win, set)
		local max = 0

		local nr = 1
		for i, player in pairs(set._playeridx) do
			if player.damagetaken > 0 and player.damagetakenspells[win.modedata.spellname] then
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.value = player.damagetakenspells[win.modedata.spellname].damage
				d.valuetext = Skada:FormatNumber(player.damagetakenspells[win.modedata.spellname].damage)
				d.id = player.id
				d.class = player.class
				d.role = player.role

				if player.damagetakenspells[win.modedata.spellname].damage > max then
					max = player.damagetakenspells[win.modedata.spellname].damage
				end
				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Damage taken by mob overview.
	function mob:Update(win, set)
		local nr = 1
		local max = 0

		-- build mob table
		local mobTable = {}
		for i, player in pairs(set._playeridx) do
			for mname, mob in pairs(player.damagetakenmobs) do
				if not mobTable[mname] then
					mobTable[mname] = 0
				end
				mobTable[mname] = mobTable[mname] + mob.amount
			end
		end

		for name, amount in pairs(mobTable) do
			if amount > 0 then
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.value = amount
				d.id = name
				d.valuetext = Skada:FormatNumber(amount)
				d.label = name

				if amount > max then
					max = amount
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Damage taken player list for mob overview.
	function mobPlayer:Enter(win, id, label)
		win.modedata.mobname = label
		self.title = L["Damage from"]..": "..label
	end

	function mobPlayer:Update(win, set)
		if win.modedata.mobname then
			local nr = 1
			local max = 0

			-- calculate total mob damage
			local mobTotal = 0
			for i, player in pairs(set._playeridx) do
				for mname, mob in pairs(player.damagetakenmobs) do
					if mname == win.modedata.mobname then
						mobTotal = mobTotal + mob.amount
					end
				end
			end

			for i, player in pairs(set._playeridx) do
				for mname, mob in pairs(player.damagetakenmobs) do
					if (mname == win.modedata.mobname) and (mob.amount > 0) then
						local d = win.dataset[nr] or {}
						win.dataset[nr] = d

						d.id = player.id
						d.label = Skada.db.profile.showrealm and player.name or player.shortname
						d.value = mob.amount
						d.valuetext = Skada:FormatNumber(mob.amount)..(" (%02.1f%%)"):format(mob.amount / mobTotal * 100)
						d.class = player.class
						d.role = player.role

						if mob.amount > max then
							max = mob.amount
						end

						nr = nr + 1
					end
				end
			end

			win.metadata.maxvalue = max
		end
	end

	-- Spell list for specific mob and player. (same above)
	function mobPlayerSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["Spell list"]..": "..win.modedata.mobname.." > "..player.name
	end

	function mobPlayerSpell:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local max = 0

		-- If we reset we have no data.
		if player then
			for mname, mob in pairs(player.damagetakenmobs) do
				if (mname == win.modedata.mobname) and (mob.amount > 0) then
					local nr = 1
					for spellname, spell in pairs(mob.spell) do
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
														string.format("%02.1f%%", spell.amount / mob.amount * 100), self.metadata.columns.Percent
													)
						if spell.amount > max then
							max = spell.amount
						end
						nr = nr + 1
					end
				end
			end
		end

		win.metadata.maxvalue = max
	end

	----------------------------------------------------------------------------------------------------------------
	-- Set mod property
	function mod:OnEnable()
		mod.metadata = 				{click1 = modPlayerSpell, showspots = true, columns = {Damage = true, DTPS = true, Percent = true}}
		modPlayerSpell.metadata =	{tooltip = playerspell_tooltip}
		spell.metadata =			{tooltip = spell_tooltip, click1 = spellPlayer, showspots = true}
		spellPlayer.metadata = 		{showspots = true}
		mob.metadata = 				{click1 = mobPlayer}
		mobPlayer.metadata = 		{showspots = true, click1 = mobPlayerSpell}
		mobPlayerSpell.metadata =	{columns = {Damage = true, Percent = true}}

		Skada:RegisterForCL(SpellDamage, 'SPELL_DAMAGE', {dst_is_interesting_nopets = true, src_is_not_interesting = true})
		Skada:RegisterForCL(SpellDamage, 'SPELL_PERIODIC_DAMAGE', {dst_is_interesting_nopets = true, src_is_not_interesting = true})
		Skada:RegisterForCL(SpellDamage, 'SPELL_BUILDING_DAMAGE', {dst_is_interesting_nopets = true, src_is_not_interesting = true})
		Skada:RegisterForCL(SpellDamage, 'RANGE_DAMAGE', {dst_is_interesting_nopets = true, src_is_not_interesting = true})

		Skada:RegisterForCL(SwingDamage, 'SWING_DAMAGE', {dst_is_interesting_nopets = true, src_is_not_interesting = true})

		Skada:AddMode(self)
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)
	end

	function spell:OnEnable()
		Skada:AddMode(self)
	end

	function spell:OnDisable()
		Skada:RemoveMode(self)
	end

	function mob:OnEnable()
		Skada:AddMode(self)
	end

	function mob:OnDisable()
		Skada:RemoveMode(self)
	end

	function mod:GetSetSummary(set)
		return Skada:FormatNumber(set.damagetaken)
	end

	-- Called by Skada when a new player is added to a set.
	function mod:AddPlayerAttributes(player)
		if not player.damagetaken then
			player.damagetaken = 0
			player.damagetakenspells = {}
			player.damagetakenmobs = {}
		end
	end

	-- Called by Skada when a new set is created.
	function mod:AddSetAttributes(set)
		if not set.damagetaken then
			set.damagetaken = 0
		end
	end
end)