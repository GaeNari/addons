if IsAddOnLoaded("Skada") then
	local disablepopup = CreateFrame("Frame", nil, UIParent)
	disablepopup:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 1, right = 1, top = 1, bottom = 1}}
	)
	disablepopup:SetSize(500, 105)
	disablepopup:SetPoint("CENTER", UIParent, "CENTER")
	disablepopup:SetFrameStrata("DIALOG")

	local text = disablepopup:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
	text:SetWidth(480)
	text:SetWordWrap(true)
	text:SetPoint("TOP", disablepopup, "TOP", 0, -10)
	local popuptext
	if GetLocale() == "koKR" then
		popuptext = "구버전 Skada를 발견하였습니다. Skada가 작동하지 않으므로 구버전 Skada를 반드시 제거해주시기 바랍니다. 제거하지 않으면 원할한 게임 플레이가 불가능 합니다. 확인 버튼을 누르면 구버전 Skada를 비활성화 합니다."
	else
		popuptext = "Skada: Ultimate found old version of Skada. Skada will not work. Please remove old version of Skada. Press okay to disable old version of Skada."
	end
	text:SetText(popuptext)

	local accept = CreateFrame("Button", nil, disablepopup)
	accept:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
	accept:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
	accept:SetSize(50, 50)
	accept:SetPoint("BOTTOM", disablepopup, "BOTTOM", 0, 0)
	accept:SetScript("OnClick", function(f)
		DisableAddOn("Skada")
		DisableAddOn("SkadaCC")
		DisableAddOn("SkadaDamage")
		DisableAddOn("SkadaDamageTaken")
		DisableAddOn("SkadaDeaths")
		DisableAddOn("SkadaDebuffs")
		DisableAddOn("SkadaDispels")
		DisableAddOn("SkadaEnemies")
		DisableAddOn("SkadaHealing")
		DisableAddOn("SkadaPower")
		DisableAddOn("SkadaThreat")
		ReloadUI()
	end)
	
	return
end
