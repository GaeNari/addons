local overlord = CreateFrame("Button", (...).."Overlord", UIParent, "SecureHandlerClickTemplate")
local IRF3 = CreateFrame("Frame", ..., overlord, "SecureHandlerAttributeTemplate")
IRF3:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
IRF3:RegisterEvent("PLAYER_LOGIN")
IRF3:SetFrameStrata("MEDIUM")
IRF3:SetFrameLevel(2)
IRF3:SetMovable(true)
IRF3:SetClampedToScreen(true)

local _G = _G
local type = _G.type
local pairs = _G.pairs
local unpack = _G.unpack
local GetSpellInfo = _G.GetSpellInfo
local LBDB = LibStub("LibBlueDB-1.0")

function IRF3:PLAYER_LOGIN()
	self.PLAYER_LOGIN = nil
	self.playerClass = select(2, UnitClass("player"))
	self:InitDB()
	self.version = GetAddOnMetadata(self:GetName(), "Version")
	self.website = GetAddOnMetadata(self:GetName(), "X-Website")
	self:ApplyPorfile()
	self:SelectClickCastingDB()
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PET_BATTLE_OPENING_START")
	self:RegisterEvent("PET_BATTLE_CLOSE")
	self.PLAYER_REGEN_ENABLED = self.UpdateTooltipState
	self.PLAYER_REGEN_DISABLED = self.UpdateTooltipState
	LibStub("LibMapButton-1.1"):CreateButton(self, "InvenRaidFrames3MapButton", "Interface\\AddOns\\InvenRaidFrames3\\Texture\\Icon.tga", 190, InvenRaidFrames3DB.minimapButton)
	self.mapButtonMenu:SetParent(InvenRaidFrames3MapButton)
	self.mapButtonMenu:SetPoint("CENTER", 0, 0)
	self.mapButtonMenu:Hide()
	LibStub("LibDataBroker-1.1"):NewDataObject("InvenRaidFrames3", {
		type = "launcher",
		text = "IRF3",
		OnClick = function(_, button) IRF3:OnClick(button) end,
		icon = "Interface\\AddOns\\InvenRaidFrames3\\Texture\\Icon.tga",
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			IRF3:OnTooltip(tooltip)
		end,
		OnLeave = GameTooltip_Hide,
	})
	self:SetScript("OnHide", InvenRaidFrames3Member_OnDragStop)
	LibStub("LibRealDispel-1.0").RegisterCallback(self, "Update", function()
		for member in pairs(IRF3.visibleMembers) do
			if member:GetScript("OnEvent") and member:IsEventRegistered("UNIT_AURA") and member.displayedUnit then
				member:GetScript("OnEvent")(member, "UNIT_AURA", member.displayedUnit)
			end
		end
	end)
end

function IRF3:LoadPosition()
	self:SetUserPlaced(nil)
	self:SetScale(self.db.scale)
	self:ClearAllPoints()
	if self.db.px then
		self:SetPoint(self.db.anchor, UIParent, self.db.px / self.db.scale, self.db.py / self.db.scale)
	else
		self:SetPoint(self.db.anchor, UIParent, "CENTER", 0, 0)
	end
	self.petHeader:SetUserPlaced(nil)
	self.petHeader:SetScale(self.db.petscale)
	self.petHeader:ClearAllPoints()
	if self.db.petpx then
		self.petHeader:SetPoint(self.db.petanchor, UIParent, self.db.petanchor, self.db.petpx / (self.db.petscale * self.db.scale), self.db.petpy / (self.db.petscale * self.db.scale))
	else
		self.petHeader:SetPoint(self.db.petanchor, UIParent, "CENTER", 0, 0)
	end
end

