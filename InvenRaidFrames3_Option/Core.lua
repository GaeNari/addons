local IRF3 = InvenRaidFrames3
local Option = IRF3.optionFrame
Option.loaded = true
Option:SetScript("OnShow", nil)
Option:UnregisterAllEvents()
Option:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
--Option:RegisterEvent("ADDON_LOADED")

local _G = _G
local type = _G.type
local pairs = _G.pairs
local ipairs = _G.ipairs
local sort = _G.table.sort
local twipe = _G.table.wipe
local tinsert = _G.table.insert
local tremove = _G.table.remove
local CreateFrame = _G.CreateFrame
local LBO = LibStub("LibBlueOption-1.0")

local tabList = { "기본", "외형", "기능" }
local menuOnClick = function(id) Option:ShowDetailMenu(id) end
local menuList = {
	["기본"] = {
		{ name = "사용", desc = "애드온 사용에 관한 설정을 합니다.", func = menuOnClick, create = "Use" },
		{ name = "정렬 및 배치", desc = "공격대 그룹의 정렬과 배치에 관한 설정을 합니다. 미리보기 기능을 통해 보다 쉽게 해당 설정을 할 수 있습니다.", func = menuOnClick, create = "Group" },
		{ name = "소환수", desc = "각 공격대원 프레임의 하단에 있는 소환수 프레임을 설정합니다.", func = menuOnClick, create = "Pet" },
		{ name = "클릭 캐스팅", desc = "각 공격대원 프레임에 마우스 버튼과 Alt, Shift, Ctrl의 조합으로 주문을 시전할 수 있는 클릭 캐스팅 설정을 합니다. (참고: 대체된 주문인 경우 표시되는 주문과 마법책 메뉴에 선택되어 있는 주문이 다를 수 있으며, 실제 선택되어 있는 주문이 시전됩니다.)", func = menuOnClick, create = "ClickCasting", disableScroll = true },
		{ name = "프로필 관리", desc = "캐릭터 별로 자신이 설정한 프로필로 간단히 변경 가능하게 해줍니다.", func = menuOnClick, create = "Profile", disableScroll = true },
	},
	["외형"] = {
		{ name = "프레임", desc = "각 공격대원 프레임의 외형을 설정합니다.", func = menuOnClick, create = "Frame" },
		{ name = "체력바 및 직업 색상", desc = "각 공격대원 프레임의 체력바 외형과 직업 색상을 설정합니다.", func = menuOnClick, create = "HealthBar" },
		{ name = "마나바", desc = "각 공격대원 프레임의 마나바 외형을 설정합니다.", func = menuOnClick, create = "ManaBar" },
		{ name = "이름", desc = "각 공격대원 프레임의 이름 글자의 모양 및 스타일을 설정합니다.", func = menuOnClick, create = "Name" },
		{ name = "파티 이름표", desc = "공격대 각 파티의 이름표 표시 및 색상에 관한 설정을 합니다. 파티 이름표는 파티별 정렬 방식에서만 사용할 수 있습니다.", func = menuOnClick, create = "PartyTag" },
		{ name = "배경 테두리", desc = "공격대 프레임 전체를 둘러싸는 테두리를 설정합니다.", func = menuOnClick, create = "Border" },
		{ name = "디버프 색상", desc = "디버프 색상을 설정합니다.", func = menuOnClick, create = "DebuffColor" },
	},
	["기능"] = {
		{ name = "어그로", desc = "위협 수준(어그로)을 획득한 플레이어의 이름 왼쪽에 붉은색 화살표를 표시 유무를 설정하거나 어그로 획득 소리의 재생유무를 설정합니다.", func = menuOnClick, create = "Aggro" },
		{ name = "외곽선", desc = "각 공격대원 프레임의 외곽선을 어떻게 표시할지에 대해 설정합니다.", func = menuOnClick, create = "Outline" },
		{ name = "사정 거리", desc = "사정 거리에 따른 프레임의 투명도를 설정합니다. 힐을 할 수 있는 범위인 40미터를 기준으로 투명도가 적용됩니다.", func = menuOnClick, create = "Range" },
		{ name = "생명력 표시", desc = "공격대 프레임에 생명력을 표시할 방법을 설정합니다.", func = menuOnClick, create = "LostHealth" },
		{ name = "버프 확인", desc = "자신이 시전 할 수 있는 버프가 걸려 있는지 유무를 표시하는 방법을 설정합니다.", func = menuOnClick, create = "BuffCheck" },
		{ name = "주문 타이머", desc = "버프 및 디버프를 아이콘과 남은 시간으로 표시합니다. 버프/디버프 이름 입력후 꼭 엔터키를 눌러야 변경 사항이 적용됩니다.", func = menuOnClick, create = "SpellTimer" },
		{ name = "생존기 표시", desc = "플레이어가 시전한 생존기의 주문 이름을 플레이어의 이름과 대체합니다.", func = menuOnClick, create = "SurvivalSkill" },
		{ name = "들어오는 치유/흡수", desc = "플레이어에게 들어오는 치유량 및 흡수량을 투명한 체력바로 보여주거나 아이콘으로 보여줍니다.", func = menuOnClick, create = "HealPrediction" },
		{ name = "무시할 오라 설정", desc = "표시 하지 않을 오라를 추가 하거나 삭제합니다.", func = menuOnClick, create = "IgnoreAura" },
		{ name = "디버프 아이콘 표시", desc = "플레이어에게 걸린 디버프를 프레임에 표시합니다.", func = menuOnClick, create = "DebuffIcon" },
		{ name = "해제 가능한 디버프", desc = "해제 가능한 디버프에 대한 설정을 합니다.", func = menuOnClick, create = "DebuffHealth" },
		{ name = "중요 오라 표시", desc = "중요한 오라를 프레임에 크게 표시합니다. (단, 버프는 블리자드가 중요 오라로 지정한 경우에만 작동합니다.)", func = menuOnClick, create = "BossAura" },
		{ name = "적대적인 대상 표시", desc = "정신 지배 등으로 적대적이된 플레이어의 체력바 색상을 변경합니다.", func = menuOnClick, create = "Enemy" },
		{ name = "전술 목표 아이콘", desc = "전술 목표 아이콘을 표시할 방법을 설정합니다.", func = menuOnClick, create = "RaidTarget" },
		{ name = "시전바", desc = "플레이어의 시전 바를 표시합니다.", func = menuOnClick, create = "CastingBar" },
		{ name = "상황 표시바", desc = "상황 표시바를 설정합니다.", func = menuOnClick, create = "PowerBarAlt" },
		{ name = "부활 시전바", desc = "부활을 받고 있는 플레이어에게 부활 시전 바를 표시합니다. 제일 먼저 시전 완료될 시전바만 표시하며, 같은 파티가 아닌 플레이어가 시전한 경우 시전바는 표시되지 않습니다.", func = menuOnClick, create = "Resurrection" },
		{ name = "역할 아이콘", desc = "플레이어에게 부여된 역할 아이콘을 표시합니다.", func = menuOnClick, create = "RaidRole" },
		{ name = "중앙 상태 아이콘", desc = "다른 인스턴스 파티 또는 다른 위상에 있거나 부활중인 대상에게 아이콘을 표시합니다.", func = menuOnClick, create = "CenterStatusIcon" },
	},
}
Option.dropdownTable = {
	["아이콘"] = { "좌측 상단", "상단", "우측 상단", "좌측", "중앙", "우측", "좌측 하단", "하단", "우측 하단" },
	["아이콘변환"] = { ["좌측 상단"] = "TOPLEFT", ["상단"] = "TOP", ["우측 상단"] = "TOPRIGHT", ["좌측"] = "LEFT", ["중앙"] = "CENTER", ["우측"] = "RIGHT", ["좌측 하단"] = "BOTTOMLEFT", ["하단"] = "BOTTOM", ["우측 하단"] = "BOTTOMRIGHT", TOPLEFT = "좌측 상단", TOP = "상단", TOPRIGHT = "우측 상단", LEFT = "좌측", CENTER = "중앙", RIGHT = "우측", BOTTOMLEFT = "좌측 하단", BOTTOM = "하단", BOTTOMRIGHT = "우측 하단" },
	["징표"] = {},
}
for i = 1, 8 do
	Option.dropdownTable["징표"][i] = ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:0:0:0:-1|t %s 징표"):format(i, _G["RAID_TARGET_"..i])
