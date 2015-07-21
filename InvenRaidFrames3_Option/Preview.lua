local IRF3 = InvenRaidFrames3
local Option = IRF3.optionFrame
local SM = LibStub("LibSharedMedia-3.0")
local preview, height, statusBarTexture, fontFile

local function registerDrag(btn)
	btn:EnableMouse(true)
	btn:RegisterForDrag("LeftButton", "RightButton")
	btn:SetScript("OnDragStart", InvenRaidFrames3Member_OnDragStart)
	btn:SetScript("OnDragStop", InvenRaidFrames3Member_OnDragStop)
	btn:SetScript("OnHide", InvenRaidFrames3Member_OnDragStop)
end

local function dummy() end

local function createButton(btn)
	btn = CreateFrame("Frame", nil, btn)
	btn.powerBar = btn:CreateTexture(nil, "BORDER")
	btn.powerBar.SetOrientation = dummy
	btn.powerBar:SetPoint("BOTTOMLEFT", 0, 0)
	btn.powerBar:SetPoint("BOTTOMRIGHT", 0, 0)
	btn.healthBar = btn:CreateTexture(nil, "BORDER")
	btn.healthBar:SetPoint("TOPLEFT", 0, 0)
	btn.healthBar:SetPoint("BOTTOMRIGHT", btn.powerBar, "TOPRIGHT", 0, 0)
	registerDrag(btn)
	return btn
end

local classList = { "WARRIOR", "PRIEST", "ROGUE", "MAGE", "WARLOCK", "HUNTER", "DRUID", "SHAMAN", "PALADIN", "DEATHKNIGHT" }
local powerColor = { WARRIOR = "1", PRIEST = "0", ROGUE = "3", MAGE = "0", WARLOCK = "0", HUNTER = "2", DRUID = "013", SHAMAN = "0", PALADIN = "0", DEATHKNIGHT = "6" }
local powerMatch = { ["0"] = "MANA", ["1"] = "RAGE", ["2"] = "FOCUS", ["3"] = "ENERGY", ["6"] = "RUNIC_POWER" }
local allPower = "01236"