function IRF3:SavePosition()
	if self.db.anchor == "TOPLEFT" then
		self.db.px = self:GetLeft() * self.db.scale
		self.db.py = self:GetTop() * self.db.scale - UIParent:GetTop()
	elseif self.db.anchor == "TOPRIGHT" then
		self.db.px = self:GetRight() * self.db.scale - UIParent:GetRight()
		self.db.py = self:GetTop() * self.db.scale - UIParent:GetTop()
	elseif self.db.anchor == "BOTTOMLEFT" then
		self.db.px = self:GetLeft() * self.db.scale
		self.db.py = self:GetBottom() * self.db.scale
	elseif self.db.anchor == "BOTTOMRIGHT" then
		self.db.px = self:GetRight() * self.db.scale - UIParent:GetRight()
		self.db.py = self:GetBottom() * self.db.scale
	end
	if self.db.petanchor == "TOPLEFT" then
		self.db.petpx = self.petHeader:GetLeft() * (self.db.petscale * self.db.scale)
		self.db.petpy = self.petHeader:GetTop() * (self.db.petscale * self.db.scale) - UIParent:GetTop()
	elseif self.db.petanchor == "TOPRIGHT" then
		self.db.petpx = self.petHeader:GetRight() * (self.db.petscale * self.db.scale) - UIParent:GetRight()
		self.db.petpy = self.petHeader:GetTop() * (self.db.petscale * self.db.scale) - UIParent:GetTop()
	elseif self.db.petanchor == "BOTTOMLEFT" then
		self.db.petpx = self.petHeader:GetLeft() * (self.db.petscale * self.db.scale)
		self.db.petpy = self.petHeader:GetBottom() * (self.db.petscale * self.db.scale)
	elseif self.db.petanchor == "BOTTOMRIGHT" then
		self.db.petpx = self.petHeader:GetRight() * (self.db.petscale * self.db.scale) - UIParent:GetRight()
		self.db.petpy = self.petHeader:GetBottom() * (self.db.petscale * self.db.scale)
	end
end

function IRF3:UpdateTooltipState()
	if self.db.units.tooltip == 0 then
		self.tootipState = nil
	elseif self.db.units.tooltip == 1 then
		self.tootipState = true
	elseif InCombatLockdown() or UnitAffectingCombat("player") then
		self.tootipState = self.db.units.tooltip == 3
	elseif self.db.units.tooltip == 2 then
		self.tootipState = true
	else
		self.tootipState = nil
	end
	if self.onEnter then
		InvenRaidFrames3Member_OnEnter(self.onEnter)
	end
end

function IRF3:BorderUpdate(fast)
	if self.db.border then
		if fast then
			self.border.updater:GetScript("OnUpdate")(self.border.updater)
		else
			self.border.updater:Show()
		end
		self.petHeader.border:Show()
	else
		self.border.updater:Hide()
		self.border:SetAlpha(0)
		self.petHeader.border:Hide()
	end
end

function IRF3:OnClick(button)
	if button == "RightButton" then
		ToggleDropDownMenu(1, nil, IRF3.mapButtonMenu, "cursor")
	elseif InterfaceOptionsFrame:IsShown() and InterfaceOptionsFramePanelContainer.displayedPanel == IRF3.optionFrame then
		InterfaceOptionsFrame_Show()
	else
		InterfaceOptionsFrame_Show()
		InterfaceOptionsFrame_OpenToCategory(IRF3.optionFrame)
	end
end

function IRF3:OnTooltip(tooltip)
	tooltip = tooltip or GameTooltip
	tooltip:AddLine("인벤 레이드 프레임 3".." v"..IRF3.version)
	tooltip:AddLine("http://wow.inven.co.kr", 1, 1, 1)
	tooltip:AddLine("좌클릭: 옵션창 열기", 1, 1, 0)
	tooltip:AddLine("우클릭: 메뉴 열기", 1, 1, 0)
end

function IRF3:Message(msg)
	ChatFrame1:AddMessage("|cffffff00IRF3: |r"..msg, 1, 1, 1)
end

function IRF3:IsLeader()
	return IsInGroup() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))
end

