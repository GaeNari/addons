Skada:AddLoadableModule("Debuffs", function(Skada, L)
	if Skada.db.profile.modulesBlocked.Debuffs then return end

	local debuff = Skada:NewModule(L["Debuff uptimes"], "AceTimer-3.0")
	local debuffSpell = Skada:NewModule(L["Debuff uptimes: Spell list"])
	local buffs = Skada:NewModule(L["Buff uptimes"])
	local buffSpell = Skada:NewModule(L["Buff uptimes: Spell list"])

	local UnitBuff, UnitDebuff, UnitExists, InCombatLockdown = _G.UnitBuff, _G.UnitDebuff, _G.UnitExists, _G.InCombatLockdown
	local debuff_update
	local elapsed = 0

	local function updatewindow()
		-- different update rate
		local windows = Skada:GetWindows()
		for i, win in ipairs(windows) do
			if win.selectedmode and win.selectedmode.ManualUpdate then
				local set = win:get_selected_set()

				if set then
					win.selectedmode:Update(win, set)
				end

				win:UpdateDisplay()
			end
		end
	end

	debuff.ManualUpdate = updatewindow
	debuffSpell.ManualUpdate = updatewindow
	buffs.ManualUpdate = updatewindow
	buffSpell.ManualUpdate = updatewindow

	debuff.Order = 91
	buffs.Order = 92

	-- Record buff status to set db.
	local function tick_spells(set)
		if set then
			local buffCT = Skada.char.buffsCharDB
			local buffT = Skada.char.buffsDB
			-- player update
			if buffCT then
				for id, name in pairs(buffCT) do
					-- Get the player.
					local auraT = buffT[id]
					local player = Skada:get_player(set, id, name, true)
					if player and auraT then
						for spellname, aura in pairs(auraT) do
							if UnitBuff(name, spellname) or UnitDebuff(name, spellname) then
								if not player.auras[spellname] then
									player.auras[spellname] = {id = aura.id, name = spellname, count = 1, uptime = 1, auratype = aura.auratype}
								else
									player.auras[spellname].uptime = player.auras[spellname].uptime + 1
								end
							else
								auraT[spellname] = nil
							end
						end
					end
				end
			end
		end
	end

	local function tick_harmspells(set)
		if set then
			-- harm update
			for i, player in pairs(set._playeridx) do
				for spellname, spell in pairs(player.harmauras) do
					if spell.active then
						spell.uptime = spell.uptime + 1
						-- total table update
						if Skada.total then
							local tplayer = Skada:get_player(Skada.total, player.id, player.name, true)
							if tplayer then
								if not tplayer.harmauras[spellname] then
									tplayer.harmauras[spellname] = {id = spell.id, name = spellname, count = 1, uptime = 1}
								else
									tplayer.harmauras[spellname].uptime = tplayer.harmauras[spellname].uptime + 1
								end
							end
						end
					end
				end
			end
		end
	end

	function debuff:Tick()
		elapsed = elapsed + 1
		tick_spells(Skada.current)
		tick_spells(Skada.total)
		tick_harmspells(Skada.current)
		updatewindow(nil, true)
	end

	local function log_auraapply(set, aura)
		local buffT = Skada.char.buffsDB
		local buffCT = Skada.char.buffsCharDB
		if buffT and buffCT and aura.playerid then
			-- add buff table
			if not buffCT[aura.playerid] then
				buffCT[aura.playerid] = aura.playername
			end
			if not buffT[aura.playerid] then
				buffT[aura.playerid] = {}
			end
			if not buffT[aura.playerid][aura.spellname] then
				buffT[aura.playerid][aura.spellname] = {id = aura.spellid, auratype = aura.auratype}
			end
			-- add count
			if Skada.current then
				local player = Skada:find_player(set, aura.playerid)
				if player then
					if not player.auras[aura.spellname] then
						player.auras[aura.spellname] = {id = aura.spellid, name = aura.spellname, count = 1, uptime = 0, auratype = aura.auratype}
					else
						player.auras[aura.spellname].count = (player.auras[aura.spellname].count or 0) + 1
					end
				end
			end
		end
	end

	local function log_auraremove(aura)
		local buffT = Skada.char.buffsDB
		local buffCT = Skada.char.buffsCharDB
		if buffT and buffCT and aura.playerid then
			if not buffCT[aura.playerid] then
				buffCT[aura.playerid] = aura.playername
			end
			if not buffT[aura.playerid] then return end
			if buffT[aura.playerid][aura.spellname] then
				buffT[aura.playerid][aura.spellname] = nil
			end
		end
	end

	local function log_auraapplyharm(set, aura)
		if set then
			-- current
			local player = Skada:get_player(set, aura.playerid, aura.playername, true)
			if player then
				if not player.harmauras[aura.spellname] then
					player.harmauras[aura.spellname] = {id = aura.spellid, name = aura.spellname, count = 1, uptime = 0, active = true}
				else
					player.harmauras[aura.spellname].active = true
					player.harmauras[aura.spellname].count = (player.harmauras[aura.spellname].count or 0) + 1
				end
			end
			-- total
			local tplayer = Skada:get_player(Skada.total, aura.playerid, aura.playername, true)
			if tplayer then
				if not tplayer.harmauras[aura.spellname] then
					tplayer.harmauras[aura.spellname] = {id = aura.spellid, name = aura.spellname, count = 1, uptime = 0}
				else
					tplayer.harmauras[aura.spellname].count = (tplayer.harmauras[aura.spellname].count or 0) + 1
				end
			end
		end
	end

	local function log_auraremoveharm(set, aura)
		-- only current table can have active status
		if set then
			local player = Skada:find_player(set, aura.playerid)
			if player and player.harmauras[aura.spellname] then
				player.harmauras[aura.spellname].active = false
			end
		end
	end

	local aura = {}

	local function AuraApplied(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)
		aura.playerid = dstGUID
		aura.playername = dstName
		aura.spellid = spellId
		aura.spellname = spellName
		aura.auratype = auraType

		log_auraapply(Skada.current, aura)
		log_auraapply(Skada.total, aura)
	end

	local function AuraRemoved(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)
		aura.playerid = dstGUID
		aura.playername = dstName
		aura.spellid = spellId
		aura.spellname = spellName

		log_auraremove(aura)
	end

	local function AuraAppliedHarm(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)
		if auraType ~= "DEBUFF" then return end
		aura.playerid = srcGUID
		aura.playername = srcName
		aura.playerflags = srcFlags
		aura.spellid = spellId
		aura.spellname = spellName

		Skada:FixPets(aura)
		log_auraapplyharm(Skada.current, aura)
	end

	local function AuraRemovedHarm(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)
		if auraType ~= "DEBUFF" then return end
		aura.playerid = srcGUID
		aura.playername = srcName
		aura.playerflags = srcFlags
		aura.spellname = spellName
		aura.spellid = spellId

		Skada:FixPets(aura)
		log_auraremoveharm(Skada.current, aura)
	end

	-- handle weapon-procced self-buffs that show with a null source
	-- 5/17 02:58:15.156 SPELL_AURA_APPLIED,0x0000000000000000,nil,0x4228,0x0,0x0180000005F37DDE,"Grimbit",0x511,0x0,104993,"Jade Spirit",0x2,BUFF
	local function NullAura(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		if srcName == nil and #srcGUID == 0 and dstName and #dstGUID > 0 then
			--print(eventtype, ...)
			srcName = dstName
			srcGUID = dstGUID
			srcFlags = dstFlags

			if eventtype == 'SPELL_AURA_APPLIED' then
				AuraApplied(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
			else
				AuraRemoved(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
			end
		end
	end

	local function len(t)
		local l = 0
		for i,j in pairs(t) do
			l = l + 1
		end
		return l
	end

	local function updatefunc(auratype, win, set)
		local nr = 1
		local max = 0

		for i, player in pairs(set._playeridx) do
			-- Find number of debuffs.
			local auracount = 0
			local aurauptime = 0
			for spellname, spell in pairs(player.auras) do
				if spell.auratype == auratype then
					auracount = auracount + (spell.count or 1) -- for lagacy.
					aurauptime = aurauptime + spell.uptime
				end
			end
			if auratype == "DEBUFF" then
				for spellname, spell in pairs(player.harmauras) do
					auracount = auracount + (spell.count or 1) -- for lagacy.
					aurauptime = aurauptime + spell.uptime
				end
			end

			if auracount > 0 then
				-- Calculate player max possible uptime.
				local maxtime = Skada:PlayerActiveTime(set, player)

				-- Now divide by the number of spells to get the average uptime.
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d

				d.id = player.id
				d.value = auracount
				d.label = Skada.db.profile.showrealm and player.name or player.shortname
				d.valuetext = ("%s"):format(Skada:FormatHitNumber(auracount))
				d.class = player.class
				d.role = player.role

				if auracount > max then
					max = auracount
				end

				nr = nr + 1
			end
		end

		win.metadata.maxvalue = max
	end

	-- Detail view of a player.
	local function detailupdatefunc(auratype, win, set, playerid)
		-- View spells for this player.
		local nr = 1
		local max = 0
		local player = Skada:find_player(set, playerid)

		if player then
			-- Calculate player max possible uptime.
			local maxtime = Skada:GetSetTime(set)

			win.metadata.maxvalue = maxtime
			if maxtime > 0 then
				local dataTable = {}
				for spellname, spell in pairs(player.auras) do
					if spell.auratype == auratype then
						dataTable[spellname] = spell
					end
				end
				if auratype == "DEBUFF" then
					for spellname, spell in pairs(player.harmauras) do
						dataTable[spellname] = spell
					end
				end
				for spellname, spell in pairs(dataTable) do
					local uptime = min(maxtime, spell.uptime)

					local d = win.dataset[nr] or {}
					win.dataset[nr] = d

					d.id = spell.name
					d.value = uptime
					d.label = spell.name
					local _, _, icon = GetSpellInfo(spell.id)
					d.icon = icon
					d.spellid = spell.id
					d.valuetext = ("%s/%s"..L["s"].." (%02.1f%%)"):format(Skada:FormatHitNumber(spell.count or 1), Skada:FormatHitNumber(uptime, true), uptime / maxtime * 100)

					nr = nr + 1
				end
			end
		end

	end

	function debuff:Update(win, set)
		updatefunc("DEBUFF", win, set)
	end

	function debuffSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["Debuffs"]..": "..player.name
	end

	function debuffSpell:Update(win, set)
		detailupdatefunc("DEBUFF", win, set, win.modedata.playerid)
	end

	function buffs:Update(win, set)
		updatefunc("BUFF", win, set)
	end

	function buffSpell:Enter(win, id, label)
		local player = Skada:find_player(win:get_selected_set(), id)
		win.modedata.playerid = id
		self.title = L["Buffs"]..": "..player.name
	end

	-- Detail view of a player.
	function buffSpell:Update(win, set)
		detailupdatefunc("BUFF", win, set, win.modedata.playerid)
	end

	function debuff:OnEnable()
		debuff.metadata 		= {showspots = 1, click1 = debuffSpell, click2 = buffSpell}
		debuffSpell.metadata 	= {}
		buffs.metadata 			= {showspots = 1, click1 = buffSpell, click2 = debuffSpell}
		buffSpell.metadata 		= {}

		Skada:RegisterForCL(AuraApplied, 'SPELL_AURA_APPLIED', {dst_is_interesting_nopets = true}, true)
		Skada:RegisterForCL(AuraApplied, 'SPELL_AURA_REFRESH', {dst_is_interesting_nopets = true}, true)
		Skada:RegisterForCL(AuraRemoved, 'SPELL_AURA_REMOVED', {dst_is_interesting_nopets = true}, true)
		Skada:RegisterForCL(AuraAppliedHarm, 'SPELL_AURA_APPLIED', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(AuraAppliedHarm, 'SPELL_AURA_REFRESH', {src_is_interesting = true, dst_is_not_interesting = true})
		Skada:RegisterForCL(AuraRemovedHarm, 'SPELL_AURA_REMOVED', {src_is_interesting = true, dst_is_not_interesting = true})

		-- ticket 307: some weapon-procced self buffs (eg Jade Spirit) have a null src
		Skada:RegisterForCL(NullAura, 'SPELL_AURA_APPLIED', {dst_is_interesting_nopets = true, src_is_not_interesting = true}, true)
		Skada:RegisterForCL(NullAura, 'SPELL_AURA_REMOVED', {dst_is_interesting_nopets = true, src_is_not_interesting = true}, true)

		Skada:AddMode(self)
		Skada:AddMode(buffs)
	end

	function debuff:OnDisable()
		Skada:RemoveMode(self)
		Skada:RemoveMode(buffs)
	end

	-- Called by Skada when a new player is added to a set.
	function debuff:AddPlayerAttributes(player)
		if not player.auras then
			player.auras = {}
		end
		if not player.harmauras then
			player.harmauras = {}
		end
	end

	function debuff:Clear()
		self:ZoneCheck(true)
		self:CancelTimer(debuff_update)
		debuff_update = nil
		-- restart tick timer if reset during combat
		if InCombatLockdown() then
			self:StartCombat()
		end
	end

	local function zonecheck()
		local buffT = Skada.char.buffsDB
		local buffCT = Skada.char.buffsCharDB
		-- clear buff table
		if buffCT then
			for id, name in pairs(buffCT) do
				if not UnitExists(name) then
					buffCT[id] = nil
					buffT[id] = nil
				else
					local auraT = buffT[id]
					if auraT then
						for spellname, aura in pairs(auraT) do
							aura.uptime = nil
							if not UnitBuff(name, spellname) and not UnitDebuff(name, spellname) then
								auraT[spellname] = nil
							end
						end
					end
				end
			end
		end
		if buffT then
			for id, spell in pairs(buffT) do
				if buffCT and not buffCT[id] then
					buffT[id] = nil
				end
			end
		end
	end

	function debuff:ZoneCheck(force)
		if not force and Skada:InCombat() then return end
		C_Timer.After(1, zonecheck)
	end

	function debuff:MemberChange()
		local buffT = Skada.char.buffsDB
		local buffCT = Skada.char.buffsCharDB
		-- clear buff table
		if buffCT then
			for id, name in pairs(buffCT) do
				if not UnitExists(name) then
					buffCT[id] = nil
					buffT[id] = nil
				end
			end
		end
		if buffT then
			for id, spell in pairs(buffT) do
				if buffCT and not buffCT[id] then
					buffT[id] = nil
				end
			end
		end
	end

	function debuff:StartCombat()
		elapsed = 0
		debuff_update = self:ScheduleRepeatingTimer("Tick", 1)
	end

	function debuff:EndCombat()
		if elapsed < Skada.current.time then
			self:Tick()
		end
		self:CancelTimer(debuff_update)
		debuff_update = nil
	end

	-- Called by Skada when a new set is created.
	function debuff:AddSetAttributes(set)
		if not Skada.char.buffsDB then
			Skada.char.buffsDB = {}
			Skada.char.buffsCharDB = {}
		end
	end
end)
