Skada:AddLoadableModule("Damage", function(Skada, L)
	if Skada.db.profile.modulesBlocked.Damage then return end

	local mod = Skada:NewModule(L["Damage list"])
	local modAllSpell = Skada:NewModule(L["Damage: Player spell list"])
	local modAllSpellHit = Skada:NewModule(L["Damage: Player spell list > Hit/miss list"])
	local modDamaged = Skada:NewModule(L["Damage: Player damaged mob"])
	local modDamagedSpell = Skada:NewModule(L["Damage: Player damaged mob > Spell list"])
	local mob = Skada:NewModule(L["Damaged mob list"])
	local mobPlayer = Skada:NewModule(L["Damaged mob: Damaged player list"])
	local mobPlayerSpell = Skada:NewModule(L["Damaged mob: Damaged player list > Player spells"])
	local dps = Skada:NewModule(L["DPS list"])

	mod.Order = 1
	mob.Order = 2
	dps.Order = 3

	local function getDPS(set, player)
		local totaltime = Skada:PlayerActiveTime(set, player)

		return player.damage / math.max(1, totaltime)
	end

	local function getRaidDPS(set)
		local settime = Skada:GetSetTime(set)

		return set.damage / math.max(1, settime)
	end

	----------------------------------------------------------------------------------------------------------------
	-- Record data to DB.
	local function log_damage(set, dmg)
		-- Get the player.
		local player = Skada:get_player(set, dmg.playerid, dmg.playername)
		if player then

			-- Subtract overkill
	--		local amount = math.max(0,dmg.amount - dmg.overkill)
	--		self:Print(player.shortname..": "..dmg.spellname.." for "..tostring(amount))

			local amount = dmg.amount

			-- Also add to set total damage.
			set.damage = set.damage + amount

			-- Add spell to player if it does not exist.
			if not player.damagespells[dmg.spellname] then
				player.damagespells[dmg.spellname] = {id = dmg.spellid, hit = 0, totalhits = 0, damage = 0, multistrikehit = 0, multistrike = 0}
			end

			-- Add to player total damage.
			player.damage = player.damage + amount

			-- Get the spell from player.
			local spell = player.damagespells[dmg.spellname]

			spell.totalhits = spell.totalhits + 1

			if (spell.max == nil or amount > spell.max) and not dmg.multistrike then
				spell.max = amount
			end

			if (spell.min == nil or amount < spell.min) and not dmg.missed and not dmg.multistrike then
				spell.min = amount
			end

			spell.damage = spell.damage + amount
			if dmg.multistrike and not dmg.missed then
				spell.multistrikehit = (spell.multistrikehit or 0) + 1
				spell.multistrike = (spell.multistrike or 0) + amount
			end
			if not dmg.multistrike then
				if dmg.critical then
					spell.critical = (spell.critical or 0) + 1
				elseif dmg.missed ~= nil then
					spell.missed = (spell.missed or 0) + 1
					spell[dmg.missed] = (spell[dmg.missed] or 0) + 1
				elseif dmg.glancing then
					spell.glancing = (spell.glancing or 0) + 1
				elseif dmg.crushing then
					spell.crushing = (spell.crushing or 0) + 1
				else
					spell.hit = (spell.hit or 0) + 1
				end
			end

			-- For now, only save damaged info to current set.
			-- Saving this to Total may become a memory hog deluxe, and besides, it does not make much sense
			-- to see in Total. Why care which particular mob you damaged the most in a whole raid, for example?
			if set == Skada.current and amount > 0 then
				if not dmg.dstname then dmg.dstname = UNKNOWN end
				-- Make sure destination exists in player.
				if not player.damaged[dmg.dstname] then
					player.damaged[dmg.dstname] = {amount = 0, spell = {}}
				end

				local dmgMob = player.damaged[dmg.dstname]

				dmgMob.amount = dmgMob.amount + amount

				if not dmgMob.spell[dmg.spellname] then
					dmgMob.spell[dmg.spellname] = {id = dmg.spellid, amount = 0}
				end

				-- Add to destination.
				dmgMob.spell[dmg.spellname].amount = dmgMob.spell[dmg.spellname].amount + amount
			end

		end
	end

	-- Listen combat log.
	local dmg = {}

	local function SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing, soffhand, smultistrike)
		-- XXX WoD quick fix for Mage's Prismatic Crystal talent
		-- All damage done to the crystal is transferred, so ignore it
		if dstGUID:match("-(76933)-") then 
			return
		end

		dmg.playerid = srcGUID
		dmg.playerflags = srcFlags
		dmg.dstname = dstName
		dmg.playername = srcName
		dmg.spellid = spellId
		dmg.spellname = spellName
		dmg.amount = samount
		dmg.overkill = soverkill
		dmg.resisted = sresisted
		dmg.blocked = sblocked
		dmg.absorbed = sabsorbed
		dmg.critical = scritical
		dmg.glancing = sglancing
		dmg.crushing = scrushing
		dmg.offhand = soffhand
		dmg.multistrike = smultistrike
		dmg.missed = nil

		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end

	local function SpellDotDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing, soffhand, smultistrike)
		-- XXX WoD quick fix for Mage's Prismatic Crystal talent
		-- All damage done to the crystal is transferred, so ignore it
		if dstGUID:match("-(76933)-") then 
			return
		end

		dmg.playerid = srcGUID
		dmg.playerflags = srcFlags
		dmg.dstname = dstName
		dmg.playername = srcName
		dmg.spellid = spellId
		dmg.spellname = spellName.. L[" (DoT)"]
		dmg.amount = samount
		dmg.overkill = soverkill
		dmg.resisted = sresisted
		dmg.blocked = sblocked
		dmg.absorbed = sabsorbed
		dmg.critical = scritical
		dmg.glancing = sglancing
		dmg.crushing = scrushing
		dmg.offhand = soffhand
		dmg.multistrike = smultistrike
		dmg.missed = nil

		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end

	local function SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing, soffhand, smultistrike)
		-- XXX WoD quick fix for Mage's Prismatic Crystal talent
		-- All damage done to the crystal is transferred, so ignore it
		if dstGUID:match("-(76933)-") then 
			return
		end

		dmg.playerid = srcGUID
		dmg.playername = srcName
		dmg.playerflags = srcFlags
		dmg.dstname = dstName
		dmg.spellid = 6603
		dmg.spellname = L["Attack"]
		dmg.amount = samount
		dmg.overkill = soverkill
		dmg.resisted = sresisted
		dmg.blocked = sblocked
		dmg.absorbed = sabsorbed
		dmg.critical = scritical
		dmg.glancing = sglancing
		dmg.crushing = scrushing
		dmg.offhand = soffhand
		dmg.multistrike = smultistrike
		dmg.missed = nil

		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end

	local function SpellAbsorbed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		local chk = ...
		if type(chk) == "number" then
			local spellId, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aspellId, aspellName, aspellSchool, aAmount = ...
			-- Exclude Spirit Shift damage
			if aspellId == 184553 then return end
			SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, aAmount)
		else
			local aGUID, aName, aFlags, aRaidFlags, aspellId, aspellName, aspellSchool, aAmount = ...
			-- Exclude Spirit Shift damage
			if aspellId == 184553 then return end
			SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, aAmount)
		end
	end

	local function SpellMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType)
		dmg.playerid = srcGUID
		dmg.playername = srcName
		dmg.playerflags = srcFlags
		dmg.dstname = dstName
		dmg.spellid = spellId
		dmg.spellname = spellName
		dmg.amount = 0
		dmg.overkill = 0
		dmg.resisted = nil
		dmg.blocked = nil
		dmg.absorbed = nil
		dmg.critical = nil
		dmg.glancing = nil
		dmg.crushing = nil
		dmg.offhand = nil
		dmg.multistrike = nil
		dmg.missed = missType

		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end

	local function SpellDotMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType)
		dmg.playerid = srcGUID
		dmg.playername = srcName
		dmg.playerflags = srcFlags
		dmg.dstname = dstName
		dmg.spellid = spellId
		dmg.spellname = spellName .. L[" (DoT)"]
		dmg.amount = 0
		dmg.overkill = 0
		dmg.resisted = nil
		dmg.blocked = nil
		dmg.absorbed = nil
		dmg.critical = nil
		dmg.glancing = nil
		dmg.crushing = nil
		dmg.offhand = nil
		dmg.multistrike = nil
		dmg.missed = missType

		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end

	local function SwingMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missed)
		dmg.playerid = srcGUID
		dmg.playername = srcName
		dmg.playerflags = srcFlags
		dmg.dstname = dstName
		dmg.spellid = 6603
		dmg.spellname = L["Attack"]
		dmg.amount = 0
		dmg.overkill = 0
		dmg.resisted = nil
		dmg.blocked = nil
		dmg.absorbed = nil
		dmg.critical = nil
		dmg.glancing = nil
		dmg.crushing = nil
		dmg.offhand = nil
		dmg.multistrike = nil
		dmg.missed = missed

		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end

	----------------------------------------------------------------------------------------------------------------
	-- Damage overview.
	local function damage_tooltip(win, id, label, tooltip)
		local set = win:get_selected_set()
		local player = Skada:find_player(set, id)
		if player then
			local activetime = Skada:PlayerActiveTime(set, player)
			local totaltime = Skada:GetSetTime(set)
			tooltip:AddDoubleLine(L["Activity"], ("%02.1f%%"):format(activetime/math.max(1,totaltime)*100), 255,255,255,255,255,255)
		end
	end

	function mod:Update(win, set)
		-- Max value.
		local max = 0
		local nr = 1

		for i, player in pairs(set._playeridx) do
			if player.damage > 0 then

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
				d.label = Skada.db.profile.showrealm and player.name or player.shortname

				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(player.damage), self.metadata.columns.Damage,
												Skada:FormatNumber(getDPS(set, player), true), self.metadata.columns.DPS,
												string.format("%02.1f%%", player.damage / set.damage * 100), self.metadata.columns.Percent
											)

				d.value = player.damage
				d.id = player.id
				d.class = player.class
				d.role = player.role
				if player.damage > max then
					max = player.damage
				end
				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Player damaged spell overview.
	local function player_tooltip(win, id, label, tooltip)
		local player = Skada:find_player(win:get_selected_set(), win.modedata.playerid)
		if player then
			local spell = player.damagespells[label]
			if spell and (spell.totalhits > 0) then
				tooltip:AddLine(player.name..": "..label)
				local rdamage = spell.damage - (spell.multistrike or 0)
				local rhits = spell.totalhits - (spell.multistrikehit or 0)
				local hitrate = (rhits - (spell.missed or 0)) / rhits * 100
				tooltip:AddDoubleLine(L["Hit rate:"], string.format("%02.1f%%", hitrate), 255,255,255,255,255,255)
				if spell.critical and spell.critical > 0 then
					tooltip:AddDoubleLine(L["Critical rate:"], string.format("%02.1f%%", spell.critical / rhits * 100), 255,255,255,255,255,255)
				end
				if spell.multistrikehit > 0 then
					tooltip:AddDoubleLine(L["Multistrike rate:"], string.format("%02.1f%%", spell.multistrikehit / rhits * 100), 255,255,255,255,255,255)
				end
				if spell.max and spell.min then
					tooltip:AddDoubleLine(L["Minimum hit:"], Skada:FormatNumber(spell.min), 255,255,255,255,255,255)
					tooltip:AddDoubleLine(L["Maximum hit:"], Skada:FormatNumber(spell.max), 255,255,255,255,255,255)
				end
				tooltip:AddDoubleLine(L["Average hit:"], Skada:FormatNumber(math.floor(rdamage / rhits)), 255,255,255,255,255,255)
				if spell.multistrike > 0 then
					tooltip:AddDoubleLine(L["Multistrike hit:"], Skada:FormatNumber(spell.multistrike)..string.format(" (%02.1f%%)", spell.multistrike / rdamage * 100), 255,255,255,255,255,255)
				end
			end
		end
	end

	function modAllSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["Damage"]..": "..player.name
	end

	function modAllSpell:Update(win, set)
		-- View spells for this player.
		local player = Skada:find_player(set, win.modedata.playerid)
		local max = 0
		local nr = 1

		-- If we reset we have no data.
		if player and (player.damage > 0) then

			for spellname, spell in pairs(player.damagespells) do

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
												string.format("%02.1f%%", spell.damage / player.damage * 100), self.metadata.columns.Percent
											)
				if spell.damage > max then
					max = spell.damage
				end
				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Player spell hit/miss list overview.
	local function add_detail_bar(win, nr, title, value)
		local d = win.dataset[nr] or {}
		win.dataset[nr] = d

		d.value = value
		d.label = title
		d.id = title
		d.valuetext = Skada:FormatHitNumber(value)

		win.metadata.maxvalue = math.max(win.metadata.maxvalue, value)
	end

	function modAllSpellHit:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), win.modedata.playerid)
		win.modedata.spellname = label
		self.title = player.name..": "..label
	end

	function modAllSpellHit:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)

		if player then
			local spell = player.damagespells[win.modedata.spellname]

			if spell and (spell.totalhits > 0) then
				modAllSpellHit.hits = spell.totalhits - (spell.multistrikehit or 0)
				win.metadata.maxvalue = 0
				local nr = 0

				if spell.hit and spell.hit > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Hit"], spell.hit)
				end
				if spell.critical and spell.critical > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Critical"], spell.critical)
				end
				if spell.multistrikehit and spell.multistrikehit > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Multistrike"], spell.multistrikehit)
				end
				if spell.glancing and spell.glancing > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Glancing"], spell.glancing)
				end
				if spell.crushing and spell.crushing > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Crushing"], spell.crushing)
				end
				if spell.ABSORB and spell.ABSORB > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Absorb"], spell.ABSORB)
				end
				if spell.BLOCK and spell.BLOCK > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Block"], spell.BLOCK)
				end
				if spell.DEFLECT and spell.DEFLECT > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Deflect"], spell.DEFLECT)
				end
				if spell.DODGE and spell.DODGE > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Dodge"], spell.DODGE)
				end
				if spell.EVADE and spell.EVADE > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Evade"], spell.EVADE)
				end
				if spell.IMMUNE and spell.IMMUNE > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Immune"], spell.IMMUNE)
				end
				if spell.MISS and spell.MISS > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Missed"], spell.MISS)
				end
				if spell.PARRY and spell.PARRY > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Parry"], spell.PARRY)
				end
				if spell.REFLECT and spell.REFLECT > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Reflect"], spell.REFLECT)
				end
				if spell.RESIST and spell.RESIST > 0 then
					nr = nr + 1
					add_detail_bar(win, nr, L["Resist"], spell.RESIST)
				end

			end
		end

	end

	-- Player view showing damaged mobs.
	function modDamaged:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		win.modedata.pname = player.name
		self.title = L["Damaged mob"]..": "..player.name
	end

	function modDamaged:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local max = 0
		local nr = 1

		-- If we reset we have no data.
		if player and (player.damage > 0) then

			for mname, mob in pairs(player.damaged) do
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
				d.label = mname
				d.id = mname
				d.value = mob.amount
				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(mob.amount), self.metadata.columns.Damage,
												string.format("%02.1f%%", mob.amount / player.damage * 100), self.metadata.columns.Percent
											)
				if mob.amount > max then
					max = mob.amount
				end
				nr = nr + 1
			end
		end
		
		win.metadata.maxvalue = max
	end

	-- Player spell list overview on damaged mobs.
	function modDamagedSpell:Enter(win, id, label)
		win.modedata.mobname = label
		self.title = L["Spell list"]..": "..win.modedata.pname.." > "..label
	end

	function modDamagedSpell:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local max = 0
		local nr = 1

		-- If we reset we have no data.
		if player then
			for mname, mob in pairs(player.damaged) do
				if (mname == win.modedata.mobname) and (mob.amount > 0) then
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

	-- Mob damaged overview.
	function mob:Update(win, set)
		local max = 0
		local nr = 1

		-- build mob table
		local mobTable = {}
		for i, player in pairs(set._playeridx) do
			for mname, mob in pairs(player.damaged) do
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

	-- Damaged player list for mob overview.
	function mobPlayer:Enter(win, id, label)
		win.modedata.mobname = label
		self.title = L["Damage"]..": "..label
	end

	function mobPlayer:Update(win, set)
		if win.modedata.mobname then
			local max = 0
			local nr = 1

			-- calculate total mob damage
			local mobTotal = 0
			for i, player in pairs(set._playeridx) do
				for mname, mob in pairs(player.damaged) do
					if mname == win.modedata.mobname then
						mobTotal = mobTotal + mob.amount
					end
				end
			end

			for i, player in pairs(set._playeridx) do
				for mname, mob in pairs(player.damaged) do
					if mname == win.modedata.mobname and (mob.amount > 0) then
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
		self.title = L["Spell list"]..": "..player.name.." > "..win.modedata.mobname
	end

	function mobPlayerSpell:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local max = 0
		local nr = 1

		-- If we reset we have no data.
		if player then
			for mname, mob in pairs(player.damaged) do
				if (mname == win.modedata.mobname) and (mob.amount > 0) then
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

	-- DPS-only view
	local function dps_tooltip(win, id, label, tooltip)
		local set = win:get_selected_set()
		local player = Skada:find_player(set, id)
		if player then

			local activetime = math.max(1, Skada:PlayerActiveTime(set, player))
			local totaltime = Skada:GetSetTime(set)
			tooltip:AddLine(player.name..": "..L["DPS"])
			tooltip:AddDoubleLine(L["Segment time"], totaltime..L["s"], 255,255,255,255,255,255)
			tooltip:AddDoubleLine(L["Active time"], activetime..L["s"], 255,255,255,255,255,255)
			tooltip:AddDoubleLine(L["Damage done"], Skada:FormatNumber(player.damage), 255,255,255,255,255,255)
			tooltip:AddDoubleLine(Skada:FormatNumber(player.damage) .. " / " .. activetime ..L["s"].. ":", Skada:FormatNumber(getDPS(set, player), true), 255,255,255,255,255,255)

		end
	end

	function dps:Update(win, set)
		local max = 0
		local nr = 1

		for i, player in pairs(set._playeridx) do
			local dps = getDPS(set, player)

			if dps > 0 then
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.id = player.id
				d.value = dps
				d.class = player.class
				d.role = player.role
				d.valuetext = Skada:FormatNumber(dps, true)
				if dps > max then
					max = dps
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	----------------------------------------------------------------------------------------------------------------
	-- Set mod property
	function mod:OnEnable()
		mod.metadata =				{post_tooltip = damage_tooltip, showspots = true, click1 = modAllSpell, click2 = modDamaged, columns = {Damage = true, DPS = true, Percent = true}}
		modAllSpell.metadata =		{tooltip = player_tooltip, click1 = modAllSpellHit, columns = {Damage = true, Percent = true}}
		modDamaged.metadata =		{click1 = modDamagedSpell, columns = {Damage = true, Percent = true}}
		modDamagedSpell.metadata =	{columns = {Damage = true, Percent = true}}
		mob.metadata = 				{click1 = mobPlayer}
		mobPlayer.metadata = 		{showspots = true, click1 = mobPlayerSpell}
		mobPlayerSpell.metadata =	{columns = {Damage = true, Percent = true}}
		dps.metadata = 				{tooltip = dps_tooltip, showspots = true}

		Skada:RegisterForCL(SpellDamage, 'DAMAGE_SHIELD', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(SpellDamage, 'SPELL_DAMAGE', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(SpellAbsorbed, 'SPELL_ABSORBED', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(SpellDamage, 'SPELL_BUILDING_DAMAGE', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(SpellDamage, 'RANGE_DAMAGE', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(SpellDotDamage, 'SPELL_PERIODIC_DAMAGE', {src_is_interesting = true, dst_is_not_interesting = true})

		Skada:RegisterForCL(SwingDamage, 'SWING_DAMAGE', {src_is_interesting = true, dst_is_not_interesting = true})

		Skada:RegisterForCL(SpellMissed, 'SPELL_MISSED', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(SpellMissed, 'SPELL_BUILDING_MISSED', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(SpellMissed, 'RANGE_MISSED', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(SpellDotMissed, 'SPELL_PERIODIC_MISSED', {src_is_interesting = true, dst_is_not_interesting = true})

		Skada:RegisterForCL(SwingMissed, 'SWING_MISSED', {src_is_interesting = true, dst_is_not_interesting = true})

		Skada:AddFeed(L["Damage: Personal DPS"],	function()
														if Skada.current then
															local player = Skada:find_player(Skada.current, UnitGUID("player"))
															if player then
																return Skada:FormatNumber(getDPS(Skada.current, player), true).." "..L["DPS"]
															end
														end
													end)
		Skada:AddFeed(L["Damage: Raid DPS"],		function()
														if Skada.current then
															return Skada:FormatNumber(getRaidDPS(Skada.current), true).." "..L["RDPS"]
														end
													end)

		Skada:AddMode(self)
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)

		Skada:RemoveFeed(L["Damage: Personal DPS"])
		Skada:RemoveFeed(L["Damage: Raid DPS"])
	end

	function mob:OnEnable()
		Skada:AddMode(self)
	end

	function mob:OnDisable()
		Skada:RemoveMode(self)
	end

	function dps:OnEnable()
		Skada:AddMode(self)
	end

	function dps:OnDisable()
		Skada:RemoveMode(self)
	end

	function mod:AddToTooltip(set, tooltip)
		GameTooltip:AddDoubleLine(L["DPS"], Skada:FormatNumber(getRaidDPS(set), true), 1,1,1)
	end

	function mod:GetSetSummary(set)
		return Skada:FormatValueText(Skada:FormatNumber(set.damage), self.metadata.columns.Damage, Skada:FormatNumber(getRaidDPS(set), true), self.metadata.columns.DPS)
	end

	function dps:GetSetSummary(set)
		return Skada:FormatNumber(getRaidDPS(set), true)
	end

	-- Called by Skada when a new player is added to a set.
	function mod:AddPlayerAttributes(player)
		if not player.damage then
			player.damage = 0
			player.damagespells = {}
		end
		if not player.damaged then
			player.damaged = {}
		end
	end

	-- Called by Skada when a new set is created.
	function mod:AddSetAttributes(set)
		if not set.damage then
			set.damage = 0
		end
	end
end)
