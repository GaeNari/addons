local _G = _G
local IRF3, noOption = ...
local pairs = _G.pairs
local ipairs = _G.ipairs
local unpack = _G.unpack
local select = _G.select
local tinsert = _G.table.insert
local max = _G.math.max
local min = _G.math.min
local UnitExists = _G.UnitExists
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnitAlternatePowerInfo = _G.UnitAlternatePowerInfo
local UnitInRange = _G.UnitInRange
local UnitIsGhost = _G.UnitIsGhost
local UnitIsDead = _G.UnitIsDead
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsAFK = _G.UnitIsAFK
local UnitIsUnit = _G.UnitIsUnit
local UnitCanAttack = _G.UnitCanAttack
local UnitIsConnected = _G.UnitIsConnected
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitGetIncomingHeals = _G.UnitGetIncomingHeals
local UnitGetTotalAbsorbs = _G.UnitGetTotalAbsorbs
local UnitIsPlayer = _G.UnitIsPlayer
local UnitInParty = _G.UnitInParty
local UnitInRaid = _G.UnitInRaid
local UnitClass = _G.UnitClass
local UnitDistanceSquared = _G.UnitDistanceSquared
local UnitInOtherParty = _G.UnitInOtherParty
local UnitHasIncomingResurrection = _G.UnitHasIncomingResurrection
local UnitInPhase = _G.UnitInPhase
local GetRaidRosterInfo = _G.GetRaidRosterInfo
local InCombatLockdown = _G.InCombatLockdown
local GetTime = _G.GetTime
local SM = LibStub("LibSharedMedia-3.0")
local LEDDM = LibStub("LibEnhanceDDMenu-1.0")
local eventHandler = {}
IRF3 = _G[IRF3]
IRF3.visibleMembers = {}

function IRF3:SetupAll(update)
	for _, header in pairs(self.headers) do
		for _, member in pairs(header.members) do
			member:Setup()
		end
	end
	for _, member in pairs(self.petHeader.members) do
		member:Setup()
	end
end

local statusBarTexture = "Interface\\RaidFrame\\Raid-Bar-Resource-Fill"

local function setupMemberTexture(self)
	statusBarTexture = SM:Fetch("statusbar", IRF3.db.units.texture)
	self.powerBar:SetStatusBarTexture(statusBarTexture, "OVERLAY", -1)
	self.healthBar:SetStatusBarTexture(statusBarTexture, "OVERLAY", -1)
	self.myHealPredictionBar:SetStatusBarTexture(statusBarTexture, "OVERLAY", -2)
	self.myHealPredictionBar:SetStatusBarColor(IRF3.db.units.myHealPredictionColor[1], IRF3.db.units.myHealPredictionColor[2], IRF3.db.units.myHealPredictionColor[3], IRF3.db.units.healPredictionAlpha)
	self.otherHealPredictionBar:SetStatusBarTexture(statusBarTexture, "OVERLAY", -3)
	self.otherHealPredictionBar:SetStatusBarColor(IRF3.db.units.otherHealPredictionColor[1], IRF3.db.units.otherHealPredictionColor[2], IRF3.db.units.otherHealPredictionColor[3], IRF3.db.units.healPredictionAlpha)
	self.absorbPredictionBar:SetStatusBarTexture(statusBarTexture, "OVERLAY", -4)
	self.absorbPredictionBar:SetStatusBarColor(IRF3.db.units.AbsorbPredictionColor[1], IRF3.db.units.AbsorbPredictionColor[2], IRF3.db.units.AbsorbPredictionColor[3], IRF3.db.units.healPredictionAlpha)
	self.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
	self.overAbsorbGlow:SetDrawLayer("OVERLAY", 2)
	self.overAbsorbGlow:SetBlendMode("ADD")
	self.overAbsorbGlow:ClearAllPoints()
	self.overAbsorbGlow:SetPoint("BOTTOMRIGHT", self.healthBar, "BOTTOMRIGHT", 7, 0)
	self.overAbsorbGlow:SetPoint("TOPRIGHT", self.healthBar, "TOPRIGHT", 7, 0)
	self.overAbsorbGlow:SetWidth(16)
	self.overAbsorbGlow:SetAlpha(0.4)
	if self.castingBar then
		self.castingBar:SetStatusBarTexture(statusBarTexture, "OVERLAY", 4)
		self.castingBar:SetStatusBarColor(IRF3.db.units.castingBarColor[1], IRF3.db.units.castingBarColor[2], IRF3.db.units.castingBarColor[3])
	end
	if self.powerBarAlt then
		self.powerBarAlt:SetStatusBarTexture(statusBarTexture, "OVERLAY", 1)
		self.powerBarAlt:SetStatusBarColor(self.powerBarAlt.r or 1, self.powerBarAlt.g or 1, self.powerBarAlt.b or 1)
	end
	if self.resurrectionBar then
		self.resurrectionBar:SetStatusBarTexture(statusBarTexture, "OVERLAY", 5)
		self.resurrectionBar:SetStatusBarColor(IRF3.db.units.resurrectionBarColor[1], IRF3.db.units.resurrectionBarColor[2], IRF3.db.units.resurrectionBarColor[3])
	end
	if self.bossAura then
		self.bossAura:SetAlpha(IRF3.db.units.bossAuraAlpha)
	end
	if self.centerStatusIcon then
		self.centerStatusIcon:ClearAllPoints()
		self.centerStatusIcon:SetPoint("CENTER", self, "BOTTOM", 0, IRF3.db.height / 3 + 2)
		self.centerStatusIcon:SetSize(18, 18)
	end
	if self.petButton then
		setupMemberTexture(self.petButton)
	end
end

local function setHorizontal(bar)
	bar:SetOrientation("HORIZONTAL")
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", bar:GetParent(), "TOPLEFT", 0, 0)
	bar:GetParent().orientation = 1
end

local function setVertical(bar, parent)
	bar:SetOrientation("VERTICAL")
	bar:ClearAllPoints()
	bar:SetPoint("BOTTOMLEFT", bar:GetParent(), "BOTTOMLEFT", 0, 0)
	bar:GetParent().orientation = 2
end

local function setupMemberBarOrientation(self)
	if IRF3.db.units.orientation == 1 then
		self.healthBar:SetOrientation("HORIZONTAL")
		setHorizontal(self.myHealPredictionBar)
		setHorizontal(self.otherHealPredictionBar)
		setHorizontal(self.absorbPredictionBar)
	else
		self.healthBar:SetOrientation("VERTICAL")
		setVertical(self.myHealPredictionBar)
		setVertical(self.otherHealPredictionBar)
		setVertical(self.absorbPredictionBar)
	end
