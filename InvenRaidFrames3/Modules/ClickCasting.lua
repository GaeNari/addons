local _G = _G
local IRF3 = _G[...]
local pairs = _G.pairs
local wipe = _G.table.wipe
local InCombatLockdown = _G.InCombatLockdown
local GetSpellInfo = _G.GetSpellInfo
local SpellHasRange = _G.SpellHasRange
local GetActiveSpecGroup = _G.GetActiveSpecGroup
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local talent, specId, ctype, ckey, ckey1, ckey2, spellName, wheelScript, wheelCount, prev_wheelCount
local modifilters = { [""] = true, ["alt-"] = true, ["ctrl-"] = true, ["shift-"] = true, ["alt-ctrl-"] = true, ["alt-shift-"] = true, ["ctrl-shift-"] = true }

IRF3.numMouseButtons = 15
local startWheelButton = 31
local clearWheelBinding = "self:ClearBindings()"
local state = {}

IRF3.overrideClickCastingSpells = {
	ROGUE = {
		-- 암살
		["독살"] = "절개",
		["속결"] = "사악한 일격",
		-- 잠행
		["과다출혈"] = "사악한 일격",
		-- 특성
		["투척 표창"] = "투척",
	},
	DRUID = {
	},
	MAGE = {
		-- 비전
		["비전 작렬"] = "얼음불꽃 화살",
		["비전 탄막"] = "화염 작렬",
		-- 화염
		["화염구"] = "얼음불꽃 화살",
		["지옥불 작렬"] = "화염 작렬",
		["용의 숨결"] = "냉기 돌풍",
		-- 냉기
		["얼음창"] = "화염 작렬",
		-- 특성
		["무의 존재"] = "얼음 방패",
		["상급 투명화"] = "투명화",
		["초신성"] = "얼음 회오리",
		["화염 폭풍"] = "얼음 회오리",
		["서리 회오리"] = "얼음 회오리",
	},
	HUNTER = {
		-- 특성
		["코브라 사격"] = "고정 사격",
		["일점 사격"] = "고정 사격",
	},
	PRIEST = {
		-- 신성
		["빛의 권능: 평온"] = "빛의 권능: 응징",
		["빛의 권능: 성역"] = "빛의 권능: 응징",
		-- 암흑
		["정신의 채찍"] = "성스러운 일격",
		-- 특성
		["환각의 마귀"] = "어둠의 마귀",
		["신의 권능: 위안"] = "신성한 불꽃",
		["목적의 명료함"] = "치유의 기원",
	},
	PALADIN = {
		-- 징벌
		["진실의 문장"] = "지휘의 문장",
		-- 특성
		["심판의 주먹"] = "심판의 망치",
		["영원의 불꽃"] = "영광의 서약",
		["최후의 선고"] = "기사단의 선고",
	},
	MONK = {
		-- 특성
		["비취 돌풍"] = "회전 학다리차기",
		["기공탄"] = "구르기",
		["기 폭발"] = "후려차기",
	},
	WARRIOR = {
		-- 무기
		["필사의 일격"] = "영웅의 일격",
		-- 방어
		["피의 갈증"] = "영웅의 일격",
		-- 특성
		["예견된 승리"] = "연전연승",
		["대규모 주문 반사"] = "주문 반사",
		["수비대장"] = "가로 막기",
		["공성파쇄기"] = "위협의 외침",
	},
	SHAMAN = {
		-- 고양
		["폭풍의 일격"] = "원시의 일격",
		-- 복원
		["물의 보호막"] = "번개 보호막",
		-- 특성
		["구속의 토템"] = "속박의 토템",
	},
	DEATHKNIGHT = {
		-- 특성
		["어둠의 질식"] = "질식 시키기",
		["파멸"] = "죽음과 부패",
	},
	WARLOCK = {
		-- 고통
		["악마의 영혼: 불행"] = "악마의 영혼",
		-- 악마
		["악마의 영혼: 지식"] = "악마의 영혼",
		-- 파괴
		["제물"] = "부패",
		["소각"] = "어둠의 화살",
		["악마의 영혼: 불안정"] = "악마의 영혼",
	},
}

do
	local overrideSpells = {}
	for c, spells in pairs(IRF3.overrideClickCastingSpells) do
		for p, v in pairs(spells) do
			if p and v and p ~= v then
				 overrideSpells[c] = overrideSpells[c] or {}
				 overrideSpells[c][p] = v
			end
		end
	end
	for c, spells in pairs(overrideSpells) do
		for p, v in pairs(spells) do
			IRF3.overrideClickCastingSpells[c][p] = v
		end
	end
end

function IRF3:GetClickCasting(modifilter, button)
	ckey = IRF3.ccdb[modifilter..button]
	if ckey == "togglemenu" then
		ckey = "menu"
		IRF3.ccdb[modifilter..button] = ckey
	end
	if ckey then
		ctype, ckey1 = ckey:match("(.+)__(.+)")
		if ctype == "macrotext" then
			return "macro", ctype, ckey1
		elseif ctype == "spell" then
			if not SpellHasRange(ckey1) then
				if self.overrideClickCastingSpells[self.playerClass] then
					spellName = self.overrideClickCastingSpells[self.playerClass][ckey1]
				elseif self.overrideClickCastingSpells[self.specId] then
					spellName = self.overrideClickCastingSpells[self.specId][ckey1]
				else
					spellName = nil
				end
				if spellName and SpellHasRange(spellName) then
					ckey1 = spellName
				end
			end
			return ctype, ctype, ckey1
		elseif ctype then
			return ctype, ctype, ckey1
		else
			return ckey
		end
	end
	return nil
