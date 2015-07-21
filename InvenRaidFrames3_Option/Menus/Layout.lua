local IRF3 = InvenRaidFrames3
local Option = IRF3.optionFrame
local LBO = LibStub("LibBlueOption-1.0")
local SM = LibStub("LibSharedMedia-3.0")

local _G = _G
local pairs = _G.pairs
local ipairs = _G.ipairs
local unpack = _G.unpack

function Option:CreateFrameMenu(menu, parent)
	local function updateTexture(member)
		member:SetupTexture()
		if member:IsVisible() then
			InvenRaidFrames3Member_UpdateState(member)
			InvenRaidFrames3Member_UpdatePowerColor(member)
		end
		if member.petButton and member.petButton:IsVisible() then
			InvenRaidFrames3Member_UpdateState(member.petButton)
			InvenRaidFrames3Member_UpdatePowerColor(member.petButton)
		end
	end
	menu.texture = LBO:CreateWidget("Media", parent, "바 텍스쳐", "바 텍스쳐를 설정합니다.", nil, nil, nil,
		function() return IRF3.db.units.texture, "statusbar" end,
		function(v)
			IRF3.db.units.texture = v
			Option:UpdateMember(updateTexture)
			Option:UpdatePreview()
		end
	)
	menu.texture:SetPoint("TOPLEFT", 5, -5)
	menu.scale = LBO:CreateWidget("Slider", parent, "크기", "프레임의 전체적인 크기를 조절합니다.", nil, nil, true,
		function()
			return IRF3.db.scale * 100, 50, 150, 1, "%"
		end,
		function(v)
			IRF3.db.scale = v / 100
			IRF3:LoadPosition()
			if Option.preview then
				Option.preview:SetScale(IRF3.db.scale)
			end
		end
	)
	menu.scale:SetPoint("TOPRIGHT", -5, -5)

	menu.width = LBO:CreateWidget("Slider", parent, "너비", "프레임의 너비를 조절합니다.", nil, nil, true,
		function()
			return IRF3.db.width, 32, 256, 1, "픽셀"
		end,
		function(v)
			IRF3.db.width = v
			IRF3.nameWidth = v - 2
			IRF3:SetWidth(v)
			IRF3:SetAttribute("width", v)
			for _, header in pairs(IRF3.headers) do
				header:SetWidth(v)
				for _, member in pairs(header.members) do
					member:SetWidth(v)
					member:SetupPowerBar()
					member:SetupBarOrientation()
				end
				if header:IsVisible() then
					header:Hide()
					header:Show()
				end
			end
			for _, member in pairs(IRF3.petHeader.members) do
				member:SetWidth(v)
				member:SetupPowerBar()
				member:SetupBarOrientation()
			end
			if IRF3.petHeader:IsVisible() then
				IRF3.petHeader:Hide()
				IRF3.petHeader:Show()
			end
			Option:UpdatePreview()
		end
	)
	menu.width:SetPoint("TOP", menu.texture, "BOTTOM", 0, -10)
	menu.height = LBO:CreateWidget("Slider", parent, "높이", "프레임의 높이를 조절합니다.", nil, nil, true,
		function()
			return IRF3.db.height, 25, 256, 1, "픽셀"
		end,
		function(v)
			IRF3.db.height = v
			IRF3:SetHeight(v)
			IRF3:SetAttribute("height", v)
			for _, header in pairs(IRF3.headers) do
				for _, member in pairs(header.members) do
					member:SetHeight(v)
					member:SetupPowerBar()
					member:SetupBarOrientation()
				end
				if header:IsVisible() then
					header:Hide()
					header:Show()
				end
			end
			for _, member in pairs(IRF3.petHeader.members) do
				member:SetHeight(v)
				member:SetupPowerBar()
				member:SetupBarOrientation()
			end
			if IRF3.petHeader:IsVisible() then
				IRF3.petHeader:Hide()
				IRF3.petHeader:Show()
			end
			IRF3:SetAttribute("updateposition", not IRF3:GetAttribute("updateposition"))
			Option:UpdatePreview()
		end
	)
	menu.height:SetPoint("TOP", menu.scale, "BOTTOM", 0, -10)
	menu.offset = LBO:CreateWidget("Slider", parent, "간격", "각 플레이어 간의 간격을 조절합니다.", nil, nil, true,
		function()
			return IRF3.db.offset, 0, 30, 1, "픽셀"
		end,
		function(v)
			IRF3.db.offset = v
			Option:SetOption("offset", v)
			Option:UpdatePreview()
		end
	)
	menu.offset:SetPoint("TOP", menu.width, "BOTTOM", 0, -10)
	menu.highlightAlpha = LBO:CreateWidget("Slider", parent, "하이라이트 투명도", "프레임에 마우스를 올렸을때 나오는 하이라이트 텍스쳐의 투명도를 설정합니다. 0으로 설정하면 보이지 않습니다.", nil, nil, nil,
		function()
			return IRF3.db.highlightAlpha * 100, 0, 100, 1, "%"
		end,
		function(v)
			IRF3.db.highlightAlpha = v / 100

		end
	)
	menu.highlightAlpha:SetPoint("TOP", menu.height, "BOTTOM", 0, -10)
	local function updateBG(member)
		member.background:SetTexture(IRF3.db.units.backgroundColor[1], IRF3.db.units.backgroundColor[2], IRF3.db.units.backgroundColor[3], IRF3.db.units.backgroundColor[4])
		if member.petButton then
			updateBG(member.petButton)
		end
	end
	menu.color = LBO:CreateWidget("ColorPicker", parent, "배경 색상", "각 플레이어 프레임의 뒷 배경 색상 및 투명도를 설정합니다.", nil, nil, nil,
		function()
			return IRF3.db.units.backgroundColor[1], IRF3.db.units.backgroundColor[2], IRF3.db.units.backgroundColor[3], IRF3.db.units.backgroundColor[4]
		end,
		function(r, g, b, a)
			IRF3.db.units.backgroundColor[1], IRF3.db.units.backgroundColor[2], IRF3.db.units.backgroundColor[3], IRF3.db.units.backgroundColor[4] = r, g, b, a
			Option:UpdateMember(updateBG)
		end
	)
	menu.color:SetPoint("TOP", menu.offset, "BOTTOM", 0, -10)