function IRF3:IsLeader2()
	if IsInRaid() then
		return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
	elseif IsInGroup() then
		return true
	end
	return nil
end

local clearObjectFuncs = {}

function IRF3:RegisterClearObject(func)
	clearObjectFuncs[func] = true
end

function IRF3:CallbackClearObject(object)
	for func in pairs(clearObjectFuncs) do
		func(object)
	end
end

local function changeParent(frame, prevParent, newParent)
	if frame and frame:GetParent() == prevParent then
		frame:SetParent(newParent)
	end
end

function IRF3:HideBlizzardPartyFrame(hide)
	self.db.hideBlizzardParty = hide
	if hide then
		for i = 1, MAX_PARTY_MEMBERS do
			changeParent(_G["PartyMemberFrame"..i], UIParent, self.dummyParent)
		end
		changeParent(PartyMemberBackground, UIParent, self.dummyParent)
	else
		for i = 1, MAX_PARTY_MEMBERS do
			changeParent(_G["PartyMemberFrame"..i], self.dummyParent, UIParent)
		end
		changeParent(PartyMemberBackground, self.dummyParent, UIParent)
	end
end

function IRF3:GetHeaderHeight(member)
	if member then
		if member > 0 then
			return self.db.height * member + ((self.db.usePet == 2 and self.db.petHeight or 0) + self.db.offset) * (member - 1)
		else
			return 0.1
		end
	else
		return (self.db.height + (self.db.usePet == 2 and self.db.petHeight or 0)) * 5 + self.db.offset * 4
	end
end

function IRF3.GetSpellName(id)
	--if not GetSpellInfo(id) then print("IRF: spell id "..id.." removed!") end
	return GetSpellInfo(id) or ""
end

local savedStatus = true

function IRF3:PET_BATTLE_OPENING_START()
	savedStatus = self:GetAttribute("run") or IRF3.db.run
	self:SetAttribute("run", false)
end
function IRF3:PET_BATTLE_CLOSE()
	self:SetAttribute("run", savedStatus)
end

IRF3.dummyParent = CreateFrame("Frame")
IRF3.dummyParent:Hide()

IRF3.border = CreateFrame("Frame", nil, IRF3)
IRF3.border:SetFrameLevel(1)
IRF3.border:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Addons\\InvenRaidFrames3\\Texture\\Border.tga",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
IRF3.border.updater = CreateFrame("Frame", nil, IRF3.border)
IRF3.border.updater:Hide()

local function hasAllPoints(frame)
	return frame:GetLeft() and frame:GetRight() and frame:GetTop() and frame:GetBottom()
end

