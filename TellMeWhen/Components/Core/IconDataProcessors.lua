-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local format = format
local isNumber = TMW.isNumber







-- SHOWN: "shown"
do
	local Processor = TMW.Classes.IconDataProcessor:New("SHOWN", "shown")
	Processor.dontInherit = true

	-- Processor:CompileFunctionSegment(t) is default.

	-- The default state is hidden, so reflect this.
	TMW.Classes.Icon.attributes.shown = false
end






-- ALPHA: "alpha"
do
	local Processor = TMW.Classes.IconDataProcessor:New("ALPHA", "alpha")
	Processor.dontInherit = true

	TMW.IconAlphaManager:AddHandler(100, "ALPHA")
	-- Processor:CompileFunctionSegment(t) is default.

	TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
		if not TMW.Locked then
			icon:SetInfo("alpha", 0)
		end
	end)
end






-- ALPHAOVERRIDE: "alphaOverride"
do
	local Processor = TMW.Classes.IconDataProcessor:New("ALPHAOVERRIDE", "alphaOverride")
	TMW.IconAlphaManager:AddHandler(0, "ALPHAOVERRIDE", true)
	Processor.dontInherit = true
end






-- REALALPHA: "realAlpha"
do
	local Processor = TMW.Classes.IconDataProcessor:New("REALALPHA", "realAlpha")
	Processor.dontInherit = true
	Processor:AssertDependency("SHOWN")

	TMW.Classes.Icon.attributes.realAlpha = 0

	Processor:RegisterIconEvent(11, "OnShow", {
		category = L["EVENT_CATEGORY_VISIBILITY"],
		text = L["SOUND_EVENT_ONSHOW"],
		desc = L["SOUND_EVENT_ONSHOW_DESC"],
	})
	Processor:RegisterIconEvent(12, "OnHide", {
		category = L["EVENT_CATEGORY_VISIBILITY"],
		text = L["SOUND_EVENT_ONHIDE"],
		desc = L["SOUND_EVENT_ONHIDE_DESC"],
		settings = {
			OnlyShown = "FORCEDISABLED",
		},
	})
	Processor:RegisterIconEvent(13, "OnAlphaInc", {
		category = L["EVENT_CATEGORY_VISIBILITY"],
		text = L["SOUND_EVENT_ONALPHAINC"],
		desc = L["SOUND_EVENT_ONALPHAINC_DESC"],
		settings = {
			Operator = true,
			Value = true,
			CndtJustPassed = true,
			PassingCndt = true,
		},
		valueName = L["ALPHA"],
		valueSuffix = "%",
		conditionChecker = function(icon, eventSettings)
			return TMW.CompareFuncs[eventSettings.Operator](icon.attributes.realAlpha * 100, eventSettings.Value)
		end,
	})
	Processor:RegisterIconEvent(14, "OnAlphaDec", {
		category = L["EVENT_CATEGORY_VISIBILITY"],
		text = L["SOUND_EVENT_ONALPHADEC"],
		desc = L["SOUND_EVENT_ONALPHADEC_DESC"],
		settings = {
			Operator = true,
			Value = true,
			CndtJustPassed = true,
			PassingCndt = true,
		},
		valueName = L["ALPHA"],
		valueSuffix = "%",
		conditionChecker = function(icon, eventSettings)
			return TMW.CompareFuncs[eventSettings.Operator](icon.attributes.realAlpha * 100, eventSettings.Value)
		end,
	})

	function Processor:CompileFunctionSegment(t)
		-- GLOBALS: realAlpha
		t[#t+1] = [[
		if realAlpha ~= attributes.realAlpha then
			local oldalpha = attributes.realAlpha or 0

			attributes.realAlpha = realAlpha

			-- detect events that occured, and handle them if they did
			if realAlpha == 0 then
				if EventHandlersSet.OnHide then
					icon:QueueEvent("OnHide")
				end
			elseif oldalpha == 0 then
				if EventHandlersSet.OnShow then
					icon:QueueEvent("OnShow")
				end
			elseif realAlpha > oldalpha then
				if EventHandlersSet.OnAlphaInc then
					icon:QueueEvent("OnAlphaInc")
				end
			else -- it must be less than, because it isnt greater than and it isnt the same
				if EventHandlersSet.OnAlphaDec then
					icon:QueueEvent("OnAlphaDec")
				end
			end

			TMW:Fire(REALALPHA.changedEvent, icon, realAlpha, oldalpha)
			doFireIconUpdated = true
		end
		--]]
	end

	Processor:RegisterDogTag("TMW", "IsShown", {	
		code = function(icon)
			icon = TMW.GUIDToOwner[icon]

			if icon then
				local attributes = icon.attributes
				return not not attributes.shown and attributes.realAlpha > 0
			else
				return false
			end
		end,
		arg = {
			'icon', 'string', '@req',
		},
		events = TMW:CreateDogTagEventString("SHOWN", "REALALPHA"),
		ret = "boolean",
		doc = L["DT_DOC_IsShown"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
		example = '[IsShown] => "true"; [IsShown(icon="TMW:icon:1I7MnrXDCz8T")] => "false"',
		category = L["ICON"],
	})
	Processor:RegisterDogTag("TMW", "Opacity", {	
		code = function(icon)
			icon = TMW.GUIDToOwner[icon]
			
			if icon then
				return icon.attributes.realAlpha
			else
				return 0
			end
		end,
		arg = {
			'icon', 'string', '@req',
		},
		events = TMW:CreateDogTagEventString("REALALPHA"),
		ret = "number",
		doc = L["DT_DOC_Opacity"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
		example = '[Opacity] => "1"; [Opacity(icon="TMW:icon:1I7MnrXDCz8T")] => "0.42"',
		category = L["ICON"],
	})
end






-- CONDITION: "conditionFailed"
do
	local Processor = TMW.Classes.IconDataProcessor:New("CONDITION", "conditionFailed")
	Processor.dontInherit = true

	-- Processor:CompileFunctionSegment(t) is default.
end






-- DURATION: "start, duration"
do
	local Processor = TMW.Classes.IconDataProcessor:New("DURATION", "start, duration")
	Processor:DeclareUpValue("OnGCD", TMW.OnGCD)

	TMW.Classes.Icon.attributes.start = 0
	TMW.Classes.Icon.attributes.duration = 0

	Processor:RegisterIconEvent(21, "OnStart", {
		category = L["EVENT_CATEGORY_TIMER"],
		text = L["SOUND_EVENT_ONSTART"],
		desc = L["SOUND_EVENT_ONSTART_DESC"],
	})

	Processor:RegisterIconEvent(22, "OnFinish", {
		category = L["EVENT_CATEGORY_TIMER"],
		text = L["SOUND_EVENT_ONFINISH"],
		desc = L["SOUND_EVENT_ONFINISH_DESC"],
	})

	Processor:RegisterIconEvent(23, "OnDuration", {
		category = L["EVENT_CATEGORY_TIMER"],
		text = L["SOUND_EVENT_ONDURATION"],
		desc = L["SOUND_EVENT_ONDURATION_DESC"],
		settings = {
			Operator = true,
			Value = true,
			CndtJustPassed = "FORCE",
			PassingCndt = "FORCE",
		},
		blacklistedOperators = {
			["~="] = true,
			["=="] = true,
		},
		valueName = L["DURATION"],
		conditionChecker = function(icon, eventSettings)
			local attributes = icon.attributes
			local d = attributes.duration - (TMW.time - attributes.start)
			d = d > 0 and d or 0

			return TMW.CompareFuncs[eventSettings.Operator](d, eventSettings.Value)
		end,
		applyDefaultsToSetting = function(EventSettings)
			EventSettings.CndtJustPassed = true
			EventSettings.PassingCndt = true
		end,
	})

	function Processor:CompileFunctionSegment(t)
		-- GLOBALS: start, duration
		t[#t+1] = [[
		duration = duration or 0
		start = start or 0
		
		if duration == 0.001 then duration = 0 end -- hardcode fix for tricks of the trade. nice hardcoding on your part too, blizzard
		local d
		if start == TMW.time then
			d = duration
		else
			d = duration - (TMW.time - start)
		end
		d = d > 0 and d or 0

		if EventHandlersSet.OnDuration then
			if d ~= icon.__lastDur then
				icon:QueueEvent("OnDuration")
				icon.__lastDur = d
			end
		end

		if attributes.start ~= start or attributes.duration ~= duration then

			local realDuration = icon:OnGCD(duration) and 0 or duration -- the duration of the cooldown, ignoring the GCD
			if icon.__realDuration ~= realDuration then
				-- detect events that occured, and handle them if they did
				if realDuration == 0 then
					if EventHandlersSet.OnFinish then
						icon:QueueEvent("OnFinish")
					end
				else
					if EventHandlersSet.OnStart then
						icon:QueueEvent("OnStart")
					end
				end
				icon.__realDuration = realDuration
			end

			attributes.start = start
			attributes.duration = duration

			TMW:Fire(DURATION.changedEvent, icon, start, duration, d)
			doFireIconUpdated = true
		end
		--]]
	end


	function Processor:OnImplementIntoIcon(icon)
		if icon.EventHandlersSet.OnDuration then
			for _, EventSettings in TMW:InNLengthTable(icon.Events) do
				if EventSettings.Event == "OnDuration" then
					self:RegisterDurationTrigger(icon, EventSettings.Value)
				end
			end
		end
	end





	---------------------------------
	-- Duration triggers
	---------------------------------

	-- Duration triggers. Register a duration trigger to cause a call to
	-- icon:SetInfo("start, duration", icon.attributes.start, icon.attributes.duration)
	-- when the icon reaches the specified duration.
	local DurationTriggers = {}
	Processor.DurationTriggers = DurationTriggers
	function Processor:RegisterDurationTrigger(icon, duration)
		if not DurationTriggers[icon] then
			DurationTriggers[icon] = {}
		end

		if not TMW.tContains(DurationTriggers[icon], duration) then
			tinsert(DurationTriggers[icon], duration)
		end
	end

	function Processor:OnUnimplementFromIcon(icon)
		if DurationTriggers[icon] then
			wipe(DurationTriggers[icon])
		end
	end

	TMW:RegisterCallback("TMW_ONUPDATE_TIMECONSTRAINED_PRE", function(event, time, Locked)
		for icon, durations in pairs(DurationTriggers) do
			if #durations > 0 then
				local lastCheckedDuration = durations.last or 0

				local currentIconDuration = icon.attributes.duration - (time - icon.attributes.start)
				if currentIconDuration < 0 then currentIconDuration = 0 end
				
				-- If the duration didn't change (i.e. it is 0) then don't even try.
				if currentIconDuration ~= lastCheckedDuration then

					for i = 1, #durations do
						local durationToCheck = durations[i]
					--	print(icon, currentIconDuration, lastCheckedDuration, durationToCheck)
						if currentIconDuration <= durationToCheck and -- Make sure we are at or have passed the duration we want to trigger at
							(lastCheckedDuration > durationToCheck -- Make sure that we just reached this duration (so it doesn't continually fire)
							or lastCheckedDuration < currentIconDuration -- or make sure that the duration increased since the last time we checked the triggers.
						) then
							if icon:IsControlled() then
								icon.group.Controller.NextUpdateTime = 0
							else
								icon.NextUpdateTime = 0
							end
						--	print(icon, "TRIGGER")
							--icon:Update()
							--icon:SetInfo("start, duration", icon.attributes.start, icon.attributes.duration)
							break
						end
					end
				end
				durations.last = currentIconDuration
			end
		end
	end)






	local OnGCD = TMW.OnGCD
	Processor:RegisterDogTag("TMW", "Duration", {
		code = function(icon, gcd)
			icon = TMW.GUIDToOwner[icon]

			if icon then
				local attributes = icon.attributes
				local duration = attributes.duration
				
				local remaining = duration - (TMW.time - attributes.start)
				if remaining <= 0 or (not gcd and icon:OnGCD(duration)) then
					return 0
				end

				-- cached version of tonumber()
				return isNumber[format("%.1f", remaining)] or 0
			else
				return 0
			end
		end,
		arg = {
			'icon', 'string', '@req',
			'gcd', 'boolean', true,
		},
		events = "FastUpdate",
		ret = "number",
		doc = L["DT_DOC_Duration"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
		example = '[Duration] => "1.435"; [Duration(gcd=false)] => "0"; [Duration:TMWFormatDuration] => "1.4"; [Duration(icon="TMW:icon:1I7MnrXDCz8T")] => "97.32156"; [Duration(icon="TMW:icon:1I7MnrXDCz8T"):TMWFormatDuration] => "1:37"',
		category = L["ICON"],
	})

	TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
		if not TMW.Locked then
			icon:SetInfo("start, duration", 0, 0)
		end
	end)
end






-- NOMANA: "noMana"
do
	local Processor = TMW.Classes.IconDataProcessor:New("NOMANA", "noMana")
	-- Processor:CompileFunctionSegment(t) is default.

	TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
		if not TMW.Locked then
			icon:SetInfo("noMana", nil)
		end
	end)
end






-- INRANGE: "inRange"
do
	local Processor = TMW.Classes.IconDataProcessor:New("INRANGE", "inRange")

	TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
		if not TMW.Locked then
			icon:SetInfo("inRange", nil)
		end
	end)
