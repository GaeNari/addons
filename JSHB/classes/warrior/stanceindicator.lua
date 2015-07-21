--
-- JSHB - stance indicator module
--

if (select(2, UnitClass("player")) ~= "WARRIOR") then return end

-- Cache
local UnitHasVehicleUI = UnitHasVehicleUI

function JSHB.SetupAspectModule()

	-- Deconstruction
	if JSHB.F.StanceIndicator then
		JSHB.DeregisterMovableFrame("MOVER_INDICATORS_STANCE")
		JSHB.F.StanceIndicator:Hide()
		JSHB.F.StanceIndicator:SetScript("OnUpdate", nil)
		JSHB.F.StanceIndicator:UnregisterAllEvents()
		JSHB.F.StanceIndicator:SetParent(nil)
	end
	
	-- Construction
	if (UnitLevel("player") < 24) then return end -- Level 24 is when Hunters first get an aspect in 6.0
	local INDICATORS_UPDATEINTERVAL = 0.125
	
	if JSHB.db.profile.indicators.stance_enable then
		
		-- Create the Frame
		JSHB.F.StanceIndicator = JSHB.MakeFrame(JSHB.F.StanceIndicator, "Frame", "JSHB_INDICATORS_STANCE", JSHB.db.profile.indicators.anchor_stance[2] or UIParent)
		JSHB.F.StanceIndicator:SetParent(JSHB.db.profile.indicators.anchor_stance[2] or UIParent)
		JSHB.F.StanceIndicator:ClearAllPoints()
		JSHB.F.StanceIndicator:SetSize(JSHB.db.profile.indicators.stance_iconsize, JSHB.db.profile.indicators.stance_iconsize)
		JSHB.F.StanceIndicator:SetPoint(JSHB.GetActiveAnchor(JSHB.db.profile.indicators.anchor_stance))
		JSHB.F.StanceIndicator.Icon = JSHB.F.StanceIndicator.Icon or JSHB.F.StanceIndicator:CreateTexture(nil, "BACKGROUND")
		JSHB.F.StanceIndicator.Icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		
		if JSHB.db.profile.indicators.stance_enabletexcoords then
			JSHB.F.StanceIndicator.Icon:SetTexCoord(unpack(JSHB.db.profile.indicators.stance_texcoords))
		else
			JSHB.F.StanceIndicator.Icon:SetTexCoord(0, 1, 0, 1)
		end
		
		JSHB.F.StanceIndicator.Icon:ClearAllPoints()
		JSHB.F.StanceIndicator.Icon:SetAllPoints(JSHB.F.StanceIndicator)
		JSHB.F.StanceIndicator.shine = JSHB.F.StanceIndicator.shine or CreateFrame("Frame", "AutocastShine_STANCE", UIParent, "AutoCastShineTemplate")
		JSHB.F.StanceIndicator.shine:ClearAllPoints()
		JSHB.F.StanceIndicator.shine:SetSize(JSHB.db.profile.indicators.stance_iconsize+2, JSHB.db.profile.indicators.stance_iconsize+2)
		JSHB.F.StanceIndicator.shine:SetPoint("CENTER", JSHB.F.StanceIndicator, "CENTER", 1, -1)
		JSHB.F.StanceIndicator.shine:SetAlpha(1)
		JSHB.F.StanceIndicator.shine:Show()
		-- Create the Background and border if the user wants one
		JSHB.F.StanceIndicator.background = JSHB.MakeBackground(JSHB.F.StanceIndicator, JSHB.db.profile.indicators, "stance_", nil, JSHB.F.StanceIndicator.background)
		JSHB.F.StanceIndicator:SetAlpha(1)
		JSHB.F.StanceIndicator:Show()
		
		JSHB.RegisterMovableFrame(
			"MOVER_INDICATORS_STANCE",
			JSHB.F.StanceIndicator,
			JSHB.F.StanceIndicator,
			JSHB.L["Stance Indicator"],
			JSHB.db.profile.indicators,
			JSHB.SetupStanceIndicatorModule,
			JSHB.defaults.profile.indicators,
			JSHB.db.profile.indicators,
			"_stance",
			"stance_"
		)

		-- DIRK Change this to stances for Warriors
		local function DoStanceUpdate(self)
			local thisIcon, hasStance
			-- Set the proper texture for the current aspect
			thisIcon = select(3, UnitAura("player", GetSpellInfo(5118), nil, "PLAYER|HELPFUL")) -- Aspect of the Cheetah
			if not (thisIcon) then
				thisIcon = select(3, UnitAura("player", GetSpellInfo(13159), nil, "PLAYER|HELPFUL")) -- Aspect of the Pack
				if not (thisIcon) then
					thisIcon = select(3, UnitAura("player", GetSpellInfo(172106), nil, "PLAYER|HELPFUL")) -- Aspect of the Fox
					if not (thisIcon) then
						thisIcon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up" -- no active aspect
						hasStance = false
					else
						self.Icon:SetTexture(thisIcon)
						hasStance = true
					end
				else
					self.Icon:SetTexture(thisIcon)
					hasStance = true
				end
			else
				self.Icon:SetTexture(thisIcon)
				hasStance = true
			end
			
			if InCombatLockdown() then
				if (hasStance == true) and (not UnitHasVehicleUI("player")) and (not C_PetBattles.IsInBattle()) then
					JSHB.F.StanceIndicator:SetAlpha((JSHB.db.profile.indicators.stance_matchbaralpha and JSHB.db.profile.resourcebar.enabled) and JSHB.F.ResourceBar:GetAlpha() or 1)
					AutoCastShine_AutoCastStart(JSHB.F.StanceIndicator.shine, 1, 0.5, 0.5)					
				else
					JSHB.F.StanceIndicator:SetAlpha(0)
					AutoCastShine_AutoCastStop(JSHB.F.StanceIndicator.shine)
				end
			else -- OOC
				if(hasStance == true) and (not JSHB.db.profile.indicators.stance_onlycombat) and (not UnitHasVehicleUI("player")) and (not C_PetBattles.IsInBattle()) then
					JSHB.F.StanceIndicator:SetAlpha( (JSHB.db.profile.indicators.stance_matchbaralpha and JSHB.db.profile.resourcebar.enabled) and JSHB.F.ResourceBar:GetAlpha() or 1)
					AutoCastShine_AutoCastStop(JSHB.F.StanceIndicator.shine)
				else
					JSHB.F.StanceIndicator:SetAlpha(0)
					AutoCastShine_AutoCastStop(JSHB.F.StanceIndicator.shine)
				end			
			end
			
		end
		
		JSHB.F.StanceIndicator.updateTimer = 0
		JSHB.F.StanceIndicator:SetScript("OnUpdate",
			function(self, elapsed, ...)	
				self.updateTimer = self.updateTimer + elapsed	
				if self.updateTimer < INDICATORS_UPDATEINTERVAL then return else self.updateTimer = 0 end
				if (not JSHB.moversLocked) then return end
				DoStanceUpdate(self)
			end)
	end
end