IRF3.border.updater:SetScript("OnUpdate", function(self)
	self:Hide()
	self = self:GetParent()
	self.headers = self:GetParent().headers
	self.count, self.left, self.right, self.top, self.bottom = 0
	for i = 0, 8 do
		if self.headers[i]:IsVisible() then
			self.count = self.count + 1
			if self.headers[i].visible > 0 then
				if hasAllPoints(self.headers[i]) then
					if not self.left or self.headers[i]:GetLeft() < self.left:GetLeft() then
						self.left = self.headers[i]
					end
					if not self.right or self.headers[i]:GetRight() > self.right:GetRight() then
						self.right = self.headers[i]
					end
					if IRF3.db.usePet == 2 and self.headers[i].members[self.headers[i].visible].petButton and self.headers[i].members[self.headers[i].visible].petButton:IsShown() then
						if hasAllPoints(self.headers[i].members[self.headers[i].visible].petButton) then
							if IRF3.db.anchor:find("TOP") then
								if not self.top or self.headers[i]:GetTop() > self.top:GetTop() then
									self.top = self.headers[i]
								end
								if not self.bottom or self.headers[i].members[self.headers[i].visible].petButton:GetBottom() < self.bottom:GetBottom() then
									self.bottom = self.headers[i].members[self.headers[i].visible].petButton
								end
							else
								if not self.top or self.headers[i].members[self.headers[i].visible].petButton:GetTop() > self.top:GetTop() then
									self.top = self.headers[i].members[self.headers[i].visible].petButton
								end
								if not self.bottom or self.headers[i]:GetBottom() < self.bottom:GetBottom() then
									self.bottom = self.headers[i]
								end
							end
						else
							self:SetAlpha(0)
							return self.updater:Show()
						end
					else
						if not self.top or self.headers[i]:GetTop() > self.top:GetTop() then
							self.top = self.headers[i]
						end
						if not self.bottom or self.headers[i]:GetBottom() < self.bottom:GetBottom() then
							self.bottom = self.headers[i]
						end
					end
				else
					self:SetAlpha(0)
					return self.updater:Show()
				end
			end
		end
	end
	if self.left then
		self:ClearAllPoints()
		if IRF3.db.anchor == "TOPLEFT" then
			self:SetPoint("TOPLEFT", -5, 5)
			self:SetPoint("RIGHT", self.right, 5, 0)
			self:SetPoint("BOTTOM", self.bottom, "BOTTOM", 0, -5)
		elseif IRF3.db.anchor == "TOPRIGHT" then
			self:SetPoint("TOPRIGHT", 5, 5)
			self:SetPoint("LEFT", self.left, -5, 0)
			self:SetPoint("BOTTOM", self.bottom, "BOTTOM", 0, -5)
		elseif IRF3.db.anchor == "BOTTOMLEFT" then
			self:SetPoint("BOTTOMLEFT", -5, -5)
			self:SetPoint("RIGHT", self.right, 5, 0)
			self:SetPoint("TOP", self.top, 0, 5)
		elseif IRF3.db.anchor == "BOTTOMRIGHT" then
			self:SetPoint("BOTTOMRIGHT", 5, -5)
			self:SetPoint("LEFT", self.left, -5, 0)
			self:SetPoint("TOP", self.top, 0, 5)
		end
		self:SetAlpha(1)
	else
		self:SetAlpha(0)
		if self.count > 0 then
			return self.updater:Show()
		end
	end
	self.headers, self.count, self.left, self.right, self.top, self.bottom, self.anchor = nil
end)

IRF3.optionFrame = CreateFrame("Frame", IRF3:GetName().."OptionFrame", InterfaceOptionsFramePanelContainer)
IRF3.optionFrame:Hide()
IRF3.optionFrame.name = "인벤 레이드 프레임 3"
IRF3.optionFrame.addon = IRF3:GetName()
IRF3.optionFrame:SetScript("OnShow", function(self)
	if InCombatLockdown() then
		if not self.title then
			self.title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			self.title:SetText(self.name)
			self.title:SetPoint("TOPLEFT", 8, -12)
			self.version = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			self.version:SetText("v"..IRF3.version)
			self.version:SetPoint("LEFT", self.title, "RIGHT", 2, 0)
			self.combatWarn = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			self.combatWarn:SetText("전투중에는 인벤 레이드 프레임의 옵션 설정이 불가능합니다.\n전투 종료후 다시 시도해주세요.")
			self.combatWarn:SetPoint("CENTER", 0, 0)
		end
		if not self:IsEventRegistered("PLAYER_REGEN_ENABLED") then
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
	else
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", nil)
		self:SetScript("OnShow", nil)
		LoadAddOn(self.addon.."_Option")
	end
end)
IRF3.optionFrame:SetScript("OnEvent", function(self, event, arg)
	if event == "PLAYER_REGEN_ENABLED" then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		if self:IsVisible() and not self.loaded and self:GetScript("OnShow") then
			self:GetScript("OnShow")(self)
		end
	end
end)
InterfaceOptions_AddCategory(IRF3.optionFrame)