end






-- REVERSE: "reverse"
do
	local Processor = TMW.Classes.IconDataProcessor:New("REVERSE", "reverse")
	-- Processor:CompileFunctionSegment(t) is default.

	TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
		icon:SetInfo("reverse", nil)
	end)
end






-- SPELL: "spell"
do
	local Processor = TMW.Classes.IconDataProcessor:New("SPELL", "spell")

	function Processor:CompileFunctionSegment(t)
		-- GLOBALS: spell
		t[#t+1] = [[
		if attributes.spell ~= spell then
			attributes.spell = spell
			
			if EventHandlersSet.OnSpell then
				icon:QueueEvent("OnSpell")
			end

			TMW:Fire(SPELL.changedEvent, icon, spell)
			doFireIconUpdated = true
		end
		--]]
	end

	Processor:RegisterIconEvent(31, "OnSpell", {
		category = L["EVENT_CATEGORY_CHANGED"],
		text = L["SOUND_EVENT_ONSPELL"],
		desc = L["SOUND_EVENT_ONSPELL_DESC"],
	})
		
	Processor:RegisterDogTag("TMW", "Spell", {
		code = function(icon, link)
			icon = TMW.GUIDToOwner[icon]

			if icon then
				local name, checkcase = icon.typeData:FormatSpellForOutput(icon, icon.attributes.spell, link)
				name = name or ""
				if checkcase and name ~= "" then
					name = TMW:RestoreCase(name)
				end
				return name
			else
				return ""
			end
		end,
		arg = {
			'icon', 'string', '@req',
			'link', 'boolean', false,
		},
		events = TMW:CreateDogTagEventString("SPELL"),
		ret = "string",
		doc = L["DT_DOC_Spell"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
		example = ('[Spell] => %q; [Spell(link=true)] => %q; [Spell(icon="TMW:icon:1I7MnrXDCz8T")] => %q; [Spell(icon="TMW:icon:1I7MnrXDCz8T", link=true)] => %q'):format(GetSpellInfo(2139), GetSpellLink(2139), GetSpellInfo(1766), GetSpellLink(1766)),
		category = L["ICON"],
	})

	TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
		icon:SetInfo("spell", nil)
	end)