local function createPreview()
	createPreview = nil
	preview = CreateFrame("Frame", "InvenRaidFrames3Preview", UIParent)
	Option.preview = preview
	preview:SetAllPoints(IRF3)
	preview:SetFrameStrata(IRF3:GetFrameStrata())
	preview:SetFrameLevel(1)
	preview:RegisterEvent("PLAYER_REGEN_DISABLED")
	preview:SetScript("OnEvent", function(self)
		if self:IsShown() then
			self.show = nil
			self:Hide()
			Option.previewDropdown:Update()
		end
	end)
	preview.border = CreateFrame("Frame", nil, preview)
	preview.border:SetBackdrop(IRF3.border:GetBackdrop())
	preview.headers = {}
	preview.headers[0] = preview:CreateTexture()
	preview.headers[0]:Hide()
	for i = 1, 8 do
		preview.headers[i] = CreateFrame("Frame", nil, preview)
		preview.headers[i]:SetAttribute("groupindex", i)
		preview.headers[i].partyTag = CreateFrame("Frame", nil, preview.headers[i])
		preview.headers[i].partyTag.tex = preview.headers[i].partyTag:CreateTexture(nil, "BORDER")
		preview.headers[i].partyTag.tex:SetAllPoints()
		preview.headers[i].partyTag.text = preview.headers[i].partyTag:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		preview.headers[i].partyTag.text:SetPoint("CENTER")
		registerDrag(preview.headers[i].partyTag)
		preview.headers[i].members, preview.headers[i].visible = {}, 5
		for j = 1, 5 do
			preview.headers[i].members[j] = createButton(preview.headers[i])
			preview.headers[i].members[j].class = classList[random(1, 10)]
			height = random(1, powerColor[preview.headers[i].members[j].class]:len())
			preview.headers[i].members[j].powerBar.color = powerMatch[powerColor[preview.headers[i].members[j].class]:sub(height, height)]
			preview.headers[i].members[j].petButton = createButton(preview.headers[i].members[j])
			preview.headers[i].members[j].petButton.healthBar:SetPoint("TOPLEFT", 0, -1)
			preview.headers[i].members[j].petButton.powerBar:SetHeight(3)
			preview.headers[i].members[j].petButton.powerBar.color = preview.headers[i].members[j].class == "HUNTER" and "FOCUS" or "MANA"
			preview.headers[i].members[j].name = preview.headers[i].members[j]:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			preview.headers[i].members[j].name:SetPoint("CENTER", preview.headers[i].members[j].healthBar, 0, 5)
			preview.headers[i].members[j].name:SetFormattedText("%d-%d", i, j)
			preview.headers[i].members[j].losttext = preview.headers[i].members[j]:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			preview.headers[i].members[j].losttext:SetPoint("TOP", preview.headers[i].members[j].name, "BOTTOM", 0, -2)
		end
	end
	preview.petHeader = CreateFrame("Frame", "InvenRaidFrames3PreviewPet", preview)
	preview.petHeader.border = CreateFrame("Frame", nil, preview.petHeader)
	preview.petHeader.border:SetBackdrop(IRF3.border:GetBackdrop())
	preview.petHeader.border:SetPoint("TOPLEFT", -5, 5)
	preview.petHeader.border:SetPoint("BOTTOMRIGHT", 5, -5)
	preview.petHeader.members = {}
	for i = 1, 40 do
		preview.petHeader.members[i] = createButton(preview.petHeader)
		preview.petHeader.members[i].class = "pet"
		height = random(1, allPower:len())
		preview.petHeader.members[i].powerBar.color = powerMatch[allPower:sub(height, height)]
		preview.petHeader.members[i].name = preview.petHeader.members[i]:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		preview.petHeader.members[i].name:SetPoint("CENTER", preview.petHeader.members[i].healthBar, 0, 5)
		preview.petHeader.members[i].name:SetFormattedText("Pet%d", i)
		preview.petHeader.members[i].losttext = preview.petHeader.members[i]:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		preview.petHeader.members[i].losttext:SetPoint("TOP", preview.petHeader.members[i].name, "BOTTOM", 0, -2)
	end
	wipe(classList)
	wipe(powerColor)
	registerDrag, createButton, classList, powerColor = nil
	preview.UpdatePosition = "if name == \"updateposition\" then"..IRF3:GetAttribute("_onattributechanged"):match("elseif name == \"updateposition\" then(.+)")
	preview.UpdatePosition = preview.UpdatePosition:gsub("self:GetAttribute", "IRF3:GetAttribute")
	preview.UpdatePosition = loadstring("return function(self, IRF3, HEADERS, LIST, name)\n"..preview.UpdatePosition.."\nend")()
	preview.border.dummy = preview.border:CreateTexture()
	preview.CallMethod = function(self, method)
		if method == "BorderUpdate" then
			if IRF3.db.border then
				IRF3.border.updater:GetScript("OnUpdate")(self.border.dummy)
				self.border:SetAlpha(1)
				self.border:Show()
				self.petHeader.border:Show()
			else
				self.border:Hide()
				self.petHeader.border:Hide()
			end
		end
	end
end

local numMembers = { 0, 1, 2, 5, 8 }
local LIST = {}

local function checkHeader(show, index)
	if show < index then
		return nil
	elseif IRF3.db.groupby ~= "GROUP" then
		return true
	elseif show == 1 and index == 1 then
		return true
	else
		return IRF3.db.groupshown[index]
	end
end

local p1, p2, o1, o2, width

