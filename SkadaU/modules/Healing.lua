Skada:AddLoadableModule("Healing", function(Skada, L)
	if Skada.db.profile.modulesBlocked.Healing then return end

	local nmax = math.max
	local fl = math.floor

	local mod = Skada:NewModule(L["Healing list"])
	local modAllSpell = Skada:NewModule(L["Healing: Player spell list"])
	local modHealed = Skada:NewModule(L["Healing: Healed list"])
	local modHealedSpell = Skada:NewModule(L["Healing: Healed list > Spell list"])
	local total = Skada:NewModule(L["Total healing list"])
	local totalSpell = Skada:NewModule(L["Total healing: Spell list"])
	local overheal = Skada:NewModule(L["Overhealing list"])
	local overhealSpell = Skada:NewModule(L["Overhealing: Spell list"])
	local absorbed = Skada:NewModule(L["Absorbed healing"])
	local absorbedSpell = Skada:NewModule(L["Absorbed Healing: Spell list"])
	local mob = Skada:NewModule(L["Enemy Healing"])
	local mobSpell = Skada:NewModule(L["Enemy Healing: Spell list"])
	local mobHealed = Skada:NewModule(L["Enemy Healing: Healed list"])
	local mobHealedSpell = Skada:NewModule(L["Enemy Healing: Healed list > Spell"])
	local taken = Skada:NewModule(L["Healing taken list"])
	local takenSpell = Skada:NewModule(L["Healing taken: Spell list"])
	local takenPlayer = Skada:NewModule(L["Healing taken: Healed player list"])

	local PET_FLAGS = bit.bor(COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN)
	local RAID_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
	local band = bit.band

	mod.Order = 11
	total.Order = 12
	overheal.Order = 13
	absorbed.Order = 14
	mob.Order = 15
	taken.Order = 16

	local function getHPS(set, player)
		local totaltime = Skada:PlayerActiveTime(set, player)

		return player.healing / nmax(1,totaltime)
	end

	local function getHPSByValue(set, player, healing)
		local totaltime = Skada:PlayerActiveTime(set, player)

		return healing / nmax(1,totaltime)
	end

	local function getRaidHPS(set)
		local settime = Skada:GetSetTime(set)

		return set.healing / nmax(1, settime)
	end

	----------------------------------------------------------------------------------------------------------------
	-- Record data to DB.
	local function log_heal(set, heal)
		-- Get the player from set.
		local player = Skada:get_player(set, heal.playerid, heal.playername)
		if player then
			-- Subtract overhealing, Add absorbed
			local amount = nmax(0, heal.amount - heal.overhealing) + heal.absorbed
			local spellname = heal.spellname

			-- Add to player total.
			player.healing = player.healing + amount
			player.overhealing = player.overhealing + heal.overhealing
			player.healingabsorbed = player.healingabsorbed + heal.absorbed

			-- Also add to set total damage.
			set.healing = set.healing + amount
			set.overhealing = set.overhealing + heal.overhealing
			set.healingabsorbed = set.healingabsorbed + heal.absorbed

			-- Create spell if it does not exist.
			if not player.healingspells[spellname] then
				player.healingspells[spellname] = {id = heal.spellid, name = spellname, hits = 0, healing = 0, overhealing = 0, absorbed = 0, critical = 0, min = nil, max = 0, multistrike = 0, multistrikehit = 0}
			end

			local spell = player.healingspells[spellname]

			spell.healing = spell.healing + amount
			spell.overhealing = spell.overhealing + heal.overhealing
			spell.absorbed = spell.absorbed + heal.absorbed

			spell.hits = (spell.hits or 0) + 1
			if heal.critical and not heal.multistrike then
				spell.critical = spell.critical + 1
			end

			if (amount > 0) and not heal.multistrike then
				if spell.min == nil or amount < spell.min then
					spell.min = amount
				end
				if spell.max == nil or amount > spell.max then
					spell.max = amount
				end
			end
			if heal.multistrike then
				spell.multistrikehit = (spell.multistrikehit or 0) + 1
				spell.multistrike = (spell.multistrike or 0) + amount
			end

			-- For now, only save recipient healing info to current set.
			-- Add to recipient healing.
			if set == Skada.current and amount > 0 then
				if not heal.dstName then heal.dstName = UNKNOWN end

				-- Create recipient if it does not exist.
				if not player.healed[heal.dstName] then
					local _, class = UnitClass(heal.dstName)
					local role = UnitGroupRolesAssigned(heal.dstName)
					player.healed[heal.dstName] = {name = heal.dstName, shortname = Ambiguate(heal.dstName, "short"), class = class, role = role, amount = 0, spell = {}}
				end

				local healed = player.healed[heal.dstName]

				if not healed.spell[spellname] then
					healed.spell[spellname] = {id = heal.spellid, hits = 0, healing = 0}
				end

				local healedspell = healed.spell[spellname]

				healed.amount = healed.amount + amount
				healedspell.healing = healedspell.healing + amount

				healedspell.hits = (healedspell.hits or 0) + 1

				if healedspell.min == nil or amount < healedspell.min then
					healedspell.min = amount
				end
				if healedspell.max == nil or amount > healedspell.max then
					healedspell.max = amount
				end
			end
		end
	end

	local function log_mob_healing(set, heal)
		local amount = nmax(0, heal.amount - heal.overhealing)

		set.mobhealing = set.mobhealing + amount

		if not heal.srcName then heal.srcName = UNKNOWN end
		if not heal.dstName then heal.dstName = UNKNOWN end

		-- Create recipient if it does not exist.
		if not set.mobhealed[heal.srcName] then
			set.mobhealed[heal.srcName] = {}
		end

		if not set.mobhealed[heal.srcName][heal.dstName] then
			set.mobhealed[heal.srcName][heal.dstName] = {}
		end

		if not set.mobhealed[heal.srcName][heal.dstName][heal.spellid] then
			set.mobhealed[heal.srcName][heal.dstName][heal.spellid] = {name = spellname, id = spellid, hits = 0, crits = 0, healing = 0, overhealing = 0, min = nil, max = 0}
		end

		local spell = set.mobhealed[heal.srcName][heal.dstName][heal.spellid]
		spell.hits = spell.hits + 1
		if heal.critical then
			spell.crits = spell.crits + 1
		end
		spell.healing = spell.healing + amount
		spell.overhealing = spell.overhealing + heal.overhealing
		if amount > 0 then
			if spell.min == nil or amount < spell.min then
				spell.min = amount
			end
			if spell.max == nil or amount > spell.max then
				spell.max = amount
			end
		end
	end

	-- Listen combat log.
	local heal = {}

	local function SpellHeal(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, samount, soverhealing, absorbed, scritical, smultistrike)
		heal.dstName = dstName
		heal.dstGUID = dstGUID
		heal.playerflags = srcFlags
		heal.playerid = srcGUID
		heal.playername = srcName
		heal.spellid = spellId
		heal.spellname = spellName
		heal.amount = samount
		heal.overhealing = soverhealing
		heal.critical = scritical
		heal.absorbed = absorbed
		heal.multistrike = smultistrike

		Skada:FixPets(heal)
		log_heal(Skada.current, heal)
		log_heal(Skada.total, heal)
	end

	local function SpellHealHot(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, samount, soverhealing, absorbed, scritical, smultistrike)
		heal.dstName = dstName
		heal.dstGUID = dstGUID
		heal.playerflags = srcFlags
		heal.playerid = srcGUID
		heal.playername = srcName
		heal.spellid = spellId
		heal.spellname = spellName.. L[" (HoT)"]
		heal.amount = samount
		heal.overhealing = soverhealing
		heal.critical = scritical
		heal.absorbed = absorbed
		heal.multistrike = smultistrike

		Skada:FixPets(heal)
		log_heal(Skada.current, heal)
		log_heal(Skada.total, heal)
	end

    local function log_absorb(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		local spellId, spellName, spellSchool, samount, soverhealing, absorbed = ...

		heal.dstName = dstName
		heal.dstGUID = dstGUID
		heal.playerid = srcGUID
		heal.playername = srcName
		heal.spellid = spellId
		heal.spellname = spellName
		heal.amount = samount
		heal.overhealing = soverhealing
		heal.critical = nil
		heal.multistrike = nil
		heal.absorbed = absorbed

		Skada:FixPets(heal)
		log_heal(Skada.current, heal)
		log_heal(Skada.total, heal)
	end

	local function SpellAbsorbed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		-- New fancy absorb events.
		-- Destination is the healed player, and cause of absorb comes later.
		local chk = ...
		local spellId, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aspellId, aspellName, aspellSchool, aAmount
		if type(chk) == "number" then
			spellId, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aspellId, aspellName, aspellSchool, aAmount = ...
		else
			aGUID, aName, aFlags, aRaidFlags, aspellId, aspellName, aspellSchool, aAmount = ...
		end
		-- Spirit of Redemption - discount absorbs on priest.
		-- Discount Monk's Stagger absorbs, Purgatory absorbs.
		if aspellId == 20711 or aspellId == 114556 or aspellId == 115069 or aspellId == 157533 or aspellId == 184553 then return end
		local valid = band(aFlags, RAID_FLAGS) ~= 0 or Skada:IsValidPet(aGUID) or (Skada:IsValidPlayer(aGUID) and band(aFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)
		if valid then
			log_absorb(timestamp, eventtype, aGUID, aName, aFlags, dstGUID, dstName, dstFlags, aspellId, aspellName, aspellSchool, aAmount, 0, 0)
		end
	end

	local shields = {}

	local function AuraApplied(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
		if amount ~= nil and dstName and srcName then
			-- see if the source and destination are both part valid
			-- controlled by player:
			local valid = (band(srcFlags, dstFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0)
			-- affiliation in party/raid:
			-- note: test separately
			valid = valid and (band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0)
			valid = valid and (band(dstFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0)
			-- lastly, check the reaction
			-- If a raid member is mind-controlled, we don't want to start tracking heal absorb debuffs
			-- so we need to make sure both source and destination are friendly to each other.
			-- Unfortunately, we can't test that trivially, so lets just test if their reaction to the player
			-- is the same.
			valid = valid and (band(srcFlags, dstFlags, COMBATLOG_OBJECT_REACTION_MASK) ~= 0)

			if valid then
				if shields[dstGUID] == nil then shields[dstGUID] = {} end
				if shields[dstGUID][spellId] == nil then shields[dstGUID][spellId] = {} end
				shields[dstGUID][spellId][srcGUID] = amount
			end
		end
	end

	local function AuraRemoved(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
		if amount ~= nil then
			if shields[dstGUID] and shields[dstGUID][spellId] and shields[dstGUID][spellId][srcGUID] then
				if Skada.current and amount and amount > 0 then
					heal.dstName = dstName
					heal.dstGUID = dstGUID
					heal.playerflags = srcFlags
					heal.playerid = srcGUID
					heal.playername = srcName
					heal.spellid = spellId
					heal.spellname = spellName
					heal.amount = 0                -- The actual healing is now accounted for by SPELL_ABSORBED.
					heal.overhealing = amount      -- The overheal is what remains on the shield when it expires. This should be identical to our stored shield value, prev.
					heal.critical = nil
					heal.absorbed = 0

					Skada:FixPets(heal)
					log_heal(Skada.current, heal)
					log_heal(Skada.total, heal)
				end
				shields[dstGUID][spellId][srcGUID] = nil
			end
		end
	end

	local function mobHealing(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, _, samount, soverhealing, _, scritical)
		heal.dstName = dstName
		heal.srcName = srcName
		heal.spellid = spellId
		heal.spellname = spellName
		heal.amount = samount
		heal.overhealing = soverhealing
		heal.critical = scritical
		
		log_mob_healing(Skada.current, heal)
		log_mob_healing(Skada.total, heal)
	end

	----------------------------------------------------------------------------------------------------------------
	-- Spell view of a player.
	function mod:Update(win, set)
		local nr = 1
		local max = 0

		for i, player in pairs(set._playeridx) do
			if player.healing > 0 then

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = player.id
				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.value = player.healing

				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(fl(player.healing)), self.metadata.columns.Healing,
												Skada:FormatNumber(getHPS(set, player), true), self.metadata.columns.HPS,
												string.format("%02.1f%%", player.healing / set.healing * 100), self.metadata.columns.Percent
											)
				d.class = player.class
				d.role = player.role

				if player.healing > max then
					max = player.healing
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Spell view of a player.
	local function spell_tooltip(win, id, label, tooltip)
		local player = Skada:find_player(win:get_selected_set(), win.modedata.playerid)
		if player then
			local spell = player.healingspells[label]
			if spell and (spell.hits > 0) then
				local rhealing = spell.healing - (spell.multistrike or 0)
				local rhits = spell.hits - (spell.multistrikehit or 0)
				tooltip:AddLine(player.name..": "..label)
				tooltip:AddDoubleLine(L["Hit:"], Skada:FormatHitNumber(rhits), 255,255,255,255,255,255)
				if spell.critical and spell.critical > 0 then
					tooltip:AddDoubleLine(L["Critical"]..":", ("%02.1f%%"):format(spell.critical / rhits * 100), 255,255,255,255,255,255)
				end
				if spell.multistrikehit > 0 then
					tooltip:AddDoubleLine(L["Multistrike"]..":", ("%02.1f%%"):format(spell.multistrikehit / rhits * 100), 255,255,255,255,255,255)
				end
				if spell.max and spell.min then
					tooltip:AddDoubleLine(L["Minimum hit:"], Skada:FormatNumber(fl(spell.min)), 255,255,255,255,255,255)
					tooltip:AddDoubleLine(L["Maximum hit:"], Skada:FormatNumber(fl(spell.max)), 255,255,255,255,255,255)
				end
				tooltip:AddDoubleLine(L["Average hit:"], Skada:FormatNumber(fl(rhealing / rhits)), 255,255,255,255,255,255)
				if spell.multistrike > 0 then
					tooltip:AddDoubleLine(L["Multistrike heal:"], Skada:FormatNumber(spell.multistrike)..(" (%02.1f%%)"):format(spell.multistrike / rhealing * 100), 255,255,255,255,255,255)
				end
				if (spell.overhealing + spell.healing) > 0 then
					if spell.hits and spell.overhealing > 0 then
						tooltip:AddDoubleLine(L["Overhealed"]..":", Skada:FormatNumber(spell.overhealing)..(" (%02.1f%%)"):format(spell.overhealing / (spell.overhealing + spell.healing) * 100), 255,255,255,255,255,255)
					end
					if spell.hits and spell.absorbed > 0 then
						tooltip:AddDoubleLine(L["Absorbed"]..":",Skada:FormatNumber(spell.absorbed)..(" (%02.1f%%)"):format(spell.absorbed / (spell.overhealing + spell.healing) * 100), 255,255,255,255,255,255)
					end
				end
			end
		end
	end

	function modAllSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["Healing"]..": "..player.name
	end

	function modAllSpell:Update(win, set)
		-- View spells for this player.

		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player and (player.healing > 0) then
			for spellname, spell in pairs(player.healingspells) do
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = spell.name
				d.label = spell.name
				d.value = spell.healing
				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(fl(spell.healing)), self.metadata.columns.Healing,
												string.format("%02.1f%%", spell.healing / player.healing * 100), self.metadata.columns.Percent
											)
				local _, _, icon = GetSpellInfo(spell.id)
				d.icon = icon
				d.spellid = spell.id

				if spell.healing > max then
					max = spell.healing
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Healed players view of a player.
	function modHealed:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = player.id
		win.modedata.playername = player.name
		self.title = L["Healed"]..": "..player.name
	end

	function modHealed:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player and (player.healing > 0) then
			for id, heal in pairs(player.healed) do
				if heal.amount > 0 then

					local d = win.dataset[nr] or {}
					win.dataset[nr] = d

					d.id = id
					d.label = Skada.db.profile.showrealm and heal.name or heal.shortname
					d.value = heal.amount
					d.class = heal.class
					d.valuetext = Skada:FormatValueText(
													Skada:FormatNumber(fl(heal.amount)), self.metadata.columns.Healing,
													string.format("%02.1f%%", heal.amount / player.healing * 100), self.metadata.columns.Percent
												)
					if heal.amount > max then
						max = heal.amount
					end

					nr = nr + 1
				end
			end
		end

		win.metadata.maxvalue = max
	end

	-- Spell view of a player.
	local function healedspell_tooltip(win, id, label, tooltip)
		local player = Skada:find_player(win:get_selected_set(), win.modedata.playerid)
		if player then
			for tid, heal in pairs(player.healed) do
				if tid == win.modedata.targetid then
					local spell = heal.spell[label]
					if spell then
						tooltip:AddLine(player.name..": "..label)
						tooltip:AddDoubleLine(L["Hit:"], Skada:FormatNumber(spell.hits), 255,255,255,255,255,255)
						if spell.max and spell.min then
							tooltip:AddDoubleLine(L["Minimum hit:"], Skada:FormatNumber(fl(spell.min)), 255,255,255,255,255,255)
							tooltip:AddDoubleLine(L["Maximum hit:"], Skada:FormatNumber(fl(spell.max)), 255,255,255,255,255,255)
						end
					end
				end
			end
		end
	end

	function modHealedSpell:Enter(win, id, label)
		win.modedata.targetid = id
		self.title = L["Healed"]..": "..win.modedata.playername.." > "..id
	end

	function modHealedSpell:Update(win, set)
		-- View spells for this player.

		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player then

			for id, heal in pairs(player.healed) do

				if (id == win.modedata.targetid) and (heal.amount > 0) then
					for spellname, spell in pairs(heal.spell) do

						local d = win.dataset[nr] or {}
						win.dataset[nr] = d

						d.id = spellname
						d.label = spellname
						d.value = spell.healing
						d.valuetext = Skada:FormatValueText(
														Skada:FormatNumber(fl(spell.healing)), self.metadata.columns.Healing,
														string.format("%02.1f%%", spell.healing / heal.amount * 100), self.metadata.columns.Percent
													)
						local _, _, icon = GetSpellInfo(spell.id)
						d.icon = icon
						d.spellid = spell.id

						if spell.healing > max then
							max = spell.healing
						end

						nr = nr + 1
					end
				end
			end
		end

		win.metadata.maxvalue = max
	end

	local function sort_by_totalhealing(a, b)
		return a.total > b.total
	end

	local green = {r = 0, g = 255, b = 0, a = 1}
	local red = {r = 255, g = 0, b = 0, a = 1}

	function total:Update(win, set)
		-- Calculate the highest total healing.
		-- How to get rid of this iteration?
		local dataTable = {}
		local tnr = 1
		local nr = 1
		local rank = 1
		local rankValue = 0
		local maxvalue = 0
		for _, player in pairs(set._playeridx) do
			if (player.healing + player.overhealing) > maxvalue then
				maxvalue = player.healing + player.overhealing
			end
		end

		for _, player in pairs(set._playeridx) do
			if (player.healing > 0) or (player.overhealing > 0) then
				local playerTotal = fl(player.healing + player.overhealing)
				local mypercent = playerTotal / maxvalue
				dataTable[tnr] = {id = player.id, healing = player.healing, total = playerTotal, name = player.name, shortname = player.shortname, perc = mypercent, class = player.class, role = player.role}
				tnr = tnr +1
			end
		end

		table.sort(dataTable, sort_by_totalhealing)

		for _, player in ipairs(dataTable) do
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			if nr == 1 then
				rankValue = player.total
				rank = nr
			else
				if player.total ~= rank then
					rankValue = player.total
					rank = nr
				end
			end
			d.id = player.id
			d.value = player.healing
			d.label = rank..". "..(Skada.db.profile.showrealm and player.name or player.shortname)
			d.valuetext = Skada:FormatNumber(player.healing).." / "..Skada:FormatNumber(player.total)..string.format(" (%02.1f%%)", player.total / (set.healing + set.overhealing) * 100)
			d.class = player.class
			d.role = player.role
			d.color = green
			d.backgroundcolor = red
			d.backgroundwidth = player.perc
			nr = nr + 1
		end

		win.metadata.maxvalue = maxvalue
	end

	function totalSpell:Enter(win, id, label)
		win.modedata.playerid = id
		local player = Skada:find_player(win:get_selected_set(), id)
		if player then
			self.title = L["Total healing"]..": "..player.name
		end
	end

	function totalSpell:Update(win, set)
		local dataTable = {}
		local tnr = 1
		local nr = 1
		local maxvalue = 0
		local player = Skada:find_player(set, win.modedata.playerid)

		if player then
			for _, spell in pairs(player.healingspells) do
				if spell.healing + spell.overhealing > maxvalue then
					maxvalue = spell.healing + spell.overhealing
				end
			end

			for _, spell in pairs(player.healingspells) do
				local spellTotal = fl(spell.healing + spell.overhealing)
				local mypercent = spellTotal / maxvalue
				dataTable[tnr] = {healing = spell.healing, total = spellTotal, name = spell.name, perc = mypercent, id = spell.id}
				tnr = tnr + 1
			end

			table.sort(dataTable, sort_by_totalhealing)

			for _, spell in ipairs(dataTable) do
				if (player.healing + player.overhealing) > 0 then
					local d = win.dataset[nr] or {}
					win.dataset[nr] = d
					d.id = spell.name
					d.label = spell.name
					d.value = spell.healing
					d.valuetext = Skada:FormatNumber(spell.healing).." / "..Skada:FormatNumber(spell.total)..string.format(" (%02.1f%%)", spell.total / (player.healing + player.overhealing) * 100)
					local _, _, icon = GetSpellInfo(spell.id)
					d.icon = icon
					d.spellid = spell.id
					d.color = green
					d.backgroundcolor = red
					d.backgroundwidth = spell.perc
					nr = nr + 1
				end
			end
			win.metadata.maxvalue = maxvalue
		end
	end

	-- Overheal view
	function overheal:Update(win, set)
		local nr = 1
		local max = 0

		for i, player in pairs(set._playeridx) do
			if player.overhealing > 0 then

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = player.id
				d.value = player.overhealing
				d.label = Skada.db.profile.showrealm and player.name or player.shortname

				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(player.overhealing), self.metadata.columns.Overheal,
												string.format(L["Overrate"].." %02.1f%%", player.overhealing / (player.overhealing + player.healing) * 100), self.metadata.columns.Percent
											)
				d.class = player.class
				d.role = player.role

				if player.overhealing > max then
					max = player.overhealing
				end
				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Overheal Spell view
	function overhealSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["Overhealing"]..": "..player.name
	end

	function overhealSpell:Update(win, set)
		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player then

			for spellname, spell in pairs(player.healingspells) do

				if (spell.overhealing + spell.healing) > 0 then
					local d = win.dataset[nr] or {}
					win.dataset[nr] = d

					d.id = spell.name
					d.label = spell.name
					d.value = spell.overhealing
					d.valuetext = Skada:FormatValueText(
													Skada:FormatNumber(spell.overhealing), self.metadata.columns.Healing,
													string.format(L["Overrate"].." %02.1f%%", spell.overhealing / (spell.overhealing + spell.healing) * 100), self.metadata.columns.Percent
												)
					local _, _, icon = GetSpellInfo(spell.id)
					d.icon = icon
					d.spellid = spell.id

					if spell.overhealing > max then
						max = spell.overhealing
					end

					nr = nr + 1
				end
			end
		end

		win.metadata.maxvalue = max
	end

	function absorbed:Update(win, set)
		local nr = 1
		local max = 0

		for i, player in pairs(set._playeridx) do
			if player.healingabsorbed > 0 then

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = player.id
				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.value = player.healingabsorbed

				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(fl(player.healingabsorbed)), self.metadata.columns.Healing,
												Skada:FormatNumber(getHPSByValue(set, player, player.healingabsorbed), true), self.metadata.columns.HPS,
												string.format("%02.1f%%", player.healingabsorbed / set.healingabsorbed * 100), self.metadata.columns.Percent
											)
				d.class = player.class
				d.role = player.role

				if player.healingabsorbed > max then
					max = player.healingabsorbed
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	function absorbedSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["Absorbed heal"]..": "..player.name
	end

	-- absorbed healing spell view
	function absorbedSpell:Update(win, set)
		-- View spells for this player.

		local player = Skada:find_player(set, win.modedata.playerid)
		local nr = 1
		local max = 0

		if player then

			for spellname, spell in pairs(player.healingspells) do
				if player.healingabsorbed > 0 then

					local d = win.dataset[nr] or {}
					win.dataset[nr] = d

					d.id = spellname
					d.label = spellname
					d.value = spell.absorbed
					d.valuetext = Skada:FormatValueText(
													Skada:FormatNumber(fl(spell.absorbed)), self.metadata.columns.Healing,
													string.format("%02.1f%%", spell.absorbed / player.healingabsorbed * 100), self.metadata.columns.Percent
												)
					local _, _, icon = GetSpellInfo(spell.id)
					d.icon = icon
					d.spellid = spell.id

					if spell.absorbed > max then
						max = spell.absorbed
					end

					nr = nr + 1
				end
			end
		end

		win.metadata.maxvalue = max
	end

	-- Spell view of a player.
	function mob:Update(win, set)
		local nr = 1
		local max = 0

		local mobheal = {}
		for name, destInfo in pairs(set.mobhealed) do
			if not mobheal[name] then
				mobheal[name] = 0
			end
			for dname, spellInfo in pairs(destInfo) do
				for spellid, spell in pairs(spellInfo) do
					mobheal[name] = mobheal[name] + spell.healing
				end
			end
		end

		for name, healing in pairs(mobheal) do
			if set.mobhealing > 0 then
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = name
				d.label = name
				d.value = healing
				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(fl(healing)), self.metadata.columns.Healing,
												string.format("%02.1f%%", healing / set.mobhealing * 100), self.metadata.columns.Percent
											)

				if healing > max then
					max = healing
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Spell view of a player.
	local function mob_spell_tooltip(win, id, label, tooltip)
		local set = win:get_selected_set()
		local spell = {}
		if win.modedata.mobname then
			for name, destInfo in pairs(set.mobhealed) do
				if name == win.modedata.mobname then
					for dname, spellInfo in pairs(destInfo) do
						if spellInfo[id] then
							if not spell.hits then
								spell = {hits = spellInfo[id].hits or 0, crits = spellInfo[id].crits or 0, healing = spellInfo[id].healing or 0, overhealing = spellInfo[id].overhealing or 0, min = spellInfo[id].min, max = spellInfo[id].max or 0} 
							else
								spell.hits = spell.hits + spellInfo[id].hits
								spell.crits = spell.crits + spellInfo[id].crits
								spell.healing = spell.healing + spellInfo[id].healing
								spell.overhealing = spell.overhealing + spellInfo[id].overhealing
								if spellInfo[id].min and spell.min and (spellInfo[id].min < spell.min) then
									spell.min = spellInfo[id].min
								end
								if (spellInfo[id].max or 0) > spell.max then
									spell.max = spellInfo[id].max
								end
							end
						end
					end
				end
			end
			if spell.hits and (spell.hits > 0) then
				tooltip:AddLine(win.modedata.mobname..": "..label)
				tooltip:AddDoubleLine(L["Hit:"], Skada:FormatHitNumber(spell.hits), 255,255,255,255,255,255)
				if spell.max and spell.min then
					tooltip:AddDoubleLine(L["Minimum hit:"], Skada:FormatNumber(fl(spell.min)), 255,255,255,255,255,255)
					tooltip:AddDoubleLine(L["Maximum hit:"], Skada:FormatNumber(fl(spell.max)), 255,255,255,255,255,255)
				end
				tooltip:AddDoubleLine(L["Average hit:"], Skada:FormatNumber(fl(spell.healing / spell.hits)), 255,255,255,255,255,255)
				tooltip:AddDoubleLine(L["Critical"]..":", ("%02.1f%%"):format(spell.crits / spell.hits * 100), 255,255,255,255,255,255)
				if (spell.overhealing + spell.healing) > 0 then
					tooltip:AddDoubleLine(L["Overhealed"]..":", ("%02.1f%%"):format(spell.overhealing / (spell.overhealing + spell.healing) * 100), 255,255,255,255,255,255)
				end
			end
		end
	end

	function mobSpell:Enter(win, id, label)
		win.modedata.mobname = label
		self.title = L["Healing"]..": "..label
	end

	function mobSpell:Update(win, set)
		local nr = 1
		local max = 0

		if win.modedata.mobname then
			local spellTable = {}
			local mobheal = 0
			for name, destInfo in pairs(set.mobhealed) do
				if name == win.modedata.mobname then
					for dname, spellInfo in pairs(destInfo) do
						for spellid, spell in pairs(spellInfo) do
							mobheal = mobheal + spell.healing
							if not spellTable[spellid] then
								spellTable[spellid] = 0
							end
							spellTable[spellid] = spellTable[spellid] + spell.healing
						end
					end
				end
			end

			for spellid, healing in pairs(spellTable) do
				if set.mobhealing > 0 then
					local d = win.dataset[nr] or {}
					win.dataset[nr] = d

					d.id = spellid
					d.label = GetSpellInfo(spellid)
					d.value = healing
					d.valuetext = Skada:FormatValueText(
													Skada:FormatNumber(fl(healing)), self.metadata.columns.Healing,
													string.format("%02.1f%%", healing / set.mobhealing * 100), self.metadata.columns.Percent
												)
					local _, _, icon = GetSpellInfo(spellid)
					d.icon = icon
					d.spellid = spellid

					if healing > max then
						max = healing
					end

					nr = nr + 1
				end
			end
		end

		win.metadata.maxvalue = max
	end

	-- Healed players view of a player.
	function mobHealed:Enter(win, id, label)
		win.modedata.mobname = label
		self.title = L["Healed"]..": "..label
	end

	function mobHealed:Update(win, set)
		local nr = 1
		local max = 0

		if win.modedata.mobname then
			for name, destInfo in pairs(set.mobhealed) do
				if name == win.modedata.mobname then
					local nameTable = {}
					for dname, spellInfo in pairs(destInfo) do
						if not nameTable[dname] then
							nameTable[dname] = 0
						end
						for spellid, spell in pairs(spellInfo) do
							nameTable[dname] = nameTable[dname] + spell.healing
						end
					end
					
					for tname, healing in pairs(nameTable) do
						if set.mobhealing > 0 then
							local d = win.dataset[nr] or {}
							win.dataset[nr] = d

							d.id = tname
							d.label = tname
							d.value = healing
							d.valuetext = Skada:FormatValueText(
															Skada:FormatNumber(fl(healing)), self.metadata.columns.Healing,
															string.format("%02.1f%%", healing / set.mobhealing * 100), self.metadata.columns.Percent
														)
							if healing > max then
								max = healing
							end

							nr = nr + 1
						end
					end
				end
			end
		end

		win.metadata.maxvalue = max
	end

	-- Spell view of a player.
	local function mob_healedspell_tooltip(win, id, label, tooltip)
		local set = win:get_selected_set()
		if win.modedata.mobname then
			for name, destInfo in pairs(set.mobhealed) do
				if name == win.modedata.mobname then
					for dname, spellInfo in pairs(destInfo) do
						if dname == win.modedata.targetmobname then
							if spellInfo[id] then
								local spell = set.mobhealed[win.modedata.mobname][win.modedata.targetmobname][id]
								if spell then
									tooltip:AddLine(win.modedata.targetmobname..": "..label)
									tooltip:AddDoubleLine(L["Hit:"], Skada:FormatNumber(spell.hits), 255,255,255,255,255,255)
									if spell.max and spell.min then
										tooltip:AddDoubleLine(L["Minimum hit:"], Skada:FormatNumber(fl(spell.min)), 255,255,255,255,255,255)
										tooltip:AddDoubleLine(L["Maximum hit:"], Skada:FormatNumber(fl(spell.max)), 255,255,255,255,255,255)
									end
								end
							end
						end
					end
				end
			end
		end
	end

	function mobHealedSpell:Enter(win, id, label)
		win.modedata.targetmobname = label
		self.title = L["Healed"]..": "..win.modedata.mobname.." > "..label
	end

	function mobHealedSpell:Update(win, set)
		local nr = 1
		local max = 0

		if win.modedata.mobname then
			for name, destInfo in pairs(set.mobhealed) do
				if name == win.modedata.mobname then
					local mobHeal = 0
					for dname, spellInfo in pairs(destInfo) do
						for spellid, spell in pairs(spellInfo) do
							mobHeal = mobHeal + spell.healing
						end
						if dname == win.modedata.targetmobname then
							for spellid, spell in pairs(spellInfo) do
								if mobHeal > 0 then
									local d = win.dataset[nr] or {}
									win.dataset[nr] = d

									d.id = spellid
									d.label = GetSpellInfo(spellid)
									local _, _, icon = GetSpellInfo(spellid)
									d.icon = icon
									d.spellid = spellid
									d.value = spell.healing
									d.valuetext = Skada:FormatValueText(
																	Skada:FormatNumber(fl(spell.healing)), self.metadata.columns.Healing,
																	string.format("%02.1f%%", spell.healing / mobHeal * 100), self.metadata.columns.Percent
																)
									if spell.healing > max then
										max = spell.healing
									end

									nr = nr + 1
								end
							end
						end
					end
				end
			end
		end

		win.metadata.maxvalue = max
	end

	-- healing taken view
	function taken:Update(win, set)
		local nr = 1
		local max = 0

		for id, player in pairs(set._playeridx) do
			-- Iterate over all players and add to this player's healing taken.
			local totalhealing = 0

			-- Iterate over each healed player this player did.
			-- Bit expensive doing this once for each player in raid; can be done differently.
			for i, p in pairs(set._playeridx) do
				for name, heal in pairs(p.healed) do
					if name == player.name then
						totalhealing = totalhealing + heal.amount
					end
				end
			end

			-- Now we have a total healing value for this player.
			if totalhealing > 0 then
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = player.name
				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.value = totalhealing

				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(fl(totalhealing)), self.metadata.columns.Healing,
												Skada:FormatNumber(getHPSByValue(set, player, totalhealing), true), self.metadata.columns.HPS,
												string.format("%02.1f%%", totalhealing / set.healing * 100), self.metadata.columns.Percent
											)
				d.class = player.class
				d.role = player.role

				if totalhealing > max then
					max = totalhealing
				end

				nr = nr + 1
			end

		end
		win.metadata.maxvalue = max
	end

	-- healing taken spell view
	function takenSpell:Enter(win, id, label)
		win.modedata.playername = id
		self.title = L["Healing taken"]..": "..id
	end

	function takenSpell:Update(win, set)
		local nr = 1
		local max = 0

		local spellTable = {}
		local playerTaken = {}
		for i, player in pairs(set._playeridx) do
			for name, heal in pairs(player.healed) do
				if name == win.modedata.playername then
					for spellname, spell in pairs(heal.spell) do
						if not spellTable[spell.id] then
							spellTable[spell.id] = 0
						end
						spellTable[spell.id] = spellTable[spell.id] + spell.healing
					end
					if not playerTaken[name] then
						playerTaken[name] = 0
					end
					playerTaken[name] = playerTaken[name] + heal.amount
				end
			end
		end

		for spellid, amount in pairs(spellTable) do
			if (playerTaken[win.modedata.playername] > 0) then
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = spellid
				d.label = GetSpellInfo(spellid)
				local _, _, icon = GetSpellInfo(spellid)
				d.icon = icon
				d.spellid = spellid
				d.value = amount

				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(fl(amount)), self.metadata.columns.Healing,
												string.format("%02.1f%%", amount / playerTaken[win.modedata.playername] * 100), self.metadata.columns.Percent
											)

				if amount > max then
					max = amount
				end

				nr = nr + 1
			end

		end

		win.metadata.maxvalue = max
	end

	-- healing taken player view
	function takenPlayer:Enter(win, id, label)
		win.modedata.playername = id
		self.title = L["Heal from"]..": "..id
	end

	function takenPlayer:Update(win, set)
		local nr = 1
		local max = 0

		local playerTable = {}
		local playerClass = {}
		local playerRole = {}
		local playerTaken = {}
		for i, player in pairs(set._playeridx) do
			for name, heal in pairs(player.healed) do
				if name == win.modedata.playername then
					if not playerTable[player.name] then
						playerTable[player.name] = 0
					end
					if not playerClass[player.name] then
						playerClass[player.name] = player.class
					end
					if not playerRole[player.name] then
						playerRole[player.name] = player.role
					end
					if not playerTaken[name] then
						playerTaken[name] = 0
					end
					playerTable[player.name] = playerTable[player.name] + heal.amount
					playerTaken[name] = playerTaken[name] + heal.amount
				end
			end
		end

		for name, amount in pairs(playerTable) do
			if (playerTaken[win.modedata.playername] > 0) then
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = name
				d.label = Skada.db.profile.showrealm and name or name:gsub("%-.*$", "")
				d.value = amount

				d.valuetext = Skada:FormatValueText(
												Skada:FormatNumber(fl(amount)), self.metadata.columns.Healing,
												string.format("%02.1f%%", amount / playerTaken[win.modedata.playername] * 100), self.metadata.columns.Percent
											)
				d.class = playerClass[name]
				d.role = playerRole[name]

				if amount > max then
					max = amount
				end

				nr = nr + 1
			end

		end
		win.metadata.maxvalue = max
	end

	function mod:OnEnable()
		mod.metadata =				{showspots = true, click1 = modAllSpell, click2 = modHealed, columns = {Healing = true, HPS = true, Percent = true}}
		modAllSpell.metadata =		{tooltip = spell_tooltip, columns = {Healing = true, Percent = true}}
		modHealed.metadata =		{showspots = true, click1 = modHealedSpell , columns = {Healing = true, Percent = true}}
		modHealedSpell.metadata =	{tooltip = healedspell_tooltip, columns = {Healing = true, Percent = true}}
		total.metadata =			{ordersort = true, click1 = totalSpell}
		totalSpell.metadata =		{ordersort = true}
		overheal.metadata =			{showspots = true, click1 = overhealSpell, columns = {Overheal = true, Percent = true}}
		overhealSpell.metadata =	{columns = {Healing = true, Percent = true}}
		absorbed.metadata =			{showspots = true, click1 = absorbedSpell, columns = {Healing = true, HPS = true, Percent = true}}
		absorbedSpell.metadata =	{columns = {Healing = true, Percent = true}}
		mob.metadata =				{showspots = true, click1 = mobSpell, click2 = mobHealed, columns = {Healing = true, Percent = true}}
		mobSpell.metadata =			{tooltip = mob_spell_tooltip, columns = {Healing = true, Percent = true}}
		mobHealed.metadata =		{showspots = true, click1 = mobHealedSpell, columns = {Healing = true, Percent = true}}
		mobHealedSpell.metadata =	{tooltip = mob_healedspell_tooltip, columns = {Healing = true, Percent = true}}
		taken.metadata =			{showspots = true, click1 = takenSpell, click2 = takenPlayer, columns = {Healing = true, HPS = true, Percent = true}}
		takenSpell.metadata =		{columns = {Healing = true, Percent = true}}
		takenPlayer.metadata =		{showspots = true, columns = {Healing = true, Percent = true}}

		-- handlers for Healing spells
		Skada:RegisterForCL(SpellHeal, 'SPELL_HEAL', {src_is_interesting = true})
		Skada:RegisterForCL(SpellAbsorbed, 'SPELL_ABSORBED', {all = true})
		Skada:RegisterForCL(SpellHealHot, 'SPELL_PERIODIC_HEAL', {src_is_interesting = true})

		-- handlers for Absorption spells
		Skada:RegisterForCL(AuraApplied, 'SPELL_AURA_APPLIED', {src_is_interesting_nopets = true}, true)
		Skada:RegisterForCL(AuraRemoved, 'SPELL_AURA_REMOVED', {src_is_interesting_nopets = true}, true)

		-- handlers for mob healings
		Skada:RegisterForCL(mobHealing, 'SPELL_HEAL', {src_is_not_interesting = true})
		Skada:RegisterForCL(mobHealing, 'SPELL_PERIODIC_HEAL', {src_is_not_interesting = true})

		Skada:AddMode(self)
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)
	end

	function total:OnEnable()
		Skada:AddMode(self)
	end

	function total:OnDisable()
		Skada:RemoveMode(self)
	end

	function overheal:OnEnable()
		Skada:AddMode(self)
	end

	function overheal:OnDisable()
		Skada:RemoveMode(self)
	end

	function absorbed:OnEnable()
		Skada:AddMode(self)
	end

	function absorbed:OnDisable()
		Skada:RemoveMode(self)
	end

	function mob:OnEnable()
		Skada:AddMode(self)
	end

	function mob:OnDisable()
		Skada:RemoveMode(self)
	end

	function taken:OnEnable()
		Skada:AddMode(self)
	end

	function taken:OnDisable()
		Skada:RemoveMode(self)
	end

	function mod:AddToTooltip(set, tooltip)
		GameTooltip:AddDoubleLine(L["HPS"], Skada:FormatNumber(getRaidHPS(set), true), 1,1,1)
	end

	function mod:GetSetSummary(set)
		return Skada:FormatValueText(Skada:FormatNumber(fl(set.healing)), self.metadata.columns.Healing, Skada:FormatNumber(getRaidHPS(set), true), self.metadata.columns.HPS)
	end

	function total:GetSetSummary(set)
		return Skada:FormatNumber(fl(set.healing + set.overhealing))
	end

	function overheal:GetSetSummary(set)
		return Skada:FormatNumber(fl(set.overhealing))
	end

	function absorbed:GetSetSummary(set)
		return Skada:FormatNumber(fl(set.healingabsorbed))
	end

	function mob:GetSetSummary(set)
		return Skada:FormatNumber(fl(set.mobhealing))
	end

	function mod:Clear(set)
		-- Clean
		wipe(shields)
	end

	-- Called by Skada when a new player is added to a set.
	function mod:AddPlayerAttributes(player)
		if not player.healing then
			player.healing = 0			-- Total healing
			player.overhealing = 0		-- Overheal total
			player.healingabsorbed = 0	-- Absorbed total
		end
		if not player.healed then
			player.healed = {}			-- Stored healing per recipient
			player.healingspells = {}	-- Healing spells
		end
	end

	-- Called by Skada when a new set is created.
	function mod:AddSetAttributes(set)
		if not set.healing then
			set.healing = 0
			set.overhealing = 0
			set.healingabsorbed = 0
			wipe(shields)
		end
		if not set.mobhealing then
			set.mobhealing = 0
		end
		if not set.mobhealed then
			set.mobhealed = {}
		end
	end
end)