end

local function setupMemberPowerBar(self)
	self.healthBar:ClearAllPoints()
	self.powerBar:ClearAllPoints()
	if IRF3.db.units.nameEndl then
		self.name:SetPoint("CENTER", self.healthBar, 0, 5)
		self.losttext:SetPoint("TOP", self.name, "BOTTOM", 0, -2)
	else
		self.name:SetPoint("CENTER", self.healthBar, 0, 0)
		self.losttext:SetPoint("TOP", self.name, "BOTTOM", 0, -2)--no use
	end
	if IRF3.db.units.powerBarPos == 1 or IRF3.db.units.powerBarPos == 2 then
		self.powerBar:SetWidth(0)
		self.powerBar:SetOrientation("HORIZONTAL")
		if IRF3.db.units.powerBarHeight > 0 then
			self.powerBar:SetHeight(IRF3.db.height * IRF3.db.units.powerBarHeight)
		else
			self.powerBar:SetHeight(0.001)
		end
		if IRF3.db.units.powerBarPos == 1 then
			self.healthBar:SetPoint("TOPLEFT", self.powerBar, "BOTTOMLEFT", 0, 0)
			self.healthBar:SetPoint("BOTTOMRIGHT", 0, 0)
			self.powerBar:SetPoint("TOPLEFT", 0, 0)
			self.powerBar:SetPoint("TOPRIGHT", 0, 0)
		else
			self.healthBar:SetPoint("TOPLEFT", 0, 0)
			self.healthBar:SetPoint("BOTTOMRIGHT", self.powerBar, "TOPRIGHT", 0, 0)
			self.powerBar:SetPoint("BOTTOMLEFT", 0, 0)
			self.powerBar:SetPoint("BOTTOMRIGHT", 0, 0)
		end
	else
		self.powerBar:SetHeight(0)
		self.powerBar:SetOrientation("VERTICAL")
		if IRF3.db.units.powerBarHeight > 0 then
			self.powerBar:SetWidth(IRF3.db.width * IRF3.db.units.powerBarHeight)
		else
			self.powerBar:SetWidth(0.001)
		end
		if IRF3.db.units.powerBarPos == 3 then
			self.healthBar:SetPoint("TOPLEFT", self.powerBar, "TOPRIGHT", 0, 0)
			self.healthBar:SetPoint("BOTTOMRIGHT", 0, 0)
			self.powerBar:SetPoint("TOPLEFT", 0, 0)
			self.powerBar:SetPoint("BOTTOMLEFT", 0, 0)
		else
			self.healthBar:SetPoint("TOPLEFT", 0, 0)
			self.healthBar:SetPoint("BOTTOMRIGHT", self.powerBar, "BOTTOMLEFT", 0, 0)
			self.powerBar:SetPoint("TOPRIGHT", 0, 0)
			self.powerBar:SetPoint("BOTTOMRIGHT", 0, 0)
		end
	end
end

local function checkMouseOver(self)
	if not UnitIsUnit(self:GetParent().displayedUnit, "mouseover") then
		self:Hide()
	end
end

local function setupMemberOutline(self)
	self.outline:SetScript("OnUpdate", nil)
	self.outline:SetScale(self.optionTable.outline.scale)
	self.outline:SetAlpha(self.optionTable.outline.alpha)
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	if self.optionTable.outline.type == 2 then
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self.outline:SetBackdropBorderColor(self.optionTable.outline.targetColor[1], self.optionTable.outline.targetColor[2], self.optionTable.outline.targetColor[3])
	elseif self.optionTable.outline.type == 3 then
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		self.outline:SetBackdropBorderColor(self.optionTable.outline.mouseoverColor[1], self.optionTable.outline.mouseoverColor[2], self.optionTable.outline.mouseoverColor[3])
		self.outline:SetScript("OnUpdate", checkMouseOver)
	elseif self.optionTable.outline.type == 4 then
		self.outline:SetBackdropBorderColor(self.optionTable.outline.lowHealthColor[1], self.optionTable.outline.lowHealthColor[2], self.optionTable.outline.lowHealthColor[3])
	elseif self.optionTable.outline.type == 5 then
		self.outline:SetBackdropBorderColor(self.optionTable.outline.aggroColor[1], self.optionTable.outline.aggroColor[2], self.optionTable.outline.aggroColor[3])
	elseif self.optionTable.outline.type == 6 then
		self.outline:SetBackdropBorderColor(self.optionTable.outline.raidIconColor[1], self.optionTable.outline.raidIconColor[2], self.optionTable.outline.raidIconColor[3])
	elseif self.optionTable.outline.type == 7 then
		self.outline:SetBackdropBorderColor(self.optionTable.outline.lowHealthColor2[1], self.optionTable.outline.lowHealthColor2[2], self.optionTable.outline.lowHealthColor2[3])
	else
		self.outline:Hide()
	end
	if self.petButton then
		setupMemberOutline(self.petButton)
	end
end

local function setupMemberDebuffIcon(self)
	if self.optionTable.debuffIconType == 1 then
		for i = 1, 5 do
			self["debuffIcon"..i].color:ClearAllPoints()
			self["debuffIcon"..i].color:SetAllPoints()
			self["debuffIcon"..i].color:Show()
			self["debuffIcon"..i].icon:ClearAllPoints()
			self["debuffIcon"..i].icon:SetPoint("TOPLEFT", 1, -1)
			self["debuffIcon"..i].icon:SetPoint("BOTTOMRIGHT", -1, 1)
			self["debuffIcon"..i].icon:Show()
		end
	elseif self.optionTable.debuffIconType == 2 then
		for i = 1, 5 do
			self["debuffIcon"..i].color:Hide()
			self["debuffIcon"..i].icon:ClearAllPoints()
			self["debuffIcon"..i].icon:SetPoint("TOPLEFT", 1, -1)
			self["debuffIcon"..i].icon:SetPoint("BOTTOMRIGHT", -1, 1)
			self["debuffIcon"..i].icon:Show()
		end
	else
		for i = 1, 5 do
			self["debuffIcon"..i].color:ClearAllPoints()
			self["debuffIcon"..i].color:SetPoint("TOPLEFT", 1, -1)
			self["debuffIcon"..i].color:SetPoint("BOTTOMRIGHT", -1, 1)
			self["debuffIcon"..i].color:Show()
			self["debuffIcon"..i].icon:Hide()
		end
	end
end