end






-- SPELLCHARGES: "charges, maxCharges"
do
	local Processor = TMW.Classes.IconDataProcessor:New("SPELLCHARGES", "charges, maxCharges")

	function Processor:CompileFunctionSegment(t)
		-- GLOBALS: charges, maxCharges
		t[#t+1] = [[
		
		if attributes.charges ~= charges or attributes.maxCharges ~= maxCharges then

			attributes.charges = charges
			attributes.maxCharges = maxCharges
			
			TMW:Fire(SPELLCHARGES.changedEvent, icon, charges, maxCharges)
			doFireIconUpdated = true
		end
		--]]
	end

	TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
		icon:SetInfo("charges, maxCharges", nil, nil)
	end)
end






-- VALUE: "value, maxValue, valueColor"
do
	local Processor = TMW.Classes.IconDataProcessor:New("VALUE", "value, maxValue, valueColor")

	function Processor:CompileFunctionSegment(t)
		-- GLOBALS: value, maxValue, valueColor
		t[#t+1] = [[
		
		if attributes.value ~= value or attributes.maxValue ~= maxValue or attributes.valueColor ~= valueColor then

			attributes.value = value
			attributes.maxValue = maxValue
			attributes.valueColor = valueColor
			
			TMW:Fire(VALUE.changedEvent, icon, value, maxValue, valueColor)
			doFireIconUpdated = true
		end
		--]]
	end

	TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
		icon:SetInfo("value, maxValue, valueColor", nil, nil, nil)
	end)
		
	Processor:RegisterDogTag("TMW", "Value", {
		code = function(icon)
			icon = TMW.GUIDToOwner[icon]
			
			local value = icon and icon.attributes.value or 0
			
			return isNumber[value] or value
		end,
		arg = {
			'icon', 'string', '@req',
		},
		events = TMW:CreateDogTagEventString("VALUE"),
		ret = "number",
		doc = L["DT_DOC_Value"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
		example = '[Value] => "256891"; [Value(icon="TMW:icon:1I7MnrXDCz8T")] => "2"',
		category = L["ICON"],
	})
		
	Processor:RegisterDogTag("TMW", "ValueMax", {
		code = function(icon)
			icon = TMW.GUIDToOwner[icon]
			
			local maxValue = icon and icon.attributes.maxValue or 0
			
			return isNumber[maxValue] or maxValue
		end,
		arg = {
			'icon', 'string', '@req',
		},
		events = TMW:CreateDogTagEventString("VALUE"),
		ret = "number",
		doc = L["DT_DOC_ValueMax"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
		example = '[ValueMax] => "312856"; [ValueMax(icon="TMW:icon:1I7MnrXDCz8T")] => "3"',
		category = L["ICON"],
	})
end






-- STACK: "stack, stackText"
do
	local Processor = TMW.Classes.IconDataProcessor:New("STACK", "stack, stackText")

	function Processor:CompileFunctionSegment(t)
		--GLOBALS: stack, stackText
		t[#t+1] = [[
		if attributes.stack ~= stack or attributes.stackText ~= stackText then
			attributes.stack = stack
			attributes.stackText = stackText

			if EventHandlersSet.OnStack then
				icon:QueueEvent("OnStack")
			end

			TMW:Fire(STACK.changedEvent, icon, stack, stackText)
			doFireIconUpdated = true
		end
		--]]
	end

	Processor:RegisterIconEvent(51, "OnStack", {
		category = L["EVENT_CATEGORY_CHANGED"],
		text = L["SOUND_EVENT_ONSTACK"],
		desc = L["SOUND_EVENT_ONSTACK_DESC"],
		settings = {
			Operator = true,
			Value = true,
			CndtJustPassed = true,
			PassingCndt = true,
		},
		valueName = L["STACKS"],
		conditionChecker = function(icon, eventSettings)
			local count = icon.attributes.stack or 0
			return TMW.CompareFuncs[eventSettings.Operator](count, eventSettings.Value)
		end,
	})
		
	Processor:RegisterDogTag("TMW", "Stacks", {
		code = function(icon)
			icon = TMW.GUIDToOwner[icon]
			
			local stacks = icon and icon.attributes.stackText or 0
			
			return isNumber[stacks] or stacks
		end,
		arg = {
			'icon', 'string', '@req',
		},
		events = TMW:CreateDogTagEventString("STACK"),
		ret = "number",
		doc = L["DT_DOC_Stacks"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
		example = '[Stacks] => "9"; [Stacks(icon="TMW:icon:1I7MnrXDCz8T")] => "3"',
		category = L["ICON"],
	})

	TMW:RegisterCallback("TMW_ICON_SETUP_POST", function(event, icon)
		if not TMW.Locked then
			icon:SetInfo("stack, stackText", nil, nil)
		end
	end)

	TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
		icon:SetInfo("stack, stackText", nil, nil)
	end)
end






-- TEXTURE: "texture"
do
	local Processor = TMW.Classes.IconDataProcessor:New("TEXTURE", "texture")

	function Processor:CompileFunctionSegment(t)
		-- GLOBALS: texture
		t[#t+1] = [[
		if texture ~= nil and attributes.texture ~= texture then
			attributes.texture = texture

			TMW:Fire(TEXTURE.changedEvent, icon, texture)
			doFireIconUpdated = true
		end
		--]]
	end