end
if not Option.title then
	Option.title = Option:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	Option.title:SetText(Option.name)
	Option.title:SetPoint("TOPLEFT", 8, -12)
	Option.version = Option:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	Option.version:SetText("v"..IRF3.version)
	Option.version:SetPoint("LEFT", Option.title, "RIGHT", 2, 0)
end
if Option.combatWarn then
	Option.combatWarn:Hide()
end
Option.mainBorder = CreateFrame("Frame", nil, Option)
Option.mainBorder:SetBackdrop({
	edgeFile = "Interface\\AddOns\\InvenRaidFrames3_Option\\Texture\\TooltipBorderNoneTop.tga",
	tile = true, edgeSize = 16,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
})
Option.mainBorder:SetPoint("TOPLEFT", Option.title, "BOTTOMLEFT", 1, -26)
Option.mainBorder:SetPoint("BOTTOMRIGHT", Option, "BOTTOMLEFT", 163, 39)

local previewList = { "미리 보기 끄기", "미리 보기 - 5인", "미리 보기 - 10인", "미리 보기 - 25인", "미리 보기 - 40인" }
Option.previewDropdown = LBO:CreateWidget("DropDown", Option, "", "미리 보기를 활성화 혹은 비활성화합니다.", nil, nil, true,
	function() return Option:GetPreviewState(), previewList end,
	function(v)
		Option:SetPreview(v > 1 and v or nil)
	end
)
Option.previewDropdown:SetPoint("TOP", Option.mainBorder, "BOTTOM", 0, 16)
Option.previewDropdown:SetWidth(154)

