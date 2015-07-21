local _G = _G
local IRF3 = _G[...]
local pairs = _G.pairs
local wipe = _G.table.wipe
local GetTime = _G.GetTime
local UnitCastingInfo = _G.UnitCastingInfo
local UnitHasIncomingResurrection = _G.UnitHasIncomingResurrection

local SL = IRF3.GetSpellName
local resurrectionSpells = {
	[SL(2006)] = true,
	[SL(2008)] = true,
	[SL(7328)] = true,
	[SL(50769)] = true,
	[SL(115178)] = true,
}

function InvenRaidFrames3Member_HideResurrection(self, noHideCenterIcon)
	if self.resurrectionBar.ticker then
		self.resurrectionBar.ticker:Cancel()
		self.resurrectionBar.ticker = nil
	end
	self.resurrectionBar.startTime = nil
	self.resurrectionBar.endTime = nil
	self.resurrectionBar.caster = nil
	self.resurrectionBar:Hide()
	if not self.centerStatusIcon.tooltip and not noHideCenterIcon then--혹시나 오류로 인해 다른 센터 아이콘이 숨겨지는걸 방지하기 위해 툴팁이 있는지 체크. 없으면 부활 아이콘이니.
		self.centerStatusIcon:Hide()
	end
end

function InvenRaidFrames3Member_OnUpdateResurrectionBar(self)
	if self.resurrectionBar.startTime then
		if (self.isGhost or self.isDead) and self.resurrectionBar.caster and UnitCastingInfo(self.resurrectionBar.caster) then--플레이어가 죽어 있고, 캐스터가 주문을 계속 시전 중이면 부활 바를 그대로 진행 (중간에 끊을 수도 있으므로)
			self.resurrectionBar:SetMinMaxValues(self.resurrectionBar.startTime, self.resurrectionBar.endTime)
			self.resurrectionBar:SetValue(GetTime() * 1000)
		else--캐스팅바 업데이트 도중에 중간에 끊거나 플레이어가 살아나거나 한 경우. 가장 마지막에 부활 주문을 시전한 캐스터를 다시 찾는다.
			self.resurrectionBar.caster = nil
			InvenRaidFrames3Member_UpdateResurrection(self)
		end
	else
		InvenRaidFrames3Member_HideResurrection(self)
	end
end

function InvenRaidFrames3Member_UpdateResurrection(self)
	if (self.isGhost or self.isDead) and self.unit and UnitHasIncomingResurrection(self.unit) then
		for member in pairs(IRF3.visibleMembers) do
			if UnitExists(member.displayedUnit) then
				local castName, _, _, _, castStart, castEnd = UnitCastingInfo(member.displayedUnit)--모든 공격대원의 캐스팅 정보를 얻어온다.
				local diff = (castStart or 0) - (self.resurrectStart or 0)--부활 이벤트 발생 시간과 캐스팅 시작 시간의 차이를 기록.
				if not self.resurrectionBar.caster and castName and resurrectionSpells[castName] and (diff > -5 and diff < 5) then--현재 캐스팅 중인 사람이 없고, 부활 주문이 감지되고, 부활 주문이 감지된 시간과 캐스팅 시간의 차이가 5ms 이하일 때 부활 바 표시
					self.resurrectionBar.startTime = castStart
					self.resurrectionBar.endTime = castEnd
					self.resurrectionBar.caster = GetUnitName(member.displayedUnit, true)
					self.resurrectionBar.ticker = self.resurrectionBar.ticker or C_Timer.NewTicker(0.02, function() InvenRaidFrames3Member_OnUpdateResurrectionBar(self) end)
					self.resurrectionBar:SetMinMaxValues(castStart, castEnd)
					self.resurrectionBar:SetValue(GetTime() * 1000)
					self.resurrectionBar:Show()
					break
				end
			end
		end
		-- 가장 마지막에 부활 주문을 시전한 캐스터를 찾기 실패한 경우. 부활바 업데이트를 중지, 센터 아이콘 유지
		if not self.resurrectionBar.caster then
			InvenRaidFrames3Member_HideResurrection(self, true)
		end
	else
		InvenRaidFrames3Member_HideResurrection(self)
	end
end