end

function Option:CreateHealthBarMenu(menu, parent)
	local orientationList = { "가로", "세로" }
	local function updateOrientation(member)

	end
	menu.orientation = LBO:CreateWidget("DropDown", parent, "체력바 방향", "체력바의 진행 방향을 설정합니다.", nil, nil, nil,
		function()
			return IRF3.db.units.orientation, orientationList
		end,
		function(v)
			IRF3.db.units.orientation = v
			Option:UpdateMember(IRF3.headers[0].members[1].SetupBarOrientation)
		end
	)
	menu.orientation:SetPoint("TOPLEFT", 5, -5)
	local function updateColor(member)
		if member:IsVisible() then
			InvenRaidFrames3Member_UpdateState(member)
			if member.petButton and member.petButton:IsVisible() then
				InvenRaidFrames3Member_UpdateState(member.petButton)
			end
		end
	end
	menu.classColor = LBO:CreateWidget("CheckBox", parent, "직업별 체력바 색상", "직업별 색상에 따라 체력바 색상을 변경합니다.", nil, nil, nil,
		function()
			return IRF3.db.units.useClassColors
		end,
		function(v)
			IRF3.db.units.useClassColors = v
			Option:UpdateMember(updateColor)
			Option:UpdatePreview()
		end
	)
	menu.classColor:SetPoint("TOPRIGHT", -5, -5)
	menu.reset = LBO:CreateWidget("Button", parent, "색상 초기화", "설정한 색상을 초기값으로 되돌립니다.", nil, nil, nil,
		function()
			IRF3.db.colors.help[1], IRF3.db.colors.help[2], IRF3.db.colors.help[3] = 0, 1, 0
			IRF3.db.colors.harm[1], IRF3.db.colors.harm[2], IRF3.db.colors.harm[3] = 0.5, 0, 0
			IRF3.db.colors.vehicle[1], IRF3.db.colors.vehicle[2], IRF3.db.colors.vehicle[3] = 0, 0.4, 0
			IRF3.db.colors.pet[1], IRF3.db.colors.pet[2], IRF3.db.colors.pet[3] = 0, 1, 0
			IRF3.db.colors.offline[1], IRF3.db.colors.offline[2], IRF3.db.colors.offline[3] = 0.25, 0.25, 0.25
			for class, color in pairs(RAID_CLASS_COLORS) do
				if IRF3.db.colors[class] then
					IRF3.db.colors[class][1], IRF3.db.colors[class][2], IRF3.db.colors[class][3] = color.r, color.g, color.b
				end
			end
			Option:UpdateMember(updateColor)
			Option:UpdatePreview()
			LBO:Refresh(parent)
		end
	)
	menu.reset:SetPoint("TOP", menu.orientation, "BOTTOM", 0, -5)
	local colorList = { "help", "harm", "pet", "vehicle", "offline", "WARRIOR", "ROGUE", "PRIEST", "MAGE", "WARLOCK", "HUNTER", "DRUID", "SHAMAN", "PALADIN", "DEATHKNIGHT", "MONK" }
	local colorLocale = { "우호적 대상", "적대적 대상", "소환수", "탈것 탑승 시", "오프라인일 때", "전사", "도적", "사제", "마법사", "흑마법사", "사냥꾼", "드루이드", "주술사", "성기사", "죽음의 기사", "수도사" }
	local function getColor(color)
		return IRF3.db.colors[color][1], IRF3.db.colors[color][2], IRF3.db.colors[color][3]
	end
	local function setColor(r, g, b, color)
		IRF3.db.colors[color][1], IRF3.db.colors[color][2], IRF3.db.colors[color][3] = r, g, b
		Option:UpdateMember(updateColor)
		Option:UpdatePreview()
	end
	for i, color in ipairs(colorList) do
		menu["color"..i] = LBO:CreateWidget("ColorPicker", parent, colorLocale[i], colorLocale[i].."의 색상을 변경합니다.", nil, nil, nil, getColor, setColor, color)
		if i == 1 then
			menu["color"..i]:SetPoint("TOP", menu.reset, "BOTTOM", 0, 15)
		elseif i == 2 then
			menu["color"..i]:SetPoint("TOP", menu.color1, 0, 0)
			menu["color"..i]:SetPoint("RIGHT", -5, 0)
		else
			menu["color"..i]:SetPoint("TOP", menu["color"..(i - 2)], "BOTTOM", 0, 14)
		end
	end