end

local function reset(member, modifilter, button, ctype)
	member:SetAttribute(modifilter.."type"..button, ctype)
	member:SetAttribute(modifilter.."spell"..button, nil)
	member:SetAttribute(modifilter.."item"..button, nil)
	member:SetAttribute(modifilter.."macro"..button, nil)
	member:SetAttribute(modifilter.."macrotext"..button, nil)
end

local function setupMembers(func, ...)
	for _, header in pairs(IRF3.headers) do
		for _, member in pairs(header.members) do
			func(member, ...)
			func(member.petButton, ...)
		end
	end
	for _, member in pairs(IRF3.petHeader.members) do
		func(member, ...)
	end
end

local function setClickCasting(member, modifilter, button, ctype, ckey1, ckey2)
	reset(member, modifilter, button, ctype)
	if ckey1 then
		member:SetAttribute(modifilter..ckey1..button, ckey2)
	end
end

function IRF3:SetClickCasting(modifilter, button)
	ctype, ckey1, ckey2 = self:GetClickCasting(modifilter, button)
	setupMembers(setClickCasting, modifilter, button, ctype, ckey1, ckey2)
end

local function setClickCastingWheel(modifilter, wheel, button)
	ctype, ckey1, ckey2 = IRF3:GetClickCasting(modifilter, wheel)
	if ckey1 == "macro" then
		wheelScript = wheelScript.." self:SetBindingMacro(1, '"..modifilter.."MOUSE"..wheel.."', '"..ckey2.."')"
	elseif ctype then
		for i = startWheelButton, button + 1, -1 do
			if IRF3.headers[1].members[1]:GetAttribute("type"..i) == ctype and IRF3.headers[1].members[1]:GetAttribute(ckey1..i) == ckey2 then
				wheelScript = wheelScript.." self:SetBindingClick(1, '"..modifilter.."MOUSE"..wheel.."', self, 'Button"..i.."')"
				return button
			end
		end
		wheelScript = wheelScript.." self:SetBindingClick(1, '"..modifilter.."MOUSE"..wheel.."', self, 'Button"..button.."')"
		setupMembers(setClickCasting, "", button, ctype, ckey1, ckey2)
		return button - 1
	end
	return button
end

local dummyWheel = function() end

local function overrideWheel(member, has)
	IRF3:UnwrapScript(member, "OnEnter")
	IRF3:UnwrapScript(member, "OnLeave")
	IRF3:UnwrapScript(member, "OnHide")
	IRF3:WrapScript(member, "OnEnter", wheelScript)
	IRF3:WrapScript(member, "OnLeave", clearWheelBinding)
	IRF3:WrapScript(member, "OnHide", clearWheelBinding)
end

function IRF3:SetClickCastingMouseWheel()
	wheelScript, wheelCount = clearWheelBinding, startWheelButton
	for modifilter in pairs(modifilters) do
		wheelCount = setClickCastingWheel(modifilter, "WHEELUP", wheelCount)
		wheelCount = setClickCastingWheel(modifilter, "WHEELDOWN", wheelCount)
	end
	setupMembers(overrideWheel)
	if prev_wheelCount then
		for i = prev_wheelCount, wheelCount do
			setupMembers(setClickCasting, "", i)
		end
	end
	prev_wheelCount, wheelScript, wheelCount = wheelCount + 1
end

function IRF3:SelectClickCastingDB()
	if InCombatLockdown() or not InvenRaidFrames3CharDB then return end
	InvenRaidFrames3CharDB.clickCasting = InvenRaidFrames3CharDB.clickCasting or { {}, {} }

	IRF3.playerClass = IRF3.playerClass or select(2, UnitClass("player"))
	IRF3.specId, specId = GetSpecializationInfo(GetSpecialization(false, false, GetActiveSpecGroup(false) or 0) or 0), IRF3.specId--현재 사용 안함. 추후 사용을 위해 남겨둠.
	IRF3.talent, talent = GetActiveSpecGroup(false) or 1, IRF3.talent

	if IRF3.specId ~= specId or IRF3.talent ~= talent then
		IRF3.ccdb = InvenRaidFrames3CharDB.clickCasting[IRF3.talent]
		for modifilter in pairs(modifilters) do
			for button = 1, IRF3.numMouseButtons do
				IRF3:SetClickCasting(modifilter, button)
			end
		end
		IRF3:SetClickCastingMouseWheel()
		if IRF3.optionFrame.UpdateClickCasting then
			IRF3.optionFrame:UpdateClickCasting()
		end
	end
end

local handler = CreateFrame("Frame")
handler:SetScript("OnEvent", IRF3.SelectClickCastingDB)
handler:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
handler:RegisterEvent("PLAYER_TALENT_UPDATE")
handler:RegisterEvent("PLAYER_LOGIN")
handler:RegisterEvent("PLAYER_ENTERING_WORLD")
handler:RegisterEvent("PLAYER_REGEN_ENABLED")
handler:RegisterEvent("LEARNED_SPELL_IN_TAB")