local function setupMemberAll(self)
	InvenRaidFrames3Member_SetOptionTable(self, IRF3.db.units)
	self.background:SetTexture(IRF3.db.units.backgroundColor[1], IRF3.db.units.backgroundColor[2], IRF3.db.units.backgroundColor[3], IRF3.db.units.backgroundColor[4])
	if self.petButton then
		InvenRaidFrames3Member_SetOptionTable(self.petButton, IRF3.db.units)
		self.petButton.background:SetTexture(IRF3.db.units.backgroundColor[1], IRF3.db.units.backgroundColor[2], IRF3.db.units.backgroundColor[3], IRF3.db.units.backgroundColor[4])
	end
	setupMemberTexture(self)
	setupMemberPowerBar(self)
	setupMemberBarOrientation(self)
	setupMemberOutline(self)
	setupMemberDebuffIcon(self)
	InvenRaidFrames3Member_SetupPowerBarAltPos(self)
	InvenRaidFrames3Member_SetupCastingBarPos(self)
	InvenRaidFrames3Member_SetupIconPos(self)
	InvenRaidFrames3Member_SetAuraFont(self)
	self.name:SetFont(SM:Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
	self.name:SetShadowColor(0, 0, 0)
	if IRF3.db.font.shadow then
		self.name:SetShadowOffset(1, -1)
	else
		self.name:SetShadowOffset(0, 0)
	end
	self.losttext:SetFont(SM:Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
	self.losttext:SetShadowColor(0, 0, 0)
	if IRF3.db.font.shadow then
		self.losttext:SetShadowOffset(1, -1)
	else
		self.losttext:SetShadowOffset(0, 0)
	end
	InvenRaidFrames3Member_UpdateAll(self)
end

local function updateHealPredictionBarSize(self)
	self = self:GetParent()
	self.myHealPredictionBar:SetWidth(self.healthBar:GetWidth())
	self.myHealPredictionBar:SetHeight(self.healthBar:GetHeight())
	self.otherHealPredictionBar:SetWidth(self.healthBar:GetWidth())
	self.otherHealPredictionBar:SetHeight(self.healthBar:GetHeight())
	self.absorbPredictionBar:SetWidth(self.healthBar:GetWidth())
	self.absorbPredictionBar:SetHeight(self.healthBar:GetHeight())
end

local function getUnitPetOrOwner(unit)
	if unit then
		if unit == "player" then
			return "pet"
		elseif unit == "vehicle" or unit == "pet" then
			return "player"
		elseif unit:find("pet") then
			return (unit:gsub("pet", ""))
		else
			return (unit:gsub("(%d+)", "pet%1"))
		end
	end
	return nil
end

local function baseOnAttributeChanged(self, key, value)
	if key == "unit" then
		if value then
			key = getUnitPetOrOwner(value)
			self:RegisterUnitEvent("UNIT_NAME_UPDATE", value, key)
			self:RegisterUnitEvent("UNIT_CONNECTION", value, key)
			self:RegisterUnitEvent("UNIT_HEALTH", value, key)
			self:RegisterUnitEvent("UNIT_MAXHEALTH", value, key)
			self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", value, key)
			self:RegisterUnitEvent("UNIT_HEAL_PREDICTION", value, key)
			self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", value, key)
			self:RegisterUnitEvent("UNIT_POWER", value, key)
			self:RegisterUnitEvent("UNIT_MAXPOWER", value, key)
			self:RegisterUnitEvent("UNIT_DISPLAYPOWER", value, key)
			self:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", value, key)
			self:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", value, key)
			self:RegisterUnitEvent("UNIT_AURA", value, key)
		else
			self:UnregisterEvent("UNIT_NAME_UPDATE")
			self:UnregisterEvent("UNIT_CONNECTION")
			self:UnregisterEvent("UNIT_HEALTH")
			self:UnregisterEvent("UNIT_MAXHEALTH")
			self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
			self:UnregisterEvent("UNIT_HEAL_PREDICTION")
			self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
			self:UnregisterEvent("UNIT_POWER")
			self:UnregisterEvent("UNIT_MAXPOWER")
			self:UnregisterEvent("UNIT_DISPLAYPOWER")
			self:UnregisterEvent("UNIT_POWER_BAR_SHOW")
			self:UnregisterEvent("UNIT_POWER_BAR_HIDE")
			self:UnregisterEvent("UNIT_AURA")
		end
	end
end

function InvenRaidFrames3Member_SetOptionTable(self, optionTable)
	self.optionTable = optionTable
end

function InvenRaidFrames3Base_OnLoad(self)
	self:RegisterForClicks("AnyUp")
	self:RegisterForDrag("LeftButton", "RightButton")
	self.timer, self.health, self.maxHealth, self.lostHealth, self.overAbsorb = 0, 0, 1, 0, 0
	InvenRaidFrames3Member_SetOptionTable(self, noOption)
	self.healthBar:SetScript("OnSizeChanged", updateHealPredictionBarSize)
	if not self.petButton then
		setHorizontal(self.myHealPredictionBar)
		setHorizontal(self.otherHealPredictionBar)
		setHorizontal(self.absorbPredictionBar)
	end
	self:SetFrameStrata("MEDIUM")
	self:SetFrameLevel(self:GetParent():GetFrameLevel())
	self:HookScript("OnAttributeChanged", baseOnAttributeChanged)
	RegisterUnitWatch(self)
end

local function isPetGroup(self)
	return self:GetParent() == IRF3.petHeader
end

local function memberOnAttributeChanged(self, key, value)
	if key == "unit" then
		if value then
			key = getUnitPetOrOwner(value)
			self:RegisterUnitEvent("READY_CHECK_CONFIRM", value, key)
			self:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", value, key)
			self:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", value, key)
			self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", value, key)
			self:RegisterUnitEvent("UNIT_PET", value, key)
			self:RegisterUnitEvent("UNIT_SPELLCAST_START", value, key)
			self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", value, key)
			self:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", value, key)
			self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", value, key)
			self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", value, key)
			self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", value, key)
			self:RegisterUnitEvent("UNIT_FLAGS", value, key)
		else
			self:UnregisterEvent("READY_CHECK_CONFIRM")
			self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE")
			self:UnregisterEvent("UNIT_ENTERED_VEHICLE")
			self:UnregisterEvent("UNIT_EXITED_VEHICLE")
			self:UnregisterEvent("UNIT_PET")
			self:UnregisterEvent("UNIT_SPELLCAST_START")
			self:UnregisterEvent("UNIT_SPELLCAST_STOP")
			self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
			self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
			self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
			self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
			self:UnregisterEvent("UNIT_FLAGS")
		end
	end
end

function InvenRaidFrames3Member_OnLoad(self)
	InvenRaidFrames3Base_OnLoad(self)
	self.UpdateAll = InvenRaidFrames3Member_UpdateAll
	self.Setup = setupMemberAll
	self.SetupTexture = setupMemberTexture
	self.SetupPowerBar = setupMemberPowerBar
	self.SetupBarOrientation = setupMemberBarOrientation
	self.SetupPowerBarAltPos = InvenRaidFrames3Member_SetupPowerBarAltPos
	self.SetupCastingBarPos = InvenRaidFrames3Member_SetupCastingBarPos
	self.SetupIconPos = InvenRaidFrames3Member_SetupIconPos
	self.SetupOutline = setupMemberOutline
	self.SetupDebuffIcon = setupMemberDebuffIcon
	self:SetID(tonumber(self:GetName():match("UnitButton(%d+)$")))
	self:GetParent().members[self:GetID()] = self
	tinsert(UnitPopupFrames, self.dropDown:GetName())
	CompactUnitFrame_SetMenuFunc(self, CompactUnitFrameDropDown_Initialize)
	self.nameTable = {}
	self.name:SetDrawLayer("OVERLAY", 2)
	self.name:Show()
	self.losttext:SetDrawLayer("OVERLAY", 2)
	self.losttext:Show()
	self.readyCheckIcon:SetParent(self.topLevel)
	self.readyCheckIcon:SetDrawLayer("OVERLAY", 6)
	self.readyCheckIcon:ClearAllPoints()
	self.readyCheckIcon:SetPoint("CENTER", 0, 0)
	self.readyCheckIcon:SetSize(24, 24)
	self.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
	self.roleIcon:SetSize(0.001, 0.001)
	self.roleIcon:SetDrawLayer("OVERLAY", 1)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	self:RegisterEvent("RAID_TARGET_UPDATE")
	self:RegisterEvent("INCOMING_RESURRECT_CHANGED")
	self:RegisterEvent("UNIT_OTHER_PARTY_CHANGED")
	self:RegisterEvent("UNIT_PHASE")
	if self:GetParent().index == 0 and self:GetID() == 1 then
		self:RegisterEvent("PLAYER_FLAGS_CHANGED")
	else
		self:RegisterEvent("GROUP_ROSTER_UPDATE")
	end

	self:HookScript("OnAttributeChanged", memberOnAttributeChanged)
end

function InvenRaidFrames3Member_OnShow(self)
	if IRF3.db then
		self:SetScript("OnEvent", InvenRaidFrames3Member_OnEvent)
		if not self.ticker then
			self.ticker = C_Timer.NewTicker(0.15, function() InvenRaidFrames3Member_OnUpdate(self) end)
		end
		self:GetParent().visible = self:GetParent().visible + 1
		InvenRaidFrames3Member_UpdateAll(self)
		if isPetGroup(self) then
			self:GetParent().border:SetAlpha(1)
		else
			IRF3:BorderUpdate()
		end
	end
	IRF3.visibleMembers[self] = true
end

function InvenRaidFrames3Member_OnHide(self)
	if IRF3.db then
		self:SetScript("OnEvent", nil)
		if self.ticker then
			self.ticker:Cancel()
			self.ticker = nil
		end
		self:GetParent().visible = self:GetParent().visible - 1
		InvenRaidFrames3Member_OnDragStop(self)
		if isPetGroup(self) then
			self:GetParent().border:SetAlpha(self:GetParent().visible > 0 and 1 or 0)
		else
			IRF3:BorderUpdate()
		end
		table.wipe(self.nameTable)
		self.lostHealth, self.overAbsorb, self.hasAggro, self.isOffline, self.isAFK, self.color, self.class = 0, 0, nil, nil, nil, nil
		self.unit, self.displayedUnit = nil, nil
	end
	IRF3.visibleMembers[self] = nil
	IRF3:CallbackClearObject(self)
end

function InvenRaidFrames3Member_OnEnter(self)
	IRF3.onEnter = self
	self.highlight:SetAlpha(IRF3.db.highlightAlpha)
	self.highlight:Show()
	if self.displayedUnit and IRF3.tootipState then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:SetUnit(self.displayedUnit)
		GameTooltipTextLeft1:SetTextColor(GameTooltip_UnitColor(self.displayedUnit))
	else
		GameTooltip:Hide()
	end
end

function InvenRaidFrames3Member_OnLeave(self)
	IRF3.onEnter = nil
	self.highlight:Hide()
	GameTooltip:Hide()
end

function InvenRaidFrames3Member_OnDragStart(self)
	if not IRF3.db.lock then
		IRF3.dragging = self
		if isPetGroup(self) or self:GetParent() == InvenRaidFrames3PreviewPet then
			IRF3.petHeader:StartMoving()
		else
			IRF3:StartMoving()
		end
	end
end

function InvenRaidFrames3Member_OnDragStop(self)
	if IRF3.dragging or not IsMouseButtonDown() then
		IRF3.dragging = nil
		IRF3:SetUserPlaced(nil)
		IRF3:StopMovingOrSizing()
		IRF3.petHeader:SetUserPlaced(nil)
		IRF3.petHeader:StopMovingOrSizing()
		IRF3:SavePosition()
	end
end

function InvenRaidFrames3Member_UpdateHealth(self)
	local health = UnitHealth(self.displayedUnit)
	local maxhealth = UnitHealthMax(self.displayedUnit)
	self.healthBar:SetValue(health)
	self.health = health
	self.maxHealth = maxhealth
	self.lostHealth = maxhealth - health
	self.healthBar:SetMinMaxValues(0, maxhealth)
	self.myHealPredictionBar:SetMinMaxValues(0, maxhealth)
	self.otherHealPredictionBar:SetMinMaxValues(0, maxhealth)
	self.absorbPredictionBar:SetMinMaxValues(0, maxhealth)
end

local function InvenRaidFrames3Member_GetDisplayedPowerID(self)
	local barType, minPower, startInset, endInset, smooth, hideFromOthers, showOnRaid, opaqueSpark, opaqueFlash, powerName, powerTooltip = UnitAlternatePowerInfo(self.displayedUnit)
	if ( showOnRaid and (UnitInParty(self.unit) or UnitInRaid(self.unit)) ) then
		return ALTERNATE_POWER_INDEX
	else
		return (UnitPowerType(self.displayedUnit))
	end
end

function InvenRaidFrames3Member_UpdateMaxPower(self)
	self.powerBar:SetMinMaxValues(0, UnitPowerMax(self.displayedUnit, InvenRaidFrames3Member_GetDisplayedPowerID(self)))
end

function InvenRaidFrames3Member_UpdatePower(self)
	self.powerBar:SetValue(UnitPower(self.displayedUnit, InvenRaidFrames3Member_GetDisplayedPowerID(self)))
end

function InvenRaidFrames3Member_UpdateHealPrediction(self)
	if self.optionTable.displayHealPrediction and not UnitIsDeadOrGhost(self.displayedUnit) then
		local myIncomingHeal = UnitGetIncomingHeals(self.displayedUnit, "player") or 0
		local allIncomingHeal = UnitGetIncomingHeals(self.displayedUnit) or 0
		local otherIncomingHeal = allIncomingHeal - myIncomingHeal
		local totalAbsorb = UnitGetTotalAbsorbs(self.displayedUnit) or 0
		local totalPrediction = allIncomingHeal + totalAbsorb
		local health = self.health
		local maxhealth = self.maxHealth
		local lost = self.lostHealth
		if self.healIcon then
			if self.optionTable.healIcon and myIncomingHeal > 0 then
				self.healIcon:SetVertexColor(self.optionTable.myHealPredictionColor[1], self.optionTable.myHealPredictionColor[2], self.optionTable.myHealPredictionColor[3])
				self.healIcon:SetSize(self.optionTable.healIconSize, self.optionTable.healIconSize)
				self.healIcon:Show()
			elseif self.optionTable.healIconOther and otherIncomingHeal > 0 then
				self.healIcon:SetVertexColor(self.optionTable.otherHealPredictionColor[1], self.optionTable.otherHealPredictionColor[2], self.optionTable.otherHealPredictionColor[3])
				self.healIcon:SetSize(self.optionTable.healIconSize, self.optionTable.healIconSize)
				self.healIcon:Show()
			elseif self.healIcon and self.healIcon:IsShown() then
				self.healIcon:SetSize(0.001, 0.001)
				self.healIcon:Hide()
			end
		end
		if lost > 0 then
			if myIncomingHeal > 0 then
				local value = min(maxhealth, health + myIncomingHeal)
				self.myHealPredictionBar:SetValue(value)
				self.myHealPredictionBar:Show()
			else
				self.myHealPredictionBar:Hide()
			end
			if otherIncomingHeal > 0 then
				local value = min(maxhealth, health + allIncomingHeal)
				self.otherHealPredictionBar:SetValue(value)
				self.otherHealPredictionBar:Show()
			else
				self.otherHealPredictionBar:Hide()
			end
			if totalAbsorb > 0 then
				local value = min(maxhealth, health + totalPrediction)
				self.absorbPredictionBar:SetValue(value)
				self.absorbPredictionBar:Show()
			else
				self.absorbPredictionBar:Hide()
			end
			self.overAbsorbGlow:Hide()
		else
			if totalAbsorb > 0 and totalPrediction >= lost then
				self.overAbsorbGlow:Show()
				self.overAbsorb = totalAbsorb
			else
				self.overAbsorbGlow:Hide()
				self.overAbsorb = 0
			end
			self.myHealPredictionBar:Hide()
			self.otherHealPredictionBar:Hide()
			self.absorbPredictionBar:Hide()
		end
	else
		if self.healIcon and self.healIcon:IsShown() then
			self.healIcon:SetSize(0.001, 0.001)
			self.healIcon:Hide()
		end
		self.overAbsorbGlow:Hide()
		self.myHealPredictionBar:Hide()
		self.otherHealPredictionBar:Hide()
		self.absorbPredictionBar:Hide()
	end
end

local colorR, colorG, colorB

function InvenRaidFrames3Member_UpdateState(self)
	local _
	_, self.class = UnitClass(self.displayedUnit)
	if UnitIsConnected(self.unit) then
		self.isOffline = nil
		if UnitIsGhost(self.displayedUnit) then
			self.isGhost = true
		elseif UnitIsDead(self.displayedUnit) then
			self.isDead = true
		elseif UnitIsAFK(self.unit) then
			self.isAFK = true
		else
			self.isGhost, self.isOffline, self.isDead, self.isAFK = nil, nil, nil, nil
		end
		if self.isGhost or self.isDead then
			colorR, colorG, colorB = IRF3.db.colors.offline[1], IRF3.db.colors.offline[2], IRF3.db.colors.offline[3]
		elseif self.optionTable.useHarm and UnitCanAttack(self.displayedUnit, "player") then
			colorR, colorG, colorB = IRF3.db.colors.harm[1], IRF3.db.colors.harm[2], IRF3.db.colors.harm[3]
		elseif self.dispelType and IRF3.db.colors[self.dispelType] and self.optionTable.useDispelColor then
			colorR, colorG, colorB = IRF3.db.colors[self.dispelType][1], IRF3.db.colors[self.dispelType][2], IRF3.db.colors[self.dispelType][3]
		elseif self.displayedUnit:find("pet") then
			if self.petButton then
				colorR, colorG, colorB = IRF3.db.colors.vehicle[1], IRF3.db.colors.vehicle[2], IRF3.db.colors.vehicle[3]
			else
				colorR, colorG, colorB = IRF3.db.colors.pet[1], IRF3.db.colors.pet[2], IRF3.db.colors.pet[3]
			end
		elseif self.optionTable.useClassColors and IRF3.db.colors[self.class] then
			colorR, colorG, colorB = IRF3.db.colors[self.class][1], IRF3.db.colors[self.class][2], IRF3.db.colors[self.class][3]
		else
			colorR, colorG, colorB = IRF3.db.colors.help[1], IRF3.db.colors.help[2], IRF3.db.colors.help[3]
		end
	else
		self.isOffline, self.isGhost, self.isDead, self.isAFK = true, nil, nil, nil
		colorR, colorG, colorB = IRF3.db.colors.offline[1], IRF3.db.colors.offline[2], IRF3.db.colors.offline[3]
	end
	self.healthBar:SetStatusBarColor(colorR, colorG, colorB)
	colorR, colorG, colorB = nil
end

local altR, altG, altB

function InvenRaidFrames3Member_UpdatePowerColor(self)
	if self.isOffline then
		colorR, colorG, colorB = IRF3.db.colors.offline[1], IRF3.db.colors.offline[2], IRF3.db.colors.offline[3]
	elseif select(7, UnitAlternatePowerInfo(self.displayedUnit)) then
		colorR, colorG, colorB = 0.7, 0.7, 0.6
	else
		colorR, colorG, altR, altG, altB = UnitPowerType(self.displayedUnit)
		if IRF3.db.colors[colorG] then
			colorR, colorG, colorB = IRF3.db.colors[colorG][1], IRF3.db.colors[colorG][2], IRF3.db.colors[colorG][3]
		elseif PowerBarColor[colorR] then
			colorR, colorG, colorB = PowerBarColor[colorR].r, PowerBarColor[colorR].g, PowerBarColor[colorR].b
		elseif altR then
			colorR, colorG, colorB = altR, altG, altB
		else
			colorR, colorG, colorB = PowerBarColor[0].r, PowerBarColor[0].g, PowerBarColor[0].b
		end
	end
	self.powerBar:SetStatusBarColor(colorR, colorG, colorB)
	colorR, colorG, colorB, altR, altG, altB = nil
end

local roleType

function InvenRaidFrames3Member_UpdateRoleIcon(self)
	if self.optionTable.displayRaidRoleIcon then
		roleType = UnitGroupRolesAssigned(self.unit)
		if roleType ~= "NONE" then
			self.roleIcon:SetTexCoord(GetTexCoordsForRoleSmallCircle(roleType))
			self.roleIcon:SetSize(self.optionTable.roleIconSize, self.optionTable.roleIconSize)
			return self.roleIcon:Show()
		end
	end
	self.roleIcon:SetSize(0.001, 0.001)
	self.roleIcon:Hide()
end

--copied from bliz source.
function InvenRaidFrames3Member_UpdateCenterStatusIcon(self)
	if not self.centerStatusIcon then return end
	if self.optionTable.centerStatusIcon and UnitInOtherParty(self.unit) then
		self.centerStatusIcon.texture:SetTexture("Interface\\LFGFrame\\LFG-Eye")
		self.centerStatusIcon.texture:SetTexCoord(0.125, 0.25, 0.25, 0.5)
		self.centerStatusIcon.border:SetTexture("Interface\\Common\\RingBorder")
		self.centerStatusIcon.border:Show()
		self.centerStatusIcon.tooltip = PARTY_IN_PUBLIC_GROUP_MESSAGE
		self.centerStatusIcon:Show()
	elseif self.optionTable.centerStatusIcon and UnitHasIncomingResurrection(self.unit) then
		self.centerStatusIcon.texture:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez")
		self.centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
		self.centerStatusIcon.border:Hide()
		self.centerStatusIcon.tooltip = nil
		self.centerStatusIcon:Show()
		self.resurrectStart = GetTime() * 1000
	elseif self.optionTable.centerStatusIcon and self.inDistance and not UnitInPhase(self.unit) then
		self.centerStatusIcon.texture:SetTexture("Interface\\TargetingFrame\\UI-PhasingIcon")
		self.centerStatusIcon.texture:SetTexCoord(0.15625, 0.84375, 0.15625, 0.84375)
		self.centerStatusIcon.border:Hide()
		self.centerStatusIcon.tooltip = PARTY_PHASED_MESSAGE
		self.centerStatusIcon:Show()
	else
		self.centerStatusIcon:Hide()
	end
	InvenRaidFrames3Member_UpdateResurrection(self)
end

local tooltipUpdate = 0
function InvenRaidFrames3Member_CenterStatusIconOnUpdate(self, elapsed)
	if not IRF3.tootipState then return end
	tooltipUpdate = tooltipUpdate + elapsed
	if tooltipUpdate > 0.1 then
		tooltipUpdate = 0
		if self:IsMouseOver() and self.tooltip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
			GameTooltip:Show()
		elseif GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end
end

function InvenRaidFrames3Member_CenterStatusIconOnHide(self)
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end

function InvenRaidFrames3Member_UpdateOutline(self)
	if self.optionTable.outline.type == 1 then
		if self.dispelType and IRF3.db.colors[self.dispelType] then
			self.outline:SetBackdropBorderColor(IRF3.db.colors[self.dispelType][1], IRF3.db.colors[self.dispelType][2], IRF3.db.colors[self.dispelType][3])
			return self.outline:Show()
		end
	elseif self.optionTable.outline.type == 2 then
		if UnitIsUnit(self.displayedUnit, "target") then
			return self.outline:Show()
		end
	elseif self.optionTable.outline.type == 3 then
		if UnitIsUnit(self.displayedUnit, "mouseover") then
			return self.outline:Show()
		end
	elseif self.optionTable.outline.type == 4 then
		if not UnitIsDeadOrGhost(self.displayedUnit) and (self.health / self.maxHealth) <= self.optionTable.outline.lowHealth then
			return self.outline:Show()
		end
	elseif self.optionTable.outline.type == 5 then
		if self.hasAggro then
			return self.outline:Show()
		end
	elseif self.optionTable.outline.type == 6 then
		if self.optionTable.outline.raidIcon[GetRaidTargetIndex(self.displayedUnit)] then
			return self.outline:Show()
		end
	elseif self.optionTable.outline.type == 7 then
		if not UnitIsDeadOrGhost(self.displayedUnit) and self.maxHealth >= self.optionTable.outline.lowHealth2 and self.health < self.optionTable.outline.lowHealth2 then
			return self.outline:Show()
		end
	end
	self.outline:Hide()
end

function InvenRaidFrames3Member_OnUpdate(self)
	local prevRange = self.outRange
	if self.isOffline then
		self.outRange = false
	else
		local inRange, checkedRange = UnitInRange(self.displayedUnit)
		self.outRange = checkedRange and not inRange
	end
	if prevRange ~= self.outRange then
		if self.outRange then
			self.healthBar:SetAlpha(self.optionTable.fadeOutOfRangeHealth and self.optionTable.fadeOutAlpha or 1)
			self.powerBar:SetAlpha(self.optionTable.fadeOutOfRangePower and self.optionTable.fadeOutAlpha or 1)
			self.myHealPredictionBar:SetAlpha(0)
			self.otherHealPredictionBar:SetAlpha(0)
			self.absorbPredictionBar:SetAlpha(0)
		else
			self.healthBar:SetAlpha(1)
			self.powerBar:SetAlpha(1)
			self.myHealPredictionBar:SetAlpha(IRF3.db.units.healPredictionAlpha)
			self.otherHealPredictionBar:SetAlpha(IRF3.db.units.healPredictionAlpha)
			self.absorbPredictionBar:SetAlpha(IRF3.db.units.healPredictionAlpha)
			InvenRaidFrames3Member_UpdateHealth(self)
			InvenRaidFrames3Member_UpdateMaxPower(self)
			InvenRaidFrames3Member_UpdatePower(self)
			InvenRaidFrames3Member_UpdatePowerColor(self)
		end
		if self.petButton then
			InvenRaidFrames3Member_UpdateAura(self)
			InvenRaidFrames3Member_UpdateSpellTimer(self)
			InvenRaidFrames3Member_UpdateSurvivalSkill(self)
			InvenRaidFrames3Member_UpdateBuffs(self)
			InvenRaidFrames3Member_UpdateHealPrediction(self)
			InvenRaidFrames3Member_UpdateState(self)
			InvenRaidFrames3Member_UpdateNameColor(self)
			InvenRaidFrames3Member_UpdateDisplayText(self)
			InvenRaidFrames3Member_UpdateRaidIconTarget(self)
		end
	elseif self.petButton then
		InvenRaidFrames3Member_UpdateState(self)
		InvenRaidFrames3Member_UpdateRaidIconTarget(self)
	end
	-- 위상 업데이트
	local distance, checkedDistance = UnitDistanceSquared(self.displayedUnit)
	if checkedDistance then
		local inDistance = distance < 250*250
		if inDistance ~= self.inDistance then
			self.inDistance = inDistance
			InvenRaidFrames3Member_UpdateCenterStatusIcon(self)
		end
	end
end

function InvenRaidFrames3Member_OnUpdate2(self)
	if self.isOffline then
		self.outRange = false
	else
		local inRange, checkedRange = UnitInRange(self.displayedUnit)
		self.outRange = checkedRange and not inRange
	end
	if self.outRange then
		self.healthBar:SetAlpha(self.optionTable.fadeOutOfRangeHealth and self.optionTable.fadeOutAlpha or 1)
		self.powerBar:SetAlpha(self.optionTable.fadeOutOfRangePower and self.optionTable.fadeOutAlpha or 1)
		self.myHealPredictionBar:SetAlpha(0)
		self.otherHealPredictionBar:SetAlpha(0)
		self.absorbPredictionBar:SetAlpha(0)
	else
		self.healthBar:SetAlpha(1)
		self.powerBar:SetAlpha(1)
		self.myHealPredictionBar:SetAlpha(IRF3.db.units.healPredictionAlpha)
		self.otherHealPredictionBar:SetAlpha(IRF3.db.units.healPredictionAlpha)
		self.absorbPredictionBar:SetAlpha(IRF3.db.units.healPredictionAlpha)
	end
end

function InvenRaidFrames3Member_OnEvent(self, event, ...)
	eventHandler[event](self, ...)
end

function InvenRaidFrames3Member_UpdateAll(self)
	if IRF3.db then
		InvenRaidFrames3Member_UpdateInVehicle(self)
		if UnitExists(self.displayedUnit or "") then
			InvenRaidFrames3Member_UpdateName(self)
			InvenRaidFrames3Member_UpdateState(self)
			InvenRaidFrames3Member_UpdateNameColor(self)
			InvenRaidFrames3Member_OnUpdate2(self)
			InvenRaidFrames3Member_UpdateHealth(self)
			InvenRaidFrames3Member_UpdateHealPrediction(self)
			InvenRaidFrames3Member_UpdateMaxPower(self)
			InvenRaidFrames3Member_UpdatePower(self)
			InvenRaidFrames3Member_UpdatePowerColor(self)
			InvenRaidFrames3Member_UpdateCastingBar(self)
			InvenRaidFrames3Member_UpdatePowerBarAlt(self)
			InvenRaidFrames3Member_UpdateThreat(self)
			InvenRaidFrames3Member_UpdateRoleIcon(self)
			InvenRaidFrames3Member_UpdateRaidIcon(self)
			InvenRaidFrames3Member_UpdateAura(self)
			InvenRaidFrames3Member_UpdateSpellTimer(self)
			InvenRaidFrames3Member_UpdateSurvivalSkill(self)
			InvenRaidFrames3Member_UpdateOutline(self)
			InvenRaidFrames3Member_OnUpdate2(self)
			InvenRaidFrames3Member_UpdateRaidIconTarget(self)
			InvenRaidFrames3Member_UpdateDisplayText(self)
			InvenRaidFrames3Member_UpdateBuffs(self)
			InvenRaidFrames3Member_UpdateCenterStatusIcon(self)
		end
	end
end

function InvenRaidFrames3Member_UpdateInVehicle(self)
	self.unit = SecureButton_GetUnit(self)
	self.displayedUnit = self.unit and (SecureButton_GetModifiedUnit(self) or self.unit) or nil
	if self.petButton then
		if UnitExists(SecureButton_GetModifiedUnit(self.petButton) or "") then
			InvenRaidFrames3Pet_OnShow(self.petButton)
		else
			InvenRaidFrames3Pet_OnHide(self.petButton)
		end
	end
	if IRF3.onEnter == self then
		InvenRaidFrames3Member_OnEnter(self)
	end
end

function InvenRaidFrames3Member_OnAttributeChanged(self, name, value)
	if name == "unit" then
		InvenRaidFrames3Member_UpdateAll(self)
	end
end

eventHandler.PLAYER_ENTERING_WORLD = InvenRaidFrames3Member_UpdateAll
eventHandler.GROUP_ROSTER_UPDATE = InvenRaidFrames3Member_UpdateAll
eventHandler.PLAYER_ROLES_ASSIGNED = InvenRaidFrames3Member_UpdateRoleIcon
eventHandler.RAID_TARGET_UPDATE = function(self)
	InvenRaidFrames3Member_UpdateRaidIcon(self)
	if self.optionTable.outline.type == 6 then
		InvenRaidFrames3Member_UpdateOutline(self)
	end
end
eventHandler.UNIT_NAME_UPDATE = function(self, unit)
	if (unit == self.unit or unit == self.displayedUnit) then
		InvenRaidFrames3Member_UpdateName(self)
		InvenRaidFrames3Member_UpdateNameColor(self)
		InvenRaidFrames3Member_UpdateDisplayText(self)
	end
end
eventHandler.UNIT_CONNECTION = function(self, unit)
	if (unit == self.unit or unit == self.displayedUnit) then
		InvenRaidFrames3Member_UpdateName(self)
		InvenRaidFrames3Member_UpdateNameColor(self)
		InvenRaidFrames3Member_UpdateDisplayText(self)
		InvenRaidFrames3Member_UpdatePowerColor(self)
	end
end
eventHandler.UNIT_FLAGS = function(self, unit)
	if (unit == self.unit or unit == self.displayedUnit) then
		InvenRaidFrames3Member_UpdateHealth(self)
		InvenRaidFrames3Member_UpdateLostHealth(self)
		InvenRaidFrames3Member_UpdateState(self)
		InvenRaidFrames3Member_UpdateNameColor(self)
		InvenRaidFrames3Member_UpdateDisplayText(self)
	end
end
eventHandler.PLAYER_FLAGS_CHANGED = eventHandler.UNIT_FLAGS
eventHandler.UNIT_HEALTH = function(self, unit)
	if unit == self.displayedUnit then
		InvenRaidFrames3Member_UpdateHealth(self)
		InvenRaidFrames3Member_UpdateLostHealth(self)
		InvenRaidFrames3Member_UpdateHealPrediction(self)
		InvenRaidFrames3Member_UpdateState(self)
		if self.optionTable.outline.type == 4 or self.optionTable.outline.type == 7 then
			InvenRaidFrames3Member_UpdateOutline(self)
		end
	end
end
eventHandler.UNIT_MAXHEALTH = eventHandler.UNIT_HEALTH
eventHandler.UNIT_HEALTH_FREQUENT = function(self, unit)
	if unit == self.displayedUnit then
		InvenRaidFrames3Member_UpdateHealth(self)
		InvenRaidFrames3Member_UpdateLostHealth(self)
	end
end
eventHandler.UNIT_MAXPOWER = function(self, unit, powerType)
	if unit == self.displayedUnit then
		if powerType == "ALTERNATE" then
			InvenRaidFrames3Member_UpdatePowerBarAlt(self)
		else
			InvenRaidFrames3Member_UpdateMaxPower(self)
			InvenRaidFrames3Member_UpdatePower(self)
		end
	end
end
eventHandler.UNIT_POWER = function(self, unit, powerType)
	if unit == self.displayedUnit then
		if powerType == "ALTERNATE" then
			InvenRaidFrames3Member_UpdatePowerBarAlt(self)
		else
			InvenRaidFrames3Member_UpdatePower(self)
		end
	end
end
eventHandler.UNIT_DISPLAYPOWER = function(self, unit)
	if unit == self.displayedUnit then
		InvenRaidFrames3Member_UpdateMaxPower(self)
		InvenRaidFrames3Member_UpdatePower(self)
		InvenRaidFrames3Member_UpdatePowerColor(self)
		InvenRaidFrames3Member_UpdatePowerBarAlt(self)
	end
end
eventHandler.UNIT_POWER_BAR_SHOW = eventHandler.UNIT_DISPLAYPOWER
eventHandler.UNIT_POWER_BAR_HIDE = eventHandler.UNIT_DISPLAYPOWER
eventHandler.UNIT_HEAL_PREDICTION = function(self, unit)
	if unit == self.displayedUnit then
		InvenRaidFrames3Member_UpdateHealth(self)
		InvenRaidFrames3Member_UpdateHealPrediction(self)
	end
end
eventHandler.UNIT_ABSORB_AMOUNT_CHANGED = eventHandler.UNIT_HEAL_PREDICTION
eventHandler.UNIT_AURA = function(self, unit)
	if (unit == self.unit or unit == self.displayedUnit) then
		InvenRaidFrames3Member_UpdateAura(self)
		InvenRaidFrames3Member_UpdateSpellTimer(self)
		InvenRaidFrames3Member_UpdateSurvivalSkill(self)
		InvenRaidFrames3Member_UpdateBuffs(self)
		if self.optionTable.outline.type == 1 then
			InvenRaidFrames3Member_UpdateOutline(self)
		end
		if self.optionTable.useDispelColor then
			InvenRaidFrames3Member_UpdateState(self)
		end
	end
end
eventHandler.UNIT_THREAT_SITUATION_UPDATE = function(self, unit)
	if unit == self.displayedUnit then
		InvenRaidFrames3Member_UpdateThreat(self)
		InvenRaidFrames3Member_UpdateDisplayText(self)
		if self.optionTable.outline.type == 5 then
			InvenRaidFrames3Member_UpdateOutline(self)
		end
	end
end
eventHandler.READY_CHECK_CONFIRM = function(self, unit)
	if unit == self.unit then
		InvenRaidFrames3Member_UpdateReadyCheck(self)
	end
end
eventHandler.UNIT_ENTERED_VEHICLE = function(self, unit)
	if unit == self.unit then
		InvenRaidFrames3Member_UpdateAll(self)
	end
end
--UNIT_PET event sometimes not fires on vehicle exit, causing health bar bug. update health againg after 1 sec.
eventHandler.UNIT_EXITED_VEHICLE = function(self, unit)
	if unit == self.unit then
		InvenRaidFrames3Member_UpdateAll(self)
		C_Timer.After(1, function()
			if UnitExists(self.unit) then
				InvenRaidFrames3Member_UpdateHealth(self)
				InvenRaidFrames3Member_UpdateLostHealth(self)
			end
		end)
	end
end
eventHandler.UNIT_PET = eventHandler.UNIT_ENTERED_VEHICLE
eventHandler.UNIT_SPELLCAST_START = function(self, unit)
	if IRF3.db.units.useCastingBar and unit == self.displayedUnit then
		InvenRaidFrames3Member_UpdateCastingBar(self)
	end
end
eventHandler.UNIT_SPELLCAST_STOP = eventHandler.UNIT_SPELLCAST_START
eventHandler.UNIT_SPELLCAST_DELAYED = eventHandler.UNIT_SPELLCAST_START
eventHandler.UNIT_SPELLCAST_CHANNEL_START = eventHandler.UNIT_SPELLCAST_START
eventHandler.UNIT_SPELLCAST_CHANNEL_UPDATE = eventHandler.UNIT_SPELLCAST_START
eventHandler.UNIT_SPELLCAST_CHANNEL_STOP = eventHandler.UNIT_SPELLCAST_START
eventHandler.PLAYER_TARGET_CHANGED = InvenRaidFrames3Member_UpdateOutline
eventHandler.UPDATE_MOUSEOVER_UNIT = InvenRaidFrames3Member_UpdateOutline
eventHandler.INCOMING_RESURRECT_CHANGED = function(self)
	InvenRaidFrames3Member_UpdateCenterStatusIcon(self)
end
eventHandler.UNIT_OTHER_PARTY_CHANGED = eventHandler.INCOMING_RESURRECT_CHANGED
eventHandler.UNIT_PHASE = eventHandler.INCOMING_RESURRECT_CHANGED