Option.mainTab, Option.mainScroll, Option.detailScroll = {}, {}, {}

local function tabOnClick(self)
	PlaySound("igCharacterInfoTab")
	Option:SetMainTab(self:GetID())
end

local function menuCheck(menu)
	for p, v in pairs(menu) do
		if v.create and type(Option["Create"..v.create.."Menu"]) ~= "function" then
			tremove(menu, p)
			menuCheck(menu)
			break
		end
	end
end

for i, name in ipairs(tabList) do
	Option.mainTab[i] = CreateFrame("Button", Option:GetName().."Tab"..i, Option, "OptionsFrameTabButtonTemplate")
	Option.mainTab[i]:SetPoint("LEFT", Option.mainTab[i - 1], "RIGHT", -16, 0)
	Option.mainTab[i]:SetID(i)
	Option.mainTab[i]:SetText(name)
	Option.mainTab[i]:SetScript("OnClick", tabOnClick)
	Option.detailScroll[name] = {}
	if menuList[name] then
		--menuCheck(menuList[name])
	end
	PanelTemplates_TabResize(Option.mainTab[i], 0)
end
Option.mainTab[1]:ClearAllPoints()
Option.mainTab[1]:SetPoint("TOPLEFT", Option.title, "BOTTOMLEFT", 2, -3)
Option.mainTabLine1 = Option.mainBorder:CreateTexture(nil, "OVERLAY")
Option.mainTabLine1:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-Spacer")
Option.mainTabLine1:SetHeight(16)
Option.mainTabLine2 = Option.mainBorder:CreateTexture(nil, "OVERLAY")
Option.mainTabLine2:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-Spacer")
Option.mainTabLine2:SetHeight(16)
Option.detailBorder = CreateFrame("Frame", nil, Option)
Option.detailBorder:SetBackdrop({
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, edgeSize = 16,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
})
Option.detailBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
Option.detailBorder:SetPoint("TOPLEFT", Option.mainBorder, "TOPRIGHT", 4, 0)
Option.detailBorder:SetPoint("BOTTOMRIGHT", Option, "BOTTOMRIGHT", -10, 10)
Option.detailDesc = Option:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Option.detailDesc:SetHeight(36)
Option.detailDesc:SetJustifyH("LEFT")
Option.detailDesc:SetJustifyV("BOTTOM")
Option.detailDesc:SetNonSpaceWrap(true)
Option.detailDesc:SetPoint("BOTTOMLEFT", Option.detailBorder, "TOPLEFT", 12, 4)
Option.detailDesc:SetPoint("RIGHT", -18, 0)
PanelTemplates_SetNumTabs(Option, #tabList)

function Option:SetMainTab(id)
	self.openedTabName = tabList[id]
	PanelTemplates_Tab_OnClick(self.mainTab[id], self)
	PanelTemplates_UpdateTabs(self)
	self.mainTabLine1:ClearAllPoints()
	self.mainTabLine1:SetPoint("LEFT", self.mainBorder, "TOPLEFT", 8, 0)
	self.mainTabLine1:SetPoint("RIGHT", self.mainTab[id], "BOTTOMLEFT", 10, 1)
	self.mainTabLine2:ClearAllPoints()
	self.mainTabLine2:SetPoint("LEFT", self.mainTab[id], "BOTTOMRIGHT", -10, 1)
	self.mainTabLine2:SetPoint("RIGHT", self.mainBorder, "RIGHT", -8, 0)
	id = self.mainTab[id].name
	if not self.mainScroll[self.openedTabName] and type(menuList[self.openedTabName]) == "table" and #menuList[self.openedTabName] > 0 then
		self.mainScroll[self.openedTabName] = LBO:CreateWidget("Menu", self, menuList[self.openedTabName])
		self.mainScroll[self.openedTabName]:SetAllPoints(self.mainBorder)
		self.mainScroll[self.openedTabName]:SetBackdrop(nil)
		self.mainScroll[self.openedTabName]:SetValue(1)
	end
	for name, frame in pairs(self.mainScroll) do
		if name == self.openedTabName then
			frame:Show()
		else
			frame:Hide()
		end
	end
	self:ShowDetailMenu(self.mainScroll[self.openedTabName]:GetValue())
end

function Option:ShowDetailMenu(id)
	self.openedDetailName = menuList[self.openedTabName][id].name
	if not self.detailScroll[self.openedTabName][self.openedDetailName] then
		local menu
		if menuList[self.openedTabName][id].create and not menuList[self.openedTabName][id].disableScroll then
			menu = LBO:CreateWidget("ScrollFrame", self.mainScroll[self.openedTabName])
		else
			menu = CreateFrame("Frame", nil, self.mainScroll[self.openedTabName])
		end
		menu:Hide()
		menu.options = {}
		menu:SetPoint("TOPLEFT", self.detailBorder, "TOPLEFT", 5, -5)
		menu:SetPoint("BOTTOMRIGHT", self.detailBorder, "BOTTOMRIGHT", -5, 5)
		if menuList[self.openedTabName][id].create and self["Create"..menuList[self.openedTabName][id].create.."Menu"] then
			self["Create"..menuList[self.openedTabName][id].create.."Menu"](self, menu.options, menu.content or menu)
			self["Create"..menuList[self.openedTabName][id].create.."Menu"] = nil
		end
		menuList[self.openedTabName][id].create = nil
		self.detailScroll[self.openedTabName][self.openedDetailName] = menu
	end
	for name, frame in pairs(self.detailScroll[self.openedTabName]) do
		if name == self.openedDetailName then
			frame:Show()
		else
			frame:Hide()
		end
	end
	self.detailDesc:SetText(menuList[self.openedTabName][id].desc or "")
end

local optKey, optValue

function Option:SetOption(...)
	IRF3:SetAttribute("startupdate", nil)
	for i = 1, select("#", ...), 2 do
		optKey, optValue = select(i, ...)
		IRF3:SetAttribute(optKey, optValue or nil)
	end
	IRF3:SetAttribute("startupdate", true)
end

function Option:UpdateMember(func)
	if type(func) == "function" then
		for _, header in pairs(IRF3.headers) do
			for _, member in pairs(header.members) do
				func(member)
			end
		end
		for _, member in pairs(IRF3.petHeader.members) do
			func(member)
		end
	end
end

function Option:ConvertTable(input, output)
	if type(input) == "table" then
		if type(output) == "table" then
			twipe(output)
		else
			output = {}
		end
		for p, v in pairs(input) do
			if v then
				tinsert(output, p)
			end
		end
		sort(output)
		return output
	else
		return nil
	end
end

Option:SetMainTab(1)