SLASH_INVENRAIDFRAMES31 = "/irf"
SLASH_INVENRAIDFRAMES32 = "/irf3"
SLASH_INVENRAIDFRAMES33 = "/인벤레이드"
SLASH_INVENRAIDFRAMES34 = "/인벤레이드프레임"
SLASH_INVENRAIDFRAMES35 = "/invenraidframe"
SLASH_INVENRAIDFRAMES36 = "/invenraidframes"
SLASH_INVENRAIDFRAMES37 = "/ㅑㄱㄹ"
SLASH_INVENRAIDFRAMES38 = "/ㅑㄱㄹ3"
SlashCmdList["INVENRAIDFRAMES3"] = IRF3.OnClick

overlord:SetFrameRef("frame", IRF3)
overlord:Execute("IRF3 = self:GetFrameRef('frame')")
overlord:SetAttribute("_onclick", "IRF3:SetAttribute('run', not IRF3:GetAttribute('run'))")
overlord:SetScript("PostClick", function()
	if IRF3.db.run ~= IRF3:GetAttribute("run") then
		IRF3.db.run = IRF3:GetAttribute("run")
		if IRF3.db.run then
			IRF3:Message("공격대 창이 활성화 되었습니다.")
		else
			IRF3:Message("공격대 창이 비활성화 되었습니다.")
		end
		if IRF3.optionFrame.runMenu and IRF3.optionFrame.runMenu:IsVisible() then
			IRF3.optionFrame.runMenu:Update()
		end
		IRF3.manager.content.hideButton:SetText(IRF3.db.run and HIDE or SHOW)
	end
end)

BINDING_HEADER_INVENRAIDFRAMES3 = "인벤 레이드 프레임 3"
BINDING_NAME_INVENRAIDFRAMES3_OPTION = "옵션창 열기"
BINDING_NAME_INVENRAIDFRAMES3_DOREADYCHECK = "전투 준비 확인하기"
BINDING_NAME_INVENRAIDFRAMES3_INITIATEROLEPOLL = "역할 확인하기"
_G["BINDING_NAME_CLICK InvenRaidFrames3Overlord:LeftButton"] = "사용/비사용 전환"

local function runFunc()
	if InCombatLockdown() then
		IRF3:Message("전투중에는 활성/비활성화 설정을 할 수 없습니다.")
	else
		IRF3:SetAttribute("run", not IRF3:GetAttribute("run"))
		overlord:GetScript("PostClick")(overlord)
	end
end

local function lockFunc()
	IRF3.db.lock = not IRF3.db.lock
end

local function initializeDropDown()
	local info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true
	info.isNotRadio = true
	info.text = "옵션창 열기"
	info.func = IRF3.OnClick
	UIDropDownMenu_AddButton(info)
	info.notCheckable = nil
	info.text = "사용하기"
	info.checked = IRF3.db and IRF3.db.run
	info.func = runFunc
	UIDropDownMenu_AddButton(info)
	info.text = "고정하기"
	info.checked = IRF3.db and IRF3.db.lock
	info.func = lockFunc
	UIDropDownMenu_AddButton(info)
	info.notCheckable = true
	info.checked = nil
	info.text = "전투 준비 확인하기"
	info.disabled = not IRF3:IsLeader()
	info.func = DoReadyCheck
	UIDropDownMenu_AddButton(info)
	info.text = "역할 확인하기"
	info.func = InitiateRolePoll
	UIDropDownMenu_AddButton(info)
	info.disabled = nil
	info.func = nil
	info.text = CLOSE
	UIDropDownMenu_AddButton(info)
end

IRF3.mapButtonMenu = CreateFrame("Frame", "InvenRaidFrames3MapButtonMenu", IRF3, "UIDropDownMenuTemplate")
IRF3.mapButtonMenu:SetID(1)
IRF3.mapButtonMenu:SetWidth(10)
IRF3.mapButtonMenu:SetHeight(10)
UIDropDownMenu_Initialize(IRF3.mapButtonMenu, initializeDropDown)