end






-- UNIT: "unit, GUID"
do
	local Processor = TMW.Classes.IconDataProcessor:New("UNIT", "unit, GUID")
	Processor:DeclareUpValue("UnitGUID", UnitGUID)
	Processor:DeclareUpValue("playerGUID", UnitGUID('player'))

	function Processor:CompileFunctionSegment(t)
		-- GLOBALS: unit, GUID
		t[#t+1] = [[
		
		GUID = GUID or (unit and (unit == "player" and playerGUID or UnitGUID(unit)))
		
		if attributes.unit ~= unit or attributes.GUID ~= GUID then
			local previousUnit = attributes.unit
			attributes.previousUnit = previousUnit
			attributes.unit = unit
			attributes.GUID = GUID

			if EventHandlersSet.OnUnit then
				icon:QueueEvent("OnUnit")
			end
			
			TMW:Fire(UNIT.changedEvent, icon, unit, previousUnit, GUID)
			doFireIconUpdated = true
		end
		--]]
	end

	Processor:RegisterIconEvent(41, "OnUnit", {
		category = L["EVENT_CATEGORY_CHANGED"],
		text = L["SOUND_EVENT_ONUNIT"],
		desc = L["SOUND_EVENT_ONUNIT_DESC"],
	})

	Processor:RegisterDogTag("TMW", "Unit", {
		code = function(icon)
			icon = TMW.GUIDToOwner[icon]
			
			if icon then
				return icon.attributes.unit or ""
			else
				return ""
			end
		end,
		arg = {
			'icon', 'string', '@req',
		},
		events = TMW:CreateDogTagEventString("UNIT"),
		ret = "string",
		doc = L["DT_DOC_Unit"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
		example = '[Unit] => "target"; [Unit:Name] => "Kobold"; [Unit(icon="TMW:icon:1I7MnrXDCz8T")] => "focus"; [Unit(icon="TMW:icon:1I7MnrXDCz8T"):Name] => "Gamon"',
		category = L["ICON"],
	})
	Processor:RegisterDogTag("TMW", "PreviousUnit", {
		code = function(icon)
			icon = TMW.GUIDToOwner[icon]
			
			if icon then
				return icon.__lastUnitChecked or ""
			else
				return ""
			end
		end,
		arg = {
			'icon', 'string', '@req',
		},
		events = TMW:CreateDogTagEventString("UNIT"),
		ret = "string",
		doc = L["DT_DOC_PreviousUnit"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
		example = '[PreviousUnit] => "target"; [PreviousUnit:Name] => "Kobold"; [PreviousUnit(icon="TMW:icon:1I7MnrXDCz8T")] => "focus"; [PreviousUnit(icon="TMW:icon:1I7MnrXDCz8T"):Name] => "Gamon"',
		category = L["ICON"],
	})

	TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
		icon:SetInfo("unit, GUID", nil, nil)
	end)
end






-- DOGTAGUNIT: "dogTagUnit"
do
	local DogTag = LibStub("LibDogTag-3.0")

		
	local Processor = TMW.Classes.IconDataProcessor:New("DOGTAGUNIT", "dogTagUnit")
	Processor:AssertDependency("UNIT")


	--Here's the hook (the whole point of this thing)

	local Hook = TMW.Classes.IconDataProcessorHook:New("UNIT_DOGTAGUNIT", "UNIT")

	Hook:DeclareUpValue("DogTag", DogTag)
	Hook:DeclareUpValue("TMW_UNITS", TMW.UNITS)

	Hook:RegisterCompileFunctionSegmentHook("post", function(Processor, t)
		-- GLOBALS: unit
		t[#t+1] = [[
		local dogTagUnit
		local typeData = icon.typeData
		
		if not typeData or typeData.unitType == "unitid" then
			dogTagUnit = unit
			if not DogTag.IsLegitimateUnit[dogTagUnit] then
				dogTagUnit = dogTagUnit and TMW_UNITS:TestUnit(dogTagUnit)
				if not DogTag.IsLegitimateUnit[dogTagUnit] then
					dogTagUnit = "player"
				end
			end
		else
			dogTagUnit = "player"
		end
		
		if attributes.dogTagUnit ~= dogTagUnit then
			doFireIconUpdated = icon:SetInfo_INTERNAL("dogTagUnit", dogTagUnit) or doFireIconUpdated
		end
		--]]
	end)
end