function Option:SetPreview(show)
	if show and numMembers[show] and numMembers[show] > 0 and not InCombatLockdown() then
		if createPreview then
			createPreview()
		end
		IRF3:SetAttribute("preview", true)
		preview.show = show
		preview:Show()
		preview:SetScale(IRF3.db.scale)
		preview.border:SetBackdropColor(unpack(IRF3.db.borderBackdrop))
		preview.border:SetBackdropBorderColor(unpack(IRF3.db.borderBackdropBorder))
		statusBarTexture = SM:Fetch("statusbar", IRF3.db.units.texture)
		fontFile = SM:Fetch("font", IRF3.db.font.file)
		if IRF3.db.dir == 1 then
			width = IRF3.db.width
			height = (IRF3.db.height + IRF3.db.offset + (IRF3.db.usePet == 2 and IRF3.db.petHeight or 0)) * 5 - IRF3.db.offset
			if IRF3.db.anchor:find("TOP") then
				p1, p2, o1, o2 = "TOP", "BOTTOM", 0, (IRF3.db.usePet == 2 and -IRF3.db.petHeight or 0) - IRF3.db.offset
			else
				p1, p2, o1, o2 = "BOTTOM", "TOP", 0, (IRF3.db.usePet == 2 and IRF3.db.petHeight or 0) + IRF3.db.offset
			end
		else
			width = IRF3.db.width * 5 + IRF3.db.offset * 4
			height = IRF3.db.height
			if IRF3.db.anchor:find("LEFT") then
				p1, p2, o1, o2 = "LEFT", "RIGHT", IRF3.db.offset, 0
			else
				p1, p2, o1, o2 = "RIGHT", "LEFT", -IRF3.db.offset, 0
			end
		end
		local members = 0
		for i = 1, 8 do
			if checkHeader(numMembers[show], i) then
				members = members + 5
				preview.headers[i]:Show()
				preview.headers[i]:SetWidth(width)
				preview.headers[i]:SetHeight(height)
				if IRF3.db.groupby == "GROUP" and IRF3.db.partyTag then
					preview.headers[i].partyTag:ClearAllPoints()
					if IRF3.db.dir == 1 then
						preview.headers[i].partyTag:SetPoint(p2.."LEFT", preview.headers[i], p1.."LEFT", 0, 0)
						preview.headers[i].partyTag:SetPoint(p2.."RIGHT", preview.headers[i], p1.."RIGHT", 0, 0)
						preview.headers[i].partyTag:SetHeight(12)
						preview.headers[i].partyTag.text:SetFormattedText("파티 %d", i)
					else
						preview.headers[i].partyTag:SetPoint("TOP"..p2, preview.headers[i], "TOP"..p1, 0, 0)
						preview.headers[i].partyTag:SetPoint("BOTTOM"..p2, preview.headers[i], "BOTTOM"..p1, 0, 0)
						preview.headers[i].partyTag:SetWidth(12)
						preview.headers[i].partyTag.text:SetText(i)
					end
					preview.headers[i].partyTag.tex:SetTexture(IRF3.db.partyTagRaid[1], IRF3.db.partyTagRaid[2], IRF3.db.partyTagRaid[3], IRF3.db.partyTagRaid[4])
					preview.headers[i].partyTag:Show()
				else
					preview.headers[i].partyTag:SetHeight(0.001)
					preview.headers[i].partyTag:Hide()
				end
				for j = 1, 5 do
					preview.headers[i].members[j]:SetWidth(IRF3.db.width)
					preview.headers[i].members[j]:SetHeight(IRF3.db.height)
					preview.headers[i].members[j]:ClearAllPoints()
					if j == 1 then
						preview.headers[i].members[j]:SetPoint(p1, 0, 0)
					else
						preview.headers[i].members[j]:SetPoint(p1, preview.headers[i].members[j - 1], p2, o1, o2)
					end
					preview.headers[i].members[j].healthBar:SetTexture(statusBarTexture)
					preview.headers[i].members[j].name:SetFont(fontFile, IRF3.db.font.size, IRF3.db.font.attribute)
					preview.headers[i].members[j].name:SetShadowColor(0, 0, 0)
					preview.headers[i].members[j].losttext:SetFont(fontFile, IRF3.db.font.size, IRF3.db.font.attribute)
					preview.headers[i].members[j].losttext:SetShadowColor(0, 0, 0)
					if IRF3.db.font.shadow then
						preview.headers[i].members[j].name:SetShadowOffset(1, -1)
						preview.headers[i].members[j].losttext:SetShadowOffset(1, -1)
					else
						preview.headers[i].members[j].name:SetShadowOffset(0, 0)
						preview.headers[i].members[j].losttext:SetShadowOffset(0, 0)
					end
					if IRF3.db.units.className then
						preview.headers[i].members[j].name:SetTextColor(IRF3.db.colors[preview.headers[i].members[j].class][1], IRF3.db.colors[preview.headers[i].members[j].class][2], IRF3.db.colors[preview.headers[i].members[j].class][3])
					else
						preview.headers[i].members[j].name:SetTextColor(IRF3.db.colors.name[1], IRF3.db.colors.name[2], IRF3.db.colors.name[3])
					end
					if IRF3.db.units.useClassColors then
						preview.headers[i].members[j].healthBar:SetVertexColor(IRF3.db.colors[preview.headers[i].members[j].class][1], IRF3.db.colors[preview.headers[i].members[j].class][2], IRF3.db.colors[preview.headers[i].members[j].class][3])
					else
						preview.headers[i].members[j].healthBar:SetVertexColor(IRF3.db.colors.help[1], IRF3.db.colors.help[2], IRF3.db.colors.help[3])
					end
					preview.headers[i].members[j].powerBar:SetTexture(statusBarTexture)
					preview.headers[i].members[j].powerBar:SetVertexColor(IRF3.db.colors[preview.headers[i].members[j].powerBar.color][1], IRF3.db.colors[preview.headers[i].members[j].powerBar.color][2], IRF3.db.colors[preview.headers[i].members[j].powerBar.color][3])
					IRF3.headers[0].members[1].SetupPowerBar(preview.headers[i].members[j])
					if IRF3.db.usePet == 2 then
						preview.headers[i].members[j].petButton:SetHeight(IRF3.db.petHeight)
						preview.headers[i].members[j].petButton:Show()
						if IRF3.db.anchor:find("TOP") then
							preview.headers[i].members[j].petButton:ClearAllPoints()
							preview.headers[i].members[j].petButton:SetPoint("TOPLEFT", preview.headers[i].members[j], "BOTTOMLEFT", 0, 0)
							preview.headers[i].members[j].petButton:SetPoint("TOPRIGHT", preview.headers[i].members[j], "BOTTOMRIGHT", 0, 0)
							preview.headers[i].members[j].petButton.powerBar:SetPoint("BOTTOMRIGHT", 0, 0)
							preview.headers[i].members[j].petButton.healthBar:SetPoint("TOPLEFT", 0, -1)
						else
							preview.headers[i].members[j].petButton:ClearAllPoints()
							preview.headers[i].members[j].petButton:SetPoint("BOTTOMLEFT", preview.headers[i].members[j], "TOPLEFT", 0, 0)
							preview.headers[i].members[j].petButton:SetPoint("BOTTOMRIGHT", preview.headers[i].members[j], "TOPRIGHT", 0, 0)
							preview.headers[i].members[j].petButton.powerBar:SetPoint("BOTTOMRIGHT", 0, 1)
							preview.headers[i].members[j].petButton.healthBar:SetPoint("TOPLEFT", 0, 0)
						end
						preview.headers[i].members[j].petButton.healthBar:SetTexture(statusBarTexture)
						preview.headers[i].members[j].petButton.healthBar:SetVertexColor(IRF3.db.colors.pet[1], IRF3.db.colors.pet[2], IRF3.db.colors.pet[3])
						preview.headers[i].members[j].petButton.powerBar:SetTexture(statusBarTexture)
						preview.headers[i].members[j].petButton.powerBar:SetVertexColor(IRF3.db.colors[preview.headers[i].members[j].petButton.powerBar.color][1], IRF3.db.colors[preview.headers[i].members[j].petButton.powerBar.color][2], IRF3.db.colors[preview.headers[i].members[j].petButton.powerBar.color][3])
					else
						preview.headers[i].members[j].petButton:SetHeight(0.001)
						preview.headers[i].members[j].petButton:Hide()
					end
				end
			else
				preview.headers[i]:Hide()
			end
		end
		preview:UpdatePosition(IRF3, preview.headers, LIST, "updateposition")
		if IRF3.db.usePet == 3 then
			preview.petHeader:Show()
			preview.petHeader.border:SetBackdropColor(unpack(IRF3.db.borderBackdrop))
			preview.petHeader.border:SetBackdropBorderColor(unpack(IRF3.db.borderBackdropBorder))
			preview.petHeader:SetScale(IRF3.db.petscale)
			preview.petHeader:ClearAllPoints()
			preview.petHeader:SetPoint(IRF3.db.petanchor, IRF3.petHeader, IRF3.db.petanchor, 0, 0)
			o1 = IRF3.db.petanchor:find("LEFT") and 1 or -1
			o2 = IRF3.db.petanchor:find("TOP") and -1 or 1
			p1, p2 = 0, 0
			for i = 1, members do
				preview.petHeader.members[i].healthBar:SetTexture(statusBarTexture)
				preview.petHeader.members[i].name:SetFont(fontFile, IRF3.db.font.size, IRF3.db.font.attribute)
				preview.petHeader.members[i].name:SetShadowColor(0, 0, 0)
				preview.petHeader.members[i].losttext:SetFont(fontFile, IRF3.db.font.size, IRF3.db.font.attribute)
				preview.petHeader.members[i].losttext:SetShadowColor(0, 0, 0)
				if IRF3.db.font.shadow then
					preview.petHeader.members[i].name:SetShadowOffset(1, -1)
					preview.petHeader.members[i].losttext:SetShadowOffset(1, -1)
				else
					preview.petHeader.members[i].name:SetShadowOffset(0, 0)
					preview.petHeader.members[i].losttext:SetShadowOffset(0, 0)
				end
				if IRF3.db.units.className then
					preview.petHeader.members[i].name:SetTextColor(IRF3.db.colors[preview.petHeader.members[i].class][1], IRF3.db.colors[preview.petHeader.members[i].class][2], IRF3.db.colors[preview.petHeader.members[i].class][3])
				else
					preview.petHeader.members[i].name:SetTextColor(IRF3.db.colors.name[1], IRF3.db.colors.name[2], IRF3.db.colors.name[3])
				end
				if IRF3.db.units.useClassColors then
					preview.petHeader.members[i].healthBar:SetVertexColor(IRF3.db.colors[preview.petHeader.members[i].class][1], IRF3.db.colors[preview.petHeader.members[i].class][2], IRF3.db.colors[preview.petHeader.members[i].class][3])
				else
					preview.petHeader.members[i].healthBar:SetVertexColor(IRF3.db.colors.help[1], IRF3.db.colors.help[2], IRF3.db.colors.help[3])
				end
				preview.petHeader.members[i].powerBar:SetTexture(statusBarTexture)
				preview.petHeader.members[i].powerBar:SetVertexColor(IRF3.db.colors[preview.petHeader.members[i].powerBar.color][1], IRF3.db.colors[preview.petHeader.members[i].powerBar.color][2], IRF3.db.colors[preview.petHeader.members[i].powerBar.color][3])
				IRF3.headers[0].members[1].SetupPowerBar(preview.petHeader.members[i])
				if i == 1 then
					width, height = 0, 0
				elseif IRF3.db.petcolumn == 1 or i % IRF3.db.petcolumn == 1 then
					if IRF3.db.petdir == 1 then
						width, height = width + IRF3.db.width + IRF3.db.offset, 0
					else
						width, height = 0, height + IRF3.db.height + IRF3.db.offset
					end
				elseif IRF3.db.petdir == 1 then
					height = height + IRF3.db.height + IRF3.db.offset
				else
					width = width + IRF3.db.width + IRF3.db.offset
				end
				p1 = max(p1, width)
				p2 = max(p2, height)
				preview.petHeader.members[i]:SetSize(IRF3.db.width, IRF3.db.height)
				preview.petHeader.members[i]:ClearAllPoints()
				preview.petHeader.members[i]:SetPoint(IRF3.db.petanchor, preview.petHeader, IRF3.db.petanchor, width * o1, height * o2)
				preview.petHeader.members[i]:Show()
			end
			for i = members + 1, 40 do
				preview.petHeader.members[i]:Hide()
			end
			preview.petHeader:SetSize(p1 + IRF3.db.width, p2 + IRF3.db.height)
		else
			preview.petHeader:Hide()
		end

	else
		if not InCombatLockdown() then
			IRF3:SetAttribute("preview", nil)
		end
		if preview then
			preview.show = nil
			preview:Hide()
			Option.previewDropdown:Update()
		end
	end
end

function Option:UpdatePreview()
	if self:GetPreviewState() > 1 then
		self:SetPreview(preview.show)
	end
end

function Option:GetPreviewState()
	if not InCombatLockdown() and preview and preview.show then
		return preview.show
	else
		return 1
	end
end