end

function Option:CreateManaBarMenu(menu, parent)
	local posList = { "상단", "하단", "좌측", "우측" }
	menu.pos = LBO:CreateWidget("DropDown", parent, "마나바 위치", "마나바의 위치를 설정합니다.", nil, nil, nil,
		function()
			return IRF3.db.units.powerBarPos, posList
		end,
		function(v)
			IRF3.db.units.powerBarPos = v
			Option:UpdateMember(IRF3.headers[0].members[1].SetupPowerBar)
			Option:UpdatePreview()
		end
	)
	menu.pos:SetPoint("TOPLEFT", 5, -5)
	menu.height = LBO:CreateWidget("Slider", parent, "크기 비율", "마나바의 크기 비율을 설정합니다. 0%로 설정하면 마나바가 숨겨지며 100%로 설정하면 체력바가 숨겨집니다.", nil, nil, nil,
		function()
			return IRF3.db.units.powerBarHeight * 100, 0, 100, 1, "%"
		end,
		function(v)
			IRF3.db.units.powerBarHeight = v / 100
			Option:UpdateMember(IRF3.headers[0].members[1].SetupPowerBar)
			Option:UpdatePreview()
		end
	)
	menu.height:SetPoint("TOPRIGHT", -5, -5)
	local colorList = { "MANA", "RAGE", "FOCUS", "ENERGY", "RUNIC_POWER" }
	local function updateColor(member)
		if member:IsVisible() then
			InvenRaidFrames3Member_UpdatePowerColor(member)
			if member.petButton and member.petButton:IsVisible() then
				InvenRaidFrames3Member_UpdatePowerColor(member.petButton)
			end
		end
	end
	menu.reset = LBO:CreateWidget("Button", parent, "색상 초기화", "설정한 색상을 초기값으로 되돌립니다.", nil, nil, nil,
		function()
			for _, color in pairs(colorList) do
				IRF3.db.colors[color][1], IRF3.db.colors[color][2], IRF3.db.colors[color][3] = PowerBarColor[color].r, PowerBarColor[color].g, PowerBarColor[color].b
			end
			Option:UpdateMember(updateColor)
			Option:UpdatePreview()
			LBO:Refresh(parent)
		end
	)
	menu.reset:SetPoint("TOP", menu.pos, "BOTTOM", 0, -5)
	local function getColor(color)
		return IRF3.db.colors[color][1], IRF3.db.colors[color][2], IRF3.db.colors[color][3]
	end
	local function setColor(r, g, b, color)
		IRF3.db.colors[color][1], IRF3.db.colors[color][2], IRF3.db.colors[color][3] = r, g, b
		Option:UpdateMember(updateColor)
		Option:UpdatePreview()
	end
	for i, color in ipairs(colorList) do
		menu["color"..i] = LBO:CreateWidget("ColorPicker", parent, _G[color], _G[color].."의 색상을 변경합니다.", nil, nil, nil, getColor, setColor, color)
		if i == 1 then
			menu["color"..i]:SetPoint("TOP", menu.reset, "BOTTOM", 0, 15)
		elseif i == 2 then
			menu["color"..i]:SetPoint("TOP", menu.color1, 0, 0)
			menu["color"..i]:SetPoint("RIGHT", -5, 0)
		else
			menu["color"..i]:SetPoint("TOP", menu["color"..(i - 2)], "BOTTOM", 0, 14)
		end
	end
end

function Option:CreateNameMenu(menu, parent)
	local function updateFont(member)
		member.name:SetFont(SM:Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
		member.name:SetShadowColor(0, 0, 0)
		member.losttext:SetFont(SM:Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
		member.losttext:SetShadowColor(0, 0, 0)
		if IRF3.db.font.shadow then
			member.name:SetShadowOffset(1, -1)
			member.losttext:SetShadowOffset(1, -1)
		else
			member.name:SetShadowOffset(0, 0)
			member.losttext:SetShadowOffset(0, 0)
		end
		if member:IsVisible() then
			InvenRaidFrames3Member_UpdateName(member)
			InvenRaidFrames3Member_UpdateDisplayText(member)
			InvenRaidFrames3Member_SetAuraFont(member)
		end
	end
	menu.file = LBO:CreateWidget("Font", parent, "이름 글꼴 설정", "이름 글꼴을 변경합니다.", nil, nil, nil,
		function()
			return IRF3.db.font.file, IRF3.db.font.size, IRF3.db.font.attribute, IRF3.db.font.shadow
		end,
		function(file, size, attribute, shadow)
			IRF3.db.font.file, IRF3.db.font.size, IRF3.db.font.attribute, IRF3.db.font.shadow = file, size, attribute, shadow
			IRF3:UpdateFont()
			IRF3:UpdateSpellTimerFont()
			Option:UpdateMember(updateFont)
			Option:UpdatePreview()
		end
	)
	menu.file:SetPoint("TOPLEFT", 5, -5)
	local function updateName(member)
		if member:IsVisible() then
			InvenRaidFrames3Member_UpdateNameColor(member)
		end
	end
	local function getClassColorName()
		return IRF3.db.units.className
	end
	menu.classColor = LBO:CreateWidget("CheckBox", parent, "직업별 이름 색상 사용", "이름 색상을 직업 색상으로 표시합니다.", nil, nil, nil,
		function() return IRF3.db.units.className end,
		function(v)
			IRF3.db.units.className = v
			Option:UpdateMember(updateName)
			Option:UpdatePreview()
			LBO:Refresh(parent)
		end
	)
	menu.classColor:SetPoint("TOP", menu.file, "BOTTOM", 0, -10)
	menu.color = LBO:CreateWidget("ColorPicker", parent, "이름 색상", "이름 색상을 설정합니다. 직업별 색상 사용시 적용되지 않습니다.", nil, nil, nil,
		function()
			return IRF3.db.colors.name[1], IRF3.db.colors.name[2], IRF3.db.colors.name[3]
		end,
		function(r, g, b)
			IRF3.db.colors.name[1], IRF3.db.colors.name[2], IRF3.db.colors.name[3] = r, g, b
			Option:UpdateMember(updateName)
			Option:UpdatePreview()
		end
	)
	menu.color:SetPoint("TOPRIGHT", -5, -60)
	menu.outRangeName = LBO:CreateWidget("CheckBox", parent, "먼 사정거리 직업별 이름 색상 사용", "사정거리가 벗어난 플레이어의 이름 색상을 직업 색상으로 표시합니다.", nil, nil, nil,
		function()
			return IRF3.db.units.outRangeName
		end,
		function(v)
			IRF3.db.units.outRangeName = v
			Option:UpdateMember(updateName)
			Option:UpdatePreview()
		end
	)
	menu.outRangeName:SetPoint("TOP", menu.classColor, "BOTTOM", 0, 0)
	menu.deathName = LBO:CreateWidget("CheckBox", parent, "죽은 플레이어 직업별 이름 색상 사용", "죽거나 유령인 플레이어의 이름 색상을 직업별 색상으로 표시합니다.", nil, nil, nil,
		function()
			return IRF3.db.units.deathName
		end,
		function(v)
			IRF3.db.units.deathName = v
			Option:UpdateMember(updateName)
			Option:UpdatePreview()
		end
	)
	menu.deathName:SetPoint("TOP", menu.outRangeName, "BOTTOM", 0, 0)
	menu.offlineName = LBO:CreateWidget("CheckBox", parent, "오프라인 플레이어 직업별 이름 색상 사용", "오프라인인 플레이어의 이름 색상을 직업별 색상으로 표시합니다.", nil, nil, nil,
		function()
			return IRF3.db.units.offlineName
		end,
		function(v)
			IRF3.db.units.offlineName = v
			Option:UpdateMember(updateName)
			Option:UpdatePreview()
		end
	)
	menu.offlineName:SetPoint("TOP", menu.deathName, "BOTTOM", 0, 0)
end

function Option:CreatePartyTagMenu(menu, parent)
	menu.use = LBO:CreateWidget("CheckBox", parent, "파티 이름표 보기", "공격대 각 파티의 이름표를 표시합니다.", nil, nil, true,
		function() return IRF3.db.partyTag end,
		function(v)
			IRF3.db.partyTag = v
			IRF3:UpdateGroupFilter()
			LBO:Refresh(parent)
		end
	)
	local function disabled()
		return not IRF3.db.partyTag
	end
	menu.use:SetPoint("TOPLEFT", 5, 5)
	menu.myParty = LBO:CreateWidget("ColorPicker", parent, "내 파티 이름표 색상", "자기 자신이 속한 파티의 이름표 배경 색상을 설정합니다.", nil, disabled, nil,
		function() return IRF3.db.partyTagParty[1], IRF3.db.partyTagParty[2], IRF3.db.partyTagParty[3], IRF3.db.partyTagParty[4] end,
		function(r, g, b, a)
			IRF3.db.partyTagParty[1], IRF3.db.partyTagParty[2], IRF3.db.partyTagParty[3], IRF3.db.partyTagParty[4] = r, g, b, a
			IRF3.headers[0].partyTag.tex:SetTexture(r, g, b, a)
			if IRF3.playerGroup then
				IRF3.headers[IRF3.playerGroup].partyTag.tex:SetTexture(r, g, b, a)
			end
			Option:UpdatePreview()
		end
	)
	menu.myParty:SetPoint("TOP", menu.use, "BOTTOM", 0, 0)
	menu.otherParty = LBO:CreateWidget("ColorPicker", parent, "파티 이름표 색상", "파티의 이름표 배경 색상을 설정합니다.", nil, disabled, nil,
		function() return IRF3.db.partyTagRaid[1], IRF3.db.partyTagRaid[2], IRF3.db.partyTagRaid[3], IRF3.db.partyTagRaid[4] end,
		function(r, g, b, a)
			IRF3.db.partyTagRaid[1], IRF3.db.partyTagRaid[2], IRF3.db.partyTagRaid[3], IRF3.db.partyTagRaid[4] = r, g, b, a
			for i = 1, 8 do
				if i ~= IRF3.playerGroup then
					IRF3.headers[IRF3.playerGroup].partyTag.tex:SetTexture(r, g, b, a)
				end
			end
			Option:UpdatePreview()
		end
	)
	menu.otherParty:SetPoint("TOP", menu.myParty, "TOP", 0, 0)
	menu.otherParty:SetPoint("RIGHT", -5, 0)
end

function Option:CreateBorderMenu(menu, parent)
	menu.use = LBO:CreateWidget("CheckBox", parent, "배경 테두리 보기", "공격대 프레임 전체를 둘러싸는 테두리를 보입니다.", nil, nil, nil,
		function() return IRF3.db.border end,
		function(v)
			IRF3.db.border = v
			IRF3:BorderUpdate(true)
			LBO:Refresh(parent)
			if Option:GetPreviewState() > 1 then
				Option.preview:CallMethod("BorderUpdate")
			end
		end
	)
	menu.use:SetPoint("TOPLEFT", 5, 5)
	local function disable()
		return not IRF3.db.border
	end
	local function updateColor()
		IRF3.border:SetBackdropColor(IRF3.db.borderBackdrop[1], IRF3.db.borderBackdrop[2], IRF3.db.borderBackdrop[3], IRF3.db.borderBackdrop[4])
		IRF3.border:SetBackdropBorderColor(IRF3.db.borderBackdropBorder[1], IRF3.db.borderBackdropBorder[2], IRF3.db.borderBackdropBorder[3], IRF3.db.borderBackdropBorder[4])
		IRF3.petHeader.border:SetBackdropColor(IRF3.db.borderBackdrop[1], IRF3.db.borderBackdrop[2], IRF3.db.borderBackdrop[3], IRF3.db.borderBackdrop[4])
		IRF3.petHeader.border:SetBackdropBorderColor(IRF3.db.borderBackdropBorder[1], IRF3.db.borderBackdropBorder[2], IRF3.db.borderBackdropBorder[3], IRF3.db.borderBackdropBorder[4])
		if Option:GetPreviewState() > 1 then
			Option.preview.border:SetBackdropColor(IRF3.db.borderBackdrop[1], IRF3.db.borderBackdrop[2], IRF3.db.borderBackdrop[3], IRF3.db.borderBackdrop[4])
			Option.preview.border:SetBackdropBorderColor(IRF3.db.borderBackdropBorder[1], IRF3.db.borderBackdropBorder[2], IRF3.db.borderBackdropBorder[3], IRF3.db.borderBackdropBorder[4])
			Option.preview.petHeader.border:SetBackdropColor(IRF3.db.borderBackdrop[1], IRF3.db.borderBackdrop[2], IRF3.db.borderBackdrop[3], IRF3.db.borderBackdrop[4])
			Option.preview.petHeader.border:SetBackdropBorderColor(IRF3.db.borderBackdropBorder[1], IRF3.db.borderBackdropBorder[2], IRF3.db.borderBackdropBorder[3], IRF3.db.borderBackdropBorder[4])
		end
	end
	menu.reset = LBO:CreateWidget("Button", parent, "색상 초기화", "설정한 색상을 초기값으로 되돌립니다.", nil, disable, nil,
		function()
			IRF3.db.borderBackdrop[1], IRF3.db.borderBackdrop[2], IRF3.db.borderBackdrop[3], IRF3.db.borderBackdrop[4] = 0, 0, 0, 0.58
			IRF3.db.borderBackdropBorder[1], IRF3.db.borderBackdropBorder[2], IRF3.db.borderBackdropBorder[3], IRF3.db.borderBackdropBorder[4] = 0.58, 0.58, 0.58, 1
			updateColor()
			LBO:Refresh(parent)
		end
	)
	menu.reset:SetPoint("TOPRIGHT", -5, 5)
	menu.backdrop = LBO:CreateWidget("ColorPicker", parent, "배경 테두리 내부 색상", "공격대 프레임 전체를 둘러싸는 테두리의 내부 색상 및 투명도를 조절합니다.", nil, disable, nil,
		function()
			return IRF3.db.borderBackdrop[1], IRF3.db.borderBackdrop[2], IRF3.db.borderBackdrop[3], IRF3.db.borderBackdrop[4]
		end,
		function(r, g, b, a)
			IRF3.db.borderBackdrop[1], IRF3.db.borderBackdrop[2], IRF3.db.borderBackdrop[3], IRF3.db.borderBackdrop[4] = r, g, b, a
			updateColor()
		end
	)
	menu.backdrop:SetPoint("TOP", menu.use, "BOTTOM", 0, 0)
	menu.border = LBO:CreateWidget("ColorPicker", parent, "배경 테두리 내부 색상", "공격대 프레임 전체를 둘러싸는 테두리의 내부 색상 및 투명도를 조절합니다.", nil, disable, nil,
		function()
			return IRF3.db.borderBackdropBorder[1], IRF3.db.borderBackdropBorder[2], IRF3.db.borderBackdropBorder[3], IRF3.db.borderBackdropBorder[4]
		end,
		function(r, g, b, a)
			IRF3.db.borderBackdropBorder[1], IRF3.db.borderBackdropBorder[2], IRF3.db.borderBackdropBorder[3], IRF3.db.borderBackdropBorder[4] = r, g, b, a
			updateColor()
		end
	)
	menu.border:SetPoint("TOP", menu.reset, "BOTTOM", 0, 0)
end

function Option:CreateDebuffColorMenu(menu, parent)
	local function update(member)
		if member:IsVisible() then
			InvenRaidFrames3Member_UpdateAura(member)
			InvenRaidFrames3Member_UpdateState(member)
			InvenRaidFrames3Member_UpdateOutline(member)
			if member.petButton then
				update(member.petButton)
			end
		end
	end
	menu.reset = LBO:CreateWidget("Button", parent, "색상 초기화", "설정한 색상을 초기값으로 되돌립니다.", nil, nil, nil,
		function()
			IRF3.db.colors.Magic[1], IRF3.db.colors.Magic[2], IRF3.db.colors.Magic[3] = DebuffTypeColor.Magic.r, DebuffTypeColor.Magic.g, DebuffTypeColor.Magic.b
			IRF3.db.colors.Curse[1], IRF3.db.colors.Curse[2], IRF3.db.colors.Curse[3] = DebuffTypeColor.Curse.r, DebuffTypeColor.Curse.g, DebuffTypeColor.Curse.b
			IRF3.db.colors.Disease[1], IRF3.db.colors.Disease[2], IRF3.db.colors.Disease[3] = DebuffTypeColor.Disease.r, DebuffTypeColor.Disease.g, DebuffTypeColor.Disease.b
			IRF3.db.colors.Poison[1], IRF3.db.colors.Poison[2], IRF3.db.colors.Poison[3] = DebuffTypeColor.Poison.r, DebuffTypeColor.Poison.g, DebuffTypeColor.Poison.b
			IRF3.db.colors.none[1], IRF3.db.colors.none[2], IRF3.db.colors.none[3] = DebuffTypeColor.none.r, DebuffTypeColor.none.g, DebuffTypeColor.none.b
			Option:UpdateMember(update)
			LBO:Refresh(parent)
		end
	)
	menu.reset:SetPoint("TOPLEFT", 5, 2)
	local function getColor(color)
		return IRF3.db.colors[color][1], IRF3.db.colors[color][2], IRF3.db.colors[color][3]
	end
	local function setColor(r, g, b, color)
		IRF3.db.colors[color][1], IRF3.db.colors[color][2], IRF3.db.colors[color][3] = r, g, b
		Option:UpdateMember(update)
	end
	local colorList = { "Magic", "Curse", "Disease", "Poison", "none" }
	local colorLocale = { "마법", "저주", "질병", "독", "무속성" }
	for i, color in ipairs(colorList) do
		menu["color"..i] = LBO:CreateWidget("ColorPicker", parent, colorLocale[i], colorLocale[i].." 디버프의 색상을 변경합니다.", nil, nil, nil, getColor, setColor, color)
		if i == 1 then
			menu["color"..i]:SetPoint("TOP", menu.reset, "BOTTOM", 0, 15)
		elseif i == 2 then
			menu["color"..i]:SetPoint("TOP", menu.color1, 0, 0)
			menu["color"..i]:SetPoint("RIGHT", -5, 0)
		else
			menu["color"..i]:SetPoint("TOP", menu["color"..(i - 2)], "BOTTOM", 0, 14)
		end
	end
end